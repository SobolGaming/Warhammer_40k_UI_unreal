#include "LiveCore/LiveCoreSession.h"

#if WITH_DEV_AUTOMATION_TESTS
#include "HAL/PlatformMisc.h"
#include "HAL/PlatformTime.h"
#include "Misc/AutomationTest.h"

struct FLiveCoreSessionIntegrationTestAccess
{
    static void ObserveRequests(FLiveCoreSession& Client, TFunction<void(const FString&, const FString&, bool, bool)>&& Observer)
    { Client.RequestObserverForTests = MoveTemp(Observer); }
};

namespace
{
// Explicit opt-in: this test creates one disposable session on an existing development
// service. It never starts a host or a rendered world and never logs credentials/state.
class FLiveSessionActionCheck final : public IAutomationLatentCommand
{
public:
    FLiveSessionActionCheck(FAutomationTestBase* InTest, FString InEndpoint, bool bInReopenAfterCreate = false)
        : Test(InTest), Endpoint(MoveTemp(InEndpoint)), Started(FPlatformTime::Seconds()), bReopenAfterCreate(bInReopenAfterCreate) {}

    virtual bool Update() override
    {
        if (!Session.IsValid())
        {
            Session = FLiveCoreSession::Create();
            Session->CreateAndStart(Endpoint);
            return false;
        }
        if (FPlatformTime::Seconds() - Started > 170.0)
        {
            Test->AddError(TEXT("Real Core session/action check exceeded 170 seconds; completion may be unknown."));
            Session->Shutdown();
            return true;
        }
        const FLiveCoreState& State = Session->GetState();
        if (State.bBusy) { return false; }
        if (!State.Error.IsEmpty() || State.bUnknown)
        {
            // The UI retains the actual error; automation records only classification,
            // avoiding private session data in the distributable test log.
            Test->AddError(FString::Printf(TEXT("Real Core check stopped: HTTP %d, unknown=%d, stage=%d"),
                State.LastHttpStatus, State.bUnknown, Step));
            Session->Shutdown();
            return true;
        }
        if (Step == 0)
        {
            if (!Test->TestTrue(TEXT("Created authenticated player session"), State.bHasSession)
                || !Test->TestEqual(TEXT("Initial public decision family"), State.RequestType, FString(TEXT("select_secondary_missions")))
                || !Test->TestTrue(TEXT("Core supplies finite options"), State.Options.Num() > 0))
            {
                Session->Shutdown();
                return true;
            }
            if (bReopenAfterCreate && !bReopened)
            {
                // Keep the separately managed service alive; shutting this client
                // cannot stop it or mutate/close the authoritative session.
                ExistingSessionId = State.SessionId; ExistingRequestId = State.RequestId;
                ExistingRevision = State.SessionRevision; ExistingOptionId = State.Options[0].Id;
                ExistingBounds = State.BoardBoundsInches;
                ExistingTerrainCount = State.Terrain.Num(); ExistingObjectiveCount = State.Objectives.Num();
                ExistingRosterCount = State.PublicArmyRosters.Num(); bExistingRostersAvailable = State.bHasPublicArmyRosters;
                Session->Shutdown(); Session = FLiveCoreSession::Create(); bReopened = true; bObserveOpening = true;
                FLiveCoreSessionIntegrationTestAccess::ObserveRequests(*Session,
                    [this](const FString& Verb, const FString& Path, bool bMutation, bool bAdministrator)
                    {
                        if (!bObserveOpening) { return; }
                        ++OpenRequestAttempts;
                        bUnexpectedOpenRequest |= Verb != TEXT("GET") || bMutation || bAdministrator;
                        if (Path == TEXT("/sessions/") + ExistingSessionId) { ++OpenMetadataAttempts; }
                        else if (Path == TEXT("/sessions/") + ExistingSessionId + TEXT("/projection")) { ++OpenProjectionAttempts; }
                        else { bUnexpectedOpenRequest = true; }
                    });
                Session->OpenExistingSession(Endpoint, ExistingSessionId);
                return false;
            }
            if (bReopened)
            {
                bObserveOpening = false;
                // Private IDs remain in memory; boolean comparisons avoid writing
                // their values into a failed automation assertion/log.
                Test->TestTrue(TEXT("Fresh client reopens the original exact session identity"), State.SessionId == ExistingSessionId);
                Test->TestEqual(TEXT("Read-only reopen changes no authoritative revision"), State.SessionRevision, ExistingRevision);
                Test->TestTrue(TEXT("Reopen retains the original offered request"), State.RequestId == ExistingRequestId);
                Test->TestTrue(TEXT("Reopen retains a Core-offered option ID"), State.Options.ContainsByPredicate(
                    [this](const FLiveCoreOption& Option) { return Option.Id == ExistingOptionId; }));
                Test->TestTrue(TEXT("Reopen restores the actual board bounds"), State.BoardBoundsInches == ExistingBounds);
                Test->TestEqual(TEXT("Reopen restores actual terrain rows"), State.Terrain.Num(), ExistingTerrainCount);
                Test->TestEqual(TEXT("Reopen restores actual objective rows"), State.Objectives.Num(), ExistingObjectiveCount);
                Test->TestEqual(TEXT("Reopen restores current roster availability"), State.bHasPublicArmyRosters, bExistingRostersAvailable);
                Test->TestEqual(TEXT("Reopen restores only supplied roster rows"), State.PublicArmyRosters.Num(), ExistingRosterCount);
                Test->TestEqual(TEXT("Accepted action count starts at zero in the fresh client"), State.AcceptedActionCount, 0);
                Test->TestFalse(TEXT("Reopen fabricates no previous command receipt"), State.bLastCommandHasOutcome);
                Test->TestEqual(TEXT("Exactly two HTTP attempts open the existing session"), OpenRequestAttempts, 2);
                Test->TestEqual(TEXT("One metadata attempt"), OpenMetadataAttempts, 1);
                Test->TestEqual(TEXT("One projection attempt"), OpenProjectionAttempts, 1);
                Test->TestFalse(TEXT("Opening attempted no POST, catalog or administrator request"), bUnexpectedOpenRequest);
            }
            Test->TestEqual(TEXT("Viewer is player-a"), State.ViewerPlayerId, FString(TEXT("player-a")));
            Test->TestTrue(TEXT("Core board has positive dimensions"), State.BoardBoundsInches.bIsValid
                && State.BoardBoundsInches.GetSize().X > 0 && State.BoardBoundsInches.GetSize().Y > 0);
            Test->TestTrue(TEXT("Real terrain parsed"), !State.Terrain.IsEmpty());
            Test->TestTrue(TEXT("Real objectives parsed"), !State.Objectives.IsEmpty());
            Test->TestEqual(TEXT("Undeployed models are not given invented poses"), State.Models.Num(), 0);
            Test->TestEqual(TEXT("Initial rendered DTO matches session revision"), State.ProjectionRevision, State.SessionRevision);
            BeforeProjectionVersion = State.ProjectionVersion;
            const TWeakPtr<FLiveCoreSession> WeakSession = Session;
            Session->OnChanged.BindLambda([this, WeakSession]()
                {
                    if (const auto Observed = WeakSession.Pin())
                    {
                        const auto& Value = Observed->GetState();
                        if (Value.SessionRevision > Value.ProjectionRevision && Value.ProjectionVersion == BeforeProjectionVersion)
                        { bObservedReceiptBeforeProjection = true; }
                    }
                });
            BeforeRevision = State.SessionRevision;
            BeforeRequest = State.RequestId;
            const FString OptionId = State.Options[0].Id;
            Step = 1;
            Session->SubmitOption(OptionId);
            return false;
        }
        if (Step == 1)
        {
            Test->TestTrue(TEXT("Actual async receipt observed before matching projection"), bObservedReceiptBeforeProjection);
            Test->TestEqual(TEXT("New DTO revision catches up to accepted receipt"), State.ProjectionRevision, State.SessionRevision);
            Test->TestTrue(TEXT("Actual applied projection changes render cache version"), State.ProjectionVersion > BeforeProjectionVersion);
            Test->TestEqual(TEXT("Exactly one player action accepted"), State.AcceptedActionCount, 1);
            Test->TestTrue(TEXT("Core returned accepted committed outcome"), State.bLastCommandHasOutcome
                && State.bLastCommandAccepted && State.bLastCommandCommitted);
            Test->TestEqual(TEXT("Authoritative revision advances once"), State.SessionRevision, BeforeRevision + 1);
            Test->TestTrue(TEXT("Consumed request is no longer actionable"), State.RequestId != BeforeRequest);
            Test->TestTrue(TEXT("Authoritative mission choice displayed"), !State.MissionSummary.IsEmpty());
            Test->TestEqual(TEXT("Opposing private options remain absent"), State.Options.Num(), 0);
            AfterProjectionVersion = State.ProjectionVersion;
            AfterRevision = State.SessionRevision;
            Step = 2;
            Session->Refresh();
            return false;
        }
        Test->TestEqual(TEXT("Refresh does not submit another action"), State.AcceptedActionCount, 1);
        Test->TestEqual(TEXT("Refresh retains authoritative revision"), State.SessionRevision, AfterRevision);
        Test->TestEqual(TEXT("Refresh keeps DTO/session revisions aligned"), State.ProjectionRevision, State.SessionRevision);
        Test->TestTrue(TEXT("Successful refresh advances only the applied DTO delivery version"), State.ProjectionVersion > AfterProjectionVersion);
        Session->Shutdown();
        return true;
    }

private:
    FAutomationTestBase* Test;
    FString Endpoint;
    TSharedPtr<FLiveCoreSession> Session;
    double Started;
    int32 Step = 0;
    int64 BeforeRevision = -1;
    int64 AfterRevision = -1;
    FString BeforeRequest;
    uint64 BeforeProjectionVersion = 0;
    uint64 AfterProjectionVersion = 0;
    bool bObservedReceiptBeforeProjection = false;
    bool bReopenAfterCreate = false;
    bool bReopened = false;
    bool bObserveOpening = false;
    bool bUnexpectedOpenRequest = false;
    int32 OpenRequestAttempts = 0;
    int32 OpenMetadataAttempts = 0;
    int32 OpenProjectionAttempts = 0;
    FString ExistingSessionId;
    FString ExistingRequestId;
    FString ExistingOptionId;
    int64 ExistingRevision = -1;
    FBox2D ExistingBounds = FBox2D(ForceInit);
    int32 ExistingTerrainCount = 0;
    int32 ExistingObjectiveCount = 0;
    int32 ExistingRosterCount = 0;
    bool bExistingRostersAvailable = false;
};
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FLiveCoreSessionIntegrationTest,
    "Warhammer.LiveCore.Integration.RealSessionAction",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::ClientContext | EAutomationTestFlags::EngineFilter)

