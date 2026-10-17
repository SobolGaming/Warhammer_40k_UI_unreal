#requires -Version 7.6
<#
.SYNOPSIS
Single-use phases of the adopted synthetic E02 proof; never a Core/game client.
.DESCRIPTION
Do not execute this new source before independent source review. Preflight only
reads/stages frozen inputs; it cannot grant review or execution authority.

Freeze schemaVersion=1: sourceHead (40 hex), packet descriptor, files descriptor
array, sourceMembership array {path,kind:'file'|'directory'}. Descriptor fields
are absolute path, bytes (integer), sha256. Membership is relative slash paths
for WarhammerClient.uproject and every Source/Config file/directory, including
empty directories. files also covers this wrapper, fixture, AGENTS/instructions,
and every engine/tool/source/SDK/asset used. toolPaths supplies absolute named
paths: buildBat,editor,editorCmd,compiler,dotnet,sdkRc,cmd,where,getDotnetPath.
compilerInputs binds powerShellHome, roslyn:[the two absolute descriptors for
Microsoft.CodeAnalysis.dll and Microsoft.CodeAnalysis.CSharp.dll], referenceRoot,
and references:[{relativePath,bytes,sha256}] for the complete top-level ref/*.dll
set. All compiler DLLs must also occur in files. dotnetSdk binds version,
directory and versionFile (the bundled sdk/<version>/.version descriptor, also
in files). Actual Build selection is checked in the same cmd environment/CWD
before Build.bat, using frozen where.exe and dotnet --version output. The child
clears inherited UE .NET bypass variables and uses PATHEXT=.EXE on actual X64.
Raw selections are logs/build-dotnet-path.txt and logs/build-dotnet-sdk.txt;
the successful Build result binds both and the actual selected executable/SDK.
pluginClosure is a frozen
review-input descriptor (also listed in files). Its schemaVersion1 object binds
sourceHead, canonical project descriptor, platform='Win64',
targets=['WarhammerClientEditor'], disabledPlugins (the exact6), enabledPlugins
(the selected closure names), and descriptors (selected .uplugin descriptors).
catalogRoots is the complete raw .uplugin catalog under exactly Engine/Plugins
and Engine/Platforms: [{path,descriptors:[{relativePath,bytes,sha256}]}]. Relative
paths use '/'; hidden descriptors are included. requiredAbsentPaths binds the
exact10 additional discovery paths checked below. emptyEnvironmentVariables is
['UE_ADDITIONAL_PLUGIN_PATHS']; the child override is explicitly empty regardless
of the parent's value. targetReceiptPolicy binds relativePath
'Binaries/Win64/WarhammerClientEditor.target', pluginOverrides:[{Name,Enabled}],
and allowEnginePluginsEnabledByDefault:boolean. The actual newly built staged
receipt is checked before native launch; BuildPlugins is an optional allowlist,
not a set of runtime enable roots. Unsupported selection shapes fail closed.
The independent source review must establish its completeness; this wrapper
binds/checks the supplied closure, not arbitrary UBT/C# dependency semantics.
The complete descriptor
closure, not an arbitrary hardcoded current authoring hash, is independently
reviewed. No dependency synchronization, installation or Core launch occurs.

Authority schemaVersion=1: runId, explicitCoordinatorGo=true, freezeManifest
descriptor, sourceReviewed {sourceHead,status:'PASS',report:descriptor,
pluginClosureReviewed:true},
allowedPhases array. Discovery/WorldInput additionally require explicit
-AllowVisibleWindow and visibleWindowOwnerApproval {status:'APPROVED',reference:
descriptor}. The referenced owner receipt must be genuine external evidence;
this wrapper does not generate it or infer permission from a switch.

Order: Preflight -> SupervisorControls -> Build -> Discovery -> Numeric ->
WorldInput -> Audit. A failed/uncertain phase blocks every dependent phase.
No resume/retry/overwrite within a RunId. Every result.json is provisional and
requires its phase's completion.json, published last after all required outputs.
Audit completion binds both audit/result.json and the top-level result.json.
Missing/invalid completion blocks dependents even if a raw result says success.
No published raw result is overwritten after a later finalization failure.
completion.json schema1: runId, phase, state='COMPLETE', executionPassed=true,
completedUtc, sourceHead, freezeManifest descriptor, phaseResult descriptor,
requiredArtifacts:[phaseResult, plus top-level result for Audit]. A failed
publication is reported FAIL and, when writable, finalization-failure.json.
Budgets: build1800s; native600s;
SUP01-03 together600s. Graceful shutdown<=15s is reserved inside the bound.

SUP01: one actual normal-root/lingering-child case (child sleeps2s); root exit
must precede an actual nonzero job observation, then actual zero-active.
SUP02: one actual8s-budget root/child timeout case (both sleep60s), preserving
typed timeout plus real exit/zero-active cleanup. SUP03 has four exact synthetic
fault subcases: assignment before resume; accounting query; handle finalization;
JSON evidence writer. Their failures must stay failures while bounded cleanup
and original primary/secondary evidence survive. These3 groups/5 process roots
plus1 writer seam are separate from the4+4+8 native cases. No complete historical
descendant ledger, IOCP/debugger, global kills, or fabricated child times.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Preflight','SupervisorControls','Build','Discovery','Numeric','WorldInput','Audit')][string] $Phase,
    [Parameter(Mandatory)][ValidatePattern('^[0-9]{8}T[0-9]{6}Z-[0-9a-f]{8}$')][string] $RunId,
    [string] $FreezeManifestPath = '',
    [string] $AuthorityPath = '',
    [string] $EngineRoot = 'C:\Program Files\Epic Games\UE_5.8',
    [switch] $AllowVisibleWindow
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:Utf8 = [Text.UTF8Encoding]::new($false,$true)
$script:Repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$script:RunRoot = Join-Path $script:Repo ".local\experiments\E02\$RunId"
$script:Stage = Join-Path $script:RunRoot 'project'
$script:Packet = Join-Path $script:Repo 'docs\plans\research\2026-10-16-e02-world-input-packet.md'
$script:Fixture = Join-Path $script:Repo 'tests\migration\fixtures\e02\world-input-v1.json'
$script:Order = @('Preflight','SupervisorControls','Build','Discovery','Numeric','WorldInput','Audit')
$script:Names = @('Numeric.RoundTrip','Numeric.HeadingAxes','Numeric.ShapesWinding','Numeric.UnsupportedGeometry',
    'Rendered.FiveForms','Rendered.RaisedPicking','Rendered.MeshSubstitution','Rendered.ObliqueNormals',
    'Input.CompletedClick','Input.CameraCapture','Input.PanDollyFrame','Input.HudExclusion','Input.ModalText','Input.CancelActivation','Input.ResizeScale','Input.RepeatedConfirm') |
    ForEach-Object { "Warhammer.Migration.E02.$_" }
$script:Disabled = @('UdpMessaging','TcpMessaging','QuicMessaging','WebSocketMessaging','DiscoveryBeaconReceiver','NetworkServiceDiscovery')
$script:Secrets = [Collections.Generic.List[string]]::new()
foreach ($entry in [Environment]::GetEnvironmentVariables().GetEnumerator()) {
    if ($entry.Key -match '(?i)TOKEN|PASSWORD|SECRET|API_KEY|CREDENTIAL' -and ([string]$entry.Value).Length -ge 8) { $script:Secrets.Add([string]$entry.Value) }
}
foreach ($name in @('github-full-access','github_token')) {
    $credentialPath = Join-Path (Split-Path $script:Repo -Parent) $name
    if ([IO.File]::Exists($credentialPath)) {
        $value = [IO.File]::ReadAllText($credentialPath).Trim()
        if ($value.Length -ge 8) { $script:Secrets.Add($value) }
    }
}
$script:Result = $null; $script:Freeze = $null; $script:Lock = $null
$script:PhaseRoot = Join-Path $script:RunRoot $Phase.ToLowerInvariant()
$script:Errors = [Collections.Generic.List[object]]::new()

function Assert-Path([string] $Path) {
    if (-not [IO.Path]::IsPathFullyQualified($Path)) { throw 'E02_PATH_NOT_ABSOLUTE' }
    $full = [IO.Path]::GetFullPath($Path)
    $cursor = $full
    while ($cursor) {
        try {
            $attributes = [IO.File]::GetAttributes($cursor)
            if (($attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'E02_REPARSE_PATH' }
        } catch [IO.FileNotFoundException] { } catch [IO.DirectoryNotFoundException] { }
        $parent = [IO.Directory]::GetParent($cursor)
        $cursor = if ($null -eq $parent) { $null } else { $parent.FullName }
    }
    return $full
}
function Under([string] $Path,[string] $Parent) {
    $full = Assert-Path $Path
    $prefix = ([IO.Path]::GetFullPath($Parent)).TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar
    if (-not $full.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)) { throw 'E02_PATH_ESCAPES_OWNER' }
    return $full
}
function Owned([string] $Relative) {
    if ($Relative -notmatch '^[A-Za-z0-9_./-]+$' -or @($Relative.Split('/') | Where-Object { $_ -in @('','.','..') }).Count) { throw 'E02_INVALID_MEMBER' }
    return Under (Join-Path $script:RunRoot $Relative) $script:RunRoot
}
function Need-File([string] $Path) {
    $full = Assert-Path $Path
    foreach($name in @('github-full-access','github_token')) {
        if($full -ieq (Join-Path (Split-Path $script:Repo -Parent) $name)){throw 'E02_CREDENTIAL_IS_NOT_AN_ARTIFACT'}
    }
    if (([IO.File]::GetAttributes($full) -band [IO.FileAttributes]::Directory) -ne 0) { throw 'E02_EXPECTED_FILE' }
    return $full
}
function Digest([string] $Path) { return (Get-FileHash -Algorithm SHA256 -LiteralPath (Need-File $Path)).Hash.ToLowerInvariant() }
function Descriptor([string] $Path) { return [ordered]@{path=(Need-File $Path);bytes=([IO.FileInfo]::new($Path)).Length;sha256=(Digest $Path)} }
function Check-Descriptor($Item) {
    if ($Item -isnot [Collections.IDictionary] -or $Item.path -isnot [string] -or $Item.sha256 -cnotmatch '^[A-Fa-f0-9]{64}$' -or
        $Item.bytes -isnot [long] -and $Item.bytes -isnot [int] -or $Item.bytes -lt 0) { throw 'E02_INVALID_DESCRIPTOR' }
    $actual = Descriptor $Item.path
    if ($actual.bytes -ne $Item.bytes -or $actual.sha256 -ine $Item.sha256) { throw 'E02_FROZEN_FILE_DRIFT' }
    return $actual
}
function Safe-Text([string] $Text) {
    foreach ($secret in $script:Secrets) { if ($Text.Contains($secret,[StringComparison]::Ordinal)) { throw 'E02_SECRET_IN_EVIDENCE' } }
    if ($Text -match '(?i)\b(?:gh[pousr]_[A-Za-z0-9]{16,}|github_pat_[A-Za-z0-9_]{16,})|https?://[^\s/:@]+:[^\s/@]+@') { throw 'E02_SECRET_IN_EVIDENCE' }
}
function Check-JsonElement($Element,[int] $Depth) {
    if ($Depth -gt 80) { throw 'E02_JSON_DEPTH' }
    switch ($Element.ValueKind.ToString()) {
        'Object' {
            $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
            foreach ($p in $Element.EnumerateObject()) {
                if (-not $seen.Add($p.Name)) { throw 'E02_JSON_DUPLICATE_OR_CASE_COLLIDING_KEY' }
                Safe-Text $p.Name; Check-JsonElement $p.Value ($Depth+1)
            }
        }
        'Array' { foreach ($v in $Element.EnumerateArray()) { Check-JsonElement $v ($Depth+1) } }
        'String' { Safe-Text $Element.GetString() }
    }
}
function Read-Json([string] $Path) {
    $plain=Need-File $Path
    if(([IO.FileInfo]::new($plain)).Length -gt 64MB){throw 'E02_JSON_SIZE'}
    $bytes = [IO.File]::ReadAllBytes($plain)
    if ($bytes.Length -gt 64MB) { throw 'E02_JSON_SIZE' }
    $text = $script:Utf8.GetString($bytes); Safe-Text $text
    $options = [Text.Json.JsonDocumentOptions]::new(); $options.MaxDepth=80
    $doc = [Text.Json.JsonDocument]::Parse($text,$options)
    try { Check-JsonElement $doc.RootElement 0 } finally { $doc.Dispose() }
    return ConvertFrom-Json -InputObject $text -AsHashtable -Depth 80 -DateKind String
}
function Failure($Record,[string] $Stage) {
    $message=$Record.Exception.Message
    try { Safe-Text $message } catch { $message='E02_REDACTED_FAILURE_DETAILS' }
    return [ordered]@{stage=$Stage;type=$Record.Exception.GetType().FullName;message=$message}
}
function Write-JsonNew([string] $Path,$Value,[switch] $InjectFailure) {
    $target = Under $Path $script:RunRoot
    $text = ConvertTo-Json -InputObject $Value -Depth 80
    Safe-Text $text
    $doc = [Text.Json.JsonDocument]::Parse($text)
    try { Check-JsonElement $doc.RootElement 0 } finally { $doc.Dispose() }
    # Publish only after a successful flush AND close of a fresh owned temporary.
    # A late close error cannot leave an apparently successful result.json that
    # a dependent phase could accept. Retain failed temporaries for diagnosis.
    $pending=Under ($target+'.pending-'+[Guid]::NewGuid().ToString('N')) $script:RunRoot
    $stream=$null; $primary=$null
    try {
        if ($InjectFailure) { throw 'E02_INJECTED_EVIDENCE_WRITE_FAILURE' }
        if([IO.File]::Exists($target) -or [IO.Directory]::Exists($target)){throw 'E02_JSON_ALREADY_EXISTS'}
        $stream=[IO.File]::Open($pending,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
        $bytes=$script:Utf8.GetBytes($text+"`n"); $stream.Write($bytes,0,$bytes.Length); $stream.Flush($true)
    } catch { $primary=$_; throw }
    finally {
        if ($null -ne $stream) {
            try { $stream.Dispose() } catch {
                $script:Errors.Add((Failure $_ 'json-close'))
                if ($null -eq $primary) { throw }
            }
        }
    }
    [IO.File]::Move($pending,$target,$false)
}
function New-Directory([string] $Path) {
    $target=Under $Path $script:RunRoot
    if ([IO.File]::Exists($target) -or [IO.Directory]::Exists($target)) { throw 'E02_OUTPUT_ALREADY_EXISTS' }
    [void][IO.Directory]::CreateDirectory($target); [void](Assert-Path $target)
}
function Review-Input([string] $Path) {
    $full=Under $Path (Join-Path $script:Repo '.local\reviews')
    $relative=[IO.Path]::GetRelativePath((Join-Path $script:Repo '.local\reviews'),$full).Replace('\','/')
    if ($relative -cnotmatch '^E02[^/]*/') { throw 'E02_REVIEW_INPUT_NOT_OWNED' }
    return Need-File $full
}
function Get-Head {
    $git=Join-Path $script:Repo '.git'
    if (-not [IO.Directory]::Exists($git)) { throw 'E02_GIT_DIRECTORY_REQUIRED' }
    $head=[IO.File]::ReadAllText((Need-File (Join-Path $git 'HEAD'))).Trim()
    if ($head -match '^ref: (refs/[A-Za-z0-9_./-]+)$') {
        $refName=$Matches[1];$refPath=Under (Join-Path $git $refName) $git
        if ([IO.File]::Exists($refPath)) { $head=[IO.File]::ReadAllText((Need-File $refPath)).Trim() }
        else {
            $lines=[IO.File]::ReadAllLines((Need-File (Join-Path $git 'packed-refs')))
            $matchesRef=@($lines | Where-Object { $_ -match ('^[0-9a-f]{40} '+[regex]::Escape($refName)+'$') })
            if ($matchesRef.Count -ne 1) { throw 'E02_GIT_REF_UNAVAILABLE' }; $head=$matchesRef[0].Split(' ')[0]
        }
    }
    if ($head -cnotmatch '^[0-9a-f]{40}$') { throw 'E02_GIT_HEAD_INVALID' }; return $head
}
function Snapshot-Authored([string] $Root) {
    $items=[Collections.Generic.List[object]]::new()
    $descriptor=Join-Path $Root 'WarhammerClient.uproject'; $d=Descriptor $descriptor
    $items.Add([ordered]@{path='WarhammerClient.uproject';kind='file';bytes=$d.bytes;sha256=$d.sha256})
    foreach ($top in @('Source','Config')) {
        $dir=Assert-Path (Join-Path $Root $top)
        if (-not [IO.Directory]::Exists($dir)) { throw 'E02_AUTHORED_DIRECTORY_ABSENT' }
        $items.Add([ordered]@{path=$top;kind='directory'})
        foreach ($entry in Get-ChildItem -LiteralPath $dir -Force -Recurse | Sort-Object FullName) {
            [void](Assert-Path $entry.FullName)
            $rel=[IO.Path]::GetRelativePath($Root,$entry.FullName).Replace('\','/')
            if ($entry.PSIsContainer) { $items.Add([ordered]@{path=$rel;kind='directory'}) }
            else { $d=Descriptor $entry.FullName; $items.Add([ordered]@{path=$rel;kind='file';bytes=$d.bytes;sha256=$d.sha256}) }
        }
    }
    return @($items | Sort-Object { $_.path })
}
function Same-Snapshot($Before,$After) {
    if ((ConvertTo-Json -InputObject @($Before) -Depth 12 -Compress) -cne (ConvertTo-Json -InputObject @($After) -Depth 12 -Compress)) { throw 'E02_AUTHORED_MEMBERSHIP_OR_BYTES_CHANGED' }
}
function Check-CompilerInputs($Manifest) {
    $inputSet=$Manifest.compilerInputs
    $entry=[Reflection.Assembly]::GetEntryAssembly()
    $referenceAnchor=if($null -ne $entry){$entry.Location}else{[Management.Automation.PSObject].Assembly.Location}
    $actualReferenceRoot=Join-Path ([IO.Path]::GetDirectoryName($referenceAnchor)) 'ref'
    if($null -eq $inputSet -or $inputSet.powerShellHome -ine $PSHOME -or
        $inputSet.referenceRoot -ine (Join-Path $PSHOME 'ref') -or $inputSet.referenceRoot -ine $actualReferenceRoot){throw 'E02_COMPILER_INPUT_ROOTS'}
    $expectedRoslyn=@((Join-Path $PSHOME 'Microsoft.CodeAnalysis.dll'),(Join-Path $PSHOME 'Microsoft.CodeAnalysis.CSharp.dll'))
    $roslyn=@($inputSet.roslyn)
    if($roslyn.Count -ne 2){throw 'E02_ROSLYN_INPUT_SET'}
    foreach($path in $expectedRoslyn){
        $match=@($roslyn|Where-Object {$_.path -ieq $path})
        if($match.Count -ne 1){throw 'E02_ROSLYN_INPUT_MISSING_OR_DUPLICATED'}
        $actual=Check-Descriptor $match[0]
        if(@($Manifest.files|Where-Object {$_.path -ieq $actual.path -and $_.sha256 -ieq $actual.sha256 -and $_.bytes -eq $actual.bytes}).Count -ne 1){throw 'E02_ROSLYN_INPUT_NOT_FROZEN'}
        $assemblyName=[IO.Path]::GetFileNameWithoutExtension($path)
        foreach($assembly in [AppDomain]::CurrentDomain.GetAssemblies()){
            if($assembly.GetName().Name -ceq $assemblyName -and $assembly.Location -ine $path){throw 'E02_ROSLYN_LOADED_FROM_OTHER_PATH'}
        }
    }
    $referenceRoot=Assert-Path $inputSet.referenceRoot
    $actualReferences=@([IO.Directory]::EnumerateFiles($referenceRoot,'*.dll',[IO.SearchOption]::TopDirectoryOnly)|ForEach-Object {
        $d=Descriptor $_
        [ordered]@{relativePath=[IO.Path]::GetFileName($d.path);path=$d.path;bytes=$d.bytes;sha256=$d.sha256}
    }|Sort-Object { $_.relativePath } -CaseSensitive)
    $frozenReferences=@($inputSet.references|Sort-Object { $_.relativePath } -CaseSensitive)
    if($actualReferences.Count -eq 0 -or $actualReferences.Count -ne $frozenReferences.Count){throw 'E02_REFERENCE_ASSEMBLY_MEMBERSHIP_CHANGED'}
    for($i=0;$i -lt $actualReferences.Count;$i++){
        $a=$actualReferences[$i];$f=$frozenReferences[$i]
        if($f.relativePath -isnot [string] -or $f.relativePath -cne $a.relativePath -or $f.bytes -ne $a.bytes -or $f.sha256 -ine $a.sha256){throw 'E02_REFERENCE_ASSEMBLY_MEMBERSHIP_OR_BYTES_CHANGED'}
        if(@($Manifest.files|Where-Object {$_.path -ieq $a.path -and $_.sha256 -ieq $a.sha256 -and $_.bytes -eq $a.bytes}).Count -ne 1){throw 'E02_REFERENCE_ASSEMBLY_NOT_FROZEN'}
    }
    return [ordered]@{powerShellHome=$PSHOME;roslyn=$roslyn;referenceRoot=$referenceRoot;referenceCount=$actualReferences.Count;references=$frozenReferences}
}
function Check-DotnetSdk($Manifest) {
    $sdk=$Manifest.dotnetSdk
    if($null -eq $sdk -or $sdk.version -isnot [string] -or $sdk.version -cnotmatch '^10\.0\.[0-9]+$'){throw 'E02_DOTNET_SDK_SHAPE'}
    $root=[IO.Path]::GetDirectoryName($Manifest.toolPaths.dotnet)
    if($sdk.directory -ine (Join-Path $root ('sdk/'+$sdk.version))){throw 'E02_DOTNET_SDK_DIRECTORY'}
    $version=Check-Descriptor $sdk.versionFile
    if($version.path -ine (Join-Path $sdk.directory '.version') -or
        @($Manifest.files|Where-Object {$_.path -ieq $version.path -and $_.sha256 -ieq $version.sha256 -and $_.bytes -eq $version.bytes}).Count -ne 1){throw 'E02_DOTNET_SDK_VERSION_FILE_NOT_FROZEN'}
    $lines=[IO.File]::ReadAllLines($version.path)
    if($lines.Length -lt 2 -or $lines[1] -cne $sdk.version){throw 'E02_DOTNET_SDK_VERSION_FILE_MISMATCH'}
    return [ordered]@{version=$sdk.version;directory=$sdk.directory;versionFile=$version}
}
function Check-Freeze {
    if (-not $FreezeManifestPath) { throw 'BLOCKED_E02_FREEZE_MANIFEST_REQUIRED' }
    [void](Review-Input $FreezeManifestPath)
    $manifest=Read-Json $FreezeManifestPath
    if ($manifest.schemaVersion -ne 1 -or $manifest.sourceHead -cnotmatch '^[0-9a-f]{40}$' -or $manifest.sourceHead -cne (Get-Head)) { throw 'E02_SOURCE_HEAD_MISMATCH' }
    $packet=Check-Descriptor $manifest.packet
    if ($packet.path -ine $script:Packet) { throw 'E02_WRONG_PACKET' }
    $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($d in $manifest.files) { $actual=Check-Descriptor $d; if (-not $seen.Add($actual.path)) { throw 'E02_DUPLICATE_FROZEN_FILE' } }
    foreach ($required in @($PSCommandPath,$script:Fixture,$script:Packet,(Join-Path $script:Repo 'AGENTS.md'),(Join-Path (Split-Path $script:Repo -Parent) 'AGENTS.md'))) {
        if (-not $seen.Contains([IO.Path]::GetFullPath($required))) { throw 'E02_FROZEN_INPUT_OMITTED' }
    }
    $actualSource=@(Snapshot-Authored $script:Repo)
    $membership=@($manifest.sourceMembership | Sort-Object { $_.path })
    if ($membership.Count -ne $actualSource.Count) { throw 'E02_SOURCE_MEMBERSHIP_COUNT' }
    for($i=0;$i -lt $actualSource.Count;$i++) {
        if ($membership[$i].path -cne $actualSource[$i].path -or $membership[$i].kind -cne $actualSource[$i].kind) { throw 'E02_SOURCE_MEMBERSHIP_MISMATCH' }
        if ($actualSource[$i].kind -eq 'file' -and -not $seen.Contains([IO.Path]::GetFullPath((Join-Path $script:Repo $actualSource[$i].path)))) { throw 'E02_AUTHORED_FILE_NOT_FROZEN' }
    }
    foreach ($name in @('buildBat','editor','editorCmd','compiler','dotnet','sdkRc','cmd','where','getDotnetPath')) {
        $tool=Need-File $manifest.toolPaths[$name]
        if (-not $seen.Contains($tool)) { throw 'E02_TOOL_NOT_FROZEN' }
    }
    [void](Review-Input $manifest.pluginClosure.path)
    $closureInput=Check-Descriptor $manifest.pluginClosure
    if(-not $seen.Contains($closureInput.path)){throw 'E02_PLUGIN_CLOSURE_NOT_FROZEN'}
    foreach($runtimePath in @([Environment]::ProcessPath,[object].Assembly.Location,[Management.Automation.PSObject].Assembly.Location,
        [Text.Json.JsonDocument].Assembly.Location,[IO.Compression.ZLibStream].Assembly.Location)) {
        if(-not $seen.Contains((Need-File $runtimePath))){throw 'E02_LOADED_SUPERVISOR_RUNTIME_NOT_FROZEN'}
    }
    $versionPath=Join-Path $EngineRoot 'Engine\Build\Build.version'
    $version=Read-Json $versionPath
    if (-not $seen.Contains([IO.Path]::GetFullPath($versionPath)) -or $version.MajorVersion -ne 5 -or $version.MinorVersion -ne 8 -or $version.PatchVersion -ne 3 -or $version.Changelist -ne 58210709) { throw 'E02_ENGINE_VERSION' }
    if ($manifest.toolPaths.buildBat -ine (Join-Path $EngineRoot 'Engine\Build\BatchFiles\Build.bat') -or
        $manifest.toolPaths.editor -ine (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.exe') -or
        $manifest.toolPaths.editorCmd -ine (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor-Cmd.exe') -or
        $manifest.toolPaths.dotnet -ine (Join-Path $EngineRoot 'Engine\Binaries\ThirdParty\DotNet\10.0\win-x64\dotnet.exe') -or
        $manifest.toolPaths.getDotnetPath -ine (Join-Path $EngineRoot 'Engine\Build\BatchFiles\GetDotnetPath.bat') -or
        $manifest.toolPaths.cmd -ine (Join-Path ([Environment]::SystemDirectory) 'cmd.exe') -or
        $manifest.toolPaths.where -ine (Join-Path ([Environment]::SystemDirectory) 'where.exe')) { throw 'E02_ENGINE_TOOL_PATH' }
    if ((Get-Item -LiteralPath $manifest.toolPaths.compiler).VersionInfo.ProductVersion -ne '14.44.35229.0' -or $manifest.toolPaths.sdkRc -notmatch '10\.0\.22621\.0[\\/]x64[\\/]rc\.exe$') { throw 'E02_COMPILER_OR_SDK' }
    $compilerInputs=Check-CompilerInputs $manifest
    $dotnetSdk=Check-DotnetSdk $manifest
    $script:Freeze=$manifest
    return [ordered]@{manifest=(Descriptor $FreezeManifestPath);sourceHead=$manifest.sourceHead;packet=$packet;authored=$actualSource;fileCount=$seen.Count;toolPaths=$manifest.toolPaths;engineVersion=$version;compilerInputs=$compilerInputs;dotnetSdk=$dotnetSdk}
}
function Check-Authority {
    if (-not $AuthorityPath) { throw 'BLOCKED_E02_EXECUTION_AUTHORITY_REQUIRED' }
    [void](Review-Input $AuthorityPath); $auth=Read-Json $AuthorityPath
    if ($auth.schemaVersion -ne 1 -or $auth.runId -cne $RunId -or $auth.explicitCoordinatorGo -isnot [bool] -or -not $auth.explicitCoordinatorGo -or $Phase -cnotin @($auth.allowedPhases)) { throw 'BLOCKED_E02_AUTHORITY_SCOPE' }
    $bound=Check-Descriptor $auth.freezeManifest
    if ($bound.path -ine [IO.Path]::GetFullPath($FreezeManifestPath)) { throw 'E02_AUTHORITY_FREEZE_MISMATCH' }
    if ($auth.sourceReviewed.sourceHead -cne $script:Freeze.sourceHead -or $auth.sourceReviewed.status -cne 'PASS') { throw 'BLOCKED_E02_SOURCE_REVIEW' }
    if($auth.sourceReviewed.pluginClosureReviewed -isnot [bool] -or -not $auth.sourceReviewed.pluginClosureReviewed){throw 'BLOCKED_E02_PLUGIN_CLOSURE_REVIEW_REQUIRED'}
    [void](Review-Input $auth.sourceReviewed.report.path); [void](Check-Descriptor $auth.sourceReviewed.report)
    if ($Phase -in @('Discovery','WorldInput')) {
        if (-not $AllowVisibleWindow -or $auth.visibleWindowOwnerApproval.status -cne 'APPROVED') { throw 'BLOCKED_E02_VISIBLE_OWNER_APPROVAL' }
        [void](Review-Input $auth.visibleWindowOwnerApproval.reference.path)
        [void](Check-Descriptor $auth.visibleWindowOwnerApproval.reference)
    } elseif ($AllowVisibleWindow) { throw 'E02_VISIBLE_SWITCH_WRONG_PHASE' }
    return [ordered]@{record=(Descriptor $AuthorityPath);sourceReview=$auth.sourceReviewed;visibleWindowOwnerApproval=$(if ($Phase -in @('Discovery','WorldInput')) {$auth.visibleWindowOwnerApproval} else {$null})}
}

# This literal is compiled ONLY after the real external source-review/authority
# checks. Merely parsing this .ps1 does not compile it or create any OS resource.
$script:NativeSource = @'
using System;
using System.IO;
using System.IO.Compression;
using System.Text;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Threading;

namespace Warhammer.E02 {
public static class Supervisor {
    const uint QUERY=0x0400, SYNCHRONIZE=0x00100000, CREATE_SUSPENDED=4,
        UNICODE_ENV=0x400, EXTENDED=0x80000, NO_WINDOW=0x08000000,
        KILL_ON_CLOSE=0x2000, WAIT_OBJECT_0=0, WAIT_TIMEOUT=258;
    const uint INVALID=0xffffffff;
    static readonly IntPtr InvalidHandle=new IntPtr(-1);
    [StructLayout(LayoutKind.Sequential)] struct SA { public int n; public IntPtr sd; [MarshalAs(UnmanagedType.Bool)] public bool inherit; }
    [StructLayout(LayoutKind.Sequential,CharSet=CharSet.Unicode)] struct SI {
        public int cb; public string reserved,desktop,title;
        public uint x,y,xSize,ySize,xChars,yChars,fill,flags;
        public short show,reservedBytes; public IntPtr reserved2,input,output,error;
    }
    [StructLayout(LayoutKind.Sequential)] struct SIX { public SI info; public IntPtr attributes; }
    [StructLayout(LayoutKind.Sequential)] struct PI { public IntPtr process,thread; public uint pid,tid; }
    [StructLayout(LayoutKind.Sequential)] struct BASIC {
        public long processTime,jobTime; public uint flags; public UIntPtr minimum,maximum;
        public uint activeLimit; public UIntPtr affinity; public uint priority,scheduling;
    }
    [StructLayout(LayoutKind.Sequential)] struct IO {
        public ulong readOps,writeOps,otherOps,readBytes,writeBytes,otherBytes;
    }
    [StructLayout(LayoutKind.Sequential)] struct LIMIT {
        public BASIC basic; public IO io; public UIntPtr processMemory,jobMemory,peakProcess,peakJob;
    }
    [StructLayout(LayoutKind.Sequential)] struct ACCOUNT {
        public long user,kernel,periodUser,periodKernel;
        public uint faults,total,active,terminatedByLimit;
    }
    [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)] static extern IntPtr CreateJobObjectW(IntPtr sa,string name);
    [DllImport("kernel32.dll",SetLastError=true)] static extern bool SetInformationJobObject(IntPtr job,int cls,ref LIMIT info,uint size);
    [DllImport("kernel32.dll",SetLastError=true)] static extern bool QueryInformationJobObject(IntPtr job,int cls,ref ACCOUNT info,uint size,out uint returned);
    [DllImport("kernel32.dll",SetLastError=true)] static extern bool QueryInformationJobObject(IntPtr job,int cls,ref LIMIT info,uint size,out uint returned);
    [DllImport("kernel32.dll",SetLastError=true)] static extern bool AssignProcessToJobObject(IntPtr job,IntPtr process);
    [DllImport("kernel32.dll",SetLastError=true)] static extern bool IsProcessInJob(IntPtr process,IntPtr job,out bool inside);
    [DllImport("kernel32.dll",SetLastError=true)] static extern bool TerminateJobObject(IntPtr job,uint exit);
    [DllImport("kernel32.dll",SetLastError=true)] static extern bool TerminateProcess(IntPtr process,uint exit);
    [DllImport("kernel32.dll",SetLastError=true)] static extern uint WaitForSingleObject(IntPtr handle,uint milliseconds);
    [DllImport("kernel32.dll",SetLastError=true)] static extern uint ResumeThread(IntPtr thread);
    [DllImport("kernel32.dll",SetLastError=true)] static extern bool GetProcessTimes(IntPtr process,out long creation,out long exit,out long kernel,out long user);
    [DllImport("kernel32.dll",SetLastError=true)] static extern bool GetExitCodeProcess(IntPtr process,out uint exit);
    [DllImport("kernel32.dll",SetLastError=true)] static extern bool CloseHandle(IntPtr handle);
    [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)] static extern IntPtr CreateFileW(string path,uint access,uint share,ref SA attributes,uint creation,uint flags,IntPtr template);
    [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)] static extern bool CreateProcessW(string exe,StringBuilder command,IntPtr processSa,IntPtr threadSa,bool inherit,uint flags,IntPtr environment,string cwd,ref SIX startup,out PI process);
    [DllImport("kernel32.dll",SetLastError=true)] static extern bool InitializeProcThreadAttributeList(IntPtr list,int count,uint flags,ref IntPtr bytes);
    [DllImport("kernel32.dll",SetLastError=true)] static extern bool UpdateProcThreadAttribute(IntPtr list,uint flags,IntPtr attribute,IntPtr value,IntPtr bytes,IntPtr previous,IntPtr returned);
    [DllImport("kernel32.dll")] static extern void DeleteProcThreadAttributeList(IntPtr list);
    delegate bool EnumWindow(IntPtr window,IntPtr parameter);
    [DllImport("user32.dll")] static extern bool EnumWindows(EnumWindow callback,IntPtr parameter);
    [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr window,out uint pid);
    [DllImport("user32.dll",SetLastError=true)] static extern bool PostMessageW(IntPtr window,uint message,IntPtr wparam,IntPtr lparam);

    static string Utc() { return DateTime.UtcNow.ToString("o"); }
    static void WinCheck(bool success,string operation) { if(!success) throw new Win32Exception(Marshal.GetLastWin32Error(),operation); }
    static Dictionary<string,object> Error(string stage,Exception e,bool injected=false) {
        return new Dictionary<string,object>{{"stage",stage},{"type",e.GetType().FullName},{"message",e.Message},
            {"win32Error",e is Win32Exception ? (object)((Win32Exception)e).NativeErrorCode : null},{"syntheticFault",injected},{"observedUtc",Utc()}};
    }
    // Windows command-line quoting, not shell escaping. Build.bat is invoked by
    // the fixed reviewed PowerShell command below; no caller text is shell code.
    public static string Quote(string argument) {
        if(argument.IndexOf('\0')>=0) throw new ArgumentException("NUL argument");
        var b=new StringBuilder("\""); int slashes=0;
        foreach(char c in argument) {
            if(c=='\\') { slashes++; continue; }
            if(c=='\"') { b.Append('\\',slashes*2+1); b.Append(c); slashes=0; continue; }
            b.Append('\\',slashes); slashes=0; b.Append(c);
        }
        b.Append('\\',slashes*2); return b.Append('"').ToString();
    }
    static void Close(ref IntPtr handle,string name,List<object> errors) {
        if(handle==IntPtr.Zero || handle==InvalidHandle) return;
        IntPtr old=handle; handle=IntPtr.Zero;
        if(!CloseHandle(old)) errors.Add(Error("close-"+name,new Win32Exception(Marshal.GetLastWin32Error())));
    }
    static Dictionary<string,object> Count(IntPtr job,List<object> samples,string stage) {
        ACCOUNT a=new ACCOUNT(); uint length;
        WinCheck(QueryInformationJobObject(job,1,ref a,(uint)Marshal.SizeOf<ACCOUNT>(),out length),"QueryInformationJobObject(accounting)");
        if(length!=(uint)Marshal.SizeOf<ACCOUNT>()) throw new InvalidDataException("Accounting size mismatch");
        var value=new Dictionary<string,object>{{"stage",stage},{"observedUtc",Utc()},{"querySucceeded",true},
            {"totalProcesses",a.total},{"activeProcesses",a.active},{"totalTerminatedProcesses",a.terminatedByLimit},
            {"totalUserTime100ns",a.user},{"totalKernelTime100ns",a.kernel},{"thisPeriodUserTime100ns",a.periodUser},
            {"thisPeriodKernelTime100ns",a.periodKernel},{"totalPageFaultCount",a.faults}};
        samples.Add(value); return value;
    }
    static void RootFinal(IntPtr process,Dictionary<string,object> r) {
        long creation,exit,kernel,user; uint code;
        WinCheck(GetProcessTimes(process,out creation,out exit,out kernel,out user),"GetProcessTimes(exit)");
        WinCheck(GetExitCodeProcess(process,out code),"GetExitCodeProcess");
        if(WaitForSingleObject(process,0)!=WAIT_OBJECT_0 || exit<=0) throw new InvalidDataException("Root exit not confirmed");
        r["creationFileTime"]=creation; r["creationUtc"]=DateTime.FromFileTimeUtc(creation).ToString("o");
        r["exitFileTime"]=exit; r["exitUtc"]=DateTime.FromFileTimeUtc(exit).ToString("o"); r["exitCode"]=code;
        r["exitObservedUtc"]=Utc(); r["exitConfirmed"]=true;
    }
    static void Graceful(uint rootPid,List<object> records) {
        EnumWindow callback=(window,parameter)=> {
            uint actual; GetWindowThreadProcessId(window,out actual);
            if(actual==rootPid) {
                bool ok=PostMessageW(window,0x10,IntPtr.Zero,IntPtr.Zero);
                records.Add(new Dictionary<string,object>{{"operation","WM_CLOSE"},{"rootPid",rootPid},{"posted",ok},
                    {"observedUtc",Utc()},{"win32Error",ok ? null : (object)Marshal.GetLastWin32Error()}});
            }
            return true;
        };
        EnumWindows(callback,IntPtr.Zero); GC.KeepAlive(callback);
    }

    public static Dictionary<string,object> Run(string exe,string[] arguments,string cwd,
        Dictionary<string,string> environment,string stdout,string stderr,int seconds,bool visible,string syntheticFault) {
        if(seconds<3 || seconds>1800) throw new ArgumentOutOfRangeException("seconds");
        var errors=new List<object>(); var samples=new List<object>(); var shutdown=new List<object>();
        var r=new Dictionary<string,object>{{"schemaVersion",1},{"executable",exe},{"arguments",arguments},{"workingDirectory",cwd},
            {"environmentOverrides",environment},{"stdout",stdout},{"stderr",stderr},{"budgetSeconds",seconds},
            {"startedObservationUtc",Utc()},{"pid",null},{"creationFileTime",null},{"creationUtc",null},{"exitFileTime",null},
            {"exitUtc",null},{"exitCode",null},{"exitConfirmed",false},{"assignedBeforeResume",false},{"resumed",false},
            {"timedOut",false},{"cleanupConfirmed",false},{"technicalBlocked",false},{"rootExitWhileMembersActive",false},{"jobAccounting",samples},
            {"shutdownRequests",shutdown},{"secondaryErrors",errors},{"primaryFailure",null},{"syntheticFault",syntheticFault},
            {"descendantInventory","NOT_COLLECTED; optional observations are incomplete"},{"visibleWindowRequested",visible}};
        IntPtr job=IntPtr.Zero, attr=IntPtr.Zero, handles=IntPtr.Zero, env=IntPtr.Zero;
        IntPtr outFile=IntPtr.Zero,errFile=IntPtr.Zero,input=IntPtr.Zero;
        PI process=new PI(); bool assigned=false, exited=false, timed=false, initialized=false;
        var clock=Stopwatch.StartNew(); double grace=Math.Min(15,seconds/4.0),reserve=Math.Min(5,seconds/4.0);
        try {
            job=CreateJobObjectW(IntPtr.Zero,null); if(job==IntPtr.Zero) throw new Win32Exception(Marshal.GetLastWin32Error(),"CreateJobObject");
            LIMIT limits=new LIMIT(); limits.basic.flags=KILL_ON_CLOSE;
            WinCheck(SetInformationJobObject(job,9,ref limits,(uint)Marshal.SizeOf<LIMIT>()),"SetInformationJobObject");
            uint length; LIMIT effective=new LIMIT();
            WinCheck(QueryInformationJobObject(job,9,ref effective,(uint)Marshal.SizeOf<LIMIT>(),out length),"QueryInformationJobObject(limits)");
            if(length!=(uint)Marshal.SizeOf<LIMIT>() || effective.basic.flags!=KILL_ON_CLOSE) throw new InvalidDataException("Private job flags differ");
            r["jobLimitFlags"]=effective.basic.flags; r["privateUnnamedJob"]=true; r["jobHandleInherited"]=false;
            var sa=new SA{n=Marshal.SizeOf<SA>(),sd=IntPtr.Zero,inherit=true};
            outFile=CreateFileW(stdout,0x40000000,1,ref sa,1,0x80,IntPtr.Zero);
            if(outFile==InvalidHandle) throw new Win32Exception(Marshal.GetLastWin32Error(),"CreateFile(stdout)");
            errFile=CreateFileW(stderr,0x40000000,1,ref sa,1,0x80,IntPtr.Zero);
            if(errFile==InvalidHandle) throw new Win32Exception(Marshal.GetLastWin32Error(),"CreateFile(stderr)");
            input=CreateFileW("NUL",0x80000000,3,ref sa,3,0x80,IntPtr.Zero);
            if(input==InvalidHandle) throw new Win32Exception(Marshal.GetLastWin32Error(),"CreateFile(NUL)");
            IntPtr attrBytes=IntPtr.Zero; InitializeProcThreadAttributeList(IntPtr.Zero,1,0,ref attrBytes);
            if(attrBytes==IntPtr.Zero) throw new Win32Exception(Marshal.GetLastWin32Error(),"Attribute-list size");
            attr=Marshal.AllocHGlobal(attrBytes); WinCheck(InitializeProcThreadAttributeList(attr,1,0,ref attrBytes),"InitializeProcThreadAttributeList"); initialized=true;
            handles=Marshal.AllocHGlobal(IntPtr.Size*3); Marshal.WriteIntPtr(handles,0,input); Marshal.WriteIntPtr(handles,IntPtr.Size,outFile); Marshal.WriteIntPtr(handles,IntPtr.Size*2,errFile);
            WinCheck(UpdateProcThreadAttribute(attr,0,new IntPtr(0x20002),handles,new IntPtr(IntPtr.Size*3),IntPtr.Zero,IntPtr.Zero),"UpdateProcThreadAttribute(HANDLE_LIST)");
            var startup=new SIX { info=new SI{cb=Marshal.SizeOf<SIX>(),flags=0x100|1,show=(short)(visible?5:0),input=input,output=outFile,error=errFile}, attributes=attr };
            var command=new StringBuilder(Quote(exe)); foreach(string argument in arguments) command.Append(' ').Append(Quote(argument));
            var vars=new SortedDictionary<string,string>(StringComparer.OrdinalIgnoreCase);
            foreach(System.Collections.DictionaryEntry entry in Environment.GetEnvironmentVariables()) {
                string key=(string)entry.Key;
                if(key.IndexOfAny(new[]{'\0','='})>=0 || key.Equals("UE_ADDITIONAL_PLUGIN_PATHS",StringComparison.OrdinalIgnoreCase) || System.Text.RegularExpressions.Regex.IsMatch(key,"TOKEN|PASSWORD|SECRET|API_KEY|CREDENTIAL",System.Text.RegularExpressions.RegexOptions.IgnoreCase)) continue;
                vars[key]=(string)entry.Value;
            }
            foreach(var pair in environment) { if(pair.Key.IndexOfAny(new[]{'\0','='})>=0 || pair.Value.IndexOf('\0')>=0) throw new ArgumentException("Environment NUL/key"); vars[pair.Key]=pair.Value; }
            var block=new StringBuilder(); foreach(var pair in vars) block.Append(pair.Key).Append('=').Append(pair.Value).Append('\0'); block.Append('\0');
            env=Marshal.StringToHGlobalUni(block.ToString());
            WinCheck(CreateProcessW(exe,command,IntPtr.Zero,IntPtr.Zero,true,CREATE_SUSPENDED|UNICODE_ENV|EXTENDED|(visible?0:NO_WINDOW),env,cwd,ref startup,out process),"CreateProcess(suspended)");
            r["pid"]=process.pid;
            long creation,exit,kernel,user; WinCheck(GetProcessTimes(process.process,out creation,out exit,out kernel,out user),"GetProcessTimes(creation)");
            r["creationFileTime"]=creation; r["creationUtc"]=DateTime.FromFileTimeUtc(creation).ToString("o");
            if(syntheticFault=="assign") throw new InvalidOperationException("E02_INJECTED_ASSIGN_FAILURE_BEFORE_RESUME");
            WinCheck(AssignProcessToJobObject(job,process.process),"AssignProcessToJobObject"); assigned=true;
            bool inside; WinCheck(IsProcessInJob(process.process,job,out inside),"IsProcessInJob");
            if(!inside) throw new InvalidDataException("Root not in retained private job");
            r["assignedBeforeResume"]=true;
            if(ResumeThread(process.thread)==INVALID) throw new Win32Exception(Marshal.GetLastWin32Error(),"ResumeThread");
            r["resumed"]=true; r["resumedObservationUtc"]=Utc();
            Close(ref process.thread,"root-thread",errors); Close(ref outFile,"stdout-original",errors); Close(ref errFile,"stderr-original",errors); Close(ref input,"stdin-original",errors);
            bool faultUsed=false; bool shutdownStarted=false; double killAt=0; uint? lastActive=null;
            while(clock.Elapsed.TotalSeconds<seconds) {
                if(process.process!=IntPtr.Zero) {
                    uint waited=WaitForSingleObject(process.process,50);
                    if(waited!=WAIT_OBJECT_0 && waited!=WAIT_TIMEOUT) throw new Win32Exception(Marshal.GetLastWin32Error(),"WaitForSingleObject(root)");
                    if(waited==WAIT_OBJECT_0) { RootFinal(process.process,r); exited=true; Close(ref process.process,"root-process",errors); }
                }
                if(syntheticFault=="query" && !faultUsed) { faultUsed=true; throw new InvalidOperationException("E02_INJECTED_ACCOUNTING_QUERY_FAILURE"); }
                ACCOUNT a=new ACCOUNT(); uint n; WinCheck(QueryInformationJobObject(job,1,ref a,(uint)Marshal.SizeOf<ACCOUNT>(),out n),"QueryInformationJobObject(loop)");
                if(n!=(uint)Marshal.SizeOf<ACCOUNT>()) throw new InvalidDataException("Loop accounting size");
                if(lastActive!=a.active || exited && !(bool)r["cleanupConfirmed"]) { Count(job,samples,"progress"); lastActive=a.active; }
                if(exited && a.active>0) r["rootExitWhileMembersActive"]=true;
                if(exited && a.active==0) { r["cleanupConfirmed"]=true; break; }
                double remaining=seconds-clock.Elapsed.TotalSeconds;
                if(!shutdownStarted && remaining<=grace+reserve) {
                    timed=true; r["timedOut"]=true; r["timeoutKind"]="EXECUTION_BUDGET_RESERVED_FOR_SHUTDOWN";
                    shutdownStarted=true; killAt=clock.Elapsed.TotalSeconds+grace;
                    // The original retained root handle prevents PID reuse.
                    // Never address a window by an already-released root PID.
                    if(!exited && process.process!=IntPtr.Zero) Graceful(process.pid,shutdown);
                }
                if(shutdownStarted && clock.Elapsed.TotalSeconds>=killAt) {
                    WinCheck(TerminateJobObject(job,0xe0200001),"TerminateJobObject(timeout)");
                    shutdown.Add(new Dictionary<string,object>{{"operation","TerminateJobObject"},{"succeeded",true},{"observedUtc",Utc()}});
                    killAt=double.PositiveInfinity;
                }
                Thread.Sleep(25);
            }
            if(!(bool)r["cleanupConfirmed"]) { timed=true; r["timedOut"]=true; throw new TimeoutException("Private job cleanup not confirmed within phase bound"); }
            if(timed) throw new TimeoutException("Owned execution exceeded its reserved running budget");
            if(!exited || (uint)r["exitCode"]!=0) throw new InvalidDataException("Root unsuccessful or exit unavailable");
            if(syntheticFault=="close") errors.Add(Error("close-control-seam",new InvalidOperationException("E02_INJECTED_HANDLE_FINALIZATION_FAILURE"),true));
        } catch(Exception e) {
            bool injected=e.Message.StartsWith("E02_INJECTED_",StringComparison.Ordinal);
            r["primaryFailure"]=Error("owned-root",e,injected);
            r["technicalBlocked"]=!injected && !(bool)r["resumed"] && e is Win32Exception;
        }
        finally {
            // Original retained handles establish ownership even when assignment
            // failed. No PID reopening, name search, or Kill(true) is used.
            if(!(bool)r["cleanupConfirmed"]) {
                try {
                    if(assigned) WinCheck(TerminateJobObject(job,0xe0200002),"TerminateJobObject(failure)");
                    else if(process.process!=IntPtr.Zero) WinCheck(TerminateProcess(process.process,0xe0200002),"TerminateProcess(original-suspended-root)");
                    while(clock.Elapsed.TotalSeconds<seconds) {
                        if(process.process!=IntPtr.Zero) {
                            uint waited=WaitForSingleObject(process.process,20);
                            if(waited!=WAIT_OBJECT_0 && waited!=WAIT_TIMEOUT) throw new Win32Exception(Marshal.GetLastWin32Error(),"WaitForSingleObject(cleanup)");
                            if(waited==WAIT_OBJECT_0) { RootFinal(process.process,r); exited=true; Close(ref process.process,"root-process",errors); }
                        }
                        if(job!=IntPtr.Zero) {
                            var final=Count(job,samples,"failure-cleanup");
                            if((uint)final["activeProcesses"]==0 && (process.pid==0 || exited)) { r["cleanupConfirmed"]=true; break; }
                        }
                        Thread.Sleep(25);
                    }
                } catch(Exception e) { errors.Add(Error("failure-cleanup",e)); }
            }
            Close(ref process.thread,"root-thread",errors); Close(ref process.process,"root-process",errors);
            Close(ref outFile,"stdout-original",errors); Close(ref errFile,"stderr-original",errors); Close(ref input,"stdin-original",errors);
            if(initialized) DeleteProcThreadAttributeList(attr);
            if(attr!=IntPtr.Zero) Marshal.FreeHGlobal(attr); if(handles!=IntPtr.Zero) Marshal.FreeHGlobal(handles); if(env!=IntPtr.Zero) Marshal.FreeHGlobal(env);
            Close(ref job,"private-job",errors);
            r["completedObservationUtc"]=Utc(); r["elapsedSeconds"]=clock.Elapsed.TotalSeconds;
            r["status"]=(r["primaryFailure"]==null && errors.Count==0 && (bool)r["exitConfirmed"] && (bool)r["cleanupConfirmed"] && !(bool)r["timedOut"]) ? "PASS" : "FAIL";
        }
        return r;
    }

    static uint BE(byte[] b,int i) { return (uint)b[i]<<24|(uint)b[i+1]<<16|(uint)b[i+2]<<8|b[i+3]; }
    static uint CRC(byte[] b,int start,int count) { uint c=0xffffffff; for(int i=start;i<start+count;i++) { c^=b[i]; for(int bit=0;bit<8;bit++) c=(c>>1)^((c&1)!=0 ? 0xedb88320u:0); } return c^0xffffffff; }
    static int Paeth(int a,int b,int c) { int p=a+b-c,pa=Math.Abs(p-a),pb=Math.Abs(p-b),pc=Math.Abs(p-c); return pa<=pb&&pa<=pc?a:pb<=pc?b:c; }
    // Decode exactly the ordinary noninterlaced8bit RGB/RGBA PNG format used
    // by these UE screenshots. Unsupported encodings fail visibly, never pass.
    public static Dictionary<string,object> DecodePng(string path) {
        long size=new FileInfo(path).Length; if(size<45 || size>64*1024*1024) throw new InvalidDataException("PNG size");
        byte[] b=File.ReadAllBytes(path); byte[] magic={137,80,78,71,13,10,26,10};
        if(b.Length<45 || b.Length>64*1024*1024) throw new InvalidDataException("PNG size");
        for(int i=0;i<8;i++) if(b[i]!=magic[i]) throw new InvalidDataException("PNG signature");
        int width=0,height=0,channels=0,offset=8; bool ihdr=false,end=false;
        using(var compressed=new MemoryStream()) {
            while(offset<b.Length) {
                if(offset+12>b.Length) throw new InvalidDataException("PNG truncated chunk");
                uint length=BE(b,offset); if(length>64*1024*1024 || offset+12L+length>b.Length) throw new InvalidDataException("PNG chunk size");
                int n=(int)length; string kind=Encoding.ASCII.GetString(b,offset+4,4);
                if(CRC(b,offset+4,n+4)!=BE(b,offset+8+n)) throw new InvalidDataException("PNG CRC");
                if(kind=="IHDR") {
                    if(ihdr||offset!=8||n!=13) throw new InvalidDataException("PNG IHDR"); ihdr=true;
                    width=checked((int)BE(b,offset+8)); height=checked((int)BE(b,offset+12));
                    int type=b[offset+17]; channels=type==2?3:type==6?4:0;
                    if(width<=0||height<=0||width>4096||height>4096||b[offset+16]!=8||channels==0||b[offset+18]!=0||b[offset+19]!=0||b[offset+20]!=0) throw new InvalidDataException("Unsupported PNG encoding");
                } else if(kind=="IDAT") { if(!ihdr||end) throw new InvalidDataException("PNG order"); compressed.Write(b,offset+8,n); }
                else if(kind=="IEND") { if(n!=0) throw new InvalidDataException("PNG IEND"); end=true; offset+=12; break; }
                else if((b[offset+4]&32)==0) throw new InvalidDataException("Unsupported critical PNG chunk");
                offset+=n+12;
            }
            if(!ihdr||!end||offset!=b.Length||compressed.Length==0) throw new InvalidDataException("Incomplete PNG");
            compressed.Position=0; int stride=checked(width*channels),expected=checked((stride+1)*height);
            byte[] raw=new byte[expected]; using(var z=new ZLibStream(compressed,CompressionMode.Decompress,true)) {
                int read=0,n; while(read<expected && (n=z.Read(raw,read,expected-read))>0) read+=n;
                if(read!=expected||z.ReadByte()!=-1) throw new InvalidDataException("PNG decompressed size");
            }
            byte[] prior=new byte[stride],row=new byte[stride]; var colors=new HashSet<uint>(); int minimum=255,maximum=0;
            for(int y=0;y<height;y++) {
                int p=y*(stride+1),filter=raw[p++]; if(filter>4) throw new InvalidDataException("PNG filter");
                for(int x=0;x<stride;x++) {
                    int left=x>=channels?row[x-channels]:0,up=prior[x],corner=x>=channels?prior[x-channels]:0;
                    int predictor=filter==0?0:filter==1?left:filter==2?up:filter==3?(left+up)/2:Paeth(left,up,corner);
                    row[x]=unchecked((byte)(raw[p+x]+predictor));
                }
                for(int x=0;x<stride;x+=channels) {
                    uint rgb=(uint)row[x]<<16|(uint)row[x+1]<<8|row[x+2]; if(colors.Count<256) colors.Add(rgb);
                    for(int c=0;c<3;c++) { minimum=Math.Min(minimum,row[x+c]); maximum=Math.Max(maximum,row[x+c]); }
                }
                var swap=prior;prior=row;row=swap;
            }
            if(colors.Count<8 || maximum-minimum<16) throw new InvalidDataException("PNG framebuffer blank/insufficient variation");
            return new Dictionary<string,object>{{"width",width},{"height",height},{"decoded",true},{"rgbColorCountCapped256",colors.Count},
                {"minimumRgb",minimum},{"maximumRgb",maximum},{"encoding","noninterlaced8bitRGB/RGBA"},{"visualGeometryInspection","REQUIRED_SEPARATELY"}};
        }
    }
}
}
'@

