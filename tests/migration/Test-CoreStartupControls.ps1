#Requires -Version 7.0
# Offline controls: load only the named function/statement ASTs; never execute
# Core startup preparation, credentials, a network request or a native process.
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$scratchParent = [IO.Path]::GetFullPath((Join-Path $repo '.local/tests/core-startup-controls'))
$scratch = Join-Path $scratchParent ([guid]::NewGuid().ToString('N'))
$previousProbe = Get-Variable -Name WarhammerCoreStartupProbe -Scope Global -ErrorAction SilentlyContinue
$caseCount = 0
$utf8 = [Text.UTF8Encoding]::new($false, $true)
function Assert-True([bool]$Condition, [string]$Message) { if (!$Condition) { throw $Message } }

function New-InertProcess([int]$Id, [bool]$Graceful) {
    $process = [pscustomobject]@{ Id = $Id; HasExited = $false; Graceful = $Graceful; WaitCalls = 0; KillCalls = 0; EntireTree = $false; Budgets = @(); DisposeCalls = 0; DisposeFails = $false }
    $process | Add-Member ScriptMethod WaitForExit {
        param([int]$Milliseconds)
        $this.WaitCalls++; $this.Budgets += $Milliseconds
        $global:WarhammerCoreStartupProbe.Events.Add('wait')
        if ($this.Graceful) { $this.HasExited = $true }
        return $this.HasExited
    }
    $process | Add-Member ScriptMethod Kill {
        param([bool]$EntireTree)
        $this.KillCalls++; $this.EntireTree = $EntireTree; $this.HasExited = $true
        $global:WarhammerCoreStartupProbe.Events.Add('kill')
    }
    $process | Add-Member ScriptMethod Dispose {
        $this.DisposeCalls++
        if ($this.DisposeFails) { throw [IO.IOException]::new('Synthetic first dispose failure') }
    }
    return $process
}

