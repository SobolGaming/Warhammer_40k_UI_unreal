# E01 bounded boundary acceptance audit

Date: 2026-10-16. Independent acceptance auditor invocation:
`/root/e01_final_acceptance`. **Final disposition: NOT_ACCEPTED.
E01-WIN-BOUNDARY failed required movement criteria; Native, wrapper Audit and
wire promotion remain gated. Full E01, M01, G-RESEARCH and G-IMPLEMENT are not
accepted.** The final addendum below supersedes the explicitly preliminary
snapshot while preserving it. The wrapper's Audit phase cannot supply this
independent decision. Machine-readable facts are in the
[result record](../evidence/2026-10-16-e01-boundary-result.json).

## Authority and independence

The auditor read the workspace, Unreal and Arcade AGENTS instructions, canonical
plan Section 0 and E01/M01 criteria, packet revision 2, separate source-review
record, execution journal and actual ignored run records. The permitted output
is this new acceptance record and, only after outcomes are final, its optional
result JSON. The auditor authored none of the wrapper, Python driver/tests,
native reader/tests or fixture candidates; it did not launch a host, install a
dependency, run the harness/build/Automation, modify an engine or sibling, or
share a mutable game session. Read-only file/JSON/hash and Git inspection is
distinct from executing those checks. This is a separate agent invocation under
the coordinator, not evidence of an externally isolated human review.

OWN13 permits the recorded bounded continuation. The selected scope is
E01-WIN-BOUNDARY using the exact external development host and fixed development
registry. It does not establish production security, native UE HTTP scheduling,
rendering, packaging, Linux execution or full migration implementation authority.

## Frozen inputs inspected

The merged PR1 base is `0467ee63fe6d4c775f429afae2233d7292787c31`.
Current candidate HEAD at inspection is
`e3f07cda8bd5b66295af1ab26a04a6c9a6684631`.
Preflight recorded `9f7e171d0e36e02f4e4b1d48037ae820c952d02a`; its narrower
packet/wrapper/inventory freeze is valid only for preparation. The packet
expressly permits the separately reviewed Python/native phase freezes. No earlier
HEAD or source count is silently used as the identity of a later executed phase.

Raw-byte hashes independently read by this auditor:

| Input | SHA256 |
| --- | --- |
| Packet revision 2 | `DA568F9BFAE7666C1CECB549B2A05B7930F5341541E25FDB96A6F08CF27B7C1F` |
| Wrapper | `5250D25BDA372AF0D8D6F8B77CDA6ACD63DBD678C0A35FAF268A2C9F8B6A5FEA` |
| Python driver | `469C07B909EBAF315073D1426941D1AADD50DECD65A76706E0CA952408BBF0C1` |
| Python tests | `F5528357299473C628AFE1DD504BAAA62858A82329001648E22FB894160D0052` |
| Native header | `ADA9FA50D1273CB85485CDF998943BD0D0D5617C7743154C16F155BD7808A153` |
| Native reader | `217D3EF245AA610EE99FA9E87223F8A9FA844AE1C99DA996633D41D28E82DBF8` |
| Native tests | `C24760C683960CA99376454DD42E3AC657C3A37B79C1BC7B466B622B5B602665` |
| Build.cs | `61286F8F12FFC90FF02F8369392479588374A8CFF6B351518CA66386C771FEFB` |
| Original source inventory manifest | `BF861B2EC555C81E85A31E4B37E756C5E6B04D343522A95F3235700C2AEC43F2` |
| Source-review record at preliminary inspection | `4062C01D2AE3C42D9F9A34AE72811F2B5F67B427F4AAA953A6AA2987712E5D31` |

The source-review invocation `/root/e01_frozen_review_record` separately reviewed
the initial candidate and the wrapper/Python deltas. Its final combined source
disposition is PASS for these hashes. F01/F02 are CLOSED_SOURCE, with their
earlier OPEN findings preserved. That disposition is source approval only:
Python now preserves valid rejected/uncommitted command outcomes, while the
wrapper refuses any runtime `.pyc`. A supported response shape is not an
observation that the actual host returned it.

