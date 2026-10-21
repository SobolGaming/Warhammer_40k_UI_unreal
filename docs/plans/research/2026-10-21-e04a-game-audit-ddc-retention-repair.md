# E04-A1G Audit DDC evidence retention repair

The Audit return now retains `ddc=$log.ddc`, the observation already produced by
`Check-A1GNativeLog` at the Audit boundary. This addresses CODE P2 and REQ-01 in
the [closed final reviews](2026-10-21-e04a-game-final-review-failure-closure.md).
It preserves the observed log-row count, owned directory and file count, and the
validator's finite scope. The validator and its failure conditions are unchanged.

Root applied the repair after failure checkpoint
`2c99fc3288f846593613e899e177ba86f9ee3537` was pushed and its exact remote SHA
verified. The [repair receipt](../evidence/2026-10-21-e04a-game-audit-ddc-retention-repair.json)
records the source identities and verified failure-backup receipt.

The only source change is a unique 13-byte insertion in
`scripts/migration/Invoke-E04A1GProfileProof.ps1`, in `Complete-A1GAuditPhase`.
Removing that insertion reproduces the whole prior source. The PowerShell parser
reported zero errors and 113 functions; all 169 CR bytes were preserved. These
are source checks. No behavioral execution or passing review is inferred.

Status is **AUDIT_DDC_RETENTION_REPAIRED_TRACE_SCOPE_DECISION_PENDING**.
Fresh affected SOURCE and all nine fresh phases are NOT_RUN; a new RunId is
UNBOUND and bindings are NOT_CREATED. The missing historical Audit observation
remains missing. Earlier raw results and both negative final reports are unchanged.

The [UBT trace output proposal](2026-10-21-e04a-game-ubt-trace-owner-choice.md)
remains UNADOPTED pending an owner scope decision. A1G acceptance remains withheld.
Checkpoint and verify a remote backup of this source repair before new bindings;
resolve trace scope before preparing the combined affected SOURCE review and a
fresh, separately authorized phase chain. No closed GO transfers. A2 remains
deferred, OWN17 remains deferred/unproven, visible authority is zero and Linux is
UNTESTED. Standing private source/API review consent remains in force.
