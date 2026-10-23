#include "LiveCore/LiveCoreSession.h"

#if WITH_DEV_AUTOMATION_TESTS

#include "Migration/CoreBoundaryEvidence.h"
#include "Dom/JsonObject.h"
#include "Misc/AutomationTest.h"
#include "Misc/FileHelper.h"
#include "Misc/Paths.h"
#include "Serialization/JsonSerializer.h"

namespace
{
namespace E01 = Warhammer::Migration::E01;
constexpr EAutomationTestFlags Flags = EAutomationTestFlags_ApplicationContextMask | EAutomationTestFlags::EngineFilter;
FString FixturePath(const TCHAR* Relative)
{
    return FPaths::Combine(FPaths::ProjectDir(), TEXT("tests/migration/fixtures/5f509724da25a2f6ded0c2739a8e7c84bdf59c91"), Relative);
}
bool Load(FAutomationTestBase& Test, const TCHAR* Relative, FString& Out)
{
    if (!FFileHelper::LoadFileToString(Out, *FixturePath(Relative)))
    { Test.AddError(TEXT("Required committed Core fixture could not be read.")); return false; }
    return true;
}
FString Serialize(const TSharedRef<FJsonObject>& Object)
{
    FString Out; const auto Writer = TJsonWriterFactory<>::Create(&Out); FJsonSerializer::Serialize(Object, Writer); return Out;
}
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FLiveCoreEndpointTest, "Warhammer.LiveCore.Unit.Endpoint", Flags)
bool FLiveCoreEndpointTest::RunTest(const FString& Parameters)
{
    FString Endpoint, Error;
    TestTrue(TEXT("Explicit development endpoint"), LiveCoreProtocol::ValidateEndpoint(TEXT("http://127.0.0.1:8765/"), Endpoint, Error));
    TestEqual(TEXT("Canonical endpoint"), Endpoint, FString(TEXT("http://127.0.0.1:8765")));
    for (const TCHAR* Invalid : {TEXT("http://127.0.0.1:0"), TEXT("http://127.0.0.1:65536"), TEXT("http://127.0.0.1:8765/path"),
        TEXT("http://127.0.0.1:8765?token=x"), TEXT("http://user@127.0.0.1:8765"), TEXT("https://127.0.0.1:8765"), TEXT("http://example.com:8765")})
    { TestFalse(TEXT("Out-of-scope endpoint rejected"), LiveCoreProtocol::ValidateEndpoint(Invalid, Endpoint, Error)); }
    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FLiveCoreEnvelopeTest, "Warhammer.LiveCore.Unit.Envelope", Flags)
bool FLiveCoreEnvelopeTest::RunTest(const FString& Parameters)
{
    E01::FCommandEnvelope Envelope; E01::FReadError Error;
    const FString Start = LiveCoreProtocol::MakeStartCommand(TEXT("session-test"), TEXT("start-test"));
    TestTrue(TEXT("Canonical start envelope accepted by existing strict contract reader"), E01::ReadCommandEnvelope(Start, Envelope, Error));
    TestEqual(TEXT("Start submission"), Envelope.SubmissionKind, FString(TEXT("start_session")));
    TestFalse(TEXT("Lifecycle request ID remains null"), Envelope.RequestId.IsSet());
    TestFalse(TEXT("Lifecycle result ID remains null"), Envelope.ResultId.IsSet());
    const FString Option(TEXT("offered:\"quoted\\identifier"));
    const FString Finite = LiveCoreProtocol::MakeFiniteCommand(TEXT("session-test"), TEXT("choice-test"), 7, TEXT("request-test"), Option);
    TestTrue(TEXT("Finite envelope is contract-shaped JSON"), E01::ReadCommandEnvelope(Finite, Envelope, Error));
    TestEqual(TEXT("Exact revision"), Envelope.ExpectedSessionRevision, int64(7));
    TestEqual(TEXT("Original request identity"), Envelope.RequestId.GetValue(), FString(TEXT("request-test")));
    TestEqual(TEXT("Stable result identity"), Envelope.ResultId.GetValue(), FString(TEXT("choice-test-result")));
    TestEqual(TEXT("Typed finite submission"), Envelope.SubmissionKind, FString(TEXT("finite_option")));
    TestEqual(TEXT("Escaped option identity roundtrips"), Envelope.Json->GetObjectField(TEXT("submission"))->GetStringField(TEXT("option_id")), Option);
    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FLiveCoreCreatedIdentityTest, "Warhammer.LiveCore.Unit.CreatedIdentity", Flags)
