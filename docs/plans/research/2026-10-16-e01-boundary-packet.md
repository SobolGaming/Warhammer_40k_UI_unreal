# E01-WIN-BOUNDARY: selected Core boundary proof packet

Date: 2026-10-16. Disposition: **PREPARED; executable phases NOT RUN**.
This packet refines Section 0 RQ03/RQ06/RQ08/RQ15/RQ17/RQ20/RQ23 of the
[canonical plan](../unreal-migration-plan.md). It credits completed BOOT01 and
defines the next bounded Windows proof. It does not claim full E01, M01,
G-RESEARCH, G-IMPLEMENT, rendering, packaging or cross-platform acceptance.

The owner instructed: “open the PR, commit, push, and merge the PR, then continue
with the migration plan.” **OWN13 covers this next bounded E01 continuation after
the requested PR/merge sequence; do not request repeated approval for that recorded
scope.** The coordinator owns publication and the dated authority record in the
canonical plan/AGENTS. Review this packet and its implementation before execution.
The current GitHub 403 blocks the requested publication sequence; source preparation
and packet review may proceed meanwhile. Preparation of this packet is documentation
work; its proposed scripts, native tests, environment and hosts do not yet exist
as executed evidence. Do not ask again about settled target, user modes,
topologies, diagnostic policy or deferred Linux hardware. A repository/permission
failure is a publication blocker, not evidence of runtime failure.

## Fixed inputs and actual preparation evidence

| Input | Required identity / meaning |
| --- | --- |
| Authoritative Core | `Warhammer_40k_AI@5f509724da25a2f6ded0c2739a8e7c84bdf59c91`, external Contract **44.3.33**; shared checkout remains reference only |
| Runtime | `warhammer40k-core-v2:runtime-tree-sha256-v1:65fc8414407ae5d6a8ea779c8e737a22733459094db679a160c60f6e2129f96a`, 3,116 resources |
| Legacy comparison | `Warhammer_40k_UI_arcade@5088c1c49dcaff29eb59fb64b3063d30214dde73`; its Core 44.1 pin remains separate; the owner's `Warhammer_40k_UI` means this checkout |
| Unreal | Existing `WarhammerClient.uproject`; BOOT01 UE5.8.3 / CL58210709, Windows x64, MSVC14.44.35229 and SDK10.0.22621.0 |
| Available Python tool | `C:/Users/Rabid/AppData/Roaming/uv/python/cpython-3.14.5-windows-x86_64-none/python.exe`; do not use global Python3.12 |
| Available package tool | `C:/Users/Rabid/.local/bin/uv.exe`; inspected local `sync --help` supports the flags below; no new uv/Python installation |
| Selected host | Existing `Warhammer_40k_AI/scripts/run_phase18m_reference_server.py`; fixed development principal registry, in-memory state, loopback only in this proof |
| Linux | Required target remains configured; all Linux execution **NOT RUN**, owner supplies host later |

The coordinator ran the existing `build_engine_build_identity.py --check` using
the above interpreter with `-I -B`: exit 0 and the exact selected build identity.
The interpreter printed `Failed to find real location`; preserve that advisory
beside the successful result. This verifies the **source** runtime inventory,
not an installed package, native dependency loading or a running HTTP server.

The existing [source fixture manifest](../../../tests/migration/fixtures/5f509724da25a2f6ded0c2739a8e7c84bdf59c91/manifest.json)
records 127 selected source/schema/example/identity files with actual checkout-byte
SHA256 and Git blob identities, the 98 case IDs, and `RuntimeCasesExecuted: 0`.
Core's committed contract manifest declares 234 `file_sha256` members; the 127-file
inventory is not a claim that all 234 canonical hashes or schemas were validated.
Treat it as a frozen source inventory. A missing member, different HEAD, dirty
Core, changed byte hash or changed Git blob fails preflight; do not refresh the
manifest automatically to accept drift. Hash the manifest itself in each run.

Source inspection found no Core `.venv` and no exact Unreal Core environment.
Arcade's `.venv` has a different installed Core provenance and lacks the selected
`jsonschema`, `referencing` and `z3-solver` dependencies. Its environment is not a
reuse candidate and must not be synchronized. The inspected uv wheel cache also
lacks those three: an offline preparation success cannot be promised.

