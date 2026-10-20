<#
E04-A1E INERT SUBSET DRAFT. No phase is authorized by source authoring.
Root amendment0004 follows the preserved blocked18-file design. Editor global EH
is measured honestly for BOTH modules, not mistaken for a disabled runtime caller.
E04-A1G remains required before full A1/RQ11/production adoption; no A1G result here.
Required freeze schema v1: experiment E04-A1, subset
E04-A1E_EDITOR_MODULE_RAW_DOCUMENT_PROOF, runtimeCallerProof NOT_RUN_REQUIRED_E04_A1G,
sourceHead, packet descriptor,
files[] descriptors, sourceMembership (uproject/Source/Config/all authored Plugins),
projectPluginMembership {rootRelativePath:Plugins,topLevelDirectories:[E04ProfileProof],
descriptors:[{relativePath,bytes,sha256}]}, toolPaths,
windows (actual resolved compiler/toolchain/SDK selection), dependency
{preparationId,sourceRoot,acquisitionResult descriptor}, pluginClosure descriptor,
compilerInputs and dotnetSdk matching the retained E02 runtime compiler contract.
Every runtime/compiler/CMake/Ninja/build/SDK/native input must be frozen in files[].
Authority schema v1: experiment E04-A1, SAME exact subset/runtimeCallerProof,
runId, explicitRootGo:true, allowedPhases:[Phase],
freezeManifest descriptor, sourceReviewed {sourceHead,status:PASS,report descriptor,
freezeManifestSha256,pluginClosureReviewed:true,dependencyAndHarnessReviewed:true}.
Both inputs must be in this repository's .local/reviews/E04A1*/ family.
No visible-window option. No network/acquisition/install/Core/Python/E02 tests.
Stream/data64MiB and aggregate reports512MiB are post-operation acceptance checks;
preserve oversize files and every partial failure, never truncate or delete/retry.
Supervisor job deadline is enforced; synchronous host I/O checks its phase clock
at operation boundaries. These limits are not OS network/instantaneous disk quotas.
Reuse provenance: Invoke-E02WorldProof.ps1 154668 bytes SHA256
3047BA75D8E293A616FE0039928A315A979CA312B814ADCB8B3AD588B8151C30.
The literal C# body is unchanged (UTF8 SHA EFC07429759AED7CB1B41D8179E1F44FBE6C1AF2C2398E6497825C75701FF250).
Retained E02_* control tags/diagnostic strings identify the exact supervisor fixture,
not E02 Automation tests, a transferred E02 execution result or E02 environment inputs.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Preflight','SupervisorControls','Configure','DependencyBuild','EditorBuild','Discovery','Native','Audit')][string]$Phase,
    [Parameter(Mandatory)][ValidatePattern('^[0-9]{8}T[0-9]{6}Z-[0-9a-f]{8}$')][string]$RunId,
    [Parameter(Mandatory)][string]$FreezeManifestPath,
    [Parameter(Mandatory)][string]$AuthorityPath,
    [string]$EngineRoot='C:/Program Files/Epic Games/UE_5.8'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$script:Utf8=[Text.UTF8Encoding]::new($false,$true)
$script:Repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$script:RunRoot=Join-Path $script:Repo ".local/experiments/E04A1/$RunId"
$script:Stage=Join-Path $script:RunRoot 'project'
$script:PhaseRoot=Join-Path $script:RunRoot $Phase.ToLowerInvariant()
$script:Packet=Join-Path $script:Repo 'docs/plans/research/2026-10-19-e04a-profile-packet.md'
$script:FixtureRoot=Join-Path $script:Repo 'tests/migration/fixtures/e04a'
$script:Order=@('Preflight','SupervisorControls','Configure','DependencyBuild','EditorBuild','Discovery','Native','Audit')
$script:Subset='E04-A1E_EDITOR_MODULE_RAW_DOCUMENT_PROOF'
$script:RuntimeCallerProof='NOT_RUN_REQUIRED_E04_A1G'
$script:Budgets=@{Preflight=300;SupervisorControls=600;Configure=600;DependencyBuild=1200;EditorBuild=1800;Discovery=600;Native=600;Audit=300}
$script:SuiteSlugs=[ordered]@{'Abi.LoadAndBoundary'='abi-load-boundary';'Abi.TypedRefusal'='abi-typed-refusal';'Abi.ValueLifetime'='abi-value-lifetime';'Parser.CanonicalSyntax'='parser-canonical-syntax';'Parser.OrderedCaseValues'='parser-ordered-case-values';'Parser.LexicalFailures'='parser-lexical-failures';'Parser.ResourceBounds'='parser-resource-bounds';'Integration.RepeatIsolation'='integration-repeat-isolation'}
$script:Names=@($script:SuiteSlugs.Keys|ForEach-Object {"Warhammer.Migration.E04A1.$_"})
$script:Disabled=@('UdpMessaging','TcpMessaging','QuicMessaging','WebSocketMessaging','DiscoveryBeaconReceiver','NetworkServiceDiscovery')
$script:Secrets=[Collections.Generic.List[string]]::new()
foreach($entry in [Environment]::GetEnvironmentVariables().GetEnumerator()) {if($entry.Key -match '(?i)TOKEN|PASSWORD|SECRET|API_KEY|CREDENTIAL' -and ([string]$entry.Value).Length -ge 8){$script:Secrets.Add([string]$entry.Value)}}
$script:Errors=[Collections.Generic.List[object]]::new()
$script:Result=$null;$script:Freeze=$null;$script:E02UserContext=$null;$script:RunLock=$null
$script:Clock=[Diagnostics.Stopwatch]::StartNew();$script:RootCount=0
# exact reused function Assert-Path; original rows 138-151; UTF8 SHA256 93A9B93B0F8FB8F820A1BA0263661E991D088347A811AC1AA40EF8036C731E0B
# exact reused function Under; original rows 152-157; UTF8 SHA256 58D77B2E28DDA4A175B0AA9BBE70BF88F0F18EF61C3F6E4C88C65642FE7972AD
# exact reused function Owned; original rows 158-161; UTF8 SHA256 0DF4EE43A173B67447C55CD0F0C5F4E3C640F5F7CBBB77CFDF0B4404116ECDF9
# exact reused function Need-File; original rows 162-169; UTF8 SHA256 E7A4C4AC8A77B0BD7DDA9F1F9716EA1CFFBA4211DA4456C2D7F8042BC59FA7D2
# exact reused function Digest; original rows 170-170; UTF8 SHA256 8B187B58E6DC4219967EACEDD23C15CF3EFD77BA1671DE659A955FA605A901F2
# exact reused function Descriptor; original rows 171-171; UTF8 SHA256 C1E8E2472A2DE317ADB51A15AB28E4E45FCB09B7BE19FC3E1E1CC98E2DC99178
# exact reused function Check-Descriptor; original rows 172-178; UTF8 SHA256 4B5572B9FA05319F360F5B92763261095D2972CE9D7B16E39F8BB1357F49D705
# exact reused function Safe-Text; original rows 179-182; UTF8 SHA256 C37FF40CE1AAD536A737E2E6EDFAF16DD6E53FF0C2CF5B36C63B87D9B47AE078
# exact reused function Check-JsonElement; original rows 183-196; UTF8 SHA256 D35616DEACA2D0A7560120C407D3BC5920885530559B6C6A8D53654D5BC3E454
# exact reused function Read-Json; original rows 197-210; UTF8 SHA256 E2EA572F532FC3E12CD586AA061128DFBAF59299CB5F9295D9D4A0511E137A41
# exact reused function Failure; original rows 211-215; UTF8 SHA256 5AE70D84E23304E182266085CD524CDBBE6014489D9B4B3D5420A75083EA89DF
# exact reused function Write-JsonNew; original rows 216-242; UTF8 SHA256 D8D03DA8E514FBC2AAD355B680C42DDDDAB1309DCB2FA48736368167703C71F3
# exact reused function New-Directory; original rows 243-247; UTF8 SHA256 C17333F26AACA28D24800EADF146677110A05E42F87CE6E6CB91011E76DB8415
# exact reused function Get-Head; original rows 254-268; UTF8 SHA256 11E7239DA47713D125DA6CBC670E3A13852434205FC08992946053F19C25CF18
# exact reused function Check-CompilerInputs; original rows 289-322; UTF8 SHA256 EBD33665E5BBE1312E501B9FEDF4D091EED1D85C32062B1AAFC38894E55F2B39
# exact reused function Check-DotnetSdk; original rows 323-334; UTF8 SHA256 F03F8312F370796061DDC8DC49A9E08E3BDC527DD48C243D826A7253F6A825B4
# exact reused function Observed-File; original rows 713-743; UTF8 SHA256 50F9F7BA5830B9BC3D8E0B33A9902636C3508BD20EF59E3BF67977523B16DB8D
# exact reused function Execution-UserContext; original rows 744-757; UTF8 SHA256 60A52D10FDC4D5C2C829A578F01F69EE30FF7CC732CB9F9322C5B9E6824D605B
# exact reused function Settings; original rows 758-773; UTF8 SHA256 2F1AEF475198377AE8126C3183B1649C19297A2FB74BD8E5B4E7FA561D386AA7
# exact reused function Check-Settings; original rows 774-788; UTF8 SHA256 25A8421BD71F1C5463F5195A7ACF8B84BB8F14195B80BB119EFFE8386D1254DF
# exact reused function Control-UInt; original rows 900-907; UTF8 SHA256 AA8AC9EA9DEE429520ADE38AEF99FFA0FF410170F3220F1145AEA68003B4A750
# exact reused function Control-Utc; original rows 909-920; UTF8 SHA256 7EE68047B9C31EE71A91B193E3D6A08F6F74442B8FFBB0FD8CD083A033459DD3
# exact reused function Sup03-Diagnostic; original rows 922-939; UTF8 SHA256 8B39D20BCA5CC4EAD2B916B9A57CAFE89F372D5C619C2727998C48055DB8F7BE
# exact reused function Check-Sup03ExpectedFailure; original rows 941-1052; UTF8 SHA256 D79CE8F67C8C37CE4CFB044485083B0647141B6B24C8F2A3C02EFE3A0BB7EC61
# exact reused function Check-ControlChildEvidence; original rows 1054-1157; UTF8 SHA256 07864D0A13E198ACC1671AEE9F6BBD18A172FF0F992018E5E5F7CE029B48DA3D
# exact reused function Supervisor-Controls; original rows 1159-1279; UTF8 SHA256 75B5FE725CD9E863DC4FAF1D5707A081DA667B0E7E5A1DB9318C0E23869434E1

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
    # Unreal Automation may prefix its JSON export with one UTF-8 byte-order mark.
    $offset=0
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) { $offset=3 }
    $text = $script:Utf8.GetString($bytes,$offset,$bytes.Length-$offset); Safe-Text $text
    $options = [Text.Json.JsonDocumentOptions]::new(); $options.MaxDepth=80
    $doc = [Text.Json.JsonDocument]::Parse($text,$options)
    try { Check-JsonElement $doc.RootElement 0 } finally { $doc.Dispose() }
    return ConvertFrom-Json -InputObject $text -AsHashtable -Depth 80 -DateKind String
}

function Parse-JsonLine([string] $Line) {
    if ($Line.Length -gt 8MB -or [string]::IsNullOrWhiteSpace($Line)) { throw 'E02_JSONL_EMPTY_OR_OVERSIZED_LINE' }
    Safe-Text $Line; $options=[Text.Json.JsonDocumentOptions]::new();$options.MaxDepth=80
    $doc=[Text.Json.JsonDocument]::Parse($Line,$options)
    try { Check-JsonElement $doc.RootElement 0 } finally {$doc.Dispose()}
    return ConvertFrom-Json -InputObject $Line -AsHashtable -Depth 80 -DateKind String
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

function Observed-File([string] $Role,[string] $Path,[switch] $KnownDocumentsObservation) {
    $r=[ordered]@{role=$Role;path=[IO.Path]::GetFullPath($Path);observedUtc=[DateTime]::UtcNow.ToString('o');inspection='UNAVAILABLE';exists=$null;sha256=$null;
        pathPolicy=$(if($KnownDocumentsObservation){'READ_ONLY_ACTUAL_KNOWN_DOCUMENTS_LOGICAL_PATH'}else{'STRICT_NO_REPARSE_PATH'})}
    try {
        if($KnownDocumentsObservation) {
            # This exception cannot authorize arbitrary reads or enter an owned
            # output/descriptor path. Bind the two exact OS-known-folder roles.
            $documents=[Environment]::GetFolderPath('MyDocuments')
            if(-not [IO.Path]::IsPathFullyQualified($documents)){throw 'E02_SETTINGS_ROOT_UNAVAILABLE'}
            $relative=switch -CaseSensitive ($Role) {
                'editor-known-documents-user' {'Unreal Engine/Engine/Config/UserEditorSettings.ini'}
                'ubt-known-documents' {'Unreal Engine/UnrealBuildTool/BuildConfiguration.xml'}
                default {throw 'E02_INVALID_KNOWN_DOCUMENTS_OBSERVATION_ROLE'}
            }
            if($r.path -cne [IO.Path]::GetFullPath((Join-Path $documents $relative))){throw 'E02_INVALID_KNOWN_DOCUMENTS_OBSERVATION_PATH'}
        } else {[void](Assert-Path $r.path)}
        $absent=$false
        try { $attributes=[IO.File]::GetAttributes($r.path) }
        catch [IO.FileNotFoundException] { $absent=$true } catch [IO.DirectoryNotFoundException] { $absent=$true }
        $r.exists=-not $absent
        if (-not $absent) {
            if (($attributes -band ([IO.FileAttributes]::Directory -bor [IO.FileAttributes]::ReparsePoint)) -ne 0) { throw 'E02_SETTINGS_NOT_PLAIN_FILE' }
            # A cloud-backed ancestor is not a claim about resolved target
            # identity. Hash only an observed plain leaf, through the exact
            # external logical path; never use this route for run artifacts.
            $r.sha256=if($KnownDocumentsObservation){(Get-FileHash -Algorithm SHA256 -LiteralPath $r.path -ErrorAction Stop).Hash.ToLowerInvariant()}else{Digest $r.path}
        }
        $r.inspection='PASS'
    } catch { $r.error=Failure $_ 'settings-observation' }
    return $r
}

function Execution-UserContext {
    $local=[Environment]::GetFolderPath('LocalApplicationData'); $roaming=[Environment]::GetFolderPath('ApplicationData')
    $profile=[Environment]::GetFolderPath('UserProfile'); $documents=[Environment]::GetFolderPath('MyDocuments')
    foreach($root in @($local,$roaming,$profile,$documents)) { if (-not [IO.Path]::IsPathFullyQualified($root)) { throw 'E02_SETTINGS_ROOT_UNAVAILABLE' } }
    # This desktop proof must observe the workstation's existing LocalAppData
    # settings. A restricted package context can redirect this known folder to
    # Packages/sandbox.../AC and report the real EditorSettings file absent.
    # Refuse that execution context before allocating a run or starting a child.
    $expectedLocal=Assert-Path (Join-Path $profile 'AppData/Local')
    if((Assert-Path $local) -ine $expectedLocal){throw 'BLOCKED_E02_REDIRECTED_LOCAL_SETTINGS_CONTEXT_USE_APPROVED_NORMAL_DESKTOP_ROUTE'}
    return [ordered]@{localApplicationData=(Assert-Path $local);applicationData=(Assert-Path $roaming);
        userProfile=(Assert-Path $profile);myDocuments=([IO.Path]::GetFullPath($documents));policy='NORMAL_DESKTOP_LOCAL_APPDATA_PROFILE_ROUTE';
        myDocumentsUsage='TWO_READ_ONLY_LOGICAL_SETTINGS_PATHS_ANCESTOR_TAGS_AND_TARGET_IDENTITY_UNVERIFIED'}
}

function Settings {
    $context=Execution-UserContext
    if($null -eq $script:E02UserContext -or ($context|ConvertTo-Json -Compress) -cne ($script:E02UserContext|ConvertTo-Json -Compress)){throw 'E02_EXECUTION_USER_CONTEXT_CHANGED'}
    $local=$context.localApplicationData;$roaming=$context.applicationData;$profile=$context.userProfile;$documents=$context.myDocuments
    return @(
        Observed-File 'editor-engine-base' (Join-Path $EngineRoot 'Engine\Config\BaseEditorSettings.ini')
        Observed-File 'editor-local-user' (Join-Path $local 'Unreal Engine\Engine\Config\UserEditorSettings.ini')
        Observed-File 'editor-local-versioned' (Join-Path $local 'UnrealEngine\5.8\Saved\Config\WindowsEditor\EditorSettings.ini')
        Observed-File 'editor-profile-documents-user' (Join-Path $profile 'Documents\Unreal Engine\Engine\Config\UserEditorSettings.ini')
        Observed-File 'editor-project-default' (Join-Path $script:Stage 'Config\DefaultEditorSettings.ini')
        Observed-File 'editor-known-documents-user' (Join-Path $documents 'Unreal Engine\Engine\Config\UserEditorSettings.ini') -KnownDocumentsObservation
        Observed-File 'ubt-roaming' (Join-Path $roaming 'Unreal Engine\UnrealBuildTool\BuildConfiguration.xml')
        Observed-File 'ubt-local' (Join-Path $local 'Unreal Engine\UnrealBuildTool\BuildConfiguration.xml')
        Observed-File 'ubt-known-documents' (Join-Path $documents 'Unreal Engine\UnrealBuildTool\BuildConfiguration.xml') -KnownDocumentsObservation
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
            $expectedPolicy=if($s.role -cin @('editor-known-documents-user','ubt-known-documents')){'READ_ONLY_ACTUAL_KNOWN_DOCUMENTS_LOGICAL_PATH'}else{'STRICT_NO_REPARSE_PATH'}
            if($s.pathPolicy -cne $expectedPolicy){throw 'E02_SETTINGS_OBSERVATION_PATH_POLICY'}
            if ($s.inspection -cne 'PASS' -or $s.exists -isnot [bool] -or ($s.exists -and $s.sha256 -cnotmatch '^[0-9a-f]{64}$') -or (-not $s.exists -and $null -ne $s.sha256)) { throw 'E02_SETTINGS_UNAVAILABLE' }
        }
        if ($prior.path -cne $current[0].path -or $prior.exists -cne $current[0].exists -or $prior.sha256 -cne $current[0].sha256) { throw 'E02_SETTINGS_CHANGED' }
    }
}

function Control-UInt($Value, [uint64] $Maximum=[uint64]::MaxValue) {
    $allowed=@([byte],[sbyte],[int16],[uint16],[int32],[uint32],[int64],[uint64])
    if ($null -eq $Value -or $Value.GetType() -notin $allowed -or
        [decimal]$Value -lt 0 -or [decimal]$Value -gt [decimal]$Maximum) {
        throw 'E02_CONTROL_INTEGER_EVIDENCE_INVALID'
    }
    return [uint64]$Value
}

function Control-Utc($Value) {
    if ($Value -isnot [string] -or
        $Value -cnotmatch '\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,7})?(?:Z|\+00:00)\z') {
        throw 'E02_CONTROL_UTC_EVIDENCE_INVALID'
    }
    $utc=[DateTimeOffset]::MinValue
    if (-not [DateTimeOffset]::TryParse($Value,[Globalization.CultureInfo]::InvariantCulture,
        [Globalization.DateTimeStyles]::None,[ref]$utc) -or $utc.Offset -ne [TimeSpan]::Zero) {
        throw 'E02_CONTROL_UTC_EVIDENCE_INVALID'
    }
    return $utc
}

