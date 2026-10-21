# E04-A1G dependency-fact comparison SOURCE failure

Status is CLOSED_SOURCE_FAILED_DEPENDENCY_FACT_EQUALITY_REPAIR_REQUIRED.
Fresh independent SOURCE for 92d915fc11679e8ba4f7ec4346d24fa5c67adf81 against
e43ec1d3f451d2a8d33b1a526141a15f9e1d64e5 returned raw FAIL. The
[exact report](2026-10-21-e04a-game-source-review-92d915f.md) and
[factual receipt](../evidence/2026-10-21-e04a-game-source-failure-92d915f.json)
preserve the assessment and its limits.

Three dependency fact checks in Invoke-E04A1GProfileProof.ps1 (lines 566, 578
and 618) compare serialized JSON strings. Dictionary property order can therefore
make identical descriptors/reference facts compare unequal, refusing DependencyBuild
before launch or during postbuild validation. The packet requires structural
comparison with dictionary order ignored and array order/cardinality, exact keys,
scalar types/values and null distinctions preserved. Root confirmed the source
gap. No runtime reproduction or source repair occurred. The narrow correction is
to use the existing Equal-Data helper for these three comparisons while retaining
independent descriptor/hash checks.

The review process closed exit 0 in 560.7801594 seconds with confirmed exit and
cleanup, no timeout and final job accounting of 366 total/zero active. This process
success does not alter raw FAIL. Actual foreground closure preceded strict seals
of 12 raw and eight selected members, then root independently rehashed 789
frozen/control identities before first report/tool-value body inspection at
2026-10-21T13:31:37.5991391Z. All compared identities matched. The initial
selector's actual console bytes were persisted.

Root inspected all 47 retained command inputs: inert source/metadata/hash/clock
and permitted pinned read-only Git only. No helper, agent, network, connector,
candidate, native, build, test, GUI or Core execution was observed. The trace has
47 inputs/47 outputs and zero unmatched inputs/orphan outputs. Four returned
outputs contain clipping markers (ordinals 1, 3, 5 and 31). The initial root marker
query overcaptured escaped newlines and was clipped; a bounded query established
those four ordinals without altering evidence. Retained stderr contains skill-icon
and unsupported PowerShell snapshot warnings. Coverage counts are reviewer-reported;
all-byte delivery, consumption and comprehension remain unproved.

Selected actual metadata records one read-only/approval-never context and
memory_mode disabled, with the exact prompt plus one CRLF. Lower memory/feature
enforcement and universal isolation remain UNVERIFIED.

Root closed planned run 20261021T132014Z-5daec77b at
2026-10-21T13:33:47.6905847Z, rehashing all 625 frozen current files and observing
clean HEAD, no positive SOURCE admission, phase GO or native RunRoot. All nine
phases are NOT_RUN; actual Game attempts/checks are zero. Two inputs/two
attempts/52 checks remain planned. There is no retry authority.

Checkpoint this failure/report overlay, push and gh-verify OWN18 exact backup
before narrow source repair. Then checkpoint/verify repaired-source backup, derive
fresh bindings and obtain fresh affected SOURCE before any ordered native GO.
Final CODE and different REQ follow successful closed execution. Bounded A1E
acceptance, historical failures and the closed 073826d predecessor results remain
unchanged. OWN17 stays deferred/unproven, visible authority zero, Linux UNTESTED
and perpetual private source/API review consent unchanged. This metadata/report
overlay supplies no source repair, native launch or milestone acceptance.
