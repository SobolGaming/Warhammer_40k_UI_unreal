# Parity, normalized configuration and input closure design

Date: 2026-10-16. Final source/design supplement to the
[capability checklist](2026-10-16-capability-checklist.md),
[parity/data findings](2026-10-16-parity-and-data.md), and
[selected44.3.33 adaptation](2026-10-16-contract-44-3-33-adaptation.md).
The [canonical plan](../unreal-migration-plan.md) owns RQ states and authorization.
This report contains design decisions and evidence obligations, **not implementation or proof**.

Source identities: `UI` = `Warhammer_40k_UI_arcade@5088c1c49dcaff29eb59fb64b3063d30214dde73`;
`Core` = `Warhammer_40k_AI@5f509724da25a2f6ded0c2739a8e7c84bdf59c91` / Contract44.3.33.
The UI's historical pin is Core44.1 `fc12fa214642f1b1f2a31b56be7323b7d76dbebc`.
Python module abbreviations expand as in the linked packets. No sibling was edited and no
application/test/parser probe/install/build was run. Source inspection and official upstream
documentation review are the only new evidence.

## Selected target mapped onto the complete baseline catalogue

The baseline97 cases remain identified in the capability checklist. The selected Core catalogue
contains **98 cases:73 top-level finite, one nested finite,24 parameterized**. The added case is
`finite:select_source_reposition`, variant `finite_option`, interaction `opportunity_window`.
The exact selected catalogue is `Core:contracts/examples/decisions/interaction-conformance.json`,
declared manifest SHA256 `f77c531fd8cf0be39a088e8b83d0a7eaae947820b112143d08f8b60778fd6b20`.
No new editor family is needed. The editor-supported subset remains the existing finite path,
eight movement kinds, ten placement kinds and three assignment kinds. The three Cult Ambush
parameterized cases remain explicitly unsupported; neither target expansion nor a conformance
example silently authorizes a new editor.

| Target delta / CAP mapping | Final client-side design and exact source boundary | Required empirical capture |
| --- | --- | --- |
| Physical movement sequence: CAP05/10/14/16/19/31 | Keep `InventoryModelIds` and `MovementSequence` as distinct values. Every current placed living canonical-unit model occurs exactly once in a witnessed move; initial sequence follows current public emission order but is displayed as numbered models. Local Move Earlier/Later controls reorder that sequence; group/subset path editing never sorts it. Emit model_paths and parallel model_movements in that same explicit order. Core `geometry/pathing.py:PathWitness:614–683`, `engine/sequential_movement.py:sequential_peer_models:59–91`, contract `7727–7732`. UI's incidental sorted projection order is not preserved as a rules requirement. | E08-M: vacate-before-follow accepted versus cyclic exchange rejected; attached components; order changes after ready invalidate review. Core `tests/unit/test_order126_sequential_movement.py:64,145` supplies canonical procedures. |
| Inventory failure versus rule-invalid attempt: CAP03/05/12/28/31 | Preserve typed invalid reason and request identity. Inventory mismatch before mutation retains the exact request: rebuild inventory from the current authorized projection, preserve only still-current local intent, require review and retry. A rule-invalid geometry attempt may have recorded an event and issued a new request: discard old payload/ready state and rebuild against that new request. Do not generalize every invalid into either rollback or new-request behavior. Core `contracts/migrations/44.3.28-to-44.3.29.md`; `tests/integration/test_movement_witness_membership.py:64,180`. | E08-M captures before/after visible revisions, pending IDs, events and complete witness; trusted mutation checks remain test-only. |
| Same physical copy, alternative profiles: CAP07/31 | Retain all emitted profile rows for presentation, but group selection by the opaque physical `weapon_instance_id` and current source authority. Choosing another profile replaces the prior profile/target choice for that physical copy; it does not create a second declaration. Distinct copies stay distinct, including borrowed Firing Deck source identity. Nullable target and empty declarations remain separate. Core `contracts/migrations/44.3.31-to-44.3.32.md`, adapter contract `2215`; old UI test at `tests/test_assignment_workspace.py:188` documents the intentional difference. | E08-A: ordinary and borrowed copies, alternate profiles, targetless rows; duplicate same-copy profile submission rejected atomically as `duplicate_weapon_declaration`, valid replacement accepted. |
| `select_source_reposition`: CAP04/08/09/29/31 | Generic finite HUD shows only offered choices, preserves source occasion/context and spatial identity, submits exact `decline_source_reposition` or `enter_strategic_reserves` option ID. No invented activation or preceding movement. Core `engine/movement_source_reposition.py:_options:107–133`, `request_source_reposition:136–164`; `engine/interaction_metadata.py:300`. | E08-F:98th parser/routing case plus public real-session accept/decline source procedures in `tests/unit/test_order80_normal_move.py:676,763`. Synthetic `contract-option` is not named-faction reachability proof. |
| Existing envelopes with new semantics: CAP04/06/07/08/09/16/28/29/31 | Forward current source IDs, ordering, nulls, Z, keyword and journal evidence unchanged. Fixed-pose/fit/timing/Embark/disembark/Heavy/Counter-offensive/no-melee rules stay in Core. Display typed invalid/unsupported and source-provided dice classification; never animate a fabricated attack, Leadership roll or provider grant. Respect current redaction for retained/expired/private source events and internal native_snapshots. Full migration/source table lives in the selected adaptation packet; no second rules map is introduced here. | E08-P/A/F captures current emitted outcomes for the selected canonical procedures; EPIC physical CHARACTER and no-melee continuation use `tests/unit/test_d12_epic_challenge.py:154,330` and `test_d12_no_melee_continuation.py:46`. |

