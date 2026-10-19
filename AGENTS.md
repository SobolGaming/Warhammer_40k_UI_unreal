# Unreal client repository instructions

## Scope and current authority

This repository is the C++ first Unreal client for the separately maintained Python
rules engine. Read `../AGENTS.md` and `docs/plans/unreal-migration-plan.md` before work.
The canonical migration plan and its Section 0 research register govern sequencing.
The owner approved BOOT01 on 2026-10-16: minimal textual C++ project, Linux-capable
Game/Editor targets, Windows Development Editor probe/final builds and VS Code plus
VS2022 generation. Follow the bounded packet in `docs/plans/research/2026-10-16-bootstrap-and-native-parser.md`.
BOOT01 is complete; actual results/limits are in `docs/plans/evidence/2026-10-16-boot01.md`.
Use README commands to rebuild/regenerate this existing project; the creation
wrapper intentionally refuses it. Do not repeat bootstrap or broaden its scope.
Normal per-user build caches and creation of the absent empty default UBT XML are
covered; preserve existing settings. Linux execution stays UNTESTED. Dependency/tool
installation, gameplay/transport features, new Python hosts and binary art were
outside BOOT01. The owner subsequently authorized committing, pushing, opening and
merging its PR, then continuing the migration plan (OWN13, 2026-10-16). Continue
through the next bounded plan gate; record its files, runtime/output ownership and
pass/fail before execution. Do not infer Core edits, new host implementation or
broader feature acceptance from that continuation. The Core diagnostic issue is
already filed. Record subsequent authority without asking again.

The bounded E01 packet is `docs/plans/research/2026-10-16-e01-boundary-packet.md`;
actual results and preserved failed attempts belong in
`docs/plans/evidence/2026-10-16-e01-boundary.md`. It permits the exact locked Core
installation in owned `.local/` paths and the existing loopback development host.
Review each changed candidate before its affected phase; use fresh RunIds after
failure and preserve earlier results. Native tests are a protocol evidence suite,
not a production transport or playable scene. Its JSON reader visibly rejects
case-colliding keys; RISK19 must be resolved before production adoption. Keep
arbitrary submitted movement order intact. The fixture-only uniform-translation
recipe chooses leading-first paths from the selected Core's published examples;
that construction is not a client legality test or a general reorder policy.
The prior 30-second capture passed 38 Python tests and 11 boundary checks but timed out
on a normal-move invalid-geometry command. EXT09 / Core #590 records the latency
gap. Preserve its unknown outcome, result JSON and NOT_ACCEPTED audit. OWN14
(2026-10-16) explicitly approves a separate E01-SLOW120 diagnostic with a
120-second total request budget. Follow packet revision 7; freeze/review the
changed candidate and use a fresh run. Keep connect at three seconds, managed
readiness at 30 seconds and process limits at 30 minutes. A slow-host success
does not pass the old 30-second budget or establish production responsiveness.
Native/Audit and public wire promotion remain gated on successful predecessors
and independent privacy review. Refuse any bytecode cache in the owned runtime.

Fresh normal run `20261017T044903Z-b0169768`, on executed source
`d1189592a5f99bdee58cea25ae8546e5ee2e3623` and packet revision 7, completed
Preflight, verified runtime reuse, Capture, auxiliary privacy inspection,
exact-byte promotion, Native and Audit in order. Actual results are 87 Python
unit tests in 15.167 seconds, 14 Capture checks, 132 unique native Automation
successes and two automated evidence checks. The 14 include source/runtime/schema
checks alongside live HTTP checks. The 135 pure PowerShell controls with 39 stable
inputs are separate pre-execution evidence. All six current editor-settings
before/after observations matched: three present hashes and three established
absences, alongside all three UBT paths and Native/Audit authored Config checks.
Keep the completed raw evidence, process receipts and same-run wire binding.

Current status is **BOUNDED_E01_SLOW120_ACCEPTANCE_RECORDED**, recorded by root at
`2026-10-17T06:00:32.004673+00:00` for the narrow E01-SLOW120 diagnostic. The reviewed candidate is
`b97ed5e8c1b2b2a1472aeb7fb70a267e0eab3d37` against cumulative base
`0467ee63fe6d4c775f429afae2233d7292787c31`; its execution evidence is the unchanged
`044903` run on source `d1189592a5f99bdee58cea25ae8546e5ee2e3623`.
CODE r13 is PASS. Valid initial REQ r3 remains BLOCKED on administrative A1/A2;
the separate administrative supplement is PASS and closes those items. Root
combined those dispositions for bounded acceptance; do not rewrite the initial
REQ verdict as PASS. The contaminated original REQ r2 is invalid and contributes
no approval. See `docs/plans/evidence/2026-10-17-e01-slow120-final-review-provenance.json` and the
separate public reports linked from plan Section 0.8. Supplement SHA256 is
`C382B8A36ED9D033B892220ADA9FDF265119948A7D9A2455F6C8CD22B197855E`.

