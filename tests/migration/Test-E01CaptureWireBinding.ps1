# Source-unit guard checks only. This does not execute an E01 wrapper phase.
# Requires only PowerShell and the tracked reviewed wire corpus; it creates
# explicitly simulated metadata and copies in a new ignored private directory.
param([string] $OutputRoot = '', [string] $ActualUnitLogPath = '', [int] $ActualUnitCount = 0)
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
    'Read-Json', 'Assert-Candidate', 'Get-PythonUnitEvidence', 'Get-CurrentCaptureWireEvidence', 'Assert-CaptureWireBinding',
    'New-EditorSettingsPaths', 'Get-EditorSettingsPaths', 'Get-EditorSettingsAttributes', 'Get-EditorSettingsState',
    'Assert-EditorSettingsState', 'Save-EditorSettingsFailureEvidence')
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
if ($ActualUnitLogPath) {
    $ActualUnitLogPath = Assert-ChildPath ([IO.Path]::GetFullPath($ActualUnitLogPath)) (Join-Path $projectRoot '.local\experiments\E01-target')
    Require-File $ActualUnitLogPath
    if ($ActualUnitCount -le 0) { throw 'Actual unit-log evidence requires its expected positive case count.' }
    $sourcePaths += $ActualUnitLogPath
} elseif ($ActualUnitCount -ne 0) { throw 'Actual unit count requires an explicit preserved unit-log path.' }
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

function Check-PythonUnitLog([string] $Name, [string] $Text, [int] $ExpectedCount = 0, [string] $ExpectedFailure = '') {
    $failure = $null; $evidence = $null
    try { $evidence = Get-PythonUnitEvidence $Text } catch { $failure = $_.Exception.Message }
    $pass = if ($ExpectedFailure) { $null -ne $failure -and $failure -like ('*' + $ExpectedFailure + '*') } else {
        $null -eq $failure -and $evidence.executed -eq $ExpectedCount -and $evidence.status -ceq 'PASS' -and $evidence.footer -ceq 'OK'
    }
    $checks.Add(@{ name = $Name; status = $(if ($pass) { 'PASS' } else { 'FAIL' }); kind = 'unittest-summary-parser'
        expectedCount = $ExpectedCount; expectedFailure = $ExpectedFailure; observedFailure = $failure; evidence = $evidence })
    Write-Output ("{0}: {1}" -f $Name, $(if ($pass) { 'PASS' } else { 'FAIL' }))
}

$summary = "Ran 2 tests in 0.125s`n`n"
$verbose = "test_failed_evidence_preserves_validated_accepted_and_rejected_receipts_when_raw_damaged (EvidenceTests) ... ok`n" +
    "test_FAILED_skipped_expected_failures_unexpected_successes_are_ordinary_name_words (EvidenceTests) ... ok`n`n" +
    "----------------------------------------------------------------------`n" + $summary
Check-PythonUnitLog 'unit-verbose-name-words-are-not-footers' ($verbose + "OK`n") 2
Check-PythonUnitLog 'unit-single-test-summary' "Ran 1 test in 0.000s`n`nOK`n" 1
Check-PythonUnitLog 'unit-crlf-summary' "Ran 2 tests in 0.125s`r`n`r`nOK`r`n" 2
Check-PythonUnitLog 'unit-failed-footer' ($verbose + "FAILED (failures=1)`n") 0 'final footer must be exactly OK'
Check-PythonUnitLog 'unit-skipped-footer' ($verbose + "OK (skipped=1)`n") 0 'final footer must be exactly OK'
Check-PythonUnitLog 'unit-expected-failure-footer' ($verbose + "OK (expected failures=1)`n") 0 'final footer must be exactly OK'
Check-PythonUnitLog 'unit-unexpected-success-footer' ($verbose + "FAILED (unexpected successes=1)`n") 0 'final footer must be exactly OK'
Check-PythonUnitLog 'unit-annotated-unexpected-success-footer' ($verbose + "OK (unexpected successes=1)`n") 0 'final footer must be exactly OK'
Check-PythonUnitLog 'unit-missing-summary' "OK`n" 0 'exactly one standard anchored unittest summary'
Check-PythonUnitLog 'unit-missing-footer' $summary 0 'final footer must be exactly OK'
Check-PythonUnitLog 'unit-duplicate-summary' ($summary + $summary + "OK`n") 0 'exactly one standard anchored unittest summary'
Check-PythonUnitLog 'unit-zero-summary' "Ran 0 tests in 0.000s`n`nOK`n" 0 'positive count and finite duration'
Check-PythonUnitLog 'unit-zero-and-positive-summaries' ("Ran 0 tests in 0.000s`n`n" + $summary + "OK`n") 0 'exactly one standard anchored unittest summary'
Check-PythonUnitLog 'unit-extra-trailing-output' ($verbose + "OK`nextra output`n") 0 'final footer must be exactly OK'
Check-PythonUnitLog 'unit-duplicate-footer' ($verbose + "OK`nOK`n") 0 'final footer must be exactly OK'
Check-PythonUnitLog 'unit-malformed-duration' "Ran 2 tests in NaNs`n`nOK`n" 0 'exactly one standard anchored unittest summary'
Check-PythonUnitLog 'unit-wrong-singular-summary' "Ran 2 test in 0.125s`n`nOK`n" 0 'positive count and finite duration'
if ($ActualUnitLogPath) {
    Check-PythonUnitLog 'unit-preserved-full-verbose-log' ([IO.File]::ReadAllText($ActualUnitLogPath, $utf8)) $ActualUnitCount
}