Core remains `5f509724da25a2f6ded0c2739a8e7c84bdf59c91`, Contract 44.3.33,
runtime build
`warhammer40k-core-v2:runtime-tree-sha256-v1:65fc8414407ae5d6a8ea779c8e737a22733459094db679a160c60f6e2129f96a`,
3,116 resources. Arcade remains
`5088c1c49dcaff29eb59fb64b3063d30214dde73`. Source identity, installed identity,
schema consumption and live behavior are separate evidence classes.

## Fresh run observed so far

Run root: ignored `.local/experiments/E01-target/20261016T231112Z-f8ef82ca/`.
At this preliminary inspection Capture had a start marker but no final result
or scenario report; Native and wrapper Audit had no result. No in-progress
file or console line supplies a final phase PASS.

| Phase | Actual status and time | Result raw SHA256 |
| --- | --- | --- |
| Preflight | `SOURCE_INVENTORY_PASS`, 23:11:12.931013Z–23:12:00.7161356Z | `9C34488E9D63A65DEC0321C60318465DBA337A750E004D3CC9C3F928CDA9AF30` |
| PrepareRuntime | `INSTALLED_RUNTIME_PASS`, 23:12:16.7758845Z–23:13:00.5876303Z; verified reuse | `95FFDF39C3744BE295874F311A42802E79055C651135B7D789C1423D0326706D` |
| Capture | Started 23:13:11.9774032Z; final status PENDING | No final result yet |
| Native | NOT RUN at preliminary inspection | No result |
| Wrapper Audit | NOT RUN at preliminary inspection | No result |

Both completed phase records preserve 127 source inventory members, 98 canonical
case IDs and exact installed build/resource identity. Runtime tree SHA256 is
`B01989FC595730D8EA6F1A10C7A5004510FCA877A9B69AAD9F3285CAB357A897`;
provenance SHA256 is
`39C485C33E482B158EDB157A0FFAA69224C09E15DE5655277B64289887F7CF7C`.
Their before/after records show both sibling HEADs unchanged and both statuses
empty. All their recorded children exited 0 without timeout and passed output
scanning. These completed phase records do not prove Capture cleanup.

The fresh Capture unit log explicitly says **38 tests in 0.108s, OK**. Its final
wrapper child exit, scan disposition and artifact hash remain to be frozen.
This executed unit output is not a live scenario result or a native test count.

## Required final evidence mapping

Each row must be mapped to its final case-level result and hashed artifact.
The Python driver adds `RUNTIME-01` and `SCHEMA-01` to the packet's twelve Python
case IDs, so an intact scenario report has **14 discovered** cases. `NATIVE-01`
belongs to the separate nonempty exported native suite. Blocked, failed,
unexecuted and excluded cases must remain distinct from passed counts.

