# Project-owned startup level: M03 planning basis

2026-10-19. Planning only, following local checkpoint
56ab55bf7f16b81b74e81b5f4c1124a621683207 on codex/phase-bootstrap-plan.
No asset, project configuration, code or frozen E02 input was changed by this
investigation. No Editor, game, build, test, Core host or asset generator was run.
ENTRY01–ENTRY08 are prospective requirements, NOT IMPLEMENTED / NOT RUN.

## Owner direction and actual gap

The owner retained the current path to M03 and requested an explicit
project-owned startup level, with advice about optional configuration/army
selection versus gameplay levels and whether every battlefield needs a new scene.
The minimum accepted scope is a single small M03 entry level using the approved
canonical Core scenario/connection path. A complete setup/army-building UI,
multiple worlds and one map asset per battlefield are not new prerequisites.

Source inspection at Unreal c9878630c586fc2641c08da8171ce1b969150fd1 and planning
parent 56ab55b found no tracked .umap. Config/DefaultEngine.ini names the base
GlobalDefaultGameMode and target graphics settings but has no EditorStartupMap
or GameDefaultMap choice. The E02 wrapper's graphical arguments explicitly use
/Engine/Maps/Entry plus the proof GameMode and -E02Proof
(scripts/migration/Invoke-E02WorldProof.ps1:1426–1444). That is an intentional
synthetic proof route, not the M03 product startup. Existing M03/E03B demands
packaged real-Core interaction but did not name a project-owned default level.
ENTRY fills that planning gap without changing or discrediting E02 evidence.

Planning authority was supplied as an explicit owner transcript relayed from
progress chat 01a11844-54b2-778d-90e7-7f9253e0c00f through source chat
01a14ffe-4b20-7627-8b84-049ecd8c502e. The owner said to keep the current M03 path
and insert the project-owned startup-level requirement if missing or underspecified.
The source transcript was not independently re-retrieved in this task. The relay
authorizes this narrow planning follow-up and local checkpoint, not level
authoring, runtime execution, another visible pair, publication or merge.

## Design recommendation and boundaries

Use one minimal project-owned entry/gameplay level for M03 with connection/status
UI and runtime presenters. A later FrontEnd may contain configuration/army
selection and a Gameplay level may contain the board; screens in the same world
are also acceptable. Existing Section 5.5 already assigns the client application/
session coordinator game-instance scope and world presenters a rebuildable world
lifetime. A GameInstance-owned object or subsystem implements that existing
contract; no new framework, module split or travel system is mandated by this note.

Treat the Unreal level asset as the presentation environment and entry contract.
Treat board layout/terrain/model state as authorized Core data mapped through
reviewed visual definitions. It can be rendered by creating/updating world
geometry in the same scene; a distinct Core battlefield does not inherently
require a separate .umap. Authored scenery/lighting or independently streamed
content may justify additional maps later. Streaming and World Partition are not
needed merely to display different tabletop layouts. Reopening the same board
level for a fresh match is sufficient; arbitrary in-place battlefield hot-swapping
is neither a new M03 requirement nor an existing E02 proof.

Retain Core authority and exact public session/decision paths. The application
contract must preserve the existing external Core session across world travel;
travel must not itself select Core phases or submit Core commands. Unreal world
gameplay and the destination GameMode are recreated. Keep session/command
reconciliation in the application lifetime; invalidate old world/viewer callbacks,
widgets, input and subscriptions before binding new presentation. No world or
process-global singleton may mix PIE instances or viewer-private state.

Editor Open, Play, direct uncooked game and packaged-default launch are distinct
checks. A forced map/URL succeeding does not establish default configuration or
cook closure. Explicitly retain required maps and soft/dynamic resources and
inspect the produced package. Opening the editor must not create or mutate Core
sessions. Minimal M03 entry may use documented approved parameters/canonical
inputs; later setup UI still follows actual Core requests.

## Primary documentation inspected

Retrieved 2026-10-19; these live pages identified themselves as UE 5.8 documentation.
They support API/workflow facts, not a claim that this project's launch/cook works.

