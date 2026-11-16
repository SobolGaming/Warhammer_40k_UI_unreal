#include "LiveCore/LiveCoreRosterPresentation.h"

#if WITH_DEV_AUTOMATION_TESTS

#include "LiveCore/LiveCoreSession.h"
#include "Misc/AutomationTest.h"

namespace
{
constexpr EAutomationTestFlags RosterFlags = EAutomationTestFlags_ApplicationContextMask | EAutomationTestFlags::EngineFilter;

FLiveCoreState RosterState()
{
    FLiveCoreState State;
    State.bHasSession = true;
    State.bHasPublicArmyRosters = true;
    State.SessionId = TEXT("session-not-for-roster-display");
    State.ViewerPlayerId = TEXT("player-a");
    State.SessionRevision = State.ProjectionRevision = 17;
    State.ProjectionVersion = 3;

    FLiveCorePublicArmyRoster Own;
    Own.ArmyId = TEXT("army:Alpha/issued"); Own.PlayerId = TEXT("player-a"); Own.FactionId = TEXT("faction:Original-A");
    Own.DetachmentIds = { TEXT("detachment:Original-A"), TEXT("detachment:Original-B") };
    Own.UnitSelectionIds = { TEXT("selection:Original-Leader"), TEXT("selection:Original-Bodyguard"), TEXT("selection:Original-Transport") };
    FLiveCoreRosterBearer Warlord;
    Warlord.UnitSelectionId = Own.UnitSelectionIds[0]; Warlord.ModelProfileId = TEXT("profile:Warlord-Original");
    Warlord.ModelIndex = 3; Warlord.SourceId = TEXT("source:Warlord-Original"); Own.Warlord = Warlord;
    FLiveCoreRosterEnhancement Enhancement;
    Enhancement.EnhancementId = TEXT("enhancement:Original"); Enhancement.Bearer.UnitSelectionId = Own.UnitSelectionIds[1];
    Enhancement.Bearer.ModelProfileId = TEXT("profile:Enhancement-Original"); Enhancement.Bearer.ModelIndex = 2;
    Enhancement.Bearer.SourceId = TEXT("source:Enhancement-Original"); Own.Enhancements.Add(Enhancement);
    Own.bAttachmentsDisclosed = Own.bStartingCargoDisclosed = true;
    FLiveCoreRosterAttachment Attachment;
    Attachment.SourceUnitSelectionId = Own.UnitSelectionIds[0]; Attachment.BodyguardUnitSelectionId = Own.UnitSelectionIds[1];
    Own.Attachments.Add(Attachment);
    FLiveCoreRosterStartingCargo Cargo;
    Cargo.TransportUnitSelectionId = Own.UnitSelectionIds[2]; Cargo.EmbarkedUnitSelectionIds = { Own.UnitSelectionIds[0], Own.UnitSelectionIds[1] };
    Own.StartingCargo.Add(Cargo); State.PublicArmyRosters.Add(Own);

    FLiveCorePublicArmyRoster Other;
    Other.ArmyId = TEXT("army:Beta/issued"); Other.PlayerId = TEXT("player-b"); Other.FactionId = TEXT("faction:Original-B");
    Other.DetachmentIds = { TEXT("detachment:Other") }; Other.UnitSelectionIds = { TEXT("selection:Other") };
    State.PublicArmyRosters.Add(Other);
    return State;
}

void ExpectNoIdentities(FAutomationTestBase& Test, const FLiveCoreState& State)
{
    const FString Summary = LiveCorePresentation::BuildPublicRosterSummary(State);
    Test.TestTrue(TEXT("Unavailable summary explains its status"), Summary.Contains(TEXT("unavailable"), ESearchCase::CaseSensitive));
    for (const FLiveCorePublicArmyRoster& Roster : State.PublicArmyRosters)
    {
        Test.TestFalse(TEXT("Unavailable summary has no retained army identity"), Summary.Contains(Roster.ArmyId, ESearchCase::CaseSensitive));
        Test.TestFalse(TEXT("Unavailable summary has no retained faction identity"), Summary.Contains(Roster.FactionId, ESearchCase::CaseSensitive));
        for (const FString& Id : Roster.UnitSelectionIds)
        { Test.TestFalse(TEXT("Unavailable summary has no retained unit-selection identity"), Summary.Contains(Id, ESearchCase::CaseSensitive)); }
    }
    Test.TestFalse(TEXT("Status text never displays session identity"), Summary.Contains(State.SessionId, ESearchCase::CaseSensitive) && !State.SessionId.IsEmpty());
}
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FLiveCoreRosterExactIdentifiersTest,
    "Warhammer.LiveCore.Unit.RosterPresentation.ExactIdentifiers", RosterFlags)
