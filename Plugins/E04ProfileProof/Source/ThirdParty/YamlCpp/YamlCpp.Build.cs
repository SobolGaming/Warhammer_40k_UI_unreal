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

// Inert A1 draft. No dependency acquisition, CMake install or native authority.
public class YamlCpp : ModuleRules
{
    private const string Pin = "56e3bb550c91fd7005566f19c079cb7a503223cf";
    private static readonly object SelectionSync = new object();
    // Deny writes/deletion of verified files until this UBT process exits.
    private static readonly List<FileStream> ReadLocks = new List<FileStream>();
    private static StringComparison PathComparison => OperatingSystem.IsWindows() ? StringComparison.OrdinalIgnoreCase : StringComparison.Ordinal;

    public YamlCpp(ReadOnlyTargetRules Target) : base(Target)
    {
        Type = ModuleType.External;
        CppStandard = CppStandardVersion.Cpp20;
        if (Target.Name == "WarhammerClientE04A1G")
        {
            ConfigureA1G(Target);
            return;
        }
        if (Required("E04A1_NATIVE_BOUNDARY_REQUIRED") != "1") Fail("REQUIRED_FLAG_INVALID");
        if (Target.Name != "WarhammerClientE04AEditor" || Target.Type != TargetType.Editor
            || Target.Configuration != UnrealTargetConfiguration.Development || Target.Architectures.bIsMultiArch
            || !Target.Architecture.bIsX64) Fail("TARGET_OUTSIDE_DEDICATED_PROOF");
        // A native Linux host/toolchain/artifact review is a real prerequisite.
        // Never select a Win64 library or make a /MD claim for Linux.
        if (Target.Platform == UnrealTargetPlatform.Linux) Fail("LINUX_NATIVE_TOOLCHAIN_AND_ARTIFACT_PREREQUISITE_UNMET");
        if (Target.Platform != UnrealTargetPlatform.Win64 || !OperatingSystem.IsWindows()
            || RuntimeInformation.ProcessArchitecture != Architecture.X64) Fail("WIN64_NATIVE_HOST_REQUIRED");
        if (Target.bUseStaticCRT || Target.bDebugBuildsActuallyUseDebugCRT) Fail("DEVELOPMENT_DYNAMIC_RELEASE_CRT_REQUIRED");
        if (Target.CppStandard != CppStandardVersion.Cpp20) Fail("DEDICATED_TARGET_CPP20_REQUIRED");
        RejectUnsupportedNativeToolAlternatives(Target);

        lock (SelectionSync)
        {
            string runId = Required("E04A1_RUN_ID");
            string sourceHead = Required("E04A1_SOURCE_HEAD");
            if (!Regex.IsMatch(runId, "\\A[0-9]{8}T[0-9]{6}Z-[0-9a-f]{8}\\z")
                || !Regex.IsMatch(sourceHead, "\\A[0-9a-f]{40}\\z")) Fail("RUN_OR_SOURCE_IDENTITY_INVALID");
            DirectoryInfo module = new DirectoryInfo(CheckedPath(ModuleDirectory, true));
            DirectoryInfo thirdParty = Parent(module, "YamlCpp");
            DirectoryInfo source = Parent(thirdParty, "ThirdParty");
            DirectoryInfo plugin = Parent(source, "Source");
            DirectoryInfo plugins = Parent(plugin, "E04ProfileProof");
            DirectoryInfo project = Parent(plugins, "Plugins");
            DirectoryInfo run = Parent(project, "project");
            DirectoryInfo experiment = Parent(run, runId);
            DirectoryInfo experiments = Parent(experiment, "E04A1");
            DirectoryInfo local = Parent(experiments, "experiments");
            DirectoryInfo repository = Parent(local, ".local");
            string sourceRoot = CheckedPath(repository.FullName, true);
            string stagedProject = CheckedPath(Path.Combine(project.FullName, "WarhammerClient.uproject"), true);
            string receiptPath = CheckedPath(Path.Combine(run.FullName, "logs", "yaml-artifact-receipt.json"), true);
            string selectionPath = CheckedPath(Path.Combine(run.FullName, "logs", "yaml-module-selection.json"), false);
            if (!Same(sourceRoot, CheckedPath(Required("E04A1_SOURCE_ROOT"), true))
                || !Same(stagedProject, CheckedPath(Required("E04A1_STAGED_PROJECT"), true))
                || !Same(receiptPath, CheckedPath(Required("E04A1_ARTIFACT_RECEIPT"), true))
                || Target.ProjectFile == null || !Same(stagedProject, CheckedPath(Target.ProjectFile.FullName, true))) Fail("STAGED_ANCESTRY_OR_PROJECT_MISMATCH");

            FileStream receiptLock = Hold(receiptPath, null, HashInput("E04A1_ARTIFACT_RECEIPT_SHA256"));
            using JsonDocument receipt = ReadJson(receiptLock);
            JsonElement r = receipt.RootElement;
            Identity(r, "E04A1_VENDOR_ARTIFACT_RECEIPT", runId, sourceHead, sourceRoot, stagedProject);
            Eq(r, "vendorPin", Pin);
            JsonElement abi = Get(r, "abi");
            Eq(abi, "target", Target.Name); Eq(abi, "platform", "Win64"); Eq(abi, "architecture", "x64");
            Eq(abi, "configuration", "Development"); Eq(abi, "cppStandard", "C++20");
            Eq(abi, "runtime", "MD"); Eq(abi, "linkage", "static"); Eq(abi, "staticDefine", "YAML_CPP_STATIC_DEFINE");
            if (!Boolean(abi, "exceptionsEnabled")) Fail("VENDOR_EXCEPTIONS_REQUIRED");

            string preparationId = Text(r, "sourcePreparationId");
            if (!Regex.IsMatch(preparationId, "\\A[0-9]{8}T[0-9]{6}Z-[a-z0-9]{8,32}\\z")) Fail("SOURCE_PREPARATION_ID_INVALID");
            string acquiredOwner = CheckedPath(Path.Combine(sourceRoot, ".local", "dependencies", "E04A1", preparationId), true);
            string acquiredSource = CheckedPath(Path.Combine(acquiredOwner, "yaml-cpp"), true);
            string acquisitionPath = CheckedPath(Path.Combine(acquiredOwner, "acquisition-result.json"), true);
            FileStream acquisitionLock = HoldDescriptor(Get(r, "acquisitionResult"), acquisitionPath);
            using JsonDocument acquisition = ReadJson(acquisitionLock);
            JsonElement a = acquisition.RootElement;
            Eq(a, "status", "ACQUIRED_PIN_AND_BYTES_VERIFIED_NOT_BUILD_OR_SOURCE_APPROVAL");
            Eq(a, "pin", Pin); Eq(a, "preparationId", preparationId);
            Eq(a, "repository", "https://github.com/jbeder/yaml-cpp.git");
            if (!Boolean(a, "allCheckoutBytesMatchPinnedBlobs") || Boolean(a, "dependencySourceExecuted") || Boolean(a, "buildReleased")) Fail("ACQUISITION_SCOPE_INVALID");
            string treeOid = Text(r, "sourceTreeOid");
            if (!Regex.IsMatch(treeOid, "\\A[0-9a-f]{40}\\z")) Fail("SOURCE_TREE_IDENTITY_INVALID");
            JsonElement[] roots = Array(a, "trees").Where(e => Text(e, "path") == "").ToArray();
            if (roots.Length != 1 || Text(roots[0], "treeOid") != treeOid) Fail("ACQUISITION_TREE_MISMATCH");

            string artifactRoot = CheckedPath(Path.Combine(run.FullName, "vendor-artifact", "Win64", "Development", "x64"), true);
            string includeRoot = CheckedPath(Path.Combine(artifactRoot, "include"), true);
            string libraryPath = CheckedPath(Path.Combine(artifactRoot, "lib", "yaml-cpp.lib"), true);
            if (!Same(CheckedPath(Text(r, "artifactRoot"), true), artifactRoot)
                || !Same(CheckedPath(Text(r, "includeRoot"), true), includeRoot)) Fail("ARTIFACT_ROOT_MISMATCH");
            FileStream libraryLock = HoldDescriptor(Get(r, "library"), libraryPath);
            if (libraryLock.Length == 0) Fail("STATIC_LIBRARY_EMPTY");
            string libraryHash = StreamHash(libraryLock);

            // Only complete explicit copies of the acquired include/ files are accepted.
            // No installed/system/header-directory fallback or vendor-tree include path.
            var sourceHeaders = new Dictionary<string, JsonElement>(StringComparer.Ordinal);
            foreach (JsonElement file in Array(a, "files"))
            {
                string relative = Text(file, "path");
                if (relative.StartsWith("include/", StringComparison.Ordinal))
                {
                    string headerRelative = SafeRelative(relative.Substring("include/".Length));
                    if (!sourceHeaders.TryAdd(headerRelative, file)) Fail("DUPLICATE_ACQUIRED_HEADER");
                }
            }
            if (sourceHeaders.Count == 0) Fail("ACQUIRED_HEADERS_ABSENT");
            var headerPaths = new HashSet<string>(PathComparison == StringComparison.OrdinalIgnoreCase ? StringComparer.OrdinalIgnoreCase : StringComparer.Ordinal);
            foreach (JsonElement header in Array(r, "headers"))
            {
                string relative = SafeRelative(Text(header, "relativePath"));
                if (!headerPaths.Add(relative)) Fail("DUPLICATE_OR_CASE_COLLIDING_HEADER");
                if (!sourceHeaders.TryGetValue(relative, out JsonElement original)) Fail("HEADER_MEMBERSHIP_MISMATCH");
                string copied = Inside(includeRoot, relative);
                string originalPath = Inside(acquiredSource, "include/" + relative);
                long bytes = Integer(header, "bytes"); string hash = HashText(header, "sha256");
                if (bytes != Integer(original, "bytes") || hash != HashText(original, "sha256")) Fail("HEADER_NOT_PINNED_SOURCE_BYTES");
                Hold(originalPath, bytes, hash); Hold(copied, bytes, hash);
            }
            if (headerPaths.Count != sourceHeaders.Count) Fail("HEADER_LIST_INCOMPLETE");
            CheckMembership(CheckedPath(Path.Combine(acquiredSource, "include"), true), headerPaths);
            CheckMembership(includeRoot, headerPaths);

            JsonElement windows = Get(r, "windows");
            ReadOnlyWindowsTargetRules w = Target.WindowsPlatform;
            if (w.Compiler != WindowsCompiler.VisualStudio2022 || w.ToolChain != WindowsCompiler.VisualStudio2022
                || w.CompilerVersion != "14.44.35229" || w.ToolChainVersion != "14.44.35229"
                || w.WindowsSdkVersion != "10.0.22621.0" || !w.Architecture.bIsX64) Fail("WINDOWS_SELECTED_VERSION_MISMATCH");
            string compilerDir = CheckedPath(w.CompilerDir ?? throw new BuildException("E04A1_YAML_COMPILER_DIRECTORY_UNRESOLVED"), true);
            string toolChainDir = CheckedPath(w.ToolChainDir ?? throw new BuildException("E04A1_YAML_TOOLCHAIN_DIRECTORY_UNRESOLVED"), true);
            string sdkDir = CheckedPath(w.WindowsSdkDir ?? throw new BuildException("E04A1_YAML_SDK_DIRECTORY_UNRESOLVED"), true);
            if (!Same(compilerDir, toolChainDir)) Fail("WINDOWS_COMPILER_TOOLCHAIN_DIRECTORY_MISMATCH");
            Eq(windows, "compilerName", w.Compiler.ToString()); Eq(windows, "compilerVersion", w.CompilerVersion!);
            Eq(windows, "toolChainName", w.ToolChain.ToString()); Eq(windows, "toolChainVersion", w.ToolChainVersion!);
            Eq(windows, "sdkVersion", w.WindowsSdkVersion!);
            PathEq(windows, "compilerDir", compilerDir); PathEq(windows, "toolChainDir", toolChainDir); PathEq(windows, "sdkDir", sdkDir);
            var selectedTools = new Dictionary<string, string>(StringComparer.Ordinal)
            {
                { "compiler", Path.Combine(compilerDir, "bin", "Hostx64", "x64", "cl.exe") },
                { "linker", Path.Combine(toolChainDir, "bin", "Hostx64", "x64", "link.exe") },
                { "librarian", Path.Combine(toolChainDir, "bin", "Hostx64", "x64", "lib.exe") },
                { "resourceCompiler", Path.Combine(sdkDir, "bin", w.WindowsSdkVersion!, "x64", "rc.exe") }
            };
            JsonElement tools = Get(r, "tools");
            foreach (var tool in selectedTools) HoldDescriptor(Get(tools, tool.Key), CheckedPath(tool.Value, true));

            string buildReceiptPath = CheckedPath(Path.Combine(run.FullName, "logs", "vendor-cmake-build.json"), true);
            FileStream buildReceiptLock = HoldDescriptor(Get(r, "vendorBuildReceipt"), buildReceiptPath);
            using JsonDocument build = ReadJson(buildReceiptLock);
            JsonElement b = build.RootElement;
            Identity(b, "E04A1_VENDOR_CMAKE_BUILD_RECEIPT", runId, sourceHead, sourceRoot, stagedProject);
            Eq(b, "status", "COMPLETED_SUCCESS"); Eq(b, "vendorPin", Pin); Eq(b, "sourceTreeOid", treeOid);
            PathEq(b, "vendorSourceRoot", acquiredSource);
            if (HashText(b, "acquisitionResultSha256") != StreamHash(acquisitionLock)) Fail("ACQUISITION_RECEIPT_HASH_MISMATCH");
            Eq(b, "configuration", "Release"); Eq(b, "platform", "Win64"); Eq(b, "architecture", "x64");
            Eq(b, "cppStandard", "C++20"); Eq(b, "runtime", "MD"); Eq(b, "linkage", "static");
            if (!Boolean(b, "exceptionsEnabled") || Boolean(b, "installTargetInvoked")) Fail("VENDOR_BUILD_SCOPE_INVALID");
            JsonElement builtLibrary = Get(b, "library");
            string buildRoot = CheckedPath(Path.Combine(run.FullName, "vendor-build", "Win64", "Development", "x64"), true);
            string builtLibraryPath = CheckedPath(Text(builtLibrary, "path"), true);
            if (!IsInside(builtLibraryPath, buildRoot) || Path.GetFileName(builtLibraryPath) != "yaml-cpp.lib") Fail("BUILT_LIBRARY_OUTSIDE_SAME_RUN");
            FileStream builtLibraryLock = HoldDescriptor(builtLibrary, builtLibraryPath);
            if (builtLibraryLock.Length != libraryLock.Length || StreamHash(builtLibraryLock) != libraryHash) Fail("LIBRARY_COPY_NOT_BUILD_BYTES");
            JsonElement buildCompiler = Get(b, "compiler");
            HoldDescriptor(buildCompiler, CheckedPath(selectedTools["compiler"], true));
            if (Integer(buildCompiler, "bytes") != Integer(Get(tools, "compiler"), "bytes")
                || HashText(buildCompiler, "sha256") != HashText(Get(tools, "compiler"), "sha256")) Fail("VENDOR_UBT_COMPILER_BYTES_MISMATCH");

            object rulesWitness = ObserveRules(Target, runId, sourceHead, sourceRoot, stagedProject, run.FullName);

            byte[] selection = JsonSerializer.SerializeToUtf8Bytes(new
            {
                schemaVersion = 1, kind = "E04A1_YAML_MODULE_SELECTION", runId, sourceHead, sourceRoot,
                stagedProject, vendorPin = Pin, sourcePreparationId = preparationId, sourceTreeOid = treeOid,
                artifactReceipt = new { path = receiptPath, bytes = receiptLock.Length, sha256 = StreamHash(receiptLock) },
                acquisitionResult = new { path = acquisitionPath, bytes = acquisitionLock.Length, sha256 = StreamHash(acquisitionLock) },
                vendorBuildReceipt = new { path = buildReceiptPath, bytes = buildReceiptLock.Length, sha256 = StreamHash(buildReceiptLock) },
                target = Target.Name, platform = Target.Platform.ToString(), configuration = Target.Configuration.ToString(), architecture = "x64",
                cppStandard = "C++20", runtime = "MD", linkage = "static", includeRoot, libraryPath, librarySha256 = libraryHash,
                headerCount = headerPaths.Count, selectedWindows = windows, selectedTools = tools,
                rulesWitness,
                fileReadLocksHeldThroughUbtExit = true,
                scope = "CONSTRUCTOR_SELECTION_AND_BYTES_ONLY_NOT_NATIVE_FLAGS_OR_ARTIFACT_LINEAGE_CERTIFICATION"
            });
            WriteStable(selectionPath, selection);
            PublicDefinitions.Add("YAML_CPP_STATIC_DEFINE");
            PublicSystemIncludePaths.Add(includeRoot);
            PublicAdditionalLibraries.Add(libraryPath);
        }
    }

