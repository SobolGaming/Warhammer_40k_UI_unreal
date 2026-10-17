**BLOCKED — bounded E01-SLOW120 requirements/evidence assessment.**

The supplied evidence supports the reported protocol outcomes, movement, native fixture execution, and configuration preservation. Final evidence compliance is blocked by missing raw process records. The frozen documentation overlay also fails `git diff --check`.

I acted only as the independent requirements/acceptance auditor. I made no edits, delegated no work, contacted nobody, and ran no harness, host, build, automation, installation, or generator. I did not obtain or infer the independent code reviewer’s verdict.

### Candidate and isolation

Assessed:

- Base: `0467ee63fe6d4c775f429afae2233d7292787c31`
- Executable/source/fixture HEAD: `8955112131c8be4c26499325bddbe1d24eaf0260`
- Packet: `audit-20261017T010141Z-a7a5a8f5`
- [input-manifest.json](/C:/SWDev/warhammer/Warhammer_40k_UI_unreal/.local/reviews/E01-SLOW120-final/audit-20261017T010141Z-a7a5a8f5/input-manifest.json) SHA256: `F97DB1D05523AEF394F2F382F245F4BE14CF885D3ABFFD6EA23E4345721D4348`

All **182 candidate, instruction, and documentation-overlay hash entries matched**. A final recheck found no drift. HEAD and working-tree status matched the declared candidate.

The final factual overlay is bound by these verified SHA256 values:

| File | SHA256 |
|---|---|
| `AGENTS.md` | `57787AE6473A24F35214AC0A2C41DB394E08B1846CA6900DF6A87BBA1B0FE0C8` |
| `README.md` | `B34603ABC70A0DD72A27CAE577C04AB5B5173ACCEB8A367DF8187BEB69F50835` |
| `docs/plans/README.md` | `D08268C0A7D1A5B5B2032EC7C80E7D3258E5D90653331164878258FE179939E8` |
| `docs/plans/unreal-migration-plan.md` | `564C1FEFF285BD14B4246630E87DDFEAC92744D17392707B0BE686FFC93E7AB9` |
| `docs/plans/evidence/2026-10-16-e01-slow120-result.json` | `648AF28B6C1AA88AA5CE265E7B5A86DEDEB5686D113F3BAC5D02D4A542F9E1F2` |

The three excluded journal/review-history overlays also matched their manifest hashes; their bodies were not inspected.

`invocation.json` records CLI `0.162.0-alpha.17.2`, a new invocation starting `2026-10-17T01:01:57.1567389Z`, no resume/fork, retained normal user configuration, and explicit strict-config/read-only/approval-never, disabled memories, apps, and multi-agent settings. These are invocation records, not independent proof of every underlying implementation property.

The active runtime instructions independently expose read-only filesystem permissions and approval policy `never`. An attempted Python executable launch was denied; subsequent checks used PowerShell. No escalation was attempted. The runtime identifies the GPT-6 family, but the exact deployed model identifier and an internal session UUID were not independently observable. Memory suppression beyond the requested settings remains **UNVERIFIED**; neither accepted flags nor `memory_mode=disabled` would attest every possible injection path.

No reviewer-verdict contamination or inherited implementation transcript was observed. Only permitted extracts, source, fixtures, metadata/hash checks, and configuration-observation records were used.

### Findings

1. **Acceptance blocker: raw process provenance is absent from the selected evidence.**

   `capture-result.selected.json`, `python-report.selected.json`, and the supplement’s selected Preflight/PrepareRuntime/Native/Audit results omit their process ledgers. Actual PIDs, complete command arrays, start/exit times, timeout flags, and managed-host readiness/shutdown records appear only in the implementer’s compiled factual summary.

   Source supports the intended controls, raw phase timestamps are bounded, and the actual native logs corroborate the native command and completion. Those facts do not independently verify every process record asserted by the compiled summary or establish a complete executed-process inventory.

   **Required evidence:** provenance-bound, sanitized selections of the original wrapper `.processes` records and Capture Python report’s owned-host `.processes` records, including executable/script identities, arguments without credentials, PID/start/exit, exit/timeout, readiness and shutdown fields. This should also expose the supplement’s complete process inventory to substantiate the no-host/no-game-command claim. No runtime rerun is indicated by this evidence gap.

