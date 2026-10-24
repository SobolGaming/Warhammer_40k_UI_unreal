#include "WarhammerClientGameMode.h"

#include "LiveCore/LiveCoreSession.h"
#include "LiveCore/LiveCoreCamera.h"
#include "Migration/E02InputPolicy.h"
#include "Camera/CameraActor.h"
#include "Camera/CameraComponent.h"
#include "Components/DirectionalLightComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/DirectionalLight.h"
#include "Engine/GameViewportClient.h"
#include "Engine/LocalPlayer.h"
#include "Engine/StaticMesh.h"
#include "Engine/World.h"
#include "GameFramework/PlayerController.h"
#include "Framework/Application/SlateApplication.h"
#include "Framework/Application/SlateUser.h"
#include "HAL/PlatformMisc.h"
#include "InputCoreTypes.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "Materials/MaterialInterface.h"
#include "Misc/CommandLine.h"
#include "Misc/Parse.h"
#include "Styling/CoreStyle.h"
#include "Rendering/DrawElementTypes.h"
#include "SceneView.h"
#include "UObject/StrongObjectPtr.h"
#include "Widgets/Input/SButton.h"
#include "Widgets/Input/SEditableTextBox.h"
#include "Widgets/Layout/SBorder.h"
#include "Widgets/Layout/SBox.h"
#include "Widgets/Layout/SScrollBox.h"
#include "Widgets/SBoxPanel.h"
#include "Widgets/SCompoundWidget.h"
#include "Widgets/SOverlay.h"
#include "Widgets/SLeafWidget.h"
#include "Widgets/SViewport.h"
#include "Widgets/Text/STextBlock.h"

namespace
{
constexpr double CmPerInch = 2.54;
constexpr double CameraHelpHeight = 32.0;

// Display transform only: Core inches, +Y up-table -> Unreal centimetres, -Y.
FVector DisplayPoint(const FVector& Inches, const FVector2D& Centre)
{
    return FVector((Inches.X - Centre.X) * CmPerInch,
        -(Inches.Y - Centre.Y) * CmPerInch, Inches.Z * CmPerInch);
}
}

class SLiveCorePanel;
class SLiveCoreCameraSurface;

struct FLiveCoreScene
{
    explicit FLiveCoreScene(AWarhammerClientGameMode* InOwner) : Owner(InOwner)
    {
        Session = FLiveCoreSession::Create();
        FParse::Value(FCommandLine::Get(), TEXT("CoreUrl="), Endpoint);
        Session->InitializeEndpoint(Endpoint);
    }

    TWeakObjectPtr<AWarhammerClientGameMode> Owner;
    TSharedPtr<FLiveCoreSession> Session;
    TSharedPtr<SLiveCorePanel> Panel;
    TSharedPtr<SLiveCoreCameraSurface> CameraSurface;
    TSharedPtr<SWidget> Overlay;
    TWeakObjectPtr<ACameraActor> Camera;
    TWeakObjectPtr<ADirectionalLight> Light;
    TStrongObjectPtr<UStaticMesh> Cube;
    TStrongObjectPtr<UStaticMesh> Cylinder;
    TStrongObjectPtr<UMaterialInterface> Material;
    TArray<TWeakObjectPtr<AActor>> BoardActors;
    FString Endpoint = TEXT("http://127.0.0.1:8765");
    FString SceneError;
    FString CameraError;
    FString RenderedSession;
    uint64 RenderedProjectionVersion = 0;
    bool bAttached = false;
    FDelegateHandle ActivationHandle;
    Warhammer::LiveCore::FTabletopCamera CameraNavigation;
#if WITH_DEV_AUTOMATION_TESTS && WITH_E02_AUTOMATION_DRIVER
    TOptional<Warhammer::LiveCore::FTabletopCamera> NavigationBeforeInputProof;
    FTransform CameraBeforeInputProof;
    FText EndpointBeforeInputProof;
    FString CameraErrorBeforeInputProof;
#endif

    UWorld* World() const { return Owner.IsValid() ? Owner->GetWorld() : nullptr; }
    UGameViewportClient* Viewport() const { return World() ? World()->GetGameViewport() : nullptr; }
    void Initialize();
    void Attach();
    void Changed();
    void RebuildBoard();
    void Shutdown();
    void UpdateCameraLayout(const FGeometry& Geometry);
    void UpdateCamera();
    void FrameBoard();

    void ClearBoard()
    {
        for (const auto& Actor : BoardActors) { if (Actor.IsValid()) { Actor->Destroy(); } }
        BoardActors.Empty();
    }

    void Mesh(UStaticMesh* Asset, const FVector& Position, const FVector& Scale,
        const FRotator& Rotation, const FLinearColor& Colour)
    {
        if (!World() || !Asset || !Material.IsValid()) { return; }
        AActor* Actor = World()->SpawnActor<AActor>();
        if (!Actor) { SceneError = TEXT("Could not create a board display actor."); return; }
        Actor->SetFlags(RF_Transient);
        UStaticMeshComponent* Component = NewObject<UStaticMeshComponent>(Actor, NAME_None, RF_Transient);
        Actor->SetRootComponent(Component);
        Component->SetMobility(EComponentMobility::Movable);
        Component->SetStaticMesh(Asset);
        Component->SetCollisionEnabled(ECollisionEnabled::NoCollision);
        Component->SetCastShadow(false);
        UMaterialInstanceDynamic* Tint = UMaterialInstanceDynamic::Create(Material.Get(), Component);
        if (Tint)
        {
            Tint->SetVectorParameterValue(TEXT("Color"), Colour);
            Component->SetMaterial(0, Tint);
        }
        Component->RegisterComponent();
        Actor->SetActorLocation(Position);
        Actor->SetActorRotation(Rotation);
        Actor->SetActorScale3D(Scale);
        BoardActors.Add(Actor);
    }

    void Box(const FVector& Position, const FVector& SizeCm, const FLinearColor& Colour,
        const FRotator& Rotation = FRotator::ZeroRotator)
    {
        Mesh(Cube.Get(), Position, SizeCm / 100.0, Rotation, Colour);
    }

