# Migration plans and evidence

The [Unreal migration plan](unreal-migration-plan.md), revision148, is the active plan. It prioritizes the smallest useful rendered client driving the existing Core: board, real session/state, one offered action and authoritative result.

Candidate `ca315fb` passed the Windows Editor compile/link and ten native checks, including actual Core session/action/refresh and rejection-diagnostic fidelity. Initial review findings were corrected; fresh affected CODE and separate requirements reviews passed. See [slice progress](evidence/2026-10-23-live-core-slice.md), [headless results](evidence/2026-10-23-live-core-headless.json) and [review provenance](evidence/2026-10-23-live-core-reviews.json). Rendered slice acceptance remains pending.

Implementation and verification have separate Markdown checklists. Publish the plan checkpoint before implementation; commit, push and exact-GitHub-verify every checkpoint. Continue [PR #3](https://github.com/SobolGaming/Warhammer_40k_UI_unreal/pull/3) without merging.

Visible tests remain on HOLD pending explicit owner resumption. Linux remains UNTESTED. Exhaustive profiles/roundtrip/727 and broad certification are deferred; ordinary builds, focused functional checks and independent CODE/different requirements review precede acceptance.

- [BOOT01](evidence/2026-10-16-boot01.md)
- [E01 original boundary](evidence/2026-10-16-e01-boundary.md), [SLOW120 provenance](evidence/2026-10-17-e01-slow120-final-review-provenance.json)
- [Bounded E02 acceptance](evidence/2026-10-20-e02-bounded-acceptance.json)
- [A1G final provenance](evidence/2026-10-23-e04a-game-final-review-provenance.json)
- [Bounded P0 final acceptance](evidence/2026-10-23-e04a2-p0-final-acceptance.json)
- [Deferred canonical-roundtrip source](research/2026-10-23-e04a2-canonical-roundtrip-source-adoption.md)
- [Complete through-r146 plan](unreal-migration-plan-through-r146.md)
- [Complete through-r146 route index](README-through-r146.md)
- [Repository instructions](../../AGENTS.md)