function Sup03-Diagnostic($Diagnostic,[string] $Stage,[string] $Message,$Started,$Completed) {
    $keys=@('stage','type','message','win32Error','syntheticFault','observedUtc')
    if ($Diagnostic -isnot [Collections.IDictionary] -or $Diagnostic.get_Count() -ne $keys.Count) {
        throw 'E02_SUP03_DIAGNOSTIC_SCHEMA_INVALID'
    }
    foreach($key in $keys) {
        if ($key -cnotin $Diagnostic.get_Keys()) { throw 'E02_SUP03_DIAGNOSTIC_SCHEMA_INVALID' }
    }
    if ($Diagnostic['stage'] -isnot [string] -or $Diagnostic['stage'] -cne $Stage -or
        $Diagnostic['type'] -isnot [string] -or $Diagnostic['type'] -cne 'System.InvalidOperationException' -or
        $Diagnostic['message'] -isnot [string] -or $Diagnostic['message'] -cne $Message -or
        $Diagnostic['syntheticFault'] -isnot [bool] -or -not $Diagnostic['syntheticFault'] -or
        $null -ne $Diagnostic['win32Error']) { throw 'E02_SUP03_EXPECTED_DIAGNOSTIC_NOT_OBSERVED' }
    $observed=Control-Utc ($Diagnostic['observedUtc'])
    if ($observed -lt $Started -or $observed -gt $Completed) {
        throw 'E02_SUP03_DIAGNOSTIC_TIME_INVALID'
    }
}

function Check-Sup03ExpectedFailure($Record,
    [ValidateSet('assign','query','close')][string] $Fault,
    [string] $ExpectedExecutable,[string] $ExpectedWorkingDirectory) {
    # Key membership uses the actual key collection for native generic dictionaries,
    # Hashtable and OrderedDictionary; no Contains overload or adapted .Keys property.
    $required=@('schemaVersion','syntheticFault','status','technicalBlocked','timedOut',
        'cleanupConfirmed','exitConfirmed','assignedBeforeResume','resumed','visibleWindowRequested',
        'pid','creationFileTime','creationUtc','exitFileTime','exitUtc','exitCode','exitObservedUtc',
        'startedObservationUtc','completedObservationUtc','elapsedSeconds','budgetSeconds',
        'executable','arguments','workingDirectory','primaryFailure','secondaryErrors','jobAccounting')
    if ($Record -isnot [Collections.IDictionary]) { throw 'E02_SUP03_RECEIPT_SCHEMA_INVALID' }
    foreach($key in $required) {
        if ($key -cnotin $Record.get_Keys()) { throw 'E02_SUP03_RECEIPT_SCHEMA_INVALID' }
    }
    if ($Record['technicalBlocked'] -isnot [bool]) { throw 'E02_SUP03_RECEIPT_STATE_INVALID' }
    if ($Record['technicalBlocked']) { throw 'BLOCKED_E02_PRIVATE_JOB_OR_PROCESS_SETUP_UNSUPPORTED' }
    if ((Control-UInt ($Record['schemaVersion']) 1) -ne 1 -or
        $Record['syntheticFault'] -isnot [string] -or $Record['syntheticFault'] -cne $Fault -or
        $Record['status'] -isnot [string] -or $Record['status'] -cne 'FAIL') {
        throw 'E02_SUP03_SYNTHETIC_FAILURE_NOT_FAIL_CLOSED'
    }
    $shouldResume=$Fault -cne 'assign'
    foreach($state in @(@('timedOut',$false),@('cleanupConfirmed',$true),@('exitConfirmed',$true),
        @('assignedBeforeResume',$shouldResume),@('resumed',$shouldResume),@('visibleWindowRequested',$false))) {
        if ($Record[$state[0]] -isnot [bool] -or $Record[$state[0]] -ne $state[1]) {
            throw 'E02_SUP03_RECEIPT_STATE_INVALID'
        }
    }
    if ((Control-UInt ($Record['budgetSeconds']) 15) -ne 15 -or
        $Record['executable'] -isnot [string] -or $Record['executable'] -cne $ExpectedExecutable -or
        $Record['workingDirectory'] -isnot [string] -or $Record['workingDirectory'] -cne $ExpectedWorkingDirectory) {
        throw 'E02_SUP03_FIXTURE_IDENTITY_INVALID'
    }
    $expectedArguments=@('-NoProfile','-NonInteractive','-Command','exit 0')
    if ($Record['arguments'] -isnot [Collections.IList] -or $Record['arguments'].Count -ne 4) {
        throw 'E02_SUP03_FIXTURE_IDENTITY_INVALID'
    }
    for($i=0;$i -lt $expectedArguments.Count;$i++) {
        if ($Record['arguments'][$i] -isnot [string] -or $Record['arguments'][$i] -cne $expectedArguments[$i]) {
            throw 'E02_SUP03_FIXTURE_IDENTITY_INVALID'
        }
    }
    if ((Control-UInt ($Record['pid']) ([uint32]::MaxValue)) -eq 0) { throw 'E02_SUP03_PID_UNVERIFIED' }
    $creation=Control-UInt ($Record['creationFileTime']) ([long]::MaxValue)
    $exit=Control-UInt ($Record['exitFileTime']) ([long]::MaxValue)
    if ($creation -eq 0 -or $exit -lt $creation) { throw 'E02_SUP03_KERNEL_TIMES_UNVERIFIED' }
    try { $kernelCreation=[DateTime]::FromFileTimeUtc([long]$creation);$kernelExit=[DateTime]::FromFileTimeUtc([long]$exit) }
    catch [ArgumentOutOfRangeException] { throw 'E02_SUP03_KERNEL_TIMES_UNVERIFIED' }
    $created=Control-Utc ($Record['creationUtc']);$exited=Control-Utc ($Record['exitUtc'])
    $started=Control-Utc ($Record['startedObservationUtc']);$completed=Control-Utc ($Record['completedObservationUtc'])
    $exitObserved=Control-Utc ($Record['exitObservedUtc'])
    if ($created.UtcDateTime -ne $kernelCreation -or $exited.UtcDateTime -ne $kernelExit -or
        $started -gt $created -or $exited -gt $exitObserved -or $exitObserved -gt $completed) {
        throw 'E02_SUP03_PROCESS_TIME_EVIDENCE_INVALID'
    }
    $numeric=@([byte],[sbyte],[int16],[uint16],[int32],[uint32],[int64],[uint64],[single],[double],[decimal])
    $elapsed=$Record['elapsedSeconds']
    if ($null -eq $elapsed -or $elapsed.GetType() -notin $numeric -or
        [double]::IsNaN([double]$elapsed) -or [double]::IsInfinity([double]$elapsed) -or [double]$elapsed -le 0) {
        throw 'E02_SUP03_ELAPSED_EVIDENCE_INVALID'
    }
    $hasResume='resumedObservationUtc' -cin $Record.get_Keys()
    if ($shouldResume) {
        if (-not $hasResume) { throw 'E02_SUP03_RESUME_EVIDENCE_INVALID' }
        $resumed=Control-Utc ($Record['resumedObservationUtc'])
        if ($resumed -lt $created -or $resumed -gt $exitObserved) { throw 'E02_SUP03_RESUME_EVIDENCE_INVALID' }
    } elseif ($hasResume) { throw 'E02_SUP03_RESUME_EVIDENCE_INVALID' }
    $exitCode=Control-UInt ($Record['exitCode']) ([uint32]::MaxValue)
    $secondary=$Record['secondaryErrors']
    if ($secondary -isnot [Collections.IList]) { throw 'E02_SUP03_SECONDARY_ERRORS_INVALID' }
    if ($Fault -ceq 'close') {
        if ($null -ne $Record['primaryFailure'] -or $secondary.Count -ne 1 -or $exitCode -ne 0) {
            throw 'E02_SUP03_CLOSE_DIAGNOSTIC_MISSING_OR_UNEXPECTED_FAILURE'
        }
        Sup03-Diagnostic $secondary[0] 'close-control-seam' 'E02_INJECTED_HANDLE_FINALIZATION_FAILURE' $started $completed
    } else {
        if ($secondary.Count -ne 0 -or
            ($Fault -ceq 'assign' -and $exitCode -ne [uint64]3760193538) -or
            ($Fault -ceq 'query' -and $exitCode -notin @([uint64]0,[uint64]3760193538))) {
            throw 'E02_SUP03_UNEXPECTED_FAILURE_OR_EXIT'
        }
        $message=if($Fault -ceq 'assign'){'E02_INJECTED_ASSIGN_FAILURE_BEFORE_RESUME'}else{'E02_INJECTED_ACCOUNTING_QUERY_FAILURE'}
        Sup03-Diagnostic ($Record['primaryFailure']) 'owned-root' $message $started $completed
    }
    $samples=$Record['jobAccounting']
    if ($samples -isnot [Collections.IList] -or $samples.Count -eq 0) { throw 'E02_SUP03_JOB_ZERO_UNVERIFIED' }
    $last=$samples[$samples.Count-1]
    $sampleKeys=@('stage','observedUtc','querySucceeded','totalProcesses','activeProcesses',
        'totalTerminatedProcesses','totalUserTime100ns','totalKernelTime100ns',
        'thisPeriodUserTime100ns','thisPeriodKernelTime100ns','totalPageFaultCount')
    if ($last -isnot [Collections.IDictionary]) { throw 'E02_SUP03_JOB_ZERO_UNVERIFIED' }
    foreach($key in $sampleKeys) {
        if ($key -cnotin $last.get_Keys()) { throw 'E02_SUP03_JOB_ZERO_UNVERIFIED' }
    }
    $expectedStage=if($Fault -ceq 'close'){'progress'}else{'failure-cleanup'}
    if ($last['stage'] -isnot [string] -or $last['stage'] -cne $expectedStage -or
        $last['querySucceeded'] -isnot [bool] -or -not $last['querySucceeded'] -or
        (Control-UInt ($last['activeProcesses']) ([uint32]::MaxValue)) -ne 0) {
        throw 'E02_SUP03_JOB_ZERO_UNVERIFIED'
    }
    $total=Control-UInt ($last['totalProcesses']) ([uint32]::MaxValue)
    if (($Fault -ceq 'assign' -and $total -ne 0) -or ($Fault -cne 'assign' -and $total -lt 1)) {
        throw 'E02_SUP03_JOB_MEMBERSHIP_EVIDENCE_INVALID'
    }
    foreach($key in $sampleKeys[5..10]) { [void](Control-UInt ($last[$key])) }
    $sampleObserved=Control-Utc ($last['observedUtc'])
    if ($sampleObserved -lt $exitObserved -or $sampleObserved -gt $completed) {
        throw 'E02_SUP03_JOB_SAMPLE_TIME_INVALID'
    }
    # Success emits nothing and changes no field. Invoke-Root already preserved
    # the raw native FAIL receipt before this enclosing-case assertion runs.
}

function Check-ControlChildEvidence($Record,[bool] $Timeout,[string] $Executable,[string] $Command) {
    # This reads only the closed, descriptor-bound stdout of the fixed fixture.
    # Parent observations retain the original Process handle; aggregate job
    # accounting is separate evidence, not a per-child identity query.
    if ($Record['technicalBlocked'] -isnot [bool]) { throw 'E02_CHILD_CONTROL_STATE_INVALID' }
    if ($Record['technicalBlocked']) { throw 'BLOCKED_E02_PRIVATE_JOB_OR_PROCESS_SETUP_UNSUPPORTED' }
    foreach($state in @(@('timedOut',$Timeout),@('cleanupConfirmed',$true),@('exitConfirmed',$true),
        @('assignedBeforeResume',$true),@('resumed',$true),@('visibleWindowRequested',$false))) {
        if ($Record[$state[0]] -isnot [bool] -or $Record[$state[0]] -ne $state[1]) { throw 'E02_CHILD_CONTROL_STATE_INVALID' }
    }
    $budget=if($Timeout){8}else{20};$status=if($Timeout){'FAIL'}else{'PASS'}
    if ((Control-UInt ($Record['schemaVersion']) 1) -ne 1 -or
        (Control-UInt ($Record['budgetSeconds']) 20) -ne $budget -or $Record['status'] -cne $status -or
        $Record['syntheticFault'] -isnot [string] -or $Record['syntheticFault'].Length -ne 0 -or $Record['executable'] -cne $Executable -or
        $Record['workingDirectory'] -cne $script:Stage) { throw 'E02_CHILD_CONTROL_FIXTURE_IDENTITY_INVALID' }
    $arguments=$Record['arguments'];$expected=@('-NoProfile','-NonInteractive','-Command',$Command)
    if ($arguments -isnot [Collections.IList] -or $arguments.Count -ne 4) { throw 'E02_CHILD_CONTROL_ARGUMENTS_INVALID' }
    for($i=0;$i -lt 4;$i++) { if($arguments[$i] -isnot [string] -or $arguments[$i] -cne $expected[$i]) { throw 'E02_CHILD_CONTROL_ARGUMENTS_INVALID' } }
    if ($Record['secondaryErrors'] -isnot [Collections.IList] -or $Record['secondaryErrors'].Count -ne 0) { throw 'E02_CHILD_CONTROL_UNEXPECTED_SECONDARY_ERROR' }
    $rootPid=Control-UInt ($Record['pid']) ([uint32]::MaxValue)
    $rootCreation=Control-UInt ($Record['creationFileTime']) ([long]::MaxValue)
    $rootExit=Control-UInt ($Record['exitFileTime']) ([long]::MaxValue)
    if ($rootPid -eq 0 -or $rootCreation -eq 0 -or $rootExit -lt $rootCreation) { throw 'E02_CHILD_CONTROL_ROOT_IDENTITY_INVALID' }
    $created=Control-Utc ($Record['creationUtc']);$exited=Control-Utc ($Record['exitUtc'])
    $started=Control-Utc ($Record['startedObservationUtc']);$completed=Control-Utc ($Record['completedObservationUtc'])
    $exitObserved=Control-Utc ($Record['exitObservedUtc']);$resumed=Control-Utc ($Record['resumedObservationUtc'])
    if ($created.UtcDateTime -ne [DateTime]::FromFileTimeUtc([long]$rootCreation) -or
        $exited.UtcDateTime -ne [DateTime]::FromFileTimeUtc([long]$rootExit) -or
        $started -gt $created -or $created -gt $resumed -or $resumed -gt $exitObserved -or
        $exited -gt $exitObserved -or $exitObserved -gt $completed) { throw 'E02_CHILD_CONTROL_ROOT_TIMES_INVALID' }
    $exitCode=Control-UInt ($Record['exitCode']) ([uint32]::MaxValue)
    if ($Timeout) {
        $timeoutError=$Record['primaryFailure'];$keys=@('stage','type','message','win32Error','syntheticFault','observedUtc')
        if ($timeoutError -isnot [Collections.IDictionary] -or $timeoutError.get_Count() -ne $keys.Count) { throw 'E02_SUP02_TIMEOUT_DIAGNOSTIC_INVALID' }
        foreach($key in $keys) { if($key -cnotin $timeoutError.get_Keys()) { throw 'E02_SUP02_TIMEOUT_DIAGNOSTIC_INVALID' } }
        if ($timeoutError['stage'] -cne 'owned-root' -or $timeoutError['type'] -cne 'System.TimeoutException' -or
            $timeoutError['message'] -cne 'Owned execution exceeded its reserved running budget' -or
            $timeoutError['syntheticFault'] -isnot [bool] -or $timeoutError['syntheticFault'] -or $null -ne $timeoutError['win32Error'] -or
            $exitCode -ne [uint64]3760193537) { throw 'E02_SUP02_EXPECTED_TIMEOUT_NOT_OBSERVED' }
        $timeoutErrorTime=Control-Utc ($timeoutError['observedUtc'])
        if($timeoutErrorTime -lt $started -or $timeoutErrorTime -gt $completed) { throw 'E02_SUP02_TIMEOUT_DIAGNOSTIC_TIME_INVALID' }
    } elseif ($null -ne $Record['primaryFailure'] -or $exitCode -ne 0 -or
        $Record['rootExitWhileMembersActive'] -isnot [bool] -or -not $Record['rootExitWhileMembersActive']) {
        throw 'E02_SUP01_LINGERING_CHILD_NOT_OBSERVED'
    }
    $samples=$Record['jobAccounting']
    if($samples -isnot [Collections.IList] -or $samples.Count -eq 0) { throw 'E02_CHILD_CONTROL_JOB_ZERO_UNVERIFIED' }
    $last=$samples[$samples.Count-1]
    if($last['querySucceeded'] -isnot [bool] -or -not $last['querySucceeded'] -or
        (Control-UInt ($last['activeProcesses']) ([uint32]::MaxValue)) -ne 0 -or
        (Control-UInt ($last['totalProcesses']) ([uint32]::MaxValue)) -lt 2) { throw 'E02_CHILD_CONTROL_JOB_ZERO_UNVERIFIED' }
    $sampleTime=Control-Utc ($last['observedUtc'])
    if($sampleTime -lt $exitObserved -or $sampleTime -gt $completed) { throw 'E02_CHILD_CONTROL_JOB_SAMPLE_TIME_INVALID' }
    $stdout=Check-Descriptor ($Record['stdoutArtifact'])
    if($stdout.bytes -le 0 -or $stdout.bytes -gt 65536 -or $Record['stderrArtifact'].bytes -ne 0) { throw 'E02_CHILD_CONTROL_OUTPUT_INVALID' }
    $lines=[IO.File]::ReadAllLines($stdout.path,$script:Utf8)
    if($lines.Count -lt 2 -or (-not $Timeout -and $lines.Count -ne 2)) { throw 'E02_CHILD_CONTROL_OBSERVATIONS_MISSING' }
    $observations=[Collections.Generic.List[object]]::new();$previousTime=$created;$previousMs=[uint64]0
    $childPid=[uint64]0;$childCreation=[uint64]0;$lastAlive=$null;$firstAliveMs=$null
    for($i=0;$i -lt $lines.Count;$i++) {
        $item=Parse-JsonLine $lines[$i]
        $keys=@('schemaVersion','kind','rootPid','childPid','childCreationFileTime','hasExited','observedUtc','elapsedMs')
        if($i -eq 0){$keys+=@('ackRaw','ackReadElapsedMs')}else{$keys+=@('sequence')}
        if($item -isnot [Collections.IDictionary] -or $item.get_Count() -ne $keys.Count) { throw 'E02_CHILD_CONTROL_OBSERVATION_SCHEMA_INVALID' }
        foreach($key in $keys) { if($key -cnotin $item.get_Keys()) { throw 'E02_CHILD_CONTROL_OBSERVATION_SCHEMA_INVALID' } }
        $kind=if($i -eq 0){'E02_SUP_CHILD_BOUND_V1'}else{'E02_SUP_CHILD_ALIVE_V1'}
        if((Control-UInt ($item['schemaVersion']) 1) -ne 1 -or $item['kind'] -cne $kind -or
            (Control-UInt ($item['rootPid']) ([uint32]::MaxValue)) -ne $rootPid -or
            $item['hasExited'] -isnot [bool] -or $item['hasExited']) { throw 'E02_CHILD_CONTROL_OBSERVATION_INVALID' }
        $observed=Control-Utc ($item['observedUtc']);$ms=Control-UInt ($item['elapsedMs']) ([long]::MaxValue)
        if($observed -lt $previousTime -or $observed -gt $exited -or $ms -lt $previousMs) { throw 'E02_CHILD_CONTROL_OBSERVATION_TIME_INVALID' }
        if($i -eq 0) {
            $childPid=Control-UInt ($item['childPid']) ([int]::MaxValue)
            $childCreation=Control-UInt ($item['childCreationFileTime']) ([long]::MaxValue)
            $ackMs=Control-UInt ($item['ackReadElapsedMs']) 1999
            if($childPid -eq 0 -or $childPid -eq $rootPid -or $childCreation -lt $rootCreation -or
                [DateTime]::FromFileTimeUtc([long]$childCreation) -gt $observed.UtcDateTime -or $ackMs -gt $ms) { throw 'E02_CHILD_CONTROL_BOUND_IDENTITY_INVALID' }
            $expectedAck=([ordered]@{schemaVersion=1;kind='E02_SUP_CHILD_READY_V1';childPid=[int]$childPid;childCreationFileTime=[long]$childCreation}|ConvertTo-Json -Compress -Depth 3)
            if($item['ackRaw'] -isnot [string] -or $item['ackRaw'].Length -gt 256 -or
                -not [string]::Equals($item['ackRaw'],$expectedAck,[StringComparison]::Ordinal)) { throw 'E02_CHILD_CONTROL_SELF_ACK_INVALID' }
        } else {
            if((Control-UInt ($item['childPid']) ([int]::MaxValue)) -ne $childPid -or
                (Control-UInt ($item['childCreationFileTime']) ([long]::MaxValue)) -ne $childCreation -or
                (Control-UInt ($item['sequence']) ([int]::MaxValue)) -ne $i) { throw 'E02_CHILD_CONTROL_ALIVE_IDENTITY_INVALID' }
            if($i -eq 1){$firstAliveMs=$ms}
            $lastAlive=$observed
        }
        $previousTime=$observed;$previousMs=$ms;$observations.Add($item)
    }
    $termination=$null
    if($Timeout) {
        if($lines.Count -lt 3 -or ($previousMs - $firstAliveMs) -lt 250 -or
            $Record['shutdownRequests'] -isnot [Collections.IList]) { throw 'E02_SUP02_CHILD_ALIVE_PROOF_MISSING' }
        $termination=@($Record['shutdownRequests']|Where-Object {$_['operation'] -ceq 'TerminateJobObject'})
        if($termination.Count -ne 1 -or $termination[0]['succeeded'] -isnot [bool] -or -not $termination[0]['succeeded']) { throw 'E02_SUP02_PRIVATE_JOB_TERMINATION_UNVERIFIED' }
        $termination=Control-Utc ($termination[0]['observedUtc'])
        if($termination -lt $lastAlive -or ($termination-$lastAlive).TotalSeconds -gt 1 -or $termination -gt $completed) { throw 'E02_SUP02_CHILD_ALIVE_PROOF_STALE' }
    }
    # Return annotations only; never change the already-published native receipt.
    return @{stdoutArtifact=$stdout;childPid=$childPid;childCreationFileTime=$childCreation;observations=@($observations);
        lastAliveUtc=$lastAlive.ToString('o');terminationObservationUtc=$(if($null -ne $termination){$termination.ToString('o')}else{$null});
        basis='FIXED_CHILD_SELF_ACK_MATCHED_TO_ORIGINAL_PROCESS_HANDLE_AND_FINITE_HAS_EXITED_OBSERVATIONS';
        limits='Not a direct per-child job query or complete descendant inventory. Job accounting independently establishes final zero active members.'}
}

