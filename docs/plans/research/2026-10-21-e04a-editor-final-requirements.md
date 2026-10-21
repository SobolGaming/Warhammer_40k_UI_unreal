**BLOCKED — immutable E04-A1E FINAL_REQ disposition.**

The inspected run supports the bounded Windows exception-enabled Editor component’s functional result. I found no failed functional suite, ignored component assertion, failed required build, or unknown required job cleanup.

Complete FINAL_REQ acceptance remains blocked by the unverified historical 38/40-input preservation requirement and outstanding administrative closure. The disclosed SOURCE seal-ordering failure cannot be converted into an ordering PASS by later matching hashes.

| Subject | Exact identity |
|---|---|
| Role | `FINAL_REQ` |
| FinalHead | `3bfd22d0018dbda285a3db4184c8509dbc3783f1` |
| ExecutedHead | `0bbbf884308a9d896cf19a2e2cf42614481559e8` |
| ComparisonBase | `03d28af606fc6c57d20915f746296b0d843211c6` |
| RunId | `20261021T062742Z-6f13b8a2` |
| Own review directory | `.local/reviews/E04A1-final-review/final_req-3bfd22d-062742-20261021T073518Z-2c337d` |

The actual permission file’s SHA256 matched the separately supplied GO:

`155D97C9C29C239A398743E1B69116DA728EFF4F18DD637E30E826C2A472E12D`

The input-manifest hash was `D1E8BAB2E536380A028B6D705F972FECDD34AC55005DE79B221F4CCC13180F5C`; the final-freeze-manifest hash was `24C108D0DAFAECEB7F298305652E613CB2C33A98E6B49D60EA6399207BFFC947`. Their 523 frozen-member lists matched, and my identity checks found **zero byte-count/hash mismatches across those 523 members**.

This review used the supplied fresh task context, read-only filesystem policy and approval-never policy. I used no resume, fork, subagent or model override, inspected no peer verdict body, and executed no candidate, helper, control, build, native, engine or Core command. Current backend model identity, memory mode, reviewer OS-process identity, exact transported-payload hash and final reviewer-process closure were not exposed by the permitted controls; those remain **UNVERIFIED**, rather than borrowing another review’s metadata.

For the references below, paths are relative to `C:\SWDev\warhammer\Warhammer_40k_UI_unreal`:

- **Source**: `.local/planning/E04/source-refresh-runs/0bbbf88-20261021T062742Z-6f13b8a2-practical/bodies/canonical`
- **Run**: `.local/experiments/E04A1/20261021T062742Z-6f13b8a2`
- **Common**: `.local/reviews/E04A1-final-review/common-3bfd22d-062742-20261021T073518Z-2c337d`
- **Correspondence**: `.local/planning/E04/focused-component-source-0bbbf88/final-packet-source-data/3bfd22d-062742/source-execution-correspondence.json`

**A1E-01 — PASS for the inspected boundary and finite observations.**

Primary source: `E04ProfileFormat.h:9–57`, `E04ProfileValue.h:19–49`, `E04ProfileParserModule.cpp:9–46`, `E04YamlEventReader.cpp:161–399`, and `E04ProfileAbiTests.cpp:199–469`.

The source exposes a synchronous input view and UE-owned return values through `noexcept`. Vendor strings, streams, parser state, callbacks and exceptions remain private. The completed graph and original bytes are published only after successful parsing. Typed refusals therefore retain the default empty public document.

The native evidence supports module loading, typed failure followed by success, deep copying, nested-array independence, survival after source destruction, moving allocations and stable alias targets. These are evaluated assertions tied to the inspected caller logic and successful UE suite results—not conclusions drawn from suite names.

Unsupported-format and empty-input branches are source-supported; these 50 attempts do not independently exercise every public refusal branch. Unexpected/allocation exceptions intentionally terminate at `noexcept`; universal recovery and allocation-failure safety are unproven.

**A1E-02 — PASS for the specified representation and finite boundaries.**

Primary source: public limits, entry gates, event copying/attachment and null probe; tests at `E04ProfileAbiTests.cpp:507–636`; primary outcomes in `Run/artifacts/native/parser-resource-bounds/input-ledger.json` and `parser-lexical-failures/input-ledger.json`.

