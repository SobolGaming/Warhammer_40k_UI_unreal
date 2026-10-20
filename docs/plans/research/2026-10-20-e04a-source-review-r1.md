**BLOCKED — E04-A1E SOURCE approval is not established.**

The actual permission, manifest, policies and runtime freeze match the supplied bindings:

- **Head:** `c6a9410a524649147f157c3c17a2b838c7e0fc81`
- **Base:** `03d28af606fc6c57d20915f746296b0d843211c6`
- **Run:** `20261020T010406Z-a7dec142`
- **Manifest SHA256:** `cbc9d8df4c1a26267172dc4bdcec8819891f96a68f59116dd44d221fb3e2ddea`

Permission and freeze hashes also match the ROOT ACTUAL GO. All 47 BODY files matched their granted hashes and sizes. Commit correspondence relies on the manifest/launcher binding; I performed no Git operation. The adopted runtime freeze retains `explicitRootGo=false`.

Material blockers:

1. **Plugin/target discovery cannot be independently approved from the admitted inputs.**  
   `Check-StagedPluginClosure` explicitly makes closure completeness an independent SOURCE prerequisite, while `Check-Authority` requires `pluginClosureReviewed=true`. The supplied closure provides identities, names, catalogs and receipt policy, but no `sourceBindings` field. The 11 reading artifacts contain no primary implementation of plugin selection, target-receipt serialization/consumption or `UE-CmdLineArgs` insertion. Consequently, checking metadata consistency cannot establish that the listed discovery routes and enabled-plugin closure are complete.  
   **Required amendment:** grant clean, frozen excerpts covering those installed UE/UBT implementations and relevant descriptor selection fields. See [wrapper lines 1133–1139 and 1251–1381](C:/SWDev/warhammer/Warhammer_40k_UI_unreal/scripts/migration/Invoke-E04AProfileProof.ps1:1133). The packet requires frozen, reviewed target/plugin inputs before execution: [selected packet, lines 151–155](C:/SWDev/warhammer/Warhammer_40k_UI_unreal/.local/planning/E04/source-refresh-runs/c6a9410-20261020T005808Z-0e2b7512/norms-a1e-packet.selected.txt:151).

2. **The response/forced-include audit has an unresolved path-contract dependency.**  
   `Response-Chain` and `Forced-DefinitionHeaders` require absolute paths inside the staged project. The supplied UE excerpts show path normalization and explicitly support relative response-file paths. They omit `NormalizeCommandLinePath`, the effective root-path configuration, shared-response placement, PCH selection and generated-definition placement. I therefore cannot determine whether this exact target’s valid compiler output satisfies the audit or is rejected before its measurements can be accepted. This is an unresolved interface risk, not a demonstrated build failure.  
   **Required amendment:** supply those primary implementations/configuration seams, including the shared-response and definition-generation ranges referenced by the wrapper itself. See [wrapper lines 1477–1535](C:/SWDev/warhammer/Warhammer_40k_UI_unreal/scripts/migration/Invoke-E04AProfileProof.ps1:1477), and [UE excerpt lines 148–201 and 342–366](C:/SWDev/warhammer/Warhammer_40k_UI_unreal/.local/planning/E04/source-refresh-runs/c6a9410-20261020T005808Z-0e2b7512/ue-editor-target-response.primary.txt:148), corresponding to `VCToolChain.cs` 258–310 and `VCCompileAction.cs` 609–633.

3. **This assessment has a metadata-read discipline deviation.**  
   One catalog projection inadvertently emitted `selectedRanges.purpose` strings, excluded by the permitted range-field selection. I corrected subsequent projections, but this report should not be treated as a policy-clean SOURCE approval. No peer verdicts, excluded origin bodies, credentials or private sessions were read. See [metadata policy lines 117–128](C:/SWDev/warhammer/Warhammer_40k_UI_unreal/.local/reviews/E04A1-source-review/source-c6a9410-20261020T010406Z-a7dec142/metadata-selection-policy.json:117).

