#Requires -Version 7.0
# Offline exact-profile and destination controls. No clone, install or host launch.
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
. (Join-Path $repo 'scripts/CoreRuntimeProfile.ps1')
function Assert-True([bool]$Condition, [string]$Message) { if (!$Condition) { throw $Message } }
$current = Get-CoreRuntimeProfile
$previous = Get-CoreRuntimeProfile '44.3.33'
Assert-True ($current.version -ceq '44.5.0' -and $current.commit -ceq '4f9bef0df2fb974d1285232a1009b8781926361d' -and $current.resourceCount -eq 3130) 'Selected adoption profile changed without updating its contract controls'
Assert-True ($previous.commit -ceq '5f509724da25a2f6ded0c2739a8e7c84bdf59c91' -and $previous.resourceCount -eq 3116 -and $previous.legacyProvenance) 'Retained preview profile changed'
Assert-True ($current.runtimeRoot -ine $previous.runtimeRoot -and $current.sourceRoot -ine $previous.sourceRoot -and $current.build -cne $previous.build) 'Core profiles must not share source/runtime identity'
$tokens = $null; $errors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'scripts/Prepare-CoreDevelopmentRuntime.ps1'), [ref]$tokens, [ref]$errors)
Assert-True ($errors.Count -eq 0) 'Preparation script failed to parse'
foreach ($name in @('Assert-PlainPath', 'Assert-FreshPreparationDestination')) {
    $matches = @($ast.FindAll({ param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq $name }, $false))
    Assert-True ($matches.Count -eq 1) 'Missing production destination guard'
    . ([scriptblock]::Create($matches[0].Extent.Text))
}
$cases = 3
foreach ($destination in @($repo, (Join-Path $repo '../Warhammer_40k_AI'), (Join-Path $repo '.local/../Source'), (Join-Path $repo '.local'))) {
    $failure = $null
    try { Assert-FreshPreparationDestination $destination $repo } catch { $failure = $_ }
    Assert-True ($null -ne $failure) 'Preparation accepted an existing/outside destination'
    $cases++
}
$fresh = Join-Path $repo ('.local/tests/profile-fresh-' + [guid]::NewGuid().ToString('N'))
Assert-FreshPreparationDestination $fresh $repo
Assert-True (!(Test-Path -LiteralPath $fresh)) 'Validation created a destination'
$cases++
[pscustomobject]@{ status = 'PASS_OFFLINE'; cases = $cases; runtimePrepared = $false; nativeProcessesLaunched = 0; coreProcessesLaunched = 0; networkRequested = $false }
