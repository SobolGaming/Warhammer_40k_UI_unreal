# P2c Core 46 manual verification

P2c adapts the existing workflow to exact Core `fc52e9166ff6380b606269ce362f4f1cbc6a2835` /46.0.0. The [canonical plan](../plans/unreal-migration-plan.md) owns P2C-V1/V2 and their actual status. These are required workflow checks, not a claim that Linux, clean-machine installation or full gameplay is verified. At this original-criteria checkpoint the46 implementation/package/runtime is **not yet prepared**; run these commands only after its build/native/SOURCE gates pass. A prepared absolute workstation command will be recorded after the copy is verified.

## Prepare and compile

Prerequisites: native Windows x64, PowerShell7, Git, `uv`, native Python3.14, UE5.8.3 with the existing C++ toolchain. The reference Core Git repository must contain the selected commit; fetching is safe, checking out/resetting that sibling is not part of these instructions. Keep existing44.5/44.3 environments and packages intact.

On a fresh checkout only, create the separate46 source/runtime. This command refuses existing destinations; if one exists inspect its provenance and prior result instead of deleting or overwriting it:

```powershell
Set-Location -LiteralPath 'C:\SWDev\warhammer\Warhammer_40k_UI_unreal'
$taskNativePython = 'C:\Users\Rabid\AppData\Roaming\uv\python\cpython-3.14-windows-x86_64-none\python.exe'
& ./scripts/Prepare-CoreDevelopmentRuntime.ps1 -CoreVersion '46.0.0' -PythonExecutable $taskNativePython
```

Build/cook without a visible window, copy the **entire** archived Windows folder to a fresh outside-checkout location and save its actual executable path. Do not copy just the executable or use a source-relative binaries path:

```powershell
Set-Location -LiteralPath 'C:\SWDev\warhammer\Warhammer_40k_UI_unreal'
$ErrorActionPreference = 'Stop'
$package = & ./scripts/Build-ClientPackage.ps1 -EngineRoot 'C:\Program Files\Epic Games\UE_5.8'
$taskCopy = Join-Path (Split-Path (Get-Location).Path -Parent) ('p2c-client-' + [guid]::NewGuid().ToString('N'))
Copy-Item -LiteralPath (Join-Path $package.archive 'Windows') -Destination $taskCopy -Recurse -ErrorAction Stop
$taskExe = Join-Path $taskCopy 'WarhammerClient/Binaries/Win64/WarhammerClient.exe'
if (!(Test-Path -LiteralPath $taskExe -PathType Leaf)) { throw 'Copied executable is missing.' }
New-Item -ItemType Directory -Path './.local' -Force | Out-Null
Set-Content -LiteralPath './.local/p2c-client-executable.txt' -Value $taskExe -Encoding utf8
Get-FileHash -LiteralPath $taskExe -Algorithm SHA256
& ./scripts/Test-ClientPackage.ps1 -ClientExecutable $taskExe -Mode Resources
& ./scripts/Test-ClientPackage.ps1 -ClientExecutable $taskExe -Mode Core -CoreMode Managed -CoreVersion '46.0.0' -Port 19138
```

Keep failures and package logs. The two tests above are non-visible and do not satisfy P2C-V1/V2. Independent SOURCE results are also required before visible acceptance.

## P2C-V1: Managed two-player workflow

From a fresh shell after setup, this opens one game window. Keep each launch within ten minutes and close normally:

```powershell
Set-Location -LiteralPath 'C:\SWDev\warhammer\Warhammer_40k_UI_unreal'
$taskExe = (Get-Content -LiteralPath './.local/p2c-client-executable.txt' -Raw).Trim()
& ./scripts/Start-Client.ps1 -CoreMode Managed -CoreVersion '46.0.0' -Port 19138 -ClientExecutable $taskExe
```

1. Connect/create as player-a. Choose one offered mission, then Refresh; record Core's actual returned counter and accepted result privately.
2. Hand off. Confirm the board, mission, options, roster/receipt/error and session ID clear before Ready; target is player-b.
3. Ready as player-b. Confirm the same session and only that viewer's permitted data, local count0 and their own current choice. Submit an offered choice and Refresh.
4. Hand back through the empty screen; Ready as player-a. Do not expect equal counters across players, or exactly +1 per choice. Only Core supplies revisions and aliases.
5. Check board framing, panel-focused typing/F/wheel and readable status. Close normally; confirm only the Managed host stops.

## P2C-V2: Attach reopen and failed handoff

Start the separate host in terminal1; keep it running through the clients, then press Ctrl+C only after the final health check:

```powershell
Set-Location -LiteralPath 'C:\SWDev\warhammer\Warhammer_40k_UI_unreal'
& ./scripts/Start-CoreDevelopmentServer.ps1 -CoreVersion '46.0.0' -Port 19139
```

Terminal2, fresh shell. This diagnostic changes only the client's player-b credential and restores it afterwards; the host retains its ordinary development credentials. Never publish real credentials, seeds or session IDs:

```powershell
Set-Location -LiteralPath 'C:\SWDev\warhammer\Warhammer_40k_UI_unreal'
$taskExe = (Get-Content -LiteralPath './.local/p2c-client-executable.txt' -Raw).Trim()
$taskSavedPlayerB = [Environment]::GetEnvironmentVariable('WH_CORE_PLAYER_B_TOKEN', 'Process')
try {
    $env:WH_CORE_PLAYER_B_TOKEN = 'diagnostic-invalid-player-b'
    & ./scripts/Start-Client.ps1 -CoreMode Attach -CoreVersion '46.0.0' -Endpoint 'http://127.0.0.1:19139/' -ClientExecutable $taskExe
} finally {
    [Environment]::SetEnvironmentVariable('WH_CORE_PLAYER_B_TOKEN', $taskSavedPlayerB, 'Process')
}
Invoke-RestMethod -Uri 'http://127.0.0.1:19139/health' | Select-Object status
& ./scripts/Start-Client.ps1 -CoreMode Attach -CoreVersion '46.0.0' -Endpoint 'http://127.0.0.1:19139/' -ClientExecutable $taskExe
Invoke-RestMethod -Uri 'http://127.0.0.1:19139/health' | Select-Object status
```

1. In the first client create/choose as player-a and copy the session ID privately. Hand off/Ready; expect actual HTTP401 and an empty privacy display. No automatic create/retry or old player's data may reappear. Close normally; the host must survive.
2. In the second, ordinary client paste that ID and Open existing session. Confirm current player-a projection and local count0; submit an offered choice if still available, otherwise retain the current known result. Hand off/Ready to player-b successfully, confirming current disclosure only. Close normally.
3. Both health calls must succeed. Stop the separately owned host from terminal1; the client must never stop it.

For each criterion record tester, UTC date, source/package executable SHA256, exact Core SHA/build/resources, ordered observations and private screenshot/log locations. Native request instrumentation supplies zero-mutation/read-count proof. Keep failed/blocked/not-run boxes unchecked in the plan and PR body; rendered/native results do not certify physical held-button/OS-switch behavior or native Linux.
