#include "LiveCore/LiveCoreCamera.h"

#if WITH_DEV_AUTOMATION_TESTS
#include "Migration/E02InputPolicy.h"
#include "Misc/AutomationTest.h"
#include <limits>

using namespace Warhammer::LiveCore;
namespace
{
constexpr EAutomationTestFlags CameraFlags = EAutomationTestFlags_ApplicationContextMask | EAutomationTestFlags::EngineFilter;
const FBox Table(FVector(-56, -77, -2), FVector(56, 77, 12));
FCameraLayout Layout(double Width, double Height, double Dpi = 1)
{
    FCameraLayout Value;
    Value.ViewportPixels = FVector2D(Width, Height);
    Value.SurfacePixels = FBox2D(FVector2D(410 * Dpi, 32 * Dpi), Value.ViewportPixels);
    Value.PixelsPerLogicalUnit = Dpi;
    return Value;
}
bool CornersFit(FAutomationTestBase& Test, const FTabletopCamera& Camera, const FBox& Box)
{
    const auto& V = Camera.GetLayout();
    const FRotationMatrix Rotation(Camera.GetRotation());
    const FVector Forward = Rotation.GetUnitAxis(EAxis::X), Right = Rotation.GetUnitAxis(EAxis::Y), Up = Rotation.GetUnitAxis(EAxis::Z);
    const double TanH = FMath::Tan(FMath::DegreesToRadians(V.HorizontalFovDegrees * 0.5));
    const double TanV = TanH * V.ViewportPixels.Y / V.ViewportPixels.X;
    const double Padding = 16 * V.PixelsPerLogicalUnit;
    bool bAll = true;
    for (int32 Bits = 0; Bits < 8; ++Bits)
    {
        const FVector World(Bits & 1 ? Box.Max.X : Box.Min.X, Bits & 2 ? Box.Max.Y : Box.Min.Y, Bits & 4 ? Box.Max.Z : Box.Min.Z);
        const FVector Relative = World - Camera.GetLocation();
        const double Depth = FVector::DotProduct(Relative, Forward);
        const double X = (1 + FVector::DotProduct(Relative, Right) / (Depth * TanH)) * V.ViewportPixels.X * 0.5;
        const double Y = (1 - FVector::DotProduct(Relative, Up) / (Depth * TanV)) * V.ViewportPixels.Y * 0.5;
        bAll &= Test.TestTrue(TEXT("Every actual projected corner clears near and all four inset sides"),
            Depth >= V.NearClipCm && FMath::IsFinite(X) && FMath::IsFinite(Y) &&
            X >= V.SurfacePixels.Min.X + Padding - 1.e-4 && X <= V.SurfacePixels.Max.X - Padding + 1.e-4 &&
            Y >= V.SurfacePixels.Min.Y + Padding - 1.e-4 && Y <= V.SurfacePixels.Max.Y - Padding + 1.e-4);
    }
    return bAll;
}
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FLiveCoreFrameFitTest, "Warhammer.LiveCore.Camera.FrameCornersAndLayout", CameraFlags)
bool FLiveCoreFrameFitTest::RunTest(const FString& Parameters)
{
    for (const FCameraLayout& View : {Layout(1280,720), Layout(1920,1080,1.5), Layout(800,1000), Layout(3440,1440), Layout(480,720)})
    {
        FTabletopCamera Camera;
        TestTrue(TEXT("Board bounds accepted"), Camera.SetBounds(Table));
        if (!TestTrue(TEXT("Real remaining surface is frameable"), Camera.SetLayout(View))) { continue; }
        CornersFit(*this, Camera, Table);
        Camera.Orbit(FVector2D(725, -10000));
        TestEqual(TEXT("Minimum pitch"), Camera.GetElevation(), 20.0);
        TestTrue(TEXT("Frame at low oblique angle"), Camera.FrameBoard());
        CornersFit(*this, Camera, Table);
        Camera.Orbit(FVector2D(-2250, 10000));
        TestEqual(TEXT("Maximum pitch"), Camera.GetElevation(), 85.0);
        TestTrue(TEXT("Frame near overhead"), Camera.FrameBoard());
        CornersFit(*this, Camera, Table);
        TestTrue(TEXT("Solved distance is not clamped below the fit"), Camera.GetMaximumDistance() >= Camera.GetDistance());
    }
    FTabletopCamera Small;
    Small.SetBounds(Table);
    TestFalse(TEXT("Window with less than 64 logical board width is refused"), Small.SetLayout(Layout(460,720)));
    TestTrue(TEXT("Too-small area has a visible diagnostic"), Small.GetError().Contains(TEXT("enlarge the window")));
    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FLiveCoreNavigationBoundsTest, "Warhammer.LiveCore.Camera.NavigationAndRefresh", CameraFlags)
