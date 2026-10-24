#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "WarhammerClientGameMode.generated.h"

struct FLiveCoreScene;

#if WITH_DEV_AUTOMATION_TESTS && WITH_E02_AUTOMATION_DRIVER
class SWidget;

/** Test observations only; these contain no credentials or authoritative Core DTOs. */
struct FLiveCoreCameraInputObservation
{
    TWeakPtr<SWidget> Surface;
    TWeakPtr<SWidget> Endpoint;
    TWeakPtr<SWidget> Viewport;
    FVector ActorLocation = FVector::ZeroVector;
    FRotator ActorRotation = FRotator::ZeroRotator;
    FVector Focus = FVector::ZeroVector;
    double Distance = 0;
    double Azimuth = 0;
    double Elevation = 0;
    bool bReady = false;
    bool bViewTarget = false;
    bool bFocused = false;
    bool bEndpointFocused = false;
    bool bPolicyActive = false;
    bool bPolicyCapture = false;
    bool bSlateCapture = false;
    int32 CaptureOwner = -1;
    uint64 FrameKeyEvents = 0;
    uint64 ConfirmAttempts = 0;
    bool bBusy = false;
    bool bHasSession = false;
    bool bUnknown = false;
    bool bHasCommandOutcome = false;
    bool bCommandAccepted = false;
    bool bCommandCommitted = false;
    FString SessionId;
    FString RequestId;
    FString SessionStatus;
    FString SessionError;
    FString LastOutcomeCode;
    int32 LastHttpStatus = 0;
    int64 SessionRevision = -1;
    int64 ProjectionRevision = -1;
    uint64 ProjectionVersion = 0;
    int32 AcceptedActionCount = 0;
};
#endif

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

#if WITH_DEV_AUTOMATION_TESTS && WITH_E02_AUTOMATION_DRIVER
    // Explicit opt-in, disconnected-only synthetic presentation setup; no Core state injection.
    bool BeginCameraInputProofForTests(FString& OutError);
    void EndCameraInputProofForTests();
    bool ObserveCameraInputProofForTests(FLiveCoreCameraInputObservation& Out) const;
#endif

private:
    friend struct FLiveCoreScene;
    TUniquePtr<FLiveCoreScene> Scene;
};