The initial CODE and valid initial REQ contexts had runtime-enforced read-only,
approval `never` and disabled `memory_mode`; lower-level memory/feature limits
remain UNVERIFIED. The supplement used a new context after the valid initial
assessment was sealed; it was neither a resumed assessment nor a new blind initial
review, and received no final CODE verdict. The later publication commit is a
separate metadata overlay; those reports did not review that later commit.
Execution is stopped. Full E01/M01/M02, research/implementation gates, the original
30-second budget, production responsiveness, UE HTTP, rendering, packaging and
Linux remain open. This E01 record supplies no E02 execution result.

Current E02 source `5abe18cbd020ea97676ad87283735e17822fc462` received affected
SOURCE PASS (4270 bytes/SHA256
`347EA5D65BEF3666143769016B5E408E5DF7EB6600BD3E74C1C0DA6577EA3318`).
Run `20261018T173740Z-647fb0c4` actually executed on 2026-10-19 UTC, after the
owner directly resumed work and conditionally approved two bounded visible tests.
Preflight, SUP6 (three groups/five roots), Win64 Editor Build, Discovery and Numeric
passed. Discovery reconciled 2211 engine names/exact 16 E02 names; Numeric passed
four cases/17041 assertions through the repaired BOM-aware reader.

WorldInput FAILED: `FramePaintStale` aborted `Input.PanDollyFrame` before report
finalization; the wrapper then reported missing `reports/world-input/index.json`.
Five earlier Input log successes/141 assertions are partial diagnostics only.
PID 16900 exited 0 in 25.4134518 seconds with confirmed exit/cleanup and final job
active 0/total 9. Nine settings pairs match before/after and Preflight.after (four
present/five absent). No complete twelve-case result, six PNGs or Audit exists.
Both visible launches were consumed; all current run/hidden/visible authorities
are CLOSED_DO_NOT_REUSE. The [closure](.local/reviews/E02-source-review/root-5abe18c-20261018T173740Z-647fb0c4/worldinput-failure-and-authority-closure.json)
is 11316 bytes/SHA256
`E993BB0AABD78A430E20765B94FA9F81511A43E96AFFB89B8AC4FF4B20971AD0`.

Only bounded paint-coordinate remediation, focused controls and factual docs are
released: align actually painted window-relative geometry with desktop input,
preserving draw geometry, the strict `1e-3` stale-layout guard, native assertions,
fixture, cases, screenshot requirements and budgets. The repair is UNEXECUTED;
checkpoint/fresh freeze/affected SOURCE/new RunId/build and new applicable visible
approval precede repaired graphical execution. Current owner approval does not
transfer to materially changed candidates. No startup flag change is authorized.
Fresh final OWN15 CODE/different REQ, acceptance, packaging and Linux remain pending.
The [E02 journal](docs/plans/evidence/2026-10-16-e02-world-input.md) binds exact evidence.

The following fff05fc disposition is historical, as recorded before the later repair.

Historical E02 candidate `fff05fc2b7e663bd345ddae22c68058f849f7029` received affected
SOURCE PASS (5241-byte raw report, SHA256
`583663C9E698BBC40F89AB28CFDE7760E4FD195D07848A28A6CA75F13963107A`).
Run `20261018T160124Z-dcf2685f` completed Preflight, six supervisor subcases
in three groups/five roots, Win64 Editor Build and visible Discovery. Discovery
reconciled 2211 eligible engine names and the exact 16 E02 names. Its D3D12 scene
used the RTX 4090, driver 610.88; PID11088 exited0 in 255.7679178 seconds, with
confirmed exit/cleanup and final job active0/total40.

Numeric FAILED because the JSON reader rejected the report's leading UTF-8 BOM
(`0xEF` at byte0). PID32692 exited0 in 20.3899516 seconds, with confirmed
exit/cleanup and final job active0/total11. Separate strict BOM-aware decoding
observes four exported Success cases/17041 assertions; Numeric remains FAIL.
All nine Numeric settings pairs match Preflight.after: four present/five absent.
No Numeric completion exists. WorldInput/Audit remain NOT RUN; six PNG captures
were NOT REQUESTED.

