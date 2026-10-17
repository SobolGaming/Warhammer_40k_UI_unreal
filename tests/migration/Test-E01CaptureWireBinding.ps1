# Source-unit guard checks only. This does not execute an E01 wrapper phase.
# Requires only PowerShell and the tracked reviewed wire corpus; it creates
# explicitly simulated metadata and copies in a new ignored private directory.
param([string] $OutputRoot = '')
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$guardWrapperPath = Join-Path $projectRoot 'scripts\migration\Invoke-E01BoundaryProof.ps1'
$packetPath = Join-Path $projectRoot 'docs\plans\research\2026-10-16-e01-boundary-packet.md'
$harnessPath = Join-Path $projectRoot 'scripts\migration\e01_boundary.py'
$unitTestsPath = Join-Path $projectRoot 'tests\migration\test_e01_boundary.py'
$sourceManifestPath = Join-Path $projectRoot 'tests\migration\fixtures\5f509724da25a2f6ded0c2739a8e7c84bdf59c91\manifest.json'
$expectedCommit = '5f509724da25a2f6ded0c2739a8e7c84bdf59c91'
$expectedBuild = 'warhammer40k-core-v2:runtime-tree-sha256-v1:65fc8414407ae5d6a8ea779c8e737a22733459094db679a160c60f6e2129f96a'
$utf8 = [Text.UTF8Encoding]::new($false, $true)
$script:secretValues = @()
$tokens = $null; $parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($guardWrapperPath, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count) { throw 'Wrapper AST failed.' }
$names = @('Assert-NoReparsePoint', 'Assert-ChildPath', 'Get-MemberPath', 'Require-File', 'Get-Hash', 'Assert-SafeText',
    'Read-Json', 'Assert-Candidate', 'Get-CurrentCaptureWireEvidence', 'Assert-CaptureWireBinding')
foreach ($definition in $ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false)) {
    if ($definition.Name -in $names) {
        # Extracted function definitions lose their automatic source-file binding.
        # Only that automatic variable is rebound; the tested guard logic is raw.
        Invoke-Expression $definition.Extent.Text.Replace('$PSCommandPath', '$guardWrapperPath')
    }
}
if (-not $OutputRoot) { $OutputRoot = Join-Path $projectRoot ('.local\tests\e01-wire-binding-' + [guid]::NewGuid().ToString('N')) }
$OutputRoot = Assert-ChildPath ([IO.Path]::GetFullPath($OutputRoot)) (Join-Path $projectRoot '.local\tests')
if (Test-Path -LiteralPath $OutputRoot) { throw 'Refusing an existing private test-output root.' }
$null = [IO.Directory]::CreateDirectory($OutputRoot)
$actualRoot = Join-Path $projectRoot 'tests\migration\fixtures\5f509724da25a2f6ded0c2739a8e7c84bdf59c91\wire'
$indexBytes = [IO.File]::ReadAllBytes((Join-Path $actualRoot 'index.json'))
$indexTemplate = $utf8.GetString($indexBytes) | ConvertFrom-Json -AsHashtable
$simulatedRuntime = Join-Path $OutputRoot 'SIMULATED-runtime-provenance.json'
[IO.File]::WriteAllText($simulatedRuntime, '{"SIMULATED_UNIT_FIXTURE":true,"realRuntimeVerified":false}', $utf8)
$runtime = @{ provenance = $simulatedRuntime; provenanceSha256 = Get-Hash $simulatedRuntime; runtimeTreeSha256 = 'b' * 64 }
$sourcePaths = @($guardWrapperPath, $harnessPath, $unitTestsPath, $sourceManifestPath, $packetPath, $PSCommandPath,
    (Join-Path $actualRoot 'index.json')) + @($indexTemplate.cases | ForEach-Object { Get-MemberPath $actualRoot $_.path })
$sourceBefore = @(foreach ($path in $sourcePaths) { @{ path = $path; sha256 = Get-Hash $path } })
$checks = [Collections.Generic.List[object]]::new()
$CaptureRunId = ''

function Write-PrivateJson([string] $Path, $Value) {
    $Path = Assert-ChildPath $Path $OutputRoot
    $null = [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($Path))
    [IO.File]::WriteAllText($Path, (($Value | ConvertTo-Json -Depth 40) + "`n"), $utf8)
}

