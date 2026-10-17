# E01-SLOW120 preliminary evidence audit

Packet date: 2026-10-16. Preliminary inspection UTC: **2026-10-17T00:00:24Z**.
Auditor invocation: `/root/e01_slow120_acceptance`.
**Current status: PRELIMINARY EVIDENCE AUDIT; final acceptance BLOCKED pending
remediation, fresh execution and fresh affected reviews. This is
not an OWN15 fresh final approval.** Historical snapshots below preserve actual
checks and partial results. Native002136 exported 132 successful tests but its
phase failed, and an editor-settings after-guard found a new global file. The
separate native-only supplement has now gathered passing runtime evidence;
its historical runtime evidence remains preserved. Initial OWN15 code review
returned CHANGES_REQUESTED and requirements assessment returned BLOCKED. Fresh
blind final
code-quality and requirements reviews must make the final decision in their own
reports; this persistent preliminary invocation does not author their verdicts.

## Authority and independence

The auditor read the workspace, Unreal and Arcade AGENTS instructions, canonical
[plan Section 0](../unreal-migration-plan.md),
[packet revision 3](2026-10-16-e01-boundary-packet.md),
[source review](2026-10-16-e01-boundary-review.md),
[execution journal](../evidence/2026-10-16-e01-boundary.md), and the old
[NOT_ACCEPTED audit](2026-10-16-e01-boundary-acceptance-audit.md) and
[result](../evidence/2026-10-16-e01-boundary-result.json) read-only. OWN14 explicitly
authorizes the separately labelled 120-second diagnostic. It retains three-second
connect, 30-second managed readiness, 30-minute process, body/submission and owned
cleanup limits. This approval supplies no production responsiveness acceptance.

This invocation authored none of the implementation or fixture candidates and
did not run a harness, install, host, native build or Automation suite, edit a
sibling, or share a mutable game session. It owns only this new audit and its
optional new machine-readable summary. This is separate agent review on the
coordinator's machine, not an independently isolated external environment.

The earlier run `20261016T231112Z-f8ef82ca` remains **FAIL / NOT_ACCEPTED** and
the expired geometric command's missing completion remains **UNKNOWN**. The
auditor independently read its immutable result SHA256
`A90E132B530FB64A53031158857F59712F0677A2186C3828066AC1B09125702D` and audit
SHA256 `3071FCB50F67625E0CFCBD01BBD4C2A18376A0B545ACC28FF1DBFE022451B4AE`.
A later slow success cannot change those facts or pass the old 30-second budget.

## Frozen candidate inspected

Current implementation commit is
`eafce53e8630bbe1e1c992449c7b2c30e8f0d409`; base is
`0467ee63fe6d4c775f429afae2233d7292787c31`. Preparation froze the smaller
packet/wrapper/inventory candidate at `fd7c28f94cc0877bff33fe3cabbc94e75621c8a2`.
Packet-permitted phase freezes do not silently substitute an earlier HEAD for a
later Python or native candidate. The independent source-review invocation
`/root/e01_frozen_review_record` records source PASS for the following Python
delta at 23:58:19Z; its 40-method enumeration was source evidence, not test PASS.

| Input | Independently read raw SHA256 |
| --- | --- |
| Packet revision 3 | `D540CF96F8513833C4C708A7104F520554E8244B4502ED7A49D5F695EBE90C76` |
| Wrapper | `5250D25BDA372AF0D8D6F8B77CDA6ACD63DBD678C0A35FAF268A2C9F8B6A5FEA` |
| Python driver | `0384ABC244B1A40D55043D830AABC334FD32D0457FA7810E2D1A0901D552BC2F` |
| Python tests | `316FF378B54566B3052EAD3AA13AA660CD1ADBF542CEF0A9CDF670F03EDD6CFF` |
| Native header | `ADA9FA50D1273CB85485CDF998943BD0D0D5617C7743154C16F155BD7808A153` |
| Native reader | `217D3EF245AA610EE99FA9E87223F8A9FA844AE1C99DA996633D41D28E82DBF8` |
| Native tests | `C24760C683960CA99376454DD42E3AC657C3A37B79C1BC7B466B622B5B602665` |
| Build.cs | `61286F8F12FFC90FF02F8369392479588374A8CFF6B351518CA66386C771FEFB` |
| Source inventory manifest | `BF861B2EC555C81E85A31E4B37E756C5E6B04D343522A95F3235700C2AEC43F2` |
| Source-review record at this inspection | `886D4A05E392DAFFF0E89FAE400816BF9F629B0324625C9242BE9D91DF34948F` |

Core stays `5f509724da25a2f6ded0c2739a8e7c84bdf59c91`, Contract 44.3.33,
build `warhammer40k-core-v2:runtime-tree-sha256-v1:65fc8414407ae5d6a8ea779c8e737a22733459094db679a160c60f6e2129f96a`,
3,116 resources. Arcade stays
`5088c1c49dcaff29eb59fb64b3063d30214dde73`. The owned runtime is
`.local/core-44.3.33`; verified reuse retains tree SHA256
`B01989FC595730D8EA6F1A10C7A5004510FCA877A9B69AAD9F3285CAB357A897` and
provenance SHA256
`39C485C33E482B158EDB157A0FFAA69224C09E15DE5655277B64289887F7CF7C`.
The wrapper refuses any bytecode cache. No install or shared environment change
is credited for this verified-reuse phase.

