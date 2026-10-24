# E04 A1G: repaired-source prerequisites admitted

Date: 2026-10-23. This note records the closed SOURCE review and subsequent pure metadata controls for source head `c329a3a32dca48272e29bad46af616bcc6bdebd4`, run `20261023T154418Z-ce672e5f`, session `01a16970-203f-7dd3-aa44-f87db6763ff6`. It records prerequisites for a fresh native proof, not A1G acceptance. The separate [execution closure](2026-10-23-e04a-game-execution-closure.md) records the later nine-phase result; no native result is inferred from these prerequisites.

## SOURCE result and root admission

The actual SOURCE review closed successfully, with a PASS verdict and no actionable findings. Root observed closure in tool chunk `294ad9` at `2026-10-23T15:57:36Z`. The strict sealing and independent rehash pipeline (`73ec96`) and metadata inspection (`a163fe`) preceded the first root report/tool-value BODY read (`162c27`). The retained seal describes 12 raw items, eight selected items including four actual extraction consoles, 852 unique frozen/control identities and 1,021 descriptor occurrences.

Root audited all 52 actual review inputs: `f02f41` covered ordinals 1–18, `e41a0a` covered 19–36, and `5a440d` covered 37–52. No unauthorized conduct was observed in those retained calls. Complete-ledger output ordinals 4, 6, 8 and 86 were clipped; this qualification remains attached to the audit and does not imply recovery of unrecorded bytes. Call 8 used name-status metadata for its Git comparison and separately read granted source bodies; call 48 read a scoped source BODY diff. The Git metadata comparison and source BODY reads are distinct kinds of access.

The raw Git-blob comparison in call 27 initially identified 14 CRLF differences. Call 35 resolved them through raw/LF comparison: all 36 required tracked files matched. This was a line-ending identity check, not a source change or behavioral test.

Root admitted this exact SOURCE subject in tool chunk `1e5e07`, separately from controls and any phase GO. The exact comparison-base and freeze joins remain in that retained admission; this note does not substitute a new base or freeze.

| Retained record | Bytes | SHA-256 |
| --- | ---: | --- |
| Original SOURCE report | 2,637 | `C27754D3723981DDC1BE8D4E999CC3595CC1765974EADB438B5C031232D26E31` |
| Root SOURCE admission | 6,261 | `0B1DB81F13D1F1B7918A362C521EDD44B29E14D62F9082285F41871627E404D7` |
| Actual post-admission controls receipt | 2,085 | `51ED1BA2D5DA56BDF129EE789BBB3D5D1CA61DA6C7CF89E5EF3BEA291496A7E7` |

The [public encoded SOURCE report](2026-10-23-e04a-game-source-review-c329a3a.json) preserves the original report bytes with UTF-8 Base64. The original-report identity above refers to the decoded original, not the JSON wrapper. Private admission, extraction, session and nested descriptor paths remain opaque identity references; mentioning them grants no BODY access.

## Actual runtime and audit qualifications

The observed review used one context and one turn, a read-only sandbox, approval policy `never`, and memory disabled. The configured default `gpt-6.1-sol` with `ultra` reasoning was observed; it was not overridden for this review. Lower-level memory/feature enforcement remains UNVERIFIED.

Retained stderr contained four icon warnings, one unsupported PowerShell snapshot warning and one sampling-stream retry within the same context. The retry was not a resumed CLI review and did not establish an additional context or turn. These warnings and the clipped-output qualifications remain part of the actual conduct record; PASS does not erase them.

## Post-admission pure metadata controls

After SOURCE admission, root executed the 14 pure trace/SDK metadata regression controls. Actual tool chunk `9db5e6` recorded PASS, with the separate receipt identified above. These controls exercise the finite trace/SDK metadata policy. They do not force or prove the repaired window-owner query-failure branch. Source inspection and these controls therefore provide no claim that the zero-return observer branch has been exercised at runtime.

SOURCE admission, actual controls execution and phase authorization remain separate records. Neither this note nor the public report authorizes a phase, grants access to opaque recovery `.uba` bodies, or supplies a native result. Any eventual final CODE/REQ review must use actual closed execution evidence and its own admitted controls.

## Scope carried forward

The earlier missing-vendor-header BODY-grant closure, the `b049c02` SOURCE failure for a window-owner query false pass, and the earlier `a898057` Cook trace failure remain historical evidence. The repaired-source PASS does not rewrite those attempts or reopen the resolved packet coverage gap. The normative proof requirements are unchanged.

Bounded A1E acceptance remains unchanged; OWN17 remains deferred and unproven; visible authority remains zero; Linux remains UNTESTED; and A2 remains deferred. Standing private source/API review consent remains in force. The later native proof has its own execution closure and still requires final CODE/different REQ; no migration acceptance follows from these SOURCE prerequisites alone.
