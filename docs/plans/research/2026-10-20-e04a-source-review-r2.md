**CHANGES_REQUESTED**

Reviewed candidate `3791b43dd5966b49c5abc2926fb989aea587d941`, comparison base `03d28af606fc6c57d20915f746296b0d843211c6`, run `20261020T013901Z-4761d5fc`.

The actual ROOT GO, launch permission, input manifest, adopted policies and coverage plan are consistent. All three GO-supplied SHA256 bindings match. The runtime freeze remains `explicitRootGo:false`; adopting its identity does not authorize an experiment phase.

**Material finding — P1: required supervisor controls call an undefined function.**

[Invoke-E04AProfileProof.ps1, line 569](C:/SWDev/warhammer/Warhammer_40k_UI_unreal/.local/planning/E04/source-refresh-runs/3791b43-20261020T013901Z-4761d5fc/bodies/canonical/scripts/migration/Invoke-E04AProfileProof.ps1:569) calls `Parse-JsonLine` while validating child observations. The complete wrapper contains no definition or import providing that command.

The normal SUP01 path calls this validator at lines 713–715; SUP02 calls it again at lines 717–718. With otherwise valid control output, the first validation reaches the missing command and fails. Consequently, the required six controls cannot complete, and the successful-predecessor checks at lines 1594–1600 prevent later phases from proceeding.

This conflicts with the required SupervisorControls phase: six controls, three groups and five roots, specified in [the clean packet excerpt, lines 155–159](C:/SWDev/warhammer/Warhammer_40k_UI_unreal/.local/planning/E04/source-refresh-runs/3791b43-20261020T013901Z-4761d5fc/norms-a1e-packet.selected.txt:155), retaining original packet provenance **163–167**.

Provide self-contained, reviewed JSON-line parsing or replace the call with equivalent strict handling. Preserve the observation schema, type and duplicate-field safeguards, then refresh the candidate bindings and obtain a new SOURCE review. No fix was made.

The remaining inspected source supports the bounded design: UE-owned results with private vendor ownership, typed refusals at the `noexcept` boundary, flat indexed alias graphs, copy/move/lifetime checks, and five explicitly defined quota units. Unexpected allocation exceptions intentionally terminate rather than becoming typed refusals. The quotas constrain accepted input and graph construction; they do not establish a vendor-allocation or OS resource ceiling. See [the public contract](C:/SWDev/warhammer/Warhammer_40k_UI_unreal/.local/planning/E04/source-refresh-runs/3791b43-20261020T013901Z-4761d5fc/bodies/canonical/Plugins/E04ProfileProof/Source/E04ProfileParser/Public/E04ProfileFormat.h:26) and [boundary implementation](C:/SWDev/warhammer/Warhammer_40k_UI_unreal/.local/planning/E04/source-refresh-runs/3791b43-20261020T013901Z-4761d5fc/bodies/canonical/Plugins/E04ProfileProof/Source/E04ProfileParser/Private/E04ProfileParserModule.cpp:9).

Actual scope completed:

| Required BODY group | Completely inspected |
|---|---:|
| currentCanonical | 15 |
| reusedEntryDefault | 9 |
| pinnedLegacy | 10 |
| refreshedPrimaryNormOwner | 11 |
| pluginTargetReceiptPrimary | 27 |
| responsePchPrimary | 4 |
| neutralNotRunFields | 1 |
| cleanArcadeInstructions | 1 |
| **Total** | **78** |

All **26,413 BODY lines** were inspected, with truncation and read errors recovered. Body descriptors and canonical/original copy bindings matched. The complete clean Arcade instructions satisfied the workspace route; embedded commands and credential references remained inert.

All 13 selected metadata records were inspected through permitted field queries. This included all 902 selector rows and indexed originals, their presence/value fidelity, 1,774 module declarations, 1,561 plugin references, source/range/symbol bindings and receipt relationships. The conservative dependency closure matches the frozen 245-descriptor membership and does not reach the six disabled plugins. That membership is **not actual runtime enablement**.

Inspection also covered Editor exception inheritance, response/forced-include/root mapping, NoPCHs/NoVFS, static-library/CRT isolation, fixtures and recipes, supervision/cleanup, settings checks, plugin discovery/default/dependency routes, receipt serialization/consumption, startup ordering, command-line environment insertion and DDC configuration.

No candidate code, recipes, build, tests or engine were executed; no files were saved or changed. Head/base are adopted packet identities, without independent Git-history verification. All A1 phases remain **NOT_RUN**. Runtime ABI, lifetime, cleanup, settings preservation and measurement outcomes remain unproved. A1G remains required before full A1/RQ11/production adoption; A2 retains 727 scenarios. Shared HUD/render/input, packaging and Linux remain unestablished.

This report grants neither final acceptance nor permission to execute the experiment.