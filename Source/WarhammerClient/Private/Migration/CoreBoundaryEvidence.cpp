#include "Migration/CoreBoundaryEvidence.h"

#include "Serialization/JsonReader.h"
#include "Serialization/JsonSerializer.h"

#include <initializer_list>

namespace Warhammer::Migration::E01
{
namespace
{
bool Fail(FReadError& Error, const TCHAR* Code, const TCHAR* Message)
{
    Error.Code = Code;
    Error.Message = Message;
    return false;
}

bool IsDigit(TCHAR Character)
{
    return Character >= TEXT('0') && Character <= TEXT('9');
}

// UE's reader also accepts non-JSON numeric extensions and some trailing commas.
// Check the actual JSON grammar first, without converting any numbers to double.
class FStrictSyntax
{
public:
    explicit FStrictSyntax(const FString& InText) : Text(InText) {}

    bool Read()
    {
        SkipWhitespace();
        if (!Value(0))
        {
            return false;
        }
        SkipWhitespace();
        return Position == Text.Len();
    }

private:
    const FString& Text;
    int32 Position = 0;

    void SkipWhitespace()
    {
        while (Position < Text.Len() && (Text[Position] == TEXT(' ') || Text[Position] == TEXT('\t') ||
            Text[Position] == TEXT('\r') || Text[Position] == TEXT('\n')))
        {
            ++Position;
        }
    }

    bool Take(TCHAR Character)
    {
        if (Position < Text.Len() && Text[Position] == Character)
        {
            ++Position;
            return true;
        }
        return false;
    }

    bool Literal(const TCHAR* LiteralText)
    {
        const int32 Length = FCString::Strlen(LiteralText);
        if (!Text.Mid(Position, Length).Equals(LiteralText, ESearchCase::CaseSensitive))
        {
            return false;
        }
        Position += Length;
        return true;
    }

    bool String()
    {
        if (!Take(TEXT('"')))
        {
            return false;
        }
        while (Position < Text.Len())
        {
            const TCHAR Character = Text[Position++];
            if (Character == TEXT('"'))
            {
                return true;
            }
            if (Character < 0x20)
            {
                return false;
            }
            if (Character == TEXT('\\'))
            {
                if (Position == Text.Len())
                {
                    return false;
                }
                const TCHAR Escape = Text[Position++];
                if (Escape == TEXT('u'))
                {
                    for (int32 Index = 0; Index < 4; ++Index)
                    {
                        if (Position == Text.Len() || !FChar::IsHexDigit(Text[Position++]))
                        {
                            return false;
                        }
                    }
                }
                else if (Escape != TEXT('"') && Escape != TEXT('\\') && Escape != TEXT('/') &&
                    Escape != TEXT('b') && Escape != TEXT('f') && Escape != TEXT('n') &&
                    Escape != TEXT('r') && Escape != TEXT('t'))
                {
                    return false;
                }
            }
        }
        return false;
    }

    bool Number()
    {
        Take(TEXT('-'));
        if (!Take(TEXT('0')))
        {
            if (Position == Text.Len() || Text[Position] < TEXT('1') || Text[Position] > TEXT('9'))
            {
                return false;
            }
            while (Position < Text.Len() && IsDigit(Text[Position]))
            {
                ++Position;
            }
        }
        if (Take(TEXT('.')))
        {
            const int32 Start = Position;
            while (Position < Text.Len() && IsDigit(Text[Position]))
            {
                ++Position;
            }
            if (Start == Position)
            {
                return false;
            }
        }
        if (Take(TEXT('e')) || Take(TEXT('E')))
        {
            if (!Take(TEXT('+')))
            {
                Take(TEXT('-'));
            }
            const int32 Start = Position;
            while (Position < Text.Len() && IsDigit(Text[Position]))
            {
                ++Position;
            }
            if (Start == Position)
            {
                return false;
            }
        }
        return true;
    }

