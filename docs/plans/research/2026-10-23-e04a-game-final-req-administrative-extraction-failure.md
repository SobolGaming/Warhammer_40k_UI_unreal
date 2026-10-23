# E04 A1G final REQ administrative extraction failure

Revision 129 records **FINAL_REQ_ADMIN_EVIDENCE_INADMISSIBLE_CODE_AUDIT_PENDING** for final-review candidate `cb9e4588408b142c5b3908e7061b58a350b26376`, execution source `c329a3a32dca48272e29bad46af616bcc6bdebd4`, run `20261023T154418Z-ce672e5f`.

FINAL_REQ foreground closed with exit 0, observed by root at `2026-10-23T17:21:25.0589005Z` (`f4a872`); the 12-member raw seal completed (`f35515`). The final selector ran and created its selected runtime. Root then incorrectly checked native `$LASTEXITCODE` after an in-process PowerShell script and threw before saving the actual selector console stdout. That stdout is unrecoverable. Preserve this invocation; do not reconstruct the console or rerun the selector.

The REQ report body and its raw component verdict remain **UNREAD**. The eight-member selected seal and independent root rehash before first body read were **NOT_COMPLETED**. This makes the administrative evidence inadmissible; it establishes no component failure or other component verdict. A fresh independent REQ is needed. CODE strict closure, seal and rehash are separately complete. Root subsequently reported reading its raw PASS body; the root audit remains in progress and no admission is inferred here.

The [evidence receipt](../evidence/2026-10-23-e04a-game-final-req-administrative-extraction-failure.json) binds the immutable root administrative record by its supplied descriptor. This note uses root-supplied administrative facts and canonical metadata; no current review output, report or ledger was read to draft it.

Publish/checkpoint/push/gh-verify this failure before fresh REQ preparation. Keep candidate source, current raw review artifacts, [revision 128 execution closure](2026-10-23-e04a-game-execution-closure.md) and all earlier history unchanged. A1G acceptance remains withheld. No candidate repair, launch binding or authority expansion follows. Execution remains closed with no retry or successor GO; the visible hold remains in effect and visible authority is zero. OWN17 remains deferred/unproven, Linux UNTESTED and A2 deferred; perpetual private source/API review consent is unchanged.
