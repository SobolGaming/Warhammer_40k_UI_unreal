**CHANGES_REQUESTED — closed E04-A1G FINAL_REQ assessment.**

The retained evidence supports the finite cooked Game caller result. One required evidence-retention finding remains: Audit computes the Native DDC observation but omits its counts and directory from the retained Audit object. Administrative admission and isolation qualifications also remain unresolved within this role’s permitted visibility.

**Exact binding**

```text
Role: FINAL_REQ
FinalHead: c187d3496bb473e1cbbac3387350ba58898e3b3a
ExecutedHead: fa11be76cca922006f9bb7eb16f7240bc51925f7
ComparisonBase: 2651a8652915824fe339a958ca5afc1a835f5731
RunId: 20261021T152810Z-45e572ca

Permission SHA256:
77A9F5BE63DFBD1F4658E6EE8B938A388C3CEB92BE8007ACD71A3660A6CB3012

Own input manifest SHA256:
2416E7DB276EE6DFD3198B4BAE15904882A84740D3D4F4ECD1C080EBF2D0E671

Own final freeze SHA256:
D4E936A1B46077E5AF0058F1A1ED37CC686BA768034CEE6146125976FF00D7BD

Execution freeze SHA256:
CC4F42A2CC22E56F28FF9DA9F8B8D41A936C251ACC7F2B48875743FF30C84362
```

The actual permission file matches the separately supplied GO. All **981 final-frozen members** matched their recorded byte counts and SHA256 values.

For the references below:

- `U` means `C:\SWDev\warhammer\Warhammer_40k_UI_unreal`.
- `R` means `U\.local\experiments\E04A1G\20261021T152810Z-45e572ca`.
- `P` means the supplied `positive-facts-fa11be7-20261021T161803Z-b54f0985\closed-execution.positive-facts.json`.
- `T` means the supplied source-review `technical-inputs-v9\installed-primary-excerpts` directory.
- A pointer such as Native `/native/ddc` identifies the corresponding literal `sourcePointer` record and child value in `P`.

**Finding REQ-01 — retain the Audit-boundary DDC observation**

The norm requires zero legacy-DDC log rows and zero owned Native DDC files at **Native and Audit validation boundaries**, retaining the counts and owned directory.

Native `/native/ddc` retains:

```text
backendLogRowCount: 0
ownedFileCount: 0
ownedDirectory: R\ddc\native
ownedFiles: []
observedRows: []
```

Audit calls `Check-A1GNativeLog`, which computes those observations, at [Invoke-E04A1GProfileProof.ps1](C:/SWDev/warhammer/Warhammer_40k_UI_unreal/scripts/migration/Invoke-E04A1GProfileProof.ps1:1751). Its following return object omits `$log.ddc`. The frozen Audit `/audit` object has no DDC observation, and no separately selected Audit DDC fact was present.

Consequently:

- The **source assertion** requiring zero counts during Audit is established.
- Native’s retained zero counts and the unchanged closed-log identity are established.
- A **separately retained Audit-boundary file count and directory observation** is unresolved. Audit success alone does not replace that required primary observation.

Retain that finite observation in the Audit evidence, or supply an already frozen, explicitly granted primary Audit-boundary record containing it. This finding does **not** assert that DDC activity occurred. It requires no OWN17 certification campaign.

**Criterion-to-primary-evidence map**

