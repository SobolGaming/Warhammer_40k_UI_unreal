#requires -Version 7.2
<#
.SYNOPSIS
Runs one reviewed E01 Windows boundary-proof phase in packet-owned directories.
.DESCRIPTION
Preflight is read-only except for a fresh ignored run and its evidence. Runtime
preparation installs only the committed Core lock into the one owned environment.
Capture delegates to the reviewed Python harness; Native runs the nonempty pure
protocol suite. Audit gathers evidence and cannot replace independent reviews.
Each phase is single-use. Preserve failed runs and use a new RunId for another
attempt; this script never deletes, replaces or repairs an existing environment.
.EXAMPLE
./scripts/migration/Invoke-E01BoundaryProof.ps1 -Phase Preflight -RunId 20261016T230000Z-0123abcd
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Preflight', 'PrepareRuntime', 'Capture', 'Native', 'Audit')]
    [string] $Phase,
    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9]{8}T[0-9]{6}Z-[0-9a-f]{8}$')]
    [string] $RunId,
    [string] $EngineRoot = 'C:\Program Files\Epic Games\UE_5.8'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$utf8 = [Text.UTF8Encoding]::new($false, $true)
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$coreRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot '..\Warhammer_40k_AI'))
$arcadeRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot '..\Warhammer_40k_UI_arcade'))
$expectedCommit = '5f509724da25a2f6ded0c2739a8e7c84bdf59c91'
$expectedBuild = 'warhammer40k-core-v2:runtime-tree-sha256-v1:65fc8414407ae5d6a8ea779c8e737a22733459094db679a160c60f6e2129f96a'
$selectedPython = 'C:\Users\Rabid\AppData\Roaming\uv\python\cpython-3.14.5-windows-x86_64-none\python.exe'
$uvPath = 'C:\Users\Rabid\.local\bin\uv.exe'
$fixtureRoot = Join-Path $projectRoot "tests\migration\fixtures\$expectedCommit"
$sourceManifestPath = Join-Path $fixtureRoot 'manifest.json'
$packetPath = Join-Path $projectRoot 'docs\plans\research\2026-10-16-e01-boundary-packet.md'
$harnessPath = Join-Path $PSScriptRoot 'e01_boundary.py'
$unitTestsPath = Join-Path $projectRoot 'tests\migration\test_e01_boundary.py'
$runtimeRoot = Join-Path $projectRoot '.local\core-44.3.33'
$runtimePython = Join-Path $runtimeRoot 'Scripts\python.exe'
$provenancePath = Join-Path $runtimeRoot '.e01-provenance.json'
$runParent = Join-Path $projectRoot '.local\experiments\E01-target'
$runRoot = Join-Path $runParent $RunId
$phaseRoot = Join-Path $runRoot $Phase.ToLowerInvariant()
$timeoutMilliseconds = 30 * 60 * 1000
$gitPath = (Get-Command git -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
$phaseResult = $null
$runLock = $null
$runtimeLock = $null
$failure = $null
$before = $null
$script:secretValues = @([Environment]::GetEnvironmentVariables().GetEnumerator() |
    Where-Object { $_.Key -match '(?i)(TOKEN|PASSWORD|SECRET|API_KEY|CREDENTIAL)' -and ([string]$_.Value).Length -ge 8 } |
    ForEach-Object { [string]$_.Value })
$normalizedSourceHashes = [ordered]@{
    'uv.lock' = '51896fa6800d7bbb5c6dfe08a8c7155640ec71842fafe9d78020b6a36b43e0aa'
    'pyproject.toml' = 'b0fed8cc1f2a25bec5821a96f50e0d7da47ec5e9e8e17df528cd6f69c6d67192'
    'contracts/manifest.json' = '3723e0bf79cc163c521f6c7636d903aef987237431116cc128539366849d7e66'
    'src/warhammer40k_core/_engine_build_manifest.json' = 'b3f45468657d97f8242ecfb4f49e5fa8becfca8b2f6957721228fb44d04a1f6f'
    'scripts/run_phase18m_reference_server.py' = '4b20a9e281e1b44f2aaac3d3badc4328592f54a789abc6c7646089ce24a595a7'
}

function Assert-NoReparsePoint([string] $Path) {
    $cursor = [IO.Path]::GetFullPath($Path)
    while ($cursor) {
        if ([IO.File]::Exists($cursor) -or [IO.Directory]::Exists($cursor)) {
            if (([IO.File]::GetAttributes($cursor) -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "Reparse-point path is outside this proof's ownership model: $cursor"
            }
        }
        $parent = [IO.Directory]::GetParent($cursor)
        $cursor = if ($null -eq $parent) { $null } else { $parent.FullName }
    }
}

function Assert-ChildPath([string] $Path, [string] $Parent) {
    $absolute = [IO.Path]::GetFullPath($Path)
    $prefix = [IO.Path]::GetFullPath($Parent).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
    if (-not $absolute.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Output path escapes its approved parent: $absolute"
    }
    Assert-NoReparsePoint $absolute
    return $absolute
}

function Get-MemberPath([string] $Root, [string] $Relative) {
    if ($Relative -notmatch '^[A-Za-z0-9_./-]+$' -or
        @($Relative.Split('/') | Where-Object { $_ -in @('', '.', '..') }).Count -ne 0) {
        throw 'Invalid portable relative member path.'
    }
    return Assert-ChildPath (Join-Path $Root $Relative) $Root
}

function Get-ArchiveEntryPath([string] $Root, [string] $EntryName) {
    # Git's full source archive includes ordinary Windows filenames (including
    # commas, spaces and Unicode) beyond the portable fixture-member alphabet.
    # Validate each component without normalizing away traversal or aliases.
    if ([string]::IsNullOrEmpty($EntryName) -or [IO.Path]::IsPathRooted($EntryName) -or $EntryName.Contains('\')) {
        throw 'Rooted or backslash archive member is forbidden.'
    }
    $relative = if ($EntryName.EndsWith('/')) { $EntryName.Substring(0, $EntryName.Length - 1) } else { $EntryName }
    foreach ($component in $relative.Split('/')) {
        if ($component -in @('', '.', '..') -or $component.IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0 -or
            $component.EndsWith('.') -or $component.EndsWith(' ') -or
            $component -match '^(?i:CON|PRN|AUX|NUL|CONIN\$|CONOUT\$|COM[1-9¹²³]|LPT[1-9¹²³])(?:\.|$)') {
            throw 'Invalid, traversing or Windows-aliased archive member.'
        }
    }
    return Assert-ChildPath (Join-Path $Root $relative) $Root
}

function Require-File([string] $Path) {
    Assert-NoReparsePoint $Path
    if (-not [IO.File]::Exists($Path)) { throw "Required file absent: $Path" }
}

function Get-Hash([string] $Path) {
    Require-File $Path
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-TextHash([string] $Text) {
    return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($utf8.GetBytes($Text))).ToLowerInvariant()
}

function Get-NormalizedHash([string] $Path) {
    Require-File $Path
    $text = $utf8.GetString([IO.File]::ReadAllBytes($Path)).Replace("`r`n", "`n").Replace("`r", "`n")
    return Get-TextHash $text
}

function Assert-SafeText([string] $Text) {
    foreach ($secret in $script:secretValues) {
        if ($Text.Contains($secret, [StringComparison]::Ordinal)) { throw 'Credential scan rejected output; original output was not exported.' }
    }
    if ($Text -match '(?i)(?:\bBearer\s+[A-Za-z0-9._~+/-]{8,}|\bgh[pousr]_[A-Za-z0-9]{16,}|\bgithub_pat_[A-Za-z0-9_]{16,}|https?://[^\s/@:]+:[^\s/@]+@)') {
        throw 'Credential scan rejected output; original output was not exported.'
    }
}

function Write-NewJson([string] $Path, $Value) {
    $absolute = Assert-ChildPath $Path $projectRoot
    $json = ($Value | ConvertTo-Json -Depth 80) + "`n"
    Assert-SafeText $json
    $stream = [IO.File]::Open($absolute, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::Read)
    try { $bytes = $utf8.GetBytes($json); $stream.Write($bytes, 0, $bytes.Length) } finally { $stream.Dispose() }
}

function Read-Json([string] $Path) {
    Require-File $Path
    $text = [IO.File]::ReadAllText($Path, $utf8)
    Assert-SafeText $text
    return $text | ConvertFrom-Json -AsHashtable
}

function New-OwnedDirectory([string] $Path, [string] $Parent) {
    $absolute = Assert-ChildPath $Path $Parent
    if (Test-Path -LiteralPath $absolute) { throw "Refusing an existing output collision: $absolute" }
    $null = New-Item -ItemType Directory -Path $absolute
    Assert-NoReparsePoint $absolute
    return $absolute
}

function New-ChildEnvironment([hashtable] $Extra = @{}) {
    $environment = @{}
    # Start from an allowlist. No GitHub, index, proxy, Python or uv configuration
    # is inherited by install/test/host children. The parent environment is intact.
    foreach ($name in @('SystemRoot', 'WINDIR', 'SystemDrive', 'COMSPEC', 'PATH', 'PATHEXT',
            'USERPROFILE', 'APPDATA', 'LOCALAPPDATA', 'ProgramFiles', 'ProgramFiles(x86)',
            'ProgramW6432', 'NUMBER_OF_PROCESSORS', 'PROCESSOR_ARCHITECTURE', 'OS')) {
        $value = [Environment]::GetEnvironmentVariable($name)
        if ($null -ne $value) { $environment[$name] = $value }
    }
    $environment['TEMP'] = Join-Path $runRoot 'tmp'
    $environment['TMP'] = $environment['TEMP']
    $environment['PYTHONDONTWRITEBYTECODE'] = '1'
    $environment['PYTHONNOUSERSITE'] = '1'
    $environment['UV_PYTHON_DOWNLOADS'] = 'never'
    $environment['UV_CACHE_DIR'] = Join-Path $runRoot 'cache\uv'
    $environment['UV_NO_CONFIG'] = '1'
    foreach ($entry in $Extra.GetEnumerator()) { $environment[$entry.Key] = [string]$entry.Value }
    return $environment
}

function Stop-OwnedProcess($Process, [datetime] $StartedUtc) {
    if (-not $Process.HasExited) {
        $current = [Diagnostics.Process]::GetProcessById($Process.Id)
        try {
            if ($current.StartTime.ToUniversalTime().Ticks -ne $StartedUtc.Ticks) { throw 'Owned PID identity changed; refusing termination.' }
            $Process.Kill($true)
            if (-not $Process.WaitForExit(10000)) { throw 'Owned process tree did not stop within ten seconds.' }
        } finally { $current.Dispose() }
    }
}

function Invoke-OwnedProcess([string] $Label, [string] $Executable, [string[]] $Arguments,
    [string] $WorkingDirectory, [hashtable] $ExtraEnvironment = @{}, [int] $MaximumMilliseconds = $timeoutMilliseconds) {
    if ($Label -notmatch '^[a-z0-9-]+$') { throw 'Unsafe process log label.' }
    Require-File $Executable
    $null = Assert-ChildPath (Join-Path $WorkingDirectory '.boundary-check') $runRoot
    Assert-SafeText ($Arguments -join "`n")
    $stdoutPath = Join-Path $phaseRoot "$Label.stdout.log"
    $stderrPath = Join-Path $phaseRoot "$Label.stderr.log"
    if ((Test-Path -LiteralPath $stdoutPath) -or (Test-Path -LiteralPath $stderrPath)) { throw 'Process log collision; use a new run.' }
    $start = [Diagnostics.ProcessStartInfo]::new()
    $start.FileName = $Executable
    $start.WorkingDirectory = $WorkingDirectory
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.WindowStyle = [Diagnostics.ProcessWindowStyle]::Hidden
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    foreach ($argument in $Arguments) { $start.ArgumentList.Add($argument) }
    $start.Environment.Clear()
    foreach ($entry in (New-ChildEnvironment $ExtraEnvironment).GetEnumerator()) { $start.Environment[$entry.Key] = $entry.Value }
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $start
    $record = [ordered]@{ label = $Label; executable = $Executable; executableSha256 = Get-Hash $Executable
        arguments = $Arguments; workingDirectory = $WorkingDirectory; timeoutSeconds = $MaximumMilliseconds / 1000
        pid = $null; startedUtc = $null; exitedUtc = $null; exitCode = $null; timedOut = $false
        redaction = 'PENDING'; stdout = $stdoutPath; stderr = $stderrPath }
    $phaseResult.processes.Add($record)
    $stdoutWriter = [IO.StreamWriter]::new($stdoutPath, $false, $utf8)
    $stderrWriter = [IO.StreamWriter]::new($stderrPath, $false, $utf8)
    $stdoutWriter.AutoFlush = $true; $stderrWriter.AutoFlush = $true
    $captured = [Text.StringBuilder]::new()
    $watch = [Diagnostics.Stopwatch]::StartNew()
    $lastProgress = 0L
    $startedUtc = $null
    $logBytes = 0L
    try {
        if (-not $process.Start()) { throw 'Child process did not start.' }
        $startedUtc = $process.StartTime.ToUniversalTime()
        $record.pid = $process.Id; $record.startedUtc = $startedUtc.ToString('o')
        $outTask = $process.StandardOutput.ReadLineAsync()
        $errTask = $process.StandardError.ReadLineAsync()
        $outDone = $false; $errDone = $false
        while (-not ($process.HasExited -and $outDone -and $errDone)) {
            if ($watch.ElapsedMilliseconds -ge $MaximumMilliseconds) { $record.timedOut = $true; throw "Process deadline exceeded: $Label" }
            $drainedAny = $false
            foreach ($lane in @('out', 'err')) {
                # Drain buffered output promptly, with a fair per-stream batch so
                # a noisy stream cannot starve its peer or the deadline checks.
                for ($drained = 0; $drained -lt 256; $drained++) {
                    $task = if ($lane -eq 'out') { $outTask } else { $errTask }
                    $done = if ($lane -eq 'out') { $outDone } else { $errDone }
                    if ($done -or -not $task.IsCompleted) { break }
                    if ($watch.ElapsedMilliseconds -ge $MaximumMilliseconds) { $record.timedOut = $true; throw "Process deadline exceeded: $Label" }
                    $drainedAny = $true
                    $line = $task.GetAwaiter().GetResult()
                    if ($null -eq $line) {
                        if ($lane -eq 'out') { $outDone = $true } else { $errDone = $true }
                    } else {
                        Assert-SafeText $line
                        $logBytes += $utf8.GetByteCount($line) + 1
                        if ($logBytes -gt 64MB) { throw "Process log ceiling exceeded: $Label" }
                        if ($lane -eq 'out') {
                            $stdoutWriter.WriteLine($line); $null = $captured.AppendLine($line)
                            $outTask = $process.StandardOutput.ReadLineAsync()
                        } else {
                            $stderrWriter.WriteLine($line); $errTask = $process.StandardError.ReadLineAsync()
                        }
                    }
                }
            }
            if ($watch.ElapsedMilliseconds - $lastProgress -ge 15000) {
                Write-Host ("E01 {0}/{1}: child {2} active for {3:N0}s; sanitized logs in {4}" -f $RunId, $Phase, $Label, $watch.Elapsed.TotalSeconds, $phaseRoot)
                $lastProgress = $watch.ElapsedMilliseconds
            }
            if (-not $drainedAny) { Start-Sleep -Milliseconds 50 }
        }
        $process.WaitForExit()
        $record.exitCode = $process.ExitCode
        $record.redaction = 'PASS'
        if ($process.ExitCode -ne 0) { throw "Child process failed: $Label (exit $($process.ExitCode)); inspect its sanitized logs." }
        return $captured.ToString().TrimEnd()
    } catch {
        $record.redaction = if ($_.Exception.Message -like 'Credential scan*') { 'REJECTED_QUARANTINED' } else { 'SCANNED_PARTIAL' }
        if ($null -ne $startedUtc) { Stop-OwnedProcess $process $startedUtc }
        throw
    } finally {
        $record.exitedUtc = [datetime]::UtcNow.ToString('o')
        $stdoutWriter.Dispose(); $stderrWriter.Dispose()
        if ($null -ne $startedUtc -and $process.HasExited) { $record.exitCode = $process.ExitCode }
        $process.Dispose()
    }
}

function Invoke-Git([string] $Label, [string] $Root, [string[]] $Arguments) {
    return Invoke-OwnedProcess $Label $gitPath (@('-C', $Root) + $Arguments) $runRoot @{} 30000
}

function Get-SiblingState([string] $Suffix) {
    $coreHead = Invoke-Git "core-head-$Suffix" $coreRoot @('rev-parse', 'HEAD')
    $coreStatus = Invoke-Git "core-status-$Suffix" $coreRoot @('status', '--porcelain=v1', '--untracked-files=all')
    return [ordered]@{ core = @{ head = $coreHead; status = $coreStatus }
        arcade = @{ head = (Invoke-Git "arcade-head-$Suffix" $arcadeRoot @('rev-parse', 'HEAD'))
            status = (Invoke-Git "arcade-status-$Suffix" $arcadeRoot @('status', '--porcelain=v1', '--untracked-files=all')) } }
}

function Assert-SelectedCore($State) {
    if ($State.core.head -ne $expectedCommit -or $State.core.status) { throw 'Selected Core must remain at its exact clean committed source; never reset it here.' }
}

function Assert-SameSiblings($Before, $After) {
    foreach ($name in @('core', 'arcade')) {
        if ($Before[$name].head -ne $After[$name].head -or $Before[$name].status -ne $After[$name].status) { throw 'Sibling source state changed; preserve evidence and investigate.' }
    }
}

function Get-SourceEvidence {
    $manifest = Read-Json $sourceManifestPath
    if ($manifest.CoreCommit -ne $expectedCommit -or $manifest.ContractVersion -ne '44.3.33' -or
        $manifest.RuntimeBuildId -ne $expectedBuild -or $manifest.RuntimeResourceCount -ne 3116 -or
        $manifest.SourceFiles.Count -ne 127 -or $manifest.CanonicalInteractionCaseCount -ne 98) { throw 'Frozen source inventory identity/count mismatch.' }
    $treeText = Invoke-Git 'core-tree' $coreRoot @('ls-tree', '-r', $expectedCommit)
    $tree = @{}
    foreach ($line in $treeText.Split("`n")) {
        if ($line -match '^100[0-9]{3} blob ([0-9a-f]{40})\t(.+)$') { $tree[$Matches[2].TrimEnd("`r")] = $Matches[1] }
    }
    $sourceRecords = @(); $seen = @{}; $copiedContracts = 0
    foreach ($member in $manifest.SourceFiles) {
        if ($seen.ContainsKey($member.Path)) { throw 'Duplicate source inventory member.' }
        $seen[$member.Path] = $true
        $path = Get-MemberPath $coreRoot $member.Path
        $hash = Get-Hash $path
        if ($hash -ne $member.SHA256.ToLowerInvariant() -or $tree[$member.Path] -ne $member.GitBlob) { throw "Frozen source member drift: $($member.Path)" }
        if ($member.Path.StartsWith('contracts/', [StringComparison]::Ordinal)) {
            $copy = Get-MemberPath $fixtureRoot $member.Path
            if ((Get-Hash $copy) -ne $hash) { throw "Immutable fixture copy mismatch: $($member.Path)" }
            $copiedContracts++
        }
        $sourceRecords += @{ path = $member.Path; rawSha256 = $hash; gitBlob = $member.GitBlob }
    }
    $additional = @(foreach ($entry in $normalizedSourceHashes.GetEnumerator()) {
        $path = Get-MemberPath $coreRoot $entry.Key
        $normalized = Get-NormalizedHash $path
        if ($normalized -ne $entry.Value) { throw "Selected normalized source hash drift: $($entry.Key)" }
        @{ path = $entry.Key; rawSha256 = Get-Hash $path; normalizedSha256 = $normalized; gitBlob = $tree[$entry.Key] }
    })
    $contract = Read-Json (Join-Path $coreRoot 'contracts\manifest.json')
    if ($contract.contract_version -ne '44.3.33' -or $contract.file_sha256.Count -ne 234) { throw 'Canonical committed contract identity/count mismatch.' }
    $canonical = @(foreach ($entry in $contract.file_sha256.GetEnumerator() | Sort-Object Key) {
        $path = Get-MemberPath (Join-Path $coreRoot 'contracts') $entry.Key
        $normalized = Get-NormalizedHash $path
        if ($normalized -ne $entry.Value) { throw "Canonical normalized contract hash mismatch: $($entry.Key)" }
        @{ path = "contracts/$($entry.Key)"; rawSha256 = Get-Hash $path; normalizedSha256 = $normalized }
    })
    $conformance = Read-Json (Join-Path $coreRoot 'contracts\examples\decisions\interaction-conformance.json')
    $caseIds = @($conformance.cases | ForEach-Object { $_.case_id })
    if ($caseIds.Count -ne 98 -or @($caseIds | Sort-Object -Unique).Count -ne 98 -or
        @(Compare-Object ($caseIds | Sort-Object) ($manifest.CanonicalInteractionCaseIds | Sort-Object)).Count -ne 0) { throw 'Canonical case IDs differ from frozen inventory.' }
    $build = Read-Json (Join-Path $coreRoot 'src\warhammer40k_core\_engine_build_manifest.json')
    if ($build.build_id -ne $expectedBuild -or $build.resource_count -ne 3116 -or $build.resources.Count -ne 3116) { throw 'Source runtime metadata mismatch.' }
    return [ordered]@{ coreCommit = $expectedCommit; contractVersion = '44.3.33'; runtimeBuildId = $expectedBuild
        runtimeResources = 3116; sourceManifestSha256 = Get-Hash $sourceManifestPath; sourceFiles = $sourceRecords
        canonicalContractMembers = $canonical; copiedContractCount = $copiedContracts; additionalSources = $additional
        canonicalCaseIds = $caseIds; runtimeCasesExecuted = 0 }
}

function Get-Candidate([string[]] $Paths) {
    return [ordered]@{ head = (Invoke-Git 'candidate-head' $projectRoot @('rev-parse', 'HEAD'))
        files = @(foreach ($path in $Paths | Sort-Object -Unique) { @{ path = $path; sha256 = Get-Hash $path } }) }
}

function Assert-Candidate($Candidate) {
    foreach ($file in $Candidate.files) { if ((Get-Hash $file.path) -ne $file.sha256) { throw "Frozen authored candidate changed: $($file.path)" } }
}

function Get-Toolchain {
    foreach ($path in @($selectedPython, $uvPath, (Join-Path $EngineRoot 'Engine\Build\BatchFiles\Build.bat'),
            (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor-Cmd.exe'))) { Require-File $path }
    $versionPath = Join-Path $EngineRoot 'Engine\Build\Build.version'
    $version = Read-Json $versionPath
    if ($version.MajorVersion -ne 5 -or $version.MinorVersion -ne 8 -or $version.PatchVersion -ne 3 -or $version.Changelist -ne 58210709) { throw 'Expected UE5.8.3 / CL58210709; no tool upgrade is permitted.' }
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    $instances = (Invoke-OwnedProcess 'vswhere' $vswhere @('-all', '-products', '*', '-requires', 'Microsoft.VisualStudio.Component.VC.Tools.x86.x64', '-format', 'json') $runRoot) | ConvertFrom-Json
    $compiler = @(foreach ($instance in $instances) {
        $path = Join-Path $instance.installationPath 'VC\Tools\MSVC\14.44.35207\bin\Hostx64\x64\cl.exe'
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            if ((Get-Item -LiteralPath $path).VersionInfo.ProductVersion -eq '14.44.35229.0' -and [version]$instance.installationVersion -ge [version]'17.14') { $path }
        }
    }) | Select-Object -First 1
    if (-not $compiler) { throw 'Selected MSVC14.44.35229 / VS2022 17.14 unavailable.' }
    $sdk = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10'
    foreach ($relative in @('Include\10.0.22621.0\um\Windows.h', 'Include\10.0.22621.0\ucrt\stdio.h',
            'Lib\10.0.22621.0\um\x64\kernel32.lib', 'Lib\10.0.22621.0\ucrt\x64\ucrt.lib', 'bin\10.0.22621.0\x64\rc.exe')) { Require-File (Join-Path $sdk $relative) }
    $free = [IO.DriveInfo]::new([IO.Path]::GetPathRoot($projectRoot)).AvailableFreeSpace
    if ($free -lt 20GB) { throw 'E01 proof requires 20 GiB available for its bounded runtime/build outputs.' }
    return @{ selectedPython = $selectedPython; selectedPythonSha256 = Get-Hash $selectedPython
        pythonVersion = Invoke-OwnedProcess 'python-version' $selectedPython @('-I', '-B', '--version') $runRoot
        uv = $uvPath; uvSha256 = Get-Hash $uvPath; uvVersion = Invoke-OwnedProcess 'uv-version' $uvPath @('--version') $runRoot
        engineRoot = $EngineRoot; engineVersion = $version; engineVersionSha256 = Get-Hash $versionPath
        compiler = $compiler; compilerSha256 = Get-Hash $compiler; compilerVersion = '14.44.35229'; sdk = '10.0.22621.0'; freeBytes = $free }
}

function Invoke-Harness([string] $HarnessPhase, [string] $Interpreter, [string] $Label, [string] $ExistingOutput = '') {
    Require-File $harnessPath
    $output = if ($ExistingOutput) { Assert-ChildPath $ExistingOutput $runRoot } else { New-OwnedDirectory (Join-Path $phaseRoot $Label) $phaseRoot }
    $report = Join-Path $output $(if ($ExistingOutput) { 'audit-report.json' } else { 'report.json' })
    $arguments = @('-I', '-B', $harnessPath, $HarnessPhase, '--core-root', $coreRoot,
        '--fixture-root', $fixtureRoot, '--output-root', $output, '--report-file', $report,
        '--core-launcher', (Join-Path $coreRoot 'scripts\run_phase18m_reference_server.py'))
    $null = Invoke-OwnedProcess $Label $Interpreter $arguments $runRoot
    $result = Read-Json $report
    foreach ($key in @('schemaVersion', 'phase', 'status', 'caseCounts', 'cases', 'artifacts', 'redaction')) {
        if (-not $result.ContainsKey($key)) { throw "Harness report missing field: $key" }
    }
    if ($result.schemaVersion -ne 1 -or $result.phase -ne $HarnessPhase -or $result.redaction.status -ne 'PASS') { throw 'Harness report identity/redaction failed.' }
    $expected = @{ preflight = 'SOURCE_INVENTORY_PASS'; 'verify-runtime' = 'INSTALLED_RUNTIME_PASS'; capture = 'LOCAL_HTTP_BOUNDARY_PASS' }
    if ($HarnessPhase -ne 'audit' -and $result.status -ne $expected[$HarnessPhase]) { throw "Harness phase did not pass: $HarnessPhase ($($result.status))" }
    if ($result.status -in @('FAIL', 'BLOCKED', 'NOT_RUN')) { throw "Harness phase did not pass: $HarnessPhase ($($result.status))" }
    foreach ($artifact in $result.artifacts) {
        $path = if ([IO.Path]::IsPathRooted($artifact.path)) { $artifact.path } else { Join-Path $output $artifact.path }
        $path = Assert-ChildPath $path $output
        if ((Get-Hash $path) -ne $artifact.sha256.ToLowerInvariant()) { throw 'Harness artifact hash mismatch.' }
    }
    $phaseResult.childReports.Add(@{ phase = $HarnessPhase; path = $report; sha256 = Get-Hash $report; status = $result.status; caseCounts = $result.caseCounts })
    return $result
}

function Expand-OwnedArchive([string] $Archive, [string] $Destination) {
    $null = New-OwnedDirectory $Destination $runRoot
    $zip = [IO.Compression.ZipFile]::OpenRead($Archive)
    try {
        $seen = @{}; $totalBytes = 0L
        foreach ($entry in $zip.Entries) {
            $path = Get-ArchiveEntryPath $Destination $entry.FullName
            if ($seen.ContainsKey($path)) { throw 'Unsafe or duplicate archive member.' }
            $seen[$path] = $true
            $unixType = (($entry.ExternalAttributes -shr 16) -band 0xF000)
            if ($unixType -notin @(0, 0x4000, 0x8000) -or ($entry.ExternalAttributes -band 0x400) -ne 0) { throw 'Archive contains a link/reparse/special member.' }
            $totalBytes += $entry.Length
        }
        if ($zip.Entries.Count -eq 0 -or $totalBytes -gt 8GB -or $totalBytes + 5GB -gt [IO.DriveInfo]::new([IO.Path]::GetPathRoot($Destination)).AvailableFreeSpace) { throw 'Archive is empty or exceeds bounded extraction/disk budget.' }
        foreach ($entry in $zip.Entries) {
            $path = Get-ArchiveEntryPath $Destination $entry.FullName
            if ($entry.FullName.EndsWith('/')) { $null = [IO.Directory]::CreateDirectory($path); continue }
            $null = [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($path))
            Assert-NoReparsePoint $path
            $inputStream = $entry.Open()
            $outputStream = [IO.File]::Open($path, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
            try { $inputStream.CopyTo($outputStream) } finally { $outputStream.Dispose(); $inputStream.Dispose() }
        }
        return @{ entries = $zip.Entries.Count; uncompressedBytes = $totalBytes; sha256 = Get-Hash $Archive }
    } finally { $zip.Dispose() }
}

function Get-GitBlobHash([string] $Path) {
    $bytes = [IO.File]::ReadAllBytes($Path)
    $header = $utf8.GetBytes("blob $($bytes.Length)`0")
    $hash = [Security.Cryptography.IncrementalHash]::CreateHash([Security.Cryptography.HashAlgorithmName]::SHA1)
    try { $hash.AppendData($header); $hash.AppendData($bytes); return [Convert]::ToHexString($hash.GetHashAndReset()).ToLowerInvariant() } finally { $hash.Dispose() }
}

function Get-RuntimeTree {
    Assert-NoReparsePoint $runtimeRoot
    $records = [Collections.Generic.List[object]]::new()
    $directories = [Collections.Generic.Queue[string]]::new(); $directories.Enqueue($runtimeRoot)
    while ($directories.Count -gt 0) {
        $directory = $directories.Dequeue()
        foreach ($item in Get-ChildItem -LiteralPath $directory -Force) {
            if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'Runtime tree contains an unsupported reparse point.' }
            if ($item.PSIsContainer) { $directories.Enqueue($item.FullName) }
            elseif ($item.Extension -eq '.pyc') { throw 'Runtime tree contains loadable bytecode; bytecode is forbidden in the verified runtime.' }
            elseif ($item.Name -ne '.e01-provenance.json') {
                $records.Add([ordered]@{ path = [IO.Path]::GetRelativePath($runtimeRoot, $item.FullName).Replace('\', '/'); sha256 = Get-Hash $item.FullName })
            }
        }
    }
    return @($records | Sort-Object { $_.path })
}

function Get-RuntimeTreeHash($Tree) {
    return Get-TextHash ((@($Tree | ForEach-Object { $_.path + "`t" + $_.sha256 }) -join "`n") + "`n")
}

function Invoke-InstalledVerification([string] $Label) {
    $outside = Join-Path $runRoot 'outside-source'
    $code = @'
import hashlib, importlib, importlib.metadata as m, json, pathlib, sys
root = pathlib.Path(sys.argv[1]).resolve()
expected = sys.argv[2]
if pathlib.Path(sys.prefix).resolve() != root or sys.version_info[:3] != (3, 14, 5):
    raise RuntimeError('Unexpected isolated interpreter identity')
import warhammer40k_core
package = pathlib.Path(warhammer40k_core.__file__).resolve()
if not package.is_relative_to(root):
    raise RuntimeError('Core resolved outside the owned installed environment')
from warhammer40k_core.build_identity import verified_engine_build_identity
identity = verified_engine_build_identity()
if identity.build_id != expected or identity.resource_count != 3116:
    raise RuntimeError('Installed authoritative runtime identity mismatch')
modules = {}
for name in ('orjson', 'msgspec', 'pydantic', 'shapely', 'numpy', 'jsonschema', 'referencing', 'z3'):
    module = importlib.import_module(name)
    path = pathlib.Path(module.__file__).resolve()
    if not path.is_relative_to(root):
        raise RuntimeError('Dependency resolved outside the owned runtime: ' + name)
    modules[name] = {'file': str(path), 'distributionVersions': {dist: m.version(dist) for dist in m.packages_distributions().get(name, [])}}
inventory = []
for dist in m.distributions():
    record = {'name': dist.metadata['Name'], 'version': dist.version, 'location': str(dist.locate_file('')), 'provenance': {}}
    for member in ('WHEEL', 'direct_url.json', 'INSTALLER', 'RECORD'):
        value = dist.read_text(member)
        if value is not None:
            record['provenance'][member] = {'sha256': hashlib.sha256(value.encode('utf-8')).hexdigest()}
            if member != 'RECORD':
                record['provenance'][member]['text'] = value
    inventory.append(record)
print(json.dumps({'python': sys.version, 'prefix': str(root), 'package': str(package), 'buildId': identity.build_id, 'resourceCount': identity.resource_count, 'modules': modules, 'installed': sorted(inventory, key=lambda d: d['name'].lower())}, sort_keys=True))
'@
    $text = Invoke-OwnedProcess $Label $runtimePython @('-I', '-B', '-c', $code, $runtimeRoot, $expectedBuild) $outside
    return $text | ConvertFrom-Json -AsHashtable
}

function Assert-Runtime {
    $provenance = Read-Json $provenancePath
    if ($provenance.status -ne 'INSTALLED_RUNTIME_PASS' -or $provenance.coreCommit -ne $expectedCommit -or
        $provenance.runtimeBuildId -ne $expectedBuild -or $provenance.sourceManifestSha256 -ne (Get-Hash $sourceManifestPath) -or
        $provenance.uvSha256 -ne (Get-Hash $uvPath) -or $provenance.selectedPythonSha256 -ne (Get-Hash $selectedPython)) { throw 'Existing runtime provenance does not match this frozen proof.' }
    foreach ($source in $provenance.sourceHashes) {
        if ((Get-NormalizedHash (Get-MemberPath $coreRoot $source.path)) -ne $source.normalizedSha256) { throw 'Runtime source/lock provenance drift.' }
    }
    $tree = Get-RuntimeTree
    $fingerprint = Get-RuntimeTreeHash $tree
    if ($fingerprint -ne $provenance.runtimeTreeSha256) { throw 'Owned installed runtime changed since verified preparation.' }
    $identity = Invoke-InstalledVerification 'runtime-recheck'
    $phaseResult.runtime = @{ provenance = $provenancePath; provenanceSha256 = Get-Hash $provenancePath; identity = $identity; runtimeTreeSha256 = $fingerprint }
}

function Get-UBTSettings {
    $paths = @((Join-Path ([Environment]::GetFolderPath('ApplicationData')) 'Unreal Engine\UnrealBuildTool\BuildConfiguration.xml'),
        (Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'Unreal Engine\UnrealBuildTool\BuildConfiguration.xml'))
    $documents = [Environment]::GetFolderPath('MyDocuments')
    if ($documents) { $paths += Join-Path $documents 'Unreal Engine\UnrealBuildTool\BuildConfiguration.xml' }
    return @(foreach ($path in $paths | Sort-Object -Unique) {
        Assert-NoReparsePoint $path
        @{ path = $path; exists = [IO.File]::Exists($path); sha256 = $(if ([IO.File]::Exists($path)) { Get-Hash $path } else { $null }) }
    })
}

function Assert-UBTSettings($Before, $After) {
    foreach ($setting in $Before) {
        $current = @($After | Where-Object { $_.path -eq $setting.path })
        if ($current.Count -ne 1 -or $setting.exists -ne $current[0].exists -or $setting.sha256 -ne $current[0].sha256) { throw 'Global UBT settings changed during the native proof.' }
    }
}

function Get-SafeArtifact([string] $Path) {
    Require-File $Path
    $reader = [IO.StreamReader]::new($Path, $utf8)
    try { while ($null -ne ($line = $reader.ReadLine())) { Assert-SafeText $line } } finally { $reader.Dispose() }
    return @{ path = $Path; sha256 = Get-Hash $Path; redaction = 'PASS' }
}

function Get-AutomationEvidence([string] $ReportPath) {
    $report = Read-Json $ReportPath
    $tests = @($report.tests | Where-Object { $_.fullTestPath -like 'Warhammer.Migration.E01Boundary*' })
    if ($tests.Count -eq 0) { throw 'Native suite exported zero matching cases.' }
    foreach ($test in $tests) {
        if ($test.state -ne 'Success') { throw "Native case did not pass: $($test.fullTestPath) ($($test.state))" }
    }
    if ($report.failed -ne 0 -or $report.notRun -ne 0 -or $report.inProcess -ne 0) { throw 'Native report contains failed/incomplete cases.' }
    return @{ matchingCount = $tests.Count; tests = @($tests | ForEach-Object { @{ name = $_.fullTestPath; state = $_.state } }); reportSha256 = Get-Hash $ReportPath }
}

try {
    if (-not $IsWindows -or -not [Environment]::Is64BitOperatingSystem -or [Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture -ne 'X64') { throw 'E01 requires native x64 Windows and PowerShell7.2+.' }
    foreach ($path in @($projectRoot, $coreRoot, $arcadeRoot, $EngineRoot, $runRoot, $runtimeRoot, $fixtureRoot)) {
        Assert-NoReparsePoint $path
        if ($path -match '["\r\n%!^&|<>]') { throw 'Bounded Windows proof paths cannot contain shell metacharacters.' }
    }
    $null = Assert-ChildPath $runRoot $runParent
    $null = Assert-ChildPath $runtimeRoot $projectRoot
    if ($Phase -eq 'Preflight') {
        $null = New-OwnedDirectory $runRoot $runParent
        foreach ($relative in @('tmp', 'cache', 'cache\uv', 'outside-source')) { $null = [IO.Directory]::CreateDirectory((Assert-ChildPath (Join-Path $runRoot $relative) $runRoot)) }
    } elseif (-not [IO.Directory]::Exists($runRoot)) { throw 'Preflight must create this unique run first.' }
    $runLock = [IO.File]::Open((Join-Path $runRoot '.phase.lock'), [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    $null = New-OwnedDirectory $phaseRoot $runRoot
    $phaseResult = [ordered]@{ schemaVersion = 1; packet = 'E01-WIN-BOUNDARY'; runId = $RunId; phase = $Phase
        status = 'RUNNING'; startedUtc = [datetime]::UtcNow.ToString('o'); completedUtc = $null
        runRoot = $runRoot; processes = [Collections.Generic.List[object]]::new(); childReports = [Collections.Generic.List[object]]::new()
        checks = [Collections.Generic.List[object]]::new(); redaction = @{ status = 'PENDING'; scope = 'wrapper outputs; harness scans role/private artifacts separately' }
        linux = 'NOT_RUN'; independentCodeReview = 'EXTERNAL_REQUIRED'; independentAcceptanceAudit = 'EXTERNAL_REQUIRED' }
    Write-NewJson (Join-Path $phaseRoot 'started.json') @{ runId = $RunId; phase = $Phase; startedUtc = $phaseResult.startedUtc; wrapperSha256 = Get-Hash $PSCommandPath }
    if ($Phase -ne 'Preflight') {
        $preflight = Read-Json (Join-Path $runRoot 'preflight\result.json')
        if ($preflight.status -ne 'SOURCE_INVENTORY_PASS' -or $preflight.runId -ne $RunId) { throw 'Preflight did not pass for this run.' }
        Assert-Candidate $preflight.candidate
        if ($EngineRoot -ne $preflight.toolchain.engineRoot -or (Get-Hash $selectedPython) -ne $preflight.toolchain.selectedPythonSha256 -or
            (Get-Hash $uvPath) -ne $preflight.toolchain.uvSha256) { throw 'Selected tool paths/bytes changed after Preflight.' }
        $predecessors = @{ PrepareRuntime = 'preflight'; Capture = 'prepareruntime'; Native = 'capture'; Audit = 'native' }
        $previous = Read-Json (Join-Path $runRoot ($predecessors[$Phase] + '\result.json'))
        $expectedStatuses = @{ PrepareRuntime = 'SOURCE_INVENTORY_PASS'; Capture = 'INSTALLED_RUNTIME_PASS'; Native = 'LOCAL_HTTP_BOUNDARY_PASS'; Audit = 'NATIVE_FIXTURE_PASS' }
        if ($previous.status -ne $expectedStatuses[$Phase] -or $previous.runId -ne $RunId) { throw 'Explicit predecessor phase did not pass for this run.' }
        $phaseResult.predecessor = @{ path = Join-Path $runRoot ($predecessors[$Phase] + '\result.json'); sha256 = Get-Hash (Join-Path $runRoot ($predecessors[$Phase] + '\result.json')) }
        if ($Phase -eq 'Audit') {
            Assert-Candidate $previous.candidate
            $capture = Read-Json (Join-Path $runRoot 'capture\result.json'); Assert-Candidate $capture.candidate
        }
    }
    $before = Get-SiblingState 'before'
    $phaseResult.siblingsBefore = $before
    Assert-SelectedCore $before
    $phaseResult.source = Get-SourceEvidence
    if ($Phase -eq 'Preflight') {
        $phaseResult.candidate = Get-Candidate @($PSCommandPath, $packetPath, $sourceManifestPath)
        $phaseResult.toolchain = Get-Toolchain
        if ($phaseResult.toolchain.pythonVersion -ne 'Python 3.14.5') { throw 'Selected Python must be exactly3.14.5.' }
        $phaseResult.existingRuntime = @{ exists = (Test-Path -LiteralPath $runtimeRoot); verified = $false }
        if (Test-Path -LiteralPath $runtimeRoot) {
            if (-not (Test-Path -LiteralPath $provenancePath -PathType Leaf)) { throw 'Existing unverified runtime must be preserved; no automatic replacement.' }
            Assert-Runtime; $phaseResult.existingRuntime.verified = $true
        }
        $null = Invoke-OwnedProcess 'source-build-identity' $selectedPython @('-I', '-B', (Join-Path $coreRoot 'scripts\build_engine_build_identity.py'), '--check') $runRoot
        $phaseResult.checks.Add(@{ id = 'python-preflight'; status = 'NOT_RUN'; reason = 'Deferred until Capture after the harness candidate is frozen and reviewed; wrapper source/inventory checks ran independently.' })
        $phaseResult.status = 'SOURCE_INVENTORY_PASS'
    } elseif ($Phase -eq 'PrepareRuntime') {
        if (Test-Path -LiteralPath $runtimeRoot) {
            Assert-Runtime
            $phaseResult.runtime.reusedVerifiedEnvironment = $true
            $phaseResult.status = 'INSTALLED_RUNTIME_PASS'
        } else {
        # A bounded reservation/provenance file serializes installs across RunIds.
        # Never remove it here: an interrupted/failed attempt stays inspectable.
        $reservationPath = Assert-ChildPath ($runtimeRoot + '.e01-reservation.json') $projectRoot
        $runtimeLock = [IO.File]::Open($reservationPath, [IO.FileMode]::CreateNew, [IO.FileAccess]::ReadWrite, [IO.FileShare]::Read)
        $reservation = $utf8.GetBytes((@{ runId = $RunId; runtime = $runtimeRoot; startedUtc = [datetime]::UtcNow.ToString('o') } | ConvertTo-Json) + "`n")
        $runtimeLock.Write($reservation, 0, $reservation.Length); $runtimeLock.Flush()
        if (Test-Path -LiteralPath $runtimeRoot) { throw 'PrepareRuntime refuses a preexisting environment; preserve it and use its verified originating run.' }
        $archivePath = Join-Path $runRoot 'core-source.zip'
        if (Test-Path -LiteralPath $archivePath) { throw 'Source archive collision.' }
        # Archive conversion otherwise inherits checkout autocrlf settings even
        # though extraction must retain the exact committed Git blob bytes.
        $null = Invoke-Git 'archive-core' $coreRoot @('-c', 'core.autocrlf=false', '-c', 'core.eol=lf',
            'archive', '--format=zip', "--output=$archivePath", $expectedCommit)
        $sourceRoot = Join-Path $runRoot 'source'
        $phaseResult.archive = Expand-OwnedArchive $archivePath $sourceRoot
        $manifest = Read-Json $sourceManifestPath
        foreach ($member in $manifest.SourceFiles) {
            if ((Get-GitBlobHash (Get-MemberPath $sourceRoot $member.Path)) -ne $member.GitBlob) { throw "Extracted committed member mismatch: $($member.Path)" }
        }
        $sourceHashes = @(foreach ($entry in $normalizedSourceHashes.GetEnumerator()) {
            $path = Get-MemberPath $sourceRoot $entry.Key
            $normalized = Get-NormalizedHash $path
            if ($normalized -ne $entry.Value) { throw "Extracted source identity mismatch: $($entry.Key)" }
            @{ path = $entry.Key; normalizedSha256 = $normalized; rawSha256 = Get-Hash $path }
        })
        $null = Invoke-OwnedProcess 'uv-sync' $uvPath @('sync', '--project', $sourceRoot, '--locked', '--no-editable', '--no-default-groups',
            '--python', $selectedPython, '--no-python-downloads', '--cache-dir', (Join-Path $runRoot 'cache\uv'),
            '--default-index', 'https://pypi.org/simple', '--no-config', '--no-progress') $sourceRoot @{ UV_PROJECT_ENVIRONMENT = $runtimeRoot }
        $null = Invoke-OwnedProcess 'uv-pip-check' $uvPath @('pip', 'check', '--python', $runtimePython, '--no-config', '--no-progress') $runRoot
        $installed = Invoke-InstalledVerification 'installed-identity'
        foreach ($source in $sourceHashes) {
            $path = Get-MemberPath $sourceRoot $source.path
            if ((Get-Hash $path) -ne $source.rawSha256 -or (Get-NormalizedHash $path) -ne $source.normalizedSha256) { throw 'Install input changed during runtime preparation.' }
        }
        $tree = Get-RuntimeTree
        $provenance = [ordered]@{ schemaVersion = 1; status = 'INSTALLED_RUNTIME_PASS'; runId = $RunId; coreCommit = $expectedCommit
            runtimeBuildId = $expectedBuild; runtimeResourceCount = 3116; archive = $archivePath; archiveSha256 = Get-Hash $archivePath
            sourceManifestSha256 = Get-Hash $sourceManifestPath; sourceHashes = $sourceHashes
            uvSha256 = Get-Hash $uvPath; selectedPythonSha256 = Get-Hash $selectedPython; installed = $installed
            runtimeTree = $tree; runtimeTreeSha256 = Get-RuntimeTreeHash $tree
            createdUtc = [datetime]::UtcNow.ToString('o') }
        Write-NewJson $provenancePath $provenance
        $phaseResult.runtime = @{ provenance = $provenancePath; provenanceSha256 = Get-Hash $provenancePath
            runtimeTreeSha256 = $provenance.runtimeTreeSha256; installed = $installed; sourceHashes = $sourceHashes }
        $phaseResult.status = 'INSTALLED_RUNTIME_PASS'
        }
    } elseif ($Phase -eq 'Capture') {
        Assert-Runtime
        $phaseResult.candidate = Get-Candidate @($PSCommandPath, $harnessPath, $unitTestsPath, $sourceManifestPath, $packetPath)
        $null = Invoke-Harness 'preflight' $runtimePython 'python-preflight'
        $null = Invoke-Harness 'verify-runtime' $runtimePython 'python-runtime'
        $null = Invoke-OwnedProcess 'python-unittest' $runtimePython @('-I', '-B', $unitTestsPath) $runRoot
        $unitLog = [IO.File]::ReadAllText((Join-Path $phaseRoot 'python-unittest.stdout.log')) + [IO.File]::ReadAllText((Join-Path $phaseRoot 'python-unittest.stderr.log'))
        $unitCount = [regex]::Match($unitLog, 'Ran ([1-9][0-9]*) tests? in ')
        if (-not $unitCount.Success -or $unitLog -match '(?i)skipped=|FAILED|expected failures=|unexpected successes=') { throw 'Python unit suite must run a positive count without skipped/failed cases.' }
        $phaseResult.unitTests = @{ executed = [int]$unitCount.Groups[1].Value; status = 'PASS' }
        $null = Invoke-Harness 'capture' $runtimePython 'python-capture'
        Assert-Candidate $phaseResult.candidate
        $phaseResult.status = 'LOCAL_HTTP_BOUNDARY_PASS'
    } elseif ($Phase -eq 'Native') {
        Assert-Runtime
        Assert-Candidate $previous.candidate
        $phaseResult.toolchain = Get-Toolchain
        foreach ($key in @('engineVersionSha256', 'compilerSha256', 'selectedPythonSha256', 'uvSha256')) {
            if ($phaseResult.toolchain[$key] -ne $preflight.toolchain[$key]) { throw 'Native toolchain bytes changed after Preflight.' }
        }
        $phaseResult.ubtSettingsBefore = Get-UBTSettings
        $nativePaths = @('Source/WarhammerClient/Private/Migration/CoreBoundaryEvidence.h',
            'Source/WarhammerClient/Private/Migration/CoreBoundaryEvidence.cpp',
            'Source/WarhammerClient/Private/Tests/CoreBoundaryEvidenceTests.cpp', 'Source/WarhammerClient/WarhammerClient.Build.cs',
            'Source/WarhammerClient.Target.cs', 'Source/WarhammerClientEditor.Target.cs', 'WarhammerClient.uproject')
        $phaseResult.candidate = Get-Candidate (@($nativePaths | ForEach-Object { Join-Path $projectRoot $_ }) + @($PSCommandPath, $sourceManifestPath, $packetPath))
        $wireIndex = Join-Path $fixtureRoot 'wire\index.json'
        $index = Read-Json $wireIndex
        if ($index.format_version -ne 1 -or $index.cases.Count -eq 0) { throw 'Reviewed nonempty wire fixture index is required.' }
        $phaseResult.fixtureFiles = @(@{ path = $wireIndex; sha256 = Get-Hash $wireIndex }) + @(foreach ($case in $index.cases) {
            $path = Get-MemberPath (Join-Path $fixtureRoot 'wire') $case.path
            if ((Get-Hash $path) -ne $case.sha256.ToLowerInvariant()) { throw 'Reviewed wire fixture changed.' }
            @{ path = $path; sha256 = Get-Hash $path }
        })
        $project = Join-Path $projectRoot 'WarhammerClient.uproject'
        $build = Join-Path $EngineRoot 'Engine\Build\BatchFiles\Build.bat'
        $buildLog = Join-Path $runRoot 'native-build.log'
        $uba = New-OwnedDirectory (Join-Path $runRoot 'uba') $runRoot
        # Constant worker code receives paths through an isolated environment;
        # no supplied text is interpolated into shell code or re-evaluated.
        $buildWorker = '& $env:E01_BUILD_SCRIPT @("WarhammerClientEditor", "Win64", "Development", ("-Project=" + $env:E01_PROJECT), "-WaitMutex", "-NoUBA", ("-UBARootDir=" + $env:E01_UBA), ("-Log=" + $env:E01_BUILD_LOG)); if ($null -eq $LASTEXITCODE) { exit 99 }; exit $LASTEXITCODE'
        $pwsh = (Get-Process -Id $PID).Path
        $null = Invoke-OwnedProcess 'native-build' $pwsh @('-NoLogo', '-NoProfile', '-NonInteractive', '-Command', $buildWorker) $runRoot @{
            E01_BUILD_SCRIPT = $build; E01_PROJECT = $project; E01_UBA = $uba; E01_BUILD_LOG = $buildLog; UE_USE_SYSTEM_DOTNET = '0' }
        $editor = Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor-Cmd.exe'
        $automationRoot = Join-Path $runRoot 'automation'
        $userRoot = New-OwnedDirectory (Join-Path $runRoot 'ue-user') $runRoot
        $ddcRoot = New-OwnedDirectory (Join-Path $runRoot 'ddc') $runRoot
        $null = Invoke-OwnedProcess 'native-automation' $editor @($project, '-unattended', '-nop4', '-NullRHI', '-nosplash',
            '-ExecCmds=Automation RunTests Warhammer.Migration.E01Boundary', '-TestExit=Automation Test Queue Empty',
            "-ReportExportPath=$automationRoot", "-log=$(Join-Path $runRoot 'native-automation.log')", "-E01FixtureRoot=$fixtureRoot",
            "-UserDir=$userRoot", '-DDC=(EnginePak=InstalledEnginePak,Local)', '-DDC-NoDefaultGraph', "-LocalDataCachePath=$ddcRoot") $runRoot
        $phaseResult.automation = Get-AutomationEvidence (Join-Path $automationRoot 'index.json')
        $phaseResult.nativeArtifacts = @((Get-SafeArtifact $buildLog), (Get-SafeArtifact (Join-Path $runRoot 'native-automation.log')),
            (Get-SafeArtifact (Join-Path $automationRoot 'index.json')))
        $phaseResult.ubtSettingsAfter = Get-UBTSettings
        Assert-UBTSettings $phaseResult.ubtSettingsBefore $phaseResult.ubtSettingsAfter
        foreach ($file in $phaseResult.fixtureFiles) { if ((Get-Hash $file.path) -ne $file.sha256) { throw 'Native fixture changed during execution.' } }
        Assert-Candidate $phaseResult.candidate
        $phaseResult.status = 'NATIVE_FIXTURE_PASS'
    } else {
        Assert-Runtime
        foreach ($file in $previous.fixtureFiles) { if ((Get-Hash $file.path) -ne $file.sha256) { throw 'Accepted native fixture changed before audit.' } }
        $null = Invoke-Harness 'audit' $runtimePython 'python-audit' (Join-Path $runRoot 'capture\python-capture')
        $phaseResult.status = 'EVIDENCE_GATHERED_REQUIRES_INDEPENDENT_AUDIT'
    }
    $after = Get-SiblingState 'after'
    $phaseResult.siblingsAfter = $after
    Assert-SelectedCore $after
    Assert-SameSiblings $before $after
    if ($Phase -ne 'Preflight') {
        Assert-SameSiblings $preflight.siblingsBefore $before
        Assert-Candidate $preflight.candidate
    }
    $phaseResult.redaction.status = 'PASS'
} catch {
    $failure = $_.Exception.Message
    try { Assert-SafeText $failure } catch { $failure = 'Credential scan rejected failure details; original output was not exported.' }
    if ($null -ne $phaseResult) {
        $phaseResult.status = 'FAIL'
        $phaseResult.failure = $failure
        $phaseResult.redaction.status = if ($failure -like '*Credential scan*') { 'REJECTED_QUARANTINED' } else { 'SCANNED_PARTIAL' }
        try { $phaseResult.siblingsAfterFailure = Get-SiblingState 'failed-after' }
        catch { $phaseResult.siblingAfterFailureCheck = 'UNAVAILABLE; inspect preserved sanitized process logs' }
        if ($phaseResult.Contains('ubtSettingsBefore')) {
            try { $phaseResult.ubtSettingsAfterFailure = Get-UBTSettings; Assert-UBTSettings $phaseResult.ubtSettingsBefore $phaseResult.ubtSettingsAfterFailure }
            catch { $phaseResult.ubtSettingsFailure = 'Global UBT guard changed or could not be inspected.' }
        }
    }
} finally {
    if ($null -ne $phaseResult) {
        $phaseResult.completedUtc = [datetime]::UtcNow.ToString('o')
        try { Write-NewJson (Join-Path $phaseRoot 'result.json') $phaseResult }
        catch { if ($null -eq $failure) { $failure = 'Could not safely export the phase result; preserve the run for inspection.' } }
    }
    if ($null -ne $runtimeLock) { $runtimeLock.Dispose() }
    if ($null -ne $runLock) { $runLock.Dispose() }
}
if ($null -ne $failure) { Write-Error $failure; exit 1 }
Write-Host "E01 $RunId/${Phase}: $($phaseResult.status). Result: $(Join-Path $phaseRoot 'result.json')"
