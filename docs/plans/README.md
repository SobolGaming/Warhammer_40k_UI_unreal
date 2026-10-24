# Plans and evidence index

[unreal-migration-plan.md](unreal-migration-plan.md) is the **single canonical root plan** for current scope, all feature-parity milestones and implementation/verification status. `unreal-development-plan.md` preserves old links as a pointer only. The owner has confirmed `Warhammer_40k_UI_arcade` as the Python UI baseline.

Current finite increment: **P2a reopen an existing active session**, [PR #7](https://github.com/SobolGaming/Warhammer_40k_UI_unreal/pull/7), on `codex/p2a-reopen-session` from PR #6 merge `dbe186ff`. Implementation and bounded verification are complete at source20600a5, pending normal merge. It adds player-a known-ID reads/Open controls; P2A-V1/V2 passed actual visible verification. The deferred human/platform checklist HV-01–HV-06 remains unchecked with its own instructions and milestone ownership. PR #6/P1c is merged; its [native results](evidence/2026-10-24-p1c-core-adoption.md), [identities](evidence/2026-10-24-p1c-core-adoption.json) and [source reviews](evidence/2026-10-24-p1c-source-reviews.json) retain their exact scope.

P2a supporting evidence:

- [Native results](evidence/2026-10-24-p2a-native.json):45.439-second package build;16 Unit,4 resources and two real integration workflows in each Managed/Attach mode, totaling24 executions/22 names. Native request instrumentation verifies exactly two player GETs and no reopening mutation/admin request. Initial compilation and overlapping Core-start failures remain recorded.
- [Independent SOURCE reviews](evidence/2026-10-24-p2a-source-reviews.json): fresh CODE and separate requirements PASS at20600a5 within the finite affected-source scope; they do not substitute for runtime or visible results.
- [Visible known-session workflow](evidence/2026-10-24-p2a-visible.md), [machine-readable results](evidence/2026-10-24-p2a-visible.json): three sequential Attach clients retained one44.5 session across actual launches, copied/pasted its ID, reopened revisions1 and2 with local count0, committed one offered choice, refreshed hidden opposing state, and recovered from local invalid-ID rejection and real HTTP404. Board zoom/Frame board and field/panel isolation were observed; all clients/launchers exited0, with Core healthy after each client before its owner stopped it normally.

P1b supporting evidence:

- [Build and native checks](evidence/2026-10-24-p1b-native-checks.md), [machine-readable provenance](evidence/2026-10-24-p1b-native-checks.json): 83.439-second package build; eleven unit, four resource and two mode-specific integration executions, totaling 17 across four native launches/16 names. Original build/harness failures and native log diagnostics remain recorded.
- [Independent source-review record](evidence/2026-10-24-p1b-source-reviews.json): CODE and separate requirements PASS within their finite affected-source scope.
- [Visible packaged preview](evidence/2026-10-24-p1b-visible-preview.md), [machine-readable results](evidence/2026-10-24-p1b-visible-preview.json): Managed/Attach accepted one mission choice each at revision 2 and explicitly refreshed to a hidden decision; focus/F/frame/zoom/UI isolation and native Maximize/Restore framing observed. The intentional child-player-auth diagnostic displayed actual HTTP401 `authentication_required` without inventing a projection. Three normal Game/launcher exits, Config/environment/binary preservation and Core ownership were confirmed. Earlier supervisor/access-timeout failures and the ineffective corner drag remain distinct.

Completed P1a [PR #4](https://github.com/SobolGaming/Warhammer_40k_UI_unreal/pull/4) merged on 2026-10-24. Its [results](evidence/2026-10-24-p1a-windows-package.md), [provenance](evidence/2026-10-24-p1a-windows-package.json) and [Mermaid correction](evidence/2026-10-24-architecture-mermaid.json) retain exact earlier scopes and the then-active screen HOLD. Standing visible-test permission now applies until revoked. P1b used44.3.33. P1c explicitly adopts unmerged4f9 /44.5.0 in a separate runtime; earlier results are not transferred. Full P1, clean-machine proof and native Linux remain open.

[PR #3](https://github.com/SobolGaming/Warhammer_40k_UI_unreal/pull/3) merged as `2f9e0c11cee65f531be2d4eebe8e7e29532ebf64`. [Closed history through r156](unreal-migration-plan-through-r156.md) preserves its implementation/checklists. Its bounded [manual launcher](evidence/2026-10-24-live-core-camera-visible.md), [native input](evidence/2026-10-24-live-core-native-camera-input.md) and [cancellation](evidence/2026-10-24-live-core-cancellation.md) results retain their original source/workflow limits. The earlier manual F failure has cause unestablished; P1b's observed packaged F success does not rewrite it. Packaged held-button input, real OS switching/teardown and native Linux remain untested; general gameplay remains later bounded work. P1c's latest-Core adoption is complete within its recorded boundary.

Supporting research: [latest Core capability inventory](research/2026-10-24-latest-core-capabilities.md), with all 89 families, 16 HTTP paths and 26 rule sections at the exact unmerged development candidate; [source-target receipt](evidence/2026-10-24-p1b-source-targets.json).

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
