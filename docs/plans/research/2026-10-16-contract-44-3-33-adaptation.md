# Core 44.1 to 44.3.33 adaptation and developer launch research

**Date:** 2026-10-16. **Evidence:** source inspection only; no installation,
dependency synchronization, host launch, test, generated fixture, build or new
host implementation was performed. This extends
[the original Core44.1 packet](2026-10-16-contract-integration.md) without
rewriting that historical baseline.

The owner selected exact sibling Core revision
`5f509724da25a2f6ded0c2739a8e7c84bdf59c91` / external contract `44.3.33`, subject
to this adaptation review. The owner also selected managed local launch plus
attach, Windows and Linux for the first slice, local/remote/spectator modes, and
personal/internal use. Developer instructions must support an existing checked-out
Core as well as source/package pip installation. In the subsequent owner answer,
"Use the currently checked out development server" selects this exact checkout's
`scripts/run_phase18m_reference_server.py` for initial internal development;
no new host or runtime artifact is required to begin that approved route.
Linux's actual host and proof are explicitly deferred: "arranged later; plumb
project; acknowledged un-tested". Retain Linux project/build plumbing and record
Linux execution as NOT RUN until that host is available; this is not Linux PASS.
These choices do not appoint a later runtime-artifact maintainer or authorize
edits to Core. This packet's later decisions supersede the earlier packet's
unanswered deployment/target recommendations; its historical source baseline
stays intact.

## Exact identities and inspected delta

`Core` below means
`Warhammer_40k_AI@5f509724da25a2f6ded0c2739a8e7c84bdf59c91`.
`Baseline` means
`Warhammer_40k_AI@fc12fa214642f1b1f2a31b56be7323b7d76dbebc` / `44.1.0`.
`UI` means
`Warhammer_40k_UI_arcade@5088c1c49dcaff29eb59fb64b3063d30214dde73`.
Paths following these aliases are repository relative. Python-module paths
abbreviated `adapters/`, `engine/`, `geometry/` resolve beneath
`src/warhammer40k_core/`; UI `core_client/`, `state/`, `render/` resolve beneath
`src/warhammer40k_arcade_ui/`. Thus every alias/path/symbol expands to an immutable
`repository@commit:path:symbol` reference. Both siblings reported clean status.

| Identity | Selected value/source |
|---|---|
| Commit and contract | `5f509724da25a2f6ded0c2739a8e7c84bdf59c91`, `44.3.33`; `Core:src/warhammer40k_core/adapters/external_contract.py:EXTERNAL_CONTRACT_VERSION` line 15, `contracts/manifest.json` line 2, `contracts/openapi.yaml:info.version` line 5 agree. |
| Runtime build | `warhammer40k-core-v2:runtime-tree-sha256-v1:65fc8414407ae5d6a8ea779c8e737a22733459094db679a160c60f6e2129f96a`; `Core:src/warhammer40k_core/_engine_build_manifest.json:build_id` lines 1-5; 3,116 resources. Source-generated identity, not verification of any installed interpreter. |
| Contract manifest object | Git blob SHA-1 `4d4593a44610e9b4850565ec640abe0abdd9f83a`. |
| OpenAPI object | Git blob SHA-1 `e8e73f9e3bad2fccba8a3ebb1b42edfe9e2eb11b`. |
| Selected developer launcher | `scripts/run_phase18m_reference_server.py`, Git blob SHA-1 `4da965aa9cef439570629037ff377fca0102e692`; the read-only fixture launcher has distinct blob `3a01fe4e344c935425d27d5c92e78c76b5abaf72`. |
| Inventory | 98 interaction-conformance cases, 86 registered decision types, 88 known external tokens, four live scenarios, 13 interaction kinds, 21 proposal kinds, 24 parameterized payload kinds (`Core:contracts/manifest.json`). Counts are declared inventory, not executed gameplay coverage. |
| Legacy identity retained | UI still requires `fc12fa...` / `44.1.0` / build `7e6f1a71...`; `UI:core_client/compatibility.py` lines 46-65 and 70-145 reject drift. Do not point the existing Arcade installation at 44.3.33 or relax its guard here. |