    void Disc(const FVector& Position, double RadiusInches, double HeightCm, const FLinearColor& Colour)
    {
        Mesh(Cylinder.Get(), Position, FVector(2 * RadiusInches * CmPerInch / 100.0,
            2 * RadiusInches * CmPerInch / 100.0, HeightCm / 100.0), FRotator::ZeroRotator, Colour);
    }
};

class SLiveCorePanel : public SCompoundWidget
{
public:
    SLATE_BEGIN_ARGS(SLiveCorePanel) {} SLATE_END_ARGS()
    virtual bool SupportsKeyboardFocus() const override { return true; }

    void Construct(const FArguments&, FLiveCoreScene* InScene)
    {
        Scene = InScene;
        ChildSlot
        [
            SNew(SBorder)
            .BorderImage(FCoreStyle::Get().GetBrush(TEXT("WhiteBrush")))
            .BorderBackgroundColor(FLinearColor(0.025f, 0.035f, 0.055f, 0.97f))
            .Padding(16)
            [
                SNew(SScrollBox)
                + SScrollBox::Slot()
                [
                SNew(SVerticalBox)
                + SVerticalBox::Slot().AutoHeight().Padding(0, 0, 0, 10)
                [SNew(STextBlock).Text(FText::FromString(TEXT("Warhammer — live Core")))
                    .Font(FCoreStyle::GetDefaultFontStyle(TEXT("Bold"), 20))]
                + SVerticalBox::Slot().AutoHeight().Padding(0, 0, 0, 6)
                [SNew(STextBlock).AutoWrapText(true).Text(FText::FromString(
                    TEXT("Connect to the selected Core. Create a session or open a known active session as player-a. Keep Core running with Attach when reopening across client launches.")))]
                + SVerticalBox::Slot().AutoHeight().Padding(0, 0, 0, 8)
                [SAssignNew(EndpointBox, SEditableTextBox).Text(FText::FromString(Scene->Endpoint))
                    .IsEnabled_Lambda([this]() { return !State().bBusy && !State().bHasSession && !State().bUnknown; })]
                + SVerticalBox::Slot().AutoHeight().Padding(0, 0, 0, 8)
                [SNew(SButton).Text(FText::FromString(TEXT("Connect / create session")))
                    .IsEnabled_Lambda([this]() { return !State().bBusy && !State().bHasSession && !State().bUnknown; })
                    .OnClicked_Lambda([this]()
                    {
                        if (!Scene || !Scene->Session.IsValid()) { return FReply::Handled(); }
                        Scene->Endpoint = EndpointBox->GetText().ToString();
                        Scene->Session->CreateAndStart(Scene->Endpoint);
                        return FReply::Handled();
                    })]
                + SVerticalBox::Slot().AutoHeight().Padding(0, 0, 0, 4)
                [SNew(STextBlock).AutoWrapText(true).Text(FText::FromString(TEXT("Existing session ID (player-a)")))]
                + SVerticalBox::Slot().AutoHeight().Padding(0, 0, 0, 8)
                [SAssignNew(SessionIdBox, SEditableTextBox)
                    .HintText(FText::FromString(TEXT("Paste a known active session ID")))
                    .IsReadOnly_Lambda([this]() { return State().bBusy || State().bHasSession || State().bUnknown; })]
                + SVerticalBox::Slot().AutoHeight().Padding(0, 0, 0, 8)
                [SNew(SButton).Text(FText::FromString(TEXT("Open existing session")))
                    .IsEnabled_Lambda([this]() { return !State().bBusy && !State().bHasSession && !State().bUnknown; })
                    .OnClicked_Lambda([this]()
                    {
                        if (!Scene || !Scene->Session.IsValid() || !SessionIdBox.IsValid()) { return FReply::Handled(); }
                        Scene->Endpoint = EndpointBox->GetText().ToString();
                        Scene->Session->OpenExistingSession(Scene->Endpoint, SessionIdBox->GetText().ToString());
                        return FReply::Handled();
                    })]
                + SVerticalBox::Slot().AutoHeight().Padding(0, 0, 0, 8)
                [SNew(STextBlock).AutoWrapText(true).Text_Lambda([this]()
                    { return FText::FromString(State().Status); })]
                + SVerticalBox::Slot().AutoHeight().Padding(0, 0, 0, 8)
                [SNew(STextBlock).AutoWrapText(true).ColorAndOpacity(FLinearColor(1.0f, 0.52f, 0.28f))
                    .Text_Lambda([this]()
                    {
                        if (!Scene) { return FText::GetEmpty(); }
                        return FText::FromString(State().Error +
                            (Scene->SceneError.IsEmpty() ? FString() : TEXT("\n") + Scene->SceneError) +
                            (Scene->CameraError.IsEmpty() ? FString() : TEXT("\n") + Scene->CameraError));
                    })]
                + SVerticalBox::Slot().AutoHeight().Padding(0, 0, 0, 8)
                [SNew(STextBlock).AutoWrapText(true).Text_Lambda([this]()
                    {
                        const auto& Value = State();
                        if (!Value.bHasSession) { return FText::FromString(TEXT("Awaiting authoritative session state.")); }
                        const FString RevisionText = Value.SessionRevision == Value.ProjectionRevision ?
                            FString::Printf(TEXT("Revision: %lld"), static_cast<long long>(Value.SessionRevision)) :
                            FString::Printf(TEXT("Session revision: %lld; displayed projection: %lld (refresh pending)"),
                                static_cast<long long>(Value.SessionRevision), static_cast<long long>(Value.ProjectionRevision));
                        return FText::FromString(FString::Printf(TEXT("Session: %s\n%s\nPhase: %s\nViewer: %s\nAccepted actions in this client: %d\nLast HTTP: %d"),
                            *Value.SessionId, *RevisionText, *Value.Phase, *Value.ViewerPlayerId,
                            Value.AcceptedActionCount, Value.LastHttpStatus));
                    })]
                + SVerticalBox::Slot().AutoHeight().Padding(0, 0, 0, 8)
                [SNew(STextBlock).AutoWrapText(true).Text_Lambda([this]()
                    { return FText::FromString(State().MissionSummary); })]
                + SVerticalBox::Slot().AutoHeight().Padding(0, 0, 0, 8)
                [SNew(STextBlock).AutoWrapText(true).Text_Lambda([this]()
                    {
                        const auto& Value = State();
                        return FText::FromString(Value.bLastCommandHasOutcome
                            ? FString::Printf(TEXT("Core outcome: %s\naccepted=%s, committed=%s"), *Value.LastOutcomeCode,
                                Value.bLastCommandAccepted ? TEXT("true") : TEXT("false"),
                                Value.bLastCommandCommitted ? TEXT("true") : TEXT("false"))
                            : FString());
                    })]
                + SVerticalBox::Slot().AutoHeight().Padding(0, 0, 0, 8)
                [SNew(SButton).Text(FText::FromString(TEXT("Frame board")))
                    .IsEnabled_Lambda([this]() { return Scene && Scene->CameraNavigation.IsReady(); })
                    .OnClicked_Lambda([this]()
                    {
                        if (Scene) { Scene->FrameBoard(); }
                        return FReply::Handled();
                    })]
                + SVerticalBox::Slot().AutoHeight().Padding(0, 0, 0, 8)
                [SNew(SButton).Text(FText::FromString(TEXT("Refresh viewer state")))
                    .IsEnabled_Lambda([this]() { return State().bHasSession && !State().bBusy && !State().bUnknown; })
                    .OnClicked_Lambda([this]()
                    {
                        if (Scene && Scene->Session.IsValid()) { Scene->Session->Refresh(); }
                        return FReply::Handled();
                    })]
                + SVerticalBox::Slot().AutoHeight().Padding(0, 0, 0, 8)
                [SNew(SButton).Text(FText::FromString(TEXT("Reconcile unknown command")))
                    .IsEnabled_Lambda([this]() { return State().bCanReconcile && !State().bBusy; })
                    .OnClicked_Lambda([this]()
                    {
                        if (Scene && Scene->Session.IsValid()) { Scene->Session->ReconcileUnknown(); }
                        return FReply::Handled();
                    })]
                + SVerticalBox::Slot().AutoHeight().Padding(0, 4, 0, 8)
                [SNew(STextBlock).AutoWrapText(true).Text_Lambda([this]()
                    {
                        const auto& Value = State();
                        switch (Value.DecisionPresentation)
                        {
                        case ELiveCoreDecisionPresentation::NoPending:
                            return FText::FromString(TEXT("Core reports no pending decision."));
                        case ELiveCoreDecisionPresentation::Hidden:
                            return FText::FromString(TEXT("Core has hidden the pending decision from this viewer. No hidden details are displayed."));
                        case ELiveCoreDecisionPresentation::ParameterizedUnsupported:
                            return FText::FromString(TEXT("This visible decision needs an editor that this preview does not yet support.\nDecision: ") + Value.RequestType);
                        case ELiveCoreDecisionPresentation::OtherActor:
                            return FText::FromString(TEXT("This visible decision belongs to a different actor. This preview cannot submit it."));
                        case ELiveCoreDecisionPresentation::UnsupportedActor:
                            return FText::FromString(TEXT("This visible decision has no supported player actor for this preview."));
                        case ELiveCoreDecisionPresentation::FiniteOptions:
                            return FText::FromString((Value.Options.IsEmpty()
                                ? FString(TEXT("Core currently offers no finite options for this decision."))
                                : FString(TEXT("Choose a Core-offered option below. Submit now sends the choice immediately."))) + TEXT("\n") + Value.RequestType);
                        default:
                            return FText::FromString(TEXT("Decision information is unavailable until an authoritative projection arrives."));
                        }
                    })]
                + SVerticalBox::Slot().AutoHeight()
                [SAssignNew(Options, SVerticalBox)]
                + SVerticalBox::Slot().AutoHeight().Padding(0, 12, 0, 0)
                [SNew(STextBlock).AutoWrapText(true).Text(FText::FromString(
                    TEXT("Terrain outlines and tokens are advisory. Unplaced models are not drawn. Click the board to focus; RMB drag orbits, MMB drag pans, wheel zooms, F frames. Window resizing reframes.")))
                    .ColorAndOpacity(FLinearColor(0.65f, 0.72f, 0.8f))]
                ]
            ]
        ];
        RefreshOptions();
    }

