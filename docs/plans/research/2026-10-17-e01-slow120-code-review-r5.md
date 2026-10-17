**CHANGES_REQUESTED — code quality of this exact E01-SLOW120 candidate.**

Role: independent code reviewer. I did not author or modify the candidate, delegate, launch another reviewer, merge, or contact others. This assessment used read-only static inspection.

Base: `0467ee63fe6d4c775f429afae2233d7292787c31`  
HEAD: `83815a4a12b049d7ecd537328fd47d201e4e34e2`

All 174 manifest-listed files matched before and after review. HEAD and the clean working tree remained unchanged; no executable or documentation overlay drift was observed. The instruction-file hashes also matched.

Relevant SHA256 bindings:

| File | SHA256 |
|---|---|
| `input-manifest.json` | `309f71240abde0bb4dea78d7620ac56fcec4337fb284ec53754195f7bf298dcc` |
| `normative-criteria.txt` | `2d86112b4191932769d2368c02c6883978184886310881b7bcf0034a563e8c6e` |
| `scripts/migration/e01_boundary.py` | `551c379c4dd2df102ac9ab9a68fcf2b1ebd21bb070152a2963076f2783813bb0` |
| `scripts/migration/Invoke-E01BoundaryProof.ps1` | `e5fb8305e22398eacc7dfa263373e6c480d7152b0b47dabc7cfdfee18d7ea86e` |
| `tests/migration/test_e01_boundary.py` | `38d0e21136821f5a0b3a6ecb744c764ee1ba3f70a052dd2a54f9c0f018013a68` |
| `CoreBoundaryEvidence.cpp` | `217d3ef245aa610ee99fa9e87223f8a9fa844ae1c99da996633d41d28e82dbf8` |
| `CoreBoundaryEvidenceTests.cpp` | `208ec4402ab87beed977dcf26dab2d8cf122a71124936186e85227a9d15c14ff` |
| Public `wire/index.json` | `e1658b116e6ed53f84cee84b3d8a5c1adfd3ded3fa225db61d80d21d9953df0a` |

**Actionable findings**

1. **[P2] Native classification accepts internally inconsistent receipts.**  
   [CoreBoundaryEvidence.cpp:638](C:/SWDev/warhammer/Warhammer_40k_UI_unreal/Source/WarhammerClient/Private/Migration/CoreBoundaryEvidence.cpp:638), through line 645.

   Starting with the canonical accepted outcome, change only `event_range.to_cursor`, checkpoint `visibility_role`, or checkpoint `viewer_player_id`. Native validates their individual types but never compares the range endpoint with the checkpoint cursor or checkpoint scope with `session.visibility`. It can consequently return `Accepted` for a receipt that Python rejects at `e01_boundary.py:278–282`.

   Add these coherence comparisons and corresponding native negative assertions. The Python mutations at `test_e01_boundary.py:313` already cover these discrepancies; the native negatives do not.

2. **[P2] Session creation trusts an incomplete or mismatched HTTP 201 receipt.**  
   [e01_boundary.py:718](C:/SWDev/warhammer/Warhammer_40k_UI_unreal/scripts/migration/e01_boundary.py:718).

   The success branch checks only a nonempty `session_id`. A 201 body containing just that field passes this guard. More generally, complete metadata for the wrong game, build, contract or administrator scope is not validated here. The attach supervisor immediately uses the returned ID for `start_session` at lines 1453–1455. The main lane’s later build/contract comparison also omits submitted-game binding and complete metadata validation.

   Validate the full selected-Core session-metadata response and its applicable identities against the retained creation request inside this guard. An unusable post-submission receipt must retain UNKNOWN and prevent downstream commands. Add malformed and wrong-identity 201 controls for both creation lanes; existing tests cover response loss and outgoing schema failure.

3. **[P2] Failure to write the shutdown marker bypasses owned-host termination and ledger finalization.**  
   [e01_boundary.py:566](C:/SWDev/warhammer/Warhammer_40k_UI_unreal/scripts/migration/e01_boundary.py:566).

   `stop()` cancels its timer before calling `shutdown.touch()`. If that operation raises, for example because of access denial or exhausted storage, execution never reaches the handle-based termination fallback, log closure, or process-record append. Capture can then exit unsuccessfully while its host remains alive. The wrapper’s `Stop-OwnedProcess` skips termination once the harness itself has exited, so it does not repair this orphaned-host path.

   Treat marker-write failure as a reason to use bounded cleanup through the retained process handle, and finalize ownership evidence in `finally`. Add a marker-write failure regression proving host termination and retained failure details.