## Actual preliminary phase evidence

Fresh ignored run root:
`.local/experiments/E01-target/20261016T235710Z-fcfefb29/`.

| Phase | Actual status and UTC interval | Result SHA256 |
| --- | --- | --- |
| Preflight | `SOURCE_INVENTORY_PASS`, 23:57:11.4351723Z–23:57:58.3032721Z | `1BE1E6A4831DDF7E8B262576243B4FA8CF371E4A0ADEADB09A761ABCD0CE0B96` |
| PrepareRuntime | `INSTALLED_RUNTIME_PASS`, verified reuse, 23:58:17.7842984Z–23:59:02.823404Z | `7D9E4E3C11718F40DE48A80EBAD2C6BA3E9F499DF9E2099B4B49F52F88988DA7` |
| Capture | Started 23:59:12.1277639Z; final result PENDING | No final result |
| Native | NOT_RUN | No result |
| Wrapper Audit | NOT_RUN | No result |

Both completed phases record 127 source members, 98 canonical case IDs, exact
runtime identity, unchanged clean sibling HEAD/status before/after, no failed or
timed-out child, and wrapper redaction PASS. These facts do not prove Capture
cleanup. The Capture unit log actually says **40 tests in 0.104s, OK**; the
final Capture child exit, artifact hash and scan chain are not yet frozen.
No scenario PASS or native count is inferred from that unit output.

## Required final evidence mapping

The final Capture report must account for all **14 discovered Python cases**:
the packet's twelve Python groups plus RUNTIME-01 and SCHEMA-01. NATIVE-01 is a
separate positive-count exported Automation suite. Failed, blocked, skipped and
unexecuted results cannot enter a passed count.

| Required row | Evidence needed before a final bounded PASS | Preliminary status |
| --- | --- | --- |
| SOURCE-01 | Exact source/installed identities, 127 inventory members, all 234 normalized contract hashes and 98 unique IDs: 73 finite, one nested, 24 parameterized | Preparation PASS; scenario pending |
| RUNTIME-01 | Approved installed interpreter/package/imports, 3,116 resources and unchanged runtime/provenance/bytecode guard | Preparation PASS; scenario pending |
| SCHEMA-01 | Positive local-registry schema/example count without network resolution | Pending |
| FINITE-01 | Offered bound-player option, original opaque IDs/revision, accepted once, matching local/HTTP outcome and refreshed views | Pending |
| MOVE-01 | Current complete ordered physical-model witness, accepted one-inch normal move and authoritative projected endpoint changes in local/HTTP comparison | Pending |
| MOVE-02 | Three uncommitted inventory negatives, actual recorded-invalid geometry branch/revision/history/fresh retry, then accepted current valid witness | Pending |
| RETRY-01 | Byte-equivalent same-envelope/scope replay applies once, changed envelope conflicts, labelled lost response reconciles same ID without display rollback | Pending |
| STALE-01 | Wrong revision, consumed request and waiting advance retain typed outcomes without silently rewriting uncertain intent | Pending |
| AUTH-01 | Explicit separate principals deny required operations without hidden request IDs/options/event-count leakage | Pending; privacy review required |
| VIEW-01 | Role-scoped local/HTTP views/events, server delay/scoped cursor and live replay denial; privileged lane separate | Pending; privacy review required |
| ERROR-01 | Actual status/code/message for 400/auth/404/409 and both live 422 shapes, plus strict malformed/type/flag negatives | Pending |
| FIDELITY-01 | Actual wire 422 status/code/message with detailed-reasons-absent notice and Core #588; no private/local reason attributed to HTTP | Pending |
| SCOPE-01 | Deterministic generation/callback/cursor/draft invalidation for viewer/session changes | Pending; UE scheduling excluded |
| LIFETIME-01 | Bounded prelaunch-port refusal, independent attach/disconnect/other-session survival, owned stop and restart SessionLost, child exits/cleanup | Pending; late co-bind excluded |
| NATIVE-01 | Frozen built reader consumes every canonical envelope and reviewed actual-wire corpus; positive exported discovered/executed/passed counts with no failures/skips/missing fixtures | NOT_RUN |
| Privacy/promotion | Separate reviewer approves concrete non-admin original-byte index/files/roles/hashes; promoted bytes match and exclude admin/raw/private captures | Pending |
| Native environment | Exact engine/compiler/SDK and commands; actual log proves owned DDC path; real-user settings before/after preserved | NOT_RUN |
| Wrapper Audit | Valid predecessor/source/runtime/fixture hashes and positive native report; child timeout/scans, cleanup and sibling preservation verified | NOT_RUN |

The source-reposition case remains synthetic/envelope-only. Terminal replay
without a reviewed public completion procedure remains explicitly NOT_RUN and
excluded from this subset; it is still required for full E01. Ninety-eight
envelopes are protocol shape coverage, not 98 live workflows.

