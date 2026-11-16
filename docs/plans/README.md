# Plans and evidence index

[unreal-migration-plan.md](unreal-migration-plan.md) is the **single canonical root plan** for current scope, all feature-parity milestones and implementation/verification status. `unreal-development-plan.md` preserves old links as a pointer only. The owner has confirmed `Warhammer_40k_UI_arcade` as the Python UI baseline.

Current finite increment: **P2c Core 46 adoption of the existing session workflow**, [PR #9](https://github.com/SobolGaming/Warhammer_40k_UI_unreal/pull/9), branch `codex/p2c-core-reference-adoption`, original criteria checkpoint `c46f6ad`. It adapts exact Core main fc52 /46.0.0 for create/start, finite choices, known-ID reopen, privacy-cleared two-player handoff and exact-command reconciliation. No roster UI or later gameplay is included. Its bounded verification is complete and PR #9 is ready for review, unmerged. Implementation/build/native/SOURCE/visible acceptance have separate checked criteria and evidence in the canonical plan. Required manual criteria and complete preparation/build/copy/Attach commands are in [P2c manual testing](../development/p2c-manual-testing.md) and mirrored in the PR body. The [source adaptation inventory](research/2026-11-16-core-46-reference.md) binds exact contracts and coverage limits; it is not runtime acceptance.

P2b / PR #8 merged as `6e76f4a44ab84eca8ae343db27631f3ccbc55d6c` after the owner reported the manual tests passed. Its prepared package and Core44.5 runtime remain separate. P2a/PR #7 is also merged. Full gameplay, remote/spectator, durability and deferred HV-01–HV-06 remain open.

P2c supporting results: [native/launch provenance](evidence/2026-11-16-p2c-core-adoption.json), [actual independent SOURCE settings/results](evidence/2026-11-16-p2c-source-reviews.json). Runtime7ee4a4f passed the package,23 Unit,4 resources and3 real workflows in each Managed/Attach mode. [P2C-V1/V2 visible results](evidence/2026-11-16-p2c-visible.json) passed in three sequential normal launches with22 private captures; no game window remains. Broader HV criteria remain deferred; preserve the recorded failed builds, first real integration failure and blocked CLI review.

P2b supporting evidence:

- [Manual testing and complete setup commands](../development/manual-testing.md), [2026-11-16 preparation/results](evidence/2026-11-16-p2b-manual-setup.json): prepared a verified complete Windows copy at a usable absolute path; four resources and three real-Core checks pass. Includes compilation/copy/Core preparation and both Attach terminals. The owner subsequently reported these manual tests passed before PR #8 merged; this does not verify the46 candidate.
- [Native/launcher results](evidence/2026-10-24-p2b-native.json): Windows Development package,19 Unit,4 resources and3 real workflows in each Managed/Attach mode passed;29 executions/26 distinct names. Initial fixture failure and its repair remain recorded.
- [Independent SOURCE reviews](evidence/2026-10-24-p2b-source-reviews.json): full finite CODE/REQ PASS at runtime source a6dbb1c, then separate fresh delta roles PASS for the launcher/documentation repair at71a6389; no GUI acceptance inferred.
- [Visible handoff and recovery](evidence/2026-10-24-p2b-visible.md), [machine-readable results](evidence/2026-10-24-p2b-visible.json): P2B-V1/V2 passed on 2026-10-25 UTC in three sequential packaged launches. Both player choices committed through Core; handoffs cleared the outgoing view, the invalid-B read showed actual HTTP401 while staying private, and a fresh ordinary Attach client recovered the same session. Field/panel input isolation and normal ownership cleanup were observed, with25 private captures retained. The initial sandbox/locked-desktop attempts remain preserved. PR #8 subsequently merged as 6e76f4a; its 44.5 evidence is not transferred to46.

P2a supporting evidence:

- [Native results](evidence/2026-10-24-p2a-native.json):45.439-second package build;16 Unit,4 resources and two real integration workflows in each Managed/Attach mode, totaling24 executions/22 names. Native request instrumentation verifies exactly two player GETs and no reopening mutation/admin request. Initial compilation and overlapping Core-start failures remain recorded.
- [Independent SOURCE reviews](evidence/2026-10-24-p2a-source-reviews.json): fresh CODE and separate requirements PASS at20600a5 within the finite affected-source scope; they do not substitute for runtime or visible results.
- [Visible known-session workflow](evidence/2026-10-24-p2a-visible.md), [machine-readable results](evidence/2026-10-24-p2a-visible.json): three sequential Attach clients retained one44.5 session across actual launches, copied/pasted its ID, reopened revisions1 and2 with local count0, committed one offered choice, refreshed hidden opposing state, and recovered from local invalid-ID rejection and real HTTP404. Board zoom/Frame board and field/panel isolation were observed; all clients/launchers exited0, with Core healthy after each client before its owner stopped it normally.

P1b supporting evidence:

- [Build and native checks](evidence/2026-10-24-p1b-native-checks.md), [machine-readable provenance](evidence/2026-10-24-p1b-native-checks.json): 83.439-second package build; eleven unit, four resource and two mode-specific integration executions, totaling 17 across four native launches/16 names. Original build/harness failures and native log diagnostics remain recorded.
- [Independent source-review record](evidence/2026-10-24-p1b-source-reviews.json): CODE and separate requirements PASS within their finite affected-source scope.
- [Visible packaged preview](evidence/2026-10-24-p1b-visible-preview.md), [machine-readable results](evidence/2026-10-24-p1b-visible-preview.json): Managed/Attach accepted one mission choice each at revision 2 and explicitly refreshed to a hidden decision; focus/F/frame/zoom/UI isolation and native Maximize/Restore framing observed. The intentional child-player-auth diagnostic displayed actual HTTP401 `authentication_required` without inventing a projection. Three normal Game/launcher exits, Config/environment/binary preservation and Core ownership were confirmed. Earlier supervisor/access-timeout failures and the ineffective corner drag remain distinct.

Completed P1a [PR #4](https://github.com/SobolGaming/Warhammer_40k_UI_unreal/pull/4) merged on 2026-10-24. Its [results](evidence/2026-10-24-p1a-windows-package.md), [provenance](evidence/2026-10-24-p1a-windows-package.json) and [Mermaid correction](evidence/2026-10-24-architecture-mermaid.json) retain exact earlier scopes and the then-active screen HOLD. Standing visible-test permission now applies until revoked. P1b used44.3.33. P1c adopted then-unmerged4f9 /44.5.0 in a separate runtime; P2c now targets main fc52 /46.0.0. Earlier results are not transferred. Full P1, clean-machine proof and native Linux remain open.

[PR #3](https://github.com/SobolGaming/Warhammer_40k_UI_unreal/pull/3) merged as `2f9e0c11cee65f531be2d4eebe8e7e29532ebf64`. [Closed history through r156](unreal-migration-plan-through-r156.md) preserves its implementation/checklists. Its bounded [manual launcher](evidence/2026-10-24-live-core-camera-visible.md), [native input](evidence/2026-10-24-live-core-native-camera-input.md) and [cancellation](evidence/2026-10-24-live-core-cancellation.md) results retain their original source/workflow limits. The earlier manual F failure has cause unestablished; P1b's observed packaged F success does not rewrite it. Packaged held-button input, real OS switching/teardown and native Linux remain untested; general gameplay remains later bounded work. P1c's latest-Core adoption is complete within its recorded boundary.

Supporting research: [current Core 46 source delta](research/2026-11-16-core-46-reference.md); [dated Core44.5 capability inventory](research/2026-10-24-latest-core-capabilities.md), with all 89 families, 16 HTTP paths and 26 rule sections at the exact unmerged development candidate; [source-target receipt](evidence/2026-10-24-p1b-source-targets.json).

Supporting history and evidence:

- [BOOT01](evidence/2026-10-16-boot01.md)
- [E01 original boundary](evidence/2026-10-16-e01-boundary.md), [SLOW120 provenance](evidence/2026-10-17-e01-slow120-final-review-provenance.json)
- [Bounded E02 acceptance](evidence/2026-10-20-e02-bounded-acceptance.json)
- [A1G final provenance](evidence/2026-10-23-e04a-game-final-review-provenance.json)
- [Bounded P0 final acceptance](evidence/2026-10-23-e04a2-p0-final-acceptance.json)
- [Deferred canonical-roundtrip source](research/2026-10-23-e04a2-canonical-roundtrip-source-adoption.md)
- [Complete through-r146 plan](unreal-migration-plan-through-r146.md)
- [Complete through-r146 route index](README-through-r146.md)
- [Repository instructions](../../AGENTS.md)
