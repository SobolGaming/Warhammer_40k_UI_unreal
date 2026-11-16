# P3a public roster verification

The [canonical plan](../plans/unreal-migration-plan.md) owns P3A-V1/V2. The coordinator performs functional pass/fail checks, including the actual screen; the owner only needs to decide visual style when a later first-class interface introduces that choice. This preview reuses the current style. Build/native/SOURCE gates precede rendered acceptance. Source implementation and Windows native checks are recorded separately in the canonical plan; required P3A-V1/V2 remain pending until actually observed. Do not reuse an old package as P3a evidence.

## Prepared workstation command

A complete verified source `ae423d02a723bae1f408e83420bafed3d4048cae` package is prepared outside the checkout:50 files /976,478,897 bytes; executable SHA256 `87d62f0920b4daf2c7b42b3eeb5fa3e4a09135f70a150ae39058de501c7ff441`. The separate exact46 runtime is already installed. No compilation or undefined shell variable is needed for this prepared copy:

```powershell
& 'C:\SWDev\warhammer\Warhammer_40k_UI_unreal\scripts\Start-Client.ps1' -CoreMode Managed -CoreVersion '46.0.0' -Port 19148 -ClientExecutable 'C:\SWDev\warhammer\.local\manual-client\p3a\ae423d0\Windows\WarhammerClient\Binaries\Win64\WarhammerClient.exe'
```

The actual path is also saved in `.local/p3a-client-executable.txt`. Keep the whole Windows folder together. Other checkouts must prepare their own matching runtime and follow the complete build/copy steps below. The prepared package is a workstation artifact, not a source-tree executable.

## Prepare and compile

Prerequisites: native Windows x64, PowerShell7, Git, `uv`, native Python3.14, UE5.8.3 with the existing C++ toolchain. The reference Core Git repository must contain the selected commit; fetching is safe, checking out/resetting that sibling is not part of these instructions. Keep existing44.5/44.3 environments and packages intact.

On a fresh checkout only, create the separate46 source/runtime. This command refuses existing destinations; if one exists inspect its provenance and prior result instead of deleting or overwriting it:

```powershell
Set-Location -LiteralPath 'C:\SWDev\warhammer\Warhammer_40k_UI_unreal'
$taskNativePython = 'C:\Users\Rabid\AppData\Roaming\uv\python\cpython-3.14.5-windows-x86_64-none\python.exe'
& ./scripts/Prepare-CoreDevelopmentRuntime.ps1 -CoreVersion '46.0.0' -PythonExecutable $taskNativePython
```

Build/cook without a visible window, copy the **entire** archived Windows folder to a fresh outside-checkout location and save its actual executable path. Do not copy just the executable or use a source-relative binaries path:

```powershell
Set-Location -LiteralPath 'C:\SWDev\warhammer\Warhammer_40k_UI_unreal'
$ErrorActionPreference = 'Stop'
$package = & ./scripts/Build-ClientPackage.ps1 -EngineRoot 'C:\Program Files\Epic Games\UE_5.8'
$taskCopy = Join-Path (Split-Path (Get-Location).Path -Parent) ('p3a-client-' + [guid]::NewGuid().ToString('N'))
Copy-Item -LiteralPath (Join-Path $package.archive 'Windows') -Destination $taskCopy -Recurse -ErrorAction Stop
$taskExe = Join-Path $taskCopy 'WarhammerClient/Binaries/Win64/WarhammerClient.exe'
if (!(Test-Path -LiteralPath $taskExe -PathType Leaf)) { throw 'Copied executable is missing.' }
New-Item -ItemType Directory -Path './.local' -Force | Out-Null
Set-Content -LiteralPath './.local/p3a-client-executable.txt' -Value $taskExe -Encoding utf8
Get-FileHash -LiteralPath $taskExe -Algorithm SHA256
& ./scripts/Test-ClientPackage.ps1 -ClientExecutable $taskExe -Mode Resources
& ./scripts/Test-ClientPackage.ps1 -ClientExecutable $taskExe -Mode Core -CoreMode Managed -CoreVersion '46.0.0' -Port 19148
```

Keep failures and package logs. The two tests above are non-visible and do not satisfy P3A-V1/V2. Independent SOURCE results are also required before visible acceptance.

Run the required non-visible Unit gate against the just-built Editor module. This block defines its own report path and checks the structured result; preserve any failure. The coordinator uses a bounded owned-process runner for the same command. If this reproduction command does not exit within three minutes, stop this owned command and retain its logs rather than reporting a pass.

