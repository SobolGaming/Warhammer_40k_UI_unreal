# Prospective bounded A1G Game proof. This source grants no execution authority.
# Exact source/run/freeze, independent SOURCE and a phase GO precede execution.
# Nine ordinary phase hooks are present; no successful test or review is claimed.
# Native selects qualified same-job WS_VISIBLE samples; no continuous absence claim.
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Preflight','DependencyConfigure','DependencyBuild','EditorPrerequisiteBuild','GameBuild','Cook','Stage','Native','Audit')][string]$Phase,
    [Parameter(Mandatory)][ValidatePattern('^[0-9]{8}T[0-9]{6}Z-[0-9a-f]{8}$')][string]$RunId,
    [Parameter(Mandatory)][string]$FreezeManifestPath,
    [Parameter(Mandatory)][ValidatePattern('^[A-Fa-f0-9]{64}$')][string]$ExpectedFreezeSha256,
    [Parameter(Mandatory)][string]$AuthorityPath,
    [Parameter(Mandatory)][ValidatePattern('^[A-Fa-f0-9]{64}$')][string]$ExpectedAuthoritySha256,
    [string]$RepositoryRoot='C:/SWDev/warhammer/Warhammer_40k_UI_unreal',
    [string]$EngineRoot='C:/Program Files/Epic Games/UE_5.8'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$false
$script:Utf8=[Text.UTF8Encoding]::new($false,$true)
$script:Repo=[IO.Path]::GetFullPath($RepositoryRoot)
$script:RunRoot=Join-Path $script:Repo ('.local/experiments/E04A1G/'+$RunId)
$script:Stage=Join-Path $script:RunRoot 'project'
$script:PhaseRoot=Join-Path $script:RunRoot $Phase.ToLowerInvariant()
$script:Order=@('Preflight','DependencyConfigure','DependencyBuild','EditorPrerequisiteBuild','GameBuild','Cook','Stage','Native','Audit')
$script:Budgets=@{Preflight=300;DependencyConfigure=600;DependencyBuild=1200;EditorPrerequisiteBuild=1800;GameBuild=1800;Cook=1800;Stage=600;Native=600;Audit=300}
$script:Subset='E04-A1G_WIN64_DEVELOPMENT_GAME_CALLER'
$script:RuntimeCallerProof='ACTUAL_HIDDEN_COOKED_GAME_REQUIRED'
$script:Errors=[Collections.Generic.List[object]]::new()
$script:Secrets=[Collections.Generic.List[string]]::new()
foreach($entry in [Environment]::GetEnvironmentVariables().GetEnumerator()){
    if($entry.Key -match '(?i)TOKEN|PASSWORD|SECRET|API_KEY|CREDENTIAL' -and ([string]$entry.Value).Length -ge 8){$script:Secrets.Add([string]$entry.Value)}
}
$script:Freeze=$null;$script:Result=$null;$script:E02UserContext=$null;$script:RunLock=$null
$script:RootCount=0;$script:Clock=[Diagnostics.Stopwatch]::StartNew()
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

