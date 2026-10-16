# Contract and external-runtime research, 2026-10-16

This packet supports Section 0 RQ02/RQ03/RQ04/RQ08/RQ09/RQ15/RQ17 of
[the migration plan](../unreal-migration-plan.md). It records source inspection,
not executed conformance, an approved target selection, a portable runtime, or an
authorization to implement. No sibling files, branches, environments, or services
were changed; no dependencies, tests, experiments, or host processes were run.

## Immutable source identities and how to read references

`UI` below expands to
`Warhammer_40k_UI_arcade@5088c1c49dcaff29eb59fb64b3063d30214dde73`.
The owner's `Warhammer_40k_UI` shorthand refers to that legacy client, not a third
checkout. `Core44.1` expands to
`Warhammer_40k_AI@fc12fa214642f1b1f2a31b56be7323b7d76dbebc`; it is the actual UI pin
and the candidate characterized here, not a newly approved Unreal dependency.
`CoreTip` expands to
`Warhammer_40k_AI@5f509724da25a2f6ded0c2739a8e7c84bdf59c91`.
Both sibling worktrees reported clean `git status --porcelain=v1` during inspection.
References use `alias:path:symbol (lines)` and expand to the complete immutable
`repository@commit:path:symbol` form above. Subsequent abbreviated Python paths
`adapters/`, `geometry/` and `core_client/`, `render/`, `state/` are relative to
`src/warhammer40k_core/` in Core and `src/warhammer40k_arcade_ui/` in UI,
respectively; all `contracts/`, `tests/`, `scripts/` and `docs/` paths are
repository-root relative.

The Core44.1 commit object exists locally and was inspected using `git show`,
without moving the sibling checkout. A `git diff --name-only Core44.1 CoreTip --`
comparison returned no changes for adapter `contracts.py`, `server.py`,
`http_transport.py`, `command_protocol.py`, `battlefield_projection.py`,
`access_control.py`, `setup_smoke.py`, `contracts/session-semantics.md`,
`geometry/pose.py`, `geometry/base.py`, `geometry/model_geometry.py`,
`geometry/shapely_backend.py`, both launcher scripts discussed below, and
`pyproject.toml`. Those inspected worktree source bytes can therefore be cited at
Core44.1. The manifest, OpenAPI, external-contract constants and several tests
changed; their Core44.1 versions were read explicitly from Git objects.

| Identity | Source result | Limit |
|---|---|---|
| UI dependency, lock, guard and CI | Core `fc12fa...`, external contract `44.1.0` | `UI:pyproject.toml:tool.uv.sources` 34-35; `uv.lock` 869-871; `core_client/compatibility.py:SUPPORTED_CORE_REVISION` 46-65; `.github/workflows/ci.yml` 17. Not 10.2 or 42.0. |
| UI campaign continuation | Owner-authorized 44.1 continuation recorded 2026-10-02 | `UI:docs/plans/phase-35-core-contract-42-adaptation.md` 5-17; current evidence in `phase-35-contract-44-1-m2-evidence.md`. This is Arcade authority, not a new Unreal target decision. |
| Core44.1 source | External contract `44.1.0` | `Core44.1:src/warhammer40k_core/adapters/external_contract.py:EXTERNAL_CONTRACT_VERSION` 15. |
| Core44.1 runtime identity | `warhammer40k-core-v2:runtime-tree-sha256-v1:7e6f1a71a4ae347f98fa512cbcee8f8c9c03b409cf65c8464b55831daa6c6d54` | `Core44.1:src/warhammer40k_core/_engine_build_manifest.json:build_id` 1-5; 3,043 declared resources. Generated source metadata, not verification of the machine's installed package. |
| Sibling checkout | CoreTip / contract `44.3.33` | `CoreTip:contracts/manifest.json:contract_version` 2. Must not supply 44.1 fixtures without isolation. |
| Existing UI environment | Coordinator found a third installed core revision, `4ee7ccddb03401ddaea20684fdf833ba79f5200f`, in `.venv` distribution provenance | Coordinator's environment packet owns the file-level evidence. No interpreter or integration check was executed by this research task. |