bool FLiveCoreRosterExactIdentifiersTest::RunTest(const FString& Parameters)
{
    const FLiveCoreState State = RosterState();
    const FString Summary = LiveCorePresentation::BuildPublicRosterSummary(State);
    TestTrue(TEXT("Only the matching player is labeled as the current viewer's army"), Summary.Contains(TEXT("Army ID: army:Alpha/issued (current viewer's army)"), ESearchCase::CaseSensitive));
    TestTrue(TEXT("The other supplied army remains public without an ownership inference"), Summary.Contains(TEXT("Army ID: army:Beta/issued (other public army)"), ESearchCase::CaseSensitive));
    TestTrue(TEXT("Unit entries are explicitly original selections"), Summary.Contains(TEXT("Original unit-selection IDs (3): selection:Original-Leader, selection:Original-Bodyguard, selection:Original-Transport"), ESearchCase::CaseSensitive));
    TestTrue(TEXT("Presentation states the historical selection limits"), Summary.Contains(TEXT("do not describe current formations, remaining strength, positions or legality"), ESearchCase::CaseSensitive));
    const TArray<FString> IssuedIds = {
        TEXT("Player ID: player-a"), TEXT("Player ID: player-b"), TEXT("faction:Original-A"), TEXT("faction:Original-B"),
        TEXT("detachment:Original-A"), TEXT("detachment:Original-B"), TEXT("detachment:Other"), TEXT("selection:Other"),
        TEXT("profile:Warlord-Original"), TEXT("source:Warlord-Original"), TEXT("enhancement:Original"),
        TEXT("profile:Enhancement-Original"), TEXT("source:Enhancement-Original")
    };
    for (const FString& Id : IssuedIds)
    { TestTrue(TEXT("Issued identifier spelling and case are retained"), Summary.Contains(Id, ESearchCase::CaseSensitive)); }
    TestTrue(TEXT("Warlord keeps its one-based bearer index and complete reference"), Summary.Contains(TEXT("Warlord selection: Unit-selection ID: selection:Original-Leader; model-profile ID: profile:Warlord-Original; model index (one-based): 3; source ID: source:Warlord-Original"), ESearchCase::CaseSensitive));
    TestTrue(TEXT("Enhancement keeps its distinct one-based bearer reference"), Summary.Contains(TEXT("Enhancement ID: enhancement:Original; Unit-selection ID: selection:Original-Bodyguard; model-profile ID: profile:Enhancement-Original; model index (one-based): 2; source ID: source:Enhancement-Original"), ESearchCase::CaseSensitive));
    TestTrue(TEXT("Disclosed attachment identities are labeled explicitly"), Summary.Contains(TEXT("Source unit-selection ID: selection:Original-Leader; bodyguard unit-selection ID: selection:Original-Bodyguard"), ESearchCase::CaseSensitive));
    TestTrue(TEXT("Disclosed starting cargo keeps the supplied transport and embarked selections"), Summary.Contains(TEXT("Transport unit-selection ID: selection:Original-Transport; embarked unit-selection IDs: selection:Original-Leader, selection:Original-Bodyguard"), ESearchCase::CaseSensitive));
    TestFalse(TEXT("Session identity is not part of roster presentation"), Summary.Contains(State.SessionId, ESearchCase::CaseSensitive));
    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FLiveCoreRosterDisclosureAndEmptyTest,
    "Warhammer.LiveCore.Unit.RosterPresentation.DisclosureAndEmpty", RosterFlags)
