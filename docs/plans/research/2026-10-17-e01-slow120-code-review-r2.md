**CHANGES_REQUESTED — CODE QUALITY**

Role: independent code reviewer. I did not author or modify the candidate, delegate work, launch another reviewer, or perform publication actions.

Reviewed base `0467ee63fe6d4c775f429afae2233d7292787c31` through frozen HEAD `f318dc2a78da478867f79af5cb80159408fd5369`, including the manifest-defined working tree.

**Actionable findings**

1. **P1 — Attach/lifetime commands bypass envelope retention and UNKNOWN handling.**  
   [e01_boundary.py:1142](C:/SWDev/warhammer/Warhammer_40k_UI_unreal/scripts/migration/e01_boundary.py:1142), with the same bypass at lines **1155** and **1186**.

   The attach worker submits its finite command directly through `Endpoint.request`; the supervisor similarly submits attach-session start and close commands directly. These paths bypass `Pair.submit`, which provides schema validation, the pre-send envelope/role/session ledger, and `CompletionUnknown`.

   If Core commits the attach action but its response times out, the worker exits before writing its result. The supervisor reports “Attach worker failed,” and `run_case_groups` records `completionOutcome: NOT_ASSERTED`. The exact envelope and submitted scope were never persisted. Start/close response loss has the same retention gap.

   Route these commands through a submission guard that persists the complete credential-free envelope and scope before possible transmission, records uncertain completion as **UNKNOWN**, and abandons the affected session. Add commit-before-response-loss regressions for the worker and supervisor lifecycle paths. Current tests exercise this protection through `Pair.submit` only.

2. **P1 — Native can consume historical wire fixtures after a fresh Capture.**  
   [Invoke-E01BoundaryProof.ps1:875](C:/SWDev/warhammer/Warhammer_40k_UI_unreal/scripts/migration/Invoke-E01BoundaryProof.ps1:875), concerning the normal Native path at lines **859–879** and Audit at **913–914**.

   Native checks the successful current Capture’s authored candidate, then reads `fixtureRoot/wire/index.json` and verifies bodies against that index’s own hashes. It never compares this set with the current run’s `capture/python-capture/proposed-wire` artifacts. Audit subsequently inspects the current Capture output separately, without establishing that Native consumed those bytes.

   Consequently, leaving the historical `E1658B…` wire set unchanged after a fresh Capture can still satisfy Native’s fixture checks and 132-case gate. This permits a phase chain whose Native evidence is unrelated to its fresh Capture.

   Bind the reviewed, promoted index and every Native-consumed body to the current Capture’s recorded artifact hashes before building or running Native, and retain that linkage through Audit. Add a regression requiring rejection when current Capture artifacts and promoted fixtures differ. Preserve independent privacy review before promotion.

**Candidate identity and drift**

All **173 manifest files matched before and after review**. HEAD remained unchanged; the working tree was clean. No executable or documented-status overlay drift was observed.

Relevant SHA-256 identities:

| Input | SHA-256 |
|---|---|
| Input manifest | `D06FBEEF136F107285510986DA941A641A9291CC0327F073AAE20E35A16507D6` |
| Python harness | `3C9A1F57009E070968BE82A58F3E839BFCC1CA556D7899CD4585209581248E3B` |
| PowerShell coordinator | `095EBF4359665E05AFCFD864EB33E2D6FA9CB7FD9CFD19BE5AFCC78DB92AAB52` |
| Python tests | `C8C8453FFDF01B71E7E7FC2734542271BB3732372843AE8D0E738AD6B8AEEB7E` |
| Fixture source manifest | `BF861B2EC555C81E85A31E4B37E756C5E6B04D343522A95F3235700C2AEC43F2` |
| Historical public wire index | `E1658B116E6ED53F84CEE84B3D8A5C1ADFD3DED3FA225DB61D80D21D9953DF0A` |

Core remained clean at `5f509724da25a2f6ded0c2739a8e7c84bdf59c91`; Arcade remained clean at `5088c1c49dcaff29eb59fb64b3063d30214dde73`. Core’s source manifest declares Contract `44.3.33`, the selected runtime build ID ending `65fc8414407ae5d6a8ea779c8e737a22733459094db679a160c60f6e2129f96a`, and 3,116 resources.

**Inputs and personally performed checks**

Read the clean manifest, normative criteria, invocation/runtime extracts, selected raw unit evidence, necessary AGENTS, both migration scripts, Python tests, native reader/tests, application callers, targets, descriptor, Config and `.gitattributes`. Inspected fixture inventories, schemas/examples and all 30 public wire bodies through parsing and targeted semantic summaries. Inspected relevant immutable Core contract, command handling, launcher and fixture-recipe source.

Personally verified:

- All 127 source inventory members’ checkout hashes and Git blob identities, and matching contract copies.
- All 234 normalized committed contract hashes.
- Parsing of 121 canonical JSON files and all indexed public wire bodies; all wire body hashes matched.
- PowerShell static parsing: zero errors.
- Public wire credential-marker scan: no matches; this is not privacy acceptance.
- `git diff --check`: default check reported 632 CR-at-EOL findings in the immutable OpenAPI fixture. It contains 632 CRLF endings and no trailing spaces/tabs. The CR-aware check passed.
- Root `.gitattributes` stays within its permitted plan/report patterns.

An AST-only Python invocation failed to start with **Access is denied**. No Python code executed through that attempt; no escalation was attempted. I ran no unit suite, harness phase, runtime preparation, Core host, build, automation or generator.

**Prior execution evidence inspected**

The selected unit invocation records PID `37244`, exit `0`, isolated Python `-I -B`, and identical before/after harness/test hashes matching this candidate. The original stderr independently hashes to:

`46BF8DF99B304DEA929477A8A0A612426928A20CAD860C48B5ECED37F46BC16E`

It records **47 tests passed in 1.109 seconds**. Stdout is empty with the expected empty-file hash. The invocation extract is explicitly derived; its recorded original invocation hash was not independently verified outside the clean packet.

The tests cover useful deadline, HTTP/1.0 ownership, schema, reducer, pose and paired UNKNOWN regressions. They do not cover the two findings above. The Native guard requires 132 unique successful results; no current-candidate case-level Native execution result was established here.

**Isolation evidence and limits**

The supplied runtime extract reports session `01a1476f-83f2-7160-b47b-50634d75e095`, turn `01a1476f-8497-70b0-9c69-66ff1b639eee`, CLI `0.162.0-alpha.17.2`, model `gpt-6.1-sol`, effort `ultra`, source `exec`, and `memory_mode: disabled`.

Invocation evidence requests strict configuration, read-only sandbox, approval `never`, both memory settings disabled, apps/multi-agent disabled, and no resume/fork. Active permission instructions also specify restricted read-only filesystem access, restricted networking and approval `never`. I used only read-only/static operations. These records do not independently attest every low-level memory injection path or OS enforcement detail.

No excluded prior verdicts, author chats/notes, private projections, privileged-wire bodies, host logs, generated credential configuration or credential stores were read. Excluded document filenames appeared only as metadata. No prohibited context contamination was detected.

**Acceptance exclusions**

Revision 5’s current-candidate full phase chain is **NOT RUN** according to the clean manifest. Historical runtime success cannot supply that proof. This report does not establish requirements acceptance, privacy approval, full E01, production responsiveness, Unreal transport/scheduling/rendering/packaging, Linux execution, or low-level memory isolation. The original 30-second FAIL/UNKNOWN remains unchanged.