All run/hidden/visible authorities are CLOSED_DO_NOT_REUSE. The exact-run
[owner relay](.local/reviews/E02-source-review/root-fff05fc-20261018T160124Z-dcf2685f/relayed-visible-window-owner-approval.json)
covered two sequential visible windows; one was used and the remaining window is
closed/nontransferable. Only strict single-leading-UTF8-BOM reader repair, focused
offline controls and factual docs are released. The repair candidate is UNEXECUTED
and needs checkpoint, fresh freeze/affected SOURCE review and a new RunId.
Default Trace Server/control1985 and CrashReportClient startup were observed;
no attributed activation diagnostic for the six forbidden messaging plugins was
found. Descendant second-hop
behavior/network egress remain UNVERIFIED; no actual job escape is established.
Startup mitigation remains separate pending research, with no startup flag change
authorized here and no acceptance waiver.
The [E02 journal](docs/plans/evidence/2026-10-16-e02-world-input.md) and
[closure](.local/reviews/E02-source-review/root-fff05fc-20261018T160124Z-dcf2685f/numeric-failure-and-authority-closure.json)
(6758 bytes/SHA256
`E6C5B79EED91C1D4B923D590117A4094F3DC1B18C9B61AA6A9973DA0C9E7ECFA`)
bind actual results and limits. Standing SOURCE consent supplies no fresh-candidate
GUI/final CODE/REQ/acceptance/merge authority. Final OWN15 CODE by a fresh reviewer
and REQ by a different fresh auditor follow the execution/evidence freeze.
Linux/packaging and visual acceptance remain pending.

The historical affected E02 SOURCE assessment of `e8f1837e7083f6db03ae7a3909eae76769e1692b`
is PASS (4589-byte raw report, SHA256
`E720D499E2ECC4E0C95E21A5AF1133DBFDFAC77CB6215000C705DBE0E1F5CF66`).
Run `20261018T061145Z-1afc8afb` passed Preflight, all six supervisor subcases
in three groups/five roots, and the Win64 Development Editor Build. Build phase
duration was 97.9442252 seconds; native PID 2576 exited 0 with confirmed cleanup.

Its first visible Discovery, under direct owner approval, FAILED with
`E02_DISCOVERY_COMPLETE_LIST_MISSING`. Native PID 27432 exited 0 in 221.4102112
seconds within 600 seconds, with confirmed exit/cleanup and final job active0/total25.
The engine listed 2211 unique quoted names; the parser accepted 2210 because it
excluded the interior apostrophe in log line 2246,
`System.AI.Gameplay Tasks.Component's basic behavior`. All 16 E02 names were present;
Discovery remains FAIL. Nine Discovery settings states match before/after and
Preflight.after. No Discovery completion/required-artifact manifest exists.
Scene JSON exists, but Check-Scene was not reached. Numeric/WorldInput/Audit did
not run; the six required screenshot captures were not requested.

This run and all its hidden/visible execution authorities are CLOSED_DO_NOT_REUSE.
Only the bounded quoted-name regex repair and relevant docs are released; that
repair is UNEXECUTED. Preserve complete-list reconciliation, exact 16 names, all
C++/fixture/input semantics, criteria and budgets. Require checkpoint, fresh freeze,
affected SOURCE review and a new RunId before repaired execution. This approval
does not authorize a fresh candidate's graphical launch. Final OWN15 still needs
a fresh independent CODE reviewer and a different fresh REQ auditor after the
execution/evidence freeze; SOURCE PASS is not final acceptance. Linux/packaging
remain pending. The [E02 journal](docs/plans/evidence/2026-10-16-e02-world-input.md)
binds the actual results, raw failure and closure.

The [direct visible approval record](.local/reviews/E02-source-review/root-e8f1837-20261018T061145Z-1afc8afb/direct-visible-window-owner-approval.json)
is 1613 bytes, SHA256
`279D35F265599F4EBD77326E78C560584550BAE4D7CFBD7E7C1D44CF8AEC2498`.
It preserves this exact question and direct human reply for e8f1837/061145 only:

> The frozen E02 candidate e8f1837 passed source review, Preflight, all six supervisor cases and the Windows Editor build. Do you approve graphical discovery and rendered/input testing on this desktop: two sequential visible proof launches, one window at a time, each limited to 10 minutes, with scripted focus, camera/UI input, resizing from 1280×720 to 1600×900, six viewport screenshots, logs and normal graphics-cache writes? The E02 packet explicitly requires this separate window approval. Tests use the synthetic advisory fixture.

> Approve the bounded visible E02 tests

The earlier relayed approval is preserved separately (3485 bytes, SHA256
`24B1E088B5E29E3A36DD4335C7837A9C2EF920032D8F2E837B1B7AE74C636C51`).
Neither approval supplies final CODE/REQ runtime-evidence transmission, acceptance
or merge authority; the run's execution authority is now closed.

