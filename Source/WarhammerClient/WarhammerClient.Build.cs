using UnrealBuildTool;

public class WarhammerClient : ModuleRules
{
    public WarhammerClient(ReadOnlyTargetRules Target) : base(Target)
    {
        PCHUsage = PCHUsageMode.UseExplicitOrSharedPCHs;
        PublicDependencyModuleNames.AddRange(new[] { "Core", "CoreUObject", "Engine" });
        PrivateDependencyModuleNames.AddRange(new[]
        {
            "Json", "InputCore", "Slate", "SlateCore", "ProceduralMeshComponent", "RHI"
        });

        bool bE02AutomationDriver = Target.bBuildDeveloperTools
            && Target.Configuration != UnrealTargetConfiguration.Shipping;
        PrivateDefinitions.Add("WITH_E02_AUTOMATION_DRIVER=" + (bE02AutomationDriver ? "1" : "0"));
        if (bE02AutomationDriver)
        {
            PrivateDependencyModuleNames.AddRange(new[] { "AutomationDriver", "ApplicationCore" });
        }
    }
}