function Supervisor-Controls {
    $pwsh=Need-File ([Environment]::ProcessPath)
    $clock=[Diagnostics.Stopwatch]::StartNew()
    $results=[Collections.Generic.List[object]]::new()
    # Fixed trusted child/parent programs; no caller-supplied shell program text.
    # Keep the original child Process until fixture exit; no PID reopening.
$fixtureChildTemplate=@'
$ErrorActionPreference='Stop'
try {
    $self=[Diagnostics.Process]::GetCurrentProcess()
    try {
        $selfPid=[int]$self.Id
        $selfCreation=[long]$self.StartTime.ToFileTimeUtc()
    } finally { $self.Dispose() }
    if($selfPid -le 0 -or $selfCreation -le 0){throw 'E02_SUP_CHILD_SELF_IDENTITY'}
    $ack=[ordered]@{schemaVersion=1;kind='E02_SUP_CHILD_READY_V1';childPid=$selfPid;childCreationFileTime=$selfCreation}
    [Console]::Out.WriteLine(($ack|ConvertTo-Json -Compress -Depth 3))
    [Console]::Out.Flush()
    Start-Sleep -Seconds __HOLD_SECONDS__
    exit 0
} catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    [Console]::Error.Flush()
    exit 1
}
'@

$fixtureParentTemplate=@'
$ErrorActionPreference='Stop'
$childCommand=__CHILD_LITERAL__
$childExecutable=__EXECUTABLE_LITERAL__
$timeoutMode=__TIMEOUT_LITERAL__
$c=$null
$failureCode='START'
$emit={param($value)
    [Console]::Out.WriteLine(($value|ConvertTo-Json -Compress -Depth 5))
    [Console]::Out.Flush()
}
try {
    $si=[Diagnostics.ProcessStartInfo]::new()
    $si.FileName=$childExecutable
    $si.UseShellExecute=$false
    $si.CreateNoWindow=$true
    $si.RedirectStandardOutput=$true
    foreach($a in @('-NoProfile','-NonInteractive','-Command',$childCommand)){$si.ArgumentList.Add($a)}
    $clock=[Diagnostics.Stopwatch]::StartNew()
    $c=[Diagnostics.Process]::Start($si)
    if($null -eq $c){throw 'E02_SUP_CHILD_START_NULL'}
    if($c.HasExited){throw 'E02_SUP_CHILD_EXITED_BEFORE_ACK'}
    $childPid=[int]$c.Id
    $childCreation=[long]$c.StartTime.ToFileTimeUtc()
    if($childPid -le 0 -or $childCreation -le 0){throw 'E02_SUP_CHILD_ORIGINAL_IDENTITY'}
    $failureCode='ACK'
    $read=$c.StandardOutput.ReadLineAsync()
    while(-not $read.IsCompleted){
        if($c.HasExited){throw 'E02_SUP_CHILD_EXITED_DURING_ACK'}
        if($clock.ElapsedMilliseconds -ge 2000){throw 'E02_SUP_CHILD_ACK_TIMEOUT'}
        Start-Sleep -Milliseconds 20
    }
    if($clock.ElapsedMilliseconds -ge 2000){throw 'E02_SUP_CHILD_ACK_TIMEOUT'}
    $ackReadElapsedMs=[long]$clock.ElapsedMilliseconds
    $rawAck=$read.GetAwaiter().GetResult()
    if($null -eq $rawAck -or $rawAck.Length -gt 256){throw 'E02_SUP_CHILD_ACK_LENGTH'}
    $expectedAck=([ordered]@{schemaVersion=1;kind='E02_SUP_CHILD_READY_V1';childPid=$childPid;childCreationFileTime=$childCreation}|ConvertTo-Json -Compress -Depth 3)
    if(-not [string]::Equals($rawAck,$expectedAck,[StringComparison]::Ordinal)){throw 'E02_SUP_CHILD_ACK_IDENTITY_OR_FORMAT'}
    if($c.HasExited){throw 'E02_SUP_CHILD_EXITED_AFTER_ACK'}
    & $emit ([ordered]@{schemaVersion=1;kind='E02_SUP_CHILD_BOUND_V1';rootPid=[int]$PID;childPid=$childPid;childCreationFileTime=$childCreation;ackRaw=$rawAck;ackReadElapsedMs=$ackReadElapsedMs;hasExited=$false;observedUtc=[DateTime]::UtcNow.ToString('o');elapsedMs=[long]$clock.ElapsedMilliseconds})
    $sequence=0
    $lastAliveMs=-250L
    $failureCode='OBSERVATION'
    while($clock.ElapsedMilliseconds -lt 60000){
        if($c.HasExited){$failureCode='CHILD_EXIT';throw 'E02_SUP_CHILD_EXITED_WHILE_ROOT_HELD'}
        $now=[long]$clock.ElapsedMilliseconds
        if($sequence -eq 0 -or $now-$lastAliveMs -ge 250){
            $sequence++
            & $emit ([ordered]@{schemaVersion=1;kind='E02_SUP_CHILD_ALIVE_V1';rootPid=[int]$PID;childPid=$childPid;childCreationFileTime=$childCreation;sequence=$sequence;hasExited=$false;observedUtc=[DateTime]::UtcNow.ToString('o');elapsedMs=$now})
            $lastAliveMs=$now
        }
        if(-not $timeoutMode){exit 0}
        Start-Sleep -Milliseconds 100
    }
    throw 'E02_SUP_CHILD_ROOT_HOLD_EXHAUSTED'
} catch {
    & $emit ([ordered]@{schemaVersion=1;kind='E02_SUP_FIXTURE_FAILURE_V1';rootPid=[int]$PID;code=$failureCode;observedUtc=[DateTime]::UtcNow.ToString('o')})
    [Console]::Error.WriteLine($_.Exception.Message)
    [Console]::Error.Flush()
    exit 1
} finally {
    # Dispose only the original Process wrapper; no PID reopen or child kill.
    # An outstanding read is not synchronously awaited here.
    if($null -ne $c){$c.Dispose()}
}
'@

$fixtureExecutableLiteral="'"+$pwsh.Replace("'","''")+"'"
$normalChild=$fixtureChildTemplate.Replace('__HOLD_SECONDS__','2')
$timeoutChild=$fixtureChildTemplate.Replace('__HOLD_SECONDS__','60')
$normal=$fixtureParentTemplate.Replace('__CHILD_LITERAL__',("'"+$normalChild.Replace("'","''")+"'")).Replace('__EXECUTABLE_LITERAL__',$fixtureExecutableLiteral).Replace('__TIMEOUT_LITERAL__','$false')
$long=$fixtureParentTemplate.Replace('__CHILD_LITERAL__',("'"+$timeoutChild.Replace("'","''")+"'")).Replace('__EXECUTABLE_LITERAL__',$fixtureExecutableLiteral).Replace('__TIMEOUT_LITERAL__','$true')
    $r=Invoke-Root 'sup01-normal-lingering' $pwsh @('-NoProfile','-NonInteractive','-Command',$normal) 20
    Require-RootPass $r
    $childProof=Check-ControlChildEvidence $r $false $pwsh $normal
    $results.Add(@{group='SUP01';subcase='normal-root-lingering-child';status='PASS';childProof=$childProof;process=Descriptor (Join-Path $script:PhaseRoot 'sup01-normal-lingering.process.json')})
    $r=Invoke-Root 'sup02-timeout' $pwsh @('-NoProfile','-NonInteractive','-Command',$long) 8
    $childProof=Check-ControlChildEvidence $r $true $pwsh $long
    $results.Add(@{group='SUP02';subcase='timeout-root-child';status='PASS';attemptStatus='FAIL';childProof=$childProof;process=Descriptor (Join-Path $script:PhaseRoot 'sup02-timeout.process.json')})
    foreach($fault in @('assign','query','close')) {
        $r=Invoke-Root "sup03-$fault" $pwsh @('-NoProfile','-NonInteractive','-Command','exit 0') 15 $false $fault
        Check-Sup03ExpectedFailure $r $fault $pwsh $script:Stage
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
                if(key.IndexOfAny(new[]{'\0','='})>=0 || key.Equals("UE_ADDITIONAL_PLUGIN_PATHS",StringComparison.OrdinalIgnoreCase) || key.Equals("UE-CmdLineArgs",StringComparison.OrdinalIgnoreCase) || System.Text.RegularExpressions.Regex.IsMatch(key,"TOKEN|PASSWORD|SECRET|API_KEY|CREDENTIAL",System.Text.RegularExpressions.RegexOptions.IgnoreCase)) continue;
                vars[key]=(string)entry.Value;
            }
            foreach(var pair in environment) {
                if(pair.Key.IndexOfAny(new[]{'\0','='})>=0 || pair.Value.IndexOf('\0')>=0) throw new ArgumentException("Environment NUL/key");
                if((pair.Key.Equals("UE_ADDITIONAL_PLUGIN_PATHS",StringComparison.OrdinalIgnoreCase) || pair.Key.Equals("UE-CmdLineArgs",StringComparison.OrdinalIgnoreCase)) && pair.Value.Length!=0) throw new ArgumentException("E02 reserved startup environment must be empty");
                vars[pair.Key]=pair.Value;
            }
            // The effective block also clears these channels if a caller omits
            // an override. UE appends UE-CmdLineArgs before selecting plugins.
            vars["UE_ADDITIONAL_PLUGIN_PATHS"]=""; vars["UE-CmdLineArgs"]="";
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

