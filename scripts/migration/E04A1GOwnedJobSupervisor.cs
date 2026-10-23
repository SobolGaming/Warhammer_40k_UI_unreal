using System;
using System.IO;
using System.IO.Compression;
using System.Text;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Threading;

namespace Warhammer.E02 {
public static class Supervisor {
    const uint QUERY=0x0400, SYNCHRONIZE=0x00100000, CREATE_SUSPENDED=4,
        UNICODE_ENV=0x400, EXTENDED=0x80000, NO_WINDOW=0x08000000,
        KILL_ON_CLOSE=0x2000, WAIT_OBJECT_0=0, WAIT_TIMEOUT=258;
    const uint INVALID=0xffffffff;
    static readonly IntPtr InvalidHandle=new IntPtr(-1);
    [StructLayout(LayoutKind.Sequential)] struct SA { public int n; public IntPtr sd; [MarshalAs(UnmanagedType.Bool)] public bool inherit; }
    [StructLayout(LayoutKind.Sequential,CharSet=CharSet.Unicode)] struct SI {
        public int cb; public string reserved,desktop,title;
        public uint x,y,xSize,ySize,xChars,yChars,fill,flags;
        public short show,reservedBytes; public IntPtr reserved2,input,output,error;
    }
    [StructLayout(LayoutKind.Sequential)] struct SIX { public SI info; public IntPtr attributes; }
    [StructLayout(LayoutKind.Sequential)] struct PI { public IntPtr process,thread; public uint pid,tid; }
    [StructLayout(LayoutKind.Sequential)] struct BASIC {
        public long processTime,jobTime; public uint flags; public UIntPtr minimum,maximum;
        public uint activeLimit; public UIntPtr affinity; public uint priority,scheduling;
    }
    [StructLayout(LayoutKind.Sequential)] struct IO {
        public ulong readOps,writeOps,otherOps,readBytes,writeBytes,otherBytes;
    }
    [StructLayout(LayoutKind.Sequential)] struct LIMIT {
        public BASIC basic; public IO io; public UIntPtr processMemory,jobMemory,peakProcess,peakJob;
    }
    [StructLayout(LayoutKind.Sequential)] struct ACCOUNT {
        public long user,kernel,periodUser,periodKernel;
        public uint faults,total,active,terminatedByLimit;
    }
    [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)] static extern IntPtr CreateJobObjectW(IntPtr sa,string name);
    [DllImport("kernel32.dll",SetLastError=true)] static extern bool SetInformationJobObject(IntPtr job,int cls,ref LIMIT info,uint size);
    [DllImport("kernel32.dll",SetLastError=true)] static extern bool QueryInformationJobObject(IntPtr job,int cls,ref ACCOUNT info,uint size,out uint returned);
    [DllImport("kernel32.dll",SetLastError=true)] static extern bool QueryInformationJobObject(IntPtr job,int cls,ref LIMIT info,uint size,out uint returned);
    [DllImport("kernel32.dll",SetLastError=true)] static extern bool AssignProcessToJobObject(IntPtr job,IntPtr process);
    [DllImport("kernel32.dll",SetLastError=true)] static extern bool IsProcessInJob(IntPtr process,IntPtr job,out bool inside);
    [DllImport("kernel32.dll",SetLastError=true)] static extern bool TerminateJobObject(IntPtr job,uint exit);
    [DllImport("kernel32.dll",SetLastError=true)] static extern bool TerminateProcess(IntPtr process,uint exit);
    [DllImport("kernel32.dll",SetLastError=true)] static extern uint WaitForSingleObject(IntPtr handle,uint milliseconds);
    [DllImport("kernel32.dll",SetLastError=true)] static extern uint ResumeThread(IntPtr thread);
    [DllImport("kernel32.dll",SetLastError=true)] static extern bool GetProcessTimes(IntPtr process,out long creation,out long exit,out long kernel,out long user);
    [DllImport("kernel32.dll",SetLastError=true)] static extern bool GetExitCodeProcess(IntPtr process,out uint exit);
    [DllImport("kernel32.dll",SetLastError=true)] static extern bool CloseHandle(IntPtr handle);
    [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)] static extern IntPtr CreateFileW(string path,uint access,uint share,ref SA attributes,uint creation,uint flags,IntPtr template);
    [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)] static extern bool CreateProcessW(string exe,StringBuilder command,IntPtr processSa,IntPtr threadSa,bool inherit,uint flags,IntPtr environment,string cwd,ref SIX startup,out PI process);
    [DllImport("kernel32.dll",SetLastError=true)] static extern bool InitializeProcThreadAttributeList(IntPtr list,int count,uint flags,ref IntPtr bytes);
    [DllImport("kernel32.dll",SetLastError=true)] static extern bool UpdateProcThreadAttribute(IntPtr list,uint flags,IntPtr attribute,IntPtr value,IntPtr bytes,IntPtr previous,IntPtr returned);
    [DllImport("kernel32.dll")] static extern void DeleteProcThreadAttributeList(IntPtr list);
    delegate bool EnumWindow(IntPtr window,IntPtr parameter);
    [DllImport("user32.dll")] static extern bool EnumWindows(EnumWindow callback,IntPtr parameter);
    [DllImport("user32.dll",SetLastError=true)] static extern uint GetWindowThreadProcessId(IntPtr window,out uint pid);
    [DllImport("user32.dll",SetLastError=true)] static extern bool PostMessageW(IntPtr window,uint message,IntPtr wparam,IntPtr lparam);

    static string Utc() { return DateTime.UtcNow.ToString("o"); }
    static void WinCheck(bool success,string operation) { if(!success) throw new Win32Exception(Marshal.GetLastWin32Error(),operation); }
    static Dictionary<string,object> Error(string stage,Exception e,bool injected=false) {
        return new Dictionary<string,object>{{"stage",stage},{"type",e.GetType().FullName},{"message",e.Message},
            {"win32Error",e is Win32Exception ? (object)((Win32Exception)e).NativeErrorCode : null},{"syntheticFault",injected},{"observedUtc",Utc()}};
    }
    // Windows command-line quoting, not shell escaping. Build.bat is invoked by
    // the fixed reviewed PowerShell command below; no caller text is shell code.
    public static string Quote(string argument) {
        if(argument.IndexOf('\0')>=0) throw new ArgumentException("NUL argument");
        var b=new StringBuilder("\""); int slashes=0;
        foreach(char c in argument) {
            if(c=='\\') { slashes++; continue; }
            if(c=='\"') { b.Append('\\',slashes*2+1); b.Append(c); slashes=0; continue; }
            b.Append('\\',slashes); slashes=0; b.Append(c);
        }
        b.Append('\\',slashes*2); return b.Append('"').ToString();
    }
    static void Close(ref IntPtr handle,string name,List<object> errors) {
        if(handle==IntPtr.Zero || handle==InvalidHandle) return;
        IntPtr old=handle; handle=IntPtr.Zero;
        if(!CloseHandle(old)) errors.Add(Error("close-"+name,new Win32Exception(Marshal.GetLastWin32Error())));
    }
    static Dictionary<string,object> Count(IntPtr job,List<object> samples,string stage) {
        ACCOUNT a=new ACCOUNT(); uint length;
        WinCheck(QueryInformationJobObject(job,1,ref a,(uint)Marshal.SizeOf<ACCOUNT>(),out length),"QueryInformationJobObject(accounting)");
        if(length!=(uint)Marshal.SizeOf<ACCOUNT>()) throw new InvalidDataException("Accounting size mismatch");
        var value=new Dictionary<string,object>{{"stage",stage},{"observedUtc",Utc()},{"querySucceeded",true},
            {"totalProcesses",a.total},{"activeProcesses",a.active},{"totalTerminatedProcesses",a.terminatedByLimit},
            {"totalUserTime100ns",a.user},{"totalKernelTime100ns",a.kernel},{"thisPeriodUserTime100ns",a.periodUser},
            {"thisPeriodKernelTime100ns",a.periodKernel},{"totalPageFaultCount",a.faults}};
        samples.Add(value); return value;
    }
    static void RootFinal(IntPtr process,Dictionary<string,object> r) {
        long creation,exit,kernel,user; uint code;
        WinCheck(GetProcessTimes(process,out creation,out exit,out kernel,out user),"GetProcessTimes(exit)");
        WinCheck(GetExitCodeProcess(process,out code),"GetExitCodeProcess");
        if(WaitForSingleObject(process,0)!=WAIT_OBJECT_0 || exit<=0) throw new InvalidDataException("Root exit not confirmed");
        r["creationFileTime"]=creation; r["creationUtc"]=DateTime.FromFileTimeUtc(creation).ToString("o");
        r["exitFileTime"]=exit; r["exitUtc"]=DateTime.FromFileTimeUtc(exit).ToString("o"); r["exitCode"]=code;
        r["exitObservedUtc"]=Utc(); r["exitConfirmed"]=true;
    }
    static void Graceful(uint rootPid,List<object> records) {
        EnumWindow callback=(window,parameter)=> {
            uint actual; GetWindowThreadProcessId(window,out actual);
            if(actual==rootPid) {
                bool ok=PostMessageW(window,0x10,IntPtr.Zero,IntPtr.Zero);
                records.Add(new Dictionary<string,object>{{"operation","WM_CLOSE"},{"rootPid",rootPid},{"posted",ok},
                    {"observedUtc",Utc()},{"win32Error",ok ? null : (object)Marshal.GetLastWin32Error()}});
            }
            return true;
        };
        EnumWindows(callback,IntPtr.Zero); GC.KeepAlive(callback);
    }

    // Pure string construction; Run uses this same path for the actual child block.
    public static string BuildEnvironmentBlock(System.Collections.IDictionary inherited, Dictionary<string,string> environment) {
        var vars=new SortedDictionary<string,string>(StringComparer.OrdinalIgnoreCase);
        foreach(System.Collections.DictionaryEntry entry in inherited) {
            string key=(string)entry.Key;
            if(key.IndexOfAny(new[]{'\0','='})>=0 || key.Equals("UE_ADDITIONAL_PLUGIN_PATHS",StringComparison.OrdinalIgnoreCase) || key.Equals("UE-CmdLineArgs",StringComparison.OrdinalIgnoreCase) || key.Equals("UBT_EXTRA_ARGS",StringComparison.OrdinalIgnoreCase) || System.Text.RegularExpressions.Regex.IsMatch(key,"TOKEN|PASSWORD|SECRET|API_KEY|CREDENTIAL",System.Text.RegularExpressions.RegexOptions.IgnoreCase)) continue;
            vars[key]=(string)entry.Value;
        }
        foreach(var pair in environment) {
            if(pair.Key.IndexOfAny(new[]{'\0','='})>=0 || pair.Value.IndexOf('\0')>=0) throw new ArgumentException("Environment NUL/key");
            if((pair.Key.Equals("UE_ADDITIONAL_PLUGIN_PATHS",StringComparison.OrdinalIgnoreCase) || pair.Key.Equals("UE-CmdLineArgs",StringComparison.OrdinalIgnoreCase)) && pair.Value.Length!=0) throw new ArgumentException("E02 reserved startup environment must be empty");
            if(pair.Key.Equals("UBT_EXTRA_ARGS",StringComparison.OrdinalIgnoreCase)) {
                if(pair.Value.Length!=0) throw new ArgumentException("E04 reserved UBT_EXTRA_ARGS must be empty");
                continue;
            }
            vars[pair.Key]=pair.Value;
        }
        // UE and UBT append these channels internally, after literal OS argv capture.
        vars["UE_ADDITIONAL_PLUGIN_PATHS"]=""; vars["UE-CmdLineArgs"]=""; vars["UBT_EXTRA_ARGS"]="";
        var block=new StringBuilder(); foreach(var pair in vars) block.Append(pair.Key).Append('=').Append(pair.Value).Append('\0'); block.Append('\0');
        return block.ToString();
    }

    // Opt-in observations only. Existing Run/default callers do not enter this path.
    [DllImport("kernel32.dll",EntryPoint="QueryInformationJobObject",SetLastError=true)]
    static extern bool QueryOwnedJobPidListNative(IntPtr job,int cls,IntPtr info,uint size,out uint returned);
    [DllImport("user32.dll",EntryPoint="EnumWindows",SetLastError=true)]
    static extern bool EnumerateOwnedWindowCandidates(EnumWindow callback,IntPtr parameter);
    [DllImport("user32.dll")]
    static extern bool IsWindowVisible(IntPtr window);

    static HashSet<uint> ReadOwnedJobPidSnapshot(IntPtr retainedJob) {
        if(retainedJob==IntPtr.Zero) throw new ArgumentException("Retained job handle required");
        if(IntPtr.Size!=8) throw new InvalidOperationException("A1G window observer requires Windows x64");
        const int pidCapacity=256,headerBytes=8;
        int bufferBytes=checked(headerBytes+pidCapacity*IntPtr.Size);
        IntPtr buffer=Marshal.AllocHGlobal(bufferBytes);
        try {
            uint returned;
            if(!QueryOwnedJobPidListNative(retainedJob,3,buffer,(uint)bufferBytes,out returned))
                throw new Win32Exception(Marshal.GetLastWin32Error(),"QueryInformationJobObject(owned PID list)");
            if(returned<headerBytes || returned>(uint)bufferBytes)
                throw new InvalidDataException("Owned PID-list returned length");
            uint assigned=unchecked((uint)Marshal.ReadInt32(buffer,0));
            uint listed=unchecked((uint)Marshal.ReadInt32(buffer,4));
            if(assigned!=listed || listed>pidCapacity || returned<headerBytes+listed*(uint)IntPtr.Size)
                throw new InvalidDataException("Owned PID-list incomplete or exceeds finite capacity");
            var pids=new HashSet<uint>();
            for(int index=0;index<(int)listed;index++) {
                ulong value=unchecked((ulong)Marshal.ReadIntPtr(buffer,headerBytes+index*IntPtr.Size).ToInt64());
                if(value==0 || value>uint.MaxValue || !pids.Add((uint)value))
                    throw new InvalidDataException("Owned PID-list invalid or duplicate PID");
            }
            return pids;
        } finally { Marshal.FreeHGlobal(buffer); }
    }
    static uint[] SortedOwnedPids(HashSet<uint> pids) {
        var ordered=new List<uint>(pids); ordered.Sort(); return ordered.ToArray();
    }
    static void SampleOwnedJobWindows(IntPtr retainedJob,Stopwatch clock,string stage,
        List<object> samples,int sampleLimit,int seconds) {
        if(samples.Count>=sampleLimit) throw new InvalidDataException("Owned-window sample cap exceeded");
        var row=new Dictionary<string,object>{
            {"stage",stage},{"startedUtc",Utc()},{"elapsedSecondsAtStart",clock.Elapsed.TotalSeconds},
            {"completedUtc",null},{"elapsedSecondsAtEnd",null},{"status","INCOMPLETE"},
            {"jobPidQueryBeforeSucceeded",false},{"jobPidQueryAfterSucceeded",false},
            {"ownedJobPidsBefore",null},{"ownedJobPidsAfter",null},{"pidSetStable",false},
            {"enumPerformed",false},{"enumSucceeded",false},{"visibleOwnedSnapshotPidCounts",new object[0]},
            {"visibleWindowObservationCount",null},{"failure",null}};
        samples.Add(row);
        try {
            if(clock.Elapsed.TotalSeconds>=seconds) throw new TimeoutException("Owned-window sample reached existing execution deadline");
            var before=ReadOwnedJobPidSnapshot(retainedJob);
            row["jobPidQueryBeforeSucceeded"]=true; row["ownedJobPidsBefore"]=SortedOwnedPids(before);
            var visibleByPid=new Dictionary<uint,int>(); Exception callbackFailure=null;
            if(before.Count>0) {
                EnumWindow callback=(window,parameter)=> {
                    try {
                        uint pid; uint thread=GetWindowThreadProcessId(window,out pid);
                        if(thread==0) throw new Win32Exception(Marshal.GetLastWin32Error(),"GetWindowThreadProcessId(owned PID filter)");
                        // Only transient owner-PID filtering is done for unrelated HWNDs.
                        // Their PID/handle, titles, text, class, input and pixels are not retained.
                        if(before.Contains(pid) && IsWindowVisible(window)) {
                            int previous; visibleByPid.TryGetValue(pid,out previous);
                            visibleByPid[pid]=checked(previous+1);
                        }
                        return true;
                    } catch(Exception error) { callbackFailure=error; return false; }
                };
                bool enumerated; int enumerationError=0;
                try {
                    enumerated=EnumerateOwnedWindowCandidates(callback,IntPtr.Zero);
                    if(!enumerated) enumerationError=Marshal.GetLastWin32Error();
                } finally { GC.KeepAlive(callback); }
                row["enumPerformed"]=true; row["enumSucceeded"]=enumerated;
                if(callbackFailure!=null) throw callbackFailure;
                if(!enumerated) throw new Win32Exception(enumerationError,"EnumWindows(owned PID filter)");
            } else { row["enumSucceeded"]=true; }
            var visibleRows=new List<object>(); int visibleCount=0;
            foreach(uint pid in SortedOwnedPids(before)) {
                int count;
                if(visibleByPid.TryGetValue(pid,out count)) {
                    visibleRows.Add(new Dictionary<string,object>{{"pid",pid},{"count",count}});
                    visibleCount=checked(visibleCount+count);
                }
            }
            // Preserve candidate observations even if the following membership query fails.
            row["visibleOwnedSnapshotPidCounts"]=visibleRows;
            row["visibleWindowObservationCount"]=visibleCount;
            var after=ReadOwnedJobPidSnapshot(retainedJob);
            row["jobPidQueryAfterSucceeded"]=true; row["ownedJobPidsAfter"]=SortedOwnedPids(after);
            bool stable=before.SetEquals(after); row["pidSetStable"]=stable;
            if(!stable) {
                row["status"]="FAIL_MEMBERSHIP_CHANGED";
                throw new InvalidDataException("Owned-window before/after job PID membership changed");
            }
            if(visibleCount!=0) {
                row["status"]="FAIL_VISIBLE_WINDOW_OBSERVED";
                throw new InvalidDataException("Owned top-level WS_VISIBLE window observed");
            }
            if(clock.Elapsed.TotalSeconds>=seconds) throw new TimeoutException("Owned-window sample exhausted existing execution deadline");
            row["status"]="ZERO_OBSERVED";
        } catch(Exception error) {
            if((string)row["status"]=="INCOMPLETE") row["status"]="FAIL_OBSERVER_ERROR";
            row["failure"]=Error("owned-job-window-sample",error); throw;
        } finally {
            row["completedUtc"]=Utc(); row["elapsedSecondsAtEnd"]=clock.Elapsed.TotalSeconds;
        }
    }
    static Dictionary<string,object> SummarizeOwnedJobWindows(List<object> rows,int sampleLimit,bool rootPassed) {
        int failed=0,total=0; double previous=-1,maximumGap=0;
        bool before=false,startup=false,final=false;
        foreach(object item in rows) {
            var row=(Dictionary<string,object>)item;
            if((string)row["status"]!="ZERO_OBSERVED") failed++;
            if(row["visibleWindowObservationCount"]!=null) total=checked(total+(int)row["visibleWindowObservationCount"]);
            double at=(double)row["elapsedSecondsAtStart"];
            if(previous>=0) maximumGap=Math.Max(maximumGap,at-previous); previous=at;
            before|=(string)row["stage"]=="assigned-before-resume";
            startup|=(string)row["stage"]=="startup-after-resume";
            final|=(string)row["stage"]=="final-before-job-cleanup";
        }
        bool endpoints=before && startup && final;
        return new Dictionary<string,object>{
            {"schemaVersion",1},{"enabled",true},
            {"method","CURRENT_DESKTOP_TOP_LEVEL_WS_VISIBLE_FILTERED_BY_RETAINED_JOB_PID_SNAPSHOTS"},
            {"intervalMilliseconds",500},{"pidCapacity",256},{"sampleLimit",sampleLimit},
            {"sampleCount",rows.Count},{"samples",rows},{"visibleWindowObservationCountTotal",total},
            {"failedSampleCount",failed},{"requiredEndpointStagesPresent",endpoints},
            {"maximumStartToStartGapSeconds",maximumGap},
            {"status",rootPassed && failed==0 && total==0 && endpoints ? "PASS_ZERO_OBSERVED" : "FAIL"},
            {"continuousAbsenceEstablished",false},
            {"limits",new[]{
                "Periodic current-desktop top-level WS_VISIBLE samples; brief windows between samples are not excluded.",
                "IsWindowVisible checks style, not pixels; obscured windows may count. Other desktops/sessions, child-only and message-only windows are outside these observations.",
                "Job-PID and HWND queries are non-atomic; no universal PID/handle-race or descendant-inventory claim.",
                "EnumWindows transiently identifies unrelated owner PIDs for filtering; no unrelated PID/handle, title, text, class, input or pixel data is retained.",
                "Hidden flags/requested visibility are separate from these actual sample receipts."}}};
    }

    public static Dictionary<string,object> Run(string exe,string[] arguments,string cwd,
        Dictionary<string,string> environment,string stdout,string stderr,int seconds,bool visible,string syntheticFault,
        bool cleanupAfterSuccessfulRoot=false) {
        return RunCore(exe,arguments,cwd,environment,stdout,stderr,seconds,visible,syntheticFault,cleanupAfterSuccessfulRoot,false);
    }
    public static Dictionary<string,object> RunWithOwnedJobWindowObservation(string exe,string[] arguments,string cwd,
        Dictionary<string,string> environment,string stdout,string stderr,int seconds,bool visible,string syntheticFault,
        bool cleanupAfterSuccessfulRoot=false) {
        if(visible) throw new ArgumentException("Owned-job window observation requires hidden launch request");
        return RunCore(exe,arguments,cwd,environment,stdout,stderr,seconds,visible,syntheticFault,cleanupAfterSuccessfulRoot,true);
    }
    static Dictionary<string,object> RunCore(string exe,string[] arguments,string cwd,
        Dictionary<string,string> environment,string stdout,string stderr,int seconds,bool visible,string syntheticFault,
        bool cleanupAfterSuccessfulRoot,bool observeOwnedJobWindows) {
        if(seconds<3 || seconds>1800) throw new ArgumentOutOfRangeException("seconds");
        var errors=new List<object>(); var samples=new List<object>(); var shutdown=new List<object>();
        List<object> windowSamples=observeOwnedJobWindows ? new List<object>() : null;
        int windowSampleLimit=checked(seconds*2+4); double nextWindowSampleAt=0;
        var r=new Dictionary<string,object>{{"schemaVersion",1},{"executable",exe},{"arguments",arguments},{"workingDirectory",cwd},
            {"environmentOverrides",environment},{"stdout",stdout},{"stderr",stderr},{"budgetSeconds",seconds},
            {"startedObservationUtc",Utc()},{"pid",null},{"creationFileTime",null},{"creationUtc",null},{"exitFileTime",null},
            {"exitUtc",null},{"exitCode",null},{"exitConfirmed",false},{"assignedBeforeResume",false},{"resumed",false},
            {"timedOut",false},{"cleanupConfirmed",false},{"technicalBlocked",false},{"rootExitWhileMembersActive",false},{"jobAccounting",samples},
            {"shutdownRequests",shutdown},{"secondaryErrors",errors},{"primaryFailure",null},{"syntheticFault",syntheticFault},
            {"completionCleanupMode",cleanupAfterSuccessfulRoot ? "PostSuccessfulRootCleanup" : "NaturalDrain"},
            {"postRootGraceSeconds",cleanupAfterSuccessfulRoot ? 5 : 0},{"rootExitObservedElapsedSeconds",null},
            {"descendantInventory","NOT_COLLECTED; optional observations are incomplete"},{"visibleWindowRequested",visible}};
        IntPtr job=IntPtr.Zero, attr=IntPtr.Zero, handles=IntPtr.Zero, env=IntPtr.Zero;
        IntPtr outFile=IntPtr.Zero,errFile=IntPtr.Zero,input=IntPtr.Zero;
        PI process=new PI(); bool assigned=false, exited=false, timed=false, initialized=false;
        var clock=Stopwatch.StartNew(); double grace=Math.Min(15,seconds/4.0),reserve=Math.Min(5,seconds/4.0);
        try {
            job=CreateJobObjectW(IntPtr.Zero,null); if(job==IntPtr.Zero) throw new Win32Exception(Marshal.GetLastWin32Error(),"CreateJobObject");
            LIMIT limits=new LIMIT(); limits.basic.flags=KILL_ON_CLOSE;
            WinCheck(SetInformationJobObject(job,9,ref limits,(uint)Marshal.SizeOf<LIMIT>()),"SetInformationJobObject");
            uint length; LIMIT effective=new LIMIT();
            WinCheck(QueryInformationJobObject(job,9,ref effective,(uint)Marshal.SizeOf<LIMIT>(),out length),"QueryInformationJobObject(limits)");
            if(length!=(uint)Marshal.SizeOf<LIMIT>() || effective.basic.flags!=KILL_ON_CLOSE) throw new InvalidDataException("Private job flags differ");
            r["jobLimitFlags"]=effective.basic.flags; r["privateUnnamedJob"]=true; r["jobHandleInherited"]=false;
            var sa=new SA{n=Marshal.SizeOf<SA>(),sd=IntPtr.Zero,inherit=true};
            outFile=CreateFileW(stdout,0x40000000,1,ref sa,1,0x80,IntPtr.Zero);
            if(outFile==InvalidHandle) throw new Win32Exception(Marshal.GetLastWin32Error(),"CreateFile(stdout)");
            errFile=CreateFileW(stderr,0x40000000,1,ref sa,1,0x80,IntPtr.Zero);
            if(errFile==InvalidHandle) throw new Win32Exception(Marshal.GetLastWin32Error(),"CreateFile(stderr)");
            input=CreateFileW("NUL",0x80000000,3,ref sa,3,0x80,IntPtr.Zero);
            if(input==InvalidHandle) throw new Win32Exception(Marshal.GetLastWin32Error(),"CreateFile(NUL)");
            IntPtr attrBytes=IntPtr.Zero; InitializeProcThreadAttributeList(IntPtr.Zero,1,0,ref attrBytes);
            if(attrBytes==IntPtr.Zero) throw new Win32Exception(Marshal.GetLastWin32Error(),"Attribute-list size");
            attr=Marshal.AllocHGlobal(attrBytes); WinCheck(InitializeProcThreadAttributeList(attr,1,0,ref attrBytes),"InitializeProcThreadAttributeList"); initialized=true;
            handles=Marshal.AllocHGlobal(IntPtr.Size*3); Marshal.WriteIntPtr(handles,0,input); Marshal.WriteIntPtr(handles,IntPtr.Size,outFile); Marshal.WriteIntPtr(handles,IntPtr.Size*2,errFile);
            WinCheck(UpdateProcThreadAttribute(attr,0,new IntPtr(0x20002),handles,new IntPtr(IntPtr.Size*3),IntPtr.Zero,IntPtr.Zero),"UpdateProcThreadAttribute(HANDLE_LIST)");
            var startup=new SIX { info=new SI{cb=Marshal.SizeOf<SIX>(),flags=0x100|1,show=(short)(visible?5:0),input=input,output=outFile,error=errFile}, attributes=attr };
            var command=new StringBuilder(Quote(exe)); foreach(string argument in arguments) command.Append(' ').Append(Quote(argument));
            var block=BuildEnvironmentBlock(Environment.GetEnvironmentVariables(),environment);
            env=Marshal.StringToHGlobalUni(block);
            WinCheck(CreateProcessW(exe,command,IntPtr.Zero,IntPtr.Zero,true,CREATE_SUSPENDED|UNICODE_ENV|EXTENDED|(visible?0:NO_WINDOW),env,cwd,ref startup,out process),"CreateProcess(suspended)");
            r["pid"]=process.pid;
            long creation,exit,kernel,user; WinCheck(GetProcessTimes(process.process,out creation,out exit,out kernel,out user),"GetProcessTimes(creation)");
            r["creationFileTime"]=creation; r["creationUtc"]=DateTime.FromFileTimeUtc(creation).ToString("o");
            if(syntheticFault=="assign") throw new InvalidOperationException("E02_INJECTED_ASSIGN_FAILURE_BEFORE_RESUME");
            WinCheck(AssignProcessToJobObject(job,process.process),"AssignProcessToJobObject"); assigned=true;
            bool inside; WinCheck(IsProcessInJob(process.process,job,out inside),"IsProcessInJob");
            if(!inside) throw new InvalidDataException("Root not in retained private job");
            r["assignedBeforeResume"]=true;
            if(observeOwnedJobWindows) SampleOwnedJobWindows(job,clock,"assigned-before-resume",windowSamples,windowSampleLimit,seconds);
            if(ResumeThread(process.thread)==INVALID) throw new Win32Exception(Marshal.GetLastWin32Error(),"ResumeThread");
            r["resumed"]=true; r["resumedObservationUtc"]=Utc();
            if(observeOwnedJobWindows) {
                SampleOwnedJobWindows(job,clock,"startup-after-resume",windowSamples,windowSampleLimit,seconds);
                nextWindowSampleAt=clock.Elapsed.TotalSeconds+0.5;
            }
            Close(ref process.thread,"root-thread",errors); Close(ref outFile,"stdout-original",errors); Close(ref errFile,"stderr-original",errors); Close(ref input,"stdin-original",errors);
            bool faultUsed=false; bool shutdownStarted=false,normalCleanupRequested=false;
            double killAt=0,rootExitAt=-1; uint? lastActive=null;
            while(clock.Elapsed.TotalSeconds<seconds) {
                if(process.process!=IntPtr.Zero) {
                    uint waited=WaitForSingleObject(process.process,50);
                    if(waited!=WAIT_OBJECT_0 && waited!=WAIT_TIMEOUT) throw new Win32Exception(Marshal.GetLastWin32Error(),"WaitForSingleObject(root)");
                    if(waited==WAIT_OBJECT_0) {
                        RootFinal(process.process,r); exited=true; rootExitAt=clock.Elapsed.TotalSeconds;
                        r["rootExitObservedElapsedSeconds"]=rootExitAt;
                        Close(ref process.process,"root-process",errors);
                    }
                }
                if(syntheticFault=="query" && !faultUsed) { faultUsed=true; throw new InvalidOperationException("E02_INJECTED_ACCOUNTING_QUERY_FAILURE"); }
                ACCOUNT a=new ACCOUNT(); uint n; WinCheck(QueryInformationJobObject(job,1,ref a,(uint)Marshal.SizeOf<ACCOUNT>(),out n),"QueryInformationJobObject(loop)");
                if(n!=(uint)Marshal.SizeOf<ACCOUNT>()) throw new InvalidDataException("Loop accounting size");
                if(lastActive!=a.active || exited && !(bool)r["cleanupConfirmed"]) { Count(job,samples,"progress"); lastActive=a.active; }
                if(exited && a.active>0) r["rootExitWhileMembersActive"]=true;
                if(exited && a.active==0) { r["cleanupConfirmed"]=true; break; }
                double remaining=seconds-clock.Elapsed.TotalSeconds;
                if(!shutdownStarted && remaining<=grace+reserve) {
                    timed=true; r["timedOut"]=true; r["timeoutKind"]="EXECUTION_BUDGET_RESERVED_FOR_SHUTDOWN";
                    shutdownStarted=true; killAt=clock.Elapsed.TotalSeconds+grace;
                    // The original retained root handle prevents PID reuse.
                    // Never address a window by an already-released root PID.
                    if(!exited && process.process!=IntPtr.Zero) Graceful(process.pid,shutdown);
                }
                if(shutdownStarted && clock.Elapsed.TotalSeconds>=killAt) {
                    WinCheck(TerminateJobObject(job,0xe0200001),"TerminateJobObject(timeout)");
                    shutdown.Add(new Dictionary<string,object>{{"operation","TerminateJobObject"},{"succeeded",true},{"observedUtc",Utc()}});
                    killAt=double.PositiveInfinity;
                }
                // Opt-in only for reviewed synchronous CMake roots and SUP01.
                // The execution-timeout route above always retains priority.
                if(cleanupAfterSuccessfulRoot && !timed && !shutdownStarted && !normalCleanupRequested &&
                    assigned && job!=IntPtr.Zero && exited && (bool)r["exitConfirmed"] && (uint)r["exitCode"]==0 && a.active>0) {
                    double requestedAt=clock.Elapsed.TotalSeconds;
                    if(rootExitAt>=0 && requestedAt-rootExitAt>=5 && seconds-requestedAt>grace+reserve) {
                        var request=new Dictionary<string,object>{{"operation","TerminateJobObject"},{"reason","POST_ROOT_COMPLETION"},
                            {"succeeded",false},{"observedUtc",Utc()},{"elapsedSeconds",requestedAt},{"rootExitElapsedSeconds",rootExitAt},
                            {"naturalGraceSeconds",5},{"activeProcessesBefore",a.active},{"rootExitCode",(uint)r["exitCode"]},
                            {"terminationExitCode",(uint)0xe0200003},{"win32Error",null}};
                        shutdown.Add(request); normalCleanupRequested=true;
                        bool stopped=TerminateJobObject(job,0xe0200003);
                        int error=stopped ? 0 : Marshal.GetLastWin32Error();
                        request["succeeded"]=stopped; request["win32Error"]=stopped ? null : (object)error;
                        if(!stopped) throw new Win32Exception(error,"TerminateJobObject(post-root-completion)");
                    }
                }
                if(observeOwnedJobWindows && !timed && !shutdownStarted &&
                    clock.Elapsed.TotalSeconds>=nextWindowSampleAt && seconds-clock.Elapsed.TotalSeconds>grace+reserve) {
                    SampleOwnedJobWindows(job,clock,"periodic",windowSamples,windowSampleLimit,seconds);
                    nextWindowSampleAt=clock.Elapsed.TotalSeconds+0.5;
                }
                Thread.Sleep(25);
            }
            if(!(bool)r["cleanupConfirmed"]) { timed=true; r["timedOut"]=true; throw new TimeoutException("Private job cleanup not confirmed within phase bound"); }
            if(timed) throw new TimeoutException("Owned execution exceeded its reserved running budget");
            if(!exited || (uint)r["exitCode"]!=0) throw new InvalidDataException("Root unsuccessful or exit unavailable");
            if(syntheticFault=="close") errors.Add(Error("close-control-seam",new InvalidOperationException("E02_INJECTED_HANDLE_FINALIZATION_FAILURE"),true));
        } catch(Exception e) {
            if(observeOwnedJobWindows && e is TimeoutException && clock.Elapsed.TotalSeconds>=seconds) {
                timed=true; r["timedOut"]=true; r["timeoutKind"]="OWNED_WINDOW_OBSERVATION_EXHAUSTED_EXISTING_BUDGET";
            }
            bool injected=e.Message.StartsWith("E02_INJECTED_",StringComparison.Ordinal);
            r["primaryFailure"]=Error("owned-root",e,injected);
            r["technicalBlocked"]=!injected && !(bool)r["resumed"] && e is Win32Exception;
        }
        finally {
            if(observeOwnedJobWindows && assigned && job!=IntPtr.Zero) {
                try { SampleOwnedJobWindows(job,clock,"final-before-job-cleanup",windowSamples,windowSampleLimit,seconds); }
                catch(Exception error) {
                    if(error is TimeoutException && clock.Elapsed.TotalSeconds>=seconds) {
                        timed=true; r["timedOut"]=true; r["timeoutKind"]="OWNED_WINDOW_OBSERVATION_EXHAUSTED_EXISTING_BUDGET";
                    }
                    // Keep every earlier failure and use the same retained-job cleanup below.
                    if(r["primaryFailure"]==null) r["primaryFailure"]=Error("owned-window-final",error);
                    else errors.Add(Error("owned-window-final",error));
                    r["cleanupConfirmed"]=false;
                }
            }
            // Original retained handles establish ownership even when assignment
            // failed. No PID reopening, name search, or Kill(true) is used.
            if(!(bool)r["cleanupConfirmed"]) {
                try {
                    if(assigned) WinCheck(TerminateJobObject(job,0xe0200002),"TerminateJobObject(failure)");
                    else if(process.process!=IntPtr.Zero) WinCheck(TerminateProcess(process.process,0xe0200002),"TerminateProcess(original-suspended-root)");
                    while(clock.Elapsed.TotalSeconds<seconds) {
                        if(process.process!=IntPtr.Zero) {
                            uint waited=WaitForSingleObject(process.process,20);
                            if(waited!=WAIT_OBJECT_0 && waited!=WAIT_TIMEOUT) throw new Win32Exception(Marshal.GetLastWin32Error(),"WaitForSingleObject(cleanup)");
                            if(waited==WAIT_OBJECT_0) { RootFinal(process.process,r); exited=true; Close(ref process.process,"root-process",errors); }
                        }
                        if(job!=IntPtr.Zero) {
                            var final=Count(job,samples,"failure-cleanup");
                            if((uint)final["activeProcesses"]==0 && (process.pid==0 || exited)) { r["cleanupConfirmed"]=true; break; }
                        }
                        Thread.Sleep(25);
                    }
                } catch(Exception e) { errors.Add(Error("failure-cleanup",e)); }
            }
            Close(ref process.thread,"root-thread",errors); Close(ref process.process,"root-process",errors);
            Close(ref outFile,"stdout-original",errors); Close(ref errFile,"stderr-original",errors); Close(ref input,"stdin-original",errors);
            if(initialized) DeleteProcThreadAttributeList(attr);
            if(attr!=IntPtr.Zero) Marshal.FreeHGlobal(attr); if(handles!=IntPtr.Zero) Marshal.FreeHGlobal(handles); if(env!=IntPtr.Zero) Marshal.FreeHGlobal(env);
            Close(ref job,"private-job",errors);
            r["completedObservationUtc"]=Utc(); r["elapsedSeconds"]=clock.Elapsed.TotalSeconds;
            r["status"]=(r["primaryFailure"]==null && errors.Count==0 && (bool)r["exitConfirmed"] && (bool)r["cleanupConfirmed"] && !(bool)r["timedOut"]) ? "PASS" : "FAIL";
            if(observeOwnedJobWindows) {
                var observation=SummarizeOwnedJobWindows(windowSamples,windowSampleLimit,(string)r["status"]=="PASS");
                r["ownedJobWindowObservation"]=observation;
                if((string)observation["status"]!="PASS_ZERO_OBSERVED") r["status"]="FAIL";
            }
        }
        return r;
    }

    static uint BE(byte[] b,int i) { return (uint)b[i]<<24|(uint)b[i+1]<<16|(uint)b[i+2]<<8|b[i+3]; }
    static uint CRC(byte[] b,int start,int count) { uint c=0xffffffff; for(int i=start;i<start+count;i++) { c^=b[i]; for(int bit=0;bit<8;bit++) c=(c>>1)^((c&1)!=0 ? 0xedb88320u:0); } return c^0xffffffff; }
    static int Paeth(int a,int b,int c) { int p=a+b-c,pa=Math.Abs(p-a),pb=Math.Abs(p-b),pc=Math.Abs(p-c); return pa<=pb&&pa<=pc?a:pb<=pc?b:c; }
    // Decode exactly the ordinary noninterlaced8bit RGB/RGBA PNG format used
    // by these UE screenshots. Unsupported encodings fail visibly, never pass.
    public static Dictionary<string,object> DecodePng(string path) {
        long size=new FileInfo(path).Length; if(size<45 || size>64*1024*1024) throw new InvalidDataException("PNG size");
        byte[] b=File.ReadAllBytes(path); byte[] magic={137,80,78,71,13,10,26,10};
        if(b.Length<45 || b.Length>64*1024*1024) throw new InvalidDataException("PNG size");
        for(int i=0;i<8;i++) if(b[i]!=magic[i]) throw new InvalidDataException("PNG signature");
        int width=0,height=0,channels=0,offset=8; bool ihdr=false,end=false;
        using(var compressed=new MemoryStream()) {
            while(offset<b.Length) {
                if(offset+12>b.Length) throw new InvalidDataException("PNG truncated chunk");
                uint length=BE(b,offset); if(length>64*1024*1024 || offset+12L+length>b.Length) throw new InvalidDataException("PNG chunk size");
                int n=(int)length; string kind=Encoding.ASCII.GetString(b,offset+4,4);
                if(CRC(b,offset+4,n+4)!=BE(b,offset+8+n)) throw new InvalidDataException("PNG CRC");
                if(kind=="IHDR") {
                    if(ihdr||offset!=8||n!=13) throw new InvalidDataException("PNG IHDR"); ihdr=true;
                    width=checked((int)BE(b,offset+8)); height=checked((int)BE(b,offset+12));
                    int type=b[offset+17]; channels=type==2?3:type==6?4:0;
                    if(width<=0||height<=0||width>4096||height>4096||b[offset+16]!=8||channels==0||b[offset+18]!=0||b[offset+19]!=0||b[offset+20]!=0) throw new InvalidDataException("Unsupported PNG encoding");
                } else if(kind=="IDAT") { if(!ihdr||end) throw new InvalidDataException("PNG order"); compressed.Write(b,offset+8,n); }
                else if(kind=="IEND") { if(n!=0) throw new InvalidDataException("PNG IEND"); end=true; offset+=12; break; }
                else if((b[offset+4]&32)==0) throw new InvalidDataException("Unsupported critical PNG chunk");
                offset+=n+12;
            }
            if(!ihdr||!end||offset!=b.Length||compressed.Length==0) throw new InvalidDataException("Incomplete PNG");
            compressed.Position=0; int stride=checked(width*channels),expected=checked((stride+1)*height);
            byte[] raw=new byte[expected]; using(var z=new ZLibStream(compressed,CompressionMode.Decompress,true)) {
                int read=0,n; while(read<expected && (n=z.Read(raw,read,expected-read))>0) read+=n;
                if(read!=expected||z.ReadByte()!=-1) throw new InvalidDataException("PNG decompressed size");
            }
            byte[] prior=new byte[stride],row=new byte[stride]; var colors=new HashSet<uint>(); int minimum=255,maximum=0;
            for(int y=0;y<height;y++) {
                int p=y*(stride+1),filter=raw[p++]; if(filter>4) throw new InvalidDataException("PNG filter");
                for(int x=0;x<stride;x++) {
                    int left=x>=channels?row[x-channels]:0,up=prior[x],corner=x>=channels?prior[x-channels]:0;
                    int predictor=filter==0?0:filter==1?left:filter==2?up:filter==3?(left+up)/2:Paeth(left,up,corner);
                    row[x]=unchecked((byte)(raw[p+x]+predictor));
                }
                for(int x=0;x<stride;x+=channels) {
                    uint rgb=(uint)row[x]<<16|(uint)row[x+1]<<8|row[x+2]; if(colors.Count<256) colors.Add(rgb);
                    for(int c=0;c<3;c++) { minimum=Math.Min(minimum,row[x+c]); maximum=Math.Max(maximum,row[x+c]); }
                }
                var swap=prior;prior=row;row=swap;
            }
            if(colors.Count<8 || maximum-minimum<16) throw new InvalidDataException("PNG framebuffer blank/insufficient variation");
            return new Dictionary<string,object>{{"width",width},{"height",height},{"decoded",true},{"rgbColorCountCapped256",colors.Count},
                {"minimumRgb",minimum},{"maximumRgb",maximum},{"encoding","noninterlaced8bitRGB/RGBA"},{"visualGeometryInspection","REQUIRED_SEPARATELY"}};
        }
    }
}
}