| Required row | Acceptance test for the final audit | Preliminary status |
| --- | --- | --- |
| SOURCE-01 | Exact source, 127 members, 234 normalized contract hashes and exactly 98 unique IDs: 73 finite, one nested, 24 parameterized | Preparation PASS; final scenario evidence pending |
| RUNTIME-01 | Exact installed interpreter/package, build, 3,116 resources, approved native imports and unchanged verified tree/provenance | PrepareRuntime PASS; final scenario evidence pending |
| SCHEMA-01 | Local frozen registry validates copied schema/example associations without network resolution; actual positive count | Pending final Capture report |
| FINITE-01 | Offered action under bound player, preserved opaque IDs/revision, accepted once; same-input local/HTTP refreshed views and outcomes agree | Pending final Capture report |
| MOVE-01 | Complete current physical-model witness, reviewed sequential order, real one-inch accepted movement and each requested endpoint in the authoritative projection | Pending final Capture report |
| MOVE-02 | Wrong/missing/duplicate inventories leave revision/request/history unchanged; complete rule-invalid geometry records one rejected attempt and fresh request; current valid retry accepted | Pending final Capture report |
| RETRY-01 | Exact same envelope and scope apply once; changed envelope conflicts; injected response loss labelled; displayed revision cannot roll back | Pending final Capture report |
| STALE-01 | Wrong revision, consumed request and waiting advance preserve actual typed results; no uncertain retry silently rewritten | Pending final Capture report |
| AUTH-01 | Distinct explicit player/opponent/coach/delayed/admin/replay/missing/invalid contexts deny as required without hidden IDs/options/counts | Pending final Capture report and privacy review |
| VIEW-01 | Matching authorized local/HTTP role views/events, delayed revision/cursor behavior and live replay denial; privileged lane separate | Pending final Capture report and privacy review |
| ERROR-01 | Actual 400/401/403/404/409 and both live 422 representations; strict malformed/flag/type negatives additionally executed in unit/native lanes | Pending final Capture report and Native |
| FIDELITY-01 | Exact wire 422 status/code/message plus missing-detail notice and Core #588; local diagnostic never attributed to HTTP | Pending final Capture report |
| SCOPE-01 | Deterministic client state invalidates old viewer/session generations, callbacks, cursors and drafts | Pending final Capture report; UE scheduling excluded |
| LIFETIME-01 | Client occupied-port refusal before launch, attach worker ownership/disconnect, other session survival, owned stop and restart SessionLost; actual child exits/cleanup | Pending final Capture report; late co-bind excluded/unproved |
| NATIVE-01 | Frozen compiled reader consumes every canonical envelope and all accepted wire cases; positive exported discovered/executed/passed counts and no failures/skips/missing-fixture success | NOT RUN |
| Privacy/review | Actual final index entries, roles, paths and byte hashes match promoted files; no admin/raw/private capture promotion; separate reviewer invocation and dispositions | Pending final capture privacy review |
| Native environment | Exact engine/compiler/SDK/build command; actual owned DDC log path; before/after real-user settings guard; no unreported global configuration change | NOT RUN |
| Wrapper Audit | Final source/runtime/fixture/predecessor hashes and positive native results verified; phase children/timeouts/scans and sibling preservation recorded | NOT RUN |

The source-reposition case remains synthetic/envelope-only. An unavailable
reviewed terminal replay completion procedure stays `VIEW-TERMINAL-REPLAY:
NOT_RUN`, explicitly excluded from this subset and still an obligation for full
E01. Ninety-eight consumed envelopes do not establish ninety-eight live workflows
or full E08 parity.

## Preserved failures and acceptance limits

The [execution journal](../evidence/2026-10-16-e01-boundary.md) preserves attempts
1–8 and their candidates. In particular, attempt 8
`20261016T230019Z-9a9e3232` actually passed 34 unit tests, but Capture failed:
14 scenario cases discovered, 13 executed, ten passed, three timed out/failed
(`MOVE-01`, `MOVE-02`, `FIDELITY-01`) and one blocked (`ERROR-01`). Its wrapper
result hash is
`B53FF756F6D12A7F9B5C82213D2B898EECF9BE56CA39E24C394EDBC47E85982B`;
scenario report hash is
`B564CEFE77324F76FEE588A62B56A12C2C9573582DBC11857D9C93FF812F31A7`.
The fresh packet raises the socket-read cap while retaining the 30-second total
deadline. It creates a fresh run/session; it does not turn an uncertain action
in that old run into accepted, rejected, rolled back or safe to resubmit under
a new command ID. Later server HTTP200/disconnected-client logs leave that old
client-visible outcome **UNKNOWN**.

Attempt 7's actual Windows direct-host busy-port failure is retained. The client
probe in attempt 8 is a narrower bounded success. The probe closes before Core
binds: **late Windows co-bind protection is NOT_PROVEN; Core #589 / EXT08 OPEN**.
This cannot be reported as robust/exclusive managed-host ownership. Core was
not edited. **RISK19 OPEN** likewise retains the native JSON reader's explicit
unsupported case-colliding-key behavior; this is not arbitrary JSON production
compatibility acceptance.