    void RefreshOptions()
    {
        // Keep the attached identity available for ordinary select/copy without
        // replacing an editable draft after a failed read.
        if (SessionIdBox.IsValid() && State().bHasSession)
        { SessionIdBox->SetText(FText::FromString(State().SessionId)); }
        if (!Options.IsValid()) { return; }
        Options->ClearChildren();
        for (const auto& Option : State().Options)
        {
            const FString Id = Option.Id;
            const bool bAvailable = Option.bAvailable;
            Options->AddSlot().AutoHeight().Padding(0, 0, 0, 6)
            [SNew(SButton)
                .IsEnabled_Lambda([this, bAvailable]() { return bAvailable && !State().bBusy && !State().bUnknown; })
                .OnClicked_Lambda([this, Id]()
                {
                    if (Scene && Scene->Session.IsValid()) { Scene->Session->SelectOfferedOption(Id); }
                    return FReply::Handled();
                })
                [SNew(STextBlock).AutoWrapText(true).Text(FText::FromString(TEXT("Submit now: ") + Option.Label))]];
        }
    }

#if WITH_DEV_AUTOMATION_TESTS && WITH_E02_AUTOMATION_DRIVER
    TWeakPtr<SEditableTextBox> EndpointForInputProof() const { return EndpointBox; }
#endif

    void Detach()
    {
        // Slate can retain this widget after it leaves the viewport (for example, focus).
        // Its callbacks must outlive the scene without retaining or dereferencing it.
        Scene = nullptr;
        if (SessionIdBox.IsValid()) { SessionIdBox->SetText(FText::GetEmpty()); }
        if (Options.IsValid()) { Options->ClearChildren(); }
    }

private:
    const FLiveCoreState& State() const
    {
        if (Scene && Scene->Session.IsValid()) { return Scene->Session->GetState(); }
        static const FLiveCoreState DetachedState = []()
        {
            FLiveCoreState Value;
            Value.bBusy = true;
            Value.Status = TEXT("Client closed.");
            return Value;
        }();
        return DetachedState;
    }
    FLiveCoreScene* Scene = nullptr;
    TSharedPtr<SEditableTextBox> EndpointBox;
    TSharedPtr<SEditableTextBox> SessionIdBox;
    TSharedPtr<SVerticalBox> Options;
};