Core #590 / EXT09 and production/30-second responsiveness remain open even if
this slow diagnostic passes. Core #589 / EXT08 late Windows co-bind exclusivity
is NOT_PROVEN. RISK19 case-colliding JSON keys remains OPEN. UE HTTP callbacks,
rendering, genuine 3D/input, packaging, Linux, durable recovery, full terminal
replay, remaining live variants, full E01/M01, G-RESEARCH and G-IMPLEMENT are not
accepted by this record. The next independent step is to inspect final frozen
Capture/privacy/promotion/Native/Audit evidence and append the actual decision.

## Progress addendum: successful Capture, pre-build Native failure

Independent follow-up inspection UTC: **2026-10-17T00:23:38Z**. The auditor again
performed read-only file/JSON/hash inspection only. Run
`20261016T235710Z-fcfefb29` has final **LOCAL_HTTP_BOUNDARY_PASS**, followed by
**Native FAIL before any build/Automation launch**. This run is not a complete
accepted phase chain. Its successful Capture and privacy-approved corpus remain
valid partial evidence; a new wrapper cannot be grafted onto that frozen run.

| Artifact under the first slow run | Independently read raw SHA256 |
| --- | --- |
| `capture/result.json` | `AB6A2EADBBE64886AAD080B22CB2CE5B1D62F632D40ADF97A075B365892BEDC3` |
| `capture/python-capture/report.json` | `33540A96EE6332F496A12CD233D7AC2F298805B50B2030A043B893F259B4AF8A` |
| Proposed and promoted `wire/index.json` | `62E6C340405CBBC30EAE8BBD4CDC321222F2DADE51B6A4304C2CE422774F03BA` |
| `wire-promotion.json` | `436F04E977D588306431F9949F0A6E8709A641C4935F673F5E19E6D4B548007B` |
| `native/result.json` | `C91BE7E9692EC7CB2DA23076E3AAB6E36926E780EED1ADAB4ED30D87B48B80B1` |

Capture ran **2026-10-16T23:59:12.1277639Z–2026-10-17T00:13:18.8612041Z**.
It records candidate `eafce53e8630bbe1e1c992449c7b2c30e8f0d409`, the original
wrapper `5250D25B...`, and the exact Python/test/packet/inventory hashes above.
All Python phase children exited 0 without process timeout. Its wrapper and
scenario redaction statuses are PASS; before/after sibling HEADs and empty
statuses agree. The scenario explicitly labels **E01-SLOW120**, request/read 120,
connect 3 and managed readiness 30 seconds. The separately executed unit log
records **40 tests in 0.104s, OK**. The scenario accounts for **14 discovered,
14 executed, 14 passed, zero failed, zero blocked and zero not-run**; the terminal
replay exclusion remains separately NOT_RUN.

| Python case | Actual first slow-run evidence |
| --- | --- |
| SOURCE-01 | PASS: exact Core, 127 source members, all 234 normalized contract hashes and 98 unique canonical envelopes. |
| RUNTIME-01 | PASS: isolated installed Core and approved dependency modules, exact build and 3,116 resources. |
| SCHEMA-01 | PASS: 93 examples validated through the local registry; network resolution false. |
| SCOPE-01 | PASS: deterministic reducer scope assertions; actual UE scheduling is not tested. |
| AUTH-01 | PASS: separate denied contexts and scoped error bodies; admin artifact stays privileged. |
| VIEW-01 | PASS: local/HTTP scoped views/events, server delay, scoped cursor and live replay denial; terminal replay excluded. |
| FINITE-01 | PASS: offered request000001 and `fixed:assassination:bring_it_down`, command `e01-finite-decision-request-000001`, revision 1→2, matching local/HTTP state. |
| RETRY-01 | PASS: byte-equivalent same-envelope/scope result at revision 2, changed envelope conflicts and labelled injected response loss; SCOPE-01 supplies display rollback protection. Response SHA256 `E1F1D42FE12D0DB6E914B3A8865C9D063BEF102F31B6055512697CD5C00F9933`. |
| STALE-01 | PASS: actual `session_revision_conflict`, consumed-request `access_denied` and `advance_not_required` results retained. |
| FIDELITY-01 | PASS: missing/duplicate/wrong inventory each returned HTTP422 `proposal_invalid`, `Submitted proposal was invalid.` with absent-detail notice and issue588. Each response SHA256 is `D7E7E71324B3758AF840FE7046F1B914C3E0EDB70D815F1054238485C06320B0`. |
| MOVE-01 | PASS: request000020, five actual authoritative model positions change +1 inch in X and match every requested initial/final pose within absolute tolerance 1e-9; remaining pose components retained. |
| MOVE-02 | PASS: three inventory errors preserve history; complete invalid geometry records one rejected attempt and revision19→20; current fresh request000020 valid witness accepted at revision21. |
| ERROR-01 | PASS: required completed real statuses and both 422 representations available; strict type/flag/malformed negatives remain separately unit/native evidence. |
| LIFETIME-01 | PASS for bounded prelaunch refusal, attach offered-action/disconnect and other-session survival, owned stop and restart SessionLost; late co-bind stays NOT_PROVEN. |