function Enable-NativeHelper {
    [void](Check-CompilerInputs $script:Freeze)
    if ($null -eq ('Warhammer.E02.Supervisor' -as [type])) { Add-Type -TypeDefinition $script:NativeSource -Language CSharp -ErrorAction Stop }
}

function Observed-File([string] $Role,[string] $Path) {
    $r=[ordered]@{role=$Role;path=[IO.Path]::GetFullPath($Path);observedUtc=[DateTime]::UtcNow.ToString('o');inspection='UNAVAILABLE';exists=$null;sha256=$null}
    try {
        $absent=$false
        try { $attributes=[IO.File]::GetAttributes($r.path) }
        catch [IO.FileNotFoundException] { $absent=$true } catch [IO.DirectoryNotFoundException] { $absent=$true }
        $r.exists=-not $absent
        if (-not $absent) {
            if (($attributes -band ([IO.FileAttributes]::Directory -bor [IO.FileAttributes]::ReparsePoint)) -ne 0) { throw 'E02_SETTINGS_NOT_PLAIN_FILE' }
            $r.sha256=Digest $r.path
        }
        $r.inspection='PASS'
    } catch { $r.error=Failure $_ 'settings-observation' }
    return $r
}
function Settings {
    $local=[Environment]::GetFolderPath('LocalApplicationData'); $roaming=[Environment]::GetFolderPath('ApplicationData')
    $profile=[Environment]::GetFolderPath('UserProfile'); $documents=[Environment]::GetFolderPath('MyDocuments')
    foreach($root in @($local,$roaming,$profile,$documents)) { if (-not [IO.Path]::IsPathFullyQualified($root)) { throw 'E02_SETTINGS_ROOT_UNAVAILABLE' } }
    return @(
        Observed-File 'editor-engine-base' (Join-Path $EngineRoot 'Engine\Config\BaseEditorSettings.ini')
        Observed-File 'editor-local-user' (Join-Path $local 'Unreal Engine\Engine\Config\UserEditorSettings.ini')
        Observed-File 'editor-local-versioned' (Join-Path $local 'UnrealEngine\5.8\Saved\Config\WindowsEditor\EditorSettings.ini')
        Observed-File 'editor-profile-documents-user' (Join-Path $profile 'Documents\Unreal Engine\Engine\Config\UserEditorSettings.ini')
        Observed-File 'editor-project-default' (Join-Path $script:Stage 'Config\DefaultEditorSettings.ini')
        Observed-File 'editor-known-documents-user' (Join-Path $documents 'Unreal Engine\Engine\Config\UserEditorSettings.ini')
        Observed-File 'ubt-roaming' (Join-Path $roaming 'Unreal Engine\UnrealBuildTool\BuildConfiguration.xml')
        Observed-File 'ubt-local' (Join-Path $local 'Unreal Engine\UnrealBuildTool\BuildConfiguration.xml')
        Observed-File 'ubt-known-documents' (Join-Path $documents 'Unreal Engine\UnrealBuildTool\BuildConfiguration.xml')
    )
}
function Check-Settings($Before,$After) {
    if (@($Before).Count -ne 9 -or @($After).Count -ne 9) { throw 'E02_SETTINGS_OBSERVATIONS_MISSING' }
    $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach($prior in $Before) {
        if (-not $seen.Add($prior.role)) { throw 'E02_DUPLICATE_SETTING_ROLE' }
        $current=@($After | Where-Object { $_.role -ceq $prior.role })
        if ($current.Count -ne 1) { throw 'E02_SETTINGS_ROLE_MISMATCH' }
        foreach($s in @($prior,$current[0])) {
            if ($s.inspection -cne 'PASS' -or $s.exists -isnot [bool] -or ($s.exists -and $s.sha256 -cnotmatch '^[0-9a-f]{64}$') -or (-not $s.exists -and $null -ne $s.sha256)) { throw 'E02_SETTINGS_UNAVAILABLE' }
        }
        if ($prior.path -cne $current[0].path -or $prior.exists -cne $current[0].exists -or $prior.sha256 -cne $current[0].sha256) { throw 'E02_SETTINGS_CHANGED' }
    }
}
function Copy-FrozenProject($Snapshot) {
    New-Directory $script:Stage
    foreach($item in $Snapshot) {
        $target=Under (Join-Path $script:Stage $item.path) $script:Stage
        if ($item.kind -eq 'directory') { [void][IO.Directory]::CreateDirectory($target) }
        else {
            [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target))
            [IO.File]::Copy((Need-File (Join-Path $script:Repo $item.path)),$target,$false)
        }
    }
    Same-Snapshot $Snapshot @(Snapshot-Authored $script:Stage)
    New-Directory (Owned 'fixture')
    [IO.File]::Copy((Need-File $script:Fixture),(Owned 'fixture/world-input-v1.json'),$false)
    if ((Digest $script:Fixture) -cne (Digest (Owned 'fixture/world-input-v1.json'))) { throw 'E02_FIXTURE_COPY_DRIFT' }
}
function Child-Environment([hashtable] $Extra=@{}) {
    $envs=[Collections.Generic.Dictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach($pair in @(
        @('TEMP','temp'),@('TMP','temp'),@('DOTNET_CLI_HOME','dotnet-home'),@('NUGET_PACKAGES','nuget'),@('UBA_ROOT','uba'))) {
        $path=Owned $pair[1]; if (-not [IO.Directory]::Exists($path)) { [void][IO.Directory]::CreateDirectory($path) }
        $envs.Add($pair[0],$path)
    }
    $envs.Add('DOTNET_CLI_TELEMETRY_OPTOUT','1'); $envs.Add('DOTNET_SKIP_FIRST_TIME_EXPERIENCE','1')
    $envs.Add('DOTNET_NOLOGO','1'); $envs.Add('UE-SharedDataCachePath','None')
    $envs.Add('UE_ADDITIONAL_PLUGIN_PATHS','')
    foreach($name in @('UE_USE_SYSTEM_DOTNET','UE_DOTNET_VERSION','UE_DOTNET_DIR','UE_DOTNET_ARCH','ProgramFiles(Arm)')){$envs.Add($name,'')}
    $envs.Add('PROCESSOR_ARCHITECTURE','AMD64');$envs.Add('PATHEXT','.EXE')
    $dotnetRoot=[IO.Path]::GetDirectoryName($script:Freeze.toolPaths.dotnet)
    $envs.Add('DOTNET_ROOT',$dotnetRoot);$envs.Add('DOTNET_ROOT_X64',$dotnetRoot)
    $envs.Add('DOTNET_MULTILEVEL_LOOKUP','0')
    foreach($entry in $Extra.GetEnumerator()) { $envs.Add($entry.Key,[string]$entry.Value) }
    return ,$envs
}
function Invoke-Root([string] $Label,[string] $Executable,[string[]] $Arguments,[int] $Budget,[bool] $Visible=$false,[string] $Fault='',[hashtable] $Extra=@{}) {
    if ($Budget -le 0 -or ($Label -eq 'build' -and $Budget -gt 1800) -or ($Label -ne 'build' -and $Budget -gt 600)) { throw 'E02_PROCESS_BUDGET' }
    $exe=Need-File $Executable
    $stdout=Owned "logs/$Label.stdout.log"; $stderr=Owned "logs/$Label.stderr.log"
    foreach($arg in $Arguments) { Safe-Text $arg; if ($arg.Contains([char]0)) { throw 'E02_ARGUMENT_NUL' } }
    $record=[Warhammer.E02.Supervisor]::Run($exe,$Arguments,$script:Stage,(Child-Environment $Extra),$stdout,$stderr,$Budget,$Visible,$(if($Fault){$Fault}else{$null}))
    $script:Result.processes.Add($record)
    # The raw receipt is preserved even when the phase later fails. No mutation of
    # validated root outcomes follows evidence inspection failure.
    Write-JsonNew (Join-Path $script:PhaseRoot "$Label.process.json") $record
    foreach($path in @($stdout,$stderr)) {
        if ([IO.File]::Exists($path)) { Safe-Text $script:Utf8.GetString([IO.File]::ReadAllBytes($path)) }
    }
    return ,$record
}
function Require-RootPass($Record) {
    if($Record['technicalBlocked']){throw 'BLOCKED_E02_PRIVATE_JOB_OR_PROCESS_SETUP_UNSUPPORTED'}
    if ($Record['status'] -cne 'PASS' -or $Record['exitConfirmed'] -isnot [bool] -or -not $Record['exitConfirmed'] -or
        $Record['cleanupConfirmed'] -isnot [bool] -or -not $Record['cleanupConfirmed'] -or $Record['timedOut']) { throw 'E02_OWNED_PROCESS_FAILED_OR_CLEANUP_UNVERIFIED' }
}
function Supervisor-Controls {
    $pwsh=Need-File ([Environment]::ProcessPath)
    $clock=[Diagnostics.Stopwatch]::StartNew()
    $results=[Collections.Generic.List[object]]::new()
    # Child fixture command text is constant; executable is passed through a
    # single-quoted PowerShell literal with escaped quotes, never interpolated
    # shell syntax or user-provided program text.
    $literal=$pwsh.Replace("'","''")
    $normal='$p=[Diagnostics.ProcessStartInfo]::new();$p.FileName='''+$literal+''';$p.UseShellExecute=$false;$p.CreateNoWindow=$true;foreach($a in @(''-NoProfile'',''-NonInteractive'',''-Command'',''Start-Sleep -Seconds 2; exit 0'')){$p.ArgumentList.Add($a)};$c=[Diagnostics.Process]::Start($p);$c.Dispose();exit 0'
    $r=Invoke-Root 'sup01-normal-lingering' $pwsh @('-NoProfile','-NonInteractive','-Command',$normal) 20
    Require-RootPass $r
    if ($r['rootExitWhileMembersActive'] -isnot [bool] -or -not $r['rootExitWhileMembersActive']) { throw 'E02_SUP01_LINGERING_CHILD_NOT_OBSERVED' }
    $results.Add(@{group='SUP01';subcase='normal-root-lingering-child';status='PASS';process=Descriptor (Join-Path $script:PhaseRoot 'sup01-normal-lingering.process.json')})
    $long=$normal.Replace('Start-Sleep -Seconds 2; exit 0','Start-Sleep -Seconds 60; exit 0').Replace('$c.Dispose();exit 0','$c.Dispose();Start-Sleep -Seconds 60;exit 0')
    $r=Invoke-Root 'sup02-timeout' $pwsh @('-NoProfile','-NonInteractive','-Command',$long) 8
    if (-not $r['timedOut'] -or -not $r['exitConfirmed'] -or -not $r['cleanupConfirmed'] -or $r['status'] -cne 'FAIL' -or $null -eq $r['primaryFailure']) { throw 'E02_SUP02_TIMEOUT_NOT_PRESERVED_OR_CLEANUP_UNVERIFIED' }
    $results.Add(@{group='SUP02';subcase='timeout-root-child';status='PASS';attemptStatus='FAIL';process=Descriptor (Join-Path $script:PhaseRoot 'sup02-timeout.process.json')})
    foreach($fault in @('assign','query','close')) {
        $r=Invoke-Root "sup03-$fault" $pwsh @('-NoProfile','-NonInteractive','-Command','exit 0') 15 $false $fault
        if ($r['status'] -cne 'FAIL' -or -not $r['cleanupConfirmed'] -or ($fault -eq 'assign' -and $r['resumed'])) { throw 'E02_SUP03_SYNTHETIC_FAILURE_NOT_FAIL_CLOSED' }
        if ($fault -eq 'close' -and @($r['secondaryErrors']).Count -ne 1) { throw 'E02_SUP03_CLOSE_DIAGNOSTIC_MISSING' }
        $results.Add(@{group='SUP03';subcase=$fault;status='PASS';synthetic=$true;attemptStatus='FAIL';process=Descriptor (Join-Path $script:PhaseRoot "sup03-$fault.process.json")})
    }
    $caught=$null;$pendingEvidence=@{primaryFailure=@{code='EXPECTED_PRIMARY'};secondaryErrors=@()}
    try { Write-JsonNew (Owned 'reports/supervisor-controls/injected-write-must-not-exist.json') $pendingEvidence -InjectFailure }
    catch { $caught=Failure $_ 'SUP03-evidence-write' }
    if ($null -eq $caught -or $pendingEvidence.primaryFailure.code -cne 'EXPECTED_PRIMARY' -or [IO.File]::Exists((Owned 'reports/supervisor-controls/injected-write-must-not-exist.json'))) { throw 'E02_SUP03_WRITER_DID_NOT_FAIL_CLOSED' }
    $results.Add(@{group='SUP03';subcase='evidence-writer';status='PASS';synthetic=$true;attemptStatus='FAIL';primaryFailure=$pendingEvidence.primaryFailure;secondaryFailure=$caught})
    if ($clock.Elapsed.TotalSeconds -gt 600 -or $results.Count -ne 6) { throw 'E02_SUPERVISOR_CONTROL_BOUND_OR_COUNT' }
    $controlEvidence=@{groups=@('SUP01','SUP02','SUP03');groupCount=3;subcaseCount=6;processRootCount=5;cases=@($results);elapsedSeconds=$clock.Elapsed.TotalSeconds;status='PASS';nativeCaseCount=0}
    Write-JsonNew (Owned 'reports/supervisor-controls/index.json') $controlEvidence
    return $controlEvidence
}
function Catalog-Descriptors([string] $Root) {
    $rootPath=Assert-Path $Root
    if(-not [IO.Directory]::Exists($rootPath)){throw 'BLOCKED_E02_PLUGIN_CATALOG_ROOT_UNAVAILABLE'}
    $pending=[Collections.Generic.Stack[string]]::new();$pending.Push($rootPath)
    $found=[Collections.Generic.List[object]]::new()
    while($pending.Count){
        $dir=$pending.Pop()
        # Enumerate raw filesystem entries, including hidden/ignored descriptors.
        # Do not follow a junction or silently omit an unavailable directory.
        foreach($path in [IO.Directory]::EnumerateFileSystemEntries($dir)){
            $attributes=[IO.File]::GetAttributes($path)
            if(($attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw 'BLOCKED_E02_PLUGIN_DISCOVERY_REPARSE_PATH'}
            if(($attributes -band [IO.FileAttributes]::Directory) -ne 0){$pending.Push($path)}
            elseif([IO.Path]::GetExtension($path) -ieq '.uplugin'){
                $d=Descriptor $path
                $found.Add([ordered]@{relativePath=[IO.Path]::GetRelativePath($rootPath,$path).Replace('\','/');bytes=$d.bytes;sha256=$d.sha256})
            }
        }
    }
    return @($found|Sort-Object { $_.relativePath } -CaseSensitive)
}
function Check-PluginDiscoveryCatalog($Closure) {
    $expectedRoots=@((Join-Path $EngineRoot 'Engine\Plugins'),(Join-Path $EngineRoot 'Engine\Platforms'))
    $roots=@($Closure.catalogRoots)
    if($roots.Count -ne 2){throw 'E02_PLUGIN_CATALOG_ROOT_SET'}
    $summaries=[Collections.Generic.List[object]]::new()
    foreach($path in $expectedRoots){
        $entry=@($roots|Where-Object {$_.path -ieq $path})
        if($entry.Count -ne 1){throw 'E02_PLUGIN_CATALOG_ROOT_MISSING_OR_DUPLICATED'}
        $actual=@(Catalog-Descriptors $path);$frozen=@($entry[0].descriptors|Sort-Object { $_.relativePath } -CaseSensitive)
        if($actual.Count -ne $frozen.Count){throw 'E02_PLUGIN_CATALOG_MEMBERSHIP_CHANGED'}
        for($i=0;$i -lt $actual.Count;$i++){
            if($frozen[$i].relativePath -isnot [string] -or $frozen[$i].sha256 -isnot [string] -or $frozen[$i].sha256 -cnotmatch '^[a-fA-F0-9]{64}$' -or
                ($frozen[$i].bytes -isnot [long] -and $frozen[$i].bytes -isnot [int]) -or $frozen[$i].bytes -lt 0){throw 'E02_PLUGIN_CATALOG_DESCRIPTOR_SHAPE'}
            if($actual[$i].relativePath -cne $frozen[$i].relativePath -or $actual[$i].bytes -ne $frozen[$i].bytes -or
                $actual[$i].sha256 -ine $frozen[$i].sha256){throw 'E02_PLUGIN_CATALOG_MEMBERSHIP_OR_BYTES_CHANGED'}
        }
        $summaries.Add(@{path=$path;descriptorCount=$actual.Count;observedUtc=[DateTime]::UtcNow.ToString('o');membershipAndBytes='MATCH_FROZEN_CATALOG'})
    }
    $absent=@((Join-Path $EngineRoot 'Engine\Restricted'),(Join-Path $EngineRoot 'Enterprise\Plugins'))
    foreach($base in @($script:Repo,$script:Stage)){foreach($leaf in @('Plugins','Mods','Platforms','Restricted')){$absent+=Join-Path $base $leaf}}
    $required=@($Closure.requiredAbsentPaths)
    if($required.Count -ne $absent.Count){throw 'E02_PLUGIN_EXTRA_ROOT_ABSENCE_SET'}
    $observations=[Collections.Generic.List[object]]::new()
    foreach($path in $absent){
        if(@($required|Where-Object {$_ -is [string] -and $_ -ieq $path}).Count -ne 1){throw 'E02_PLUGIN_EXTRA_ROOT_ABSENCE_MISSING_OR_DUPLICATED'}
        $knownAbsent=$false
        try{[void][IO.File]::GetAttributes($path)}
        catch [IO.FileNotFoundException]{$knownAbsent=$true}
        catch [IO.DirectoryNotFoundException]{$knownAbsent=$true}
        if(-not $knownAbsent){throw 'BLOCKED_E02_EXTRA_PLUGIN_DISCOVERY_PATH_PRESENT'}
        $observations.Add(@{path=$path;exists=$false;inspection='PASS';observedUtc=[DateTime]::UtcNow.ToString('o')})
    }
    if(@($Closure.emptyEnvironmentVariables).Count -ne 1 -or $Closure.emptyEnvironmentVariables[0] -cne 'UE_ADDITIONAL_PLUGIN_PATHS'){throw 'E02_PLUGIN_DISCOVERY_ENVIRONMENT_CONTRACT'}
    return @{catalogRoots=@($summaries);requiredAbsences=@($observations);subprocessEnvironmentOverrides=@{UE_ADDITIONAL_PLUGIN_PATHS=''};
        parentAdditionalPluginPathsNonempty=(-not [string]::IsNullOrEmpty([Environment]::GetEnvironmentVariable('UE_ADDITIONAL_PLUGIN_PATHS')));
        limits='Raw frozen descriptor superset and explicit discovery-root observations; not a universal plugin/dependency analyzer or whole-process network-isolation proof.'}
}
function Resolve-ReceiptPath([string] $Value,[string] $Directory,[switch] $EngineToken) {
    if([string]::IsNullOrWhiteSpace($Value)){throw 'E02_TARGET_RECEIPT_PATH_MISSING'}
    if($Value.Contains('$(')){
        if(-not $EngineToken -or -not $Value.StartsWith('$(EngineDir)/',[StringComparison]::Ordinal) -or $Value.Substring(13).Contains('$(')){throw 'E02_TARGET_RECEIPT_UNSUPPORTED_PATH_TOKEN'}
        $Value=Join-Path (Join-Path $EngineRoot 'Engine') $Value.Substring(13)
    }
    if(-not [IO.Path]::IsPathFullyQualified($Value)){$Value=Join-Path $Directory $Value}
    return Assert-Path ([IO.Path]::GetFullPath($Value))
}
function Check-TargetReceipt($Closure) {
    $policy=$Closure.targetReceiptPolicy
    if($policy.relativePath -cne 'Binaries/Win64/WarhammerClientEditor.target' -or $policy.allowEnginePluginsEnabledByDefault -isnot [bool]){throw 'E02_TARGET_RECEIPT_POLICY_SHAPE'}
    $receiptPath=Under (Join-Path $script:Stage $policy.relativePath) $script:Stage
    $receiptDirectory=[IO.Path]::GetDirectoryName($receiptPath)
    $receipts=@(Get-ChildItem -LiteralPath $receiptDirectory -Force -Filter '*.target' -File)
    if($receipts.Count -ne 1 -or $receipts[0].FullName -ine $receiptPath){throw 'BLOCKED_E02_AMBIGUOUS_OR_MISSING_STAGED_TARGET_RECEIPT'}
    $receipt=Read-Json $receiptPath
    if($receipt.TargetName -cne 'WarhammerClientEditor' -or $receipt.TargetType -cne 'Editor' -or $receipt.Platform -cne 'Win64' -or
        $receipt.Configuration -cne 'Development'){throw 'E02_TARGET_RECEIPT_IDENTITY'}
    if((Resolve-ReceiptPath $receipt.Project $receiptDirectory) -ine (Join-Path $script:Stage 'WarhammerClient.uproject') -or
        (Resolve-ReceiptPath $receipt.Launch $receiptDirectory -EngineToken) -ine $script:Freeze.toolPaths.editor -or
        (Resolve-ReceiptPath $receipt.LaunchCmd $receiptDirectory -EngineToken) -ine $script:Freeze.toolPaths.editorCmd){throw 'E02_TARGET_RECEIPT_PROJECT_OR_LAUNCH_MISMATCH'}
    $plugins=@();if($receipt.Contains('Plugins')){$plugins=@($receipt.Plugins)}
    $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach($item in $plugins){
        if($item -isnot [Collections.IDictionary] -or $item.Name -isnot [string] -or [string]::IsNullOrWhiteSpace($item.Name) -or
            $item.Enabled -isnot [bool] -or -not $seen.Add($item.Name)){throw 'E02_TARGET_RECEIPT_PLUGIN_OVERRIDE_SHAPE'}
        if($item.Enabled -and $item.Name -iin $script:Disabled){throw 'BLOCKED_E02_TARGET_RECEIPT_FORBIDDEN_PLUGIN_ENABLE'}
    }
    $expected=@($policy.pluginOverrides|Sort-Object { $_.Name } -CaseSensitive);$actual=@($plugins|Sort-Object { $_.Name } -CaseSensitive)
    if($expected.Count -ne $actual.Count){throw 'E02_TARGET_RECEIPT_PLUGIN_OVERRIDES_CHANGED'}
    for($i=0;$i -lt $actual.Count;$i++){
        if($expected[$i].Enabled -isnot [bool] -or $expected[$i].Name -cne $actual[$i].Name -or $expected[$i].Enabled -cne $actual[$i].Enabled){throw 'E02_TARGET_RECEIPT_PLUGIN_OVERRIDES_CHANGED'}
        if($actual[$i].Enabled -and $actual[$i].Name -cnotin @($Closure.enabledPlugins)){throw 'E02_TARGET_RECEIPT_ENABLE_OUTSIDE_REVIEWED_CLOSURE'}
    }
    $defaults=$true;$properties=@()
    if($receipt.Contains('AdditionalProperties')){$properties=@($receipt.AdditionalProperties|Where-Object {$_.Name -ceq 'bAllowEnginePluginsEnabledByDefault'})}
    if($properties.Count -gt 1){throw 'E02_TARGET_RECEIPT_DUPLICATE_DEFAULT_PROPERTY'}
    if($properties.Count){
        if($properties[0].Value -isnot [string] -or $properties[0].Value -notin @('true','false')){throw 'E02_TARGET_RECEIPT_DEFAULT_PROPERTY_SHAPE'}
        $defaults=$properties[0].Value -ieq 'true'
    }
    if($defaults -cne $policy.allowEnginePluginsEnabledByDefault){throw 'E02_TARGET_RECEIPT_DEFAULT_POLICY_CHANGED'}
    $buildPlugins=@();if($receipt.Contains('BuildPlugins')){$buildPlugins=@($receipt.BuildPlugins)}
    foreach($name in $buildPlugins){if($name -isnot [string] -or [string]::IsNullOrWhiteSpace($name)){throw 'E02_TARGET_RECEIPT_BUILD_ALLOWLIST_SHAPE'}}
    return @{artifact=Descriptor $receiptPath;targetName=$receipt.TargetName;platform=$receipt.Platform;configuration=$receipt.Configuration;pluginOverrides=$plugins;
        allowEnginePluginsEnabledByDefault=$defaults;buildPlugins=$buildPlugins;buildPluginsMeaning='OPTIONAL_ALLOWLIST_NOT_RUNTIME_ENABLE_ROOTS';
        limits='Actual staged receipt checked against reviewed policy. Source selection/receipt support and actual startup diagnostics remain separate evidence.'}
}
function Check-StagedPluginClosure([switch] $RequireTargetReceipt) {
    $project=Read-Json (Join-Path $script:Stage 'WarhammerClient.uproject')
    $allowedFields=@('FileVersion','EngineAssociation','Category','Description','Modules','Plugins')
    foreach($key in $project.Keys){if($key -cnotin $allowedFields){throw 'BLOCKED_E02_UNREVIEWED_PROJECT_PLUGIN_DISCOVERY_FIELD'}}
    foreach($plugin in $project.Plugins) {
        if ($plugin.Name -cin $script:Disabled -and $plugin.Enabled -eq $true) { throw 'E02_FORBIDDEN_PLUGIN_EXPLICITLY_ENABLED' }
    }
    $procedural=@($project.Plugins | Where-Object { $_.Name -ceq 'ProceduralMeshComponent' -and $_.Enabled -eq $true })
    if ($procedural.Count -ne 1) { throw 'E02_PROCEDURAL_MESH_PLUGIN_REFERENCE_MISSING' }
    $closureDescriptor=Check-Descriptor $script:Freeze.pluginClosure
    $closure=Read-Json $closureDescriptor.path
    if($closure.schemaVersion -ne 1 -or $closure.sourceHead -cne $script:Freeze.sourceHead -or $closure.platform -cne 'Win64' -or
        @($closure.targets).Count -ne 1 -or $closure.targets[0] -cne 'WarhammerClientEditor'){throw 'E02_REVIEWED_PLUGIN_CLOSURE_SCOPE'}
    if($closure.targetReceiptPolicy.relativePath -cne 'Binaries/Win64/WarhammerClientEditor.target' -or
        $closure.targetReceiptPolicy.allowEnginePluginsEnabledByDefault -isnot [bool] -or $closure.targetReceiptPolicy.pluginOverrides -isnot [Collections.IList]){throw 'E02_TARGET_RECEIPT_POLICY_SHAPE'}
    $canonicalProject=Check-Descriptor $closure.project
    if($canonicalProject.path -ine (Join-Path $script:Repo 'WarhammerClient.uproject') -or $canonicalProject.sha256 -cne (Digest (Join-Path $script:Stage 'WarhammerClient.uproject'))){throw 'E02_PLUGIN_CLOSURE_PROJECT_MISMATCH'}
    if((@($closure.disabledPlugins|Sort-Object -CaseSensitive)-join ',') -cne (@($script:Disabled|Sort-Object -CaseSensitive)-join ',')){throw 'E02_PLUGIN_CLOSURE_DISABLED_SET'}
    $enabled=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach($name in $closure.enabledPlugins){
        if($name -isnot [string] -or [string]::IsNullOrWhiteSpace($name) -or -not $enabled.Add($name) -or $name -iin $script:Disabled){throw 'E02_PLUGIN_CLOSURE_FORBIDDEN_OR_DUPLICATE_NAME'}
    }
    if(-not $enabled.Contains('ProceduralMeshComponent')){throw 'E02_PLUGIN_CLOSURE_PROCEDURAL_MESH_MISSING'}
    $described=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $seenPaths=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach($d in $closure.descriptors){
        $actual=Check-Descriptor $d
        if([IO.Path]::GetExtension($actual.path) -cne '.uplugin' -or -not $seenPaths.Add($actual.path)){throw 'E02_PLUGIN_CLOSURE_DESCRIPTOR_KIND_OR_DUPLICATE'}
        if(@($script:Freeze.files|Where-Object {$_.path -ieq $actual.path -and $_.sha256 -ieq $actual.sha256 -and $_.bytes -eq $actual.bytes}).Count -ne 1){throw 'E02_PLUGIN_CLOSURE_DESCRIPTOR_NOT_FROZEN'}
        [void]$described.Add([IO.Path]::GetFileNameWithoutExtension($actual.path))
    }
    foreach($name in $enabled){if(-not $described.Contains($name)){throw 'E02_ENABLED_PLUGIN_WITHOUT_FROZEN_DESCRIPTOR'}}
    $catalog=Check-PluginDiscoveryCatalog $closure
    $targetReceipt=$null;if($RequireTargetReceipt){$targetReceipt=Check-TargetReceipt $closure}
    $script:Result.pluginClosure=@{artifact=$closureDescriptor;project=$canonicalProject;enabledNames=@($enabled|Sort-Object -CaseSensitive);descriptorCount=$seenPaths.Count;
        discoveryCatalog=$catalog;targetReceipt=$targetReceipt;
        status='REVIEWED_CLOSURE_BINDING_CHECKED';limits='Completeness is an explicit independent source-review prerequisite. This is not a universal dependency analyzer or runtime network-isolation proof.'}
}
function Native-Arguments([string] $Kind) {
    $graphical=$Kind -in @('Discovery','WorldInput')
    $phaseName=$Kind.ToLowerInvariant()
    $reportName=if($Kind -eq 'WorldInput'){'world-input'}else{$phaseName}
    $common=@((Join-Path $script:Stage 'WarhammerClient.uproject'))
    if ($graphical) { $common+=@('/Engine/Maps/Entry?game=/Script/WarhammerClient.E02WorldProofGameMode','-game','-E02Proof','-d3d12','-windowed','-ResX=1280','-ResY=720') }
    else { $common+='-NullRHI' }
    $commands=switch($Kind) {
        'Discovery' {'Automation List;Quit'}
        'Numeric' {'Automation RunTest StartsWith:Warhammer.Migration.E02.Numeric;Quit'}
        'WorldInput' {'Automation RunTest StartsWith:Warhammer.Migration.E02.Rendered+StartsWith:Warhammer.Migration.E02.Input;Quit'}
    }
    $ddc=(Owned 'ddc').Replace('\','/')
    return @($common)+@('-unattended','-nosound','-nowrite',"-ExecCmds=$commands",'-TestExit=Automation Test Queue Empty',
        "-ReportExportPath=$((Owned "reports/$reportName").Replace('\','/'))",
        "-abslog=$((Owned "logs/native-$reportName.log").Replace('\','/'))",
        "-UserDir=$((Owned 'ue-user').Replace('\','/'))",'-DDC-NoDefaultGraph',"-DDC=(E02=(Type=FileSystem,Path=$ddc,DeleteUnused=false))",
        "-E02Fixture=$((Owned 'fixture/world-input-v1.json').Replace('\','/'))", "-E02Artifacts=$((Owned "artifacts/$reportName").Replace('\','/'))",
        ('-DisablePlugins='+($script:Disabled -join ',')))
}
function Inspect-NativeLog([string] $Kind) {
    $name=if($Kind -eq 'WorldInput'){'world-input'}else{$Kind.ToLowerInvariant()}
    $path=Owned "logs/native-$name.log"; $text=$script:Utf8.GetString([IO.File]::ReadAllBytes((Need-File $path))); Safe-Text $text
    # Anchor engine diagnostic categories, never generic ERROR/FAILED words or
    # negative-test names. Structured Automation reports establish test success.
    if ($text -match '(?im)^.*(?:LogWindows:\s+Error:\s+(?:Fatal error|Unhandled Exception)|LogOutputDevice:\s+Error:\s+=== Critical error|LogCore:\s+Error:\s+Fatal error|Fatal error:|Assertion failed:)') { throw 'E02_NATIVE_FATAL_DIAGNOSTIC' }
    $transport=@($text -split "`n" | Where-Object { $_ -match '(?i)(LogPluginManager:.*Mounting.*(?:UdpMessaging|TcpMessaging|QuicMessaging|WebSocketMessaging|DiscoveryBeaconReceiver|NetworkServiceDiscovery)|Log(?:Udp|Tcp|Quic|WebSocket)Messaging:.*(?:Initializing|Started|Listening|Connecting|bridge|tunnel))' })
    if ($transport.Count) { throw 'E02_FORBIDDEN_TRANSPORT_STARTUP' }
    $ddc=@($text -split "`n" | Where-Object { $_ -match '\bLogDerivedDataCache:' })
    $ownedDdc=(Owned 'ddc').Replace('\','/')
    $selected=@($ddc | Where-Object { $_.Replace('\','/').Contains($ownedDdc,[StringComparison]::OrdinalIgnoreCase) -and $_ -match '(?i)E02|Writable|Using' })
    if (-not $selected.Count -or @($ddc | Where-Object { $_ -match '(?i)(falling back|fallback.*(?:enabled|using)|(?:Zen|Cloud|Shared).*\b(?:using|connected|enabled|running)\b)' }).Count) { throw 'E02_DDC_SELECTION_UNVERIFIED_OR_FALLBACK' }
    foreach($line in $ddc) {
        if ($line -match '(?i)\bWritable\b' -and -not $line.Replace('\','/').Contains($ownedDdc,[StringComparison]::OrdinalIgnoreCase)) { throw 'E02_NONOWNED_DDC_WRITER' }
    }
    $identity=@($text -split "`n" | Where-Object {$_ -match '\bLog(?:RHI|D3D12RHI|Windows|Init):' -and $_ -match '(?i)adapter|vendor|device|driver|feature level|OS:|display|resolution|monitor'})
    if($text -match '(?im)\b(?:Win32_Process\.Create|external process broker|using (?:XGE|FASTBuild|Incredibuild|remote executor))\b'){throw 'BLOCKED_E02_BROKERED_OR_REMOTE_TOOL_ROUTE'}
    return @{log=(Descriptor $path);ddcLines=$ddc;selectedOwnedDdc=$selected;actualIdentityLogLines=$identity;forbiddenTransportDiagnostics=@();limits='Specific startup/log observations only; not a whole-process network/filesystem isolation proof.'}
}
function Check-Discovery {
    $text=$script:Utf8.GetString([IO.File]::ReadAllBytes((Owned 'logs/native-discovery.log')))
    $listed=@([regex]::Matches($text,"(?m)^.*\bLogAutomationCommandLine: Display:\s*'([^'\r\n]+)'\s*$") | ForEach-Object {$_.Groups[1].Value})
    $counts=@([regex]::Matches($text,'\bLogAutomationCommandLine: Display: Found ([0-9]+) Automation Tests') | ForEach-Object {[int]$_.Groups[1].Value})
    if ($counts.Count -ne 1 -or $listed.Count -ne $counts[0]) { throw 'E02_DISCOVERY_COMPLETE_LIST_MISSING' }
    $selected=@($listed | Where-Object {$_.StartsWith('Warhammer.Migration.E02.',[StringComparison]::Ordinal)} | Sort-Object -CaseSensitive)
    $expected=@($script:Names|Sort-Object -CaseSensitive)
    if ($selected.Count -ne 16 -or ($selected -join "`n") -cne ($expected -join "`n")) { throw 'E02_DISCOVERY_EXACT_SET_MISMATCH' }
    $record=@{engineEligibleCount=$listed.Count;selectedCount=16;selectedNames=$selected;mainLog=Descriptor (Owned 'logs/native-discovery.log');sourceHead=$script:Freeze.sourceHead;status='PASS'}
    Write-JsonNew (Owned 'reports/discovery/selected-names.json') $record
    return $record
}
function Check-Automation([string] $Kind) {
    $name=if($Kind -eq 'WorldInput'){'world-input'}else{'numeric'}
    $reportPath=Owned "reports/$name/index.json"; $report=Read-Json $reportPath
    $expected=@($script:Names | Where-Object { if($Kind -eq 'Numeric'){$_ -clike '*.Numeric.*'}else{$_ -cnotlike '*.Numeric.*'} } | Sort-Object -CaseSensitive)
    $tests=@($report.tests); $actual=@($tests|ForEach-Object{$_.fullTestPath}|Sort-Object -CaseSensitive)
    if ($tests.Count -ne $expected.Count -or ($actual -join "`n") -cne ($expected -join "`n")) { throw 'E02_AUTOMATION_EXACT_SET_MISMATCH' }
    $assertions=[Collections.Generic.List[object]]::new();$assertionTotal=0L
    foreach($case in $tests) {
        if($case.state -cne 'Success'){throw 'E02_AUTOMATION_CASE_NOT_SUCCESS'}
        $suffix=$case.fullTestPath.Substring('Warhammer.Migration.E02.'.Length)
        $pattern='^'+[regex]::Escape($suffix)+': actual assertions=([1-9][0-9]*)'
        if($Kind -eq 'Numeric'){$pattern+='$'}
        else{$pattern+='; elapsed=([0-9]+\.[0-9]{3})s; status=PASS$'}
        $summaries=@($case.entries|Where-Object{$_.event.type -ceq 'Info' -and $_.event.message -cmatch $pattern})
        if($summaries.Count -ne 1){throw 'E02_ACTUAL_ASSERTION_SUMMARY_MISSING_OR_DUPLICATED'}
        $match=[regex]::Match($summaries[0].event.message,$pattern)
        $count=[long]::Parse($match.Groups[1].Value,[Globalization.CultureInfo]::InvariantCulture)
        $assertionTotal+=$count;$assertions.Add(@{case=$case.fullTestPath;actualAssertions=$count;exportedEvent=$summaries[0]})
    }
    foreach($field in @('failed','notRun','inProcess')) { if ($report[$field] -ne 0) { throw 'E02_AUTOMATION_INCOMPLETE_OR_FAILED' } }
    $withWarnings=if($report.Contains('succeededWithWarnings')){[int]$report.succeededWithWarnings}else{0}
    if ([int]$report.succeeded+$withWarnings -ne $tests.Count) { throw 'E02_AUTOMATION_SUCCESS_COUNT' }
    $htmlPath=Owned "reports/$name/index.html";Safe-Text $script:Utf8.GetString([IO.File]::ReadAllBytes((Need-File $htmlPath)))
    return @{report=Descriptor $reportPath;htmlReport=Descriptor $htmlPath;executed=$tests.Count;names=$actual;state='Success';succeeded=$report.succeeded;succeededWithWarnings=$withWarnings;assertionCounts=@($assertions);actualAssertionTotal=$assertionTotal;tests=$tests}
}

function Check-ZeroCounters($Snapshot) {
    foreach($field in @('coreTransportCreations','gameCommands','acceptedResults')) {
        $value=$Snapshot[$field]
        if (-not $Snapshot.Contains($field) -or ($value -isnot [long] -and $value -isnot [int] -and $value -isnot [double] -and $value -isnot [decimal]) -or
            -not [double]::IsFinite([double]$value) -or [double]$value -ne 0) { throw 'E02_NONZERO_OR_MISSING_GAME_COUNTER' }
    }
}
function Check-Scene($Scene,[switch] $Baseline) {
    Check-ZeroCounters $Scene
    if ($Scene.schemaVersion -ne 1 -or $Scene.label -cne 'SYNTHETIC / ADVISORY — NO GAME SESSION' -or
        $Scene.ready -isnot [bool] -or -not $Scene.ready -or $Scene.error -cne '' -or $Scene.rhi -cne 'D3D12' -or
        $Scene.hardwareRhi -isnot [bool] -or -not $Scene.hardwareRhi -or $Scene.perspective -isnot [bool] -or -not $Scene.perspective -or
        [string]::IsNullOrWhiteSpace($Scene.adapter) -or $Scene.adapter -match '(?i)WARP|Basic Render|SwiftShader|software|null' -or $Scene.vendorId -eq 0x1414 -or $Scene.vendorId -le 0 -or $Scene.deviceId -le 0 -or
        $Scene.nullRhi -isnot [bool] -or $Scene.nullRhi -or [string]::IsNullOrWhiteSpace($Scene.featureLevel) -or
        [string]::IsNullOrWhiteSpace($Scene.internalDriverVersion) -or $Scene.internalDriverVersion -eq 'Unknown' -or
        [string]::IsNullOrWhiteSpace($Scene.userDriverVersion) -or $Scene.userDriverVersion -eq 'Unknown' -or
        [string]::IsNullOrWhiteSpace($Scene.osVersion) -or $Scene.display.windowVisible -isnot [bool] -or -not $Scene.display.windowVisible -or
        @($Scene.display.actualClientRectScreen).Count -ne 4 -or $Scene.display.initialMonitorCount -le 0 -or $Scene.display.windowDpiScale -le 0) { throw 'E02_ACTUAL_HARDWARE_PERSPECTIVE_UNVERIFIED' }
    if ([IO.Path]::GetFullPath($Scene.fixturePath) -ine [IO.Path]::GetFullPath((Owned 'fixture/world-input-v1.json'))) { throw 'E02_NATIVE_FIXTURE_PATH_MISMATCH' }
    if ($Baseline -and ($Scene.viewport.width -ne 1280 -or $Scene.viewport.height -ne 720 -or [double]$Scene.uiScale -ne 1.0)) { throw 'E02_BASELINE_VIEWPORT_OR_SCALE' }
    if ($Scene.viewport.width -le 0 -or $Scene.viewport.height -le 0 -or $Scene.camera.perspective -isnot [bool] -or -not $Scene.camera.perspective -or @($Scene.camera.viewProjectionMatrix).Count -ne 4) { throw 'E02_CAMERA_PROJECTION_EVIDENCE_MISSING' }
    foreach($row in $Scene.camera.viewProjectionMatrix) { if (@($row).Count -ne 4) { throw 'E02_CAMERA_MATRIX_SHAPE' } }
    $ids=@($Scene.models|ForEach-Object {$_.id}|Sort-Object -CaseSensitive)
    if (($ids -join ',') -cne 'e02-capsule,e02-circle,e02-ellipse,e02-polygon,e02-rectangle' -or @($Scene.supports).Count -ne 2) { throw 'E02_SCENE_FIXTURE_IDENTITY' }
}
function Parse-JsonLine([string] $Line) {
    if ($Line.Length -gt 8MB -or [string]::IsNullOrWhiteSpace($Line)) { throw 'E02_JSONL_EMPTY_OR_OVERSIZED_LINE' }
    Safe-Text $Line; $options=[Text.Json.JsonDocumentOptions]::new();$options.MaxDepth=80
    $doc=[Text.Json.JsonDocument]::Parse($Line,$options)
    try { Check-JsonElement $doc.RootElement 0 } finally {$doc.Dispose()}
    return ConvertFrom-Json -InputObject $Line -AsHashtable -Depth 80 -DateKind String
}
function Check-Utc([string] $Value,$Process) {
    if($Value -cnotmatch '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,7})?(?:Z|\+00:00)$'){throw 'E02_NATIVE_TIMESTAMP_NOT_EXPLICIT_UTC'}
    $utc=[DateTimeOffset]::Parse($Value,[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::None)
    if ($utc.Offset -ne [TimeSpan]::Zero -or $utc.UtcDateTime -lt [DateTime]::FromFileTimeUtc([long]$Process['creationFileTime']) -or
        $utc.UtcDateTime -gt [DateTime]::FromFileTimeUtc([long]$Process['exitFileTime'])) { throw 'E02_NATIVE_TIMESTAMP_OUTSIDE_ACTUAL_ROOT' }
}
function World-Artifacts($Process) {
    $scenePath=Owned 'artifacts/world-input/scene.json';$scene=Read-Json $scenePath;Check-Scene $scene
    $caseDescriptors=[Collections.Generic.List[object]]::new()
    foreach($fullName in $script:Names|Where-Object {$_ -cnotlike '*.Numeric.*'}) {
        $suffix=$fullName.Substring('Warhammer.Migration.E02.'.Length)
        $path=Owned "artifacts/world-input/case-$suffix.json";$case=Read-Json $path
        if ($case.case -cne $suffix) {throw 'E02_CASE_ARTIFACT_IDENTITY'};Check-Scene $case
        Check-Utc $case.observedUtc $Process;$caseDescriptors.Add((Descriptor $path))
    }
    $inputPath=Owned 'artifacts/world-input/input.jsonl';$lines=[IO.File]::ReadAllLines((Need-File $inputPath),$script:Utf8)
    if ($lines.Length -eq 0 -or $lines.Length -gt 100000) {throw 'E02_INPUT_TRACE_COUNT'}
    $cases=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal);$last=0L;$startup=0
    foreach($line in $lines) {
        $event=Parse-JsonLine $line
        if ($event.sequence -ne $last+1 -or $event.route -cne 'PlatformMessageHandler -> Slate -> SE02ProofSurface -> FInputPolicy' -or
            @($event.screenPhysical).Count -ne 2 -or @($event.viewportPhysical).Count -ne 2 -or @($event.logical).Count -ne 2 -or
            $event.hitWidget -cne 'SE02ProofSurface' -or $event.consumed -isnot [bool]) {throw 'E02_INPUT_TRACE_SCHEMA_OR_SEQUENCE'}
        $last=[long]$event.sequence;Check-Utc $event.observedUtc $Process
        Check-ZeroCounters $event.before;Check-ZeroCounters $event.after
        if ($event.case -ceq '') {$startup++} else {
            if ($event.case -cnotin @($script:Names|ForEach-Object {$_.Substring('Warhammer.Migration.E02.'.Length)})) {throw 'E02_TRACE_UNKNOWN_CASE'}
            [void]$cases.Add($event.case)
        }
    }
    foreach($required in $script:Names|Where-Object {$_ -clike '*.Input.*'}) {
        if (-not $cases.Contains($required.Substring('Warhammer.Migration.E02.'.Length))) {throw 'E02_INPUT_CASE_ROUTE_TRACE_MISSING'}
    }
    $rayPath=Owned 'artifacts/world-input/rays.jsonl';$rays=[IO.File]::ReadAllLines((Need-File $rayPath),$script:Utf8)
    if ($rays.Length -eq 0 -or $rays.Length -gt 100000) {throw 'E02_RAY_TRACE_COUNT'}
    foreach($line in $rays) {
        $ray=Parse-JsonLine $line;Check-Utc $ray.observedUtc $Process
        if ($ray.deprojected -isnot [bool] -or $ray.hit -isnot [bool] -or @($ray.screenPhysical).Count -ne 2 -or @($ray.viewportPhysical).Count -ne 2) {throw 'E02_RAY_SCHEMA'}
        if ($ray.deprojected -and (@($ray.originWorldCm).Count -ne 3 -or @($ray.directionWorld).Count -ne 3)) {throw 'E02_DEPROJECTED_RAY_MISSING'}
        if ($ray.hit -and (@($ray.domainHitInches).Count -ne 3 -or [string]::IsNullOrWhiteSpace($ray.id) -or $ray.distanceWorldCm -lt 0)) {throw 'E02_RAY_HIT_MISSING'}
    }
    $imagesPath=Owned 'artifacts/world-input/screenshots.json';$manifest=Read-Json $imagesPath
    if ($manifest.schemaVersion -ne 1) {throw 'E02_SCREENSHOT_MANIFEST_VERSION'}
    $expected=[ordered]@{'five-forms.png'='Rendered.FiveForms';'raised-pick.png'='Rendered.RaisedPicking';'mesh-before.png'='Rendered.MeshSubstitution';'mesh-after.png'='Rendered.MeshSubstitution';'oblique.png'='Rendered.ObliqueNormals';'near-top.png'='Rendered.ObliqueNormals'}
    $records=@($manifest.screenshots);$names=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach($record in $records) {if($record.filename -isnot [string] -or $record.filename -cnotmatch '^[A-Za-z0-9_.-]+\.png$' -or -not $names.Add($record.filename)){throw 'E02_SCREENSHOT_PATH_OR_DUPLICATE'}}
    $images=[Collections.Generic.List[object]]::new()
    foreach($entry in $expected.GetEnumerator()) {
        $record=@($records|Where-Object {$_.filename -ceq $entry.Key})
        if ($record.Count -ne 1 -or $record[0].case -cne $entry.Value) {throw 'E02_REQUIRED_SCREENSHOT_MISSING'}
        Check-Scene $record[0].snapshot -Baseline;Check-Utc $record[0].processedUtc $Process
        $path=Owned ('artifacts/world-input/'+$entry.Key);$decoded=[Warhammer.E02.Supervisor]::DecodePng((Need-File $path))
        if ($decoded['width'] -ne 1280 -or $decoded['height'] -ne 720 -or $record[0].width -ne $decoded['width'] -or $record[0].height -ne $decoded['height']) {throw 'E02_SCREENSHOT_DIMENSIONS'}
        $images.Add(@{case=$entry.Value;artifact=(Descriptor $path);actualDecode=$decoded;nativeCompletion=$record[0]})
    }
    return @{scene=Descriptor $scenePath;caseSnapshots=@($caseDescriptors);inputTrace=Descriptor $inputPath;inputEvents=$lines.Length;startupEvents=$startup;inputCaseNames=@($cases|Sort-Object -CaseSensitive);rayTrace=Descriptor $rayPath;rayCount=$rays.Length;screenshotManifest=Descriptor $imagesPath;requiredImages=@($images);additionalImageRecords=@($records|Where-Object {-not $expected.Contains($_.filename)});visualInspection='PENDING_SEPARATE_ACTUAL_IMAGE_INSPECTION';fixture=Descriptor (Owned 'fixture/world-input-v1.json')}
}
function Output-Inventory {
    return @(foreach($item in Get-ChildItem -LiteralPath $script:RunRoot -Force -Recurse|Sort-Object FullName) {
        [void](Assert-Path $item.FullName)
        @{path=[IO.Path]::GetRelativePath($script:RunRoot,$item.FullName).Replace('\','/');kind=$(if($item.PSIsContainer){'directory'}else{'file'});bytes=$(if($item.PSIsContainer){$null}else{$item.Length})}
    })
}
function Check-BoundDescriptors($Node,[int] $Depth=0) {
    if($Depth -gt 80){throw 'E02_BOUND_DESCRIPTOR_DEPTH'}
    if($Node -is [Collections.IDictionary]) {
        if($Node.Contains('path') -and $Node.Contains('bytes') -and $Node.Contains('sha256') -and
            $Node.path -is [string] -and [IO.Path]::IsPathFullyQualified($Node.path)) {[void](Check-Descriptor $Node)}
        foreach($entry in $Node.GetEnumerator()){Check-BoundDescriptors $entry.Value ($Depth+1)}
    } elseif($Node -is [Collections.IList]) {foreach($entry in $Node){Check-BoundDescriptors $entry ($Depth+1)}}
}
function Check-Previous {
    $index=[Array]::IndexOf($script:Order,$Phase);$links=[Collections.Generic.List[object]]::new()
    for($i=0;$i -lt $index;$i++) {
        $prior=$script:Order[$i];$path=Owned ($prior.ToLowerInvariant()+'/result.json');$r=Read-Json $path
        if ($r.runId -cne $RunId -or $r.phase -cne $prior -or $r.executionPassed -isnot [bool] -or -not $r.executionPassed -or $null -ne $r.primaryFailure -or @($r.secondaryErrors).Count -ne 0) {throw 'E02_PREDECESSOR_NOT_SUCCESSFUL'}
        if ($r.frozenInputs.manifest.sha256 -cne (Digest $FreezeManifestPath) -or $r.frozenInputs.sourceHead -cne $script:Freeze.sourceHead) {throw 'E02_PREDECESSOR_CANDIDATE_MISMATCH'}
        $desc=Descriptor $path
        $completionPath=Owned ($prior.ToLowerInvariant()+'/completion.json')
        $completion=Read-Json $completionPath
        if($completion.schemaVersion -ne 1 -or $completion.runId -cne $RunId -or $completion.phase -cne $prior -or
            $completion.state -cne 'COMPLETE' -or $completion.executionPassed -isnot [bool] -or -not $completion.executionPassed -or
            $r.completionRequired -isnot [bool] -or -not $r.completionRequired -or $r.completionPath -ine $completionPath -or
            $r.publicationState -cne 'PROVISIONAL_REQUIRES_COMPLETION_RECORD' -or @($completion.requiredArtifacts).Count -ne 1){throw 'E02_PREDECESSOR_COMPLETION_REQUIRED'}
        $bound=Check-Descriptor $completion.phaseResult
        $required=Check-Descriptor $completion.requiredArtifacts[0]
        if($bound.path -ine $desc.path -or $bound.sha256 -cne $desc.sha256 -or $bound.bytes -ne $desc.bytes -or
            $required.path -ine $desc.path -or $required.sha256 -cne $desc.sha256 -or $required.bytes -ne $desc.bytes -or
            $completion.freezeManifest.sha256 -cne (Digest $FreezeManifestPath) -or $completion.sourceHead -cne $script:Freeze.sourceHead){throw 'E02_PREDECESSOR_COMPLETION_BINDING'}
        Check-BoundDescriptors $completion
        # Every earlier result records its own full predecessor set; a later
        # invocation checks those references against the still-original bytes.
        Check-BoundDescriptors $r
        $desc['completion']=Descriptor $completionPath
        $links.Add($desc)
    }
    if ($Phase -in @('Numeric','WorldInput','Audit')) {
        $selected=Read-Json (Owned 'reports/discovery/selected-names.json')
        if ($selected.selectedCount -ne 16 -or (@($selected.selectedNames)-join "`n") -cne (@($script:Names|Sort-Object -CaseSensitive)-join "`n")) {throw 'E02_FROZEN_DISCOVERY_NAMES_REQUIRED'}
        $discovery=Read-Json (Owned 'discovery/result.json')
        [void](Check-Descriptor $discovery.selectedNameManifest)
    }
    return @($links)
}

$primary=$null;$exitCode=1;$baselineSettings=$null;$beforeAuthored=$null;$beforeStaged=$null;$publicationComplete=$false
try {
    if (-not $IsWindows -or [IntPtr]::Size -ne 8 -or
        [Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture.ToString() -cne 'X64') {throw 'BLOCKED_E02_WINDOWS_X64_ONLY_LINUX_NOT_RUN'}
    $EngineRoot=Assert-Path $EngineRoot
    # These strings enter both UE's custom DDC expression and Windows command
    # arguments. Refuse ambiguous path metacharacters rather than changing them.
    if ($script:RunRoot -match '["()\r\n\x00]' -or $EngineRoot -match '["\r\n\x00]') {throw 'E02_AMBIGUOUS_COMMAND_PATH'}
    [void](Assert-Path $script:RunRoot)
    if ($Phase -eq 'Preflight') {
        if ([IO.Directory]::Exists($script:RunRoot) -or [IO.File]::Exists($script:RunRoot)) {throw 'E02_RUN_ID_ALREADY_USED'}
        [void][IO.Directory]::CreateDirectory($script:RunRoot)
    } elseif (-not [IO.Directory]::Exists($script:RunRoot)) {throw 'E02_PREFLIGHT_REQUIRED'}
    $script:Lock=[IO.File]::Open((Owned 'run.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    New-Directory $script:PhaseRoot
    $script:Result=[ordered]@{schemaVersion=1;runId=$RunId;phase=$Phase;startedUtc=[DateTime]::UtcNow.ToString('o');completedUtc=$null;
        status='RUNNING';executionPassed=$false;primaryFailure=$null;secondaryErrors=$script:Errors;predecessors=@();processes=[Collections.Generic.List[object]]::new();
        frozenInputs=$null;authority=$null;completionRequired=$true;publicationState='PROVISIONAL_REQUIRES_COMPLETION_RECORD';completionPath=(Join-Path $script:PhaseRoot 'completion.json');
        limits=@{buildSeconds=1800;nativeSeconds=600;supervisorGroupSeconds=600;shutdownGraceMaximumSeconds=15;linux='NOT_RUN';humanInput='NOT_RUN';packaging='NOT_RUN';finalAcceptance='REQUIRES_FRESH_CODE_AND_REQ';descendantLedger='NOT_COLLECTED'}}
    $script:Result.frozenInputs=Check-Freeze
    $script:Result.predecessors=@(Check-Previous)
    $beforeAuthored=@(Snapshot-Authored $script:Repo)
    if ($Phase -eq 'Preflight') {
        Copy-FrozenProject $beforeAuthored
        foreach($dir in @('logs','reports','artifacts','ddc','ue-user','temp','dotnet-home','nuget','uba')) {New-Directory (Owned $dir)}
        foreach($dir in @('reports/supervisor-controls','reports/discovery','reports/numeric','reports/world-input','artifacts/discovery','artifacts/numeric','artifacts/world-input')) {New-Directory (Owned $dir)}
        Write-JsonNew (Owned 'manifest.json') @{schemaVersion=1;runId=$RunId;frozenInputs=$script:Result.frozenInputs;createdUtc=[DateTime]::UtcNow.ToString('o');scope='SYNTHETIC_ADVISORY_NO_CORE';nativeNames=$script:Names}
        $script:Result.status='PREFLIGHT_PASS_SOURCE_REVIEW_STILL_REQUIRED'
    } else {
        $beforeStaged=@(Snapshot-Authored $script:Stage);Same-Snapshot $beforeAuthored $beforeStaged
        if ((Digest $script:Fixture) -cne (Digest (Owned 'fixture/world-input-v1.json'))) {throw 'E02_STAGED_FIXTURE_DRIFT'}
        if ($Phase -ne 'Audit') {$script:Result.authority=Check-Authority;Enable-NativeHelper}
        if ($Phase -in @('Build','Discovery','Numeric','WorldInput')) {
            $baselineSettings=@(Settings);$script:Result.settingsBefore=$baselineSettings;Check-Settings $baselineSettings $baselineSettings
            $preflight=Read-Json (Owned 'preflight/result.json')
            if ($preflight.Contains('settingsAfter')) {Check-Settings $preflight.settingsAfter $baselineSettings}
            Check-StagedPluginClosure -RequireTargetReceipt:($Phase -ne 'Build')
        }
        switch($Phase) {
            'SupervisorControls' {$script:Result.controls=Supervisor-Controls;$script:Result.controlReport=Descriptor (Owned 'reports/supervisor-controls/index.json');$script:Result.status='SUPERVISOR_CONTROLS_PASS'}
            'Build' {
                # Selection receipts and Build.bat execute in one cmd environment
                # and the same Engine/Source CWD. GetDotnetPath initializes the
                # bundled path; its later Build.bat call reuses that exact setup.
                $worker=@'
$ErrorActionPreference='Stop'
$batch=@(
    'cd /d "%E02_ENGINE_SOURCE%"',
    'call "%E02_GET_DOTNET_BAT%"',
    '"%E02_WHERE%" dotnet >"%E02_DOTNET_WHERE_LOG%"',
    'set "E02_SELECTED_DOTNET="',
    'set /p E02_SELECTED_DOTNET=<"%E02_DOTNET_WHERE_LOG%"',
    'for %I in ("!E02_SELECTED_DOTNET!") do @set "E02_SELECTED_DOTNET=%~fI"',
    'if /i not "!E02_SELECTED_DOTNET!"=="%E02_DOTNET_EXE%" (exit /b 97)',
    'dotnet --version >"%E02_DOTNET_SDK_LOG%"',
    'set "E02_SELECTED_SDK="',
    'set /p E02_SELECTED_SDK=<"%E02_DOTNET_SDK_LOG%"',
    'if not "!E02_SELECTED_SDK!"=="%E02_DOTNET_VERSION%" (exit /b 98)',
    'echo E02_DOTNET_SELECTED_PATH=!E02_SELECTED_DOTNET!',
    'echo E02_DOTNET_SELECTED_SDK=!E02_SELECTED_SDK!',
    'call "%E02_BUILD_BAT%" WarhammerClientEditor Win64 Development "-Project=%E02_PROJECT%" -WaitMutex -NoUBA "-UBARootDir=%E02_UBA%" "-Log=%E02_BUILD_LOG%"'
) -join ' && '
& $env:E02_CMD /d /v:on /s /c $batch
if($null -eq $LASTEXITCODE){exit 99};exit $LASTEXITCODE
'@
                $pathReceipt=Owned 'logs/build-dotnet-path.txt';$sdkReceipt=Owned 'logs/build-dotnet-sdk.txt'
                foreach($path in @($pathReceipt,$sdkReceipt)){if([IO.File]::Exists($path) -or [IO.Directory]::Exists($path)){throw 'E02_DOTNET_RECEIPT_ALREADY_EXISTS'}}
                $extra=@{E02_BUILD_BAT=$script:Freeze.toolPaths.buildBat;E02_PROJECT=(Join-Path $script:Stage 'WarhammerClient.uproject');E02_UBA=(Owned 'uba');E02_BUILD_LOG=(Owned 'logs/build.log');
                    E02_CMD=$script:Freeze.toolPaths.cmd;E02_WHERE=$script:Freeze.toolPaths.where;E02_GET_DOTNET_BAT=$script:Freeze.toolPaths.getDotnetPath;
                    E02_ENGINE_SOURCE=(Join-Path $EngineRoot 'Engine/Source');E02_DOTNET_EXE=$script:Freeze.toolPaths.dotnet;E02_DOTNET_VERSION=$script:Freeze.dotnetSdk.version;
                    E02_DOTNET_WHERE_LOG=$pathReceipt;E02_DOTNET_SDK_LOG=$sdkReceipt}
                foreach($value in $extra.Values){if($value -match '[%!^&|<>\r\n\x00]'){throw 'E02_AMBIGUOUS_BUILD_BATCH_VALUE'}}
                $r=Invoke-Root 'build' ([Environment]::ProcessPath) @('-NoProfile','-NonInteractive','-Command',$worker) 1800 $false '' $extra
                Require-RootPass $r
                $resolved=[IO.File]::ReadAllLines((Need-File $pathReceipt));$actualSdk=[IO.File]::ReadAllLines((Need-File $sdkReceipt))
                if($resolved.Length -lt 1 -or (Assert-Path ([IO.Path]::GetFullPath($resolved[0]))) -ine $script:Freeze.toolPaths.dotnet -or
                    $actualSdk.Length -ne 1 -or $actualSdk[0] -cne $script:Freeze.dotnetSdk.version){throw 'E02_ACTUAL_DOTNET_SELECTION_MISMATCH'}
                $buildLog=Owned 'logs/build.log';$log=$script:Utf8.GetString([IO.File]::ReadAllBytes((Need-File $buildLog)));Safe-Text $log
                if($log -match '(?im)\b(?:Win32_Process\.Create|external process broker|using (?:XGE|FASTBuild|Incredibuild|remote executor))\b'){throw 'BLOCKED_E02_BROKERED_OR_REMOTE_BUILD_ROUTE'}
                if ($log -notmatch '(?m)^Result: Succeeded\s*$' -or $log -notmatch '14\.44\.35229' -or $log -notmatch '10\.0\.22621\.0') {throw 'E02_BUILD_SUCCESS_OR_SELECTED_TOOLCHAIN_UNVERIFIED'}
                $dll=Descriptor (Join-Path $script:Stage 'Binaries\Win64\UnrealEditor-WarhammerClient.dll')
                $generated=@(Get-ChildItem -LiteralPath (Join-Path $script:Stage 'Intermediate') -Recurse -Filter 'E02WorldProofGameMode.generated.h' -File)
                if ($generated.Count -ne 1 -or $dll.bytes -le 0) {throw 'E02_UHT_OR_EDITOR_BINARY_MISSING'}
                $script:Result.build=@{log=Descriptor $buildLog;editorBinary=$dll;generatedHeader=Descriptor $generated[0].FullName;packaging='NOT_RUN';
                    dotnetSelection=@{executable=(Descriptor ([IO.Path]::GetFullPath($resolved[0])));sdkVersion=$actualSdk[0];sdk=$script:Freeze.dotnetSdk;
                        pathReceipt=(Descriptor $pathReceipt);sdkReceipt=(Descriptor $sdkReceipt);workingDirectory=$extra.E02_ENGINE_SOURCE;
                        sameCmdEnvironmentAsBuild=$true;pathext='.EXE';initialBypassVariablesCleared=@('UE_USE_SYSTEM_DOTNET','UE_DOTNET_VERSION','UE_DOTNET_DIR','UE_DOTNET_ARCH','ProgramFiles(Arm)')}}
                Check-StagedPluginClosure -RequireTargetReceipt
                $script:Result.build.targetReceipt=$script:Result.pluginClosure.targetReceipt.artifact
                $script:Result.status='BUILD_PASS'
            }
            {$_ -in @('Discovery','Numeric','WorldInput')} {
                $args=@(Native-Arguments $Phase);$graphical=$Phase -ne 'Numeric'
                $exe=if($graphical){$script:Freeze.toolPaths.editor}else{$script:Freeze.toolPaths.editorCmd}
                $label=if($Phase -eq 'WorldInput'){'world-input'}else{$Phase.ToLowerInvariant()}
                $r=Invoke-Root $label $exe $args 600 $graphical
                Require-RootPass $r;$script:Result.nativeLog=Inspect-NativeLog $Phase
                if ($Phase -eq 'Discovery') {
                    $script:Result.discovery=Check-Discovery
                    $script:Result.selectedNameManifest=Descriptor (Owned 'reports/discovery/selected-names.json')
                    $scene=Read-Json (Owned 'artifacts/discovery/scene.json');Check-Scene $scene -Baseline
                    $script:Result.scene=Descriptor (Owned 'artifacts/discovery/scene.json');$script:Result.status='DISCOVERY_PASS'
                } else {
                    $script:Result.automation=Check-Automation $Phase
                    if($Phase -eq 'WorldInput') {$script:Result.worldArtifacts=World-Artifacts $r;$script:Result.status='WORLD_INPUT_EXECUTION_PASS_VISUAL_INSPECTION_REQUIRED'}
                    else {$script:Result.status='NUMERIC_PASS'}
                }
            }
            'Audit' {
                $world=Read-Json (Owned 'worldinput/result.json')
                $numeric=Read-Json (Owned 'numeric/result.json')
                $script:Result.nativeExecutionCounts=@{numericCases=$numeric.automation.executed;renderedInputCases=$world.automation.executed;totalCases=([int]$numeric.automation.executed+[int]$world.automation.executed);
                    numericActualAssertions=$numeric.automation.actualAssertionTotal;renderedInputActualAssertions=$world.automation.actualAssertionTotal;
                    totalActualAssertions=([long]$numeric.automation.actualAssertionTotal+[long]$world.automation.actualAssertionTotal);supervisorGroups=3;supervisorSubcases=6;supervisorProcessRoots=5}
                if($script:Result.nativeExecutionCounts.numericCases -ne 4 -or $script:Result.nativeExecutionCounts.renderedInputCases -ne 12 -or $script:Result.nativeExecutionCounts.totalCases -ne 16){throw 'E02_AUDIT_NATIVE_COUNTS'}
                foreach($item in @($world.worldArtifacts.scene,$world.worldArtifacts.inputTrace,$world.worldArtifacts.rayTrace,$world.worldArtifacts.screenshotManifest)+@($world.worldArtifacts.caseSnapshots)) {[void](Check-Descriptor $item)}
                foreach($image in $world.worldArtifacts.requiredImages) {[void](Check-Descriptor $image.artifact)}
                foreach($previous in $script:Result.predecessors) {
                    $record=Read-Json $previous.path
                    foreach($process in $record.processes) {
                        if (-not $process.cleanupConfirmed -or -not $process.exitConfirmed) {throw 'E02_AUDIT_PROCESS_CLEANUP_UNVERIFIED'}
                    }
                }
                $script:Result.status='EVIDENCE_GATHERED_REQUIRES_INDEPENDENT_AUDIT'
                $script:Result.visualInspection='PENDING_SEPARATE_ACTUAL_IMAGE_INSPECTION'
            }
        }
    }
    $script:Result.executionPassed=$true
} catch {
    $primary=Failure $_ $Phase
    if($null -ne $script:Result){$script:Result.primaryFailure=$primary;$script:Result.status=$(if($primary.message.StartsWith('BLOCKED_')){'BLOCKED'}else{'FAIL'});$script:Result.executionPassed=$false}
} finally {
    if($null -ne $script:Result) {
        foreach($observation in @('frozen','authored','staged','settings','plugin-discovery','outputs')) {
            try {
                switch($observation) {
                    'frozen' {if($null -ne $script:Freeze){$script:Result.frozenInputsAfter=Check-Freeze}}
                    'authored' {if($null -ne $beforeAuthored){$script:Result.authoredAfter=@(Snapshot-Authored $script:Repo);Same-Snapshot $beforeAuthored $script:Result.authoredAfter}}
                    'staged' {if($null -ne $beforeStaged){$script:Result.stagedAfter=@(Snapshot-Authored $script:Stage);Same-Snapshot $beforeStaged $script:Result.stagedAfter}}
                    'settings' {
                        if($Phase -eq 'Preflight' -or $null -ne $baselineSettings){
                            $script:Result.settingsAfter=@(Settings)
                            Check-Settings $script:Result.settingsAfter $script:Result.settingsAfter
                            if($null -ne $baselineSettings){Check-Settings $baselineSettings $script:Result.settingsAfter}
                        }
                    }
                    'plugin-discovery' {
                        if($script:Result.Contains('pluginClosure')){
                            $prior=$script:Result.pluginClosure
                            $closure=Read-Json $prior.artifact.path
                            $script:Result.pluginDiscoveryAfter=Check-PluginDiscoveryCatalog $closure
                            if($null -ne $prior.targetReceipt){$script:Result.targetReceiptAfter=Check-TargetReceipt $closure}
                        }
                    }
                    'outputs' {$script:Result.generatedPaths=@(Output-Inventory)}
                }
            } catch {
                $diagnostic=Failure $_ "final-$observation";$script:Errors.Add($diagnostic)
                if($null -eq $script:Result.primaryFailure){$script:Result.primaryFailure=$diagnostic}
                $script:Result.executionPassed=$false;$script:Result.status='FAIL'
            }
        }
        $script:Result.completedUtc=[DateTime]::UtcNow.ToString('o')
        # Dispose the run lock before final serialization, retaining close errors.
        if($null -ne $script:Lock){try{$script:Lock.Dispose();$script:Lock=$null}catch{
            $diagnostic=Failure $_ 'run-lock-close';$script:Errors.Add($diagnostic)
            if($null -eq $script:Result.primaryFailure){$script:Result.primaryFailure=$diagnostic}
            $script:Result.executionPassed=$false;$script:Result.status='FAIL'
        }}
        if($script:Errors.Count -gt 0){$script:Result.executionPassed=$false;$script:Result.status='FAIL'}
        try {
            $phaseResultPath=Join-Path $script:PhaseRoot 'result.json'
            Write-JsonNew $phaseResultPath $script:Result
            $requiredArtifacts=@((Descriptor $phaseResultPath))
            if($Phase -eq 'Audit') {
                Write-JsonNew (Owned 'result.json') @{schemaVersion=1;runId=$RunId;status=$script:Result.status;executionPassed=$script:Result.executionPassed;
                    completionRequired=$true;publicationState='PROVISIONAL_REQUIRES_AUDIT_COMPLETION_RECORD';completionPath=$script:Result.completionPath;
                    finalAcceptance='NOT_ESTABLISHED';phaseResults=$script:Result.predecessors;auditResult=$requiredArtifacts[0]}
                $requiredArtifacts+=Descriptor (Owned 'result.json')
            }
            # This last atomic publication is the authoritative success record.
            # Earlier immutable raw results remain provisional if any step fails.
            if($script:Result.executionPassed){
                Write-JsonNew $script:Result.completionPath @{schemaVersion=1;runId=$RunId;phase=$Phase;state='COMPLETE';executionPassed=$true;
                    completedUtc=[DateTime]::UtcNow.ToString('o');sourceHead=$script:Freeze.sourceHead;freezeManifest=(Descriptor $FreezeManifestPath);
                    phaseResult=$requiredArtifacts[0];requiredArtifacts=$requiredArtifacts}
                $publicationComplete=$true;$exitCode=0
            }
        } catch {
            $diagnostic=Failure $_ 'result-finalization'
            $script:Errors.Add($diagnostic)
            if($null -eq $script:Result.primaryFailure){$script:Result.primaryFailure=$diagnostic}
            $script:Result.executionPassed=$false;$script:Result.status='FAIL';$script:Result.publicationState='FINALIZATION_FAILED';$publicationComplete=$false;$exitCode=1
            try{Write-JsonNew (Join-Path $script:PhaseRoot 'finalization-failure.json') $script:Result}
            catch{$script:Errors.Add((Failure $_ 'finalization-failure-record'))}
            [Console]::Error.WriteLine((ConvertTo-Json -InputObject @{runId=$RunId;phase=$Phase;status='FAIL';primaryFailure=$script:Result.primaryFailure;finalizationFailure=$diagnostic;secondaryErrors=@($script:Errors)} -Depth 20 -Compress))
        }
    }
    if($null -ne $script:Lock){try{$script:Lock.Dispose()}catch{[Console]::Error.WriteLine('E02_RUN_LOCK_CLOSE_UNVERIFIED')}}
}
if($null -eq $script:Result){
    [Console]::Error.WriteLine((ConvertTo-Json -InputObject @{runId=$RunId;phase=$Phase;status='FAIL_BEFORE_PHASE_CREATION';failure=$primary} -Compress -Depth 10))
} else {[Console]::Out.WriteLine((ConvertTo-Json -InputObject @{runId=$RunId;phase=$Phase;status=$script:Result.status;executionPassed=($script:Result.executionPassed -and $publicationComplete);
    publicationComplete=$publicationComplete;completion=$(if($publicationComplete){$script:Result.completionPath}else{$null});result=(Join-Path $script:PhaseRoot 'result.json')} -Compress))}
exit $exitCode
