#include "LiveCore/LiveCoreRuntimeData.h"

#include "Migration/CoreBoundaryEvidence.h"
#include "Dom/JsonObject.h"
#include "HAL/FileManager.h"
#include "Misc/FileHelper.h"
#include "Misc/Paths.h"
#include "Misc/SecureHash.h"

namespace LiveCoreRuntimeData
{
FString CanonicalSessionCreatePath()
{
    return FPaths::Combine(FPaths::ProjectContentDir(),
        TEXT("RuntimeData/Core/4f9bef0df2fb974d1285232a1009b8781926361d/session-create.json"));
}

bool ReadCanonicalSessionCreate(const FString& Path, TSharedPtr<FJsonObject>& OutPayload, FString& OutError)
{
    OutPayload.Reset();
    constexpr int32 ExpectedBytes = 223996;
    const int64 FileBytes = IFileManager::Get().FileSize(*Path);
    if (FileBytes < 0)
    { OutError = TEXT("Required runtime session-create data is missing or unreadable."); return false; }
    if (FileBytes != ExpectedBytes)
    { OutError = TEXT("Canonical session-create fixture checksum differs from the selected Core fixture."); return false; }
    TArray<uint8> Bytes;
    if (!FFileHelper::LoadFileToArray(Bytes, *Path))
    { OutError = TEXT("Required runtime session-create data is missing or unreadable."); return false; }
    // Keep the existing portable Core checksum. The installed Windows SHA256
    // hook asserts; independent SHA256 provenance is recorded beside the data.
    // This detects consistency errors, not authentication. Runtime/session
    // identities continue to be checked separately against selected Core44.5.0.
    if (Bytes.Num() != ExpectedBytes || !FSHA1::HashBuffer(Bytes.GetData(), Bytes.Num()).ToString().Equals(
        TEXT("BE2FF8A2BE9B9F5473DDFD238EEF327BB90BFFA6"), ESearchCase::IgnoreCase))
    { OutError = TEXT("Canonical session-create fixture checksum differs from the selected Core fixture."); return false; }
    const FUTF8ToTCHAR Decoded(reinterpret_cast<const ANSICHAR*>(Bytes.GetData()), Bytes.Num());
    const FString Text(Decoded.Length(), Decoded.Get());
    const FTCHARToUTF8 Reencoded(*Text, Text.Len());
    if (Reencoded.Length() != Bytes.Num() || FMemory::Memcmp(Reencoded.Get(), Bytes.GetData(), Bytes.Num()) != 0)
    { OutError = TEXT("Invalid UTF-8 canonical session-create payload."); return false; }
    TSharedPtr<FJsonObject> Candidate;
    Warhammer::Migration::E01::FReadError ReadError;
    if (!Warhammer::Migration::E01::ParseObject(Text, Candidate, ReadError))
    { OutError = TEXT("Invalid canonical session-create payload."); return false; }
    FString Schema;
    const TSharedPtr<FJsonObject>* Config = nullptr;
    if (!Candidate->TryGetStringField(TEXT("schema_version"), Schema) ||
        !Schema.Equals(TEXT("session-create-v4"), ESearchCase::CaseSensitive) ||
        !Candidate->TryGetObjectField(TEXT("config"), Config) || !Config || !Config->IsValid())
    { OutError = TEXT("Invalid canonical session-create payload."); return false; }
    OutPayload = MoveTemp(Candidate); OutError.Reset(); return true;
}
}
