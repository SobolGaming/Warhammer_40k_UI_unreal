# P1a Windows standalone package — non-visible evidence

2026-10-24. Bounded P1a disposition: **BOUNDED CHECKS PASS WITH RECORDED DIAGNOSTICS**. Native/helper execution was at `2cad5f41c26430daaec4da982964b5b979cb9266`; the narrow closing correction/review is at `f725e75739496fe21ad9c5c2161a8d87733b21cc`. [PR #4](https://github.com/SobolGaming/Warhammer_40k_UI_unreal/pull/4) covers Windows Development packaging, runtime assets/data, packaged launch selection, lifecycle/credential controls, non-visible checks, the canonical roadmap and architecture guide. Full P1 and feature parity remain open.

The [migration plan](../unreal-migration-plan.md) is the single canonical root. The former development-plan filename is a compatibility pointer. Arcade is the owner-confirmed Python UI baseline at `5088c1c49dcaff29eb59fb64b3063d30214dde73`; selected Core is `5f509724da25a2f6ded0c2739a8e7c84bdf59c91`, contract 44.3.33. Neither sibling was edited.

## Package and retained failures

| Source | Recorded build result | Seconds |
|---|---|---:|
| `8f8c010` | FAILED before compile/cook: ambiguous Editor target without DefaultEditorTarget. | 4.1891985 |
| `9233bb6` | Package created after explicit ordinary target defaults; wrapper also returned two incidental task objects. | 199.1550355 |
| `43bb097` | Package created; repaired wrapper returned one result. | 26.1983568 |
| `71f5ced` | Package created using owned Windows Job supervision; one result, job empty, no forced termination or cleanup errors. | 25.2274696 |

The last build's OS job accounting recorded 24 total processes; this is not an attributed process list. Packaging uses bounded time/output monitoring and NullRHI/RenderOffscreen cooking, and never runs the Game or prerequisite installer. The final `2cad5f4` helper repairs change no native inputs: the Source, Config, Content and .uproject Git objects are identical to `71f5ced`. The retained package therefore supplies the native binary for the final helper checks without another rebuild.

The complete copied Windows bundle has **50 files / 975,120,505 bytes**. Exact source/destination membership, lengths and all 100 SHA256 checks matched. The nested Game executable is 332,397,568 bytes, SHA256 `9C153546F6208CED7C41F8A7AE4BE53F318A7FE7D2C427D0ED81769D7B33B8E4`. It ran outside the source checkout. This is a folder bundle with a separate Python Core dependency, not clean-machine or single-file delivery. No prerequisite installer ran.

## Final non-visible execution

| Mode | Successful tests | Native seconds | Lifecycle |
|---|---:|---:|---|
| Resources | 4 | 6.2195537 | No Core; normal exit 0. |
| Managed Core | 1 | 20.6429893 | Owned development host stopped normally; no force. |
| Attach Core | 1 | 20.6648817 | Service still HTTP200 after client exit; separate owner then stopped it normally. |

The four resource checks cover canonical input, missing input, corrupt input and startup map/GameMode/assets/font-file availability. The real-Core integration name runs in both host modes and covers create/start, viewer-scoped state, an offered secondary-mission action and authoritative refresh. Final totals are **six test executions / five distinct names / three native launches**, not an inferred assertion count. Earlier `43bb097` and `71f5ced` results each retain their own six executions; whole history is 18 executions / nine native launches / five distinct names.

Every native exit was 0, streams completed without capping, executable bytes stayed unchanged, four Config files stayed unchanged, and caller environment restoration passed. Native budgets were 120 seconds for Resources and 240 for Core; host readiness/cleanup and evidence work occur outside those process durations. Attachment does not independently establish service process identity.

All nine native logs retain **two startup warnings** (spawn without class and light mobility) and **one missing HTML-report-template error per run**. Exact JSON indexes were still generated and recorded Success with zero per-test warnings/errors. Full logs are not clean; no rendered HTML, pixels, displayed fonts/shaders or physical input are certified.

## Controls and source review

Focused controls passed: 19 Python launcher tests, 14 PowerShell launcher cases, 32 inert runner path/function-wiring cases, 28 offline Core-startup cases, 10 offline Core-stop cases and three real hidden-CLI Job cases. The 32 path controls do not execute the runner top level or create reparse points. Separately, actual runner invocations rejected an in-checkout path and an extended Windows namespace before client/Core startup. Both expected rejection results stayed FAILED/INPUTS internally and restored the environment. Inert controls create no client/Core/network traffic. The Job tests use owned hidden Python processes, including a parent that exits with live descendants; cleanup confirmed active 0. Their initial test-only output-inheritance assumption failed and was repaired before the three-case PASS.

| Frozen source and scope | CODE | Separate requirements review |
|---|---|---|
| `43bb097`, affected P1a source | CHANGES_REQUESTED | CHANGES_REQUESTED |
| `71f5ced`, affected P1a source | BLOCKED | CHANGES_REQUESTED |
| `2cad5f4`, full affected source and supplied direct interfaces | CHANGES_REQUESTED | CHANGES_REQUESTED |
| `f725e75`, focused closing endpoint-case/documentation repair | PASS | PASS |

The repairs cover endpoint validation before credential use, receipt-independent startup cleanup, owned build descendants after parent exit, restoration of caller credentials, ordinary stop cleanup despite marker/termination/persistence failures, and rejection of unsupported Windows path aliases before the external-copy check. Earlier reports remain verbatim. The `2cad5f4` CODE review identified a case-sensitive Managed-port comparison; both roles requested correction of the guide's stale shutdown budgets and found no other actionable issue in their respective affected scope. The closing change uses case-insensitive comparison consistently with dispatch, adds lowercase/mixed-case controls and documents existing 5+3-second bounds. Prior native workflows used `Managed` with matching ports, whose behavior is unchanged; the focused 28 controls cover the corrected rejection/default cases without another native run.

Finite direct Core/Windows declarations and the installed Slate default complete the supplied interface context; unchanged camera/input behavior and future unchecked Linux Game packaging work are outside this affected source scope. Closing verdicts cover the final correction and its direct dependencies, not fresh certification of all unchanged code.

The full `2cad5f4` packet contains 76 inputs / 662,167 bytes, including 39 UI Git origins, 31 finite installed-primary excerpts and five selected Core-public excerpts. Root separately verified all 80 input/control descriptors; all 39 UI Git blobs matched. Working bytes matched 31 origins directly; eight differed only by CRLF→LF checkout normalization. The machine-readable evidence separately binds the smaller closing packet. Reviewers used separate fresh read-only/approval-never/ephemeral Codex sessions with memory disabled requested; source-only verdicts received no native result evidence. No independent OS/network isolation, memory-persistence or binary/source attestation is claimed.

## Provenance and remaining limits

[Machine-readable evidence](2026-10-24-p1a-windows-package.json) preserves raw artifact digests, earlier attempts, exact test states, build/source reuse, environment/config checks and temporal receipt qualifications. READY receipt digests describe earlier bytes; the mutable files later became STOPPED. An earlier digest is not claimed to match current receipt bytes. Metadata reconciliation is author-adjacent inert checking, separate from the fresh source reviewers and root-observed runtime.

[architecture.md](../../../architecture.md) describes C++/Slate, world/GameMode lifetime, authority, runtime data, process ownership and deployment. AGENTS.md requires same-change updates when architecture changes. Its 43 local link occurrences resolve. The earlier structural check missed the sequence-diagram semicolon error. The targeted one-line correction is committed at `3ca8b21`; actual Mermaid 11.12.0 parsing under jsdom 26.1.0/Node 24.19.0 reproduced the original failure and passed both repaired blocks. [Parser evidence](2026-10-24-architecture-mermaid.json) binds the exact corrected architecture bytes and tool versions. No browser, SVG/layout rendering or GitHub renderer-version equivalence is claimed.

The screen HOLD was respected: no visible testing, focus changes or GUI automation ran. Visible packaged rendering/input, a Windows host without Unreal, native Linux, actual Core shutdown-fault injection, bundled Python, production distribution, new gameplay/profile/viewer/recovery features and full P1 remain outside this PR. The earlier manual F failure stays unresolved. This PR stops at P1a; later features need separate bounded work. Credentials, private sessions/process identities and raw report bodies are excluded from publication.
