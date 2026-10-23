using System;
using System.IO;
using Microsoft.Win32.SafeHandles;
using System.Text;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Threading;

namespace Warhammer.A2P0 {
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

    static string Utc() { return DateTime.UtcNow.ToString("o"); }
    static void WinCheck(bool success,string operation) { if(!success) throw new Win32Exception(Marshal.GetLastWin32Error(),operation); }
    static Dictionary<string,object> Error(string stage,Exception e,bool injected=false) {
        return new Dictionary<string,object>{{"stage",stage},{"type",e.GetType().FullName},{"message",e.Message},
            {"win32Error",e is Win32Exception ? (object)((Win32Exception)e).NativeErrorCode : null},{"syntheticFault",injected},{"observedUtc",Utc()}};
    }
    // Windows command-line quoting for the fixed interpreter argv.
    // No caller text is treated as shell code.
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

    [DllImport("kernel32.dll",SetLastError=true)] static extern bool CreatePipe(out IntPtr read,out IntPtr write,ref SA attributes,uint size);
    [DllImport("kernel32.dll",SetLastError=true)] static extern bool SetHandleInformation(IntPtr handle,uint mask,uint flags);
    // Each reader is the only writer of its retained file. It never retains
    // bytes beyond the fixed cap. Overflow signals cleanup; discarded tails are
    // not represented as complete capture. No source/helper is executed here.
    sealed class PipeCapture {
        readonly FileStream input,output;
        readonly Thread worker;
        readonly string path;
        readonly long cap;
        long observed,retained;
        volatile bool overflow,eof,finished,failed,started;
        Exception failure;
        public PipeCapture(SafeFileHandle handle,string target,long maximum) {
            path=target; cap=maximum;
            try {
                input=new FileStream(handle,FileAccess.Read,4096,false);
                output=new FileStream(target,FileMode.CreateNew,FileAccess.Write,FileShare.Read,4096);
            } catch {
                if(input!=null) input.Dispose(); else handle.Dispose();
                if(output!=null) output.Dispose();
                throw;
            }
            worker=new Thread(Copy){IsBackground=true,Name="A2P0-capped-pipe"};
        }
        public void Start() { worker.Start(); started=true; }
        void Copy() {
            try {
                byte[] buffer=new byte[4096];
                while(true) {
                    int n=input.Read(buffer,0,buffer.Length);
                    if(n==0) { eof=true; break; }
                    Interlocked.Add(ref observed,n);
                    int keep=(int)Math.Min((long)n,Math.Max(0,cap-Interlocked.Read(ref retained)));
                    if(keep>0) {
                        output.Write(buffer,0,keep);
                        Interlocked.Add(ref retained,keep);
                    }
                    if(keep<n) overflow=true;
                }
            } catch(Exception error) { failure=error; failed=true; }
            finally {
                try { input.Dispose(); } catch(Exception error) { if(failure==null) failure=error; failed=true; }
                try { output.Dispose(); } catch(Exception error) { if(failure==null) failure=error; failed=true; }
                finished=true;
            }
        }
        public bool Faulted { get { return overflow || failed; } }
        public bool Join(int milliseconds) {
            if(started) return worker.Join(Math.Max(0,milliseconds));
            // No thread could block in a pipe read before Start succeeded.
            try { input.Dispose(); output.Dispose(); }
            catch(Exception error) { failure=error; failed=true; }
            finished=true; return true;
        }
        public Dictionary<string,object> Record(bool joined) {
            return new Dictionary<string,object>{{"path",path},{"capBytes",cap},
                {"observedBytes",Interlocked.Read(ref observed)},{"retainedBytes",Interlocked.Read(ref retained)},
                {"overflow",overflow},{"eof",eof},{"readerFinished",finished},{"readerJoined",joined},
                {"readerFailed",failed},{"truncatedOrTailUnobserved",overflow || !eof || !joined},
                {"complete",joined && finished && eof && !overflow && !failed},
                {"failure",failure==null ? null : Error("pipe-capture",failure)}};
        }
    }

