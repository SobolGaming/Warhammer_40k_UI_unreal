# E01 frozen candidate source review

Date: 2026-10-16. Reviewer invocation: `/root/e01_frozen_review_record`.
Disposition: **SOURCE REVIEW PASS for the final candidate below; F01/F02 repaired
in source. Execution and independent acceptance remain pending.** This is a separate
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
