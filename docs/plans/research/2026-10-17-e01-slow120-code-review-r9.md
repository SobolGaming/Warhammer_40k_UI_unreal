**CHANGES_REQUESTED** for the affected source code quality gate. Two actionable findings remain.

1. **P2 — Specific observation failures are discarded.** [Invoke-E01BoundaryProof.ps1:897](C:/SWDev/warhammer/Warhammer_40k_UI_unreal/scripts/migration/Invoke-E01BoundaryProof.ps1:897) replaces access, I/O, security, reparse, directory and hashing errors with the same generic diagnostic. [Line 934](C:/SWDev/warhammer/Warhammer_40k_UI_unreal/scripts/migration/Invoke-E01BoundaryProof.ps1:934) similarly discards the actual after-observation/provider/assertion error. The phase fails conservatively and preserves its primary failure, but the required exact secondary evidence is lost. The supplied provider-failure result confirms that `SIMULATED_METADATA_PROVIDER_FAILURE` is absent from the retained record. Preserve credential-safe error type, stage and details separately from the primary failure. Extend [the regression checks:313](C:/SWDev/warhammer/Warhammer_40k_UI_unreal/tests/migration/Test-E01CaptureWireBinding.ps1:313) and line 341 to verify those details; currently they check classification, counts and field presence.

2. **P2 — Process cleanup can replace the primary Native failure.** In the adjacent, **pre-existing** caller [Invoke-E01BoundaryProof.ps1:281](C:/SWDev/warhammer/Warhammer_40k_UI_unreal/scripts/migration/Invoke-E01BoundaryProof.ps1:281), `Stop-OwnedProcess` executes before the original exception is rethrown. If termination or its bounded wait throws after a Native timeout/read failure, the outer handler records that cleanup exception as `failure`; the original exception never reaches the new observation recorder. Capture the primary error before cleanup, retain cleanup errors separately, and ensure finalization continues. The maintained tests exercise the recorder directly and provide no control for this caller failure.

The frozen candidate reviewed was:

- Base: `c2614b2484a66bd8465b855e59b184d49b2b926d`
- HEAD: `d910672a568ab0223328d75bda6790fd5a0cce9b`
- Wrapper SHA256: `5D0C3D98A47E75796BF44DCA3F8C46140FD79E66A15F538D3A63D1B38DE9DB11`
- Guard-test SHA256: `755DBE7EA8F4512DCFDED8B33C34E16FDEEA3B873115E7D408A0AD0444B49893`
- Input-manifest SHA256: `E5CD706F199EB2A861C6CC23E6F49DE5563295E0F021982A83516C18E38D4470`

I personally verified clean Git status, base ancestry, all 174 manifest file hashes, both instruction hashes, both normative-source hashes, affected-diff whitespace and static PowerShell parsing. Both scripts parsed without errors under PowerShell 7.6.5. One search reported the absent `.github` directory; the search over existing `scripts` and `tests` completed afterward. No drift or prohibited-input contamination was encountered.

Static inspection supports six distinct roles, preservation of coincident Documents observations, strict membership/path/existence/hash comparison, and rejection of unavailable observations. The Native integration retains the authored Config/UBT guards, exact 132-success Automation gate, and normal same-run Capture binding before and after execution. The delta adds no historical-Capture bypass.

I inspected supplied execution evidence without rerunning it: **68/68 guard checks passed**, with 38 unique before/after bindings matching current bytes. Process PID `36876` ran from `2026-10-17T03:45:55.3260546Z` to `03:46:35.4528610Z`, exited `0`, and did not time out against its 45-second limit. Stdout ends with `Guard checks: 68/68 PASS`; stderr is empty. Original invocation/result/log hashes match their selected provenance, and all 11 selected result fields match the original result. These are guard results, not current Core/build/Automation acceptance.

Isolation evidence was read from both packet files. Invocation records fresh `codex exec`, no resume/fork, strict configuration, requested memory suppression, and requested apps/multi-agent disablement. Selected runtime metadata reports:

- Session `01a147fb-c63b-7ca0-aa71-709e80658e82`; turn `01a147fb-cad0-7951-8e41-5ef593162194`
- CLI `0.162.0-alpha.17.2`; model `gpt-6.1-sol`; effort `ultra`
- Managed **read-only**, approval **never**, restricted network, and `memory_mode: disabled`

Lower-level memory-path absence and feature disablement are not independently established by that selection. I used no apps, delegation, escalation or underlying rollout access, and made no edits.

After remediation, re-freeze and obtain fresh affected reviews before the required new full normal chain. This report establishes no new runtime result, requirements acceptance, privacy approval, publication/merge approval, full E01, production responsiveness, UE transport/render/package proof or Linux result. The historical missing six-setting observations remain **UNVERIFIED**.