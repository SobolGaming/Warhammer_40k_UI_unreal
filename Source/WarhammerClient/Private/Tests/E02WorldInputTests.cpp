#include "Misc/AutomationTest.h"

#if WITH_DEV_AUTOMATION_TESTS && WITH_E02_AUTOMATION_DRIVER

#include "Migration/E02WorldProofGameMode.h"
#include "Async/AsyncResult.h"
#include "Dom/JsonObject.h"
#include "DriverConfiguration.h"
#include "Engine/Engine.h"
#include "Engine/GameViewportClient.h"
#include "Engine/LocalPlayer.h"
#include "Engine/World.h"
#include "Framework/Application/SlateApplication.h"
#include "HAL/PlatformTime.h"
#include "HAL/PlatformMisc.h"
#include "IAutomationDriver.h"
#include "IAutomationDriverModule.h"
#include "IDriverSequence.h"
#include "InputCoreTypes.h"
#include "SceneView.h"
#include "UnrealClient.h"
#include "Widgets/SViewport.h"
#include "Widgets/SWidget.h"

using namespace Warhammer::Migration::E02;

namespace
{
enum class EStepResult : uint8 { Wait, Done };

/** Independent measured basis: deliberately does not use AbsoluteToLocal or the proof adapter. */
struct FObservedSlateBasis
{
    FVector2D Origin, X, Y, LocalSize;
    double Determinant = 0;
    bool Read(const FGeometry& Geometry)
    {
        LocalSize = Geometry.GetLocalSize();
        if (LocalSize.X <= 0 || LocalSize.Y <= 0) { return false; }
        Origin = Geometry.LocalToAbsolute(FVector2D::ZeroVector);
        X = (FVector2D(Geometry.LocalToAbsolute(FVector2D(LocalSize.X, 0))) - Origin) / LocalSize.X;
        Y = (FVector2D(Geometry.LocalToAbsolute(FVector2D(0, LocalSize.Y))) - Origin) / LocalSize.Y;
        Determinant = X.X * Y.Y - X.Y * Y.X;
        return !Origin.ContainsNaN() && !X.ContainsNaN() && !Y.ContainsNaN() &&
            FMath::IsFinite(Determinant) && FMath::Abs(Determinant) > 1e-8;
    }
    FVector2D ToLocal(const FVector2D& Screen) const
    {
        const FVector2D D = Screen - Origin;
        return FVector2D((D.X * Y.Y - D.Y * Y.X) / Determinant,
            (X.X * D.Y - X.Y * D.X) / Determinant);
    }
    FVector2D ToScreen(const FVector2D& Local) const { return Origin + X * Local.X + Y * Local.Y; }
};

FVector2D QuantizedPhysical(const FVector2D& P)
{
    // The installed AutomationDriver cursor uses integer physical screen coordinates.
    return FVector2D(FMath::RoundToInt(P.X), FMath::RoundToInt(P.Y));
}
FVector3d JsonVector3(const TSharedPtr<FJsonObject>& Object, const TCHAR* Field)
{
    const auto& Values = Object->GetArrayField(Field);
    return FVector3d(Values[0]->AsNumber(), Values[1]->AsNumber(), Values[2]->AsNumber());
}
FVector4d JsonRect4(const TSharedPtr<FJsonObject>& Object, const TCHAR* Field)
{
    const auto& Values = Object->GetArrayField(Field);
    return FVector4d(Values[0]->AsNumber(), Values[1]->AsNumber(), Values[2]->AsNumber(), Values[3]->AsNumber());
}

/** Each Update returns to the engine loop. No driver future is synchronously waited on. */
class FE02CaseCommand final : public IAutomationLatentCommand
{
public:
    FE02CaseCommand(FAutomationTestBase* InTest, const FString& InCase)
        : Test(InTest), Name(InCase), Started(FPlatformTime::Seconds()) {}
    virtual ~FE02CaseCommand() override
    {
        // Ordinarily Finish has already restored the platform handler. This also
        // restores it when the framework abandons this command during shutdown.
        if (bOwnsDriver && IAutomationDriverModule::Get().IsEnabled()) { IAutomationDriverModule::Get().Disable(); }
    }
    virtual bool Update() override
    {
        if (!World.IsValid())
        {
            if (GEngine)
            {
                for (const FWorldContext& Context : GEngine->GetWorldContexts())
                {
                    if (Context.World() && Context.World()->IsGameWorld())
                    {
                        AE02WorldProofGameMode* Candidate = Cast<AE02WorldProofGameMode>(Context.World()->GetAuthGameMode());
                        if (Candidate) { World = Candidate; break; }
                    }
                }
            }
            if (!World.IsValid())
            {
                if (FPlatformTime::Seconds() - Started < 15) { return false; }
                Check(false, TEXT("Explicit E02 game world did not become available")); return Finish();
            }
        }
        if (!World->GetProofError().IsEmpty()) { if (!bFailed) { Check(false, World->GetProofError()); } return Finish(); }
        if (!bInitialized)
        {
            if (!World->IsProofReady())
            {
                if (FPlatformTime::Seconds() - Started < 30) { return false; }
                Check(false, TEXT("Owned hardware game viewport was not ready within30s")); return Finish();
            }
            const auto Snapshot = World->Snapshot();
            if (!Check(Snapshot->GetBoolField(TEXT("hardwareRhi")) && Snapshot->GetStringField(TEXT("rhi")) == TEXT("D3D12"), TEXT("Actual D3D12 hardware RHI required")) ||
                !Check(Snapshot->GetBoolField(TEXT("perspective")), TEXT("Actual perspective camera required")) ||
                !Check(World->GetProofViewportSize() == FIntPoint(1280, 720), TEXT("Initial actual viewport must be1280x720")) ||
                !Check(World->ResetCase() && World->BeginCase(Name), TEXT("Reset and case artifact initialization"))) { return Finish(); }
            auto& Module = IAutomationDriverModule::Get();
            if (!Check(!Module.IsEnabled(), TEXT("No pre-existing driver may be borrowed"))) { return Finish(); }
            Module.Enable(); bOwnsDriver = true;
            if (!Check(Module.IsEnabled(), TEXT("Driver must actually enable"))) { return Finish(); }
            auto Configuration = MakeShared<FDriverConfiguration, ESPMode::ThreadSafe>();
            Configuration->ImplicitWait = FTimespan::FromSeconds(2);
            Driver = Module.CreateAsyncDriver(Configuration);
            bInitialized = true; EventBaseline = World->EventCount(); BuildSteps(); StepStarted = FPlatformTime::Seconds();
            return false; // Allow the actual reset geometry/camera to reach the next frame.
        }
        if (FPlatformTime::Seconds() - Started > 60 && !bFailed)
        { Check(false, TEXT("Per-case60-second bound exceeded; incomplete input is failure")); }
        if (bFailed) { return Finish(); }
        if (Index >= Steps.Num()) { return Finish(); }
        if (Steps[Index]() == EStepResult::Done)
        { ++Index; StepStarted = FPlatformTime::Seconds(); }
        return false;
    }
private:
    bool Check(bool Value, const FString& Message)
    {
        ++Assertions;
        if (!Value) { Test->AddError(Name + TEXT(": ") + Message); bFailed = true; }
        return Value;
    }
    void Do(const FString& Label, TFunction<void()> Action)
    {
        Steps.Add([this, Label, Action = MoveTemp(Action)]()
        { Test->AddInfo(Name + TEXT(" / ") + Label); Action(); return EStepResult::Done; });
    }
    void Wait(const FString& Label, TFunction<bool()> Predicate, double Budget = 5)
    {
        Steps.Add([this, Label, Predicate = MoveTemp(Predicate), Budget]()
        {
            if (Predicate()) { return EStepResult::Done; }
            if (FPlatformTime::Seconds() - StepStarted > Budget) { Check(false, Label + TEXT(" timed out")); return EStepResult::Done; }
            return EStepResult::Wait;
        });
    }
    void Input(const FString& Label, TFunction<void(IAsyncActionSequence&)> Actions)
    {
        Steps.Add([this, Label, Actions = MoveTemp(Actions)]()
        {
            if (!Future.IsValid())
            {
                Sequence = Driver->CreateSequence(); Actions(Sequence->Actions());
                Future = MakeUnique<TAsyncResult<bool>>(Sequence->Perform());
                return EStepResult::Wait;
            }
            if (!Future->GetFuture().IsReady())
            {
                if (FPlatformTime::Seconds() - StepStarted > 5) { Check(false, Label + TEXT(" driver future incomplete after5s")); }
                return EStepResult::Wait;
            }
            Check(Future->GetFuture().Get(), Label + TEXT(" driver sequence completed successfully"));
            Future.Reset(); Sequence.Reset(); return EStepResult::Done;
        });
    }
    void MoveToModel(const FString& Id)
    {
        Do(TEXT("derive projected model screen position"), [this, Id]() { Check(World->ModelScreenPoint(Id, A), TEXT("Project ") + Id); });
        Input(TEXT("driver move to model"), [this](IAsyncActionSequence& S) { S.MoveToPosition(A); });
    }
    void ClickModel(const FString& Id)
    {
        MoveToModel(Id);
        Input(TEXT("driver completed primary click"), [](IAsyncActionSequence& S) { S.Click(EMouseButtons::Left); });
    }
    void Control(const FString& Id)
    {
        Do(TEXT("derive control geometry"), [this, Id]() { Check(World->ControlScreenPoint(Id, B), TEXT("Resolve ") + Id); });
        Input(TEXT("driver move to control"), [this](IAsyncActionSequence& S) { S.MoveToPosition(B); });
    }
    void Capture(const FString& Filename)
    {
        // These waits span real game/render ticks, then the engine's processed
        // notification and actual PNG header are required; request != completion.
        Input(TEXT("settle camera/render frames"), [](IAsyncActionSequence& S) { S.Wait(FTimespan::FromSeconds(0.2)); });
        Do(TEXT("request named PNG"), [this, Filename]() { Check(World->RequestProofScreenshot(Filename), TEXT("Request ") + Filename); });
        Wait(TEXT("actual screenshot processed and file present: ") + Filename, [this, Filename]() { return World->IsScreenshotComplete(Filename); }, 10);
    }
    void RetainIntent()
    {
        Do(TEXT("retain raw local intent bytes"), [this]()
        {
            Check(World->GetPolicy().Snapshot().SelectedIntent.IsSet(), TEXT("Local selection exists"));
            Intent = SerializeLocalIntent(World->GetPolicy().Snapshot());
            Picks = World->WorldPickCount(); Cameras = World->CameraMutationCount();
        });
    }
    void AssertIntent()
    {
        Check(SerializeLocalIntent(World->GetPolicy().Snapshot()) == Intent, TEXT("Raw ID/domainXYZ/facing intent bytes unchanged"));
        Check(World->WorldPickCount() == Picks, TEXT("No extra world selection"));
    }
    bool ObserveGeometry()
    {
        const UGameViewportClient* Client = World->GetWorld()->GetGameViewport();
        const TSharedPtr<SViewport> Viewport = Client ? Client->GetGameViewportWidget() : nullptr;
        const TSharedPtr<SWidget> Focus = FSlateApplication::Get().GetKeyboardFocusedWidget();
        if (!Check(Viewport.IsValid() && Focus.IsValid(), TEXT("Actual viewport and keyboard-focused Slate widgets exist"))) { return false; }
        if (!Check(Focus->GetTypeAsString() == TEXT("SE02ProofSurface") && Focus->HasKeyboardFocus(), TEXT("Measure actual focused proof surface"))) { return false; }
        return Check(ViewBasis.Read(Viewport->GetCachedGeometry()) && SurfaceBasis.Read(Focus->GetCachedGeometry()),
            TEXT("Actual full viewport and logical surface have invertible measured screen bases"));
    }
    FVector2D IndependentViewportPixel(const FVector2D& Screen) const
    {
        const FVector2D Local = ViewBasis.ToLocal(Screen);
        const FIntPoint Extent = World->GetProofViewportSize();
        return FVector2D(Local.X * Extent.X / ViewBasis.LocalSize.X, Local.Y * Extent.Y / ViewBasis.LocalSize.Y);
    }
    bool IndependentCircleScreen(FVector2D& Screen)
    {
        if (!ObserveGeometry()) { return false; }
        const FFixture& Fixture = World->GetFixture();
        const FFootprint* Circle = Fixture.Models.FindByPredicate([](const FFootprint& M) { return M.Id == TEXT("e02-circle"); });
        if (!Check(Circle && Circle->Kind == EShapeKind::Circle && Circle->Pose.IsSet() && Circle->RadiusInches.IsSet(), TEXT("Frozen circle is defined"))) { return false; }
        if (!Check(Circle->Pose->PositionInches.Equals(FVector3d(8, 18, -2), 1e-10) && Circle->RadiusInches.GetValue() == 1 &&
            Circle->QueryHeightInches == 1.2 && Fixture.Frame.CenterInches.Equals(FVector2d(24, 31), 1e-10) && Fixture.Frame.DatumInches == -2,
            TEXT("Independent ray expectation uses exact frozen circle and table datum"))) { return false; }
        // Explicit fixture arithmetic, independent of DomainToWorld/ModelScreenPoint.
        const double Angle = FMath::DegreesToRadians(23.0), C = FMath::Cos(Angle), S = FMath::Sin(Angle);
        const double X = 2.54 * (8.0 - 24.0), Y = -2.54 * (18.0 - 31.0), Z = 2.54 * (-0.8 + 2.0);
        const FVector WorldTop(137.0 + C * X - S * Y, -83.0 + S * X + C * Y, 41.0 + Z);
        APlayerController* Controller = World->GetWorld()->GetFirstPlayerController();
        FVector2D Pixel;
        if (!Check(Controller && Controller->ProjectWorldLocationToScreen(WorldTop, Pixel), TEXT("Actual camera projects independently constructed circle top"))) { return false; }
        const FIntPoint Extent = World->GetProofViewportSize();
        Screen = QuantizedPhysical(ViewBasis.ToScreen(FVector2D(Pixel.X * ViewBasis.LocalSize.X / Extent.X,
            Pixel.Y * ViewBasis.LocalSize.Y / Extent.Y)));
        return true;
    }
    void AddLogicalOrbitProbe(bool bTextChord = false)
    {
        Do(TEXT("measure real Slate basis and quantized logical drag probes"), [this]()
        {
            if (!IndependentCircleScreen(ProbeStart)) { return; }
            const FVector2D StartLogical = SurfaceBasis.ToLocal(ProbeStart);
            ProbeBelow = QuantizedPhysical(SurfaceBasis.ToScreen(StartLogical + FVector2D(3, 0)));
            ProbeAbove = QuantizedPhysical(SurfaceBasis.ToScreen(StartLogical + FVector2D(8, 0)));
            const FVector2D Below = SurfaceBasis.ToLocal(ProbeBelow) - StartLogical;
            const FVector2D Above = SurfaceBasis.ToLocal(ProbeAbove) - StartLogical;
            Check(World->GetFixture().Camera.DragThresholdLogicalUnits == 4 && World->GetFixture().Camera.OrbitDegreesPerLogicalUnit == 0.25,
                TEXT("Frozen four-logical-unit threshold and quarter-degree orbit increment"));
            Check(Below.Size() > 0 && Below.Size() < 4 && Above.Size() >= 4, TEXT("Quantized physical samples straddle the strict logical threshold"));
            ProbeCameras = World->CameraMutationCount(); ProbePicks = World->WorldPickCount();
            ProbeHudActivations = World->GetPolicy().Snapshot().HudActivationCount;
            bProbeTextEditing = World->GetPolicy().Snapshot().bTextEditing;
            const auto Camera = World->Snapshot()->GetObjectField(TEXT("camera"));
            ProbeAzimuth = Camera->GetNumberField(TEXT("azimuthDegrees")); ProbeElevation = Camera->GetNumberField(TEXT("elevationDegrees"));
        });
        Input(TEXT("driver starts quantized orbit gesture"), [this](IAsyncActionSequence& S) { S.MoveToPosition(ProbeStart).Press(EMouseButtons::Right); });
        Do(TEXT("real press sample agrees with independent geometry"), [this]()
        {
            const auto& Capture = World->GetPolicy().Snapshot().Capture;
            if (!Check(Capture.IsSet() && Capture->Owner == EInputOwner::Orbit && Capture->Button == EPointerButton::Secondary, TEXT("Real Slate secondary press owns orbit capture"))) { return; }
            ProbeCaptureGeneration = Capture->Generation;
            Check(Capture->Start.ScreenPhysical.Equals(ProbeStart, 1e-4) && Capture->Start.Logical.Equals(SurfaceBasis.ToLocal(ProbeStart), 1e-3),
                TEXT("Physical press and independently inverted logical press agree"));
        });
        Input(TEXT("driver moves below four logical units"), [this](IAsyncActionSequence& S) { S.MoveToPosition(ProbeBelow); });
        Do(TEXT("below-threshold displacement is logical and camera stays fixed"), [this]() { AssertOrbitProbe(false); });
        Input(TEXT("driver moves above four logical units"), [this](IAsyncActionSequence& S) { S.MoveToPosition(ProbeAbove); });
        Do(TEXT("above-threshold exact logical displacement changes orbit"), [this, bTextChord]()
        {
            AssertOrbitProbe(true); Check(World->ControlScreenPoint(bTextChord ? TEXT("text") : TEXT("button"), B), TEXT("HUD crossing position")); B = QuantizedPhysical(B);
        });
        Input(TEXT("captured orbit crosses HUD"), [this](IAsyncActionSequence& S) { S.MoveToPosition(B); });
        Do(TEXT("HUD crossing retains original capture owner"), [this]()
        {
            const auto& Capture = World->GetPolicy().Snapshot().Capture;
            Check(Capture.IsSet() && Capture->Generation == ProbeCaptureGeneration && Capture->Owner == EInputOwner::Orbit && Capture->Button == EPointerButton::Secondary && Capture->Last.ScreenPhysical.Equals(B, 1e-4) &&
                World->GetPolicy().Snapshot().HudActivationCount == ProbeHudActivations && World->WorldPickCount() == ProbePicks,
                TEXT("Actual pointer over HUD retains press generation and orbit owner"));
        });
        if (bTextChord)
        {
            Input(TEXT("press primary over text while secondary remains held"), [](IAsyncActionSequence& S) { S.Press(EMouseButtons::Left); });
            Do(TEXT("additional primary press retains secondary gesture"), [this]() { AssertTextChordCapture(); });
            Input(TEXT("release only primary over text"), [](IAsyncActionSequence& S) { S.Release(EMouseButtons::Left); });
            Do(TEXT("primary release cannot end secondary gesture or enter text"), [this]() { AssertTextChordCapture(); });
        }
        Input(TEXT("captured orbit releases over HUD"), [](IAsyncActionSequence& S) { S.Release(EMouseButtons::Right); });
        Do(TEXT("orbit retains owner through HUD and ends without selection"), [this]()
        {
            Check(!World->GetPolicy().Snapshot().Capture.IsSet() && World->GetPolicy().Snapshot().HudActivationCount == ProbeHudActivations &&
                World->WorldPickCount() == ProbePicks, TEXT("Captured HUD crossing cannot leak activation or world pick"));
        });
        Input(TEXT("reset orbit through real key route"), [](IAsyncActionSequence& S) { S.Type(EKeys::R); });
        Do(TEXT("reset leaves frozen camera defaults"), [this]()
        {
            const auto C = World->Snapshot()->GetObjectField(TEXT("camera"));
            Check(C->GetNumberField(TEXT("azimuthDegrees")) == World->GetFixture().Camera.DefaultAzimuthDegrees &&
                C->GetNumberField(TEXT("elevationDegrees")) == World->GetFixture().Camera.DefaultElevationDegrees, TEXT("Driver reset restored azimuth and elevation"));
        });
    }
    void AssertTextChordCapture()
    {
        const auto& State = World->GetPolicy().Snapshot();
        Check(State.Capture.IsSet() && State.Capture->Owner == EInputOwner::Orbit && State.Capture->Button == EPointerButton::Secondary &&
            State.Capture->Generation == ProbeCaptureGeneration && State.CaptureGeneration == ProbeCaptureGeneration &&
            State.bTextEditing == bProbeTextEditing && State.Capture->Last.ScreenPhysical.Equals(B, 1e-4),
            TEXT("Real Driver chord preserves original owner/button/generation and text state"));
        Check(World->WorldPickCount() == ProbePicks && State.HudActivationCount == ProbeHudActivations,
            TEXT("Additional button activity over text cannot select or activate HUD"));
    }
    void AssertOrbitProbe(bool bAbove)
    {
        const auto& Capture = World->GetPolicy().Snapshot().Capture;
        if (!Check(Capture.IsSet() && Capture->Generation == ProbeCaptureGeneration && Capture->Owner == EInputOwner::Orbit,
            TEXT("Same real press generation retains orbit ownership"))) { return; }
        const FVector2D Screen = bAbove ? ProbeAbove : ProbeBelow;
        const FVector2D Expected = SurfaceBasis.ToLocal(Screen) - SurfaceBasis.ToLocal(ProbeStart);
        const FVector2D Actual = Capture->Last.Logical - Capture->Start.Logical;
        Check(Capture->Last.ScreenPhysical.Equals(Screen, 1e-4) && Actual.Equals(Expected, 1e-3), TEXT("Actual logical displacement matches independently measured physical-to-logical basis"));
        Check(bAbove ? (Actual.Size() >= 4 && Capture->bDragged) : (Actual.Size() > 0 && Actual.Size() < 4 && !Capture->bDragged),
            TEXT("Actual capture obeys strict four-logical-unit threshold"));
        const auto Camera = World->Snapshot()->GetObjectField(TEXT("camera"));
        const double ExpectedAzimuth = ProbeAzimuth - (bAbove ? Expected.X * 0.25 : 0);
        const double ExpectedElevation = ProbeElevation + (bAbove ? Expected.Y * 0.25 : 0);
        Check(FMath::Abs(Camera->GetNumberField(TEXT("azimuthDegrees")) - ExpectedAzimuth) <= 1e-3 &&
            FMath::Abs(Camera->GetNumberField(TEXT("elevationDegrees")) - ExpectedElevation) <= 1e-3,
            TEXT("Actual camera follows independent logical delta at frozen orbit increment without double DPI"));
        Check(bAbove ? World->CameraMutationCount() > ProbeCameras : World->CameraMutationCount() == ProbeCameras,
            TEXT("Camera mutation occurs only above threshold"));
        Test->AddInfo(FString::Printf(TEXT("%s: extent=%dx%d uiScale=%.3f logicalDelta=(%.9f,%.9f) independentDelta=(%.9f,%.9f) basisX=(%.9f,%.9f) basisY=(%.9f,%.9f) azimuth=%.9f expected=%.9f"),
            *Name, World->GetProofViewportSize().X, World->GetProofViewportSize().Y, World->GetProofUiScale(), Actual.X, Actual.Y, Expected.X, Expected.Y,
            SurfaceBasis.X.X, SurfaceBasis.X.Y, SurfaceBasis.Y.X, SurfaceBasis.Y.Y,
            Camera->GetNumberField(TEXT("azimuthDegrees")), ExpectedAzimuth));
    }
    bool ActualViewMatches(double ExpectedAzimuth, double ExpectedElevation) const
    {
        APlayerController* Controller = World->GetWorld()->GetFirstPlayerController();
        UGameViewportClient* Client = World->GetWorld()->GetGameViewport();
        if (!Controller || !Controller->GetLocalPlayer() || !Client || !Client->Viewport) { return false; }
        FSceneViewProjectionData Data;
        if (!Controller->GetLocalPlayer()->GetProjectionData(Client->Viewport, Data)) { return false; }
        const auto Camera = World->Snapshot()->GetObjectField(TEXT("camera"));
        const FVector3d ActorPosition = JsonVector3(Camera, TEXT("positionWorldCm"));
        const FVector3d ActorRotation = JsonVector3(Camera, TEXT("rotationDegrees"));
        FVector ViewPosition; FRotator ViewRotation;
        Controller->GetPlayerViewPoint(ViewPosition, ViewRotation);
        const double A = FMath::DegreesToRadians(ExpectedAzimuth), E = FMath::DegreesToRadians(ExpectedElevation), Placement = FMath::DegreesToRadians(23.0);
        const FVector3d Back(FMath::Cos(E) * FMath::Cos(A), FMath::Cos(E) * FMath::Sin(A), FMath::Sin(E));
        const FVector3d ExpectedForward(-(FMath::Cos(Placement) * Back.X - FMath::Sin(Placement) * Back.Y),
            -(FMath::Sin(Placement) * Back.X + FMath::Cos(Placement) * Back.Y), -Back.Z);
        return FVector3d::Distance(ViewPosition, ActorPosition) <= 1e-3 && FVector3d::Distance(Data.ViewOrigin, ActorPosition) <= 1e-3 &&
            ViewRotation.Equals(FRotator(ActorRotation.X, ActorRotation.Y, ActorRotation.Z), 1e-3) && ViewRotation.Vector().Equals(ExpectedForward, 1e-5);
    }
    void AddFrameCommand(bool bSelection)
    {
        Input(TEXT("Driver establishes changed azimuth0 elevation85 before framing"), [](IAsyncActionSequence& S)
        {
            S.Type(EKeys::R);
            for (int32 I = 0; I != 18; ++I) { S.Type(EKeys::Right); }
            for (int32 I = 0; I != 8; ++I) { S.Type(EKeys::Up); }
        });
        Wait(TEXT("actual changed actor/projection view before frame command"), [this]()
        {
            const auto Camera = World->Snapshot()->GetObjectField(TEXT("camera"));
            return Camera->GetNumberField(TEXT("azimuthDegrees")) == 0 && Camera->GetNumberField(TEXT("elevationDegrees")) == 85 && ActualViewMatches(0, 85);
        });
        Do(TEXT("retain pre-frame event/generation and actual actor view"), [this]()
        {
            const auto Snapshot = World->Snapshot(); const auto Camera = Snapshot->GetObjectField(TEXT("camera"));
            FrameBeforeGeneration = static_cast<uint64>(Camera->GetNumberField(TEXT("frameGeneration")));
            FrameBeforePaint = static_cast<uint64>(Snapshot->GetObjectField(TEXT("paint"))->GetNumberField(TEXT("generation")));
            FrameBeforeEvents = World->EventCount();
            FrameBeforeActorPosition = JsonVector3(Camera, TEXT("positionWorldCm")); FrameBeforeActorRotation = JsonVector3(Camera, TEXT("rotationDegrees"));
            Check(ActualViewMatches(0, 85), TEXT("Independent actual player/projection observes changed orbit before real F/G"));
        });
        Input(bSelection ? TEXT("real Driver G frame-selection command") : TEXT("real Driver F frame-board command"), [bSelection](IAsyncActionSequence& S)
        { S.Type(bSelection ? EKeys::G : EKeys::F); });
        Wait(TEXT("fresh frame event and actual projected default-angle view"), [this, bSelection]()
        {
            const auto Camera = World->Snapshot()->GetObjectField(TEXT("camera"));
            const bool bActorChanged = !JsonVector3(Camera, TEXT("positionWorldCm")).Equals(FrameBeforeActorPosition, 1e-3) ||
                !JsonVector3(Camera, TEXT("rotationDegrees")).Equals(FrameBeforeActorRotation, 1e-3);
            return Camera->GetNumberField(TEXT("frameGeneration")) > FrameBeforeGeneration && Camera->GetNumberField(TEXT("frameEventSequence")) > FrameBeforeEvents &&
                Camera->GetStringField(TEXT("frameKind")) == (bSelection ? TEXT("selection") : TEXT("board")) && bActorChanged &&
                Camera->GetNumberField(TEXT("azimuthDegrees")) == World->GetFixture().Camera.DefaultAzimuthDegrees &&
                Camera->GetNumberField(TEXT("elevationDegrees")) == World->GetFixture().Camera.DefaultElevationDegrees &&
                ActualViewMatches(World->GetFixture().Camera.DefaultAzimuthDegrees, World->GetFixture().Camera.DefaultElevationDegrees);
        });
        Do(TEXT("independent projected descriptor-box framing assertions"), [this, bSelection]() { AssertFramedBounds(bSelection); });
    }
    void AssertFramedBounds(bool bSelection)
    {
        if (!ObserveGeometry()) { return; }
        const auto Snapshot = World->Snapshot(), Paint = Snapshot->GetObjectField(TEXT("paint")), Camera = Snapshot->GetObjectField(TEXT("camera"));
        const auto& Presentation = World->GetFixture().Presentation;
        const FVector2D HudMin = SurfaceBasis.ToScreen(Presentation.HudBoundsLogical.Min), HudMax = SurfaceBasis.ToScreen(Presentation.HudBoundsLogical.Max);
        const FVector2D HeaderMin = SurfaceBasis.ToScreen(FVector2D::ZeroVector);
        const FVector2D HeaderMax = SurfaceBasis.ToScreen(FVector2D(SurfaceBasis.LocalSize.X, Presentation.HeaderHeightLogical));
        const FVector4d PaintedHud = JsonRect4(Paint, TEXT("hudScreenPhysical")), PaintedHeader = JsonRect4(Paint, TEXT("headerScreenPhysical"));
        Check(FVector2D(PaintedHud.X, PaintedHud.Y).Equals(HudMin, 1e-3) && FVector2D(PaintedHud.Z, PaintedHud.W).Equals(HudMax, 1e-3) &&
            FVector2D(PaintedHeader.X, PaintedHeader.Y).Equals(HeaderMin, 1e-3) && FVector2D(PaintedHeader.Z, PaintedHeader.W).Equals(HeaderMax, 1e-3),
            TEXT("Actually painted HUD/header agree with independently measured Slate basis and frozen logical rectangles"));
        Check(Paint->GetBoolField(TEXT("axisAligned")) && Paint->GetNumberField(TEXT("viewportWidth")) == World->GetProofViewportSize().X &&
            Paint->GetNumberField(TEXT("viewportHeight")) == World->GetProofViewportSize().Y && Paint->GetNumberField(TEXT("uiScale")) == World->GetProofUiScale(),
            TEXT("Framing uses actual matching painted viewport and scale"));
        Check(Camera->GetNumberField(TEXT("frameGeneration")) == FrameBeforeGeneration + 1 && Camera->GetNumberField(TEXT("framePaintGeneration")) >= FrameBeforePaint &&
            Camera->GetNumberField(TEXT("framePaintGeneration")) <= Paint->GetNumberField(TEXT("generation")) &&
            Camera->GetNumberField(TEXT("frameEventSequence")) > FrameBeforeEvents && Camera->GetNumberField(TEXT("frameEventSequence")) <= World->EventCount(),
            TEXT("This real frame command owns a fresh generation/event bound to actual paint"));
        APlayerController* Controller = World->GetWorld()->GetFirstPlayerController();
        UGameViewportClient* Client = World->GetWorld()->GetGameViewport();
        FSceneViewProjectionData Data;
        if (!Check(Controller && Controller->GetLocalPlayer() && Client && Client->Viewport &&
            Controller->GetLocalPlayer()->GetProjectionData(Client->Viewport, Data) && Data.IsValidViewRectangle(), TEXT("Actual constrained view data exists for independent bounds projection"))) { return; }
        const FIntRect Rect = Data.GetConstrainedViewRect();
        const FVector2D HudPixelMax = IndependentViewportPixel(HudMax), HeaderPixelMax = IndependentViewportPixel(HeaderMax);
        const FVector4d Free(FMath::Max(static_cast<double>(Rect.Min.X), HudPixelMax.X) + 16,
            FMath::Max(static_cast<double>(Rect.Min.Y), HeaderPixelMax.Y) + 16, Rect.Max.X - 16, Rect.Max.Y - 16);
        Check(Free.Z > Free.X && Free.W > Free.Y, TEXT("Independent physical16pixel-inset unobscured rectangle has positive area"));
        // These are independent expected boxes for the immutable fixture, not production fitting output.
        const FVector3d Min = bSelection ? FVector3d(7, 17, -2) : FVector3d(-12, 7, -2.3);
        const FVector3d Max = bSelection ? FVector3d(9, 19, -0.8) : FVector3d(60, 55, 3.5);
        const double Angle = FMath::DegreesToRadians(23.0), C = FMath::Cos(Angle), S = FMath::Sin(Angle);
        auto IndependentWorld = [C, S](const FVector3d& P)
        {
            const FVector3d Q(2.54 * (P.X - 24), -2.54 * (P.Y - 31), 2.54 * (P.Z + 2));
            return FVector3d(137 + C * Q.X - S * Q.Y, -83 + S * Q.X + C * Q.Y, 41 + Q.Z);
        };
        FVector ViewPosition; FRotator ViewRotation; Controller->GetPlayerViewPoint(ViewPosition, ViewRotation);
        const double Near = Data.GetNearPlaneFromProjectionMatrix();
        Check(Near > 0 && FMath::IsFinite(Near), TEXT("Independent corner depths use actual positive near plane"));
        for (int32 Bits = 0; Bits != 8; ++Bits)
        {
            const FVector3d P = IndependentWorld(FVector3d(Bits & 1 ? Max.X : Min.X, Bits & 2 ? Max.Y : Min.Y, Bits & 4 ? Max.Z : Min.Z));
            const double Depth = FVector3d::DotProduct(P - ViewPosition, ViewRotation.Vector());
            FVector2D Pixel; const bool bProjected = Controller->ProjectWorldLocationToScreen(P, Pixel);
            Check(Depth > Near && bProjected && Pixel.X >= Free.X - 1e-2 && Pixel.X <= Free.Z + 1e-2 && Pixel.Y >= Free.Y - 1e-2 && Pixel.Y <= Free.W + 1e-2,
                FString::Printf(TEXT("Descriptor box corner%d lies beyond near plane and inside independently derived unobscured physical region"), Bits));
        }
        FVector2D CenterPixel;
        const bool bCenterProjected = Controller->ProjectWorldLocationToScreen(IndependentWorld((Min + Max) * 0.5), CenterPixel);
        const double CenterError = FVector2D::Distance(CenterPixel, FVector2D((Free.X + Free.Z) * 0.5, (Free.Y + Free.W) * 0.5));
        Check(bCenterProjected && CenterError <= 1, TEXT("Independent descriptor-box center lands within one physical pixel of unobscured region center"));
        const double Distance = Camera->GetNumberField(TEXT("distanceCm"));
        if (bSelection)
        {
            Check(World->GetPolicy().Snapshot().SelectedIntent.IsSet() && World->GetPolicy().Snapshot().SelectedIntent->ModelId == TEXT("e02-circle") &&
                Distance == World->GetFixture().Camera.FrameSelectionDistanceCm && Distance == 85 && Distance < BoardFrameDistance,
                TEXT("G fits the selected circle at unchanged85cm hint and is closer than board framing"));
        }
        else { BoardFrameDistance = Distance; Check(Distance >= 320 && Distance <= 550, TEXT("F respects unchanged board hint and distance bound")); }
        Check(SerializeLocalIntent(World->GetPolicy().Snapshot()) == Intent, TEXT("F/G preserve exact raw local advisory intent"));
        Test->AddInfo(FString::Printf(TEXT("%s: frame=%s extent=%dx%d uiScale=%.3f distanceCm=%.9f centerErrorPhysicalPixels=%.9g freeRect=(%.6f,%.6f,%.6f,%.6f)"),
            *Name, bSelection ? TEXT("selection") : TEXT("board"), World->GetProofViewportSize().X, World->GetProofViewportSize().Y,
            World->GetProofUiScale(), Distance, CenterError, Free.X, Free.Y, Free.Z, Free.W));
    }
    void BuildSteps()
    {
        if (Name == TEXT("Rendered.FiveForms"))
        {
            Do(TEXT("five real scene identities and rays"), [this]()
            {
                Check(World->GetFixture().Models.Num() == 5, TEXT("Five immutable fixture models"));
                for (const auto& M : World->GetFixture().Models)
                {
                    FVector2D Screen; FAdvisoryHit Hit; FString Diagnostic;
                    Check(World->ModelScreenPoint(M.Id, Screen), TEXT("Projected ") + M.Id);
                    Check(World->QueryScreenPoint(Screen, Hit, Diagnostic) && Hit.Id == M.Id && Hit.Kind == EHitKind::Model, TEXT("Actual world ray hits ") + M.Id);
                }
                Check(World->WriteSnapshot(TEXT("five-forms-geometry.json")), TEXT("Scene/geometry dump"));
            });
            Capture(TEXT("five-forms.png"));
        }
        else if (Name == TEXT("Rendered.RaisedPicking"))
        {
            Do(TEXT("near-top support-hole view"), [this]() { Check(World->SetProofViewElevation(85), TEXT("85-degree perspective view")); });
            Input(TEXT("wait for camera projection update"), [](IAsyncActionSequence& S) { S.Wait(FTimespan::FromSeconds(0.1)); });
            Do(TEXT("actual project/deproject support queries"), [this]()
            {
                const FVector3d Points[] = {FVector3d(27, 27, 2), FVector3d(8, 44, -2), FVector3d(35, 23, -2)};
                const FString Expected[] = {TEXT("e02-platform"), TEXT("e02-ground"), TEXT("e02-ground")};
                for (int32 I = 0; I != 3; ++I)
                {
                    double DomainError = 0, PixelError = 0; FString Id;
                    Check(World->ProjectRayRoundTrip(Points[I], DomainError, PixelError, Id), TEXT("Completed actual ray round trip"));
                    Check(Id == Expected[I], TEXT("Nearest support has expected identity"));
                    Check(DomainError <= 1e-4 && PixelError <= 1.0, TEXT("Domain <=1e-4in and projected <=1physicalpixel"));
                }
                FVector2D Outside; FAdvisoryHit Miss; FString Diagnostic;
                Check(World->DomainScreenPoint(FVector3d(60.5, 31, -2), Outside), TEXT("Project board-edge miss"));
                Check(!World->QueryScreenPoint(Outside, Miss, Diagnostic) && Diagnostic == TEXT("NoHit"), TEXT("No board clamping or invented support at outside edge"));
                Check(World->WriteSnapshot(TEXT("raised-picking-state.json")), TEXT("Ray-state dump"));
            });
            Capture(TEXT("raised-pick.png"));
        }
        else if (Name == TEXT("Rendered.MeshSubstitution"))
        {
            ClickModel(TEXT("e02-circle")); RetainIntent();
            Do(TEXT("retain analytic query before cosmetic replacement"), [this]()
            {
                FString Diagnostic; Check(World->QueryScreenPoint(A, HitBefore, Diagnostic), TEXT("Before query"));
                Check(World->WriteSnapshot(TEXT("mesh-before-state.json")), TEXT("Before identity/support descriptors"));
            });
            Capture(TEXT("mesh-before.png"));
            Do(TEXT("ordinary mesh replaces only visual branch"), [this]() { Check(World->SetCubeSubstitution(TEXT("e02-circle"), true), TEXT("Ordinary engine cube visual")); });
            Capture(TEXT("mesh-after.png"));
            Do(TEXT("identical intent and analytic hit after replacement"), [this]()
            {
                FAdvisoryHit HitAfter; FString Diagnostic; Check(World->QueryScreenPoint(A, HitAfter, Diagnostic), TEXT("After query"));
                Check(HitAfter.Id == HitBefore.Id && HitAfter.Kind == HitBefore.Kind && HitAfter.DomainPosition.Equals(HitBefore.DomainPosition, 1e-9), TEXT("Same query descriptor/identity/domain hit"));
                AssertIntent(); Check(World->WriteSnapshot(TEXT("mesh-after-state.json")), TEXT("After identity/support descriptors"));
            });
        }
        else if (Name == TEXT("Rendered.ObliqueNormals"))
        {
            Do(TEXT("oblique perspective"), [this]() { Check(World->SetProofViewElevation(25), TEXT("25-degree camera")); }); Capture(TEXT("oblique.png"));
            Do(TEXT("near-top perspective"), [this]() { Check(World->SetProofViewElevation(85), TEXT("85-degree camera")); }); Capture(TEXT("near-top.png"));
            Do(TEXT("perspective retained"), [this]() { Check(World->Snapshot()->GetBoolField(TEXT("perspective")), TEXT("No orthographic substitute")); });
        }
        else if (Name == TEXT("Input.CompletedClick"))
        {
            Do(TEXT("retain initial counters"), [this]() { Picks = World->WorldPickCount(); Cameras = World->CameraMutationCount(); });
            MoveToModel(TEXT("e02-circle"));
            Input(TEXT("primary press"), [](IAsyncActionSequence& S) { S.Press(EMouseButtons::Left); });
            Do(TEXT("press/hover cannot select"), [this]() { Check(!World->GetPolicy().Snapshot().SelectedIntent.IsSet() && World->WorldPickCount() == Picks, TEXT("No selection on press")); });
            Input(TEXT("primary release"), [](IAsyncActionSequence& S) { S.Release(EMouseButtons::Left); });
            Do(TEXT("one completed-click selection"), [this]()
            { Check(World->GetPolicy().Snapshot().SelectedIntent.IsSet() && World->GetPolicy().Snapshot().SelectedIntent->ModelId == TEXT("e02-circle") && World->WorldPickCount() == Picks + 1, TEXT("Exactly one ray selection on release")); });
            MoveToModel(TEXT("e02-capsule"));
            Input(TEXT("primary drag suppresses click"), [this](IAsyncActionSequence& S) { S.Press(EMouseButtons::Left).MoveToPosition(A + FVector2D(12, 0)).Release(EMouseButtons::Left); });
            Do(TEXT("no drag selection"), [this]() { Check(World->WorldPickCount() == Picks + 1 && World->GetPolicy().Snapshot().SelectedIntent->ModelId == TEXT("e02-circle") && World->CameraMutationCount() == Cameras, TEXT("Hover/drag did not select or move camera")); });
        }
        else if (Name == TEXT("Input.CameraCapture"))
        {
            AddLogicalOrbitProbe(true);
        }
        else if (Name == TEXT("Input.PanDollyFrame"))
        {
            ClickModel(TEXT("e02-circle")); RetainIntent();
            Input(TEXT("middle pan"), [this](IAsyncActionSequence& S) { S.Press(EMouseButtons::Middle).MoveToPosition(A + FVector2D(20, 10)).Release(EMouseButtons::Middle); });
            Input(TEXT("viewport wheel then camera keys"), [](IAsyncActionSequence& S)
            { S.ScrollBy(1).Type(EKeys::Left).Type(EKeys::Up); });
            AddFrameCommand(false); AddFrameCommand(true);
            Input(TEXT("Driver reset after independently checked frame commands"), [](IAsyncActionSequence& S) { S.Type(EKeys::R); });
            Do(TEXT("camera-only operations preserve domain"), [this]()
            {
                AssertIntent(); Check(World->CameraMutationCount() >= Cameras + 7, TEXT("Pan/dolly/frame-board/frame-selection/keyboard/reset actual effects"));
                const auto C = World->Snapshot()->GetObjectField(TEXT("camera"));
                Check(C->GetNumberField(TEXT("azimuthDegrees")) == World->GetFixture().Camera.DefaultAzimuthDegrees && C->GetNumberField(TEXT("distanceCm")) == World->GetFixture().Camera.DefaultDistanceCm, TEXT("Reset restored frozen focus and camera defaults"));
            });
        }
        else if (Name == TEXT("Input.HudExclusion"))
        {
            Do(TEXT("initial counters"), [this]() { Picks = World->WorldPickCount(); Cameras = World->CameraMutationCount(); Check(World->ModelScreenPoint(TEXT("e02-circle"), A), TEXT("Outside HUD position")); });
            Control(TEXT("button"));
            Input(TEXT("button release outside cancels"), [this](IAsyncActionSequence& S) { S.Press(EMouseButtons::Left).MoveToPosition(A).Release(EMouseButtons::Left); });
            Control(TEXT("disabled")); Input(TEXT("disabled click consumed"), [](IAsyncActionSequence& S) { S.Click(); });
            Control(TEXT("blank")); Input(TEXT("blank click/wheel consumed"), [](IAsyncActionSequence& S) { S.Click().ScrollBy(2); });
            Control(TEXT("scroll")); Input(TEXT("wheel at scroll limit remains consumed"), [](IAsyncActionSequence& S) { S.ScrollBy(20).ScrollBy(-20); });
            Do(TEXT("all HUD exclusion cases"), [this]() { Check(World->GetPolicy().Snapshot().HudActivationCount == 0 && World->WorldPickCount() == Picks && World->CameraMutationCount() == Cameras, TEXT("Canceled/disabled/blank/scroll do not leak selection/dolly")); });
        }
        else if (Name == TEXT("Input.ModalText"))
        {
            Do(TEXT("initial counters"), [this]() { Picks = World->WorldPickCount(); Cameras = World->CameraMutationCount(); EditedBefore = World->Snapshot()->GetStringField(TEXT("editedText")); });
            Input(TEXT("open modal through key route"), [](IAsyncActionSequence& S) { S.Type(EKeys::M); });
            Control(TEXT("modal-text")); Input(TEXT("focus and edit real Slate text route"), [](IAsyncActionSequence& S) { S.Click().Type(TEXT("E02")).Type(EKeys::Enter); });
            Do(TEXT("text/Enter consumes shortcuts"), [this]() { Check(World->IsModalOpen() && World->IsTextFocused() && World->Snapshot()->GetStringField(TEXT("editedText")) == EditedBefore + TEXT("E02") && World->GetPolicy().Snapshot().ConfirmAttempts == 0 && World->CameraMutationCount() == Cameras, TEXT("Actual Slate focus/characters; Enter caused no camera/Confirm leakage")); });
            Input(TEXT("first Escape cancels edit"), [](IAsyncActionSequence& S) { S.Type(EKeys::Escape); });
            Do(TEXT("modal remains after edit cancellation"), [this]() { Check(!World->IsTextFocused() && World->IsModalOpen(), TEXT("First Escape cancels focused edit")); });
            Input(TEXT("second Escape closes modal"), [](IAsyncActionSequence& S) { S.Type(EKeys::Escape); });
            Do(TEXT("no world leakage"), [this]() { Check(!World->IsModalOpen() && World->WorldPickCount() == Picks && World->CameraMutationCount() == Cameras, TEXT("Modal closes without world shortcut/click")); });
        }
        else if (Name == TEXT("Input.CancelActivation"))
        {
            ClickModel(TEXT("e02-circle")); RetainIntent();
            Input(TEXT("local review and captured drag"), [this](IAsyncActionSequence& S) { S.Type(EKeys::Enter).Press(EMouseButtons::Right).MoveToPosition(A + FVector2D(12, 0)).Type(EKeys::Escape); });
            Do(TEXT("Escape cancels candidate"), [this]() { Check(!World->GetPolicy().Snapshot().Capture.IsSet(), TEXT("Escape released capture")); AssertIntent(); });
            Input(TEXT("release canceled physical button and recapture"), [this](IAsyncActionSequence& S) { S.Release(EMouseButtons::Right).MoveToPosition(A).Press(EMouseButtons::Right).MoveToPosition(A + FVector2D(12, 0)); });
            Do(TEXT("engine-injected deactivate"), [this]() { World->InjectActivation(false); Check(!World->GetPolicy().Snapshot().bActive && !World->GetPolicy().Snapshot().Capture.IsSet(), TEXT("Deactivation cancels capture")); });
            Do(TEXT("engine-injected reactivate"), [this]() { World->InjectActivation(true); });
            Input(TEXT("release after reactivation"), [](IAsyncActionSequence& S) { S.Release(EMouseButtons::Right); });
            Do(TEXT("renew review without synthesized click"), [this]() { AssertIntent(); Check(World->GetPolicy().Snapshot().LocalReview == ELocalReview::Editing && World->GetPolicy().Snapshot().bActive, TEXT("Reactivation retains coordinates and requires renewed review")); });
            Input(TEXT("capture loss during another real drag"), [this](IAsyncActionSequence& S) { S.MoveToPosition(A).Press(EMouseButtons::Right).MoveToPosition(A + FVector2D(12, 0)); });
            Do(TEXT("actual Slate capture loss"), [this]() { World->InjectCaptureLoss(); Check(!World->GetPolicy().Snapshot().Capture.IsSet(), TEXT("Slate capture-loss callback cancels policy")); });
            Input(TEXT("release canceled drag"), [](IAsyncActionSequence& S) { S.Release(EMouseButtons::Right); });
        }
        else if (Name == TEXT("Input.ResizeScale"))
        {
            ClickModel(TEXT("e02-circle")); RetainIntent();
            Input(TEXT("Ready gesture crossing resize"), [](IAsyncActionSequence& S) { S.Type(EKeys::Enter).Press(EMouseButtons::Right); });
            Do(TEXT("retain held capture and review generation before resize"), [this]()
            {
                const auto& State = World->GetPolicy().Snapshot();
                if (!Check(State.LocalReview == ELocalReview::Ready && State.Capture.IsSet() && State.Capture->Button == EPointerButton::Secondary,
                    TEXT("Real Ready secondary gesture is outstanding before resize"))) { return; }
                ResizeCaptureGeneration = State.CaptureGeneration; ResizeCancelGeneration = State.CancelGeneration;
                ResizeCameras = World->CameraMutationCount();
            });
            Do(TEXT("programmatic resize during capture"), [this]() { Check(World->ProgrammaticResize(FIntPoint(1600, 900)), TEXT("Owned SWindow resize")); });
            Wait(TEXT("actual1600x900 viewport observed by policy"), [this]()
            { return World->GetProofViewportSize() == FIntPoint(1600, 900) && World->GetPolicy().Snapshot().ViewportExtent == FIntPoint(1600, 900); });
            Do(TEXT("resize invalidates gesture before physical button release"), [this]()
            {
                const auto& State = World->GetPolicy().Snapshot();
                Check(!State.Capture.IsSet() && State.CaptureGeneration > ResizeCaptureGeneration && State.CancelGeneration > ResizeCancelGeneration,
                    TEXT("Resize itself cancels capture and invalidates capture/cancel generations while RMB stays held"));
                Check(State.LocalReview == ELocalReview::Editing && World->CameraMutationCount() == ResizeCameras,
                    TEXT("Resize invalidates Ready without a stale camera effect")); AssertIntent();
                Check(World->ModelScreenPoint(TEXT("e02-circle"), B), TEXT("Resolve real world screen point after resize"));
                B = QuantizedPhysical(B + FVector2D(48, 32)); ResizeHeldEvents = World->EventCount();
            });
            Input(TEXT("move physical secondary button still held after resize"), [this](IAsyncActionSequence& S) { S.MoveToPosition(B); });
            Do(TEXT("held movement cannot revive canceled resize gesture"), [this]()
            {
                const auto& State = World->GetPolicy().Snapshot();
                Check(World->EventCount() > ResizeHeldEvents && !State.Capture.IsSet() && State.CaptureGeneration > ResizeCaptureGeneration &&
                    State.CancelGeneration > ResizeCancelGeneration && World->CameraMutationCount() == ResizeCameras,
                    TEXT("Actual post-resize held movement is traced with no stale capture/camera effect"));
                Check(State.LocalReview == ELocalReview::Editing, TEXT("Held movement preserves required renewed-review state")); AssertIntent();
            });
            Input(TEXT("release after resize"), [](IAsyncActionSequence& S) { S.Release(EMouseButtons::Right); });
            Do(TEXT("release cannot revive canceled resize gesture"), [this]()
            { Check(!World->GetPolicy().Snapshot().Capture.IsSet() && World->GetPolicy().Snapshot().LocalReview == ELocalReview::Editing &&
                World->CameraMutationCount() == ResizeCameras, TEXT("Physical release remains harmless after proven cancellation")); AssertIntent(); });
            AddResizeVariant(FIntPoint(1280, 720), 1.0);
            AddResizeVariant(FIntPoint(1280, 720), 1.5);
            AddResizeVariant(FIntPoint(1600, 900), 1.0);
            Do(TEXT("restore baseline viewport and scale"), [this]() { Check(World->SetProofUiScale(1.0) && World->ProgrammaticResize(FIntPoint(1280, 720)), TEXT("Restore baseline")); });
            Wait(TEXT("actual restored1280x720"), [this]() { return World->GetProofViewportSize() == FIntPoint(1280, 720) && World->GetProofUiScale() == 1.0; });
        }
        else if (Name == TEXT("Input.RepeatedConfirm"))
        {
            ClickModel(TEXT("e02-circle")); RetainIntent();
            Input(TEXT("first Confirm local Ready"), [](IAsyncActionSequence& S) { S.Type(EKeys::Enter); });
            Do(TEXT("Ready is local only"), [this]() { Check(World->GetPolicy().Snapshot().LocalReview == ELocalReview::Ready, TEXT("Local Ready transition")); });
            Input(TEXT("repeated Confirm never submits"), [](IAsyncActionSequence& S) { S.Type(EKeys::Enter).Type(EKeys::Enter); });
            Do(TEXT("visible no-session diagnostic"), [this]() { Check(World->VisibleStatus().Contains(TEXT("ProofHasNoGameSession")), TEXT("Visible precise refusal")); });
            Input(TEXT("Escape and another review cycle"), [](IAsyncActionSequence& S) { S.Type(EKeys::Escape).Type(EKeys::Enter).Type(EKeys::Enter); });
            Do(TEXT("raw local intent retained"), [this]() { AssertIntent(); Check(World->GetPolicy().Snapshot().ConfirmAttempts == 5 && World->VisibleStatus().Contains(TEXT("ProofHasNoGameSession")), TEXT("Five actual Confirm events; no fabricated acceptance")); });
        }
        else { Do(TEXT("unknown case"), [this]() { Check(false, TEXT("Unknown registered E02 case")); }); }
        Do(TEXT("save final actual case snapshot"), [this]()
        {
            Check(FInputPolicy::CoreTransportCreations() == 0 && FInputPolicy::GameCommands() == 0 && FInputPolicy::AcceptedResults() == 0, TEXT("No transport/session/game-command/accepted-result path"));
            Check(World->EventCount() > EventBaseline || Name.StartsWith(TEXT("Rendered.")), TEXT("Input cases actually traversed Slate handlers"));
            Check(World->WriteSnapshot(TEXT("case-") + Name + TEXT(".json")) && World->WriteSnapshot(TEXT("scene.json")), TEXT("Final case and scene artifacts"));
        });
    }
    void AddResizeVariant(FIntPoint Extent, double Scale)
    {
        Do(TEXT("request resize/scale variant"), [this, Extent, Scale]() { Check(World->SetProofUiScale(Scale) && World->ProgrammaticResize(Extent), TEXT("Owned viewport variant request")); });
        Wait(TEXT("actual viewport and logical scale variant"), [this, Extent, Scale]() { return World->GetProofViewportSize() == Extent && World->GetProofUiScale() == Scale && World->GetPolicy().Snapshot().UiScale == Scale; });
        Do(TEXT("independent circle-top projection at actual viewport geometry"), [this]()
        {
            Check(IndependentCircleScreen(A), TEXT("Prepare independent quantized physical click"));
            ClickPicks = World->WorldPickCount(); ClickEvents = World->EventCount();
        });
        Input(TEXT("driver actual variant completed click"), [this](IAsyncActionSequence& S) { S.MoveToPosition(A).Click(EMouseButtons::Left); });
        Do(TEXT("fresh actual click ray and precise independent hit under resize/scale"), [this]()
        {
            Check(SerializeLocalIntent(World->GetPolicy().Snapshot()) == Intent, TEXT("Identical intended ID/XYZ/facing under variant"));
            AssertFreshCirclePick();
            Cameras = World->CameraMutationCount();
        });
        Control(TEXT("blank")); Input(TEXT("variant HUD wheel/click exclusion"), [](IAsyncActionSequence& S) { S.Click().ScrollBy(1); });
        Do(TEXT("HUD remains excluded at variant"), [this]() { Check(World->CameraMutationCount() == Cameras && SerializeLocalIntent(World->GetPolicy().Snapshot()) == Intent, TEXT("Logical HUD geometry excludes world at actual scale")); });
        AddLogicalOrbitProbe();
        AddFrameCommand(false); AddFrameCommand(true);
        Do(TEXT("variant camera gesture preserves local intent"), [this]()
        { Check(SerializeLocalIntent(World->GetPolicy().Snapshot()) == Intent && World->WorldPickCount() == ClickPicks + 1, TEXT("Exact local intent and one completed pick survive variant orbit/reset")); });
    }
    void AssertFreshCirclePick()
    {
        FPointerSample Pointer; FRay Ray; FAdvisoryHit Hit; uint64 Generation = 0, SequenceNumber = 0;
        if (!Check(World->GetLastWorldPick(Pointer, Ray, Hit, Generation, SequenceNumber), TEXT("Completed input event exposes its own actual ray/hit"))) { return; }
        Check(World->WorldPickCount() == ClickPicks + 1 && Generation == ClickPicks + 1 &&
            SequenceNumber > ClickEvents && SequenceNumber <= World->EventCount(), TEXT("Fresh ray is bound to this completed click generation and traced event sequence"));
        Check(Pointer.ScreenPhysical.Equals(A, 1e-4) && Pointer.bInsideViewport && Hit.Kind == EHitKind::Model && Hit.Id == TEXT("e02-circle"),
            TEXT("Actual completed click used prescribed quantized screen point and circle identity"));
        const FVector2D ExpectedPixel = IndependentViewportPixel(Pointer.ScreenPhysical);
        Check(Pointer.ViewportPhysical.Equals(ExpectedPixel, 1e-3), TEXT("Actual ray pixel agrees with independent full viewport basis without sidebar subtraction or double DPI"));
        const double Angle = FMath::DegreesToRadians(23.0), C = FMath::Cos(Angle), S = FMath::Sin(Angle);
        const FVector3d O = Ray.OriginWorldCm - FVector3d(137, -83, 41);
        const FVector3d D = Ray.DirectionWorldUnit;
        const FVector3d DomainOrigin(24.0 + (C * O.X + S * O.Y) / 2.54,
            31.0 - (-S * O.X + C * O.Y) / 2.54, -2.0 + O.Z / 2.54);
        const FVector3d DomainDirection((C * D.X + S * D.Y) / 2.54,
            -(-S * D.X + C * D.Y) / 2.54, D.Z / 2.54);
        if (!Check(!DomainOrigin.ContainsNaN() && !DomainDirection.ContainsNaN() && FMath::Abs(D.Size() - 1) <= 1e-6 &&
            FMath::Abs(DomainDirection.Z) > 1e-8, TEXT("Actual completed-click ray has finite unit direction crossing frozen top plane"))) { return; }
        const double DistanceCm = (-0.8 - DomainOrigin.Z) / DomainDirection.Z;
        const FVector3d ExpectedDomain = DomainOrigin + DomainDirection * DistanceCm;
        Check(DistanceCm > 0 && FMath::Square(ExpectedDomain.X - 8) + FMath::Square(ExpectedDomain.Y - 18) < 1,
            TEXT("Independent forward ray-plane intersection falls inside circle top"));
        const double DomainError = FVector3d::Distance(ExpectedDomain, Hit.DomainPosition);
        Check(DomainError <= 1e-4 && FMath::Abs(Hit.DistanceWorldCm - DistanceCm) <= 2.54e-4,
            TEXT("Actual domain hit and ray distance agree with independent top-plane solution within1e-4inch"));
        const FVector3d Q(2.54 * (ExpectedDomain.X - 24), -2.54 * (ExpectedDomain.Y - 31), 2.54 * (ExpectedDomain.Z + 2));
        const FVector3d ExpectedWorld(137 + C * Q.X - S * Q.Y, -83 + S * Q.X + C * Q.Y, 41 + Q.Z);
        Check(FVector3d::Distance(ExpectedWorld, Hit.WorldPosition) <= 2.54e-4, TEXT("Actual world hit agrees with independent fixed-frame intersection"));
        APlayerController* Controller = World->GetWorld()->GetFirstPlayerController();
        FVector2D Reprojected;
        if (!Check(Controller && Controller->ProjectWorldLocationToScreen(Hit.WorldPosition, Reprojected), TEXT("Actual camera reprojects this completed click hit"))) { return; }
        const double PixelError = FVector2D::Distance(Reprojected, ExpectedPixel);
        Check(PixelError <= 1.0, TEXT("Actual completed click hit projects back within one physical pixel at actual viewport/scale"));
        Test->AddInfo(FString::Printf(TEXT("%s: extent=%dx%d uiScale=%.3f pick=%llu event=%llu screen=(%.3f,%.3f) rayPixel=(%.6f,%.6f) domainErrorInches=%.12g roundTripPhysicalPixels=%.12g"),
            *Name, World->GetProofViewportSize().X, World->GetProofViewportSize().Y, World->GetProofUiScale(),
            static_cast<unsigned long long>(Generation), static_cast<unsigned long long>(SequenceNumber),
            Pointer.ScreenPhysical.X, Pointer.ScreenPhysical.Y, Pointer.ViewportPhysical.X, Pointer.ViewportPhysical.Y, DomainError, PixelError));
    }
    bool Finish()
    {
        if (Future.IsValid() && !Future->GetFuture().IsReady())
        {
            // The installed driver exposes no cancellation API. Do not replay or
            // claim cleanup while it is executing; wait a short genuine bound.
            if (CleanupStarted == 0) { CleanupStarted = FPlatformTime::Seconds(); }
            if (FPlatformTime::Seconds() - CleanupStarted < 5) { return false; }
            Test->AddError(Name + TEXT(": driver did not quiesce; stop this owned proof process"));
            FPlatformMisc::RequestExit(false); return false;
        }
        if (Future.IsValid())
        {
            Check(Future->GetFuture().Get(), bCleanupQueued ? TEXT("Cleanup simulated releases completed") : TEXT("Pending driver action completed during finalization"));
            Future.Reset(); Sequence.Reset();
        }
        if (bOwnsDriver && !bCleanupQueued)
        {
            bCleanupQueued = true;
            Sequence = Driver->CreateSequence();
            Sequence->Actions().Release(EMouseButtons::Left).Release(EMouseButtons::Right).Release(EMouseButtons::Middle)
                .Release(EKeys::Left).Release(EKeys::Right).Release(EKeys::Up).Release(EKeys::Down).Release(EKeys::Enter).Release(EKeys::Escape);
            Future = MakeUnique<TAsyncResult<bool>>(Sequence->Perform()); CleanupStarted = FPlatformTime::Seconds();
            return false;
        }
        if (bOwnsDriver)
        {
            if (FSlateApplication::IsInitialized()) { FSlateApplication::Get().ReleaseAllPointerCapture(); }
            Driver.Reset(); IAutomationDriverModule::Get().Disable(); bOwnsDriver = false;
            Check(!IAutomationDriverModule::Get().IsEnabled(), TEXT("Platform application/message handler restored"));
        }
        Test->AddInfo(FString::Printf(TEXT("%s: actual assertions=%d; elapsed=%.3fs; status=%s"), *Name, Assertions,
            FPlatformTime::Seconds() - Started, bFailed ? TEXT("FAIL") : TEXT("PASS")));
        if (bFailed) { FPlatformMisc::RequestExit(false); }
        return true;
    }