/** Only this arranged right-hand Slate region owns camera gestures. */
class SLiveCoreCameraSurface : public SLeafWidget
{
public:
    SLATE_BEGIN_ARGS(SLiveCoreCameraSurface) {} SLATE_END_ARGS()
    void Construct(const FArguments&, FLiveCoreScene* InScene) { Scene = InScene; SetCanTick(true); }
    virtual bool SupportsKeyboardFocus() const override { return true; }
    virtual FVector2D ComputeDesiredSize(float) const override { return FVector2D(100, 100); }
    virtual void Tick(const FGeometry& G, double, float) override { if (Scene) { Scene->UpdateCameraLayout(G); } }
    virtual int32 OnPaint(const FPaintArgs&, const FGeometry& G, const FSlateRect&,
        FSlateWindowElementList& Elements, int32 Layer, const FWidgetStyle&, bool) const override
    {
        const FString Help = HasKeyboardFocus()
            ? TEXT("Board has keyboard focus  |  RMB: orbit  MMB: pan  Wheel: zoom  F: frame")
            : TEXT("Click board for keyboard focus  |  RMB: orbit  MMB: pan  Wheel: zoom  F: frame");
        FSlateDrawElement::MakeText(Elements, Layer, G.ToPaintGeometry(FVector2D(G.GetLocalSize().X, CameraHelpHeight),
            FSlateLayoutTransform(FVector2D(8, 8))), Help,
            FCoreStyle::GetDefaultFontStyle(TEXT("Regular"), 11), ESlateDrawEffect::None, FLinearColor::White);
        return Layer + 1;
    }
    void Cancel(bool bDeactivate = true)
    {
        if (bDeactivate) { Policy.FocusChanged(false); } else { Policy.CaptureLost(); }
        if (FSlateApplication::IsInitialized() && HasMouseCaptureByUser(CaptureUser, CapturePointer))
        {
            const auto User = FSlateApplication::Get().GetUser(CaptureUser);
            if (User.IsValid()) { User->ReleaseCapture(CapturePointer); }
        }
    }
    void ApplicationActive(bool bActive)
    {
        if (!bActive) { Cancel(); }
        else { Policy.FocusChanged(HasKeyboardFocus()); }
    }
    void Detach() { Cancel(); Scene = nullptr; }
    virtual FReply OnMouseButtonDown(const FGeometry& G, const FPointerEvent& E) override
    {
        using namespace Warhammer::Migration::E02;
        const FKey Button = E.GetEffectingButton();
        if (Button != EKeys::LeftMouseButton && Button != EKeys::RightMouseButton && Button != EKeys::MiddleMouseButton)
        { return FReply::Unhandled(); }
        if (Policy.Snapshot().Capture.IsSet() && !MatchesCapture(E)) { return FReply::Unhandled(); }
        if (!Scene) { return FReply::Handled(); }
        Policy.FocusChanged(true);
        FReply Reply = FReply::Handled().SetUserFocus(SharedThis(this));
        // Primary click only focuses the camera surface. It never picks, captures or submits.
        if (Button == EKeys::LeftMouseButton || !Scene->CameraNavigation.IsReady()) { return Reply; }
        const auto Effect = Policy.Press(Sample(G, E), Button == EKeys::RightMouseButton ? EPointerButton::Secondary : EPointerButton::Middle, {});
        if (Effect.bAcquireCapture)
        {
            CaptureUser = static_cast<int32>(E.GetUserIndex());
            CapturePointer = static_cast<int32>(E.GetPointerIndex());
            Reply.CaptureMouse(SharedThis(this));
        }
        return Reply;
    }
    virtual FReply OnMouseMove(const FGeometry& G, const FPointerEvent& E) override
    {
        if (!Scene || !Policy.Snapshot().Capture.IsSet()) { return FReply::Unhandled(); }
        if (!MatchesCapture(E)) { return FReply::Unhandled(); }
        if (!HasMouseCaptureByUser(CaptureUser, CapturePointer)) { Policy.FocusChanged(false); return FReply::Handled(); }
        Apply(Policy.Move(Sample(G, E)));
        return FReply::Handled();
    }
    virtual FReply OnMouseButtonUp(const FGeometry& G, const FPointerEvent& E) override
    {
        using namespace Warhammer::Migration::E02;
        if (Policy.Snapshot().Capture.IsSet() && !MatchesCapture(E)) { return FReply::Unhandled(); }
        if (E.GetEffectingButton() != EKeys::RightMouseButton && E.GetEffectingButton() != EKeys::MiddleMouseButton)
        { return FReply::Handled(); }
        const auto Effect = Policy.Release(Sample(G, E), E.GetEffectingButton() == EKeys::RightMouseButton ? EPointerButton::Secondary : EPointerButton::Middle, {});
        FReply Reply = FReply::Handled();
        if (Effect.bReleaseCapture) { Reply.ReleaseMouseCapture(); }
        return Reply;
    }
    virtual FReply OnMouseWheel(const FGeometry& G, const FPointerEvent& E) override
    {
        // Editing the endpoint does not silently hand keyboard ownership to the board.
        if (!Scene || !HasKeyboardFocus()) { return FReply::Unhandled(); }
        if (Policy.Snapshot().Capture.IsSet() && !MatchesCapture(E)) { return FReply::Unhandled(); }
        Apply(Policy.Wheel(Sample(G, E), {}, E.GetWheelDelta()));
        return FReply::Handled();
    }
    virtual FReply OnKeyDown(const FGeometry&, const FKeyEvent& E) override
    {
        using namespace Warhammer::Migration::E02;
        if (E.GetKey() == EKeys::Escape)
        {
            const auto Effect = Policy.Escape(); FReply Reply = FReply::Handled();
            if (Effect.bReleaseCapture) { Reply.ReleaseMouseCapture(); }
            return Reply;
        }
        if (Scene && E.GetKey() == EKeys::F && !E.IsControlDown() && !E.IsAltDown() && !E.IsShiftDown() && !E.IsCommandDown())
        {
#if WITH_DEV_AUTOMATION_TESTS && WITH_E02_AUTOMATION_DRIVER
            ++FrameKeyEventsForTests;
#endif
            Apply(Policy.KeyCamera(ECameraAction::FrameBoard)); return FReply::Handled();
        }
        return FReply::Unhandled();
    }
    virtual FReply OnFocusReceived(const FGeometry&, const FFocusEvent&) override
    { Policy.FocusChanged(true); Invalidate(EInvalidateWidgetReason::Paint); return FReply::Handled(); }
    virtual void OnFocusLost(const FFocusEvent&) override { Cancel(); Invalidate(EInvalidateWidgetReason::Paint); }
    virtual void OnMouseCaptureLost(const FCaptureLostEvent&) override
    { if (Policy.Snapshot().Capture.IsSet()) { Policy.FocusChanged(false); } }
#if WITH_DEV_AUTOMATION_TESTS && WITH_E02_AUTOMATION_DRIVER
    void BeginInputProof() { PolicyBeforeInputProof = Policy; }
    void EndInputProof()
    {
        Cancel();
        if (PolicyBeforeInputProof.IsSet()) { Policy = PolicyBeforeInputProof.GetValue(); PolicyBeforeInputProof.Reset(); }
    }
    void ObserveInputProof(FLiveCoreCameraInputObservation& Out) const
    {
        const auto& State = Policy.Snapshot();
        Out.bFocused = HasKeyboardFocus(); Out.bPolicyActive = State.bActive;
        Out.bPolicyCapture = State.Capture.IsSet();
        Out.bSlateCapture = HasMouseCaptureByUser(CaptureUser, CapturePointer);
        Out.CaptureOwner = State.Capture.IsSet() ? static_cast<int32>(State.Capture->Owner) : -1;
        Out.CaptureUser = CaptureUser; Out.CapturePointer = CapturePointer;
        Out.FrameKeyEvents = FrameKeyEventsForTests; Out.ConfirmAttempts = State.ConfirmAttempts;
    }
#endif
private:
    bool MatchesCapture(const FPointerEvent& E) const
    { return CaptureUser == static_cast<int32>(E.GetUserIndex()) && CapturePointer == static_cast<int32>(E.GetPointerIndex()); }
    Warhammer::Migration::E02::FPointerSample Sample(const FGeometry& G, const FPointerEvent& E) const
    {
        const FVector2D P = G.AbsoluteToLocal(E.GetScreenSpacePosition());
        Warhammer::Migration::E02::FPointerSample Value;
        Value.ScreenPhysical = E.GetScreenSpacePosition(); Value.ViewportPhysical = P; Value.Logical = P;
        Value.bInsideViewport = P.X >= 0 && P.Y >= CameraHelpHeight && P.X < G.GetLocalSize().X && P.Y < G.GetLocalSize().Y;
        return Value;
    }
    void Apply(const Warhammer::Migration::E02::FInputEffects& Effect)
    {
        using namespace Warhammer::Migration::E02;
        if (!Scene) { return; }
        switch (Effect.CameraAction)
        {
        case ECameraAction::Orbit: Scene->CameraNavigation.Orbit(Effect.LogicalDelta); break;
        case ECameraAction::Pan: Scene->CameraNavigation.Pan(Effect.LogicalDelta); break;
        case ECameraAction::Dolly: Scene->CameraNavigation.Zoom(Effect.DollyDelta); break;
        case ECameraAction::FrameBoard: Scene->FrameBoard(); return;
        default: return;
        }
        Scene->UpdateCamera();
    }
    FLiveCoreScene* Scene = nullptr;
    Warhammer::Migration::E02::FInputPolicy Policy;
    int32 CaptureUser = 0;
    int32 CapturePointer = 0;
#if WITH_DEV_AUTOMATION_TESTS && WITH_E02_AUTOMATION_DRIVER
    uint64 FrameKeyEventsForTests = 0;
    TOptional<Warhammer::Migration::E02::FInputPolicy> PolicyBeforeInputProof;
#endif
};