The UI's `tests/support/core_contract_examples.py:verified_core_examples_root`
(26-145) rejects a wrong sibling HEAD, dirty contracts, wrong manifest, changed
schemas or mismatched examples; `tests/test_core_contract_fixture_gate.py` names
`test_wrong_revision_fails_before_examples_are_read` (61) and
`test_dirty_contract_files_cannot_masquerade_as_pinned_examples` (108).
Source predicts that the current mixed checkout fails that provenance gate;
this is not a claimed test run or permission to reset the sibling.

## RQ02 — OPEN: compatibility source characterized; target/freeze needs owner

Recommend Core44.1 as the initial characterization/compatibility candidate because
the current legacy client deliberately supports it. Selecting CoreTip requires a
separate reviewed 44.1-to-44.3.33 contract/behavior delta and version-matched
fixtures; a newer sibling HEAD does not update the baseline automatically.
The historical migration plan's 10.2 baseline and proposed 42 target are obsolete
as statements of the current legacy client. Keep them as dated history only.

The source component has concrete immutable identities. Core44.1's
`contracts/manifest.json` Git blob is
`f46fbcd49803f6e12d0b2ea57292164a44e4ac86` (Git object SHA-1). Its manifest declares
97 interaction-conformance cases, four live decision scenarios, and 85 registered
decision types. Those counts are inventories, not proof every choice works live.
The following are SHA-256 values declared by that exact committed manifest;
this inspection did not independently run the full inventory verifier.

| Manifest member | Declared SHA-256 |
|---|---|
| `schemas/battlefield-view.schema.json` | `faecd553474a6396838c35541a3913247e1073e3c3e0938a9931e7ddb9243164` |
| `schemas/game-view.schema.json` | `0e6d0f2152873f4059c4dc05afa461ec5a5c3fdc3f880577ab358a7baaf735a7` |
| `schemas/session-command-envelope.schema.json` | `71213d34d360f72b81a58bf57de39729aa8747e97ed98186d0122eed80f48606` |
| `schemas/session-command-outcome.schema.json` | `677b46c2d6cd147152d71a5563fab939c68523449584e7b3b72dcce6859ea1cc` |
| `examples/battlefield/geometry-conformance.json` | `74de0022ff4a3bd6fcf1bce6c8e74a207eaf785622cbc7d17f840eaffd658ce5` |
| `examples/decisions/families/select_movement_unit.json` | `8d8ff170020518eae260806b8b08c9a71da40e035f1780033b961a6f466b8a80` |
| `examples/decisions/families/submit_movement_proposal.json` | `3d59999d54dbba2e660da76329782f513872be5703192fd72d4dfa71752cb62a` |
| `examples/decisions/parameterized/normal_move.json` | `82e67a3c3866fdfbb1870f7dda2f0e667fd91ee6db98361076d44f8e1b2fb347` |
| `examples/decisions/proposals/movement_path_witness.json` | `82037419fbcf0c07d76581628c52d76838a76ddd05084edab1785cf567a083e8` |
| `session-semantics.md` | `b3989ac0bf10f32ba95f533d65d46414ca8350d4530696bf3382a89d381258bc` |

Schema `$id` versions are not runtime `schema_version` discriminators. At
Core44.1, battlefield schema URI is `/contracts/v6/battlefield-view.schema.json`
but runtime discriminator is `battlefield-view-v5-rules-unit-membership`;
session-command-outcome URI is `/contracts/v18/session-command-outcome.schema.json`
but discriminator is `session-command-outcome-v44-contract`.
`Core44.1:src/warhammer40k_core/adapters/external_contract.py` 15-40 and
`adapters/battlefield_projection.py` 28-30 carry runtime constants.

**Missing/owner decision:** approve one Unreal core revision, runtime identity and
fixture set; name who approves future contract updates and how the migration
candidate freezes while Arcade/core development continues. Record an isolated
fixture/runtime consumption path without changing either shared sibling.

