**CHANGES_REQUESTED — independent CODE QUALITY review of the pre-execution source candidate.**

Role: independent code reviewer. I did not author or modify the candidate, delegate, launch another reviewer, merge, or access another reviewer’s verdict.

Candidate identity:

- Base: `0467ee63fe6d4c775f429afae2233d7292787c31`
- HEAD: `7d56685b39c15df220937584999cc36c1d729e2a`
- Input manifest SHA256: `97103912645fb3ad940fc2574d4bbf6d688ef84f15480a000876a1a32af9cdd3`
- All **174 manifest file hashes matched before and after review**. HEAD remained unchanged and the working tree remained clean. Instruction and normative-source hashes also matched; no executable or documented status-overlay drift was observed.
- Core: `5f509724da25a2f6ded0c2739a8e7c84bdf59c91`, Contract `44.3.33`, runtime build `warhammer40k-core-v2:runtime-tree-sha256-v1:65fc8414407ae5d6a8ea779c8e737a22733459094db679a160c60f6e2129f96a`.
- Arcade baseline: `5088c1c49dcaff29eb59fb64b3063d30214dde73`. Both sibling checkouts were clean at their selected commits.

Relevant SHA256 identities:

| File | SHA256 |
|---|---|
| `scripts/migration/e01_boundary.py` | `981c22d4b102afebe812ea71b667dce44e578b73a227f3ebb1dce14935dc0ec9` |
| `scripts/migration/Invoke-E01BoundaryProof.ps1` | `e5fb8305e22398eacc7dfa263373e6c480d7152b0b47dabc7cfdfee18d7ea86e` |
| `tests/migration/test_e01_boundary.py` | `63c57194ab5f739a2ec8024ab6c861d5b4b189097e894f9c42a5904fde0793412767f6240` |
| Fixture `manifest.json` | `bf861b2ec555c81e85a31e4b37e756c5e6b04d343522a95f3235700c2aec43f2` |
| Public `wire/index.json` | `e1658b116e6ed53f84cee84b3d8a5c1adfd3ded3fa225db61d80d21d9953df0a` |

The test-file identity above should be read as **`63c57194ab5f739a2ec8024ab6c861d5b1b2993666b4710d1da94a78e087da92`**, matching the verified manifest.

**Actionable findings**

1. **P1 — Command receipt validation does not consistently establish a coherent, envelope-bound outcome.**  
   At [e01_boundary.py:269](C:/SWDev/warhammer/Warhammer_40k_UI_unreal/scripts/migration/e01_boundary.py:269), `classify` validates session and checkpoint revisions independently, without requiring their revision, projection hash and cursor to agree. `HttpCommandLane.submit` checks command/session IDs at line 674, but does not close this consistency gap. The worker’s parent reuses the same classifier at line 1328.

   A finite-command response with matching command/session/operation and valid acceptance flags, but a different checkpoint revision, satisfies these checks and the frozen JSON Schema. The worker can emit `ACCEPTED`, the parent can validate its terminal result, and lifetime processing can subsequently close the session. Native `ReadOutcome` rejects equivalent inconsistencies, but the private attach-worker receipt is outside that native fixture lane.

   Additionally, [Pair.submit:766](C:/SWDev/warhammer/Warhammer_40k_UI_unreal/scripts/migration/e01_boundary.py:766) returns matching local/HTTP replies without receipt classification, schema validation or response-to-envelope identity checks. Matching `200 {}` replies therefore fail later as an ordinary `BoundaryError`, leaving `submission_unknown` false and reporting `NOT_ASSERTED` instead of UNKNOWN. Dependent groups still stop, but the completion classification is incorrect.

   Establish complete receipt coherence and submission binding inside every submission guard before treating completion as received. Add negative tests for inconsistent checkpoints, wrong receipt operation/identity, and matching unusable paired responses.

2. **P2 — A damaged receipt artifact can erase an already validated worker outcome.**  
   At [e01_boundary.py:1326](C:/SWDev/warhammer/Warhammer_40k_UI_unreal/scripts/migration/e01_boundary.py:1326), a `FAILED_EVIDENCE` terminal retains its known outcome when the raw receipt file is absent. If that file exists but is truncated or unreadable, validation fails before `known_received` is set, and line 1360 converts completion to UNKNOWN.

   Concrete trigger: `HttpCommandLane` validates a response and sets `last_reply`; saving its receipt partially writes the file and then raises an I/O error. The worker correctly emits a complete typed `FAILED_EVIDENCE` result with the received flags. The parent then parses the partial receipt and discards that known completion. The existing regression injects failure before creating the receipt file, so it misses this branch.

   Preserve the validated completion through later receipt-artifact failures, while retaining the evidence failure and stopping downstream work. Cover partially written and unreadable receipt files for both accepted and rejected outcomes.

