# Latest Core capabilities — supporting source inventory

**Later runtime status:** this source inventory was captured during P1b. The separate [P1c adoption](../evidence/2026-10-24-p1c-core-adoption.md) subsequently prepared/verified the same exact4f9 /44.5.0 source. Earlier44.3 evidence below remains historical and is not relabelled. The canonical plan owns current status.

Research date: 2026-10-24. This document supports the [single canonical migration plan](../unreal-migration-plan.md); it does not set a second roadmap, accept a runtime upgrade, or claim complete gameplay. Its scope is the latest supported public Core capabilities, including work beyond the owner-confirmed Arcade baseline. The [CAP01–36 checklist](2026-10-16-capability-checklist.md) remains the UI/product reference rather than the ceiling for Core coverage.

Method: read-only Git-object, schema, catalogue, source and test-definition inspection. No Core/Arcade files or environments were changed; no imports, generators, tests, servers, clients or review sessions were run for this inventory. The latest development candidate is unmerged; current Unreal runtime evidence remains bound to Core 44.3.33.

## Frozen comparison subjects

| Role | Exact Core commit | Declared external contract | Meaning |
|---|---|---|---|
| Arcade compatibility baseline | `fc12fa214642f1b1f2a31b56be7323b7d76dbebc` | 44.1.0 | Historical Python client pin, not the target ceiling. |
| Currently tested Unreal runtime / fetched main | `5f509724da25a2f6ded0c2739a8e7c84bdf59c91` | 44.3.33 | Existing runtime/evidence identity; checkout remains here. |
| Latest fetched development source | `4f9bef0df2fb974d1285232a1009b8781926361d` | 44.5.0 | `origin/codex/static-successor48`, open unmerged Core PR #591; planning candidate, not released main or a runtime already exercised by Unreal. |

The recorded remote fetch identities are: main observed at 2026-10-24T16:42:14Z; development branch at 16:43:22Z, 73 commits ahead of tested main. All candidate reads here use `git show`/`git grep`/`git ls-tree` at that exact commit, without checkout. Contract versions and counts below were independently read from the three Git objects.

## Public decision inventory: small family delta, larger semantic delta

Source for every count: `contracts/manifest.json` and `contracts/examples/decisions/family-coverage.json` at the respective exact commit.

| Inventory field | 44.1.0 | 44.3.33 | Development 44.5.0 |
|---|---:|---:|---:|
| Family rows / known external tokens | 87 | 88 | 89 |
| Registered rows | 85 | 86 | 87 |
| Nested rows | 1 | 1 | 1 |
| Redaction-only rows | 1 | 1 | 1 |
| Finite submissions | 73 | 74 | 75 |
| Parameterized submissions | 13 | 13 | 13 |
| Not-submittable placeholder | 1 | 1 | 1 |
| `envelope_only` / `live_scenario` | 82 / 4 | 83 / 4 | 84 / 4 |
| Declared standard interaction kinds / kinds used by family rows | 13 / 11 | 13 / 11 | 13 / 11 |

`hidden_decision` is the non-submittable redaction placeholder. `quantity_selection` and `roster_construction` are declared standard interaction kinds but occur in no family row at any of these three revisions. Declaration, schema parsing and envelope coverage do not establish a reachable public editor or complete game. The four `live_scenario` labels are fixture metadata, not tests rerun for this inventory.

The only added family from Arcade to tested Core is `select_source_reposition` (existing `opportunity_window`). The only added family from tested to development Core is `select_coherency_casualty` (existing `entity_selection`, finite, `envelope_only`); no family token was removed. Development `engine/interaction_metadata.py:142` adds the mapping; `engine/coherency_cleanup_decisions.py:42,128,157,200` defines request, cleanup, result application and restore validation. `contracts/migrations/44.3.33-to-44.4.0.md:1–19` binds actor, physical-model choices, current geometry/group drift and per-casualty cleanup; it does not add an artifact converter.

The development OpenAPI retains the same 16 HTTP path keys and component-schema names as tested Core. That is not wire equivalence: `game-view.schema.json`, examples, source and contract version changed. Track fields/constraints and semantics, not endpoint counts alone.

## Complete 89-family catalogue and current Unreal disposition

Rows preserve source order and literal interaction/submission/coverage/scope fields in [development family-coverage.json](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/contracts/examples/decisions/family-coverage.json). Baseline presence compares tokens only. Core coverage is fixture metadata, not current Unreal verification.

Unreal codes describe the current live client on the tested 44.3.33 runtime: **R** = one real `select_secondary_missions` choice and authoritative refresh verified, not all options or the 44.5 runtime. **G** = generic offered finite-option controls exist for player-a; this individual family/editor is not runtime-verified. **P** = parameterized editor/submission unsupported. **H** = hidden redaction placeholder, never submit. G does not establish specialized dice, ordering, entity or weapon-matrix usability. A different actor never becomes a player-a mutation.