The historical affected E02 SOURCE assessment of `ba05821a8255fca334ddd1fe04a1b4e23bf6af16`
is PASS; its 5656-byte raw report has SHA256
`4D50A3E104653965431EF940AB7314D828FCC08DBECFBA0504DB34EF8F5CC19A`.
Run `20261018T005629Z-05cac877` completed Preflight (PASS) and all six supervisor
subcases in three groups/five roots (PASS). Build then FAILED with four cascading
compiler diagnostics from incomplete `FProcMeshTangent` in
`E02GeometryTests.cpp:222`. PID28452 exited6 in 51.4887138 seconds, with
confirmed exit/cleanup and final job active0/total35. All nine Build settings
before/after states match Preflight.after; SupervisorControls has no separate pair.

The run and hidden authority are CLOSED_DO_NOT_REUSE. Only the defining-header
include in E02GeometryTests.cpp and necessary docs are released. That authored
repair is UNEXECUTED; require checkpoint, fresh freeze/affected SOURCE review and
a new RunId before execution. Preserve test assertions/counts, fixture/input
semantics, dependencies and budgets. No Build completion was published; downstream
Discovery/numeric/rendered/input Automation and GUI did not run. Visible-window approval,
final separate OWN15 CODE/REQ, packaging and Linux remain pending.
The [E02 journal](docs/plans/evidence/2026-10-16-e02-world-input.md) binds the
static PASS, failed Build and closed authority.

The historical affected E02 SOURCE assessment of `4ee4a3a54c3877d46f1fe2cdc82d282b1fc484b4`
is PASS. Run `20261018T002310Z-d6305fba` completed Preflight and all six supervisor
subcases in three groups/five roots; cleanup and final zero-active jobs are
confirmed. This actually exercises the strict no-fault empty-string repair.
The first C++ build reached UBT/UHT/native compilation and FAILED with 51 compiler
diagnostics. Root PID17736 exited6, with confirmed exit/cleanup and final job
active0/total35. All nine Build settings states match before/after and
Preflight.after; SupervisorControls has no separate settings pair.

This run and hidden authority are CLOSED_DO_NOT_REUSE. Only bounded compile
repairs to E02Geometry.cpp, E02WorldProofGameMode.cpp/.h, E02GeometryTests.cpp,
E02WorldInputTests.cpp and necessary docs are released. Preserve fixture/input
semantics, test counts/assertions, budgets and wrapper controls. Require a local
checkpoint, fresh freeze/affected SOURCE review and new RunId before execution.
Do not resume the failed run. Discovery, numeric/rendered/input Automation and
GUI did not run; visible-window approval, final separate OWN15 CODE/REQ,
packaging and Linux remain pending. The E02 journal binds the immutable evidence.

The historical affected E02 SOURCE assessment of `8e048fc369536a76891031aa4883c888bf762aa8`
is PASS; retain that static report and root's bounded composite gate. Actual run
`20261017T233109Z-85e7c8a2` completed Preflight with nine matching normal-desktop
settings observations before/after. SupervisorControls then FAILED after one
native supervisor root (PID 33344): exit 0/PASS, confirmed cleanup and final job
active count 0/total count 4. The phase took 11.7401221 seconds and raised
`E02_CHILD_CONTROL_FIXTURE_IDENTITY_INVALID`. Its no-fault `syntheticFault` was
an empty System.String, while the validator required null. Closed stdout has
matching child ACK/ALIVE records, but the validator accepted no control case;
do not mark SUP01 control PASS. No controls index/phase completion exists;
SUP02/SUP03, Build, Unreal Automation and GUI did not run. SupervisorControls
has no own settings pair; preserve Preflight's actual observation times.

Hidden authority/run are CLOSED_DO_NOT_REUSE. Root released only the strict
no-fault string predicate repair, related inspector adaptation and documentation.
The authored repair accepts the typed empty string; it remains UNEXECUTED.
Checkpoint, fresh freeze/affected SOURCE review and a new RunId must precede
repair execution. Preserve all raw receipts and earlier source/run dispositions.
The E02 journal binds review/trace/coverage, actual phases and closure. Explicit
visible-window approval, final separate OWN15 CODE/REQ and Linux remain pending.

The historical E02 SOURCE assessment of `58bad7984ef336dfbb486d75bcd51fd241b3b529`
is **CHANGES_REQUESTED**. It found two pre-existing supervisor-control gaps:
SUP03 could accept a real launch failure as an injected seam, and SUP02 could
time out the root without proving the intended child started. Root preserved
the raw report and sealed evidence, closed planned RunId
`20261017T210320Z-3fa544f1` as **UNUSED_DO_NOT_EXECUTE**, and released only bounded
supervisor fixture/validation remediation plus necessary documentation.
Require exact typed seam diagnostics/states and real child-start/alive evidence
as specified in packet revision25. The common SUP01/SUP02 fixture fails fast
on child startup/identity/liveness failure. Preserve raw FAIL receipts and all
historical phase results; the new findings prevent carrying forward affected
control approval. The prior cmd grouping correction remains unexecuted.
Checkpoint/freeze and obtain fresh affected SOURCE review with a new RunId before
any repaired-wrapper/control/Build execution. Visible-window approval and final
separate OWN15 CODE/REQ remain required. See the E02 journal for exact bindings.