bool FLiveCoreRosterDisclosureAndEmptyTest::RunTest(const FString& Parameters)
{
    FLiveCoreState State = RosterState();
    State.PublicArmyRosters.SetNum(1);
    auto& Own = State.PublicArmyRosters[0];
    Own.Warlord.Reset(); Own.Enhancements.Reset(); Own.DetachmentIds.Reset(); Own.UnitSelectionIds.Reset();
    Own.Attachments.Reset(); Own.StartingCargo.Reset();
    FString Summary = LiveCorePresentation::BuildPublicRosterSummary(State);
    TestTrue(TEXT("Missing Warlord stays explicit"), Summary.Contains(TEXT("Warlord selection: No selection supplied.")));
    TestTrue(TEXT("Empty Enhancement assignments stay explicit"), Summary.Contains(TEXT("Enhancement assignments: None listed.")));
    TestTrue(TEXT("Empty detachments stay explicit"), Summary.Contains(TEXT("Detachment IDs: None listed.")));
    TestTrue(TEXT("Empty selected-unit inventory is not remaining model strength"), Summary.Contains(TEXT("Original unit-selection IDs (0): None listed.")));
    TestTrue(TEXT("Disclosed empty attachments are explicit"), Summary.Contains(TEXT("Attachment declarations: None listed.")));
    TestTrue(TEXT("Disclosed empty cargo is explicit"), Summary.Contains(TEXT("Starting cargo manifests: None listed.")));

    Own.bAttachmentsDisclosed = Own.bStartingCargoDisclosed = false;
    FLiveCoreRosterAttachment HiddenAttachment;
    HiddenAttachment.SourceUnitSelectionId = TEXT("SECRET-ATTACHMENT-SOURCE"); HiddenAttachment.BodyguardUnitSelectionId = TEXT("SECRET-ATTACHMENT-TARGET");
    Own.Attachments.Add(HiddenAttachment);
    FLiveCoreRosterStartingCargo HiddenCargo;
    HiddenCargo.TransportUnitSelectionId = TEXT("SECRET-CARGO-TRANSPORT"); HiddenCargo.EmbarkedUnitSelectionIds = { TEXT("SECRET-CARGO-UNIT") };
    Own.StartingCargo.Add(HiddenCargo);
    Summary = LiveCorePresentation::BuildPublicRosterSummary(State);
    TestTrue(TEXT("Undisclosed attachments do not become empty declarations"), Summary.Contains(TEXT("Attachment declarations: Not disclosed.")) && !Summary.Contains(TEXT("Attachment declarations: None listed.")));
    TestTrue(TEXT("Undisclosed cargo does not become an empty manifest"), Summary.Contains(TEXT("Starting cargo manifests: Not disclosed.")) && !Summary.Contains(TEXT("Starting cargo manifests: None listed.")));
    TestFalse(TEXT("Disclosure guards suppress populated secret sentinel arrays"), Summary.Contains(TEXT("SECRET-"), ESearchCase::CaseSensitive));
    State.PublicArmyRosters.Reset();
    TestEqual(TEXT("Available empty inventory differs from unavailable"), LiveCorePresentation::BuildPublicRosterSummary(State), FString(TEXT("No public army rosters were supplied in this projection.")));
    State.bHasPublicArmyRosters = false;
    TestEqual(TEXT("Unavailable inventory does not claim empty"), LiveCorePresentation::BuildPublicRosterSummary(State), FString(TEXT("Public roster unavailable in this projection.")));
    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FLiveCoreRosterAvailabilityGuardsTest,
    "Warhammer.LiveCore.Unit.RosterPresentation.AvailabilityGuards", RosterFlags)
bool FLiveCoreRosterAvailabilityGuardsTest::RunTest(const FString& Parameters)
{
    FLiveCoreState State = RosterState(); State.bHasSession = false; ExpectNoIdentities(*this, State);
    State = RosterState(); State.bHandoffPending = true; ExpectNoIdentities(*this, State);
    State = RosterState(); State.bBusy = true; ExpectNoIdentities(*this, State);
    State = RosterState(); State.bUnknown = true; ExpectNoIdentities(*this, State);
    State = RosterState(); State.ProjectionRevision = -1; ExpectNoIdentities(*this, State);
    State = RosterState(); State.bHasPublicArmyRosters = false; ExpectNoIdentities(*this, State);
    FLiveCoreState Detached; ExpectNoIdentities(*this, Detached);

    State = RosterState(); State.Error = TEXT("Transient non-projection diagnostic"); State.RecordedCommandError = TEXT("Recorded rejection");
    TestTrue(TEXT("A diagnostic alone does not hide a validated available roster"), LiveCorePresentation::BuildPublicRosterSummary(State).Contains(State.PublicArmyRosters[0].ArmyId, ESearchCase::CaseSensitive));
    LiveCoreProtocol::InvalidateProjectionPresentation(State);
    ExpectNoIdentities(*this, State);
    TestFalse(TEXT("Failed or invalidated read cannot restore the preceding roster"), LiveCorePresentation::BuildPublicRosterSummary(State).Contains(TEXT("army:Alpha/issued"), ESearchCase::CaseSensitive));
    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FLiveCoreRosterInvalidationAndViewerChangeTest,
    "Warhammer.LiveCore.Unit.RosterPresentation.InvalidationAndViewerChange", RosterFlags)
