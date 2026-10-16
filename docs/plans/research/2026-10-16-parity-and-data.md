# Arcade parity, configuration, assets, input and continuity research

Date: 2026-10-16. This is supporting evidence for the canonical
[`unreal-migration-plan.md`](../unreal-migration-plan.md), not a second readiness checklist.
It addresses source portions of RQ07/RQ10/RQ11/RQ13/RQ16/RQ19/RQ22. **Research remains
incomplete.** No application, integration, GUI, Unreal, packaging or performance test was run
for this report. Test names below identify inspected assertions or future verification targets,
not passing results.

## Immutable source and scope

- `UI` / `Warhammer_40k_UI` means the legacy Arcade client at
  `C:\SWDev\warhammer\Warhammer_40k_UI_arcade`, repository
  `SobolGaming/Warhammer_40k_UI_arcade`, commit
  `5088c1c49dcaff29eb59fb64b3063d30214dde73`. Its `git status --porcelain=v1
  --untracked-files=all` returned no entries during this inspection. All UI paths and line ranges
  below refer to that commit; no branch name is used as immutable evidence. Abbreviated
  `state/`, `render/`, `preferences/`, `hud/`, `input/`, `resources/`, `diagnostics/` and
  `core_client/` paths are beneath `src/warhammer40k_arcade_ui/`.
- `Warhammer_40k_UI_unreal` is the owner-selected destination client repository. It is a separate
  repository, superseding the inherited same-repository `unreal/WarhammerClient/` proposal.
- `Warhammer_40k_AI` remains the separate authoritative core and reference-only sibling. This
  report made no core edits and does not select or change its target revision. UI
  `pyproject.toml:35` selects core commit `fc12fa214642f1b1f2a31b56be7323b7d76dbebc`;
  `docs/plans/phase-35-contract-44-1-m2-evidence.md:3–11` records Contract 44.1.0 adoption.
  This is the observed Arcade baseline, not an owner decision to freeze Unreal to that version.
- Read instructions: workspace `AGENTS.md` and UI `AGENTS.md`. Read the migration handoff,
  capability matrix, HUD/reuse, validation, and coexistence sections. No dependencies were
  installed, no executable experiment was created, and no shared session or Git state was changed.

## RQ07: implemented behavior and meaningful exclusions

**Recommended canonical state: OPEN.** This report is an initial source-backed inventory,
not the required exhaustive CAP01–CAP36 variant checklist. Source declarations and parser
conformance do not establish every end-to-end workflow. The next source pass must enumerate
every selected/nested variant, its positive and negative paths, the exact fixture identity,
and milestone disposition. Missing empirical proof must remain separately unverified.

The current baseline materially changes the inherited plan:

| Evidence | What it supports | Migration consequence |
| --- | --- | --- |
| UI `state/interaction_dispatch.py:16–30,69–117` | Thirteen interaction kinds route to finite, dice, movement, placement, assignment or roster editors. Parameterized `entity_selection` routes to assignment. **Any descriptor with other than one submission variant is unsupported**, returns `submission_variant_id="unselected"`, and explains that explicit variant selection is unimplemented. `roster_construction` and `battlefield_point_placement` are explicitly unsupported. | Preserve typed unsupported reporting. Do not advertise multi-variant Cult Ambush placement or arbitrary roster construction as working parity. Owner scope cannot turn unimplemented old behavior into a requirement without identifying it as new work. |
| UI `tests/test_contract42_conformance.py:172–224` | The test iterates 97 conformance cases and permits `route.diagnostic is not None or route.supported`. It checks proposal JSON-safety; it does not execute every editor or submit every proposal. Quantity/roster interactions get separate synthetic dispatch tests. | A count of 97 or 13 is parser/routing coverage, not full gameplay acceptance. Test module names retaining `42` also do not mean the selected package is still Contract 42. |
| UI `state/movement_draft.py:52–70`; `state/movement_submission.py:51–214,216–300` | Declared movement kinds: normal move, advance, fall back, surge, charge, pile in, consolidate, scout. Submission checks supported route, proposal kind, request/context/variant identity and readiness; submits through the client, refreshes status/projection, and distinguishes invalid same-request draft retention from changed-request teardown. | Enumerate every kind and no-move/witness form under the chosen contract. Do not equate a declared kind with a proven reachable workflow. |
| UI `state/placement_draft.py:28–56,299–424,616–728`; `state/placement_submission.py:53–213,215–279` | Declared proposal kinds: reinforcement, deep strike, strategic reserves, disembark, deployment, redeploy, scout reserve setup, materialization, healing revival, return on death. The decision-type set also recognizes Cult Ambush, but the point-placement/multi-variant route remains unsupported. Placement submission checks request/context/variant/readiness, then uses the public parameterized client path. | Record flat versus nested envelopes and grouped physical components separately; preserve core-owned membership/army identity rather than inferring IDs. |
| UI `state/assignment_workspace.py:17–41,146–268,271–514,516–690,750–889`; `state/assignment_submission.py:49–227` | Implemented workspace families are shooting declaration, melee declaration and stratagem target binding. Shooting preserves physical copy/profile identity, optional borrowed sources and emitted targetless candidates. Decline payload exists only where engine permission permits it. | Characterize each source-choice combination, nullable/empty case and nested request. Phase 30 is not a promise of arbitrary generic editor support. |
| UI `render/arcade_window.py:699–777,1006–1053,1091–1115`; `tests/test_gui_event_driver.py:84–130` | HUD finite buttons highlight an exact option and can focus the matching projected unit; Enter submits. A selected context-menu finite action submits directly. Local roster selection issues no decision. | Preserve these distinct interaction semantics and synchronize world/roster/Current Action focus, including when a surface is hidden. |