    FAutomationTestBase* Test;
    FString Name, Intent, EditedBefore;
    TWeakObjectPtr<AE02WorldProofGameMode> World;
    TSharedPtr<IAsyncAutomationDriver, ESPMode::ThreadSafe> Driver;
    TSharedPtr<IAsyncDriverSequence, ESPMode::ThreadSafe> Sequence;
    TUniquePtr<TAsyncResult<bool>> Future;
    TArray<TFunction<EStepResult()>> Steps;
    FVector2D A, B;
    FObservedSlateBasis ViewBasis, SurfaceBasis;
    FVector2D ProbeStart, ProbeBelow, ProbeAbove;
    FVector3d FrameBeforeActorPosition, FrameBeforeActorRotation;
    FAdvisoryHit HitBefore;
    double Started, StepStarted = 0.0, CleanupStarted = 0.0;
    uint64 Picks = 0, Cameras = 0, EventBaseline = 0;
    uint64 ProbePicks = 0, ProbeCameras = 0, ProbeHudActivations = 0, ProbeCaptureGeneration = 0, ClickPicks = 0, ClickEvents = 0;
    uint64 ResizeCaptureGeneration = 0, ResizeCancelGeneration = 0, ResizeHeldEvents = 0, ResizeCameras = 0;
    uint64 FrameBeforeGeneration = 0, FrameBeforePaint = 0, FrameBeforeEvents = 0;
    double ProbeAzimuth = 0, ProbeElevation = 0;
    double BoardFrameDistance = 0;
    int32 Index = 0, Assertions = 0;
    bool bProbeTextEditing = false;
    bool bInitialized = false, bOwnsDriver = false, bFailed = false, bCleanupQueued = false;
};

bool Enqueue(FAutomationTestBase* Test, const FString& Name)
{
    FAutomationTestFramework::Get().EnqueueLatentCommand(MakeShared<FE02CaseCommand>(Test, Name));
    return true;
}
constexpr EAutomationTestFlags Flags = EAutomationTestFlags::ClientContext | EAutomationTestFlags::NonNullRHI | EAutomationTestFlags::EngineFilter;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FE02FiveForms, "Warhammer.Migration.E02.Rendered.FiveForms", Flags)
bool FE02FiveForms::RunTest(const FString&) { return Enqueue(this, TEXT("Rendered.FiveForms")); }
IMPLEMENT_SIMPLE_AUTOMATION_TEST(FE02RaisedPicking, "Warhammer.Migration.E02.Rendered.RaisedPicking", Flags)
bool FE02RaisedPicking::RunTest(const FString&) { return Enqueue(this, TEXT("Rendered.RaisedPicking")); }
IMPLEMENT_SIMPLE_AUTOMATION_TEST(FE02MeshSubstitution, "Warhammer.Migration.E02.Rendered.MeshSubstitution", Flags)
bool FE02MeshSubstitution::RunTest(const FString&) { return Enqueue(this, TEXT("Rendered.MeshSubstitution")); }
IMPLEMENT_SIMPLE_AUTOMATION_TEST(FE02ObliqueNormals, "Warhammer.Migration.E02.Rendered.ObliqueNormals", Flags)
bool FE02ObliqueNormals::RunTest(const FString&) { return Enqueue(this, TEXT("Rendered.ObliqueNormals")); }
IMPLEMENT_SIMPLE_AUTOMATION_TEST(FE02CompletedClick, "Warhammer.Migration.E02.Input.CompletedClick", Flags)
bool FE02CompletedClick::RunTest(const FString&) { return Enqueue(this, TEXT("Input.CompletedClick")); }
IMPLEMENT_SIMPLE_AUTOMATION_TEST(FE02CameraCapture, "Warhammer.Migration.E02.Input.CameraCapture", Flags)
bool FE02CameraCapture::RunTest(const FString&) { return Enqueue(this, TEXT("Input.CameraCapture")); }
IMPLEMENT_SIMPLE_AUTOMATION_TEST(FE02PanDollyFrame, "Warhammer.Migration.E02.Input.PanDollyFrame", Flags)
bool FE02PanDollyFrame::RunTest(const FString&) { return Enqueue(this, TEXT("Input.PanDollyFrame")); }
IMPLEMENT_SIMPLE_AUTOMATION_TEST(FE02HudExclusion, "Warhammer.Migration.E02.Input.HudExclusion", Flags)
bool FE02HudExclusion::RunTest(const FString&) { return Enqueue(this, TEXT("Input.HudExclusion")); }
IMPLEMENT_SIMPLE_AUTOMATION_TEST(FE02ModalText, "Warhammer.Migration.E02.Input.ModalText", Flags)
bool FE02ModalText::RunTest(const FString&) { return Enqueue(this, TEXT("Input.ModalText")); }
IMPLEMENT_SIMPLE_AUTOMATION_TEST(FE02CancelActivation, "Warhammer.Migration.E02.Input.CancelActivation", Flags)
bool FE02CancelActivation::RunTest(const FString&) { return Enqueue(this, TEXT("Input.CancelActivation")); }
IMPLEMENT_SIMPLE_AUTOMATION_TEST(FE02ResizeScale, "Warhammer.Migration.E02.Input.ResizeScale", Flags)
bool FE02ResizeScale::RunTest(const FString&) { return Enqueue(this, TEXT("Input.ResizeScale")); }
IMPLEMENT_SIMPLE_AUTOMATION_TEST(FE02RepeatedConfirm, "Warhammer.Migration.E02.Input.RepeatedConfirm", Flags)
bool FE02RepeatedConfirm::RunTest(const FString&) { return Enqueue(this, TEXT("Input.RepeatedConfirm")); }

#endif