`git diff Baseline Core -- contracts/schemas` is empty: **every committed JSON
Schema file is unchanged**. The only changed adapter production files are
`external_contract.py`, `projection.py`, and `redaction.py`; their changes are
described below. HTTP server, command envelope, persistence/session/cursor
protocol implementations and `contracts/session-semantics.md` are unchanged.
The original packet's normative `/sessions` operation table therefore remains
source-valid at the selected commit, including its absent support-profile,
credential-provision, host-readiness and persistence-upload operations.

OpenAPI was reserialized/expanded, with the same normative route/method set;
schemas and runtime family discriminators are unchanged. Bundle version and
examples changed. Read-only JSON decoding/comparison found all `paths` and
`components` objects equal between the two commits (16 total path templates,
including deprecated routes); this was a metadata comparison, not a server test.
Do not confuse URI `/contracts/v18/...` with a runtime
`session-command-outcome-v44-contract` discriminator.

**Contradictory prose:** `Core:contracts/README.md` still says contract `44.3.8`
and `contracts/compatibility-policy.md` lines 3-5 say `44.2.0`; these do not match
the selected manifest, executable constant or OpenAPI. Record this as external
documentation drift. Do not use those prose values for negotiation or edit the
reference sibling. Exact build identity remains mandatory despite unchanged
schemas and semantic-version labels.

## Required Unreal adaptation, with legacy differences made explicit