| Criterion | Disposition | Source contracts and actual evidence |
|---|---|---|
| **A1G-01 — actual Game boundary** | **PASS, bounded** | Dedicated target, GameProbe Build.cs and complete caller/parser interfaces were inspected. Caller has the exact `noexcept` function-pointer assertion, `_CPPUNWIND` rejection, exception-disabled/private-marker guards, NoPCHs and no unity. Actual parser/caller response files and forced headers show C++20, `/MD`, monolithic `1`, Editor `0`, and Editor-only data `0`. Parser has `/EHsc` and `PLATFORM_EXCEPTIONS_DISABLED=0`; caller has no `/EH` option, `_HAS_EXCEPTIONS=0`, and `PLATFORM_EXCEPTIONS_DISABLED=1`. `R\logs\gamebuild.log` records fresh compilation of both parser units and the caller, followed by the executable link. The complete link response consumes their three objects and the same-run vendor library. UBT primary ranges in `T\primary-003/004/007/008.txt` support the mode interpretation. |
| **A1G-02 — selection and fresh Release dependency** | **PASS for the finite Game route; broader preservation qualification below** | The frozen fixture has exactly the scoped enabled proof reference and `{Name:"AndroidFileServer", Enabled:false}` with typed Boolean false. Plugin defaults and GameProbe selectors match the norm; the Game Rules branch rejects global exceptions, Editor compilation, nonmonolithic/nonshared selection, and E02/A1E environment routes. CMake cache, configure log, compile commands, verbose build output, configure/build/artifact receipts and module-selection receipt join to this run and pin. Thirty vendor compile commands have the required modes. The single direct archive action has the exact 30-object ordinal sequence, x64 output, selected shell and frozen librarian identity. The real Release ABI event compiles and links successfully; the ordinary later “working compiler … skipped” message does not substitute for that event. The copied library is 5,706,552 bytes, SHA256 `E8B405C68B394453597D0B91BFAAA7B347A43C6DAC29E4687E7BF144C4899EFE`; 38 header records and the exact 1,061-byte MIT notice are retained. No fresh A1E regression execution or comprehensive artifact-lineage certificate is claimed. |
| **A1G-03 — phases, bounds and preservation** | **PASS for retained technical facts; original authority chronology UNVERIFIED** | Complete wrapper and supervisor paths establish owned-path/reparse refusal, separate phase evidence versus Cook/Stage payloads, exclusive publication, deadlines, caps and failure preservation. All nine projected completions are complete, with null primary failures and empty secondary errors. All 36 predecessor descriptor joins reconcile. Canonical/staged/fixture before-and-after arrays match Preflight; all nine settings roles and the separate Game fallback role preserve their observed existence/hash values. Seven retained process roots have exit 0, confirmed cleanup and successful final job queries with active count zero. Original GO/admission bodies remain withheld. |
| **A1G-04 — Editor, Cook, loose Stage and dependencies** | **PASS, bounded** | Actual normal Editor receipt, project DLL, compile/link actions and module manifests establish the prerequisite; project and installed Editor BuildId both equal `55116800`. Both receipts omit `Plugins` overrides and contain typed BuildPlugins arrays: Editor excludes proof/AndroidFileServer; Game includes exactly `E04ProfileProof` and excludes AndroidFileServer. Cook log contains no selected proof/AndroidFileServer mount, enable or module-load observation. Actual UAT argv, resolved parameter blocks, copied Cook log, manifests and frozen membership establish real loose Cook/Stage. The 995 ordered Game runtime declarations all join to classified copies; Audit coverage equals Stage coverage. Specific settings, intent and copy qualifications are detailed below. |
| **A1G-05 — inputs, checks, lifetime and result** | **PASS, bounded** | Complete caller, parser, value/error interfaces, vendor direct headers and tests were read. Actual `R\reports\game-probe\result.json` contains exactly two ordered attempts and 52 ordered, explicitly evaluated, typed Boolean-positive checks. Exact fixture bytes, final LF, lengths and hashes independently match the norm and compiled literals. Source and checks establish synchronous input release, owned results, copied survivor and lexical destruction before publication. Callback removal, duplicate refusal, pending shutdown removal and create-new bounded publication precede terminal logging and orderly exit request. No UE assertion total or destructor instrumentation is inferred. |
| **A1G-06 — actual hidden Game, DDC and windows** | **CHANGES_REQUESTED: REQ-01** | Actual PID `30188`, Stage-mapped executable, result, argv, closed log, terminal and exit receipt reconcile. Native’s two M06 facts are separate typed true Booleans. Native retains zero legacy-DDC rows/files; Audit’s source recheck exists, but its returned DDC observation is omitted. Window evidence otherwise satisfies the qualified finite requirement: seven samples, required endpoints, four periodic samples, stable successful PID queries, zero observed visible-owned counts, and final empty owned PID set. |
| **A1G-07 — closure, correspondence and independence** | **Technical correspondence PASS; administrative/isolation enforcement UNVERIFIED** | The finite correspondence set contains 45 canonical Git bindings, 43 required whole-source entries and 36 source-copy mappings. Actual executed/final Git blob identities match all 45 declared canonical pairs. The explicitly identified `AGENTS.md` metadata overlay differs and is not claimed executed; neither mixed body was read. All 573 selected result/completion records are present. Original SOURCE verdict/admission, phase GO/admission/inspection and root sealing bodies remain opaque for post-seal checking. This report does not substitute their identities for approval. |
| **A1G-08 — OWN17 and scope** | **PASS as a limitation** | Special harness/generated-response/transitive/Rules/cache/witness certification remains **DEFERRED_UNPROVEN_OWN17**. Ordinary source, direct-interface, ABI, process and runtime assertions were assessed and remain fail closed. No deferred certification is marked PASS or reinstated as a campaign. Linux execution remains **UNTESTED**. |

