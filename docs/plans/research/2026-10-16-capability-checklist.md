# Source characterization checklist: Arcade capabilities and configuration

Date: 2026-10-16. Supporting evidence for
[`../unreal-migration-plan.md`](../unreal-migration-plan.md), extending
[`2026-10-16-parity-and-data.md`](2026-10-16-parity-and-data.md).

## Evidence identities, scope and reading rules

`UI` is `Warhammer_40k_UI_arcade@5088c1c49dcaff29eb59fb64b3063d30214dde73`.
Abbreviated `state/`, `render/`, `core_client/`, `hud/`, `preferences/`, `resources/`,
`input/` and `diagnostics/` paths are beneath `src/warhammer40k_arcade_ui/`.
Unprefixed `test_*.py` filenames in tables are beneath the UI `tests/` directory.
`Core44.1` is the UI's pinned `Warhammer_40k_AI@fc12fa214642f1b1f2a31b56be7323b7d76dbebc`.
Its historical contract JSON was read using `git show` without changing the sibling checkout.
The owner-selected Unreal target is the separate sibling candidate, Contract **44.3.33**;
its compatibility delta belongs to the contract research packet. No statement below silently
promotes a Core44.1 example, UI parser or test into target44.3.33 support.

All findings are source inspection, not execution results. Existing tests listed here are
characterization assets and named future verification targets. Some assertion bodies were read;
others are named by source discovery and need execution/review at the approved target. **No test,
GUI, parser probe, engine, checkpoint traversal, converter or new experiment was executed.**

The coordinator relayed owner decisions on 2026-10-16: preserve profiles and exact-core sessions;
no midgame switching back to Arcade is required; personal/internal first; Windows and Linux in
the first slice; local/remote/participant/spectator modes; adapt to the exact44.3.33 sibling.
Those choices remove the earlier continuity/product questions; they do not prove loader,
authorization, packaging or platform behavior. Refer to the canonical owner-decision record.
The later owner clarification selects the current checkout's existing development command host,
with Linux execution hosts supplied later: plumb Linux support now and label it untested. A missing
Linux test host does not itself prevent source/bootstrap work under the recorded waiver; it still
cannot be counted as a tested Linux package or rendered result. No new Python host implementation
is authorized by this delivery choice.

The catalogue below explicitly covers all CAP01–CAP36 rows, all **97 Core44.1 conformance cases**
(72 top-level finite, one nested finite, 24 parameterized cases), every declared preference field,
and the actual loader's relevant YAML semantics. This closes a broad-family-only omission in the
earlier evidence. It is **not exhaustive end-to-end target acceptance**: real-session variants,
target44.3.33 differences and empirical tests remain obligations. An unchecked workflow is not
silently removed because parser coverage exists.

## CAP01–CAP36 workflow checklist

`P` = preserve implemented behavior; `R` = redesign presentation while preserving intent;
`N` = required new capability; `U` = explicitly unsupported/deferred baseline behavior.
Every row's checks are pending target implementation/acceptance, unless a later execution record
explicitly supplies results. Milestones use the canonical plan's identifiers.