Core #588's diagnostic fidelity gap is accepted by the owner's display policy:
show actual status/code/message and disclose that detailed reasons were absent.
It is not repaired by this client proof. Development credentials, loopback attach
and in-memory restart SessionLost are bounded evidence, not production credential
provisioning, remote TLS/authentication or durable restart recovery.

Linux is deferred/UNTESTED. Native UE HTTP transport/callback scheduling,
rendered interaction, genuine 3D, packaging/relocation/offline delivery,
clean-machine execution, performance, full terminal replay, remaining live
variants and full E08/M01 capability evidence remain unexecuted or incomplete.
No eventual bounded PASS may close full E01/M01 or the implementation gate by
implication. The next audit action is to inspect frozen final outputs, final
privacy review and actual Native/Audit results, then append an explicit bounded
PASS/FAIL/BLOCKED decision with exact counts, hashes and remaining obligations.

## Final addendum: failed Capture, 2026-10-16T23:30:37Z

**E01-WIN-BOUNDARY: NOT_ACCEPTED. Capture: FAIL. Further phases:
BLOCKED_BY_CAPTURE_FAILURE / NOT_RUN.** This is an evidence-based rejection of
completion, not a rollback of the independently passed source review or actual
partial runtime checks. There is no accepted fixture corpus or native runtime
proof. An owner budget decision or a future Core change is not yet a new approved
execution packet.

The final Capture wrapper records candidate
`e3f07cda8bd5b66295af1ab26a04a6c9a6684631` and the packet/wrapper/Python/tests/
inventory hashes listed above. The auditor re-read the executable source hashes
after completion; they were unchanged. Capture ran
**23:13:11.9774032Z–23:28:43.7639931Z**, 931.7865899 seconds. Its scenario child
exited **2**, without the wrapper's 1,800-second process timeout. Unit child
PID17088 exited **0**; its log and wrapper agree on **38 executed tests, PASS**,
with the log's **0.108s** duration. Source review PASS remains source evidence;
it cannot override these failed runtime criteria.

| Final artifact beneath the fresh ignored run | Raw SHA256 |
| --- | --- |
| `capture/result.json` | `BE12B37856D27556288085F166A2ADDC33A07F1E7D40EB76FAF4D7F06DD69D4F` |
| `capture/python-capture/report.json` | `0227A04BEE040ECE58D46F47777B57C7A88C495FD3608EF6968E713725A1D22C` |
| `capture/python-unittest.stderr.log` | `FA509D47D57E457887CF2C75468B4C92D190E50527D40F55BD2AC24C63556897` |
| `capture/python-capture/proposed-wire/index.json` | `76D5779391104D9828FFD2B48A90868E30B177F4CB5CBBC63A39E3F788821080` |
| `capture/python-capture/private-trace.json` | `37A8DA528E8F0D1830A725789167884B3118D0EAC02D697627063B6FA1AED410` |
| `capture/python-capture/private-attempts/command_35/playerA.json` | `81D57998C7ECBF33801D75138D657B720C1788D2CA0B586F6A3F576487034C1E` |
| `capture/python-capture/attach-worker.json` | `06B25B1A01AFEE6896CBA8C0F02D10B69667CACE743FC34C6116AF756F3EBA09` |
| `capture/python-capture/managed-primary/host.log` | `562C4EB364CEFE5869C97FBB0D4A024E18110383B10A8C3ACAFF7D3990F73B07` |

The completed scenario report records **14 discovered, 13 executed, 11 passed,
two failed, one blocked and zero NOT_RUN among those 14**. The separately
excluded terminal-replay case is NOT_RUN and is not hidden inside the passed
count. The report's case-level results map to the packet as follows:

| Required row | Final actual result and acceptance consequence |
| --- | --- |
| SOURCE-01 | PASS: selected Core, 127 members, 234 normalized contract hashes and 98 unique canonical IDs. Catalogue consumption remains shape coverage. |
| RUNTIME-01 | PASS: exact installed build, 3,116 resources and isolated imports. Capture retains the verified runtime tree/provenance identities above. |
| SCHEMA-01 | PASS: 93 examples validated through the frozen local registry, network resolution false. This is schema evidence, not 93 executed workflows. |
| SCOPE-01 | PASS: deterministic client reducer assertions; actual UE scheduling remains NOT_RUN. |
| AUTH-01 | PASS in the scenario report for explicit denied contexts and scoped errors. The captured subset's negative bodies have only schema/error code/message fields; administrator response remains privileged. |
| VIEW-01 | PASS in the scenario report for local/HTTP authorized projections/events, delay, scoped cursors and live replay denial. Full terminal replay stays excluded/NOT_RUN. |
| FINITE-01 | PASS: offered `decision-request-000001`, option `fixed:assassination:bring_it_down`, command `e01-finite-decision-request-000001`, revision 1→2 and matching authorized local/HTTP outcome. |
| RETRY-01 | PASS: same-scope byte-equivalent response at revision 2, changed-envelope conflict and labelled injected response loss; no display rollback via SCOPE-01. Retried response SHA256 `B19C9FFDD7BF6BC7ED52F1D88A897252DA8406764166D68B6E3A3B646FD6C913`. |
| STALE-01 | PASS: actual `session_revision_conflict`, `access_denied` for consumed request and `advance_not_required` errors preserved. |
| FIDELITY-01 | PASS: three actual missing/duplicate/wrong inventory rejections, HTTP422, `proposal_invalid`, `Submitted proposal was invalid.` Each raw body is `D7E7E71324B3758AF840FE7046F1B914C3E0EDB70D815F1054238485C06320B0`. The detailed-reasons-absent notice and Core #588 remain explicit. |
| MOVE-01 | FAIL: `timed out`. The actual normal-move request was reached, but no completed accepted one-inch move or endpoint comparison was obtained. |
| MOVE-02 | FAIL: `timed out`. The three inventory negatives completed with unchanged visible revision/pose/request/history assertions before the geometric submission. The required recorded-invalid branch, fresh retry and accepted valid witness were not completed. Partial inventory success cannot pass the whole case. |
| ERROR-01 | BLOCKED: both real 422 branches unavailable because the movement predecessor did not complete. Actual 400/401/403/404/409 and uncommitted-inventory422 evidence do not substitute for the missing completed recorded-invalid outcome. |
| LIFETIME-01 | PASS for the explicitly narrower client prelaunch probe, scoped attach/disconnect, owned stop and restart SessionLost checks. Late co-bind remains NOT_PROVEN / EXT08. |
| NATIVE-01 | NOT_RUN: no Native result, build or exported Automation case count. Native source coverage cannot pass this row. |

The finite/retry/stale/view assertions compare the same-build local and HTTP
lanes using the report's declared normalization: only operational timestamps and
authenticated opaque cursor tokens are ignored. Original bytes/hashes remain.
Their success does not establish a matching completed movement trace.

### Uncertain geometric command and measured limits

The retained private snapshot is explicitly pre-submission evidence with no
completion asserted. It identifies role playerA, normal-move proposal,
`decision-request-000019`, expected revision **19**, and command
`e01-invalid-distance-decision-request-000019`. That well-formed complete
geometric candidate was the next required recorded-invalid branch. The client
timed out under the packet's **30-second total HTTP deadline**, 30-second read
cap and three-second connect cap. No response body, accepted/committed flags,
fresh retry request or authoritative post-outcome history reconciliation for that
command was received. **Its client-visible completion and commit outcome remain
UNKNOWN.** It is not a successful rejection, accepted action, rollback or safe
new-ID retry.

