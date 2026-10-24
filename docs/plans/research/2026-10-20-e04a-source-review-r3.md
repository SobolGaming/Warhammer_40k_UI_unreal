**BLOCKED — required review coverage is incomplete. No SOURCE approval is issued.**

Candidate: `745517014f1efbc7625ff88592543200337424b2`  
Comparison base: `03d28af606fc6c57d20915f746296b0d843211c6`  
Planned run: `20261020T020719Z-20adc2c5`

The manifest, runtime-freeze and launch-permission hashes match the actual ROOT GO. The bound policies identify the same candidate/run. All 93 input descriptors matched local hashes and sizes; all 78 BODY descriptors matched their coverage-plan ranges and file lengths. Canonical and legacy copies matched their designated original hashes. HEAD/base were accepted from ROOT; Git cleanliness was not independently verified.

The freeze’s `explicitRootGo=false` remains false. The separate ROOT GO authorized this review only.

**Material source finding**

- **F01 — DDC graph-switch detection is incomplete.** [Invoke-E04AProfileProof.ps1](C:/SWDev/warhammer/Warhammer_40k_UI_unreal/.local/planning/E04/source-refresh-runs/7455170-20261020T020719Z-20adc2c5/bodies/canonical/scripts/migration/Invoke-E04AProfileProof.ps1:1558), lines 1558–1560, accepts an owned-path mention and rejects selected fallback phrases. The installed implementation adds a CVar graph candidate even when default graphs are suppressed, and reports switching with “Failed to create graph…” followed by “Attempting to create graph…”. Those messages do not match the rejection pattern. See [ue-ddc-inline-filesystem.primary.txt](C:/SWDev/warhammer/Warhammer_40k_UI_unreal/.local/planning/E04/source-refresh-runs/3791b43-20261020T013901Z-4761d5fc/ue-ddc-inline-filesystem.primary.txt:188), physical lines 188–225, preserving `DerivedDataBackends.cpp:704–740`. The proposed check therefore does not establish that the owned filesystem graph remained active. Require an owned **writable active-store** observation and reject the installed graph-switch diagnostic. This affects the owned-DDC requirement in [norms-a1e-packet.selected.txt](C:/SWDev/warhammer/Warhammer_40k_UI_unreal/.local/planning/E04/source-refresh-runs/7455170-20261020T020719Z-20adc2c5/norms-a1e-packet.selected.txt:161), physical lines 161–166 / original packet lines 169–174. No actual fallback execution is claimed.

**Actual inspection scope**

I completely inspected these coverage-plan BODY IDs, from line 1 through their declared EOF:

- `SOURCE-BODY-001–039`
- `SOURCE-BODY-041–045`
- `SOURCE-BODY-047–048`
- `SOURCE-BODY-073–078`

That is **52 of 78 required BODY files**. It includes the complete authored implementation, callers/tests, harness, fixture manifests, ten legacy inputs, clean requirements/instructions, Editor exception inheritance, DDC implementation and all four response/PCH extracts.

The remaining **26 BODY files were not substantively inspected**: `040`, `046`, and `049–072`. Consequently, scanner/resource behavior, startup ordering, complete plugin discovery/selection/dependencies, and receipt serialization/consumption are not fully assessed.

All **902 descriptor rows** were mechanically compared against their indexed originals for selected literal values and presence/absence, with no discrepancies. This does **not** complete the required semantic relationship assessment. Other selected metadata and source-binding relationships also remain incompletely inspected. Hashes and parsed/read counts are not substituted for review.

Within the inspected implementation, the UE-owned boundary, private vendor use, typed refusals, five inclusive quotas and eight-suite/38-ID/45-attempt design are coherent. This is a limited observation, not SOURCE_PASS.

No files were saved or modified; no implementation was loaded or executed, and no build, test, engine, GUI, network, Git or delegated work occurred. Actual session/model and memory-disable invocation properties were not independently established.

All A1 phases remain **NOT_RUN**. A1G remains required; A2’s 727 scenarios, shared HUD/render/input, packaging and Linux remain unestablished. A complete assessment—and remediation/refreeze of affected findings—is still required. This report grants neither final acceptance nor experiment execution permission.