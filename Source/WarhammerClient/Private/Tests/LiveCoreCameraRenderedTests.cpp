#include "Misc/AutomationTest.h"

#if WITH_DEV_AUTOMATION_TESTS && WITH_E02_AUTOMATION_DRIVER

#include "WarhammerClientGameMode.h"
#include "Migration/E02InputPolicy.h"
#include "Async/AsyncResult.h"
#include "DriverConfiguration.h"
#include "Engine/Engine.h"
#include "Engine/World.h"
#include "Framework/Application/SlateApplication.h"
#include "HAL/PlatformMisc.h"
#include "HAL/PlatformTime.h"
#include "IAutomationDriver.h"
#include "IAutomationDriverModule.h"
#include "IDriverSequence.h"
#include "InputCoreTypes.h"
#include "Misc/App.h"
#include "Misc/CommandLine.h"
#include "Misc/Parse.h"
#include "Widgets/SWidget.h"

namespace
{
enum class EInputProofStep : uint8 { Wait, Done };

/** Actual live Slate routing, with synthetic advisory camera bounds and no Core setup. */
class FLiveCameraInputCommand final : public IAutomationLatentCommand
{
public:
    explicit FLiveCameraInputCommand(FAutomationTestBase* InTest)
        : Test(InTest), Started(FPlatformTime::Seconds()) {}

    virtual ~FLiveCameraInputCommand() override
    {
        // Also restore owned state if shutdown abandons the latent command.
        Restore();
    }