| Selected change and immutable evidence | Required client behavior/evidence |
|---|---|
| `Core:docs/ADAPTER_DECISION_CONTRACT.md` 7532-7549, Contract 44.2: public `mission_action_battle_shock_applied`, followed by existing Action-interruption events | Present emitted source/event/reason facts; no client-generated interruption rules or fabricated test result. |
| Same contract, 7571-7610, Contract 44.3: finite source-owned Embark carries typed source occasion/context; movement remains separate | Render offered finite choices without inventing a preceding move or rewriting turn-action history. Follow engine source context. |
| Same contract, 7611-7632, 44.3.1/.2: Snap sixes are ordinary hits; absent-Movement models are fixed including rotation/intermediate poses | Dice/HUD shows engine classification. Distinguish absent Movement from numeric zero; display `model_pose_fixed` diagnostics. Do not derive legality from a displayed number or animate a rules outcome the core did not emit. |
| Same contract, 7633-7726, 44.3.3-.11; `Core:adapters/redaction.py` 523-540, 853-864 | Existing finite/proposal envelopes now carry additional mortal-source, ability-lifetime, Psychic, timing, keyword and nested-reroll semantics. Preserve opaque source IDs/context, list ordering and nulls. Never expose new private mortal-allocation or `attack_ability_source_retained`/`attack_ability_sources_expired` events; shared core redaction hides them. `native_snapshots` is internal and stripped. |
| `Core:engine/movement_source_reposition.py:request_source_reposition` 136-164 and `_options` 107-133; `engine/interaction_metadata.py` 300; adapter contract 56-74 | New finite `select_source_reposition` uses existing `opportunity_window` descriptor. Submit the offered `decline_source_reposition` or `enter_strategic_reserves` ID; retain source occasion/spatial context; do not invent provider activation. Conformance family is `envelope_only`, not a certified named-faction workflow. |
| `Core:contracts/migrations/44.3.12-to-44.3.13.md` 1-11 | Redeploy now uses normal deployment/Infiltrators geometry and typed diagnostics, including `infiltrators_keyword_required`, enemy-zone/unit distances and unsupported Fortification. Render current invalid results; no copied old-zone-only restriction. |
| `Core:contracts/migrations/44.3.13-to-44.3.14.md` through `44.3.20-to-44.3.21.md` | Whole-model setup fit, flight/turn cleanup, destruction/scoring history, objective-directed movement, circular disembark equality, keyword identity and physical visibility changed through existing envelopes. Do not recreate these rules in Unreal. Copy current descriptor/context hashes and supported choices; show typed unresolved/unsupported results. Conditional oversized-deployment infrastructure is not proof that an actual granting provider is admitted. |
| `Core:contracts/migrations/44.3.21-to-44.3.22.md` through `44.3.24-to-44.3.25.md` | Full 3D disembark, starting cargo restore, Counter-offensive eligibility and Fight ordering/pass authority changed. Gathered Hit/Wound rolls occur by step; UI follows engine requests/journals, not a fixed per-attack dice animation. Tactical-feasibility uncertainty returns typed invalid without consuming state; do not substitute a client geometric guess. Grouped Combat hazard event has explicit `disembark_payload_kind: rules_unit_combat_disembark`; never infer it from old untagged data. |
| `Core:contracts/migrations/44.3.25-to-44.3.26.md`, `44.3.26-to-44.3.27.md` | Completed Combat hazard applies direct Battle-shock with new generic event `combat_disembark_battle_shock_applied`; `battle_shocked_until` is `until_cleared`. This is not a fabricated Leadership roll. Restore supports authenticated physical-history anchors only at the matching build. |
| `Core:contracts/migrations/44.3.27-to-44.3.28.md` | Embark uses actual 3D inclusive three-inch authority for all living attached models. Core's declared 1e-9-inch allowance is external numerical policy, not permission to implement local legality. Oval approximation/native FRAME applicability limits remain explicit. |
| `Core:contracts/migrations/44.3.28-to-44.3.29.md`; `tests/integration/test_movement_witness_membership.py` 64, 180 | Normal/Advance/Fall Back witness must contain exact current placed living inventory of the pending canonical rules unit, including attached components. `movement_witness_model_inventory_mismatch` rejects before queue/history/event/RNG mutation and allows corrected **same-request** retry. Well-formed rule-invalid geometry can still record an attempt and produce a **new** request; distinguish these paths. |
| `Core:contracts/migrations/44.3.29-to-44.3.30.md` | Physical-model MONSTER eligibility now permits stable upper Ruins floors; terrain descriptor fingerprint changed. Use updated descriptor/hash and actual Z. No broad new terrain permission, SWARM support, provider admission or cross-runtime converter is implied. |
| `Core:contracts/migrations/44.3.30-to-44.3.31.md` | Heavy depends on actual accepted movement/setup history, with separate Assault permission. Show core-provided modifiers/choices; do not equate the Advance label with ineligibility. |
| `Core:contracts/migrations/44.3.31-to-44.3.32.md`; adapter contract 2215 | Exactly one selected profile and at most one target per physical `weapon_instance_id`. Duplicate same-copy alternative profiles reject atomically as `duplicate_weapon_declaration`, including targetless declarations. Preserve independently identified copies/Firing Deck sources; retain source selection limits. |
| `Core:contracts/migrations/44.3.32-to-44.3.33.md`; adapter contract 1946 | Epic Challenge chooses an eligible physical CHARACTER of the selected canonical rules unit, including an attached Leader/Support. Unit keyword union does not grant CHARACTER to Bodyguards. A valid no-usable-melee declaration completes through no-melee activation/consolidation without inventing an actual fight; armed units still owe mandatory attacks. Invalid choice retains exact request. |

Two changes need deliberate client design, even though wire schemas did not change:

1. **Physical movement order is meaningful.** Contract 44.3.12
   (`Core:docs/ADAPTER_DECISION_CONTRACT.md` 7727-7732) and
   `Core:geometry/pathing.py:PathWitness` 614-683 preserve `model_paths` order;
   `model_ids()` alone returns a sorted inventory. `Core:engine/sequential_movement.py:`
   `sequential_peer_models` 59-91 places earlier paths at their final poses and
   later paths at their starts. Unreal must retain an explicit model-movement
   sequence, distinguish it from canonical inventory order, show it to the user,
   and serialize that sequence without sorting. Existing Arcade
   `state/movement_draft.py` 514-525 seeds from `unit.models`, and 934-1008 emits
   that tuple order. `render/core_projection.py` 370-407 groups sorted projected
   models. This source does not establish an interactive reorder workflow; do
   not treat its incidental ordering as a requirement. Future acceptance must
   cover vacate-before-follow versus cyclic exchange, attached components and
   invalid same/new-request retry distinctions.