## RQ03 — CLOSED_SOURCE for Core44.1; execution and RQ02 selection remain open

Source identifies the normative HTTP operations below. All require bearer
authentication; identity comes from server-owned principal bindings. A supplied
viewer/actor string grants no authority. `session_id` differs from `game_id`.
`Core44.1:src/warhammer40k_core/adapters/server.py:AdapterGameServer.handle`
(302-392), `_handle_protocol_session` (601-681), `_create_protocol_session`
(886-915), and `contracts/openapi.yaml:paths` establish routing and schemas.

| Operation | Route/body -> result | Privilege/semantics |
|---|---|---|
| Connect/identify existing session | `GET /sessions/{session_id}` -> `session-metadata.schema.json` | `may_view_live`; returns exact engine/build/contract/catalog/source identities, revision, visibility, projection hash and opaque event cursor. No separate negotiation/version/readiness operation was found. Endpoint/session IDs and credentials are supplied externally. |
| Create | `POST /sessions`, `session-create.schema.json` (`schema_version: session-create-v4`, `config`) -> 201 metadata | Administrator `may_create_session`; all configured players need server-owned player-principal bindings. Transport starts `created`, revision 0. Canonical schema validates `GameConfig` before creation. |
| Start | `POST /sessions/{id}/commands`, `start_session` variant | Administrator `may_mutate_lifecycle`; request/result IDs null. Starts deterministic lifecycle at next decision boundary. |
| Full projection | `GET /sessions/{id}/projection` -> `session-projection.schema.json` | Role-scoped wrapper contains `projection` (`game-view.schema.json`), revision/hash/cursor/retention; not a bare `GameView`. Nullable pending decision, actor/context fields must preserve schema nullability. |
| Catalog | `GET /sessions/{id}/catalog` -> `rules-catalog.schema.json`; global `GET /rules-catalog` also exists | `may_view_catalog`; use returned source identity. Artwork does not define supported gameplay. |
| Events | `GET /sessions/{id}/events?cursor=<opaque>&limit=<1..500>` -> `event-delta.schema.json` | `may_view_live`; default 100, maximum 500. Keep opaque cursor, use viewer sequence and `next_cursor`/`has_more`, replace from full projection on `resync_required`. |
| Finite decision | Commands variant `{submission_kind: finite_option, option_id}` | Player bound to pending actor, `may_submit_decision`; use current engine request and option IDs. |
| Parameterized decision | Commands variant `{submission_kind: parameterized_payload, payload}` | Same player authority; canonical proposal schema and pending request/spatial context checked by engine. Movement needs its `PathWitness`. |
| Explicit advance | Commands variant `advance_session` | Administrator lifecycle privilege. At a waiting decision returns `advance_not_required`; client should not guess extra advance calls after accepted decisions. |
| Export replay | `GET /sessions/{id}/replay` -> `replay-metadata.schema.json` | `may_export_replay` plus role/session export policy. Active raw replay is administrator-only; replay-viewer export requires terminal/closed. |
| Close | Commands variant `close_session` | Administrator lifecycle privilege. Core owns the authoritative close; attaching clients cannot infer permission to terminate a host process. |

The envelope schema is `session-command-envelope-v2-weapon-instances`, with exact
keys `schema_version`, `command_id`, `session_id`, `expected_session_revision`,
`request_id`, `result_id`, `submission`. Lifecycle IDs are explicitly null;
finite/parameterized IDs are nonempty strings. No actor/viewer is accepted in
the command envelope. These are source details in
`Core44.1:src/warhammer40k_core/adapters/command_protocol.py:SessionCommandEnvelope` (35-175).
HTTP 422 can be an error envelope or a recorded command outcome; parse the
declared union, including separate `committed` and `accepted` values.

Accepted decisions are drained deterministically to the next visible boundary
by engine/server orchestration. The outcome supplies metadata, checkpoint and
event range; fetch/apply the corresponding scoped projection/events. See
`Core44.1:contracts/session-semantics.md` 95-162 and
`server.py:_apply_parameterized_payload` 1207-1281 plus the shared commit helper
it calls. No private queue/lifecycle path is necessary for these operations.

