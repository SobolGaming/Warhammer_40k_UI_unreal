#include "Migration/E02InputPolicy.h"

#include "Serialization/JsonWriter.h"

namespace Warhammer::Migration::E02
{
namespace
{
bool IsHud(EInputOwner Owner)
{
    return Owner == EInputOwner::HudButton || Owner == EInputOwner::HudDisabled ||
        Owner == EInputOwner::HudBackground || Owner == EInputOwner::HudScroll;
}
bool ValidSample(const FPointerSample& Sample)
{
    return FMath::IsFinite(Sample.ScreenPhysical.X) && FMath::IsFinite(Sample.ScreenPhysical.Y) &&
        FMath::IsFinite(Sample.ViewportPhysical.X) && FMath::IsFinite(Sample.ViewportPhysical.Y) &&
        FMath::IsFinite(Sample.Logical.X) && FMath::IsFinite(Sample.Logical.Y);
}
FInputEffects Consumed()
{
    FInputEffects Effects;
    Effects.bConsumed = true;
    return Effects;
}
FInputEffects InvalidInput()
{
    FInputEffects Effects = Consumed();
    Effects.Diagnostic = { EDiagnosticCode::InvalidInput, TEXT("input"), TEXT("Input coordinates, extent or scale are invalid.") };
    return Effects;
}
}

const TCHAR* InputOwnerName(EInputOwner Owner)
{
    switch (Owner)
    {
    case EInputOwner::None: return TEXT("None");
    case EInputOwner::Text: return TEXT("Text");
    case EInputOwner::Modal: return TEXT("Modal");
    case EInputOwner::HudButton: return TEXT("HudButton");
    case EInputOwner::HudDisabled: return TEXT("HudDisabled");
    case EInputOwner::HudBackground: return TEXT("HudBackground");
    case EInputOwner::HudScroll: return TEXT("HudScroll");
    case EInputOwner::WorldSelection: return TEXT("WorldSelection");
    case EInputOwner::Orbit: return TEXT("Orbit");
    case EInputOwner::Pan: return TEXT("Pan");
    }
    return TEXT("UnknownOwner");
}
const TCHAR* LocalReviewName(ELocalReview Review)
{
    switch (Review)
    {
    case ELocalReview::Empty: return TEXT("Empty");
    case ELocalReview::Editing: return TEXT("Editing");
    case ELocalReview::Ready: return TEXT("Ready");
    }
    return TEXT("UnknownReview");
}

FInputPolicy::FInputPolicy(double Threshold) : DragThreshold(Threshold)
{
    // Invalid configuration is retained as invalid and rejected, never defaulted.
}

FInputEffects FInputPolicy::Press(const FPointerSample& Sample, EPointerButton Button, const FHitTarget& Hit)
{
    if (!ValidSample(Sample) || !FMath::IsFinite(DragThreshold) || DragThreshold <= 0.0) return InvalidInput();
    FInputEffects Effects = Consumed();
    if (!State.bActive || State.Capture.IsSet()) return Effects;
    EInputOwner Owner = Hit.Owner;
    if (State.bTextEditing) Owner = EInputOwner::Text;
    else if (State.bModalOpen) Owner = EInputOwner::Modal;
    else if (!Sample.bInsideViewport) return Effects;
    else if (Owner == EInputOwner::HudButton && !Hit.bEnabled) Owner = EInputOwner::HudDisabled;
    else if (Owner == EInputOwner::None || Owner == EInputOwner::WorldSelection)
        Owner = Button == EPointerButton::Secondary ? EInputOwner::Orbit : Button == EPointerButton::Middle ? EInputOwner::Pan : EInputOwner::WorldSelection;
    FCapture Capture;
    Capture.Generation = ++State.CaptureGeneration;
    Capture.Button = Button;
    Capture.Owner = Owner;
    Capture.Start = Sample;
    Capture.Last = Sample;
    Capture.CapturedControlId = Hit.ControlId;
    State.Capture = MoveTemp(Capture);
    Effects.bAcquireCapture = true;
    return Effects;
}

FInputEffects FInputPolicy::Move(const FPointerSample& Sample)
{
    if (!ValidSample(Sample)) return InvalidInput();
    FInputEffects Effects;
    if (!State.Capture.IsSet()) return Effects;
    Effects.bConsumed = true;
    FCapture& Capture = State.Capture.GetValue();
    const FVector2d Total = Sample.Logical - Capture.Start.Logical;
    const bool bWasDragged = Capture.bDragged;
    Capture.bDragged |= Total.SizeSquared() >= DragThreshold * DragThreshold;
    if (Capture.bDragged && (Capture.Owner == EInputOwner::Orbit || Capture.Owner == EInputOwner::Pan))
    {
        Effects.CameraAction = Capture.Owner == EInputOwner::Orbit ? ECameraAction::Orbit : ECameraAction::Pan;
        // Include threshold displacement exactly once; subsequent moves use deltas.
        Effects.LogicalDelta = Sample.Logical - (bWasDragged ? Capture.Last.Logical : Capture.Start.Logical);
    }
    Capture.Last = Sample;
    return Effects;
}

FInputEffects FInputPolicy::Release(const FPointerSample& Sample, EPointerButton Button, const FHitTarget& Hit)
{
    if (!ValidSample(Sample)) return InvalidInput();
    FInputEffects Effects = Consumed();
    if (!State.Capture.IsSet() || State.Capture->Button != Button) return Effects;
    FCapture Capture = State.Capture.GetValue();
    Capture.bDragged |= (Sample.Logical - Capture.Start.Logical).SizeSquared() >= DragThreshold * DragThreshold;
    State.Capture.Reset();
    Effects.bReleaseCapture = true;
    if (!State.bActive || State.bTextEditing || State.bModalOpen) return Effects;
    if (Button == EPointerButton::Primary && !Capture.bDragged && Sample.bInsideViewport)
    {
        if (Capture.Owner == EInputOwner::WorldSelection && (Hit.Owner == EInputOwner::None || Hit.Owner == EInputOwner::WorldSelection))
            Effects.bRequestWorldPick = true;
        else if (Capture.Owner == EInputOwner::HudButton && Hit.Owner == EInputOwner::HudButton && Hit.bEnabled &&
            Hit.ControlId == Capture.CapturedControlId)
        {
            Effects.bActivateHud = true;
            Effects.HudControlId = Hit.ControlId;
            ++State.HudActivationCount;
        }
    }
    return Effects;
}

FInputEffects FInputPolicy::Wheel(const FPointerSample& Sample, const FHitTarget& Hit, double Delta)
{
    if (!ValidSample(Sample) || !FMath::IsFinite(Delta)) return InvalidInput();
    FInputEffects Effects = Consumed();
    if (!State.bActive || State.bTextEditing || State.bModalOpen || State.Capture.IsSet() ||
        !Sample.bInsideViewport || IsHud(Hit.Owner) || Hit.Owner == EInputOwner::Text || Hit.Owner == EInputOwner::Modal) return Effects;
    Effects.CameraAction = ECameraAction::Dolly;
    Effects.DollyDelta = Delta;
    return Effects;
}

FInputEffects FInputPolicy::KeyCamera(ECameraAction Action)
{
    FInputEffects Effects = Consumed();
    if (!State.bActive || State.bTextEditing || State.bModalOpen || State.Capture.IsSet()) return Effects;
    switch (Action)
    {
    case ECameraAction::FrameBoard: case ECameraAction::FrameSelection: case ECameraAction::Reset:
    case ECameraAction::OrbitLeft: case ECameraAction::OrbitRight: case ECameraAction::OrbitUp: case ECameraAction::OrbitDown:
        Effects.CameraAction = Action;
        break;
    default:
        Effects.Diagnostic = { EDiagnosticCode::InvalidInput, TEXT("key"), TEXT("Unsupported camera key action.") };
        break;
    }
    return Effects;
}

FInputEffects FInputPolicy::Confirm()
{
    FInputEffects Effects = Consumed();
    if (!State.bActive || State.bTextEditing || State.bModalOpen || State.Capture.IsSet()) return Effects;
    ++State.ConfirmAttempts;
    if (State.SelectedIntent.IsSet() && State.LocalReview == ELocalReview::Editing)
        State.LocalReview = ELocalReview::Ready;
    else
        Effects.Diagnostic = { EDiagnosticCode::ProofHasNoGameSession, TEXT("confirm"), TEXT("ProofHasNoGameSession: synthetic local review cannot submit or accept a game command.") };
    return Effects;
}

FInputEffects FInputPolicy::CancelCapture(bool bInvalidateReview)
{
    FInputEffects Effects = Consumed();
    Effects.bReleaseCapture = State.Capture.IsSet();
    State.Capture.Reset();
    ++State.CancelGeneration;
    ++State.CaptureGeneration;
    if (bInvalidateReview && State.SelectedIntent.IsSet()) State.LocalReview = ELocalReview::Editing;
    return Effects;
}
FInputEffects FInputPolicy::Escape()
{
    if (State.Capture.IsSet()) return CancelCapture(false);
    FInputEffects Effects = Consumed();
    if (State.bTextEditing) State.bTextEditing = false;
    else if (State.bModalOpen) State.bModalOpen = false;
    else if (State.SelectedIntent.IsSet()) State.LocalReview = ELocalReview::Editing;
    ++State.CancelGeneration;
    return Effects;
}
FInputEffects FInputPolicy::FocusChanged(bool bActive)
{
    if (State.bActive == bActive) return Consumed();
    State.bActive = bActive;
    ++State.FocusGeneration;
    return CancelCapture(!bActive);
}
FInputEffects FInputPolicy::CaptureLost()
{
    // Slate also reports the ordinary release we requested after a completed
    // gesture. Only an outstanding capture represents unexpected capture loss.
    return State.Capture.IsSet() ? CancelCapture(true) : Consumed();
}
FInputEffects FInputPolicy::ViewportChanged(FIntPoint Extent, double UiScale)
{
    if (Extent.X <= 0 || Extent.Y <= 0 || !FMath::IsFinite(UiScale) || UiScale <= 0.0) return InvalidInput();
    if (State.ViewportExtent == Extent && State.UiScale == UiScale) return Consumed();
    State.ViewportExtent = Extent;
    State.UiScale = UiScale;
    return CancelCapture(true);
}
FInputEffects FInputPolicy::SetTextEditing(bool bEditing)
{
    FInputEffects Effects = CancelCapture(false);
    State.bTextEditing = bEditing;
    return Effects;
}
FInputEffects FInputPolicy::SetModalOpen(bool bOpen)
{
    FInputEffects Effects = CancelCapture(false);
    State.bModalOpen = bOpen;
    if (!bOpen) State.bTextEditing = false;
    return Effects;
}
void FInputPolicy::ApplyAdvisoryPick(const FString& ModelId, const FDomainPose& Pose)
{
    // Only the successful runtime ray handler calls this. Camera and cosmetic
    // visual changes never call it or round-trip a render offset into this pose.
    State.SelectedIntent = FLocalIntent{ ModelId, Pose };
    State.LocalReview = ELocalReview::Editing;
}
FString SerializeLocalIntent(const FInputSnapshot& Snapshot)
{
    if (!Snapshot.SelectedIntent.IsSet()) return TEXT("null");
    const FLocalIntent& Intent = Snapshot.SelectedIntent.GetValue();
    FString Result;
    const TSharedRef<TJsonWriter<TCHAR, TCondensedJsonPrintPolicy<TCHAR>>> Writer =
        TJsonWriterFactory<TCHAR, TCondensedJsonPrintPolicy<TCHAR>>::Create(&Result);
    // Explicit member order makes byte preservation independent of hash-map order.
    Writer->WriteObjectStart();
    Writer->WriteValue(TEXT("kind"), TEXT("synthetic_advisory_intent"));
    Writer->WriteValue(TEXT("label"), TEXT("SYNTHETIC / ADVISORY - NO GAME SESSION"));
    Writer->WriteValue(TEXT("has_game_session"), false);
    Writer->WriteValue(TEXT("model_id"), Intent.ModelId);
    Writer->WriteArrayStart(TEXT("position_inches"));
    Writer->WriteValue(Intent.Pose.PositionInches.X);
    Writer->WriteValue(Intent.Pose.PositionInches.Y);
    Writer->WriteValue(Intent.Pose.PositionInches.Z);
    Writer->WriteArrayEnd();
    Writer->WriteValue(TEXT("facing_degrees"), Intent.Pose.FacingDegrees);
    Writer->WriteObjectEnd();
    Writer->Close();
    return Result;
}
}
