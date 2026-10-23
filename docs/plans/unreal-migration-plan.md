# Unreal client migration plan

**Revision 148 — live Core checks passed; review corrections authored, 2026-10-23.**

The owner prioritizes a useful client driving the existing Core over exhaustive compatibility proof. Deliver a 3D board, real session/state, one meaningful player action sent to Core, and the authoritative result. Push this revised-plan checkpoint before implementation; commit, push and verify every subsequent coherent checkpoint. Use [PR #3](https://github.com/SobolGaming/Warhammer_40k_UI_unreal/pull/3); do not merge.

## Section 0 — settled scope and current decisions

- [x] Import the original Arcade migration plan into this repository and establish strong repository instructions.
- [x] Inspect the destination, reference projects, Core contract, installed Unreal/toolchain and existing experiments.
- [x] Retain Python Core as the sole rules authority; use C++ first, genuine 3D Unreal presentation.
- [x] Select existing Core development host, both managed launch and service attachment.
- [x] Select Windows x64 and Linux x86-64. Owner accepts Linux remaining untested until a native host is arranged; retain Linux plumbing.
- [x] Record local play, remote participants and spectators as product modes; first working feedback comes from the local development session.
- [x] Record personal/internal development first, preserved preferences/HUD profiles, exact-Core sessions and no midgame switching requirement.
- [x] Record explicit HTTP errors and missing diagnostic fidelity; Core issues are external dependencies.
- [x] Inventory the shortest live path: default GameMode is empty; E02 has reusable board/camera patterns; native HTTP transport is missing.
- [x] Publish revised-plan checkpoint a5c8db9 and verify the exact GitHub branch ref before implementation.

Owner direction at 23:08 UTC supersedes earlier exhaustive proof sequencing. Historical gate labels do not prevent ordinary slice implementation/builds/focused checks. No new tool installation, Core edit or production-host development is included. Independent CODE and separate requirements review still precede acceptance; do not call unchecked work complete.

**Screen HOLD:** the owner's 22:29 UTC instruction remains active: no visible tests, Editor/Game windows or desktop input until explicit human resumption. Background implementation, builds and non-graphical checks may proceed. No GUI is currently active.

## Project references and boundaries

| Project | Role and concrete pointers |
|---|---|
| [Warhammer_40k_UI_unreal](../../README.md) | This repository; runtime module [Source/WarhammerClient](../../Source/WarhammerClient), [project](../../WarhammerClient.uproject), [instructions](../../AGENTS.md). |
| [Warhammer_40k_AI](../../../Warhammer_40k_AI/README.md) | Read-only sibling and separately maintained authoritative engine. Target commit `5f509724da25a2f6ded0c2739a8e7c84bdf59c91`, adapter contract **44.3.33**. Read [decision contract](../../../Warhammer_40k_AI/docs/ADAPTER_DECISION_CONTRACT.md), public schemas, fixtures and `scripts/run_phase18m_reference_server.py`. Do not edit this checkout. |
| [Warhammer_40k_UI_arcade](../../../Warhammer_40k_UI_arcade/README.md) | Current legacy editable client, semantic/parity reference. Read [AGENTS](../../../Warhammer_40k_UI_arcade/AGENTS.md), [boundary ADR](../../../Warhammer_40k_UI_arcade/docs/adr/0001-ui-core-boundary.md), `src/warhammer40k_arcade_ui/core_client` and `render/core_projection.py`. Original import source: [docs/plans/migration/unreal-migration-plan.md](../../../Warhammer_40k_UI_arcade/docs/plans/migration/unreal-migration-plan.md). Its supported Core baseline was contract 44.1.0; do not conflate it with selected 44.3.33. |
| Warhammer_40k_UI | The UI reference name in the owner request. The original import explicitly maps it to the local Warhammer_40k_UI_arcade client above; there is no separate checkout with this name here. See the [retained provenance table](unreal-migration-plan-through-r146.md#repository-routes-and-provenance). Do not confuse this UI baseline with authoritative Core. |

The imported plan and all research/failures remain available in the [complete through-r146 plan](unreal-migration-plan-through-r146.md). This active document replaces its execution ordering, not its historical results.

## Active milestone: rendered Core playable slice

### Implementation

- [x] Minimal C++ Unreal project, Game/Editor targets, Windows toolchain and Linux platform configuration exist (BOOT01).
- [x] Map reusable board/camera rendering and public Core session/action route.
- [x] Add native asynchronous HTTP/session transport with explicit status/errors, scoped viewer credentials and exact command identity.
- [x] Add startup board and connection/session controls to the default GameMode. Leave synthetic E02 proofs unchanged.
- [x] Implement creation/start of a real canonical development session and rendering of its board/terrain, revision, phase, current request and offered choices. Unplaced models remain unplaced.
- [x] Implement player selection and submission of an offered `select_secondary_missions` finite option with original request/option IDs.
- [x] Implement refresh of that viewer and display of the authoritative revision/result/request transition. Never expose another player's private pending choice.
- [x] Support an easy managed Core development-server launch and attachment to an existing service; document checked-out and pinned-package recipes.
- [x] Document startup commands and remaining limits; actual build/functional/rendered verification remains separately tracked below.
- [x] Correct creation uncertainty, endpoint validation, retained HTTP diagnostics and projection-error recovery after initial reviews requested changes.
- [x] Separate command-receipt revision from applied projection identity so the renderer waits for refreshed board DTOs.

Source implementation above is authored. Checkboxes do not claim successful compilation, live execution or rendered behavior; see verification below.

### Verification

- [x] Retain accepted BOOT01, E01-SLOW120, bounded E02, A1E/A1G parser proofs and bounded P0 payload-reference evidence; these do not establish the live slice.
- [x] Build initial source: C++ compile/link at `42a5bdb`; final configuration/metadata build at `b804ec1`.
- [x] Pass five protocol units and one actual-Core session/action/refresh integration at `b804ec1`; managed startup, authenticated Attach, attachment-stop no-op and graceful owned Stop also passed. Four Config files stayed unchanged.
- [x] Obtain initial independent CODE and separate requirements assessments: both **CHANGES_REQUESTED**; findings are recorded in [slice evidence](evidence/2026-10-23-live-core-slice.md).
- [ ] Build the repaired candidate and run focused regressions, including invalid endpoint/no request, creation 4xx/5xx UNKNOWN, projection recovery and receipt-before-projection cache identity.
- [ ] Repeat the actual-Core session/action/refresh and host-lifecycle check against the repaired candidate.
- [ ] Obtain focused independent CODE and different-reviewer requirements assessments of the frozen changed candidate; resolve concrete blockers.
- [ ] After explicit screen resumption, observe the startup board, connection/session, player click and visible authoritative result. Record actual source/Core/session/action and limits.
- [ ] Publish the slice checkpoint, exact-GitHub-verify its commit, update PR #3 and record acceptance only for demonstrated behavior.
- [ ] Run native Linux build/render/package checks when a host becomes available (**UNTESTED**).

### Checkpoints and next sequence

1. **Plan:** publish this scope/checklist and preserve through-r146 history before changing live-client code.
2. **Connection/state:** implement native transport, board and viewer-state UI. Push source with actual checks and pending verification clearly recorded.
3. **Action/result:** wire a real offered setup choice, authoritative refresh, explicit errors and same-command reconciliation. Add easy managed-launch/attach instructions; push.
4. **Focused validation:** build, execute protocol checks and independent reviews. Push findings/fixes and evidence at coherent checkpoints.
5. **Rendered feedback:** wait for screen resumption, then demonstrate the bounded live interaction; push actual results and let owner prioritize subsequent gameplay.

Combine adjacent implementation steps when they form one coherent runnable increment. Do not create bureaucratic checkpoints for individual lines; every actual checkpoint must be pushed and exact-ref verified. Never force push or upload credentials, private sessions, generated outputs or ignored evidence.

## Essential behavior

- Core alone validates rules and changes authoritative state. Client previews/geometry are advisory.
- Follow public session/DecisionRequest/DecisionResult contracts. Preserve request, option, entity and command IDs; typed JSON-safe payloads only.
- Scope projections, requests, events, diagnostics and UI to the authenticated viewer. Development credentials are not production authentication.
- Serialize submissions. On timeout/lost response retain the exact envelope/command ID and show unknown outcome; reconcile that command before any new action. Never blindly duplicate it.
- Show actual HTTP code/message and distinguish missing fidelity from a successful detailed validation. Original E01 30-second timeout remains a failure even though the separate 120-second diagnostic passed.
- UI controls own input; camera input must not consume UI clicks. Keep world units/handedness explicit; do not synthesize unplaced poses.
- Preserve exact Core identity per session, reject incompatible versions visibly, and keep shared checkouts untouched.
- Use owned output directories, bounded background processes and reliable cleanup. A background test must not launch a window during HOLD.

## Toolchain and startup foundation

Existing project: UE **5.8.3 / CL58210709**, Windows VS2022 17.14, MSVC 14.44.35229 (folder 14.44.35207), SDK 10.0.22621.0 and bundled .NET 10.0.203. Build/regenerate the project using [README](../../README.md); do not rerun creation over it. No Unreal installation or upgrade is needed.

Selected host: checked-out `Warhammer_40k_AI/scripts/run_phase18m_reference_server.py`, with prepared `.local/core-44.3.33` runtime. The GET-only local-session fixture server cannot accept the required action. The reference host has fixed development credentials, no durable store, weak remote-service guarantees and known Windows port-exclusivity gap ([Core #589](https://github.com/SobolGaming/Warhammer_40k_AI/issues/589)). Use loopback and a dedicated port. Managed launch must establish its own readiness and terminate only its owned process.

## Deferred work and honest limits

- Exhaustive profile/HUD import/export/reimport compatibility, 727 recipes, full A2/G-IMPLEMENT parity, broad transitive SDK certification (OWN17 **DEFERRED_UNPROVEN**).
- Source at `0719125c3eacce896475611d621365ac28d2febd` for canonical profile roundtrip remains committed but **DEFERRED, unreviewed and unexecuted**. Its prepared 175-file freeze/119 whole-source grants/51 API ranges has no review GO, CLI assessment or runtime result. Do not resume that pipeline for this slice.
- Full gameplay/deployment/movement, robust reconnect/recovery, remote participant/spectator product UX/security and persistence remain later work. The local milestone does not claim those product modes complete.
- Profile preservation remains a product requirement; defer migration proof until a usable client can be prioritized.
- Linux x86-64 build/render/package remains **UNTESTED**. Windows success cannot stand in for it.
- External distribution, content provenance/clearance, runtime redistribution and production hosting remain later gates.
- Existing reference evidence is bounded; synthetic scenes, parser tests and P0 payload capture are not proof of a rendered real-Core workflow.

## Evidence and history

- [BOOT01](evidence/2026-10-16-boot01.md).
- [Original E01 boundary](evidence/2026-10-16-e01-boundary.md), [SLOW120 provenance](evidence/2026-10-17-e01-slow120-final-review-provenance.json).
- [Bounded E02 acceptance](evidence/2026-10-20-e02-bounded-acceptance.json).
- [A1G final provenance](evidence/2026-10-23-e04a-game-final-review-provenance.json).
- [Bounded P0 final acceptance](evidence/2026-10-23-e04a2-p0-final-acceptance.json), revision 145; ten payloads/six copy relations only.
- [Deferred roundtrip source adoption](research/2026-10-23-e04a2-canonical-roundtrip-source-adoption.md).
- [Full prior plan](unreal-migration-plan-through-r146.md), [prior route index](README-through-r146.md), [prior repository guidance](../../AGENTS-through-r146.md), [prior README](../../README-through-r146.md).

Historical packets retain their original labels, failures and narrow permissions. Closed run IDs/GOs do not authorize repetition. Current work follows this active scope and current owner instructions.