function New-SimulatedFixture([string] $Name) {
    $script:runRoot = Join-Path $OutputRoot $Name
    $script:RunId = 'SIMULATED-GUARD-UNIT-ONLY'
    $script:fixtureRoot = Join-Path $runRoot 'versioned-fixtures'
    $script:phaseResult = @{ runtime = $runtime }
    $script:inputRoot = Join-Path $runRoot 'capture\python-capture\proposed-wire'
    $script:targetRoot = Join-Path $fixtureRoot 'wire'
    foreach ($root in @($inputRoot, $targetRoot)) {
        $null = [IO.Directory]::CreateDirectory($root)
        [IO.File]::WriteAllBytes((Join-Path $root 'index.json'), $indexBytes)
        foreach ($row in $indexTemplate.cases) {
            $target = Get-MemberPath $root $row.path
            $null = [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target))
            [IO.File]::Copy((Get-MemberPath $actualRoot $row.path), $target, $false)
        }
    }
    $artifacts = @(@{ path = Join-Path $inputRoot 'index.json'; sha256 = Get-Hash (Join-Path $inputRoot 'index.json'); bytes = $indexBytes.Length })
    $artifacts += @(foreach ($row in $indexTemplate.cases) {
        $path = Get-MemberPath $inputRoot $row.path
        @{ path = $path; sha256 = Get-Hash $path; bytes = [IO.FileInfo]::new($path).Length }
    })
    $requirements = @(
        @{ phase = 'preflight'; relative = 'python-preflight'; status = 'SOURCE_INVENTORY_PASS'; ids = @('SOURCE-01') },
        @{ phase = 'verify-runtime'; relative = 'python-runtime'; status = 'INSTALLED_RUNTIME_PASS'; ids = @('SOURCE-01', 'RUNTIME-01') },
        @{ phase = 'capture'; relative = 'python-capture'; status = 'LOCAL_HTTP_BOUNDARY_PASS'; ids = @('SOURCE-01', 'RUNTIME-01', 'SCHEMA-01', 'SCOPE-01', 'AUTH-01', 'VIEW-01', 'FINITE-01', 'RETRY-01', 'STALE-01', 'FIDELITY-01', 'MOVE-01', 'MOVE-02', 'ERROR-01', 'LIFETIME-01') }
    )
    $children = @(foreach ($required in $requirements) {
        $path = Join-Path $runRoot ('capture\' + $required.relative + '\report.json')
        $counts = @{ discovered = $required.ids.Count; executed = $required.ids.Count; passed = $required.ids.Count; failed = 0; blocked = 0; notRun = 0 }
        $report = @{ SIMULATED_UNIT_FIXTURE = $true; schemaVersion = 1; phase = $required.phase; status = $required.status; caseCounts = $counts
            cases = @($required.ids | ForEach-Object { @{ id = $_; status = 'PASS' } }); redaction = @{ status = 'PASS' }
            artifacts = $(if ($required.phase -eq 'capture') { $artifacts } else { @() }) }
        Write-PrivateJson $path $report
        @{ phase = $required.phase; path = $path; sha256 = Get-Hash $path; status = $required.status; caseCounts = $counts }
    })
    $preparePath = Join-Path $runRoot 'prepareruntime\result.json'
    Write-PrivateJson $preparePath @{ SIMULATED_UNIT_FIXTURE = $true; phase = 'PrepareRuntime'; runId = $RunId; status = 'INSTALLED_RUNTIME_PASS'; runtime = $runtime }
    $capture = @{ SIMULATED_UNIT_FIXTURE = $true; schemaVersion = 1; packet = 'E01-WIN-BOUNDARY'; phase = 'Capture'; runId = $RunId; runRoot = $runRoot
        status = 'LOCAL_HTTP_BOUNDARY_PASS'; redaction = @{ status = 'PASS' }; unitTests = @{ status = 'PASS'; executed = 47 }; runtime = $runtime
        predecessor = @{ path = $preparePath; sha256 = Get-Hash $preparePath }; childReports = $children
        candidate = @{ files = @(@($guardWrapperPath, $packetPath, $harnessPath, $unitTestsPath, $sourceManifestPath) | ForEach-Object { @{ path = $_; sha256 = Get-Hash $_ } }) }
        source = @{ coreCommit = $expectedCommit; contractVersion = '44.3.33'; runtimeBuildId = $expectedBuild; sourceManifestSha256 = Get-Hash $sourceManifestPath } }
    Write-PrivateJson (Join-Path $runRoot 'capture\result.json') $capture
}

function Update-CaptureReport($Report) {
    $reportPath = Join-Path $runRoot 'capture\python-capture\report.json'
    Write-PrivateJson $reportPath $Report
    $capturePath = Join-Path $runRoot 'capture\result.json'
    $capture = Read-Json $capturePath
    $capture.childReports[2].sha256 = Get-Hash $reportPath
    $capture.childReports[2].caseCounts = $Report.caseCounts
    Write-PrivateJson $capturePath $capture
}

