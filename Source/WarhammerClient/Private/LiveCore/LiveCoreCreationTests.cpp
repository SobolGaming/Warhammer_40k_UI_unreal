#include "LiveCore/LiveCoreSession.h"

#if WITH_DEV_AUTOMATION_TESTS

#include "Misc/AutomationTest.h"
#include "Migration/CoreBoundaryEvidence.h"
#include "Dom/JsonObject.h"
#include "HAL/PlatformMisc.h"
#include "HttpModule.h"
#include "Interfaces/IHttpRequest.h"
#include "Misc/FileHelper.h"
#include "Misc/Paths.h"
#include "Serialization/JsonSerializer.h"

struct FOpenRequestAttempt
{
    FString Verb;
    FString Path;
    bool bMutation;
    bool bAdministrator;
};

struct FLiveCoreSessionCreationTestAccess
{
    static void BlockRequests(FLiveCoreSession& Client, int32& Count)
    {
        Client.RequestAttemptForTests = [&Count](const FString&, const FString&, bool, bool) { ++Count; };
    }
    static void RecordAndBlockRequests(FLiveCoreSession& Client, TArray<FOpenRequestAttempt>& Attempts)
    {
        Client.RequestAttemptForTests = [&Attempts](const FString& Verb, const FString& Path, bool bMutation, bool bAdministrator)
        { Attempts.Add({Verb, Path, bMutation, bAdministrator}); };
    }
    static FLiveCoreState& MutableState(FLiveCoreSession& Client) { return Client.State; }
    static void RetainPending(FLiveCoreSession& Client)
    {
        FLiveCoreSession::FPendingCommand Command;
        Command.Body = TEXT("retained-exact-command"); Command.Id = TEXT("retained-id");
        Command.Operation = TEXT("submit_finite_decision"); Command.ExpectedRevision = 7;
        Client.PendingCommand = MoveTemp(Command);
    }
    static bool HasExactRetainedCommand(const FLiveCoreSession& Client)
    {
        return Client.PendingCommand.IsSet() && Client.PendingCommand->Body == TEXT("retained-exact-command") &&
            Client.PendingCommand->Id == TEXT("retained-id") && Client.PendingCommand->ExpectedRevision == 7;
    }
    static bool HasNoAdminCredential(const FLiveCoreSession& Client) { return Client.AdministratorToken.IsEmpty(); }
    static void ExistingReply(FLiveCoreSession& Client, int32 Status, const FString& Body, const FString& ExpectedSessionId)
    { Client.HandleExistingReply(Status, Body, ExpectedSessionId); }
    static void CheckRequestBlocker(FLiveCoreSession& Client)
    {
        Client.Request(TEXT("GET"), TEXT("/test-must-not-be-sent"),
            FLiveCoreSession::ECredential::Administrator, FString(), false,
            [](int32, const FString&) {});
    }
    static void CreationReply(FLiveCoreSession& Client, int32 Status, const FString& Body)
    {
        Client.HandleCreateReply(Status, Body);
    }
    static void ProjectionReply(FLiveCoreSession& Client, int32 Status, const FString& Body)
    { Client.HandleProjectionReply(Status, Body); }
    static void SeedPrivateDisplay(FLiveCoreSession& Client)
    {
        auto& State = Client.State; State.Endpoint = TEXT("http://127.0.0.1:8765");
        State.bHasSession = true; State.SessionId = TEXT("session-synthetic-handoff"); State.SessionRevision = 2;
        State.ProjectionRevision = 2; State.ProjectionVersion = 7; State.ViewerPlayerId = TEXT("player-a");
        State.Phase = TEXT("old-private-phase"); State.RequestId = TEXT("old-private-request");
        State.RequestType = TEXT("old-private-type"); State.MissionSummary = TEXT("old-private-missions");
        State.Error = TEXT("old-private-error"); State.RecordedCommandError = State.Error;
        State.bLastCommandHasOutcome = true; State.bLastCommandAccepted = true; State.bLastCommandCommitted = true;
        State.LastOutcomeCode = TEXT("old-private-outcome"); State.AcceptedActionCount = 9;
        State.LastHttpStatus = 200; State.BoardBoundsInches = FBox2D(FVector2D(0, 0), FVector2D(44, 60));
        State.Terrain.AddDefaulted(); State.Objectives.AddDefaulted(); State.Models.AddDefaulted(); State.Options.AddDefaulted();
        State.bHasPublicArmyRosters = true; State.PublicArmyRosters.AddDefaulted();
        Client.AdministratorToken = TEXT("synthetic-admin"); Client.PlayerToken = TEXT("synthetic-player");
    }
    static bool CredentialsCleared(const FLiveCoreSession& Client)
    { return Client.AdministratorToken.IsEmpty() && Client.PlayerToken.IsEmpty(); }
    static bool UsesPlayerBCredential(const FLiveCoreSession& Client)
    { return Client.PlayerToken == FPlatformMisc::GetEnvironmentVariable(TEXT("WH_CORE_PLAYER_B_TOKEN")) && Client.AdministratorToken.IsEmpty(); }
    static uint64 CurrentGeneration(const FLiveCoreSession& Client) { return Client.Generation; }
    static bool ReplyMatchesGeneration(FLiveCoreSession& Client, uint64 Generation)
    {
        auto Request = FHttpModule::Get().CreateRequest(); Client.ActiveRequest = Request;
        const bool Accepted = Client.IsCurrentReply(Generation, Request); Client.ActiveRequest.Reset(); return Accepted;
    }
    static void SetUnsentActiveRequest(FLiveCoreSession& Client)
    { Client.ActiveRequest = FHttpModule::Get().CreateRequest(); }
};