function Phase-Budget {
    $remaining=[int][Math]::Floor($script:Budgets[$Phase]-$script:Clock.Elapsed.TotalSeconds)
    if($remaining -le 0){throw 'E04A1_PHASE_DEADLINE_EXCEEDED'};return $remaining
}
function Plain-Files([string]$Root,[switch]$SkipGit) {
    $rootPath=Assert-Path $Root;$stack=[Collections.Generic.Stack[string]]::new();$stack.Push($rootPath)
    $found=[Collections.Generic.List[string]]::new()
    while($stack.Count){[void](Phase-Budget);foreach($entry in [IO.Directory]::EnumerateFileSystemEntries($stack.Pop())){
        $p=Under $entry $rootPath;$attributes=[IO.File]::GetAttributes($p)
        if($SkipGit -and $p -ieq (Join-Path $rootPath '.git')){continue}
        if(($attributes -band [IO.FileAttributes]::Directory) -ne 0){$stack.Push($p)}else{$found.Add($p)}
    }};return @($found|Sort-Object -CaseSensitive)
}
function Snapshot-Source([string]$Root) {
    $files=@((Join-Path $Root 'WarhammerClient.uproject'))
    foreach($top in @('Source','Config')){$files+=@(Plain-Files (Join-Path $Root $top))}
    $pluginRoot=Join-Path $Root 'Plugins'
    foreach($p in Plain-Files $pluginRoot){
        $relative=[IO.Path]::GetRelativePath($pluginRoot,$p).Replace('\','/')
        # Only the owned proof plugin's generated output is outside authored source.
        # Descriptor discovery separately scans these subtrees without exclusions.
        if($relative -cmatch '^E04ProfileProof/(Binaries|Intermediate)/'){continue}
        $files+=$p
    }
    $items=@(foreach($p in $files){$d=Descriptor $p;[ordered]@{path=[IO.Path]::GetRelativePath($Root,$p).Replace('\','/');bytes=$d.bytes;sha256=$d.sha256}})
    return @($items|Sort-Object {$_.path} -CaseSensitive)
}
function Snapshot-ProjectPlugins([string]$Root) {
    $pluginRoot=Under (Join-Path $Root 'Plugins') $Root
    if(-not [IO.Directory]::Exists($pluginRoot)){throw 'E04A1_PROJECT_PLUGIN_ROOT_REQUIRED'}
    $directories=[Collections.Generic.List[string]]::new()
    foreach($entry in [IO.Directory]::EnumerateFileSystemEntries($pluginRoot)){
        [void](Phase-Budget);$path=Under $entry $pluginRoot;$attributes=[IO.File]::GetAttributes($path)
        if(($attributes -band [IO.FileAttributes]::Directory) -ne 0){$directories.Add([IO.Path]::GetFileName($path))}
    }
    return [ordered]@{rootRelativePath='Plugins';topLevelDirectories=@($directories|Sort-Object -CaseSensitive);descriptors=@(Catalog-Descriptors $pluginRoot)}
}
function Check-ProjectPluginMembership($Expected,[string]$Root) {
    # The approved eighteen-path subset adds exactly one project plugin. Binding
    # top-level directories also detects an empty/descriptor-free sibling plugin.
    if($Expected -isnot [Collections.IDictionary] -or
        (@($Expected.Keys|Sort-Object -CaseSensitive)-join ',') -cne 'descriptors,rootRelativePath,topLevelDirectories' -or
        $Expected.rootRelativePath -cne 'Plugins' -or $Expected.topLevelDirectories -isnot [Collections.IList] -or
        @($Expected.topLevelDirectories).Count -ne 1 -or $Expected.topLevelDirectories[0] -cne 'E04ProfileProof' -or
        $Expected.descriptors -isnot [Collections.IList] -or @($Expected.descriptors).Count -ne 1){throw 'E04A1_PROJECT_PLUGIN_MEMBERSHIP_SHAPE_OR_SCOPE'}
    $expectedDescriptor=$Expected.descriptors[0]
    if($expectedDescriptor -isnot [Collections.IDictionary] -or
        (@($expectedDescriptor.Keys|Sort-Object -CaseSensitive)-join ',') -cne 'bytes,relativePath,sha256' -or
        $expectedDescriptor.relativePath -cne 'E04ProfileProof/E04ProfileProof.uplugin' -or
        ($expectedDescriptor.bytes -isnot [long] -and $expectedDescriptor.bytes -isnot [int]) -or $expectedDescriptor.bytes -le 0 -or
        $expectedDescriptor.sha256 -isnot [string] -or $expectedDescriptor.sha256 -cnotmatch '^[a-fA-F0-9]{64}$'){throw 'E04A1_PROJECT_PLUGIN_DESCRIPTOR_SHAPE'}
    $actual=Snapshot-ProjectPlugins $Root
    if(@($actual.topLevelDirectories).Count -ne 1 -or $actual.topLevelDirectories[0] -cne 'E04ProfileProof' -or
        @($actual.descriptors).Count -ne 1){throw 'E04A1_PROJECT_PLUGIN_DIRECTORY_OR_DESCRIPTOR_MEMBERSHIP_CHANGED'}
    $descriptor=$actual.descriptors[0]
    if($descriptor.relativePath -cne $expectedDescriptor.relativePath -or $descriptor.bytes -ne $expectedDescriptor.bytes -or
        $descriptor.sha256 -ine $expectedDescriptor.sha256){throw 'E04A1_PROJECT_PLUGIN_DESCRIPTOR_MEMBERSHIP_OR_BYTES_CHANGED'}
    return @{path=(Join-Path $Root 'Plugins');topLevelDirectories=@($actual.topLevelDirectories);descriptors=@($actual.descriptors);
        membershipAndBytes='MATCH_FROZEN_PROJECT_PLUGIN_CATALOG';observedUtc=[DateTime]::UtcNow.ToString('o');
        limits='Exact top-level directory set and all recursive raw descriptors, including generated subtrees; source snapshot excludes only proof Binaries/Intermediate generated files. Not a continuous filesystem monitor.'}
}
function Same-Source($Before,$After) {
    if(($Before|ConvertTo-Json -Depth 10 -Compress) -cne ($After|ConvertTo-Json -Depth 10 -Compress)){throw 'E04A1_SOURCE_CONFIG_PLUGIN_MEMBERSHIP_OR_BYTES_CHANGED'}
}
function Review-Path([string]$Path) {
    $full=Under $Path (Join-Path $script:Repo '.local/reviews')
    if([IO.Path]::GetRelativePath((Join-Path $script:Repo '.local/reviews'),$full).Replace('\','/') -cnotmatch '^E04A1[^/]*/'){throw 'E04A1_REVIEW_INPUT_FAMILY_REQUIRED'};return Need-File $full
}
function Check-Freeze {
    [void](Review-Path $FreezeManifestPath);$m=Read-Json $FreezeManifestPath
    if($m.schemaVersion -ne 1 -or $m.experiment -cne 'E04-A1' -or $m.subset -cne $script:Subset -or $m.runtimeCallerProof -cne $script:RuntimeCallerProof -or $m.sourceHead -cne (Get-Head)){throw 'E04A1E_FREEZE_SUBSET_HEAD_OR_SCHEMA_MISMATCH'}
    $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach($d in $m.files){$actual=Check-Descriptor $d;if(-not $seen.Add($actual.path)){throw 'E04A1_DUPLICATE_FROZEN_PATH'}}
    foreach($p in @($PSCommandPath,$script:Packet,(Join-Path $script:Repo 'AGENTS.md'),(Join-Path (Split-Path $script:Repo -Parent) 'AGENTS.md'),(Join-Path $script:FixtureRoot 'corpus-manifest.json'),(Join-Path $script:FixtureRoot 'generated-cases.json'))){if(-not $seen.Contains((Need-File $p))){throw 'E04A1_REQUIRED_INPUT_NOT_FROZEN'}}
    if((Check-Descriptor $m.packet).path -ine $script:Packet){throw 'E04A1_PACKET_MISMATCH'}
    Same-Source @($m.sourceMembership) @(Snapshot-Source $script:Repo)
    [void](Check-ProjectPluginMembership $m.projectPluginMembership $script:Repo)
    foreach($d in $m.sourceMembership){if(-not $seen.Contains((Need-File (Join-Path $script:Repo $d.path)))){throw 'E04A1_SOURCE_FILE_NOT_FROZEN'}}
    foreach($name in @('cmake','ninja','buildBat','editor','editorCmd','compiler','linker','librarian','sdkRc','dotnet','cmd','where','getDotnetPath')){if(-not $seen.Contains((Need-File $m.toolPaths[$name]))){throw "E04A1_TOOL_NOT_FROZEN: $name"}}
    foreach($p in @([Environment]::ProcessPath,[object].Assembly.Location,[Management.Automation.PSObject].Assembly.Location,[Text.Json.JsonDocument].Assembly.Location,[IO.Compression.ZLibStream].Assembly.Location)){if(-not $seen.Contains((Need-File $p))){throw 'E04A1_LOADED_SUPERVISOR_RUNTIME_NOT_FROZEN'}}
    $version=Read-Json (Join-Path $EngineRoot 'Engine/Build/Build.version')
    if($version.MajorVersion -ne 5 -or $version.MinorVersion -ne 8 -or $version.PatchVersion -ne 3 -or $version.Changelist -ne 58210709 -or -not $seen.Contains((Need-File (Join-Path $EngineRoot 'Engine/Build/Build.version')))){throw 'E04A1_ENGINE_VERSION_NOT_FROZEN'}
    foreach($pair in @(@('buildBat','Engine/Build/BatchFiles/Build.bat'),@('editor','Engine/Binaries/Win64/UnrealEditor.exe'),@('editorCmd','Engine/Binaries/Win64/UnrealEditor-Cmd.exe'))){if($m.toolPaths[$pair[0]] -ine (Join-Path $EngineRoot $pair[1])){throw 'E04A1_ENGINE_TOOL_PATH_MISMATCH'}}
    [void](Check-CompilerInputs $m);[void](Check-DotnetSdk $m)
    $closure=Check-Descriptor $m.pluginClosure;if(-not $seen.Contains($closure.path)){throw 'E04A1_PLUGIN_CLOSURE_NOT_FROZEN'}
    $script:Freeze=$m;Check-Dependency
    if(-not $seen.Contains((Need-File (Join-Path $script:VendorRoot 'LICENSE')))){throw 'E04A1E_ACQUIRED_MIT_LICENSE_NOT_FROZEN'}
    return $m
}
function Check-Authority {
    [void](Review-Path $AuthorityPath);$a=Read-Json $AuthorityPath
    if($a.schemaVersion -ne 1 -or $a.experiment -cne 'E04-A1' -or $a.subset -cne $script:Subset -or $a.runtimeCallerProof -cne $script:RuntimeCallerProof -or $a.runId -cne $RunId -or $a.explicitRootGo -isnot [bool] -or -not $a.explicitRootGo -or @($a.allowedPhases).Count -ne 1 -or $a.allowedPhases[0] -cne $Phase){throw 'E04A1E_EXACT_SUBSET_DIRECT_ROOT_PHASE_GO_REQUIRED'}
    $f=Check-Descriptor $a.freezeManifest
    if($f.path -ine [IO.Path]::GetFullPath($FreezeManifestPath) -or $a.sourceReviewed.freezeManifestSha256 -ine $f.sha256 -or $a.sourceReviewed.sourceHead -cne $script:Freeze.sourceHead -or $a.sourceReviewed.status -cne 'PASS' -or $a.sourceReviewed.pluginClosureReviewed -ne $true -or $a.sourceReviewed.dependencyAndHarnessReviewed -ne $true){throw 'E04A1_MATCHING_AFFECTED_SOURCE_PASS_REQUIRED'}
    [void](Review-Path $a.sourceReviewed.report.path);[void](Check-Descriptor $a.sourceReviewed.report)
    return @{authority=Descriptor $AuthorityPath;sourceReview=$a.sourceReviewed;phase=$Phase;subset=$script:Subset;runtimeCallerProof=$script:RuntimeCallerProof;visibleWindows=0}
}
function Check-Dependency {
    $d=$script:Freeze.dependency
    if($d.preparationId -cne '20261020T001330Z-29e97b84'){throw 'E04A1_ACQUISITION_PREPARATION_NOT_REVIEWED'}
    $owner=Under (Join-Path $script:Repo ('.local/dependencies/E04A1/'+$d.preparationId)) $script:Repo
    $root=Assert-Path (Join-Path $owner 'yaml-cpp');$receipt=Check-Descriptor $d.acquisitionResult
    if($d.sourceRoot -ine $root -or $receipt.path -ine (Join-Path $owner 'acquisition-result.json')){throw 'E04A1_ACQUIRED_ROOT_MISMATCH'}
    $a=Read-Json $receipt.path
    if($a.pin -cne '56e3bb550c91fd7005566f19c079cb7a503223cf' -or $a.status -cne 'ACQUIRED_PIN_AND_BYTES_VERIFIED_NOT_BUILD_OR_SOURCE_APPROVAL' -or $a.allCheckoutBytesMatchPinnedBlobs -ne $true -or $a.dependencySourceExecuted -ne $false -or $a.buildReleased -ne $false){throw 'E04A1_ACQUISITION_RECORD_SCOPE_MISMATCH'}
    $files=@(Plain-Files $root -SkipGit);if($files.Count -ne @($a.files).Count){throw 'E04A1_ACQUIRED_MEMBERSHIP_CHANGED'}
    foreach($e in $a.files){$p=Under (Join-Path $root $e.path) $root;$v=Descriptor $p;if($v.bytes -ne $e.bytes -or $v.sha256 -ine $e.sha256 -or $p -inotIn $files){throw 'E04A1_ACQUIRED_BYTES_CHANGED'}}
    if(([IO.File]::ReadAllText((Need-File (Join-Path $root '.git/HEAD')))).Trim() -cne $a.pin){throw 'E04A1_ACQUIRED_DETACHED_PIN_CHANGED'}
    $script:Dependency=$a;$script:VendorRoot=$root;$script:AcquisitionDescriptor=$receipt
}
function Bytes-Hash([byte[]]$Bytes,[string]$Algorithm='SHA256') {
    $h=[Security.Cryptography.HashAlgorithm]::Create($Algorithm);try{return [Convert]::ToHexString($h.ComputeHash($Bytes)).ToLowerInvariant()}finally{$h.Dispose()}
}
function Expand-Recipe($Recipe) {
    if($Recipe.kind -ceq 'LiteralUtf8'){return ,$script:Utf8.GetBytes([string]$Recipe.text)}
    $n=[int]$Recipe.count;if($n -lt 0 -or $n -gt 1048577){throw 'E04A1_RECIPE_COUNT_OUTSIDE_FROZEN_BOUNDS'}
    $text=switch -CaseSensitive ($Recipe.kind){
        'file'{"a: x`n#"+('p'*($n-7))+"`n"}
        'depth'{('['*$n)+'x'+(']'*$n)+"`n"}
        'nodes'{'['+('x,'*($n-2))+"x]`n"}
        'aliases'{'[&a x'+(', *a'*$n)+"]`n"}
        'scalar'{'"'+('x'*$n)+"`"`n"}
        default{throw 'E04A1_UNKNOWN_RECIPE_KIND'}
    };return ,$script:Utf8.GetBytes($text)
}
function Prepare-Fixtures {
    $c=Read-Json (Join-Path $script:FixtureRoot 'corpus-manifest.json');$g=Read-Json (Join-Path $script:FixtureRoot 'generated-cases.json')
    if($c.schemaVersion -ne 1 -or $g.schemaVersion -ne 1 -or @($c.canonical).Count -ne 10 -or @($g.generated).Count -ne 28 -or $g.totalWithCanonical -ne 38 -or $c.arcadeCommit -cne '5088c1c49dcaff29eb59fb64b3063d30214dde73'){throw 'E04A1_FIXTURE_EXACT_38_REQUIRED'}
    foreach($name in @('corpus-manifest.json','generated-cases.json')){[IO.File]::Copy((Need-File (Join-Path $script:FixtureRoot $name)),(Owned "fixtures/$name"),$false)}
    $definitions=[Collections.Generic.List[object]]::new();$seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach($e in @($c.canonical)+@($g.generated)){
        if(-not $seen.Add($e.id) -or $e.id -cnotmatch '^A1-(?:C[0-9]{2}|K[0-9]{2}|F[0-9]{2}|L\.(?:file|depth|nodes|aliases|scalar)\.(?:below|at|above))$'){throw 'E04A1_DUPLICATE_OR_UNKNOWN_INPUT_ID'}
        $canonical=$e.Contains('sourceRelativePath')
        if($canonical){$src=Under (Join-Path (Join-Path (Split-Path $script:Repo -Parent) 'Warhammer_40k_UI_arcade') $e.sourceRelativePath) (Join-Path (Split-Path $script:Repo -Parent) 'Warhammer_40k_UI_arcade');$d=Descriptor $src;if($d.bytes -ne $e.bytes -or $d.sha256 -ine $e.sha256 -or @($script:Freeze.files|Where-Object {$_.path -ieq $src -and $_.sha256 -ieq $d.sha256}).Count -ne 1){throw 'E04A1_CANONICAL_SOURCE_NOT_FROZEN'};$bytes=[IO.File]::ReadAllBytes($src);$expectedBytes=$e.bytes;$expectedHash=$e.sha256}
        else{$bytes=Expand-Recipe $e.recipe;$expectedBytes=$e.inputBytes;$expectedHash=$e.inputSha256}
        if($bytes.Length -ne $expectedBytes -or (Bytes-Hash $bytes) -ine $expectedHash -or (Bytes-Hash $bytes 'SHA1') -ine $e.inputSha1){throw 'E04A1_FROZEN_RECIPE_OR_CANONICAL_HASH_MISMATCH'}
        $expected=Owned ('fixtures/expected-inputs/'+$e.id+'.yaml');[IO.File]::WriteAllBytes($expected,$bytes)
        if($canonical){[IO.File]::Copy($expected,(Owned ('fixtures/'+$e.id+'.yaml')),$false)}
        $definitions.Add(@{id=$e.id;bytes=$bytes.Length;sha256=(Bytes-Hash $bytes);inputSha1=$e.inputSha1;expectedCode=$e.expectedCode;source=$(if($canonical){'Canonical'}else{'Generated'});recipeKind=$(if($canonical){'StagedFile'}else{$e.recipe.kind});expectedInput=Descriptor $expected})
    }
    $expectedIds=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal);foreach($ids in (Expected-Attempts).Values){foreach($id in $ids){[void]$expectedIds.Add($id)}}
    if($seen.Count -ne 38 -or -not $seen.SetEquals($expectedIds)){throw 'E04A1_EXACT_INPUT_UNION_NOT_38'}
    Write-JsonNew (Owned 'fixtures/input-definitions.json') @{schemaVersion=1;runId=$RunId;sourceHead=$script:Freeze.sourceHead;inputs=@($definitions);primaryHash='SHA256';nativeSha1='AUXILIARY_ONLY'}
}
function Fixture-Snapshot {return @(Plain-Files (Owned 'fixtures')|ForEach-Object {Descriptor $_})}
function Child-Environment([hashtable]$Extra=@{}) {
    $envs=[Collections.Generic.Dictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach($pair in @(@('TEMP','temp'),@('TMP','temp'),@('DOTNET_CLI_HOME','dotnet-home'),@('NUGET_PACKAGES','nuget'),@('UBA_ROOT','uba'))){$envs[$pair[0]]=Owned $pair[1]}
    foreach($pair in @(@('DOTNET_CLI_TELEMETRY_OPTOUT','1'),@('DOTNET_SKIP_FIRST_TIME_EXPERIENCE','1'),@('DOTNET_NOLOGO','1'),@('UE-SharedDataCachePath','None'),@('UE_ADDITIONAL_PLUGIN_PATHS',''),@('UE-CmdLineArgs',''),@('UE_USE_SYSTEM_DOTNET',''),@('UE_DOTNET_VERSION',''),@('UE_DOTNET_DIR',''),@('UE_DOTNET_ARCH',''),@('ProgramFiles(Arm)',''),@('PROCESSOR_ARCHITECTURE','AMD64'),@('PATHEXT','.EXE'),@('DOTNET_MULTILEVEL_LOOKUP','0'))){$envs[$pair[0]]=$pair[1]}
    $w=$script:Freeze.windows;$vc=Assert-Path $w.compilerDir;$sdk=Assert-Path $w.sdkDir;$v=$w.sdkVersion
    $include=@((Join-Path $vc 'include'),(Join-Path $sdk "include/$v/ucrt"),(Join-Path $sdk "include/$v/shared"),(Join-Path $sdk "include/$v/um"),(Join-Path $sdk "include/$v/winrt"),(Join-Path $sdk "include/$v/cppwinrt"))
    $lib=@((Join-Path $vc 'lib/x64'),(Join-Path $sdk "lib/$v/ucrt/x64"),(Join-Path $sdk "lib/$v/um/x64"))
    foreach($p in $include+$lib){[void](Assert-Path $p);if(-not [IO.Directory]::Exists($p)){throw 'E04A1_EXPLICIT_COMPILER_ENVIRONMENT_DIRECTORY_MISSING'}}
    $dotnet=[IO.Path]::GetDirectoryName($script:Freeze.toolPaths.dotnet);$envs['DOTNET_ROOT']=$dotnet;$envs['DOTNET_ROOT_X64']=$dotnet
    $envs['INCLUDE']=$include -join ';';$envs['LIB']=$lib -join ';';$envs['LIBPATH']=$lib -join ';'
    $envs['PATH']=(@([IO.Path]::GetDirectoryName($script:Freeze.toolPaths.compiler),[IO.Path]::GetDirectoryName($script:Freeze.toolPaths.sdkRc),[IO.Path]::GetDirectoryName($script:Freeze.toolPaths.cmake),[IO.Path]::GetDirectoryName($script:Freeze.toolPaths.ninja),$dotnet,[IO.Path]::GetDirectoryName($script:Freeze.toolPaths.cmd)) -join ';')
    foreach($e in $Extra.GetEnumerator()){if($e.Key -clike 'E02_*'){throw 'E04A1_E02_CHILD_ENVIRONMENT_FORBIDDEN'};$envs[$e.Key]=[string]$e.Value};return ,$envs
}
function Invoke-Root([string]$Label,[string]$Executable,[string[]]$Arguments,[int]$Budget,[bool]$Visible=$false,[string]$Fault='',[hashtable]$Extra=@{}) {
    if($Visible){throw 'E04A1_VISIBLE_LAUNCH_FORBIDDEN'}
    $maxRoots=if($Phase -eq 'SupervisorControls'){5}elseif($Phase -in @('Configure','DependencyBuild','EditorBuild','Discovery','Native')){1}else{0}
    if($script:RootCount -ge $maxRoots){throw 'E04A1_DIRECT_ROOT_LIMIT'};$seconds=[Math]::Min($Budget,(Phase-Budget));if($seconds -lt 3 -or $seconds -gt 1800){throw 'E04A1_ROOT_BUDGET_INVALID'}
    $exe=Need-File $Executable;if(@($script:Freeze.files|Where-Object {$_.path -ieq $exe -and $_.sha256 -ieq (Digest $exe)}).Count -ne 1){throw 'E04A1_EXECUTABLE_NOT_FROZEN'}
    $out=Owned "logs/$Label.stdout.log";$err=Owned "logs/$Label.stderr.log";foreach($p in @($out,$err)){if(Test-Path -LiteralPath $p){throw 'E04A1_PROCESS_OUTPUT_COLLISION'}}
    foreach($arg in $Arguments){Safe-Text $arg;if($arg.Contains([char]0)){throw 'E04A1_ARGUMENT_NUL'}}
    $saved=@{};foreach($e in [Environment]::GetEnvironmentVariables('Process').GetEnumerator()){if($e.Key -like 'E02_*' -or $e.Key -match '^(CL|_CL_|LINK|_LINK_|CMAKE_|CC$|CXX$|CFLAGS$|CXXFLAGS$|LDFLAGS$|NINJA_STATUS$)'){$saved[$e.Key]=$e.Value}}
    foreach($key in $saved.Keys){[Environment]::SetEnvironmentVariable($key,$null,'Process')}
    try{$script:RootCount++;$record=[Warhammer.E02.Supervisor]::Run($exe,$Arguments,$script:Stage,(Child-Environment $Extra),$out,$err,$seconds,$false,$(if($Fault){$Fault}else{$null}))}
    finally{foreach($key in $saved.Keys){[Environment]::SetEnvironmentVariable($key,$saved[$key],'Process')}}
    $script:Result.processes.Add($record);$path=Join-Path $script:PhaseRoot "$Label.process.json";Write-JsonNew $path $record;$record['receiptArtifact']=Descriptor $path
    foreach($entry in @(@('stdoutArtifact',$out),@('stderrArtifact',$err))){if([IO.File]::Exists($entry[1])){if(([IO.FileInfo]::new($entry[1])).Length -gt 64MB){throw 'E04A1_RETAINED_STREAM_CAP_NO_TRUNCATION'};$record[$entry[0]]=Descriptor $entry[1];Safe-Text $script:Utf8.GetString([IO.File]::ReadAllBytes($entry[1]))}elseif($record['status'] -ceq 'PASS'){throw 'E04A1_SUCCESS_OUTPUT_MISSING'}}
    return ,$record
}
function Require-RootPass($Record) {
    if($Record['status'] -cne 'PASS' -or $Record['exitConfirmed'] -ne $true -or $Record['cleanupConfirmed'] -ne $true -or $Record['timedOut'] -or $Record['exitCode'] -ne 0){throw 'E04A1_ROOT_FAILED_OR_CLEANUP_UNVERIFIED'}
    $a=@($Record['jobAccounting']);if(-not $a.Count -or $a[-1].activeProcesses -ne 0){throw 'E04A1_FINAL_JOB_ZERO_UNVERIFIED'}
}
function Enable-NativeHelper {
    if($null -ne ('Warhammer.E02.Supervisor' -as [type])){throw 'E04A1_FRESH_POWERSHELL_PROCESS_REQUIRED'}
    Add-Type -TypeDefinition $script:NativeSource -Language CSharp -ErrorAction Stop
}


# Adapted E02 plugin closure helper; explicit E04A1 target and present project plugin root; source rows 1280-1300
function Catalog-Descriptors([string] $Root) {
    $rootPath=Assert-Path $Root
    if(-not [IO.Directory]::Exists($rootPath)){throw 'BLOCKED_E04A1_PLUGIN_CATALOG_ROOT_UNAVAILABLE'}
    $pending=[Collections.Generic.Stack[string]]::new();$pending.Push($rootPath)
    $found=[Collections.Generic.List[object]]::new()
    while($pending.Count){
        $dir=$pending.Pop()
        # Enumerate raw filesystem entries, including hidden/ignored descriptors.
        # Do not follow a junction or silently omit an unavailable directory.
        foreach($path in [IO.Directory]::EnumerateFileSystemEntries($dir)){
            $attributes=[IO.File]::GetAttributes($path)
            if(($attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw 'BLOCKED_E04A1_PLUGIN_DISCOVERY_REPARSE_PATH'}
            if(($attributes -band [IO.FileAttributes]::Directory) -ne 0){$pending.Push($path)}
            elseif([IO.Path]::GetExtension($path) -ieq '.uplugin'){
                $d=Descriptor $path
                $found.Add([ordered]@{relativePath=[IO.Path]::GetRelativePath($rootPath,$path).Replace('\','/');bytes=$d.bytes;sha256=$d.sha256})
            }
        }
    }
    return @($found|Sort-Object { $_.relativePath } -CaseSensitive)
}

# Adapted E02 plugin closure helper; explicit E04A1 target and present project plugin root; source rows 1301-1338
function Check-PluginDiscoveryCatalog($Closure) {
    $expectedRoots=@((Join-Path $EngineRoot 'Engine\Plugins'),(Join-Path $EngineRoot 'Engine\Platforms'))
    $roots=@($Closure.catalogRoots)
    if($roots.Count -ne 2){throw 'E04A1_PLUGIN_CATALOG_ROOT_SET'}
    $summaries=[Collections.Generic.List[object]]::new()
    foreach($path in $expectedRoots){
        $entry=@($roots|Where-Object {$_.path -ieq $path})
        if($entry.Count -ne 1){throw 'E04A1_PLUGIN_CATALOG_ROOT_MISSING_OR_DUPLICATED'}
        $actual=@(Catalog-Descriptors $path);$frozen=@($entry[0].descriptors|Sort-Object { $_.relativePath } -CaseSensitive)
        if($actual.Count -ne $frozen.Count){throw 'E04A1_PLUGIN_CATALOG_MEMBERSHIP_CHANGED'}
        for($i=0;$i -lt $actual.Count;$i++){
            if($frozen[$i].relativePath -isnot [string] -or $frozen[$i].sha256 -isnot [string] -or $frozen[$i].sha256 -cnotmatch '^[a-fA-F0-9]{64}$' -or
                ($frozen[$i].bytes -isnot [long] -and $frozen[$i].bytes -isnot [int]) -or $frozen[$i].bytes -lt 0){throw 'E04A1_PLUGIN_CATALOG_DESCRIPTOR_SHAPE'}
            if($actual[$i].relativePath -cne $frozen[$i].relativePath -or $actual[$i].bytes -ne $frozen[$i].bytes -or
                $actual[$i].sha256 -ine $frozen[$i].sha256){throw 'E04A1_PLUGIN_CATALOG_MEMBERSHIP_OR_BYTES_CHANGED'}
        }
        $summaries.Add(@{path=$path;descriptorCount=$actual.Count;observedUtc=[DateTime]::UtcNow.ToString('o');membershipAndBytes='MATCH_FROZEN_CATALOG'})
    }
    $projectCatalogs=@(foreach($root in @($script:Repo,$script:Stage)){Check-ProjectPluginMembership $script:Freeze.projectPluginMembership $root})
    $absent=@((Join-Path $EngineRoot 'Engine\Restricted'),(Join-Path $EngineRoot 'Enterprise\Plugins'))
    foreach($base in @($script:Repo,$script:Stage)){foreach($leaf in @('Mods','Platforms','Restricted')){$absent+=Join-Path $base $leaf}}
    $required=@($Closure.requiredAbsentPaths)
    if($required.Count -ne $absent.Count){throw 'E04A1_PLUGIN_EXTRA_ROOT_ABSENCE_SET'}
    $observations=[Collections.Generic.List[object]]::new()
    foreach($path in $absent){
        if(@($required|Where-Object {$_ -is [string] -and $_ -ieq $path}).Count -ne 1){throw 'E04A1_PLUGIN_EXTRA_ROOT_ABSENCE_MISSING_OR_DUPLICATED'}
        $knownAbsent=$false
        try{[void][IO.File]::GetAttributes($path)}
        catch [IO.FileNotFoundException]{$knownAbsent=$true}
        catch [IO.DirectoryNotFoundException]{$knownAbsent=$true}
        if(-not $knownAbsent){throw 'BLOCKED_E04A1_EXTRA_PLUGIN_DISCOVERY_PATH_PRESENT'}
        $observations.Add(@{path=$path;exists=$false;inspection='PASS';observedUtc=[DateTime]::UtcNow.ToString('o')})
    }
    if(@($Closure.emptyEnvironmentVariables).Count -ne 2 -or $Closure.emptyEnvironmentVariables[0] -cne 'UE_ADDITIONAL_PLUGIN_PATHS' -or $Closure.emptyEnvironmentVariables[1] -cne 'UE-CmdLineArgs'){throw 'E04A1_PLUGIN_DISCOVERY_ENVIRONMENT_CONTRACT'}
    return @{catalogRoots=@($summaries);projectPluginCatalogs=$projectCatalogs;requiredAbsences=@($observations);subprocessEnvironmentOverrides=@{UE_ADDITIONAL_PLUGIN_PATHS='';'UE-CmdLineArgs'=''};
        parentAdditionalPluginPathsNonempty=(-not [string]::IsNullOrEmpty([Environment]::GetEnvironmentVariable('UE_ADDITIONAL_PLUGIN_PATHS')));
        parentEngineCommandLineNonempty=(-not [string]::IsNullOrEmpty([Environment]::GetEnvironmentVariable('UE-CmdLineArgs')));
        limits='Raw frozen descriptor superset and explicit discovery-root observations; not a universal plugin/dependency analyzer or whole-process network-isolation proof.'}
}

# Adapted E02 plugin closure helper; explicit E04A1 target and present project plugin root; source rows 1339-1347
function Resolve-ReceiptPath([string] $Value,[string] $Directory,[switch] $EngineToken) {
    if([string]::IsNullOrWhiteSpace($Value)){throw 'E04A1_TARGET_RECEIPT_PATH_MISSING'}
    if($Value.Contains('$(')){
        if(-not $EngineToken -or -not $Value.StartsWith('$(EngineDir)/',[StringComparison]::Ordinal) -or $Value.Substring(13).Contains('$(')){throw 'E04A1_TARGET_RECEIPT_UNSUPPORTED_PATH_TOKEN'}
        $Value=Join-Path (Join-Path $EngineRoot 'Engine') $Value.Substring(13)
    }
    if(-not [IO.Path]::IsPathFullyQualified($Value)){$Value=Join-Path $Directory $Value}
    return Assert-Path ([IO.Path]::GetFullPath($Value))
}

# Adapted E02 plugin closure helper; explicit E04A1 target and present project plugin root; source rows 1348-1387
function Check-TargetReceipt($Closure) {
    $policy=$Closure.targetReceiptPolicy
    if($policy.relativePath -cne 'Binaries/Win64/WarhammerClientE04AEditor.target' -or $policy.allowEnginePluginsEnabledByDefault -isnot [bool]){throw 'E04A1_TARGET_RECEIPT_POLICY_SHAPE'}
    $receiptPath=Under (Join-Path $script:Stage $policy.relativePath) $script:Stage
    $receiptDirectory=[IO.Path]::GetDirectoryName($receiptPath)
    $receipts=@(Get-ChildItem -LiteralPath $receiptDirectory -Force -Filter '*.target' -File)
    if($receipts.Count -ne 1 -or $receipts[0].FullName -ine $receiptPath){throw 'BLOCKED_E04A1_AMBIGUOUS_OR_MISSING_STAGED_TARGET_RECEIPT'}
    $receipt=Read-Json $receiptPath
    if($receipt.TargetName -cne 'WarhammerClientE04AEditor' -or $receipt.TargetType -cne 'Editor' -or $receipt.Platform -cne 'Win64' -or
        $receipt.Configuration -cne 'Development'){throw 'E04A1_TARGET_RECEIPT_IDENTITY'}
    if((Resolve-ReceiptPath $receipt.Project $receiptDirectory) -ine (Join-Path $script:Stage 'WarhammerClient.uproject') -or
        (Resolve-ReceiptPath $receipt.Launch $receiptDirectory -EngineToken) -ine $script:Freeze.toolPaths.editor -or
        (Resolve-ReceiptPath $receipt.LaunchCmd $receiptDirectory -EngineToken) -ine $script:Freeze.toolPaths.editorCmd){throw 'E04A1_TARGET_RECEIPT_PROJECT_OR_LAUNCH_MISMATCH'}
    $plugins=@();if($receipt.Contains('Plugins')){$plugins=@($receipt.Plugins)}
    $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach($item in $plugins){
        if($item -isnot [Collections.IDictionary] -or $item.Name -isnot [string] -or [string]::IsNullOrWhiteSpace($item.Name) -or
            $item.Enabled -isnot [bool] -or -not $seen.Add($item.Name)){throw 'E04A1_TARGET_RECEIPT_PLUGIN_OVERRIDE_SHAPE'}
        if($item.Enabled -and $item.Name -iin $script:Disabled){throw 'BLOCKED_E04A1_TARGET_RECEIPT_FORBIDDEN_PLUGIN_ENABLE'}
    }
    $expected=@($policy.pluginOverrides|Sort-Object { $_.Name } -CaseSensitive);$actual=@($plugins|Sort-Object { $_.Name } -CaseSensitive)
    if($expected.Count -ne $actual.Count){throw 'E04A1_TARGET_RECEIPT_PLUGIN_OVERRIDES_CHANGED'}
    for($i=0;$i -lt $actual.Count;$i++){
        if($expected[$i].Enabled -isnot [bool] -or $expected[$i].Name -cne $actual[$i].Name -or $expected[$i].Enabled -cne $actual[$i].Enabled){throw 'E04A1_TARGET_RECEIPT_PLUGIN_OVERRIDES_CHANGED'}
        if($actual[$i].Enabled -and $actual[$i].Name -cnotin @($Closure.enabledPlugins)){throw 'E04A1_TARGET_RECEIPT_ENABLE_OUTSIDE_REVIEWED_CLOSURE'}
    }
    $defaults=$true;$properties=@()
    if($receipt.Contains('AdditionalProperties')){$properties=@($receipt.AdditionalProperties|Where-Object {$_.Name -ceq 'bAllowEnginePluginsEnabledByDefault'})}
    if($properties.Count -gt 1){throw 'E04A1_TARGET_RECEIPT_DUPLICATE_DEFAULT_PROPERTY'}
    if($properties.Count){
        if($properties[0].Value -isnot [string] -or $properties[0].Value -notin @('true','false')){throw 'E04A1_TARGET_RECEIPT_DEFAULT_PROPERTY_SHAPE'}
        $defaults=$properties[0].Value -ieq 'true'
    }
    if($defaults -cne $policy.allowEnginePluginsEnabledByDefault){throw 'E04A1_TARGET_RECEIPT_DEFAULT_POLICY_CHANGED'}
    $buildPlugins=@();if($receipt.Contains('BuildPlugins')){$buildPlugins=@($receipt.BuildPlugins)}
    foreach($name in $buildPlugins){if($name -isnot [string] -or [string]::IsNullOrWhiteSpace($name)){throw 'E04A1_TARGET_RECEIPT_BUILD_ALLOWLIST_SHAPE'}}
    return @{artifact=Descriptor $receiptPath;targetName=$receipt.TargetName;platform=$receipt.Platform;configuration=$receipt.Configuration;pluginOverrides=$plugins;
        allowEnginePluginsEnabledByDefault=$defaults;buildPlugins=$buildPlugins;buildPluginsMeaning='OPTIONAL_ALLOWLIST_NOT_RUNTIME_ENABLE_ROOTS';
        limits='Actual staged receipt checked against reviewed policy. Source selection/receipt support and actual startup diagnostics remain separate evidence.'}
}

# Adapted E02 plugin closure helper; explicit E04A1 target and present project plugin root; source rows 1388-1425
function Check-StagedPluginClosure([switch] $RequireTargetReceipt) {
    $project=Read-Json (Join-Path $script:Stage 'WarhammerClient.uproject')
    $allowedFields=@('FileVersion','EngineAssociation','Category','Description','Modules','Plugins')
    foreach($key in $project.Keys){if($key -cnotin $allowedFields){throw 'BLOCKED_E04A1_UNREVIEWED_PROJECT_PLUGIN_DISCOVERY_FIELD'}}
    foreach($plugin in $project.Plugins) {
        if ($plugin.Name -cin $script:Disabled -and $plugin.Enabled -eq $true) { throw 'E04A1_FORBIDDEN_PLUGIN_EXPLICITLY_ENABLED' }
    }
    $procedural=@($project.Plugins | Where-Object { $_.Name -ceq 'ProceduralMeshComponent' -and $_.Enabled -eq $true })
    if ($procedural.Count -ne 1) { throw 'E04A1_PROCEDURAL_MESH_PLUGIN_REFERENCE_MISSING' }
    $closureDescriptor=Check-Descriptor $script:Freeze.pluginClosure
    $closure=Read-Json $closureDescriptor.path
    if($closure.schemaVersion -ne 1 -or $closure.sourceHead -cne $script:Freeze.sourceHead -or $closure.platform -cne 'Win64' -or
        @($closure.targets).Count -ne 1 -or $closure.targets[0] -cne 'WarhammerClientE04AEditor'){throw 'E04A1_REVIEWED_PLUGIN_CLOSURE_SCOPE'}
    if($closure.targetReceiptPolicy.relativePath -cne 'Binaries/Win64/WarhammerClientE04AEditor.target' -or
        $closure.targetReceiptPolicy.allowEnginePluginsEnabledByDefault -isnot [bool] -or $closure.targetReceiptPolicy.pluginOverrides -isnot [Collections.IList]){throw 'E04A1_TARGET_RECEIPT_POLICY_SHAPE'}
    $canonicalProject=Check-Descriptor $closure.project
    if($canonicalProject.path -ine (Join-Path $script:Repo 'WarhammerClient.uproject') -or $canonicalProject.sha256 -cne (Digest (Join-Path $script:Stage 'WarhammerClient.uproject'))){throw 'E04A1_PLUGIN_CLOSURE_PROJECT_MISMATCH'}
    if((@($closure.disabledPlugins|Sort-Object -CaseSensitive)-join ',') -cne (@($script:Disabled|Sort-Object -CaseSensitive)-join ',')){throw 'E04A1_PLUGIN_CLOSURE_DISABLED_SET'}
    $enabled=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach($name in $closure.enabledPlugins){
        if($name -isnot [string] -or [string]::IsNullOrWhiteSpace($name) -or -not $enabled.Add($name) -or $name -iin $script:Disabled){throw 'E04A1_PLUGIN_CLOSURE_FORBIDDEN_OR_DUPLICATE_NAME'}
    }
    if(-not $enabled.Contains('E04ProfileProof') -or -not $enabled.Contains('ProceduralMeshComponent')){throw 'E04A1_PLUGIN_CLOSURE_PROCEDURAL_MESH_MISSING'}
    $described=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $seenPaths=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach($d in $closure.descriptors){
        $actual=Check-Descriptor $d
        if([IO.Path]::GetExtension($actual.path) -cne '.uplugin' -or -not $seenPaths.Add($actual.path)){throw 'E04A1_PLUGIN_CLOSURE_DESCRIPTOR_KIND_OR_DUPLICATE'}
        if(@($script:Freeze.files|Where-Object {$_.path -ieq $actual.path -and $_.sha256 -ieq $actual.sha256 -and $_.bytes -eq $actual.bytes}).Count -ne 1){throw 'E04A1_PLUGIN_CLOSURE_DESCRIPTOR_NOT_FROZEN'}
        [void]$described.Add([IO.Path]::GetFileNameWithoutExtension($actual.path))
    }
    foreach($name in $enabled){if(-not $described.Contains($name)){throw 'E04A1_ENABLED_PLUGIN_WITHOUT_FROZEN_DESCRIPTOR'}}
    $catalog=Check-PluginDiscoveryCatalog $closure
    $targetReceipt=$null;if($RequireTargetReceipt){$targetReceipt=Check-TargetReceipt $closure}
    $script:Result.pluginClosure=@{artifact=$closureDescriptor;project=$canonicalProject;enabledNames=@($enabled|Sort-Object -CaseSensitive);descriptorCount=$seenPaths.Count;
        discoveryCatalog=$catalog;targetReceipt=$targetReceipt;
        status='REVIEWED_CLOSURE_BINDING_CHECKED';limits='Completeness is an explicit independent source-review prerequisite. This is not a universal dependency analyzer or runtime network-isolation proof.'}
}
function Windows-Contract {
    $w=$script:Freeze.windows
    if($w.compilerName -cne 'VisualStudio2022' -or $w.toolChainName -cne 'VisualStudio2022' -or $w.compilerVersion -cne '14.44.35229' -or $w.toolChainVersion -cne '14.44.35229' -or $w.sdkVersion -cne '10.0.22621.0' -or $w.compilerDir -ine $w.toolChainDir){throw 'E04A1_REVIEWED_WINDOWS_SELECTION_MISMATCH'}
    foreach($e in @(@('compiler',(Join-Path $w.compilerDir 'bin/Hostx64/x64/cl.exe')),@('linker',(Join-Path $w.toolChainDir 'bin/Hostx64/x64/link.exe')),@('librarian',(Join-Path $w.toolChainDir 'bin/Hostx64/x64/lib.exe')),@('sdkRc',(Join-Path $w.sdkDir ('bin/'+$w.sdkVersion+'/x64/rc.exe'))))){if($script:Freeze.toolPaths[$e[0]] -ine (Assert-Path $e[1])){throw 'E04A1_FROZEN_TOOL_NOT_SELECTED_PATH'}}
    return $w
}
function Build-Root {return Owned 'vendor-build/Win64/Development/x64'}
function Artifact-Root {return Owned 'vendor-artifact/Win64/Development/x64'}
# CMake listfiles quote these values; native backslashes can become escapes such as \P.
function CMake-Path([string]$Path) {return $Path.Replace('\','/')}
function CMake-Options {
    return @('-G','Ninja',('-DCMAKE_MAKE_PROGRAM='+(CMake-Path $script:Freeze.toolPaths.ninja)),('-DCMAKE_CXX_COMPILER='+(CMake-Path $script:Freeze.toolPaths.compiler)),('-DCMAKE_LINKER='+(CMake-Path $script:Freeze.toolPaths.linker)),('-DCMAKE_AR='+(CMake-Path $script:Freeze.toolPaths.librarian)),('-DCMAKE_RC_COMPILER='+(CMake-Path $script:Freeze.toolPaths.sdkRc)),
        '-DCMAKE_BUILD_TYPE=Release','-DCMAKE_CXX_STANDARD=20','-DCMAKE_CXX_STANDARD_REQUIRED=ON','-DCMAKE_CXX_EXTENSIONS=OFF','-DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreadedDLL','-DCMAKE_CXX_FLAGS=/EHsc /GR-','-DCMAKE_EXPORT_COMPILE_COMMANDS=ON',
        '-DYAML_BUILD_SHARED_LIBS=OFF','-DYAML_CPP_BUILD_TESTS=OFF','-DYAML_CPP_BUILD_TOOLS=OFF','-DYAML_CPP_BUILD_CONTRIB=OFF','-DYAML_CPP_INSTALL=OFF','-DYAML_CPP_FORMAT_SOURCE=OFF','-DBUILD_TESTING=OFF','-DYAML_CPP_DISABLE_UNINSTALL=ON','-DYAML_ENABLE_PIC=ON','-DYAML_MSVC_SHARED_RT=ON')
}
function Check-CMake {
    $root=Build-Root;$cache=Need-File (Join-Path $root 'CMakeCache.txt');$text=$script:Utf8.GetString([IO.File]::ReadAllBytes($cache));Safe-Text $text
    $expected=@{CMAKE_BUILD_TYPE='Release';CMAKE_CXX_STANDARD='20';CMAKE_CXX_STANDARD_REQUIRED='ON';CMAKE_CXX_EXTENSIONS='OFF';CMAKE_MSVC_RUNTIME_LIBRARY='MultiThreadedDLL';CMAKE_EXPORT_COMPILE_COMMANDS='ON';YAML_BUILD_SHARED_LIBS='OFF';YAML_CPP_BUILD_TESTS='OFF';YAML_CPP_BUILD_TOOLS='OFF';YAML_CPP_BUILD_CONTRIB='OFF';YAML_CPP_INSTALL='OFF';YAML_CPP_FORMAT_SOURCE='OFF';BUILD_TESTING='OFF';YAML_CPP_DISABLE_UNINSTALL='ON';YAML_ENABLE_PIC='ON';YAML_MSVC_SHARED_RT='ON'}
    foreach($e in $expected.GetEnumerator()){$m=[regex]::Matches($text,('(?m)^'+[regex]::Escape($e.Key)+':[^=]+=([^\r\n]*)\r?$'));if($m.Count -ne 1 -or $m[0].Groups[1].Value -cne $e.Value){throw ('E04A1_CMAKE_CACHE_OPTION_MISMATCH: '+$e.Key)}}
    foreach($e in @(@('CMAKE_CXX_COMPILER',$script:Freeze.toolPaths.compiler),@('CMAKE_MAKE_PROGRAM',$script:Freeze.toolPaths.ninja),@('CMAKE_AR',$script:Freeze.toolPaths.librarian),@('CMAKE_LINKER',$script:Freeze.toolPaths.linker),@('CMAKE_RC_COMPILER',$script:Freeze.toolPaths.sdkRc),@('CMAKE_HOME_DIRECTORY',$script:VendorRoot))){$m=[regex]::Matches($text,('(?m)^'+$e[0]+':[^=]+=([^\r\n]*)\r?$'));if($m.Count -ne 1 -or (Assert-Path $m[0].Groups[1].Value) -ine (Assert-Path $e[1])){throw ('E04A1_CMAKE_SELECTED_PATH_MISMATCH: '+$e[0])}}
    $commandsPath=Join-Path $root 'compile_commands.json';$commands=@(Read-Json $commandsPath)
    $expectedSources=@($script:Dependency.files|Where-Object {$_.path -cmatch '^src/[^/]+\.cpp$'}|ForEach-Object {Assert-Path (Join-Path $script:VendorRoot $_.path)}|Sort-Object -CaseSensitive)
    $actual=[Collections.Generic.List[string]]::new();$flags=[Collections.Generic.List[object]]::new()
    foreach($c in $commands){$file=Assert-Path $c.file;if($file -cin $actual){throw 'E04A1_DUPLICATE_VENDOR_COMPILE_COMMAND'};$actual.Add($file)
        if((Assert-Path $c.directory) -ine $root -or $c.command -isnot [string]){throw 'E04A1_VENDOR_COMMAND_SHAPE_OR_DIRECTORY'}
        $cmd=[string]$c.command;Safe-Text $cmd;$compiler=CMake-Path $script:Freeze.toolPaths.compiler;$commandPathView=$cmd.Replace('\','/')
        if(-not ($commandPathView.StartsWith(('"'+$compiler+'" '),[StringComparison]::OrdinalIgnoreCase) -or $commandPathView.StartsWith(($compiler+' '),[StringComparison]::OrdinalIgnoreCase)) -or $cmd -notmatch '(?i)(?:^|\s)[/-]MD(?:\s|$)' -or $cmd -match '(?i)(?:^|\s)[/-](?:MDd|MTd?)(?:\s|$)' -or $cmd -notmatch '(?i)(?:^|\s)[/-]std:c\+\+20(?:\s|$)' -or $cmd -notmatch '(?i)(?:^|\s)/EHsc(?:\s|$)' -or $cmd -notmatch '(?i)(?:^|\s)/GR-(?:\s|$)' -or $cmd -notmatch '(?:-D|/D)YAML_CPP_STATIC_DEFINE(?:=1)?(?:\s|$)'){throw 'E04A1_VENDOR_ACTUAL_COMPILE_FLAGS_MISMATCH'}
        $flags.Add(@{file=$file;command=$cmd;observedRuntime='MD';observedStandard='C++20';observedExceptions='EHsc';observedRtti='GR-';staticDefineObserved=$true})
    }
    if(-not $expectedSources.Count -or (@($actual|Sort-Object -CaseSensitive)-join "`n") -cne ($expectedSources -join "`n")){throw 'E04A1_VENDOR_COMPILE_SOURCE_MEMBERSHIP_MISMATCH'}
    $ninja=Need-File (Join-Path $root 'build.ninja');$ninjaText=$script:Utf8.GetString([IO.File]::ReadAllBytes($ninja))
    if($ninjaText -notmatch '(?m)^build yaml-cpp\.lib: CXX_STATIC_LIBRARY_LINKER__yaml-cpp_Release\b' -or $ninjaText -match '(?m)^build (?:install|uninstall|format):'){throw 'E04A1_NINJA_STATIC_TARGET_OR_FORBIDDEN_TARGET'}
    return @{cache=Descriptor $cache;compileCommands=Descriptor $commandsPath;ninja=Descriptor $ninja;sourceCount=$actual.Count;actualCommandData=@($flags);qualification='Literal generated command/flag observations, never executed as evidence text. Actual supervised build/process evidence remains separate.'}
}
function Publish-VendorArtifact($Process) {
    $root=Build-Root;$lib=Need-File (Join-Path $root 'yaml-cpp.lib');$libDescriptor=Descriptor $lib
    if($libDescriptor.bytes -le 8 -or $libDescriptor.bytes -gt 64MB){throw 'E04A1_VENDOR_STATIC_LIBRARY_SIZE'}
    $stream=[IO.File]::OpenRead($lib);try{$magic=[byte[]]::new(8);if($stream.Read($magic,0,8) -ne 8 -or [Text.Encoding]::ASCII.GetString($magic) -cne "!<arch>`n"){throw 'E04A1_STATIC_ARCHIVE_MAGIC_MISSING'}}finally{$stream.Dispose()}
    $cmake=Check-CMake;$w=Windows-Contract;$tree=@($script:Dependency.trees|Where-Object {$_.path -ceq ''});if($tree.Count -ne 1){throw 'E04A1_ROOT_TREE_NOT_UNIQUE'}
    $licenseEntry=@($script:Dependency.files|Where-Object {$_.path -ceq 'LICENSE'});$sourceLicense=Descriptor (Join-Path $script:VendorRoot 'LICENSE')
    if($licenseEntry.Count -ne 1 -or $sourceLicense.bytes -ne 1061 -or $sourceLicense.sha256 -ine 'AA6FCC27BE034E41E21DD832F9175BFE694A48491D9E14FF0FA278E19AD14F1B' -or $licenseEntry[0].bytes -ne $sourceLicense.bytes -or $licenseEntry[0].sha256 -ine $sourceLicense.sha256 -or @($script:Freeze.files|Where-Object {$_.path -ieq $sourceLicense.path -and $_.bytes -eq $sourceLicense.bytes -and $_.sha256 -ieq $sourceLicense.sha256}).Count -ne 1){throw 'E04A1E_PINNED_MIT_LICENSE_IDENTITY_OR_FREEZE_MISMATCH'}
    $tools=@{compiler=Descriptor $script:Freeze.toolPaths.compiler;linker=Descriptor $script:Freeze.toolPaths.linker;librarian=Descriptor $script:Freeze.toolPaths.librarian;resourceCompiler=Descriptor $script:Freeze.toolPaths.sdkRc}
    $identity=@{schemaVersion=1;subset=$script:Subset;runtimeCallerProof=$script:RuntimeCallerProof;runId=$RunId;sourceHead=$script:Freeze.sourceHead;sourceRoot=$script:Repo;stagedProject=(Join-Path $script:Stage 'WarhammerClient.uproject');vendorPin=$script:Dependency.pin;sourceTreeOid=$tree[0].treeOid}
    $b=@{};foreach($e in $identity.GetEnumerator()){$b[$e.Key]=$e.Value};$b.kind='E04A1_VENDOR_CMAKE_BUILD_RECEIPT';$b.status='COMPLETED_SUCCESS';$b.vendorSourceRoot=$script:VendorRoot;$b.acquisitionResultSha256=$script:AcquisitionDescriptor.sha256;$b.configuration='Release';$b.platform='Win64';$b.architecture='x64';$b.cppStandard='C++20';$b.runtime='MD';$b.linkage='static';$b.exceptionsEnabled=$true;$b.installTargetInvoked=$false;$b.library=$libDescriptor;$b.compiler=$tools.compiler;$b.process=$Process.receiptArtifact;$b.actualGeneratedCommands=$cmake;$b.qualification='Producer receipt bound to supervised build and generated commands, not independent artifact lineage approval.'
    $b.sourceLicense=$sourceLicense;Write-JsonNew (Owned 'logs/vendor-cmake-build.json') $b
    $artifact=Artifact-Root;New-Directory $artifact;[void][IO.Directory]::CreateDirectory((Join-Path $artifact 'include'));[void][IO.Directory]::CreateDirectory((Join-Path $artifact 'lib'))
    $licensePath=Under (Join-Path $artifact 'LICENSE.yaml-cpp') $artifact
    [IO.File]::Copy($sourceLicense.path,$licensePath,$false);$license=Descriptor $licensePath
    if($license.bytes -ne $sourceLicense.bytes -or $license.sha256 -ine $sourceLicense.sha256){throw 'E04A1E_MIT_NOTICE_RAW_COPY_MISMATCH'}
    $headers=[Collections.Generic.List[object]]::new()
    foreach($e in $script:Dependency.files|Where-Object {$_.path.StartsWith('include/',[StringComparison]::Ordinal)}){
        $src=Under (Join-Path $script:VendorRoot $e.path) $script:VendorRoot;$d=Descriptor $src;if($d.bytes -ne $e.bytes -or $d.sha256 -ine $e.sha256){throw 'E04A1_SOURCE_HEADER_CHANGED_BEFORE_COPY'}
        $relative=$e.path.Substring(8);$dst=Under (Join-Path (Join-Path $artifact 'include') $relative) $artifact;[void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($dst));[IO.File]::Copy($src,$dst,$false);$copy=Descriptor $dst
        if($copy.bytes -ne $d.bytes -or $copy.sha256 -ine $d.sha256){throw 'E04A1_HEADER_COPY_CHANGED'};$headers.Add(@{relativePath=$relative;bytes=$copy.bytes;sha256=$copy.sha256})
    }
    $dstLib=Join-Path $artifact 'lib/yaml-cpp.lib';[IO.File]::Copy($lib,$dstLib,$false);$copiedLib=Descriptor $dstLib;if($copiedLib.sha256 -ine $libDescriptor.sha256 -or $copiedLib.bytes -ne $libDescriptor.bytes){throw 'E04A1_LIBRARY_COPY_CHANGED'}
    $r=@{};foreach($e in $identity.GetEnumerator()){$r[$e.Key]=$e.Value};$r.kind='E04A1_VENDOR_ARTIFACT_RECEIPT';$r.sourcePreparationId=$script:Freeze.dependency.preparationId;$r.acquisitionResult=$script:AcquisitionDescriptor;$r.vendorBuildReceipt=Descriptor (Owned 'logs/vendor-cmake-build.json');$r.artifactRoot=$artifact;$r.includeRoot=Join-Path $artifact 'include';$r.library=$copiedLib;$r.headers=@($headers);$r.windows=$w;$r.tools=$tools;$r.abi=@{target='WarhammerClientE04AEditor';platform='Win64';architecture='x64';configuration='Development';cppStandard='C++20';runtime='MD';linkage='static';staticDefine='YAML_CPP_STATIC_DEFINE';exceptionsEnabled=$true}
    $r.sourceLicense=$sourceLicense;$r.license=$license;Write-JsonNew (Owned 'logs/yaml-artifact-receipt.json') $r
    return @{library=$copiedLib;builtLibrary=$libDescriptor;headerCount=$headers.Count;sourceLicense=$sourceLicense;license=$license;artifactReceipt=Descriptor (Owned 'logs/yaml-artifact-receipt.json');buildReceipt=Descriptor (Owned 'logs/vendor-cmake-build.json');generatedCommandEvidence=$cmake;installTargetInvoked=$false}
}
function Editor-Build {
    foreach($relative in @('Binaries','Intermediate','Plugins/E04ProfileProof/Binaries','Plugins/E04ProfileProof/Intermediate')){if(Test-Path -LiteralPath (Join-Path $script:Stage $relative)){throw 'E04A1_EDITOR_BUILD_REQUIRES_FRESH_STAGED_NATIVE_OUTPUTS'}}
    foreach($relative in @('logs/yaml-module-selection.json','logs/build-dotnet-path.txt','logs/build-dotnet-sdk.txt','logs/build.log')){if(Test-Path -LiteralPath (Owned $relative)){throw 'E04A1_EDITOR_BUILD_EVIDENCE_ALREADY_EXISTS'}}
    $receipt=Descriptor (Owned 'logs/yaml-artifact-receipt.json');$pathReceipt=Owned 'logs/build-dotnet-path.txt';$sdkReceipt=Owned 'logs/build-dotnet-sdk.txt'
    $extra=@{E04A1_NATIVE_BOUNDARY_REQUIRED='1';E04A1_RUN_ID=$RunId;E04A1_SOURCE_HEAD=$script:Freeze.sourceHead;E04A1_SOURCE_ROOT=$script:Repo;E04A1_STAGED_PROJECT=(Join-Path $script:Stage 'WarhammerClient.uproject');E04A1_ARTIFACT_RECEIPT=$receipt.path;E04A1_ARTIFACT_RECEIPT_SHA256=$receipt.sha256;
        E04A1_BUILD_BAT=$script:Freeze.toolPaths.buildBat;E04A1_CMD=$script:Freeze.toolPaths.cmd;E04A1_WHERE=$script:Freeze.toolPaths.where;E04A1_GET_DOTNET_BAT=$script:Freeze.toolPaths.getDotnetPath;E04A1_ENGINE_SOURCE=(Join-Path $EngineRoot 'Engine/Source');E04A1_DOTNET_EXE=$script:Freeze.toolPaths.dotnet;E04A1_DOTNET_VERSION=$script:Freeze.dotnetSdk.version;E04A1_DOTNET_WHERE_LOG=$pathReceipt;E04A1_DOTNET_SDK_LOG=$sdkReceipt;E04A1_UBA=(Owned 'uba');E04A1_BUILD_LOG=(Owned 'logs/build.log')}
    foreach($v in $extra.Values){if($v -match '[%!^&|<>\r\n\x00]'){throw 'E04A1_AMBIGUOUS_BUILD_BATCH_VALUE'}}
    $worker=@'
$ErrorActionPreference='Stop'
$batch=@(
 'cd /d "%E04A1_ENGINE_SOURCE%"',
 'call "%E04A1_GET_DOTNET_BAT%"',
 '"%E04A1_WHERE%" dotnet >"%E04A1_DOTNET_WHERE_LOG%"',
 'set "E04A1_SELECTED_DOTNET="',
 'set /p E04A1_SELECTED_DOTNET=<"%E04A1_DOTNET_WHERE_LOG%"',
 '(for %I in ("!E04A1_SELECTED_DOTNET!") do @set "E04A1_SELECTED_DOTNET=%~fI")',
 '(if /i not "!E04A1_SELECTED_DOTNET!"=="%E04A1_DOTNET_EXE%" (exit /b 97))',
 'dotnet --version >"%E04A1_DOTNET_SDK_LOG%"',
 'set "E04A1_SELECTED_SDK="',
 'set /p E04A1_SELECTED_SDK=<"%E04A1_DOTNET_SDK_LOG%"',
 '(if not "!E04A1_SELECTED_SDK!"=="%E04A1_DOTNET_VERSION%" (exit /b 98))',
 'call "%E04A1_BUILD_BAT%" WarhammerClientE04AEditor Win64 Development "-Project=%E04A1_STAGED_PROJECT%" -WaitMutex -NoUBA -NoVFS -Compiler=VisualStudio2022 -CompilerVersion=14.44.35229 -WindowsSDKVersion=10.0.22621.0 "-UBARootDir=%E04A1_UBA%" "-Log=%E04A1_BUILD_LOG%"'
) -join ' && '
& $env:E04A1_CMD /d /v:on /s /c $batch
if($null -eq $LASTEXITCODE){exit 99};exit $LASTEXITCODE
'@
    $p=Invoke-Root 'editor-build' ([Environment]::ProcessPath) @('-NoProfile','-NonInteractive','-Command',$worker) 1800 $false '' $extra;Require-RootPass $p
    $resolved=[IO.File]::ReadAllLines((Need-File $pathReceipt));$sdk=[IO.File]::ReadAllLines((Need-File $sdkReceipt));if(-not $resolved.Count -or (Assert-Path $resolved[0]) -ine $script:Freeze.toolPaths.dotnet -or $sdk.Count -ne 1 -or $sdk[0] -cne $script:Freeze.dotnetSdk.version){throw 'E04A1_ACTUAL_DOTNET_SELECTION_MISMATCH'}
    $log=Need-File (Owned 'logs/build.log');$text=$script:Utf8.GetString([IO.File]::ReadAllBytes($log));Safe-Text $text
    if($text -notmatch '(?m)^Result: Succeeded\s*$' -or $text -notmatch '14\.44\.35229' -or $text -notmatch '10\.0\.22621\.0' -or $text -match '(?im)\b(?:Win32_Process\.Create|external process broker|using (?:XGE|FASTBuild|Incredibuild|remote executor))\b'){throw 'E04A1_EDITOR_BUILD_RESULT_OR_EXECUTOR_MISMATCH'}
    $selection=Read-Json (Owned 'logs/yaml-module-selection.json')
    if($selection.kind -cne 'E04A1_YAML_MODULE_SELECTION' -or $selection.runId -cne $RunId -or $selection.sourceHead -cne $script:Freeze.sourceHead -or $selection.target -cne 'WarhammerClientE04AEditor' -or $selection.fileReadLocksHeldThroughUbtExit -ne $true -or $selection.artifactReceipt.sha256 -ine $receipt.sha256){throw 'E04A1_ACTUAL_MODULE_SELECTION_MISMATCH'}
    foreach($key in @('artifactReceipt','acquisitionResult','vendorBuildReceipt')){[void](Check-Descriptor $selection[$key])}
    Check-StagedPluginClosure -RequireTargetReceipt
    return @{log=Descriptor $log;process=$p.receiptArtifact;selection=Descriptor (Owned 'logs/yaml-module-selection.json');dotnetPath=Descriptor $pathReceipt;dotnetSdk=Descriptor $sdkReceipt;nativeFlags=Check-EditorFlags;targetReceipt=$script:Result.pluginClosure.targetReceipt.artifact;packaging='NOT_RUN'}
}
function Response-Chain([string]$Path) {
    # Literal data only. UBT emits @shared.rsp (VCToolChain.cs:258-261,3184-3204).
    # Resolve no shell syntax, environment variables, response macros or relative paths.
    $queue=[Collections.Generic.Queue[object]]::new();$queue.Enqueue(@{path=(Under $Path $script:Stage);parents=@()})
    $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase);$parts=[Collections.Generic.List[object]]::new()
    while($queue.Count){$next=$queue.Dequeue();$p=Need-File $next.path
        if($p -iin @($next.parents)){throw 'E04A1_RESPONSE_CYCLE'};if(-not $seen.Add($p)){continue}
        if([IO.Path]::GetExtension($p) -ine '.rsp' -or ([IO.FileInfo]::new($p)).Length -gt 64MB){throw 'E04A1_RESPONSE_KIND_OR_SIZE'}
        $text=$script:Utf8.GetString([IO.File]::ReadAllBytes($p));Safe-Text $text;if($text.Contains([char]0)){throw 'E04A1_RESPONSE_NUL'}
        $references=@([regex]::Matches($text,'(?m)^\s*@(?:"(?<path>[^"\r\n]+)"|(?<path>[^\s"\r\n]+))\s*$'))
        if(@([regex]::Matches($text,'(?m)^\s*@')).Count -ne $references.Count){throw 'E04A1_UNSUPPORTED_RESPONSE_REFERENCE_SYNTAX'}
        foreach($reference in $references){$q=Under $reference.Groups['path'].Value $script:Stage;$queue.Enqueue(@{path=$q;parents=@($next.parents)+@($p)})}
        $parts.Add(@{file=Descriptor $p;text=$text})
    }
    return @{files=@($parts);text=(@($parts|ForEach-Object {$_.text})-join "`n")}
}
function Forced-DefinitionHeaders([string]$Text,[string]$Module) {
    # UEBuildModuleCPP.cs:2322-2340 writes definitions then inserts /FI;
    # VCToolChain.cs:306-309 emits the quoted header argument. Only generated,
    # module-scoped Definitions*.h contribute definition claims; other FI headers
    # are retained as identities, not recursively treated as a C++ preprocessor.
    $headers=[Collections.Generic.List[object]]::new();$definitions=[Collections.Generic.List[string]]::new();$seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $matches=@([regex]::Matches($Text,'(?im)^\s*/FI"(?<path>[^"\r\n]+)"\s*$'))
    if(@([regex]::Matches($Text,'(?im)^\s*/FI')).Count -ne $matches.Count){throw 'E04A1_UNSUPPORTED_FORCED_HEADER_SYNTAX'}
    foreach($m in $matches){$p=Under $m.Groups['path'].Value $script:Stage;if(-not $seen.Add($p)){continue};if([IO.Path]::GetExtension($p) -ine '.h' -or ([IO.FileInfo]::new((Need-File $p))).Length -gt 64MB){throw 'E04A1_FORCED_HEADER_KIND_OR_SIZE'}
        $isModuleDefinitions=[IO.Path]::GetFileName($p) -cmatch '^Definitions(?:\..+)?\.h$' -and $p.Replace('\','/').Contains(('/'+$Module+'/'),[StringComparison]::OrdinalIgnoreCase)
        $headers.Add(@{file=Descriptor $p;isModuleDefinitions=$isModuleDefinitions});if($isModuleDefinitions){$definitions.Add($script:Utf8.GetString([IO.File]::ReadAllBytes($p)))}
    }
    if(-not $definitions.Count){throw 'E04A1_MODULE_FORCED_DEFINITIONS_NOT_OBSERVED'}
    return @{headers=@($headers);moduleDefinitionText=($definitions -join "`n");qualification='Actual @response and /FI bindings, not a general C++ preprocessor or proof of arbitrary include side effects.'}
}
function Macro-Values([string]$Response,[string]$Definitions,[string]$Name) {
    $values=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach($m in [regex]::Matches($Response,'(?im)(?:^|\s)/D(?:"(?<define>[^"\r\n]+)"|(?<define>[^\s"\r\n]+))')){$d=$m.Groups['define'].Value;if($d -ceq $Name){[void]$values.Add('1')}elseif($d.StartsWith(($Name+'='),[StringComparison]::Ordinal)){[void]$values.Add($d.Substring($Name.Length+1))}}
    foreach($m in [regex]::Matches($Definitions,('(?m)^\s*#define\s+'+[regex]::Escape($Name)+'(?:[\t ]+(?<value>[^\r\n]*))?\r?$'))){$v=$m.Groups['value'].Value.Trim();[void]$values.Add($(if($v -eq ''){'1'}else{$v}))}
    return @($values)
}
function Check-EditorFlags {
    $all=@(Plain-Files (Join-Path $script:Stage 'Intermediate'))+@(Plain-Files (Join-Path $script:Stage 'Plugins/E04ProfileProof/Intermediate'))
    $rsp=@($all|Where-Object {[IO.Path]::GetExtension($_) -ieq '.rsp'});$observed=[Collections.Generic.List[object]]::new()
    foreach($spec in @(@('E04ProfileParser','E04ProfileParserModule.cpp',$true),@('E04ProfileParser','E04YamlEventReader.cpp',$true),@('E04ProfileProbe','E04ProfileProbeModule.cpp',$false),@('E04ProfileProbe','Tests/E04ProfileAbiTests.cpp',$false))){
        $source=(Join-Path $script:Stage ('Plugins/E04ProfileProof/Source/'+$spec[0]+'/Private/'+$spec[1])).Replace('\','/')
        $matches=@(foreach($p in $rsp){$text=$script:Utf8.GetString([IO.File]::ReadAllBytes($p));if($text.Replace('\','/').Contains($source,[StringComparison]::OrdinalIgnoreCase)){@{path=$p;text=$text}}})
        if($matches.Count -ne 1){throw 'E04A1_ACTUAL_COMPILE_RESPONSE_NOT_UNIQUE'};$chain=Response-Chain $matches[0].path;$t=$chain.text;$headers=Forced-DefinitionHeaders $t $spec[0]
        $platform=@(Macro-Values $t $headers.moduleDefinitionText 'PLATFORM_EXCEPTIONS_DISABLED');$static=@(Macro-Values $t $headers.moduleDefinitionText 'YAML_CPP_STATIC_DEFINE');$has=@(Macro-Values $t $headers.moduleDefinitionText '_HAS_EXCEPTIONS')
        $standardOptions=@([regex]::Matches($t,'(?i)(?:^|\s)(?<option>/std:[^\s]*)')|ForEach-Object {$_.Groups['option'].Value})
        if($t -notmatch '(?i)(?:^|\s)/MD(?:\s|$)' -or $t -cnotmatch '(?:^|\s)/std:c\+\+20(?:\s|$)' -or @($standardOptions|Where-Object {$_ -cne '/std:c++20'}).Count -or $t -match '(?i)(?:^|\s)/(?:MDd|MTd?)(?:\s|$)'){throw 'E04A1_ACTUAL_UBT_STANDARD_OR_CRT_FLAGS_MISMATCH'}
        # A1E deliberately measures the installed Editor's globally enabled mode
        # for BOTH modules. The third spec item marks private vendor exposure only.
        $exceptionOptions=@([regex]::Matches($t,'(?i)(?:^|\s)(?<option>/EH[^\s]*)')|ForEach-Object {$_.Groups['option'].Value})
        if($t -cnotmatch '(?:^|\s)/EHsc(?:\s|$)' -or @($exceptionOptions|Where-Object {$_ -cne '/EHsc'}).Count -or $platform.Count -ne 1 -or $platform[0] -cne '0' -or $has -contains '0'){throw 'E04A1E_ACTUAL_EDITOR_EXCEPTION_MODE_UNVERIFIED_OR_MISMATCH'}
        if($spec[2]){if($static.Count -ne 1 -or $static[0] -cne '1'){throw 'E04A1E_PARSER_STATIC_VENDOR_DEFINE_MISSING'}}
        else{if($static.Count -ne 0 -or $t.Replace('\','/').Contains(((Join-Path (Artifact-Root) 'include').Replace('\','/')),[StringComparison]::OrdinalIgnoreCase)){throw 'E04A1E_ACTUAL_VENDOR_DEFINITION_OR_INCLUDE_LEAK_TO_PROBE'}}
        $observed.Add(@{source=$source;module=$spec[0];exceptionsEnabled=$true;vendorPrivateConsumer=$spec[2];subset=$script:Subset;runtimeCallerProof=$script:RuntimeCallerProof;responseChain=$chain;forcedHeaders=$headers;actualStandardOptions=$standardOptions;actualExceptionOptions=$exceptionOptions;actualMacroValues=@{PLATFORM_EXCEPTIONS_DISABLED=$platform;YAML_CPP_STATIC_DEFINE=$static;_HAS_EXCEPTIONS=$has}})
    }
    $dlls=@(foreach($module in @('E04ProfileParser','E04ProfileProbe')){Descriptor (Join-Path $script:Stage ('Plugins/E04ProfileProof/Binaries/Win64/UnrealEditor-'+$module+'.dll'))})
    $library=(Join-Path (Artifact-Root) 'lib/yaml-cpp.lib').Replace('\','/')
    $links=[Collections.Generic.List[object]]::new()
    foreach($module in @('E04ProfileParser','E04ProfileProbe')){$pattern='(?im)^\s*/OUT:"?[^\r\n"]*UnrealEditor-'+[regex]::Escape($module)+'\.dll"?\s*$';$leaf=@(foreach($p in $rsp){$t=$script:Utf8.GetString([IO.File]::ReadAllBytes($p));if($t -match $pattern){$p}});if($leaf.Count -ne 1){throw 'E04A1_MODULE_LINK_RESPONSE_NOT_UNIQUE'};$chain=Response-Chain $leaf[0];$usesVendor=$chain.text.Replace('\','/').Contains($library,[StringComparison]::OrdinalIgnoreCase);if($usesVendor -ne ($module -ceq 'E04ProfileParser')){throw 'E04A1_STATIC_VENDOR_LINK_SCOPE_NOT_PRIVATE_TO_PARSER'};$links.Add(@{module=$module;responseChain=$chain;vendorStaticLibraryObserved=$usesVendor})}
    return @{subset=$script:Subset;runtimeCallerProof=$script:RuntimeCallerProof;compileResponses=@($observed);linkResponses=@($links);moduleBinaries=$dlls;countsQualification='Observed Editor-enabled flags, nested response files, bound forced-definition headers and byte identities; no exception-disabled caller proof.'}
}
function Native-Arguments {
    $name=$Phase.ToLowerInvariant();$commands=if($Phase -eq 'Discovery'){'Automation List;Quit'}else{'Automation RunTest StartsWith:Warhammer.Migration.E04A1.;Quit'}
    $ddc=(Owned 'ddc').Replace('\','/')
    return @((Join-Path $script:Stage 'WarhammerClient.uproject'),'-NullRHI','-unattended','-nosound','-nowrite','-NoSplash','-NoSourceControl','-NoLiveCoding',
        "-ExecCmds=$commands",'-TestExit=Automation Test Queue Empty',"-ReportExportPath=$((Owned "reports/$name").Replace('\','/'))","-abslog=$((Owned "logs/native-$name.log").Replace('\','/'))",
        "-UserDir=$((Owned 'ue-user').Replace('\','/'))",'-DDC-NoDefaultGraph',"-DDC=(E04A1=(Type=FileSystem,Path=$ddc,DeleteUnused=false))",'-EnablePlugins=E04ProfileProof',('-DisablePlugins='+($script:Disabled -join ',')))
}
function Check-OwnedDdcLog([string]$Text,[string]$OwnedPath) {
    $ddc=@($Text -split "`n"|Where-Object {$_ -match '\bLogDerivedDataCache:'})
    $path=$OwnedPath.Replace('\','/');$ownedWritable=$false
    # Installed FileSystemCacheStore.cpp logs this only after StoreOwner.Add.
    # Compare the complete parsed path; slash direction and one trailing slash
    # are the only spelling differences accepted for this Windows-only proof.
    foreach($line in $ddc){
        if($line -match '(?i)(falling back|fallback.*(?:enabled|using)|(?:Zen|Cloud|Shared).*\b(?:using|connected|enabled|running)\b|Failed to create graph\b|Attempting to create graph\b)'){throw 'E04A1_OWNED_DDC_SELECTION_UNVERIFIED_OR_FALLBACK'}
        $store=[regex]::Match($line,'\bLogDerivedDataCache:\s+(?<store>[^:\r\n]+): Using data cache path (?<path>[^\r\n]+): (?<access>Writable|ReadOnly|DeleteOnly)\r?$')
        if($line -match '(?i)\bWritable\b'){
            if(-not $store.Success -or $store.Groups['access'].Value -cne 'Writable'){throw 'E04A1_NONOWNED_DDC_WRITER'}
            $observed=$store.Groups['path'].Value.Replace('\','/')
            if(-not $observed.Equals($path,[StringComparison]::OrdinalIgnoreCase) -and -not $observed.Equals(($path+'/'),[StringComparison]::OrdinalIgnoreCase)){throw 'E04A1_NONOWNED_DDC_WRITER'}
            if($store.Groups['store'].Value -ceq 'E04A1'){$ownedWritable=$true}
        }
    }
    if(-not $ownedWritable){throw 'E04A1_OWNED_DDC_SELECTION_UNVERIFIED_OR_FALLBACK'}
    return $ddc
}
function Inspect-NativeLog {
    $p=Owned ('logs/native-'+$Phase.ToLowerInvariant()+'.log');if(([IO.FileInfo]::new((Need-File $p))).Length -gt 64MB){throw 'E04A1_NATIVE_LOG_CAP'};$text=$script:Utf8.GetString([IO.File]::ReadAllBytes($p));Safe-Text $text
    if($text -match '(?im)^.*(?:LogWindows:\s+Error:\s+(?:Fatal error|Unhandled Exception)|LogOutputDevice:\s+Error:\s+=== Critical error|LogCore:\s+Error:\s+Fatal error|Fatal error:|Assertion failed:)'){throw 'E04A1_FATAL_NATIVE_DIAGNOSTIC'}
    if($text -match '(?i)(LogPluginManager:.*Mounting.*(?:UdpMessaging|TcpMessaging|QuicMessaging|WebSocketMessaging|DiscoveryBeaconReceiver|NetworkServiceDiscovery)|Log(?:Udp|Tcp|Quic|WebSocket)Messaging:.*(?:Initializing|Started|Listening|Connecting|bridge|tunnel))' -or $text -match 'Inserting commandline from UE-CmdLineArgs:|\s-EnvAfterHere(?:\s|$)'){throw 'E04A1_FORBIDDEN_STARTUP_OR_ENVIRONMENT_ROUTE'}
    if($text -notmatch '(?i)LogPluginManager:.*Mounting.*\bE04ProfileProof\b'){throw 'E04A1_PROOF_PLUGIN_STARTUP_NOT_OBSERVED'}
    $ddc=@(Check-OwnedDdcLog $text (Owned 'ddc'))
    return @{log=Descriptor $p;ddcLines=$ddc;startupQualification='Specific observed startup/log routes, not complete network/filesystem isolation.';visibleWindowRequested=$false;rendering='NULLRHI_HEADLESS_NO_RENDERED_PROOF'}
}
function Check-Discovery {
    $text=$script:Utf8.GetString([IO.File]::ReadAllBytes((Need-File (Owned 'logs/native-discovery.log'))))
    $listed=@([regex]::Matches($text,"(?m)^.*\bLogAutomationCommandLine: Display:\s*'([^\r\n]+)'\s*$")|ForEach-Object {$_.Groups[1].Value})
    $counts=@([regex]::Matches($text,'\bLogAutomationCommandLine: Display: Found ([0-9]+) Automation Tests')|ForEach-Object {[int]$_.Groups[1].Value})
    if($counts.Count -ne 1 -or $listed.Count -ne $counts[0]){throw 'E04A1_DISCOVERY_COMPLETE_LIST_MISSING'}
    $selected=@($listed|Where-Object {$_.StartsWith('Warhammer.Migration.E04A1.',[StringComparison]::Ordinal)}|Sort-Object -CaseSensitive)
    if($selected.Count -ne 8 -or ($selected -join "`n") -cne (@($script:Names|Sort-Object -CaseSensitive)-join "`n")){throw 'E04A1_EXACT_EIGHT_DISCOVERY_MISMATCH'}
    return @{engineEligibleCount=$listed.Count;selectedCount=8;selectedNames=$selected;log=Descriptor (Owned 'logs/native-discovery.log')}
}
function Expected-Attempts {
    $m=[ordered]@{'Abi.LoadAndBoundary'=@('A1-K04');'Abi.TypedRefusal'=@('A1-F01','A1-K04');'Abi.ValueLifetime'=@('A1-K03');'Parser.CanonicalSyntax'=@(1..10|ForEach-Object {'A1-C{0:D2}' -f $_});'Parser.OrderedCaseValues'=@(1..4|ForEach-Object {'A1-K{0:D2}' -f $_});'Parser.LexicalFailures'=@(1..9|ForEach-Object {'A1-F{0:D2}' -f $_});'Parser.ResourceBounds'=@(foreach($kind in @('file','depth','nodes','aliases','scalar')){foreach($level in @('below','at','above')){"A1-L.$kind.$level"}});'Integration.RepeatIsolation'=@('A1-K03','A1-F02','A1-K03')};return $m
}
function Check-Native {
    $reportPath=Owned 'reports/native/index.json';$report=Read-Json $reportPath;$tests=@($report.tests)
    if($tests.Count -ne 8 -or (@($tests|ForEach-Object {$_.fullTestPath}|Sort-Object -CaseSensitive)-join "`n") -cne (@($script:Names|Sort-Object -CaseSensitive)-join "`n")){throw 'E04A1_EXACT_EIGHT_NATIVE_REPORT_MISMATCH'}
    foreach($t in $tests){if($t.state -cne 'Success'){throw 'E04A1_UE_CASE_NOT_SUCCESS'}}
    foreach($field in @('failed','notRun','inProcess')){if($report[$field] -ne 0){throw 'E04A1_UE_REPORT_INCOMPLETE'}}
    $warnings=if($report.Contains('succeededWithWarnings')){[int]$report.succeededWithWarnings}else{0};if([int]$report.succeeded+$warnings -ne 8){throw 'E04A1_UE_SUCCESS_TOTAL_MISMATCH'}
    $definitions=Read-Json (Owned 'fixtures/input-definitions.json');$byId=@{};foreach($d in $definitions.inputs){if($byId.ContainsKey($d.id)){throw 'E04A1_DEFINITION_DUPLICATE'};$byId[$d.id]=$d}
    if($byId.Count -ne 38){throw 'E04A1_DEFINITION_UNION_MISMATCH'}
    $expected=Expected-Attempts;$union=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal);$artifacts=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase);$observed=[Collections.Generic.List[object]]::new();$totalChecks=0L;$totalAttempts=0
    foreach($suffix in $script:SuiteSlugs.Keys){$slug=$script:SuiteSlugs[$suffix];$ledgerPath=Owned "artifacts/native/$slug/input-ledger.json";$ledger=Read-Json $ledgerPath
        if($ledger.schemaVersion -ne 1 -or $ledger.subset -cne $script:Subset -or $ledger.runtimeCallerProof -cne $script:RuntimeCallerProof -or $ledger.callerExceptionsEnabled -isnot [bool] -or $ledger.callerExceptionsEnabled -ne $true -or $ledger.platformExceptionsDisabled -ne 0 -or ($ledger.platformExceptionsDisabled -isnot [int] -and $ledger.platformExceptionsDisabled -isnot [long])){throw 'E04A1E_ACTUAL_LEDGER_SUBSET_OR_EDITOR_CALLER_MODE_MISMATCH'}
        if($ledger.suiteName -cne "Warhammer.Migration.E04A1.$suffix" -or (Assert-Path $ledger.projectDir).TrimEnd('\','/') -ine $script:Stage.TrimEnd('\','/') -or (Assert-Path $ledger.runRoot).TrimEnd('\','/') -ine $script:RunRoot.TrimEnd('\','/') -or $ledger.status -cne 'PASS' -or $ledger.failedCheckCount -ne 0 -or $ledger.checkCount -le 0 -or $ledger.observedInputCount -ne @($expected[$suffix]).Count -or @($ledger.inputs).Count -ne @($expected[$suffix]).Count){throw 'E04A1_SUITE_LEDGER_IDENTITY_OR_ACTUAL_CHECKS_MISMATCH'}
        [void]$artifacts.Add($ledgerPath);$rowChecks=0L;$rows=[Collections.Generic.List[object]]::new()
        for($i=0;$i -lt @($expected[$suffix]).Count;$i++){$row=$ledger.inputs[$i];$id=$expected[$suffix][$i];$attempt=if($suffix -ceq 'Integration.RepeatIsolation' -and $i -eq 2){2}else{1};$d=$byId[$id]
            $relative="artifacts/native/$slug/inputs/$id-$attempt.yaml";$p=Owned $relative
            if($row.id -cne $id -or $row.attempt -ne $attempt -or $row.inputArtifactRelativePath -cne $relative -or $row.actualCode -cne $d.expectedCode -or $row.expectedCode -cne $d.expectedCode -or $row.source -cne $d.source -or $row.recipeKind -cne $d.recipeKind -or $row.checks -le 0 -or $row.failedChecks -ne 0 -or $row.inputBytes -ne $d.bytes -or $row.inputSha1 -ine $d.inputSha1 -or $row.success -isnot [bool] -or $row.success -ne ($d.expectedCode -ceq 'Success')){throw 'E04A1_INPUT_LEDGER_TYPED_CODE_OR_ATTEMPT_MISMATCH'}
            if($d.expectedCode -cne 'Success' -and $row.diagnostic.code -cne $d.expectedCode){throw 'E04A1_TYPED_DIAGNOSTIC_MISMATCH'}
            $actual=Descriptor $p;if($actual.bytes -ne $d.bytes -or $actual.sha256 -ine $d.sha256){throw 'E04A1_PRIMARY_NATIVE_INPUT_SHA256_OR_BYTES_MISMATCH'}
            [void]$union.Add($id);if(-not $artifacts.Add($p)){throw 'E04A1_DUPLICATE_INPUT_ARTIFACT'};$rowChecks+=[long]$row.checks;$rows.Add(@{id=$id;attempt=$attempt;actualInput=$actual;primaryHash='SHA256';auxiliaryNativeSha1=$row.inputSha1;actualCode=$row.actualCode;checks=$row.checks;diagnostic=$row.diagnostic})
        }
        if($rowChecks -gt [long]$ledger.checkCount){throw 'E04A1_ROW_CHECK_TOTAL_EXCEEDS_ACTUAL_SUITE_CHECKS'}
        $totalChecks+=[long]$ledger.checkCount;$totalAttempts+=@($ledger.inputs).Count;$observed.Add(@{suite=$ledger.suiteName;subset=$ledger.subset;runtimeCallerProof=$ledger.runtimeCallerProof;callerExceptionsEnabled=$ledger.callerExceptionsEnabled;platformExceptionsDisabled=$ledger.platformExceptionsDisabled;ledger=Descriptor $ledgerPath;actualCustomCheckCount=$ledger.checkCount;rowChecks=$rowChecks;inputs=@($rows)})
    }
    $files=@(Plain-Files (Owned 'artifacts/native'));if($files.Count -ne $artifacts.Count -or @($files|Where-Object {-not $artifacts.Contains($_)}).Count -or $union.Count -ne 38 -or $totalAttempts -ne 45){throw 'E04A1_EXACT_ARTIFACT_MEMBERSHIP_OR_38_ID_UNION_MISMATCH'}
    [void](Need-File (Owned 'reports/native/index.html'))
    return @{subset=$script:Subset;runtimeCallerProof=$script:RuntimeCallerProof;fullA1Acceptance='NOT_ESTABLISHED_REQUIRES_A1G_AND_OTHER_OPEN_GATES';automationReport=Descriptor $reportPath;html=Descriptor (Owned 'reports/native/index.html');suiteCount=8;attemptCount=$totalAttempts;distinctInputCount=$union.Count;actualCustomCheckTotal=$totalChecks;ueAssertionTotal='NOT_ESTABLISHED_BY_EXPORT_DO_NOT_EQUATE_WITH_CUSTOM_CHECK_COUNT';actualCustomCountQualification='Evaluated native P.Check calls before ledger publication, not a prefilled assertion total.';suites=@($observed);linux='NOT_RUN_UNTESTED'}
}
function Check-Previous {
    $index=[Array]::IndexOf($script:Order,$Phase);$links=[Collections.Generic.List[object]]::new()
    for($i=0;$i -lt $index;$i++){$prior=$script:Order[$i];$root=Owned $prior.ToLowerInvariant();$c=Read-Json (Join-Path $root 'completion.json')
        if($c.schemaVersion -ne 1 -or $c.subset -cne $script:Subset -or $c.runtimeCallerProof -cne $script:RuntimeCallerProof -or $c.runId -cne $RunId -or $c.phase -cne $prior -or $c.sourceHead -cne $script:Freeze.sourceHead -or $c.executionPassed -ne $true -or $c.state -cne 'COMPLETE' -or $c.freezeManifestSha256 -ine (Digest $FreezeManifestPath)){throw 'E04A1E_SUCCESSFUL_SAME_SUBSET_PREDECESSOR_REQUIRED'}
        $r=Check-Descriptor $c.result;$body=Read-Json $r.path;if($body.subset -cne $script:Subset -or $body.runtimeCallerProof -cne $script:RuntimeCallerProof -or $body.executionPassed -ne $true -or $body.phase -cne $prior -or $body.runId -cne $RunId){throw 'E04A1E_PREDECESSOR_RESULT_SUBSET_MISMATCH'}
        foreach($d in $body.retainedArtifacts){[void](Check-Descriptor $d)};$links.Add(@{phase=$prior;completion=Descriptor (Join-Path $root 'completion.json');result=$r})
    };return @($links)
}
function Output-Inventory {
    $items=[Collections.Generic.List[object]]::new();$reportBytes=0L
    foreach($name in @('logs','reports','artifacts','fixtures')){foreach($p in Plain-Files (Owned $name)){$d=Descriptor $p;if($d.bytes -gt 64MB){throw 'E04A1_DATA_OR_STREAM_CAP_PRESERVE_OVERSIZE'};if($name -ceq 'reports'){$reportBytes+=$d.bytes};$items.Add($d)}}
    if([IO.Directory]::Exists((Artifact-Root))){foreach($p in Plain-Files (Artifact-Root)){$d=Descriptor $p;if($d.bytes -gt 64MB){throw 'E04A1E_COPIED_VENDOR_ARTIFACT_DATA_CAP'};$items.Add($d)}}
    foreach($phaseName in $script:Order){$root=Owned $phaseName.ToLowerInvariant();if([IO.Directory]::Exists($root)){foreach($p in Plain-Files $root){$items.Add((Descriptor $p))}}}
    if($reportBytes -gt 512MB){throw 'E04A1_REPORT_AGGREGATE_CAP'};return @($items)
}

# Everything above is definition/data only. Actual phase work starts after all gates.
$primary=$null;$phaseCreated=$false;$published=$false;$baseline=$null;$sourceBefore=$null;$stageBefore=$null;$fixtureBefore=$null
try {
    if(-not $IsWindows -or [Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture -ne [Runtime.InteropServices.Architecture]::X64){throw 'E04A1_NATIVE_WINDOWS_X64_HOST_REQUIRED_LINUX_UNTESTED'}
    $script:E02UserContext=Execution-UserContext
    $script:Freeze=Check-Freeze;$authority=Check-Authority;[void](Windows-Contract)
    $drive=[IO.DriveInfo]::new([IO.Path]::GetPathRoot($script:RunRoot));if($drive.AvailableFreeSpace -lt 20GB){throw 'E04A1_TWENTY_GIB_FREE_REQUIRED'}
    if($Phase -ceq 'Preflight'){
        [void](Assert-Path $script:RunRoot);if(Test-Path -LiteralPath $script:RunRoot){throw 'E04A1_FRESH_RUN_ROOT_REQUIRED'};[void][IO.Directory]::CreateDirectory($script:RunRoot)
        $script:RunLock=[IO.File]::Open((Owned 'phase-serialization.lock'),[IO.FileMode]::CreateNew,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    }else{$script:RunLock=[IO.File]::Open((Need-File (Owned 'phase-serialization.lock')),[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)}
    New-Directory $script:PhaseRoot;$phaseCreated=$true
    $script:Result=[ordered]@{schemaVersion=1;experiment='E04-A1';subset=$script:Subset;runtimeCallerProof=$script:RuntimeCallerProof;fullA1Acceptance='NOT_ESTABLISHED_REQUIRES_A1G_AND_OTHER_OPEN_GATES';runId=$RunId;phase=$Phase;sourceHead=$script:Freeze.sourceHead;startedUtc=[DateTime]::UtcNow.ToString('o');completedUtc=$null;status='PROVISIONAL';executionPassed=$false;authority=$authority;freezeManifest=Descriptor $FreezeManifestPath;processes=[Collections.Generic.List[object]]::new();primaryFailure=$null;secondaryErrors=@();retainedArtifacts=@();settingsBefore=$null;settingsAfter=$null;sourceBefore=$null;sourceAfter=$null;stageBefore=$null;stageAfter=$null;projectPluginCatalogAfter=$null;previous=@();limits=@('A1E Editor modules have exceptions enabled; A1G exception-disabled runtime caller remains required.','No GUI/render/Core/network/install/package/Linux execution claim.','Producer receipts and custom native checks are not independent acceptance.','Private job aggregate final zero is not universal descendant identity or OS isolation.','Host phase limits check synchronous I/O at boundaries; streams/data/report caps are retained-output acceptance checks.')}
    $script:Result.previous=Check-Previous
    if($Phase -ceq 'Preflight'){
        foreach($name in @('project','logs','reports','reports/supervisor-controls','reports/discovery','reports/native','artifacts','artifacts/native','fixtures','fixtures/expected-inputs','temp','dotnet-home','nuget','uba','ddc','ue-user')){[void][IO.Directory]::CreateDirectory((Owned $name))}
        foreach($d in $script:Freeze.sourceMembership){$target=Under (Join-Path $script:Stage $d.path) $script:Stage;[void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target));[IO.File]::Copy((Need-File (Join-Path $script:Repo $d.path)),$target,$false)}
        Same-Source @(Snapshot-Source $script:Repo) @(Snapshot-Source $script:Stage);Prepare-Fixtures
    }
    $sourceBefore=@(Snapshot-Source $script:Repo);$stageBefore=@(Snapshot-Source $script:Stage)
    Same-Source @($script:Freeze.sourceMembership) $sourceBefore;Same-Source @($script:Freeze.sourceMembership) $stageBefore
    $fixtureBefore=@(Fixture-Snapshot);$baseline=@(Settings);Check-Settings $baseline $baseline
    $script:Result.sourceBefore=$sourceBefore;$script:Result.stageBefore=$stageBefore;$script:Result.settingsBefore=$baseline;$script:Result.fixturesBefore=$fixtureBefore
    if($Phase -cne 'Preflight'){$pf=Read-Json (Owned 'preflight/result.json');Check-Settings $pf.settingsAfter $baseline}
    Check-StagedPluginClosure -RequireTargetReceipt:($Phase -in @('Discovery','Native','Audit'))
    if($Phase -notin @('Preflight','Audit')){Enable-NativeHelper}
    switch($Phase){
        'Preflight'{$script:Result.status='PREFLIGHT_PASS_NO_NATIVE_ROOT';$script:Result.generatedInputCount=38}
        'SupervisorControls'{$script:Result.controls=Supervisor-Controls;$script:Result.status='SUPERVISOR_CONTROLS_PASS_6_SEPARATE_FROM_NATIVE'}
        'Configure'{$build=Build-Root;New-Directory $build;$p=Invoke-Root 'configure' $script:Freeze.toolPaths.cmake (@('-S',(CMake-Path $script:VendorRoot),'-B',(CMake-Path $build))+(CMake-Options)) 600;Require-RootPass $p;$script:Result.configure=Check-CMake;$script:Result.status='CONFIGURE_PASS_NO_INSTALL'}
        'DependencyBuild'{$p=Invoke-Root 'dependency-build' $script:Freeze.toolPaths.cmake @('--build',(CMake-Path (Build-Root)),'--target','yaml-cpp','--parallel','2','--verbose') 1200;Require-RootPass $p;$script:Result.vendorArtifact=Publish-VendorArtifact $p;$script:Result.status='DEPENDENCY_BUILD_AND_EXPLICIT_COPY_PASS'}
        'EditorBuild'{$script:Result.editorBuild=Editor-Build;$script:Result.status='EDITOR_BUILD_PASS_SELECTED_NATIVE_FLAGS_OBSERVED'}
        {$_ -in @('Discovery','Native')}{$label=$Phase.ToLowerInvariant();$p=Invoke-Root $label $script:Freeze.toolPaths.editorCmd @(Native-Arguments) 600;Require-RootPass $p;$script:Result.nativeLog=Inspect-NativeLog;if($Phase -ceq 'Discovery'){$script:Result.discovery=Check-Discovery;Write-JsonNew (Owned 'reports/discovery/selected-names.json') $script:Result.discovery;$script:Result.status='DISCOVERY_PASS_EXACT_8'}else{$script:Result.native=Check-Native;Write-JsonNew (Owned 'reports/native/validated-input-ledgers.json') $script:Result.native;$script:Result.status='NATIVE_A1E_EDITOR_SUBSET_EXECUTION_PASS_NO_A1G_NO_FULL_A1_ACCEPTANCE'}}
        'Audit'{$script:Result.native=Check-Native;$script:Result.editorFlags=Check-EditorFlags;$script:Result.configure=Check-CMake;$script:Result.status='EVIDENCE_GATHERED_REQUIRES_INDEPENDENT_AUDIT';$script:Result.authorityState='RUNTIME_CLOSED_REQUIRE_ROOT_RECORD_NO_RETRY_OR_MERGE'}
    }
    $expectedRoots=if($Phase -ceq 'SupervisorControls'){5}elseif($Phase -in @('Configure','DependencyBuild','EditorBuild','Discovery','Native')){1}else{0};if($script:RootCount -ne $expectedRoots){throw 'E04A1_EXACT_PHASE_ROOT_COUNT_MISMATCH'}
    [void](Phase-Budget);$script:Result.executionPassed=$true
}catch{$primary=Failure $_ $Phase;if($null -ne $script:Result){$script:Result.primaryFailure=$primary;$script:Result.executionPassed=$false;$script:Result.status='FAIL_PRESERVE_PARTIALS_NO_RETRY'}}
finally{
    if($phaseCreated -and $null -ne $script:Result){
        try{
            if($null -ne $baseline){$script:Result.settingsAfter=@(Settings);Check-Settings $baseline $script:Result.settingsAfter}
            if($null -ne $sourceBefore){$script:Result.sourceAfter=@(Snapshot-Source $script:Repo);Same-Source $sourceBefore $script:Result.sourceAfter}
            if($null -ne $stageBefore){$script:Result.stageAfter=@(Snapshot-Source $script:Stage);Same-Source $stageBefore $script:Result.stageAfter}
            if($null -ne $sourceBefore -and $null -ne $stageBefore){
                $script:Result.projectPluginCatalogAfter=@(foreach($root in @($script:Repo,$script:Stage)){Check-ProjectPluginMembership $script:Freeze.projectPluginMembership $root})
            }
            if($null -ne $fixtureBefore){$after=@(Fixture-Snapshot);if(($fixtureBefore|ConvertTo-Json -Depth 8 -Compress) -cne ($after|ConvertTo-Json -Depth 8 -Compress)){throw 'E04A1_FIXTURE_PRIMARY_BYTES_CHANGED'};$script:Result.fixturesAfter=$after}
            Check-Dependency;$script:Result.retainedArtifacts=@(Output-Inventory);[void](Phase-Budget)
        }catch{$script:Errors.Add((Failure $_ 'post-phase-preservation'));$script:Result.executionPassed=$false;$script:Result.status='FAIL_PRESERVATION_OR_OUTPUT_VALIDATION'}
        try{
            $script:Result.completedUtc=[DateTime]::UtcNow.ToString('o');$script:Result.elapsedSeconds=$script:Clock.Elapsed.TotalSeconds;$script:Result.secondaryErrors=@($script:Errors)
            $resultPath=Join-Path $script:PhaseRoot 'result.json';Write-JsonNew $resultPath $script:Result
            if($script:Result.executionPassed -and $script:Errors.Count -eq 0){Write-JsonNew (Join-Path $script:PhaseRoot 'completion.json') @{schemaVersion=1;experiment='E04-A1';subset=$script:Subset;runtimeCallerProof=$script:RuntimeCallerProof;fullA1Acceptance='NOT_ESTABLISHED_REQUIRES_A1G_AND_OTHER_OPEN_GATES';runId=$RunId;phase=$Phase;sourceHead=$script:Freeze.sourceHead;freezeManifestSha256=Digest $FreezeManifestPath;state='COMPLETE';executionPassed=$true;result=Descriptor $resultPath;status=$script:Result.status;completedUtc=[DateTime]::UtcNow.ToString('o')};$published=$true}
        }catch{$script:Errors.Add((Failure $_ 'publication'));$published=$false;[Console]::Error.WriteLine('E04A1_PUBLICATION_FAILED_PRESERVE_PENDING_AND_PARTIAL_RECORDS')}
    }
    if($null -ne $script:RunLock){$script:RunLock.Dispose()}
}
if($published){[Console]::Out.WriteLine((@{runId=$RunId;phase=$Phase;subset=$script:Subset;runtimeCallerProof=$script:RuntimeCallerProof;status=$script:Result.status;executionPassed=$true;completion=(Join-Path $script:PhaseRoot 'completion.json')}|ConvertTo-Json -Compress));exit 0}
[Console]::Error.WriteLine((@{runId=$RunId;phase=$Phase;subset=$script:Subset;runtimeCallerProof=$script:RuntimeCallerProof;status='FAIL_OR_UNPUBLISHED';primaryFailure=$primary;secondaryErrors=@($script:Errors)}|ConvertTo-Json -Depth 12 -Compress));exit 1
