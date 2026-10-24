# Core development startup

All commands run from the `Warhammer_40k_UI_unreal` repository root. Core remains a separate, read-only sibling checkout at `../Warhammer_40k_AI`, selected commit `5f509724da25a2f6ded0c2739a8e7c84bdf59c91`, contract 44.3.33. This guide uses its existing reference development server; it does not implement a new host.

## Choose a route

| Situation | Route |
|---|---|
| This Windows workstation, with its prepared `.local/core-44.3.33` | `Start-Client.ps1 -CoreMode Managed`: start hidden Core, wait for readiness, open client, stop only the owned Core when the client closes. |
| Fresh Windows setup or a foreground Core you want to keep running | Prepare a separate native environment once; run the checkout server in terminal 1, then use `Start-Client.ps1 -CoreMode Attach` in terminal 2. |
| Native Linux x86-64 | Separate native environment and Editor build; foreground Core plus `Start-Client.py`. **The entire Linux route remains UNTESTED.** No Linux Managed launcher is provided. |

A pip install alone does **not** create the prepared Windows Managed provenance. Its pinned interpreter hashes and `.e01-provenance.json` belong to the existing verified workstation environment. New machines can use the normal foreground/Attach path below without running historical E01 experiment phases or manufacturing that receipt.

Build the native `WarhammerClientEditor` target first using the [README](../../README.md#first-time-setup-and-build). The development client uses UnrealEditor with `-game -windowed`; these are not packaged-client instructions.

## Prepare a fresh native Windows Core environment

Skip this if you are using the existing prepared Managed runtime. Otherwise use an installed native Python 3.14 interpreter (3.14.5 is the workspace target), Git and normal private-repository access. If your Python installation has no `py` launcher, replace `py -3.14` with its full native `python.exe` path. Do not copy an existing virtual environment or change/reset the shared Core checkout.

```powershell
$taskCore = [IO.Path]::GetFullPath('../Warhammer_40k_AI')
$taskPin = '5f509724da25a2f6ded0c2739a8e7c84bdf59c91'
$taskHead = & git -C $taskCore rev-parse HEAD
if ($LASTEXITCODE -ne 0 -or $taskHead -cne $taskPin) { throw 'Core checkout revision differs' }
$taskChanges = @(& git -C $taskCore status --porcelain=v1 --untracked-files=all)
if ($LASTEXITCODE -ne 0 -or $taskChanges.Count) { throw 'Core checkout must be clean; use a separate matching checkout rather than resetting it' }
$taskVenv = Join-Path (Get-Location).Path '.local/core-dev-windows'
if (Test-Path -LiteralPath $taskVenv) { throw 'This setup recipe requires a fresh environment; inspect/reuse an existing one separately' }
py -3.14 -I -B -m venv $taskVenv
if ($LASTEXITCODE -ne 0) { throw 'Native Python 3.14 environment creation failed' }
$taskPython = Join-Path $taskVenv 'Scripts/python.exe'
& $taskPython -I -B -m pip install 'git+https://github.com/SobolGaming/Warhammer_40k_AI.git@5f509724da25a2f6ded0c2739a8e7c84bdf59c91'
if ($LASTEXITCODE -ne 0) { throw 'Pinned Core package installation failed' }
& $taskPython -I -B -c 'import sys; from warhammer40k_core.build_identity import verified_engine_build_identity; i=verified_engine_build_identity(); assert sys.version_info[:2] == (3,14); assert i.build_id == "warhammer40k-core-v2:runtime-tree-sha256-v1:65fc8414407ae5d6a8ea779c8e737a22733459094db679a160c60f6e2129f96a" and i.resource_count == 3116; print("Selected Core runtime verified")'
if ($LASTEXITCODE -ne 0) { throw 'Installed Core identity check failed' }
```

Core's public package metadata names `warhammer40k-core-v2`, requires Python `>=3.14,<3.15`, and uses Hatchling/native dependencies. Git authentication must use normal credential handling, never credentials in URLs. The pinned Core commit identifies the selected source; pip may still resolve dependency versions. This is development setup, not a hash-locked portable release. Package version `0.1.0` alone does not identify the selected Core build.

If downloading from Git is unsuitable, install from a disposable committed-source copy/archive of the same pin outside the read-only Core checkout. Do not build/edit/sync dependencies inside the shared checkout. The [archived installation recipes](../../README-through-r146.md#run-the-python-rules-core-from-its-checkout) give that alternative; their former experiment sequencing is historical.

Installing the package does not install a host console command. Keep the matching checkout for `scripts/run_phase18m_reference_server.py`; it imports the installed package from the chosen environment.

## Windows foreground Core and Attach

Use two PowerShell 7 terminals in the Unreal repository. In terminal 1:

```powershell
$taskCore = [IO.Path]::GetFullPath('../Warhammer_40k_AI')
$taskPython = [IO.Path]::GetFullPath('.local/core-dev-windows/Scripts/python.exe')
& $taskPython -I -B (Join-Path $taskCore 'scripts/run_phase18m_reference_server.py') --host 127.0.0.1 --port 8765
```

Wait for this process's own `Serving Phase 18M reference contract at http://127.0.0.1:8765` message. In terminal 2:

```powershell
$taskUeRoot = if ($env:UE_ROOT) { $env:UE_ROOT } else { 'C:\Program Files\Epic Games\UE_5.8' }
& ./scripts/Start-Client.ps1 -CoreMode Attach -EngineRoot $taskUeRoot -CoreRoot '../Warhammer_40k_AI' -Endpoint 'http://127.0.0.1:8765/'
```

Attach initializes missing development credentials silently in the launcher's process environment and performs authenticated `GET /rules-catalog` with a three-second timeout before opening the client. It does not need the prepared Managed runtime/provenance. Closing the client leaves the foreground Core running; stop it with Ctrl+C in terminal 1.

To launch UnrealEditor directly, first run the existing Attach helper **in the same PowerShell session** so the client inherits its initialized environment:

```powershell
$taskUeRoot = if ($env:UE_ROOT) { $env:UE_ROOT } else { 'C:\Program Files\Epic Games\UE_5.8' }
$attached = & ./scripts/Start-CoreDevelopmentServer.ps1 -Mode Attach -CoreRoot '../Warhammer_40k_AI' -Endpoint 'http://127.0.0.1:8765/'
$taskEditor = Join-Path $taskUeRoot 'Engine/Binaries/Win64/UnrealEditor.exe'
$taskProject = Join-Path (Get-Location).Path 'WarhammerClient.uproject'
& $taskEditor $taskProject -game -windowed ("-CoreUrl=" + $attached.endpoint)
```

Use `& ./scripts/...` in that shell. A separately spawned `pwsh -File` process cannot set its parent shell's environment. An alternative manual client launcher using the fresh installed environment is:

```powershell
& ./.local/core-dev-windows/Scripts/python.exe -I -B ./scripts/Start-Client.py --engine-root $taskUeRoot --core-root '../Warhammer_40k_AI' --endpoint 'http://127.0.0.1:8765'
```

## Existing Windows Managed runtime

Routine one-command launch on the prepared workstation:

```powershell
& ./scripts/Start-Client.ps1 -CoreMode Managed
```

For a different engine path, set `$env:UE_ROOT` once in the current shell and pass `-EngineRoot $env:UE_ROOT`; the PowerShell script itself does not read `UE_ROOT` automatically. Use `-CoreRoot` for a different clean matching checkout and `-Port` for a dedicated loopback port. `-Endpoint` is useful for Attach; in Managed it must exactly match the selected `127.0.0.1` port.

Managed uses the existing `.local/core-44.3.33/Scripts/python.exe`, checks interpreter/base-interpreter hashes and prepared provenance, verifies installed Core, then starts the checked-out host hidden. Readiness requires its owned process identity, verified-build marker, its own flushed bind marker and authenticated catalog HTTP 200. The default 60-second budget includes runtime verification, not only socket binding; `-ReadinessSeconds 120` is available for startup diagnosis. It does not establish gameplay responsiveness.

You can manage the Core separately in the same client-launching shell:

```powershell
$hostInfo = & ./scripts/Start-CoreDevelopmentServer.ps1 -Mode Managed -Port 8765
# Launch the client from this same shell to inherit the prepared WH_CORE_* environment.
# Stop only this exact owned service when finished:
& ./scripts/Stop-CoreDevelopmentServer.ps1 -ReceiptPath $hostInfo.receiptPath
```

Without `-ReceiptPath`, Stop uses the current Managed receipt:

```powershell
& ./scripts/Stop-CoreDevelopmentServer.ps1
```

Logs, bootstrap, unique shutdown marker and ownership receipt are under `.local/development/core-host/<run>/`; `current.json` refers only to Managed ownership. Stop verifies PID, creation time and executable, requests shutdown, waits 10 seconds and may terminate only verified owned processes with a further 5-second exit budget. It never kills by port/name or an unverified process tree. If identity is unavailable or changed, it refuses and retains the receipt/logs. Passing a valid Attach receipt returns `ATTACHED_NOT_STOPPED` without shutdown/termination.

## Prepare native Linux Core — UNTESTED

The complete Linux path is untested: native dependency installation, interpreter/package identity, server startup, Unreal build, graphics/input and packaging. Use a native Python 3.14 environment (3.14.5 target) and the matching native UE 5.8 host/toolchain described in the [README](../../README.md#linux-native-prerequisites-and-editor-build--untested). Neither the Windows virtual environment nor its prepared provenance is portable to Linux. No new runtime-profile preparation campaign is required for this manual route.

```bash
task_core="$(realpath ../Warhammer_40k_AI)"
task_pin=5f509724da25a2f6ded0c2739a8e7c84bdf59c91
task_head="$(git -C "$task_core" rev-parse HEAD)" || exit 1
test "$task_head" = "$task_pin" || exit 1
task_changes="$(git -C "$task_core" status --porcelain=v1 --untracked-files=all)" || exit 1
test -z "$task_changes" || exit 1
task_venv="$PWD/.local/core-dev-linux"
test ! -e "$task_venv" || { printf '%s\n' 'Choose a fresh native environment or inspect the existing one.'; exit 1; }
python3.14 -I -B -m venv "$task_venv" || exit 1
task_python="$task_venv/bin/python"
"$task_python" -I -B -m pip install 'git+https://github.com/SobolGaming/Warhammer_40k_AI.git@5f509724da25a2f6ded0c2739a8e7c84bdf59c91' || exit 1
"$task_python" -I -B -c 'import sys; from warhammer40k_core.build_identity import verified_engine_build_identity; i=verified_engine_build_identity(); assert sys.version_info[:2] == (3,14); assert i.build_id == "warhammer40k-core-v2:runtime-tree-sha256-v1:65fc8414407ae5d6a8ea779c8e737a22733459094db679a160c60f6e2129f96a" and i.resource_count == 3116; print("Selected Core runtime verified")' || exit 1
```

This is the native Linux package identity check, separate from the Windows Managed provenance checks. No Windows runtime success proves these commands work on Linux. Stop and inspect actual installation/import errors instead of substituting an unrelated Core version.

## Linux native manual route — UNTESTED

In terminal 1, from this repository:

```bash
task_core="$(realpath ../Warhammer_40k_AI)"
task_python="$PWD/.local/core-dev-linux/bin/python"
"$task_python" -I -B "$task_core/scripts/run_phase18m_reference_server.py" \
  --host 127.0.0.1 --port 8765
```

After that process prints its own bind message, terminal 2 can launch the client:

```bash
export UE_ROOT=/absolute/path/to/native/UE_5.8
"$PWD/.local/core-dev-linux/bin/python" -I -B ./scripts/Start-Client.py \
  --engine-root "$UE_ROOT" --core-root ../Warhammer_40k_AI \
  --endpoint http://127.0.0.1:8765
```

`Start-Client.py` locates native `Engine/Binaries/Linux/UnrealEditor`, launches the existing project with `-game -windowed -CoreUrl=http://127.0.0.1:8765`, waits for the client and leaves Core alone. Close the client normally and Ctrl+C the foreground Core when finished. It performs no service launch, service health check or ownership/shutdown operation. Linux-specific behavior has not been executed here; source tests of binary-path selection do not establish Linux runtime success.

## Credentials, endpoint and manual launcher options

Current client endpoint validation accepts only `http://127.0.0.1:<port>` with an optional trailing slash. The helper scripts require a dedicated port 1024–65535. Do not use HTTPS, IPv6, another 127.* address, `localhost`, paths, query/fragment strings or credentials in URLs for this client.

The process environment names are `WH_CORE_ADMIN_TOKEN`, `WH_CORE_PLAYER_TOKEN` and `WH_CORE_BASE_URL`. Never echo token values or put them in commands, logs, receipts, screenshots or tracked files. Existing nonempty credential values are retained, so stale credentials need deliberate correction rather than silent replacement. For another configured host, use its matching credentials; the present client remains restricted to the local endpoint route.

The PowerShell helper reads only the two named literals `DEV_ADMIN_TOKEN` and `DEV_PLAYER_A_TOKEN` from the pinned clean checkout's development registry. The Python manual helper verifies the installed Core's exact build/resource identity first, then imports only those named defaults when an environment value is missing. Both supply process-only credentials; the Python helper passes a copied environment to Unreal without changing its parent shell. Both set `WH_CORE_BASE_URL` and pass the actual client endpoint through `-CoreUrl`.

Inspect the manual launcher's options without launching a client:

```powershell
& ./.local/core-dev-windows/Scripts/python.exe -I -B ./scripts/Start-Client.py --help
```

```bash
"$PWD/.local/core-dev-linux/bin/python" -I -B ./scripts/Start-Client.py --help
```

`--engine-root` uses native UE 5.8 and defaults to `UE_ROOT`; `--endpoint` is required. Optional `--core-root` verifies a clean selected checkout as the server script reference, with each read-only Git check bounded to 15 seconds. That check and local package verification do not prove which process answered an HTTP endpoint. Only the client receives the copied credentials. The manual helper does not build/install, mutate Core or claim ownership of the attached service.

## Development limits and troubleshooting

- The reference host has fixed development principals and in-memory state. Restarting it loses sessions; it is not a production or durable host.
- Windows has a known late port co-bind exclusivity gap ([Core #589](https://github.com/SobolGaming/Warhammer_40k_AI/issues/589)). The Managed helper's prelaunch exclusive probe only checks that instant; an HTTP response alone does not identify the answering process. Use a dedicated port and the launched process's own bind marker.
- Attach requires catalog HTTP 200, refuses redirects and reports `owned=false`. It does not verify the attached server's exact build; the live client still checks session/build/contract data. Actual HTTP 4xx/status/messages remain visible rather than becoming fabricated rules diagnostics.
- A startup timeout is not a gameplay rejection. Inspect the retained managed logs and receipt; do not repeatedly launch on an uncertain receipt or kill an unrelated process. The [README troubleshooting table](../../README.md#troubleshooting) covers missing builds, black-before-Connect, credentials, unknown commands and lost sessions.

The owner directly resumed bounded camera/UI/startup/manual-launcher tests on 2026-10-24. Each launch uses one game window, a ten-minute limit and owned-process cleanup. This bounded test authority does not change the manual setup/run instructions for the owner.

The [actual manual-launcher observations](../plans/evidence/2026-10-24-live-core-camera-visible.md) cover Windows startup, board framing and a Core choice. The separate [native input test](../plans/evidence/2026-10-24-live-core-native-camera-input.md) passed 92 assertions for actual Slate/CameraActor input with synthetic bounds. Both processes are closed; neither result verifies Linux execution or removes the earlier manual F workflow failure.