# Editor preservation controls use invented metadata only. No editor settings
# file is written, and the Native dispatcher/build/editor are never invoked.
$EngineRoot = Join-Path $OutputRoot 'SIMULATED-engine'
$phaseResult.toolchain = @{ engineVersion = @{ MajorVersion = 5; MinorVersion = 8 } }
function New-SimulatedEditorState {
    $index = 0
    return @(foreach ($setting in Get-EditorSettingsPaths) {
        $present = $index -in @(0, 2, 4); $index++
        @{ role = $setting.role; path = $setting.path; exists = $present; inspection = 'PASS'
            sha256 = $(if ($present) { 'a' * 64 } else { $null }) }
    })
}

function Check-EditorGuard([string] $Name, [scriptblock] $Mutation, [string] $ExpectedFailure = '') {
    $editorBefore = @(New-SimulatedEditorState)
    $editorAfter = @((ConvertTo-Json -InputObject $editorBefore -Depth 8) | ConvertFrom-Json -AsHashtable)
    . $Mutation
    $failure = $null
    try { Assert-EditorSettingsState $editorBefore $editorAfter } catch { $failure = $_.Exception.Message }
    $pass = if ($ExpectedFailure) { $null -ne $failure -and $failure -like ('*' + $ExpectedFailure + '*') } else { $null -eq $failure }
    $checks.Add(@{ name = $Name; status = $(if ($pass) { 'PASS' } else { 'FAIL' }); kind = 'editor-settings-metadata'
        simulation = $true; beforeCount = $editorBefore.Count; afterCount = $editorAfter.Count; expectedFailure = $ExpectedFailure; observedFailure = $failure })
    Write-Output ("{0}: {1}" -f $Name, $(if ($pass) { 'PASS' } else { 'FAIL' }))
}

Check-EditorGuard 'editor-six-unchanged' {}
Check-EditorGuard 'editor-reordered-roles-unchanged' { [array]::Reverse($editorAfter) }
Check-EditorGuard 'editor-changed-hash' { $editorAfter[0].sha256 = 'b' * 64 } 'existence or hash changed'
Check-EditorGuard 'editor-file-appeared' { $editorAfter[1].exists = $true; $editorAfter[1].sha256 = 'b' * 64 } 'existence or hash changed'
Check-EditorGuard 'editor-file-disappeared' { $editorAfter[0].exists = $false; $editorAfter[0].sha256 = $null } 'existence or hash changed'
Check-EditorGuard 'editor-missing-after-role' { $editorAfter = @($editorAfter | Select-Object -First 5) } 'all six observations'
Check-EditorGuard 'editor-missing-before-role' { $editorBefore = @($editorBefore | Select-Object -First 5) } 'all six observations'
Check-EditorGuard 'editor-duplicate-role' { $editorAfter[5] = $editorAfter[4] } 'membership is missing or duplicated'
Check-EditorGuard 'editor-unknown-role' { $editorAfter[5].role = 'invented-role' } 'membership is missing or duplicated'
Check-EditorGuard 'editor-extra-role' { $editorAfter += $editorAfter[0] } 'all six observations'
Check-EditorGuard 'editor-path-substitution' { $editorAfter[0].path += '.substituted' } 'path changed or was substituted'
Check-EditorGuard 'editor-matching-path-substitution' { $editorAfter[0].path += '.substituted'; $editorBefore[0].path = $editorAfter[0].path } 'path changed or was substituted'
Check-EditorGuard 'editor-present-without-hash' { $editorAfter[0].sha256 = $null } 'invalid existence/hash metadata'
Check-EditorGuard 'editor-absent-with-hash' { $editorAfter[1].sha256 = 'a' * 64 } 'invalid existence/hash metadata'
Check-EditorGuard 'editor-nonboolean-existence' { $editorAfter[0].exists = 'true' } 'invalid existence/hash metadata'
Check-EditorGuard 'editor-unavailable-inspection' { $editorAfter[0].inspection = 'UNAVAILABLE' } 'unavailable or has invalid'

