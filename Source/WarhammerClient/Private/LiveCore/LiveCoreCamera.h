#pragma once

#include "CoreMinimal.h"

namespace Warhammer::LiveCore
{
struct FCameraLayout
{
    FVector2D ViewportPixels = FVector2D::ZeroVector;
    FBox2D SurfacePixels = FBox2D(ForceInit);
    double PixelsPerLogicalUnit = 1.0;
    double HorizontalFovDegrees = 55.0;
    double NearClipCm = 10.0;
};

/** Pure local presentation navigation. No session, selection or command interface. */
class FTabletopCamera
{
public:
    bool SetBounds(const FBox& WorldBounds);
    bool SetLayout(const FCameraLayout& InLayout);
    bool FrameBoard();
    bool Orbit(const FVector2D& LogicalDelta);
    bool Pan(const FVector2D& LogicalDelta);
    bool Zoom(double WheelDelta);
    bool IsReady() const { return bBoundsValid && bLayoutValid && Error.IsEmpty(); }
    const FString& GetError() const { return Error; }
    FVector GetLocation() const;
    FRotator GetRotation() const;
    FVector GetFocus() const { return Focus; }
    double GetDistance() const { return Distance; }
    double GetElevation() const { return Elevation; }
    double GetAzimuth() const { return Azimuth; }
    double GetMinimumDistance() const { return MinimumDistance; }
    double GetMaximumDistance() const { return MaximumDistance; }
    const FCameraLayout& GetLayout() const { return Layout; }

private:
    bool Fail(const TCHAR* Message);
    bool Slopes(double& L, double& R, double& B, double& T) const;
    void Basis(FVector& Forward, FVector& Right, FVector& Up) const;
    FBox Bounds = FBox(ForceInit);
    FCameraLayout Layout;
    FVector Focus = FVector::ZeroVector;
    double Azimuth = -90.0, Elevation = 50.0, Distance = 300.0;
    double MinimumDistance = 20.0, MaximumDistance = 3000.0;
    bool bBoundsValid = false, bLayoutValid = false;
    FString Error;
};
}
