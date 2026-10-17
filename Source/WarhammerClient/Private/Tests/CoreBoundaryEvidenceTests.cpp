#include "Migration/CoreBoundaryEvidence.h"

#if WITH_DEV_AUTOMATION_TESTS

#include "Misc/AutomationTest.h"
#include "Misc/CommandLine.h"
#include "Misc/FileHelper.h"
#include "Misc/Parse.h"
#include "Misc/Paths.h"
#include "Serialization/JsonSerializer.h"

using namespace Warhammer::Migration::E01;

namespace
{
constexpr EAutomationTestFlags TestFlags = EAutomationTestFlags_ApplicationContextMask | EAutomationTestFlags::EngineFilter;

bool Exact(FStringView Left, FStringView Right)
{
    return Left.Equals(Right, ESearchCase::CaseSensitive);
}

bool ContainsExact(const TArray<FString>& Values, const FString& Value)
{
    return Values.ContainsByPredicate([&Value](const FString& Existing) { return Exact(Existing, Value); });
}

bool LoadRoot(FString& Root, FString& Error)
{
    if (!FParse::Value(FCommandLine::Get(), TEXT("E01FixtureRoot="), Root) || Root.IsEmpty() || FPaths::IsRelative(Root))
    {
        Error = TEXT("Supply -E01FixtureRoot=<absolute versioned fixture root>; missing fixtures fail, never skip.");
        return false;
    }
    FPaths::NormalizeDirectoryName(Root);
    return true;
}

bool LoadObject(const FString& Path, TSharedPtr<FJsonObject>& Object, FString& Error, FString* Raw = nullptr)
{
    FString Text;
    FReadError ReadError;
    if (!FFileHelper::LoadFileToString(Text, *Path))
    {
        Error = FString::Printf(TEXT("Required E01 fixture could not be read: %s"), *Path);
        return false;
    }
    if (!ParseObject(Text, Object, ReadError))
    {
        Error = FString::Printf(TEXT("E01 fixture parse failed (%s): %s"), *ReadError.Code, *Path);
        return false;
    }
    if (Raw != nullptr)
    {
        *Raw = MoveTemp(Text);
    }
    return true;
}

TSharedPtr<FJsonValue> Field(const TSharedPtr<FJsonObject>& Object, FStringView Name)
{
    if (Object.IsValid())
    {
        for (const auto& Pair : Object->Values)
        {
            if (Exact(FStringView(*Pair.Key, Pair.Key.Len()), Name))
            {
                return Pair.Value;
            }
        }
    }
    return nullptr;
}

bool IsType(const TSharedPtr<FJsonValue>& Value, EJson Type)
{
    return Value.IsValid() && Value->Type == Type;
}

bool String(const TSharedPtr<FJsonObject>& Object, const TCHAR* Name, FString& Out)
{
    const TSharedPtr<FJsonValue> Value = Field(Object, Name);
    return IsType(Value, EJson::String) && Value->TryGetString(Out) && !Out.IsEmpty();
}

bool Serialize(const TSharedPtr<FJsonObject>& Object, FString& Out)
{
    Out.Reset();
    return Object.IsValid() && FJsonSerializer::Serialize(Object.ToSharedRef(), TJsonWriterFactory<>::Create(&Out));
}

bool SameJson(const TSharedPtr<FJsonValue>& Left, const TSharedPtr<FJsonValue>& Right)
{
    if (!Left.IsValid() || !Right.IsValid() || Left->Type != Right->Type)
    {
        return false;
    }
    switch (Left->Type)
    {
    case EJson::Null: return true;
    case EJson::Boolean: return Left->AsBool() == Right->AsBool();
    case EJson::String: return Exact(Left->AsString(), Right->AsString());
    case EJson::Number:
    {
        FString LeftToken;
        FString RightToken;
        return Left->PreferStringRepresentation() && Right->PreferStringRepresentation() &&
            Left->TryGetString(LeftToken) && Right->TryGetString(RightToken) && Exact(LeftToken, RightToken);
    }
    case EJson::Array:
    {
        const TArray<TSharedPtr<FJsonValue>>& A = Left->AsArray();
        const TArray<TSharedPtr<FJsonValue>>& B = Right->AsArray();
        if (A.Num() != B.Num())
        {
            return false;
        }
        for (int32 Index = 0; Index < A.Num(); ++Index)
        {
            if (!SameJson(A[Index], B[Index]))
            {
                return false;
            }
        }
        return true;
    }
    case EJson::Object:
    {
        const TSharedPtr<FJsonObject>& A = Left->AsObject();
        const TSharedPtr<FJsonObject>& B = Right->AsObject();
        if (!A.IsValid() || !B.IsValid() || A->Values.Num() != B->Values.Num())
        {
            return false;
        }
        for (const auto& Pair : A->Values)
        {
            if (!SameJson(Pair.Value, Field(B, FStringView(*Pair.Key, Pair.Key.Len()))))
            {
                return false;
            }
        }
        return true;
    }
    default: return false;
    }
}

bool RoundTrip(const TSharedPtr<FJsonObject>& Object)
{
    FString Text;
    FReadError Error;
    TSharedPtr<FJsonObject> Parsed;
    return Serialize(Object, Text) && ParseObject(Text, Parsed, Error) &&
        SameJson(MakeShared<FJsonValueObject>(Object), MakeShared<FJsonValueObject>(Parsed));
}

bool LoadCases(const TCHAR* RelativePath, TArray<TSharedPtr<FJsonValue>>& Cases, FString& Error)
{
    FString Root;
    TSharedPtr<FJsonObject> Object;
    if (!LoadRoot(Root, Error) || !LoadObject(FPaths::Combine(Root, RelativePath), Object, Error) ||
        !IsType(Field(Object, TEXT("cases")), EJson::Array))
    {
        if (Error.IsEmpty())
        {
            Error = TEXT("E01 fixture must have a cases array.");
        }
        return false;
    }
    Cases = Field(Object, TEXT("cases"))->AsArray();
    return true;
}

bool SafeSlug(const FString& Slug)
{
    if (Slug.IsEmpty())
    {
        return false;
    }
    for (TCHAR Character : Slug)
    {
        if (!((Character >= TEXT('a') && Character <= TEXT('z')) ||
            (Character >= TEXT('A') && Character <= TEXT('Z')) ||
            (Character >= TEXT('0') && Character <= TEXT('9')) || Character == TEXT('_') || Character == TEXT('-')))
        {
            return false;
        }
    }
    return true;
}

bool WireEntry(const TSharedPtr<FJsonObject>& Entry, FString& CaseId, FString& Role, FString& Kind,
    FString& Path, FString& Expected, int32& Status)
{
    FString Recipe;
    FString Hash;
    FReadError Error;
    int64 Revision = 0;
    if (!Entry.IsValid() || Entry->Values.Num() != 8 || !String(Entry, TEXT("case_id"), CaseId) ||
        !String(Entry, TEXT("role"), Role) || !SafeSlug(Role) || !String(Entry, TEXT("kind"), Kind) ||
        (!Exact(Kind, TEXT("http")) && !Exact(Kind, TEXT("local")) && !Exact(Kind, TEXT("synthetic_negative"))) ||
        !String(Entry, TEXT("recipe"), Recipe) || !String(Entry, TEXT("path"), Path) ||
        !String(Entry, TEXT("sha256"), Hash) || Hash.Len() != 64 ||
        !String(Entry, TEXT("expected_outcome"), Expected) ||
        !ReadExactRevision(Field(Entry, TEXT("http_status")), Revision, Error) || Revision < 100 || Revision > 599)
    {
        return false;
    }
    for (TCHAR Character : Hash)
    {
        if (!FChar::IsHexDigit(Character))
        {
            return false;
        }
    }
    TArray<FString> Parts;
    Path.ParseIntoArray(Parts, TEXT("/"), false);
    if (Parts.Num() != 2 || !SafeSlug(Parts[0]) || !Exact(Parts[1], Role + TEXT(".json")))
    {
        return false;
    }
    Status = static_cast<int32>(Revision);
    return Exact(Expected, TEXT("accepted")) || Exact(Expected, TEXT("recorded_invalid")) ||
        Exact(Expected, TEXT("uncommitted_invalid")) || Exact(Expected, TEXT("error")) || Exact(Expected, TEXT("payload"));
}

bool LoadWire(TArray<TSharedPtr<FJsonValue>>& Cases, FString& Error)
{
    FString Root;
    TSharedPtr<FJsonObject> Index;
    FReadError ReadError;
    int64 Version = 0;
    if (!LoadRoot(Root, Error) || !LoadObject(FPaths::Combine(Root, TEXT("wire/index.json")), Index, Error))
    {
        return false;
    }
    if (Index->Values.Num() != 2 || !ReadExactRevision(Field(Index, TEXT("format_version")), Version, ReadError) ||
        Version != 1 || !IsType(Field(Index, TEXT("cases")), EJson::Array) || Field(Index, TEXT("cases"))->AsArray().IsEmpty())
    {
        Error = TEXT("Wire index requires format_version:1 and a nonempty cases array.");
        return false;
    }
    // Keep conservative case-insensitive file collision checks for Windows;
    // protocol case IDs below use exact comparisons independently of file names.
    TSet<FString> Paths;
    TArray<FString> Identities;
    Cases = Field(Index, TEXT("cases"))->AsArray();
    for (const TSharedPtr<FJsonValue>& Value : Cases)
    {
        FString CaseId, Role, Kind, Path, Expected;
        int32 Status = 0;
        if (!IsType(Value, EJson::Object) || !WireEntry(Value->AsObject(), CaseId, Role, Kind, Path, Expected, Status) ||
            Paths.Contains(Path) || ContainsExact(Identities, CaseId + TEXT("/") + Role))
        {
            Error = TEXT("Wire index has invalid fields, unsafe paths or duplicate identities/paths.");
            return false;
        }
        Paths.Add(Path);
        Identities.Add(CaseId + TEXT("/") + Role);
    }
    // Byte SHA256 and viewer-safe promotion are verified by the phase coordinator.
    // Native consumption does not independently establish capture provenance.
    return true;
}

bool CanonicalOutcome(FString& Text, TSharedPtr<FJsonObject>& Object, FString& Error)
{
    FString Root;
    return LoadRoot(Root, Error) && LoadObject(FPaths::Combine(Root,
        TEXT("contracts/examples/sessions/session-command-outcome.json")), Object, Error, &Text);
}
}