void FLiveCoreScene::Initialize()
{
    Cube.Reset(LoadObject<UStaticMesh>(nullptr, TEXT("/Engine/BasicShapes/Cube.Cube")));
    Cylinder.Reset(LoadObject<UStaticMesh>(nullptr, TEXT("/Engine/BasicShapes/Cylinder.Cylinder")));
    Material.Reset(LoadObject<UMaterialInterface>(nullptr, TEXT("/Engine/BasicShapes/BasicShapeMaterial.BasicShapeMaterial")));
    if (!Cube.IsValid() || !Cylinder.IsValid() || !Material.IsValid())
    {
        SceneError = TEXT("Required engine display meshes/material are unavailable.");
    }
    else
    {
        TArray<FMaterialParameterInfo> Parameters;
        TArray<FGuid> ParameterIds;
        Material->GetAllVectorParameterInfo(Parameters, ParameterIds);
        if (!Parameters.ContainsByPredicate([](const FMaterialParameterInfo& Value) { return Value.Name == TEXT("Color"); }))
        {
            SceneError = TEXT("Engine display material lacks its required Color parameter.");
        }
    }
    Camera = World()->SpawnActor<ACameraActor>();
    Light = World()->SpawnActor<ADirectionalLight>();
    if (Camera.IsValid())
    {
        Camera->SetFlags(RF_Transient);
        UCameraComponent* Component = Camera->GetCameraComponent();
        Component->ProjectionMode = ECameraProjectionMode::Perspective;
        Component->SetFieldOfView(55.0f);
        Component->SetConstraintAspectRatio(false);
        Component->bOverrideAspectRatioAxisConstraint = true;
        Component->SetAspectRatioAxisConstraint(AspectRatio_MaintainXFOV);
        auto& Exposure = Component->PostProcessSettings;
        Exposure.bOverride_AutoExposureMethod = true;
        Exposure.AutoExposureMethod = AEM_Manual;
        Exposure.bOverride_AutoExposureApplyPhysicalCameraExposure = true;
        Exposure.AutoExposureApplyPhysicalCameraExposure = false;
        Exposure.bOverride_AutoExposureBias = true;
        Exposure.AutoExposureBias = 0.0f;
        Exposure.bOverride_AutoExposureMinBrightness = true;
        Exposure.AutoExposureMinBrightness = 1.0f;
        Exposure.bOverride_AutoExposureMaxBrightness = true;
        Exposure.AutoExposureMaxBrightness = 1.0f;
        Component->PostProcessBlendWeight = 1.0f;
        Camera->SetActorLocation(FVector(0, -220, 260));
        Camera->SetActorRotation((FVector::ZeroVector - Camera->GetActorLocation()).Rotation());
    }
    else { SceneError = TEXT("Could not create the board camera."); }
    if (Light.IsValid())
    {
        Light->SetFlags(RF_Transient);
        Light->SetActorRotation(FRotator(-55, -35, 0));
        UDirectionalLightComponent* Component = Cast<UDirectionalLightComponent>(Light->GetLightComponent());
        if (Component) { Component->SetIntensity(6.0f); Component->SetCastShadows(false); }
    }
    const TWeakObjectPtr<AWarhammerClientGameMode> WeakOwner = Owner;
    Session->OnChanged.BindLambda([WeakOwner]()
    {
        if (WeakOwner.IsValid())
        {
            // The session client delivers state changes on the game thread.
            AWarhammerClientGameMode* GameMode = WeakOwner.Get();
            if (GameMode->Scene) { GameMode->Scene->Changed(); }
        }
    });
}