The historical affected E02 SOURCE assessment of `2efd348b20bbf4adcd014dba9d50e178cad5c71c`
is PASS. Root's historical composite gate applies the 338 full-source assessment
only to demonstrated unchanged scope; the affected review is no fresh whole-C++/
plugin verdict. Run `20261017T202655Z-2b75d9a6` completed Preflight with nine
normal-desktop settings observations before and after. SupervisorControls completed
three groups/six subcases/five roots in 9.2460989 seconds with 20 bound artifacts
and confirmed exit/cleanup/final zero-active jobs. It records no same-phase
settings pair. Build then FAILED on the missing `logs/build-toolchain-selection.json`.
Worker PID 4472 exited 0 with cleanup/job-zero confirmed; that process success is
not build success. SDK-selection receipt, build.log, staged Binaries/Intermediate
and Build completion are absent; no UBT/C++/UHT/native/GUI proof ran. All nine
Build before/after settings states match each other and Preflight.after.

Hidden authority/run are CLOSED; preserve the failure and do not resume, retry
or reuse its RunId. Root released only a bounded Build-launcher correction and
related documentation. Source now groups the cmd FOR/IF bodies so their tails
cannot capture later continuations; repaired-wrapper execution remains NOT RUN.
Checkpoint/freeze, fresh affected SOURCE review and a new RunId are required.
The E02 journal binds the raw reports, composite gate, phases and closure.
Final OWN15 CODE/REQ, visible-window and merge authority remain separate.

The historical E02 SOURCE assessment of `338735e737c6892736b03c884b475c66ae0f69f8`
is PASS for that frozen source only. Run `20261017T181128Z-06d66926` then failed
Preflight with `E02_REPARSE_PATH` / `FAIL_BEFORE_PHASE_CREATION`: the normal
Known Documents route is `C:/Users/Rabid/OneDrive/Documents`, whose unclassified
reparse-point ancestors were rejected before RunRoot allocation. No RunRoot,
phase result, completion or supervised child was created; Build/native/GUI
remain NOT RUN. Its hidden authority is CLOSED and its attempted RunId must
not be reused. The E02 journal binds the unchanged report, seal, root gate,
hidden authority and separate closure; this supplies no final OWN15 acceptance.

The later Known Documents observation repair permits only the two exact settings
paths to use an absolute, actual-KnownFolder, read-only logical route with unclassified
reparse ancestors. The leaf must remain a plain non-reparse file; retain all
nine role/path/existence/hash comparisons and typed unavailable observations.
Keep strict owned/source/tool/engine and Local/Profile/Roaming guards. Resolved
target identity remains UNVERIFIED. The 202655 run exercised both absence routes;
hashing a present Known Documents file remains unexecuted/UNVERIFIED.

The earlier E02 SOURCE assessment of `73f73b5994456b008cc104e05f7a915a5976f49b`
is CHANGES_REQUESTED: P1 procedural outward-face winding and its numeric oracle,
and P2 shortcut dispatch accepting unbound modifier chords. These are static
findings, not observed rendered/input failures. At that disposition root released only bounded
source/test/documentation remediation. Planned RunId `20261017T174203Z-7dbe90d1`
is UNUSED, has no execution authority and must not be executed. That release
required a checkpoint/freeze, fresh SOURCE review and new RunId before execution.
The later 338 source/run disposition above preserves that history. Final OWN15 CODE/REQ and visible
window gates remain separate; see the E02 journal below for immutable reports.

The earlier bounded E02 source at `c10c02173b2d40b4f80d9bdb2dfa1d37c52079ed` received
independent pre-execution SOURCE PASS; see
`docs/plans/evidence/2026-10-16-e02-world-input.md` for the unchanged report,
operator seal, separately corrected manifest transcription and root's gate.
This is not final OWN15 CODE/REQ acceptance. Run `20261017T171627Z-6e96cd42`
completed Preflight. Its three supervisor groups recorded six successful control
subcases in 9.5589701 seconds, with all five process roots' exit/cleanup confirmed
and final zero-active job accounting. The phase then failed artifact publication
on a dictionary `Contains` overload: no SupervisorControls result or completion
record exists, and no dependent phase may start. Build/native/GUI remain NOT RUN.

That Preflight recorded nine after-settings paths but used redirected LocalAppData
and persisted no before-settings baseline; the real desktop EditorSettings file
was omitted. Preservation of real settings for this run is UNVERIFIED. Root has
authored repairs to both recursive descriptor walkers, the normal desktop
execution-context guard and persisted baseline checks. Those changes received
the 338 static SOURCE PASS above; its failed Preflight supplies no runtime proof.
A visible game window still needs separate explicit owner approval.
E01 reviewed/executed/publication identities and historical limits are unchanged.


