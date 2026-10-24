#Requires -Version 7.0
# Path-only package controls. Never execute the runner's top-level launch logic.
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (!$IsWindows) { throw 'These Windows path controls do not establish Linux behavior.' }
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$runner = Join-Path $repo 'scripts/Test-ClientPackage.ps1'
$scratchParent = [IO.Path]::GetFullPath((Join-Path $repo '.local/tests/client-package-guards'))
$fixtureRoot = Join-Path $scratchParent ([guid]::NewGuid().ToString('N'))
$cases = [Collections.Generic.List[object]]::new()

function Assert-True([bool]$Condition, [string]$Message) { if (!$Condition) { throw $Message } }
function Invoke-PathCase([string]$Name, [string]$Path, [string]$CheckoutRoot, [string]$ExpectedRejection = '') {
    $failure = $null; $result = @()
    try { $result = @(Assert-OutsideCheckoutPath -Path $Path -CheckoutRoot $CheckoutRoot) }
    catch { $failure = $_ }
    if ($ExpectedRejection) {
        Assert-True ($null -ne $failure) ('Guard accepted rejected case: ' + $Name)
        Assert-True ($failure.Exception.Message -match $ExpectedRejection) ('Unexpected rejection in case: ' + $Name)
    } else {
        if ($failure) { throw $failure }
        Assert-True ($result.Count -eq 1 -and $result[0] -is [string]) ('Guard did not return one path: ' + $Name)
        Assert-True ([string]::Equals($result[0], [IO.Path]::GetFullPath($Path), [StringComparison]::OrdinalIgnoreCase)) ('Guard did not return the normalized path: ' + $Name)
        Assert-True ([IO.Path]::IsPathFullyQualified($result[0])) ('Guard returned a relative path: ' + $Name)
    }
    $cases.Add([pscustomobject]@{ name = $Name; result = 'PASS' })
}
function New-InertExecutable([string]$Path) {
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($Path)) | Out-Null
    [IO.File]::WriteAllBytes($Path, [byte[]]@())
}
function Test-ProductionNode($Node) {
    for ($parent = $Node.Parent; $null -ne $parent; $parent = $parent.Parent) {
        if ($parent -is [Management.Automation.Language.FunctionDefinitionAst]) { return $false }
    }
    return $true
}

