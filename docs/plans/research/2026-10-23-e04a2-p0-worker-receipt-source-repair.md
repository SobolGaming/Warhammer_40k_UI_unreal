# A2-P0 worker receipt repair: source adopted; fresh SOURCE pending

Root adopted the worker and two packet rows at 2026-10-23T20:49:44.1760785Z after the exact revision 138 failure checkpoint was backed up remotely. Status is WORKER_RECEIPT_SOURCE_REPAIRED_FRESH_SOURCE_PENDING. [Adoption evidence](../evidence/2026-10-23-e04a2-p0-worker-receipt-source-repair.json).

The worker reserves two seconds within its unchanged 70-second cooperative budget. After argv/environment preparation, it passes floor((68 − elapsed) × 1000) milliseconds to the supervisor and still refuses launch below 65,000 ms. Child 60 seconds, cleanup 5 seconds and the outer 75-second backstop remain.

A returned supervisor record receives one best-effort bounded CreateNew process-receipt attempt before Task-Tick. Dedicated receipt stat/hash does not reenter the deadline gate; a later deadline or write failure remains a separate worker failure. Original accounting/PID data remain in the unchanged 131,072-byte process receipt, with incomplete retention failing closed. Original supervisorPrimaryError is also separate completion metadata beside worker failure under the unchanged 4,096-byte completion cap. IO success and synchronous-call preemption are not promised; no path, process, retry or fatal-guard policy changes.

Root checked four exact worker replacements, removal of the 147-byte early guard, both whole inverses and only the P0-S07/S08 row changes. These are source/data checks, not compilation or runtime proof. Fresh affected SOURCE, compilation, controls and runtime are NOT_RUN; future head/run UNBOUND and bindings/GO NOT_CREATED.

Checkpoint/push/exact-gh back up repaired source, then refresh the canonical worker descriptor, MapD worker pin and complete API/packet/freeze/control bindings. Fresh affected SOURCE/root admission precedes separate GO. The Rev138 raw CHANGES_REQUESTED, c62/d0 native failures and revision 131 bounded A1G acceptance/history remain unchanged. The 19:35 visible HOLD, OWN17 deferred/unproven, Linux UNTESTED and full A2/727/G-IMPLEMENT/final CODE/REQ limits remain.