    // Bounded A1G-only constructor seam. No acquisition/build,
    // Editor receipt relabel, Rules reflection or native authority occurs here.
    private void ConfigureA1G(ReadOnlyTargetRules target)
    {
        if (Required("E04_A1G_NATIVE_BOUNDARY_REQUIRED") != "1") Fail("A1G_REQUIRED_FLAG_INVALID");
        if (target.Name != "WarhammerClientE04A1G" || target.Type != TargetType.Game
            || target.Platform != UnrealTargetPlatform.Win64
            || target.Configuration != UnrealTargetConfiguration.Development
            || target.Architectures.bIsMultiArch || !target.Architecture.bIsX64
            || !OperatingSystem.IsWindows() || RuntimeInformation.ProcessArchitecture != Architecture.X64)
            Fail("A1G_DEDICATED_WIN64_GAME_REQUIRED");
        if (target.CppStandard != CppStandardVersion.Cpp20 || target.bUseStaticCRT
            || target.bDebugBuildsActuallyUseDebugCRT) Fail("A1G_CPP20_DYNAMIC_RELEASE_CRT_REQUIRED");
        if (target.bForceEnableExceptions || target.bCompileAgainstEditor
            || !target.bBuildRequiresCookedData || target.LinkType != TargetLinkType.Monolithic
            || target.BuildEnvironment != TargetBuildEnvironment.Shared || target.bOverrideBuildEnvironment)
            Fail("A1G_NORMAL_INSTALLED_GAME_ENVIRONMENT_REQUIRED");
        RejectUnsupportedNativeToolAlternatives(target);
        foreach (System.Collections.DictionaryEntry entry in Environment.GetEnvironmentVariables())
        {
            string key = (string)entry.Key;
            if (key.StartsWith("E04A1_", StringComparison.OrdinalIgnoreCase)
                || key.StartsWith("E02_", StringComparison.OrdinalIgnoreCase))
                Fail("A1G_EDITOR_OR_E02_ENVIRONMENT_MUST_BE_ABSENT");
        }

        lock (SelectionSync)
        {
            string runId = Required("E04_A1G_RUN_ID");
            string sourceHead = Required("E04_A1G_SOURCE_HEAD");
            if (!Regex.IsMatch(runId, "\\A[0-9]{8}T[0-9]{6}Z-[0-9a-f]{8}\\z")
                || !Regex.IsMatch(sourceHead, "\\A[0-9a-f]{40}\\z")) Fail("A1G_RUN_OR_SOURCE_INVALID");
            DirectoryInfo module = new DirectoryInfo(CheckedPath(ModuleDirectory, true));
            DirectoryInfo thirdParty = Parent(module, "YamlCpp");
            DirectoryInfo source = Parent(thirdParty, "ThirdParty");
            DirectoryInfo plugin = Parent(source, "Source");
            DirectoryInfo plugins = Parent(plugin, "E04ProfileProof");
            DirectoryInfo project = Parent(plugins, "Plugins");
            DirectoryInfo run = Parent(project, "project");
            DirectoryInfo experiment = Parent(run, runId);
            DirectoryInfo experiments = Parent(experiment, "E04A1G");
            DirectoryInfo local = Parent(experiments, "experiments");
            DirectoryInfo repository = Parent(local, ".local");
            string sourceRoot = CheckedPath(repository.FullName, true);
            string stagedProject = CheckedPath(Path.Combine(project.FullName, "WarhammerClient.uproject"), true);
            string logs = CheckedPath(Path.Combine(run.FullName, "logs"), true);
            string receiptPath = CheckedPath(Path.Combine(logs, "a1g-yaml-artifact-receipt.json"), true);
            string selectionPath = CheckedPath(Path.Combine(logs, "a1g-yaml-module-selection.json"), false);
            if (!Same(sourceRoot, CheckedPath(Required("E04_A1G_SOURCE_ROOT"), true))
                || !Same(run.FullName, CheckedPath(Required("E04_A1G_RUN_ROOT"), true))
                || !Same(stagedProject, CheckedPath(Required("E04_A1G_STAGED_PROJECT"), true))
                || !Same(receiptPath, CheckedPath(Required("E04_A1G_ARTIFACT_RECEIPT"), true))
                || target.ProjectFile == null || !Same(stagedProject, CheckedPath(target.ProjectFile.FullName, true)))
                Fail("A1G_STAGED_ANCESTRY_OR_RECEIPT_MISMATCH");

            FileStream receiptLock = Hold(receiptPath, null, HashInput("E04_A1G_ARTIFACT_RECEIPT_SHA256"));
            using JsonDocument receipt = ReadJson(receiptLock);
            JsonElement r = receipt.RootElement;
            Identity(r, "E04_A1G_VENDOR_ARTIFACT_RECEIPT", runId, sourceHead, sourceRoot, stagedProject);
            Eq(r, "status", "COPIED_FROM_SAME_RUN_BUILD_NOT_PHASE_ACCEPTANCE");
            Eq(r, "vendorPin", Pin);
            Eq(r, "specialAssuranceCertification", "DEFERRED_UNPROVEN_OWN17");
            JsonElement abi = Get(r, "abi");
            Eq(abi, "target", target.Name); Eq(abi, "targetType", "Game");
            Eq(abi, "targetConfiguration", "Development"); Eq(abi, "vendorConfiguration", "Release");
            Eq(abi, "platform", "Win64"); Eq(abi, "architecture", "x64");
            Eq(abi, "cppStandard", "C++20"); Eq(abi, "runtime", "MD");
            Eq(abi, "linkage", "static"); Eq(abi, "staticDefine", "YAML_CPP_STATIC_DEFINE");
            if (!Boolean(abi, "vendorExceptionsEnabled")) Fail("A1G_VENDOR_EH_REQUIRED");
            JsonElement requirements = Get(r, "consumerRequirements");
            Eq(requirements, "parserExceptions", "EHsc"); Eq(requirements, "callerExceptions", "Disabled");
            Eq(requirements, "publicBoundary", "UE_OWNED_SYNCHRONOUS_NOEXCEPT");

            // The acquisition is immutable source data, with its original identity
            // and E04A1 preparation path; it is neither an Editor nor Game artifact.
            string preparationId = Text(r, "sourcePreparationId");
            if (!Regex.IsMatch(preparationId, "\\A[0-9]{8}T[0-9]{6}Z-[a-z0-9]{8,32}\\z")) Fail("A1G_PREPARATION_ID_INVALID");
            string acquiredOwner = CheckedPath(Path.Combine(sourceRoot, ".local", "dependencies", "E04A1", preparationId), true);
            string acquiredSource = CheckedPath(Path.Combine(acquiredOwner, "yaml-cpp"), true);
            string acquisitionPath = CheckedPath(Path.Combine(acquiredOwner, "acquisition-result.json"), true);
            FileStream acquisitionLock = HoldDescriptor(Get(r, "acquisitionResult"), acquisitionPath);
            using JsonDocument acquisition = ReadJson(acquisitionLock);
            JsonElement a = acquisition.RootElement;
            Eq(a, "status", "ACQUIRED_PIN_AND_BYTES_VERIFIED_NOT_BUILD_OR_SOURCE_APPROVAL");
            Eq(a, "pin", Pin); Eq(a, "preparationId", preparationId);
            Eq(a, "repository", "https://github.com/jbeder/yaml-cpp.git");
            if (!Boolean(a, "allCheckoutBytesMatchPinnedBlobs") || Boolean(a, "dependencySourceExecuted")
                || Boolean(a, "buildReleased")) Fail("A1G_ACQUISITION_SCOPE_INVALID");
            string treeOid = Text(r, "sourceTreeOid");
            if (!Regex.IsMatch(treeOid, "\\A[0-9a-f]{40}\\z")) Fail("A1G_SOURCE_TREE_INVALID");
            JsonElement[] roots = Array(a, "trees").Where(e => Text(e, "path") == "").ToArray();
            if (roots.Length != 1 || Text(roots[0], "treeOid") != treeOid) Fail("A1G_ACQUISITION_TREE_MISMATCH");

            string artifactRoot = CheckedPath(Path.Combine(run.FullName, "vendor-artifact", "Win64", "Release", "x64"), true);
            string includeRoot = CheckedPath(Path.Combine(artifactRoot, "include"), true);
            string libraryPath = CheckedPath(Path.Combine(artifactRoot, "lib", "yaml-cpp.lib"), true);
            PathEq(r, "artifactRoot", artifactRoot); PathEq(r, "includeRoot", includeRoot);
            FileStream libraryLock = HoldDescriptor(Get(r, "library"), libraryPath);
            if (libraryLock.Length <= 8 || libraryLock.Length > 67108864) Fail("A1G_STATIC_LIBRARY_SIZE_INVALID");
            byte[] magic = new byte[8]; libraryLock.Position = 0; libraryLock.ReadExactly(magic); libraryLock.Position = 0;
            if (System.Text.Encoding.ASCII.GetString(magic) != "!<arch>\n") Fail("A1G_STATIC_ARCHIVE_MAGIC_MISSING");
            string libraryHash = StreamHash(libraryLock);

            var sourceHeaders = new Dictionary<string, JsonElement>(StringComparer.Ordinal);
            foreach (JsonElement file in Array(a, "files"))
            {
                string relative = Text(file, "path");
                if (relative.StartsWith("include/", StringComparison.Ordinal)
                    && !sourceHeaders.TryAdd(SafeRelative(relative.Substring(8)), file)) Fail("A1G_DUPLICATE_SOURCE_HEADER");
            }
            if (sourceHeaders.Count == 0) Fail("A1G_SOURCE_HEADERS_ABSENT");
            var headerPaths = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            foreach (JsonElement header in Array(r, "headers"))
            {
                string relative = SafeRelative(Text(header, "relativePath"));
                if (!headerPaths.Add(relative)) Fail("A1G_DUPLICATE_OR_COLLIDING_HEADER");
                if (!sourceHeaders.TryGetValue(relative, out JsonElement original)) Fail("A1G_HEADER_MEMBERSHIP_MISMATCH");
                long bytes = Integer(header, "bytes"); string hash = HashText(header, "sha256");
                if (bytes != Integer(original, "bytes") || hash != HashText(original, "sha256")) Fail("A1G_HEADER_NOT_PINNED_BYTES");
                Hold(Inside(acquiredSource, "include/" + relative), bytes, hash);
                Hold(Inside(includeRoot, relative), bytes, hash);
            }
            if (headerPaths.Count != sourceHeaders.Count) Fail("A1G_HEADER_LIST_INCOMPLETE");
            CheckMembership(CheckedPath(Path.Combine(acquiredSource, "include"), true), headerPaths);
            CheckMembership(includeRoot, headerPaths);
            FileStream sourceLicense = HoldDescriptor(Get(r, "sourceLicense"), CheckedPath(Path.Combine(acquiredSource, "LICENSE"), true));
            FileStream license = HoldDescriptor(Get(r, "license"), CheckedPath(Path.Combine(artifactRoot, "LICENSE.yaml-cpp"), true));
            if (sourceLicense.Length != 1061 || StreamHash(sourceLicense) != "AA6FCC27BE034E41E21DD832F9175BFE694A48491D9E14FF0FA278E19AD14F1B"
                || license.Length != sourceLicense.Length || StreamHash(license) != StreamHash(sourceLicense)) Fail("A1G_MIT_NOTICE_COPY_MISMATCH");

            JsonElement windows = Get(r, "windows");
            ReadOnlyWindowsTargetRules w = target.WindowsPlatform;
            if (w.Compiler != WindowsCompiler.VisualStudio2022 || w.ToolChain != WindowsCompiler.VisualStudio2022
                || w.CompilerVersion != "14.44.35229" || w.ToolChainVersion != "14.44.35229"
                || w.WindowsSdkVersion != "10.0.22621.0" || !w.Architecture.bIsX64) Fail("A1G_WINDOWS_VERSION_MISMATCH");
            string compilerDir = CheckedPath(w.CompilerDir ?? throw new BuildException("E04_A1G_COMPILER_DIRECTORY_UNRESOLVED"), true);
            string toolChainDir = CheckedPath(w.ToolChainDir ?? throw new BuildException("E04_A1G_TOOLCHAIN_DIRECTORY_UNRESOLVED"), true);
            string sdkDir = CheckedPath(w.WindowsSdkDir ?? throw new BuildException("E04_A1G_SDK_DIRECTORY_UNRESOLVED"), true);
            if (!Same(compilerDir, toolChainDir)) Fail("A1G_COMPILER_TOOLCHAIN_DIRECTORY_MISMATCH");
            Eq(windows, "compilerName", w.Compiler.ToString()); Eq(windows, "compilerVersion", w.CompilerVersion!);
            Eq(windows, "toolChainName", w.ToolChain.ToString()); Eq(windows, "toolChainVersion", w.ToolChainVersion!);
            Eq(windows, "sdkVersion", w.WindowsSdkVersion!);
            PathEq(windows, "compilerDir", compilerDir); PathEq(windows, "toolChainDir", toolChainDir); PathEq(windows, "sdkDir", sdkDir);
            var selectedTools = new Dictionary<string, string>(StringComparer.Ordinal)
            {
                { "compiler", Path.Combine(compilerDir, "bin", "Hostx64", "x64", "cl.exe") },
                { "linker", Path.Combine(toolChainDir, "bin", "Hostx64", "x64", "link.exe") },
                { "librarian", Path.Combine(toolChainDir, "bin", "Hostx64", "x64", "lib.exe") },
                { "resourceCompiler", Path.Combine(sdkDir, "bin", w.WindowsSdkVersion!, "x64", "rc.exe") }
            };
            JsonElement tools = Get(r, "tools");
            foreach (var tool in selectedTools) HoldDescriptor(Get(tools, tool.Key), CheckedPath(tool.Value, true));
            string cmakePath = CheckedPath(Text(Get(tools, "cmake"), "path"), true);
            HoldDescriptor(Get(tools, "cmake"), cmakePath);
            HoldDescriptor(Get(tools, "ninja"), CheckedPath(Text(Get(tools, "ninja"), "path"), true));

            string buildRoot = CheckedPath(Path.Combine(run.FullName, "vendor-build", "Win64", "Release", "x64"), true);
            string configureReceiptPath = CheckedPath(Path.Combine(logs, "a1g-vendor-cmake-configure.json"), true);
            FileStream configureLock = HoldDescriptor(Get(r, "vendorConfigureReceipt"), configureReceiptPath);
            using JsonDocument configure = ReadJson(configureLock);
            JsonElement c = configure.RootElement;
            Identity(c, "E04_A1G_VENDOR_CMAKE_CONFIGURE_RECEIPT", runId, sourceHead, sourceRoot, stagedProject);
            Eq(c, "status", "CONFIGURE_ROOT_AND_CHECKS_PASSED"); Eq(c, "vendorPin", Pin); Eq(c, "sourceTreeOid", treeOid);
            PathEq(c, "vendorSourceRoot", acquiredSource); PathEq(c, "buildRoot", buildRoot);
            if (HashText(c, "acquisitionResultSha256") != StreamHash(acquisitionLock)) Fail("A1G_CONFIGURE_ACQUISITION_MISMATCH");
            Eq(c, "configuration", "Release"); Eq(c, "tryCompileConfiguration", "Release");
            Eq(c, "cxxScanForModules", "OFF");
            Eq(c, "cppStandard", "C++20"); Eq(c, "runtime", "MD"); Eq(c, "exceptions", "EHsc"); Eq(c, "rtti", "GR-");
            Eq(c, "abiProbe", "ACTUAL_RELEASE_COMPILE_AND_LINK_SUCCEEDED");
            HoldDescriptor(Get(c, "cache"), CheckedPath(Path.Combine(buildRoot, "CMakeCache.txt"), true));
            HoldDescriptor(Get(c, "compileCommands"), CheckedPath(Path.Combine(buildRoot, "compile_commands.json"), true));
            HoldDescriptor(Get(c, "ninja"), CheckedPath(Path.Combine(buildRoot, "build.ninja"), true));
            HoldDescriptor(Get(c, "abiEvidenceLog"), CheckedPath(Path.Combine(buildRoot, "CMakeFiles", "CMakeConfigureLog.yaml"), true));
            RequireA1GCMakeRoot(Get(c, "process"),
                CheckedPath(Path.Combine(run.FullName, "dependencyconfigure", "a1g-cmake-configure.process.json"), true), cmakePath, buildRoot);

            string buildReceiptPath = CheckedPath(Path.Combine(logs, "a1g-vendor-cmake-build.json"), true);
            FileStream buildLock = HoldDescriptor(Get(r, "vendorBuildReceipt"), buildReceiptPath);
            using JsonDocument build = ReadJson(buildLock);
            JsonElement b = build.RootElement;
            Identity(b, "E04_A1G_VENDOR_CMAKE_BUILD_RECEIPT", runId, sourceHead, sourceRoot, stagedProject);
            Eq(b, "status", "BUILD_ROOT_AND_ARTIFACT_CHECKS_PASSED"); Eq(b, "vendorPin", Pin); Eq(b, "sourceTreeOid", treeOid);
            PathEq(b, "vendorSourceRoot", acquiredSource); PathEq(b, "buildRoot", buildRoot);
            if (HashText(b, "acquisitionResultSha256") != StreamHash(acquisitionLock)) Fail("A1G_BUILD_ACQUISITION_MISMATCH");
            Eq(b, "configuration", "Release"); Eq(b, "platform", "Win64"); Eq(b, "architecture", "x64");
            Eq(b, "cppStandard", "C++20"); Eq(b, "runtime", "MD"); Eq(b, "linkage", "static");
            Eq(b, "exceptions", "EHsc"); Eq(b, "rtti", "GR-");
            if (!Boolean(b, "exceptionsEnabled") || Boolean(b, "installTargetInvoked")) Fail("A1G_VENDOR_BUILD_SCOPE_INVALID");
            FileStream sameConfigure = HoldDescriptor(Get(b, "configureReceipt"), configureReceiptPath);
            if (StreamHash(sameConfigure) != StreamHash(configureLock)) Fail("A1G_CONFIGURE_RECEIPT_MISMATCH");
            FileStream builtLibrary = HoldDescriptor(Get(b, "library"), CheckedPath(Path.Combine(buildRoot, "yaml-cpp.lib"), true));
            if (builtLibrary.Length != libraryLock.Length || StreamHash(builtLibrary) != libraryHash) Fail("A1G_LIBRARY_COPY_NOT_BUILD_BYTES");
            FileStream buildCompiler = HoldDescriptor(Get(b, "compiler"), CheckedPath(selectedTools["compiler"], true));
            if (buildCompiler.Length != Integer(Get(tools, "compiler"), "bytes")
                || StreamHash(buildCompiler) != HashText(Get(tools, "compiler"), "sha256")) Fail("A1G_VENDOR_UBT_COMPILER_MISMATCH");
            RequireA1GCMakeRoot(Get(b, "process"),
                CheckedPath(Path.Combine(run.FullName, "dependencybuild", "a1g-cmake-build.process.json"), true), cmakePath, buildRoot);

            byte[] selection = JsonSerializer.SerializeToUtf8Bytes(new
            {
                schemaVersion = 1, kind = "E04_A1G_YAML_MODULE_SELECTION", runId, sourceHead, sourceRoot, stagedProject,
                vendorPin = Pin, sourcePreparationId = preparationId, sourceTreeOid = treeOid,
                artifactReceipt = new { path = receiptPath, bytes = receiptLock.Length, sha256 = StreamHash(receiptLock) },
                acquisitionResult = new { path = acquisitionPath, bytes = acquisitionLock.Length, sha256 = StreamHash(acquisitionLock) },
                vendorConfigureReceipt = new { path = configureReceiptPath, bytes = configureLock.Length, sha256 = StreamHash(configureLock) },
                vendorBuildReceipt = new { path = buildReceiptPath, bytes = buildLock.Length, sha256 = StreamHash(buildLock) },
                target = target.Name, targetType = target.Type.ToString(), platform = target.Platform.ToString(),
                targetConfiguration = target.Configuration.ToString(), vendorConfiguration = "Release", architecture = "x64",
                cppStandard = "C++20", runtime = "MD", linkage = "static", includeRoot, libraryPath, librarySha256 = libraryHash,
                headerCount = headerPaths.Count, selectedWindows = windows, selectedTools = tools,
                targetGlobalExceptionsRequested = target.bForceEnableExceptions, targetCompilesAgainstEditor = target.bCompileAgainstEditor,
                parserExceptionsRequirement = "EHsc", callerExceptionsRequirement = "Disabled", publicBoundaryRequirement = "UE_OWNED_SYNCHRONOUS_NOEXCEPT",
                terminalCallerAndParserFlagsObserved = false, fileReadLocksHeldThroughUbtExit = true,
                specialAssuranceCertification = "DEFERRED_UNPROVEN_OWN17",
                scope = "ORDINARY_GAME_TARGET_AND_RECEIPT_FILE_SELECTION_NOT_NATIVE_FLAGS_RULES_OR_ARTIFACT_LINEAGE_CERTIFICATION"
            });
            WriteStable(selectionPath, selection);
            PublicDefinitions.Add("YAML_CPP_STATIC_DEFINE");
            PublicSystemIncludePaths.Add(includeRoot);
            PublicAdditionalLibraries.Add(libraryPath);
        }
    }

