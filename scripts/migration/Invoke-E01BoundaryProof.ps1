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
    [string] $EngineRoot = 'C:\Program Files\Epic Games\UE_5.8',
    [string] $CaptureRunId = ''
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
$linkedCapture = $null
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

function Assert-SafeStructuredNode($Value, [int] $Depth, [ref] $Nodes) {
    $Nodes.Value++
    if ($Depth -gt 80 -or $Nodes.Value -gt 1000000) { throw 'Structured evidence exceeds its depth or node bound.' }
    if ($null -eq $Value) { return }
    if ($Value -is [string]) {
        if ($Value.Length -gt 64MB) { throw 'Structured evidence string exceeds its size bound.' }
        Assert-SafeText $Value
        return
    }
    if ($Value -is [bool] -or $Value -is [byte] -or $Value -is [sbyte] -or $Value -is [int16] -or $Value -is [uint16] -or
        $Value -is [int32] -or $Value -is [uint32] -or $Value -is [int64] -or $Value -is [uint64] -or $Value -is [decimal]) { return }
    if ($Value -is [datetime] -or $Value -is [datetimeoffset]) { Assert-SafeText $Value.ToString('o'); return }
    if ($Value -is [double] -or $Value -is [single]) {
        if (-not [double]::IsFinite([double]$Value)) { throw 'Structured evidence contains a non-finite number.' }
        return
    }
    if ($Value -is [Collections.IDictionary]) {
        $type = $Value.GetType()
        $knownDictionary = ($type.FullName -in @('System.Collections.Hashtable', 'System.Collections.Specialized.OrderedDictionary', 'System.Management.Automation.OrderedHashtable') -and
            $type.Assembly -in @([hashtable].Assembly, [Collections.Specialized.OrderedDictionary].Assembly, [Management.Automation.PSObject].Assembly)) -or
            ($type.IsGenericType -and $type.GetGenericTypeDefinition() -eq [Collections.Generic.Dictionary[string, object]].GetGenericTypeDefinition())
        if (-not $knownDictionary) { throw 'Structured evidence contains an unsupported dictionary implementation.' }
        foreach ($entry in $Value.GetEnumerator()) {
            if ($entry.Key -isnot [string]) { throw 'Structured evidence requires string dictionary keys.' }
            Assert-SafeStructuredNode $entry.Key ($Depth + 1) $Nodes
            Assert-SafeStructuredNode $entry.Value ($Depth + 1) $Nodes
        }
        return
    }
    if ($Value -is [Collections.IList]) {
        $type = $Value.GetType()
        if (-not ($type.IsArray -or $type -eq [Collections.ArrayList] -or
            ($type.IsGenericType -and $type.GetGenericTypeDefinition() -eq [Collections.Generic.List[object]].GetGenericTypeDefinition()))) {
            throw 'Structured evidence contains an unsupported list implementation.'
        }
        foreach ($member in $Value) { Assert-SafeStructuredNode $member ($Depth + 1) $Nodes }
        return
    }
    if ($Value -is [pscustomobject]) {
        foreach ($property in $Value.PSObject.Properties) {
            if ($property.MemberType -ne [Management.Automation.PSMemberTypes]::NoteProperty) { throw 'Structured evidence cannot invoke custom property getters.' }
            Assert-SafeStructuredNode $property.Name ($Depth + 1) $Nodes
            Assert-SafeStructuredNode $property.Value ($Depth + 1) $Nodes
        }
        return
    }
    throw 'Structured evidence contains an unsupported value type.'
}

function Assert-SafeStructuredValue($Value) {
    $nodes = 0
    Assert-SafeStructuredNode $Value 0 ([ref]$nodes)
}

function Assert-SafeJsonElement($Element, [ref] $Nodes) {
    $Nodes.Value++
    if ($Nodes.Value -gt 1000000) { throw 'Decoded JSON exceeds its node bound.' }
    switch ($Element.ValueKind.ToString()) {
        'String' { Assert-SafeText $Element.GetString() }
        'Object' { foreach ($property in $Element.EnumerateObject()) { Assert-SafeText $property.Name; Assert-SafeJsonElement $property.Value $Nodes } }
        'Array' { foreach ($member in $Element.EnumerateArray()) { Assert-SafeJsonElement $member $Nodes } }
    }
}

function Assert-SafeDecodedJson([string] $Text) {
    $options = [Text.Json.JsonDocumentOptions]::new(); $options.MaxDepth = 80
    $document = [Text.Json.JsonDocument]::Parse($Text, $options)
    try { $nodes = 0; Assert-SafeJsonElement $document.RootElement ([ref]$nodes) }
    finally { $document.Dispose() }
}

function Get-SafeFailureEvidence([Management.Automation.ErrorRecord] $ErrorRecord, [string] $Stage) {
    $exception = $ErrorRecord.Exception
    $record = @{ stage = $Stage; type = $exception.GetType().FullName; details = $exception.Message; redaction = 'PASS' }
    $causes = [Collections.Generic.List[object]]::new()
    $inner = $exception.InnerException
    for ($depth = 0; $null -ne $inner -and $depth -lt 8; $depth++) {
        $causes.Add(@{ type = $inner.GetType().FullName; details = $inner.Message })
        $inner = $inner.InnerException
    }
    $record.causes = @($causes)
    $record.causesTruncated = $null -ne $inner
    try { Assert-SafeStructuredValue $record }
    catch {
        # Retain no rejected value, message fragment or hash of secret material.
        $safeStage = $Stage; $safeType = $exception.GetType().FullName
        try { Assert-SafeText ($safeStage + "`n" + $safeType) }
        catch { $safeStage = 'redacted-diagnostic'; $safeType = 'REDACTED' }
        $record = @{ stage = $safeStage; type = $safeType
            details = 'Credential scan rejected diagnostic details; original details were not retained.'; redaction = 'REJECTED_NOT_RETAINED' }
    }
    return $record
}

function New-JsonOutputStream([string] $Path) {
    return [IO.File]::Open($Path, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::Read)
}

function Write-NewJson([string] $Path, $Value, [Collections.Generic.List[object]] $SecondaryErrors = $null) {
    $absolute = Assert-ChildPath $Path $projectRoot
    if (Test-Path -LiteralPath $absolute) { throw 'Refusing an existing JSON output collision.' }
    Assert-SafeStructuredValue $Value
    $json = (ConvertTo-Json -InputObject $Value -Depth 80 -WarningAction Stop) + "`n"
    Assert-SafeText $json
    $bytes = $utf8.GetBytes($json)
    if ($bytes.Length -gt 64MB) { throw 'Structured JSON output exceeds its size bound.' }
    $partial = $absolute + '.partial-' + [guid]::NewGuid().ToString('N')
    $stream = $null; $exportFailure = $null
    try { $stream = New-JsonOutputStream $partial; $stream.Write($bytes, 0, $bytes.Length); $stream.Flush() }
    catch { $exportFailure = $_ }
    finally {
        if ($null -ne $stream) {
            try { $stream.Dispose() }
            catch {
                if ($null -eq $exportFailure) { $exportFailure = $_ }
                elseif ($null -ne $SecondaryErrors) { $SecondaryErrors.Add((Get-SafeFailureEvidence $_ 'json-stream-dispose')) }
            }
        }
    }
    if ($null -ne $exportFailure) { throw $exportFailure }
    # The final pathname is published only after every stream finalizer succeeds.
    # Partial bytes remain immutable evidence on failure; never replace a result.
    [IO.File]::Move($partial, $absolute, $false)
}