function Child-Environment([hashtable]$Extra=@{}) {
    $envs=[Collections.Generic.Dictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach($pair in @(@('TEMP','temp'),@('TMP','temp'),@('DOTNET_CLI_HOME','dotnet-home'),@('NUGET_PACKAGES','nuget'),@('UBA_ROOT','uba'))){$envs[$pair[0]]=Owned $pair[1]}
    foreach($pair in @(@('DOTNET_CLI_TELEMETRY_OPTOUT','1'),@('DOTNET_SKIP_FIRST_TIME_EXPERIENCE','1'),@('DOTNET_NOLOGO','1'),@('UE-SharedDataCachePath','None'),@('UE_ADDITIONAL_PLUGIN_PATHS',''),@('UE-CmdLineArgs',''),@('UBT_EXTRA_ARGS',''),@('UE_USE_SYSTEM_DOTNET',''),@('UE_DOTNET_VERSION',''),@('UE_DOTNET_DIR',''),@('UE_DOTNET_ARCH',''),@('ProgramFiles(Arm)',''),@('PROCESSOR_ARCHITECTURE','AMD64'),@('PATHEXT','.EXE'),@('DOTNET_MULTILEVEL_LOOKUP','0'))){$envs[$pair[0]]=$pair[1]}
    $w=$script:Freeze.windows;$vc=Assert-Path $w.compilerDir;$sdk=Assert-Path $w.sdkDir;$v=$w.sdkVersion
    $include=@((Join-Path $vc 'include'),(Join-Path $sdk "include/$v/ucrt"),(Join-Path $sdk "include/$v/shared"),(Join-Path $sdk "include/$v/um"),(Join-Path $sdk "include/$v/winrt"),(Join-Path $sdk "include/$v/cppwinrt"))
    $lib=@((Join-Path $vc 'lib/x64'),(Join-Path $sdk "lib/$v/ucrt/x64"),(Join-Path $sdk "lib/$v/um/x64"))
    foreach($p in $include+$lib){[void](Assert-Path $p);if(-not [IO.Directory]::Exists($p)){throw 'E04A1_EXPLICIT_COMPILER_ENVIRONMENT_DIRECTORY_MISSING'}}
    $dotnet=[IO.Path]::GetDirectoryName($script:Freeze.toolPaths.dotnet);$envs['DOTNET_ROOT']=$dotnet;$envs['DOTNET_ROOT_X64']=$dotnet
    $envs['INCLUDE']=$include -join ';';$envs['LIB']=$lib -join ';';$envs['LIBPATH']=$lib -join ';'
    $envs['PATH']=(@([IO.Path]::GetDirectoryName($script:Freeze.toolPaths.compiler),[IO.Path]::GetDirectoryName($script:Freeze.toolPaths.sdkRc),[IO.Path]::GetDirectoryName($script:Freeze.toolPaths.cmake),[IO.Path]::GetDirectoryName($script:Freeze.toolPaths.ninja),$dotnet,[IO.Path]::GetDirectoryName($script:Freeze.toolPaths.cmd)) -join ';')
    foreach($e in $Extra.GetEnumerator()){
        if($e.Key -clike 'E02_*' -or $e.Key -clike 'E04A1_*'){throw 'E04A1_E02_CHILD_ENVIRONMENT_FORBIDDEN'}
        if([StringComparer]::OrdinalIgnoreCase.Equals([string]$e.Key,'UBT_EXTRA_ARGS') -and ($e.Value -isnot [string] -or $e.Value -cne '')){throw 'E04A1_UBT_EXTRA_ARGS_RESERVED_EMPTY'}
        $envs[$e.Key]=[string]$e.Value
    }
    $envs['UBT_EXTRA_ARGS']='';return ,$envs
}

function Require-RootPass($Record) {
    if($Record['status'] -cne 'PASS' -or $Record['exitConfirmed'] -ne $true -or $Record['cleanupConfirmed'] -ne $true -or $Record['timedOut'] -or $Record['exitCode'] -ne 0){throw 'E04A1_ROOT_FAILED_OR_CLEANUP_UNVERIFIED'}
    $a=@($Record['jobAccounting']);if(-not $a.Count -or $a[-1].activeProcesses -ne 0){throw 'E04A1_FINAL_JOB_ZERO_UNVERIFIED'}
}

function Windows-Contract {
    $w=$script:Freeze.windows
    if($w.compilerName -cne 'VisualStudio2022' -or $w.toolChainName -cne 'VisualStudio2022' -or $w.compilerVersion -cne '14.44.35229' -or $w.toolChainVersion -cne '14.44.35229' -or $w.sdkVersion -cne '10.0.22621.0' -or $w.compilerDir -ine $w.toolChainDir){throw 'E04A1_REVIEWED_WINDOWS_SELECTION_MISMATCH'}
    foreach($e in @(@('compiler',(Join-Path $w.compilerDir 'bin/Hostx64/x64/cl.exe')),@('linker',(Join-Path $w.toolChainDir 'bin/Hostx64/x64/link.exe')),@('librarian',(Join-Path $w.toolChainDir 'bin/Hostx64/x64/lib.exe')),@('sdkRc',(Join-Path $w.sdkDir ('bin/'+$w.sdkVersion+'/x64/rc.exe'))))){if($script:Freeze.toolPaths[$e[0]] -ine (Assert-Path $e[1])){throw 'E04A1_FROZEN_TOOL_NOT_SELECTED_PATH'}}
    return $w
}

function CMake-Path([string]$Path) {return $Path.Replace('\','/')}

function CMake-Options {
    # Match the real compiler ABI probe to this Release-only dependency build.
    return @('-G','Ninja',('-DCMAKE_MAKE_PROGRAM='+(CMake-Path $script:Freeze.toolPaths.ninja)),('-DCMAKE_CXX_COMPILER='+(CMake-Path $script:Freeze.toolPaths.compiler)),('-DCMAKE_LINKER='+(CMake-Path $script:Freeze.toolPaths.linker)),('-DCMAKE_AR='+(CMake-Path $script:Freeze.toolPaths.librarian)),('-DCMAKE_RC_COMPILER='+(CMake-Path $script:Freeze.toolPaths.sdkRc)),
        '-DCMAKE_BUILD_TYPE=Release','-DCMAKE_TRY_COMPILE_CONFIGURATION=Release','-DCMAKE_CXX_SCAN_FOR_MODULES=OFF','-DCMAKE_CXX_STANDARD=20','-DCMAKE_CXX_STANDARD_REQUIRED=ON','-DCMAKE_CXX_EXTENSIONS=OFF','-DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreadedDLL','-DCMAKE_CXX_FLAGS=/EHsc /GR-','-DCMAKE_EXPORT_COMPILE_COMMANDS=ON',
        '-DYAML_BUILD_SHARED_LIBS=OFF','-DYAML_CPP_BUILD_TESTS=OFF','-DYAML_CPP_BUILD_TOOLS=OFF','-DYAML_CPP_BUILD_CONTRIB=OFF','-DYAML_CPP_INSTALL=OFF','-DYAML_CPP_FORMAT_SOURCE=OFF','-DBUILD_TESTING=OFF','-DYAML_CPP_DISABLE_UNINSTALL=ON','-DYAML_ENABLE_PIC=ON','-DYAML_MSVC_SHARED_RT=ON')
}

function Check-CMake {
    $root=Build-Root;$cache=Need-File (Join-Path $root 'CMakeCache.txt');$text=$script:Utf8.GetString([IO.File]::ReadAllBytes($cache));Safe-Text $text
    $expected=@{CMAKE_BUILD_TYPE='Release';CMAKE_TRY_COMPILE_CONFIGURATION='Release';CMAKE_CXX_SCAN_FOR_MODULES='OFF';CMAKE_CXX_STANDARD='20';CMAKE_CXX_STANDARD_REQUIRED='ON';CMAKE_CXX_EXTENSIONS='OFF';CMAKE_MSVC_RUNTIME_LIBRARY='MultiThreadedDLL';CMAKE_EXPORT_COMPILE_COMMANDS='ON';YAML_BUILD_SHARED_LIBS='OFF';YAML_CPP_BUILD_TESTS='OFF';YAML_CPP_BUILD_TOOLS='OFF';YAML_CPP_BUILD_CONTRIB='OFF';YAML_CPP_INSTALL='OFF';YAML_CPP_FORMAT_SOURCE='OFF';BUILD_TESTING='OFF';YAML_CPP_DISABLE_UNINSTALL='ON';YAML_ENABLE_PIC='ON';YAML_MSVC_SHARED_RT='ON'}
    foreach($e in $expected.GetEnumerator()){$m=[regex]::Matches($text,('(?m)^'+[regex]::Escape($e.Key)+':[^=]+=([^\r\n]*)\r?$'));if($m.Count -ne 1 -or $m[0].Groups[1].Value -cne $e.Value){throw ('E04A1_CMAKE_CACHE_OPTION_MISMATCH: '+$e.Key)}}
    foreach($e in @(@('CMAKE_CXX_COMPILER',$script:Freeze.toolPaths.compiler),@('CMAKE_MAKE_PROGRAM',$script:Freeze.toolPaths.ninja),@('CMAKE_AR',$script:Freeze.toolPaths.librarian),@('CMAKE_LINKER',$script:Freeze.toolPaths.linker),@('CMAKE_RC_COMPILER',$script:Freeze.toolPaths.sdkRc),@('CMAKE_HOME_DIRECTORY',$script:VendorRoot))){$m=[regex]::Matches($text,('(?m)^'+$e[0]+':[^=]+=([^\r\n]*)\r?$'));if($m.Count -ne 1 -or (Assert-Path $m[0].Groups[1].Value) -ine (Assert-Path $e[1])){throw ('E04A1_CMAKE_SELECTED_PATH_MISMATCH: '+$e[0])}}
    $commandsPath=Join-Path $root 'compile_commands.json';$commands=@(Read-Json $commandsPath)
    $expectedSources=@($script:Dependency.files|Where-Object {$_.path -cmatch '^src/[^/]+\.cpp$'}|ForEach-Object {Assert-Path (Join-Path $script:VendorRoot $_.path)}|Sort-Object -CaseSensitive)
    $actual=[Collections.Generic.List[string]]::new();$flags=[Collections.Generic.List[object]]::new()
    foreach($c in $commands){$file=Assert-Path $c.file;if($file -cin $actual){throw 'E04A1_DUPLICATE_VENDOR_COMPILE_COMMAND'};$actual.Add($file)
        if((Assert-Path $c.directory) -ine $root -or $c.command -isnot [string]){throw 'E04A1_VENDOR_COMMAND_SHAPE_OR_DIRECTORY'}
        $cmd=[string]$c.command;Safe-Text $cmd;$compiler=Need-File $script:Freeze.toolPaths.compiler
        $leading=[regex]::Match($cmd,'\A(?:"(?<quoted>[^"\r\n]+)"|(?<plain>[^\s"]+))(?=[ \t]+\S)')
        if(-not $leading.Success){throw 'E04A1_VENDOR_ACTUAL_COMPILE_FLAGS_MISMATCH'}
        $compilerToken=if($leading.Groups['quoted'].Success){$leading.Groups['quoted'].Value}else{$leading.Groups['plain'].Value}
        $actualCompiler=Need-File $compilerToken
        $actualCompiler=Need-File ((Get-Item -LiteralPath $actualCompiler -Force -ErrorAction Stop).FullName)
        if($actualCompiler -ine $compiler -or $cmd -notmatch '(?i)(?:^|\s)[/-]MD(?:\s|$)' -or $cmd -match '(?i)(?:^|\s)[/-](?:MDd|MTd?)(?:\s|$)' -or $cmd -notmatch '(?i)(?:^|\s)[/-]std:c\+\+20(?:\s|$)' -or $cmd -notmatch '(?i)(?:^|\s)/EHsc(?:\s|$)' -or $cmd -notmatch '(?i)(?:^|\s)/GR-(?:\s|$)' -or $cmd -notmatch '(?:-D|/D)YAML_CPP_STATIC_DEFINE(?:=1)?(?:\s|$)'){throw 'E04A1_VENDOR_ACTUAL_COMPILE_FLAGS_MISMATCH'}
        $flags.Add(@{file=$file;command=$cmd;observedRuntime='MD';observedStandard='C++20';observedExceptions='EHsc';observedRtti='GR-';staticDefineObserved=$true})
    }
    if(-not $expectedSources.Count -or (@($actual|Sort-Object -CaseSensitive)-join "`n") -cne ($expectedSources -join "`n")){throw 'E04A1_VENDOR_COMPILE_SOURCE_MEMBERSHIP_MISMATCH'}
    $ninja=Need-File (Join-Path $root 'build.ninja');$ninjaText=$script:Utf8.GetString([IO.File]::ReadAllBytes($ninja))
    if($ninjaText -notmatch '(?m)^build yaml-cpp\.lib: CXX_STATIC_LIBRARY_LINKER__yaml-cpp_Release\b' -or $ninjaText -match '(?m)^build (?:install|uninstall|format):'){throw 'E04A1_NINJA_STATIC_TARGET_OR_FORBIDDEN_TARGET'}
    return @{cache=Descriptor $cache;compileCommands=Descriptor $commandsPath;ninja=Descriptor $ninja;sourceCount=$actual.Count;actualCommandData=@($flags);qualification='Literal generated command/flag observations, never executed as evidence text. Actual supervised build/process evidence remains separate.'}
}

function Require-GeneratedBuildKeys($Value,[string[]]$Keys) {
    if($Value -isnot [Collections.IDictionary] -or $Value.Count -ne $Keys.Count){throw 'E04A1_GENERATED_INPUT_OBJECT_KEYS'}
    $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach($key in $Value.Keys){if($key -isnot [string] -or -not $seen.Add($key)){throw 'E04A1_GENERATED_INPUT_OBJECT_KEYS'}}
    if(-not $seen.SetEquals($Keys)){throw 'E04A1_GENERATED_INPUT_OBJECT_KEYS'}
}

function Assert-GeneratedBuildDescriptor($Value,[switch]$IdentityOnly) {
    Require-GeneratedBuildKeys $Value @('path','bytes','sha256')
    if($Value.path -isnot [string] -or -not [IO.Path]::IsPathFullyQualified($Value.path) -or
        ($Value.bytes -isnot [int] -and $Value.bytes -isnot [long]) -or $Value.bytes -lt 0 -or
        $Value.sha256 -isnot [string] -or $Value.sha256 -cnotmatch '^[a-fA-F0-9]{64}$'){throw 'E04A1_GENERATED_INPUT_DESCRIPTOR_TYPE'}
    [void](Assert-Path $Value.path)
    if(-not $IdentityOnly){[void](Check-Descriptor $Value)}
}

function Resolve-GeneratedBuildReference([string]$Token,[string]$Root) {
    $token=$Token.Trim()
    if($token.StartsWith('"',[StringComparison]::Ordinal)){
        if($token.Length -lt 2 -or -not $token.EndsWith('"',[StringComparison]::Ordinal)){throw 'E04A1_GENERATED_INPUT_UNSUPPORTED_REFERENCE'}
        $token=$token.Substring(1,$token.Length-2)
    }
    $decoded=[Text.StringBuilder]::new()
    for($i=0;$i -lt $token.Length;$i++){
        $ch=$token[$i]
        if($ch -eq '$'){
            $i++;if($i -ge $token.Length -or $token[$i] -cnotin @(' ',':','$')){throw 'E04A1_GENERATED_INPUT_UNSUPPORTED_REFERENCE'}
            $ch=$token[$i]
        }
        if([int]$ch -lt 32 -or $ch -eq '"'){throw 'E04A1_GENERATED_INPUT_UNSUPPORTED_REFERENCE'}
        [void]$decoded.Append($ch)
    }
    $name=$decoded.ToString();if(-not $name){throw 'E04A1_GENERATED_INPUT_UNSUPPORTED_REFERENCE'}
    $path=if([IO.Path]::IsPathFullyQualified($name)){Assert-Path $name}else{Under (Join-Path $Root $name) $Root}
    [void](Need-File $path)
    $prefix=$Root.TrimEnd('\','/')+[IO.Path]::DirectorySeparatorChar
    if(-not $path.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){
        $frozen=@($script:Freeze.files|Where-Object {$_.path -is [string] -and [string]::Equals((Assert-Path $_.path),$path,[StringComparison]::OrdinalIgnoreCase)})
        if($frozen.Count -ne 1){throw 'E04A1_GENERATED_INPUT_EXTERNAL_REFERENCE_NOT_FROZEN'}
        Assert-GeneratedBuildDescriptor @{path=$frozen[0].path;bytes=$frozen[0].bytes;sha256=$frozen[0].sha256}
    }
    return $path
}

function Assert-UnusedCMakeScanMetadata($Block,$Blocks,[string[]]$NinjaFiles,[string]$Owner) {
    if(@($Blocks|Where-Object {$_.name -ceq $Block.name}).Count -ne 1){throw 'E04A1_GENERATED_INPUT_UNSUPPORTED_CMAKE_SCAN_METADATA'}
    $command=[string]$Block.properties.command
    if($Block.name -ceq 'CXX_DYNDEP__yaml-cpp_Release'){
        $expected='"'+$script:Freeze.toolPaths.cmake+'" -E cmake_ninja_dyndep --tdi=CMakeFiles\yaml-cpp.dir\CXXDependInfo.json --lang=CXX --modmapfmt=msvc --dd=$out @$out.rsp'
        if($Block.properties.Count -ne 3 -or $command -cne $expected -or
            $Block.properties.rspfile -cne '$out.rsp' -or $Block.properties.rspfile_content -cne '$in'){throw 'E04A1_GENERATED_INPUT_UNSUPPORTED_CMAKE_SCAN_METADATA'}
    }elseif($Block.name -ceq 'CXX_COMPILER__yaml-cpp_scanned_Release'){
        $ordinary=@($Blocks|Where-Object {$_.name -ceq 'CXX_COMPILER__yaml-cpp_unscanned_Release'})
        $moduleMap=' @$DYNDEP_MODULE_MAP_FILE'
        if($Block.properties.Count -ne 1 -or $ordinary.Count -ne 1 -or
            $ordinary[0].properties.Count -ne 1 -or -not $ordinary[0].properties.ContainsKey('command') -or
            $ordinary[0].properties.command.Contains('@') -or
            [regex]::Matches($command,[regex]::Escape($moduleMap)).Count -ne 1 -or
            $command.Replace($moduleMap,'') -cne $ordinary[0].properties.command){throw 'E04A1_GENERATED_INPUT_UNSUPPORTED_CMAKE_SCAN_METADATA'}
    }else{throw 'E04A1_GENERATED_INPUT_UNSUPPORTED_CMAKE_SCAN_METADATA'}
    $cache=$script:Utf8.GetString([IO.File]::ReadAllBytes((Need-File (Join-Path (Build-Root) 'CMakeCache.txt'))));Safe-Text $cache
    $scanEntries=[regex]::Matches($cache,'(?m)^CMAKE_CXX_SCAN_FOR_MODULES:[^=\r\n]+=([^\r\n]*)\r?$')
    if($scanEntries.Count -ne 1 -or $scanEntries[0].Groups[1].Value -cne 'OFF'){throw 'E04A1_GENERATED_INPUT_CMAKE_SCAN_METADATA_REQUIRES_OFF'}
    [long]$occurrences=0;$rawOwnerDeclaration=$false
    foreach($ninja in @($NinjaFiles|Sort-Object -CaseSensitive)){
        $path=Need-File $ninja
        if(([IO.FileInfo]::new($path)).Length -gt 64MB){throw 'E04A1_GENERATED_INPUT_SIZE'}
        $raw=$script:Utf8.GetString([IO.File]::ReadAllBytes($path));Safe-Text $raw
        $occurrences += [regex]::Matches($raw,[regex]::Escape([string]$Block.name)).Count
        if([string]::Equals($path,$Owner,[StringComparison]::OrdinalIgnoreCase)){
            $rawOwnerDeclaration=[regex]::Matches($raw,('(?m)^rule '+[regex]::Escape([string]$Block.name)+'\r?$')).Count -eq 1
        }
    }
    # Exactly one raw substring globally, demonstrably in this raw declaration.
    # Comments, paths, longer identifiers and every other occurrence refuse.
    if($occurrences -ne 1 -or -not $rawOwnerDeclaration){throw 'E04A1_GENERATED_INPUT_CMAKE_SCAN_RULE_NOT_LITERAL_UNUSED'}
    $rsp=if($Block.properties.ContainsKey('rspfile')){$Block.properties.rspfile}else{''}
    $content=if($Block.properties.ContainsKey('rspfile_content')){$Block.properties.rspfile_content}else{''}
    return ($command+' | rspfile='+$rsp+' | rspfile_content='+$content)
}

function Get-GeneratedBuildInputInventory {
    $root=Build-Root
    $files=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $rootFiles=@(foreach($name in @('CMakeCache.txt','compile_commands.json','build.ninja')){Need-File (Under (Join-Path $root $name) $root)})
    foreach($path in $rootFiles){[void]$files.Add($path)}
    foreach($path in Plain-Files $root){
        if([IO.Path]::GetExtension($path) -in @('.ninja','.cmake') -or [IO.Path]::GetFileName($path) -in @('CMakeCache.txt','compile_commands.json')){
            if(-not $files.Add($path) -and $path -inotIn $rootFiles){throw 'E04A1_GENERATED_INPUT_PATH_COLLISION'}
        }
    }
    $references=[Collections.Generic.List[object]]::new()
    foreach($path in @($files|Sort-Object -CaseSensitive)){
        if([IO.Path]::GetExtension($path) -ine '.ninja'){continue}
        if(([IO.FileInfo]::new($path)).Length -gt 64MB){throw 'E04A1_GENERATED_INPUT_SIZE'}
        $text=$script:Utf8.GetString([IO.File]::ReadAllBytes($path));Safe-Text $text
        # Only Ninja's escaped newline is joined; unresolved path-variable forms refuse.
        $logical=[regex]::Replace($text,'\$\r?\n[ \t]*','')
        $rule='';$properties=@{};$blocks=[Collections.Generic.List[object]]::new()
        foreach($line in ($logical -split '\r?\n')){
            if($line -match '^\s*(?:#|$)'){continue}
            if($line -cmatch '^rule ([A-Za-z0-9_.-]+)$'){
                if($rule){$blocks.Add(@{name=$rule;properties=$properties})};$rule=$Matches[1];$properties=@{};continue
            }
            if($line -cmatch '^\S'){
                if($rule){$blocks.Add(@{name=$rule;properties=$properties});$rule='';$properties=@{}}
            }
            if($rule -and $line -cmatch '^\s+(command|rspfile|rspfile_content)\s*=\s*(.*)$'){
                if($properties.ContainsKey($Matches[1])){throw 'E04A1_GENERATED_INPUT_RULE_PROPERTY_DUPLICATE'}
                $properties[$Matches[1]]=$Matches[2]
            }
            if($line -cmatch '^(include|subninja)\s+(.+)$'){
                $kind=$Matches[1];$target=Resolve-GeneratedBuildReference $Matches[2] $root
                if([IO.Path]::GetExtension($target) -ine '.ninja' -or -not $files.Contains($target)){throw 'E04A1_GENERATED_INPUT_INCLUDE_OUTSIDE_TYPED_CLOSURE'}
                $references.Add([ordered]@{kind=$kind;owner=$path;target=$target;rule='';expression=$line})
            }elseif($line -match '^\s*(?:include|subninja)\b'){throw 'E04A1_GENERATED_INPUT_UNSUPPORTED_REFERENCE'}
            if($line -match '^\s*dyndep\s*='){throw 'E04A1_GENERATED_INPUT_UNSUPPORTED_DYNDEP'}
            if($line -cmatch '^\s*(?:command|COMMAND|PRE_LINK|POST_BUILD)\s*=\s*(.*)$'){
                $command=$Matches[1]
                foreach($m in [regex]::Matches($command,'(?:^|\s)-P\s+("[^"]+"|[^\s"&|]+)')){
                    $target=Resolve-GeneratedBuildReference $m.Groups[1].Value $root
                    if([IO.Path]::GetExtension($target) -ine '.cmake'){throw 'E04A1_GENERATED_INPUT_UNSUPPORTED_SCRIPT'}
                    [void]$files.Add($target);$references.Add([ordered]@{kind='cmake-P';owner=$path;target=$target;rule=$rule;expression=$m.Value})
                    $scriptText=$script:Utf8.GetString([IO.File]::ReadAllBytes($target));Safe-Text $scriptText
                    # Positive bounded script grammar: no user-defined commands or hidden
                    # script-reading primitives. Ambiguous literals may conservatively refuse.
                    foreach($call in [regex]::Matches($scriptText,'(?i)(?<![A-Za-z0-9_])([A-Za-z_][A-Za-z0-9_]*)\s*\(')){
                        if($call.Groups[1].Value -inotIn @('cmake_policy','file','set','if','message','endif')){throw 'E04A1_GENERATED_INPUT_UNSUPPORTED_CMAKE_SCRIPT_COMMAND'}
                        if($call.Groups[1].Value -ieq 'file' -and $scriptText.Substring($call.Index+$call.Length) -notmatch '(?i)^\s*(?:GLOB_RECURSE|GLOB|TOUCH_NOCREATE)(?:\s|\))'){throw 'E04A1_GENERATED_INPUT_UNSUPPORTED_CMAKE_SCRIPT_REFERENCE'}
                    }
                    foreach($call in [regex]::Matches($scriptText,'(?i)\bfile\s*\(\s*([A-Za-z_][A-Za-z0-9_]*)')){
                        if($call.Groups[1].Value -inotIn @('GLOB','GLOB_RECURSE','TOUCH_NOCREATE')){throw 'E04A1_GENERATED_INPUT_UNSUPPORTED_CMAKE_SCRIPT_REFERENCE'}
                    }
                    if($scriptText -match '(?i)\b(?:include|execute_process|cmake_language|add_subdirectory|configure_file)\s*\(' -or
                        $scriptText -match '(?i)\bfile\s*\(\s*(?:READ|STRINGS|MD5|SHA[0-9]+|DOWNLOAD|UPLOAD|COPY|INSTALL|CONFIGURE|GENERATE)\b'){throw 'E04A1_GENERATED_INPUT_UNSUPPORTED_CMAKE_SCRIPT_REFERENCE'}
                }
                foreach($m in [regex]::Matches($command,'(?i)"[^"]+\.(?:bat|cmd|ps1)"|[^\s"&|]+\.(?:bat|cmd|ps1)')){
                    $target=Resolve-GeneratedBuildReference $m.Value $root;[void]$files.Add($target)
                    $references.Add([ordered]@{kind='command-script';owner=$path;target=$target;rule=$rule;expression=$m.Value})
                    # Never guess transitive semantics of a generated shell/PowerShell script.
                    throw 'E04A1_GENERATED_INPUT_UNSUPPORTED_COMMAND_SCRIPT'
                }
            }
        }
        if($rule){$blocks.Add(@{name=$rule;properties=$properties})}
        foreach($block in $blocks){
            if($block.name -cin @('CXX_DYNDEP__yaml-cpp_Release','CXX_COMPILER__yaml-cpp_scanned_Release')){
                $expression=Assert-UnusedCMakeScanMetadata $block @($blocks) @($files|Where-Object {[IO.Path]::GetExtension($_) -ieq '.ninja'}) $path
                $references.Add([ordered]@{kind='unused-cmake-rule-metadata';owner=$path;target='';rule=$block.name;expression=$expression})
                continue
            }
            if(-not $block.properties.ContainsKey('command')){continue}
            foreach($m in [regex]::Matches($block.properties.command,'@("[^"]+"|[^\s"&|]+)')){
                $arg=$m.Groups[1].Value.Trim('"')
                if($arg -cin @('$RSP_FILE','${RSP_FILE}')){
                    if(-not $block.properties.ContainsKey('rspfile') -or -not $block.properties.ContainsKey('rspfile_content') -or
                        $block.properties.rspfile -cne $arg -or -not $block.properties.rspfile_content){throw 'E04A1_GENERATED_INPUT_UNSUPPORTED_RESPONSE'}
                    $references.Add([ordered]@{kind='ninja-produced-response';owner=$path;target='';rule=$block.name;expression=($arg+' | '+$block.properties.rspfile_content)})
                }else{
                    # Only Ninja-produced response files have a supported grammar here.
                    # Refuse literal argument files rather than infer recursive tool semantics.
                    throw 'E04A1_GENERATED_INPUT_UNSUPPORTED_PREEXISTING_RESPONSE'
                }
            }
        }
        # An @ argument outside the recognized rule-command form must not be ignored.
        foreach($line in ($logical -split '\r?\n')){if($line -match '^\s*(?:#|$)'){continue};if($line.Contains('@') -and $line -cnotmatch '^\s*command\s*='){throw 'E04A1_GENERATED_INPUT_UNSUPPORTED_RESPONSE_CONTEXT'}}
    }
    return @{files=@($files|Sort-Object -CaseSensitive);references=@($references)}
}

function Copy-GeneratedBuildInput([string]$Source,[string]$Destination) {
    $before=Descriptor $Source
    if($before.bytes -gt 64MB){throw 'E04A1_GENERATED_INPUT_SIZE_PRESERVE_ORIGINAL'}
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName((Under $Destination $script:RunRoot)))
    [IO.File]::Copy((Need-File $Source),$Destination,$false)
    $copy=Descriptor $Destination;$after=Descriptor $Source
    if($before.bytes -ne $after.bytes -or $before.sha256 -ine $after.sha256 -or $copy.bytes -ne $before.bytes -or $copy.sha256 -ine $before.sha256){throw 'E04A1_GENERATED_INPUT_CHANGED_DURING_COPY'}
    return @{live=$before;retainedCopy=$copy}
}

function Capture-ConfiguredBuildInputs($CheckedConfigure,$ConfigureProcess) {
    if($CheckedConfigure -isnot [Collections.IDictionary]){throw 'E04A1_GENERATED_INPUT_CONFIGURE_TYPE'}
    $rootNames=@{cache='CMakeCache.txt';compileCommands='compile_commands.json';ninja='build.ninja'}
    foreach($key in $rootNames.Keys){Assert-GeneratedBuildDescriptor $CheckedConfigure[$key];if(-not [string]::Equals((Assert-Path $CheckedConfigure[$key].path),(Under (Join-Path (Build-Root) $rootNames[$key]) (Build-Root)),[StringComparison]::OrdinalIgnoreCase)){throw 'E04A1_GENERATED_INPUT_CONFIGURE_ROOT_PATH'}}
    Assert-GeneratedBuildDescriptor $ConfigureProcess
    if(-not [string]::Equals((Assert-Path $ConfigureProcess.path),(Owned 'dependencyconfigure/a1g-cmake-configure.process.json'),[StringComparison]::OrdinalIgnoreCase)){throw 'E04A1_GENERATED_INPUT_CONFIGURE_PROCESS_PATH'}
    $store=Owned 'logs/configured-build-inputs';New-Directory $store
    $records=[Collections.Generic.List[object]]::new()
    try{
        # Copy the typed inputs first, so unsupported reference syntax also retains its bytes.
        $copied=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase);$n=0
        foreach($path in @(Plain-Files (Build-Root)|Where-Object {[IO.Path]::GetExtension($_) -in @('.ninja','.cmake') -or [IO.Path]::GetFileName($_) -in @('CMakeCache.txt','compile_commands.json')})){
            $n++;$records.Add((Copy-GeneratedBuildInput $path (Join-Path $store ('files/{0:D6}.input' -f $n))));[void]$copied.Add($path)
        }
        $inventory=Get-GeneratedBuildInputInventory
        foreach($path in $inventory.files){if($copied.Add($path)){$n++;$records.Add((Copy-GeneratedBuildInput $path (Join-Path $store ('files/{0:D6}.input' -f $n))))}}
        $manifest=@{schemaVersion=1;kind='E04A1_CONFIGURED_BUILD_INPUT_CLOSURE';status='CAPTURED';runId=$RunId;sourceHead=$script:Freeze.sourceHead;freezeManifest=Descriptor $FreezeManifestPath;buildRoot=Build-Root;configureProcess=$ConfigureProcess;configureRoots=@{cache=$CheckedConfigure.cache;compileCommands=$CheckedConfigure.compileCommands;ninja=$CheckedConfigure.ninja};records=@($records);references=$inventory.references;limits='Typed generated input identity, not general Ninja/CMake interpretation, atomic launch or universal TOCTOU protection.'}
        $path=Join-Path $store 'manifest.json';Write-JsonNew $path $manifest;return Descriptor $path
    }catch{
        $primary=$_
        try{Write-JsonNew (Join-Path $store 'capture-failure.json') @{kind='E04A1_GENERATED_INPUT_CAPTURE_FAILED';runId=$RunId;sourceHead=$script:Freeze.sourceHead;retainedPartialRecords=@($records);primaryFailure=Failure $primary 'generated-input-capture';limits='Partial files preserved; no Configure success or build release.'}}catch{$script:Errors.Add((Failure $_ 'generated-input-capture-evidence'))}
        throw $primary
    }
}

function Read-ConfiguredBuildInputBaseline {
    $completion=Read-Json (Owned 'dependencyconfigure/completion.json')
    foreach($key in @('phase','state','runId','sourceHead','freezeManifestSha256','subset','runtimeCallerProof')){if($completion[$key] -isnot [string]){throw 'E04A1_GENERATED_INPUT_PREDECESSOR_TYPE'}}
    if(($completion.schemaVersion -isnot [int] -and $completion.schemaVersion -isnot [long]) -or $completion.schemaVersion -ne 1 -or $completion.executionPassed -isnot [bool] -or -not $completion.executionPassed -or
        $completion.phase -cne 'DependencyConfigure' -or $completion.state -cne 'COMPLETE' -or $completion.runId -cne $RunId -or $completion.sourceHead -cne $script:Freeze.sourceHead -or
        $completion.subset -cne $script:Subset -or $completion.runtimeCallerProof -cne $script:RuntimeCallerProof -or $completion.freezeManifestSha256 -ine (Digest $FreezeManifestPath)){throw 'E04A1_GENERATED_INPUT_SAME_RUN_CONFIGURE_REQUIRED'}
    Assert-GeneratedBuildDescriptor $completion.result
    if(-not [string]::Equals((Assert-Path $completion.result.path),(Owned 'dependencyconfigure/result.json'),[StringComparison]::OrdinalIgnoreCase)){throw 'E04A1_GENERATED_INPUT_PREDECESSOR_PATH'}
    $result=Read-Json $completion.result.path
    foreach($key in @('phase','runId','sourceHead','subset','runtimeCallerProof')){if($result[$key] -isnot [string]){throw 'E04A1_GENERATED_INPUT_PREDECESSOR_TYPE'}}
    if(($result.schemaVersion -isnot [int] -and $result.schemaVersion -isnot [long]) -or $result.schemaVersion -ne 1 -or
        $result.executionPassed -isnot [bool] -or -not $result.executionPassed -or $result.phase -cne 'DependencyConfigure' -or $result.runId -cne $RunId -or
        $result.sourceHead -cne $script:Freeze.sourceHead -or $result.subset -cne $script:Subset -or $result.runtimeCallerProof -cne $script:RuntimeCallerProof -or $result.configure -isnot [Collections.IDictionary]){throw 'E04A1_GENERATED_INPUT_SAME_RUN_CONFIGURE_REQUIRED'}
    $descriptor=$result.configure.generatedBuildInputs;Assert-GeneratedBuildDescriptor $descriptor
    if(-not [string]::Equals((Assert-Path $descriptor.path),(Owned 'logs/configured-build-inputs/manifest.json'),[StringComparison]::OrdinalIgnoreCase)){throw 'E04A1_GENERATED_INPUT_BASELINE_PATH'}
    $manifest=Read-Json $descriptor.path
    Require-GeneratedBuildKeys $manifest @('schemaVersion','kind','status','runId','sourceHead','freezeManifest','buildRoot','configureProcess','configureRoots','records','references','limits')
    foreach($key in @('kind','status','runId','sourceHead','buildRoot','limits')){if($manifest[$key] -isnot [string]){throw 'E04A1_GENERATED_INPUT_MANIFEST_TYPE'}}
    if(($manifest.schemaVersion -isnot [int] -and $manifest.schemaVersion -isnot [long]) -or $manifest.schemaVersion -ne 1 -or $manifest.kind -cne 'E04A1_CONFIGURED_BUILD_INPUT_CLOSURE' -or $manifest.status -cne 'CAPTURED' -or
        $manifest.runId -cne $RunId -or $manifest.sourceHead -cne $script:Freeze.sourceHead -or -not [string]::Equals((Assert-Path $manifest.buildRoot),(Build-Root),[StringComparison]::OrdinalIgnoreCase) -or
        $manifest.records -isnot [Collections.IList] -or -not $manifest.records.Count -or $manifest.references -isnot [Collections.IList]){throw 'E04A1_GENERATED_INPUT_MANIFEST_TYPE'}
    Assert-GeneratedBuildDescriptor $manifest.freezeManifest
    if(-not [string]::Equals((Assert-Path $manifest.freezeManifest.path),(Assert-Path $FreezeManifestPath),[StringComparison]::OrdinalIgnoreCase)){throw 'E04A1_GENERATED_INPUT_FREEZE_PATH'}
    Assert-GeneratedBuildDescriptor $manifest.configureProcess
    if(-not [string]::Equals((Assert-Path $manifest.configureProcess.path),(Owned 'dependencyconfigure/a1g-cmake-configure.process.json'),[StringComparison]::OrdinalIgnoreCase)){throw 'E04A1_GENERATED_INPUT_CONFIGURE_PROCESS_PATH'}
    if($result.processes -isnot [Collections.IList] -or $result.processes.Count -ne 1 -or $result.processes[0] -isnot [Collections.IDictionary]){throw 'E04A1_GENERATED_INPUT_CONFIGURE_PROCESS_BINDING'}
    Assert-GeneratedBuildDescriptor $result.processes[0].receiptArtifact
    if(($result.processes[0].receiptArtifact|ConvertTo-Json -Compress) -cne ($manifest.configureProcess|ConvertTo-Json -Compress)){throw 'E04A1_GENERATED_INPUT_CONFIGURE_PROCESS_BINDING'}
    Require-GeneratedBuildKeys $manifest.configureRoots @('cache','compileCommands','ninja')
    foreach($reference in $manifest.references){
        Require-GeneratedBuildKeys $reference @('kind','owner','target','rule','expression')
        foreach($key in @('kind','owner','target','rule','expression')){if($reference[$key] -isnot [string]){throw 'E04A1_GENERATED_INPUT_REFERENCE_TYPE'}}
        if($reference.kind -cnotin @('include','subninja','cmake-P','ninja-produced-response','unused-cmake-rule-metadata')){throw 'E04A1_GENERATED_INPUT_REFERENCE_TYPE'}
        if(-not $reference.owner -or ($reference.kind -cnotin @('ninja-produced-response','unused-cmake-rule-metadata') -and -not $reference.target)){throw 'E04A1_GENERATED_INPUT_REFERENCE_TYPE'}
        if($reference.kind -ceq 'unused-cmake-rule-metadata' -and ($reference.target -cne '' -or
            $reference.rule -cnotin @('CXX_DYNDEP__yaml-cpp_Release','CXX_COMPILER__yaml-cpp_scanned_Release') -or -not $reference.expression)){throw 'E04A1_GENERATED_INPUT_REFERENCE_TYPE'}
    }
    foreach($key in @('cache','compileCommands','ninja')){
        Assert-GeneratedBuildDescriptor $manifest.configureRoots[$key] -IdentityOnly;Assert-GeneratedBuildDescriptor $result.configure[$key] -IdentityOnly
        if(($manifest.configureRoots[$key]|ConvertTo-Json -Compress) -cne ($result.configure[$key]|ConvertTo-Json -Compress)){throw 'E04A1_GENERATED_INPUT_CONFIGURE_ROOT_BINDING'}
    }
    return @{descriptor=$descriptor;manifest=$manifest;configureResult=$completion.result}
}

function Confirm-ConfiguredBuildInputs([switch]$AfterBuild) {
    $label=if($AfterBuild){'postbuild'}else{'prelaunch'}
    $store=Owned ('logs/configured-build-input-'+$label);New-Directory $store
    $observed=[Collections.Generic.List[object]]::new();$baseline=$null;$missing=@();$unexpected=@();$drift=@()
    try{
        $baseline=Read-ConfiguredBuildInputBaseline
        $expected=[Collections.Generic.Dictionary[string,object]]::new([StringComparer]::OrdinalIgnoreCase)
        foreach($record in $baseline.manifest.records){
            Require-GeneratedBuildKeys $record @('live','retainedCopy');Assert-GeneratedBuildDescriptor $record.live -IdentityOnly;Assert-GeneratedBuildDescriptor $record.retainedCopy -IdentityOnly
            [void](Under $record.retainedCopy.path (Owned 'logs/configured-build-inputs/files'))
            if(-not $expected.TryAdd((Assert-Path $record.live.path),$record)){throw 'E04A1_GENERATED_INPUT_BASELINE_DUPLICATE'}
            # Preserve a corrupt retained copy before refusing it.
            $copyActual=Descriptor $record.retainedCopy.path
            if($copyActual.bytes -ne $record.live.bytes -or $copyActual.sha256 -ine $record.live.sha256 -or
                $copyActual.bytes -ne $record.retainedCopy.bytes -or $copyActual.sha256 -ine $record.retainedCopy.sha256){
                $drift+=@{kind='retained-copy';expected=$record.retainedCopy;actual=$copyActual}
                [void](Copy-GeneratedBuildInput $record.retainedCopy.path (Join-Path $store ('corrupt-copy-{0:D6}.input' -f $expected.Count)))
                throw 'E04A1_GENERATED_INPUT_RETAINED_COPY_DRIFT'
            }
        }
        # Preserve typed current files even if later reference recognition refuses.
        $typed=@(Plain-Files (Build-Root)|Where-Object {[IO.Path]::GetExtension($_) -in @('.ninja','.cmake') -or [IO.Path]::GetFileName($_) -in @('CMakeCache.txt','compile_commands.json')})
        $n=0;foreach($path in $typed){$n++;$observed.Add((Copy-GeneratedBuildInput $path (Join-Path $store ('files/{0:D6}.input' -f $n))))}
        foreach($path in $expected.Keys){if(-not [IO.File]::Exists($path)){$missing+=$path}}
        if($missing.Count){throw 'E04A1_GENERATED_INPUT_LIVE_MEMBER_MISSING'}
        $inventory=Get-GeneratedBuildInputInventory
        # Retain discovered argument/script inputs before membership/byte refusal too.
        foreach($path in $inventory.files){if($path -inotIn $typed){$n++;$observed.Add((Copy-GeneratedBuildInput $path (Join-Path $store ('files/{0:D6}.input' -f $n))))}}
        $unexpected=@($inventory.files|Where-Object {-not $expected.ContainsKey($_)})
        if($inventory.files.Count -ne $expected.Count){throw 'E04A1_GENERATED_INPUT_LIVE_MEMBERSHIP_DRIFT'}
        foreach($path in $inventory.files){
            if(-not $expected.ContainsKey($path)){throw 'E04A1_GENERATED_INPUT_LIVE_MEMBERSHIP_DRIFT'}
            $actual=Descriptor $path;$record=$expected[$path]
            if($actual.bytes -ne $record.live.bytes -or $actual.sha256 -ine $record.live.sha256){$drift+=@{kind='live-input';expected=$record.live;actual=$actual};throw 'E04A1_GENERATED_INPUT_LIVE_BYTE_DRIFT'}
        }
        if(($inventory.references|ConvertTo-Json -Depth 10 -Compress) -cne ($baseline.manifest.references|ConvertTo-Json -Depth 10 -Compress)){throw 'E04A1_GENERATED_INPUT_REFERENCE_DRIFT'}
        foreach($key in @('cache','compileCommands','ninja')){Assert-GeneratedBuildDescriptor $baseline.manifest.configureRoots[$key]}
        $receipt=Join-Path $store 'observed.json'
        Write-JsonNew $receipt @{kind='E04A1_GENERATED_INPUT_CONFIRMED';runId=$RunId;sourceHead=$script:Freeze.sourceHead;stage=$label;baseline=$baseline.descriptor;configureResult=$baseline.configureResult;observed=@($observed);references=$inventory.references;limits='Immediate synchronous before/after identity observations, not atomic launch or universal TOCTOU/lineage proof.'}
        return Descriptor $receipt
    }catch{
        $primary=$_
        try{Write-JsonNew (Join-Path $store 'failure.json') @{kind='E04A1_GENERATED_INPUT_CONFIRM_FAILED';runId=$RunId;sourceHead=$script:Freeze.sourceHead;stage=$label;baseline=$(if($null -ne $baseline){$baseline.descriptor}else{$null});missing=$missing;unexpected=$unexpected;drift=$drift;observedPartial=@($observed);primaryFailure=Failure $primary 'generated-input-confirm';limits='No prelaunch release; preserve missing/extra/drift evidence and all partial copies without rebaselining.'}}catch{$script:Errors.Add((Failure $_ 'generated-input-confirm-evidence'))}
        throw $primary
    }
}

function Retain-GeneratedBuildInputPartials {
    $store=Owned ('logs/configured-build-input-partials-'+$Phase.ToLowerInvariant());New-Directory $store
    $records=[Collections.Generic.List[object]]::new();$errors=[Collections.Generic.List[object]]::new();$root=Build-Root;$n=0
    if([IO.Directory]::Exists($root)){
        foreach($path in @(Plain-Files $root|Where-Object {[IO.Path]::GetExtension($_) -in @('.ninja','.cmake','.rsp') -or [IO.Path]::GetFileName($_) -in @('CMakeCache.txt','compile_commands.json')})){
            $n++;$entry=@{live=$null;retainedCopy=$null;failure=$null}
            try{$entry.live=Descriptor $path;$copy=Copy-GeneratedBuildInput $path (Join-Path $store ('files/{0:D6}.input' -f $n));$entry.retainedCopy=$copy.retainedCopy}
            catch{$entry.failure=Failure $_ 'generated-input-partial-copy';$errors.Add($entry.failure)}
            $records.Add($entry)
        }
    }
    $path=Join-Path $store 'retention.json';Write-JsonNew $path @{kind='E04A1_GENERATED_INPUT_FAILED_PHASE_PARTIALS';phase=$Phase;runId=$RunId;sourceHead=$script:Freeze.sourceHead;buildRoot=$root;buildRootPresent=[IO.Directory]::Exists($root);records=@($records);copyErrors=@($errors);limits='Failed-phase partial evidence only. Oversize/unreadable originals remain untouched at recorded live paths; no successful Configure/build or complete closure is inferred.'}
    return Descriptor $path
}

function Build-Root { Owned 'vendor-build/Win64/Release/x64' }
function Artifact-Root { Owned 'vendor-artifact/Win64/Release/x64' }
function Equal-Data($Left,$Right,[string]$Label){
    if(($Left|ConvertTo-Json -Depth 80 -Compress) -cne ($Right|ConvertTo-Json -Depth 80 -Compress)){throw ('A1G_DATA_CHANGED: '+$Label)}
}
function Snapshot-Members([string]$Root,$Members){
    $observed=@(foreach($m in $Members){$p=Under (Join-Path $Root $m.path) $Root;$d=Descriptor $p
        if($d.bytes -ne $m.bytes -or $d.sha256 -ine $m.sha256){throw ('A1G_AUTHORED_SOURCE_DRIFT: '+$m.path)}
        [ordered]@{path=$m.path;bytes=$d.bytes;sha256=$d.sha256}})
    $catalog=@(Snapshot-Source $Root)
    if((@($catalog.path|Sort-Object -CaseSensitive)-join "`n") -cne (@($Members.path|Sort-Object -CaseSensitive)-join "`n")){throw 'A1G_AUTHORED_SOURCE_MEMBERSHIP_CHANGED'}
    $observed
}
function Snapshot-Inputs {
    @(foreach($d in $script:Freeze.fixtureInputs){Check-Descriptor $d})
}
function Check-Storage([switch]$Initial){
    $drive=[IO.DriveInfo]::new([IO.Path]::GetPathRoot($script:RunRoot))
    if($drive.AvailableFreeSpace -lt $(if($Initial){50GB}else{20GB})){throw 'A1G_FREE_SPACE_PREREQUISITE_OR_FLOOR'}
    if(-not [IO.Directory]::Exists($script:RunRoot)){return}
    $total=0L;$reports=0L;$cook=0L;$stage=0L
    foreach($p in Plain-Files $script:RunRoot){$bytes=([IO.FileInfo]::new($p)).Length;$total+=$bytes
        if($p.StartsWith((Owned 'reports')+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){$reports+=$bytes}
        if($p.StartsWith((Owned 'cook')+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){$cook+=$bytes}
        if($p.StartsWith((Owned 'stage')+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){$stage+=$bytes}}
    if($total -gt 24GB -or $cook -gt 8GB -or $stage -gt 8GB -or $reports -gt 512MB){throw 'A1G_RETAINED_STORAGE_CAP_PRESERVE_OUTPUTS'}
    [ordered]@{observedUtc=[DateTime]::UtcNow.ToString('o');runBytes=$total;reportBytes=$reports;cookBytes=$cook;stageBytes=$stage;availableFreeSpace=$drive.AvailableFreeSpace;qualification='Synchronous operation-boundary observations; not a live filesystem quota.'}
}
function Check-Bindings {
    if((Digest $FreezeManifestPath) -ine $ExpectedFreezeSha256 -or (Digest $AuthorityPath) -ine $ExpectedAuthoritySha256){throw 'A1G_INPUT_IDENTITY_DRIFT'}
    $f=Read-Json $FreezeManifestPath;$a=Read-Json $AuthorityPath
    if($f.schemaVersion -ne 1 -or $f.experiment -cne 'E04-A1G' -or $f.runId -cne $RunId -or $f.sourceHead -cnotmatch '^[0-9a-f]{40}$' -or (Assert-Path $f.sourceRoot) -ine $script:Repo){throw 'A1G_FRESH_FREEZE_REQUIRED'}
    if($a.schemaVersion -ne 1 -or $a.experiment -cne 'E04-A1G' -or $a.runId -cne $RunId -or $a.sourceHead -cne $f.sourceHead -or $a.explicitRootGo -ne $true -or @($a.allowedPhases).Count -ne 1 -or $a.allowedPhases[0] -cne $Phase -or $a.freezeManifestSha256 -ine $ExpectedFreezeSha256 -or $a.visibleWindows -ne 0){throw 'A1G_EXACT_SINGLE_PHASE_GO_REQUIRED'}
    if($a.sourceReviewed.status -cne 'PASS_ADMITTED' -or $a.sourceReviewed.sourceHead -cne $f.sourceHead -or $a.sourceReviewed.runId -cne $RunId -or $a.sourceReviewed.freezeManifestSha256 -ine $ExpectedFreezeSha256){throw 'A1G_FRESH_AFFECTED_SOURCE_ADMISSION_REQUIRED'}
    $expectedRootLimit=if($Phase -in @('Preflight','Audit')){0}else{1}
    if($a.phaseBudgetSeconds -ne $script:Budgets[$Phase] -or $a.expectedSupervisedRoots -ne $expectedRootLimit){throw 'A1G_EXACT_PHASE_GO_BOUNDS_REQUIRED'}
    if($a.specialAssuranceCertification -cne 'DEFERRED_UNPROVEN_OWN17' -or $a.sourceReviewed.specialAssuranceCertification -cne 'DEFERRED_UNPROVEN_OWN17'){throw 'A1G_FOCUSED_OWN17_DEFERRAL_REQUIRED'}
    $norm=Check-Descriptor $f.normativeRequirement
    foreach($bound in @($a.normativeRequirement,$a.sourceReviewed.normativeRequirement)){
        if($bound.path -ine $norm.path -or $bound.bytes -ne $norm.bytes -or $bound.sha256 -ine $norm.sha256){throw 'A1G_CURRENT_NORM_BINDING_REQUIRED'}
    }
    if($f.ownedWindowObserver.entryPoint -cne 'RunWithOwnedJobWindowObservation' -or $f.ownedWindowObserver.sampleIntervalMilliseconds -ne 500){throw 'A1G_EXPLICIT_OPT_IN_OBSERVER_SELECTION_REQUIRED'}
    if($f.sourceMembership -isnot [array] -or -not $f.sourceMembership.Count -or $f.stageCopies -isnot [array] -or -not $f.stageCopies.Count -or $f.stageMembership -isnot [array] -or $f.stageMembership.Count -ne $f.stageCopies.Count){throw 'A1G_EXACT_CANONICAL_AND_OWNED_STAGE_INPUTS_REQUIRED'}
    foreach($d in $f.files){[void](Check-Descriptor $d)}
    foreach($path in @($PSCommandPath,[Environment]::ProcessPath,$f.supervisorSource.path)+@($f.toolPaths.Values)){
        $actual=Descriptor $path;$found=@($f.files|Where-Object {$_.path -ieq $actual.path -and $_.bytes -eq $actual.bytes -and $_.sha256 -ieq $actual.sha256})
        if($found.Count -ne 1){throw 'A1G_RUNTIME_TOOL_OR_WRAPPER_NOT_UNIQUELY_FROZEN'}}
    if($f.supervisorSource.sha256 -ine 'F4BF73355ECCEB727DBE23E60FB21B61A29C424776F7C7938EA946F18826E32C' -or $f.supervisorSource.bytes -ne 41523){throw 'A1G_EXACT_OPT_IN_SUPERVISOR_SOURCE_REQUIRED'}
    if($f.bounds.streamBytes -ne 64MB -or $f.bounds.dataBytes -ne 64MB -or $f.bounds.reportBytes -ne 512MB -or $f.bounds.initialFreeBytes -ne 50GB -or $f.bounds.freeFloorBytes -ne 20GB -or $f.bounds.runBytes -ne 24GB -or $f.bounds.cookBytes -ne 8GB -or $f.bounds.stageBytes -ne 8GB){throw 'A1G_EXACT_PROPOSED_BOUNDS_REQUIRED'}
    $script:Freeze=$f
    [ordered]@{authority=(Descriptor $AuthorityPath);sourceReviewed=$a.sourceReviewed;phase=$Phase;visibleWindows=0}
}
function Check-Dependency {
    $script:AcquisitionDescriptor=Check-Descriptor $script:Freeze.dependency.acquisitionResult
    $script:Dependency=Read-Json $script:AcquisitionDescriptor.path
    $script:VendorRoot=Assert-Path $script:Freeze.dependency.vendorSourceRoot
    if($script:Dependency.pin -cne '56e3bb550c91fd7005566f19c079cb7a503223cf' -or $script:Dependency.preparationId -cne $script:Freeze.dependency.preparationId -or $script:Dependency.status -cne 'ACQUIRED_PIN_AND_BYTES_VERIFIED_NOT_BUILD_OR_SOURCE_APPROVAL' -or -not $script:Dependency.allCheckoutBytesMatchPinnedBlobs -or $script:Dependency.dependencySourceExecuted -or $script:Dependency.buildReleased){throw 'A1G_PINNED_SOURCE_ACQUISITION_REQUIRED'}
    $expectedRoot=Join-Path $script:Repo ('.local/dependencies/E04A1/'+$script:Dependency.preparationId+'/yaml-cpp')
    if($script:VendorRoot -ine (Assert-Path $expectedRoot)){throw 'A1G_VENDOR_SOURCE_PATH_MISMATCH'}
    foreach($file in $script:Dependency.files){$actual=Descriptor (Under (Join-Path $script:VendorRoot $file.path) $script:VendorRoot);if($actual.bytes -ne $file.bytes -or $actual.sha256 -ine $file.sha256){throw 'A1G_PINNED_VENDOR_BYTES_CHANGED'}}
    $expectedHeaders=@($script:Dependency.files|Where-Object {$_.path.StartsWith('include/',[StringComparison]::Ordinal)}|ForEach-Object {$_.path.Substring(8)}|Sort-Object -CaseSensitive)
    $includeRoot=Join-Path $script:VendorRoot 'include';$actualHeaders=@(Plain-Files $includeRoot|ForEach-Object {[IO.Path]::GetRelativePath($includeRoot,$_).Replace('\','/')}|Sort-Object -CaseSensitive)
    if(($expectedHeaders -join "`n") -cne ($actualHeaders -join "`n")){throw 'A1G_PINNED_HEADER_MEMBERSHIP_CHANGED'}
}
function Check-Previous {
    $links=[Collections.Generic.List[object]]::new();$index=[Array]::IndexOf($script:Order,$Phase)
    for($i=0;$i -lt $index;$i++){
        $name=$script:Order[$i];$completion=Read-Json (Owned ($name.ToLowerInvariant()+'/completion.json'))
        if($completion.phase -cne $name -or $completion.state -cne 'COMPLETE' -or $completion.executionPassed -ne $true -or $completion.runId -cne $RunId -or $completion.sourceHead -cne $script:Freeze.sourceHead -or $completion.freezeManifestSha256 -ine $ExpectedFreezeSha256){throw 'A1G_SAME_RUN_ORDERED_PREDECESSOR_REQUIRED'}
        [void](Check-Descriptor $completion.result);$result=Read-Json $completion.result.path
        if($result.executionPassed -ne $true -or $null -ne $result.primaryFailure -or @($result.secondaryErrors).Count -or $result.phase -cne $name -or $result.runId -cne $RunId -or $result.sourceHead -cne $script:Freeze.sourceHead){throw 'A1G_PREDECESSOR_FAILED_OR_UNCLOSED'}
        foreach($d in $result.retainedArtifacts){[void](Check-Descriptor $d)}
        foreach($p in $result.processes){Require-RootPass $p}
        $links.Add([ordered]@{phase=$name;completion=(Descriptor (Owned ($name.ToLowerInvariant()+'/completion.json')));result=$completion.result})
    };$links.ToArray()
}
function Materialize-Stage {
    foreach($name in @('project','logs','reports','artifacts','fixtures','temp','dotnet-home','nuget','uba','ddc','ue-user','shader-work')){[void][IO.Directory]::CreateDirectory((Owned $name))}
    $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach($copy in $script:Freeze.stageCopies){
        if($copy.relativePath -notmatch '^[A-Za-z0-9_./-]+$' -or @($copy.relativePath.Split('/')|Where-Object {$_ -in @('','.','..')}).Count -or -not $seen.Add($copy.relativePath)){throw 'A1G_INVALID_OR_COLLIDING_STAGE_MEMBER'}
        $source=Check-Descriptor $copy.source;$target=Under (Join-Path $script:Stage $copy.relativePath) $script:Stage
        [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target));[IO.File]::Copy($source.path,$target,$false)
        $actual=Descriptor $target;if($actual.bytes -ne $source.bytes -or $actual.sha256 -ine $source.sha256){throw 'A1G_STAGE_COPY_IDENTITY'}
    }
    [void](Snapshot-Members $script:Stage $script:Freeze.stageMembership)
    $plugin=Read-Json (Join-Path $script:Stage 'Plugins/E04ProfileProof/E04ProfileProof.uplugin')
    $project=Read-Json (Join-Path $script:Stage 'WarhammerClient.uproject')
    if($plugin.EnabledByDefault -ne $false -or $plugin.CanContainContent -ne $false -or @($project.Plugins|Where-Object {$_.Name -ceq 'E04ProfileProof' -and $_.Enabled}).Count){throw 'A1G_EDITOR_COOK_PLUGIN_MUST_REMAIN_DISABLED'}
    $engineConfig=$script:Utf8.GetString([IO.File]::ReadAllBytes((Join-Path $script:Stage 'Config/DefaultEngine.ini')))
    $gameConfig=$script:Utf8.GetString([IO.File]::ReadAllBytes((Join-Path $script:Stage 'Config/DefaultGame.ini')))
    foreach($text in @('DefaultGameTarget=WarhammerClientE04A1G','DefaultEditorTarget=WarhammerClientEditor','GameDefaultMap=/Engine/Maps/Entry','ServerDefaultMap=/Engine/Maps/Entry','GlobalDefaultGameMode=/Script/Engine.GameModeBase','LocalMapOptions=')){if($engineConfig -notmatch ('(?m)^'+[regex]::Escape($text)+'\r?$')){throw 'A1G_OWNED_STARTUP_CONFIGURATION_MISSING'}}
    foreach($text in @('UsePakFile=False','bUseIoStore=False','bUseZenStore=False')){if($gameConfig -notmatch ('(?m)^'+[regex]::Escape($text)+'\r?$')){throw 'A1G_OWNED_LOOSE_STORE_CONFIGURATION_MISSING'}}
}
function Invoke-A1GRoot([string]$Label,[string]$Executable,[string[]]$Arguments,[string]$WorkingDirectory,[hashtable]$Extra=@{}){
    if($Phase -in @('Preflight','Audit') -or $script:RootCount -ne 0){throw 'A1G_EXACT_SINGLE_ROOT_LIMIT'}
    [void](Check-Storage);$exe=Need-File $Executable;$cwd=Assert-Path $WorkingDirectory
    $frozen=@($script:Freeze.files|Where-Object {$_.path -ieq $exe});if($frozen.Count -ne 1){throw 'A1G_EXECUTABLE_NOT_UNIQUELY_FROZEN'};[void](Check-Descriptor $frozen[0])
    foreach($arg in $Arguments){Safe-Text $arg;if($arg.Contains([char]0) -or $arg.Contains("`r") -or $arg.Contains("`n")){throw 'A1G_NATIVE_ARGUMENT_CONTROL_CHARACTER'}}
    $out=Owned ('logs/'+$Label+'.stdout.log');$err=Owned ('logs/'+$Label+'.stderr.log')
    foreach($p in @($out,$err)){if(Test-Path -LiteralPath $p){throw 'A1G_NATIVE_OUTPUT_COLLISION'}}
    $saved=@{};foreach($entry in [Environment]::GetEnvironmentVariables('Process').GetEnumerator()){
        if($entry.Key -match '(?i)^(E02_|E04A1_|E04_A1G_|CL$|_CL_$|LINK$|_LINK_$|CMAKE_|CC$|CXX$|CFLAGS$|CXXFLAGS$|LDFLAGS$|NINJA_STATUS$|DOTNET_|_DOTNET_|CORECLR_|COR_|COMPlus_|APP_CONTEXT_|MSBUILD|NUGET_|ASPNETCORE_|UnrealBuildTool_)'){$saved[$entry.Key]=$entry.Value}}
    foreach($key in $saved.Keys){[Environment]::SetEnvironmentVariable($key,$null,'Process')}
    try{
        $envs=Child-Environment $Extra;$cleanup=$Phase -in @('DependencyConfigure','DependencyBuild')
        if($cleanup -and $script:Freeze.cmakePostSuccessfulRootCleanup -ne $true){throw 'A1G_CMAKE_SCOPED_CLEANUP_NOT_EXPLICITLY_SELECTED'}
        $seconds=[Math]::Min($script:Budgets[$Phase],(Phase-Budget));if($seconds -lt 3){throw 'A1G_PHASE_BUDGET_EXHAUSTED'}
        $script:RootCount++
        $record=[Warhammer.E02.Supervisor]::Run($exe,$Arguments,$cwd,$envs,$out,$err,$seconds,$false,'',$cleanup)
        $script:Result.processes.Add($record)
        $processPath=Join-Path $script:PhaseRoot ($Label+'.process.json');Write-JsonNew $processPath $record;$record['receiptArtifact']=Descriptor $processPath
        foreach($p in @($out,$err)){if(-not [IO.File]::Exists($p) -or ([IO.FileInfo]::new($p)).Length -gt 64MB){throw 'A1G_RETAINED_STREAM_CAP_OR_MISSING_PRESERVE_ORIGINAL'};Safe-Text $script:Utf8.GetString([IO.File]::ReadAllBytes($p))}
        Require-RootPass $record
        if(@($record.jobAccounting).Count -eq 0 -or $record.jobAccounting[-1].querySucceeded -ne $true){throw 'A1G_FINAL_JOB_ACCOUNTING_QUERY_NOT_CONFIRMED'}
        if($record.technicalBlocked -or $null -ne $record.primaryFailure -or @($record.secondaryErrors).Count -or $record.visibleWindowRequested -or -not $record.assignedBeforeResume -or -not $record.resumed){throw 'A1G_PROCESS_ACCOUNTING_FAILURE'}
        if($cleanup -and ($record.completionCleanupMode -cne 'PostSuccessfulRootCleanup' -or $record.postRootGraceSeconds -ne 5)){throw 'A1G_CMAKE_CLEANUP_RECEIPT_MISMATCH'}
        [void](Check-Storage);return $record
    }finally{foreach($key in $saved.Keys){[Environment]::SetEnvironmentVariable($key,$saved[$key],'Process')}}
}
function Vendor-Identity {
    $trees=@($script:Dependency.trees|Where-Object path -CEQ '');if($trees.Count -ne 1){throw 'A1G_VENDOR_ROOT_TREE_NOT_UNIQUE'}
    @{schemaVersion=1;runId=$RunId;sourceHead=$script:Freeze.sourceHead;sourceRoot=$script:Repo;stagedProject=(Join-Path $script:Stage 'WarhammerClient.uproject');vendorPin=$script:Dependency.pin;sourceTreeOid=$trees[0].treeOid}
}
function Check-ReleaseAbi {
    $path=Join-Path (Build-Root) 'CMakeFiles/CMakeConfigureLog.yaml';$d=Descriptor $path
    if($d.bytes -gt 64MB){throw 'A1G_ABI_LOG_SIZE'};$text=$script:Utf8.GetString([IO.File]::ReadAllBytes($path));Safe-Text $text
    $events=@([regex]::Matches($text,'(?ms)^  -\r?\n    kind: "try_compile-v1"\r?\n.*?(?=^  -\r?$|\z)')|Where-Object {$_.Value.Contains('variable: "CMAKE_CXX_ABI_COMPILED"',[StringComparison]::Ordinal)})
    if($events.Count -ne 1){throw 'A1G_UNIQUE_RELEASE_ABI_EVENT_REQUIRED'};$event=$events[0].Value
    foreach($pattern in @('(?m)^      exitCode: 0\r?$','(?m)^      CMAKE_CXX_FLAGS_RELEASE: "/O2 /Ob2 /DNDEBUG"\r?$','(?m)^      CMAKE_MSVC_RUNTIME_LIBRARY: "MultiThreadedDLL"\r?$','\[1/2\].*CMakeCXXCompilerABI\.cpp\.obj','\[2/2\].*vs_link_exe.*CMakeCXXCompilerABI\.cpp\.obj.*?/out:cmTC_[A-Za-z0-9_]+\.exe','(?:^|\s)-MD(?:\s|$)','(?:^|\s)-std:c\+\+20(?:\s|$)','(?:^|\s)/EHsc(?:\s|$)')){if($event -notmatch $pattern){throw 'A1G_RELEASE_ABI_COMPILE_OR_LINK_NOT_OBSERVED'}}
    @{artifact=$d;observation='One retained try_compile ABI event, Release compile and executable-link records with exit0. Narrow installed-log shape only; no general YAML or compiler lineage certification.'}
}
function Configure-Dependency {
    New-Directory (Build-Root)
    $p=Invoke-A1GRoot 'a1g-cmake-configure' $script:Freeze.toolPaths.cmake (@('-S',(CMake-Path $script:VendorRoot),'-B',(CMake-Path (Build-Root)))+(CMake-Options)) (Build-Root)
    $checked=Check-CMake;$abi=Check-ReleaseAbi
    $checked.generatedBuildInputs=Capture-ConfiguredBuildInputs $checked $p.receiptArtifact
    $r=Vendor-Identity;$r.kind='E04_A1G_VENDOR_CMAKE_CONFIGURE_RECEIPT';$r.status='CONFIGURE_ROOT_AND_CHECKS_PASSED';$r.vendorSourceRoot=$script:VendorRoot;$r.buildRoot=Build-Root;$r.acquisitionResultSha256=$script:AcquisitionDescriptor.sha256
    $r.configuration='Release';$r.tryCompileConfiguration='Release';$r.cxxScanForModules='OFF';$r.cppStandard='C++20';$r.runtime='MD';$r.exceptions='EHsc';$r.rtti='GR-';$r.abiProbe='ACTUAL_RELEASE_COMPILE_AND_LINK_SUCCEEDED'
    $r.cache=$checked.cache;$r.compileCommands=$checked.compileCommands;$r.ninja=$checked.ninja;$r.abiEvidenceLog=$abi.artifact;$r.process=$p.receiptArtifact
    Write-JsonNew (Owned 'logs/a1g-vendor-cmake-configure.json') $r
    $script:Result.configure=$checked;$script:Result.abi=$abi;$script:Result.vendorConfigureReceipt=Descriptor (Owned 'logs/a1g-vendor-cmake-configure.json')
}
function Build-Dependency {
    $library=Join-Path (Build-Root) 'yaml-cpp.lib';if(Test-Path -LiteralPath $library){throw 'A1G_FRESH_LIBRARY_PREABSENCE_REQUIRED'}
    $script:Result.configuredBuildInputPrelaunch=Confirm-ConfiguredBuildInputs
    $p=Invoke-A1GRoot 'a1g-cmake-build' $script:Freeze.toolPaths.cmake @('--build',(CMake-Path (Build-Root)),'--target','yaml-cpp','--parallel','2','--verbose') (Build-Root)
    $script:Result.configuredBuildInputPostbuild=Confirm-ConfiguredBuildInputs -AfterBuild
    $checked=Check-CMake;$lib=Descriptor $library
    if($lib.bytes -le 8 -or $lib.bytes -gt 64MB){throw 'A1G_STATIC_LIBRARY_SIZE'}
    $stream=[IO.File]::OpenRead($library);try{$magic=[byte[]]::new(8);if($stream.Read($magic,0,8) -ne 8 -or [Text.Encoding]::ASCII.GetString($magic) -cne "!<arch>`n"){throw 'A1G_STATIC_ARCHIVE_MAGIC'}}finally{$stream.Dispose()}
    $log=$script:Utf8.GetString([IO.File]::ReadAllBytes($p.stdout));$expectedSources=@($script:Dependency.files|Where-Object path -CMatch '^src/[^/]+\.cpp$')
    foreach($source in $expectedSources){if($log -notmatch ([regex]::Escape([IO.Path]::GetFileName($source.path))+'(?:\.obj)?')){throw 'A1G_FRESH_VENDOR_COMPILE_NOT_OBSERVED'}}
    if($log -match '(?i)ninja: no work to do' -or $log -notmatch '(?i)yaml-cpp\.lib' -or $log -notmatch '(?i)cmake\.exe"? -E vs_link_lib'){throw 'A1G_VENDOR_STATIC_ARCHIVE_ACTION_NOT_OBSERVED'}
    $b=Vendor-Identity;$b.kind='E04_A1G_VENDOR_CMAKE_BUILD_RECEIPT';$b.status='BUILD_ROOT_AND_ARTIFACT_CHECKS_PASSED';$b.vendorSourceRoot=$script:VendorRoot;$b.buildRoot=Build-Root;$b.acquisitionResultSha256=$script:AcquisitionDescriptor.sha256
    $b.configuration='Release';$b.platform='Win64';$b.architecture='x64';$b.cppStandard='C++20';$b.runtime='MD';$b.linkage='static';$b.exceptions='EHsc';$b.rtti='GR-';$b.exceptionsEnabled=$true;$b.installTargetInvoked=$false
    $b.configureReceipt=Descriptor (Owned 'logs/a1g-vendor-cmake-configure.json');$b.compiler=Descriptor $script:Freeze.toolPaths.compiler;$b.library=$lib;$b.process=$p.receiptArtifact
    Write-JsonNew (Owned 'logs/a1g-vendor-cmake-build.json') $b
    New-Directory (Artifact-Root);[void][IO.Directory]::CreateDirectory((Join-Path (Artifact-Root) 'lib'));[void][IO.Directory]::CreateDirectory((Join-Path (Artifact-Root) 'include'))
    $headers=[Collections.Generic.List[object]]::new()
    foreach($file in $script:Dependency.files|Where-Object {$_.path.StartsWith('include/',[StringComparison]::Ordinal)}){
        $relative=$file.path.Substring(8);$src=Descriptor (Under (Join-Path $script:VendorRoot $file.path) $script:VendorRoot);$dst=Under (Join-Path (Join-Path (Artifact-Root) 'include') $relative) (Artifact-Root)
        [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($dst));[IO.File]::Copy($src.path,$dst,$false);$copy=Descriptor $dst
        if($copy.bytes -ne $file.bytes -or $copy.sha256 -ine $file.sha256){throw 'A1G_HEADER_COPY_MISMATCH'};$headers.Add(@{relativePath=$relative;bytes=$copy.bytes;sha256=$copy.sha256})}
    $sourceLicense=Descriptor (Join-Path $script:VendorRoot 'LICENSE');if($sourceLicense.bytes -ne 1061 -or $sourceLicense.sha256 -ine 'AA6FCC27BE034E41E21DD832F9175BFE694A48491D9E14FF0FA278E19AD14F1B'){throw 'A1G_PINNED_RAW_MIT_NOTICE_REQUIRED'}
    [IO.File]::Copy($sourceLicense.path,(Join-Path (Artifact-Root) 'LICENSE.yaml-cpp'),$false);[IO.File]::Copy($library,(Join-Path (Artifact-Root) 'lib/yaml-cpp.lib'),$false)
    $copiedLib=Descriptor (Join-Path (Artifact-Root) 'lib/yaml-cpp.lib');$license=Descriptor (Join-Path (Artifact-Root) 'LICENSE.yaml-cpp')
    if($copiedLib.sha256 -ine $lib.sha256 -or $copiedLib.bytes -ne $lib.bytes -or $license.sha256 -ine $sourceLicense.sha256 -or $license.bytes -ne $sourceLicense.bytes){throw 'A1G_LIBRARY_OR_LICENSE_COPY_DRIFT'}
    $r=Vendor-Identity;$r.kind='E04_A1G_VENDOR_ARTIFACT_RECEIPT';$r.status='COPIED_FROM_SAME_RUN_BUILD_NOT_PHASE_ACCEPTANCE';$r.sourcePreparationId=$script:Dependency.preparationId;$r.acquisitionResult=$script:AcquisitionDescriptor
    $r.vendorConfigureReceipt=$b.configureReceipt;$r.vendorBuildReceipt=Descriptor (Owned 'logs/a1g-vendor-cmake-build.json');$r.artifactRoot=Artifact-Root;$r.includeRoot=Join-Path (Artifact-Root) 'include';$r.library=$copiedLib;$r.headers=$headers.ToArray();$r.sourceLicense=$sourceLicense;$r.license=$license;$r.windows=Windows-Contract
    $r.tools=@{compiler=Descriptor $script:Freeze.toolPaths.compiler;linker=Descriptor $script:Freeze.toolPaths.linker;librarian=Descriptor $script:Freeze.toolPaths.librarian;resourceCompiler=Descriptor $script:Freeze.toolPaths.sdkRc;cmake=Descriptor $script:Freeze.toolPaths.cmake;ninja=Descriptor $script:Freeze.toolPaths.ninja}
    $r.abi=@{target='WarhammerClientE04A1G';targetType='Game';targetConfiguration='Development';vendorConfiguration='Release';platform='Win64';architecture='x64';cppStandard='C++20';runtime='MD';linkage='static';staticDefine='YAML_CPP_STATIC_DEFINE';vendorExceptionsEnabled=$true}
    $r.consumerRequirements=@{parserExceptions='EHsc';callerExceptions='Disabled';publicBoundary='UE_OWNED_SYNCHRONOUS_NOEXCEPT'};$r.specialAssuranceCertification='DEFERRED_UNPROVEN_OWN17'
    Write-JsonNew (Owned 'logs/a1g-yaml-artifact-receipt.json') $r
    $script:Result.vendorArtifact=@{artifactReceipt=Descriptor (Owned 'logs/a1g-yaml-artifact-receipt.json');library=$copiedLib;builtLibrary=$lib;headerCount=$headers.Count;license=$license;generatedCommands=$checked}
}
function Ubt-Arguments([string]$Target){
    @($script:Freeze.toolPaths.ubt,$Target,'Win64','Development',('-Project='+(Join-Path $script:Stage 'WarhammerClient.uproject')),'-WaitMutex','-NoUBA','-NoVFS','-NoUBTMakefiles','-Compiler=VisualStudio2022','-CompilerVersion=14.44.35229','-WindowsSDKVersion=10.0.22621.0',('-UBARootDir='+(Owned 'uba')),('-Log='+(Owned ('logs/'+$Phase.ToLowerInvariant()+'.log'))))
}
function Game-BuildEnvironment {
    $receipt=Descriptor (Owned 'logs/a1g-yaml-artifact-receipt.json')
    @{E04_A1G_NATIVE_BOUNDARY_REQUIRED='1';E04_A1G_RUN_ID=$RunId;E04_A1G_SOURCE_HEAD=$script:Freeze.sourceHead;E04_A1G_SOURCE_ROOT=$script:Repo;E04_A1G_RUN_ROOT=$script:RunRoot;E04_A1G_STAGED_PROJECT=(Join-Path $script:Stage 'WarhammerClient.uproject');E04_A1G_ARTIFACT_RECEIPT=$receipt.path;E04_A1G_ARTIFACT_RECEIPT_SHA256=$receipt.sha256}
}
function Uat-Arguments([switch]$Cook){
    $common=@($script:Freeze.toolPaths.uat,'-NoCompile','-NoP4','BuildCookRun',('-project='+(Join-Path $script:Stage 'WarhammerClient.uproject')),'-target=WarhammerClientE04A1G','-platform=Win64','-clientconfig=Development','-skipbuild','-skippackage','-unattended')
    if($Cook){
        $ddc=Owned 'ddc/cook';if($ddc.Length -ge 119){throw 'A1G_DDC_PATH_TOO_LONG'}
        $child='-SkipZenStore -NullRHI -RenderOffScreen -NoSplash -nosound -NoSourceControl -NoLiveCoding -DDC-NoDefaultGraph -DDC=(E04A1G=(Type=FileSystem,Path='+$ddc+',ReadOnly=false,Remote=false,DeleteUnused=false)) -UserDir='+(Owned 'ue-user/cook')+' -ShaderWorkingDir='+(Owned 'shader-work/cook')+' -NoRemoteShaderCompile'
        $common+@('-cook','-map=/Engine/Maps/Entry',('-CookOutputDir='+(Owned 'cook/Windows')),('-unrealexe='+$script:Freeze.toolPaths.editorCmd),('-AdditionalCookerOptions='+$child))
    }else{$common+@('-skipcook','-stage','-map=/Engine/Maps/Entry',('-CookOutputDir='+(Owned 'cook/Windows')),('-stagingdirectory='+(Owned 'stage')))}
}
function Uat-Environment {
    $slug=$Phase.ToLowerInvariant();$log=Owned ('logs/uat-'+$slug);New-Directory $log;$saved=Owned ('temp/uat-'+$slug);New-Directory $saved
    @{uebp_LOCAL_ROOT=$EngineRoot;uebp_EngineSavedFolder=$saved;uebp_LogFolder=$log;uebp_FinalLogFolder=$log;TEMP=(Owned ('temp/'+$slug));TMP=(Owned ('temp/'+$slug));DOTNET_CLI_HOME=(Owned ('dotnet-home/'+$slug));NUGET_PACKAGES=(Owned 'nuget')}
}
function Read-GameResult([string]$ExpectedBinary,[string]$ExpectedBinarySha){
    $p=Owned 'reports/game-probe/result.json';$d=Descriptor $p;if($d.bytes -gt 64KB){throw 'A1G_NATIVE_RESULT_CAP'};$r=Read-Json $p
    if($r.kind -cne 'E04_A1G_GAME_CALLER_RESULT' -or $r.status -cne 'PASS' -or $r.runId -cne $RunId -or $r.sourceHead -cne $script:Freeze.sourceHead -or $r.compiledTargetGuard -cne 'WarhammerClientE04A1G/Game/Win64/x64/Development' -or (Assert-Path $r.actualExecutablePath) -ine (Assert-Path $ExpectedBinary) -or $r.expectedExecutableSha256FromSupervisor -ine $ExpectedBinarySha){throw 'A1G_NATIVE_SUBJECT_OR_OUTCOME_MISMATCH'}
    $ids=@((1..18|ForEach-Object {'M{0:D2}' -f $_})+(1..9|ForEach-Object {'B{0:D2}' -f $_})+(1..13|ForEach-Object {'G{0:D2}' -f $_})+'G23'+(14..22|ForEach-Object {'G{0:D2}' -f $_})+@('L01','L02'))
    if($r.attemptCount -ne 2 -or $r.expectedCheckCount -ne 52 -or $r.evaluatedCheckCount -ne 52 -or -not $r.completeOrderedCheckSet -or -not $r.parserValuesDestroyedBeforePublication -or $r.callerCppUnwindDefined -ne $false -or $r.callerPlatformExceptionsDisabled -ne 1 -or $r.callback -cne 'OnFEngineLoopInitComplete' -or $r.callbackInvocationCount -ne 1 -or @($r.checks).Count -ne 52){throw 'A1G_INCOMPLETE_NATIVE_CHECKS_OR_MODE'}
    # Field names below must match the supplied caller source, not a guessed report.
    Equal-Data @($r.checks|ForEach-Object {$_.id}) $ids 'actual ordered check IDs'
    if(@($r.checks|Where-Object {$_.evaluated -ne $true -or $_.passed -ne $true}).Count){throw 'A1G_UNEVALUATED_OR_FAILED_NATIVE_CHECK'}
    Equal-Data @($r.attempts|ForEach-Object {$_.id}) @('A1G_BAD','A1G_GOOD') 'actual attempts'
    [void](Check-Descriptor @{path=$ExpectedBinary;bytes=([IO.FileInfo]::new($ExpectedBinary)).Length;sha256=$ExpectedBinarySha})
    @{result=$d;attemptCount=2;evaluatedCheckCount=52;nativeAssertionTotal='NOT_INFERRED';scope='Finite two-input/lifetime Game proof only'}
}

# BEGIN direct ordinary source integration; source origins are operator metadata, not verdicts.
# Ordinary response helpers; definitions alone grant no process authority.
# Byte-for-text source-range copies from canonical FE278EA1; original diagnostic prefixes retained.
function Response-Chain([string]$Path) {
    # Preserve BFS file/text ordering; complete edge validation is independent of node deduplication.
    $queue=[Collections.Generic.Queue[string]]::new();$queue.Enqueue((Under $Path $script:Stage))
    $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase);$parts=[Collections.Generic.List[object]]::new()
    $graph=[Collections.Generic.Dictionary[string,object]]::new([StringComparer]::OrdinalIgnoreCase)
    $pattern='(?m)^\s*@(?:"(?<path>[^"\r\n]+)"|(?<path>[^\s"\r\n]+))\s*$'
    while($queue.Count){$p=Need-File $queue.Dequeue();if(-not $seen.Add($p)){continue}
        if([IO.Path]::GetExtension($p) -ine '.rsp' -or ([IO.FileInfo]::new($p)).Length -gt 64MB){throw 'E04A1_RESPONSE_KIND_OR_SIZE'}
        $text=$script:Utf8.GetString([IO.File]::ReadAllBytes($p));Safe-Text $text;if($text.Contains([char]0)){throw 'E04A1_RESPONSE_NUL'}
        $references=@([regex]::Matches($text,$pattern))
        # Only complete standalone references are supported. Quoted/inline residual @ is refused too.
        if(([regex]::Replace($text,$pattern,'')).Contains('@')){throw 'E04A1_UNSUPPORTED_RESPONSE_REFERENCE_SYNTAX'}
        $edges=[Collections.Generic.List[string]]::new()
        foreach($reference in $references){$q=Under $reference.Groups['path'].Value $script:Stage;$edges.Add($q);$queue.Enqueue($q)}
        $graph.Add($p,@($edges));$parts.Add(@{file=Descriptor $p;text=$text})
    }
    # Kahn's linear validation counts every edge, including duplicates and edges to seen nodes.
    $degree=[Collections.Generic.Dictionary[string,int]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach($part in $parts){$degree.Add($part.file.path,0)}
    foreach($edges in $graph.Values){foreach($q in $edges){if(-not $degree.ContainsKey($q)){throw 'E04A1_RESPONSE_TARGET_NOT_IN_GRAPH'};$degree[$q]++}}
    $ready=[Collections.Generic.Queue[string]]::new();foreach($part in $parts){if($degree[$part.file.path] -eq 0){$ready.Enqueue($part.file.path)}}
    $visited=0
    while($ready.Count){$p=$ready.Dequeue();$visited++;foreach($q in $graph[$p]){$degree[$q]--;if($degree[$q] -eq 0){$ready.Enqueue($q)}}}
    if($visited -ne $graph.Count){throw 'E04A1_RESPONSE_CYCLE'}
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

# Bounded ordinary UBT consumers. Source text is not SOURCE admission or a GO.
# Future integration requires the companion ordinary Response-Chain,
# Forced-DefinitionHeaders and Macro-Values definitions, copied without edits
# from the pinned A1E wrapper. No Rules/cache/reflection/witness branch is used.
# Host interface: wrapper E817186B2D09F14888D96BB0DCAEA256FE54CBA5765E97938F5AFC534538A0C6.
# All paths, identities, results and action formats below are future requirements,
# not observations. Unsupported forms refuse; no recovery launch is provided.

function Read-A1GBuildText([string]$Path) {
    $p=Need-File $Path
    if(([IO.FileInfo]::new($p)).Length -gt 64MB){throw 'A1G_BUILD_TEXT_RETAINED_CAP'}
    $text=$script:Utf8.GetString([IO.File]::ReadAllBytes($p));Safe-Text $text
    if($text.Contains([char]0)){throw 'A1G_BUILD_TEXT_NUL'}
    return $text
}

# Call BEFORE the one permitted UBT root; pass this exact object to the checker.
# This observes only four existing generated-output subtrees in this owned project.
function Get-A1GUbtPrebuildEvidence {
    if($Phase -cnotin @('EditorPrerequisiteBuild','GameBuild')){throw 'A1G_UBT_BASELINE_WRONG_PHASE'}
    $files=[Collections.Generic.List[object]]::new()
    foreach($relative in @('Binaries','Intermediate','Plugins/E04ProfileProof/Binaries','Plugins/E04ProfileProof/Intermediate')){
        $root=Under (Join-Path $script:Stage $relative) $script:Stage
        if([IO.Directory]::Exists($root)){foreach($p in Plain-Files $root){$files.Add((Descriptor $p))}}
    }
    if($Phase -ceq 'EditorPrerequisiteBuild' -and $files.Count){throw 'A1G_EDITOR_PREREQUISITE_REQUIRES_FRESH_GENERATED_OUTPUTS'}
    if($Phase -ceq 'GameBuild' -and @($files|Where-Object {$_.path.Replace('\','/').Contains('/Plugins/E04ProfileProof/',[StringComparison]::OrdinalIgnoreCase)}).Count){throw 'A1G_GAME_REQUIRES_FRESH_PROOF_PLUGIN_OUTPUTS'}
    $log=Owned ('logs/'+$Phase.ToLowerInvariant()+'.log')
    if(Test-Path -LiteralPath $log){throw 'A1G_UBT_LOG_PREEXISTS'}
    return @{phase=$Phase;runId=$RunId;sourceHead=$script:Freeze.sourceHead;observedUtc=[DateTime]::UtcNow.ToString('o');files=$files.ToArray();logPath=$log}
}

function Assert-A1GNewBuildFile($Before,[string]$Path) {
    if($Before.phase -cne $Phase -or $Before.runId -cne $RunId -or $Before.sourceHead -cne $script:Freeze.sourceHead){throw 'A1G_UBT_BASELINE_SUBJECT_MISMATCH'}
    $p=Under $Path $script:Stage
    if(@($Before.files|Where-Object {$_.path -ieq $p}).Count){throw 'A1G_REQUIRED_FRESH_UBT_OUTPUT_PREEXISTED'}
    return Descriptor $p
}

function Resolve-A1GReceiptFile([string]$Value,[string]$ReceiptDirectory) {
    if([string]::IsNullOrWhiteSpace($Value)){throw 'A1G_RECEIPT_FILE_MISSING'}
    if($Value.StartsWith('$(EngineDir)/',[StringComparison]::Ordinal)){$Value=Join-Path (Join-Path $EngineRoot 'Engine') $Value.Substring(13)}
    elseif($Value.StartsWith('$(ProjectDir)/',[StringComparison]::Ordinal)){$Value=Join-Path $script:Stage $Value.Substring(14)}
    elseif($Value.Contains('$(')){throw 'A1G_RECEIPT_PATH_TOKEN_UNSUPPORTED'}
    elseif(-not [IO.Path]::IsPathFullyQualified($Value)){$Value=Join-Path $ReceiptDirectory $Value}
    $p=Assert-Path ([IO.Path]::GetFullPath($Value))
    $owned=$p.StartsWith($script:Stage+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)
    $installed=$p.StartsWith((Join-Path $EngineRoot 'Engine')+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)
    if(-not ($owned -or $installed)){throw 'A1G_RECEIPT_FILE_OUTSIDE_SELECTED_PROJECT_ENGINE'}
    return Need-File $p
}

function Read-A1GMatchingTargetReceipt([string]$Target,[string]$Type) {
    $root=Under (Join-Path $script:Stage 'Binaries') $script:Stage
    $candidates=@(foreach($p in Plain-Files $root){if([IO.Path]::GetExtension($p) -ieq '.target'){
        $r=Read-Json $p
        if($r.TargetName -ceq $Target -and $r.TargetType -ceq $Type){@{path=$p;data=$r}}
    }})
    if($candidates.Count -ne 1){throw 'A1G_MATCHING_TARGET_RECEIPT_NOT_UNIQUE'}
    $item=$candidates[0];$r=$item.data;$directory=[IO.Path]::GetDirectoryName($item.path)
    # The pinned installed enum explicitly aliases Latest=V7. Either serialized
    # name denotes that same value; no runtime enum parsing or Rules loading.
    if($r.Platform -cne 'Win64' -or $r.Configuration -cne 'Development' -or $r.Architecture -cne 'x64' -or $r.TargetBuildEnvironment -cne 'Shared' -or $r.BuildSettingsVersion -cnotin @('V7','Latest')) {throw 'A1G_TARGET_RECEIPT_PLATFORM_CONFIGURATION_OR_SHARED_MISMATCH'}
    if((Resolve-A1GReceiptFile $r.Project $directory) -ine (Join-Path $script:Stage 'WarhammerClient.uproject')){throw 'A1G_TARGET_RECEIPT_PROJECT_MISMATCH'}
    $products=[Collections.Generic.List[object]]::new();$dependencies=[Collections.Generic.List[object]]::new()
    $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach($p in @($r.BuildProducts)){
        if($p.Type -isnot [string]){throw 'A1G_BUILD_PRODUCT_TYPE_MISSING'}
        $path=Resolve-A1GReceiptFile $p.Path $directory
        if(-not $seen.Add($path)){throw 'A1G_DUPLICATE_BUILD_PRODUCT'}
        $products.Add(@{file=Descriptor $path;type=$p.Type})
    }
    if(-not $products.Count){throw 'A1G_BUILD_PRODUCTS_EMPTY'}
    foreach($p in @($r.RuntimeDependencies)){
        if($p.Type -isnot [string]){throw 'A1G_RUNTIME_DEPENDENCY_TYPE_MISSING'}
        $dependencies.Add(@{file=Descriptor (Resolve-A1GReceiptFile $p.Path $directory);type=$p.Type})
    }
    return @{targetReceipt=Descriptor $item.path;data=$r;directory=$directory;buildProducts=$products.ToArray();runtimeDependencies=$dependencies.ToArray();launch=Descriptor (Resolve-A1GReceiptFile $r.Launch $directory)}
}

function Get-A1GProofPluginSelection($Receipt,[bool]$Enabled) {
    $descriptor=Join-Path $script:Stage 'Plugins/E04ProfileProof/E04ProfileProof.uplugin'
    $project=Join-Path $script:Stage 'WarhammerClient.uproject'
    $d=Read-Json $descriptor;$p=Read-Json $project
    if($d.EnabledByDefault -ne $false -or $d.CanContainContent -ne $false){throw 'A1G_PROOF_PLUGIN_DISABLED_DEFAULT_REQUIRED'}
    $projectRows=@($p.Plugins|Where-Object {$_.Name -ceq 'E04ProfileProof'})
    if($projectRows.Count -gt 1 -or @($projectRows|Where-Object {$_.Enabled -ne $false}).Count){throw 'A1G_PROJECT_WIDE_PROOF_ENABLE_FORBIDDEN'}
    $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $overrides=@($Receipt.Plugins)
    foreach($row in $overrides){if($row.Name -isnot [string] -or $row.Enabled -isnot [bool] -or -not $seen.Add($row.Name)){throw 'A1G_PLUGIN_OVERRIDE_SHAPE'}}
    $rows=@($overrides|Where-Object {$_.Name -ceq 'E04ProfileProof'})
    $built=@($Receipt.BuildPlugins|Where-Object {$_ -ceq 'E04ProfileProof'})
    if($Enabled){if($rows.Count -ne 1 -or $rows[0].Enabled -ne $true -or $built.Count -ne 1){throw 'A1G_GAME_RECEIPT_PROOF_PLUGIN_ENABLE_REQUIRED'}}
    else{
        if(@($rows|Where-Object Enabled).Count -or $built.Count){throw 'A1G_EDITOR_RECEIPT_PROOF_PLUGIN_MUST_BE_DISABLED'}
        foreach($relative in @('Plugins/E04ProfileProof/Binaries','Plugins/E04ProfileProof/Intermediate')){
            $root=Join-Path $script:Stage $relative
            if([IO.Directory]::Exists($root) -and @(Plain-Files $root).Count){throw 'A1G_DISABLED_EDITOR_PLUGIN_GENERATED_OUTPUTS_PRESENT'}
        }
    }
    return @{proofPluginEnabled=$Enabled;descriptor=Descriptor $descriptor;project=Descriptor $project;receiptOverrides=$overrides;buildPlugins=@($Receipt.BuildPlugins);qualification='Actual receipt/build set, selected disabled default/project configuration and owned output checks; not an Editor startup observation. Cook must retain the actual normal startup outcome.'}
}

function Get-A1GUbtActionLog($Process,$Before,[string]$Target) {
    [void](Check-Descriptor $Process.receiptArtifact);Require-RootPass $Process
    if($Process.executable -ine $script:Freeze.toolPaths.dotnet -or $Process.workingDirectory -ine (Join-Path $EngineRoot 'Engine/Source') -or $null -ne $Process.primaryFailure -or @($Process.secondaryErrors).Count -or $Process.visibleWindowRequested){throw 'A1G_UBT_PROCESS_SUBJECT_OR_RESULT_MISMATCH'}
    Equal-Data @($Process.arguments) @(Ubt-Arguments $Target) 'ubt argv'
    foreach($entry in $Process.environmentOverrides.GetEnumerator()){
        if($entry.Key -match '^(?i:E02_|E04A1_)' -or ($Phase -ceq 'EditorPrerequisiteBuild' -and $entry.Key -match '^(?i:E04_A1G_)')){throw 'A1G_UBT_CROSS_ROUTE_ENVIRONMENT_FORBIDDEN'}
    }
    if($Phase -ceq 'GameBuild'){foreach($entry in (Game-BuildEnvironment).GetEnumerator()){if($Process.environmentOverrides[$entry.Key] -cne $entry.Value){throw 'A1G_GAME_ENVIRONMENT_BINDING_MISMATCH'}}}
    $log=Owned ('logs/'+$Phase.ToLowerInvariant()+'.log')
    if($Before.logPath -ine $log){throw 'A1G_UBT_LOG_BASELINE_MISMATCH'}
    $text=Read-A1GBuildText $log
    if($text -notmatch '(?m)^Result: Succeeded\s*$' -or $text -notmatch '14\.44\.35229' -or $text -notmatch '10\.0\.22621\.0' -or $text -match '(?im)\b(?:Win32_Process\.Create|external process broker|using (?:XGE|FASTBuild|Incredibuild|remote executor))\b'){throw 'A1G_UBT_BUILD_RESULT_TOOL_OR_EXECUTOR_MISMATCH'}
    return @{file=Descriptor $log;text=$text;process=$Process.receiptArtifact}
}

function Require-A1GBuildAction([string]$Text,[string]$Action,[string]$Leaf) {
    # Narrow installed ActionLogger/VC status form; unsupported output refuses.
    $pattern='(?m)^\s*\[[0-9]+/[0-9]+\]\s+'+[regex]::Escape($Action)+' \[x64\]\s+'+[regex]::Escape($Leaf)+'\s*\r?$'
    if(@([regex]::Matches($Text,$pattern)).Count -ne 1){throw 'A1G_UNIQUE_REAL_BUILD_ACTION_NOT_OBSERVED'}
}

function Get-A1GOwnedResponses {
    $all=@()
    foreach($relative in @('Intermediate','Plugins/E04ProfileProof/Intermediate')){
        $root=Join-Path $script:Stage $relative
        if([IO.Directory]::Exists($root)){$all+=@(Plain-Files $root|Where-Object {[IO.Path]::GetExtension($_) -ieq '.rsp'})}
    }
    return @($all|Sort-Object -CaseSensitive)
}

function Get-A1GCompileEvidence([string]$Module,[string]$ExactSource,[string]$Mode,$Before,[string]$ActionLog) {
    $responses=@(Get-A1GOwnedResponses);$candidates=[Collections.Generic.List[object]]::new()
    foreach($p in $responses){
        if(-not $p.Replace('\','/').Contains('/'+$Module+'/',[StringComparison]::OrdinalIgnoreCase)){continue}
        $leaf=Read-A1GBuildText $p
        if($leaf -notmatch '(?im)^\s*/Fo"'){continue}
        $chain=Response-Chain $p;$t=$chain.text
        $sources=@([regex]::Matches($t,'(?im)^\s*(?:"(?<path>[^"\r\n]+\.cpp)"|(?<path>[^\s"\r\n]+\.cpp))\s*\r?$'))
        if($sources.Count -ne 1){throw 'A1G_CPP_RESPONSE_SOURCE_FORM_UNSUPPORTED'}
        $source=Under $sources[0].Groups['path'].Value $script:Stage
        if($ExactSource -and $source -ine $ExactSource){continue}
        $objects=@([regex]::Matches($t,'(?im)^\s*/Fo"(?<path>[^"\r\n]+)"\s*\r?$'))
        if($objects.Count -ne 1){throw 'A1G_CPP_RESPONSE_OBJECT_FORM_UNSUPPORTED'}
        $object=Assert-A1GNewBuildFile $Before $objects[0].Groups['path'].Value
        [void](Assert-A1GNewBuildFile $Before $p)
        Require-A1GBuildAction $ActionLog 'Compile' ([IO.Path]::GetFileName($source))
        $headers=Forced-DefinitionHeaders $t $Module
        $macro=@{};foreach($name in @('PLATFORM_EXCEPTIONS_DISABLED','_HAS_EXCEPTIONS','YAML_CPP_STATIC_DEFINE','IS_MONOLITHIC','WITH_EDITOR','UE_BUILD_DEVELOPMENT','E04_A1G_DEDICATED_CALLER')){$macro[$name]=@(Macro-Values $t $headers.moduleDefinitionText $name)}
        $std=@([regex]::Matches($t,'(?i)(?:^|\s)(?<option>/std:[^\s]*)')|ForEach-Object {$_.Groups['option'].Value})
        $eh=@([regex]::Matches($t,'(?i)(?:^|\s)(?<option>/EH[^\s]*)')|ForEach-Object {$_.Groups['option'].Value})
        if($t -notmatch '(?i)(?:^|\s)/MD(?:\s|$)' -or $t -match '(?i)(?:^|\s)/(?:MDd|MTd?)(?:\s|$)'){throw 'A1G_ACTUAL_DYNAMIC_RELEASE_CRT_REQUIRED'}
        if($Mode -ne 'EditorProject'){
            if($t -cnotmatch '(?:^|\s)/std:c\+\+20(?:\s|$)' -or @($std|Where-Object {$_ -cne '/std:c++20'}).Count){throw 'A1G_ACTUAL_CPP20_REQUIRED'}
            foreach($pair in @(@('IS_MONOLITHIC','1'),@('WITH_EDITOR','0'),@('UE_BUILD_DEVELOPMENT','1'))){if($macro[$pair[0]].Count -ne 1 -or $macro[$pair[0]][0] -cne $pair[1]){throw 'A1G_ACTUAL_GAME_DEFINITIONS_MISMATCH'}}
            if($Mode -ceq 'Parser'){
                if($t -cnotmatch '(?:^|\s)/EHsc(?:\s|$)' -or @($eh|Where-Object {$_ -cne '/EHsc'}).Count -or $macro.PLATFORM_EXCEPTIONS_DISABLED.Count -ne 1 -or $macro.PLATFORM_EXCEPTIONS_DISABLED[0] -cne '0' -or $macro._HAS_EXCEPTIONS -contains '0' -or $macro.YAML_CPP_STATIC_DEFINE.Count -ne 1 -or $macro.YAML_CPP_STATIC_DEFINE[0] -cne '1'){throw 'A1G_PARSER_PRIVATE_EH_STATIC_MODE_MISMATCH'}
            }elseif($Mode -ceq 'Caller'){
                if($eh.Count -or $macro.PLATFORM_EXCEPTIONS_DISABLED.Count -ne 1 -or $macro.PLATFORM_EXCEPTIONS_DISABLED[0] -cne '1' -or $macro._HAS_EXCEPTIONS.Count -ne 1 -or $macro._HAS_EXCEPTIONS[0] -cne '0' -or $macro.E04_A1G_DEDICATED_CALLER.Count -ne 1 -or $macro.E04_A1G_DEDICATED_CALLER[0] -cne '1' -or $macro.YAML_CPP_STATIC_DEFINE.Count -or $t.Replace('\','/').Contains(((Join-Path (Artifact-Root) 'include').Replace('\','/')),[StringComparison]::OrdinalIgnoreCase)){throw 'A1G_CALLER_DISABLED_MODE_OR_VENDOR_LEAK_MISMATCH'}
            }else{throw 'A1G_COMPILE_MODE_UNSUPPORTED'}
        }
        $candidates.Add(@{source=Descriptor $source;module=$Module;mode=$Mode;object=$object;responseChain=$chain;forcedHeaders=$headers;actualMacroValues=$macro;actualStandardOptions=$std;actualExceptionOptions=$eh})
    }
    if($ExactSource){if($candidates.Count -ne 1){throw 'A1G_EXACT_COMPILE_RESPONSE_NOT_UNIQUE'};return $candidates[0]}
    if(-not $candidates.Count){throw 'A1G_EDITOR_PROJECT_REAL_COMPILE_NOT_OBSERVED'}
    # One or more actual current project compile units are sufficient here; this
    # is prerequisite evidence, not a declaration that every source was compiled.
    return $candidates.ToArray()
}

function Get-A1GLinkEvidence([string]$Output,$CompileRows,$Before,[string]$ActionLog,[string]$VendorLibrary='') {
    $binary=Assert-A1GNewBuildFile $Before $Output
    $candidates=@(foreach($p in Get-A1GOwnedResponses){$t=Read-A1GBuildText $p
        $outs=@([regex]::Matches($t,'(?im)^\s*/OUT:"(?<path>[^"\r\n]+)"\s*\r?$'))
        if($outs.Count -eq 1 -and (Assert-Path $outs[0].Groups['path'].Value) -ieq $Output){$p}
    })
    if($candidates.Count -ne 1){throw 'A1G_EXACT_OUTPUT_LINK_RESPONSE_NOT_UNIQUE'}
    [void](Assert-A1GNewBuildFile $Before $candidates[0]);$chain=Response-Chain $candidates[0];$t=$chain.text.Replace('\','/')
    Require-A1GBuildAction $ActionLog 'Link' ([IO.Path]::GetFileName($Output))
    foreach($row in @($CompileRows)){
        $token=$row.object.path.Replace('\','/')
        if($t -notmatch ('(?im)^\s*"?'+[regex]::Escape($token)+'"?\s*\r?$')){throw 'A1G_REQUIRED_COMPILED_OBJECT_NOT_IN_FINAL_LINK'}
    }
    if($VendorLibrary){
        if([IO.Path]::GetExtension($Output) -ine '.exe' -or $t -match '(?im)^\s*/DLL\s*\r?$' -or $t -notmatch '(?im)^\s*/MACHINE:X64\s*\r?$' -or $t -notmatch ('(?im)^\s*"?'+[regex]::Escape($VendorLibrary.Replace('\','/'))+'"?\s*\r?$')){throw 'A1G_MONOLITHIC_EXECUTABLE_STATIC_VENDOR_LINK_MISMATCH'}
    }elseif([IO.Path]::GetExtension($Output) -ine '.dll' -or $t -notmatch '(?im)^\s*/DLL\s*\r?$'){throw 'A1G_EDITOR_PROJECT_DLL_LINK_REQUIRED'}
    return @{binary=$binary;responseChain=$chain;vendorStaticLibraryObserved=[bool]$VendorLibrary;requiredObjectCount=@($CompileRows).Count;qualification='Actual current action log, fresh owned output and retained terminal response inputs; not a general linker-language/delivery certificate.'}
}

function Check-A1GEditorPrerequisiteBuild($Process,$Before) {
    if($Phase -cne 'EditorPrerequisiteBuild'){throw 'A1G_EDITOR_VALIDATOR_WRONG_PHASE'}
    $log=Get-A1GUbtActionLog $Process $Before 'WarhammerClientEditor'
    $receipt=Read-A1GMatchingTargetReceipt 'WarhammerClientEditor' 'Editor'
    [void](Assert-A1GNewBuildFile $Before $receipt.targetReceipt.path)
    $launchCmd=Descriptor (Resolve-A1GReceiptFile $receipt.data.LaunchCmd $receipt.directory)
    if($receipt.launch.path -ine $script:Freeze.toolPaths.editor -or $launchCmd.path -ine $script:Freeze.toolPaths.editorCmd){throw 'A1G_EDITOR_INSTALLED_LAUNCH_MISMATCH'}
    $plugin=Get-A1GProofPluginSelection $receipt.data $false
    $manifests=@(foreach($p in Plain-Files (Join-Path $script:Stage 'Binaries')){if([IO.Path]::GetExtension($p) -ieq '.modules'){
        $m=Read-Json $p
        if(@($m.Modules.Keys|Where-Object {$_ -clike 'E04Profile*'}).Count){throw 'A1G_DISABLED_EDITOR_PROOF_MODULE_IN_MANIFEST'}
        if($m.Modules.Contains('WarhammerClient')){@{path=$p;data=$m}}
    }})
    if($manifests.Count -ne 1){throw 'A1G_EDITOR_PROJECT_MODULE_MANIFEST_NOT_UNIQUE'}
    $manifest=$manifests[0];[void](Assert-A1GNewBuildFile $Before $manifest.path)
    $engineManifest=Join-Path ([IO.Path]::GetDirectoryName($receipt.launch.path)) ([IO.Path]::GetFileNameWithoutExtension($receipt.launch.path)+'.modules')
    $engineModules=Read-Json $engineManifest
    if($manifest.data.BuildId -isnot [string] -or [string]::IsNullOrEmpty($manifest.data.BuildId) -or $manifest.data.BuildId -cne $engineModules.BuildId){throw 'A1G_EDITOR_PROJECT_ENGINE_BUILDID_MISMATCH'}
    $binary=Under (Join-Path ([IO.Path]::GetDirectoryName($manifest.path)) $manifest.data.Modules.WarhammerClient) $script:Stage
    if(@($receipt.buildProducts|Where-Object {$_.file.path -ieq $binary -and $_.type -ceq 'DynamicLibrary'}).Count -ne 1){throw 'A1G_EDITOR_MODULE_NOT_MATCHING_RECEIPT_PRODUCT'}
    if(@($receipt.buildProducts|Where-Object {$_.file.path.Replace('\','/').Contains('/Plugins/E04ProfileProof/',[StringComparison]::OrdinalIgnoreCase)}).Count -or @($receipt.runtimeDependencies|Where-Object {$_.file.path.Replace('\','/').Contains('/Plugins/E04ProfileProof/',[StringComparison]::OrdinalIgnoreCase)}).Count){throw 'A1G_DISABLED_EDITOR_PROOF_PLUGIN_PRODUCT_OR_RUNTIME_INPUT'}
    $compiles=@(Get-A1GCompileEvidence 'WarhammerClient' '' 'EditorProject' $Before $log.text)
    $link=Get-A1GLinkEvidence $binary $compiles $Before $log.text
    return @{targetReceipt=$receipt.targetReceipt;launch=$receipt.launch;launchCmd=$launchCmd;projectModule=@{module='WarhammerClient';manifest=Descriptor $manifest.path;engineManifest=Descriptor $engineManifest;binary=$link.binary;buildId=$manifest.data.BuildId};pluginSelection=$plugin;buildProducts=$receipt.buildProducts;runtimeDependencies=$receipt.runtimeDependencies;log=$log.file;process=$Process.receiptArtifact;nativeFlags=@{compileResponses=$compiles;linkResponses=@($link)};limits='Normal Editor build prerequisite only; no Editor/cook startup or A1E proof/acceptance transfer.'}
}

function Check-A1GGameBuild($Process,$Before) {
    if($Phase -cne 'GameBuild'){throw 'A1G_GAME_VALIDATOR_WRONG_PHASE'}
    $log=Get-A1GUbtActionLog $Process $Before 'WarhammerClientE04A1G'
    $receipt=Read-A1GMatchingTargetReceipt 'WarhammerClientE04A1G' 'Game'
    [void](Assert-A1GNewBuildFile $Before $receipt.targetReceipt.path)
    $plugin=Get-A1GProofPluginSelection $receipt.data $true
    $executable=Under $receipt.launch.path $script:Stage
    if([IO.Path]::GetExtension($executable) -ine '.exe' -or @($receipt.buildProducts|Where-Object {$_.file.path -ieq $executable -and $_.type -ceq 'Executable'}).Count -ne 1){throw 'A1G_GAME_LAUNCH_NOT_EXACT_OWNED_EXECUTABLE_PRODUCT'}
    $artifact=Descriptor (Owned 'logs/a1g-yaml-artifact-receipt.json');$selectionPath=Owned 'logs/a1g-yaml-module-selection.json';$selection=Read-Json $selectionPath
    if($selection.kind -cne 'E04_A1G_YAML_MODULE_SELECTION' -or $selection.runId -cne $RunId -or $selection.sourceHead -cne $script:Freeze.sourceHead -or $selection.target -cne 'WarhammerClientE04A1G' -or $selection.targetType -cne 'Game' -or $selection.platform -cne 'Win64' -or $selection.architecture -cne 'x64' -or $selection.targetConfiguration -cne 'Development' -or $selection.vendorConfiguration -cne 'Release' -or $selection.fileReadLocksHeldThroughUbtExit -ne $true -or $selection.terminalCallerAndParserFlagsObserved -ne $false -or $selection.artifactReceipt.sha256 -ine $artifact.sha256){throw 'A1G_ACTUAL_GAME_VENDOR_SELECTION_MISMATCH'}
    foreach($key in @('artifactReceipt','acquisitionResult','vendorConfigureReceipt','vendorBuildReceipt')){[void](Check-Descriptor $selection[$key])}
    $compiles=[Collections.Generic.List[object]]::new()
    foreach($spec in @(@('E04ProfileParser','E04ProfileParserModule.cpp','Parser'),@('E04ProfileParser','E04YamlEventReader.cpp','Parser'),@('E04ProfileGameProbe','E04ProfileGameProbeModule.cpp','Caller'))){
        $source=Join-Path $script:Stage ('Plugins/E04ProfileProof/Source/'+$spec[0]+'/Private/'+$spec[1])
        $compiles.Add((Get-A1GCompileEvidence $spec[0] $source $spec[2] $Before $log.text))
    }
    $library=Under (Join-Path (Artifact-Root) 'lib/yaml-cpp.lib') $script:RunRoot
    if($selection.libraryPath -ine $library -or $selection.librarySha256 -ine (Descriptor $library).sha256){throw 'A1G_GAME_SELECTED_LIBRARY_DRIFT'}
    $link=Get-A1GLinkEvidence $executable $compiles.ToArray() $Before $log.text $library
    return @{targetReceipt=$receipt.targetReceipt;executable=$link.binary;buildProducts=$receipt.buildProducts;runtimeDependencies=$receipt.runtimeDependencies;pluginSelection=$plugin;selection=Descriptor $selectionPath;vendorArtifactReceipt=$artifact;log=$log.file;process=$Process.receiptArtifact;nativeFlags=@{compileResponses=$compiles.ToArray();linkResponses=@($link);monolithicDefinitionObserved=$true};limits='Actual exception-disabled Game caller compile/link proof only; cook, stage, actual loaded process, windows, two-input result, cleanup/preservation and final acceptance remain separate.'}
}

# Bounded normal Cook/Stage consumers; exact phase authority is required.
# No top-level action, native invocation, general asset/command interpreter or
# transitive graph certification. Uses the ordinary wrapper's named leaf helpers.

function Read-A1GCookStageText([string]$Path){
    $d=Descriptor $Path;if($d.bytes -gt 64MB){throw 'A1G_COOK_STAGE_RETAINED_TEXT_CAP_PRESERVE_ORIGINAL'}
    $text=$script:Utf8.GetString([IO.File]::ReadAllBytes($d.path));if($text.StartsWith([string][char]0xFEFF,[StringComparison]::Ordinal)){$text=$text.Substring(1)};Safe-Text $text
    @{file=$d;text=$text}
}
function Remove-A1GUatTimestamps([string]$Text){
    # Installed DefaultLogger adds only this optional elapsed-time prefix.
    [regex]::Replace($Text,'(?m)^\[[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}\] ','')
}
function Get-A1GOnlyLogValue([string]$Text,[string]$Key,[switch]$Spaced){
    $separator=if($Spaced){' = '}else{'='}
    $found=@([regex]::Matches($Text,('(?m)^[\t ]*'+[regex]::Escape($Key+$separator)+'(?<value>[^\r\n]*)\r?$')))
    if($found.Count -ne 1){throw ('A1G_MISSING_OR_AMBIGUOUS_UAT_VALUE: '+$Key)}
    $found[0].Groups['value'].Value
}
function Get-A1GUatLog([string]$Name){
    $directory=Owned ('logs/uat-'+$Name)
    $found=@(Plain-Files $directory|Where-Object {[IO.Path]::GetDirectoryName($_) -ieq $directory -and [IO.Path]::GetFileName($_) -cmatch '^Log(?:_[0-9]+)?\.txt$'})
    if($found.Count -ne 1){throw 'A1G_MISSING_OR_AMBIGUOUS_NORMAL_UAT_LOG'}
    $log=Read-A1GCookStageText $found[0]
    @{file=$log.file;text=(Remove-A1GUatTimestamps $log.text);directory=$directory}
}
function Get-A1GUatIntent([string]$Text,[string]$Name){
    $blocks=@([regex]::Matches($Text,'(?ms)^[\t ]*Project Params \*+\r?\n(?<body>.*?)^[\t ]*Project Params \*+\r?$'))
    if($blocks.Count -ne 1){throw 'A1G_SINGLE_NORMAL_UAT_PROJECT_PARAMS_REQUIRED'};$body=$blocks[0].Groups['body'].Value
    $expected=[ordered]@{Build='False';SkipBuildClient='True';Cook='True';CookOnTheFly='False';DedicatedServer='False';IsProgramTarget='False';Pak='False';IoStore='False';ZenStore='False';SkipPak='False';PrePak='False';Package='False';SkipPackage='True';Archive='False';Deploy='False';Run='False';IncrementalCook='False';CookInEditor='False';IterateSharedCookedBuild='False';NoCleanStage='False';SkipStage='False';LogWindow='False';bTreatNonShippingBinariesAsDebugFiles='False';ClientConfigsToBuild='Development';ClientCookedTargets='WarhammerClientE04A1G';ClientTargetPlatform='Win64';RawProjectPath=(Join-Path $script:Stage 'WarhammerClient.uproject');MapsToCook='/Engine/Maps/Entry'}
    $expected.SkipCook=if($Name -ceq 'cook'){'False'}else{'True'}
    $expected.Stage=if($Name -ceq 'stage'){'True'}else{'False'}
    $actual=[ordered]@{}
    foreach($key in $expected.Keys){$value=Get-A1GOnlyLogValue $body $key
        if($key -ceq 'RawProjectPath'){if((Assert-Path $value) -ine (Assert-Path $expected[$key])){throw 'A1G_UAT_PROJECT_PATH_MISMATCH'}}
        elseif($value -cne $expected[$key]){throw ('A1G_UNEXPECTED_RESOLVED_UAT_INTENT: '+$key)};$actual[$key]=$value}
    # SkipCook makes Cook=true in ProjectParams. This is deliberately not tested
    # as Cook=false for Stage; the actual SkipCook flag must be true there.
    @{values=$actual;requiresPakSourcePolicy='DontCare';requiresPakRuntimeValue='NOT_DIRECTLY_LOGGED';requiresPakBasis='Exact pinned installed Win64 class inherits Platform.RequiresPak; actual emitted loose mappings/files are checked separately. Compiled UAT-to-source provenance remains a trusted installed-tool leaf.';qualification='Actual normal ProjectParams debug block plus qualified primary-source policy, not command-line intent alone or a general platform graph certificate.'}
}
function Assert-A1GLoosePlatformSources {
    foreach($row in @(
        @('Programs/AutomationTool/AutomationUtils/Platform.cs','F90A31FDE3A396FE7AF084F16B6A1B8FFBB506F0434EA0EE2AE8637397775397'),
        @('Programs/AutomationTool/Win/WinPlatform.Automation.cs','FB0A1E8E294AA48D29C2455FE0D0F23F9F2B71A567CD42C5EC62BB7BE1147C45'))){
        $path=Join-Path (Join-Path $EngineRoot 'Engine/Source') $row[0];$actual=Descriptor $path
        if($actual.sha256 -ine $row[1]){throw 'A1G_SELECTED_WIN64_LOOSE_PLATFORM_SOURCE_CHANGED'}
        $frozen=@($script:Freeze.files|Where-Object {$_.path -ieq $actual.path -and $_.bytes -eq $actual.bytes -and $_.sha256 -ieq $actual.sha256})
        if($frozen.Count -ne 1){throw 'A1G_WIN64_LOOSE_PLATFORM_PRIMARY_NOT_UNIQUELY_FROZEN'}
    }
}
function Assert-A1GUatRoot($Process,[string]$Name){
    if($Name -cnotin @('cook','stage')){throw 'A1G_UAT_PHASE_NAME'}
    [void](Check-Descriptor $Process.receiptArtifact);$raw=Read-Json $Process.receiptArtifact.path
    Require-RootPass $raw
    if($raw.technicalBlocked -or $null -ne $raw.primaryFailure -or @($raw.secondaryErrors).Count -or $raw.visibleWindowRequested -or -not $raw.assignedBeforeResume -or -not $raw.resumed -or $raw.completionCleanupMode -cne 'NaturalDrain' -or $raw.jobAccounting[-1].querySucceeded -ne $true){throw 'A1G_UAT_PROCESS_OR_CLEANUP_MISMATCH'}
    if((Assert-Path $raw.executable) -ine (Assert-Path $script:Freeze.toolPaths.dotnet) -or (Assert-Path $raw.workingDirectory) -ine (Assert-Path (Split-Path $script:Freeze.toolPaths.uat -Parent))){throw 'A1G_UAT_EXECUTABLE_OR_CWD_MISMATCH'}
    $expected=@(if($Name -ceq 'cook'){Uat-Arguments -Cook}else{Uat-Arguments})
    Equal-Data @($raw.arguments) $expected 'actual UAT root argv'
    foreach($pair in @(@('uebp_LOCAL_ROOT',$EngineRoot),@('uebp_EngineSavedFolder',(Owned ('temp/uat-'+$Name))),@('uebp_LogFolder',(Owned ('logs/uat-'+$Name))),@('uebp_FinalLogFolder',(Owned ('logs/uat-'+$Name))),@('TEMP',(Owned ('temp/'+$Name))),@('TMP',(Owned ('temp/'+$Name))),@('DOTNET_CLI_HOME',(Owned ('dotnet-home/'+$Name))),@('NUGET_PACKAGES',(Owned 'nuget')))){
        if((Assert-Path $raw.environmentOverrides[$pair[0]]) -ine (Assert-Path $pair[1])){throw ('A1G_UAT_ENVIRONMENT_PATH_MISMATCH: '+$pair[0])}}
    foreach($path in @($raw.stdout,$raw.stderr)){[void](Read-A1GCookStageText $path)}
    $raw
}
function Get-A1GClosedPriorResult([string]$Name,[string]$Field){
    $directory=Owned $Name.ToLowerInvariant();$completion=Read-Json (Join-Path $directory 'completion.json')
    if($completion.phase -cne $Name -or $completion.runId -cne $RunId -or $completion.sourceHead -cne $script:Freeze.sourceHead -or $completion.freezeManifestSha256 -ine $ExpectedFreezeSha256 -or $completion.state -cne 'COMPLETE' -or $completion.executionPassed -ne $true){throw 'A1G_CLOSED_SAME_RUN_PHASE_REQUIRED'}
    [void](Check-Descriptor $completion.result);$r=Read-Json $completion.result.path
    if($r.phase -cne $Name -or $r.runId -cne $RunId -or $r.sourceHead -cne $script:Freeze.sourceHead -or $r.executionPassed -ne $true -or $null -ne $r.primaryFailure -or @($r.secondaryErrors).Count -or $r[$Field] -isnot [Collections.IDictionary]){throw 'A1G_POSITIVE_PRIOR_PHASE_FACTS_REQUIRED'}
    @{result=$completion.result;facts=$r[$Field]}
}
function Assert-A1GCookEditorPrerequisite($Editor){
    if($Editor.pluginSelection.proofPluginEnabled -ne $false -or $Editor.projectModule.module -cne 'WarhammerClient'){throw 'A1G_NORMAL_EDITOR_PLUGIN_DISABLED_PREREQUISITE_REQUIRED'}
    foreach($d in @($Editor.targetReceipt,$Editor.launch,$Editor.launchCmd,$Editor.projectModule.manifest,$Editor.projectModule.binary,$Editor.pluginSelection.descriptor,$Editor.pluginSelection.project)){[void](Check-Descriptor $d)}
    if((Assert-Path $Editor.launchCmd.path) -ine (Assert-Path $script:Freeze.toolPaths.editorCmd)){throw 'A1G_COOK_EDITOR_EXECUTABLE_MISMATCH'}
    $receipt=Read-Json $Editor.targetReceipt.path
    if($receipt.TargetType -cne 'Editor' -or $receipt.TargetName -cne 'WarhammerClientEditor' -or $receipt.Platform -cne 'Win64' -or $receipt.Configuration -cne 'Development' -or @($receipt.Plugins|Where-Object {$_.Name -ceq 'E04ProfileProof' -and $_.Enabled}).Count){throw 'A1G_COOK_NORMAL_EDITOR_RECEIPT_MISMATCH'}
    $plugin=Read-Json $Editor.pluginSelection.descriptor.path;$project=Read-Json $Editor.pluginSelection.project.path
    if($plugin.EnabledByDefault -ne $false -or @($project.Plugins|Where-Object {$_.Name -ceq 'E04ProfileProof' -and $_.Enabled}).Count){throw 'A1G_COOK_EDITOR_PROOF_PLUGIN_ENABLE'}
    $manifest=Read-Json $Editor.projectModule.manifest.path
    if(@($manifest.Modules.Keys|Where-Object {$_ -in @('E04ProfileParser','E04ProfileProbe','E04ProfileGameProbe')}).Count){throw 'A1G_COOK_EDITOR_MODULE_MANIFEST_ENABLES_PROOF'}
}
function Prepare-A1GCookStagePhase([string]$Name){
    if($Phase.ToLowerInvariant() -cne $Name -or $Name -cnotin @('cook','stage') -or $script:RunRoot -match '\s'){throw 'A1G_EXACT_NOSPACE_UAT_OWNERSHIP_REQUIRED'}
    Assert-A1GLoosePlatformSources
    foreach($path in @((Owned ('logs/uat-'+$Name)),(Owned ('temp/uat-'+$Name)))){if(Test-Path -LiteralPath $path){throw 'A1G_UAT_REQUIRES_FRESH_PHASE_LOG_AND_ENGINE_SAVED_DIRECTORIES'}}
    # Uat-Environment creates the two directories above. Create only its other
    # exact child roots here, so no inherited TEMP/DotNet-home fallback is needed.
    foreach($path in @((Owned ('temp/'+$Name)),(Owned ('dotnet-home/'+$Name)))){New-Directory $path}
    $editor=Get-A1GClosedPriorResult 'EditorPrerequisiteBuild' 'editorPrerequisiteBuild';Assert-A1GCookEditorPrerequisite $editor.facts
    $game=Get-A1GClosedPriorResult 'GameBuild' 'gameBuild'
    foreach($d in @($game.facts.targetReceipt,$game.facts.executable,$game.facts.selection,$game.facts.vendorArtifactReceipt)){[void](Check-Descriptor $d)}
    if($Name -ceq 'cook'){
        if(Test-Path -LiteralPath (Owned 'cook')){throw 'A1G_COOK_OUTPUT_REQUIRES_PREABSENCE'}
        @{name=$Name;editor=$editor;game=$game;outputPreabsence=$true;observedUtc=[DateTime]::UtcNow.ToString('o')}
    }else{
        if(Test-Path -LiteralPath (Owned 'stage')){throw 'A1G_STAGE_OUTPUT_REQUIRES_PREABSENCE'}
        $cook=Get-A1GClosedPriorResult 'Cook' 'cook';Confirm-A1GCookedFiles $cook.facts
        @{name=$Name;editor=$editor;game=$game;cook=$cook;outputPreabsence=$true;observedUtc=[DateTime]::UtcNow.ToString('o')}
    }
}
function Split-A1GSimpleCookArguments([string]$Text){
    # Deliberately finite observed text syntax for this no-space owned project.
    # No backslash-quote decoding, shell expansion or captured-command execution.
    if($Text.Contains('\"') -or $Text.Contains('""') -or $Text.Contains([char]0)){throw 'A1G_UNSUPPORTED_COOK_ARGUMENT_TEXT_SYNTAX'}
    $found=@([regex]::Matches($Text,'(?:[^\s"]+|"[^"\r\n]*")+'))
    if(-not $found.Count -or ([regex]::Replace($Text,'(?:[^\s"]+|"[^"\r\n]*")+','')).Trim().Length){throw 'A1G_UNPARSED_COOK_ARGUMENT_TEXT'}
    @($found|ForEach-Object {$_.Value.Replace('"','')})
}
function Assert-A1GExactCookArgument([string[]]$Arguments,[string]$Name,[string]$Value='',[switch]$PathValue){
    $pattern='(?i)^-'+[regex]::Escape($Name)+'(?:=(?<value>.*))?$'
    $found=@(foreach($arg in $Arguments){$match=[regex]::Match($arg,$pattern);if($match.Success){$match}})
    if($found.Count -ne 1){throw ('A1G_MISSING_OR_DUPLICATE_COOK_ARGUMENT: '+$Name)}
    $actual=$found[0].Groups['value'].Value
    if($PathValue){if((Assert-Path $actual) -ine (Assert-Path $Value)){throw ('A1G_COOK_ARGUMENT_PATH_MISMATCH: '+$Name)}}
    elseif($actual -cne $Value){throw ('A1G_COOK_ARGUMENT_VALUE_MISMATCH: '+$Name)}
}
function Get-A1GCookArgumentEvidence([string]$UatText,[string]$CookText){
    $editor=$script:Freeze.toolPaths.editorCmd.Replace('\','/')
    $normalized=$UatText.Replace('\','/')
    $runs=@([regex]::Matches($normalized,('(?m)^Running: "?'+[regex]::Escape($editor)+'"? (?<args>[^\r\n]*)\r?$'))|Where-Object {$_.Groups['args'].Value -match '(?i)(?:^|\s)-run=Cook(?:\s|$)'})
    if($runs.Count -ne 1){throw 'A1G_ONE_ACTUAL_COOK_CHILD_COMMAND_REQUIRED'}
    $arguments=@(Split-A1GSimpleCookArguments $runs[0].Groups['args'].Value)
    if(@($arguments|Where-Object {$_ -ieq (Join-Path $script:Stage 'WarhammerClient.uproject').Replace('\','/')}).Count -ne 1){throw 'A1G_COOK_CHILD_PROJECT_ARGUMENT'}
    foreach($pair in @(@('run','Cook'),@('TargetPlatform','Windows'),@('Map','/Engine/Maps/Entry'),@('outputdir',(Owned 'cook/Windows')), @('UserDir',(Owned 'ue-user/cook')),@('ShaderWorkingDir',(Owned 'shader-work/cook')))){
        Assert-A1GExactCookArgument $arguments $pair[0] $pair[1] -PathValue:($pair[0] -in @('outputdir','UserDir','ShaderWorkingDir'))}
    foreach($flag in @('SkipZenStore','NullRHI','RenderOffScreen','NoSplash','nosound','NoSourceControl','NoLiveCoding','DDC-NoDefaultGraph','NoRemoteShaderCompile','stdout','CrashForUAT','unattended','NoLogTimes')){Assert-A1GExactCookArgument $arguments $flag}
    $ddc='(E04A1G=(Type=FileSystem,Path='+(Owned 'ddc/cook').Replace('\','/')+',ReadOnly=false,Remote=false,DeleteUnused=false))'
    Assert-A1GExactCookArgument $arguments 'DDC' $ddc
    $abslog=@($arguments|Where-Object {$_ -match '(?i)^-abslog='});if($abslog.Count -ne 1){throw 'A1G_ONE_COOK_CHILD_ABSLOG_REQUIRED'}
    $temporary=Under $abslog[0].Substring(8) (Owned 'temp/uat-cook')
    foreach($arg in $arguments){if($arg -match '(?i)^-(?:EnablePlugins?|Plugin|PluginDir|AdditionalPluginDirectories|CookOnTheFly|CookInEditor|iterate|IterateSharedCookedBuild|CookProcessCount|AllowCommandletRendering|AllowCommandletAudio|NoDefaultMaps|DisableUnsolicitedPackages|SkipHardReferences|SkipSoftReferences|ZenStore|Pak|IoStore)(?:=|$)'){throw 'A1G_FORBIDDEN_COOK_CHILD_MODE_OR_PLUGIN_ARGUMENT'}}
    $received=@([regex]::Matches($CookText,'(?m)^LogInit: (?:Filtered )?Command Line: (?<args>[^\r\n]*)\r?$'))
    if($received.Count -ne 1 -or $received[0].Value.Contains('Filtered Command Line:')){throw 'A1G_UNFILTERED_OWN_COOK_RECEIVED_ARGUMENTS_REQUIRED'}
    $ownArguments=@(Split-A1GSimpleCookArguments $received[0].Groups['args'].Value|ForEach-Object {$_.Replace('\','/')})
    # Normal UE startup may remove the initial project token before logging.
    $withoutProject=@($arguments|Where-Object {$_ -ine (Join-Path $script:Stage 'WarhammerClient.uproject').Replace('\','/')})
    $ownWithoutProject=@($ownArguments|Where-Object {$_ -ine (Join-Path $script:Stage 'WarhammerClient.uproject').Replace('\','/')})
    Equal-Data $withoutProject $ownWithoutProject 'UAT sent versus own unfiltered Cook argument tokens'
    @{sentArguments=$arguments;ownReceivedArguments=$ownArguments;temporaryAbslog=$temporary;scope='Exact finite literal argument observations; not OS argv/whole-descendant attestation.'}
}
function Get-A1GCookDdc([string]$Text){
    $rows=@($Text -split "`n"|Where-Object {$_ -match '\bLogDerivedDataCache:'});$expected=(Owned 'ddc/cook').Replace('\','/');$writers=[Collections.Generic.List[object]]::new()
    foreach($row in $rows){
        if($row -match '(?i)(falling back|fallback.*(?:enabled|using)|(?:Zen|Cloud|Shared).*\b(?:using|connected|enabled|running)\b|Failed to create graph\b|Attempting to create graph\b)'){throw 'A1G_COOK_DDC_FALLBACK_OR_NONOWNED_BACKEND'}
        $match=[regex]::Match($row,'\bLogDerivedDataCache:\s+(?<store>[^:\r\n]+): Using data cache path (?<path>[^\r\n]+): (?<access>Writable|ReadOnly|DeleteOnly)\r?$')
        if($row -match '(?i)\bWritable\b'){
            if(-not $match.Success -or $match.Groups['store'].Value -cne 'E04A1G' -or $match.Groups['access'].Value -cne 'Writable'){throw 'A1G_COOK_UNSELECTED_DDC_WRITER'}
            $path=$match.Groups['path'].Value.Replace('\','/').TrimEnd('/')
            if($path -ine $expected){throw 'A1G_COOK_NONOWNED_DDC_WRITER'}
            $writers.Add(@{store='E04A1G';path=(Assert-Path $path);access='Writable'})}}
    if(-not $writers.Count){throw 'A1G_COOK_POSITIVE_OWNED_DDC_BACKEND_REQUIRED'}
    @{writers=$writers.ToArray();observedRows=$rows;scope='Positive retained filesystem-backend log observations; no universal write-isolation claim.'}
}
function Get-A1GCookedInventory {
    $root=Owned 'cook/Windows';$files=@(foreach($path in Plain-Files $root){$d=Descriptor $path;if($d.bytes -gt 64MB){throw 'A1G_COOK_DATA_FILE_CAP_PRESERVE_ORIGINAL'};@{relativePath=[IO.Path]::GetRelativePath($root,$path).Replace('\','/');file=$d}})
    if(-not $files.Count -or ($files|Measure-Object -Property {$_.file.bytes} -Sum).Sum -gt 8GB){throw 'A1G_COOK_EMPTY_OR_STORAGE_CAP'}
    if(@($files|Where-Object {$_.relativePath -match '(?i)(?:^|/)(?:zenfs\.manifest|ue\.projectstore)$|\.(?:pak|utoc|ucas)$'}).Count){throw 'A1G_COOK_UNEXPECTED_ZEN_OR_CONTAINER_OUTPUT'}
    $files
}
function Confirm-A1GCookedFiles($Cook){
    $actual=@(Get-A1GCookedInventory);$prior=@($Cook.files)
    Equal-Data @($prior|Sort-Object relativePath -CaseSensitive) @($actual|Sort-Object relativePath -CaseSensitive) 'same-run full cooked-file membership and bytes'
    foreach($d in @($Cook.copiedChildLog,$Cook.uatLog)){[void](Check-Descriptor $d)}
}
function Complete-A1GCookPhase($Process,$Before){
    if($Before.name -cne 'cook' -or -not $Before.outputPreabsence){throw 'A1G_COOK_PRELAUNCH_FACTS_REQUIRED'}
    $raw=Assert-A1GUatRoot $Process 'cook';Assert-A1GCookEditorPrerequisite $Before.editor.facts
    $uat=Get-A1GUatLog 'cook';$intent=Get-A1GUatIntent $uat.text 'cook'
    if($uat.text -match '(?i)Commandlet Cook failed to copy the local log file|Ignoring cook failure|BUILD FAILED|ERROR:|AutomationTool exiting with ExitCode=[1-9]'){throw 'A1G_COOK_OUTER_LOG_FAILURE_OR_LOST_CHILD_LOG'}
    if(@([regex]::Matches($uat.text,'(?m)^\*+ COOK COMMAND COMPLETED \*+\r?$')).Count -ne 1 -or @([regex]::Matches($uat.text,'(?m)^Took [^\r\n]+ to run UnrealEditor-Cmd\.exe, ExitCode=0\r?$')).Count -ne 1){throw 'A1G_COOK_UNAMBIGUOUS_NORMAL_CHILD_CLOSURE_REQUIRED'}
    $logs=@(Plain-Files $uat.directory|Where-Object {[IO.Path]::GetDirectoryName($_) -ieq $uat.directory -and [IO.Path]::GetFileName($_) -cmatch '^Cook-[0-9]{4}\.[0-9]{2}\.[0-9]{2}-[0-9]{2}\.[0-9]{2}\.[0-9]{2}\.txt$'})
    if($logs.Count -ne 1){throw 'A1G_ONE_RETAINED_FINAL_COPIED_COOK_LOG_REQUIRED'};$child=Read-A1GCookStageText $logs[0]
    $lines=@($child.text -split "`n"|Where-Object {-not [string]::IsNullOrWhiteSpace($_)})
    if(-not $lines.Count -or $lines[-1] -notmatch '^Log file closed, [^\r\n]+\r?$' -or @([regex]::Matches($child.text,'(?m)^LogInit: Display: Success - 0 error\(s\), [0-9]+ warning\(s\)\r?$')).Count -ne 1 -or $child.text -match '(?im)\b(?:Fatal error:|Critical error:|Log[^:\r\n]*: Error:)'){throw 'A1G_COOK_COPIED_LOG_INCOMPLETE_OR_FAILED'}
    if($child.text -match '(?im)LogPluginManager:.*(?:Mounting|Enabling).*\bE04ProfileProof\b|LogModuleManager:.*(?:Loaded|Loading).*\bE04Profile(?:Parser|Probe|GameProbe)\b'){throw 'A1G_COOK_EDITOR_PROOF_PLUGIN_OBSERVED_ENABLED'}
    $argv=Get-A1GCookArgumentEvidence $uat.text $child.text;$ddc=Get-A1GCookDdc $child.text
    $files=@(Get-A1GCookedInventory)
    $dev=@([regex]::Matches($child.text,'(?m)^LogAssetRegistryGenerator: Display: Generated development asset registry (?<path>[^\r\n]+) num assets [0-9]+, size is [^\r\n]+\r?$'))
    if($dev.Count -ne 1){throw 'A1G_COOK_DEVELOPMENT_REGISTRY_OUTPUT_IDENTITY_REQUIRED'}
    $devPath=Under $dev[0].Groups['path'].Value (Owned 'cook/Windows');$metadataRoot=[IO.Path]::GetDirectoryName($devPath)
    if([IO.Path]::GetFileName($metadataRoot) -cne 'Metadata'){throw 'A1G_COOK_EMITTED_METADATA_DIRECTORY_MISMATCH'}
    $metadata=@($files|Where-Object {$_.file.path.StartsWith($metadataRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)})
    $runtime=@($files|Where-Object {[IO.Path]::GetFileName($_.file.path) -ceq 'AssetRegistry.bin'})
    $maps=@($files|Where-Object {[IO.Path]::GetExtension($_.file.path) -ceq '.umap'})
    if(-not $metadata.Count -or -not $runtime.Count -or -not $maps.Count -or @($files|Where-Object {$_.file.path -ieq $devPath -and $_.file.bytes -gt 0}).Count -ne 1 -or $child.text -notmatch 'LogAssetRegistryGenerator: Display: Generated asset registry (?:\[chunkbucket [0-9]+\] )?num assets [0-9]+, size is '){throw 'A1G_COOK_ACTUAL_REGISTRY_METADATA_MAP_OUTPUTS_REQUIRED'}
    foreach($row in $metadata+$runtime+$maps){if($row.file.bytes -le 0){throw 'A1G_EMPTY_COOK_PRIMARY_OUTPUT'}}
    # packagestore.manifest is compact binary in this installed loose writer,
    # not JSON. Retain its bytes without inventing a decoder/certification path.
    foreach($d in @($Before.game.facts.targetReceipt,$Before.game.facts.executable)){[void](Check-Descriptor $d)}
    @{uatLog=$uat.file;copiedChildLog=$child.file;process=$Process.receiptArtifact;resolvedIntent=$intent;cookChildArguments=$argv;ddc=$ddc;outputRoot=(Owned 'cook/Windows');files=$files;metadataRoot=$metadataRoot;metadataFiles=$metadata;runtimeRegistries=$runtime;mapFiles=$maps;editorPrerequisite=$Before.editor.result;gameBuild=$Before.game.result;entryPackageRequested='/Engine/Maps/Entry';scope='Real same-run normal loose cook/log/output facts. Actual map filenames are discovered output files; Entry package identity and functional startup dependencies must still be established by later actual Native Entry-world load. No broad cooked/transitive-graph certificate.'}
}
function Read-A1GCopyMap([string]$Path,[string]$StageRoot,[string]$Kind){
    $text=Read-A1GCookStageText $Path;$rows=[Collections.Generic.List[object]]::new();$seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach($line in $text.text -split "`n"){
        if([string]::IsNullOrWhiteSpace($line)){continue};$match=[regex]::Match($line,'^"(?<source>[^"\r\n]+)" "(?<relative>[^"\r\n]+)"\r?$')
        if(-not $match.Success){throw 'A1G_UNSUPPORTED_NORMAL_FINALCOPY_MANIFEST_LINE'}
        $source=Assert-Path $match.Groups['source'].Value;$relative=$match.Groups['relative'].Value.Replace('\','/')
        if([IO.Path]::IsPathFullyQualified($relative) -or $relative -match '[\x00-\x1f\x7f:]' -or @($relative.Split('/')|Where-Object {$_ -in @('','.','..')}).Count -or -not $seen.Add($relative)){throw 'A1G_STAGE_MANIFEST_PATH_ESCAPE_OR_COLLISION'}
        if(-not $source.StartsWith($script:RunRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -and -not $source.StartsWith((Assert-Path $EngineRoot)+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'A1G_STAGE_SOURCE_OUTSIDE_RUN_OR_PINNED_ENGINE'}
        $sourceFile=Descriptor $source;$staged=Descriptor (Under (Join-Path $StageRoot $relative) $StageRoot)
        # Descriptor-only normal binary payloads stay in owned project/stage paths.
        # They are never copied into capped text/data artifacts; stage/run aggregate caps remain.
        $extension=[IO.Path]::GetExtension($source)
        $binaryPayload=$Kind -in @('NonUFSFiles','NonUFSFilesDebug') -and $extension -in @('.exe','.dll','.pdb') -and [IO.Path]::GetExtension($staged.path) -ieq $extension
        if(($sourceFile.bytes -gt 64MB -or $staged.bytes -gt 64MB) -and -not $binaryPayload){throw 'A1G_STAGE_DATA_FILE_CAP_PRESERVE_ORIGINAL'}
        $equal=$sourceFile.bytes -eq $staged.bytes -and $sourceFile.sha256 -ieq $staged.sha256
        if(-not $equal -and [IO.Path]::GetExtension($source) -ine '.ini'){throw 'A1G_STAGE_COPY_SOURCE_BYTES_MISMATCH'}
        $rows.Add(@{kind=$Kind;relativePath=$relative;source=$sourceFile;staged=$staged;byteIdentical=$equal;copyQualification=if($equal){'EXACT_BYTES'}else{'INI_MAY_BE_SANITIZED_BY_NORMAL_COPY_NO_SOURCE_BYTE_EQUALITY_CLAIM'}})
    }
    if(-not $rows.Count){throw 'A1G_EMPTY_REQUIRED_STAGE_COPY_MANIFEST'}
    @{manifest=$text.file;rows=$rows.ToArray()}
}
function Confirm-A1GTimestampManifest([string]$Path,$Rows){
    $text=Read-A1GCookStageText $Path;$found=[Collections.Generic.List[string]]::new()
    foreach($line in $text.text -split "`n"){
        if([string]::IsNullOrWhiteSpace($line)){continue};$parts=$line.TrimEnd("`r") -split "`t"
        if($parts.Count -ne 2 -or ($parts[1] -cnotmatch '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}Z$' -and $parts[1] -cnotmatch '^[0-9A-F]{32}$')){throw 'A1G_UNSUPPORTED_NORMAL_STAGE_TIMESTAMP_MANIFEST'}
        $found.Add($parts[0].Replace('\','/'))}
    Equal-Data @($found|Sort-Object -CaseSensitive) @($Rows.relativePath|Sort-Object -CaseSensitive) 'emitted stage timestamp versus actual FinalCopy destination membership'
    $text.file
}
function Complete-A1GStagePhase($Process,$Before){
    if($Before.name -cne 'stage' -or -not $Before.outputPreabsence){throw 'A1G_STAGE_PRELAUNCH_FACTS_REQUIRED'}
    $raw=Assert-A1GUatRoot $Process 'stage';$uat=Get-A1GUatLog 'stage';$intent=Get-A1GUatIntent $uat.text 'stage'
    if($uat.text -match '(?i)BUILD FAILED|ERROR:|AutomationTool exiting with ExitCode=[1-9]' -or @([regex]::Matches($uat.text,'(?m)^\*+ STAGE COMMAND COMPLETED \*+\r?$')).Count -ne 1 -or $uat.text -match '(?m)^Running: .*UnrealEditor-Cmd\.exe .*-(?:run=Cook|run=cook)\b'){throw 'A1G_STAGE_FAILED_OR_RECOOKED'}
    $contexts=@([regex]::Matches($uat.text,'(?ms)^[\t ]*Deployment Context \*+\r?\n(?<body>.*?)^[\t ]*End Deployment Context \*+\r?$'))
    if($contexts.Count -ne 1){throw 'A1G_ONE_ACTUAL_STAGE_DEPLOYMENT_CONTEXT_REQUIRED'};$context=$contexts[0].Groups['body'].Value
    $platform=Get-A1GOnlyLogValue $context 'StageTargetPlatform' -Spaced;$dir=Get-A1GOnlyLogValue $context 'PlatformDir' -Spaced;$project=Get-A1GOnlyLogValue $context 'ShortProjectName' -Spaced
    $stageRoot=Under (Get-A1GOnlyLogValue $context 'StagedOutputDir' -Spaced) (Owned 'stage')
    if($platform -cne 'Win64' -or $dir -cne 'Win64' -or $project -cne [IO.Path]::GetFileNameWithoutExtension((Join-Path $script:Stage 'WarhammerClient.uproject')) -or (Get-A1GOnlyLogValue $context 'DedicatedServer' -Spaced) -cne 'False' -or (Get-A1GOnlyLogValue $context 'Stage' -Spaced) -cne 'True' -or [IO.Path]::GetFileName($stageRoot) -cne 'Windows'){throw 'A1G_ACTUAL_STAGE_PLATFORM_LAYOUT_MISMATCH'}
    if((Assert-Path (Get-A1GOnlyLogValue $context 'InputProjectDir' -Spaced)) -ine $script:Stage -or (Assert-Path (Get-A1GOnlyLogValue $context 'RunRootDir' -Spaced)) -ine $stageRoot){throw 'A1G_STAGE_PROJECT_OR_RUNTIME_ROOT_MISMATCH'}
    $maps=@{};$timestamps=@{};$stagedManifestFiles=[Collections.Generic.List[string]]::new()
    $kinds=@(@('UFSFiles','UFSFiles'),@('NonUFSFiles','NonUFSFiles'))
    if([IO.File]::Exists((Join-Path $uat.directory ('FinalCopy'+$platform+'_NonUFSFilesDebug.txt')))){$kinds+=,@('NonUFSFilesDebug','DebugFiles')}
    foreach($pair in $kinds){
        $kind=$pair[0];$path=Join-Path $uat.directory ('FinalCopy'+$platform+'_'+$kind+'.txt');$maps[$kind]=Read-A1GCopyMap $path $stageRoot $kind
        $timestampPath=Join-Path $uat.directory ('Manifest_'+$pair[1]+'_'+$platform+'.txt');$timestamps[$kind]=Confirm-A1GTimestampManifest $timestampPath $maps[$kind].rows
        $stagedManifest=Join-Path $stageRoot ([IO.Path]::GetFileName($timestampPath));$copy=Descriptor $stagedManifest
        if($copy.bytes -ne $timestamps[$kind].bytes -or $copy.sha256 -ine $timestamps[$kind].sha256){throw 'A1G_STAGED_MANIFEST_RAW_COPY_MISMATCH'}
        $stagedManifestFiles.Add($stagedManifest)
    }
    $allRows=@(foreach($pair in $kinds){$maps[$pair[0]].rows})
    $duplicate=@($allRows|Group-Object relativePath|Where-Object Count -GT 1);if($duplicate.Count){throw 'A1G_UFS_NONUFS_DESTINATION_COLLISION'}
    $exe=Check-Descriptor $Before.game.facts.executable
    $executableRows=@($maps.NonUFSFiles.rows|Where-Object {$_.source.path -ieq $exe.path -and $_.byteIdentical})
    if($executableRows.Count -ne 1){throw 'A1G_GAME_RECEIPT_EXECUTABLE_NOT_UNIQUELY_LOOSE_STAGED'}
    foreach($product in $Before.game.facts.buildProducts|Where-Object {$_.type -in @('Executable','DynamicLibrary','RequiredResource')}){
        [void](Check-Descriptor $product.file);if(@($maps.NonUFSFiles.rows|Where-Object {$_.source.path -ieq $product.file.path -and $_.byteIdentical}).Count -ne 1){throw 'A1G_REQUIRED_GAME_BUILD_PRODUCT_NOT_LOOSE_STAGED'}}
    $cookRoot=Assert-Path $Before.cook.facts.outputRoot
    $cookedRows=@($maps.UFSFiles.rows|Where-Object {$_.source.path.StartsWith($cookRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)})
    $stagedMaps=@($cookedRows|Where-Object {[IO.Path]::GetExtension($_.source.path) -ceq '.umap'})
    $stagedRegistries=@($cookedRows|Where-Object {[IO.Path]::GetFileName($_.source.path) -ceq 'AssetRegistry.bin'})
    if(-not $cookedRows.Count -or -not $stagedMaps.Count -or -not $stagedRegistries.Count){throw 'A1G_REAL_COOKED_MAP_REGISTRY_BYTES_NOT_LOOSE_STAGED'}
    foreach($row in $cookedRows){if(-not $row.byteIdentical){throw 'A1G_COOKED_BYTES_CHANGED_DURING_STAGE'}}
    Confirm-A1GCookedFiles $Before.cook.facts
    $allFiles=@(foreach($path in Plain-Files $stageRoot){$d=Descriptor $path;if($d.bytes -gt 64MB -and [IO.Path]::GetExtension($path) -notin @('.exe','.dll','.pdb')){throw 'A1G_STAGE_FILE_CAP_PRESERVE_ORIGINAL'};@{relativePath=[IO.Path]::GetRelativePath($stageRoot,$path).Replace('\','/');file=$d}})
    if(($allFiles|Measure-Object -Property {$_.file.bytes} -Sum).Sum -gt 8GB -or @($allFiles|Where-Object {$_.relativePath -match '(?i)(?:^|/)(?:zenfs\.manifest|ue\.projectstore)$|\.(?:pak|utoc|ucas)$'}).Count){throw 'A1G_STAGE_CAP_OR_UNEXPECTED_CONTAINER_OR_ZEN_MARKER'}
    foreach($row in $allFiles){[void](Under $row.file.path $stageRoot)}
    $expectedPaths=@($allRows.staged.path)+$stagedManifestFiles.ToArray()
    Equal-Data @($allFiles.file.path|Sort-Object -CaseSensitive) @($expectedPaths|Sort-Object -CaseSensitive) 'actual stage files versus emitted copy maps and copied timestamp manifests'
    @{uatLog=$uat.file;process=$Process.receiptArtifact;resolvedIntent=$intent;stageRoot=$stageRoot;platform=$platform;projectName=$project;copyManifests=@(foreach($pair in $kinds){$maps[$pair[0]].manifest});timestampManifests=@(foreach($pair in $kinds){$timestamps[$pair[0]]});copyRows=$allRows;files=$allFiles;executable=$executableRows[0].staged;originalGameExecutable=$exe;gameTargetReceipt=$Before.game.facts.targetReceipt;cookedMaps=$stagedMaps;cookedRuntimeRegistries=$stagedRegistries;cookResult=$Before.cook.result;scope='Observed normal loose-stage mappings/current bytes and receipt executable. Binary registry/package-store contents are retained opaque data. Later actual Native cooked Game/Entry world supplies functional startup-dependency proof; no comprehensive transitive asset graph certification.'}
}

# Bounded Native/Audit consumers. Source definitions do not grant execution.
# Requires the separate wrapper/UBT/CookStage definitions and the separately
# reviewed opt-in same-job observer entry. No Rules/cache/witness branch.

function Get-A1GUnownedGameSettings {
    # Capture from Preflight onward as a separate one-role array. Do not change
    # the established nine-role Settings/Check-Settings contract or its baseline.
    $context=Execution-UserContext
    if(($context|ConvertTo-Json -Compress) -cne ($script:E02UserContext|ConvertTo-Json -Compress)){throw 'A1G_GAME_SETTINGS_CONTEXT_CHANGED'}
    @(Observed-File 'game-medium-user-settings' (Join-Path $context.localApplicationData 'WarhammerClient/Saved/Config/Windows/GameUserSettings.ini'))
}

function Check-A1GUnownedGameSettings($Before,$After) {
    $expected=@(Get-A1GUnownedGameSettings)[0]
    foreach($set in @(@{rows=@($Before)},@{rows=@($After)})){
        if($set.rows.Count -ne 1){throw 'A1G_GAME_SETTINGS_BASELINE_MISSING'}
        $row=$set.rows[0]
        if($row.role -cne 'game-medium-user-settings' -or $row.path -cne $expected.path -or $row.pathPolicy -cne 'STRICT_NO_REPARSE_PATH' -or $row.inspection -cne 'PASS' -or $row.exists -isnot [bool] -or ($row.exists -and $row.sha256 -cnotmatch '^[a-f0-9]{64}$') -or (-not $row.exists -and $null -ne $row.sha256)){throw 'A1G_GAME_SETTINGS_OBSERVATION_INVALID'}
    }
    $left=@($Before)[0];$right=@($After)[0]
    if($left.path -cne $right.path -or $left.exists -cne $right.exists -or $left.sha256 -cne $right.sha256){throw 'A1G_UNOWNED_GAME_SETTINGS_CHANGED'}
}

function Get-A1GNativePaths {
    @{log=(Owned 'logs/native-game.log');result=(Owned 'reports/game-probe/result.json');user=(Owned 'ue-user/native');ddc=(Owned 'ddc/native');shader=(Owned 'shader-work/native');gameUserSettings=(Owned 'ue-user/native/Saved/Config/Windows/GameUserSettings.ini')}
}

function Get-A1GNativeArguments($Executable,$Paths) {
    if($script:RunRoot -match '\s'){throw 'A1G_NATIVE_REQUIRES_FROZEN_NOSPACE_ROOT'}
    @('-NullRHI','-RenderOffScreen','-unattended','-nosound','-NoSplash','-NoSourceControl','-NoLiveCoding','-NoLogTimes','-stdout','-FullStdOutLogOutput',
      ('-abslog='+$Paths.log),('-UserDir='+$Paths.user),('-ShaderWorkingDir='+$Paths.shader),'-NoRemoteShaderCompile',
      '-DDC-NoDefaultGraph',('-DDC=(E04A1G=(Type=FileSystem,Path='+$Paths.ddc+',ReadOnly=false,Remote=false,DeleteUnused=false))'),
      '-ExpectMediumIntegrityLevel',('-GameUserSettingsINI='+$Paths.gameUserSettings),
      ('-E04A1GRunId='+$RunId),('-E04A1GSourceHead='+$script:Freeze.sourceHead),('-E04A1GRunRoot='+$script:RunRoot),
      ('-E04A1GResult='+$Paths.result),('-E04A1GBinary='+$Executable.path),('-E04A1GBinarySha256='+$Executable.sha256))
}

function Confirm-A1GStageFiles($StageFacts) {
    $root=Under $StageFacts.stageRoot (Owned 'stage')
    $actual=@(foreach($p in Plain-Files $root){@{relativePath=[IO.Path]::GetRelativePath($root,$p).Replace('\','/');file=Descriptor $p}})
    Equal-Data @($StageFacts.files|Sort-Object relativePath -CaseSensitive) @($actual|Sort-Object relativePath -CaseSensitive) 'actual loose-stage membership and bytes'
    foreach($d in @($StageFacts.executable,$StageFacts.originalGameExecutable,$StageFacts.gameTargetReceipt)+@($StageFacts.copyManifests)+@($StageFacts.timestampManifests)){[void](Check-Descriptor $d)}
    return $actual
}

function Get-A1GNativePriorJoin {
    $game=Get-A1GClosedPriorResult 'GameBuild' 'gameBuild';$cook=Get-A1GClosedPriorResult 'Cook' 'cook';$stage=Get-A1GClosedPriorResult 'Stage' 'stage'
    Confirm-A1GCookedFiles $cook.facts;[void](Confirm-A1GStageFiles $stage.facts)
    foreach($d in @($game.facts.targetReceipt,$game.facts.executable,$game.facts.selection,$game.facts.vendorArtifactReceipt)){[void](Check-Descriptor $d)}
    if($stage.facts.originalGameExecutable.path -ine $game.facts.executable.path -or $stage.facts.executable.bytes -ne $game.facts.executable.bytes -or $stage.facts.executable.sha256 -ine $game.facts.executable.sha256 -or $stage.facts.gameTargetReceipt.sha256 -ine $game.facts.targetReceipt.sha256 -or $stage.facts.cookResult.sha256 -ine $cook.result.sha256){throw 'A1G_NATIVE_STAGE_GAME_COOK_JOIN_MISMATCH'}
    $literals=@(foreach($spec in @(@('A1G_BAD',17,'CA15BE3A44E31C173E9697942EA8AE1F1988C902954AB10E74EAFE9F4E98B93C'),@('A1G_GOOD',19,'F522FFF3CCDADCDA1FB8001D2B86727D39E43DB96A2D2D5A7C4CE7A2D0AD095B'))){
        $literalCandidates=@($script:Freeze.fixtureInputs|Where-Object {$_.bytes -eq $spec[1] -and $_.sha256 -ieq $spec[2]})
        if($literalCandidates.Count -ne 1){throw 'A1G_FROZEN_COMPILED_LITERAL_DATA_NOT_UNIQUE'}
        @{id=$spec[0];file=Check-Descriptor $literalCandidates[0]}
    })
    $caller=@($game.facts.nativeFlags.compileResponses|Where-Object {$_.module -ceq 'E04ProfileGameProbe'})
    if($caller.Count -ne 1 -or $caller[0].mode -cne 'Caller' -or $game.facts.nativeFlags.monolithicDefinitionObserved -ne $true){throw 'A1G_ACTUAL_CALLER_BUILD_EVIDENCE_MISSING'}
    [void](Check-Descriptor $caller[0].source)
    @{game=$game;cook=$cook;stage=$stage;literalInputs=$literals;compiledCallerSource=$caller[0].source}
}

function Prepare-A1GNativePhase {
    if($Phase -cne 'Native'){throw 'A1G_NATIVE_PREPARATION_WRONG_PHASE'}
    $prior=Get-A1GNativePriorJoin;$paths=Get-A1GNativePaths
    foreach($p in @($paths.log,$paths.result,$paths.user,$paths.ddc,$paths.shader)){if(Test-Path -LiteralPath $p){throw 'A1G_NATIVE_OUTPUT_REQUIRES_PREABSENCE'}}
    if($paths.ddc.Length -ge 119){throw 'A1G_NATIVE_DDC_PATH_TOO_LONG'}
    # An explicit reviewed supervisor entry is essential. The old Run entry does
    # not silently gain observation semantics, and no external monitor is used.
    if($script:Freeze.ownedWindowObserver.entryPoint -cne 'RunWithOwnedJobWindowObservation' -or $script:Freeze.ownedWindowObserver.sampleIntervalMilliseconds -ne 500){throw 'A1G_REVIEWED_OBSERVER_SELECTION_REQUIRED'}
    foreach($p in @($paths.user,$paths.ddc,$paths.shader,[IO.Path]::GetDirectoryName($paths.result),[IO.Path]::GetDirectoryName($paths.gameUserSettings))){[void][IO.Directory]::CreateDirectory((Under $p $script:RunRoot))}
    @{prior=$prior;paths=$paths;arguments=@(Get-A1GNativeArguments $prior.stage.facts.executable $paths);resultWasAbsent=$true;logWasAbsent=$true;observedUtc=[DateTime]::UtcNow.ToString('o')}
}

# This one narrow launcher differs from Invoke-A1GRoot only where Native needs
# the closed Stage executable instead of an impossible initial-freeze binary,
# and the explicit same-job window observer entry instead of ordinary Run.
function Invoke-A1GObservedNativeRoot($Before) {
    if($Phase -cne 'Native' -or $script:RootCount -ne 0){throw 'A1G_NATIVE_ONE_ROOT_REQUIRED'}
    $exe=Check-Descriptor $Before.prior.stage.facts.executable;[void](Under $exe.path $Before.prior.stage.facts.stageRoot)
    [void](Check-Storage);$out=Owned 'logs/a1g-native.stdout.log';$err=Owned 'logs/a1g-native.stderr.log'
    foreach($p in @($out,$err)){if(Test-Path -LiteralPath $p){throw 'A1G_NATIVE_STREAM_COLLISION'}}
    $saved=@{};foreach($entry in [Environment]::GetEnvironmentVariables('Process').GetEnumerator()){
        if($entry.Key -match '(?i)^(E02_|E04A1_|E04_A1G_|CL$|_CL_$|LINK$|_LINK_$|CMAKE_|CC$|CXX$|CFLAGS$|CXXFLAGS$|LDFLAGS$|NINJA_STATUS$|DOTNET_|_DOTNET_|CORECLR_|COR_|COMPlus_|APP_CONTEXT_|MSBUILD|NUGET_|ASPNETCORE_|UnrealBuildTool_)'){$saved[$entry.Key]=$entry.Value}}
    foreach($key in $saved.Keys){[Environment]::SetEnvironmentVariable($key,$null,'Process')}
    try{
        $envs=Child-Environment;$seconds=[Math]::Min($script:Budgets.Native,(Phase-Budget));if($seconds -lt 3){throw 'A1G_NATIVE_BUDGET_EXHAUSTED'}
        $script:RootCount++
        $record=[Warhammer.E02.Supervisor]::RunWithOwnedJobWindowObservation($exe.path,$Before.arguments,$Before.prior.stage.facts.stageRoot,$envs,$out,$err,$seconds,$false,'',$false)
        $script:Result.processes.Add($record)
        $p=Join-Path $script:PhaseRoot 'a1g-native.process.json';Write-JsonNew $p $record;$record['receiptArtifact']=Descriptor $p
        foreach($p in @($out,$err)){[void](Read-A1GBuildText $p)}
        # Observer/query/membership/visible-row failures must already have entered
        # the producer's ORIGINAL retained-job cleanup. No PID/window kill here.
        Require-RootPass $record
        if($null -ne $record.primaryFailure -or @($record.secondaryErrors).Count -or $record.technicalBlocked -or $record.visibleWindowRequested -or $record.completionCleanupMode -cne 'NaturalDrain'){throw 'A1G_NATIVE_ROOT_OR_OBSERVER_FAILED'}
        [void](Check-Descriptor $exe);return $record
    }finally{foreach($key in $saved.Keys){[Environment]::SetEnvironmentVariable($key,$saved[$key],'Process')}}
}

function Check-A1GOwnedWindowSamples($Process) {
    $o=$Process.ownedJobWindowObservation;$rows=@($o.samples)
    if($o.schemaVersion -ne 1 -or $o.enabled -ne $true -or $o.method -cne 'CURRENT_DESKTOP_TOP_LEVEL_WS_VISIBLE_FILTERED_BY_RETAINED_JOB_PID_SNAPSHOTS' -or $o.intervalMilliseconds -ne 500 -or $o.pidCapacity -ne 256 -or $o.sampleLimit -ne ($Process.budgetSeconds*2+4) -or $o.sampleCount -ne $rows.Count -or $rows.Count -lt 3 -or $rows.Count -gt $o.sampleLimit -or $o.requiredEndpointStagesPresent -ne $true -or $o.status -cne 'PASS_ZERO_OBSERVED' -or $o.failedSampleCount -ne 0 -or $o.visibleWindowObservationCountTotal -ne 0 -or $o.continuousAbsenceEstablished -isnot [bool] -or $o.continuousAbsenceEstablished -ne $false){throw 'A1G_COMPLETE_QUALIFIED_WINDOW_OBSERVATION_REQUIRED'}
    if($rows[0].stage -cne 'assigned-before-resume' -or $rows[1].stage -cne 'startup-after-resume' -or $rows[-1].stage -cne 'final-before-job-cleanup'){throw 'A1G_STARTUP_AND_FINAL_WINDOW_SAMPLES_REQUIRED'}
    # Periodic rows occur only when due within the existing process deadline;
    # a short root may truthfully have only the three endpoint observations.
    if($rows.Count -gt 3 -and @($rows[2..($rows.Count-2)]|Where-Object {$_.stage -cne 'periodic'}).Count){throw 'A1G_WINDOW_INTERMEDIATE_SAMPLE_STAGE_INVALID'}
    $last=-1.0;$maximum=0.0
    foreach($row in $rows){
        if($row.stage -cnotin @('assigned-before-resume','startup-after-resume','periodic','final-before-job-cleanup') -or $row.status -cne 'ZERO_OBSERVED' -or $row.jobPidQueryBeforeSucceeded -ne $true -or $row.jobPidQueryAfterSucceeded -ne $true -or $row.pidSetStable -ne $true -or $null -ne $row.failure -or $row.visibleWindowObservationCount -ne 0 -or @($row.visibleOwnedSnapshotPidCounts).Count){throw 'A1G_FAILED_OR_VISIBLE_OWNED_WINDOW_SAMPLE'}
        Equal-Data @($row.ownedJobPidsBefore|Sort-Object) @($row.ownedJobPidsAfter|Sort-Object) 'sample retained-job PID membership'
        if(@($row.ownedJobPidsBefore).Count -and ($row.enumPerformed -ne $true -or $row.enumSucceeded -ne $true)){throw 'A1G_OWNED_PID_ENUMERATION_NOT_CONFIRMED'}
        if($row.elapsedSecondsAtStart -lt $last -or $row.elapsedSecondsAtEnd -lt $row.elapsedSecondsAtStart -or $row.elapsedSecondsAtEnd -gt $Process.elapsedSeconds){throw 'A1G_WINDOW_SAMPLE_TIME_ORDER_INVALID'}
        if($last -ge 0){$maximum=[Math]::Max($maximum,($row.elapsedSecondsAtStart-$last))};$last=$row.elapsedSecondsAtStart
    }
    if($rows[0].ownedJobPidsBefore -notcontains $Process.pid -or [Math]::Abs($maximum-$o.maximumStartToStartGapSeconds) -gt 0.01){throw 'A1G_ROOT_MEMBERSHIP_OR_ACTUAL_SAMPLE_GAP_MISMATCH'}
    @{process=$Process.receiptArtifact;sampleCount=$rows.Count;periodicSampleCount=@($rows|Where-Object {$_.stage -ceq 'periodic'}).Count;visibleWindowObservationCount=0;maximumStartToStartGapSeconds=$maximum;continuousAbsenceEstablished=$false;scope='Zero observed WS_VISIBLE owned top-level windows at complete recorded current-desktop samples only. Brief intervening/other-desktop/child-only windows and non-atomic PID/HWND races are not disproved.'}
}

function Check-A1GNativeResultDetails($Process,$Prior,$Paths) {
    $base=Read-GameResult $Prior.stage.facts.executable.path $Prior.stage.facts.executable.sha256;$r=Read-Json $base.result.path
    if($r.schemaVersion -ne 1 -or $r.pid -ne $Process.pid -or (Assert-Path $r.resultPath) -ine $Paths.result -or $r.binaryHashScope -cne 'EXPECTED_BINDING_ONLY_ROOT_MUST_REHASH_ACTUAL_BINARY_AND_MATCH_RECEIPT_STAGE' -or $r.specialAssuranceCertification -cne 'DEFERRED_UNPROVEN_OWN17'){throw 'A1G_NATIVE_RESULT_PROCESS_OR_PUBLICATION_JOIN_MISMATCH'}
    foreach($name in @('completeOrderedCheckSet','parserValuesDestroyedBeforePublication')){if($r[$name] -isnot [bool] -or $r[$name] -ne $true){throw 'A1G_NATIVE_LIFETIME_OR_COMPLETE_FLAG_INVALID'}}
    foreach($row in $r.checks){if($row.evaluated -isnot [bool] -or $row.passed -isnot [bool] -or $row.evaluated -ne $true -or $row.passed -ne $true){throw 'A1G_NATIVE_CHECK_NOT_POSITIVE_TYPED_BOOL'}}
    if(@($r.attempts).Count -ne 2){throw 'A1G_NATIVE_EXACT_TWO_ATTEMPTS_REQUIRED'}
    foreach($spec in @(@(0,'A1G_BAD',17,11,'CA15BE3A44E31C173E9697942EA8AE1F1988C902954AB10E74EAFE9F4E98B93C'),@(1,'A1G_GOOD',19,0,'F522FFF3CCDADCDA1FB8001D2B86727D39E43DB96A2D2D5A7C4CE7A2D0AD095B'))){
        $a=$r.attempts[$spec[0]]
        if($a.id -cne $spec[1] -or $a.ordinal -ne ($spec[0]+1) -or $a.inputByteCount -ne $spec[2] -or $a.codeNumber -ne $spec[3] -or $a.diagnosticCodeNumber -ne $spec[3] -or $a.frozenLiteralSha256 -ine $spec[4] -or $a.markUnits -cne 'UNCLAIMED_VENDOR_START_OBSERVATIONS'){throw 'A1G_NATIVE_LITERAL_TYPED_RESULT_OR_ORDER_MISMATCH'}
    }
    $when=[DateTimeOffset]::Parse($r.completedUtc)
    if($when -lt [DateTimeOffset]::Parse($Process.creationUtc) -or $when -gt [DateTimeOffset]::Parse($Process.exitUtc)){throw 'A1G_NATIVE_RESULT_TIME_OUTSIDE_ROOT_LIFETIME'}
    @{result=$base.result;pid=$r.pid;attemptCount=2;evaluatedCheckCount=52;orderedCheckIds=@($r.checks.id);literalInputs=$Prior.literalInputs;compiledCallerSource=$Prior.compiledCallerSource;parserValuesDestroyedBeforePublication=$true;destructionScope='Completed lexical-scope milestone in actual compiled caller, not allocator/destructor instrumentation';nativeAssertionTotal='NOT_INFERRED'}
}

function Check-A1GNativeLog($Process,$Paths,$Arguments) {
    $text=Read-A1GBuildText $Paths.log;$lines=@($text -split "`n"|Where-Object {-not [string]::IsNullOrWhiteSpace($_)})
    if(-not $lines.Count -or $lines[-1] -notmatch '^Log file closed, [^\r\n]+\r?$' -or $text -match '(?im)\b(?:Fatal error:|Critical error:|Unhandled Exception|Assertion failed|Log[^:\r\n]*: Error:)'){throw 'A1G_FULL_NATIVE_LOG_FAILED_OR_UNCLOSED'}
    $command=@([regex]::Matches($text,'(?m)^LogInit: Command Line: (?<value>[^\r\n]+)\r?$'))
    if($command.Count -ne 1){throw 'A1G_NATIVE_COMMAND_LINE_NOT_OBSERVED'}
    Equal-Data @(Split-A1GSimpleCookArguments $command[0].Groups['value'].Value) @($Arguments) 'actual normal Game command line'
    $terminal='E04_A1G_TERMINAL status=PASS run='+$RunId+' attempts=2 checks=52 result='+$Paths.result.Replace('\','/')
    $normal=$text.Replace('\','/');$markers=@([regex]::Matches($normal,[regex]::Escape($terminal)))
    $exit=@([regex]::Matches($text,'FPlatformMisc::RequestExitWithStatus\(0, 0, E04_A1G_PROOF_COMPLETE\)'))
    if($markers.Count -ne 1 -or $exit.Count -ne 1 -or $exit[0].Index -le $markers[0].Index -or $text -notmatch '(?m)^LogExit: Exiting\.\r?$'){throw 'A1G_NATIVE_TERMINAL_OR_ORDERLY_EXIT_NOT_OBSERVED'}
    $rows=@($lines|Where-Object {$_ -match '\bLogDerivedDataCache:'});$writers=[Collections.Generic.List[object]]::new()
    foreach($line in $rows){
        if($line -match '(?i)(falling back|fallback.*(?:enabled|using)|(?:Zen|Cloud|Shared).*\b(?:using|connected|enabled|running)\b|Failed to create graph\b|Attempting to create graph\b)'){throw 'A1G_NATIVE_DDC_FALLBACK_OR_NONOWNED_BACKEND'}
        $m=[regex]::Match($line,'\bLogDerivedDataCache:\s+(?<store>[^:\r\n]+): Using data cache path (?<path>[^\r\n]+): (?<access>Writable|ReadOnly|DeleteOnly)\r?$')
        if($line -match '(?i)\bWritable\b'){
            if(-not $m.Success -or $m.Groups['store'].Value -cne 'E04A1G' -or $m.Groups['access'].Value -cne 'Writable' -or (Assert-Path $m.Groups['path'].Value) -ine $Paths.ddc){throw 'A1G_NATIVE_UNSELECTED_DDC_WRITER'}
            $writers.Add(@{store='E04A1G';path=$Paths.ddc;access='Writable'})
        }
    }
    if(-not $writers.Count){throw 'A1G_NATIVE_ACTUAL_OWNED_WRITABLE_DDC_REQUIRED'}
    @{log=Descriptor $Paths.log;commandLine=$Arguments;terminalMarker=$terminal;orderlyExitCall='RequestExitWithStatus(false,0,E04_A1G_PROOF_COMPLETE)';logClosed=$true;ddc=@{writers=$writers.ToArray();observedRows=$rows;scope='Positive selected filesystem-backend log observations; no universal write-isolation claim.'}}
}

function Complete-A1GNativePhase($Process,$Before) {
    if($Before.resultWasAbsent -ne $true -or $Before.logWasAbsent -ne $true){throw 'A1G_NATIVE_PRELAUNCH_PREABSENCE_REQUIRED'}
    [void](Check-Descriptor $Process.receiptArtifact);Require-RootPass $Process
    if($Process.executable -ine $Before.prior.stage.facts.executable.path -or $Process.workingDirectory -ine $Before.prior.stage.facts.stageRoot -or $null -ne $Process.primaryFailure -or @($Process.secondaryErrors).Count -or $Process.completionCleanupMode -cne 'NaturalDrain'){throw 'A1G_NATIVE_ACTUAL_PROCESS_MISMATCH'}
    Equal-Data @($Process.arguments) @($Before.arguments) 'owned native actual argv'
    $windows=Check-A1GOwnedWindowSamples $Process;$result=Check-A1GNativeResultDetails $Process $Before.prior $Before.paths;$log=Check-A1GNativeLog $Process $Before.paths $Before.arguments
    $current=Get-A1GNativePriorJoin
    Equal-Data $Before.prior.stage.facts.executable $current.stage.facts.executable 'native before-after staged executable'
    @{process=$Process.receiptArtifact;stageResult=$current.stage.result;gameBuildResult=$current.game.result;cookResult=$current.cook.result;executable=$current.stage.facts.executable;gameTargetReceipt=$current.game.facts.targetReceipt;vendorArtifactReceipt=$current.game.facts.vendorArtifactReceipt;arguments=$Before.arguments;paths=$Before.paths;result=$result.result;proof=$result;log=$log.log;ddc=$log.ddc;terminalMarker=$log.terminalMarker;windowObservation=$windows;resultWasAbsentBeforeLaunch=$true;logWasAbsentBeforeLaunch=$true;scope='Finite two compiled-literal Game/cooked Entry/lifetime proof and qualified zero-observed-window samples; no rendering, distribution, continuous visibility, full A1 or OWN17 certification.'}
}

function Complete-A1GAuditPhase {
    if($Phase -cne 'Audit' -or $script:RootCount -ne 0){throw 'A1G_AUDIT_MUST_HAVE_ZERO_ROOTS'}
    $names=@('Preflight','DependencyConfigure','DependencyBuild','EditorPrerequisiteBuild','GameBuild','Cook','Stage','Native');$closed=[ordered]@{};$descriptors=[Collections.Generic.List[object]]::new();$last=$null
    $statuses=@{Preflight='PREFLIGHT_PASS_NO_NATIVE_ROOT';DependencyConfigure='DEPENDENCY_CONFIGURE_PASS_NO_INSTALL';DependencyBuild='DEPENDENCY_BUILD_AND_EXPLICIT_GAME_ARTIFACT_COPY_PASS';EditorPrerequisiteBuild='EDITOR_PREREQUISITE_BUILD_PASS_NORMAL_RECEIPT_AND_PROJECT_MODULE';GameBuild='GAME_BUILD_PASS_ACTUAL_CALLER_PARSER_FLAGS_AND_MONOLITHIC_LINK';Cook='COOK_PASS_NORMAL_COPIED_LOG_AND_LOOSE_PRIMARY_OUTPUTS';Stage='STAGE_PASS_ACTUAL_LOOSE_MANIFESTS_AND_GAME_EXECUTABLE_MAPPING';Native='NATIVE_PASS_COOKED_GAME_FINITE_RESULT_AND_ZERO_OBSERVED_WINDOWS'}
    foreach($name in $names){
        $root=Owned $name.ToLowerInvariant();$completion=Read-Json (Join-Path $root 'completion.json');[void](Check-Descriptor $completion.result);$r=Read-Json $completion.result.path
        if($completion.state -cne 'COMPLETE' -or $completion.executionPassed -ne $true -or $completion.phase -cne $name -or $completion.runId -cne $RunId -or $completion.sourceHead -cne $script:Freeze.sourceHead -or $completion.freezeManifestSha256 -ine $ExpectedFreezeSha256 -or $completion.subset -cne $script:Subset -or $completion.runtimeCallerProof -cne $script:RuntimeCallerProof -or (Assert-Path $completion.result.path) -ine (Join-Path $root 'result.json') -or $r.phase -cne $name -or $r.runId -cne $RunId -or $r.sourceHead -cne $script:Freeze.sourceHead -or $r.executionPassed -ne $true -or $r.status -cne $statuses[$name] -or $null -ne $r.primaryFailure -or @($r.secondaryErrors).Count){throw 'A1G_AUDIT_SAME_RUN_CLOSED_PREFIX_REQUIRED'}
        [void](Check-Descriptor $r.freezeManifest)
        if((Assert-Path $r.freezeManifest.path) -ine (Assert-Path $FreezeManifestPath) -or $r.freezeManifest.sha256 -ine $ExpectedFreezeSha256){throw 'A1G_AUDIT_PRIOR_FREEZE_IDENTITY_MISMATCH'}
        $expected=if($name -ceq 'Preflight'){0}else{1};if(@($r.processes).Count -ne $expected){throw 'A1G_AUDIT_PRIOR_ROOT_COUNT_MISMATCH'}
        foreach($p in $r.processes){Require-RootPass $p;[void](Check-Descriptor $p.receiptArtifact);if($null -ne $p.primaryFailure -or @($p.secondaryErrors).Count -or $p.jobAccounting[-1].querySucceeded -ne $true){throw 'A1G_AUDIT_PRIOR_PROCESS_NOT_CLOSED'}}
        foreach($d in $r.retainedArtifacts){[void](Check-Descriptor $d)}
        Check-Settings $r.settingsBefore $r.settingsAfter;Check-A1GUnownedGameSettings $r.gameSettingsBefore $r.gameSettingsAfter
        foreach($prefix in @('source','stage','fixtures')){Equal-Data @($r[$prefix+'Before']) @($r[$prefix+'After']) ($name+' '+$prefix+' preservation')}
        if($null -ne $last -and [DateTimeOffset]::Parse($r.startedUtc) -le $last){throw 'A1G_AUDIT_PHASE_PREFIX_TIME_ORDER'}
        $last=[DateTimeOffset]::Parse($completion.completedUtc);$closed[$name]=$r;$descriptors.Add(@{phase=$name;completion=Descriptor (Join-Path $root 'completion.json');result=$completion.result})
    }
    $baseline=$closed.Preflight
    foreach($r in $closed.Values){Check-Settings $baseline.settingsAfter $r.settingsBefore;Check-A1GUnownedGameSettings $baseline.gameSettingsAfter $r.gameSettingsBefore}
    Check-A1GUnownedGameSettings $baseline.gameSettingsAfter @(Get-A1GUnownedGameSettings)
    Equal-Data @($baseline.sourceAfter) @(Snapshot-Members $script:Repo $script:Freeze.sourceMembership) 'audit current canonical source'
    Equal-Data @($baseline.stageAfter) @(Snapshot-Members $script:Stage $script:Freeze.stageMembership) 'audit current staged source'
    Equal-Data @($baseline.fixturesAfter) @(Snapshot-Inputs) 'audit current frozen literal inputs'
    $join=Get-A1GNativePriorJoin;$n=$closed.Native.native
    if($n.stageResult.sha256 -ine $join.stage.result.sha256 -or $n.gameBuildResult.sha256 -ine $join.game.result.sha256 -or $n.cookResult.sha256 -ine $join.cook.result.sha256 -or $n.executable.sha256 -ine $join.stage.facts.executable.sha256 -or $n.resultWasAbsentBeforeLaunch -ne $true -or $n.logWasAbsentBeforeLaunch -ne $true){throw 'A1G_AUDIT_NATIVE_PREDECESSOR_OR_BINARY_JOIN'}
    [void](Check-Descriptor $n.result);[void](Check-Descriptor $n.log)
    $process=$closed.Native.processes[0]
    if($process.executable -ine $join.stage.facts.executable.path -or $process.workingDirectory -ine $join.stage.facts.stageRoot -or $process.completionCleanupMode -cne 'NaturalDrain'){throw 'A1G_AUDIT_NATIVE_PROCESS_BINARY_OR_CWD_MISMATCH'}
    Equal-Data @($process.arguments) @($n.arguments) 'audit actual native argv'
    $windows=Check-A1GOwnedWindowSamples $process;$proof=Check-A1GNativeResultDetails $process $join $n.paths;$log=Check-A1GNativeLog $process $n.paths $n.arguments
    @{closedPhaseCount=8;predecessors=$descriptors.ToArray();literalInputCount=$join.literalInputs.Count;attemptCount=$proof.attemptCount;evaluatedCheckCount=$proof.evaluatedCheckCount;nativeAssertionTotal='NOT_INFERRED';executable=$join.stage.facts.executable;result=$proof.result;log=$log.log;windowObservation=$windows;settingsScope='Original9 roles plus separately prebaselined medium-integrity GameUserSettings fallback role';specialAssuranceCertification='DEFERRED_UNPROVEN_OWN17';scope='Closed ordinary source/settings/input/cook/stage/binary/result reconciliation. Final CODE and different REQ remain required; no A1E acceptance transfer.'}
}

# END direct ordinary source integration.
function Assert-ImplementedPhase {
    # Source hooks exist for all nine phases; this is not an execution or gate PASS.
    if($Phase -cnotin $script:Order){throw 'A1G_PHASE_NOT_IMPLEMENTED'}
}
function Output-Inventory {
    $items=[Collections.Generic.List[object]]::new();$reportBytes=0L
    foreach($name in @('logs','reports','artifacts','fixtures')){foreach($p in Plain-Files (Owned $name)){$d=Descriptor $p;if($d.bytes -gt 64MB){throw 'A1G_DATA_STREAM_OR_LOG_CAP_PRESERVE_ORIGINAL'};if($name -ceq 'reports'){$reportBytes+=$d.bytes};$items.Add($d)}}
    if($reportBytes -gt 512MB){throw 'A1G_REPORT_AGGREGATE_CAP'};$items.ToArray()
}

$phaseCreated=$false;$published=$false;$primary=$null;$baseline=$null;$gameBaseline=$null;$sourceBefore=$null;$stageBefore=$null;$inputsBefore=$null
try{
    if(-not $IsWindows -or [Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture -ne [Runtime.InteropServices.Architecture]::X64){throw 'A1G_NATIVE_WINDOWS_X64_REQUIRED_LINUX_UNTESTED'}
    $script:E02UserContext=Execution-UserContext;$authority=Check-Bindings;[void](Windows-Contract);Check-Dependency
    $gameBaseline=@(Get-A1GUnownedGameSettings);Check-A1GUnownedGameSettings $gameBaseline $gameBaseline
    Assert-ImplementedPhase
    if($Phase -ceq 'Preflight'){
        [void](Check-Storage -Initial);if(Test-Path -LiteralPath $script:RunRoot){throw 'A1G_FRESH_RUN_ROOT_REQUIRED'}
        [void][IO.Directory]::CreateDirectory((Assert-Path $script:RunRoot));$script:RunLock=[IO.File]::Open((Owned 'phase-serialization.lock'),[IO.FileMode]::CreateNew,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    }else{$script:RunLock=[IO.File]::Open((Need-File (Owned 'phase-serialization.lock')),[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)}
    New-Directory $script:PhaseRoot;$phaseCreated=$true
    $script:Result=[ordered]@{schemaVersion=1;experiment='E04-A1G';subset=$script:Subset;runtimeCallerProof=$script:RuntimeCallerProof;phase=$Phase;runId=$RunId;sourceHead=$script:Freeze.sourceHead;startedUtc=[DateTime]::UtcNow.ToString('o');status='PROVISIONAL';executionPassed=$false;authority=$authority;freezeManifest=Descriptor $FreezeManifestPath;processes=[Collections.Generic.List[object]]::new();primaryFailure=$null;secondaryErrors=@();previous=@();retainedArtifacts=@();settingsBefore=$null;settingsAfter=$null;gameSettingsBefore=$gameBaseline;gameSettingsAfter=$null;sourceBefore=$null;sourceAfter=$null;stageBefore=$null;stageAfter=$null;fixturesBefore=$null;fixturesAfter=$null;limits=@('Prospective bounded proof; source adoption or tool exit does not establish final acceptance.','Windows Game proof is separate from A1E, A2, Linux, rendering, packaging-distribution and migration acceptance.','64MiB stream/data/log and512MiB report limits are retained-output checks, not live quotas.','OWN17 special assurance remains deferred/unproven; ordinary runtime assertions remain fail-closed.')}
    $script:Result.previous=@(Check-Previous)
    if($Phase -ceq 'Preflight'){Materialize-Stage}
    $sourceBefore=@(Snapshot-Members $script:Repo $script:Freeze.sourceMembership);$stageBefore=@(Snapshot-Members $script:Stage $script:Freeze.stageMembership);$inputsBefore=@(Snapshot-Inputs)
    $baseline=@(Settings);Check-Settings $baseline $baseline
    if($Phase -cne 'Preflight'){$pf=Read-Json (Owned 'preflight/result.json');Check-Settings $pf.settingsAfter $baseline;Check-A1GUnownedGameSettings $pf.gameSettingsAfter $gameBaseline}
    $script:Result.settingsBefore=$baseline;$script:Result.sourceBefore=$sourceBefore;$script:Result.stageBefore=$stageBefore;$script:Result.fixturesBefore=$inputsBefore
    if($Phase -notin @('Preflight','Audit')){if('Warhammer.E02.Supervisor' -as [type]){throw 'A1G_FRESH_POWERSHELL_HOST_REQUIRED'};Add-Type -TypeDefinition ([IO.File]::ReadAllText($script:Freeze.supervisorSource.path)) -Language CSharp}
    switch($Phase){
        'Preflight' {$script:Result.status='PREFLIGHT_PASS_NO_NATIVE_ROOT'}
        'DependencyConfigure' {Configure-Dependency;$script:Result.status='DEPENDENCY_CONFIGURE_PASS_NO_INSTALL'}
        'DependencyBuild' {Build-Dependency;$script:Result.status='DEPENDENCY_BUILD_AND_EXPLICIT_GAME_ARTIFACT_COPY_PASS'}
        'EditorPrerequisiteBuild' {
            $before=Get-A1GUbtPrebuildEvidence
            $process=Invoke-A1GRoot 'a1g-editor-prerequisite' $script:Freeze.toolPaths.dotnet (Ubt-Arguments 'WarhammerClientEditor') (Join-Path $EngineRoot 'Engine/Source')
            $script:Result.editorPrerequisiteBuild=Check-A1GEditorPrerequisiteBuild $process $before
            $script:Result.status='EDITOR_PREREQUISITE_BUILD_PASS_NORMAL_RECEIPT_AND_PROJECT_MODULE'
        }
        'GameBuild' {
            $before=Get-A1GUbtPrebuildEvidence
            $process=Invoke-A1GRoot 'a1g-game-build' $script:Freeze.toolPaths.dotnet (Ubt-Arguments 'WarhammerClientE04A1G') (Join-Path $EngineRoot 'Engine/Source') (Game-BuildEnvironment)
            $script:Result.gameBuild=Check-A1GGameBuild $process $before
            $script:Result.status='GAME_BUILD_PASS_ACTUAL_CALLER_PARSER_FLAGS_AND_MONOLITHIC_LINK'
        }
        'Cook' {
            $before=Prepare-A1GCookStagePhase 'cook'
            $extra=Uat-Environment
            $process=Invoke-A1GRoot 'a1g-cook' $script:Freeze.toolPaths.dotnet (Uat-Arguments -Cook) (Split-Path $script:Freeze.toolPaths.uat -Parent) $extra
            $script:Result.cook=Complete-A1GCookPhase $process $before
            $script:Result.status='COOK_PASS_NORMAL_COPIED_LOG_AND_LOOSE_PRIMARY_OUTPUTS'
        }
        'Stage' {
            $before=Prepare-A1GCookStagePhase 'stage'
            $extra=Uat-Environment
            $process=Invoke-A1GRoot 'a1g-stage' $script:Freeze.toolPaths.dotnet (Uat-Arguments) (Split-Path $script:Freeze.toolPaths.uat -Parent) $extra
            $script:Result.stage=Complete-A1GStagePhase $process $before
            $script:Result.status='STAGE_PASS_ACTUAL_LOOSE_MANIFESTS_AND_GAME_EXECUTABLE_MAPPING'
        }
        'Native' {
            $before=Prepare-A1GNativePhase
            $process=Invoke-A1GObservedNativeRoot $before
            $script:Result.native=Complete-A1GNativePhase $process $before
            $script:Result.status='NATIVE_PASS_COOKED_GAME_FINITE_RESULT_AND_ZERO_OBSERVED_WINDOWS'
        }
        'Audit' {
            $script:Result.audit=Complete-A1GAuditPhase
            $script:Result.status='AUDIT_PASS_SAME_RUN_SOURCE_SETTINGS_STAGE_BINARY_RESULT_RECONCILED'
        }
    }
    $expectedRoots=if($Phase -in @('Preflight','Audit')){0}else{1};if($script:RootCount -ne $expectedRoots){throw 'A1G_EXACT_ROOT_COUNT_MISMATCH'}
    [void](Phase-Budget);$script:Result.executionPassed=$true
}catch{$primary=Failure $_ $Phase;if($null -ne $script:Result){$script:Result.primaryFailure=$primary;$script:Result.executionPassed=$false;$script:Result.status='FAIL_CLOSED_PRESERVE_PARTIALS_NO_RETRY'}}
finally{
    if($phaseCreated -and $null -ne $script:Result){
        try{
            if($null -ne $baseline){$script:Result.settingsAfter=@(Settings);Check-Settings $baseline $script:Result.settingsAfter}
            if($null -ne $gameBaseline){$script:Result.gameSettingsAfter=@(Get-A1GUnownedGameSettings);Check-A1GUnownedGameSettings $gameBaseline $script:Result.gameSettingsAfter}
            if($null -ne $sourceBefore){$script:Result.sourceAfter=@(Snapshot-Members $script:Repo $script:Freeze.sourceMembership);Equal-Data $sourceBefore $script:Result.sourceAfter 'canonical source'}
            if($null -ne $stageBefore){$script:Result.stageAfter=@(Snapshot-Members $script:Stage $script:Freeze.stageMembership);Equal-Data $stageBefore $script:Result.stageAfter 'staged source'}
            if($null -ne $inputsBefore){$script:Result.fixturesAfter=@(Snapshot-Inputs);Equal-Data $inputsBefore $script:Result.fixturesAfter 'frozen fixture inputs'}
            Check-Dependency;$script:Result.storage=Check-Storage;$script:Result.retainedArtifacts=@(Output-Inventory);[void](Phase-Budget)
        }catch{$script:Errors.Add((Failure $_ 'post-phase-preservation'));$script:Result.executionPassed=$false;$script:Result.status='FAIL_PRESERVATION_OR_RETAINED_OUTPUT_CAP'}
        if($Phase -in @('DependencyConfigure','DependencyBuild') -and -not $script:Result.executionPassed){try{$script:Result.generatedBuildInputFailureEvidence=Retain-GeneratedBuildInputPartials}catch{$script:Errors.Add((Failure $_ 'configured-input-partial-retention'))}}
        try{
            $script:Result.secondaryErrors=$script:Errors.ToArray();$script:Result.completedUtc=[DateTime]::UtcNow.ToString('o');$script:Result.elapsedSeconds=$script:Clock.Elapsed.TotalSeconds
            Write-JsonNew (Join-Path $script:PhaseRoot 'result.json') $script:Result
            if($script:Result.executionPassed -and -not $script:Errors.Count){Write-JsonNew (Join-Path $script:PhaseRoot 'completion.json') @{schemaVersion=1;experiment='E04-A1G';subset=$script:Subset;runtimeCallerProof=$script:RuntimeCallerProof;runId=$RunId;phase=$Phase;sourceHead=$script:Freeze.sourceHead;freezeManifestSha256=$ExpectedFreezeSha256;state='COMPLETE';executionPassed=$true;result=Descriptor (Join-Path $script:PhaseRoot 'result.json');completedUtc=[DateTime]::UtcNow.ToString('o')};$published=$true}
        }catch{[Console]::Error.WriteLine('A1G_PUBLICATION_FAILED_PRESERVE_PENDING_AND_PARTIALS')}
    }
    if($null -ne $script:RunLock){$script:RunLock.Dispose()}
}
if($published){exit 0}
[Console]::Error.WriteLine((@{phase=$Phase;runId=$RunId;status='FAIL_OR_UNIMPLEMENTED_OR_UNPUBLISHED';primaryFailure=$primary;secondaryErrors=$script:Errors.ToArray()}|ConvertTo-Json -Depth 12 -Compress));exit 1