namespace
{
constexpr EAutomationTestFlags CreationFlags = EAutomationTestFlags_ApplicationContextMask | EAutomationTestFlags::EngineFilter;

class FScopedOpenCredentials
{
public:
    FScopedOpenCredentials()
        : Administrator(FPlatformMisc::GetEnvironmentVariable(TEXT("WH_CORE_ADMIN_TOKEN"))),
          Player(FPlatformMisc::GetEnvironmentVariable(TEXT("WH_CORE_PLAYER_TOKEN"))),
          PlayerB(FPlatformMisc::GetEnvironmentVariable(TEXT("WH_CORE_PLAYER_B_TOKEN")))
    {
        FPlatformMisc::SetEnvironmentVar(TEXT("WH_CORE_ADMIN_TOKEN"), TEXT("synthetic-unused-admin"));
        FPlatformMisc::SetEnvironmentVar(TEXT("WH_CORE_PLAYER_TOKEN"), TEXT("synthetic-open-player"));
        FPlatformMisc::SetEnvironmentVar(TEXT("WH_CORE_PLAYER_B_TOKEN"), TEXT("synthetic-handoff-player-b"));
    }
    ~FScopedOpenCredentials()
    {
        FPlatformMisc::SetEnvironmentVar(TEXT("WH_CORE_ADMIN_TOKEN"), *Administrator);
        FPlatformMisc::SetEnvironmentVar(TEXT("WH_CORE_PLAYER_TOKEN"), *Player);
        FPlatformMisc::SetEnvironmentVar(TEXT("WH_CORE_PLAYER_B_TOKEN"), *PlayerB);
    }
private:
    FString Administrator;
    FString Player;
    FString PlayerB;
};

bool DisplayClearedForHandoff(const FLiveCoreState& Value)
{
    return Value.bHandoffPending && !Value.bHasSession && Value.SessionId.IsEmpty() && Value.ViewerPlayerId.IsEmpty() &&
        Value.Endpoint.IsEmpty() && Value.Phase.IsEmpty() && Value.RequestId.IsEmpty() && Value.RequestType.IsEmpty() &&
        Value.MissionSummary.IsEmpty() && Value.RecordedCommandError.IsEmpty() && Value.LastOutcomeCode.IsEmpty() &&
        !Value.bLastCommandHasOutcome && !Value.bLastCommandAccepted && !Value.bLastCommandCommitted && Value.AcceptedActionCount == 0 &&
        Value.SessionRevision == -1 && Value.ProjectionRevision == -1 && Value.ProjectionVersion == 0 &&
        !Value.BoardBoundsInches.bIsValid && Value.Terrain.IsEmpty() && Value.Objectives.IsEmpty() && Value.Models.IsEmpty() &&
        Value.Options.IsEmpty() && !Value.bHasPublicArmyRosters && Value.PublicArmyRosters.IsEmpty() &&
        Value.DecisionPresentation == ELiveCoreDecisionPresentation::Unavailable;
}

bool LoadActivePlayerMetadata(FAutomationTestBase& Test, FString& Out, FString& SessionId)
{
    FString Text;
    const FString Path = FPaths::Combine(FPaths::ProjectDir(),
        TEXT("tests/migration/fixtures/4f9bef0df2fb974d1285232a1009b8781926361d/contracts/examples/sessions/session-metadata-created.json"));
    if (!FFileHelper::LoadFileToString(Text, *Path)) { Test.AddError(TEXT("Selected metadata control is unavailable.")); return false; }
    Warhammer::Migration::E01::FReadError Error; TSharedPtr<FJsonObject> Root;
    if (!Warhammer::Migration::E01::ParseObject(Text, Root, Error)) { Test.AddError(TEXT("Selected metadata control is invalid.")); return false; }
    SessionId = Root->GetStringField(TEXT("session_id"));
    Root->SetStringField(TEXT("session_state"), TEXT("active")); Root->SetNumberField(TEXT("session_revision"), 1);
    const auto Visibility = Root->GetObjectField(TEXT("visibility"));
    Visibility->SetStringField(TEXT("role"), TEXT("player")); Visibility->SetStringField(TEXT("player_id"), TEXT("player-a"));
    Visibility->SetNumberField(TEXT("delay_revisions"), 0); Visibility->SetBoolField(TEXT("may_mutate_lifecycle"), false);
    Visibility->SetBoolField(TEXT("may_submit_decision"), true); Visibility->SetBoolField(TEXT("omniscient"), false);
    const auto Writer = TJsonWriterFactory<>::Create(&Out); FJsonSerializer::Serialize(Root.ToSharedRef(), Writer);
    Test.AddInfo(TEXT("Synthetic callback control derives active player metadata from the selected committed example; no real service is contacted."));
    return true;
}
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FLiveCoreInvalidCreateEndpointTest,
    "Warhammer.LiveCore.Unit.Creation.InvalidEndpointDoesNotRequest", CreationFlags)