This is a source-supported target difference ledger. Schemas being unchanged does not prove
execution compatibility. Legacy44.1 checkpoints are never rehashed into44.3.33 fixtures; the old
client's strict pin is not relaxed. Baseline intent comparisons have an explicit version-difference
ledger. A same-build differential claim requires an authorized target-compatible test driver and
matching fixtures; running old Arcade44.1 beside new Unreal44.3.33 is not that experiment.

## Native configuration normalization contract

Use one internal typed `PresentationProfile` and `CompositionTree` in the shared presentation
boundary. Runtime and preview consume the same normalized values and allocation engine.
The internal model is not a replacement on-disk schema or an approval to discard legacy files.
Each import retains source path/builtin ID, content hash, legacy schema, source-field locations,
original semantic values, normalized active values and preserved inactive values. Export into a
new file/store only; source originals remain unchanged. JSON and YAML serialize the same semantic
tree; formatting/comments/alias spelling are not promised because legacy typed export loses them.

`A` below means active presentation/input binding; `I` means preserved with a visible
`configuration_inactive` warning, without activating unfinished behavior; `R` means rejected with
a typed error and original preserved. The complete exact whitelist, limits and defaults are in
the capability checklist; the total mapping rule is **every accepted field maps to A or I,
and every malformed/unknown/unsafe field maps to R or the explicitly defined legacy-import
compatibility warning below**. No accepted field silently vanishes.

| Preference group/fields | Normalized mapping and disposition |
| --- | --- |
| schema_version,profile_name | A: retain exact legacy string schema1 and profile label/provenance. Unsupported schema R; no guessed upgrade. |
| overlays four lists | A for selected_model,selected_unit,debug_coordinates,movement_budget,movement_path_draft; retain order/values. Planned objective_control_context,engagement_range,coherency,line_of_sight,cover → I. Unknown IDs R. |
| hotkeys command_id/key/modifiers/overlay_id; selection.default_mouse_button/cycle_overlapping_bases | A: typed known local command and normalized key/modifier binding, mouse button and overlap selection. Duplicate binding/unknown ID R. Planned overlay bindings I. toggle_measure_mode remains I with an explicit unavailable-command notice until a separately implemented measurement surface exists; its registry-active legacy no-op is not advertised as functionality. |
| hud.layout_preset/composition_profile/zones.*.visible,size_px,collapsed | A: named layouts and zones, source-relative profile references, fixed `LegacyPx` sizes. Preserve missing-zone defaults. `LegacyPx` is the same nominal extent at100% UI scale, converted once into the parent's logical coordinate system. Retain original numbers on export; proportional sizing is a separate additive mode, never a rewrite of size_px. |
| hud.show_phase/show_active_player/show_event_log | A: filter the corresponding safe presentation groups. |
| hud.show_config_diagnostics | I: source search found schema/default/export only, no runtime consumer. Configuration errors always remain visible; this saved Boolean cannot suppress startup or protocol failure. |
| hud.show_assignment_hud/assignment_hud_mode/show_assignment_warning_markers/assignment_target_highlight_color/show_chain_breadcrumbs | A: panel visibility, compact/detailed view, markers, advisory RGBA target highlights and source breadcrumbs; never affects rules or entity ownership. |
| hud.action_summary_default/action_summary_max_labels/movement_budget_ring_mode | A: hidden/dim/review summary,0–20 label budget, total/split advisory rings. |
| hud.text_scale/high_contrast | A: preserve numeric preference and theme intent. Legacy mode reproduces effective text-scale clamp0.75–1.6 from `UI:hud/runtime_data.py:157–170`, while preserving accepted0.5–2 input for export. New responsive mode applies its documented user text scale once, independently of viewport DPI. No font file is implicitly bundled. |
| experimental.planned_settings; root extensions | I for the five known planned settings; arbitrary JSON-safe extension values preserved opaque. They cannot define code, bindings, legality, visibility or decisions. Unknown planned IDs R. |