void FLiveCoreScene::Attach()
{
    if (bAttached || !Viewport() || !World()->GetFirstPlayerController()) { return; }
    APlayerController* Controller = World()->GetFirstPlayerController();
    Controller->bShowMouseCursor = true;
    Controller->SetIgnoreMoveInput(true);
    Controller->SetIgnoreLookInput(true);
    if (Camera.IsValid()) { Controller->SetViewTarget(Camera.Get()); }
    Panel = SNew(SLiveCorePanel, this);
    CameraSurface = SNew(SLiveCoreCameraSurface, this);
    Overlay = SNew(SHorizontalBox)
        + SHorizontalBox::Slot().AutoWidth()[SNew(SBox).WidthOverride(410)[Panel.ToSharedRef()]]
        + SHorizontalBox::Slot().FillWidth(1)[CameraSurface.ToSharedRef()];
    Viewport()->AddViewportWidgetContent(Overlay.ToSharedRef(), 10);
    FInputModeUIOnly Input;
    Input.SetWidgetToFocus(Panel);
    Controller->SetInputMode(Input);
    const TWeakPtr<SLiveCoreCameraSurface> WeakSurface = CameraSurface;
    ActivationHandle = FSlateApplication::Get().OnApplicationActivationStateChanged().AddLambda([WeakSurface](bool bActive)
    { if (const auto Surface = WeakSurface.Pin()) { Surface->ApplicationActive(bActive); } });
    bAttached = true;
}

void FLiveCoreScene::Changed()
{
    if (Panel.IsValid()) { Panel->RefreshOptions(); }
    const auto& State = Session->GetState();
    if (State.bHasSession && State.ProjectionVersion > 0 && (RenderedSession != State.SessionId || RenderedProjectionVersion != State.ProjectionVersion))
    {
        RebuildBoard();
    }
}

void FLiveCoreScene::RebuildBoard()
{
    const auto& State = Session->GetState();
    if (!State.BoardBoundsInches.bIsValid) { return; }
    ClearBoard();
    const FVector2D Centre = State.BoardBoundsInches.GetCenter();
    const FVector2D Size = State.BoardBoundsInches.GetSize();
    Box(FVector(0, 0, -1), FVector(Size.X * CmPerInch, Size.Y * CmPerInch, 2), FLinearColor(0.11f, 0.18f, 0.20f));
    for (const auto& Terrain : State.Terrain)
    {
        for (int32 Index = 0; Index < Terrain.PolygonInches.Num(); ++Index)
        {
            const FVector2D A = Terrain.PolygonInches[Index];
            const FVector2D B = Terrain.PolygonInches[(Index + 1) % Terrain.PolygonInches.Num()];
            const FVector From = DisplayPoint(FVector(A.X, A.Y, 0), Centre);
            const FVector To = DisplayPoint(FVector(B.X, B.Y, 0), Centre);
            const FVector Delta = To - From;
            // Thin raised outlines preserve the real polygon boundary; their thickness is cosmetic.
            Box((From + To) * 0.5 + FVector(0, 0, 0.6), FVector(Delta.Size(), 0.8, 1.2),
                FLinearColor(0.45f, 0.53f, 0.60f), Delta.Rotation());
        }
    }
    for (const auto& Objective : State.Objectives)
    {
        Disc(DisplayPoint(Objective.PositionInches, Centre) + FVector(0, 0, 0.35),
            Objective.RadiusInches, 0.7, FLinearColor(0.95f, 0.68f, 0.12f));
    }
    for (const auto& Model : State.Models)
    {
        Disc(DisplayPoint(Model.PositionInches, Centre) + FVector(0, 0, 0.7),
            Model.RadiusInches, 1.4, FLinearColor(0.20f, 0.65f, 0.90f));
    }
    FBox DisplayBounds(FVector(-Size.X * CmPerInch * 0.5, -Size.Y * CmPerInch * 0.5, -2),
        FVector(Size.X * CmPerInch * 0.5, Size.Y * CmPerInch * 0.5, 2));
    for (const auto& Actor : BoardActors) { if (Actor.IsValid()) { DisplayBounds += Actor->GetComponentsBoundingBox(true); } }
    CameraNavigation.SetBounds(DisplayBounds);
    UpdateCamera();
    RenderedSession = State.SessionId;
    RenderedProjectionVersion = State.ProjectionVersion;
}