The auditor directly inspected the promoted geometry outcome's
`accepted:false, committed:true, outcome_code:proposal_invalid`, command
`e01-invalid-distance-decision-request-000019` and session revision20. Its body
SHA256 is `F41BD1EED939131AC4BDA0051A97A49F1711486E971ECAD9942C9681094EC4F5`.
The following movement outcome has
`accepted:true, committed:true, outcome_code:command_committed`, command
`e01-move-one-inch-decision-request-000020`, revision21 and body SHA256
`786AC7D69292D20BC877E6E7C052D136CE8A2F6522BD222155CC9143975C1D98`.
These are newly completed diagnostic responses. They cannot supply the old
expired request's missing receipt or change its UNKNOWN completion.

| Completed-request lane | Requests | Largest request bytes | Largest response bytes | Maximum latency seconds |
| --- | --- | --- | --- | --- |
| HTTP | 139 | 222,671 | 2,610,120 | 38.09380270028487 |
| In-process local | 129 | 222,664 | 4,889,647 | 36.57793760020286 |

The observed HTTP maximum exceeds 30 seconds. This is measured slow-diagnostic
success, not a 30-second or production responsiveness PASS, Core SLA, statistical
baseline or bottleneck attribution. Both managed processes record shutdown by
their owned markers and exit0: primary PID992 and restart PID2084. Each retains
an original process handle, start/exit timestamps, approved executable/launcher
and unique marker path. The lifetime report explicitly excludes live late co-bind
exclusivity and does not recreate the lost old session.

### Exact wire approval and promotion

The coordinator relayed actual independent invocation
`/root/e01_wire_privacy_review`'s **FINAL PRIVACY PASS**, no findings, for the
exact index above and 30 raw bodies totaling **2,003,509 bytes**. The receipt
records **2026-10-17T00:19:26.9658971Z** and
`PRIVACY_PASS_EXACT_INDEX_AND_30_RAW_BODIES`. This audit did not author that
corpus or substitute its own scanner for the separate privacy review.

The auditor independently compared every receipt source/target hash against the
approved values: **30 bodies, zero hash mismatches, 2,003,509 target bytes and
30 index cases**. The index is byte-identical to its approved hash. The promoted
31 files are versioned in commit
`6567f805c2e5b64741616c4ee8f0a04b558a88e9` beneath
`tests/migration/fixtures/5f509724da25a2f6ded0c2739a8e7c84bdf59c91/wire/`.
The receipt excludes admin, private attempts/traces and host logs. The separate
source manifest remains unchanged. Native must consume this reviewed corpus
explicitly and retain its identity, regardless of a later fresh Capture's new
session-specific original bytes.

### Native failure and reviewed repair

Native ran **00:19:38.8731543Z–00:19:55.3730677Z**, status **FAIL**. Exact failure:
`Reparse-point path is outside this proof's ownership model: C:\Users\Rabid\OneDrive\Documents`.
The absent Documents `BuildConfiguration.xml` had a cloud-reparse ancestor.
The actual process list contains only source/runtime/tool inspections and
failed-after sibling inspections: **no Build.bat or UnrealEditor-Cmd process**,
no compiled native result, no exported native case count, and no actual DDC-path
proof. The result redaction state is **SCANNED_PARTIAL**, not whole-phase PASS.
Both siblings remain clean at their selected HEADs in `siblingsAfterFailure`.
This is a settings observation guard failure, not a compiler/test failure.

The wrapper repair is independently hashed
`F3B2A938A1F314EE5FF6D39B77FADB73CB3D5E1D5E92A562957305759ACBA2DC`.
Read-only source inspection confirms `Get-UBTSettings` records an absent XML
`exists:false, sha256:null`, applies the strict reparse/hash guard to existing
files, and retains `Assert-UBTSettings`'s appeared/changed-file rejection.
General output ownership/reparse checks remain. The coordinator reports the
actual separate reviewer invocation `/root/e01_native_gate_diagnosis` returned
source PASS with matching before/after hash, PowerShell AST zero errors, three
matching isolated guards and rejection of a synthetic appeared XML. The auditor
did not execute those checks, and their source PASS supplies no native runtime
acceptance. Final record inspection must include the persisted review evidence.

The repaired wrapper invalidates the affected frozen execution chain. Fresh
complete run **`20261017T002136Z-8dad7f29`** is now required; the first slow run's
Native FAIL remains preserved. The new Preflight actually passed
**SOURCE_INVENTORY_PASS**, **00:22:32.811034Z–00:23:08.0697625Z**, candidate
`6567f805c2e5b64741616c4ee8f0a04b558a88e9` plus the repaired wrapper bytes.
Its raw result SHA256 is
`CEDC5B165EB19F81D1459B51F8194865D68D509BD2EC432B7A8E3956D8F0AD5E`.
Sibling identities/status and wrapper redaction are preserved. At this inspection
PrepareRuntime is in progress; fresh Capture, Native and Audit have no final
result. **Final bounded acceptance remains PENDING.** The old result/audit hashes
were read back unchanged again. All production/full-E01 limits stated above hold.

## Fresh-chain follow-up: Capture and new privacy gate passed

Independent read-only inspection UTC: **2026-10-17T00:40:28Z**. Fresh run
`20261017T002136Z-8dad7f29` now has its own completed preparation and Capture;
the first slow run is not used as a predecessor. **Final acceptance is still
PENDING: Native started at 00:39:46.5299848Z and has no final result; wrapper
Audit is NOT_RUN.** An active build log is not a compiled/native-suite PASS.