try {
    [IO.Directory]::CreateDirectory($scratch) | Out-Null
    $tokens = $null; $errors = $null
    $source = Join-Path $repo 'scripts/Start-CoreDevelopmentServer.ps1'
    $ast = [Management.Automation.Language.Parser]::ParseFile($source, [ref]$tokens, [ref]$errors)
    Assert-True ($errors.Count -eq 0) 'Core startup source did not parse'
    foreach ($name in @('Resolve-CoreEndpoint', 'Stop-StartedCoreProcesses', 'Complete-FailedCoreStartup')) {
        $functions = @($ast.FindAll({ param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq $name }, $false))
        Assert-True ($functions.Count -eq 1) 'Expected a single production control function'
        . ([scriptblock]::Create($functions[0].Extent.Text))
    }
    $mainTry = @($ast.EndBlock.Statements | Where-Object { $_ -is [Management.Automation.Language.TryStatementAst] })
    Assert-True ($mainTry.Count -eq 1 -and $mainTry[0].CatchClauses.Count -eq 1) 'Unexpected main startup failure boundary'
    $catchText = $mainTry[0].CatchClauses[0].Body.Extent.Text
    $script:failureBody = [scriptblock]::Create($catchText.Substring(1, $catchText.Length - 2))
    $finallyText = $mainTry[0].Finally.Extent.Text
    $script:finallyBody = [scriptblock]::Create($finallyText.Substring(1, $finallyText.Length - 2))
    $receiptAssignments = @($mainTry[0].FindAll({ param($node)
        $node -is [Management.Automation.Language.AssignmentStatementAst] -and $node.Left.Extent.Text -ceq '$receipt' -and
        $node.Right.Extent.Text.Contains('Get-OwnedIdentity $launcher')
    }, $true))
    Assert-True ($receiptAssignments.Count -eq 1) 'Unexpected managed receipt/identity construction'
    $script:receiptAssignment = [scriptblock]::Create($receiptAssignments[0].Extent.Text)
    $writes = @($mainTry[0].FindAll({ param($node)
        $node -is [Management.Automation.Language.CommandAst] -and $node.Extent.Text -ceq 'Write-Receipt $receiptPath $receipt'
    }, $true) | Sort-Object { $_.Extent.StartOffset })
    Assert-True ($writes.Count -ge 1) 'Missing initial production receipt write'
    $script:receiptWrite = [scriptblock]::Create($writes[0].Extent.Text)
    $mainStatements = @($ast.EndBlock.Statements)
    $guards = @($mainStatements | Where-Object { $_.Extent.Text.StartsWith('$Endpoint = Resolve-CoreEndpoint ', [StringComparison]::Ordinal) })
    $preparation = @($mainStatements | Where-Object { $_.Extent.Text.StartsWith('$CoreRoot = [IO.Path]::GetFullPath', [StringComparison]::Ordinal) })
    Assert-True ($guards.Count -eq 1 -and $preparation.Count -eq 1 -and $guards[0].Extent.StartOffset -lt $preparation[0].Extent.StartOffset) 'Endpoint validation must precede all Core path/credential/network preparation'

    foreach ($url in @('https://127.0.0.1:8765/', 'http://example.com:8765/', 'http://localhost:8765/',
        'http://127.0.0.1:80/', 'http://127.0.0.1:65536/', 'http://127.0.0.1:8765/path',
        'http://127.0.0.1:8765/?query=1', 'http://127.0.0.1:8765/#fragment',
        'http://user@127.0.0.1:8765/', 'http://127.0.0.1:8765/x/../',
        'http://2130706433:8765/', 'http://[::1]:8765/')) {
        $failure = $null
        try { $null = Resolve-CoreEndpoint ([uri]$url) 'Attach' 8765 } catch { $failure = $_ }
        Assert-True ($null -ne $failure) 'Unsupported Attach origin was accepted'
        $caseCount++
    }
    foreach ($port in @(1024, 65535)) {
        $uri = Resolve-CoreEndpoint ([uri]("http://127.0.0.1:$port")) 'Attach' 8765
        Assert-True ($uri.AbsoluteUri -ceq "http://127.0.0.1:$port/") 'Valid Attach origin was not canonicalized'
        $caseCount++
    }
    foreach ($managedMode in @('Managed', 'managed', 'mAnAgEd')) {
        $failure = $null
        try { $null = Resolve-CoreEndpoint ([uri]'http://127.0.0.1:8766/') $managedMode 8765 } catch { $failure = $_ }
        Assert-True ($null -ne $failure) 'Every accepted Managed casing must preserve the dedicated port'
        Assert-True ((Resolve-CoreEndpoint $null $managedMode 8765).AbsoluteUri -ceq 'http://127.0.0.1:8765/') 'Managed default origin changed'
        $caseCount += 2
    }

    function Invoke-InertStartupFault([bool]$IdentityFails, [bool]$Graceful, [bool]$WithServer, [bool]$HasLauncher = $true, [bool]$CleanupFails = $false) {
        $global:WarhammerCoreStartupProbe = [pscustomobject]@{ IdentityFails = $IdentityFails; ReceiptCalls = 0; Events = [Collections.Generic.List[string]]::new() }
        # These replace only the identity/persistence seams. The actual receipt
        # assignment, main catch and cleanup functions above execute unchanged.
        function Get-OwnedIdentity($Process) {
            if ($global:WarhammerCoreStartupProbe.IdentityFails) { throw [IO.IOException]::new('Synthetic Get-OwnedIdentity failure') }
            return [ordered]@{ pid = $Process.Id; startTimeUtcTicks = 1; executable = 'inert-python.exe' }
        }
        function Write-Receipt([string]$Path, $Value) {
            $global:WarhammerCoreStartupProbe.ReceiptCalls++
            $global:WarhammerCoreStartupProbe.Events.Add('receipt')
            throw [IO.IOException]::new('Synthetic persistent receipt-write failure')
        }
        if ($CleanupFails) { function Complete-FailedCoreStartup { throw [IO.IOException]::new('Synthetic cleanup-helper failure') } }
        $launcher = if ($HasLauncher) { New-InertProcess 4111 $Graceful } else { $null }
        $server = if ($WithServer) { New-InertProcess 4222 $Graceful } else { $null }
        $receipt = $null; $receiptPath = Join-Path $scratch 'inert-receipt.json'
        $shutdown = Join-Path $scratch ('shutdown-' + [guid]::NewGuid().ToString('N'))
        $Endpoint = [uri]'http://127.0.0.1:8765/'; $expectedCommit = 'synthetic'; $expectedBuild = 'synthetic'
        $CoreVersion = 'synthetic'; $runtimeProfile = [pscustomobject]@{ resourceCount = 0 }
        $runRoot = $scratch; $nonce = 'synthetic'; $basePython = 'inert-python.exe'; $stdout = 'inert'; $stderr = 'inert'
        $caught = $null
        try {
            try { . $script:receiptAssignment; . $script:receiptWrite }
            catch { . $script:failureBody }
        } catch { $caught = $_ }
        Assert-True ($null -ne $caught) 'Primary startup failure was lost'
        $expected = if ($IdentityFails) { 'Synthetic Get-OwnedIdentity failure' } else { 'Synthetic persistent receipt-write failure' }
        Assert-True ($caught.Exception.Message -ceq $expected) 'Cleanup replaced the original startup diagnostic'
        $cleanup = $caught.Exception.Data['CoreStartupCleanup']
        if (!$HasLauncher) {
            Assert-True ($null -eq $cleanup -and $global:WarhammerCoreStartupProbe.Events.Count -eq 0) 'Attach/no-start failure attempted owned-process cleanup'
        } else {
            Assert-True ($null -ne $cleanup -and $cleanup.attempted -and $cleanup.allExited) 'Retained process cleanup did not finish'
            Assert-True ($cleanup.graceSeconds -eq 5 -and $cleanup.forcedExitSeconds -eq 3) 'Cleanup bounds changed'
            if ($CleanupFails) { Assert-True ($caught.Exception.Data.Contains('CoreStartupCleanupFailure')) 'Unexpected helper failure must retain its classification and use fallback cleanup' }
            Assert-True ($launcher.HasExited -and $launcher.KillCalls -eq [int](!$Graceful)) 'Launcher cleanup was skipped'
            if (!$Graceful) { Assert-True $launcher.EntireTree 'Forced cleanup must target the owned descendant tree' }
            if ($WithServer) { Assert-True ($server.HasExited -and $server.KillCalls -eq [int](!$Graceful)) 'Verified retained child cleanup was skipped' }
            foreach ($budget in $launcher.Budgets) { Assert-True ($budget -ge 0 -and $budget -le 5000) 'Unbounded process wait' }
            if ($IdentityFails) { Assert-True ($null -eq $receipt -and $global:WarhammerCoreStartupProbe.ReceiptCalls -eq 0) 'Identity failure should not require a receipt' }
            else {
                Assert-True ($global:WarhammerCoreStartupProbe.ReceiptCalls -eq 2 -and $cleanup.errors.Count -eq 1 -and $cleanup.errors[0].StartsWith('RECEIPT_UPDATE:')) 'Persistent receipt failure was not retained independently'
                Assert-True ($global:WarhammerCoreStartupProbe.Events[-1] -ceq 'receipt') 'Receipt retry must occur after process cleanup'
            }
        }
        $script:caseCount++
    }
    Invoke-InertStartupFault $true $false $false
    Invoke-InertStartupFault $false $false $true
    Invoke-InertStartupFault $false $true $true
    Invoke-InertStartupFault $true $false $false $false
    Invoke-InertStartupFault $true $false $false $true $true

    # Execute the real finally statement body with inert resources. A first
    # disposal failure must not skip the remaining process or control-lock handle.
    $server = New-InertProcess 4401 $false; $server.DisposeFails = $true
    $launcher = New-InertProcess 4402 $false; $controlLock = New-InertProcess 4403 $false
    $startupFailure = $null; $caught = $null
    try { . $script:finallyBody } catch { $caught = $_ }
    Assert-True ($null -ne $caught -and $caught.Exception.Message.Contains('Synthetic first dispose failure')) 'Success-path disposal failure was not reported'
    Assert-True ($server.DisposeCalls -eq 1 -and $launcher.DisposeCalls -eq 1 -and $controlLock.DisposeCalls -eq 1) 'A disposal failure skipped a remaining resource'
    $caseCount++
    $server = New-InertProcess 4411 $false; $server.DisposeFails = $true
    $launcher = New-InertProcess 4412 $false; $controlLock = New-InertProcess 4413 $false
    $startupFailure = [Management.Automation.ErrorRecord]::new([IO.IOException]::new('Synthetic primary startup error'), 'Synthetic', [Management.Automation.ErrorCategory]::OpenError, $null)
    . $script:finallyBody
    Assert-True ($startupFailure.Exception.Message -ceq 'Synthetic primary startup error' -and $startupFailure.Exception.Data.Contains('CoreStartupDisposeFailure')) 'Disposal replaced the original startup failure'
    Assert-True ($server.DisposeCalls -eq 1 -and $launcher.DisposeCalls -eq 1 -and $controlLock.DisposeCalls -eq 1) 'Failure-path disposal skipped a resource'
    $caseCount++

    $global:WarhammerCoreStartupProbe = [pscustomobject]@{ Events = [Collections.Generic.List[string]]::new() }
    $inert = New-InertProcess 4333 $false
    $cleanup = Stop-StartedCoreProcesses $inert $null $scratch # Directory forces a marker-write failure.
    Assert-True ($cleanup.allExited -and !$cleanup.shutdownRequested -and $cleanup.forcedTermination -and $inert.WaitCalls -eq 0 -and $inert.EntireTree) 'Marker failure must not block retained-process cleanup'
    Assert-True ($cleanup.errors.Count -eq 1 -and $cleanup.errors[0].StartsWith('SHUTDOWN_MARKER:')) 'Marker failure classification was lost'
    $caseCount++
    [pscustomobject]@{ status = 'PASS'; cases = $caseCount; scope = 'OFFLINE_AST_AND_INERT_PROCESS_CONTROLS'; serviceOrClientStarted = $false; networkRequested = $false }
} finally {
    if ($previousProbe) { Set-Variable -Name WarhammerCoreStartupProbe -Scope Global -Value $previousProbe.Value }
    else { Remove-Variable -Name WarhammerCoreStartupProbe -Scope Global -ErrorAction SilentlyContinue }
    if (Test-Path -LiteralPath $scratch) {
        $resolved = [IO.Path]::GetFullPath($scratch)
        if (!$resolved.StartsWith($scratchParent + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe offline scratch cleanup path' }
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}