IMPLEMENT_COMPLEX_AUTOMATION_TEST(FE01CanonicalEnvelopes,
    "Warhammer.Migration.E01Boundary.CanonicalEnvelopes", TestFlags)

void FE01CanonicalEnvelopes::GetTests(TArray<FString>& Names, TArray<FString>& Commands) const
{
    FString Error;
    TArray<TSharedPtr<FJsonValue>> Cases;
    if (LoadCases(TEXT("contracts/examples/decisions/interaction-conformance.json"), Cases, Error) && Cases.Num() == 98)
    {
        for (const TSharedPtr<FJsonValue>& Value : Cases)
        {
            FString CaseId;
            if (IsType(Value, EJson::Object) && String(Value->AsObject(), TEXT("case_id"), CaseId))
            {
                Names.Add(CaseId);
                Commands.Add(CaseId);
            }
        }
    }
    if (Names.Num() != 98)
    {
        Names.Reset();
        Commands.Reset();
        Names.Add(TEXT("FixtureConfiguration"));
        Commands.Add(TEXT("FixtureConfiguration"));
    }
}

bool FE01CanonicalEnvelopes::RunTest(const FString& Parameters)
{
    FString Error;
    TArray<TSharedPtr<FJsonValue>> Cases;
    if (!LoadCases(TEXT("contracts/examples/decisions/interaction-conformance.json"), Cases, Error))
    {
        AddError(Error);
        return false;
    }
    for (const TSharedPtr<FJsonValue>& Value : Cases)
    {
        if (!IsType(Value, EJson::Object))
        {
            continue;
        }
        const TSharedPtr<FJsonObject> Case = Value->AsObject();
        FString CaseId;
        if (!String(Case, TEXT("case_id"), CaseId) || !Exact(CaseId, Parameters))
        {
            continue;
        }
        const TSharedPtr<FJsonValue> RequestValue = Field(Case, TEXT("request"));
        if (!IsType(RequestValue, EJson::Object))
        {
            AddError(TEXT("Canonical case requires a typed request object."));
            return false;
        }
        const TSharedPtr<FJsonObject> Request = RequestValue->AsObject();
        FString RequestId, ActorId, Variant;
        if (!String(Request, TEXT("request_id"), RequestId) || !String(Request, TEXT("actor_id"), ActorId) ||
            !String(Case, TEXT("submission_variant_id"), Variant) ||
            !IsType(Field(Request, TEXT("is_parameterized")), EJson::Boolean) ||
            !IsType(Field(Request, TEXT("options")), EJson::Array) ||
            Field(Request, TEXT("options"))->AsArray().IsEmpty() || !Field(Case, TEXT("proposal_payload")).IsValid())
        {
            AddError(TEXT("Canonical request/case has missing or incorrectly typed fields."));
            return false;
        }
        const bool bParameterized = Field(Request, TEXT("is_parameterized"))->AsBool();
        const TSharedPtr<FJsonObject> Submission = MakeShared<FJsonObject>();
        if (bParameterized)
        {
            if (!IsType(Field(Case, TEXT("proposal_payload")), EJson::Object))
            {
                AddError(TEXT("Parameterized canonical case requires its published typed payload."));
                return false;
            }
            Submission->SetStringField(TEXT("submission_kind"), TEXT("parameterized_payload"));
            Submission->SetField(TEXT("payload"), Field(Case, TEXT("proposal_payload")));
        }
        else
        {
            const TSharedPtr<FJsonValue> Option = Field(Request, TEXT("options"))->AsArray()[0];
            FString OptionId;
            if (!IsType(Field(Case, TEXT("proposal_payload")), EJson::Null) || !IsType(Option, EJson::Object) ||
                !String(Option->AsObject(), TEXT("option_id"), OptionId))
            {
                AddError(TEXT("Finite canonical case requires explicit null proposal and its offered opaque option ID."));
                return false;
            }
            Submission->SetStringField(TEXT("submission_kind"), TEXT("finite_option"));
            Submission->SetStringField(TEXT("option_id"), OptionId);
        }
        const TSharedPtr<FJsonObject> Envelope = MakeShared<FJsonObject>();
        Envelope->SetStringField(TEXT("schema_version"), TEXT("session-command-envelope-v2-weapon-instances"));
        // Explicit synthetic test framing; none of these envelopes is submitted to Core.
        Envelope->SetStringField(TEXT("command_id"), TEXT("e01-native-envelope-only:") + CaseId);
        Envelope->SetStringField(TEXT("session_id"), TEXT("e01-native-envelope-only"));
        Envelope->SetField(TEXT("expected_session_revision"), MakeShared<FJsonValueNumberString>(TEXT("17")));
        Envelope->SetStringField(TEXT("request_id"), RequestId);
        Envelope->SetStringField(TEXT("result_id"), TEXT("e01-native-envelope-only:") + CaseId);
        Envelope->SetObjectField(TEXT("submission"), Submission);
        FString Text;
        FCommandEnvelope Parsed;
        FReadError ReadError;
        if (!Serialize(Envelope, Text) || !ReadCommandEnvelope(Text, Parsed, ReadError))
        {
            AddError(TEXT("Native command reader rejected canonical envelope framing: ") + ReadError.Code);
            return false;
        }
        TestTrue(TEXT("Original request identity"), Exact(Parsed.RequestId.GetValue(), RequestId));
        TestTrue(TEXT("Opaque command identity"), Exact(Parsed.CommandId, TEXT("e01-native-envelope-only:") + CaseId));
        TestEqual(TEXT("Exact revision"), Parsed.ExpectedSessionRevision, static_cast<int64>(17));
        TestTrue(TEXT("Full canonical case retains nulls, JSON types, numeric lexemes and array order"), RoundTrip(Case));
        TestTrue(TEXT("Envelope retains full typed submission"), SameJson(Field(Parsed.Json, TEXT("submission")),
            MakeShared<FJsonValueObject>(Submission)));
        AddInfo(TEXT("Published conformance case consumed; synthetic envelope framing only, no live workflow or UE transport."));
        return true;
    }
    AddError(TEXT("Requested canonical case is missing; no skipped or empty fixture success."));
    return false;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FE01CanonicalInventory,
    "Warhammer.Migration.E01Boundary.CanonicalInventory", TestFlags)

