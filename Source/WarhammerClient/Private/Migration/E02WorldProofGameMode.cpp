#include "Migration/E02WorldProofGameMode.h"

#include "Camera/CameraActor.h"
#include "Camera/CameraComponent.h"
#include "Components/DirectionalLightComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Dom/JsonObject.h"
#include "DynamicRHI.h"
#include "Engine/DirectionalLight.h"
#include "Engine/GameViewportClient.h"
#include "Engine/LocalPlayer.h"
#include "Engine/StaticMesh.h"
#include "Engine/World.h"
#include "Framework/Application/SlateApplication.h"
#include "HAL/FileManager.h"
#include "HAL/PlatformMisc.h"
#include "Input/Events.h"
#include "Input/Reply.h"
#include "InputCoreTypes.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "Materials/MaterialInterface.h"
#include "Misc/CommandLine.h"
#include "Misc/FileHelper.h"
#include "Misc/Parse.h"
#include "Misc/Paths.h"
#include "ProceduralMeshComponent.h"
#include "Rendering/DrawElementTypes.h"
#include "RHI.h"
#include "RHIStrings.h"
#include "SceneView.h"
#include "Serialization/JsonSerializer.h"
#include "Serialization/JsonWriter.h"
#include "Styling/CoreStyle.h"
#include "Types/PaintArgs.h"
#include "UnrealClient.h"
#include "Widgets/SLeafWidget.h"
#include "Widgets/SViewport.h"
#include "Widgets/SWindow.h"

using namespace Warhammer::Migration::E02;

namespace
{
TArray<TSharedPtr<FJsonValue>> VectorJson(const FVector3d& V)
{
    return {MakeShared<FJsonValueNumber>(V.X), MakeShared<FJsonValueNumber>(V.Y),
        MakeShared<FJsonValueNumber>(V.Z)};
}
TArray<TSharedPtr<FJsonValue>> PointJson(const FVector2d& V)
{
    return {MakeShared<FJsonValueNumber>(V.X), MakeShared<FJsonValueNumber>(V.Y)};
}
TArray<TSharedPtr<FJsonValue>> RectJson(const FVector4d& R)
{
    return {MakeShared<FJsonValueNumber>(R.X), MakeShared<FJsonValueNumber>(R.Y),
        MakeShared<FJsonValueNumber>(R.Z), MakeShared<FJsonValueNumber>(R.W)};
}
bool AnalyticLocalBounds(const FFootprint& M, double Thickness, FVector3d& Min, FVector3d& Max)
{
    FDiagnostic Diagnostic;
    if (!ValidateFootprint(M, Diagnostic)) { return false; }
    FVector2d XYMin, XYMax;
    if (M.Kind == EShapeKind::Polygon)
    {
        XYMin = XYMax = M.VerticesInches[0];
        for (const FVector2d& V : M.VerticesInches)
        { XYMin.X = FMath::Min(XYMin.X, V.X); XYMin.Y = FMath::Min(XYMin.Y, V.Y); XYMax.X = FMath::Max(XYMax.X, V.X); XYMax.Y = FMath::Max(XYMax.Y, V.Y); }
    }
    else
    {
        const double X = M.Kind == EShapeKind::Circle ? M.RadiusInches.GetValue() : M.LengthInches.GetValue() * 0.5;
        const double Y = M.Kind == EShapeKind::Circle ? X : M.WidthInches.GetValue() * 0.5;
        XYMin = FVector2d(-X, -Y); XYMax = FVector2d(X, Y);
    }
    Min = FVector3d(XYMin.X, XYMin.Y, 0);
    Max = FVector3d(XYMax.X, XYMax.Y, FMath::Max(M.QueryHeightInches, Thickness));
    return true;
}
FVector3d PoseBoundsPoint(const FDomainPose& Pose, const FVector3d& Local)
{
    const double A = FMath::DegreesToRadians(Pose.FacingDegrees), C = FMath::Cos(A), S = FMath::Sin(A);
    return Pose.PositionInches + FVector3d(C * Local.X - S * Local.Y, S * Local.X + C * Local.Y, Local.Z);
}
FString JsonText(const TSharedPtr<FJsonObject>& Object)
{
    FString Text;
    const TSharedRef<TJsonWriter<>> Writer = TJsonWriterFactory<>::Create(&Text);
    return FJsonSerializer::Serialize(Object.ToSharedRef(), Writer) ? Text : FString();
}
FString CompactJson(const TSharedPtr<FJsonObject>& Object)
{
    FString Text;
    const auto Writer = TJsonWriterFactory<TCHAR, TCondensedJsonPrintPolicy<TCHAR>>::Create(&Text);
    return FJsonSerializer::Serialize(Object.ToSharedRef(), Writer) ? Text : FString();
}
bool Inside(const FVector2d& P, double X0, double Y0, double X1, double Y1)
{
    return P.X >= X0 && P.X < X1 && P.Y >= Y0 && P.Y < Y1;
}
const TCHAR* ProofLabel = TEXT("SYNTHETIC / ADVISORY — NO GAME SESSION");
}

class SE02ProofSurface;

struct FE02ProofState
{
    TWeakObjectPtr<AE02WorldProofGameMode> Owner;
    FFixture Fixture;
    FInputPolicy Policy;
    TSharedPtr<SE02ProofSurface> Surface;
    TWeakObjectPtr<ACameraActor> Camera;
    TWeakObjectPtr<ADirectionalLight> Light;
    TWeakObjectPtr<APlayerController> Controller;
    TWeakObjectPtr<UStaticMesh> CubeAsset;
    TWeakObjectPtr<UMaterialInterface> BaseMaterial;
    TMap<FString, TWeakObjectPtr<UProceduralMeshComponent>> ModelMeshes;
    TMap<FString, TWeakObjectPtr<UStaticMeshComponent>> ReplacementMeshes;
    FString FixturePath, Artifacts, Error, CaseName, Status = TEXT("Local advisory proof; select a footprint");
    FString EditedText = TEXT("local proof text");
    FVector3d CameraTarget;
    double Azimuth = 0.0, Elevation = 45.0, Distance = 320.0;
    double OriginalApplicationScale = 1.0;
    bool bReady = false, bSceneBuilt = false, bEnding = false, bInitialSceneWritten = false, bInjectingActivation = false;
    uint64 Events = 0, Picks = 0, CameraChanges = 0;
    FPointerSample LastPickPointer;
    Warhammer::Migration::E02::FRay LastPickRay;
    TOptional<FAdvisoryHit> LastPickHit;
    TSharedPtr<FJsonObject> LastKeyEvent;
    uint64 LastPickGeneration = 0, LastPickEventSequence = 0;
    FVector4d PaintedHudScreen = FVector4d(0, 0, 0, 0), PaintedHeaderScreen = FVector4d(0, 0, 0, 0);
    FIntPoint PaintedExtent = FIntPoint::ZeroValue;
    double PaintedScale = 0;
    uint64 PaintGeneration = 0, FrameGeneration = 0, FramePaintGeneration = 0, FrameEventSequence = 0;
    bool bPaintAxisAligned = false;
    FString FrameKind;
    FIntPoint LastExtent = FIntPoint::ZeroValue;
    double LastScale = 0.0;
    FDelegateHandle ActivationHandle, ScreenshotHandle;
    FString PendingScreenshot;
    TSet<FString> CompletedScreenshots;
    TArray<TSharedPtr<FJsonValue>> ScreenshotRecords;

    bool FrameBounds(bool bSelection); // Defined after the complete Slate surface type.
    void RecordPaint(const FGeometry& G, FVector2D HeaderSize, FVector2D HudPosition, FVector2D HudSize)
    {
        bPaintAxisAligned = true;
        auto ObserveRect = [&](FVector2D Position, FVector2D Size)
        {
            const FVector2D TL = G.LocalToAbsolute(Position), TR = G.LocalToAbsolute(Position + FVector2D(Size.X, 0));
            const FVector2D BL = G.LocalToAbsolute(Position + FVector2D(0, Size.Y)), BR = G.LocalToAbsolute(Position + Size);
            bPaintAxisAligned &= FMath::Abs(TR.Y - TL.Y) <= 1e-3 && FMath::Abs(BL.X - TL.X) <= 1e-3 &&
                FMath::Abs(BR.X - TR.X) <= 1e-3 && FMath::Abs(BR.Y - BL.Y) <= 1e-3 && TR.X > TL.X && BL.Y > TL.Y;
            return FVector4d(TL.X, TL.Y, BR.X, BR.Y);
        };
        PaintedHeaderScreen = ObserveRect(FVector2D::ZeroVector, HeaderSize);
        PaintedHudScreen = ObserveRect(HudPosition, HudSize);
        PaintedExtent = Extent(); PaintedScale = FSlateApplication::Get().GetApplicationScale(); ++PaintGeneration;
    }

