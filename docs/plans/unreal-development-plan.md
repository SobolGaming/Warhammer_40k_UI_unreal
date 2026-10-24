# Unreal development plan: Python UI feature parity

**Revision 2, 2026-10-24. Status: reviewed forward development roadmap; full parity is not implemented or accepted.**

This is the primary forward plan for developing the Unreal client to feature parity with the Python UI. The [migration record](unreal-migration-plan.md) retains current closing work, prior implementation/checklists and dated evidence; the [through-r146 plan](unreal-migration-plan-through-r146.md) preserves the original research and decisions. Historical proof campaigns do not replace delivery of usable client features.

## Baselines and settled decisions

| Project | Identity, role and direct references |
|---|---|
| `Warhammer_40k_UI_unreal` | This C++ first presentation client: [runtime module](../../Source/WarhammerClient), [Game target](../../Source/WarhammerClient.Target.cs), [launch/build guide](../../README.md), [repository instructions](../../AGENTS.md). |
| `Warhammer_40k_UI_arcade` | Python UI parity baseline at **`5088c1c49dcaff29eb59fb64b3063d30214dde73`**: [README](../../../Warhammer_40k_UI_arcade/README.md), [source](../../../Warhammer_40k_UI_arcade/src/warhammer40k_arcade_ui), [tests](../../../Warhammer_40k_UI_arcade/tests), [UI configuration](../../../Warhammer_40k_UI_arcade/docs/ui-configuration.md), [HUD customization](../../../Warhammer_40k_UI_arcade/docs/hud-customization.md). Its supported Core pin is `fc12fa214642f1b1f2a31b56be7323b7d76dbebc`, Contract **44.1.0**. |
| `Warhammer_40k_AI` | Separately maintained, reference-only authoritative Core at **`5f509724da25a2f6ded0c2739a8e7c84bdf59c91`**, Contract **44.3.33**: [adapter decision contract](../../../Warhammer_40k_AI/docs/ADAPTER_DECISION_CONTRACT.md), [development host](../../../Warhammer_40k_AI/scripts/run_phase18m_reference_server.py), [Unreal startup guide](../development/core-startup.md). Never edit this checkout as UI work. |

The requested name `warhammer_40k_UI_python` is interpreted here as the checked-out Python Arcade UI above, consistent with the earlier `Warhammer_40k_UI` reference. No separate checkout or accessible GitHub repository with the exact `_python` name was found. This is an explicit baseline assumption, not a claim that two distinct repositories were compared. If a distinct repository is supplied, refresh this inventory and record its differences before claiming parity with it.

- Python Core alone owns rules, legality and authoritative state. Unreal owns presentation, drafts and collection of player intent through public APIs.
- Support Windows x64 and Linux x86-64. Windows work proceeds now; native Linux build/render/package remains **UNTESTED** until its host is arranged. Linux plumbing or Windows success never closes Linux acceptance.
- Support managed launch of the existing development Core and attachment to an already running service. Document checked-out source and pinned package installation; a UI launcher is not a replacement Core host.
- Local play, remote participants and spectators are required target product modes. The existing local player-a slice does not satisfy all three.
- Preserve preferences/HUD profiles and originals. Sessions remain bound to their exact compatible Core; no midgame switching back to Arcade or cross-Core session conversion is required.
- Personal/internal delivery comes first. External distribution, production host operation and artwork/runtime redistribution clearance are separate later decisions.
- Existing review consent and ordinary checkpoint workflow apply. The owner directly authorizes closing cancellation verification and merging PR #3; this does not mean future parity milestones are complete.

## What exists today

The current Windows development preview runs through UnrealEditor. It creates/starts one canonical development session, displays player-a's projection, offers nonparameterized finite choices, submits one offered setup choice and refreshes the authoritative result. Its current world DTO and fixed panel are deliberately small. It has basic 3D board rendering, managed/attached Core startup and camera controls. See the [migration evidence index](README.md) for exact revisions and bounded results.