| CAP / disposition / milestone | Concrete workflow and variant checklist | Source and existing check/procedure; negative/limit |
| --- | --- | --- |
| CAP01 P / M03 | [ ] Fixture launch is labelled; [ ] real local start negotiates then opens; [ ] attach/remote launch follows selected host contract. | `app.py:84–184`, `main.py:90–180`; `tests/test_entrypoint.py:142–214`, `tests/test_live_core_smoke.py:105–240`. Typed startup/unsupported checkpoint errors must stay visible; fixture success is not real-core proof. |
| CAP02 P / M01,M03 | [ ] Exact build/contract/schema/content match; [ ] wrong build, revision, schema or fixture identity fails before play. | `core_client/compatibility.py:70+`; `tests/test_contract42_compatibility.py:13–49`; `tests/test_core_contract_fixture_gate.py:43–296` covers missing/dirty/hash/schema/empty-family fixtures. Target44.3.33 needs its own identity set. |
| CAP03 P / M03 | [ ] Current finite/parameterized public request forwards exact IDs/payload; [ ] accepted outcome refreshes; [ ] invalid/unsupported/terminal stays distinct. | `core_client/local_session_client.py:63–205`, `state/finite_decision.py:324–402`, each submission module. `tests/test_finite_decision_state.py:87–245`, movement/placement/assignment submission tests. No private rules/lifecycle path. |
| CAP04 P / M03,M04 | [ ] Every finite family/group in the catalogue below; [ ] nested source selection; [ ] highlighted option and direct context option; [ ] dice/confirmation/ordered/opportunity forms. | `state/finite_decision.py:65–148,193–258`; `tests/test_contract42_finite_source.py:91–160` routes nine new families with forged-ID rejection; `tests/test_finite_decision_state.py:21–66,246–319`. Catalogue parser checks alone do not prove each reachable flow. |
| CAP05 P,R / M03,M04 | [ ] Eight movement kinds; [ ] model/subset/group assignment; [ ] endpoints/waypoints/unchanged paths; [ ] Scout setup envelope; [ ] family no-move and committed targets; [ ] stale/invalid/retry/cancel. | `state/movement_draft.py:444–539,702–1053`, `state/movement_submission.py:51–300`; `tests/test_movement_draft.py:198–579,592–770`, `tests/test_movement_submission.py`. Missing mode/context and foreign members block locally; core owns legality. |
| CAP06 P,R,U / M04 | [ ] Ten supported placement kinds; [ ] ordinary/grouped physical models; [ ] deployment/redeploy/setup fields; [ ] materialization/revival/return flat forms; [ ] one pose per required model, retry and viewer clear. | `state/placement_draft.py:28–56,299–424,616–727`; `tests/test_placement_draft.py:15–115`; attached/materialization/split/whole-return/setup tests listed below. Cult Ambush marker variants and `cult_ambush_placement` are unsupported by actual editor despite recognized protocol. |
| CAP07 P,R,U / M05 | [ ] Shooting ordinary/duplicate copy/multi-profile/targetless/empty/Firing Deck; [ ] melee emitted primary/source; [ ] stratagem binding/friendly intent/Heroic modes/decline; [ ] complete/incomplete/stale. | `state/assignment_workspace.py:146–268,271–889`, `state/assignment_submission.py:49–227`; `tests/test_assignment_workspace.py:54–1177`; shooting/Firing Deck/melee/Heroic HUD and real-session modules. Melee split attacks and optional extra-attacks editing are explicit follow-ons (`workspace:681–684`). |
| CAP08 P,R,U / M05 | [ ] Finite reaction/opportunity/grant choices; [ ] optional declination only where issued; [ ] parameterized stratagem continuation; [ ] unsupported routes report reason. | `interaction_dispatch.py:16–117`; `tests/test_assignment_workspace.py:768–925`, `tests/test_contract42_overwatch.py:117–253`, Heroic tests. No generic arbitrarily composed intent tray is established. |
| CAP09 P / M04,M05 | [ ] Public smoke traversal through advertised setup/prebattle/movement/shooting; [ ] accepted/invalid decision progression; [ ] terminal/unsupported/unreachable phase. | `core_client/live_smoke.py:110–179`; `tests/test_live_core_smoke.py:105–461`. Charge/Fight scenarios in dedicated fixtures do not establish canonical smoke checkpoints or full-game playability. |
| CAP10 P,R / M04 | [ ] World model/unit/alias focus; [ ] roster and Current Action selection sync; [ ] attached physical versus canonical actor; [ ] hidden panels do not break sync; [ ] viewer drift clears. | `render/arcade_window.py:746–777,1220–1580,2168–2404`; `tests/test_gui_event_driver.py:84–286,514–633`, `tests/test_contract42_attached_prebattle.py:555–1086`, charge-source tests. Foreign/stale aliases must not retarget a request. |
| CAP11 P,U / M01,M05 | [ ] Preserve current projected roster/display and pending unplaced-unit rows; [ ] reject unsupported construction/import rather than inventing army authoring. | `hud/ergonomics.py:413–560`, `state/interaction_dispatch.py:99–117`, full `main.py:90–180`; `tests/test_hud_ergonomics.py:182–488`. No user roster import/edit CLI or functioning roster-construction editor found. |
| CAP12 P,R / M02–M05 | [ ] HUD versus world click priority; [ ] ready/review/submit; [ ] cancel/clear; [ ] wheel capture; [ ] click/drag threshold; [ ] focus/capture loss and release outside viewport. | `render/arcade_window.py:693–1053,1091–1159`; `tests/test_gui_event_driver.py:48–105,309–452,634–651`. Focus loss/pointer capture proof is new, not implied by these tests. |
| CAP13 R / M02,M03 | [ ] Inch-space continuous conversion; [ ] pointer-anchored zoom/pan baseline; [ ] new 3D orbit/pitch/dolly/framing; [ ] cross-view same-world-target commands. | `render/camera.py:14–140`; `tests/test_render_camera.py:10–82`. A planar camera test does not prove Unreal picking or depth. |
| CAP14 P,R / M02,M03 | [ ] Separate support/measurement/query/display shapes; [ ] identical semantic geometry after art/mesh replacement. | `render/core_projection.py:418–590`, `render/primitives.py:418–449`; `tests/test_contract42_projection.py:106–217`, `tests/test_core_projection.py:298–355`. New E02 mesh-substitution invariance proof required. |
| CAP15 P,R / M02 | [ ] Circle/rectangle/ellipse/capsule/polygon model bases; [ ] facing/asymmetry; [ ] concavity/triangulation; [ ] terrain parser limitations distinct. | `render/core_projection.py:482–637`; `tests/test_contract42_projection.py:123–198`. All five parse/model forms exist; source parser alone is not all-shape rendering/picking acceptance. |
| CAP16 P,R / M02,M03 | [ ] Preserve nonzero Z and facing in DTO/drafts; [ ] render actual elevation and terrain volume; [ ] explicit invertible unit/handedness conversion. | `render/core_projection.py:418–464`, `state/movement_draft.py:514–520,1461–1472`; `tests/test_contract42_projection.py:106–122,200–288`, `tests/test_movement_draft.py:334–392`. Legacy XY drawing flattens elevation; no new rules semantics. |
| CAP17 P,R / M02,M04 | [ ] Bounds/origin, deployment zones and cutouts; [ ] objectives/linked terrain; [ ] typed areas/features; [ ] empty deployment; [ ] malformed geometry. | `render/core_projection.py:135–265`; `tests/test_core_projection.py:17–297`, `tests/test_render_primitives.py:65–133`. Nonzero origin support needs explicit new converter evidence, not legacy assumptions. |
| CAP18 N / M02 | [ ] Optional world grid only; [ ] scale/aliasing/visibility; [ ] toggling never snaps or changes payload. | No functioning grid workflow found in inspected procedural primitive path. E02/new zero-command and continuous-coordinate proof required; no existing pass claimed. |
| CAP19 P,R / M03,M04 | [ ] Selection/advisory target/path/waypoint/ghost/range; [ ] core distance text; [ ] dim/review label limits; [ ] occluded/offscreen/behind-camera labels. | `render/primitives.py:177–216,453–778`; `tests/test_render_primitives.py:134–467`, `tests/test_action_summary.py`. 3D occlusion and camera cases are new. |
| CAP20 P,R / M02 | [ ] Procedural base/color/text equivalence; [ ] 17 SVG sources and stable icon IDs; [ ] missing-art fallback; [ ] geometry missing is fatal. | Resource manifest in companion report; `core_projection.py:331–340`, `hud/toolkit.py:284–295`, `toolkit_render.py:1503–1526`. Current texture placeholders are actual baseline; no raster/font licence or import/cook settings inferred. |
| CAP21 P,N / M02,M03 | [ ] Camera/hover/selection commands are local; [ ] camera gestures issue zero gameplay submissions; [ ] trusted state/revision unchanged. | `camera.py:93–126`, window input source, `tests/test_gui_event_driver.py:634–651`. Full command-count/trusted-state assertion requires E02; unchanged camera zoom alone is narrower evidence. |
| CAP22 N / M02,M03 | [ ] Shallow token and ordinary mesh coexist; [ ] same IDs/focus/HUD/commands/query geometry; [ ] cosmetic bounds never become legal footprint. | No existing ordinary3D replacement implementation; E02 proof required. Keep separate visual-definition/query contract from CAP14. |
| CAP23 P,R / M02,M05 | [ ] All accepted widgets/attributes/data refs; [ ] same normalized tree live and preview; [ ] strict production/preview separation. | `hud/composition.py:235–288,430–567`, `toolkit_render.py:54–153`; `tests/test_hud_widget_toolkit.py:353–598`. Full whitelist and permissive exceptions recorded below. |
| CAP24 P,N / M02,M05 | [ ] `compass_ring`/`command_bench` zones, visibility/collapse/fixed sizes; [ ] additive proportional mode; [ ] narrow drawer/reflow. | `preferences/schema.py:35–43,609–712`, `hud/layouts.py`; `tests/test_hud_layouts.py:19–101`. Widget `%` is not zone `size_px`; proposed proportional sizing must not reinterpret old files. |
| CAP25 P,R,U / M05 | [ ] Text scale/high contrast; [ ] all overflow/scroll/chip forms; [ ] long labels, reachable controls and keyboard focus. | `hud/toolkit.py:1059–1181`, `toolkit_render.py`; `tests/test_hud_widget_toolkit.py:204–352,639–882`. Icons are placeholders; scrollbar dragging, advanced anchor placement and rounded/pill visuals are incomplete. |
| CAP26 P,R / M05 | [ ] Every preference field/default/error below; [ ] active/inactive/extension preservation; [ ] explicit/default/builtin/relative paths; [ ] stale profiles; [ ] safe export. | `preferences/io.py`, `schema.py`, `registries.py`; `tests/test_preferences.py:33–407`, composition-reference tests `test_hud_widget_toolkit.py:382–529`. Do not claim arbitrary YAML or reject all tolerated values without a recorded mapping. |
| CAP27 P,R / M02,M05 | [ ] Whole composition/subtree preview; [ ] theme/density/window choices; [ ] headless PNG+metadata; [ ] same renderer as live. | `hud/preview.py:140–160,338+`; `tests/test_hud_widget_toolkit.py:372–381,884–965`. Unreal preview CLI/tool does not yet exist. |
| CAP28 P,R / M03,M05 | [ ] off/summary/payload/render trace modes; [ ] includes/excludes/category/config; [ ] truncate/rotate; [ ] fatal bundle+trace; [ ] token redaction; [ ] ordinary invalid is not crash. | `diagnostics/forensic_trace.py:96–219,295–399`; `tests/test_forensic_trace.py:25–275`, `tests/test_crash_report.py:31–119`. Keep viewer data isolated; diagnostics are not authoritative replay. |
| CAP29 P,N / M01,M03 | [ ] Request actor versus viewer/turn owner; [ ] per-view projection/events/display caches; [ ] viewer switch/failed refresh clears old data; [ ] async generations; [ ] remote/spectator authorization. | `local_session_client.py:77–112,194–205`, `finite_decision.py:354–402`, `arcade_window.py:2538–2638`; `tests/test_contract42_projection.py:452+`, finite viewer-handoff tests. Following next actor locally is not remote authentication. |
| CAP30 P,N / M03,M06 | [ ] Preserve original exact-core artifacts; [ ] route/open compatible sessions; [ ] current session restart and corrupt/mismatched rejection; [ ] backup/one-writer rule. | No UI save/resume API discovered; full CLI and LocalSessionClient inspected. `docs/plans/phase-35-contract-44-1-m2-evidence.md:44–60` limits test checkpoints. Owner does not require midgame switching; E06 must prove the promised exact-core session workflow. |
| CAP31 P,R / M01,M04,M05 | [ ] Current source identity/copy/nullable/retained/split/committed-target behaviours; [ ] selected target44.3.33 delta with separate fixtures. | Current44.1 evidence and contract42-named test modules. Historical42 bugs/failures are not current44.1 facts; current44.1 outcomes are not future44.3.33 proof. |
| CAP32 R,N / M03,M07 | [ ] Separate native Windows+Linux bundles in first slice; [ ] local/attach/remote deployment as selected; [ ] packaged real action on clean hosts. | Arcade `pyproject.toml:19–35`; `tests/test_packaging_metadata.py:11–49` verifies Python metadata/resources only. Unreal packages/external runtime consumption unexecuted. |
| CAP33 N / M00,M07 | [ ] Matched workload identities/hardware; [ ] measured frame/input/startup/memory; [ ] transport/core attribution; [ ] budgets agreed from evidence. | Prior Contract42 measurements are historical; no current controlled baseline or Unreal speedup established. E05 needs real measurements. |
| CAP34 N / M06 | [ ] Same safe presentation/composition in separate synthetic observation host; [ ] resolved/ambiguous/stale/lost/duplicate/manual correction; [ ] explicit intent uses current core path. | Companion report RQ19 contract proposal; no observation host exists. E07 proves seam/authority, not physical recognition or hardware calibration. |
| CAP35 U / all | [ ] Acceptance never depends on detailed miniatures, rigs, paid art or replacement library; [ ] approved minimal visuals remain usable. | Settled plan scope. Future optional art is separate work and cannot silently become a first-slice dependency. |
| CAP36 U / all | [ ] No new gravity/elevation rules or production CV/projector stack; [ ] preserve existing authoritative Z; [ ] label synthetic observations. | Settled scope and authority boundary. New hardware/vision work needs its own project; retained Python core is not retired. |