    virtual bool Update() override
    {
        if (bFailed || bFinishing) { return Finish(); }
        if (FPlatformTime::Seconds() - Started > 55)
        { Check(false, TEXT("55-second live-input test budget exceeded")); return Finish(); }
        if (!bInitialized)
        {
            if (!World.IsValid() && GEngine)
            {
                for (const FWorldContext& Context : GEngine->GetWorldContexts())
                {
                    if (Context.World() && Context.World()->IsGameWorld())
                    {
                        if (auto* Mode = Cast<AWarhammerClientGameMode>(Context.World()->GetAuthGameMode()))
                        { World = Mode; break; }
                    }
                }
            }
            FLiveCoreCameraInputObservation Initial;
            if (!World.IsValid() || !World->ObserveCameraInputProofForTests(Initial) || !Points(Initial))
            {
                if (FPlatformTime::Seconds() - Started < 15) { return false; }
                Check(false, TEXT("Ordinary live GameMode and arranged camera/endpoint widgets did not become ready"));
                return Finish();
            }
            if (!Check(FApp::CanEverRender(), TEXT("A non-NullRHI game viewport is required"))) { return Finish(); }
            Baseline = Initial;
            if (!Check(Disconnected(Initial) && !Initial.bPolicyCapture && !Initial.bSlateCapture,
                TEXT("Refuse any real, busy or unknown Core session or pre-existing camera capture"))) { return Finish(); }
            FString Error;
            const bool bSetup = World->BeginCameraInputProofForTests(Error);
            if (!Check(bSetup, Error.IsEmpty() ? TEXT("Synthetic camera setup") : Error))
            { return Finish(); }
            bOwnsSetup = true;
            OriginalFocus = FSlateApplication::Get().GetKeyboardFocusedWidget();
            if (!Check(OriginalFocus.IsValid(), TEXT("Original Slate keyboard focus is available for restoration"))) { return Finish(); }
            auto& Module = IAutomationDriverModule::Get();
            if (!Check(!Module.IsEnabled(), TEXT("Do not borrow a pre-existing AutomationDriver"))) { return Finish(); }
            Module.Enable(); bOwnsDriver = Module.IsEnabled();
            if (!Check(bOwnsDriver, TEXT("AutomationDriver enabled"))) { return Finish(); }
            auto Configuration = MakeShared<FDriverConfiguration, ESPMode::ThreadSafe>();
            Configuration->ImplicitWait = FTimespan::FromSeconds(2);
            Driver = Module.CreateAsyncDriver(Configuration);
            if (!Check(Driver.IsValid(), TEXT("Owned async AutomationDriver created"))) { return Finish(); }
            bInitialized = true; BuildSteps(); StepStarted = FPlatformTime::Seconds();
            Test->AddInfo(TEXT("Synthetic/advisory bounds only; actual live GameMode/Slate input. No Core session or rendered-board fidelity proof."));
            return false;
        }
        if (!World.IsValid()) { Check(false, TEXT("Live GameMode ended during the test")); return Finish(); }
        if (Index >= Steps.Num()) { return Finish(); }
        if (Steps[Index]() == EInputProofStep::Done)
        { ++Index; StepStarted = FPlatformTime::Seconds(); }
        return false;
    }

private:
    bool Check(bool bValue, const FString& Message)
    {
        ++Assertions;
        if (!bValue)
        {
            bFailed = true;
            UE_LOG(LogTemp, Error, TEXT("Live camera input step %d: %s"), Index, *Message);
            Test->AddError(Message);
        }
        return bValue;
    }
    static bool Disconnected(const FLiveCoreCameraInputObservation& O)
    { return !O.bBusy && !O.bHasSession && !O.bUnknown && O.SessionId.IsEmpty() && O.RequestId.IsEmpty() && O.AcceptedActionCount == 0; }
    static bool SameChoices(const FLiveCoreCameraInputObservation& A, const FLiveCoreCameraInputObservation& B)
    {
        if (!A.RequestType.Equals(B.RequestType, ESearchCase::CaseSensitive) || A.Options.Num() != B.Options.Num()) { return false; }
        for (int32 I = 0; I < A.Options.Num(); ++I)
        {
            if (!A.Options[I].Id.Equals(B.Options[I].Id, ESearchCase::CaseSensitive) ||
                !A.Options[I].Label.Equals(B.Options[I].Label, ESearchCase::CaseSensitive) ||
                A.Options[I].bAvailable != B.Options[I].bAvailable) { return false; }
        }
        return true;
    }
    bool Read(FLiveCoreCameraInputObservation& O)
    {
        if (!Check(World.IsValid() && World->ObserveCameraInputProofForTests(O), TEXT("Read actual live camera observations"))) { return false; }
        return Check(Disconnected(O) && O.SessionRevision == Baseline.SessionRevision &&
            O.ProjectionRevision == Baseline.ProjectionRevision && O.ProjectionVersion == Baseline.ProjectionVersion &&
            O.ConfirmAttempts == Baseline.ConfirmAttempts && O.bHasCommandOutcome == Baseline.bHasCommandOutcome &&
            O.bCommandAccepted == Baseline.bCommandAccepted && O.bCommandCommitted == Baseline.bCommandCommitted &&
            O.LastHttpStatus == Baseline.LastHttpStatus && O.LastOutcomeCode == Baseline.LastOutcomeCode &&
            O.SessionStatus == Baseline.SessionStatus && O.SessionError == Baseline.SessionError && SameChoices(O, Baseline),
            TEXT("Available session/command state stayed unchanged; no accepted Core action"));
    }
    static bool SamePose(const FLiveCoreCameraInputObservation& A, const FLiveCoreCameraInputObservation& B)
    { return A.ActorLocation.Equals(B.ActorLocation, 1.e-3) && A.ActorRotation.Equals(B.ActorRotation, 1.e-3); }
    static bool SameNavigation(const FLiveCoreCameraInputObservation& A, const FLiveCoreCameraInputObservation& B)
    {
        return SamePose(A, B) && A.Focus.Equals(B.Focus, 1.e-3) &&
            FMath::IsNearlyEqual(A.Distance, B.Distance, 1.e-3) &&
            FMath::IsNearlyEqual(A.Azimuth, B.Azimuth, 1.e-3) && FMath::IsNearlyEqual(A.Elevation, B.Elevation, 1.e-3);
    }
    static bool WithinDistanceBounds(const FLiveCoreCameraInputObservation& O)
    {
        return FMath::IsFinite(O.Distance) && FMath::IsFinite(O.MinimumDistance) && FMath::IsFinite(O.MaximumDistance) &&
            O.MinimumDistance > 0 && O.MaximumDistance >= O.MinimumDistance &&
            O.Distance >= O.MinimumDistance - 1.e-3 && O.Distance <= O.MaximumDistance + 1.e-3;
    }
    bool Points(const FLiveCoreCameraInputObservation& O)
    {
        const auto Surface = O.Surface.Pin(), Endpoint = O.Endpoint.Pin(), Viewport = O.Viewport.Pin();
        if (!Surface.IsValid() || !Endpoint.IsValid() || !Viewport.IsValid()) { return false; }
        const FGeometry& G = Surface->GetCachedGeometry(); const FVector2D Size = G.GetLocalSize();
        const FGeometry& E = Endpoint->GetCachedGeometry(); const FVector2D EndpointSize = E.GetLocalSize();
        if (Size.X < 180 || Size.Y < 160 || EndpointSize.X < 20 || EndpointSize.Y < 10) { return false; }
        const auto Quantize = [](const FVector2D& P) { return FVector2D(FMath::RoundToInt(P.X), FMath::RoundToInt(P.Y)); };
        Board = Quantize(G.LocalToAbsolute(FVector2D(Size.X * 0.5, Size.Y * 0.5)));
        OrbitEnd = Quantize(G.LocalToAbsolute(FVector2D(Size.X * 0.5 + 32, Size.Y * 0.5 + 20)));
        PanEnd = Quantize(G.LocalToAbsolute(FVector2D(Size.X * 0.5 + 25, Size.Y * 0.5 + 18)));
        EndpointPoint = Quantize(E.LocalToAbsolute(EndpointSize * 0.5));
        const FGeometry& V = Viewport->GetCachedGeometry();
        return !Board.ContainsNaN() && !EndpointPoint.ContainsNaN() &&
            V.IsUnderLocation(Board) && V.IsUnderLocation(OrbitEnd) && V.IsUnderLocation(PanEnd) &&
            V.IsUnderLocation(EndpointPoint) && G.IsUnderLocation(Board) && G.IsUnderLocation(OrbitEnd) && G.IsUnderLocation(PanEnd);
    }
    void Do(const TCHAR* Label, TFunction<void()> Action)
    {
        Steps.Add([this, Label, Action = MoveTemp(Action)]()
        { Test->AddInfo(Label); Action(); return EInputProofStep::Done; });
    }
    void Input(const TCHAR* Label, TFunction<void(IAsyncActionSequence&)> Actions)
    {
        Steps.Add([this, Label, Actions = MoveTemp(Actions)]()
        {
            if (!Future.IsValid())
            {
                Test->AddInfo(Label);
                Sequence = Driver->CreateSequence(); Actions(Sequence->Actions());
                Future = MakeUnique<TAsyncResult<bool>>(Sequence->Perform());
                return EInputProofStep::Wait;
            }
            if (!Future->GetFuture().IsReady())
            {
                if (FPlatformTime::Seconds() - StepStarted > 5) { Check(false, TEXT("Driver action exceeded five seconds")); }
                return EInputProofStep::Wait;
            }
            Check(Future->GetFuture().Get(), TEXT("Actual AutomationDriver sequence completed"));
            Future.Reset(); Sequence.Reset(); return EInputProofStep::Done;
        });
    }
    void BuildSteps()
    {
        using Warhammer::Migration::E02::EInputOwner;
        Input(TEXT("Click the actual board surface"), [this](IAsyncActionSequence& S) { S.MoveToPosition(Board).Click(EMouseButtons::Left); });
        Do(TEXT("Observe keyboard ownership before orbit"), [this]()
        { Read(Before); Check(Before.bReady && Before.bViewTarget && Before.bFocused && Before.bPolicyActive, TEXT("Live camera is the view target and board owns actual keyboard focus")); });
        Input(TEXT("Hold right button"), [this](IAsyncActionSequence& S) { S.MoveToPosition(Board).Press(EMouseButtons::Right); });
        Do(TEXT("Observe real right-button capture"), [this]()
        { FLiveCoreCameraInputObservation O; Read(O); Check(O.bPolicyCapture && O.bSlateCapture && O.CaptureOwner == static_cast<int32>(EInputOwner::Orbit) && SamePose(O, Before), TEXT("RMB press owns orbit capture without moving camera")); });
        Input(TEXT("Move with RMB held"), [this](IAsyncActionSequence& S) { S.MoveToPosition(OrbitEnd); });
        Do(TEXT("Observe orbit actor mutation"), [this]()
        { FLiveCoreCameraInputObservation O; Read(O); Check(O.bSlateCapture && !O.ActorRotation.Equals(Before.ActorRotation, 1.e-3) && O.Focus.Equals(Before.Focus, 1.e-3) && FMath::IsNearlyEqual(O.Distance, Before.Distance, 1.e-3), TEXT("Routed held RMB changes actual camera rotation only")); });
        Input(TEXT("Release right button"), [](IAsyncActionSequence& S) { S.Release(EMouseButtons::Right); });
        Do(TEXT("Observe RMB release"), [this]()
        { Read(Before); Check(!Before.bPolicyCapture && !Before.bSlateCapture, TEXT("RMB capture fully released")); });
        Input(TEXT("Move without any button after RMB release"), [this](IAsyncActionSequence& S) { S.MoveToPosition(Board); });
        Do(TEXT("Observe no post-release orbit"), [this]()
        { FLiveCoreCameraInputObservation O; Read(O); Check(!O.bPolicyCapture && !O.bSlateCapture && SameNavigation(O, Before), TEXT("Move-only after RMB release preserves actual pose, focus and distance")); FrameKeys = O.FrameKeyEvents; });
        Input(TEXT("Establish a routed-F fitted view at the retained orbit"), [](IAsyncActionSequence& S) { S.Type(EKeys::F); });
        Do(TEXT("Save the observed fitted pose and distance"), [this]()
        { Read(Fitted); Check(Fitted.FrameKeyEvents == FrameKeys + 1 && Fitted.Focus.Equals(FVector::ZeroVector, 1.e-3) && WithinDistanceBounds(Fitted), TEXT("Actual F establishes a finite fitted reference at the current orbit")); Before = Fitted; });
        Input(TEXT("Hold middle button"), [this](IAsyncActionSequence& S) { S.MoveToPosition(Board).Press(EMouseButtons::Middle); });
        Do(TEXT("Observe real middle-button capture"), [this]()
        { FLiveCoreCameraInputObservation O; Read(O); Check(O.bPolicyCapture && O.bSlateCapture && O.CaptureOwner == static_cast<int32>(EInputOwner::Pan) && SamePose(O, Before), TEXT("MMB press owns pan capture without moving camera")); });
        Input(TEXT("Move with MMB held"), [this](IAsyncActionSequence& S) { S.MoveToPosition(PanEnd); });
        Do(TEXT("Observe pan actor mutation"), [this]()
        { FLiveCoreCameraInputObservation O; Read(O); Check(O.bSlateCapture && !O.Focus.Equals(Before.Focus, 1.e-3) && !O.ActorLocation.Equals(Before.ActorLocation, 1.e-3) && O.ActorRotation.Equals(Before.ActorRotation, 1.e-3), TEXT("Routed held MMB changes focus/actual position without orbit")); });
        Input(TEXT("Release middle button"), [](IAsyncActionSequence& S) { S.Release(EMouseButtons::Middle); });
        Do(TEXT("Observe MMB release"), [this]()
        { Read(Before); Check(!Before.bSlateCapture && !Before.bPolicyCapture, TEXT("MMB capture fully released")); });
        Input(TEXT("Move without any button after MMB release"), [this](IAsyncActionSequence& S) { S.MoveToPosition(Board); });
        Do(TEXT("Observe no post-release pan"), [this]()
        { FLiveCoreCameraInputObservation O; Read(O); Check(!O.bPolicyCapture && !O.bSlateCapture && SameNavigation(O, Before), TEXT("Move-only after MMB release preserves actual pose, focus and distance")); Before = O; });
        Input(TEXT("Zoom the focused board"), [](IAsyncActionSequence& S) { S.ScrollBy(1); });
        Do(TEXT("Observe actual wheel zoom"), [this]()
        { FLiveCoreCameraInputObservation O; Read(O); Check(WithinDistanceBounds(O) && O.Distance < Before.Distance && !SamePose(O, Before), TEXT("Actual board wheel moves camera within observed finite distance bounds")); Before = O; });
        Input(TEXT("Finite inward wheel sequence reaches the lower bound"), [](IAsyncActionSequence& S)
        { for (int32 I = 0; I < 8; ++I) { S.ScrollBy(8); } });
        Do(TEXT("Observe lower zoom clamp"), [this]()
        { FLiveCoreCameraInputObservation O; Read(O); Check(WithinDistanceBounds(O) && FMath::IsNearlyEqual(O.Distance, O.MinimumDistance, 1.e-3), TEXT("Routed inward wheel clamps at the camera's observed minimum distance")); });
        Input(TEXT("Finite outward wheel sequence reaches the upper bound"), [](IAsyncActionSequence& S)
        { for (int32 I = 0; I < 8; ++I) { S.ScrollBy(-8); } });
        Do(TEXT("Observe upper zoom clamp"), [this]()
        { FLiveCoreCameraInputObservation O; Read(O); Check(WithinDistanceBounds(O) && FMath::IsNearlyEqual(O.Distance, O.MaximumDistance, 1.e-3), TEXT("Routed outward wheel clamps at the camera's observed maximum distance")); });
        Input(TEXT("Return to an interior zoom for UI isolation"), [](IAsyncActionSequence& S) { S.ScrollBy(1); });
        Do(TEXT("Observe an interior perturbed view"), [this]()
        { Read(Before); Check(WithinDistanceBounds(Before) && Before.Distance > Before.MinimumDistance && Before.Distance < Before.MaximumDistance &&
            !Before.Focus.Equals(Fitted.Focus, 1.e-3) && !FMath::IsNearlyEqual(Before.Distance, Fitted.Distance, 1.e-3) &&
            Before.ActorRotation.Equals(Fitted.ActorRotation, 1.e-3), TEXT("Pan and zoom perturb the fitted reference while retaining its orbit")); });
        Input(TEXT("Focus the endpoint UI"), [this](IAsyncActionSequence& S) { S.MoveToPosition(EndpointPoint).Click(EMouseButtons::Left); });
        Do(TEXT("Observe UI keyboard ownership"), [this]()
        { FLiveCoreCameraInputObservation O; Read(O); Check(!O.bFocused && O.bEndpointFocused && SamePose(O, Before), TEXT("Endpoint owns actual keyboard focus without moving camera")); UiKeys = O.FrameKeyEvents; });
        Input(TEXT("F and wheel remain within the UI"), [](IAsyncActionSequence& S) { S.Type(EKeys::F).ScrollBy(-2); });
        Do(TEXT("Observe UI isolation"), [this]()
        { FLiveCoreCameraInputObservation O; Read(O); Check(SamePose(O, Before) && O.FrameKeyEvents == UiKeys && !O.bPolicyCapture && !O.bSlateCapture, TEXT("UI text/wheel neither frame nor navigate/capture the board")); });
        Input(TEXT("Refocus board after UI scroll"), [this](IAsyncActionSequence& S) { S.MoveToPosition(Board).Click(EMouseButtons::Left); });
        Do(TEXT("Observe focus before F"), [this]()
        { Read(Before); Check(Before.bFocused && Before.bPolicyActive && !Before.bPolicyCapture, TEXT("Actual board focus restored after scrolling UI")); FrameKeys = Before.FrameKeyEvents; });
        Input(TEXT("Send unmodified F key-down through AutomationDriver"), [](IAsyncActionSequence& S) { S.Type(EKeys::F); });
        Do(TEXT("Observe F framing the actual actor"), [this]()
        { Read(Framed); Check(Framed.FrameKeyEvents == FrameKeys + 1 && SameNavigation(Framed, Fitted) && WithinDistanceBounds(Framed) && !SamePose(Framed, Before), TEXT("Actual surface F restores the earlier fitted actor pose, focus and distance at the retained orbit")); });
        Input(TEXT("Send F again"), [](IAsyncActionSequence& S) { S.Type(EKeys::F); });
        Do(TEXT("Observe idempotent second F and unchanged Core state"), [this]()
        { FLiveCoreCameraInputObservation O; Read(O); Check(O.FrameKeyEvents == FrameKeys + 2 && SameNavigation(O, Framed), TEXT("Second routed F preserves the fitted actor pose, focus and distance")); });
    }
    void Restore()
    {
        if (bOwnsSetup && World.IsValid()) { World->EndCameraInputProofForTests(); }
        bOwnsSetup = false;
        if (bOwnsDriver && FSlateApplication::IsInitialized())
        {
            if (IAutomationDriverModule::Get().IsEnabled()) { IAutomationDriverModule::Get().Disable(); }
            if (const auto Focus = OriginalFocus.Pin()) { FSlateApplication::Get().SetKeyboardFocus(Focus, EFocusCause::SetDirectly); }
        }
        bOwnsDriver = false; Driver.Reset(); Sequence.Reset(); Future.Reset();
    }
    bool Finish()
    {
        bFinishing = true;
        if (Future.IsValid() && !Future->GetFuture().IsReady())
        {
            if (CleanupStarted == 0) { CleanupStarted = FPlatformTime::Seconds(); }
            if (FPlatformTime::Seconds() - CleanupStarted < 5) { return false; }
            if (!bExitRequested)
            {
                Check(false, TEXT("Driver did not quiesce; owned proof process must close"));
                bExitRequested = true; FPlatformMisc::RequestExit(false, TEXT("LiveCameraInput.DriverDidNotQuiesce"));
            }
            return false; // No cancellation API: retain the command until owned process shutdown.
        }
        if (Future.IsValid())
        { Check(Future->GetFuture().Get(), TEXT("Pending/cleanup driver sequence completed")); Future.Reset(); Sequence.Reset(); }
        if (bOwnsDriver && Driver.IsValid() && !bCleanupQueued)
        {
            bCleanupQueued = true; Sequence = Driver->CreateSequence();
            Sequence->Actions().Release(EMouseButtons::Left).Release(EMouseButtons::Right).Release(EMouseButtons::Middle)
                .Release(EKeys::F).Release(EKeys::Escape);
            Future = MakeUnique<TAsyncResult<bool>>(Sequence->Perform()); CleanupStarted = FPlatformTime::Seconds(); return false;
        }
        if (bInitialized)
        { FLiveCoreCameraInputObservation O; Read(O); Check(!O.bPolicyCapture && !O.bSlateCapture, TEXT("No owned capture remains before restoration")); }
        const bool bVerifyRestoration = bOwnsSetup;
        const bool bVerifyDriver = bOwnsDriver;
        Restore();
        if (bVerifyRestoration && World.IsValid())
        {
            FLiveCoreCameraInputObservation O;
            if (Read(O))
            { Check(SamePose(O, Baseline) && O.bReady == Baseline.bReady && O.Focus.Equals(Baseline.Focus, 1.e-3) &&
                FMath::IsNearlyEqual(O.Distance, Baseline.Distance, 1.e-3), TEXT("Original navigation and actor pose restored")); }
        }
        if (bVerifyDriver && FSlateApplication::IsInitialized())
        {
            Check(!IAutomationDriverModule::Get().IsEnabled(), TEXT("Owned AutomationDriver platform handler restored"));
            if (const auto Focus = OriginalFocus.Pin())
            { Check(FSlateApplication::Get().GetKeyboardFocusedWidget() == Focus, TEXT("Original Slate keyboard focus restored")); }
        }
        Test->AddInfo(FString::Printf(TEXT("LiveCoreCamera.Input assertions=%d elapsed=%.3fs status=%s; available Core state unchanged is not a zero-HTTP-attempt proof."),
            Assertions, FPlatformTime::Seconds() - Started, bFailed ? TEXT("FAIL") : TEXT("PASS")));
        return true;
    }

