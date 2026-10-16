# Selected session, role and failure design closure

**Date:** 2026-10-16. This packet closes source/design portions of RQ02/RQ03/
RQ04/RQ06/RQ15/RQ17 for the selected development route. Runtime verification
remains unexecuted and is mapped to E01/E03 below. It creates no source, tests,
scripts, installation, running host or new host implementation.

The owner selected Core commit
`5f509724da25a2f6ded0c2739a8e7c84bdf59c91`, contract `44.3.33`, runtime build
`warhammer40k-core-v2:runtime-tree-sha256-v1:65fc8414407ae5d6a8ea779c8e737a22733459094db679a160c60f6e2129f96a`,
and the existing `scripts/run_phase18m_reference_server.py`, with managed local
launch and attach, local/remote/spectator modes and personal/internal use.
Windows is the available native host; Linux project plumbing is required but
actual Linux execution is owner-deferred, **NOT RUN**. The checked-out host's
fixed development credential registry, nonpersistent state and missing release
hardening are accepted development limitations, not reasons to invent a host
or block all development. See [adaptation/launch evidence](2026-10-16-contract-44-3-33-adaptation.md).

`Core` references expand to
`Warhammer_40k_AI@5f509724da25a2f6ded0c2739a8e7c84bdf59c91:path:symbol`.
Abbreviated `adapters/` paths are beneath `src/warhammer40k_core/`; other paths
are repository relative. No development credential values appear in this packet.

## Fixed target and identity change control

- Only the human owner approves a new core target. Do not follow sibling HEAD,
  tags, dependency resolver updates or a newer contract automatically. A target
  change requires a recorded commit/build/contract/schema/fixture delta review,
  affected parser/interaction/recovery tests and refreshed evidence before use.
- Namespace legacy source/fixtures as `arcade-core-44.1-fc12fa` and selected
  fixtures as `unreal-core-44.3.33-5f5097`. Keep original IDs, source bytes,
  hashes and runtime provenance within each set. These are proposed evidence
  namespaces, not renamed files or a compatibility converter.
- Current Arcade remains pinned to Core44.1. Do not edit its guard, install
  44.3.33 into its environment, reset the shared Core checkout or relabel its
  exact-build gzip checkpoints. The new client validates the selected build
  independently; package version `0.1.0` alone is insufficient.
- Separate transport revision, viewer projection hash, spatial context hash,
  ruleset/catalog/source identity and command identity. Preserve opaque fields
  exactly. Never recompute a core hash from differently serialized C++ JSON.

## Role, mode and operation matrix

The authority below is source-established in
`Core:adapters/access_control.py:ROLE_POLICY_BY_ROLE` (68-128),
`AuthenticatedPrincipal.bind_to_session` (157-176),
`Core:adapters/server.py:_handle_protocol_session` (601-681),
`_execute_protocol_command` (683-790), and
`Core:adapters/server_authorization.py:require_replay_export_allowed` (22-31).
Client UX must preserve these policies; a player ID field is never a login.

| Principal/role | Metadata, projection, events | Global/session catalog | Create; start/advance/close | Finite/proposal decision | Raw replay export | Intended presentation |
|---|---|---|---|---|---|---|
| `player` | Own bound-player view, current revision | Yes | No; no | Only current pending request owned by that bound player | No | Local or remote participant; act only when authorized request is visible |
| `coach` | Bound player's view, current revision | Yes | No; no | No | No | Read-only coach surface; no Submit controls |
| `delayed_spectator` | Role-scoped delayed view/events, default one revision behind | Yes | No; no | No | No | Initial spectator policy uses the server's existing delayed role; label the delay |
| `administrator` | Omniscient privileged view, current revision | Yes | Yes; yes | **No** | Yes, including active session | Separate developer/session administration context, visibly privileged; never the default participant view |
| `replay_viewer` | No live metadata/projection/events | Yes | No; no | No | Only terminal/closed session | Non-live replay/export context with externally supplied session ID; not a live spectator |

