#include "LiveCore/LiveCoreRosterPresentation.h"

#include "LiveCore/LiveCoreSession.h"

namespace
{
FString ListedIds(const TArray<FString>& Ids)
{
    return Ids.IsEmpty() ? FString(TEXT("None listed.")) : FString::Join(Ids, TEXT(", "));
}

FString BearerSummary(const FLiveCoreRosterBearer& Bearer)
{
    return FString::Printf(TEXT("Unit-selection ID: %s; model-profile ID: %s; model index (one-based): %lld; source ID: %s"),
        *Bearer.UnitSelectionId, *Bearer.ModelProfileId, static_cast<long long>(Bearer.ModelIndex), *Bearer.SourceId);
}
}

namespace LiveCorePresentation
{
FString BuildPublicRosterSummary(const FLiveCoreState& State)
{
    // Do not let populated stale arrays override the session's presentation guards.
    if (State.bHandoffPending) { return TEXT("Public roster unavailable during local player handoff."); }
    if (!State.bHasSession) { return TEXT("Public roster unavailable until an authenticated session projection arrives."); }
    if (State.bUnknown) { return TEXT("Public roster unavailable while the command outcome is unknown."); }
    if (State.bBusy) { return TEXT("Public roster unavailable while Core state is refreshing."); }
    if (State.ProjectionRevision < 0) { return TEXT("Public roster unavailable until a validated projection arrives."); }
    if (!State.bHasPublicArmyRosters) { return TEXT("Public roster unavailable in this projection."); }
    if (State.PublicArmyRosters.IsEmpty()) { return TEXT("No public army rosters were supplied in this projection."); }

    TArray<FString> Lines;
    Lines.Add(TEXT("Recorded public roster selections. These original selections do not describe current formations, remaining strength, positions or legality."));
    Lines.Add(TEXT("IDs below are supplied identifiers."));
    for (const FLiveCorePublicArmyRoster& Roster : State.PublicArmyRosters)
    {
        Lines.Add(FString());
        const TCHAR* ViewerLabel = Roster.PlayerId.Equals(State.ViewerPlayerId, ESearchCase::CaseSensitive)
            ? TEXT("current viewer's army") : TEXT("other public army");
        Lines.Add(FString::Printf(TEXT("Army ID: %s (%s)"), *Roster.ArmyId, ViewerLabel));
        Lines.Add(TEXT("Player ID: ") + Roster.PlayerId);
        Lines.Add(TEXT("Faction ID: ") + Roster.FactionId);
        Lines.Add(TEXT("Detachment IDs: ") + ListedIds(Roster.DetachmentIds));
        Lines.Add(FString::Printf(TEXT("Original unit-selection IDs (%d): %s"), Roster.UnitSelectionIds.Num(), *ListedIds(Roster.UnitSelectionIds)));
        Lines.Add(Roster.Warlord.IsSet()
            ? TEXT("Warlord selection: ") + BearerSummary(Roster.Warlord.GetValue())
            : FString(TEXT("Warlord selection: No selection supplied.")));

        if (Roster.Enhancements.IsEmpty()) { Lines.Add(TEXT("Enhancement assignments: None listed.")); }
        else
        {
            Lines.Add(TEXT("Enhancement assignments:"));
            for (const FLiveCoreRosterEnhancement& Enhancement : Roster.Enhancements)
            {
                Lines.Add(TEXT("Enhancement ID: ") + Enhancement.EnhancementId + TEXT("; ") + BearerSummary(Enhancement.Bearer));
            }
        }

        if (!Roster.bAttachmentsDisclosed) { Lines.Add(TEXT("Attachment declarations: Not disclosed.")); }
        else if (Roster.Attachments.IsEmpty()) { Lines.Add(TEXT("Attachment declarations: None listed.")); }
        else
        {
            Lines.Add(TEXT("Attachment declarations:"));
            for (const FLiveCoreRosterAttachment& Attachment : Roster.Attachments)
            {
                Lines.Add(TEXT("Source unit-selection ID: ") + Attachment.SourceUnitSelectionId +
                    TEXT("; bodyguard unit-selection ID: ") + Attachment.BodyguardUnitSelectionId);
            }
        }

        if (!Roster.bStartingCargoDisclosed) { Lines.Add(TEXT("Starting cargo manifests: Not disclosed.")); }
        else if (Roster.StartingCargo.IsEmpty()) { Lines.Add(TEXT("Starting cargo manifests: None listed.")); }
        else
        {
            Lines.Add(TEXT("Starting cargo manifests:"));
            for (const FLiveCoreRosterStartingCargo& Cargo : Roster.StartingCargo)
            {
                Lines.Add(TEXT("Transport unit-selection ID: ") + Cargo.TransportUnitSelectionId +
                    TEXT("; embarked unit-selection IDs: ") + ListedIds(Cargo.EmbarkedUnitSelectionIds));
            }
        }
    }
    return FString::Join(Lines, TEXT("\n"));
}
}
