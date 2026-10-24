// Bounded exact Game caller module; its guards preserve the separate Editor branch.
#nullable enable
using System;
using System.Collections;
using System.IO;
using System.Text.RegularExpressions;
using UnrealBuildTool;

public class E04ProfileGameProbe : ModuleRules
{
    public E04ProfileGameProbe(ReadOnlyTargetRules Target) : base(Target)
    {
        if (!OperatingSystem.IsWindows()
            || Target.Name != "WarhammerClientE04A1G"
            || Target.Type != TargetType.Game
            || Target.Platform != UnrealTargetPlatform.Win64
            || Target.Configuration != UnrealTargetConfiguration.Development
            || Target.Architectures.bIsMultiArch || !Target.Architecture.bIsX64
            || Target.bUseStaticCRT || Target.bDebugBuildsActuallyUseDebugCRT
            || Target.CppStandard != CppStandardVersion.Cpp20)
            throw new BuildException("E04_A1G_CALLER_TARGET_MISMATCH");

        foreach (DictionaryEntry Entry in Environment.GetEnvironmentVariables())
            if (((string)Entry.Key).StartsWith("E02_", StringComparison.OrdinalIgnoreCase))
                throw new BuildException("E04_A1G_E02_ENVIRONMENT_MUST_BE_ABSENT");

        string RunId = Required("E04_A1G_RUN_ID");
        string SourceHead = Required("E04_A1G_SOURCE_HEAD");
        if (!Regex.IsMatch(RunId, "\\A[0-9]{8}T[0-9]{6}Z-[0-9a-f]{8}\\z")
            || !Regex.IsMatch(SourceHead, "\\A[0-9a-f]{40}\\z"))
            throw new BuildException("E04_A1G_RUN_OR_SOURCE_INVALID");

        // Exact module-derived owned ancestry; no environment-selected output.
        DirectoryInfo Module = new DirectoryInfo(ExistingPath(ModuleDirectory));
        DirectoryInfo Source = Parent(Module, "E04ProfileGameProbe");
        DirectoryInfo Plugin = Parent(Source, "Source");
        DirectoryInfo Plugins = Parent(Plugin, "E04ProfileProof");
        DirectoryInfo Project = Parent(Plugins, "Plugins");
        DirectoryInfo Run = Parent(Project, "project");
        DirectoryInfo Experiment = Parent(Run, RunId);
        DirectoryInfo Experiments = Parent(Experiment, "E04A1G");
        DirectoryInfo Local = Parent(Experiments, "experiments");
        DirectoryInfo Repository = Parent(Local, ".local");
        string ProjectFile = ExistingPath(Path.Combine(Project.FullName, "WarhammerClient.uproject"));
        if (Target.ProjectFile == null
            || !Same(ProjectFile, ExistingPath(Target.ProjectFile.FullName))
            || !Same(Run.FullName, ExistingPath(Required("E04_A1G_RUN_ROOT")))
            || !Same(Repository.FullName, ExistingPath(Required("E04_A1G_SOURCE_ROOT"))))
            throw new BuildException("E04_A1G_STAGED_ANCESTRY_MISMATCH");

        PCHUsage = PCHUsageMode.NoPCHs;
        CppStandard = CppStandardVersion.Cpp20;
        bUseUnity = false;
        bEnableExceptions = false;
        PrivateDependencyModuleNames.AddRange(new[]
        {
            "Core", "CoreUObject", "Engine", "Json", "E04ProfileParser"
        });
        PrivateDefinitions.Add("E04_A1G_DEDICATED_CALLER=1");
        // Freeze/review the actual emitted definitions and terminal compile
        // arguments; source settings/string text alone are not a mode proof.
        PrivateDefinitions.Add("E04_A1G_EXPECTED_RUN_ID=\"" + RunId + "\"");
        PrivateDefinitions.Add("E04_A1G_EXPECTED_SOURCE_HEAD=\"" + SourceHead + "\"");
        PrivateDefinitions.Add("E04_A1G_EXPECTED_RUN_ROOT=\"" + Run.FullName.Replace('\\', '/') + "\"");
    }

    private static string Required(string Name)
    {
        string? Value = Environment.GetEnvironmentVariable(Name);
        if (String.IsNullOrWhiteSpace(Value) || Value != Value.Trim())
            throw new BuildException("E04_A1G_REQUIRED_INPUT_INVALID: {0}", Name);
        return Value;
    }

    private static bool Same(string A, string B) =>
        String.Equals(A, B, StringComparison.OrdinalIgnoreCase);

    private static DirectoryInfo Parent(DirectoryInfo Child, string Name)
    {
        if (!Same(Child.Name, Name) || Child.Parent == null)
            throw new BuildException("E04_A1G_MODULE_ANCESTRY_INVALID");
        return Child.Parent;
    }

    private static string ExistingPath(string Value)
    {
        if (!Path.IsPathFullyQualified(Value) || Value.IndexOf('"') >= 0)
            throw new BuildException("E04_A1G_ABSOLUTE_PATH_REQUIRED");
        foreach (char C in Value)
            if (Char.IsControl(C)) throw new BuildException("E04_A1G_CONTROL_IN_PATH");
        string Full = Path.GetFullPath(Value).TrimEnd(Path.DirectorySeparatorChar);
        if (!Regex.IsMatch(Full, "\\A[A-Za-z]:\\\\") || Full.IndexOf(':', 2) >= 0
            || (!File.Exists(Full) && !Directory.Exists(Full)))
            throw new BuildException("E04_A1G_EXISTING_LOCAL_PATH_REQUIRED");
        for (string? P = Full; P != null; P = Path.GetDirectoryName(P))
            if ((File.GetAttributes(P) & FileAttributes.ReparsePoint) != 0)
                throw new BuildException("E04_A1G_REPARSE_PATH_FORBIDDEN");
        return Full;
    }
}
