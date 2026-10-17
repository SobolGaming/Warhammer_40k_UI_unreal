#pragma once

#include "Migration/E02Geometry.h"

namespace Warhammer::Migration::E02
{
enum class EInputOwner : uint8
{
    None, Text, Modal, HudButton, HudDisabled, HudBackground, HudScroll,
    WorldSelection, Orbit, Pan
};
enum class EPointerButton : uint8 { Primary, Secondary, Middle };
enum class ECameraAction : uint8
{
    None, Orbit, Pan, Dolly, FrameBoard, FrameSelection, Reset,
    OrbitLeft, OrbitRight, OrbitUp, OrbitDown
};
enum class ELocalReview : uint8 { Empty, Editing, Ready };

const TCHAR* InputOwnerName(EInputOwner Owner);
const TCHAR* LocalReviewName(ELocalReview Review);

struct FPointerSample
{
    FVector2d ScreenPhysical = FVector2d::ZeroVector;
    FVector2d ViewportPhysical = FVector2d::ZeroVector;
    FVector2d Logical = FVector2d::ZeroVector;
    bool bInsideViewport = false;
};
struct FHitTarget
{
    EInputOwner Owner = EInputOwner::None;
    FString ControlId;
    bool bEnabled = true;
};
struct FCapture
{
    uint64 Generation = 0;
    EPointerButton Button = EPointerButton::Primary;
    EInputOwner Owner = EInputOwner::None;
    FPointerSample Start;
    FPointerSample Last;
    FString CapturedControlId;
    bool bDragged = false;
};
struct FLocalIntent
{
    FString ModelId;
    FDomainPose Pose;
};
struct FInputSnapshot
{
    TOptional<FLocalIntent> SelectedIntent;
    ELocalReview LocalReview = ELocalReview::Empty;
    uint64 ConfirmAttempts = 0;
    uint64 CancelGeneration = 0;
    uint64 HudActivationCount = 0;
    uint64 FocusGeneration = 0;
    uint64 CaptureGeneration = 0;
    bool bTextEditing = false;
    bool bModalOpen = false;
    bool bActive = true;
    TOptional<FCapture> Capture;
    FIntPoint ViewportExtent = FIntPoint::ZeroValue;
    double UiScale = 1.0;
};
struct FInputEffects
{
    bool bConsumed = false;
    bool bAcquireCapture = false;
    bool bReleaseCapture = false;
    bool bRequestWorldPick = false;
    bool bActivateHud = false;
    FString HudControlId;
    ECameraAction CameraAction = ECameraAction::None;
    FVector2d LogicalDelta = FVector2d::ZeroVector;
    double DollyDelta = 0.0;
    FDiagnostic Diagnostic;
};

// Slate owns actual hit tests/capture. This reducer only returns local effects.
class FInputPolicy
{
public:
    explicit FInputPolicy(double DragThresholdLogicalUnits = 4.0);
    const FInputSnapshot& Snapshot() const { return State; }
    FInputEffects Press(const FPointerSample& Sample, EPointerButton Button, const FHitTarget& Hit);
    FInputEffects Move(const FPointerSample& Sample);
    FInputEffects Release(const FPointerSample& Sample, EPointerButton Button, const FHitTarget& Hit);
    FInputEffects Wheel(const FPointerSample& Sample, const FHitTarget& Hit, double Delta);
    FInputEffects KeyCamera(ECameraAction Action);
    FInputEffects Confirm();
    FInputEffects Escape();
    FInputEffects FocusChanged(bool bActive);
    FInputEffects CaptureLost();
    FInputEffects ViewportChanged(FIntPoint Extent, double UiScale);
    FInputEffects SetTextEditing(bool bEditing);
    FInputEffects SetModalOpen(bool bOpen);
    void ApplyAdvisoryPick(const FString& ModelId, const FDomainPose& Pose);
    static constexpr uint64 CoreTransportCreations() { return 0; }
    static constexpr uint64 GameCommands() { return 0; }
    static constexpr uint64 AcceptedResults() { return 0; }

private:
    FInputEffects CancelCapture(bool bInvalidateReview);
    FInputSnapshot State;
    double DragThreshold;
};

FString SerializeLocalIntent(const FInputSnapshot& Snapshot);
}
