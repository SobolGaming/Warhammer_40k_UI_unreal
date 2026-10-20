# UNEXECUTED pure/offline controls. Root must read/adopt this source before use.
# Never dot-source the wrapper or invoke UBT/engine/native code/PEReader here.
[CmdletBinding()]
param(
 [Parameter(Mandatory)][switch]$RootAdoptsPureControls,
 [Parameter(Mandatory)][string]$WrapperPath,
 [Parameter(Mandatory)][ValidatePattern('^[A-Fa-f0-9]{64}$')][string]$ExpectedWrapperSha256,
 [Parameter(Mandatory)][string]$NewControlDirectory,
 [string]$RepositoryRoot=(Join-Path $PSScriptRoot '../..')
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if(-not $RootAdoptsPureControls){throw 'EXPLICIT_PURE_CONTROL_SOURCE_ADOPTION_REQUIRED'}
$repository=[IO.Path]::GetFullPath($RepositoryRoot)
if(-not [IO.Path]::IsPathFullyQualified($repository) -or -not [IO.File]::Exists((Join-Path $repository 'WarhammerClient.uproject'))){throw 'EXPLICIT_UNREAL_REPOSITORY_ROOT_REQUIRED'}
$owner=[IO.Path]::GetFullPath((Join-Path $repository '.local'))
$controlRoot=[IO.Path]::GetFullPath($NewControlDirectory)
if(-not [IO.Path]::IsPathFullyQualified($NewControlDirectory) -or
 -not $controlRoot.StartsWith($owner.TrimEnd('\','/')+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -or
 [IO.Directory]::Exists($controlRoot) -or [IO.File]::Exists($controlRoot)){throw 'FRESH_OWNED_CONTROL_DIRECTORY_REQUIRED'}
$cursor=$controlRoot
while($cursor){try{if(([IO.File]::GetAttributes($cursor)-band[IO.FileAttributes]::ReparsePoint)-ne0){throw 'CONTROL_REPARSE_REFUSED'}}catch [IO.FileNotFoundException]{}catch [IO.DirectoryNotFoundException]{};$parent=[IO.Directory]::GetParent($cursor);$cursor=if($parent){$parent.FullName}else{''}}
$wrapper=[IO.Path]::GetFullPath($WrapperPath)
$canonicalWrapper=[IO.Path]::GetFullPath((Join-Path $repository 'scripts/migration/Invoke-E04AProfileProof.ps1'))
$proposalWrapper=[IO.Path]::GetFullPath((Join-Path $repository '.local/planning/E04/rules-witness-wrapper-repair-PROPOSED/Invoke-E04AProfileProof.RulesWitness.PROPOSED.ps1'))
if(($wrapper -ine $canonicalWrapper -and $wrapper -ine $proposalWrapper) -or
 (Get-FileHash -LiteralPath $wrapper -Algorithm SHA256).Hash -ine $ExpectedWrapperSha256){throw 'EXACT_LOCAL_WRAPPER_SOURCE_REQUIRED'}
$tokens=$null;$parseErrors=$null;$tree=[Management.Automation.Language.Parser]::ParseFile($wrapper,[ref]$tokens,[ref]$parseErrors)
if($parseErrors.Count){throw 'WRAPPER_AST_PARSE_FAILED'}
$selected=@('Require-RulesKeys','Assert-RulesValue','Assert-RulesDescriptor','Collect-RulesCacheSources','Check-RulesWitnessData','Check-RulesRetentionData','Safe-Text','Check-JsonElement','Parse-JsonLine','Assert-Path','Under','Owned','Need-File','Digest','Descriptor','Check-Descriptor','Rules-GeneratedPaths','Check-RulesPreservation','Editor-Build')
$functionBindings=@()
foreach($name in $selected){
 $nodes=@($tree.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-ceq$name},$true))
 if($nodes.Count-ne1){throw ('TRUSTED_FUNCTION_NOT_UNIQUE: '+$name)}
 $text=$nodes[0].Extent.Text
 $functionBindings+=@{name=$name;firstLine=$nodes[0].Extent.StartLineNumber;lastLineInclusive=$nodes[0].Extent.EndLineNumber;sha256=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($text)))}
 # Only exact named definitions from the full hash-bound, root-adopted source.
 . ([scriptblock]::Create($text))
}
[void][IO.Directory]::CreateDirectory($controlRoot)
$script:Secrets=[Collections.Generic.List[string]]::new();$script:Utf8=[Text.UTF8Encoding]::new($false,$true)
$script:RunRoot=$controlRoot;$script:Stage=Join-Path $controlRoot 'project';$script:Repo=$repository
$script:Errors=[Collections.Generic.List[object]]::new()
$cases=[Collections.Generic.List[object]]::new()
function Copy-Fixture($Value){ConvertFrom-Json -InputObject (ConvertTo-Json -InputObject $Value -Depth 80 -Compress) -AsHashtable -Depth 80 -DateKind String}
function Fake-Descriptor([string]$Path){@{path=[IO.Path]::GetFullPath($Path);bytes=10;sha256=('A'*64)}}
function New-RulesFixture {
 $root=Join-Path $controlRoot 'synthetic-data-only';$project=Join-Path $root 'project/WarhammerClient.uproject'
 $sources=@('Source/WarhammerClient.Target.cs','Source/WarhammerClientEditor.Target.cs','Source/WarhammerClientE04AEditor.Target.cs','Source/WarhammerClient/WarhammerClient.Build.cs','Plugins/E04ProfileProof/Source/E04ProfileParser/E04ProfileParser.Build.cs','Plugins/E04ProfileProof/Source/E04ProfileProbe/E04ProfileProbe.Build.cs','Plugins/E04ProfileProof/Source/ThirdParty/YamlCpp/YamlCpp.Build.cs')
 $sourceDescriptors=@($sources|ForEach-Object{Fake-Descriptor (Join-Path ([IO.Path]::GetDirectoryName($project)) $_)})
 $selector=@{name='WarhammerClientE04AEditor';originalName='WarhammerClientE04AEditor';targetType='Editor';platform='Win64';configuration='Development';architectures='x64';isMultiArch=$false;architecture='x64';cppStandard='Cpp20';defaultBuildSettings='V7';includeOrderVersion='Unreal5_8';bBuildAllModules=$false;bCompileWithPluginSupport=$true;bCompileAgainstEngine=$true;bCompileAgainstCoreUObject=$true;bCompileAgainstEditor=$true;bBuildDeveloperTools=$true;bBuildWithEditorOnlyData=$true;bBuildRequiresCookedData=$false;bPrecompile=$false;bIncludePluginsForTargetPlatforms=$false;bAllowEnginePluginsEnabledByDefault=$true;optedInModulePlatforms=$null;linkType='Modular';buildEnvironment='Shared';enablePlugins=@('E04ProfileProof','SYNTHETIC_SECOND');disablePlugins=@();optionalPlugins=@();additionalPlugins=@();buildPlugins=@();bUseStaticCRT=$false;bDebugBuildsActuallyUseDebugCRT=$false}
 $challenge=@{schemaVersion=1;kind='E04A1_RULES_WITNESS_INPUT';runId='20990101T000000Z-12345678';sourceHead=('1'*40);sourceRoot=$root;stagedProject=$project;attemptNonce='11111111-1111-1111-1111-111111111111';phase='EditorBuild';freezeManifest=(Fake-Descriptor (Join-Path $root 'freeze.json'));expectedRuntime=@{runtimeFramework='.NET SYNTHETIC';runtimeVersion='0.0.0';processArchitecture='X64'};expectedWorkingDirectory=(Join-Path $root 'engine/Engine/Source');processHost=(Fake-Descriptor (Join-Path $root 'dotnet/dotnet.exe'));ubtAssembly=(Fake-Descriptor (Join-Path $root 'engine/UnrealBuildTool.dll'));buildAssembly=(Fake-Descriptor (Join-Path $root 'engine/UnrealBuildBase.dll'));rulesCacheLockAssembly=(Fake-Descriptor (Join-Path $root 'dotnet/System.Threading.dll'));rulesCompilerSource=(Fake-Descriptor (Join-Path $root 'RulesCompiler.cs'));rulesAssemblySource=(Fake-Descriptor (Join-Path $root 'RulesAssembly.cs'));rulesCacheSource=(Fake-Descriptor (Join-Path $root 'Rules.cs'));dynamicCompilationSource=(Fake-Descriptor (Join-Path $root 'DynamicCompilation.cs'));targetSource=$sourceDescriptors[2];moduleSource=$sourceDescriptors[6];rulesSourceFiles=$sourceDescriptors;parentAssemblies=@((Fake-Descriptor (Join-Path $root 'engine/UE5Rules.dll')),(Fake-Descriptor (Join-Path $root 'engine/UE5ProgramRules.dll')));expectedSelectors=$selector;prelaunchTopologyReceipt=(Fake-Descriptor (Join-Path $root 'topology.json'));finiteDiscoveryRoots=@((Join-Path ([IO.Path]::GetDirectoryName($project)) 'Source'),(Join-Path ([IO.Path]::GetDirectoryName($project)) 'Plugins/E04ProfileProof/Source'))}
 $optional=@('Tests','Mods','Platforms','Restricted','Intermediate/Source','Plugins/E04ProfileProof/Tests','Plugins/E04ProfileProof/Platforms','Plugins/E04ProfileProof/Restricted')|ForEach-Object{Join-Path ([IO.Path]::GetDirectoryName($project)) $_}
 $topology=@{schemaVersion=1;kind='E04A1_RULES_PRELAUNCH_TOPOLOGY';runId=$challenge.runId;sourceHead=$challenge.sourceHead;sourceRoot=$root;stagedProject=$project;attemptNonce=$challenge.attemptNonce;phase='EditorBuild';freezeManifest=$challenge.freezeManifest;freshProjectDirectory=$true;projectBuildRulesAbsent=$true;projectIntermediateSourceAbsent=$true;sourceMembershipLockedBeforeLaunch=$true;rulesSourceFiles=$sourceDescriptors;optionalDiscoveryAbsences=@($optional)}
 $dll=Fake-Descriptor (Join-Path ([IO.Path]::GetDirectoryName($project)) 'Intermediate/Build/BuildRules/WarhammerClientModuleRules.dll')
 $pdb=Fake-Descriptor ([IO.Path]::ChangeExtension($dll.path,'.pdb'));$manifest=Fake-Descriptor (Join-Path ([IO.Path]::GetDirectoryName($dll.path)) 'WarhammerClientModuleRulesManifest.json')
 $mvid='22222222-2222-2222-2222-222222222222';$assemblyName='WarhammerClientModuleRules, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null'
 $parentFacts=@();$rawParents=@();$parentMetadata=@()
 for($i=0;$i-lt2;$i++){$name=if($i-eq0){'UE5Rules'}else{'UE5ProgramRules'};$id=if($i-eq0){'33333333-3333-3333-3333-333333333333'}else{'44444444-4444-4444-4444-444444444444'};$full=$name+', Version=0.0.0.0, Culture=neutral, PublicKeyToken=null';$parentFacts+=@{level=$i;simpleName=$name;fullName=$full;assemblyDescriptor=$challenge.parentAssemblies[$i];loadedMvid=$id};$rawParents+=@{index=$i;hasCompiledAssembly=$true;identity=@{simpleName=$name;fullName=$full;path=$challenge.parentAssemblies[$i].path;mvid=$id}};$parentMetadata+=@{mvid=$id;simpleName=$name}}
 $names=@{targetNameMapSequence=@();moduleNameMapSequence=@()}
 foreach($d in $sourceDescriptors){$tail=if($d.path.EndsWith('.Target.cs')){'.Target.cs'}else{'.Build.cs'};$key=if($tail-ceq'.Target.cs'){'targetNameMapSequence'}else{'moduleNameMapSequence'};$stem=[IO.Path]::GetFileName($d.path);$names[$key]+=@{name=$stem.Substring(0,$stem.Length-$tail.Length);path=$d.path}}
 $cache=@{kind='E04A1_COMPLETED_PROJECT_RULES_CACHE_POSTSTATE';exactProjectPath=$project;expectedProjectAssemblyPath=$dll.path;selectedProjectLazyWasValueCreated=$true;selectedType=('WarhammerClientE04AEditorTarget, '+$assemblyName);selectedTypeSource=$challenge.targetSource.path;selectedModuleType=('YamlCpp, '+$assemblyName);selectedModuleTypeSource=$challenge.moduleSource.path;selectedAssembly=@{simpleName='WarhammerClientModuleRules';fullName=$assemblyName;path=$dll.path;mvid=$mvid};selectedAssemblyObjectEqualsActualTargetAssembly=$true;actualAssemblySourceFilesSequence=@($sourceDescriptors|ForEach-Object{$_.path});actualPreprocessorDefines=@('SYNTHETIC_A','SYNTHETIC_B');targetNameMapSequence=$names.targetNameMapSequence;moduleNameMapSequence=$names.moduleNameMapSequence;parentChain=$rawParents;loadedProjectCacheEntryMetadata=@(@{project=$project;isValueCreated=$true});scope='SAME_PROCESS_COMPLETED_CACHE_AND_LOADED_ASSEMBLY_NOT_SCAN_CHRONOLOGY'}
 $roots=@()
 for($i=0;$i-lt2;$i++){$own=@($sourceDescriptors|Where-Object{$_.path.StartsWith($challenge.finiteDiscoveryRoots[$i]+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)});$roots+=@{path=$challenge.finiteDiscoveryRoots[$i];cacheNodePresent=$true;node=@{isScanned=$true;hasFilesContainer=$true;listsInActualOrder=@{ModuleRules=@($own|Where-Object{$_.path.EndsWith('.Build.cs')}|ForEach-Object{$_.path});TargetRules=@($own|Where-Object{$_.path.EndsWith('.Target.cs')}|ForEach-Object{$_.path});AutomationModules=@();UbtPlugins=@()};hasSubdirectoryContainer=$false;childrenInActualOrder=@()}}}
 $start=[DateTime]::Parse('2099-01-01T00:00:00.0000000Z',[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::RoundtripKind)
 $environment=@{DOTNET_ROLL_FORWARD='LatestPatch';DOTNET_MULTILEVEL_LOOKUP='0';DOTNET_STARTUP_HOOKS='';DOTNET_ADDITIONAL_DEPS='';DOTNET_SHARED_STORE='';DOTNET_EnableDiagnostics='0';CORECLR_ENABLE_PROFILING='0';COR_ENABLE_PROFILING='0';COMPlus_EnableDiagnostics='0'}
 $argv=@($challenge.ubtAssembly.path,'WarhammerClientE04AEditor','Win64','Development')
 $process=@{pid=12345;startTimeUtc=$start.ToString('o');startFileTimeUtc=$start.ToFileTimeUtc();processPath=$challenge.processHost.path;workingDirectory=$challenge.expectedWorkingDirectory;actualArgv=$argv;runtimeFramework=$challenge.expectedRuntime.runtimeFramework;runtimeVersion=$challenge.expectedRuntime.runtimeVersion;processArchitecture='X64';hostDescriptor=$challenge.processHost;ubtAssemblyDescriptor=$challenge.ubtAssembly;buildAssemblyDescriptor=$challenge.buildAssembly;rulesCacheLockAssemblyDescriptor=$challenge.rulesCacheLockAssembly}
 $qualification=@{freshProcessInference='CONDITIONAL_SOURCE_SUPPORTED_FROM_ROOT_OWNED_PROCESS_AND_PREABSENCE';cacheObservation='POSTSTATE_ONLY';manifestOrder='DIRECT_MANIFEST_ARRAY_ORDER';assemblySourceOrder='DIRECT_CURRENT_ENUMERATION_ORDER';roslynOrder='SOURCE_DERIVED_FILEPATH_SORT_NOT_DIRECT_EVENT_TRACE';chronologicalScanEventsObserved=$false;nativeFlagsObserved=$false;pluginActivationObserved=$false}
 $actual=@{dll=$dll;pdb=$pdb;manifest=$manifest;inputContract=(Fake-Descriptor (Join-Path $root 'input.json'));manifestBody=@{SourceFiles=$cache.actualAssemblySourceFilesSequence;EngineVersion='SYNTHETIC_ENGINE'};parentMetadata=$parentMetadata;expectedArgv=$argv;expectedChildEnvironment=$environment}
 $witness=@{schemaVersion=1;kind='E04A1_RULES_RUNTIME_WITNESS';runId=$challenge.runId;sourceHead=$challenge.sourceHead;sourceRoot=$root;stagedProject=$project;attemptNonce=$challenge.attemptNonce;phase='EditorBuild';freezeManifest=$challenge.freezeManifest;inputContract=$actual.inputContract;prelaunchTopologyReceipt=$challenge.prelaunchTopologyReceipt;process=$process;selectedTarget=@{exactClrType='WarhammerClientE04AEditorTarget';assemblyQualifiedName=$cache.selectedType;sourceDescriptor=$challenge.targetSource;assemblyDescriptor=$dll;loadedMvid=$mvid;constructorInstanceId='55555555-5555-5555-5555-555555555555';constructorBuildAllModules=$false};module=@{actualClrType='YamlCpp';sourceDescriptor=$challenge.moduleSource;sameAssemblyReference=$true};effectiveSelectors=$selector;actualProjectRules=$cache;generatedRules=@{dll=$dll;pdb=$pdb;manifest=$manifest;engineVersion='SYNTHETIC_ENGINE';orderedManifestSourceFiles=$cache.actualAssemblySourceFilesSequence;manifestSequenceEqualsAssemblySourceFiles=$true};orderedAssemblySourceFileDescriptors=$sourceDescriptors;parentAssemblyChain=$parentFacts;discoveryCache=@{kind='E04A1_FINITE_RULES_TREE_POSTSTATE';selectedRoots=$roots;nodesCopied=2;fileMembersCopied=7;scope='READ_LOCKED_MATERIALIZED_POSTSTATE_NO_POPULATE_NO_INVALIDATE_NO_CHRONOLOGY'};pinnedEngineSources=@($challenge.rulesCompilerSource,$challenge.rulesAssemblySource,$challenge.rulesCacheSource,$challenge.dynamicCompilationSource);moduleTimeOptionalDiscoveryAbsences=@($optional);observationStage='MODULE_CONSTRUCTOR_AFTER_CREATE_TARGET_RULES_VALIDATION';lineageQualification=$qualification;fileReadLocksHeldThroughUbtExit=$true;scope='CONSTRUCTOR_SELECTION_AND_RULES_CACHE_POSTSTATE_NOT_NATIVE_FLAGS_OR_ACTIVATION_CERTIFICATION'}
 $receipt=@{status='PASS';pid=$process.pid;creationFileTime=$process.startFileTimeUtc;executable=$process.processPath;arguments=$argv;workingDirectory=$process.workingDirectory;exitCode=0;exitConfirmed=$true;cleanupConfirmed=$true;timedOut=$false;assignedBeforeResume=$true;resumed=$true;jobAccounting=@(@{activeProcesses=0});environmentOverrides=$environment}
 $metadata=@{mvid=$mvid;simpleName='WarhammerClientModuleRules';assemblyVersion='0.0.0.0';pdbIdentity=@{guid='66666666-6666-6666-6666-666666666666';stamp=123;age=1};documents=@($sourceDescriptors|ForEach-Object{@{path=$_.path;sourceDescriptor=$_;checksumAlgorithm='SHA256';checksum=('A'*64)}})}
 Copy-Fixture @{Challenge=$challenge;Topology=$topology;Witness=$witness;Root=$receipt;Actual=$actual;Metadata=$metadata;Policy=@{expectedPreprocessorDefines=$cache.actualPreprocessorDefines;expectedManifestEngineVersion='SYNTHETIC_ENGINE'}}
}
function Run-JoinControl([string]$Name,[scriptblock]$Mutate,[bool]$ExpectedPass=$false){
 $fixture=New-RulesFixture;& $Mutate $fixture;$observedPass=$false;$errorText=$null
 try{$null=Check-RulesWitnessData $fixture.Challenge $fixture.Topology $fixture.Witness $fixture.Root $fixture.Actual $fixture.Metadata $fixture.Policy;$observedPass=$true}catch{$errorText=$_.Exception.Message}
 $cases.Add(@{name=$Name;expectedPass=$ExpectedPass;observedPass=$observedPass;matched=($ExpectedPass-eq$observedPass);diagnostic=$errorText})
}
Run-JoinControl 'complete-synthetic-seven-source-join' {} $true
Run-JoinControl 'same-pid-wrong-creation-filetime' {$args[0].Witness.process.startFileTimeUtc++}
Run-JoinControl 'different-ubt-pid' {$args[0].Witness.process.pid++}
Run-JoinControl 'wrong-cwd' {$args[0].Witness.process.workingDirectory+='-foreign'}
Run-JoinControl 'wrong-host-path' {$args[0].Witness.process.processPath+='-foreign'}
Run-JoinControl 'managed-argv-reordered' {$f=$args[0];$f.Witness.process.actualArgv=@($f.Witness.process.actualArgv[1],$f.Witness.process.actualArgv[0])}
Run-JoinControl 'both-root-and-managed-wrong-argv' {$f=$args[0];$f.Root.arguments=@('wrong');$f.Witness.process.actualArgv=@('wrong')}
Run-JoinControl 'cleanup-unverified' {$args[0].Root.cleanupConfirmed=$null}
Run-JoinControl 'timeout' {$args[0].Root.timedOut=$true}
Run-JoinControl 'boolean-string-rejected' {$args[0].Root.exitConfirmed='True'}
Run-JoinControl 'wrong-challenge' {$args[0].Witness.attemptNonce='77777777-7777-7777-7777-777777777777'}
Run-JoinControl 'wrong-run' {$args[0].Witness.runId='20990101T000000Z-87654321'}
Run-JoinControl 'wrong-source-head' {$args[0].Witness.sourceHead=('2'*40)}
Run-JoinControl 'wrong-freeze' {$args[0].Witness.freezeManifest.sha256=('B'*64)}
Run-JoinControl 'case-different-required-key' {$f=$args[0];$f.Witness['Kind']=$f.Witness.kind;$f.Witness.Remove('kind')}
Run-JoinControl 'wrong-runtime-vs-sdk' {$args[0].Witness.process.runtimeVersion='SDK-IS-NOT-CLR'}
Run-JoinControl 'startup-hook-channel' {$args[0].Root.environmentOverrides.DOTNET_STARTUP_HOOKS='foreign.dll'}
Run-JoinControl 'constructor-false-finalized-true' {$args[0].Witness.effectiveSelectors.bBuildAllModules=$true}
Run-JoinControl 'unsupported-specialized-type' {$args[0].Witness.selectedTarget.exactClrType='WarhammerClientE04AEditorTarget_Win64'}
Run-JoinControl 'selector-null-not-empty' {$args[0].Witness.effectiveSelectors.optedInModulePlatforms=@()}
Run-JoinControl 'selector-key-absent' {$args[0].Witness.effectiveSelectors.Remove('bCompileAgainstEngine')}
Run-JoinControl 'plugin-selector-array-order' {$f=$args[0];$f.Witness.effectiveSelectors.enablePlugins=@($f.Witness.effectiveSelectors.enablePlugins[1],$f.Witness.effectiveSelectors.enablePlugins[0])}
Run-JoinControl 'wrong-target-source' {$args[0].Witness.selectedTarget.sourceDescriptor.path+='-wrong'}
Run-JoinControl 'wrong-loaded-mvid' {$args[0].Witness.selectedTarget.loadedMvid='88888888-8888-8888-8888-888888888888'}
Run-JoinControl 'missing-pdb-debug-pair' {$args[0].Metadata.pdbIdentity=$null}
Run-JoinControl 'manifest-order-diverges' {$f=$args[0];$f.Actual.manifestBody.SourceFiles=@($f.Actual.manifestBody.SourceFiles[1],$f.Actual.manifestBody.SourceFiles[0])+@($f.Actual.manifestBody.SourceFiles[2..6])}
Run-JoinControl 'extra-source' {$args[0].Witness.orderedAssemblySourceFileDescriptors+=@{path='C:/foreign.cs';bytes=1;sha256=('B'*64)}}
Run-JoinControl 'source-byte-identity-drift' {$args[0].Witness.orderedAssemblySourceFileDescriptors[0].sha256=('B'*64)}
Run-JoinControl 'pdb-source-association-drift' {$args[0].Metadata.documents[0].sourceDescriptor.sha256=('B'*64)}
Run-JoinControl 'target-name-map-wrong-case' {$args[0].Witness.actualProjectRules.targetNameMapSequence[0].name='warhammerclient'}
Run-JoinControl 'uncreated-project-lazy' {$args[0].Witness.actualProjectRules.selectedProjectLazyWasValueCreated=$false}
Run-JoinControl 'extra-project-cache-entry' {$args[0].Witness.actualProjectRules.loadedProjectCacheEntryMetadata+=@{project='C:/other.uproject';isValueCreated=$false}}
Run-JoinControl 'parent-order-swap' {$f=$args[0];$f.Witness.parentAssemblyChain=@($f.Witness.parentAssemblyChain[1],$f.Witness.parentAssemblyChain[0])}
Run-JoinControl 'parent-mvid-drift' {$args[0].Actual.parentMetadata[0].mvid='88888888-8888-8888-8888-888888888888'}
Run-JoinControl 'raw-parent-mismatch' {$args[0].Witness.actualProjectRules.parentChain[0].identity.mvid='88888888-8888-8888-8888-888888888888'}
Run-JoinControl 'cache-root-absent' {$args[0].Witness.discoveryCache.selectedRoots[0].cacheNodePresent=$false}
Run-JoinControl 'cache-root-unscanned' {$args[0].Witness.discoveryCache.selectedRoots[0].node.isScanned=$false}
Run-JoinControl 'cache-source-extra' {$args[0].Witness.discoveryCache.selectedRoots[0].node.listsInActualOrder.ModuleRules+= 'C:/foreign.Build.cs'}
Run-JoinControl 'optional-absence-order-or-value-drift' {$args[0].Witness.moduleTimeOptionalDiscoveryAbsences[0]+='-different'}
Run-JoinControl 'chronological-cache-claim-forbidden' {$args[0].Witness.lineageQualification.chronologicalScanEventsObserved=$true}
foreach($sample in @(@{name='nested-case-key-collision';text='{"outer":{"pid":1,"PID":2}}'},@{name='nested-duplicate-key';text='{"outer":{"pid":1,"pid":2}}'},@{name='malformed-json';text='{"outer":'})){
 $refused=$false;try{$null=Parse-JsonLine $sample.text}catch{$refused=$true};$cases.Add(@{name=$sample.name;expectedPass=$false;observedPass=(-not$refused);matched=$refused})
}
# Actual retained/live hashing under owned synthetic files; no real PE is loaded.
$roles=@('dll','pdb','manifest','witness','input','topology','before','after');$items=@()
$generated=Rules-GeneratedPaths
$originals=[ordered]@{dll=$generated.dll;pdb=$generated.pdb;manifest=$generated.manifest;witness=(Owned 'logs/rules-runtime-witness.json');input=(Owned 'logs/rules-witness-input.json');topology=(Owned 'logs/rules-prelaunch-topology.json');before=(Owned 'logs/rules-source-before.json');after=(Owned 'logs/rules-source-after.json')}
foreach($role in $roles){$original=$originals[$role];$copy=Owned ('artifacts/rules/'+[IO.Path]::GetFileName($original));foreach($p in @($original,$copy)){[void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($p));[IO.File]::WriteAllText($p,'SYNTHETIC_'+$role)};$items+=@{role=$role;original=(Descriptor $original);retainedCopy=(Descriptor $copy)}}
$validation=Join-Path $controlRoot 'synthetic-validation.json';[IO.File]::WriteAllText($validation,'SYNTHETIC')
$editor=@{rulesWitness=@{status='VALIDATED_FINITE_OWNED_PROCESS_RULES_POSTSTATE'};rulesRetention=@{kind='E04A1_RULES_RAW_ARTIFACT_RETENTION';status='COMPLETE';missing=@();failures=@();items=$items};rulesValidation=(Descriptor $validation)}
function Plain-Files([string]$Root){[IO.Directory]::EnumerateFiles($Root,'*',[IO.SearchOption]::AllDirectories)}
$ok=$false;try{$null=Check-RulesPreservation $editor;$ok=$true}catch{};$cases.Add(@{name='actual-synthetic-live-retained-positive';expectedPass=$true;observedPass=$ok;matched=$ok})
foreach($sample in @('copy-mismatch','missing-role','partial-retention','wrong-original-path','wrong-retained-path')){$bad=Copy-Fixture $editor;switch($sample){'copy-mismatch'{$bad.rulesRetention.items[0].retainedCopy.sha256=('B'*64)};'missing-role'{$bad.rulesRetention.items=@($bad.rulesRetention.items[1..7])};'partial-retention'{$bad.rulesRetention.status='PARTIAL_PRESERVED'};'wrong-original-path'{$bad.rulesRetention.items[0].original.path+='-foreign'};'wrong-retained-path'{$bad.rulesRetention.items[0].retainedCopy.path+='-foreign'}};$refused=$false;try{Check-RulesRetentionData $bad.rulesRetention}catch{$refused=$true};$cases.Add(@{name=$sample;expectedPass=$false;observedPass=(-not$refused);matched=$refused})}
[IO.File]::AppendAllText($generated.dll,'DRIFT');$refused=$false;try{$null=Check-RulesPreservation $editor}catch{$refused=$true};$cases.Add(@{name='later-live-dll-byte-drift';expectedPass=$false;observedPass=(-not$refused);matched=$refused})
# Run the real Editor-Build failure/finally path with process/setup/retention stubs.
# No direct child/native call is possible through this explicitly replaced seam.
$script:Freeze=@{windows=@{platform='Win64'};sourceHead=('1'*40);toolPaths=@{dotnet='C:/SYNTHETIC/dotnet.exe'}}
$script:Stage=Join-Path $controlRoot 'clean-failure-stage'
$script:Result=@{primaryFailure=$null};$script:Errors=[Collections.Generic.List[object]]::new();$script:RulesSourceLocks=$null;$script:RulesTopologyBefore=$null
function Prepare-RulesChallenge {$script:TestLock=[IO.MemoryStream]::new();$script:RulesSourceLocks=@($script:TestLock);@{stagedProject='C:/SYNTHETIC/project.uproject';attemptNonce='11111111-1111-1111-1111-111111111111';ubtAssembly=@{path='C:/SYNTHETIC/UBT.dll'};expectedWorkingDirectory='C:/SYNTHETIC/Engine/Source'}}
function Descriptor([string]$Path){Fake-Descriptor $Path}
function Invoke-Root {throw 'SYNTHETIC_PRIMARY_BUILD_FAILURE'}
function Retain-RulesArtifacts {throw 'SYNTHETIC_SECONDARY_RETENTION_FAILURE'}
function Failure($Record,[string]$Stage){@{stage=$Stage;message=$Record.Exception.Message}}
$RunId='20990101T000000Z-12345678';$caught=$null
try{$null=Editor-Build}catch{$caught=$_.Exception.Message}
$kept=($caught-ceq'SYNTHETIC_PRIMARY_BUILD_FAILURE'-and$script:Errors.Count-eq1-and$script:Errors[0].message-ceq'SYNTHETIC_SECONDARY_RETENTION_FAILURE'-and-not$script:TestLock.CanRead)
$cases.Add(@{name='primary-failure-preserved-secondary-retention-and-lock-close';expectedPass=$true;observedPass=$kept;matched=$kept;primary=$caught;secondary=@($script:Errors)})
$failures=@($cases|Where-Object{-not$_.matched})
$report=@{schemaVersion=1;kind='PURE_SYNTHETIC_RULES_VALIDATOR_CONTROLS_NOT_NATIVE_PROOF';wrapper=@{path=$wrapper;sha256=$ExpectedWrapperSha256};functionBindings=$functionBindings;caseCount=$cases.Count;matchedCount=$cases.Count-$failures.Count;failedCount=$failures.Count;cases=@($cases);nativeOrImplementationProcessInvoked=$false;peReaderInvoked=$false;limits=@('Synthetic validator/owned-file rejection controls, not a real UBT witness or compiled PE/PDB/native proof.','Metadata-reader APIs and actual CLR/cache/toolchain/selector observations remain unexecuted.','No full wrapper initialization, phase entry, Add-Type, process launch, credentials, network, engine or sibling mutation.')}
$bytes=[Text.UTF8Encoding]::new($false).GetBytes((ConvertTo-Json -InputObject $report -Depth 40)+"`n")
$out=Join-Path $controlRoot 'pure-control-report.json';$stream=[IO.File]::Open($out,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);try{$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
if($failures.Count){throw ('PURE_CONTROL_FAILURES: '+$failures.Count)}
@{report=$out;caseCount=$cases.Count;matchedCount=$cases.Count}
