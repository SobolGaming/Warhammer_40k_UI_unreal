# A2-P0 native capture failed on job accounting

The first native attempt for d0aa425e0b37a82642c1e60ce5659f32b5a33fe2 / run 20261023T192055Z-4a226106 is **FAIL**, closed without retry authority. The preceding [SOURCE PASS](2026-10-23-e04a2-p0-source-prerequisite-d0aa425.md) remains admitted and unchanged. [Failure evidence](../evidence/2026-10-23-e04a2-p0-native-job-accounting-failure.json).

The supervisor assigned root PID 33140 before resume with active-process limit 1. Accounting changed from total 1 / active 1 to total 2 / active 2. It retained primary and secondary “Single-root job accounting differs” errors and called TerminateJobObject. Root exit 2733637633 (0xA2F00001) was confirmed; final active count was 0, cleanup was confirmed within budget and both Python streams reached complete empty EOF.

Microsoft documents limit-rejected associations in TotalProcesses and temporarily in ActiveProcesses. These counters alone do not establish two running payloads or an ineffective active limit. [Accounting semantics](https://learn.microsoft.com/en-us/windows/win32/api/winnt/ns-winnt-jobobject_basic_accounting_information). Configured flags 8200 combine active-process 0x8 and kill-on-close 0x2000. [Limit flags](https://learn.microsoft.com/en-us/windows/win32/api/winnt/ns-winnt-jobobject_basic_limit_information). Both references were retrieved on 2026-10-23.

The identity and cause behind the counter change are UNATTRIBUTED. No retained PID evidence identifies Python, Core or a Windows helper as its cause. C# compilation succeeded and execution reached the resumed-process path; collector entry remains UNPROVEN. There is no capture file or completion result and zero captured profiles.

Outer worker PID 42624 exited 1, confirmed, after 1.7702389 seconds, without outer forced kill or timeout. Its positivePythonCleanupReceiptJoined remains false because the phase failed, while the child process receipt separately records cleanup true / final active 0. The retained worker failure metadata is distinct from the empty Python stdout/stderr.

Four retained files total 10,622 bytes with no unexpected paths. The initial artifact-freeze totalBytes remains null because its aggregate projection did not sum dictionary entries; the later explicit per-descriptor sum qualifies that immutable record without rewriting it.

Publish/checkpoint/push/exact-gh-verify this failure under OWN18 BEFORE actual repair, rebinding or diagnostic execution. Source remains frozen; no guard relaxation or repair has been adopted. All runtime authority is closed and cannot be reused. Finite read-only source/API diagnosis may continue.

**Renewed visible HOLD — reported owner message 2026-10-23 19:35 UTC:**

> Alright.  I'm back to using the screen.  Pause visible tests until I approve otherwise

Trusted relay thread 01a15972-8d00-76fb-b21e-78cded2ea00b; minute precision, original not independently retrieved. This supersedes the historical 19:10 availability until explicit owner approval. No visible testing is authorized. A1G acceptance/history remains; OWN17 deferred/unproven, Linux UNTESTED and full A2/727/G-IMPLEMENT/final CODE/REQ gates remain open.