**Actual gaps:** no normative `/sessions/{id}/support-profile` route exists
(`Core44.1:tests/unit/test_phase18e_server_api.py:`
`test_phase18e_formal_session_rejects_undocumented_support_profile_route`, 1899).
The local Python facade exposes `support_profile()` and the deprecated `/games`
route exposes a support profile, but neither establishes a new-client HTTP
operation. If HUD parity requires a separate support-profile payload beyond the
supported viewer projection/capability catalog, record an external API dependency
or an explicitly approved presentation mapping; do not silently use `/games`.
There is no persistence upload/restore HTTP operation: the durable checkpoint is
operator-only. There is also no general discover/list-session, credential-issue,
host-ready or shutdown endpoint in this route table.

**Execution outstanding:** E01 must exercise exact-Core local and HTTP choices,
including both principals, finite and real parameterized actions, negative cases,
schema parsing and equivalent outcomes. All tests named in this packet were
inspected as source and were **not run**. Current Arcade is in-process:
`UI:src/warhammer40k_arcade_ui/core_client/local_session_client.py:LocalSessionClient` 49-205 calls the public
`AdapterGameSession`; its integer event cursor is not the HTTP opaque cursor.
Its local actor-following viewer convenience cannot supply remote authorization.

## RQ04 — OPEN: topology/host owner requires explicit choice

Two Core44.1 scripts are concrete but have different purposes:

- `scripts/run_local_session_dev_server.py:main` (43-76), `_handler_for` (79-141):
  read-only contract fixture harness, loopback/default 8766, custom `/health`,
  `/view/player-a` and similar routes. It does not implement the command protocol
  and cannot be the Unreal gameplay service.
- `scripts/run_phase18m_reference_server.py:main` (14-44): authenticated reference
  HTTP/OpenAPI conformance host, loopback/default, required port, optional
  shutdown-file watcher. It constructs default `AdapterGameServer()` with its
  development principal registry and no persistence-store configuration.
  It proves a launcher source exists; it does not prove production credentials,
  repair, readiness, runtime relocation or packaging.

`Core44.1:src/warhammer40k_core/adapters/server.py:create_local_dev_http_server` (1408-1427) is another
development factory, not a shipped executable. `Core44.1:pyproject.toml` 1-78 has
no `[project.scripts]` host entrypoint. The wheel includes the Python package and
contract schemas; repository scripts are outside that package configuration.

| Proposed mode | Client responsibility if selected | Separate core/deployer responsibility | Status |
|---|---|---|---|
| Managed local/offline | Stage an owner-supplied immutable artifact, start only that owned process, bounded readiness/exit, restricted endpoint/credential handoff | Supply host/runtime/native/data closure, supported launcher arguments/handshake, identity, persistence/repair/update contract | Owner choice and artifact missing |
| Attach to local service | Obtain approved endpoint/session/credential, connect and reconcile, leave process ownership with service operator | Start/stop/configure/recover service and supply compatibility guarantees | Owner choice/endpoint contract missing |
| Remote service | Client connection/identity/reconciliation over approved transport | Operator owns TLS/exposure, credentials, host limits, persistence, session admin and updates | Product/network trust choice missing |

**Owner question:** should desktop launch an owner-supplied local runtime for
offline play, attach to an existing local/remote service, or support both? Who
delivers the host artifact and administers sessions/credentials? Recommend
supporting an attach adapter plus managed local mode if offline play is required,
with the host artifact externally owned. This recommendation does not choose the
mode or authorize a new Python host in the Unreal repository.

## RQ08 — OPEN: source-backed first action; exact HTTP/package proof absent

