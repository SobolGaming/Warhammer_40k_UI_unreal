# P1c Core 44.5 adoption: bounded native results

The selected Core is `4f9bef0df2fb974d1285232a1009b8781926361d` /44.5.0 /build `warhammer40k-core-v2:runtime-tree-sha256-v1:0443ce4bc405aad1737ec9a396948775010df933bd75144f6ab9ff54152118ba`, 3130 resources. It came from `codex/static-successor48`, open/unmerged [Core PR #591](https://github.com/SobolGaming/Warhammer_40k_AI/pull/591), after a safe fetch. The reference checkout remains clean at5f509 /44.3.33. This is an explicit development-source adoption.

Implementation is `cc494c3ca5a9b4c98acddf189bf497c5eb3af1fc`. Launcher/preparation repair is `de95717262d4db5d37b308a940cc2df802cf40d4`; Source/Config/Content/project inputs are identical between them. Exact runtime input is 223996 bytes, SHA256 `17a4491eec3ab0fd099acb17b2bd9f9b50e7bcdba901ab7d85f93fb3bf463a8a`, copied from selected committed Core bytes and staged separately from tests. [Machine-readable results](2026-10-24-p1c-core-adoption.json) retain hashes of private raw results, exact candidates and limits.

## Native and lifecycle results

| Check | Actual result |
|---|---|
| Separate source/runtime preparation | PASS. Independent no-hardlink clone, literal Git bytes, frozen/hash-checked lock dependencies, installed exact build/resources and current development provenance. Reference HEAD/status unchanged. |
| Windows Game/Editor build, cook/stage/archive | PASS,64.50 seconds,65 accounted processes, empty owned job, no forced cleanup. No game/installer launch during packaging. |
| Complete initial copy outside UI checkout | All50 files /975,380,089 bytes match exact membership/hashes. Later runtime Saved files are separate. |
| Focused native Unit suite |12/12 PASS, zero per-test errors/warnings,15.98 seconds, empty owned job. Includes optional roster availability/disclosure, physical bearer IDs/index, atomic malformed-field rejection, viewer scope and presentation invalidation. |
| Packaged resource/data checks |4/4 PASS, including selected input and missing/corrupt data. |
| Packaged real-Core Managed workflow |1/1 PASS: public create/start → one offered secondary-mission submission → accepted/committed revision advance → explicit authoritative refresh. Owned host STOPPED normally. |
| Packaged real-Core Attach workflow |1/1 PASS, same real workflow. External host still authenticated HTTP200 after client exit, then its separate owner stopped it normally. |
| Preserved44.3 profile | Hidden exact old runtime reached READY with3116 resources and STOPPED normally; old preview SHA256 unchanged. No old Game window launched. |

These are18 native test executions /17 distinct names across four native launches. Packaged checks exited 0 with four Config files, binary and caller environment unchanged, no forced termination or cleanup errors. Each packaged non-visible log retains two startup warnings and one missing HTML-report-template Error line, while structured JSON records zero errors/warnings per test; logs are not claimed clean. The nested new executable is 332,452,352 bytes, SHA256 `92925c4da9f52fecc1fe39ea9282fa8ec0a36470c544bc32e175846b62bd7b22`.

Script/component controls also passed111 cases across seven suites:21 Python launcher,15 PowerShell launcher,28 startup,32 package-path,8 profile/destination,4 real inert-process and3 miniature-Git cases. These ran against evolving implementation edits; their exact HEADs were not captured and they are not relabelled as a full de95717 rerun. Their commands/limits are retained in the JSON.

Commands used the existing `Build-ClientPackage.ps1`, fixed `Test-ClientPackage.ps1 -Mode Resources|Core` with Managed/Attach, selected preparation script with the physical installed Python3.14.5, and a bounded private Unit runner. Exact invocations/results remain private with hashes in the JSON. These tests use NullRHI/RenderOffScreen and establish no new rendered/input result.

## Failures and scope

The first interpreter alias path was rejected as a junction before preparation. An initial physical-path run failed because incidental async task return values contaminated captured stdout and falsely classified reference preservation; that failed receipt is retained, not evidence of a real reference mutation. Four real inert-process controls cover the repair. A later run verified the installed build/resources but failed source cleanliness:38 Core JSON blobs contain committed CRLF under conflicting LF attributes, producing false Git modifications despite byte equality. Failed source/runtime outputs were preserved in a checked private archive. The fresh clone now uses a clone-local literal-byte attribute policy and checks cleanliness before installation; three real miniature-Git controls passed, including actual-edit detection. No reference/Core source was repaired or reset.

Initial Python TEMP permission failures and the inert Git MSYS sandbox failure remain separate from successful controls using workspace TEMP and authorized native Git execution. A private old-profile helper Boolean typo failed before host startup; its corrected run passed. No failed attempt is relabelled PASS.

Public-roster support is a typed subset with original selection/profile/source/bearer identities and explicit undisclosed attachment/cargo fields. There is no roster rendering/editor, detailed points/options/composition or physical-instance join. Coherency/source-reposition workflow demonstrations remain for their appropriate P4 editors; no private mutation or local casualty policy was added. Full battle, joining/hotseat, remote/spectator, production hosting, clean-machine delivery and Linux execution remain open. P1b visible results remain bound to 44.3; this milestone has no new rendered test claim.

Initial independent requirements SOURCE review passed at de95717. CODE requested process-tree cleanup after parent exit and a narrow nonempty-roster serialization interface supplement. These are retained in the [source-review record](2026-10-24-p1c-source-reviews.json); repairs/fresh reviews are pending. The interface finding is an evidence blocker, not a confirmed serialization bug. Native results alone do not close review acceptance.
