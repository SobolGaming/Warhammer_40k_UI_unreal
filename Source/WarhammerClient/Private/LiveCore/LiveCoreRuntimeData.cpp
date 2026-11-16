#include "LiveCore/LiveCoreRuntimeData.h"

#include "Migration/CoreBoundaryEvidence.h"
#include "Dom/JsonObject.h"
#include "IPlatformCrypto.h"
#include "HAL/FileManager.h"
#include "Misc/FileHelper.h"
#include "Misc/Paths.h"
#include "Misc/SecureHash.h"

namespace LiveCoreRuntimeData
{
FString CanonicalSessionCreatePath()
{
    return FPaths::Combine(FPaths::ProjectContentDir(),
        TEXT("RuntimeData/Core/fc52e9166ff6380b606269ce362f4f1cbc6a2835/session-create.json"));
}

bool ReadCanonicalSessionCreate(const FString& Path, TSharedPtr<FJsonObject>& OutPayload, FString& OutError)
{
    OutPayload.Reset();
    constexpr int32 ExpectedBytes = 224844;
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
    // identities continue to be checked separately against selected Core46.0.0.
    if (Bytes.Num() != ExpectedBytes || !FSHA1::HashBuffer(Bytes.GetData(), Bytes.Num()).ToString().Equals(
        TEXT("FCE4782B539F7F5121D7B9CF74C30659C161A46E"), ESearchCase::IgnoreCase))
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
        !Schema.Equals(TEXT("session-create-v5-private-rng"), ESearchCase::CaseSensitive) ||
        !Candidate->TryGetObjectField(TEXT("config"), Config) || !Config || !Config->IsValid())
    { OutError = TEXT("Invalid canonical session-create payload."); return false; }
    // The shipped Core example is public and cannot provide a real private seed.
    // Create independent cryptographic randomness for each privileged create
    // payload. Never derive it from game_id, display it, or retain it in state.
    auto Crypto = IPlatformCrypto::Get().CreateContext();
    uint8 SeedBytes[32] = {};
    if (!Crypto.IsValid() || Crypto->CreateRandomBytes(MakeArrayView(SeedBytes)) != EPlatformCryptoResult::Success)
    {
        FMemory::Memzero(SeedBytes, sizeof(SeedBytes));
        OutError = TEXT("Secure randomness is unavailable; no session-create payload was produced.");
        return false;
    }
    (*Config)->SetStringField(TEXT("private_rng_seed"), BytesToHex(SeedBytes, UE_ARRAY_COUNT(SeedBytes)).ToLower());
    FMemory::Memzero(SeedBytes, sizeof(SeedBytes));
    OutPayload = MoveTemp(Candidate); OutError.Reset(); return true;
}
}
