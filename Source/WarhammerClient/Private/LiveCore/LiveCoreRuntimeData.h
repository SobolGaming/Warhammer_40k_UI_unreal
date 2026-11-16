#pragma once

#include "CoreMinimal.h"

class FJsonObject;

namespace LiveCoreRuntimeData
{
// UFS path within Content, available in both a checkout and a staged package.
FString CanonicalSessionCreatePath();

// Reads the exact public pinned example and replaces its example seed with fresh
// cryptographic private randomness in memory for every privileged create. Fails
// without a payload if data or secure randomness is unavailable. Never log this
// payload. Path is explicit for focused missing/corrupt-data tests; production
// always supplies CanonicalSessionCreatePath.
bool ReadCanonicalSessionCreate(const FString& Path, TSharedPtr<FJsonObject>& OutPayload, FString& OutError);
}