bool FE01CanonicalInventory::RunTest(const FString& Parameters)
{
    FString Root, Error;
    TSharedPtr<FJsonObject> Manifest;
    TArray<TSharedPtr<FJsonValue>> Cases;
    if (!LoadRoot(Root, Error) || !LoadObject(FPaths::Combine(Root, TEXT("manifest.json")), Manifest, Error) ||
        !LoadCases(TEXT("contracts/examples/decisions/interaction-conformance.json"), Cases, Error))
    {
        AddError(Error);
        return false;
    }
    const TSharedPtr<FJsonValue> Expected = Field(Manifest, TEXT("CanonicalInteractionCaseIds"));
    if (!IsType(Expected, EJson::Array))
    {
        AddError(TEXT("Frozen source manifest requires CanonicalInteractionCaseIds."));
        return false;
    }
    TArray<FString> ActualIds;
    TArray<FString> ExpectedIds;
    int32 Finite = 0, Nested = 0, Parameterized = 0;
    for (const TSharedPtr<FJsonValue>& Value : Cases)
    {
        FString Id;
        if (!IsType(Value, EJson::Object) || !String(Value->AsObject(), TEXT("case_id"), Id) || ContainsExact(ActualIds, Id))
        {
            AddError(TEXT("Canonical case IDs must be present and unique."));
            return false;
        }
        ActualIds.Add(Id);
        Finite += Id.StartsWith(TEXT("finite:"), ESearchCase::CaseSensitive) ? 1 : 0;
        Nested += Id.StartsWith(TEXT("nested:"), ESearchCase::CaseSensitive) ? 1 : 0;
        Parameterized += Id.StartsWith(TEXT("parameterized:"), ESearchCase::CaseSensitive) ? 1 : 0;
    }
    for (const TSharedPtr<FJsonValue>& Value : Expected->AsArray())
    {
        if (!IsType(Value, EJson::String) || ContainsExact(ExpectedIds, Value->AsString()))
        {
            AddError(TEXT("Frozen manifest IDs must be unique strings."));
            return false;
        }
        ExpectedIds.Add(Value->AsString());
    }
    TestEqual(TEXT("Canonical total"), ActualIds.Num(), 98);
    TestEqual(TEXT("Top-level finite"), Finite, 73);
    TestEqual(TEXT("Nested finite"), Nested, 1);
    TestEqual(TEXT("Parameterized"), Parameterized, 24);
    TestEqual(TEXT("Manifest case count"), ExpectedIds.Num(), 98);
    for (const FString& Id : ActualIds)
    {
        TestTrue(TEXT("Canonical ID occurs in frozen source manifest"), ContainsExact(ExpectedIds, Id));
    }
    return true;
}

