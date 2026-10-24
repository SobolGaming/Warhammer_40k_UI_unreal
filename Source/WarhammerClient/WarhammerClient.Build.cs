#nullable enable

using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text.Json;
using System.Text.RegularExpressions;
using UnrealBuildTool;

public class WarhammerClient : ModuleRules
{
    // These handles deliberately live until this UBT process exits. FileShare.Read
    // permits execution/read access while denying changes to the checked EXE bytes.
    private static readonly object E02SelectionSync = new object();
    private static readonly List<FileStream> E02ExecutableReadLocks = new List<FileStream>();

    public WarhammerClient(ReadOnlyTargetRules Target) : base(Target)
    {
        GuardE02NativeToolchain(Target);

        PCHUsage = PCHUsageMode.UseExplicitOrSharedPCHs;
        PublicDependencyModuleNames.AddRange(new[] { "Core", "CoreUObject", "Engine" });
        PrivateDependencyModuleNames.AddRange(new[]
        {
            "Json", "HTTP", "InputCore", "Slate", "SlateCore", "ProceduralMeshComponent", "RHI"
        });

        bool bE02AutomationDriver = Target.Type == TargetType.Editor
            && Target.bBuildDeveloperTools
            && Target.Configuration != UnrealTargetConfiguration.Shipping;
        PrivateDefinitions.Add("WITH_E02_AUTOMATION_DRIVER=" + (bE02AutomationDriver ? "1" : "0"));
        if (bE02AutomationDriver)
        {
            PrivateDependencyModuleNames.AddRange(new[] { "AutomationDriver", "ApplicationCore" });
        }
    }

