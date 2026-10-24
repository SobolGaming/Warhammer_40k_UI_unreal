#Requires -Version 7.0
# A real miniature Git fixture: CRLF JSON blob with conflicting tracked eol=lf.
# Never touches either sibling checkout or prepares/installs a Core runtime.
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$run = Join-Path $repo ('.local/tests/core-checkout-bytes/' + [guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($run) | Out-Null
$utf8 = [Text.UTF8Encoding]::new($false, $true)
function Assert-True([bool]$Condition, [string]$Message) { if (!$Condition) { throw $Message } }
$tokens = $null; $errors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'scripts/Prepare-CoreDevelopmentRuntime.ps1'), [ref]$tokens, [ref]$errors)
Assert-True ($errors.Count -eq 0) 'Preparation source failed to parse'
foreach ($name in @('Assert-PlainPath', 'Set-CoreCheckoutBytePolicy', 'Invoke-PreparationTool')) {
    $functions = @($ast.FindAll({ param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq $name }, $false))
    Assert-True ($functions.Count -eq 1) 'Missing production preparation function'
    . ([scriptblock]::Create($functions[0].Extent.Text))
}
$git = (Get-Command git -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
$fixture = Join-Path $run 'source fixture'
$clone = Join-Path $run 'prepared clone'
$null = Invoke-PreparationTool $git @('-c', 'core.hooksPath=NUL', 'init', $fixture) 'init' 30
[IO.File]::WriteAllText((Join-Path $fixture '.gitattributes'), "*.json text eol=lf`n", $utf8)
$json = "{`r`n  `"value`": 1`r`n}`r`n"
[IO.File]::WriteAllText((Join-Path $fixture 'example.json'), $json, $utf8)
$options = @('-c', 'core.hooksPath=NUL', '-C', $fixture)
$blob = Invoke-PreparationTool $git ($options + @('hash-object', '-w', '--no-filters', 'example.json')) 'blob' 30
$null = Invoke-PreparationTool $git ($options + @('add', '.gitattributes')) 'attributes' 30
$null = Invoke-PreparationTool $git ($options + @('update-index', '--add', '--cacheinfo', ('100644,' + $blob + ',example.json'))) 'index' 30
$null = Invoke-PreparationTool $git ($options + @('-c', 'user.name=Local Test', '-c', 'user.email=local-test@example.invalid', '-c', 'commit.gpgsign=false', 'commit', '-m', 'CRLF source fixture')) 'commit' 30
$null = Invoke-PreparationTool $git @('clone', '--config', 'core.autocrlf=false', '--config', 'core.hooksPath=NUL', '--no-hardlinks', '--no-checkout', '--', $fixture, $clone) 'clone' 30
Set-CoreCheckoutBytePolicy $clone
$null = Invoke-PreparationTool $git @('-C', $clone, 'checkout', '--detach', 'HEAD') 'checkout' 30
$actual = [IO.File]::ReadAllBytes((Join-Path $clone 'example.json'))
$expected = $utf8.GetBytes($json)
Assert-True ([Linq.Enumerable]::SequenceEqual[byte]($actual, $expected)) 'Checkout changed the exact committed CRLF bytes'
$status = Invoke-PreparationTool $git @('-C', $clone, 'status', '--porcelain=v1', '--untracked-files=normal') 'clean-status' 30
Assert-True ($status -ceq '') 'Raw-byte checkout was falsely reported dirty by text normalization'
# The override must preserve ordinary change detection rather than hiding edits.
[IO.File]::WriteAllText((Join-Path $clone 'example.json'), $json.Replace('1', '2'), $utf8)
$changed = Invoke-PreparationTool $git @('-C', $clone, 'status', '--porcelain=v1', '--untracked-files=normal') 'changed-status' 30
Assert-True ($changed -cmatch '^M? ?M? example\.json$') 'Raw-byte policy hid a real source edit'
[pscustomobject]@{ status = 'PASS_MINIATURE_GIT'; cases = 3; sourceBytesPreserved = $true; initialCloneClean = $true; detectsRealEdits = $true; runtimePrepared = $false; resultRoot = $run }
