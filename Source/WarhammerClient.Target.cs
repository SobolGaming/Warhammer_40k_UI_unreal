using UnrealBuildTool;

public class WarhammerClientTarget : TargetRules
{
    public WarhammerClientTarget(TargetInfo Target) : base(Target)
    {
        Type = TargetType.Game;
        DefaultBuildSettings = BuildSettingsVersion.V7;
        IncludeOrderVersion = EngineIncludeOrderVersion.Unreal5_8;
        ExtraModuleNames.Add("WarhammerClient");
    }
}