It does not yet provide general parameterized gameplay editors, complete roster/world/HUD synchronization, configurable live HUD/profile parity, other viewer modes, durable recovery or a packaged current-client executable. The cooked Game parser/caller proof is narrower than a packaged live gameplay client. Authored profile roundtrip source at `0719125` remains deferred, unreviewed and unexecuted; earlier parser/P0 passes do not establish live profile parity.

## Parity ledger and completion rules

Use the source-backed [CAP01–CAP36 checklist](research/2026-10-16-capability-checklist.md), its full finite/parameterized catalogue, preference-field table and HUD-attribute table as the requirements index. [Parity/data characterization](research/2026-10-16-parity-and-data.md) and the [44.3.33 adaptation review](research/2026-10-16-contract-44-3-33-adaptation.md) retain important supported/unsupported distinctions. Their **97 Core44.1 conformance cases are inventory and parser/routing characterization, not 97 completed target gameplay workflows**.

For each family and variant, maintain a row containing: stable capability ID; exact baseline symbol/test; preserve/redesign/new/unsupported disposition; target contract/request/variant; public Core start recipe; Unreal implementation and verification states; accepted/rejected/stale/cancel outcome evidence; viewer and platform coverage; remaining Core dependency. Add new target44.3.33 families explicitly; never silently infer support from a version number or old fixture.

Every milestone has separate implementation and verification checklists. Before marking one accepted, build the affected target, run focused regressions and applicable real-Core workflows, obtain fresh independent CODE and different requirements review, record exact identities and limits, then commit/push and verify the GitHub ref. Keep scope proportionate; exhaustive historical 727-recipe or transitive SDK certification is not a prerequisite to ordinary feature work. Completion requires working user flows, not merely parsers, test names or raw JSON submission screens.

## Ordered milestones

### P0 — Close this camera increment and merge PR #3

Implementation:

- [x] Extend the existing native camera regression for cancellation during held RMB orbit/MMB pan, retaining existing camera/F/UI checks and owned-process cleanup. The Windows Editor build passed; source review and visible verification are recorded separately below.
- [x] Establish this forward roadmap and preserve the narrower migration/evidence records.

Verification:

- [x] Build and independently review the cancellation source and affected supervisor repair; execute the bounded visible run at `76297e2`. One test passed 386 assertions, including ten cancellation cases. The process exited 0 in 23.898 seconds; all four Config files stayed unchanged and no game window remained. [Results and review dispositions](evidence/2026-10-24-live-core-cancellation.md).
- [x] Preserve the earlier manual F failure separately from the passed native F route. Eight cases cover actual Escape/focus/capture/resize operations; the two application-deactivation cases cover deliberately delivered events only. Real OS app switching and teardown remain unverified.
- [x] Record this increment's closing implementation, verification and review dispositions for the owner's authorized PR #3 merge. The [PR's GitHub merge disposition](https://github.com/SobolGaming/Warhammer_40k_UI_unreal/pull/3) is the final merge record; this milestone does not close P1–P9.

### P1 — Deliver a standalone internal client early

Implementation:

- [ ] Build the existing `WarhammerClient` Game target and create a repeatable Windows Development build/cook/stage/package command. Keep the Editor development route available.
- [ ] Make the canonical session-create JSON explicit runtime data: it currently loads from `tests/migration/fixtures/...` in [LiveCoreSession.cpp](../../Source/WarhammerClient/Private/LiveCore/LiveCoreSession.cpp). Retain its selected-Core identity/checksum and avoid an accidental source-checkout dependency.
- [ ] Include and verify the configured startup map/GameMode and dynamically loaded Cube, Cylinder and material in [GameMode](../../Source/WarhammerClient/Private/WarhammerClientGameMode.cpp). Keep required fonts/shaders/config/runtime prerequisites in the runnable bundle.
- [ ] Extend [Windows launcher](../../scripts/Start-Client.ps1) and [manual Python launcher](../../scripts/Start-Client.py) to select the packaged executable while preserving endpoint, credentials, managed/attached ownership and shutdown behavior. The Python Core may remain separately installed/checked out for this internal milestone.
- [ ] Document first build separately from routine launch and refresh the pinned-runtime/package instructions; lay out matching native Linux packaging commands without claiming execution.

