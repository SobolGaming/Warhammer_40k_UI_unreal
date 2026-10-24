#pragma once

#include "CoreMinimal.h"

class FJsonObject;

namespace LiveCoreRuntimeData
{
// UFS path within Content, available in both a checkout and a staged package.
FString CanonicalSessionCreatePath();

// Reads only the exact pinned development payload. Path is explicit for focused
// missing/corrupt-data tests; production always supplies CanonicalSessionCreatePath.
bool ReadCanonicalSessionCreate(const FString& Path, TSharedPtr<FJsonObject>& OutPayload, FString& OutError);
}