bool FLiveCoreInvalidCreateEndpointTest::RunTest(const FString& Parameters)
{
    int32 Requests = 0;
    const TSharedRef<FLiveCoreSession> Client = FLiveCoreSession::Create();
    FLiveCoreSessionCreationTestAccess::BlockRequests(Client.Get(), Requests);
    FLiveCoreSessionCreationTestAccess::CheckRequestBlocker(Client.Get());
    TestEqual(TEXT("Test seam intercepts before HTTP, credentials or busy state"), Requests, 1);
    TestFalse(TEXT("Intercepted request did not enter busy state"), Client->GetState().bBusy);
    Requests = 0;
    Client->InitializeEndpoint(TEXT("http://127.0.0.1:8765"));
    FString Validated, ExpectedDiagnostic;
    TestFalse(TEXT("Invalid requested endpoint is rejected"),
        LiveCoreProtocol::ValidateEndpoint(TEXT("http://example.com:8765"), Validated, ExpectedDiagnostic));
    Client->CreateAndStart(TEXT("http://example.com:8765"));
    TestEqual(TEXT("Invalid creation sends zero requests to the prior valid endpoint"), Requests, 0);
    TestEqual(TEXT("Exact validation diagnostic survives"), Client->GetState().Error, ExpectedDiagnostic);
    TestEqual(TEXT("Existing endpoint is not silently used"), Client->GetState().Endpoint, FString(TEXT("http://127.0.0.1:8765")));
    TestFalse(TEXT("Invalid creation is not busy"), Client->GetState().bBusy);
    TestFalse(TEXT("Invalid local input did not create a session"), Client->GetState().bHasSession);
    TestFalse(TEXT("Local validation failure is not a sent mutation"), Client->GetState().bUnknown);
    Client->Shutdown();
    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FLiveCoreCreationErrorUnknownTest,
    "Warhammer.LiveCore.Unit.Creation.ErrorEnvelopeRemainsUnknown", CreationFlags)
