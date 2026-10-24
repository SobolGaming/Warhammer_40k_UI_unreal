# Warhammer 40k Unreal client

A C++ first 3D client for the separate authoritative Python Core. This personal/internal development preview supports the Editor route and a Windows Development Game folder. The packaged client has non-visible startup/Core checks; visible package testing and clean-machine delivery remain open.

Read [architecture.md](architecture.md) for the source-tree map, component boundaries and runtime/session flows. The [canonical migration plan](docs/plans/unreal-migration-plan.md) owns all milestone scope and acceptance.

## Get started playing

The current preview can connect/create a real Core session, display the current viewer's board, submit an offered secondary-mission choice and refresh its authoritative result. Full deployment, movement, turns and complete gameplay are still being developed.

Run every command below from the `Warhammer_40k_UI_unreal` repository root. Complete [first-time setup and build](#first-time-setup-and-build) once before using the routine launch commands.

### Windows: routine launch

On this workstation, the prepared Core environment and Editor build already exist. In **PowerShell 7**:

```powershell
& ./scripts/Start-Client.ps1 -CoreMode Managed
```

This starts the existing checked-out development Core hidden, waits for authenticated readiness, then opens the client. Close the client window normally to stop that exact managed Core. It does not build or install anything.

For an already running Core, keep it running and use:

```powershell
& ./scripts/Start-Client.ps1 -CoreMode Attach -Endpoint 'http://127.0.0.1:8765/'
```

**Fresh Windows machines:** a new pip-installed environment does not create the prepared Managed provenance. Use the [foreground Core + Attach route](docs/development/core-startup.md#windows-foreground-core-and-attach) after setting up your own native environment.

The default engine location is `C:\Program Files\Epic Games\UE_5.8`. To use another installation, optionally set its location once in your shell and explicitly pass it to the PowerShell launcher:

```powershell
$env:UE_ROOT = 'D:\Unreal\UE_5.8'
& ./scripts/Start-Client.ps1 -CoreMode Managed -EngineRoot $env:UE_ROOT
```

The PowerShell launcher does not automatically read `UE_ROOT`. Its other options are `-CoreRoot` (default sibling `../Warhammer_40k_AI`), `-Port` (default 8765), `-Endpoint` for Attach, and `-ReadinessSeconds` (default 60, maximum 120) for Managed startup. For example:

```powershell
& ./scripts/Start-Client.ps1 -CoreMode Managed -CoreRoot '../Warhammer_40k_AI' -Port 8766 -ReadinessSeconds 120
& ./scripts/Start-Client.ps1 -CoreMode Attach -CoreRoot '../Warhammer_40k_AI' -Endpoint 'http://127.0.0.1:8766/'
```

Current client endpoints must be **`http://127.0.0.1:<port>`**, optionally with a trailing slash. HTTPS, IPv6, hostnames, other addresses, URL paths and credentials in URLs are unsupported by the current client.

### In the window

1. A black viewport before connection is expected. Click **Connect / create session**.
2. Once the Core projection arrives, select one of the **Core-offered secondary-mission options**.
3. Use **Refresh** to reread the state and inspect the accepted/committed result, revision and selected missions. Only the current viewer's private options should be visible.

The board's advisory terrain outlines and omission of undeployed models are intentional current limits. A full playable battle is not available yet.

The bounded Windows manual run verified wheel zoom, the Frame board button, full-board framing across window sizes and UI focus isolation. A separate [native input test](docs/plans/evidence/2026-10-24-live-core-native-camera-input.md) passed held-button orbit/pan, release stability, zoom limits and F routing on the actual live widgets and CameraActor with synthetic bounds. The later [cancellation check](docs/plans/evidence/2026-10-24-live-core-cancellation.md) passed 386 assertions, including Escape, focus/capture loss and actual resize during orbit/pan; application deactivation was tested by deliberate event delivery only. Click the board to give it keyboard focus, then use:

| Control | Effect |
|---|---|
| Right-drag over the board | Orbit, with elevation limited to 20–85 degrees. |
| Middle-drag over the board | Pan within the board's vicinity. |
| Wheel over the focused board | Zoom within extent-based limits. After editing a UI field, click the board again first. |
| **Frame board** in the panel | Fit the full board into the available area beside the panel; observed in the manual run. |
| **F** with board focus | Frame the board; the native routed-key test passed. The earlier manual F workflow remains unresolved with no established source cause. |
| **Escape**, focus loss or application deactivation | Cancel the current camera drag. |

UI clicks, text entry and panel scrolling retain their own input. Camera gestures do not submit game actions. Resizing deliberately reframes the board; a normal state Refresh preserves your view. See the [current verification checklist](docs/plans/unreal-migration-plan.md).

### Windows standalone Development package (P1a)

The packaging source and its bounded verification are tracked in [P1a of the canonical plan](docs/plans/unreal-migration-plan.md). It packages the existing limited client. Using the installed UE 5.8 Windows toolchain from PowerShell 7:

```powershell
$package = & ./scripts/Build-ClientPackage.ps1
```

The command builds the Game and required Editor/cook targets, cooks the startup resources and runtime input, stages a runnable Windows folder and archives it under a fresh `.local/packages/<run>/archive/Windows`. It never opens a game window or runs the staged prerequisite installer. Its default time limit is 60 minutes (`-TimeoutMinutes`, range5–120); `-EngineRoot` selects another matching native installation. Inspect `package-result.json` and `uat-stdout.log`/`uat-stderr.log` in the returned output root on failure. A successful build is separate from startup or rendering verification.

The folder contains a root bootstrap executable, `WarhammerClient/Binaries/Win64/WarhammerClient.exe`, cooked content/engine dependencies and a separate prerequisite installer. Keep the entire folder together. Python Core remains separately installed/checked out; it is not embedded in this package. From this checkout, use the existing prepared Managed route with explicit packaged selection:

```powershell
& ./scripts/Start-Client.ps1 -CoreMode Managed -ClientExecutable $package.clientExecutable
# Or attach to an existing matching development Core:
& ./scripts/Start-Client.ps1 -CoreMode Attach -Endpoint 'http://127.0.0.1:8765/' -ClientExecutable $package.clientExecutable
```

The manual Python launcher supports `--client-executable /absolute/path/to/WarhammerClient.exe` instead of `--engine-root`, with the same `--endpoint` and selected installed Core runtime requirements. Packaged launches omit the Editor `.uproject -game` arguments, use the executable's directory and retain process-only credentials. PowerShell still supervises only an owned Managed Core; Python remains Attach and leaves the server running. These interactive commands must not be executed during the owner screen HOLD.

P1a's allowed verification is non-visible only. Rendered package controls/fonts/shaders, a machine without an Unreal installation and native Linux remain separate unverified acceptance work.

For the fixed offscreen checks, first copy the **entire** runnable Windows folder outside this repository. Use a fresh destination and select its actual nested executable (not the root bootstrap):

```powershell
$taskCopy = Join-Path (Split-Path (Get-Location).Path -Parent) ('p1-runtime-' + [guid]::NewGuid().ToString('N'))
Copy-Item -LiteralPath (Join-Path $package.archive 'Windows') -Destination $taskCopy -Recurse -ErrorAction Stop
$taskCopiedExe = Join-Path $taskCopy 'WarhammerClient/Binaries/Win64/WarhammerClient.exe'
& ./scripts/Test-ClientPackage.ps1 -ClientExecutable $taskCopiedExe -Mode Resources
& ./scripts/Test-ClientPackage.ps1 -ClientExecutable $taskCopiedExe -Mode Core -CoreMode Managed -Port 19084
```

Resources selects exactly four runtime-data/startup checks, including missing/corrupt-data controls. Core selects exactly one real session/action/refresh check and stops its owned development host afterward; `-CoreMode Attach -Endpoint 'http://127.0.0.1:19084/'` instead leaves an existing service running. These commands enforce NullRHI/RenderOffScreen, use 120/240-second native limits and retain reports under `.local/testpackage`. They reject executables inside the checkout and paths through reparse points, and record the selected absolute path. They do not establish visible rendering or controls. The source checkout hosts only the test tooling.

### Linux x86-64: routine launch — UNTESTED

All Linux setup, compilation, Core startup, client input/rendering and packaging remain **UNTESTED** until a native host is arranged. The PowerShell `Start-Client.ps1` launcher is Windows-only; there is no Linux Managed mode.

After the native Linux setup/build below, open two terminals in this repository. In terminal 1, run the existing Core in the foreground:

```bash
task_core="$(realpath ../Warhammer_40k_AI)"
task_python="$PWD/.local/core-dev-linux/bin/python"
"$task_python" -I -B "$task_core/scripts/run_phase18m_reference_server.py" \
  --host 127.0.0.1 --port 8765
```

Wait for that process's own `Serving Phase 18M reference contract at http://127.0.0.1:8765` message. In terminal 2:

```bash
export UE_ROOT=/absolute/path/to/native/UE_5.8
"$PWD/.local/core-dev-linux/bin/python" -I -B ./scripts/Start-Client.py \
  --engine-root "$UE_ROOT" --core-root ../Warhammer_40k_AI \
  --endpoint http://127.0.0.1:8765
```

The manual Python launcher checks the installed Core identity, supplies missing development credentials silently through the client process environment and launches native `UnrealEditor -game -windowed -CoreUrl=...`. It does not start, health-check, own or stop Core. Close the client normally, then use Ctrl+C in terminal 1 when finished. See [manual startup details](docs/development/core-startup.md#linux-native-manual-route--untested).

## First-time setup and build

### Windows prerequisites and Editor build

Use UE 5.8.3, PowerShell 7, Git, Visual Studio 2022 with C++ build tools/Windows SDK, and VS Code. The existing workstation uses VS2022 17.14, MSVC 14.44.35229 (folder 14.44.35207), Windows SDK 10.0.22621.0 and Unreal's bundled .NET 10.0.203. The current prepared Core uses Python 3.14.5. Do not replace working tools or copy a Windows virtual environment to another host.

For a fresh Core environment, follow [native Windows Core preparation](docs/development/core-startup.md#prepare-a-fresh-native-windows-core-environment). For the existing prepared Managed runtime, no reinstall is needed.

Build the existing **Editor** target; do not rerun the project-creation script:

```powershell
$taskUeRoot = if ($env:UE_ROOT) { $env:UE_ROOT } else { 'C:\Program Files\Epic Games\UE_5.8' }
$taskProject = Join-Path (Get-Location).Path 'WarhammerClient.uproject'
$taskBuild = Join-Path $taskUeRoot 'Engine\Build\BatchFiles\Build.bat'
$taskLogs = Join-Path (Get-Location).Path '.local\development'
New-Item -ItemType Directory -Force -Path $taskLogs | Out-Null
& $taskBuild WarhammerClientEditor Win64 Development "-Project=$taskProject" -WaitMutex -NoUBA "-UBARootDir=$taskLogs\uba" "-Log=$taskLogs\editor-build.log"
if ($LASTEXITCODE -ne 0) { throw "Editor build failed: $LASTEXITCODE" }
```

Rebuild after source changes. Generating the VS Code workspace is a separate optional development step:

```powershell
& $taskBuild -ProjectFiles "-Project=$taskProject" -Game -VSCode -2022 -Automated "-Log=$taskLogs\ide-generation.log"
if ($LASTEXITCODE -ne 0) { throw "IDE generation failed: $LASTEXITCODE" }
```

Open `WarhammerClient.code-workspace`. Normal Unreal per-user build caches apply; local outputs are ignored. UE 5.8 may use local UBA storage even with `-NoUBA`, so the command routes its root explicitly.

### Linux native prerequisites and Editor build — UNTESTED

Use a native x86-64 Linux machine with a supported Vulkan GPU/driver and a native UE 5.8 installed build or source build. Epic lists Ubuntu 22.04/Rocky 8 and the v26 clang 20.1.8 native toolchain for UE 5.7–5.8. Follow the matching engine's setup/toolchain instructions, rather than substituting an unrelated system compiler: [Linux quickstart](https://dev.epicgames.com/documentation/unreal-engine/linux-development-quickstart-for-unreal-engine), [versioned requirements](https://dev.epicgames.com/documentation/unreal-engine/linux-development-requirements-for-unreal-engine?lang=en-US).

Prepare a separate native Python 3.14 environment as described in [Core startup](docs/development/core-startup.md#prepare-native-linux-core--untested). The Windows prepared environment/provenance cannot be reused. The project's Linux renderer selects Vulkan SM6.

Once the native engine/toolchain is installed, the proposed native Editor build is:

```bash
export UE_ROOT=/absolute/path/to/native/UE_5.8
task_project="$PWD/WarhammerClient.uproject"
"$UE_ROOT/Engine/Build/BatchFiles/Linux/Build.sh" \
  WarhammerClientEditor Linux Development "-Project=$task_project" -WaitMutex -NoUBA
```

This command is documented for the future native host; it has not been executed here. Do not use the Windows engine directory or Windows compiled project modules on Linux. After a successful native build, use the two-terminal Linux routine above.

## Troubleshooting

| Symptom | What to check |
|---|---|
| UnrealEditor missing, missing modules or a request to rebuild | Set the correct native engine location and build `WarhammerClientEditor` for your platform. The launcher does not build it. |
| Black viewport | Before Connect this is expected. After Connect, inspect the displayed connection/HTTP error and the Core terminal or managed logs; do not assume a sample game loaded. |
| Login or HTTP 401/403 | Use the selected local development Core and matching process credentials. Helpers preserve existing `WH_CORE_ADMIN_TOKEN`/`WH_CORE_PLAYER_TOKEN`; a stale value is not silently replaced. Do not print them or put them in a URL. |
| Endpoint rejected or HTTP 4xx | Use `http://127.0.0.1:<port>` without a path. Preserve the actual status/message: a timeout is not a rejection and missing diagnostic detail is not an invented rules violation. |
| Managed startup exceeds 60 seconds | Inspect `.local/development/core-host/<run>/stdout.log`, `stderr.log` and its receipt. The budget includes installed-runtime verification; use `-ReadinessSeconds 120` only for startup diagnosis. This is not a gameplay-latency guarantee. |
| Port busy or uncertain managed receipt | Stop the exact owned server with `./scripts/Stop-CoreDevelopmentServer.ps1`, or choose a dedicated different port. Never kill processes by port/name; Attach never stops the existing service. |
| Sessions disappear after Core restarts | This development server has in-memory state. Confirm the restart and begin a fresh client/session; durable save/resume is not provided. |
| **Reconcile unknown command** appears | The client retains one uncertain command envelope/ID in memory and blocks new actions. Reconcile that same command; do not submit a replacement/new ID. Restart recovery and injected response loss remain unverified. Unknown session creation cannot be retried safely. |

Additional startup/authentication details and package recipes are in [Core development startup](docs/development/core-startup.md).

## Related projects

- [Warhammer_40k_AI](../Warhammer_40k_AI/README.md): separate authoritative Core, reference-only sibling. Selected commit `5f509724da25a2f6ded0c2739a8e7c84bdf59c91`, contract 44.3.33, Python package `warhammer40k-core-v2`.
- [Warhammer_40k_UI_arcade](../Warhammer_40k_UI_arcade/README.md): existing Arcade client and behavioral/configuration reference; [original migration plan](../Warhammer_40k_UI_arcade/docs/plans/migration/unreal-migration-plan.md).
- `Warhammer_40k_UI` is the owner's reference name mapped to that local Arcade checkout. [Import provenance](docs/plans/unreal-migration-plan-through-r146.md#repository-routes-and-provenance) records the mapping.

## Status and evidence

The [Unreal migration plan](docs/plans/unreal-migration-plan.md) is the single canonical root roadmap and milestone checklist, using the owner-confirmed Arcade client as the Python UI baseline. The former development-plan filename is only a compatibility pointer. It covers standalone packaging, the full supported interaction families, geometry/selection, profiles/HUD, viewer modes, recovery, native Linux and release criteria. Its unchecked milestones remain future work; this preview is not full parity.

The [active migration checklist](docs/plans/unreal-migration-plan.md) separates source implementation, checks, independent reviews and rendered behavior. The [earlier visible Windows setup check](docs/plans/evidence/2026-10-23-live-core-visible.md) exposed the startup-focus error and cropped board edge. The [camera/startup increment](docs/plans/evidence/2026-10-23-live-core-ergonomics.json) then passed the Windows Editor build, 13 native checks, ten stubbed launcher tests, non-graphical startup and fresh independent CODE/requirements reviews. The resumed [actual manual-launcher check](docs/plans/evidence/2026-10-24-live-core-camera-visible.md) observed repaired keyboard navigation, real-board fit across window sizes, wheel zoom, Frame board, UI wheel isolation, refresh preservation and an accepted/committed mission choice at revision 2. The separate [native camera input check](docs/plans/evidence/2026-10-24-live-core-native-camera-input.md) passed 92 assertions for held orbit/pan, release, zoom clamps, F routing and UI isolation with synthetic bounds; its owned process closed normally. The earlier manual F failure remains recorded. The later [cancellation check](docs/plans/evidence/2026-10-24-live-core-cancellation.md) passed 386 assertions covering Escape, focus/capture loss and actual resize; application deactivation was deliberate event entry only. Actual OS app switching, teardown and fresh-install execution remain unverified. All native Linux execution is UNTESTED. Full gameplay, profile/HUD migration, remote participant/spectator completion, production hosting and exhaustive compatibility remain later work.

[PR #3](https://github.com/SobolGaming/Warhammer_40k_UI_unreal/pull/3) is merged. The current bounded P1a increment packages the existing Windows client and runs non-visible verification in a new PR. The owner is using the screen: visible launches/input/focus changes are on HOLD. The [evidence index](docs/plans/README.md), [prior README](README-through-r146.md) and historical plan preserve earlier accepted scopes and all failed attempts; their former current-status sequencing is historical.