## Finite and nested variant catalogue at Core44.1

Immutable source: `Core44.1:contracts/examples/decisions/interaction-conformance.json`, named
`finite:<decision_type>` cases below, and `nested:select_weapon_ability_instance`.
The file contains 72 finite cases + one nested finite case; each selected variant is
`finite_option`. `family-coverage.json` contains 73 finite families, 13 parameterized decision
families and a non-submittable hidden discriminator. These source counts were obtained by
read-only JSON metadata inspection, not by running the application's conformance suite.

| Interaction | Complete finite/nested decision-type list in this baseline catalogue |
| --- | --- |
| `confirmation` | `discard_tactical_secondary_mission`, `draw_tactical_secondary_missions`, `replace_tactical_secondary_mission`, `score_tactical_secondary_mission`, `select_cult_ambush_resurgence`, `select_lethal_hit_wound`, `select_stratagem_cost_modifier_option` |
| `dice_selection` | `select_dice_extremum`, `select_dice_reroll`, `select_dice_result_override` |
| `entity_selection` | `select_beacon_unit`, `select_catalog_movement_end_target_effect`, `select_catalog_post_fight_hit_target_effect`, `select_catalog_post_shoot_hit_target_effect`, `select_catalog_post_shoot_hit_target_status`, `select_catalog_unit_move_completed_mortal_wounds_target`, `select_charging_unit`, `select_damage_allocation_model`, `select_deployment_unit`, `select_desperate_escape_model`, `select_embark_transport`, `select_fight_activation`, `select_healing_model`, `select_mortal_wound_model`, `select_movement_unit`, `select_precision_allocation`, `select_redeploy_unit`, `select_resolve_target_unit`, `select_shooting_unit`, `select_tracked_target` |
| `finite_option_list` | `resolve_tactical_secondary_when_drawn`, `select_burden_of_trust_guard`, `select_catalog_movement_target_pair`, `select_charge_targets`, `select_core_ability_instance`, `select_feel_no_pain`, `select_melee_weapon`, `select_modifier_ignores`, `select_movement_action`, `select_prebattle_action`, `select_primary_mission_choice`, `select_psychic_attack_modifier_ignores`, `select_reserve_declaration`, `select_secondary_missions`, `select_shooting_type`, `select_target_replacement`, `select_tempting_target_objective`, `select_unit_split_membership`; nested `select_weapon_ability_instance` |
| `opportunity_window` | `resolve_fight_interrupt`, `resolve_reaction_window`, `select_catalog_any_phase_once_per_battle_ability`, `select_catalog_setup_reactive_shoot_charge`, `select_charge_declaration_grant`, `select_destruction_reaction`, `select_faction_rule_battle_round_option`, `select_faction_rule_command_phase_start_option`, `select_faction_rule_fight_phase_end_option`, `select_faction_rule_fight_phase_start_option`, `select_faction_rule_setup_option`, `select_faction_rule_shooting_phase_start_option`, `select_faction_rule_turn_end_option`, `select_fight_activation_ability`, `select_fight_unit_grant`, `select_movement_action_grant`, `select_shooting_unit_grant`, `select_triggered_movement`, `start_mission_action`, `use_stratagem` |
| `ordered_sequencing` | `resolve_sequencing_order`, `select_allocation_order`, `select_post_roll_attack_pool` |
| `weapon_allocation_matrix` | `select_attack_weapon_group` is **finite**, despite its matrix presentation kind. |