Basis: [LiveCoreSession.cpp](../../../Source/WarhammerClient/Private/LiveCore/LiveCoreSession.cpp), ReadProjection actor/is_parameterized gating; [real visible choice](../evidence/2026-10-24-live-core-camera-visible.md); [packaged checks](../evidence/2026-10-24-p1a-windows-package.md). No new runtime result is claimed.

| Decision family | Interaction kind(s) | Submission | Core coverage | Registry scope | In 44.1 | In 44.3.33 | Unreal |
|---|---|---|---|---|---|---|---|
| `discard_tactical_secondary_mission` | confirmation | finite | envelope_only | registered | Yes | Yes | G |
| `draw_tactical_secondary_missions` | confirmation | finite | envelope_only | registered | Yes | Yes | G |
| `hidden_decision` | — | not_submittable | redaction_only | redaction | Yes | Yes | H |
| `replace_tactical_secondary_mission` | confirmation | finite | envelope_only | registered | Yes | Yes | G |
| `resolve_fight_interrupt` | opportunity_window | finite | envelope_only | registered | Yes | Yes | G |
| `resolve_reaction_window` | opportunity_window | finite | envelope_only | registered | Yes | Yes | G |
| `resolve_sequencing_order` | ordered_sequencing | finite | envelope_only | registered | Yes | Yes | G |
| `resolve_tactical_secondary_when_drawn` | finite_option_list | finite | envelope_only | registered | Yes | Yes | G |
| `score_tactical_secondary_mission` | confirmation | finite | envelope_only | registered | Yes | Yes | G |
| `select_allocation_order` | ordered_sequencing | finite | envelope_only | registered | Yes | Yes | G |
| `select_attack_weapon_group` | weapon_allocation_matrix | finite | envelope_only | registered | Yes | Yes | G |
| `select_beacon_unit` | entity_selection | finite | envelope_only | registered | Yes | Yes | G |
| `select_burden_of_trust_guard` | finite_option_list | finite | envelope_only | registered | Yes | Yes | G |
| `select_catalog_any_phase_once_per_battle_ability` | opportunity_window | finite | envelope_only | registered | Yes | Yes | G |
| `select_catalog_movement_end_target_effect` | entity_selection | finite | envelope_only | registered | Yes | Yes | G |
| `select_catalog_movement_target_pair` | finite_option_list | finite | envelope_only | registered | Yes | Yes | G |
| `select_catalog_post_fight_hit_target_effect` | entity_selection | finite | envelope_only | registered | Yes | Yes | G |
| `select_catalog_post_shoot_hit_target_effect` | entity_selection | finite | envelope_only | registered | Yes | Yes | G |
| `select_catalog_post_shoot_hit_target_status` | entity_selection | finite | envelope_only | registered | Yes | Yes | G |
| `select_catalog_setup_reactive_shoot_charge` | opportunity_window | finite | envelope_only | registered | Yes | Yes | G |
| `select_catalog_unit_move_completed_mortal_wounds_target` | entity_selection | finite | envelope_only | registered | Yes | Yes | G |
| `select_charge_declaration_grant` | opportunity_window | finite | envelope_only | registered | Yes | Yes | G |
| `select_charge_targets` | finite_option_list | finite | envelope_only | registered | Yes | Yes | G |
| `select_charging_unit` | entity_selection | finite | envelope_only | registered | Yes | Yes | G |
| `select_coherency_casualty` | entity_selection | finite | envelope_only | registered | No | No | G |
| `select_core_ability_instance` | finite_option_list | finite | envelope_only | registered | Yes | Yes | G |
| `select_cult_ambush_resurgence` | confirmation | finite | envelope_only | registered | Yes | Yes | G |
| `select_damage_allocation_model` | entity_selection | finite | envelope_only | registered | Yes | Yes | G |
| `select_deployment_unit` | entity_selection | finite | envelope_only | registered | Yes | Yes | G |
| `select_desperate_escape_model` | entity_selection | finite | envelope_only | registered | Yes | Yes | G |
| `select_destruction_reaction` | opportunity_window | finite | envelope_only | registered | Yes | Yes | G |
| `select_dice_extremum` | dice_selection | finite | envelope_only | registered | Yes | Yes | G |
| `select_dice_reroll` | dice_selection | finite | envelope_only | registered | Yes | Yes | G |
| `select_dice_result_override` | dice_selection | finite | envelope_only | registered | Yes | Yes | G |
| `select_embark_transport` | entity_selection | finite | envelope_only | registered | Yes | Yes | G |
| `select_faction_rule_battle_round_option` | opportunity_window | finite | envelope_only | registered | Yes | Yes | G |
| `select_faction_rule_command_phase_start_option` | opportunity_window | finite | envelope_only | registered | Yes | Yes | G |
| `select_faction_rule_fight_phase_end_option` | opportunity_window | finite | envelope_only | registered | Yes | Yes | G |
| `select_faction_rule_fight_phase_start_option` | opportunity_window | finite | envelope_only | registered | Yes | Yes | G |
| `select_faction_rule_setup_option` | opportunity_window | finite | envelope_only | registered | Yes | Yes | G |
| `select_faction_rule_shooting_phase_start_option` | opportunity_window | finite | envelope_only | registered | Yes | Yes | G |
| `select_faction_rule_turn_end_option` | opportunity_window | finite | envelope_only | registered | Yes | Yes | G |
| `select_feel_no_pain` | finite_option_list | finite | envelope_only | registered | Yes | Yes | G |
| `select_fight_activation` | entity_selection | finite | envelope_only | registered | Yes | Yes | G |
| `select_fight_activation_ability` | opportunity_window | finite | envelope_only | registered | Yes | Yes | G |
| `select_fight_unit_grant` | opportunity_window | finite | envelope_only | registered | Yes | Yes | G |
| `select_healing_model` | entity_selection | finite | envelope_only | registered | Yes | Yes | G |
| `select_lethal_hit_wound` | confirmation | finite | envelope_only | registered | Yes | Yes | G |
| `select_melee_weapon` | finite_option_list | finite | envelope_only | registered | Yes | Yes | G |
| `select_modifier_ignores` | finite_option_list | finite | envelope_only | registered | Yes | Yes | G |
| `select_mortal_wound_model` | entity_selection | finite | envelope_only | registered | Yes | Yes | G |
| `select_movement_action` | finite_option_list | finite | live_scenario | registered | Yes | Yes | G |
| `select_movement_action_grant` | opportunity_window | finite | envelope_only | registered | Yes | Yes | G |
| `select_movement_unit` | entity_selection | finite | live_scenario | registered | Yes | Yes | G |
| `select_post_roll_attack_pool` | ordered_sequencing | finite | envelope_only | registered | Yes | Yes | G |
| `select_prebattle_action` | finite_option_list | finite | envelope_only | registered | Yes | Yes | G |
| `select_precision_allocation` | entity_selection | finite | envelope_only | registered | Yes | Yes | G |
| `select_primary_mission_choice` | finite_option_list | finite | envelope_only | registered | Yes | Yes | G |
| `select_psychic_attack_modifier_ignores` | finite_option_list | finite | envelope_only | registered | Yes | Yes | G |
| `select_redeploy_unit` | entity_selection | finite | envelope_only | registered | Yes | Yes | G |
| `select_reserve_declaration` | finite_option_list | finite | envelope_only | registered | Yes | Yes | G |
| `select_resolve_target_unit` | entity_selection | finite | envelope_only | registered | Yes | Yes | G |
| `select_secondary_missions` | finite_option_list | finite | live_scenario | registered | Yes | Yes | R |
| `select_shooting_type` | finite_option_list | finite | envelope_only | registered | Yes | Yes | G |
| `select_shooting_unit` | entity_selection | finite | envelope_only | registered | Yes | Yes | G |
| `select_shooting_unit_grant` | opportunity_window | finite | envelope_only | registered | Yes | Yes | G |
| `select_source_reposition` | opportunity_window | finite | envelope_only | registered | No | Yes | G |
| `select_stratagem_cost_modifier_option` | confirmation | finite | envelope_only | registered | Yes | Yes | G |
| `select_target_replacement` | finite_option_list | finite | envelope_only | registered | Yes | Yes | G |
| `select_tempting_target_objective` | finite_option_list | finite | envelope_only | registered | Yes | Yes | G |
| `select_tracked_target` | entity_selection | finite | envelope_only | registered | Yes | Yes | G |
| `select_triggered_movement` | opportunity_window | finite | envelope_only | registered | Yes | Yes | G |
| `select_unit_split_membership` | finite_option_list | finite | envelope_only | registered | Yes | Yes | G |
| `select_weapon_ability_instance` | finite_option_list | finite | envelope_only | nested | Yes | Yes | G |
| `start_mission_action` | opportunity_window | finite | envelope_only | registered | Yes | Yes | G |
| `submit_catalog_model_materialization_placement` | multi_model_placement | parameterized | envelope_only | registered | Yes | Yes | P |
| `submit_cult_ambush_marker_placement` | battlefield_point_placement, confirmation | parameterized | envelope_only | registered | Yes | Yes | P |
| `submit_deployment_placement` | multi_model_placement | parameterized | envelope_only | registered | Yes | Yes | P |
| `submit_healing_revival_placement` | model_pose_placement | parameterized | envelope_only | registered | Yes | Yes | P |
| `submit_melee_declaration` | weapon_allocation_matrix | parameterized | envelope_only | registered | Yes | Yes | P |
| `submit_movement_proposal` | path_editor | parameterized | live_scenario | registered | Yes | Yes | P |
| `submit_placement_proposal` | multi_model_placement | parameterized | envelope_only | registered | Yes | Yes | P |
| `submit_redeploy_placement` | multi_model_placement | parameterized | envelope_only | registered | Yes | Yes | P |
| `submit_return_on_death_placement` | model_pose_placement | parameterized | envelope_only | registered | Yes | Yes | P |
| `submit_scout_move` | path_editor | parameterized | envelope_only | registered | Yes | Yes | P |
| `submit_scout_reserve_setup` | multi_model_placement | parameterized | envelope_only | registered | Yes | Yes | P |
| `submit_shooting_declaration` | weapon_allocation_matrix | parameterized | envelope_only | registered | Yes | Yes | P |
| `submit_stratagem_target_proposal` | entity_selection | parameterized | envelope_only | registered | Yes | Yes | P |
| `use_stratagem` | opportunity_window | finite | envelope_only | registered | Yes | Yes | G |