Verification:

- [ ] Launch the current client from its runnable folder outside the source checkout, without using UnrealEditor as the game process. Verify startup, resources, real Core creation/action/refresh, HTTP errors, camera/UI controls and normal close.
- [ ] Verify managed versus attached Core cleanup, missing runtime data/config/credentials and incompatible Core behavior. Record the first real packaged-client result; earlier parser/caller staging is not a substitute.
- [ ] Repeat on a Windows host without an editor installation before claiming portable/clean-machine delivery. Native Linux execution remains open until P8; packaging is a runnable folder, not a promise of a single self-contained file or a bundled Python installer.

### P2 — General public session and decision application shell

Implementation:

- [ ] Replace player-a-only assumptions with explicit session, principal/viewer, actor and turn-owner identity. Introduce typed, viewer-scoped application state and public session/start/reset/join recipes as supported by Core.
- [ ] Adapt every supported 44.1 request/outcome/projection family to 44.3.33. Add a descriptor/variant dispatcher for finite, nested, ordered, confirmation, dice, quantity, entity-selection and parameterized flows; keep unsupported/terminal states explicit.
- [ ] Preserve original IDs, typed JSON-safe payloads, revision/event cursors and catalog/build/schema/content identity. Serialize mutations and discard obsolete async callbacks by session/viewer/generation.
- [ ] Retain the exact uncertain command envelope/ID, reconcile it before another mutation and show actual HTTP status/messages. Add safe lifecycle handling for uncertain session creation; never blindly retry with new IDs.

Verification:

- [ ] Exercise representative real public sessions plus every supported request/variant as its editor lands. Check wrong Core/schema/revision, malformed/unknown descriptors, stale IDs, rejection, delayed/duplicate/lost replies, projection drift and viewer change.
- [ ] Demonstrate that a rejection is distinct from unknown completion and that commands cannot double-submit. Exposed snapshot invariance alone is not zero-HTTP-attempt proof.

### P3 — Complete battlefield presentation, picking and selection

Implementation:

- [ ] Expand typed projection geometry: board bounds/origin, deployment zones/cutouts, objectives/linked terrain, area/feature types, facing, actual nonzero Z and supported circular/rectangular/elliptical/capsule/polygon bases.
- [ ] Keep display meshes, support surfaces, measurement shapes and authoritative footprints distinct. Make Core inches ↔ Unreal centimeters/handedness conversion explicit and invertible. Never invent undeployed poses or new elevation/gravity rules.
- [ ] Add camera-aware picking, overlap cycling, unit/model/physical-component aliases, hover/selection and synchronized world/roster/Current Action focus, including collapsed/hidden panels and stale viewer teardown.
- [ ] Add advisory paths/waypoints/ghosts/targets/ranges, Core-supplied measurements, readable annotations, optional nonsnapping grid, stable icons and minimal visual fallbacks. Support shallow tokens and ordinary meshes with the same IDs and query semantics.

Verification:

- [ ] Compare semantic geometry and intended selection across camera angles, asymmetric/elevated/overlapping entities, hidden UI and mesh substitutions. Test malformed/missing geometry separately from missing optional art.
- [ ] Verify input ownership, click/drag thresholds, release outside the viewport and cancellation; prove local camera/hover/selection/grid changes cause no gameplay submissions using appropriate instrumentation.

### P4 — Play setup, placement and movement through Core

Implementation:

- [ ] Migrate supported setup/prebattle choices and all ten supported model-placement kinds: deployment, redeploy, reinforcement, deep strike, strategic reserves, disembark, scout-reserve setup, materialization, healing revival and return on death.
- [ ] Migrate all eight movement kinds: normal move, advance, fall back, surge, charge, pile in, consolidate and Scout. Preserve emitted physical membership, subset/group assignments, no-move/committed-target and setup envelopes.
- [ ] Provide usable entity/pose/path editors with endpoints, waypoints, readiness, review, explicit confirmation and cancellation; submit public `PathWitness`/proposal forms and preserve request/context/variant identity.

Verification:

- [ ] Record a real reachable start recipe and accepted authoritative before/after state for each supported family, then execute its variant ledger. Cover attached/physical membership, unchanged paths, unsupported variants, stale requests and viewer changes.
- [ ] Separately verify invalid same-context retry/draft retention versus changed-context draft teardown. Do not replace deployment/movement with a private Core mutation or fabricated start state.

### P5 — Complete remaining supported interactions and progression

Implementation:

- [ ] Deliver the three implemented assignment workspaces: shooting declaration, melee declaration and stratagem target binding. Preserve duplicate physical weapon copies, shared/multiple profiles, borrowed/Firing Deck sources, nullable/empty/targetless choices and permitted decline payloads.
- [ ] Complete supported finite/dice/quantity/entity/confirmation/opportunity/reaction flows, source disambiguation, phase/current-action explanations, scrollable roster and synchronized HUD/world action controls.
- [ ] Traverse supported setup → prebattle → movement → shooting and dedicated charge/fight workflows through public Core requests; surface terminal/unsupported/unreachable states honestly.

Verification:

- [ ] Check each supported family/variant through user-operable controls, real-Core outcomes and negative/stale/cancel cases. Parser conformance or synthetic charge/fight fixtures do not prove an entire reachable battle.
- [ ] Preserve baseline highlight-then-confirm versus direct context-action semantics. Keep roster selection local; do not invent unsupported army/roster construction.

### P6 — Preserve profiles, adaptive HUD, preview and diagnostics

Start shared presentation/view-model and composition interfaces alongside P2/P3; do not wait until all gameplay is complete to design profile compatibility.

Implementation:

- [ ] Map every preference field/default/path/error from the capability catalogue, including recognized inactive fields and extensions. Preserve original files, relative/builtin/default/explicit paths, input bindings and intentional inactive semantics; export atomically without silent loss.
- [ ] Implement the accepted HUD widget/attribute/data-reference schema using one normalized composition model and renderer for live UI and preview. Preserve `compass_ring`/`command_bench`, fixed dimensions, visibility/collapse, overflow/scroll/chips and accepted layout/theme/density controls.
- [ ] Add required proportional/min/max/narrow-window reflow, reachable drawers, keyboard navigation, text scaling and high contrast. Port baseline icon identifiers with approved minimal art and visible fallback.
- [ ] Implement whole/subtree preview and headless image+metadata export using the same renderer. Keep production versus synthetic preview inputs explicit.
- [ ] Preserve implemented diagnostic off/summary/payload/render-trace behavior, category/include/exclude/config controls, bounded truncation/rotation and crash bundles with credential/viewer redaction. Ordinary invalid actions are not crashes.

Verification:

- [ ] Begin with a bounded representative preference/HUD corpus, then close every supported field/widget/attribute and import/export/reimport route. Compare semantic state and rendered layout; successful YAML parsing is insufficient.
- [ ] Cover long labels, narrow/high-DPI windows, overflow, stale/unknown fields, malformed files, active/inactive/extension preservation and safe recovery. Keep viewer-private data out of previews, traces and crash output.
- [ ] Review and test any reused deferred profile code before product integration. Historical 727 recipes remain a coverage inventory until materialized and executed, not a blanket gate before ordinary feature progress.

### P7 — Required viewer modes, reconnect and exact-Core continuity

