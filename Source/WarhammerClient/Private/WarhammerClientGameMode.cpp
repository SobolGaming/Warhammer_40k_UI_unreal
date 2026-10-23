#include "WarhammerClientGameMode.h"

#include "LiveCore/LiveCoreSession.h"
#include "Camera/CameraActor.h"
#include "Camera/CameraComponent.h"
#include "Components/DirectionalLightComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/DirectionalLight.h"
#include "Engine/GameViewportClient.h"
#include "Engine/StaticMesh.h"
#include "Engine/World.h"
#include "GameFramework/PlayerController.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "Materials/MaterialInterface.h"
#include "Misc/CommandLine.h"
#include "Misc/Parse.h"
#include "Styling/CoreStyle.h"
#include "UObject/StrongObjectPtr.h"
#include "Widgets/Input/SButton.h"
#include "Widgets/Input/SEditableTextBox.h"
#include "Widgets/Layout/SBorder.h"
#include "Widgets/Layout/SBox.h"
#include "Widgets/Layout/SScrollBox.h"
#include "Widgets/SBoxPanel.h"
#include "Widgets/SCompoundWidget.h"
#include "Widgets/SOverlay.h"
#include "Widgets/Text/STextBlock.h"

namespace
{
constexpr double CmPerInch = 2.54;

// Display transform only: Core inches, +Y up-table -> Unreal centimetres, -Y.
FVector DisplayPoint(const FVector& Inches, const FVector2D& Centre)
{
    return FVector((Inches.X - Centre.X) * CmPerInch,
        -(Inches.Y - Centre.Y) * CmPerInch, Inches.Z * CmPerInch);
}
}

class SLiveCorePanel;

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
    TSharedPtr<SWidget> Overlay;
    TWeakObjectPtr<ACameraActor> Camera;
    TWeakObjectPtr<ADirectionalLight> Light;
    TStrongObjectPtr<UStaticMesh> Cube;
    TStrongObjectPtr<UStaticMesh> Cylinder;
    TStrongObjectPtr<UMaterialInterface> Material;
    TArray<TWeakObjectPtr<AActor>> BoardActors;
    FString Endpoint = TEXT("http://127.0.0.1:8765");
    FString SceneError;
    FString RenderedSession;
    int64 RenderedRevision = -1;
    bool bAttached = false;

    UWorld* World() const { return Owner.IsValid() ? Owner->GetWorld() : nullptr; }
    UGameViewportClient* Viewport() const { return World() ? World()->GetGameViewport() : nullptr; }
    void Initialize();
    void Attach();
    void Changed();
    void RebuildBoard();
    void Shutdown();

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
                    TEXT("Start the checked-out Core development server, then create a session. No game state is invented locally.")))]
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
                        Scene->Session->InitializeEndpoint(Scene->Endpoint);
                        Scene->Session->NewSession();
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
                            (Scene->SceneError.IsEmpty() ? FString() : TEXT("\n") + Scene->SceneError));
                    })]
                + SVerticalBox::Slot().AutoHeight().Padding(0, 0, 0, 8)
                [SNew(STextBlock).AutoWrapText(true).Text_Lambda([this]()
                    {
                        const auto& Value = State();
                        if (!Value.bHasSession) { return FText::FromString(TEXT("Awaiting authoritative session state.")); }
                        return FText::FromString(FString::Printf(TEXT("Session: %s\nRevision: %lld\nPhase: %s\nViewer: %s\nAccepted actions: %d\nLast HTTP: %d"),
                            *Value.SessionId, static_cast<long long>(Value.SessionRevision), *Value.Phase, *Value.ViewerPlayerId,
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
                        return FText::FromString(State().RequestId.IsEmpty()
                            ? TEXT("No decision is visible to this viewer.")
                            : State().RequestType + TEXT("\n") + State().RequestId);
                    })]
                + SVerticalBox::Slot().AutoHeight()
                [SAssignNew(Options, SVerticalBox)]
                + SVerticalBox::Slot().AutoHeight().Padding(0, 12, 0, 0)
                [SNew(STextBlock).AutoWrapText(true).Text(FText::FromString(
                    TEXT("Terrain outlines and token appearance are advisory. Unplaced models are not drawn. Camera is fixed; UI clicks submit only the selected Core option.")))
                    .ColorAndOpacity(FLinearColor(0.65f, 0.72f, 0.8f))]
                ]
            ]
        ];
        RefreshOptions();
    }

    void RefreshOptions()
    {
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
                [SNew(STextBlock).AutoWrapText(true).Text(FText::FromString(Option.Label))]];
        }
    }

    void Detach()
    {
        // Slate can retain this widget after it leaves the viewport (for example, focus).
        // Its callbacks must outlive the scene without retaining or dereferencing it.
        Scene = nullptr;
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
    TSharedPtr<SVerticalBox> Options;
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
    Overlay = SNew(SOverlay)
        + SOverlay::Slot().HAlign(HAlign_Left).VAlign(VAlign_Fill)
        [SNew(SBox).WidthOverride(410)[Panel.ToSharedRef()]];
    Viewport()->AddViewportWidgetContent(Overlay.ToSharedRef(), 10);
    FInputModeUIOnly Input;
    Input.SetWidgetToFocus(Panel);
    Controller->SetInputMode(Input);
    bAttached = true;
}

void FLiveCoreScene::Changed()
{
    if (Panel.IsValid()) { Panel->RefreshOptions(); }
    const auto& State = Session->GetState();
    if (State.bHasSession && (RenderedSession != State.SessionId || RenderedRevision != State.SessionRevision))
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
    if (Camera.IsValid())
    {
        const double Span = FMath::Max(Size.X, Size.Y) * CmPerInch;
        // The camera looks up +Y, so a +X aim offset leaves the board beside the left UI.
        const FVector Target(Span * 0.15, 0, 0);
        Camera->SetActorLocation(Target + FVector(0, -Span * 0.78, Span * 0.90));
        Camera->SetActorRotation((Target - Camera->GetActorLocation()).Rotation());
    }
    RenderedSession = State.SessionId;
    RenderedRevision = State.SessionRevision;
}

void FLiveCoreScene::Shutdown()
{
    Session->OnChanged.Unbind();
    Session->Shutdown();
    if (Panel.IsValid()) { Panel->Detach(); }
    if (Overlay.IsValid() && Viewport()) { Viewport()->RemoveViewportWidgetContent(Overlay.ToSharedRef()); }
    Overlay.Reset();
    Panel.Reset();
    ClearBoard();
    if (Camera.IsValid()) { Camera->Destroy(); }
    if (Light.IsValid()) { Light->Destroy(); }
}

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