Family names are not the complete editor inventory: proposal kinds and nested/submission variants share them. Expand with the [submission catalogue](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/docs/DECISION_SUBMISSION_CATALOG.md), [interaction metadata](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/src/warhammer40k_core/engine/interaction_metadata.py) and [interaction-conformance data](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/contracts/examples/decisions/interaction-conformance.json). Preserve unsupported reasons.

## All 16 declared HTTP paths

Source: [OpenAPI 3.1](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/contracts/openapi.yaml). Groups describe declared backend roles, not production hosting readiness or shipped UI. The live client uses authoritative session commands; legacy game operations are not a proposed alternate authority. Operator-only persistence/recovery and historical reconstruction APIs are not inferred HTTP routes.

| Group | HTTP path key | Method | Declared operationId |
|---|---|---|---|
| Presentation / shared catalogue | `/rules-catalog` | GET | `getRulesCatalog` |
| Legacy lifecycle backend | `/games` | POST | `createLegacyGame` |
| Legacy lifecycle backend | `/games/{game_id}/advance` | POST | `advanceLegacyGame` |
| Presentation / legacy projection | `/games/{game_id}/view` | GET | `getLegacyGameProjection` |
| Presentation / legacy events | `/games/{game_id}/events` | GET | `getLegacyGameEvents` |
| Backend replay export | `/games/{game_id}/replay` | GET | `exportLegacyGameReplay` |
| Presentation / support disclosure | `/games/{game_id}/support-profile` | GET | `getLegacyGameSupportProfile` |
| Legacy finite mutation backend | `/games/{game_id}/decisions/{request_id}/option` | POST | `submitLegacyFiniteDecision` |
| Legacy parameterized mutation backend | `/games/{game_id}/decisions/{request_id}/payload` | POST | `submitLegacyParameterizedDecision` |
| Authoritative lifecycle | `/sessions` | POST | `createAuthoritativeSession` |
| Authoritative metadata | `/sessions/{session_id}` | GET | `getSessionMetadata` |
| Authoritative mutation / reconciliation | `/sessions/{session_id}/commands` | POST | `executeSessionCommand` |
| Presentation / viewer projection | `/sessions/{session_id}/projection` | GET | `getSessionProjection` |
| Presentation / session catalogue | `/sessions/{session_id}/catalog` | GET | `getSessionCatalog` |
| Presentation / cursor events | `/sessions/{session_id}/events` | GET | `getSessionEvents` |
| Backend replay export | `/sessions/{session_id}/replay` | GET | `exportSessionReplay` |