bool FLiveCoreRosterInvalidationAndViewerChangeTest::RunTest(const FString& Parameters)
{
    FLiveCoreState State = RosterState();
    const uint64 Version = State.ProjectionVersion;
    TestTrue(TEXT("First supplied snapshot is present"), LiveCorePresentation::BuildPublicRosterSummary(State).Contains(TEXT("army:Alpha/issued"), ESearchCase::CaseSensitive));
    LiveCoreProtocol::InvalidateProjectionPresentation(State);
    TestEqual(TEXT("Production invalidation leaves delivery version unchanged"), State.ProjectionVersion, Version);
    TestFalse(TEXT("Same-version invalidation immediately removes preceding rows"), LiveCorePresentation::BuildPublicRosterSummary(State).Contains(TEXT("army:Alpha/issued"), ESearchCase::CaseSensitive));

    State = RosterState(); State.ViewerPlayerId = TEXT("player-b");
    FString Summary = LiveCorePresentation::BuildPublicRosterSummary(State);
    TestTrue(TEXT("Current-viewer label follows the supplied player identity"), Summary.Contains(TEXT("Army ID: army:Beta/issued (current viewer's army)"), ESearchCase::CaseSensitive));
    TestTrue(TEXT("Former current-viewer label is replaced"), Summary.Contains(TEXT("Army ID: army:Alpha/issued (other public army)"), ESearchCase::CaseSensitive));
    TestFalse(TEXT("Former current-viewer label is not accumulated"), Summary.Contains(TEXT("Army ID: army:Alpha/issued (current viewer's army)"), ESearchCase::CaseSensitive));
    State.ViewerPlayerId = TEXT("PLAYER-B");
    Summary = LiveCorePresentation::BuildPublicRosterSummary(State);
    TestFalse(TEXT("Ownership labels do not normalize issued identity case"), Summary.Contains(TEXT("(current viewer's army)"), ESearchCase::CaseSensitive));
    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FLiveCoreRosterPureReadOnlyTest,
    "Warhammer.LiveCore.Unit.RosterPresentation.PureReadOnly", RosterFlags)