function Read-Json([string] $Path) {
    Require-File $Path
    if ([IO.FileInfo]::new($Path).Length -gt 64MB) { throw 'JSON evidence input exceeds its size bound.' }
    $text = [IO.File]::ReadAllText($Path, $utf8)
    Assert-SafeText $text
    Assert-SafeDecodedJson $text
    $value = $text | ConvertFrom-Json -AsHashtable -Depth 80 -NoEnumerate
    Assert-SafeStructuredValue $value
    return ,$value
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

function New-OwnedProcessHandle([Diagnostics.ProcessStartInfo] $StartInfo) {
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $StartInfo
    return $process
}

function New-OwnedLogWriter([string] $Path) {
    return [IO.StreamWriter]::new($Path, $false, $utf8)
}

function Get-OwnedProcessIdentity([int] $ProcessId) {
    return [Diagnostics.Process]::GetProcessById($ProcessId)
}

function Add-OwnedProcessSecondaryFailure([Collections.IDictionary] $Record,
    [Management.Automation.ErrorRecord] $ErrorRecord, [string] $Stage) {
    $Record.secondaryErrors.Add((Get-SafeFailureEvidence $ErrorRecord $Stage))
}

function Stop-OwnedProcess($Process, [datetime] $StartedUtc, [Collections.IDictionary] $Record) {
    $current = $null; $stopFailure = $null
    try {
        if (-not $Process.get_HasExited()) {
            $processId = $Process.get_Id()
            if ($processId -ne $Record.pid) {
                $Record.terminationRefused = $true
                $Record.terminationRefusalReason = 'Original process handle PID differs from the retained identity; no PID was terminated.'
                throw 'Owned PID identity changed; refusing termination.'
            }
            $current = Get-OwnedProcessIdentity $processId
            if ($current.get_StartTime().ToUniversalTime().Ticks -ne $StartedUtc.Ticks) {
                $Record.terminationRefused = $true
                $Record.terminationRefusalReason = 'PID/start-time identity check failed; no PID was terminated.'
                throw 'Owned PID identity changed; refusing termination.'
            }
            $Process.Kill($true)
            if (-not $Process.WaitForExit(10000)) { throw 'Owned process tree did not stop within ten seconds.' }
        }
        $Record.exitConfirmed = $true
        $Record.exitedUtc = [datetime]::UtcNow.ToString('o')
    } catch { $stopFailure = $_ }
    finally {
        if ($null -ne $current) {
            try { $current.Dispose() }
            catch {
                Add-OwnedProcessSecondaryFailure $Record $_ 'cleanup-identity-handle-dispose'
                if ($null -eq $stopFailure) { $stopFailure = $_ }
            }
        }
    }
    if ($null -ne $stopFailure) { throw $stopFailure }
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
    $record = [ordered]@{ label = $Label; executable = $Executable; executableSha256 = Get-Hash $Executable
        arguments = $Arguments; workingDirectory = $WorkingDirectory; timeoutSeconds = $MaximumMilliseconds / 1000
        pid = $null; startedUtc = $null; exitedUtc = $null; endedUtc = $null; exitCode = $null; timedOut = $false
        startAttempted = $false; startConfirmed = $false; exitConfirmed = $null; exitInspection = 'NOT_STARTED'
        startIdentityComplete = $false; identityRecoveryAttempted = $false; identityRecoveredForCleanup = $false; terminationRefused = $false
        cleanupStatus = 'NOT_STARTED'; stdoutClosed = $false; stderrClosed = $false; handleDisposed = $false
        ownership = 'Original process handle; termination requires matching PID/start time'
        secondaryErrors = [Collections.Generic.List[object]]::new()
        redaction = 'PENDING'; stdout = $stdoutPath; stderr = $stderrPath }
    $phaseResult.processes.Add($record)
    $process = $null; $stdoutWriter = $null; $stderrWriter = $null; $primaryError = $null; $capturedText = $null
    $captured = [Text.StringBuilder]::new()
    $watch = [Diagnostics.Stopwatch]::StartNew()
    $lastProgress = 0L
    $startedUtc = $null
    $logBytes = 0L
    $processStage = 'create-process-handle'
    try {
        $process = New-OwnedProcessHandle $start
        $processStage = 'create-stdout-log'; $stdoutWriter = New-OwnedLogWriter $stdoutPath
        $processStage = 'configure-stdout-log'; $stdoutWriter.set_AutoFlush($true)
        $processStage = 'create-stderr-log'; $stderrWriter = New-OwnedLogWriter $stderrPath
        $processStage = 'configure-stderr-log'; $stderrWriter.set_AutoFlush($true)
        $processStage = 'start-process'; $record.startAttempted = $true
        if (-not $process.Start()) { throw 'Child process did not start.' }
        $record.startConfirmed = $true
        $processStage = 'read-start-process-id'
        $record.pid = $process.get_Id()
        $processStage = 'read-start-process-time'
        $startedUtc = $process.get_StartTime().ToUniversalTime()
        $record.startedUtc = $startedUtc.ToString('o')
        $record.startIdentityComplete = $true
        $processStage = 'read-process-output'
        $outTask = $process.StandardOutput.ReadLineAsync()
        $errTask = $process.StandardError.ReadLineAsync()
        $outDone = $false; $errDone = $false
        while (-not ($process.get_HasExited() -and $outDone -and $errDone)) {
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
        $processStage = 'wait-process-exit'
        $process.WaitForExit()
        $record.exitConfirmed = $true; $record.exitedUtc = [datetime]::UtcNow.ToString('o')
        $processStage = 'read-process-exit-code'
        $record.exitCode = $process.get_ExitCode()
        $record.redaction = 'PASS'
        if ($record.exitCode -ne 0) { throw "Child process failed: $Label (exit $($record.exitCode)); inspect its sanitized logs." }
        $capturedText = $captured.ToString().TrimEnd()
    } catch {
        $primaryError = $_
        $record.primaryFailure = Get-SafeFailureEvidence $primaryError $processStage
        $record.redaction = if ($_.Exception.Message -like 'Credential scan*') { 'REJECTED_QUARANTINED' } else { 'SCANNED_PARTIAL' }
        if ($record.startConfirmed -and $null -eq $startedUtc) {
            # Start succeeded, but identity inspection did not. Recover only
            # through this original handle; never substitute an unverified PID.
            $record.identityRecoveryAttempted = $true
            $record.identityRecoveryUtc = [datetime]::UtcNow.ToString('o')
            try {
                $cleanupId = $process.get_Id()
                if ($null -ne $record.pid -and $cleanupId -ne $record.pid) { throw 'Original process handle PID changed during start-identity recovery.' }
                $cleanupStartUtc = $process.get_StartTime().ToUniversalTime()
                $record.pid = $cleanupId; $startedUtc = $cleanupStartUtc
                $record.startedUtc = $startedUtc.ToString('o'); $record.startIdentityComplete = $true
                $record.identityRecoveredForCleanup = $true
            } catch {
                Add-OwnedProcessSecondaryFailure $record $_ 'cleanup-recover-start-identity'
                $record.terminationRefused = $true
                $record.terminationRefusalReason = 'PID/start-time identity could not be established from the original handle; no PID was terminated.'
            }
        }
        if ($null -ne $startedUtc) {
            try { Stop-OwnedProcess $process $startedUtc $record }
            catch { Add-OwnedProcessSecondaryFailure $record $_ 'cleanup-stop-process' }
        }
    } finally {
        if ($null -ne $process -and $record.startConfirmed) {
            try {
                # Invoke getters as methods so PowerShell cannot turn a throwing
                # property getter into a null value and conceal inspection loss.
                $hasExited = $process.get_HasExited()
                $record.exitInspection = if ($hasExited) { 'CONFIRMED_EXIT' } else { 'STILL_RUNNING' }
                if ($hasExited) {
                    $record.exitConfirmed = $true
                    if ($null -eq $record.exitedUtc) { $record.exitedUtc = [datetime]::UtcNow.ToString('o') }
                    try { $record.exitCode = $process.get_ExitCode() }
                    catch { Add-OwnedProcessSecondaryFailure $record $_ 'finalize-exit-code'; if ($null -eq $primaryError) { $primaryError = $_ } }
                }
            } catch {
                $record.exitInspection = 'UNAVAILABLE'
                Add-OwnedProcessSecondaryFailure $record $_ 'finalize-exit-inspection'
                if ($null -eq $primaryError) { $primaryError = $_ }
            }
        }
        foreach ($lane in @('stdout', 'stderr')) {
            $writer = if ($lane -eq 'stdout') { $stdoutWriter } else { $stderrWriter }
            if ($null -ne $writer) {
                try { $writer.Dispose(); $record[$lane + 'Closed'] = $true }
                catch {
                    Add-OwnedProcessSecondaryFailure $record $_ ('finalize-' + $lane + '-log')
                    if ($null -eq $primaryError) { $primaryError = $_ }
                }
            }
        }
        if ($null -ne $process) {
            try { $process.Dispose(); $record.handleDisposed = $true }
            catch { Add-OwnedProcessSecondaryFailure $record $_ 'finalize-process-handle'; if ($null -eq $primaryError) { $primaryError = $_ } }
        }
        $record.cleanupStatus = if ($record.exitConfirmed -eq $true) {
            if ($record.secondaryErrors.Count) { 'STOPPED_WITH_ERRORS' } else { 'STOPPED' }
        } elseif ($record.terminationRefused) { 'REFUSED_UNVERIFIED_IDENTITY' }
        elseif ($record.startAttempted) { 'EXIT_UNCONFIRMED' } else { 'NOT_STARTED' }
        $record.endedUtc = [datetime]::UtcNow.ToString('o')
    }
    if ($null -ne $primaryError) {
        if (-not $record.Contains('primaryFailure')) { $record.primaryFailure = Get-SafeFailureEvidence $primaryError 'process-finalization' }
        if ($record.redaction -eq 'PASS') { $record.redaction = 'SCANNED_PARTIAL' }
        throw $primaryError
    }
    return $capturedText
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

function Get-PythonUnitEvidence([string] $LogText) {
    $normalized = $LogText.Replace("`r`n", "`n").Replace("`r", "`n")
    $summaries = [regex]::Matches($normalized, '(?m)^Ran ([0-9]+) (test|tests) in ([0-9]+(?:\.[0-9]+)?)s$')
    if ($summaries.Count -ne 1) { throw 'Python unit log requires exactly one standard anchored unittest summary.' }
    $summary = $summaries[0]
    $count = 0
    $seconds = 0.0
    if (-not [int]::TryParse($summary.Groups[1].Value, [ref]$count) -or $count -le 0 -or
        $summary.Groups[2].Value -cne $(if ($count -eq 1) { 'test' } else { 'tests' }) -or
        -not [double]::TryParse($summary.Groups[3].Value, [Globalization.NumberStyles]::AllowDecimalPoint,
            [Globalization.CultureInfo]::InvariantCulture, [ref]$seconds) -or -not [double]::IsFinite($seconds)) {
        throw 'Python unittest summary requires a positive count and finite duration.'
    }
    $footer = $normalized.Substring($summary.Index + $summary.Length)
    if ($footer -cnotmatch '\A\n+OK\n*\z') {
        throw 'Python unittest final footer must be exactly OK without annotations or trailing output.'
    }
    return @{ executed = $count; status = 'PASS'; durationSeconds = $seconds; summary = $summary.Value; footer = 'OK' }
}

function Get-CurrentCaptureWireEvidence {
    if ($CaptureRunId) { throw 'Current-run wire binding cannot replace the historical Capture supplement.' }
    $capturePath = Assert-ChildPath (Join-Path $runRoot 'capture\result.json') $runRoot
    $captureHash = Get-Hash $capturePath
    $capture = Read-Json $capturePath
    if ($capture.schemaVersion -ne 1 -or $capture.packet -cne 'E01-WIN-BOUNDARY' -or $capture.phase -cne 'Capture' -or
        $capture.runId -cne $RunId -or $capture.runRoot -cne $runRoot -or $capture.status -cne 'LOCAL_HTTP_BOUNDARY_PASS' -or
        $capture.redaction.status -cne 'PASS' -or $capture.unitTests.status -cne 'PASS' -or
        ($capture.unitTests.executed -isnot [long] -and $capture.unitTests.executed -isnot [int]) -or $capture.unitTests.executed -le 0) {
        throw 'Current Capture identity, status or positive unit-test count failed.'
    }
    $candidatePaths = @($PSCommandPath, $packetPath, $harnessPath, $unitTestsPath, $sourceManifestPath)
    $seenCandidates = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    if ($capture.candidate.files.Count -ne $candidatePaths.Count) { throw 'Current Capture candidate must contain exactly five reviewed files.' }
    foreach ($file in $capture.candidate.files) {
        if ($file.path -notin $candidatePaths -or -not $seenCandidates.Add($file.path)) { throw 'Current Capture candidate path set differs.' }
    }
    Assert-Candidate $capture.candidate
    if ($capture.source.coreCommit -cne $expectedCommit -or $capture.source.contractVersion -cne '44.3.33' -or
        $capture.source.runtimeBuildId -cne $expectedBuild -or $capture.source.sourceManifestSha256 -cne (Get-Hash $sourceManifestPath)) {
        throw 'Current Capture source identity differs from the reviewed fixture inventory.'
    }
    $preparePath = Join-Path $runRoot 'prepareruntime\result.json'
    $prepare = Read-Json $preparePath
    if ($prepare.phase -cne 'PrepareRuntime' -or $prepare.runId -cne $RunId -or $prepare.status -cne 'INSTALLED_RUNTIME_PASS' -or
        $capture.predecessor.path -cne $preparePath -or $capture.predecessor.sha256 -cne (Get-Hash $preparePath)) {
        throw 'Current Capture does not link the same run prepared runtime.'
    }
    foreach ($runtime in @($capture.runtime, $prepare.runtime)) {
        foreach ($key in @('provenance', 'provenanceSha256', 'runtimeTreeSha256')) {
            if ($runtime[$key] -cne $phaseResult.runtime[$key]) { throw 'Current Capture and verified native runtime identities differ.' }
        }
    }
    $requirements = @{
        preflight = @{ relative = 'python-preflight'; status = 'SOURCE_INVENTORY_PASS'; ids = @('SOURCE-01') }
        'verify-runtime' = @{ relative = 'python-runtime'; status = 'INSTALLED_RUNTIME_PASS'; ids = @('SOURCE-01', 'RUNTIME-01') }
        capture = @{ relative = 'python-capture'; status = 'LOCAL_HTTP_BOUNDARY_PASS'; ids = @('SOURCE-01', 'RUNTIME-01', 'SCHEMA-01', 'SCOPE-01', 'AUTH-01', 'VIEW-01', 'FINITE-01', 'RETRY-01', 'STALE-01', 'FIDELITY-01', 'MOVE-01', 'MOVE-02', 'ERROR-01', 'LIFETIME-01') }
    }
    if ($capture.childReports.Count -ne 3) { throw 'Current Capture child report count differs.' }
    $seenReports = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $captureReport = $null; $captureReportPath = $null; $captureArtifacts = $null
    foreach ($child in $capture.childReports) {
        if (-not $seenReports.Add($child.phase) -or $child.phase -cnotin @('preflight', 'verify-runtime', 'capture')) { throw 'Current Capture child report identity differs.' }
        $required = $requirements[$child.phase]
        $reportRoot = Assert-ChildPath (Join-Path $runRoot ("capture\" + $required.relative)) $runRoot
        $reportPath = Join-Path $reportRoot 'report.json'
        if ($child.path -cne $reportPath -or $child.sha256 -cnotmatch '^[0-9a-f]{64}$' -or
            $child.sha256 -cne (Get-Hash $reportPath) -or $child.status -cne $required.status) { throw 'Current Capture child path/hash/status differs.' }
        $report = Read-Json $reportPath
        if ($report.schemaVersion -ne 1 -or $report.phase -cne $child.phase -or $report.status -cne $required.status -or $report.redaction.status -cne 'PASS') {
            throw 'Current Capture child report identity or redaction failed.'
        }
        foreach ($counts in @($child.caseCounts, $report.caseCounts)) {
            if ($counts.discovered -ne $required.ids.Count -or $counts.executed -ne $required.ids.Count -or $counts.passed -ne $required.ids.Count -or
                $counts.failed -ne 0 -or $counts.blocked -ne 0 -or $counts.notRun -ne 0) { throw 'Current Capture child case counts did not all pass.' }
        }
        $seenCases = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        if ($report.cases.Count -ne $required.ids.Count) { throw 'Current Capture child case set differs.' }
        foreach ($case in $report.cases) {
            if ($case.id -cnotin $required.ids -or -not $seenCases.Add($case.id) -or $case.status -cne 'PASS') { throw 'Current Capture child case ID/status differs.' }
        }
        $artifacts = [Collections.Generic.Dictionary[string,object]]::new([StringComparer]::OrdinalIgnoreCase)
        foreach ($artifact in $report.artifacts) {
            $path = if ([IO.Path]::IsPathRooted($artifact.path)) { $artifact.path } else { Join-Path $reportRoot $artifact.path }
            $path = Assert-ChildPath $path $reportRoot
            if ($artifacts.ContainsKey($path) -or $artifact.sha256 -cnotmatch '^[0-9a-f]{64}$' -or
                (Get-Hash $path) -cne $artifact.sha256 -or [IO.FileInfo]::new($path).Length -ne $artifact.bytes) {
                throw 'Current Capture child artifact path/hash/length differs.'
            }
            $artifacts.Add($path, $artifact)
        }
        if ($child.phase -ceq 'capture') { $captureReport = $report; $captureReportPath = $reportPath; $captureArtifacts = $artifacts }
    }
    $sourceRoot = Assert-ChildPath (Join-Path $runRoot 'capture\python-capture\proposed-wire') $runRoot
    $wireRoot = Assert-ChildPath (Join-Path $fixtureRoot 'wire') $fixtureRoot
    $sourceIndex = Join-Path $sourceRoot 'index.json'; $wireIndex = Join-Path $wireRoot 'index.json'
    if ($null -eq $captureReport -or -not $captureArtifacts.ContainsKey($sourceIndex)) { throw 'Current Capture report must list its proposed wire index.' }
    $indexHash = Get-Hash $sourceIndex
    if ($captureArtifacts[$sourceIndex].sha256 -cne $indexHash -or (Get-Hash $wireIndex) -cne $indexHash -or
        [IO.FileInfo]::new($sourceIndex).Length -ne [IO.FileInfo]::new($wireIndex).Length) {
        throw 'Versioned wire index is not byte-identical to this run reported Capture index.'
    }
    $index = Read-Json $sourceIndex
    if ($index.format_version -ne 1 -or $index.cases.Count -ne 30) { throw 'Current Capture must contain exactly 30 indexed wire bodies.' }
    $paths = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $caseRoles = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $bodies = [Collections.Generic.List[object]]::new()
    foreach ($case in $index.cases) {
        if ($case.case_id -isnot [string] -or $case.case_id -cnotmatch '^[A-Za-z0-9_.:-]+$' -or
            $case.role -cnotin @('playerA', 'playerB', 'coach', 'delayed', 'replay', 'missing', 'invalid') -or $case.kind -cne 'http' -or
            $case.sha256 -cnotmatch '^[0-9a-f]{64}$' -or $case.expected_outcome -cnotin @('payload', 'accepted', 'recorded_invalid', 'uncommitted_invalid', 'error') -or
            ($case.http_status -isnot [long] -and $case.http_status -isnot [int]) -or $case.http_status -lt 100 -or $case.http_status -gt 599) {
            throw 'Current Capture wire row identity/role/outcome metadata is invalid.'
        }
        $expectedPath = $case.case_id.ToLowerInvariant().Replace(':', '_').Replace('.', '_') + '/' + $case.role + '.json'
        if ($case.path -cne $expectedPath -or -not $paths.Add($case.path) -or -not $caseRoles.Add($case.case_id + "`t" + $case.role)) {
            throw 'Current Capture wire row path/role identity is duplicate or inconsistent.'
        }
        if (($case.expected_outcome -cin @('accepted', 'payload') -and $case.http_status -ne 200) -or
            ($case.expected_outcome -cin @('recorded_invalid', 'uncommitted_invalid') -and $case.http_status -ne 422) -or
            ($case.expected_outcome -ceq 'error' -and $case.http_status -lt 400)) { throw 'Current Capture outcome/status metadata is inconsistent.' }
        $source = Get-MemberPath $sourceRoot $case.path; $target = Get-MemberPath $wireRoot $case.path
        if (-not $captureArtifacts.ContainsKey($source) -or $captureArtifacts[$source].sha256 -cne $case.sha256 -or
            (Get-Hash $source) -cne $case.sha256 -or (Get-Hash $target) -cne $case.sha256 -or
            [IO.FileInfo]::new($source).Length -ne [IO.FileInfo]::new($target).Length) {
            throw 'Versioned wire body is not byte-identical to this run reported Capture body.'
        }
        $bodies.Add([ordered]@{ path = $case.path; caseId = $case.case_id; role = $case.role; kind = $case.kind
            httpStatus = $case.http_status; expectedOutcome = $case.expected_outcome; source = $source; target = $target; sha256 = $case.sha256 })
    }
    foreach ($root in @($sourceRoot, $wireRoot)) {
        $expectedPaths = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        $null = $expectedPaths.Add((Join-Path $root 'index.json'))
        foreach ($body in $bodies) { $null = $expectedPaths.Add((Get-MemberPath $root $body.path)) }
        $actualPaths = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        $directories = [Collections.Generic.Queue[string]]::new(); $directories.Enqueue($root)
        while ($directories.Count -gt 0) {
            foreach ($item in Get-ChildItem -LiteralPath $directories.Dequeue() -Force) {
                Assert-NoReparsePoint $item.FullName
                if ($item.PSIsContainer) { $directories.Enqueue($item.FullName) }
                elseif (-not $actualPaths.Add($item.FullName) -or -not $expectedPaths.Contains($item.FullName)) { throw 'Unindexed or duplicate wire file is present.' }
            }
        }
        if ($actualPaths.Count -ne 31) { throw 'Wire file set must contain its index and exactly 30 bodies.' }
    }
    $publicPrefix = $sourceRoot + [IO.Path]::DirectorySeparatorChar
    if (@($captureArtifacts.Keys | Where-Object { $_.StartsWith($publicPrefix, [StringComparison]::OrdinalIgnoreCase) }).Count -ne 31) {
        throw 'Current Capture report public wire artifact set differs from its index.'
    }
    return [ordered]@{ captureRunId = $RunId; capturePath = $capturePath; captureSha256 = $captureHash
        captureReportPath = $captureReportPath; captureReportSha256 = Get-Hash $captureReportPath
        sourceIndexPath = $sourceIndex; sourceIndexSha256 = $indexHash; fixtureIndexPath = $wireIndex; fixtureIndexSha256 = Get-Hash $wireIndex
        bodyCount = $bodies.Count; bodies = @($bodies) }
}

function Assert-CaptureWireBinding($Expected, $Current) {
    foreach ($key in @('captureRunId', 'capturePath', 'captureSha256', 'captureReportPath', 'captureReportSha256',
            'sourceIndexPath', 'sourceIndexSha256', 'fixtureIndexPath', 'fixtureIndexSha256', 'bodyCount')) {
        if ($Expected[$key] -cne $Current[$key]) { throw 'Current Capture wire linkage changed after native acceptance.' }
    }
    if ($Expected.bodies.Count -ne $Current.bodies.Count) { throw 'Current Capture wire body binding count changed.' }
    for ($index = 0; $index -lt $Expected.bodies.Count; $index++) {
        foreach ($key in @('path', 'caseId', 'role', 'kind', 'httpStatus', 'expectedOutcome', 'source', 'target', 'sha256')) {
            if ($Expected.bodies[$index][$key] -cne $Current.bodies[$index][$key]) { throw 'Current Capture wire body linkage changed after native acceptance.' }
        }
    }
}

function Get-LinkedCapture {
    # This is the one reviewed log-only supplement, not a general resume path.
    # Its original Capture and failed Native results are immutable evidence.
    $captureRoot = Assert-ChildPath (Join-Path $runParent $CaptureRunId) $runParent
    $capturePath = Assert-ChildPath (Join-Path $captureRoot 'capture\result.json') $captureRoot
    $captureHash = '137ceaaa5a3b85f3a49193525eeb198aedaf28a113b7f760da66081d5983e699'
    if ((Get-Hash $capturePath) -ne $captureHash) { throw 'Pinned original Capture result changed.' }
    $capture = Read-Json $capturePath
    if ($capture.schemaVersion -ne 1 -or $capture.phase -ne 'Capture' -or $capture.runId -ne $CaptureRunId -or
        $capture.runRoot -ne $captureRoot -or $capture.status -ne 'LOCAL_HTTP_BOUNDARY_PASS' -or
        $capture.redaction.status -ne 'PASS' -or $capture.unitTests.status -ne 'PASS' -or $capture.unitTests.executed -ne 40) {
        throw 'Pinned original Capture identity, status or unit count mismatch.'
    }
    $expectedFiles = @{
        $PSCommandPath = 'f3b2a938a1f314ee5ff6d39b77fadb73cb3d5e1d5e92a562957305759acba2dc'
        $packetPath = 'd540cf96f8513833c4c708a7104f520554e8244b4502ed7a49d5f695ebe90c76'
        $harnessPath = '0384abc244b1a40d55043d830aabc334fd32d0457fa7810e2d1a0901d552bc2f'
        $unitTestsPath = '316ff378b54566b3052ead3aa13aa660cd1adbf542cef0a9cdf670f03edd6cff'
        $sourceManifestPath = 'bf861b2ec555c81e85a31e4b37e756c5e6b04d343522a95f3235700c2aec43f2'
    }
    if ($capture.candidate.files.Count -ne $expectedFiles.Count) { throw 'Pinned original Capture candidate must contain exactly five files.' }
    $seen = @{}
    foreach ($file in $capture.candidate.files) {
        if ($seen.ContainsKey($file.path) -or -not $expectedFiles.ContainsKey($file.path) -or $file.sha256 -ne $expectedFiles[$file.path]) {
            throw 'Pinned original Capture candidate path/hash mismatch.'
        }
        $seen[$file.path] = $true
        if ($file.path -notin @($PSCommandPath, $packetPath) -and (Get-Hash $file.path) -ne $file.sha256) {
            throw 'Capture Python, tests or source inventory changed before the native supplement.'
        }
    }
    $reports = @{
        preflight = @{ relative = 'python-preflight'; sha256 = 'e5736d5135817f3fda8324a45f5443795888d32364857a14601aa3af2d5dfc9f'; status = 'SOURCE_INVENTORY_PASS'; count = 1 }
        'verify-runtime' = @{ relative = 'python-runtime'; sha256 = '4de2b91c7fdc46a8a184070c0c9c8e38a8dc23be6ceaaf919c320806132d5f55'; status = 'INSTALLED_RUNTIME_PASS'; count = 2 }
        capture = @{ relative = 'python-capture'; sha256 = 'c99109764c6708889f2dc365696d03a9fd987465dd6e5d71f108a794223530a0'; status = 'LOCAL_HTTP_BOUNDARY_PASS'; count = 14 }
    }
    if ($capture.childReports.Count -ne 3) { throw 'Pinned original Capture child report count mismatch.' }
    $seenReports = @{}
    foreach ($child in $capture.childReports) {
        if ($seenReports.ContainsKey($child.phase) -or -not $reports.ContainsKey($child.phase)) { throw 'Pinned original Capture child identity mismatch.' }
        $seenReports[$child.phase] = $true
        $expected = $reports[$child.phase]
        $reportRoot = Assert-ChildPath (Join-Path $captureRoot ("capture\" + $expected.relative)) $captureRoot
        $reportPath = Join-Path $reportRoot 'report.json'
        if ($child.path -ne $reportPath -or $child.sha256 -ne $expected.sha256 -or (Get-Hash $reportPath) -ne $expected.sha256 -or $child.status -ne $expected.status) {
            throw 'Pinned original Capture child path/hash/status mismatch.'
        }
        $report = Read-Json $reportPath
        if ($report.schemaVersion -ne 1 -or $report.phase -ne $child.phase -or $report.status -ne $expected.status -or $report.redaction.status -ne 'PASS' -or
            $report.caseCounts.discovered -ne $expected.count -or $report.caseCounts.executed -ne $expected.count -or $report.caseCounts.passed -ne $expected.count -or
            $report.caseCounts.failed -ne 0 -or $report.caseCounts.blocked -ne 0 -or $report.caseCounts.notRun -ne 0 -or
            $report.cases.Count -ne $expected.count -or @($report.cases | Where-Object { $_.status -ne 'PASS' }).Count -ne 0) {
            throw 'Pinned original Capture child cases did not all pass.'
        }
        foreach ($artifact in $report.artifacts) {
            $path = if ([IO.Path]::IsPathRooted($artifact.path)) { $artifact.path } else { Join-Path $reportRoot $artifact.path }
            $path = Assert-ChildPath $path $reportRoot
            if ((Get-Hash $path) -ne $artifact.sha256.ToLowerInvariant()) { throw 'Pinned original Capture artifact changed.' }
        }
    }
    $wireHash = 'e1658b116e6ed53f84cee84b3d8a5c1adfd3ded3fa225db61d80d21d9953df0a'
    $proposedIndex = Join-Path $captureRoot 'capture\python-capture\proposed-wire\index.json'
    if ((Get-Hash $proposedIndex) -ne $wireHash -or (Get-Hash (Join-Path $fixtureRoot 'wire\index.json')) -ne $wireHash -or
        (Read-Json $proposedIndex).cases.Count -ne 30) { throw 'Pinned reviewed wire index changed.' }
    foreach ($state in @($capture.siblingsBefore, $capture.siblingsAfter)) {
        Assert-SelectedCore $state
        if ($state.arcade.head -ne '5088c1c49dcaff29eb59fb64b3063d30214dde73' -or $state.arcade.status) { throw 'Pinned original Arcade state must be exact and clean.' }
    }
    $preparePath = Join-Path $runRoot 'prepareruntime\result.json'
    $prepare = Read-Json $preparePath
    if ($prepare.runId -ne $RunId -or $prepare.phase -ne 'PrepareRuntime' -or $prepare.status -ne 'INSTALLED_RUNTIME_PASS' -or $prepare.redaction.status -ne 'PASS') {
        throw 'Current supplement requires its own successful PrepareRuntime.'
    }
    $preflightPath = Join-Path $runRoot 'preflight\result.json'
    if ($prepare.predecessor.path -ne $preflightPath -or $prepare.predecessor.sha256 -ne (Get-Hash $preflightPath)) {
        throw 'Current prepared runtime does not link the successful Preflight for this run.'
    }
    $provenanceHash = '39c485c33e482b158edb157a0ffaa69224c09e15de5655277b64289887f7cf7c'
    $runtimeHash = 'b01989fc595730d8ea6f1a10c7a5004510fca877a9b69aad9f3285cab357a897'
    foreach ($runtime in @($capture.runtime, $prepare.runtime)) {
        if ($runtime.provenance -ne $provenancePath -or $runtime.provenanceSha256 -ne $provenanceHash -or $runtime.runtimeTreeSha256 -ne $runtimeHash) {
            throw 'Pinned Capture and current prepared runtime identities differ.'
        }
    }
    if ((Get-Hash $provenancePath) -ne $provenanceHash) { throw 'Pinned runtime provenance changed.' }
    $phaseResult.captureSupplement = @{ captureRunId = $CaptureRunId; capturePath = $capturePath; captureSha256 = $captureHash
        childReports = $capture.childReports; historicalCandidate = $capture.candidate; wireIndexSha256 = $wireHash
        currentPrepareRuntime = @{ path = $preparePath; sha256 = Get-Hash $preparePath }
        runtimeProvenanceSha256 = $provenanceHash; runtimeTreeSha256 = $runtimeHash
        reuse = 'Read-only approved Capture evidence; this supplement launches no Core host and submits no commands. The original failed Native remains unchanged.' }
    return $capture
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
    if ($HarnessPhase -eq 'audit' -and $CaptureRunId) {
        $expectedInput = Join-Path $runParent "$CaptureRunId\capture\python-capture"
        if ($ExistingOutput -ne $expectedInput) { throw 'Supplement audit input must be the exact pinned original Capture.' }
        $output = Assert-ChildPath $ExistingOutput (Join-Path $runParent $CaptureRunId)
        $report = Join-Path (New-OwnedDirectory (Join-Path $phaseRoot $Label) $phaseRoot) 'report.json'
        # The frozen CLI requires output/report co-location. Call its unchanged
        # read-only audit function directly so this supplement never writes into
        # the original capture. Both input and new report paths are guarded here.
        $worker = @'
import argparse, pathlib, runpy, sys
module = runpy.run_path(sys.argv[1])
args = argparse.Namespace(core_root=pathlib.Path(sys.argv[2]), fixture_root=pathlib.Path(sys.argv[3]), output_root=pathlib.Path(sys.argv[4]), report_file=pathlib.Path(sys.argv[5]), core_launcher=pathlib.Path(sys.argv[6]))
report = module['Report']('audit', args.report_file.parent)
module['audit'](args, report)
report.details['captureSupplement'] = {'captureRunId': sys.argv[7], 'readOnlyInput': str(args.output_root), 'newReport': str(args.report_file), 'launchesCoreHost': False, 'submitsCommands': False}
payload = report.payload()
module['write_new'](args.report_file, module['json_bytes'](payload), report.secrets)
print(module['json'].dumps({'phase': 'audit', 'status': payload['status'], 'caseCounts': payload['caseCounts'], 'reportFile': str(args.report_file)}))
raise SystemExit(0 if payload['status'] == 'EVIDENCE_AUDIT_PASS' else 2)
'@
        $arguments = @('-I', '-B', '-c', $worker, $harnessPath, $coreRoot, $fixtureRoot, $output, $report,
            (Join-Path $coreRoot 'scripts\run_phase18m_reference_server.py'), $CaptureRunId)
    } else {
        $output = if ($ExistingOutput) { Assert-ChildPath $ExistingOutput $runRoot } else { New-OwnedDirectory (Join-Path $phaseRoot $Label) $phaseRoot }
        $report = Join-Path $output $(if ($ExistingOutput) { 'audit-report.json' } else { 'report.json' })
        $arguments = @('-I', '-B', $harnessPath, $HarnessPhase, '--core-root', $coreRoot,
            '--fixture-root', $fixtureRoot, '--output-root', $output, '--report-file', $report,
            '--core-launcher', (Join-Path $coreRoot 'scripts\run_phase18m_reference_server.py'))
    }
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
        # This is a read-only absence snapshot, never an owned output path. An
        # absent XML may live below Windows' OneDrive Documents cloud reparse
        # point. Existing XML still requires the full strict path/hash guard;
        # appearance after the build therefore fails the preservation check.
        $exists = $true
        try { $attributes = Get-PreservationFileAttributes $path }
        catch [IO.FileNotFoundException] { $exists = $false }
        catch [IO.DirectoryNotFoundException] { $exists = $false }
        if ($exists) {
            if (($attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'Global UBT settings file is a reparse point.' }
            if (($attributes -band [IO.FileAttributes]::Directory) -ne 0) { throw 'Global UBT settings path is a directory.' }
            Assert-NoReparsePoint $path
        }
        @{ path = $path; exists = $exists; sha256 = $(if ($exists) { Get-Hash $path } else { $null }) }
    })
}

function Assert-UBTSettings($Before, $After) {
    foreach ($setting in $Before) {
        $current = @($After | Where-Object { $_.path -eq $setting.path })
        if ($current.Count -ne 1 -or $setting.exists -ne $current[0].exists -or $setting.sha256 -ne $current[0].sha256) { throw 'Global UBT settings changed during the native proof.' }
    }
}

function New-EditorSettingsPaths([string] $EngineDirectory, [string] $ProjectDirectory,
    [string] $LocalDataDirectory, [string] $ProfileDirectory, [string] $DocumentsDirectory,
    [int] $MajorVersion, [int] $MinorVersion) {
    foreach ($root in @($EngineDirectory, $ProjectDirectory, $LocalDataDirectory, $ProfileDirectory, $DocumentsDirectory)) {
        if ([string]::IsNullOrWhiteSpace($root) -or -not [IO.Path]::IsPathFullyQualified($root)) {
            throw 'All editor-settings observation roots must be available absolute paths.'
        }
    }
    if ($MajorVersion -le 0 -or $MinorVersion -lt 0) { throw 'Editor-settings engine version is unavailable.' }
    $version = '{0}.{1}' -f $MajorVersion, $MinorVersion
    # Keep the two Documents observations even when their paths coincide. Roles,
    # rather than unique filenames, identify the six required observations.
    return @(
        @{ role = 'engine-base'; path = [IO.Path]::GetFullPath((Join-Path $EngineDirectory 'Engine\Config\BaseEditorSettings.ini')) },
        @{ role = 'local-user'; path = [IO.Path]::GetFullPath((Join-Path $LocalDataDirectory 'Unreal Engine\Engine\Config\UserEditorSettings.ini')) },
        @{ role = 'local-versioned'; path = [IO.Path]::GetFullPath((Join-Path $LocalDataDirectory "UnrealEngine\$version\Saved\Config\WindowsEditor\EditorSettings.ini")) },
        @{ role = 'profile-documents-user'; path = [IO.Path]::GetFullPath((Join-Path $ProfileDirectory 'Documents\Unreal Engine\Engine\Config\UserEditorSettings.ini')) },
        @{ role = 'project-default'; path = [IO.Path]::GetFullPath((Join-Path $ProjectDirectory 'Config\DefaultEditorSettings.ini')) },
        @{ role = 'known-documents-user'; path = [IO.Path]::GetFullPath((Join-Path $DocumentsDirectory 'Unreal Engine\Engine\Config\UserEditorSettings.ini')) }
    )
}

function Get-EditorSettingsPaths {
    return New-EditorSettingsPaths $EngineRoot $projectRoot ([Environment]::GetFolderPath('LocalApplicationData')) `
        ([Environment]::GetFolderPath('UserProfile')) ([Environment]::GetFolderPath('MyDocuments')) `
        $phaseResult.toolchain.engineVersion.MajorVersion $phaseResult.toolchain.engineVersion.MinorVersion
}

function Get-PreservationFileAttributes([string] $Path) {
    return [IO.File]::GetAttributes($Path)
}

function Get-EditorSettingsState {
    return @(foreach ($setting in Get-EditorSettingsPaths) {
        $record = @{ role = $setting.role; path = $setting.path; exists = $null; sha256 = $null; inspection = 'UNAVAILABLE' }
        $inspectionStage = 'editor-attributes'
        try {
            # Absence below a cloud/reparse Documents ancestor is a read-only
            # observation. Only explicit not-found errors establish absence:
            # File.Exists also returns false for access/IO errors and is unsafe
            # for this preservation record. Hash/read races remain UNAVAILABLE.
            $knownAbsent = $false
            try { $attributes = Get-PreservationFileAttributes $setting.path }
            catch [IO.FileNotFoundException] { $knownAbsent = $true }
            catch [IO.DirectoryNotFoundException] { $knownAbsent = $true }
            $record.exists = -not $knownAbsent
            if (-not $knownAbsent) {
                # Check returned attributes directly: a broken link may not pass
                # File.Exists, but available reparse metadata must be rejected.
                $inspectionStage = 'editor-reparse-check'
                if (($attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'Editor-settings file is a reparse point.' }
                $inspectionStage = 'editor-file-kind-check'
                if (($attributes -band [IO.FileAttributes]::Directory) -ne 0) { throw 'Expected an editor-settings file, not a directory.' }
                $inspectionStage = 'editor-hash'
                $record.sha256 = Get-Hash $setting.path
            }
            $record.inspection = 'PASS'
        } catch {
            # Retain all available observations even if one file cannot be read.
            # The assertion rejects UNAVAILABLE; this is not an absence fallback.
            $record.error = Get-SafeFailureEvidence $_ $inspectionStage
        }
        $record
    })
}

function Assert-EditorSettingsState($Before, $After) {
    $expected = @(Get-EditorSettingsPaths)
    if ($expected.Count -ne 6 -or @($Before).Count -ne 6 -or @($After).Count -ne 6) {
        throw 'Editor-settings preservation requires all six observations before and after native work.'
    }
    foreach ($setting in $expected) {
        $prior = @($Before | Where-Object { $_.role -ceq $setting.role })
        $current = @($After | Where-Object { $_.role -ceq $setting.role })
        if ($prior.Count -ne 1 -or $current.Count -ne 1) { throw 'Editor-settings observation membership is missing or duplicated.' }
        foreach ($observation in @($prior[0], $current[0])) {
            if ($observation.path -cne $setting.path) { throw 'Editor-settings observation path changed or was substituted.' }
            if ($observation.inspection -cne 'PASS' -or $observation.exists -isnot [bool] -or
                ($observation.exists -and ($observation.sha256 -isnot [string] -or $observation.sha256 -cnotmatch '^[0-9a-f]{64}$')) -or
                (-not $observation.exists -and $null -ne $observation.sha256)) {
                throw 'Editor-settings observation is unavailable or has invalid existence/hash metadata.'
            }
        }
        if ($prior[0].exists -cne $current[0].exists -or $prior[0].sha256 -cne $current[0].sha256) {
            throw 'Editor-settings existence or hash changed during native work.'
        }
    }
}

function Save-EditorSettingsFailureEvidence([Collections.IDictionary] $Result) {
    $Result.editorSettingsAfterFailureUtc = [datetime]::UtcNow.ToString('o')
    $inspectionStage = 'editor-after-observation-provider'
    try {
        $Result.editorSettingsAfterFailure = Get-EditorSettingsState
        $inspectionStage = 'editor-after-assertion'
        Assert-EditorSettingsState $Result.editorSettingsBefore $Result.editorSettingsAfterFailure
    } catch {
        # Do not replace the original build/automation/phase failure.
        $Result.editorSettingsFailure = Get-SafeFailureEvidence $_ $inspectionStage
    }
}

function Get-ConfigState {
    $configRoot = Join-Path $projectRoot 'Config'
    Assert-NoReparsePoint $configRoot
    if (-not [IO.Directory]::Exists($configRoot)) { throw 'Authored Config directory is absent.' }
    $records = [Collections.Generic.List[object]]::new()
    $directories = [Collections.Generic.Queue[string]]::new(); $directories.Enqueue($configRoot)
    while ($directories.Count -gt 0) {
        foreach ($item in Get-ChildItem -LiteralPath $directories.Dequeue() -Force) {
            Assert-NoReparsePoint $item.FullName
            $records.Add(@{ path = $item.FullName; kind = $(if ($item.PSIsContainer) { 'directory' } else { 'file' })
                sha256 = $(if ($item.PSIsContainer) { $null } else { Get-Hash $item.FullName }) })
            if ($item.PSIsContainer) { $directories.Enqueue($item.FullName) }
        }
    }
    return @($records | Sort-Object { $_.path })
}

function Assert-ConfigState($Before, $After) {
    if ($Before.Count -ne $After.Count) { throw 'Native execution changed the authored Config directory/file set.' }
    for ($index = 0; $index -lt $Before.Count; $index++) {
        if ($Before[$index].path -ne $After[$index].path -or $Before[$index].kind -ne $After[$index].kind -or $Before[$index].sha256 -ne $After[$index].sha256) {
            throw 'Native execution changed an authored Config path or file hash.'
        }
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
    $tests = @($report.tests | Where-Object { $_.fullTestPath -is [string] -and $_.fullTestPath.StartsWith('Warhammer.Migration.E01Boundary.', [StringComparison]::Ordinal) })
    if ($tests.Count -ne 132 -or $report.tests.Count -ne 132 -or $report.succeeded -ne 132) {
        throw 'Frozen native suite must export exactly 132 matching successful cases and no unrelated tests.'
    }
    $names = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($test in $tests) {
        if (-not $names.Add($test.fullTestPath)) { throw 'Native suite exported a duplicate case path.' }
        if ($test.state -ne 'Success') { throw "Native case did not pass: $($test.fullTestPath) ($($test.state))" }
    }
    if ($report.failed -ne 0 -or $report.notRun -ne 0 -or $report.inProcess -ne 0) { throw 'Native report contains failed/incomplete cases.' }
    return @{ matchingCount = $tests.Count; tests = @($tests | ForEach-Object { @{ name = $_.fullTestPath; state = $_.state } }); reportSha256 = Get-Hash $ReportPath }
}

function Get-PhaseFailureEnvelope($Result, [string] $Failure, $Errors) {
    $evidence = [ordered]@{}; $omitted = 0
    if ($null -ne $Result) {
        foreach ($key in $Result.Keys) {
            try {
                Assert-SafeStructuredValue $key
                Assert-SafeStructuredValue $Result[$key]
                $evidence[$key] = $Result[$key]
            } catch { $omitted++ }
        }
    }
    return @{ status = 'FAIL'; failure = $Failure; secondaryErrors = $Errors; evidence = $evidence; omittedUnsafeOrUnsupportedFields = $omitted }
}

function Write-PhaseFailureDiagnostic($Envelope, [string] $Channel = 'stderr') {
    Assert-SafeStructuredValue $Envelope
    $json = $Envelope | ConvertTo-Json -Depth 80 -Compress -WarningAction Stop
    if ($Channel -eq 'stderr') { [Console]::Error.WriteLine($json) }
    elseif ($Channel -eq 'stdout') { [Console]::Out.WriteLine($json) }
    else { throw 'Unsupported phase diagnostic channel.' }
}

function Complete-PhaseFinalization($Result, [string] $PrimaryFailure, $RuntimeHandle, $RunHandle, [string] $Directory) {
    $errors = [Collections.Generic.List[object]]::new()
    $failure = $PrimaryFailure
    if ($failure) { try { Assert-SafeText $failure } catch { $failure = 'Credential scan rejected primary failure details; original details were not retained.' } }
    $lockStates = [ordered]@{}
    # All critical resource finalizers precede final result publication. A lock
    # failure therefore cannot leave a newly published successful predecessor.
    foreach ($entry in @(@{ name = 'runtime'; handle = $RuntimeHandle }, @{ name = 'run'; handle = $RunHandle })) {
        $lockStates[$entry.name] = 'NOT_ACQUIRED'
        if ($null -ne $entry.handle) {
            try { $entry.handle.Dispose(); $lockStates[$entry.name] = 'DISPOSED' }
            catch {
                $lockStates[$entry.name] = 'UNCONFIRMED'
                $diagnostic = Get-SafeFailureEvidence $_ ('phase-' + $entry.name + '-lock-dispose')
                $errors.Add($diagnostic)
                if (-not $failure) { $failure = $diagnostic.details }
            }
        }
    }
    if ($null -ne $Result) {
        if ($failure) { $Result.status = 'FAIL'; $Result.failure = $failure }
        $Result.completedUtc = [datetime]::UtcNow.ToString('o')
        $Result.finalization = @{ locks = $lockStates; secondaryErrors = $errors }
        try { Write-NewJson (Join-Path $Directory 'result.json') $Result $errors }
        catch {
            $diagnostic = Get-SafeFailureEvidence $_ 'phase-result-export'
            $errors.Add($diagnostic)
            if (-not $failure) { $failure = $diagnostic.details }
            $Result.status = 'FAIL'; $Result.failure = $failure
        }
    }
    if ($errors.Count) {
        $envelope = Get-PhaseFailureEnvelope $Result $failure $errors
        try { Write-NewJson (Join-Path $Directory 'finalization-failure.json') $envelope $errors }
        catch { $errors.Add((Get-SafeFailureEvidence $_ 'phase-diagnostic-file-export')) }
        try { Write-PhaseFailureDiagnostic $envelope 'stderr' }
        catch {
            $errors.Add((Get-SafeFailureEvidence $_ 'phase-diagnostic-stderr'))
            # Never rewrite a prior artifact. A second immutable file can retain
            # the stderr failure when the file channel is the surviving one.
            try { Write-NewJson (Join-Path $Directory 'finalization-channel-failure.json') $envelope $errors }
            catch { $errors.Add((Get-SafeFailureEvidence $_ 'phase-secondary-diagnostic-file-export')) }
            try { Write-PhaseFailureDiagnostic $envelope 'stdout' }
            catch { $errors.Add((Get-SafeFailureEvidence $_ 'phase-diagnostic-stdout')) }
        }
    }
    return @{ failure = $(if ($failure) { $failure } else { $null }); secondaryErrors = $errors; locks = $lockStates }
}

try {
    if (-not $IsWindows -or -not [Environment]::Is64BitOperatingSystem -or [Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture -ne 'X64') { throw 'E01 requires native x64 Windows and PowerShell7.2+.' }
    if ($CaptureRunId -and ($Phase -notin @('Native', 'Audit') -or $CaptureRunId -ne '20261017T002136Z-8dad7f29' -or $CaptureRunId -eq $RunId)) {
        throw 'CaptureRunId is permitted only for the reviewed Native/Audit supplement of 20261017T002136Z-8dad7f29 in a different fresh run.'
    }
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
        if ($CaptureRunId -and (Test-Path -LiteralPath (Join-Path $runRoot 'capture'))) { throw 'Native/Audit supplement must not contain a copied or newly executed Capture phase.' }
        $predecessors = @{ PrepareRuntime = 'preflight'; Capture = 'prepareruntime'; Native = $(if ($CaptureRunId) { 'prepareruntime' } else { 'capture' }); Audit = 'native' }
        $previous = Read-Json (Join-Path $runRoot ($predecessors[$Phase] + '\result.json'))
        $expectedStatuses = @{ PrepareRuntime = 'SOURCE_INVENTORY_PASS'; Capture = 'INSTALLED_RUNTIME_PASS'; Native = $(if ($CaptureRunId) { 'INSTALLED_RUNTIME_PASS' } else { 'LOCAL_HTTP_BOUNDARY_PASS' }); Audit = 'NATIVE_FIXTURE_PASS' }
        if ($previous.status -ne $expectedStatuses[$Phase] -or $previous.runId -ne $RunId) { throw 'Explicit predecessor phase did not pass for this run.' }
        $phaseResult.predecessor = @{ path = Join-Path $runRoot ($predecessors[$Phase] + '\result.json'); sha256 = Get-Hash (Join-Path $runRoot ($predecessors[$Phase] + '\result.json')) }
        if ($CaptureRunId) { $linkedCapture = Get-LinkedCapture }
        if ($Phase -eq 'Audit') {
            Assert-Candidate $previous.candidate
            if ($CaptureRunId) {
                if (-not $previous.ContainsKey('captureSupplement')) { throw 'Native predecessor did not use the same explicit Capture supplement.' }
                foreach ($key in @('captureRunId', 'capturePath', 'captureSha256', 'wireIndexSha256', 'runtimeProvenanceSha256', 'runtimeTreeSha256')) {
                    if ($previous.captureSupplement[$key] -ne $phaseResult.captureSupplement[$key]) { throw 'Native/Audit Capture supplement linkage differs.' }
                }
                if ($previous.captureSupplement.currentPrepareRuntime.path -ne $phaseResult.captureSupplement.currentPrepareRuntime.path -or
                    $previous.captureSupplement.currentPrepareRuntime.sha256 -ne $phaseResult.captureSupplement.currentPrepareRuntime.sha256) { throw 'Native/Audit prepared-runtime linkage differs.' }
            } else {
                if ($previous.ContainsKey('captureSupplement')) { throw 'Audit must explicitly repeat Native CaptureRunId; no silent fallback.' }
                $capture = Read-Json (Join-Path $runRoot 'capture\result.json'); Assert-Candidate $capture.candidate
            }
        }
    }
    $before = Get-SiblingState 'before'
    $phaseResult.siblingsBefore = $before
    Assert-SelectedCore $before
    if ($null -ne $linkedCapture) { Assert-SameSiblings $linkedCapture.siblingsBefore $before }
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
        $phaseResult.unitTests = Get-PythonUnitEvidence $unitLog
        $null = Invoke-Harness 'capture' $runtimePython 'python-capture'
        Assert-Candidate $phaseResult.candidate
        $phaseResult.status = 'LOCAL_HTTP_BOUNDARY_PASS'
    } elseif ($Phase -eq 'Native') {
        Assert-Runtime
        if (-not $CaptureRunId) { Assert-Candidate $previous.candidate }
        $phaseResult.toolchain = Get-Toolchain
        foreach ($key in @('engineVersionSha256', 'compilerSha256', 'selectedPythonSha256', 'uvSha256')) {
            if ($phaseResult.toolchain[$key] -ne $preflight.toolchain[$key]) { throw 'Native toolchain bytes changed after Preflight.' }
        }
        $phaseResult.ubtSettingsBefore = Get-UBTSettings
        $phaseResult.configBefore = Get-ConfigState
        $phaseResult.editorSettingsBeforeUtc = [datetime]::UtcNow.ToString('o')
        $phaseResult.editorSettingsBefore = Get-EditorSettingsState
        Assert-EditorSettingsState $phaseResult.editorSettingsBefore $phaseResult.editorSettingsBefore
        $nativePaths = @('Source/WarhammerClient/Private/Migration/CoreBoundaryEvidence.h',
            'Source/WarhammerClient/Private/Migration/CoreBoundaryEvidence.cpp',
            'Source/WarhammerClient/Private/Tests/CoreBoundaryEvidenceTests.cpp', 'Source/WarhammerClient/WarhammerClient.Build.cs',
            'Source/WarhammerClient.Target.cs', 'Source/WarhammerClientEditor.Target.cs', 'WarhammerClient.uproject')
        $configPaths = @($phaseResult.configBefore | Where-Object { $_.kind -eq 'file' -and [IO.Path]::GetExtension($_.path) -eq '.ini' } | ForEach-Object { $_.path })
        $phaseResult.candidate = Get-Candidate (@($nativePaths | ForEach-Object { Join-Path $projectRoot $_ }) + @($PSCommandPath, $sourceManifestPath, $packetPath) + $configPaths)
        $wireIndex = Join-Path $fixtureRoot 'wire\index.json'
        $index = Read-Json $wireIndex
        if ($index.format_version -ne 1 -or $index.cases.Count -eq 0) { throw 'Reviewed nonempty wire fixture index is required.' }
        $phaseResult.fixtureFiles = @(@{ path = $wireIndex; sha256 = Get-Hash $wireIndex }) + @(foreach ($case in $index.cases) {
            $path = Get-MemberPath (Join-Path $fixtureRoot 'wire') $case.path
            if ((Get-Hash $path) -ne $case.sha256.ToLowerInvariant()) { throw 'Reviewed wire fixture changed.' }
            @{ path = $path; sha256 = Get-Hash $path }
        })
        if (-not $CaptureRunId) { $phaseResult.captureWireBinding = Get-CurrentCaptureWireEvidence }
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
        $null = Invoke-OwnedProcess 'native-automation' $editor @($project, '-unattended', '-nop4', '-NullRHI', '-nosplash', '-nowrite',
            '-ExecCmds=Automation RunTests Warhammer.Migration.E01Boundary', '-TestExit=Automation Test Queue Empty',
            "-ReportExportPath=$automationRoot", "-ABSLOG=$(Join-Path $runRoot 'native-automation.log')", "-E01FixtureRoot=$fixtureRoot",
            "-UserDir=$userRoot", '-DDC=(EnginePak=InstalledEnginePak,Local)', '-DDC-NoDefaultGraph', "-LocalDataCachePath=$ddcRoot") $runRoot
        $phaseResult.automation = Get-AutomationEvidence (Join-Path $automationRoot 'index.json')
        $phaseResult.nativeArtifacts = @((Get-SafeArtifact $buildLog), (Get-SafeArtifact (Join-Path $runRoot 'native-automation.log')),
            (Get-SafeArtifact (Join-Path $automationRoot 'index.json')))
        $phaseResult.editorSettingsAfterUtc = [datetime]::UtcNow.ToString('o')
        $phaseResult.editorSettingsAfter = Get-EditorSettingsState
        Assert-EditorSettingsState $phaseResult.editorSettingsBefore $phaseResult.editorSettingsAfter
        $phaseResult.ubtSettingsAfter = Get-UBTSettings
        Assert-UBTSettings $phaseResult.ubtSettingsBefore $phaseResult.ubtSettingsAfter
        $phaseResult.configAfter = Get-ConfigState
        Assert-ConfigState $phaseResult.configBefore $phaseResult.configAfter
        foreach ($file in $phaseResult.fixtureFiles) { if ((Get-Hash $file.path) -ne $file.sha256) { throw 'Native fixture changed during execution.' } }
        if (-not $CaptureRunId) { Assert-CaptureWireBinding $phaseResult.captureWireBinding (Get-CurrentCaptureWireEvidence) }
        Assert-Candidate $phaseResult.candidate
        $phaseResult.status = 'NATIVE_FIXTURE_PASS'
    } else {
        Assert-Runtime
        if (-not $CaptureRunId) {
            if (-not $previous.ContainsKey('captureWireBinding')) { throw 'Native predecessor lacks the current Capture wire binding.' }
            $phaseResult.captureWireBinding = Get-CurrentCaptureWireEvidence
            Assert-CaptureWireBinding $previous.captureWireBinding $phaseResult.captureWireBinding
        }
        $phaseResult.configBefore = Get-ConfigState
        Assert-ConfigState $previous.configAfter $phaseResult.configBefore
        foreach ($file in $previous.fixtureFiles) { if ((Get-Hash $file.path) -ne $file.sha256) { throw 'Accepted native fixture changed before audit.' } }
        $auditInput = if ($CaptureRunId) { Join-Path $runParent "$CaptureRunId\capture\python-capture" } else { Join-Path $runRoot 'capture\python-capture' }
        $null = Invoke-Harness 'audit' $runtimePython 'python-audit' $auditInput
        if (-not $CaptureRunId) { Assert-CaptureWireBinding $phaseResult.captureWireBinding (Get-CurrentCaptureWireEvidence) }
        $phaseResult.configAfter = Get-ConfigState
        Assert-ConfigState $phaseResult.configBefore $phaseResult.configAfter
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
    if ($null -ne $linkedCapture) {
        $null = Get-LinkedCapture
        if ($phaseResult.runtime.provenanceSha256 -ne $phaseResult.captureSupplement.runtimeProvenanceSha256 -or
            $phaseResult.runtime.runtimeTreeSha256 -ne $phaseResult.captureSupplement.runtimeTreeSha256) { throw 'Verified current runtime differs from the reused Capture.' }
    }
    $phaseResult.redaction.status = 'PASS'
} catch {
    $phaseError = $_
    $failure = $_.Exception.Message
    try { Assert-SafeText $failure } catch { $failure = 'Credential scan rejected failure details; original output was not exported.' }
    if ($null -ne $phaseResult) {
        $phaseResult.status = 'FAIL'
        $phaseResult.failure = $failure
        $phaseResult.primaryFailure = Get-SafeFailureEvidence $phaseError 'phase-execution'
        $phaseResult.redaction.status = if ($failure -like '*Credential scan*') { 'REJECTED_QUARANTINED' } else { 'SCANNED_PARTIAL' }
        try { $phaseResult.siblingsAfterFailure = Get-SiblingState 'failed-after' }
        catch { $phaseResult.siblingAfterFailureCheck = 'UNAVAILABLE; inspect preserved sanitized process logs' }
        if ($phaseResult.Contains('ubtSettingsBefore')) {
            try { $phaseResult.ubtSettingsAfterFailure = Get-UBTSettings; Assert-UBTSettings $phaseResult.ubtSettingsBefore $phaseResult.ubtSettingsAfterFailure }
            catch { $phaseResult.ubtSettingsFailure = Get-SafeFailureEvidence $_ 'ubt-after-failure-inspection' }
        }
        if ($phaseResult.Contains('configBefore')) {
            try { $phaseResult.configAfterFailure = Get-ConfigState; Assert-ConfigState $phaseResult.configBefore $phaseResult.configAfterFailure }
            catch { $phaseResult.configFailure = Get-SafeFailureEvidence $_ 'config-after-failure-inspection' }
        }
        if ($phaseResult.Contains('editorSettingsBefore')) { Save-EditorSettingsFailureEvidence $phaseResult }
    }
} finally {
    $finalized = Complete-PhaseFinalization $phaseResult $failure $runtimeLock $runLock $phaseRoot
    $failure = $finalized.failure
}
if ($null -ne $failure) { Write-Error $failure; exit 1 }
Write-Host "E01 $RunId/${Phase}: $($phaseResult.status). Result: $(Join-Path $phaseRoot 'result.json')"
