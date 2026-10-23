# Guarded canonical payload outer. Defaults are UNBOUND; exact SOURCE and GO required.
[CmdletBinding()]
param(
 [string]$BindingPath='__UNBOUND__',
 [string]$ExpectedBindingSha256='__UNBOUND__',
 [string]$AuthorityPath='__UNBOUND__',
 [string]$ExpectedAuthoritySha256='__UNBOUND__',
 [string]$Nonce='__UNBOUND__'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
foreach($v in @($BindingPath,$ExpectedBindingSha256,$AuthorityPath,$ExpectedAuthoritySha256,$Nonce)){
 if([string]::IsNullOrWhiteSpace($v)-or$v.Contains('__UNBOUND')){throw 'P0_OUTER_BINDINGS_REQUIRED'}
}
if($ExpectedBindingSha256-notmatch'^[A-F0-9]{64}$'-or$ExpectedAuthoritySha256-notmatch'^[A-F0-9]{64}$'-or$Nonce-notmatch'^[a-f0-9]{32}$'){throw 'P0_OUTER_BINDING_FORMAT'}
$startedUtc=[DateTime]::UtcNow.ToString('o')
$clock=[Diagnostics.Stopwatch]::StartNew()
$repo='C:/SWDev/warhammer/Warhammer_40k_UI_unreal'
$hostPath='C:/Users/Rabid/.cache/codex-runtimes/codex-primary-runtime/dependencies/native/powershell/pwsh.exe'
$hostHash='362A356CE7F0940EC74F73A8FC2C990A2CC24A38A11C90BBD8ECA947110AD139'
$utf8=[Text.UTF8Encoding]::new($false,$true)
function Plain-Path([string]$Path){
 if(-not[IO.Path]::IsPathFullyQualified($Path)){throw 'P0_OUTER_ABSOLUTE_PATH_REQUIRED'}
 $p=[IO.Path]::GetFullPath($Path);$cursor=$p
 while($cursor){
  if(Test-Path -LiteralPath $cursor){if(([IO.File]::GetAttributes($cursor)-band[IO.FileAttributes]::ReparsePoint)-ne0){throw 'P0_OUTER_REPARSE_REFUSED'}}
  $parent=[IO.Directory]::GetParent($cursor);$cursor=if($parent){$parent.FullName}else{''}
 }
 return $p
}
function File-Descriptor([string]$Path,[long]$Cap=4194304){
 $p=Plain-Path $Path;$f=Get-Item -LiteralPath $p
 if($f.PSIsContainer-or$f.Length-gt$Cap){throw 'P0_OUTER_FILE_KIND_OR_CAP'}
 return @{path=$p;bytes=$f.Length;sha256=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash}
}
function Assert-Descriptor($Expected,[long]$Cap=4194304){
 $d=File-Descriptor $Expected.path $Cap
 if($d.bytes-ne$Expected.bytes-or$d.sha256-ine$Expected.sha256){throw 'P0_OUTER_DESCRIPTOR_DRIFT'}
 return $d
}
function True-Flag($Value){return ($Value-is[bool]-and$Value)}
function False-Flag($Value){return ($Value-is[bool]-and-not$Value)}
function Zero-Integer($Value){return (($Value-is[int]-or$Value-is[long])-and$Value-eq0)}
function Assert-Entries([string]$Directory,[string[]]$Expected){
 $count=0
 foreach($p in [IO.Directory]::EnumerateFileSystemEntries($Directory)){
  $count++;if($count-gt$Expected.Count-or$p-notin$Expected){throw 'P0_OUTER_EXACT_FIVE_PATH_FAMILY_REQUIRED'}
 }
 if($count-ne$Expected.Count){throw 'P0_OUTER_EXACT_FIVE_PATH_FAMILY_REQUIRED'}
}
function Reader-State($Reader,[int]$Cap){
 $buffer=[char[]]::new(256)
 return @{reader=$Reader;buffer=$buffer;task=$Reader.ReadAsync($buffer,0,$buffer.Length);prefix=[Text.StringBuilder]::new();cap=$Cap;chars=0L;capped=$false;complete=$false;error=$null}
}
function Poll-Reader($R){
 if($R.complete-or$R.error-or-not$R.task.IsCompleted){return}
 if($R.task.IsFaulted){$R.error=$R.task.Exception.GetBaseException().GetType().FullName;return}
 if($R.task.IsCanceled){$R.error='READ_CANCELED';return}
 # Result cannot block here: IsCompleted was true and fault/cancellation excluded.
 $n=$R.task.Result
 if($n-eq0){$R.complete=$true;$R.task=$null;return}
 $R.chars+=$n;$keep=[Math]::Min($n,[Math]::Max(0,$R.cap-$R.prefix.Length))
 if($keep-gt0){[void]$R.prefix.Append($R.buffer,0,$keep)}
 if($keep-ne$n){$R.capped=$true}
 $R.task=$R.reader.ReadAsync($R.buffer,0,$R.buffer.Length)
}
$bindingFile=File-Descriptor $BindingPath
$authorityFile=File-Descriptor $AuthorityPath
if($bindingFile.sha256-ine$ExpectedBindingSha256-or$authorityFile.sha256-ine$ExpectedAuthoritySha256){throw 'P0_OUTER_BINDING_OR_AUTHORITY_HASH'}
$b=Get-Content -LiteralPath $bindingFile.path -Raw|ConvertFrom-Json -AsHashtable -DateKind String
$a=Get-Content -LiteralPath $authorityFile.path -Raw|ConvertFrom-Json -AsHashtable -DateKind String
if($b.recordKind-cne'A2P0_CANONICAL_CAPTURE_BINDING'-or$b.state-cne'BOUND_DATA_ONLY_NOT_EXECUTION_AUTHORITY'-or$a.recordKind-cne'ROOT_A2P0_CANONICAL_CAPTURE_GO'-or-not(True-Flag $a.explicitCoordinatorGo)-or-not(True-Flag $a.sourceApprovedByRoot)-or-not(True-Flag $a.outerWatchdogRequired)-or$a.allowedAction-cne'ONE_MINIMUM_CANONICAL_PAYLOAD_REFERENCE_CAPTURE'-or$a.outerDeadlineSeconds-ne75){throw 'P0_OUTER_EXACT_GO_REQUIRED'}
foreach($key in @('sourceHead','sourceBase','runId','nonce')){if($b[$key]-cne$a[$key]){throw 'P0_OUTER_AUTHORITY_SUBJECT_MISMATCH'}}
if($b.nonce-cne$Nonce-or$b.runId-notmatch'^[0-9]{8}T[0-9]{6}Z-[0-9a-f]{8}$'){throw 'P0_OUTER_NONCE_OR_RUN'}
$bound=Assert-Descriptor $a.binding
if($bound.path-ine$bindingFile.path-or$bound.sha256-ine$bindingFile.sha256){throw 'P0_OUTER_AUTHORITY_BINDING_MISMATCH'}
$outer=Assert-Descriptor $b.outerSource;$outerGo=Assert-Descriptor $a.outerSource
if($outer.path-ine(Plain-Path $PSCommandPath)-or$outerGo.path-ine$outer.path-or$outerGo.sha256-ine$outer.sha256){throw 'P0_OUTER_EXACT_SOURCE_REQUIRED'}
$hostD=Assert-Descriptor $b.powerShellExecutable
if($hostD.path-ine(Plain-Path $hostPath)-or$hostD.bytes-ne301368-or$hostD.sha256-ine$hostHash){throw 'P0_OUTER_PINNED_PWSH_REQUIRED'}
$worker=Assert-Descriptor $b.workerSource
[void](Assert-Descriptor $b.supervisorSource);[void](Assert-Descriptor $b.collectorSource);[void](Assert-Descriptor $b.referenceData);[void](Assert-Descriptor $a.sourceAdmission)
$family=Plain-Path (Join-Path $repo '.local/experiments/A2P0')
$runRoot=Plain-Path $b.runRoot;$captureRoot=Plain-Path $b.captureRoot
if(-not[IO.Directory]::Exists($family)-or$runRoot-ine(Join-Path $family $b.runId)-or$captureRoot-ine(Join-Path $runRoot 'capture')-or(Test-Path -LiteralPath $runRoot)){throw 'P0_OUTER_NEW_OWNED_RUN_REQUIRED'}
$paths=@{capture=(Join-Path $captureRoot 'reference-capture.json');stdout=(Join-Path $runRoot 'stdout.original.txt');stderr=(Join-Path $runRoot 'stderr.original.txt');process=(Join-Path $runRoot 'process-receipt.original.json');outer=(Join-Path $runRoot 'execution-receipt.original.json')}
$caps=@{capture=2093056L;stdout=16384L;stderr=65536L;process=131072L}
# One absent RunRoot is claimed without creating the experiment family.
if($clock.Elapsed.TotalSeconds-ge70){throw 'P0_OUTER_PREFLIGHT_DEADLINE'}
$claimed=New-Item -ItemType Directory -Path $runRoot -ErrorAction Stop
$start=[Diagnostics.ProcessStartInfo]::new($hostD.path)
$start.UseShellExecute=$false;$start.CreateNoWindow=$true;$start.WindowStyle=[Diagnostics.ProcessWindowStyle]::Hidden
$start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true
$start.StandardOutputEncoding=$utf8;$start.StandardErrorEncoding=$utf8;$start.WorkingDirectory=$repo
foreach($arg in @('-NoLogo','-NoProfile','-NonInteractive','-File',$worker.path,'-BindingPath',$bindingFile.path,'-ExpectedBindingSha256',$ExpectedBindingSha256,'-AuthorityPath',$authorityFile.path,'-ExpectedAuthoritySha256',$ExpectedAuthoritySha256,'-Nonce',$Nonce)){[void]$start.ArgumentList.Add($arg)}
$process=[Diagnostics.Process]::new();$process.StartInfo=$start
# The clock began before binding reads and before this worker can execute Add-Type.
$started=$false;$exited=$false;$forced=$false;$timedOut=$false;$success=$false
$stdout=$null;$stderr=$null;$failure=$null;$pidValue=$null;$exitCode=$null;$completion=$null;$processReceipt=$null;$files=@{}
try{
 if(-not$process.Start()){throw 'P0_OUTER_WORKER_START_FALSE'};$started=$true;$pidValue=$process.Id
 $stdout=Reader-State $process.StandardOutput 4096;$stderr=Reader-State $process.StandardError 1024
 while($clock.Elapsed.TotalSeconds-lt70){
  Poll-Reader $stdout;Poll-Reader $stderr;$exited=$process.HasExited
  if($stdout.capped-or$stderr.capped-or$stdout.error-or$stderr.error){throw 'P0_OUTER_STREAM_CAP_OR_READER_ERROR'}
  if($exited-and$stdout.complete-and$stderr.complete){break}
  [Threading.Thread]::Sleep(10)
 }
 if(-not($exited-and$stdout.complete-and$stderr.complete)){$timedOut=$true;throw 'P0_OUTER_WORK_DEADLINE'}
 $exitCode=$process.ExitCode
 $text=$stdout.prefix.ToString().TrimEnd([char]13,[char]10)
 if(-not(Zero-Integer $exitCode)-or$stderr.chars-ne0-or$utf8.GetByteCount($text)-gt4096-or$text-match'[\r\n]'){throw 'P0_OUTER_NONZERO_OR_COMPLETION_STREAM'}
 $completion=$text|ConvertFrom-Json -AsHashtable -DateKind String
 foreach($key in @('sourceHead','runId','nonce')){if($completion[$key]-cne$b[$key]){throw 'P0_OUTER_COMPLETION_SUBJECT'}}
 if($completion.recordKind-cne'A2P0_WORKER_CLOSED_NOT_ACCEPTANCE'-or$completion.status-cne'PASS_CAPTURE_CLOSED_NOT_ACCEPTED'-or-not(Zero-Integer $completion.exitCode)-or-not(True-Flag $completion.cleanupConfirmed)-or-not(Zero-Integer $completion.finalActiveJobCountObserved)-or-not(True-Flag $completion.streamsComplete)-or-not(True-Flag $completion.processReceipt.complete)-or$completion.processReceipt.relativePath-cne'process-receipt.original.json'){throw 'P0_OUTER_POSITIVE_WORKER_COMPLETION_REQUIRED'}
 foreach($key in @('capture','stdout','stderr','process')){
  if($clock.Elapsed.TotalSeconds-ge75){throw 'P0_OUTER_TOTAL_DEADLINE'}
  $files[$key]=File-Descriptor $paths[$key] $caps[$key]
 }
 if($files.process.bytes-ne$completion.processReceipt.bytes-or$files.process.sha256-ine$completion.processReceipt.sha256){throw 'P0_OUTER_PROCESS_RECEIPT_JOIN'}
 $processReceipt=Get-Content -LiteralPath $paths.process -Raw|ConvertFrom-Json -AsHashtable -DateKind String
 foreach($key in @('sourceHead','runId','nonce')){if($processReceipt[$key]-cne$b[$key]){throw 'P0_OUTER_PROCESS_RECEIPT_SUBJECT'}}
 if($processReceipt.recordKind-cne'A2P0_OWNED_PYTHON_JOB_PROCESS_RESULT_NOT_ACCEPTANCE'-or$processReceipt.status-cne'PASS'-or-not(True-Flag $processReceipt.exitConfirmed)-or-not(True-Flag $processReceipt.assignedBeforeResume)-or-not(True-Flag $processReceipt.resumed)-or-not(Zero-Integer $processReceipt.exitCode)-or-not(False-Flag $processReceipt.timedOut)-or-not(True-Flag $processReceipt.cleanupConfirmed)-or-not(True-Flag $processReceipt.streamsComplete)-or-not(Zero-Integer $processReceipt.finalActiveJobCountObserved)-or-not(False-Flag $processReceipt.readerJoinUncertainty)-or-not$processReceipt.ContainsKey('primaryError')-or$null-ne$processReceipt.primaryError-or-not$processReceipt.ContainsKey('secondaryErrors')-or$processReceipt.secondaryErrors-isnot[array]-or$processReceipt.secondaryErrors.Count-ne0){throw 'P0_OUTER_POSITIVE_PYTHON_RECEIPT_REQUIRED'}
 Assert-Entries $runRoot @($captureRoot,$paths.stdout,$paths.stderr,$paths.process)
 Assert-Entries $captureRoot @($paths.capture)
 if($clock.Elapsed.TotalSeconds-ge75){throw 'P0_OUTER_TOTAL_DEADLINE'}
 $success=$true
}catch{
 $failure=@{type=$_.Exception.GetType().FullName;message=$_.Exception.Message.Substring(0,[Math]::Min(256,$_.Exception.Message.Length))}
 if($started){
  $cleanupDeadline=[Math]::Min(75.0,$clock.Elapsed.TotalSeconds+5.0)
  try{if(-not$process.HasExited){$process.Kill();$forced=$true}}catch{$failure.terminationError=$_.Exception.GetType().FullName}
  while($clock.Elapsed.TotalSeconds-lt$cleanupDeadline){
   if($stdout){Poll-Reader $stdout};if($stderr){Poll-Reader $stderr}
   $exited=$process.HasExited
   if($exited-and$stdout-and$stderr-and$stdout.complete-and$stderr.complete){break}
   [Threading.Thread]::Sleep(10)
  }
 }
}finally{
 if($started){try{$exited=$process.HasExited;if($exited){$exitCode=$process.ExitCode}}catch{$exited=$false}}
 if($forced-or$timedOut-or-not$exited-or-not$stdout-or-not$stderr-or-not$stdout.complete-or-not$stderr.complete-or$stdout.capped-or$stderr.capped-or$stdout.error-or$stderr.error-or$clock.Elapsed.TotalSeconds-ge75){$success=$false}
 $storage=@{};$observedTotal=0L
 foreach($key in $caps.Keys){
  try{
   if([IO.File]::Exists($paths[$key])){
    $length=[IO.FileInfo]::new($paths[$key]).Length;$observedTotal+=$length
    $storage[$key]=@{observedBytes=$length;cap=$caps[$key];closed=$exited}
    if($length-gt$caps[$key]){$success=$false;$storage[$key].capExceeded=$true}
   }else{$storage[$key]=@{exists=$false;closed=$exited}}
  }catch{$success=$false;$storage[$key]=@{observationError=$_.Exception.GetType().FullName}}
 }
 if($clock.Elapsed.TotalSeconds-ge75){$success=$false;$timedOut=$true}
 $completionJoin=if($completion){@{recordKind=$completion.recordKind;status=$completion.status;runId=$completion.runId;sourceHead=$completion.sourceHead;nonce=$completion.nonce;processReceipt=$completion.processReceipt}}else{$null}
 $record=[ordered]@{recordKind='A2P0_OUTER_OPERATOR_CLOSED_NOT_ACCEPTANCE';status=if($success){'PASS_CAPTURE_CLOSED_NOT_ACCEPTED'}else{'FAIL'};sourceHead=$b.sourceHead;runId=$b.runId;nonce=$Nonce;binding=$bindingFile;authority=$authorityFile;outerSource=$outer;workerSource=$worker;collectorSource=$b.collectorSource;referenceData=$b.referenceData;sourceAdmission=$a.sourceAdmission;startedUtc=$startedUtc;closedUtc=[DateTime]::UtcNow.ToString('o');operatorPid=$PID;workerPid=$pidValue;workerExitConfirmed=$exited;workerExitCode=$exitCode;forcedRootTermination=$forced;timedOut=$timedOut;workBudgetSeconds=70;totalBudgetSeconds=75;elapsedSeconds=$clock.Elapsed.TotalSeconds;failure=$failure;workerStdout=if($stdout){@{prefix=$stdout.prefix.ToString();observedChars=$stdout.chars;capped=$stdout.capped;complete=$stdout.complete;readerError=$stdout.error}}else{$null};workerStderr=if($stderr){@{prefix=$stderr.prefix.ToString();observedChars=$stderr.chars;capped=$stderr.capped;complete=$stderr.complete;readerError=$stderr.error}}else{$null};completionLine=$completionJoin;closedFiles=$files;storageObservations=$storage;positivePythonCleanupReceiptJoined=($success-and-not$forced);limits='Normal finite supervision only. Forced outer termination never establishes successful Python/job cleanup. Missing/open/capped streams or receipts fail. No acceptance, publication, visible-window or successor authority.'}
 $receiptBytes=$utf8.GetBytes(($record|ConvertTo-Json -Depth 16)+"`n")
 if($receiptBytes.Length-gt65536-or$observedTotal+$receiptBytes.Length-gt4194304){
  $success=$false;$record=@{recordKind='A2P0_OUTER_OPERATOR_CLOSED_NOT_ACCEPTANCE';status='FAIL';sourceHead=$b.sourceHead;runId=$b.runId;nonce=$Nonce;failure='P0_OUTER_RECEIPT_OR_RUNROOT_CAP';workerPid=$pidValue;workerExitConfirmed=$exited;forcedRootTermination=$forced;positivePythonCleanupReceiptJoined=$false;prefixesShortenedForReceiptCap=$true;workerStdout=if($stdout){@{prefix=$stdout.prefix.ToString().Substring(0,[Math]::Min(256,$stdout.prefix.Length));complete=$stdout.complete;capped=$stdout.capped;readerError=$stdout.error}}else{$null};workerStderr=if($stderr){@{prefix=$stderr.prefix.ToString().Substring(0,[Math]::Min(256,$stderr.prefix.Length));complete=$stderr.complete;capped=$stderr.capped;readerError=$stderr.error}}else{$null}}
  $receiptBytes=$utf8.GetBytes(($record|ConvertTo-Json -Depth 6)+"`n")
 }
 $stream=[IO.File]::Open($paths.outer,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
 try{$stream.Write($receiptBytes,0,$receiptBytes.Length)}finally{$stream.Dispose();$process.Dispose()}
}
[Console]::Out.WriteLine((@{recordKind='A2P0_OUTER_COMPLETION_NOT_ACCEPTANCE';runId=$b.runId;status=$record.status;workerPid=$pidValue}|ConvertTo-Json -Compress))
if($success){exit 0};exit 1