| Fresh-chain result | Status / UTC interval | Raw SHA256 |
| --- | --- | --- |
| Preflight | `SOURCE_INVENTORY_PASS`, 00:22:32.811034Z–00:23:08.0697625Z | `CEDC5B165EB19F81D1459B51F8194865D68D509BD2EC432B7A8E3956D8F0AD5E` |
| PrepareRuntime | `INSTALLED_RUNTIME_PASS`, verified reuse, 00:23:15.3686904Z–00:23:49.270113Z | `667CB2A61942ABE205AFC26ACD3F9DC1D96D6D1DF19C8AA48E4041CE9AA411A1` |
| Capture | `LOCAL_HTTP_BOUNDARY_PASS`, 00:23:54.514451Z–00:37:21.7596852Z | `137CEAAA5A3B85F3A49193525EEB198AEDAF28A113B7F760DA66081D5983E699` |
| Scenario report | `LOCAL_HTTP_BOUNDARY_PASS`, E01-SLOW120 | `C99109764C6708889F2DC365696D03A9FD987465DD6E5D71F108A794223530A0` |

The Capture freeze records HEAD
`6567f805c2e5b64741616c4ee8f0a04b558a88e9` plus wrapper `F3B2A938...`;
Python `0384ABC2...`, tests `316FF378...`, packet `D540CF96...` and source
manifest `BF861B2E...` remain unchanged. The auditor read the persisted repair
review addendum, record SHA256
`BCE3FF815567955A0B9FF70F5EBF369DAAD0ED47ACE38F3A2616048818030A81`.
It explicitly records `/root/e01_native_gate_diagnosis`'s actual source PASS,
unchanged wrapper hashes, zero AST errors, isolated observations and rejected
synthetic appeared XML, with `/root/e01_doc_final_review`'s distinct compilation
of that record. It does not supply a native runtime result.

Every completed phase has matching explicit predecessor hashes, zero failed or
timed-out children, wrapper redaction PASS and clean unchanged Core/Arcade
identities before/after. The same runtime/provenance hashes remain verified;
PrepareRuntime explicitly records verified reuse. The actual unit log says
**40 tests in 0.070s, OK**. Fresh scenario counts are **14 discovered, 14 executed,
14 passed, zero failed, blocked or not-run**. All fourteen IDs in the preceding
mapping independently appear once with PASS. The report retains 120-second
request/read, three-second connect and 30-second readiness values. Terminal
replay remains separately NOT_RUN, and the lifetime report retains NOT_PROVEN
late co-bind exclusivity.

| Fresh completed-request lane | Requests | Largest request bytes | Largest response bytes | Maximum latency seconds |
| --- | --- | --- | --- | --- |
| HTTP | 139 | 222,671 | 2,610,120 | 36.995944599621 |
| In-process local | 129 | 222,664 | 4,889,647 | 37.51746609993279 |

Both new owned hosts record owned-marker shutdown and exit0: primary PID30736
and restart PID5596. Primary start/ready/exit are 00:24:35.322706Z /
00:24:44.454247Z / 00:37:20.291268Z; restart start/ready/exit are
00:37:10.170679Z / 00:37:19.422962Z / 00:37:20.280967Z. Their readiness requests
received only about 24.67 and 24.47 seconds of the remaining readiness budget.
Completed requests exceeding 30 seconds again preclude a 30-second budget PASS.

The coordinator relayed the fresh actual independent
`/root/e01_wire_privacy_review` **FINAL PRIVACY PASS**, unchanged before/after
index and body hashes, no findings and the same visibility policy. This new
corpus is approved at index SHA256
`E1658B116E6ED53F84CEE84B3D8A5C1ADFD3DED3FA225DB61D80D21D9953DF0A`.
Promotion receipt SHA256
`E2211D3FF5F3F3C92873BE70EF515F92B1FFCD3A2F7A7981D1C23BDC600150F6`
records **00:39:46.1683767Z**, before Native's start, and preserves the old index
`62E6C340...` through commit `6567f805...`. The fresh approved bytes replace that
historical corpus for the new Native freeze. Independent audit comparison found
**30 source/target body hashes matching, zero mismatches, 2,003,509 bytes,
30 index cases, all kind `http`**. Roles are playerA, playerB, coach, delayed,
replay, missing and invalid; admin/private attempts/traces/host logs are excluded.

The explicit editor-config before guard was captured at **00:33:57.9421345Z**,
SHA256 `7BC9C50E5F21B3C48A7840BA24C32E2F23D52E33C0880D5637797980C7E56037`.
It includes six concrete paths: engine BaseEditorSettings and project
DefaultEditorSettings exist with hashes; actual LocalAppData, physical Documents
and known OneDrive Documents user/editor settings are absent. This is a
before-snapshot, not yet a post-Native preservation result. The actual native
cache path, positive exported test count and complete after-guard/Audit chain
remain to be inspected. The old 30-second result/audit hashes were read back
unchanged again. No broader acceptance is implied by this follow-up.

## OWN15 qualification and Native002136 final failure