    bool Value(int32 Depth)
    {
        if (Depth > 128 || Position == Text.Len())
        {
            return false;
        }
        if (Take(TEXT('{')))
        {
            SkipWhitespace();
            if (Take(TEXT('}')))
            {
                return true;
            }
            do
            {
                SkipWhitespace();
                if (!String())
                {
                    return false;
                }
                SkipWhitespace();
                if (!Take(TEXT(':')))
                {
                    return false;
                }
                SkipWhitespace();
                if (!Value(Depth + 1))
                {
                    return false;
                }
                SkipWhitespace();
                if (Take(TEXT('}')))
                {
                    return true;
                }
            } while (Take(TEXT(',')));
            return false;
        }
        if (Take(TEXT('[')))
        {
            SkipWhitespace();
            if (Take(TEXT(']')))
            {
                return true;
            }
            do
            {
                SkipWhitespace();
                if (!Value(Depth + 1))
                {
                    return false;
                }
                SkipWhitespace();
                if (Take(TEXT(']')))
                {
                    return true;
                }
            } while (Take(TEXT(',')));
            return false;
        }
        if (Text[Position] == TEXT('"'))
        {
            return String();
        }
        if (Text[Position] == TEXT('t'))
        {
            return Literal(TEXT("true"));
        }
        if (Text[Position] == TEXT('f'))
        {
            return Literal(TEXT("false"));
        }
        if (Text[Position] == TEXT('n'))
        {
            return Literal(TEXT("null"));
        }
        return Number();
    }
};

TSharedPtr<FJsonValue> Field(const TSharedPtr<FJsonObject>& Object, FStringView Key)
{
    if (Object.IsValid())
    {
        for (const auto& Pair : Object->Values)
        {
            if (FStringView(*Pair.Key, Pair.Key.Len()).Equals(Key, ESearchCase::CaseSensitive))
            {
                return Pair.Value;
            }
        }
    }
    return nullptr;
}

bool ExactKeys(const TSharedPtr<FJsonObject>& Object, std::initializer_list<const TCHAR*> Keys)
{
    if (!Object.IsValid() || Object->Values.Num() != static_cast<int32>(Keys.size()))
    {
        return false;
    }
    for (const TCHAR* Key : Keys)
    {
        if (!Field(Object, Key).IsValid())
        {
            return false;
        }
    }
    return true;
}

bool Type(const TSharedPtr<FJsonValue>& Value, EJson Expected)
{
    return Value.IsValid() && Value->Type == Expected;
}

bool StringField(const TSharedPtr<FJsonObject>& Object, const TCHAR* Key, FString& Out)
{
    const TSharedPtr<FJsonValue> Value = Field(Object, Key);
    return Type(Value, EJson::String) && Value->TryGetString(Out) && !Out.IsEmpty();
}

bool NullableString(const TSharedPtr<FJsonValue>& Value, TOptional<FString>& Out)
{
    Out.Reset();
    if (Type(Value, EJson::Null))
    {
        return true;
    }
    FString Text;
    if (!Type(Value, EJson::String) || !Value->TryGetString(Text) || Text.IsEmpty())
    {
        return false;
    }
    Out = MoveTemp(Text);
    return true;
}

bool BoolField(const TSharedPtr<FJsonObject>& Object, const TCHAR* Key, bool& Out)
{
    const TSharedPtr<FJsonValue> Value = Field(Object, Key);
    return Type(Value, EJson::Boolean) && Value->TryGetBool(Out);
}

TSharedPtr<FJsonObject> ObjectField(const TSharedPtr<FJsonObject>& Object, const TCHAR* Key)
{
    const TSharedPtr<FJsonValue> Value = Field(Object, Key);
    return Type(Value, EJson::Object) ? Value->AsObject() : nullptr;
}

bool Schema(const TSharedPtr<FJsonObject>& Object, const TCHAR* Expected)
{
    FString Actual;
    return StringField(Object, TEXT("schema_version"), Actual) && Actual.Equals(Expected, ESearchCase::CaseSensitive);
}

bool IsOneOf(const FString& Value, std::initializer_list<const TCHAR*> Choices)
{
    for (const TCHAR* Choice : Choices)
    {
        if (Value.Equals(Choice, ESearchCase::CaseSensitive))
        {
            return true;
        }
    }
    return false;
}

bool StringArray(const TSharedPtr<FJsonValue>& Value)
{
    if (!Type(Value, EJson::Array))
    {
        return false;
    }
    for (const TSharedPtr<FJsonValue>& Member : Value->AsArray())
    {
        if (!Type(Member, EJson::String) || Member->AsString().IsEmpty())
        {
            return false;
        }
    }
    return true;
}

bool Session(const TSharedPtr<FJsonObject>& Object, int64& Revision, FReadError& Error)
{
    if (!ExactKeys(Object, {TEXT("schema_version"), TEXT("session_id"), TEXT("game_id"),
        TEXT("session_state"), TEXT("session_revision"), TEXT("ruleset_id"), TEXT("ruleset_descriptor_hash"),
        TEXT("rules_overlay_ids"), TEXT("catalog_id"), TEXT("source_package_id"), TEXT("source_hash"),
        TEXT("projection_state_hash"), TEXT("event_cursor"), TEXT("lifecycle_status"), TEXT("terminal_reason"),
        TEXT("created_at"), TEXT("last_activity_at"), TEXT("visibility"), TEXT("server_contract_version"),
        TEXT("engine_version"), TEXT("engine_build_id")}) ||
        !Schema(Object, TEXT("session-metadata-v44-contract")))
    {
        return false;
    }
    FString Text;
    for (const TCHAR* Key : {TEXT("session_id"), TEXT("game_id"), TEXT("ruleset_descriptor_hash"),
        TEXT("catalog_id"), TEXT("source_package_id"), TEXT("source_hash"), TEXT("projection_state_hash"),
        TEXT("event_cursor"), TEXT("created_at"), TEXT("last_activity_at"), TEXT("server_contract_version"),
        TEXT("engine_version"), TEXT("engine_build_id")})
    {
        if (!StringField(Object, Key, Text))
        {
            return false;
        }
    }
    if (!StringField(Object, TEXT("session_state"), Text) ||
        !IsOneOf(Text, {TEXT("created"), TEXT("active"), TEXT("terminal"), TEXT("closed")}) ||
        !ReadExactRevision(Field(Object, TEXT("session_revision")), Revision, Error) ||
        !ObjectField(Object, TEXT("ruleset_id")).IsValid() ||
        !StringArray(Field(Object, TEXT("rules_overlay_ids"))))
    {
        return false;
    }
    const TSharedPtr<FJsonObject> Status = ObjectField(Object, TEXT("lifecycle_status"));
    if (!ExactKeys(Status, {TEXT("status_kind"), TEXT("stage"), TEXT("pending_request_id"), TEXT("decision_type"),
        TEXT("actor_id"), TEXT("message"), TEXT("payload")}) || !StringField(Status, TEXT("status_kind"), Text))
    {
        return false;
    }
    TOptional<FString> Nullable;
    for (const TCHAR* Key : {TEXT("stage"), TEXT("pending_request_id"), TEXT("decision_type"), TEXT("actor_id"), TEXT("message")})
    {
        if (!NullableString(Field(Status, Key), Nullable))
        {
            return false;
        }
    }
    const TSharedPtr<FJsonValue> Terminal = Field(Object, TEXT("terminal_reason"));
    if (!Type(Terminal, EJson::Null))
    {
        if (!Type(Terminal, EJson::Object) ||
            !ExactKeys(Terminal->AsObject(), {TEXT("code"), TEXT("message")}) ||
            !StringField(Terminal->AsObject(), TEXT("code"), Text) ||
            !StringField(Terminal->AsObject(), TEXT("message"), Text))
        {
            return false;
        }
    }
    const TSharedPtr<FJsonObject> Visibility = ObjectField(Object, TEXT("visibility"));
    bool Flag = false;
    int64 Delay = 0;
    return ExactKeys(Visibility, {TEXT("role"), TEXT("player_id"), TEXT("delay_revisions"), TEXT("may_mutate_lifecycle"),
        TEXT("may_submit_decision"), TEXT("omniscient")}) && StringField(Visibility, TEXT("role"), Text) &&
        IsOneOf(Text, {TEXT("player"), TEXT("coach"), TEXT("delayed_spectator"), TEXT("administrator"), TEXT("replay_viewer")}) &&
        NullableString(Field(Visibility, TEXT("player_id")), Nullable) &&
        ReadExactRevision(Field(Visibility, TEXT("delay_revisions")), Delay, Error) &&
        BoolField(Visibility, TEXT("may_mutate_lifecycle"), Flag) &&
        BoolField(Visibility, TEXT("may_submit_decision"), Flag) && BoolField(Visibility, TEXT("omniscient"), Flag);
}
}

bool ParseObject(const FString& Text, TSharedPtr<FJsonObject>& OutObject, FReadError& OutError)
{
    OutObject.Reset();
    OutError = {};
    if (Text.Len() > 64 * 1024 * 1024 || !FStrictSyntax(Text).Read())
    {
        return Fail(OutError, TEXT("malformed_json"), TEXT("Expected bounded strict JSON with a maximum nesting depth of 128."));
    }
    struct FScope
    {
        bool bObject = false;
        TArray<FString> Keys;
    };
    TArray<FScope> Scopes;
    const TSharedRef<TJsonReader<>> KeyReader = TJsonReaderFactory<>::Create(Text);
    EJsonNotation Notation;
    while (KeyReader->ReadNext(Notation))
    {
        if (Notation == EJsonNotation::Error)
        {
            return Fail(OutError, TEXT("malformed_json"), TEXT("JSON decoding failed."));
        }
        const bool bEnd = Notation == EJsonNotation::ObjectEnd || Notation == EJsonNotation::ArrayEnd;
        if (!bEnd && !Scopes.IsEmpty() && Scopes.Last().bObject)
        {
            const FString& Key = KeyReader->GetIdentifier();
            if (Scopes.Last().Keys.ContainsByPredicate([&Key](const FString& Existing)
                { return Existing.Equals(Key, ESearchCase::CaseSensitive); }))
            {
                return Fail(OutError, TEXT("duplicate_member"), TEXT("Duplicate decoded JSON member name."));
            }
            // UE5.8's string interner is case-sensitive, but FJsonObject::Values
            // uses the default FSharedString map equality/hash (IgnoreCase).
            if (Scopes.Last().Keys.ContainsByPredicate([&Key](const FString& Existing)
                { return Existing.Equals(Key, ESearchCase::IgnoreCase); }))
            {
                return Fail(OutError, TEXT("unsupported_key_case_collision"),
                    TEXT("Selected Unreal JSON object storage cannot preserve distinct keys that differ only by case."));
            }
            Scopes.Last().Keys.Add(Key);
        }
        if (Notation == EJsonNotation::ObjectStart || Notation == EJsonNotation::ArrayStart)
        {
            FScope Scope;
            Scope.bObject = Notation == EJsonNotation::ObjectStart;
            Scopes.Add(MoveTemp(Scope));
        }
        else if (bEnd)
        {
            Scopes.Pop();
        }
    }
    const TSharedRef<TJsonReader<>> Reader = TJsonReaderFactory<>::Create(Text);
    if (!FJsonSerializer::Deserialize(Reader, OutObject, FJsonSerializer::EFlags::StoreNumbersAsStrings) ||
        !OutObject.IsValid())
    {
        OutObject.Reset();
        return Fail(OutError, TEXT("object_required"), TEXT("A JSON object is required."));
    }
    return true;
}

bool ReadExactRevision(const TSharedPtr<FJsonValue>& Value, int64& OutRevision, FReadError& OutError)
{
    FString Token;
    // Parsed numeric values retain the original token. No float conversion is used.
    if (!Type(Value, EJson::Number) || !Value->PreferStringRepresentation() || !Value->TryGetString(Token) || Token.IsEmpty())
    {
        return Fail(OutError, TEXT("invalid_revision"), TEXT("Revision requires an exact nonnegative integer JSON token."));
    }
    int64 Result = 0;
    for (const TCHAR Character : Token)
    {
        if (!IsDigit(Character))
        {
            return Fail(OutError, TEXT("invalid_revision"), TEXT("Revision requires integer syntax; fractions and exponents are unsupported."));
        }
        const int64 Digit = Character - TEXT('0');
        if (Result > (MaximumExactRevision - Digit) / 10)
        {
            return Fail(OutError, TEXT("revision_out_of_range"), TEXT("Revision exceeds the reader's exact range 0..9007199254740991."));
        }
        Result = Result * 10 + Digit;
    }
    OutRevision = Result;
    return true;
}

bool ReadCommandEnvelope(const FString& Text, FCommandEnvelope& OutEnvelope, FReadError& OutError)
{
    OutEnvelope = {};
    FCommandEnvelope Candidate;
    if (!ParseObject(Text, Candidate.Json, OutError))
    {
        return false;
    }
    const TSharedPtr<FJsonObject>& Object = Candidate.Json;
    if (!ExactKeys(Object, {TEXT("schema_version"), TEXT("command_id"), TEXT("session_id"),
        TEXT("expected_session_revision"), TEXT("request_id"), TEXT("result_id"), TEXT("submission")}) ||
        !Schema(Object, TEXT("session-command-envelope-v2-weapon-instances")) ||
        !StringField(Object, TEXT("command_id"), Candidate.CommandId) ||
        !StringField(Object, TEXT("session_id"), Candidate.SessionId) ||
        !NullableString(Field(Object, TEXT("request_id")), Candidate.RequestId) ||
        !NullableString(Field(Object, TEXT("result_id")), Candidate.ResultId))
    {
        return Fail(OutError, TEXT("invalid_envelope"), TEXT("Command envelope has missing, unsupported or incorrectly typed fields."));
    }
    if (!ReadExactRevision(Field(Object, TEXT("expected_session_revision")), Candidate.ExpectedSessionRevision, OutError))
    {
        return false;
    }
    const TSharedPtr<FJsonObject> Submission = ObjectField(Object, TEXT("submission"));
    if (!StringField(Submission, TEXT("submission_kind"), Candidate.SubmissionKind))
    {
        return Fail(OutError, TEXT("invalid_submission"), TEXT("Command submission requires a string submission_kind."));
    }
    if (IsOneOf(Candidate.SubmissionKind, {TEXT("start_session"), TEXT("advance_session"), TEXT("close_session")}))
    {
        if (!ExactKeys(Submission, {TEXT("submission_kind")}) || Candidate.RequestId.IsSet() || Candidate.ResultId.IsSet())
        {
            return Fail(OutError, TEXT("invalid_submission"), TEXT("Lifecycle commands require explicit null request/result IDs and no additional submission fields."));
        }
    }
    else if (Candidate.RequestId.IsSet() && Candidate.ResultId.IsSet())
    {
        FString OptionId;
        if (Candidate.SubmissionKind.Equals(TEXT("finite_option"), ESearchCase::CaseSensitive))
        {
            if (!ExactKeys(Submission, {TEXT("submission_kind"), TEXT("option_id")}) ||
                !StringField(Submission, TEXT("option_id"), OptionId))
            {
                return Fail(OutError, TEXT("invalid_submission"), TEXT("Finite submission requires its opaque string option ID."));
            }
        }
        else if (!Candidate.SubmissionKind.Equals(TEXT("parameterized_payload"), ESearchCase::CaseSensitive) ||
            !ExactKeys(Submission, {TEXT("submission_kind"), TEXT("payload")}) ||
            !Type(Field(Submission, TEXT("payload")), EJson::Object))
        {
            return Fail(OutError, TEXT("invalid_submission"), TEXT("Unsupported submission kind or non-object parameterized payload."));
        }
    }
    else
    {
        return Fail(OutError, TEXT("invalid_submission"), TEXT("Decision commands require nonempty string request/result IDs."));
    }
    OutEnvelope = MoveTemp(Candidate);
    return true;
}

bool ReadOutcome(int32 HttpStatus, const FString& Text, FOutcome& OutOutcome, FReadError& OutError)
{
    OutOutcome = {};
    FOutcome Candidate;
    Candidate.HttpStatus = HttpStatus;
    if (!ParseObject(Text, Candidate.Json, OutError))
    {
        return false;
    }
    const TSharedPtr<FJsonObject>& Object = Candidate.Json;
    if (Schema(Object, TEXT("error-envelope-v1")))
    {
        const TSharedPtr<FJsonObject> Error = ObjectField(Object, TEXT("error"));
        if (HttpStatus < 400 || HttpStatus > 599 || !ExactKeys(Object, {TEXT("schema_version"), TEXT("error")}) ||
            !ExactKeys(Error, {TEXT("code"), TEXT("message")}) ||
            !StringField(Error, TEXT("code"), Candidate.Code) || !StringField(Error, TEXT("message"), Candidate.Message))
        {
            return Fail(OutError, TEXT("invalid_error"), TEXT("Error envelope requires its actual error HTTP status and string code/message."));
        }
        if (HttpStatus == 422 && IsOneOf(Candidate.Code, {TEXT("proposal_invalid"), TEXT("rule_path_unsupported")}))
        {
            Candidate.Kind = EOutcomeKind::UncommittedInvalid;
            Candidate.FidelityGap = TEXT("Detailed engine reasons were not supplied by this HTTP response. Core issue #588.");
        }
        OutOutcome = MoveTemp(Candidate);
        return true;
    }
    FString Operation;
    if (!Schema(Object, TEXT("session-command-outcome-v44-contract")) ||
        !ExactKeys(Object, {TEXT("schema_version"), TEXT("command_id"), TEXT("outcome_code"), TEXT("operation"),
            TEXT("committed"), TEXT("accepted"), TEXT("session"), TEXT("checkpoint"), TEXT("event_range")}) ||
        !StringField(Object, TEXT("command_id"), Candidate.CommandId) ||
        !StringField(Object, TEXT("outcome_code"), Candidate.Code) || !StringField(Object, TEXT("operation"), Operation) ||
        !IsOneOf(Operation, {TEXT("start_session"), TEXT("advance_session"), TEXT("submit_finite_decision"),
            TEXT("submit_parameterized_decision"), TEXT("close_session")}) ||
        !BoolField(Object, TEXT("accepted"), Candidate.bAccepted) || !BoolField(Object, TEXT("committed"), Candidate.bCommitted))
    {
        return Fail(OutError, TEXT("invalid_outcome"), TEXT("Outcome has missing, unsupported or incorrectly typed fields."));
    }
    if (Candidate.bAccepted)
    {
        if (!Candidate.bCommitted || !Candidate.Code.Equals(TEXT("command_committed"), ESearchCase::CaseSensitive) || HttpStatus != 200)
        {
            return Fail(OutError, TEXT("invalid_flags"), TEXT("Accepted outcome requires committed:true, command_committed and HTTP 200."));
        }
        Candidate.Kind = EOutcomeKind::Accepted;
    }
    else
    {
        if (!IsOneOf(Candidate.Code, {TEXT("proposal_invalid"), TEXT("rule_path_unsupported")}) || HttpStatus != 422)
        {
            return Fail(OutError, TEXT("invalid_flags"), TEXT("Rejected command outcome requires its rejection code and HTTP 422."));
        }
        Candidate.Kind = Candidate.bCommitted ? EOutcomeKind::RecordedInvalid : EOutcomeKind::UncommittedInvalid;
    }
    const TSharedPtr<FJsonObject> Metadata = ObjectField(Object, TEXT("session"));
    const TSharedPtr<FJsonObject> Checkpoint = ObjectField(Object, TEXT("checkpoint"));
    const TSharedPtr<FJsonObject> EventRange = ObjectField(Object, TEXT("event_range"));
    int64 Revision = 0;
    int64 CheckpointRevision = 0;
    TOptional<FString> Viewer;
    FString Role;
    FString Hash;
    FString Cursor;
    FString RangeCursor;
    if (!Session(Metadata, Revision, OutError) ||
        !ExactKeys(Checkpoint, {TEXT("visibility_role"), TEXT("viewer_player_id"), TEXT("session_revision"),
            TEXT("projection_state_hash"), TEXT("event_cursor")}) ||
        !ReadExactRevision(Field(Checkpoint, TEXT("session_revision")), CheckpointRevision, OutError) ||
        Revision != CheckpointRevision || !NullableString(Field(Checkpoint, TEXT("viewer_player_id")), Viewer) ||
        !StringField(Checkpoint, TEXT("visibility_role"), Role) ||
        !IsOneOf(Role, {TEXT("player"), TEXT("coach"), TEXT("delayed_spectator"), TEXT("administrator")}) ||
        !StringField(Checkpoint, TEXT("projection_state_hash"), Hash) ||
        !Hash.Equals(Metadata->GetStringField(TEXT("projection_state_hash")), ESearchCase::CaseSensitive) ||
        !StringField(Checkpoint, TEXT("event_cursor"), Cursor) ||
        !Cursor.Equals(Metadata->GetStringField(TEXT("event_cursor")), ESearchCase::CaseSensitive) ||
        !ExactKeys(EventRange, {TEXT("from_cursor"), TEXT("to_cursor")}) ||
        !StringField(EventRange, TEXT("from_cursor"), RangeCursor) || !StringField(EventRange, TEXT("to_cursor"), RangeCursor))
    {
        if (OutError.Code.IsEmpty())
        {
            return Fail(OutError, TEXT("invalid_outcome_context"), TEXT("Outcome requires typed session metadata, checkpoint and event range with matching revision/hash/cursor."));
        }
        return false;
    }
    const TSharedPtr<FJsonObject> Visibility = ObjectField(Metadata, TEXT("visibility"));
    TOptional<FString> SessionViewer;
    FString SessionRole;
    if (!StringField(Visibility, TEXT("role"), SessionRole) ||
        !NullableString(Field(Visibility, TEXT("player_id")), SessionViewer) ||
        !Role.Equals(SessionRole, ESearchCase::CaseSensitive) || Viewer.IsSet() != SessionViewer.IsSet() ||
        (Viewer.IsSet() && !Viewer.GetValue().Equals(SessionViewer.GetValue(), ESearchCase::CaseSensitive)) ||
        !RangeCursor.Equals(Cursor, ESearchCase::CaseSensitive))
    {
        return Fail(OutError, TEXT("invalid_outcome_context"),
            TEXT("Outcome checkpoint viewer scope and event-range endpoint must match its session metadata."));
    }
    Candidate.bCommandOutcome = true;
    Candidate.SessionRevision = Revision;
    OutOutcome = MoveTemp(Candidate);
    return true;
}

const TCHAR* OutcomeName(EOutcomeKind Kind)
{
    switch (Kind)
    {
    case EOutcomeKind::Accepted: return TEXT("accepted");
    case EOutcomeKind::RecordedInvalid: return TEXT("recorded_invalid");
    case EOutcomeKind::UncommittedInvalid: return TEXT("uncommitted_invalid");
    default: return TEXT("error");
    }
}
}