Current additional source hashes are recorded below. `Normalized SHA256` means
UTF-8 source text with CRLF/CR converted to LF, with no other text changes;
execution must also capture raw-byte hashes. Core's contract builder hashes
`read_text(encoding="utf-8").encode("utf-8")`, so distinguish canonical manifest
hashes from checkout bytes. Never change a copied fixture to hide this difference.

| Core path | Normalized SHA256 |
| --- | --- |
| `uv.lock` | `51896fa6800d7bbb5c6dfe08a8c7155640ec71842fafe9d78020b6a36b43e0aa` |
| `pyproject.toml` | `b0fed8cc1f2a25bec5821a96f50e0d7da47ec5e9e8e17df528cd6f69c6d67192` |
| `contracts/manifest.json` | `3723e0bf79cc163c521f6c7636d903aef987237431116cc128539366849d7e66` |
| `src/warhammer40k_core/_engine_build_manifest.json` | `b3f45468657d97f8242ecfb4f49e5fa8becfca8b2f6957721228fb44d04a1f6f` |
| `scripts/run_phase18m_reference_server.py` | `4b20a9e281e1b44f2aaac3d3badc4328592f54a789abc6c7646089ce24a595a7` |

## Bounded file and process scope

The following are the complete proposed authored implementation paths for this
packet, relative to `Warhammer_40k_UI_unreal`. They are a file contract, not a
claim that these files are already present. Stop and revise the packet if the
small proof needs materially broader architecture.

| Paths | Permitted purpose |
| --- | --- |
| `scripts/migration/Invoke-E01BoundaryProof.ps1` | Phase coordinator; path/collision/source guards, bounded owned child processes, environment isolation, sanitized logs and result manifest |
| `scripts/migration/e01_boundary.py` | Exact-source/schema/native-dependency preflight; public-facade/in-process/HTTP scenario driver; JSON Schema validation; viewer-safe evidence capture; no new server implementation |
| `tests/migration/test_e01_boundary.py` | Standard-library `unittest` checks for the proof's envelope/outcome/redaction/evidence code; real protocol fixture cases, no fake engine integration result |
| `Source/WarhammerClient/Private/Migration/CoreBoundaryEvidence.h` and `.cpp` | Small native protocol evidence reader/classifier preserving typed JSON and opaque identities; no gameplay, world, new host or production transport coordinator |
| `Source/WarhammerClient/Private/Tests/CoreBoundaryEvidenceTests.cpp` | Real nonempty Unreal Automation tests under `Warhammer.Migration.E01Boundary`; consume versioned canonical and actual sanitized wire fixtures |
| `Source/WarhammerClient/WarhammerClient.Build.cs` | Add private `Json` dependency only if required by those native tests; retain runtime/editor separation |
| `tests/migration/fixtures/5f509724da25a2f6ded0c2739a8e7c84bdf59c91/manifest.json` | Preserve existing source records; append separately named executed-run references/status only after execution and review; never rewrite old hashes/case IDs to make drift pass |
| Same fixture directory: `contracts/<member>` | Immutable copies of only `contracts/` paths named in the existing 127-entry source inventory, including the selected contract manifest; retain relative paths and original bytes; no old Arcade gzip checkpoints or unlisted contract expansion |
| Same fixture directory: `wire/index.json`, `wire/<case-slug>/<role>.json` | Reviewed credential-free canonical-session wire captures; filename slugs restricted to ASCII letters/digits/underscore/hyphen, original full case IDs retained in the index, no arbitrary supplied path names; index lists every file/hash/role/recipe and whether real HTTP, local or synthetic negative |
| `docs/plans/evidence/2026-10-16-e01-boundary.md` and `2026-10-16-e01-boundary-result.json` | Actual commands, counts, outcomes, identities, review links and limitations after execution |
| `docs/plans/research/2026-10-16-e01-boundary-review.md` and `2026-10-16-e01-boundary-acceptance-audit.md` | Separate frozen-candidate code review and evidence/acceptance audit |

