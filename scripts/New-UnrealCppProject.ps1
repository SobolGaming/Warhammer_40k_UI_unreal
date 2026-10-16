#requires -Version 7.2
<#
.SYNOPSIS
Runs the approved BOOT01 Windows C++ bootstrap without launching a graphical app.
.DESCRIPTION
The default performs a same-name scratch compile and both IDE generators, then
promotes only collision-checked source and repeats build/generation at the final
path. -CheckOnly stops after scratch proof. Review that manifest, then reuse it
with -PromoteFrom to avoid repeating the probe. No installs or preference edits.
Normal per-user UBT/cache discovery remains; only creation of an absent empty
default UBT configuration is permitted. Existing configurations are hash-guarded.
.EXAMPLE
pwsh -NoProfile -File ./scripts/New-UnrealCppProject.ps1 -CheckOnly
.EXAMPLE
pwsh -NoProfile -File ./scripts/New-UnrealCppProject.ps1 -PromoteFrom ./.local/experiments/BOOT01/<run>
#>
[CmdletBinding()]
param(
    [string] $EngineRoot = 'C:\Program Files\Epic Games\UE_5.8',
    [switch] $CheckOnly,
    [string] $PromoteFrom
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$projectName = 'WarhammerClient'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$experimentRoot = Join-Path $projectRoot '.local\experiments\BOOT01'
$scriptPath = $PSCommandPath
$manifestPath = $null
$manifest = $null
$lock = $null
$guardBefore = $null
$processTimeoutMs = 30 * 60 * 1000
$utf8 = [Text.UTF8Encoding]::new($false)

function Get-Hash([string] $Path) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function Get-TextHash([string] $Text) {
    return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($utf8.GetBytes($Text)))
}