IMPLEMENT_COMPLEX_AUTOMATION_TEST(FE01ActualWire,
    "Warhammer.Migration.E01Boundary.Wire", TestFlags)

void FE01ActualWire::GetTests(TArray<FString>& Names, TArray<FString>& Commands) const
{
    FString Error;
    TArray<TSharedPtr<FJsonValue>> Cases;
    if (LoadWire(Cases, Error))
    {
        for (const TSharedPtr<FJsonValue>& Value : Cases)
        {
            const TSharedPtr<FJsonObject> Entry = Value->AsObject();
            const FString Identity = Entry->GetStringField(TEXT("case_id")) + TEXT("/") + Entry->GetStringField(TEXT("role"));
            Names.Add(Identity);
            Commands.Add(Identity);
        }
    }
    if (Names.IsEmpty())
    {
        Names.Add(TEXT("FixtureConfiguration"));
        Commands.Add(TEXT("FixtureConfiguration"));
    }
}

bool FE01ActualWire::RunTest(const FString& Parameters)
{
    FString Root, Error;
    TArray<TSharedPtr<FJsonValue>> Cases;
    if (!LoadRoot(Root, Error) || !LoadWire(Cases, Error))
    {
        AddError(Error);
        return false;
    }
    for (const TSharedPtr<FJsonValue>& Value : Cases)
    {
        FString CaseId, Role, Kind, Path, Expected;
        int32 Status = 0;
        WireEntry(Value->AsObject(), CaseId, Role, Kind, Path, Expected, Status);
        if (!Exact(CaseId + TEXT("/") + Role, Parameters))
        {
            continue;
        }
        FString Raw;
        TSharedPtr<FJsonObject> Body;
        if (!LoadObject(FPaths::Combine(Root, TEXT("wire"), Path), Body, Error, &Raw))
        {
            AddError(Error);
            return false;
        }
        TestTrue(TEXT("Actual parsed wire body preserves full JSON tree"), RoundTrip(Body));
        if (!Exact(Expected, TEXT("payload")))
        {
            FOutcome Outcome;
            FReadError ReadError;
            if (!ReadOutcome(Status, Raw, Outcome, ReadError))
            {
                AddError(TEXT("Selected wire outcome rejected: ") + ReadError.Code);
                return false;
            }
            TestTrue(TEXT("Actual outcome branch"), Exact(OutcomeName(Outcome.Kind), Expected));
            TestEqual(TEXT("Actual HTTP status retained"), Outcome.HttpStatus, Status);
            if (!Outcome.bCommandOutcome)
            {
                TestTrue(TEXT("Actual server code retained"), Exact(Outcome.Code, Body->GetObjectField(TEXT("error"))->GetStringField(TEXT("code"))));
                TestTrue(TEXT("Actual server message retained"), Exact(Outcome.Message, Body->GetObjectField(TEXT("error"))->GetStringField(TEXT("message"))));
                if (Outcome.Kind == EOutcomeKind::UncommittedInvalid)
                {
                    TestTrue(TEXT("Missing wire detail is explicit"), Outcome.FidelityGap.Contains(TEXT("not supplied")));
                }
            }
        }
        AddInfo(TEXT("Evidence kind: ") + Kind + TEXT("; native fixture consumption only; no UE HTTP request was executed."));
        return true;
    }
    AddError(TEXT("Requested wire fixture is missing."));
    return false;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FE01WireCoverage,
    "Warhammer.Migration.E01Boundary.WireRequiredCoverage", TestFlags)

