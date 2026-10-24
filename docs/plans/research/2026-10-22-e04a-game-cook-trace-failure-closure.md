# E04-A1G Cook trace failure closure

Run 20261022T192551Z-711fa6f6 for source
a8980572ca05e9b1a32880915e7b8cbf5cb0d337 closed after Cook failed with
`FAIL_UBT_TRACE_EXCEPTION_OBSERVATION_OR_RECOVERY`. The five predecessor phases—Preflight,
DependencyConfigure, DependencyBuild, EditorPrerequisiteBuild and GameBuild—passed and
were root-admitted. The repaired-source [SOURCE prerequisite](2026-10-22-e04a-game-source-prerequisite-a898057.md)
remains PASS; its [original report](2026-10-22-e04a-game-source-review-a898057.md) and
[exact Base64 representation](2026-10-22-e04a-game-source-review-a898057.json) remain unchanged.
The [factual receipt](../evidence/2026-10-22-e04a-game-cook-trace-failure.json) binds the
exact root closure and post-failure preservation records. Status is
**COOK_TRACE_VALIDATION_FAILURE_SCOPE_REVIEW_PENDING**; no repair or retry is adopted.

Root's inspected child output records Cook commandlet success in about 308.32 seconds;
BuildCookRun reported 328.66 seconds, UAT exited 0, and Cook had zero errors/warnings. The whole phase failed
after 440.0249346 seconds when final trace observation hit
`A1G_DATA_CHANGED: trace unchanged outside the two approved UBT roots`.
The raw primary failure is null and this explicit failure is retained in secondary
errors under `ubt-trace-observation-recovery`; null primary does not mean phase success.
Cook has no completion record or positive root admission. Outer PowerShell closed exit 1
without timeout, with complete stream copies. All five supervised roots closed with
confirmed cleanup and final active-job counts zero.

The logged `-Mode=ValidatePlatforms -OutputSDKs -AllPlatforms` invocation occurs during
Cook, beyond the [clean norm's](2026-10-21-e04a-game-proof-packet.md) approved two build-root
trace transitions. Root read installed TargetPlatformManagerModule.cpp lines 221..238
and 366..408, which launch SDK validation inside the Editor child; actual closed child
stdout lines 42/61 record that invocation. The pinned 61188-byte installed source has
SHA256 E86827925AECB8ED2250F5D7AB655269ED7FE6A83D6691B244FA36FAAD5A4E17.
This finite source finding explains the observed route; it does not establish
installed-source/binary correspondence or universal writer attribution. The recorded trace changed from
9917 to 319 bytes; the 9228-byte oldest backup was pruned, and a new 9917-byte backup
matches the preceding Game trace bytes. Before/after family totals were 11 files/76584
bytes and 11 files/67675 bytes. These finite observations do not establish universal
writer attribution or approve a third trace-producing path.

The [SDK trace owner-choice proposal](2026-10-22-e04a-game-cook-sdk-trace-owner-choice.md)
is UNADOPTED and grants no repair, retry or expanded writer scope. The supported skip
route assumes all platforms valid; Multiprocess changes semantics and NoAutoSDK does
not bypass this native SDK check. The finite Stage investigation found no known SDK
writer under Build=False/skipcook/defaultRunChunkAssigner=false, so no Stage scope
extension is proposed. None of these findings approves a workaround.

Root's exact 60474-byte closure has SHA256
0014F77BE7E7F21E94C33D2722BCB40090046508436E20FBA294B218EDC96614.
It records all 84 finite source/stage/fixture/settings states matched, zero changed,
all six phases' recorded before/after arrays matched, 456 retained-artifact descriptor
occurrences and 30 predecessor descriptor occurrences matched. After failure, root
copied 11 opaque trace-family files/67675 bytes into owned recovery storage. The
10464-byte recovery record has SHA256
1DE608298FAF9B147DF14BD6EF204E32A26A1D10BD937EB44955D90C98DEAA94.
This later copy preserves observed bytes; it does not reconstruct missing phase
before/after recovery, satisfy the failed guard or modify global paths. Preservation
and technical findings here are attributed to those root records; this publication
preparation opened no historical global trace files and reran no native checks.

Stage, Native, Audit and final CODE/REQ are NOT_RUN, with no successor GOs. The seven
pure synthetic trace-policy controls remain a separate post-SOURCE-admission check,
not SOURCE reviewer, native or end-to-end execution. The success-closure writer stays
unexecuted. There is no new Game runtime/graphical proof or A1G acceptance.

Checkpoint, push and exact gh-verify this failure under OWN18 before any repair.
Source causality and scope need resolution; no fix, retry or expanded trace scope is
authorized by this record. Any adopted repair then needs its own source checkpoint/
verified backup, fresh exact bindings, affected SOURCE and separate ordered phase GOs.
Preserve revision 122, all earlier failures/raw records, the separate settings
restoration and bounded A1E acceptance. OWN17 stays deferred/unproven, visible authority
zero, Linux UNTESTED, A2 deferred and perpetual private source/API review consent unchanged.
