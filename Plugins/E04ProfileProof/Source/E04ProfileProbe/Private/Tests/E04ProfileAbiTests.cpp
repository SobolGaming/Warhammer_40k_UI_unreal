#include "E04ProfileFormat.h"

#include "Containers/StringConv.h"
#include "Dom/JsonObject.h"
#include "Dom/JsonValue.h"
#include "HAL/FileManager.h"
#include "Misc/AutomationTest.h"
#include "Misc/FileHelper.h"
#include "Misc/Paths.h"
#include "Misc/SecureHash.h"
#include "Modules/ModuleManager.h"
#include "Serialization/JsonReader.h"
#include "Serialization/JsonSerializer.h"
#include "Serialization/JsonWriter.h"
#include <type_traits>

#if !WITH_EDITOR
#error E04-A1E is an Editor module proof; the required A1G runtime caller is separate.
#endif
#if !defined(_CPPUNWIND) && !defined(__EXCEPTIONS) && !defined(__cpp_exceptions)
#error E04-A1E must observe the actual exception-enabled Editor environment.
#endif
#if PLATFORM_EXCEPTIONS_DISABLED != 0
#error E04-A1E expects the actual Editor platform exception definition.
#endif

#if WITH_DEV_AUTOMATION_TESTS
namespace
{
using namespace Warhammer::E04A1;
static_assert(std::is_same_v<decltype(&ParseDocument), FParseResult (*)(TConstArrayView<uint8>, EFormat) noexcept>, "Public boundary must be noexcept");
constexpr EAutomationTestFlags Flags = EAutomationTestFlags_ApplicationContextMask | EAutomationTestFlags::EngineFilter;
constexpr bool CallerExceptionsEnabled = true; // Enforced by compiler guards above.
constexpr int32 CallerPlatformExceptionsDisabled = PLATFORM_EXCEPTIONS_DISABLED;

const TCHAR* CodeName(EParseCode Code)
{
    switch (Code)
    {
#define E04_CODE(Name) case EParseCode::Name: return TEXT(#Name)
    E04_CODE(Success); E04_CODE(UnsupportedFormat); E04_CODE(InputTooLarge);
    E04_CODE(NoDocument); E04_CODE(MultipleDocuments); E04_CODE(NullPropertiesUnavailable);
    E04_CODE(UnsupportedTag); E04_CODE(DepthLimit); E04_CODE(NodeLimit);
    E04_CODE(AliasLimit); E04_CODE(ScalarLimit); E04_CODE(MalformedYaml); E04_CODE(InvalidEventStream);
#undef E04_CODE
    }
    return TEXT("INVALID_ENUM");
}

TArray<uint8> Utf8(const FString& Text)
{
    // The conversion treats its final zero as a terminator. Include FString's
    // OWN terminator so an intentional final data NUL remains in Length().
    const FTCHARToUTF8 Encoded(*Text, Text.Len() + 1);
    TArray<uint8> Bytes;
    Bytes.Append(reinterpret_cast<const uint8*>(Encoded.Get()), Encoded.Length());
    return Bytes;
}

bool BytesEqual(const TArray<uint8>& Bytes, const FString& Text) { return Bytes == Utf8(Text); }
FString Sha1(const TArray<uint8>& Bytes)
{
    uint8 Digest[20];
    FSHA1::HashBuffer(Bytes.GetData(), static_cast<uint64>(Bytes.Num()), Digest);
    return BytesToHex(Digest, UE_ARRAY_COUNT(Digest));
}

struct FGeneratedSpec
{
    const TCHAR* Id;
    const TCHAR* Kind;
    int32 Count;
    const TCHAR* Literal;
    EParseCode Code;
    int32 LiteralCharacters = INDEX_NONE;
};

// Counts and literals are independent authored expectations, not parser output.
const FGeneratedSpec Generated[] = {
    {TEXT("A1-K01"), TEXT("LiteralUtf8"), 0, TEXT("A: {Value: upper, value: lower}\na: {\u043a\u043b\u044e\u0447: one, \u041a\u043b\u044e\u0447: two}\n"), EParseCode::Success},
    {TEXT("A1-K02"), TEXT("LiteralUtf8"), 0, TEXT("a: first\na: second\n"), EParseCode::Success},
    {TEXT("A1-K03"), TEXT("LiteralUtf8"), 0, TEXT("[&a [x], *a, &a y, *a]\n"), EParseCode::Success},
    {TEXT("A1-K04"), TEXT("LiteralUtf8"), 0, TEXT("plain: yes\nquoted: \"yes\"\nexplicit: !!str 123\nescaped: \"x\\0y\\0\"\n"), EParseCode::Success},
    {TEXT("A1-K05"), TEXT("LiteralUtf8"), 0, TEXT("escaped: \"\\x01\"\nquoted: \"") TEXT("\x007F") TEXT("\x0080") TEXT("\x009F") TEXT("\"\n"), EParseCode::Success},
    {TEXT("A1-F01"), TEXT("LiteralUtf8"), 0, TEXT("a: [unterminated\n"), EParseCode::MalformedYaml},
    {TEXT("A1-F02"), TEXT("LiteralUtf8"), 0, TEXT("a: *missing\n"), EParseCode::MalformedYaml},
    {TEXT("A1-F03"), TEXT("LiteralUtf8"), 0, TEXT("a: one\n---\nb: two\n"), EParseCode::MultipleDocuments},
    {TEXT("A1-F04"), TEXT("LiteralUtf8"), 0, TEXT("a: !unsupported value\n"), EParseCode::UnsupportedTag},
    {TEXT("A1-F05"), TEXT("LiteralUtf8"), 0, TEXT("!unsupported"), EParseCode::NullPropertiesUnavailable},
    {TEXT("A1-F06"), TEXT("LiteralUtf8"), 0, TEXT("a\0:\0 \0x\0"), EParseCode::MalformedYaml, 8},
    {TEXT("A1-F07"), TEXT("LiteralUtf8"), 0, TEXT("a: x") TEXT("\x04") TEXT("b: y\n"), EParseCode::MalformedYaml},
    {TEXT("A1-F08"), TEXT("LiteralUtf8"), 0, TEXT("\"\\N\"\n"), EParseCode::InvalidEventStream},
    {TEXT("A1-F09"), TEXT("LiteralUtf8"), 0, TEXT("\"\\_\"\n"), EParseCode::InvalidEventStream},
    {TEXT("A1-F10"), TEXT("LiteralUtf8"), 0, TEXT("\"") TEXT("\x0001") TEXT("\"\n"), EParseCode::MalformedYaml},
    {TEXT("A1-L.file.below"), TEXT("file"), 1048575, nullptr, EParseCode::Success},
    {TEXT("A1-L.file.at"), TEXT("file"), 1048576, nullptr, EParseCode::Success},
    {TEXT("A1-L.file.above"), TEXT("file"), 1048577, nullptr, EParseCode::InputTooLarge},
    {TEXT("A1-L.depth.below"), TEXT("depth"), 63, nullptr, EParseCode::Success},
    {TEXT("A1-L.depth.at"), TEXT("depth"), 64, nullptr, EParseCode::Success},
    {TEXT("A1-L.depth.above"), TEXT("depth"), 65, nullptr, EParseCode::DepthLimit},
    {TEXT("A1-L.nodes.below"), TEXT("nodes"), 99999, nullptr, EParseCode::Success},
    {TEXT("A1-L.nodes.at"), TEXT("nodes"), 100000, nullptr, EParseCode::Success},
    {TEXT("A1-L.nodes.above"), TEXT("nodes"), 100001, nullptr, EParseCode::NodeLimit},
    {TEXT("A1-L.aliases.below"), TEXT("aliases"), 9999, nullptr, EParseCode::Success},
    {TEXT("A1-L.aliases.at"), TEXT("aliases"), 10000, nullptr, EParseCode::Success},
    {TEXT("A1-L.aliases.above"), TEXT("aliases"), 10001, nullptr, EParseCode::AliasLimit},
    {TEXT("A1-L.scalar.below"), TEXT("scalar"), 65535, nullptr, EParseCode::Success},
    {TEXT("A1-L.scalar.at"), TEXT("scalar"), 65536, nullptr, EParseCode::Success},
    {TEXT("A1-L.scalar.above"), TEXT("scalar"), 65537, nullptr, EParseCode::ScalarLimit},
    {TEXT("A1-F11"), TEXT("LiteralUtf8"), 0, TEXT("[null, x]\n"), EParseCode::NullPropertiesUnavailable},
    {TEXT("A1-F12"), TEXT("LiteralUtf8"), 0, TEXT("[null, a: [unterminated\n"), EParseCode::MalformedYaml},
    {TEXT("A1-F13"), TEXT("LiteralUtf8"), 0, TEXT("[null,[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[x]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]], [unterminated\n"), EParseCode::NullPropertiesUnavailable},
};
static_assert(UE_ARRAY_COUNT(Generated) == 33);

FString LiteralText(const FGeneratedSpec& Spec)
{
    return Spec.LiteralCharacters == INDEX_NONE ? FString(Spec.Literal) : FString::ConstructFromPtrSize(Spec.Literal, Spec.LiteralCharacters);
}

const FGeneratedSpec* FindSpec(const FString& Id)
{
    for (const FGeneratedSpec& Spec : Generated) { if (Id == Spec.Id) { return &Spec; } }
    return nullptr;
}

TArray<uint8> Expand(const FGeneratedSpec& Spec)
{
    if (Spec.Literal) { return Utf8(LiteralText(Spec)); }
    TArray<uint8> Bytes;
    auto Append = [&Bytes](const ANSICHAR* Text)
    {
        while (*Text) { Bytes.Add(static_cast<uint8>(*Text++)); }
    };
    if (FCString::Strcmp(Spec.Kind, TEXT("file")) == 0)
    {
        Append("a: x\n#");
        Bytes.AddUninitialized(Spec.Count - 7);
        FMemory::Memset(Bytes.GetData() + 6, 'p', Spec.Count - 7);
        Append("\n");
    }
    else if (FCString::Strcmp(Spec.Kind, TEXT("depth")) == 0)
    {
        for (int32 I = 0; I < Spec.Count; ++I) { Bytes.Add('['); }
        Bytes.Add('x');
        for (int32 I = 0; I < Spec.Count; ++I) { Bytes.Add(']'); }
        Bytes.Add('\n');
    }
    else if (FCString::Strcmp(Spec.Kind, TEXT("nodes")) == 0)
    {
        Append("[");
        for (int32 I = 0; I < Spec.Count - 2; ++I) { Append("x,"); }
        Append("x]\n");
    }
    else if (FCString::Strcmp(Spec.Kind, TEXT("aliases")) == 0)
    {
        Append("[&a x");
        for (int32 I = 0; I < Spec.Count; ++I) { Append(", *a"); }
        Append("]\n");
    }
    else if (FCString::Strcmp(Spec.Kind, TEXT("scalar")) == 0)
    {
        Bytes.Add('"');
        for (int32 I = 0; I < Spec.Count; ++I) { Bytes.Add('x'); }
        Append("\"\n");
    }
    return Bytes;
}

bool GraphReferencesValid(const FDocument& Document)
{
    if (!Document.Nodes.IsValidIndex(Document.Root)) { return false; }
    int32 Aliases = 0;
    for (const FNode& Node : Document.Nodes)
    {
        if (Node.Kind == ENodeKind::Alias)
        {
            ++Aliases;
            if (!Document.Nodes.IsValidIndex(Node.AliasTarget) ||
                Document.Nodes[Node.AliasTarget].AnchorDefinitionId == INDEX_NONE) { return false; }
        }
        for (int32 Child : Node.Children) { if (!Document.Nodes.IsValidIndex(Child)) { return false; } }
        for (const FMappingPair& Pair : Node.Pairs)
        { if (!Document.Nodes.IsValidIndex(Pair.KeyNode) || !Document.Nodes.IsValidIndex(Pair.ValueNode)) { return false; } }
    }
    return Aliases == Document.ObservedAliasOccurrences;
}

const FNode* MappingValue(const FDocument& Document, const FNode& Map, const FString& Key)
{
    for (const FMappingPair& Pair : Map.Pairs)
    {
        if (Document.Nodes.IsValidIndex(Pair.KeyNode) && Document.Nodes.IsValidIndex(Pair.ValueNode) &&
            BytesEqual(Document.Nodes[Pair.KeyNode].ScalarUtf8, Key)) { return &Document.Nodes[Pair.ValueNode]; }
    }
    return nullptr;
}

class FProbe
{
public:
    FProbe(FAutomationTestBase& InTest, const TCHAR* InSuffix, const TCHAR* InSlug)
        : Test(InTest), SuiteName(FString(TEXT("Warhammer.Migration.E04A1.")) + InSuffix), Slug(InSlug) {}