2. **Documentation check failure: mixed line endings produce trailing-whitespace errors.**

   `git diff --check` failed at `docs/plans/unreal-migration-plan.md` lines **7, 235, 403, 507, and 558**. Inspection found terminal CR characters on those lines, rather than trailing spaces.

   Normalize the affected line endings, rerun the check, and transparently bind the resulting documentation hash. This is a documentation correction; it does not invalidate the inspected runtime outcomes.

### Criterion-to-evidence mapping

Here, `P` means the supplied audit-packet directory; `F` means `tests/migration/fixtures/5f509724da25a2f6ded0c2739a8e7c84bdf59c91`. Source references are to the frozen Unreal HEAD above.

| Criterion | Evidence and assessment |
|---|---|
| **SOURCE-01** | Independently verified all **127 unique source-member byte hashes and Git blobs**, all copied contract members, and **234 normalized contract hashes** against the selected clean Core. All matched. `F/manifest.json` and the interaction-conformance fixture agree on **98 unique IDs: 73 finite, one nested, 24 parameterized**. `e01_boundary.py:169` implements the corresponding checks. **Supported.** |
| **Runtime/schema inventory** | Raw Capture `RUNTIME-01` records Python 3.14.5, installed Core beneath owned `.local/core-44.3.33`, the exact build ID, **3,116 resources**, eight dependency imports, and the installed distribution inventory. `SCHEMA-01` records **93 examples** validated through the frozen local registry without network resolution; source is `e01_boundary.py:201–243`. These are inspected prior results, not imports or schema validation rerun by me. **Supported within that limit.** |
| **FINITE-01** | `python-report.selected.json`, `cases[FINITE-01]`, records request `decision-request-000001`, offered option `fixed:assassination:bring_it_down`, command `e01-finite-decision-request-000001`, revision **1→2**. Public `wire/finite_accepted/playerA.json` independently contains accepted/committed true at revision 2. `e01_boundary.py:836` selects an offered option under the actor’s scoped context and compares local/HTTP results. **Supported.** |
| **MOVE-01** | Public movement-before/after bodies, the raw pose evidence, and `e01_boundary.py:691–748,966–1023` agree. I independently matched every reported endpoint to authoritative projected poses and verified the inventory against current placed, living physical models. All five moved **+1 inch X**, with zero Y/Z/facing change. **Supported; no rendering or nonzero-elevation proof.** |
| **MOVE-02** | Three public inventory-error bodies contain the uncommitted generic 422 error envelope. Raw case evidence reports unchanged revision/request/history for those attempts. The recorded-invalid body has accepted false, committed true, `proposal_invalid`, revision **20**, and fresh request `decision-request-000020`; corrected movement commits revision **21**. History-count observations are raw harness assertions, not a replay export I inspected. **Supported within the selected evidence.** |
| **RETRY-01** | Raw result explicitly labels injected response loss, byte-equivalent same-envelope retry, unchanged revision 2, and response hash `847c180f…164a82f`, matching the public finite outcome. Source `e01_boundary.py:836–876` resubmits the same command and role, checks exact response bytes, and checks changed-result-ID conflict. `wire/retry_changed_envelope/playerA.json` confirms 409 `command_id_conflict`. **Supported.** |
| **STALE-01** | Public wrong-revision body confirms 409 `session_revision_conflict`; consumed-request body confirms scoped 403 `access_denied`. Raw `STALE-01` records waiting-advance `advance_not_required`; source requires its actual 409. This admin-lifecycle response is excluded from public fixtures. **Supported by raw case results and source.** |
| **AUTH-01** | Independently inspected missing/invalid 401 and coach/delayed/replay/wrong-player/forged-viewer 403 public bodies. They contain only the shared error-envelope shape, without request/options/event counts. Administrator gameplay denial is recorded by raw `AUTH-01` and checked in source; its privileged body was correctly excluded from this audit. **Supported with that visibility limit.** |
| **VIEW-01** | Public Player A and coach projections expose Player A’s offered secret choice; Player B receives `hidden_decision`, `hidden-request`, null actor/interaction, and no options. Delayed spectator is revision **0**, while players/coach are revision **1**, with no delayed pending decision/events. Wrong-viewer cursor response has empty events and `resync_required:true`, `wrong_viewer`. Source `e01_boundary.py:777–833` checks local/HTTP equality and server-owned delay. Terminal replay remains explicitly NOT_RUN. **Supported for this bounded snapshot/event evidence.** |
| **ERROR-01** | Public bodies retain actual 401/403/404/409 and both 422 shapes. Raw result records malformed HTTP 400; source `e01_boundary.py:1025` requires it. Existing `/games/{game_id}/support-profile` returned 200. Python and native strict-negative sources cover malformed JSON, missing/null/wrong-type fields, invalid acceptance flags, and accepted-before-later-unsupported semantics. **Supported; malformed/admin bodies were not inspected.** |
| **FIDELITY-01** | All three inventory bodies match hash `d7e7e713…06320b0` and contain HTTP **422**, code **`proposal_invalid`**, message **“Submitted proposal was invalid.”** Raw evidence and native reader explicitly preserve **“Detailed engine reasons were not supplied by this HTTP response.”** and Core #588. The detailed recorded-invalid geometry response remains a separate branch. **Supported.** |
| **SCOPE-01** | `e01_boundary.py:281–300,750–762` clears body/cursor/draft on scope changes, rejects old generations and lower revisions, and tests viewer/session changes. Raw case reports these deterministic assertions passed. **Supported as reducer evidence; UE callback scheduling remains unproved.** |
| **LIFETIME-01** | Raw case records authorized attach acceptance, busy-port rejection before launch, unaffected other session, owned stop, and restart `SessionLost` without recreating the old session. Source `e01_boundary.py:393–497,1045–1112` bounds readiness, retains process handles, and separates attach from supervision. Late Windows co-bind exclusivity remains explicitly NOT_PROVEN. **Behavioral result supported; detailed executed process provenance BLOCKED by finding 1.** |
| **NATIVE-01** | Exact Automation index independently contains **132 unique successful identities**, zero warnings/errors/failures/notRun/inProcess. Breakdown is **98 canonical envelopes +30 public wire cases +4 aggregate/negative/preservation cases**. Selected main log independently has 132 unique Success completions and queue-empty count 132. Native sources preserve string IDs, JSON types/nulls/order/numeric lexemes and reject unsupported revisions, malformed structures and invalid flags. Case-colliding keys fail visibly with `unsupported_key_case_collision`; RISK19 remains open. **Supported as fixture evidence.** |

