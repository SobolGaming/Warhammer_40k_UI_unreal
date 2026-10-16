using UnrealBuildTool;

public class WarhammerClientEditorTarget : TargetRules
{
    public WarhammerClientEditorTarget(TargetInfo Target) : base(Target)
    {
        Type = TargetType.Editor;
        DefaultBuildSettings = BuildSettingsVersion.V7;
        IncludeOrderVersion = EngineIncludeOrderVersion.Unreal5_8;
        ExtraModuleNames.Add("WarhammerClient");
    }
}