| Inclusive limit | Below / at / above tested | Above result |
|---|---|---|
| Input bytes | 1,048,575 / 1,048,576 / 1,048,577 | `InputTooLarge` |
| Collection depth | 63 / 64 / 65 | `DepthLimit` |
| Raw nodes | 99,999 / 100,000 / 100,001 | `NodeLimit` |
| Alias occurrences | 9,999 / 10,000 / 10,001 | `AliasLimit` |
| Decoded scalar bytes | 65,535 / 65,536 / 65,537 | `ScalarLimit` |

Below/at cases succeeded. Above cases reported the corresponding observed value and exact limit, with zero returned node/depth/alias metrics and successful complete failed-empty assertions.

The source preserves ordered mapping pairs, equal and case-distinct keys, length-delimited scalar/tag/anchor bytes, alias indices and observed collection styles. The tests evaluate those properties, including K04’s `78007900` decoded bytes and K05’s `01` and `7FC280C29F`.

The null probe uses the same owned input after entry gates, fixed local bounds and no public null graph:

- **F11:** `NullPropertiesUnavailable`, Observed **2**, Limit 0, available mark `(position 1, line 0, column 1)`.
- **F12:** `MalformedYaml`, available mark `(24, 1, 0)`, empty result.
- **F13:** `NullPropertiesUnavailable`, Observed **3**, Limit 0, mark `(1, 0, 1)`, empty result. The source restores that refusal after the bounded probe stops; it does not establish syntax completion beyond the stop.

Raw NUL/EOT/quoted-C0 refusals and escaped/quoted-byte acceptance are finite regressions. General YAML, null/property and plain-DEL conformance remain unproven.

**A1E-03 — Current functional set PASS; historical preservation UNVERIFIED.**

Primary evidence: both fixture manifests; independent fixed native definitions and recipes at test lines 79–168; reader/writer logic at 218–399; wrapper `Expected-Attempts` and `Check-Native`; eight original suite ledgers, 50 retained input files, UE `Run/reports/native/index.json`, and `Run/logs/native-native.log`.

I independently reconstructed all 33 generated inputs, checked the ten canonical byte sources, and compared every retained native input byte-for-byte, including SHA256, auxiliary SHA1 and length. There were **zero mismatches**.

| Suite suffix under `Warhammer.Migration.E04A1.` | Attempts | Evaluated checks | Checks attributed to input rows |
|---|---:|---:|---:|
| Abi.LoadAndBoundary | 1 | 115 | 13 |
| Abi.TypedRefusal | 2 | 127 | 26 |
| Abi.ValueLifetime | 1 | 118 | 17 |
| Parser.CanonicalSyntax | 10 | 391 | 290 |
| Parser.OrderedCaseValues | 5 | 248 | 147 |
| Parser.LexicalFailures | 13 | 279 | 178 |
| Parser.ResourceBounds | 15 | 326 | 225 |
| Integration.RepeatIsolation | 3 | 141 | 40 |
| **Total** | **50** | **1,745** | **936** |

The source’s evaluated control flow reconciles these totals: 101 setup checks per suite, one additional pre-input module-load check, and the input-associated checks. No prefabricated assertion total was substituted.

Membership, per-suite order and multiplicity matched. K03 occurred four times, K04 three times, F01 and F02 twice each; other IDs occurred once. The union was exactly **43 IDs**. All expected codes matched, with zero failed custom checks. The independent UE export and native log recorded **eight successful suites**, zero failed/not-run/in-process tests and zero exported suite errors or warnings.

The 1,745 count is **not an observed UE assertion total**. Full returned graphs were not serialized; their value/lifetime properties are supported by evaluated native assertions and UE outcomes.

The current definitions contain the earlier-set projections and preserve their relative order when additions are removed. However, separately granted earlier 38- and 40-input snapshots were unavailable. Their historical byte/recipe/expectation equality cannot be independently established from current records or amendment prose alone. That required part of A1E-03 remains unverified.

**A1E-04 — PASS for the ordinary direct build contract, with stated provenance limits.**

Primary evidence: pinned vendor `CMakeLists.txt`, parser/event/mark/anchor/exception/stream sources; `YamlCpp.Build.cs`; dedicated target; complete `CMakeConfigureLog.yaml`; cache, compile commands and Ninja files; actual dependency stdout; Editor build log; four terminal compile responses with shared responses/forced definitions; both DLL link responses; artifact/build/module-selection receipts.