bool FLiveCoreCreatedIdentityTest::RunTest(const FString& Parameters)
{
    FString Text, Error; if (!Load(*this, TEXT("contracts/examples/sessions/session-metadata-created.json"), Text)) { return false; }
    LiveCoreProtocol::FMetadata Metadata;
    TestTrue(TEXT("Exact selected Core metadata"), LiveCoreProtocol::ReadCreatedSession(Text, Metadata, Error));
    TestEqual(TEXT("Created revision"), Metadata.Revision, int64(0));
    FString Wrong = Text.Replace(TEXT("44.3.33"), TEXT("44.1.0"));
    TestFalse(TEXT("Different contract refused"), LiveCoreProtocol::ReadCreatedSession(Wrong, Metadata, Error));
    Wrong = Text.Replace(TEXT("65fc8414407ae5d6a8ea779c8e737a22733459094db679a160c60f6e2129f96a"), TEXT("75fc8414407ae5d6a8ea779c8e737a22733459094db679a160c60f6e2129f96a"));
    TestFalse(TEXT("Different runtime build refused"), LiveCoreProtocol::ReadCreatedSession(Wrong, Metadata, Error));
    Wrong = Text.Replace(TEXT("\"session_revision\": 0"), TEXT("\"session_revision\": 0, \"Session_Revision\": 0"));
    TestFalse(TEXT("Case-colliding JSON fields refused before map loss"), LiveCoreProtocol::ReadCreatedSession(Wrong, Metadata, Error));
    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FLiveCoreProjectionTest, "Warhammer.LiveCore.Unit.ProjectionPrivacyAndGeometry", Flags)
bool FLiveCoreProjectionTest::RunTest(const FString& Parameters)
{
    FString Text, Error; if (!Load(*this, TEXT("wire/view_initial/playerA.json"), Text)) { return false; }
    E01::FReadError ReadError; TSharedPtr<FJsonObject> Root;
    if (!E01::ParseObject(Text, Root, ReadError)) { AddError(TEXT("Committed projection fixture is not valid JSON.")); return false; }
    const FString Session = Root->GetStringField(TEXT("session_id"));
    FLiveCoreState State;
    if (!TestTrue(TEXT("Real player-a projection parsed"), LiveCoreProtocol::ReadProjection(Text, Session, State, Error))) { return false; }
    TestEqual(TEXT("Initial revision"), State.SessionRevision, int64(1));
    TestEqual(TEXT("Actual width inches"), State.BoardBoundsInches.GetSize().X, 44.0);
    TestEqual(TEXT("Actual length inches"), State.BoardBoundsInches.GetSize().Y, 60.0);
    TestEqual(TEXT("Actual objective count"), State.Objectives.Num(), 6);
    TestEqual(TEXT("Actual terrain count"), State.Terrain.Num(), 30);
    TestEqual(TEXT("No fabricated undeployed model poses"), State.Models.Num(), 0);
    TestEqual(TEXT("Real decision family"), State.RequestType, FString(TEXT("select_secondary_missions")));
    TestEqual(TEXT("Only actual offered choices"), State.Options.Num(), 4);
    TestFalse(TEXT("Foreign session is refused"), LiveCoreProtocol::ReadProjection(Text, TEXT("different-session"), State, Error));
    FString Other; if (!Load(*this, TEXT("wire/view_initial/playerB.json"), Other)) { return false; }
    TestFalse(TEXT("Opposing player projection cannot become display state"), LiveCoreProtocol::ReadProjection(Other, Session, State, Error));
    State.SessionRevision = 2;
    TestFalse(TEXT("Older asynchronous projection cannot replace current revision"), LiveCoreProtocol::ReadProjection(Text, Session, State, Error));
    State.SessionRevision = 1;
    Root->GetObjectField(TEXT("projection"))->GetObjectField(TEXT("battlefield_view"))->GetObjectField(TEXT("bounds"))->RemoveField(TEXT("max_x_inches"));
    TestFalse(TEXT("Missing dimensions fail without defaults"), LiveCoreProtocol::ReadProjection(Serialize(Root.ToSharedRef()), Session, State, Error));
    TestEqual(TEXT("Failed parse preserves previously valid board"), State.BoardBoundsInches.GetSize().X, 44.0);
    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FLiveCoreOutcomeTest, "Warhammer.LiveCore.Unit.OutcomeAndUncertainErrors", Flags)
