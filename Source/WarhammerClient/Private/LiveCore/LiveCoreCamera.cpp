#include "LiveCore/LiveCoreCamera.h"

namespace Warhammer::LiveCore
{
namespace
{
bool Finite(const FVector2D& V) { return FMath::IsFinite(V.X) && FMath::IsFinite(V.Y); }
bool Finite(const FVector& V) { return FMath::IsFinite(V.X) && FMath::IsFinite(V.Y) && FMath::IsFinite(V.Z); }
}

bool FTabletopCamera::Fail(const TCHAR* Message) { Error = Message; return false; }

bool FTabletopCamera::SetBounds(const FBox& InBounds)
{
    if (!InBounds.IsValid || !Finite(InBounds.Min) || !Finite(InBounds.Max) ||
        InBounds.GetSize().X <= 0 || InBounds.GetSize().Y <= 0 || InBounds.GetSize().Z < 0)
    {
        bBoundsValid = false; return Fail(TEXT("Camera: finite nonempty board bounds required."));
    }
    if (bBoundsValid && Bounds.Min.Equals(InBounds.Min, 1.e-6) && Bounds.Max.Equals(InBounds.Max, 1.e-6))
    { return true; } // An ordinary HTTP refresh must not reset the user's view.
    const double Diagonal = InBounds.GetSize().Size();
    if (!FMath::IsFinite(Diagonal) || Diagonal <= 0 || !FMath::IsFinite(Diagonal * 8))
    { bBoundsValid = false; return Fail(TEXT("Camera: board extent cannot be represented safely.")); }
    Bounds = InBounds; bBoundsValid = true;
    MinimumDistance = FMath::Max(20.0, Diagonal * 0.10);
    MaximumDistance = FMath::Max(MinimumDistance * 2.0, Diagonal * 8.0);
    Error.Reset();
    return bLayoutValid ? FrameBoard() : true;
}

bool FTabletopCamera::SetLayout(const FCameraLayout& InLayout)
{
    const double Padding = 16.0 * InLayout.PixelsPerLogicalUnit;
    if (!Finite(InLayout.ViewportPixels) || !InLayout.SurfacePixels.bIsValid ||
        !Finite(InLayout.SurfacePixels.Min) || !Finite(InLayout.SurfacePixels.Max) || !Finite(InLayout.SurfacePixels.GetSize()) || !FMath::IsFinite(Padding) ||
        !FMath::IsFinite(InLayout.PixelsPerLogicalUnit) || InLayout.PixelsPerLogicalUnit <= 0 ||
        !FMath::IsFinite(InLayout.HorizontalFovDegrees) || InLayout.HorizontalFovDegrees < 5 || InLayout.HorizontalFovDegrees > 150 ||
        !FMath::IsFinite(InLayout.NearClipCm) || InLayout.NearClipCm <= 0 ||
        InLayout.ViewportPixels.X <= 0 || InLayout.ViewportPixels.Y <= 0 ||
        InLayout.SurfacePixels.Min.X < -0.5 || InLayout.SurfacePixels.Min.Y < -0.5 ||
        InLayout.SurfacePixels.Max.X > InLayout.ViewportPixels.X + 0.5 || InLayout.SurfacePixels.Max.Y > InLayout.ViewportPixels.Y + 0.5 ||
        InLayout.SurfacePixels.GetSize().X < FMath::Max(64.0 * InLayout.PixelsPerLogicalUnit, 2 * Padding + 1) ||
        InLayout.SurfacePixels.GetSize().Y < FMath::Max(64.0 * InLayout.PixelsPerLogicalUnit, 2 * Padding + 1))
    {
        bLayoutValid = false; return Fail(TEXT("Camera: enlarge the window; the board area must be at least 64 logical units in each direction."));
    }
    const bool bSame = bLayoutValid && Layout.ViewportPixels.Equals(InLayout.ViewportPixels, 0.1) &&
        Layout.SurfacePixels.Min.Equals(InLayout.SurfacePixels.Min, 0.1) && Layout.SurfacePixels.Max.Equals(InLayout.SurfacePixels.Max, 0.1) &&
        FMath::IsNearlyEqual(Layout.PixelsPerLogicalUnit, InLayout.PixelsPerLogicalUnit, 1.e-6) &&
        FMath::IsNearlyEqual(Layout.HorizontalFovDegrees, InLayout.HorizontalFovDegrees, 1.e-6) &&
        FMath::IsNearlyEqual(Layout.NearClipCm, InLayout.NearClipCm, 1.e-6);
    if (bSame) { return true; }
    Layout = InLayout; bLayoutValid = true; Error.Reset();
    return bBoundsValid ? FrameBoard() : true; // Resizing deliberately frames the table again.
}

void FTabletopCamera::Basis(FVector& Forward, FVector& Right, FVector& Up) const
{
    const double A = FMath::DegreesToRadians(Azimuth), E = FMath::DegreesToRadians(Elevation);
    Forward = -FVector(FMath::Cos(E) * FMath::Cos(A), FMath::Cos(E) * FMath::Sin(A), FMath::Sin(E));
    Right = FVector::CrossProduct(FVector::UpVector, Forward).GetSafeNormal();
    Up = FVector::CrossProduct(Forward, Right).GetSafeNormal();
}

bool FTabletopCamera::Slopes(double& L, double& R, double& B, double& T) const
{
    if (!bLayoutValid) { return false; }
    const double Padding = 16.0 * Layout.PixelsPerLogicalUnit;
    const double TanH = FMath::Tan(FMath::DegreesToRadians(Layout.HorizontalFovDegrees * 0.5));
    const double TanV = TanH * Layout.ViewportPixels.Y / Layout.ViewportPixels.X;
    L = (2 * (Layout.SurfacePixels.Min.X + Padding) / Layout.ViewportPixels.X - 1) * TanH;
    R = (2 * (Layout.SurfacePixels.Max.X - Padding) / Layout.ViewportPixels.X - 1) * TanH;
    B = (1 - 2 * (Layout.SurfacePixels.Max.Y - Padding) / Layout.ViewportPixels.Y) * TanV;
    T = (1 - 2 * (Layout.SurfacePixels.Min.Y + Padding) / Layout.ViewportPixels.Y) * TanV;
    return FMath::IsFinite(L) && FMath::IsFinite(R) && FMath::IsFinite(B) && FMath::IsFinite(T) && R > L && T > B;
}

bool FTabletopCamera::FrameBoard()
{
    if (!bBoundsValid || !bLayoutValid) { return false; }
    double L, R, B, T;
    if (!Slopes(L, R, B, T)) { return Fail(TEXT("Camera: invalid perspective fit.")); }
    FVector Forward, Right, Up; Basis(Forward, Right, Up);
    const double CX = (L + R) * 0.5, CY = (B + T) * 0.5;
    const FVector Centre = Bounds.GetCenter();
    MinimumDistance = FMath::Max(Bounds.GetSize().Size() * 0.10, Layout.NearClipCm * 2);
    double Required = MinimumDistance;
    for (int32 Bits = 0; Bits < 8; ++Bits)
    {
        const FVector V = FVector(Bits & 1 ? Bounds.Max.X : Bounds.Min.X,
            Bits & 2 ? Bounds.Max.Y : Bounds.Min.Y, Bits & 4 ? Bounds.Max.Z : Bounds.Min.Z) - Centre;
        const double F = FVector::DotProduct(V, Forward), X = FVector::DotProduct(V, Right), Y = FVector::DotProduct(V, Up);
        // Perspective side-plane inequalities, solved for distance. The optical aim
        // shifts with the available Slate surface, while the viewing basis stays fixed.
        for (double D : {(L * F - X) / (CX - L), (X - R * F) / (R - CX),
            (B * F - Y) / (CY - B), (Y - T * F) / (T - CY), Layout.NearClipCm - F})
        {
            if (!FMath::IsFinite(D)) { return Fail(TEXT("Camera: nonfinite frame distance.")); }
            Required = FMath::Max(Required, D);
        }
    }
    if (!FMath::IsFinite(Required * 4)) { return Fail(TEXT("Camera: frame extent overflow.")); }
    MaximumDistance = FMath::Max(Bounds.GetSize().Size() * 8.0, Required * 4.0);
    Distance = Required + FMath::Max(0.1, Required * 1.e-5);
    Focus = Centre; Error.Reset(); return true;
}

FVector FTabletopCamera::GetLocation() const
{
    double L, R, B, T;
    if (!Slopes(L, R, B, T)) { return FVector::ZeroVector; }
    FVector Forward, Right, Up; Basis(Forward, Right, Up);
    return Focus - Forward * Distance - Right * ((L + R) * 0.5 * Distance) - Up * ((B + T) * 0.5 * Distance);
}
FRotator FTabletopCamera::GetRotation() const
{
    FVector Forward, Right, Up; Basis(Forward, Right, Up); return Forward.Rotation();
}
bool FTabletopCamera::Orbit(const FVector2D& Delta)
{
    if (!IsReady() || !Finite(Delta)) { return false; }
    Azimuth = FMath::Fmod(Azimuth - FMath::Clamp(Delta.X, -10000.0, 10000.0) * 0.25, 360.0);
    if (Azimuth < -180) { Azimuth += 360; } else if (Azimuth >= 180) { Azimuth -= 360; }
    Elevation = FMath::Clamp(Elevation + FMath::Clamp(Delta.Y, -10000.0, 10000.0) * 0.25, 20.0, 85.0);
    return true;
}
bool FTabletopCamera::Pan(const FVector2D& Delta)
{
    if (!IsReady() || !Finite(Delta)) { return false; }
    FVector Forward, Right, Up; Basis(Forward, Right, Up);
    const double TanV = FMath::Tan(FMath::DegreesToRadians(Layout.HorizontalFovDegrees * 0.5)) * Layout.ViewportPixels.Y / Layout.ViewportPixels.X;
    const double CmPerLogical = 2 * Distance * TanV * Layout.PixelsPerLogicalUnit / Layout.ViewportPixels.Y;
    const FVector GroundUp(Up.X, Up.Y, 0);
    const double SinElevation = FMath::Sin(FMath::DegreesToRadians(Elevation));
    Focus += -Right * FMath::Clamp(Delta.X, -10000.0, 10000.0) * CmPerLogical +
        GroundUp.GetSafeNormal() * FMath::Clamp(Delta.Y, -10000.0, 10000.0) * CmPerLogical / SinElevation;
    const FVector Centre = Bounds.GetCenter(), Size = Bounds.GetSize();
    Focus.X = FMath::Clamp(Focus.X, Centre.X - Size.X, Centre.X + Size.X);
    Focus.Y = FMath::Clamp(Focus.Y, Centre.Y - Size.Y, Centre.Y + Size.Y);
    Focus.Z = Centre.Z;
    return true;
}
bool FTabletopCamera::Zoom(double WheelDelta)
{
    if (!IsReady() || !FMath::IsFinite(WheelDelta)) { return false; }
    Distance = FMath::Clamp(Distance * FMath::Exp(-FMath::Clamp(WheelDelta, -8.0, 8.0) * 0.15), MinimumDistance, MaximumDistance);
    return true;
}
}
