// Bounded Game caller proof; source grants no native, build, review or GO authority.
// E04ProfileGameProbe/Private/E04ProfileGameProbeModule.cpp
#include "CoreMinimal.h"
#include "CoreGlobals.h"
#include "E04ProfileFormat.h"
#include "Dom/JsonObject.h"
#include "Engine/Engine.h"
#include "Engine/World.h"
#include "GameFramework/GameModeBase.h"
#include "HAL/FileManager.h"
#include "HAL/PlatformMisc.h"
#include "HAL/PlatformProcess.h"
#include "HAL/PlatformProperties.h"
#include "Misc/App.h"
#include "Misc/CommandLine.h"
#include "Misc/CoreDelegates.h"
#include "Misc/Parse.h"
#include "Misc/Paths.h"
#include "Modules/ModuleManager.h"
#include "Serialization/JsonSerializer.h"
#include "UObject/Package.h"
#include "Windows/WindowsHWrapper.h"
#include <type_traits>

#if !PLATFORM_WINDOWS || !PLATFORM_64BITS || WITH_EDITOR || !UE_BUILD_DEVELOPMENT
#error E04_A1G_REQUIRES_WIN64_DEVELOPMENT_NON_EDITOR_GAME
#endif
#if defined(_CPPUNWIND)
#error E04_A1G_CALLER_MUST_DISABLE_CPP_EXCEPTIONS
#endif
#if !defined(PLATFORM_EXCEPTIONS_DISABLED) || PLATFORM_EXCEPTIONS_DISABLED != 1
#error E04_A1G_CALLER_REQUIRES_PLATFORM_EXCEPTIONS_DISABLED_1
#endif
#if !defined(E04_A1G_DEDICATED_CALLER) || E04_A1G_DEDICATED_CALLER != 1
#error E04_A1G_DEDICATED_CALLER_MARKER_MISSING
#endif
#if !defined(E04_A1G_EXPECTED_RUN_ID) || !defined(E04_A1G_EXPECTED_SOURCE_HEAD) || !defined(E04_A1G_EXPECTED_RUN_ROOT)
#error E04_A1G_COMPILED_BINDINGS_MISSING
#endif

using namespace Warhammer::E04A1;
static_assert(std::is_same_v<decltype(&ParseDocument), FParseResult (*)(TConstArrayView<uint8>, EFormat) noexcept>, "Public boundary must be noexcept");
DEFINE_LOG_CATEGORY_STATIC(LogE04A1G, Log, All);

namespace
{
constexpr ANSICHAR BadInput[] = "a: [unterminated\n";
constexpr ANSICHAR GoodInput[] = "A: first\na: second\n";
static_assert(UE_ARRAY_COUNT(BadInput) - 1 == 17);
static_assert(UE_ARRAY_COUNT(GoodInput) - 1 == 19);
constexpr int32 ResultByteCap = 65536;

FString FullPath(const FString& Value)
{
    FString Path = FPaths::ConvertRelativePathToFull(Value);
    FPaths::NormalizeFilename(Path);
    FPaths::CollapseRelativeDirectories(Path);
    return Path;
}

bool SamePath(const FString& A, const FString& B)
{
    return FullPath(A).Equals(FullPath(B), ESearchCase::IgnoreCase);
}

bool IsHex64(const FString& Value)
{
    if (Value.Len() != 64) return false;
    for (TCHAR C : Value)
        if (!((C >= TEXT('0') && C <= TEXT('9'))
            || (C >= TEXT('a') && C <= TEXT('f')) || (C >= TEXT('A') && C <= TEXT('F')))) return false;
    return true;
}

bool BytesEqual(const TArray<uint8>& Actual, const ANSICHAR* Expected, int32 Count)
{
    return Actual.Num() == Count && (Count == 0 || FMemory::Memcmp(Actual.GetData(), Expected, Count) == 0);
}

const FNode* NodeAt(const FDocument& Doc, int32 Index)
{
    return Doc.Nodes.IsValidIndex(Index) ? &Doc.Nodes[Index] : nullptr;
}

bool PairEquals(const FDocument& Doc, const FNode* Root, int32 PairIndex,
    const ANSICHAR* Key, int32 KeyBytes, const ANSICHAR* Value, int32 ValueBytes, bool bKeys)
{
    if (Root == nullptr || !Root->Pairs.IsValidIndex(PairIndex)) return false;
    const FMappingPair& Pair = Root->Pairs[PairIndex];
    const FNode* Node = NodeAt(Doc, bKeys ? Pair.KeyNode : Pair.ValueNode);
    return Node != nullptr && Node->Kind == ENodeKind::Scalar
        && BytesEqual(Node->ScalarUtf8, bKeys ? Key : Value, bKeys ? KeyBytes : ValueBytes);
}

TArray<FString> ExpectedIds()
{
    TArray<FString> Ids;
    for (int32 I = 1; I <= 18; ++I) Ids.Add(FString::Printf(TEXT("M%02d"), I));
    for (int32 I = 1; I <= 9; ++I) Ids.Add(FString::Printf(TEXT("B%02d"), I));
    for (int32 I = 1; I <= 13; ++I) Ids.Add(FString::Printf(TEXT("G%02d"), I));
    Ids.Add(TEXT("G23")); // Checked while both original and copied arrays are live.
    for (int32 I = 14; I <= 22; ++I) Ids.Add(FString::Printf(TEXT("G%02d"), I));
    Ids.Add(TEXT("L01")); Ids.Add(TEXT("L02"));
    return Ids;
}

struct FOutcome
{
    bool bEveryEvaluatedCheckPassed = true;
    bool bParserScopeCompleted = false;
    TArray<FString> Ids;
    TArray<FString> AttemptIds;
    TArray<TSharedPtr<FJsonValue>> Checks;
    TArray<TSharedPtr<FJsonValue>> Attempts;

