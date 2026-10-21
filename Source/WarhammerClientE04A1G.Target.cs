// Prospective bounded Game target; source is not build or execution authority.
using UnrealBuildTool;

public class WarhammerClientE04A1GTarget : TargetRules
{
    public WarhammerClientE04A1GTarget(TargetInfo Target) : base(Target)
    {
        if (WindowsPlatform.ObjSrcMapFile != null)
            throw new BuildException("E04_A1G_OBJ_SRC_MAP_FILE_UNSUPPORTED");

        Type = TargetType.Game;
        if (Name != "WarhammerClientE04A1G"
            || Platform != UnrealTargetPlatform.Win64
            || Configuration != UnrealTargetConfiguration.Development
            || Architectures.bIsMultiArch || !Architecture.bIsX64)
            throw new BuildException("E04_A1G_TARGET_OUTSIDE_DEDICATED_GAME");

        DefaultBuildSettings = BuildSettingsVersion.V7;
        IncludeOrderVersion = EngineIncludeOrderVersion.Unreal5_8;
        CppStandard = CppStandardVersion.Cpp20;
        bBuildAllModules = false;
        ExtraModuleNames.Add("WarhammerClient");
        EnablePlugins.Add("E04ProfileProof");
        // Retain ordinary installed Game/Shared/monolithic defaults. Do not set
        // Unique, bOverrideBuildEnvironment or bForceEnableExceptions.
    }
}