bool FLiveCoreRosterPureReadOnlyTest::RunTest(const FString& Parameters)
{
    const FLiveCoreState State = RosterState();
    const FLiveCoreState Before = State;
    const FString First = LiveCorePresentation::BuildPublicRosterSummary(State);
    TestEqual(TEXT("Repeated presentation has deterministic text"), LiveCorePresentation::BuildPublicRosterSummary(State), First);
    TestEqual(TEXT("Presentation leaves session identity unchanged"), State.SessionId, Before.SessionId);
    TestEqual(TEXT("Presentation leaves authenticated viewer unchanged"), State.ViewerPlayerId, Before.ViewerPlayerId);
    TestEqual(TEXT("Presentation leaves authority revision unchanged"), State.SessionRevision, Before.SessionRevision);
    TestEqual(TEXT("Presentation leaves displayed revision unchanged"), State.ProjectionRevision, Before.ProjectionRevision);
    TestEqual(TEXT("Presentation leaves delivery counter unchanged"), State.ProjectionVersion, Before.ProjectionVersion);
    TestEqual(TEXT("Presentation leaves inventory availability unchanged"), State.bHasPublicArmyRosters, Before.bHasPublicArmyRosters);
    TestEqual(TEXT("Presentation leaves roster count unchanged"), State.PublicArmyRosters.Num(), Before.PublicArmyRosters.Num());
    for (int32 Index = 0; Index < State.PublicArmyRosters.Num(); ++Index)
    {
        const auto& Roster = State.PublicArmyRosters[Index]; const auto& Original = Before.PublicArmyRosters[Index];
        TestEqual(TEXT("Army identity is not rewritten"), Roster.ArmyId, Original.ArmyId);
        TestEqual(TEXT("Player identity is not rewritten"), Roster.PlayerId, Original.PlayerId);
        TestEqual(TEXT("Faction identity is not rewritten"), Roster.FactionId, Original.FactionId);
        TestTrue(TEXT("Detachment identities and order are unchanged"), Roster.DetachmentIds == Original.DetachmentIds);
        TestTrue(TEXT("Unit-selection identities and order are unchanged"), Roster.UnitSelectionIds == Original.UnitSelectionIds);
        TestEqual(TEXT("Warlord presence is unchanged"), Roster.Warlord.IsSet(), Original.Warlord.IsSet());
        if (Roster.Warlord.IsSet())
        {
            TestEqual(TEXT("Warlord selection is unchanged"), Roster.Warlord->UnitSelectionId, Original.Warlord->UnitSelectionId);
            TestEqual(TEXT("Warlord profile is unchanged"), Roster.Warlord->ModelProfileId, Original.Warlord->ModelProfileId);
            TestEqual(TEXT("Warlord index is unchanged"), Roster.Warlord->ModelIndex, Original.Warlord->ModelIndex);
            TestEqual(TEXT("Warlord source is unchanged"), Roster.Warlord->SourceId, Original.Warlord->SourceId);
        }
        TestEqual(TEXT("Enhancement count is unchanged"), Roster.Enhancements.Num(), Original.Enhancements.Num());
        for (int32 EnhancementIndex = 0; EnhancementIndex < Roster.Enhancements.Num(); ++EnhancementIndex)
        {
            const auto& Enhancement = Roster.Enhancements[EnhancementIndex]; const auto& Old = Original.Enhancements[EnhancementIndex];
            TestEqual(TEXT("Enhancement identity is unchanged"), Enhancement.EnhancementId, Old.EnhancementId);
            TestEqual(TEXT("Enhancement selection is unchanged"), Enhancement.Bearer.UnitSelectionId, Old.Bearer.UnitSelectionId);
            TestEqual(TEXT("Enhancement profile is unchanged"), Enhancement.Bearer.ModelProfileId, Old.Bearer.ModelProfileId);
            TestEqual(TEXT("Enhancement index is unchanged"), Enhancement.Bearer.ModelIndex, Old.Bearer.ModelIndex);
            TestEqual(TEXT("Enhancement source is unchanged"), Enhancement.Bearer.SourceId, Old.Bearer.SourceId);
        }
        TestEqual(TEXT("Attachment disclosure is unchanged"), Roster.bAttachmentsDisclosed, Original.bAttachmentsDisclosed);
        TestEqual(TEXT("Attachment count is unchanged"), Roster.Attachments.Num(), Original.Attachments.Num());
        for (int32 AttachmentIndex = 0; AttachmentIndex < Roster.Attachments.Num(); ++AttachmentIndex)
        {
            TestEqual(TEXT("Attachment source is unchanged"), Roster.Attachments[AttachmentIndex].SourceUnitSelectionId, Original.Attachments[AttachmentIndex].SourceUnitSelectionId);
            TestEqual(TEXT("Attachment bodyguard is unchanged"), Roster.Attachments[AttachmentIndex].BodyguardUnitSelectionId, Original.Attachments[AttachmentIndex].BodyguardUnitSelectionId);
        }
        TestEqual(TEXT("Cargo disclosure is unchanged"), Roster.bStartingCargoDisclosed, Original.bStartingCargoDisclosed);
        TestEqual(TEXT("Cargo count is unchanged"), Roster.StartingCargo.Num(), Original.StartingCargo.Num());
        for (int32 CargoIndex = 0; CargoIndex < Roster.StartingCargo.Num(); ++CargoIndex)
        {
            TestEqual(TEXT("Cargo transport is unchanged"), Roster.StartingCargo[CargoIndex].TransportUnitSelectionId, Original.StartingCargo[CargoIndex].TransportUnitSelectionId);
            TestTrue(TEXT("Cargo selections and order are unchanged"), Roster.StartingCargo[CargoIndex].EmbarkedUnitSelectionIds == Original.StartingCargo[CargoIndex].EmbarkedUnitSelectionIds);
        }
    }
    return true;
}

#endif