Composition normalization is similarly total:

| Composition field/group | Mapping |
| --- | --- |
| schema_version/profile_id/layout_preset/regions/widget.type,id/children | A: exact accepted schema normalization, stable widget IDs, ordered child tree, named region allocation. Unknown widget/region structure R. No duplicate-ID routing ambiguity: diagnose invalid duplicate component IDs before activation. |
| data_ref/icon_id | A through the exact safe registries; missing current display data remains absent, unknown name R. Icons remain deterministic placeholders. No raw-core binding or SVG activation is inferred. |
| root theme | I: retain arbitrary nonempty legacy theme string and warn that it was not a functioning general theme registry. The active default/high-contrast style is selected through known preferences/preview controls. |
| sample_data | A only in labelled preview and only for known data refs; absent data for a used preview ref R; any production sample_data R. |
| layout.kind/orientation/columns/gap_px/padding_px | A: stack horizontal/vertical or equal-cell grid. Preserve legacy anchor/overlay spelling but normalize its effective layout to the old stack behavior with `legacy_layout_limited` warning; advanced positioning I. Source `UI:hud/toolkit_render.py:1855–1905` branches only grid versus stack. |
| layout.alignment | I: parsed but not consumed by that legacy allocator; retain start/center/end/stretch without pretending it worked. A future layout improvement must be documented, not silently introduced through import. |
| width,height,min_width,max_width,min_height,max_height | A: typed expression px/percent/fr/fill/auto/fit_content. Preserve expression and coefficient; evaluate against actual allocated logical parent axis. Percent constraints evaluate in that axis; fr applies only to sibling flexible allocation. Mixed-unit constraints are checked after allocation, not by unrelated unit arithmetic. |
| overflow,scroll,clip_children | A: bounded text/child presentation and wheel ownership. Preserve all overflow fields and implemented scroll fields; scroll.drag_scrollbars → I. Explicit wrap intent becomes actual bounded native wrapping; this is a documented renderer correction to legacy estimated truncation, not a gameplay change. |
| common color_role | A where the legacy shell/gauge/status implementation consumes it, using the known role palette; unknown role preserves value plus diagnostic and deterministic neutral style. |
| common aspect_ratio | I: validated/exported but no consumer found in the legacy renderer. Do not silently enforce it on old layouts. |
| other common attributes | I unless explicitly active in the widget table below: alignment,alpha,background_alpha,border_alpha,border_color_role,border_width,debug_label_visible,density,fill_color_role,icons,opacity,padding,state,slots,text,tooltip_key,z_order. These are schema-accepted reservations; retain values and show inactive status. Runtime button state comes from the safe binding, not an untrusted profile override. |

For **every widget**, allowed title/primary_label/label/unit_label/group_label are active title
sources in that precedence, and subtitle/secondary_label/value/value_text/status_summary/body/
hotkey_hint/first two summary_lines are active subtitle sources where allowed. Safe runtime
binding supplies fallback text. This follows `UI:hud/toolkit_render.py:2316–2353`. Root icon_id,
allowed generic icon, sizing, clipping and overflow remain active. The following table adds the
specialized active attributes; **every remaining widget-specific attribute in the complete
whitelist maps to I**, preserving it without claiming an unavailable renderer feature.