The admitted source supports these bounded observations:

- **Editor exceptions:** the global Editor exception setting is inherited and ORed with module settings. The probe’s local false does not disable it. Compiler guards and the proposed flag audit correctly require enabled Editor exceptions.
- **ABI/lifetime:** exported results contain Core-owned values; vendor/std objects remain private. Graph references use indices, and attachment obtains node references after array growth. Copy/move/destruction tests exercise independent nested storage after parser temporaries and source results die.
- **Failure semantics:** oversized input is refused before copying/vendor parsing. Expected refusals unwind privately into typed results; failed results publish no partial document. Unexpected allocation/other exceptions terminate at `noexcept`, consistent with the bounded packet.
- **Raw fidelity/resources:** ordered duplicate and case-distinct keys, anchor rebinding, alias targets and decoded NUL bytes are represented. All five limits use inclusive comparisons. Vendor source supports the deliberate null/property refusal and the `\N`/`\_` fidelity limitation.
- **Harness:** staging, source/plugin membership, explicit artifact copies, settings observations, E02 environment clearing, retained process handles and private-job cleanup are implemented. Their successful operation remains unproved.
- **Measurements:** eight suites, 38 distinct inputs and 45 attempts correspond across recipes, tests and wrapper expectations. The quotas have independently authored below/at/above recipes. These measurements would support the named raw-document subset, subject to resolving the blockers and obtaining actual execution evidence.

Relevant implementations inspected include `ParseDocument`, `IsWellFormedUtf8`, `ReadYamlDocument`, every `FEventGraph` callback and attachment/definition/counting method; `YamlCpp` selection, read-lock and membership routines; `FProbe`, generators and all eight `RunTest` bodies; wrapper authority/freeze, staging, settings, supervisor, artifact, response, discovery and ledger validation; and the supplied vendor parser, scanner, stream, tag and escape implementations.

**Complete BODY coverage: 47/47; no required body remains partially read.** Truncated metadata output was recovered through smaller selected reads; body chunks reached their stated EOFs.

| Grants | Complete files inspected |
|---|---|
| 01–15 | Dedicated Editor target; plugin descriptor; `YamlCpp.Build.cs`; parser/probe Build files; `E04ProfileValue.h`, `E04ProfileFormat.h`, `E04ProfileInternals.h`; parser module, event reader and probe module; `E04ProfileAbiTests.cpp`; `Invoke-E04AProfileProof.ps1`; `corpus-manifest.json`; `generated-cases.json` |
| 16–24 | `WarhammerClient.uproject`; ordinary Game/Editor targets; `WarhammerClient.Build.cs`; primary module; GameMode header/source; `DefaultEngine.ini`; `DefaultGame.ini` |
| 25–34 | Preferences `default`, `dense-debug`, `keyboard-heavy`, `command-bench`; HUD `default-hud`, `command-bench-hud`; previews `unit-datasheet`, `workbench`, `overflow-stress`, `player-units-roster` |
| 35–45 | `ue-editor-target-response.primary.txt`; `ue-ddc-inline-filesystem.primary.txt`; `ue-owned-value-probe.primary.txt`; `yaml-cpp-build.primary.txt`; `yaml-cpp-parser-events.primary.txt`; `yaml-cpp-stream-scanner.primary.txt`; `cmake-installed-options.primary.txt`; both Unreal/legacy norm extracts; owner requirements; A1E packet extract |
| 46–47 | Complete neutral NOT_RUN extract and clean Arcade `AGENTS.md` |

Complete excerpt inspection does not establish complete origin/API coverage; the missing material above remains blocked.

No files were saved or changed. No helper, implementation, build, test, engine, GUI, network operation, delegation or memory tool was invoked. All proposed A1 execution results remain **NOT_RUN**. A1G remains required before full A1/RQ11/production adoption; A2 retains 727 scenarios. Shared HUD/render/input, packaging and Linux remain unproved. This report supplies neither final CODE/REQ acceptance nor experiment execution permission.