# Core development startup

Run commands from `Warhammer_40k_UI_unreal`. Core remains a separately maintained Python authority. The reference sibling `../Warhammer_40k_AI` stays unchanged at 5f509 /44.3.33. P2c / [PR #9](https://github.com/SobolGaming/Warhammer_40k_UI_unreal/pull/9) selects main **fc52e9166ff6380b606269ce362f4f1cbc6a2835 /46.0.0**. This is an implementation in progress; runtime/build/review/visible acceptance is recorded only by the [canonical plan](../plans/unreal-migration-plan.md). Its source is prepared separately under this UI repository's ignored `.local`. These commands use Core's existing `scripts/run_phase18m_reference_server.py`; they do not implement a new host.

## Choose a route

| Situation | Route |
|---|---|
| Native Windows, one-command owned Core/client | Prepare the separate 46 runtime once, then `Start-Client.ps1 -CoreMode Managed`. |
| Foreground Core or an existing local development service | Use the matching selected source/package and `-CoreMode Attach`; client exit leaves Core running. |
| Preserved44.5.0 /44.3.33 previews | Explicit `-CoreVersion 44.5.0` or `44.3.33` and the corresponding old executable; environments/evidence stay separate. |
| Native Linux x86-64 | Separate native Python/UE, foreground Core and `Start-Client.py`; **all Linux execution remains UNTESTED**. |

A new 46 client requires the exact 46 Core build. Selecting an old launcher profile does not make a new client compatible with old sessions. Keep the complete copied Game folder together; omit `-ClientExecutable` only for the built Editor route. See [README](../../README.md) for package/build commands.

## Prepare a fresh native Windows Core environment

Prerequisites: installed native Python 3.14 (workspace 3.14.5), PowerShell 7, Git, `uv`, and the selected Git object available in the reference repository. Safe-fetch that branch if necessary using normal private Git authentication; never reset the reference checkout. The preparation script requires fresh destinations and never deletes/replaces an existing environment:

```powershell
git -C ../Warhammer_40k_AI fetch origin main
if ($LASTEXITCODE -ne 0) { throw 'Selected Core source fetch failed' }
$taskPython = 'C:\Users\Rabid\AppData\Roaming\uv\python\cpython-3.14.5-windows-x86_64-none\python.exe'
& ./scripts/Prepare-CoreDevelopmentRuntime.ps1 -CoreVersion 46.0.0 -PythonExecutable $taskPython
```

The literal Python path above is this workstation's physical installation; replace it with the actual physical native Python 3.14 interpreter on another host. The minorless `cpython-3.14-windows-x86_64-none` alias is a junction here and fails the path guard. The prepared 46 environment already exists on this workstation: inspect/reuse its receipt rather than rerunning fresh preparation over it. [Preparation](../../scripts/Prepare-CoreDevelopmentRuntime.ps1) independently clones committed Git objects without hardlinks, uses clone-local literal-byte attributes (Core contains CRLF blobs under conflicting LF attributes), checks out the exact pin under `.local/core-source-46.0.0`, creates `.local/core-46.0.0`, installs dependencies from that source's frozen `uv.lock` with hashes, installs the Core package, verifies its exact build/resource identity and writes fresh `.development-provenance.json`. It records reference HEAD/status before/after and refuses changed source or mismatched identity. Each preparation tool is bounded inside an owned Windows job; descendants are cleaned even after parent exit, with output limits and confirmed empty-job cleanup. No historical E01 receipt is needed for the new 46 preparation. Failed output is retained under `.local/development/core-prepare/<run>` for inspection; choose a reviewed repair rather than deleting it blindly.

[Runtime profiles](../../scripts/CoreRuntimeProfile.ps1) contain exact source/build/resource identities and default paths. 46.0.0 uses build `warhammer40k-core-v2:runtime-tree-sha256-v1:ae914a56833e43a3bbf086730b354c7a18673ccc15ca93e4b474347b95380f19`, 3256 resources. 44.3.33 retains its previous build, 3116 resources, sibling source and `.e01-provenance.json`; preparation does not modify it.

### Install the Python package from Git instead

Core is a real installable package named `warhammer40k-core-v2`, Python `>=3.14,<3.15`, using Hatchling/native dependencies. Package version 0.1.0 alone is not the build identity. In a **separate disposable native environment**, normal pip supports:

```powershell
$taskPython = 'C:\path\to\separate-environment\Scripts\python.exe'
& $taskPython -I -B -m pip install 'git+https://github.com/SobolGaming/Warhammer_40k_AI.git@fc52e9166ff6380b606269ce362f4f1cbc6a2835'
if ($LASTEXITCODE -ne 0) { throw 'Pinned Core package installation failed' }
& $taskPython -I -B -c 'from warhammer40k_core.build_identity import verified_engine_build_identity; i=verified_engine_build_identity(); assert i.build_id == "warhammer40k-core-v2:runtime-tree-sha256-v1:ae914a56833e43a3bbf086730b354c7a18673ccc15ca93e4b474347b95380f19" and i.resource_count == 3256; print("Selected Core verified")'
if ($LASTEXITCODE -ne 0) { throw 'Installed Core identity differs' }
```

Use normal Git credential handling, never tokens in URLs. Pip may resolve dependency versions; this alternative is not the locked preparation recipe. It does not create Managed provenance. Use foreground/Attach with its matching clean source. A disposable committed-source copy can replace the Git URL; never build/install into the reference sibling. Installing the package provides no host console command, so retain the matching source script.

## Windows foreground Core and Attach

After preparation, terminal 1:

```powershell
$taskCore = [IO.Path]::GetFullPath('.local/core-source-46.0.0')
$taskPython = [IO.Path]::GetFullPath('.local/core-46.0.0/Scripts/python.exe')
& $taskPython -I -B (Join-Path $taskCore 'scripts/run_phase18m_reference_server.py') --host 127.0.0.1 --port 8765
```

Wait for that process's own `Serving Phase 18M reference contract at http://127.0.0.1:8765` message. Terminal 2:

```powershell
$taskExe = 'C:\path\to\Windows\WarhammerClient\Binaries\Win64\WarhammerClient.exe'
& ./scripts/Start-Client.ps1 -CoreMode Attach -Endpoint 'http://127.0.0.1:8765/' -ClientExecutable $taskExe
```

The 46.0.0 profile/source is default. `-CoreRoot` selects another clean source at the same exact pin. Attach reads only named development credential defaults when missing, then performs authenticated `GET /rules-catalog` with a three-second timeout before opening the client. It does not require Managed provenance and does not prove the endpoint's build; client responses validate selected identity. Close the client normally; stop foreground Core with Ctrl+C in terminal 1.

For direct Editor startup, run the helper **in the same shell**, then launch the already-built Editor:

```powershell
$attached = & ./scripts/Start-CoreDevelopmentServer.ps1 -Mode Attach -Endpoint 'http://127.0.0.1:8765/'
$taskUeRoot = 'C:\Program Files\Epic Games\UE_5.8'
& (Join-Path $taskUeRoot 'Engine/Binaries/Win64/UnrealEditor.exe') (Join-Path (Get-Location).Path 'WarhammerClient.uproject') -game -windowed ("-CoreUrl=" + $attached.endpoint)
```

A separately spawned `pwsh -File` cannot initialize its parent's environment. The Python alternative runs from the selected installed environment and leaves Core alone:

```powershell
$taskUeRoot = 'C:\Program Files\Epic Games\UE_5.8'
& ./.local/core-46.0.0/Scripts/python.exe -I -B ./scripts/Start-Client.py --engine-root $taskUeRoot --core-root .local/core-source-46.0.0 --endpoint http://127.0.0.1:8765
```

## Existing Windows Managed runtime

After preparation and a matching client build:

```powershell
Set-Location -LiteralPath 'C:\SWDev\warhammer\Warhammer_40k_UI_unreal'
$taskExe = (Get-Content -LiteralPath './.local/p2c-client-executable.txt' -Raw).Trim()
& ./scripts/Start-Client.ps1 -CoreVersion 46.0.0 -CoreMode Managed -ClientExecutable $taskExe
```

The [P2c guide](p2c-manual-testing.md) creates this dedicated path file after a successful build and whole-folder copy. If it is absent, complete that guide first; do not substitute the retained P2b executable.

Managed validates interpreter/base-interpreter hashes, selected source/provenance and installed Core, then starts the existing source host hidden. Readiness requires owned process identity, verified-build marker, its own flushed bind marker and authenticated catalog HTTP200. The default 60-second budget includes verification; `-ReadinessSeconds 120` diagnoses startup, not gameplay responsiveness. `-Port` selects a dedicated port. A Managed `-Endpoint` must match that port.

For separate management in the same shell:

```powershell
$hostInfo = & ./scripts/Start-CoreDevelopmentServer.ps1 -Mode Managed -Port 8765
# Launch the matching client here; stop only this owned service afterwards.
& ./scripts/Stop-CoreDevelopmentServer.ps1 -ReceiptPath $hostInfo.receiptPath
```

Logs/bootstrap/shutdown marker/receipt are under `.local/development/core-host/<run>`. Without `-ReceiptPath`, Stop uses only the current Managed receipt. It verifies PID, creation time and executable, requests shutdown with a shared 5-second grace (`-GraceSeconds`,1–5), then allows 3 seconds for verified owned termination (`-CleanupSeconds`,1–3). Marker/persistence/other-process errors do not bypass remaining cleanup. STOPPED requires confirmed exit. Attach receipts return `ATTACHED_NOT_STOPPED`; never kill by port/name.

### Preserved 44.5.0 and 44.3.33 previews

The old `.local/core-source-44.5.0` / `.local/core-44.5.0` pair and prepared P2b package remain separate. The already prepared workstation command is:

```powershell
& 'C:\SWDev\warhammer\Warhammer_40k_UI_unreal\scripts\Start-Client.ps1' -CoreVersion 44.5.0 -CoreMode Managed -Port 19128 -ClientExecutable 'C:\SWDev\warhammer\.local\manual-client\p2b\Windows\WarhammerClient\Binaries\Win64\WarhammerClient.exe'
```

For a fresh old 44.5 environment only, use `Prepare-CoreDevelopmentRuntime.ps1 -CoreVersion 44.5.0 -PythonExecutable <physical-native-Python3.14-path>`. Its exact pin remains `4f9bef0df2fb974d1285232a1009b8781926361d`, build fingerprint `0443ce4bc405aad1737ec9a396948775010df933bd75144f6ab9ff54152118ba`, 3130 resources. Existing destinations are never replaced. The [retained manual guide](manual-testing.md) has its actual actions and two-terminal Attach commands.

The older44.3 environment/source and copied P1b executable also remain separate:

```powershell
$taskOldExe = 'C:\path\to\preserved-P1b\Windows\WarhammerClient\Binaries\Win64\WarhammerClient.exe'
& ./scripts/Start-Client.ps1 -CoreVersion 44.3.33 -CoreMode Managed -ClientExecutable $taskOldExe
```

Do not pair the new executable with that profile or reuse exact-Core sessions across versions. Existing old provenance is retained; this script does not manufacture a replacement historical receipt.

## Optional Linux authority backend

Core now exposes operator-selected `LinuxAuthority`/`LinuxGameSession` and registered profile-bound execution. The existing development runner still defaults to native `LocalGameSession`; current client tooling does not provision or register another authority backend. Only `legacy-binary-inch-v1` is admitted. Milli-inch arithmetic is inactive gameplay; preserve Core geometry rather than snapping coordinates. See the [source delta](../plans/research/2026-11-16-core-46-reference.md) and [Core setup](https://github.com/SobolGaming/Warhammer_40k_AI/blob/fc52e9166ff6380b606269ce362f4f1cbc6a2835/README.md#linux-authoritative-execution-from-windows-and-linux). Native Windows/Linux numerical equivalence is not established.

## Prepare native Linux Core — UNTESTED

No Linux host is arranged. Native dependencies, Python/package identity, startup, UE build, graphics/input and packaging are all **UNTESTED**. Use native Python 3.14 and native UE 5.8; no Windows environment/provenance is portable and no Linux Managed launcher is provided.

From this UI repository, after obtaining the selected Git object in the reference repository, the proposed independent source/native install route is:

```bash
task_core="$PWD/.local/core-source-46.0.0"
test ! -e "$task_core" || exit 1
git -c core.autocrlf=false clone --no-hardlinks --no-checkout ../Warhammer_40k_AI "$task_core" || exit 1
mkdir -p "$task_core/.git/info" || exit 1
printf '%s\n' '* -text -filter -ident -working-tree-encoding' > "$task_core/.git/info/attributes" || exit 1
git -C "$task_core" checkout --detach fc52e9166ff6380b606269ce362f4f1cbc6a2835 || exit 1
task_venv="$PWD/.local/core-dev-linux"
test ! -e "$task_venv" || exit 1
python3.14 -I -B -m venv "$task_venv" || exit 1
"$task_venv/bin/python" -I -B -m pip install 'git+https://github.com/SobolGaming/Warhammer_40k_AI.git@fc52e9166ff6380b606269ce362f4f1cbc6a2835' || exit 1
"$task_venv/bin/python" -I -B -c 'from warhammer40k_core.build_identity import verified_engine_build_identity; i=verified_engine_build_identity(); assert i.build_id == "warhammer40k-core-v2:runtime-tree-sha256-v1:ae914a56833e43a3bbf086730b354c7a18673ccc15ca93e4b474347b95380f19" and i.resource_count == 3256; print("Selected Core verified")' || exit 1
```

## Linux native manual route — UNTESTED

Terminal 1:

```bash
task_core="$PWD/.local/core-source-46.0.0"
task_python="$PWD/.local/core-dev-linux/bin/python"
"$task_python" -I -B "$task_core/scripts/run_phase18m_reference_server.py" --host 127.0.0.1 --port 8765
```

After its own bind message, terminal 2:

```bash
export UE_ROOT=/absolute/path/to/native/UE_5.8
"$PWD/.local/core-dev-linux/bin/python" -I -B ./scripts/Start-Client.py \
  --engine-root "$UE_ROOT" --core-root .local/core-source-46.0.0 --endpoint http://127.0.0.1:8765
```

The Python helper verifies installed identity, optional clean source and native executable selection. It copies credentials to the client environment, runs the client and leaves Core alone; it does not health-check/own it. Close the client and Ctrl+C foreground Core when finished. `--client-executable /absolute/path/to/native/Game` selects a future native package instead of Editor; no native Game package is verified here.

## Credentials, endpoint and manual launcher options

Only `http://127.0.0.1:<1024-65535>` with optional trailing slash is supported. Hostnames/HTTPS/IPv6/otheraddresses/paths/query/fragments/URL credentials are rejected before credential access/networking.

The process variables are `WH_CORE_ADMIN_TOKEN`, `WH_CORE_PLAYER_TOKEN` (player-a), `WH_CORE_PLAYER_B_TOKEN` (player-b), `WH_CORE_BASE_URL` and test-only `WH_LIVE_CORE_TEST_URL`. Never echo token values or put credentials/private sessions in commands/logs/receipts/reviews. Nonempty caller credentials are preserved; correct stale values deliberately. Windows launchers restore all five caller variables after exit. Named `DEV_ADMIN_TOKEN`, `DEV_PLAYER_A_TOKEN` and `DEV_PLAYER_B_TOKEN` are read silently only from the matching clean source/package; Python supplies a copied child environment. Each player has a separate credential: a missing or malformed player-b declaration is never replaced by the administrator or player-a token. Both existing development principals are available for local handoff; this adds no production login, account creation or remote authorization flow. Package builds and resource-only checks strip both player credentials from their child environment.

```powershell
& ./.local/core-46.0.0/Scripts/python.exe -I -B ./scripts/Start-Client.py --help
```

Python options include required `--endpoint`, `--engine-root` (or `UE_ROOT`), `--client-executable`, optional `--core-root`, and `--core-version 46.0.0|44.5.0|44.3.33`. Source checks are bounded to 15 seconds. Neither source/package verification nor authenticated catalog health alone identifies the answering HTTP process.

## Development limits and troubleshooting

- The host uses fixed development principals and in-memory sessions. Restart loses sessions; no production credentials, persistence/recovery or remote limits are implemented by this client.
- Selected46 source adds Windows exclusive listener binding for [Core #589](https://github.com/SobolGaming/Warhammer_40k_AI/issues/589); preserve the older failure history. Still use a dedicated port and the launched process's own bind marker; a prelaunch probe checks only one instant.
- Reads use 30-second budgets and mutations120 seconds. The historical invalid-move 30-second failure and 120-second diagnostic in [Core #590](https://github.com/SobolGaming/Warhammer_40k_AI/issues/590) remain historical, not proof of current latency. A timeout means completion unknown, not rejected; reconcile the retained exact command ID.
- Display the actual HTTP status/error and permitted typed46 diagnostics. Generic/no-detail branches still retain their fidelity gap; never invent violations. Player revisions are viewer-visible event counts, with nullable activity time and viewer-scoped IDs; see the [source delta](../plans/research/2026-11-16-core-46-reference.md).
- Package/build success is separate from runtime and rendering. Exact46 verification status belongs to the [canonical plan](../plans/unreal-migration-plan.md); old 44.3 results are not transferred.
