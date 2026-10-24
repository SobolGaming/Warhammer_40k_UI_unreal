# Unreal client migration plan

**Revision 152 — owner startup guide and tabletop camera source checked; visible HOLD active, 2026-10-24 UTC / 2026-10-23 EDT.**

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
- [x] Inventory the original empty default GameMode, reusable E02 board/camera patterns and missing native HTTP route; the live implementation is now present.
- [x] Publish revised-plan checkpoint a5c8db9 and verify the exact GitHub branch ref before implementation.

Owner direction at 23:08 UTC supersedes earlier exhaustive proof sequencing. Historical gate labels do not prevent ordinary slice implementation/builds/focused checks. No new tool installation, Core edit or production-host development is included. Independent CODE and separate requirements review still precede acceptance; do not call unchecked work complete.

The earlier bounded visible real-Core test completed and is closed. The latest relayed human instruction returns visible testing to **HOLD at 10:15 p.m. America/New_York on October 23 (02:15 UTC October 24)** until explicit resumption. No owned visible test remains active; this increment proceeds in the background now. Relayed human approvals may be accepted until revoked, preserving their scope and bounds. Neither this feature request nor source-review consent grants blanket desktop authority.

## Project references and boundaries

| Project | Role and concrete pointers |
|---|---|
| [Warhammer_40k_UI_unreal](../../README.md) | This repository; runtime module [Source/WarhammerClient](../../Source/WarhammerClient), [project](../../WarhammerClient.uproject), [instructions](../../AGENTS.md). |
| [Warhammer_40k_AI](../../../Warhammer_40k_AI/README.md) | Read-only sibling and separately maintained authoritative engine. Target commit `5f509724da25a2f6ded0c2739a8e7c84bdf59c91`, adapter contract **44.3.33**. Read [decision contract](../../../Warhammer_40k_AI/docs/ADAPTER_DECISION_CONTRACT.md), public schemas, fixtures and `scripts/run_phase18m_reference_server.py`. Do not edit this checkout. |
| [Warhammer_40k_UI_arcade](../../../Warhammer_40k_UI_arcade/README.md) | Current legacy editable client, semantic/parity reference. Read [AGENTS](../../../Warhammer_40k_UI_arcade/AGENTS.md), [boundary ADR](../../../Warhammer_40k_UI_arcade/docs/adr/0001-ui-core-boundary.md), `src/warhammer40k_arcade_ui/core_client` and `render/core_projection.py`. Original import source: [docs/plans/migration/unreal-migration-plan.md](../../../Warhammer_40k_UI_arcade/docs/plans/migration/unreal-migration-plan.md). Its supported Core baseline was contract 44.1.0; do not conflate it with selected 44.3.33. |
| Warhammer_40k_UI | The UI reference name in the owner request. The original import explicitly maps it to the local Warhammer_40k_UI_arcade client above; there is no separate checkout with this name here. See the [retained provenance table](unreal-migration-plan-through-r146.md#repository-routes-and-provenance). Do not confuse this UI baseline with authoritative Core. |

The imported plan and all research/failures remain available in the [complete through-r146 plan](unreal-migration-plan-through-r146.md). This active document replaces its execution ordering, not its historical results.

## Active increment: owner startup and tabletop ergonomics

The owner wants to launch the existing client/server personally on Windows and Linux, and evaluate normal tabletop mouse controls. Retain the existing Core setup choice; this increment adds presentation ergonomics and reproducible development instructions, not additional rules or full gameplay.

### Implementation

- [x] Add a comprehensive README **Get started playing** section, with separate Windows/Linux prerequisites/build and routine run/play instructions.
- [x] Cover managed Windows startup, separately started Core plus client attachment, endpoint/auth environment names without secret values, shutdown, expected scene/actions and troubleshooting.
- [x] Give native Linux preparation/build and foreground server/client recipes, explicitly UNTESTED and using a native runtime. Add a manual credential-to-client Python launcher; the Windows-only PowerShell launcher remains clearly separate.
- [x] Label the current Unreal Editor development route and distinguish packaged/final-client delivery still pending.
- [x] Author board-only right-drag orbit, middle-drag pan, wheel zoom and F/Frame board control using the unchanged E02 input reducer. Wheel/F require board keyboard focus.
- [x] Author separate panel/board input regions and user/pointer-owned capture cancellation on release, focus/capture loss, Escape, deactivation, resize and teardown. New camera handlers have no Core submission path.
- [x] Author aspect/geometry-based corner fitting, finite navigation bounds and focused camera tests. Ordinary same-bounds refresh preserves navigation; resize reframes. Actual build/runtime/graphical checks remain separate below.

### Verification

- [x] Publish plan checkpoint `d0af1a8a036d074eca32014dc44c58005efa6f84` before source implementation; push and verify the exact GitHub ref.
- [x] Build camera source `1193cb6`: Windows Editor compile/link passed (six actions, 11.54 seconds; UBA retried a compile after memory pressure). Thirteen native checks passed, including three camera geometry/shared-input cases and the retained real-Core action; Config remained unchanged. Actual Slate input/rendering remains unverified.
- [x] Validate documentation paths/links and parse 15 PowerShell plus seven Bash blocks without executing their setup/run commands. Windows Git Bash syntax checks do not establish Linux execution. No tools or packages were installed.
- [x] Pass ten stubbed manual-launcher tests and CLI help; verify the actual installed Windows Core identity through the new wrapper without reading credentials or opening a client. Preserve the first sandbox Temp-permission failure and the same-source workspace-temp rerun.
- [x] Pass non-graphical default-GameMode startup at `721d229` / camera source `1193cb6`: exit 0 in 8.24 seconds, intended GameMode and normal benchmark exit, no original focus error or Error/Fatal lines, unchanged Config. This is not positive focus/input proof.
- [x] Obtain fresh independent CODE and distinct requirements review of frozen `721d229`: both PASS for affected source/documentation; all 43 inputs matched after review. [Evidence and provenance](evidence/2026-10-23-live-core-ergonomics.json).
- [ ] Observe camera controls, framing/resize, UI isolation and repaired startup focus in an applicable approved visible workflow. **Pending HOLD resumption; no new visible run is being started now.**
- [x] Record actual results/limits and push/exact-ref-verify plan `d0af1a8`, camera `1193cb6` and startup guide/manual launcher `721d229`. Publish the final evidence checkpoint and update existing PR #3 without merging.
- [ ] Execute native Linux build/render/package when a host is arranged (**UNTESTED**).

## Established milestone: rendered Core setup slice

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
- [x] Preserve supplied scoped lifecycle messages/violation details on known rejection; label them as returned status and state missing fidelity only when details are absent.

- [x] Repair the observed non-focusable startup-widget error by making the existing UI-only panel focusable at `d2c242d`; rendered verification remains separate.

Implementation and verification remain separate. The observed visible result belongs to `4dacce3` / runtime `ca315fb`; it does not verify a later focus repair.

### Verification

- [x] Retain accepted BOOT01, E01-SLOW120, bounded E02, A1E/A1G parser proofs and bounded P0 payload-reference evidence; these do not establish the live slice.
- [x] Build initial source: C++ compile/link at `42a5bdb`; final configuration/metadata build at `b804ec1`.
- [x] Pass five protocol units and one actual-Core session/action/refresh integration at `b804ec1`; managed startup, authenticated Attach, attachment-stop no-op and graceful owned Stop also passed. Four Config files stayed unchanged.
- [x] Obtain initial independent CODE and separate requirements assessments: both **CHANGES_REQUESTED**; findings are recorded in [slice evidence](evidence/2026-10-23-live-core-slice.md).
- [x] Build repaired `160b510`: Windows Editor compile/link passed (21.88 seconds); all nine native checks passed, including invalid endpoint/no request, creation 4xx/5xx UNKNOWN, projection recovery and receipt-before-projection cache identity.
- [x] Repeat the actual-Core session/action/refresh and host-lifecycle check against `160b510`: passed, four Config files unchanged. See [headless results](evidence/2026-10-23-live-core-headless.json).
- [x] Build and run diagnostic repair `ca315fb`: Editor compile/link passed (22.20 seconds), all ten native checks passed, including actual supplied-message/violation assertions.
- [x] Resolve initial independent CODE/REQ findings; fresh CODE and different-reviewer REQ both passed the affected diagnostic seam at `ca315fb`. [Review provenance](evidence/2026-10-23-live-core-reviews.json) preserves earlier CHANGES_REQUESTED reports and bounded final coverage.
- [x] Observe the approved visible run at `4dacce319a17cdd37e714c52b10d70e6f88ac70c` / runtime `ca315fb317015c701d4bae894af341a30e721edd`: keyboard Connect displayed player-a's board at revision 1 with four offered choices.
- [x] Click an offered Fixed choice with the mouse; observe accepted/committed, revision 2, one accepted player action and the selected missions. Mouse Refresh retained that state; a separate read-only player projection confirmed it.
- [x] Close the visible client normally; Editor and launcher exited 0, owned Core stopped without force, four Config files stayed byte-identical and final target-window count was zero. Preserve the startup-focus error and cropped board edge in [visible evidence](evidence/2026-10-23-live-core-visible.md).
- [x] Compile/link startup-focus repair `d2c242d`: four Windows Editor build actions passed in 7.56 seconds.
- [x] Complete fresh independent CODE and separate requirements reviews of `d2c242d`: both PASS for the affected source; all ten frozen inputs matched after review.
- [x] Run the default GameMode non-graphically at `f5e8180` / runtime `d2c242d`: NullRHI/offscreen startup exited 0 in 17.34 seconds, logged the intended GameMode and normal benchmark exit, with zero original focus errors or Error/Fatal lines and unchanged Config. This is startup smoke, not positive focus/navigation proof. [Repair evidence](evidence/2026-10-23-live-core-focus-repair.json).
- [ ] Observe repaired startup focus/navigation under applicable visible-test approval. The earlier rendered result does not verify `d2c242d`.
- [x] Publish source/headless checkpoints, exact-GitHub-verify each commit and update PR #3.
- [x] Publish bounded visible result/checklist checkpoint `f5e8180e4da955b8ed4aaaac9ff62430da3ff3ee`, push and exact-GitHub-verify it; keep PR #3 open without merge.
- [ ] Improve camera framing/responsive sizing and obtain owner feedback. The observed 3840×2160 view cropped the near board edge; fixed-camera setup proof is not full-board-fit proof.
- [ ] Run native Linux build/render/package checks when a host becomes available (**UNTESTED**).

### Checkpoints and next sequence

1. **Plan:** publish this scope/checklist and preserve through-r146 history before changing live-client code.
2. **Connection/state:** implement native transport, board and viewer-state UI. Push source with actual checks and pending verification clearly recorded.
3. **Action/result:** wire a real offered setup choice, authoritative refresh, explicit errors and same-command reconciliation. Add easy managed-launch/attach instructions; push.
4. **Focused validation:** build, execute protocol checks and independent reviews. Push findings/fixes and evidence at coherent checkpoints.
5. **Rendered feedback:** the bounded local setup workflow is observed and published. Camera controls/framing and owner startup instructions now pass affected build/background checks and independent source/documentation reviews. Actual new camera input/framing, repaired focus and real manual-launcher integration remain unchecked during HOLD. Next is that bounded visible workflow after owner resumption, then ergonomics feedback; Linux still needs a native host.

Combine adjacent implementation steps when they form one coherent runnable increment. Do not create bureaucratic checkpoints for individual lines; every actual checkpoint must be pushed and exact-ref verified. Never force push or upload credentials, private sessions, generated outputs or ignored evidence.

## Essential behavior

- Core alone validates rules and changes authoritative state. Client previews/geometry are advisory.
- Follow public session/DecisionRequest/DecisionResult contracts. Preserve request, option, entity and command IDs; typed JSON-safe payloads only.
- Scope projections, requests, events, diagnostics and UI to the authenticated viewer. Development credentials are not production authentication.
- Serialize submissions. On timeout/lost response retain the exact envelope/command ID and show unknown outcome; reconcile that command before any new action. Never blindly duplicate it.
- Show actual HTTP code/message and distinguish missing fidelity from a successful detailed validation. Original E01 30-second timeout remains a failure even though the separate 120-second diagnostic passed.
- UI controls own input; camera input must not consume UI clicks. Keep world units/handedness explicit; do not synthesize unplaced poses.
- Preserve exact Core identity per session, reject incompatible versions visibly, and keep shared checkouts untouched.
- Use owned output directories, bounded background processes and reliable cleanup. Background tests must stay non-graphical; visible tests/input must remain within applicable owner approval.

## Toolchain and startup foundation

Existing project: UE **5.8.3 / CL58210709**, Windows VS2022 17.14, MSVC 14.44.35229 (folder 14.44.35207), SDK 10.0.22621.0 and bundled .NET 10.0.203. Build/regenerate the project using [README](../../README.md); do not rerun creation over it. No Unreal installation or upgrade is needed.

Selected host: checked-out `Warhammer_40k_AI/scripts/run_phase18m_reference_server.py`, with prepared `.local/core-44.3.33` runtime. The GET-only local-session fixture server cannot accept the required action. The reference host has fixed development credentials, no durable store, weak remote-service guarantees and known Windows port-exclusivity gap ([Core #589](https://github.com/SobolGaming/Warhammer_40k_AI/issues/589)). Use loopback and a dedicated port. Managed launch must establish its own readiness and terminate only its owned process.

## Deferred work and honest limits

- Exhaustive profile/HUD import/export/reimport compatibility, 727 recipes, full A2/G-IMPLEMENT parity, broad transitive SDK certification (OWN17 **DEFERRED_UNPROVEN**).
- Source at `0719125c3eacce896475611d621365ac28d2febd` for canonical profile roundtrip remains committed but **DEFERRED, unreviewed and unexecuted**. Its prepared 175-file freeze/119 whole-source grants/51 API ranges has no review GO, CLI assessment or runtime result. Do not resume that pipeline for this slice.
- Full gameplay/deployment/movement, robust reconnect/recovery, remote participant/spectator product UX/security and persistence remain later work. Unknown-command state is in memory only; restart recovery and actual response-loss injection remain unverified. The local milestone does not claim those product modes complete.
- Profile preservation remains a product requirement; defer migration proof until a usable client can be prioritized.
- Linux x86-64 build/render/package remains **UNTESTED**. Windows success cannot stand in for it.
- External distribution, content provenance/clearance, runtime redistribution and production hosting remain later gates.
- Existing reference evidence retains its original bounds. The new visible evidence proves one local real-Core setup choice; it does not establish full gameplay, full board fit or later source repairs.

## Evidence and history

- [Bounded live-Core visible setup](evidence/2026-10-23-live-core-visible.md), [structured result](evidence/2026-10-23-live-core-visible.json), and [chronological slice progress](evidence/2026-10-23-live-core-slice.md).
- [Startup-focus repair checks and independent review provenance](evidence/2026-10-23-live-core-focus-repair.json); affected source only, repaired rendering untested.
- [Owner startup/camera checks and independent review provenance](evidence/2026-10-23-live-core-ergonomics.json); new graphical workflow pending HOLD resumption, Linux UNTESTED.

- [BOOT01](evidence/2026-10-16-boot01.md).
- [Original E01 boundary](evidence/2026-10-16-e01-boundary.md), [SLOW120 provenance](evidence/2026-10-17-e01-slow120-final-review-provenance.json).
- [Bounded E02 acceptance](evidence/2026-10-20-e02-bounded-acceptance.json).
- [A1G final provenance](evidence/2026-10-23-e04a-game-final-review-provenance.json).
- [Bounded P0 final acceptance](evidence/2026-10-23-e04a2-p0-final-acceptance.json), revision 145; ten payloads/six copy relations only.
- [Deferred roundtrip source adoption](research/2026-10-23-e04a2-canonical-roundtrip-source-adoption.md).
- [Full prior plan](unreal-migration-plan-through-r146.md), [prior route index](README-through-r146.md), [prior repository guidance](../../AGENTS-through-r146.md), [prior README](../../README-through-r146.md).

Historical packets retain their original labels, failures and narrow permissions. Closed run IDs/GOs do not authorize repetition. Current work follows this active scope and current owner instructions.