function Update-Indexes($Index) {
    foreach ($root in @($inputRoot, $targetRoot)) { Write-PrivateJson (Join-Path $root 'index.json') $Index }
    $report = Read-Json (Join-Path $runRoot 'capture\python-capture\report.json')
    $report.artifacts[0].sha256 = Get-Hash (Join-Path $inputRoot 'index.json')
    $report.artifacts[0].bytes = [IO.FileInfo]::new((Join-Path $inputRoot 'index.json')).Length
    Update-CaptureReport $report
}

function Check-Guard([string] $Name, [scriptblock] $Mutation, [string] $ExpectedFailure = '') {
    New-SimulatedFixture $Name
    & $Mutation
    $failure = $null; $binding = $null
    try { $binding = Get-CurrentCaptureWireEvidence } catch { $failure = $_.Exception.Message }
    $pass = if ($ExpectedFailure) { $null -ne $failure -and $failure -like ('*' + $ExpectedFailure + '*') } else { $null -eq $failure -and $binding.bodyCount -eq 30 }
    $checks.Add(@{ name = $Name; status = $(if ($pass) { 'PASS' } else { 'FAIL' }); expectedFailure = $ExpectedFailure; observedFailure = $failure
        simulation = $true; bodyCount = $(if ($null -eq $binding) { $null } else { $binding.bodyCount }) })
    Write-Output ("{0}: {1}" -f $Name, $(if ($pass) { 'PASS' } else { 'FAIL' }))
}

Check-Guard 'positive-47-units' {}
Check-Guard 'positive-40-units' {
    $path = Join-Path $runRoot 'capture\result.json'; $capture = Read-Json $path; $capture.unitTests.executed = 40; Write-PrivateJson $path $capture
}
Check-Guard 'self-consistent-stale-corpus' {
    # Current Capture now records different, still valid JSON bytes. Both the
    # stale versioned corpus and the fresh source corpus retain correct hashes.
    $index = $utf8.GetString($indexBytes) | ConvertFrom-Json -AsHashtable
    $path = Get-MemberPath $inputRoot $index.cases[0].path
    [IO.File]::AppendAllText($path, "`n", $utf8)
    $index.cases[0].sha256 = Get-Hash $path
    Write-PrivateJson (Join-Path $inputRoot 'index.json') $index
    $report = Read-Json (Join-Path $runRoot 'capture\python-capture\report.json')
    $report.artifacts[0].sha256 = Get-Hash (Join-Path $inputRoot 'index.json')
    $report.artifacts[0].bytes = [IO.FileInfo]::new((Join-Path $inputRoot 'index.json')).Length
    $report.artifacts[1].sha256 = Get-Hash $path; $report.artifacts[1].bytes = [IO.FileInfo]::new($path).Length
    Update-CaptureReport $report
} 'not byte-identical'
Check-Guard 'versioned-body-substitution' { $path = Get-MemberPath $targetRoot $indexTemplate.cases[0].path; [IO.File]::AppendAllText($path, "`n", $utf8) } 'not byte-identical'
Check-Guard 'source-body-substitution' { $path = Get-MemberPath $inputRoot $indexTemplate.cases[0].path; [IO.File]::AppendAllText($path, "`n", $utf8) } 'artifact path/hash/length differs'
Check-Guard 'missing-reported-index' {
    $report = Read-Json (Join-Path $runRoot 'capture\python-capture\report.json'); $report.artifacts = @($report.artifacts | Select-Object -Skip 1); Update-CaptureReport $report
} 'must list its proposed wire index'
Check-Guard 'duplicate-reported-index' {
    $report = Read-Json (Join-Path $runRoot 'capture\python-capture\report.json'); $report.artifacts += $report.artifacts[0]; Update-CaptureReport $report
} 'artifact path/hash/length differs'
Check-Guard 'reported-index-wrong-hash' {
    $report = Read-Json (Join-Path $runRoot 'capture\python-capture\report.json'); $report.artifacts[0].sha256 = '0' * 64; Update-CaptureReport $report
} 'artifact path/hash/length differs'
Check-Guard 'failed-capture-child' {
    $report = Read-Json (Join-Path $runRoot 'capture\python-capture\report.json'); $report.status = 'FAIL'; Update-CaptureReport $report
} 'child report identity or redaction failed'
Check-Guard 'missing-boundary-case' {
    $report = Read-Json (Join-Path $runRoot 'capture\python-capture\report.json'); $report.cases = @($report.cases | Select-Object -Skip 1)
    $report.caseCounts.discovered = 13; $report.caseCounts.executed = 13; $report.caseCounts.passed = 13; Update-CaptureReport $report
} 'case counts did not all pass'
Check-Guard 'wrong-role-filename' { $index = $utf8.GetString($indexBytes) | ConvertFrom-Json -AsHashtable; $index.cases[0].role = 'playerB'; Update-Indexes $index } 'path/role identity'
Check-Guard 'admin-role-refused' { $index = $utf8.GetString($indexBytes) | ConvertFrom-Json -AsHashtable; $index.cases[0].role = 'admin'; Update-Indexes $index } 'identity/role/outcome metadata'
Check-Guard 'outcome-status-mismatch' { $index = $utf8.GetString($indexBytes) | ConvertFrom-Json -AsHashtable; $index.cases[0].expected_outcome = 'accepted'; Update-Indexes $index } 'outcome/status metadata is inconsistent'
Check-Guard 'duplicate-case-role' { $index = $utf8.GetString($indexBytes) | ConvertFrom-Json -AsHashtable; $index.cases[1] = $index.cases[0]; Update-Indexes $index } 'path/role identity is duplicate'
Check-Guard 'unindexed-versioned-file' { [IO.File]::WriteAllText((Join-Path $targetRoot 'extra.json'), '{}', $utf8) } 'Unindexed or duplicate wire file'
Check-Guard 'zero-unit-count' { $path = Join-Path $runRoot 'capture\result.json'; $capture = Read-Json $path; $capture.unitTests.executed = 0; Write-PrivateJson $path $capture } 'positive unit-test count'
Check-Guard 'changed-authored-candidate-hash' { $path = Join-Path $runRoot 'capture\result.json'; $capture = Read-Json $path; $capture.candidate.files[0].sha256 = '0' * 64; Write-PrivateJson $path $capture } 'Frozen authored candidate changed'

