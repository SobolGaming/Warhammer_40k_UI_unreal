#include "LiveCore/LiveCoreSession.h"
#include "LiveCore/LiveCoreRuntimeData.h"

#include "Migration/CoreBoundaryEvidence.h"
#include "Dom/JsonObject.h"
#include "HAL/PlatformMisc.h"
#include "HttpModule.h"
#include "Interfaces/IHttpRequest.h"
#include "Interfaces/IHttpResponse.h"
#include "Serialization/JsonSerializer.h"
#include "Serialization/JsonWriter.h"

namespace
{
namespace E01 = Warhammer::Migration::E01;
constexpr int32 MaximumResponseBytes = 4 * 1024 * 1024;
constexpr int32 MaximumEntities = 4096;
const TCHAR* CoreBuild = TEXT("warhammer40k-core-v2:runtime-tree-sha256-v1:65fc8414407ae5d6a8ea779c8e737a22733459094db679a160c60f6e2129f96a");
const TCHAR* Contract = TEXT("44.3.33");

bool Exact(const FString& A, const FString& B) { return A.Equals(B, ESearchCase::CaseSensitive); }
TSharedPtr<FJsonValue> Field(const TSharedPtr<FJsonObject>& O, const TCHAR* Name)
{
    if (O.IsValid()) { for (const auto& Pair : O->Values) { if (FStringView(*Pair.Key, Pair.Key.Len()).Equals(Name, ESearchCase::CaseSensitive)) { return Pair.Value; } } }
    return nullptr;
}
TSharedPtr<FJsonObject> Object(const TSharedPtr<FJsonObject>& O, const TCHAR* Name)
{
    const auto V = Field(O, Name);
    return V.IsValid() && V->Type == EJson::Object ? V->AsObject() : nullptr;
}
bool String(const TSharedPtr<FJsonObject>& O, const TCHAR* Name, FString& Out)
{
    const auto V = Field(O, Name);
    return V.IsValid() && V->Type == EJson::String && V->TryGetString(Out) && !Out.IsEmpty() && Out.Len() <= 4096;
}
bool IsString(const TSharedPtr<FJsonObject>& O, const TCHAR* Name, const TCHAR* Expected)
{
    FString S; return String(O, Name, S) && Exact(S, Expected);
}
bool Number(const TSharedPtr<FJsonObject>& O, const TCHAR* Name, double& Out)
{
    const auto V = Field(O, Name);
    return V.IsValid() && V->Type == EJson::Number && V->TryGetNumber(Out) && FMath::IsFinite(Out) && FMath::Abs(Out) <= 1000000.0;
}
bool Boolean(const TSharedPtr<FJsonObject>& O, const TCHAR* Name, bool& Out)
{
    const auto V = Field(O, Name); return V.IsValid() && V->Type == EJson::Boolean && V->TryGetBool(Out);
}
bool Null(const TSharedPtr<FJsonObject>& O, const TCHAR* Name)
{
    const auto V = Field(O, Name); return V.IsValid() && V->Type == EJson::Null;
}
bool Array(const TSharedPtr<FJsonObject>& O, const TCHAR* Name, const TArray<TSharedPtr<FJsonValue>>*& Out)
{
    const auto V = Field(O, Name); return V.IsValid() && V->Type == EJson::Array && V->TryGetArray(Out) && Out->Num() <= MaximumEntities;
}
bool Revision(const TSharedPtr<FJsonObject>& O, const TCHAR* Name, int64& Out)
{
    E01::FReadError E; return E01::ReadExactRevision(Field(O, Name), Out, E);
}
bool SafeId(const FString& S)
{
    if (S.IsEmpty() || S.Len() > 256) { return false; }
    for (TCHAR C : S)
    {
        if (!((C >= TEXT('a') && C <= TEXT('z')) || (C >= TEXT('A') && C <= TEXT('Z')) ||
            (C >= TEXT('0') && C <= TEXT('9')) || C == TEXT('-') || C == TEXT('_') || C == TEXT('.') || C == TEXT(':'))) { return false; }
    }
    return true;
}
bool Parse(const FString& Text, TSharedPtr<FJsonObject>& Out, FString& Error)
{
    E01::FReadError E;
    if (!E01::ParseObject(Text, Out, E)) { Error = TEXT("Invalid bounded JSON: ") + E.Code; return false; }
    return true;
}
bool Identity(const TSharedPtr<FJsonObject>& O)
{
    return IsString(O, TEXT("schema_version"), TEXT("session-metadata-v44-contract")) &&
        IsString(O, TEXT("engine_build_id"), CoreBuild) && IsString(O, TEXT("server_contract_version"), Contract);
}
bool Scope(const TSharedPtr<FJsonObject>& Visibility, bool bAdministrator)
{
    return bAdministrator ? IsString(Visibility, TEXT("role"), TEXT("administrator")) && Null(Visibility, TEXT("player_id")) :
        IsString(Visibility, TEXT("role"), TEXT("player")) && IsString(Visibility, TEXT("player_id"), TEXT("player-a"));
}
bool Position(const TSharedPtr<FJsonObject>& O, FVector& Out)
{
    double X, Y, Z;
    if (!Number(O, TEXT("x_inches"), X) || !Number(O, TEXT("y_inches"), Y) || !Number(O, TEXT("z_inches"), Z)) { return false; }
    Out = FVector(X, Y, Z); return true;
}
bool DecodeUtf8(const TArray<uint8>& Bytes, FString& Out)
{
    if (Bytes.IsEmpty() || Bytes.Num() > MaximumResponseBytes) { return false; }
    const FUTF8ToTCHAR Decoded(reinterpret_cast<const ANSICHAR*>(Bytes.GetData()), Bytes.Num());
    Out = FString(Decoded.Length(), Decoded.Get());
    const FTCHARToUTF8 Reencoded(*Out, Out.Len());
    return Reencoded.Length() == Bytes.Num() && FMemory::Memcmp(Reencoded.Get(), Bytes.GetData(), Bytes.Num()) == 0;
}
FString Json(const TSharedRef<FJsonObject>& O)
{
    FString Text;
    const auto Writer = TJsonWriterFactory<TCHAR, TCondensedJsonPrintPolicy<TCHAR>>::Create(&Text);
    FJsonSerializer::Serialize(O, Writer); return Text;
}
FString Command(const FString& Session, const FString& Id, int64 RevisionValue,
    const FString* Request, const FString* Option)
{
    auto O = MakeShared<FJsonObject>();
    O->SetStringField(TEXT("schema_version"), TEXT("session-command-envelope-v2-weapon-instances"));
    O->SetStringField(TEXT("command_id"), Id); O->SetStringField(TEXT("session_id"), Session);
    O->SetNumberField(TEXT("expected_session_revision"), static_cast<double>(RevisionValue));
    auto Submission = MakeShared<FJsonObject>();
    if (Request && Option)
    {
        O->SetStringField(TEXT("request_id"), *Request); O->SetStringField(TEXT("result_id"), Id + TEXT("-result"));
        Submission->SetStringField(TEXT("submission_kind"), TEXT("finite_option")); Submission->SetStringField(TEXT("option_id"), *Option);
    }
    else
    {
        O->SetField(TEXT("request_id"), MakeShared<FJsonValueNull>()); O->SetField(TEXT("result_id"), MakeShared<FJsonValueNull>());
        Submission->SetStringField(TEXT("submission_kind"), TEXT("start_session"));
    }
    O->SetObjectField(TEXT("submission"), Submission); return Json(O);
}
FString ErrorText(int32 Status, const FString& Code, const FString& Message)
{
    return FString::Printf(TEXT("HTTP %d — %s: %s"), Status, *Code, *Message);
}
bool CredentialValid(const FString& Token)
{
    if (Token.IsEmpty() || Token.Len() > 256) { return false; }
    for (TCHAR C : Token) { if (C <= 32 || C >= 127) { return false; } }
    return true;
}
}