The coordinator owns changes to README, AGENTS, the canonical plan and their
authority/status links. No new plugin/module graph, Content assets, Blueprint,
YAML dependency, renderer, camera, HUD, packaged target, CI/service configuration,
Core/Arcade source/dependency/history or shared environment belongs to this packet.

Generated/install outputs are limited to:

- A fresh `.local/core-44.3.33/` environment and provenance record. Refuse a
  preexisting unverified environment; a subsequent phase may reuse only the same
  verified one with unchanged installed identity/lock/source hashes.
- `.local/experiments/E01-target/<UTC-yyyyMMddTHHmmssZ>-<8-hex>/`: source archive
  and extracted source copy, package/build/HTTP/native logs, temporary files,
  private role-separated raw responses, shutdown markers, cache, result manifest
  and source/review hashes. Nothing under either sibling is an output.
- Existing ignored Unreal `Binaries/`, `Intermediate/`, `Saved/` and normal
  documented per-user build caches; no global compiler/IDE/UBT configuration edit.
  Export automation reports to the unique run directory.

Resolve absolute paths, ensure every output is inside its intended approved root,
reject reparse points/path traversal, and collision-check before writing. Never
delete a failed run to retry. Cleanup may remove only an explicitly selected
packet-owned path after checking its resolved absolute boundary; no shared cache
purge, environment replacement, engine deletion or recursive sibling operation.

## Proposed phase commands and environment preparation

These are **future commands for the reviewed coordinator**, not checks already
run or a currently available executable suite. The coordinator must implement the
named phase arguments and process bounds before these can be used. Run from the
Unreal repository root; use one unique run ID for the phases and freeze the
candidate's Git base/head or base plus full content hashes before execution.

```powershell
$taskRunId = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ') + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
& ./scripts/migration/Invoke-E01BoundaryProof.ps1 -Phase Preflight -RunId $taskRunId
& ./scripts/migration/Invoke-E01BoundaryProof.ps1 -Phase PrepareRuntime -RunId $taskRunId
& ./scripts/migration/Invoke-E01BoundaryProof.ps1 -Phase Capture -RunId $taskRunId
& ./scripts/migration/Invoke-E01BoundaryProof.ps1 -Phase Native -RunId $taskRunId
& ./scripts/migration/Invoke-E01BoundaryProof.ps1 -Phase Audit -RunId $taskRunId
```

Each phase checks its predecessor's explicit success, source/candidate/fixture
hashes and environment provenance. A failure does not start subsequent phases.
`Audit` gathers and verifies evidence; it does not substitute for independent
human/agent code review or acceptance audit.

1. **Preflight:** verify clean selected Core HEAD and frozen inventory; preserve
   Arcade status without changing it; inspect actual Python/uv/UE/compiler paths,
   disk space and any existing runtime ownership. Verify all canonical member
   hashes and case count/IDs, distinguishing actual checkout bytes from Core's
   normalized text hashes. Validate all 234 committed contract hashes read-only;
   copy only the selected inventory's allowed fixtures. Record this as a new check,
   separate from the existing 127-file source inventory. No install, implicit uv
   sync or host launch occurs here.
2. **PrepareRuntime:** use `git -C <Core> archive --format=zip --output=<run>/core-source.zip
   5f509724da25a2f6ded0c2739a8e7c84bdf59c91` to read committed objects into the
   packet. Verify every archive entry stays beneath a fresh `<run>/source/`, reject
   absolute/parent/reparse entries, then extract. Hash archive, extracted lock,
   pyproject, launcher and fixture sources. This copy is disposable install input;
   the shared Core checkout is never a build/output directory.
3. The owned install child receives `UV_PROJECT_ENVIRONMENT=<Unreal>/.local/core-44.3.33`,
   `UV_CACHE_DIR=<run>/cache/uv`, `TEMP`/`TMP=<run>/tmp`,
   `PYTHONDONTWRITEBYTECODE=1`, and `UV_PYTHON_DOWNLOADS=never` in its own environment.
   Clear inherited GitHub credentials and package-index overrides from that child;
   use only the selected public package index and archive metadata. Do not change
   the parent shell, user environment or uv/Python global configuration.
4. The reviewed coordinator runs the following equivalent uv arguments, with
   absolute arguments passed as arguments, never through string-built shell code:

```text
C:/Users/Rabid/.local/bin/uv.exe sync --project <run>/source --locked --no-editable --no-default-groups --python C:/Users/Rabid/AppData/Roaming/uv/python/cpython-3.14.5-windows-x86_64-none/python.exe --no-python-downloads --cache-dir <run>/cache/uv --default-index https://pypi.org/simple --no-config --no-progress
```

This is a **new isolated runtime dependency installation**, including the selected
package/native dependencies from the committed lock; it has not run. It installs
no new Python, compiler, engine, npm package or developer/test dependency group.
Do not use `uv run` against the shared Core, `uv sync` in either sibling, pip
installation into Arcade, or a different Core tip. Network/package unavailability,
unsupported wheel, changed lock or native load failure is a typed preparation
failure; never fall back to a mismatched installed Core or private source import.

5. Verify with `uv pip check --python <runtime>/Scripts/python.exe`; record the
   full installed name/version inventory, lock/archive/source hashes, wheel/build
   provenance and resolved package path. From `<run>/outside-source`, use the
   isolated interpreter `-I -B`, without `PYTHONPATH`, to call
   `warhammer40k_core.build_identity.verified_engine_build_identity()`. Require the
   exact selected ID and 3,116 resources; require `warhammer40k_core.__file__` under
   this environment, not source or Arcade. Import the selected native/runtime
   dependencies, including `orjson`, `msgspec`, `pydantic`, `shapely`, `numpy`,
   `jsonschema`, `referencing` and `z3`; record their versions/load results. Package
   version `0.1.0`, a successful import alone or `pip check` alone cannot pass.
6. **Capture:** run the new harness and its standard-library `unittest` cases with
   that exact interpreter using `-I -B`. The harness takes explicit absolute
   fixture/output/core-launcher paths, not the process working directory. Validate
   JSON Schema references through the frozen local registry, with no network
   schema resolution. Do not execute/import Core tests or fixture generators.
7. **Native:** build once after native source is frozen, using the existing README
   Build.bat command and packet-local log/UBA paths. The equivalent automation
   invocation is below; the suite must first exist and enumerate a positive count.

```text
<UE>/Engine/Build/BatchFiles/Build.bat WarhammerClientEditor Win64 Development -Project=<Unreal>/WarhammerClient.uproject -WaitMutex -NoUBA -UBARootDir=<run>/uba -Log=<run>/native-build.log
<UE>/Engine/Binaries/Win64/UnrealEditor-Cmd.exe <Unreal>/WarhammerClient.uproject -unattended -nop4 -NullRHI -nosplash -ExecCmds="Automation RunTests Warhammer.Migration.E01Boundary" -TestExit="Automation Test Queue Empty" -ReportExportPath=<run>/automation -log=<run>/native-automation.log
```

The installed UE5.8 AutomationCommandline.cpp accepts `RunTests`/`RunTest`
(lines 610-626) and emits `Automation Test Queue Empty` with the performed count
only after its command queue completes (lines 117-125). Use completion-driven
exit; do not append an immediate `Quit`. Require exported case-level results and
nonzero matching test count, not merely exit 0. NullRHI is intentional for this pure
protocol proof and cannot establish rendered behavior. Pass the evidence fixture
root through one documented test argument/config field; no hardcoded sibling
dependency in normal application startup. Native test entry points remain behind
the applicable development automation guard.

## Sessions, ownership and bounded execution

Every install/build/test/owned-host process has a **30-minute maximum** measured
by the coordinator. Use redirected live logs and periodic progress; do not block
communication on one long uninterruptible wait. HTTP defaults for this proof:
3-second connect, 10-second socket read, 30-second total request deadline,
16 MiB request and 64 MiB response ceilings, one authoritative command in flight,
at most 256 setup/action submissions per scenario and eight event pages of at
most 100 visible events each. Record actual largest bodies and latency; exceeding
these values fails with transport/unknown-outcome evidence and ends that lane.
They are proposed measured proof bounds, not established production budgets.

Launch only the existing selected host, with the verified interpreter:

