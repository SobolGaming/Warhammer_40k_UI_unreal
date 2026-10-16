# Plans

- [Unreal migration plan](unreal-migration-plan.md) — canonical owner-requested import
  from the Arcade repository, with Section 0 research in progress. It preserves the
  client-only scope, genuine 3D and parity requirements, and separate execution gates.

Supporting source, environment and contract findings live under [research](research/).
Research question status and owner decisions belong in the canonical plan.

[BOOT01 Windows execution evidence](evidence/2026-10-16-boot01.md) records the
approved C++ scaffold, probe/final builds, IDE generation and review limits.

The [plan/BOOT01 PR was merged](evidence/2026-10-16-bootstrap-publication.md).
The earlier [publication/source-preparation record](evidence/2026-10-16-publication-and-e01-source.md)
preserves the original access failure and source-only preparation.

Current work follows the frozen [bounded E01 packet](research/2026-10-16-e01-boundary-packet.md).
Its [execution journal](evidence/2026-10-16-e01-boundary.md) records the installed
runtime, failed attempts and actual checks separately from pending acceptance.
The [independent source review](research/2026-10-16-e01-boundary-review.md) passed;
the [acceptance audit](research/2026-10-16-e01-boundary-acceptance-audit.md) keeps
E01 unaccepted after the 30-second command timeout tracked in Core #590. Native,
Audit and fixture promotion remain gated. The [E02 architecture packet](research/2026-10-16-e02-world-input-packet.md)
is prepared conditionally and has not executed.