Historical normal run `20261017T030835Z-0d4af4e2`, source
`c2614b2484a66bd8465b855e59b184d49b2b926d` and packet revision 6, retains its
87/14/132/2 raw results and 37 separate pure PowerShell guards. It omitted the
required same-run six-path editor-settings snapshots, so that run's criterion
remains **UNVERIFIED**, without waiver or a reconstructed before observation.
The new run supplies its own real observations and does not retroactively change
the historical result. Preserve the byte-exact historical result and journal.

Historical revision4 permits only its recorded Native/Audit supplement linked to
the one pinned immutable historical Capture, with no new Core process or game
submissions. Use its exact hashes and guards; do not invent a general resume path.
Earlier failures remain failures.
Native proof uses ABSLOG, disables INI writes and checks authored Config membership/
bytes plus observed editor/UBT settings. Preserve quarantined generated startup
configuration privately and the documented new global EditorSettings file. Final
acceptance/publication still needs the fresh three-role gate below; test execution
or auxiliary helper inspection alone does not supply those approvals.
Retain raw process-ledger evidence and consistent plan line endings. Changed
harness/tests require a fresh full phase chain; the historical revision4
Capture link cannot substitute for proof of changed Python bytes. Block all
dependent groups after a failed/uncertain session, retain the original authorized
envelope and completion UNKNOWN, and enforce remaining time on each socket read.
These controls cover paired, attach-worker and supervisor lifecycle commands.
An unusable worker terminal result is UNKNOWN unless a complete validated receipt
already establishes a known outcome; retain known receipts through later evidence
failures. Preserve absent wire flags as null and explicit booleans exactly.
Validate receipt session/checkpoint revision, hash and cursor coherence, and bind
the operation and identities to the retained submission in every command lane.
Matching unusable paired replies still mean UNKNOWN. Preserve validated worker
outcomes through missing, partially written or unreadable evidence artifacts;
keep the evidence failure visible. Python/native error classification must agree.
Validate complete pinned creation metadata, including the submitted ruleset
descriptor hash, before further commands. Owned host and worker cleanup must
preserve primary UNKNOWN and finalize process records through cleanup errors.
Host cleanup must survive shutdown-marker errors. Unusable deeply
nested terminal JSON must retain typed UNKNOWN and the owned-process evidence.
Keep a complete owned-process inventory including the attach worker. Normal
Native/Audit must bind every promoted wire byte to the same run's successful
Capture artifacts before execution and revalidate the binding afterward.

Repository names are explicit:

- `Warhammer_40k_UI_unreal` (this repository): new Unreal client and migration evidence.
- `../Warhammer_40k_UI_arcade`: legacy client and behavior/reference baseline. The
  owner's shorthand `Warhammer_40k_UI` means this checkout unless they identify a
  different repository. Read its `AGENTS.md` before inspecting or working there.
- `../Warhammer_40k_AI`: authoritative external core; reference only. Never change
  its files, tests, data, dependencies, history, branch, or release artifacts here.

Do not change either sibling as a side effect of Unreal work. Missing external APIs,
fixtures or host/runtime artifacts need a dependency record with owner and unblock
condition. A client packaging task does not authorize writing a new Python host.

## Authority, identity and privacy invariants

- The core alone generates legal choices, validates rules, mutates authoritative
  state, controls randomness, and owns replay/persistence formats. Local selections,
  draft poses, camera state, support hits, previews and meshes are advisory.
- Every game effect uses the current public `DecisionRequest` / `DecisionResult`
  path. Preserve engine request/option/entity IDs, selected variant, spatial context,
  command identity and typed JSON payloads. Never invent legal options, private
  lifecycle calls, movement witnesses or a second rules path.
- Freeze one exact core commit, runtime build ID, contract, schema and fixture set.
  Read the matching `docs/ADAPTER_DECISION_CONTRACT.md` and schemas before changing
  protocol handling. A sibling branch tip or package version `0.1.0` is insufficient.
  Never reset the shared sibling to make tests pass. Use approved isolated fixtures.
- Keep presentation, decisions, events, caches, diagnostics and traces scoped to
  the authenticated viewer. A player ID parameter is not authorization. Viewer or
  session changes discard caches and invalidate older async callbacks.
- Separate command, session revision, projection, spatial-context and catalog
  identities. On uncertain completion retain the same command ID/envelope and
  reconcile through the public protocol; do not blindly submit a new action.
- Fail visibly on missing/incompatible data. Use typed errors and bounded requests.
  No broad catches, invented default poses, permissive schema fallbacks, hidden
  opponent data or credentials in logs/fixtures. Keep unknown outcomes unknown.