namespace LiveCoreProtocol
{
bool ValidateEndpoint(const FString& Input, FString& OutEndpoint, FString& OutError)
{
    FString S = Input;
    if (S.EndsWith(TEXT("/"))) { S.LeftChopInline(1); }
    const FString Prefix(TEXT("http://127.0.0.1:"));
    if (!S.StartsWith(Prefix, ESearchCase::CaseSensitive)) { OutError = TEXT("Use an explicit loopback development URL: http://127.0.0.1:<port>."); return false; }
    const FString PortText = S.Mid(Prefix.Len());
    if (PortText.IsEmpty() || PortText.Len() > 5) { OutError = TEXT("Core port must be 1–65535."); return false; }
    for (TCHAR C : PortText) { if (C < TEXT('0') || C > TEXT('9')) { OutError = TEXT("Core endpoint must contain only a loopback host and numeric port."); return false; } }
    const int32 Port = FCString::Atoi(*PortText);
    if (Port <= 0 || Port > 65535) { OutError = TEXT("Core port must be 1–65535."); return false; }
    OutEndpoint = Prefix + FString::FromInt(Port); OutError.Reset(); return true;
}

bool ReadCreatedSession(const FString& Text, FMetadata& OutMetadata, FString& OutError)
{
    TSharedPtr<FJsonObject> O; FMetadata Candidate;
    if (!Parse(Text, O, OutError)) { return false; }
    if (!Identity(O) || !String(O, TEXT("session_id"), Candidate.SessionId) || !SafeId(Candidate.SessionId) ||
        !String(O, TEXT("game_id"), Candidate.GameId) || !Revision(O, TEXT("session_revision"), Candidate.Revision) ||
        Candidate.Revision != 0 || !IsString(O, TEXT("session_state"), TEXT("created")) || !Scope(Object(O, TEXT("visibility")), true))
    {
        OutError = TEXT("Created session identity, revision or administrator scope differs from the selected Core 44.3.33 build."); return false;
    }
    OutMetadata = MoveTemp(Candidate); OutError.Reset(); return true;
}

bool ReadProjection(const FString& Text, const FString& SessionId, FLiveCoreState& OutState, FString& OutError)
{
    TSharedPtr<FJsonObject> O;
    if (!Parse(Text, O, OutError)) { return false; }
    FString ReturnedSession;
    int64 NewRevision;
    const auto P = Object(O, TEXT("projection"));
    if (!IsString(O, TEXT("schema_version"), TEXT("session-projection-v9-random-profiles")) ||
        !String(O, TEXT("session_id"), ReturnedSession) || !Exact(ReturnedSession, SessionId) ||
        !IsString(O, TEXT("visibility_role"), TEXT("player")) || !Revision(O, TEXT("session_revision"), NewRevision) ||
        NewRevision < OutState.SessionRevision || OutState.ProjectionVersion == MAX_uint64 || !IsString(P, TEXT("viewer_player_id"), TEXT("player-a")) ||
        !IsString(P, TEXT("viewer_role"), TEXT("player")))
    {
        OutError = TEXT("Projection session, revision or authenticated player-a scope mismatch."); return false;
    }
    FString OuterHash, InnerHash;
    if (!String(O, TEXT("projection_state_hash"), OuterHash) || !String(P, TEXT("projection_state_hash"), InnerHash) || !Exact(OuterHash, InnerHash))
    { OutError = TEXT("Projection checkpoint hash mismatch."); return false; }
    FLiveCoreState Candidate = OutState;
    Candidate.SessionRevision = NewRevision; Candidate.ProjectionRevision = NewRevision;
    Candidate.ProjectionVersion = OutState.ProjectionVersion + 1;
    Candidate.Terrain.Reset(); Candidate.Objectives.Reset(); Candidate.Models.Reset();
    Candidate.Options.Reset(); Candidate.RequestId.Reset(); Candidate.RequestType.Reset(); Candidate.MissionSummary.Reset();
    FString Stage;
    if (!String(P, TEXT("stage"), Stage)) { OutError = TEXT("Projection stage is missing."); return false; }
    Candidate.Phase = Stage;
    FString Step;
    if (String(P, TEXT("current_setup_step"), Step) || String(P, TEXT("current_battle_phase"), Step)) { Candidate.Phase += TEXT(" / ") + Step; }
    const auto Board = Object(P, TEXT("battlefield_view"));
    const auto Bounds = Object(Board, TEXT("bounds"));
    double MinX, MinY, MaxX, MaxY;
    if (!IsString(Board, TEXT("coordinate_space"), TEXT("battlefield_inches_right_handed_z_up")) ||
        !Number(Bounds, TEXT("min_x_inches"), MinX) || !Number(Bounds, TEXT("min_y_inches"), MinY) ||
        !Number(Bounds, TEXT("max_x_inches"), MaxX) || !Number(Bounds, TEXT("max_y_inches"), MaxY) || MaxX <= MinX || MaxY <= MinY)
    { OutError = TEXT("Core battlefield bounds/coordinate space are unsupported or invalid."); return false; }
    Candidate.BoardBoundsInches = FBox2D(FVector2D(MinX, MinY), FVector2D(MaxX, MaxY));
    const auto Authoritative = Object(Board, TEXT("authoritative"));
    const auto Terrain = Object(Authoritative, TEXT("terrain_features_by_id"));
    const auto Objectives = Object(Authoritative, TEXT("objectives_by_id"));
    const auto Models = Object(Authoritative, TEXT("models_by_id"));
    if (!Terrain.IsValid() || !Objectives.IsValid() || !Models.IsValid() || Terrain->Values.Num() > MaximumEntities ||
        Objectives->Values.Num() > MaximumEntities || Models->Values.Num() > MaximumEntities)
    { OutError = TEXT("Core battlefield entity maps are missing or exceed this slice's limits."); return false; }
    for (const auto& Pair : Terrain->Values)
    {
        const auto T = Pair.Value->Type == EJson::Object ? Pair.Value->AsObject() : nullptr;
        FLiveCoreTerrain Item; const auto Footprint = Object(T, TEXT("footprint"));
        const TArray<TSharedPtr<FJsonValue>>* Vertices = nullptr;
        if (!String(T, TEXT("terrain_feature_id"), Item.Id) || !FStringView(*Pair.Key, Pair.Key.Len()).Equals(Item.Id, ESearchCase::CaseSensitive) || !IsString(Footprint, TEXT("kind"), TEXT("polygon")) ||
            !Array(Footprint, TEXT("vertices"), Vertices) || Vertices->Num() < 3)
        { OutError = TEXT("Unsupported Core terrain footprint; no replacement geometry was invented."); return false; }
        for (const auto& V : *Vertices)
        {
            double X, Y; const auto Point = V->Type == EJson::Object ? V->AsObject() : nullptr;
            if (!Number(Point, TEXT("x_inches"), X) || !Number(Point, TEXT("y_inches"), Y)) { OutError = TEXT("Invalid terrain vertex."); return false; }
            Item.PolygonInches.Emplace(X, Y);
        }
        const TArray<TSharedPtr<FJsonValue>>* Volumes = nullptr;
        if (!Array(T, TEXT("volumes"), Volumes)) { OutError = TEXT("Missing terrain volumes."); return false; }
        for (const auto& V : *Volumes)
        {
            double Height; const auto Volume = V->Type == EJson::Object ? V->AsObject() : nullptr;
            if (!Number(Volume, TEXT("height_inches"), Height) || Height < 0) { OutError = TEXT("Invalid terrain volume height."); return false; }
            Item.HeightInches = FMath::Max(Item.HeightInches, Height);
        }
        Candidate.Terrain.Add(MoveTemp(Item));
    }
    for (const auto& Pair : Objectives->Values)
    {
        const auto Objective = Pair.Value->Type == EJson::Object ? Pair.Value->AsObject() : nullptr;
        FLiveCoreObjective Item; double Diameter = 0.0;
        if (!String(Objective, TEXT("objective_id"), Item.Id) || !FStringView(*Pair.Key, Pair.Key.Len()).Equals(Item.Id, ESearchCase::CaseSensitive) ||
            !Position(Object(Objective, TEXT("position")), Item.PositionInches) || !Number(Objective, TEXT("marker_diameter_inches"), Diameter) || Diameter <= 0)
        { OutError = TEXT("Invalid Core objective marker."); return false; }
        Item.RadiusInches = Diameter / 2.0; Candidate.Objectives.Add(MoveTemp(Item));
    }
    for (const auto& Pair : Models->Values)
    {
        const auto Model = Pair.Value->Type == EJson::Object ? Pair.Value->AsObject() : nullptr;
        FString ModelState;
        if (!String(Model, TEXT("state"), ModelState)) { OutError = TEXT("Missing model placement state."); return false; }
        if (!Exact(ModelState, TEXT("placed"))) { continue; }
        FLiveCoreModel Item;
        const auto Shape = Object(Object(Model, TEXT("geometry")), TEXT("support_shape"));
        if (!String(Model, TEXT("model_instance_id"), Item.Id) || !FStringView(*Pair.Key, Pair.Key.Len()).Equals(Item.Id, ESearchCase::CaseSensitive) ||
            !String(Model, TEXT("owner_player_id"), Item.OwnerPlayerId) || !Position(Object(Object(Model, TEXT("pose")), TEXT("position")), Item.PositionInches) ||
            !IsString(Shape, TEXT("kind"), TEXT("circle")) || !Number(Shape, TEXT("radius_inches"), Item.RadiusInches) || Item.RadiusInches <= 0)
        { OutError = TEXT("Placed model lacks supported actual pose/base geometry."); return false; }
        Candidate.Models.Add(MoveTemp(Item));
    }
    const TArray<TSharedPtr<FJsonValue>>* Choices = nullptr;
    if (!Array(P, TEXT("public_secondary_mission_choices"), Choices)) { OutError = TEXT("Missing scoped mission choices."); return false; }
    for (const auto& V : *Choices)
    {
        const auto Choice = V->Type == EJson::Object ? V->AsObject() : nullptr;
        FString Player;
        if (!String(Choice, TEXT("player_id"), Player)) { OutError = TEXT("Invalid scoped mission choice."); return false; }
        if (!Exact(Player, TEXT("player-a"))) { continue; }
        bool Hidden = true; FString Mode;
        const TArray<TSharedPtr<FJsonValue>>* Missions = nullptr;
        if (!Boolean(Choice, TEXT("hidden"), Hidden) || Hidden || !String(Choice, TEXT("mode"), Mode) || !Array(Choice, TEXT("fixed_mission_ids"), Missions))
        { OutError = TEXT("Own mission choice is missing its explicit public values."); return false; }
        TArray<FString> Names;
        for (const auto& M : *Missions) { FString S; if (M->Type != EJson::String || !M->TryGetString(S)) { OutError = TEXT("Invalid mission ID."); return false; } Names.Add(S); }
        Candidate.MissionSummary = Mode + (Names.IsEmpty() ? FString() : TEXT(": ") + FString::Join(Names, TEXT(", ")));
    }
    const auto PendingValue = Field(P, TEXT("pending_decision"));
    if (!PendingValue.IsValid()) { OutError = TEXT("Missing pending decision field."); return false; }
    if (PendingValue->Type != EJson::Null)
    {
        const auto Pending = PendingValue->Type == EJson::Object ? PendingValue->AsObject() : nullptr;
        if (!IsString(Pending, TEXT("schema_version"), TEXT("decision-request-view-v5-phase17n-step4")) || !String(Pending, TEXT("decision_type"), Candidate.RequestType))
        { OutError = TEXT("Invalid current DecisionRequest schema/type."); return false; }
        if (!Exact(Candidate.RequestType, TEXT("hidden_decision")))
        {
            FString Actor; bool Parameterized = true;
            if (!String(Pending, TEXT("request_id"), Candidate.RequestId) || !String(Pending, TEXT("actor_id"), Actor) || !Boolean(Pending, TEXT("is_parameterized"), Parameterized))
            { OutError = TEXT("Incomplete offered DecisionRequest."); return false; }
            if (Exact(Actor, TEXT("player-a")) && !Parameterized)
            {
                const TArray<TSharedPtr<FJsonValue>>* Options = nullptr;
                if (!Array(Pending, TEXT("options"), Options)) { OutError = TEXT("Missing offered finite options."); return false; }
                TSet<FString> Ids;
                for (const auto& V : *Options)
                {
                    const auto Option = V->Type == EJson::Object ? V->AsObject() : nullptr; FLiveCoreOption Item;
                    if (!String(Option, TEXT("option_id"), Item.Id) || !String(Option, TEXT("label"), Item.Label) || Ids.Contains(Item.Id))
                    { OutError = TEXT("Invalid or duplicate offered option ID."); return false; }
                    Ids.Add(Item.Id); Candidate.Options.Add(MoveTemp(Item));
                }
            }
        }
    }
    // A fresh valid snapshot recovers a GET/parser error, while a known recorded
    // command rejection remains visible until a subsequent command resolves it.
    Candidate.Error = Candidate.RecordedCommandError;
    OutState = MoveTemp(Candidate); OutError.Reset(); return true;
}

bool ReadOutcome(const FString& Text, int32 HttpStatus, const FString& CommandId, const FString& SessionId,
    int64 ExpectedRevision, bool bAdministrator, const FString& Operation, FOutcome& OutOutcome, FString& OutError)
{
    E01::FOutcome Parsed; E01::FReadError Error;
    if (!E01::ReadOutcome(HttpStatus, Text, Parsed, Error)) { OutError = TEXT("Unusable command receipt: ") + Error.Code; return false; }
    FOutcome Candidate; Candidate.bError = !Parsed.bCommandOutcome; Candidate.bRequiresReconciliation = Candidate.bError;
    Candidate.Code = Parsed.Code; Candidate.Message = Parsed.Message;
    if (!Parsed.FidelityGap.IsEmpty()) { Candidate.Message += TEXT(" ") + Parsed.FidelityGap; }
    if (Parsed.bCommandOutcome)
    {
        const auto Metadata = Object(Parsed.Json, TEXT("session"));
        FString ActualSession, ActualOperation;
        if (!Exact(Parsed.CommandId, CommandId) || !String(Metadata, TEXT("session_id"), ActualSession) || !Exact(ActualSession, SessionId) ||
            !String(Parsed.Json, TEXT("operation"), ActualOperation) || !Exact(ActualOperation, Operation) || !Identity(Metadata) ||
            !Scope(Object(Metadata, TEXT("visibility")), bAdministrator) || !Parsed.SessionRevision.IsSet() ||
            ExpectedRevision >= E01::MaximumExactRevision || Parsed.SessionRevision.GetValue() != ExpectedRevision + (Parsed.bCommitted ? 1 : 0))
        { OutError = TEXT("Command receipt identity, viewer, Core build or revision does not match the retained command."); return false; }
        Candidate.bAccepted = Parsed.bAccepted; Candidate.bCommitted = Parsed.bCommitted; Candidate.Revision = Parsed.SessionRevision.GetValue();
        // Only inspect supplied diagnostics after all receipt identity/scope gates.
        // This is returned lifecycle status; an uncommitted result can retain older status.
        const auto Lifecycle = Object(Metadata, TEXT("lifecycle_status"));
        const auto LifecycleMessage = Field(Lifecycle, TEXT("message"));
        if (!Null(Lifecycle, TEXT("message")) && (!LifecycleMessage.IsValid() || LifecycleMessage->Type != EJson::String ||
            !LifecycleMessage->TryGetString(Candidate.ReturnedLifecycleMessage) || Candidate.ReturnedLifecycleMessage.Len() > 4096))
        { OutError = TEXT("Returned lifecycle message is invalid or exceeds the display bound."); return false; }
        const auto Payload = Object(Lifecycle, TEXT("payload"));
        const auto ViolationCode = Field(Payload, TEXT("violation_code"));
        if (ViolationCode.IsValid() && ViolationCode->Type != EJson::Null && !String(Payload, TEXT("violation_code"), Candidate.ReturnedViolationCode))
        { OutError = TEXT("Returned lifecycle violation code is invalid."); return false; }
        const auto ValidationValue = Field(Payload, TEXT("proposal_validation"));
        if (ValidationValue.IsValid() && ValidationValue->Type != EJson::Null)
        {
            const auto Validation = Object(Payload, TEXT("proposal_validation"));
            const TArray<TSharedPtr<FJsonValue>>* Violations = nullptr;
            if (!Array(Validation, TEXT("violations"), Violations))
            { OutError = TEXT("Returned lifecycle violations are invalid or exceed the display bound."); return false; }
            for (const auto& Value : *Violations)
            {
                const auto Violation = Value->Type == EJson::Object ? Value->AsObject() : nullptr;
                FReturnedViolation Item; FString FieldName;
                if (!String(Violation, TEXT("violation_code"), Item.Code) || !String(Violation, TEXT("message"), Item.Message) ||
                    (!Null(Violation, TEXT("field")) && !String(Violation, TEXT("field"), FieldName)))
                { OutError = TEXT("Returned lifecycle violation has invalid fields."); return false; }
                if (!Null(Violation, TEXT("field"))) { Item.Field = MoveTemp(FieldName); }
                Candidate.ReturnedViolations.Add(MoveTemp(Item));
            }
        }
    }
    OutOutcome = MoveTemp(Candidate); OutError.Reset(); return true;
}
bool ApplyKnownCommandOutcome(const FOutcome& Outcome, int32 HttpStatus, bool bFiniteAction, FLiveCoreState& State)
{
    if (Outcome.bError || Outcome.Revision < State.SessionRevision || Outcome.Revision < 0) { return false; }
    State.bLastCommandHasOutcome = true; State.bLastCommandAccepted = Outcome.bAccepted; State.bLastCommandCommitted = Outcome.bCommitted;
    State.LastOutcomeCode = Outcome.Code; State.SessionRevision = Outcome.Revision;
    // Receipt revision is not evidence that matching board/model DTOs have arrived.
    if (Outcome.bAccepted)
    {
        State.RecordedCommandError.Reset(); State.Error.Reset();
        if (bFiniteAction) { ++State.AcceptedActionCount; }
    }
    else
    {
        TArray<FString> Details;
        if (!Outcome.ReturnedLifecycleMessage.IsEmpty())
        { Details.Add(TEXT("Returned lifecycle status: ") + Outcome.ReturnedLifecycleMessage); }
        for (const auto& Violation : Outcome.ReturnedViolations)
        {
            const FString FieldName = Violation.Field.IsSet() ? TEXT(" [") + Violation.Field.GetValue() + TEXT("]") : FString();
            Details.Add(TEXT("Returned lifecycle violation: ") + Violation.Code + FieldName + TEXT(": ") + Violation.Message);
        }
        if (Outcome.ReturnedViolations.IsEmpty() && !Outcome.ReturnedViolationCode.IsEmpty())
        { Details.Add(TEXT("Returned lifecycle violation code: ") + Outcome.ReturnedViolationCode); }
        if (Details.IsEmpty())
        { Details.Add(TEXT("Core recorded a rejected command. Detailed engine reasons were not supplied by this HTTP response.")); }
        State.RecordedCommandError = ErrorText(HttpStatus, Outcome.Code, FString::Join(Details, TEXT("\n")));
        State.Error = State.RecordedCommandError;
    }
    return true;
}
FString MakeStartCommand(const FString& SessionId, const FString& CommandId) { return Command(SessionId, CommandId, 0, nullptr, nullptr); }
FString MakeFiniteCommand(const FString& SessionId, const FString& CommandId, int64 RevisionValue, const FString& RequestId, const FString& OptionId)
{
    return Command(SessionId, CommandId, RevisionValue, &RequestId, &OptionId);
}
}