Use Core44.1's public
`src/warhammer40k_core/adapters/setup_smoke.py:canonical_setup_prebattle_smoke_config`
(32-87), default game `setup-prebattle-ui-smoke`, players `player-a`/`player-b`,
turn order A then B, source ruleset descriptor
`core-v2-setup-prebattle-ui-smoke`. It constructs real catalog/mustering/mission
data, including its explicit `allow_legacy_non_strict_rosters=True` smoke policy;
do not describe that fixture as a production strict army-list acceptance test.
The host must receive the serialized public `GameConfig`, not a private state
patch or a screenshot fixture.

`UI:src/warhammer40k_arcade_ui/core_client/live_smoke.py:build_live_core_smoke_startup` (105-123),
`_drive_to_checkpoint` (126-178), `_automated_option_id` (197-258), and
`_automated_parameterized_payload` (278-312) define the existing ordered setup
policy. Follow the currently emitted request/option IDs: fixed secondary choices,
decline stratagem windows, complete reserves, canonical deployment units and
placements, redeploy/prebattle/Scout decisions, then movement. The traversal is
bounded and rejects unknown families. Do not reuse hard-coded request IDs from
`normal_move.json`, which belongs to a different exported fixture.

`UI:tests/test_live_core_smoke.py:`
`test_live_core_smoke_startup_reaches_real_movement_unit_selection` (105-146)
expects player A at `select_movement_unit`, a 44-by-60-inch board, 46 terrain
records and current actor/unit IDs. The meaningful action recipe is
`_ready_live_core_normal_move_payload` (496-576): select emitted
`army-alpha:scout-redeploy-unit`, then `normal_move`, retain the current
`submit_movement_proposal` request/context, select that unit's current group,
and add a waypoint one inch in +X relative to its current group anchor.
Preserve every model's original Z/facing and a complete per-model witness.
The test `test_live_core_smoke_uses_real_finite_and_parameterized_movement_path`
(311-340) submits that payload through `LocalSessionClient`, expects
`waiting_for_decision` at `select_movement_unit` or `start_mission_action`, and
asserts `movement_activation_completed`. This is a source expectation, not this
session's measured acceptance. The packaged proof should additionally compare
before/after authoritative poses so a no-op cannot satisfy acceptance.

An existing invalid case,
`test_live_core_smoke_preserves_canonical_monster_and_surfaces_invalid_advance`
(343-410), selects the monster Advance and a +2-inch draft, expects typed
`terrain_feature_transit_forbidden` on `witness` and no completion event. Retain
invalid state/draft behavior and prove a safe retry through the current request.

**Historical-plan correction:** current UI advertises a shooting checkpoint and
`test_live_core_smoke_reaches_shooting_after_declining_overwatch` (228-238).
Charge/Fight are still not advertised checkpoints. Thus the inherited assertion
that the fixture terminates before all shooting is no longer current.

Keep the two committed exact-build materialization/Damage-to-zero gzip checkpoints
separate: their provenance documents explicitly say they start from in-progress
domain helpers, not roster-start traversal. They cannot replace the first-slice
public setup/movement proof, and their filenames containing `contract42` do not
change their documented Core44.1 identity.

**Missing:** an isolated exact-Core44.1 runtime/fixture environment, a captured
complete HTTP command/principal/revision sequence generated through public
operations, observed accepted/invalid outcomes and updated poses, and E03A/B
packaged execution. No new capture/harness was written. After authorization,
replay the source recipe through `/sessions` with administrator create/start and
the correctly bound player credential for each choice; compare local and HTTP
outcomes on the same build. Render raised/asymmetric geometry separately until a
legal raised gameplay scenario is supplied/proven.

## RQ09 — OPEN: mapping source established; asymmetric-axis discrepancy/proof remains

`Core44.1:src/warhammer40k_core/adapters/battlefield_projection.py` 28-110, 180-195, 313-338,
465-531 and 635-731 is the authoritative projection boundary.