```text
<runtime>/Scripts/python.exe -I -B C:/SWDev/warhammer/Warhammer_40k_AI/scripts/run_phase18m_reference_server.py --host 127.0.0.1 --port <explicit-positive-port> --shutdown-file <run>/managed-<unique>/shutdown
```

Use an owned hidden-window process with an argument array, current directory
under the run, and bytecode-disabled child environment. Record executable/script
hash, PID/start time and process handle. Select a currently unused positive port,
then fail visibly if binding races; port 0 has no supported endpoint discovery
handshake here. Do not attach to an unexpected responder. Authenticated global
catalog 200 within 30 seconds plus child-alive checks establishes readiness only;
it does not establish exact build identity. Verify selected local provenance
before launch and verify returned session metadata after create. No invented
`/health`, pre-create version or credential provisioning route.

Use separate fresh in-process and HTTP sessions for the matching canonical
scenario. Preserve the same config, recorded choices and random outcomes; record
any unavoidable transport-only normalization explicitly. A second independent
owned host may be used when the same game ID must be replayed without collision.
Never share an active mutable session between agents or parallel writers.

For the attach proof, the supervising coordinator holds the host process and
creates a separate disposable canonical session through an explicit admin context.
An independently invoked attach worker receives only endpoint, supplied session
ID and its scoped player/read-only credential. It neither creates/closes the
session nor acquires the process handle/shutdown path. Prove it can read, submit
its offered action when authorized, disconnect, and leave the host/other session
alive. This proves attach ownership on loopback, not Internet/TLS deployment.
Never test against an unrelated user's service/session by guessing identifiers.

Only the supervisor may close its own disposable sessions with its explicit
administrator context. Normal shutdown writes that host's unique shutdown file,
waits ten seconds, and closes its own handles. On timeout, stop only that owned
process tree after rechecking PID/start identity; no process-name or port-owner
kill. Preserve failed artifacts. Attach exit never signals/stops the host.
Restart one owned development host and prove its old session is lost; report
`SessionLost`, do not recreate the old ID or replay an uncertain command into a
new session. In-memory idempotency is not durable restart recovery.

## Meaningful case matrix and pass/fail

All case IDs below must have explicit actual status, count, command/fixture
hashes and role-scoped artifacts. No empty suite, skipped missing fixture,
schema-only success, stationary/no-op move or synthetic response passes a live
case. Failed/unavailable canonical procedures become exact blockers; never edit
Core, inject decisions, adjust engine state or add a private route to finish.