    // Ordinary retained owned-root receipt predicate, not descendant inventory,
    // command-language interpretation, phase-completion or lineage certification.
    private static FileStream RequireA1GCMakeRoot(JsonElement descriptor, string expectedPath, string cmakePath, string buildRoot)
    {
        FileStream held = HoldDescriptor(descriptor, expectedPath);
        using JsonDocument json = ReadJson(held);
        JsonElement p = json.RootElement;
        if (Integer(p, "schemaVersion") != 1) Fail("A1G_PROCESS_SCHEMA_UNSUPPORTED");
        PathEq(p, "executable", cmakePath); PathEq(p, "workingDirectory", buildRoot);
        Eq(p, "status", "PASS"); Eq(p, "completionCleanupMode", "PostSuccessfulRootCleanup");
        Eq(p, "syntheticFault", "");
        if (Integer(p, "exitCode") != 0 || Integer(p, "postRootGraceSeconds") != 5
            || !Boolean(p, "assignedBeforeResume") || !Boolean(p, "resumed")
            || !Boolean(p, "exitConfirmed") || !Boolean(p, "cleanupConfirmed")
            || Boolean(p, "timedOut") || Boolean(p, "technicalBlocked") || Boolean(p, "visibleWindowRequested")
            || Get(p, "primaryFailure").ValueKind != JsonValueKind.Null || Array(p, "secondaryErrors").Length != 0)
            Fail("A1G_CMAKE_ROOT_NOT_COMPLETE_SUCCESS");
        JsonElement[] samples = Array(p, "jobAccounting");
        if (samples.Length == 0 || !Boolean(samples[samples.Length - 1], "querySucceeded")
            || Integer(samples[samples.Length - 1], "activeProcesses") != 0) Fail("A1G_CMAKE_JOB_NOT_EMPTY");
        return held;
    }