    bool Check(const TCHAR* What, bool bValue)
    {
        ++CheckCount;
        if (ActiveRow.IsValid()) { ActiveRow->SetNumberField(TEXT("checks"), ActiveRow->GetNumberField(TEXT("checks")) + 1); }
        if (!bValue)
        {
            ++FailedCheckCount;
            if (ActiveRow.IsValid()) { ActiveRow->SetNumberField(TEXT("failedChecks"), ActiveRow->GetNumberField(TEXT("failedChecks")) + 1); }
            UE_LOG(LogTemp, Error, TEXT("E04A1 %s: %s"), *SuiteName, What);
        }
        return Test.TestTrue(What, bValue);
    }

    bool Initialize()
    {
        ProjectDir = FPaths::ConvertRelativePathToFull(FPaths::ProjectDir());
        FPaths::NormalizeDirectoryName(ProjectDir);
        if (!Check(TEXT("ProjectDir collapses"), FPaths::CollapseRelativeDirectories(ProjectDir))) { return false; }
        RunRoot = FPaths::GetPath(ProjectDir);
        const FString Family = FPaths::GetPath(RunRoot);
        const FString Experiments = FPaths::GetPath(Family);
        const FString Local = FPaths::GetPath(Experiments);
        const FString RunId = FPaths::GetCleanFilename(RunRoot);
        bool bRunId = !RunId.IsEmpty() && RunId.Len() <= 64;
        for (TCHAR Ch : RunId) { bRunId &= (Ch >= '0' && Ch <= '9') || (Ch >= 'A' && Ch <= 'Z') ||
            (Ch >= 'a' && Ch <= 'z') || Ch == '-' || Ch == '_'; }
        // Physical/reparse ancestry is separately sealed by wrapper Preflight.
        // No CLI path, Saved fallback, canonical project or arbitrary user root.
        if (!Check(TEXT("Exact owned staged project ancestry"), bRunId &&
            FPaths::GetCleanFilename(ProjectDir) == TEXT("project") &&
            FPaths::GetCleanFilename(Family) == TEXT("E04A1") &&
            FPaths::GetCleanFilename(Experiments) == TEXT("experiments") &&
            FPaths::GetCleanFilename(Local) == TEXT(".local"))) { return false; }
        FixtureRoot = FPaths::Combine(RunRoot, TEXT("fixtures"));
        SuiteRoot = FPaths::Combine(RunRoot, TEXT("artifacts/native"), Slug);
        if (!Check(TEXT("Suite output is fresh"), !IFileManager::Get().DirectoryExists(*SuiteRoot)) ||
            !Check(TEXT("Create owned suite inputs"), IFileManager::Get().MakeDirectory(*FPaths::Combine(SuiteRoot, TEXT("inputs")), true))) { return false; }
        TSharedPtr<FJsonObject> Corpus, Cases;
        if (!ReadManifest(TEXT("corpus-manifest.json"), Corpus) || !ReadManifest(TEXT("generated-cases.json"), Cases)) { return false; }
        if (!IndexManifest(Corpus, TEXT("canonical"), 10) || !IndexManifest(Cases, TEXT("generated"), 33)) { return false; }
        return Check(TEXT("Exactly43 distinct frozen input IDs"), Descriptors.Num() == 43);
    }

