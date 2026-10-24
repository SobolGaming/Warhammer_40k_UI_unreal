#include "LiveCore/LiveCoreSession.h"

#if WITH_DEV_AUTOMATION_TESTS
#include "HAL/PlatformMisc.h"
#include "HAL/PlatformTime.h"
#include "Misc/AutomationTest.h"

namespace
{
// Explicit opt-in: this test creates one disposable session on an existing development
// service. It never starts a host or a rendered world and never logs credentials/state.
class FLiveSessionActionCheck final : public IAutomationLatentCommand
{
public:
    FLiveSessionActionCheck(FAutomationTestBase* InTest, FString InEndpoint)
        : Test(InTest), Endpoint(MoveTemp(InEndpoint)), Started(FPlatformTime::Seconds()) {}

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
#endif