Follow-up inspection UTC: **2026-10-17T00:53:50Z**. This record is explicitly a
**PRELIMINARY EVIDENCE AUDIT**, retaining all performed historical inspections.
OWN15 is now recorded in AGENTS and canonical plan Section0.2. It requires two
different fresh, initially unprimed code-quality and requirements reviewers,
enforced read-only permissions, approval policy `never`, requested
`memories.use_memories=false`, exact frozen inputs and raw evidence, and honest
attestation of runtime versus requested properties. Prior reviewer conclusions
are excluded from each initial review packet.

This invocation's initial assignment expressly included prior source-review and
acceptance records, and it read their conclusions. It has remained the same
persistent subagent context for these follow-ups. Its tools permit workspace
writes with automatic approval review; it did not attest an enforced read-only,
approval-never or fresh no-memory execution. Its separate authorship and actual
read-only experiment inspection are useful diagnostics, but **do not satisfy
OWN15's renewed blind final gate**. No historical result is erased or relabelled
as if that protocol had run. Later fresh CLI review reports must record their
own invocation/isolation evidence and verdict; this document supplies neither
their approval nor a substitute final result JSON.

Run **`20261017T002136Z-8dad7f29` Native: FAIL**, from
**00:39:46.5299848Z to 00:41:16.5244736Z**. Actual native-build child exited0
at **00:40:37.8464158Z**; actual native-automation child exited0 at
**00:41:16.1538206Z**, neither timed out. Its exported Automation index contains
**132 matching Warhammer.Migration.E01Boundary tests, all state Success**:
succeeded132, succeededWithWarnings0, failed0, notRun0, inProcess0. Exported
test duration is 1.4224151372909546 seconds. This is positive native execution
evidence even though the complete phase failed.

| Actual completed artifact | Independently read raw SHA256 |
| --- | --- |
| `native/result.json` | `CD9DE29ECB41A68E9482B6E4AB1BA951C2413BEAB9C79C65496776D29379405A` |
| `automation/index.json` | `02CA7BA7C007DB578BEFB08D88B865CB5EA6F3260EEC5D709D16AB642BBA3188` |
| `native-config-after.json` | `6DF637A2346F81FC820EE2061F15F696B4121E17B8657BE1FC157607023B21D5` |
| `native-generated-config-recovery.json` | `DA477EF231F989C272BC30FD86C6F32F1CD22C1C763AC98C9D07E0853A831312` |

The exact phase failure is the absent required main log
`.local/experiments/E01-target/20261017T002136Z-8dad7f29/native-automation.log`.
The requested `-LOG=<absolute>` did not produce that expected file. Consequently
this run has **no accepted actual Local DDC main-log proof**, regardless of its
successful exported cases. The wrapper result remains FAIL, with redaction
`SCANNED_PARTIAL`; its failed-after sibling inspection shows both clean exact
HEADs. Wrapper Audit did not run for that failed predecessor.

The supplemental after guard at **00:42:43.5327253Z** reports **CHANGED**, one
changed path: previously absent
`C:/Users/Rabid/AppData/Local/UnrealEngine/5.8/Saved/Config/WindowsEditor/EditorSettings.ini`
now exists at SHA256
`B7E47645C8169E0C05AB6AD43F99F4529D33CD12EF019432FA56BD9F994B464E`.
The other five editor-config observations match their before values. The new
global file is preserved; its appearance is not settings-preservation PASS and
is not hidden by resetting the baseline retroactively.

Editor startup also generated project Config changes. The recovery receipt at
**00:45:45.9334027Z** records private preservation of the generated
DefaultEngine.ini and DefaultInput.ini bytes beneath the failed run, restoration
of the tracked authored DefaultEngine.ini, and DefaultInput.ini restored to its
prior absence. The receipt explicitly retains Native FAIL and preserves the
global EditorSettings file. **This auditor read only the recovery receipt; it
did not read or print either private generated Config body.** Those bodies remain
excluded from public evidence/commits. Recovery does not convert the settings
side effect or failed phase into PASS.

### Native-only supplement pending; final reviews remain separate

Reviewed packet revision4 SHA256 is
`40CE909D2B4A36638BDC922D9093DF8650747B9F0A2DEEBE09846A86C6205249`;
current wrapper SHA256 is
`095EBF4359665E05AFCFD864EB33E2D6FA9CB7FD9CFD19BE5AFCC78DB92AAB52`.
The frozen source HEAD is `8955112131c8be4c26499325bddbe1d24eaf0260`.
The packet permits a fresh Native/Audit supplement explicitly linked through
`-CaptureRunId 20261017T002136Z-8dad7f29` to its immutable successful Capture,
report and approved E1658B11... corpus. It launches no new Core host or game
commands and creates no replacement Capture result. It requires `-ABSLOG`,
`-nowrite`, exactly132 exported successes, actual owned DDC log evidence,
unchanged global/UBT settings and an unchanged exact Config file set/hash guard.
These are requirements, not executed success claims.

