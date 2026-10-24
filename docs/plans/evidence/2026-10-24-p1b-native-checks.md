# P1b Windows package — non-visible native checks

2026-10-24. **Bounded checks passed with retained failures and diagnostics.** This is supporting evidence for the [canonical plan](../unreal-migration-plan.md), not P1b acceptance. Source was `388b4fda24ad3bbdb5b5d92c799de9a2c2a71cee`; runtime Core remained `5f509724da25a2f6ded0c2739a8e7c84bdf59c91` / 44.3.33. Fetched `4f9bef0df2fb974d1285232a1009b8781926361d` / 44.5.0 is an unmerged planning candidate and was not adopted or executed here.

## Build and original failures

The first package attempt failed after 68.0286244 seconds with exit -1. Its retained log reports sandbox denial while AutomationTool tried to delete/write its AppData logs; the operator intentionally stopped that attempt. The result records an empty owned job, two total job processes, no cleanup errors and `ownedBuildTreeTerminated=false`. Preserve those actual flags rather than interpreting the stop as a recorded forced-tree termination.

The subsequent package succeeded in **83.4390593 seconds**, exit 0. It built the ordinary Game and Editor targets together: 15 build actions, 47.92 seconds in the build log, followed by successful cook/stage/archive. Cooking was non-visible; the builder launched neither the Game nor the prerequisite installer. Its owned job ended empty, with 59 total accounted processes, no forced-tree termination and no cleanup errors. That count is not an attributed process list.

The original unit harness also returned **FAILED**, because it expected nine tests while the selected Unit prefix ran eleven. The native process exited 0 and all eleven tests succeeded. The same immutable JSON report was revalidated against the nine main-file tests plus two existing creation tests; **no native rerun** occurred. Revalidation does not erase the original harness failure.

## Native results

| Launch | Target and scope | Successful tests | Native seconds | Exit |
|---|---|---:|---:|---:|
| Unit | Editor commandlet, `Warhammer.LiveCore.Unit` | 11 | 17.8834782 | 0 |
| Resources | Outside-checkout Development Game, runtime input/startup resources | 4 | 5.989623 | 0 |
| Managed | Outside-checkout Game, real Core create/action/refresh | 1 | 15.6212205 | 0 |
| Attach | Outside-checkout Game, same real Core integration test | 1 | 15.4204695 | 0 |

This is **17 test executions across four native launches and 16 distinct test names**: the integration test ran once in each Core mode. It is not an assertion count. Every structured JSON test reports Success with zero per-test warnings/errors. The unit log severity scan found no warning/error/fatal lines. Each packaged native log retains **two startup warnings** (unspecified spawn class and light mobility) and **one missing HTML-report-template error**; the JSON reports were generated and passed. None reports a Fatal line. These logs are not described as diagnostically clean.

The original exact outside-copy snapshot contains **50 files / 975,194,745 bytes**. All 50 declared source and destination files were rechecked: 100 size/SHA256 matches. The Game executable is 332,414,464 bytes, SHA256 `64EC651358C60880B24841FFF3B5818CABFDC7CB3865E2F3462D2D13AE2EDD9A`. Its before/after identities match across the three packaged runs. Later inspection found five additional Saved outputs in the outside runtime tree: a manifest, two generated crash-report configurations and two logs. They are outside the original copy snapshot; their private bodies were not read for this record. A generated crash-report configuration alone does not establish a crash.

The three packaged runs record all four Config files unchanged, parent environment restored, complete uncapped stdout/stderr, no forced termination and no cleanup errors. Resources used no Core host. Managed started an owned host and stopped it normally. Attach left the service running; the separate owner observed HTTP200 after client exit and then stopped its own host normally, without forced termination. The small original unit result has no separate Config/environment snapshot, so this record does not invent one.

## Commands and provenance

The recorded public command forms are:

```powershell
& ./scripts/Build-ClientPackage.ps1
& ./scripts/Test-ClientPackage.ps1 -ClientExecutable $CopiedExecutable -Mode Resources
& ./scripts/Test-ClientPackage.ps1 -ClientExecutable $CopiedExecutable -Mode Core -CoreMode Managed -Port $OwnedCorePort
& ./scripts/Test-ClientPackage.ps1 -ClientExecutable $CopiedExecutable -Mode Core -CoreMode Attach -Endpoint $OwnedCoreEndpoint
```

The unit commandlet selected `-ExecCmds="Automation RunTests Warhammer.LiveCore.Unit"` and `-TestExit="Automation Test Queue Empty"`, with NullRHI, RenderOffScreen, unattended/no-splash/no-sound/no-crash-dialog/no-live-coding and owned log/report output. Its limit was 180 seconds. Packaged Resources/Core limits were 120/240 seconds, with 64 MiB per-stream caps. Output/executable paths and ephemeral loopback ports above are variables; credentials and private command bodies are excluded.

The [machine-readable record](2026-10-24-p1b-native-checks.json) contains safe leaf/byte/SHA256 descriptors for original results, reports and streams; the failed build, original unit failure and revalidation; binary/config identities; host-ownership outcomes; and the two-PASS architecture Mermaid parser receipt. Parser evidence establishes syntax only. Raw logs, reports, private session/process identifiers, accounts and credentials remain unpublished.

## Remaining limits

These are non-visible build/automation results. They do not verify pixels, fonts, shaders, physical input, visible packaged P1b workflows, a clean Windows machine, Linux, general gameplay or latest-Core runtime compatibility. [Independent source reviews](2026-10-24-p1b-source-reviews.json) and [visible results](2026-10-24-p1b-visible-preview.md) have their own separate dispositions. Historical manual F failure and earlier evidence remain intact; this native record alone does not grant P1b acceptance.