Implementation:

- [ ] Implement local player handoff plus explicit remote participant/spectator connection, session selection/join and authorization UI, using separately supported Core service capabilities. Spectators observe permitted public state and cannot submit player actions.
- [ ] Partition projections, requests, event cursors, drafts, selection, display caches and async callbacks by authenticated viewer. Clear old data on failed refresh, viewer/session switches and permission changes.
- [ ] Implement reconnect/recovery and exact-Core saved-session handling only through supported Core APIs. Keep compatible runtime routing, originals/backups, one-writer ownership and clear mismatch/corruption errors.

Verification:

- [ ] Prove player/actor/turn-owner distinctions, private versus public projection boundaries, spectator restrictions, cross-view stale callback rejection and no hidden opponent-data leakage.
- [ ] Inject response loss/reconnect, restart and permission changes; demonstrate exact-command reconciliation and supported persistence/recovery behavior. Current in-memory UI reconciliation and the development host do not prove durability.
- [ ] Track missing Core authentication, remote-service or persistence support as explicit external Core issues. The UI must not implement a new authority/host, claim unsupported save/resume, or invent cross-Core/midgame client conversion.

### P8 — Native Linux, performance, release and cutover

Implementation:

- [ ] Arrange a native Linux x86-64 machine, matching Unreal toolchain/runtime and rendered GPU host; build/cook/package the same client. Keep Windows bundles usable throughout development.
- [ ] Add reproducible package manifests/CI and clean-machine setup/launch documentation for both platforms, pinned dependency/runtime identity and declared asset provenance. Address intended distribution prerequisites before external release.
- [ ] Define matched baseline/Unreal workloads and hardware early; measure frame time, input latency, startup, memory and large-board/HUD behavior. Separate Core/transport delay from rendering cost and agree budgets from measurements rather than invented PASS numbers.

Verification:

- [ ] Run real packaged-client/Core action, camera/UI and cleanup/error workflows on Windows and native Linux, outside the source/editor environment. Source portability and Windows Git Bash syntax checks do not count as Linux execution.
- [ ] Close practical performance/accessibility/reliability findings and all required parity-ledger variants. Record any agreed intentional difference or remaining waiver explicitly.
- [ ] Approve a default-client switch only after the required feature/platform evidence is complete. Preserve separate profiles/session stores and rollback to compatible exact-Core client bundles; retiring Arcade is a separate decision.

### P9 — Retained presentation-reuse extension

- [ ] After P3/P6 interfaces stabilize, demonstrate shared safe tabletop presentation/composition in a separate synthetic observation host: resolved/ambiguous/stale/lost/duplicate IDs and manual correction, with explicit intent still using current Core requests.
- [ ] Label this CAP34 extension as new work beyond Python UI parity. Production computer vision/projector calibration, detailed miniature libraries/rigs/paid art and new rules/physics are outside parity prerequisites (CAP35–36).

## Capability-to-milestone coverage

Every CAP ID remains traceable to its detailed variant/source/test checklist; grouped rows below enumerate all 36 IDs without promoting unimplemented baseline behavior into shipped parity.