Representative existing regression sources to carry into the characterization plan:

- `tests/test_movement_submission.py:28–101,102–210,246–301,318+`: exact IDs/readiness,
  stale prevention, accepted refresh, next-actor viewer, unsupported terminal boundary and invalid
  diagnostics. Despite its name, the test at line 246 uses a **changed request** and asserts draft
  clearing; same-request retention must be a separate case.
- `tests/test_placement_submission.py:24–103,145–213`: exact request/payload, ready requirement,
  invalid response clears the submitted draft and does not advance; unsupported state remains
  visible and does not advance.
- `tests/test_assignment_workspace.py:131–309,310–412,510–679,705–829,926–1087`: duplicate
  physical copies, profiles sharing a copy, empty/targetless declaration, Firing Deck authority,
  ability-source disambiguation, declined stratagem permission and submission boundaries.
- `tests/test_contract42_materialization_placement.py:64–220,221–322,323+`: request-created
  models, advisory circular preview for rectangular bases, stale/invalid flow, viewer teardown,
  real-core accepted retry. Fixture provenance must be checked before claiming roster-start proof.
- `tests/test_contract42_attached_prebattle.py:274+,469+,555+,686+,905+,1087+`: attached
  deployment/Scout physical membership, synchronized HUD/world/roster, hidden HUD behavior,
  membership/viewer drift and core acceptance. These are candidate evidence sources, not tests
  executed here.
- `docs/plans/phase-35-contract-44-1-m2-evidence.md:13–60` separates current attached movement,
  Firing Deck history authority and exact-build checkpoints from historical Contract 42 blockers
  and measurements. Do not carry the earlier attached-Scout failure forward as a current fact.

Remaining CAP characterization work is explicit:

| CAP rows | Outstanding work in this research lane |
| --- | --- |
| CAP01–03 | Root baseline/contract lane must freeze startup, compatibility and public lifecycle evidence. |
| CAP04–09, CAP31 | Enumerate **all** finite, dice, movement, placement, assignment, opportunity, setup and progression variants against the approved core; separate parser-only and real-session cases. |
| CAP10–12, CAP21 | Finish alias/focus/input ownership matrix, including focus loss and capture outside the viewport. |
| CAP13–22 | Geometry/platform lane handles coordinate/elevation/query proof; art evidence below does not close rendered 3D proof. |
| CAP23–28 | Finish complete field/corpus/diagnostic mapping and compare actual native parser/rendering behavior under E04. |
| CAP29–30 | Contract/identity lane plus continuity owner answers; no old UI resume guarantee established. |
| CAP32–33 | Packaging/performance lanes; this report makes no execution claims. |
| CAP34 | Reuse acceptance contract below remains proposed and unexecuted. |
| CAP35–36 | Preserve the already settled exclusions: detailed miniatures/paid artwork, new rules, and production CV/projector systems are not prerequisites. |

