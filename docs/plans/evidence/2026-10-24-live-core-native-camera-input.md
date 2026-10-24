# Bounded native camera input check

The Windows D3D12 game run at `4e6518b5439aadde6faadd20f89727ba5961213f` passed `Warhammer.Rendered.LiveCoreCamera.Input`: **one test, 92 assertions, zero failures or warnings**. Its automation duration was 0.749 seconds; the supervised process ran for 20.492 seconds within the approved 600-second limit, then exited normally with code 0. Four Config files stayed unchanged and the final observed game-window count was zero. The native Error/Fatal scan and stderr byte count were both zero.

This test delivered actual in-application AutomationDriver events to the ordinary live GameMode's Slate widgets and observed the actual CameraActor. It used explicitly synthetic advisory camera bounds, a disconnected client and no Core credentials or service. A passive screenshot confirmed one visible game window with the expected unconnected black viewport; no operating-system input was issued during the driver sequence. The screenshot does not itself show camera motion or establish rendered-board fit.

The successful assertions cover:

- RMB hold/capture, orbit movement, matching release and unchanged navigation on a subsequent move without a held button.
- MMB hold/capture, pan movement, matching release and the same post-release stability check.
- Wheel zoom and both observed distance clamps.
- Endpoint focus and UI-focused F/wheel input preserving the camera without acquiring board capture.
- Refocusing the board, routed F restoring a previously observed fitted actor/navigation reference after pan/zoom, and a second F preserving that reference.
- Unchanged available session/request/choice/command observations, plus normal cleanup restoration of navigation, actor pose, zoom limits, keyboard focus and the owned driver handler.

Snapshot invariance does not prove zero attempted HTTP. Synthetic bounds do not establish real-Core semantics or rendered-board fidelity. The separate [manual-launcher run](2026-10-24-live-core-camera-visible.md) supplies actual startup navigation, Core board framing across observed outer window sizes, Frame board, UI wheel isolation, refresh and accepted-choice evidence. Its repeated F attempts did not restore framing. That manual failure remains recorded with no established source cause; the native routed-key result does not overwrite it.

The test was invoked in a dedicated `-game -unattended` process with both `-LiveCoreCameraInputProof` and `-LiveCoreCameraInputProofOwnedProcess`, `-d3d12`, and Unreal-compatible value quoting for `-ExecCmds="Automation RunTests Warhammer.Rendered.LiveCoreCamera.Input"` and `-TestExit="Automation Test Queue Empty"`. The engine selected exactly this one test and exited at queue empty. The retained process supervisor enforced the outer limit. Failure termination and watchdog paths were not exercised by this successful run.

Four candidate builds passed: `c3a751e` (six actions, 21.94 seconds, including a memory-pressure retry), `91174a8` (six, 13.72 seconds), `08f5c69` (six, 12.79 seconds) and `4e6518b` (four, 6.30 seconds). Earlier source reviews requested stronger cleanup, assertion coverage and runner quoting; no native visible run occurred at those rejected candidates. Fresh CODE and separate REQ both passed affected SOURCE at `4e6518b` before this run. All 38 frozen inputs and ten Git blobs matched before source inspection and after review. Build-source identity includes the documented LF/CRLF reconciliation; it is not binary attestation. The companion JSON retains the review history and private artifact digests.

Escape, unexpected capture loss, focus loss/deactivation/resize/teardown during an active drag, mismatched user/pointer delivery and panel RMB/MMB gestures have no positive runtime result here. Fresh-install execution, broader DPI/readability, packaging and Linux build/render/package remain unverified. Private screenshots, raw reports/logs, process/session identifiers and credential values are excluded from publication.
