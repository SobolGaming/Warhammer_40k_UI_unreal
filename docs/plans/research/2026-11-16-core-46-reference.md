# Core 46 reference and bounded adoption delta

Research date: 2026-11-16. This supports the [single canonical migration plan](../unreal-migration-plan.md); the plan owns P2c scope and acceptance. This is a source inspection, not a runtime, gameplay, platform or review PASS.

## Frozen subjects and method

| Subject | Exact Core commit | External contract |
|---|---|---|
| Previously selected Unreal runtime | `4f9bef0df2fb974d1285232a1009b8781926361d` | 44.5.0 |
| New source reference / P2c adoption candidate | `fc52e9166ff6380b606269ce362f4f1cbc6a2835` | 46.0.0 |

The coordinator fetched the existing Core remote safely. Research read the exact Git objects with `git show`, `git grep` and JSON parsing; it did not check out, edit, import or execute the candidate. The sibling working checkout remains at `5f509724da25a2f6ded0c2739a8e7c84bdf59c91`. Historical 44.3 and 44.5 packages, runtimes, sessions and evidence retain their original identities. The [previous supporting inventory](2026-10-24-latest-core-capabilities.md) remains dated history, not a statement that 44.5 is current main.

The new [committed build manifest][new-build] declares `runtime-tree-sha256-v1`, fingerprint `ae914a56833e43a3bbf086730b354c7a18673ccc15ca93e4b474347b95380f19`, full build ID `warhammer40k-core-v2:runtime-tree-sha256-v1:ae914a56833e43a3bbf086730b354c7a18673ccc15ca93e4b474347b95380f19`, and 3,256 resources. The [old manifest][old-build] declares 3,130 resources and fingerprint `0443ce4bc405aad1737ec9a396948775010df933bd75144f6ab9ff54152118ba`. Parsed array lengths match these declared counts. This inspection did not recompute the installed resource tree. Core's [build identity implementation, lines 78–144][build-code] hashes the canonical inventory of logical paths, byte lengths and individual SHA256 values, then verifies the installed tree against the committed manifest; fresh runtime preparation must perform that installed verification.

## Public inventory: counts are not feature certification

Counts come from the exact [old][old-family] and [new][new-family] family catalogues, [new contract manifest][new-manifest] and parsed old/new OpenAPI documents.

| Inventory | 44.5.0 | 46.0.0 |
|---|---:|---:|
| Family rows / known external tokens | 89 | 90 |
| Registered / nested / redaction rows | 87 / 1 / 1 | 88 / 1 / 1 |
| Finite / parameterized / not submittable | 75 / 13 / 1 | 76 / 13 / 1 |
| Envelope-only / live-scenario / redaction-only labels | 84 / 4 / 1 | 85 / 4 / 1 |
| Standard interaction kinds / kinds used by rows | 13 / 11 | 13 / 11 |
| Interaction-conformance cases | 99 | 100 |
| Parameterized payload kinds / proposal kinds | 24 / 21 | 24 / 21 |
| HTTP path keys / component-schema names | 16 / 22 | 16 / 22 |

The only added family token is `select_move_completion_effect`: finite, `opportunity_window`, registered, envelope-only. Core owns occurrence binding, eligibility, validation, resource spending, source effects and interrupted-charge continuation; the client submits only an advertised option. See the [decision contract at line 2875][move-family] and the [producer][move-producer]. No old token was removed. `quantity_selection` and `roster_construction` remain declared interaction kinds without family rows. Four live-scenario labels do not establish four tests run here, full family coverage or a reachable complete battle. Unchanged endpoint counts do not imply compatible wire semantics.

## Required wire-family changes

These are literal discriminator changes read from the matching [schema bundle][schema-tree]. Existing strict 44.5 parsers must be adapted deliberately.