| Widget(s) | Additional A mapping / explicit limitations |
| --- | --- |
| HudContainer | render_mode none/panel/outline/debug; other anchor/rect/offset/size-policy attributes I. |
| HudPanel,IconTextBar,EntityChip,UnitRailCard,DatasheetHeader,MissionCard,StratagemButton,DicePipeline,Tooltip,StatStrip,StatCell | Generic labelled-shell text/icon/color presentation; specialized stats/weapon/mission/dice pipeline fields I unless delivered by an existing safe runtime binding. No new generic templating or engine action is invented. |
| IconSlot | size and icon_id produce placeholder glyph; badge_text/fallback_glyph/icon_size reservations I where not consumed. |
| StatusChip | shape kind, diameter_px,size_px plus title/value/icon/color. Preserve rounded_rect/pill as legacy labelled-box style with notice. corner_radius_px,preserve_aspect_ratio,content_alignment and progress_fraction remain I for this renderer; fixed round/square extent stays explicit. |
| DonutGauge | outer_diameter,inner_diameter,progress_fraction,color_role; progress is presentation-clamped0–1. Segment/start/sweep/gap/label/center-icon reservations I. |
| DatasheetPanel | stat_cell_height/stat_cell_gap/stat_cell_min_width plus safe-bound header/stat strip. Other zone flags/order/comparison/debug fields I; no invented weapon/ability/keyword model. |
| CurrentActionPanel | title,show_actor,show_request,max_buttons,button_gap,button_height,max_buttons_per_row,button_shape; safe generated buttons retain exact option/request IDs. Decorative unused hints/width reservations I. |
| ActionButton | label,command_id,enabled,icon appearance; known local command resolves through the same command registry as hotkeys. The old window ignored local_command hit regions: make any not-yet-wired command visibly disabled with `command_unavailable`, rather than copying a silent no-op or fabricating game choices. confirmation_required/disabled_reason reservations remain preserved until the local command port supports them. |
| AssignmentGroupRow | summary/title plus button_gap/button_height/button_shape on safe-bound runtime assignment rows; source/target/group semantics come from typed binding, other schema reservations I. |
| DiceTray | title,show_source,face_icon_size and safe-bound roll/source/face-count/diagnostic data. Configured dice assets/history/count/bucket reservations I unless an existing data binding explicitly supplies the corresponding display; never roll or recompute classification in the HUD. |
| PlayerUnitsRoster | title/subtitle,button_gap/button_height/button_min_width/button_shape/status_icon_text, implemented scroll. max_visible_rows I; safe binding defines viewer-scoped rows and local focus actions. |
| Separator | orientation active; fixed visual divider. |

This table is a target normalization policy derived from current use sites, not an assertion that
every reserved field already has native support. It prevents fixed UMG screens from erasing
profiles and prevents accepted schema reservations from silently becoming gameplay features.

## Parser boundary, compatibility and explicit defect diagnostics