3. **P2 — Python and native classification disagree on a supported HTTP 422 error.**  
   [e01_boundary.py:259](C:/SWDev/warhammer/Warhammer_40k_UI_unreal/scripts/migration/e01_boundary.py:259) classifies a 422 `rule_path_unsupported` error envelope as `error`. [CoreBoundaryEvidence.cpp:587](C:/SWDev/warhammer/Warhammer_40k_UI_unreal/Source/WarhammerClient/Private/Migration/CoreBoundaryEvidence.cpp:587) classifies the same response as `uncommitted_invalid`.

   This is a real selected-Core response shape: `Warhammer_40k_AI@5f509724…:src/warhammer40k_core/adapters/server.py:759` emits precisely that HTTP 422 envelope. A capture indexed using the Python classification would disagree with native consumption. Align the classifiers and add the unsupported error-envelope variant to their parity tests.

These findings follow from static control-flow inspection; I did not execute fault reproductions.

**Inputs and verification**

I read the permitted AGENTS files, clean normative extract and manifest, both migration scripts, both maintained migration test files, all `Source/WarhammerClient` code and relevant targets/configuration/descriptor, fixture inventories and schemas, public wire data, selected raw unit evidence, and relevant selected-Core contract/server sections. I did not semantically read excluded plans, journals, author notes, prior reports or audits. No context contamination was encountered.

Personally performed read-only checks:

- Verified 127 source inventory records against checkout hashes and Git blob identities, 122 copied contract files, and all 234 normalized canonical contract hashes.
- Confirmed 98 unique canonical cases: 73 finite, one nested and 24 parameterized.
- Verified all 30 indexed public wire bodies and the 31-file wire corpus. Inspected role metadata, error shapes and existing receipt consistency; a credential-pattern scan found no matching credential patterns. This does not replace independent privacy approval.
- Parsed both PowerShell files successfully with zero parser errors.
- Attempted Python AST parsing only; launching the selected interpreter was denied with **Access is denied**. No escalation or replacement interpreter was used.
- Raw `git diff --check` reported 632 CRLF-related trailing-whitespace diagnostics in the immutable copied `contracts/openapi.yaml`. A CRLF-aware check passed. Those fixture bytes match the frozen source.
- Inspected the native test enumeration and guards, request deadlines, retained envelopes, process ownership, runtime/bytecode guards, fresh-Capture wire binding, `-ABSLOG`, `-nowrite`, Config membership checks, UBT settings checks and DDC arguments. Their current runtime behavior remains unexecuted.

Prior evidence inspected, rather than personally run:

- Original Python stderr reports **65 tests, OK**, in `5.440s`; selected invocation reports exit 0. Original stdout is empty. Raw hashes and before/after source identities match the current candidate.
- Guard evidence reports **19/19 PASS**, explicitly **SIMULATED**. Its 37 before/after source bindings match.
- No current full Core/Native chain exists. The native source is structured for 132 cases; this review does not establish 132 executed successes.

**Session and evidence limits**

Observed thread ID: `01a14791-e087-7922-9ed9-06e7a3729db8`. The supplied invocation records a new `codex exec`, CLI `0.162.0-alpha.17.2`, strict configuration, read-only sandbox, approval policy `never`, disabled memories/apps/multi-agent, and no resume/fork. Runtime instructions expose read-only/approval-never permissions; the interpreter-launch denial is an observed restriction. Exact deployed model identity, reasoning settings, and low-level memory suppression were not independently exposed or attested. No auth, configuration or memory stores were read.

This verdict concerns code quality of this exact source candidate. It supplies no requirements acceptance, permission to bypass remediation reviews, current Capture/Native success, privacy promotion approval, full E01 acceptance, production responsiveness, Unreal transport/render/package proof, Linux execution, or low-level memory guarantees. The original 30-second FAIL/UNKNOWN and historical SLOW120 results remain unchanged.