void FLiveCoreScene::Shutdown()
{
    Session->OnChanged.Unbind();
    Session->Shutdown();
    if (FSlateApplication::IsInitialized()) { FSlateApplication::Get().OnApplicationActivationStateChanged().Remove(ActivationHandle); }
    if (CameraSurface.IsValid()) { CameraSurface->Detach(); }
    if (Panel.IsValid()) { Panel->Detach(); }
    if (Overlay.IsValid() && Viewport()) { Viewport()->RemoveViewportWidgetContent(Overlay.ToSharedRef()); }
    Overlay.Reset();
    Panel.Reset();
    CameraSurface.Reset();
    ClearBoard();
    if (Camera.IsValid()) { Camera->Destroy(); }
    if (Light.IsValid()) { Light->Destroy(); }
}

void FLiveCoreScene::UpdateCameraLayout(const FGeometry& G)
{
    if (!Viewport() || !Viewport()->Viewport || !Camera.IsValid() || !World()->GetFirstPlayerController()) { return; }
    const auto ViewportWidget = Viewport()->GetGameViewportWidget();
    if (!ViewportWidget.IsValid()) { return; }
    const FGeometry& Root = ViewportWidget->GetCachedGeometry();
    const FVector2D Logical = Root.GetLocalSize();
    const FIntPoint Pixels = Viewport()->Viewport->GetSizeXY();
    if (Logical.X <= 0 || Logical.Y <= 0 || Pixels.X <= 0 || Pixels.Y <= 0) { return; }
    const FVector2D Scale(Pixels.X / Logical.X, Pixels.Y / Logical.Y);
    const FVector2D Min = Root.AbsoluteToLocal(G.LocalToAbsolute(FVector2D(0, CameraHelpHeight)));
    const FVector2D Max = Root.AbsoluteToLocal(G.LocalToAbsolute(G.GetLocalSize()));
    FSceneViewProjectionData Data;
    ULocalPlayer* Player = World()->GetFirstPlayerController()->GetLocalPlayer();
    if (!Player || !Player->GetProjectionData(Viewport()->Viewport, Data) || !Data.IsValidViewRectangle()) { return; }
    if (!Data.IsPerspectiveProjection() || Data.GetConstrainedViewRect().Min != FIntPoint::ZeroValue || Data.GetConstrainedViewRect().Size() != Pixels)
    { CameraError = TEXT("Camera: a full single-player perspective viewport is required."); return; }
    Warhammer::LiveCore::FCameraLayout Layout;
    Layout.ViewportPixels = FVector2D(Pixels); Layout.PixelsPerLogicalUnit = Scale.Y;
    Layout.SurfacePixels = FBox2D(Min * Scale, Max * Scale);
    Layout.NearClipCm = Data.GetNearPlaneFromProjectionMatrix();
    const auto& Previous = CameraNavigation.GetLayout();
    if (CameraSurface.IsValid() && (!Previous.ViewportPixels.Equals(Layout.ViewportPixels, 0.1) ||
        !Previous.SurfacePixels.Min.Equals(Layout.SurfacePixels.Min, 0.1) || !Previous.SurfacePixels.Max.Equals(Layout.SurfacePixels.Max, 0.1) ||
        !FMath::IsNearlyEqual(Previous.PixelsPerLogicalUnit, Layout.PixelsPerLogicalUnit, 1.e-6)))
    { CameraSurface->Cancel(false); }
    CameraNavigation.SetLayout(Layout);
    CameraError = CameraNavigation.GetError(); UpdateCamera();
}

void FLiveCoreScene::UpdateCamera()
{
    if (Camera.IsValid() && CameraNavigation.IsReady())
    { Camera->SetActorLocationAndRotation(CameraNavigation.GetLocation(), CameraNavigation.GetRotation()); }
}

void FLiveCoreScene::FrameBoard()
{
    if (CameraNavigation.FrameBoard()) { UpdateCamera(); }
    CameraError = CameraNavigation.GetError();
}

#if WITH_DEV_AUTOMATION_TESTS && WITH_E02_AUTOMATION_DRIVER
bool AWarhammerClientGameMode::BeginCameraInputProofForTests(FString& OutError)
{
    check(IsInGameThread());
    FString SuppliedCoreUrl, TestExit;
    if (!FParse::Param(FCommandLine::Get(), TEXT("LiveCoreCameraInputProof")) ||
        !FParse::Param(FCommandLine::Get(), TEXT("LiveCoreCameraInputProofOwnedProcess")) ||
        !FParse::Param(FCommandLine::Get(), TEXT("game")) || !FParse::Param(FCommandLine::Get(), TEXT("unattended")) ||
        !FParse::Value(FCommandLine::Get(), TEXT("TestExit="), TestExit) ||
        !TestExit.Equals(TEXT("Automation Test Queue Empty"), ESearchCase::CaseSensitive) ||
        FParse::Value(FCommandLine::Get(), TEXT("CoreUrl="), SuppliedCoreUrl) ||
        !FPlatformMisc::GetEnvironmentVariable(TEXT("WH_CORE_ADMIN_TOKEN")).IsEmpty() ||
        !FPlatformMisc::GetEnvironmentVariable(TEXT("WH_CORE_PLAYER_TOKEN")).IsEmpty())
    { OutError = TEXT("Camera input proof requires both dedicated-process opt-ins, -game -unattended, exact TestExit, no CoreUrl and no Core credentials."); return false; }
    if (!Scene || !Scene->bAttached || !Scene->Camera.IsValid() || !Scene->CameraSurface.IsValid() ||
        !Scene->Panel.IsValid() || Scene->NavigationBeforeInputProof.IsSet())
    { OutError = TEXT("Live camera surface is unavailable or already owned by an input proof."); return false; }
    const auto& State = Scene->Session->GetState();
    if (State.bHasSession || State.bBusy || State.bUnknown || !State.SessionId.IsEmpty() ||
        !State.RequestId.IsEmpty() || State.AcceptedActionCount != 0)
    { OutError = TEXT("Camera input proof refuses a real, busy or uncertain Core session."); return false; }
    FLiveCoreCameraInputObservation Input;
    Scene->CameraSurface->ObserveInputProof(Input);
    if (Input.bPolicyCapture || Input.bSlateCapture)
    { OutError = TEXT("Camera input proof refuses pre-existing camera capture."); return false; }
    const auto Endpoint = Scene->Panel->EndpointForInputProof().Pin();
    if (!Endpoint.IsValid()) { OutError = TEXT("Endpoint widget is unavailable."); return false; }
    Scene->NavigationBeforeInputProof = Scene->CameraNavigation;
    Scene->CameraBeforeInputProof = Scene->Camera->GetActorTransform();
    Scene->EndpointBeforeInputProof = Endpoint->GetText();
    Scene->CameraErrorBeforeInputProof = Scene->CameraError;
    Scene->CameraSurface->BeginInputProof();
    // Synthetic/advisory presentation bounds only. No Session/DTO/command is created.
    if (!Scene->CameraNavigation.SetBounds(FBox(FVector(-90, -60, -2), FVector(90, 60, 2))) ||
        !Scene->CameraNavigation.IsReady())
    { OutError = TEXT("Synthetic camera layout is not ready."); EndCameraInputProofForTests(); return false; }
    Scene->UpdateCamera(); OutError.Reset(); return true;
}

