**CHANGES_REQUESTED — immutable FINAL_CODE assessment.**

Bound subject:

```text
FinalHead:      c187d3496bb473e1cbbac3387350ba58898e3b3a
ExecutedHead:   fa11be76cca922006f9bb7eb16f7240bc51925f7
ComparisonBase: 2651a8652915824fe339a958ca5afc1a835f5731
RunId:          20261021T152810Z-45e572ca
```

The separate actual permission and ROOT GO match this review. Verified SHA256 identities:

| Control | SHA256 |
|---|---|
| Actual permission | `838C73FCB64203338B0AD129E96E15F52ED78166F68BB5ADAD8BD0B623866F21` |
| Own input manifest | `170AB1997A909CFD376164AD4A39CDB1A89D79A78EBAA4EBD32052B81EB7BC30` |
| Own final freeze | `50E2B13ECD449BE6C41F83E9BE5A96987BBEBF5FD86B55151046144E586BB9A3` |
| Execution freeze | `CC4F42A2CC22E56F28FF9DA9F8B8D41A936C251ACC7F2B48875743FF30C84362` |

Two findings prevent PASS:

1. **P1 — UBT reports outputs outside the required owned run root.** Editor prerequisite stdout reports writing `C:\Users\Rabid\AppData\Local\UnrealBuildTool\Trace.uba` (9.3 KB); Game build stdout reports the same destination (9.6 KB). This conflicts with the norm’s requirement to own outputs under R. The wrapper’s `-NoUBA` and owned `-UBARootDir` did not prevent these reported writes. Bind and verify an owned trace route before claiming that requirement satisfied. I did not inspect or modify the ungranted destination. Primary evidence: [Editor stdout, line 43](/C:/SWDev/warhammer/Warhammer_40k_UI_unreal/.local/experiments/E04A1G/20261021T152810Z-45e572ca/logs/a1g-editor-prerequisite.stdout.log:43), [Game stdout, line 49](/C:/SWDev/warhammer/Warhammer_40k_UI_unreal/.local/experiments/E04A1G/20261021T152810Z-45e572ca/logs/a1g-game-build.stdout.log:49), [UBT arguments](/C:/SWDev/warhammer/Warhammer_40k_UI_unreal/scripts/migration/Invoke-E04A1GProfileProof.ps1:894).

2. **P2 — Audit discards its fresh DDC observation record.** Audit calls `Check-A1GNativeLog`, which checks and returns category-row count, owned-file count and owned directory, but its returned audit object retains only `$log.log`. The closed `phase=Audit, sourcePointer="/audit"` value likewise lacks `ddc`. The fail-closed call remains present; the required Audit-boundary counts are not retained. Preserve `$log.ddc` in the Audit evidence. Native’s earlier zero counts cannot substitute for that later observation. Primary pointers: [validator return](/C:/SWDev/warhammer/Warhammer_40k_UI_unreal/scripts/migration/Invoke-E04A1GProfileProof.ps1:1708), [Audit call and return](/C:/SWDev/warhammer/Warhammer_40k_UI_unreal/scripts/migration/Invoke-E04A1GProfileProof.ps1:1751), [closed positive facts](/C:/SWDev/warhammer/Warhammer_40k_UI_unreal/.local/reviews/E04A1G-final-review/positive-facts-fa11be7-20261021T161803Z-b54f0985/closed-execution.positive-facts.json).

The inspected component and execution evidence otherwise support these bounded facts:

