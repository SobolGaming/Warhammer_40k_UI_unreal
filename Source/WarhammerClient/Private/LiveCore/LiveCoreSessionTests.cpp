#include "LiveCore/LiveCoreSession.h"

#if WITH_DEV_AUTOMATION_TESTS

#include "Migration/CoreBoundaryEvidence.h"
#include "Dom/JsonObject.h"
#include "Dom/JsonValue.h"
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

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FLiveCoreDecisionPresentationTest, "Warhammer.LiveCore.Unit.DecisionPresentationTransitions", Flags)
bool FLiveCoreDecisionPresentationTest::RunTest(const FString& Parameters)
{
    FString Text, HiddenText, Error;
    if (!Load(*this, TEXT("wire/view_initial/playerA.json"), Text) || !Load(*this, TEXT("wire/view_initial/playerB.json"), HiddenText)) { return false; }
    E01::FReadError ReadError; TSharedPtr<FJsonObject> Root, HiddenRoot;
    if (!E01::ParseObject(Text, Root, ReadError) || !E01::ParseObject(HiddenText, HiddenRoot, ReadError)) { AddError(TEXT("Committed projection fixture is invalid.")); return false; }
    const FString Session = Root->GetStringField(TEXT("session_id"));
    const auto Projection = Root->GetObjectField(TEXT("projection"));
    const auto Finite = Projection->GetObjectField(TEXT("pending_decision"));
    const auto Hidden = HiddenRoot->GetObjectField(TEXT("projection"))->GetObjectField(TEXT("pending_decision"));
    const FString OfferedRequest = Finite->GetStringField(TEXT("request_id"));
    FLiveCoreState State;
    auto ReadPending = [&](const TCHAR* Label, const TSharedPtr<FJsonValue>& Pending)
    {
        // Derived parser controls use the real projection envelope/geometry, not
        // fabricated gameplay or a claim about reachable live Core transitions.
        Projection->SetField(TEXT("pending_decision"), Pending);
        return TestTrue(Label, LiveCoreProtocol::ReadProjection(Serialize(Root.ToSharedRef()), Session, State, Error));
    };
    if (!ReadPending(TEXT("Own real finite request parsed"), MakeShared<FJsonValueObject>(Finite))) { return false; }
    TestTrue(TEXT("Own finite request has its explicit presentation"), State.DecisionPresentation == ELiveCoreDecisionPresentation::FiniteOptions);
    TestEqual(TEXT("Own original request ID retained"), State.RequestId, OfferedRequest);
    TestEqual(TEXT("Only actual finite options retained"), State.Options.Num(), 4);

    if (!ReadPending(TEXT("Actual Core-redacted pending shape parsed"), MakeShared<FJsonValueObject>(Hidden))) { return false; }
    TestTrue(TEXT("Hidden differs from no pending"), State.DecisionPresentation == ELiveCoreDecisionPresentation::Hidden);
    TestTrue(TEXT("Hidden placeholder does not expose a request ID"), State.RequestId.IsEmpty());
    TestEqual(TEXT("Hidden exposes only the public hidden type"), State.RequestType, FString(TEXT("hidden_decision")));
    TestEqual(TEXT("Hidden clears previous own options"), State.Options.Num(), 0);

    if (!ReadPending(TEXT("Explicit null pending parsed"), MakeShared<FJsonValueNull>())) { return false; }
    TestTrue(TEXT("Null pending has its own presentation"), State.DecisionPresentation == ELiveCoreDecisionPresentation::NoPending);
    TestTrue(TEXT("No pending clears prior request identity and type"), State.RequestId.IsEmpty() && State.RequestType.IsEmpty());
    TestEqual(TEXT("No pending has no stale options"), State.Options.Num(), 0);

    for (bool bParameterized : { false, true })
    {
        const auto Other = MakeShared<FJsonObject>(*Finite);
        Other->SetStringField(TEXT("actor_id"), TEXT("player-b"));
        Other->SetBoolField(TEXT("is_parameterized"), bParameterized);
        if (!ReadPending(TEXT("Visible other-actor request parsed"), MakeShared<FJsonValueObject>(Other))) { return false; }
        TestTrue(TEXT("Visible other actor is neither hidden nor an own editor request"), State.DecisionPresentation == ELiveCoreDecisionPresentation::OtherActor);
        TestEqual(TEXT("Other actor never offers this preview submission controls"), State.Options.Num(), 0);
        TestEqual(TEXT("Visible public request identity is not replaced"), State.RequestId, OfferedRequest);
    }
    const auto Parameterized = MakeShared<FJsonObject>(*Finite);
    Parameterized->SetBoolField(TEXT("is_parameterized"), true);
    if (!ReadPending(TEXT("Own parameterized request parsed as unsupported presentation"), MakeShared<FJsonValueObject>(Parameterized))) { return false; }
    TestTrue(TEXT("Own editor absence is explicit"), State.DecisionPresentation == ELiveCoreDecisionPresentation::ParameterizedUnsupported);
    TestEqual(TEXT("Parameterized request never exposes finite submit buttons"), State.Options.Num(), 0);

    const auto NoActor = MakeShared<FJsonObject>(*Finite);
    NoActor->SetField(TEXT("actor_id"), MakeShared<FJsonValueNull>());
    if (!ReadPending(TEXT("Public nullable actor accepted without inventing an owner"), MakeShared<FJsonValueObject>(NoActor))) { return false; }
    TestTrue(TEXT("Null actor is not described as another actor"), State.DecisionPresentation == ELiveCoreDecisionPresentation::UnsupportedActor);
    TestEqual(TEXT("Null actor has no submission controls"), State.Options.Num(), 0);

    const auto EmptyFinite = MakeShared<FJsonObject>(*Finite);
    EmptyFinite->SetArrayField(TEXT("options"), TArray<TSharedPtr<FJsonValue>>());
    if (!ReadPending(TEXT("Schema-valid empty finite inventory parsed"), MakeShared<FJsonValueObject>(EmptyFinite))) { return false; }
    TestTrue(TEXT("Empty inventory remains a visible finite request"), State.DecisionPresentation == ELiveCoreDecisionPresentation::FiniteOptions);
    TestEqual(TEXT("No available option is invented for an empty inventory"), State.Options.Num(), 0);
    if (!ReadPending(TEXT("Fresh own finite request recovers presentation"), MakeShared<FJsonValueObject>(Finite))) { return false; }
    TestTrue(TEXT("Own finite presentation recovers after unsupported requests"), State.DecisionPresentation == ELiveCoreDecisionPresentation::FiniteOptions);
    TestEqual(TEXT("Fresh finite inventory replaces the empty inventory"), State.Options.Num(), 4);
    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FLiveCoreDecisionInvalidationTest, "Warhammer.LiveCore.Unit.DecisionPresentationInvalidation", Flags)