function Assert-NoReparsePoint([string] $Path) {
    $cursor = [IO.Path]::GetFullPath($Path)
    while ($cursor) {
        if (Test-Path -LiteralPath $cursor) {
            if (([IO.File]::GetAttributes($cursor) -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "Reparse-point path is outside this bootstrap's ownership model: $cursor"
            }
        }
        $parent = [IO.Directory]::GetParent($cursor)
        $cursor = if ($null -eq $parent) { $null } else { $parent.FullName }
    }
}

function Assert-ChildPath([string] $Path, [string] $Parent) {
    $resolved = [IO.Path]::GetFullPath($Path)
    $prefix = [IO.Path]::GetFullPath($Parent).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
    if (-not $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Path escapes the approved output parent: $resolved"
    }
    Assert-NoReparsePoint $resolved
    return $resolved
}

function Require-File([string] $Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Required file absent: $Path" }
}

function Assert-DestinationEmpty {
    foreach ($relative in @('WarhammerClient.uproject', 'Source', 'Config', 'Content', 'Plugins',
            'Binaries', 'Intermediate', 'Saved', 'DerivedDataCache', '.vscode', '.vs', '.ignore', '.vsconfig',
            'WarhammerClient.sln', 'WarhammerClient.slnx', 'WarhammerClient.code-workspace',
            'Automation_WarhammerClient.sln', 'Automation_WarhammerClient.slnx')) {
        $path = Join-Path $projectRoot $relative
        Assert-NoReparsePoint $path
        if (Test-Path -LiteralPath $path) {
            throw "Refusing an existing source/generated-output collision: $path. Preserve it; do not recreate source to regenerate IDE files."
        }
    }
}

function Get-ConfigGuard {
    $locations = @(
        (Join-Path ([Environment]::GetFolderPath('ApplicationData')) 'Unreal Engine\UnrealBuildTool\BuildConfiguration.xml'),
        (Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'Unreal Engine\UnrealBuildTool\BuildConfiguration.xml')
    )
    $documents = [Environment]::GetFolderPath('MyDocuments')
    if ($documents) { $locations += Join-Path $documents 'Unreal Engine\UnrealBuildTool\BuildConfiguration.xml' }
    return @($locations | Select-Object -Unique | ForEach-Object {
        [ordered]@{ Path = $_; Exists = (Test-Path -LiteralPath $_ -PathType Leaf)
            Hash = $(if (Test-Path -LiteralPath $_ -PathType Leaf) { Get-Hash $_ } else { $null }) }
    })
}

function Assert-ConfigGuard($Before) {
    $after = @(Get-ConfigGuard)
    for ($i = 0; $i -lt $Before.Count; $i++) {
        if ($Before[$i].Exists) {
            if (-not $after[$i].Exists -or $Before[$i].Hash -ne $after[$i].Hash) {
                throw "Existing global UBT configuration changed: $($Before[$i].Path)"
            }
        } elseif ($after[$i].Exists) {
            $allowed = Join-Path ([Environment]::GetFolderPath('ApplicationData')) 'Unreal Engine\UnrealBuildTool\BuildConfiguration.xml'
            if ($after[$i].Path -ne $allowed) { throw "Unexpected global UBT configuration created: $($after[$i].Path)" }
            [xml] $xml = [IO.File]::ReadAllText($after[$i].Path)
            if ($xml.DocumentElement.LocalName -ne 'Configuration' -or
                $xml.DocumentElement.NamespaceURI -ne 'https://www.unrealengine.com/BuildConfiguration' -or
                @($xml.DocumentElement.ChildNodes | Where-Object { $_.NodeType -eq 'Element' }).Count -ne 0) {
                throw "New default global UBT configuration is not empty: $($after[$i].Path)"
            }
        }
    }
    return $after
}

function Get-Readiness {
    if (-not $IsWindows -or -not [Environment]::Is64BitOperatingSystem -or
        [Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture -ne 'X64') {
        throw 'BOOT01 requires native x64 Windows and x64 PowerShell 7.2+.'
    }
    if ($CheckOnly -and $PromoteFrom) { throw '-CheckOnly and -PromoteFrom are mutually exclusive.' }
    Assert-NoReparsePoint $projectRoot
    Assert-NoReparsePoint $EngineRoot
    Assert-NoReparsePoint $experimentRoot
    foreach ($value in @($projectRoot, $EngineRoot)) {
        if ($value -match '["\r\n%!^&|<>]') { throw 'Bootstrap paths cannot contain quotes, newlines or cmd metacharacters in this bounded proof.' }
        if ($value.Length -gt 160) { throw 'Bootstrap root is too long for this bounded Windows proof (maximum 160 characters).' }
    }
    Require-File (Join-Path $projectRoot 'AGENTS.md')
    Require-File (Join-Path $projectRoot 'docs\plans\unreal-migration-plan.md')
    $versionPath = Join-Path $EngineRoot 'Engine\Build\Build.version'
    Require-File $versionPath
    $version = Get-Content -LiteralPath $versionPath -Raw | ConvertFrom-Json
    if ($version.MajorVersion -ne 5 -or $version.MinorVersion -ne 8 -or
        $version.PatchVersion -ne 3 -or $version.Changelist -ne 58210709) {
        throw 'This BOOT01 scaffold is reviewed for UE 5.8.3 / CL58210709 only.'
    }
    $required = @('Engine\Build\InstalledBuild.txt', 'Engine\Build\BatchFiles\Build.bat',
        'Engine\Build\BatchFiles\GetDotnetPath.bat', 'Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.dll',
        'Engine\Binaries\Win64\UnrealEditor.exe', 'Engine\Binaries\Win64\UnrealEditor-Cmd.exe',
        'Engine\Binaries\ThirdParty\DotNet\10.0\win-x64\dotnet.exe',
        'Templates\TP_Blank\Source\TP_Blank.Target.cs', 'Templates\TP_Blank\Source\TP_BlankEditor.Target.cs',
        'Engine\Config\Windows\Windows_SDK.json')
    foreach ($relative in $required) { Require-File (Join-Path $EngineRoot $relative) }
    foreach ($relative in @('Templates\TP_Blank\Source\TP_Blank.Target.cs', 'Templates\TP_Blank\Source\TP_BlankEditor.Target.cs')) {
        $target = Get-Content -LiteralPath (Join-Path $EngineRoot $relative) -Raw
        if ($target -notmatch 'BuildSettingsVersion\.V7' -or $target -notmatch 'EngineIncludeOrderVersion\.Unreal5_8') {
            throw "Installed template conventions changed: $relative"
        }
    }
    if (Test-Path -LiteralPath (Join-Path $EngineRoot 'Engine\Build\BatchFiles\BuildUBT.bat')) {
        throw 'Unexpected BuildUBT.bat: stop before a wrapper could rebuild the installed engine tool.'
    }
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    Require-File $vswhere
    $vsJson = & $vswhere -all -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -format json
    if ($LASTEXITCODE -ne 0) { throw 'Visual Studio metadata query failed.' }
    $instances = @($vsJson | ConvertFrom-Json)
    $compilers = @(foreach ($instance in $instances) {
        $toolRoot = Join-Path $instance.installationPath 'VC\Tools\MSVC'
        if (Test-Path -LiteralPath $toolRoot) {
            foreach ($family in Get-ChildItem -LiteralPath $toolRoot -Directory) {
                $compiler = Join-Path $family.FullName 'bin\Hostx64\x64\cl.exe'
                $linker = Join-Path $family.FullName 'bin\Hostx64\x64\link.exe'
                if ((Test-Path -LiteralPath $compiler) -and (Test-Path -LiteralPath $linker)) {
                    [pscustomobject]@{ Path = $compiler; Linker = $linker; Family = $family.Name
                        Version = (Get-Item -LiteralPath $compiler).VersionInfo.ProductVersion
                        VisualStudio = $instance.installationVersion }
                }
            }
        }
    })
    $compiler = $compilers | Where-Object { $_.Version -eq '14.44.35229.0' -and $_.Family -eq '14.44.35207' } | Select-Object -First 1
    if ($null -eq $compiler) { throw 'The source-inspected MSVC family 14.44.35207 / actual compiler 14.44.35229 is unavailable; no automatic upgrade.' }
    if ([version]$compiler.VisualStudio -lt [version]'17.14') { throw 'UE5.8 BOOT01 requires the inspected VS2022 17.14+ installation.' }
    $sdkRoot = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10'
    $sdks = @(foreach ($sdk in @('10.0.22621.0', '10.0.26100.0')) {
        $paths = @("Include\$sdk\um\Windows.h", "Include\$sdk\ucrt\stdio.h", "Lib\$sdk\um\x64\kernel32.lib",
            "Lib\$sdk\ucrt\x64\ucrt.lib", "bin\$sdk\x64\rc.exe")
        $missing = @($paths | Where-Object { -not (Test-Path -LiteralPath (Join-Path $sdkRoot $_) -PathType Leaf) })
        if ($missing.Count -eq 0) { $sdk }
    })
    if ($sdks.Count -eq 0) { throw 'Neither inspected Windows SDK has required headers, x64 libraries and resource compiler.' }
    $dotnetRoot = Join-Path $EngineRoot 'Engine\Binaries\ThirdParty\DotNet\10.0\win-x64'
    if (-not (Test-Path -LiteralPath (Join-Path $dotnetRoot 'sdk\10.0.203'))) { throw 'Inspected bundled .NET SDK 10.0.203 is absent.' }
    $code = Get-Command code -CommandType Application -ErrorAction Stop | Select-Object -First 1
    Require-File $code.Source
    $extensionRoot = Join-Path $env:USERPROFILE '.vscode\extensions'
    $extensions = @(Get-ChildItem -LiteralPath $extensionRoot -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
    if (@($extensions | Where-Object { $_ -match '^ms-vscode\.cpptools-\d' }).Count -eq 0) {
        throw 'VS Code C/C++ extension readiness is missing. No extension will be installed by BOOT01.'
    }
    if (@($extensions | Where-Object { $_ -match '^ms-dotnettools\.csharp-' }).Count -eq 0) {
        Write-Warning 'Optional VS Code C# extension not found; C++ compilation and IDE generation can proceed. C# editing/debug readiness remains unverified.'
    }
    $drive = [IO.DriveInfo]::new([IO.Path]::GetPathRoot($projectRoot))
    if ($drive.AvailableFreeSpace -lt 20GB) { throw 'BOOT01 requires at least 20 GiB free at the project output drive; this is a proof budget, not a packaging estimate.' }
    $fileIdentities = @(foreach ($relative in @('Engine\Build\Build.version', 'Engine\Config\Windows\Windows_SDK.json',
            'Engine\Build\BatchFiles\Build.bat', 'Engine\Build\BatchFiles\GetDotnetPath.bat',
            'Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.dll')) {
        [ordered]@{ RelativePath = $relative; Hash = Get-Hash (Join-Path $EngineRoot $relative) }
    })
    $identity = [ordered]@{ EngineRoot = $EngineRoot; EngineFiles = $fileIdentities
        CompilerPath = $compiler.Path; CompilerVersion = $compiler.Version; CompilerHash = Get-Hash $compiler.Path
        LinkerVersion = (Get-Item -LiteralPath $compiler.Linker).VersionInfo.ProductVersion
        VisualStudioVersion = $compiler.VisualStudio; AvailableSDKs = $sdks; DotNetSDK = '10.0.203'; CodeCLI = $code.Source }
    return [ordered]@{ Identity = $identity; Fingerprint = Get-TextHash ($identity | ConvertTo-Json -Depth 8 -Compress)
        AvailableFreeBytes = $drive.AvailableFreeSpace; Extensions = $extensions; DotNetRoot = $dotnetRoot
        OriginalUseSystemDotNet = $env:UE_USE_SYSTEM_DOTNET; OS = [Runtime.InteropServices.RuntimeInformation]::OSDescription }
}

function Get-Scaffold([string] $ProjectId) {
    if ($ProjectId -notmatch '^[A-F0-9]{32}$') { throw 'Invalid scaffold ProjectID.' }
    $files = [ordered]@{}
    $files['WarhammerClient.uproject'] = @'
{
    "FileVersion": 3,
    "EngineAssociation": "5.8",
    "Category": "Games",
    "Description": "Warhammer client BOOT01 C++ foundation; external core remains authoritative.",
    "Modules": [{ "Name": "WarhammerClient", "Type": "Runtime", "LoadingPhase": "Default" }]
}
'@
    foreach ($target in @(@{ Name = 'WarhammerClient'; Type = 'Game' }, @{ Name = 'WarhammerClientEditor'; Type = 'Editor' })) {
        $files["Source/$($target.Name).Target.cs"] = @"
using UnrealBuildTool;

public class $($target.Name)Target : TargetRules
{
    public $($target.Name)Target(TargetInfo Target) : base(Target)
    {
        Type = TargetType.$($target.Type);
        DefaultBuildSettings = BuildSettingsVersion.V7;
        IncludeOrderVersion = EngineIncludeOrderVersion.Unreal5_8;
        ExtraModuleNames.Add("WarhammerClient");
    }
}
"@
    }
    $files['Source/WarhammerClient/WarhammerClient.Build.cs'] = @'
using UnrealBuildTool;

public class WarhammerClient : ModuleRules
{
    public WarhammerClient(ReadOnlyTargetRules Target) : base(Target)
    {
        PCHUsage = PCHUsageMode.UseExplicitOrSharedPCHs;
        PublicDependencyModuleNames.AddRange(new[] { "Core", "CoreUObject", "Engine" });
    }
}
'@
    $files['Source/WarhammerClient/Private/WarhammerClient.cpp'] = @'
#include "Modules/ModuleManager.h"

IMPLEMENT_PRIMARY_GAME_MODULE(FDefaultGameModuleImpl, WarhammerClient, "WarhammerClient");
'@
    $files['Source/WarhammerClient/Public/WarhammerClientGameMode.h'] = @'
#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "WarhammerClientGameMode.generated.h"

/** Client shell only. The external Python core owns all game rules. */
UCLASS()
class WARHAMMERCLIENT_API AWarhammerClientGameMode : public AGameModeBase
{
    GENERATED_BODY()
};
'@
    $files['Source/WarhammerClient/Private/WarhammerClientGameMode.cpp'] = @'
#include "WarhammerClientGameMode.h"
'@
    $files['Config/DefaultEngine.ini'] = @'
[/Script/EngineSettings.GameMapsSettings]
GlobalDefaultGameMode=/Script/WarhammerClient.WarhammerClientGameMode

[/Script/WindowsTargetPlatform.WindowsTargetSettings]
DefaultGraphicsRHI=DefaultGraphicsRHI_DX12

[/Script/LinuxTargetPlatform.LinuxTargetSettings]
+TargetedRHIs=SF_VULKAN_SM6
'@
    $files['Config/DefaultGame.ini'] = @"
[/Script/EngineSettings.GeneralProjectSettings]
ProjectID=$ProjectId
ProjectName=WarhammerClient
ProjectVersion=0.0.1
"@
    $files['Config/DefaultEditorSettings.ini'] = @'
[/Script/SourceCodeAccess.SourceCodeAccessSettings]
PreferredAccessor=VisualStudioCode
'@
    foreach ($key in @($files.Keys)) { $files[$key] = $files[$key].Replace("`r`n", "`n").TrimEnd() + "`n" }
    return $files
}

function Write-Manifest { [IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 15), $utf8) }

function Get-ScaffoldManifest($Files, [string] $Root) {
    foreach ($directory in @('Source', 'Config')) {
        foreach ($item in Get-ChildItem -LiteralPath (Join-Path $Root $directory) -Recurse -File) {
            $relative = [IO.Path]::GetRelativePath($Root, $item.FullName).Replace('\', '/')
            if (-not $Files.Contains($relative)) { throw "Unexpected authored probe/source input: $($item.FullName)" }
        }
    }
    if (Test-Path -LiteralPath (Join-Path $Root 'Plugins')) { throw 'BOOT01 cannot consume an unexpected project plugin.' }
    if (@(Get-ChildItem -LiteralPath (Join-Path $Root 'Content') -Recurse -File).Count -ne 0) { throw 'BOOT01 Content must contain no assets.' }
    return @(foreach ($relative in $Files.Keys) {
        $path = Assert-ChildPath (Join-Path $Root $relative) $Root
        Require-File $path
        $hash = Get-Hash $path
        if ($hash -ne (Get-TextHash $Files[$relative])) { throw "Scaffold input changed: $path" }
        [ordered]@{ RelativePath = $relative; Hash = $hash; Bytes = (Get-Item -LiteralPath $path).Length }
    })
}

function Invoke-BuildStep([string] $Root, [ValidateSet('Build', 'Generate')] [string] $Action, [string] $Label) {
    $logRoot = Join-Path $experiment 'logs'
    [void][IO.Directory]::CreateDirectory($logRoot)
    $ubtLog = Join-Path $logRoot "$Label.ubt.log"
    $stdout = Join-Path $logRoot "$Label.stdout.log"
    $stderr = Join-Path $logRoot "$Label.stderr.log"
    $start = [Diagnostics.ProcessStartInfo]::new()
    $start.FileName = (Get-Process -Id $PID).Path
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.WorkingDirectory = $Root
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    foreach ($argument in @('-NoProfile', '-NonInteractive', '-File', $runner, '-EngineRoot', $EngineRoot,
            '-ProjectFile', (Join-Path $Root 'WarhammerClient.uproject'), '-Action', $Action, '-UbtLog', $ubtLog)) {
        $start.ArgumentList.Add($argument)
    }
    $start.Environment['UE_USE_SYSTEM_DOTNET'] = '0'
    $start.Environment['UE_DOTNET_VERSION'] = ''
    $start.Environment['UE_DOTNET_DIR'] = ''
    $start.Environment['DOTNET_HOST_PATH'] = Join-Path $readiness.DotNetRoot 'dotnet.exe'
    $start.Environment['DOTNET_CLI_HOME'] = Join-Path $experiment 'dotnet-home'
    $start.Environment['DOTNET_SKIP_FIRST_TIME_EXPERIENCE'] = '1'
    $start.Environment['DOTNET_CLI_TELEMETRY_OPTOUT'] = '1'
    $start.Environment['NUGET_PACKAGES'] = Join-Path $experiment 'nuget-packages'
    $start.Environment['NUGET_HTTP_CACHE_PATH'] = Join-Path $experiment 'nuget-http-cache'
    $start.Environment['UBA_ROOT'] = Join-Path $experiment 'uba'
    $start.Environment['TEMP'] = Join-Path $experiment 'temp'
    $start.Environment['TMP'] = $start.Environment['TEMP']
    foreach ($key in @('DOTNET_CLI_HOME', 'NUGET_PACKAGES', 'NUGET_HTTP_CACHE_PATH', 'UBA_ROOT', 'TEMP')) { [void][IO.Directory]::CreateDirectory($start.Environment[$key]) }
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $start
    $outStream = [IO.File]::Open($stdout, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::Read)
    $errStream = [IO.File]::Open($stderr, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::Read)
    $started = $false
    try {
        Write-Host "$Label started; live UBT log: $ubtLog"
        if (-not $process.Start()) { throw "Could not start owned process for $Label" }
        $started = $true
        $copies = [Threading.Tasks.Task[]]@($process.StandardOutput.BaseStream.CopyToAsync($outStream), $process.StandardError.BaseStream.CopyToAsync($errStream))
        $watch = [Diagnostics.Stopwatch]::StartNew()
        $lastProgress = 0
        $timedOut = $false
        while (-not $process.WaitForExit(1000)) {
            if ($watch.ElapsedMilliseconds -ge $processTimeoutMs) {
                $process.Kill($true)
                [void]$process.WaitForExit(10000)
                $timedOut = $true
                break
            }
            if ($watch.Elapsed.TotalSeconds - $lastProgress -ge 30) {
                Write-Host ("{0}: running {1:N0}s; inspect {2}" -f $Label, $watch.Elapsed.TotalSeconds, $ubtLog)
                $lastProgress = $watch.Elapsed.TotalSeconds
            }
        }
        if (-not [Threading.Tasks.Task]::WaitAll($copies, 10000)) { throw "Timed out draining $Label output; UBT log is retained." }
        if ($timedOut) { throw "$Label exceeded 30 minutes; stopped only owned process tree PID $($process.Id). Logs retained at $logRoot" }
        $exitCode = $process.ExitCode
        if ($exitCode -ne 0) { throw "$Label failed with exit $exitCode. Inspect $stdout, $stderr and $ubtLog" }
        Require-File $ubtLog
        $toolchainLines = @(Get-Content -LiteralPath $ubtLog | Where-Object { $_ -match 'Using Visual Studio|Using.*toolchain|Windows.*SDK|Using bundled DotNet' })
        $result = [ordered]@{ Label = $Label; Action = $Action; ExitCode = $exitCode
            UbtLog = $ubtLog; Stdout = $stdout; Stderr = $stderr; ToolchainLogLines = $toolchainLines }
        $manifest.Steps += $result
        Write-Manifest
        return $result
    } finally {
        if ($started -and -not $process.HasExited) { $process.Kill($true); [void]$process.WaitForExit(10000) }
        $outStream.Dispose()
        $errStream.Dispose()
        $process.Dispose()
    }
}

function Assert-GeneratedOutputs([string] $Root) {
    $dll = Join-Path $Root 'Binaries\Win64\UnrealEditor-WarhammerClient.dll'
    $workspace = Join-Path $Root 'WarhammerClient.code-workspace'
    $solution = Join-Path $Root 'WarhammerClient.sln'
    $properties = Join-Path $Root '.vscode\c_cpp_properties.json'
    foreach ($path in @($dll, $workspace, $solution, $properties)) { Require-File $path }
    $generatedHeaders = @(Get-ChildItem -LiteralPath (Join-Path $Root 'Intermediate') -Filter 'WarhammerClientGameMode.generated.h' -Recurse -File)
    if ($generatedHeaders.Count -eq 0) { throw "UHT generated header absent under $Root" }
    $workspaceData = Get-Content -LiteralPath $workspace -Raw | ConvertFrom-Json
    if (@($workspaceData.tasks.tasks).Count -eq 0 -or @($workspaceData.launch.configurations).Count -eq 0) {
        throw "Generated workspace lacks build/debug configurations: $workspace"
    }
    $intellisense = Get-Content -LiteralPath $properties -Raw | ConvertFrom-Json
    if (@($intellisense.configurations).Count -eq 0) { throw "Generated IntelliSense configuration absent: $properties" }
    $vcProjects = @(Get-ChildItem -LiteralPath (Join-Path $Root 'Intermediate') -Filter '*.vcxproj' -Recurse -File)
    if ($vcProjects.Count -eq 0) { throw "Visual Studio project output absent under $Root" }
    return [ordered]@{ Root = $Root; RuntimeModuleDll = $dll; UhtHeaders = $generatedHeaders.Count
        Workspace = $workspace; BuildTasks = @($workspaceData.tasks.tasks).Count
        DebugConfigurations = @($workspaceData.launch.configurations).Count
        IntelliSenseConfigurations = @($intellisense.configurations).Count; Solution = $solution; VisualStudioProjects = $vcProjects.Count
        FileHashes = @(@($dll, $workspace, $solution, $properties) | ForEach-Object { [ordered]@{ Path = $_; Hash = Get-Hash $_ } }) }
}

try {
    $EngineRoot = [IO.Path]::GetFullPath($EngineRoot)
    $readiness = Get-Readiness
    Assert-DestinationEmpty
    $scriptHash = Get-Hash $scriptPath
    $guardBefore = @(Get-ConfigGuard)
    $sourceManifest = $null
    if ($PromoteFrom) {
        $sourceExperiment = Assert-ChildPath $PromoteFrom $experimentRoot
        if ([IO.Directory]::GetParent($sourceExperiment).FullName -ne [IO.Path]::GetFullPath($experimentRoot) -or
            [IO.Path]::GetFileName($sourceExperiment) -notmatch '^\d{8}T\d{6}Z-[a-f0-9]{8}$') {
            throw '-PromoteFrom must identify a direct packet-owned BOOT01 run directory.'
        }
        $previousManifest = Join-Path $sourceExperiment 'manifest.json'
        Require-File $previousManifest
        $sourceManifest = Get-Content -LiteralPath $previousManifest -Raw | ConvertFrom-Json
        if ($sourceManifest.SchemaVersion -ne 1 -or $sourceManifest.Packet -ne 'BOOT01' -or
            $sourceManifest.ProjectName -ne $projectName -or $sourceManifest.Mode -ne 'CheckOnly' -or
            $sourceManifest.Status -ne 'Passed' -or $sourceManifest.ScriptHash -ne $scriptHash -or
            $sourceManifest.Readiness.Fingerprint -ne $readiness.Fingerprint) {
            throw 'Probe is not a successful CheckOnly run of this script with the same engine/toolchain identity.'
        }
        $projectId = $sourceManifest.ProjectId
        $files = Get-Scaffold $projectId
        $probe = Join-Path $sourceExperiment 'probe\WarhammerClient'
        $actual = @(Get-ScaffoldManifest $files $probe)
        if (@($sourceManifest.SourceFiles).Count -ne $files.Count) { throw 'Probe source manifest count differs from the exact whitelist.' }
        foreach ($entry in $sourceManifest.SourceFiles) {
            if (-not $files.Contains($entry.RelativePath) -or
                @($actual | Where-Object { $_.RelativePath -eq $entry.RelativePath -and $_.Hash -eq $entry.Hash }).Count -ne 1) {
                throw 'Probe source manifest has an unknown, duplicate, traversing or changed path.'
            }
        }
        if (@($sourceManifest.SourceFiles.RelativePath | Select-Object -Unique).Count -ne $files.Count) { throw 'Probe source whitelist contains duplicates.' }
        [void](Assert-GeneratedOutputs $probe)
    } else {
        $projectId = [Guid]::NewGuid().ToString('N').ToUpperInvariant()
        $files = Get-Scaffold $projectId
    }
    $rootWriteProbe = Join-Path $projectRoot ('.BOOT01-write-' + [Guid]::NewGuid().ToString('N') + '.tmp')
    try {
        $writeStream = [IO.File]::Open($rootWriteProbe, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        $writeStream.Dispose()
    } finally {
        if (Test-Path -LiteralPath $rootWriteProbe -PathType Leaf) { [IO.File]::Delete($rootWriteProbe) }
    }
    [void][IO.Directory]::CreateDirectory($experimentRoot)
    Assert-NoReparsePoint $experimentRoot
    $lock = [IO.File]::Open((Join-Path $experimentRoot 'bootstrap.lock'), [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    $runName = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ') + '-' + [Guid]::NewGuid().ToString('N').Substring(0, 8)
    $experiment = Assert-ChildPath (Join-Path $experimentRoot $runName) $experimentRoot
    if (Test-Path -LiteralPath $experiment) { throw "Unique experiment path already exists: $experiment" }
    [void][IO.Directory]::CreateDirectory($experiment)
    $writeProbe = Join-Path $experiment 'write-check.tmp'
    [IO.File]::WriteAllText($writeProbe, 'BOOT01 writable output', $utf8)
    [IO.File]::Delete($writeProbe)
    $manifestPath = Join-Path $experiment 'manifest.json'
    $manifest = [ordered]@{ SchemaVersion = 1; Packet = 'BOOT01'; ProjectName = $projectName; ProjectId = $projectId
        Mode = $(if ($CheckOnly) { 'CheckOnly' } elseif ($PromoteFrom) { 'PromoteFrom' } else { 'Bootstrap' })
        Status = 'Running'; ScriptHash = $scriptHash; StartedUtc = [DateTime]::UtcNow.ToString('o')
        Readiness = $readiness; GlobalConfigBefore = $guardBefore; Steps = @(); SourceFiles = @(); Outputs = @()
        SourceExperiment = $(if ($PromoteFrom) { $sourceExperiment } else { $null })
        SideEffects = @('Experiment-local TEMP/TMP, DOTNET_CLI_HOME, NuGet package/HTTP caches and UBA_ROOT; subprocess bundled .NET forced',
            'Root writability checked with a unique temporary file that is removed before source writes',
            'Normal per-user Unreal/compiler caches may be read/created; they are not globally redirected',
            'Only absent default empty Roaming UBT configuration may be created; existing global XML is hash-guarded')
        Linux = 'UNTESTED; unrestricted Game/Editor targets and Linux RHI configuration only'
        PreferredAccessor = 'Project DefaultEditorSettings requests VisualStudioCode; existing saved settings may override; active accessor/debugger NOT RUN'
        BuildPolicy = 'Development Editor with UE5.8 UBA local executor; -NoUBA disables detours, UBA_ROOT scopes local storage to this experiment; no persistent build settings changed' }
    Write-Manifest
    $runner = Join-Path $experiment 'Invoke-OwnedUnrealBuild.ps1'
    $runnerText = @'
param([string] $EngineRoot, [string] $ProjectFile, [ValidateSet('Build', 'Generate')] [string] $Action, [string] $UbtLog)
$ErrorActionPreference = 'Stop'
$buildArguments = if ($Action -eq 'Build') {
    @('WarhammerClientEditor', 'Win64', 'Development', "-Project=$ProjectFile", '-WaitMutex', '-NoUBA', "-Log=$UbtLog")
} else {
    @('-ProjectFiles', "-Project=$ProjectFile", '-Game', '-VSCode', '-2022', '-Automated', "-Log=$UbtLog")
}
& (Join-Path $EngineRoot 'Engine\Build\BatchFiles\Build.bat') @buildArguments
if ($null -eq $LASTEXITCODE) { throw 'Build.bat supplied no exit status.' }
exit $LASTEXITCODE
'@
    [IO.File]::WriteAllText($runner, $runnerText, $utf8)
    if (-not $PromoteFrom) {
        $probe = Join-Path $experiment 'probe\WarhammerClient'
        if (Test-Path -LiteralPath $probe) { throw "Refusing existing probe input: $probe" }
        [void][IO.Directory]::CreateDirectory((Join-Path $probe 'Content'))
        foreach ($relative in $files.Keys) {
            $path = Assert-ChildPath (Join-Path $probe $relative) $probe
            [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($path))
            [IO.File]::WriteAllText($path, $files[$relative], $utf8)
        }
        $manifest.SourceFiles = @(Get-ScaffoldManifest $files $probe)
        Write-Manifest
        [void](Invoke-BuildStep $probe Build 'probe-editor-build')
        [void](Invoke-BuildStep $probe Generate 'probe-ide-generation')
        $manifest.Outputs += Assert-GeneratedOutputs $probe
    } else {
        $manifest.SourceFiles = @(Get-ScaffoldManifest $files $probe)
        $manifest.Outputs += Assert-GeneratedOutputs $probe
    }
    $manifest.GlobalConfigAfterProbe = @(Assert-ConfigGuard $guardBefore)
    if ((Get-Readiness).Fingerprint -ne $readiness.Fingerprint) { throw 'Inspected engine/toolchain identity changed during proof.' }
    if (-not $CheckOnly) {
        Assert-DestinationEmpty
        [void](Get-ScaffoldManifest $files $probe)
        foreach ($relative in $files.Keys) {
            $destination = Assert-ChildPath (Join-Path $projectRoot $relative) $projectRoot
            if (Test-Path -LiteralPath $destination) { throw "Promotion collision: $destination" }
        }
        # File.Copy(overwrite=false) also rejects a collision that races the full preflight.
        foreach ($relative in $files.Keys) {
            $destination = Join-Path $projectRoot $relative
            [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination))
            [IO.File]::Copy((Join-Path $probe $relative), $destination, $false)
        }
        [void][IO.Directory]::CreateDirectory((Join-Path $projectRoot 'Content'))
        $manifest.PromotedSourceFiles = @(Get-ScaffoldManifest $files $projectRoot)
        Write-Manifest
        [void](Invoke-BuildStep $projectRoot Build 'final-editor-build')
        [void](Invoke-BuildStep $projectRoot Generate 'final-ide-generation')
        $manifest.Outputs += Assert-GeneratedOutputs $projectRoot
        $manifest.PromotedSourceFiles = @(Get-ScaffoldManifest $files $projectRoot)
    }
    $manifest.GlobalConfigAfter = @(Assert-ConfigGuard $guardBefore)
    if ((Get-Readiness).Fingerprint -ne $readiness.Fingerprint) { throw 'Inspected engine/toolchain identity changed during final proof.' }
    $manifest.Status = 'Passed'
    $manifest.CompletedUtc = [DateTime]::UtcNow.ToString('o')
    Write-Manifest
    Write-Host "BOOT01 $($manifest.Mode) passed. Manifest: $manifestPath"
    if ($CheckOnly) { Write-Host 'Repository source was not promoted. Review this manifest before -PromoteFrom.' }
    Write-Host 'No graphical app launched. Linux, rendering, packaging, runtime-core integration and debugger activation remain UNTESTED.'
} catch {
    if ($null -ne $manifest) {
        $manifest.Status = 'Failed'
        $manifest.Error = $_.Exception.Message
        $manifest.CompletedUtc = [DateTime]::UtcNow.ToString('o')
        if ($null -ne $guardBefore) { $manifest.GlobalConfigAfterFailure = @(Get-ConfigGuard) }
        Write-Manifest
        Write-Host "BOOT01 stopped; evidence retained: $manifestPath"
    }
    throw
} finally {
    if ($null -ne $lock) { $lock.Dispose() }
}
