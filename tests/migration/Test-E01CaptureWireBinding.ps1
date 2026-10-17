# Source-unit guard checks only. This does not execute an E01 wrapper phase.
# Requires only PowerShell and the tracked reviewed wire corpus; it creates
# explicitly simulated metadata and copies in a new ignored private directory.
param([string] $OutputRoot = '', [string] $ActualUnitLogPath = '', [int] $ActualUnitCount = 0, [string] $ActualPhaseResultPath = '')
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
    'New-EditorSettingsPaths', 'Get-EditorSettingsPaths', 'Get-PreservationFileAttributes', 'Get-EditorSettingsState',
    'Assert-EditorSettingsState', 'Save-EditorSettingsFailureEvidence', 'Get-SafeFailureEvidence', 'Get-UBTSettings',
    'New-ChildEnvironment', 'New-OwnedProcessHandle', 'New-OwnedLogWriter', 'Get-OwnedProcessIdentity',
    'Add-OwnedProcessSecondaryFailure', 'Stop-OwnedProcess', 'Invoke-OwnedProcess', 'Assert-SafeStructuredNode',
    'Assert-SafeStructuredValue', 'Assert-SafeJsonElement', 'Assert-SafeDecodedJson', 'New-JsonOutputStream', 'Write-NewJson',
    'Get-PhaseFailureEnvelope', 'Write-PhaseFailureDiagnostic', 'Complete-PhaseFinalization')
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
if ($ActualPhaseResultPath) {
    $ActualPhaseResultPath = Assert-ChildPath ([IO.Path]::GetFullPath($ActualPhaseResultPath)) (Join-Path $projectRoot '.local\experiments\E01-target')
    Require-File $ActualPhaseResultPath
    $sourcePaths += $ActualPhaseResultPath
}
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
    function Get-PreservationFileAttributes([string] $Path) {
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
    if ($ExpectedInspection -eq 'UNAVAILABLE') {
        $expectedDetails = switch ($Mode) {
            'denied' { 'SIMULATED_ACCESS_DENIED' }; 'io-error' { 'SIMULATED_IO_ERROR' }; 'security-error' { 'SIMULATED_SECURITY_ERROR' }
            'broken-link' { 'Editor-settings file is a reparse point.' }; 'directory' { 'Expected an editor-settings file, not a directory.' }
            'hash-race' { 'SIMULATED_DISAPPEARED_AFTER_ATTRIBUTES' }
        }
        $expectedStage = switch ($Mode) { 'broken-link' { 'editor-reparse-check' }; 'directory' { 'editor-file-kind-check' }; 'hash-race' { 'editor-hash' }; default { 'editor-attributes' } }
        $pass = $pass -and @($snapshot | Where-Object {
            $_.error.details -notlike ('*' + $expectedDetails + '*') -or $_.error.stage -cne $expectedStage -or
            [string]::IsNullOrEmpty($_.error.type) -or $_.error.redaction -cne 'PASS'
        }).Count -eq 0
    }
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
    if ($Mode -eq 'provider-failed') {
        $pass = $pass -and $record.Contains('editorSettingsFailure') -and
            $record.editorSettingsFailure.details -like '*SIMULATED_METADATA_PROVIDER_FAILURE*' -and
            $record.editorSettingsFailure.stage -ceq 'editor-after-observation-provider' -and
            -not [string]::IsNullOrEmpty($record.editorSettingsFailure.type)
    }
    else { $pass = $pass -and @($record.editorSettingsAfterFailure).Count -eq 6 }
    if ($Mode -in @('changed', 'unavailable')) {
        $expectedDetail = if ($Mode -eq 'changed') { 'existence or hash changed' } else { 'unavailable or has invalid' }
        $pass = $pass -and $record.Contains('editorSettingsFailure') -and
            $record.editorSettingsFailure.details -like ('*' + $expectedDetail + '*') -and
            $record.editorSettingsFailure.stage -ceq 'editor-after-assertion'
    }
    if ($Mode -eq 'unchanged') { $pass = $pass -and -not $record.Contains('editorSettingsFailure') }
    $checks.Add(@{ name = $Name; kind = 'editor-settings-post-failure'; simulation = $true; status = $(if ($pass) { 'PASS' } else { 'FAIL' })
        primaryFailurePreserved = ($record.failure -ceq 'SIMULATED_PRIMARY_BUILD_FAILURE'); retained = $record })
    Write-Output ("{0}: {1}" -f $Name, $(if ($pass) { 'PASS' } else { 'FAIL' }))
}
Check-EditorFailureEvidence 'editor-primary-failure-unchanged-after' 'unchanged'
Check-EditorFailureEvidence 'editor-primary-failure-retains-changed-after' 'changed'
Check-EditorFailureEvidence 'editor-primary-failure-retains-unavailable-after' 'unavailable'
Check-EditorFailureEvidence 'editor-primary-failure-provider-also-fails' 'provider-failed'

function Check-UBTInspection([string] $Name, [string] $Mode, [string] $ExpectedFailure = '') {
    function Get-PreservationFileAttributes([string] $Path) {
        switch ($Mode) {
            'missing-file' { throw [IO.FileNotFoundException]::new('SIMULATED_UBT_NOT_FOUND') }
            'missing-parent' { throw [IO.DirectoryNotFoundException]::new('SIMULATED_UBT_PARENT_NOT_FOUND') }
            'denied' { throw [UnauthorizedAccessException]::new('SIMULATED_UBT_ACCESS_DENIED') }
            'io-error' { throw [IO.IOException]::new('SIMULATED_UBT_IO_ERROR') }
            'broken-link' { return [IO.FileAttributes]::ReparsePoint }
            'directory' { return [IO.FileAttributes]::Directory }
            default { return [IO.FileAttributes]::Normal }
        }
    }
    function Assert-NoReparsePoint([string] $Path) { }
    function Get-Hash([string] $Path) {
        if ($Mode -eq 'hash-race') { throw [IO.FileNotFoundException]::new('SIMULATED_UBT_HASH_RACE') }
        return 'a' * 64
    }
    $failure = $null; $observations = @()
    try { $observations = @(Get-UBTSettings) } catch { $failure = Get-SafeFailureEvidence $_ 'ubt-synthetic-query' }
    $pass = if ($ExpectedFailure) { $null -ne $failure -and $failure.details -like ('*' + $ExpectedFailure + '*') -and $failure.redaction -ceq 'PASS' } else {
        $expectedExists = $Mode -eq 'present'
        $observations.Count -ge 2 -and @($observations | Where-Object { $_.exists -ne $expectedExists }).Count -eq 0
    }
    $checks.Add(@{ name = $Name; kind = 'ubt-settings-query'; simulation = $true; status = $(if ($pass) { 'PASS' } else { 'FAIL' })
        observedFailure = $failure; observations = $observations })
    Write-Output ("{0}: {1}" -f $Name, $(if ($pass) { 'PASS' } else { 'FAIL' }))
}
Check-UBTInspection 'ubt-present-file' 'present'
Check-UBTInspection 'ubt-explicit-missing-file' 'missing-file'
Check-UBTInspection 'ubt-explicit-missing-parent' 'missing-parent'
Check-UBTInspection 'ubt-denied-is-not-absence' 'denied' 'SIMULATED_UBT_ACCESS_DENIED'
Check-UBTInspection 'ubt-io-error-is-not-absence' 'io-error' 'SIMULATED_UBT_IO_ERROR'
Check-UBTInspection 'ubt-broken-link-rejected' 'broken-link' 'Global UBT settings file is a reparse point.'
Check-UBTInspection 'ubt-directory-rejected' 'directory' 'Global UBT settings path is a directory.'
Check-UBTInspection 'ubt-hash-race-is-not-absence' 'hash-race' 'SIMULATED_UBT_HASH_RACE'