Authorization, role-bound cursors/resynchronization, exact IDs/revisions and unknown-outcome handling still apply. Declarations do not prove credential provisioning, persistent deployment, spectator join, reconnect UX, release security or full-game service. See [session semantics](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/contracts/session-semantics.md), [redaction policy](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/contracts/redaction-policy.md) and [compatibility policy](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/contracts/compatibility-policy.md).

## Concrete development changes the UI inventory must include

All references in this section use `Warhammer_40k_AI@4f9bef0...` unless labelled otherwise. Python paths beginning `engine/` or `adapters/` abbreviate the exact Git prefix `src/warhammer40k_core/`; `docs/`, `contracts/`, `data/` and `tests/` are repository-root paths. The same Python prefix convention applies below.

| Change | Public consumption / precise evidence |
|---|---|
| Public roster disclosure, contract 44.5 | `docs/ADAPTER_DECISION_CONTRACT.md:3–22`; `adapters/projection.py:310` (`GameViewPayload.public_army_rosters`) and `project_game_view` roster assignment at 576; `adapters/redaction.py:73` (`public_army_roster_payload`). Preserve selected faction/detachment/options/points/Warlord/Enhancement and physical bearer joins. Attachments/cargo remain null to unauthorized viewers before reveal. This is projection data, not a new mutation route. |
| Coherency casualty choice, contract 44.4 | Adapter contract `36–52`, the migration above, and `coherency_cleanup_decisions` symbols. Present actual offered physical-model choices through existing finite submission, then refresh the authoritative result. Do not choose casualties locally. |
| Delayed secondary Action completion | Adapter contract `24–34`; existing `resolve_sequencing_order` and `score_tactical_secondary_mission` families acquire source-backed contexts. `tests/rules/section16/test_facade.py:18,69,104,135` documents public Action start, revalidation and completion tests; source presence is not a new Unreal result. |
| Attack model-versus-unit completion | Adapter contract `55–66`: unchanged family names carry repaired completion timing/history. New internal completion evidence is explicitly redacted (`adapters/redaction.py`, `_event_record_hidden_from_context`). Never expose internal evidence merely because it appears in engine history. |
| Pre-session roster creation is an existing public input path | Adapter contract `477–530`: `PlayerArmyList` → `army_muster_request_from_player_army_list` → strict `ArmyMusterRequest` → `GameConfig`. `engine/army_mustering.py:639,848,1103,1209` defines request, result, muster and legality. Preserve ordered units, exact MFM price identity, dispositions, physical bearer identities and sparse reviewed geometry; no inferred measurements, balances or faction legality. New UI roster authoring can exceed Arcade's display-only CAP11 while using this path. |
| Exact historical checkpoint reconstruction | `adapters/checkpoint_reconstruction.py:53,105`; `docs/A32_HISTORICAL_CHECKPOINT_RECONSTRUCTION.md:1–38`. One exact profile/source artifact is supported. This is not general cross-version save migration or an HTTP recovery endpoint; ordinary persistence/replay remains exact-runtime bound. |
| Rules with no new UI request | Changed movement, terrain, attack, death, Battle-shock, reserve, mission and faction consumers must be recorded against projections/events/diagnostics and real public workflows. A changed automatic rule does not require an invented client-side rules path or new button. Source obligations are indexed in `tests/rules/section00` through `section25/coverage.json`; these 26 varied schemas retain limitations and source-to-test mappings rather than a universal gameplay-PASS flag. |

