using UnrealBuildTool;

public class E04ProfileParser : ModuleRules
{
    public E04ProfileParser(ReadOnlyTargetRules Target) : base(Target)
    {
        PCHUsage = PCHUsageMode.UseExplicitOrSharedPCHs;
        CppStandard = CppStandardVersion.Cpp20;
        bUseUnity = false;
        bEnableExceptions = true;
        PublicDependencyModuleNames.Add("Core");
        PrivateDependencyModuleNames.Add("YamlCpp");
    }
}
