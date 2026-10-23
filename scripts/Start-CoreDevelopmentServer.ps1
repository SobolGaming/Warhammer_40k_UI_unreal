#Requires -Version 7.0
[CmdletBinding()]
param(
    [ValidateSet('Managed', 'Attach')][string]$Mode = 'Managed',
    [ValidateRange(1024, 65535)][int]$Port = 8765,
    [uri]$Endpoint,
    [string]$CoreRoot = (Join-Path $PSScriptRoot '../../Warhammer_40k_AI'),
    [ValidateRange(5, 120)][int]$ReadinessSeconds = 30
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$hostRoot = Join-Path $repo '.local/development/core-host'
$expectedCommit = '5f509724da25a2f6ded0c2739a8e7c84bdf59c91'
$expectedBuild = 'warhammer40k-core-v2:runtime-tree-sha256-v1:65fc8414407ae5d6a8ea779c8e737a22733459094db679a160c60f6e2129f96a'
$utf8 = [Text.UTF8Encoding]::new($false, $true)

function Assert-PlainPath([string]$Path) {
    $cursor = [IO.Path]::GetFullPath($Path)
    while ($cursor) {
        if ((Test-Path -LiteralPath $cursor) -and ((Get-Item -LiteralPath $cursor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Reparse points are not supported for development host paths.' }
        $parent = [IO.Directory]::GetParent($cursor)
        $cursor = if ($parent) { $parent.FullName } else { $null }
    }
}
function Write-Receipt([string]$Path, $Value) {
    $temporary = $Path + '.' + [guid]::NewGuid().ToString('N') + '.tmp'
    [IO.File]::WriteAllText($temporary, ($Value | ConvertTo-Json -Depth 12) + "`n", $utf8)
    [IO.File]::Move($temporary, $Path, $true)
}
function Get-OwnedIdentity([Diagnostics.Process]$Process) {
    $null = $Process.SafeHandle # Retain the actual process handle before observing identity.
    [ordered]@{ pid = $Process.Id; startTimeUtcTicks = $Process.StartTime.ToUniversalTime().Ticks; executable = $Process.MainModule.FileName }
}
function Read-StartupLog([string]$Path) {
    if (!(Test-Path -LiteralPath $Path)) { return '' }
    $stream = [IO.File]::Open($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
    try {
        $buffer = [byte[]]::new(65537)
        $count = $stream.Read($buffer, 0, $buffer.Length)
        if ($count -gt 65536) { throw 'Core startup stdout exceeded 64 KiB.' }
        $utf8.GetString($buffer, 0, $count)
    } finally { $stream.Dispose() }
}
function Test-Catalog([uri]$Base, [double]$TimeoutSeconds) {
    $handler = [Net.Http.HttpClientHandler]::new()
    $handler.AllowAutoRedirect = $false
    $handler.UseProxy = $false
    $client = [Net.Http.HttpClient]::new($handler)
    $client.Timeout = [TimeSpan]::FromSeconds($TimeoutSeconds)
    $request = [Net.Http.HttpRequestMessage]::new([Net.Http.HttpMethod]::Get, [uri]::new($Base, 'rules-catalog'))
    $request.Headers.Authorization = [Net.Http.Headers.AuthenticationHeaderValue]::new('Bearer', $env:WH_CORE_ADMIN_TOKEN)
    $response = $null
    try {
        $response = $client.SendAsync($request, [Net.Http.HttpCompletionOption]::ResponseHeadersRead).GetAwaiter().GetResult()
        if ([int]$response.StatusCode -ne 200) { throw ('Core catalog health returned HTTP ' + [int]$response.StatusCode + '.') }
        if ($response.Content.Headers.ContentType.MediaType -cne 'application/json') { throw 'Core catalog health did not return JSON.' }
        [ordered]@{ path = '/rules-catalog'; httpStatus = 200; authenticated = $true; observedUtc = [DateTime]::UtcNow.ToString('o') }
    } finally {
        if ($response) { $response.Dispose() }
        $request.Dispose(); $client.Dispose()
    }
}

$CoreRoot = [IO.Path]::GetFullPath($CoreRoot)
Assert-PlainPath $CoreRoot
Assert-PlainPath $hostRoot
if (!$Endpoint) { $Endpoint = [uri]("http://127.0.0.1:$Port/") }
if ($Endpoint.Scheme -cnotin @('http', 'https') -or $Endpoint.UserInfo -or $Endpoint.Query -or $Endpoint.Fragment -or $Endpoint.AbsolutePath -cne '/') { throw 'Endpoint must be an HTTP(S) origin, without credentials, query or path.' }
if ($Mode -eq 'Managed' -and $Endpoint.AbsoluteUri -cne "http://127.0.0.1:$Port/") { throw 'Managed mode uses only 127.0.0.1 and the selected dedicated port.' }
if ($Mode -eq 'Managed' -and !$IsWindows) { throw 'The prepared managed runtime is Windows-only. Use the documented native Linux recipe or Attach.' }

$git = (Get-Command git -CommandType Application -ErrorAction Stop).Source
$gitOptions = @('--no-optional-locks', '-c', 'core.fsmonitor=false', '-c', 'core.untrackedCache=false', '-c', 'core.hooksPath=NUL', '-C', $CoreRoot)
$head = @(& $git @gitOptions rev-parse HEAD 2>&1)
if ($LASTEXITCODE -ne 0 -or $head.Count -ne 1 -or $head[0] -cne $expectedCommit) { throw 'Core checkout must be at the selected 5f509724 commit.' }
$changes = @(& $git @gitOptions status --porcelain=v1 --untracked-files=normal 2>&1)
if ($LASTEXITCODE -ne 0 -or $changes.Count) { throw 'Core checkout must be clean; this helper never resets or changes it.' }

# Read only the two named simple literals from this pinned development registry.
# They stay in process environment/memory, never in a receipt or command line.
$registry = [IO.File]::ReadAllText((Join-Path $CoreRoot 'src/warhammer40k_core/adapters/access_control.py'))
foreach ($entry in @(@('WH_CORE_ADMIN_TOKEN', 'DEV_ADMIN_TOKEN'), @('WH_CORE_PLAYER_TOKEN', 'DEV_PLAYER_A_TOKEN'))) {
    if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($entry[0], 'Process'))) {
        $credentialMatches = [regex]::Matches($registry, ('(?m)^' + $entry[1] + ' = "([^"\\\r\n]+)"\r?$'))
        if ($credentialMatches.Count -ne 1) { throw 'Pinned development credential declaration was not found in the expected form.' }
        [Environment]::SetEnvironmentVariable($entry[0], $credentialMatches[0].Groups[1].Value, 'Process')
    }
}
foreach ($credentialName in @('WH_CORE_ADMIN_TOKEN', 'WH_CORE_PLAYER_TOKEN')) {
    $credentialValue = [Environment]::GetEnvironmentVariable($credentialName, 'Process')
    if ($credentialValue.Length -gt 256 -or $credentialValue -cnotmatch '^[A-Za-z0-9._~+/\-]+=*$') {
        throw ($credentialName + ' must contain a valid bearer token of at most 256 ASCII characters; its value is not displayed.')
    }
}
$env:WH_CORE_BASE_URL = $Endpoint.AbsoluteUri.TrimEnd('/')
[IO.Directory]::CreateDirectory($hostRoot) | Out-Null
$controlLock = [IO.File]::Open((Join-Path $hostRoot 'control.lock'), [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
$receiptPath = $null; $receipt = $null; $launcher = $null
try {
    if ($Mode -eq 'Attach') {
        $health = Test-Catalog $Endpoint 3
        $attachRoot = Join-Path $hostRoot ('attach-' + [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ') + '-' + [guid]::NewGuid().ToString('N'))
        [IO.Directory]::CreateDirectory($attachRoot) | Out-Null
        $receiptPath = Join-Path $attachRoot 'receipt.json'
        Write-Receipt $receiptPath ([ordered]@{ recordKind = 'WARHAMMER_CORE_DEVELOPMENT_HOST'; mode = 'Attach'; owned = $false; status = 'ATTACHED_HEALTHY'; endpoint = $Endpoint.AbsoluteUri; health = $health; serviceIdentity = 'NOT_VERIFIED_BY_ATTACHMENT'; createdUtc = [DateTime]::UtcNow.ToString('o') })
        [pscustomobject]@{ mode = 'Attach'; status = 'ATTACHED_HEALTHY'; owned = $false; endpoint = $Endpoint.AbsoluteUri; receiptPath = $receiptPath }
        return
    }
    $current = Join-Path $hostRoot 'current.json'
    if (Test-Path -LiteralPath $current) {
        $previous = Get-Content -LiteralPath $current -Raw | ConvertFrom-Json -AsHashtable
        $old = Get-Content -LiteralPath $previous.receiptPath -Raw | ConvertFrom-Json -AsHashtable
        if ($old.status -cnotin @('STOPPED', 'START_FAILED_CLEANED')) { throw 'A managed receipt is still active or uncertain. Stop it explicitly before starting another server.' }
    }
    $runtime = Join-Path $repo '.local/core-44.3.33'
    Assert-PlainPath $runtime
    $python = Join-Path $runtime 'Scripts/python.exe'
    if ((Get-FileHash -LiteralPath $python -Algorithm SHA256).Hash -cne '8E0C2B85DAD09707B0DC6A9561F8E7AF0C303A59F9C00A6C0FE6E5829B48018E') { throw 'Prepared runtime Python identity differs; no runtime is installed automatically.' }
    $provenance = Get-Content -LiteralPath (Join-Path $runtime '.e01-provenance.json') -Raw | ConvertFrom-Json -AsHashtable -Depth 100
    if ($provenance.status -cne 'INSTALLED_RUNTIME_PASS' -or $provenance.coreCommit -cne $expectedCommit -or $provenance.runtimeBuildId -cne $expectedBuild) { throw 'Prepared Core runtime provenance differs.' }
    $config = [IO.File]::ReadAllText((Join-Path $runtime 'pyvenv.cfg'))
    $baseHome = [regex]::Match($config, '(?m)^home = (.+)\r?$')
    if (!$baseHome.Success) { throw 'Prepared runtime base interpreter is not recorded.' }
    $basePython = Join-Path ($baseHome.Groups[1].Value.Trim()) 'python.exe'
    if ((Get-FileHash -LiteralPath $basePython -Algorithm SHA256).Hash -cne '5556F2048A17B14693FFADEB25DC0ADD537933873CEE2CA623CF981CA65A6168') { throw 'Prepared runtime base interpreter changed.' }
    # Availability probe only; Core #589 still limits late Windows co-bind exclusivity.
    $probe = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, $Port)
    try { $probe.Server.ExclusiveAddressUse = $true; $probe.Start() } finally { $probe.Stop() }
    $runRoot = Join-Path $hostRoot ([DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ') + '-' + [guid]::NewGuid().ToString('N'))
    [IO.Directory]::CreateDirectory($runRoot) | Out-Null
    $receiptPath = Join-Path $runRoot 'receipt.json'
    $shutdown = Join-Path $runRoot 'shutdown.requested'
    $stdout = Join-Path $runRoot 'stdout.log'; $stderr = Join-Path $runRoot 'stderr.log'
    $nonce = [guid]::NewGuid().ToString('N')
    $bootstrapPath = Join-Path $runRoot 'bootstrap.py'
    $bootstrap = @'
import json, os, pathlib, runpy, sys
runtime, launcher, build, port, shutdown, nonce = sys.argv[1:]
print('WH_CORE_HOST_IDENTITY ' + json.dumps({'nonce': nonce, 'pid': os.getpid(), 'parentPid': os.getppid(), 'baseExecutable': sys._base_executable}), flush=True)
if sys.version_info[:3] != (3, 14, 5) or pathlib.Path(sys.prefix).resolve() != pathlib.Path(runtime).resolve():
    raise RuntimeError('Prepared interpreter identity differs')
import warhammer40k_core
if not pathlib.Path(warhammer40k_core.__file__).resolve().is_relative_to(pathlib.Path(runtime).resolve()):
    raise RuntimeError('Core resolved outside prepared runtime')
from warhammer40k_core.build_identity import verified_engine_build_identity
identity = verified_engine_build_identity()
if identity.build_id != build or identity.resource_count != 3116:
    raise RuntimeError('Prepared Core build identity differs')
print('WH_CORE_RUNTIME_VERIFIED ' + build, flush=True)
sys.argv = [launcher, '--host', '127.0.0.1', '--port', port, '--shutdown-file', shutdown]
runpy.run_path(launcher, run_name='__main__')
'@
    [IO.File]::WriteAllText($bootstrapPath, $bootstrap + "`n", $utf8)
    $arguments = @('-I', '-B', '-u', $bootstrapPath, $runtime, (Join-Path $CoreRoot 'scripts/run_phase18m_reference_server.py'), $expectedBuild, [string]$Port, $shutdown, $nonce)
    $quoted = @($arguments | ForEach-Object { if ($_.Contains('"') -or $_.EndsWith('\')) { throw 'Unsupported quote/trailing separator in launch argument.' }; '"' + $_ + '"' }) -join ' '
    $launcher = Start-Process -FilePath $python -ArgumentList $quoted -WorkingDirectory $runRoot -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru
    $receipt = [ordered]@{ recordKind = 'WARHAMMER_CORE_DEVELOPMENT_HOST'; mode = 'Managed'; owned = $true; status = 'STARTING'; endpoint = $Endpoint.AbsoluteUri; coreCommit = $expectedCommit; contractVersion = '44.3.33'; runtimeBuildId = $expectedBuild; runRoot = $runRoot; nonce = $nonce; launcher = (Get-OwnedIdentity $launcher); server = $null; expectedServerExecutable = $basePython; shutdownFile = $shutdown; stdout = $stdout; stderr = $stderr; createdUtc = [DateTime]::UtcNow.ToString('o'); portExclusivity = 'Prelaunch availability probe only; Core #589 remains.' }
    Write-Receipt $receiptPath $receipt
    Write-Receipt $current ([ordered]@{ receiptPath = $receiptPath })
    $clock = [Diagnostics.Stopwatch]::StartNew()
    $healthFailure = 'Core readiness marker not observed.'
    while ($clock.Elapsed.TotalSeconds -lt $ReadinessSeconds) {
        if ($launcher.HasExited) { throw 'Core launcher exited before readiness. Inspect the owned logs.' }
        $text = Read-StartupLog $stdout
        $lines = @($text -split '\r?\n')
        if (!$receipt.server) {
            $identityLines = @($lines | Where-Object { $_.StartsWith('WH_CORE_HOST_IDENTITY ', [StringComparison]::Ordinal) })
            if ($identityLines.Count -gt 1) { throw 'Duplicate Core process identity marker.' }
            if ($identityLines.Count -eq 1) {
                $identity = $identityLines[0].Substring(22) | ConvertFrom-Json -AsHashtable
                if ($identity.nonce -cne $nonce -or ($identity.pid -ne $launcher.Id -and $identity.parentPid -ne $launcher.Id) -or $identity.baseExecutable -ine $basePython) { throw 'Owned Core process identity marker differs.' }
                $server = [Diagnostics.Process]::GetProcessById([int]$identity.pid)
                try { $receipt.server = Get-OwnedIdentity $server } finally { $server.Dispose() }
                if ($receipt.server.executable -ine $basePython -and $receipt.server.executable -ine $python) { throw 'Owned Core process executable differs.' }
                Write-Receipt $receiptPath $receipt
            }
        }
        if ($receipt.server -and ('WH_CORE_RUNTIME_VERIFIED ' + $expectedBuild) -cin $lines -and ("Serving Phase 18M reference contract at http://127.0.0.1:$Port") -cin $lines) {
            try {
                $health = Test-Catalog $Endpoint ([Math]::Min(3, [Math]::Max(0.1, $ReadinessSeconds - $clock.Elapsed.TotalSeconds)))
                if ($launcher.HasExited) { throw 'Core launcher exited during readiness.' }
                $receipt.status = 'READY'; $receipt['health'] = $health; $receipt['readyUtc'] = [DateTime]::UtcNow.ToString('o')
                Write-Receipt $receiptPath $receipt
                [pscustomobject]@{ mode = 'Managed'; status = 'READY'; owned = $true; endpoint = $Endpoint.AbsoluteUri; pid = $receipt.server.pid; receiptPath = $receiptPath }
                return
            } catch { $healthFailure = $_.Exception.Message }
        }
        Start-Sleep -Milliseconds 100
    }
    throw ('Core readiness exceeded ' + $ReadinessSeconds + ' seconds. ' + $healthFailure)
} catch {
    if ($receipt -and $receiptPath) {
        $receipt.status = 'START_FAILED'; Write-Receipt $receiptPath $receipt
        # Release the control lock before the stop helper acquires it.
        $controlLock.Dispose(); $controlLock = $null
        & (Join-Path $PSScriptRoot 'Stop-CoreDevelopmentServer.ps1') -ReceiptPath $receiptPath | Out-Null
    }
    throw
} finally {
    if ($controlLock) { $controlLock.Dispose() }
    if ($launcher) { $launcher.Dispose() }
}
