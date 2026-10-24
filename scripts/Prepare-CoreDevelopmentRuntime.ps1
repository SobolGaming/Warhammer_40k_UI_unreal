#Requires -Version 7.0
# One-time native Windows preparation. Never installs into the reference checkout.
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$PythonExecutable,
    [string]$ReferenceCoreRoot = (Join-Path $PSScriptRoot '../../Warhammer_40k_AI')
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (!$IsWindows) { throw 'This preparation command requires native Windows; use the documented Linux Attach route (UNTESTED).' }
. (Join-Path $PSScriptRoot 'CoreRuntimeProfile.ps1')
$runtimeProfile = Get-CoreRuntimeProfile '44.5.0'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$reference = [IO.Path]::GetFullPath($ReferenceCoreRoot)
$python = [IO.Path]::GetFullPath($PythonExecutable)
$uv = (Get-Command uv -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
$git = (Get-Command git -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
$utf8 = [Text.UTF8Encoding]::new($false, $true)

function Assert-PlainPath([string]$Path) {
    $cursor = [IO.Path]::GetFullPath($Path)
    while ($cursor) {
        if ((Test-Path -LiteralPath $cursor) -and ((Get-Item -LiteralPath $cursor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Reparse points are not supported for preparation paths.' }
        $parent = [IO.Directory]::GetParent($cursor)
        $cursor = if ($parent) { $parent.FullName } else { $null }
    }
}
foreach ($path in @($reference, $python, $runtimeProfile.sourceRoot, $runtimeProfile.runtimeRoot)) { Assert-PlainPath $path }
function Assert-FreshPreparationDestination([string]$Destination, [string]$Repository) {
    $resolvedDestination = [IO.Path]::GetFullPath($Destination)
    $localRoot = [IO.Path]::GetFullPath((Join-Path $Repository '.local')).TrimEnd('\', '/')
    if (!$resolvedDestination.StartsWith($localRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Preparation destination must be inside this repository .local directory.' }
    Assert-PlainPath $resolvedDestination
    if (Test-Path -LiteralPath $resolvedDestination) { throw 'Preparation requires fresh source and runtime directories. Inspect existing output; this command never replaces or deletes it.' }
}
foreach ($destination in @($runtimeProfile.sourceRoot, $runtimeProfile.runtimeRoot)) { Assert-FreshPreparationDestination $destination $repo }
function Set-CoreCheckoutBytePolicy([string]$SourceRoot) {
    # The disposable clone must materialize literal committed bytes. Some Core
    # JSON blobs contain CRLF despite *.json text eol=lf in its tracked attributes.
    # A clone-local override avoids rewriting source or falsely dirtying checkout.
    Assert-PlainPath $SourceRoot
    $privateGit = Join-Path $SourceRoot '.git'
    if (![IO.Directory]::Exists($privateGit)) { throw 'Exact-byte preparation requires its own ordinary Git clone.' }
    [IO.Directory]::CreateDirectory((Join-Path $privateGit 'info')) | Out-Null
    [IO.File]::WriteAllText((Join-Path $privateGit 'info/attributes'), "* -text -filter -ident -working-tree-encoding`n", $utf8)
}
$run = Join-Path $repo ('.local/development/core-prepare/' + [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ') + '-' + [guid]::NewGuid().ToString('N'))
Assert-PlainPath $run
[IO.Directory]::CreateDirectory($run) | Out-Null
function Invoke-PreparationTool([string]$Executable, [string[]]$Arguments, [string]$Stage, [int]$Seconds = 900) {
    if (-not ('Warhammer.Tools.OwnedBuildProcess' -as [type])) { Add-Type -Path (Join-Path $repo 'scripts/OwnedBuildProcess.cs') }
    $info = [Diagnostics.ProcessStartInfo]::new()
    $info.FileName = $Executable; $info.WorkingDirectory = $run
    $info.UseShellExecute = $false; $info.CreateNoWindow = $true
    $info.RedirectStandardOutput = $true; $info.RedirectStandardError = $true
    foreach ($argument in $Arguments) { $info.ArgumentList.Add($argument) }
    $stdoutPath = Join-Path $run ($Stage + '.stdout.log')
    $stderrPath = Join-Path $run ($Stage + '.stderr.log')
    $process = $null; $failure = $null; $cleanupFailure = $null
    $cleanup = [ordered]@{ ownership = 'Windows job assigned before resume; kill on job close'; parentExited = $false; totalProcesses = $null; confirmed = $false; finalActiveProcesses = $null }
    try {
        $process = [Warhammer.Tools.OwnedBuildProcess]::Start($info, $stdoutPath, $stderrPath, 5000)
        $clock = [Diagnostics.Stopwatch]::StartNew()
        while (!$process.WaitForExit(100)) {
            if ($clock.Elapsed.TotalSeconds -gt $Seconds) { throw ('Preparation stage exceeded its bounded deadline: ' + $Stage) }
            if ([IO.FileInfo]::new($stdoutPath).Length -gt 64MB -or [IO.FileInfo]::new($stderrPath).Length -gt 64MB) { throw ('Preparation output exceeded its 64 MiB per-stream budget: ' + $Stage) }
        }
        # Parent exit does not release the job or establish descendant exit.
        # Keep ownership through a bounded drain, even if a child retains output.
        $drain = [Diagnostics.Stopwatch]::StartNew()
        while (!$process.WaitJobEmpty(100)) {
            if ($drain.Elapsed.TotalSeconds -gt 5) { throw ('Preparation descendants survived the parent beyond five seconds: ' + $Stage) }
            if ($clock.Elapsed.TotalSeconds -gt $Seconds) { throw ('Preparation stage exceeded its bounded deadline: ' + $Stage) }
            if ([IO.FileInfo]::new($stdoutPath).Length -gt 64MB -or [IO.FileInfo]::new($stderrPath).Length -gt 64MB) { throw ('Preparation output exceeded its 64 MiB per-stream budget: ' + $Stage) }
        }
        if ($clock.Elapsed.TotalSeconds -gt $Seconds) { throw ('Preparation stage exceeded its bounded deadline: ' + $Stage) }
        if ([IO.FileInfo]::new($stdoutPath).Length -gt 64MB -or [IO.FileInfo]::new($stderrPath).Length -gt 64MB) { throw ('Preparation output exceeded its 64 MiB per-stream budget: ' + $Stage) }
        if ($process.ExitCode -ne 0) { throw ('Preparation failed at ' + $Stage + '; inspect private output under ' + $run) }
    } catch { $failure = $_
    } finally {
        if ($null -ne $process) {
            try { $cleanup.parentExited = $process.HasExited; $cleanup.totalProcesses = $process.TotalProcessCount }
            catch { $cleanupFailure = $_ }
            try { $process.Dispose() } catch { if (!$cleanupFailure) { $cleanupFailure = $_ } }
            $cleanup.confirmed = $process.CleanupConfirmed
            $cleanup.finalActiveProcesses = $process.FinalActiveProcessCount
            if (!$cleanup.confirmed -and !$cleanupFailure) { $cleanupFailure = [Management.Automation.ErrorRecord]::new([InvalidOperationException]::new('Preparation job cleanup could not be confirmed.'), 'PreparationCleanup', [Management.Automation.ErrorCategory]::CloseError, $null) }
        }
        if ($failure) {
            $failure.Exception.Data['PreparationCleanup'] = [pscustomobject]$cleanup
            if ($cleanupFailure) { $failure.Exception.Data['PreparationCleanupFailure'] = $cleanupFailure.Exception.GetType().FullName }
        }
    }
    if ($failure) { throw $failure }
    if ($cleanupFailure) { throw $cleanupFailure }
    return [IO.File]::ReadAllText($stdoutPath, $utf8).Trim()
}
$gitOptions = @('--no-optional-locks', '-c', 'core.fsmonitor=false', '-c', 'core.untrackedCache=false', '-c', 'core.hooksPath=NUL', '-C', $reference)
$beforeHead = Invoke-PreparationTool $git ($gitOptions + @('rev-parse', 'HEAD')) 'reference-head' 30
$beforeStatus = Invoke-PreparationTool $git ($gitOptions + @('status', '--porcelain=v1', '--untracked-files=normal')) 'reference-status' 30
$record = [ordered]@{ schemaVersion = 1; status = 'PREPARATION_FAILED'; coreCommit = $runtimeProfile.commit; contractVersion = $runtimeProfile.version; runtimeBuildId = $runtimeProfile.build; runtimeResourceCount = $runtimeProfile.resourceCount; sourceRoot = $runtimeProfile.sourceRoot; runtimeRoot = $runtimeProfile.runtimeRoot; startedUtc = [DateTime]::UtcNow.ToString('o'); referenceUnchanged = $false }
try {
    $version = Invoke-PreparationTool $python @('-I', '-B', '-c', 'import sys; assert sys.version_info[:2] == (3,14); print(sys.executable)') 'python-version' 30
    if (![IO.Path]::GetFullPath($version).Equals($python, [StringComparison]::OrdinalIgnoreCase)) { throw 'Selected interpreter path differs.' }
    $null = Invoke-PreparationTool $git ($gitOptions + @('cat-file', '-e', ($runtimeProfile.commit + '^{commit}'))) 'selected-source' 30
    $null = Invoke-PreparationTool $git @('-c', 'core.hooksPath=NUL', 'clone', '--config', 'core.autocrlf=false', '--config', 'core.hooksPath=NUL', '--no-hardlinks', '--no-checkout', '--', $reference, $runtimeProfile.sourceRoot) 'clone' 180
    Set-CoreCheckoutBytePolicy $runtimeProfile.sourceRoot
    $sourceGit = @('--no-optional-locks', '-c', 'core.autocrlf=false', '-c', 'core.hooksPath=NUL', '-C', $runtimeProfile.sourceRoot)
    $null = Invoke-PreparationTool $git ($sourceGit + @('checkout', '--detach', $runtimeProfile.commit)) 'checkout' 180
    $initialChanges = Invoke-PreparationTool $git ($sourceGit + @('status', '--porcelain=v1', '--untracked-files=normal')) 'source-initial-clean' 30
    if ($initialChanges) { throw 'Prepared source is dirty immediately after checkout; dependency installation was not started.' }
    $null = Invoke-PreparationTool $uv @('venv', '--python', $python, $runtimeProfile.runtimeRoot) 'venv' 120
    $installedPython = Join-Path $runtimeProfile.runtimeRoot 'Scripts/python.exe'
    $requirements = Join-Path $run 'requirements.txt'
    $null = Invoke-PreparationTool $uv @('export', '--frozen', '--no-dev', '--no-emit-project', '--project', $runtimeProfile.sourceRoot, '--output-file', $requirements) 'locked-dependencies' 120
    $null = Invoke-PreparationTool $uv @('pip', 'sync', '--python', $installedPython, '--require-hashes', $requirements) 'install-dependencies' 900
    $null = Invoke-PreparationTool $uv @('pip', 'install', '--python', $installedPython, '--no-deps', $runtimeProfile.sourceRoot) 'install-core' 900
    $verify = @'
import json, pathlib, sys
assert sys.version_info[:2] == (3,14)
import warhammer40k_core
assert pathlib.Path(warhammer40k_core.__file__).resolve().is_relative_to(pathlib.Path(sys.prefix).resolve())
from warhammer40k_core.build_identity import verified_engine_build_identity
i = verified_engine_build_identity()
assert i.build_id == sys.argv[1] and i.resource_count == int(sys.argv[2])
print(json.dumps({'buildId': i.build_id, 'resourceCount': i.resource_count, 'baseExecutable': sys._base_executable}))
'@
    $identity = (Invoke-PreparationTool $installedPython @('-I', '-B', '-c', $verify, $runtimeProfile.build, [string]$runtimeProfile.resourceCount) 'verify-installed' 120) | ConvertFrom-Json
    $sourceChanges = Invoke-PreparationTool $git ($sourceGit + @('status', '--porcelain=v1', '--untracked-files=normal')) 'source-clean' 30
    if ($sourceChanges) { throw 'Prepared source changed during package installation.' }
    $record['pythonSha256'] = (Get-FileHash -LiteralPath $installedPython -Algorithm SHA256).Hash
    $record['basePythonSha256'] = (Get-FileHash -LiteralPath $identity.baseExecutable -Algorithm SHA256).Hash
    $record['basePython'] = $identity.baseExecutable
    $record['lockSha256'] = (Get-FileHash -LiteralPath (Join-Path $runtimeProfile.sourceRoot 'uv.lock') -Algorithm SHA256).Hash
    $record['sourceCheckoutPolicy'] = 'RAW_GIT_BLOBS'
    $record['sourceCheckoutAttributesSha256'] = (Get-FileHash -LiteralPath (Join-Path $runtimeProfile.sourceRoot '.git/info/attributes') -Algorithm SHA256).Hash
    $record['requirementsSha256'] = (Get-FileHash -LiteralPath $requirements -Algorithm SHA256).Hash
    $record['preparationRun'] = $run
    $record.status = 'INSTALLED_RUNTIME_PASS'
} finally {
    $afterHead = Invoke-PreparationTool $git ($gitOptions + @('rev-parse', 'HEAD')) 'reference-after-head' 30
    $afterStatus = Invoke-PreparationTool $git ($gitOptions + @('status', '--porcelain=v1', '--untracked-files=normal')) 'reference-after-status' 30
    $record.referenceUnchanged = ($beforeHead -ceq $afterHead -and $beforeStatus -ceq $afterStatus)
    $record['finishedUtc'] = [DateTime]::UtcNow.ToString('o')
    if (!$record.referenceUnchanged) { $record.status = 'PREPARATION_FAILED_REFERENCE_CHANGED' }
    $json = ($record | ConvertTo-Json -Depth 8) + "`n"
    [IO.File]::WriteAllText((Join-Path $run 'result.json'), $json, $utf8)
    if ($record.status -ceq 'INSTALLED_RUNTIME_PASS') { [IO.File]::WriteAllText((Join-Path $runtimeProfile.runtimeRoot $runtimeProfile.provenanceLeaf), $json, $utf8) }
}
if (!$record.referenceUnchanged) { throw 'Reference checkout changed during preparation; inspect private result. No valid runtime provenance was written.' }
[pscustomobject]@{ status = $record.status; coreCommit = $runtimeProfile.commit; contractVersion = $runtimeProfile.version; runtimeRoot = $runtimeProfile.runtimeRoot; sourceRoot = $runtimeProfile.sourceRoot; resultPath = (Join-Path $run 'result.json') }