    void Check(const TCHAR* Id, const TCHAR* Meaning, bool bPassed)
    {
        Ids.Add(Id);
        TSharedRef<FJsonObject> Row = MakeShared<FJsonObject>();
        Row->SetStringField(TEXT("id"), Id);
        Row->SetStringField(TEXT("meaning"), Meaning);
        Row->SetBoolField(TEXT("evaluated"), true);
        Row->SetBoolField(TEXT("passed"), bPassed);
        Checks.Add(MakeShared<FJsonValueObject>(Row));
        bEveryEvaluatedCheckPassed &= bPassed;
    }

    void Attempt(const TCHAR* Id, const FParseResult& Result, const TCHAR* ExpectedHash)
    {
        AttemptIds.Add(Id);
        TSharedRef<FJsonObject> Row = MakeShared<FJsonObject>();
        Row->SetStringField(TEXT("id"), Id);
        Row->SetNumberField(TEXT("ordinal"), AttemptIds.Num());
        Row->SetNumberField(TEXT("inputByteCount"), Result.InputByteCount);
        Row->SetStringField(TEXT("frozenLiteralSha256"), ExpectedHash);
        Row->SetNumberField(TEXT("codeNumber"), static_cast<uint8>(Result.Code));
        Row->SetNumberField(TEXT("diagnosticCodeNumber"), static_cast<uint8>(Result.Diagnostic.Code));
        Row->SetBoolField(TEXT("markAvailable"), Result.Diagnostic.Mark.bAvailable);
        Row->SetNumberField(TEXT("markPositionObservation"), Result.Diagnostic.Mark.Position);
        Row->SetNumberField(TEXT("markLineObservation"), Result.Diagnostic.Mark.Line);
        Row->SetNumberField(TEXT("markColumnObservation"), Result.Diagnostic.Mark.Column);
        Row->SetStringField(TEXT("markUnits"), TEXT("UNCLAIMED_VENDOR_START_OBSERVATIONS"));
        Attempts.Add(MakeShared<FJsonValueObject>(Row));
    }
};

void RunTwoInputs(FOutcome& Out)
{
    {
        TArray<uint8> Input;
        Input.Append(reinterpret_cast<const uint8*>(BadInput), UE_ARRAY_COUNT(BadInput) - 1);
        FParseResult Result = ParseDocument(TConstArrayView<uint8>(Input), EFormat::Yaml);
        for (uint8& Byte : Input) Byte = 0xcc;
        Input.Empty(0);
        Out.Attempt(TEXT("A1G_BAD"), Result, TEXT("CA15BE3A44E31C173E9697942EA8AE1F1988C902954AB10E74EAFE9F4E98B93C"));
        Out.Check(TEXT("B01"), TEXT("BAD typed MalformedYaml"), Result.Code == EParseCode::MalformedYaml);
        Out.Check(TEXT("B02"), TEXT("BAD diagnostic MalformedYaml"), Result.Diagnostic.Code == EParseCode::MalformedYaml);
        Out.Check(TEXT("B03"), TEXT("BAD exact byte count"), Result.InputByteCount == 17);
        Out.Check(TEXT("B04"), TEXT("BAD no root"), Result.Document.Root == INDEX_NONE);
        Out.Check(TEXT("B05"), TEXT("BAD no nodes"), Result.Document.Nodes.IsEmpty());
        Out.Check(TEXT("B06"), TEXT("BAD no original bytes"), Result.Document.OriginalBytes.IsEmpty());
        Out.Check(TEXT("B07"), TEXT("BAD depth zero"), Result.Document.ObservedMaximumCollectionDepth == 0);
        Out.Check(TEXT("B08"), TEXT("BAD alias count zero"), Result.Document.ObservedAliasOccurrences == 0);
        Out.Check(TEXT("B09"), TEXT("BAD caller array overwritten and released"), Input.Num() == 0 && Input.Max() == 0);
    } // BAD result and input are destroyed before the second call.

    {
        FDocument Survivor;
        {
            TArray<uint8> Input;
            Input.Append(reinterpret_cast<const uint8*>(GoodInput), UE_ARRAY_COUNT(GoodInput) - 1);
            FParseResult Result = ParseDocument(TConstArrayView<uint8>(Input), EFormat::Yaml);
            for (uint8& Byte : Input) Byte = 0xdd;
            Input.Empty(0);
            Out.Attempt(TEXT("A1G_GOOD"), Result, TEXT("F522FFF3CCDADCDA1FB8001D2B86727D39E43DB96A2D2D5A7C4CE7A2D0AD095B"));
            const FDocument& Doc = Result.Document;
            const FNode* Root = NodeAt(Doc, Doc.Root);
            Out.Check(TEXT("G01"), TEXT("GOOD typed Success"), Result.Code == EParseCode::Success);
            Out.Check(TEXT("G02"), TEXT("GOOD diagnostic Success"), Result.Diagnostic.Code == EParseCode::Success);
            Out.Check(TEXT("G03"), TEXT("GOOD exact byte count"), Result.InputByteCount == 19);
            Out.Check(TEXT("G04"), TEXT("GOOD caller array overwritten and released"), Input.Num() == 0 && Input.Max() == 0);
            Out.Check(TEXT("G05"), TEXT("GOOD valid root index"), Root != nullptr);
            Out.Check(TEXT("G06"), TEXT("GOOD exact five nodes"), Doc.Nodes.Num() == 5);
            Out.Check(TEXT("G07"), TEXT("GOOD mapping root"), Root != nullptr && Root->Kind == ENodeKind::Mapping);
            Out.Check(TEXT("G08"), TEXT("GOOD two ordered pairs"), Root != nullptr && Root->Pairs.Num() == 2);
            Out.Check(TEXT("G09"), TEXT("GOOD scalar keys A then a"), PairEquals(Doc, Root, 0, "A", 1, "first", 5, true) && PairEquals(Doc, Root, 1, "a", 1, "second", 6, true));
            Out.Check(TEXT("G10"), TEXT("GOOD scalar values first then second"), PairEquals(Doc, Root, 0, "A", 1, "first", 5, false) && PairEquals(Doc, Root, 1, "a", 1, "second", 6, false));
            Out.Check(TEXT("G11"), TEXT("GOOD collection depth one"), Doc.ObservedMaximumCollectionDepth == 1);
            Out.Check(TEXT("G12"), TEXT("GOOD no aliases"), Doc.ObservedAliasOccurrences == 0);
            Out.Check(TEXT("G13"), TEXT("GOOD exact owned original bytes after caller release"), BytesEqual(Doc.OriginalBytes, GoodInput, 19));
            Survivor = Doc;
            Out.Check(TEXT("G23"), TEXT("GOOD copied top-level arrays have distinct allocations"), Survivor.Nodes.GetData() != Doc.Nodes.GetData() && Survivor.OriginalBytes.GetData() != Doc.OriginalBytes.GetData());
        } // Original GOOD result/input and all references to its graph are gone.
        const FNode* Root = NodeAt(Survivor, Survivor.Root);
        Out.Check(TEXT("G14"), TEXT("Survivor retains exact original bytes"), BytesEqual(Survivor.OriginalBytes, GoodInput, 19));
        Out.Check(TEXT("G15"), TEXT("Survivor valid root index"), Root != nullptr);
        Out.Check(TEXT("G16"), TEXT("Survivor exact five nodes"), Survivor.Nodes.Num() == 5);
        Out.Check(TEXT("G17"), TEXT("Survivor mapping root"), Root != nullptr && Root->Kind == ENodeKind::Mapping);
        Out.Check(TEXT("G18"), TEXT("Survivor two ordered pairs"), Root != nullptr && Root->Pairs.Num() == 2);
        Out.Check(TEXT("G19"), TEXT("Survivor scalar keys A then a"), PairEquals(Survivor, Root, 0, "A", 1, "first", 5, true) && PairEquals(Survivor, Root, 1, "a", 1, "second", 6, true));
        Out.Check(TEXT("G20"), TEXT("Survivor scalar values first then second"), PairEquals(Survivor, Root, 0, "A", 1, "first", 5, false) && PairEquals(Survivor, Root, 1, "a", 1, "second", 6, false));
        Out.Check(TEXT("G21"), TEXT("Survivor collection depth one"), Survivor.ObservedMaximumCollectionDepth == 1);
        Out.Check(TEXT("G22"), TEXT("Survivor no aliases"), Survivor.ObservedAliasOccurrences == 0);
    } // Survivor and its nested UE arrays are destroyed before returning.
    Out.bParserScopeCompleted = true;
}

// Win64-only exclusive creation. No FILEWRITE_NoReplaceExisting claim: the
// inspected generic UE writer reaches Windows OpenWrite/CREATE_ALWAYS.
// Wrapper preflight must already establish the exact owned non-reparse parent.
// No replacement, directory creation, rename, retry or partial-file deletion.
bool PublishNew(const FString& Path, const TSharedRef<FJsonObject>& Report)
{
    FString Text;
    if (!FJsonSerializer::Serialize(Report, TJsonWriterFactory<>::Create(&Text))) return false;
    FTCHARToUTF8 Utf8(*Text);
    if (Utf8.Length() <= 0 || Utf8.Length() > ResultByteCap) return false;
    ::HANDLE File = ::CreateFileW(*Path, GENERIC_WRITE, 0, nullptr, CREATE_NEW, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (File == INVALID_HANDLE_VALUE) return false;
    ::DWORD Written = 0;
    const bool bWritten = ::WriteFile(File, Utf8.Get(), static_cast<::DWORD>(Utf8.Length()), &Written, nullptr) != 0;
    const bool bFlushed = bWritten && Written == static_cast<::DWORD>(Utf8.Length()) && ::FlushFileBuffers(File) != 0;
    const bool bClosed = ::CloseHandle(File) != 0;
    return bWritten && bFlushed && bClosed;
}
}

class FE04ProfileGameProbeModule final : public IModuleInterface
{
public:
    void StartupModule() override
    {
        InitCompleteHandle = FCoreDelegates::OnFEngineLoopInitComplete.AddRaw(this, &FE04ProfileGameProbeModule::OnInitComplete);
    }