The policy contains `may_view_support`, but normative `/sessions` has no separate
support-profile route. Do not imply that permission creates an endpoint. Existing
support/capability data must come from documented returned payloads, or a missing
required separate operation remains an external API gap. Likewise, no session
listing, token issue/refresh, principal switch or host-management endpoint exists.

| Selected product/connection mode | Coordinator design |
|---|---|
| Managed local participant | Start the selected checked-out development host with the selected installed Core; use a distinct administrator credential context to create/start if needed, then a player credential context for gameplay. Admin permission cannot submit a player's choice. |
| Local player switching | Explicitly switch to another supplied player credential and rebuild that viewer's state. This supports deliberate local handoff; it does not auto-follow the next actor or reveal the former viewer's hidden choices during switching. No separate AI or automatic opponent is implied. |
| Attach local/remote participant | User/operator supplies endpoint, session ID and appropriate credential. Client connects and verifies selected contract/build. No process, service configuration or session ownership is acquired merely by attaching. |
| Spectator/coach | Attach using the corresponding existing read-only principal policy; suppress draft/submit affordances. The delayed-spectator revision is that viewer's authoritative snapshot, not the participant's latest revision. |
| Developer administration | Separate explicit context for create/start/advance/close and privileged inspection. Dispose its data when returning to a participant; do not reuse an omniscient projection in gameplay. |
| Replay viewer | Export only when server policy permits. Live game snapshots and opaque cursors are not replay artifacts. Preserve the exact-runtime binding of exported data. |

The reference registry provides fixed development principals. Supplying different
token environment variables to the TypeScript conformance client does not change
this host's registry. A remote operator must supply a reachable approved endpoint
and matching credentials; selecting remote mode does not prove TLS, credential
provisioning or safe public exposure. Those limitations stay visible in the
internal development documentation and later remote acceptance.

## Session/viewer switching and asynchronous lifetime

Use a game-instance coordinator for endpoint/authentication/session state, with
world presenters rebuilt from current viewer-safe values. Each asynchronous
operation carries a monotonically increasing local generation, the selected
endpoint/session and opaque local credential handle, returned role/player/delay
scope, request ID where applicable, and expected revision/hash context. The wire
metadata does not publish a principal ID or authorization epoch; do not invent
those fields. The server's opaque cursor already binds its private authorization
context (`Core:adapters/access_control.py:ViewerContext` 180-241;
`adapters/session_protocol.py:VisibilityPolicyPayload/SessionMetadataPayload` 85-115).

Changing endpoint, session, credential or active viewer increments the generation,
cancels outstanding operations, disables submission and discards projections,
events/cursors, selected options, drafts, diagnostics, selection/highlight,
tooltip/roster/HUD caches and pending asset callbacks derived from the old scope.
Do not show the old scope's last frame beneath a loading overlay for a new viewer.
For an ordinary disconnect within the same scope, the last confirmed view may
remain visibly disconnected and read-only; no predictions become authoritative.
If a command was already OutcomeUnknown during a switch, quarantine its exact
envelope in an undisplayed old-scope ledger. It may be reconciled only after
explicitly returning to that credential/session scope; it is never submitted or
rendered under the new viewer. A known nonpersistent host restart instead marks
that command/session lost and forbids replay into a fresh game.

Key presentation/cache data by endpoint, session, local credential generation and
role/player/delay scope. Keep catalog source identity in its cache key too.
Sharing immutable presentation artwork is fine; sharing viewer-derived entity
content requires evidence that it is public. Session closure, privilege changes
and world teardown unsubscribe observers and invalidate obsolete callbacks.
UObject/widget/world changes occur on the game thread after generation checks.

Within a generation, an older response cannot replace a newer confirmed revision.
An exact-id retry may legitimately return its historical journaled outcome after
later commands have committed: record that command's resolution, but refresh the
current projection instead of regressing the display. Same-revision cursor/hash
divergence requires resynchronization, not an invented ordering rule. For delayed
spectators use the returned delayed revision; never reject it merely because a
participant elsewhere has a larger revision.