    FParseResult Run(const FString& Id, int32 Attempt = 1)
    {
        ActiveRow = MakeShared<FJsonObject>();
        Rows.Add(MakeShared<FJsonValueObject>(ActiveRow));
        ActiveRow->SetStringField(TEXT("id"), Id);
        ActiveRow->SetNumberField(TEXT("attempt"), Attempt);
        ActiveRow->SetNumberField(TEXT("checks"), 0);
        ActiveRow->SetNumberField(TEXT("failedChecks"), 0);
        ActiveRow->SetStringField(TEXT("actualCode"), TEXT("NOT_RUN"));
        FParseResult Result;
        const TSharedPtr<FJsonObject>* Descriptor = Descriptors.Find(Id);
        if (!Check(TEXT("Input ID is frozen"), Descriptor != nullptr)) { return Result; }
        const FGeneratedSpec* Spec = FindSpec(Id);
        TArray<uint8> Bytes;
        const EParseCode Expected = Spec ? Spec->Code : EParseCode::Success;
        ActiveRow->SetStringField(TEXT("source"), Spec ? TEXT("Generated") : TEXT("Canonical"));
        ActiveRow->SetStringField(TEXT("recipeKind"), Spec ? Spec->Kind : TEXT("StagedFile"));
        ActiveRow->SetStringField(TEXT("expectedCode"), CodeName(Expected));
        if (!Check(TEXT("Frozen expected code matches independent spec"), (*Descriptor)->GetStringField(TEXT("expectedCode")) == CodeName(Expected))) { return Result; }
        if (Spec)
        {
            if (!Check(TEXT("Recipe is a metadata object"), (*Descriptor)->HasTypedField<EJson::Object>(TEXT("recipe")))) { return Result; }
            const TSharedPtr<FJsonObject>& Recipe = (*Descriptor)->GetObjectField(TEXT("recipe"));
            if (!Check(TEXT("Recipe kind matches fixed generator"), Recipe->GetStringField(TEXT("kind")) == Spec->Kind)) { return Result; }
            if (Spec->Literal)
            { if (!Check(TEXT("Recipe literal matches independent full bytes"), Utf8(Recipe->GetStringField(TEXT("text"))) == Utf8(LiteralText(*Spec)))) { return Result; } }
            else if (!Check(TEXT("Recipe count matches fixed generator"), Recipe->GetIntegerField(TEXT("count")) == Spec->Count)) { return Result; }
            Bytes = Expand(*Spec);
        }
        else if (!Check(TEXT("Load staged canonical bytes"), FFileHelper::LoadFileToArray(Bytes, *FPaths::Combine(FixtureRoot, Id + TEXT(".yaml"))))) { return Result; }
        const int64 ExpectedBytes = (*Descriptor)->GetIntegerField(Spec ? TEXT("inputBytes") : TEXT("bytes"));
        const FString InputSha1 = Sha1(Bytes);
        ActiveRow->SetNumberField(TEXT("inputBytes"), Bytes.Num());
        ActiveRow->SetStringField(TEXT("inputSha1"), InputSha1);
        if (!Check(TEXT("Exact input byte count"), Bytes.Num() == ExpectedBytes) ||
            !Check(TEXT("Auxiliary Core SHA1 matches frozen bytes"), InputSha1.Equals((*Descriptor)->GetStringField(TEXT("inputSha1")), ESearchCase::IgnoreCase))) { return Result; }
        const FString RelativeInput = FString(TEXT("artifacts/native/")) + Slug + TEXT("/inputs/") + Id + FString::Printf(TEXT("-%d.yaml"), Attempt);
        ActiveRow->SetStringField(TEXT("inputArtifactRelativePath"), RelativeInput);
        if (!Check(TEXT("Save original input without replacing"), FFileHelper::SaveArrayToFile(Bytes, *FPaths::Combine(RunRoot, RelativeInput),
            &IFileManager::Get(), FILEWRITE_NoReplaceExisting))) { return Result; }
        Result = ParseDocument(Bytes);
        ActiveRow->SetStringField(TEXT("actualCode"), CodeName(Result.Code));
        ActiveRow->SetBoolField(TEXT("success"), Result.IsSuccess());
        ActiveRow->SetNumberField(TEXT("nodeCount"), Result.Document.Nodes.Num());
        ActiveRow->SetNumberField(TEXT("maximumCollectionDepth"), Result.Document.ObservedMaximumCollectionDepth);
        ActiveRow->SetNumberField(TEXT("aliasOccurrences"), Result.Document.ObservedAliasOccurrences);
        TSharedPtr<FJsonObject> Diagnostic = MakeShared<FJsonObject>();
        Diagnostic->SetStringField(TEXT("code"), CodeName(Result.Diagnostic.Code));
        Diagnostic->SetNumberField(TEXT("observed"), Result.Diagnostic.Observed);
        Diagnostic->SetNumberField(TEXT("limit"), Result.Diagnostic.Limit);
        Diagnostic->SetBoolField(TEXT("markAvailable"), Result.Diagnostic.Mark.bAvailable);
        Diagnostic->SetNumberField(TEXT("markPosition"), Result.Diagnostic.Mark.Position);
        Diagnostic->SetNumberField(TEXT("markLine"), Result.Diagnostic.Mark.Line);
        Diagnostic->SetNumberField(TEXT("markColumn"), Result.Diagnostic.Mark.Column);
        ActiveRow->SetObjectField(TEXT("diagnostic"), Diagnostic);
        Check(TEXT("Typed code matches"), Result.Code == Expected);
        Check(TEXT("InputByteCount is actual original length"), Result.InputByteCount == Bytes.Num());
        if (Result.IsSuccess())
        {
            Check(TEXT("Accepted original bytes owned exactly"), Result.Document.OriginalBytes == Bytes);
            Check(TEXT("Flat graph references and alias count valid"), GraphReferencesValid(Result.Document));
        }
        else
        {
            Check(TEXT("Refusal diagnostic agrees with code"), Result.Diagnostic.Code == Result.Code);
            Check(TEXT("No partial/refused original document returned"), Result.Document.Root == INDEX_NONE && Result.Document.Nodes.IsEmpty() &&
                Result.Document.OriginalBytes.IsEmpty() && Result.Document.ObservedAliasOccurrences == 0 && Result.Document.ObservedMaximumCollectionDepth == 0);
        }
        return Result; // Local input dies; the returned value must own its bytes.
    }

