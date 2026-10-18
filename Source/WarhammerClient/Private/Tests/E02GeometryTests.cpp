#include "Migration/E02Geometry.h"

#if WITH_DEV_AUTOMATION_TESTS

#include "Misc/AutomationTest.h"
#include "Misc/CommandLine.h"
#include "Misc/FileHelper.h"
#include "Misc/Parse.h"
#include "Dom/JsonObject.h"
#include "Serialization/JsonSerializer.h"
#include "KismetProceduralMeshLibrary.h"
#include "ProceduralMeshComponent.h"
#include <limits>

using namespace Warhammer::Migration::E02;

namespace
{
constexpr EAutomationTestFlags NumericFlags = EAutomationTestFlags::EditorContext |
    EAutomationTestFlags::ClientContext | EAutomationTestFlags::EngineFilter;

class FCaseAssertions
{
public:
    FCaseAssertions(FAutomationTestBase& InTest, const TCHAR* InCase) : Test(InTest), Case(InCase) {}
    ~FCaseAssertions()
    {
        Test.AddInfo(FString::Printf(TEXT("%s: actual assertions=%llu"), *Case, static_cast<unsigned long long>(Count)));
    }
    bool TestTrue(const TCHAR* What, bool Value) { ++Count; return Test.TestTrue(What, Value); }
    bool TestFalse(const TCHAR* What, bool Value) { ++Count; return Test.TestFalse(What, Value); }
    template<typename T> bool TestEqual(const TCHAR* What, const T& Actual, const T& Expected)
    {
        ++Count;
        return Test.TestEqual(What, Actual, Expected);
    }
    void AddError(const FString& Message) { Test.AddError(Message); }
    bool HasAnyErrors() const { return Test.HasAnyErrors(); }
private:
    FAutomationTestBase& Test;
    FString Case;
    uint64 Count = 0;
};

bool Fixture(FCaseAssertions& Test, FFixture& Out)
{
    FString Path;
    if (!Test.TestTrue(TEXT("Required absolute fixture argument supplied"), FParse::Value(FCommandLine::Get(), TEXT("E02Fixture="), Path)))
    {
        Test.AddError(TEXT("Required -E02Fixture=<absolute frozen fixture> is missing; no skip or default fixture."));
        return false;
    }
    FDiagnostic Error;
    if (!Test.TestTrue(TEXT("Frozen synthetic fixture validates"), LoadFixture(Path, Out, Error)))
    {
        Test.AddError(FString::Printf(TEXT("Fixture %s at %s: %s"), DiagnosticCodeName(Error.Code), *Error.Field, *Error.Message));
        return false;
    }
    return true;
}
bool NearVector(FCaseAssertions& Test, const TCHAR* What, const FVector3d& Actual,
    const FVector3d& Expected, double Tolerance = 1.e-8)
{
    return Test.TestTrue(What, (Actual - Expected).GetAbsMax() <= Tolerance);
}
Warhammer::Migration::E02::FRay DownRay(const FTableFrame& Frame, const FVector3d& OriginDomain)
{
    return { DomainToWorld(Frame, OriginDomain), Frame.WorldFromTableCm.TransformVectorNoScale(FVector3d(0.0, 0.0, -1.0)) };
}

void AssertOutwardDisplayFaces(FCaseAssertions& Assertions, const FTableFrame& Frame,
    const FFootprint& Model, const FDisplayMesh& Mesh, double Thickness)
{
    if (!Assertions.TestTrue(TEXT("Display has complete triangles and vertex normals"),
        !Mesh.Triangles.IsEmpty() && Mesh.Triangles.Num() % 3 == 0 && Mesh.NormalsWorld.Num() == Mesh.VerticesWorldCm.Num())) return;
    const FVector3d Up = Frame.WorldFromTableCm.TransformVectorNoScale(FVector3d::UpVector);
    FVector2d Interior = FVector2d::ZeroVector;
    // A positive average of a strictly convex polygon's vertices is interior;
    // the other four symmetric descriptors have the local origin as interior.
    if (Model.Kind == EShapeKind::Polygon)
    {
        for (const FVector2d& V : Model.VerticesInches) { Interior += V; }
        Interior /= Model.VerticesInches.Num();
    }
    const double Facing = FMath::DegreesToRadians(Model.Pose->FacingDegrees);
    const FVector3d InteriorDomain = Model.Pose->PositionInches + FVector3d(
        FMath::Cos(Facing) * Interior.X - FMath::Sin(Facing) * Interior.Y,
        FMath::Sin(Facing) * Interior.X + FMath::Cos(Facing) * Interior.Y, 0);
    const FVector3d InteriorWorld = DomainToWorld(Frame, InteriorDomain);
    bool bTop = false, bBottom = false, bSide = false;
    for (int32 T = 0; T < Mesh.Triangles.Num(); T += 3)
    {
        const int32 IA = Mesh.Triangles[T], IB = Mesh.Triangles[T + 1], IC = Mesh.Triangles[T + 2];
        if (!Assertions.TestTrue(TEXT("Every triangle index addresses an actual vertex"),
            Mesh.VerticesWorldCm.IsValidIndex(IA) && Mesh.VerticesWorldCm.IsValidIndex(IB) && Mesh.VerticesWorldCm.IsValidIndex(IC))) return;
        const FVector3d& A = Mesh.VerticesWorldCm[IA];
        const FVector3d& B = Mesh.VerticesWorldCm[IB];
        const FVector3d& C = Mesh.VerticesWorldCm[IC];
        const FVector3d Cross = FVector3d::CrossProduct(B - A, C - A);
        if (!Assertions.TestTrue(TEXT("No degenerate generated triangle"), Cross.SizeSquared() > 1.e-16)) return;
        const FVector3d& Normal = Mesh.NormalsWorld[IA];
        for (const int32 Index : { IA, IB, IC })
        {
            const FVector3d& VertexNormal = Mesh.NormalsWorld[Index];
            Assertions.TestTrue(TEXT("Every face vertex has the same finite outward unit shading normal"),
                !VertexNormal.ContainsNaN() && FMath::Abs(VertexNormal.SizeSquared() - 1.0) < 1.e-9 && VertexNormal.Equals(Normal, 1.e-9));
            Assertions.TestTrue(TEXT("Indexed cross opposes shading normal as in installed UE GenerateBoxMesh"),
                FVector3d::DotProduct(Cross.GetSafeNormal(), VertexNormal) < -0.999999);
        }
        const double ZA = WorldToDomain(Frame, A).Z - Model.Pose->PositionInches.Z;
        const double ZB = WorldToDomain(Frame, B).Z - Model.Pose->PositionInches.Z;
        const double ZC = WorldToDomain(Frame, C).Z - Model.Pose->PositionInches.Z;
        if (FMath::Abs(ZA - Thickness) < 1.e-9 && FMath::Abs(ZB - Thickness) < 1.e-9 && FMath::Abs(ZC - Thickness) < 1.e-9)
        {
            bTop = true;
            Assertions.TestTrue(TEXT("Physical top shading normal points up independently of index convention"), FVector3d::DotProduct(Normal, Up) > 0.999999);
        }
        else if (FMath::Abs(ZA) < 1.e-9 && FMath::Abs(ZB) < 1.e-9 && FMath::Abs(ZC) < 1.e-9)
        {
            bBottom = true;
            Assertions.TestTrue(TEXT("Physical bottom shading normal points down"), FVector3d::DotProduct(Normal, Up) < -0.999999);
        }
        else
        {
            bSide = true;
            Assertions.TestTrue(TEXT("Side shading normal is horizontal and points away from a known interior point"),
                FMath::Abs(FVector3d::DotProduct(Normal, Up)) < 1.e-9 &&
                FVector3d::DotProduct(Normal, (A + B + C) / 3.0 - InteriorWorld) > 1.e-9);
        }
    }
    Assertions.TestTrue(TEXT("Closed shallow display includes top, bottom and outward sides"), bTop && bBottom && bSide);
}
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FE02RoundTrip, "Warhammer.Migration.E02.Numeric.RoundTrip", NumericFlags)
bool FE02RoundTrip::RunTest(const FString& Parameters)
{
    FCaseAssertions Assertions(*this, TEXT("Numeric.RoundTrip"));
    FFixture F;
    if (!Fixture(Assertions, F)) return false;
    Assertions.TestEqual(TEXT("Synthetic form count"), F.Models.Num(), 5);
    Assertions.TestTrue(TEXT("Nonzero board bounds"), F.BoardBoundsInches.Min == FVector2d(-12.0, 7.0) && F.BoardBoundsInches.Max == FVector2d(60.0, 55.0));
    NearVector(Assertions, TEXT("Declared center/datum maps to rigid translation"),
        DomainToWorld(F.Frame, FVector3d(24.0, 31.0, -2.0)), FVector3d(137.0, -83.0, 41.0));
    // Independent golden basis values: 2.54*cos(23deg), 2.54*sin(23deg).
    NearVector(Assertions, TEXT("One domain inch X has correct cm and rigid yaw"),
        DomainToWorld(F.Frame, FVector3d(25.0, 31.0, -2.0)), FVector3d(139.3380823277692, -82.00754293363724, 41.0));
    NearVector(Assertions, TEXT("One domain inch Y is reflected before placement"),
        DomainToWorld(F.Frame, FVector3d(24.0, 32.0, -2.0)), FVector3d(137.99245706636276, -85.3380823277692, 41.0));
    NearVector(Assertions, TEXT("Four inch support elevation remains10.16cm"),
        DomainToWorld(F.Frame, FVector3d(24.0, 31.0, 2.0)), FVector3d(137.0, -83.0, 51.16));
    const FVector3d Points[] = { {-12,7,-2}, {60,55,2}, {0,0,0}, {24,31,-2}, {8,18,-2}, {42,23,2}, {-19.25,72.125,-6.375} };
    FTableFrame Tilted = F.Frame;
    Tilted.WorldFromTableCm = FTransform3d(FRotator3d(12.0, 23.0, -7.0), FVector3d(137.0, -83.0, 41.0), FVector3d::OneVector);
    FDiagnostic Error;
    Assertions.TestTrue(TEXT("Rigid pitch12/roll-7 presentation is valid"), ValidateFrame(Tilted, Error));
    for (const FTableFrame& Frame : { F.Frame, Tilted })
        for (const FVector3d& P : Points)
            NearVector(Assertions, TEXT("Double inverse roundtrip at/beyond both sides of origin"), WorldToDomain(Frame, DomainToWorld(Frame, P)), P);
    const FVector3d OneInch = DomainToWorld(Tilted, FVector3d(25,31,-2)) - DomainToWorld(Tilted, FVector3d(24,31,-2));
    Assertions.TestTrue(TEXT("Rigid tilt preserves2.54cm per inch"), FMath::Abs(OneInch.Size() - 2.54) <= 1.e-10);
    return !Assertions.HasAnyErrors();
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FE02HeadingAxes, "Warhammer.Migration.E02.Numeric.HeadingAxes", NumericFlags)
bool FE02HeadingAxes::RunTest(const FString& Parameters)
{
    FCaseAssertions Assertions(*this, TEXT("Numeric.HeadingAxes"));
    FFixture F;
    if (!Fixture(Assertions, F)) return false;
    NearVector(Assertions, TEXT("Heading0 golden world basis"), HeadingToWorld(F.Frame, 0.0), FVector3d(0.9205048534524404, 0.3907311284892738, 0.0));
    NearVector(Assertions, TEXT("Heading90 reflected golden basis"), HeadingToWorld(F.Frame, 90.0), FVector3d(0.3907311284892738, -0.9205048534524404, 0.0));
    const FVector3d X = HeadingToWorld(F.Frame, 0.0), Y = HeadingToWorld(F.Frame, 90.0);
    Assertions.TestTrue(TEXT("Handed basis is orthogonal"), FMath::Abs(FVector3d::DotProduct(X, Y)) <= 1.e-12);
    Assertions.TestTrue(TEXT("Reflection reverses handedness without negative Actor scale"), FVector3d::CrossProduct(X, Y).Z < -0.999999);
    for (double Heading : { 0.0, 90.0, 37.0, 180.0, 359.999, -37.0, 397.0 })
    {
        const double Recovered = WorldToHeading(F.Frame, HeadingToWorld(F.Frame, Heading));
        Assertions.TestTrue(TEXT("Inverse heading modulo360 within1e-8degree"), FMath::Abs(FMath::FindDeltaAngleDegrees(Heading, Recovered)) <= 1.e-8);
    }
    FTableFrame Tilted = F.Frame;
    Tilted.WorldFromTableCm = FTransform3d(FRotator3d(12.0,23.0,-7.0), FVector3d(137,-83,41), FVector3d::OneVector);
    for (double Heading : {0.0,90.0,37.0})
        Assertions.TestTrue(TEXT("Heading inverse also survives presentation pitch/roll"),
            FMath::Abs(FMath::FindDeltaAngleDegrees(Heading, WorldToHeading(Tilted, HeadingToWorld(Tilted, Heading)))) <= 1.e-8);
    const FFootprint& Ellipse = F.Models[1];
    const FFootprint& Rectangle = F.Models[2];
    Assertions.TestEqual(TEXT("Ellipse stable identity"), Ellipse.Id, FString(TEXT("e02-ellipse")));
    Assertions.TestTrue(TEXT("Ellipse length along localX reaches2.5"), ContainsLocalPoint(Ellipse, FVector2d(2.5, 0)));
    Assertions.TestFalse(TEXT("Ellipse localX stops beyond2.5"), ContainsLocalPoint(Ellipse, FVector2d(2.5001, 0)));
    Assertions.TestFalse(TEXT("Ellipse width along localY stops at1"), ContainsLocalPoint(Ellipse, FVector2d(0, 1.0001)));
    Assertions.TestTrue(TEXT("Rectangle length4/width2 boundary"), ContainsLocalPoint(Rectangle, FVector2d(2, 1)));
    Assertions.TestFalse(TEXT("Rectangle length stops beyond2"), ContainsLocalPoint(Rectangle, FVector2d(2.0001, 0)));
    Assertions.TestFalse(TEXT("Rectangle width is not accidentally4"), ContainsLocalPoint(Rectangle, FVector2d(0, 1.0001)));
    Warhammer::Migration::E02::FRay Ray = DownRay(F.Frame, FVector3d(42,25.4,10));
    FAdvisoryHit Hit;
    FDiagnostic Error;
    Assertions.TestTrue(TEXT("Rotated ellipse long axis lies along domainY"), RaycastModels(F.Frame, { Ellipse }, Ray, Hit, Error));
    Assertions.TestEqual(TEXT("Long-axis hit retains ellipse ID"), Hit.Id, Ellipse.Id);
    Ray = DownRay(F.Frame, FVector3d(43.1,23,10));
    Assertions.TestFalse(TEXT("Rotated ellipse shortX axis misses beyond1inch"), RaycastModels(F.Frame, { Ellipse }, Ray, Hit, Error));
    Assertions.TestTrue(TEXT("Short-axis miss is typed"), Error.Code == EDiagnosticCode::NoHit);
    return !Assertions.HasAnyErrors();
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FE02ShapesWinding, "Warhammer.Migration.E02.Numeric.ShapesWinding", NumericFlags)
bool FE02ShapesWinding::RunTest(const FString& Parameters)
{
    FCaseAssertions Assertions(*this, TEXT("Numeric.ShapesWinding"));
    FFixture F;
    if (!Fixture(Assertions, F)) return false;
    FDiagnostic Error;
    const TCHAR* Ids[] = { TEXT("e02-circle"), TEXT("e02-ellipse"), TEXT("e02-rectangle"), TEXT("e02-capsule"), TEXT("e02-polygon") };
    const double Heights[] = { 1.2, 1.0, 1.5, 1.2, 1.2 };
    const FVector2d ExpectedMin[] = {{-1,-1},{-2.5,-1},{-2,-1},{-3,-1},{0,0}};
    const FVector2d ExpectedMax[] = {{1,1},{2.5,1},{2,1},{3,1},{3,2}};
    // The independent engine helper supplies the actual installed convention.
    // Its +Z face starts (-2,+3,+4),(+2,+3,+4),(-2,-3,+4), whose indexed
    // conventional cross is -Z while its outward shading normal is +Z.
    TArray<FVector> BoxVertices, BoxNormals;
    TArray<int32> BoxTriangles;
    TArray<FVector2D> BoxUVs;
    TArray<FProcMeshTangent> BoxTangents;
    UKismetProceduralMeshLibrary::GenerateBoxMesh(FVector(2, 3, 4), BoxVertices, BoxTriangles, BoxNormals, BoxUVs, BoxTangents);
    if (!Assertions.TestTrue(TEXT("Installed procedural box supplies six complete faces"),
        BoxVertices.Num() == 24 && BoxNormals.Num() == 24 && BoxTriangles.Num() == 36)) return false;
    Assertions.TestTrue(TEXT("Installed upward face agrees with independent integer-coordinate anchor"),
        BoxTriangles[0] == 0 && BoxTriangles[1] == 1 && BoxTriangles[2] == 3 &&
        BoxVertices[0] == FVector(-2, 3, 4) && BoxVertices[1] == FVector(2, 3, 4) && BoxVertices[3] == FVector(-2, -3, 4) &&
        BoxNormals[0] == FVector::UpVector);
    for (int32 T = 0; T < BoxTriangles.Num(); T += 3)
    {
        const int32 IA = BoxTriangles[T], IB = BoxTriangles[T + 1], IC = BoxTriangles[T + 2];
        if (!Assertions.TestTrue(TEXT("Installed box indices address its actual vertices and normals"),
            BoxVertices.IsValidIndex(IA) && BoxVertices.IsValidIndex(IB) && BoxVertices.IsValidIndex(IC))) return false;
        const FVector Cross = FVector::CrossProduct(BoxVertices[IB] - BoxVertices[IA], BoxVertices[IC] - BoxVertices[IA]);
        Assertions.TestTrue(TEXT("Every actual UE box face uses an indexed cross opposite its outward normal"),
            FVector::DotProduct(Cross.GetSafeNormal(), BoxNormals[IA]) < -0.999999 &&
            FVector::DotProduct(BoxNormals[IA], (BoxVertices[IA] + BoxVertices[IB] + BoxVertices[IC]) / 3.0) > 0);
    }
    for (int32 I = 0; I < 5; ++I)
    {
        const FFootprint& Model = F.Models[I];
        Assertions.TestEqual(TEXT("Fixture stable ID/order"), Model.Id, FString(Ids[I]));
        Assertions.TestTrue(TEXT("Each descriptor validates"), ValidateFootprint(Model, Error));
        Assertions.TestTrue(TEXT("Query extrusion independent expected height"), Model.QueryHeightInches == Heights[I]);
        FDisplayMesh Mesh;
        if (!Assertions.TestTrue(TEXT("All five forms build a display mesh"), BuildDisplayMesh(F.Frame, Model, 0.12, Mesh, Error))) return false;
        Assertions.TestTrue(TEXT("Mesh has nonempty triangles"), !Mesh.Triangles.IsEmpty() && Mesh.Triangles.Num() % 3 == 0);
        Assertions.TestEqual(TEXT("Every vertex has normal"), Mesh.NormalsWorld.Num(), Mesh.VerticesWorldCm.Num());
        FVector3d Min(TNumericLimits<double>::Max()), Max(TNumericLimits<double>::Lowest());
        const double Facing = FMath::DegreesToRadians(Model.Pose->FacingDegrees);
        for (const FVector3d& Vertex : Mesh.VerticesWorldCm)
        {
            const FVector3d Offset = WorldToDomain(F.Frame, Vertex) - Model.Pose->PositionInches;
            const FVector3d Local(FMath::Cos(Facing)*Offset.X + FMath::Sin(Facing)*Offset.Y,
                -FMath::Sin(Facing)*Offset.X + FMath::Cos(Facing)*Offset.Y, Offset.Z);
            Min = Min.ComponentMin(Local); Max = Max.ComponentMax(Local);
        }
        NearVector(Assertions, TEXT("Display local minima preserve independent expected dimensions"), Min, FVector3d(ExpectedMin[I].X,ExpectedMin[I].Y,0));
        NearVector(Assertions, TEXT("Display local maxima preserve lengthX/widthY/thickness"), Max, FVector3d(ExpectedMax[I].X,ExpectedMax[I].Y,0.12));
        AssertOutwardDisplayFaces(Assertions, F.Frame, Model, Mesh, 0.12);
        FTableFrame TiltedFrame = F.Frame;
        TiltedFrame.WorldFromTableCm.SetRotation(FQuat4d(FRotator3d(17, 23, -11)));
        FDisplayMesh TiltedMesh;
        if (!Assertions.TestTrue(TEXT("All five forms build in a pitched and rolled rigid placement"),
            BuildDisplayMesh(TiltedFrame, Model, 0.12, TiltedMesh, Error))) return false;
        AssertOutwardDisplayFaces(Assertions, TiltedFrame, Model, TiltedMesh, 0.12);
        FVector3d Origin = Model.Pose->PositionInches + FVector3d(0,0,20);
        // Polygon origin is a boundary vertex; choose a known interior point.
        if (I == 4) Origin += FVector3d(0.1830127018922193, 0.6830127018922193, 0);
        FAdvisoryHit Hit;
        if (Assertions.TestTrue(TEXT("Analytic volume queried independently of mesh"), RaycastModels(F.Frame, { Model }, DownRay(F.Frame, Origin), Hit, Error)))
        {
            Assertions.TestEqual(TEXT("Query retains stable ID"), Hit.Id, Model.Id);
            Assertions.TestTrue(TEXT("Analytic top uses query height, not0.12visual"), FMath::Abs(Hit.DomainPosition.Z - (Model.Pose->PositionInches.Z + Heights[I])) < 1.e-8);
        }
    }
    Assertions.TestTrue(TEXT("Circle radius1 boundary"), ContainsLocalPoint(F.Models[0], FVector2d(1,0)));
    Assertions.TestFalse(TEXT("Circle beyond boundary misses"), ContainsLocalPoint(F.Models[0], FVector2d(1.0001,0)));
    Assertions.TestTrue(TEXT("Synthetic capsule is explicit"), F.Models[3].bSyntheticCapsule);
    Assertions.TestTrue(TEXT("Capsule total length6 reaches3"), ContainsLocalPoint(F.Models[3], FVector2d(3,0)));
    Assertions.TestFalse(TEXT("Capsule total length stops beyond3"), ContainsLocalPoint(F.Models[3], FVector2d(3.0001,0)));
    Assertions.TestFalse(TEXT("Capsule rounded corner excludes bounding rectangle"), ContainsLocalPoint(F.Models[3], FVector2d(2.9,0.9)));
    FFootprint CircularCapsule = F.Models[3];
    CircularCapsule.LengthInches = 2.0;
    FDisplayMesh CircleLimitMesh;
    Assertions.TestTrue(TEXT("Equal length/width capsule has exact circular limit"), BuildDisplayMesh(F.Frame, CircularCapsule, 0.12, CircleLimitMesh, Error));
    AssertOutwardDisplayFaces(Assertions, F.Frame, CircularCapsule, CircleLimitMesh, 0.12);
    for (int32 T = 0; T < CircleLimitMesh.Triangles.Num(); T += 3)
    {
        const FVector3d& A = CircleLimitMesh.VerticesWorldCm[CircleLimitMesh.Triangles[T]];
        const FVector3d& B = CircleLimitMesh.VerticesWorldCm[CircleLimitMesh.Triangles[T + 1]];
        const FVector3d& C = CircleLimitMesh.VerticesWorldCm[CircleLimitMesh.Triangles[T + 2]];
        Assertions.TestTrue(TEXT("Circular-limit capsule has no degenerate join triangles"), FVector3d::CrossProduct(B-A,C-A).SizeSquared() > 1.e-16);
    }
    Assertions.TestTrue(TEXT("Circular-limit capsule contains left circle boundary"), ContainsLocalPoint(CircularCapsule, FVector2d(-1,0)));
    Assertions.TestFalse(TEXT("Circular-limit capsule excludes square corner"), ContainsLocalPoint(CircularCapsule, FVector2d(-0.9,0.9)));
    FAdvisoryHit CircleLimitHit;
    Assertions.TestTrue(TEXT("Circular-limit analytic side ray hits left hemisphere"), RaycastModels(F.Frame, {CircularCapsule},
        {DomainToWorld(F.Frame, FVector3d(16,38,-1.4)), HeadingToWorld(F.Frame,0)}, CircleLimitHit, Error));
    NearVector(Assertions, TEXT("Circular-limit independent left-side endpoint"), CircleLimitHit.DomainPosition, FVector3d(17,38,-1.4));
    Assertions.TestTrue(TEXT("Asymmetric polygon independent shoelace area3.5"), FMath::Abs(PolygonSignedArea(F.Models[4].VerticesInches) - 3.5) < 1.e-12);
    Assertions.TestFalse(TEXT("Polygon outside diagonal excluded"), ContainsLocalPoint(F.Models[4], FVector2d(2.8,1.5)));
    FAdvisoryHit Hit;
    Assertions.TestTrue(TEXT("Raised support nearer than ground"), RaycastSupport(F.Frame, F.Supports, DownRay(F.Frame, FVector3d(27,27,10)), Hit, Error));
    Assertions.TestEqual(TEXT("Nearest support ID"), Hit.Id, FString(TEXT("e02-platform")));
    Assertions.TestTrue(TEXT("Raised supportZ retained"), FMath::Abs(Hit.DomainPosition.Z - 2.0) < 1.e-8);
    Assertions.TestFalse(TEXT("Open support hole misses raised plane"), RaycastSupport(F.Frame, {F.Supports[1]}, DownRay(F.Frame, FVector3d(35,23,10)), Hit, Error));
    Assertions.TestTrue(TEXT("Hole miss is typed"), Error.Code == EDiagnosticCode::NoHit);
    Assertions.TestTrue(TEXT("Through-hole ray can reach ground"), RaycastSupport(F.Frame, F.Supports, DownRay(F.Frame, FVector3d(35,23,10)), Hit, Error));
    Assertions.TestEqual(TEXT("Hole reaches ground identity"), Hit.Id, FString(TEXT("e02-ground")));
    Assertions.TestFalse(TEXT("Outside support edge is not clamped"), RaycastSupport(F.Frame, {F.Supports[1]}, DownRay(F.Frame, FVector3d(48.0001,27,10)), Hit, Error));

    // Coincident analytic descriptors exercise depth/identity ordering without
    // altering the frozen five-pose scene or consuming display geometry. IDs
    // differ only in case so an accidental case-insensitive comparison fails.
    const FTableFrame PickingFrame;
    const Warhammer::Migration::E02::FRay PickingRay = DownRay(PickingFrame, FVector3d(0,0,10));
    FFootprint ModelA = F.Models[0];
    ModelA.Id = TEXT("e02-A-model");
    ModelA.Pose = FDomainPose { FVector3d::ZeroVector, 0.0 };
    ModelA.QueryHeightInches = 1.0;
    FFootprint ModelZ = ModelA;
    ModelZ.Id = TEXT("e02-a-model");
    FSupportSurface SupportA;
    SupportA.Id = TEXT("e02-A-support");
    SupportA.BoundsInches = { FVector2d(-1,-1), FVector2d(1,1) };
    SupportA.ZInches = 1.0;
    FSupportSurface SupportZ = SupportA;
    SupportZ.Id = TEXT("e02-a-support");
    FAdvisoryHit BaselineModel, BaselineSupport;
    if (!Assertions.TestTrue(TEXT("Independent coincident model baseline hits"),
        RaycastModels(PickingFrame, {ModelA}, PickingRay, BaselineModel, Error))) return false;
    if (!Assertions.TestTrue(TEXT("Independent coincident support baseline hits"),
        RaycastSupport(PickingFrame, {SupportA}, PickingRay, BaselineSupport, Error))) return false;
    Assertions.TestEqual(TEXT("Mixed tie has exactly equal computed double depth"),
        BaselineModel.DistanceWorldCm, BaselineSupport.DistanceWorldCm);
    for (const bool bReverse : { false, true })
    {
        const TArray<FFootprint> Models = bReverse ? TArray<FFootprint>{ModelZ,ModelA} : TArray<FFootprint>{ModelA,ModelZ};
        if (Assertions.TestTrue(TEXT("Coincident models hit in either descriptor order"),
            RaycastModels(PickingFrame, Models, PickingRay, Hit, Error)))
        {
            Assertions.TestEqual(TEXT("Exact model depth tie chooses earlier stable ID in either order"), Hit.Id, ModelA.Id);
            Assertions.TestEqual(TEXT("Model tie preserves the actual depth"), Hit.DistanceWorldCm, BaselineModel.DistanceWorldCm);
        }
        const TArray<FSupportSurface> Supports = bReverse ? TArray<FSupportSurface>{SupportZ,SupportA} : TArray<FSupportSurface>{SupportA,SupportZ};
        if (Assertions.TestTrue(TEXT("Coincident supports hit in either descriptor order"),
            RaycastSupport(PickingFrame, Supports, PickingRay, Hit, Error)))
        {
            Assertions.TestEqual(TEXT("Exact support depth tie chooses earlier stable ID in either order"), Hit.Id, SupportA.Id);
            Assertions.TestEqual(TEXT("Support tie preserves the actual depth"), Hit.DistanceWorldCm, BaselineSupport.DistanceWorldCm);
        }
    }
    if (Assertions.TestTrue(TEXT("Mixed exact tie with earlier model identity hits"),
        RaycastAdvisory(PickingFrame, {ModelA}, {SupportZ}, PickingRay, Hit, Error)))
    {
        Assertions.TestEqual(TEXT("Global ID order can choose model over coincident support"), Hit.Id, ModelA.Id);
        Assertions.TestTrue(TEXT("Earlier model identity retains model kind"), Hit.Kind == EHitKind::Model);
    }
    if (Assertions.TestTrue(TEXT("Mixed exact tie with earlier support identity hits"),
        RaycastAdvisory(PickingFrame, {ModelZ}, {SupportA}, PickingRay, Hit, Error)))
    {
        Assertions.TestEqual(TEXT("Global ID order can choose support over coincident model"), Hit.Id, SupportA.Id);
        Assertions.TestTrue(TEXT("Earlier support identity retains support kind"), Hit.Kind == EHitKind::Support);
    }

    // The difference is representable but smaller than the geometry boundary
    // tolerance. It must remain a depth difference, never an ID tie group.
    FFootprint NearModelZ = ModelZ;
    NearModelZ.QueryHeightInches += 1.e-12;
    FSupportSurface NearSupportZ = SupportZ;
    NearSupportZ.ZInches += 1.e-12;
    Assertions.TestTrue(TEXT("Near-depth control uses a positive sub-tolerance separation"),
        NearModelZ.QueryHeightInches > ModelA.QueryHeightInches &&
        NearModelZ.QueryHeightInches - ModelA.QueryHeightInches < 1.e-10);
    auto StrictlyNearer = [&Assertions](const FAdvisoryHit& Near, const FAdvisoryHit& Far)
    {
        const double DifferenceCm = Far.DistanceWorldCm - Near.DistanceWorldCm;
        Assertions.TestTrue(TEXT("Representably nearer hit wins even below1e-10cm"), DifferenceCm > 0.0 && DifferenceCm < 1.e-10);
    };
    for (const bool bReverse : { false, true })
    {
        const TArray<FFootprint> Models = bReverse ? TArray<FFootprint>{NearModelZ,ModelA} : TArray<FFootprint>{ModelA,NearModelZ};
        if (Assertions.TestTrue(TEXT("Unequal-depth models hit in either descriptor order"),
            RaycastModels(PickingFrame, Models, PickingRay, Hit, Error)))
        {
            Assertions.TestEqual(TEXT("Nearer model wins despite lexically later ID in either order"), Hit.Id, NearModelZ.Id);
            StrictlyNearer(Hit, BaselineModel);
        }
        const TArray<FSupportSurface> Supports = bReverse ? TArray<FSupportSurface>{NearSupportZ,SupportA} : TArray<FSupportSurface>{SupportA,NearSupportZ};
        if (Assertions.TestTrue(TEXT("Unequal-depth supports hit in either descriptor order"),
            RaycastSupport(PickingFrame, Supports, PickingRay, Hit, Error)))
        {
            Assertions.TestEqual(TEXT("Nearer support wins despite lexically later ID in either order"), Hit.Id, NearSupportZ.Id);
            StrictlyNearer(Hit, BaselineSupport);
        }
    }
    if (Assertions.TestTrue(TEXT("Nearer model competes with lexically earlier support"),
        RaycastAdvisory(PickingFrame, {NearModelZ}, {SupportA}, PickingRay, Hit, Error)))
    {
        Assertions.TestEqual(TEXT("Depth precedes global ID when the model is nearer"), Hit.Id, NearModelZ.Id);
        StrictlyNearer(Hit, BaselineSupport);
    }
    if (Assertions.TestTrue(TEXT("Nearer support competes with lexically earlier model"),
        RaycastAdvisory(PickingFrame, {ModelA}, {NearSupportZ}, PickingRay, Hit, Error)))
    {
        Assertions.TestEqual(TEXT("Depth precedes global ID when the support is nearer"), Hit.Id, NearSupportZ.Id);
        StrictlyNearer(Hit, BaselineModel);
    }
    return !Assertions.HasAnyErrors();
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FE02UnsupportedGeometry, "Warhammer.Migration.E02.Numeric.UnsupportedGeometry", NumericFlags)
bool FE02UnsupportedGeometry::RunTest(const FString& Parameters)
{
    FCaseAssertions Assertions(*this, TEXT("Numeric.UnsupportedGeometry"));
    FFixture F;
    if (!Fixture(Assertions, F)) return false;
    auto Rejected = [&Assertions, &F](const TCHAR* Name, const FFootprint& Model, EDiagnosticCode Code)
    {
        FDiagnostic Error;
        FDisplayMesh Mesh;
        Assertions.TestFalse(Name, ValidateFootprint(Model, Error));
        Assertions.TestTrue(TEXT("Exact typed validation diagnostic"), Error.Code == Code);
        Assertions.TestFalse(TEXT("Unsupported data never generates substitute mesh"), BuildDisplayMesh(F.Frame, Model, 0.12, Mesh, Error));
        Assertions.TestTrue(TEXT("Mesh rejection preserves diagnostic"), Error.Code == Code);
        Assertions.TestTrue(TEXT("No generated vertices on fresh failure output"), Mesh.VerticesWorldCm.IsEmpty());
        FAdvisoryHit Hit;
        Assertions.TestFalse(TEXT("Unsupported data cannot silently vanish from query"), RaycastModels(F.Frame, {Model}, DownRay(F.Frame, FVector3d(8,18,10)), Hit, Error));
        Assertions.TestTrue(TEXT("Query has same exact typed diagnostic"), Error.Code == Code);
    };
    FFootprint Bad = F.Models[0]; Bad.RadiusInches.Reset();
    Rejected(TEXT("Missing radius"), Bad, EDiagnosticCode::MissingDimension);
    Bad = F.Models[1]; Bad.LengthInches.Reset();
    Rejected(TEXT("Missing length"), Bad, EDiagnosticCode::MissingDimension);
    Bad = F.Models[2]; Bad.WidthInches = 0.0;
    Rejected(TEXT("Nonpositive width"), Bad, EDiagnosticCode::MissingDimension);
    Bad = F.Models[0]; Bad.RadiusInches = std::numeric_limits<double>::quiet_NaN();
    Rejected(TEXT("Nonfinite radius"), Bad, EDiagnosticCode::NonFinite);
    Bad = F.Models[0]; Bad.Pose->PositionInches.Z = std::numeric_limits<double>::infinity();
    Rejected(TEXT("Nonfinite elevation"), Bad, EDiagnosticCode::NonFinite);
    Bad = F.Models[0]; Bad.Kind = EShapeKind::Unknown;
    Rejected(TEXT("Unknown shape"), Bad, EDiagnosticCode::UnknownShape);
    Bad = F.Models[0]; Bad.Pose.Reset();
    Rejected(TEXT("Null pose"), Bad, EDiagnosticCode::NullPose);
    Bad = F.Models[4]; Bad.VerticesInches = {{0,0},{2,2},{0,2},{2,0}};
    Rejected(TEXT("Self-intersecting polygon"), Bad, EDiagnosticCode::InvalidPolygon);
    Bad = F.Models[4]; Bad.VerticesInches = {{0,0},{1,0},{2,0}};
    Rejected(TEXT("Degenerate polygon"), Bad, EDiagnosticCode::InvalidPolygon);
    Bad = F.Models[4]; Bad.VerticesInches = {{0,0},{0,2},{2,1},{3,0}};
    Rejected(TEXT("Wrong domain winding"), Bad, EDiagnosticCode::InvalidPolygon);
    Bad = F.Models[4]; Bad.VerticesInches = {{0,0},{3,0},{1,0.5},{0,2}};
    Rejected(TEXT("Concave polygon"), Bad, EDiagnosticCode::InvalidPolygon);
    Bad = F.Models[3]; Bad.bSyntheticCapsule = false;
    Rejected(TEXT("Capsule cannot imply canonical Core kind"), Bad, EDiagnosticCode::InvalidFixture);
    FTableFrame Scaled = F.Frame; Scaled.WorldFromTableCm.SetScale3D(FVector3d(1,-1,1));
    FDiagnostic Error;
    Assertions.TestFalse(TEXT("Actor negative scale is rejected"), ValidateFrame(Scaled, Error));
    Assertions.TestTrue(TEXT("Nonrigid frame exact diagnostic"), Error.Code == EDiagnosticCode::InvalidFrame);
    FAdvisoryHit Hit;
    Assertions.TestFalse(TEXT("Zero direction is not invented as down ray"), RaycastAdvisory(F.Frame, F.Models, F.Supports,
        {FVector3d::ZeroVector,FVector3d::ZeroVector}, Hit, Error));
    Assertions.TestTrue(TEXT("Invalid ray exact diagnostic"), Error.Code == EDiagnosticCode::InvalidRay);
    // Malformed fixture controls operate on in-memory JSON only. They do not
    // create alternate fixture files or exercise a rendered input route.
    FString FixturePath, RawFixture;
    FParse::Value(FCommandLine::Get(), TEXT("E02Fixture="), FixturePath);
    if (!Assertions.TestTrue(TEXT("Read original fixture for pure parser controls"), FFileHelper::LoadFileToString(RawFixture, *FixturePath))) return false;
    auto RejectedFixture = [&Assertions, &RawFixture](const TCHAR* Name,
        TFunction<void(const TSharedPtr<FJsonObject>&)> Mutate, EDiagnosticCode Expected)
    {
        TSharedPtr<FJsonObject> Root;
        if (!Assertions.TestTrue(TEXT("Original JSON parses for controlled mutation"), FJsonSerializer::Deserialize(TJsonReaderFactory<>::Create(RawFixture), Root))) return;
        Mutate(Root);
        FString Mutated;
        FJsonSerializer::Serialize(Root.ToSharedRef(), TJsonWriterFactory<>::Create(&Mutated));
        FFixture Unsupported;
        FDiagnostic Diagnostic;
        Assertions.TestFalse(Name, ParseFixtureJson(Mutated, Unsupported, Diagnostic));
        Assertions.TestTrue(TEXT("Every rejected fixture supplies exact non-None diagnostic"), Diagnostic.Code == Expected);
        Assertions.TestTrue(TEXT("Failure does not publish partial/substitute fixture"), Unsupported.Models.IsEmpty());
    };
    RejectedFixture(TEXT("Nonpositive fixture visual thickness"), [](const TSharedPtr<FJsonObject>& Root)
        { Root->SetNumberField(TEXT("visual_thickness_inches"), 0.0); }, EDiagnosticCode::MissingDimension);
    RejectedFixture(TEXT("Invalid fixture camera range"), [](const TSharedPtr<FJsonObject>& Root)
        { Root->GetObjectField(TEXT("camera"))->SetNumberField(TEXT("minimum_distance_cm"), -1.0); }, EDiagnosticCode::InvalidFixture);
    RejectedFixture(TEXT("Frozen camera FOV cannot silently change"), [](const TSharedPtr<FJsonObject>& Root)
        { Root->GetObjectField(TEXT("camera"))->SetNumberField(TEXT("fov_degrees"), 60.0); }, EDiagnosticCode::InvalidFixture);
    RejectedFixture(TEXT("Missing model count is typed"), [](const TSharedPtr<FJsonObject>& Root)
        { TArray<TSharedPtr<FJsonValue>> Models = Root->GetArrayField(TEXT("models")); Models.Pop(); Root->SetArrayField(TEXT("models"), Models); }, EDiagnosticCode::InvalidFixture);
    RejectedFixture(TEXT("Mistyped support hole is typed"), [](const TSharedPtr<FJsonObject>& Root)
        { Root->GetArrayField(TEXT("supports"))[1]->AsObject()->SetArrayField(TEXT("holes_inches"), {MakeShared<FJsonValueBoolean>(true)}); }, EDiagnosticCode::InvalidFixture);
    RejectedFixture(TEXT("Invalid frozen light is typed"), [](const TSharedPtr<FJsonObject>& Root)
        { Root->GetObjectField(TEXT("presentation"))->SetNumberField(TEXT("light_intensity_lux"), -1.0); }, EDiagnosticCode::InvalidFixture);
    return !Assertions.HasAnyErrors();
}

#endif