    void Fail(const FString& Message)
    {
        if (Error.IsEmpty())
        {
            Error = Message;
            Status = Message;
            UE_LOG(LogTemp, Error, TEXT("E02 proof: %s"), *Message);
        }
        bReady = false;
    }
    UGameViewportClient* ViewportClient() const
    {
        return Owner.IsValid() && Owner->GetWorld() ? Owner->GetWorld()->GetGameViewport() : nullptr;
    }
    FIntPoint Extent() const
    {
        const UGameViewportClient* Client = ViewportClient();
        return Client && Client->Viewport ? Client->Viewport->GetSizeXY() : FIntPoint::ZeroValue;
    }
    bool ViewportGeometry(FGeometry& Geometry) const
    {
        const UGameViewportClient* Client = ViewportClient();
        const TSharedPtr<SViewport> Widget = Client ? Client->GetGameViewportWidget() : nullptr;
        if (!Widget.IsValid()) { return false; }
        Geometry = Widget->GetCachedGeometry();
        return Geometry.GetLocalSize().X > 0.0 && Geometry.GetLocalSize().Y > 0.0;
    }
    FPointerSample Sample(const FGeometry& SurfaceGeometry, const FVector2D& Absolute) const
    {
        FPointerSample Result;
        Result.ScreenPhysical = Absolute;
        Result.Logical = SurfaceGeometry.AbsoluteToLocal(Absolute);
        FGeometry Geometry;
        const FIntPoint Size = Extent();
        if (ViewportGeometry(Geometry) && Size.X > 0 && Size.Y > 0)
        {
            const FVector2D Local = Geometry.AbsoluteToLocal(Absolute);
            const FVector2D LogicalSize = Geometry.GetLocalSize();
            Result.ViewportPhysical = FVector2d(Local.X * Size.X / LogicalSize.X,
                Local.Y * Size.Y / LogicalSize.Y);
            Result.bInsideViewport = Inside(Result.ViewportPhysical, 0, 0, Size.X, Size.Y);
        }
        return Result;
    }
    bool AbsoluteFromPixels(const FVector2D& Pixel, FVector2D& Absolute) const
    {
        FGeometry Geometry;
        const FIntPoint Size = Extent();
        if (!ViewportGeometry(Geometry) || Size.X <= 0 || Size.Y <= 0) { return false; }
        Absolute = Geometry.LocalToAbsolute(FVector2D(Pixel.X / Size.X * Geometry.GetLocalSize().X,
            Pixel.Y / Size.Y * Geometry.GetLocalSize().Y));
        return true;
    }
    FHitTarget HitTarget(const FVector2d& Logical, const FVector2d& LogicalSize) const
    {
        const FInputSnapshot& Input = Policy.Snapshot();
        if (Input.bModalOpen)
        {
            const FVector2d Origin = (LogicalSize - Fixture.Presentation.ModalSizeLogical) * 0.5;
            if (Inside(Logical, Origin.X + 20, Origin.Y + 65,
                Origin.X + Fixture.Presentation.ModalSizeLogical.X - 20, Origin.Y + 105))
            { return {EInputOwner::Text, TEXT("modal-text"), true}; }
            return {EInputOwner::Modal, TEXT("modal"), true};
        }
        if (Logical.Y < Fixture.Presentation.HeaderHeightLogical)
        { return {EInputOwner::HudBackground, TEXT("header"), true}; }
        const FBounds2d& H = Fixture.Presentation.HudBoundsLogical;
        if (Inside(Logical, H.Min.X, H.Min.Y, H.Max.X, H.Max.Y))
        {
            if (Inside(Logical, 30, 96, 230, 132))
            { return {EInputOwner::HudButton, TEXT("button"), true}; }
            if (Inside(Logical, 30, 144, 230, 180))
            { return {EInputOwner::HudDisabled, TEXT("disabled"), false}; }
            if (Inside(Logical, 30, 240, 230, 304))
            { return {EInputOwner::HudScroll, TEXT("scroll"), true}; }
            if (Inside(Logical, 30, 316, 230, 352))
            { return {EInputOwner::Text, TEXT("text"), true}; }
            if (Inside(Logical, 30, 364, 230, 400))
            { return {EInputOwner::HudButton, TEXT("open-modal"), true}; }
            return {EInputOwner::HudBackground, TEXT("blank"), true};
        }
        return {EInputOwner::WorldSelection, TEXT("world"), true};
    }
    const FFootprint* Model(const FString& Id) const
    {
        return Fixture.Models.FindByPredicate([&Id](const FFootprint& M) { return M.Id == Id; });
    }
    bool HardwareIdentityReady() const
    {
        return GDynamicRHI && !GUsingNullRHI && GRHIVendorId != 0 && GRHIVendorId != 0x1414 && GRHIDeviceId != 0 &&
            !GRHIAdapterName.IsEmpty() && !GRHIAdapterInternalDriverVersion.IsEmpty() && !GRHIAdapterUserDriverVersion.IsEmpty() &&
            !GRHIAdapterInternalDriverVersion.Contains(TEXT("Unknown")) && !GRHIAdapterUserDriverVersion.Contains(TEXT("Unknown")) &&
            !GRHIAdapterName.Contains(TEXT("WARP")) && !GRHIAdapterName.Contains(TEXT("Software")) && !GRHIAdapterName.Contains(TEXT("Basic Render"));
    }
    TSharedPtr<FJsonObject> CameraJson() const
    {
        const auto Result = MakeShared<FJsonObject>();
        Result->SetArrayField(TEXT("targetDomainInches"), VectorJson(CameraTarget));
        Result->SetNumberField(TEXT("azimuthDegrees"), Azimuth);
        Result->SetNumberField(TEXT("elevationDegrees"), Elevation);
        Result->SetNumberField(TEXT("distanceCm"), Distance);
        Result->SetNumberField(TEXT("fovDegrees"), Fixture.Camera.FovDegrees);
        Result->SetNumberField(TEXT("frameGeneration"), static_cast<double>(FrameGeneration));
        Result->SetNumberField(TEXT("framePaintGeneration"), static_cast<double>(FramePaintGeneration));
        Result->SetNumberField(TEXT("frameEventSequence"), static_cast<double>(FrameEventSequence));
        Result->SetStringField(TEXT("frameKind"), FrameKind);
        if (Camera.IsValid())
        {
            Result->SetArrayField(TEXT("positionWorldCm"), VectorJson(Camera->GetActorLocation()));
            const FRotator Rotation = Camera->GetActorRotation();
            Result->SetArrayField(TEXT("rotationDegrees"), VectorJson(FVector3d(Rotation.Pitch, Rotation.Yaw, Rotation.Roll)));
        }
        if (Controller.IsValid() && Controller->GetLocalPlayer() && ViewportClient() && ViewportClient()->Viewport)
        {
            FSceneViewProjectionData Data;
            if (Controller->GetLocalPlayer()->GetProjectionData(ViewportClient()->Viewport, Data))
            {
                TArray<TSharedPtr<FJsonValue>> Matrix;
                const FMatrix ViewProjection = Data.ComputeViewProjectionMatrix();
                for (int32 Row = 0; Row != 4; ++Row)
                {
                    TArray<TSharedPtr<FJsonValue>> Values;
                    for (int32 Col = 0; Col != 4; ++Col)
                    { Values.Add(MakeShared<FJsonValueNumber>(ViewProjection.M[Row][Col])); }
                    Matrix.Add(MakeShared<FJsonValueArray>(Values));
                }
                Result->SetArrayField(TEXT("viewProjectionMatrix"), Matrix);
                Result->SetArrayField(TEXT("projectionViewOriginWorldCm"), VectorJson(Data.ViewOrigin));
                Result->SetStringField(TEXT("projectionObservation"), TEXT("ULocalPlayer::GetProjectionData at event time; camera cache may update on the next world tick"));
                Result->SetBoolField(TEXT("perspective"), Data.IsPerspectiveProjection());
            }
        }
        return Result;
    }
    TArray<TSharedPtr<FJsonValue>> ActualDisplayGeometry(bool bIncludeGeometry = true) const
    {
        TArray<TSharedPtr<FJsonValue>> Result;
        for (const auto& Pair : ModelMeshes)
        {
            if (!Pair.Value.IsValid()) { continue; }
            const auto ModelRecord = MakeShared<FJsonObject>(); ModelRecord->SetStringField(TEXT("id"), Pair.Key);
            ModelRecord->SetStringField(TEXT("componentTransform"), Pair.Value->GetComponentTransform().ToString());
            ModelRecord->SetNumberField(TEXT("componentTransformDeterminant"), Pair.Value->GetComponentTransform().GetDeterminant());
            ModelRecord->SetBoolField(TEXT("visible"), Pair.Value->IsVisible());
            ModelRecord->SetBoolField(TEXT("collisionEnabled"), Pair.Value->GetCollisionEnabled() != ECollisionEnabled::NoCollision);
            TArray<TSharedPtr<FJsonValue>> Sections;
            for (int32 I = 0; I < Pair.Value->GetNumSections(); ++I)
            {
                const FProcMeshSection* Section = Pair.Value->GetProcMeshSection(I);
                if (!Section) { continue; }
                const auto SectionRecord = MakeShared<FJsonObject>(); SectionRecord->SetNumberField(TEXT("section"), I);
                UMaterialInterface* Material = Pair.Value->GetMaterial(I);
                SectionRecord->SetBoolField(TEXT("materialPresent"), Material != nullptr);
                if (Material)
                {
                    SectionRecord->SetStringField(TEXT("material"), Material->GetPathName());
                    SectionRecord->SetBoolField(TEXT("materialIsTwoSided"), Material->IsTwoSided());
                    SectionRecord->SetBoolField(TEXT("materialOpaque"), Material->GetBlendMode() == BLEND_Opaque);
                }
                else { SectionRecord->SetStringField(TEXT("materialDiagnostic"), TEXT("RequiredMaterialMissing")); }
                if (bIncludeGeometry)
                {
                    TArray<TSharedPtr<FJsonValue>> Vertices, Normals, Indices;
                    for (const FProcMeshVertex& V : Section->ProcVertexBuffer)
                    { Vertices.Add(MakeShared<FJsonValueArray>(VectorJson(V.Position))); Normals.Add(MakeShared<FJsonValueArray>(VectorJson(V.Normal))); }
                    for (uint32 Index : Section->ProcIndexBuffer) { Indices.Add(MakeShared<FJsonValueNumber>(Index)); }
                    SectionRecord->SetArrayField(TEXT("verticesWorldCm"), Vertices); SectionRecord->SetArrayField(TEXT("normalsWorld"), Normals);
                    SectionRecord->SetArrayField(TEXT("indices"), Indices);
                }
                Sections.Add(MakeShared<FJsonValueObject>(SectionRecord));
            }
            ModelRecord->SetArrayField(TEXT("sections"), Sections); Result.Add(MakeShared<FJsonValueObject>(ModelRecord));
        }
        return Result;
    }
    TSharedPtr<FJsonObject> Snapshot() const
    {
        const auto Result = MakeShared<FJsonObject>();
        const auto& Input = Policy.Snapshot();
        Result->SetNumberField(TEXT("schemaVersion"), 1);
        Result->SetStringField(TEXT("label"), ProofLabel);
        Result->SetStringField(TEXT("case"), CaseName);
        Result->SetStringField(TEXT("observedUtc"), FDateTime::UtcNow().ToIso8601());
        Result->SetBoolField(TEXT("ready"), bReady);
        Result->SetStringField(TEXT("error"), Error);
        Result->SetStringField(TEXT("fixturePath"), FixturePath);
        Result->SetStringField(TEXT("rhi"), GDynamicRHI ? GDynamicRHI->GetName() : TEXT("UNAVAILABLE"));
        Result->SetStringField(TEXT("adapter"), GRHIAdapterName);
        Result->SetNumberField(TEXT("vendorId"), GRHIVendorId);
        Result->SetNumberField(TEXT("deviceId"), GRHIDeviceId);
        Result->SetStringField(TEXT("internalDriverVersion"), GRHIAdapterInternalDriverVersion);
        Result->SetStringField(TEXT("userDriverVersion"), GRHIAdapterUserDriverVersion);
        FString FeatureName;
        const ERHIFeatureLevel::Type Feature = Owner.IsValid() && Owner->GetWorld() ? Owner->GetWorld()->GetFeatureLevel() : GMaxRHIFeatureLevel;
        GetFeatureLevelName(Feature, FeatureName);
        Result->SetNumberField(TEXT("featureLevelEnum"), static_cast<int32>(Feature));
        Result->SetStringField(TEXT("featureLevel"), FeatureName);
        Result->SetBoolField(TEXT("nullRhi"), GUsingNullRHI);
        Result->SetBoolField(TEXT("hardwareRhi"), HardwareIdentityReady());
        Result->SetStringField(TEXT("osVersion"), FPlatformMisc::GetOSVersion());
        if (FSlateApplication::IsInitialized())
        {
            FDisplayMetrics Metrics; FSlateApplication::Get().GetInitialDisplayMetrics(Metrics);
            const auto Display = MakeShared<FJsonObject>();
            Display->SetNumberField(TEXT("initialPrimaryWidth"), Metrics.PrimaryDisplayWidth);
            Display->SetNumberField(TEXT("initialPrimaryHeight"), Metrics.PrimaryDisplayHeight);
            Display->SetNumberField(TEXT("initialMonitorCount"), Metrics.MonitorInfo.Num());
            const auto Window = ViewportClient() ? ViewportClient()->GetWindow() : nullptr;
            if (Window.IsValid())
            {
                const FSlateRect Rect = Window->GetClientRectInScreen();
                Display->SetArrayField(TEXT("actualClientRectScreen"), {MakeShared<FJsonValueNumber>(Rect.Left), MakeShared<FJsonValueNumber>(Rect.Top), MakeShared<FJsonValueNumber>(Rect.Right), MakeShared<FJsonValueNumber>(Rect.Bottom)});
                Display->SetNumberField(TEXT("windowDpiScale"), Window->GetDPIScaleFactor());
                Display->SetNumberField(TEXT("windowModeEnum"), static_cast<int32>(Window->GetWindowMode()));
                Display->SetBoolField(TEXT("windowVisible"), Window->IsVisible());
            }
            Result->SetObjectField(TEXT("display"), Display);
        }
        Result->SetBoolField(TEXT("perspective"), Camera.IsValid() && Camera->GetCameraComponent()->ProjectionMode == ECameraProjectionMode::Perspective);
        const auto View = MakeShared<FJsonObject>();
        const FIntPoint Size = Extent();
        View->SetNumberField(TEXT("width"), Size.X); View->SetNumberField(TEXT("height"), Size.Y);
        Result->SetObjectField(TEXT("viewport"), View);
        Result->SetNumberField(TEXT("uiScale"), FSlateApplication::IsInitialized() ? FSlateApplication::Get().GetApplicationScale() : 0.0);
        const auto Paint = MakeShared<FJsonObject>();
        Paint->SetNumberField(TEXT("generation"), static_cast<double>(PaintGeneration));
        Paint->SetNumberField(TEXT("viewportWidth"), PaintedExtent.X); Paint->SetNumberField(TEXT("viewportHeight"), PaintedExtent.Y);
        Paint->SetNumberField(TEXT("uiScale"), PaintedScale); Paint->SetBoolField(TEXT("axisAligned"), bPaintAxisAligned);
        Paint->SetArrayField(TEXT("hudScreenPhysical"), RectJson(PaintedHudScreen));
        Paint->SetArrayField(TEXT("headerScreenPhysical"), RectJson(PaintedHeaderScreen));
        Result->SetObjectField(TEXT("paint"), Paint);
        Result->SetObjectField(TEXT("camera"), CameraJson());
        Result->SetStringField(TEXT("localIntent"), SerializeLocalIntent(Input));
        Result->SetStringField(TEXT("review"), LocalReviewName(Input.LocalReview));
        Result->SetStringField(TEXT("visibleStatus"), Status);
        Result->SetNumberField(TEXT("captureGeneration"), static_cast<double>(Input.CaptureGeneration));
        Result->SetNumberField(TEXT("focusGeneration"), static_cast<double>(Input.FocusGeneration));
        Result->SetNumberField(TEXT("cancelGeneration"), static_cast<double>(Input.CancelGeneration));
        Result->SetStringField(TEXT("owner"), Input.Capture.IsSet() ? InputOwnerName(Input.Capture->Owner) : TEXT("None"));
        Result->SetBoolField(TEXT("captured"), Input.Capture.IsSet());
        Result->SetBoolField(TEXT("textEditing"), Input.bTextEditing);
        Result->SetStringField(TEXT("editedText"), EditedText);
        Result->SetBoolField(TEXT("modalOpen"), Input.bModalOpen);
        Result->SetNumberField(TEXT("worldPickCount"), static_cast<double>(Picks));
        Result->SetNumberField(TEXT("cameraMutationCount"), static_cast<double>(CameraChanges));
        Result->SetNumberField(TEXT("eventCount"), static_cast<double>(Events));
        if (LastKeyEvent.IsValid()) { Result->SetObjectField(TEXT("lastKeyEvent"), LastKeyEvent); }
        if (LastPickHit.IsSet())
        {
            const auto Pick = MakeShared<FJsonObject>();
            Pick->SetNumberField(TEXT("pickGeneration"), static_cast<double>(LastPickGeneration));
            Pick->SetNumberField(TEXT("eventSequence"), static_cast<double>(LastPickEventSequence));
            Pick->SetArrayField(TEXT("screenPhysical"), PointJson(LastPickPointer.ScreenPhysical));
            Pick->SetArrayField(TEXT("viewportPhysical"), PointJson(LastPickPointer.ViewportPhysical));
            Pick->SetArrayField(TEXT("logical"), PointJson(LastPickPointer.Logical));
            Pick->SetBoolField(TEXT("insideViewport"), LastPickPointer.bInsideViewport);
            Pick->SetArrayField(TEXT("originWorldCm"), VectorJson(LastPickRay.OriginWorldCm));
            Pick->SetArrayField(TEXT("directionWorld"), VectorJson(LastPickRay.DirectionWorldUnit));
            Pick->SetStringField(TEXT("id"), LastPickHit->Id);
            Pick->SetNumberField(TEXT("kind"), static_cast<int32>(LastPickHit->Kind));
            Pick->SetNumberField(TEXT("distanceWorldCm"), LastPickHit->DistanceWorldCm);
            Pick->SetArrayField(TEXT("domainHitInches"), VectorJson(LastPickHit->DomainPosition));
            Pick->SetArrayField(TEXT("worldHitCm"), VectorJson(LastPickHit->WorldPosition));
            Result->SetObjectField(TEXT("lastWorldPick"), Pick);
        }
        Result->SetNumberField(TEXT("confirmAttempts"), static_cast<double>(Input.ConfirmAttempts));
        Result->SetNumberField(TEXT("hudActivationCount"), static_cast<double>(Input.HudActivationCount));
        Result->SetNumberField(TEXT("coreTransportCreations"), FInputPolicy::CoreTransportCreations());
        Result->SetNumberField(TEXT("gameCommands"), FInputPolicy::GameCommands());
        Result->SetNumberField(TEXT("acceptedResults"), FInputPolicy::AcceptedResults());
        TArray<TSharedPtr<FJsonValue>> Models;
        for (const FFootprint& M : Fixture.Models)
        {
            const auto Item = MakeShared<FJsonObject>();
            Item->SetStringField(TEXT("id"), M.Id);
            Item->SetNumberField(TEXT("shapeKind"), static_cast<int32>(M.Kind));
            Item->SetArrayField(TEXT("positionInches"), VectorJson(M.Pose->PositionInches));
            Item->SetNumberField(TEXT("facingDegrees"), M.Pose->FacingDegrees);
            Item->SetNumberField(TEXT("queryHeightInches"), M.QueryHeightInches);
            if (M.RadiusInches.IsSet()) { Item->SetNumberField(TEXT("radiusInches"), M.RadiusInches.GetValue()); }
            if (M.LengthInches.IsSet()) { Item->SetNumberField(TEXT("lengthInches"), M.LengthInches.GetValue()); }
            if (M.WidthInches.IsSet()) { Item->SetNumberField(TEXT("widthInches"), M.WidthInches.GetValue()); }
            TArray<TSharedPtr<FJsonValue>> Vertices;
            for (const auto& V : M.VerticesInches) { Vertices.Add(MakeShared<FJsonValueArray>(PointJson(V))); }
            Item->SetArrayField(TEXT("polygonLocalInches"), Vertices);
            Item->SetBoolField(TEXT("syntheticCapsule"), M.bSyntheticCapsule);
            Item->SetBoolField(TEXT("cubeSubstitution"), ReplacementMeshes.Contains(M.Id) && ReplacementMeshes[M.Id].IsValid() && ReplacementMeshes[M.Id]->IsVisible());
            Models.Add(MakeShared<FJsonValueObject>(Item));
        }
        Result->SetArrayField(TEXT("models"), Models);
        TArray<TSharedPtr<FJsonValue>> Supports;
        for (const FSupportSurface& S : Fixture.Supports)
        {
            const auto Item = MakeShared<FJsonObject>();
            Item->SetStringField(TEXT("id"), S.Id); Item->SetArrayField(TEXT("minInches"), PointJson(S.BoundsInches.Min));
            Item->SetArrayField(TEXT("maxInches"), PointJson(S.BoundsInches.Max)); Item->SetNumberField(TEXT("zInches"), S.ZInches);
            TArray<TSharedPtr<FJsonValue>> Holes;
            for (const FBounds2d& Hole : S.HolesInches)
            {
                const auto H = MakeShared<FJsonObject>(); H->SetArrayField(TEXT("minInches"), PointJson(Hole.Min)); H->SetArrayField(TEXT("maxInches"), PointJson(Hole.Max));
                Holes.Add(MakeShared<FJsonValueObject>(H));
            }
            Item->SetArrayField(TEXT("holes"), Holes); Supports.Add(MakeShared<FJsonValueObject>(Item));
        }
        Result->SetArrayField(TEXT("supports"), Supports);
        const auto Lighting = MakeShared<FJsonObject>();
        Lighting->SetArrayField(TEXT("rotationDegrees"), VectorJson(Fixture.Presentation.LightRotationDegrees));
        Lighting->SetArrayField(TEXT("linearColor"), VectorJson(Fixture.Presentation.LightColor));
        Lighting->SetNumberField(TEXT("intensityLux"), Fixture.Presentation.LightIntensityLux);
        Lighting->SetStringField(TEXT("exposureMethod"), TEXT("Manual; physical-camera-exposure disabled"));
        Lighting->SetNumberField(TEXT("exposureBias"), Fixture.Presentation.ExposureBias);
        Result->SetObjectField(TEXT("lighting"), Lighting);
        Result->SetStringField(TEXT("cubeAsset"), TEXT("/Engine/BasicShapes/Cube.Cube"));
        Result->SetStringField(TEXT("materialAsset"), TEXT("/Engine/BasicShapes/BasicShapeMaterial.BasicShapeMaterial"));
        Result->SetBoolField(TEXT("materialCompilationInProgress"), BaseMaterial.IsValid() && BaseMaterial->IsCompiling());
        return Result;
    }
    bool WriteJson(const FString& Basename, const TSharedPtr<FJsonObject>& Data)
    {
        if (FPaths::GetCleanFilename(Basename) != Basename || !Basename.EndsWith(TEXT(".json")))
        { Fail(TEXT("ArtifactBasenameInvalid")); return false; }
        const FString Text = JsonText(Data);
        if (Text.IsEmpty() || !FFileHelper::SaveStringToFile(Text, *FPaths::Combine(Artifacts, Basename), FFileHelper::EEncodingOptions::ForceUTF8WithoutBOM))
        { Fail(TEXT("ArtifactWriteFailed: ") + Basename); return false; }
        return true;
    }
    void AppendJson(const FString& Basename, const TSharedPtr<FJsonObject>& Data)
    {
        const FString Text = CompactJson(Data);
        if (Text.IsEmpty() || !FFileHelper::SaveStringToFile(Text + TEXT("\n"), *FPaths::Combine(Artifacts, Basename),
            FFileHelper::EEncodingOptions::ForceUTF8WithoutBOM, &IFileManager::Get(), FILEWRITE_Append))
        { Fail(TEXT("ArtifactAppendFailed: ") + Basename); }
    }
    void UpdateCamera()
    {
        if (!Camera.IsValid()) { return; }
        const double A = FMath::DegreesToRadians(Azimuth), E = FMath::DegreesToRadians(Elevation);
        const FVector3d Offset = FVector3d(FMath::Cos(E) * FMath::Cos(A), FMath::Cos(E) * FMath::Sin(A), FMath::Sin(E)) * Distance;
        const FVector3d Target = DomainToWorld(Fixture.Frame, CameraTarget);
        const FVector3d Position = Target + Fixture.Frame.WorldFromTableCm.TransformVectorNoScale(Offset);
        Camera->SetActorLocation(Position);
        Camera->SetActorRotation((Target - Position).Rotation());
    }
    void CameraEffect(const FInputEffects& Effect)
    {
        const auto& C = Fixture.Camera;
        bool bChange = true;
        switch (Effect.CameraAction)
        {
        case ECameraAction::Orbit: Azimuth -= Effect.LogicalDelta.X * C.OrbitDegreesPerLogicalUnit; Elevation = FMath::Clamp(Elevation + Effect.LogicalDelta.Y * C.OrbitDegreesPerLogicalUnit, C.MinimumElevationDegrees, C.MaximumElevationDegrees); break;
        case ECameraAction::Pan:
        {
            const double A = FMath::DegreesToRadians(Azimuth);
            const FVector3d DeltaTable(-FMath::Sin(A) * Effect.LogicalDelta.X + FMath::Cos(A) * Effect.LogicalDelta.Y,
                FMath::Cos(A) * Effect.LogicalDelta.X + FMath::Sin(A) * Effect.LogicalDelta.Y, 0.0);
            CameraTarget.X -= DeltaTable.X * C.PanCmPerLogicalUnit / CentimetresPerInch;
            CameraTarget.Y += DeltaTable.Y * C.PanCmPerLogicalUnit / CentimetresPerInch;
            break;
        }
        case ECameraAction::Dolly: Distance = FMath::Clamp(Distance - Effect.DollyDelta * C.DollyStepCm, C.MinimumDistanceCm, C.MaximumDistanceCm); break;
        case ECameraAction::FrameBoard: bChange = FrameBounds(false); break;
        case ECameraAction::FrameSelection: bChange = FrameBounds(true); break;
        case ECameraAction::Reset: CameraTarget = C.TargetDomainInches; Azimuth = C.DefaultAzimuthDegrees; Elevation = C.DefaultElevationDegrees; Distance = C.DefaultDistanceCm; break;
        case ECameraAction::OrbitLeft: Azimuth -= C.KeyboardOrbitStepDegrees; break;
        case ECameraAction::OrbitRight: Azimuth += C.KeyboardOrbitStepDegrees; break;
        case ECameraAction::OrbitUp: Elevation = FMath::Clamp(Elevation + C.KeyboardOrbitStepDegrees, C.MinimumElevationDegrees, C.MaximumElevationDegrees); break;
        case ECameraAction::OrbitDown: Elevation = FMath::Clamp(Elevation - C.KeyboardOrbitStepDegrees, C.MinimumElevationDegrees, C.MaximumElevationDegrees); break;
        default: bChange = false; break;
        }
        if (bChange)
        {
            Distance = FMath::Clamp(Distance, C.MinimumDistanceCm, C.MaximumDistanceCm);
            Elevation = FMath::Clamp(Elevation, C.MinimumElevationDegrees, C.MaximumElevationDegrees);
            ++CameraChanges; UpdateCamera();
        }
    }
    bool Query(const FPointerSample& Pointer, FAdvisoryHit& Hit, FString& Diagnostic,
        Warhammer::Migration::E02::FRay* ActualRay = nullptr)
    {
        FVector Origin, Direction;
        FDiagnostic Detail;
        const bool bDeprojected = Controller.IsValid() && Pointer.bInsideViewport &&
            Controller->DeprojectScreenPositionToWorld(static_cast<float>(Pointer.ViewportPhysical.X), static_cast<float>(Pointer.ViewportPhysical.Y), Origin, Direction);
        const Warhammer::Migration::E02::FRay RayValue = bDeprojected
            ? Warhammer::Migration::E02::FRay{Origin, Direction.GetSafeNormal()} : Warhammer::Migration::E02::FRay{};
        if (ActualRay) { *ActualRay = RayValue; }
        const bool bHit = bDeprojected && RaycastAdvisory(Fixture.Frame, Fixture.Models, Fixture.Supports, RayValue, Hit, Detail);
        Diagnostic = bDeprojected ? DiagnosticCodeName(Detail.Code) : TEXT("DeprojectionUnavailable");
        const auto Ray = MakeShared<FJsonObject>();
        Ray->SetStringField(TEXT("case"), CaseName); Ray->SetStringField(TEXT("observedUtc"), FDateTime::UtcNow().ToIso8601());
        Ray->SetArrayField(TEXT("screenPhysical"), PointJson(Pointer.ScreenPhysical)); Ray->SetArrayField(TEXT("viewportPhysical"), PointJson(Pointer.ViewportPhysical));
        Ray->SetBoolField(TEXT("deprojected"), bDeprojected); Ray->SetBoolField(TEXT("hit"), bHit); Ray->SetStringField(TEXT("diagnostic"), Diagnostic);
        if (bDeprojected) { Ray->SetArrayField(TEXT("originWorldCm"), VectorJson(Origin)); Ray->SetArrayField(TEXT("directionWorld"), VectorJson(Direction)); }
        if (bHit) { Ray->SetStringField(TEXT("id"), Hit.Id); Ray->SetArrayField(TEXT("domainHitInches"), VectorJson(Hit.DomainPosition)); Ray->SetNumberField(TEXT("distanceWorldCm"), Hit.DistanceWorldCm); }
        Ray->SetObjectField(TEXT("camera"), CameraJson()); AppendJson(TEXT("rays.jsonl"), Ray);
        return bHit;
    }
    void Apply(const FInputEffects& Effect, const FPointerSample& Pointer)
    {
        CameraEffect(Effect);
        if (Effect.bRequestWorldPick)
        {
            ++Picks;
            LastPickHit.Reset(); LastPickPointer = Pointer;
            LastPickGeneration = Picks; LastPickEventSequence = 0;
            FAdvisoryHit Hit; FString Detail;
            if (Query(Pointer, Hit, Detail, &LastPickRay))
            {
                LastPickHit = Hit;
                if (Hit.Kind == EHitKind::Model)
                {
                    const FFootprint* M = Model(Hit.Id);
                    if (M && M->Pose.IsSet()) { Policy.ApplyAdvisoryPick(M->Id, M->Pose.GetValue()); Status = TEXT("Local advisory selection: ") + M->Id; }
                }
            }
        }
        if (Effect.bActivateHud)
        {
            Status = TEXT("Local HUD activation: ") + Effect.HudControlId;
            if (Effect.HudControlId == TEXT("open-modal")) { Policy.SetModalOpen(true); }
        }
        if (Effect.Diagnostic.Code != EDiagnosticCode::None)
        { Status = FString(DiagnosticCodeName(Effect.Diagnostic.Code)) + TEXT(": ") + Effect.Diagnostic.Message; }
        else if (Policy.Snapshot().LocalReview == ELocalReview::Ready)
        { Status = TEXT("Local Ready — advisory only; no game session"); }
    }
    void Trace(const FString& Event, const FPointerSample& Pointer, const FHitTarget& Hit,
        const TSharedPtr<FJsonObject>& Before, const FInputEffects& Effect,
        const FKeyEvent* KeyEvent = nullptr, const FString& MatchedBinding = FString())
    {
        ++Events;
        if (Effect.bRequestWorldPick) { LastPickEventSequence = Events; }
        if ((Effect.CameraAction == ECameraAction::FrameBoard || Effect.CameraAction == ECameraAction::FrameSelection) && FrameEventSequence == 0 && !FrameKind.IsEmpty())
        { FrameEventSequence = Events; }
        const auto Data = MakeShared<FJsonObject>();
        if (KeyEvent)
        {
            LastKeyEvent = MakeShared<FJsonObject>();
            LastKeyEvent->SetStringField(TEXT("key"), KeyEvent->GetKey().ToString());
            LastKeyEvent->SetBoolField(TEXT("controlDown"), KeyEvent->IsControlDown());
            LastKeyEvent->SetBoolField(TEXT("altDown"), KeyEvent->IsAltDown());
            LastKeyEvent->SetBoolField(TEXT("shiftDown"), KeyEvent->IsShiftDown());
            LastKeyEvent->SetBoolField(TEXT("commandDown"), KeyEvent->IsCommandDown());
            LastKeyEvent->SetBoolField(TEXT("isRepeat"), KeyEvent->IsRepeat());
            FString Chord;
            if (KeyEvent->IsControlDown()) { Chord += TEXT("Ctrl+"); }
            if (KeyEvent->IsAltDown()) { Chord += TEXT("Alt+"); }
            if (KeyEvent->IsShiftDown()) { Chord += TEXT("Shift+"); }
            if (KeyEvent->IsCommandDown()) { Chord += TEXT("Command+"); }
            LastKeyEvent->SetStringField(TEXT("normalizedChord"), Chord + KeyEvent->GetKey().ToString());
            LastKeyEvent->SetStringField(TEXT("matchedBinding"), MatchedBinding);
            LastKeyEvent->SetNumberField(TEXT("eventSequence"), static_cast<double>(Events));
            Data->SetObjectField(TEXT("keyEvent"), LastKeyEvent);
        }
        Data->SetNumberField(TEXT("sequence"), static_cast<double>(Events)); Data->SetStringField(TEXT("observedUtc"), FDateTime::UtcNow().ToIso8601());
        Data->SetStringField(TEXT("case"), CaseName); Data->SetStringField(TEXT("route"), TEXT("PlatformMessageHandler -> Slate -> SE02ProofSurface -> FInputPolicy"));
        Data->SetStringField(TEXT("event"), Event); Data->SetArrayField(TEXT("screenPhysical"), PointJson(Pointer.ScreenPhysical));
        Data->SetArrayField(TEXT("viewportPhysical"), PointJson(Pointer.ViewportPhysical)); Data->SetArrayField(TEXT("logical"), PointJson(Pointer.Logical));
        Data->SetNumberField(TEXT("uiScale"), FSlateApplication::Get().GetApplicationScale());
        Data->SetStringField(TEXT("hitWidget"), TEXT("SE02ProofSurface")); Data->SetStringField(TEXT("hitControl"), Hit.ControlId);
        Data->SetStringField(TEXT("hitOwner"), InputOwnerName(Hit.Owner)); Data->SetBoolField(TEXT("consumed"), Effect.bConsumed);
        Data->SetObjectField(TEXT("before"), Before); Data->SetObjectField(TEXT("after"), Snapshot());
        AppendJson(TEXT("input.jsonl"), Data);
    }
    UMaterialInstanceDynamic* Tint(UObject* Outer, const FLinearColor& Color)
    {
        UMaterialInstanceDynamic* Material = UMaterialInstanceDynamic::Create(BaseMaterial.Get(), Outer);
        if (!Material) { Fail(TEXT("MaterialInstanceUnavailable")); return nullptr; }
        Material->SetVectorParameterValue(TEXT("Color"), Color);
        return Material;
    }
    UStaticMeshComponent* Box(const FVector3d& Center, const FVector3d& Dimensions, const FRotator& Rotation, const FLinearColor& Color)
    {
        AActor* Actor = Owner->GetWorld()->SpawnActor<AActor>();
        if (!Actor) { Fail(TEXT("TransientActorUnavailable")); return nullptr; }
        Actor->SetFlags(RF_Transient);
        UStaticMeshComponent* Mesh = NewObject<UStaticMeshComponent>(Actor, NAME_None, RF_Transient);
        Actor->SetRootComponent(Mesh); Mesh->SetMobility(EComponentMobility::Movable);
        Mesh->SetStaticMesh(CubeAsset.Get()); Mesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);
        Mesh->SetCastShadow(false); Mesh->SetMaterial(0, Tint(Mesh, Color)); Mesh->RegisterComponent();
        Actor->SetActorLocation(Center); Actor->SetActorRotation(Rotation); Actor->SetActorScale3D(Dimensions / 100.0);
        return Mesh;
    }
    bool BuildScene()
    {
        CubeAsset = LoadObject<UStaticMesh>(nullptr, TEXT("/Engine/BasicShapes/Cube.Cube"));
        BaseMaterial = LoadObject<UMaterialInterface>(nullptr, TEXT("/Engine/BasicShapes/BasicShapeMaterial.BasicShapeMaterial"));
        if (!CubeAsset.IsValid() || !BaseMaterial.IsValid()) { Fail(TEXT("RequiredEngineAssetMissing")); return false; }
        TArray<FMaterialParameterInfo> Parameters; TArray<FGuid> ParameterIds;
        BaseMaterial->GetAllVectorParameterInfo(Parameters, ParameterIds);
        if (!Parameters.ContainsByPredicate([](const FMaterialParameterInfo& P) { return P.Name == TEXT("Color"); }))
        { Fail(TEXT("UnsupportedMaterial: required Color vector parameter absent")); return false; }
        const FRotator TableRotation = Fixture.Frame.WorldFromTableCm.GetRotation().Rotator();
        for (const FSupportSurface& S : Fixture.Supports)
        {
            TArray<FBounds2d> Slabs;
            if (S.HolesInches.Num() == 0) { Slabs.Add(S.BoundsInches); }
            else if (S.HolesInches.Num() == 1)
            {
                const FBounds2d& B = S.BoundsInches; const FBounds2d& H = S.HolesInches[0];
                Slabs = {{B.Min, FVector2d(H.Min.X, B.Max.Y)}, {FVector2d(H.Max.X, B.Min.Y), B.Max},
                    {FVector2d(H.Min.X, B.Min.Y), FVector2d(H.Max.X, H.Min.Y)}, {FVector2d(H.Min.X, H.Max.Y), FVector2d(H.Max.X, B.Max.Y)}};
            }
            else { Fail(TEXT("UnsupportedSupportVisual: more than one hole")); return false; }
            const double Depth = S.ZInches > Fixture.Frame.DatumInches ? S.ZInches - Fixture.Frame.DatumInches : 0.3;
            for (const FBounds2d& B : Slabs)
            {
                const FVector2d Center = (B.Min + B.Max) * 0.5;
                Box(DomainToWorld(Fixture.Frame, FVector3d(Center.X, Center.Y, S.ZInches - Depth * 0.5)),
                    FVector3d(B.Max.X - B.Min.X, B.Max.Y - B.Min.Y, Depth) * CentimetresPerInch,
                    TableRotation, S.ZInches > Fixture.Frame.DatumInches ? FLinearColor(0.28f, 0.32f, 0.39f) : FLinearColor(0.10f, 0.15f, 0.18f));
            }
        }
        const FLinearColor Colors[] = {FLinearColor(0.95f, 0.20f, 0.10f), FLinearColor(0.95f, 0.62f, 0.08f),
            FLinearColor(0.08f, 0.68f, 0.88f), FLinearColor(0.45f, 0.22f, 0.85f)};
        for (const FFootprint& M : Fixture.Models)
        {
            FDisplayMesh Data; FDiagnostic Detail;
            if (!BuildDisplayMesh(Fixture.Frame, M, Fixture.VisualThicknessInches, Data, Detail))
            { Fail(FString(DiagnosticCodeName(Detail.Code)) + TEXT(": ") + Detail.Message); return false; }
            AActor* Actor = Owner->GetWorld()->SpawnActor<AActor>();
            if (!Actor) { Fail(TEXT("TransientModelActorUnavailable")); return false; }
            Actor->SetFlags(RF_Transient);
            UProceduralMeshComponent* Mesh = NewObject<UProceduralMeshComponent>(Actor, NAME_None, RF_Transient);
            Actor->SetRootComponent(Mesh); Mesh->SetMobility(EComponentMobility::Movable);
            Mesh->SetCollisionEnabled(ECollisionEnabled::NoCollision); Mesh->SetCastShadow(false);
            TArray<FVector> Vertices, Normals;
            for (const auto& V : Data.VerticesWorldCm) { Vertices.Add(V); }
            for (const auto& V : Data.NormalsWorld) { Normals.Add(V); }
            for (int32 Sector = 0; Sector != 4; ++Sector)
            {
                TArray<int32> Indices;
                for (int32 I = 0; I + 2 < Data.Triangles.Num(); I += 3)
                {
                    const FVector3d Centroid = (Data.VerticesWorldCm[Data.Triangles[I]] + Data.VerticesWorldCm[Data.Triangles[I + 1]] + Data.VerticesWorldCm[Data.Triangles[I + 2]]) / 3.0;
                    const FVector3d Delta = WorldToDomain(Fixture.Frame, Centroid) - M.Pose->PositionInches;
                    const double A = FMath::DegreesToRadians(M.Pose->FacingDegrees);
                    const double X = FMath::Cos(A) * Delta.X + FMath::Sin(A) * Delta.Y;
                    const double Y = -FMath::Sin(A) * Delta.X + FMath::Cos(A) * Delta.Y;
                    const int32 Classified = (X >= 0 ? 1 : 0) + (Y >= 0 ? 2 : 0);
                    if (Classified == Sector) { Indices.Append({Data.Triangles[I], Data.Triangles[I + 1], Data.Triangles[I + 2]}); }
                }
                Mesh->CreateMeshSection_LinearColor(Sector, Vertices, Indices, Normals, Data.UV0,
                    Data.VertexColors, TArray<FProcMeshTangent>(), false);
                Mesh->SetMaterial(Sector, Tint(Mesh, Colors[Sector]));
            }
            Mesh->RegisterComponent(); ModelMeshes.Add(M.Id, Mesh);
            const FVector3d Center = DomainToWorld(Fixture.Frame, M.Pose->PositionInches + FVector3d(0, 0, 0.2));
            const FVector3d X = HeadingToWorld(Fixture.Frame, M.Pose->FacingDegrees);
            const FVector3d Y = HeadingToWorld(Fixture.Frame, M.Pose->FacingDegrees + 90.0);
            Box(Center + X * 0.9, FVector3d(1.8, 0.12, 0.10), X.Rotation(), FLinearColor(1, 0.12f, 0.12f));
            Box(Center + Y * 0.9, FVector3d(1.8, 0.12, 0.10), Y.Rotation(), FLinearColor(0.15f, 1, 0.18f));
        }
        Camera = Owner->GetWorld()->SpawnActor<ACameraActor>(); Light = Owner->GetWorld()->SpawnActor<ADirectionalLight>();
        if (!Camera.IsValid() || !Light.IsValid()) { Fail(TEXT("CameraOrLightUnavailable")); return false; }
        Camera->SetFlags(RF_Transient); Light->SetFlags(RF_Transient);
        UCameraComponent* C = Camera->GetCameraComponent(); C->ProjectionMode = ECameraProjectionMode::Perspective;
        C->SetFieldOfView(static_cast<float>(Fixture.Camera.FovDegrees)); C->SetConstraintAspectRatio(false);
        auto& Exposure = C->PostProcessSettings;
        Exposure.bOverride_AutoExposureMethod = true; Exposure.AutoExposureMethod = AEM_Manual;
        Exposure.bOverride_AutoExposureApplyPhysicalCameraExposure = true; Exposure.AutoExposureApplyPhysicalCameraExposure = false;
        Exposure.bOverride_AutoExposureBias = true; Exposure.AutoExposureBias = Fixture.Presentation.ExposureBias;
        Exposure.bOverride_AutoExposureMinBrightness = true; Exposure.AutoExposureMinBrightness = 1.0f;
        Exposure.bOverride_AutoExposureMaxBrightness = true; Exposure.AutoExposureMaxBrightness = 1.0f;
        C->PostProcessBlendWeight = 1.0f;
        const auto& P = Fixture.Presentation;
        UDirectionalLightComponent* L = Cast<UDirectionalLightComponent>(Light->GetLightComponent());
        if (!L) { Fail(TEXT("DirectionalLightComponentUnavailable")); return false; }
        L->SetMobility(EComponentMobility::Movable);
        Light->SetActorRotation(FRotator(P.LightRotationDegrees.X, P.LightRotationDegrees.Y, P.LightRotationDegrees.Z));
        L->SetIntensity(P.LightIntensityLux);
        L->SetLightColor(FLinearColor(P.LightColor.X, P.LightColor.Y, P.LightColor.Z)); L->SetCastShadows(false);
        CameraTarget = Fixture.Camera.TargetDomainInches; Azimuth = Fixture.Camera.DefaultAzimuthDegrees;
        Elevation = Fixture.Camera.DefaultElevationDegrees; Distance = Fixture.Camera.DefaultDistanceCm; UpdateCamera();
        return Error.IsEmpty();
    }
    void ScreenshotProcessed()
    {
        if (PendingScreenshot.IsEmpty()) { return; }
        const FString Name = PendingScreenshot; PendingScreenshot.Empty();
        TArray<uint8> Bytes;
        if (!FFileHelper::LoadFileToArray(Bytes, *FPaths::Combine(Artifacts, Name)) || Bytes.Num() < 24 ||
            Bytes[0] != 137 || Bytes[1] != 80 || Bytes[2] != 78 || Bytes[3] != 71)
        { Fail(TEXT("ScreenshotMissingOrInvalid: ") + Name); return; }
        auto BigEndian = [&Bytes](int32 I) { return (static_cast<uint32>(Bytes[I]) << 24) | (static_cast<uint32>(Bytes[I + 1]) << 16) | (static_cast<uint32>(Bytes[I + 2]) << 8) | Bytes[I + 3]; };
        const uint32 Width = BigEndian(16), Height = BigEndian(20);
        if (Width != 1280 || Height != 720) { Fail(TEXT("ScreenshotExtentMismatch: ") + Name); return; }
        const auto Record = MakeShared<FJsonObject>(); Record->SetStringField(TEXT("case"), CaseName);
        Record->SetStringField(TEXT("filename"), Name); Record->SetStringField(TEXT("processedUtc"), FDateTime::UtcNow().ToIso8601());
        Record->SetNumberField(TEXT("width"), Width); Record->SetNumberField(TEXT("height"), Height); Record->SetObjectField(TEXT("snapshot"), Snapshot());
        ScreenshotRecords.Add(MakeShared<FJsonValueObject>(Record)); CompletedScreenshots.Add(Name);
        const auto Root = MakeShared<FJsonObject>(); Root->SetNumberField(TEXT("schemaVersion"), 1); Root->SetArrayField(TEXT("screenshots"), ScreenshotRecords);
        WriteJson(TEXT("screenshots.json"), Root);
    }
};