    private static void RejectUnsupportedNativeToolAlternatives(ReadOnlyTargetRules target)
    {
        // Read final effective settings; do not replace inherited configuration
        // with defaults. Only the frozen MSVC compiler/linker route is supported.
        ReadOnlyWindowsTargetRules windows = target.WindowsPlatform;
        if (windows.bAllowRadLinker)
            Fail("RAD_LINKER_UNSUPPORTED");
        if (target.bPrintToolChainTimingInfo)
            Fail("TOOLCHAIN_TIMING_UNSUPPORTED");
        if (windows.bCompilerTrace)
            Fail("COMPILER_TRACE_UNSUPPORTED");
    }

    private static void Fail(string code) => throw new BuildException("E04A1_YAML_" + code);
    private static string Required(string name)
    {
        string? value = Environment.GetEnvironmentVariable(name);
        if (String.IsNullOrWhiteSpace(value) || value != value.Trim()) throw new BuildException("E04A1_YAML_INPUT_MISSING_OR_INVALID: {0}", name);
        return value;
    }
    private static string HashInput(string name)
    {
        string value = Required(name); if (!Regex.IsMatch(value, "\\A[0-9A-Fa-f]{64}\\z")) Fail("INPUT_HASH_INVALID"); return value.ToUpperInvariant();
    }
    private static bool Same(string a, string b) => String.Equals(a, b, PathComparison);
    private static bool IsInside(string path, string root) => path.StartsWith(root + Path.DirectorySeparatorChar, PathComparison);
    private static string CheckedPath(string value, bool exists)
    {
        if (!Path.IsPathFullyQualified(value) || value.Any(Char.IsControl)) Fail("PATH_INVALID");
        string full = Path.GetFullPath(value).TrimEnd(Path.DirectorySeparatorChar);
        if (OperatingSystem.IsWindows() && (!Regex.IsMatch(full, "\\A[A-Za-z]:\\\\") || full.IndexOf(':', 2) >= 0)) Fail("LOCAL_PATH_REQUIRED");
        if (exists && !File.Exists(full) && !Directory.Exists(full)) Fail("PATH_MISSING");
        for (string? current = full; current != null; current = Path.GetDirectoryName(current))
            if ((File.Exists(current) || Directory.Exists(current)) && (File.GetAttributes(current) & FileAttributes.ReparsePoint) != 0) Fail("REPARSE_PATH_FORBIDDEN");
        return full;
    }
    private static DirectoryInfo Parent(DirectoryInfo child, string name)
    {
        if (!String.Equals(child.Name, name, PathComparison) || child.Parent == null) throw new BuildException("E04A1_YAML_MODULE_ANCESTRY_INVALID");
        return child.Parent;
    }
    private static string SafeRelative(string value)
    {
        if (String.IsNullOrEmpty(value) || value.Contains('\\') || Path.IsPathRooted(value) || value.Any(Char.IsControl)) Fail("RELATIVE_HEADER_PATH_INVALID");
        foreach (string part in value.Split('/'))
            if (part == "" || part == "." || part == ".." || part.IndexOfAny(new[] { ':', '<', '>', '"', '|', '?', '*' }) >= 0
                || part.EndsWith(' ') || part.EndsWith('.') || part.Equals(".git", StringComparison.OrdinalIgnoreCase)) Fail("HEADER_PATH_COMPONENT_INVALID");
        return value;
    }
    private static string Inside(string root, string relative)
    {
        string full = CheckedPath(Path.Combine(root, SafeRelative(relative).Replace('/', Path.DirectorySeparatorChar)), true);
        if (!IsInside(full, root)) Fail("HEADER_PATH_ESCAPE"); return full;
    }
    private static FileStream Hold(string path, long? bytes, string hash)
    {
        path = CheckedPath(path, true);
        FileStream stream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read);
        try
        {
            if ((bytes.HasValue && stream.Length != bytes.Value) || StreamHash(stream) != hash) Fail("FILE_BYTES_OR_HASH_MISMATCH");
            CheckedPath(path, true); ReadLocks.Add(stream); return stream;
        }
        catch { stream.Dispose(); throw; }
    }
    private static FileStream HoldDescriptor(JsonElement value, string expected)
    {
        if (!Same(CheckedPath(Text(value, "path"), true), expected)) Fail("DESCRIPTOR_PATH_MISMATCH");
        return Hold(expected, Integer(value, "bytes"), HashText(value, "sha256"));
    }
    private static string StreamHash(FileStream stream)
    {
        stream.Position = 0; using SHA256 algorithm = SHA256.Create(); string hash = Convert.ToHexString(algorithm.ComputeHash(stream)); stream.Position = 0; return hash;
    }
    private static JsonDocument ReadJson(FileStream stream)
    {
        long length = stream.Length;
        if (length <= 0 || length > 8388608) throw new BuildException("E04A1_YAML_RECEIPT_SIZE_INVALID");
        byte[] bytes = new byte[checked((int)length)];
        stream.Position = 0;
        try
        {
            stream.ReadExactly(bytes, 0, bytes.Length);
            if (stream.ReadByte() != -1 || stream.Length != length) Fail("RECEIPT_LENGTH_CHANGED");
        }
        finally { stream.Position = 0; }
        string json = new System.Text.UTF8Encoding(false, true).GetString(bytes, 0, bytes.Length);
        JsonDocument document = JsonDocument.Parse(json: json,
            options: new JsonDocumentOptions { MaxDepth = 32, CommentHandling = JsonCommentHandling.Disallow, AllowTrailingCommas = false });
        try { CheckDuplicates(document.RootElement); return document; }
        catch { document.Dispose(); throw; }
    }
    private static void CheckDuplicates(JsonElement element)
    {
        if (element.ValueKind == JsonValueKind.Object)
        {
            var keys = new HashSet<string>(StringComparer.Ordinal);
            foreach (JsonProperty p in element.EnumerateObject()) { if (!keys.Add(p.Name)) Fail("DUPLICATE_RECEIPT_KEY"); CheckDuplicates(p.Value); }
        }
        else if (element.ValueKind == JsonValueKind.Array) foreach (JsonElement item in element.EnumerateArray()) CheckDuplicates(item);
    }
    private static JsonElement Get(JsonElement obj, string key)
    {
        if (obj.ValueKind != JsonValueKind.Object || !obj.TryGetProperty(key, out JsonElement value)) throw new BuildException("E04A1_YAML_RECEIPT_FIELD_MISSING: {0}", key);
        return value;
    }
    private static string Text(JsonElement obj, string key)
    {
        JsonElement value = Get(obj, key); if (value.ValueKind != JsonValueKind.String || value.GetString() == null) throw new BuildException("E04A1_YAML_RECEIPT_STRING_INVALID: {0}", key); return value.GetString()!;
    }
    private static JsonElement[] Array(JsonElement obj, string key)
    {
        JsonElement value = Get(obj, key); if (value.ValueKind != JsonValueKind.Array) throw new BuildException("E04A1_YAML_RECEIPT_ARRAY_INVALID: {0}", key); return value.EnumerateArray().ToArray();
    }
    private static long Integer(JsonElement obj, string key)
    {
        JsonElement value = Get(obj, key); if (value.ValueKind != JsonValueKind.Number || !value.TryGetInt64(out long result) || result < 0) throw new BuildException("E04A1_YAML_RECEIPT_INTEGER_INVALID: {0}", key); return result;
    }
    private static bool Boolean(JsonElement obj, string key)
    {
        JsonElement value = Get(obj, key); if (value.ValueKind != JsonValueKind.True && value.ValueKind != JsonValueKind.False) throw new BuildException("E04A1_YAML_RECEIPT_BOOLEAN_INVALID: {0}", key); return value.GetBoolean();
    }
    private static string HashText(JsonElement obj, string key)
    {
        string hash = Text(obj, key); if (!Regex.IsMatch(hash, "\\A[0-9a-fA-F]{64}\\z")) Fail("RECEIPT_HASH_INVALID"); return hash.ToUpperInvariant();
    }
    private static void Eq(JsonElement obj, string key, string expected) { if (Text(obj, key) != expected) throw new BuildException("E04A1_YAML_RECEIPT_IDENTITY_MISMATCH: {0}", key); }
    private static void PathEq(JsonElement obj, string key, string expected) { if (!Same(CheckedPath(Text(obj, key), true), expected)) throw new BuildException("E04A1_YAML_RECEIPT_PATH_MISMATCH: {0}", key); }
    private static void Identity(JsonElement obj, string kind, string run, string head, string source, string project)
    {
        if (Integer(obj, "schemaVersion") != 1) Fail("RECEIPT_SCHEMA_UNSUPPORTED"); Eq(obj, "kind", kind); Eq(obj, "runId", run); Eq(obj, "sourceHead", head); PathEq(obj, "sourceRoot", source); PathEq(obj, "stagedProject", project);
    }
    private static void CheckMembership(string root, HashSet<string> expected)
    {
        var canonical = new HashSet<string>(expected, StringComparer.Ordinal);
        var seen = new HashSet<string>(StringComparer.Ordinal);
        var collisions = new HashSet<string>(expected.Comparer);
        var directories = new Stack<string>(); directories.Push(root);
        while (directories.Count > 0)
            foreach (string entry in Directory.EnumerateFileSystemEntries(directories.Pop()))
            {
                string path = CheckedPath(entry, true); if (!IsInside(path, root)) Fail("HEADER_DIRECTORY_ESCAPE");
                if (Directory.Exists(path)) { directories.Push(path); continue; }
                string relative = Path.GetRelativePath(root, path).Replace(Path.DirectorySeparatorChar, '/');
                if (!collisions.Add(relative) || !seen.Add(relative) || !canonical.Contains(relative)) Fail("UNLISTED_OR_COLLIDING_HEADER");
            }
        if (!seen.SetEquals(canonical)) Fail("HEADER_DIRECTORY_MEMBERSHIP_INCOMPLETE");
    }
    private static void WriteStable(string path, byte[] bytes)
    {
        CheckedPath(path, false);
        if (Directory.Exists(path)) Fail("SELECTION_RECEIPT_IS_DIRECTORY");
        if (File.Exists(path)) { if (!File.ReadAllBytes(path).SequenceEqual(bytes)) Fail("SELECTION_RECEIPT_ALREADY_DIFFERS"); return; }
        using FileStream output = new FileStream(path, FileMode.CreateNew, FileAccess.Write, FileShare.Read); output.Write(bytes); output.Flush(true);
    }
    // Proposed source-only rules provenance boundary. Runtime execution remains gated.
    private object ObserveRules(ReadOnlyTargetRules target, string runId, string sourceHead,
        string sourceRoot, string stagedProject, string runRoot)
    {
        string inputPath = CheckedPath(Path.Combine(runRoot, "logs", "rules-witness-input.json"), true);
        if (!Same(inputPath, CheckedPath(Required("E04A1_RULES_WITNESS_INPUT"), true))) Fail("RULES_INPUT_PATH_MISMATCH");
        FileStream inputLock = Hold(inputPath, null, HashInput("E04A1_RULES_WITNESS_INPUT_SHA256"));
        using JsonDocument input = ReadJson(inputLock);
        JsonElement r = input.RootElement;
        RulesKeys(r, new[] { "schemaVersion", "kind", "runId", "sourceHead", "sourceRoot", "stagedProject", "attemptNonce",
            "expectedWorkingDirectory", "processHost", "ubtAssembly", "buildAssembly", "rulesCacheLockAssembly",
            "rulesCompilerSource", "rulesAssemblySource", "rulesCacheSource", "dynamicCompilationSource",
            "targetSource", "moduleSource", "rulesSourceFiles", "parentAssemblies", "expectedSelectors",
            "prelaunchTopologyReceipt", "finiteDiscoveryRoots", "phase", "freezeManifest", "expectedRuntime" });
        Identity(r, "E04A1_RULES_WITNESS_INPUT", runId, sourceHead, sourceRoot, stagedProject);
        Eq(r, "phase", "EditorBuild");
        JsonElement frozen = Get(r, "freezeManifest");
        object freezeManifest = RulesHeldDescriptor(frozen, CheckedPath(Text(frozen, "path"), true));
        var runtime = new { runtimeFramework = RuntimeInformation.FrameworkDescription, runtimeVersion = Environment.Version.ToString(),
            processArchitecture = RuntimeInformation.ProcessArchitecture.ToString() };
        using JsonDocument runtimeJson = JsonDocument.Parse(json: JsonSerializer.Serialize(runtime));
        RulesEqual(Get(r, "expectedRuntime"), runtimeJson.RootElement);
        string nonce = Required("E04A1_RULES_WITNESS_NONCE");
        if (!Guid.TryParseExact(nonce, "D", out Guid attempt) || attempt == Guid.Empty) Fail("RULES_NONCE_INVALID");
        Eq(r, "attemptNonce", nonce);
        string workingDirectory = CheckedPath(Directory.GetCurrentDirectory(), true);
        PathEq(r, "expectedWorkingDirectory", workingDirectory);
        string processPath = CheckedPath(Environment.ProcessPath ?? throw new BuildException("E04A1_RULES_PROCESS_PATH_MISSING"), true);
        object processHost = RulesHeldDescriptor(Get(r, "processHost"), processPath);
        object ubtAssembly = RulesHeldDescriptor(Get(r, "ubtAssembly"), CheckedPath(typeof(TargetRules).Assembly.Location, true));
        object buildAssembly = RulesHeldDescriptor(Get(r, "buildAssembly"), CheckedPath(typeof(UnrealBuildBase.Rules).Assembly.Location, true));
        string engine = CheckedPath(UnrealBuildBase.Unreal.EngineDirectory.FullName, true);
        object[] sourcePins = new[] {
            RulesHeldDescriptor(Get(r, "rulesCompilerSource"), Path.Combine(engine, "Source", "Programs", "UnrealBuildTool", "Configuration", "Rules", "RulesCompiler.cs")),
            RulesHeldDescriptor(Get(r, "rulesAssemblySource"), Path.Combine(engine, "Source", "Programs", "UnrealBuildTool", "Configuration", "Rules", "RulesAssembly.cs")),
            RulesHeldDescriptor(Get(r, "rulesCacheSource"), Path.Combine(engine, "Source", "Programs", "Shared", "EpicGames.Build", "System", "Rules.cs")),
            RulesHeldDescriptor(Get(r, "dynamicCompilationSource"), Path.Combine(engine, "Source", "Programs", "UnrealBuildTool", "System", "DynamicCompilation.cs")) };
        string topologyPath = CheckedPath(Path.Combine(runRoot, "logs", "rules-prelaunch-topology.json"), true);
        object topologyDescriptor = RulesHeldDescriptor(Get(r, "prelaunchTopologyReceipt"), topologyPath);
        FileStream topologyLock = ReadLocks.Last();
        using JsonDocument topology = ReadJson(topologyLock);
        JsonElement t = topology.RootElement;
        RulesKeys(t, new[] { "schemaVersion", "kind", "runId", "sourceHead", "sourceRoot", "stagedProject", "attemptNonce",
            "freshProjectDirectory", "projectBuildRulesAbsent", "projectIntermediateSourceAbsent", "sourceMembershipLockedBeforeLaunch", "rulesSourceFiles", "phase", "freezeManifest", "optionalDiscoveryAbsences" });
        Identity(t, "E04A1_RULES_PRELAUNCH_TOPOLOGY", runId, sourceHead, sourceRoot, stagedProject);
        Eq(t, "phase", "EditorBuild"); RulesEqual(Get(t, "freezeManifest"), frozen);
        Eq(t, "attemptNonce", nonce);
        foreach (string key in new[] { "freshProjectDirectory", "projectBuildRulesAbsent", "projectIntermediateSourceAbsent", "sourceMembershipLockedBeforeLaunch" })
            if (!Boolean(t, key)) Fail("RULES_PRELAUNCH_TOPOLOGY_REQUIRED");
        RulesEqual(Get(t, "rulesSourceFiles"), Get(r, "rulesSourceFiles"));
        string topologyProjectRoot = CheckedPath(Path.GetDirectoryName(stagedProject)!, true);
        string[] optionalAbsences = RulesStrings(Get(t, "optionalDiscoveryAbsences"));
        string[] expectedAbsences = new[] {
            Path.Combine(topologyProjectRoot, "Tests"), Path.Combine(topologyProjectRoot, "Mods"),
            Path.Combine(topologyProjectRoot, "Platforms"), Path.Combine(topologyProjectRoot, "Restricted"),
            Path.Combine(topologyProjectRoot, "Intermediate", "Source"),
            Path.Combine(topologyProjectRoot, "Plugins", "E04ProfileProof", "Tests"),
            Path.Combine(topologyProjectRoot, "Plugins", "E04ProfileProof", "Platforms"),
            Path.Combine(topologyProjectRoot, "Plugins", "E04ProfileProof", "Restricted") };
        if (!optionalAbsences.SequenceEqual(expectedAbsences, StringComparer.Ordinal)) Fail("RULES_OPTIONAL_ABSENCE_POLICY_MISMATCH");
        foreach (string path in optionalAbsences) RulesRequireAbsent(path);


        var observation = target.AdditionalData as E04RulesObservation
            ?? throw new BuildException("E04A1_RULES_ADDITIONAL_DATA_WITNESS_MISSING");
        Dictionary<string, object?> selectors = observation.CaptureSelectors(target);
        using JsonDocument actualSelectors = JsonDocument.Parse(json: JsonSerializer.Serialize(selectors));
        RulesEqual(Get(r, "expectedSelectors"), actualSelectors.RootElement);
        System.Type targetType = observation.SelectedType;
        System.Type moduleType = GetType();
        if (moduleType != typeof(YamlCpp) || targetType.Assembly != moduleType.Assembly) Fail("RULES_MODULE_TYPE_OR_ASSEMBLY_MISMATCH");
        var loaded = targetType.Assembly;
        string projectRoot = CheckedPath(Path.GetDirectoryName(stagedProject)!, true);
        string expectedAssemblyPath = CheckedPath(Path.Combine(projectRoot, "Intermediate", "Build", "BuildRules",
            Path.GetFileNameWithoutExtension(stagedProject) + "ModuleRules.dll"), true);
        if (loaded.IsDynamic || loaded.ManifestModule.ModuleVersionId == Guid.Empty
            || !Same(CheckedPath(loaded.Location, true), expectedAssemblyPath)) Fail("RULES_LOADED_ASSEMBLY_OUTSIDE_FINITE_PROOF");
        object dll = RulesObservedDescriptor(expectedAssemblyPath);
        object pdb = RulesObservedDescriptor(Path.ChangeExtension(expectedAssemblyPath, ".pdb"));
        string manifestPath = CheckedPath(Path.Combine(Path.GetDirectoryName(expectedAssemblyPath)!,
            Path.GetFileNameWithoutExtension(expectedAssemblyPath) + "Manifest.json"), true);
        object manifestDescriptor = RulesObservedDescriptor(manifestPath);
        FileStream manifestLock = ReadLocks.Last();
        using JsonDocument manifest = ReadJson(manifestLock);
        RulesKeys(manifest.RootElement, new[] { "SourceFiles", "EngineVersion" });
        string[] manifestSources = RulesStrings(Get(manifest.RootElement, "SourceFiles"));
        string engineVersion = Text(manifest.RootElement, "EngineVersion");
        if (String.IsNullOrWhiteSpace(engineVersion)) Fail("RULES_MANIFEST_ENGINE_VERSION_EMPTY");
        object projectCache = E04CompletedProjectRules(targetType, moduleType, stagedProject, expectedAssemblyPath);
        using JsonDocument cache = JsonDocument.Parse(json: JsonSerializer.Serialize(projectCache));
        JsonElement c = cache.RootElement;
        string[] actualSources = RulesStrings(Get(c, "actualAssemblySourceFilesSequence"));
        if (!manifestSources.SequenceEqual(actualSources, StringComparer.Ordinal)) Fail("RULES_MANIFEST_SOURCE_SEQUENCE_MISMATCH");
        var expectedSources = new Dictionary<string, JsonElement>(PathComparison == StringComparison.OrdinalIgnoreCase ? StringComparer.OrdinalIgnoreCase : StringComparer.Ordinal);
        foreach (JsonElement descriptor in Array(r, "rulesSourceFiles"))
        {
            string path = CheckedPath(Text(descriptor, "path"), true);
            if (!IsInside(path, projectRoot) || !expectedSources.TryAdd(path, descriptor)) Fail("RULES_FROZEN_SOURCE_OUTSIDE_PROJECT_OR_DUPLICATE");
        }
        if (expectedSources.Count == 0 || expectedSources.Count > 8192 || actualSources.Length != expectedSources.Count) Fail("RULES_SOURCE_MEMBERSHIP_COUNT");
        var seen = new HashSet<string>(expectedSources.Comparer);
        var sourceDescriptors = new List<object>();
        foreach (string rawPath in actualSources)
        {
            string path = CheckedPath(rawPath, true);
            if (!seen.Add(path)) Fail("RULES_DUPLICATE_SOURCE");
            if (!expectedSources.TryGetValue(path, out JsonElement expected)) Fail("RULES_UNFROZEN_SOURCE");
            sourceDescriptors.Add(RulesHeldDescriptor(expected, path));
        }
        string targetSource = CheckedPath(Text(c, "selectedTypeSource"), true);
        string moduleSource = CheckedPath(Text(c, "selectedModuleTypeSource"), true);
        string expectedTargetSource = CheckedPath(Path.Combine(projectRoot, "Source", "WarhammerClientE04AEditor.Target.cs"), true);
        string expectedModuleSource = CheckedPath(Path.Combine(projectRoot, "Plugins", "E04ProfileProof", "Source", "ThirdParty", "YamlCpp", "YamlCpp.Build.cs"), true);
        if (!Same(targetSource, expectedTargetSource) || !Same(moduleSource, expectedModuleSource)
            || !seen.Contains(targetSource) || !seen.Contains(moduleSource)) Fail("RULES_SELECTED_SOURCE_MAPPING_MISMATCH");
        object targetDescriptor = RulesHeldDescriptor(Get(r, "targetSource"), targetSource);
        object moduleDescriptor = RulesHeldDescriptor(Get(r, "moduleSource"), moduleSource);
        JsonElement[] parentFacts = Array(c, "parentChain");
        JsonElement[] expectedParents = Array(r, "parentAssemblies");
        if (parentFacts.Length == 0 || parentFacts.Length != expectedParents.Length) Fail("RULES_PARENT_CHAIN_COUNT");
        var parents = new List<object>();
        for (int i = 0; i < parentFacts.Length; ++i)
        {
            if (!Boolean(parentFacts[i], "hasCompiledAssembly")) Fail("RULES_PARENT_WITHOUT_COMPILED_ASSEMBLY_UNSUPPORTED");
            JsonElement identity = Get(parentFacts[i], "identity");
            string path = CheckedPath(Text(identity, "path"), true);
            string mvid = Text(identity, "mvid");
            if (!Guid.TryParseExact(mvid, "D", out Guid parentMvid) || parentMvid == Guid.Empty) Fail("RULES_PARENT_MVID_INVALID");
            parents.Add(new { level = i, simpleName = Text(identity, "simpleName"), fullName = Text(identity, "fullName"), assemblyDescriptor = RulesHeldDescriptor(expectedParents[i], path), loadedMvid = mvid });
        }
        string[] finiteRoots = RulesStrings(Get(r, "finiteDiscoveryRoots"));
        string[] exactRoots = new[] {
            CheckedPath(Path.Combine(projectRoot, "Source"), true),
            CheckedPath(Path.Combine(projectRoot, "Plugins", "E04ProfileProof", "Source"), true) };
        if (!finiteRoots.SequenceEqual(exactRoots, StringComparer.Ordinal)) Fail("RULES_FINITE_DISCOVERY_ROOTS_MISMATCH");
        object lockAssembly = RulesLockAssemblyDescriptor(Get(r, "rulesCacheLockAssembly"));
        // Only these two required existing source roots receive cache/scanned obligations.
        // Optional absent roots are wrapper topology policy, not cache observations.
        object tree = E04RulesTreePoststate(finiteRoots);
        using JsonDocument treeJson = JsonDocument.Parse(json: JsonSerializer.Serialize(tree));
        var treeSources = new HashSet<string>(expectedSources.Comparer);
        foreach (JsonElement root in Array(treeJson.RootElement, "selectedRoots"))
        {
            if (!Boolean(root, "cacheNodePresent") || !Boolean(Get(root, "node"), "isScanned")) Fail("RULES_REQUIRED_CACHE_ROOT_MISSING_OR_UNSCANNED");
            RulesCollectTreeSources(Get(root, "node"), treeSources);
        }
        if (!treeSources.SetEquals(seen)) Fail("RULES_CACHE_SOURCE_MEMBERSHIP_MISMATCH");
        using var process = System.Diagnostics.Process.GetCurrentProcess();
        DateTime startUtc = process.StartTime.ToUniversalTime();
        byte[] bytes = JsonSerializer.SerializeToUtf8Bytes(new {
            schemaVersion = 1, kind = "E04A1_RULES_RUNTIME_WITNESS", runId, sourceHead, sourceRoot, stagedProject, attemptNonce = nonce,
            phase = "EditorBuild", freezeManifest,
            inputContract = RulesDescriptor(inputPath, inputLock), prelaunchTopologyReceipt = topologyDescriptor,
            process = new { pid = Environment.ProcessId, startTimeUtc = startUtc.ToString("O", CultureInfo.InvariantCulture),
                startFileTimeUtc = startUtc.ToFileTimeUtc(), processPath, workingDirectory,
                actualArgv = Environment.GetCommandLineArgs(), runtimeFramework = RuntimeInformation.FrameworkDescription,
                runtimeVersion = Environment.Version.ToString(), processArchitecture = RuntimeInformation.ProcessArchitecture.ToString(),
                hostDescriptor = processHost, ubtAssemblyDescriptor = ubtAssembly, buildAssemblyDescriptor = buildAssembly,
                rulesCacheLockAssemblyDescriptor = lockAssembly },
            selectedTarget = new { exactClrType = targetType.FullName, assemblyQualifiedName = targetType.AssemblyQualifiedName,
                sourceDescriptor = targetDescriptor, assemblyDescriptor = dll, loadedMvid = loaded.ManifestModule.ModuleVersionId.ToString("D"),
                constructorInstanceId = observation.InstanceId, constructorBuildAllModules = observation.ConstructorBuildAllModules },
            module = new { actualClrType = moduleType.FullName, sourceDescriptor = moduleDescriptor, sameAssemblyReference = true },
            effectiveSelectors = selectors, actualProjectRules = projectCache,
            generatedRules = new { dll, pdb, manifest = manifestDescriptor, engineVersion,
                orderedManifestSourceFiles = manifestSources, manifestSequenceEqualsAssemblySourceFiles = true },
            orderedAssemblySourceFileDescriptors = sourceDescriptors.ToArray(), parentAssemblyChain = parents.ToArray(),
            discoveryCache = tree, pinnedEngineSources = sourcePins,
            moduleTimeOptionalDiscoveryAbsences = optionalAbsences,
            observationStage = "MODULE_CONSTRUCTOR_AFTER_CREATE_TARGET_RULES_VALIDATION",
            lineageQualification = new {
                freshProcessInference = "CONDITIONAL_SOURCE_SUPPORTED_FROM_ROOT_OWNED_PROCESS_AND_PREABSENCE",
                cacheObservation = "POSTSTATE_ONLY", manifestOrder = "DIRECT_MANIFEST_ARRAY_ORDER",
                assemblySourceOrder = "DIRECT_CURRENT_ENUMERATION_ORDER",
                roslynOrder = "SOURCE_DERIVED_FILEPATH_SORT_NOT_DIRECT_EVENT_TRACE",
                chronologicalScanEventsObserved = false, nativeFlagsObserved = false, pluginActivationObserved = false },
            fileReadLocksHeldThroughUbtExit = true,
            scope = "CONSTRUCTOR_SELECTION_AND_RULES_CACHE_POSTSTATE_NOT_NATIVE_FLAGS_OR_ACTIVATION_CERTIFICATION" });
        string witnessPath = CheckedPath(Path.Combine(runRoot, "logs", "rules-runtime-witness.json"), false);
        // Repeated construction is supported only when this exact witness is byte-identical.
        // Changed target instance/cache order/poststate is unsupported: WriteStable fails; never overwrite.
        WriteStable(witnessPath, bytes);
        return RulesObservedDescriptor(witnessPath);
    }

    private static void RulesRequireAbsent(string path)
    {
        path = CheckedPath(path, false);
        try { File.GetAttributes(path); Fail("RULES_OPTIONAL_DISCOVERY_PATH_EXISTS"); }
        catch (FileNotFoundException) { }
        catch (DirectoryNotFoundException) { }
        // Any access/IO error is unsupported and propagates; it is never absence.
    }
    private static object RulesDescriptor(string path, FileStream stream)
        => new { path = CheckedPath(path, true), bytes = stream.Length, sha256 = StreamHash(stream) };
    private static object RulesHeldDescriptor(JsonElement expected, string path)
    {
        path = CheckedPath(path, true);
        RulesKeys(expected, new[] { "path", "bytes", "sha256" });
        return RulesDescriptor(path, HoldDescriptor(expected, path));
    }
    private static object RulesObservedDescriptor(string path)
    {
        path = CheckedPath(path, true);
        FileStream stream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read);
        try { if (stream.Length == 0) Fail("RULES_OBSERVED_FILE_EMPTY"); CheckedPath(path, true); ReadLocks.Add(stream); return RulesDescriptor(path, stream); }
        catch { stream.Dispose(); throw; }
    }
    private static void RulesKeys(JsonElement value, string[] expected)
    {
        if (value.ValueKind != JsonValueKind.Object) Fail("RULES_OBJECT_REQUIRED");
        string[] actual = value.EnumerateObject().Select(p => p.Name).ToArray();
        if (actual.Length != expected.Length || !new HashSet<string>(actual, StringComparer.Ordinal).SetEquals(expected)) Fail("RULES_OBJECT_FIELDS_MISMATCH");
    }
    private static string[] RulesStrings(JsonElement value)
    {
        if (value.ValueKind != JsonValueKind.Array) Fail("RULES_STRING_ARRAY_REQUIRED");
        return value.EnumerateArray().Select(e => e.ValueKind == JsonValueKind.String ? e.GetString()!
            : throw new BuildException("E04A1_RULES_STRING_MEMBER_REQUIRED")).ToArray();
    }
    private static void RulesEqual(JsonElement expected, JsonElement actual)
    {
        if (expected.ValueKind != actual.ValueKind) Fail("RULES_EXPECTED_JSON_TYPE_MISMATCH");
        if (expected.ValueKind == JsonValueKind.Object)
        {
            var a = actual.EnumerateObject().ToDictionary(p => p.Name, p => p.Value, StringComparer.Ordinal);
            var e = expected.EnumerateObject().ToArray();
            if (a.Count != e.Length) Fail("RULES_EXPECTED_JSON_FIELDS_MISMATCH");
            foreach (JsonProperty p in e) { if (!a.TryGetValue(p.Name, out JsonElement v)) Fail("RULES_EXPECTED_JSON_FIELD_ABSENT"); RulesEqual(p.Value, v); }
        }
        else if (expected.ValueKind == JsonValueKind.Array)
        {
            var e = expected.EnumerateArray().ToArray(); var a = actual.EnumerateArray().ToArray();
            if (e.Length != a.Length) Fail("RULES_EXPECTED_JSON_ARRAY_LENGTH");
            for (int i = 0; i < e.Length; ++i) RulesEqual(e[i], a[i]);
        }
        else if (expected.ValueKind == JsonValueKind.String)
        { if (expected.GetString() != actual.GetString()) Fail("RULES_EXPECTED_JSON_STRING"); }
        else if (expected.GetRawText() != actual.GetRawText()) Fail("RULES_EXPECTED_JSON_SCALAR");
    }
    private static void RulesCollectTreeSources(JsonElement node, HashSet<string> result)
    {
        JsonElement lists = Get(node, "listsInActualOrder");
        if (Boolean(node, "hasFilesContainer"))
            foreach (string name in new[] { "ModuleRules", "TargetRules" })
                foreach (string path in RulesStrings(Get(lists, name)))
                    if (!result.Add(CheckedPath(path, true))) Fail("RULES_CACHE_DUPLICATE_SOURCE");
        foreach (JsonElement child in Array(node, "childrenInActualOrder")) RulesCollectTreeSources(Get(child, "node"), result);
    }
    private static object RulesLockAssemblyDescriptor(JsonElement expected)
    {
        var field = E04LockField();
        return RulesHeldDescriptor(expected, CheckedPath(field.FieldType.Assembly.Location, true));
    }
    private static System.Reflection.FieldInfo E04LockField()
    {
        System.Type owner = typeof(UnrealBuildBase.Rules);
        var field = owner.GetField("RootLock", System.Reflection.BindingFlags.NonPublic
            | System.Reflection.BindingFlags.Static | System.Reflection.BindingFlags.DeclaredOnly);
        if (field == null || field.DeclaringType != owner || !field.IsStatic || field.IsInitOnly
            || field.FieldType.FullName != "System.Threading.ReaderWriterLockSlim") Fail("RULES_LOCK_FIELD_SHAPE_UNSUPPORTED");
        return field!;
    }