    private void GuardE02NativeToolchain(ReadOnlyTargetRules Target)
    {
        string[] InputNames =
        {
            "E02_BUILD_RUN_ID", "E02_SOURCE_HEAD", "E02_SOURCE_ROOT", "E02_STAGED_PROJECT", "E02_TOOLCHAIN_RECEIPT",
            "E02_COMPILER_PATH", "E02_COMPILER_BYTES", "E02_COMPILER_SHA256",
            "E02_RESOURCE_COMPILER_PATH", "E02_RESOURCE_COMPILER_BYTES", "E02_RESOURCE_COMPILER_SHA256"
        };
        string? Required = Environment.GetEnvironmentVariable("E02_NATIVE_TOOLCHAIN_REQUIRED");
        string ActualModuleDirectory = Path.GetFullPath(ModuleDirectory);
        bool IsE02Stage = ActualModuleDirectory.IndexOf(
            Path.DirectorySeparatorChar + Path.Combine(".local", "experiments", "E02") + Path.DirectorySeparatorChar,
            StringComparison.OrdinalIgnoreCase) >= 0;
        if (Required == null && !IsE02Stage
            && !InputNames.Any(Name => Environment.GetEnvironmentVariable(Name) != null))
        {
            return;
        }
        if (Required != "1")
        {
            throw new BuildException("E02_NATIVE_TOOLCHAIN_REQUIRED_MISSING_OR_INVALID");
        }

        lock (E02SelectionSync)
        {
            string RunId = E02Required("E02_BUILD_RUN_ID");
            string SourceHead = E02Required("E02_SOURCE_HEAD");
            if (!Regex.IsMatch(RunId, "\\A[0-9]{8}T[0-9]{6}Z-[0-9a-f]{8}\\z")
                || !Regex.IsMatch(SourceHead, "\\A[0-9a-f]{40}\\z"))
            {
                throw new BuildException("E02_NATIVE_TOOLCHAIN_IDENTITY_INVALID");
            }
            if (!OperatingSystem.IsWindows() || RuntimeInformation.ProcessArchitecture != Architecture.X64
                || Target.Platform != UnrealTargetPlatform.Win64 || !Target.Architecture.bIsX64
                || Target.Architectures.bIsMultiArch || Target.Type != TargetType.Editor
                || Target.Name != "WarhammerClientEditor" || Target.Configuration != UnrealTargetConfiguration.Development)
            {
                throw new BuildException("E02_NATIVE_TOOLCHAIN_TARGET_OUTSIDE_OWNED_PROOF");
            }

            // Bind caller inputs to the actual module ancestry, not an arbitrary
            // environment-provided output path. The wrapper owns execution authority.
            DirectoryInfo Module = new DirectoryInfo(E02Path(ActualModuleDirectory, true));
            DirectoryInfo Source = E02Parent(Module, "WarhammerClient");
            DirectoryInfo Project = E02Parent(Source, "Source");
            DirectoryInfo Run = E02Parent(Project, "project");
            DirectoryInfo E02 = E02Parent(Run, RunId);
            DirectoryInfo Experiments = E02Parent(E02, "E02");
            DirectoryInfo Local = E02Parent(Experiments, "experiments");
            DirectoryInfo Repository = E02Parent(Local, ".local");
            string SourceRoot = E02Path(Repository.FullName, true);
            string ProjectPath = E02Path(Path.Combine(Project.FullName, "WarhammerClient.uproject"), true);
            string ReceiptPath = E02Path(Path.Combine(Run.FullName, "logs", "build-toolchain-selection.json"), false);
            if (!E02SamePath(E02Path(E02Required("E02_SOURCE_ROOT"), true), SourceRoot)
                || !E02SamePath(E02Path(E02Required("E02_STAGED_PROJECT"), true), ProjectPath)
                || !E02SamePath(E02Path(E02Required("E02_TOOLCHAIN_RECEIPT"), false), ReceiptPath)
                || Target.ProjectFile == null || !E02SamePath(E02Path(Target.ProjectFile.FullName, true), ProjectPath)
                || !Directory.Exists(Path.GetDirectoryName(ReceiptPath)))
            {
                throw new BuildException("E02_NATIVE_TOOLCHAIN_STAGE_OR_RECEIPT_MISMATCH");
            }

            ReadOnlyWindowsTargetRules Windows = Target.WindowsPlatform;
            string CompilerVersion = Windows.CompilerVersion ?? throw new BuildException("E02_COMPILER_VERSION_UNRESOLVED");
            string ToolchainVersion = Windows.ToolChainVersion ?? throw new BuildException("E02_TOOLCHAIN_VERSION_UNRESOLVED");
            string SdkVersion = Windows.WindowsSdkVersion ?? throw new BuildException("E02_SDK_VERSION_UNRESOLVED");
            if (Windows.Compiler != WindowsCompiler.VisualStudio2022 || Windows.ToolChain != WindowsCompiler.VisualStudio2022
                || CompilerVersion != "14.44.35229" || ToolchainVersion != "14.44.35229"
                || SdkVersion != "10.0.22621.0" || !Windows.Architecture.bIsX64)
            {
                throw new BuildException("E02_NATIVE_TOOLCHAIN_SELECTED_VERSION_MISMATCH");
            }
            string CompilerDirectory = E02Path(Windows.CompilerDir ?? throw new BuildException("E02_COMPILER_DIRECTORY_UNRESOLVED"), true);
            string ToolchainDirectory = E02Path(Windows.ToolChainDir ?? throw new BuildException("E02_TOOLCHAIN_DIRECTORY_UNRESOLVED"), true);
            string SdkDirectory = E02Path(Windows.WindowsSdkDir ?? throw new BuildException("E02_SDK_DIRECTORY_UNRESOLVED"), true);
            if (!E02SamePath(CompilerDirectory, ToolchainDirectory))
            {
                throw new BuildException("E02_NATIVE_TOOLCHAIN_SELECTED_DIRECTORY_MISMATCH");
            }

            // Exact UE 5.8 Windows VCEnvironment paths for the required x64 host
            // and target. No PATH search or version-to-directory inference occurs.
            string CompilerPath = E02Path(Path.Combine(CompilerDirectory, "bin", "Hostx64", "x64", "cl.exe"), true);
            string ResourceCompilerPath = E02Path(Path.Combine(SdkDirectory, "bin", SdkVersion, "x64", "rc.exe"), true);
            string ExpectedCompilerPath = E02Path(E02Required("E02_COMPILER_PATH"), true);
            string ExpectedResourceCompilerPath = E02Path(E02Required("E02_RESOURCE_COMPILER_PATH"), true);
            long ExpectedCompilerBytes = E02Bytes("E02_COMPILER_BYTES");
            long ExpectedResourceCompilerBytes = E02Bytes("E02_RESOURCE_COMPILER_BYTES");
            string ExpectedCompilerHash = E02Hash("E02_COMPILER_SHA256");
            string ExpectedResourceCompilerHash = E02Hash("E02_RESOURCE_COMPILER_SHA256");
            if (!E02SamePath(CompilerPath, ExpectedCompilerPath) || !E02SamePath(ResourceCompilerPath, ExpectedResourceCompilerPath))
            {
                throw new BuildException("E02_NATIVE_TOOLCHAIN_SELECTED_EXECUTABLE_PATH_MISMATCH");
            }

            FileStream? CompilerLock = null;
            FileStream? ResourceCompilerLock = null;
            try
            {
                CompilerLock = new FileStream(CompilerPath, FileMode.Open, FileAccess.Read, FileShare.Read);
                ResourceCompilerLock = new FileStream(ResourceCompilerPath, FileMode.Open, FileAccess.Read, FileShare.Read);
                long CompilerBytes = CompilerLock.Length;
                long ResourceCompilerBytes = ResourceCompilerLock.Length;
                string CompilerHash = E02StreamHash(CompilerLock);
                string ResourceCompilerHash = E02StreamHash(ResourceCompilerLock);
                if (CompilerBytes != ExpectedCompilerBytes || ResourceCompilerBytes != ExpectedResourceCompilerBytes
                    || CompilerHash != ExpectedCompilerHash || ResourceCompilerHash != ExpectedResourceCompilerHash)
                {
                    throw new BuildException("E02_NATIVE_TOOLCHAIN_SELECTED_EXECUTABLE_BYTES_MISMATCH");
                }

                byte[] Receipt = JsonSerializer.SerializeToUtf8Bytes(new
                {
                    schemaVersion = 1,
                    runId = RunId,
                    sourceHead = SourceHead,
                    sourceRoot = SourceRoot,
                    sourceRootBinding = "CALLER_INPUT_MATCHES_MODULE_DERIVED_REPOSITORY",
                    project = ProjectPath,
                    target = Target.Name,
                    configuration = Target.Configuration.ToString(),
                    platform = Target.Platform.ToString(),
                    architecture = "x64",
                    hostArchitecture = "X64",
                    compilerSelection = new
                    {
                        name = Windows.Compiler.ToString(),
                        version = CompilerVersion,
                        directory = CompilerDirectory,
                        toolChain = Windows.ToolChain.ToString(),
                        toolChainVersion = ToolchainVersion,
                        toolChainDirectory = ToolchainDirectory
                    },
                    windowsSdk = new { version = SdkVersion, directory = SdkDirectory },
                    compiler = new { path = CompilerPath, bytes = CompilerBytes, sha256 = CompilerHash },
                    resourceCompiler = new { path = ResourceCompilerPath, bytes = ResourceCompilerBytes, sha256 = ResourceCompilerHash },
                    validationPhase = "MODULE_RULES_CONSTRUCTOR_BEFORE_NATIVE_ACTIONS",
                    scope = "DIRECT_COMPILER_AND_RESOURCE_COMPILER_EXECUTABLES_ONLY",
                    directExecutableReadLocksHeldThroughUbtExit = true
                });
                E02WriteReceipt(ReceiptPath, Receipt);
                E02ExecutableReadLocks.Add(CompilerLock);
                CompilerLock = null;
                E02ExecutableReadLocks.Add(ResourceCompilerLock);
                ResourceCompilerLock = null;
            }
            finally
            {
                CompilerLock?.Dispose();
                ResourceCompilerLock?.Dispose();
            }
        }
    }

