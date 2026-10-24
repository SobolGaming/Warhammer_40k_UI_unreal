# Core development startup

Run commands from `Warhammer_40k_UI_unreal`. Core remains a separately maintained Python authority. The reference sibling `../Warhammer_40k_AI` stays unchanged at 5f509 /44.3.33. P1c explicitly selects **4f9bef0df2fb974d1285232a1009b8781926361d /44.5.0**, from open, unmerged [Core PR #591](https://github.com/SobolGaming/Warhammer_40k_AI/pull/591). Its source is prepared separately under this UI repository's ignored `.local`. These commands use Core's existing `scripts/run_phase18m_reference_server.py`; they do not implement a new host.

## Choose a route

| Situation | Route |
|---|---|
| Native Windows, one-command owned Core/client | Prepare the 44.5 runtime once, then `Start-Client.ps1 -CoreMode Managed`. |
| Foreground Core or an existing local development service | Use the matching selected source/package and `-CoreMode Attach`; client exit leaves Core running. |
| Preserved44.3.33 preview | Select `-CoreVersion 44.3.33` and the old copied executable. Its environment/evidence stay separate. |
| Native Linux x86-64 | Separate native Python/UE, foreground Core and `Start-Client.py`; **all Linux execution remains UNTESTED**. |

A new 44.5 client requires44.5 Core. Selecting an old launcher profile does not make a new client compatible with old sessions. Keep the complete copied Game folder together; omit `-ClientExecutable` only for the built Editor route. See [README](../../README.md) for package/build commands.

## Prepare a fresh native Windows Core environment

Prerequisites: installed native Python 3.14 (workspace 3.14.5), PowerShell 7, Git, `uv`, and the selected Git object available in the reference repository. Safe-fetch that branch if necessary using normal private Git authentication; never reset the reference checkout. The preparation script requires fresh destinations and never deletes/replaces an existing environment:

```powershell
git -C ../Warhammer_40k_AI fetch origin codex/static-successor48
if ($LASTEXITCODE -ne 0) { throw 'Selected Core source fetch failed' }
$taskPython = 'C:\path\to\physical-native-python-3.14\python.exe'
& ./scripts/Prepare-CoreDevelopmentRuntime.ps1 -PythonExecutable $taskPython
```

Use the interpreter's physical directory; version-alias junctions are rejected by the path guard. [Preparation](../../scripts/Prepare-CoreDevelopmentRuntime.ps1) independently clones committed Git objects without hardlinks, uses clone-local literal-byte attributes (Core contains CRLF blobs under conflicting LF attributes), checks out the exact pin under `.local/core-source-44.5.0`, creates `.local/core-44.5.0`, installs dependencies from that source's frozen `uv.lock` with hashes, installs the Core package, verifies its exact build/resource identity and writes fresh `.development-provenance.json`. It records reference HEAD/status before/after and refuses changed source or mismatched identity. No historical E01 receipt is needed for 44.5. Failed output is retained under `.local/development/core-prepare/<run>` for inspection; choose a reviewed repair rather than deleting it blindly.

[Runtime profiles](../../scripts/CoreRuntimeProfile.ps1) contain exact source/build/resource identities and default paths. 44.5 uses build `warhammer40k-core-v2:runtime-tree-sha256-v1:0443ce4bc405aad1737ec9a396948775010df933bd75144f6ab9ff54152118ba`, 3130 resources. 44.3.33 retains its previous build, 3116 resources, sibling source and `.e01-provenance.json`; preparation does not modify it.

### Install the Python package from Git instead

Core is a real installable package named `warhammer40k-core-v2`, Python `>=3.14,<3.15`, using Hatchling/native dependencies. Package version 0.1.0 alone is not the build identity. In a **separate disposable native environment**, normal pip supports:

```powershell
$taskPython = 'C:\path\to\separate-environment\Scripts\python.exe'
& $taskPython -I -B -m pip install 'git+https://github.com/SobolGaming/Warhammer_40k_AI.git@4f9bef0df2fb974d1285232a1009b8781926361d'
if ($LASTEXITCODE -ne 0) { throw 'Pinned Core package installation failed' }
& $taskPython -I -B -c 'from warhammer40k_core.build_identity import verified_engine_build_identity; i=verified_engine_build_identity(); assert i.build_id == "warhammer40k-core-v2:runtime-tree-sha256-v1:0443ce4bc405aad1737ec9a396948775010df933bd75144f6ab9ff54152118ba" and i.resource_count == 3130; print("Selected Core verified")'
if ($LASTEXITCODE -ne 0) { throw 'Installed Core identity differs' }
```

Use normal Git credential handling, never tokens in URLs. Pip may resolve dependency versions; this alternative is not the locked preparation recipe. It does not create Managed provenance. Use foreground/Attach with its matching clean source. A disposable committed-source copy can replace the Git URL; never build/install into the reference sibling. Installing the package provides no host console command, so retain the matching source script.

## Windows foreground Core and Attach

After preparation, terminal 1:

```powershell
$taskCore = [IO.Path]::GetFullPath('.local/core-source-44.5.0')
$taskPython = [IO.Path]::GetFullPath('.local/core-44.5.0/Scripts/python.exe')
& $taskPython -I -B (Join-Path $taskCore 'scripts/run_phase18m_reference_server.py') --host 127.0.0.1 --port 8765
```

Wait for that process's own `Serving Phase 18M reference contract at http://127.0.0.1:8765` message. Terminal 2:

```powershell
$taskExe = 'C:\path\to\Windows\WarhammerClient\Binaries\Win64\WarhammerClient.exe'
& ./scripts/Start-Client.ps1 -CoreMode Attach -Endpoint 'http://127.0.0.1:8765/' -ClientExecutable $taskExe
```

The44.5 profile/source is default. `-CoreRoot` selects another clean source at the same exact pin. Attach reads only named development credential defaults when missing, then performs authenticated `GET /rules-catalog` with a three-second timeout before opening the client. It does not require Managed provenance and does not prove the endpoint's build; client responses validate selected identity. Close the client normally; stop foreground Core with Ctrl+C in terminal 1.

For direct Editor startup, run the helper **in the same shell**, then launch the already-built Editor:

```powershell
$attached = & ./scripts/Start-CoreDevelopmentServer.ps1 -Mode Attach -Endpoint 'http://127.0.0.1:8765/'
$taskUeRoot = 'C:\Program Files\Epic Games\UE_5.8'
& (Join-Path $taskUeRoot 'Engine/Binaries/Win64/UnrealEditor.exe') (Join-Path (Get-Location).Path 'WarhammerClient.uproject') -game -windowed ("-CoreUrl=" + $attached.endpoint)
```

A separately spawned `pwsh -File` cannot initialize its parent's environment. The Python alternative runs from the selected installed environment and leaves Core alone:

```powershell
& ./.local/core-44.5.0/Scripts/python.exe -I -B ./scripts/Start-Client.py --engine-root $taskUeRoot --core-root .local/core-source-44.5.0 --endpoint http://127.0.0.1:8765
```

## Existing Windows Managed runtime

After preparation and a matching client build:

```powershell
& ./scripts/Start-Client.ps1 -CoreMode Managed -ClientExecutable $taskExe
```

Managed validates interpreter/base-interpreter hashes, selected source/provenance and installed Core, then starts the existing source host hidden. Readiness requires owned process identity, verified-build marker, its own flushed bind marker and authenticated catalog HTTP200. The default 60-second budget includes verification; `-ReadinessSeconds 120` diagnoses startup, not gameplay responsiveness. `-Port` selects a dedicated port. A Managed `-Endpoint` must match that port.

For separate management in the same shell:

```powershell
$hostInfo = & ./scripts/Start-CoreDevelopmentServer.ps1 -Mode Managed -Port 8765
# Launch the matching client here; stop only this owned service afterwards.
& ./scripts/Stop-CoreDevelopmentServer.ps1 -ReceiptPath $hostInfo.receiptPath
```

Logs/bootstrap/shutdown marker/receipt are under `.local/development/core-host/<run>`. Without `-ReceiptPath`, Stop uses only the current Managed receipt. It verifies PID, creation time and executable, requests shutdown with a shared 5-second grace (`-GraceSeconds`,1–5), then allows 3 seconds for verified owned termination (`-CleanupSeconds`,1–3). Marker/persistence/other-process errors do not bypass remaining cleanup. STOPPED requires confirmed exit. Attach receipts return `ATTACHED_NOT_STOPPED`; never kill by port/name.

### Preserved44.3.33 preview

The old environment/source and copied P1b executable remain separate:

```powershell
$taskOldExe = 'C:\path\to\preserved-P1b\Windows\WarhammerClient\Binaries\Win64\WarhammerClient.exe'
& ./scripts/Start-Client.ps1 -CoreVersion 44.3.33 -CoreMode Managed -ClientExecutable $taskOldExe
```

Do not pair the new executable with that profile or reuse exact-Core sessions across versions. Existing old provenance is retained; this script does not manufacture a replacement historical receipt.

## Prepare native Linux Core — UNTESTED

No Linux host is arranged. Native dependencies, Python/package identity, startup, UE build, graphics/input and packaging are all **UNTESTED**. Use native Python 3.14 and native UE 5.8; no Windows environment/provenance is portable and no Linux Managed launcher is provided.

From this UI repository, after obtaining the selected Git object in the reference repository, the proposed independent source/native install route is:

```bash
task_core="$PWD/.local/core-source-44.5.0"
test ! -e "$task_core" || exit 1
git -c core.autocrlf=false clone --no-hardlinks --no-checkout ../Warhammer_40k_AI "$task_core" || exit 1
mkdir -p "$task_core/.git/info" || exit 1
printf '%s\n' '* -text -filter -ident -working-tree-encoding' > "$task_core/.git/info/attributes" || exit 1
git -C "$task_core" checkout --detach 4f9bef0df2fb974d1285232a1009b8781926361d || exit 1
task_venv="$PWD/.local/core-dev-linux"
test ! -e "$task_venv" || exit 1
python3.14 -I -B -m venv "$task_venv" || exit 1
"$task_venv/bin/python" -I -B -m pip install 'git+https://github.com/SobolGaming/Warhammer_40k_AI.git@4f9bef0df2fb974d1285232a1009b8781926361d' || exit 1
"$task_venv/bin/python" -I -B -c 'from warhammer40k_core.build_identity import verified_engine_build_identity; i=verified_engine_build_identity(); assert i.build_id == "warhammer40k-core-v2:runtime-tree-sha256-v1:0443ce4bc405aad1737ec9a396948775010df933bd75144f6ab9ff54152118ba" and i.resource_count == 3130; print("Selected Core verified")' || exit 1
```

## Linux native manual route — UNTESTED

Terminal 1:

```bash
task_core="$PWD/.local/core-source-44.5.0"
task_python="$PWD/.local/core-dev-linux/bin/python"
"$task_python" -I -B "$task_core/scripts/run_phase18m_reference_server.py" --host 127.0.0.1 --port 8765
```

After its own bind message, terminal 2:

```bash
export UE_ROOT=/absolute/path/to/native/UE_5.8
"$PWD/.local/core-dev-linux/bin/python" -I -B ./scripts/Start-Client.py \
  --engine-root "$UE_ROOT" --core-root .local/core-source-44.5.0 --endpoint http://127.0.0.1:8765
```

The Python helper verifies installed identity, optional clean source and native executable selection. It copies credentials to the client environment, runs the client and leaves Core alone; it does not health-check/own it. Close the client and Ctrl+C foreground Core when finished. `--client-executable /absolute/path/to/native/Game` selects a future native package instead of Editor; no native Game package is verified here.

## Credentials, endpoint and manual launcher options

Only `http://127.0.0.1:<1024-65535>` with optional trailing slash is supported. Hostnames/HTTPS/IPv6/otheraddresses/paths/query/fragments/URL credentials are rejected before credential access/networking.

The process variables are `WH_CORE_ADMIN_TOKEN`, `WH_CORE_PLAYER_TOKEN`, `WH_CORE_BASE_URL` and test-only `WH_LIVE_CORE_TEST_URL`. Never echo token values or put credentials/private sessions in commands/logs/receipts/reviews. Nonempty caller credentials are preserved; correct stale values deliberately. Windows launchers restore caller variables after exit. Named `DEV_ADMIN_TOKEN` and `DEV_PLAYER_A_TOKEN` are read silently only from the matching clean source/package; Python supplies a copied child environment.

```powershell
& ./.local/core-44.5.0/Scripts/python.exe -I -B ./scripts/Start-Client.py --help
```

Python options include required `--endpoint`, `--engine-root` (or `UE_ROOT`), `--client-executable`, optional `--core-root`, and `--core-version 44.5.0|44.3.33`. Source checks are bounded to 15 seconds. Neither source/package verification nor authenticated catalog health alone identifies the answering HTTP process.

## Development limits and troubleshooting

- The host uses fixed development principals and in-memory sessions. Restart loses sessions; no production credentials, persistence/recovery or remote limits are implemented by this client.
- Windows late port co-bind exclusivity remains [Core #589](https://github.com/SobolGaming/Warhammer_40k_AI/issues/589). The prelaunch exclusive probe checks one instant; use a dedicated port and the launched process's own bind marker.
- Reads use 30-second budgets and mutations120 seconds. The historical invalid-move 30-second failure and 120-second diagnostic in [Core #590](https://github.com/SobolGaming/Warhammer_40k_AI/issues/590) remain historical, not proof of current latency. A timeout means completion unknown, not rejected; reconcile the retained exact command ID.
- Display the actual HTTP status/error. Missing detailed violations are a fidelity gap, not permission to invent legality diagnostics.
- Package/build success is separate from runtime and rendering. Exact44.5 verification status belongs to the [canonical plan](../plans/unreal-migration-plan.md); old 44.3 results are not transferred.
