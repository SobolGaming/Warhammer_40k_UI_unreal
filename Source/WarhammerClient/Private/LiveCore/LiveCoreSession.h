#pragma once

#include "CoreMinimal.h"

class IHttpRequest;

struct FLiveCoreOption
{
    FString Id;
    FString Label;
    bool bAvailable = true;
};

struct FLiveCoreTerrain
{
    FString Id;
    TArray<FVector2D> PolygonInches;
    // Maximum supplied volume height. This is a visual summary, not collision geometry.
    double HeightInches = 0.0;
};

struct FLiveCoreObjective
{
    FString Id;
    FVector PositionInches = FVector::ZeroVector;
    double RadiusInches = 0.0;
};

struct FLiveCoreModel
{
    FString Id;
    FString OwnerPlayerId;
    FVector PositionInches = FVector::ZeroVector;
    double RadiusInches = 0.0;
};

// Original pre-session selection identities, not inferred current formation or
// placement. Core owns the one-based physical bearer mapping and all legality.
struct FLiveCoreRosterBearer
{
    FString UnitSelectionId;
    FString ModelProfileId;
    int64 ModelIndex = 0;
    FString SourceId;
};

struct FLiveCoreRosterEnhancement
{
    FLiveCoreRosterBearer Bearer;
    FString EnhancementId;
};

struct FLiveCoreRosterAttachment
{
    FString SourceUnitSelectionId;
    FString BodyguardUnitSelectionId;
};

struct FLiveCoreRosterStartingCargo
{
    FString TransportUnitSelectionId;
    TArray<FString> EmbarkedUnitSelectionIds;
};

// A narrow, viewer-scoped selection/disclosure seam, not a roster editor or
// complete roster display. No arbitrary JSON/private config is retained.
struct FLiveCorePublicArmyRoster
{
    FString ArmyId;
    FString PlayerId;
    FString FactionId;
    TArray<FString> DetachmentIds;
    TArray<FString> UnitSelectionIds;
    TOptional<FLiveCoreRosterBearer> Warlord;
    TArray<FLiveCoreRosterEnhancement> Enhancements;
    // Null means undisclosed; visible empty arrays mean disclosed with no entries.
    bool bAttachmentsDisclosed = false;
    bool bStartingCargoDisclosed = false;
    TArray<FLiveCoreRosterAttachment> Attachments;
    TArray<FLiveCoreRosterStartingCargo> StartingCargo;
};

// Presentation of the authenticated projection only; never a second legality path.
enum class ELiveCoreDecisionPresentation : uint8
{
    Unavailable,
    NoPending,
    Hidden,
    ParameterizedUnsupported,
    OtherActor,
    UnsupportedActor,
    FiniteOptions
};

struct FLiveCoreState
{
    bool bBusy = false;
    bool bHasSession = false;
    bool bUnknown = false;
    bool bCanReconcile = false;
    bool bLastCommandHasOutcome = false;
    bool bLastCommandAccepted = false;
    bool bLastCommandCommitted = false;
    FString Endpoint;
    FString Status = TEXT("Disconnected. Connect to the approved development Core.");
    FString Error;
    // Known recorded command rejection, retained independently of transient read errors.
    FString RecordedCommandError;
    FString SessionId;
    FString Phase;
    FString ViewerPlayerId = TEXT("player-a");
    FString RequestId;
    FString RequestType;
    ELiveCoreDecisionPresentation DecisionPresentation = ELiveCoreDecisionPresentation::Unavailable;
    FString MissionSummary;
    FString LastOutcomeCode;
    // Latest verified command/session revision; also the minimum acceptable projection.
    int64 SessionRevision = -1;
    // These identify only a successfully parsed/applied DTO snapshot, never a receipt.
    int64 ProjectionRevision = -1;
    uint64 ProjectionVersion = 0;
    int32 LastHttpStatus = 0;
    int32 AcceptedActionCount = 0;
    FBox2D BoardBoundsInches = FBox2D(ForceInit);
    TArray<FLiveCoreOption> Options;
    TArray<FLiveCoreTerrain> Terrain;
    TArray<FLiveCoreObjective> Objectives;
    // Only actual placed models with supplied poses; undeployed/reserve models stay absent.
    TArray<FLiveCoreModel> Models;
    // Optional in the unchanged v13 GameView family. Absence is unavailable,
    // distinct from a supported empty inventory. Only the player projection feeds it.
    bool bHasPublicArmyRosters = false;
    TArray<FLiveCorePublicArmyRoster> PublicArmyRosters;
};

