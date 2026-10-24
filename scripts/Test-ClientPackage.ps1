#Requires -Version 7.0
# Nonvisible automation only; never remove NullRHI/RenderOffScreen during a screen HOLD.
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$ClientExecutable,
    [ValidateSet('Resources', 'Core')][string]$Mode = 'Resources',
    [ValidateSet('Managed', 'Attach')][string]$CoreMode = 'Managed',
    [ValidateRange(1024, 65535)][int]$Port = 19084,
    [string]$Endpoint,
    [string]$CoreRoot = (Join-Path $PSScriptRoot '../../Warhammer_40k_AI')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
if (!$IsWindows) { throw 'This runner requires native Windows; Linux remains untested.' }
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$utf8 = [Text.UTF8Encoding]::new($false, $true)
$environmentNames = @('WH_CORE_ADMIN_TOKEN', 'WH_CORE_PLAYER_TOKEN', 'WH_CORE_BASE_URL', 'WH_LIVE_CORE_TEST_URL')
$savedEnvironment = @{}
foreach ($name in $environmentNames) { $savedEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }

function Assert-PlainPath([string]$Path) {
    $cursor = [IO.Path]::GetFullPath($Path)
    while ($cursor) {
        if ((Test-Path -LiteralPath $cursor) -and ((Get-Item -LiteralPath $cursor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw 'Reparse points are not supported for package-test paths.'
        }
        $parent = [IO.Directory]::GetParent($cursor)
        $cursor = if ($parent) { $parent.FullName } else { $null }
    }
}
function File-Descriptor([string]$Path) {
    if (![IO.File]::Exists($Path)) { return $null }
    [ordered]@{ leaf = [IO.Path]::GetFileName($Path); bytes = [IO.FileInfo]::new($Path).Length; sha256 = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash }
}
function Config-Snapshot {
    $snapshot = @{}
    foreach ($file in Get-ChildItem -LiteralPath (Join-Path $repo 'Config') -File -Recurse) {
        $snapshot[[IO.Path]::GetRelativePath((Join-Path $repo 'Config'), $file.FullName)] = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
    }
    return $snapshot
}
function Unreal-Arguments([string[]]$Values) {
    # Unreal FParse expects quotes immediately after '=' for spaced values.
    (@(foreach ($value in $Values) {
        if ($value.Contains('"') -or $value.EndsWith('\') -or $value.Contains("`r") -or $value.Contains("`n")) { throw 'Unsupported launch argument.' }
        if ($value.StartsWith('-') -and $value.Contains('=')) {
            $split = $value.IndexOf('=')
            $value.Substring(0, $split + 1) + '"' + $value.Substring($split + 1) + '"'
        } elseif ($value.StartsWith('-')) { $value } else { '"' + $value + '"' }
    })) -join ' '
}
function New-Reader($InputStream, $OutputStream) {
    $buffer = [byte[]]::new(65536)
    return @{ input = $InputStream; output = $OutputStream; buffer = $buffer; pending = $InputStream.ReadAsync($buffer, 0, $buffer.Length); done = $false; bytes = 0L; capped = $false }
}
function Poll-Reader($Reader) {
    # Only the main thread writes files. Each async operation holds at most 64 KiB.
    for ($batch = 0; $batch -lt 16 -and !$Reader.done -and $Reader.pending.IsCompleted; $batch++) {
        $count = $Reader.pending.GetAwaiter().GetResult()
        if ($count -eq 0) { $Reader.done = $true; return }
        $keep = [int][Math]::Min($count, [Math]::Max(0L, 64MB - $Reader.bytes))
        if ($keep -gt 0) { $Reader.output.Write($Reader.buffer, 0, $keep); $Reader.bytes += $keep }
        if ($keep -ne $count) { $Reader.capped = $true; throw 'Native stream exceeded its 64 MiB retained-file limit.' }
        $Reader.pending = $Reader.input.ReadAsync($Reader.buffer, 0, $Reader.buffer.Length)
    }
}
function Need-Integer($Object, [string]$Name, [long]$Expected) {
    if ($Object -isnot [Collections.IDictionary] -or !$Object.Contains($Name) -or
        ($Object[$Name] -isnot [int] -and $Object[$Name] -isnot [long]) -or $Object[$Name] -ne $Expected) {
        throw 'Automation report has a missing, noninteger or unexpected count.'
    }
}
function Validate-Report([string]$Path, [string[]]$Expected) {
    if (![IO.File]::Exists($Path) -or [IO.FileInfo]::new($Path).Length -gt 64MB) { throw 'Automation report is missing or exceeds its limit.' }
    $report = [IO.File]::ReadAllText($Path, $utf8) | ConvertFrom-Json -AsHashtable -Depth 60
    Need-Integer $report 'succeeded' $Expected.Count
    foreach ($key in @('succeededWithWarnings', 'failed', 'notRun', 'inProcess')) { Need-Integer $report $key 0 }
    if (!$report.Contains('tests') -or $report.tests -isnot [array] -or $report.tests.Count -ne $Expected.Count) { throw 'Automation report test count differs.' }
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($test in $report.tests) {
        if ($test -isnot [Collections.IDictionary] -or !$test.Contains('fullTestPath') -or $test.fullTestPath -isnot [string] -or
            !$Expected.Contains($test.fullTestPath) -or !$seen.Add($test.fullTestPath) -or !$test.Contains('state') -or $test.state -cne 'Success') {
            throw 'Automation report has an unexpected, duplicate or unsuccessful test.'
        }
        Need-Integer $test 'warnings' 0
        Need-Integer $test 'errors' 0
        if (!$test.Contains('entries') -or $test.entries -isnot [array]) { throw 'Automation report entries are missing.' }
        foreach ($entry in $test.entries) {
            if ($entry -isnot [Collections.IDictionary] -or !$entry.Contains('event') -or $entry.event -isnot [Collections.IDictionary] -or
                !$entry.event.Contains('type') -or $entry.event.type -cnotin @('Info', 'Warning', 'Error')) { throw 'Automation report entry type is missing or unknown.' }
            if ($entry.event.type -cne 'Info') { throw 'Automation report contains a warning or error entry.' }
        }
    }
    [ordered]@{ expectedCount = $Expected.Count; succeeded = $Expected.Count; succeededWithWarnings = 0; failed = 0; notRun = 0; inProcess = 0; tests = @($Expected | ForEach-Object { @{ name = $_; state = 'Success'; warnings = 0; errors = 0 } }) }
}

$run = Join-Path $repo ('.local/testpackage/' + [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ') + '-' + [guid]::NewGuid().ToString('N'))
Assert-PlainPath $run
if (Test-Path -LiteralPath $run) { throw 'A new package-test output directory is required.' }
[IO.Directory]::CreateDirectory($run) | Out-Null
$reportRoot = Join-Path $run 'report'
$nativeLog = Join-Path $run 'native.log'
$resultPath = Join-Path $run 'result.json'
$record = [ordered]@{
    kind = 'WINDOWS_NONVISIBLE_PACKAGE_TEST'; status = 'FAILED'; mode = $Mode; coreMode = if ($Mode -eq 'Core') { $CoreMode } else { $null }
    startedUtc = [DateTime]::UtcNow.ToString('o'); finishedUtc = $null; sourceHead = $null; runner = (File-Descriptor $PSCommandPath)
    binaryBefore = $null; binaryAfter = $null; arguments = @(); rawArguments = $null; nonVisibleFlagsRequired = $true; renderingVerified = $false
    timeoutSeconds = if ($Mode -eq 'Resources') { 120 } else { 240 }; streamLimitBytes = 64MB
    processStarted = $false; nativeExitCode = $null; elapsedSeconds = $null; forcedTermination = $false
    stdoutComplete = $false; stderrComplete = $false; streamsCapped = $false
    host = $null; hostStop = $null; parentEnvironmentRestored = $false; configUnchanged = $null
    configBefore = $null; configAfter = $null; automation = $null; raw = @{}; failureStage = $null; errorType = $null; cleanupErrors = @()
    limits = 'NullRHI checks runtime availability and automation only; no rendered/input, clean-machine or Linux acceptance.'
}
[string[]]$expected = if ($Mode -eq 'Resources') {
    @('Warhammer.RuntimeData.CanonicalSession', 'Warhammer.RuntimeData.MissingSessionFails', 'Warhammer.RuntimeData.CorruptSessionFails', 'Warhammer.RuntimeData.StartupResources')
} else { @('Warhammer.LiveCore.Integration.RealSessionAction') }
$hostInfo = $null; $native = $null; $started = $false; $outFile = $null; $errFile = $null; $outReader = $null; $errReader = $null
$timer = $null; $stage = 'INPUTS'; $validated = $false
try {
    $binary = [IO.Path]::GetFullPath($ClientExecutable)
    Assert-PlainPath $binary
    if ($binary.Replace('\', '/') -inotmatch '/WarhammerClient/Binaries/Win64/WarhammerClient\.exe$' -or ![IO.File]::Exists($binary)) {
        throw 'Select the actual nested WarhammerClient/Binaries/Win64/WarhammerClient.exe, not the bootstrap executable.'
    }
    if ($Mode -eq 'Resources' -and $Endpoint) { throw 'Resources mode does not use a Core endpoint.' }
    $coreEndpoint = if ($Endpoint) { $Endpoint } else { "http://127.0.0.1:$Port" }
    if ($Mode -eq 'Core') {
        if ($coreEndpoint -cnotmatch '^http://127\.0\.0\.1:([0-9]{1,5})/?$') { throw 'Core endpoint must be http://127.0.0.1:<port>.' }
        $endpointPort = [int]$Matches[1]
        if ($endpointPort -lt 1024 -or $endpointPort -gt 65535 -or ($CoreMode -eq 'Managed' -and $endpointPort -ne $Port)) { throw 'Core endpoint port is invalid or differs from the managed port.' }
        $coreEndpoint = "http://127.0.0.1:$endpointPort/"
    }
    $head = @(git --no-optional-locks -C $repo rev-parse HEAD 2>&1)
    if ($LASTEXITCODE -ne 0 -or $head.Count -ne 1 -or $head[0] -cnotmatch '^[0-9a-f]{40}$') { throw 'Source HEAD could not be recorded.' }
    $record.sourceHead = $head[0]
    $record.binaryBefore = File-Descriptor $binary
    $record.configBefore = Config-Snapshot
    if ($Mode -eq 'Core') {
        $stage = 'CORE_START'
        $hostInfo = & (Join-Path $PSScriptRoot 'Start-CoreDevelopmentServer.ps1') -Mode $CoreMode -Port $Port -Endpoint ([uri]$coreEndpoint) -CoreRoot $CoreRoot
        if (!$hostInfo -or $hostInfo.owned -isnot [bool] -or $hostInfo.owned -ne ($CoreMode -eq 'Managed') -or $hostInfo.endpoint -cne $coreEndpoint -or !$hostInfo.receiptPath) { throw 'Core helper returned inconsistent ownership or endpoint.' }
        $record.host = @{ mode = $CoreMode; owned = $hostInfo.owned; status = $hostInfo.status; receipt = (File-Descriptor $hostInfo.receiptPath) }
    }
    $stage = 'NATIVE_START'
    $selector = if ($Mode -eq 'Resources') { 'Warhammer.RuntimeData' } else { $expected[0] }
    $arguments = @('-NullRHI', '-RenderOffScreen', '-unattended', '-nosplash', '-nosound', '-nowrite', '-stdout', '-FullStdOutLogOutput', '-NoCrashDialog', '-NoLiveCoding',
        ('-UserDir=' + (Join-Path $run 'user')), ('-abslog=' + $nativeLog), ('-ReportExportPath=' + $reportRoot),
        ('-ExecCmds=Automation RunTests ' + $selector), '-TestExit=Automation Test Queue Empty')
    $record.arguments = $arguments
    $info = [Diagnostics.ProcessStartInfo]::new($binary)
    $info.WorkingDirectory = [IO.Path]::GetDirectoryName($binary)
    $info.UseShellExecute = $false; $info.CreateNoWindow = $true; $info.WindowStyle = [Diagnostics.ProcessWindowStyle]::Hidden
    $info.RedirectStandardOutput = $true; $info.RedirectStandardError = $true
    $info.Arguments = Unreal-Arguments $arguments
    $record.rawArguments = $info.Arguments
    foreach ($name in @('GH_TOKEN', 'GITHUB_TOKEN')) { $null = $info.Environment.Remove($name) }
    if ($Mode -eq 'Resources') {
        foreach ($name in $environmentNames) { $null = $info.Environment.Remove($name) }
    } else { $info.Environment['WH_LIVE_CORE_TEST_URL'] = $hostInfo.endpoint.TrimEnd('/') }
    $outFile = [IO.File]::Create((Join-Path $run 'stdout.log'))
    $errFile = [IO.File]::Create((Join-Path $run 'stderr.log'))
    $native = [Diagnostics.Process]::new(); $native.StartInfo = $info
    if (!$native.Start()) { throw 'Packaged Game did not start.' }
    $started = $true; $record.processStarted = $true; $timer = [Diagnostics.Stopwatch]::StartNew()
    $outReader = New-Reader $native.StandardOutput.BaseStream $outFile
    $errReader = New-Reader $native.StandardError.BaseStream $errFile
    $null = $native.SafeHandle # Retain this actual started process; never look up by name or port.
    $stage = 'NATIVE_WAIT'
    do {
        Poll-Reader $outReader; Poll-Reader $errReader
        if ($timer.Elapsed.TotalSeconds -gt $record.timeoutSeconds) { throw 'Native automation exceeded its time budget.' }
        if ($native.HasExited) { break }
        Start-Sleep -Milliseconds 20
    } while ($true)
    $record.nativeExitCode = $native.ExitCode; $record.elapsedSeconds = $timer.Elapsed.TotalSeconds
    $stage = 'STREAM_DRAIN'
    $drain = [Diagnostics.Stopwatch]::StartNew()
    while ((!$outReader.done -or !$errReader.done) -and $drain.Elapsed.TotalSeconds -lt 10) { Poll-Reader $outReader; Poll-Reader $errReader; Start-Sleep -Milliseconds 10 }
    if (!$outReader.done -or !$errReader.done) { throw 'Native output did not finish within the drain budget.' }
    $stage = 'AUTOMATION_REPORT'
    if ($record.nativeExitCode -ne 0) { throw 'Native automation exited unsuccessfully.' }
    $record.automation = Validate-Report (Join-Path $reportRoot 'index.json') $expected
    $validated = $true
} catch {
    $record.failureStage = $stage; $record.errorType = $_.Exception.GetType().FullName
} finally {
    # Each independent cleanup runs even if a previous cleanup fails.
    try {
        if ($started) {
            if (!$native.HasExited) { $native.Kill($true); $record.forcedTermination = $true; if (!$native.WaitForExit(10000)) { throw 'Owned native process did not exit.' } }
            $record.nativeExitCode = $native.ExitCode
            if ($timer) { $record.elapsedSeconds = $timer.Elapsed.TotalSeconds }
        }
    } catch { $record.cleanupErrors += 'NATIVE_STOP:' + $_.Exception.GetType().Name }
    try {
        if ($outReader -and $errReader) {
            $drain = [Diagnostics.Stopwatch]::StartNew()
            while ((!$outReader.done -or !$errReader.done) -and !$outReader.capped -and !$errReader.capped -and $drain.Elapsed.TotalSeconds -lt 2) { Poll-Reader $outReader; Poll-Reader $errReader; Start-Sleep -Milliseconds 10 }
        }
    } catch { $record.cleanupErrors += 'STREAM_DRAIN:' + $_.Exception.GetType().Name }
    foreach ($reader in @($outReader, $errReader)) {
        try { if ($reader) { $reader.input.Dispose(); if ($reader.pending.IsFaulted) { $null = $reader.pending.Exception } } } catch { $record.cleanupErrors += 'STREAM_CLOSE:' + $_.Exception.GetType().Name }
    }
    foreach ($stream in @($outFile, $errFile)) {
        try { if ($stream) { $stream.Dispose() } } catch { $record.cleanupErrors += 'FILE_CLOSE:' + $_.Exception.GetType().Name }
    }
    try { if ($native) { $native.Dispose() } } catch { $record.cleanupErrors += 'PROCESS_DISPOSE:' + $_.Exception.GetType().Name }
    try {
        if ($hostInfo -and $hostInfo.owned -is [bool] -and $hostInfo.owned) {
            $stop = & (Join-Path $PSScriptRoot 'Stop-CoreDevelopmentServer.ps1') -ReceiptPath $hostInfo.receiptPath
            $record.hostStop = @{ status = $stop.status; owned = $stop.owned; forcedTermination = if ($stop.PSObject.Properties['forcedTermination']) { $stop.forcedTermination } else { $null } }
            if ($stop.status -cnotin @('STOPPED', 'ALREADY_STOPPED') -or $stop.owned -ne $true -or $record.hostStop.forcedTermination -eq $true) { throw 'Owned Core did not stop normally.' }
        } elseif ($Mode -eq 'Core' -and $hostInfo -and $hostInfo.owned -is [bool] -and !$hostInfo.owned) { $record.hostStop = @{ status = 'ATTACHED_NOT_STOPPED'; owned = $false } }
    } catch { $record.cleanupErrors += 'CORE_STOP:' + $_.Exception.GetType().Name }
    foreach ($name in $environmentNames) {
        try { [Environment]::SetEnvironmentVariable($name, $savedEnvironment[$name], 'Process') } catch { $record.cleanupErrors += 'ENVIRONMENT_RESTORE:' + $_.Exception.GetType().Name }
    }
    try {
        $record.parentEnvironmentRestored = $true
        foreach ($name in $environmentNames) { if (![string]::Equals([Environment]::GetEnvironmentVariable($name, 'Process'), $savedEnvironment[$name], [StringComparison]::Ordinal)) { $record.parentEnvironmentRestored = $false } }
        if (!$record.parentEnvironmentRestored) { throw 'Parent environment differs after restoration.' }
    } catch { $record.cleanupErrors += 'ENVIRONMENT_CHECK:' + $_.Exception.GetType().Name }
    try {
        $record.configAfter = Config-Snapshot
        if ($null -ne $record.configBefore) {
            $record.configUnchanged = $record.configBefore.Count -eq $record.configAfter.Count
            foreach ($name in $record.configBefore.Keys) { if (!$record.configAfter.ContainsKey($name) -or $record.configBefore[$name] -cne $record.configAfter[$name]) { $record.configUnchanged = $false } }
        }
        if ($record.binaryBefore) { $record.binaryAfter = File-Descriptor $binary }
        if ($outReader) { $record.stdoutComplete = $outReader.done }
        if ($errReader) { $record.stderrComplete = $errReader.done }
        $record.streamsCapped = ($outReader -and $outReader.capped) -or ($errReader -and $errReader.capped)
        foreach ($pair in @(@('stdout', (Join-Path $run 'stdout.log')), @('stderr', (Join-Path $run 'stderr.log')), @('nativeLog', $nativeLog), @('automationIndex', (Join-Path $reportRoot 'index.json')))) { $record.raw[$pair[0]] = File-Descriptor $pair[1] }
    } catch { $record.cleanupErrors += 'FINAL_METADATA:' + $_.Exception.GetType().Name }
    if ($validated -and !$record.forcedTermination -and $record.stdoutComplete -and $record.stderrComplete -and !$record.streamsCapped -and
        $record.parentEnvironmentRestored -and $record.configUnchanged -eq $true -and $record.binaryAfter -and
        $record.binaryBefore.sha256 -ceq $record.binaryAfter.sha256 -and $record.cleanupErrors.Count -eq 0) { $record.status = 'PASS' }
    elseif ($record.cleanupErrors.Count -gt 0) { $record.status = 'CLEANUP_FAILED' }
    $record.finishedUtc = [DateTime]::UtcNow.ToString('o')
    [IO.File]::WriteAllText($resultPath, ($record | ConvertTo-Json -Depth 15) + "`n", $utf8)
}
if ($record.status -cne 'PASS') { throw ('Package test failed; inspect retained result: ' + $resultPath) }
[pscustomobject]@{ status = $record.status; mode = $Mode; runRoot = $run; resultPath = $resultPath; tests = $expected.Count; nativeExitCode = $record.nativeExitCode }