function Check-DiagnosticRedaction {
    $marker = 'SIMULATED_' + 'PRIVATE_DIAGNOSTIC'
    $priorSecrets = $script:secretValues
    $script:secretValues = @($marker)
    try {
        try { throw [IO.IOException]::new('safe outer', [UnauthorizedAccessException]::new($marker)) }
        catch { $redacted = Get-SafeFailureEvidence $_ 'synthetic-diagnostic' }
        $editorSnapshot = @(New-SimulatedEditorState)
        function Get-EditorSettingsState { throw $marker }
        $record = [ordered]@{ failure = 'SIMULATED_PRIMARY'; editorSettingsBefore = $editorSnapshot }
        Save-EditorSettingsFailureEvidence $record
        $json = @{ direct = $redacted; provider = $record } | ConvertTo-Json -Depth 12 -Compress
        $pass = $redacted.redaction -ceq 'REJECTED_NOT_RETAINED' -and
            $record.editorSettingsFailure.redaction -ceq 'REJECTED_NOT_RETAINED' -and
            $record.failure -ceq 'SIMULATED_PRIMARY' -and -not $json.Contains($marker, [StringComparison]::Ordinal) -and
            $redacted.stage -ceq 'synthetic-diagnostic' -and -not [string]::IsNullOrEmpty($redacted.type)
        $checks.Add(@{ name = 'diagnostic-secret-details-and-causes-not-retained'; kind = 'failure-diagnostic-redaction'; simulation = $true
            status = $(if ($pass) { 'PASS' } else { 'FAIL' }); retained = @{ direct = $redacted; provider = $record } })
        Write-Output ("diagnostic-secret-details-and-causes-not-retained: {0}" -f $(if ($pass) { 'PASS' } else { 'FAIL' }))
    } finally { $script:secretValues = $priorSecrets }
}
Check-DiagnosticRedaction

function New-SimulatedReadTask([string] $Mode) {
    $task = [pscustomobject]@{ Mode = $Mode; IsCompleted = $Mode -ne 'timeout' }
    $task | Add-Member ScriptMethod GetAwaiter { return $this }
    $task | Add-Member ScriptMethod GetResult { if ($this.Mode -eq 'read') { throw 'SIMULATED_PRIMARY_READ_FAILURE' }; return $null }
    return $task
}

function New-SimulatedProcessReader([string] $Mode) {
    $reader = [pscustomobject]@{ Mode = $Mode }
    $reader | Add-Member ScriptMethod ReadLineAsync { return New-SimulatedReadTask $this.Mode }
    return $reader
}