- All **981 unique frozen/input file descriptors** matched current bytes. All **45 canonical mappings** matched the bound Git objects, with no executed-to-final blob differences in that set. The **43 required frozen sources** and **36 owned project copies** joined correctly. The later AGENTS metadata overlay remains distinct from executed source.
- Fresh Release yaml-cpp evidence includes a real Release ABI compile/link, 30 compile commands, one direct archive action with the exact ordered 30-object sequence, 38 copied headers, matching library bytes and the raw MIT notice. Compiler/SDK selection, C++20, dynamic Release CRT, EHsc, GR-, static define and disabled build options reconcile.
- The normal Editor prerequisite has matching project/installed BuildId `55116800`. Actual Game evidence establishes Shared/monolithic Development, caller exceptions disabled, parser EHsc, `/MD`, C++20, `WITH_EDITOR=0`, **`WITH_EDITORONLY_DATA=0`**, and link consumption of both parser objects, caller object and fresh vendor library.
- The exact owned fixture contains typed `AndroidFileServer.Enabled=false` with only the required fields. Neither receipt has the prohibited Rules overrides; both actual BuildPlugins arrays exclude AndroidFileServer. Game contains the required E04ProfileProof membership; Editor excludes it. The retained Cook log contains zero AndroidFileServer or proof-plugin rows. Owned project `DefaultEngine.ini` remains 375 bytes with SHA256 `15E5F0F761C9DD6EFE929062426257904197222AB4A0183BEABC82D24B620A25`.
- Cook’s source path checks require EditorSettingsINI preabsence and create its owned parent before launch. Exact sent/received tokens select `R/ue-user/cook/Saved/Config/WindowsEditor/EditorSettings.ini`. All nine shared Editor/UBT setting roles and the separate actual LocalApplicationData GameUserSettings baseline remain unchanged across the retained phase observations. Preabsence is supported by the executed fail-closed path, not a separately retained file-observation row.
- Actual UAT logs distinguish resolved `Build=False`, `SkipBuildClient=False` and inactive `IterateSharedCookedBuild=""`. Loose Cook/Stage reconcile 1,048 cooked files, 2,797 classified copy rows, three timestamp manifests and 2,800 staged files. All 995 ordered runtime-dependency declarations join, with zero optional missing declarations. The 79 nonidentical INI copies retain the normal sanitization qualification.
- The [actual Game result](/C:/SWDev/warhammer/Warhammer_40k_UI_unreal/.local/experiments/E04A1G/20261021T152810Z-45e572ca/reports/game-probe/result.json) records exactly BAD then GOOD, 17/19 bytes with the required hashes and codes, and **52 explicitly evaluated, Boolean-positive checks in the required order**. Source supports synchronous input release, UE-owned values, deep-copy survival and lexical destruction before publication. M06 uses `RequiresCookedData()` and direct nonloading `TryGetDerivedDataCache()==nullptr`; both separate result fields are typed Boolean `true`.
- Cook positively logs the owned writable filesystem DDC. Native retains zero `LogDerivedDataCache` rows and zero files in its owned Native DDC directory. Audit’s missing retained counts are finding 2. Native DDC arguments remain defensive requests with unproven effectiveness; runtime DerivedData IoStore is separate. These observations prove neither universal DDC absence nor universal write absence.

All nine projected phase completions, ordered predecessor/result/freeze joins and preservation comparisons reconcile. Recorded root counts are `0,1,1,1,1,1,1,1,0`; elapsed seconds are `6.43,14.39,23.68,164.40,75.61,439.27,230.24,193.35,110.31`, within their respective budgets. Seven retained process roots have exit 0, confirmed cleanup and successful final job queries with active count zero. Only CMake selected post-success cleanup; UBT/UAT/Game selected NaturalDrain. Storage observations remain within caps; these are boundary checks, not live quotas.

Native PID **30188** joins the staged executable, arguments, result, terminal marker, orderly exit and closed log. Its [process receipt](/C:/SWDev/warhammer/Warhammer_40k_UI_unreal/.local/experiments/E04A1G/20261021T152810Z-45e572ca/phases/native/a1g-native.process.json) records seven successful zero-observed window samples: three endpoints and four periodic samples, maximum start gap approximately **0.56543 seconds**. This establishes only zero **OBSERVED** owned top-level WS_VISIBLE windows at those current-desktop samples. It establishes no continuous, between-sample, other-desktop or child-only absence. No UE assertion total is inferred.

I read the whole clean norm, common/role criteria and governing controls; complete caller/parser/value/error/lifetime implementation, wrapper, supervisor, relevant build branches and E04 ABI tests; selected granted direct APIs; and material primary execution evidence. Inert hashes, Git identities, structural comparisons, log scans and manifest joins were reviewer checks. No candidate, helper, build, native, engine or Core code was executed.

Unread coverage includes excluded peer/SOURCE conclusions and original admission/GO bodies, private sessions/configuration, broad transitive internals, most legacy E02 test implementation, and deferred Rules/witness machinery. Large inventories and logs received structural comparison/search coverage rather than a claim that every line was substantively read. Binary contents remained identity-only.

This context used read-only/approval-never permissions, no resume/fork, subagents, apps or model override. Hidden memory/feature enforcement and current invocation/session metadata remain **UNVERIFIED**; requested settings are not enforcement evidence. Tool-output truncations were recovered for material source/control passages; omitted repetitive output remains outside claimed coverage. Reviewer-side recovery included an unavailable Python command, a PowerShell formatting error, hash-letter-case false positives and a singleton-array counting error. Corrected PowerShell checks resolved these without changing originals.

Original SOURCE admission, actual phase GO chronology and this review’s root sealing procedure remain a separate administrative qualification for root’s post-seal inspection. Preserve this report unchanged. **OWN17 remains DEFERRED_UNPROVEN; Linux remains UNTESTED.** A2, full fidelity, Core play, rendering, distribution and broader acceptance remain separate. This verdict grants no execution, acceptance, publication or merge authority.
