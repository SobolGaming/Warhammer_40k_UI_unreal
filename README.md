# Warhammer 40k Unreal client

C++ first 3D Unreal client for the external Python rules Core. The active goal is a board connected to a real Core session, one player action and its authoritative visible result. Follow the [migration checklist](docs/plans/unreal-migration-plan.md).

The foundation and synthetic board proofs exist; the default GameMode is still an empty shell at this checkpoint. Live connection/action work is next. This is personal/internal development. Linux x86-64 plumbing exists but native builds/rendering/packages are **UNTESTED**.

**Desktop testing is on HOLD until the owner explicitly resumes it.** Background development/builds continue. Every checkpoint is committed, pushed and exact-ref verified in [PR #3](https://github.com/SobolGaming/Warhammer_40k_UI_unreal/pull/3), which stays open without merge.

## Related projects

- [Warhammer_40k_AI](../Warhammer_40k_AI/README.md): separate authoritative Core, reference-only sibling. Selected commit `5f509724da25a2f6ded0c2739a8e7c84bdf59c91`, contract44.3.33.
- [Warhammer_40k_UI_arcade](../Warhammer_40k_UI_arcade/README.md): existing Arcade client and semantic reference; [original migration plan](../Warhammer_40k_UI_arcade/docs/plans/migration/unreal-migration-plan.md).
- `Warhammer_40k_UI`: distinct earlier UI project referenced in the imported plan; no checkout here. See [historical provenance](docs/plans/unreal-migration-plan-through-r146.md).

## Windows build

Existing toolchain: UE5.8.3/CL58210709 at `C:\Program Files\Epic Games\UE_5.8`, VS2022 17.14, MSVC14.44.35229 (folder14.44.35207), Windows SDK10.0.22621.0, Unreal bundled .NET10.0.203. VS Code is the chosen editor. No new installation is needed.

Run in PowerShell from this repository:

```powershell
$taskUeRoot = 'C:\Program Files\Epic Games\UE_5.8'
$taskProject = Join-Path (Get-Location).Path 'WarhammerClient.uproject'
$taskBuild = Join-Path $taskUeRoot 'Engine\Build\BatchFiles\Build.bat'
$taskLogs = Join-Path (Get-Location).Path '.local\development'
New-Item -ItemType Directory -Force -Path $taskLogs | Out-Null
& $taskBuild WarhammerClientEditor Win64 Development "-Project=$taskProject" -WaitMutex -NoUBA "-UBARootDir=$taskLogs\uba" "-Log=$taskLogs\editor-build.log"
if ($LASTEXITCODE -ne 0) { throw "Editor build failed: $LASTEXITCODE" }
& $taskBuild -ProjectFiles "-Project=$taskProject" -Game -VSCode -2022 -Automated "-Log=$taskLogs\ide-generation.log"
if ($LASTEXITCODE -ne 0) { throw "IDE generation failed: $LASTEXITCODE" }
```

Open generated `WarhammerClient.code-workspace` in VS Code. Do not rerun `New-UnrealCppProject.ps1` over the existing project. Normal Unreal per-user build caches apply; local build outputs are ignored. UE5.8 still uses local UBA storage with `-NoUBA`; its root is explicitly routed above. Linux requires a native UE5.8/toolchain host, still to be arranged.

## Existing Core development server

Prepared Windows environment: `.local/core-44.3.33`. From this repository, the checked-out host can run without changing the Core checkout:

```powershell
$taskCore = [IO.Path]::GetFullPath('..\Warhammer_40k_AI')
$taskCorePython = [IO.Path]::GetFullPath('.local\core-44.3.33\Scripts\python.exe')
if ((git -C $taskCore rev-parse HEAD) -ne '5f509724da25a2f6ded0c2739a8e7c84bdf59c91') { throw 'Core revision mismatch' }
if (git -C $taskCore status --porcelain=v1 --untracked-files=all) { throw 'Core checkout must be clean' }
& $taskCorePython -I -B (Join-Path $taskCore 'scripts\run_phase18m_reference_server.py') --host 127.0.0.1 --port 8765
```

Use a dedicated free loopback port and wait for this process's own `Serving Phase 18M reference contract at http://127.0.0.1:8765` message. Stop a manually attached service with Ctrl+C. The host has fixed development credentials, no durable persistence and a known Windows port-exclusivity gap ([Core #589](https://github.com/SobolGaming/Warhammer_40k_AI/issues/589)); it is the owner-selected internal development service.

The [previous README](README-through-r146.md#run-the-python-rules-core-from-its-checkout) retains detailed pinned-source/environment installation and package recipes, build identity checks and caveats. Core supports installing as the Python package `warhammer40k-core-v2`. In a separately created Python3.14 environment, the pinned Git recipe is:

```powershell
& $taskCorePython -I -B -m pip install 'git+https://github.com/SobolGaming/Warhammer_40k_AI.git@5f509724da25a2f6ded0c2739a8e7c84bdf59c91'
```

This is an alternative environment-preparation recipe, not a request to reinstall the working environment. Private Git authentication is required; never embed credentials in URLs. The development host script remains a checkout/source-artifact entry point; package installation alone does not promise an installed host console command.

## Status and evidence

[Active checklist](docs/plans/unreal-migration-plan.md) separates implemented code from verified behavior. [Evidence index](docs/plans/README.md) links retained results. BOOT01, the separately labelled120-second E01 diagnostic, synthetic E02 and bounded parser/P0 proofs do not establish a live rendered client.

Profile/HUD migration, full gameplay, remote participant/spectator completion, production hosting and exhaustive compatibility proof follow usable local feedback. The [full prior README](README-through-r146.md) preserves original commands, failed attempts and detailed evidence; its former current-status sequencing is historical.