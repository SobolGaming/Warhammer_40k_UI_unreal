#pragma once

#include "CoreMinimal.h"
#include "Dom/JsonObject.h"

// Bounded E01 evidence reader, not a gameplay client or a JSON Schema validator.
namespace Warhammer::Migration::E01
{
constexpr int64 MaximumExactRevision = 9007199254740991LL;

struct FReadError
{
    FString Code;
    FString Message;
};

struct FCommandEnvelope
{
    FString CommandId;
    FString SessionId;
    int64 ExpectedSessionRevision = 0;
    TOptional<FString> RequestId;
    TOptional<FString> ResultId;
    FString SubmissionKind;
    // Retains payload types, explicit nulls, array order and numeric lexemes.
    TSharedPtr<FJsonObject> Json;
};

enum class EOutcomeKind : uint8
{
    Accepted,
    RecordedInvalid,
    UncommittedInvalid,
    Error
};

struct FOutcome
{
    EOutcomeKind Kind = EOutcomeKind::Error;
    int32 HttpStatus = 0;
    bool bCommandOutcome = false;
    bool bAccepted = false;
    bool bCommitted = false;
    FString CommandId;
    TOptional<int64> SessionRevision;
    FString Code;
    // Empty for an outcome that supplies no message; never inferred from local rules.
    FString Message;
    FString FidelityGap;
    TSharedPtr<FJsonObject> Json;
};

// Selected UE JSON maps cannot retain case-colliding object keys. Reject them
// explicitly before deserialization instead of silently dropping a member.
bool ParseObject(const FString& Text, TSharedPtr<FJsonObject>& OutObject, FReadError& OutError);
bool ReadExactRevision(const TSharedPtr<FJsonValue>& Value, int64& OutRevision, FReadError& OutError);
bool ReadCommandEnvelope(const FString& Text, FCommandEnvelope& OutEnvelope, FReadError& OutError);
bool ReadOutcome(int32 HttpStatus, const FString& Text, FOutcome& OutOutcome, FReadError& OutError);
const TCHAR* OutcomeName(EOutcomeKind Kind);
}