    FAutomationTestBase* Test;
    TWeakObjectPtr<AWarhammerClientGameMode> World;
    TWeakPtr<SWidget> OriginalFocus;
    TSharedPtr<IAsyncAutomationDriver, ESPMode::ThreadSafe> Driver;
    TSharedPtr<IAsyncDriverSequence, ESPMode::ThreadSafe> Sequence;
    TUniquePtr<TAsyncResult<bool>> Future;
    TArray<TFunction<EInputProofStep()>> Steps;
    FLiveCoreCameraInputObservation Baseline, Before, Fitted, Framed;
    FVector2D Board, OrbitEnd, PanEnd, EndpointPoint;
    double Started, StepStarted = 0, CleanupStarted = 0;
    uint64 UiKeys = 0, FrameKeys = 0;
    int32 Index = 0, Assertions = 0;
    bool bInitialized = false, bOwnsSetup = false, bOwnsDriver = false, bFailed = false;
    bool bFinishing = false, bCleanupQueued = false, bExitRequested = false;
};
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FLiveCoreCameraRenderedInputTest, "Warhammer.Rendered.LiveCoreCamera.Input",
    EAutomationTestFlags::ClientContext | EAutomationTestFlags::NonNullRHI | EAutomationTestFlags::EngineFilter)
bool FLiveCoreCameraRenderedInputTest::RunTest(const FString&)
{
    FString CoreUrl;
    if (!FParse::Param(FCommandLine::Get(), TEXT("LiveCoreCameraInputProof")) ||
        FParse::Value(FCommandLine::Get(), TEXT("CoreUrl="), CoreUrl) ||
        !FPlatformMisc::GetEnvironmentVariable(TEXT("WH_CORE_ADMIN_TOKEN")).IsEmpty() ||
        !FPlatformMisc::GetEnvironmentVariable(TEXT("WH_CORE_PLAYER_TOKEN")).IsEmpty())
    { AddError(TEXT("Requires -LiveCoreCameraInputProof with no CoreUrl or Core credentials.")); return false; }
    FAutomationTestFramework::Get().EnqueueLatentCommand(MakeShared<FLiveCameraInputCommand>(this));
    return true;
}
#endif