## RQ10: current input semantics and proposed Unreal ownership

**Recommended canonical state: OPEN.** Existing behavior below is source-backed. A complete
capture/focus/remapping/state table still needs specification and E02/E04 execution.

| Event | Observed Arcade priority and effect | Exact source |
| --- | --- | --- |
| Configured selection-button press | HUD hit first, context action second, movement entity-selection/waypoint third, placement current-model pose fourth, ordinary world selection last. | `render/arcade_window.py:693–777` |
| Right press with active movement draft | Records click origin/distance and returns before HUD/selection handling. | Same file `693–696` |
| Right or middle drag | Pans the camera and updates cursor world position. Right movement accumulates Manhattan pixel distance. Left drag updates movement/placement preview only. | Same file `778–818` |
| Right release | Removes last waypoint only with active movement draft, recorded right press, and distance at/below `RIGHT_CLICK_REMOVE_DRAG_TOLERANCE_PX`; then clears click tracking. | Same file `820–848` |
| Wheel | Configured HUD scroll region under pointer consumes wheel even if its offset does not change; otherwise vertical wheel zooms at pointer. | Same file `850–891`; `tests/test_gui_event_driver.py:634–651` asserts unchanged zoom over roster. |
| Key press | Resolves exact configured key+modifier command. Finite cycle precedes movement/placement cycling; selection layer/group/add/subtract/toggle commands are local. | Same file `894–1005`; `input/commands.py` |
| Confirm | Movement/placement first mark ready, then a second confirm submits; assignment submits its workspace; finite submits highlighted option. | Same file `1006–1043` |
| Cancel | Cancels movement, placement and assignment workspace and closes context menu. | Same file `1044–1053`; cancellation helpers at `2364–2404`. |
| HUD option click | Highlights finite choice, does not submit. Disabled buttons return. | Same file `1091–1115` |

Proposed reversible Unreal default: HUD owns events originating in its hit regions; pointer-down
assigns one gesture owner until release/cancel; camera drag cannot remove a waypoint; preserve a
separate remappable remove-waypoint command; keep middle drag for pan and use a documented orbit
gesture in the viewport. Store click/drag threshold in logical pointer units and document the
viewport-local conversion after HUD allocation. On focus/capture loss cancel the pointer gesture,
retain the draft, and require an explicit confirm to submit. Camera-only operations issue zero
game commands. These are design proposals, not observed old behavior or passing Unreal tests.
No owner question is needed merely to choose a reversible default; ask only if an indispensable
control preference conflicts with that policy.

## RQ11: preference/HUD dialect and compatibility corpus

**Recommended canonical state: OPEN.** Preserve the actual loaders and schema, not every feature
of YAML. No compatibility break has been approved.

Source answers:

- Preferences use `orjson.loads` for JSON and `yaml.safe_load` for YAML, accepting `.json`, `.yaml`
  and `.yml` (`preferences/io.py:240–277`). Empty YAML becomes `{}` and is then schema-validated.
  Export emits deterministic JSON or `yaml.safe_dump(..., sort_keys=False, allow_unicode=False)`
  (`preferences/io.py:114–141`). Export preserves semantic values; comments and original YAML
  alias formatting are not represented in the typed preferences.
- Root preference schema fields are `schema_version`, `profile_name`, `overlays`, `hotkeys`,
  `selection`, `hud`, `experimental`, `extensions` (`preferences/schema.py:62–75,262–315`).
  Exact schema mismatch produces no preferences. Other error diagnostics can accompany a typed
  preferences object, so callers must respect `has_errors`, not merely non-null presence.
- `HudZonePreference.size_px` is an **integer fixed-pixel zone setting** (`schema.py:142–156,
  648–712`). This is distinct from child widget size syntax. Widget sizes accept numeric pixels,
  `px`, `%` up to 100, positive `fr`, `fill`, `auto`, and both `fit-content` / `fit_content`
  (`hud/toolkit.py:1025–1056`). Preserve fixed legacy zones in a named legacy mode; additive
  proportional allocation must not reinterpret a saved `size_px` value.