bool FLiveCoreCreationErrorUnknownTest::RunTest(const FString& Parameters)
{
    const FString Body(TEXT("{\"schema_version\":\"error-envelope-v1\",\"error\":{\"code\":\"creation_transport_error\",\"message\":\"Actual Core creation diagnostic\"}}"));
    for (int32 Status : {400, 401, 403, 409, 422, 500, 503})
    {
        int32 Requests = 0;
        const TSharedRef<FLiveCoreSession> Client = FLiveCoreSession::Create();
        FLiveCoreSessionCreationTestAccess::BlockRequests(Client.Get(), Requests);
        Client->InitializeEndpoint(TEXT("http://127.0.0.1:8765"));
        FLiveCoreSessionCreationTestAccess::CreationReply(Client.Get(), Status, Body);
        const auto& State = Client->GetState();
        TestTrue(TEXT("Flagless creation errors remain UNKNOWN for 4xx and 5xx"), State.bUnknown);
        TestFalse(TEXT("Creation has no command identity for reconciliation"), State.bCanReconcile);
        TestFalse(TEXT("No created session identity was supplied"), State.bHasSession);
        TestFalse(TEXT("Closed unknown creation is not busy"), State.bBusy);
        TestEqual(TEXT("Actual HTTP status retained"), State.LastHttpStatus, Status);
        TestTrue(TEXT("Error displays actual HTTP"), State.Error.Contains(FString::Printf(TEXT("HTTP %d"), Status)));
        TestTrue(TEXT("Actual Core code retained"), State.Error.Contains(TEXT("creation_transport_error")));
        TestTrue(TEXT("Actual Core message retained"), State.Error.Contains(TEXT("Actual Core creation diagnostic")));
        const FString OriginalError = State.Error;
        Client->NewSession();
        Client->CreateAndStart(TEXT("http://127.0.0.1:8765"));
        Client->ReconcileUnknown();
        TestEqual(TEXT("No recreation or command retry after unknown creation"), Requests, 0);
        TestTrue(TEXT("Unknown disposition survives blocked actions"), Client->GetState().bUnknown);
        TestEqual(TEXT("Original diagnostic survives blocked actions"), Client->GetState().Error, OriginalError);
        Client->Shutdown();
    }
    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FLiveCoreInvalidOpenInputTest,
    "Warhammer.LiveCore.Unit.Open.InvalidInputDoesNotRequest", CreationFlags)
bool FLiveCoreInvalidOpenInputTest::RunTest(const FString& Parameters)
{
    int32 Requests = 0;
    const auto Client = FLiveCoreSession::Create();
    FLiveCoreSessionCreationTestAccess::BlockRequests(Client.Get(), Requests);
    Client->InitializeEndpoint(TEXT("http://127.0.0.1:8765"));
    for (const TCHAR* Id : {TEXT(""), TEXT(" "), TEXT("."), TEXT(".."), TEXT("id/path"), TEXT("id%2fpath"), TEXT("id?query"), TEXT("id#fragment"), TEXT(" id"), TEXT("id "), TEXT("id\r\nheader")})
    {
        Client->OpenExistingSession(TEXT("http://127.0.0.1:8765"), Id);
        TestEqual(TEXT("Invalid session ID sends no HTTP attempt"), Requests, 0);
        TestFalse(TEXT("Invalid input does not attach or create uncertainty"), Client->GetState().bHasSession || Client->GetState().bUnknown);
    }
    Client->OpenExistingSession(TEXT("http://example.com:8765"), TEXT("session-safe"));
    TestEqual(TEXT("Invalid requested endpoint sends no request to prior valid endpoint"), Requests, 0);
    TestEqual(TEXT("Prior endpoint is not silently replaced or used"), Client->GetState().Endpoint, FString(TEXT("http://127.0.0.1:8765")));
    FString Error;
    TestTrue(TEXT("A literal Core-style session identifier is supported"), LiveCoreProtocol::ValidateSessionId(TEXT("session-a:b.1_2-3"), Error));
    TestTrue(TEXT("A bounded literal ID is accepted"), LiveCoreProtocol::ValidateSessionId(FString::ChrN(256, TEXT('a')), Error));
    TestFalse(TEXT("Overlong ID is refused"), LiveCoreProtocol::ValidateSessionId(FString::ChrN(257, TEXT('a')), Error));
    FScopedOpenCredentials Credentials;
    FPlatformMisc::SetEnvironmentVar(TEXT("WH_CORE_PLAYER_TOKEN"), TEXT(""));
    Client->OpenExistingSession(TEXT("http://127.0.0.1:8765"), TEXT("session-safe"));
    TestEqual(TEXT("An administrator credential is not a fallback for the player read"), Requests, 0);
    TestTrue(TEXT("Missing player credential is explained"), Client->GetState().Error.Contains(TEXT("WH_CORE_PLAYER_TOKEN")));
    Client->Shutdown(); return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FLiveCoreOpenReadOnlyFlowTest,
    "Warhammer.LiveCore.Unit.Open.ReadOnlyFlowAndErrors", CreationFlags)