bool FE01WireCoverage::RunTest(const FString& Parameters)
{
    FString Root, Error;
    TArray<TSharedPtr<FJsonValue>> Cases;
    if (!LoadRoot(Root, Error) || !LoadWire(Cases, Error))
    {
        AddError(Error);
        return false;
    }
    bool bAccepted = false, bRecorded422 = false, bErrorEnvelope422 = false, bError = false;
    int32 RealHttp = 0;
    for (const TSharedPtr<FJsonValue>& Value : Cases)
    {
        FString CaseId, Role, Kind, Path, Expected;
        int32 Status = 0;
        WireEntry(Value->AsObject(), CaseId, Role, Kind, Path, Expected, Status);
        if (!Exact(Kind, TEXT("http")) || Exact(Expected, TEXT("payload")))
        {
            continue;
        }
        FString Raw;
        TSharedPtr<FJsonObject> Body;
        FOutcome Outcome;
        FReadError ReadError;
        if (!LoadObject(FPaths::Combine(Root, TEXT("wire"), Path), Body, Error, &Raw) ||
            !ReadOutcome(Status, Raw, Outcome, ReadError))
        {
            AddError(TEXT("Required actual HTTP evidence could not be classified: ") + Error + ReadError.Code);
            return false;
        }
        ++RealHttp;
        bAccepted |= Outcome.Kind == EOutcomeKind::Accepted;
        bRecorded422 |= Status == 422 && Outcome.bCommandOutcome && Outcome.Kind == EOutcomeKind::RecordedInvalid;
        bErrorEnvelope422 |= Status == 422 && !Outcome.bCommandOutcome && Outcome.Kind == EOutcomeKind::UncommittedInvalid;
        bError |= Outcome.Kind == EOutcomeKind::Error;
    }
    TestTrue(TEXT("Real HTTP accepted outcome required"), bAccepted);
    TestTrue(TEXT("Real HTTP 422 recorded-invalid outcome shape required"), bRecorded422);
    TestTrue(TEXT("Real HTTP 422 uncommitted error-envelope shape required"), bErrorEnvelope422);
    TestTrue(TEXT("Real HTTP typed error required"), bError);
    AddInfo(FString::Printf(TEXT("Classified %d actual HTTP outcomes; synthetic/local evidence cannot satisfy this coverage."), RealHttp));
    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FE01StrictNegatives,
    "Warhammer.Migration.E01Boundary.StrictNegatives", TestFlags)