    private static string E02Required(string Name)
    {
        string? Value = Environment.GetEnvironmentVariable(Name);
        if (String.IsNullOrWhiteSpace(Value) || Value != Value.Trim())
        {
            throw new BuildException("E02_NATIVE_TOOLCHAIN_INPUT_MISSING_OR_INVALID: {0}", Name);
        }
        return Value;
    }

    private static long E02Bytes(string Name)
    {
        string Value = E02Required(Name);
        if (!Regex.IsMatch(Value, "\\A[1-9][0-9]*\\z")
            || !Int64.TryParse(Value, NumberStyles.None, CultureInfo.InvariantCulture, out long Bytes))
        {
            throw new BuildException("E02_NATIVE_TOOLCHAIN_BYTE_COUNT_INVALID: {0}", Name);
        }
        return Bytes;
    }

    private static string E02Hash(string Name)
    {
        string Value = E02Required(Name);
        if (!Regex.IsMatch(Value, "\\A[0-9a-fA-F]{64}\\z"))
        {
            throw new BuildException("E02_NATIVE_TOOLCHAIN_HASH_INVALID: {0}", Name);
        }
        return Value.ToUpperInvariant();
    }

    private static bool E02SamePath(string Left, string Right)
    {
        return String.Equals(Left, Right, StringComparison.OrdinalIgnoreCase);
    }

