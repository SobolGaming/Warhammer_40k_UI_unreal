#Requires -Version 7.0
# Offline AST/inert-object controls only. This never reads a real host receipt,
# discovers a process, sends a shutdown request or runs Core/service/client code.
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$previousProbe = Get-Variable -Name WarhammerCoreStopProbe -Scope Global -ErrorAction SilentlyContinue
$caseCount = 0
function Assert-True([bool]$Value, [string]$Message) { if (!$Value) { throw $Message } }
function New-InertProcess([int]$Id, [bool]$Graceful) {
    $object = [pscustomobject]@{ Id = $Id; HasExited = $false; Graceful = $Graceful; KillFails = $false; DisposeFails = $false;
        KillCalls = 0; WaitCalls = 0; DisposeCalls = 0; EntireTree = $false; Budgets = @() }
    $object | Add-Member ScriptMethod WaitForExit {
        param([int]$Milliseconds)
        $this.WaitCalls++; $this.Budgets += $Milliseconds
        $global:WarhammerCoreStopProbe.Events.Add('wait:' + $this.Id)
        if ($this.Graceful) { $this.HasExited = $true }
        return $this.HasExited
    }
    $object | Add-Member ScriptMethod Kill {
        param([bool]$EntireTree)
        $this.KillCalls++; $this.EntireTree = $EntireTree
        $global:WarhammerCoreStopProbe.Events.Add('kill:' + $this.Id)
        if ($this.KillFails) { throw [IO.IOException]::new('Synthetic first termination failure') }
        $this.HasExited = $true
    }
    $object | Add-Member ScriptMethod Dispose {
        $this.DisposeCalls++
        if ($this.DisposeFails) { throw [IO.IOException]::new('Synthetic first disposal failure') }
    }
    return $object
}

