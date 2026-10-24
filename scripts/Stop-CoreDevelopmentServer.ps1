#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$ReceiptPath,
    [ValidateRange(1, 30)][int]$GraceSeconds = 10,
    [ValidateRange(1, 10)][int]$CleanupSeconds = 5
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
Assert-PlainPath $hostRoot
if (!(Test-Path -LiteralPath $hostRoot)) { throw 'No managed Core host receipt exists.' }
$controlLock = [IO.File]::Open((Join-Path $hostRoot 'control.lock'), [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
$processes = [Collections.Generic.List[Diagnostics.Process]]::new()
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
    [IO.File]::WriteAllText($receipt.shutdownFile, [DateTime]::UtcNow.ToString('o') + "`n", $utf8)
    $receipt['shutdownRequestedUtc'] = [DateTime]::UtcNow.ToString('o')
    $deadline = [Diagnostics.Stopwatch]::StartNew()
    while ($deadline.Elapsed.TotalSeconds -lt $GraceSeconds -and @($processes | Where-Object { !$_.HasExited }).Count) { Start-Sleep -Milliseconds 100 }
    $forced = $false
    foreach ($process in $processes) {
        if (!$process.HasExited) {
            if (!$receipt.server) { throw 'Server identity was never established; refusing an unverified child-tree kill. Owned logs and receipt are retained.' }
            # InputObject retains the verified actual process handle; never kill by port or name.
            Stop-Process -InputObject $process -Force -ErrorAction Stop
            $forced = $true
        }
    }
    $cleanup = [Diagnostics.Stopwatch]::StartNew()
    while ($cleanup.Elapsed.TotalSeconds -lt $CleanupSeconds -and @($processes | Where-Object { !$_.HasExited }).Count) { Start-Sleep -Milliseconds 50 }
    if (@($processes | Where-Object { !$_.HasExited }).Count) { throw 'Owned Core processes did not exit within the cleanup budget.' }
    $receipt['status'] = 'STOPPED'; $receipt['forcedTermination'] = $forced; $receipt['stoppedUtc'] = [DateTime]::UtcNow.ToString('o')
    $temporary = $ReceiptPath + '.' + [guid]::NewGuid().ToString('N') + '.tmp'
    [IO.File]::WriteAllText($temporary, ($receipt | ConvertTo-Json -Depth 20) + "`n", $utf8)
    [IO.File]::Move($temporary, $ReceiptPath, $true)
    [pscustomobject]@{ status = 'STOPPED'; owned = $true; forcedTermination = $forced; receiptPath = $ReceiptPath }
} finally {
    foreach ($process in $processes) { $process.Dispose() }
    $controlLock.Dispose()
}