- Current HUD fields include layout/composition, zone visibility/collapse, phase/player/event/config
  diagnostics, assignment mode/warnings/highlight color, action-summary mode/label count,
  movement-budget ring mode, breadcrumbs, text scale and high contrast (`schema.py:161–203`).
  Full field limits and default semantics still need transcription from each parser branch.
- Known planned settings are retained and produce `inactive_planned_setting` warnings, while
  unknown planned IDs error. JSON-safe extension values round-trip separately (`schema.py:715–751,
  1170–1208`; `tests/test_preferences.py:160–176,282–305`). They must not become active gameplay
  logic or silently disappear in Unreal.
- HUD compositions use safe YAML loading, a whitelist of root/widget/attribute/icon/data-reference
  keys, strict schema validation and explicit preview mode (`hud/composition.py:125–169,
  235–288,430–567,831–892,1077–1113`). Production rejects `sample_data`; preview needs it.
  Unknown composition keys are errors; include/template keys are `unsafe_include` errors.
- Generic references accept absolute filesystem paths and relative references resolved against
  the source preferences file; built-in aliases and `builtin:` references address packaged
  resources (`resources/source.py:66–92`). Package-relative paths reject root escapes and may
  traverse upward only within the package (`105–135`). Do not silently make all references
  process-working-directory relative or globally ban user-selected absolute paths.
- Live and preview call the same composition renderer with typed presentation data
  (`hud/toolkit_render.py:54–153`). Theme defaults refer to Arial (`hud/toolkit.py:871–889`);
  this is not evidence of an embeddable font asset/license. Child clipping, scroll regions,
  fixed/equal grid semantics and placeholder shapes must be mapped to C++/UMG explicitly.

Minimum import/normalization/round-trip corpus to specify before E04:

1. Four packaged preference profiles (`default`, `dense-debug`, `keyboard-heavy`, `command-bench`)
   and their documentation copies; both packaged HUD profiles; all four `docs/hud/examples/`
   previews, including overflow stress and roster preview.
2. Existing cases in `tests/test_preferences.py:33–396` and
   `tests/test_hud_widget_toolkit.py:204–598,734–905`: valid JSON/YAML parity, absent/default/stale
   files, unknown IDs and duplicate hotkeys, invalid modifiers, extension/inactive preservation,
   unsafe resource paths, relative package/filesystem references, invalid size/constraints,
   unknown widget/attribute/data/icon, preview isolation and PNG/metadata output.
3. Existing layout rendering assertions (`tests/test_hud_layouts.py:19–101` and
   `tests/test_hud_widget_toolkit.py:757–882`) for oversized-zone scaling, collapsed sockets,
   px/fr/fill/fit allocation, clip rectangles and scissor behavior.
4. **Still to characterize without claiming closure:** YAML aliases/merge keys/duplicate keys,
   scalar resolution, custom tags, timestamps, non-finite numbers, non-string keys, cyclic and
   oversized values; full optional/default fields; normalization of partially supported widgets;
   diagnostic severity parity; native parser exact revision/toolchain/ABI. This report did not
   run a parser corpus or create a new probe.

## RQ13: source resource manifest and Unreal import boundary

**Recommended canonical state: OPEN.** The tracked-art discovery is complete for the searched
extensions at this UI commit; usage/provenance/import/cook metadata and geometry proof are not.

`git ls-files '*.png' '*.jpg' '*.jpeg' '*.webp' '*.svg' '*.ttf' '*.otf' '*.fbx' '*.gltf'
'*.glb' '*.obj' '*.atlas'` returned only these 17 SVG files under
`src/warhammer40k_arcade_ui/resources/art/icons/`:

- `aeldari_die_face_1.svg` through `aeldari_die_face_6.svg`;
- `cp_icon.svg`, `missions_icon.svg`, `model_icon.svg`, `phase_icon.svg`, `round_icon.svg`,
  `score_icon.svg`, `stratagems_icon.svg`, `timer_icon.svg`, `unit_icon.svg`;
- `warhammer_hud_icon_sprite.svg`, `icon_contact_sheet.svg`.

