#include "LiveCore/LiveCoreSession.h"

#if WITH_DEV_AUTOMATION_TESTS

#include "Misc/AutomationTest.h"

struct FLiveCoreSessionCreationTestAccess
{
    static void BlockRequests(FLiveCoreSession& Client, int32& Count)
    {
        Client.RequestAttemptForTests = [&Count]() { ++Count; };
    }
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
};

namespace
{
constexpr EAutomationTestFlags CreationFlags = EAutomationTestFlags_ApplicationContextMask | EAutomationTestFlags::EngineFilter;
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

#endif
