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
installation, gameplay/transport features, new Python hosts, binary art and broader
implementation remain outside this approval. The owner separately authorized one
Core issue about HTTP diagnostic fidelity, using `gh`; other publication is not
authorized. Record subsequent authority in the plan without asking again.

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
paths. In this initially uncommitted repository, `git diff --check` alone does not
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

## Collaboration and GitHub

Preserve unrelated work, assign parallel agents distinct files, and never share a
mutable game session or binary asset between writers. Research may continue while
owner questions are pending; stop only dependent work at the applicable gate.
Do not install tools or move shared checkouts. Publication remains limited to the
explicitly authorized Core diagnostic issue until the owner authorizes more.
After publication is authorized, use a scoped branch and `gh` for GitHub actions;
read `../github-full-access` into `GH_TOKEN` without displaying it. Keep the separate
`../github_token` credential unchanged. Never print, log, commit or place tokens in
arguments, documentation, review packets or URLs. Wait for required PR checks and
investigate actionable failures; merging needs its own applicable authorization.

Handoffs state what changed, evidence/tests passed or failed or not run, remaining
RQ/external blockers, and the next concrete authorized step. Do not equate imported
planning documents with a working Unreal application or completed research gate.
