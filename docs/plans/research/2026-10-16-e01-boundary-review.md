# E01 frozen candidate source review

Date: 2026-10-16. Reviewer invocation: `/root/e01_frozen_review_record`.
Current disposition: **revision 3 / E01-SLOW120 frozen candidate source PASS,
including the 120-second Python delta below.** F01/F02
were repaired in the earlier reviewed candidate. Earlier PASS dispositions below
apply only to their frozen hashes. Execution and independent acceptance remain
separate. This is a separate
source review, not execution evidence or milestone acceptance.

The coordinator delegated read-only review of the E01 wrapper, Python driver and
tests, native reader and tests, and frozen fixture inventory against the
[execution packet](2026-10-16-e01-boundary-packet.md), repository AGENTS and
[canonical plan](../unreal-migration-plan.md). This reviewer authored none of
those candidates. The sole permitted edit is this review record. No harness,
host, install, build, automation suite or sibling mutation was invoked here.

The review base is merged PR1 commit
`0467ee63fe6d4c775f429afae2233d7292787c31`; reviewed HEAD was
`da1bbdaba93a5787e9a46a2736aefbbeb574e6e2` before and after inspection.
Documentation changes were present outside the frozen executable candidate.
The active Capture run `20261016T230019Z-9a9e3232` is not a result established by
this review. Native and Audit had not run at assignment. Final execution and
acceptance require their own records.

## Findings and disposition

1. **F01 / P2 — Python rejects a supported uncommitted command outcome. OPEN.**
   In `scripts/migration/e01_boundary.py:255`, `classify` requires every command
   outcome to have `committed:true`. Exact selected Core
   `Warhammer_40k_AI@5f509724da25a2f6ded0c2739a8e7c84bdf59c91:docs/ADAPTER_DECISION_CONTRACT.md:5033`
   explicitly permits facade pre-validator failures returned as command results
   with `accepted:false, committed:false`, without a revision increment. The
   frozen `contracts/schemas/session-command-outcome.schema.json` likewise leaves
   `committed` unconstrained for its rejected outcome alternatives. The native
   reader already distinguishes this valid uncommitted branch. Current Python
   tests reject a false/false mutation under HTTP 200, but do not check a valid
   HTTP 422 command outcome. Repair the Python classifier and focused tests to
   preserve this third valid representation, and keep error-envelope rejection,
   recorded rejection and actual observed wire fidelity distinct. Freeze/review
   the repaired candidate and run its affected Capture in a fresh RunId. Do not
   edit the active run's source or infer that the current Core returned this
   shape merely because its contract permits it.

2. **F02 / P2 — Runtime fingerprint excludes loadable bytecode. OPEN.**
   `scripts/migration/Invoke-E01BoundaryProof.ps1:467` excludes every `.pyc` from
   the installed runtime tree fingerprint. `-I -B` suppresses bytecode writes;
   it does not suppress loading an existing valid bytecode cache. This was
   verified from the installed Python 3.14.5 primary implementation,
   `Lib/importlib/_bootstrap_external.py:840–895`: cache reading and
   `_compile_bytecode` precede the `sys.dont_write_bytecode` write condition.
   A read-only recursive inventory found **zero `.pyc` files** in the owned
   `.local/core-44.3.33` environment during this review. No actual bytecode drift
   or compromised execution is alleged. Nevertheless, the reusable-runtime
   unchanged-identity guard would miss introduced/changed executable caches.
   Refuse bytecode caches or include them in a verified immutable fingerprint;
   obtain separate delta review and a fresh affected run. Preserve the existing
   installed environment and failed-run evidence.

   The coordinator proposes failing `Get-RuntimeTree` on **any** `.pyc` instead
   of omitting those files. This is sufficient minimal hardening for this bounded
   zero-bytecode runtime: it refuses drift without changing the environment or
   its original provenance. This is a proposed repair, not inspected patched
   source or a claim of protection against concurrent hostile writes. The
   provenance file's intentional exclusion remains separately hash-bound by the
   phase records.

The coordinator acknowledged both findings and will keep the active frozen run
unchanged until it ends, then repair/review and rerun the affected phases. Neither
finding is waived by a prior source review or a successful subset of tests.

## Other source checks and retained limits

- Wrapper output containment, reparse/alias/traversal checks, fresh phase
  directories, extraction bounds and collision refusal are present. Process
  launches use argument arrays and owned handles; fallback termination is limited
  to the owned process/tree and preserves failed artifacts. No broad port-owner
  or process-name kill, shared environment replacement, or sibling output path
  was found. Child environments use the wrapper's allowlist and isolated
  package/cache paths; credential-shaped output fails scanning before export.