| Case group | Required proof / failure condition |
| --- | --- |
| `SOURCE-01` | Source and installed identities/127-member inventory agree; 98 canonical case IDs are present once each: 73 top-level finite, one nested finite, 24 parameterized. Catalogue consumption is shape coverage, not 98 live workflows. The source-reposition envelope-only example stays labelled synthetic/envelope-only. |
| `FINITE-01` | Public canonical setup reaches an actual visible finite request. Select only an offered option under its bound player, preserving exact request/option/result/command IDs and expected revision. Match same-build local/HTTP authorized outcomes and refresh after acceptance. No admin gameplay submission, invented option or auto-following hidden next actor. |
| `MOVE-01` | Public setup reaches normal-move proposal. Submit a complete ordered witness for every current placed living physical model in the request's canonical unit; retain current request/spatial/source IDs, pose/facing/Z and sequential order. Choose the canonical one-inch translation candidate and require Core acceptance plus at least one authoritative projected position change. A rejected candidate is evidence, not permission to rewrite legality or call it PASS. Compare local/HTTP action trace and allowed before/after views under identical inputs. |
| `MOVE-02` | Wrong/missing/duplicate witness inventory is uncommitted: preserve visible revision/current request/history evidence and show actual HTTP status/code/message. A well-formed rule-invalid geometric witness must exercise its recorded-invalid branch with committed revision/history and fresh retry request. Then submit a reviewed current complete valid witness successfully. Do not assume every 422 has the same retention semantics. |
| `RETRY-01` | Exact same complete command envelope and credential scope retries byte-equivalently on the same running HTTP host and applies once. Changed payload under same ID conflicts. A simulated lost response after a real committed request retains the envelope and reconciles the same ID; label the injected response loss. Reusing a later journaled outcome never rolls the displayed current revision backward. |
| `STALE-01` | Wrong revision, consumed request and waiting-decision advance produce their actual typed conflict/rejection, with no unauthorized client choice. Refresh authority before corrected intent; never fix by silently changing IDs/revision inside an uncertain retry. |
| `AUTH-01` | Missing/invalid bearer, wrong bound player, forged viewer claim, coach/spectator decision, administrator gameplay decision and live replay-viewer access deny with the shared scoped error policy. Check no hidden request IDs/options/event counts leak in bodies or diagnostics. PlayerA/B, coach, delayed spectator, admin and replay-viewer use distinct explicit contexts. |
| `VIEW-01` | Player/opponent/coach views and event pages obey selected policy; delayed spectator observes its server-provided one-revision delay and scoped cursor. Admin omniscient evidence stays in a separate privileged lane. Replay-viewer live access denies; terminal/closed replay policy uses a separate allowed canonical completion procedure or remains explicitly NOT RUN if unavailable. No forced private terminal-state mutation. |
| `ERROR-01` | Malformed 400, forbidden/auth failures, conflict 409, both 422 wire shapes and unavailable route retain actual status/code/message. The existing support-profile route is not invented. An action accepted before later unsupported advancement remains accepted according to explicit flags. `accepted:true, committed:false`, missing/null/wrong-type fields and malformed JSON fail native classification visibly. |
| `FIDELITY-01` | For the live uncommitted proposal rejection, display exact HTTP status/code/message and: detailed engine reasons were not supplied by this HTTP response. Link Core issue #588. Never report an in-process fine-grained inventory reason as wire-visible, infer a replacement rules reason or fetch privileged details through another route. |
| `SCOPE-01` | Pure client evidence/reducer tests switch viewer/session generation with outstanding responses, reject stale callbacks and invalidate old cursors/drafts; prove no old-view data enters the new scope. This is deterministic client state evidence, not actual UE network scheduling proof. |
| `LIFETIME-01` | Busy port/readiness failure bounded; attach disconnect leaves owned server/other session alive; managed stop affects only owned process; restart shows explicit old-session loss. Credentials/build mismatch never falls back to another principal/runtime. |
| `NATIVE-01` | Nonempty native automation consumes all 98 canonical envelopes and selected actual wire fixtures, preserves opaque string IDs/order/null/JSON types, classifies both 422 shapes and error states, and rejects missing/wrong-type/invalid flag combinations. Numeric identities/revisions outside the reader's exact representable integer range fail explicitly rather than rounding. It does not claim a full Draft 2020-12 validator or implemented UI editors. |

The one-inch movement recipe is sourced from legacy
`tests/test_live_core_smoke.py:_ready_live_core_normal_move_payload` and must be
recreated against selected Core, not executed through Arcade's mismatched
environment. Selected Core recipes/tests to trace before implementing the driver:

- `scripts/external_contract_session_examples.py:phase18e_session_examples` and
  `adapters/setup_smoke.py:canonical_setup_prebattle_smoke_config` produce the
  committed `contracts/examples/sessions/session-create.json` from real state.
- `adapters/contracts.py:AdapterGameSession` and
  `adapters/server.py:AdapterGameServer.handle` supply local facade/public command
  paths. Local `GameConfig.from_payload` may decode the same frozen creation config;
  only public facade start/advance/submit/view/history APIs are allowed. HTTP
  commands use `/sessions/{id}/commands`, with separate admin lifecycle/player
  decision credentials. No direct lifecycle/queue/decision-controller access.
- `tests/shared/category_migration/phase18f_session_commands.py:`
  `_advance_to_movement_selection`, `_deployment_payload_from_proposal` and
  `_invalid_distance_witness`; read as recipes, do not import private test helpers.
- `tests/infrastructure/adapters/unit/test_session_commands.py:`
  `test_phase18f_duplicate_http_commands_are_byte_equivalent_after_reconnect`,
  `test_phase18f_well_formed_illegal_proposal_is_uncommitted_and_retryable`,
  `test_phase18f_recorded_invalid_retry_is_atomically_journaled`.