## All 26 rule-section source coverage maps

Links point to the exact development commit, not the local tested checkout. Each file is a source/obligation/owner/test-definition inventory with its own schema and qualifications. Schemas vary, including integer schema 1 in sections 01/02. There is no imposed uniform status/total and no rerun of assertions. Dated README pass/failure counts, metadata authentication and corpus completeness do not establish engine compliance, all-source correctness or Unreal coverage.

| Section | Source topic | Exact coverage map | Declared schema | Test definitions |
|---|---|---|---|---|
| 00 | Universal Rules Updates | [coverage.json](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section00/coverage.json) | `section00-complete-literal-and-behavior-inventory-v1` | [section00](https://github.com/SobolGaming/Warhammer_40k_AI/tree/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section00) |
| 01 | Armies, units/models, effects, measurement, dice and Battle-shock | [coverage.json](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section01/coverage.json) | `1` | [section01](https://github.com/SobolGaming/Warhammer_40k_AI/tree/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section01) |
| 02 | Datasheets, modifiers, abilities, keywords, equipment and options | [coverage.json](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section02/coverage.json) | `1` | [section02](https://github.com/SobolGaming/Warhammer_40k_AI/tree/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section02) |
| 03 | Movement, setup, coherency and engagement | [coverage.json](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section03/coverage.json) | `section03-semantic-map-v1` | [section03](https://github.com/SobolGaming/Warhammer_40k_AI/tree/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section03) |
| 04 | Making attacks, weapons, targets, split attacks and completion | [coverage.json](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section04/coverage.json) | `section04-semantic-map-v1` | [section04](https://github.com/SobolGaming/Warhammer_40k_AI/tree/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section04) |
| 05 | Attack sequence, allocation, damage and destruction | [coverage.json](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section05/coverage.json) | `section05-semantic-map-v1` | [section05](https://github.com/SobolGaming/Warhammer_40k_AI/tree/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section05) |
| 06 | Visibility, mortal/normal wounds and Hazardous | [coverage.json](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section06/coverage.json) | `section06-semantic-map-v1` | [section06](https://github.com/SobolGaming/Warhammer_40k_AI/tree/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section06) |
| 07 | Battle-round / turn / phase sequencing | [coverage.json](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section07/coverage.json) | `section07-clause-corpus-v1` | [section07](https://github.com/SobolGaming/Warhammer_40k_AI/tree/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section07) |
| 08 | Command Phase | [coverage.json](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section08/coverage.json) | `section08-clause-corpus-v1` | [section08](https://github.com/SobolGaming/Warhammer_40k_AI/tree/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section08) |
| 09 | Movement Phase | [coverage.json](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section09/coverage.json) | `section09-clause-corpus-v1` | [section09](https://github.com/SobolGaming/Warhammer_40k_AI/tree/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section09) |
| 10 | Shooting Phase | [coverage.json](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section10/coverage.json) | `section10-clause-corpus-v1` | [section10](https://github.com/SobolGaming/Warhammer_40k_AI/tree/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section10) |
| 11 | Charge | [coverage.json](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section11/coverage.json) | `section11-clause-corpus-v1` | [section11](https://github.com/SobolGaming/Warhammer_40k_AI/tree/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section11) |
| 12 | Fight | [coverage.json](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section12/coverage.json) | `section12-clause-corpus-v1` | [section12](https://github.com/SobolGaming/Warhammer_40k_AI/tree/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section12) |
| 13 | Terrain | [coverage.json](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section13/coverage.json) | `section13-clause-corpus-v1` | [section13](https://github.com/SobolGaming/Warhammer_40k_AI/tree/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section13) |
| 14 | Objectives | [coverage.json](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section14/coverage.json) | `section14-clause-corpus-v1` | [section14](https://github.com/SobolGaming/Warhammer_40k_AI/tree/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section14) |
| 15 | Stratagems | [coverage.json](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section15/coverage.json) | `section15-source-behavior-inventory-v1` | [section15](https://github.com/SobolGaming/Warhammer_40k_AI/tree/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section15) |
| 16 | Actions | [coverage.json](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section16/coverage.json) | `section16-source-behavior-inventory-v1` | [section16](https://github.com/SobolGaming/Warhammer_40k_AI/tree/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section16) |
| 17 | Monsters And Vehicles | [coverage.json](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section17/coverage.json) | `section17-source-behavior-inventory-v1` | [section17](https://github.com/SobolGaming/Warhammer_40k_AI/tree/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section17) |
| 18 | Transports | [coverage.json](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section18/coverage.json) | `section18-source-behavior-inventory-v1` | [section18](https://github.com/SobolGaming/Warhammer_40k_AI/tree/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section18) |
| 19 | Attached Units | [coverage.json](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section19/coverage.json) | `section19-source-behavior-inventory-v1` | [section19](https://github.com/SobolGaming/Warhammer_40k_AI/tree/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section19) |
| 20 | Strategic Reserves | [coverage.json](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section20/coverage.json) | `section20-source-behavior-inventory-v1` | [section20](https://github.com/SobolGaming/Warhammer_40k_AI/tree/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section20) |
| 21 | Flying and Surging | [coverage.json](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section21/coverage.json) | `section21-source-behavior-inventory-v1` | [section21](https://github.com/SobolGaming/Warhammer_40k_AI/tree/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section21) |
| 22 | Other Rules And Abilities | [coverage.json](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section22/coverage.json) | `section22-source-behavior-inventory-v1` | [section22](https://github.com/SobolGaming/Warhammer_40k_AI/tree/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section22) |
| 23 | Aircraft | [coverage.json](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section23/coverage.json) | `section23-source-behavior-inventory-v1` | [section23](https://github.com/SobolGaming/Warhammer_40k_AI/tree/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section23) |
| 24 | Core Abilities | [coverage.json](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section24/coverage.json) | `section24-complete-literal-and-behavior-inventory-v1` | [section24](https://github.com/SobolGaming/Warhammer_40k_AI/tree/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section24) |
| 25 | Muster Armies | [coverage.json](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section25/coverage.json) | `section25-complete-literal-and-behavior-inventory-v1` | [section25](https://github.com/SobolGaming/Warhammer_40k_AI/tree/4f9bef0df2fb974d1285232a1009b8781926361d/tests/rules/section25) |

Preserve source authority, constructed-input qualifications, cross-section ownership, unadopted gaps, missing semantic assertions and source-expected failures in each map. Do not sum obligations/statuses across schemas without a definition. Read the named production owner and assertion together. Sections 00 and 16 have coverage maps but no README.md at this commit; this table invents none.

### Internal automatic consumers and public exposure gaps

| Capability axis | Exact development source anchors | UI obligation / remaining boundary |
|---|---|---|
| Roster / content admission | [src/warhammer40k_core/engine/army_mustering.py](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/src/warhammer40k_core/engine/army_mustering.py); [docs/SECTION25_MUSTER_ARMIES_SCOPE.md](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/docs/SECTION25_MUSTER_ARMIES_SCOPE.md) | Use strict pre-session input and scoped roster disclosure. Catalog membership or points validation does not make every faction playable. Current Unreal has no roster editor. |
| Movement / placement / geometry | [src/warhammer40k_core/engine/movement_legality.py](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/src/warhammer40k_core/engine/movement_legality.py); [src/warhammer40k_core/engine/charge_move_geometry.py](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/src/warhammer40k_core/engine/charge_move_geometry.py) | Submit Core path/placement proposals and show actual poses/diagnostics. Current Unreal has no parameterized movement/placement editor; previews remain advisory. |
| Combat / damage / completion | [src/warhammer40k_core/engine/model_attack_completion.py](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/src/warhammer40k_core/engine/model_attack_completion.py); [src/warhammer40k_core/engine/attack_sequence_damage_resolution.py](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/src/warhammer40k_core/engine/attack_sequence_damage_resolution.py) | Consume visible choices/results at the proper model/unit boundary. Internal records do not authorize hidden-state display or client damage rules. |
| Missions / Actions / scoring | [src/warhammer40k_core/engine/secondary_mission_action_resolution.py](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/src/warhammer40k_core/engine/secondary_mission_action_resolution.py); [src/warhammer40k_core/engine/mission_turn_end_sequencing.py](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/src/warhammer40k_core/engine/mission_turn_end_sequencing.py) | Present offered starts/sequencing/scoring and public outcomes. Automatic completion adds no invented choice; one secondary selection is not full mission playability. |
| Faction / detachment / RuleIR | [src/warhammer40k_core/engine/faction_content/runtime.py](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/src/warhammer40k_core/engine/faction_content/runtime.py); [src/warhammer40k_core/adapters/capability_manifest_runtime.py](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/src/warhammer40k_core/adapters/capability_manifest_runtime.py) | Distinguish executable consumers from descriptors, placeholders and partial providers. UI buttons cannot supply absent Core execution. |
| Transport / viewer / recovery | [src/warhammer40k_core/adapters/server_sync.py](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/src/warhammer40k_core/adapters/server_sync.py); [src/warhammer40k_core/adapters/session_recovery.py](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/src/warhammer40k_core/adapters/session_recovery.py) | Use scoped events/projections and exact-runtime recovery. Backend definitions do not establish production host, credential UX or general conversion. |

## Stable comparison and tracking method

Maintain one inventory with four related row types, rather than using Arcade's feature list as the Core ceiling:

1. **Public decision/editor rows:** key by `decision_type` + submission kind + proposal kind / submission variant + interaction kind, with actor/viewer constraints. Read `docs/DECISION_SUBMISSION_CATALOG.md`, `engine/interaction_metadata.py:23,131,542`, `contracts/examples/decisions/{family-coverage,interaction-conformance}.json`, typed schemas and each cited public-facade test. One family can have multiple materially different editors (movement, placement, weapon allocation, nested requests).
2. **Public data/service rows:** identity/catalog/mustering, geometry/LOS/query data, state/phase, events/diagnostics, command outcomes, viewer privacy, recovery/persistence/replay. Use `contracts/openapi.yaml`, `contracts/session-semantics.md`, `contracts/redaction-policy.md`, `contracts/coordinate-system.md`, and `adapters/{command_protocol,session_protocol,session_events,server_sync,session_persistence,session_recovery}.py`. Record whether the selected development host actually exposes/operates the API; an operator-only Python API does not establish a usable HTTP product route.
3. **Rule/content rows:** stable source/rule/clause/handler/runtime-consumer IDs, support status and named consuming phase/query. Link `tests/rules/sectionNN/coverage.json` obligations to actual source and named tests; preserve unadopted gaps, unsupported inputs and scope qualifications. Distinguish automatic effects needing faithful presentation from genuine unexposed Core gaps.
4. **UI/product rows:** retain all CAP01–36 from `docs/plans/research/2026-10-16-capability-checklist.md:42–86`, including camera/input, geometry, profiles/HUD, diagnostics, modes, continuity, platforms and performance. Extend Core-facing requirements beyond that baseline. Existing unsupported Arcade forms (Cult Ambush editors, melee split/extra attacks, roster construction) are backlog requirements when Core supports them, not exclusions justified by parity.

For every row retain exact Core commit + path/symbol, public entry/shape, supported/rejected/unsupported status, a reachable public setup recipe or explicit exposure gap, UI implementation status, runtime verification status, and dependency. Keep implementation and verification separate. Diff schema properties/required/nullable/enums/order, proposal variants, source/identity semantics, revision/idempotency/unknown-outcome behavior and redaction, even when family/endpoint/schema-name sets are unchanged.

The comparison can be built read-only from Git objects and JSON. Its next implementation step should be a bounded latest-Core adaptation and real public-session slice, with exact runtime/package/fixture identities selected explicitly. It need not become a new exhaustive certification framework before useful gameplay can proceed. Actual upgrade/build/test/review work must follow the canonical plan; current 44.3.33 evidence is not relabelled 44.5 evidence.

## Supported versus merely present: mandatory qualification

`adapters/capability_manifest.py:77–163` distinguishes loadable, displayable, musterable, physically playable, semantically executable, full-game supported, network safe and replay verified. Its `build_capability_manifest:165` and `project_capability_manifest:314` are source-backed inventories with viewer scoping; definition presence does not assert any selected army satisfies them. `adapters/capability_manifest_runtime.py` separates runtime families and executable statuses.

`docs/ABILITY_SUPPORT_MATRIX_V2.md:18–25,190` separates descriptor-only, compiled unsupported, generic executable, engine-consumed and placeholder/partial/implemented runtime semantics; loadable is not playable. `docs/FACTION_SUPPORT.md:9` expressly does not certify a current full-game faction/roster. Those docs, both capability-manifest sources and `data/generated/ability_coverage/runtime_content_semantic_coverage.json` have identical Git blobs between tested and development Core; do not assume they enumerate all newly repaired consumer behavior. Cross-check new branch source/section obligations and record stale/unspecified exposure as a gap, without inventing faction support or requiring the UI to implement missing rules.

## Reproducible selected identities

| Git path | Tested 5f509 Git blob | Development 4f9 Git blob |
|---|---|---|
| `contracts/manifest.json` | `4d4593a44610e9b4850565ec640abe0abdd9f83a` | `40cf643491a94f08ed3ffc58cc2454d5c8c2ec97` |
| `contracts/examples/decisions/family-coverage.json` | `ad7848163a0f7ea190c0e1f186629cd4c27783d9` | `7db43a193093e0a7a62a91f9610229e61687f919` |
| `contracts/openapi.yaml` | `e8e73f9e3bad2fccba8a3ebb1b42edfe9e2eb11b` | `b4be1d0aad42e7d7532581a4ac9d8067e26c9776` |
| `contracts/schemas/game-view.schema.json` | `125c9dcf2cbe12125a7df1e82a622981a1b4c204` | `a18d377103bd68506538041e322e9619324b5a4e` |

This is a finite supporting source inventory. It does not claim every Core rule/content provider is exposed or supported, any fetched branch is released, any Core test was run, or current Unreal implements all listed capabilities.

## Immutable source navigation

The local sibling remains at `5f509` / 44.3.33; its working paths do not show the candidate. Use these immutable links or `git show 4f9bef0df2fb974d1285232a1009b8781926361d:<exact Git path>` from the Core repository. Python shorthand above expands under `src/warhammer40k_core/`.

- [docs/ADAPTER_DECISION_CONTRACT.md](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/docs/ADAPTER_DECISION_CONTRACT.md)
- [docs/DECISION_SUBMISSION_CATALOG.md](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/docs/DECISION_SUBMISSION_CATALOG.md)
- [contracts/manifest.json](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/contracts/manifest.json)
- [contracts/migrations/44.3.33-to-44.4.0.md](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/contracts/migrations/44.3.33-to-44.4.0.md)
- [contracts/schemas/game-view.schema.json](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/contracts/schemas/game-view.schema.json)
- [src/warhammer40k_core/adapters/projection.py](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/src/warhammer40k_core/adapters/projection.py)
- [src/warhammer40k_core/adapters/redaction.py](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/src/warhammer40k_core/adapters/redaction.py)
- [src/warhammer40k_core/engine/coherency_cleanup_decisions.py](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/src/warhammer40k_core/engine/coherency_cleanup_decisions.py)
- [src/warhammer40k_core/adapters/capability_manifest.py](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/src/warhammer40k_core/adapters/capability_manifest.py)
- [src/warhammer40k_core/adapters/capability_manifest_runtime.py](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/src/warhammer40k_core/adapters/capability_manifest_runtime.py)
- [docs/ABILITY_SUPPORT_MATRIX_V2.md](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/docs/ABILITY_SUPPORT_MATRIX_V2.md)
- [docs/FACTION_SUPPORT.md](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/docs/FACTION_SUPPORT.md)
- [data/generated/ability_coverage/runtime_content_semantic_coverage.json](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/data/generated/ability_coverage/runtime_content_semantic_coverage.json)
- [src/warhammer40k_core/adapters/checkpoint_reconstruction.py](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/src/warhammer40k_core/adapters/checkpoint_reconstruction.py)
- [docs/A32_HISTORICAL_CHECKPOINT_RECONSTRUCTION.md](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/docs/A32_HISTORICAL_CHECKPOINT_RECONSTRUCTION.md)