| Payload | 44.5 discriminator | 46.0 discriminator |
|---|---|---|
| Legacy create game | `create-session-v3` | `create-session-v4-private-rng` |
| Authenticated create session | `session-create-v4` | `session-create-v5-private-rng` |
| Decision request view | `decision-request-view-v5-phase17n-step4` | `decision-request-view-v6-viewer-identities` |
| Error envelope | `error-envelope-v1` | `error-envelope-v2-diagnostics` |
| Event delta | `event-delta-v5-phase17n-step4` | `event-delta-v6-viewer-identities` |
| Game view (`projection_schema`) | `game-view-v13-random-profiles` | `game-view-v14-viewer-identities` |
| Lifecycle status | `lifecycle-status-v4-phase17n-step4` | `lifecycle-status-v5-viewer-identities` |
| Command envelope | `session-command-envelope-v2-weapon-instances` | `session-command-envelope-v3-viewer-identities` |
| Command outcome / result | `session-command-outcome-v44-contract` / `session-command-result-v44-contract` | `session-command-outcome-v46-contract` / `session-command-result-v46-contract` |
| Session metadata | `session-metadata-v44-contract` | `session-metadata-v46-contract` |
| Session projection | `session-projection-v9-random-profiles` | `session-projection-v10-viewer-identities` |
| Operator session persistence | `session-persistence-v35-target-aware-attack-groups` | `session-persistence-v37-contract46` |
| Replay | `replay-artifact-v36-target-aware-attack-groups` | `replay-artifact-v37-private-rng` |

The create JSON-schema IDs also move from `/v3/create-session.schema.json` to `/v4/`, and `/v4/session-create.schema.json` to `/v5/`. Session metadata now requires major 46 and permits `last_activity_at` to be either a timestamp or null. For non-omniscient viewers the producer emits null. Metadata, checkpoint, outcome and projection must still agree on their own viewer, revision, hash and cursor; loosening identity validation is not an adoption strategy. See [metadata schema][metadata-schema] and [metadata producer at lines 741–781][metadata-code].

### Operator creation and private randomness

For authenticated `POST /sessions`, the canonical candidate fixture is [contracts/examples/sessions/session-create.json][session-create-example]. Its discriminator is `session-create-v5-private-rng`. The separately named `create-session.json` fixture belongs to the legacy `POST /games` family and is not a substitute discriminator.

The HTTP payload **requires** `config.private_rng_seed`: exactly 64 lowercase hexadecimal characters, independent of public game identity. The [configuration schema][create-schema] requires it; [server.py lines 895–910][create-code] validates the canonical request before deserializing `GameConfig`. Omitting the field over HTTP does not invoke Python's fresh-construction default. Direct fresh Python `GameConfig` construction has a `default_factory` at [game_state.py line 583][config-code], while payload restoration explicitly reads the seed at line 718.

The [45-to-46 migration][migration46] says current restoration rejects absent, mismatched or malformed private RNG authority; there is no silent old-save migration or reseeding. Operator config, persistence and replay remain private artifacts and must not be used as player projections or logged in client receipts. Published example seeds are test fixtures. P2c must keep its fixed development scenario clearly identified; package preparation must not turn the private seed into a public UI field or claim competitive randomness from a published test seed.

### Player identity, revisions and reconciliation

The [migration][migration46] and [decision contract lines 44–96][identity-contract] define viewer-scoped request, option, event, decision-record and runtime/entity identities. Public game/player/actor/army and stable catalog IDs retain their meaning. Typed object-map keys preserve joins; declared labels/messages/reasons may render mapped references. Preserve the actual IDs issued to the authenticated submitting player. Do not reconstruct aliases, use administrator IDs for a player, or copy player-a IDs into player-b controls. Geometry commitments are recomputed over the emitted identifiers by the [projection producer lines 670–690][projection-code]. Public roster structure is unchanged in the parsed game-view schema; its identities still pass through this new viewer namespace.

For administrator views, `session_revision` retains authoritative command-boundary meaning. For player/coach/spectator views, it is the visible event count: one accepted command can advance it by several events, while hidden-only work does not advance it. The [revision producer lines 497–503][revision-code] explicitly selects the namespace. Copy the revision from that viewer's latest metadata/projection into the next command. Never infer `+1`, compare a player's revision with administrator creation/start revision, or assume player-a and player-b have the same revision after handoff.