- [Epic: Changing the Default Level](https://dev.epicgames.com/documentation/en-us/unreal-engine/changing-the-default-level-of-an-unreal-engine-project) distinguishes player startup selection from the editor's initial level and locates both in Maps & Modes.
- [Epic: Programming Subsystems](https://dev.epicgames.com/documentation/en-us/unreal-engine/programming-subsystems-in-unreal-engine) documents managed instance lifetimes, including GameInstance subsystems initialized/shut down with their owner.
- [Epic: Level Streaming Overview](https://dev.epicgames.com/documentation/en-us/unreal-engine/level-streaming-overview-in-unreal-engine) describes optional persistent-level/sublevel organization and runtime load/unload. That capability is not a reason to require streaming for this small slice.

## Acceptance and unchanged gates

Canonical Section 11.6 ENTRY01–ENTRY08 and M03/E03B contain the normative owned-map,
default-config, four launch modes, Core-linked slice, lifetime, cook and error
evidence requirements. START/E09 remains the separate developer scenario/target
selector and reproducible start-profile obligation. The manual c987 preview is
synthetic inspection only. All runtime proof awaits its bounded packet/reviews and
applicable approvals; Linux execution remains deferred/NOT RUN under OWN08.

This source/design investigation and auxiliary helper checks are not independent
final CODE or REQ acceptance. Preserve the implementer, independent CODE reviewer
and a different independent requirements auditor, exact candidate freeze, coherent
checkpoints, existing payload/window/manual approvals and no automatic merge.

## Installed-version source checks

Text inspection only of UE 5.8.3 / changelist 58210709 at
C:/Program Files/Epic Games/UE_5.8/Engine/Source. Source settings/API support is
not launch, packaged-content or recovery evidence.

| Source relative to Engine/Source | Inspected meaning / relevant line range |
|---|---|
| Runtime/EngineSettings/Classes/GameMapsSettings.h:156–159,207–213 | EditorStartupMap and game/server default-map settings have distinct roles. SHA256 F2FA2E6A6CFAC657CC84DA9ED9259871209A5DFAA60117A432760F3D4AFEC6D9. |
| Runtime/EngineSettings/Private/EngineSettingsModule.cpp:92–106; Runtime/Engine/Private/GameInstance.cpp:626,670–687 | Client runtime selects GameDefaultMap and dedicated-server runtime selects ServerDefaultMap when no map override supplies another route. |
| Editor/UnrealEd/Private/FileHelpers.cpp:5267–5293 | Editor startup can prefer a user's last-opened level before the configured project startup map. Test/README must record the startup-mode precondition in isolated owned settings, preserve existing personal preferences and explain intentional user overrides. |
| Developer/DeveloperToolSettings/Classes/Settings/ProjectPackagingSettings.h:557–561 | MapsToCook supplies maps when no command-line map list is specified. SHA256 267B6259CDD3B51EE2651B0DDB269112107F6FF39BFB680BE59E7C4F170FC22E. |
| Editor/UnrealEd/Private/CookOnTheFlyServer.cpp:8665–8673,9030–9035 | Cook selection uses MapsToCook only after earlier CookMaps and selected INI map lists have not supplied maps, and consumes default game/server maps and required class references subject to cooker flags, including NoDefaultMaps. EditorStartupMap alone is not packaged-content proof. Verify actual package contents and launch under the frozen cook procedure. |
| Runtime/Engine/Classes/Engine/GameInstance.h:143–147; Runtime/Engine/Public/Subsystems/GameInstanceSubsystem.h:11–25; Runtime/Engine/Public/Subsystems/WorldSubsystem.h:10–16 | GameInstance and its subsystem live for the game instance; each PIE context has its own instance. World subsystems belong to the world lifetime. GameInstance.h SHA256 8A6CE49600FE25677432C01E02E00C25A60E88F27CE1C04ACC58F048E4D83D68. |
| Runtime/Engine/Private/GameplayStatics.cpp:981–1006; Runtime/Engine/Private/UnrealEngine.cpp:16259–16262,16504–16508 | Ordinary travel cleans the old world and assigns the existing owning GameInstance to the new world; destination world gameplay/GameMode is recreated (UnrealEngine.cpp:16549). Preserving the external Core session is an application contract, not automatic service persistence, reconnect or callback safety. |
| Runtime/Engine/Classes/Engine/World.h:3765,3790 onward; Runtime/CoreUObject/Private/Misc/PackageName.cpp:805,816; Runtime/CoreUObject/Private/Misc/PackagePath.cpp:103–104 | Runtime actor creation supports scene population. Project Content backs /Game package names, and map packages use .umap. |
| Unreal c987863 Source/WarhammerClient/Private/Migration/E02WorldProofGameMode.cpp:641–711 | BuildScene creates actors/meshes/camera/light at runtime, demonstrating synthetic scene construction only. It does not demonstrate live Core-driven battlefield loading or hot-swapping. |

Existing plan Sections 5.5, 5.6 and 6.2 already contain the coordinator lifetime,
binary provenance/cook and domain-projected board design. ENTRY adds the missing
project-owned startup asset/default-launch evidence to that architecture; it does
not replace those sections or require a new architecture.