The primary host log records a command POST422 at **23:28:00Z** (19:28:00 local)
and later `ConnectionAbortedError: [WinError 10053]` while writing a response.
Those server log observations do not restore the missing response body or
prove its commit flags. In particular, a server HTTP422 log cannot distinguish
the uncommitted and recorded-invalid branches required by this packet.

Reported completed-request measurements are: HTTP **130 requests**, largest
request **222,671 bytes**, largest response **2,567,701 bytes**, maximum returned
latency **28.205224299803376s**; local **121 requests**, largest request
**222,664 bytes**, largest response **4,801,158 bytes**, maximum returned latency
**46.22404729994014s**. The HTTP maximum is not a measured duration for the failed
request; the synchronous local lane is separately reported. These figures do
not establish a production SLA violation or identify a measured source
bottleneck. [Core issue #590](https://github.com/SobolGaming/Warhammer_40k_AI/issues/590)
records the external latency/unknown-outcome dependency. **RQ18's proof-budget
decision remains open**: the proposed 120-second diagnostic budget has not been
approved. This audit does not authorize increasing the budget or modifying Core.

### Cleanup, sibling preservation and capture disposition

The final harness report records primary PID **17732**, port 54057, start
23:14:03.138300Z and owned-marker exit **0** at **23:28:42.156441Z**. Restart
PID **32312**, port 52314, started 23:28:29.302266Z and owned-marker exit **0** at
**23:28:42.142393Z**. The exact selected launcher hash is
`F83F8F4CD5D55DA1B5A4A5A8E6F7CECA1666DABF400DD8C4A39B2ACE31FFAEF5`.
The attach-worker result confirms its offered action was accepted with endpoint/
session/scoped-credential ownership only. The report records the occupied-port
probe prevented launch, other-session preservation and explicit old-session loss
after restart. These are actual bounded process results; they do not reverse
the earlier direct Core co-bind failure or prove exclusive late bind ownership.

The wrapper's **`siblingsAfterFailure`**, rather than absent `siblingsAfter`,
records both siblings at their exact before HEADs with empty statuses; all four
failed-after Git children exited 0. Thus the failed Capture has actual unchanged
sibling evidence and cleanup evidence. The wrapper redaction disposition is
**SCANNED_PARTIAL**, while the subordinate report records role/private scanning
**PASS**. Neither label is silently upgraded to whole-phase privacy approval.

Read-only audit of the **27 proposed wire entries** found 27 unique safe slug/
role paths, zero raw hash mismatches and zero admin entries. Every indexed
negative/error body inspected has only the error-envelope schema and code/message
shape. Two broad text-pattern matches were the generic authentication message
`A valid bearer credential is required.`, not observed credential values.
Administrator captures remain under the ignored privileged lane; private traces
and pre-attempt inputs remain outside the proposed index. This is a bounded
storage/hash/negative-body inspection, **not final fixture promotion approval**
or a full independent hidden-information audit. The versioned `wire/index.json`
does not exist. No fixture was promoted, and none is accepted by this audit.

Native and wrapper Audit remain **NOT_RUN**, correctly gated by failed Capture.
Their test counts, real-user setting before/after preservation and actual DDC
paths therefore have no PASS. Existing pre-Native guards are merely preserved
before-snapshots. The earlier attempts, uncertain outcomes and unexecuted
intermediate candidates remain in the journal and ignored run roots; this
decision overwrites none of them.

The next bounded execution requires a recorded budget/diagnostic decision or
external resolution, a newly frozen/reviewed affected candidate and a fresh run.
Keep the uncertain old commands unchanged and do not reuse those sessions to
claim recovery. After an actual complete Capture passes, obtain concrete fixture
privacy approval, then run the positive native suite and wrapper Audit before
renewed independent acceptance. EXT08/Core #589, RISK19, terminal replay, UE HTTP,
rendering, genuine 3D, packaging, Linux, durable recovery, performance and full
variant/M01 evidence remain outstanding regardless of the eleven passed cases.
