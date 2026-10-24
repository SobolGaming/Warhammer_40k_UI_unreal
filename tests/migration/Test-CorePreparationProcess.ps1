#Requires -Version 7.0
# Executes only the preparation process wrapper against inert hidden Python tasks.
# Never invokes preparation, clone/install, Core, a service or graphical software.
[CmdletBinding()]
param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$PythonExecutable)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$run = Join-Path $repo ('.local/tests/core-preparation-process/' + [guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($run) | Out-Null
$utf8 = [Text.UTF8Encoding]::new($false, $true)
function Assert-True([bool]$Condition, [string]$Message) { if (!$Condition) { throw $Message } }
$tokens = $null; $errors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'scripts/Prepare-CoreDevelopmentRuntime.ps1'), [ref]$tokens, [ref]$errors)
Assert-True ($errors.Count -eq 0) 'Preparation source did not parse'
$functions = @($ast.FindAll({ param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq 'Invoke-PreparationTool' }, $false))
Assert-True ($functions.Count -eq 1) 'Expected one production process wrapper'
. ([scriptblock]::Create($functions[0].Extent.Text))
if (-not ('Warhammer.Tools.OwnedBuildProcess' -as [type])) { Add-Type -Path (Join-Path $repo 'scripts/OwnedBuildProcess.cs') }
$python = [IO.Path]::GetFullPath($PythonExecutable)
$normal = @(Invoke-PreparationTool $python @('-I', '-B', '-c', 'import sys; print("only-result"); print("private-stderr", file=sys.stderr)') 'normal' 10)
Assert-True ($normal.Count -eq 1 -and $normal[0] -is [string] -and $normal[0] -ceq 'only-result') 'Process wrapper polluted the returned stdout with asynchronous task results'
Assert-True ([IO.File]::ReadAllText((Join-Path $run 'normal.stderr.log'), $utf8).Trim() -ceq 'private-stderr') 'Process stderr was not retained separately'
$empty = @(Invoke-PreparationTool $python @('-I', '-B', '-c', 'pass') 'empty' 10)
Assert-True ($empty.Count -eq 1 -and $empty[0] -is [string] -and $empty[0] -ceq '') 'Empty stdout must remain one empty string for exact reference-status comparisons'
$failure = $null
try { $null = Invoke-PreparationTool $python @('-I', '-B', '-c', 'import sys; print("private-failure", file=sys.stderr); sys.exit(7)') 'failure' 10 } catch { $failure = $_ }
Assert-True ($null -ne $failure -and $failure.Exception.Message.Contains('Preparation failed at failure') -and !$failure.Exception.Message.Contains('private-failure')) 'Nonzero process failure was not surfaced with a sanitized stage diagnostic'
$timeout = $null
$clock = [Diagnostics.Stopwatch]::StartNew()
try { $null = Invoke-PreparationTool $python @('-I', '-B', '-c', 'import time; time.sleep(20)') 'timeout' 1 } catch { $timeout = $_ }
Assert-True ($null -ne $timeout -and $timeout.Exception.Message.Contains('bounded deadline') -and $clock.Elapsed.TotalSeconds -lt 10) 'Inert process deadline/owned cleanup was not bounded'
Assert-True ($timeout.Exception.Data['PreparationCleanup'].confirmed -and $timeout.Exception.Data['PreparationCleanup'].finalActiveProcesses -eq 0) 'Deadline failure did not confirm complete job cleanup'
$childScript = Join-Path $run 'outliving-child.py'
$parentScript = Join-Path $run 'exiting-parent.py'
$childIdentity = Join-Path $run 'outliving-child.pid'
$heartbeat = Join-Path $run 'outliving-child.heartbeat'
$childText = @'
import os, pathlib, sys, time
pathlib.Path(sys.argv[1]).write_text(str(os.getpid()))
for n in range(600):
    pathlib.Path(sys.argv[2]).write_text(str(n))
    print('owned-child-alive', flush=True)
    print('owned-child-stderr', file=sys.stderr, flush=True)
    time.sleep(0.05)
'@
$parentText = @'
import pathlib, subprocess, sys, time
# Explicit output/error inheritance is essential: a default Popen may not inherit
# redirected handles on Windows, which would fail to reproduce this ownership gap.
child = subprocess.Popen([sys.executable, '-I', '-B', *sys.argv[1:]],
                         stdout=sys.stdout, stderr=sys.stderr, close_fds=False,
                         creationflags=subprocess.CREATE_NO_WINDOW)
deadline = time.monotonic() + 3
while not pathlib.Path(sys.argv[2]).exists():
    if time.monotonic() > deadline:
        raise RuntimeError('Inert child did not become ready')
    time.sleep(0.01)
'@
[IO.File]::WriteAllText($childScript, $childText, $utf8)
[IO.File]::WriteAllText($parentScript, $parentText, $utf8)
$survivorFailure = $null
$survivorClock = [Diagnostics.Stopwatch]::StartNew()
try { $null = Invoke-PreparationTool $python @('-I', '-B', $parentScript, $childScript, $childIdentity, $heartbeat) 'outliving-child' 15 } catch { $survivorFailure = $_ }
Assert-True ($null -ne $survivorFailure -and $survivorFailure.Exception.Message.Contains('descendants survived the parent') -and $survivorClock.Elapsed.TotalSeconds -lt 13) 'An outliving child did not fail within the bounded descendant budget'
$survivorCleanup = $survivorFailure.Exception.Data['PreparationCleanup']
Assert-True ($survivorCleanup.parentExited -and $survivorCleanup.totalProcesses -ge 2 -and $survivorCleanup.confirmed -and $survivorCleanup.finalActiveProcesses -eq 0) 'Outliving-child failure did not confirm empty owned job after its parent exited'
$childPid = [int][IO.File]::ReadAllText($childIdentity)
$remainingChild = Get-Process -Id $childPid -ErrorAction SilentlyContinue
try { Assert-True ($null -eq $remainingChild -or $remainingChild.HasExited) 'The inert owned descendant remained alive after failure was returned' }
finally { if ($remainingChild) { $remainingChild.Dispose() } }
$heartbeatBefore = [IO.File]::ReadAllText($heartbeat)
Start-Sleep -Milliseconds 250
Assert-True ([IO.File]::ReadAllText($heartbeat) -ceq $heartbeatBefore) 'The descendant continued mutating preparation output after failure'
Assert-True ([IO.File]::ReadAllText((Join-Path $run 'outliving-child.stdout.log')).Contains('owned-child-alive') -and [IO.File]::ReadAllText((Join-Path $run 'outliving-child.stderr.log')).Contains('owned-child-stderr')) 'The descendant did not actually inherit both redirected streams'
$result = [pscustomobject]@{ status = 'PASS_INERT_NATIVE'; cases = 5; explicitPythonLaunches = 6; outlivingChild = @{ parentExited = $survivorCleanup.parentExited; jobTotalProcesses = $survivorCleanup.totalProcesses; cleanupConfirmed = $survivorCleanup.confirmed; finalActiveProcesses = $survivorCleanup.finalActiveProcesses; descendantAbsentAfterFailure = $true; outputMutationStopped = $true; inheritedBothStreams = $true }; guiLaunched = $false; coreProcessesLaunched = 0; runtimePrepared = $false; resultRoot = $run }
[IO.File]::WriteAllText((Join-Path $run 'result.json'), ($result | ConvertTo-Json -Depth 6) + "`n", $utf8)
$result