function Check-ProcessCaller([string] $Name, [hashtable] $Configuration, [string] $ExpectedFailure = '', [string[]] $ExpectedSecondaryStages = @()) {
    $state = @{ Primary = 'read'; Exited = $false; KillFault = $false; WaitFault = $false; IdentityDisposeFault = $false
        HasExitedAlwaysFault = $false; HasExitedFinalFault = $false; ExitCodeFault = $false; StdoutDisposeFault = $false
        StderrDisposeFault = $false; HandleDisposeFault = $false; HasExitedCalls = 0; KillCalls = 0; WaitMilliseconds = $null
        IdentityDisposeCalls = 0; StdoutDisposeCalls = 0; StderrDisposeCalls = 0; HandleDisposeCalls = 0
        IdFaultMode = 'none'; TimeFaultMode = 'none'; IdReads = 0; TimeReads = 0; IdentityMismatch = $false
        ExpectRefusal = $false; ExpectedRecovery = $null
        FactoryFault = ''; ConfigureFault = ''; StartCalls = 0
        CleanupDetails = 'SIMULATED_CLEANUP_KILL_FAILURE'; ExpectRedactedCleanup = $false
        StartTime = [datetime]::new(2026, 1, 1, 0, 0, 0, [DateTimeKind]::Utc) }
    foreach ($entry in $Configuration.GetEnumerator()) { $state[$entry.Key] = $entry.Value }
    $state.Exited = $state.Primary -eq 'none'
    $fakeProcess = [pscustomobject]@{ State = $state; Id = 424242; StartTime = $state.StartTime
        StandardOutput = New-SimulatedProcessReader $state.Primary; StandardError = New-SimulatedProcessReader 'none' }
    $fakeProcess | Add-Member ScriptMethod get_Id {
        $this.State.IdReads++
        if ($this.State.IdFaultMode -eq 'permanent' -or ($this.State.IdFaultMode -eq 'transient' -and $this.State.IdReads -eq 1)) { throw 'SIMULATED_START_ID_FAILURE' }
        if ($this.State.IdFaultMode -eq 'changed-on-recovery' -and $this.State.IdReads -ge 2) { return 424243 }
        return 424242
    }
    $fakeProcess | Add-Member ScriptMethod get_StartTime {
        $this.State.TimeReads++
        if ($this.State.TimeFaultMode -eq 'permanent' -or ($this.State.TimeFaultMode -eq 'transient' -and $this.State.TimeReads -eq 1)) { throw 'SIMULATED_START_TIME_FAILURE' }
        return $this.State.StartTime
    }
    $fakeProcess | Add-Member ScriptMethod get_HasExited {
        $this.State.HasExitedCalls++
        if ($this.State.HasExitedAlwaysFault -or ($this.State.HasExitedFinalFault -and $this.State.HasExitedCalls -ge 3)) { throw 'SIMULATED_HAS_EXITED_FAILURE' }
        return $this.State.Exited
    }
    $fakeProcess | Add-Member ScriptMethod get_ExitCode { if ($this.State.ExitCodeFault) { throw 'SIMULATED_EXIT_CODE_FAILURE' }; return 0 }
    $fakeProcess | Add-Member ScriptMethod Start { $this.State.StartCalls++; return $true }
    $fakeProcess | Add-Member ScriptMethod Kill {
        param($Tree)
        $this.State.KillCalls++
        if ($this.State.KillFault) { throw $this.State.CleanupDetails }
        if (-not $this.State.WaitFault) { $this.State.Exited = $true }
    }
    $fakeProcess | Add-Member ScriptMethod WaitForExit {
        param($Milliseconds)
        if ($null -eq $Milliseconds) { return }
        $this.State.WaitMilliseconds = $Milliseconds
        if ($this.State.WaitFault) { throw 'SIMULATED_CLEANUP_WAIT_FAILURE' }
        $this.State.Exited = $true
        return $true
    }
    $fakeProcess | Add-Member ScriptMethod Dispose { $this.State.HandleDisposeCalls++; if ($this.State.HandleDisposeFault) { throw 'SIMULATED_HANDLE_DISPOSE_FAILURE' } }
    $fakeIdentity = [pscustomobject]@{ State = $state; StartTime = $state.StartTime }
    $fakeIdentity | Add-Member ScriptMethod get_StartTime { if ($this.State.IdentityMismatch) { return $this.State.StartTime.AddSeconds(1) }; return $this.State.StartTime }
    $fakeIdentity | Add-Member ScriptMethod Dispose { $this.State.IdentityDisposeCalls++; if ($this.State.IdentityDisposeFault) { throw 'SIMULATED_IDENTITY_DISPOSE_FAILURE' } }
    function New-OwnedProcessHandle($StartInfo) { return $fakeProcess }
    function Get-OwnedProcessIdentity([int] $ProcessId) { return $fakeIdentity }
    function New-OwnedLogWriter([string] $Path) {
        $lane = if ($Path.EndsWith('.stdout.log')) { 'Stdout' } else { 'Stderr' }
        if ($state.FactoryFault -ceq $lane) { throw ('SIMULATED_' + $lane.ToUpperInvariant() + '_FACTORY_FAILURE') }
        $writer = [pscustomobject]@{ State = $state; Lane = $lane }
        $writer | Add-Member ScriptMethod set_AutoFlush { param($Enabled); if ($this.State.ConfigureFault -ceq $this.Lane) { throw ('SIMULATED_' + $this.Lane.ToUpperInvariant() + '_CONFIGURE_FAILURE') } }
        $writer | Add-Member ScriptMethod WriteLine { param($Line) }
        $writer | Add-Member ScriptMethod Dispose {
            $this.State[$this.Lane + 'DisposeCalls']++
            if ($this.State[$this.Lane + 'DisposeFault']) { throw ('SIMULATED_' + $this.Lane.ToUpperInvariant() + '_DISPOSE_FAILURE') }
        }
        return $writer
    }
    $script:runRoot = Join-Path $OutputRoot ('SIMULATED-caller-' + $Name)
    $script:phaseRoot = Join-Path $runRoot 'fake-owned-logs'
    $null = [IO.Directory]::CreateDirectory($phaseRoot)
    $script:phaseResult = @{ processes = [Collections.Generic.List[object]]::new(); toolchain = @{ engineVersion = @{ MajorVersion = 5; MinorVersion = 8 } } }
    $editorSnapshot = @(New-SimulatedEditorState)
    function Get-EditorSettingsState { return $editorSnapshot }
    $phaseResult.editorSettingsBefore = $editorSnapshot
    $maximum = if ($state.Primary -eq 'timeout') { 0 } else { 1000 }
    $failure = $null
    try { $null = Invoke-OwnedProcess $Name $guardWrapperPath @('SIMULATED_NO_EXECUTION') $runRoot @{} $maximum }
    catch { $failure = $_.Exception.Message; $phaseResult.failure = $failure; Save-EditorSettingsFailureEvidence $phaseResult }
    $record = $phaseResult.processes[0]
    $pass = if ($ExpectedFailure) { $null -ne $failure -and $failure -like ('*' + $ExpectedFailure + '*') } else { $null -eq $failure }
    $stdoutCount = if ($state.FactoryFault -ceq 'Stdout') { 0 } else { 1 }
    $stderrCount = if ($state.FactoryFault -or $state.ConfigureFault -ceq 'Stdout') { 0 } else { 1 }
    $pass = $pass -and $phaseResult.processes.Count -eq 1 -and $null -ne $record.endedUtc -and
        $state.StdoutDisposeCalls -eq $stdoutCount -and $state.StderrDisposeCalls -eq $stderrCount -and $state.HandleDisposeCalls -eq 1
    foreach ($stage in $ExpectedSecondaryStages) { $pass = $pass -and @($record.secondaryErrors | Where-Object { $_.stage -ceq $stage }).Count -ge 1 }
    if ($ExpectedFailure) {
        $pass = $pass -and $record.primaryFailure.details -like ('*' + $ExpectedFailure + '*') -and
            $phaseResult.failure -ceq $failure -and @($phaseResult.editorSettingsAfterFailure).Count -eq 6
    }
    if ($state.WaitFault) { $pass = $pass -and $state.WaitMilliseconds -eq 10000 }
    if ($state.FactoryFault -or $state.ConfigureFault) {
        $pass = $pass -and $state.StartCalls -eq 0 -and -not $record.startConfirmed -and
            $null -eq $record.exitConfirmed -and $null -eq $record.exitedUtc -and $record.cleanupStatus -ceq 'NOT_STARTED'
    }
    elseif ($state.Exited) { $pass = $pass -and $record.exitConfirmed -eq $true -and $null -ne $record.exitedUtc }
    else {
        $expectedCleanup = if ($state.ExpectRefusal) { 'REFUSED_UNVERIFIED_IDENTITY' } else { 'EXIT_UNCONFIRMED' }
        $pass = $pass -and $null -eq $record.exitConfirmed -and $null -eq $record.exitedUtc -and $record.cleanupStatus -ceq $expectedCleanup
    }
    if ($state.ExpectRefusal) { $pass = $pass -and $record.terminationRefused -and $state.KillCalls -eq 0 -and -not [string]::IsNullOrEmpty($record.terminationRefusalReason) }
    if ($null -ne $state.ExpectedRecovery) {
        $pass = $pass -and $record.identityRecoveryAttempted -and $record.identityRecoveredForCleanup -eq $state.ExpectedRecovery
        if ($state.ExpectedRecovery) { $pass = $pass -and $record.startIdentityComplete -and $state.KillCalls -eq 1 -and $state.WaitMilliseconds -eq 10000 }
    }
    if ($state.Primary -eq 'none' -and -not $state.ExitCodeFault) { $pass = $pass -and $record.exitCode -eq 0 }
    if ($state.ExpectRedactedCleanup) {
        $pass = $pass -and @($record.secondaryErrors | Where-Object { $_.redaction -ceq 'REJECTED_NOT_RETAINED' }).Count -ge 1 -and
            -not (($record | ConvertTo-Json -Depth 16 -Compress).Contains($state.CleanupDetails, [StringComparison]::Ordinal))
    }
    $checks.Add(@{ name = $Name; kind = 'owned-process-caller'; simulation = $true; status = $(if ($pass) { 'PASS' } else { 'FAIL' })
        observedFailure = $failure; expectedFailure = $ExpectedFailure; retainedProcess = $record
        finalizationCalls = @{ stdout = $state.StdoutDisposeCalls; stderr = $state.StderrDisposeCalls; process = $state.HandleDisposeCalls } })
    Write-Output ("{0}: {1}" -f $Name, $(if ($pass) { 'PASS' } else { 'FAIL' }))
}
Check-ProcessCaller 'caller-timeout-retains-all-cleanup-faults' @{ Primary = 'timeout'; KillFault = $true; HasExitedFinalFault = $true
    IdentityDisposeFault = $true; StdoutDisposeFault = $true; StderrDisposeFault = $true; HandleDisposeFault = $true } 'Process deadline exceeded' @(
    'cleanup-stop-process', 'cleanup-identity-handle-dispose', 'finalize-exit-inspection', 'finalize-stdout-log', 'finalize-stderr-log', 'finalize-process-handle')