TSharedRef<FLiveCoreSession> FLiveCoreSession::Create() { return MakeShared<FLiveCoreSession>(); }
FLiveCoreSession::~FLiveCoreSession() { Shutdown(); }
void FLiveCoreSession::Changed() { check(IsInGameThread()); OnChanged.ExecuteIfBound(); }
void FLiveCoreSession::Fail(const FString& Message) { State.bBusy = false; State.Error = Message; State.Status = TEXT("Core operation stopped."); Changed(); }
void FLiveCoreSession::MarkUnknown(const FString& Message, bool bCreation)
{
    State.bBusy = false; State.bUnknown = true; State.bCanReconcile = !bCreation && PendingCommand.IsSet();
    State.Options.Reset(); State.Error = Message;
    State.Status = bCreation ? TEXT("Session creation UNKNOWN. No retry or recreation is safe in this client.") :
        TEXT("Command outcome UNKNOWN. No new action is allowed; explicitly reconcile the retained command.");
    Changed();
}
void FLiveCoreSession::InitializeEndpoint(const FString& Endpoint)
{
    check(IsInGameThread()); if (bStopped) { return; }
    FString Valid, Error;
    if (State.bBusy || State.bUnknown) { return; }
    if (State.bHasSession && !Exact(Endpoint, State.Endpoint))
    { Fail(TEXT("Finish or reconcile the current session before changing its endpoint.")); return; }
    if (!LiveCoreProtocol::ValidateEndpoint(Endpoint, Valid, Error)) { Fail(Error); return; }
    State.Endpoint = Valid; State.Error.Reset(); Changed();
}
void FLiveCoreSession::CreateAndStart(const FString& Endpoint)
{
    check(IsInGameThread());
    if (bStopped || State.bBusy || State.bUnknown || State.bHasSession) { return; }
    FString Valid, Error;
    if (!LiveCoreProtocol::ValidateEndpoint(Endpoint, Valid, Error)) { Fail(Error); return; }
    InitializeEndpoint(Valid); NewSession();
}
void FLiveCoreSession::NewSession()
{
    check(IsInGameThread()); if (bStopped) { return; }
    if (State.bBusy || State.bUnknown) { return; }
    if (State.bHasSession) { Fail(TEXT("This client already owns an attached session. It will not silently replace or recreate it.")); return; }
    FString Valid, Error;
    if (!LiveCoreProtocol::ValidateEndpoint(State.Endpoint, Valid, Error)) { Fail(Error); return; }
    const FString Admin = FPlatformMisc::GetEnvironmentVariable(TEXT("WH_CORE_ADMIN_TOKEN"));
    const FString Player = FPlatformMisc::GetEnvironmentVariable(TEXT("WH_CORE_PLAYER_TOKEN"));
    if (!CredentialValid(Admin) || !CredentialValid(Player))
    { Fail(TEXT("Set WH_CORE_ADMIN_TOKEN and WH_CORE_PLAYER_TOKEN for the approved development registry before starting the client. Values are never logged.")); return; }
    // Preserve exact credentials in memory for this session and any same-command reconciliation.
    AdministratorToken = Admin; PlayerToken = Player;
    State = FLiveCoreState(); State.Endpoint = Valid; PendingCommand.Reset(); CreatingGameId.Reset();
    State.Status = TEXT("Checking the existing loopback Core service…");
    const TWeakPtr<FLiveCoreSession> Weak = AsShared();
    Request(TEXT("GET"), TEXT("/rules-catalog"), ECredential::Administrator, FString(), false,
        [Weak](int32 Status, const FString& Text)
        {
            if (const auto Self = Weak.Pin())
            {
                if (Status != 200)
                {
                    LiveCoreProtocol::FOutcome Received; FString ParseError;
                    if (LiveCoreProtocol::ReadOutcome(Text, Status, FString(), FString(), 0, true, FString(), Received, ParseError) && Received.bError)
                    { Self->Fail(ErrorText(Status, Received.Code, Received.Message)); }
                    else { Self->Fail(ErrorText(Status, TEXT("readiness_failed"), TEXT("No usable authenticated Core catalog response was supplied."))); }
                    return;
                }
                TSharedPtr<FJsonObject> Catalog; FString Error;
                if (!Parse(Text, Catalog, Error)) { Self->Fail(Error); return; }
                Self->CreateCanonicalSession();
            }
        });
}
void FLiveCoreSession::Request(const FString& Verb, const FString& Path, ECredential Credential,
    const FString& Body, bool bMutation, FReadReply&& OnReply)
{
    check(IsInGameThread()); if (bStopped || ActiveRequest.IsValid()) { return; }
#if WITH_DEV_AUTOMATION_TESTS
    if (RequestAttemptForTests) { RequestAttemptForTests(); return; }
#endif
    const FString& Token = Credential == ECredential::Administrator ? AdministratorToken : PlayerToken;
    if (!CredentialValid(Token)) { Fail(TEXT("The required development credential is unavailable.")); return; }
    auto Http = FHttpModule::Get().CreateRequest();
    Http->SetURL(State.Endpoint + Path); Http->SetVerb(Verb); Http->SetHeader(TEXT("Accept"), TEXT("application/json"));
    Http->SetHeader(TEXT("Authorization"), TEXT("Bearer ") + Token);
    if (!Body.IsEmpty()) { Http->SetHeader(TEXT("Content-Type"), TEXT("application/json")); Http->SetContentAsString(Body); }
    Http->SetTimeout(bMutation ? 120.0f : 30.0f);
    Http->SetDelegateThreadPolicy(EHttpRequestDelegateThreadPolicy::CompleteOnGameThread);
    const uint64 ExpectedGeneration = ++Generation;
    const TWeakPtr<FLiveCoreSession> Weak = AsShared();
    Http->OnProcessRequestComplete().BindLambda([Weak, ExpectedGeneration, bMutation, OnReply = MoveTemp(OnReply)]
        (FHttpRequestPtr CompletedRequest, FHttpResponsePtr Response, bool bSucceeded) mutable
        {
            const auto Self = Weak.Pin();
            if (!Self.IsValid() || Self->bStopped || Self->Generation != ExpectedGeneration || Self->ActiveRequest != CompletedRequest) { return; }
            check(IsInGameThread()); Self->ActiveRequest.Reset(); Self->State.bBusy = false;
            Self->State.LastHttpStatus = Response.IsValid() ? Response->GetResponseCode() : 0;
            FString Text;
            if (!bSucceeded || !Response.IsValid() || !DecodeUtf8(Response->GetContent(), Text))
            {
                const FString Message = FString::Printf(TEXT("HTTP %d: no complete bounded UTF-8 response was received. Completion is not a rejection."), Self->State.LastHttpStatus);
                if (bMutation) { Self->MarkUnknown(Message, !Self->PendingCommand.IsSet()); } else { Self->Fail(Message); }
                return;
            }
            OnReply(Self->State.LastHttpStatus, Text);
        });
    ActiveRequest = Http; State.bBusy = true; Changed();
    if (bStopped || Generation != ExpectedGeneration) { return; }
    if (!Http->ProcessRequest() && ActiveRequest == Http)
    {
        Http->OnProcessRequestComplete().Unbind(); ActiveRequest.Reset();
        if (bMutation) { MarkUnknown(TEXT("Core submission could not complete. Its outcome is UNKNOWN."), !PendingCommand.IsSet()); }
        else { Fail(TEXT("Could not send the Core HTTP request. Check the loopback service.")); }
    }
}
void FLiveCoreSession::CreateCanonicalSession()
{
    TSharedPtr<FJsonObject> Payload; FString Error;
    if (!LiveCoreRuntimeData::ReadCanonicalSessionCreate(LiveCoreRuntimeData::CanonicalSessionCreatePath(), Payload, Error))
    { Fail(Error); return; }
    CreatingGameId = TEXT("unreal-live-") + FGuid::NewGuid().ToString(EGuidFormats::Digits);
    Object(Payload, TEXT("config"))->SetStringField(TEXT("game_id"), CreatingGameId);
    State.Status = TEXT("Creating one canonical development session…");
    const TWeakPtr<FLiveCoreSession> Weak = AsShared();
    Request(TEXT("POST"), TEXT("/sessions"), ECredential::Administrator, Json(Payload.ToSharedRef()), true,
        [Weak](int32 Status, const FString& Response)
        {
            if (const auto Self = Weak.Pin())
            {
                Self->HandleCreateReply(Status, Response);
            }
        });
}
void FLiveCoreSession::HandleCreateReply(int32 Status, const FString& Response)
{
    check(IsInGameThread());
    State.LastHttpStatus = Status;
    LiveCoreProtocol::FMetadata Metadata; FString Error;
    if (Status != 201)
    {
        LiveCoreProtocol::FOutcome Received;
        if (LiveCoreProtocol::ReadOutcome(Response, Status, FString(), FString(), 0, true, FString(), Received, Error) && Received.bError)
        { MarkUnknown(ErrorText(Status, Received.Code, Received.Message), true); }
        else { MarkUnknown(ErrorText(Status, TEXT("creation_unknown"), TEXT("Session creation has no retry identity.")), true); }
        return;
    }
    if (!LiveCoreProtocol::ReadCreatedSession(Response, Metadata, Error) || !Exact(Metadata.GameId, CreatingGameId))
    { MarkUnknown(Error.IsEmpty() ? TEXT("Created game identity does not match the submitted configuration.") : Error, true); return; }
    State.SessionId = Metadata.SessionId; State.SessionRevision = Metadata.Revision; State.bHasSession = true;
    FPendingCommand Command; Command.Id = TEXT("unreal-start-") + FGuid::NewGuid().ToString(EGuidFormats::Digits);
    Command.Body = LiveCoreProtocol::MakeStartCommand(Metadata.SessionId, Command.Id); Command.Operation = TEXT("start_session");
    Command.ExpectedRevision = 0; Command.Credential = ECredential::Administrator;
    PendingCommand = MoveTemp(Command); SendPendingCommand();
}
void FLiveCoreSession::SelectOfferedOption(const FString& OptionId)
{
    check(IsInGameThread());
    if (bStopped || State.bBusy || State.bUnknown || !State.bHasSession || PendingCommand.IsSet()) { return; }
    if (State.RequestId.IsEmpty() || !State.Options.ContainsByPredicate([&](const FLiveCoreOption& Option) { return Option.bAvailable && Exact(Option.Id, OptionId); }))
    { Fail(TEXT("Only an option from the current authenticated player's offered request may be submitted.")); return; }
    if (State.SessionRevision < 0 || State.SessionRevision >= E01::MaximumExactRevision) { Fail(TEXT("Session revision cannot be represented safely.")); return; }
    FPendingCommand Command; Command.Id = TEXT("unreal-choice-") + FGuid::NewGuid().ToString(EGuidFormats::Digits);
    Command.ExpectedRevision = State.SessionRevision; Command.Operation = TEXT("submit_finite_decision"); Command.bFiniteAction = true;
    Command.Body = LiveCoreProtocol::MakeFiniteCommand(State.SessionId, Command.Id, State.SessionRevision, State.RequestId, OptionId);
    PendingCommand = MoveTemp(Command); State.Options.Reset(); State.Error.Reset(); State.RecordedCommandError.Reset(); State.bLastCommandHasOutcome = false;
    SendPendingCommand();
}
void FLiveCoreSession::SendPendingCommand()
{
    if (!PendingCommand.IsSet() || State.bBusy || bStopped) { return; }
    const FPendingCommand Retained = PendingCommand.GetValue();
    State.Status = State.bUnknown ? TEXT("Reconciling the exact retained command…") : TEXT("Waiting for the authoritative command outcome…");
    const TWeakPtr<FLiveCoreSession> Weak = AsShared();
    Request(TEXT("POST"), TEXT("/sessions/") + State.SessionId + TEXT("/commands"), Retained.Credential, Retained.Body, true,
        [Weak, Retained](int32 Status, const FString& Text)
        {
            if (const auto Self = Weak.Pin())
            {
                LiveCoreProtocol::FOutcome Outcome; FString Error;
                if (!LiveCoreProtocol::ReadOutcome(Text, Status, Retained.Id, Self->State.SessionId, Retained.ExpectedRevision,
                    Retained.Credential == ECredential::Administrator, Retained.Operation, Outcome, Error))
                { Self->MarkUnknown(ErrorText(Status, TEXT("unusable_receipt"), Error), false); return; }
                if (Outcome.bError)
                {
                    // Even HTTP422 can lack flags after an uncertain mutation. Keep the
                    // exact envelope and scope for explicit reconciliation for all errors.
                    Self->State.bLastCommandHasOutcome = false; Self->State.LastOutcomeCode = Outcome.Code;
                    Self->MarkUnknown(ErrorText(Status, Outcome.Code, Outcome.Message), false); return;
                }
                if (!LiveCoreProtocol::ApplyKnownCommandOutcome(Outcome, Status, Retained.bFiniteAction, Self->State))
                { Self->MarkUnknown(TEXT("Known command receipt could not be applied without regressing session state."), false); return; }
                Self->PendingCommand.Reset(); Self->State.bUnknown = false; Self->State.bCanReconcile = false;
                Self->FetchProjection();
            }
        });
}
void FLiveCoreSession::FetchProjection()
{
    // No old offered action becomes enabled if a refresh fails.
    State.Options.Reset();
    const TWeakPtr<FLiveCoreSession> Weak = AsShared();
    Request(TEXT("GET"), TEXT("/sessions/") + State.SessionId + TEXT("/projection"), ECredential::PlayerA, FString(), false,
        [Weak](int32 Status, const FString& Text)
        {
            if (const auto Self = Weak.Pin())
            {
                if (Status != 200)
                {
                    LiveCoreProtocol::FOutcome Error; FString ParseError;
                    if (LiveCoreProtocol::ReadOutcome(Text, Status, FString(), FString(), 0, false, FString(), Error, ParseError) && Error.bError)
                    { Self->Fail(ErrorText(Status, Error.Code, Error.Message)); }
                    else { Self->Fail(ErrorText(Status, TEXT("projection_failed"), TEXT("No usable authenticated projection was supplied."))); }
                    return;
                }
                FString Error;
                if (!LiveCoreProtocol::ReadProjection(Text, Self->State.SessionId, Self->State, Error)) { Self->State.Options.Reset(); Self->Fail(Error); return; }
                Self->State.Status = !Self->State.RecordedCommandError.IsEmpty() ? TEXT("Core recorded a rejected command; authoritative state refreshed.") :
                    Self->State.AcceptedActionCount > 0 ? TEXT("Core accepted the player action; authoritative state refreshed.") : TEXT("Connected. Choose an option offered by Core.");
                Self->Changed();
            }
        });
}
void FLiveCoreSession::Refresh()
{
    check(IsInGameThread()); if (!bStopped && State.bHasSession && !State.bBusy && !State.bUnknown && !PendingCommand.IsSet()) { FetchProjection(); }
}
void FLiveCoreSession::ReconcileUnknown()
{
    check(IsInGameThread());
    if (!bStopped && State.bUnknown && State.bCanReconcile && PendingCommand.IsSet() && !State.bBusy) { SendPendingCommand(); }
}
void FLiveCoreSession::Shutdown()
{
    bStopped = true; ++Generation;
    if (ActiveRequest.IsValid()) { ActiveRequest->OnProcessRequestComplete().Unbind(); ActiveRequest->CancelRequest(); ActiveRequest.Reset(); }
    OnChanged.Unbind(); PendingCommand.Reset(); AdministratorToken.Reset(); PlayerToken.Reset(); State.bBusy = false;
    // This client attaches to a service. It never stops a host or closes its sessions on teardown.
}