2. **Alternative weapon profiles are mutually exclusive within a copy.** Current
   `UI:render/arcade_window.py:_same_shooting_physical_source` 2893-2903 includes
   profile ID in its equality, and selection replacement at 1440-1452 uses that
   equality. `UI:state/assignment_workspace.py:_shooting_row_id` 963-971 also
   includes profile; default workspace rows (315-336) iterate emitted profiles.
   `UI:tests/test_assignment_workspace.py:`
   `test_shooting_assignment_workspace_keeps_legal_profiles_sharing_a_copy` (188)
   explicitly preserves the old behavior. Unreal's selected-copy grouping must
   follow 44.3.32 instead: preserve profile rows for presentation, but selecting
   another profile replaces the previous selection of the same physical copy.
   This is an intentional target-contract change, not lost parity.

Generic parser implications: `UI:core_client/protocol.py:UiDecision` 1525-1679
accepts a nonempty decision type and typed descriptor, while
`UI:state/interaction_dispatch.py` 15-31 already maps `opportunity_window` to
the generic finite editor. The added family does not need invented proposal
support. `protocol.py:invalid_diagnostics_from_status` 2129-2205 accepts typed
violation codes/`invalid_reason` as strings, so new source diagnostics should
remain visible. New Unreal parsing must remain strict about shape/discriminators
without using a stale diagnostic-code whitelist to reject legitimate new codes.

`Core:adapters/projection.py:project_rules_catalog_view` line 395 now uses
`datasheet.effective_keywords`; model/unit/catalog views acquire name keywords.
`Core:adapters/redaction.py` 169-178 preserves a legitimate name keyword even
when it equals an attachment marker. Display these engine-owned tokens; do not
turn names, aliases, unit unions or client normalization into eligibility rules.
The source geometry axis discrepancy recorded in the earlier packet is still
present because the projection/geometry converters concerned are unchanged.
The selected contract also names terrain classification `exposed` alongside
`dense`, `light`, `mixed` and `unknown` (adapter contract 4390); retain the emitted
classification/presentation label without deriving terrain legality from styling.

## Exact selected fixtures and future verification

The hashes below are **declared SHA-256 entries in Core's committed manifest**;
this research did not execute the generator, inventory checker or test suite.

| `contracts/` member | Selected SHA-256 |
|---|---|
| `examples/decisions/interaction-conformance.json` | `f77c531fd8cf0be39a088e8b83d0a7eaae947820b112143d08f8b60778fd6b20` |
| `examples/decisions/family-coverage.json` | `419be9dbfe9035a6365f135be88d34dd82771d0d7d96f3ee09c67a708ce41107` |
| `examples/sessions/session-create.json` | `2b1db622c7c09f8a982b515a8be932afa38af8a9383cf491996c2cb26a9627b0` |
| `examples/sessions/session-command-outcome.json` | `342ae97187046486c752cc04d42c0c4aff866ca6575a014f6606019c9aa238cb` |
| `examples/decisions/proposals/deployment_placement.json` | `28dcb42c87d471bc4161e4cc8a4ab843f098871da91810003bcb39d2f7f8c08f` |
| `examples/projections/post_deployment_view.json` | `7fa46cfa146f96e50d9c05c514b539df9b3530ba9eb310078567d30a0dca819b` |
| `examples/projections/attached_charge_view.json` | `162872a3010d6b28f3931df88cba09bb2f0f6a83368df5232524d91a37774c3b` |
| `examples/persistence/session-persistence.json` | `355a9fc20e53c1d675db0d8ef38e9da2b9fcab608d9ee601da7dc0d8b0ffaca7` |
| `examples/replay-metadata.json` | `c3ae5af4c0018b7cf3363ab02b588a3237ccd805a0839c40504f42379d7a2c0f` |
| `examples/battlefield/geometry-conformance.json` (unchanged) | `74de0022ff4a3bd6fcf1bce6c8e74a207eaf785622cbc7d17f840eaffd658ce5` |
| `examples/decisions/parameterized/normal_move.json` (unchanged) | `82e67a3c3866fdfbb1870f7dda2f0e667fd91ee6db98361076d44f8e1b2fb347` |
| `examples/decisions/proposals/movement_path_witness.json` (unchanged) | `82037419fbcf0c07d76581628c52d76838a76ddd05084edab1785cf567a083e8` |
| `schemas/battlefield-view.schema.json` | `faecd553474a6396838c35541a3913247e1073e3c3e0938a9931e7ddb9243164` |
| `schemas/game-view.schema.json` | `0e6d0f2152873f4059c4dc05afa461ec5a5c3fdc3f880577ab358a7baaf735a7` |
| `schemas/session-command-envelope.schema.json` | `71213d34d360f72b81a58bf57de39729aa8747e97ed98186d0122eed80f48606` |
| `schemas/session-command-outcome.schema.json` | `677b46c2d6cd147152d71a5563fab939c68523449584e7b3b72dcce6859ea1cc` |
| `schemas/session-create.schema.json` | `837e5a43a9a1eada3216eb809a530a1b09c2c328dca6a2001b5874f940ff4618` |
| `schemas/session-projection.schema.json` | `75bf8c44671af5357105ad93f63a1e7f956656167f5f31c55515a3eac2b95274` |

