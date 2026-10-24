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
$heldStreamProposalWrapper=[IO.Path]::GetFullPath((Join-Path $repository '.local/planning/E04/rules-source-held-stream-repair-PROPOSED/Invoke-E04AProfileProof.HeldSources.PROPOSED.ps1'))
$targetMapManifestProposalWrapper=[IO.Path]::GetFullPath((Join-Path $repository '.local/planning/E04/rules-target-map-manifest-repair-v3-PROPOSED/Invoke-E04AProfileProof.TargetMapManifest.v3.PROPOSED.ps1'))
if(($wrapper -ine $canonicalWrapper -and $wrapper -ine $proposalWrapper -and $wrapper -ine $heldStreamProposalWrapper -and $wrapper -ine $targetMapManifestProposalWrapper) -or
 (Get-FileHash -LiteralPath $wrapper -Algorithm SHA256).Hash -ine $ExpectedWrapperSha256){throw 'EXACT_LOCAL_WRAPPER_SOURCE_REQUIRED'}
$tokens=$null;$parseErrors=$null;$tree=[Management.Automation.Language.Parser]::ParseFile($wrapper,[ref]$tokens,[ref]$parseErrors)
if($parseErrors.Count){throw 'WRAPPER_AST_PARSE_FAILED'}
$selected=@('Require-RulesKeys','Assert-RulesValue','Assert-RulesDescriptor','Collect-RulesCacheSources','Check-RulesWitnessData','Check-RulesRetentionData','Safe-Text','Check-JsonElement','Parse-JsonLine','Assert-Path','Under','Owned','Need-File','Digest','Descriptor','Check-Descriptor','Rules-GeneratedPaths','Check-RulesPreservation','Editor-Build','Read-RulesHeldDescriptor','Confirm-RulesHeldSources','Rules-SourceFiles','Confirm-RulesPrelaunchInputs','Rules-Topology','Prepare-RulesChallenge','Read-Json','Write-JsonNew','Plain-Files','Snapshot-Source','Failure')
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
 $environment=@{DOTNET_ROLL_FORWARD='LatestPatch';DOTNET_MULTILEVEL_LOOKUP='0';DOTNET_STARTUP_HOOKS='';DOTNET_ADDITIONAL_DEPS='';DOTNET_SHARED_STORE='';DOTNET_EnableDiagnostics='0';CORECLR_ENABLE_PROFILING='0';COR_ENABLE_PROFILING='0';COMPlus_EnableDiagnostics='0';UBT_EXTRA_ARGS=''}
 $argv=@($challenge.ubtAssembly.path,'WarhammerClientE04AEditor','Win64','Development')
 $process=@{pid=12345;startTimeUtc=$start.ToString('o');startFileTimeUtc=$start.ToFileTimeUtc();processPath=$challenge.processHost.path;workingDirectory=$challenge.expectedWorkingDirectory;actualArgv=$argv;runtimeFramework=$challenge.expectedRuntime.runtimeFramework;runtimeVersion=$challenge.expectedRuntime.runtimeVersion;processArchitecture='X64';hostDescriptor=$challenge.processHost;ubtAssemblyDescriptor=$challenge.ubtAssembly;buildAssemblyDescriptor=$challenge.buildAssembly;rulesCacheLockAssemblyDescriptor=$challenge.rulesCacheLockAssembly}
 $qualification=@{freshProcessInference='CONDITIONAL_SOURCE_SUPPORTED_FROM_ROOT_OWNED_PROCESS_AND_PREABSENCE';cacheObservation='POSTSTATE_ONLY';manifestOrder='DIRECT_MANIFEST_ARRAY_ORDER';assemblySourceOrder='DIRECT_CURRENT_ENUMERATION_ORDER';roslynOrder='SOURCE_DERIVED_FILEPATH_SORT_NOT_DIRECT_EVENT_TRACE';chronologicalScanEventsObserved=$false;nativeFlagsObserved=$false;pluginActivationObserved=$false}
 $actual=@{dll=$dll;pdb=$pdb;manifest=$manifest;inputContract=(Fake-Descriptor (Join-Path $root 'input.json'));manifestBody=@{SourceFiles=$cache.actualAssemblySourceFilesSequence;EngineVersion='SYNTHETIC_ENGINE'};parentMetadata=$parentMetadata;expectedArgv=$argv;expectedChildEnvironment=$environment}
 $witness=@{schemaVersion=1;kind='E04A1_RULES_RUNTIME_WITNESS';runId=$challenge.runId;sourceHead=$challenge.sourceHead;sourceRoot=$root;stagedProject=$project;attemptNonce=$challenge.attemptNonce;phase='EditorBuild';freezeManifest=$challenge.freezeManifest;inputContract=$actual.inputContract;prelaunchTopologyReceipt=$challenge.prelaunchTopologyReceipt;process=$process;selectedTarget=@{exactClrType='WarhammerClientE04AEditorTarget';assemblyQualifiedName=$cache.selectedType;sourceDescriptor=$challenge.targetSource;assemblyDescriptor=$dll;loadedMvid=$mvid;constructorInstanceId='55555555-5555-5555-5555-555555555555';constructorBuildAllModules=$false};module=@{actualClrType='YamlCpp';sourceDescriptor=$challenge.moduleSource;sameAssemblyReference=$true};effectiveSelectors=$selector;actualProjectRules=$cache;generatedRules=@{dll=$dll;pdb=$pdb;manifest=$manifest;engineVersion='SYNTHETIC_ENGINE';orderedManifestSourceFiles=$cache.actualAssemblySourceFilesSequence;manifestSequenceEqualsAssemblySourceFiles=$true};orderedAssemblySourceFileDescriptors=$sourceDescriptors;parentAssemblyChain=$parentFacts;discoveryCache=@{kind='E04A1_FINITE_RULES_TREE_POSTSTATE';selectedRoots=$roots;nodesCopied=2;fileMembersCopied=7;scope='READ_LOCKED_MATERIALIZED_POSTSTATE_NO_POPULATE_NO_INVALIDATE_NO_CHRONOLOGY'};pinnedEngineSources=@($challenge.rulesCompilerSource,$challenge.rulesAssemblySource,$challenge.rulesCacheSource,$challenge.dynamicCompilationSource);moduleTimeOptionalDiscoveryAbsences=@($optional);observationStage='MODULE_CONSTRUCTOR_AFTER_CREATE_TARGET_RULES_VALIDATION';lineageQualification=$qualification;fileReadLocksHeldThroughUbtExit=$true;scope='CONSTRUCTOR_SELECTION_AND_RULES_CACHE_POSTSTATE_NOT_NATIVE_FLAGS_OR_ACTIVATION_CERTIFICATION'}
 $receipt=@{status='PASS';pid=$process.pid;creationFileTime=$process.startFileTimeUtc;executable=$process.processPath;arguments=$argv;workingDirectory=$process.workingDirectory;exitCode=0;exitConfirmed=$true;cleanupConfirmed=$true;timedOut=$false;assignedBeforeResume=$true;resumed=$true;jobAccounting=@(@{activeProcesses=0});environmentOverrides=$environment}
 $metadata=@{mvid=$mvid;simpleName='WarhammerClientModuleRules';assemblyVersion='0.0.0.0';pdbIdentity=@{guid='66666666-6666-6666-6666-666666666666';stamp=123;age=1};documents=@($sourceDescriptors|ForEach-Object{@{path=$_.path;sourceDescriptor=$_;checksumAlgorithm='SHA256';checksum=('A'*64)}})}
 Copy-Fixture @{Challenge=$challenge;Topology=$topology;Witness=$witness;Root=$receipt;Actual=$actual;Metadata=$metadata;Policy=@{expectedPreprocessorDefines=$cache.actualPreprocessorDefines;expectedManifestEngineVersion='SYNTHETIC_ENGINE'}}
}
function Run-JoinControl([string]$Name,[scriptblock]$Mutate,[bool]$ExpectedPass=$false,[string]$ExpectedDiagnostic=''){
 $fixture=New-RulesFixture;& $Mutate $fixture;$observedPass=$false;$errorText=$null
 try{$null=Check-RulesWitnessData $fixture.Challenge $fixture.Topology $fixture.Witness $fixture.Root $fixture.Actual $fixture.Metadata $fixture.Policy;$observedPass=$true}catch{$errorText=$_.Exception.Message}
 $cases.Add(@{name=$Name;expectedPass=$ExpectedPass;observedPass=$observedPass;matched=($ExpectedPass-eq$observedPass-and($ExpectedDiagnostic-ceq''-or$errorText-ceq$ExpectedDiagnostic));diagnostic=$errorText;expectedDiagnostic=$ExpectedDiagnostic})
}
Run-JoinControl 'complete-synthetic-seven-source-join' {} $true
# Reproduce both old combined-dictionary category escapes with the same truncated
# stem that the old validator accepted. Other complete fixture joins stay intact.
Run-JoinControl 'target-map-rejects-approved-module-source' {
 $f=$args[0];$path=$f.Challenge.moduleSource.path;$name=[IO.Path]::GetFileName($path);$name=$name.Substring(0,$name.Length-'.Target.cs'.Length)
 $f.Witness.actualProjectRules.targetNameMapSequence[0]=@{name=$name;path=$path}
} $false 'E04A1_RULES_NAME_MAP_CATEGORY_OR_SOURCE'
Run-JoinControl 'module-map-rejects-approved-target-source' {
 $f=$args[0];$path=$f.Witness.actualProjectRules.targetNameMapSequence[0].path;$name=[IO.Path]::GetFileName($path);$name=$name.Substring(0,$name.Length-'.Build.cs'.Length)
 $f.Witness.actualProjectRules.moduleNameMapSequence[0]=@{name=$name;path=$path}
} $false 'E04A1_RULES_NAME_MAP_CATEGORY_OR_SOURCE'
Run-JoinControl 'absent-raw-manifest-data' {$args[0].Actual.Remove('manifestBody')} $false 'E04A1_RULES_MANIFEST_DATA_REQUIRED'
Run-JoinControl 'absent-generated-manifest-descriptor' {$args[0].Witness.generatedRules.manifest=$null} $false 'E04A1_RULES_OBJECT_REQUIRED'
# Valid map order is preserved as observed; it need not equal source-union order.
$orderFixture=New-RulesFixture
foreach($key in @('targetNameMapSequence','moduleNameMapSequence')){$rows=@($orderFixture.Witness.actualProjectRules[$key]);[Array]::Reverse($rows);$orderFixture.Witness.actualProjectRules[$key]=$rows}
$beforeMapOrder=Copy-Fixture @{target=$orderFixture.Witness.actualProjectRules.targetNameMapSequence;module=$orderFixture.Witness.actualProjectRules.moduleNameMapSequence}
$mapOrderOk=$false;$mapOrderDiagnostic=$null
try{$null=Check-RulesWitnessData $orderFixture.Challenge $orderFixture.Topology $orderFixture.Witness $orderFixture.Root $orderFixture.Actual $orderFixture.Metadata $orderFixture.Policy;Assert-RulesValue $beforeMapOrder.target $orderFixture.Witness.actualProjectRules.targetNameMapSequence 'targetObservedOrderUnchanged';Assert-RulesValue $beforeMapOrder.module $orderFixture.Witness.actualProjectRules.moduleNameMapSequence 'moduleObservedOrderUnchanged';$mapOrderOk=$true}catch{$mapOrderDiagnostic=$_.Exception.Message}
$cases.Add(@{name='valid-category-maps-retain-observed-order';expectedPass=$true;observedPass=$mapOrderOk;matched=$mapOrderOk;diagnostic=$mapOrderDiagnostic})
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
Run-JoinControl 'ubt-extra-args-root-nonempty' {$args[0].Root.environmentOverrides.UBT_EXTRA_ARGS='-NoMutex'} $false 'E04A1_RULES_UBT_EXTRA_ARGS_MUST_BE_EMPTY'
Run-JoinControl 'ubt-extra-args-root-missing' {$args[0].Root.environmentOverrides.Remove('UBT_EXTRA_ARGS')} $false 'E04A1_RULES_UBT_EXTRA_ARGS_MUST_BE_EMPTY'
Run-JoinControl 'ubt-extra-args-root-null' {$args[0].Root.environmentOverrides.UBT_EXTRA_ARGS=$null} $false 'E04A1_RULES_UBT_EXTRA_ARGS_MUST_BE_EMPTY'
Run-JoinControl 'ubt-extra-args-root-wrong-type' {$args[0].Root.environmentOverrides.UBT_EXTRA_ARGS=$false} $false 'E04A1_RULES_UBT_EXTRA_ARGS_MUST_BE_EMPTY'
Run-JoinControl 'ubt-extra-args-expected-nonempty' {$args[0].Actual.expectedChildEnvironment.UBT_EXTRA_ARGS='-NoMutex'} $false 'E04A1_RULES_UBT_EXTRA_ARGS_MUST_BE_EMPTY'
Run-JoinControl 'ubt-extra-args-expected-missing' {$args[0].Actual.expectedChildEnvironment.Remove('UBT_EXTRA_ARGS')} $false 'E04A1_RULES_UBT_EXTRA_ARGS_MUST_BE_EMPTY'
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
# Real source acquisition/preparation/Editor-Build control flow over owned text
# fixtures. Only the installed-runtime prerequisite and native-launch/retention
# seams are replaced; Rules-SourceFiles/Topology/Prepare are never replaced here.
$script:RealRulesNeedFile=${function:Need-File}
function Need-File([string]$Path){
 if($null -ne $script:PreparationHook -and [IO.Path]::GetFullPath($Path) -ieq $script:PreparationHookPath){$hook=$script:PreparationHook;$script:PreparationHook=$null;& $hook}
 & $script:RealRulesNeedFile $Path
}
function Phase-Budget {1800}
function Check-RulesFreeze {$script:SyntheticRuntimePrerequisiteCalls++}
function Invoke-Root {
 $script:SyntheticLaunchCounter++
 $script:LocksAtLaunch=@($script:RulesSourceLocks)
 $script:AllLocksReadableAtLaunch=($script:LocksAtLaunch.Count-eq66-and@($script:LocksAtLaunch|Where-Object{-not$_.CanRead}).Count-eq0)
 throw 'SYNTHETIC_LAUNCH_BOUNDARY_REACHED_NO_PROCESS'
}
function Retain-RulesArtifacts {
 $script:LocksAtRetention=@($script:RulesSourceLocks)
 if($script:InjectSyntheticRetentionFailure){throw 'SYNTHETIC_SECONDARY_RETENTION_FAILURE'}
 @{status='SYNTHETIC_NO_NATIVE_ARTIFACTS';items=@();missing=@();failures=@()}
}
function New-PrelaunchFixture([string]$Name){
 $root=Join-Path $controlRoot ('prelaunch-'+$Name)
 $script:Repo=Join-Path $root 'canonical';$script:RunRoot=Join-Path $root 'run';$script:Stage=Join-Path $script:RunRoot 'project'
 $script:EngineRoot=Join-Path $root 'engine';$script:FreezeManifestPath=Join-Path $script:RunRoot 'freeze.json'
 foreach($directory in @($script:Repo,$script:Stage,(Join-Path $script:RunRoot 'logs'),(Join-Path $script:EngineRoot 'Engine/Source'))){[void][IO.Directory]::CreateDirectory($directory)}
 $paths=@('WarhammerClient.uproject','Config/DefaultEditorSettings.ini','Config/DefaultEngine.ini','Config/DefaultGame.ini','Plugins/E04ProfileProof/E04ProfileProof.uplugin','Source/WarhammerClient.Target.cs','Source/WarhammerClientEditor.Target.cs','Source/WarhammerClientE04AEditor.Target.cs','Source/WarhammerClient/WarhammerClient.Build.cs','Plugins/E04ProfileProof/Source/E04ProfileParser/E04ProfileParser.Build.cs','Plugins/E04ProfileProof/Source/E04ProfileProbe/E04ProfileProbe.Build.cs','Plugins/E04ProfileProof/Source/ThirdParty/YamlCpp/YamlCpp.Build.cs')
 for($i=0;$i -lt 21;$i++){$paths+=('Source/WarhammerClient/Private/Synthetic'+$i.ToString('D2')+'.h')}
 foreach($relative in $paths){foreach($base in @($script:Repo,$script:Stage)){$p=Join-Path $base $relative;[void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($p));$text=if($relative.EndsWith('.uproject')-or$relative.EndsWith('.uplugin')){'{}'}else{'SYNTHETIC_APPROVED_A'};[IO.File]::WriteAllText($p,$text,$script:Utf8)}}
 $script:PreparationHook=$null;$script:PreparationHookPath='';$script:SyntheticLaunchCounter=0;$script:SyntheticRuntimePrerequisiteCalls=0;$script:LocksAtLaunch=@();$script:LocksAtRetention=@();$script:AllLocksReadableAtLaunch=$false;$script:InjectSyntheticRetentionFailure=$false
 $script:RulesSourceLocks=$null;$script:RulesSourceBindings=$null;$script:RulesTopologyBefore=$null;$script:Errors=[Collections.Generic.List[object]]::new();$script:Result=@{primaryFailure=$null}
 $membership=@(Snapshot-Source $script:Repo)
 $hostPath=Join-Path $root 'dotnet-NOT-EXECUTABLE.txt';[IO.File]::WriteAllText($hostPath,'SYNTHETIC_HOST_NEVER_EXECUTED',$script:Utf8);$hostDescriptor=Descriptor $hostPath
 $r=@{expectedRuntime=@{runtimeFramework='SYNTHETIC';runtimeVersion='SYNTHETIC';processArchitecture='X64'};parentAssemblies=@($hostDescriptor);expectedSelectors=@{name='SYNTHETIC'};optionalDiscoveryAbsenceRelativePaths=@('Tests','Mods','Platforms','Restricted','Intermediate/Source','Plugins/E04ProfileProof/Tests','Plugins/E04ProfileProof/Platforms','Plugins/E04ProfileProof/Restricted')}
 foreach($key in @('ubtAssembly','buildAssembly','rulesCacheLockAssembly','rulesCompilerSource','rulesAssemblySource','rulesCacheSource','dynamicCompilationSource')){$r[$key]=$hostDescriptor}
 $script:Freeze=@{sourceHead=('1'*40);sourceMembership=$membership;files=@(foreach($relative in $paths){Descriptor (Join-Path $script:Repo $relative)});toolPaths=@{dotnet=$hostPath};rulesWitness=$r;windows=@{platform='Win64'}}
 [IO.File]::WriteAllText($script:FreezeManifestPath,'SYNTHETIC_FREEZE_NOT_NATIVE_AUTHORITY',$script:Utf8)
 [IO.File]::WriteAllText((Owned 'logs/yaml-artifact-receipt.json'),'SYNTHETIC_NO_LIBRARY',$script:Utf8)
 $script:RunId='20990101T000000Z-12345678'
 return @{root=$root;canonical=$script:Repo;stage=$script:Stage;first=(Join-Path $script:Repo 'Config/DefaultEditorSettings.ini');last=(Join-Path $script:Stage 'WarhammerClient.uproject');target='Source/WarhammerClientE04AEditor.Target.cs'}
}
function Set-PrelaunchMutation([string]$Path,[scriptblock]$Action){$script:PreparationHookPath=[IO.Path]::GetFullPath($Path);$script:PreparationHook=$Action}
function Run-PrelaunchControl([string]$Name,[scriptblock]$Setup,[int]$ExpectedLaunches,[string]$DiagnosticPrefix,[bool]$RequireNoChallenge=$false){
 $fixture=New-PrelaunchFixture $Name;& $Setup $fixture;$caught=$null
 try{$null=Editor-Build}catch{$caught=$_.Exception.Message}
 $closed=($null -eq $script:RulesSourceLocks -and $null -eq $script:RulesSourceBindings -and @($script:LocksAtRetention|Where-Object {$_.CanRead}).Count -eq 0)
 $launchLocks=($ExpectedLaunches -eq 0 -or ($script:AllLocksReadableAtLaunch -and $script:LocksAtLaunch.Count -eq 66 -and @($script:LocksAtLaunch|Where-Object {$_.CanRead}).Count -eq 0))
 $unpublished=(-not $RequireNoChallenge -or -not [IO.File]::Exists((Owned 'logs/rules-witness-input.json')))
 $matched=($script:SyntheticLaunchCounter -eq $ExpectedLaunches -and $null -ne $caught -and $caught.StartsWith($DiagnosticPrefix,[StringComparison]::Ordinal) -and $closed -and $launchLocks -and $unpublished -and $script:SyntheticRuntimePrerequisiteCalls -eq 1)
 $cases.Add(@{name=$Name;expectedPass=($ExpectedLaunches-eq1);observedPass=($script:SyntheticLaunchCounter-eq1);expectedLaunches=$ExpectedLaunches;observedLaunches=$script:SyntheticLaunchCounter;diagnostic=$caught;expectedDiagnosticPrefix=$DiagnosticPrefix;allAcquiredHandlesClosed=$closed;retainedHandleCount=$script:LocksAtRetention.Count;launchHandleCount=$script:LocksAtLaunch.Count;challengePublicationRequirementMet=$unpublished;matched=$matched;fixtureKind='REAL_PREPARATION_AND_EDITOR_BUILD_WITH_NO_PROCESS_SEAM'})
}
Run-PrelaunchControl 'held-all33-positive-reaches-launch-seam' {} 1 'SYNTHETIC_LAUNCH_BOUNDARY_REACHED_NO_PROCESS'
Run-PrelaunchControl 'same-length-frozen-A-locks-B' {
 $f=$args[0];$script:MutationFixture=$f
 Set-PrelaunchMutation $f.first {foreach($root in @($script:MutationFixture.canonical,$script:MutationFixture.stage)){[IO.File]::WriteAllText((Join-Path $root $script:MutationFixture.target),'SYNTHETIC_APPROVED_B',$script:Utf8)}}
} 0 'E04A1_RULES_DESCRIPTOR_MISMATCH' $true
Run-PrelaunchControl 'canonical-only-byte-mismatch' {[IO.File]::WriteAllText((Join-Path $args[0].canonical $args[0].target),'SYNTHETIC_APPROVED_B',$script:Utf8)} 0 'E04A1_RULES_DESCRIPTOR_MISMATCH' $true
Run-PrelaunchControl 'staged-only-byte-mismatch' {[IO.File]::WriteAllText((Join-Path $args[0].stage $args[0].target),'SYNTHETIC_APPROVED_B',$script:Utf8)} 0 'E04A1_RULES_DESCRIPTOR_MISMATCH' $true
Run-PrelaunchControl 'missing-last-stage-file-partial-lock-cleanup' {[IO.File]::Delete($args[0].last)} 0 '' $true
$lastCase=$cases[$cases.Count-1];$lastCase.matched=($lastCase.matched -and $lastCase.retainedHandleCount -eq 65)
Run-PrelaunchControl 'full33-flat-freeze-descriptor-conflict' {$script:Freeze.files[0].sha256=('B'*64)} 0 'E04A1_RULES_DESCRIPTOR_MISMATCH' $true
Run-PrelaunchControl 'unexpected-CSharp-before-challenge' {
 $f=$args[0];$script:MutationFixture=$f
 Set-PrelaunchMutation $f.last {[IO.File]::WriteAllText((Join-Path $script:MutationFixture.stage 'Source/Unexpected.Target.cs'),'SYNTHETIC_EXTRA',$script:Utf8)}
} 0 'E04A1_RULES_ARRAY_MISMATCH: prelaunchAuthoredMembership:' $true
foreach($sample in @(@{name='late-extra-CSharp';relative='Source/Late.Target.cs';diagnostic='E04A1_RULES_ARRAY_MISMATCH: prelaunchAuthoredMembership:'},@{name='late-pruning-marker';relative='Source/.ubtignore';diagnostic='E04A1_RULES_PRUNING_MARKER_UNSUPPORTED'},@{name='late-project-pruning-input';relative='Source/Late.csproj';diagnostic='E04A1_RULES_PRUNING_MARKER_UNSUPPORTED'},@{name='late-config-boundary-file';relative='Config/Unexpected.ini';diagnostic='E04A1_RULES_ARRAY_MISMATCH: prelaunchAuthoredMembership:'},@{name='late-plugin-boundary-file';relative='Plugins/Unexpected.uplugin';diagnostic='E04A1_RULES_ARRAY_MISMATCH: prelaunchAuthoredMembership:'})){
 $script:LateRelative=$sample.relative
 Run-PrelaunchControl $sample.name {
  $script:LateStage=$args[0].stage
  Set-PrelaunchMutation (Owned 'logs/yaml-artifact-receipt.json') {[IO.File]::WriteAllText((Join-Path $script:LateStage $script:LateRelative),'SYNTHETIC_EXTRA',$script:Utf8)}
 } 0 $sample.diagnostic
}
Run-PrelaunchControl 'late-empty-discovery-directory' {
 $script:LateStage=$args[0].stage
 Set-PrelaunchMutation (Owned 'logs/yaml-artifact-receipt.json') {[void][IO.Directory]::CreateDirectory((Join-Path $script:LateStage 'Source/UnexpectedEmpty'))}
} 0 'E04A1_RULES_ARRAY_MISMATCH: prelaunchApprovedDiscoveryTopology.entries'
Run-PrelaunchControl 'late-excluded-discovery-root' {
 $script:LateStage=$args[0].stage
 Set-PrelaunchMutation (Owned 'logs/yaml-artifact-receipt.json') {[void][IO.Directory]::CreateDirectory((Join-Path $script:LateStage 'Mods'))}
} 0 'E04A1_RULES_EXCLUDED_DISCOVERY_ROOT_PRESENT: Mods'
Run-PrelaunchControl 'staged-project-boundary-drift' {[IO.File]::WriteAllText((Join-Path $args[0].stage 'WarhammerClient.uproject'),'{"AdditionalRootDirectories":["foreign"]}',$script:Utf8)} 0 'E04A1_RULES_DESCRIPTOR_MISMATCH' $true
Run-PrelaunchControl 'staged-plugin-boundary-drift' {[IO.File]::WriteAllText((Join-Path $args[0].stage 'Plugins/E04ProfileProof/E04ProfileProof.uplugin'),'{"EnabledByDefault":true}',$script:Utf8)} 0 'E04A1_RULES_DESCRIPTOR_MISMATCH' $true
Run-PrelaunchControl 'canonical-config-boundary-drift' {[IO.File]::WriteAllText((Join-Path $args[0].canonical 'Config/DefaultEngine.ini'),'SYNTHETIC_APPROVED_B',$script:Utf8)} 0 'E04A1_RULES_DESCRIPTOR_MISMATCH' $true
Run-PrelaunchControl 'both-copies-boundary-handles-deny-late-write' {
 $script:MutationFixture=$args[0];$script:BoundaryWritesDenied=0
 Set-PrelaunchMutation (Owned 'logs/yaml-artifact-receipt.json') {
  foreach($p in @((Join-Path $script:MutationFixture.stage 'WarhammerClient.uproject'),(Join-Path $script:MutationFixture.canonical 'Config/DefaultEngine.ini'),(Join-Path $script:MutationFixture.stage 'Plugins/E04ProfileProof/E04ProfileProof.uplugin'))){try{[IO.File]::WriteAllText($p,'FOREIGN_BOUNDARY',$script:Utf8)}catch [IO.IOException]{$script:BoundaryWritesDenied++}}
 }
} 1 'SYNTHETIC_LAUNCH_BOUNDARY_REACHED_NO_PROCESS'
$lastCase=$cases[$cases.Count-1];$lastCase.matched=($lastCase.matched -and $script:BoundaryWritesDenied -eq 3)
Run-PrelaunchControl 'prelaunch-primary-preserved-with-retention-failure' {
 [IO.File]::WriteAllText((Join-Path $args[0].stage $args[0].target),'SYNTHETIC_APPROVED_B',$script:Utf8);$script:InjectSyntheticRetentionFailure=$true
} 0 'E04A1_RULES_DESCRIPTOR_MISMATCH' $true
$lastCase=$cases[$cases.Count-1];$lastCase.matched=($lastCase.matched -and @($script:Errors|Where-Object {$_.stage -ceq 'rules-failure-retention' -and $_.message -ceq 'SYNTHETIC_SECONDARY_RETENTION_FAILURE'}).Count -eq 1)
# Direct real held-stream hashing checks full content and restores caller offset.
$offsetFile=Join-Path $controlRoot 'held-offset.bin';[IO.File]::WriteAllText($offsetFile,'SYNTHETIC_OFFSET_HASH',$script:Utf8);$offsetExpected=Descriptor $offsetFile
$offsetStream=[IO.File]::Open($offsetFile,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
$offsetOk=$false;$offsetError=$null
try{$offsetStream.Position=3;$offsetActual=Read-RulesHeldDescriptor $offsetFile $offsetStream;Assert-RulesDescriptor $offsetExpected $offsetActual;$offsetOk=($offsetStream.Position-eq3)}catch{$offsetError=$_.Exception.Message}finally{$offsetStream.Dispose()}
$cases.Add(@{name='held-stream-full-content-and-offset-reset';expectedPass=$true;observedPass=$offsetOk;matched=$offsetOk;diagnostic=$offsetError})
$disposedRefused=$false;try{$null=Read-RulesHeldDescriptor $offsetFile $offsetStream}catch{$disposedRefused=$_.Exception.Message-ceq'E04A1_RULES_HELD_SOURCE_STREAM_REQUIRED'}
$cases.Add(@{name='disposed-held-stream-refused';expectedPass=$false;observedPass=(-not$disposedRefused);matched=$disposedRefused})
# Restore real path helper and original owned-root scope before legacy controls.
Set-Item -LiteralPath Function:Need-File -Value $script:RealRulesNeedFile
$script:Repo=$repository;$script:RunRoot=$controlRoot;$script:Stage=Join-Path $controlRoot 'project';$script:RulesSourceLocks=$null;$script:RulesSourceBindings=$null;$script:RulesTopologyBefore=$null
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
# Explicit manifest-role omission: the DLL and six other roles remain present.
$missingManifestRole=Copy-Fixture $editor
$missingManifestRole.rulesRetention.items=@($missingManifestRole.rulesRetention.items|Where-Object {$_.role -cne 'manifest'})
$manifestRoleTargeted=($editor.rulesRetention.items.Count-eq8-and$missingManifestRole.rulesRetention.items.Count-eq7-and@($missingManifestRole.rulesRetention.items|Where-Object {$_.role-ceq'dll'}).Count-eq1-and@($missingManifestRole.rulesRetention.items|Where-Object {$_.role-ceq'manifest'}).Count-eq0)
$manifestRoleRefused=$false;$manifestRoleDiagnostic=$null
try{Check-RulesRetentionData $missingManifestRole.rulesRetention}catch{$manifestRoleDiagnostic=$_.Exception.Message;$manifestRoleRefused=$manifestRoleDiagnostic-ceq'E04A1_RULES_RETENTION_REQUIRED_ROLE_SET'}
$cases.Add(@{name='missing-retained-manifest-role';expectedPass=$false;observedPass=(-not$manifestRoleRefused);matched=($manifestRoleTargeted-and$manifestRoleRefused);diagnostic=$manifestRoleDiagnostic;manifestOmittedDllPreserved=$manifestRoleTargeted})
# Exercise actual preservation reads after deleting only an owned manifest path.
# The known-good complete set must pass before deletion and after exact restore.
foreach($roleToDelete in @('original','retainedCopy')){
 $manifestEntries=@($editor.rulesRetention.items|Where-Object {$_.role -ceq 'manifest'});if($manifestEntries.Count-ne1){throw 'PURE_MANIFEST_FIXTURE_NOT_UNIQUE'}
 $manifestEntry=$manifestEntries[0];$deleteDescriptor=$manifestEntry[$roleToDelete];$otherKey=if($roleToDelete-ceq'original'){'retainedCopy'}else{'original'}
 $deletePath=Under $deleteDescriptor.path $script:RunRoot;$restorePath=Under $manifestEntry[$otherKey].path $script:RunRoot
 $beforeDeletionPassed=$false;$targetedDeletion=$false;$missingManifestRefused=$false;$restoredAndPassed=$false;$missingManifestDiagnostic=$null
 try{
  $null=Check-RulesPreservation $editor;$beforeDeletionPassed=$true
  [IO.File]::Delete($deletePath);$targetedDeletion=(-not[IO.File]::Exists($deletePath)-and[IO.File]::Exists($restorePath))
  try{$null=Check-RulesPreservation $editor}catch{$missingManifestDiagnostic=$_.Exception.Message;$missingManifestRefused=($missingManifestDiagnostic.IndexOf($deletePath,[StringComparison]::OrdinalIgnoreCase)-ge0)}
 }finally{
  if(-not[IO.File]::Exists($deletePath)){[IO.File]::Copy($restorePath,$deletePath,$false)}
  [void](Check-Descriptor $deleteDescriptor);$null=Check-RulesPreservation $editor;$restoredAndPassed=$true
 }
 $caseName=if($roleToDelete-ceq'original'){'missing-live-manifest-preservation'}else{'missing-retained-manifest-copy-preservation'}
 $cases.Add(@{name=$caseName;expectedPass=$false;observedPass=(-not$missingManifestRefused);matched=($beforeDeletionPassed-and$targetedDeletion-and$missingManifestRefused-and$restoredAndPassed);diagnostic=$missingManifestDiagnostic;knownGoodBeforeDeletion=$beforeDeletionPassed;onlyOwnedManifestPathDeleted=$targetedDeletion;exactRestorationAndCompletePreservationPassed=$restoredAndPassed})
}
[IO.File]::AppendAllText($generated.dll,'DRIFT');$refused=$false;try{$null=Check-RulesPreservation $editor}catch{$refused=$true};$cases.Add(@{name='later-live-dll-byte-drift';expectedPass=$false;observedPass=(-not$refused);matched=$refused})
# Run the real Editor-Build failure/finally path with process/setup/retention stubs.
# No direct child/native call is possible through this explicitly replaced seam.
$script:Freeze=@{windows=@{platform='Win64'};sourceHead=('1'*40);toolPaths=@{dotnet='C:/SYNTHETIC/dotnet.exe'}}
$script:Stage=Join-Path $controlRoot 'clean-failure-stage'
$script:Result=@{primaryFailure=$null};$script:Errors=[Collections.Generic.List[object]]::new();$script:RulesSourceLocks=$null;$script:RulesSourceBindings=$null;$script:RulesTopologyBefore=$null
function Prepare-RulesChallenge {$script:TestLock=[IO.MemoryStream]::new();$script:RulesSourceLocks=@($script:TestLock);@{rulesSourceFiles=@();stagedProject='C:/SYNTHETIC/project.uproject';attemptNonce='11111111-1111-1111-1111-111111111111';ubtAssembly=@{path='C:/SYNTHETIC/UBT.dll'};expectedWorkingDirectory='C:/SYNTHETIC/Engine/Source'}}
function Descriptor([string]$Path){Fake-Descriptor $Path}
# This legacy failure-isolation control follows the real prelaunch controls above.
function Confirm-RulesPrelaunchInputs {}
function Rules-Topology {}
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