- `tests/integration/test_movement_witness_membership.py:`
  `test_native_wrong_witness_inventory_is_atomic_with_legal_retry_and_continuation`
  and `test_native_rule_invalid_geometry_still_records_attempt_and_emits_fresh_retry`.
- `tests/unit/test_phase18g_18h_session_security.py:`
  `test_phase18h_derives_live_visibility_and_delay_from_server_owned_roles`,
  `test_phase18h_enforces_mutation_replay_support_and_viewer_claim_policies`,
  `test_phase18h_auth_failures_share_one_redacted_shape_and_ignore_legacy_header`,
  `test_phase18h_event_redaction_hides_secret_counts_and_uses_viewer_sequences`,
  `test_phase18h_idempotent_retry_requires_exact_current_authorization_context`.

These are immutable references to Core `5f509724...`; they are source recipes,
not a claim that this packet has run its tests. Core's TypeScript conformance
client is additional source evidence only: it has no installed node_modules here
and explicitly omits coach, delayed spectator and live rejected unsupported
coverage. Do not run npm install/test or reproduce its implicit uv launch.

## Evidence, redaction, review and closure

The harness imports public default development credential **constant names** only
in its private test process. Never persist token values, token hashes,
Authorization headers, complete environment dumps, credential-bearing command
lines/URLs or workspace GitHub credentials. Role labels and a credential-scope
generation ID are enough for traces. Secret scan/redaction precedes every log
export, hash manifest and proposed commit. A scanner rejection quarantines output;
it does not replace the fact with a successful redaction claim.

Separate playerA/playerB/coach/delayed/admin/replay output directories and index
permissions. A permitted diagnostic comparison may privately read an admin
baseline, but the public/player fixture contains only authorized derived
assertions, not the omniscient body or hidden counts. Review all committed wire
fixtures for viewer safety; raw session/cursor/private outputs remain ignored.
Canonical published opaque IDs/hashes can remain intact; do not recompute Core
projection/spatial/catalog hashes after reserialization or anonymize authoritative
IDs while claiming byte-equivalent replay. Mark local/synthetic error fixtures
distinctly from actual HTTP captures.

The result manifest records UTC/run ID; approved phase/candidate and script
hashes; exact source/installed/runtime/schema/fixture/lock identities; interpreter,
uv, engine/compiler/SDK; process ownership/start/exit/timeout; sanitized actual
commands; discovered/executed/passed/failed/skipped case counts; each expected and
actual outcome; role/viewer/session scope; measured body/latency bounds; artifact
hashes and redaction disposition; before/after sibling cleanliness; and independent
code-review/acceptance-audit frozen manifests. Preserve failed attempts append-only.

Freeze authored sources and accepted fixture candidates before separate code
review; resolve actionable findings. After execution, freeze results and obtain a
separate acceptance audit mapping each required row to actual evidence. Any source
change invalidates the affected code review/run rather than silently inheriting
the previous PASS. A blocked case is never counted as passed.

Report phase-specific statuses: `SOURCE_INVENTORY_PASS`, `INSTALLED_RUNTIME_PASS`,
`LOCAL_HTTP_BOUNDARY_PASS`, `NATIVE_FIXTURE_PASS`, or exact `FAIL/BLOCKED/NOT_RUN`.
E01-WIN-BOUNDARY passes only when its required meaningful finite/movement,
error/retry/auth/viewer/process rows and independent reviews have evidence; an
unavailable full terminal replay case stays explicitly outside this subset and
cannot close full E01. Source-only checks do not establish installed/native/HTTP
results. Native fixture tests do not establish UE HTTP callbacks, UI input,
world rendering, packaged loading, remote TLS/security or real role controls.
Python HTTP success does not establish a functioning native UE transport.

The next architecture lane must still prove actual Unreal transport/scheduling,
E02 3D transforms/picking and E04 HUD/parser feasibility before broad dependent
implementation. E08 keeps the remaining per-variant real captures and full
behavioral parity; consuming all 98 envelopes does not close them. E03A/E03B,
standalone/offline delivery, Linux, durable recovery, performance and final release
remain separate acceptance work. The existing development host's limits and
[Core issue #588](https://github.com/SobolGaming/Warhammer_40k_AI/issues/588) remain
visible regardless of this subset's eventual result.