All finite choices preserve current request/option IDs through `FiniteDecisionUiState.prepare_submission`
and `submit_finite_option` (`state/finite_decision.py:193–258,324–351`). Unknown option, absent
request and parameterized-as-finite submissions stop before client calls. Hidden decisions must
not supply options. Core provides selected-source identities, sequencing and numeric choices;
the client does not synthesize them. Finite matrix/dice requests still use this finite path.

`UiGameView` parses `nested_interaction_requests` (`core_client/protocol.py:1836,1867,1956–1964`),
but source search found no separate generic window consumer of that tuple. Assignment editors
instead consume emitted weapon/source options embedded in their parent request
(`assignment_workspace.py:692–748,1396–1466`). The nested case therefore needs both parse evidence
and the actual parent-source selection test; merely listing the nested finite request is insufficient.
Existing `tests/test_contract42_melee_sources.py:157+` and
`tests/test_assignment_workspace.py:705–767` are the relevant issued-source/forged/stale checks.

Common finite tests: `tests/test_finite_decision_state.py:21–66,87–245,246–319`;
`tests/test_contract42_finite_source.py:116–160` performs fake-facade exact-ID positive and
forged-ID negative routing for nine newer families. Real-session tests in that file separately
cover private extrema (`162+`), duplicate core sources (`324+`), mandatory destruction reaction
(`552+`), save/AP/roll-source distinctions (`629+`), random-expression identity (`773+`) and
action-OC scope (`1108+`). `tests/test_dice_tray.py:18–360` covers roll/reroll/override display,
physical-face versus assigned/aggregate evidence, mismatch diagnostics and absent visible roll.
These are named existing assertions, not executed results.

## All 24 parameterized conformance cases and editor subvariants

Case IDs are `parameterized:<name>` from the same immutable Core44.1 conformance file.
The selected submission variant equals `<name>` except Cult Ambush marker (`place_marker`),
Cult Ambush no-marker (`no_marker`) and `submit_return_on_death_placement`
(`return_on_death_placement`). This table explicitly separates protocol recognition, editor
opening, serialization and real/HUD evidence. No row establishes target44.3.33 compatibility.

