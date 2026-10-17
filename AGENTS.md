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
120-second total request budget. Follow packet revision 5; freeze/review the
changed candidate and use a fresh run. Keep connect at three seconds, managed
readiness at 30 seconds and process limits at 30 minutes. A slow-host success
does not pass the old 30-second budget or establish production responsiveness.
Native/Audit and public wire promotion remain gated on successful predecessors
and independent privacy review. Refuse any bytecode cache in the owned runtime.

SLOW120 execution now has 40 Python tests, 14 live boundary checks, 132 native
Automation cases and two automated evidence checks passing. Revision4 explicitly
permits a fresh Native/Audit run linked to the one pinned immutable successful
Capture, with no new Core process or game submissions. Use its exact hashes and
guards; do not invent a general resume path. Earlier failures remain failures.
Native proof uses ABSLOG, disables INI writes and checks authored Config membership/
bytes plus observed editor/UBT settings. Preserve quarantined generated startup
configuration privately and the documented new global EditorSettings file. Final
acceptance/publication still needs the fresh three-role gate below; test execution
or auxiliary helper inspection alone does not supply those approvals. Initial
fresh code review requested finite-envelope/session-abandonment and absolute
header-deadline repairs. The initial auditor requires raw process-ledger evidence
and consistent plan line endings. Preserve both reports and prior execution.
Repaired harness/tests require a fresh full phase chain; the historical revision4
Capture link cannot substitute for proof of changed Python bytes. Block all
dependent groups after a failed/uncertain session, retain the original authorized
envelope and completion UNKNOWN, and enforce remaining time on each socket read.

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

Before accepting a code milestone, freeze the candidate and obtain separate code
review and acceptance audit against plan criteria. Report actual session isolation
and evidence limits; reviewer configuration files alone prove neither invocation
nor independence. Resolve actionable findings before completion.

## Standing three-role review protocol

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
history; record their provenance. A contaminated approval is invalid and needs a
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
