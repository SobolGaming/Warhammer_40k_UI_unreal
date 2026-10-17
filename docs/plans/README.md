# Plans

The [Unreal migration plan](unreal-migration-plan.md), revision 17, is canonical.
Section 0 holds research status, owner decisions and the next bounded gate. It
preserves the client-only scope, genuine 3D/parity requirements and separate
execution and acceptance criteria. Supporting findings live under [research](research/).

[BOOT01 Windows evidence](evidence/2026-10-16-boot01.md) records the approved C++
scaffold, probe/final builds, IDE generation and limits. The
[plan/BOOT01 PR was merged](evidence/2026-10-16-bootstrap-publication.md); the
[earlier publication/source record](evidence/2026-10-16-publication-and-e01-source.md)
retains the original access failure and source-only preparation.

Current E01-SLOW120 status is
**EXECUTION_EVIDENCE_RECORDED_FINAL_REVIEW_PENDING**. Normal run
`20261017T044903Z-b0169768` completed the [revision-7 packet](research/2026-10-16-e01-boundary-packet.md)
on executed source `d1189592a5f99bdee58cea25ae8546e5ee2e3623`. The
[factual result](evidence/2026-10-16-e01-slow120-result.json) and
[execution journal](evidence/2026-10-16-e01-boundary.md) record 87 Python units
in 15.167 seconds, 14 Capture checks including source/runtime/schema checks,
132 unique native successes and two automated evidence checks. The 135 pure
PowerShell controls with 39 stable inputs are separate pre-execution evidence.
Auxiliary privacy inspection and exact-byte promotion preceded Native. All six
real editor-settings before/after observations matched, alongside UBT/Config and
same-run wire checks. Owned execution is stopped.

Finalize the factual/documentation freeze, then launch separate fresh final CODE
and REQ contexts under OWN15; neither has launched. The
[C12 source-only descriptor](research/2026-10-17-e01-slow120-code-review-r12.md)
and auxiliary privacy inspection do not supply final acceptance roles. Actual
context/model/memory/read-only enforcement limits remain UNVERIFIED for the
auxiliary inspection. Full E01/M01/M02, G-RESEARCH/G-IMPLEMENT, the original
30-second budget, production responsiveness, UE HTTP, rendering, packaging,
Linux, Core #588/#589/#590 and RISK19 remain open or unaccepted.

After acceptance of the bounded E01 prerequisite, advance to the
[E02 architecture packet gate](research/2026-10-16-e02-world-input-packet.md).
That packet remains unchanged and planning only; E02 has not executed.
The [E01 continuation PR](https://github.com/SobolGaming/Warhammer_40k_UI_unreal/pull/2)
is recorded as a draft. Its last recorded GitHub result reported no checks, which
is not a CI pass; this update makes no current remote-state claim. OWN16's
[local checkpoint workflow](unreal-migration-plan.md#02-research-procedure-and-evidence-rules)
adds no publication or merge authority.

## Historical records

- The [byte-exact 030835 schema-2 archive](evidence/2026-10-17-e01-slow120-result-030835-schema2-history.json)
  retains source `c2614b2484a66bd8465b855e59b184d49b2b926d`, packet revision 6,
  87/14/132/2 results and the omitted six-editor-settings criterion as UNVERIFIED.
  Run `044903` has its own observations and does not retroactively pass `030835`.
- The [schema-1 archive](evidence/2026-10-17-e01-slow120-result-schema1-history.json)
  preserves the earlier diagnostic result, including the historical revision-4
  Native/Audit supplement. The journal retains every failed attempt, original
  30-second FAIL/UNKNOWN and all source/guard repair results.
- The [source/helper review history](research/2026-10-16-e01-boundary-review.md),
  [original acceptance audit](research/2026-10-16-e01-boundary-acceptance-audit.md)
  and [preliminary SLOW120 audit](research/2026-10-16-e01-slow120-acceptance-audit.md)
  retain their actual scope and limitations. They do not satisfy the pending final
  cumulative OWN15 roles. Detailed rounds 2–12 remain linked from the journal and
  canonical plan; their historical results are unchanged.