/** A small real Slate control surface; each painted control has explicit hit/ownership semantics. */
class SE02ProofSurface : public SLeafWidget
{
public:
    SLATE_BEGIN_ARGS(SE02ProofSurface) {} SLATE_END_ARGS()
    void Construct(const FArguments&, FE02ProofState* InProof) { Proof = InProof; }
    virtual bool SupportsKeyboardFocus() const override { return true; }
    virtual FVector2D ComputeDesiredSize(float) const override { return FVector2D(1280, 720); }
    virtual int32 OnPaint(const FPaintArgs& Args, const FGeometry& G, const FSlateRect&,
        FSlateWindowElementList& Elements, int32 Layer, const FWidgetStyle&, bool) const override
    {
        // Slate passes window-space paint geometry, while cached/input geometry is desktop-space.
        // Match SWidget::Paint's conversion; keep G for drawing in the window's paint space.
        FGeometry DesktopGeometry = G;
        DesktopGeometry.AppendTransform(FSlateLayoutTransform(Args.GetWindowToDesktopTransform()));
        auto Rect = [&](FVector2D Pos, FVector2D Size, FLinearColor Color)
        { FSlateDrawElement::MakeBox(Elements, Layer, G.ToPaintGeometry(Size, FSlateLayoutTransform(Pos)), FCoreStyle::Get().GetBrush(TEXT("WhiteBrush")), ESlateDrawEffect::None, Color); };
        auto Text = [&](FVector2D Pos, const FString& Value, int32 Size, FLinearColor Color = FLinearColor::White)
        { FSlateDrawElement::MakeText(Elements, Layer + 1, G.ToPaintGeometry(FVector2D(1000, 40), FSlateLayoutTransform(Pos)), Value, FCoreStyle::GetDefaultFontStyle(TEXT("Regular"), Size), ESlateDrawEffect::None, Color); };
        const FVector2D Size = G.GetLocalSize();
        const FVector2D HeaderSize(Size.X, Proof->Fixture.Presentation.HeaderHeightLogical);
        const FVector2D HudPosition = Proof->Fixture.Presentation.HudBoundsLogical.Min;
        const FVector2D HudSize = Proof->Fixture.Presentation.HudBoundsLogical.Max - HudPosition;
        Rect(FVector2D::ZeroVector, HeaderSize, FLinearColor(0.015f, 0.025f, 0.04f, 0.98f));
        Text(FVector2D(18, 8), ProofLabel, 18, FLinearColor(1, 0.8f, 0.25f));
        Text(FVector2D(18, 34), Proof->Status, 12);
        Rect(HudPosition, HudSize, FLinearColor(0.025f, 0.04f, 0.06f, 0.95f));
        Proof->RecordPaint(DesktopGeometry, HeaderSize, HudPosition, HudSize);
        Rect(FVector2D(30, 96), FVector2D(200, 36), FLinearColor(0.12f, 0.25f, 0.38f)); Text(FVector2D(40, 104), TEXT("Local HUD button"), 13);
        Rect(FVector2D(30, 144), FVector2D(200, 36), FLinearColor(0.08f, 0.09f, 0.10f)); Text(FVector2D(40, 152), TEXT("Disabled control"), 13, FLinearColor(0.4f, 0.4f, 0.4f));
        Text(FVector2D(40, 204), TEXT("Blank HUD consumes input"), 11);
        Rect(FVector2D(30, 240), FVector2D(200, 64), FLinearColor(0.06f, 0.10f, 0.14f)); Text(FVector2D(40, 248), TEXT("Scroll region at boundary"), 11); Text(FVector2D(40, 276), TEXT("Wheel stays in the HUD"), 11);
        Rect(FVector2D(30, 316), FVector2D(200, 36), FLinearColor(0.08f, 0.16f, 0.18f)); Text(FVector2D(40, 324), Proof->EditedText.Left(24), 11);
        Rect(FVector2D(30, 364), FVector2D(200, 36), FLinearColor(0.16f, 0.20f, 0.30f)); Text(FVector2D(40, 372), TEXT("Open modal (M)"), 13);
        Text(FVector2D(30, 416), TEXT("RMB orbit / MMB pan"), 11); Text(FVector2D(30, 436), TEXT("F board / G selection / R reset"), 10); Text(FVector2D(30, 456), TEXT("Enter local review; never submits"), 10);
        for (const FFootprint& M : Proof->Fixture.Models)
        {
            if (!Proof->Controller.IsValid() || !M.Pose.IsSet()) { continue; }
            const auto Label = [&](const FVector3d& Domain, const FString& Value, FLinearColor Color)
            {
                FVector2D Pixel, Absolute;
                if (Proof->Controller->ProjectWorldLocationToScreen(DomainToWorld(Proof->Fixture.Frame, Domain), Pixel) && Proof->AbsoluteFromPixels(Pixel, Absolute))
                { Text(DesktopGeometry.AbsoluteToLocal(Absolute), Value, 10, Color); }
            };
            Label(M.Pose->PositionInches + FVector3d(0, 0, 0.5), M.Id, FLinearColor::White);
            const double A = FMath::DegreesToRadians(M.Pose->FacingDegrees);
            Label(M.Pose->PositionInches + FVector3d(FMath::Cos(A), FMath::Sin(A), 0.25), TEXT("+X"), FLinearColor(1, 0.2f, 0.2f));
            Label(M.Pose->PositionInches + FVector3d(-FMath::Sin(A), FMath::Cos(A), 0.25), TEXT("+Y"), FLinearColor(0.2f, 1, 0.2f));
        }
        if (Proof->Policy.Snapshot().bModalOpen)
        {
            Rect(FVector2D(0, 64), FVector2D(Size.X, FMath::Max(0.0, Size.Y - 64)), FLinearColor(0, 0, 0, 0.65f));
            const FVector2D Origin = (Size - Proof->Fixture.Presentation.ModalSizeLogical) * 0.5;
            Rect(Origin, Proof->Fixture.Presentation.ModalSizeLogical, FLinearColor(0.08f, 0.13f, 0.20f));
            Text(Origin + FVector2D(20, 20), TEXT("Local modal — no game session"), 16);
            Rect(Origin + FVector2D(20, 65), FVector2D(Proof->Fixture.Presentation.ModalSizeLogical.X - 40, 40), FLinearColor(0.12f, 0.22f, 0.26f));
            Text(Origin + FVector2D(30, 76), Proof->EditedText.Left(38), 13);
            Text(Origin + FVector2D(20, 130), TEXT("Escape: cancel edit, then close modal"), 12);
        }
        return Layer + 2;
    }
    virtual FReply OnMouseButtonDown(const FGeometry& G, const FPointerEvent& E) override
    {
        const auto Before = Proof->Snapshot(); const FPointerSample P = Proof->Sample(G, E.GetScreenSpacePosition());
        const FHitTarget Hit = Proof->HitTarget(P.Logical, G.GetLocalSize());
        EPointerButton Button;
        if (E.GetEffectingButton() == EKeys::LeftMouseButton) { Button = EPointerButton::Primary; }
        else if (E.GetEffectingButton() == EKeys::RightMouseButton) { Button = EPointerButton::Secondary; }
        else if (E.GetEffectingButton() == EKeys::MiddleMouseButton) { Button = EPointerButton::Middle; }
        else { return FReply::Handled(); }
        // An additional button cannot replace the owner selected by the held gesture.
        if (Hit.Owner == EInputOwner::Text && !Proof->Policy.Snapshot().Capture.IsSet()) { Proof->Policy.SetTextEditing(true); }
        const FInputEffects Effect = Proof->Policy.Press(P, Button, Hit); Proof->Apply(Effect, P);
        Proof->Trace(TEXT("PointerDown"), P, Hit, Before, Effect);
        FReply Reply = FReply::Handled().SetUserFocus(SharedThis(this));
        if (Effect.bAcquireCapture) { Reply.CaptureMouse(SharedThis(this)); }
        return Reply;
    }
    virtual FReply OnMouseMove(const FGeometry& G, const FPointerEvent& E) override
    {
        const auto Before = Proof->Snapshot(); const auto P = Proof->Sample(G, E.GetScreenSpacePosition());
        const auto Hit = Proof->HitTarget(P.Logical, G.GetLocalSize()); const auto Effect = Proof->Policy.Move(P);
        Proof->Apply(Effect, P); Proof->Trace(TEXT("PointerMove"), P, Hit, Before, Effect); return FReply::Handled();
    }
    virtual FReply OnMouseButtonUp(const FGeometry& G, const FPointerEvent& E) override
    {
        const auto Before = Proof->Snapshot(); const auto P = Proof->Sample(G, E.GetScreenSpacePosition());
        const auto Hit = Proof->HitTarget(P.Logical, G.GetLocalSize());
        const EPointerButton Button = E.GetEffectingButton() == EKeys::RightMouseButton ? EPointerButton::Secondary :
            E.GetEffectingButton() == EKeys::MiddleMouseButton ? EPointerButton::Middle : EPointerButton::Primary;
        const auto Effect = Proof->Policy.Release(P, Button, Hit); Proof->Apply(Effect, P);
        Proof->Trace(TEXT("PointerUp"), P, Hit, Before, Effect);
        FReply Reply = FReply::Handled(); if (Effect.bReleaseCapture) { Reply.ReleaseMouseCapture(); } return Reply;
    }
    virtual FReply OnMouseWheel(const FGeometry& G, const FPointerEvent& E) override
    {
        const auto Before = Proof->Snapshot(); const auto P = Proof->Sample(G, E.GetScreenSpacePosition());
        const auto Hit = Proof->HitTarget(P.Logical, G.GetLocalSize()); const auto Effect = Proof->Policy.Wheel(P, Hit, E.GetWheelDelta());
        Proof->Apply(Effect, P); Proof->Trace(TEXT("Wheel"), P, Hit, Before, Effect); return FReply::Handled();
    }
    virtual FReply OnKeyDown(const FGeometry& G, const FKeyEvent& E) override
    {
        const auto Before = Proof->Snapshot(); FInputEffects Effect; const FKey K = E.GetKey();
        const bool bBare = !E.IsControlDown() && !E.IsAltDown() && !E.IsShiftDown() && !E.IsCommandDown();
        FString MatchedBinding;
        auto Matches = [&](const TCHAR* Name)
        {
            const FString* Bound = Proof->Fixture.KeyBindings.Find(Name);
            if (!bBare || !Bound || K != FKey(FName(**Bound))) { return false; }
            MatchedBinding = Name; return true;
        };
        // Text/modal owners retain their existing Escape behavior. Outside them,
        // all ten frozen bindings require their exact normalized bare key chord.
        if (K == EKeys::Escape && (Proof->Policy.Snapshot().bTextEditing || Proof->Policy.Snapshot().bModalOpen)) { Effect = Proof->Policy.Escape(); }
        else if (Proof->Policy.Snapshot().bTextEditing)
        {
            Effect.bConsumed = true;
            if (K == EKeys::BackSpace && !Proof->EditedText.IsEmpty()) { Proof->EditedText.LeftChopInline(1); }
        }
        else if (Matches(TEXT("cancel"))) { Effect = Proof->Policy.Escape(); }
        else if (Matches(TEXT("confirm"))) { Effect = Proof->Policy.Confirm(); }
        else if (Matches(TEXT("modal"))) { Effect = Proof->Policy.SetModalOpen(true); }
        else
        {
            ECameraAction Action = ECameraAction::None;
            if (Matches(TEXT("orbit_left"))) { Action = ECameraAction::OrbitLeft; }
            else if (Matches(TEXT("orbit_right"))) { Action = ECameraAction::OrbitRight; }
            else if (Matches(TEXT("orbit_up"))) { Action = ECameraAction::OrbitUp; }
            else if (Matches(TEXT("orbit_down"))) { Action = ECameraAction::OrbitDown; }
            else if (Matches(TEXT("frame_board"))) { Action = ECameraAction::FrameBoard; }
            else if (Matches(TEXT("frame_selection"))) { Action = ECameraAction::FrameSelection; }
            else if (Matches(TEXT("reset"))) { Action = ECameraAction::Reset; }
            if (Action != ECameraAction::None) { Effect = Proof->Policy.KeyCamera(Action); }
            else { Effect.bConsumed = true; }
        }
        const auto P = Proof->Sample(G, FSlateApplication::Get().GetCursorPos()); Proof->Apply(Effect, P);
        Proof->Trace(TEXT("KeyDown:") + K.ToString(), P, Proof->HitTarget(P.Logical, G.GetLocalSize()), Before, Effect, &E, MatchedBinding);
        FReply Reply = FReply::Handled(); if (Effect.bReleaseCapture) { Reply.ReleaseMouseCapture(); } return Reply;
    }
    virtual FReply OnKeyChar(const FGeometry& G, const FCharacterEvent& E) override
    {
        const auto Before = Proof->Snapshot(); FInputEffects Effect; Effect.bConsumed = true;
        const TCHAR Character = E.GetCharacter();
        if (Proof->Policy.Snapshot().bTextEditing && Character >= 32 && Proof->EditedText.Len() < 80) { Proof->EditedText.AppendChar(Character); }
        const auto P = Proof->Sample(G, FSlateApplication::Get().GetCursorPos());
        Proof->Trace(TEXT("TextCharacter"), P, Proof->HitTarget(P.Logical, G.GetLocalSize()), Before, Effect); return FReply::Handled();
    }
    virtual void OnMouseCaptureLost(const FCaptureLostEvent&) override
    {
        if (!Proof || Proof->bEnding || !Proof->Policy.Snapshot().Capture.IsSet()) { return; }
        const auto Before = Proof->Snapshot(); const auto Effect = Proof->Policy.CaptureLost();
        const auto P = Proof->Sample(GetCachedGeometry(), FSlateApplication::Get().GetCursorPos());
        Proof->Trace(TEXT("CaptureLost"), P, {}, Before, Effect);
    }
    virtual void OnFocusLost(const FFocusEvent&) override
    {
        if (!Proof || Proof->bEnding) { return; }
        const auto Before = Proof->Snapshot(); const auto Effect = Proof->Policy.FocusChanged(false);
        if (Effect.bReleaseCapture) { FSlateApplication::Get().ReleaseAllPointerCapture(); }
        const auto P = Proof->Sample(GetCachedGeometry(), FSlateApplication::Get().GetCursorPos());
        Proof->Trace(TEXT("SlateFocusLost"), P, {}, Before, Effect);
    }
    virtual FReply OnFocusReceived(const FGeometry& G, const FFocusEvent&) override
    {
        const auto Before = Proof->Snapshot(); const auto Effect = Proof->Policy.FocusChanged(true);
        const auto P = Proof->Sample(G, FSlateApplication::Get().GetCursorPos());
        Proof->Trace(TEXT("SlateFocusReceived"), P, {}, Before, Effect);
        return FReply::Handled();
    }
private:
    FE02ProofState* Proof = nullptr;
};