## Lifecycle and command outcome transitions

Server transport states are exactly `created`, `active`, `terminal`, `closed`
(`Core:adapters/session_protocol.py:SessionState`, 73-77). Client connection and
pending-command states are separate; a timeout is not a game-terminal result.

| Client state/trigger | Next state/action |
|---|---|
| Disconnected; connect or managed launch | Connecting; bounded process/HTTP readiness, authenticate and verify available exact identity |
| Connected with supplied session identity | Synchronizing; fetch role-allowed metadata/projection/catalog and establish the supplied opaque cursor |
| Current snapshot and compatible identity | Ready; player can draft only a current authorized request; other roles remain read-only |
| Submit current intent | CommandPending; freeze canonical envelope/command ID/result ID and disable duplicate submission |
| Connection loss/timeout before a conclusive response | OutcomeUnknown; keep the identical envelope, mark view read-only, reconcile with the same credential scope and command ID |
| Confirmed accepted outcome | Synchronizing; consume confirmed metadata/checkpoint and refresh current projection/events; do not guess an extra advance |
| Confirmed recorded rejection | Synchronizing; use returned committed revision and fresh request/diagnostics, preserve only locally useful editable intent compatible with that fresh context |
| Confirmed unrecorded rejection | Ready/Invalid; show typed reason, keep same request only if refreshed authority still matches; corrected intent gets a fresh command/result identity |
| Stale revision/request or cursor resync | ResyncRequired -> Synchronizing; discard stale readiness/context and replace derived state from full projection |
| Wrong credentials/role | AuthenticationRequired/AccessDenied; no silent fallback to admin or another player |
| Managed host exits/restarts with lost session | SessionLost; explicitly report nonpersistent state loss, never silently create a replacement game or replay an old intent into it |
| Server terminal/closed | Terminal/Closed view; preserve allowed final projection/replay/export policy; disable gameplay submissions |
| User switches session/viewer or exits | Teardown old generation; attach leaves external host running; managed shutdown touches only its own process |

All mutations after creation use `/sessions/{id}/commands`; lifecycle variants
have null request/result IDs, finite/proposal variants preserve current IDs and
typed payloads. One authoritative command is in flight per session coordinator.
Use bounded connect/read/request/response queues; no unbounded polling or retry
loop. Initial timeout/body-size values are client configuration to select and
validate in E01 against the actual catalog/config/path workload; these limits
cannot establish protection of the external server.

Exact outcome handling is source-backed by
`Core:adapters/server.py:_execute_protocol_command/_apply_protocol_command`
(683-884), `Core:adapters/server_mutations.py:commit_submission_status`
(87-112), `_submission_was_applied` (141-150), and
`Core:contracts/session-semantics.md` (95-162):

| HTTP/payload class | Meaning and required client action |
|---|---|
| 200 command outcome, `committed:true, accepted:true` | Command entered history and action applied. Subsequent lifecycle may be waiting, terminal or unsupported after advancement; the explicit flags decide application. Refresh; do not duplicate the action. |
| 422 command outcome, `committed:true, accepted:false` | Recorded invalid/unsupported attempt. Revision/history advanced; show typed diagnostics and the fresh retry request where emitted. Never reuse the consumed request. |
| 422 typed error envelope `proposal_invalid` or `rule_path_unsupported` | Uncommitted rejection; no journal entry/revision publication for this command. It is not a success-shaped outcome with invented Boolean defaults. Refresh the actual pending request before editing/retrying. |
| 400 malformed/schema rejection | Show contract/validation error; no permissive DTO fallback or automatic payload rewrite. |
| 401/403 | Shared redacted authentication/authorization denial. Do not infer hidden request counts or journal contents from it. |
| 409 revision/request/session/command conflict | Preserve diagnostic code. Refresh current authority. Same command ID with different payload is an error, not a request to edit the journal. `advance_not_required` at a waiting decision consumes no revision or ID. |
| Transport failure, 5xx or truncated/oversized/unparseable response | Completion may be unknown. Keep exact envelope and reconcile; do not assume rejection from HTTP failure. A persistence-fail-stop response matters only if a separately configured persistent host is selected later. |