| Case / route | Actual baseline serialization/editing; positive/failure evidence |
| --- | --- |
| `normal_move` / path | Request/context/selected-model paths; initial/current Z+facing and unchanged paths; mode mandatory. `movement_draft.py:444–539,934–975`; `test_movement_draft.py:34–334,623–646`; live smoke and submission tests. Display base-M fallback is advisory, not legality. |
| `advance` / path | Same witness envelope, engine context and advisory base-M+advance-roll budget. `movement_draft.py:934–975,1266–1328`; `test_movement_draft.py:158–179`; `test_live_core_smoke.py:343–450` surfaces invalid advance and endpoint-only paths. |
| `fall_back` / path | Same witness plus required issued `fall_back_mode` when kind/action is fall back. `movement_draft.py:968–974,1207–1230`; `test_movement_draft.py:592–667` preserves mode and rejects absent mode. |
| `surge_move` / path | Same movement serializer, `maximum_distance_inches`; nullable movement mode only when public source permits it. `movement_draft.py:1176–1222,1252`; `test_contract42_public_contexts.py:257–313` exercises public target and nullable mode; ordinary missing mode negative at `456+`. |
| `charge_move` / path | Witness + **committed** `target_selection.target_ids`, not every reachable target; optional stratagem handler. Without assignments emits no witness/model_movements and empty charge target list. `movement_draft.py:939–940,1011–1027`; `test_movement_draft.py:394–578`; `test_contract42_charge.py:26+`, `test_contract42_charge_sources.py:389–568` cover real committed subset/attached membership/HUD. |
| `pile_in` / path | Same witness; copies public legal pile-in target IDs; no-assignment variant omits witness and emits empty target list. `movement_draft.py:1028–1036`; `test_movement_draft.py:449–529` parameterized witness preservation; no-move serialization exists but dedicated real no-move acceptance remains unverified. |
| `consolidate` / path | Same witness; copies legal consolidate targets; selects first issued consolidation mode when present; no-move omits witness/targets/mode. `movement_draft.py:1037–1052`; same witness regression `449–529`. Alternative consolidation-mode editing is not established; do not claim full option selector. |
| `scout_move` / path | Separate setup/game/ruleset/player/source/action/scout-distance envelope plus witness/context; ordinary/dedicated-transport action forms. `movement_draft.py:977–1009`; `test_movement_draft.py:449–529`; `test_contract42_attached_prebattle.py:469–1110`; `test_contract42_charge_sources.py:859+` for issued distance sources. |
| `reinforcement_placement` / multi-model | Generic `submit_placement_proposal`, all required poses, explicit public owner/army, `attempted_placement` or grouped components. `placement_draft.py:616–727`; `test_placement_draft.py:15–60`; attached real/HUD invalid/stale retry `test_contract42_attached_placement.py:153–273`. |
| `deep_strike_placement` / multi-model | Same generic serializer/context ownership; canonical split origins preserved. `placement_draft.py:299–424,616–727`; `test_contract42_split_placement.py:53+` tests owner/viewer/placement branches; setup arrival tests provide public continuation. Dedicated all-mode real coverage must be checked at target. |
| `strategic_reserves_placement` / multi-model | Same serializer plus emitted arrival/restriction context. `test_contract42_setup_arrival.py:749–1118` covers edges/corner/oversized/round deadlines/Aircraft mandatory arrival; target legality remains core-owned. |
| `disembark_placement` / multi-model | Same ordinary/grouped serializer; context forwards transport ID/mode/movement status/restrictions and **explicit empty** `start_engaged_enemy_unit_instance_ids`. `placement_draft.py:711–726`; grouped decoder/source test `test_contract42_attached_placement.py:274–367`; real rapid/tactical/shock paths `test_contract42_setup_arrival.py:1119–1227,1307+`. Do not label grouped decoder evidence live attached-disembark acceptance. |
| `deployment_placement` / multi-model | Setup fields + `model_placements`, request/context; public ownership for unplaced units. `placement_draft.py:623–640`; `test_placement_draft.py:61–100`; `test_contract42_attached_prebattle.py:274–468` real empty-board attached deployment and missing public army error; opaque/split army tests `test_contract42_opaque_placement.py:90–218`. |
| `redeploy_placement` / multi-model | Setup envelope adds issued `action_kind` and context. `placement_draft.py:641–660`; reachable public prebattle smoke and `test_contract42_split_placement.py:53+`; dedicated all-source acceptance remains an execution obligation. |
| `scout_reserve_setup` / multi-model | Same prebattle action envelope. `placement_draft.py:641–660`; smoke prebattle tests; no dedicated all-action real acceptance claim from generic serializer. |
| `model_materialization_placement` / multi-model | Flat request; new requested model IDs may not yet exist in projection. Exact request model/base/army authority is required; generic attempted placement serializes new poses. `protocol.py:1283–1326`, `placement_draft.py:299–424`; `test_contract42_materialization_placement.py:64–551` covers headless edit, rectangular advisory radius, malformed authority, stale/invalid, viewer clear and real accepted retry. |
| `healing_revival_placement` / model-pose | Flat request normalized to same public identity; current/request model authority and emitted phase-start witness forwarded. `protocol.py:1327–1390`; `test_contract42_setup_arrival.py:1228–1306`; specific invalid/retry real branches need target validation. |
| `submit_return_on_death_placement` / model-pose | Flat request; submission is explicitly `{submission_kind: submit_return_on_death_placement, attempted_placement: ...}`. `placement_draft.py:665–677`; `test_contract42_whole_unit_return.py:159–369` covers all destroyed models, oval/rectangle previews and absent/foreign model authority. |
| `cult_ambush_placement` / multi-model | Protocol recognizes the generic proposal but `SUPPORTED_PLACEMENT_PROPOSAL_KINDS` excludes this kind (`placement_draft.py:43–56,750–766`). Thus route support does not establish an opening editor. Preserve typed unsupported; new support requires explicit scope disposition, not inferred parity. |
| `cult_ambush_marker_placement` / point, `place_marker` | Request publishes both `place_marker` and `no_marker`; route marks **all multi-variant descriptors unsupported** before variant choice. Point editor is also unsupported (`interaction_dispatch.py:78–116`). Parser test `test_core_client_protocol.py:224+` does not implement either branch. |
| `cult_ambush_no_marker` / point, `no_marker` | Same multi-variant rejection. Do not invent no-marker button or skip this case because it has no point geometry. Both conformance variants need explicit unsupported disposition until approved new work. |
| `shooting_declaration` / assignment matrix | Parent request supplies physical copy/profile/source options, target and targetless rows, limits, history, visibility key. Empty declaration and selected nullable target are distinct. `assignment_workspace.py:271–514,974–1116,1290–1395`; ordinary/duplicates/multi-profile/targetless/stale/forged tests `test_assignment_workspace.py:54–679`, real `test_contract42_shooting.py:96–421`, HUD `test_contract42_shooting_hud.py:18–112`. Firing Deck first/later/empty history/current cargo/drift `test_contract42_firing_deck.py:481–714`. |
| `melee_declaration` / assignment matrix | Current primary physical weapon, engaged target and issued ability-source choice; one selected row/model, explicit source linkage, automatic initial single primary choice only if unambiguous. `assignment_workspace.py:516–748`; `test_assignment_workspace.py:680–767`, `test_contract42_melee_sources.py:157+` accepted/forged/stale. Optional extra attacks/split allocations are not editor-complete (`681–684`). |
| `stratagem_target_binding` / parameterized entity selection | Supports one unambiguous emitted binding or source-permitted selected friendly intent; Heroic requires an explicit issued mode. Serializes `{proposal:{proposal_kind,context,catalog_record,target_binding,effect_selection}}`; decline only engine-authorized `{submission_kind: decline_stratagem_window}`. `assignment_workspace.py:197–225,750–888`; `test_assignment_workspace.py:768–925,945–964`; `test_contract42_heroic_intervention.py:96–251`, HUD `test_contract42_heroic_hud.py:19+`. No candidate+mandatory creates diagnostic, optional can decline. |

Common parameterized failure lifecycle: route/proposal/readiness/current request/spatial context
and selected variant must agree before submission. Movement preserves an invalid same-request
draft as preview, while a changed request clears it (`movement_submission.py:289–300`);
placement clears submitted draft after invalid (`placement_submission.py:267–279`), and assignment
rebuilds only against its current request. `status_after_submission` advances only on `advanced`;
invalid/waiting/unsupported/terminal boundaries stay visible. Cancellation, projection refresh and
viewer switching must be characterized independently of successful serialization.

Request envelope is not optional syntax: four decision types are flat (Cult Ambush marker,
materialization, healing revival, return-on-death); others require `payload.proposal_request` with
matching request/type/actor. `core_client/protocol.py:1487–1525` and
`tests/test_contract42_protocol.py:28–102` reject flat/nested substitution and mismatched identities.
All24 catalogue cases are parsed by `tests/test_contract42_conformance.py:172–198`, which accepts
typed unsupported routes and therefore is not24 successful editor submissions.

## Complete preference-field mapping at UI baseline

Canonical type/validation source: `preferences/schema.py:17–75,262–1208`.
All unknown keys in root, overlays, each hotkey, selection, HUD, each zone and experimental
objects are **errors** (`unknown_key`); malformed nonempty-string keys are `invalid_key`.
`extensions` and `experimental.planned_settings` intentionally allow their JSON-safe values,
with planned IDs registry-checked. A typed `preferences` object may coexist with errors; callers
must inspect `has_errors`. Only invalid root type and wrong schema immediately return none.

