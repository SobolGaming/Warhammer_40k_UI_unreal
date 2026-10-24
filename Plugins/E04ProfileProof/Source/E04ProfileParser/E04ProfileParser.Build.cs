using UnrealBuildTool;

public class E04ProfileParser : ModuleRules
{
    public E04ProfileParser(ReadOnlyTargetRules Target) : base(Target)
    {
        // Keep this boundary proof's generated definitions local and explicit.
        PCHUsage = PCHUsageMode.NoPCHs;
        CppStandard = CppStandardVersion.Cpp20;
        bUseUnity = false;
        bEnableExceptions = true;
        PublicDependencyModuleNames.Add("Core");
        PrivateDependencyModuleNames.Add("YamlCpp");
    }
}
