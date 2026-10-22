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
$definitions=foreach($name in @('ConvertTo-A1GComparableData','Equal-Data','Get-A1GUbtTraceDelta')){
    $nodes=@($ast.FindAll({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq $name},$true))
    if($nodes.Count -ne 1){throw 'TRACE_CONTROL_FUNCTION_NOT_UNIQUE'}
    $nodes[0].Extent.Text
}
# Execute only these three function definitions in this control's local scope.
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
[ordered]@{recordKind='E04_A1G_PURE_TRACE_DELTA_REGRESSION_CONTROLS';wrapperSha256=$ExpectedWrapperSha256;passed=$results.Count;cases=$results.ToArray();scope='Pure synthetic metadata only. No live filesystem capture, recovery-copy, source review, build, process, trace writing or end-to-end assurance.'}|ConvertTo-Json -Depth 6
