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
                fileReadLocksHeldThroughUbtExit = true,
                scope = "CONSTRUCTOR_SELECTION_AND_BYTES_ONLY_NOT_NATIVE_FLAGS_OR_ARTIFACT_LINEAGE_CERTIFICATION"
            });
            WriteStable(selectionPath, selection);
            PublicDefinitions.Add("YAML_CPP_STATIC_DEFINE");
            PublicSystemIncludePaths.Add(includeRoot);
            PublicAdditionalLibraries.Add(libraryPath);
        }
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
        if (stream.Length <= 0 || stream.Length > 8388608) throw new BuildException("E04A1_YAML_RECEIPT_SIZE_INVALID");
        stream.Position = 0;
        JsonDocument document = JsonDocument.Parse(stream, new JsonDocumentOptions { MaxDepth = 32, CommentHandling = JsonCommentHandling.Disallow, AllowTrailingCommas = false });
        CheckDuplicates(document.RootElement); stream.Position = 0; return document;
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
}