bool FLiveCoreOpenReadOnlyFlowTest::RunTest(const FString& Parameters)
{
    FScopedOpenCredentials Credentials;
    FString Metadata, SessionId;
    if (!LoadActivePlayerMetadata(*this, Metadata, SessionId)) { return false; }
    TArray<FOpenRequestAttempt> Attempts;
    const auto Client = FLiveCoreSession::Create();
    FLiveCoreSessionCreationTestAccess::RecordAndBlockRequests(Client.Get(), Attempts);
    const FString ErrorBody(TEXT("{\"schema_version\":\"error-envelope-v1\",\"error\":{\"code\":\"session_not_found\",\"message\":\"Session was not found.\"}}"));
    for (int32 Status : {401, 403, 404, 500})
    {
        Client->OpenExistingSession(TEXT("http://127.0.0.1:8765"), SessionId);
        FLiveCoreSessionCreationTestAccess::ExistingReply(Client.Get(), Status, ErrorBody, SessionId);
        const auto& Value = Client->GetState();
        TestEqual(TEXT("Actual metadata read HTTP status is retained"), Value.LastHttpStatus, Status);
        TestTrue(TEXT("Actual service code and message are retained"), Value.Error.Contains(TEXT("session_not_found")) && Value.Error.Contains(TEXT("Session was not found.")));
        TestFalse(TEXT("A failed GET is not an unknown mutation"), Value.bUnknown || Value.bCanReconcile);
        TestTrue(TEXT("Failed metadata publishes no attached identity, projection or choices"), !Value.bHasSession && Value.SessionId.IsEmpty() &&
            Value.ProjectionVersion == 0 && Value.Options.IsEmpty() && !Value.bHasPublicArmyRosters && Value.PublicArmyRosters.IsEmpty());
    }
    Attempts.Reset();
    Client->OpenExistingSession(TEXT("http://127.0.0.1:8765"), SessionId);
    if (!TestEqual(TEXT("Opening begins with exactly one metadata read"), Attempts.Num(), 1)) { return false; }
    TestEqual(TEXT("Metadata method"), Attempts[0].Verb, FString(TEXT("GET")));
    TestEqual(TEXT("Exact requested metadata route"), Attempts[0].Path, TEXT("/sessions/") + SessionId);
    TestFalse(TEXT("Opening metadata read is not a mutation or admin request"), Attempts[0].bMutation || Attempts[0].bAdministrator);
    TestTrue(TEXT("Opening does not retain the environment's administrator credential"), FLiveCoreSessionCreationTestAccess::HasNoAdminCredential(Client.Get()));
    FLiveCoreSessionCreationTestAccess::ExistingReply(Client.Get(), 200, Metadata, SessionId);
    if (!TestEqual(TEXT("Validated metadata triggers only the player projection read"), Attempts.Num(), 2)) { return false; }
    TestEqual(TEXT("Projection method"), Attempts[1].Verb, FString(TEXT("GET")));
    TestEqual(TEXT("Projection route binds the verified session"), Attempts[1].Path, TEXT("/sessions/") + SessionId + TEXT("/projection"));
    TestFalse(TEXT("Projection read is not a mutation or admin request"), Attempts[1].bMutation || Attempts[1].bAdministrator);
    TestTrue(TEXT("Verified metadata establishes an attached session"), Client->GetState().bHasSession);
    TestEqual(TEXT("Metadata establishes the projection's minimum revision"), Client->GetState().SessionRevision, int64(1));
    TestEqual(TEXT("Metadata is not a successfully applied projection"), Client->GetState().ProjectionVersion, uint64(0));
    TestEqual(TEXT("Opening invents no accepted action history"), Client->GetState().AcceptedActionCount, 0);
    TestFalse(TEXT("Opening invents no previous command outcome"), Client->GetState().bLastCommandHasOutcome);
    for (const auto& Attempt : Attempts)
    { TestTrue(TEXT("The complete reopen path contains no catalog, create or command operation"), Attempt.Verb == TEXT("GET") && !Attempt.bMutation && !Attempt.bAdministrator); }
    Client->Shutdown(); return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FLiveCoreOpenGuardTest,
    "Warhammer.LiveCore.Unit.Open.PreservesCurrentOrUnknownSession", CreationFlags)