The five ordered physical-model witnesses in the raw pose evidence are suffixes **004, 005, 001, 002, 003** of `army-alpha:scout-redeploy-unit:core-intercessor-like`. Their initial/final poses match the public authoritative bodies. The fixture construction’s leading-first ordering is explicitly limited in source to the selected uniform-translation recipe; this assessment supplies no general client reordering or legality policy.

### Immutable linkage, privacy, and configuration

The successful Capture is immutably linked to the fresh supplement:

| Artifact | Verified SHA256 |
|---|---|
| Capture `20261017T002136Z-8dad7f29/capture/result.json` | `137CEAAA5A3B85F3A49193525EEB198AEDAF28A113B7F760DA66081D5983E699` |
| Capture Python report | `C99109764C6708889F2DC365696D03A9FD987465DD6E5D71F108A794223530A0` |
| Public/original Capture wire index | `E1658B116E6ED53F84CEE84B3D8A5C1ADFD3DED3FA225DB61D80D21D9953DF0A` |
| Supplement Native result | `58DCDADA2AACED2F72D4026CAB9A382EDCC8C1A513CB09C8F69BDDE9DD287ED2` |
| Supplement Audit result | `8D5A0D821B73814043AB16188BD9B72612D1855850AB45157B8CBC14F5FE569D` |
| Automation index | `A469EA4CD41CD6E6C30873ED9871A391FD69B98BAEF77DC6F328F7AFD93B7A24` |