bool FLiveCoreSessionIntegrationTest::RunTest(const FString& Parameters)
{
    const FString Endpoint = FPlatformMisc::GetEnvironmentVariable(TEXT("WH_LIVE_CORE_TEST_URL"));
    if (Endpoint.IsEmpty())
    {
        AddError(TEXT("Opt-in integration test requires WH_LIVE_CORE_TEST_URL for an owned loopback Core development host."));
        return false;
    }
    FString ValidEndpoint, Error;
    if (!LiveCoreProtocol::ValidateEndpoint(Endpoint, ValidEndpoint, Error))
    {
        AddError(TEXT("Invalid integration-test endpoint."));
        return false;
    }
    ADD_LATENT_AUTOMATION_COMMAND(FLiveSessionActionCheck(this, ValidEndpoint));
    return true;
}
IMPLEMENT_SIMPLE_AUTOMATION_TEST(FLiveCoreSessionReopenIntegrationTest,
    "Warhammer.LiveCore.Integration.ReopenSessionAction",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::ClientContext | EAutomationTestFlags::EngineFilter)

bool FLiveCoreSessionReopenIntegrationTest::RunTest(const FString& Parameters)
{
    const FString Endpoint = FPlatformMisc::GetEnvironmentVariable(TEXT("WH_LIVE_CORE_TEST_URL"));
    FString ValidEndpoint, Error;
    if (Endpoint.IsEmpty() || !LiveCoreProtocol::ValidateEndpoint(Endpoint, ValidEndpoint, Error))
    {
        AddError(TEXT("Reopen integration requires an opted-in owned loopback Core development service."));
        return false;
    }
    ADD_LATENT_AUTOMATION_COMMAND(FLiveSessionActionCheck(this, ValidEndpoint, true));
    return true;
}