- Python imports the selected installed public adapter server, build identity
  and development credential constants. No private lifecycle, controller or
  queue access was found. Decisions preserve current offered IDs; outgoing
  paired commands pass the frozen local schema validator before transport.
  The reviewed translation order is explicitly a fixed fixture recipe, and Core
  alone accepts or rejects it. Model-motion evidence compares actual requested
  endpoint poses and requires a nonzero XYZ change.
- Proposed captures retain original reply bytes. Administrator bodies are
  directed to ignored privileged output, omitted from the proposed public wire
  index, and actor-specific rejected inputs remain in an ignored role-scoped
  diagnostic. Generic traces retain request/response hashes rather than hidden
  command contents. This source policy is **not final fixture privacy approval**;
  inspect the actual final index, files, roles and hashes before promotion.
- The native reader rejects malformed JSON, duplicate decoded keys, missing or
  incorrectly typed required framing, case-changed protocol discriminators,
  invalid accepted/committed flags, and revisions outside its exact integer
  range. It preserves array order, explicit nulls, opaque string case and numeric
  lexemes. Valid JSON keys differing only by case fail explicitly with
  `unsupported_key_case_collision`; **RISK19 stays OPEN**. This is neither an
  arbitrary-JSON compatibility approval nor a full JSON Schema validator.
- The native source suite defines four simple tests, 98 canonical envelope
  cases and a nonempty variable wire lane. Missing wire fixtures create a failing
  configuration case. Wrapper Native requires a positive exported matching test
  count and successful case states. These are source expectations; this reviewer
  ran none of the tests. No execution count is inferred from them.