$coincident = @(New-EditorSettingsPaths (Join-Path $OutputRoot 'engine') (Join-Path $OutputRoot 'project') `
    (Join-Path $OutputRoot 'local') (Join-Path $OutputRoot 'profile') (Join-Path $OutputRoot 'profile\Documents') 5 8)
$coincidentPass = $coincident.Count -eq 6 -and @($coincident.role | Sort-Object -Unique).Count -eq 6 -and
    @($coincident | Where-Object { $_.role -in @('profile-documents-user', 'known-documents-user') } | Select-Object -ExpandProperty path -Unique).Count -eq 1
$checks.Add(@{ name = 'editor-coincident-documents-retain-six-roles'; kind = 'editor-settings-paths'; simulation = $true
    status = $(if ($coincidentPass) { 'PASS' } else { 'FAIL' }); observations = $coincident.Count })
Write-Output ("editor-coincident-documents-retain-six-roles: {0}" -f $(if ($coincidentPass) { 'PASS' } else { 'FAIL' }))

function Check-CoincidentEditorComparison {
    function Get-EditorSettingsPaths { return $coincident }
    $snapshot = @(New-SimulatedEditorState)
    $failure = $null
    try { Assert-EditorSettingsState $snapshot $snapshot } catch { $failure = $_.Exception.Message }
    $pass = $null -eq $failure -and $snapshot.Count -eq 6
    $checks.Add(@{ name = 'editor-coincident-documents-compare-by-role'; kind = 'editor-settings-metadata'; simulation = $true
        status = $(if ($pass) { 'PASS' } else { 'FAIL' }); observations = $snapshot.Count; observedFailure = $failure })
    Write-Output ("editor-coincident-documents-compare-by-role: {0}" -f $(if ($pass) { 'PASS' } else { 'FAIL' }))
}
Check-CoincidentEditorComparison

function Check-EditorInspection([string] $Name, [string] $Mode, [string] $ExpectedInspection, $ExpectedExists) {
    $hashCalls = [Collections.Generic.List[string]]::new()
    # Supply only invented attributes/errors/hash bytes to the maintained sampler.
    # No settings file or directory is queried or changed by these controls.
    function Get-EditorSettingsAttributes([string] $Path) {
        switch ($Mode) {
            'missing-file' { throw [IO.FileNotFoundException]::new('SIMULATED_NOT_FOUND') }
            'missing-parent' { throw [IO.DirectoryNotFoundException]::new('SIMULATED_PARENT_NOT_FOUND') }
            'denied' { throw [UnauthorizedAccessException]::new('SIMULATED_ACCESS_DENIED') }
            'io-error' { throw [IO.IOException]::new('SIMULATED_IO_ERROR') }
            'security-error' { throw [Security.SecurityException]::new('SIMULATED_SECURITY_ERROR') }
            'broken-link' { return [IO.FileAttributes]::ReparsePoint }
            'directory' { return [IO.FileAttributes]::Directory }
            default { return [IO.FileAttributes]::Normal }
        }
    }
    function Get-Hash([string] $Path) {
        $hashCalls.Add($Path)
        if ($Mode -eq 'hash-race') { throw [IO.FileNotFoundException]::new('SIMULATED_DISAPPEARED_AFTER_ATTRIBUTES') }
        return 'a' * 64
    }
    $snapshot = @(Get-EditorSettingsState)
    $pass = $snapshot.Count -eq 6 -and @($snapshot | Where-Object {
        $_.inspection -cne $ExpectedInspection -or $_.exists -cne $ExpectedExists
    }).Count -eq 0
    $expectedHashCalls = if ($Mode -in @('present', 'hash-race')) { 6 } else { 0 }
    $pass = $pass -and $hashCalls.Count -eq $expectedHashCalls
    $checks.Add(@{ name = $Name; kind = 'editor-settings-sampler'; simulation = $true; status = $(if ($pass) { 'PASS' } else { 'FAIL' })
        expectedInspection = $ExpectedInspection; expectedExists = $ExpectedExists; hashCalls = $hashCalls.Count; retained = $snapshot })
    Write-Output ("{0}: {1}" -f $Name, $(if ($pass) { 'PASS' } else { 'FAIL' }))
}
Check-EditorInspection 'editor-inspection-present-file' 'present' 'PASS' $true
Check-EditorInspection 'editor-inspection-explicit-missing-file' 'missing-file' 'PASS' $false
Check-EditorInspection 'editor-inspection-explicit-missing-parent' 'missing-parent' 'PASS' $false
Check-EditorInspection 'editor-inspection-access-denied-is-unknown' 'denied' 'UNAVAILABLE' $null
Check-EditorInspection 'editor-inspection-io-error-is-unknown' 'io-error' 'UNAVAILABLE' $null
Check-EditorInspection 'editor-inspection-security-error-is-unknown' 'security-error' 'UNAVAILABLE' $null
Check-EditorInspection 'editor-inspection-broken-link-is-unavailable' 'broken-link' 'UNAVAILABLE' $true
Check-EditorInspection 'editor-inspection-directory-is-unavailable' 'directory' 'UNAVAILABLE' $true
Check-EditorInspection 'editor-inspection-hash-race-is-not-absence' 'hash-race' 'UNAVAILABLE' $true

function Check-EditorFailureEvidence([string] $Name, [string] $Mode) {
    $simulatedAfter = @(New-SimulatedEditorState)
    $record = [ordered]@{ failure = 'SIMULATED_PRIMARY_BUILD_FAILURE'; editorSettingsBefore = @(New-SimulatedEditorState) }
    if ($Mode -eq 'changed') { $simulatedAfter[0].sha256 = 'b' * 64 }
    if ($Mode -eq 'unavailable') { $simulatedAfter[0].inspection = 'UNAVAILABLE'; $simulatedAfter[0].sha256 = $null }
    # This local metadata provider shadows only filesystem sampling. The actual
    # maintained failure recorder and membership/hash assertion run unchanged.
    function Get-EditorSettingsState { if ($Mode -eq 'provider-failed') { throw 'SIMULATED_METADATA_PROVIDER_FAILURE' }; return $simulatedAfter }
    Save-EditorSettingsFailureEvidence $record
    $pass = $record.failure -ceq 'SIMULATED_PRIMARY_BUILD_FAILURE' -and $record.Contains('editorSettingsAfterFailureUtc')
    if ($Mode -eq 'provider-failed') { $pass = $pass -and $record.Contains('editorSettingsFailure') }
    else { $pass = $pass -and @($record.editorSettingsAfterFailure).Count -eq 6 }
    if ($Mode -in @('changed', 'unavailable')) { $pass = $pass -and $record.Contains('editorSettingsFailure') }
    if ($Mode -eq 'unchanged') { $pass = $pass -and -not $record.Contains('editorSettingsFailure') }
    $checks.Add(@{ name = $Name; kind = 'editor-settings-post-failure'; simulation = $true; status = $(if ($pass) { 'PASS' } else { 'FAIL' })
        primaryFailurePreserved = ($record.failure -ceq 'SIMULATED_PRIMARY_BUILD_FAILURE'); retained = $record })
    Write-Output ("{0}: {1}" -f $Name, $(if ($pass) { 'PASS' } else { 'FAIL' }))
}
Check-EditorFailureEvidence 'editor-primary-failure-unchanged-after' 'unchanged'
Check-EditorFailureEvidence 'editor-primary-failure-retains-changed-after' 'changed'
Check-EditorFailureEvidence 'editor-primary-failure-retains-unavailable-after' 'unavailable'
Check-EditorFailureEvidence 'editor-primary-failure-provider-also-fails' 'provider-failed'

$sourceAfter = @(foreach ($record in $sourceBefore) { @{ path = $record.path; sha256 = Get-Hash $record.path; unchanged = ((Get-Hash $record.path) -ceq $record.sha256) } })
$passed = @($checks | Where-Object { $_.status -eq 'PASS' }).Count
$invocation = @('pwsh', '-NoProfile', '-File', $PSCommandPath, '-OutputRoot', $OutputRoot)
if ($ActualUnitLogPath) { $invocation += @('-ActualUnitLogPath', $ActualUnitLogPath, '-ActualUnitCount', $ActualUnitCount) }
$result = @{ purpose = 'Private simulated source-unit guard checks; no actual E01 phase, Core host, native build, install or global configuration mutation'
    invocation = $invocation; wrapperSha256 = Get-Hash $guardWrapperPath
    unitScriptSha256 = Get-Hash $PSCommandPath; sourceBefore = $sourceBefore; sourceAfter = $sourceAfter; checks = @($checks)
    executed = $checks.Count; passed = $passed; failed = $checks.Count - $passed; scriptPathBinding = 'Only automatic PSCommandPath adapted to the reviewed wrapper path in extracted function definitions' }
Write-PrivateJson (Join-Path $OutputRoot 'guard-unit-result.json') $result
Write-Output ("Guard checks: {0}/{1} PASS" -f $passed, $checks.Count)
if ($passed -ne $checks.Count -or @($sourceAfter | Where-Object { -not $_.unchanged }).Count -ne 0) { exit 1 }
