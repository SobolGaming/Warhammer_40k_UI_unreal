#pragma once

#include "CoreMinimal.h"

struct FLiveCoreState;

namespace LiveCorePresentation
{
// Formats only the current typed public snapshot. No lookup, selection, HTTP or
// physical-instance join is performed; all displayed identities remain supplied IDs.
FString BuildPublicRosterSummary(const FLiveCoreState& State);
}
