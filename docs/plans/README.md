# Migration plans and evidence

The [Unreal development plan](unreal-development-plan.md) is the single forward roadmap to Python UI feature parity. It inventories the explicit Arcade/Core baselines, maps every CAP01–CAP36 capability to ordered milestones and separates implementation from acceptance. Standalone packaging, complete interaction editors, profiles/HUD, viewer modes, recovery, native Linux and release work remain open. The requested `_python` repository name is explicitly interpreted as the available Arcade baseline unless a distinct repository is supplied.

The [migration/closing record](unreal-migration-plan.md), revision 155, tracks the current cancellation closure and earlier evidence. The owner startup/camera increment has a comprehensive Windows/Linux guide, implemented mouse controls and aspect-aware board framing. [Background checks and independent source reviews](evidence/2026-10-23-live-core-ergonomics.json) passed. The resumed [manual-launcher visible run](evidence/2026-10-24-live-core-camera-visible.md) verified startup keyboard navigation, real board fit across window sizes, wheel zoom, Frame board, UI wheel isolation, refresh preservation and one Core choice. The separate [native camera input check](evidence/2026-10-24-live-core-native-camera-input.md) passed 92 assertions for actual held orbit/pan, release, zoom clamps, F routing and UI isolation with synthetic bounds. The earlier manual F failure remains unresolved. All native Linux execution remains UNTESTED.

The [earlier visible workflow](evidence/2026-10-23-live-core-visible.md) at `4dacce3` (runtime `ca315fb`) demonstrated the bounded local setup slice, preserving its startup-focus error and camera crop. The [focus repair record](evidence/2026-10-23-live-core-focus-repair.json) covers compile/link, independent source reviews and non-graphical smoke at that time; the later [resumed visible run](evidence/2026-10-24-live-core-camera-visible.md) adds actual keyboard startup navigation. See [structured earlier evidence](evidence/2026-10-23-live-core-visible.json), [slice progress](evidence/2026-10-23-live-core-slice.md), [headless results](evidence/2026-10-23-live-core-headless.json) and [earlier review provenance](evidence/2026-10-23-live-core-reviews.json).

Implementation and verification have separate Markdown checklists. Publish the plan checkpoint before implementation; commit, push and exact-GitHub-verify every checkpoint. The owner's latest direction authorizes closing cancellation checks, publishing the full roadmap and merging existing [PR #3](https://github.com/SobolGaming/Warhammer_40k_UI_unreal/pull/3) once affected checks and independent reviews pass. That supersedes the earlier no-merge direction.

The owner directly resumed bounded camera/UI/startup/manual-launcher testing on October 24, superseding the prior HOLD for that scope. Both the manual run and native input test are closed; no game window remains. Each used one game window, a ten-minute launch limit and owned-process cleanup. Active-drag cancellation and Linux remain unverified; profiles/roundtrip/727, full gameplay and broad certification remain deferred.

- [BOOT01](evidence/2026-10-16-boot01.md)
- [E01 original boundary](evidence/2026-10-16-e01-boundary.md), [SLOW120 provenance](evidence/2026-10-17-e01-slow120-final-review-provenance.json)
- [Bounded E02 acceptance](evidence/2026-10-20-e02-bounded-acceptance.json)
- [A1G final provenance](evidence/2026-10-23-e04a-game-final-review-provenance.json)
- [Bounded P0 final acceptance](evidence/2026-10-23-e04a2-p0-final-acceptance.json)
- [Deferred canonical-roundtrip source](research/2026-10-23-e04a2-canonical-roundtrip-source-adoption.md)
- [Complete through-r146 plan](unreal-migration-plan-through-r146.md)
- [Complete through-r146 route index](README-through-r146.md)
- [Repository instructions](../../AGENTS.md)