The same directory contains tracked `preview.html`. These are source/preview resources, not
ready Unreal textures or verified distribution permissions. The dice SVGs have 1024×1024 viewboxes
and use `currentColor`; `unit_icon.svg` has a 128×128 viewbox and `currentColor`. Preserve source
and identity; choose rasterization/tint/atlas policy explicitly after provenance review. Do not
invent PNG import/filter/pivot metadata for files that are currently vector art.

Runtime visuals are procedural circles/polygons/lines/text (`render/primitives.py:62–112,
391–450`) with support footprint and measurement footprints separate. Current render hints
retain optional core `asset_id` (`render/core_projection.py:331–340`) but source search found no
texture-loading consumer; `IconTextureCache` is explicitly a future seam
(`hud/toolkit.py:284–295`), and dice rendering calls `_dice_face_placeholder`
(`hud/toolkit_render.py:1503–1526`). Preserve placeholder-equivalent visuals before treating art
activation as feature parity. Model shapes support circle, rectangle, ellipse, capsule and polygon
conversion (`render/core_projection.py:504–591`); the terrain footprint parser has its own smaller
shape set (`593–637`), so do not conflate model and terrain capabilities.

Packaging includes `src/warhammer40k_arcade_ui` (`pyproject.toml:28–29`); four packaged preferences
and two packaged HUD profiles live beneath `resources/`. Unreal must retain corresponding data
through explicit cooked/packaged references, without relying on developer `docs/` paths. Record
source/hash, icon ID mapping, generation/tint parameters, UV padding, physical dimensions,
orientation/pivot, mip/filter/material decisions, cooked retention and missing-art diagnostics.
Missing cosmetic art may use a dimensionally stable fallback; missing authoritative query geometry
must fail visibly. E02 must demonstrate all five base forms and an ordinary mesh substitution
with identical IDs, HUD bindings, commands and query/measurement geometry. No art import or Unreal
asset was created here. No paid assets or detailed miniature library is required.

## RQ16 and RQ22: data, coexistence and actual owner choices

**Recommended canonical states: OPEN.** Source supports current data locations and the absence
of a discovered player save/resume entrypoint, not a universal proof that no external tool has one.
No real user preferences, private saves or traces were opened.

| Data / surface | Current source evidence | Proposed preservation/routing |
| --- | --- | --- |
| JSON/YAML presentation preferences | `preferences/io.py:44–86,114–141`; default path comes from `platformdirs.user_config_path(appname="warhammer40k-arcade-ui", appauthor=False)` plus `ui-preferences.yaml`. Missing default loads packaged defaults; missing explicit path errors. | Read-only original; copy to a distinct Unreal store; map/diagnose every field; semantic backup and atomic replacement. Do not change the Arcade default store. |
| HUD YAML and relative references | `hud/composition.py:171–232`; `resources/source.py:66–135`. | Copy/manifest referenced resources so relative paths keep meaning; retain packaged built-in IDs; no shared mutable composition directory. |
| Forensic traces | JSONL writer truncates configured file at session start and appends rows (`diagnostics/forensic_trace.py:295–308,328–357`); default root is `~/.local/state/warhammer40k-arcade-ui/event-traces` (`853`). | Distinct Unreal destination; preserve old diagnostic files without treating them as authoritative replay; avoid concurrent writers or accidental overwrite. |
| Crash bundles | `diagnostics/crash_report.py:142–176,367–389,440–446`; bundles contain JSON report and optional copied trace. | Preserve originals; viewer-safe/redacted export; separate new bundle namespace. |
| Preview/render artifacts | `hud/preview.py:140–152,338`; `tests/test_hud_widget_toolkit.py:884–905`; README render evidence path. | Disposable new output directories; preserve requested reference PNG+metadata artifacts; do not treat screenshots as gameplay persistence. |
| Player saves/replays / midgame resume | Complete application CLI at `main.py:90–180` has preferences, live smoke checkpoint and diagnostics options, with no player save/load/resume/import command. `core_client/local_session_client.py` exposes no persistence loader/writer. `docs/plans/phase-35-contract-44-1-m2-evidence.md:44–60` explicitly limits checkpoints to exact-build test provenance and rejects cross-version interpretation. | Keep original exact core/runtime identity. No converter, save metadata edit or midgame Arcade rollback may be promised. External core persistence APIs do not establish an existing Arcade UI workflow. |
| Roster construction/import | `state/interaction_dispatch.py:99–116` rejects roster editor; CLI exposes no roster import/edit command. Current roster is viewer-scoped selection/presentation. | Preserve implemented display/focus, classify arbitrary roster authoring/import separately; do not invent legality or roster format. |

