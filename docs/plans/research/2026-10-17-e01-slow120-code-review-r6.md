**CHANGES_REQUESTED — CODE QUALITY**

Independent code review of base `0467ee63fe6d4c775f429afae2233d7292787c31` through frozen HEAD `db725a786329b01f174820dc1e94d538581db1cc`, including the manifest-listed working tree. Two actionable findings remain.

1. **P2 — Attach-worker cleanup failures can erase typed UNKNOWN and leave an incomplete process ledger.**  
   [scripts/migration/e01_boundary.py:1549](/C:/SWDev/warhammer/Warhammer_40k_UI_unreal/scripts/migration/e01_boundary.py:1549), `run_attach_worker`, lines 1536–1560.

   After the worker may have submitted its command, a wait failure raises `CompletionUnknown`. The `finally` block then calls `poll`, `terminate`, `kill` and bounded waits without preserving that primary disposition against cleanup exceptions. For example, an initial wait `OSError` followed by a termination `OSError` replaces `CompletionUnknown`; `run_case_groups` records `completionOutcome: NOT_ASSERTED`. A failure in this block also skips the final exit fields and terminal validation. A final cleanup `TimeoutExpired` can similarly escape before UNKNOWN is established.

   Preserve the submission disposition independently of cleanup success, record cleanup errors and unconfirmed exit explicitly, and finalize the process ledger unconditionally. Existing tests at lines 1855–1889 cover successful cleanup following timeout/wait failure; add controls where termination, killing or cleanup waits also fail, asserting retained UNKNOWN and zero dependent submissions.

2. **P2 — Session creation does not bind the returned ruleset descriptor hash to the retained request.**  
   [scripts/migration/e01_boundary.py:842](/C:/SWDev/warhammer/Warhammer_40k_UI_unreal/scripts/migration/e01_boundary.py:842), `create_session_attempt`.

   A schema-valid HTTP 201 response can retain the expected game/build/contract, ruleset ID, overlays and administrator scope while returning a different valid `ruleset_descriptor_hash`. This guard accepts it and the supervisor proceeds to `start_session`. The schema checks the hash’s shape, not equality with the submitted descriptor.

   Compare the returned hash with the retained request’s `config.ruleset_descriptor.descriptor_hash`. Selected Core `5f509724…:src/warhammer40k_core/adapters/session_protocol.py:332` directly establishes this relationship; no derived session-ID mapping or new Core API is needed. Add matching negative controls for HTTP-only and paired creation, retaining the existing positive opaque-session-ID control. The mutation matrix at `tests/migration/test_e01_boundary.py:1387` currently omits descriptor-hash mismatch.

**Candidate and drift**

Input manifest SHA256: `2A8FF2C9B555A5D39F1AE2BC29367AA3AAF6FB9BA89BFFCE6B025189858864C6`.

All **174 manifest-listed files matched before and after review**. HEAD remained frozen and Git status remained clean. There was no executable, fixture or documented-status overlay drift.

Relevant SHA256 identities:

| File | SHA256 |
|---|---|
| `scripts/migration/e01_boundary.py` | `F0590617E9E30B551B9F7DE58F1B5C22031A0A87ECABB31AFEF8B4A7A27C7B77` |
| `scripts/migration/Invoke-E01BoundaryProof.ps1` | `E5FB8305E22398EACC7DFA263373E6C480D7152B0B47DABC7CFDFEE18D7EA86E` |
| `tests/migration/test_e01_boundary.py` | `E778B29607B5FC05492D08A5A629E2D6B38D6F20A88B6190ABFA1C387B325EAF` |
| `CoreBoundaryEvidence.cpp` | `1BED4803BA70DE5A9A2231D67FE3A4A4E088BCF26EC4C7745F7AEB1C523783CA` |
| `CoreBoundaryEvidenceTests.cpp` | `813A959FC0190F668AF34789AD3B667B563554FFB0C9CA0858FB6FD7B9E9E40D` |
| Fixture `manifest.json` | `BF861B2EC555C81E85A31E4B37E756C5E6B04D343522A95F3235700C2AEC43F2` |
| Public `wire/index.json` | `E1658B116E6ED53F84CEE84B3D8A5C1ADFD3DED3FA225DB61D80D21D9953DF0A` |