namespace LiveCoreProtocol
{
struct FMetadata
{
    FString SessionId;
    FString GameId;
    int64 Revision = -1;
};

struct FReturnedViolation
{
    FString Code;
    FString Message;
    TOptional<FString> Field;
};

struct FOutcome
{
    bool bError = false;
    // Error envelopes have no commit flags; a received error alone is not rollback proof.
    bool bRequiresReconciliation = false;
    bool bAccepted = false;
    bool bCommitted = false;
    FString Code;
    FString Message;
    // Viewer-scoped returned status, not necessarily a new cause of this rejection.
    FString ReturnedLifecycleMessage;
    FString ReturnedViolationCode;
    TArray<FReturnedViolation> ReturnedViolations;
    int64 Revision = -1;
};

bool ValidateEndpoint(const FString& Input, FString& OutEndpoint, FString& OutError);
// User-entered identifiers are used as one literal URL path segment, never normalized.
bool ValidateSessionId(const FString& Input, FString& OutError);
bool ReadCreatedSession(const FString& Text, FMetadata& OutMetadata, FString& OutError);
// Reopening reads the current player-a metadata; it never starts a created session.
bool ReadExistingSession(const FString& Text, const FString& ExpectedSessionId, FMetadata& OutMetadata, FString& OutError);
bool ReadProjection(const FString& Text, const FString& SessionId, FLiveCoreState& OutState, FString& OutError);
// Clear local decision controls while a fresh projection or command outcome is unavailable.
// The separately retained command envelope and authoritative revision are unchanged.
void InvalidateDecisionPresentation(FLiveCoreState& State);
// Also clear optional roster disclosure while a new/uncertain snapshot is pending.
// Geometry and the applied projection identity remain the last validated snapshot.
void InvalidateProjectionPresentation(FLiveCoreState& State);
bool ReadOutcome(const FString& Text, int32 HttpStatus, const FString& CommandId,
    const FString& SessionId, int64 ExpectedRevision, bool bAdministrator,
    const FString& Operation, FOutcome& OutOutcome, FString& OutError);
// Applies a validated known receipt without advancing the applied projection identity.
bool ApplyKnownCommandOutcome(const FOutcome& Outcome, int32 HttpStatus, bool bFiniteAction, FLiveCoreState& State);
FString MakeStartCommand(const FString& SessionId, const FString& CommandId);
FString MakeFiniteCommand(const FString& SessionId, const FString& CommandId,
    int64 Revision, const FString& RequestId, const FString& OptionId);
}

// All methods, delegates and state access belong to the game thread. The HTTP completion
// delegate explicitly requests that thread; weak callbacks cannot keep a torn-down mode alive.
class FLiveCoreSession : public TSharedFromThis<FLiveCoreSession>
{
public:
    static TSharedRef<FLiveCoreSession> Create();
    ~FLiveCoreSession();
    void InitializeEndpoint(const FString& Endpoint);
    void NewSession();
    void CreateAndStart(const FString& Endpoint);
    // Attach a fresh client to a known active session using player-scoped GETs only.
    void OpenExistingSession(const FString& Endpoint, const FString& SessionId);
    void SelectOfferedOption(const FString& OptionId);
    void SubmitOption(const FString& OptionId) { SelectOfferedOption(OptionId); }
    void Refresh();
    // Explicit user action only: resends the retained command bytes, ID and original role.
    // Session creation has no retry identity and cannot use this reconciliation path.
    void ReconcileUnknown();
    void Shutdown();
    const FLiveCoreState& GetState() const { return State; }
    FSimpleDelegate OnChanged;

private:
    enum class ECredential { Administrator, PlayerA };
    struct FPendingCommand
    {
        FString Body;
        FString Id;
        FString Operation;
        int64 ExpectedRevision = -1;
        ECredential Credential = ECredential::PlayerA;
        bool bFiniteAction = false;
    };
    using FReadReply = TFunction<void(int32, const FString&)>;
    FLiveCoreState State;
    TSharedPtr<IHttpRequest, ESPMode::ThreadSafe> ActiveRequest;
    TOptional<FPendingCommand> PendingCommand;
    uint64 Generation = 0;
    bool bStopped = false;
    FString AdministratorToken;
    FString PlayerToken;
    FString CreatingGameId;
#if WITH_DEV_AUTOMATION_TESTS
    friend struct FLiveCoreSessionCreationTestAccess;
    friend struct FLiveCoreSessionIntegrationTestAccess;
    // A focused test can count/block requests before HTTP or credentials are touched.
    TFunction<void(const FString&, const FString&, bool, bool)> RequestAttemptForTests;
    // Nonblocking real-integration observation: verb/path, mutation and admin flags only.
    // No credential/body or response content is exposed to the observer.
    TFunction<void(const FString&, const FString&, bool, bool)> RequestObserverForTests;
#endif
    void Changed();
    void Fail(const FString& Message);
    void MarkUnknown(const FString& Message, bool bCreation);
    void Request(const FString& Verb, const FString& Path, ECredential Credential,
        const FString& Body, bool bMutation, FReadReply&& OnReply);
    void CreateCanonicalSession();
    void HandleCreateReply(int32 Status, const FString& Response);
    void HandleExistingReply(int32 Status, const FString& Response, const FString& ExpectedSessionId);
    void SendPendingCommand();
    void FetchProjection();
};