4. **[P2] Deeply nested terminal JSON escapes typed UNKNOWN handling.**  
   [e01_boundary.py:1301](C:/SWDev/warhammer/Warhammer_40k_UI_unreal/scripts/migration/e01_boundary.py:1301), with the exception boundary at line 1390.

   A terminal file can remain well below 64 MiB while exceeding the JSON decoder’s recursion depth. `strict_json()` then raises `RecursionError`, which is absent from this handler and the surrounding case-group/main handlers. The result escapes without the required typed worker UNKNOWN disposition or exported Capture process ledger, despite possible prior transmission.

   Bound decoder nesting or explicitly translate this decoding failure into the unusable-terminal UNKNOWN path. Add a deeply nested terminal regression alongside the existing malformed/truncated controls.

These findings are established by static control-flow inspection; I did not execute reproductions.

**Inputs and checks**

I inspected both migration scripts, both maintained test files, the complete native reader/tests, application callers, module/target files, descriptor and authored configuration. I read the permitted AGENTS, clean criteria, manifest, selected invocation/results and original unit logs, plus relevant selected-Core contract/server references. I did not read excluded reviewer reports, author notes, mixed planning histories, private projections, privileged wire, host logs or credential bodies. No context contamination was encountered.

Personally performed checks:

- Verified all 127 source-inventory hashes and Git blobs, all 122 copied contract files, and all 234 normalized canonical hashes against the selected Core.
- Parsed all 122 copied JSON-formatted contract files; confirmed 98 unique interaction cases: 73 finite, one nested and 24 parameterized.
- Parsed and hash-checked all 30 public wire bodies. The bounded credential-pattern scan found no matches or administrator rows; this is not independent privacy approval.
- PowerShell AST parsing passed for both scripts.
- Authored-code `git diff --check` passed. Whole-delta checking reported 632 trailing-whitespace diagnostics confined to the byte-preserved canonical `contracts/openapi.yaml`; its source bytes matched.
- Python static parsing was **not performed**: launching the selected interpreter was denied by the runtime sandbox. No escalation was attempted.

Prior evidence inspected, not personally executed:

- Original stderr reports **72 tests, OK**, consistent with 72 source test definitions. Invocation exit was 0; before/after source hashes match this candidate. Original stdout is empty.
- The guard log/result reports **19/19 PASS**, explicitly simulated filesystem/Capture-binding checks. All 37 selected source-after bindings still match.
- Original evidence hashes match the supplied descriptors, including unit stderr `fd22bd40382af97bbc7f2bddc17198b34adc197fc30bb06cfa535a1a5a91f3da` and guard result `f1e54a404d37cbfee677b2c1cee4ff7beb96e1b04cd41dc1e94798e48eef7454`.

The source retains the fresh-chain checks and current-Capture index/body binding. Historical `CaptureRunId` reuse rejects the changed Python bytes. Native enumeration is designed for 132 cases; **no current native execution count or success is established**.

**Isolation evidence and limits**

The supplied invocation identifies CLI `0.162.0-alpha.17.2`, packet invocation `code-c5-20261017T021049Z-5171b09b`, supervisor PID `30736`, new exec/no resume/no fork, strict config, read-only sandbox, approval `never`, disabled apps/multi-agent and both memory settings false. Runtime instructions independently specify read-only/approval-never, and the interpreter denial is observed enforcement evidence.

An actual session UUID and deployed model identifier were not exposed in the permitted evidence; they remain **UNVERIFIED** beyond the runtime’s GPT-6-family identification. Requested memory suppression and reported disabled memory mode do not attest every low-level injection path. I did not inspect configuration, authentication or memory stores.

The current full Preflight → PrepareRuntime → Capture → Native → Audit chain is **NOT RUN**. This report grants no requirements acceptance, privacy promotion, publication/merge approval, full E01 acceptance, production responsiveness, UE transport/rendering/packaging or Linux proof. Historical failures and UNKNOWN outcomes remain unchanged.