try {
    $tokens = $null; $parseErrors = $null
    $ast = [Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'scripts/Stop-CoreDevelopmentServer.ps1'), [ref]$tokens, [ref]$parseErrors)
    Assert-True ($parseErrors.Count -eq 0) 'Stop source must parse'
    $functions = @($ast.FindAll({ param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq 'Invoke-VerifiedCoreStop' }, $false))
    Assert-True ($functions.Count -eq 1) 'Expected one production verified-stop function'
    . ([scriptblock]::Create($functions[0].Extent.Text))
    $main = @($ast.EndBlock.Statements | Where-Object { $_ -is [Management.Automation.Language.TryStatementAst] })
    Assert-True ($main.Count -eq 1 -and $main[0].CatchClauses.Count -eq 1) 'Unexpected main stop boundary'
    $identityLoops = @($main[0].Body.Statements | Where-Object {
        $_ -is [Management.Automation.Language.ForEachStatementAst] -and $_.Variable.Extent.Text -ceq '$identity'
    })
    Assert-True ($identityLoops.Count -eq 1) 'Expected one complete pre-stop identity loop'
    $script:identityLoop = [scriptblock]::Create($identityLoops[0].Extent.Text)
    $stopCalls = @($main[0].Body.Statements | Where-Object { $_.Extent.Text.StartsWith('$stopResult = Invoke-VerifiedCoreStop ', [StringComparison]::Ordinal) })
    Assert-True ($stopCalls.Count -eq 1 -and $identityLoops[0].Extent.EndOffset -lt $stopCalls[0].Extent.StartOffset) 'All identities must be checked before any stop action'
    $script:stopCall = [scriptblock]::Create($stopCalls[0].Extent.Text)
    $text = $main[0].CatchClauses[0].Body.Extent.Text
    $script:catchBody = [scriptblock]::Create($text.Substring(1, $text.Length - 2))
    $text = $main[0].Finally.Extent.Text
    $script:finallyBody = [scriptblock]::Create($text.Substring(1, $text.Length - 2))

    function Invoke-InertStopCase([hashtable]$Faults = @{}) {
        $global:WarhammerCoreStopProbe = [pscustomobject]@{ MarkerFails = $false; ReceiptFails = $false; IdentityFails = $false;
            MarkerCalls = 0; ReceiptCalls = 0; IdentityCalls = 0; Receipt = $null; Events = [Collections.Generic.List[string]]::new() }
        foreach ($name in @('MarkerFails', 'ReceiptFails', 'IdentityFails')) {
            if ($Faults.ContainsKey($name)) { $global:WarhammerCoreStopProbe.$name = $Faults[$name] }
        }
        $graceful = $Faults.ContainsKey('Graceful') -and $Faults.Graceful
        $server = New-InertProcess 5101 $graceful
        $launcher = New-InertProcess 5102 $graceful
        $controlLock = New-InertProcess 5103 $false
        if ($Faults.ContainsKey('KillFails')) { $server.KillFails = $Faults.KillFails }
        if ($Faults.ContainsKey('DisposeFails')) { $server.DisposeFails = $Faults.DisposeFails }
        $processes = [Collections.Generic.List[object]]::new()
        $receipt = [ordered]@{ status = 'READY'; shutdownFile = 'inert-shutdown-file'; server = @{ pid = 5101 }; launcher = @{ pid = 5102 } }
        $ReceiptPath = 'inert-receipt'; $GraceSeconds = 5; $CleanupSeconds = 3; $primaryFailure = $null
        function Find-OwnedProcess($Identity) {
            $global:WarhammerCoreStopProbe.IdentityCalls++
            if ($Identity.pid -eq 5102 -and $global:WarhammerCoreStopProbe.IdentityFails) { throw [IO.IOException]::new('Synthetic second identity mismatch') }
            return $(if ($Identity.pid -eq 5101) { $server } else { $launcher })
        }
        function Write-StopMarker([string]$Path) {
            $global:WarhammerCoreStopProbe.MarkerCalls++
            $global:WarhammerCoreStopProbe.Events.Add('marker')
            if ($global:WarhammerCoreStopProbe.MarkerFails) { throw [IO.IOException]::new('Synthetic marker-write failure') }
        }
        function Write-StopReceipt([string]$Path, $Value) {
            $global:WarhammerCoreStopProbe.ReceiptCalls++
            $global:WarhammerCoreStopProbe.Events.Add('receipt')
            if ($global:WarhammerCoreStopProbe.ReceiptFails) { throw [IO.IOException]::new('Synthetic receipt-write failure') }
            $global:WarhammerCoreStopProbe.Receipt = $Value | ConvertTo-Json -Depth 20 | ConvertFrom-Json -AsHashtable -Depth 20
        }
        $caught = $null; $stopResult = $null
        try {
            try { . $script:identityLoop; . $script:stopCall }
            catch { . $script:catchBody }
            finally { . $script:finallyBody }
        } catch { $caught = $_ }
        $probe = $global:WarhammerCoreStopProbe
        if ($probe.IdentityFails) {
            Assert-True ($null -ne $caught -and $caught.Exception.Message.Contains('Synthetic second identity mismatch')) 'Identity failure was not primary'
            Assert-True ($probe.MarkerCalls -eq 0 -and $probe.ReceiptCalls -eq 0 -and $server.KillCalls -eq 0 -and $launcher.KillCalls -eq 0) 'Identity failure must permit zero marker/persistence/kill actions'
            Assert-True ($server.DisposeCalls -eq 1 -and $launcher.DisposeCalls -eq 0 -and $controlLock.DisposeCalls -eq 1) 'Only retained identity objects and lock must be disposed'
        } else {
            Assert-True ($server.DisposeCalls -eq 1 -and $launcher.DisposeCalls -eq 1 -and $controlLock.DisposeCalls -eq 1) 'Every retained process and lock must receive disposal'
            Assert-True ($probe.MarkerCalls -eq 1 -and $probe.ReceiptCalls -eq 1) 'Marker/persistence must each be attempted once independently'
            Assert-True ($probe.Events[-1] -ceq 'receipt') 'Receipt persistence must follow every process cleanup attempt'
            $expectFailure = $probe.MarkerFails -or $probe.ReceiptFails -or $server.KillFails -or $server.DisposeFails
            Assert-True (($null -ne $caught) -eq $expectFailure) 'Unexpected overall stop outcome'
            if (!$graceful) {
                Assert-True ($server.KillCalls -eq 1 -and $launcher.KillCalls -eq 1 -and $server.EntireTree -and $launcher.EntireTree) 'A first process error skipped another verified process or changed tree scope'
            } else { Assert-True ($server.KillCalls -eq 0 -and $launcher.KillCalls -eq 0) 'Graceful exit must not be force-terminated' }
            $cleanup = if ($caught -and $caught.Exception.Data.Contains('CoreStopCleanup')) { $caught.Exception.Data['CoreStopCleanup'] } else { $stopResult }
            Assert-True ($null -ne $cleanup -and $cleanup.graceSeconds -eq 5 -and $cleanup.forcedExitSeconds -eq 3) 'Bounded cleanup result is missing'
            Assert-True ($cleanup.allExited -eq !$server.KillFails -and ($cleanup.status -ceq 'STOPPED') -eq $cleanup.allExited) 'STOPPED must require confirmed exit of every retained process'
            foreach ($process in @($server, $launcher)) { foreach ($budget in $process.Budgets) { Assert-True ($budget -ge 0 -and $budget -le 5000) 'An unbounded wait was requested' } }
            if ($probe.MarkerFails) {
                Assert-True ($caught.Exception.Message.Contains('Synthetic marker-write failure')) 'A later failure replaced the marker failure'
                Assert-True (!$cleanup.shutdownRequested -and $server.WaitCalls -eq [int]$server.KillFails -and $launcher.WaitCalls -eq 0) 'Marker failure must skip grace without skipping forced cleanup/exit checks'
            } elseif ($server.KillFails) { Assert-True ($caught.Exception.Message.Contains('Synthetic first termination failure')) 'First termination failure was replaced' }
            elseif ($probe.ReceiptFails) { Assert-True ($caught.Exception.Message.Contains('Synthetic receipt-write failure')) 'Receipt failure was not preserved' }
            if ($server.DisposeFails -and ($probe.MarkerFails -or $server.KillFails -or $probe.ReceiptFails)) {
                Assert-True ($caught.Exception.Data.Contains('CoreStopDisposeFailure')) 'Disposal failure must attach without replacing the primary failure'
            }
            if (!$probe.ReceiptFails) {
                Assert-True ($probe.Receipt.status -ceq $cleanup.status -and $probe.Receipt.stopCleanup.allExited -eq $cleanup.allExited) 'Persisted stop classification differs from confirmed process state'
                if ($server.KillFails) { Assert-True (!$probe.Receipt.Contains('stoppedUtc')) 'A running process must not get a stopped timestamp' }
            }
        }
        $script:caseCount++
    }

    Invoke-InertStopCase @{ Graceful = $true }
    Invoke-InertStopCase @{}
    Invoke-InertStopCase @{ MarkerFails = $true }
    Invoke-InertStopCase @{ KillFails = $true }
    Invoke-InertStopCase @{ ReceiptFails = $true }
    Invoke-InertStopCase @{ MarkerFails = $true; KillFails = $true; ReceiptFails = $true }
    Invoke-InertStopCase @{ IdentityFails = $true }
    Invoke-InertStopCase @{ IdentityFails = $true; DisposeFails = $true }
    Invoke-InertStopCase @{ DisposeFails = $true }
    Invoke-InertStopCase @{ MarkerFails = $true; DisposeFails = $true }
    [pscustomobject]@{ status = 'PASS'; cases = $caseCount; scope = 'OFFLINE_AST_AND_INERT_VERIFIED_STOP_CONTROLS'; serviceOrClientStarted = $false; networkRequested = $false }
} finally {
    if ($previousProbe) { Set-Variable -Name WarhammerCoreStopProbe -Scope Global -Value $previousProbe.Value }
    else { Remove-Variable -Name WarhammerCoreStopProbe -Scope Global -ErrorAction SilentlyContinue }
}
