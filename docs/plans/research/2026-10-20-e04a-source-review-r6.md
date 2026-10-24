**BLOCKED — incomplete SOURCE assessment. No SOURCE_PASS or experiment execution permission is established.**

Candidate bindings inspected:

```text
SourceHead: 0ed4221749657b8b8fba2cc22e461b470ce7d156
ComparisonBase: 03d28af606fc6c57d20915f746296b0d843211c6
PlannedRunId: 20261020T035315Z-1e4656b7
InputManifestSHA256: 78446e4880be0a56faf9d2f05184ae238ec9158480d0027702090ca03c82f8a1
```

The bootstrap, manifest, policies, runtime freeze and launch-permission hashes matched the supplied bindings. Selected freeze fields identify the correct head/subset and retain `explicitRootGo=false`.

**Material access gap:** the freeze’s selected `/sourceMembership` stages `Config/DefaultEditorSettings.ini`, existing WarhammerClient migration sources and three existing test translation units, without granting their BODY access. The dedicated target includes WarhammerClient ([target, line 12](/C:/SWDev/warhammer/Warhammer_40k_UI_unreal/Source/WarhammerClientE04AEditor.Target.cs:12)); its rules enable the existing automation driver when developer tools are built ([Build.cs, lines 32–38](/C:/SWDev/warhammer/Warhammer_40k_UI_unreal/Source/WarhammerClient/WarhammerClient.Build.cs:32)). The wrapper copies the frozen membership into the staged project ([wrapper, line 1653](/C:/SWDev/warhammer/Warhammer_40k_UI_unreal/scripts/migration/Invoke-E04AProfileProof.ps1:1653)).

Their registration, entry guards and configuration effects therefore remain unassessed. This is uncertainty, **not evidence that an unwanted action occurs**. Completing the requested startup/settings/Core-containment assessment requires bounded clean grants for those relevant routes, or source evidence establishing their exclusion. The packet requires freezing and reviewing actual callers and execution inputs before native work ([clean requirements, lines 149–166](/C:/SWDev/warhammer/Warhammer_40k_UI_unreal/.local/planning/E04/source-refresh-runs/0ed4221-20261020T035315Z-1e4656b7/norms-a1e-packet.selected.txt:149)).

Actual coverage:

- Completely inspected **48/81 BODY files**: IDs `001–036`, `042–045`, `073–075`, `077–081`.
- Uninspected BODY IDs: `037–041`, `046–072`, `076`.
- Verified hashes, byte lengths and line counts for all 81 BODY descriptors. Verified all 15 canonical copies and ten legacy copies against their bound originals.
- Read the access/metadata policies; inspected only part of the selected runtime-freeze fields. **The complete thirteen-record metadata assessment and 902-row selector assessment were not completed.**

Consequently, vendor behavior, plugin/default/dependency closure, receipt consumption and startup ordering remain insufficiently assessed. No implementation defect is asserted from this partial review, and its limited observations cannot support overall correctness, ABI, lifetime or failure-safety approval.

No implementation, build, test, engine, GUI, network, GitHub or delegated work occurred; no files were saved. All experiment phases remain **NOT_RUN**. A1G remains required; A2’s 727 scenarios, shared HUD/render/input, packaging and Linux remain outside established proof.