    static void NewPipe(ref IntPtr read,ref IntPtr write,ref SA sa) {
        IntPtr candidateRead,candidateWrite;
        // Failed CreatePipe output values are unspecified; do not close them.
        if(!CreatePipe(out candidateRead,out candidateWrite,ref sa,0))
            throw new Win32Exception(Marshal.GetLastWin32Error(),"CreatePipe");
        read=candidateRead; write=candidateWrite;
        WinCheck(SetHandleInformation(read,1,0),"SetHandleInformation(noninherited-read)");
    }
    static PipeCapture TakePipe(ref IntPtr read,string path,long cap) {
        var owned=new SafeFileHandle(read,true); read=IntPtr.Zero;
        return new PipeCapture(owned,path,cap);
    }
    static void RequireSingle(Dictionary<string,object> count) {
        if((uint)count["totalProcesses"]!=1 || (uint)count["activeProcesses"]>1 ||
           (uint)count["totalTerminatedProcesses"]!=0)
            throw new InvalidDataException("Single-root job accounting differs");
    }
    static int RemainingMilliseconds(Stopwatch clock,double deadline) {
        return (int)Math.Max(0,Math.Min(Int32.MaxValue,(deadline-clock.Elapsed.TotalSeconds)*1000));
    }

    // Derived from the existing Run API. The extra integer is the remaining
    // externally watched operator budget; it does not implement that watchdog.
    public static Dictionary<string,object> Run(string exe,string[] arguments,string cwd,
        Dictionary<string,string> environment,string stdout,string stderr,int seconds,bool visible,string syntheticFault,
        int operatorRemainingMilliseconds) {
        if(seconds!=60 || visible || syntheticFault!="" || operatorRemainingMilliseconds<65000 || operatorRemainingMilliseconds>75000)
            throw new ArgumentException("Fixed P0 hidden60s/cleanup5s/external75s contract required");
        const uint ACTIVE_LIMIT=8;
        var errors=new List<object>(); var samples=new List<object>(); var shutdown=new List<object>();
        var r=new Dictionary<string,object>{{"schemaVersion",1},{"recordKind","A2P0_OWNED_PYTHON_JOB_PROCESS_RESULT_NOT_ACCEPTANCE"},
            {"executable",exe},{"arguments",arguments},{"workingDirectory",cwd},
            {"environmentOverrides",environment},{"stdout",stdout},{"stderr",stderr},{"budgetSeconds",seconds},
            {"startedObservationUtc",Utc()},{"pid",null},{"creationFileTime",null},{"creationUtc",null},{"exitFileTime",null},
            {"exitUtc",null},{"exitCode",null},{"exitConfirmed",false},{"assignedBeforeResume",false},{"resumed",false},
            {"timedOut",false},{"cleanupConfirmed",false},{"technicalBlocked",false},{"rootExitWhileMembersActive",false},{"jobAccounting",samples},
            {"shutdownRequests",shutdown},{"secondaryErrors",errors},{"primaryError",null},{"syntheticFault",syntheticFault},
            {"visibleWindowRequested",false},{"childCreationAttempts","NOT_OBSERVED_OR_ATTRIBUTED"},
            {"cleanupBudgetSeconds",5},{"operatorRemainingMilliseconds",operatorRemainingMilliseconds},
            {"outerHardWall","REQUIRED_EXTERNAL_WATCHDOG_NOT_IMPLEMENTED_BY_THIS_CLASS"},
            {"deadlineOrigin","MONOTONIC_CREATEPROCESS_CALL_START_CONSERVATIVE_OF_ACTUAL_CREATION"}};
        IntPtr job=IntPtr.Zero,attr=IntPtr.Zero,handles=IntPtr.Zero,jobList=IntPtr.Zero,env=IntPtr.Zero;
        IntPtr outRead=IntPtr.Zero,outWrite=IntPtr.Zero,errRead=IntPtr.Zero,errWrite=IntPtr.Zero,input=IntPtr.Zero;
        PI process=new PI(); bool assigned=false,exited=false,initialized=false;
        bool outJoined=false,errJoined=false,jobZero=false;
        PipeCapture outCapture=null,errCapture=null;
        var clock=Stopwatch.StartNew(); double outerDeadline=operatorRemainingMilliseconds/1000.0;
        double cleanupDeadline=-1;
        try {
            job=CreateJobObjectW(IntPtr.Zero,null); if(job==IntPtr.Zero) throw new Win32Exception(Marshal.GetLastWin32Error(),"CreateJobObject");
            LIMIT limits=new LIMIT(); limits.basic.flags=KILL_ON_CLOSE|ACTIVE_LIMIT; limits.basic.activeLimit=1;
            WinCheck(SetInformationJobObject(job,9,ref limits,(uint)Marshal.SizeOf<LIMIT>()),"SetInformationJobObject");
            uint length; LIMIT effective=new LIMIT();
            WinCheck(QueryInformationJobObject(job,9,ref effective,(uint)Marshal.SizeOf<LIMIT>(),out length),"QueryInformationJobObject(limits)");
            if(length!=(uint)Marshal.SizeOf<LIMIT>() || effective.basic.flags!=(KILL_ON_CLOSE|ACTIVE_LIMIT) || effective.basic.activeLimit!=1)
                throw new InvalidDataException("Private job single-process limits differ");
            r["jobLimitFlags"]=effective.basic.flags; r["activeProcessLimit"]=effective.basic.activeLimit;
            r["privateUnnamedJob"]=true; r["jobHandleInherited"]=false;
            var sa=new SA{n=Marshal.SizeOf<SA>(),sd=IntPtr.Zero,inherit=true};
            NewPipe(ref outRead,ref outWrite,ref sa); NewPipe(ref errRead,ref errWrite,ref sa);
            outCapture=TakePipe(ref outRead,stdout,16384); errCapture=TakePipe(ref errRead,stderr,65536);
            input=CreateFileW("NUL",0x80000000,3,ref sa,3,0x80,IntPtr.Zero);
            if(input==InvalidHandle) throw new Win32Exception(Marshal.GetLastWin32Error(),"CreateFile(NUL)");
            IntPtr attrBytes=IntPtr.Zero; InitializeProcThreadAttributeList(IntPtr.Zero,2,0,ref attrBytes);
            if(attrBytes==IntPtr.Zero) throw new Win32Exception(Marshal.GetLastWin32Error(),"Attribute-list size");
            attr=Marshal.AllocHGlobal(attrBytes); WinCheck(InitializeProcThreadAttributeList(attr,2,0,ref attrBytes),"InitializeProcThreadAttributeList"); initialized=true;
            handles=Marshal.AllocHGlobal(IntPtr.Size*3); Marshal.WriteIntPtr(handles,0,input); Marshal.WriteIntPtr(handles,IntPtr.Size,outWrite); Marshal.WriteIntPtr(handles,IntPtr.Size*2,errWrite);
            WinCheck(UpdateProcThreadAttribute(attr,0,new IntPtr(0x20002),handles,new IntPtr(IntPtr.Size*3),IntPtr.Zero,IntPtr.Zero),"UpdateProcThreadAttribute(HANDLE_LIST)");
            // Associate the retained kill-on-close job inside process creation,
            // removing the worker-killed-before-Assign ownership gap. Win10+.
            jobList=Marshal.AllocHGlobal(IntPtr.Size); Marshal.WriteIntPtr(jobList,job);
            WinCheck(UpdateProcThreadAttribute(attr,0,new IntPtr(0x2000d),jobList,new IntPtr(IntPtr.Size),IntPtr.Zero,IntPtr.Zero),"UpdateProcThreadAttribute(JOB_LIST)");
            var startup=new SIX{info=new SI{cb=Marshal.SizeOf<SIX>(),flags=0x100|1,show=0,input=input,output=outWrite,error=errWrite},attributes=attr};
            var command=new StringBuilder(Quote(exe)); foreach(string argument in arguments) command.Append(' ').Append(Quote(argument));
            var vars=new SortedDictionary<string,string>(StringComparer.OrdinalIgnoreCase);
            foreach(System.Collections.DictionaryEntry entry in Environment.GetEnvironmentVariables()) {
                string key=(string)entry.Key;
                if(key.IndexOfAny(new[]{'\0','='})>=0 || key.Equals("UE_ADDITIONAL_PLUGIN_PATHS",StringComparison.OrdinalIgnoreCase) || key.Equals("UE-CmdLineArgs",StringComparison.OrdinalIgnoreCase) || System.Text.RegularExpressions.Regex.IsMatch(key,"TOKEN|PASSWORD|SECRET|API_KEY|CREDENTIAL",System.Text.RegularExpressions.RegexOptions.IgnoreCase)) continue;
                vars[key]=(string)entry.Value;
            }
            if(environment.Count!=0) throw new ArgumentException("P0 uses no caller environment overrides");
            vars["UE_ADDITIONAL_PLUGIN_PATHS"]=""; vars["UE-CmdLineArgs"]="";
            var block=new StringBuilder(); foreach(var pair in vars) block.Append(pair.Key).Append('=').Append(pair.Value).Append('\0'); block.Append('\0');
            env=Marshal.StringToHGlobalUni(block.ToString());
            if(outerDeadline-clock.Elapsed.TotalSeconds<65) throw new TimeoutException("No room for child60s and cleanup5s before external operator bound");
            outCapture.Start(); errCapture.Start();
            double creationCallStart=clock.Elapsed.TotalSeconds;
            r["creationCallStartedElapsedSeconds"]=creationCallStart;
            double runDeadline=creationCallStart+60;
            PI created=new PI();
            WinCheck(CreateProcessW(exe,command,IntPtr.Zero,IntPtr.Zero,true,CREATE_SUSPENDED|UNICODE_ENV|EXTENDED|NO_WINDOW,env,cwd,ref startup,out created),"CreateProcess(suspended/job-list)");
            process=created; assigned=true;
            r["creationJobAssociation"]="PROC_THREAD_ATTRIBUTE_JOB_LIST";
            r["pid"]=process.pid;
            long creation,exit,kernel,user; WinCheck(GetProcessTimes(process.process,out creation,out exit,out kernel,out user),"GetProcessTimes(creation)");
            r["creationFileTime"]=creation; r["creationUtc"]=DateTime.FromFileTimeUtc(creation).ToString("o");
            bool inside; WinCheck(IsProcessInJob(process.process,job,out inside),"IsProcessInJob");
            if(!inside) throw new InvalidDataException("Root not in retained private job");
            RequireSingle(Count(job,samples,"assigned-before-resume")); r["assignedBeforeResume"]=true;
            Close(ref outWrite,"stdout-parent-write",errors); Close(ref errWrite,"stderr-parent-write",errors);
            if(errors.Count!=0) throw new InvalidDataException("Inherited pipe-end closure failed");
            if(clock.Elapsed.TotalSeconds>=runDeadline) throw new TimeoutException("Creation/assignment consumed child deadline before resume");
            if(ResumeThread(process.thread)==INVALID) throw new Win32Exception(Marshal.GetLastWin32Error(),"ResumeThread");
            r["resumed"]=true; r["resumedObservationUtc"]=Utc();
            Close(ref process.thread,"root-thread",errors); Close(ref input,"stdin-original",errors);
            while(true) {
                if(outCapture.Faulted || errCapture.Faulted) throw new InvalidDataException("Bounded pipe overflow or reader failure");
                if(clock.Elapsed.TotalSeconds>=runDeadline) { r["timedOut"]=true; throw new TimeoutException("Python child60s deadline reached"); }
                uint waited=WaitForSingleObject(process.process,(uint)Math.Min(25,RemainingMilliseconds(clock,runDeadline)));
                if(waited!=WAIT_OBJECT_0 && waited!=WAIT_TIMEOUT) throw new Win32Exception(Marshal.GetLastWin32Error(),"WaitForSingleObject(root)");
                if(clock.Elapsed.TotalSeconds>=runDeadline) { r["timedOut"]=true; throw new TimeoutException("Python child60s deadline reached during wait"); }
                if(waited==WAIT_OBJECT_0) { RootFinal(process.process,r); exited=true; }
                ACCOUNT observation=new ACCOUNT(); uint observationBytes;
                WinCheck(QueryInformationJobObject(job,1,ref observation,(uint)Marshal.SizeOf<ACCOUNT>(),out observationBytes),"QueryInformationJobObject(loop)");
                if(observationBytes!=(uint)Marshal.SizeOf<ACCOUNT>()) throw new InvalidDataException("Loop accounting size mismatch");
                if(observation.total!=1 || observation.active>1 || observation.terminatedByLimit!=0) {
                    Count(job,samples,"unexpected-membership");
                    throw new InvalidDataException("Single-root job accounting differs");
                }
                if(exited) {
                    var count=Count(job,samples,"root-exit"); RequireSingle(count);
                    jobZero=(uint)count["activeProcesses"]==0;
                    r["rootExitWhileMembersActive"]=!jobZero;
                    if(!jobZero) throw new InvalidDataException("Root exit with unexpected active job member");
                    if((uint)r["exitCode"]!=0) throw new InvalidDataException("Python root exit unsuccessful");
                    break;
                }
                // Stable per-poll queries are not retained as new samples.
                // Assigned, exit, unexpected and final queries are retained.
            }
        } catch(Exception error) {
            if(error is TimeoutException) r["timedOut"]=true;
            r["primaryError"]=Error("owned-root",error);
            r["technicalBlocked"]=!(bool)r["resumed"] && error is Win32Exception;
        } finally {
            cleanupDeadline=Math.Min(outerDeadline,clock.Elapsed.TotalSeconds+5);
            r["cleanupStartedElapsedSeconds"]=clock.Elapsed.TotalSeconds;
            r["cleanupDeadlineElapsedSeconds"]=cleanupDeadline;
            // No window enumeration/messages, PID reopening, name search or Kill(true).
            if(process.pid!=0 && (!exited || !jobZero || r["primaryError"]!=null)) {
                try {
                    if(assigned) WinCheck(TerminateJobObject(job,0xa2f00001),"TerminateJobObject(failure)");
                    else if(process.process!=IntPtr.Zero) WinCheck(TerminateProcess(process.process,0xa2f00002),"TerminateProcess(original-suspended-root)");
                    shutdown.Add(new Dictionary<string,object>{{"operation",assigned ? "TerminateJobObject" : "TerminateProcess(original-suspended-root)"},{"observedUtc",Utc()}});
                } catch(Exception error) { errors.Add(Error("failure-termination",error)); }
            }
            Close(ref outWrite,"stdout-parent-write",errors); Close(ref errWrite,"stderr-parent-write",errors);
            try {
                while(process.pid!=0 && clock.Elapsed.TotalSeconds<cleanupDeadline) {
                    if(!exited && process.process!=IntPtr.Zero) {
                        uint waited=WaitForSingleObject(process.process,(uint)Math.Min(20,RemainingMilliseconds(clock,cleanupDeadline)));
                        if(waited!=WAIT_OBJECT_0 && waited!=WAIT_TIMEOUT) throw new Win32Exception(Marshal.GetLastWin32Error(),"WaitForSingleObject(cleanup)");
                        if(waited==WAIT_OBJECT_0) { RootFinal(process.process,r); exited=true; }
                    }
                    if(job!=IntPtr.Zero) {
                        var final=Count(job,samples,"final-job");
                        jobZero=(uint)final["activeProcesses"]==0;
                        if(assigned) RequireSingle(final);
                    }
                    if(exited && jobZero) break;
                    Thread.Sleep(Math.Min(10,RemainingMilliseconds(clock,cleanupDeadline)));
                }
                if(process.pid==0 && job!=IntPtr.Zero) jobZero=(uint)Count(job,samples,"no-root-final-job")["activeProcesses"]==0;
            } catch(Exception error) { errors.Add(Error("failure-cleanup",error)); }
            try { if(outCapture!=null) outJoined=outCapture.Join(RemainingMilliseconds(clock,cleanupDeadline)); }
            catch(Exception error) { errors.Add(Error("stdout-join",error)); }
            try { if(errCapture!=null) errJoined=errCapture.Join(RemainingMilliseconds(clock,cleanupDeadline)); }
            catch(Exception error) { errors.Add(Error("stderr-join",error)); }
            r["stdoutCapture"]=outCapture==null ? null : outCapture.Record(outJoined);
            r["stderrCapture"]=errCapture==null ? null : errCapture.Record(errJoined);
            bool streams=outCapture!=null && errCapture!=null && outJoined && errJoined &&
                (bool)outCapture.Record(outJoined)["complete"] && (bool)errCapture.Record(errJoined)["complete"];
            r["streamsComplete"]=streams;
            r["cleanupConfirmed"]=process.pid!=0 && exited && jobZero && outJoined && errJoined;
            r["finalActiveJobCountObserved"]=jobZero ? (object)0 : null;
            r["readerJoinUncertainty"]=!outJoined || !errJoined;
            // Failed reader joins remain incomplete; background readers die with
            // this fresh operator process. The required outer watchdog owns it.
            Close(ref process.thread,"root-thread",errors); Close(ref process.process,"root-process",errors);
            Close(ref outRead,"stdout-untransferred-read",errors); Close(ref errRead,"stderr-untransferred-read",errors); Close(ref input,"stdin-original",errors);
            if(initialized) DeleteProcThreadAttributeList(attr);
            if(attr!=IntPtr.Zero) Marshal.FreeHGlobal(attr); if(handles!=IntPtr.Zero) Marshal.FreeHGlobal(handles); if(jobList!=IntPtr.Zero) Marshal.FreeHGlobal(jobList); if(env!=IntPtr.Zero) Marshal.FreeHGlobal(env);
            Close(ref job,"private-job",errors);
            r["cleanupElapsedSeconds"]=clock.Elapsed.TotalSeconds-(double)r["cleanupStartedElapsedSeconds"];
            r["cleanupWithinBudget"]=clock.Elapsed.TotalSeconds<=cleanupDeadline;
            if(!(bool)r["cleanupWithinBudget"]) r["cleanupConfirmed"]=false;
            r["completedObservationUtc"]=Utc(); r["elapsedSeconds"]=clock.Elapsed.TotalSeconds;
            r["status"]=(r["primaryError"]==null && errors.Count==0 && (bool)r["exitConfirmed"] &&
                (bool)r["cleanupConfirmed"] && streams && !(bool)r["timedOut"] && clock.Elapsed.TotalSeconds<=outerDeadline) ? "PASS" : "FAIL";
        }
        return r;
    }
}
}