bool FLiveCoreOpenGuardTest::RunTest(const FString& Parameters)
{
    for (int32 Case = 0; Case < 6; ++Case)
    {
        int32 Requests = 0;
        const auto Client = FLiveCoreSession::Create();
        FLiveCoreSessionCreationTestAccess::BlockRequests(Client.Get(), Requests);
        auto& Value = FLiveCoreSessionCreationTestAccess::MutableState(Client.Get());
        Value.Error = TEXT("retained-diagnostic"); Value.RequestId = TEXT("retained-request"); Value.SessionRevision = 7;
        if (Case == 0) { Value.bBusy = true; }
        if (Case == 1) { Value.bUnknown = true; } // uncertain creation, without a command identity
        if (Case == 2) { Value.bHasSession = true; Value.SessionId = TEXT("session-current"); }
        if (Case == 3 || Case == 4) { FLiveCoreSessionCreationTestAccess::RetainPending(Client.Get()); }
        if (Case == 4) { Value.bUnknown = true; Value.bCanReconcile = true; }
        if (Case == 5) { Client->Shutdown(); }
        Client->OpenExistingSession(TEXT("http://127.0.0.1:8765"), TEXT("session-other"));
        TestEqual(TEXT("Busy, attached, pending, unknown or stopped clients send no reopen request"), Requests, 0);
        TestEqual(TEXT("Blocked open preserves the prior diagnostic"), Value.Error, FString(TEXT("retained-diagnostic")));
        TestEqual(TEXT("Blocked open preserves the offered or retained request identity"), Value.RequestId, FString(TEXT("retained-request")));
        TestEqual(TEXT("Blocked open preserves authoritative revision"), Value.SessionRevision, int64(7));
        if (Case == 3 || Case == 4)
        { TestTrue(TEXT("Exact retained command is not discarded to open another session"), FLiveCoreSessionCreationTestAccess::HasExactRetainedCommand(Client.Get())); }
        Client->Shutdown();
    }
    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FLiveCoreHandoffClearAndGuardTest,
    "Warhammer.LiveCore.Unit.Handoff.ClearAndGuards", CreationFlags)