| Field | Accepted value, default and presentation semantics | Parser / diagnostics |
| --- | --- | --- |
| `schema_version` | Required **string** exactly `"1"`; numeric YAML1 is not preference-schema equivalent. | `262–315`, `invalid_string`, `unsupported_schema_version`. HUD composition schema separately accepts integer1. |
| `profile_name` | Required nonempty string; exported as given. | `291`, `827–845`, `invalid_string`. |
| `overlays.default_on_model_selection` | Required list of known nonempty overlay IDs, preserves order/duplicates. Default profile: selected_model. | `319–359,751–773`, `invalid_list/string`, `unknown_overlay_id`, inactive warning. |
| `overlays.default_on_unit_selection` | Same; default selected_unit. | Same. |
| `overlays.default_on_movement_draft` | Same; default movement_path_draft,movement_budget. | Same. |
| `overlays.enabled_by_default` | Same; default debug_coordinates. | Same. |
| `hotkeys` | Required list; each object: required `command_id`, required `key`, `modifiers` must be a list even though dataclass default is empty, optional nullable `overlay_id`. | `362–457`, `invalid_hotkeys/hotkey/list/string`; unknown IDs error; planned ID warning. |
| `hotkeys[].key` | Lowercased; one a–z/0–9, f1–f12, or named escape/enter/tab/space/backspace/delete/up/down/left/right/pageup/pagedown/home/end. No trimming in `_normalize_key`. | `1112–1137`, `invalid_key_syntax`. |
| `hotkeys[].modifiers` | ctrl/alt/shift/meta lowercased and deduplicated, preserving first occurrence. Binding identity sorts modifiers; same normalized key+modifiers is duplicate regardless of command. | `1087–1109`, `invalid_modifier`, `duplicate_hotkey`. |
| `selection.default_mouse_button` | Required left/right/middle; default left. | `460–492`, `invalid_mouse_button/string`. |
| `selection.cycle_overlapping_bases` | Required exact Boolean; default true. | Same, `invalid_bool`. |
| `hud.layout_preset` | Required compass_ring or command_bench; error construction fallback compass_ring is not permission to launch with errors. | `623–642`, `invalid_hud_layout_preset`. |
| `hud.composition_profile` | Missing/null → none in schema; otherwise nonempty string. Live composition loader then errors on missing reference; built-in IDs/file references have source-relative semantics. | `549`, `848–870`; `composition.py:216–232,331–356`. |
| `hud.zones` | Required object; missing individual zone retains default. Each provided known zone requires exact Boolean visible/collapsed and integer size_px in zone bounds. | `645–712`, `invalid_section/key`, `unknown_hud_zone_id`, `invalid_integer/bool`, `invalid_hud_zone_size`. |
| `hud.show_phase` | Required Boolean, default true. | `551`, `invalid_bool`. |
| `hud.show_active_player` | Required Boolean, default true. | `552`, `invalid_bool`. |
| `hud.show_event_log` | Required Boolean, default true. | `553`, `invalid_bool`. |
| `hud.show_config_diagnostics` | Required Boolean, default true. | `554–559`, `invalid_bool`. |
| `hud.show_assignment_hud` | Required Boolean, default true. | `560–565`, `invalid_bool`. |
| `hud.assignment_hud_mode` | Required compact/detailed; default profile compact. | `566–571,938–957`, `invalid_assignment_hud_mode`. |
| `hud.show_assignment_warning_markers` | Required Boolean, default true. | `572–577`, `invalid_bool`. |
| `hud.assignment_target_highlight_color` | Missing/null → [220,54,64,72]; otherwise exactly four exact integers0–255; Boolean is not integer. | `578–584,1004–1053`, `invalid_rgba_color`. |
| `hud.action_summary_default` | Required hidden/dim/review; default profile dim. | `585–590,960–979`, `invalid_action_summary_default`. |
| `hud.action_summary_max_labels` | Required exact integer0–20; default6. | `534–546`, `invalid_integer`, `invalid_action_summary_max_labels`. |
| `hud.movement_budget_ring_mode` | Missing → total; valid total/split; explicit null invalid; default total. | `982–1001`, `invalid_movement_budget_ring_mode`. |
| `hud.show_chain_breadcrumbs` | Required Boolean, default true. | `598–603`, `invalid_bool`. |
| `hud.text_scale` | Required exact int/float, excluding Boolean; range0.5–2, default1.0. | `523–533,894–914`, `invalid_number`, `invalid_text_scale`; NaN hardening gap below. |
| `hud.high_contrast` | Required Boolean, default false. | `605`, `invalid_bool`. |
| `experimental` | Required object; allowed only planned_settings. | `715–749`, `invalid_section`, `unknown_key`. |
| `experimental.planned_settings` | Missing/null → {}; known setting ID → any JSON-safe value preserved inactive; unknown ID error. | `723–743`, `unknown_planned_setting`, `inactive_planned_setting` warning. |
| `extensions` | Missing/null → {}; arbitrary nonempty string keys and recursively JSON-safe scalar/list/object values; exported at root. | `744–749,794–824,1170–1200`, invalid_section/key/json_value. |

Zone fixed-pixel bounds/defaults (`schema.py:35–43,609–620`):

| Zone | Inclusive size bounds | Default size/visible/collapsed |
| --- | --- | --- |
| top_ribbon | 40–140 |84 / true / false|
| left_rail |120–360|300 / true / false|
| right_inspector |140–420|276 / true / false|
| bottom_workbench |90–260|156 / true / false|
| left_player_bench |140–380|240 / true / false|
| right_opponent_bench |140–380|240 / true / false|
| bottom_command_bench |120–320|220 / true / false|

Registry source is `preferences/registries.py` in full. Active overlays: selected_model,
selected_unit, debug_coordinates, movement_budget, movement_path_draft. Planned overlays:
objective_control_context, engagement_range, coherency, line_of_sight, cover. Known planned
settings: hud.minimap_enabled, input.keyboard_first_mode, movement.auto_path_preview,
render.cached_text_objects, selection.history_limit. All remain preserved/inactive.

Commands: toggle_overlay, open_selected_unit_actions, toggle_measure_mode, confirm, cancel,
cycle_selection, add_entity_selection, subtract_entity_selection, toggle_entity_selection,
cycle_entity_layer, select_current_entity_group, toggle_action_summary, review_action_summary.
**Registry-active is not execution proof**: toggle_measure_mode is accepted and default-bound to R
(`defaults.py:16–76`) but has no branch in `ArcadeWarhammerWindow.on_key_press:923–1053`.
Record this as a baseline no-op/defect, not a working free-form measurement mode to preserve.
Other commands have explicit window branches. Configuration never supplies legal decisions.

Preference I/O diagnostics (`preferences/io.py:57–112,144–208,240–277`): explicit missing file,
unsupported extension, read failure and JSON/YAML parse errors are typed errors. Missing platform
default uses packaged default; a present malformed/stale default is not silently ignored.
JSON/YAML export shares `UiPreferences.to_payload` (`schema.py:233–245`) and emits stable semantic
values through orjson or safe_dump. Comments, anchor spelling and original document formatting
are not represented in the typed profile. See existing tests `test_preferences.py:33–407`.