The reviewed candidate is **yaml-cpp0.9.0**, immutable commit
[`56e3bb550c91fd7005566f19c079cb7a503223cf`](https://github.com/jbeder/yaml-cpp/commit/56e3bb550c91fd7005566f19c079cb7a503223cf),
retrieved2026-10-16. Its source provides CMake≥3.5, default C++11, static/shared/PIC and MSVC
runtime controls. Plan a private static dependency built with matching UE compiler/runtime,
tools/tests/contrib disabled for the client artifact and no build-time network fetch.
[Pinned build configuration](https://github.com/jbeder/yaml-cpp/blob/56e3bb550c91fd7005566f19c079cb7a503223cf/CMakeLists.txt).
Retain its MIT notice with any adopted copy.
[Pinned licence](https://github.com/jbeder/yaml-cpp/blob/56e3bb550c91fd7005566f19c079cb7a503223cf/LICENSE).

Keep parser exceptions inside a private native boundary and return typed diagnostics; never
throw through UObject/Slate callbacks. The installed UE5.8.3
`Engine/Source/Programs/UnrealBuildTool/Configuration/Rules/ModuleRules.cs:967` declares
`bEnableExceptions` (file SHA256 `45b529f360183a3d840c59d5e864688481eaaed7bcc037f6c89fe38608b0bc58`).
Use a dedicated parser wrapper build unit/module with exceptions enabled; wider modules need
not change exception policy. ABI, linking and actual packaged behavior remain E04 proof.

Do not rely on `Node.as<T>` for legacy scalar semantics: string conversion keeps the scalar,
numeric conversions admit non-finite values, and Boolean conversion also accepts y/n, unlike
the inspected PyYAML resolver. Normalize tagged/plain/quoted scalars, aliases, duplicates and
merge entries into the legacy typed semantic tree before schema validation.
[Conversion header](https://github.com/jbeder/yaml-cpp/blob/yaml-cpp-0.9.0/include/yaml-cpp/node/convert.h),
[Boolean conversion](https://github.com/jbeder/yaml-cpp/blob/yaml-cpp-0.9.0/src/convert.cpp).
The parser event interface exposes scalar tag/anchor and alias/map/sequence events, supporting
an explicit normalization boundary; that interface is source evidence, not proof of the adapter.
[Event interface](https://github.com/jbeder/yaml-cpp/blob/yaml-cpp-0.9.0/include/yaml-cpp/eventhandler.h).

Compatibility import preserves PyYAML semantic results for ordinary aliases/merge keys,
last-key-wins duplicates and documented scalar forms, with a warning for duplicates before
exporting one normalized key. It preserves formerly ignored unknown nested overflow/scroll/shape
subkeys and wrongly typed optional presentation values as inactive raw metadata with
`legacy_value_ignored`, using the documented old effective default. Newly authored active values
are strict. This avoids converting ignored old typos into a silent destructive migration.

Reject explicitly with field/source context: cyclic values (`configuration_cycle`), invalid or
unsafe tags (`unsupported_yaml_tag`), non-finite numbers (`configuration_nonfinite`), non-string
mapping keys, missing/wrong required types, unknown active schema/widget/binding/command IDs,
unsafe package root escape, production sample data and invalid dimensions. Keep legacy severities
for already characterized warning cases. Defaults never mask an error. Proposed application
budgets are1MiB/file, depth64,100,000 normalized nodes,10,000 aliases and64KiB/scalar; exceeding
them reports `configuration_limit_exceeded` with the limit, preserves the original and stops that
import. These are adjustable presentation safety defaults, not claimed old limits or game rules.
JSON receives the same semantic limits/type/finiteness checks. E04 must prove native lexical and
semantic agreement; if the parser cannot represent required tag/merge/duplicate information,
the boundary fails E04 instead of dropping compatibility or requiring a gameplay Python service.

## Complete event ownership, focus, cancellation and retry policy

This is the selected reversible default design, explicitly refining the legacy event handlers
recorded in the capability checklist. It does not claim Unreal execution.
Keep the game viewport full-window initially: deprojection consumes actual game-viewport pixels,
not sidebar-subtracted coordinates. Convert Slate logical hit rectangles through one known UI
scale/viewport adapter; do not apply DPI twice. HUD rectangles exclude world actions and define
camera framing. A future true inset viewport needs an explicit origin/extent adapter.

| State/trigger | Owner, transition and permitted effect |
| --- | --- |
| Modal or editable text focus | Modal/text owner consumes pointer and keys. Text editing owns ordinary characters/Enter; Escape first cancels the focused edit, then a later Escape closes modal. No world or game command falls through. Disabled controls and blank visible HUD zones still exclude world input. |
| Pointer down | Pick owner once: modal/text, topmost HUD interactive/scroll region, visible HUD background, viewport gesture/tool, world selection. Store pointer/button/modifiers, initial viewport position and capture generation; never transfer ownership merely because pointer crosses a panel. |
| HUD button | Activate on release inside the same captured enabled control; release outside cancels activation. Finite option buttons highlight only; explicit Confirm submits. Existing direct context-option action remains an explicit finite submission affordance. Submit/Cancel consumes both press/release with no world click-through. |
| Viewport primary click / drag | Configured selection button click updates local model/unit focus, movement waypoint or current placement pose on completed click. The target uses completed-click commit rather than legacy press-time commit; hover/drag remains advisory preview. Modifiers select current request layer/add/subtract/toggle/group, preserving alias checks. An actual draft edit invalidates ready/review; hover does not. |
| Right button in viewport | Pending camera-or-click candidate until four logical pointer units of movement; then capture orbit for the entire gesture. If no drag, an active movement draft can remove its last waypoint on release within viewport; otherwise no action. Release over HUD/outside viewport cannot remove a waypoint. This preserves the old right-click convenience while separating it from orbit. |
| Middle drag / alternatives | Middle drag pans; wheel outside HUD dollies/zooms around a documented world anchor. Remappable Alt+primary orbit and a separate Remove Last Waypoint key provide alternatives. Camera gestures issue zero game commands and preserve draft/ready values unless projection identity changes. |
| Wheel over configured HUD scroll | HUD consumes wheel even at content boundary; no fallback camera zoom. Unscrollable visible HUD background also excludes camera wheel. Scroll offsets clamp after content/layout change. |
| Keyboard without text/modal owner | Exact normalized key+modifier lookup. Tab cycles request focus; layer/group commands remain local. Confirm on movement/placement first enters Ready review, second Confirm submits; assignment requires a complete reviewed current workspace; finite submits highlighted current option. Disabled/unsupported/missing/stale input gives a visible typed reason. |
| Escape / Clear | If pointer captured, Escape cancels gesture first without deleting committed draft points. Next Escape exits draft/context while retaining current authoritative request; a subsequent explicit action may reopen it. Clear explicitly clears local editor assignments. Neither requests engine rollback or cancels an already submitted action. |
| Focus loss / capture loss / resize | End camera gesture, discard click candidate and never synthesize release activation. Retain draft coordinates/selection but require renewed review before game submission after focus loss. Recompute viewport/scale and hit regions on resize; cancel a crossing drag/click, clamp HUD scroll, preserve domain coordinates. |
| Submission in flight | Freeze that immutable request/payload/sequence/command envelope. Disable duplicate game-effect buttons; allow camera and safe inspection. Local Cancel cannot recall a command; show pending reconciliation. Uncertain transport completion stays Unknown, retaining the same command ID/envelope for supported retry; no optimistic second submission. |
| Authoritative response | Accept only matching session/viewer/connection generation. Accepted outcome refreshes through public facade; invalid same/new request follows the target distinction above. Current context/hash/identity changes invalidate ready state and stale drafts; do not rewrite old IDs to fit a new request. |
| Viewer/session change or disconnect | Increment generation, dispose viewer-bound pending caches/drafts/highlights/events before showing another authorized view. Discard late callbacks. Authenticated remote viewer never follows another actor automatically; spectator never receives submit controls. Local mode may follow only its explicitly authorized local role policy. |

All event traces record owner, stable IDs, draft/ready transition, command identity and resulting
authorized status. They exclude credentials/hidden opponent state. E02/E04 must test press→drag→
release over HUD, focus loss, resize boundaries and repeated Confirm/Escape, with zero command
assertions for camera, hover, local selection, scroll and cancellation.

## Exact missing empirical capture obligations: E08

There is no remaining vague requirement to "discover all13 interaction kinds". Source catalogue,
target delta and intended editor dispositions are explicit. These **future captures** are missing:

| Capture ID / scope | Exact required fixture/procedure and result artifacts |
| --- | --- |
| E08-F finite/nested | For all74 finite/nested target cases, consume the selected98-case catalogue and record case_id, current request/option/actor/viewer, offered option chosen, normalized outgoing payload and facade calls; forged/absent/hidden/wrong-viewer cases must issue no unauthorized client choice. Capture actual parent weapon-source choice for the nested case. For select_source_reposition add both public source procedures cited above; keep envelope-only versus real-session evidence distinct. |
| E08-M movement | Eight kinds × witness form; ordinary/dedicated/attached Scout, individual/subset/group/unchanged models, per-model Z/facing and waypoints; Charge committed subset/no-move; Pile In/Consolidate witnessed and allowed no-move; current public mode/null/fall-back source. Add sequential vacate/cycle and exact-inventory same-request/new-request procedures above. Record ordered model IDs/poses, request/spatial hashes, review/edit/cancel, outgoing envelope, visible before/after projection/events and trusted no-mutation negatives. Dedicated real target fixtures not already committed are captured from the selected public/core-owned canonical procedure after authorization; absence is an empirical fixture-production obligation. |
| E08-P placement | Ten supported kinds with ordinary/grouped components and full model inventory; deployment/redeploy/scout setup envelope; flat materialization/revival/return; split origin, opaque army ownership, rectangular/oval preview, transport explicit-empty context. For each: open/edit/review/submit, malformed owner/model authority, stale request/viewer teardown and invalid/accepted retry. Use selected Core-owned version-matched scenarios, not old gzip checkpoints. Capture all three Cult Ambush cases as typed unsupported with zero submissions. |
| E08-A assignment | Shooting empty/targetless/ordinary/distinct copies/alternate same-copy replacement/borrowed first-later-empty history/current cargo; Melee primary/emitted nested ability source/no-usable-melee and forged source; stratagem unambiguous binding/friendly intent/Heroic modes/authorized decline/mandatory missing candidate. Record user choice sequence, exact issued IDs, normalized declarations, accepted/invalid/stale/unsupported outcomes; target duplicate-profile negative must be atomic. |
| E08-U selection/input | Actual world/roster/Current Action synchronization with hidden surfaces, physical/canonical aliases, local-role handoff, remote principal/spectator, viewer-generation late response, ready/clear/cancel/reopen, focus loss and pointer-owner matrix above. Capture semantic traces and submission counts, not just screenshots. |
| E08-C configuration/HUD | Four preference profiles +two packaged HUDs +four preview examples; normalized A/I/R tree and semantic export/reimport; parser edges and rejection cases above; every accepted attribute classified by the total rule. Render both named layouts at the canonical resolution/DPI matrix with narrow mode, clipping/overflow/scroll/reachable Submit/Cancel; same tree in runtime/preview; PNG+metadata plus actual allocated geometry and focus/command trace. E04 supplies native/parser feasibility results, E08 references those artifacts instead of rerunning automatically. |

Each future packet manifest must name exact Core build/contract/catalog/descriptor hashes,
fixture content hash and generation recipe, role/viewer, input sequence, expected source-supported
outcome, actual result, test count and artifacts. Missing prepared fixtures are a bounded capture
task, not permission to invent a new rule source, mutate Core or claim a no-op screenshot is play.
If an existing selected canonical procedure cannot produce the required fixture, record that
exact external-fixture blocker then; no new inaccessible API is assumed here.

## Honest research disposition

| Question | Source/design disposition now | Remaining evidence gate |
| --- | --- | --- |
| RQ07 | Baseline36-CAP/97-case inventory plus target98-case delta and partial/unsupported/editor subvariants are source-answered; no new supported editor inferred. | E08 captures above BLOCKED on execution authorization/prepared exact environments, not unidentified source discovery. Final parity acceptance remains later. |
| RQ10 | Event priority/capture/focus/cancel/remapping/coordinates/retry policy is specified with intentional legacy differences. | E02/E04 actual interaction/zero-command proof BLOCKED until executed. |
| RQ11/RQ12 | Legacy fields/limits/diagnostics/YAML semantics, total native A/I/R mapping, private parser boundary and responsive legacy/proportional separation specified. Reviewed immutable parser candidate/source requirements supplied. | E04 compiler/ABI/lexical-normalization/corpus/layout/preview proof BLOCKED. This design is not native compatibility success. |
| RQ13 | Default procedural visual/placeholder and cooked identifier policy specified; optional17-SVG source inventory is preserved. No source-art adoption is needed for the slice. | E02 five-shape/mesh/query invariance and cooking evidence later; optional SVG/font provenance reviewed only before adopting/bundling them. |
| RQ16/RQ19/RQ22 | Owner continuity/modes/repository decisions plus copy/exact-core routing/one-writer/coexistence and bounded synthetic reuse designs are specified in this packet set. Migration coordinator records accepted Arcade drift; owner controls actual default switch/retirement. No midgame-back-switch promise. | E06 exact-core recovery and E07 separate-host reuse proof remain later, with no claim existing UI save controls or production CV already exist. |

The remaining items here are named empirical/implementation gates, not reasons to keep performing
unbounded read-only research. Root should reconcile the canonical register accordingly and ask
for the appropriate bounded authorization. Missing Linux execution remains explicitly waived for
Windows source/bootstrap progress, with Linux marked UNTESTED until a real host runs it.
No test or experiment is marked PASS by this document.