Opaque HTTP cursors remain authenticated viewer bindings, preserved and returned unchanged. Hidden-only progress retains the existing viewer token; old cursor schemas fail closed. A genuinely expired cursor needs explicit resynchronization. Delayed spectator and retention semantics also change, but P2c does not implement spectator/event-stream UI.

Exact-command reconciliation retains its existing safety purpose. [server.py lines 720–736][command-code] returns a matching journalled command's original payload only when authorization context and envelope fingerprint match; a new command compares its expected revision against the same viewer's revision. An original receipt may precede a later freshly fetched projection. Keep the retained command ID, envelope and viewer binding until reconciled, then refresh the current projection. Do not reinterpret a historical receipt as current state or issue a new-ID retry after an unknown outcome.

At the pre-P2c client source, `LiveCoreSession.cpp` pins 44.5/build identity and metadata-v44, and its `ReadOutcome` requires exactly `expected + 1` for committed commands. `CoreBoundaryEvidence.cpp` also binds metadata/outcome-v44, string-only activity timestamps and error-v1. These are concrete adoption seams, not evidence that the existing packaged client supports 46.

### Authenticated rejection diagnostics

The new [error schema][error-schema] is a closed union: ordinary code/message, `proposal_invalid` with `kind: proposal_validation` and nonempty `{violation_code, field}` entries (field nullable), or `rule_path_unsupported` with `kind: unsupported_reason` and `reason_code`. Missing diagnostics remain missing. Only an authenticated current-request owner with submission authority receives permitted detail; wrong viewer/coach/spectator/changed authorization context stays generic. The [shared response producer][diagnostic-code] obtains redacted typed diagnostics rather than returning raw engine objects.

Preserve the distinction between HTTP 422 **error envelope** (uncommitted, same pending request/revision; corrected new command/result IDs may retry) and HTTP 422 **command outcome** (`committed:true, accepted:false`, recorded attempt with updated viewer revision and fresh request). Do not infer one from status alone. The historical [44-to-45 migration][migration45] describes these semantics; that file was removed from the new working tree during narrative cleanup, so its link deliberately binds the retained ancestor. The [current decision contract lines 8151–8170][diagnostic-contract] reports selected authenticated movement coverage, pure response assembly for unsupported/no-detail branches, and no deterministic native live uncommitted-unsupported certification. P2c must not label every former diagnostics gap universally resolved.

## Runtime and geometry implications

The selected development host remains the existing `scripts/run_phase18m_reference_server.py`; [lines 23–27][reference-runner] instantiate `AdapterGameServer()` and [server.py line 230][server-default] defaults its session factory to native `LocalGameSession`. Its Windows listener now uses exclusive socket binding. No new credential/persistence/profile CLI options appeared in this runner. Native Windows personal-development testing is still a possible bounded workflow; it does not establish numerical equivalence with Linux.

Core now separately offers an operator-selected `LinuxAuthority` / `LinuxGameSession` backend. The [README lines 301–363][linux-readme] describes the trusted installed executor, exact client/executor build match, explicit registration, profile drift failure, ownership and profile-bound checkpoint/replay artifacts. This backend does not add an HTTP decision family and is not automatically selected by the development runner. Adding a new hosting implementation or provisioning WSL/Linux is outside this adoption slice.

The [distance contract][precision] binds newly registered Linux profiles to `linux-execution-profile-v2-numerical-policy` and `legacy-binary-inch-v1`. Only that retained, unrounded legacy behavior is executable. The milli-inch half-away arithmetic foundation is **inactive gameplay**: clients must preserve `battlefield-coordinate-v1` coordinates and must not snap, round inputs, infer tolerances or relabel an old history. Geometry input/hash/cache/contact representation and all rule consumers still require coordinated future activation. Registered Linux authority is not proof of native Windows geometry equivalence; native Linux builds/rendering remain untested until the required host exists.

