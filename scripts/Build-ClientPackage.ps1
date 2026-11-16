#Requires -Version 7.0
# Builds/cooks only. Never runs the packaged game or a prerequisite installer.
[CmdletBinding()]
param(
    [string]$EngineRoot = 'C:/Program Files/Epic Games/UE_5.8',
    [ValidateRange(5, 120)][int]$TimeoutMinutes = 60
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (!$IsWindows) { throw 'This package recipe targets native Windows x64. Linux remains untested.' }
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$engine = [IO.Path]::GetFullPath($EngineRoot)
$dotnetRoot = Join-Path $engine 'Engine/Binaries/ThirdParty/DotNet/10.0/win-x64'
$dotnet = Join-Path $dotnetRoot 'dotnet.exe'
$uat = Join-Path $engine 'Engine/Binaries/DotNET/AutomationTool/AutomationTool.dll'
$editorCmd = Join-Path $engine 'Engine/Binaries/Win64/UnrealEditor-Cmd.exe'
$project = Join-Path $repo 'WarhammerClient.uproject'
foreach ($path in @($dotnet, $uat, $editorCmd, $project)) {
    if (!(Test-Path -LiteralPath $path -PathType Leaf)) { throw ('Required UE 5.8 packaging file is missing: ' + $path) }
}
$run = Join-Path $repo ('.local/packages/' + [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ') + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
if (Test-Path -LiteralPath $run) { throw 'Package output already exists; preserve previous results.' }
[IO.Directory]::CreateDirectory($run) | Out-Null
$archive = Join-Path $run 'archive'
$stage = Join-Path $run 'stage'
$cooker = '-NullRHI -RenderOffScreen -NoSplash -nosound -NoLiveCoding -SkipZenStore'
$arguments = @($uat, '-NoCompile', '-NoP4', '-UTF8Output', 'BuildCookRun',
    ('-project=' + $project), '-target=WarhammerClient', '-platform=Win64', '-clientconfig=Development',
    '-build', '-cook', '-stage', '-pak', '-package', '-archive', '-prereqs', '-unattended',
    '-map=/Engine/Maps/Entry', ('-unrealexe=' + $editorCmd),
    ('-stagingdirectory=' + $stage), ('-archivedirectory=' + $archive),
    '-UbtArgs=-NoUBA -MaxParallelActions=1', ('-AdditionalCookerOptions=' + $cooker))
$info = [Diagnostics.ProcessStartInfo]::new($dotnet)
$info.WorkingDirectory = Split-Path $uat
$info.UseShellExecute = $false; $info.CreateNoWindow = $true
$info.WindowStyle = [Diagnostics.ProcessWindowStyle]::Hidden
$info.RedirectStandardOutput = $true; $info.RedirectStandardError = $true
foreach ($argument in $arguments) { $info.ArgumentList.Add($argument) }
# Match the installed GetDotnetPath/RunUAT bundled runtime selection without a
# command shell or SDK installation. Environment changes apply only to this child.
$info.Environment['PATH'] = $dotnetRoot + [IO.Path]::PathSeparator + $info.Environment['PATH']
$info.Environment['DOTNET_ROOT'] = $dotnetRoot
$info.Environment['DOTNET_MULTILEVEL_LOOKUP'] = '0'
$info.Environment['DOTNET_ROLL_FORWARD'] = 'LatestMajor'
$info.Environment['UE_DOTNET_VERSION'] = '10.0'
$info.Environment['UE_DOTNET_DIR'] = $dotnetRoot
foreach ($name in @('VisualStudioDir', 'VSSKUEDITION', 'PkgDefApplicationConfigFile', 'VSAPPIDDIR', 'VisualStudioEdition', 'VisualStudioVersion',
    'GH_TOKEN', 'GITHUB_TOKEN', 'WH_CORE_ADMIN_TOKEN', 'WH_CORE_PLAYER_TOKEN', 'WH_CORE_PLAYER_B_TOKEN', 'WH_CORE_BASE_URL', 'WH_LIVE_CORE_TEST_URL')) {
    $null = $info.Environment.Remove($name)
}
$record = [ordered]@{ kind = 'WINDOWS_DEVELOPMENT_CLIENT_PACKAGE'; startedUtc = [DateTime]::UtcNow.ToString('o');
    sourceHead = (git -C $repo rev-parse HEAD).Trim(); status = 'STARTED'; timeoutMinutes = $TimeoutMinutes;
    outputRoot = $run; archive = $archive; stage = $stage; executable = $dotnet; arguments = $arguments;
    nonVisibleCook = $true; gameLaunched = $false; prerequisiteInstallerExecuted = $false; cleanupErrors = @() }
$helper = Join-Path $PSScriptRoot 'OwnedBuildProcess.cs'
if (-not ('Warhammer.Tools.OwnedBuildProcess' -as [type])) { Add-Type -Path $helper }
$process = $null
$stdoutPath = Join-Path $run 'uat-stdout.log'
$stderrPath = Join-Path $run 'uat-stderr.log'
$record.processOwnership = 'Windows job; suspended creation, assignment before resume, kill on job close'
$record.ownedBuildTreeTerminated = $false
$record.ownedJobEmpty = $false
try {
    $process = [Warhammer.Tools.OwnedBuildProcess]::Start($info, $stdoutPath, $stderrPath, 10000)
    $timer = [Diagnostics.Stopwatch]::StartNew()
    while (!$process.WaitForExit(500)) {
        if ($timer.Elapsed.TotalMinutes -gt $TimeoutMinutes) { throw 'Package build exceeded its time budget.' }
        if ([IO.FileInfo]::new($stdoutPath).Length -gt 64MB -or [IO.FileInfo]::new($stderrPath).Length -gt 64MB) { throw 'Package output exceeded its 64 MiB per-stream budget.' }
    }
    $record.elapsedSeconds = $timer.Elapsed.TotalSeconds; $record.exitCode = $process.ExitCode
    # Parent exit is not descendant exit. The job remains owned until every child
    # exits; cleanup below also handles a failed UAT parent with surviving cookers.
    if (!$process.WaitJobEmpty(10000)) { throw 'Owned build descendants survived the parent beyond ten seconds.' }
    $record.ownedJobEmpty = $true
    if ($timer.Elapsed.TotalMinutes -gt $TimeoutMinutes -or [IO.FileInfo]::new($stdoutPath).Length -gt 64MB -or [IO.FileInfo]::new($stderrPath).Length -gt 64MB) { throw 'Package exceeded its time or output budget.' }
    if ($process.ExitCode -ne 0) { throw ('AutomationTool failed with exit code ' + $process.ExitCode + '; inspect the retained logs.') }
    $binary = Join-Path $archive 'Windows/WarhammerClient/Binaries/Win64/WarhammerClient.exe'
    $bootstrap = Join-Path $archive 'Windows/WarhammerClient.exe'
    foreach ($path in @($binary, $bootstrap)) {
        if (!(Test-Path -LiteralPath $path -PathType Leaf)) { throw 'UAT exited zero but the expected Windows runnable folder is incomplete.' }
    }
    $record.status = 'PACKAGE_CREATED_RUNTIME_UNVERIFIED'
    $record.clientExecutable = $binary; $record.bootstrapExecutable = $bootstrap
} catch {
    $record.status = 'FAILED'; $record.error = $_.Exception.Message
} finally {
    try {
        if ($null -ne $process) {
            # Dispose always supervises the retained job, even after UAT exited.
            # Native logs remain open until bounded job cleanup finishes.
            try {
                $record.ownedBuildTreeTerminated = $process.ActiveProcessCount -gt 0
                $record.ownedJobTotalProcesses = $process.TotalProcessCount
            } finally {
                try { $process.Dispose() } finally {
                    $record.ownedJobEmpty = $process.CleanupConfirmed
                }
            }
            if (!$record.ownedJobEmpty) { throw 'Owned job cleanup could not be confirmed.' }
        }
    } catch { $record.cleanupErrors += $_.Exception.GetType().Name; $record.status = 'CLEANUP_FAILED' }
    $record.finishedUtc = [DateTime]::UtcNow.ToString('o')
    $record | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $run 'package-result.json') -Encoding utf8
}
if ($record.status -ne 'PACKAGE_CREATED_RUNTIME_UNVERIFIED') { throw ('Package failed; retained evidence: ' + $run) }
[pscustomobject]$record