- Windows prelaunch port checks set `SO_EXCLUSIVEADDRUSE` before probing and
  readiness also requires the owned child's exact post-bind log marker. The
  probe is released before Core starts; it cannot prevent a later co-bind to the
  unchanged development host. **Core issue
  [#589](https://github.com/SobolGaming/Warhammer_40k_AI/issues/589) / EXT08 stays
  OPEN**. Robust managed-host exclusivity and real remote security are unproven.
  The supervisor/attach proof uses the selected development credentials and is
  not production credential provisioning or capability isolation.
- Native `-UserDir` and command-line DDC overrides do not alone prove isolation
  from global Editor settings. Before Native, preserve/check relevant settings;
  require actual logs to identify the owned Local DDC path and record any global
  side effects. No editor configuration was changed by this review.
- Full E01, terminal replay, UE HTTP callbacks/scheduling, rendered input,
  packaged loading, Linux, durable recovery and broad implementation acceptance
  remain outside this source-review result. Core issue
  [#588](https://github.com/SobolGaming/Warhammer_40k_AI/issues/588) and the exact
  HTTP diagnostic fidelity gap remain visible.

## Frozen byte identities and read-only checks

The following **raw SHA256 values were identical before and after** inspection
(post-check UTC `2026-10-16T23:08:02Z`). Paths are relative to this repository.

| Path | Before = after raw SHA256 |
| --- | --- |
| `scripts/migration/Invoke-E01BoundaryProof.ps1` | `D0316138D8B4736D277B43FDFFDCBC7CBD98C7232020A92813FE34B0DF14AF01` |
| `scripts/migration/e01_boundary.py` | `DE7493759C234C84C93B0B4E3028A47F483E1F70C51BD45187A8B55F880EC74E` |
| `tests/migration/test_e01_boundary.py` | `C1C08D53B09AF7A9C5FE24D981635CC69B3303792E880B5C5BF77153994B0D99` |
| `Source/WarhammerClient/Private/Migration/CoreBoundaryEvidence.h` | `ADA9FA50D1273CB85485CDF998943BD0D0D5617C7743154C16F155BD7808A153` |
| `Source/WarhammerClient/Private/Migration/CoreBoundaryEvidence.cpp` | `217D3EF245AA610EE99FA9E87223F8A9FA844AE1C99DA996633D41D28E82DBF8` |
| `Source/WarhammerClient/Private/Tests/CoreBoundaryEvidenceTests.cpp` | `C24760C683960CA99376454DD42E3AC657C3A37B79C1BC7B466B622B5B602665` |
| `Source/WarhammerClient/WarhammerClient.Build.cs` | `61286F8F12FFC90FF02F8369392479588374A8CFF6B351518CA66386C771FEFB` |
| `tests/migration/fixtures/5f509724da25a2f6ded0c2739a8e7c84bdf59c91/manifest.json` | `BF861B2EC555C81E85A31E4B37E756C5E6B04D343522A95F3235700C2AEC43F2` |

The read packet SHA256 was
`B263A3AE8567FBDE8E6CAB0F2A7C3024F1F0D4E7516DEAA875DAECB6681775C0`.
The fixture-scoped `.gitattributes` is `* -text`, raw SHA256
`92ABBB699C5A9A72C82B893D5EBEDC3F643BAA601E28144DD2E7595374D82262`.
Neither was edited here.

Read-only PowerShell JSON/file-hash inspection found 127 source inventory rows,
122 copied contract files with **zero raw hash mismatches**, and 98 unique
canonical case IDs (73 finite, one nested, 24 parameterized).
`RuntimeCasesExecuted:0` in that original source manifest remains source-only.
`git diff --name-only HEAD -- scripts/migration Source tests/migration` was empty
at inspection. These checks inspect source data; they do not run Core workflows
or confer final capture provenance.

Closure requires a reviewed repair of F01/F02, frozen final execution artifacts,
actual fixture privacy review, nonempty Native results and a separate acceptance
audit against the packet. This review must be updated for changed candidates;
the identities above cannot silently stand for a later source revision.

## Delta review: bytecode guard and packet revision 2

Invocation: `/root/e01_frozen_review_record`, separate follow-up source review,
2026-10-16; post-check UTC `2026-10-16T23:10:26Z`. Base and HEAD remained
`0467ee63fe6d4c775f429afae2233d7292787c31` and
`da1bbdaba93a5787e9a46a2736aefbbeb574e6e2`, respectively; this delta was dirty
source identified by its raw hashes. Before/after hashes matched:

| Delta path | Before = after raw SHA256 |
| --- | --- |
| `scripts/migration/Invoke-E01BoundaryProof.ps1` | `5250D25BDA372AF0D8D6F8B77CDA6ACD63DBD678C0A35FAF268A2C9F8B6A5FEA` |
| `docs/plans/research/2026-10-16-e01-boundary-packet.md` | `DA568F9BFAE7666C1CECB549B2A05B7930F5341541E25FDB96A6F08CF27B7C1F` |

**Wrapper/packet source disposition: PASS for fresh Preflight and
PrepareRuntime; F02 CLOSED_SOURCE.** The sole wrapper change replaces the `.pyc`
exclusion with an immediate typed failure on any file with that extension,
before fingerprint construction. PowerShell's comparison is case-insensitive.
The existing no-reparse traversal and ordinary file hashing remain intact;
there is no deletion, environment replacement or provenance rewrite. An existing
runtime containing executable bytecode is now refused rather than accepted with
an unchanged fingerprint. Actual execution of this repaired guard remains to be
recorded in the next fresh run.

Packet revision 2 preserves the original packet hash and failed-run history,
explicitly scopes classifier/schema-routing and bytecode repairs, and changes
the socket-read cap to 30 seconds while retaining the 30-second total request
deadline, three-second connect cap and existing body/submission limits. It
forbids retrying the uncertain request in the old session. These amendments
stay within the bounded protocol/runtime proof and confer no broader migration
acceptance.

For the packet's historical statement only, this reviewer read the preserved
`20261016T230019Z-9a9e3232/capture/result.json` and harness report: wrapper FAIL,
34 Python unit tests PASS, movement/fidelity cases FAIL with `timed out`. The
owned host log contains later HTTP 200 lines and a disconnected-client
`ConnectionAbortedError`. Those observations do not prove the timed-out action's
client-visible completion. No process or suite was executed by this reviewer.

**F01 stays OPEN.** Python repair was still being authored and is excluded from
this delta approval. Capture needs its separately frozen/reviewed Python
candidate; this wrapper/packet review cannot substitute for it. The original
source review, privacy requirement, Core #589 / EXT08, RISK19 and remaining
Native/acceptance obligations above continue to apply.

## Delta review: classifier, request budget and private attempt evidence

Invocation: `/root/e01_frozen_review_record`, independent follow-up source review,
2026-10-16; post-check UTC `2026-10-16T23:12:19Z`. The base remains
`0467ee63fe6d4c775f429afae2233d7292787c31`; reviewed HEAD is now
`9f7e171d0e36e02f4e4b1d48037ae820c952d02a` plus the two dirty Python candidates.
Before/after raw hashes matched:

| Delta path | Before = after raw SHA256 |
| --- | --- |
| `scripts/migration/e01_boundary.py` | `469C07B909EBAF315073D1426941D1AADD50DECD65A76706E0CA952408BBF0C1` |
| `tests/migration/test_e01_boundary.py` | `F5528357299473C628AFE1DD504BAAA62858A82329001648E22FB894160D0052` |

The wrapper remains `5250D25BDA372AF0D8D6F8B77CDA6ACD63DBD678C0A35FAF268A2C9F8B6A5FEA`;
packet revision 2 remains
`DA568F9BFAE7666C1CECB549B2A05B7930F5341541E25FDB96A6F08CF27B7C1F`.
The initial native/Build.cs/source-manifest identities above remain the reviewed
native and inventory set, without expansion of their acceptance scope.

**Python delta source disposition: PASS; F01 CLOSED_SOURCE.** The classifier now
accepts HTTP 422 rejected command outcomes with supported codes and both boolean
flags false, preserving `uncommitted_invalid` distinctly from `recorded_invalid`.
It still rejects `accepted:true, committed:false`, wrong flag types and rejected
outcomes under HTTP 200. `Captures.add` chooses the error-envelope schema from the
actual `error` member and the command-outcome schema for all command outcome
branches, including uncommitted outcomes. It preserves original response bytes
and administrator segregation. Focused source tests cover both supported
uncommitted negative codes and schema routing; their mocked/temp-file checks
are explicitly labelled synthetic and do not fabricate live HTTP evidence.

The request-budget delta retains the three-second connect timeout, checks the
remaining 30-second total budget after connect and before response headers, and
caps each subsequent socket-read timeout by that remaining budget and the new
30-second read cap. A final elapsed check and response-size/truncation checks
remain. Its focused source regression checks decreasing remaining-time values
using the real standard-library HTTP response parser and a deterministic clock.
This is approval of the bounded owned-loopback proof; it does not claim a
production transport security/availability budget or actual successful timing.

Before setup and movement submissions, the driver now freezes a private input
snapshot beneath ignored `private-attempts/command_<ordinal>/<role>.json`.
`authorized_candidate_snapshot` first requires the authenticated role to match
the offered actor, the view's viewer to match that actor, and visible/current
request and command request IDs to agree. New-file writes and secret scanning
precede export. The ordinal is derived from the next submission, not supplied
path data. No snapshot is added to the proposed wire index. Snapshots explicitly
assert no completion outcome; after timeout they preserve the attempted input
without promoting an uncertain action to accepted. The source regression checks
that the authorized snapshot survives a synthetic timeout, a wrong role fails
before a file is written, and no wire result is invented.

Read-only source enumeration found **38 Python test methods**. This reviewer ran
none; no 38-test PASS or current Capture result is asserted. Fresh Preflight
started at approximately `23:11:12Z` was in progress at assignment and was not audited here.
The coordinator still needs actual phase results and final fixture privacy
review before Native. **Combined bounded candidate source disposition: PASS**
for the frozen identities in this section and the prior unchanged native set.
F02 stays CLOSED_SOURCE; all earlier findings and their repairs remain in this
record rather than being overwritten as if the first candidate had passed.
Core #589 / EXT08, RISK19, DDC verification and independent acceptance remain open
as specified above.

## OWN14 / revision 3: slow diagnostic preparation source review

Invocation: `/root/e01_frozen_review_record`, independent follow-up on
2026-10-16; post-check UTC `2026-10-16T23:56:21Z`. Reviewed HEAD is
`875e2711cd89f6f04237afb7b6b206aa0fcafdb8`; the base remains
`0467ee63fe6d4c775f429afae2233d7292787c31`. The packet delta is identified by
raw bytes rather than the branch name. Before/after SHA256 matched:

| Reviewed path | Before = after raw SHA256 |
| --- | --- |
| `scripts/migration/Invoke-E01BoundaryProof.ps1` (unchanged) | `5250D25BDA372AF0D8D6F8B77CDA6ACD63DBD678C0A35FAF268A2C9F8B6A5FEA` |
| `docs/plans/research/2026-10-16-e01-boundary-packet.md` (revision 3) | `D540CF96F8513833C4C708A7104F520554E8244B4502ED7A49D5F695EBE90C76` |

**Disposition: source PASS for fresh Preflight and PrepareRuntime under OWN14.**
The owner explicitly authorized the increased 120-second diagnostic. Revision 3
restricts that amendment to a separately labelled **E01-SLOW120** public-protocol
run, requires a fresh RunId and frozen source review, and retains exact source
and runtime identity, verified runtime reuse, three-second connect timeout,
30-second managed-host readiness, 30-minute process bounds, body/submission caps,
credential isolation and owned cleanup. It permits no Core edit, private rules
path, new host, uncertain-session reuse or automatic new-command retry.

The new budget cannot retrospectively pass the earlier 30-second budget.
Revision 2's packet hash and the failed run
`20261016T231112Z-f8ef82ca`, missing receipt/UNKNOWN outcome and NOT_ACCEPTED audit
remain explicit. Read-only file hashes observed for the earlier result and audit
are `A90E132B530FB64A53031158857F59712F0677A2186C3828066AC1B09125702D`
and `3071FCB50F67625E0CFCBD01BBD4C2A18376A0B545ACC28FF1DBFE022451B4AE`,
respectively. This reviewer did not modify either. The audit's actual disposition
is NOT_ACCEPTED; no old test result or unknown receipt is promoted by this review.

The packet explicitly adds two separate permitted documentation outputs,
`docs/plans/evidence/2026-10-16-e01-slow120-result.json` and
`docs/plans/research/2026-10-16-e01-slow120-acceptance-audit.md`. It retains
independent privacy approval of actual non-admin original-byte fixtures before
promotion and Native, positive native counts, frozen inputs, actual owned cache
path and settings-preservation requirements. A slow diagnostic success cannot
close Core #590's latency concern, RISK19, robust Windows exclusivity, UE HTTP,
rendering, packaging, Linux or full migration acceptance.

The wrapper is byte-identical to its prior approved source, including its
`.pyc` refusal. Its preparation phases do not execute the not-yet-reviewed
Python diagnostic change. **Python 120-second budget/readiness implementation
is excluded from this approval**; its separate frozen review is required before
Capture. No Preflight, install/reuse, host, test or native phase was executed by
this reviewer. Final diagnostic outcomes and a renewed independent acceptance
audit remain pending.

## OWN14: frozen 120-second Python candidate review

Actual reviewing invocation: `/root/e01_frozen_review_record`, focused independent
source inspection on 2026-10-16; post-check UTC `2026-10-16T23:58:19Z`. The
coordinator separately confirmed that `/root/e01_python_review` was invoked for
this same candidate and returned source PASS with no actionable findings,
unchanged before/after hashes and no execution. That reported review is distinct
from this invocation's direct inspection; neither invocation establishes an
independent machine or isolated runtime environment.

Reviewed base remains `0467ee63fe6d4c775f429afae2233d7292787c31`; current HEAD is
`fd7c28f94cc0877bff33fe3cabbc94e75621c8a2` plus dirty Python candidate bytes.
This review directly checked the complete Python delta from the earlier reviewed
candidate and its tests. Before/after raw SHA256 matched:

| Reviewed path | Before = after raw SHA256 |
| --- | --- |
| `scripts/migration/e01_boundary.py` | `0384ABC244B1A40D55043D830AABC334FD32D0457FA7810E2D1A0901D552BC2F` |
| `tests/migration/test_e01_boundary.py` | `316FF378B54566B3052EAD3AA13AA660CD1ADBF542CEF0A9CDF670F03EDD6CFF` |
| `scripts/migration/Invoke-E01BoundaryProof.ps1` (unchanged) | `5250D25BDA372AF0D8D6F8B77CDA6ACD63DBD678C0A35FAF268A2C9F8B6A5FEA` |
| `docs/plans/research/2026-10-16-e01-boundary-packet.md` (revision 3) | `D540CF96F8513833C4C708A7104F520554E8244B4502ED7A49D5F695EBE90C76` |

**Disposition: source PASS for the bounded E01-SLOW120 candidate; no new
actionable finding in this delta.** The Python request and socket caps are now
120 seconds. An explicit `request_budget_seconds` override must be finite,
positive, numeric, and no larger than 120; booleans and invalid budgets fail
before a connection is created. The connect timeout remains at most three
seconds, further reduced when a smaller request budget applies. Socket waits
before headers and each body chunk use the remaining total budget; the final
elapsed, response-size and truncation checks remain. This is source approval of
the owned-loopback diagnostic, not proof of production transport availability or
hard real-time scheduling.

Managed readiness retains its own 30-second deadline and passes only that
deadline's remaining time to the catalogue request. It does not inherit a new
120-second readiness wait. Readiness still requires the original owned process
alive and its exact post-bind marker. The owner/probe/shutdown, 30-minute process,
body/submission, credential, fixture and sibling boundaries are unchanged.

Every Python report now contains `diagnostic.label: E01-SLOW120`, its request/read
caps, three-second connect cap and 30-second readiness budget. Transport
measurements belong to that labelled report and use the new constants. Focused
source regressions cover both 120- and 30-second remaining-time calculations,
invalid/oversized budgets, the retained readiness deadline and diagnostic report
labelling. Read-only enumeration found **40 Python test methods**; no 40-test
PASS is asserted and no suite, host or phase was executed by this reviewer.

Fresh Preflight `20261016T235710Z-fcfefb29` had started under the packet commit at
assignment; its preparation-stage freeze defers the Python candidate until
Capture. Its actual status is not audited here. Before and after this review,
the old failed 30-second result JSON remained
`A90E132B530FB64A53031158857F59712F0677A2186C3828066AC1B09125702D` and its
NOT_ACCEPTED audit remained
`3071FCB50F67625E0CFCBD01BBD4C2A18376A0B545ACC28FF1DBFE022451B4AE`.
They remain immutable; the distinct slow diagnostic summary/audit paths from
revision 3 must receive any new results. A possible slow diagnostic PASS is not
a 30-second performance PASS, does not resolve Core #590, and cannot infer the
earlier command receipt. F01/F02 source repairs, prior native review scope,
mandatory final fixture privacy review and all acceptance limits above remain.

## Native gate repair: read-only UBT settings absence snapshot

Actual independent reviewing invocation: `/root/e01_native_gate_diagnosis`,
2026-10-17 UTC. This addendum records that invocation's results supplied by the
coordinator; `/root/e01_doc_final_review` compiled this documentation entry and
independently confirmed the wrapper hash, limited diff and zero PowerShell AST
errors. Neither documentation compilation nor this source review is a native
build, complete wrapper execution or acceptance result.

| Reviewed path | Reviewer's before = after raw SHA256 |
| --- | --- |
| `scripts/migration/Invoke-E01BoundaryProof.ps1` | `F3B2A938A1F314EE5FF6D39B77FADB73CB3D5E1D5E92A562957305759ACBA2DC` |

**Disposition: source PASS for this bounded wrapper delta.** The actual diff is
limited to `Get-UBTSettings`: an absent settings XML is recorded as a read-only
absence snapshot without requiring ownership of its ancestor directories. The
known absent OneDrive Documents XML can therefore be observed below the cloud
folder's reparse point. This exception creates no output there and grants no
general permission to traverse that folder for owned outputs. Existing XML
still passes the unchanged strict reparse/path guard and raw file-hash check.
`Assert-UBTSettings` still rejects an absent-to-present transition or a changed
existing hash; the post-phase and failure-path preservation checks remain.
General reparse, output containment, runtime and candidate guards are unchanged.

The independent reviewer parsed the complete wrapper with **zero AST errors**
and evaluated only its isolated settings/guard functions, twice obtaining the
same three settings observations:

| Settings candidate | Both read-only observations |
| --- | --- |
| Roaming `Unreal Engine/UnrealBuildTool/BuildConfiguration.xml` | Exists; SHA256 `1E7CD8512DEDF37D7B103C5592F5600433E7FE97DA23434E69990F8A3370508A` |
| OneDrive Documents `Unreal Engine/UnrealBuildTool/BuildConfiguration.xml` | Absent |
| Review sandbox LocalAppData `UnrealBuildTool/BuildConfiguration.xml` | Absent |

A synthetic absent-to-present snapshot comparison was rejected. Calling the
general `Assert-NoReparsePoint` on the cloud folder still rejected it, confirming
that the general ownership guard was not relaxed. The reviewer ran no complete
wrapper phase, Core host, installation, native build or Automation suite.

The prior Native result for `20261016T235710Z-fcfefb29` remains **FAIL**, SHA256
`C91BE7E9692EC7CB2DA23076E3AAB6E36926E780EED1ADAB4ED30D87B48B80B1`.
It failed on the OneDrive Documents reparse guard before the build was invoked;
this source repair does not relabel that result. The same run's actual Capture
remains `LOCAL_HTTP_BOUNDARY_PASS`, **14 discovered / 14 executed / 14 passed**,
with zero failed or blocked cases. This change rewrites none of those results.

Because the wrapper freeze changed, the coordinator planned a complete fresh
run, `20261017T002136Z-8dad7f29`, with its own preparation, Capture and subsequent
gates. Do not borrow the earlier Capture result as this new run's predecessor.
Actual new phase results, fixture privacy approval, positive native counts,
settings/cache evidence and renewed independent acceptance must be recorded
separately. This source PASS supplies none of those execution results and does
not close the retained Core, JSON, rendering, packaging or Linux limitations.

## Native log recovery supplement: auxiliary source inspection

Inspection invocation: `/root/e01_native_log_recovery`, 2026-10-17 UTC.
Reviewed code HEAD: `8955112131c8be4c26499325bddbe1d24eaf0260`.
The coordinator supplied this invocation's actual read-only inspection results;
`/root/e01_doc_final_review` compiled this addendum and independently confirmed
the current hashes and PowerShell parse/function counts.

| Inspected input | Raw SHA256 |
| --- | --- |
| `scripts/migration/Invoke-E01BoundaryProof.ps1` | `095EBF4359665E05AFCFD864EB33E2D6FA9CB7FD9CFD19BE5AFCC78DB92AAB52` |
| `docs/plans/research/2026-10-16-e01-boundary-packet.md` (revision 4) | `40CE909D2B4A36638BDC922D9093DF8650747B9F0A2DEEBE09846A86C6205249` |

**Disposition: AUXILIARY SOURCE INSPECTION PASS for these bytes. This is not
the fresh blind final code-review gate required by OWN15.** The helper inherited
implementation history and did not attest enforced read-only permissions or
no-memory behavior. Its useful source findings therefore supply neither that
renewed gate nor a final independent code-quality verdict. Earlier review records
remain historical evidence of their actual invocations and findings; this entry
makes no retroactive equivalence claim for them.

The inspection reported zero PowerShell AST errors and **37 functions**. The
embedded Python audit worker parsed as **ten top-level statements**. After its
finding was repaired, the Automation guard requires exactly **132** matching
suite tests, exactly 132 report tests and 132 successful results; the existing
successful-state and incomplete/failure checks remain. It cannot accept a
nonempty subset or unrelated extra tests as this frozen suite.

The explicit Native/Audit supplement pins the immutable successful Capture,
its child reports, reviewed original-byte fixtures and runtime identities. Only
the historical wrapper and packet entries may differ from current source;
the Python harness, regression tests and source manifest must still match.
There is no general resume, silent input substitution, copied Capture result or
new Core command path. Current native source/descriptor/targets are independently
frozen for the new phase. Authored Config directory membership and file hashes
are guarded before and after Native/Audit and on failure.

The source uses `-ABSLOG` for the new run's main native log and `-nowrite` to
suppress INI saves. Those flags do not prove global settings preservation or
the actual selected DDC path: the new execution must supply its log, ordinary
settings guards and exact Config before/after evidence. Output, runtime,
process, credential and sibling boundaries remain required. The inspection
invocation executed no wrapper phase, host, installation, build or Automation
suite; AST/source inspection is not runtime verification.

The original Native result for `20261017T002136Z-8dad7f29` remains **FAIL**,
SHA256 `CD9DE29ECB41A68E9482B6E4AB1BA951C2413BEAB9C79C65496776D29379405A`.
That attempt built and exported **132 successful Automation cases** but lacked
the required main log. Those successful tests do not repair the failed phase or
provide missing direct DDC log evidence. The fresh linked supplement
`20261017T004553Z-ba9995c1` was at Preflight when this addendum was requested;
new Native/Audit outcomes remain separate evidence.

Under OWN15, the coordinator is separately orchestrating two new `codex exec`
sessions for final code-quality review and a different requirements/acceptance
audit, with fresh contexts, read-only sandboxing, approval policy `never` and
requested `memories.use_memories=false`. Their actual session/configuration
attestations and independently established limits must be recorded. This
auxiliary helper is neither of those sessions. **No final code-review verdict
or renewed acceptance is asserted here.**

## OWN15 fresh CLI reviews, round 1: findings and provenance

This is a factual history entry compiled by `/root/e01_doc_final_review` from
the original reviewer reports and retained invocation/runtime records. It is
not this documentation writer's independent verdict or an author's approval.
The round-1 freeze has been released for remediation; neither report accepts
the affected final candidate.

Both reviewers assessed base `0467ee63fe6d4c775f429afae2233d7292787c31` and
source/fixture HEAD `8955112131c8be4c26499325bddbe1d24eaf0260`. The original
CLI reports were copied without rewriting their conclusions:

| Role / actual report disposition | Preserved report | Raw SHA256 |
| --- | --- | --- |
| Code quality: **CHANGES_REQUESTED** | [Round-1 code review](2026-10-17-e01-slow120-code-review-r1.md) | `9C8587B1877A21E14FA1FA33DA2C2663F06B63C2A5AFCBEB08B3A5ED97F5D9E3` |
| Separate requirements/evidence audit: **BLOCKED** | [Round-1 requirements report](2026-10-17-e01-slow120-requirements-r1.md) | `CEE6907DA5A5AE30D1BADDE62144912B52BA4CE11503C12213487CE2EA18CC0A` |

The retained evidence directories, relative to the repository root, are
`.local/reviews/E01-SLOW120-final/code-20261017T005624Z-511f61f4` and
`.local/reviews/E01-SLOW120-final/audit-20261017T010141Z-a7a5a8f5`.
Each contains its invocation, selected runtime evidence, executed-command
manifest, completion record and original last message. These are actual new
`codex exec` invocations, not configuration-file-only review claims:

| Role | Actual session ID | Recorded commands | Reviewing process completion |
| --- | --- | ---: | --- |
| Code reviewer | `01a1475c-2876-78b0-b114-f7a39f291ad1` | 32 | Exit 0, `2026-10-17T01:03:18.7896381Z` |
| Requirements auditor | `01a14761-3d69-7733-bc95-14c5a9afc69e` | 34 | Exit 0, `2026-10-17T01:09:12.4616831Z` |

Exit 0 denotes completion of the reviewing process, not a PASS verdict or a
claim that every attempted static command succeeded. Both reports record that
the protected Python interpreter launch was denied and no escalation or suite
execution followed. Their reported checks were static evidence inspections;
the inspected runtime test outcomes were not rerun by either reviewer.

CLI version was `0.162.0-alpha.17.2`. Invocation records retain normal user
configuration (`ignoreUserConfig:false`), no resume or fork, `--strict-config`,
`--sandbox read-only`, `approval_policy=never`, both memory-use/generation flags
false, apps disabled and multi-agent disabled. Selected authoritative runtime
metadata independently identifies both sessions as `source:exec`, model
`gpt-6.1-sol`, read-only filesystem policy, approval policy `never`, restricted
network and `memory_mode:disabled`. These observations distinguish actual
runtime metadata from requested flags. **Independent low-level attestation of
every possible backend memory-injection path remains UNVERIFIED.** The original
reports' statements about what each reviewer could personally observe remain
unchanged; this supplementary provenance does not rewrite them.

The code report records zero final mismatches among 171 source/configuration/
target/descriptor/fixture entries, but observed later changes to AGENTS and the
mixed migration plan and did not read their changed contents. Its verdict is
bound to the frozen code and supplied normative extracts. The separate auditor
bound a later documentation overlay and verified all 182 manifest entries with
no final drift. The reports preserve these different input scopes; no shared
overlay or reviewer-verdict inheritance is inferred.

The code reviewer reported two actionable findings:

- **P1:** preserve the complete finite-command envelope and scope before
  submission, record a possibly submitted timeout as UNKNOWN, and stop dependent
  mutations on that uncertain session until explicit same-envelope reconciliation
  or abandonment. Continuing later groups with the same `Pair` can otherwise
  submit new command IDs after an unknown finite result.
- **P2:** enforce the absolute request deadline throughout status/header parsing.
  A single socket timeout before `getresponse()` does not bound multiple partial
  header reads or informational responses. Add short-budget slow-header coverage,
  including UNKNOWN handling for a possibly submitted mutation.

The requirements auditor reported missing provenance-bound selections of the
raw wrapper and owned-host process ledgers: executable/script identities,
sanitized arguments, PID/start/exit, timeout, readiness and shutdown records.
The compiled factual summary was insufficient to independently establish the
complete executed-process inventory. It also reported mixed CR line endings
in the frozen migration-plan overlay causing `git diff --check` failures;
corrected documentation must receive new transparent hashes. These are the
auditor's stated blockers, not a claim that the omitted processes never ran.
Other bounded protocol, movement, native fixture, privacy and configuration
criteria were corroborated within the report's stated evidence limits.

Repairs are being authored separately under packet revision 5. Source repairs
require a new frozen candidate, a complete fresh affected execution chain and
new separate blind reviews under OWN15; the round-1 findings are not waived by
the successful subsets of earlier execution. This entry closes no finding,
supplies no fresh verdict and accepts neither E01 nor the whole migration.
Earlier failed/unknown outcomes, helper-review limitations and immutable review
reports remain preserved.

## OWN15 round-2 pre-execution source review

Fresh CLI session `01a1476f-83f2-7160-b47b-50634d75e095` assessed clean HEAD
`f318dc2a78da478867f79af5cb80159408fd5369` against base
`0467ee63fe6d4c775f429afae2233d7292787c31`. Its byte-exact
[original report](2026-10-17-e01-slow120-code-review-r2.md), SHA256
`800B48EAB7C605C61A8F772D0F27AF0312E70665077403D4E9E57D427CCF8EBA`,
is **CHANGES_REQUESTED**. The reviewing CLI completed at
`2026-10-17T01:23:55.681524Z`, exit0, with29 completed read-only commands.
All173 declared candidate hashes and the clean tree remained unchanged.

The context received clean normative criteria and source-bound47-unit logs,
not earlier reviews, author notes or mixed status prose. Automatically loaded
AGENTS had prior findings removed before launch; no context launched against
the preceding instruction draft. Invocation/runtime records under ignored
`code-r2-20261017T011712Z-0d44782b` retain CLI0.162.0-alpha.17.2, actual
modelgpt-6.1-sol, read-only/approval-never, memory_mode disabled and no resume/fork.
Low-level memory internals remain unverified. These supplementary observations
do not rewrite the original reviewer's personal-observability statements.

The report found attach-worker finite and supervisor start/close commands bypassed
the paired guard, losing pre-send envelopes and explicit UNKNOWN on response loss.
It also found normal Native checked promoted wire only against itself, allowing
stale bytes unrelated to current Capture. It requires guarded command lanes and
Capture index/body binding through Audit. The deadline repair and inspected47-unit
evidence were supported, not current-candidate runtime acceptance.

Revision6 covers focused repairs and a complete worker process inventory. No new
Core Capture/build/native phase ran. Fresh source review precedes the full chain;
final code/requirements contexts cover final promoted fixtures/results. This
factual entry supplies no independent verdict or waiver of either P1 finding.
