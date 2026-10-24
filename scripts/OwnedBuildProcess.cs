using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

namespace Warhammer.Tools
{
// Single-owner Windows build runner. The job, not the UAT parent PID, owns descendants.
// No breakaway flags are enabled; the job handle is never inherited by the child.
public sealed class OwnedBuildProcess : IDisposable
{
    const uint KillOnClose = 0x2000, Suspended = 4, UnicodeEnvironment = 0x400,
        ExtendedStartup = 0x80000, NoWindow = 0x08000000, UseStdHandles = 0x100,
        WaitObject = 0, WaitTimeout = 258, Failed = 0xffffffff, CleanupExit = 0xc000013a;
    static readonly IntPtr InvalidHandle = new IntPtr(-1);
    IntPtr job, process, output, error, input;
    readonly int cleanupMilliseconds;
    bool assigned, disposed;
    public bool CleanupConfirmed { get; private set; }
    public uint? FinalActiveProcessCount { get; private set; }
    public bool TerminationRequested { get; private set; }

    [StructLayout(LayoutKind.Sequential)] struct SecurityAttributes
    { public int Length; public IntPtr Descriptor; [MarshalAs(UnmanagedType.Bool)] public bool Inherit; }
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)] struct StartupInfo
    {
        public int Size; public string Reserved, Desktop, Title;
        public uint X, Y, Width, Height, XChars, YChars, Fill, Flags;
        public short Show, ReservedBytes; public IntPtr ReservedData, Input, Output, Error;
    }
    [StructLayout(LayoutKind.Sequential)] struct StartupInfoEx { public StartupInfo Info; public IntPtr Attributes; }
    [StructLayout(LayoutKind.Sequential)] struct ProcessInformation
    { public IntPtr Process, Thread; public uint ProcessId, ThreadId; }
    [StructLayout(LayoutKind.Sequential)] struct BasicLimit
    {
        public long ProcessTime, JobTime; public uint Flags; public UIntPtr MinWorkingSet, MaxWorkingSet;
        public uint ActiveLimit; public UIntPtr Affinity; public uint Priority, Scheduling;
    }
    [StructLayout(LayoutKind.Sequential)] struct IoCounters
    { public ulong ReadOps, WriteOps, OtherOps, ReadBytes, WriteBytes, OtherBytes; }
    [StructLayout(LayoutKind.Sequential)] struct ExtendedLimit
    { public BasicLimit Basic; public IoCounters Io; public UIntPtr ProcessMemory, JobMemory, PeakProcess, PeakJob; }
    [StructLayout(LayoutKind.Sequential)] struct Accounting
    { public long User, Kernel, PeriodUser, PeriodKernel; public uint Faults, Total, Active, Terminated; }

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)] static extern IntPtr CreateJobObjectW(IntPtr attributes, string name);
    [DllImport("kernel32.dll", SetLastError = true)] static extern bool SetInformationJobObject(IntPtr job, int kind, ref ExtendedLimit value, uint bytes);
    [DllImport("kernel32.dll", SetLastError = true)] static extern bool QueryInformationJobObject(IntPtr job, int kind, out Accounting value, uint bytes, out uint returned);
    [DllImport("kernel32.dll", SetLastError = true)] static extern bool AssignProcessToJobObject(IntPtr job, IntPtr process);
    [DllImport("kernel32.dll", SetLastError = true)] static extern bool TerminateJobObject(IntPtr job, uint exitCode);
    [DllImport("kernel32.dll", SetLastError = true)] static extern bool TerminateProcess(IntPtr process, uint exitCode);
    [DllImport("kernel32.dll", SetLastError = true)] static extern uint WaitForSingleObject(IntPtr handle, uint milliseconds);
    [DllImport("kernel32.dll", SetLastError = true)] static extern bool GetExitCodeProcess(IntPtr process, out uint exitCode);
    [DllImport("kernel32.dll", SetLastError = true)] static extern uint ResumeThread(IntPtr thread);
    [DllImport("kernel32.dll", SetLastError = true)] static extern bool CloseHandle(IntPtr handle);
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)] static extern IntPtr CreateFileW(string path, uint access, uint share, ref SecurityAttributes attributes, uint creation, uint flags, IntPtr template);
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)] static extern bool CreateProcessW(string application, StringBuilder command, IntPtr processAttributes, IntPtr threadAttributes, bool inheritHandles, uint flags, IntPtr environment, string directory, ref StartupInfoEx startup, out ProcessInformation info);
    [DllImport("kernel32.dll", SetLastError = true)] static extern bool InitializeProcThreadAttributeList(IntPtr list, int count, uint flags, ref IntPtr bytes);
    [DllImport("kernel32.dll", SetLastError = true)] static extern bool UpdateProcThreadAttribute(IntPtr list, uint flags, IntPtr attribute, IntPtr value, IntPtr bytes, IntPtr previous, IntPtr returned);
    [DllImport("kernel32.dll")] static extern void DeleteProcThreadAttributeList(IntPtr list);

    OwnedBuildProcess(int cleanupTimeoutMilliseconds) { cleanupMilliseconds = cleanupTimeoutMilliseconds; }
    static Win32Exception NativeError(string operation) { return new Win32Exception(Marshal.GetLastWin32Error(), operation); }
    static void Check(bool success, string operation) { if (!success) throw NativeError(operation); }
    void RequireLive() { if (disposed) throw new ObjectDisposedException(nameof(OwnedBuildProcess)); }

    // Windows CRT/CommandLineToArgvW-compatible quoting, including empty arguments,
    // embedded quotes and trailing backslashes. No command shell is involved.
    static string Quote(string value)
    {
        if (value == null || value.IndexOf('\0') >= 0) throw new ArgumentException("Invalid process argument.");
        var text = new StringBuilder("\""); int slashes = 0;
        foreach (char c in value)
        {
            if (c == '\\') { slashes++; continue; }
            text.Append('\\', c == '"' ? slashes * 2 + 1 : slashes); text.Append(c); slashes = 0;
        }
        return text.Append('\\', slashes * 2).Append('"').ToString();
    }

    public static OwnedBuildProcess Start(ProcessStartInfo info, string stdoutPath, string stderrPath,
        int cleanupTimeoutMilliseconds = 10000)
    {
        if (!RuntimeInformation.IsOSPlatform(OSPlatform.Windows) || IntPtr.Size != 8)
            throw new PlatformNotSupportedException("Owned build jobs require native Windows x64.");
        if (info == null || info.UseShellExecute || !String.IsNullOrEmpty(info.Arguments) ||
            !String.IsNullOrEmpty(info.UserName) || !Path.IsPathFullyQualified(info.FileName) ||
            !Path.IsPathFullyQualified(info.WorkingDirectory) || !Directory.Exists(info.WorkingDirectory))
            throw new ArgumentException("Supply an absolute executable/directory, ArgumentList and current-user non-shell environment.");
        if (cleanupTimeoutMilliseconds < 1 || cleanupTimeoutMilliseconds > 30000)
            throw new ArgumentOutOfRangeException(nameof(cleanupTimeoutMilliseconds));
        if (!Path.IsPathFullyQualified(stdoutPath) || !Path.IsPathFullyQualified(stderrPath) ||
            String.Equals(Path.GetFullPath(stdoutPath), Path.GetFullPath(stderrPath), StringComparison.OrdinalIgnoreCase))
            throw new ArgumentException("Supply two distinct absolute create-new output files.");
        if (Marshal.SizeOf<ExtendedLimit>() != 144 || Marshal.SizeOf<Accounting>() != 48 || Marshal.SizeOf<StartupInfoEx>() != 112)
            throw new PlatformNotSupportedException("Unexpected Windows x64 ABI layout.");
        var command = new StringBuilder(Quote(info.FileName));
        foreach (string argument in info.ArgumentList) command.Append(' ').Append(Quote(argument));
        if (command.Length >= 32767) throw new ArgumentException("Native command line is too long.");
        var environment = new List<string>();
        foreach (var pair in info.Environment)
        {
            if (String.IsNullOrEmpty(pair.Key) || pair.Key.IndexOfAny(new[] { '=', '\0' }) >= 0 ||
                pair.Value == null || pair.Value.IndexOf('\0') >= 0) throw new ArgumentException("Invalid child environment entry.");
            environment.Add(pair.Key + "=" + pair.Value);
        }
        environment.Sort(StringComparer.OrdinalIgnoreCase);
        var owner = new OwnedBuildProcess(cleanupTimeoutMilliseconds);
        IntPtr attributes = IntPtr.Zero, handles = IntPtr.Zero, environmentBlock = IntPtr.Zero, thread = IntPtr.Zero;
        bool initialized = false;
        try
        {
            owner.job = CreateJobObjectW(IntPtr.Zero, null);
            if (owner.job == IntPtr.Zero) throw NativeError("CreateJobObject");
            var limits = new ExtendedLimit(); limits.Basic.Flags = KillOnClose;
            Check(SetInformationJobObject(owner.job, 9, ref limits, (uint)Marshal.SizeOf<ExtendedLimit>()), "SetInformationJobObject(KILL_ON_JOB_CLOSE)");
            var security = new SecurityAttributes { Length = Marshal.SizeOf<SecurityAttributes>(), Inherit = true };
            owner.output = CreateFileW(stdoutPath, 0x40000000, 1, ref security, 1, 0x80, IntPtr.Zero);
            if (owner.output == InvalidHandle) { owner.output = IntPtr.Zero; throw NativeError("CreateFile(stdout)"); }
            owner.error = CreateFileW(stderrPath, 0x40000000, 1, ref security, 1, 0x80, IntPtr.Zero);
            if (owner.error == InvalidHandle) { owner.error = IntPtr.Zero; throw NativeError("CreateFile(stderr)"); }
            owner.input = CreateFileW("NUL", 0x80000000, 3, ref security, 3, 0x80, IntPtr.Zero);
            if (owner.input == InvalidHandle) { owner.input = IntPtr.Zero; throw NativeError("CreateFile(stdin)"); }
            IntPtr bytes = IntPtr.Zero; InitializeProcThreadAttributeList(IntPtr.Zero, 1, 0, ref bytes);
            if (bytes == IntPtr.Zero) throw NativeError("InitializeProcThreadAttributeList(size)");
            attributes = Marshal.AllocHGlobal(bytes);
            Check(InitializeProcThreadAttributeList(attributes, 1, 0, ref bytes), "InitializeProcThreadAttributeList"); initialized = true;
            handles = Marshal.AllocHGlobal(IntPtr.Size * 3);
            Marshal.WriteIntPtr(handles, 0, owner.input); Marshal.WriteIntPtr(handles, IntPtr.Size, owner.output); Marshal.WriteIntPtr(handles, IntPtr.Size * 2, owner.error);
            Check(UpdateProcThreadAttribute(attributes, 0, new IntPtr(0x20002), handles, new IntPtr(IntPtr.Size * 3), IntPtr.Zero, IntPtr.Zero), "UpdateProcThreadAttribute(HANDLE_LIST)");
            environmentBlock = Marshal.StringToHGlobalUni(String.Join("\0", environment) + "\0\0");
            var startup = new StartupInfoEx { Attributes = attributes };
            startup.Info.Size = Marshal.SizeOf<StartupInfoEx>(); startup.Info.Flags = UseStdHandles;
            startup.Info.Input = owner.input; startup.Info.Output = owner.output; startup.Info.Error = owner.error;
            ProcessInformation created;
            Check(CreateProcessW(info.FileName, command, IntPtr.Zero, IntPtr.Zero, true,
                Suspended | UnicodeEnvironment | ExtendedStartup | NoWindow, environmentBlock, info.WorkingDirectory, ref startup, out created), "CreateProcess(suspended)");
            owner.process = created.Process; thread = created.Thread;
            Check(AssignProcessToJobObject(owner.job, owner.process), "AssignProcessToJobObject(before resume)"); owner.assigned = true;
            if (ResumeThread(thread) == Failed) throw NativeError("ResumeThread");
            return owner;
        }
        catch (Exception primary)
        {
            try { owner.Dispose(); }
            catch (Exception cleanup) { throw new AggregateException("Build start and cleanup failed.", primary, cleanup); }
            throw;
        }
        finally
        {
            if (thread != IntPtr.Zero) CloseHandle(thread);
            if (initialized) DeleteProcThreadAttributeList(attributes);
            if (attributes != IntPtr.Zero) Marshal.FreeHGlobal(attributes);
            if (handles != IntPtr.Zero) Marshal.FreeHGlobal(handles);
            if (environmentBlock != IntPtr.Zero) Marshal.FreeHGlobal(environmentBlock);
        }
    }

    public bool HasExited { get { return WaitForExit(0); } }
    public bool WaitForExit(int milliseconds)
    {
        RequireLive(); if (milliseconds < 0) throw new ArgumentOutOfRangeException(nameof(milliseconds));
        uint result = WaitForSingleObject(process, (uint)milliseconds);
        if (result == WaitObject) return true;
        if (result == WaitTimeout) return false;
        throw NativeError("WaitForSingleObject(process)");
    }
    public int ExitCode
    {
        get { RequireLive(); if (!HasExited) throw new InvalidOperationException("The build parent has not exited.");
            uint code; Check(GetExitCodeProcess(process, out code), "GetExitCodeProcess"); return unchecked((int)code); }
    }
    Accounting ReadAccounting()
    {
        RequireLive(); Accounting value; uint returned; uint bytes = (uint)Marshal.SizeOf<Accounting>();
        Check(QueryInformationJobObject(job, 1, out value, bytes, out returned), "QueryInformationJobObject(accounting)");
        if (returned != bytes) throw new InvalidOperationException("Unexpected job accounting size."); return value;
    }
    public uint ActiveProcessCount { get { return ReadAccounting().Active; } }
    public uint TotalProcessCount { get { return ReadAccounting().Total; } }
    public void TerminateOwnedTree()
    { RequireLive(); Check(TerminateJobObject(job, CleanupExit), "TerminateJobObject"); TerminationRequested = true; }
    public bool WaitJobEmpty(int milliseconds)
    {
        RequireLive(); if (milliseconds < 0) throw new ArgumentOutOfRangeException(nameof(milliseconds));
        var clock = Stopwatch.StartNew();
        do { uint active = ActiveProcessCount; FinalActiveProcessCount = active; if (active == 0) return true;
            int remaining = milliseconds - (int)Math.Min(Int32.MaxValue, clock.ElapsedMilliseconds);
            if (remaining <= 0) return false; Thread.Sleep(Math.Min(20, remaining)); } while (true);
    }
    public void Dispose()
    {
        if (disposed) return;
        var failures = new List<Exception>();
        try
        {
            // Failed assignment leaves a suspended, unowned root: terminate its retained
            // handle as well. A successfully assigned tree is always terminated by job.
            if (process != IntPtr.Zero && !assigned)
            {
                try { if (!HasExited) { Check(TerminateProcess(process, CleanupExit), "TerminateProcess(unassigned suspended root)");
                    if (!WaitForExit(cleanupMilliseconds)) throw new TimeoutException("Suspended root cleanup timed out."); } }
                catch (Exception e) { failures.Add(e); }
            }
            if (job != IntPtr.Zero)
            {
                try { TerminateOwnedTree(); if (!WaitJobEmpty(cleanupMilliseconds)) throw new TimeoutException("Owned build job did not become empty."); }
                catch (Exception e) { failures.Add(e); }
            }
            CleanupConfirmed = failures.Count == 0 && FinalActiveProcessCount == 0;
        }
        finally
        {
            // Closing the non-inherited final job handle enforces KILL_ON_JOB_CLOSE
            // even if termination/accounting failed. Logs stay open through that step.
            Close(ref job, failures); Close(ref process, failures);
            Close(ref input, failures); Close(ref output, failures); Close(ref error, failures);
            disposed = true; GC.SuppressFinalize(this);
        }
        if (failures.Count != 0) { CleanupConfirmed = false; throw new AggregateException("Owned build cleanup failed.", failures); }
    }
    static void Close(ref IntPtr handle, List<Exception> failures)
    {
        if (handle == IntPtr.Zero) return;
        IntPtr owned = handle; handle = IntPtr.Zero;
        if (!CloseHandle(owned)) failures.Add(NativeError("CloseHandle(owned build resource)"));
    }
    ~OwnedBuildProcess()
    {
        // No waits or exceptions on the finalizer thread. Kernel job-close cleanup
        // also applies if the owning PowerShell process itself terminates.
        foreach (IntPtr handle in new[] { job, process, input, output, error })
            if (handle != IntPtr.Zero) CloseHandle(handle);
    }
}
}
