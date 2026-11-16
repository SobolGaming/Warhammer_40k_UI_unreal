# Retained P2b 44.5 manual testing

This guide repeats the merged P2b 44.5 workflow only. Current P2c 46 instructions and verification criteria are in [P2c manual testing](p2c-manual-testing.md). P2b revisions1/2/3 below must not be applied to Core 46 viewer revisions. The owner reported these manual tests passed before PR #8 merged as 6e76f4a.

The [canonical migration plan](../plans/unreal-migration-plan.md#required-p2b-manual-verification) owns the P2B-V1/V2 criteria. This guide supplies their complete setup and reproduction commands. Use PowerShell 7 on native Windows x64. Run one game window at a time; allow up to ten minutes per verification launch.

## Run the prepared copy on this workstation

The complete P2b Windows package has been copied to `C:\SWDev\warhammer\.local\manual-client\p2b\Windows`. Its matching Core 44.5 environment is already prepared in this repository. Run this whole command in PowerShell 7; no earlier variable assignments or compilation are needed:

```powershell
& 'C:\SWDev\warhammer\Warhammer_40k_UI_unreal\scripts\Start-Client.ps1' -CoreVersion 44.5.0 -CoreMode Managed -Port 19128 -ClientExecutable 'C:\SWDev\warhammer\.local\manual-client\p2b\Windows\WarhammerClient\Binaries\Win64\WarhammerClient.exe'
```

The command starts the matching development Core, waits for readiness and opens the standalone game. Close the game with its X button or Alt+F4; the launcher then stops its owned Core and returns to the prompt. Start only one Managed client on this port. Its development sessions exist in memory and disappear when Core stops.

The prepared package is the frozen P2b runtime source `a6dbb1c`, executable SHA256 `95e6b03a53292e353458a554696e0351e71caab96c6804744bbff8fc3dd501b2`. Current P2c source targets Core 46 and does not reproduce this old executable. Use the [P2c guide](p2c-manual-testing.md) for current compilation and verification. This local, ignored folder is supplied for this workstation; a new checkout needs the build instructions below. Keep the complete Windows folder together.

## Why the earlier commands failed

`WarhammerClient/Binaries/Win64/WarhammerClient.exe` is a path **inside a packaged Windows folder**, not a source-repository path. Building the project creates a separate archive; `Start-Client.ps1` only launches an existing executable.

`$taskExe` is a PowerShell variable, not a built-in project setting. It is empty in a new shell until assigned. Every client-shell block below assigns it explicitly. The prepared-copy command above uses the absolute path directly.

## P2B-V1: two-player handoff

Use the Managed command above with ordinary development credentials. The launcher supplies missing development credential values from the pinned Core source; no token entry is needed.

1. Click **Connect / create session**. The board and player-a's offered secondary-mission choices should appear at revision1, with **Accepted actions in this view: 0**.
2. Click one **Submit now** choice, such as **Fixed assassination bring_it_down**. This submits immediately. Wait for Core's committed result, then click **Refresh viewer state**. Expect revision2, local count1, your own mission and an explicit hidden opposing decision.
3. Click **Hand off to the other local player**. Before clicking Ready, verify the board, mission, options, previous receipt/error and session-ID field are cleared. The privacy screen must name player-b and remain hidden.
4. Click **Ready: show player-b**. Expect the same session/revision2, viewer player-b, local count0 and only that player's offered choices. Player-a's private mission must be absent.
5. Submit a distinct player-b choice, such as **Tactical**, then Refresh. Expect Core's committed result and revision3.
6. Hand off again. Verify the empty privacy screen before clicking **Ready: show player-a**. Expect revision3, local count0, player-a's own mission and no player-b private mission. Stop this test here; complete battle progression is outside P2b.
7. Click the board before camera testing. The wheel zooms; **F** fits the board into view. F while a UI field has focus and the wheel over the panel must stay with UI. **Frame board** explicitly restores framing. Real held right/middle-button and OS-switch tests remain separate deferred criteria.
8. Close the client normally and wait for the launcher to return. Record the actual result, date, executable/Core identities and any screenshots privately. Earlier automated/visible evidence does not record the outcome of your new run.

## P2B-V2: failed read and recovery with Attach

This test uses two PowerShell 7 terminals. Core must stay alive between the two sequential clients so the copied session ID remains valid. First close any Managed client from V1.

In **terminal 1**, start the existing selected Core in the foreground:

```powershell
Set-Location -LiteralPath 'C:\SWDev\warhammer\Warhammer_40k_UI_unreal'
& ./.local/core-44.5.0/Scripts/python.exe -I -B ./.local/core-source-44.5.0/scripts/run_phase18m_reference_server.py --host 127.0.0.1 --port 19129
```

Wait for its `Serving Phase 18M reference contract at http://127.0.0.1:19129` message. Leave terminal 1 running. In **terminal 2**, launch the first client with an intentionally invalid player-b credential, restoring the shell value on exit:

```powershell
Set-Location -LiteralPath 'C:\SWDev\warhammer\Warhammer_40k_UI_unreal'
$taskExe = 'C:\SWDev\warhammer\.local\manual-client\p2b\Windows\WarhammerClient\Binaries\Win64\WarhammerClient.exe'
$taskSavedPlayerB = [Environment]::GetEnvironmentVariable('WH_CORE_PLAYER_B_TOKEN', 'Process')
try {
    $env:WH_CORE_PLAYER_B_TOKEN = 'diagnostic-invalid-player-b'
    & ./scripts/Start-Client.ps1 -CoreVersion 44.5.0 -CoreMode Attach -Endpoint 'http://127.0.0.1:19129/' -ClientExecutable $taskExe
} finally {
    [Environment]::SetEnvironmentVariable('WH_CORE_PLAYER_B_TOKEN', $taskSavedPlayerB, 'Process')
}
```

1. Connect/create as player-a and submit one offered mission. Copy the displayed session ID with field focus, Ctrl+A, Ctrl+C **before** handing off.
2. Hand off and click Ready for player-b. Expect **HTTP401**, `authentication_required`, **A valid bearer credential is required.** The outgoing board, mission, options and receipt must stay hidden. Ready may retry the read; no new session should be created automatically.
3. Close the client normally. Terminal 1 must keep Core running. Wait until terminal 2 returns to its prompt so the credential has been restored.

Then run this full block in **terminal 2** with ordinary credentials:

```powershell
Set-Location -LiteralPath 'C:\SWDev\warhammer\Warhammer_40k_UI_unreal'
$taskExe = 'C:\SWDev\warhammer\.local\manual-client\p2b\Windows\WarhammerClient\Binaries\Win64\WarhammerClient.exe'
& ./scripts/Start-Client.ps1 -CoreVersion 44.5.0 -CoreMode Attach -Endpoint 'http://127.0.0.1:19129/' -ClientExecutable $taskExe
```

4. Paste the copied ID and click **Open existing session**. Expect player-a on the retained session/revision with local count0 and their own mission. Click Hand off, inspect the empty screen, then Ready. Player-b's own view should now load successfully.
5. Verify readable target/viewer/status text and panel input isolation. For a visible F check, zoom the board, focus/select text in the ID field, then press F: the board should stay zoomed. Panel wheel input should not zoom the board. During handoff, clicks/wheel/F on the privacy screen must not reveal the board or act as Ready. Panel content may fit the window without scrolling.
6. Close normally. Confirm terminal 1 is still serving; then stop only that foreground Core with Ctrl+C in terminal 1. Record your actual result. Do not publish real session IDs or credentials in the PR.

## Build a new standalone package from this checkout

Current source builds the P2c Core 46 candidate. Use the [complete P2c preparation/build/copy guide](p2c-manual-testing.md); do not pair that new package with the old 44.5 commands above. The already prepared P2b copy is retained for historical regression only. Its original compilation/copy recipe is preserved in the merged [PR #8 source](https://github.com/SobolGaming/Warhammer_40k_UI_unreal/blob/f2b1f9706a29247f38a8a589fc88afc23dc5ac9a/docs/development/manual-testing.md#build-a-new-standalone-package-from-this-checkout). Rebuilding historical source requires a separate exact checkout and matching runtime; a current-branch build does not reproduce it.

## Prepare Core on a fresh checkout only

The current workstation already has `.local/core-source-44.5.0` and `.local/core-44.5.0` with Managed provenance. Do not run preparation over them. The [Core startup guide](core-startup.md#preserved-4450-and-44333-previews) distinguishes retained profiles from current46 setup; the explicit command below prepares only44.5. Never overwrite the existing old environment.

On a fresh checkout, install the listed prerequisites (Git, `uv`, a physical native Python 3.14 interpreter) and ensure the selected Git object `4f9bef0df2fb974d1285232a1009b8781926361d` is available in the reference repository. Then run the preparation command below with the actual interpreter path. The example is this workstation's physical Python installation:

```powershell
Set-Location -LiteralPath 'C:\SWDev\warhammer\Warhammer_40k_UI_unreal'
$taskNativePython = 'C:\Users\Rabid\AppData\Roaming\uv\python\cpython-3.14.5-windows-x86_64-none\python.exe'
& ./scripts/Prepare-CoreDevelopmentRuntime.ps1 -CoreVersion 44.5.0 -PythonExecutable $taskNativePython
```

Preparation creates a separate pinned source/runtime and verifies build identity/resources. It refuses existing destinations. If a destination exists but is incomplete, inspect its retained preparation results before choosing a repair; do not delete or reset the reference Core checkout. A plain pip install supplies no Managed provenance, so use the documented foreground/Attach route for that alternative.

## Startup problems

- **Required client file is missing:** use the complete prepared absolute command, or build/copy above. A source-relative `WarhammerClient/Binaries/...` path is not the archived package.
- **ClientExecutable is null or empty:** run the full block that defines `$taskExe`, or use the no-variable prepared-copy command.
- **Core port is already occupied:** close your owned Managed client normally, or choose a different unused port. Attach to a deliberately retained matching Core; never stop an unrelated service by port or name.
- **Unexpected HTTP401/403 outside the intentional V2 test:** the helpers respect existing process credential overrides. Use ordinary development credentials in that shell; the V2 block restores only its player-b diagnostic override. Keep credential values private.
- **Black board before Connect:** expected. After Connect, use the displayed HTTP/error message and managed logs under `.local/development/core-host/<run>` to diagnose it.
- **Missing/broken Core runtime:** use the startup guide and retained receipt; starting a client does not install or repair Core automatically.