bool FLiveCoreOutcomeTest::RunTest(const FString& Parameters)
{
    FString Text, Error; if (!Load(*this, TEXT("wire/finite_accepted/playerA.json"), Text)) { return false; }
    E01::FOutcome Base; E01::FReadError ReadError;
    if (!E01::ReadOutcome(200, Text, Base, ReadError)) { AddError(TEXT("Committed outcome fixture could not be read.")); return false; }
    const FString Session = Base.Json->GetObjectField(TEXT("session"))->GetStringField(TEXT("session_id"));
    LiveCoreProtocol::FOutcome Outcome;
    TestTrue(TEXT("Actual command receipt binds original command/viewer/revision"), LiveCoreProtocol::ReadOutcome(Text, 200, Base.CommandId, Session, 1, false, TEXT("submit_finite_decision"), Outcome, Error));
    TestTrue(TEXT("Accepted and committed"), Outcome.bAccepted && Outcome.bCommitted && !Outcome.bRequiresReconciliation);
    TestEqual(TEXT("Exactly one committed revision"), Outcome.Revision, int64(2));
    TestFalse(TEXT("Wrong command receipt refused"), LiveCoreProtocol::ReadOutcome(Text, 200, TEXT("wrong-command"), Session, 1, false, TEXT("submit_finite_decision"), Outcome, Error));
    TestFalse(TEXT("Wrong expected revision refused"), LiveCoreProtocol::ReadOutcome(Text, 200, Base.CommandId, Session, 2, false, TEXT("submit_finite_decision"), Outcome, Error));
    TestFalse(TEXT("Player receipt cannot stand in for administrator scope"), LiveCoreProtocol::ReadOutcome(Text, 200, Base.CommandId, Session, 1, true, TEXT("submit_finite_decision"), Outcome, Error));
    const FString ErrorEnvelope(TEXT("{\"schema_version\":\"error-envelope-v1\",\"error\":{\"code\":\"proposal_invalid\",\"message\":\"Actual engine message\"}}"));
    TestTrue(TEXT("Actual 422 error envelope retained"), LiveCoreProtocol::ReadOutcome(ErrorEnvelope, 422, Base.CommandId, Session, 1, false, TEXT("submit_finite_decision"), Outcome, Error));
    TestTrue(TEXT("422 without commit flags requires reconciliation, not assumed rollback"), Outcome.bError && Outcome.bRequiresReconciliation);
    TestTrue(TEXT("Actual supplied message preserved"), Outcome.Message.StartsWith(TEXT("Actual engine message")));
    TestTrue(TEXT("Missing detailed fidelity is explicit"), Outcome.Message.Contains(TEXT("Detailed engine reasons were not supplied")));
    TestTrue(TEXT("Received 500 is still not rollback proof"), LiveCoreProtocol::ReadOutcome(ErrorEnvelope, 500, Base.CommandId, Session, 1, false, TEXT("submit_finite_decision"), Outcome, Error) && Outcome.bRequiresReconciliation);
    return true;
}

#endif