Dependencies assessed: Core `5f509724da25a2f6ded0c2739a8e7c84bdf59c91`, Contract `44.3.33`, runtime identity ending `65fc8414407ae5d6a8ea779c8e737a22733459094db679a160c60f6e2129f96a`, 3,116 resources; legacy baseline `5088c1c49dcaff29eb59fb64b3063d30214dde73`.

**Inputs and personally performed checks**

Read the owner brief, necessary workspace/Unreal/Arcade AGENTS, clean manifest and normative extract, both migration scripts, both Python/PowerShell test files, native reader/tests, module callers, targets, descriptor/configuration, source inventory, immutable fixture inputs and public wire corpus. Inspected relevant pinned Core contract and session-creation implementation.

Performed only read-only inspection, hashing, JSON parsing, Git checks and PowerShell AST parsing:

- All 127 source-inventory members and 122 copied contract members matched their recorded byte hashes.
- Confirmed 98 unique canonical cases and all 30 indexed public wire body hashes.
- Both PowerShell files parsed without AST errors.
- Public wire credential-pattern scan found no matches; this is not independent privacy approval.
- `git diff --check` reported 632 CR-at-EOL whitespace diagnostics in the byte-preserved `contracts/openapi.yaml`. Excluding that immutable file, it passed.
- Attempted Python AST-only parsing; launching the selected interpreter was denied with “Access is denied.” Python parsing was therefore **NOT RUN**. No escalation was attempted.

No tests, Core processes, preparation/install, build, Unreal automation or generators were executed.

**Prior execution evidence inspected**

Read `unit-invocation.selected.json`, original stderr, empty original stdout, `guard-unit-result.selected.json` and original guard log. Verified their supplied raw hashes and original invocation/guard-result/log hashes without reading excluded author metadata.

The supplied execution reports **83 Python tests passing** and **19/19 simulated PowerShell guard checks passing**. Their source bindings match this candidate; all 37 guard input bindings still match. These are inspected prior executions, not checks I ran.

The source enumerates an intended 132-case native suite and enforces positive, unique successful exported results. No current native build or executed case count is established. The current full Preflight → PrepareRuntime/reuse → fresh Capture → Native → Audit chain remains **NOT RUN**. Historical Capture linkage cannot prove these changed Python/test bytes.

**Role, isolation and limits**

I did not author or edit the candidate, delegate, launch another reviewer, send external messages or merge.

The supplied invocation records new `codex exec`, no resume/fork, CLI `0.162.0-alpha.17.2`, start `2026-10-17T02:32:07.2725039Z`, supervisor PID `23084`, retained normal configuration, strict configuration, read-only sandbox, approval `never`, both memory settings false, and apps/multi-agent disabled. Runtime instructions independently specify read-only filesystem permissions and approval `never`; reads succeeded and the interpreter launch was denied.

Exact model identifier, CLI session UUID, accepted feature configuration and runtime memory metadata were not exposed by the authorized inputs and remain **UNVERIFIED**. The system identifies the agent as Codex based on GPT-6. Invocation settings do not independently attest every low-level memory injection path.

No excluded reviewer reports, author chats/notes, mixed planning histories, private projections, privileged wire, host logs, generated credential bodies or credential/config/memory stores were read. Necessary AGENTS contained historical status statements; these were treated as history, never current execution proof. No peer-verdict contamination was encountered.

This verdict covers code quality of this exact candidate. Requirements acceptance, independent privacy promotion, final publication/merge, full E01, the original 30-second FAIL/UNKNOWN, production responsiveness, UE transport/rendering/packaging, Linux execution and low-level memory internals remain outside this approval.