Check-ProcessCaller 'caller-read-failure-keeps-bounded-wait-error' @{ WaitFault = $true; IdentityDisposeFault = $true } 'SIMULATED_PRIMARY_READ_FAILURE' @('cleanup-stop-process', 'cleanup-identity-handle-dispose')
Check-ProcessCaller 'caller-read-failure-keeps-exit-code-error' @{ ExitCodeFault = $true } 'SIMULATED_PRIMARY_READ_FAILURE' @('finalize-exit-code')
Check-ProcessCaller 'caller-successful-exit-stdout-cleanup-fails' @{ Primary = 'none'; StdoutDisposeFault = $true } 'SIMULATED_STDOUT_DISPOSE_FAILURE' @('finalize-stdout-log')
Check-ProcessCaller 'caller-successful-exit-stderr-cleanup-fails' @{ Primary = 'none'; StderrDisposeFault = $true } 'SIMULATED_STDERR_DISPOSE_FAILURE' @('finalize-stderr-log')
Check-ProcessCaller 'caller-successful-exit-handle-cleanup-fails' @{ Primary = 'none'; HandleDisposeFault = $true } 'SIMULATED_HANDLE_DISPOSE_FAILURE' @('finalize-process-handle')
Check-ProcessCaller 'caller-exit-code-unavailable-is-failure' @{ Primary = 'none'; ExitCodeFault = $true } 'SIMULATED_EXIT_CODE_FAILURE' @('finalize-exit-code')
Check-ProcessCaller 'caller-has-exited-unavailable-keeps-primary' @{ HasExitedAlwaysFault = $true } 'SIMULATED_HAS_EXITED_FAILURE' @('cleanup-stop-process', 'finalize-exit-inspection')
Check-ProcessCaller 'caller-success-control' @{ Primary = 'none' }
Check-ProcessCaller 'caller-stdout-factory-fails-before-start' @{ FactoryFault = 'Stdout' } 'SIMULATED_STDOUT_FACTORY_FAILURE'
Check-ProcessCaller 'caller-stderr-factory-fails-before-start' @{ FactoryFault = 'Stderr' } 'SIMULATED_STDERR_FACTORY_FAILURE'
Check-ProcessCaller 'caller-stdout-configuration-finalizes-writer' @{ ConfigureFault = 'Stdout' } 'SIMULATED_STDOUT_CONFIGURE_FAILURE'
Check-ProcessCaller 'caller-stderr-configuration-finalizes-writers' @{ ConfigureFault = 'Stderr' } 'SIMULATED_STDERR_CONFIGURE_FAILURE'
Check-ProcessCaller 'caller-start-id-transient-recovers-cleanup' @{ IdFaultMode = 'transient'; ExpectedRecovery = $true } 'SIMULATED_START_ID_FAILURE'
Check-ProcessCaller 'caller-start-time-transient-recovers-cleanup' @{ TimeFaultMode = 'transient'; ExpectedRecovery = $true } 'SIMULATED_START_TIME_FAILURE'
Check-ProcessCaller 'caller-start-id-unavailable-refuses-unverified-kill' @{ IdFaultMode = 'permanent'; ExpectedRecovery = $false; ExpectRefusal = $true } 'SIMULATED_START_ID_FAILURE' @('cleanup-recover-start-identity')
Check-ProcessCaller 'caller-start-time-unavailable-refuses-unverified-kill' @{ TimeFaultMode = 'permanent'; ExpectedRecovery = $false; ExpectRefusal = $true } 'SIMULATED_START_TIME_FAILURE' @('cleanup-recover-start-identity')
Check-ProcessCaller 'caller-start-recovery-pid-substitution-refused' @{ IdFaultMode = 'changed-on-recovery'; TimeFaultMode = 'transient'; ExpectedRecovery = $false; ExpectRefusal = $true } 'SIMULATED_START_TIME_FAILURE' @('cleanup-recover-start-identity')
Check-ProcessCaller 'caller-cleanup-start-time-mismatch-refused' @{ IdentityMismatch = $true; ExpectRefusal = $true } 'SIMULATED_PRIMARY_READ_FAILURE' @('cleanup-stop-process')
function Check-CallerDiagnosticRedaction {
    $marker = 'SIMULATED_' + 'PRIVATE_CLEANUP'
    $priorSecrets = $script:secretValues; $script:secretValues = @($marker)
    try {
        Check-ProcessCaller 'caller-secondary-error-details-redacted' @{ KillFault = $true; CleanupDetails = $marker; ExpectRedactedCleanup = $true } `
            'SIMULATED_PRIMARY_READ_FAILURE' @('cleanup-stop-process')
    } finally { $script:secretValues = $priorSecrets }
}
Check-CallerDiagnosticRedaction

function Get-TestDecodedStrings($Value) {
    if ($Value -is [string]) { $Value }
    elseif ($Value -is [Collections.IDictionary]) { foreach ($entry in $Value.GetEnumerator()) { [string]$entry.Key; Get-TestDecodedStrings $entry.Value } }
    elseif ($Value -is [Collections.IList]) { foreach ($member in $Value) { Get-TestDecodedStrings $member } }
}

function Check-EscapedSecret([string] $Name, [string] $Character) {
    $marker = 'SIMULATED_RAW_' + $Character + 'PRIVATE_VALUE'
    $priorSecrets = $script:secretValues; $script:secretValues = @($marker)
    $directory = Join-Path $OutputRoot ('escaped-secret-' + $Name); $null = [IO.Directory]::CreateDirectory($directory)
    try {
        try { throw [IO.IOException]::new('safe outer context', [UnauthorizedAccessException]::new($marker)) }
        catch { $diagnostic = Get-SafeFailureEvidence $_ 'synthetic-raw-secret' }
        try { throw 'safe details' } catch { $stageDiagnostic = Get-SafeFailureEvidence $_ $marker }
        $decoded = (@{ direct = $diagnostic; stage = $stageDiagnostic } | ConvertTo-Json -Depth 12) | ConvertFrom-Json -AsHashtable
        $leaked = @((Get-TestDecodedStrings $decoded) | Where-Object { $_.Contains($marker, [StringComparison]::Ordinal) }).Count
        $rejected = 0
        $value = @{ nested = @('safe', @{ details = $marker }) }
        $keyValue = @{}; $keyValue[$marker] = 'safe'
        foreach ($item in @(@{ name = 'value'; value = $value }, @{ name = 'key'; value = $keyValue })) {
            try { Write-NewJson (Join-Path $directory ($item.name + '.json')) $item.value }
            catch { if ($_.Exception.Message -like 'Credential scan*') { $rejected++ } }
        }
        # This is intentionally unsafe synthetic INPUT, never an exported result.
        $inputPath = Join-Path $directory 'SIMULATED-input.json'
        [IO.File]::WriteAllText($inputPath, ($value | ConvertTo-Json -Depth 8), $utf8)
        $readRejected = $false
        try { $null = Read-Json $inputPath } catch { $readRejected = $_.Exception.Message -like 'Credential scan*' }
        $pass = $diagnostic.redaction -ceq 'REJECTED_NOT_RETAINED' -and $stageDiagnostic.redaction -ceq 'REJECTED_NOT_RETAINED' -and
            $leaked -eq 0 -and $rejected -eq 2 -and $readRejected -and
            -not (Test-Path -LiteralPath (Join-Path $directory 'value.json')) -and -not (Test-Path -LiteralPath (Join-Path $directory 'key.json'))
        $checks.Add(@{ name = ('raw-secret-' + $Name); kind = 'decoded-secret-validation'; simulation = $true
            status = $(if ($pass) { 'PASS' } else { 'FAIL' }); decodedLeakCount = $leaked; rejectedExports = $rejected; decodedReadRejected = $readRejected })
        Write-Output ("raw-secret-{0}: {1}" -f $Name, $(if ($pass) { 'PASS' } else { 'FAIL' }))
    } finally { $script:secretValues = $priorSecrets }
}
Check-EscapedSecret 'backslash' '\'
Check-EscapedSecret 'quote' '"'
Check-EscapedSecret 'tab' "`t"
Check-EscapedSecret 'newline' "`n"
Check-EscapedSecret 'carriage-return' "`r"
Check-EscapedSecret 'nul' ([string][char]0)

function Check-StructuredRejection([string] $Name, $Value, [string] $ExpectedFailure) {
    $failure = $null
    try { Assert-SafeStructuredValue $Value } catch { $failure = $_.Exception.Message }
    $pass = $null -ne $failure -and $failure -like ('*' + $ExpectedFailure + '*')
    $checks.Add(@{ name = $Name; kind = 'structured-evidence-bounds'; simulation = $true; observedFailure = $failure; status = $(if ($pass) { 'PASS' } else { 'FAIL' }) })
    Write-Output ("{0}: {1}" -f $Name, $(if ($pass) { 'PASS' } else { 'FAIL' }))
}
$cycle = @{}; $cycle.loop = $cycle
Check-StructuredRejection 'structured-cycle-stops-at-depth-bound' $cycle 'depth or node bound'
Check-StructuredRejection 'structured-nonfinite-rejected' ([double]::NaN) 'non-finite number'
Check-StructuredRejection 'structured-unsupported-object-rejected' ([object]::new()) 'unsupported value type'
$script:syntheticGetterInvoked = $false
$unsafeProperty = [pscustomobject]@{}
$unsafeProperty | Add-Member ScriptProperty unsafe { $script:syntheticGetterInvoked = $true; throw 'SIMULATED_UNSAFE_GETTER' }
Check-StructuredRejection 'structured-custom-getter-never-invoked' $unsafeProperty 'custom property getters'
if ($script:syntheticGetterInvoked) { throw 'Synthetic custom property was incorrectly invoked.' }

function Check-AtomicJsonExport([string] $Name, [string] $Mode) {
    $directory = Join-Path $OutputRoot ('atomic-json-' + $Name); $null = [IO.Directory]::CreateDirectory($directory)
    $target = Join-Path $directory 'result.json'
    function New-JsonOutputStream([string] $Path) {
        if ($Mode -eq 'create') { throw [IO.IOException]::new('SIMULATED_JSON_CREATE_FAILURE') }
        $inner = [IO.File]::Open($Path, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::Read)
        $stream = [pscustomobject]@{ Inner = $inner; Mode = $Mode; Target = $target }
        $stream | Add-Member ScriptMethod Write {
            param([byte[]] $Bytes, [int] $Offset, [int] $Count)
            if ($this.Mode -in @('write', 'write-and-dispose')) { $this.Inner.Write($Bytes, $Offset, [Math]::Min(5, $Count)); throw 'SIMULATED_JSON_WRITE_FAILURE' }
            $this.Inner.Write($Bytes, $Offset, $Count)
        }
        $stream | Add-Member ScriptMethod Flush { if ($this.Mode -eq 'flush') { throw 'SIMULATED_JSON_FLUSH_FAILURE' }; $this.Inner.Flush() }
        $stream | Add-Member ScriptMethod Dispose {
            $this.Inner.Dispose()
            if ($this.Mode -in @('dispose', 'write-and-dispose')) { throw 'SIMULATED_JSON_DISPOSE_FAILURE' }
            if ($this.Mode -eq 'collision') { [IO.File]::WriteAllText($this.Target, 'SIMULATED_IMMUTABLE_EXISTING_RESULT') }
        }
        return $stream
    }
    $errors = [Collections.Generic.List[object]]::new(); $failure = $null
    try { Write-NewJson $target @{ status = 'SIMULATED_PASS'; safe = "path\value`nquoted`"value" } $errors }
    catch { $failure = Get-SafeFailureEvidence $_ 'synthetic-json-export' }
    $partials = @(Get-ChildItem -LiteralPath $directory -File -Filter '*.partial-*')
    $pass = if ($Mode -eq 'none') {
        $null -eq $failure -and (Read-Json $target).status -ceq 'SIMULATED_PASS' -and $partials.Count -eq 0
    } elseif ($Mode -eq 'collision') {
        $null -ne $failure -and [IO.File]::ReadAllText($target) -ceq 'SIMULATED_IMMUTABLE_EXISTING_RESULT' -and $partials.Count -eq 1
    } else { $null -ne $failure -and -not (Test-Path -LiteralPath $target) -and $partials.Count -eq $(if ($Mode -eq 'create') { 0 } else { 1 }) }
    if ($Mode -eq 'write-and-dispose') { $pass = $pass -and $failure.details -like '*SIMULATED_JSON_WRITE_FAILURE*' -and $errors.Count -eq 1 -and $errors[0].details -like '*SIMULATED_JSON_DISPOSE_FAILURE*' }
    $checks.Add(@{ name = ('atomic-json-' + $Name); kind = 'atomic-json-publication'; simulation = $true; status = $(if ($pass) { 'PASS' } else { 'FAIL' })
        finalExists = (Test-Path -LiteralPath $target); partialCount = $partials.Count; observedFailure = $failure; secondaryErrors = @($errors) })
    Write-Output ("atomic-json-{0}: {1}" -f $Name, $(if ($pass) { 'PASS' } else { 'FAIL' }))
}
Check-AtomicJsonExport 'success' 'none'
Check-AtomicJsonExport 'create-failure' 'create'
Check-AtomicJsonExport 'partial-write-failure' 'write'
Check-AtomicJsonExport 'flush-failure' 'flush'
Check-AtomicJsonExport 'close-failure-full-bytes-unpublished' 'dispose'
Check-AtomicJsonExport 'write-primary-close-secondary' 'write-and-dispose'
Check-AtomicJsonExport 'existing-result-never-overwritten' 'collision'

# Inspect every real writer call, then execute only the original initializer and
# two original export commands against synthetic paths and fault-injected streams.
# This exercises the dispatcher callers' conventions without invoking a phase.
$productionJsonCalls = @($ast.FindAll({ param($node)
    $node -is [Management.Automation.Language.CommandAst] -and $node.GetCommandName() -ceq 'Write-NewJson'
}, $true))
$phaseInitializers = @($ast.FindAll({ param($node)
    $node -is [Management.Automation.Language.AssignmentStatementAst] -and $node.Left.Extent.Text -ceq '$phaseResult' -and
        $node.Right.Extent.Text.StartsWith('[ordered]@{', [StringComparison]::Ordinal)
}, $true))
$explicitCollectors = $productionJsonCalls.Count -ge 5 -and @($productionJsonCalls | Where-Object { $_.CommandElements.Count -ne 4 }).Count -eq 0
$checks.Add(@{ name = 'json-production-callers-explicit-secondary-collectors'; kind = 'production-caller-convention'; simulation = $true
    status = $(if ($explicitCollectors) { 'PASS' } else { 'FAIL' }); productionCallerCount = $productionJsonCalls.Count })
Write-Output ('json-production-callers-explicit-secondary-collectors: ' + $(if ($explicitCollectors) { 'PASS' } else { 'FAIL' }))
if ($phaseInitializers.Count -ne 1) { throw 'Expected one original phase result initializer for the synthetic caller controls.' }

function Check-PhaseJsonCallerFault([string] $Name, [string] $Mode) {
    $directory = Join-Path $OutputRoot ('SIMULATED-json-caller-' + $Name + '-' + $Mode)
    $null = [IO.Directory]::CreateDirectory($directory)
    $runRoot = $directory; $phaseRoot = $directory; $RunId = 'SIMULATED-JSON-CALLER'; $Phase = 'SIMULATED_ONLY'
    Invoke-Expression $phaseInitializers[0].Extent.Text
    $provenancePath = Join-Path $directory 'SIMULATED-runtime-provenance.json'
    $provenance = @{ schemaVersion = 1; status = 'SIMULATED_RUNTIME'; source = 'NO_CORE_OR_RUNTIME_EXECUTION' }
    $target = if ($Name -eq 'started') { Join-Path $directory 'started.json' } else { $provenancePath }
    $field = if ($Name -eq 'started') { 'startedJsonExportErrors' } else { 'runtimeProvenanceExportErrors' }
    $command = @($productionJsonCalls | Where-Object {
        if ($Name -eq 'started') { $_.CommandElements[1].Extent.Text -like '*started.json*' }
        else { $_.CommandElements[1].Extent.Text -ceq '$provenancePath' }
    })
    if ($command.Count -ne 1) { throw 'Expected exactly one original export command for the synthetic caller control.' }
    function New-JsonOutputStream([string] $Path) {
        $inner = [IO.File]::Open($Path, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::Read)
        if (-not $Path.StartsWith(($target + '.partial-'), [StringComparison]::OrdinalIgnoreCase)) { return $inner }
        $stream = [pscustomobject]@{ Inner = $inner; Mode = $Mode }
        $stream | Add-Member ScriptMethod Write {
            param([byte[]] $Bytes, [int] $Offset, [int] $Count)
            if ($this.Mode -eq 'write') { $this.Inner.Write($Bytes, $Offset, [Math]::Min(5, $Count)); throw 'SIMULATED_CALLER_WRITE_FAILURE' }
            $this.Inner.Write($Bytes, $Offset, $Count)
        }
        $stream | Add-Member ScriptMethod Flush { throw 'SIMULATED_CALLER_FLUSH_FAILURE' }
        $stream | Add-Member ScriptMethod Dispose { $this.Inner.Dispose(); throw 'SIMULATED_CALLER_CLOSE_FAILURE' }
        return $stream
    }
    $primary = $null
    try { Invoke-Expression $command[0].Extent.Text.Replace('$PSCommandPath', '$guardWrapperPath') }
    catch { $primary = Get-SafeFailureEvidence $_ 'synthetic-original-export-caller' }
    $expected = if ($Mode -eq 'write') { 'SIMULATED_CALLER_WRITE_FAILURE' } else { 'SIMULATED_CALLER_FLUSH_FAILURE' }
    $collector = $phaseResult[$field]
    $outcome = Complete-PhaseFinalization $phaseResult $primary.details $null $null $directory
    $retained = Read-Json (Join-Path $directory 'result.json')
    $partials = @(Get-ChildItem -LiteralPath $directory -File -Filter (([IO.Path]::GetFileName($target)) + '.partial-*'))
    $pass = $primary.details -like ('*' + $expected + '*') -and $outcome.failure -ceq $primary.details -and
        $retained.status -ceq 'FAIL' -and $retained.failure -ceq $primary.details -and
        $collector.Count -eq 1 -and $collector[0].stage -ceq 'json-stream-dispose' -and
        $collector[0].details -like '*SIMULATED_CALLER_CLOSE_FAILURE*' -and $retained[$field].Count -eq 1 -and
        $retained[$field][0].details -like '*SIMULATED_CALLER_CLOSE_FAILURE*' -and
        -not (Test-Path -LiteralPath $target) -and $partials.Count -eq 1
    $checks.Add(@{ name = ('json-original-' + $Name + '-' + $Mode + '-and-close'); kind = 'original-production-export-caller'; simulation = $true
        status = $(if ($pass) { 'PASS' } else { 'FAIL' }); primaryFailure = $primary; retainedSecondaryErrors = @($retained[$field])
        unpublishedPartialCount = $partials.Count; publishedStatus = $retained.status })
    Write-Output ("json-original-{0}-{1}-and-close: {2}" -f $Name, $Mode, $(if ($pass) { 'PASS' } else { 'FAIL' }))
}
Check-PhaseJsonCallerFault 'started' 'write'
Check-PhaseJsonCallerFault 'started' 'flush'
Check-PhaseJsonCallerFault 'runtime-provenance' 'write'
Check-PhaseJsonCallerFault 'runtime-provenance' 'flush'

function Check-StructuredPositive([string] $Name, $Value) {
    $directory = Join-Path $OutputRoot ('structured-positive-' + $Name); $null = [IO.Directory]::CreateDirectory($directory)
    $path = Join-Path $directory 'result.json'; $failure = $null; $roundTrip = $false
    try {
        Write-NewJson $path $Value
        $decoded = Read-Json $path
        $expected = (ConvertTo-Json -InputObject $Value -Depth 80 -Compress) | ConvertFrom-Json -Depth 80 -AsHashtable -NoEnumerate
        $roundTrip = (ConvertTo-Json -InputObject $expected -Depth 80 -Compress) -ceq (ConvertTo-Json -InputObject $decoded -Depth 80 -Compress)
    } catch { $failure = Get-SafeFailureEvidence $_ 'synthetic-positive-export' }
    $pass = $null -eq $failure -and $roundTrip
    $checks.Add(@{ name = ('structured-positive-' + $Name); kind = 'production-shaped-export'; simulation = $true
        status = $(if ($pass) { 'PASS' } else { 'FAIL' }); decodedRoundTrip = $roundTrip; observedFailure = $failure })
    Write-Output ("structured-positive-{0}: {1}" -f $Name, $(if ($pass) { 'PASS' } else { 'FAIL' }))
}
$syntheticList = [Collections.Generic.List[object]]::new()
$syntheticList.Add(@{ label = 'SIMULATED_PROCESS'; pid = 1; startedUtc = '2026-10-17T00:00:00.0000000Z'; exitCode = 0; exitConfirmed = $true; cleanupErrors = @() })
$syntheticDictionary = [Collections.Generic.Dictionary[string, object]]::new(); $syntheticDictionary.Add('safe', @('one', 'two'))
$syntheticShape = [ordered]@{ status = 'SIMULATED_PASS'; processes = $syntheticList; nested = $syntheticDictionary
    before = @(@{ exists = $false; sha256 = $null }); object = [pscustomobject]@{ enabled = $true; count = 2; finite = 0.25 } }
Check-StructuredPositive 'ordered-list-dictionary-processes' $syntheticShape
Check-StructuredPositive 'single-root-list-preserved' @('SIMULATED_SINGLE_VALUE')
Check-StructuredPositive 'empty-root-list-preserved' @()
Check-StructuredPositive 'multiple-root-list-preserved' @('SIMULATED_FIRST_VALUE', 'SIMULATED_SECOND_VALUE')
if ($ActualPhaseResultPath) { Check-StructuredPositive 'preserved-phase-result-metadata' (Read-Json $ActualPhaseResultPath) }

function Check-PhaseFinalization([string] $Name, [hashtable] $Options) {
    $state = @{ RuntimeFault = $false; RunFault = $false; ExportFault = $false; ExportCloseFault = $false
        DiagnosticFileFault = $false; StderrFault = $false; Primary = $false; SecretEvidence = $false; RuntimeCalls = 0; RunCalls = 0 }
    foreach ($entry in $Options.GetEnumerator()) { $state[$entry.Key] = $entry.Value }
    $directory = Join-Path $OutputRoot ('SIMULATED-finalization-' + $Name); $null = [IO.Directory]::CreateDirectory($directory)
    $runtime = [pscustomobject]@{ State = $state; Name = 'Runtime' }; $run = [pscustomobject]@{ State = $state; Name = 'Run' }
    foreach ($handle in @($runtime, $run)) {
        $handle | Add-Member ScriptMethod Dispose { $this.State[$this.Name + 'Calls']++; if ($this.State[$this.Name + 'Fault']) { throw ('SIMULATED_' + $this.Name.ToUpperInvariant() + '_LOCK_FAILURE') } }
    }
    function New-JsonOutputStream([string] $Path) {
        $leaf = [IO.Path]::GetFileName($Path)
        if ($leaf.StartsWith('result.json.partial-', [StringComparison]::Ordinal)) {
            if ($state.RuntimeCalls -ne 1 -or $state.RunCalls -ne 1) { throw 'SIMULATED_PUBLICATION_BEFORE_LOCK_FINALIZERS' }
            if ($state.ExportFault) { throw [IO.IOException]::new('SIMULATED_PHASE_RESULT_EXPORT_FAILURE') }
        } elseif ($state.DiagnosticFileFault) { throw [IO.IOException]::new('SIMULATED_DIAGNOSTIC_FILE_FAILURE') }
        $inner = [IO.File]::Open($Path, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::Read)
        if (-not $state.ExportCloseFault -or -not $leaf.StartsWith('result.json.partial-', [StringComparison]::Ordinal)) { return $inner }
        $stream = [pscustomobject]@{ Inner = $inner }
        $stream | Add-Member ScriptMethod Write { param([byte[]] $Bytes, [int] $Offset, [int] $Count); $this.Inner.Write($Bytes, $Offset, $Count) }
        $stream | Add-Member ScriptMethod Flush { $this.Inner.Flush() }
        $stream | Add-Member ScriptMethod Dispose { $this.Inner.Dispose(); throw 'SIMULATED_PHASE_EXPORT_CLOSE_FAILURE' }
        return $stream
    }
    $channels = [Collections.Generic.List[object]]::new()
    function Write-PhaseFailureDiagnostic($Envelope, [string] $Channel = 'stderr') {
        Assert-SafeStructuredValue $Envelope
        if ($Channel -eq 'stderr' -and $state.StderrFault) { throw [IO.IOException]::new('SIMULATED_STDERR_FAILURE') }
        $decoded = ($Envelope | ConvertTo-Json -Depth 80) | ConvertFrom-Json -AsHashtable
        $channels.Add(@{ channel = $Channel; decoded = $decoded })
    }
    $result = [ordered]@{ status = 'SIMULATED_PASS'; completedUtc = $null
        processes = @(@{ identity = 'SIMULATED_OWNED_PROCESS'; exitConfirmed = $false })
        editorSettingsAfterFailure = @(@{ role = 'SIMULATED_SETTINGS'; inspection = 'UNAVAILABLE' }) }
    $primary = if ($state.Primary) { 'SIMULATED_PRIMARY_TIMEOUT' } else { $null }
    $priorSecrets = $script:secretValues
    $marker = 'SIMULATED_' + '\"' + "`t" + 'PRIVATE_PHASE_INPUT'
    if ($state.SecretEvidence) { $script:secretValues = @($marker); $result.unsafeInput = $marker }
    try {
        $outcome = Complete-PhaseFinalization $result $primary $runtime $run $directory
        $resultPath = Join-Path $directory 'result.json'; $resultExists = Test-Path -LiteralPath $resultPath
        $published = if ($resultExists) { Read-Json $resultPath } else { $null }
        $expectedFailure = $state.Primary -or $state.RuntimeFault -or $state.RunFault -or $state.ExportFault -or $state.ExportCloseFault -or $state.SecretEvidence
        $pass = $state.RuntimeCalls -eq 1 -and $state.RunCalls -eq 1
        if ($state.Primary) { $pass = $pass -and $outcome.failure -ceq 'SIMULATED_PRIMARY_TIMEOUT' }
        if ($expectedFailure) { $pass = $pass -and -not [string]::IsNullOrEmpty($outcome.failure) -and $result.status -ceq 'FAIL' }
        else { $pass = $pass -and $null -eq $outcome.failure -and $resultExists -and $published.status -ceq 'SIMULATED_PASS' -and $channels.Count -eq 0 }
        if ($state.ExportFault -or $state.ExportCloseFault -or $state.SecretEvidence) { $pass = $pass -and -not $resultExists }
        elseif ($expectedFailure) { $pass = $pass -and $resultExists -and $published.status -ceq 'FAIL' }
        foreach ($fault in @(@{ flag = 'RuntimeFault'; stage = 'phase-runtime-lock-dispose'; detail = 'SIMULATED_RUNTIME_LOCK_FAILURE' },
                @{ flag = 'RunFault'; stage = 'phase-run-lock-dispose'; detail = 'SIMULATED_RUN_LOCK_FAILURE' },
                @{ flag = 'ExportFault'; stage = 'phase-result-export'; detail = 'SIMULATED_PHASE_RESULT_EXPORT_FAILURE' },
                @{ flag = 'ExportCloseFault'; stage = 'phase-result-export'; detail = 'SIMULATED_PHASE_EXPORT_CLOSE_FAILURE' })) {
            if ($state[$fault.flag]) { $pass = $pass -and @($outcome.secondaryErrors | Where-Object { $_.stage -ceq $fault.stage -and $_.details -like ('*' + $fault.detail + '*') }).Count -ge 1 }
        }
        $decodedStrings = @($channels | ForEach-Object { Get-TestDecodedStrings $_.decoded })
        $leaked = @($decodedStrings | Where-Object { $_.Contains($marker, [StringComparison]::Ordinal) }).Count
        $pass = $pass -and $leaked -eq 0
        if ($outcome.secondaryErrors.Count) {
            $pass = $pass -and $channels.Count -ge 1 -and @($channels | Where-Object { $_.decoded.evidence.processes.Count -eq 1 -and $_.decoded.evidence.editorSettingsAfterFailure.Count -eq 1 }).Count -ge 1
        }
        if ($state.DiagnosticFileFault) { $pass = $pass -and @($outcome.secondaryErrors | Where-Object { $_.stage -ceq 'phase-diagnostic-file-export' }).Count -eq 1 }
        if ($state.StderrFault) { $pass = $pass -and @($outcome.secondaryErrors | Where-Object { $_.stage -ceq 'phase-diagnostic-stderr' }).Count -eq 1 -and @($channels | Where-Object { $_.channel -ceq 'stdout' }).Count -eq 1 }
        if ($state.StderrFault -and -not $state.DiagnosticFileFault) {
            $fileEvidence = Read-Json (Join-Path $directory 'finalization-channel-failure.json')
            $pass = $pass -and @($fileEvidence.secondaryErrors | Where-Object { $_.details -like '*SIMULATED_STDERR_FAILURE*' }).Count -eq 1
        }
        if ($state.ExportCloseFault) {
            $partial = @(Get-ChildItem -LiteralPath $directory -File -Filter 'result.json.partial-*')
            $pass = $pass -and $partial.Count -eq 1 -and (Read-Json $partial[0].FullName).status -ceq 'SIMULATED_PASS'
        }
        $checks.Add(@{ name = ('phase-finalization-' + $Name); kind = 'phase-finalization-caller'; simulation = $true; status = $(if ($pass) { 'PASS' } else { 'FAIL' })
            primaryPreserved = $(if ($state.Primary) { $outcome.failure -ceq $primary } else { $null }); resultPublished = $resultExists
            publishedStatus = $(if ($null -ne $published) { $published.status } else { $null }); secondaryErrors = @($outcome.secondaryErrors)
            survivingChannels = @($channels | ForEach-Object { $_.channel }); decodedLeakCount = $leaked; runtimeDisposeCalls = $state.RuntimeCalls; runDisposeCalls = $state.RunCalls })
        Write-Output ("phase-finalization-{0}: {1}" -f $Name, $(if ($pass) { 'PASS' } else { 'FAIL' }))
    } finally { $script:secretValues = $priorSecrets }
}
Check-PhaseFinalization 'success-published-after-both-locks' @{}
Check-PhaseFinalization 'primary-timeout-export-failure' @{ Primary = $true; ExportFault = $true }
Check-PhaseFinalization 'secondary-only-export-fails-phase' @{ ExportFault = $true }
Check-PhaseFinalization 'primary-and-both-locks-and-export-fail' @{ Primary = $true; RuntimeFault = $true; RunFault = $true; ExportFault = $true }
Check-PhaseFinalization 'secondary-runtime-lock-blocks-pass' @{ RuntimeFault = $true }
Check-PhaseFinalization 'diagnostic-file-fails-stderr-survives' @{ Primary = $true; ExportFault = $true; DiagnosticFileFault = $true }
Check-PhaseFinalization 'stderr-fails-new-file-and-stdout-survive' @{ Primary = $true; ExportFault = $true; StderrFault = $true }
Check-PhaseFinalization 'file-and-stderr-fail-stdout-survives' @{ Primary = $true; ExportFault = $true; DiagnosticFileFault = $true; StderrFault = $true }
Check-PhaseFinalization 'unsafe-field-omitted-safe-evidence-retained' @{ Primary = $true; SecretEvidence = $true }
Check-PhaseFinalization 'primary-only-failed-result-preserved' @{ Primary = $true }
Check-PhaseFinalization 'complete-pass-bytes-stay-partial-on-close-failure' @{ ExportCloseFault = $true }

$sourceAfter = @(foreach ($record in $sourceBefore) { @{ path = $record.path; sha256 = Get-Hash $record.path; unchanged = ((Get-Hash $record.path) -ceq $record.sha256) } })
$passed = @($checks | Where-Object { $_.status -eq 'PASS' }).Count
$invocation = @('pwsh', '-NoProfile', '-File', $PSCommandPath, '-OutputRoot', $OutputRoot)
if ($ActualUnitLogPath) { $invocation += @('-ActualUnitLogPath', $ActualUnitLogPath, '-ActualUnitCount', $ActualUnitCount) }
if ($ActualPhaseResultPath) { $invocation += @('-ActualPhaseResultPath', $ActualPhaseResultPath) }
$result = @{ purpose = 'Private simulated source-unit guard checks; no actual E01 phase, Core host, native build, install or global configuration mutation'
    invocation = $invocation; wrapperSha256 = Get-Hash $guardWrapperPath
    unitScriptSha256 = Get-Hash $PSCommandPath; sourceBefore = $sourceBefore; sourceAfter = $sourceAfter; checks = @($checks)
    executed = $checks.Count; passed = $passed; failed = $checks.Count - $passed; scriptPathBinding = 'Only automatic PSCommandPath adapted to the reviewed wrapper path in extracted function definitions' }
Write-PrivateJson (Join-Path $OutputRoot 'guard-unit-result.json') $result
Write-Output ("Guard checks: {0}/{1} PASS" -f $passed, $checks.Count)
if ($passed -ne $checks.Count -or @($sourceAfter | Where-Object { -not $_.unchanged }).Count -ne 0) { exit 1 }
