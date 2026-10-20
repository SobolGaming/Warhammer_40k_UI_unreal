using UnrealBuildTool;

// Dedicated proof target. Ordinary Game/Editor targets leave the plugin disabled.
public class WarhammerClientE04AEditorTarget : TargetRules
{
    public WarhammerClientE04AEditorTarget(TargetInfo Target) : base(Target)
    {
        Type = TargetType.Editor;
        DefaultBuildSettings = BuildSettingsVersion.V7;
        IncludeOrderVersion = EngineIncludeOrderVersion.Unreal5_8;
        CppStandard = CppStandardVersion.Cpp20;
        ExtraModuleNames.Add("WarhammerClient");
        EnablePlugins.Add("E04ProfileProof");
    }
}
