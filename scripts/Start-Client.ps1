#Requires -Version 7.0
# Interactive user entry point. Do not invoke during an owner screen HOLD.
[CmdletBinding(DefaultParameterSetName = 'Editor')]
param(
    [ValidateSet('Managed', 'Attach')][string]$CoreMode = 'Managed',
    [ValidateRange(1024, 65535)][int]$Port = 8765,
    [uri]$Endpoint,
    [Parameter(ParameterSetName = 'Editor')][string]$EngineRoot = 'C:/Program Files/Epic Games/UE_5.8',
    [Parameter(Mandatory, ParameterSetName = 'Packaged')][ValidateNotNullOrEmpty()][string]$ClientExecutable,
    [ValidateSet('44.5.0', '44.3.33')][string]$CoreVersion = '44.5.0',
    [string]$CoreRoot,
    [ValidateRange(5, 120)][int]$ReadinessSeconds = 60
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (!$IsWindows) { throw 'This interactive launcher currently targets Windows. Linux is untested.' }
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if ($PSCmdlet.ParameterSetName -eq 'Packaged') {
    $clientPath = [IO.Path]::GetFullPath($ClientExecutable)
    if ([IO.Path]::GetExtension($clientPath) -ine '.exe') { throw 'ClientExecutable must be a Windows packaged .exe file.' }
    $workingDirectory = Split-Path $clientPath -Parent
    $clientArguments = @()
    $requiredFiles = @($clientPath)
} else {
    $clientPath = Join-Path ([IO.Path]::GetFullPath($EngineRoot)) 'Engine/Binaries/Win64/UnrealEditor.exe'
    $project = Join-Path $repo 'WarhammerClient.uproject'
    $workingDirectory = $repo
    $clientArguments = @($project, '-game')
    $requiredFiles = @($clientPath, $project)
}
foreach ($path in $requiredFiles) { if (!(Test-Path -LiteralPath $path -PathType Leaf)) { throw ('Required client file is missing: ' + $path) } }
$hostArguments = @{ Mode = $CoreMode; Port = $Port; CoreVersion = $CoreVersion; CoreRoot = $CoreRoot; ReadinessSeconds = $ReadinessSeconds }
if ($Endpoint) { $hostArguments.Endpoint = $Endpoint }
$environmentNames = @('WH_CORE_ADMIN_TOKEN', 'WH_CORE_PLAYER_TOKEN', 'WH_CORE_PLAYER_B_TOKEN', 'WH_CORE_BASE_URL', 'WH_LIVE_CORE_TEST_URL')
$savedEnvironment = @{}
foreach ($name in $environmentNames) { $savedEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }
$hostInfo = $null; $client = $null
try {
    $hostInfo = & (Join-Path $PSScriptRoot 'Start-CoreDevelopmentServer.ps1') @hostArguments
    $arguments = $clientArguments + @('-windowed', ('-CoreUrl=' + $hostInfo.endpoint))
    $quoted = @($arguments | ForEach-Object { if ($_.Contains('"') -or $_.EndsWith('\')) { throw 'Unsupported quote/trailing separator in client argument.' }; '"' + $_ + '"' }) -join ' '
    Write-Host ('Opening client with ' + $CoreMode + ' Core at ' + $hostInfo.endpoint + '. Close the client window to finish.')
    # This is an explicitly interactive command, not a hidden build/test launch.
    $client = Start-Process -FilePath $clientPath -ArgumentList $quoted -WorkingDirectory $workingDirectory -WindowStyle Normal -PassThru
    $client.WaitForExit()
    if ($client.ExitCode -ne 0) { throw ('Unreal client exited with code ' + $client.ExitCode + '.') }
} finally {
    $cleanupFailure = $null
    try {
        if ($client) { $client.Dispose() }
    } catch { $cleanupFailure = $_ }
    try {
        if ($hostInfo -and $hostInfo.owned -eq $true) {
            & (Join-Path $PSScriptRoot 'Stop-CoreDevelopmentServer.ps1') -ReceiptPath $hostInfo.receiptPath | Out-Null
        }
    } catch { if ($null -eq $cleanupFailure) { $cleanupFailure = $_ } }
    foreach ($name in $environmentNames) {
        try { [Environment]::SetEnvironmentVariable($name, $savedEnvironment[$name], 'Process') }
        catch { if ($null -eq $cleanupFailure) { $cleanupFailure = $_ } }
    }
    if ($null -ne $cleanupFailure) { throw $cleanupFailure }
}