## HUD composition schema and complete accepted widget attributes

Source: `hud/composition.py:37–55,235–288,385–1113` and `hud/toolkit.py:620–868`.
Root fields: schema_version (string1 or integer1), profile_id required nonempty string,
layout_preset required compass_ring/command_bench, optional theme default default,
regions object; preview alone allows sample_data. Each region has only widget. Each widget
has required type/id, optional icon_id/data_ref/layout/children plus whitelisted attributes.
Children absent/null → no children; provided children must be list.

Common accepted attributes for **every** widget: alignment, alpha, background_alpha,
border_alpha, border_color_role, border_width, clip_children, color_role, debug_label_visible,
density, fill_color_role, height, icons, aspect_ratio, max_width, max_height, min_width,
min_height, opacity, overflow, padding, scroll, shape, state, slots, text, tooltip_key, width,
z_order. This whitelist is schema acceptance, not a claim every attribute changes rendering.

| Widget | Additional accepted attributes |
| --- | --- |
| HudContainer |anchor,gap,max_size,min_size,offset,rect,render_mode,scroll_policy,size_policy|
| HudPanel |collapse_state,collapsed_size,content_gap,footer_visible,header_visible,subtitle,title,title_padding|
| IconSlot |badge_text,fallback_glyph,icon_size,shape,size|
| IconTextBar |height,hotkey_hint,icon_side,icon_size,primary_label,secondary_label,text_alignment,truncation_policy,underline_style,value_text|
| StatusChip |diameter_px,icon_id,label,preserve_aspect_ratio,progress_fraction,size_px,value|
| EntityChip |badge_count,compact_mode,display_label,entity_ref,expanded_mode,warning_marker|
| DonutGauge |background_ring_alpha,center_icon_id,gap_between_segments,inner_diameter,label_text,outer_diameter,progress_fraction,segment_count,start_angle,sweep_angle|
| UnitRailCard |activation_state,compact,expanded,model_count_summary,short_label,status_summary,unit_label|
| DatasheetHeader |badges,collapse_control_visible,faction_icon_id,status_chips,subtitle,title|
| DatasheetPanel |ability_zone_visible,comparison_mode,debug_source_fields_visible,footer_action_row_visible,keyword_zone_visible,stat_cell_gap,stat_cell_height,stat_cell_min_width,stat_zone_visible,title,weapon_zone_visible,zone_order|
| StatStrip |cells,columns,stat_labels,stat_values|
| StatCell |delta_state,emphasis_state,icon_id,label,value|
| MissionCard |card_type,compact,expanded,owner_color_role,progress_chips,reveal_state,score,subtitle,title|
| ActionButton |command_id,confirmation_required,disabled_reason,enabled,hotkey_hint,icon_side,label|
| CurrentActionPanel |button_gap,button_height,button_min_width,max_buttons_per_row,button_shape,cancel_hint,confirm_hint,max_buttons,show_actor,show_request,title|
| StratagemButton |cp_cost_badge,eligibility_state,hotkey_hint,phase_badge,target_summary,title|
| AssignmentGroupRow |button_gap,button_height,button_shape,detailed,expanded,group_label,operation_kind,source_entity_chips,summary_lines,target_entity_chips|
| DicePipeline |compact,current_step,dice_pool_summaries,history_visible,modifier_chips,pipeline_steps|
| DiceTray |bucket_label,compact,count_only_threshold,dice_face_asset_ids,face_icon_size,history_visible,max_visible_dice_per_face,show_source,title|
| PlayerUnitsRoster |button_gap,button_height,button_min_width,button_shape,max_visible_rows,status_icon_text,subtitle,title|
| Tooltip |body,title|
| Separator |orientation|

Layout (`composition.py:569–647`): optional layout defaults stack/vertical/stretch, columns1,
gap_px8, padding_px8. Kinds stack/grid/anchor/overlay; orientations vertical/horizontal;
alignment start/center/end/stretch; columns exact integer1–12. Invalid kind/orientation/alignment
errors. **Current permissive exceptions:** wrongly typed optional values may revert to default
without diagnostic through `_optional_string/int/float` (`1049–1074`); gap/padding floats have
no nonnegative/finiteness guard here. Advanced anchor/overlay remains limited; grid equal cells.

Size forms (`toolkit.py:1025–1056`): exact numeric int/float → px, strings px, percent≤100,
fr>0, fill, auto, fit-content/fit_content; whitespace around whole string stripped.
Negative invalid; zero px/percent accepted. Min/max pairs compare only when **both** normalize to
pixels (`composition.py:724–777`), not arbitrary mixed-unit contradictions. Aspect ratio accepts
positive number or positive `a:b` string (`780–807`). Finite-value guard is incomplete.

Overflow (`toolkit.py:1059–1084`): string mode or object; modes clip/ellipsis/wrap/shrink_to_fit/
scroll/visible; defaults ellipsis,max_lines1,min_font_size_px10,preserve_icon true,debug_bounds false.
Scroll (`1087–1136`): Boolean, axis string or object; defaults disabled,y,wheel y,scrollbars auto,
step48,drag false,clamp true. Axes x/y/both; wheel x/y/auto; scrollbars never/auto/always;
wheel step>0; drag_scrollbars is accepted but not implemented.
StatusChip shape (`1139–1181`): string or object; round/square/rounded_rect/pill;
default rounded_rect; optional diameter/size, corner radius0, preserve_aspect true,
content_alignment center or start/end/stretch. Rounded/pill currently use generic labelled boxes.
Nested overflow/scroll/shape unknown subkeys are **not** diagnosed by these parser functions;
do not claim a recursive unknown-key ban. text/icons/slots must be objects; most other accepted
widget attributes are JSON-safe values without field-specific parser validation.

Safe data_ref names (`toolkit.py:979–1014`): active_player,assignment_groups,command_points,
current_action,current_assignment,debug_status,hud.selected_unit.card,hud.selected_unit.rows,
hud.status_chips,hud.status_chips.active_player,hud.status_chips.pending,hud.status_chips.phase,
hud.workbench.actions,hud.workbench.assignments.groups,hud.workbench.assignments.notices,
hud.dice_tray.active,hud.workbench.review.diagnostics,hud.workbench.review.events,
hud.workbench.review.hotkeys,hud.player_units.roster,mission_summary,movement_budget,dice_tray,
opponent_roster,phase_state,player_roster,selected_model,selected_unit,selection_status.
Runtime missing data is absent display data, not permission to inspect raw core payloads.