private static System.Reflection.FieldInfo E04Field(
    System.Type owner, string name, System.Type expectedType, bool isStatic, bool isReadOnly)
{
    var flags = System.Reflection.BindingFlags.DeclaredOnly
        | System.Reflection.BindingFlags.NonPublic
        | (isStatic ? System.Reflection.BindingFlags.Static : System.Reflection.BindingFlags.Instance);
    var field = owner.GetField(name, flags);
    if (field == null || field.DeclaringType != owner || field.FieldType != expectedType
        || field.IsStatic != isStatic || field.IsInitOnly != isReadOnly)
        throw new BuildException("E04A1_RULES_PRIVATE_SHAPE_UNSUPPORTED: {0}.{1}", owner.FullName, name);
    return field;
}

private static object E04RequiredField(System.Reflection.FieldInfo field, object? instance)
    => field.GetValue(instance) ?? throw new BuildException("E04A1_RULES_PRIVATE_VALUE_MISSING: {0}", field.Name);

private static object E04AssemblyIdentity(System.Reflection.Assembly assembly)
{
    if (assembly.IsDynamic || String.IsNullOrWhiteSpace(assembly.Location) || assembly.FullName == null)
        throw new BuildException("E04A1_RULES_ASSEMBLY_NOT_FILE_BACKED");
    return new { simpleName = assembly.GetName().Name, fullName = assembly.FullName, path = assembly.Location,
        mvid = assembly.ManifestModule.ModuleVersionId.ToString("D") };
}