bool FLiveCoreHandoffClearAndGuardTest::RunTest(const FString& Parameters)
{
    for (int32 Case = 0; Case < 8; ++Case)
    {
        int32 Requests = 0; const auto Client = FLiveCoreSession::Create();
        FLiveCoreSessionCreationTestAccess::SeedPrivateDisplay(Client.Get());
        FLiveCoreSessionCreationTestAccess::BlockRequests(Client.Get(), Requests);
        auto& Value = FLiveCoreSessionCreationTestAccess::MutableState(Client.Get());
        if (Case == 0) { Value.bBusy = true; }
        if (Case == 1) { Value.bUnknown = true; }
        if (Case == 2) { FLiveCoreSessionCreationTestAccess::RetainPending(Client.Get()); }
        if (Case == 3) { Client->Shutdown(); }
        if (Case == 4) { Value.ProjectionVersion = 0; }
        if (Case == 5) { Value.ViewerPlayerId = TEXT("player-c"); }
        if (Case == 6) { Value.bHasSession = false; }
        if (Case == 7) { FLiveCoreSessionCreationTestAccess::SetUnsentActiveRequest(Client.Get()); }
        TestFalse(TEXT("Unsafe or unverified state cannot begin handoff"), Client->CanBeginPlayerHandoff());
        TestFalse(TEXT("Blocked handoff returns no transition"), Client->BeginPlayerHandoff());
        Client->ContinuePlayerHandoff();
        TestEqual(TEXT("Blocked handoff/Ready sends no request"), Requests, 0);
        TestEqual(TEXT("Blocked handoff retains prior private display rather than discarding command context"), Value.MissionSummary, FString(TEXT("old-private-missions")));
        if (Case == 2) { TestTrue(TEXT("Retained uncertain-command bytes survive blocked switching"), FLiveCoreSessionCreationTestAccess::HasExactRetainedCommand(Client.Get())); }
        Client->Shutdown();
    }
    int32 Requests = 0; const auto Client = FLiveCoreSession::Create();
    FLiveCoreSessionCreationTestAccess::SeedPrivateDisplay(Client.Get());
    FLiveCoreSessionCreationTestAccess::BlockRequests(Client.Get(), Requests);
    const uint64 OldGeneration = FLiveCoreSessionCreationTestAccess::CurrentGeneration(Client.Get());
    bool bChangedSawClearedState = false;
    Client->OnChanged.BindLambda([&]() { bChangedSawClearedState = DisplayClearedForHandoff(Client->GetState()); });
    TestTrue(TEXT("Verified idle player can begin handoff"), Client->CanBeginPlayerHandoff());
    TestTrue(TEXT("Begin performs local handoff transition"), Client->BeginPlayerHandoff());
    TestTrue(TEXT("Change notification exposes only the cleared privacy state"), bChangedSawClearedState);
    TestTrue(TEXT("Entire former player snapshot is cleared before Ready"), DisplayClearedForHandoff(Client->GetState()));
    TestEqual(TEXT("Only intended next development player is identified"), Client->GetState().HandoffTargetPlayerId, FString(TEXT("player-b")));
    TestTrue(TEXT("Old player/admin credentials are dropped"), FLiveCoreSessionCreationTestAccess::CredentialsCleared(Client.Get()));
    TestFalse(TEXT("Obsolete callback generation is rejected by actual HTTP completion gate"), FLiveCoreSessionCreationTestAccess::ReplyMatchesGeneration(Client.Get(), OldGeneration));
    TestTrue(TEXT("Current generation/request still matches completion gate"), FLiveCoreSessionCreationTestAccess::ReplyMatchesGeneration(Client.Get(), FLiveCoreSessionCreationTestAccess::CurrentGeneration(Client.Get())));
    Client->CreateAndStart(TEXT("http://127.0.0.1:8765")); Client->NewSession();
    Client->OpenExistingSession(TEXT("http://127.0.0.1:8765"), TEXT("session-other"));
    Client->Refresh(); Client->SubmitOption(TEXT("old-private-option")); Client->ReconcileUnknown();
    TestEqual(TEXT("Begin and all non-Ready actions during curtain send no request"), Requests, 0);
    TestTrue(TEXT("Blocked creation/open/refresh cannot restore prior viewer snapshot"), DisplayClearedForHandoff(Client->GetState()));
    Client->Shutdown(); return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FLiveCoreHandoffRetryTest,
    "Warhammer.LiveCore.Unit.Handoff.ReadFailuresKeepPrivacy", CreationFlags)