The 98th conformance case is `finite:select_source_reposition`; it has synthetic
`contract-option` data and an `envelope_only` family record. It proves the
fixture/parser shape only when actually checked. It is not the real source
occasion, an admitted named faction activation or a public roster-start traversal.
Full selected session/replay examples carry the new build/contract, descriptor,
projection hashes and opaque cursors; mixing old envelopes/IDs with refreshed
fixtures is invalid. The standard setup descriptor hash changes from
`50ca2851b6f30ff2891ef55d1cd5bebee425fd47c17a3c3807362ce99e6c3e4e`
to `4628f51dc7a64ed686669da01ae0633c1ad3a598c4ddc8dc4cb2059e6ef5c9ce`.
Deployment proposal fixture hashes are distinct and remain opaque; clients must
copy the request's actual current value rather than the standard setup hash.

Existing selected-Core test source provides focused future checks, all **NOT RUN**:

- `tests/unit/test_order126_sequential_movement.py:`
  `test_facade_occupancy_order_invalid_retry_pending_completed_restore_and_replay`
  (64), and
  `test_shared_path_consumers_accept_vacate_before_follow_and_reject_cyclic_occupancy`
  (145).
- `tests/integration/test_movement_witness_membership.py:`
  `test_native_wrong_witness_inventory_is_atomic_with_legal_retry_and_continuation`
  (64), and
  `test_native_rule_invalid_geometry_still_records_attempt_and_emits_fresh_retry`
  (180).
- `tests/unit/test_order80_normal_move.py:`
  `test_order119_prior_reactive_move_then_source_reposition_restores_and_replays`
  (676), `test_order119_decline_source_reposition_preserves_movement_and_continuation`
  (763).
- `tests/unit/test_d12_epic_challenge.py:`
  `test_d12_epic_invalid_model_choice_is_atomic_and_exact_request_retries` (154),
  `test_d12_native_split_epic_keeps_physical_model_ownership` (330);
  `tests/unit/test_d12_no_melee_continuation.py:`
  `test_d12_dead_leader_support_no_usable_melee_completes_and_replays` (46).

The original Arcade public setup/+1-inch movement recipe remains a candidate
first action, not a verified 44.3.33 result. Recreate its command/principal/revision
trace against selected Core, preserve actual sequential path order and complete
current inventory, then prove accepted pose change and invalid retry. Old
Core44.1 gzip checkpoints are historical exact-build fixtures and must never be
rehash-edited or described as 44.3.33 saves. Windows/Linux HTTP/package proofs,
remote authentication/spectator evidence and actual rendered 3D remain E01/E02/E03
obligations after the relevant authorization.

## Source-verified developer installation and launch recipes

The commands below are **documented future user procedures, not executed results**.
An existing isolated Python 3.14 environment containing exactly the selected Core
is a prerequisite. These recipes do not repair the workspace's already mismatched
Arcade environment. Use one installation source per environment; no token belongs
in a Git URL, command argument, README, log or committed configuration.

