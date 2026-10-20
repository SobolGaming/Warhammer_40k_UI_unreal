using UnrealBuildTool;

public class E04ProfileProbe : ModuleRules
{
    public E04ProfileProbe(ReadOnlyTargetRules Target) : base(Target)
    {
        // Keep this boundary proof's generated definitions local and explicit.
        PCHUsage = PCHUsageMode.NoPCHs;
        CppStandard = CppStandardVersion.Cpp20;
        bUseUnity = false;
        // A1E uses the actual Editor environment: global exceptions are ON.
        // This local false does not override UBT's inherited global true.
        // A1G must separately prove a genuinely exception-disabled runtime caller.
        bEnableExceptions = false;
        // Json is fixture/report bookkeeping only; opaque YAML keys stay byte values.
        PrivateDependencyModuleNames.AddRange(new[] { "Core", "E04ProfileParser", "Json" });
    }
}