foreach ($mode in @('capture-substitution-after-native', 'index-metadata-substitution-after-native')) {
    New-SimulatedFixture $mode
    $accepted = Get-CurrentCaptureWireEvidence
    if ($mode -eq 'capture-substitution-after-native') {
        $path = Join-Path $runRoot 'capture\result.json'; $capture = Read-Json $path; $capture.unitTests.executed = 48; Write-PrivateJson $path $capture
    } else {
        $index = $utf8.GetString($indexBytes) | ConvertFrom-Json -AsHashtable; $index.cases[0].recipe += ' SIMULATED-METADATA-SUBSTITUTION'; Update-Indexes $index
    }
    $current = Get-CurrentCaptureWireEvidence
    $failure = $null
    try { Assert-CaptureWireBinding $accepted $current } catch { $failure = $_.Exception.Message }
    $pass = $null -ne $failure -and $failure -like '*linkage changed after native acceptance*'
    $checks.Add(@{ name = $mode; status = $(if ($pass) { 'PASS' } else { 'FAIL' }); observedFailure = $failure; simulation = $true })
    Write-Output ("{0}: {1}" -f $mode, $(if ($pass) { 'PASS' } else { 'FAIL' }))
}
$sourceAfter = @(foreach ($record in $sourceBefore) { @{ path = $record.path; sha256 = Get-Hash $record.path; unchanged = ((Get-Hash $record.path) -ceq $record.sha256) } })
$passed = @($checks | Where-Object { $_.status -eq 'PASS' }).Count
$result = @{ purpose = 'Private simulated source-unit guard checks; no actual E01 phase, Core host, native build, install or global configuration mutation'
    invocation = @('pwsh', '-NoProfile', '-File', $PSCommandPath, '-OutputRoot', $OutputRoot); wrapperSha256 = Get-Hash $guardWrapperPath
    unitScriptSha256 = Get-Hash $PSCommandPath; sourceBefore = $sourceBefore; sourceAfter = $sourceAfter; checks = @($checks)
    executed = $checks.Count; passed = $passed; failed = $checks.Count - $passed; scriptPathBinding = 'Only automatic PSCommandPath adapted to the reviewed wrapper path in extracted function definitions' }
Write-PrivateJson (Join-Path $OutputRoot 'guard-unit-result.json') $result
Write-Output ("Guard checks: {0}/{1} PASS" -f $passed, $checks.Count)
if ($passed -ne $checks.Count -or @($sourceAfter | Where-Object { -not $_.unchanged }).Count -ne 0) { exit 1 }
