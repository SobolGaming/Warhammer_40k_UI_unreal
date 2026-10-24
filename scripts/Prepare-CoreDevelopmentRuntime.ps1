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
$run = Join-Path $repo ('.local/development/core-prepare/' + [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ') + '-' + [guid]::NewGuid().ToString('N'))
Assert-PlainPath $run
[IO.Directory]::CreateDirectory($run) | Out-Null
function Invoke-PreparationTool([string]$Executable, [string[]]$Arguments, [string]$Stage, [int]$Seconds = 900) {
    $info = [Diagnostics.ProcessStartInfo]::new()
    $info.FileName = $Executable; $info.WorkingDirectory = $run
    $info.UseShellExecute = $false; $info.CreateNoWindow = $true
    $info.RedirectStandardOutput = $true; $info.RedirectStandardError = $true
    foreach ($argument in $Arguments) { $info.ArgumentList.Add($argument) }
    $process = [Diagnostics.Process]::new(); $process.StartInfo = $info
    $output = [IO.File]::Create((Join-Path $run ($Stage + '.stdout.log')))
    $errors = [IO.File]::Create((Join-Path $run ($Stage + '.stderr.log')))
    $started = $false
    try {
        if (!$process.Start()) { throw ('Could not start preparation stage ' + $Stage) }
        $started = $true
        $stdout = $process.StandardOutput.BaseStream.CopyToAsync($output)
        $stderr = $process.StandardError.BaseStream.CopyToAsync($errors)
        if (!$process.WaitForExit($Seconds * 1000)) {
            $process.Kill($true); $null = $process.WaitForExit(5000)
            throw ('Preparation stage exceeded its bounded deadline: ' + $Stage)
        }
        if (![Threading.Tasks.Task]::WaitAll([Threading.Tasks.Task[]]@($stdout, $stderr), 5000)) { throw ('Preparation streams exceeded the five-second drain limit: ' + $Stage) }
        $null = $stdout.GetAwaiter().GetResult(); $null = $stderr.GetAwaiter().GetResult()
        if ($process.ExitCode -ne 0) { throw ('Preparation failed at ' + $Stage + '; inspect private output under ' + $run) }
        $output.Dispose(); $errors.Dispose()
        return [IO.File]::ReadAllText((Join-Path $run ($Stage + '.stdout.log')), $utf8).Trim()
    } finally {
        if ($started -and !$process.HasExited) { $process.Kill($true); $null = $process.WaitForExit(5000) }
        $process.Dispose(); $output.Dispose(); $errors.Dispose()
    }
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
    $sourceGit = @('--no-optional-locks', '-c', 'core.autocrlf=false', '-c', 'core.hooksPath=NUL', '-C', $runtimeProfile.sourceRoot)
    $null = Invoke-PreparationTool $git ($sourceGit + @('checkout', '--detach', $runtimeProfile.commit)) 'checkout' 180
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
