# E04-A1E shared plugin target refusal closure — 2026-10-21

Status: **FOCUSED_SOURCE_PASSED_SHARED_PLUGIN_TARGET_EDITORBUILD_FAILURE_CLOSED**, plan revision 90. Technical source is `058deb1168f61e8457fcdf7cee8a1be76bc315bf`; actual run is `20261021T044229Z-e2488cb8`. The [factual receipt](../evidence/2026-10-21-e04a-shared-plugin-target-result.json) preserves exact local evidence descriptors and limits.

Focused SOURCE was PASS and root-admitted: report 12630 bytes / SHA256 `8F47736F61FBFF32C27E371BAF637D19BAA71DB0DC45AB95FEDA7DF77BADA988`; admission 6975 bytes / `161F034907D570F826B49982CC66331C2A923A038E30E37A2526A063534A0532`. The ordinary conduct check read 85 input pairs with zero pairing anomalies. SOURCE does not establish runtime acceptance. Configure retained 30 unscanned object edges, two unused metadata stanzas and 11 generated-input pairs. DependencyBuild copied 38 matched headers and produced a 5706624-byte library / SHA256 `756CBDF89BF9EA6FDA55FD1F648792F91DC83354D4E6699B0361BDC2FD895400`; six vendor C4267 conversion warnings remain recorded.

| Actual phase | Result | Elapsed seconds |
| --- | --- | ---: |
| Preflight | PASS; no native root | 31.0196195 |
| SupervisorControls | PASS; six roots and existing finite controls | 51.6455496 |
| Configure | PASS; real Release ABI compile/link and scanning OFF | 39.3270712 |
| DependencyBuild | PASS; 30 vendor C++ objects and one archive, explicit copy | 48.9350208 |
| EditorBuild | FAIL; target setting conflict, no completion | 42.2335898 |
| Discovery / Native / Audit | NOT_RUN; no GOs | — |

The owned UBT process (PID 44528) exited 6 after 3.316249 seconds. Its diagnostic identifies `bCompileWithPluginSupport: True != False` as a prohibited modification while WarhammerClientE04AEditor shares build products with UnrealEditor. UBT returned `OtherCompilationError` after compiling project Rules C# and writing a partial `.target` receipt, before client/plugin C++ compilation/link or parser activation. The wrapper retained primary `E04A1_ROOT_FAILED_OR_CLEANUP_UNVERIFIED`, zero secondary errors and no completion. Exit and cleanup are confirmed, no timeout, final private-job aggregate total 2 / active 0; the primary failure is the nonzero root exit, not an observed cleanup failure.

Root rehashed 434 retained descriptors and checked nine settings, 33 canonical files, 33 staged files and 56 fixtures. Rules retention is `PARTIAL_PRESERVED`: the runtime witness is absent, seven available roles are retained, and no retention failure was reported. The partial target receipt is retained as partial evidence, not a successful target receipt. UBT stdout reports the ordinary global `C:\Users\Rabid\AppData\Local\UnrealBuildTool\Trace.uba` output; this is an observed diagnostic path, not an owned-path or universal filesystem-isolation claim.

All execution authority is closed and cannot transfer. Native parser attempts are zero; the 43-input / 33-generated / 50-attempt / eight-suite proof remains planned. No visible window or Linux test ran. A1G, final CODE/different REQ, A1E acceptance and broader migration gates remain open; OWN17/D-P2 stay deferred/unproven/fail-closed and standing source/API review consent is unchanged.

Checkpoint this closure, push and verify OWN18 exact remote backup before reviewing the prospective one-line removal of the forced `bCompileWithPluginSupport=true` setting for the installed Shared target. That repair is not applied or proved here. Any adopted source change requires a fresh exact head/run/freeze/current bindings and affected focused SOURCE before ordered native phases. Prior revision 89 source-only repair and older failures remain unchanged historical records; no old approval transfers.