bool FLiveCoreHandoffRetryTest::RunTest(const FString& Parameters)
{
    FScopedOpenCredentials Credentials;
    FString MetadataA, SessionId;
    if (!LoadActivePlayerMetadata(*this, MetadataA, SessionId)) { return false; }
    const FString MetadataB = MetadataA.Replace(TEXT("player-a"), TEXT("player-b"));
    FString ProjectionA;
    const FString ProjectionPath = FPaths::Combine(FPaths::ProjectDir(),
        TEXT("tests/migration/fixtures/5f509724da25a2f6ded0c2739a8e7c84bdf59c91/wire/view_initial/playerA.json"));
    if (!FFileHelper::LoadFileToString(ProjectionA, *ProjectionPath)) { AddError(TEXT("Projection parser control is unavailable.")); return false; }
    Warhammer::Migration::E01::FReadError Error; TSharedPtr<FJsonObject> Projection;
    if (!Warhammer::Migration::E01::ParseObject(ProjectionA, Projection, Error)) { AddError(TEXT("Projection parser control is invalid.")); return false; }
    Projection->SetStringField(TEXT("session_id"), SessionId);
    ProjectionA.Reset();
    { const auto Writer = TJsonWriterFactory<>::Create(&ProjectionA); FJsonSerializer::Serialize(Projection.ToSharedRef(), Writer); }
    // These are synthetic callback controls, not a claim about live Core's private fields.
    const FString ProjectionB = ProjectionA.Replace(TEXT("player-a"), TEXT("player-b"));
    TArray<FOpenRequestAttempt> Attempts; const auto Client = FLiveCoreSession::Create();
    FLiveCoreSessionCreationTestAccess::SeedPrivateDisplay(Client.Get());
    FLiveCoreSessionCreationTestAccess::MutableState(Client.Get()).SessionId = SessionId;
    FLiveCoreSessionCreationTestAccess::MutableState(Client.Get()).SessionRevision = 1;
    FLiveCoreSessionCreationTestAccess::MutableState(Client.Get()).ProjectionRevision = 1;
    FLiveCoreSessionCreationTestAccess::RecordAndBlockRequests(Client.Get(), Attempts);
    if (!TestTrue(TEXT("Seeded viewer begins privacy transition"), Client->BeginPlayerHandoff())) { return false; }
    FPlatformMisc::SetEnvironmentVar(TEXT("WH_CORE_PLAYER_B_TOKEN"), TEXT(""));
    Client->ContinuePlayerHandoff();
    TestEqual(TEXT("Missing player-b credential causes zero HTTP; player-a/admin are no fallback"), Attempts.Num(), 0);
    TestTrue(TEXT("Missing credential keeps every prior private value absent"), DisplayClearedForHandoff(Client->GetState()));
    TestTrue(TEXT("Missing credential is named without its value"), Client->GetState().Error.Contains(TEXT("WH_CORE_PLAYER_B_TOKEN")));
    FPlatformMisc::SetEnvironmentVar(TEXT("WH_CORE_PLAYER_B_TOKEN"), TEXT("synthetic-handoff-player-b"));
    const FString HttpError(TEXT("{\"schema_version\":\"error-envelope-v1\",\"error\":{\"code\":\"authentication_required\",\"message\":\"Authentication is required.\"}}"));
    Client->ContinuePlayerHandoff();
    TestTrue(TEXT("Ready retains only player-b credential"), FLiveCoreSessionCreationTestAccess::UsesPlayerBCredential(Client.Get()));
    FLiveCoreSessionCreationTestAccess::ExistingReply(Client.Get(), 401, HttpError, SessionId);
    TestTrue(TEXT("Real-shaped HTTP failure keeps privacy curtain retryable"), DisplayClearedForHandoff(Client->GetState()));
    TestTrue(TEXT("Actual status/code remains visible"), Client->GetState().Error.Contains(TEXT("HTTP 401")) && Client->GetState().Error.Contains(TEXT("authentication_required")));
    Client->ContinuePlayerHandoff();
    FLiveCoreSessionCreationTestAccess::ExistingReply(Client.Get(), 200, MetadataA, SessionId);
    TestTrue(TEXT("Wrong-player metadata cannot publish any prior/new partial state"), DisplayClearedForHandoff(Client->GetState()));
    Attempts.Reset(); Client->ContinuePlayerHandoff();
    FLiveCoreSessionCreationTestAccess::ExistingReply(Client.Get(), 200, MetadataB, SessionId);
    TestTrue(TEXT("Metadata success does not uncover the screen before a validated projection"), DisplayClearedForHandoff(Client->GetState()));
    TestEqual(TEXT("Ready metadata/projection path is exactly two requests"), Attempts.Num(), 2);
    FLiveCoreSessionCreationTestAccess::ProjectionReply(Client.Get(), 200, ProjectionA);
    TestTrue(TEXT("Wrong-player projection leaves the entire display cleared"), DisplayClearedForHandoff(Client->GetState()));
    Attempts.Reset(); Client->ContinuePlayerHandoff();
    FLiveCoreSessionCreationTestAccess::ExistingReply(Client.Get(), 200, MetadataB, SessionId);
    FLiveCoreSessionCreationTestAccess::ProjectionReply(Client.Get(), 200, ProjectionB);
    TestFalse(TEXT("Validated current-player projection releases curtain"), Client->GetState().bHandoffPending);
    TestTrue(TEXT("Recovered snapshot is attached to exactly intended session/viewer"), Client->GetState().bHasSession && Client->GetState().SessionId == SessionId && Client->GetState().ViewerPlayerId == TEXT("player-b"));
    TestEqual(TEXT("Recovered view starts a fresh local count"), Client->GetState().AcceptedActionCount, 0);
    TestEqual(TEXT("Recovered view begins with one new projection delivery"), Client->GetState().ProjectionVersion, uint64(1));
    TestTrue(TEXT("No former command receipt/error is replayed"), !Client->GetState().bLastCommandHasOutcome && Client->GetState().Error.IsEmpty());
    for (const auto& Attempt : Attempts)
    { TestTrue(TEXT("Ready uses only non-admin read attempts"), Attempt.Verb == TEXT("GET") && !Attempt.bMutation && !Attempt.bAdministrator); }
    Client->Shutdown(); return true;
}

#endif