bool FLiveCoreDecisionInvalidationTest::RunTest(const FString& Parameters)
{
    FString Text, Other, Error;
    if (!Load(*this, TEXT("wire/view_initial/playerA.json"), Text) || !Load(*this, TEXT("wire/view_initial/playerB.json"), Other)) { return false; }
    E01::FReadError ReadError; TSharedPtr<FJsonObject> Root;
    if (!E01::ParseObject(Text, Root, ReadError)) { AddError(TEXT("Committed projection fixture is invalid.")); return false; }
    const FString Session = Root->GetStringField(TEXT("session_id"));
    FLiveCoreState State;
    if (!TestTrue(TEXT("Seed real actionable snapshot"), LiveCoreProtocol::ReadProjection(Text, Session, State, Error))) { return false; }
    const FString Request = State.RequestId;
    const uint64 Version = State.ProjectionVersion;
    TestFalse(TEXT("Foreign session cannot publish a presentation"), LiveCoreProtocol::ReadProjection(Text, TEXT("foreign-session"), State, Error));
    TestFalse(TEXT("Foreign viewer cannot publish a presentation"), LiveCoreProtocol::ReadProjection(Other, Session, State, Error));
    State.SessionRevision = 2;
    TestFalse(TEXT("Stale projection cannot publish a presentation"), LiveCoreProtocol::ReadProjection(Text, Session, State, Error));
    TestTrue(TEXT("Rejected projections preserve the last atomic presentation"), State.DecisionPresentation == ELiveCoreDecisionPresentation::FiniteOptions);
    TestEqual(TEXT("Rejected projections preserve original request identity"), State.RequestId, Request);
    TestEqual(TEXT("Rejected projections do not advance delivery version"), State.ProjectionVersion, Version);

    LiveCoreProtocol::InvalidateDecisionPresentation(State);
    TestTrue(TEXT("Production refresh/unknown invalidation is not no-pending"), State.DecisionPresentation == ELiveCoreDecisionPresentation::Unavailable);
    TestTrue(TEXT("Invalidation clears stale request identity and type"), State.RequestId.IsEmpty() && State.RequestType.IsEmpty());
    TestEqual(TEXT("Invalidation clears actionable options"), State.Options.Num(), 0);
    TestEqual(TEXT("Local invalidation does not change authoritative revision"), State.SessionRevision, int64(2));
    TestEqual(TEXT("Local invalidation does not pretend a new projection arrived"), State.ProjectionVersion, Version);
    State.SessionRevision = 1;
    const auto Pending = Root->GetObjectField(TEXT("projection"))->GetObjectField(TEXT("pending_decision"));
    Pending->SetStringField(TEXT("decision_type"), TEXT("hidden_decision"));
    Pending->SetStringField(TEXT("schema_version"), TEXT("invalid-hidden-schema"));
    TestFalse(TEXT("Malformed hidden projection cannot replace cleared controls"), LiveCoreProtocol::ReadProjection(Serialize(Root.ToSharedRef()), Session, State, Error));
    TestTrue(TEXT("Failed parse leaves decision information unavailable"), State.DecisionPresentation == ELiveCoreDecisionPresentation::Unavailable);
    TestTrue(TEXT("Failed parse cannot restore old or hidden identities"), State.RequestId.IsEmpty() && State.RequestType.IsEmpty() && State.Options.IsEmpty());
    TestTrue(TEXT("Fresh authenticated projection recovers after invalidation"), LiveCoreProtocol::ReadProjection(Text, Session, State, Error));
    TestTrue(TEXT("Recovered controls use current finite presentation"), State.DecisionPresentation == ELiveCoreDecisionPresentation::FiniteOptions);
    TestEqual(TEXT("Recovered original request identity"), State.RequestId, Request);
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

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FLiveCoreProjectionVersionTest, "Warhammer.LiveCore.Unit.ProjectionVersionAndReadRecovery", Flags)
bool FLiveCoreProjectionVersionTest::RunTest(const FString& Parameters)
{
    FString Before, After, Receipt, Rejection, Error;
    if (!Load(*this, TEXT("wire/movement_before/playerA.json"), Before) || !Load(*this, TEXT("wire/movement_after/playerA.json"), After) ||
        !Load(*this, TEXT("wire/movement_accepted/playerA.json"), Receipt) || !Load(*this, TEXT("wire/movement_recorded_invalid/playerA.json"), Rejection)) { return false; }
    E01::FOutcome Original; E01::FReadError ReadError;
    if (!E01::ReadOutcome(200, Receipt, Original, ReadError)) { AddError(TEXT("Committed movement receipt fixture is invalid.")); return false; }
    const FString Session = Original.Json->GetObjectField(TEXT("session"))->GetStringField(TEXT("session_id"));
    FLiveCoreState State;
    if (!TestTrue(TEXT("Actual pre-move DTO snapshot applied"), LiveCoreProtocol::ReadProjection(Before, Session, State, Error))) { return false; }
    const FLiveCoreState BeforeState = State;
    TMap<FString, FVector> OldPositions;
    for (const auto& Model : State.Models) { OldPositions.Add(Model.Id, Model.PositionInches); }
    LiveCoreProtocol::FOutcome Outcome;
    if (!TestTrue(TEXT("Actual accepted move receipt parsed"), LiveCoreProtocol::ReadOutcome(Receipt, 200, Original.CommandId, Session,
        Original.SessionRevision.GetValue() - 1, false, TEXT("submit_parameterized_decision"), Outcome, Error))) { return false; }
    TestTrue(TEXT("Production receipt-application path succeeds"), LiveCoreProtocol::ApplyKnownCommandOutcome(Outcome, 200, true, State));
    TestEqual(TEXT("Receipt advances session lower bound"), State.SessionRevision, Outcome.Revision);
    TestEqual(TEXT("Receipt alone does not advance DTO revision"), State.ProjectionRevision, BeforeState.ProjectionRevision);
    TestEqual(TEXT("Receipt alone does not advance render cache version"), State.ProjectionVersion, BeforeState.ProjectionVersion);
    TestFalse(TEXT("Pre-receipt old projection remains rejected"), LiveCoreProtocol::ReadProjection(Before, Session, State, Error));
    TestEqual(TEXT("Rejected projection preserves cache version"), State.ProjectionVersion, BeforeState.ProjectionVersion);
    State.Error = TEXT("A prior projection GET failed.");
    if (!TestTrue(TEXT("Actual changed post-move DTO snapshot applied"), LiveCoreProtocol::ReadProjection(After, Session, State, Error))) { return false; }
    TestEqual(TEXT("DTO revision catches up only after valid parse"), State.ProjectionRevision, Outcome.Revision);
    TestEqual(TEXT("New DTO delivery advances render cache version"), State.ProjectionVersion, BeforeState.ProjectionVersion + 1);
    TestTrue(TEXT("Successful projection clears prior read failure"), State.Error.IsEmpty());
    bool bActualModelChanged = false;
    for (const auto& Model : State.Models)
    {
        const FVector* Old = OldPositions.Find(Model.Id);
        if (Old && !Old->Equals(Model.PositionInches, 0.000001)) { bActualModelChanged = true; }
    }
    TestTrue(TEXT("Regression fixture includes actual authoritative model movement"), bActualModelChanged);
    E01::FOutcome RejectedOriginal;
    if (!E01::ReadOutcome(422, Rejection, RejectedOriginal, ReadError)) { AddError(TEXT("Recorded rejection fixture is invalid.")); return false; }
    LiveCoreProtocol::FOutcome Rejected;
    TestTrue(TEXT("Actual recorded rejection parsed"), LiveCoreProtocol::ReadOutcome(Rejection, 422, RejectedOriginal.CommandId, Session,
        RejectedOriginal.SessionRevision.GetValue() - 1, false, TEXT("submit_parameterized_decision"), Rejected, Error));
    FLiveCoreState RejectedState = BeforeState;
    TestTrue(TEXT("Actual known rejected receipt applied"), LiveCoreProtocol::ApplyKnownCommandOutcome(Rejected, 422, true, RejectedState));
    const FString RecordedError = RejectedState.RecordedCommandError;
    TestFalse(TEXT("Recorded rejection detail exists"), RecordedError.IsEmpty());
    RejectedState.Error = TEXT("A subsequent projection GET failed.");
    TestTrue(TEXT("Fresh valid read recovers after the GET failure"), LiveCoreProtocol::ReadProjection(After, Session, RejectedState, Error));
    TestEqual(TEXT("Recovery preserves known recorded rejection details"), RejectedState.Error, RecordedError);
    return true;
}
IMPLEMENT_SIMPLE_AUTOMATION_TEST(FLiveCoreReturnedDiagnosticsTest, "Warhammer.LiveCore.Unit.ReturnedRejectionDiagnostics", Flags)
bool FLiveCoreReturnedDiagnosticsTest::RunTest(const FString& Parameters)
{
    FString Text, Error;
    if (!Load(*this, TEXT("wire/movement_recorded_invalid/playerA.json"), Text)) { return false; }
    E01::FOutcome Original; E01::FReadError ReadError;
    if (!E01::ReadOutcome(422, Text, Original, ReadError)) { AddError(TEXT("Recorded rejection fixture could not be read.")); return false; }
    const FString Session = Original.Json->GetObjectField(TEXT("session"))->GetStringField(TEXT("session_id"));
    const int64 ExpectedRevision = Original.SessionRevision.GetValue() - 1;
    LiveCoreProtocol::FOutcome Outcome;
    if (!TestTrue(TEXT("Actual scoped rejection receipt parsed"), LiveCoreProtocol::ReadOutcome(Text, 422, Original.CommandId, Session,
        ExpectedRevision, false, TEXT("submit_parameterized_decision"), Outcome, Error))) { return false; }
    TestEqual(TEXT("Actual returned lifecycle message retained"), Outcome.ReturnedLifecycleMessage, FString(TEXT("Normal Move path is invalid.")));
    if (!TestEqual(TEXT("Actual returned violation count"), Outcome.ReturnedViolations.Num(), 1)) { return false; }
    TestEqual(TEXT("Actual returned violation code retained"), Outcome.ReturnedViolations[0].Code, FString(TEXT("movement_distance_exceeded")));
    TestTrue(TEXT("Nullable violation field has its supplied value"), Outcome.ReturnedViolations[0].Field.IsSet() && Outcome.ReturnedViolations[0].Field.GetValue() == TEXT("witness"));
    FLiveCoreState State; State.SessionRevision = ExpectedRevision;
    TestTrue(TEXT("Known rejection applied"), LiveCoreProtocol::ApplyKnownCommandOutcome(Outcome, 422, true, State));
    TestTrue(TEXT("UI preserves actual supplied lifecycle message"), State.Error.Contains(TEXT("Normal Move path is invalid.")));
    TestTrue(TEXT("UI preserves actual supplied violation code"), State.Error.Contains(TEXT("movement_distance_exceeded")));
    TestTrue(TEXT("Lifecycle text is labelled as returned status, not invented current cause"), State.Error.Contains(TEXT("Returned lifecycle status:")));
    TestFalse(TEXT("No false missing-detail claim when diagnostics exist"), State.Error.Contains(TEXT("not supplied")));
    LiveCoreProtocol::FOutcome Foreign;
    TestFalse(TEXT("Scope validation precedes diagnostic extraction"), LiveCoreProtocol::ReadOutcome(Text, 422, Original.CommandId, Session,
        ExpectedRevision, true, TEXT("submit_parameterized_decision"), Foreign, Error));
    TestTrue(TEXT("Failed-scope output receives no lifecycle diagnostic"), Foreign.ReturnedLifecycleMessage.IsEmpty() && Foreign.ReturnedViolations.IsEmpty());
    const auto Lifecycle = Original.Json->GetObjectField(TEXT("session"))->GetObjectField(TEXT("lifecycle_status"));
    Lifecycle->SetField(TEXT("message"), MakeShared<FJsonValueNull>());
    const auto Payload = Lifecycle->GetObjectField(TEXT("payload"));
    Payload->RemoveField(TEXT("proposal_validation")); Payload->RemoveField(TEXT("violation_code"));
    TestTrue(TEXT("Known outcome can legitimately omit diagnostic detail"), LiveCoreProtocol::ReadOutcome(Serialize(Original.Json.ToSharedRef()), 422,
        Original.CommandId, Session, ExpectedRevision, false, TEXT("submit_parameterized_decision"), Outcome, Error));
    TestTrue(TEXT("Known detail-free rejection still applied"), LiveCoreProtocol::ApplyKnownCommandOutcome(Outcome, 422, true, State));
    TestTrue(TEXT("Missing detail explicitly stated only when absent"), State.Error.Contains(TEXT("Detailed engine reasons were not supplied")));
    const FString ErrorEnvelope(TEXT("{\"schema_version\":\"error-envelope-v1\",\"error\":{\"code\":\"proposal_invalid\",\"message\":\"Actual error message\"}}"));
    TestTrue(TEXT("Flagless 422 still requires same-command reconciliation"), LiveCoreProtocol::ReadOutcome(ErrorEnvelope, 422, Original.CommandId,
        Session, ExpectedRevision, false, TEXT("submit_parameterized_decision"), Outcome, Error) && Outcome.bRequiresReconciliation);
    const FString PreservedError = State.Error;
    TestFalse(TEXT("Flagless error cannot be promoted to a known recorded rejection"), LiveCoreProtocol::ApplyKnownCommandOutcome(Outcome, 422, true, State));
    TestEqual(TEXT("Unknown receipt does not overwrite recorded diagnostics"), State.Error, PreservedError);
    return true;
}

#endif