Observed/computed facts:

- yaml-cpp pin: `56e3bb550c91fd7005566f19c079cb7a503223cf`.
- Actual dependency build compiled **30 sources** and produced a static archive.
- Main Release and ABI try-compile Release selections were present. The configure log contains a real ABI **compile and executable link**, exit 0.
- Module scanning was OFF. The two permitted generic scan-rule names each occurred once across the two retained Ninja files, in declarations; no `dyndep` binding was found.
- Actual dependency commands used C++20, `/MD`, `/EHsc`, `/GR-` and `YAML_CPP_STATIC_DEFINE`.
- Built and copied `yaml-cpp.lib` identities matched: **5,706,624 bytes**, SHA256 `B60A72EF8F77F415D93C1B745904498F53D773F4A93BB66FFF34B77C8A2AAB35`.
- Parser link input names that copied archive. Probe link input excludes it; probe compile input excludes the vendor include path/static definition.
- Both Editor modules actually used `/EHsc`, `/MD`, C++20 and `PLATFORM_EXCEPTIONS_DISABLED=0`. Probe-local `bEnableExceptions=false` did **not** disable effective Editor exceptions.
- Actual compiler/linker versions were 19.44.35229 / 14.44.35229, SDK 10.0.22621.0. The installed directory’s `14.44.35207` name is reconciled by the configure/build version observations.
- The pinned 1,061-byte MIT notice and retained copy matched.

The constructor’s verification of 38 copied headers is source-supported and recorded by its post-validation selection receipt. Those 38 copied header targets were not separately frozen/granted for my rehash; I do not label their independent byte inspection complete. Compiler/framework internals and installed Ninja binary-to-source provenance remain trusted or unverified leaves.

**A1E-05 — Technical phase reconciliation PASS; administrative closure BLOCKED.**

Primary evidence: all 499 selected `resultFacts`/`completionFacts` in `Common/phase-evidence/closed-execution.positive-facts.json`, exact technical process/log bodies, and administrative selected fields in `neutral-administrative-facts.root-adopted.original.json`.

All 499 selected values were present. The phases, predecessors and projected GO/host/completion times reconcile in this order:

| Phase | Budget seconds | Supervised roots | Recorded elapsed seconds |
|---|---:|---:|---:|
| Preflight | 300 | 0 | 32.0602097 |
| SupervisorControls | 600 | 6 | 52.3322303 |
| Configure | 600 | 1 | 39.1474452 |
| DependencyBuild | 1200 | 1 | 49.0146437 |
| EditorBuild | 1800 | 1 | 118.0172809 |
| Discovery | 600 | 1 | 66.9221937 |
| Native | 600 | 1 | 53.1188738 |
| Audit | 300 | 0 | 38.31898 |

Discovery’s complete list contained 6,350 eligible engine tests and exactly the eight required selected suites. Native results reconcile with the primary functional evidence above.

The supplied pre-native SOURCE metadata records one matching payload, explicit actual GO, read-only/approval-never, memory disabled, `gpt-6.1-sol`, and closed process 45920 before these phases. These are **that SOURCE review’s projected facts**, not proof of this reviewer’s runtime identity or its semantic verdict.

Administrative qualifications remain:

1. `/sourceSealOrderingFacts` explicitly records **358 members rehashed before the first SOURCE report-body read and 15 afterward**. All 373 reportedly matched, but `/orderingRequirementFullyMet` is false. The recorded orchestration/schema error and ignored checker exit are preserved; later rehashing does not repair chronology.
2. Original SOURCE report/admission and original phase GO bodies remain opaque under the grant. Root’s reserved post-seal checks have not been observed by this reviewer.
3. Reuse of the still-unused planned RunId after the preallocation host refusal is expressly recorded as an **interpretation**, not an express packet exception.

These prevent my complete administrative acceptance statement.

**A1E-06 — PASS for inspected ordinary safety and preservation observations.**

Primary source: complete wrapper initialization, authority, environment, process, error and finalization paths; primary evidence: 11 process receipts, 22 streams, supervisor child observations, settings/source/stage/fixture snapshots and retained-output descriptors.