bool FE01StrictNegatives::RunTest(const FString& Parameters)
{
    const TCHAR* InvalidJson[] = {TEXT(""), TEXT("null"), TEXT("[]"), TEXT("{\"a\":[1,]}"),
        TEXT("{\"a\":1,}"), TEXT("{\"a\":NaN}"), TEXT("{\"a\":Infinity}"), TEXT("{\"a\":01}"),
        TEXT("{\"a\":1e}"), TEXT("{\"a\":tRue}"), TEXT("{\"a\":1}{}"), TEXT("{\"a\":1,\"a\":2}"),
        TEXT("{\"a\":1,\"\\u0061\":2}"), TEXT("{/*comment*/\"a\":1}"), TEXT("{\"a\":\"\\q\"}")};
    for (const TCHAR* Text : InvalidJson)
    {
        TSharedPtr<FJsonObject> Object;
        FReadError Error;
        TestFalse(TEXT("Malformed/non-object/duplicate JSON fails visibly"), ParseObject(Text, Object, Error));
        TestFalse(TEXT("Parse failure returns no stale object"), Object.IsValid());
        TestFalse(TEXT("Parse failure has typed diagnostic"), Error.Code.IsEmpty());
    }
    const FString BaseEnvelope = TEXT("{\"schema_version\":\"session-command-envelope-v2-weapon-instances\",\"command_id\":\"00001:opaque\",\"session_id\":\"s:opaque\",\"expected_session_revision\":0,\"request_id\":null,\"result_id\":null,\"submission\":{\"submission_kind\":\"start_session\"}}");
    FCommandEnvelope Envelope;
    FReadError ReadError;
    TestTrue(TEXT("Explicit lifecycle nulls accepted"), ReadCommandEnvelope(BaseEnvelope, Envelope, ReadError));
    TestFalse(TEXT("Null request remains null"), Envelope.RequestId.IsSet());
    TestFalse(TEXT("Case-changed command schema rejected"), ReadCommandEnvelope(BaseEnvelope.Replace(
        TEXT("session-command-envelope-v2-weapon-instances"), TEXT("SESSION-COMMAND-ENVELOPE-V2-WEAPON-INSTANCES"),
        ESearchCase::CaseSensitive), Envelope, ReadError));
    TestFalse(TEXT("Case-changed command field name rejected"), ReadCommandEnvelope(BaseEnvelope.Replace(
        TEXT("\"command_id\""), TEXT("\"COMMAND_ID\""), ESearchCase::CaseSensitive), Envelope, ReadError));
    TestFalse(TEXT("Case-changed submission discriminator rejected"), ReadCommandEnvelope(BaseEnvelope.Replace(
        TEXT("start_session"), TEXT("START_SESSION"), ESearchCase::CaseSensitive), Envelope, ReadError));
    TestTrue(TEXT("Mixed-case opaque identity accepted unchanged"), ReadCommandEnvelope(BaseEnvelope.Replace(
        TEXT("00001:opaque"), TEXT("00001:Opaque"), ESearchCase::CaseSensitive), Envelope, ReadError));
    TestTrue(TEXT("Opaque identity retains exact case"), Exact(Envelope.CommandId, TEXT("00001:Opaque")));
    TestFalse(TEXT("Opaque identities that differ in case remain distinct"), Exact(Envelope.CommandId, TEXT("00001:opaque")));
    const TCHAR* InvalidRevisions[] = {TEXT("9007199254740992"), TEXT("9007199254740993"), TEXT("9223372036854775808"),
        TEXT("1.0"), TEXT("1e0"), TEXT("-1"), TEXT("true"), TEXT("null"), TEXT("\"1\"")};
    for (const TCHAR* Revision : InvalidRevisions)
    {
        const FString Mutated = BaseEnvelope.Replace(TEXT("\"expected_session_revision\":0"),
            *(FString(TEXT("\"expected_session_revision\":")) + Revision));
        TestFalse(TEXT("Revision is rejected without numeric rounding/coercion"), ReadCommandEnvelope(Mutated, Envelope, ReadError));
        TestFalse(TEXT("Rejected envelope returns no stale JSON"), Envelope.Json.IsValid());
        TestFalse(TEXT("Revision failure has typed diagnostic"), ReadError.Code.IsEmpty());
    }
    TestTrue(TEXT("Maximum exact supported revision"), ReadCommandEnvelope(BaseEnvelope.Replace(
        TEXT("\"expected_session_revision\":0"), TEXT("\"expected_session_revision\":9007199254740991")), Envelope, ReadError));
    TestEqual(TEXT("Maximum revision exact"), Envelope.ExpectedSessionRevision, MaximumExactRevision);
    for (const TCHAR* Key : {TEXT("schema_version"), TEXT("command_id"), TEXT("session_id"), TEXT("expected_session_revision"),
        TEXT("request_id"), TEXT("result_id"), TEXT("submission")})
    {
        TSharedPtr<FJsonObject> Mutated;
        ParseObject(BaseEnvelope, Mutated, ReadError);
        Mutated->RemoveField(Key);
        FString Text;
        Serialize(Mutated, Text);
        TestFalse(TEXT("Missing required envelope field rejected"), ReadCommandEnvelope(Text, Envelope, ReadError));
        ParseObject(BaseEnvelope, Mutated, ReadError);
        Mutated->SetArrayField(Key, {});
        Serialize(Mutated, Text);
        TestFalse(TEXT("Wrong-type required envelope field rejected"), ReadCommandEnvelope(Text, Envelope, ReadError));
    }
    TestFalse(TEXT("Numeric command identity rejected"), ReadCommandEnvelope(BaseEnvelope.Replace(TEXT("\"00001:opaque\""), TEXT("9007199254740993")), Envelope, ReadError));
    TestFalse(TEXT("Lifecycle ID cannot be silently ignored"), ReadCommandEnvelope(BaseEnvelope.Replace(TEXT("\"request_id\":null"), TEXT("\"request_id\":\"unexpected\"")), Envelope, ReadError));

    FString OutcomeText, Error;
    TSharedPtr<FJsonObject> OutcomeObject;
    if (!CanonicalOutcome(OutcomeText, OutcomeObject, Error))
    {
        AddError(Error);
        return false;
    }
    FOutcome Outcome;
    TestTrue(TEXT("Canonical accepted outcome"), ReadOutcome(200, OutcomeText, Outcome, ReadError));
    for (const TCHAR* Key : {TEXT("schema_version"), TEXT("outcome_code"), TEXT("operation")})
    {
        TSharedPtr<FJsonObject> Changed;
        ParseObject(OutcomeText, Changed, ReadError);
        Changed->SetStringField(Key, Field(Changed, Key)->AsString().ToUpper());
        FString ChangedText;
        Serialize(Changed, ChangedText);
        TestFalse(TEXT("Case-changed outcome discriminator rejected"), ReadOutcome(200, ChangedText, Outcome, ReadError));
    }
    TestFalse(TEXT("Case-changed outcome field name rejected"), ReadOutcome(200, OutcomeText.Replace(
        TEXT("\"accepted\""), TEXT("\"Accepted\""), ESearchCase::CaseSensitive), Outcome, ReadError));
    for (const TCHAR* Key : {TEXT("schema_version"), TEXT("command_id"), TEXT("outcome_code"), TEXT("operation"), TEXT("committed"),
        TEXT("accepted"), TEXT("session"), TEXT("checkpoint"), TEXT("event_range")})
    {
        TSharedPtr<FJsonObject> Mutated;
        ParseObject(OutcomeText, Mutated, ReadError);
        Mutated->RemoveField(Key);
        FString Text;
        Serialize(Mutated, Text);
        TestFalse(TEXT("Missing required outcome field rejected"), ReadOutcome(200, Text, Outcome, ReadError));
        TestFalse(TEXT("Rejected outcome has no stale JSON"), Outcome.Json.IsValid());
        ParseObject(OutcomeText, Mutated, ReadError);
        Mutated->SetField(Key, MakeShared<FJsonValueNull>());
        Serialize(Mutated, Text);
        TestFalse(TEXT("Null required outcome field rejected"), ReadOutcome(200, Text, Outcome, ReadError));
        ParseObject(OutcomeText, Mutated, ReadError);
        Mutated->SetArrayField(Key, {});
        Serialize(Mutated, Text);
        TestFalse(TEXT("Wrong-type required outcome field rejected"), ReadOutcome(200, Text, Outcome, ReadError));
    }
    TSharedPtr<FJsonObject> Mutated;
    ParseObject(OutcomeText, Mutated, ReadError);
    Mutated->SetBoolField(TEXT("committed"), false);
    FString Text;
    Serialize(Mutated, Text);
    TestFalse(TEXT("accepted:true committed:false is never acceptance"), ReadOutcome(200, Text, Outcome, ReadError));
    TestTrue(TEXT("Flag error is explicit"), Exact(ReadError.Code, TEXT("invalid_flags")));
    TestFalse(TEXT("Accepted body under HTTP 422 rejected"), ReadOutcome(422, OutcomeText, Outcome, ReadError));
    ParseObject(OutcomeText, Mutated, ReadError);
    Mutated->SetStringField(TEXT("accepted"), TEXT("true"));
    Serialize(Mutated, Text);
    TestFalse(TEXT("String acceptance flag rejected"), ReadOutcome(200, Text, Outcome, ReadError));
    ParseObject(OutcomeText, Mutated, ReadError);
    Mutated->GetObjectField(TEXT("session"))->SetField(TEXT("session_revision"), MakeShared<FJsonValueNumberString>(TEXT("9007199254740993")));
    Serialize(Mutated, Text);
    TestFalse(TEXT("Nested session revision cannot round"), ReadOutcome(200, Text, Outcome, ReadError));
    TestTrue(TEXT("Nested range failure explicit"), Exact(ReadError.Code, TEXT("revision_out_of_range")));
    ParseObject(OutcomeText, Mutated, ReadError);
    const TSharedPtr<FJsonObject> ChangedCheckpoint = Mutated->GetObjectField(TEXT("checkpoint"));
    const FString OriginalCursor = Field(ChangedCheckpoint, TEXT("event_cursor"))->AsString();
    FString ChangedCursor = OriginalCursor;
    ChangedCursor[0] = FChar::IsUpper(OriginalCursor[0]) ? FChar::ToLower(OriginalCursor[0]) : FChar::ToUpper(OriginalCursor[0]);
    TestFalse(TEXT("Cursor regression changes actual case"), Exact(OriginalCursor, ChangedCursor));
    ChangedCheckpoint->SetStringField(TEXT("event_cursor"), ChangedCursor);
    Serialize(Mutated, Text);
    TestFalse(TEXT("Case-changed opaque checkpoint cursor rejected"), ReadOutcome(200, Text, Outcome, ReadError));
    ParseObject(OutcomeText, Mutated, ReadError);
    const TSharedPtr<FJsonObject> HashCheckpoint = Mutated->GetObjectField(TEXT("checkpoint"));
    const FString OriginalHash = Field(HashCheckpoint, TEXT("projection_state_hash"))->AsString();
    const FString ChangedHash = OriginalHash.ToUpper();
    TestFalse(TEXT("Hash regression changes actual case"), Exact(OriginalHash, ChangedHash));
    HashCheckpoint->SetStringField(TEXT("projection_state_hash"), ChangedHash);
    Serialize(Mutated, Text);
    TestFalse(TEXT("Case-changed opaque checkpoint hash rejected"), ReadOutcome(200, Text, Outcome, ReadError));
    ParseObject(OutcomeText, Mutated, ReadError);
    Mutated->SetBoolField(TEXT("accepted"), false);
    Mutated->SetStringField(TEXT("outcome_code"), TEXT("proposal_invalid"));
    Serialize(Mutated, Text);
    TestTrue(TEXT("Recorded-invalid 422 branch"), ReadOutcome(422, Text, Outcome, ReadError));
    TestTrue(TEXT("Recorded-invalid retains committed flag"), Outcome.bCommitted);
    TestTrue(TEXT("Recorded-invalid classification"), Exact(OutcomeName(Outcome.Kind), TEXT("recorded_invalid")));
    Mutated->SetBoolField(TEXT("committed"), false);
    Serialize(Mutated, Text);
    TestTrue(TEXT("Uncommitted outcome branch preserved"), ReadOutcome(422, Text, Outcome, ReadError));
    TestTrue(TEXT("Uncommitted classification"), Exact(OutcomeName(Outcome.Kind), TEXT("uncommitted_invalid")));
    const FString ErrorBody = TEXT("{\"schema_version\":\"error-envelope-v1\",\"error\":{\"code\":\"proposal_invalid\",\"message\":\"Submitted proposal was invalid.\"}}");
    TestTrue(TEXT("Uncommitted error-envelope 422 shape"), ReadOutcome(422, ErrorBody, Outcome, ReadError));
    TestTrue(TEXT("Exact wire message"), Exact(Outcome.Message, TEXT("Submitted proposal was invalid.")));
    TestTrue(TEXT("Fidelity gap is explicit"), Outcome.FidelityGap.Contains(TEXT("not supplied")));
    // Synthetic branch control, not a live capture. The selected Core's
    // adapters/server.py maps its uncommitted unsupported outcome to this body.
    const FString UnsupportedErrorBody = TEXT("{\"schema_version\":\"error-envelope-v1\",\"error\":{\"code\":\"rule_path_unsupported\",\"message\":\"Submitted command reached an unsupported rule path.\"}}");
    TestTrue(TEXT("Seed a command receipt before unsupported error"), ReadOutcome(200, OutcomeText, Outcome, ReadError));
    TestTrue(TEXT("Synthetic unsupported error-envelope 422 shape"), ReadOutcome(422, UnsupportedErrorBody, Outcome, ReadError));
    TestEqual(TEXT("Unsupported HTTP status retained"), Outcome.HttpStatus, 422);
    TestTrue(TEXT("Exact unsupported wire code"), Exact(Outcome.Code, TEXT("rule_path_unsupported")));
    TestTrue(TEXT("Exact unsupported wire message"), Exact(Outcome.Message, TEXT("Submitted command reached an unsupported rule path.")));
    TestTrue(TEXT("Unsupported error is uncommitted-invalid"), Exact(OutcomeName(Outcome.Kind), TEXT("uncommitted_invalid")));
    TestFalse(TEXT("Unsupported error does not invent a command receipt"), Outcome.bCommandOutcome);
    TestFalse(TEXT("Unsupported error discards prior acceptance"), Outcome.bAccepted);
    TestFalse(TEXT("Unsupported error discards prior commitment"), Outcome.bCommitted);
    TestTrue(TEXT("Unsupported error has no invented command ID"), Outcome.CommandId.IsEmpty());
    TestFalse(TEXT("Unsupported error has no invented session revision"), Outcome.SessionRevision.IsSet());
    for (const TCHAR* Key : {TEXT("command_id"), TEXT("accepted"), TEXT("committed"), TEXT("session"), TEXT("checkpoint"), TEXT("event_range")})
    {
        TestFalse(TEXT("Unsupported error retains absent receipt fields"), Field(Outcome.Json, Key).IsValid());
    }
    TestTrue(TEXT("Unsupported missing-detail notice is explicit"), Exact(Outcome.FidelityGap,
        TEXT("Detailed engine reasons were not supplied by this HTTP response. Core issue #588.")));
    TestFalse(TEXT("Unsupported error cannot pass as HTTP success"), ReadOutcome(200, UnsupportedErrorBody, Outcome, ReadError));
    TestFalse(TEXT("Error body cannot pass as HTTP success"), ReadOutcome(200, ErrorBody, Outcome, ReadError));
    TestFalse(TEXT("Error missing message rejected"), ReadOutcome(422, TEXT("{\"schema_version\":\"error-envelope-v1\",\"error\":{\"code\":\"proposal_invalid\"}}"), Outcome, ReadError));
    TestFalse(TEXT("Error wrong message type rejected"), ReadOutcome(422, ErrorBody.Replace(TEXT("\"Submitted proposal was invalid.\""), TEXT("false")), Outcome, ReadError));
    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FE01JsonPreservation,
    "Warhammer.Migration.E01Boundary.JsonPreservation", TestFlags)