bool FLiveCoreNavigationBoundsTest::RunTest(const FString& Parameters)
{
    FTabletopCamera Camera;
    Camera.SetBounds(Table); Camera.SetLayout(Layout(1280,720));
    Camera.Orbit(FVector2D(10000,10)); Camera.Pan(FVector2D(10000,-10000)); Camera.Zoom(2);
    const FVector Focus = Camera.GetFocus(), Position = Camera.GetLocation();
    const double Distance = Camera.GetDistance(), Azimuth = Camera.GetAzimuth();
    TestTrue(TEXT("Pan remains in board vicinity"), FMath::Abs(Focus.X) <= Table.GetSize().X && FMath::Abs(Focus.Y) <= Table.GetSize().Y);
    TestTrue(TEXT("Azimuth wraps into a finite conventional interval"), Azimuth >= -180 && Azimuth < 180);
    Camera.SetBounds(Table); Camera.SetLayout(Layout(1280,720));
    TestTrue(TEXT("Same-bounds HTTP refresh does not reset pan/orbit/zoom"), Camera.GetFocus().Equals(Focus) && Camera.GetLocation().Equals(Position) && Camera.GetDistance() == Distance && Camera.GetAzimuth() == Azimuth);
    for (int32 I=0; I<100; ++I) { Camera.Zoom(1000); }
    TestEqual(TEXT("Zoom in clamps to extent-dependent minimum"), Camera.GetDistance(), Camera.GetMinimumDistance());
    for (int32 I=0; I<100; ++I) { Camera.Zoom(-1000); }
    TestEqual(TEXT("Zoom out clamps to extent-dependent maximum"), Camera.GetDistance(), Camera.GetMaximumDistance());
    const FVector Before = Camera.GetLocation();
    TestFalse(TEXT("NaN wheel rejected"), Camera.Zoom(std::numeric_limits<double>::quiet_NaN()));
    TestFalse(TEXT("Infinite drag rejected"), Camera.Pan(FVector2D(std::numeric_limits<double>::infinity(),0)));
    TestTrue(TEXT("Rejected input preserves camera"), Camera.GetLocation().Equals(Before));
    TestTrue(TEXT("Resize deliberately reframes"), Camera.SetLayout(Layout(1600,900)));
    CornersFit(*this, Camera, Table);
    FTabletopCamera DpiA, DpiB;
    DpiA.SetBounds(Table); DpiB.SetBounds(Table); DpiA.SetLayout(Layout(1280,720)); DpiB.SetLayout(Layout(1920,1080,1.5));
    TestTrue(TEXT("Uniform DPI scaling preserves initial framing"), DpiA.GetLocation().Equals(DpiB.GetLocation(),1.e-6));
    DpiA.Pan(FVector2D(10,10)); DpiB.Pan(FVector2D(10,10));
    TestTrue(TEXT("Equal logical pan is DPI independent"), DpiA.GetFocus().Equals(DpiB.GetFocus(),1.e-6));
    FTabletopCamera Bad;
    TestFalse(TEXT("Nonfinite board bounds rejected"), Bad.SetBounds(FBox(FVector(0,0,0),FVector(std::numeric_limits<double>::infinity(),1,1))));
    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FLiveCoreCameraInputTest, "Warhammer.LiveCore.Camera.InputOwnershipAndCancellation", CameraFlags)
bool FLiveCoreCameraInputTest::RunTest(const FString& Parameters)
{
    using namespace Warhammer::Migration::E02;
    FInputPolicy Policy;
    FPointerSample P; P.bInsideViewport=true; P.Logical=FVector2D(30,50);
    const FHitTarget Board;
    TestTrue(TEXT("RMB acquires an owned camera drag"), Policy.Press(P, EPointerButton::Secondary, Board).bAcquireCapture);
    P.Logical.X += 2;
    TestEqual(TEXT("Small motion does not orbit"), Policy.Move(P).CameraAction, ECameraAction::None);
    P.Logical.X += 5;
    const auto Orbit = Policy.Move(P);
    TestEqual(TEXT("RMB threshold emits only orbit"), Orbit.CameraAction, ECameraAction::Orbit);
    TestFalse(TEXT("Camera drag cannot request a world pick"), Orbit.bRequestWorldPick);
    TestTrue(TEXT("Matching release relinquishes capture"), Policy.Release(P, EPointerButton::Secondary, Board).bReleaseCapture);
    Policy.Press(P, EPointerButton::Middle, Board);
    P.Logical.Y += 10;
    TestEqual(TEXT("MMB emits pan"), Policy.Move(P).CameraAction, ECameraAction::Pan);
    TestTrue(TEXT("Escape cancels owned drag"), Policy.Escape().bReleaseCapture);
    Policy.Press(P, EPointerButton::Secondary, Board);
    TestTrue(TEXT("Focus/deactivation cancels owned drag"), Policy.FocusChanged(false).bReleaseCapture);
    TestEqual(TEXT("No movement while deactivated"), Policy.Move(P).CameraAction, ECameraAction::None);
    Policy.FocusChanged(true); Policy.Press(P, EPointerButton::Middle, Board);
    TestTrue(TEXT("Unexpected capture loss cancels"), Policy.CaptureLost().bReleaseCapture);
    TestEqual(TEXT("Wheel over HUD is not a camera action"), Policy.Wheel(P,{EInputOwner::HudScroll,FString(),true},1).CameraAction, ECameraAction::None);
    TestFalse(TEXT("Camera gestures create no local selection/submission draft"), Policy.Snapshot().SelectedIntent.IsSet());
    TestEqual(TEXT("No Confirm/submission path was exercised"), Policy.Snapshot().ConfirmAttempts, uint64(0));
    return true;
}
#endif
