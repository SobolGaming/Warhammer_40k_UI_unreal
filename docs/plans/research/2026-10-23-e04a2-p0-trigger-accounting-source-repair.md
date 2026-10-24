# A2-P0 trigger-accounting source retention

Root adopted the minimal retention change at 2026-10-23T19:54:39.8672424Z (e820d4), followed by the criterion precision at 2026-10-23T19:55:28.3455532Z (3d7bda). [Adoption evidence](../evidence/2026-10-23-e04a2-p0-trigger-accounting-source-repair.json).

On a strict loop-accounting guard failure after a successful complete-size query, the source retains the same already-returned eight ACCOUNT fields, requested/returned size and Stopwatch query interval. It replaces the second Count query on that failure path. Initial/root-exit/final Count paths and query-error/size-mismatch behavior remain unchanged. The interval brackets observation; it is not an atomic kernel timestamp.

The strict condition, throw, termination, active-process limit, API set, deadlines, caps, paths and success predicate are unchanged. No PID list, cause attribution, policy relaxation or pass of the old native failure is supplied.

Current source is 29,365 bytes / 5A86A94BEEA4141A6F3F6F78DB0367C1E2D45488DDE90078C79F11B5E8E36D79. Current packet is 14,439 bytes / 02099B4272C1FCE3F74D09DAB01ACBDFA8F95BFCBAD5EF261E1C462E73405579; its earlier 10EF5AD9 packet identity is intermediate history only. Root recorded exact forward/inverses, exact guard-prefix removal and diff-check success. Compilation, successor runtime and fresh affected SOURCE are NOT_RUN; new head/run remain UNBOUND.

The d0aa425 SOURCE PASS covers its original source only. [Revision 134 native FAIL](2026-10-23-e04a2-p0-native-job-accounting-failure.md) and all raw evidence remain closed and unchanged. Its OWN18 failure backup precedes this adoption. Checkpoint/push/exact-gh-verify the repaired source, then create fresh bindings and obtain affected SOURCE before a separately bound runtime GO. No old authority transfers.

The 19:35 visible HOLD remains operative until explicit owner approval. Revision 131 bounded A1G acceptance/history remains; OWN17 is deferred/unproven, Linux UNTESTED and full A2/727/G-IMPLEMENT/final CODE/REQ gates remain open.