| Capability IDs | Coverage and target milestone |
|---|---|
| CAP01, CAP02, CAP03 | Startup, exact compatibility and sole-Core mutation authority: P1/P2; continued regression throughout. |
| CAP04 | Finite/nested/dice/ordered/confirmation families: P2 foundation, P4/P5 concrete workflows. |
| CAP05, CAP06 | Movement and placement variants: P3 geometry prerequisites, P4 editors/real outcomes. |
| CAP07, CAP08, CAP09 | Assignment/reaction/opportunity and supported progression: P2 lifecycle, P4/P5 workflows. |
| CAP10, CAP11, CAP12 | Selection/roster, supported-versus-unsupported data and input ownership: P0/P3/P5. |
| CAP13, CAP14, CAP15, CAP16, CAP17 | 3D camera, display/query/support geometry, bases, Z/facing and terrain/deployment/objectives: P0/P1/P3/P4. |
| CAP18, CAP19, CAP20, CAP21, CAP22 | Nonsnapping grid, advisory overlays, icons/fallback, local-only interaction and token/mesh equivalence: P1/P3/P6. |
| CAP23, CAP24, CAP25, CAP26, CAP27 | Composition/schema, layouts, accessibility, preference preservation and shared live/preview renderer: P6; interfaces start P2/P3. |
| CAP28 | Actual HTTP/error/uncertainty diagnostics: P2; trace/config/crash product behavior: P6. |
| CAP29, CAP30 | Viewer/actor/cache isolation and exact-Core recovery/coexistence: P2/P7/P8. Remote/spectator product support is required new work. |
| CAP31 | 44.1→44.3.33 adaptation, source/inventory/copy/nullable/membership/committed-target semantics: P2/P4/P5, per-variant ledger. |
| CAP32, CAP33 | Executable bundles, native Windows/Linux and measured performance: P1/P8. |
| CAP34 | Shared synthetic tabletop presentation reuse: P9, distinct from parity acceptance. |
| CAP35, CAP36 | Detailed art, new rules/gravity and production recognition exclusions: all milestones; no completion claim by omission. |

## Supported baseline versus new work and dependencies

- The baseline implements eight movement kinds, ten model-placement kinds and three assignment families. Its generic opportunity/intent tray is proposed; arbitrary roster construction, battlefield-point placement and explicit multi-variant selection are unsupported. Cult Ambush marker/multi-variant placement and optional melee split/extra-attacks editing need separate disposition. Preserve honest unsupported diagnostics; add these features only as explicitly identified target extensions.
- Registered controls, DTO role enums, archived plan titles and tests allowing `supported OR diagnostic` do not establish working features. Characterize inactive preference fields, registered-only measure/debug options and unconsumed standalone local-command HUD buttons before deciding whether to preserve inactive semantics or implement an explicit enhancement.
- No working remote/spectator join UI or saved-session/replay entrypoint is established by the current Python baseline inventory. These target product requirements and Core-dependent recovery work are tracked in P7, rather than misrepresented as existing parity.
- The Core development host has fixed development principals, in-memory sessions and limited remote guarantees. Preserve [Core #589](https://github.com/SobolGaming/Warhammer_40k_AI/issues/589) port-ownership limits and [Core #590](https://github.com/SobolGaming/Warhammer_40k_AI/issues/590) responsiveness evidence; the original 30-second failure remains a failure despite a separate successful longer diagnostic. Show actual HTTP status and any missing diagnostic fidelity.
- Changes to the pinned Core or Python UI baseline require an explicit compatibility/inventory update. Do not edit shared checkouts or silently chase branch tips. Stop for an unavoidable product/compatibility decision; routine reviewed implementation and the already authorized closing merge do not require repeated approval.

## Definition of feature-parity completion

- [ ] Every supported baseline family/variant, active preference/HUD behavior and intentional redesign has an implemented, user-operable Unreal equivalent with linked acceptance evidence; unsupported/inactive baseline behavior is honestly preserved or explicitly dispositioned.
- [ ] All required target product modes, viewer privacy, exact-Core continuity, Windows and native Linux packages have applicable real runtime evidence. Missing external Core capability or a missing Linux host stays open, not silently waived into PASS.
- [ ] Positive, rejected, stale, cancelled, incompatible and uncertain outcomes are exercised; profiles/original artifacts are preserved and local presentation never becomes a second rules path.
- [ ] Packaging, clean-machine startup, diagnostics/redaction, accessibility and measured performance meet the recorded release criteria. Independent reviews and owner acceptance cover the final scope before cutover.

This document can be complete as a development roadmap while these implementation and verification checkboxes remain open. Closing the present camera/plan PR does not close full feature parity.