Icon IDs are the exact whitelist in `toolkit.py:936–977`, including six dice.aeldari.d6.face_N
IDs; they resolve to placeholders in current rendering. Unknown top-level icon_id and data_ref
diagnose errors. Internal arbitrary attribute strings are not all checked as registry references.
theme is stored as a nonempty string or default, but source search found no consumption of
`profile.theme`; runtime uses the supplied ergonomic theme and preview uses CLI theme
(`arcade_window.py:615`, `hud/preview.py:109–116`, `toolkit_render.py:99`). Preserve the value
without pretending general named-theme selection is implemented.

Composition diagnostics are errors: invalid_document/regions/section/key/string/children;
invalid_schema_version/unsupported_schema_version; invalid_layout_preset/kind/orientation/
alignment/columns; unknown_key/widget_type/widget_attribute/icon_id/data_ref; unsafe_include;
invalid_size_spec/size_constraint/aspect_ratio/overflow_policy/scroll_config/status_chip_shape/
widget_mapping/json_value; production_sample_data_not_allowed and missing_sample_data.
Read/path/parse/load and missing-composition diagnostics are separately typed in
`composition.py:125–213,292–356`. A returned profile is none if any error. Preview requires a
sample_data entry **for each used data_ref**, not an unconditional nonempty sample block.

Native compatibility corpus must include all packaged four preference profiles, both HUD profiles,
all four docs/hud/examples, and existing invalid/reference/preview/overflow/scroll/scissor tests.
Preserve meaningful values and intentionally inactive fields. Schema acceptance and generic
fallback rendering are separate inventory columns for later normalized-tree/render acceptance.

## Actual YAML loader semantics from installed primary source

The inspected UI environment contains PyYAML **6.0.3** (`.venv/Lib/site-packages/pyyaml-6.0.3.dist-info/
METADATA:2–3`), matching `uv.lock:633–634`. Application code explicitly calls `yaml.safe_load`
(`preferences/io.py:255–267`; `hud/composition.py:149,314`). This dispatches to **SafeLoader**,
not CSafeLoader (`yaml/__init__.py:117–125`), whose constructor includes SafeConstructor+Resolver
(`yaml/loader.py:31–40`). The inspected ignored installation is identified by SHA256:

| File beneath `.venv/Lib/site-packages/yaml/` | SHA256 |
| --- | --- |
| __init__.py |b19dfcc333d6a75dfd73073901164507252f271b41d3b5f7d85510033a0547a7|
| loader.py |5156becc8aa6905482218abf3e04869b835226db4763645fff3438fdbd5f1cdd|
| constructor.py |90d8247da78b524c10618fd0e857f54f3d97570fe91b5c5513d024ef3faf88b0|
| composer.py |fcaa37d16afa783594794a5ab94193dcb720f503c19ce3d59539c8311189f453|
| resolver.py |f4bf9561f9b89961f1503d558385fbae30d12bfed565de9bf76c33abb63620a6|

These conclusions come from source, with no newly executed parsing examples:

| YAML feature | Loader behavior and application boundary |
| --- | --- |
| Single document | `composer.py:29–48` rejects a second document; empty input gives none, transformed to{} by preference loader then schema-validated. |
| Anchors/aliases | `composer.py:63–96` resolves existing aliases; undefined alias and duplicate anchor errors. Aliases are not banned by app. Typed normalization/export preserves semantic values, not alias spelling. |
| Merge keys | `resolver.py:195–198`, `constructor.py:180–218` support `<<` map/sequence merging, flatten before ordinary mapping; explicit keys override merged entries. Merge sequence precedence is the loader's reverse/append order, so native normalization needs a matching corpus. |
| Duplicate mapping keys | `constructor.py:132–145` uses `mapping[key]=value` with no duplicate rejection: later equal key wins. A native parser that errors here changes tolerated input and must report an explicit import disposition. |
| Boolean/null resolution | `resolver.py:170–175,200–205` resolves plain yes/no/on/off and true/false spellings to Boolean, and null/Null/NULL/~ or empty scalar to none. Exact-type schema then accepts Boolean only in Boolean fields; quoted strings remain strings. |
| Numbers | `resolver.py:177–193`, `constructor.py:237–293` support binary, leading-zero octal, hex, sexagesimal and underscored numbers, floating .inf/.nan forms. Schema uses exact types and range checks, not general JSON lexical equivalence. |
| Timestamp/binary/set/pairs/omap | Safe constructors exist (`constructor.py:294–480`). Their date/datetime/bytes/set/tuple-containing results fail app JSON-safe value checks or exact known-field types; these are not general supported profile data types. |
| Custom/unsafe tags | SafeConstructor undefined tag raises ConstructorError (`426–430,479–480`); Python object constructors belong to Full/Unsafe constructors and are not selected. Application catches YAMLError as a typed YAML parse diagnostic. |
| Non-string keys | YAML may construct hashable scalar keys; application root/widget/extension validation requires nonempty string keys and reports errors. Unhashable YAML keys fail constructor first. |
| Cycles/depth/size | Composer supports aliases and app recursively copies/converts lists/maps without visited/depth/size budget (`schema.py:1170–1200`, `composition.py:947–984`). No application input cap or cycle diagnostic was found. This is a source-derived hardening gap; no adversarial probe or runtime outcome is claimed. |
| Non-finite values | `_required_float` and JSON-safe scalar checks accept float type; many checks compare< or> without isfinite (`schema.py:894–914,1175`; `toolkit.py:1028–1055,1274–1298`). Infinity fails some bounded fields but not all sizes/extension values; NaN can evade comparisons. Treat intended JSON-safe/fail-visible behavior as the invariant; do not preserve this defect as a required native parser feature. |

No claim is made that a YAML1.2 C++ parser automatically matches this resolver. Finish the
immutable native-parser choice/toolchain review separately, then E04 must compare the supported
semantic corpus, diagnostic severity and all intentionally documented import hardening changes.

## Remaining source and execution work

RQ07 now has an explicit36-row capability checklist and complete97-case baseline catalogue,
including nested requests, accepted editor subvariants and typed unsupported paths. Remaining
source work is to apply the selected44.3.33 delta and finish per-case fixture/procedure identities
where table rows explicitly name unverified dedicated coverage. The catalogue does not establish
that every rules-source combination is reachable or that partial editors have complete controls.

RQ11 now has the complete preference fields, registry IDs, composition attribute whitelist,
diagnostic structure and source-backed YAML handling. Remaining source design is the target native
normalization/conversion mapping and per-attribute render/inactive disposition; E04 remains actual
native round-trip/layout/render proof. Do not close whole RQ07/RQ11 solely from this report.
No tests passed/failed because none were run. No owner answer, compatibility result or empirical
success was inferred; no application/test/core source was edited.
