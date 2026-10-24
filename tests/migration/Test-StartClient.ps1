#Requires -Version 7.0
# Offline launcher control-flow tests. Every Core helper and process launch is stubbed.
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (!$IsWindows) { throw 'These Windows launcher stub tests require Windows; no Linux runtime result is implied.' }
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$scratchParent = [IO.Path]::GetFullPath((Join-Path $repo '.local/tests/start-client'))
$fixtureRoot = Join-Path $scratchParent ([guid]::NewGuid().ToString('N'))
$previousProbe = Get-Variable -Name WarhammerStartClientTestProbe -Scope Global -ErrorAction SilentlyContinue
$caseCount = 0
$environmentNames = @('WH_CORE_ADMIN_TOKEN', 'WH_CORE_PLAYER_TOKEN', 'WH_CORE_PLAYER_B_TOKEN', 'WH_CORE_BASE_URL', 'WH_LIVE_CORE_TEST_URL')
$originalEnvironment = @{}
foreach ($name in $environmentNames) { $originalEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }

function Assert-True([bool]$Condition, [string]$Message) { if (!$Condition) { throw $Message } }
function Start-Process {
    param([string]$FilePath, [string]$ArgumentList, [string]$WorkingDirectory, [string]$WindowStyle, [switch]$PassThru)
    $probe = $global:WarhammerStartClientTestProbe
    $probe.LaunchCalls++
    if ($env:WH_CORE_PLAYER_B_TOKEN -cne 'stub-helper-WH_CORE_PLAYER_B_TOKEN') { throw 'Player-b child credential environment was not supplied' }
    $probe.FilePath = $FilePath; $probe.Arguments = $ArgumentList
    $probe.WorkingDirectory = $WorkingDirectory; $probe.WindowStyle = $WindowStyle
    if ($probe.LaunchFails) { throw 'Synthetic client launch failure' }
    $client = [pscustomobject]@{ ExitCode = $probe.ExitCode }
    $client | Add-Member ScriptMethod WaitForExit {
        $global:WarhammerStartClientTestProbe.WaitCalls++
        if ($global:WarhammerStartClientTestProbe.WaitFails) { throw 'Synthetic client wait failure' }
    }
    $client | Add-Member ScriptMethod Dispose {
        $global:WarhammerStartClientTestProbe.DisposeCalls++
        if ($global:WarhammerStartClientTestProbe.DisposeFails) { throw 'Synthetic client dispose failure' }
    }
    return $client
}
function Invoke-LauncherCase([hashtable]$Arguments, [hashtable]$Faults = @{}, [string]$ExpectedError = '',
    [hashtable]$InitialEnvironment = @{ WH_CORE_ADMIN_TOKEN = 'stub-parent-admin'; WH_CORE_PLAYER_TOKEN = 'stub-parent-player'; WH_CORE_PLAYER_B_TOKEN = 'stub-parent-player-b'; WH_CORE_BASE_URL = 'http://stub.invalid/'; WH_LIVE_CORE_TEST_URL = 'http://stub.invalid/test' }) {
    $expectedEnvironment = @{}
    foreach ($name in $environmentNames) {
        [Environment]::SetEnvironmentVariable($name, $InitialEnvironment[$name], 'Process')
        $expectedEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
    }
    $global:WarhammerStartClientTestProbe = [pscustomobject]@{
        HostCalls = 0; StopCalls = 0; LaunchCalls = 0; WaitCalls = 0; DisposeCalls = 0
        HostFails = $false; LaunchFails = $false; WaitFails = $false; DisposeFails = $false; StopFails = $false; ExitCode = 0
        Mode = ''; Port = 0; Endpoint = ''; CoreRoot = ''; CoreVersion = ''; ReadinessSeconds = 0
        FilePath = ''; Arguments = ''; WorkingDirectory = ''; WindowStyle = ''; StoppedReceipt = ''
    }
    foreach ($name in $Faults.Keys) { $global:WarhammerStartClientTestProbe.$name = $Faults[$name] }
    $failure = $null
    try { & $script:fixtureLauncher @Arguments 6>$null } catch { $failure = $_ }
    foreach ($name in $environmentNames) {
        Assert-True ([string]::Equals([Environment]::GetEnvironmentVariable($name, 'Process'), $expectedEnvironment[$name], [StringComparison]::Ordinal)) 'Launcher changed the parent Core environment'
    }
    if ($ExpectedError) {
        Assert-True ($null -ne $failure) 'Expected synthetic launcher failure did not occur'
        Assert-True ($failure.Exception.Message -like ('*' + $ExpectedError + '*')) 'Unexpected launcher error'
    } elseif ($failure) { throw $failure }
    $script:caseCount++
    return $global:WarhammerStartClientTestProbe
}