Source can answer the API/data facts above. The owner/coordinator must decide:

1. Which existing profiles or sessions require continuity, and whether a session begun in Unreal
   must continue midgame in Arcade. Recommendation: preserve profiles and originals now; promise
   cross-client gameplay continuation only after a version-matched E06 proof. Alternative: require
   interchangeable continuation, adding an explicit compatibility blocker before cutover.
2. Who triages new Arcade bug fixes/capability additions and approves the migration freeze, default
   switch and later retirement. Recommendation: a named coordinator maintains an immutable
   baseline/change ledger and explicitly accepts relevant changes. Automatic copying would hide
   contract and capability changes.

Coexistence design remains proposed: separate executables/runtimes/configuration/session stores;
shared immutable fixture copies/manifests only; exactly one authoritative session writer; route
old artifacts to their exact compatible client/core bundle; default selection is an executable
launch choice. Reverting a launch default is distinct from reversing gameplay or a core-version
change. The user already selected the separate Unreal repository, so no further approval is
needed for that repository choice.

Campaign-index inconsistency: `docs/plans/README.md:16–20` still links Phase 30/32 at root plan
paths, while tracked files are `docs/plans/legacy/phase-30-generic-assignment-proposal-editors.md`
and `docs/plans/legacy/phase-32-opportunity-window-and-interface-intent-tray.md`. Treat that as
stale routing evidence, not proof that those campaigns are currently being executed. The current
index's Contract 44.1 continuation at lines 23–43 supersedes inherited 10.2/42 target assumptions.

## RQ19: bounded reuse contract proposal

**Recommended canonical state: OPEN.** Existing source demonstrates typed safe presentation
bindings and one live/preview composition engine, not a physical observation host. The inherited
requirement is already settled; camera/projector purchases or production recognition are not
owner questions for this migration.

Carry this proposed contract into the selected module map, then prove it under E07:

- Shared: stable entity references; viewer-scoped presentation DTOs; named HUD bindings; normalized
  composition/style; request-bound intent/submission interface; semantic diagnostics. Host-specific:
  simulated scene/camera/picking, physical observations/registration/calibration and process transport.
- Observation envelope: source/track/frame IDs, capture sequence, capture timestamp plus clock
  domain, receive timestamp, coordinate-frame ID, units, calibration version, observed pose,
  confidence/optional covariance and resolved or ambiguous/unresolved registration reference.
- A registration record relates tracker identity to stable model/unit/army identity with provenance.
  Duplicate tracks, stale/lost samples, ambiguous reassociation and manual correction remain explicit
  display states. Observed pose never overwrites authoritative pose and never manufactures a legal
  path witness. Calibration corrections issue zero gameplay commands.
- Minimal separate host sequence: load same composition, bind one viewer-safe projection, feed
  synthetic registered observation, show disagreement, feed ambiguous/stale/lost observations,
  correct registration manually, then submit one explicit intent through the same current decision
  facade and display core acceptance/rejection. Assert zero commands for observation/camera/correction
  steps. Preserve hidden-information boundaries and stable IDs through the sequence.
- Shared code must run without a simulated battlefield camera or production CV SDK. The synthetic
  demonstration proves the presentation seam and authority boundary, not recognition/calibration
  accuracy, hardware latency, projector occlusion or a physical move's legality.

The original proposed stale/lost thresholds are synthetic tunables, not accepted hardware requirements.
Source architecture and module-dependency review can finish the design portion; actual reuse stays
unverified until the authorized separate-host proof exists.

## Evidence limits and next work

Only read-only source/Git inspection and this planning-document write were performed. No source tests
were executed; none are marked passing. No owner response was inferred. No native YAML library was
selected/installed, no Unreal input or asset feasibility was tested, and no compatibility conversion
was run. A further source pass can finish the remaining CAP/field/variant checklist without new
implementation. Empirical E02/E04/E06/E07 questions require their bounded authorization and exact
environment/fixture packets. Keep all seven RQ rows OPEN with these partial answers until their
stated closure conditions genuinely hold.