`accepted:true` with `committed:false` is schema-invalid. Source chooses HTTP 200
when accepted, including an applied action reaching a later typed unsupported
boundary; do not describe that case as a rejected 422. Conversely, `committed`
does not imply rules acceptance. The HTTP 422 schema is a union of error envelope
and command outcome, so transport status alone cannot decide draft retention.

An uncertain retry retains the **same complete canonical envelope**, command ID,
request/result IDs, expected revision and credential scope. Matching journaled
commands return the original outcome; changed payload conflicts and changed
authorization denies. A new corrected intent after confirmed rejection uses new
IDs and the current request/context; it is not an uncertain retry. Do not let a
timeout allocate new IDs or let a stale response authorize a new request.

## Selected host ownership, readiness and real source gaps

Managed mode runs the exact selected checkout script using an isolated,
version-verified Core interpreter; the source/package recipes are in the
adaptation packet. It binds loopback by default. Choose an explicit positive
port and retain the launched process handle; port 0 is not a documented discovery
handshake, because the script prints the requested argument rather than supplying
the OS-selected endpoint. A busy port produces a visible bounded startup error.
Do not attach automatically to whichever unrelated process happens to answer it.

The existing conformance runner establishes readiness with an authenticated
global-catalog 200, a bounded 30-second wait and process-exit detection
(`Core:conformance/typescript/src/main.ts:waitUntilReady`, 180-204).
That proves responsive/authenticated transport, not exact engine/build identity.
For an existing session, verify returned metadata before enabling gameplay.
For managed startup, verify selected checkout/interpreter provenance locally
before launch and compare session metadata after creation. The client does not
modify the host or use the unrelated read-only fixture server's `/health`.

Only a managed process may be stopped by this coordinator. On normal managed
exit, request any explicitly authorized session close with a separate admin
context, then use that process's own unique shutdown file or controlled stop,
wait a bounded interval, and clean up only owned outputs/process resources.
An attach client only closes its connection unless the user explicitly invokes
an authorized session-admin action; it never stops/reconfigures the service.
No global process-name kill, shared shutdown file, dependency installation or
worktree movement is a recovery action.

The selected launcher has no persistence store. Shutdown/restart discards its
in-memory games; no durable-save acknowledgement can be awaited or claimed.
This is the accepted initial mode, and SessionLost is the explicit failure path.
Runtime cache/idempotency semantics are meaningful within that running host;
they do not survive its restart. A future durable host is separately selected,
owned and proven before the client promises recovery across process death.
Creating a new game starts a fresh client generation and unique game identity;
never recreate an old game/session ID automatically to make a disconnected view
appear resumed. The protocol has no independent host-incarnation identifier, so
a mere network reconnection cannot establish restart durability. Attach operators
must distinguish an existing live session from a newly created game; the client
does not replay an old uncertain envelope into an explicitly replaced session.

The following gaps are real and must not be closed by optimism:

- No separate version/readiness endpoint: attach requires an existing supplied
  session ID to read metadata, or trusted operator identity for a fresh host.
  There is no pre-create HTTP build negotiation operation.
- `POST /sessions` creation has no command envelope/idempotency key; the command
  journal covers later commands. An uncertain **creation** cannot use the command
  retry recipe. Stop automatic create retries and ask the operator to reconcile
  that admin operation; do not guess an opaque session ID or create another game.
- No session listing, credential provisioning/refresh, remote TLS configuration,
  host restart/health or separate normative support-profile operation exists.
  Use supplied configuration and documented payloads; required missing behavior
  becomes an external dependency rather than a new private route.
