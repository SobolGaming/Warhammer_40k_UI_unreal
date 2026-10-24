# Plans and evidence index

[unreal-migration-plan.md](unreal-migration-plan.md) is the **single canonical root plan** for current scope, all feature-parity milestones and implementation/verification status. `unreal-development-plan.md` preserves old links as a pointer only. The owner has confirmed `Warhammer_40k_UI_arcade` as the Python UI baseline.

Current finite increment: **P1b Windows packaged interactive preview**, on `codex/p1-playable-preview` from PR #4 merge `7ba2c117`. Visible testing is now permitted until revoked. Focus guidance, viewer-safe decision status, clear option submission and real packaged Managed/Attach interactions are its boundary. The canonical plan keeps a fast usable-client path while the ultimate target includes all latest-Core-supported capabilities beyond Arcade.

Completed P1a [PR #4](https://github.com/SobolGaming/Warhammer_40k_UI_unreal/pull/4) merged on 2026-10-24. Its [results](evidence/2026-10-24-p1a-windows-package.md), [provenance](evidence/2026-10-24-p1a-windows-package.json) and [Mermaid correction](evidence/2026-10-24-architecture-mermaid.json) retain exact earlier scopes and the then-active screen HOLD. P1b's latest-source planning candidate is unmerged Core44.5.0 at `4f9bef0d`; runtime remains tested44.3.33 until staged adoption. Clean-machine proof and native Linux remain open.

[PR #3](https://github.com/SobolGaming/Warhammer_40k_UI_unreal/pull/3) merged as `2f9e0c11cee65f531be2d4eebe8e7e29532ebf64`. [Closed history through r156](unreal-migration-plan-through-r156.md) preserves its implementation/checklists. Its bounded [manual launcher](evidence/2026-10-24-live-core-camera-visible.md), [native input](evidence/2026-10-24-live-core-native-camera-input.md) and [cancellation](evidence/2026-10-24-live-core-cancellation.md) results remain valid only within their recorded source and workflow limits. The earlier manual F failure, real OS-switch/teardown gaps and native Linux UNTESTED status remain explicit.

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