Supplement run **`20261017T004553Z-ba9995c1`** Preflight actually passed
**SOURCE_INVENTORY_PASS**, **00:51:04.9690687Z–00:51:50.7766857Z**; result
SHA256 `D897D11FF314A2F3EAB741D017CC6928DC6F49177C15155B26495CA030AE1D0B`.
It records the exact new packet/wrapper/HEAD, unchanged source manifest, zero
failed/timed-out children, redaction PASS and clean unchanged siblings. Runtime
preparation was active at assignment; its final result and all supplement
Native/Audit outcomes are not audited in this snapshot. Fresh CLI review
orchestration `/root/e01_fresh_cli_reviews` is pending. Final diagnostic-subset
acceptance remains pending both actual phase evidence and OWN15 reports; no
final verdict is supplied here. The old30-second FAIL/UNKNOWN and immutable
result/audit hashes were read back unchanged once more. Full E01, 30-second or
production performance, UE HTTP, render/package and Linux claims remain excluded.

## Factual execution summary gathered; OWN15 final review pending

The new [machine-readable execution summary](../evidence/2026-10-16-e01-slow120-result.json)
records **`EVIDENCE_GATHERED_PENDING_FRESH_REVIEW`**. It is a factual summary,
**not a fresh independent acceptance verdict**. This helper inspected final raw
records and wrote only its two assigned diagnostic outputs. It did not execute
the proof, reopen an old session, read private generated Config bodies, or change
either old30-second evidence file. Their hashes remain A90E132B... / 3071FCB5....

Native-only supplement **`20261017T004553Z-ba9995c1`** completed its actual chain:

| Phase | Actual status and UTC interval | Raw result SHA256 |
| --- | --- | --- |
| Preflight | `SOURCE_INVENTORY_PASS`, 00:51:04.9690687Z–00:51:50.7766857Z | `D897D11FF314A2F3EAB741D017CC6928DC6F49177C15155B26495CA030AE1D0B` |
| PrepareRuntime | `INSTALLED_RUNTIME_PASS`, verified reuse, 00:52:23.0704271Z–00:53:07.4333937Z | `0A20A841F9F521AA745C98F011936124617472654A5449A0A0960AF7AADE39E3` |
| Native | `NATIVE_FIXTURE_PASS`, 00:53:50.6268575Z–00:54:33.8365994Z | `58DCDADA2AACED2F72D4026CAB9A382EDCC8C1A513CB09C8F69BDDE9DD287ED2` |
| Wrapper Audit | `EVIDENCE_GATHERED_REQUIRES_INDEPENDENT_AUDIT`, 00:54:59.7350796Z–00:55:57.9179713Z | `8D5A0D821B73814043AB16188BD9B72612D1855850AB45157B8CBC14F5FE569D` |

The Native result explicitly links unchanged Capture002136/result137CEAAA...,
reportC9910976... and reviewed indexE1658B11... under packet revision4. It creates
no replacement Capture and launches no Core host/game command. Every completed
supplement phase records clean unchanged sibling identities, no failed or timed
out child, and redaction PASS. Runtime/provenance remain B01989FC... / 39C485C3....

Actual build PID18364 exited0, **00:54:10.6629556Z–00:54:13.8074437Z**; actual
Automation PID35872 exited0, **00:54:13.8206892Z–00:54:32.9671342Z**. Export
SHA256 `A469EA4CD41CD6E6C30873ED9871A391FD69B98BAEF77DC6F328F7AFD93B7A24`
contains **132 unique matching Success cases**: 98 canonical envelopes, 30 real
wire cases and four inventory/preservation/negative/coverage cases; zero warnings,
failed, not-run or in-process cases. Exported test duration is
1.6587226390838623 seconds. NullRHI remains protocol-only evidence.

Main log SHA256
`0978A501B950AC8361D7F5C0B19234A00C2E271475264B3F99F8EE4D65CCDE1D`
actually records the installed engine pak opened for reading (line941), the
packet-local LocalDataCachePath override (line942), and that owned cache writable
(line945). Its DDC records show no fallback; the command includes the explicit
inline graph and `-DDC-NoDefaultGraph`. Line2920 records 132 tests performed.
Actual `-ABSLOG` and `-nowrite` appear in the command/log.

The six editor-config before/after receipt hashes are respectively
`BB2DCFF50FD0984C0392096B7B6AEDE983D8087B10C93BD0534E27ADE710EDC5`
and `49A7308221D8C095D0DC5063029FA27270E637F2404A8EB52EB3F3B9A42BFABB`.
Their result is **UNCHANGED**, six observations and no changed path. The historic
global EditorSettings B7E47645... remains preserved. Native/Audit also retain
the unchanged three-file authored Config exact set/hashes and before/after UBT
settings; no private generated Config body was consulted for this record.

Python evidence-audit PID29300 exited0. Its report SHA256 is
`E668E4F2969CF7E8472BD1712032EC30BB3E72FC26A6133E4DACB388233D8F2C`,
status `EVIDENCE_AUDIT_PASS`, **two discovered/executed/passed, zero failed,
blocked or not-run**. The report explicitly says independent review is required
separately. It cannot convert the historical Native failures or this preliminary
helper audit into OWN15 approval. The new factual JSON parses, its count/status
assertions and referenced relative artifact hashes match, and whitespace checks
pass. Fresh code-quality and requirements CLI reports remain **PENDING** at this
snapshot; their own reports govern later acceptance/publication. No final
diagnostic-subset, full E01, 30-second performance or broader claim is made here.