namespace
{
class FLocalPlayerHandoffCheck final : public IAutomationLatentCommand
{
public:
    FLocalPlayerHandoffCheck(FAutomationTestBase* InTest, FString InEndpoint)
        : Test(InTest), Endpoint(MoveTemp(InEndpoint)), Started(FPlatformTime::Seconds()) {}
    virtual bool Update() override
    {
        if (!Session.IsValid())
        {
            Session = FLiveCoreSession::Create();
            FLiveCoreSessionIntegrationTestAccess::ObserveRequests(*Session,
                [this](const FString& Verb, const FString& Path, bool bMutation, bool bAdministrator)
                {
                    if (!bObserveHandoff) { return; }
                    ++ReadAttempts;
                    bUnexpectedRead |= Verb != TEXT("GET") || bMutation || bAdministrator;
                    if (Path == TEXT("/sessions/") + SessionId) { ++MetadataAttempts; }
                    else if (Path == TEXT("/sessions/") + SessionId + TEXT("/projection")) { ++ProjectionAttempts; }
                    else { bUnexpectedRead = true; }
                });
            Session->CreateAndStart(Endpoint); return false;
        }
        if (FPlatformTime::Seconds() - Started > 170.0)
        { Test->AddError(TEXT("Real local handoff exceeded170 seconds; completion may be unknown.")); Session->Shutdown(); return true; }
        const auto& State = Session->GetState();
        if (State.bBusy) { return false; }
        if (!State.Error.IsEmpty() || State.bUnknown)
        {
            Test->AddError(FString::Printf(TEXT("Real handoff stopped: HTTP%d, unknown=%d, stage=%d"), State.LastHttpStatus, State.bUnknown, Step));
            Session->Shutdown(); return true;
        }
        if (Step == 0)
        {
            if (!Test->TestTrue(TEXT("Real player-a setup choice is offered"), State.bHasSession && State.ViewerPlayerId == TEXT("player-a") &&
                State.RequestType == TEXT("select_secondary_missions") && !State.Options.IsEmpty())) { Session->Shutdown(); return true; }
            SessionId = State.SessionId; InitialRevision = State.SessionRevision;
            const FString Offered = State.Options[0].Id; Step = 1; Session->SubmitOption(Offered); return false;
        }
        if (Step == 1)
        {
            Test->TestTrue(TEXT("Player-a choice is authoritatively accepted/committed"), State.bLastCommandAccepted && State.bLastCommandCommitted);
            Test->TestEqual(TEXT("Player-a action advances exactly one revision"), State.SessionRevision, InitialRevision + 1);
            Test->TestEqual(TEXT("Player-a local action count"), State.AcceptedActionCount, 1);
            Test->TestTrue(TEXT("Player-a sees own missions and no opposing choice controls"), !State.MissionSummary.IsEmpty() && State.Options.IsEmpty());
            PlayerAMissions = State.MissionSummary; HandoffRevision = State.SessionRevision;
            StartObserving();
            if (!Test->TestTrue(TEXT("Idle verified player-a begins handoff"), Session->BeginPlayerHandoff())) { Session->Shutdown(); return true; }
            CheckCurtain(TEXT("player-b")); Step = 2; return false;
        }
        if (Step == 2 || Step == 5)
        {
            CheckCurtain(Step == 2 ? TEXT("player-b") : TEXT("player-a"));
            Test->TestEqual(TEXT("Waiting for Ready sends zero HTTP attempts"), ReadAttempts, 0);
            Session->ContinuePlayerHandoff();
            Test->TestFalse(TEXT("In-flight Ready cannot begin another switch"), Session->CanBeginPlayerHandoff());
            ++Step; return false;
        }
        if (Step == 3 || Step == 6)
        {
            bObserveHandoff = false;
            const bool bPlayerB = Step == 3;
            Test->TestTrue(TEXT("Ready reopens exactly the same session identity"), State.SessionId == SessionId);
            Test->TestEqual(TEXT("Ready does not mutate authoritative revision"), State.SessionRevision, HandoffRevision);
            Test->TestEqual(TEXT("Ready uses exactly two real HTTP attempts"), ReadAttempts, 2);
            Test->TestEqual(TEXT("Ready metadata read"), MetadataAttempts, 1);
            Test->TestEqual(TEXT("Ready projection read"), ProjectionAttempts, 1);
            Test->TestFalse(TEXT("No administrator/catalog/create/start/gameplay request during handoff"), bUnexpectedRead);
            Test->TestEqual(TEXT("Expected authenticated viewer is restored"), State.ViewerPlayerId, FString(bPlayerB ? TEXT("player-b") : TEXT("player-a")));
            Test->TestEqual(TEXT("Each fresh local view begins at zero accepted actions"), State.AcceptedActionCount, 0);
            Test->TestFalse(TEXT("Old viewer command receipt is absent"), State.bLastCommandHasOutcome);
            Test->TestTrue(TEXT("Only a newly validated projection restores board DTOs"), State.bHasSession && !State.bHandoffPending &&
                State.ProjectionVersion == 1 && State.ProjectionRevision == State.SessionRevision && State.BoardBoundsInches.bIsValid && !State.Terrain.IsEmpty());
            if (!bPlayerB)
            {
                Test->TestEqual(TEXT("Handback restores player-a's own mission state"), State.MissionSummary, PlayerAMissions);
                Test->TestTrue(TEXT("Handback does not substitute player-b's own mission summary"), State.MissionSummary != PlayerBMissions);
                Session->Shutdown(); return true;
            }
            if (!Test->TestTrue(TEXT("Player-b sees own offered secondary choice without inheriting player-a mission text"),
                State.MissionSummary.IsEmpty() && State.RequestType == TEXT("select_secondary_missions") && !State.Options.IsEmpty()))
            { Session->Shutdown(); return true; }
            const FString Offered = State.Options.Last().Id; Step = 4; Session->SubmitOption(Offered); return false;
        }
        if (Step == 4)
        {
            Test->TestTrue(TEXT("Player-b own option is authoritatively accepted/committed"), State.bLastCommandAccepted && State.bLastCommandCommitted);
            Test->TestEqual(TEXT("Player-b action advances exactly one revision"), State.SessionRevision, HandoffRevision + 1);
            Test->TestEqual(TEXT("Player-b local action count"), State.AcceptedActionCount, 1);
            Test->TestTrue(TEXT("Player-b mission summary is independently projected"), !State.MissionSummary.IsEmpty() && State.MissionSummary != PlayerAMissions);
            PlayerBMissions = State.MissionSummary; HandoffRevision = State.SessionRevision;
            StartObserving();
            if (!Test->TestTrue(TEXT("Idle verified player-b begins handback"), Session->BeginPlayerHandoff())) { Session->Shutdown(); return true; }
            CheckCurtain(TEXT("player-a")); Step = 5; return false;
        }
        Test->AddError(TEXT("Unexpected real handoff stage.")); Session->Shutdown(); return true;
    }
private:
    void StartObserving()
    { bObserveHandoff = true; bUnexpectedRead = false; ReadAttempts = MetadataAttempts = ProjectionAttempts = 0; }
    void CheckCurtain(const TCHAR* Target)
    {
        const auto& State = Session->GetState();
        Test->TestTrue(TEXT("Privacy curtain names only intended next player"), State.bHandoffPending && State.HandoffTargetPlayerId == Target);
        Test->TestTrue(TEXT("Former viewer's entire presentation is absent before Ready"), !State.bHasSession && State.SessionId.IsEmpty() &&
            State.ViewerPlayerId.IsEmpty() && State.Phase.IsEmpty() && State.RequestId.IsEmpty() && State.RequestType.IsEmpty() &&
            State.MissionSummary.IsEmpty() && State.Options.IsEmpty() && State.Terrain.IsEmpty() && State.Objectives.IsEmpty() &&
            State.Models.IsEmpty() && !State.bHasPublicArmyRosters && State.PublicArmyRosters.IsEmpty() && !State.bLastCommandHasOutcome &&
            State.LastOutcomeCode.IsEmpty() && State.RecordedCommandError.IsEmpty() && State.AcceptedActionCount == 0 &&
            State.ProjectionVersion == 0 && State.SessionRevision == -1 && State.ProjectionRevision == -1 && !State.BoardBoundsInches.bIsValid);
    }
    FAutomationTestBase* Test;
    FString Endpoint, SessionId, PlayerAMissions, PlayerBMissions;
    TSharedPtr<FLiveCoreSession> Session;
    double Started;
    int32 Step = 0, ReadAttempts = 0, MetadataAttempts = 0, ProjectionAttempts = 0;
    int64 InitialRevision = -1, HandoffRevision = -1;
    bool bObserveHandoff = false, bUnexpectedRead = false;
};
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FLiveCoreLocalHandoffIntegrationTest,
    "Warhammer.LiveCore.Integration.LocalPlayerHandoffAction",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::ClientContext | EAutomationTestFlags::EngineFilter)
bool FLiveCoreLocalHandoffIntegrationTest::RunTest(const FString& Parameters)
{
    const FString Endpoint = FPlatformMisc::GetEnvironmentVariable(TEXT("WH_LIVE_CORE_TEST_URL"));
    FString ValidEndpoint, Error;
    if (Endpoint.IsEmpty() || !LiveCoreProtocol::ValidateEndpoint(Endpoint, ValidEndpoint, Error))
    { AddError(TEXT("Local handoff integration requires an opted-in owned loopback Core service.")); return false; }
    ADD_LATENT_AUTOMATION_COMMAND(FLocalPlayerHandoffCheck(this, ValidEndpoint)); return true;
}

#endif