try {
    $tokens = $null; $parseErrors = $null
    $ast = [Management.Automation.Language.Parser]::ParseFile($runner, [ref]$tokens, [ref]$parseErrors)
    Assert-True ($parseErrors.Count -eq 0) 'Package runner must parse before extracting its path functions'
    foreach ($name in @('Assert-PlainPath', 'Assert-OutsideCheckoutPath')) {
        $nodes = @($ast.FindAll({ param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq $name }, $false))
        Assert-True ($nodes.Count -eq 1) ('Expected one path function: ' + $name)
        # Import only these two definitions. The runner's param block, environment
        # reads, helper calls, process construction and launch/finalization never run.
        . ([scriptblock]::Create($nodes[0].Extent.Text))
    }

    $guardCalls = @($ast.FindAll({ param($node) $node -is [Management.Automation.Language.CommandAst] -and $node.GetCommandName() -ceq 'Assert-OutsideCheckoutPath' }, $true) | Where-Object { Test-ProductionNode $_ })
    $coreStarts = @($ast.FindAll({ param($node) $node -is [Management.Automation.Language.CommandAst] -and $node.InvocationOperator -eq [Management.Automation.Language.TokenKind]::Ampersand -and $node.CommandElements[0].Extent.Text -match 'Start-CoreDevelopmentServer\.ps1' }, $true) | Where-Object { Test-ProductionNode $_ })
    $nativeStarts = @($ast.FindAll({ param($node) $node -is [Management.Automation.Language.InvokeMemberExpressionAst] -and $node.Expression.Extent.Text -ceq '$native' -and $node.Member.Extent.Text -ceq 'Start' }, $true) | Where-Object { Test-ProductionNode $_ })
    Assert-True ($guardCalls.Count -eq 1 -and $coreStarts.Count -eq 1 -and $nativeStarts.Count -eq 1) 'Expected one production guard, Core invocation and native Start seam'
    Assert-True ($guardCalls[0].Extent.StartOffset -lt $coreStarts[0].Extent.StartOffset -and $guardCalls[0].Extent.StartOffset -lt $nativeStarts[0].Extent.StartOffset) 'Outside-checkout guard must precede Core and native startup'
    $cases.Add([pscustomobject]@{ name = 'production guard precedes Core and native startup'; result = 'PASS' })

    $checkout = Join-Path $fixtureRoot 'checkout'
    $inside = Join-Path $checkout 'WarhammerClient/Binaries/Win64/WarhammerClient.exe'
    $localInside = Join-Path $checkout '.local/packages/archive/Windows/WarhammerClient/Binaries/Win64/WarhammerClient.exe'
    $prefixSibling = Join-Path $fixtureRoot 'checkout-packaged/WarhammerClient/Binaries/Win64/WarhammerClient.exe'
    $plainPrefixSibling = Join-Path $fixtureRoot 'checkout2/WarhammerClient/Binaries/Win64/WarhammerClient.exe'
    $spaces = Join-Path $fixtureRoot 'outside package with spaces/WarhammerClient/Binaries/Win64/WarhammerClient.exe'
    foreach ($path in @($inside, $localInside, $prefixSibling, $plainPrefixSibling, $spaces)) { New-InertExecutable $path }

    Invoke-PathCase 'inside checkout' $inside $checkout 'outside.*checkout'
    Invoke-PathCase 'inside checkout .local package' $localInside $checkout 'outside.*checkout'
    Invoke-PathCase 'checkout equality' $checkout $checkout 'outside.*checkout'
    Invoke-PathCase 'checkout equality with trailing separator' ($checkout + [IO.Path]::DirectorySeparatorChar) $checkout 'outside.*checkout'
    Invoke-PathCase 'normalized dot-dot resolves inside' (Join-Path $fixtureRoot 'checkout-packaged/../checkout/WarhammerClient/Binaries/Win64/WarhammerClient.exe') $checkout 'outside.*checkout'
    Invoke-PathCase 'case-insensitive descendant' $inside.ToUpperInvariant() $checkout.ToLowerInvariant() 'outside.*checkout'
    Invoke-PathCase 'case-insensitive equality' $checkout.ToUpperInvariant() $checkout.ToLowerInvariant() 'outside.*checkout'
    Invoke-PathCase 'checkout root with trailing separator' $localInside ($checkout + [IO.Path]::DirectorySeparatorChar) 'outside.*checkout'
    Invoke-PathCase 'separator-boundary sibling with dash' $prefixSibling $checkout
    Invoke-PathCase 'separator-boundary sibling without dash' $plainPrefixSibling $checkout
    Invoke-PathCase 'outside path with spaces' $spaces $checkout
    Invoke-PathCase 'normalized dot-dot resolves outside' (Join-Path $checkout '../checkout-packaged/WarhammerClient/Binaries/Win64/WarhammerClient.exe') $checkout

    # A narrow attribute shim exercises the reparse refusal without requesting
    # symlink/junction privileges or creating any real link. Other reads stay real.
    $script:reparseFixture = [IO.Path]::GetDirectoryName($spaces)
    $script:reparseAttributeReads = 0
    function Get-Item {
        [CmdletBinding()]
        param([Parameter(Mandatory)][string]$LiteralPath, [switch]$Force)
        if ([string]::Equals([IO.Path]::GetFullPath($LiteralPath), $script:reparseFixture, [StringComparison]::OrdinalIgnoreCase)) {
            $script:reparseAttributeReads++
            return [pscustomobject]@{ Attributes = [IO.FileAttributes]::Directory -bor [IO.FileAttributes]::ReparsePoint }
        }
        Microsoft.PowerShell.Management\Get-Item @PSBoundParameters
    }
    try {
        Invoke-PathCase 'reparse ancestor attribute stub' $spaces $checkout 'Reparse'
        Assert-True ($script:reparseAttributeReads -eq 1) 'The reparse attribute control did not exercise the guard'
    } finally { Remove-Item -LiteralPath Function:\Get-Item -ErrorAction SilentlyContinue }

    [pscustomobject]@{
        status = 'PASS_PATH_FUNCTIONS_ONLY'; cases = $cases.Count; functionDefinitionsExtracted = 2
        runnerTopLevelExecuted = $false; nativeProcessesLaunched = 0; coreProcessesLaunched = 0
        guiLaunched = $false; actualReparsePointCreated = $false; linuxRuntimeEstablished = $false
    } | ConvertTo-Json
} finally {
    # Check the exact resolved scratch target before recursive deletion, using
    # native PowerShell end-to-end and leaving all other workspace files alone.
    $resolvedFixture = [IO.Path]::GetFullPath($fixtureRoot)
    if (!$resolvedFixture.StartsWith($scratchParent.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Refusing scratch cleanup outside its parent' }
    if (Test-Path -LiteralPath $resolvedFixture) { Remove-Item -LiteralPath $resolvedFixture -Recurse -Force }
}
