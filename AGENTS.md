# Unreal client repository instructions

## Active work

Read `../AGENTS.md`, the legacy `../Warhammer_40k_UI_arcade/AGENTS.md` and the [single canonical migration plan](docs/plans/unreal-migration-plan.md) before work. It alone owns scope, priorities, milestone checklists and parity acceptance. `unreal-development-plan.md` is a compatibility pointer, and other plans/research/evidence are supporting documents. The owner explicitly confirmed Arcade as the Python UI baseline; `_python` was a naming mistake.

Current bounded increment: **P1b Windows packaged interactive preview**, [PR #5](https://github.com/SobolGaming/Warhammer_40k_UI_unreal/pull/5), on `codex/p1-playable-preview` from PR #4 merge `7ba2c1179416efc6d992d49540aeb165631cb697`. Implementation, finite SOURCE reviews, native build/checks and bounded visible Managed/Attach/authentication workflows passed at source388b4fd. Closing evidence is published and PR #5 is ready for review; stop this PR's implementation scope here. Read the exact closing criteria in the canonical plan. Current preview remains player-a/setup-choice only. Core44.5 adoption, hotseat/general gameplay editors, full feature coverage and Linux execution are later bounded increments, each with a separate branch/PR.

**Visible testing is authorized until explicitly revoked**, by the owner's 2026-10-24 direction replacing the earlier screen HOLD. Use the computer-use skill and supported APIs for Windows control. Use bounded owned launches, one game window at a time, normal close/owned Core cleanup and private captures/logs; no invented held-button API or unsupported GUI helper. Existing private-source/API review consent persists independently. No renewed permission question is needed for these authorized tests.

PR #4/P1a is merged and closed; preserve its [exact evidence](docs/plans/evidence/2026-10-24-p1a-windows-package.md). The [manual launcher](docs/plans/evidence/2026-10-24-live-core-camera-visible.md), [native input](docs/plans/evidence/2026-10-24-live-core-native-camera-input.md) and [cancellation](docs/plans/evidence/2026-10-24-live-core-cancellation.md) records remain historical. Preserve the earlier manual F failure with cause unestablished; a new packaged result does not rewrite it. Actual OS switching, teardown and Linux stay unverified until observed. Current launch authority comes from the new standing permission above.

## Repository boundaries

- This repository is a C++ first Unreal presentation client. Python Core remains a separately maintained authority.
- `../Warhammer_40k_AI` is reference-only: never edit/reset its code, schemas, tests, data, lockfiles or environment. The user authorizes safe fetches; preserve checkout HEAD/worktree and read candidate source through exact Git objects. P1b runtime remains `5f509724da25a2f6ded0c2739a8e7c84bdf59c91` /44.3.33. Newer development source `4f9bef0df2fb974d1285232a1009b8781926361d` /44.5.0 is fetched from `codex/static-successor48`, open unmerged Core PR #591, as a planning/adoption candidate. Do not silently upgrade the runtime or relabel prior evidence.
- Read the public adapter decision contract and matching schemas/callers before integration changes. A missing Core capability is an external issue, not a private UI rules path or new host implementation.
- `../Warhammer_40k_UI_arcade` is the legacy client and parity reference. Do not change it as a migration side effect. `Warhammer_40k_UI` in the owner request maps to that local Arcade baseline per the imported provenance; no separate checkout with that name exists here.
- Arcade parity is the initial useful milestone, not a feature ceiling. The ultimate target covers all source-current Core-supported public/editor/data/service and automatic-rule presentation obligations. Record unsupported/unexposed Core gaps; do not implement missing engine rules in Unreal. Prioritize a usable client and small real workflows over exhaustive up-front proof/catalogue campaigns.
- Preserve unrelated user changes. Do not install/upgrade tools or assets without applicable authority.
- Existing UE5.8.3 project/targets already exist; use README build commands, never rerun the creation script over this project.

## Runtime invariants

- Only Core validates legality and mutates authoritative game state. Local drafts, geometry and previews are advisory.
- Preserve original request/option/entity/command IDs and revision semantics. Use typed JSON-safe payloads through public DecisionRequest/DecisionResult/session APIs.
- Scope projections, pending decisions, events, errors and traces to the authenticated viewer. Never fetch admin/private opposing state for display convenience.
- Serialize state-changing submissions. Retain the exact command on uncertain completion and reconcile the same command ID before another action. No blind retry/new-ID duplicate.
- Display actual HTTP status/error. Do not turn missing detail into invented violations or report a timeout as rejection.
- Treat development credentials as development-only. Do not put credentials/private sessions into logs, tracked fixtures, reports or reviews.
- Keep unplaced models unplaced; never fabricate Core poses. Keep inches/centimeters/handedness explicit.
- UI controls own UI input; camera bindings must not intercept their clicks. Handle teardown/async callbacks safely.
- Managed Core launch is client supervision of the existing approved runtime, not Core implementation. Use dedicated loopback port, owned process/readiness/shutdown, bounded waits and cleanup; never terminate an attached service or unrelated process.
- Preserve E02 synthetic modes/proofs and their zero-Core-command assertions.
- Retain Linux-capable seams/targets; Linux execution remains UNTESTED until a native host is arranged.

## Architecture maintenance

Read [architecture.md](architecture.md) before changing code. Assess the architecture impact of every code change and update that guide in the same change whenever directories/components, responsibilities, interfaces/dependencies, startup or data flow, or deployment shape changes. Keep its diagrams and source links consistent with the implementation. Architecture-neutral changes need no cosmetic edit. Clearly distinguish implemented behavior from planned/deferred features, development/proof tooling from the client, and tested platforms from unverified ones.

## Verification and reviews

Run commands in this repository. For docs, check whitespace and referenced paths/commands. For behavior, build the affected target and run focused functional/regression checks covering changed seams and concrete risks. Use actual Core for integration evidence where possible; mocked/synthetic results must be labelled.

Separate implementation completion from verification in the plan's Markdown checklists. Record exact commit/Core version, commands, results and relevant limits. Mark rendered verification complete only for the observed source and workflow. Later source repairs need their own affected checks; the completed visible run does not verify them.

Retain the independent three-role discipline: implementer, fresh independent CODE reviewer and different fresh requirements auditor. Before acceptance, freeze the candidate, provide original slice criteria plus necessary source/interfaces/tests/raw results, exclude author notes and peer verdicts, request read-only/approval-never/no-memory execution, and record actual settings/limits. Prefer fresh `codex exec` sessions. Findings are PASS/CHANGES_REQUESTED/BLOCKED; preserve raw reports, fix actionable blockers and refresh affected reviews after material changes. Standing consent for private source/API reviews to the configured OpenAI Codex service persists until explicitly revoked; do not ask again.

Keep review scope proportionate: changed code, directly used contracts and slice requirements. Expand for concrete findings. Broad transitive SDK and exhaustive profile certification are deferred, not PASS. Ordinary implementation/builds/focused checks do not require elaborate historical packet/phase-GO machinery. Historical failed runs remain failures; closed run authorities do not transfer.

## Checkpoints and GitHub

- Commit **and push every coherent checkpoint**, including plan, implementation, fixes and actual verification records. Record actual tests and pending reviews; checkpoints are not acceptance.
- Verify exact GitHub branch ref equals the committed SHA after each push.
- Use `gh` for normal GitHub actions and PR updates, with process-only `GH_TOKEN` loaded from `../github-full-access`. Keep `github_token` separate. Never display/log/commit either credential.
- PR #3/#4 are merged and closed. PR #4 was merged through normal gates at exact head `c0abfcb` as `7ba2c117`; no protection bypass. Use the new `codex/p1-playable-preview` branch and one bounded P1b PR, with source/runtime candidates and actual remaining verification clear. Do not expand it into later gameplay or latest-Core runtime adoption.
- No force push/history rewrite/new remote/unrelated branch mutation. Exclude ignored/private evidence, generated binaries/caches and tokens.
- Workspace-root AGENTS is local guidance, not a file for this repository's PR.

## History

[Through-r146 guidance](AGENTS-through-r146.md), [through-r146 plan](docs/plans/unreal-migration-plan-through-r146.md) and [closed history through r156](docs/plans/unreal-migration-plan-through-r156.md) preserve original evidence/constraints in context. They are historical references, not active sequencing instructions. Keep accepted BOOT01/E01-SLOW120/bounded E02/A1E/A1G/P0 records and all failures intact.

Canonical profile-roundtrip source at0719125 and its review preparation are DEFERRED, unreviewed/unexecuted. No new profile review/runtime should be launched for the current slice. Personal/internal development first; production hosting, external distribution and full compatibility remain later work.