private static object E04CompletedProjectRules(System.Type actualTargetType, System.Type actualModuleType, string exactProjectPath,
    string expectedProjectAssemblyPath)
{
    var mapType = typeof(System.Collections.Concurrent.ConcurrentDictionary<
        EpicGames.Core.FileReference, System.Lazy<RulesAssembly>>);
    var mapField = E04Field(typeof(RulesCompiler), "LoadedAssemblyMap", mapType, true, true);
    var map = (System.Collections.Concurrent.ConcurrentDictionary<
        EpicGames.Core.FileReference, System.Lazy<RulesAssembly>>)E04RequiredField(mapField, null);
    var entries = map.ToArray();
    if (entries.Length > 128) throw new BuildException("E04A1_RULES_CACHE_ENTRY_CAP");
    var selected = entries.Where(e => String.Equals(e.Key.FullName, exactProjectPath,
        OperatingSystem.IsWindows() ? StringComparison.OrdinalIgnoreCase : StringComparison.Ordinal)).ToArray();
    if (selected.Length != 1 || !selected[0].Value.IsValueCreated)
        throw new BuildException("E04A1_RULES_PROJECT_CACHE_MISSING_AMBIGUOUS_OR_UNCREATED");
    // This Value is already completed. Never read Value for any uncreated Lazy.
    RulesAssembly project = selected[0].Value.Value;
    var assemblyField = E04Field(typeof(RulesAssembly), "CompiledAssembly",
        typeof(System.Reflection.Assembly), false, true);
    var compiled = (System.Reflection.Assembly)E04RequiredField(assemblyField, project);
    if (!Object.ReferenceEquals(compiled, actualTargetType.Assembly)
        || !String.Equals(compiled.Location, expectedProjectAssemblyPath,
            OperatingSystem.IsWindows() ? StringComparison.OrdinalIgnoreCase : StringComparison.Ordinal))
        throw new BuildException("E04A1_RULES_SELECTED_ASSEMBLY_OBJECT_OR_PATH_MISMATCH");
    // Compiler-level GetFileNameFromType reads all map Lazy.Value entries and can
    // force another project. Query this already completed assembly directly.
    if (!project.TryGetFileNameFromType(actualTargetType, out EpicGames.Core.FileReference? selectedFile)
        || selectedFile == null)
        throw new BuildException("E04A1_RULES_SELECTED_TYPE_SOURCE_MISSING");
    string selectedSource = selectedFile.FullName;
    if (!project.TryGetFileNameFromType(actualModuleType, out EpicGames.Core.FileReference? moduleFile)
        || moduleFile == null || actualModuleType.Assembly != compiled)
        throw new BuildException("E04A1_RULES_SELECTED_MODULE_SOURCE_OR_ASSEMBLY_MISMATCH");
    string selectedModuleSource = moduleFile.FullName;
    var sources = project.AssemblySourceFiles?.Select(f => f.FullName).ToArray()
        ?? throw new BuildException("E04A1_RULES_PROJECT_SOURCE_ENUMERATION_MISSING");
    if (sources.Length == 0 || sources.Length > 8192)
        throw new BuildException("E04A1_RULES_PROJECT_SOURCE_ENUMERATION_CAP");
    var mapFieldType = typeof(System.Collections.Generic.IReadOnlyDictionary<string, EpicGames.Core.FileReference>);
    var targetField = E04Field(typeof(RulesAssembly), "TargetNameToTargetFile", mapFieldType, false, true);
    var moduleField = E04Field(typeof(RulesAssembly), "ModuleNameToModuleFile", mapFieldType, false, true);
    var targetMap = (System.Collections.Generic.IReadOnlyDictionary<string, EpicGames.Core.FileReference>)
        E04RequiredField(targetField, project);
    var moduleMap = (System.Collections.Generic.IReadOnlyDictionary<string, EpicGames.Core.FileReference>)
        E04RequiredField(moduleField, project);
    if (targetMap.Count > 8192 || moduleMap.Count > 8192)
        throw new BuildException("E04A1_RULES_NAME_MAP_CAP");
    var parents = new System.Collections.Generic.List<object>();
    var seen = new System.Collections.Generic.HashSet<RulesAssembly>();
    for (RulesAssembly? parent = project.Parent; parent != null; parent = parent.Parent)
    {
        if (!seen.Add(parent) || parents.Count >= 32)
            throw new BuildException("E04A1_RULES_PARENT_CYCLE_OR_CAP");
        var parentAssembly = (System.Reflection.Assembly?)assemblyField.GetValue(parent);
        parents.Add(new { index = parents.Count, hasCompiledAssembly = parentAssembly != null,
            identity = parentAssembly == null ? null : E04AssemblyIdentity(parentAssembly) });
    }
    // Preserve actual sequences. Do not sort maps/source arrays into one inferred order.
    // Other cache keys are metadata only: do not force their Lazy values.
    return new {
        kind = "E04A1_COMPLETED_PROJECT_RULES_CACHE_POSTSTATE",
        exactProjectPath, expectedProjectAssemblyPath,
        selectedProjectLazyWasValueCreated = true,
        selectedType = actualTargetType.AssemblyQualifiedName,
        selectedTypeSource = selectedSource,
        selectedModuleType = actualModuleType.AssemblyQualifiedName, selectedModuleTypeSource = selectedModuleSource,
        selectedAssembly = E04AssemblyIdentity(compiled),
        selectedAssemblyObjectEqualsActualTargetAssembly = true,
        actualAssemblySourceFilesSequence = sources,
        actualPreprocessorDefines = project.PreprocessorDefines?.ToArray()
            ?? throw new BuildException("E04A1_RULES_PREPROCESSOR_ENUMERATION_MISSING"),
        targetNameMapSequence = targetMap.Select(e => new { name = e.Key, path = e.Value.FullName }).ToArray(),
        moduleNameMapSequence = moduleMap.Select(e => new { name = e.Key, path = e.Value.FullName }).ToArray(),
        parentChain = parents.ToArray(),
        loadedProjectCacheEntryMetadata = entries.Select(e => new {
            project = e.Key.FullName, isValueCreated = e.Value.IsValueCreated }).ToArray(),
        scope = "SAME_PROCESS_COMPLETED_CACHE_AND_LOADED_ASSEMBLY_NOT_SCAN_CHRONOLOGY"
    };
}