The retained phase totals are distinct from child-process runtimes:

| Phase | Required seconds / root cap | Retained elapsed seconds / roots |
|---|---:|---:|
| Preflight | 300 / 0 | 6.429 / 0 |
| DependencyConfigure | 600 / 1 | 14.386 / 1 |
| DependencyBuild | 1200 / 1 | 23.677 / 1 |
| EditorPrerequisiteBuild | 1800 / 1 | 164.402 / 1 |
| GameBuild | 1800 / 1 | 75.612 / 1 |
| Cook | 1800 / 1 | 439.266 / 1 |
| Stage | 600 / 1 | 230.239 / 1 |
| Native | 600 / 1 | 193.346 / 1 |
| Audit | 300 / 0 | 110.313 / 0 |

Only the two CMake roots select five-second post-success cleanup. UBT, UAT and Game retain NaturalDrain. Root counts concern retained orchestration/jobs, not universal process inventory.

The initial 50-GiB requirement is a source-enforced gate; the first retained free-space observation is 749,742,911,488 bytes. All retained boundary observations exceed the 20-GiB floor. Maximum recorded totals remain below the caps: run 7,182,974,999 bytes, Cook 206,698,987, Stage 1,011,088,708 and reports 8,402. These are synchronous observations, not live quotas or universal write-isolation evidence.

**Required detailed reconciliations**

Cook’s owned EditorSettings destination is exactly:

```text
R\ue-user\cook\Saved\Config\WindowsEditor\EditorSettings.ini
```

Wrapper preparation requires file preabsence and creates the checked owned parent before launching UAT. That is a source-enforced prerequisite; no separate timestamped preabsence observation is serialized in the selected Cook object. The exact override is present in both UAT’s sent command (`uat-cook\Log.txt:301`) and Cook’s own received command (`Cook-2026.10.21-11.54.00.txt:457`). Shared settings observations remain unchanged across the nine phases. Installed config/settings ranges explain why UserDir alone is insufficient.

The AndroidFileServer fixture disables the plugin itself. Installed source shows its default-enabled Editor module can instantiate the settings object and update DefaultEngine.ini when its token is `[AUTO]`; runtime `bEnablePlugin` does not guard that writer. Receipt selection and the retained Cook-log observations reconcile the disabled route. The owned project’s `DefaultEngine.ini` remains exactly **375 bytes**, SHA256 `15E5F0F761C9DD6EFE929062426257904197222AB4A0183BEABC82D24B620A25`, throughout the preservation arrays.

The loose Stage copy of that INI is separately recorded as 312 bytes under normal INI sanitization. Across Stage, **79 nonidentical copies are all INI files**. This qualification does not certify their content or assert source-byte equality.

Both UAT parameter blocks independently retain:

```text
Build=False
SkipBuildClient=False
IterateSharedCookedBuild=
IterateSharedBuildUsePrecompiledExe=False
NoDebugInfo=False
SeparateDebugInfo=False
```

`IterateSharedCookedBuild` is the inactive **empty string**, not Boolean false. Stage retains `Cook=True` with `SkipCook=True` and `Stage=True`; Cook retains `SkipCook=False`, `Stage=False`. The actual ordinary non-DLC argv/default route is supported without inventing a logged null DLC value. RequiresPak’s `DontCare` interpretation remains an installed-source inference; its runtime value was not directly logged.

Cook’s three retained `LogDerivedDataCache` rows include the positive **E04A1G owned Writable filesystem backend** observation. Native’s DDC arguments remain defensive requests with **unproven effectiveness**, supplying no selected Native writer/backend claim.

Actual Game definitions have `WITH_EDITORONLY_DATA=0`. The same M06 separately snapshots:

- `requiresCookedData=true` from `FPlatformProperties::RequiresCookedData()`;
- `existingLegacyDerivedDataCacheIsNull=true` from direct `TryGetDerivedDataCache()==nullptr`.

The inspected Core implementation uses `GetModulePtr` and `GetCache`, without loading or creating the cache. Runtime DerivedData IoStore initialization is a separate facility. Native’s zero closed-log category rows and zero owned-directory files do not establish universal DDC or write absence.

Stage reconciliation computed:

- **2,757 UFS**, **34 NonUFS**, **6 debug** copy rows;
- matching membership in all three timestamp manifests;
- **2,800 Stage files**, including the three copied manifests;
- **995 runtime declarations**: 974 UFS, 16 NonUFS and 5 DebugNonUFS; no optional missing rows or duplicate declarations in this actual receipt;
- 1,032 cooked-source copy rows, with retained Entry map and runtime registry byte identities.