## Unreal architecture and presentation

The BOOT01 project descriptor is `WarhammerClient.uproject` at this repository root;
the plan records actual bootstrap status. Keep runtime/editor dependencies separate. The planned
`TabletopPresentation` plugin owns reusable presentation types and HUD; the
application, core transport and battlefield modules have separate responsibilities.
Do not create all proposed modules before their authorized milestone needs them.

- C++ owns application behavior, reducers, interaction editors, bindings and layout
  policy. UMG/Slate and editor content provide visual authoring. Blueprint graphs
  must not own rules, protocol submission, or a parallel application state machine.
- Runtime modules must not depend on editor modules, editor Python, an embedded
  rules implementation, or a future computer-vision SDK. Apply UObject/world/widget
  changes on the game thread; scope subscriptions and async work to owner lifetime.
- Preserve domain inches, facing, Z, support and measurement geometry. Use explicit,
  invertible handedness/unit transforms at the boundary. Keep display tessellation,
  visual bounds, query proxies, support queries and authoritative geometry distinct.
- Genuine 3D is required from the first playable slice: perspective runtime camera,
  world picking, nonzero elevation proof and ordinary mesh substitution. Camera
  gestures issue zero game commands. Cosmetic substitution preserves IDs and intent.
- HUD/modal/text focus has explicit input ownership. Capture/release, Escape, focus
  loss, camera drag and UI clicks cannot leak into world submissions. Keep roster,
  battlefield and Current Action selection synchronized even while panels are hidden.
- Preserve supported JSON/YAML preferences, named HUD composition, preview reuse,
  recognized inactive values and extension round-trips. Profiles change presentation
  only; they cannot execute code or override authorization/legality. Label previews.

## Sources, assets and outputs

Keep authored `Source/`, `Config/`, `Content/`, `Plugins/`, scripts and textual
generation/import inputs reviewable. Pair binary assets with provenance, import
settings, semantic metadata and visual evidence; give each binary one writer.
Get owner approval before changing Git LFS, remote storage or locking commitments.
Do not commit `Binaries/`, `Intermediate/`, `Saved/`, `DerivedDataCache/`, generated
IDE files, SDKs/engines, downloaded runtime bundles, credentials or private sessions.
The approved ignore rules are present. Keep generated `.ignore` and `.vsconfig`
protected during creation and ignored with the other generated IDE files.

Use explicit cook references for dynamically selected assets; packaged execution
must not depend on sibling checkouts, developer `docs/` paths, system Python, or
runtime package installation. Keep legacy preferences/saves unchanged. Import into
versioned copies and preserve exact-core routing; never promise cross-version resume
or reverse migration without evidence.

## Verification and evidence

Read the active plan before a change and update affected requirements and status.
Distinguish source support, owner choice, a check actually run, and future proof.
Use immutable `repository@commit:path:symbol` references and relevant line ranges;
hash relevant dirty source. Never mark a blocked or unexecuted check PASS.

For documentation, check whitespace, local links, IDs, source identities and command
paths. For newly added untracked files, `git diff --check` alone does not
inspect untracked files; inspect added content directly or use a no-index check.
Run Git/checks from the repository they concern. Python/Arcade checks belong in
`../Warhammer_40k_UI_arcade`; they are not Unreal build gates.

After execution is authorized, verify the smallest meaningful affected layer:
strict protocol/reducer/transform/profile checks, then relevant rendered interaction
and packaged real-core tests. Record exact engine/build/compiler/SDK/host, fixtures,
commands, executed test counts and artifacts. NullRHI does not prove rendering,
an Editor target build does not prove packaging, and an empty automation suite is
failure. Do not invent an existing `Warhammer.Migration` suite. Do not repeat costly
checks without a relevant change or unresolved concern.
Use the successful child exit and complete final unittest summary to establish
positive execution without skips/failures. Test names are not failure summaries.

Before accepting a code milestone, freeze the candidate and obtain separate code
review and acceptance audit against plan criteria. Report actual session isolation
and evidence limits; reviewer configuration files alone prove neither invocation
nor independence. Resolve actionable findings before completion.

## Standing three-role review protocol

The owner directly approved current and future E02 SOURCE review transmission.
The [direct human consent record](.local/reviews/E02-source-review/root-ba058-20261018T005629Z-05cac877/direct-human-current-and-future-source-review-consent.json)
is 2766 bytes, SHA256
`9238AFF6A1F47B10C6CA0128C6AF009BFE31D3FC237A8D36A77B9316DEBE5D4B`,
and records a direct user-message question reply in this chat:

> Do you authorize sending the frozen E02 packet for ba05821—private Unreal client C++ source, installed UE/API excerpts, requirements and file metadata—to the configured OpenAI Codex service for a fresh read-only source review? Credentials, private sessions, author notes and peer verdicts are excluded. The launch prompt is saved for inspection; automatic approval requires direct consent for this revision.