Creation also accepts `user_supplied_estimate`, `unverified_estimate` and `provisional_estimate` geometry evidence tokens, with explicit dimensions and evidence still required; they grant no client legality authority. The [decision contract lines 98–108][geometry-evidence] describes the boundary. Source-side Boolean LOS and terrain/path reuse changes do not add a client LOS solver or authorize approximating Core visibility.

Material data/rules changes include source-current catalog/points and faction repairs, Event Companion layouts, and explicit `secondary_vp_cap_scope` (`player_turn` or `battle_round`). The historical `secondary_max_vp_per_turn` numeric field is interpreted under that explicit scope; clients must render Core output instead of computing a cap from its name. See the [decision contract at lines 8172–8196][secondary-cap]. These are reasons to prepare current fixtures/runtime rather than relabel 44.5 content. This inspection did not audit every changed faction, AI/training producer, terrain predicate or possible battle continuation.

## Finite adoption recommendation and evidence limits

P2c should adopt the exact 46 candidate only for the existing create/start → player-a finite choice → privacy-cleared player-b handoff/choice → reopen/reconcile workflow, preserving Managed and Attach ownership. Use separate source/runtime/package directories and the exact new contract/build/resource checks. Regress same-viewer revision copying, administrator-to-player namespace transition, cross-player aliases, hidden-work stability, jumps larger than one, nullable metadata activity, malformed/wrong-major rejection, typed/generic diagnostics, and exact-command reconciliation before gameplay expansion.

Public roster UI, specialized/parameterized editors, complete setup/battle progression, remote/spectator mode, persistence/recovery across restart, new authority hosting, milli-inch activation and Linux acceptance remain later bounded work. The existing roster DTO is not a rendered roster feature. Automated/source/build checks do not satisfy visible/manual criteria; the canonical plan and PR body must own actionable identified checks and their actual results. This report supplies no runtime, build, rendered, independent-review or full-Core PASS.

