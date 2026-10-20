#nullable enable
using System;
using System.Collections.Generic;
using System.Linq;
using UnrealBuildTool;

// Dedicated proof target. Ordinary Game/Editor targets leave the plugin disabled.
public class WarhammerClientE04AEditorTarget : TargetRules
{
    public WarhammerClientE04AEditorTarget(TargetInfo Target) : base(Target)
    {
        Type = TargetType.Editor;
        bBuildAllModules = false;
        bCompileWithPluginSupport = true;
        bDebugBuildsActuallyUseDebugCRT = false;
        DefaultBuildSettings = BuildSettingsVersion.V7;
        IncludeOrderVersion = EngineIncludeOrderVersion.Unreal5_8;
        CppStandard = CppStandardVersion.Cpp20;
        ExtraModuleNames.Add("WarhammerClient");
        EnablePlugins.Add("E04ProfileProof");
        if (AdditionalData != null) throw new BuildException("E04_RULES_ADDITIONAL_DATA_ALREADY_SET");
        AdditionalData = new E04RulesObservation(this);
    }
}


// Read-only project-owned bridge. No file, loader, parser or engine-cache call.
public sealed class E04RulesObservation
{
    private readonly TargetRules Actual;
    public string InstanceId { get; } = Guid.NewGuid().ToString("D");
    public int ConstructorProcessId { get; } = Environment.ProcessId;
    public System.Type ConstructorType { get; }
    public bool ConstructorBuildAllModules { get; }
    public System.Type SelectedType => Actual.GetType();

    public E04RulesObservation(TargetRules actual)
    {
        Actual = actual;
        ConstructorType = actual.GetType();
        ConstructorBuildAllModules = actual.bBuildAllModules;
    }

    public Dictionary<string, object?> CaptureSelectors(ReadOnlyTargetRules view)
    {
        if (!Object.ReferenceEquals(view.AdditionalData, this)
            || !Object.ReferenceEquals(Actual.AdditionalData, this)
            || ConstructorProcessId != Environment.ProcessId
            || SelectedType != ConstructorType
            || SelectedType != typeof(WarhammerClientE04AEditorTarget)
            || Actual.Name != view.Name || Actual.Platform != view.Platform
            || Actual.Configuration != view.Configuration
            || Actual.bBuildAllModules != view.bBuildAllModules
            || view.bBuildAllModules
            || view.CppStandard != CppStandardVersion.Cpp20
            || view.DefaultBuildSettings != BuildSettingsVersion.V7
            || view.IncludeOrderVersion != EngineIncludeOrderVersion.Unreal5_8)
            throw new BuildException("E04_RULES_TARGET_WITNESS_OR_FINAL_SELECTOR_MISMATCH");
        return new Dictionary<string, object?>(StringComparer.Ordinal)
        {
            ["name"] = view.Name, ["originalName"] = view.OriginalName,
            ["targetType"] = view.Type.ToString(), ["platform"] = view.Platform.ToString(),
            ["configuration"] = view.Configuration.ToString(),
            ["architectures"] = view.Architectures.ToString(),
            ["isMultiArch"] = view.Architectures.bIsMultiArch, ["architecture"] = view.Architecture.ToString(),
            ["cppStandard"] = nameof(CppStandardVersion.Cpp20),
            ["defaultBuildSettings"] = nameof(BuildSettingsVersion.V7),
            ["includeOrderVersion"] = nameof(EngineIncludeOrderVersion.Unreal5_8),
            ["bBuildAllModules"] = view.bBuildAllModules,
            ["bCompileWithPluginSupport"] = view.bCompileWithPluginSupport,
            ["bCompileAgainstEngine"] = view.bCompileAgainstEngine,
            ["bCompileAgainstCoreUObject"] = view.bCompileAgainstCoreUObject,
            ["bCompileAgainstEditor"] = view.bCompileAgainstEditor,
            ["bBuildDeveloperTools"] = view.bBuildDeveloperTools,
            ["bBuildWithEditorOnlyData"] = view.bBuildWithEditorOnlyData,
            ["bBuildRequiresCookedData"] = view.bBuildRequiresCookedData,
            ["bPrecompile"] = view.bPrecompile,
            ["bIncludePluginsForTargetPlatforms"] = view.bIncludePluginsForTargetPlatforms,
            ["bAllowEnginePluginsEnabledByDefault"] = view.bAllowEnginePluginsEnabledByDefault,
            ["optedInModulePlatforms"] = view.OptedInModulePlatforms == null ? null : view.OptedInModulePlatforms.Select(p => p.ToString()).ToArray(),
            ["linkType"] = view.LinkType.ToString(), ["buildEnvironment"] = view.BuildEnvironment.ToString(),
            ["enablePlugins"] = view.EnablePlugins.ToArray(), ["disablePlugins"] = view.DisablePlugins.ToArray(),
            ["optionalPlugins"] = view.OptionalPlugins.ToArray(), ["additionalPlugins"] = view.AdditionalPlugins.ToArray(),
            ["buildPlugins"] = view.BuildPlugins.ToArray(), ["bUseStaticCRT"] = view.bUseStaticCRT,
            ["bDebugBuildsActuallyUseDebugCRT"] = view.bDebugBuildsActuallyUseDebugCRT
        };
    }
}
