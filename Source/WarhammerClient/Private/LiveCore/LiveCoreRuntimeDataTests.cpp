#include "LiveCore/LiveCoreRuntimeData.h"

#if WITH_DEV_AUTOMATION_TESTS

#include "WarhammerClientGameMode.h"
#include "Dom/JsonObject.h"
#include "Engine/Engine.h"
#include "Engine/StaticMesh.h"
#include "Engine/World.h"
#include "HAL/FileManager.h"
#include "Materials/MaterialInterface.h"
#include "Misc/AutomationTest.h"
#include "Misc/ConfigCacheIni.h"
#include "Misc/FileHelper.h"
#include "Misc/PackageName.h"
#include "Misc/Paths.h"
#include "Misc/ScopeExit.h"
#include "UObject/Package.h"

namespace
{
constexpr EAutomationTestFlags DataFlags = EAutomationTestFlags_ApplicationContextMask | EAutomationTestFlags::EngineFilter;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FLiveCoreRuntimeFixtureTest, "Warhammer.RuntimeData.CanonicalSession", DataFlags)
bool FLiveCoreRuntimeFixtureTest::RunTest(const FString&)
{
    TSharedPtr<FJsonObject> Payload; FString Error;
    const FString Path = LiveCoreRuntimeData::CanonicalSessionCreatePath();
    TestTrue(TEXT("Canonical data resolves within this runtime Content directory"), Path.StartsWith(FPaths::ProjectContentDir()));
    if (!TestTrue(TEXT("Pinned session-create bytes load through UFS without a tests directory"),
        LiveCoreRuntimeData::ReadCanonicalSessionCreate(Path, Payload, Error))) { return false; }
    TestTrue(TEXT("Successful load clears diagnostic"), Error.IsEmpty());
    TestEqual(TEXT("Canonical payload schema"), Payload->GetStringField(TEXT("schema_version")), FString(TEXT("session-create-v4")));
    TestTrue(TEXT("Canonical payload retains its Core config"), Payload->GetObjectField(TEXT("config")).IsValid());
    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FLiveCoreMissingRuntimeFixtureTest, "Warhammer.RuntimeData.MissingSessionFails", DataFlags)
bool FLiveCoreMissingRuntimeFixtureTest::RunTest(const FString&)
{
    const FString Missing = FPaths::Combine(FPaths::ProjectSavedDir(),
        TEXT("missing-runtime-data-") + FGuid::NewGuid().ToString(EGuidFormats::Digits) + TEXT(".json"));
    TSharedPtr<FJsonObject> Payload = MakeShared<FJsonObject>(); FString Error;
    TestFalse(TEXT("Missing runtime data is a visible local failure"), LiveCoreRuntimeData::ReadCanonicalSessionCreate(Missing, Payload, Error));
    TestFalse(TEXT("No previous payload survives a missing-data failure"), Payload.IsValid());
    TestTrue(TEXT("Missing-data diagnostic identifies runtime data"), Error.Contains(TEXT("runtime session-create data is missing or unreadable")));
    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FLiveCoreCorruptRuntimeFixtureTest, "Warhammer.RuntimeData.CorruptSessionFails", DataFlags)
bool FLiveCoreCorruptRuntimeFixtureTest::RunTest(const FString&)
{
    TArray<uint8> Bytes;
    if (!TestTrue(TEXT("Load the actual runtime file for the corruption control"),
        FFileHelper::LoadFileToArray(Bytes, *LiveCoreRuntimeData::CanonicalSessionCreatePath())) || Bytes.IsEmpty()) { return false; }
    const FString Path = FPaths::Combine(FPaths::ProjectSavedDir(),
        TEXT("runtime-data-corrupt-") + FGuid::NewGuid().ToString(EGuidFormats::Digits) + TEXT(".json"));
    ON_SCOPE_EXIT { TestTrue(TEXT("Remove only this test's temporary file"), IFileManager::Get().Delete(*Path, false)); };
    if (!TestTrue(TEXT("Runtime Saved directory is writable"), IFileManager::Get().MakeDirectory(*FPaths::ProjectSavedDir(), true))) { return false; }
    // Keep the length unchanged so the portable checksum, rather than size alone,
    // must reject the actual file read. The shipped Content file is never edited.
    Bytes[Bytes.Num() / 2] ^= 1;
    if (!TestTrue(TEXT("Write the isolated corruption control"), FFileHelper::SaveArrayToFile(Bytes, *Path))) { return false; }
    TSharedPtr<FJsonObject> Payload = MakeShared<FJsonObject>(); FString Error;
    TestFalse(TEXT("Changed bytes cannot be submitted as a canonical session"), LiveCoreRuntimeData::ReadCanonicalSessionCreate(Path, Payload, Error));
    TestFalse(TEXT("No previous payload survives checksum failure"), Payload.IsValid());
    TestEqual(TEXT("Original checksum-failure diagnostic is preserved"), Error,
        FString(TEXT("Canonical session-create fixture checksum differs from the selected Core fixture.")));
    Bytes.Pop();
    if (!TestTrue(TEXT("Write the isolated truncation control"), FFileHelper::SaveArrayToFile(Bytes, *Path))) { return false; }
    TestFalse(TEXT("Truncated data also fails closed"), LiveCoreRuntimeData::ReadCanonicalSessionCreate(Path, Payload, Error));
    TestFalse(TEXT("Truncation cannot publish a payload"), Payload.IsValid());
    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FLiveCoreRuntimeResourcesTest, "Warhammer.RuntimeData.StartupResources",
    EAutomationTestFlags::ClientContext | EAutomationTestFlags::EngineFilter)
