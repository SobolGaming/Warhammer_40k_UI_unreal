#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "GameFramework/PlayerController.h"
#include "Migration/E02Geometry.h"
#include "Migration/E02InputPolicy.h"
#include "E02WorldProofGameMode.generated.h"

class FJsonObject;
struct FE02ProofState;

/** Only the explicitly selected synthetic E02 world uses this controller. */
UCLASS(Transient)
class WARHAMMERCLIENT_API AE02ProofPlayerController : public APlayerController
{
    GENERATED_BODY()
public:
    AE02ProofPlayerController();
};

/** Opt-in, transient architecture experiment. There is deliberately no Core/session port. */
UCLASS(Transient)
class WARHAMMERCLIENT_API AE02WorldProofGameMode : public AGameModeBase
{
    GENERATED_BODY()
public:
    AE02WorldProofGameMode();
    virtual ~AE02WorldProofGameMode() override;
    virtual void BeginPlay() override;
    virtual void Tick(float DeltaSeconds) override;
    virtual void EndPlay(const EEndPlayReason::Type EndPlayReason) override;

    bool IsProofReady() const;
    FString GetProofError() const;
    const Warhammer::Migration::E02::FFixture& GetFixture() const;
    const Warhammer::Migration::E02::FInputPolicy& GetPolicy() const;
    FIntPoint GetProofViewportSize() const;
    double GetProofUiScale() const;
    TSharedPtr<FJsonObject> Snapshot() const;
    bool WriteSnapshot(const FString& Basename);
    bool BeginCase(const FString& CaseName);
    bool ResetCase();

    bool ModelScreenPoint(const FString& ModelId, FVector2D& AbsoluteScreen) const;
    bool DomainScreenPoint(const FVector3d& Domain, FVector2D& AbsoluteScreen) const;
    bool ControlScreenPoint(const FString& ControlId, FVector2D& AbsoluteScreen) const;
    bool QueryScreenPoint(const FVector2D& AbsoluteScreen,
        Warhammer::Migration::E02::FAdvisoryHit& Hit, FString& Diagnostic);
    /** Only a completed world-pick input event supplies this observation. Direct queries do not. */
    bool GetLastWorldPick(Warhammer::Migration::E02::FPointerSample& Pointer,
        Warhammer::Migration::E02::FRay& Ray, Warhammer::Migration::E02::FAdvisoryHit& Hit,
        uint64& PickGeneration, uint64& EventSequence) const;
    bool ProjectRayRoundTrip(const FVector3d& Domain, double& DomainErrorInches,
        double& PhysicalPixelError, FString& HitId);

    bool SetProofViewElevation(double Degrees);
    bool SetCubeSubstitution(const FString& ModelId, bool bEnabled);
    bool RequestProofScreenshot(const FString& Basename);
    bool IsScreenshotComplete(const FString& Basename) const;
    bool ProgrammaticResize(FIntPoint PhysicalExtent);
    bool SetProofUiScale(double Scale);
    void InjectActivation(bool bActive);
    void InjectCaptureLoss();
    uint64 EventCount() const;
    uint64 WorldPickCount() const;
    uint64 CameraMutationCount() const;
    FString VisibleStatus() const;
    bool IsTextFocused() const;
    bool IsModalOpen() const;

private:
    TUniquePtr<FE02ProofState> Proof;
};
