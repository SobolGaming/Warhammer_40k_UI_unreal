#Requires -Version 7.0
# Offline credential-resolution controls. Only a named production function AST
# executes against synthetic literals; no Core, network or native process starts.
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$names = @('WH_CORE_ADMIN_TOKEN', 'WH_CORE_PLAYER_TOKEN', 'WH_CORE_PLAYER_B_TOKEN')
$saved = @{}
foreach ($name in $names) { $saved[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }
$cases = 0

function Assert-True([bool]$Condition, [string]$Message) { if (!$Condition) { throw $Message } }
function Set-SyntheticEnvironment([hashtable]$Values) {
    foreach ($name in $names) { [Environment]::SetEnvironmentVariable($name, $Values[$name], 'Process') }
}
function Test-ExpectedFailure([string]$Registry, [hashtable]$Values, [string]$ExpectedMessage) {
    Set-SyntheticEnvironment $Values
    $before = @{}
    foreach ($name in $names) { $before[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }
    $failure = $null
    try { $output = @(Initialize-DevelopmentCredentials $Registry); Assert-True ($output.Count -eq 0) 'Credential resolver emitted output' }
    catch { $failure = $_ }
    Assert-True ($null -ne $failure -and $failure.Exception.Message.Contains($ExpectedMessage)) 'Expected credential failure was not returned'
    foreach ($name in $names) {
        Assert-True ([string]::Equals([Environment]::GetEnvironmentVariable($name, 'Process'), $before[$name], [StringComparison]::Ordinal)) 'Failed credential validation partially changed the caller environment'
        $value = $before[$name]
        if (![string]::IsNullOrEmpty($value)) { Assert-True (!$failure.Exception.Message.Contains($value)) 'Credential failure disclosed a supplied value' }
    }
    $script:cases++
}

try {
    $tokens = $null; $errors = $null
    $ast = [Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'scripts/Start-CoreDevelopmentServer.ps1'), [ref]$tokens, [ref]$errors)
    Assert-True ($errors.Count -eq 0) 'Core startup script did not parse'
    $functions = @($ast.FindAll({ param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq 'Initialize-DevelopmentCredentials' }, $false))
    Assert-True ($functions.Count -eq 1) 'Expected one production credential resolver'
    . ([scriptblock]::Create($functions[0].Extent.Text))
    $registry = @'
DEV_ADMIN_TOKEN = "synthetic-default-admin"
DEV_PLAYER_A_TOKEN = "synthetic-default-player-a"
DEV_PLAYER_B_TOKEN = "synthetic-default-player-b"
'@

    Set-SyntheticEnvironment @{}
    $output = @(Initialize-DevelopmentCredentials $registry)
    Assert-True ($output.Count -eq 0) 'Defaults emitted credential output'
    Assert-True ($env:WH_CORE_ADMIN_TOKEN -ceq 'synthetic-default-admin' -and $env:WH_CORE_PLAYER_TOKEN -ceq 'synthetic-default-player-a' -and $env:WH_CORE_PLAYER_B_TOKEN -ceq 'synthetic-default-player-b') 'Independent development defaults were not selected'
    $cases++

    $overrides = @{ WH_CORE_ADMIN_TOKEN = 'synthetic-override-admin'; WH_CORE_PLAYER_TOKEN = 'synthetic-override-player-a'; WH_CORE_PLAYER_B_TOKEN = 'synthetic-override-player-b' }
    Set-SyntheticEnvironment $overrides
    $output = @(Initialize-DevelopmentCredentials '') # No default registry is needed.
    Assert-True ($output.Count -eq 0) 'Overrides emitted credential output'
    foreach ($name in $names) { Assert-True ([Environment]::GetEnvironmentVariable($name, 'Process') -ceq $overrides[$name]) 'An existing caller credential was replaced' }
    $cases++

    Set-SyntheticEnvironment @{ WH_CORE_ADMIN_TOKEN = 'synthetic-override-admin'; WH_CORE_PLAYER_TOKEN = 'synthetic-override-player-a' }
    $output = @(Initialize-DevelopmentCredentials $registry)
    Assert-True ($output.Count -eq 0 -and $env:WH_CORE_ADMIN_TOKEN -ceq 'synthetic-override-admin' -and $env:WH_CORE_PLAYER_TOKEN -ceq 'synthetic-override-player-a' -and $env:WH_CORE_PLAYER_B_TOKEN -ceq 'synthetic-default-player-b') 'Missing player-b did not use only its own default'
    $cases++

    foreach ($invalid in @('synthetic private bad token', ('x' * 257), ('non-ascii-' + [char]0xE9),
        "synthetic-final-lf`n", "synthetic-final-crlf`r`n", "synthetic-embedded`nlf")) {
        Test-ExpectedFailure $registry @{ WH_CORE_PLAYER_B_TOKEN = $invalid } 'WH_CORE_PLAYER_B_TOKEN must contain a valid bearer token'
    }
    $missing = $registry -replace '(?m)^DEV_PLAYER_B_TOKEN[^\r\n]*', ''
    Test-ExpectedFailure $missing @{} 'Pinned development credential declaration was not found'
    Test-ExpectedFailure ($registry + "`nDEV_PLAYER_B_TOKEN = `"synthetic-duplicate-player-b`"") @{} 'Pinned development credential declaration was not found'
    Test-ExpectedFailure ($registry.Replace('synthetic-default-player-b', 'synthetic bad default')) @{} 'WH_CORE_PLAYER_B_TOKEN must contain a valid bearer token'

    [pscustomobject]@{ status = 'PASS_SYNTHETIC_CREDENTIAL_FUNCTION_ONLY'; cases = $cases; coreOrClientStarted = $false; networkRequested = $false }
} finally {
    foreach ($name in $names) { [Environment]::SetEnvironmentVariable($name, $saved[$name], 'Process') }
}