| Source field | Required client mapping/ownership |
|---|---|
| `coordinate_spec_version`, `coordinate_space` | Require `battlefield-coordinate-v1` and `battlefield_inches_right_handed_z_up`; fail unknown contracts. |
| Bounds | Preserve min/max X/Y and min Z. Current emitter uses (0,0,0) minima; nonzero-origin E02 data is a synthetic transform fixture, not a claimed current game emission. |
| Projected pose | `position.{x_inches,y_inches,z_inches}`, `facing_degrees`. Nullable pose for absent/hidden/off-board states is not an origin default. Preserve physical `unit_instance_id` and nullable canonical `rules_unit_instance_id` separately. |
| Proposal/PathWitness pose | `position.{x,y,z}`, `facing.{degrees}` (`geometry/pose.py:PosePayload/Pose`, 13-26, 97-135). Explicit field conversion; do not send projected names unchanged. |
| Model geometry | `support_shape`, separate `measurement_shapes`, `measurement_basis` base/hull, `height_inches`, source kinds/IDs. Mesh bounds or collision cannot substitute for any authoritative dimension. |
| Terrain/overlays | Wall/floor `bottom_center`, width/depth/height/rotation; objective positions, measurements and path segment poses retain Z. Presentation offsets never return to proposals. |
| Shape variants | Canonical union is circle/ellipse/rectangle/polygon. Model measurement emission handles circular/oval/rectangular/hull; support emission handles known base dimensions and raises on unsupported data. Capsule is an Arcade visualization capability, not an emitted Core44.1 canonical kind. |

Domain orientation uses ordinary positive-angle XY rotation: local X at heading
0, local Y at heading 90. `geometry/base.py:OvalBase.radius_at_angle` (86-98),
`RectangularBase.radius_at_angle` (124-142), and
`geometry/shapely_backend.py:_cached_base_footprint` (190-228) put length on local
X and width on local Y, then rotate by model facing. Polygon serialization
normalizes positive signed-area winding (`battlefield_projection.py:_normalized_polygon`,
699-708). The chosen presentation reflection must account for this winding.

Retain the plan's proposed invertible transform
`q_cm = 2.54 * (x-cx, -(y-cy), z-z0)`, followed by declared rigid table placement.
Its inverse returns `(cx+qx/2.54, cy-qy/2.54, z0+qz/2.54)` before/after the
appropriate world placement inverse. Heading basis maps `(cos(theta), sin(theta))`
to `(cos(theta), -sin(theta))`; horizontal UE yaw is consequently `-theta` before
world rotation. These are mathematical proposal values, not a run UE test.
Use double domain values, preserve source IDs/hashes verbatim and specify future
numeric round-trip tolerance independently from rules tolerances.

**Concrete source discrepancy:** Core projection emits ellipse/rectangle
`length_inches = 2*radius_x`, `width_inches = 2*radius_y`
(`battlefield_projection.py:_footprint_part_shape`, 491-511), consistent with the
core X/Y base convention above. Current Arcade
`render/core_projection.py:_model_local_shape_points` (545-565) uses width on
local X and length on local Y, then `_model_shape_footprint` (503-520) rotates by
facing. That is a source-backed 90-degree asymmetric geometry discrepancy.
Do not preserve it as intended parity or change core to match the old picture.
Before final mapping closure, numerically compare asymmetric projected parts
against the exact core's analytic/query footprint at facing 0/90 and a non-axis
angle; classify any missing contract clarity as an external dependency.

Current Arcade already preserves model elevation/facing in
`_canonical_model` (418-459), backed by source test
`tests/test_contract42_projection.py:test_canonical_model_projection_preserves_elevation_and_facing`
(106-120) and movement test
`tests/test_movement_draft.py:test_movement_payload_preserves_each_model_elevation_and_facing`
(335). Its generic `_canonical_position` (657-662), board and picking remain
planar; do not repeat the inherited claim that model Z is entirely discarded.

Core44.1 `contracts/examples/battlefield/geometry-conformance.json` includes
circle, hull/rectangle and oval models, model heading 30/135/45 degrees, a hull
model at Z 0.5, and floor volume bottom Z 2.0. Its bounds still start at zero.
It is a geometry conformance fixture with manual-override geometry, not proof
of a legal elevated movement. E02 still needs explicit asymmetric/capsule
presentation, nonzero origin/world placement, winding/normal/mesh replacement,
raised picking and inverse transform acceptance. Capsule should stay a named
synthetic presentation case unless the selected core schema adds it.