[new-build]: https://github.com/SobolGaming/Warhammer_40k_AI/blob/fc52e9166ff6380b606269ce362f4f1cbc6a2835/src/warhammer40k_core/_engine_build_manifest.json
[old-build]: https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/src/warhammer40k_core/_engine_build_manifest.json
[build-code]: https://github.com/SobolGaming/Warhammer_40k_AI/blob/fc52e9166ff6380b606269ce362f4f1cbc6a2835/src/warhammer40k_core/build_identity.py#L78-L144
[old-family]: https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/contracts/examples/decisions/family-coverage.json
[new-family]: https://github.com/SobolGaming/Warhammer_40k_AI/blob/fc52e9166ff6380b606269ce362f4f1cbc6a2835/contracts/examples/decisions/family-coverage.json
[new-manifest]: https://github.com/SobolGaming/Warhammer_40k_AI/blob/fc52e9166ff6380b606269ce362f4f1cbc6a2835/contracts/manifest.json
[move-family]: https://github.com/SobolGaming/Warhammer_40k_AI/blob/fc52e9166ff6380b606269ce362f4f1cbc6a2835/docs/ADAPTER_DECISION_CONTRACT.md#L2875
[move-producer]: https://github.com/SobolGaming/Warhammer_40k_AI/blob/fc52e9166ff6380b606269ce362f4f1cbc6a2835/src/warhammer40k_core/engine/move_completion_effects.py
[schema-tree]: https://github.com/SobolGaming/Warhammer_40k_AI/tree/fc52e9166ff6380b606269ce362f4f1cbc6a2835/contracts/schemas
[metadata-schema]: https://github.com/SobolGaming/Warhammer_40k_AI/blob/fc52e9166ff6380b606269ce362f4f1cbc6a2835/contracts/schemas/session-metadata.schema.json
[metadata-code]: https://github.com/SobolGaming/Warhammer_40k_AI/blob/fc52e9166ff6380b606269ce362f4f1cbc6a2835/src/warhammer40k_core/adapters/session_protocol.py#L741-L781
[session-create-example]: https://github.com/SobolGaming/Warhammer_40k_AI/blob/fc52e9166ff6380b606269ce362f4f1cbc6a2835/contracts/examples/sessions/session-create.json
[create-schema]: https://github.com/SobolGaming/Warhammer_40k_AI/blob/fc52e9166ff6380b606269ce362f4f1cbc6a2835/contracts/schemas/create-session.schema.json#L294-L395
[create-code]: https://github.com/SobolGaming/Warhammer_40k_AI/blob/fc52e9166ff6380b606269ce362f4f1cbc6a2835/src/warhammer40k_core/adapters/server.py#L895-L910
[config-code]: https://github.com/SobolGaming/Warhammer_40k_AI/blob/fc52e9166ff6380b606269ce362f4f1cbc6a2835/src/warhammer40k_core/engine/game_state.py#L575-L718
[migration46]: https://github.com/SobolGaming/Warhammer_40k_AI/blob/fc52e9166ff6380b606269ce362f4f1cbc6a2835/contracts/migrations/45-to-46.md
[identity-contract]: https://github.com/SobolGaming/Warhammer_40k_AI/blob/fc52e9166ff6380b606269ce362f4f1cbc6a2835/docs/ADAPTER_DECISION_CONTRACT.md#L44-L96
[projection-code]: https://github.com/SobolGaming/Warhammer_40k_AI/blob/fc52e9166ff6380b606269ce362f4f1cbc6a2835/src/warhammer40k_core/adapters/projection.py#L670-L690
[revision-code]: https://github.com/SobolGaming/Warhammer_40k_AI/blob/fc52e9166ff6380b606269ce362f4f1cbc6a2835/src/warhammer40k_core/adapters/session_protocol.py#L497-L503
[command-code]: https://github.com/SobolGaming/Warhammer_40k_AI/blob/fc52e9166ff6380b606269ce362f4f1cbc6a2835/src/warhammer40k_core/adapters/server.py#L720-L736
[error-schema]: https://github.com/SobolGaming/Warhammer_40k_AI/blob/fc52e9166ff6380b606269ce362f4f1cbc6a2835/contracts/schemas/error-envelope.schema.json
[diagnostic-code]: https://github.com/SobolGaming/Warhammer_40k_AI/blob/fc52e9166ff6380b606269ce362f4f1cbc6a2835/src/warhammer40k_core/adapters/server_commands.py#L157-L187
[migration45]: https://github.com/SobolGaming/Warhammer_40k_AI/blob/9fba7dc56d9093d76bdc65019859f8904a888c53/contracts/migrations/44-to-45.md
[diagnostic-contract]: https://github.com/SobolGaming/Warhammer_40k_AI/blob/fc52e9166ff6380b606269ce362f4f1cbc6a2835/docs/ADAPTER_DECISION_CONTRACT.md#L8151-L8170
[reference-runner]: https://github.com/SobolGaming/Warhammer_40k_AI/blob/fc52e9166ff6380b606269ce362f4f1cbc6a2835/scripts/run_phase18m_reference_server.py#L23-L27
[server-default]: https://github.com/SobolGaming/Warhammer_40k_AI/blob/fc52e9166ff6380b606269ce362f4f1cbc6a2835/src/warhammer40k_core/adapters/server.py#L230
[linux-readme]: https://github.com/SobolGaming/Warhammer_40k_AI/blob/fc52e9166ff6380b606269ce362f4f1cbc6a2835/README.md#L301-L363
[precision]: https://github.com/SobolGaming/Warhammer_40k_AI/blob/fc52e9166ff6380b606269ce362f4f1cbc6a2835/docs/DISTANCE_PRECISION.md#L3-L47
[geometry-evidence]: https://github.com/SobolGaming/Warhammer_40k_AI/blob/fc52e9166ff6380b606269ce362f4f1cbc6a2835/docs/ADAPTER_DECISION_CONTRACT.md#L98-L108
[secondary-cap]: https://github.com/SobolGaming/Warhammer_40k_AI/blob/fc52e9166ff6380b606269ce362f4f1cbc6a2835/docs/ADAPTER_DECISION_CONTRACT.md#L8172-L8196