    private static string E02Path(string Value, bool MustExist)
    {
        if (!Path.IsPathFullyQualified(Value) || Value.Any(Character => Char.IsControl(Character)))
        {
            throw new BuildException("E02_NATIVE_TOOLCHAIN_PATH_INVALID");
        }
        string FullPath = Path.GetFullPath(Value).TrimEnd(Path.DirectorySeparatorChar);
        if (!Regex.IsMatch(FullPath, "\\A[A-Za-z]:\\\\") || FullPath.IndexOf(':', 2) >= 0
            || (MustExist && !File.Exists(FullPath) && !Directory.Exists(FullPath)))
        {
            throw new BuildException("E02_NATIVE_TOOLCHAIN_LOCAL_PATH_MISSING_OR_INVALID");
        }
        for (string? Current = FullPath; Current != null; Current = Path.GetDirectoryName(Current))
        {
            if ((File.Exists(Current) || Directory.Exists(Current))
                && (File.GetAttributes(Current) & FileAttributes.ReparsePoint) != 0)
            {
                throw new BuildException("E02_NATIVE_TOOLCHAIN_REPARSE_PATH_FORBIDDEN");
            }
        }
        return FullPath;
    }

    private static DirectoryInfo E02Parent(DirectoryInfo Child, string ExpectedName)
    {
        DirectoryInfo? Parent = Child.Parent;
        if (!String.Equals(Child.Name, ExpectedName, StringComparison.OrdinalIgnoreCase) || Parent == null)
        {
            throw new BuildException("E02_NATIVE_TOOLCHAIN_MODULE_ANCESTRY_INVALID");
        }
        return Parent;
    }

    private static string E02StreamHash(FileStream Stream)
    {
        using SHA256 Algorithm = SHA256.Create();
        return Convert.ToHexString(Algorithm.ComputeHash(Stream));
    }

    private static void E02WriteReceipt(string ReceiptPath, byte[] Receipt)
    {
        if (Directory.Exists(ReceiptPath))
        {
            throw new BuildException("E02_NATIVE_TOOLCHAIN_RECEIPT_IS_DIRECTORY");
        }
        if (File.Exists(ReceiptPath))
        {
            if (!File.ReadAllBytes(ReceiptPath).SequenceEqual(Receipt))
            {
                throw new BuildException("E02_NATIVE_TOOLCHAIN_RECEIPT_ALREADY_EXISTS_WITH_DIFFERENT_IDENTITY");
            }
            return;
        }
        using FileStream Output = new FileStream(ReceiptPath, FileMode.CreateNew, FileAccess.Write, FileShare.Read);
        Output.Write(Receipt, 0, Receipt.Length);
        Output.Flush(true);
    }
}
