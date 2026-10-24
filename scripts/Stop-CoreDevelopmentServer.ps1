#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$ReceiptPath,
    [ValidateRange(1, 5)][int]$GraceSeconds = 5,
    [ValidateRange(1, 3)][int]$CleanupSeconds = 3
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$hostRoot = Join-Path $repo '.local/development/core-host'
$utf8 = [Text.UTF8Encoding]::new($false, $true)
function Assert-PlainPath([string]$Path) {
    $cursor = [IO.Path]::GetFullPath($Path)
    while ($cursor) {
        if ((Test-Path -LiteralPath $cursor) -and ((Get-Item -LiteralPath $cursor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Reparse points are not supported for development host paths.' }
        $parent = [IO.Directory]::GetParent($cursor); $cursor = if ($parent) { $parent.FullName } else { $null }
    }
}
function Find-OwnedProcess($Identity) {
    try { $process = [Diagnostics.Process]::GetProcessById([int]$Identity.pid) } catch [ArgumentException] { return $null }
    try {
        $null = $process.SafeHandle
        if ($process.HasExited) { $process.Dispose(); return $null }
        if ($process.StartTime.ToUniversalTime().Ticks -ne $Identity.startTimeUtcTicks -or $process.MainModule.FileName -ine $Identity.executable) { throw 'PID is now a different process; no termination is permitted.' }
        $process
    } catch [InvalidOperationException] {
        if ($process.HasExited) { $process.Dispose(); return $null }
        $process.Dispose(); throw
    } catch { $process.Dispose(); throw }
}
function Write-StopMarker([string]$Path) {
    [IO.File]::WriteAllText($Path, [DateTime]::UtcNow.ToString('o') + "`n", $utf8)
}
function Write-StopReceipt([string]$Path, $Value) {
    $temporary = $Path + '.' + [guid]::NewGuid().ToString('N') + '.tmp'
    [IO.File]::WriteAllText($temporary, ($Value | ConvertTo-Json -Depth 20) + "`n", $utf8)
    [IO.File]::Move($temporary, $Path, $true)
}
function Invoke-VerifiedCoreStop($Processes, $Receipt, [string]$Path, [int]$Grace, [int]$ExitWait) {
    # The caller has verified every retained object before entering this function.
    # No receipt write, marker error or first-process failure gates later cleanup.
    $result = [pscustomobject]@{ status = 'STOP_FAILED'; graceSeconds = $Grace; forcedExitSeconds = $ExitWait;
        shutdownRequested = $false; forcedTermination = $false; allExited = $true; errors = @() }
    $firstFailure = $null
    try {
        Write-StopMarker $Receipt.shutdownFile
        $result.shutdownRequested = $true
        $Receipt['shutdownRequestedUtc'] = [DateTime]::UtcNow.ToString('o')
    } catch { $firstFailure = $_; $result.errors += 'SHUTDOWN_MARKER:' + $_.Exception.GetType().FullName }
    $graceClock = [Diagnostics.Stopwatch]::StartNew()
    if ($result.shutdownRequested) {
        foreach ($process in $Processes) {
            try {
                $remaining = [Math]::Max(0, $Grace * 1000 - [int]$graceClock.ElapsedMilliseconds)
                if (!$process.HasExited -and $remaining -gt 0) { $null = $process.WaitForExit($remaining) }
            } catch {
                if (!$firstFailure) { $firstFailure = $_ }
                $result.errors += 'GRACE_WAIT:' + $_.Exception.GetType().FullName
            }
        }
    }
    foreach ($process in $Processes) {
        try {
            if (!$process.HasExited) {
                # The actual verified handle and only its descendants are targeted.
                $process.Kill($true); $result.forcedTermination = $true
            }
        } catch {
            if (!$firstFailure) { $firstFailure = $_ }
            $result.errors += 'OWNED_STOP:' + $_.Exception.GetType().FullName
        }
    }
    $exitClock = [Diagnostics.Stopwatch]::StartNew()
    foreach ($process in $Processes) {
        try {
            $remaining = [Math]::Max(0, $ExitWait * 1000 - [int]$exitClock.ElapsedMilliseconds)
            if (!$process.HasExited -and $remaining -gt 0) { $null = $process.WaitForExit($remaining) }
            if (!$process.HasExited) {
                $result.allExited = $false; $result.errors += 'OWNED_PROCESS_STILL_RUNNING'
                if (!$firstFailure) {
                    $firstFailure = [Management.Automation.ErrorRecord]::new([TimeoutException]::new('Owned Core processes did not exit within the cleanup budget.'),
                        'CoreStopExitTimeout', [Management.Automation.ErrorCategory]::OperationTimeout, $null)
                }
            }
        } catch {
            $result.allExited = $false
            if (!$firstFailure) { $firstFailure = $_ }
            $result.errors += 'EXIT_CHECK:' + $_.Exception.GetType().FullName
        }
    }
    $result.status = if ($result.allExited) { 'STOPPED' } else { 'STOP_FAILED' }
    $Receipt['status'] = $result.status; $Receipt['forcedTermination'] = $result.forcedTermination
    $Receipt['stopAttemptedUtc'] = [DateTime]::UtcNow.ToString('o'); $Receipt['stopCleanup'] = $result
    if ($result.allExited) { $Receipt['stoppedUtc'] = [DateTime]::UtcNow.ToString('o') }
    try { Write-StopReceipt $Path $Receipt }
    catch {
        if (!$firstFailure) { $firstFailure = $_ }
        $result.errors += 'RECEIPT_UPDATE:' + $_.Exception.GetType().FullName
    }
    if ($firstFailure) { $firstFailure.Exception.Data['CoreStopCleanup'] = $result; throw $firstFailure }
    return $result
}
Assert-PlainPath $hostRoot
if (!(Test-Path -LiteralPath $hostRoot)) { throw 'No managed Core host receipt exists.' }
$controlLock = [IO.File]::Open((Join-Path $hostRoot 'control.lock'), [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
$processes = [Collections.Generic.List[Diagnostics.Process]]::new()
$primaryFailure = $null
try {
    if (!$ReceiptPath) { $ReceiptPath = (Get-Content -LiteralPath (Join-Path $hostRoot 'current.json') -Raw | ConvertFrom-Json -AsHashtable).receiptPath }
    $ReceiptPath = [IO.Path]::GetFullPath($ReceiptPath)
    Assert-PlainPath $ReceiptPath
    if (!$ReceiptPath.StartsWith(([IO.Path]::GetFullPath($hostRoot).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar), [StringComparison]::OrdinalIgnoreCase) -or [IO.Path]::GetFileName($ReceiptPath) -cne 'receipt.json') { throw 'Receipt must be an owned development host receipt.' }
    $receipt = Get-Content -LiteralPath $ReceiptPath -Raw | ConvertFrom-Json -AsHashtable -Depth 20
    if ($receipt.recordKind -cne 'WARHAMMER_CORE_DEVELOPMENT_HOST') { throw 'Unknown host receipt kind.' }
    if ($receipt.mode -ceq 'Attach' -and $receipt.owned -eq $false) {
        [pscustomobject]@{ status = 'ATTACHED_NOT_STOPPED'; owned = $false; endpoint = $receipt.endpoint }
        return
    }
    if ($receipt.mode -cne 'Managed' -or $receipt.owned -ne $true) { throw 'Receipt does not establish managed ownership.' }
    $runRoot = [IO.Path]::GetDirectoryName($ReceiptPath)
    if ($receipt.runRoot -ine $runRoot -or $receipt.shutdownFile -ine (Join-Path $runRoot 'shutdown.requested')) { throw 'Owned shutdown path differs.' }
    Assert-PlainPath $receipt.shutdownFile
    if ($receipt.status -ceq 'STOPPED') { [pscustomobject]@{ status = 'ALREADY_STOPPED'; owned = $true; receiptPath = $ReceiptPath }; return }
    # Every process is pinned by PID, creation time and executable before a marker or kill.
    foreach ($identity in @($receipt.server, $receipt.launcher)) {
        if (!$identity) { continue }
        if (@($processes | Where-Object { $_.Id -eq $identity.pid }).Count) { continue }
        $process = Find-OwnedProcess $identity
        if ($process) { $processes.Add($process) }
    }
    $stopResult = Invoke-VerifiedCoreStop $processes $receipt $ReceiptPath $GraceSeconds $CleanupSeconds
    [pscustomobject]@{ status = $stopResult.status; owned = $true; forcedTermination = $stopResult.forcedTermination; receiptPath = $ReceiptPath }
} catch {
    $primaryFailure = $_
    throw $primaryFailure
} finally {
    $disposeFailure = $null
    $resources = [Collections.Generic.List[object]]::new()
    foreach ($process in $processes) { $resources.Add($process) }
    if ($controlLock) { $resources.Add($controlLock) }
    foreach ($resource in $resources) {
        try { $resource.Dispose() }
        catch {
            if (!$disposeFailure) { $disposeFailure = $_ }
            if ($primaryFailure) { $primaryFailure.Exception.Data['CoreStopDisposeFailure'] = $disposeFailure.Exception.GetType().FullName }
        }
    }
    if ($disposeFailure -and !$primaryFailure) { throw $disposeFailure }
}