- Uncommitted proposal rejections lose their fine-grained engine diagnostics on
  this HTTP surface: `server.py` 757-772 returns generic `proposal_invalid` or
  `rule_path_unsupported`, and `contracts/schemas/error-envelope.schema.json`
  contains only code/message. Thus an in-process
  `movement_witness_model_inventory_mismatch` diagnostic is not automatically
  a wire-visible diagnostic of the same name. Display the actual generic typed
  HTTP rejection and preserve same-request retry semantics; local inventory
  hints must be labelled advisory. OWN10 accepts this initial fidelity gap: show
  the actual HTTP status, code and message and state that detailed engine reasons
  were not supplied. Do not fabricate a reason from client assumptions or use a
  private route. Under OWN12, [Core issue #588](https://github.com/SobolGaming/Warhammer_40k_AI/issues/588)
  was filed through `gh` and read back on 2026-10-16. It requests viewer-safe public
  diagnostics and regressions; the ticket reports source inspection, not an HTTP
  reproduction or an engine fix.
- Client timeout/body-size defaults and actual runtime scheduling/response order
  have not been measured; source protocol semantics do not prove responsive UE
  callbacks, correct native loads or actual packaged process ownership.

## Remaining empirical obligations and disposition

| Proof item | Exact E01/E03 acceptance to run after authorization | Current disposition |
|---|---|---|
| E01 role matrix | Exercise every matrix role through actual HTTP; wrong-player, coach/spectator mutation, admin decision submission and live replay-viewer access must deny with scoped errors; verify delayed snapshot/event behavior and no hidden-data leaks | BLOCKED on authorized exact-runtime execution, not missing source policy |
| E01 commands and real movement | Same exact-build local and HTTP setup/finite/complete witnessed movement; assert actual pose change, sequential order, accepted/recorded-invalid/unrecorded-invalid branches, same-ID retry, conflict and stale request/revision | BLOCKED; test source exists, no executed result claimed |
| E01 scopes/async/resync | Viewer/session/credential switches with in-flight responses, late old-revision journal outcome, cursor expiry/hash drift and delayed-spectator scope; assert teardown and no stale callback/UI leakage | BLOCKED on client proof; design above is not implementation |
| E01 transport bounds | Set and test client connect/read/size/queue limits against selected fixtures and largest supported catalog/config/path; oversize/timeouts become typed transport failure/unknown outcome, never invented rules rejection | BLOCKED; limits need measured workload validation |
| E03A selected managed/attach route | Windows minimal package/developer flow uses exact interpreter/script/build, authenticated readiness, one canonical command, visible busy-port/version/auth failures, attach never stops external service, managed exit stops only owned process | BLOCKED on authorized bootstrap/package proof; no portable artifact prerequisite added to initial development route |
| E03B actual workflow/failures | Packaged real 3D action with camera/selection/world/HUD; loss before/after response, exact retry while host lives, managed crash/restart showing SessionLost, no silent fresh game, scope-safe shutdown | BLOCKED; nonpersistent restart is tested as explicit loss, not fictitious durable recovery |
| Later durable/remote delivery | Only if separately selected: configured credential/TLS/limit/persistence owner and crash-before/after durable commit proof on supplied artifact | DEFERRED later gate; not a requirement to write a new host now |
| Linux native/render/package | Preserve Linux plumbing and reusable commands; run matching proofs when owner-arranged native/render host exists | Owner-deferred, NOT RUN; cannot be reported PASS or silently omitted at final acceptance |

Source policy and the proposed client responsibilities are now concrete enough
to close their source/design subquestions. No row above is execution approval or
an experimental PASS. Section 0's authorization gates and RQ23 uncertainty map
retain these empirical obligations independently of that source/design closure.

## EXT05 narrow closure: actual support-profile consumers

This source trace uses the unchanged legacy identity
`Warhammer_40k_UI_arcade@5088c1c49dcaff29eb59fb64b3063d30214dde73` (`UI`) and
the selected `Core` above. It does **not** establish full support-profile parity
through `/sessions`.

- **Startup/refresh dependency:** `UI:core_client/live_smoke.py:`
  `_startup_from_status` (564-605) always fetches a profile and checks its game ID;
  `render/arcade_window.py:_refresh_public_contract_data` (2598-2638) lazily
  fetches/caches one per viewer and validates game/catalog identity. The strict
  `UiSupportProfile.from_payload` parser (`core_client/protocol.py`, 635-690)
  requires support counts/rows, smoke-eligibility Boolean and capability manifest.
  Copying this facade/startup literally into HTTP would therefore fail without
  the missing operation; Unreal needs its own explicit public-source wiring.
- **Functional placement identity, not rules legality:**
  `UI:state/placement_draft.py:_public_army_id_for_player` (956-1006) reads
  `battlefield_state.placed_armies[{player_id,army_id}]` and profile
  `mustering_support_rows[{player_id,army_id}]`, requiring one consistent owner
  army and matching `game_id`/`capability_manifest.viewer_scope`. Before any army
  is placed, the profile can be the only source of that opaque army identity.
  `PlacementDraft.start_for_pending` (353-365) refuses missing identity; it does
  not decide rules legality. Live-smoke `_public_smoke_army_id` (491-525) uses
  the same two sources for setup automation. Source tests
  `tests/test_contract42_attached_prebattle.py:`
  `test_attached_deployment_requires_public_army_authority` (384) and
  `tests/test_contract42_opaque_placement.py` (120-130) explicitly reject absent,
  foreign or conflicting owner-army authority. Neither test was run here.
- **Presentation/diagnostics use:** the inspected runtime references do not
  render a separate support-profile dashboard or use `overall_status`,
  `eligible_for_headless_self_play_smoke`, status counts or capability dimensions
  to permit gameplay. The profile is exposed on the window and passed to the
  placement draft; missing data can visibly prevent drafting/startup. The
  forensic wrapper traces the already-redacted profile (`diagnostics/forensic_trace.py:`
  `get_support_profile`, 487-511). No direct HUD consumer was found by the
  repository-wide profile/capability-field reference search.

Normative metadata/projection/catalog **do not contain a semantically equivalent
full profile**: `Core:adapters/projection.py:GameViewPayload` (308-337),
`RulesCatalogViewPayload` (222-240), and
`adapters/session_protocol.py:SessionMetadataPayload` (94-115) lack the support
rows/counts, selected-content runtime status and capability manifest.
Catalog `datasheet_display_by_id[*].abilities[*].support` is catalog display
evidence, not the selected game's runtime support or any eight-dimension
capability result. Do not manufacture a `UiSupportProfile`, a supported status,
headless eligibility or a capability certificate from those display fields.

**First-slice disposition:** a newly created canonical setup/movement session
need not consume a support profile merely to start. A concrete existing public
source alternative for its required army mapping is the exact submitted
`SessionCreate.config.army_muster_requests[{player_id,army_id}]`:
`Core:conformance/typescript/src/scenario.ts:playerArmyIds` (672-693) validates
and retains that mapping, and `deploymentPayload` (695 onward) uses it to build
the existing deployment proposal through normative HTTP. This is an observed
source recipe, not an invented equivalence or a test result. Retain that exact
public creation-input mapping, bind it to the returned session/game identity,
and prove the HTTP setup/movement recipe in E01. It cannot be inferred from ID
spelling, static catalog entries, another viewer's profile or arbitrary local
preferences.

For **attach to an already placed game**, public `placed_armies` can supply the
same specific owner-army fields when present and consistent. For **attach before
first placement**, an existing-session projection alone may lack that mapping;
require the operator-supplied original public creation input with identity checks
or record that placement workflow as blocked on a public source/API extension.
Do not assume that retaining the creator's input solves arbitrary remote attach.
Exact support/capability metadata parity remains EXT05; the initial managed
canonical first slice has a source-backed alternative for the metadata it
actually needs, while undeployed attach and full support reporting retain their
explicit capability-specific gap. Core still validates every submitted choice.