    void Metrics(const FDocument& Document, int32 Nodes, int32 Depth, int32 Aliases)
    {
        Check(TEXT("Independent raw node count incl mapping keys"), Document.Nodes.Num() == Nodes);
        Check(TEXT("Independent collection depth root1"), Document.ObservedMaximumCollectionDepth == Depth);
        Check(TEXT("Independent alias occurrence count"), Document.ObservedAliasOccurrences == Aliases);
    }

    TArray<FString> ExpectedStrings(const FString& Id, const TCHAR* Field)
    {
        TArray<FString> Strings;
        const TSharedPtr<FJsonObject>* Descriptor = Descriptors.Find(Id);
        if (!Check(TEXT("Expected raw structure metadata exists"), Descriptor && (*Descriptor)->HasTypedField<EJson::Object>(TEXT("expected")))) { return Strings; }
        const TSharedPtr<FJsonObject>& Expected = (*Descriptor)->GetObjectField(TEXT("expected"));
        const TArray<TSharedPtr<FJsonValue>>* Values = nullptr;
        if (!Check(TEXT("Expected byte-hex metadata array exists"), Expected->TryGetArrayField(Field, Values) && Values)) { return Strings; }
        for (const TSharedPtr<FJsonValue>& Value : *Values)
        {
            if (!Check(TEXT("Expected byte-hex metadata string"), Value.IsValid() && Value->Type == EJson::String)) { return {}; }
            Strings.Add(Value->AsString());
        }
        return Strings;
    }

