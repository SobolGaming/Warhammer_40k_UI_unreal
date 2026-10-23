# Core development startup

Use PowerShell 7 or newer from the Unreal repository root. These helpers supervise the existing reference server from the clean sibling `Warhammer_40k_AI` checkout at `5f509724da25a2f6ded0c2739a8e7c84bdf59c91` / contract **44.3.33**. They do not install a runtime or change the Core checkout.

## One-command client launch

Once visible checks are permitted, use:

```powershell
& ./scripts/Start-Client.ps1 -CoreMode Managed
# Or keep an existing server running:
& ./scripts/Start-Client.ps1 -CoreMode Attach
```

This interactive command launches the installed UE 5.8 Editor with the existing project/default map, `-game -windowed -CoreUrl=<endpoint>`. It inherits the silently prepared `WH_CORE_*` environment, waits for you to close the client, and stops only the exact managed host it started. Attach mode leaves the existing service running. Use `-EngineRoot`, `-Port` or `-Endpoint` for explicit alternatives; no build or installation is performed. Close the client window normally rather than interrupting its waiting launcher. The current owner screen HOLD still prevents agents from invoking this command until explicitly resumed.

## Managed Windows host

Run this in the same PowerShell session that will launch the client:

```powershell
$hostInfo = & ./scripts/Start-CoreDevelopmentServer.ps1
$hostInfo
# Launch the Unreal client from this session so it inherits WH_CORE_* variables.
```

Default endpoint: `http://127.0.0.1:8765`. Use `-Port 8766` to select a different dedicated loopback port. Managed mode uses the existing `.local/core-44.3.33/Scripts/python.exe`, checks the pinned interpreter/provenance, and verifies the installed Core build before running the checkout's `scripts/run_phase18m_reference_server.py`. Readiness requires the owned process identity, installed-build marker, Core's flushed bind marker and an authenticated `GET /rules-catalog` HTTP 200. Default readiness budget is 60 seconds: the first functional attempt exceeded 30 seconds during runtime verification and reached its own bind marker during graceful cleanup. This remains a development-startup allowance, not a gameplay-latency guarantee.

The helper silently fills missing process environment variables `WH_CORE_ADMIN_TOKEN` and `WH_CORE_PLAYER_TOKEN` from the two named development constants in the pinned Core registry; an existing value is retained. It sets `WH_CORE_BASE_URL` to the selected endpoint. The tokens are never included in output objects, receipts or launch arguments. Do not echo these variables. If using `pwsh -File` in a separate process, its environment changes cannot propagate back to your parent shell; invoke the script with `&` in the shell that launches Unreal.

Stop the owned server explicitly:

```powershell
& ./scripts/Stop-CoreDevelopmentServer.ps1
# Or use the exact earlier receipt:
& ./scripts/Stop-CoreDevelopmentServer.ps1 -ReceiptPath $hostInfo.receiptPath
```

Logs, startup wrapper, shutdown marker and ownership receipt live under `.local/development/core-host/<unique-run>/`; `current.json` points only to the managed receipt. Stop verifies PID, process creation time and executable, requests the unique shutdown file, waits up to 10 seconds, then can terminate only the verified owned server/launcher with a further 5-second exit budget. It never kills by port/name or terminates an unverified process tree. A missing/changed identity fails visibly with the receipt and logs retained.

## Attach to an existing host

```powershell
$attached = & ./scripts/Start-CoreDevelopmentServer.ps1 -Mode Attach
# For another endpoint, use an origin URI with a trailing slash:
# $attached = & ./scripts/Start-CoreDevelopmentServer.ps1 -Mode Attach -Endpoint 'http://127.0.0.1:8766/'
```

Attach performs the authenticated catalog health request with a three-second timeout and reports `ATTACHED_HEALTHY`, `owned = false`. It starts no service, does not replace `current.json` and does not claim the attached service's exact build identity; the client must still validate returned session/build/contract data. Passing its attachment receipt to Stop returns `ATTACHED_NOT_STOPPED` without a shutdown request or termination. Supply the matching `WH_CORE_ADMIN_TOKEN` / `WH_CORE_PLAYER_TOKEN` in the current process environment when attaching to a differently configured host. Redirects are refused, and credentials must not be placed in the endpoint URL.

The current reference host uses fixed development principals and in-memory state. Restarting it loses sessions. It is not a production host. The helper's prelaunch exclusive loopback probe does not repair Core's known late Windows co-bind exclusivity gap ([Core #589](https://github.com/SobolGaming/Warhammer_40k_AI/issues/589)).

## Checked-out Core and package recipes

The selected Core is an installable Python package (`warhammer40k-core-v2`, Python 3.14). The managed helper uses the already prepared installation; it does not invoke pip/uv or install anything. A separately prepared environment can install the pinned checkout or Git revision:

```text
python -m pip install /absolute/path/to/Warhammer_40k_AI
python -m pip install "git+https://github.com/SobolGaming/Warhammer_40k_AI.git@5f509724da25a2f6ded0c2739a8e7c84bdf59c91"
```

Use normal authenticated Git access for the private repository; never embed a token in the URL. Installing the package does not install a server console entry point. Keep the matching checkout for `scripts/run_phase18m_reference_server.py`, and consult Core's own README/lockfile for environment preparation. These are manual preparation recipes, not actions performed or verified by the helpers.

For a native Linux Python 3.14 environment with the selected package already installed, a manual foreground command is:

```bash
mkdir -p .local/development/core-host/linux-manual
/path/to/native/venv/bin/python -I -B ../Warhammer_40k_AI/scripts/run_phase18m_reference_server.py \
  --host 127.0.0.1 --port 8765 \
  --shutdown-file "$PWD/.local/development/core-host/linux-manual/shutdown.requested"
```

Choose a fresh manual output directory/absent shutdown marker for each run. Request shutdown from another terminal by creating that exact marker, or stop the foreground process normally. The Windows environment cannot be reused on Linux. Native Linux startup/build/render/package remains **UNTESTED** until a host is arranged; no Linux helper or portability result is claimed here.