```powershell
Set-Location -LiteralPath 'C:\SWDev\warhammer\Warhammer_40k_UI_unreal'
$ErrorActionPreference = 'Stop'
$taskUnitReport = Join-Path (Get-Location).Path ('.local/unit-reproduction-' + [guid]::NewGuid().ToString('N'))
& 'C:\Program Files\Epic Games\UE_5.8\Engine\Binaries\Win64\UnrealEditor-Cmd.exe' (Join-Path (Get-Location).Path 'WarhammerClient.uproject') -NullRHI -RenderOffScreen -unattended -nosplash -nosound -NoCrashDialog -NoLiveCoding "-ReportExportPath=$taskUnitReport" '-ExecCmds=Automation RunTests Warhammer.LiveCore.Unit' '-TestExit=Automation Test Queue Empty'
if ($LASTEXITCODE -ne 0) { throw 'Native Unit process failed; preserve its report/logs.' }
$taskUnitResult = Get-Content -LiteralPath (Join-Path $taskUnitReport 'index.json') -Raw | ConvertFrom-Json
if ($taskUnitResult.succeeded -ne 28 -or $taskUnitResult.tests.Count -ne 28 -or $taskUnitResult.failed -ne 0 -or $taskUnitResult.succeededWithWarnings -ne 0 -or $taskUnitResult.notRun -ne 0 -or $taskUnitResult.inProcess -ne 0) { throw 'Expected 28 successful Unit tests for this exact P3a source.' }
if (@($taskUnitResult.tests | Where-Object { $_.state -cne 'Success' -or $_.errors -ne 0 -or $_.warnings -ne 0 }).Count -gt 0) { throw 'A Unit test failed or emitted a warning.' }
$taskUnitResult | Select-Object succeeded, failed, notRun
```

## P3A-V1: Managed roster and handoff

From a fresh shell after preparation/build/copy:

```powershell
Set-Location -LiteralPath 'C:\SWDev\warhammer\Warhammer_40k_UI_unreal'
$taskExe = (Get-Content -LiteralPath './.local/p3a-client-executable.txt' -Raw).Trim()
& ./scripts/Start-Client.ps1 -CoreMode Managed -CoreVersion '46.0.0' -Port 19148 -ClientExecutable $taskExe
```

1. Connect/create; inspect supplied public army/player/faction/detachment/unit selections, Warlord and Enhancement bearers, and attachment/cargo disclosure. IDs are source identities, not invented names or current formation. Distinguish unavailable, empty and undisclosed notices where actually emitted; native tests cover states the live example does not emit.
2. Zoom the board. Scroll through the roster and back to the action controls; panel wheel/F must not move the board. Check wrapping/readability and normal Maximize/Restore if supported.
3. Make one offered setup choice and Refresh. Inspect current source-backed roster/result; no roster editing or new action exists.
4. Hand off; outgoing roster/board/options/ID must be absent before Ready. Enter player-b and inspect current permitted disclosure; make their offered choice, Refresh and hand back through the empty screen.
5. Close normally within ten minutes. Managed must stop only its owned host. Record actual observations separately from native request-count assertions.

## P3A-V2: Attach failed handoff and reopen

Terminal1: keep the existing selected development server alive through both clients, then stop it normally with Ctrl+C after terminal2's final health check.

```powershell
Set-Location -LiteralPath 'C:\SWDev\warhammer\Warhammer_40k_UI_unreal'
& ./.local/core-46.0.0/Scripts/python.exe -I -B ./.local/core-source-46.0.0/scripts/run_phase18m_reference_server.py --host 127.0.0.1 --port 19149
```

Terminal2, fresh shell:

```powershell
Set-Location -LiteralPath 'C:\SWDev\warhammer\Warhammer_40k_UI_unreal'
$taskExe = (Get-Content -LiteralPath './.local/p3a-client-executable.txt' -Raw).Trim()
$taskSavedPlayerB = [Environment]::GetEnvironmentVariable('WH_CORE_PLAYER_B_TOKEN', 'Process')
try {
    $env:WH_CORE_PLAYER_B_TOKEN = 'diagnostic-invalid-player-b'
    & ./scripts/Start-Client.ps1 -CoreMode Attach -CoreVersion '46.0.0' -Endpoint 'http://127.0.0.1:19149/' -ClientExecutable $taskExe
} finally {
    [Environment]::SetEnvironmentVariable('WH_CORE_PLAYER_B_TOKEN', $taskSavedPlayerB, 'Process')
}
& ./scripts/Start-CoreDevelopmentServer.ps1 -Mode Attach -CoreVersion '46.0.0' -Endpoint 'http://127.0.0.1:19149/' | Select-Object status
& ./scripts/Start-Client.ps1 -CoreMode Attach -CoreVersion '46.0.0' -Endpoint 'http://127.0.0.1:19149/' -ClientExecutable $taskExe
& ./scripts/Start-CoreDevelopmentServer.ps1 -Mode Attach -CoreVersion '46.0.0' -Endpoint 'http://127.0.0.1:19149/' | Select-Object status
```

1. First client: create/choose as player-a, inspect roster and copy the session ID privately. Hand off/Ready must show actual HTTP401 and no outgoing roster/board/private details. Close normally; the host survives.
2. Ordinary client: paste that ID and Open. Confirm same current player-a public roster/local count0; make a choice only if Core offers one. Hand off/Ready successfully to player-b and inspect their permitted roster. Close normally, then confirm both authenticated health checks passed and stop terminal1's host.

Keep each launch under ten minutes. For both criteria record tester/UTC, exact source/package executable SHA256/Core SHA/build/resources, actions/results and private screenshot/log locations. Never publish real session IDs, credentials or generated seeds. Keep failed/blocked/not-run boxes unchecked. Native Linux, clean-machine and actual held-button/OS-switch/teardown remain deferred; these tests do not establish full gameplay or visual-style acceptance of a future first-class interface.