try {
    $scripts = Join-Path $fixtureRoot 'source checkout/scripts'
    [IO.Directory]::CreateDirectory($scripts) | Out-Null
    $script:fixtureLauncher = Join-Path $scripts 'Start-Client.ps1'
    Copy-Item -LiteralPath (Join-Path $repo 'scripts/Start-Client.ps1') -Destination $script:fixtureLauncher
    # This unchanged launcher copy resolves only inert sibling helpers. A function
    # intercepts the one unqualified Start-Process call before any native process API.
    $tokens = $null; $parseErrors = $null
    $ast = [Management.Automation.Language.Parser]::ParseFile($script:fixtureLauncher, [ref]$tokens, [ref]$parseErrors)
    $launchCommands = @($ast.FindAll({ param($node) $node -is [Management.Automation.Language.CommandAst] -and $node.GetCommandName() -eq 'Start-Process' }, $true))
    Assert-True ($parseErrors.Count -eq 0 -and $launchCommands.Count -eq 1) 'Unexpected launcher process seam'
    $startStub = @'
param($Mode, $Port, $Endpoint, $CoreRoot, $CoreVersion, $ReadinessSeconds)
$probe = $global:WarhammerStartClientTestProbe
$probe.HostCalls++; $probe.Mode = $Mode; $probe.Port = $Port
$probe.Endpoint = $Endpoint; $probe.CoreRoot = $CoreRoot; $probe.CoreVersion = $CoreVersion; $probe.ReadinessSeconds = $ReadinessSeconds
# The actual helper can initialize credentials before either success or failure.
foreach ($name in @('WH_CORE_ADMIN_TOKEN', 'WH_CORE_PLAYER_TOKEN', 'WH_CORE_PLAYER_B_TOKEN', 'WH_CORE_BASE_URL', 'WH_LIVE_CORE_TEST_URL')) {
    [Environment]::SetEnvironmentVariable($name, ('stub-helper-' + $name), 'Process')
}
if ($probe.HostFails) { throw 'Synthetic Core startup failure' }
[pscustomobject]@{ owned = ($Mode -eq 'Managed'); endpoint = 'http://127.0.0.1:8765/'; receiptPath = 'synthetic-owned-receipt' }
'@
    $stopStub = @'
param($ReceiptPath)
$global:WarhammerStartClientTestProbe.StopCalls++
$global:WarhammerStartClientTestProbe.StoppedReceipt = $ReceiptPath
if ($global:WarhammerStartClientTestProbe.StopFails) { throw 'Synthetic Core stop failure' }
'@
    [IO.File]::WriteAllText((Join-Path $scripts 'Start-CoreDevelopmentServer.ps1'), $startStub)
    [IO.File]::WriteAllText((Join-Path $scripts 'Stop-CoreDevelopmentServer.ps1'), $stopStub)
    $sourceRoot = Split-Path $scripts -Parent
    $project = Join-Path $sourceRoot 'WarhammerClient.uproject'
    [IO.File]::WriteAllText($project, '{}')
    $engine = Join-Path $fixtureRoot 'engine with spaces'
    $editor = Join-Path $engine 'Engine/Binaries/Win64/UnrealEditor.exe'
    [IO.Directory]::CreateDirectory((Split-Path $editor -Parent)) | Out-Null
    [IO.File]::WriteAllBytes($editor, [byte[]]@())
    $packaged = Join-Path $fixtureRoot 'packaged client with spaces/WarhammerClient.exe'
    [IO.Directory]::CreateDirectory((Split-Path $packaged -Parent)) | Out-Null
    [IO.File]::WriteAllBytes($packaged, [byte[]]@())
    $nested = Join-Path $fixtureRoot 'packaged client with spaces/WarhammerClient/Binaries/Win64/WarhammerClient.exe'
    [IO.Directory]::CreateDirectory((Split-Path $nested -Parent)) | Out-Null
    [IO.File]::WriteAllBytes($nested, [byte[]]@())

    $probe = Invoke-LauncherCase @{ EngineRoot = $engine; CoreRoot = 'synthetic Core with spaces'; Port = 8765; ReadinessSeconds = 30 }
    Assert-True ($probe.FilePath -ceq $editor -and $probe.WorkingDirectory -ceq $sourceRoot) 'Editor selection or CWD changed'
    Assert-True ($probe.Arguments -ceq ('"' + $project + '" "-game" "-windowed" "-CoreUrl=http://127.0.0.1:8765/"')) 'Editor argument vector changed'
    Assert-True ($probe.HostCalls -eq 1 -and $probe.Mode -eq 'Managed' -and $probe.ReadinessSeconds -eq 30 -and $probe.CoreRoot -ceq 'synthetic Core with spaces') 'Core startup arguments changed'
    Assert-True ($probe.CoreVersion -ceq '44.5.0') 'Default launcher must explicitly select the new Core profile'
    Assert-True ($probe.WaitCalls -eq 1 -and $probe.DisposeCalls -eq 1 -and $probe.StopCalls -eq 1 -and $probe.StoppedReceipt -ceq 'synthetic-owned-receipt') 'Owned Editor lifecycle changed'

    # Packaged selection works without either Editor or project files.
    Remove-Item -LiteralPath $project
    Remove-Item -LiteralPath $editor
    $probe = Invoke-LauncherCase @{ ClientExecutable = $packaged }
    Assert-True ($probe.FilePath -ceq $packaged -and $probe.WorkingDirectory -ceq (Split-Path $packaged -Parent)) 'Packaged path or CWD is wrong'
    Assert-True ($probe.Arguments -ceq '"-windowed" "-CoreUrl=http://127.0.0.1:8765/"') 'Packaged arguments include Editor-only values'
    Assert-True ($probe.StopCalls -eq 1 -and $probe.StoppedReceipt -ceq 'synthetic-owned-receipt') 'Packaged Managed Core was not stopped'

    $probe = Invoke-LauncherCase @{ ClientExecutable = $packaged; CoreVersion = '44.3.33' }
    Assert-True ($probe.CoreVersion -ceq '44.3.33' -and $probe.StopCalls -eq 1) 'Retained preview profile was not propagated'

    $probe = Invoke-LauncherCase @{ ClientExecutable = $nested; CoreMode = 'Attach'; Endpoint = [uri]'http://127.0.0.1:8765/' }
    Assert-True ($probe.FilePath -ceq $nested -and $probe.WorkingDirectory -ceq (Split-Path $nested -Parent)) 'Nested packaged binary path or CWD is wrong'
    Assert-True ($probe.Mode -eq 'Attach' -and $probe.StopCalls -eq 0 -and $probe.DisposeCalls -eq 1) 'Attached Core must remain running'

    $probe = Invoke-LauncherCase @{ ClientExecutable = (Join-Path $fixtureRoot 'absent.exe') } @{} 'Required client file is missing'
    Assert-True ($probe.HostCalls -eq 0 -and $probe.LaunchCalls -eq 0) 'Missing client must fail before Core startup'
    $probe = Invoke-LauncherCase @{ ClientExecutable = $packaged; EngineRoot = $engine } @{} 'Parameter set'
    Assert-True ($probe.HostCalls -eq 0 -and $probe.LaunchCalls -eq 0) 'Conflicting selection must fail before Core startup'

    $probe = Invoke-LauncherCase @{ ClientExecutable = $packaged } @{ HostFails = $true } 'Synthetic Core startup failure'
    Assert-True ($probe.LaunchCalls -eq 0 -and $probe.StopCalls -eq 0) 'A failed Core start must not launch a client or stop an unreturned receipt'
    $probe = Invoke-LauncherCase @{ ClientExecutable = $packaged } @{ LaunchFails = $true } 'Synthetic client launch failure'
    Assert-True ($probe.StopCalls -eq 1) 'Client launch failure skipped owned Core cleanup'
    $probe = Invoke-LauncherCase @{ ClientExecutable = $packaged } @{ ExitCode = 7 } 'exited with code 7'
    Assert-True ($probe.DisposeCalls -eq 1 -and $probe.StopCalls -eq 1) 'Nonzero client exit skipped owned cleanup'
    $probe = Invoke-LauncherCase @{ ClientExecutable = $packaged } @{ WaitFails = $true } 'Synthetic client wait failure'
    Assert-True ($probe.DisposeCalls -eq 1 -and $probe.StopCalls -eq 1) 'Client wait failure skipped owned cleanup'
    $probe = Invoke-LauncherCase @{ ClientExecutable = $packaged } @{ DisposeFails = $true } 'Synthetic client dispose failure'
    Assert-True ($probe.StopCalls -eq 1) 'Client disposal failure skipped owned Core cleanup'
    $probe = Invoke-LauncherCase @{ ClientExecutable = $packaged } @{ StopFails = $true } 'Synthetic Core stop failure'
    Assert-True ($probe.StopCalls -eq 1 -and $probe.DisposeCalls -eq 1) 'Owned Core stop failure skipped client cleanup'
    $probe = Invoke-LauncherCase @{ ClientExecutable = $packaged } @{ DisposeFails = $true; StopFails = $true } 'Synthetic client dispose failure'
    Assert-True ($probe.StopCalls -eq 1 -and $probe.DisposeCalls -eq 1) 'Combined cleanup failures skipped a cleanup attempt'
    $probe = Invoke-LauncherCase @{ ClientExecutable = $packaged } @{} '' @{}
    Assert-True ($probe.StopCalls -eq 1) 'Initially absent environment affected managed cleanup'
    $probe = Invoke-LauncherCase @{ ClientExecutable = $packaged } @{ HostFails = $true } 'Synthetic Core startup failure' @{}
    Assert-True ($probe.LaunchCalls -eq 0 -and $probe.StopCalls -eq 0) 'Failed initialization with absent environment launched or stopped a process'

    [pscustomobject]@{ status = 'PASS_STUB_ONLY'; cases = $caseCount; nativeProcessesLaunched = 0; coreProcessesLaunched = 0; guiLaunched = $false; linuxRuntimeEstablished = $false } | ConvertTo-Json
} finally {
    foreach ($name in $environmentNames) { [Environment]::SetEnvironmentVariable($name, $originalEnvironment[$name], 'Process') }
    if ($previousProbe) { Set-Variable -Name WarhammerStartClientTestProbe -Scope Global -Value $previousProbe.Value }
    else { Remove-Variable -Name WarhammerStartClientTestProbe -Scope Global -ErrorAction SilentlyContinue }
    # One shell performs cleanup, after checking the resolved target remains in
    # this test's workspace-owned scratch directory.
    $resolvedFixture = [IO.Path]::GetFullPath($fixtureRoot)
    if (!$resolvedFixture.StartsWith($scratchParent.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Refusing scratch cleanup outside its parent' }
    if (Test-Path -LiteralPath $resolvedFixture) { Remove-Item -LiteralPath $resolvedFixture -Recurse -Force }
}
