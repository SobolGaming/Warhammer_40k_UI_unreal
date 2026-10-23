#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "WarhammerClientGameMode.generated.h"

struct FLiveCoreScene;

/** Minimal live development client. The external Python core owns all game rules. */
UCLASS()
class WARHAMMERCLIENT_API AWarhammerClientGameMode : public AGameModeBase
{
    GENERATED_BODY()
public:
    AWarhammerClientGameMode();
    AWarhammerClientGameMode(FVTableHelper& Helper);
    virtual ~AWarhammerClientGameMode() override;
    virtual void BeginPlay() override;
    virtual void Tick(float DeltaSeconds) override;
    virtual void EndPlay(const EEndPlayReason::Type EndPlayReason) override;

private:
    friend struct FLiveCoreScene;
    TUniquePtr<FLiveCoreScene> Scene;
};
