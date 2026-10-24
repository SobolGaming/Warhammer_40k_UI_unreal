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
[pscustomobject]@{ status = 'PASS_INERT_NATIVE'; cases = 4; nativeProcessesLaunched = 4; guiLaunched = $false; coreProcessesLaunched = 0; runtimePrepared = $false; resultRoot = $run }
