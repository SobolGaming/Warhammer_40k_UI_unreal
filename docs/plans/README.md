# Migration plans and evidence

The [Unreal migration plan](unreal-migration-plan.md), revision 153, is the active plan. The owner startup/camera increment has a comprehensive Windows/Linux guide, implemented mouse controls and aspect-aware board framing. [Background checks and independent source reviews](evidence/2026-10-23-live-core-ergonomics.json) passed. The resumed [manual-launcher visible run](evidence/2026-10-24-live-core-camera-visible.md) verified startup keyboard navigation, real board fit across window sizes, wheel zoom, Frame board, UI wheel isolation, refresh preservation and one Core choice. F remains unresolved; held-button orbit/pan need the focused native input regression. All native Linux execution remains UNTESTED.

The [earlier visible workflow](evidence/2026-10-23-live-core-visible.md) at `4dacce3` (runtime `ca315fb`) demonstrated the bounded local setup slice, preserving its startup-focus error and camera crop. The [focus repair record](evidence/2026-10-23-live-core-focus-repair.json) covers compile/link, independent source reviews and non-graphical smoke at that time; the later [resumed visible run](evidence/2026-10-24-live-core-camera-visible.md) adds actual keyboard startup navigation. See [structured earlier evidence](evidence/2026-10-23-live-core-visible.json), [slice progress](evidence/2026-10-23-live-core-slice.md), [headless results](evidence/2026-10-23-live-core-headless.json) and [earlier review provenance](evidence/2026-10-23-live-core-reviews.json).

Implementation and verification have separate Markdown checklists. Publish the plan checkpoint before implementation; commit, push and exact-GitHub-verify every checkpoint. Continue [PR #3](https://github.com/SobolGaming/Warhammer_40k_UI_unreal/pull/3) without merging.

The owner directly resumed bounded camera/UI/startup/manual-launcher testing on October 24, superseding the prior HOLD for that scope. Use one game window at a time, a ten-minute launch limit and owned-process cleanup. The actual manual run is closed; a focused synthetic native Slate input test is being prepared separately. Linux remains UNTESTED; profiles/roundtrip/727, full gameplay and broad certification remain deferred.

- [BOOT01](evidence/2026-10-16-boot01.md)
- [E01 original boundary](evidence/2026-10-16-e01-boundary.md), [SLOW120 provenance](evidence/2026-10-17-e01-slow120-final-review-provenance.json)
- [Bounded E02 acceptance](evidence/2026-10-20-e02-bounded-acceptance.json)
- [A1G final provenance](evidence/2026-10-23-e04a-game-final-review-provenance.json)
- [Bounded P0 final acceptance](evidence/2026-10-23-e04a2-p0-final-acceptance.json)
- [Deferred canonical-roundtrip source](research/2026-10-23-e04a2-canonical-roundtrip-source-adoption.md)
- [Complete through-r146 plan](unreal-migration-plan-through-r146.md)
- [Complete through-r146 route index](README-through-r146.md)
- [Repository instructions](../../AGENTS.md)