The historical Capture’s packet/wrapper hashes match the revision-4 exceptions; unchanged driver, tests and source-manifest hashes match current files. `Invoke-E01BoundaryProof.ps1:374–465,726–770` restricts linkage to this exact Capture, validates predecessors and identities, and rejects replacement Capture. The supplement currently contains no `capture` directory. Its audit worker calls only the static audit path and writes beneath the fresh run. Complete actual process-inventory verification remains the finding-1 blocker.

I independently parsed and hashed **all 30 public wire bodies**: 30 unique paths/case-role pairs, all HTTP-labelled, no admin body, all index hashes matching. Credential-field/header/value-shape scans found no matches. Role-sensitive projections, events, outcome metadata, and denial bodies were inspected independently; no public-fixture privacy blocker was found. This does not attest forbidden private artifacts, which I did not read.

Raw runtime records consistently bind:

- Core `5f509724da25a2f6ded0c2739a8e7c84bdf59c91`, Contract **44.3.33**;
- runtime build suffix `65fc8414407ae5d6a8ea779c8e737a22733459094db679a160c60f6e2129f96a`;
- runtime-tree hash `b01989fc595730d8ea6f1a10c7a5004510fca877a9b69aad9f3285cab357a897`;
- provenance hash `39c485c33e482b158edb157a0ffaa69224c09e15de5655277b64289887f7cf7c`.

Source rejects `.pyc` files in the owned runtime. I did not reimport or rehash the complete installed runtime tree. Both sibling checkouts were independently observed clean at the required commits.

Actual native log lines **32/473** include `-ABSLOG`, `-nowrite`, the owned user/DDC paths and `-DDC-NoDefaultGraph`. Lines **941–945** show installed EnginePak opened for reading and the supplement’s Local DDC writable path. The selected DDC evidence shows no fallback. The build log records success; toolchain records identify UE **5.8.3/CL58210709**, MSVC **14.44.35229**, SDK **10.0.22621.0**.

I read and compared the safe six-path configuration observations:

- before hash `BB2DCFF5…10EDC5`;
- after hash `49A73082…2BFABB`;
- identical existence/hash sets, no changed paths.

Raw Native/Audit records also preserve all three authored Config files and exact membership; current bytes match. Three UBT existence/hash observations agree before/after. These observations do not claim universal confinement of every Unreal or build-system side effect.

### Checks performed and remaining limits

Personally executed only static reads, JSON parsing, hashes, Git identity/status/blob/whitespace checks, count/uniqueness checks, credential-pattern scans, and pose comparisons. I inspected prior raw results reporting:

- **40 Python unit checks PASS**, corroborated by 40 source test definitions;
- **14/14 Capture cases PASS**, no failed/blocked/notRun required cases;
- **132/132 unique native cases Success**, no failed/incomplete cases;
- **2/2 automated artifact-audit cases PASS**.

The automated audit is not independent acceptance. Required suites were not rerun.

Historical failed-attempt artifact hashes remain unchanged. The original 30-second run remains **FAIL/UNKNOWN**; earlier reparse-guard and missing-log Native failures remain failures. The historical configuration observation still records creation of global EditorSettings; its preserved hash matches the supplement baseline. Generated configuration recovery was hash-checked only; quarantined bodies were not read.

The selected final factual claims stay within the demonstrated protocol scope. Final Capture records **139 HTTP requests**, maximum **36.9959446 seconds**, largest request **222,671 bytes**, largest response **2,610,120 bytes**. The separately identified predecessor’s approximately 38.1-second result does not pass a 30-second budget. Production responsiveness remains unresolved.

Full E01/M01/G-RESEARCH/G-IMPLEMENT, terminal replay, native UE HTTP and callback scheduling, rendering/genuine 3D/input, packaging/offline/clean-machine delivery, durable recovery, hardened remote roles and Linux execution remain outside proof. The 98 envelopes establish shape coverage, not 98 live workflows.

This report supplies no code-review approval. A later acceptance PASS requires closure of the raw-evidence blocker, correction and rebinding of the documentation overlay, the separate current code-review gate, and transparent binding of both final reports.