bool FLiveCoreRuntimeResourcesTest::RunTest(const FString&)
{
    FString Map, Mode;
    TestTrue(TEXT("Runtime startup map is configured"), GConfig && GConfig->GetString(TEXT("/Script/EngineSettings.GameMapsSettings"), TEXT("GameDefaultMap"), Map, GEngineIni));
    TestTrue(TEXT("Runtime GameMode is configured"), GConfig && GConfig->GetString(TEXT("/Script/EngineSettings.GameMapsSettings"), TEXT("GlobalDefaultGameMode"), Mode, GEngineIni));
    TestEqual(TEXT("Configured map remains the current client Entry map"), Map, FString(TEXT("/Engine/Maps/Entry")));
    TestEqual(TEXT("Configured GameMode remains the ordinary live client"), Mode, FString(TEXT("/Script/WarhammerClient.WarhammerClientGameMode")));
    TestTrue(TEXT("Startup map package is present in this runtime"), FPackageName::DoesPackageExist(TEXT("/Engine/Maps/Entry")));
    UStaticMesh* Cube = LoadObject<UStaticMesh>(nullptr, TEXT("/Engine/BasicShapes/Cube.Cube"));
    UStaticMesh* Cylinder = LoadObject<UStaticMesh>(nullptr, TEXT("/Engine/BasicShapes/Cylinder.Cylinder"));
    UMaterialInterface* Material = LoadObject<UMaterialInterface>(nullptr, TEXT("/Engine/BasicShapes/BasicShapeMaterial.BasicShapeMaterial"));
    TestNotNull(TEXT("Dynamically loaded Cube is available"), Cube);
    TestNotNull(TEXT("Dynamically loaded Cylinder is available"), Cylinder);
    if (TestNotNull(TEXT("Dynamically loaded display material is available"), Material))
    {
        TArray<FMaterialParameterInfo> Parameters; TArray<FGuid> Ids;
        Material->GetAllVectorParameterInfo(Parameters, Ids);
        TestTrue(TEXT("Display material retains the client's required Color parameter"),
            Parameters.ContainsByPredicate([](const FMaterialParameterInfo& P) { return P.Name == TEXT("Color"); }));
    }
    // Installed CoreStyle uses these runtime Slate fonts; Slate.Build.cs declares
    // their UFS runtime dependencies. Reading bytes proves availability only.
    for (const TCHAR* Font : { TEXT("Roboto-Regular.ttf"), TEXT("Roboto-Bold.ttf"), TEXT("DroidSansFallback.ttf") })
    {
        TArray<uint8> FontBytes;
        const FString FontPath = FPaths::Combine(FPaths::EngineContentDir(), TEXT("Slate/Fonts"), Font);
        TestTrue(FString::Printf(TEXT("Required runtime Slate font bytes are readable: %s"), Font),
            FFileHelper::LoadFileToArray(FontBytes, *FontPath) && !FontBytes.IsEmpty());
    }
    bool bLiveStartup = false;
    if (GEngine)
    {
        for (const FWorldContext& Context : GEngine->GetWorldContexts())
        {
            UWorld* World = Context.World();
            const auto* GameMode = World && World->IsGameWorld() ? World->GetAuthGameMode() : nullptr;
            bLiveStartup |= GameMode && GameMode->GetClass() == AWarhammerClientGameMode::StaticClass() &&
                World->GetOutermost()->GetName().Equals(TEXT("/Engine/Maps/Entry"), ESearchCase::CaseSensitive);
        }
    }
    TestTrue(TEXT("Actual current game world uses Entry and the ordinary live GameMode"), bLiveStartup);
    AddInfo(TEXT("Runtime data/assets/font bytes/config/world check only; NullRHI success does not verify shader execution, text rendering, board or interaction fidelity."));
    return true;
}

#endif