private static object E04RulesTreePoststate(string[] finiteAbsoluteRoots)
{
    if (finiteAbsoluteRoots.Length == 0 || finiteAbsoluteRoots.Length > 128)
        throw new BuildException("E04A1_RULES_TREE_ROOT_CAP");
    System.Type owner = typeof(UnrealBuildBase.Rules);
    System.Type node = owner.GetNestedType("Directory", System.Reflection.BindingFlags.NonPublic)
        ?? throw new BuildException("E04A1_RULES_DIRECTORY_TYPE_UNSUPPORTED");
    System.Type files = owner.GetNestedType("Files", System.Reflection.BindingFlags.NonPublic)
        ?? throw new BuildException("E04A1_RULES_FILES_TYPE_UNSUPPORTED");
    var rootField = E04Field(owner, "Root", node, true, false);
    var lockField = E04LockField();
    var dirsType = typeof(System.Collections.Generic.Dictionary<,>).MakeGenericType(typeof(string), node);
    // Directory's fields are internal. E04Field's NonPublic flag covers them.
    var dirsField = E04Field(node, "SubDirectories", dirsType, false, false);
    var filesField = E04Field(node, "Files", files, false, false);
    var scannedField = E04Field(node, "IsScanned", typeof(bool), false, false);
    // Files' four list fields are public on a private nested class.
    var fileLists = new System.Collections.Generic.Dictionary<string, System.Reflection.FieldInfo>();
    foreach (string name in new[] { "ModuleRules", "TargetRules", "AutomationModules", "UbtPlugins" })
    {
        var field = files.GetField(name, System.Reflection.BindingFlags.Public
            | System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.DeclaredOnly);
        if (field == null || field.DeclaringType != files || field.IsStatic || field.IsInitOnly
            || field.FieldType != typeof(System.Collections.Generic.List<EpicGames.Core.FileReference>))
            throw new BuildException("E04A1_RULES_FILES_LIST_SHAPE_UNSUPPORTED: {0}", name);
        fileLists.Add(name, field);
    }
    object rootLock = E04RequiredField(lockField, null);
    System.Type lockType = lockField.FieldType;
    var methodFlags = System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.DeclaredOnly;
    var enter = lockType.GetMethod("TryEnterReadLock", methodFlags, null, new[] { typeof(int) }, null);
    var exit = lockType.GetMethod("ExitReadLock", methodFlags, null, System.Type.EmptyTypes, null);
    if (rootLock.GetType() != lockType || enter == null || exit == null
        || enter.DeclaringType != lockType || exit.DeclaringType != lockType
        || enter.IsStatic || exit.IsStatic || enter.IsGenericMethod || exit.IsGenericMethod
        || enter.ReturnType != typeof(bool) || exit.ReturnType != typeof(void))
        throw new BuildException("E04A1_RULES_TREE_LOCK_METHOD_SHAPE_UNSUPPORTED");
    if (!(bool)(enter.Invoke(rootLock, new object[] { 2000 })
        ?? throw new BuildException("E04A1_RULES_TREE_LOCK_RESULT_MISSING")))
        throw new BuildException("E04A1_RULES_TREE_LOCK_UNAVAILABLE");
    try
    {
        object root = E04RequiredField(rootField, null);
        int nodes = 0, members = 0;
        object Copy(object value, int depth)
        {
            if (value.GetType() != node || depth > 64 || ++nodes > 4096)
                throw new BuildException("E04A1_RULES_TREE_NODE_SHAPE_OR_CAP");
            var listValues = new System.Collections.Generic.Dictionary<string, string[]>();
            object? fileValue = filesField.GetValue(value);
            if (fileValue != null)
            {
                if (fileValue.GetType() != files) throw new BuildException("E04A1_RULES_FILES_VALUE_SHAPE");
                foreach (var pair in fileLists)
                {
                    var list = (System.Collections.Generic.List<EpicGames.Core.FileReference>)
                        E04RequiredField(pair.Value, fileValue);
                    members += list.Count;
                    if (members > 65536) throw new BuildException("E04A1_RULES_TREE_MEMBER_CAP");
                    listValues.Add(pair.Key, list.Select(f => f.FullName).ToArray());
                }
            }
            var children = new System.Collections.Generic.List<object>();
            var childValue = (System.Collections.IDictionary?)dirsField.GetValue(value);
            if (childValue != null)
                foreach (System.Collections.DictionaryEntry pair in childValue)
                    children.Add(new { name = (string)pair.Key,
                        node = Copy(pair.Value ?? throw new BuildException("E04A1_RULES_NULL_CHILD"), depth + 1) });
            return new { isScanned = (bool)E04RequiredField(scannedField, value),
                hasFilesContainer = fileValue != null, listsInActualOrder = listValues,
                hasSubdirectoryContainer = childValue != null, childrenInActualOrder = children.ToArray() };
        }
        var selected = new System.Collections.Generic.List<object>();
        foreach (string path in finiteAbsoluteRoots)
        {
            if (!System.IO.Path.IsPathFullyQualified(path)
                || !String.Equals(System.IO.Path.GetFullPath(path), path, StringComparison.Ordinal))
                throw new BuildException("E04A1_RULES_TREE_ROOT_NOT_CANONICAL");
            object? current = root;
            // Match Rules.FindDirectory's exact split, including drive component.
            foreach (string component in path.Split(System.IO.Path.DirectorySeparatorChar))
            {
                if (current == null) break;
                var children = (System.Collections.IDictionary?)dirsField.GetValue(current);
                if (children == null || !children.Contains(component)) { current = null; break; }
                current = children[component];
            }
            selected.Add(new { path, cacheNodePresent = current != null,
                node = current == null ? null : Copy(current, 0) });
        }
        return new { kind = "E04A1_FINITE_RULES_TREE_POSTSTATE", selectedRoots = selected.ToArray(),
            nodesCopied = nodes, fileMembersCopied = members,
            scope = "READ_LOCKED_MATERIALIZED_POSTSTATE_NO_POPULATE_NO_INVALIDATE_NO_CHRONOLOGY" };
    }
    finally { exit.Invoke(rootLock, null); }
}



}