bool FE02ProofState::FrameBounds(bool bSelection)
{
    if (!Camera.IsValid() || !Controller.IsValid() || !Controller->GetLocalPlayer() || !ViewportClient() || !ViewportClient()->Viewport)
    { Fail(TEXT("FrameProjectionUnavailable: actual camera/local player/viewport required")); return false; }
    if (PaintGeneration == 0 || !Surface.IsValid() || !bPaintAxisAligned)
    { Fail(TEXT("FramePaintUnavailable: an actually painted axis-aligned HUD/header is required")); return false; }
    if (PaintedExtent != Extent() || PaintedScale != FSlateApplication::Get().GetApplicationScale())
    { Fail(TEXT("FramePaintStale: painted extent/scale differs from actual viewport")); return false; }
    FSceneViewProjectionData Data;
    if (!Controller->GetLocalPlayer()->GetProjectionData(ViewportClient()->Viewport, Data) || !Data.IsValidViewRectangle())
    { Fail(TEXT("FrameProjectionUnavailable: actual constrained projection data required")); return false; }
    const FIntRect View = Data.GetConstrainedViewRect();
    const FMatrix& M = Data.ProjectionMatrix;
    bool bSupported = View.Max.X <= Extent().X && View.Max.Y <= Extent().Y;
    for (int32 Row = 0; Row != 4; ++Row)
        for (int32 Col = 0; Col != 4; ++Col) { bSupported &= FMath::IsFinite(M.M[Row][Col]); }
    bSupported &= M.M[0][0] > 0 && M.M[1][1] > 0 && M.M[3][2] > 0;
    // The installed perspective path uses reversed-Z infinite projection. Off-center X/Y is supported.
    for (const FIntPoint Zero : {FIntPoint(0,1), FIntPoint(0,2), FIntPoint(0,3), FIntPoint(1,0), FIntPoint(1,2),
        FIntPoint(1,3), FIntPoint(2,2), FIntPoint(3,0), FIntPoint(3,1), FIntPoint(3,3)})
    { bSupported &= FMath::Abs(M.M[Zero.X][Zero.Y]) <= 1e-6; }
    bSupported &= FMath::Abs(M.M[2][3] - 1) <= 1e-6;
    if (!bSupported) { Fail(TEXT("FrameProjectionUnsupported: finite conventional perspective projection required")); return false; }
    const FGeometry& G = Surface->GetCachedGeometry();
    const FVector2D CurrentHudMax = G.LocalToAbsolute(Fixture.Presentation.HudBoundsLogical.Max);
    const FVector2D CurrentHeaderMax = G.LocalToAbsolute(FVector2D(G.GetLocalSize().X, Fixture.Presentation.HeaderHeightLogical));
    if (!CurrentHudMax.Equals(FVector2D(PaintedHudScreen.Z, PaintedHudScreen.W), 1e-3) ||
        !CurrentHeaderMax.Equals(FVector2D(PaintedHeaderScreen.Z, PaintedHeaderScreen.W), 1e-3))
    { Fail(TEXT("FramePaintStale: current layout differs from actually painted rectangles")); return false; }
    const FVector2d HudMax = Sample(G, FVector2D(PaintedHudScreen.Z, PaintedHudScreen.W)).ViewportPhysical;
    const FVector2d HeaderMax = Sample(G, FVector2D(PaintedHeaderScreen.Z, PaintedHeaderScreen.W)).ViewportPhysical;
    // This inset is physical pixels; it does not scale again with Slate or application DPI.
    const double X0 = FMath::Max(static_cast<double>(View.Min.X), HudMax.X) + 16.0;
    const double Y0 = FMath::Max(static_cast<double>(View.Min.Y), HeaderMax.Y) + 16.0;
    const double X1 = View.Max.X - 16.0, Y1 = View.Max.Y - 16.0;
    if (!FMath::IsFinite(X0) || !FMath::IsFinite(Y0) || X1 <= X0 || Y1 <= Y0)
    { Fail(TEXT("FrameFitUnavailable: painted HUD/header leave no inset viewport region")); return false; }
    const double L = (2 * (X0 - View.Min.X) / View.Width() - 1 - M.M[2][0]) / M.M[0][0];
    const double R = (2 * (X1 - View.Min.X) / View.Width() - 1 - M.M[2][0]) / M.M[0][0];
    const double B = (1 - 2 * (Y1 - View.Min.Y) / View.Height() - M.M[2][1]) / M.M[1][1];
    const double T = (1 - 2 * (Y0 - View.Min.Y) / View.Height() - M.M[2][1]) / M.M[1][1];
    const double CX = (L + R) * 0.5, CY = (B + T) * 0.5;
    if (!FMath::IsFinite(CX) || !FMath::IsFinite(CY) || R <= L || T <= B)
    { Fail(TEXT("FrameProjectionUnsupported: invalid perspective side slopes")); return false; }

    FVector3d Min(Fixture.BoardBoundsInches.Min.X, Fixture.BoardBoundsInches.Min.Y, Fixture.Frame.DatumInches);
    FVector3d Max(Fixture.BoardBoundsInches.Max.X, Fixture.BoardBoundsInches.Max.Y, Fixture.Frame.DatumInches);
    TArray<FVector3d> DomainCorners;
    FVector3d CenterDomain;
    auto Include = [&](const FVector3d& P)
    { for (int32 I = 0; I != 3; ++I) { Min[I] = FMath::Min(Min[I], P[I]); Max[I] = FMath::Max(Max[I], P[I]); } };
    auto Corner = [](const FVector3d& A, const FVector3d& Z, int32 Bits)
    { return FVector3d(Bits & 1 ? Z.X : A.X, Bits & 2 ? Z.Y : A.Y, Bits & 4 ? Z.Z : A.Z); };
    if (bSelection)
    {
        if (!Policy.Snapshot().SelectedIntent.IsSet()) { return false; }
        const FFootprint* Selected = Model(Policy.Snapshot().SelectedIntent->ModelId);
        if (!Selected || !AnalyticLocalBounds(*Selected, Fixture.VisualThicknessInches, Min, Max))
        { Fail(TEXT("FrameGeometryUnsupported: selected analytic bounds unavailable")); return false; }
        CenterDomain = PoseBoundsPoint(Selected->Pose.GetValue(), (Min + Max) * 0.5);
        for (int32 Bits = 0; Bits != 8; ++Bits) { DomainCorners.Add(PoseBoundsPoint(Selected->Pose.GetValue(), Corner(Min, Max, Bits))); }
    }
    else
    {
        for (const FSupportSurface& S : Fixture.Supports)
        {
            const double Depth = S.ZInches > Fixture.Frame.DatumInches ? S.ZInches - Fixture.Frame.DatumInches : 0.3;
            Include(FVector3d(S.BoundsInches.Min.X, S.BoundsInches.Min.Y, S.ZInches - Depth));
            Include(FVector3d(S.BoundsInches.Max.X, S.BoundsInches.Max.Y, S.ZInches));
        }
        for (const FFootprint& ModelValue : Fixture.Models)
        {
            FVector3d LocalMin, LocalMax;
            if (!AnalyticLocalBounds(ModelValue, Fixture.VisualThicknessInches, LocalMin, LocalMax))
            { Fail(TEXT("FrameGeometryUnsupported: board analytic bounds unavailable")); return false; }
            for (int32 Bits = 0; Bits != 8; ++Bits) { Include(PoseBoundsPoint(ModelValue.Pose.GetValue(), Corner(LocalMin, LocalMax, Bits))); }
        }
        CenterDomain = (Min + Max) * 0.5;
        for (int32 Bits = 0; Bits != 8; ++Bits) { DomainCorners.Add(Corner(Min, Max, Bits)); }
    }
    // Form the box before presentation placement. A world AABB would inflate a rotated table.
    const FVector3d Center = DomainToWorld(Fixture.Frame, CenterDomain);
    const auto& C = Fixture.Camera;
    const double A = FMath::DegreesToRadians(C.DefaultAzimuthDegrees), E = FMath::DegreesToRadians(C.DefaultElevationDegrees);
    const FVector3d Forward = -Fixture.Frame.WorldFromTableCm.TransformVectorNoScale(FVector3d(FMath::Cos(E) * FMath::Cos(A), FMath::Cos(E) * FMath::Sin(A), FMath::Sin(E))).GetSafeNormal();
    const FVector3d Right = FVector3d::CrossProduct(FVector3d::UpVector, Forward).GetSafeNormal();
    const FVector3d Up = FVector3d::CrossProduct(Forward, Right).GetSafeNormal();
    const double Near = Data.GetNearPlaneFromProjectionMatrix();
    if (!FMath::IsFinite(Near) || Near <= 0 || Right.IsNearlyZero() || Up.IsNearlyZero())
    { Fail(TEXT("FrameProjectionUnsupported: near plane or default orientation unavailable")); return false; }
    double GeometricDistance = 0;
    for (const FVector3d& P : DomainCorners)
    {
        const FVector3d V = DomainToWorld(Fixture.Frame, P) - Center;
        const double VF = FVector3d::DotProduct(V, Forward), VR = FVector3d::DotProduct(V, Right), VU = FVector3d::DotProduct(V, Up);
        for (const double Bound : {(L * VF - VR) / (CX - L), (VR - R * VF) / (R - CX),
            (B * VF - VU) / (CY - B), (VU - T * VF) / (T - CY), Near - VF})
        {
            if (!FMath::IsFinite(Bound)) { Fail(TEXT("FrameFitUnavailable: nonfinite conservative corner bound")); return false; }
            GeometricDistance = FMath::Max(GeometricDistance, Bound);
        }
    }
    // Numerical slack belongs to the geometric bound, preserving an already sufficient 320/85 hint exactly.
    const double NewDistance = FMath::Max(FMath::Max(C.MinimumDistanceCm,
        bSelection ? C.FrameSelectionDistanceCm : C.DefaultDistanceCm), GeometricDistance + 0.01);
    const FVector3d NewTarget = WorldToDomain(Fixture.Frame, Center - Right * CX * NewDistance - Up * CY * NewDistance);
    if (!FMath::IsFinite(NewDistance) || NewDistance > C.MaximumDistanceCm || NewTarget.ContainsNaN())
    { Fail(TEXT("FrameFitUnavailable: conservative bounds cannot fit within camera distance limit")); return false; }
    // Commit only after layout, projection and every geometric bound have passed.
    CameraTarget = NewTarget; Distance = NewDistance; Azimuth = C.DefaultAzimuthDegrees; Elevation = C.DefaultElevationDegrees;
    FrameKind = bSelection ? TEXT("selection") : TEXT("board"); ++FrameGeneration;
    FramePaintGeneration = PaintGeneration; FrameEventSequence = 0;
    return true;
}

