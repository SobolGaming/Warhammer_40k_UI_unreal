#Requires -Version 7.0
# Focused real Win64 job regressions. Python uses only stdlib; no Core, UE or GUI.
[CmdletBinding()]
param([Parameter(Mandatory)][string]$Python)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (!$IsWindows -or [IntPtr]::Size -ne 8) { throw 'These owned-job tests require native Windows x64.' }
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$Python = [IO.Path]::GetFullPath($Python)
if (!(Test-Path -LiteralPath $Python -PathType Leaf)) { throw 'Supply an existing native Python executable.' }
$root = Join-Path $repo ('.local/tests/owned-build-process/' + [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ') + '-' + [guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($root)
Add-Type -Path (Join-Path $repo 'scripts/OwnedBuildProcess.cs')
function Assert-True([bool]$Value, [string]$Message) { if (!$Value) { throw $Message } }
function New-Info([string]$Code, [string[]]$Arguments = @()) {
    $info = [Diagnostics.ProcessStartInfo]::new($Python)
    $info.WorkingDirectory = $root; $info.UseShellExecute = $false
    foreach ($argument in @('-I', '-B', '-c', $Code) + $Arguments) { $info.ArgumentList.Add($argument) }
    foreach ($name in @('GH_TOKEN','GITHUB_TOKEN','WH_CORE_ADMIN_TOKEN','WH_CORE_PLAYER_TOKEN','WH_CORE_BASE_URL','WH_LIVE_CORE_TEST_URL')) { $null = $info.Environment.Remove($name) }
    return $info
}
$cases = [Collections.Generic.List[object]]::new()
$all = [Diagnostics.Stopwatch]::StartNew()
$owner = $null
try {
    # This checks actual argv decoding, Unicode environment and direct output handles.
    $code = @'
import os, sys
assert sys.argv[1:] == ['', 'two words', 'a"b', 'tail\\', 'slash\\"quote', 'snowman-\u2603']
assert os.environ['OWNED_BUILD_TEST_VALUE'] == 'unicode-\u2603'
print('argument-environment-ok', flush=True)
print('stderr-ok', file=sys.stderr, flush=True)
'@
    $info = New-Info $code @('', 'two words', 'a"b', 'tail\', 'slash\"quote', 'snowman-☃')
    $info.Environment['OWNED_BUILD_TEST_VALUE'] = 'unicode-☃'
    $stdout = Join-Path $root 'arguments.stdout.log'; $stderr = Join-Path $root 'arguments.stderr.log'
    $owner = [Warhammer.Tools.OwnedBuildProcess]::Start($info, $stdout, $stderr)
    Assert-True ($owner.WaitForExit(10000)) 'Argument/environment child did not exit.'
    Assert-True ($owner.ExitCode -eq 0) 'Argument/environment child failed.'
    Assert-True ($owner.WaitJobEmpty(5000)) 'Argument/environment job did not become empty.'
    $owner.Dispose()
    Assert-True $owner.CleanupConfirmed 'Argument/environment cleanup was not confirmed.'
    Assert-True ([IO.File]::ReadAllText($stdout).Trim() -ceq 'argument-environment-ok') 'Stdout bytes did not reach the owned file.'
    Assert-True ([IO.File]::ReadAllText($stderr).Trim() -ceq 'stderr-ok') 'Stderr bytes did not reach the owned file.'
    $cases.Add([ordered]@{ name='ActualArgumentEnvironmentAndOutput'; status='PASS' }); $owner = $null

    # Parent deliberately leaves a live child after exiting. Parent PID-based cleanup
    # would miss it; the retained kernel job must still report/terminate that child.
    $ready = Join-Path $root 'child.ready'
    $code = @'
import subprocess, sys, time
from pathlib import Path
child = "from pathlib import Path; import sys,time; Path(sys.argv[1]).write_text('ready',encoding='ascii'); print('owned-child-ready',flush=True); time.sleep(60)"
subprocess.Popen([sys.executable, '-I', '-B', '-c', child, sys.argv[1]], stdout=sys.stdout, stderr=sys.stderr, creationflags=subprocess.CREATE_NO_WINDOW)
deadline = time.monotonic() + 5
while not Path(sys.argv[1]).exists() and time.monotonic() < deadline:
    time.sleep(.01)
assert Path(sys.argv[1]).read_text(encoding='ascii') == 'ready'
print('owned-parent-exiting', flush=True)
'@
    $stdout = Join-Path $root 'descendant.stdout.log'; $stderr = Join-Path $root 'descendant.stderr.log'
    $owner = [Warhammer.Tools.OwnedBuildProcess]::Start((New-Info $code @($ready)), $stdout, $stderr)
    Assert-True ($owner.WaitForExit(10000)) 'Deliberately exiting parent did not exit.'
    Assert-True ($owner.HasExited -and $owner.ExitCode -eq 0) 'Parent exit was not observed through its retained handle.'
    Assert-True (Test-Path -LiteralPath $ready -PathType Leaf) 'Real child did not produce its readiness marker.'
    $active = $owner.ActiveProcessCount; $total = $owner.TotalProcessCount
    Assert-True ($active -gt 0 -and $total -ge 2) 'Job did not retain a live descendant after parent exit.'
    $cleanup = [Diagnostics.Stopwatch]::StartNew(); $owner.Dispose(); $cleanup.Stop()
    Assert-True ($owner.CleanupConfirmed -and $owner.FinalActiveProcessCount -eq 0) 'Dispose did not confirm an empty owned job.'
    Assert-True ($cleanup.Elapsed.TotalSeconds -lt 11) 'Job cleanup exceeded its finite budget.'
    $text = [IO.File]::ReadAllText($stdout)
    Assert-True ($text.Contains('owned-child-ready') -and $text.Contains('owned-parent-exiting')) 'Parent and child did not use the inherited owned output.'
    $cases.Add([ordered]@{ name='ParentExitedDescendantStillOwned'; status='PASS'; observedActiveAfterParentExit=$active; observedTotal=$total; finalActive=$owner.FinalActiveProcessCount; cleanupSeconds=$cleanup.Elapsed.TotalSeconds }); $owner = $null

    # CreateProcess fails only after the job/output handles have been allocated.
    # Exclusive reopen demonstrates those owned file handles were released.
    $bad = New-Info 'raise AssertionError("must not run")'
    $bad.FileName = Join-Path $root 'does-not-exist.exe'
    $stdout = Join-Path $root 'failed.stdout.log'; $stderr = Join-Path $root 'failed.stderr.log'; $failed = $false
    try { $owner = [Warhammer.Tools.OwnedBuildProcess]::Start($bad, $stdout, $stderr) }
    catch { $failed = $true }
    Assert-True $failed 'Nonexistent native executable unexpectedly started.'
    foreach ($path in @($stdout, $stderr)) {
        $stream = [IO.File]::Open($path, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
        try { Assert-True ($stream.Length -eq 0) 'Failed start wrote unexpected process output.' } finally { $stream.Dispose() }
    }
    $cases.Add([ordered]@{ name='FailedStartReleasesOwnedOutputs'; status='PASS' })
    [ordered]@{ kind='OWNED_BUILD_PROCESS_FOCUSED_REGRESSIONS'; status='PASS'; cases=@($cases.ToArray()); elapsedSeconds=$all.Elapsed.TotalSeconds; sourceSha256=(Get-FileHash -LiteralPath (Join-Path $repo 'scripts/OwnedBuildProcess.cs')).Hash; limits='Owned hidden CLI processes only; no Core, Unreal, GUI, network or descendant identity attribution.' } |
        ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $root 'result.json') -Encoding utf8
    Get-Content -LiteralPath (Join-Path $root 'result.json') -Raw
} finally {
    if ($owner) { $owner.Dispose() }
}
