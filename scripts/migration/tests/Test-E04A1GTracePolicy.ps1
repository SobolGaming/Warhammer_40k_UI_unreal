# Focused pure-data regression controls. Never runs the wrapper or touches live traces.
[CmdletBinding()]
param([Parameter(Mandatory)][ValidatePattern('^[A-Fa-f0-9]{64}$')][string]$ExpectedWrapperSha256)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$wrapper=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../Invoke-E04A1GProfileProof.ps1'))
if((Get-FileHash -LiteralPath $wrapper -Algorithm SHA256).Hash -ine $ExpectedWrapperSha256){throw 'TRACE_CONTROL_WRAPPER_IDENTITY_DRIFT'}
$tokens=$null;$parseErrors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($wrapper,[ref]$tokens,[ref]$parseErrors)
if(@($parseErrors).Count){throw 'TRACE_CONTROL_SOURCE_PARSE_ERROR'}
$definitions=foreach($name in @('ConvertTo-A1GComparableData','Equal-Data','Get-A1GUbtTraceDelta','Split-A1GSimpleCookArguments','Assert-A1GCookSdkValidationContext','Read-A1GCookSdkValidationText')){
    $nodes=@($ast.FindAll({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq $name},$true))
    if($nodes.Count -ne 1){throw 'TRACE_CONTROL_FUNCTION_NOT_UNIQUE'}
    $nodes[0].Extent.Text
}
# Execute only these six pure metadata function definitions in this control's local scope.
. ([scriptblock]::Create(($definitions -join "`n")))
$traceDirectory='C:\Users\Rabid\AppData\Local\UnrealBuildTool'
function FileFact([string]$Name,[string]$Hash='a',[string]$Created='2026-10-22T10:00:00.0000000Z'){
    @{name=$Name;path=(Join-Path $traceDirectory $Name);bytes=10L;sha256=($Hash*64);creationTimeUtc=$Created;lastWriteTimeUtc='2026-10-22T10:00:00.0000000Z'}
}
function State([object[]]$Files){
    @{directory=$traceDirectory;directoryExists=$true;traceExists=(@($Files|Where-Object {$_.name -ceq 'Trace.uba'}).Count -eq 1);files=$Files}
}
$results=[Collections.Generic.List[object]]::new()
function Case([string]$Name,[scriptblock]$Body){& $Body;$results.Add(@{name=$Name;passed=$true})}
function Refuses([scriptblock]$Body,[string]$Expected){
    $caught=$null
    try{[void](& $Body)}catch{$caught=$_.Exception.Message}
    if($caught -cne $Expected){throw ('TRACE_CONTROL_WRONG_REFUSAL expected='+$Expected+' actual='+$caught)}
}
Case 'first trace creation preserves existing backups' {
    $backup=FileFact 'Trace-backup-2026.10.20-10.00.00.uba'
    $d=Get-A1GUbtTraceDelta (State @($backup)) (State @($backup,(FileFact 'Trace.uba' 'b')))
    if(@($d.created).Count -ne 1 -or @($d.deleted).Count -ne 0 -or $null -ne $d.moved){throw 'TRACE_CONTROL_FIRST_CREATE'}
}
Case 'normal rotation prunes oldest backups and preserves prior trace bytes' {
    $backups=@(1..12|ForEach-Object {FileFact ('Trace-backup-2026.10.'+$_.ToString('00')+'-10.00.00.uba')})
    $oldTrace=FileFact 'Trace.uba' 'b'
    $kept=@($backups|Where-Object {$_.name -cge 'Trace-backup-2026.10.04-10.00.00.uba'})
    $d=Get-A1GUbtTraceDelta (State (@($oldTrace)+$backups)) (State ($kept+@((FileFact 'Trace-backup-2026.10.22-10.00.00.uba' 'b'),(FileFact 'Trace.uba' 'c'))))
    if(@($d.deleted).Count -ne 3 -or $d.moved.to.sha256 -cne $oldTrace.sha256){throw 'TRACE_CONTROL_ROTATION'}
}
Case 'creation timestamp collision advances to the next available second' {
    $backup=FileFact 'Trace-backup-2026.10.22-10.00.00.uba'
    $d=Get-A1GUbtTraceDelta (State @($backup,(FileFact 'Trace.uba' 'b'))) (State @($backup,(FileFact 'Trace-backup-2026.10.22-10.00.01.uba' 'b'),(FileFact 'Trace.uba' 'c')))
    if($d.moved.to.name -cne 'Trace-backup-2026.10.22-10.00.01.uba'){throw 'TRACE_CONTROL_COLLISION'}
}
Case 'missing preceding trace backup refuses' {
    Refuses {Get-A1GUbtTraceDelta (State @((FileFact 'Trace.uba'))) (State @((FileFact 'Trace.uba' 'b')))} 'A1G_UBT_TRACE_EXPECTED_MOVE_NOT_OBSERVED'
}
Case 'changed surviving backup refuses' {
    Refuses {Get-A1GUbtTraceDelta (State @((FileFact 'Trace-backup-2026.10.20-10.00.00.uba'))) (State @((FileFact 'Trace-backup-2026.10.20-10.00.00.uba' 'b'),(FileFact 'Trace.uba')))} 'A1G_DATA_CHANGED: surviving trace backup unchanged'
}
Case 'unexplained new backup refuses' {
    Refuses {Get-A1GUbtTraceDelta (State @()) (State @((FileFact 'Trace.uba'),(FileFact 'Trace-backup-2026.10.20-10.00.00.uba')))} 'A1G_UBT_TRACE_UNEXPLAINED_FAMILY_DELTA'
}
Case 'backup pruning without preceding trace refuses' {
    Refuses {Get-A1GUbtTraceDelta (State @((FileFact 'Trace-backup-2026.10.20-10.00.00.uba'))) (State @((FileFact 'Trace.uba')))} 'A1G_UBT_TRACE_UNEXPLAINED_BACKUP_REMOVAL'
}
# Synthetic command/log text only. None of these paths is opened or executed.
$sdkProject='C:\proof\project\WarhammerClient.uproject'
$sdkPath='C:\proof\ue-user\cook\Saved\Logs\AutoSDKInfo.txt'
$sdkVersion='10.0.22621.0'
$sdkCommand='Running UnrealBuildTool: dotnet "..\..\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.dll" -Mode=ValidatePlatforms -OutputSDKs  -AllPlatforms -project="'+$sdkProject.Replace('\','/')+'" -log="'+$sdkPath.Replace('\','/')+'" -verbose -timestamps'
$sdkStdout=$sdkCommand+"`n##PlatformValidate: Win64 VALID 10.0.22621.0`n##PlatformValidate: Mac INVALID 26.1.1`nTrace written to file C:\Users\Rabid\AppData\Local\UnrealBuildTool\Trace.uba with size 319b`n"
$sdkOwnLog="[00:00:00.304] ##PlatformValidate: Win64 VALID 10.0.22621.0`n[00:00:00.304] ##PlatformValidate: Mac INVALID 26.1.1`n[00:00:00.310] Result: Succeeded`n[00:00:00.310] Total execution time: 0.24 seconds`n"
function ReadSdk([string]$Stdout=$sdkStdout,[string]$OwnLog=$sdkOwnLog){Read-A1GCookSdkValidationText $Stdout $OwnLog $sdkProject $sdkPath $sdkVersion}
Case 'one normal SDK command matches timestamped owned Win64 log and trace route' {
    $guard=Assert-A1GCookSdkValidationContext '' ' 0 ' @('-cook','-AdditionalCookerOptions=-NullRHI -unattended')
    $evidence=ReadSdk
    if($guard.uatBuildMachine -ne $false -or $guard.sdkSetupBypass -ne $false -or $evidence.sdkVersion -cne $sdkVersion -or $evidence.observedSdkInvocationCount -ne 1 -or $evidence.observedTraceLineCount -ne 1 -or $null -ne $evidence.actualSdkWriterPid -or $evidence.writerPidAttestation -cne 'UNVERIFIED'){throw 'TRACE_CONTROL_NORMAL_COOK_SDK'}
}
Case 'duplicate emitted SDK invocations refuse' {
    Refuses {ReadSdk ($sdkCommand+"`n"+$sdkStdout)} 'A1G_COOK_SDK_ONE_NORMAL_EMITTED_UBT_REQUIRED'
}
Case 'wrong SDK mode tool spelling or extra command argument refuses' {
    foreach($pair in @(@('-Mode=ValidatePlatforms','-Mode=Build'),@('UnrealBuildTool.dll','OtherTool.dll'),@('-verbose -timestamps','-verbose -timestamps -Session=other'))){
        Refuses {ReadSdk ($sdkStdout.Replace($pair[0],$pair[1]))} 'A1G_DATA_CHANGED: Cook SDK exact emitted command tokens'
    }
}
Case 'SDK project or owned log route mismatch refuses' {
    foreach($pair in @(@('C:/proof/project/WarhammerClient.uproject','C:/other/WarhammerClient.uproject'),@('C:/proof/ue-user/cook/Saved/Logs/AutoSDKInfo.txt','C:/other/AutoSDKInfo.txt'))){
        Refuses {ReadSdk ($sdkStdout.Replace($pair[0],$pair[1]))} 'A1G_DATA_CHANGED: Cook SDK exact emitted command tokens'
    }
}
Case 'missing duplicate wrong-version or failed owned SDK evidence refuses' {
    Refuses {ReadSdk $sdkStdout ($sdkOwnLog.Replace('##PlatformValidate: Win64 VALID 10.0.22621.0','other platform data'))} 'A1G_COOK_SDK_WIN64_VALID_OBSERVATION_REQUIRED'
    Refuses {ReadSdk $sdkStdout ($sdkOwnLog+"[00:00:00.304] ##PlatformValidate: Win64 VALID 10.0.22621.0`n")} 'A1G_COOK_SDK_WIN64_VALID_OBSERVATION_REQUIRED'
    Refuses {ReadSdk ($sdkStdout.Replace('Win64 VALID 10.0.22621.0','Win64 VALID 10.0.99999.0'))} 'A1G_COOK_SDK_WIN64_VALID_OBSERVATION_REQUIRED'
    Refuses {ReadSdk $sdkStdout ($sdkOwnLog.Replace('Result: Succeeded','Result: Failed'))} 'A1G_COOK_SDK_OWN_LOG_SUCCESS_REQUIRED'
}
Case 'missing duplicate or unapproved Cook trace route refuses' {
    Refuses {ReadSdk ($sdkStdout.Replace('Trace written to file','other output'))} 'A1G_COOK_SDK_ONE_CLOSED_TRACE_ROUTE_REQUIRED'
    Refuses {ReadSdk ($sdkStdout+"Trace written to file C:\Users\Rabid\AppData\Local\UnrealBuildTool\Trace.uba with size 320b`n")} 'A1G_COOK_SDK_ONE_CLOSED_TRACE_ROUTE_REQUIRED'
    Refuses {ReadSdk ($sdkStdout.Replace('C:\Users\Rabid\AppData\Local\UnrealBuildTool\Trace.uba','C:\other\Trace.uba'))} 'A1G_COOK_SDK_TRACE_DESTINATION_UNEXPECTED'
}
Case 'UAT nonzero selectors native skip prefixes and worker substitutions refuse' {
    foreach($value in @('1',' 2 ','-1')){Refuses {Assert-A1GCookSdkValidationContext $value '' @()} 'A1G_COOK_SDK_UAT_BUILD_MACHINE_ROUTE_FORBIDDEN'}
    foreach($value in @('1','1junk','+1tail','00')){Refuses {Assert-A1GCookSdkValidationContext '' $value @()} 'A1G_COOK_SDK_SETUP_SELECTOR_UNSAFE'}
    foreach($value in @('-BuildMachine','-AdditionalCookerOptions=-Multiprocess','-CookWorkerId=1','-CookProcessCount=2')){Refuses {Assert-A1GCookSdkValidationContext '' '' @($value)} 'A1G_COOK_SDK_VALIDATION_BYPASS_OR_WORKER_ARGUMENT'}
}
[ordered]@{recordKind='E04_A1G_PURE_TRACE_AND_COOK_SDK_METADATA_REGRESSION_CONTROLS';wrapperSha256=$ExpectedWrapperSha256;passed=$results.Count;cases=$results.ToArray();scope='Pure synthetic trace delta and Cook SDK command/log/selector metadata only. No live filesystem capture, recovery-copy, source review, build, process, trace writing, actual writer-PID or end-to-end assurance.'}|ConvertTo-Json -Depth 6
