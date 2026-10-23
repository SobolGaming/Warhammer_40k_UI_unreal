#Requires -Version 7.0
# Interactive user entry point. Do not invoke during an owner screen HOLD.
[CmdletBinding()]
param(
    [ValidateSet('Managed', 'Attach')][string]$CoreMode = 'Managed',
    [ValidateRange(1024, 65535)][int]$Port = 8765,
    [uri]$Endpoint,
    [string]$EngineRoot = 'C:/Program Files/Epic Games/UE_5.8',
    [string]$CoreRoot = (Join-Path $PSScriptRoot '../../Warhammer_40k_AI'),
    [ValidateRange(5, 120)][int]$ReadinessSeconds = 60
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (!$IsWindows) { throw 'This interactive launcher currently targets the installed Windows Unreal Editor. Linux is untested.' }
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$editor = Join-Path ([IO.Path]::GetFullPath($EngineRoot)) 'Engine/Binaries/Win64/UnrealEditor.exe'
$project = Join-Path $repo 'WarhammerClient.uproject'
foreach ($path in @($editor, $project)) { if (!(Test-Path -LiteralPath $path -PathType Leaf)) { throw ('Required client file is missing: ' + $path) } }
$hostArguments = @{ Mode = $CoreMode; Port = $Port; CoreRoot = $CoreRoot; ReadinessSeconds = $ReadinessSeconds }
if ($Endpoint) { $hostArguments.Endpoint = $Endpoint }
$hostInfo = $null; $client = $null
try {
    $hostInfo = & (Join-Path $PSScriptRoot 'Start-CoreDevelopmentServer.ps1') @hostArguments
    $arguments = @($project, '-game', '-windowed', ('-CoreUrl=' + $hostInfo.endpoint))
    $quoted = @($arguments | ForEach-Object { if ($_.Contains('"') -or $_.EndsWith('\')) { throw 'Unsupported quote/trailing separator in client argument.' }; '"' + $_ + '"' }) -join ' '
    Write-Host ('Opening client with ' + $CoreMode + ' Core at ' + $hostInfo.endpoint + '. Close the client window to finish.')
    # This is an explicitly interactive command, not a hidden build/test launch.
    $client = Start-Process -FilePath $editor -ArgumentList $quoted -WorkingDirectory $repo -WindowStyle Normal -PassThru
    $client.WaitForExit()
    if ($client.ExitCode -ne 0) { throw ('Unreal client exited with code ' + $client.ExitCode + '.') }
} finally {
    if ($client) { $client.Dispose() }
    if ($hostInfo -and $hostInfo.owned -eq $true) {
        & (Join-Path $PSScriptRoot 'Stop-CoreDevelopmentServer.ps1') -ReceiptPath $hostInfo.receiptPath | Out-Null
    }
}
