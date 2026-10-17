**CHANGES_REQUESTED — independent CODE REVIEW**

Reviewed the complete implementation delta from base `0467ee63fe6d4c775f429afae2233d7292787c31` to frozen HEAD `8955112131c8be4c26499325bddbe1d24eaf0260`. I did not author or modify the candidate, delegate, launch reviewers, or perform publication actions.

1. **P1 — A timed-out command does not stop dependent submissions on the uncertain session.**  
   [e01_boundary.py:1119](/C:/SWDev/warhammer/Warhammer_40k_UI_unreal/scripts/migration/e01_boundary.py:1119) catches transport exceptions and continues to subsequent groups. The group sequence at line 1167 reuses the same `Pair` and session.

   For example, if the finite submission at [line 853](/C:/SWDev/warhammer/Warhammer_40k_UI_unreal/scripts/migration/e01_boundary.py:853) commits but its response times out, the movement group can observe matching refreshed state and issue further commands with new IDs. There is no explicit reconciliation of the uncertain command or invalidation of that lane. That finite submission also lacks the pre-submission envelope snapshot used by movement attempts; `Pair.trace` records the request only after both transports return.

   Preserve the complete uncertain envelope and scope, record UNKNOWN explicitly, and stop dependent mutations until same-envelope reconciliation or abandonment of that session. The timeout test at line 443 supplies only one group, so it cannot detect subsequent session reuse.

2. **P2 — The total request deadline does not bound response-header processing.**  
   [e01_boundary.py:362](/C:/SWDev/warhammer/Warhammer_40k_UI_unreal/scripts/migration/e01_boundary.py:362) sets the socket timeout once before `getresponse()`. Header processing can perform multiple blocking reads without recalculating the remaining deadline. A responder delivering headers gradually—or repeated informational responses—can keep each read within that timeout while exceeding the 120-second request budget. The same issue affects the 30-second readiness request.

   CPython 3.14.5’s header/status loops substantiate this path. [CPython source](https://raw.githubusercontent.com/python/cpython/v3.14.5/Lib/http/client.py)

   The deadline needs enforcement throughout header processing. Existing tests preconstruct the response before the timed request and therefore do not exercise slow headers. Add coverage using a short budget, including UNKNOWN handling for a possibly submitted mutation.

**Candidate identity and drift**

All 176 manifest-listed files/instruction files matched initially. Final verification found **zero mismatches among the 171 source, configuration, target, descriptor and fixture records**; HEAD remained unchanged.

During review, `AGENTS.md` and the mixed migration plan changed. Their final hashes were respectively:

- `57787AE6473A24F35214AC0A2C41DB394E08B1846CA6900DF6A87BBA1B0FE0C8`
- `564C1FEFF285BD14B4246630E87DDFEAC92744D17392707B0BE686FFC93E7AB9`

I did not read their changed contents. This verdict applies to the frozen code and supplied normative extracts, not those later documentation changes.

Relevant SHA256 identities:

| Input | SHA256 |
|---|---|
| Review input manifest | `817D40F480413FFCCC64A6F4812C96E019F07FD520D43B16E638EDA6A26282A1` |
| Normative criteria | `C22CB84DA41490C0B2F10022487CEAA311A60866D027DBDB3E22718F39F2E1E3` |
| Python harness | `0384ABC244B1A40D55043D830AABC334FD32D0457FA7810E2D1A0901D552BC2F` |
| PowerShell coordinator | `095EBF4359665E05AFCFD864EB33E2D6FA9CB7FD9CFD19BE5AFCC78DB92AAB52` |
| Native reader | `217D3EF245AA610EE99FA9E87223F8A9FA844AE1C99DA996633D41D28E82DBF8` |
| Native tests | `C24760C683960CA99376454DD42E3AC657C3A37B79C1BC7B466B622B5B602665` |
| Python tests | `316FF378B54566B3052EAD3AA13AA660CD1ADBF542CEF0A9CDF670F03EDD6CFF` |
| Source fixture manifest | `BF861B2EC555C81E85A31E4B37E756C5E6B04D343522A95F3235700C2AEC43F2` |
| Public wire index | `E1658B116E6ED53F84CEE84B3D8A5C1ADFD3DED3FA225DB61D80D21D9953DF0A` |

**Inputs and verification**

Read the four supplied review inputs, necessary AGENTS files, both migration scripts, Python/native tests, native reader, application callers/configuration/targets/descriptor, fixture inventory, relevant public schemas/examples, all 30 public wire bodies, and relevant Core contract sections. No prohibited review reports, working notes, private projections, privileged bodies, host logs or mutable supplement outputs were inspected. No context contamination was observed.

Personally performed:

- Manifest/hash verification, including original Capture/report hashes matching `137CEAAA…3E699` and `C9910976…530A0`.
- Verification of 127 source byte hashes/Git blob identities, 122 copied contract members and 234 normalized contract hashes.
- Verification of 98 unique canonical cases: 73 finite, one nested, 24 parameterized.
- Parsing, hash/identity checks and credential-pattern scanning of the 30 public wire bodies.
- Comparison of the five reported model translations against public before/after fixtures.
- PowerShell syntax parsing: zero errors.
- CRLF-aware delta whitespace check: PASS. The ordinary check reported 632 CRLF-related warnings in the immutable original-byte `openapi.yaml`.

Python AST parsing was **not completed**: the sandbox denied launching the selected interpreter. No harness, host, installation, build or Unreal automation was run.

The inspected selected results report **40 Python tests and 14 boundary cases passing**, 93 validated examples, and maximum latencies approximately 37 seconds. Public fixtures corroborate accepted finite submission, distinct 422 branches, revisions 19→20→21 and meaningful movement. These are inspected prior results, not tests I reran.

The linked Native/Audit branch statically avoids Capture/host/game-command relaunch. Native count validation requires 132 distinct successful paths, rejecting duplicate successes. Authored Config membership/hash and UBT XML guards are present. Actual DDC selection, `-nowrite` preservation and the six additional global-setting observations remain unverified here; I did not inspect the concurrent supplement.

**Isolation and limits**

Session ID exposed through `CODEX_THREAD_ID`: `01a1475c-2876-78b0-b114-f7a39f291ad1`. Observable CLI: `codex-cli 0.162.0-alpha.17.2`; PowerShell: `7.6.5`.

Runtime instructions specify read-only filesystem permissions, approval policy `never` and restricted network; `CODEX_SANDBOX_NETWORK_DISABLED=1` was observed. Protected interpreter execution and standard-library reads were denied. No escalation was requested.

The requested strict-config, no-memory and apps-disabled flags were supplied in the task provenance; their complete effective configuration was not independently inspected. Runtime model/settings and independently attested memory suppression remain **UNVERIFIED**.

This code verdict does not establish requirements acceptance, full E01, production responsiveness, UE transport/scheduling, rendering, packaging, Linux, durable recovery or production authorization isolation. RISK19 remains an explicit native-reader limitation.