## RQ15 — OPEN: strong existing protocol; delivery/client proof unresolved

Core44.1 source specifies these responsibility boundaries:

| Failure/order case | Existing external source guarantee | Required client/host work and proof |
|---|---|---|
| Lost response/uncertain commit | Same command ID + canonical envelope + exact current authorization context returns original cached public outcome; different payload conflicts | Persist pending envelope identity locally; mark outcome unknown, retry the same envelope or reconcile. Never allocate a replacement action merely on timeout. |
| Concurrent commands/stale revision | Server lock, expected revision, isolated session fork, journal/revision/checkpoint publication allow at most one commit for a revision | Serialize client commands, reject obsolete callbacks; refresh/invalidate stale drafts instead of reinterpreting old intent. |
| Invalid attempt | `committed` differs from `accepted`; recorded invalid attempt advances revision and may yield a fresh request; unrecorded rejection leaves authority unchanged | Parse outcome/error union; show typed diagnostics and refresh based on commitment. Do not treat all HTTP 422 as identical. |
| Wrong viewer/role changes | Server principal binding, shared redaction; journal retry checks full authorization context before exposing cached outcome | Partition/dispose caches and cancel/invalidate old-generation callbacks. Request actor, turn owner and authenticated player are distinct. |
| Expired/foreign/drifted cursor | Typed successful delta with `resync_required`, no leaked hidden offsets; full projection supplies a fresh cursor | Replace derived state atomically and resume from supplied opaque cursor. Never use Arcade's integer local cursor on HTTP. |
| Persistence failure/ambiguous commit | Persisted handler latches fail-stop, returns typed 503; a fresh verified process is required after ambiguous commit | Keep view read-only/disconnected; operator owns restart/recovery; do not silently start a new game or overwrite old durable state. |
| Host crash/restart | Exact build/checkpoint/journal/cursor restoration supported by optional persistence-store path | Owner must configure persistence and deliver recoverable host. Current reference launcher does not wire a store. Test actual interruption/order in E03. |
| Bounds, credentials, process exit | HTTP reads declared Content-Length; query duplicates rejected; event page limit 500; bearer token size bounded | No body-size cap, request timeout, TLS configuration, rate limit or release credential provisioning is visible in this wrapper. External host/deployer supplies these; client limits alone do not protect server. Owned-process readiness/exit/persistence confirmation contract remains absent. |

Evidence: `Core44.1:src/warhammer40k_core/adapters/server.py:handle/_handle_persisted` (302-457),
`_execute_protocol_command` (683-790); `command_protocol.py:fingerprint`
(125-132); `contracts/session-semantics.md` 37-162, 164-266;
`http_transport.py:_read_json_body/_parse_content_length` (62-95, 111-119);
`access_control.py:RolePolicy/ROLE_POLICY_BY_ROLE` (32-125) and bearer parsing
(536-545). Do not log credentials, private checkpoint data or raw hidden events.
The existence of default development tokens in the reference registry is a
source limitation; this packet intentionally contains none of their values.

Named Core44.1 tests read as source, all **NOT RUN**:

- `tests/unit/test_phase18f_session_commands.py`: `test_phase18f_command_is_idempotent_and_enforces_revision_ordering`
  (111), `test_phase18f_simultaneous_commands_commit_once_and_replay_projection_hashes`
  (161), `test_phase18f_duplicate_http_commands_are_byte_equivalent_after_reconnect`
  (250), `test_phase18f_precommit_rejections_preserve_authoritative_state` (289),
  `test_phase18f_recorded_invalid_retry_is_atomically_journaled` (485), and
  `test_phase18f_noop_advance_cannot_consume_revision_or_win_decision_race` (664).
