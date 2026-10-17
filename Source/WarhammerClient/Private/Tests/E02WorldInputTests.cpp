#include "Misc/AutomationTest.h"

#if WITH_DEV_AUTOMATION_TESTS && WITH_E02_AUTOMATION_DRIVER

#include "Migration/E02WorldProofGameMode.h"
#include "Async/AsyncResult.h"
#include "Dom/JsonObject.h"
#include "DriverConfiguration.h"
#include "Engine/Engine.h"
#include "Engine/World.h"
#include "Framework/Application/SlateApplication.h"
#include "HAL/PlatformTime.h"
#include "HAL/PlatformMisc.h"
#include "IAutomationDriver.h"
#include "IAutomationDriverModule.h"
#include "IDriverSequence.h"
#include "InputCoreTypes.h"

using namespace Warhammer::Migration::E02;

namespace
{
enum class EStepResult : uint8 { Wait, Done };

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
            Do(TEXT("initial counters"), [this]() { Picks = World->WorldPickCount(); Cameras = World->CameraMutationCount(); });
            MoveToModel(TEXT("e02-circle"));
            Input(TEXT("right below drag threshold"), [this](IAsyncActionSequence& S) { S.Press(EMouseButtons::Right).MoveToPosition(A + FVector2D(3, 0)); });
            Do(TEXT("below4logical no orbit"), [this]() { Check(World->CameraMutationCount() == Cameras && World->GetPolicy().Snapshot().Capture.IsSet(), TEXT("Capture exists; no below-threshold camera mutation")); });
            Input(TEXT("right above drag threshold"), [this](IAsyncActionSequence& S) { S.MoveToPosition(A + FVector2D(8, 0)); });
            Do(TEXT("orbit retains press owner"), [this]() { Check(World->CameraMutationCount() > Cameras && World->GetPolicy().Snapshot().Capture.IsSet() && World->GetPolicy().Snapshot().Capture->Owner == EInputOwner::Orbit, TEXT("Actual orbit through Slate capture")); Check(World->ControlScreenPoint(TEXT("button"), B), TEXT("HUD crossing position")); });
            Input(TEXT("captured orbit crosses HUD and releases"), [this](IAsyncActionSequence& S) { S.MoveToPosition(B).Release(EMouseButtons::Right); });
            Do(TEXT("no leaked activation or selection"), [this]() { Check(!World->GetPolicy().Snapshot().Capture.IsSet() && World->GetPolicy().Snapshot().HudActivationCount == 0 && World->WorldPickCount() == Picks, TEXT("Capture released; HUD/world did not receive click")); });
        }
        else if (Name == TEXT("Input.PanDollyFrame"))
        {
            ClickModel(TEXT("e02-circle")); RetainIntent();
            Input(TEXT("middle pan"), [this](IAsyncActionSequence& S) { S.Press(EMouseButtons::Middle).MoveToPosition(A + FVector2D(20, 10)).Release(EMouseButtons::Middle); });
            Input(TEXT("viewport wheel then camera keys"), [](IAsyncActionSequence& S)
            { S.ScrollBy(1).Type(EKeys::G).Type(EKeys::F).Type(EKeys::Left).Type(EKeys::Up).Type(EKeys::R); });
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
            Input(TEXT("gesture crossing resize"), [](IAsyncActionSequence& S) { S.Press(EMouseButtons::Right); });
            Do(TEXT("programmatic resize during capture"), [this]() { Check(World->ProgrammaticResize(FIntPoint(1600, 900)), TEXT("Owned SWindow resize")); });
            Wait(TEXT("actual1600x900 viewport"), [this]() { return World->GetProofViewportSize() == FIntPoint(1600, 900); });
            Input(TEXT("release after resize"), [](IAsyncActionSequence& S) { S.Release(EMouseButtons::Right); });
            Do(TEXT("resize cancels crossing gesture"), [this]() { Check(!World->GetPolicy().Snapshot().Capture.IsSet(), TEXT("Resize cancellation")); AssertIntent(); });
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
        ClickModel(TEXT("e02-circle"));
        Do(TEXT("same intended ray under resize/scale"), [this]()
        {
            Check(SerializeLocalIntent(World->GetPolicy().Snapshot()) == Intent, TEXT("Identical intended ID/XYZ/facing under variant"));
            FAdvisoryHit Hit; FString Diagnostic;
            Check(World->QueryScreenPoint(A, Hit, Diagnostic) && Hit.Id == TEXT("e02-circle"), TEXT("No sidebar subtraction or doubleDPI in world ray"));
            Cameras = World->CameraMutationCount();
        });
        Control(TEXT("blank")); Input(TEXT("variant HUD wheel/click exclusion"), [](IAsyncActionSequence& S) { S.Click().ScrollBy(1); });
        Do(TEXT("HUD remains excluded at variant"), [this]() { Check(World->CameraMutationCount() == Cameras && SerializeLocalIntent(World->GetPolicy().Snapshot()) == Intent, TEXT("Logical HUD geometry excludes world at actual scale")); });
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
    FAdvisoryHit HitBefore;
    double Started, StepStarted = 0.0, CleanupStarted = 0.0;
    uint64 Picks = 0, Cameras = 0, EventBaseline = 0;
    int32 Index = 0, Assertions = 0;
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