AE02ProofPlayerController::AE02ProofPlayerController()
{
    bShowMouseCursor = true; bEnableClickEvents = false; bEnableMouseOverEvents = false;
    bAutoManageActiveCameraTarget = false;
}
AE02WorldProofGameMode::AE02WorldProofGameMode()
{
    PrimaryActorTick.bCanEverTick = true; PlayerControllerClass = AE02ProofPlayerController::StaticClass();
    DefaultPawnClass = nullptr; HUDClass = nullptr; Proof = MakeUnique<FE02ProofState>();
}
// Keep the hot-reload helper constructor where the private state is complete.
AE02WorldProofGameMode::AE02WorldProofGameMode(FVTableHelper& Helper) : Super(Helper) {}
AE02WorldProofGameMode::~AE02WorldProofGameMode() = default;
void AE02WorldProofGameMode::BeginPlay()
{
    Super::BeginPlay(); Proof->Owner = this;
    const TCHAR* ExplicitGame = GetWorld()->URL.GetOption(TEXT("game="), nullptr);
    if (!FParse::Param(FCommandLine::Get(), TEXT("E02Proof")) || !ExplicitGame ||
        FCString::Strcmp(ExplicitGame, TEXT("/Script/WarhammerClient.E02WorldProofGameMode")) != 0)
    { Proof->Fail(TEXT("ProofOptInMissing: explicit GameMode and -E02Proof are both required")); return; }
    FString Artifacts;
    if (!FParse::Value(FCommandLine::Get(), TEXT("E02Fixture="), Proof->FixturePath) || FPaths::IsRelative(Proof->FixturePath) ||
        !FParse::Value(FCommandLine::Get(), TEXT("E02Artifacts="), Artifacts) || FPaths::IsRelative(Artifacts))
    { Proof->Fail(TEXT("ProofPathsMissing: absolute -E02Fixture and -E02Artifacts required")); return; }
    Proof->Artifacts = FPaths::ConvertRelativePathToFull(Artifacts);
    FString StagedProject = FPaths::ConvertRelativePathToFull(FPaths::ProjectDir());
    FPaths::NormalizeDirectoryName(StagedProject);
    const FString RunRoot = FPaths::GetPath(StagedProject);
    FString ExpectedFixture = FPaths::Combine(RunRoot, TEXT("fixture/world-input-v1.json"));
    FPaths::NormalizeFilename(ExpectedFixture); FPaths::NormalizeFilename(Proof->FixturePath);
    FPaths::NormalizeDirectoryName(Proof->Artifacts);
    const FString ArtifactPrefix = FPaths::Combine(RunRoot, TEXT("artifacts")) + TEXT("/");
    if (FPaths::GetCleanFilename(StagedProject) != TEXT("project") ||
        !Proof->Artifacts.StartsWith(ArtifactPrefix) || Proof->FixturePath != ExpectedFixture ||
        Proof->Artifacts.Contains(TEXT("/../")) || Proof->FixturePath.Contains(TEXT("/../")))
    { Proof->Fail(TEXT("ProofStagingRequired: fixture and artifacts must belong to the staged project's RunRoot")); return; }
    FDiagnostic Detail;
    if (!LoadFixture(Proof->FixturePath, Proof->Fixture, Detail))
    { Proof->Fail(FString(DiagnosticCodeName(Detail.Code)) + TEXT(": ") + Detail.Field + TEXT(": ") + Detail.Message); return; }
    if (!IFileManager::Get().MakeDirectory(*Proof->Artifacts, true)) { Proof->Fail(TEXT("ArtifactDirectoryUnavailable")); return; }
    if (!FSlateApplication::IsInitialized()) { Proof->Fail(TEXT("SlateUnavailable")); return; }
    Proof->OriginalApplicationScale = FSlateApplication::Get().GetApplicationScale();
    Proof->Policy = FInputPolicy(Proof->Fixture.Camera.DragThresholdLogicalUnits);
    Proof->bSceneBuilt = Proof->BuildScene();
}
void AE02WorldProofGameMode::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);
    if (!Proof->bSceneBuilt || !Proof->Error.IsEmpty() || Proof->bEnding) { return; }
    if (!Proof->bReady)
    {
        Proof->Controller = GetWorld()->GetFirstPlayerController();
        if (!Proof->Controller.IsValid() || !Proof->ViewportClient() || !Proof->ViewportClient()->GetGameViewportWidget().IsValid()) { return; }
        const auto Window = Proof->ViewportClient()->GetWindow();
        if (!Window.IsValid() || !Window->GetNativeWindow().IsValid()) { return; }
        if (!Window->IsVisible() || !Proof->HardwareIdentityReady() || FCString::Strcmp(GDynamicRHI->GetName(), TEXT("D3D12")) != 0)
        {
            Proof->Fail(TEXT("HardwareViewportUnavailable: visible owned window, D3D12, nonsoftware adapter/device and driver identity required"));
            Proof->WriteJson(TEXT("scene.json"), Proof->Snapshot()); return;
        }
        Proof->Controller->SetViewTarget(Proof->Camera.Get());
        Proof->Surface = SNew(SE02ProofSurface, Proof.Get());
        Proof->ViewportClient()->AddViewportWidgetContent(Proof->Surface.ToSharedRef(), 100);
        FSlateApplication::Get().SetKeyboardFocus(Proof->Surface, EFocusCause::SetDirectly);
        Proof->ActivationHandle = FSlateApplication::Get().OnApplicationActivationStateChanged().AddLambda([this](bool bActive)
        {
            const auto Before = Proof->Snapshot(); const auto Effect = Proof->Policy.FocusChanged(bActive);
            if (Effect.bReleaseCapture) { FSlateApplication::Get().ReleaseAllPointerCapture(); }
            const auto P = Proof->Sample(Proof->Surface->GetCachedGeometry(), FSlateApplication::Get().GetCursorPos());
            Proof->Trace(Proof->bInjectingActivation ? TEXT("EngineInjectedActivation") : TEXT("ObservedApplicationActivation"), P, {}, Before, Effect);
        });
        Proof->ScreenshotHandle = FScreenshotRequest::OnScreenshotRequestProcessed().AddLambda([this]() { Proof->ScreenshotProcessed(); });
        Proof->bReady = true;
    }
    const FIntPoint Size = Proof->Extent(); const double Scale = FSlateApplication::Get().GetApplicationScale();
    Proof->Surface->Invalidate(EInvalidateWidgetReason::Paint);
    if (Size != Proof->LastExtent || Scale != Proof->LastScale)
    {
        const auto Before = Proof->Snapshot(); const auto Effect = Proof->Policy.ViewportChanged(Size, Scale);
        if (Effect.bReleaseCapture) { FSlateApplication::Get().ReleaseAllPointerCapture(); }
        Proof->LastExtent = Size; Proof->LastScale = Scale;
        Proof->Trace(TEXT("ObservedViewportOrScaleChanged"), {}, {}, Before, Effect);
    }
    if (!Proof->bInitialSceneWritten && Size.X > 0 && Size.Y > 0 &&
        Proof->Surface->GetCachedGeometry().GetLocalSize().X > 0)
    {
        Proof->bInitialSceneWritten = Proof->WriteJson(TEXT("scene.json"), Proof->Snapshot());
    }
}
void AE02WorldProofGameMode::EndPlay(const EEndPlayReason::Type Reason)
{
    Proof->bEnding = true;
    if (FSlateApplication::IsInitialized())
    {
        FSlateApplication::Get().OnApplicationActivationStateChanged().Remove(Proof->ActivationHandle);
        FSlateApplication::Get().ReleaseAllPointerCapture();
        FSlateApplication::Get().SetApplicationScale(Proof->OriginalApplicationScale);
        if (Proof->Surface.IsValid() && Proof->ViewportClient()) { Proof->ViewportClient()->RemoveViewportWidgetContent(Proof->Surface.ToSharedRef()); }
    }
    FScreenshotRequest::OnScreenshotRequestProcessed().Remove(Proof->ScreenshotHandle);
    Proof->Surface.Reset(); Super::EndPlay(Reason);
}
bool AE02WorldProofGameMode::IsProofReady() const
{
    return Proof->bReady && Proof->bInitialSceneWritten && Proof->Error.IsEmpty() &&
        Proof->BaseMaterial.IsValid() && !Proof->BaseMaterial->IsCompiling();
}
FString AE02WorldProofGameMode::GetProofError() const { return Proof->Error; }
const FFixture& AE02WorldProofGameMode::GetFixture() const { return Proof->Fixture; }
const FInputPolicy& AE02WorldProofGameMode::GetPolicy() const { return Proof->Policy; }
FIntPoint AE02WorldProofGameMode::GetProofViewportSize() const { return Proof->Extent(); }
double AE02WorldProofGameMode::GetProofUiScale() const { return FSlateApplication::IsInitialized() ? FSlateApplication::Get().GetApplicationScale() : 0.0; }
TSharedPtr<FJsonObject> AE02WorldProofGameMode::Snapshot() const
{
    const auto Record = Proof->Snapshot();
    Record->SetArrayField(TEXT("actualDisplayCulling"), Proof->ActualDisplayGeometry(false));
    return Record;
}
bool AE02WorldProofGameMode::WriteSnapshot(const FString& Basename)
{
    const auto Record = Snapshot();
    if (Basename == TEXT("five-forms-geometry.json")) { Record->SetArrayField(TEXT("actualDisplayGeometry"), Proof->ActualDisplayGeometry()); }
    return Proof->WriteJson(Basename, Record);
}
bool AE02WorldProofGameMode::BeginCase(const FString& Name)
{
    if (!IsProofReady() || !Proof->PendingScreenshot.IsEmpty()) { return false; }
    Proof->CaseName = Name; return WriteSnapshot(TEXT("scene.json"));
}
bool AE02WorldProofGameMode::ResetCase()
{
    if (!IsProofReady() || !Proof->PendingScreenshot.IsEmpty()) { return false; }
    FSlateApplication::Get().ReleaseAllPointerCapture();
    Proof->Policy = FInputPolicy(Proof->Fixture.Camera.DragThresholdLogicalUnits);
    Proof->LastPickHit.Reset(); Proof->LastPickGeneration = 0; Proof->LastPickEventSequence = 0;
    Proof->LastKeyEvent.Reset();
    Proof->Policy.ViewportChanged(Proof->Extent(), 1.0);
    FSlateApplication::Get().SetApplicationScale(1.0);
    FSlateApplication::Get().SetKeyboardFocus(Proof->Surface);
    Proof->CameraTarget = Proof->Fixture.Camera.TargetDomainInches; Proof->Azimuth = Proof->Fixture.Camera.DefaultAzimuthDegrees;
    Proof->Elevation = Proof->Fixture.Camera.DefaultElevationDegrees; Proof->Distance = Proof->Fixture.Camera.DefaultDistanceCm;
    Proof->UpdateCamera(); Proof->Status = TEXT("Local advisory proof; select a footprint");
    for (auto& Pair : Proof->ModelMeshes) { if (Pair.Value.IsValid()) { Pair.Value->SetVisibility(true); } }
    for (auto& Pair : Proof->ReplacementMeshes) { if (Pair.Value.IsValid()) { Pair.Value->SetVisibility(false); } }
    return true;
}
bool AE02WorldProofGameMode::DomainScreenPoint(const FVector3d& Domain, FVector2D& Absolute) const
{
    FVector2D Pixel;
    return IsProofReady() && Proof->Controller->ProjectWorldLocationToScreen(DomainToWorld(Proof->Fixture.Frame, Domain), Pixel) && Proof->AbsoluteFromPixels(Pixel, Absolute);
}
bool AE02WorldProofGameMode::ModelScreenPoint(const FString& Id, FVector2D& Absolute) const
{
    const FFootprint* M = Proof->Model(Id);
    if (!M || !M->Pose.IsSet()) { return false; }
    // Aim inside the convex polygon rather than at its boundary/origin vertex.
    FVector3d Domain = M->Pose->PositionInches;
    if (M->Kind == EShapeKind::Polygon)
    {
        FVector2d Center = FVector2d::ZeroVector; for (const auto& V : M->VerticesInches) { Center += V; }
        Center /= M->VerticesInches.Num(); const double A = FMath::DegreesToRadians(M->Pose->FacingDegrees);
        Domain += FVector3d(FMath::Cos(A) * Center.X - FMath::Sin(A) * Center.Y, FMath::Sin(A) * Center.X + FMath::Cos(A) * Center.Y, 0.0);
    }
    Domain.Z += M->QueryHeightInches; return DomainScreenPoint(Domain, Absolute);
}
bool AE02WorldProofGameMode::ControlScreenPoint(const FString& Id, FVector2D& Absolute) const
{
    if (!Proof->Surface.IsValid()) { return false; }
    FVector2D P;
    if (Id == TEXT("button")) { P = FVector2D(130, 114); }
    else if (Id == TEXT("disabled")) { P = FVector2D(130, 162); }
    else if (Id == TEXT("blank")) { P = FVector2D(130, 210); }
    else if (Id == TEXT("scroll")) { P = FVector2D(130, 272); }
    else if (Id == TEXT("text")) { P = FVector2D(130, 334); }
    else if (Id == TEXT("open-modal")) { P = FVector2D(130, 382); }
    else if (Id == TEXT("modal-text")) { P = (Proof->Surface->GetCachedGeometry().GetLocalSize() - Proof->Fixture.Presentation.ModalSizeLogical) * 0.5 + FVector2D(100, 85); }
    else { return false; }
    Absolute = Proof->Surface->GetCachedGeometry().LocalToAbsolute(P); return true;
}
bool AE02WorldProofGameMode::QueryScreenPoint(const FVector2D& Absolute, FAdvisoryHit& Hit, FString& Diagnostic)
{
    return IsProofReady() && Proof->Surface.IsValid() && Proof->Query(Proof->Sample(Proof->Surface->GetCachedGeometry(), Absolute), Hit, Diagnostic);
}
bool AE02WorldProofGameMode::GetLastWorldPick(FPointerSample& Pointer, Warhammer::Migration::E02::FRay& Ray,
    FAdvisoryHit& Hit, uint64& PickGeneration, uint64& EventSequence) const
{
    if (!Proof->LastPickHit.IsSet() || Proof->LastPickEventSequence == 0) { return false; }
    Pointer = Proof->LastPickPointer; Ray = Proof->LastPickRay; Hit = Proof->LastPickHit.GetValue();
    PickGeneration = Proof->LastPickGeneration; EventSequence = Proof->LastPickEventSequence;
    return true;
}
bool AE02WorldProofGameMode::ProjectRayRoundTrip(const FVector3d& Domain, double& DomainError, double& PixelError, FString& Id)
{
    FVector2D Screen; FAdvisoryHit Hit; FString Detail;
    if (!DomainScreenPoint(Domain, Screen) || !QueryScreenPoint(Screen, Hit, Detail)) { return false; }
    FVector2D Again;
    if (!DomainScreenPoint(Hit.DomainPosition, Again)) { return false; }
    DomainError = FVector3d::Distance(Domain, Hit.DomainPosition); PixelError = FVector2D::Distance(Screen, Again); Id = Hit.Id;
    return true;
}
bool AE02WorldProofGameMode::SetProofViewElevation(double Degrees)
{
    if (!IsProofReady() || !FMath::IsFinite(Degrees) || Degrees < Proof->Fixture.Camera.MinimumElevationDegrees || Degrees > Proof->Fixture.Camera.MaximumElevationDegrees) { return false; }
    Proof->Elevation = Degrees; Proof->UpdateCamera(); return true;
}
bool AE02WorldProofGameMode::SetCubeSubstitution(const FString& Id, bool bEnabled)
{
    const FFootprint* M = Proof->Model(Id);
    if (!IsProofReady() || !M || !M->Pose.IsSet() || !Proof->ModelMeshes.Contains(Id)) { return false; }
    if (bEnabled && (!Proof->ReplacementMeshes.Contains(Id) || !Proof->ReplacementMeshes[Id].IsValid()))
    {
        const FVector3d Position = DomainToWorld(Proof->Fixture.Frame, M->Pose->PositionInches + FVector3d(0, 0, 0.7));
        UStaticMeshComponent* Mesh = Proof->Box(Position, FVector3d(2.2, 1.7, 1.4) * CentimetresPerInch,
            HeadingToWorld(Proof->Fixture.Frame, M->Pose->FacingDegrees).Rotation(), FLinearColor(0.75f, 0.80f, 0.90f));
        if (!Mesh) { return false; } Proof->ReplacementMeshes.Add(Id, Mesh);
    }
    Proof->ModelMeshes[Id]->SetVisibility(!bEnabled);
    if (Proof->ReplacementMeshes.Contains(Id) && Proof->ReplacementMeshes[Id].IsValid()) { Proof->ReplacementMeshes[Id]->SetVisibility(bEnabled); }
    return true;
}
bool AE02WorldProofGameMode::RequestProofScreenshot(const FString& Basename)
{
    if (!IsProofReady() || !Proof->PendingScreenshot.IsEmpty() || FPaths::GetCleanFilename(Basename) != Basename ||
        !Basename.EndsWith(TEXT(".png")) || Proof->CompletedScreenshots.Contains(Basename) || Proof->Extent() != FIntPoint(1280, 720) || GetProofUiScale() != 1.0)
    { return false; }
    const FString Path = FPaths::Combine(Proof->Artifacts, Basename);
    if (IFileManager::Get().FileExists(*Path)) { Proof->Fail(TEXT("ScreenshotAlreadyExists: ") + Basename); return false; }
    Proof->PendingScreenshot = Basename;
    FScreenshotRequest::RequestScreenshot(Path, true, false, false, FIntRect(), true);
    return true;
}
bool AE02WorldProofGameMode::IsScreenshotComplete(const FString& Basename) const { return Proof->CompletedScreenshots.Contains(Basename); }
bool AE02WorldProofGameMode::ProgrammaticResize(FIntPoint Extent)
{
    const auto Window = Proof->ViewportClient() ? Proof->ViewportClient()->GetWindow() : nullptr;
    if (!Window.IsValid() || Extent.X < 640 || Extent.Y < 360) { return false; }
    const auto Before = Proof->Snapshot(); FInputEffects Effect; Effect.bConsumed = true;
    Window->Resize(FVector2D(Extent.X, Extent.Y));
    Proof->Trace(TEXT("ProgrammaticOwnedWindowResizeRequested"), {}, {}, Before, Effect); return true;
}
bool AE02WorldProofGameMode::SetProofUiScale(double Scale)
{
    if (!IsProofReady() || (Scale != 1.0 && Scale != 1.5)) { return false; }
    FSlateApplication::Get().SetApplicationScale(Scale); return true;
}
void AE02WorldProofGameMode::InjectActivation(bool bActive)
{
    Proof->bInjectingActivation = true; FSlateApplication::Get().OnApplicationActivationChanged(bActive); Proof->bInjectingActivation = false;
}
void AE02WorldProofGameMode::InjectCaptureLoss() { FSlateApplication::Get().ReleaseAllPointerCapture(); }
uint64 AE02WorldProofGameMode::EventCount() const { return Proof->Events; }
uint64 AE02WorldProofGameMode::WorldPickCount() const { return Proof->Picks; }
uint64 AE02WorldProofGameMode::CameraMutationCount() const { return Proof->CameraChanges; }
FString AE02WorldProofGameMode::VisibleStatus() const { return Proof->Status; }
bool AE02WorldProofGameMode::IsTextFocused() const { return Proof->Surface.IsValid() && Proof->Surface->HasKeyboardFocus() && Proof->Policy.Snapshot().bTextEditing; }
bool AE02WorldProofGameMode::IsModalOpen() const { return Proof->Policy.Snapshot().bModalOpen; }
