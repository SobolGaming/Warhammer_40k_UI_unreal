# Guarded canonical payload worker. This script creates no authority or binding.
# A separately bound/source-reviewed retained-process outer watchdog is REQUIRED.
# This worker does not enforce the hard75s outer wall by checking its own clock.
[CmdletBinding()]
param(
    [string]$BindingPath='__UNBOUND_BINDING_PATH__',
    [string]$ExpectedBindingSha256='__UNBOUND_BINDING_SHA256__',
    [string]$AuthorityPath='__UNBOUND_AUTHORITY_PATH__',
    [string]$ExpectedAuthoritySha256='__UNBOUND_AUTHORITY_SHA256__',
    [string]$Nonce='__UNBOUND_OUTER_SUBJECT_NONCE__'
)
# Refuse the proposal before input reads, Add-Type or any process creation.
foreach($value in @($BindingPath,$ExpectedBindingSha256,$AuthorityPath,$ExpectedAuthoritySha256,$Nonce)){
    if([string]::IsNullOrWhiteSpace($value) -or $value.Contains('__UNBOUND')){throw 'UNBOUND P0 source proposal; do not execute'}
}
if($ExpectedBindingSha256 -cnotmatch '^[0-9A-F]{64}$' -or $ExpectedAuthoritySha256 -cnotmatch '^[0-9A-F]{64}$' -or $Nonce -cnotmatch '^[0-9a-f]{32}$'){throw 'Exact binding/authority hashes and nonce required'}
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$taskClock=[Diagnostics.Stopwatch]::StartNew()
$taskUtf8=[Text.UTF8Encoding]::new($false,$true)
$taskFamily='C:\SWDev\warhammer\Warhammer_40k_UI_unreal\.local\experiments\A2P0'
$taskBasePython='C:\Users\Rabid\AppData\Roaming\uv\python\cpython-3.14.5-windows-x86_64-none\python.exe'
$taskBaseSha='5556F2048A17B14693FFADEB25DC0ADD537933873CEE2CA623CF981CA65A6168'
$taskRoot=$null;$taskRunId=$null;$taskHead=$null;$taskProcess=$null;$taskReceiptDescriptor=$null
$taskCaptureDescriptor=$null;$taskStdoutDescriptor=$null;$taskStderrDescriptor=$null
$taskFailure=$null;$taskExit=1;$taskStatus='FAIL_CAPTURE_NOT_ACCEPTED';$taskData=$null
function Task-Tick {
    if($taskClock.Elapsed.TotalSeconds -ge 70){throw 'P0 cooperative70s work budget exhausted; external watchdog still required'}
}
function Task-Path([string]$Path){
    if([string]::IsNullOrWhiteSpace($Path) -or $Path.Contains('__UNBOUND') -or ![IO.Path]::IsPathFullyQualified($Path)){throw 'Unbound or nonabsolute path'}
    [IO.Path]::GetFullPath($Path).TrimEnd([char]92,[char]47)
}
function Task-SamePath([string]$Left,[string]$Right){[StringComparer]::OrdinalIgnoreCase.Equals((Task-Path $Left),(Task-Path $Right))}
function Task-Descriptor([string]$Path){
    Task-Tick
    $item=Get-Item -LiteralPath (Task-Path $Path)
    if($item.PSIsContainer){throw 'Descriptor names a directory'}
    [ordered]@{path=$item.FullName;bytes=$item.Length;sha256=(Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash}
}
function Task-CheckDescriptor($Descriptor){
    if($Descriptor -isnot [Collections.IDictionary] -or $Descriptor.path -isnot [string] -or $Descriptor.sha256 -cnotmatch '^[0-9A-F]{64}$' -or
       ($Descriptor.bytes -isnot [int] -and $Descriptor.bytes -isnot [long]) -or $Descriptor.bytes -lt 0){throw 'Invalid exact descriptor'}
    $actual=Task-Descriptor $Descriptor.path
    if($actual.bytes -ne $Descriptor.bytes -or $actual.sha256 -cne $Descriptor.sha256){throw 'Frozen descriptor mismatch'}
}
function Task-MatchDescriptor($Left,$Right){
    if(!(Task-SamePath $Left.path $Right.path) -or $Left.bytes -ne $Right.bytes -or $Left.sha256 -cne $Right.sha256){throw 'Descriptor join mismatch'}
}
function Task-ReadJson([string]$Path,[long]$Maximum){
    Task-Tick
    if([IO.FileInfo]::new((Task-Path $Path)).Length -gt $Maximum){throw 'JSON input exceeds exact read cap'}
    $bytes=[IO.File]::ReadAllBytes((Task-Path $Path))
    if($bytes.Length -gt $Maximum){throw 'JSON input exceeds exact read cap'}
    $taskUtf8.GetString($bytes)|ConvertFrom-Json -AsHashtable -Depth 100
}
function Task-True($Value){if($Value -isnot [bool] -or $Value -ne $true){throw 'Explicit Boolean true required'}}
function Task-WriteProcessReceipt($Value){
    Task-Tick
    $bytes=$taskUtf8.GetBytes(($Value|ConvertTo-Json -Depth 100 -Compress)+"`n")
    $retained=[Math]::Min($bytes.Length,131072)
    $path=Join-Path $taskRoot 'process-receipt.original.json'
    $stream=[IO.FileStream]::new($path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
    try{$stream.Write($bytes,0,$retained)}finally{$stream.Dispose()}
    $descriptor=Task-Descriptor $path
    [ordered]@{relativePath='process-receipt.original.json';bytes=$descriptor.bytes;sha256=$descriptor.sha256;complete=($bytes.Length -le 131072);encodedBytes=$bytes.Length}
}
function Task-RelativeDescriptor([string]$Relative){
    $d=Task-Descriptor (Join-Path $taskRoot $Relative)
    [ordered]@{relativePath=$Relative;bytes=$d.bytes;sha256=$d.sha256}
}
try{
    $bindingActual=Task-Descriptor $BindingPath
    if($bindingActual.sha256 -cne $ExpectedBindingSha256){throw 'Binding hash mismatch'}
    $authorityActual=Task-Descriptor $AuthorityPath
    if($authorityActual.sha256 -cne $ExpectedAuthoritySha256){throw 'Authority hash mismatch'}
    $binding=Task-ReadJson $BindingPath 131072
    $authority=Task-ReadJson $AuthorityPath 131072
    if($binding.recordKind -cne 'A2P0_CANONICAL_CAPTURE_BINDING' -or $binding.state -cne 'BOUND_DATA_ONLY_NOT_EXECUTION_AUTHORITY' -or
       $authority.recordKind -cne 'ROOT_A2P0_CANONICAL_CAPTURE_GO' -or $authority.allowedAction -cne 'ONE_MINIMUM_CANONICAL_PAYLOAD_REFERENCE_CAPTURE'){
        throw 'Wrong P0 binding or authority kind'
    }
    Task-True $authority.explicitCoordinatorGo
    Task-True $authority.sourceApprovedByRoot
    Task-True $authority.outerWatchdogRequired
    if($authority.outerDeadlineSeconds -ne 75 -or $binding.nonce -cne $Nonce -or $authority.nonce -cne $Nonce){throw 'Outer deadline/nonce join mismatch'}
    Task-MatchDescriptor $authority.binding $bindingActual
    foreach($field in @('sourceHead','sourceBase','runId')){if($binding[$field] -cne $authority[$field]){throw 'Source/run join mismatch'}}
    if($binding.sourceHead -cnotmatch '^[0-9a-f]{40}$' -or $binding.sourceBase -cnotmatch '^[0-9a-f]{40}$' -or $binding.runId -cnotmatch '^[0-9]{8}T[0-9]{6}Z-[0-9a-f]{8}$'){throw 'Exact subject identities required'}
    $taskRunId=$binding.runId;$taskHead=$binding.sourceHead
    # The exact outer source/authority is mandatory. Its nonce/metadata is a join,
    # not proof the external retained-process watchdog is actually enforcing75s.
    foreach($descriptor in @($binding.workerSource,$binding.supervisorSource,$binding.collectorSource,$binding.outerSource,$binding.powerShellExecutable,$binding.referenceData,$authority.sourceAdmission)){
        Task-CheckDescriptor $descriptor
    }
    Task-MatchDescriptor $authority.outerSource $binding.outerSource
    if(!(Task-SamePath $PSCommandPath $binding.workerSource.path) -or !(Task-SamePath ([Environment]::ProcessPath) $binding.powerShellExecutable.path)){throw 'Exact fresh worker/PowerShell source host mismatch'}
    $taskRoot=Task-Path $binding.runRoot
    if(!(Task-SamePath $taskRoot (Join-Path $taskFamily $taskRunId)) -or !(Task-SamePath $binding.captureRoot (Join-Path $taskRoot 'capture'))){throw 'Wrong owned output roots'}
    foreach($directory in @($taskFamily,$taskRoot)){
        $item=Get-Item -LiteralPath $directory
        if(!$item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)){throw 'Existing owned non-reparse output directory required'}
    }
    if(@(Get-ChildItem -LiteralPath $taskRoot -Force).Count -ne 0){throw 'Outer-created RunRoot must be empty before worker'}
    $taskData=Task-ReadJson $binding.referenceData.path 131072
    if($taskData.state -cne 'BOUND_DATA_ONLY_NOT_EXECUTION_AUTHORITY' -or $taskData.captureScope -cne 'PAYLOAD_SEMANTICS_ONLY' -or
       !(Task-SamePath $taskData.outputRoot $binding.captureRoot) -or $taskData.runtime.version -cne '3.14.5'){
        throw 'Wrong exact payload data context'
    }
    if(!(Task-SamePath $taskData.runtime.python.path $taskBasePython) -or $taskData.runtime.python.bytes -ne 91648 -or $taskData.runtime.python.sha256 -cne $taskBaseSha){throw 'Fixed direct base interpreter required; no launcher fallback'}
    if(@($taskData.inputs).Count -ne 10 -or @($taskData.documentCopies).Count -ne 6 -or @($taskData.originalModules).Count -ne 9 -or @($taskData.yamlModules).Count -ne 16){throw 'Exact canonical/module membership count required'}
    $descriptors=@($taskData.runtime.python,$taskData.runtime.venvConfiguration,$taskData.colorProjection.sourceDescriptor)
    foreach($entry in @($taskData.inputs)+@($taskData.documentCopies)+@($taskData.originalModules)+@($taskData.yamlModules)){$descriptors+=,$entry.descriptor}
    foreach($descriptor in $descriptors){Task-CheckDescriptor $descriptor}
    if('Warhammer.A2P0.Supervisor' -as [type]){throw 'Fresh worker PowerShell process required'}
    Task-Tick
    Add-Type -TypeDefinition ([IO.File]::ReadAllText($binding.supervisorSource.path)) -Language CSharp -ErrorAction Stop
    Task-Tick
    $remaining=[int][Math]::Floor((70-$taskClock.Elapsed.TotalSeconds)*1000)
    if($remaining -lt 65000){throw 'No room for child60s/cleanup5s inside cooperative work budget'}
    $environment=[Collections.Generic.Dictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
    $arguments=[string[]]@('-I','-B','-S',(Task-Path $binding.collectorSource.path))
    $taskProcess=[Warhammer.A2P0.Supervisor]::Run($taskBasePython,$arguments,$taskRoot,$environment,
        (Join-Path $taskRoot 'stdout.original.txt'),(Join-Path $taskRoot 'stderr.original.txt'),60,$false,'',$remaining)
    $taskProcess['sourceHead']=$taskHead;$taskProcess['runId']=$taskRunId;$taskProcess['nonce']=$Nonce
    $taskProcess['sourceBase']=$binding.sourceBase;$taskProcess['boundCollector']=$binding.collectorSource
    $taskProcess['boundData']=$binding.referenceData;$taskProcess['authority']=$authorityActual;$taskProcess['sourceAdmission']=$authority.sourceAdmission
    $taskReceiptDescriptor=Task-WriteProcessReceipt $taskProcess
    if(!$taskReceiptDescriptor.complete){throw 'Process receipt retained only a bounded prefix; incomplete result'}
    if($taskProcess.status -cne 'PASS' -or !$taskProcess.exitConfirmed -or $taskProcess.exitCode -ne 0 -or $taskProcess.timedOut -or
       !$taskProcess.assignedBeforeResume -or !$taskProcess.resumed -or !$taskProcess.cleanupConfirmed -or !$taskProcess.streamsComplete -or
       $taskProcess.finalActiveJobCountObserved -ne 0 -or $taskProcess.readerJoinUncertainty -or $null -ne $taskProcess.primaryError -or @($taskProcess.secondaryErrors).Count){
        throw 'Python process/stream/job closure failed; preserve original process receipt'
    }
    $taskStdoutDescriptor=Task-RelativeDescriptor 'stdout.original.txt'
    $taskStderrDescriptor=Task-RelativeDescriptor 'stderr.original.txt'
    $taskCaptureDescriptor=Task-RelativeDescriptor 'capture/reference-capture.json'
    if($taskStdoutDescriptor.bytes -gt 16384 -or $taskStderrDescriptor.bytes -ne 0 -or $taskCaptureDescriptor.bytes -gt 2093056){throw 'Clean stream/capture cap requirement failed'}
    $line=[IO.File]::ReadAllText((Join-Path $taskRoot 'stdout.original.txt'),$taskUtf8).TrimEnd([char[]]@([char]13,[char]10))
    if($line.Contains([char]13) -or $line.Contains([char]10)){throw 'Exactly one Python completion line required'}
    $closed=$line|ConvertFrom-Json -AsHashtable -Depth 20
    if($closed.recordKind -cne 'REFERENCE_CAPTURE_FILE_CLOSED_NOT_ACCEPTANCE' -or $closed.bytes -ne $taskCaptureDescriptor.bytes -or $closed.sha256 -cne $taskCaptureDescriptor.sha256){throw 'Python completion/capture descriptor mismatch'}
    $capture=Task-ReadJson (Join-Path $taskRoot 'capture/reference-capture.json') 2093056
    if($capture.recordKind -cne 'A2P0_CANONICAL_REFERENCE_DATA_CAPTURE_NOT_ACCEPTANCE' -or $capture.captureScope -cne 'PAYLOAD_SEMANTICS_ONLY' -or
       $capture.bindingSha256 -cne $binding.referenceData.sha256 -or $capture.canonicalCount -ne 10 -or $capture.copyRelationCount -ne 6 -or @($capture.results).Count -ne 10){throw 'Wrong capture scope/count/data join'}
    for($n=0;$n -lt 10;$n++){if($capture.results[$n].id -cne ('C{0:00}' -f ($n+1))){throw 'Ordered canonical capture IDs differ'}}
    $allowed=@('capture/reference-capture.json','stdout.original.txt','stderr.original.txt','process-receipt.original.json')
    $total=0L
    foreach($file in Get-ChildItem -LiteralPath $taskRoot -Recurse -File -Force){
        $relative=[IO.Path]::GetRelativePath($taskRoot,$file.FullName).Replace([char]92,[char]47)
        if($relative -cnotin $allowed){throw 'Unprescribed worker output'}
        $total+=$file.Length
    }
    if($total -gt 2306048){throw 'Four worker files exceed their allocated total; outer receipt reservation preserved'}
    Task-Tick
    $taskExit=0;$taskStatus='PASS_CAPTURE_CLOSED_NOT_ACCEPTED'
}catch{
    $message=[string]$_.Exception.Message
    $taskFailure=[ordered]@{type=$_.Exception.GetType().FullName;message=$message.Substring(0,[Math]::Min(512,$message.Length));messageTruncated=($message.Length -gt 512)}
}
# The outer owns execution-receipt.original.json. Emit metadata only, never the
# reference body, source/review narrative or a compatibility verdict.
$completion=[ordered]@{recordKind='A2P0_WORKER_CLOSED_NOT_ACCEPTANCE';runId=$taskRunId;sourceHead=$taskHead;nonce=$Nonce;
    status=$taskStatus;exitCode=$taskExit;cleanupConfirmed=($null -ne $taskProcess -and $taskProcess.cleanupConfirmed -eq $true);
    finalActiveJobCountObserved=$(if($taskProcess){$taskProcess.finalActiveJobCountObserved}else{$null});
    streamsComplete=($null -ne $taskProcess -and $taskProcess.streamsComplete -eq $true);processReceipt=$taskReceiptDescriptor;
    capture=$taskCaptureDescriptor;stdout=$taskStdoutDescriptor;stderr=$taskStderrDescriptor;failure=$taskFailure;
    cooperativeElapsedSeconds=$taskClock.Elapsed.TotalSeconds;outerHardWall='REQUIRED_EXTERNAL_WATCHDOG_NOT_PROVEN_BY_WORKER_NONCE'}
$completionBytes=$taskUtf8.GetBytes(($completion|ConvertTo-Json -Depth 20 -Compress)+"`n")
if($completionBytes.Length -gt 4096){exit 1}
[Console]::Out.Write($taskUtf8.GetString($completionBytes))
exit $taskExit
