#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "WarhammerClientGameMode.generated.h"

/** Client shell only. The external Python core owns all game rules. */
UCLASS()
class WARHAMMERCLIENT_API AWarhammerClientGameMode : public AGameModeBase
{
    GENERATED_BODY()
};