    void ShutdownModule() override
    {
        if (InitCompleteHandle.IsValid())
        {
            FCoreDelegates::OnFEngineLoopInitComplete.Remove(InitCompleteHandle);
            InitCompleteHandle.Reset();
        }
    }

private:
    FDelegateHandle InitCompleteHandle;
    bool bRan = false;

    void OnInitComplete()
    {
        if (InitCompleteHandle.IsValid())
        {
            FCoreDelegates::OnFEngineLoopInitComplete.Remove(InitCompleteHandle);
            InitCompleteHandle.Reset();
        }
        if (bRan)
        {
            UE_LOG(LogE04A1G, Error, TEXT("Duplicate init callback; no second proof/publication"));
            FPlatformMisc::RequestExitWithStatus(false, 2, TEXT("E04_A1G_DUPLICATE_CALLBACK"));
            return;
        }
        bRan = true;

        const FString RunId = UTF8_TO_TCHAR(E04_A1G_EXPECTED_RUN_ID);
        const FString SourceHead = UTF8_TO_TCHAR(E04_A1G_EXPECTED_SOURCE_HEAD);
        const FString RunRoot = FullPath(UTF8_TO_TCHAR(E04_A1G_EXPECTED_RUN_ROOT));
        const FString ResultPath = FPaths::Combine(RunRoot, TEXT("reports/game-probe/result.json"));
        const FString ActualBinary = FullPath(FPlatformProcess::ExecutablePath());
        FString ArgRun, ArgHead, ArgRoot, ArgResult, ArgBinary, ArgBinarySha;
        const TCHAR* CommandLine = FCommandLine::Get();
        const bool bArgs = FParse::Value(CommandLine, TEXT("E04A1GRunId="), ArgRun)
            && FParse::Value(CommandLine, TEXT("E04A1GSourceHead="), ArgHead)
            && FParse::Value(CommandLine, TEXT("E04A1GRunRoot="), ArgRoot)
            && FParse::Value(CommandLine, TEXT("E04A1GResult="), ArgResult)
            && FParse::Value(CommandLine, TEXT("E04A1GBinary="), ArgBinary)
            && FParse::Value(CommandLine, TEXT("E04A1GBinarySha256="), ArgBinarySha);

        UWorld* GameWorld = nullptr;
        int32 GameWorldCount = 0;
        if (GEngine != nullptr)
            for (const FWorldContext& Context : GEngine->GetWorldContexts())
                if (Context.WorldType == EWorldType::Game && Context.World() != nullptr)
                { ++GameWorldCount; GameWorld = Context.World(); }
        const AGameModeBase* Mode = GameWorld != nullptr ? GameWorld->GetAuthGameMode() : nullptr;
        FOutcome Out;
        Out.Check(TEXT("M01"), TEXT("Game thread"), IsInGameThread());
        Out.Check(TEXT("M02"), TEXT("GIsRunning after normal initialization"), GIsRunning);
        Out.Check(TEXT("M03"), TEXT("Non-Editor process"), !GIsEditor);
        Out.Check(TEXT("M04"), TEXT("Non-commandlet process"), !IsRunningCommandlet());
        Out.Check(TEXT("M05"), TEXT("Game application state"), FApp::IsGame());
        Out.Check(TEXT("M06"), TEXT("Cooked data required"), FPlatformProperties::RequiresCookedData());
        Out.Check(TEXT("M07"), TEXT("Unattended mode"), FApp::IsUnattended());
        Out.Check(TEXT("M08"), TEXT("NullRHI flag"), FParse::Param(CommandLine, TEXT("NullRHI")));
        Out.Check(TEXT("M09"), TEXT("RenderOffScreen flag"), FParse::Param(CommandLine, TEXT("RenderOffScreen")));
        Out.Check(TEXT("M10"), TEXT("NoSound flag"), FParse::Param(CommandLine, TEXT("nosound")));
        Out.Check(TEXT("M11"), TEXT("NoSplash flag"), FParse::Param(CommandLine, TEXT("NoSplash")));
        Out.Check(TEXT("M12"), TEXT("No earlier exit request"), !IsEngineExitRequested());
        Out.Check(TEXT("M13"), TEXT("Exactly one actual Game world"), GameWorldCount == 1);
        Out.Check(TEXT("M14"), TEXT("Actual Engine Entry world"), GameWorld != nullptr && GameWorld->GetOutermost()->GetName() == TEXT("/Engine/Maps/Entry"));
        Out.Check(TEXT("M15"), TEXT("Actual exact GameModeBase class"), Mode != nullptr && Mode->GetClass() == AGameModeBase::StaticClass());
        Out.Check(TEXT("M16"), TEXT("Runtime arguments match compiled run/source/root"), bArgs && ArgRun == RunId && ArgHead == SourceHead && !FPaths::IsRelative(ArgRoot) && SamePath(ArgRoot, RunRoot) && IsHex64(ArgBinarySha));
        Out.Check(TEXT("M17"), TEXT("Exact absolute owned result path and existing parent"), !FPaths::IsRelative(ArgResult) && SamePath(ArgResult, ResultPath) && IFileManager::Get().DirectoryExists(*FPaths::GetPath(ResultPath)));
        Out.Check(TEXT("M18"), TEXT("Actual executable equals expected staged path"), !FPaths::IsRelative(ArgBinary) && SamePath(ActualBinary, ArgBinary) && ActualBinary.StartsWith(RunRoot + TEXT("/stage/"), ESearchCase::IgnoreCase));
        if (Out.bEveryEvaluatedCheckPassed) RunTwoInputs(Out);
        // RunTwoInputs retained no FDocument, result, input view or task.
        Out.Check(TEXT("L01"), TEXT("Both-input parser result/input/survivor scopes reached their completed milestone before publication"), Out.bParserScopeCompleted);
        Out.Check(TEXT("L02"), TEXT("Exactly BAD then GOOD once each"), Out.AttemptIds == TArray<FString>{TEXT("A1G_BAD"), TEXT("A1G_GOOD")});
        const TArray<FString> Expected = ExpectedIds();
        const bool bComplete = Out.Ids == Expected && Out.Ids.Num() == 52;
        const bool bPassed = Out.bEveryEvaluatedCheckPassed && bComplete;

        TSharedRef<FJsonObject> Report = MakeShared<FJsonObject>();
        Report->SetNumberField(TEXT("schemaVersion"), 1);
        Report->SetStringField(TEXT("kind"), TEXT("E04_A1G_GAME_CALLER_RESULT"));
        Report->SetStringField(TEXT("status"), bPassed ? TEXT("PASS") : TEXT("FAIL"));
        Report->SetStringField(TEXT("runId"), RunId);
        Report->SetStringField(TEXT("sourceHead"), SourceHead);
        Report->SetStringField(TEXT("compiledTargetGuard"), TEXT("WarhammerClientE04A1G/Game/Win64/x64/Development"));
        Report->SetStringField(TEXT("appNameObservation"), FApp::GetName());
        Report->SetStringField(TEXT("actualExecutablePath"), ActualBinary);
        Report->SetStringField(TEXT("expectedExecutableSha256FromSupervisor"), ArgBinarySha);
        Report->SetStringField(TEXT("binaryHashScope"), TEXT("EXPECTED_BINDING_ONLY_ROOT_MUST_REHASH_ACTUAL_BINARY_AND_MATCH_RECEIPT_STAGE"));
        Report->SetNumberField(TEXT("pid"), FPlatformProcess::GetCurrentProcessId());
        Report->SetStringField(TEXT("resultPath"), ResultPath);
        Report->SetStringField(TEXT("callback"), TEXT("OnFEngineLoopInitComplete"));
        Report->SetNumberField(TEXT("callbackInvocationCount"), 1);
        Report->SetNumberField(TEXT("attemptCount"), Out.AttemptIds.Num());
        Report->SetNumberField(TEXT("expectedCheckCount"), 52);
        Report->SetNumberField(TEXT("evaluatedCheckCount"), Out.Ids.Num());
        Report->SetBoolField(TEXT("completeOrderedCheckSet"), bComplete);
        Report->SetBoolField(TEXT("parserValuesDestroyedBeforePublication"), Out.bParserScopeCompleted);
        Report->SetBoolField(TEXT("callerCppUnwindDefined"), false);
        Report->SetNumberField(TEXT("callerPlatformExceptionsDisabled"), PLATFORM_EXCEPTIONS_DISABLED);
        Report->SetStringField(TEXT("actualCompileFlagEvidence"), TEXT("REQUIRES_SEPARATE_TERMINAL_CALLER_AND_PARSER_BUILD_RECORDS"));
        Report->SetArrayField(TEXT("checks"), Out.Checks);
        Report->SetArrayField(TEXT("attempts"), Out.Attempts);
        Report->SetStringField(TEXT("specialAssuranceCertification"), TEXT("DEFERRED_UNPROVEN_OWN17"));
        Report->SetStringField(TEXT("completedUtc"), FDateTime::UtcNow().ToIso8601());
        const bool bPublished = PublishNew(ResultPath, Report);
        if (bPublished)
        {
            UE_LOG(LogE04A1G, Display, TEXT("E04_A1G_TERMINAL status=%s run=%s attempts=%d checks=%d result=%s"), bPassed ? TEXT("PASS") : TEXT("FAIL"), *RunId, Out.AttemptIds.Num(), Out.Ids.Num(), *ResultPath);
        }
        else
        {
            UE_LOG(LogE04A1G, Error, TEXT("Result publication failed; no terminal proof marker; preserve partial output"));
        }
        // Windows may still return EngineInit's zero from this callback. The
        // consumer must independently reject absent/invalid/FAIL result files.
        FPlatformMisc::RequestExitWithStatus(false, bPassed && bPublished ? 0 : 1, TEXT("E04_A1G_PROOF_COMPLETE"));
    }
};

IMPLEMENT_MODULE(FE04ProfileGameProbeModule, E04ProfileGameProbe)