    bool Finish()
    {
        ActiveRow.Reset();
        if (SuiteRoot.IsEmpty()) { return false; }
        TSharedPtr<FJsonObject> Report = MakeShared<FJsonObject>();
        Report->SetNumberField(TEXT("schemaVersion"), 1);
        Report->SetStringField(TEXT("suiteName"), SuiteName);
        Report->SetStringField(TEXT("projectDir"), ProjectDir);
        Report->SetStringField(TEXT("runRoot"), RunRoot);
        Report->SetStringField(TEXT("subset"), TEXT("E04-A1E_EDITOR_MODULE_RAW_DOCUMENT_PROOF"));
        Report->SetBoolField(TEXT("callerExceptionsEnabled"), CallerExceptionsEnabled);
        Report->SetNumberField(TEXT("platformExceptionsDisabled"), CallerPlatformExceptionsDisabled);
        Report->SetStringField(TEXT("runtimeCallerProof"), TEXT("NOT_RUN_REQUIRED_E04_A1G"));
        Report->SetNumberField(TEXT("observedInputCount"), Rows.Num());
        Report->SetNumberField(TEXT("checkCount"), CheckCount);
        Report->SetNumberField(TEXT("failedCheckCount"), FailedCheckCount);
        Report->SetStringField(TEXT("checkCountQualification"), TEXT("Actual evaluated Check calls before ledger publication; not a prefabricated or UE-equivalent assertion total."));
        Report->SetStringField(TEXT("status"), FailedCheckCount == 0 ? TEXT("PASS") : TEXT("FAIL"));
        Report->SetArrayField(TEXT("inputs"), Rows);
        FString Text;
        if (!FJsonSerializer::Serialize(Report, TJsonWriterFactory<>::Create(&Text))) { Check(TEXT("Serialize suite ledger"), false); return false; }
        const FString Pending = FPaths::Combine(SuiteRoot, TEXT("input-ledger.pending.json"));
        const FString Final = FPaths::Combine(SuiteRoot, TEXT("input-ledger.json"));
        if (!FFileHelper::SaveStringToFile(Text, *Pending, FFileHelper::EEncodingOptions::ForceUTF8WithoutBOM,
            &IFileManager::Get(), FILEWRITE_NoReplaceExisting) || !IFileManager::Get().Move(*Final, *Pending, false))
        { Check(TEXT("Publish new owned suite ledger"), false); return false; }
        return FailedCheckCount == 0;
    }

private:
    bool ReadManifest(const TCHAR* Name, TSharedPtr<FJsonObject>& Object)
    {
        const FString Path = FPaths::Combine(FixtureRoot, Name);
        const int64 Size = IFileManager::Get().FileSize(*Path);
        FString Text;
        return Check(TEXT("Manifest bounded and present"), Size > 0 && Size <= 131072) &&
            Check(TEXT("Read staged manifest"), FFileHelper::LoadFileToString(Text, *Path)) &&
            Check(TEXT("Controlled manifest JSON object"), FJsonSerializer::Deserialize(TJsonReaderFactory<>::Create(Text), Object) && Object.IsValid()) &&
            Check(TEXT("Manifest experiment/schema"), Object->GetIntegerField(TEXT("schemaVersion")) == 1 && Object->GetStringField(TEXT("experiment")) == TEXT("E04-A1"));
    }

    bool IndexManifest(const TSharedPtr<FJsonObject>& Object, const TCHAR* Field, int32 Count)
    {
        const TArray<TSharedPtr<FJsonValue>>* Values = nullptr;
        if (!Check(TEXT("Exact manifest entry count"), Object->TryGetArrayField(Field, Values) && Values && Values->Num() == Count)) { return false; }
        for (const TSharedPtr<FJsonValue>& Value : *Values)
        {
            if (!Check(TEXT("Manifest entry object"), Value.IsValid() && Value->Type == EJson::Object)) { return false; }
            const TSharedPtr<FJsonObject> Entry = Value->AsObject();
            const FString Id = Entry->GetStringField(TEXT("id"));
            bool bCanonical = false;
            for (int32 I = 1; I <= 10; ++I) { bCanonical |= Id == FString::Printf(TEXT("A1-C%02d"), I); }
            if (!Check(TEXT("Unique known ID in correct manifest"), !Descriptors.Contains(Id) &&
                ((Count == 10 && bCanonical) || (Count == 33 && FindSpec(Id) != nullptr)))) { return false; }
            Descriptors.Add(Id, Entry);
        }
        return true;
    }