The Game executable is **332,392,448 bytes**, SHA256 `7BD57B8890069560CBC553DE6589E41717527B2DFEED6E22FA0E47F73B220902`, joined across GameBuild, Stage, Native and Audit.

The actual check order is exactly:

```text
M01..M18, B01..B09, G01..G13, G23, G14..G22, L01, L02
```

M checks bind Game-thread/normal initialized Game state, cooked data, flags, no prior exit, one Entry world, exact GameModeBase and runtime identities. B checks establish typed MalformedYaml, 17 bytes and an empty refused document. G checks establish Success, 19 bytes, five nodes, two ordered pairs, keys `A` then `a`, values `first` then `second`, depth one, no aliases, owned original bytes and survivor preservation. G23 checks distinct top-level allocations while both values live. L checks mark completed lexical scopes and exactly BAD then GOOD once each.

The result completed during PID 30188’s lifetime. Native log lines 711–734 establish terminal marker, `RequestExitWithStatus(false,0,...)`, orderly shutdown and log closure. The process receipt independently confirms exit 0 and job zero. Its runtime was approximately **2.472 seconds**.

The seven window samples contain zero observed owned top-level WS_VISIBLE counts. Maximum start-to-start gap is approximately **0.5654303 seconds**. The final sample has an empty owned PID set and therefore performs no HWND enumeration. These noncontinuous, non-atomic current-desktop samples prove no continuous, between-sample, other-desktop or child-only absence. Build/Cook roots have no empirical window-observer coverage.

**Isolation, coverage and review-method qualifications**

This context received the bound audit request without visible implementation history. I authored no candidate changes, spawned/forked no agents, requested no model override, used no apps/browser/network tools, and inspected no other final-role directory or peer verdict/findings body. Runtime instructions enforce read-only filesystem access and approval-never.

Own session/invocation ID, actual CLI/model identity, and hidden memory/apps/multi-agent enforcement were not supplied through readable own runtime evidence. Those remain **UNVERIFIED**; multi-agent tools were available but unused. Prior SOURCE runtime metadata is evidence about that separate SOURCE context, not this reviewer’s runtime.

I read all **43 required whole-source entries**, including complete caller/parser, wrapper, supervisor, vendor Rules, E04 ABI tests and guarded E02 input tests; fixture bodies were checked byte-for-byte. I read the whole clean norm, both criteria, full sibling Arcade AGENTS and supplied clean instruction extracts. I inspected **55 complete supplied primary-excerpt files** covering relevant UBT, config/DDC, lifecycle, arrays, staging and Win32 interfaces. The other 35 excerpt files and ungranted upstream bodies remain unread. Installed binary-to-source provenance and unexamined compiler/framework internals remain qualified trusted/UNVERIFIED leaves.

Large evidence arrays were processed through finite structural and membership comparisons, not claimed as individually narrated semantic inspections. Payload binaries remained identity-only. No recursive directory grant was inferred, and no broad transitive asset certificate was attempted.

One schema-only introspection displayed execution-freeze field names/types/counts; I did not use its authority values or peer conclusions. Its body-access qualification remains recorded rather than treating that introspection as substantive authority review.

Checks I ran were inert reads, hashes, Git identity/name-status queries, JSON comparisons, exact-byte comparisons and log scans. **No candidate, helper, control, build, native, engine or external Core code was executed.**

Review-tool errors were recovered: initial oversized output truncations were reread in bounded portions; an unavailable `python` command executed no script; null-value display errors were corrected; preliminary comparisons incorrectly treated hash-letter casing, MSVC `-MD`/`-std` spellings, PowerShell string construction or array sorting as mismatches. Corrected comparisons passed. One inert join attempt yielded no captured result and was replaced by a completed indexed comparison. No unrecovered truncated material is claimed read.

Observed build/runtime warnings were retained: deprecated `PLATFORM_64BITS`, existing E02 potentially-uninitialized warnings, and the Native EnhancedInput user-settings warning. No failed Game check or native assertion failure was found in the inspected result/log scans; Cook reports zero errors and warnings.

Original SOURCE admission/findings closure, original phase GOs and timing bindings, backup verification, and root output-sealing chronology remain administrative prerequisites for root’s separate post-seal inspection. This read-only role created no report file and cannot attest that external sealing has occurred. Root must preserve this closed report and raw outputs unchanged before its first body inspection.

**Acceptance remains withheld for REQ-01.** OWN17 stays deferred/unproven. A2, full YAML/profile/HUD fidelity, Core-connected play, rendering, Linux execution, distribution and broader migration gates remain separate. This report supplies no execution, visible-window, publication or merge authority.