I checked kernel creation/exit-time consistency and **711 accounting samples across 11 roots**, finding no checked timing/accounting violations. Every required root had confirmed exit and final zero-active job accounting.

Configure and DependencyBuild used successful-root cleanup after more than five seconds, with root exit 0, successful retained-job termination and subsequent zero-active accounting. EditorBuild, Discovery and Native drained naturally.

The six supervisor subcases retained their expected unsuccessful attempts. SUP01 demonstrated the post-root cleanup path; SUP02 retained timeout/termination evidence. Assign/query/close and writer failures remained failures in their underlying evidence. The separate sixth process root produced the expected ObjSrcMap `RulesError`, exit 8, preserved canary and confirmed cleanup. Its `ubt.json` was correctly parsed as **47 JSON Lines**.

The 18 build-boundary and seven generated-input controls were pure/offline controls, not native suites or comprehensive recognizer certification.

All nine settings roles had available before/after observations with matching existence/hash data. All eight phases retained equal 33-member canonical/staged snapshots and equal 56-member fixture snapshots. External settings contents were not read. Known-Documents observations remain logical-path observations, without resolved-target assurance.

The 20-GiB prerequisite is source-enforced; no numeric free-space sample was exported. The 64-MiB and 512-MiB checks apply at the documented operation/retention boundaries. Audit’s selected inventory maximum was 5,706,624 bytes and report total 90,824 bytes. Discovery also logged a 118.5-MiB asset-registry cache outside that retained inventory: these controls are not universal instantaneous disk quotas.

Final job zero is aggregate accounting, not a universal descendant inventory or OS/network isolation proof.

**A1E-07 — PASS for applying the deferral; special assurance remains DEFERRED_UNPROVEN_OWN17.**

I inspected the material direct interfaces and retained ordinary assertions. No bypass was selected or inferred.

Comprehensive custom-harness/generated-input/response recognizer correctness, broad transitive Unreal graphs and private Rules/cache witness certification remain unproven. The ordinary witness records seven Rules sources, two parents and eight matching retention-role pairs; those facts do not certify the deferred machinery. Older producer completeness strings do not override the focused norm.

**A1E-08 — PASS for scope discipline.**

This assessment establishes no A1G exception-disabled caller result, A2/727 compatibility result, full YAML/null/property/plain-DEL fidelity, universal resource limits, HUD/input/rendering result, Linux execution, packaging, real-Core play or full migration acceptance. None was made a prerequisite for the substantive component findings above.

**Source correspondence, coverage and discrepancies.**

I independently confirmed all 33 executed/final Git entries were identical, all current canonical/staged identities matched their frozen/audit snapshots, and all 36 canonical source mappings matched. FinalHead was current HEAD. Executed-to-final differences were exactly the four identified metadata files; excluded AGENTS/README/migration-plan bodies were not read. I therefore establish execution-source correspondence, not semantic approval of those excluded final documentation bodies.

Material component, tests, wrapper, fixtures, direct configuration and norm coverage was complete, including recovery of material output truncations. Selected vendor lifetime/event/escape sources, all 43 retained primary excerpts, four CMake documents and four installed API range families were inspected. Other optional vendor/framework/API sources, portions of optional broader Core-boundary source, HTML presentation and ungranted historical snapshots remain unread or outside substantive coverage. Binary inspection was identity-only.

Additional discrepancies/errors retained:

- Wrapper line 28’s “unchanged” embedded-C# provenance/hash comment is stale. The extracted literal hashes differed from the stated older hash. The verified whole-wrapper identity and actual cleanup implementation were used instead.
- Dependency build retained six C4267 warnings; Editor build retained two C4701 warnings in broader E02 units.
- Discovery retained a missing-Content directory-watcher warning. Native’s complete log contained no matched error/warning/fatal/assertion diagnostics.
- The earlier metadata inspector’s separator-comparison failure remains preserved. Its correction record does not prove a later successor execution.
- My unavailable-Python read attempt and oversized output truncations were audit-tool issues; material reads were recovered through inert PowerShell reads/comparisons.

The remaining closure is targeted: establish the earlier 38/40 fixture preservation from separately granted primary identities, complete root’s reserved original authority/SOURCE checks, and explicitly dispose of the disclosed ordering and preallocation interpretations. No favorable peer string or future field resolves those items.

This report grants no execution, publication, merge or launch authority.