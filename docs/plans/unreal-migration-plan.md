# Unreal client migration and development plan

**Revision 173, 2026-10-25. This is the single canonical root plan. Full feature coverage is not implemented or accepted.**

This document owns scope, priorities, baselines, milestone checklists and feature-parity acceptance. Supporting research/evidence documents supply detail; they do not define a second root roadmap. The previous `unreal-development-plan.md` is a compatibility pointer only. [Closed history through r156](unreal-migration-plan-through-r156.md) preserves PR #3 and [earlier history through r146](unreal-migration-plan-through-r146.md) preserves the imported research and decisions. The [plan/evidence index](README.md) is navigation only.

**Product goal:** support all capabilities supported by the latest selected Core source, including capabilities beyond the Arcade client. Arcade parity is the initial useful milestone and reuse/reference baseline, not the feature ceiling. A useful rendering client that connects to and drives Core comes before exhaustive coverage; close small working slices, then let observed gameplay priorities guide the next slice. Do not postpone that client behind an exhaustive proof campaign.

## Current bounded increment: P2b local two-player handoff

Branch: `codex/p2b-local-player-handoff`, [PR #8](https://github.com/SobolGaming/Warhammer_40k_UI_unreal/pull/8), from verified PR #7 merge `f490bf05a99f0621e59e4cba16a429d22aa6c825` (2026-10-24T20:19:59Z), exact head `8e1246725577b7d68c9685e832dd87f227aadb8e`. This PR is limited to the two existing development principals on one selected Core session. Core remains exact `4f9bef0df2fb974d1285232a1009b8781926361d` /44.5.0; no runtime upgrade or sibling edit is included.

Finite deliverable: let player-a select an offered secondary mission, explicitly hide the current viewer's display for handoff, then let player-b click Ready to read their own projection and make their offered choice. Support handing back through the same privacy-cleared path. Handoff itself sends no mutation or lifecycle request. Only the selected player's credential authenticates metadata/projection/commands, and every returned viewer must match the fixed expected player. This is local development convenience on a trusted workstation; the privacy screen is not account authentication or protection against a person who can inspect the process.

Scope excludes session listing/new-principal joining, remote/spectator UI, arbitrary viewer/role entry, general decision editors, complete setup/battle progression, persistence and recovery of an uncertain command after restart. Existing creation/reopen remains player-a by default. Preserve earlier evidence and the old44.3 preview; full P2 and deferred HV-01–HV-06 stay open.

Implementation:

- [x] Verify PR #7/main and start a separate bounded branch; preserve its completed evidence and record the actual merge.
- [x] Bind protocol/session reads, outcomes, decision actor and own-mission display to explicit supported player-a/player-b identities; reject wrong viewer/scope atomically without administrator fallback.
- [x] Add two-phase handoff: Begin clears old viewer state, credentials, board actors, rosters, decisions/options, mission/outcome/error text and camera capture; Ready reads only the target player's metadata/projection. Block busy/UNKNOWN/pending-command switching and stale callbacks; keep failed target reads private and retryable.
- [x] Supply separate player-b development credentials through existing native launch routes with override validation, redaction and environment restoration; retain current Managed/Attach ownership and Linux seams.
- [x] Add clear Hand off/Ready controls and target/viewer/local-count labels; update README, architecture and the PR body with the actual workflow, limits and manual instructions.

Verification:

- [x] Run focused protocol/state/launcher regressions for wrong viewer/credential, malformed identity, all unsafe handoff states, empty privacy state, stale callbacks and failed-read retry. Observe zero HTTP at Begin, exactly player metadata/projection GETs at Ready, and no create/start/admin/mutation during handoff.
- [x] Build the affected Windows Development package, check Unit/resources and real Core a-choice → hide → b-read/choice → hide → a-read in Managed and Attach modes. Record exact source/package/Core, original IDs/revisions, per-viewer privacy and normal owned/attached cleanup. Existing create/reopen checks remain regressions.
- [x] Obtain fresh independent CODE and separate requirements SOURCE reviews of the frozen candidate, publish actual results/limits, and commit/push/verify every coherent checkpoint. Full finite CODE/REQ passed at runtime source a6dbb1c; fresh distinct CODE/REQ passed the narrow launcher/documentation delta at71a6389 (selected blobs unchanged froma1d9013). SOURCE/native results do not satisfy the visible criteria below.

**Actual non-visible results:** [native/launcher provenance](evidence/2026-10-24-p2b-native.json), [independent SOURCE records](evidence/2026-10-24-p2b-source-reviews.json). Runtime source `a6dbb1ca4ca34be2aaeef767286a9738145a439a` passed the35.506-second Windows Development Game package build,19 Unit,4 resource and three real Core workflows in each mode:29 executions/26 distinct names across four native launches. Attach remained HTTP200 after client exit and its separate owner stopped it normally; Managed stopped normally. CODE and separate REQ passed their finite source scope. The original18/19 Unit failure and CODE request for changes remain preserved; the synthetic receipt fixture was repaired without weakening production validation. A later launcher-only absolute-anchor fix and architecture wording correction at `a1d9013b62336997b838c21c3e4860e20cd9cb7e` passed12 credential controls. Fresh CODE and separate REQ DELTA SOURCE reviews both passed at document checkpoint `71a6389467b6a33a9d3f1083cdf7fcb308330151`, covering only the three changed launcher/documentation files and narrow direct interfaces; their selected blobs remain identical to a1d9013. No C++ or Config changed after a6dbb1c. Required P2B-V1/V2 visible results are recorded separately below.

**Upstream observation, not adoption:** at `2026-10-24T23:57:15.4684816Z`, [Core PR #591](https://github.com/SobolGaming/Warhammer_40k_AI/pull/591) remained OPEN and its head was `c86a37fa95dff95347cf3f7a9c6b14178fd8acde`. P2b retains exact selected Core `4f9bef0df2fb974d1285232a1009b8781926361d` /44.5.0. The [source evidence](evidence/2026-10-24-p2b-source-reviews.json) binds this dated observation and the independent review scopes; a newer upstream head requires a separate adoption review. This does not upgrade the runtime or relabel prior evidence.

### Required P2b manual verification

These criteria **block this PR's user-workflow acceptance**. A human or supported computer use may perform them under the standing visible-test authorization. Before launching, record the exact frozen source, complete outside-checkout package/executable SHA256 and selected4f9/44.5 Core build/resources. Prerequisites: passing affected build/native/SOURCE checks, native Windows x64 and a fresh disposable session. One owned game window at a time, at most ten minutes per launch; retain private screenshots/logs and no real session IDs/credentials in tracked evidence. Use `$taskExe` for the copied nested `WarhammerClient/Binaries/Win64/WarhammerClient.exe`:

```powershell
& ./scripts/Start-Client.ps1 -CoreMode Managed -ClientExecutable $taskExe
# For a separately running matching Core, use its dedicated loopback URL:
& ./scripts/Start-Client.ps1 -CoreMode Attach -Endpoint 'http://127.0.0.1:8765/' -ClientExecutable $taskExe
```

- [x] **P2B-V1 — Two-player workflow and privacy screen.** (1) In a normal Managed launch, Connect/create as player-a; submit one offered mission and Refresh. Record revision, viewer, own mission and hidden opposing decision privately. (2) Click Hand off; before Ready, confirm the old board, mission, offered controls, roster/receipt/error and session-ID field are cleared, the target is player-b, and nothing automatically reveals the next view. (3) Click Ready; confirm same session, unchanged revision, viewer player-b, fresh local count0, only their own offered decision and no player-a private mission. Submit one player-b option and Refresh; confirm Core's actual committed outcome/revision. (4) Hand back, inspect the empty screen again, click Ready as player-a, and confirm only player-a's permitted mission/projection, no player-b private details and local count0. (5) Close normally and confirm Managed stops only its owned host. Native transport checks supply no-mutation/request-count assertions; pixels alone are insufficient.
- [x] **P2B-V2 — Read failure, UI isolation and Attach cleanup.** (1) Launch with a separately owned selected Core in Attach mode, using the approved child-only invalid player-b credential diagnostic (never publish credential values). Create/choose as player-a, then Hand off and Ready. Expect the actual HTTP401/code/message and a still-empty privacy display, with old board/options/missions/receipts absent and no automatic new session. Close normally and confirm the attached host survives. (2) Relaunch with ordinary credentials against that same retained host, open the known ID as player-a and perform handoff/Ready to player-b successfully. Confirm panel clicks, scrolling and focused-field F stay with UI, readable target/viewer/status text and no camera action while the display is hidden. (3) Close normally; confirm the attached service remains healthy before its separate owner stops it. Busy/UNKNOWN/pending switch denial and stale callback rejection are independently required native controls; do not manufacture an uncertain live command solely for a screenshot.

For each checked result publish tester, UTC date, exact identities, ordered actions/actual observations, private evidence locations and limitations. Failed/blocked/not-run boxes remain unchecked. Physical RMB/MMB, actual OS switching/teardown, clean-host Windows and native Linux remain deferred HV criteria, not silently passed by this slice.

For P2B-V2, keep Core running in its separate owner shell using the [foreground/Attach instructions](../development/core-startup.md#windows-foreground-core-and-attach). In the client shell only, run the first Attach client with this deliberately invalid, nonsecret player-b value. The existing Core process keeps its ordinary credentials. After closing that client, the `finally` restores the client shell; launch the second Attach client normally against the same endpoint and retained session. Record/copy the session ID privately before handing off in the first client.

```powershell
$taskSavedPlayerB = [Environment]::GetEnvironmentVariable('WH_CORE_PLAYER_B_TOKEN', 'Process')
try {
    $env:WH_CORE_PLAYER_B_TOKEN = 'diagnostic-invalid-player-b'
    & ./scripts/Start-Client.ps1 -CoreMode Attach -Endpoint 'http://127.0.0.1:8765/' -ClientExecutable $taskExe
} finally {
    [Environment]::SetEnvironmentVariable('WH_CORE_PLAYER_B_TOKEN', $taskSavedPlayerB, 'Process')
}
& ./scripts/Start-Client.ps1 -CoreMode Attach -Endpoint 'http://127.0.0.1:8765/' -ClientExecutable $taskExe
```

**Actual visible result:** [observed workflow and preserved blocked history](evidence/2026-10-24-p2b-visible.md), [identities and private evidence hashes](evidence/2026-10-24-p2b-visible.json). On 2026-10-25 UTC the coordinator used supported Sky computer use on native Windows x64 at launch checkpoint `f8470c387e2b16abfdf89e8cc34f6615ead10bf3`, unchanged runtime source a6dbb1c/launcher delta a1d9013, executable SHA256 `95e6b03a53292e353458a554696e0351e71caab96c6804744bbff8fc3dd501b2` and exact selected4f9/44.5 Core. Three sequential launches passed within their ten-minute budgets. Managed player-a chose a fixed mission at revision2, the empty privacy screen held until Ready, player-b entered that same revision with local count0 and only their own choices, then committed Tactical at revision3. Handing back cleared the view again and restored only player-a's own mission with local count0. The invalid-B Attach client showed actual HTTP401 `authentication_required` / "A valid bearer credential is required." while the old view stayed absent. A fresh ordinary Attach client pasted the copied ID, reopened that same revision2 session and successfully handed to player-b. Field-focused F and panel wheel kept a zoomed board unchanged; hidden-screen click/wheel/F kept the curtain visible until Ready. Panel content fit the observed window, so no overflow-scroll layout claim is made. All clients/launchers exited0 normally, with Config/binary/environment value comparisons preserved. Managed stopped its owned Core; both Attach clients left the shared Core healthy before its separate owner stopped it normally. No test Game remained. Native checks supply transport counts and unsafe-state guards; screenshots alone do not establish internal HTTP or hidden camera state. The initial sandbox failure and locked-desktop attempt retain their original failed/blocked status.

**P2b implementation and verification are complete within this finite boundary; PR #8 is ready for review and remains unmerged.** No required P2b manual gate remains. Stop feature scope here. Broader HV-01–HV-06, native Linux, clean-machine Windows, physical held-button/OS switching, new principals, remote/spectator workflows, durable recovery and general gameplay editors remain future work.

## Completed bounded increment: P2a reopen an existing active session

Branch: `codex/p2a-reopen-session`, [PR #7](https://github.com/SobolGaming/Warhammer_40k_UI_unreal/pull/7), from verified PR #6 merge `dbe186ff99a5369fd8e8dcf0b82ddd0b1f1bcfbd` (2026-10-24T19:57:28Z), exact head `c1b3035f38eccdbad7dd8659585793bf6bfaf0c0`. The owner authorized normal-gates merge and continuation when no manual P1c gate remained. The manual-verification checklist and durable AGENTS rule were committed before merging. GitHub reported MERGEABLE/CLEAN with no remote checks/formal reviews. P1c has no outstanding human-only gate within its finite scope.

Finite deliverable: reopen one known **active** session on the existing selected44.5 service as the existing authenticated **player-a**, through player metadata/projection GETs. Add an existing-session ID field/Open control and make the displayed session ID copyable. Opening must not create/start/reset a session or submit a gameplay command. Current session, busy and UNKNOWN/pending-command guards remain intact. Keep creation's strict administrator/revision0 parser separate from existing-session metadata validation.

This is a known-ID read/reattach feature, not session listing, a new join/principal authorization flow, local handoff, remote/spectator support or durable recovery. General decision editors/roster rendering remain later slices. The in-memory development host must stay alive: cross-client reopen uses **Attach** against a separately owned Core; closing Managed stops Core and loses its sessions. Reopening does not recover a lost uncertain-command envelope after client restart.

Implementation:

- [x] Merge PR #6 at its verified head and create a separate next-milestone branch.
- [x] Add exact selected-Core, requested-session, active lifecycle, player-a scope and nonnegative-revision metadata validation. Validate endpoint/session ID before credential access/HTTP; reject path/query/escape/whitespace and dot-segment IDs.
- [x] Add guarded player-only read/open state flow, clear derived state before a fresh read and require the resulting projection revision to meet the metadata minimum. Preserve unknown command reconciliation and reject in-process session replacement.
- [x] Add usable known-ID/Open controls, copyable current ID and a clearly local accepted-action count; update README/architecture with supported workflow and in-memory limits.

Verification:

- [x] Run focused protocol and request controls: wrong Core/schema/session/scope/lifecycle, malformed revision/ID, atomic failures, zero requests for invalid input and zero POST/start/gameplay mutation while opening; retain current busy/attached/UNKNOWN/stopped protections.
- [x] Build the affected Windows Development Game package, run Unit/resources and real Core create with object A → shut down A → open same ID in fresh object B within one native process → one offered choice → authoritative refresh. Check unchanged authoritative revision during opening, exact viewer/request, zero local accepted actions on entry and correct Managed/Attach cleanup. Repeat the retained create workflow as a regression. [Actual native results](evidence/2026-10-24-p2a-native.json):16 Unit,4 resources and2 real workflows in each mode passed (24 executions/22 names). The first failed build and overlapping startup failure remain failures. The separate-process GUI proof is recorded below.
- [x] Obtain fresh independent CODE and separate requirements SOURCE reviews, publish exact source/runtime results/limits, and commit/push checkpoints. Both fresh roles passed at20600a5 in their finite SOURCE scope; [review records](evidence/2026-10-24-p2a-source-reviews.json) preserve both candidates. Actual P2A-V1/V2 results are separate from those SOURCE reviews.

Manual/visible verification required for this PR (human **or** supported computer use under standing authorization; these two criteria were required for P2a user-workflow acceptance):

- [x] **P2A-V1 — Reopen through the actual controls.** Prerequisites: exact copied P2a package outside the checkout and separately owned selected44.5 Core on a dedicated loopback port; use `Start-Client.ps1 -CoreMode Attach -Endpoint <that loopback URL> -ClientExecutable $taskExe`. (1) In one client window, Connect/create and copy the displayed session ID; record its revision/offered setup decision privately, then close normally without stopping Core. (2) Launch a fresh client, paste that ID and press Open existing session. Confirm same session/revision/viewer, readable board/options and local accepted-action count0, with no new/start command. (3) Submit one offered mission option, Refresh, verify authoritative revision advance/known outcome, close normally and confirm the separately owned host survives before its owner stops it. Record source/package/Core/platform, tester/time and private captures/logs. Native transport instrumentation supplies the zero-mutation assertion; appearance alone is insufficient.
- [x] **P2A-V2 — Input isolation and real read failure.** With a fresh client and the same retained host, (1) focus the ID field, type/edit an invalid path-style ID and press Open; expect validation before any HTTP, no session/board/options, and field typing/F/wheel must stay with UI rather than camera navigation. (2) Enter a syntactically valid nonexistent ID; expect actual HTTP404/code/message, no invented board/options or automatic creation. (3) Correct the field to a known active ID and reopen successfully; confirm usable focus/scroll/layout and normal Attach cleanup. Keep real session IDs/credentials out of tracked evidence. Use at most one owned game window and a ten-minute launch budget.

**Actual visible result:** [P2a packaged workflow](evidence/2026-10-24-p2a-visible.md), [identities/private evidence hashes](evidence/2026-10-24-p2a-visible.json). On 2026-10-24 the coordinator used supported Sky computer use on native Windows x64 with source/package20600a5, executable SHA256 `14c955951ad7dcd0d833f994251c485e14a0275d0dce5de803f160a18a71a521` and exact4f9/44.5 Core. Three sequential ordinary Attach launches passed: actual ID copy/paste across processes restored revision1/player-a/local0; one offered mission committed at revision2/local1; explicit Refresh kept opposing choices hidden. A fresh client rejected a path-style ID, displayed actual HTTP404 `session_not_found`, then reopened the corrected ID at revision2/local0. Field-focused F and panel wheel preserved board zoom; Frame board restored framing. All clients/launchers exited0 normally, attached Core survived each and its separate owner stopped it normally. Fourteen private captures and raw logs/results are retained. No physical held-button, OS-switch/teardown, clean-machine or Linux claim is added.

**P2a implementation and verification are complete within this finite boundary; PR #7 merged normally as `f490bf05a99f0621e59e4cba16a429d22aa6c825` on 2026-10-24T20:19:59Z.** No manual P2a gate remains. Stop this PR's feature scope here; broader P2 and the later milestones remain open. The next separate slice should bring an actual second-player/local-handoff workflow forward only through the selected public Core API, with its own bounded criteria and viewer-isolation checks.

The deferred HV-01–HV-06 checks below retain their broader P1/P3/P8 scope and do not become owner-only blockers for P2a. Required physical-input and native-host capabilities remain explicit.

## Closed P1c Core 44.5 adoption

Branch: `codex/p1c-core-44-5-adoption`, [PR #6](https://github.com/SobolGaming/Warhammer_40k_UI_unreal/pull/6), from verified PR #5 merge `062863c1a13b6fb5597ec360b1e2f4510f5a0860` (2026-10-24T18:43:15Z). The owner authorized that normal-gates merge and a separate next-milestone PR. GitHub reported MERGEABLE/CLEAN before merging, with no remote checks/formal reviews; retained independent local reviews and actual bounded results remain scoped to P1b.

This PR adopts exact Core `4f9bef0df2fb974d1285232a1009b8781926361d`, contract44.5.0, from `codex/static-successor48` / [Core PR #591](https://github.com/SobolGaming/Warhammer_40k_AI/pull/591). A fresh fetch on 2026-10-24 confirmed this selection, upstream PR still OPEN/unmerged and main/reference checkout still clean at5f509. Runtime build ID ends `0443ce4bc405aad1737ec9a396948775010df933bd75144f6ab9ff54152118ba`, resource count3130. The [source-delta inventory](research/2026-10-24-latest-core-capabilities.md) supplies the adaptation inputs. This is an explicit development-source adoption, not a release/Core-merge claim.

Finite deliverable: separately prepared source/runtime, explicit identity and canonical-input adaptation, optional viewer-scoped public-roster DTO support, and the existing real create → finite setup choice → authoritative refresh workflow. Retain the exact44.3.33 preview/environment and historical evidence. General roster editing, session joining/hotseat, deployment/movement/attack editors, all89 family proofs, production hosting and Linux execution remain later slices. Coherency selection belongs to the P4 entity editor; do not invent a mutation route or local casualty rule.

Implementation:

- [x] Merge PR #5 at its verified head and start a separate branch from the exact merge.
- [x] Fetch/freeze the selected Core branch/SHA/contract/unmerged status without changing the reference checkout.
- [x] Prepare a separate exact-source Python runtime, canonical data and explicit launch selection; preserve the old runtime/preview. Exact installed44.5 build/3130 resources verified; explicit44.3 profile still reaches READY/normal STOP and its copied preview hash is unchanged.
- [x] Adapt selected client identity/resources and optional public-roster projection, retaining viewer disclosure and physical IDs. The narrow typed DTO keeps original selection/bearer IDs and nullable attachment/cargo disclosure; points/options/composition/roster rendering and physical-instance joins remain later work. Native checks and independent review are separate below.

Verification:

- [x] Run focused launcher/projection/identity/malformed-field/viewer-disclosure controls and build the affected native client. The [actual results](evidence/2026-10-24-p1c-core-adoption.md) record12 Unit +4 resources +Managed/Attach real integration,18 executions/17 names; native input and source bindings remain explicit.
- [x] Run actual44.5 create → offered setup action → refresh in Managed and Attach modes; record runtime/input identities and owned/attached cleanup. One offered setup choice committed before authoritative refresh; Managed stopped normally, attached host remained HTTP200 then its separate owner stopped it.
- [x] Obtain independent CODE and separate requirements reviews, publish results/limits and close this finite PR scope. Fresh CODE and separate REQ both passed at `a31f64f5247c382a74ffd89ad45d4094308956de` after the preparation-job repair and exact roster-producer supplement. The [review record](evidence/2026-10-24-p1c-source-reviews.json) retains both rounds. The full repaired preparation recipe also passed from exact copied scripts in a short isolated root; its deeper Git path-limit failure remains recorded.

**P1c is complete within this finite boundary; PR #6 merged normally as `dbe186ff99a5369fd8e8dcf0b82ddd0b1f1bcfbd`**, after exact-head MERGEABLE/CLEAN inspection with no remote CI checks/formal GitHub reviews reported. Stop implementation scope here. The native build uses cc494c3, final preparation/source review uses a31f64f, and subsequent commits publish documentation/evidence with unchanged runtime inputs. No new rendered44.5, Linux, full-battle or roster-editor claim is made. The next implementation slice is the thin P2 public session/decision shell in a separate branch/PR.

## Outstanding visible and human verification

**These are deferred full-P1/P3/P8 criteria, not P1c/PR #6 merge blockers.** P1c changed protocol/runtime inputs and made no new rendered, physical-input, clean-machine or Linux acceptance claim. A routine PR review opportunity does not require another owner approval. Each future bounded slice must identify which criteria apply to it and add its own manual checks when it changes a user workflow.

For every checked result record the tester (human or agent), UTC date, source commit, package/executable SHA256, exact Core SHA/build, platform/host, actions, expected versus actual result and private evidence location. Link the public sanitized result from this plan. Keep failed, blocked and not-run boxes unchecked. Use a fresh disposable session; never publish credentials or real session IDs. Perform visible tests under the existing applicable authorization, one owned game window at a time, normally limited to ten minutes. A criterion needing physical input or a separate native host must wait for that capability; do not replace it with injected events or syntax checks.

Common Windows prerequisites: build using [README](../../README.md#build-a-windows-standalone-development-package), copy the complete runnable folder outside the source checkout, prepare the exact matching Core using [startup instructions](../development/core-startup.md), then set `$taskExe` to the copied nested executable. These commands are for the current selected44.5 profile; retained44.3 packages require explicit matching profile selection.

```powershell
$taskExe = 'C:\path\to\Windows\WarhammerClient\Binaries\Win64\WarhammerClient.exe'
& ./scripts/Start-Client.ps1 -CoreMode Managed -ClientExecutable $taskExe
```

For Attach, first run the matching foreground Core using the startup guide, then use `-CoreMode Attach -Endpoint 'http://127.0.0.1:8765/'` instead. Closing an attached client must leave that separately owned service alive.

- [ ] **HV-01 — Current packaged rendering and setup workflow (P1; human or supported computer use).** Launch the selected package with the common command. (1) Connect/create; confirm readable text/materials, complete board framing and accurate keyboard-focus guidance. (2) Submit one offered secondary-mission option, then Refresh; confirm an accepted/committed outcome and authoritative revision without opposing private options. (3) Check wheel zoom, board-focused F, Frame board and panel keyboard/wheel isolation. (4) Close normally; verify owned Core stops, while an Attach service survives. Earlier44.3 visible evidence cannot check a current44.5 box.
- [ ] **HV-02 — Physical held-button gestures (P1/P3; real RMB/MMB input).** After connecting, (1) hold RMB and move to orbit, then release over the board; repeat MMB to pan. (2) Repeat release outside the board and over the panel. (3) Confirm motion stops, fresh gestures work, panel controls retain input, and navigation causes no Core action submission. Requires physical input or a supported API with actual held RMB/MMB; left-only drag or injected reducer events do not qualify.
- [ ] **HV-03 — Actual OS switching during a drag (P1/P3; physical operator or supported actual switching/input API).** With an ordinary approved application available, (1) hold RMB and begin orbiting; switch to that app, release there, then return. (2) Repeat for MMB. (3) Move the mouse without a button and start a fresh gesture; expect no continued motion/jump, no stuck capture and normal new input. Delivered application-deactivation events are not this test.
- [ ] **HV-04 — Actual teardown during a drag (P1/P3; actual held input and normal close).** (1) Begin a held camera gesture, close the client normally (for example Alt+F4), then release the button. (2) Confirm normal client exit without crash/stuck input and owned Managed Core cleanup. (3) Repeat with a separately owned Attach host and confirm it survives. Record each mode separately; do not terminate unrelated processes to simulate success.
- [ ] **HV-05 — Windows without Unreal installed (P8; separate suitable host/operator).** On a Windows x64 host without an Editor installation, (1) follow documented native prerequisites and transfer the complete package plus separately prepared matching Core. (2) Run Managed/Attach startup, create → offered action → refresh, an actual HTTP error and the applicable camera/UI checks. (3) Confirm normal exit/ownership cleanup and retained configuration. Do not uninstall this workstation's Unreal to simulate a clean host; record absent prerequisites or installation failures explicitly.
- [ ] **HV-06 — Native Linux graphics/package workflow (P8; Linux x86-64 host, matching native UE/Core and graphics access).** After arranging the host, (1) follow [native setup/build instructions](../../README.md#linux-native-prerequisites-and-editor-build--untested), establish and record a native Game packaging recipe, and build/copy the complete native bundle. (2) Run foreground Core and the Python Attach launcher, then perform real create/action/refresh, rendering/input and actual-error checks. (3) Close the client and verify Attach leaves Core alive before its operator stops it. Record exact native toolchain/GPU/runtime and diagnostics; Windows, Git Bash or parser tests cannot satisfy this box.

## Closed P1b Windows packaged interactive preview

Branch: `codex/p1-playable-preview`, [PR #5](https://github.com/SobolGaming/Warhammer_40k_UI_unreal/pull/5), from verified PR #4 merge `7ba2c1179416efc6d992d49540aeb165631cb697`. PR #4 merged normally on 2026-10-24 with no protection bypass; GitHub reported no remote checks or formal reviews, while its recorded independent local reviews and bounded checks passed within their stated scopes.

P1b implementation and bounded runtime verification passed at source **`388b4fda24ad3bbdb5b5d92c799de9a2c2a71cee`**. The [native results](evidence/2026-10-24-p1b-native-checks.md), [independent source reviews](evidence/2026-10-24-p1b-source-reviews.json) and [visible results](evidence/2026-10-24-p1b-visible-preview.md) preserve actual identities, failures and limits. Closing evidence was committed/pushed at `7a16b50112d35e459bdcf01052624809da696deb` and PR #5 was marked ready for review. This closes its implementation scope, not full P1 or a playable battle. Keep later P1c/gameplay changes in a separate branch/PR.

**Visible testing is permitted until the owner revokes it**, replacing the previous screen HOLD. Use the computer-use skill for Windows input, one owned game window at a time, bounded launches and exact owned Core cleanup. Record actual manual F/camera/UI outcomes; historical failures remain failures. Do not invent unsupported held-button automation or claim Linux/clean-machine verification.

Implementation:

- [x] Merge PR #4 after verifying its exact head/gates; create this separate P1 branch from the merged base.
- [x] Fetch Core main and its newer development branch without moving or editing the reference checkout; record source targets separately from the tested runtime below.
- [x] Update this roadmap and supporting source inventory for latest-Core capabilities beyond Arcade, preserving the fast playable path and separate implementation/verification checkboxes.
- [x] Show actual board keyboard-focus guidance and label option buttons as immediate Core submissions. Native/rendered verification remains separate below.
- [x] Explain no pending, hidden, visible-but-unsupported and actionable decisions using typed viewer-scoped presentation state; preserve Core authority, command identity and public request/option IDs. Focused regressions and review results are recorded below.
- [x] Build/package the affected Windows client and document a usable preview launch. Game/Editor build, cook/stage/archive passed in 83.44 seconds; the complete initial 50-file copy outside the checkout matched all declared hashes. Runtime-created Saved files are separate. This preview remains player-a and one offered setup action; session joining/handoff and general gameplay editors are subsequent bounded work.

Verification:

- [x] Run focused projection/presentation regressions, the affected native build and packaged resource/Core checks. Eleven unit tests, four resource tests and the real integration test in each Managed/Attach mode passed: 17 test executions, 16 distinct names, four native launches. The original private validator's expected-nine mismatch is preserved; the same successful eleven-test report was revalidated without another execution. Preserve the earlier sandbox-blocked build and the native packaged report-template diagnostic.
- [x] Use the actual packaged manual launcher outside the checkout for Managed and Attach workflows: connect/create → offered mission submission → accepted/committed result → authoritative refresh; readable board/fonts/materials, wheel, Frame button/F, UI isolation, actual HTTP error and normal close. Managed fixed missions and Attach Tactical each reached revision2/one accepted player action and a correctly explained hidden pending decision. A separate invalid-player-credential diagnostic displayed actual HTTP401/`authentication_required`, with no invented projection. F used the supported key-input API with observed board focus; native Maximize/Restore framing passed at the observed window sizes. The initial corner-drag resize attempt changed no size and is not a resize PASS.
- [x] Verify the owned Managed host stops and the attached service survives; preserve configuration and report actual input/tool limitations. All three completed visible workflows exited Game/launcher0 with Config4, parent environment and binary unchanged, normal owned Core cleanup and no remaining Game window. The earlier receipt-observer failure and app-access approval timeout remain failed runs. Real held RMB/MMB, OS switching, clean-machine delivery and Linux stay open wherever not observed.
- [x] Publish final evidence/documentation, commit/push/exact-ref-verify the closing checkpoint and mark this one bounded PR ready for review. PR #5 merged normally as `062863c1a13b6fb5597ec360b1e2f4510f5a0860` on 2026-10-24T18:43:15Z after MERGEABLE/CLEAN inspection, with no remote CI checks reported. Fresh independent CODE and different requirements SOURCE reviews both passed at388b4fd within their finite scope; runtime verification is recorded separately. PR merge is a separate normal-gates action, not an implied extension into P1c.

Stop this PR at the interactive-preview boundary. Core44.5 runtime adoption, hotseat/join, deployment/movement/attack editors, full latest-Core feature coverage and Linux execution are not additions to this PR. P1c/P2–P10 below own those next slices.

## Closed P1a: Windows standalone package, non-visible checks

Branch: `codex/p1-windows-standalone`, based on merged PR #3 / main `2f9e0c11cee65f531be2d4eebe8e7e29532ebf64`. [PR #4](https://github.com/SobolGaming/Warhammer_40k_UI_unreal/pull/4) owns this finite deliverable; do not roll later gameplay or remaining P1 acceptance into it. The owner's additional architecture-guide request is included as supporting documentation for this deployment change.

During P1a the owner was using the desktop and visible work was on HOLD; its checks were non-visible only. The new permission above supersedes that hold for current work. Historical run permissions/results are not relabelled. P1a included no Core/Arcade edits or new host implementation.

Implementation:

- [x] Consolidate the reviewed full roadmap into this original migration-plan path; retain historical evidence and a pointer from the former development-plan path. Record the owner's confirmed Arcade baseline.
- [x] Stage pinned canonical session-create runtime data independently of the source-test tree, retaining checksum validation and explicit missing/corrupt-data failure.
- [x] Cook the startup map and dynamically loaded Cube/Cylinder/material; provide a reproducible Windows Development Game build/cook/stage/package command with ignored output and bounded process supervision.
- [x] Add explicit packaged-executable selection to both launchers while preserving Editor mode, Core identity, process-only credentials and managed/attached cleanup.
- [x] Document package contents, first build versus launch and retained runtime/Core prerequisites.
- [x] Add a source-grounded root architecture guide with useful Mermaid diagrams, source links, implemented/planned distinctions and a durable same-change maintenance rule in AGENTS.md.

Implementation above is separate from runtime acceptance. Final focused checks passed 19 Python launcher tests, 14 PowerShell launcher cases, 32 inert path/function-wiring controls, 28 offline Core-startup controls, ten offline Core-stop controls and three real hidden-CLI Job cases. The inert checks launch no client/Core/GUI; the Job controls launch only owned hidden Python processes. Native results and independent review dispositions are recorded separately below.

Initial package attempt at `8f8c010` failed in 4.19 seconds before compilation/cooking because the ordinary and historical proof Editor targets were ambiguous. Preserve that failure. `DefaultEngine.ini` explicitly selects the ordinary Game/Editor targets; the following successful attempt validated that repair. No visible testing was performed.

Package creation at `9233bb6` succeeded in 199.16 seconds (36 Game/Editor build actions, 144.25 seconds), validating the target-default repair. The runnable folder contains 50 files / 975,120,505 bytes. At `43bb097`, a second build completed in 26.20 seconds and returned exactly one result object, repairing two incidental PowerShell task-result objects. An exact 50-file copy outside this checkout passed four resource/data checks and one real-Core create/action/refresh test in each Managed and Attach mode: six executions / five distinct names. The attached service remained HTTP200 after client exit; its separate owner then stopped it. These runs preserve two native startup warnings and one missing HTML-report-template error per run; structured JSON reports were generated with zero per-test warnings/errors. They establish no visible rendering or clean-machine result.

Both independent source reviews at `43bb097` requested repairs before acceptance: endpoint validation before credential transmission, receipt-independent failed-start cleanup, build descendants after parent exit, restoration of caller credentials, and enforcement of the outside-checkout test boundary. Preserve those verdicts. Later checks/reviews below cover the repairs; the runtime-data loader itself had no actionable finding. Installed UE's `bUsesSlate=true` default was supplied as a finite source excerpt for font-staging review.

The repaired Core-startup controls passed 24 offline AST/inert-process cases. Three real hidden-CLI job controls passed, including a parent that exited with live descendants followed by confirmed empty-job cleanup. An actual runner invocation against an inside-checkout path failed at INPUTS before client/Core startup, as intended, and restored its environment. The initial job-test attempt failed a test-only output-inheritance assumption; explicit child stdout/stderr inheritance repaired that test before the three-case PASS. No Core, Unreal or GUI was launched by these job controls.

At `71f5ced`, the job-owned package build succeeded in 25.23 seconds, returned one result and confirmed an empty job without forced termination. A fresh 50-file outside copy passed the same six non-visible test executions. CODE returned BLOCKED and REQ returned CHANGES_REQUESTED: both found shutdown-marker failure could bypass ordinary owned Core cleanup, and extended Windows path namespaces could bypass the external-copy guard. These were repaired within P1a. Additional finite direct Core/Windows interfaces completed the source packet; unchanged camera behavior and future unchecked Linux packaging instructions remain outside this affected P1a review. The Linux guide documents Python installation and Editor startup, not a native Game package recipe.

The second repair preserves the existing process identity checks, attempts stopping every verified process independently of marker/persistence/other-process failures, and marks STOPPED only after confirmed exit. Ten offline stop controls passed. The runner rejects unsupported namespace/short-name aliases before normalization; 32 focused path/wiring controls passed. Both repairs received affected native checks and fresh source review. Game/Config/Content inputs have not changed since the successful package build.

All six affected native executions passed at `2cad5f4`. Its full source reviews both requested changes: CODE found a case-sensitive Managed-port comparison, and both roles found the startup guide still described the old shutdown budgets. The final narrow repair at `f725e75` uses the same case-insensitive mode comparison as parameter dispatch, extends controls to Managed/lowercase/mixed-case inputs, and documents the implemented 5+3-second wait budgets. Fresh independent CODE and separate requirements closing reviews both returned PASS for that affected correction and direct interfaces. Unchanged native/package behavior is covered by the retained `2cad5f4` results; no new native run is claimed for the case-only guard repair.

**P1a is complete within this boundary; [PR #4](https://github.com/SobolGaming/Warhammer_40k_UI_unreal/pull/4) merged as `7ba2c1179416efc6d992d49540aeb165631cb697`.** The [result summary](evidence/2026-10-24-p1a-windows-package.md) and [machine-readable provenance](evidence/2026-10-24-p1a-windows-package.json) retain every source-review disposition, the failed initial build, later native results and remaining limits. The owner-reported Mermaid grammar error was reproduced with Mermaid 11.12.0; its one-line correction at `3ca8b21` passed actual parsing of both diagrams without a visible browser. [Parser evidence](evidence/2026-10-24-architecture-mermaid.json). Full P1 remains open below.

Non-visible verification and PR exit criteria:

- [x] Windows Game build/cook/stage succeeds and the runnable folder exists. Actual asset/data loading is verified separately below; this is not a portable single executable or a runtime PASS.
- [x] Execute an owned packaged binary outside the source checkout using NullRHI/RenderOffScreen; check intended map/GameMode, runtime data/assets and a real selected-Core create/action/refresh workflow, with normal bounded exit and unchanged Config. Six final test executions / five distinct names; Managed and Attach ownership verified.
- [x] Exercise missing/corrupt runtime-data failure and focused launcher regressions; preserve actual failures before repairs. Actual in-checkout and namespace rejection controls ran before any client/Core launch.
- [x] Complete fresh independent CODE and different requirements review for affected source, record exact results/limits, commit/push/exact-ref-verify and publish the bounded PR. Full assessments and focused closing correction reviews retain their actual separate scopes and dispositions.

**Stop this PR at these criteria.** Actual visible packaged-client controls/rendering, a Windows host without Unreal installed, native Linux, Python runtime bundling, production distribution and new gameplay/profile/viewer/recovery features are out of this PR. They remain separate P1/P2–P9 work. A headless result cannot close their acceptance boxes.

## Baselines and settled decisions

| Project | Identity, role and direct references |
|---|---|
| `Warhammer_40k_UI_unreal` | This C++ first presentation client: [runtime module](../../Source/WarhammerClient), [Game target](../../Source/WarhammerClient.Target.cs), [launch/build guide](../../README.md), [repository instructions](../../AGENTS.md). |
| `Warhammer_40k_UI_arcade` | Python UI parity baseline at **`5088c1c49dcaff29eb59fb64b3063d30214dde73`**: [README](../../../Warhammer_40k_UI_arcade/README.md), [source](../../../Warhammer_40k_UI_arcade/src/warhammer40k_arcade_ui), [tests](../../../Warhammer_40k_UI_arcade/tests), [UI configuration](../../../Warhammer_40k_UI_arcade/docs/ui-configuration.md), [HUD customization](../../../Warhammer_40k_UI_arcade/docs/hud-customization.md). Its supported Core pin is `fc12fa214642f1b1f2a31b56be7323b7d76dbebc`, Contract **44.1.0**. |
| Preserved tested Core / fetched main | `Warhammer_40k_AI` reference checkout and preserved P1b runtime remain at **`5f509724da25a2f6ded0c2739a8e7c84bdf59c91`**, Contract **44.3.33**: [checked-out adapter contract](../../../Warhammer_40k_AI/docs/ADAPTER_DECISION_CONTRACT.md), [development host](../../../Warhammer_40k_AI/scripts/run_phase18m_reference_server.py), [startup guide](../development/core-startup.md). `origin/main` was fetched/observed at this SHA on 2026-10-24 16:42 UTC; checkout HEAD/worktree were preserved. |
| Selected development source target | **`4f9bef0df2fb974d1285232a1009b8781926361d`**, Contract **44.5.0**, branch **`codex/static-successor48`**, fetched 2026-10-24 16:43 UTC; commit date 2026-10-23 16:48 EDT. This is open, unmerged [Core PR #591](https://github.com/SobolGaming/Warhammer_40k_AI/pull/591), 73 commits beyond main. Read the [exact candidate contract](https://github.com/SobolGaming/Warhammer_40k_AI/blob/4f9bef0df2fb974d1285232a1009b8781926361d/docs/ADAPTER_DECISION_CONTRACT.md), not a sibling path that still shows the tested checkout. P1c completed this explicit adoption in a separate runtime; P2a and P2b use that same exact selection; their native and visible status is recorded separately above. The newer upstream head observed at23:57 UTC is a separate adoption item. It is not released main. |

The owner explicitly confirmed on 2026-10-24 that the Python UI baseline is `Warhammer_40k_UI_arcade`; `_python` was a naming mistake. The later direction makes all latest-Core-supported capabilities the ultimate target. Preserve exact tested identities and historical evidence while explicitly staging each newer source/runtime adoption. Fetching refs is permitted; editing/resetting the shared Core checkout or silently substituting an untested runtime is not.

- Python Core alone owns rules, legality and authoritative state. Unreal owns presentation, drafts and collection of player intent through public APIs.
- Support Windows x64 and Linux x86-64. Windows work proceeds now; native Linux build/render/package remains **UNTESTED** until its host is arranged. Linux plumbing or Windows success never closes Linux acceptance.
- Support managed launch of the existing development Core and attachment to an already running service. Document checked-out source and pinned package installation; a UI launcher is not a replacement Core host.
- Local play, remote participants and spectators are required target product modes. The existing local player-a slice does not satisfy all three.
- Preserve preferences/HUD profiles and originals. Sessions remain bound to their exact compatible Core; no midgame switching back to Arcade or cross-Core session conversion is required.
- Personal/internal delivery comes first. External distribution, production host operation and artwork/runtime redistribution clearance are separate later decisions.
- Existing private-source/API review consent and ordinary checkpoint workflow apply. PR #3/#4/#5/#6 are merged; P2a/PR #7 has completed its fixed implementation/verification scope and every coherent checkpoint is committed, pushed and exactly verified. Full latest-Core coverage remains future work.

## What exists today

The current Windows development preview has Editor and standalone Development Game routes. It creates/starts one canonical development session or reopens a known active ID as player-a on a retained Core service, displays that viewer's projection, offers nonparameterized finite choices, submits one offered setup choice and refreshes the authoritative result. Its current world DTO and fixed panel are deliberately small. It has basic 3D board rendering, managed/attached Core startup and camera controls. P1b passed bounded non-visible and visible Windows package checks, including the actual manual launcher, viewer-safe status, camera/UI behavior, HTTP401 and normal ownership cleanup. See the [migration evidence index](README.md) for exact revisions and limits.

It does not yet provide general parameterized gameplay editors, complete roster/world/HUD synchronization, configurable live HUD/profile parity, other viewer modes or durable recovery. The Development folder is not clean-machine or release delivery. The older cooked Game parser/caller proof is narrower than the current package checks. Authored profile roundtrip source at `0719125` remains deferred, unreviewed and unexecuted; earlier parser/P0 passes do not establish live profile parity.

## Parity ledger and completion rules

Use the source-backed [CAP01–CAP36 checklist](research/2026-10-16-capability-checklist.md), its catalogue/preferences/HUD tables as the initial UI/product requirements index. Extend it with the latest selected Core's complete public decision/data/service and automatic rule/content obligations. [Parity/data characterization](research/2026-10-16-parity-and-data.md) and the [44.3.33 adaptation review](research/2026-10-16-contract-44-3-33-adaptation.md) remain historical inputs. Their **97 Core44.1 conformance cases are inventory/parser characterization, not completed gameplay or a limit on target features**.

For each family/variant and Core capability, maintain a row containing: stable ID; exact Core SHA/path/symbol and source/test; preserve/redesign/new/unsupported disposition; public entry/contract/request/variant; reachable setup recipe or explicit exposure gap; separate Unreal implementation/verification states; representative accepted/rejected/stale/cancel outcomes; viewer/platform coverage and remaining Core dependency. Track public editors, public data/services, automatic rule/content consumers and CAP01–36 product behavior separately. A registered/envelope-only family, loadable army or unchanged support-matrix artifact is not proof of a reachable supported battle. Do not recreate missing Core rules in Unreal.

The source-backed [latest Core capability inventory](research/2026-10-24-latest-core-capabilities.md) maps all 89 decision families, 16 HTTP paths and 26 rule sections to immutable source references, baseline differences and current Unreal gaps. The [fetch and merge receipt](evidence/2026-10-24-p1b-source-targets.json) records the exact observed identities without upgrading the runtime.

The frozen family inventories are 87/88/89 rows at Arcade44.1 / tested44.3.33 / development44.5 respectively, including one non-submittable hidden placeholder. The new families are `select_source_reposition` and then `select_coherency_casualty`; 44.5 also adds viewer-scoped public army rosters and changes existing Action/attack sequencing semantics. Family counts understate semantic/rule changes. Source-only inventory and a working public slice precede deeper per-family coverage; do not make an exhaustive catalogue/proof corpus a prerequisite for the first playable client.

Every milestone has separate implementation and verification checklists. Before marking one accepted, build the affected target, run focused regressions and applicable real-Core workflows, obtain fresh independent CODE and different requirements review, record exact identities and limits, then commit/push and verify the GitHub ref. Keep scope proportionate; exhaustive historical 727-recipe or transitive SDK certification is not a prerequisite to ordinary feature work. Completion requires working user flows, not merely parsers, test names or raw JSON submission screens.

## Ordered milestones

**Fast playable lane:** P1b gives the owner the packaged interactive preview now. P1c explicitly adopts the selected newer Core with a small real workflow. Then take a thin P2 session/join/local-handoff slice and enough P3/P4 picking, placement and one movement workflow to make the next game interaction usable. Complete the other variants, viewer modes, HUD and rule/content coverage incrementally. Whole-milestone exhaustive certification is not a serial gate before this lane; each bounded PR still needs working behavior, focused checks and honest remaining gaps.

### P0 — Closed camera increment (PR #3 merged)

Implementation:

- [x] Extend the existing native camera regression for cancellation during held RMB orbit/MMB pan, retaining existing camera/F/UI checks and owned-process cleanup. The Windows Editor build passed; source review and visible verification are recorded separately below.
- [x] Establish this forward roadmap and preserve the narrower migration/evidence records.

Verification:

- [x] Build and independently review the cancellation source and affected supervisor repair; execute the bounded visible run at `76297e2`. One test passed 386 assertions, including ten cancellation cases. The process exited 0 in 23.898 seconds; all four Config files stayed unchanged and no game window remained. [Results and review dispositions](evidence/2026-10-24-live-core-cancellation.md).
- [x] Preserve the earlier manual F failure separately from the passed native F route. Eight cases cover actual Escape/focus/capture/resize operations; the two application-deactivation cases cover deliberately delivered events only. Real OS app switching and teardown remain unverified.
- [x] Record this increment's closing implementation, verification and review dispositions for the owner's authorized PR #3 merge. [PR #3](https://github.com/SobolGaming/Warhammer_40k_UI_unreal/pull/3) merged on 2026-10-24 as `2f9e0c11cee65f531be2d4eebe8e7e29532ebf64`; this milestone does not close P1–P9.

### P1 — Deliver a standalone internal client early

Implementation:

- [x] Build the existing `WarhammerClient` Game target and create a repeatable Windows Development build/cook/stage/package command. Keep the Editor development route available. P1a source-review repairs remain under the bounded increment above.
- [x] Make the canonical session-create JSON explicit runtime data through [LiveCoreRuntimeData](../../Source/WarhammerClient/Private/LiveCore/LiveCoreRuntimeData.cpp), consumed by [LiveCoreSession.cpp](../../Source/WarhammerClient/Private/LiveCore/LiveCoreSession.cpp). Retain its selected-Core identity/checksum and avoid an accidental source-test-tree dependency.
- [x] Include the configured startup map/GameMode and dynamically loaded Cube, Cylinder and material in [GameMode](../../Source/WarhammerClient/Private/WarhammerClientGameMode.cpp). Resource checks cover byte availability; rendered fonts/shaders and fresh-machine prerequisites remain open verification.
- [x] Extend [Windows launcher](../../scripts/Start-Client.ps1) and [manual Python launcher](../../scripts/Start-Client.py) to select the packaged executable while preserving endpoint, credentials, managed/attached ownership and shutdown behavior. The Python Core remains separately installed/checked out for this internal milestone.
- [ ] Document first build separately from routine launch and refresh the pinned-runtime/package instructions; lay out matching native Linux packaging commands without claiming execution.

Verification:

- [ ] Launch the current client from its runnable folder outside the source checkout, without using UnrealEditor as the game process. Verify startup, resources, real Core creation/action/refresh, HTTP errors, camera/UI controls and normal close.
- [ ] Verify managed versus attached Core cleanup, missing runtime data/config/credentials and incompatible Core behavior. Record the first real packaged-client result; earlier parser/caller staging is not a substitute.
- [ ] Repeat on a Windows host without an editor installation before claiming portable/clean-machine delivery. Native Linux execution remains open until P8; packaging is a runnable folder, not a promise of a single self-contained file or a bundled Python installer.

### P1c — Explicit latest-Core adoption, before broad coverage

This follows the P1b preview and can overlap the P2 shell foundation. It is a separate bounded increment, not an automatic pin change in P1b.

Implementation:

- [x] Freeze the adoption target's exact branch/SHA/contract, including whether its upstream PR is still unmerged. Review source/schema/identity/redaction deltas against the current runtime; overlapping envelope versions do not establish compatibility.
- [x] Prepare a separate runtime and canonical input from the selected source without editing the reference checkout or replacing the working 44.3.33 environment. Update client expected identity/resources only with an explicit adaptation.
- [x] Add the new public army-roster projection and coherency-choice semantics to the appropriate DTO/editor backlog, preserving actual disclosure and physical bearer/model IDs. Do not infer new mutation routes from projection fields.
- [x] Keep the previous exact-Core preview available while upgrading; never relabel its session or test evidence as a newer-Core result.

Verification:

- [x] Build the adapted client and run a representative real create → offered action → refresh workflow against the exact new runtime, plus focused identity, malformed/new-field and viewer-disclosure controls. See the [P1c native results](evidence/2026-10-24-p1c-core-adoption.md); this records the already performed checks, not a rerun.
- [ ] Record reachable new-family workflows as their editors land, or a concrete Core/public-service exposure gap. Do not require all89 families or all internal rules before accepting the narrow adoption slice. **Deferred to P4 editor slices:** P1c adds no family editor or fabricated start/mutation route. `select_coherency_casualty` preserves the offered physical model and per-casualty/final `completes_boundary` distinction; Core supplies legal offers and validates/applies removal. `select_source_reposition` retains its exact request/context. This is an acknowledged editor/workflow gap, not a claimed Core defect or a P1c runtime-adoption gate.
- [x] Independently review affected changes, publish exact source/runtime/input identities and actual limits, and commit/push checkpoints. Full latest-Core coverage remains P2–P10 work.

### P2 — General public session and decision application shell

Implementation:

- [ ] Replace player-a-only assumptions with explicit session, principal/viewer, actor and turn-owner identity. Introduce typed, viewer-scoped application state and public session/start/reset/join recipes as supported by Core.
- [ ] Adapt supported request/outcome/projection families to the selected Core target, first 44.3.33 and then explicitly staged 44.5/beyond. Add a descriptor/variant dispatcher for finite, nested, ordered, confirmation, dice, quantity, entity-selection and parameterized flows; keep unsupported/terminal states explicit. Track all current family rows and semantic variants, not only Arcade's supported subset; declared quantity/roster kinds with no submitted family remain an exposure gap.
- [ ] Build the first session selection/join and local two-player handoff slice early, using public service/principal APIs and strict cache clearing. General remote/spectator operations and durable recovery remain P7 work; do not block one usable local progression behind all P7 variants.
- [ ] Preserve original IDs, typed JSON-safe payloads, revision/event cursors and catalog/build/schema/content identity. Serialize mutations and discard obsolete async callbacks by session/viewer/generation.
- [ ] Retain the exact uncertain command envelope/ID, reconcile it before another mutation and show actual HTTP status/messages. Add safe lifecycle handling for uncertain session creation; never blindly retry with new IDs.

Verification:

- [ ] Exercise representative real public sessions plus every supported request/variant as its editor lands. Check wrong Core/schema/revision, malformed/unknown descriptors, stale IDs, rejection, delayed/duplicate/lost replies, projection drift and viewer change.
- [ ] Demonstrate that a rejection is distinct from unknown completion and that commands cannot double-submit. Exposed snapshot invariance alone is not zero-HTTP-attempt proof.

### P3 — Complete battlefield presentation, picking and selection

Implementation:

- [ ] Expand typed projection geometry: board bounds/origin, deployment zones/cutouts, objectives/linked terrain, area/feature types, facing, actual nonzero Z and supported circular/rectangular/elliptical/capsule/polygon bases.
- [ ] Consume latest-Core public army-roster disclosure and physical bearer joins as available in the adopted contract. Preserve per-viewer attachment/cargo reveal rules; show supported army/content status without claiming a complete playable faction from loadable data alone.
- [ ] Keep display meshes, support surfaces, measurement shapes and authoritative footprints distinct. Make Core inches ↔ Unreal centimeters/handedness conversion explicit and invertible. Never invent undeployed poses or new elevation/gravity rules.
- [ ] Add camera-aware picking, overlap cycling, unit/model/physical-component aliases, hover/selection and synchronized world/roster/Current Action focus, including collapsed/hidden panels and stale viewer teardown.
- [ ] Add advisory paths/waypoints/ghosts/targets/ranges, Core-supplied measurements, readable annotations, optional nonsnapping grid, stable icons and minimal visual fallbacks. Support shallow tokens and ordinary meshes with the same IDs and query semantics.

Verification:

- [ ] Compare semantic geometry and intended selection across camera angles, asymmetric/elevated/overlapping entities, hidden UI and mesh substitutions. Test malformed/missing geometry separately from missing optional art.
- [ ] Verify input ownership, click/drag thresholds, release outside the viewport and cancellation; prove local camera/hover/selection/grid changes cause no gameplay submissions using appropriate instrumentation.

### P4 — Play setup, placement and movement through Core

Implementation:

- [ ] Migrate supported setup/prebattle choices and all ten supported model-placement kinds: deployment, redeploy, reinforcement, deep strike, strategic reserves, disembark, scout-reserve setup, materialization, healing revival and return on death.
- [ ] Migrate all eight movement kinds: normal move, advance, fall back, surge, charge, pile in, consolidate and Scout. Preserve emitted physical membership, subset/group assignments, no-move/committed-target and setup envelopes.
- [ ] Provide usable entity/pose/path editors with endpoints, waypoints, readiness, review, explicit confirmation and cancellation; submit public `PathWitness`/proposal forms and preserve request/context/variant identity.
- [ ] Add actual Core-offered coherency casualty selection and source-reposition choices when the adopted contract emits them; refresh authoritative casualties/placement rather than choosing casualties, resolving drift or imposing legality locally.

Verification:

- [ ] Record a real reachable start recipe and accepted authoritative before/after state for each supported family, then execute its variant ledger. Cover attached/physical membership, unchanged paths, unsupported variants, stale requests and viewer changes.
- [ ] Separately verify invalid same-context retry/draft retention versus changed-context draft teardown. Do not replace deployment/movement with a private Core mutation or fabricated start state.

### P5 — Complete remaining supported interactions and progression

Implementation:

- [ ] Deliver the three implemented assignment workspaces: shooting declaration, melee declaration and stratagem target binding. Preserve duplicate physical weapon copies, shared/multiple profiles, borrowed/Firing Deck sources, nullable/empty/targetless choices and permitted decline payloads.
- [ ] Complete supported finite/dice/quantity/entity/confirmation/opportunity/reaction flows, source disambiguation, phase/current-action explanations, scrollable roster and synchronized HUD/world action controls.
- [ ] Traverse supported setup → prebattle → movement → shooting and dedicated charge/fight workflows through public Core requests; surface terminal/unsupported/unreachable states honestly.
- [ ] Cover source-current Action/secondary completion, sequencing and attack model-versus-unit completion changes even where family names are unchanged. Display permitted outcomes/events and retain internal completion evidence redaction.
- [ ] Extend beyond Arcade where Core supports it: Cult Ambush/placement variants, melee allocation/split/extra attacks and pre-session roster/mustering inputs. Use the public `PlayerArmyList`/`ArmyMusterRequest` path where the selected host exposes it; otherwise record the Core service dependency, not a fabricated `roster_construction` request or client rules implementation.

Verification:

- [ ] Check each supported family/variant through user-operable controls, real-Core outcomes and negative/stale/cancel cases. Parser conformance or synthetic charge/fight fixtures do not prove an entire reachable battle.
- [ ] Preserve baseline highlight-then-confirm versus direct context-action semantics. Keep roster selection local; validate new roster/mustering inputs through the supported Core path and distinguish supported pre-session APIs from absent service/editor routes.

### P6 — Preserve profiles, adaptive HUD, preview and diagnostics

Start shared presentation/view-model and composition interfaces alongside P2/P3; do not wait until all gameplay is complete to design profile compatibility.

Implementation:

- [ ] Map every preference field/default/path/error from the capability catalogue, including recognized inactive fields and extensions. Preserve original files, relative/builtin/default/explicit paths, input bindings and intentional inactive semantics; export atomically without silent loss.
- [ ] Implement the accepted HUD widget/attribute/data-reference schema using one normalized composition model and renderer for live UI and preview. Preserve `compass_ring`/`command_bench`, fixed dimensions, visibility/collapse, overflow/scroll/chips and accepted layout/theme/density controls.
- [ ] Add required proportional/min/max/narrow-window reflow, reachable drawers, keyboard navigation, text scaling and high contrast. Port baseline icon identifiers with approved minimal art and visible fallback.
- [ ] Implement whole/subtree preview and headless image+metadata export using the same renderer. Keep production versus synthetic preview inputs explicit.
- [ ] Preserve implemented diagnostic off/summary/payload/render-trace behavior, category/include/exclude/config controls, bounded truncation/rotation and crash bundles with credential/viewer redaction. Ordinary invalid actions are not crashes.

Verification:

- [ ] Begin with a bounded representative preference/HUD corpus, then close every supported field/widget/attribute and import/export/reimport route. Compare semantic state and rendered layout; successful YAML parsing is insufficient.
- [ ] Cover long labels, narrow/high-DPI windows, overflow, stale/unknown fields, malformed files, active/inactive/extension preservation and safe recovery. Keep viewer-private data out of previews, traces and crash output.
- [ ] Review and test any reused deferred profile code before product integration. Historical 727 recipes remain a coverage inventory until materialized and executed, not a blanket gate before ordinary feature progress.

### P7 — Required viewer modes, reconnect and exact-Core continuity

Implementation:

- [ ] Implement local player handoff plus explicit remote participant/spectator connection, session selection/join and authorization UI, using separately supported Core service capabilities. Spectators observe permitted public state and cannot submit player actions.
- [ ] Partition projections, requests, event cursors, drafts, selection, display caches and async callbacks by authenticated viewer. Clear old data on failed refresh, viewer/session switches and permission changes.
- [ ] Implement reconnect/recovery and exact-Core saved-session handling only through supported Core APIs. Keep compatible runtime routing, originals/backups, one-writer ownership and clear mismatch/corruption errors.

Verification:

- [ ] Prove player/actor/turn-owner distinctions, private versus public projection boundaries, spectator restrictions, cross-view stale callback rejection and no hidden opponent-data leakage.
- [ ] Inject response loss/reconnect, restart and permission changes; demonstrate exact-command reconciliation and supported persistence/recovery behavior. Current in-memory UI reconciliation and the development host do not prove durability.
- [ ] Track missing Core authentication, remote-service or persistence support as explicit external Core issues. The UI must not implement a new authority/host, claim unsupported save/resume, or invent cross-Core/midgame client conversion.

### P8 — Native Linux, performance, release and cutover

Implementation:

- [ ] Arrange a native Linux x86-64 machine, matching Unreal toolchain/runtime and rendered GPU host; build/cook/package the same client. Keep Windows bundles usable throughout development.
- [ ] Add reproducible package manifests/CI and clean-machine setup/launch documentation for both platforms, pinned dependency/runtime identity and declared asset provenance. Address intended distribution prerequisites before external release.
- [ ] Define matched baseline/Unreal workloads and hardware early; measure frame time, input latency, startup, memory and large-board/HUD behavior. Separate Core/transport delay from rendering cost and agree budgets from measurements rather than invented PASS numbers.

Verification:

- [ ] Run real packaged-client/Core action, camera/UI and cleanup/error workflows on Windows and native Linux, outside the source/editor environment. Source portability and Windows Git Bash syntax checks do not count as Linux execution.
- [ ] Close practical performance/accessibility/reliability findings and all required parity-ledger variants. Record any agreed intentional difference or remaining waiver explicitly.
- [ ] Approve a default-client switch only after the required feature/platform evidence is complete. Preserve separate profiles/session stores and rollback to compatible exact-Core client bundles; retiring Arcade is a separate decision.

### P9 — Retained presentation-reuse extension

- [ ] After P3/P6 interfaces stabilize, demonstrate shared safe tabletop presentation/composition in a separate synthetic observation host: resolved/ambiguous/stale/lost/duplicate IDs and manual correction, with explicit intent still using current Core requests.
- [ ] Label this CAP34 extension as new work beyond Python UI parity. Production computer vision/projector calibration, detailed miniature libraries/rigs/paid art and new rules/physics are outside parity prerequisites (CAP35–36).

### P10 — Source-current Core coverage beyond the Arcade milestone

This is the long-term target ledger, not a gate ahead of P1b or the thin gameplay lane. Bring an individual requirement forward when it enables the next useful interaction; do not wait for P9 to start Core extensions.

Implementation:

- [ ] Maintain the complete selected-Core public family/variant inventory, public data/service inventory and rule/content consumer obligations alongside CAP01–36. Every supported capability needs an editor, faithful automatic-result presentation, or an explicit Core/public-exposure dependency.
- [ ] Implement source-supported capabilities absent or incomplete in Arcade, including the pre-session roster/mustering, public roster disclosure and newer finite/parameterized contexts above. Unsupported Core behavior remains a Core gap; it is not a license for a private Unreal rules path.
- [ ] Diff each subsequent Core target for schema constraints, family/proposal variants, sequencing/identity/idempotency, redaction, source/resource identity, rule-consumer repairs and support-status changes. Freeze the actual target before adaptation instead of chasing a moving HEAD at runtime.
- [ ] Keep automatic rule/content support separate from UI controls: engine movement/attack/death/reserve/mission/faction effects must be reflected faithfully, not reimplemented in the client. Cross-check source/section coverage when older capability manifests/support matrices have not changed.

Verification:

- [ ] Close representative public workflows as each feature lands; expand per-family/variant and rule/content coverage incrementally without promoting envelope-only examples or unchanged manifests to gameplay acceptance.
- [ ] Verify viewer disclosure, accepted/rejected/stale/uncertain results and authoritative presentation for each adopted extension; keep exact runtime/source/data identities with results.
- [ ] Reach a declared latest-source coverage snapshot with all supported obligations implemented and verified or explicitly blocked by Core. Arcade parity alone does not close this target, and a blocked Core capability stays open until its supported public path exists.

## Capability-to-milestone coverage

Every CAP ID remains traceable to its detailed variant/source/test checklist; grouped rows below enumerate all 36 IDs without promoting unimplemented baseline behavior into shipped parity.

| Capability IDs | Coverage and target milestone |
|---|---|
| CAP01, CAP02, CAP03 | Startup, exact compatibility and sole-Core mutation authority: P1/P2; continued regression throughout. |
| CAP04 | Finite/nested/dice/ordered/confirmation families: P2 foundation, P4/P5 concrete workflows. |
| CAP05, CAP06 | Movement and placement variants: P3 geometry prerequisites, P4 editors/real outcomes. |
| CAP07, CAP08, CAP09 | Assignment/reaction/opportunity and supported progression: P2 lifecycle, P4/P5 workflows. |
| CAP10, CAP11, CAP12 | Selection/roster, supported-versus-unsupported data and input ownership: P0/P3/P5. |
| CAP13, CAP14, CAP15, CAP16, CAP17 | 3D camera, display/query/support geometry, bases, Z/facing and terrain/deployment/objectives: P0/P1/P3/P4. |
| CAP18, CAP19, CAP20, CAP21, CAP22 | Nonsnapping grid, advisory overlays, icons/fallback, local-only interaction and token/mesh equivalence: P1/P3/P6. |
| CAP23, CAP24, CAP25, CAP26, CAP27 | Composition/schema, layouts, accessibility, preference preservation and shared live/preview renderer: P6; interfaces start P2/P3. |
| CAP28 | Actual HTTP/error/uncertainty diagnostics: P2; trace/config/crash product behavior: P6. |
| CAP29, CAP30 | Viewer/actor/cache isolation and exact-Core recovery/coexistence: P2/P7/P8. Remote/spectator product support is required new work. |
| CAP31 | 44.1→tested44.3.33→selected44.5/beyond adaptation, source/inventory/copy/nullable/membership/committed-target semantics: P1c/P2/P4/P5/P10, per-variant ledger. |
| CAP32, CAP33 | Executable bundles, native Windows/Linux and measured performance: P1/P8. |
| CAP34 | Shared synthetic tabletop presentation reuse: P9, distinct from parity acceptance. |
| CAP35, CAP36 | Detailed art, new rules/gravity and production recognition exclusions: all milestones; no completion claim by omission. |

## Supported baseline versus new work and dependencies

- The baseline implements eight movement kinds, ten model-placement kinds and three assignment families. Its generic opportunity/intent tray is proposed; arbitrary roster construction, battlefield-point placement and explicit multi-variant selection are unsupported there. These are baseline gaps, not permanent target exclusions. Core-supported Cult Ambush/placement, melee and roster extensions belong to P2/P4/P5/P10 with actual public-path/exposure evidence.
- Registered controls, DTO role enums, archived plan titles and tests allowing `supported OR diagnostic` do not establish working features. Characterize inactive preference fields, registered-only measure/debug options and unconsumed standalone local-command HUD buttons before deciding whether to preserve inactive semantics or implement an explicit enhancement.
- No working remote/spectator join UI or saved-session/replay entrypoint is established by the current Python baseline inventory. These target product requirements and Core-dependent recovery work are tracked in P7, rather than misrepresented as existing parity.
- The Core development host has fixed development principals, in-memory sessions and limited remote guarantees. Preserve [Core #589](https://github.com/SobolGaming/Warhammer_40k_AI/issues/589) port-ownership limits and [Core #590](https://github.com/SobolGaming/Warhammer_40k_AI/issues/590) responsiveness evidence; the original 30-second failure remains a failure despite a separate successful longer diagnostic. Show actual HTTP status and any missing diagnostic fidelity.
- Changes to a tested runtime pin require explicit compatibility/inventory updates. Fetch and compare newer Core source without editing/resetting the shared checkout; do not silently upgrade the running client or relabel old results. Latest Core source support is the goal, while every actual adoption remains an exact, staged, tested snapshot. Routine implementation in an agreed bounded slice does not require repeated approval.

## Definition of feature-parity completion

- [ ] Every supported baseline family/variant, active preference/HUD behavior and intentional redesign has an implemented, user-operable Unreal equivalent with linked acceptance evidence; unsupported/inactive baseline behavior is honestly preserved or explicitly dispositioned.
- [ ] All required target product modes, viewer privacy, exact-Core continuity, Windows and native Linux packages have applicable real runtime evidence. Missing external Core capability or a missing Linux host stays open, not silently waived into PASS.
- [ ] Positive, rejected, stale, cancelled, incompatible and uncertain outcomes are exercised; profiles/original artifacts are preserved and local presentation never becomes a second rules path.
- [ ] Packaging, clean-machine startup, diagnostics/redaction, accessibility and measured performance meet the recorded release criteria. Independent reviews and owner acceptance cover the final scope before cutover.

This document can be complete as a development roadmap while these implementation and verification checkboxes remain open. Closing a bounded milestone PR does not close full feature parity.

## Definition of the ultimate latest-Core target

- [ ] The initial Arcade milestone above is complete, and every supported capability of the explicitly selected current Core snapshot is mapped to its public editor, public data/service use, faithful automatic presentation or unresolved Core exposure gap.
- [ ] All supported mapped obligations have user-operable implementation and appropriate runtime evidence across required viewers/platforms. No capability is excluded merely because Arcade lacked it; Core-unsupported or unexposed obligations remain explicit open dependencies.
- [ ] The current tested source/runtime/data identities and next development candidate are clear, with a repeatable staged update process. New Core work can extend the backlog without invalidating or rewriting previous exact-Core results.