## Initial OWN15 reports received; remediation and fresh run pending

This persistent helper remains the **factual recorder/preliminary auditor**, not
either final reviewer. Both initial OWN15 CLI reports are complete for executable
HEAD **`8955112131c8be4c26499325bddbe1d24eaf0260`**, base
**`0467ee63fe6d4c775f429afae2233d7292787c31`**. Their outcomes are recorded as
actual reviewer reports; this helper neither substitutes a verdict nor claims
that an inspected runtime success resolves their findings.

Before updating either factual record, the helper preserved its current bytes
without overwrite beneath
`.local/reviews/E01-SLOW120-final/pre-remediation-records/`:

| Immutable pre-remediation source | Snapshot raw SHA256 |
| --- | --- |
| `2026-10-16-e01-slow120-result.json` | `648AF28B6C1AA88AA5CE265E7B5A86DEDEB5686D113F3BAC5D02D4A542F9E1F2` |
| `2026-10-16-e01-slow120-acceptance-audit.md` | `476F057248E556B7B776BB17EED998602CC7C182ACB0D46DAB4903EB5D58B3A7` |

Each snapshot filename embeds that full hash. New provenance record
`provenance-20261017T0109494764325Z.json`, SHA256
`22E4DA4F8E1E049AE569015F65317A6FA354020C4D0E23A5F5E8F89C0F0673CB`,
records the exact source/snapshot paths, hashes and byte lengths. Snapshot bytes
were read back and matched before status edits. Neither snapshot nor an existing
provenance file was overwritten.

| Initial OWN15 report | Actual disposition | Raw report SHA256 |
| --- | --- | --- |
| `.local/reviews/E01-SLOW120-final/code-20261017T005624Z-511f61f4/last-message.txt` | **CHANGES_REQUESTED** | `9C8587B1877A21E14FA1FA33DA2C2663F06B63C2A5AFCBEB08B3A5ED97F5D9E3` |
| `.local/reviews/E01-SLOW120-final/audit-20261017T010141Z-a7a5a8f5/last-message.txt` | **BLOCKED** | `CEE6907DA5A5AE30D1BADDE62144912B52BA4CE11503C12213487CE2EA18CC0A` |

The code input manifest is
`817D40F480413FFCCC64A6F4812C96E019F07FD520D43B16E638EDA6A26282A1`,
with normative criteria
`C22CB84DA41490C0B2F10022487CEAA311A60866D027DBDB3E22718F39F2E1E3`.
The requirements input manifest is
`F97DB1D05523AEF394F2F382F245F4BE14CF885D3ABFFD6EA23E4345721D4348`;
it explicitly binds the original factual JSON `648AF28B...`, now preserved above.
Both report hashes were independently read back for this update. Their reports
state runtime read-only/approval-never observations and preserve independently
attested memory/model limits as UNVERIFIED; this helper does not strengthen those
attestations.

The initial code reviewer requests two source repairs:

- **P1:** a timed-out mutation can be followed by dependent submissions on the
  same uncertain session. The finite submission also lacks the complete
  pre-submission envelope/scope snapshot used by movement. Persist the uncertain
  envelope, explicitly retain UNKNOWN, and stop dependent mutation until
  same-envelope reconciliation or session abandonment. Add multi-group timeout
  coverage. The report references frozen `e01_boundary.py` lines853,1119,1167.
- **P2:** `getresponse()` can process gradual status/headers through multiple
  socket reads after the timeout was set once; it can exceed the total request
  or readiness deadline. Enforce the remaining deadline throughout header
  processing and test short-budget slow headers, including UNKNOWN after a
  possibly submitted mutation. The report references frozen line362.

The initial requirements assessment records two blockers:

- The selected review extracts omit original wrapper process ledgers and Capture
  owned-host `.processes` records. The compiled factual summary is not a
  substitute for provenance-bound sanitized raw selections with executable/script
  identity, complete credential-free arguments, PID/start/exit/timeout and
  readiness/shutdown fields. The supplement's complete inventory is also needed.
  **This evidence gap alone does not require rerunning runtime checks.**
- The frozen mixed migration-plan line endings caused `git diff --check` to fail
  at lines7,235,403,507,558 due to terminal CR characters. Normalize, recheck and
  bind the new documentation hash. This correction alone does not invalidate
  the inspected runtime outcomes.

The factual JSON now records **`REMEDIATION_AND_FRESH_RUN_PENDING`**, the exact
initial reports/findings and snapshots, and blocked final acceptance/publication.
The source fixes require a newly frozen candidate, fresh complete execution and
fresh affected reviews; the evidence-extract and line-ending gaps must also be
closed transparently. This helper made no source edit and ran no new proof,
host/build/Automation or GitHub action. Historical 40-unit/14-case Capture,
132-case Native, owned DDC/settings and 2-case automated-audit successes remain
recorded for their exact old candidates. Both old Native FAILs, configuration
side-effect/recovery history and original30-second FAIL/UNKNOWN remain unchanged.
No remediated source result, new run result, renewed final approval or publication
acceptance is asserted by this update.
