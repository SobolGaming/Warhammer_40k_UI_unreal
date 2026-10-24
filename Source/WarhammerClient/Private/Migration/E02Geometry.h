#pragma once

#include "CoreMinimal.h"

// Synthetic, advisory presentation proof. These types do not describe legal moves.
namespace Warhammer::Migration::E02
{
constexpr double CentimetresPerInch = 2.54;

enum class EDiagnosticCode : uint8
{
    None, InvalidFixture, MissingDimension, NonFinite, UnknownShape, NullPose,
    InvalidPolygon, InvalidFrame, InvalidRay, NoHit, InvalidInput, ProofHasNoGameSession
};

struct FDiagnostic
{
    EDiagnosticCode Code = EDiagnosticCode::None;
    FString Field;
    FString Message;
};

const TCHAR* DiagnosticCodeName(EDiagnosticCode Code);

struct FDomainPose
{
    FVector3d PositionInches = FVector3d::ZeroVector;
    double FacingDegrees = 0.0;
};

struct FTableFrame
{
    FVector2d CenterInches = FVector2d::ZeroVector;
    double DatumInches = 0.0;
    FTransform3d WorldFromTableCm = FTransform3d::Identity;
};

struct FBounds2d
{
    FVector2d Min = FVector2d::ZeroVector;
    FVector2d Max = FVector2d::ZeroVector;
};

enum class EShapeKind : uint8 { Unknown, Circle, Ellipse, Rectangle, Capsule, Polygon };

struct FFootprint
{
    FString Id;
    EShapeKind Kind = EShapeKind::Unknown;
    TOptional<double> RadiusInches;
    TOptional<double> LengthInches;
    TOptional<double> WidthInches;
    TArray<FVector2d> VerticesInches;
    TOptional<FDomainPose> Pose;
    double QueryHeightInches = 0.0;
    bool bSyntheticCapsule = false;
};

struct FSupportSurface
{
    FString Id;
    FBounds2d BoundsInches;
    double ZInches = 0.0;
    TArray<FBounds2d> HolesInches;
};

struct FCameraSettings
{
    FVector3d TargetDomainInches = FVector3d::ZeroVector;
    double DefaultAzimuthDegrees = 0.0;
    double DefaultElevationDegrees = 0.0;
    double DefaultDistanceCm = 0.0;
    double FovDegrees = 0.0;
    double OrbitDegreesPerLogicalUnit = 0.0;
    double PanCmPerLogicalUnit = 0.0;
    double DollyStepCm = 0.0;
    double MinimumDistanceCm = 0.0;
    double MaximumDistanceCm = 0.0;
    double MinimumElevationDegrees = 0.0;
    double MaximumElevationDegrees = 0.0;
    double FrameSelectionDistanceCm = 0.0;
    double KeyboardOrbitStepDegrees = 0.0;
    double DragThresholdLogicalUnits = 0.0;
    double ObliqueElevationDegrees = 0.0;
    double NearTopElevationDegrees = 0.0;
};

struct FPresentationSettings
{
    FVector3d LightRotationDegrees = FVector3d::ZeroVector;
    FVector3d LightColor = FVector3d::ZeroVector;
    double LightIntensityLux = 0.0;
    double ExposureBias = 0.0;
    double ExposureMinBrightness = 0.0;
    double ExposureMaxBrightness = 0.0;
    bool bLightCastShadows = false;
    bool bPhysicalCameraExposure = false;
    FBounds2d HudBoundsLogical;
    double HeaderHeightLogical = 0.0;
    FVector2d ModalSizeLogical = FVector2d::ZeroVector;
};

struct FFixture
{
    FString Label;
    FTableFrame Frame;
    FBounds2d BoardBoundsInches;
    TArray<FFootprint> Models;
    TArray<FSupportSurface> Supports;
    FCameraSettings Camera;
    FPresentationSettings Presentation;
    double VisualThicknessInches = 0.0;
    TMap<FString, FString> KeyBindings;
    TMap<FString, TArray<FString>> InputSequences;
    TArray<FString> ExpectedTestNames;
};

bool ValidateFrame(const FTableFrame& Frame, FDiagnostic& Error);
bool ValidateFootprint(const FFootprint& Model, FDiagnostic& Error);
bool LoadFixture(const FString& AbsolutePath, FFixture& OutFixture, FDiagnostic& Error);
bool ParseFixtureJson(const FString& Text, FFixture& OutFixture, FDiagnostic& Error);
FVector3d DomainToWorld(const FTableFrame& Frame, const FVector3d& DomainInches);
FVector3d WorldToDomain(const FTableFrame& Frame, const FVector3d& WorldCm);
FVector3d HeadingToWorld(const FTableFrame& Frame, double DomainDegrees);
double WorldToHeading(const FTableFrame& Frame, const FVector3d& WorldDirection);
double PolygonSignedArea(const TArray<FVector2d>& Vertices);
// Requires an already validated descriptor; returns boundary-inclusive membership.
bool ContainsLocalPoint(const FFootprint& Model, const FVector2d& LocalInches);

struct FDisplayMesh
{
    TArray<FVector3d> VerticesWorldCm;
    TArray<int32> Triangles;
    TArray<FVector3d> NormalsWorld;
    TArray<FVector2D> UV0;
    TArray<FLinearColor> VertexColors;
};

// Tessellation is display only. Query functions below never consume this mesh.
bool BuildDisplayMesh(const FTableFrame& Frame, const FFootprint& Model,
    double ThicknessInches, FDisplayMesh& OutMesh, FDiagnostic& Error);

struct FRay
{
    FVector3d OriginWorldCm = FVector3d::ZeroVector;
    FVector3d DirectionWorldUnit = FVector3d::ZeroVector;
};

enum class EHitKind : uint8 { Model, Support };
struct FAdvisoryHit
{
    EHitKind Kind = EHitKind::Support;
    FString Id;
    FVector3d DomainPosition = FVector3d::ZeroVector;
    FVector3d WorldPosition = FVector3d::ZeroVector;
    double DistanceWorldCm = 0.0;
};

// A miss returns false/NoHit; malformed geometry returns its specific diagnostic.
bool RaycastSupport(const FTableFrame& Frame, const TArray<FSupportSurface>& Supports,
    const FRay& Ray, FAdvisoryHit& OutHit, FDiagnostic& Error);
bool RaycastModels(const FTableFrame& Frame, const TArray<FFootprint>& Models,
    const FRay& Ray, FAdvisoryHit& OutHit, FDiagnostic& Error);
bool RaycastAdvisory(const FTableFrame& Frame, const TArray<FFootprint>& Models,
    const TArray<FSupportSurface>& Supports, const FRay& Ray,
    FAdvisoryHit& OutHit, FDiagnostic& Error);
}
