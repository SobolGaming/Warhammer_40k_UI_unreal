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
$retained = Get-CoreRuntimeProfile '44.5.0'
$previous = Get-CoreRuntimeProfile '44.3.33'
Assert-True ($current.version -ceq '46.0.0' -and $current.commit -ceq 'fc52e9166ff6380b606269ce362f4f1cbc6a2835' -and $current.resourceCount -eq 3256 -and
    $current.build -ceq 'warhammer40k-core-v2:runtime-tree-sha256-v1:ae914a56833e43a3bbf086730b354c7a18673ccc15ca93e4b474347b95380f19') 'Selected adoption profile changed without updating its contract controls'
Assert-True ($retained.commit -ceq '4f9bef0df2fb974d1285232a1009b8781926361d' -and $retained.resourceCount -eq 3130 -and
    $retained.build -ceq 'warhammer40k-core-v2:runtime-tree-sha256-v1:0443ce4bc405aad1737ec9a396948775010df933bd75144f6ab9ff54152118ba' -and !$retained.legacyProvenance) 'Retained handoff profile changed'
Assert-True ($previous.commit -ceq '5f509724da25a2f6ded0c2739a8e7c84bdf59c91' -and $previous.resourceCount -eq 3116 -and $previous.legacyProvenance) 'Retained preview profile changed'
$profiles = @($current, $retained, $previous)
foreach ($property in @('sourceRoot', 'runtimeRoot', 'build', 'commit')) {
    Assert-True (@($profiles | ForEach-Object { $_.$property } | Sort-Object -Unique).Count -eq 3) ('Core profiles must not share ' + $property)
}
foreach ($profile in @($current, $retained)) {
    Assert-True ($profile.sourceRoot -ieq (Join-Path $repo ('.local/core-source-' + $profile.version)) -and
        $profile.runtimeRoot -ieq (Join-Path $repo ('.local/core-' + $profile.version)) -and
        $profile.provenanceLeaf -ceq '.development-provenance.json' -and !$profile.legacyProvenance) 'Newer profiles must use separate local source/runtime/provenance'
}
$cases = 6
# Read fresh production parameter declarations, never run their top-level launch logic.
foreach ($leaf in @('Start-Client.ps1', 'Start-CoreDevelopmentServer.ps1', 'Prepare-CoreDevelopmentRuntime.ps1', 'Test-ClientPackage.ps1')) {
    $parameterTokens = $null; $parameterErrors = $null
    $parameterAst = [Management.Automation.Language.Parser]::ParseFile((Join-Path $repo ('scripts/' + $leaf)), [ref]$parameterTokens, [ref]$parameterErrors)
    Assert-True ($parameterErrors.Count -eq 0) ('Profile consumer failed to parse: ' + $leaf)
    $parameters = @($parameterAst.ParamBlock.Parameters | Where-Object { $_.Name.VariablePath.UserPath -ceq 'CoreVersion' })
    Assert-True ($parameters.Count -eq 1 -and $parameters[0].DefaultValue.SafeGetValue() -ceq '46.0.0') ('Profile consumer must explicitly default to46: ' + $leaf)
    $validation = @($parameters[0].Attributes | Where-Object { $_.TypeName.Name -ceq 'ValidateSet' })
    $allowed = @($validation.PositionalArguments | ForEach-Object { $_.SafeGetValue() })
    $expectedVersions = if ($leaf -ceq 'Prepare-CoreDevelopmentRuntime.ps1') { @('46.0.0', '44.5.0') } else { @('46.0.0', '44.5.0', '44.3.33') }
    Assert-True ($validation.Count -eq 1 -and ($allowed -join ',') -ceq ($expectedVersions -join ',')) ('Profile consumer dropped an applicable retained profile: ' + $leaf)
    if ($leaf -in @('Prepare-CoreDevelopmentRuntime.ps1', 'Start-CoreDevelopmentServer.ps1')) {
        $bindings = @($parameterAst.FindAll({ param($node) $node -is [Management.Automation.Language.AssignmentStatementAst] -and $node.Left.Extent.Text -ceq '$runtimeProfile' }, $true))
        Assert-True ($bindings.Count -eq 1 -and $bindings[0].Right.Extent.Text -ceq 'Get-CoreRuntimeProfile $CoreVersion') ('Profile consumer must bind the requested profile: ' + $leaf)
    }
    $cases++
}
$tokens = $null; $errors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'scripts/Prepare-CoreDevelopmentRuntime.ps1'), [ref]$tokens, [ref]$errors)
Assert-True ($errors.Count -eq 0) 'Preparation script failed to parse'
foreach ($name in @('Assert-PlainPath', 'Assert-FreshPreparationDestination')) {
    $matches = @($ast.FindAll({ param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq $name }, $false))
    Assert-True ($matches.Count -eq 1) 'Missing production destination guard'
    . ([scriptblock]::Create($matches[0].Extent.Text))
}
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