> Approve this and future E02 source reviews within the same data scope and destination

This covers the current ba05821 and future E02 SOURCE reviews within that exact
data scope and configured OpenAI Codex destination. It adds no candidate/runtime
execution, final CODE/REQ transmission or acceptance, visible-window, merge or
unrelated authority. Freeze, affected-review and final separate OWN15 gates remain.

The historical relayed approval authorized transmission of current and subsequent revised E02 review
packets to OpenAI's ChatGPT/Codex service using the existing sign-in: project
source, supporting Unreal/API excerpts, requirements and file metadata only.
The [standing consent record](.local/reviews/E02-source-review/root-338-owner-approved-20261017T200218Z-d47cd4ea/standing-e02-review-transmission-approval.json)
preserves the exact human reply relayed from the progress chat and its trusted
source/message identifiers; independent retrieval of those literal messages was
not established. Credentials/private sessions remain excluded; initial reviewer
inputs also exclude author notes and peer verdicts. This scoped transmission
approval retains freeze/source/final-review gates and grants no visible-window,
merge or unrelated authority. The E02 journal records the exact binding/limits.

OWN15 (2026-10-17 UTC, owner's progress chat) requires the legacy review discipline
for this migration. Keep three distinct roles: an implementer who owns changes
and remediation, an independent code reviewer, and a different independent
requirements/acceptance auditor. Neither reviewer may have authored the candidate,
edit implementation, merge, or substitute the other role's verdict.

For each initial assessment, launch a new context with no resume, fork or inherited
implementation transcript. Prefer fresh `codex exec` sessions with enforced
read-only sandbox and approval policy `never`; request
`memories.use_memories=false`. Record session/invocation IDs, CLI/model/settings,
actual runtime permission evidence, and requested versus verified memory behavior.
An equivalent mechanism must demonstrate the same isolation. If a property is
unavailable, record BLOCKED or UNVERIFIED rather than asserting equivalence.

Supply original owner requirements, necessary repository instructions and normative
plan criteria, exact base/head plus dirty-file hashes, dependency/fixture identities,
relevant source/callers/tests and trustworthy raw execution artifacts. Do not prime
an initial assessment with author working notes/chats or other reviewers' verdicts.
Use clean normative extracts when a planning document mixes criteria with review
history; record their provenance. Launch initial reviewers from the workspace root
or another clean instruction context so this file's current-status review history
is not automatically supplied. Bind and supply the necessary normative instruction
extracts explicitly; exclude peer conclusions and Git message bodies from an initial
assessment. This preserves the existing isolation requirement without discarding
administrative evidence needed later. A contaminated approval is invalid and needs a
fresh assessment. Ordinary diagnostic/helper reviews remain useful but do not
silently satisfy this final gate.

Save separate PASS, CHANGES_REQUESTED or BLOCKED reports with exact candidate,
role/isolation evidence, checks run versus results inspected, limitations and
actionable findings. The auditor maps criteria to evidence. The implementer fixes
findings, re-freezes and obtains fresh affected reviews; material changes invalidate
their affected approvals. Final acceptance, publication and merge of the affected
candidate need both current reports and no unresolved acceptance blockers. Preserve
all failures/unknowns, including the original 30-second failure and separate SLOW120
diagnostic. Historical records retain their actual evidence and limitations; do not
retroactively claim enforced read-only/no-memory isolation from agent names or config.

## Collaboration and GitHub

OWN16 (2026-10-17 UTC) requires regular local checkpoint commits of coherent
increments, before risky changes and after fixes. Record actual test and independent
review status in the checkpoint message/body. Exclude secrets, private sessions and
generated build outputs. A checkpoint is a recoverable save point, not acceptance
or additional push/merge authority. Keep a reviewed/executing candidate frozen;
commit queued changes after that operation ends rather than changing its inputs.

Preserve unrelated work, assign parallel agents distinct files, and never share a
mutable game session or binary asset between writers. Research may continue while
owner questions are pending; stop only dependent work at the applicable gate.
Do not move shared checkouts or silently install/upgrade tools. OWN13 authorizes
publication and merge of the imported plan/BOOT01 PR. Use a scoped branch and `gh`
for GitHub actions;
read `../github-full-access` into `GH_TOKEN` without displaying it. Keep the separate
`../github_token` credential unchanged. Never print, log, commit or place tokens in
arguments, documentation, review packets or URLs. Wait for required PR checks and
investigate actionable failures; merging needs its own applicable authorization.

Handoffs state what changed, evidence/tests passed or failed or not run, remaining
RQ/external blockers, and the next concrete authorized step. Do not equate imported
planning documents with a working Unreal application or completed research gate.