void AWarhammerClientGameMode::EndCameraInputProofForTests()
{
    check(IsInGameThread());
    if (!Scene || !Scene->NavigationBeforeInputProof.IsSet()) { return; }
    if (Scene->CameraSurface.IsValid()) { Scene->CameraSurface->EndInputProof(); }
    if (Scene->Panel.IsValid())
    {
        if (const auto Endpoint = Scene->Panel->EndpointForInputProof().Pin())
        { Endpoint->SetText(Scene->EndpointBeforeInputProof); }
    }
    Scene->CameraNavigation = Scene->NavigationBeforeInputProof.GetValue();
    Scene->NavigationBeforeInputProof.Reset();
    if (Scene->Camera.IsValid()) { Scene->Camera->SetActorTransform(Scene->CameraBeforeInputProof); }
    Scene->CameraError = Scene->CameraErrorBeforeInputProof;
}

bool AWarhammerClientGameMode::ObserveCameraInputProofForTests(FLiveCoreCameraInputObservation& Out) const
{
    check(IsInGameThread());
    if (!Scene || !Scene->bAttached || !Scene->Camera.IsValid() || !Scene->CameraSurface.IsValid() || !Scene->Panel.IsValid())
    { return false; }
    Out = FLiveCoreCameraInputObservation();
    Out.Surface = Scene->CameraSurface; Out.Endpoint = Scene->Panel->EndpointForInputProof();
    Out.Viewport = Scene->Viewport() ? Scene->Viewport()->GetGameViewportWidget() : TSharedPtr<SViewport>();
    Out.ActorLocation = Scene->Camera->GetActorLocation(); Out.ActorRotation = Scene->Camera->GetActorRotation();
    const auto* Controller = Scene->World()->GetFirstPlayerController();
    Out.bViewTarget = Controller && Controller->GetViewTarget() == Scene->Camera.Get();
    if (const auto Endpoint = Scene->Panel->EndpointForInputProof().Pin())
    { Out.bEndpointFocused = Endpoint->HasKeyboardFocus(); Out.EndpointText = Endpoint->GetText().ToString(); }
    Out.CameraError = Scene->CameraError;
    Out.Focus = Scene->CameraNavigation.GetFocus(); Out.Distance = Scene->CameraNavigation.GetDistance();
    Out.MinimumDistance = Scene->CameraNavigation.GetMinimumDistance();
    Out.MaximumDistance = Scene->CameraNavigation.GetMaximumDistance();
    Out.Azimuth = Scene->CameraNavigation.GetAzimuth(); Out.Elevation = Scene->CameraNavigation.GetElevation();
    const auto& Layout = Scene->CameraNavigation.GetLayout();
    Out.LayoutViewportPixels = Layout.ViewportPixels;
    Out.LayoutSurfaceMin = Layout.SurfacePixels.Min; Out.LayoutSurfaceMax = Layout.SurfacePixels.Max;
    Out.bReady = Scene->CameraNavigation.IsReady(); Scene->CameraSurface->ObserveInputProof(Out);
    const auto& State = Scene->Session->GetState();
    Out.bBusy = State.bBusy; Out.bHasSession = State.bHasSession; Out.bUnknown = State.bUnknown;
    Out.bHasCommandOutcome = State.bLastCommandHasOutcome; Out.bCommandAccepted = State.bLastCommandAccepted;
    Out.bCommandCommitted = State.bLastCommandCommitted; Out.LastHttpStatus = State.LastHttpStatus;
    Out.SessionId = State.SessionId; Out.RequestId = State.RequestId;
    Out.RequestType = State.RequestType;
    for (const auto& Option : State.Options)
    {
        FLiveCoreCameraChoiceObservation Choice;
        Choice.Id = Option.Id; Choice.Label = Option.Label; Choice.bAvailable = Option.bAvailable;
        Out.Options.Add(MoveTemp(Choice));
    }
    Out.SessionStatus = State.Status; Out.SessionError = State.Error; Out.LastOutcomeCode = State.LastOutcomeCode;
    Out.SessionRevision = State.SessionRevision; Out.ProjectionRevision = State.ProjectionRevision;
    Out.ProjectionVersion = State.ProjectionVersion; Out.AcceptedActionCount = State.AcceptedActionCount;
    return true;
}
#endif

AWarhammerClientGameMode::AWarhammerClientGameMode()
{
    PrimaryActorTick.bCanEverTick = true;
    DefaultPawnClass = nullptr;
    HUDClass = nullptr;
}

AWarhammerClientGameMode::AWarhammerClientGameMode(FVTableHelper& Helper) : Super(Helper) {}
AWarhammerClientGameMode::~AWarhammerClientGameMode() = default;

void AWarhammerClientGameMode::BeginPlay()
{
    Super::BeginPlay();
    Scene = MakeUnique<FLiveCoreScene>(this);
    Scene->Initialize();
}

void AWarhammerClientGameMode::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);
    if (Scene)
    {
        Scene->Attach();
    }
}

void AWarhammerClientGameMode::EndPlay(const EEndPlayReason::Type EndPlayReason)
{
    if (Scene) { Scene->Shutdown(); Scene.Reset(); }
    Super::EndPlay(EndPlayReason);
}