### Existing prepared checkout environment

Run from the exact selected Core checkout root. The launcher path and flags are
directly supported by `Core:scripts/run_phase18m_reference_server.py:main` lines
14-44; the conformance runner invokes this same script from Core root at
`conformance/typescript/src/main.ts:startReferenceServer` lines 137-150.

```text
uv run --no-sync python scripts/run_phase18m_reference_server.py --host 127.0.0.1 --port 8765
```

`--no-sync` requires a prepared, verified environment and prevents an implicit
dependency sync. It does not verify that the environment is correct. The Core
worktree alone is insufficient: this script imports `warhammer40k_core` as an
installed package and does not insert repository `src/` into `sys.path`.

### Separate pip environment: checkout or pinned Git source

Example Windows PowerShell, starting in `Warhammer_40k_UI_unreal`:

```powershell
py -3.14 -m venv .local\core-44.3.33
$CorePython = Join-Path (Get-Location) '.local\core-44.3.33\Scripts\python.exe'
$CoreCheckout = (Resolve-Path '..\Warhammer_40k_AI').Path
git -C $CoreCheckout rev-parse HEAD
git -C $CoreCheckout status --porcelain=v1
# Continue only when this is 5f509724da25a2f6ded0c2739a8e7c84bdf59c91.
# The status must be empty before installing this frozen candidate.
# Select ONE installation source:
& $CorePython -m pip install $CoreCheckout
# OR, using already configured secure Git authentication:
& $CorePython -m pip install 'git+https://github.com/SobolGaming/Warhammer_40k_AI.git@5f509724da25a2f6ded0c2739a8e7c84bdf59c91'
& $CorePython -m pip check
& $CorePython -I (Join-Path $CoreCheckout 'scripts\run_phase18m_reference_server.py') --host 127.0.0.1 --port 8765
```

Example Linux shell, starting in `Warhammer_40k_UI_unreal`:

```bash
python3.14 -m venv .local/core-44.3.33
core_python="$PWD/.local/core-44.3.33/bin/python"
core_checkout="$(cd ../Warhammer_40k_AI && pwd)"
git -C "$core_checkout" rev-parse HEAD
git -C "$core_checkout" status --porcelain=v1
# Continue only when this is 5f509724da25a2f6ded0c2739a8e7c84bdf59c91.
# The status must be empty before installing this frozen candidate.
# Select ONE installation source:
"$core_python" -m pip install "$core_checkout"
# OR, using already configured secure Git authentication:
"$core_python" -m pip install 'git+https://github.com/SobolGaming/Warhammer_40k_AI.git@5f509724da25a2f6ded0c2739a8e7c84bdf59c91'
"$core_python" -m pip check
"$core_python" -I "$core_checkout/scripts/run_phase18m_reference_server.py" --host 127.0.0.1 --port 8765
```

Select only one `pip install` branch; the two adjacent lines are alternatives,
not a script to run verbatim in sequence. Replace paths/interpreter selection for
the actual machine, and inspect exact provenance/build/contract before a client
session. These examples install a normal package from source; they do not request
an editable checkout, modify the core dependency lock or synchronize the shared
environment. Protect `.local/` as an ignored generated environment when creating
it is authorized. The launch remains foreground; stop with Ctrl+C.

If the separate owner supplies a verified wheel, replace the install line with
`<core-python> -m pip install <absolute-path-to-verified-core-wheel.whl>` and run
`<core-python> -m pip check`. The artifact hash and complete platform dependency
closure must accompany that wheel. No verified wheel file currently exists in
this evidence packet. A private package-index route is not documented because
none was identified.

The pinned Git source recipe still uses the selected checkout's **repository
launcher script**. A pip-installed package is not enough to discover or execute
that script: `Core:pyproject.toml` lines 1-78 declares no `[project.scripts]`
entrypoint; wheel configuration includes `src/warhammer40k_core` and
`contracts/schemas`, not top-level `scripts/`. Requiring the checkout for this
developer route is intentional and is not the eventual managed-runtime package.