    FAutomationTestBase& Test;
    FString SuiteName, Slug, ProjectDir, RunRoot, FixtureRoot, SuiteRoot;
    int32 CheckCount = 0, FailedCheckCount = 0;
    TMap<FString, TSharedPtr<FJsonObject>> Descriptors;
    TArray<TSharedPtr<FJsonValue>> Rows;
    TSharedPtr<FJsonObject> ActiveRow;
};

void CheckPairs(FProbe& Probe, const FDocument& Document, const FNode& Map,
    const TArray<FString>& Keys, const TArray<FString>& Values = {})
{
    if (!Probe.Check(TEXT("Mapping has exact ordered pair count"), Map.Kind == ENodeKind::Mapping && Map.Pairs.Num() == Keys.Num())) { return; }
    for (int32 I = 0; I < Keys.Num(); ++I)
    {
        const FMappingPair& Pair = Map.Pairs[I];
        if (!Probe.Check(TEXT("Ordered mapping indices exist"), Document.Nodes.IsValidIndex(Pair.KeyNode) && Document.Nodes.IsValidIndex(Pair.ValueNode))) { continue; }
        Probe.Check(TEXT("Ordered key remains exact case-preserving bytes"), Document.Nodes[Pair.KeyNode].Kind == ENodeKind::Scalar && BytesEqual(Document.Nodes[Pair.KeyNode].ScalarUtf8, Keys[I]));
        if (Values.IsValidIndex(I)) { Probe.Check(TEXT("Ordered scalar value remains bytes"), Document.Nodes[Pair.ValueNode].Kind == ENodeKind::Scalar && BytesEqual(Document.Nodes[Pair.ValueNode].ScalarUtf8, Values[I])); }
    }
}
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FE04A1Load, "Warhammer.Migration.E04A1.Abi.LoadAndBoundary", Flags)
bool FE04A1Load::RunTest(const FString&)
{
    FProbe P(*this, TEXT("Abi.LoadAndBoundary"), TEXT("abi-load-boundary"));
    if (!P.Initialize()) { return false; }
    P.Check(TEXT("Parser module actually loaded across UE module boundary"), FModuleManager::LoadModulePtr<IModuleInterface>(TEXT("E04ProfileParser")) != nullptr);
    const FParseResult R = P.Run(TEXT("A1-K04"));
    P.Check(TEXT("Editor caller receives owned successful value across module boundary"), R.IsSuccess() && BytesEqual(R.Document.OriginalBytes, Generated[3].Literal));
    return P.Finish();
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FE04A1Refusal, "Warhammer.Migration.E04A1.Abi.TypedRefusal", Flags)
bool FE04A1Refusal::RunTest(const FString&)
{
    FProbe P(*this, TEXT("Abi.TypedRefusal"), TEXT("abi-typed-refusal"));
    if (!P.Initialize()) { return false; }
    const FParseResult Bad = P.Run(TEXT("A1-F01"));
    P.Check(TEXT("Malformed vendor input returns typed error to Editor caller"), Bad.Code == EParseCode::MalformedYaml);
    const FParseResult Good = P.Run(TEXT("A1-K04"));
    P.Check(TEXT("Good parse succeeds after typed vendor failure"), Good.IsSuccess());
    return P.Finish();
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FE04A1Lifetime, "Warhammer.Migration.E04A1.Abi.ValueLifetime", Flags)
bool FE04A1Lifetime::RunTest(const FString&)
{
    FProbe P(*this, TEXT("Abi.ValueLifetime"), TEXT("abi-value-lifetime"));
    if (!P.Initialize()) { return false; }
    FDocument Survivor;
    {
        FParseResult R = P.Run(TEXT("A1-K03"));
        if (P.Check(TEXT("Lifetime source graph has safe scalar/collection shape"), R.IsSuccess() && R.Document.Nodes.Num() == 6 &&
            R.Document.Nodes[1].Kind == ENodeKind::Sequence && R.Document.Nodes[2].Kind == ENodeKind::Scalar &&
            R.Document.Nodes[2].ScalarUtf8.Num() == 1 && R.Document.Nodes[1].Children.Num() == 1))
        {
            Survivor = R.Document;
            P.Check(TEXT("UE-owned arrays deep copy across module value"), Survivor.Nodes.GetData() != R.Document.Nodes.GetData() && Survivor.OriginalBytes.GetData() != R.Document.OriginalBytes.GetData());
            Survivor.Nodes[2].ScalarUtf8[0] = 'z';
            Survivor.Nodes[1].Children.Add(2);
            P.Check(TEXT("Nested owned arrays do not alias original"), BytesEqual(R.Document.Nodes[2].ScalarUtf8, TEXT("x")) && R.Document.Nodes[1].Children.Num() == 1);
        }
    } // Returned parse result and all its arrays destroyed in the caller module.
    P.Check(TEXT("Copied value survives source destruction"), Survivor.Nodes.Num() == 6 && BytesEqual(Survivor.OriginalBytes, Generated[2].Literal));
    const FNode* PreviousAllocation = Survivor.Nodes.GetData();
    FDocument Moved = MoveTemp(Survivor);
    P.Check(TEXT("Move transfers owned allocation and stable alias targets"), Moved.Nodes.GetData() == PreviousAllocation && Moved.Nodes.Num() == 6 && Moved.Nodes[3].AliasTarget == 1 && Moved.Nodes[5].AliasTarget == 4);
    return P.Finish(); // Moved graph destructs in the separate Editor caller module.
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FE04A1Canonical, "Warhammer.Migration.E04A1.Parser.CanonicalSyntax", Flags)
bool FE04A1Canonical::RunTest(const FString&)
{
    FProbe P(*this, TEXT("Parser.CanonicalSyntax"), TEXT("parser-canonical-syntax"));
    if (!P.Initialize()) { return false; }
    const TCHAR* Identities[] = {TEXT("default"), TEXT("dense-debug"), TEXT("keyboard-heavy"), TEXT("command-bench"), TEXT("default_compass_hud"), TEXT("command_bench_hud"), TEXT("unit_datasheet_preview"), TEXT("workbench_preview"), TEXT("overflow_stress_preview"), TEXT("player_units_roster_preview")};
    for (int32 I = 0; I < 10; ++I)
    {
        const FParseResult R = P.Run(FString::Printf(TEXT("A1-C%02d"), I + 1));
        if (!P.Check(TEXT("Canonical restricted raw document accepted with valid root"), R.IsSuccess() && R.Document.Nodes.IsValidIndex(R.Document.Root))) { continue; }
        const FNode& Root = R.Document.Nodes[R.Document.Root];
        const TArray<FString> Keys = I < 4 ? TArray<FString>{TEXT("schema_version"), TEXT("profile_name"), TEXT("overlays"), TEXT("hotkeys"), TEXT("selection"), TEXT("hud"), TEXT("experimental"), TEXT("extensions")} :
            I < 6 ? TArray<FString>{TEXT("schema_version"), TEXT("profile_id"), TEXT("layout_preset"), TEXT("theme"), TEXT("regions")} :
            TArray<FString>{TEXT("schema_version"), TEXT("profile_id"), TEXT("layout_preset"), TEXT("theme"), TEXT("sample_data"), TEXT("regions")};
        CheckPairs(P, R.Document, Root, Keys);
        const FNode* Identity = MappingValue(R.Document, Root, I < 4 ? TEXT("profile_name") : TEXT("profile_id"));
        P.Check(TEXT("Literal canonical profile identity"), Identity && Identity->Kind == ENodeKind::Scalar && BytesEqual(Identity->ScalarUtf8, Identities[I]));
        const FNode* Schema = MappingValue(R.Document, Root, TEXT("schema_version"));
        P.Check(TEXT("Literal schema scalar bytes and observable tag"), Schema && Schema->Kind == ENodeKind::Scalar && BytesEqual(Schema->ScalarUtf8, TEXT("1")) && Schema->bTagAvailable && BytesEqual(Schema->TagUtf8, I < 4 ? TEXT("!") : TEXT("?")));
        const FNode* MainMap = MappingValue(R.Document, Root, I < 4 ? TEXT("overlays") : TEXT("regions"));
        P.Check(TEXT("Canonical overlays/regions remains raw mapping"), MainMap && MainMap->Kind == ENodeKind::Mapping);
        if (I < 4)
        {
            const FNode* Hotkeys = MappingValue(R.Document, Root, TEXT("hotkeys"));
            P.Check(TEXT("Unindented hotkeys dash sequence remains sequence"), Hotkeys && Hotkeys->Kind == ENodeKind::Sequence);
        }
        if (I >= 6)
        {
            const FNode* Samples = MappingValue(R.Document, Root, TEXT("sample_data"));
            P.Check(TEXT("Preview sample_data remains raw mapping"), Samples && Samples->Kind == ENodeKind::Mapping);
        }
    }
    return P.Finish();
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FE04A1Ordered, "Warhammer.Migration.E04A1.Parser.OrderedCaseValues", Flags)
bool FE04A1Ordered::RunTest(const FString&)
{
    FProbe P(*this, TEXT("Parser.OrderedCaseValues"), TEXT("parser-ordered-case-values"));
    if (!P.Initialize()) { return false; }
    for (int32 I = 0; I < 5; ++I)
    {
        const FParseResult R = P.Run(Generated[I].Id);
        if (!P.Check(TEXT("Structured raw graph accepted"), R.IsSuccess() && R.Document.Nodes.IsValidIndex(R.Document.Root))) { continue; }
        const FDocument& D = R.Document;
        const FNode& Root = D.Nodes[D.Root];
        P.Metrics(D, I == 0 ? 13 : I == 1 ? 5 : I == 2 ? 6 : I == 3 ? 9 : 5, I == 1 || I == 3 || I == 4 ? 1 : 2, I == 2 ? 2 : 0);
        if (I == 0)
        {
            CheckPairs(P, D, Root, {TEXT("A"), TEXT("a")});
            const FNode* Upper = MappingValue(D, Root, TEXT("A"));
            const FNode* Lower = MappingValue(D, Root, TEXT("a"));
            if (P.Check(TEXT("Case-distinct nested mappings present"), Upper && Lower))
            {
                CheckPairs(P, D, *Upper, {TEXT("Value"), TEXT("value")}, {TEXT("upper"), TEXT("lower")});
                CheckPairs(P, D, *Lower, {TEXT("\u043a\u043b\u044e\u0447"), TEXT("\u041a\u043b\u044e\u0447")}, {TEXT("one"), TEXT("two")});
            }
        }
        else if (I == 1) { CheckPairs(P, D, Root, {TEXT("a"), TEXT("a")}, {TEXT("first"), TEXT("second")}); }
        else if (I == 2 && P.Check(TEXT("Anchor graph exact node and child count"), D.Nodes.Num() == 6 && Root.Kind == ENodeKind::Sequence && Root.Children == TArray<int32>{1, 3, 4, 5}))
        {
            P.Check(TEXT("Collection/scalar anchor definitions preserve names and distinct IDs"), D.Nodes[1].Kind == ENodeKind::Sequence && D.Nodes[4].Kind == ENodeKind::Scalar &&
                BytesEqual(D.Nodes[1].AnchorNameUtf8, TEXT("a")) && BytesEqual(D.Nodes[4].AnchorNameUtf8, TEXT("a")) &&
                D.Nodes[1].AnchorDefinitionId != INDEX_NONE && D.Nodes[4].AnchorDefinitionId != INDEX_NONE && D.Nodes[1].AnchorDefinitionId != D.Nodes[4].AnchorDefinitionId);
            P.Check(TEXT("Rebound aliases retain occurrence targets without expansion"), D.Nodes[3].Kind == ENodeKind::Alias && D.Nodes[3].AliasTarget == 1 && D.Nodes[5].Kind == ENodeKind::Alias && D.Nodes[5].AliasTarget == 4);
            P.Check(TEXT("Observable collection flow style preserved"), Root.CollectionStyle == ECollectionStyle::Flow && D.Nodes[1].CollectionStyle == ECollectionStyle::Flow);
        }
        else if (I == 3)
        {
            CheckPairs(P, D, Root, {TEXT("plain"), TEXT("quoted"), TEXT("explicit"), TEXT("escaped")});
            const TArray<FString> ExpectedHex = P.ExpectedStrings(TEXT("A1-K04"), TEXT("valueUtf8Hex"));
            P.Check(TEXT("Frozen decoded values match independent full-byte expectations"), ExpectedHex == TArray<FString>{TEXT("796573"), TEXT("796573"), TEXT("313233"), TEXT("78007900")});
            const TCHAR* Keys[] = {TEXT("plain"), TEXT("quoted"), TEXT("explicit"), TEXT("escaped")};
            const TCHAR* Tags[] = {TEXT("?"), TEXT("!"), TEXT("tag:yaml.org,2002:str"), TEXT("!")};
            for (int32 J = 0; J < 4; ++J)
            {
                const FNode* Value = MappingValue(D, Root, Keys[J]);
                P.Check(TEXT("Decoded scalar full bytes including embedded/terminal NUL"), Value && Value->Kind == ENodeKind::Scalar && ExpectedHex.IsValidIndex(J) &&
                    BytesToHex(Value->ScalarUtf8.GetData(), Value->ScalarUtf8.Num()).Equals(ExpectedHex[J], ESearchCase::IgnoreCase));
                P.Check(TEXT("Plain/nonplain/explicit tag observation without resolution"), Value && Value->bTagAvailable && BytesEqual(Value->TagUtf8, Tags[J]));
            }
        }
        else if (I == 4)
        {
            CheckPairs(P, D, Root, {TEXT("escaped"), TEXT("quoted")});
            const TArray<FString> ExpectedHex = P.ExpectedStrings(TEXT("A1-K05"), TEXT("valueUtf8Hex"));
            P.Check(TEXT("Escaped control and quoted non-C0 have exact independent bytes"), ExpectedHex == TArray<FString>{TEXT("01"), TEXT("7FC280C29F")});
            const TCHAR* Keys[] = {TEXT("escaped"), TEXT("quoted")};
            for (int32 J = 0; J < 2; ++J)
            {
                const FNode* Value = MappingValue(D, Root, Keys[J]);
                P.Check(TEXT("Valid escaped control and quoted DEL/C1 remain scalar bytes"), Value && Value->Kind == ENodeKind::Scalar && ExpectedHex.IsValidIndex(J) &&
                    BytesToHex(Value->ScalarUtf8.GetData(), Value->ScalarUtf8.Num()).Equals(ExpectedHex[J], ESearchCase::IgnoreCase));
            }
        }
    }
    return P.Finish();
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FE04A1Lexical, "Warhammer.Migration.E04A1.Parser.LexicalFailures", Flags)
bool FE04A1Lexical::RunTest(const FString&)
{
    FProbe P(*this, TEXT("Parser.LexicalFailures"), TEXT("parser-lexical-failures"));
    if (!P.Initialize()) { return false; }
    for (int32 I = 5; I < 15; ++I)
    {
        const FParseResult R = P.Run(Generated[I].Id);
        P.Check(TEXT("Each frozen negative refuses with precise independent type"), R.Code == Generated[I].Code && !R.IsSuccess());
        if (FCString::Strcmp(Generated[I].Id, TEXT("A1-F10")) == 0)
        {
            P.Check(TEXT("Raw quoted C0 refuses at entry with default unavailable mark"), R.InputByteCount == 4 &&
                !R.Diagnostic.Mark.bAvailable && R.Diagnostic.Observed == 0 && R.Diagnostic.Limit == 0);
        }
    }
    const TCHAR* NullProbeIds[] = {TEXT("A1-F11"), TEXT("A1-F12"), TEXT("A1-F13")};
    for (const TCHAR* Id : NullProbeIds)
    {
        const FGeneratedSpec* Spec = FindSpec(Id);
        if (!P.Check(TEXT("Null-only syntax regression has exact fixed spec"), Spec != nullptr)) { continue; }
        const FParseResult R = P.Run(Id);
        P.Check(TEXT("Null-only syntax probe keeps exact independent refusal type"),
            R.Code == Spec->Code && R.Diagnostic.Code == Spec->Code && !R.IsSuccess());
        P.Check(TEXT("Null-only syntax probe never publishes a partial document"),
            R.Document.Nodes.IsEmpty() && R.Document.OriginalBytes.IsEmpty() &&
            R.Document.Root == INDEX_NONE && R.Document.ObservedMaximumCollectionDepth == 0 &&
            R.Document.ObservedAliasOccurrences == 0);
        if (Spec->Code == EParseCode::NullPropertiesUnavailable)
        {
            // Unclosed F13 retains a provisional root map before its flow sequence.
            const int64 ExpectedObservedNodes = FCString::Strcmp(Id, TEXT("A1-F13")) == 0 ? 3 : 2;
            P.Check(TEXT("Original null diagnostic survives completed or bounded probe"),
                R.Diagnostic.Code == EParseCode::NullPropertiesUnavailable &&
                R.Diagnostic.Mark.bAvailable && R.Diagnostic.Mark.Position == 1 &&
                R.Diagnostic.Mark.Line == 0 && R.Diagnostic.Mark.Column == 1 &&
                R.Diagnostic.Observed == ExpectedObservedNodes && R.Diagnostic.Limit == 0);
        }
    }
    return P.Finish();
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FE04A1Limits, "Warhammer.Migration.E04A1.Parser.ResourceBounds", Flags)
bool FE04A1Limits::RunTest(const FString&)
{
    FProbe P(*this, TEXT("Parser.ResourceBounds"), TEXT("parser-resource-bounds"));
    if (!P.Initialize()) { return false; }
    for (int32 I = 15; I < 30; ++I)
    {
        const FGeneratedSpec& S = Generated[I];
        const FParseResult R = P.Run(S.Id);
        const int32 Family = (I - 15) / 3;
        if (S.Code == EParseCode::Success && R.IsSuccess())
        {
            const int32 Nodes = Family == 0 ? 3 : Family == 1 ? S.Count + 1 : Family == 2 ? S.Count : Family == 3 ? S.Count + 2 : 1;
            P.Metrics(R.Document, Nodes, Family == 1 ? S.Count : Family == 4 ? 0 : 1, Family == 3 ? S.Count : 0);
            int32 MaximumScalar = 0;
            for (const FNode& Node : R.Document.Nodes) { MaximumScalar = FMath::Max(MaximumScalar, Node.ScalarUtf8.Num()); }
            P.Check(TEXT("Decoded scalar byte metric independently matches"), MaximumScalar == (Family == 4 ? S.Count : 1));
        }
        else if (S.Code != EParseCode::Success)
        {
            const int64 Limit = Family == 0 ? FLimits::MaxInputBytes : Family == 1 ? FLimits::MaxCollectionDepth : Family == 2 ? FLimits::MaxRawNodes : Family == 3 ? FLimits::MaxAliasOccurrences : FLimits::MaxScalarUtf8Bytes;
            P.Check(TEXT("Above inclusive boundary reports actual rejected unit and limit"), R.Diagnostic.Code == S.Code && R.Diagnostic.Observed == S.Count && R.Diagnostic.Limit == Limit);
        }
    }
    return P.Finish();
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FE04A1Repeat, "Warhammer.Migration.E04A1.Integration.RepeatIsolation", Flags)
bool FE04A1Repeat::RunTest(const FString&)
{
    FProbe P(*this, TEXT("Integration.RepeatIsolation"), TEXT("integration-repeat-isolation"));
    if (!P.Initialize()) { return false; }
    const FParseResult Before = P.Run(TEXT("A1-K03"), 1);
    const FParseResult Bad = P.Run(TEXT("A1-F02"), 1);
    const FParseResult After = P.Run(TEXT("A1-K03"), 2);
    P.Check(TEXT("Fresh good/bad/good outcomes remain isolated"), Before.IsSuccess() && Bad.Code == EParseCode::MalformedYaml && After.IsSuccess());
    if (P.Check(TEXT("Both independent good graphs have exact shape"), Before.Document.Nodes.Num() == 6 && After.Document.Nodes.Num() == 6))
    {
        P.Check(TEXT("Repeated original and alias targets unchanged after failure"), Before.Document.OriginalBytes == After.Document.OriginalBytes && Before.Document.Nodes[3].AliasTarget == After.Document.Nodes[3].AliasTarget && Before.Document.Nodes[5].AliasTarget == After.Document.Nodes[5].AliasTarget);
        P.Check(TEXT("Fresh owned graph storage per call"), Before.Document.Nodes.GetData() != After.Document.Nodes.GetData() && Before.Document.OriginalBytes.GetData() != After.Document.OriginalBytes.GetData());
    }
    return P.Finish();
}
#endif