- `tests/unit/test_phase18g_18h_session_security.py`:
  `test_phase18g_returns_typed_non_leaking_resync_for_invalid_cursor_classes`
  (447), `test_phase18h_enforces_mutation_replay_support_and_viewer_claim_policies`
  (729), `test_phase18h_event_redaction_hides_secret_counts_and_uses_viewer_sequences`
  (913), `test_phase18h_idempotent_retry_requires_exact_current_authorization_context`
  (1027).
- `tests/unit/test_phase18l_session_persistence.py`:
  `test_phase18l_sqlite_restart_restores_idempotency_cursors_and_exact_role_views`
  (797), `test_phase18l_crash_before_or_after_atomic_commit_recovers_exactly_once`
  (1097), `test_phase18l_untyped_custom_store_post_commit_failure_latches_fail_stop`
  (1150), and
  `test_phase18l_same_package_version_different_build_fingerprint_fails_before_recovery`
  (1643).

The future client state model should distinguish Disconnected, Connecting,
Ready, CommandPending, OutcomeUnknown, ResyncRequired, Recovered and Terminal;
generation/viewer/revision guards apply before committing any callback. This is
a proposed client design, not existing Unreal code. Close RQ15 only after the
selected deployment trust model, host safeguards and specific E01/E03 proof
scope are agreed; do not ask the owner to certify technical behavior from memory.

## RQ17 — BLOCKED: no approved consumable runtime/service artifact yet

Core44.1 metadata requires Python `>=3.14,<3.15`, includes native-sensitive
orjson/msgspec/Pydantic/Shapely/NumPy plus jsonschema/referencing, and pins
`z3-solver==4.15.4.0` (`pyproject.toml` 1-20). This solver dependency is absent
from the old migration plan's dependency-floor summary and must enter the native
runtime inventory. Floors are not locks or compatible Windows/Linux artifacts.
The wheel includes `src/warhammer40k_core` and force-includes `contracts/schemas`
(`pyproject.toml` 66-75); it is not a self-contained Python executable or a
cross-platform service delivery contract. Runtime identity validation covers
packaged resource bytes, not a promise of native relocation or licensing.

Required external delivery record for each selected platform/mode:

1. Exact source, runtime build ID, artifact hash/signature, platform/architecture,
   interpreter/native dependency inventory and provenance, schema/catalog/source
   identities, redistribution owner and supported update pairings.
2. Supported host entrypoint/arguments, endpoint/session discovery, secure
   credential handoff, admin versus player responsibilities, readiness/exit
   semantics, persistence store initialization/recovery/repair, writable paths,
   single-writer ownership and log redaction contract.
3. Client staging and cook references with no sibling/system-Python/developer-path
   assumptions. Managed mode proves offline/relocation; attach mode proves the
   approved endpoint/service identity and does not terminate the service.
4. Isolated E03A clean-machine consumption/native loading/connection/one-command
   feasibility, followed by E03B full packaged movement and failure/recovery
   acceptance. Do not describe either as passed until executed.

**Dependency owner/unblock:** the user/core-service owner must identify who
supplies that artifact or approves an attach-only service contract (RQ04/RQ05).
Creating a new Python host, adding release packaging to Core, editing reference
scripts or publishing a runtime is separately owned work outside this campaign.
An Unreal project scaffold would not resolve this blocker.

## Questions worth taking to the owner

1. Freeze Unreal against the existing Arcade-supported Core44.1 commit/build, or
   select another explicit release with a reviewed delta? Who approves later
   contract changes? Recommend the existing 44.1 candidate for first parity work.
2. Which of managed offline local, existing local service and remote service must
   ship, and who supplies/operates the host runtime, credentials and durable state?
   Recommend preserving offline intent through an externally supplied local
   artifact if offline play is required, while keeping attach mode possible.
3. Which player/hotseat/remote/spectator modes must the first slice support? This
   affects credential/viewer switching, session admin and the RQ06 role matrix.

These owner choices cannot close missing numerical geometry, runtime relocation,
HTTP differential, crash-order or packaged evidence. Those remain explicitly
bounded future checks/experiments under Section 0's authorization gates.