Native dependency caveat is concrete: the selected pyproject requires Python
`>=3.14,<3.15`, orjson, msgspec, Pydantic, Shapely, NumPy, jsonschema, referencing,
and `z3-solver==4.15.4.0` (lines 1-20). Pip resolves those declarations for the
chosen interpreter/platform; availability of usable Windows/Linux wheels and
relocation has not been tested. Build isolation also needs Hatchling. No claim
is made that a clean machine can install offline, that these are complete
transitive pins or that absent native wheels will compile automatically.

`Core:scripts/smoke_installed_contract_wheel.py:main` (250-307) supplies a future
existing check: build the wheel, create a fresh external environment, install
with dependencies, remove `PYTHONPATH`, run the isolated interpreter outside the
repository, and verify packaged schema/runtime metadata. It has not been run.
The runtime verifier normalizes source text line endings
(`Core:src/warhammer40k_core/build_identity.py` 215-223, 277-278), so exact runtime
identity is distinct from arbitrary working-tree newline hashes.

### Correct host, shutdown and authentication boundaries

`scripts/run_phase18m_reference_server.py` accepts **only** `--host`, required
`--port`, and optional `--shutdown-file`. For file-triggered shutdown, supply an
absolute path that does not already exist; its watcher calls `server.shutdown()`
when that file appears (47-50). The launcher closes its socket in `finally`.
It does not implement a documented persist-and-exit handshake or write a durable
store. The absence of a separate `/health` on this formal host is expected;
conformance readiness is an authenticated `/rules-catalog` request, not the
unrelated fixture harness's health route.

`scripts/run_local_session_dev_server.py` is the different read-only fixture
server on default port 8766, with custom `/view/...` and `/health` routes. It
cannot accept `/sessions/{id}/commands` and is unsuitable for gameplay launch.

The formal reference launcher constructs `AdapterGameServer()` with the default
development principal registry and no configured persistence store. Its CLI has
no credential file, token, TLS or persistence option. The four
`CORE_V2_CONFORMANCE_*_TOKEN` variables in the TypeScript README configure
conformance **client** credentials; they do not configure this Python host.
Do not claim that exporting a custom token secures this default launcher. This
packet does not include development credential values. Development use stays on
loopback by default. The owner accepts this existing development host for initial
internal work, including its fixed development registry and absent durable store.
Managed mode launches only its own selected-checkout process; attach mode uses
an already running instance and never stops or reconfigures it. Existing
server-owned player/coach/delayed-spectator/admin/replay roles retain their actual
policies; a caller's viewer parameter cannot substitute for those credentials.
Remote exposure, stronger credential provisioning, durable recovery and packaged
runtime independence remain explicit later acceptance/design work, rather than
conditions invented to block the selected development route.

## Remaining external delivery and experiment boundary

This review supplies the owner-selected **source-level development launch and
attach procedure**, subject to successful authorized package/environment checks.
RQ04's initial host/topology is now selected: use the exact checked-out reference
server, with the client launching its own process or attaching to an existing one.
RQ17's initial development consumption route is a prepared exact-Core environment
or separate pip installation plus the exact checkout's launcher. A portable
artifact is not a prerequisite for this initial route and none was produced.

Record the development limitations honestly: no configured persistence store,
fixed development credential registry, no TLS/body-size/time/rate hardening in
the launcher, and no packaged standalone host entrypoint. These become relevant
later gates for durable recovery, remote exposure or checkout-independent
packaged delivery. Such delivery still needs an identified maintainer and exact
Windows/Linux artifact/native/data closure; do not assign that work implicitly
or write a new Python host here. A prepared developer machine remains distinct
from a clean-machine/offline package proof.

RQ15's unknown-commit/crash cases must distinguish the selected nonpersistent
development host from a future durable host: a restart of this selected launcher
does not restore a game, and the client must surface session loss explicitly.
Source deduplication and optional persistence tests are not evidence of configured
durability. Linux plumbing may proceed under the owner's accepted deferral;
its native/render/package evidence remains NOT RUN with a deferred host, and
cannot pass final Linux acceptance silently. Schema stability closes neither
source geometry discrepancies nor native-runtime risks. Section 0's separate
experiment/implementation gates still govern execution.
