# Unreal client repository instructions

## Active work

Read `../AGENTS.md`, the legacy `../Warhammer_40k_UI_arcade/AGENTS.md`, and [active migration plan](docs/plans/unreal-migration-plan.md) before work.

The owner's latest increment is to finish the bounded visible active-drag cancellation checks, complete `docs/plans/unreal-development-plan.md` as a forward feature-parity roadmap, then commit, push and merge existing PR #3 after affected checks and independent reviews pass. This direct October 24 instruction supersedes the earlier leave-open/no-merge direction. Keep the working client usable; do not implement the entire future parity roadmap in this closing increment. Preserve the bounded real-Core setup workflow and all historical failures.

**The owner directly resumed bounded visible testing on 2026-10-24**, approving camera controls, board framing, UI isolation, startup focus and the manual launcher. This supersedes the October 23 screen HOLD for those tests. Use one game window at a time, at most ten minutes per launch, with owned-process cleanup and private screenshots/logs. Close each run normally when possible; no blanket unrelated desktop authority is implied. Private-source review consent remains separate from desktop authority. The earlier [visible setup workflow](docs/plans/evidence/2026-10-23-live-core-visible.md) remains a closed historical run.

The resumed [manual launcher check](docs/plans/evidence/2026-10-24-live-core-camera-visible.md) and separate [native camera input check](docs/plans/evidence/2026-10-24-live-core-native-camera-input.md) are closed. The owner now directly approves the remaining visible cancellation checks while the screen is free. Keep one game window at a time, at most ten minutes per launch, with owned-process cleanup. Preserve the earlier manual F failure with cause unestablished; the native synthetic-bound F route passed separately. Linux remains unverified. Distinguish actual Slate/window events from deliberately delivered application events; do not imply broader acceptance.

## Repository boundaries

- This repository is a C++ first Unreal presentation client. Python Core remains a separately maintained authority.
- `../Warhammer_40k_AI` is reference-only: never edit/reset its code, schemas, tests, data, lockfiles or environment. Use its exact selected commit `5f509724da25a2f6ded0c2739a8e7c84bdf59c91`, contract44.3.33 and existing reference development server.
- Read the public adapter decision contract and matching schemas/callers before integration changes. A missing Core capability is an external issue, not a private UI rules path or new host implementation.
- `../Warhammer_40k_UI_arcade` is the legacy client and parity reference. Do not change it as a migration side effect. `Warhammer_40k_UI` in the owner request maps to that local Arcade baseline per the imported provenance; no separate checkout with that name exists here.
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

## Verification and reviews

Run commands in this repository. For docs, check whitespace and referenced paths/commands. For behavior, build the affected target and run focused functional/regression checks covering changed seams and concrete risks. Use actual Core for integration evidence where possible; mocked/synthetic results must be labelled.

Separate implementation completion from verification in the plan's Markdown checklists. Record exact commit/Core version, commands, results and relevant limits. Mark rendered verification complete only for the observed source and workflow. Later source repairs need their own affected checks; the completed visible run does not verify them.

Retain the independent three-role discipline: implementer, fresh independent CODE reviewer and different fresh requirements auditor. Before acceptance, freeze the candidate, provide original slice criteria plus necessary source/interfaces/tests/raw results, exclude author notes and peer verdicts, request read-only/approval-never/no-memory execution, and record actual settings/limits. Prefer fresh `codex exec` sessions. Findings are PASS/CHANGES_REQUESTED/BLOCKED; preserve raw reports, fix actionable blockers and refresh affected reviews after material changes. Standing consent for private source/API reviews to the configured OpenAI Codex service persists until explicitly revoked; do not ask again.

Keep review scope proportionate: changed code, directly used contracts and slice requirements. Expand for concrete findings. Broad transitive SDK and exhaustive profile certification are deferred, not PASS. Ordinary implementation/builds/focused checks do not require elaborate historical packet/phase-GO machinery. Historical failed runs remain failures; closed run authorities do not transfer.

## Checkpoints and GitHub

- Commit **and push every coherent checkpoint**, including plan, implementation, fixes and actual verification records. Record actual tests and pending reviews; checkpoints are not acceptance.
- Verify exact GitHub branch ref equals the committed SHA after each push.
- Use `gh` for normal GitHub actions and PR updates, with process-only `GH_TOKEN` loaded from `../github-full-access`. Keep `github_token` separate. Never display/log/commit either credential.
- Continue branch `codex/e02-world-input-proof` and existing [PR #3](https://github.com/SobolGaming/Warhammer_40k_UI_unreal/pull/3). Verify its identity; no duplicate PR. The owner authorizes merging after this closing increment's checks, reviews and evidence are complete; preserve the branch and history.
- No force push/history rewrite/new remote/unrelated branch mutation. Exclude ignored/private evidence, generated binaries/caches and tokens.
- Workspace-root AGENTS is local guidance, not a file for this repository's PR.

## History

[Through-r146 guidance](AGENTS-through-r146.md) and [through-r146 plan](docs/plans/unreal-migration-plan-through-r146.md) preserve original evidence/constraints in context. They are historical references, not active sequencing instructions. Keep accepted BOOT01/E01-SLOW120/bounded E02/A1E/A1G/P0 records and all failures intact.

Canonical profile-roundtrip source at0719125 and its review preparation are DEFERRED, unreviewed/unexecuted. No new profile review/runtime should be launched for the current slice. Personal/internal development first; production hosting, external distribution and full compatibility remain later work.