bool FE01JsonPreservation::RunTest(const FString& Parameters)
{
    const FString Text = TEXT("{\"ids\":[\"0001\",\"a:b/..\",\"\\u0394\"],\"null\":null,\"bool\":true,\"string\":\"1\",\"number\":1.2500,\"ordered\":[{\"id\":\"second\"},{\"id\":\"first\"}],\"opaque_payload_integer\":9007199254740993}");
    TSharedPtr<FJsonObject> Object;
    FReadError Error;
    if (!ParseObject(Text, Object, Error))
    {
        AddError(Error.Code);
        return false;
    }
    TestTrue(TEXT("All JSON types and array order survive serialization"), RoundTrip(Object));
    TestTrue(TEXT("Opaque leading zero ID"), Exact(Field(Object, TEXT("ids"))->AsArray()[0]->AsString(), TEXT("0001")));
    TestTrue(TEXT("Ordered second stays first"), Exact(Field(Object, TEXT("ordered"))->AsArray()[0]->AsObject()->GetStringField(TEXT("id")), TEXT("second")));
    FString Token;
    Field(Object, TEXT("opaque_payload_integer"))->TryGetString(Token);
    TestTrue(TEXT("Opaque numeric payload token retains precision"), Exact(Token, TEXT("9007199254740993")));
    TestTrue(TEXT("Explicit null remains JSON null"), IsType(Field(Object, TEXT("null")), EJson::Null));
    TestTrue(TEXT("Numeric-looking string remains JSON string"), IsType(Field(Object, TEXT("string")), EJson::String));
    TestFalse(TEXT("JSON comparison distinguishes opaque ID case"), SameJson(
        MakeShared<FJsonValueString>(TEXT("Entity:Alpha")), MakeShared<FJsonValueString>(TEXT("entity:alpha"))));
    TSharedPtr<FJsonObject> UpperKey, LowerKey;
    TestTrue(TEXT("A single mixed-case key is supported"), ParseObject(TEXT("{\"EntityId\":\"Case:Alpha\"}"), UpperKey, Error));
    TestTrue(TEXT("Single key retains its original spelling"), Field(UpperKey, TEXT("EntityId")).IsValid());
    TestFalse(TEXT("Exact field lookup rejects changed key case"), Field(UpperKey, TEXT("entityid")).IsValid());
    TestTrue(TEXT("Single mixed-case key round trip"), RoundTrip(UpperKey));
    TestTrue(TEXT("A differently cased single key parses independently"), ParseObject(TEXT("{\"entityid\":\"Case:Alpha\"}"), LowerKey, Error));
    TestFalse(TEXT("JSON comparison distinguishes object-key case"), SameJson(
        MakeShared<FJsonValueObject>(UpperKey), MakeShared<FJsonValueObject>(LowerKey)));
    TSharedPtr<FJsonObject> Unsupported;
    TestFalse(TEXT("Valid JSON case-colliding keys cannot silently collapse"), ParseObject(TEXT("{\"a\":1,\"A\":2}"), Unsupported, Error));
    TestTrue(TEXT("DOM limitation has its own typed diagnostic"), Exact(Error.Code, TEXT("unsupported_key_case_collision")));
    TestFalse(TEXT("Unsupported case collision returns no lossy DOM"), Unsupported.IsValid());
    TestFalse(TEXT("Exact repeated key remains a true duplicate"), ParseObject(TEXT("{\"a\":1,\"a\":2}"), Unsupported, Error));
    TestTrue(TEXT("Exact duplicate is distinct from DOM limitation"), Exact(Error.Code, TEXT("duplicate_member")));
    return true;
}

#endif // WITH_DEV_AUTOMATION_TESTS
