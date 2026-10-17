#include "Migration/E02Geometry.h"

#include "Dom/JsonObject.h"
#include "Misc/FileHelper.h"
#include "Misc/Paths.h"
#include "Serialization/JsonReader.h"
#include "Serialization/JsonSerializer.h"
#include <limits>

namespace Warhammer::Migration::E02
{
namespace
{
constexpr double Epsilon = 1.e-10;
bool Finite(const FVector2d& V) { return FMath::IsFinite(V.X) && FMath::IsFinite(V.Y); }
bool Finite(const FVector3d& V) { return FMath::IsFinite(V.X) && FMath::IsFinite(V.Y) && FMath::IsFinite(V.Z); }
bool Fail(FDiagnostic& Error, EDiagnosticCode Code, const FString& Field, const TCHAR* Message)
{
    Error = { Code, Field, Message };
    return false;
}
double Cross(const FVector2d& A, const FVector2d& B) { return A.X * B.Y - A.Y * B.X; }
FVector2d Rotate(const FVector2d& V, double Degrees)
{
    const double Radians = FMath::DegreesToRadians(Degrees);
    const double C = FMath::Cos(Radians), S = FMath::Sin(Radians);
    return { C * V.X - S * V.Y, S * V.X + C * V.Y };
}
bool InBounds(const FBounds2d& Bounds, const FVector2d& P)
{
    return P.X >= Bounds.Min.X && P.X <= Bounds.Max.X && P.Y >= Bounds.Min.Y && P.Y <= Bounds.Max.Y;
}
bool ValidBounds(const FBounds2d& Bounds)
{
    return Finite(Bounds.Min) && Finite(Bounds.Max) && Bounds.Min.X < Bounds.Max.X && Bounds.Min.Y < Bounds.Max.Y;
}
bool Positive(const TOptional<double>& Value, const FString& Field, FDiagnostic& Error)
{
    if (!Value.IsSet()) return Fail(Error, EDiagnosticCode::MissingDimension, Field, TEXT("Required dimension is absent."));
    if (!FMath::IsFinite(Value.GetValue())) return Fail(Error, EDiagnosticCode::NonFinite, Field, TEXT("Dimension must be finite."));
    return Value.GetValue() > 0.0 || Fail(Error, EDiagnosticCode::MissingDimension, Field, TEXT("Dimension must be positive."));
}
bool ReadNumber(const TSharedPtr<FJsonObject>& Object, const TCHAR* Name, double& Out, FDiagnostic& Error)
{
    const TSharedPtr<FJsonValue>* V = Object->Values.Find(Name);
    if (!V || !V->IsValid() || (*V)->Type != EJson::Number)
        return Fail(Error, EDiagnosticCode::InvalidFixture, Name, TEXT("Required numeric field is missing or mistyped."));
    Out = (*V)->AsNumber();
    return FMath::IsFinite(Out) || Fail(Error, EDiagnosticCode::NonFinite, Name, TEXT("Numeric fixture value must be finite."));
}
bool ReadString(const TSharedPtr<FJsonObject>& Object, const TCHAR* Name, FString& Out, FDiagnostic& Error)
{
    const TSharedPtr<FJsonValue>* V = Object->Values.Find(Name);
    if (!V || !V->IsValid() || (*V)->Type != EJson::String || (*V)->AsString().IsEmpty())
        return Fail(Error, EDiagnosticCode::InvalidFixture, Name, TEXT("Required nonempty string is missing or mistyped."));
    Out = (*V)->AsString();
    return true;
}
bool ReadBool(const TSharedPtr<FJsonObject>& Object, const TCHAR* Name, bool& Out, FDiagnostic& Error)
{
    const TSharedPtr<FJsonValue>* Value = Object->Values.Find(Name);
    if (!Value || !Value->IsValid() || (*Value)->Type != EJson::Boolean)
        return Fail(Error, EDiagnosticCode::InvalidFixture, Name, TEXT("Required boolean is missing or mistyped."));
    Out = (*Value)->AsBool();
    return true;
}
bool ReadObject(const TSharedPtr<FJsonObject>& Object, const TCHAR* Name, TSharedPtr<FJsonObject>& Out, FDiagnostic& Error)
{
    const TSharedPtr<FJsonValue>* V = Object->Values.Find(Name);
    if (!V || !V->IsValid() || (*V)->Type != EJson::Object)
        return Fail(Error, EDiagnosticCode::InvalidFixture, Name, TEXT("Required object is missing or mistyped."));
    Out = (*V)->AsObject();
    return true;
}
bool ReadArray(const TSharedPtr<FJsonObject>& Object, const TCHAR* Name, TArray<TSharedPtr<FJsonValue>>& Out, FDiagnostic& Error)
{
    const TSharedPtr<FJsonValue>* V = Object->Values.Find(Name);
    if (!V || !V->IsValid() || (*V)->Type != EJson::Array)
        return Fail(Error, EDiagnosticCode::InvalidFixture, Name, TEXT("Required array is missing or mistyped."));
    Out = (*V)->AsArray();
    return true;
}
bool ReadVector(const TSharedPtr<FJsonObject>& Object, const TCHAR* Name, int32 Count, FVector3d& Out, FDiagnostic& Error)
{
    TArray<TSharedPtr<FJsonValue>> Values;
    if (!ReadArray(Object, Name, Values, Error)) return false;
    if (Values.Num() != Count) return Fail(Error, EDiagnosticCode::InvalidFixture, Name, TEXT("Vector has the wrong dimension."));
    double Components[3] = { 0.0, 0.0, 0.0 };
    for (int32 I = 0; I < Count; ++I)
    {
        if (!Values[I].IsValid() || Values[I]->Type != EJson::Number || !FMath::IsFinite(Values[I]->AsNumber()))
            return Fail(Error, EDiagnosticCode::NonFinite, Name, TEXT("Vector component is missing, mistyped or nonfinite."));
        Components[I] = Values[I]->AsNumber();
    }
    Out = FVector3d(Components[0], Components[1], Components[2]);
    return true;
}
bool ReadBounds(const TSharedPtr<FJsonObject>& Object, FBounds2d& Out, FDiagnostic& Error)
{
    FVector3d Min, Max;
    if (!ReadVector(Object, TEXT("min"), 2, Min, Error) || !ReadVector(Object, TEXT("max"), 2, Max, Error)) return false;
    Out = { FVector2d(Min.X, Min.Y), FVector2d(Max.X, Max.Y) };
    return ValidBounds(Out) || Fail(Error, EDiagnosticCode::InvalidFixture, TEXT("bounds"), TEXT("Bounds must be finite and strictly ordered."));
}
bool ReadOptionalDimension(const TSharedPtr<FJsonObject>& Object, const TCHAR* Name, TOptional<double>& Out, FDiagnostic& Error)
{
    const TSharedPtr<FJsonValue>* V = Object->Values.Find(Name);
    if (!V || !V->IsValid()) return Fail(Error, EDiagnosticCode::InvalidFixture, Name, TEXT("Dimension must explicitly be numeric or null."));
    if ((*V)->Type == EJson::Null) { Out.Reset(); return true; }
    double Number;
    if (!ReadNumber(Object, Name, Number, Error)) return false;
    Out = Number;
    return true;
}
bool RayInDomain(const FTableFrame& Frame, const FRay& Ray, FVector3d& Origin, FVector3d& Direction, FDiagnostic& Error)
{
    if (!ValidateFrame(Frame, Error)) return false;
    if (!Finite(Ray.OriginWorldCm) || !Finite(Ray.DirectionWorldUnit) ||
        FMath::Abs(Ray.DirectionWorldUnit.SizeSquared() - 1.0) > 1.e-8)
        return Fail(Error, EDiagnosticCode::InvalidRay, TEXT("ray"), TEXT("World ray requires finite origin and a unit direction."));
    Origin = WorldToDomain(Frame, Ray.OriginWorldCm);
    const FVector3d Local = Frame.WorldFromTableCm.InverseTransformVectorNoScale(Ray.DirectionWorldUnit) / CentimetresPerInch;
    Direction = FVector3d(Local.X, -Local.Y, Local.Z);
    // Do not normalize: the parameter remains distance in world centimetres.
    return true;
}
void AddQuadraticRoots(double A, double B, double C, TArray<double>& Candidates)
{
    if (FMath::Abs(A) < Epsilon) return;
    const double Discriminant = B * B - 4.0 * A * C;
    const double Roundoff = 16.0 * std::numeric_limits<double>::epsilon() *
        (FMath::Abs(B * B) + FMath::Abs(4.0 * A * C));
    if (Discriminant < -Roundoff) return;
    const double Root = FMath::Sqrt(FMath::Max(0.0, Discriminant));
    // Stable roots avoid cancellation for the distant side of a small footprint.
    const double Q = -0.5 * (B + (B >= 0.0 ? Root : -Root));
    if (Q == 0.0) Candidates.Add(-B / (2.0 * A));
    else { Candidates.Add(Q / A); Candidates.Add(C / Q); }
}
FVector3d PosePoint(const FDomainPose& Pose, const FVector2d& Local, double ZOffset)
{
    const FVector2d XY = Rotate(Local, Pose.FacingDegrees);
    return Pose.PositionInches + FVector3d(XY.X, XY.Y, ZOffset);
}
void FillHit(const FRay& Ray, const FVector3d& Origin,
    const FVector3d& Direction, double Distance, EHitKind Kind, const FString& Id, FAdvisoryHit& Out)
{
    Out = { Kind, Id, Origin + Direction * Distance, Ray.OriginWorldCm + Ray.DirectionWorldUnit * Distance, Distance };
}
bool HitPrecedes(double Distance, const FString& Id, double BestDistance, const FString& BestId)
{
    // Depth is the computed double ray distance in world centimetres. Only exact
    // equality uses the case-sensitive ordinal ID order: a tolerance must never
    // allow a representably farther hit to win because of its identity.
    return Distance < BestDistance ||
        (Distance == BestDistance && Id.Compare(BestId, ESearchCase::CaseSensitive) < 0);
}
}

const TCHAR* DiagnosticCodeName(EDiagnosticCode Code)
{
    switch (Code)
    {
    case EDiagnosticCode::None: return TEXT("None");
    case EDiagnosticCode::InvalidFixture: return TEXT("InvalidFixture");
    case EDiagnosticCode::MissingDimension: return TEXT("MissingDimension");
    case EDiagnosticCode::NonFinite: return TEXT("NonFinite");
    case EDiagnosticCode::UnknownShape: return TEXT("UnknownShape");
    case EDiagnosticCode::NullPose: return TEXT("NullPose");
    case EDiagnosticCode::InvalidPolygon: return TEXT("InvalidPolygon");
    case EDiagnosticCode::InvalidFrame: return TEXT("InvalidFrame");
    case EDiagnosticCode::InvalidRay: return TEXT("InvalidRay");
    case EDiagnosticCode::NoHit: return TEXT("NoHit");
    case EDiagnosticCode::InvalidInput: return TEXT("InvalidInput");
    case EDiagnosticCode::ProofHasNoGameSession: return TEXT("ProofHasNoGameSession");
    }
    return TEXT("UnknownDiagnostic");
}

bool ValidateFrame(const FTableFrame& Frame, FDiagnostic& Error)
{
    const FQuat4d Rotation = Frame.WorldFromTableCm.GetRotation();
    if (!Finite(Frame.CenterInches) || !FMath::IsFinite(Frame.DatumInches) ||
        !Finite(Frame.WorldFromTableCm.GetTranslation()) || Rotation.ContainsNaN() ||
        !Rotation.IsNormalized() || !Frame.WorldFromTableCm.GetScale3D().Equals(FVector3d::OneVector, 1.e-12))
        return Fail(Error, EDiagnosticCode::InvalidFrame, TEXT("frame"), TEXT("Frame must be finite, rigid and unit scale."));
    Error = {};
    return true;
}
FVector3d DomainToWorld(const FTableFrame& Frame, const FVector3d& P)
{
    return Frame.WorldFromTableCm.TransformPosition(FVector3d(P.X - Frame.CenterInches.X,
        -(P.Y - Frame.CenterInches.Y), P.Z - Frame.DatumInches) * CentimetresPerInch);
}
FVector3d WorldToDomain(const FTableFrame& Frame, const FVector3d& P)
{
    const FVector3d Q = Frame.WorldFromTableCm.InverseTransformPosition(P) / CentimetresPerInch;
    return { Frame.CenterInches.X + Q.X, Frame.CenterInches.Y - Q.Y, Frame.DatumInches + Q.Z };
}
FVector3d HeadingToWorld(const FTableFrame& Frame, double Degrees)
{
    const double R = FMath::DegreesToRadians(Degrees);
    return Frame.WorldFromTableCm.TransformVectorNoScale(FVector3d(FMath::Cos(R), -FMath::Sin(R), 0.0));
}
double WorldToHeading(const FTableFrame& Frame, const FVector3d& Direction)
{
    const FVector3d Q = Frame.WorldFromTableCm.InverseTransformVectorNoScale(Direction);
    double Result = FMath::RadiansToDegrees(FMath::Atan2(-Q.Y, Q.X));
    if (Result < 0.0) Result += 360.0;
    return Result;
}
double PolygonSignedArea(const TArray<FVector2d>& Vertices)
{
    double TwiceArea = 0.0;
    for (int32 I = 0; I < Vertices.Num(); ++I) TwiceArea += Cross(Vertices[I], Vertices[(I + 1) % Vertices.Num()]);
    return TwiceArea * 0.5;
}
bool ValidateFootprint(const FFootprint& Model, FDiagnostic& Error)
{
    if (Model.Kind != EShapeKind::Circle && Model.Kind != EShapeKind::Ellipse && Model.Kind != EShapeKind::Rectangle &&
        Model.Kind != EShapeKind::Capsule && Model.Kind != EShapeKind::Polygon)
        return Fail(Error, EDiagnosticCode::UnknownShape, Model.Id, TEXT("Unsupported shape; no substitute is generated."));
    if (!Model.Pose.IsSet()) return Fail(Error, EDiagnosticCode::NullPose, Model.Id, TEXT("A null pose cannot become an origin pose."));
    if (!Finite(Model.Pose->PositionInches) || !FMath::IsFinite(Model.Pose->FacingDegrees) || !FMath::IsFinite(Model.QueryHeightInches))
        return Fail(Error, EDiagnosticCode::NonFinite, Model.Id, TEXT("Pose and query height must be finite."));
    if (Model.Id.IsEmpty() || Model.QueryHeightInches <= 0.0)
        return Fail(Error, EDiagnosticCode::MissingDimension, Model.Id, TEXT("Stable ID and positive query height are required."));
    if (Model.Kind == EShapeKind::Circle && !Positive(Model.RadiusInches, TEXT("radius"), Error)) return false;
    if (Model.Kind == EShapeKind::Ellipse || Model.Kind == EShapeKind::Rectangle || Model.Kind == EShapeKind::Capsule)
    {
        if (!Positive(Model.LengthInches, TEXT("length"), Error) || !Positive(Model.WidthInches, TEXT("width"), Error)) return false;
        if ((Model.Kind == EShapeKind::Ellipse || Model.Kind == EShapeKind::Capsule) && Model.LengthInches.GetValue() < Model.WidthInches.GetValue())
            return Fail(Error, EDiagnosticCode::MissingDimension, TEXT("length"), TEXT("Ellipse/capsule length must be at least its width."));
    }
    if (Model.Kind == EShapeKind::Capsule && !Model.bSyntheticCapsule)
        return Fail(Error, EDiagnosticCode::InvalidFixture, Model.Id, TEXT("Capsule must explicitly be synthetic."));
    if (Model.Kind == EShapeKind::Polygon)
    {
        if (Model.VerticesInches.Num() < 3) return Fail(Error, EDiagnosticCode::InvalidPolygon, Model.Id, TEXT("Polygon requires at least three vertices."));
        for (const FVector2d& V : Model.VerticesInches)
            if (!Finite(V)) return Fail(Error, EDiagnosticCode::NonFinite, Model.Id, TEXT("Polygon vertices must be finite."));
        if (PolygonSignedArea(Model.VerticesInches) <= Epsilon)
            return Fail(Error, EDiagnosticCode::InvalidPolygon, Model.Id, TEXT("Polygon must have positive domain winding."));
        // Every vertex must lie strictly left of every nonincident edge: rejects
        // self intersections, duplicates, collinear edges and concavity.
        for (int32 I = 0; I < Model.VerticesInches.Num(); ++I)
        {
            const int32 Next = (I + 1) % Model.VerticesInches.Num();
            for (int32 J = 0; J < Model.VerticesInches.Num(); ++J)
                if (J != I && J != Next && Cross(Model.VerticesInches[Next] - Model.VerticesInches[I],
                    Model.VerticesInches[J] - Model.VerticesInches[I]) <= Epsilon)
                    return Fail(Error, EDiagnosticCode::InvalidPolygon, Model.Id, TEXT("Polygon must be simple and strictly convex."));
        }
    }
    Error = {};
    return true;
}
bool ContainsLocalPoint(const FFootprint& Model, const FVector2d& P)
{
    switch (Model.Kind)
    {
    case EShapeKind::Circle: return P.SizeSquared() <= FMath::Square(Model.RadiusInches.GetValue()) + Epsilon;
    case EShapeKind::Ellipse: return FMath::Square(P.X / (Model.LengthInches.GetValue() * 0.5)) +
        FMath::Square(P.Y / (Model.WidthInches.GetValue() * 0.5)) <= 1.0 + Epsilon;
    case EShapeKind::Rectangle: return FMath::Abs(P.X) <= Model.LengthInches.GetValue() * 0.5 + Epsilon &&
        FMath::Abs(P.Y) <= Model.WidthInches.GetValue() * 0.5 + Epsilon;
    case EShapeKind::Capsule:
    {
        const double R = Model.WidthInches.GetValue() * 0.5;
        const double H = (Model.LengthInches.GetValue() - Model.WidthInches.GetValue()) * 0.5;
        const double X = P.X - FMath::Clamp(P.X, -H, H);
        return X * X + P.Y * P.Y <= R * R + Epsilon;
    }
    case EShapeKind::Polygon:
        for (int32 I = 0; I < Model.VerticesInches.Num(); ++I)
            if (Cross(Model.VerticesInches[(I + 1) % Model.VerticesInches.Num()] - Model.VerticesInches[I], P - Model.VerticesInches[I]) < -Epsilon) return false;
        return true;
    default: return false;
    }
}

bool BuildDisplayMesh(const FTableFrame& Frame, const FFootprint& Model, double Thickness,
    FDisplayMesh& OutMesh, FDiagnostic& Error)
{
    if (!ValidateFrame(Frame, Error) || !ValidateFootprint(Model, Error)) return false;
    if (!FMath::IsFinite(Thickness) || Thickness <= 0.0)
        return Fail(Error, EDiagnosticCode::MissingDimension, TEXT("visualThickness"), TEXT("Visual thickness must be finite and positive."));
    TArray<FVector2d> Outline;
    if (Model.Kind == EShapeKind::Polygon) Outline = Model.VerticesInches;
    else if (Model.Kind == EShapeKind::Rectangle)
    {
        const double X = Model.LengthInches.GetValue() * 0.5, Y = Model.WidthInches.GetValue() * 0.5;
        Outline = { {-X,-Y}, {X,-Y}, {X,Y}, {-X,Y} };
    }
    else if (Model.Kind == EShapeKind::Capsule && Model.LengthInches.GetValue() > Model.WidthInches.GetValue())
    {
        const double R = Model.WidthInches.GetValue() * 0.5, H = (Model.LengthInches.GetValue() - Model.WidthInches.GetValue()) * 0.5;
        for (int32 Side = 0; Side < 2; ++Side)
            for (int32 I = 0; I <= 32; ++I)
            {
                const double A = -UE_DOUBLE_PI * 0.5 + Side * UE_DOUBLE_PI + I * UE_DOUBLE_PI / 32.0;
                Outline.Add({ (Side == 0 ? H : -H) + R * FMath::Cos(A), R * FMath::Sin(A) });
            }
    }
    else
    {
        // A capsule with length==width is exactly a circle. Use one closed
        // circular outline, avoiding duplicate join vertices/zero-area triangles.
        const double X = Model.Kind == EShapeKind::Circle ? Model.RadiusInches.GetValue() : Model.LengthInches.GetValue() * 0.5;
        const double Y = Model.Kind == EShapeKind::Circle ? X : Model.WidthInches.GetValue() * 0.5;
        for (int32 I = 0; I < 64; ++I)
        {
            const double A = I * 2.0 * UE_DOUBLE_PI / 64.0;
            Outline.Add({ X * FMath::Cos(A), Y * FMath::Sin(A) });
        }
    }
    FDisplayMesh Mesh;
    const FDomainPose& Pose = Model.Pose.GetValue();
    auto AddTriangle = [&](const FVector2d& A, double ZA, const FVector2d& B, double ZB, const FVector2d& C, double ZC)
    {
        const FVector3d Points[3] = { DomainToWorld(Frame, PosePoint(Pose, A, ZA)),
            DomainToWorld(Frame, PosePoint(Pose, B, ZB)), DomainToWorld(Frame, PosePoint(Pose, C, ZC)) };
        const FVector3d Normal = FVector3d::CrossProduct(Points[1] - Points[0], Points[2] - Points[0]).GetSafeNormal();
        const FVector2d Locals[3] = { A, B, C };
        for (int32 I = 0; I < 3; ++I)
        {
            Mesh.Triangles.Add(Mesh.VerticesWorldCm.Num());
            Mesh.VerticesWorldCm.Add(Points[I]);
            Mesh.NormalsWorld.Add(Normal);
            Mesh.UV0.Add(FVector2D(Locals[I].X, Locals[I].Y));
            Mesh.VertexColors.Add(Locals[I].X > 0.0 ? FLinearColor(0.9f,0.35f,0.12f) : FLinearColor(0.1f,0.55f,0.9f));
        }
    };
    for (int32 I = 1; I < Outline.Num() - 1; ++I)
    {
        // Domain CCW becomes CW under the explicit Y reflection; reverse top.
        AddTriangle(Outline[0], Thickness, Outline[I + 1], Thickness, Outline[I], Thickness);
        AddTriangle(Outline[0], 0.0, Outline[I], 0.0, Outline[I + 1], 0.0);
    }
    for (int32 I = 0; I < Outline.Num(); ++I)
    {
        const FVector2d& A = Outline[I]; const FVector2d& B = Outline[(I + 1) % Outline.Num()];
        AddTriangle(A, 0.0, B, Thickness, B, 0.0);
        AddTriangle(A, 0.0, A, Thickness, B, Thickness);
    }
    OutMesh = MoveTemp(Mesh);
    Error = {};
    return true;
}

bool RaycastSupport(const FTableFrame& Frame, const TArray<FSupportSurface>& Supports,
    const FRay& Ray, FAdvisoryHit& OutHit, FDiagnostic& Error)
{
    FVector3d O, D;
    if (!RayInDomain(Frame, Ray, O, D, Error)) return false;
    double Best = TNumericLimits<double>::Max();
    FString BestId;
    for (const FSupportSurface& Surface : Supports)
    {
        if (Surface.Id.IsEmpty() || !ValidBounds(Surface.BoundsInches) || !FMath::IsFinite(Surface.ZInches))
            return Fail(Error, EDiagnosticCode::InvalidFixture, Surface.Id, TEXT("Invalid support descriptor."));
        for (const FBounds2d& Hole : Surface.HolesInches)
            if (!ValidBounds(Hole)) return Fail(Error, EDiagnosticCode::InvalidFixture, Surface.Id, TEXT("Invalid support hole."));
        if (FMath::Abs(D.Z) < Epsilon) continue;
        const double T = (Surface.ZInches - O.Z) / D.Z;
        const FVector2d P(O.X + D.X * T, O.Y + D.Y * T);
        if (T <= Epsilon || !HitPrecedes(T, Surface.Id, Best, BestId) || !InBounds(Surface.BoundsInches, P)) continue;
        bool bHole = false;
        // Hole edges are excluded too: never bridge a visible hole with a hit.
        for (const FBounds2d& Hole : Surface.HolesInches) bHole |= InBounds(Hole, P);
        if (!bHole) { Best = T; BestId = Surface.Id; }
    }
    if (BestId.IsEmpty()) return Fail(Error, EDiagnosticCode::NoHit, TEXT("support"), TEXT("Ray misses all bounded support surfaces."));
    FillHit(Ray, O, D, Best, EHitKind::Support, BestId, OutHit);
    Error = {};
    return true;
}

bool RaycastModels(const FTableFrame& Frame, const TArray<FFootprint>& Models,
    const FRay& Ray, FAdvisoryHit& OutHit, FDiagnostic& Error)
{
    FVector3d O, D;
    if (!RayInDomain(Frame, Ray, O, D, Error)) return false;
    double Best = TNumericLimits<double>::Max();
    FString BestId;
    for (const FFootprint& Model : Models)
    {
        if (!ValidateFootprint(Model, Error)) return false;
        const FDomainPose& Pose = Model.Pose.GetValue();
        const FVector2d XY = Rotate(FVector2d(O.X - Pose.PositionInches.X, O.Y - Pose.PositionInches.Y), -Pose.FacingDegrees);
        const FVector2d V = Rotate(FVector2d(D.X, D.Y), -Pose.FacingDegrees);
        const double Z = O.Z - Pose.PositionInches.Z;
        TArray<double> Candidates;
        if (FMath::Abs(D.Z) >= Epsilon) { Candidates.Add(-Z / D.Z); Candidates.Add((Model.QueryHeightInches - Z) / D.Z); }
        if (Model.Kind == EShapeKind::Circle || Model.Kind == EShapeKind::Ellipse)
        {
            const double X = Model.Kind == EShapeKind::Circle ? Model.RadiusInches.GetValue() : Model.LengthInches.GetValue() * 0.5;
            const double Y = Model.Kind == EShapeKind::Circle ? X : Model.WidthInches.GetValue() * 0.5;
            AddQuadraticRoots(V.X * V.X / (X * X) + V.Y * V.Y / (Y * Y),
                2.0 * (XY.X * V.X / (X * X) + XY.Y * V.Y / (Y * Y)),
                XY.X * XY.X / (X * X) + XY.Y * XY.Y / (Y * Y) - 1.0, Candidates);
        }
        else if (Model.Kind == EShapeKind::Rectangle)
        {
            if (FMath::Abs(V.X) >= Epsilon)
            { Candidates.Add((Model.LengthInches.GetValue() * 0.5 - XY.X) / V.X); Candidates.Add((-Model.LengthInches.GetValue() * 0.5 - XY.X) / V.X); }
            if (FMath::Abs(V.Y) >= Epsilon)
            { Candidates.Add((Model.WidthInches.GetValue() * 0.5 - XY.Y) / V.Y); Candidates.Add((-Model.WidthInches.GetValue() * 0.5 - XY.Y) / V.Y); }
        }
        else if (Model.Kind == EShapeKind::Capsule)
        {
            const double R = Model.WidthInches.GetValue() * 0.5, H = (Model.LengthInches.GetValue() - Model.WidthInches.GetValue()) * 0.5;
            if (FMath::Abs(V.Y) >= Epsilon)
                for (const double Edge : { -R, R })
                { const double T = (Edge - XY.Y) / V.Y; if (FMath::Abs(XY.X + V.X * T) <= H + Epsilon) Candidates.Add(T); }
            for (const double Center : { -H, H })
            {
                TArray<double> Roots;
                AddQuadraticRoots(V.SizeSquared(), 2.0 * ((XY.X - Center) * V.X + XY.Y * V.Y),
                    FMath::Square(XY.X - Center) + XY.Y * XY.Y - R * R, Roots);
                for (double T : Roots)
                    if (H <= Epsilon || (Center < 0.0 && XY.X + V.X * T <= -H + Epsilon) ||
                        (Center >= 0.0 && XY.X + V.X * T >= H - Epsilon)) Candidates.Add(T);
            }
        }
        else if (Model.Kind == EShapeKind::Polygon)
        {
            for (int32 I = 0; I < Model.VerticesInches.Num(); ++I)
            {
                const FVector2d& A = Model.VerticesInches[I];
                const FVector2d Edge = Model.VerticesInches[(I + 1) % Model.VerticesInches.Num()] - A;
                const double Denominator = Cross(Edge, V);
                if (FMath::Abs(Denominator) >= Epsilon) Candidates.Add(Cross(Edge, A - XY) / Denominator);
            }
        }
        for (const double T : Candidates)
            if (FMath::IsFinite(T) && T > Epsilon && HitPrecedes(T, Model.Id, Best, BestId) && Z + D.Z * T >= -Epsilon &&
                Z + D.Z * T <= Model.QueryHeightInches + Epsilon && ContainsLocalPoint(Model, XY + V * T))
            { Best = T; BestId = Model.Id; }
    }
    if (BestId.IsEmpty()) return Fail(Error, EDiagnosticCode::NoHit, TEXT("models"), TEXT("Ray misses analytic selection volumes."));
    FillHit(Ray, O, D, Best, EHitKind::Model, BestId, OutHit);
    Error = {};
    return true;
}
bool RaycastAdvisory(const FTableFrame& Frame, const TArray<FFootprint>& Models,
    const TArray<FSupportSurface>& Supports, const FRay& Ray, FAdvisoryHit& OutHit, FDiagnostic& Error)
{
    FAdvisoryHit Model, Support;
    FDiagnostic ModelError, SupportError;
    const bool bModel = RaycastModels(Frame, Models, Ray, Model, ModelError);
    if (!bModel && ModelError.Code != EDiagnosticCode::NoHit) { Error = ModelError; return false; }
    const bool bSupport = RaycastSupport(Frame, Supports, Ray, Support, SupportError);
    if (!bSupport && SupportError.Code != EDiagnosticCode::NoHit) { Error = SupportError; return false; }
    if (!bModel && !bSupport) return Fail(Error, EDiagnosticCode::NoHit, TEXT("scene"), TEXT("Ray misses advisory model and support descriptors."));
    OutHit = bModel && (!bSupport || HitPrecedes(Model.DistanceWorldCm, Model.Id, Support.DistanceWorldCm, Support.Id)) ? Model : Support;
    Error = {};
    return true;
}

bool LoadFixture(const FString& Path, FFixture& OutFixture, FDiagnostic& Error)
{
    FString Text;
    if (FPaths::IsRelative(Path) || !FFileHelper::LoadFileToString(Text, *Path))
        return Fail(Error, EDiagnosticCode::InvalidFixture, TEXT("fixture"), TEXT("Absolute readable JSON fixture is required."));
    return ParseFixtureJson(Text, OutFixture, Error);
}

bool ParseFixtureJson(const FString& Text, FFixture& OutFixture, FDiagnostic& Error)
{
    TSharedPtr<FJsonObject> Root;
    if (!FJsonSerializer::Deserialize(TJsonReaderFactory<>::Create(Text), Root) || !Root.IsValid())
        return Fail(Error, EDiagnosticCode::InvalidFixture, TEXT("fixture"), TEXT("A JSON object is required."));
    FFixture F;
    double Version;
    if (!ReadNumber(Root, TEXT("version"), Version, Error) || Version != 1.0)
        return Fail(Error, EDiagnosticCode::InvalidFixture, TEXT("version"), TEXT("Only synthetic fixture version 1 is supported."));
    if (!ReadString(Root, TEXT("label"), F.Label, Error) || F.Label != TEXT("SYNTHETIC / ADVISORY - NO GAME SESSION"))
        return Fail(Error, EDiagnosticCode::InvalidFixture, TEXT("label"), TEXT("Synthetic no-session label is required."));
    TSharedPtr<FJsonObject> Object;
    FVector3d V, Translation, Rotation;
    if (!ReadObject(Root, TEXT("frame"), Object, Error) || !ReadVector(Object, TEXT("center_inches"), 2, V, Error) ||
        !ReadNumber(Object, TEXT("datum_inches"), F.Frame.DatumInches, Error) ||
        !ReadVector(Object, TEXT("translation_cm"), 3, Translation, Error) || !ReadVector(Object, TEXT("rotation_degrees"), 3, Rotation, Error)) return false;
    F.Frame.CenterInches = FVector2d(V.X, V.Y);
    F.Frame.WorldFromTableCm = FTransform3d(FRotator3d(Rotation.X, Rotation.Y, Rotation.Z), Translation, FVector3d::OneVector);
    if (!ValidateFrame(F.Frame, Error) || !ReadObject(Root, TEXT("board_bounds_inches"), Object, Error) || !ReadBounds(Object, F.BoardBoundsInches, Error) ||
        !ReadNumber(Root, TEXT("visual_thickness_inches"), F.VisualThicknessInches, Error)) return false;
    if (F.VisualThicknessInches <= 0.0)
        return Fail(Error, EDiagnosticCode::MissingDimension, TEXT("visual_thickness_inches"), TEXT("Visual thickness must be positive."));
    if (F.Frame.CenterInches != FVector2d(24,31) || F.Frame.DatumInches != -2.0 || Translation != FVector3d(137,-83,41) ||
        Rotation != FVector3d(0,23,0) || F.BoardBoundsInches.Min != FVector2d(-12,7) ||
        F.BoardBoundsInches.Max != FVector2d(60,55) || F.VisualThicknessInches != 0.12)
        return Fail(Error, EDiagnosticCode::InvalidFixture, TEXT("frame/board"), TEXT("Fixture differs from frozen E02 frame, board or visual thickness."));
    TArray<TSharedPtr<FJsonValue>> Values;
    if (!ReadArray(Root, TEXT("models"), Values, Error)) return false;
    TSet<FString> Ids;
    for (const TSharedPtr<FJsonValue>& Value : Values)
    {
        if (!Value.IsValid() || Value->Type != EJson::Object) return Fail(Error, EDiagnosticCode::InvalidFixture, TEXT("models"), TEXT("Every model must be an object."));
        const TSharedPtr<FJsonObject> ModelObject = Value->AsObject();
        FFootprint Model;
        FString Kind;
        if (!ReadString(ModelObject, TEXT("id"), Model.Id, Error) || !ReadString(ModelObject, TEXT("kind"), Kind, Error)) return false;
        if (Ids.Contains(Model.Id)) return Fail(Error, EDiagnosticCode::InvalidFixture, Model.Id, TEXT("Duplicate stable model ID."));
        Ids.Add(Model.Id);
        Model.Kind = Kind == TEXT("circle") ? EShapeKind::Circle : Kind == TEXT("ellipse") ? EShapeKind::Ellipse :
            Kind == TEXT("rectangle") ? EShapeKind::Rectangle : Kind == TEXT("capsule") ? EShapeKind::Capsule : Kind == TEXT("polygon") ? EShapeKind::Polygon : EShapeKind::Unknown;
        if (!ReadOptionalDimension(ModelObject, TEXT("radius_inches"), Model.RadiusInches, Error) ||
            !ReadOptionalDimension(ModelObject, TEXT("length_inches"), Model.LengthInches, Error) ||
            !ReadOptionalDimension(ModelObject, TEXT("width_inches"), Model.WidthInches, Error) ||
            !ReadNumber(ModelObject, TEXT("query_height_inches"), Model.QueryHeightInches, Error)) return false;
        const TSharedPtr<FJsonValue>* Synthetic = ModelObject->Values.Find(TEXT("synthetic_capsule"));
        if (!Synthetic || !Synthetic->IsValid() || (*Synthetic)->Type != EJson::Boolean)
            return Fail(Error, EDiagnosticCode::InvalidFixture, Model.Id, TEXT("Explicit synthetic_capsule boolean is required."));
        Model.bSyntheticCapsule = (*Synthetic)->AsBool();
        TArray<TSharedPtr<FJsonValue>> Vertices;
        if (!ReadArray(ModelObject, TEXT("vertices_inches"), Vertices, Error)) return false;
        for (const TSharedPtr<FJsonValue>& Vertex : Vertices)
        {
            if (!Vertex.IsValid() || Vertex->Type != EJson::Array || Vertex->AsArray().Num() != 2 ||
                Vertex->AsArray()[0]->Type != EJson::Number || Vertex->AsArray()[1]->Type != EJson::Number)
                return Fail(Error, EDiagnosticCode::InvalidPolygon, Model.Id, TEXT("Vertex must contain two numbers."));
            Model.VerticesInches.Add({ Vertex->AsArray()[0]->AsNumber(), Vertex->AsArray()[1]->AsNumber() });
        }
        const TSharedPtr<FJsonValue>* PoseValue = ModelObject->Values.Find(TEXT("pose"));
        if (PoseValue && PoseValue->IsValid() && (*PoseValue)->Type == EJson::Object)
        {
            FDomainPose Pose;
            if (!ReadVector((*PoseValue)->AsObject(), TEXT("position_inches"), 3, Pose.PositionInches, Error) ||
                !ReadNumber((*PoseValue)->AsObject(), TEXT("facing_degrees"), Pose.FacingDegrees, Error)) return false;
            Model.Pose = Pose;
        }
        if (!ValidateFootprint(Model, Error)) return false;
        F.Models.Add(MoveTemp(Model));
    }
    if (F.Models.Num() != 5) return Fail(Error, EDiagnosticCode::InvalidFixture, TEXT("models"), TEXT("Exactly five synthetic forms are required."));
    const TCHAR* ModelIds[] = { TEXT("e02-circle"), TEXT("e02-ellipse"), TEXT("e02-rectangle"), TEXT("e02-capsule"), TEXT("e02-polygon") };
    const EShapeKind Kinds[] = { EShapeKind::Circle, EShapeKind::Ellipse, EShapeKind::Rectangle, EShapeKind::Capsule, EShapeKind::Polygon };
    const FVector3d Positions[] = { {8,18,-2}, {42,23,2}, {30,20,2}, {18,38,-2}, {43,39,-2} };
    const double Headings[] = { 0.0,90.0,37.0,0.0,30.0 }, Heights[] = { 1.2,1.0,1.5,1.2,1.2 };
    for (int32 I = 0; I < 5; ++I)
        if (F.Models[I].Id != ModelIds[I] || F.Models[I].Kind != Kinds[I] || F.Models[I].Pose->PositionInches != Positions[I] ||
            F.Models[I].Pose->FacingDegrees != Headings[I] || F.Models[I].QueryHeightInches != Heights[I] || F.Models[I].bSyntheticCapsule != (I == 3))
            return Fail(Error, EDiagnosticCode::InvalidFixture, TEXT("models"), TEXT("Model identity, pose, kind or height differs from frozen E02 fixture."));
    if (F.Models[0].RadiusInches.GetValue() != 1.0 || F.Models[1].LengthInches.GetValue() != 5.0 || F.Models[1].WidthInches.GetValue() != 2.0 ||
        F.Models[2].LengthInches.GetValue() != 4.0 || F.Models[2].WidthInches.GetValue() != 2.0 ||
        F.Models[3].LengthInches.GetValue() != 6.0 || F.Models[3].WidthInches.GetValue() != 2.0 ||
        F.Models[4].VerticesInches != TArray<FVector2d>({{0,0},{3,0},{2,1},{0,2}}))
        return Fail(Error, EDiagnosticCode::InvalidFixture, TEXT("dimensions"), TEXT("Dimensions differ from frozen five-form fixture."));
    if (!ReadArray(Root, TEXT("supports"), Values, Error)) return false;
    for (const TSharedPtr<FJsonValue>& Value : Values)
    {
        if (!Value.IsValid() || Value->Type != EJson::Object) return Fail(Error, EDiagnosticCode::InvalidFixture, TEXT("supports"), TEXT("Support must be an object."));
        FSupportSurface Support;
        const TSharedPtr<FJsonObject> S = Value->AsObject();
        if (!ReadString(S, TEXT("id"), Support.Id, Error) || !ReadNumber(S, TEXT("z_inches"), Support.ZInches, Error) ||
            !ReadObject(S, TEXT("bounds_inches"), Object, Error) || !ReadBounds(Object, Support.BoundsInches, Error)) return false;
        TArray<TSharedPtr<FJsonValue>> Holes;
        if (!ReadArray(S, TEXT("holes_inches"), Holes, Error)) return false;
        for (const TSharedPtr<FJsonValue>& Hole : Holes)
        {
            FBounds2d Bounds;
            if (!Hole.IsValid() || Hole->Type != EJson::Object)
                return Fail(Error, EDiagnosticCode::InvalidFixture, Support.Id, TEXT("Support hole must be a bounds object."));
            if (!ReadBounds(Hole->AsObject(), Bounds, Error)) return false;
            Support.HolesInches.Add(Bounds);
        }
        F.Supports.Add(MoveTemp(Support));
    }
    if (F.Supports.Num() != 2) return Fail(Error, EDiagnosticCode::InvalidFixture, TEXT("supports"), TEXT("Ground and raised support are required."));
    if (F.Supports[0].Id != TEXT("e02-ground") || F.Supports[0].BoundsInches.Min != FVector2d(-12,7) ||
        F.Supports[0].BoundsInches.Max != FVector2d(60,55) || F.Supports[0].ZInches != -2.0 || !F.Supports[0].HolesInches.IsEmpty() ||
        F.Supports[1].Id != TEXT("e02-platform") || F.Supports[1].BoundsInches.Min != FVector2d(25,15) ||
        F.Supports[1].BoundsInches.Max != FVector2d(48,29) || F.Supports[1].ZInches != 2.0 || F.Supports[1].HolesInches.Num() != 1 ||
        F.Supports[1].HolesInches[0].Min != FVector2d(34,22) || F.Supports[1].HolesInches[0].Max != FVector2d(36,24))
        return Fail(Error, EDiagnosticCode::InvalidFixture, TEXT("supports"), TEXT("Support/ground/hole differs from frozen E02 fixture."));
    if (!ReadObject(Root, TEXT("camera"), Object, Error) || !ReadVector(Object, TEXT("target_domain_inches"), 3, F.Camera.TargetDomainInches, Error)) return false;
    struct FNumberField { const TCHAR* Name; double* Value; };
    const FNumberField CameraFields[] = {
        {TEXT("default_azimuth_degrees"), &F.Camera.DefaultAzimuthDegrees}, {TEXT("default_elevation_degrees"), &F.Camera.DefaultElevationDegrees},
        {TEXT("default_distance_cm"), &F.Camera.DefaultDistanceCm}, {TEXT("fov_degrees"), &F.Camera.FovDegrees},
        {TEXT("orbit_degrees_per_logical_unit"), &F.Camera.OrbitDegreesPerLogicalUnit}, {TEXT("pan_cm_per_logical_unit"), &F.Camera.PanCmPerLogicalUnit},
        {TEXT("dolly_step_cm"), &F.Camera.DollyStepCm}, {TEXT("minimum_distance_cm"), &F.Camera.MinimumDistanceCm},
        {TEXT("maximum_distance_cm"), &F.Camera.MaximumDistanceCm}, {TEXT("frame_selection_distance_cm"), &F.Camera.FrameSelectionDistanceCm},
        {TEXT("minimum_elevation_degrees"), &F.Camera.MinimumElevationDegrees}, {TEXT("maximum_elevation_degrees"), &F.Camera.MaximumElevationDegrees},
        {TEXT("keyboard_orbit_step_degrees"), &F.Camera.KeyboardOrbitStepDegrees}, {TEXT("drag_threshold_logical_units"), &F.Camera.DragThresholdLogicalUnits},
        {TEXT("oblique_elevation_degrees"), &F.Camera.ObliqueElevationDegrees}, {TEXT("near_top_elevation_degrees"), &F.Camera.NearTopElevationDegrees} };
    for (const FNumberField& Field : CameraFields) if (!ReadNumber(Object, Field.Name, *Field.Value, Error)) return false;
    if (F.Camera.TargetDomainInches != FVector3d(24,31,-2) || F.Camera.DefaultAzimuthDegrees != -90.0 ||
        F.Camera.DefaultDistanceCm != 320.0 || F.Camera.MinimumDistanceCm != 60.0 || F.Camera.MaximumDistanceCm != 550.0 ||
        F.Camera.FrameSelectionDistanceCm != 85.0 || F.Camera.KeyboardOrbitStepDegrees != 5.0 ||
        F.Camera.MinimumElevationDegrees != 10.0 || F.Camera.MaximumElevationDegrees != 88.0 ||
        F.Camera.OrbitDegreesPerLogicalUnit != 0.25 || F.Camera.PanCmPerLogicalUnit != 0.15 || F.Camera.DollyStepCm != 20.0 ||
        F.Camera.DefaultElevationDegrees != 45.0 || F.Camera.FovDegrees != 50.0 || F.Camera.ObliqueElevationDegrees != 25.0 ||
        F.Camera.NearTopElevationDegrees != 85.0 || F.Camera.DragThresholdLogicalUnits != 4.0 || F.Camera.MinimumDistanceCm <= 0.0 ||
        F.Camera.MaximumDistanceCm <= F.Camera.MinimumDistanceCm || F.Camera.DefaultDistanceCm < F.Camera.MinimumDistanceCm ||
        F.Camera.DefaultDistanceCm > F.Camera.MaximumDistanceCm || F.Camera.OrbitDegreesPerLogicalUnit <= 0.0 ||
        F.Camera.PanCmPerLogicalUnit <= 0.0 || F.Camera.DollyStepCm <= 0.0 || F.Camera.FrameSelectionDistanceCm <= 0.0 || F.Camera.KeyboardOrbitStepDegrees <= 0.0)
        return Fail(Error, EDiagnosticCode::InvalidFixture, TEXT("camera"), TEXT("Camera violates frozen proof angles, threshold or bounds."));
    if (!ReadObject(Root, TEXT("presentation"), Object, Error) ||
        !ReadVector(Object, TEXT("light_rotation_degrees"), 3, F.Presentation.LightRotationDegrees, Error) ||
        !ReadVector(Object, TEXT("light_color"), 3, F.Presentation.LightColor, Error) ||
        !ReadNumber(Object, TEXT("light_intensity_lux"), F.Presentation.LightIntensityLux, Error) ||
        !ReadNumber(Object, TEXT("exposure_bias"), F.Presentation.ExposureBias, Error) ||
        !ReadNumber(Object, TEXT("exposure_min_brightness"), F.Presentation.ExposureMinBrightness, Error) ||
        !ReadNumber(Object, TEXT("exposure_max_brightness"), F.Presentation.ExposureMaxBrightness, Error) ||
        !ReadBool(Object, TEXT("light_cast_shadows"), F.Presentation.bLightCastShadows, Error) ||
        !ReadBool(Object, TEXT("physical_camera_exposure"), F.Presentation.bPhysicalCameraExposure, Error) ||
        !ReadNumber(Object, TEXT("header_height_logical"), F.Presentation.HeaderHeightLogical, Error) ||
        !ReadVector(Object, TEXT("modal_size_logical"), 2, V, Error)) return false;
    F.Presentation.ModalSizeLogical = FVector2d(V.X, V.Y);
    TSharedPtr<FJsonObject> Hud;
    if (!ReadObject(Object, TEXT("hud_bounds_logical"), Hud, Error) || !ReadBounds(Hud, F.Presentation.HudBoundsLogical, Error)) return false;
    FString ExposureMethod;
    if (!ReadString(Object, TEXT("exposure_method"), ExposureMethod, Error)) return false;
    if (F.Presentation.LightRotationDegrees != FVector3d(-55,-35,0) || F.Presentation.LightColor != FVector3d(1,0.96,0.9) ||
        F.Presentation.LightIntensityLux != 6.0 || F.Presentation.ExposureBias != 0.0 || F.Presentation.ExposureMinBrightness != 1.0 ||
        F.Presentation.ExposureMaxBrightness != 1.0 || F.Presentation.bLightCastShadows || F.Presentation.bPhysicalCameraExposure ||
        ExposureMethod != TEXT("Manual") || F.Presentation.HeaderHeightLogical != 64.0 ||
        F.Presentation.ModalSizeLogical != FVector2d(420,180) || F.Presentation.HudBoundsLogical.Min != FVector2d(16,76) ||
        F.Presentation.HudBoundsLogical.Max != FVector2d(246,480))
        return Fail(Error, EDiagnosticCode::InvalidFixture, TEXT("presentation"), TEXT("Light/exposure/HUD differs from frozen E02 defaults."));
    if (!ReadObject(Root, TEXT("key_bindings"), Object, Error)) return false;
    for (const auto& Pair : Object->Values)
    {
        if (!Pair.Value.IsValid() || Pair.Value->Type != EJson::String || Pair.Value->AsString().IsEmpty())
            return Fail(Error, EDiagnosticCode::InvalidFixture, Pair.Key, TEXT("Key binding must be a nonempty string."));
        F.KeyBindings.Add(Pair.Key, Pair.Value->AsString());
    }
    if (!ReadObject(Root, TEXT("input_sequences"), Object, Error)) return false;
    for (const auto& Pair : Object->Values)
    {
        if (!Pair.Value.IsValid() || Pair.Value->Type != EJson::Array || Pair.Value->AsArray().IsEmpty())
            return Fail(Error, EDiagnosticCode::InvalidFixture, Pair.Key, TEXT("Every frozen input sequence must be nonempty."));
        TArray<FString> Steps;
        for (const auto& Step : Pair.Value->AsArray())
        {
            if (!Step.IsValid() || Step->Type != EJson::String) return Fail(Error, EDiagnosticCode::InvalidFixture, Pair.Key, TEXT("Sequence step must be a string."));
            Steps.Add(Step->AsString());
        }
        F.InputSequences.Add(Pair.Key, MoveTemp(Steps));
    }
    if (!ReadArray(Root, TEXT("expected_test_names"), Values, Error)) return false;
    TSet<FString> TestNames;
    for (const auto& Value : Values)
    {
        if (!Value.IsValid() || Value->Type != EJson::String || !Value->AsString().StartsWith(TEXT("Warhammer.Migration.E02.")) || TestNames.Contains(Value->AsString()))
            return Fail(Error, EDiagnosticCode::InvalidFixture, TEXT("expected_test_names"), TEXT("Expected tests must be unique E02 names."));
        TestNames.Add(Value->AsString()); F.ExpectedTestNames.Add(Value->AsString());
    }
    if (F.ExpectedTestNames.Num() != 16 || F.InputSequences.Num() != 8)
        return Fail(Error, EDiagnosticCode::InvalidFixture, TEXT("suite"), TEXT("Exactly 16 cases and 8 frozen input sequences are required."));
    const TCHAR* Suffixes[] = { TEXT("Numeric.RoundTrip"), TEXT("Numeric.HeadingAxes"), TEXT("Numeric.ShapesWinding"), TEXT("Numeric.UnsupportedGeometry"),
        TEXT("Rendered.FiveForms"), TEXT("Rendered.RaisedPicking"), TEXT("Rendered.MeshSubstitution"), TEXT("Rendered.ObliqueNormals"),
        TEXT("Input.CompletedClick"), TEXT("Input.CameraCapture"), TEXT("Input.PanDollyFrame"), TEXT("Input.HudExclusion"),
        TEXT("Input.ModalText"), TEXT("Input.CancelActivation"), TEXT("Input.ResizeScale"), TEXT("Input.RepeatedConfirm") };
    for (int32 I = 0; I < 16; ++I)
    {
        if (!TestNames.Contains(FString(TEXT("Warhammer.Migration.E02.")) + Suffixes[I]))
            return Fail(Error, EDiagnosticCode::InvalidFixture, TEXT("expected_test_names"), TEXT("A required exact E02 case name is missing."));
        if (I >= 8 && !F.InputSequences.Contains(FString(Suffixes[I]).RightChop(6)))
            return Fail(Error, EDiagnosticCode::InvalidFixture, TEXT("input_sequences"), TEXT("A required input sequence is missing."));
    }
    const TCHAR* BindingNames[] = { TEXT("orbit_left"), TEXT("orbit_right"), TEXT("orbit_up"), TEXT("orbit_down"), TEXT("frame_board"),
        TEXT("frame_selection"), TEXT("reset"), TEXT("confirm"), TEXT("cancel"), TEXT("modal") };
    const TCHAR* Keys[] = { TEXT("Left"), TEXT("Right"), TEXT("Up"), TEXT("Down"), TEXT("F"), TEXT("G"), TEXT("R"), TEXT("Enter"), TEXT("Escape"), TEXT("M") };
    if (F.KeyBindings.Num() != 10) return Fail(Error, EDiagnosticCode::InvalidFixture, TEXT("key_bindings"), TEXT("Exactly ten frozen key bindings are required."));
    for (int32 I = 0; I < 10; ++I)
        if (!F.KeyBindings.Contains(BindingNames[I]) || F.KeyBindings[BindingNames[I]] != Keys[I])
            return Fail(Error, EDiagnosticCode::InvalidFixture, TEXT("key_bindings"), TEXT("A frozen key binding is missing or changed."));
    OutFixture = MoveTemp(F);
    Error = {};
    return true;
}
}
