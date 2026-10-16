# E02 Windows world/input architecture proof — proposed packet

Date: 2026-10-16. Status: **PLANNING ONLY; E02 NOT RUN**. This is the next
reviewable subset of E02, conditional on accepted E01 evidence and a recorded
review of the applicable execution authority. OWN13 permits continuation through
the next bounded gate; it is not blanket permission for new scaffolding or every
E02–E08 experiment. This packet itself grants no execution authority.

Read with [canonical Section 0/RQ05/RQ09/RQ10/RQ12/RQ20/RQ23 and E02](../unreal-migration-plan.md),
[BOOT01 results](../evidence/2026-10-16-boot01.md),
[geometry contract](2026-10-16-contract-integration.md#rq09--open-mapping-source-established-asymmetric-axis-discrepancyproof-remains),
[selected target adaptation](2026-10-16-contract-44-3-33-adaptation.md), and
[input ownership table](2026-10-16-parity-closure-design.md#complete-event-ownership-focus-cancellation-and-retry-policy).
The coordinator owns acceptance/authority reconciliation; the eventual proof
implementer owns source, wrapper and one isolated process tree. Separate read-only
source review and acceptance audit are required against frozen hashes.

## Bound and intended result

Prove a small C++ fixture can preserve units, basis, nonzero origin/Z and identity
through genuine perspective rendering, world-ray picking, cosmetic substitution
and explicit HUD/camera input ownership. Use this existing project and installed
UE 5.8.3; stage a frozen textual source copy for the run. No Core connection,
Python host, session, rule choice or authoritative mutation exists in this proof.
The scene and local intent records must visibly say **SYNTHETIC / ADVISORY — NO
GAME SESSION**. A local ready state must never display an accepted game result.

This subset can supply architecture evidence for D08/D09 and RQ09/RQ10, plus the
small HUD interception seam in RQ12. It cannot accept all E02/M02, E04 profile/HUD
compatibility, M03 playable gameplay, packaging/cooking, performance or Linux.
Linux targets/seams remain required; Linux build/render/package are owner-deferred
**NOT RUN** under OWN08 and do not block this separately authorized Windows proof.
No tools, drivers, dependencies, art, cloud hosts or storage policies are added.

## Exact proposed authored scope

All paths below are relative to `Warhammer_40k_UI_unreal/`. They are future files
or future permitted deltas, not files created by this planning task. Keep the proof
inside the existing module; do not create the planned production plugin/module tree.

| File | Permitted responsibility |
|---|---|
| `WarhammerClient.uproject` | Explicit reference to the already installed `ProceduralMeshComponent` engine plugin; no content/plugin download. |
| `Source/WarhammerClient/WarhammerClient.Build.cs` | Runtime `InputCore`, `Slate`, `SlateCore`, `ProceduralMeshComponent`, `RHI`; `AutomationDriver`/`ApplicationCore` only with developer-tools/test guards. No editor module dependency. Preserve E01 dependencies. |
| `Source/WarhammerClient/Private/Migration/E02Geometry.h`, `.cpp` | Double precision frame/shape values, exact inverse, independent advisory ray queries and display tessellation. |
| `Source/WarhammerClient/Private/Migration/E02InputPolicy.h`, `.cpp` | Capture generation, ownership and local draft/review state; no transport. |
| `Source/WarhammerClient/Private/Migration/E02WorldProofGameMode.h`, `.cpp` | Opt-in reflected GameMode/controller, runtime perspective rig, transient meshes and Slate proof surface. Require both explicit GameMode URL and `-E02Proof`; normal GameMode remains unchanged. |
| `Source/WarhammerClient/Private/Tests/E02GeometryTests.cpp` | Four proposed numeric tests below. |
| `Source/WarhammerClient/Private/Tests/E02WorldInputTests.cpp` | Four rendered and eight input tests; driver lifecycle/cleanup and artifacts. Guard with development automation support; never ship a test driver dependency. |
| `tests/migration/fixtures/e02/world-input-v1.json` | Versioned synthetic fixture, expected dimensions/coordinates/IDs/camera settings; no private or copied session data. |
| `scripts/migration/Invoke-E02WorldProof.ps1` | Reviewed preflight, immutable staging, bounded subprocesses, result-count/artifact validation and owned-process cleanup. |
| `docs/plans/evidence/2026-10-16-e02-world-input.md`, `2026-10-16-e02-world-input-result.json` | Actual attempts, exact candidate/authority/reviews, per-test results and artifact hashes; do not prefill PASS. |

This is 14 exact future authored paths, counting each `.h`/`.cpp` separately.
No `Config/`, existing E01 source/fixtures, default GameMode, Content assets,
Arcade/Core files, lockfiles, installed-engine files or global configuration may
change. Any additional file/dependency needs a reviewed packet delta first.
Canonical plan status/link updates belong to the coordinator after evidence exists.

## Geometry and camera fixture

Use domain bounds X `[-12,60]`, Y `[7,55]` inches; center `(24,31)`; datum `z0=-2`.
Map `q=2.54*(x-24, -(y-31), z+2)` centimetres, then rigid presentation placement
`T`: translation `(137,-83,41)` cm and yaw `23°`, unit scale. The inverse applies
`T^-1` then `(24+qx/2.54,31-qy/2.54,-2+qz/2.54)`. A separate numeric case uses
presentation pitch `12°`/roll `-7°`; this introduces no gameplay roll/pitch fields.
Map heading by its basis `(cos θ,sin θ,0)` through the reflection and `T`;
horizontal pre-placement UE yaw is `-θ`. Do not negative-scale the Actor tree.

Keep five stable fixture model IDs. Circle radius `1`, ellipse length-X `5` /
width-Y `2` at `90°`, rectangle length-X `4` / width-Y `2` at `37°`, capsule total
length `6` / width `2`, and asymmetric convex polygon local vertices
`[(0,0),(3,0),(2,1),(0,2)]` at `30°`. Their stable IDs and poses are respectively
`e02-circle=(8,18,-2,0°)`, `e02-ellipse=(42,23,2,90°)`,
`e02-rectangle=(30,20,2,37°)`, `e02-capsule=(18,38,-2,0°)` and
`e02-polygon=(43,39,-2,30°)`. Advisory query extrusion heights are `1.2`, `1.0`,
`1.5`, `1.2`, `1.2` inches respectively; visual shallow-base thickness is `0.12`.
Platform bounds X `[25,48]`, Y `[15,29]`, Z `[-2,2]` have an open rectangular hole
X `[34,36]`, Y `[22,24]`; render four slabs around the hole so it is visible.
Rectangle/ellipse rest on the platform. The four-inch support separation must be visible.
Capsule is a synthetic presentation capability, never a new canonical Core kind.

Core `5f509724da25a2f6ded0c2739a8e7c84bdf59c91:src/warhammer40k_core/`
`adapters/battlefield_projection.py:_footprint_part_shape:491–531` and
`geometry/base.py:OvalBase/RectangularBase:73–142` establish length on local X,
width on local Y. `_normalized_polygon:698–708` normalizes positive domain area.
The existing Arcade axes mismatch must not be copied. Reflection flips winding;
reverse generated triangle order and validate upward normals/visible top faces.

Use transient `UProceduralMeshComponent` shallow opaque footprint meshes with
labelled local +X/+Y marks and asymmetric color sectors; no texture import is
needed to expose orientation. Use installed `/Engine/Maps/Entry` as the blank
world and `/Engine/BasicShapes/Cube.Cube` for board/platform and ordinary-mesh
substitution; the installed BasicShapeMaterial may supply a transient tinted
material instance. Add a transient fixed directional light and locked exposure;
record their settings so the blank Entry world is not dependent on editor lighting.
Record engine asset path/hash provenance. No `.umap`/`.uasset`
is authored or saved. Fail missing asset loads visibly.

Separate immutable support/measurement descriptors, selection query, and visual
mesh. For this small proof, compute nearest positive world-ray intersections in
table coordinates against bounded support planes and descriptor-derived extruded
selection volumes; this is advisory picking, never collision-based legality.
Visual collision is disabled. Missing/unknown required dimensions or null pose
produce a typed unsupported diagnostic, not origin/default/cube geometry. Display
tessellation cannot become the analytic query. Include a support hole/edge miss
and a ray that hits raised support before the ground. Preserve raw domain Z in
every local intent record; cosmetic anti-Z-fighting offsets never return through
the inverse. No snapping or out-of-board clamping is introduced.

Create an actual runtime perspective camera (initial vertical angle `45°`, FOV
`50°`), plus `25°` oblique and near-top proof views. Implement orbit, table-plane
pan, bounded dolly, frame-board/selection and reset with explicit focus. Record
projection matrix, camera pose, viewport pixels and UI scale for each capture.
Cube substitution changes only the visual branch: IDs, support/measurement
descriptors, query result and serialized **local advisory intent** stay identical.
There is no submitted command whose semantics this fixture can prove.

## Actual input route and its limits

Attach one C++ Slate proof surface to the game viewport. Its pointer/key/focus
handlers are the runtime route used by both a user and AutomationDriver: platform
message handler → Slate hit test/capture/focus → proof surface/widget handler →
ownership policy → camera/local intent/world-ray query. Input tests must drive
that route with screen positions/keys; directly calling the reducer, camera
method or selection setter cannot pass an input case. Numeric tests may call the
pure policy helpers and are reported separately.

Use one full-window pixel-to-viewport adapter for `APlayerController` projection/
deprojection, and Slate logical hit geometry/scale for HUD exclusion and the
four-logical-unit drag threshold. Never subtract sidebar width from deprojection
or apply DPI twice. Show a HUD button, disabled control, blank visible background,
scroll region, editable text and modal. Pick owner on press; keep it across panel
crossings and release. Orbit/pan/wheel/hover/selection/cancel send zero commands.
The proof has no submit port: repeated Confirm enters local Ready, then visibly
rejects submission as `ProofHasNoGameSession`; it must not fabricate acceptance.

Installed AutomationDriver moves a simulated cursor and sends mouse/key events
through the real application's message handler. This can demonstrate Slate input
routing and runtime behavior in a rendered game viewport. It does **not** prove
physical mouse/keyboard delivery, OS focus switching, manual usability, remote
desktop input or packaged input. Enable it only in the owned proof process and
restore it on completion/failure. Native computer-control tools are unavailable
in this session; do not invent a human interaction check.

For focus loss use Slate's public application-activation event path; for resize
use the owned `SWindow::Resize` and wait for actual new viewport geometry. Record
these as **engine-injected activation / programmatic resize**, not OS Alt-Tab or
human window dragging. Replay any incomplete driver action as failure, not a skip.
An available desktop/RHI and reachable game window are prerequisites, even with
`-unattended`. Screenshot inspection can be performed on saved PNGs; human
interaction remains `NOT RUN` unless a named person later records it separately.

## Proposed suite and acceptance artifacts

The following names/counts are a specification, not an existing registered suite.
Discover and freeze **16 exact names** after implementation; fail empty/missing/
extra discovery, skipped/not-run cases, crashes, timeout or missing result data.
Log assertion counts separately from test counts. Prefix: `Warhammer.Migration.E02`.

| Suffix | Count | Required assertions / artifacts |
|---|---:|---|
| `Numeric.RoundTrip` | 1 | Units, nonzero center/datum and rigid placements; points both sides of origin; ≤`1e-8` inch double round trip. |
| `Numeric.HeadingAxes` | 1 | `0/90/37°`, length-X/width-Y, handed basis, inverse heading modulo 360; ≤`1e-8` degree. |
| `Numeric.ShapesWinding` | 1 | Five dimensions, polygon signed area/reversed triangles/up normals, independent analytic query boundary cases; explicit synthetic capsule label. |
| `Numeric.UnsupportedGeometry` | 1 | Nonfinite/missing dimensions, unknown kind, null pose and invalid polygon fail with exact typed diagnostic; no generated substitute. |
| `Rendered.FiveForms` | 1 | Genuine perspective, all five forms/local axes distinguishable, correct silhouettes/extents; `five-forms.png`, scene/geometry dump. |
| `Rendered.RaisedPicking` | 1 | Project → deproject → nearest raised/ground/support-hole/edge/query hits; domain hit ≤`1e-4` inch, projected round trip ≤1 physical pixel; `raised-pick.png`, ray dump. |
| `Rendered.MeshSubstitution` | 1 | Same-ID cube replacement preserves descriptors, selection and local intent bytes; before/after PNGs and identity/query diff. |
| `Rendered.ObliqueNormals` | 1 | 25° and near-top views expose winding, height, orientation/occlusion; `oblique.png`, `near-top.png`; no flat-camera substitute. |
| `Input.CompletedClick` | 1 | Release commits local selection once; press/hover/drag does not; actual ray/ID trace. |
| `Input.CameraCapture` | 1 | Right movement below/above 4 logical units, orbit crossing HUD and release; capture retained, no selection or leaked widget activation. |
| `Input.PanDollyFrame` | 1 | Middle-pan, viewport wheel, frame/reset and keyboard orbit alternative change camera only; retain draft/domain values and zero submissions. |
| `Input.HudExclusion` | 1 | HUD button release outside cancels; disabled/blank/scroll-at-limit consumes; no world pick/dolly underneath. |
| `Input.ModalText` | 1 | Text consumes characters/Enter; first Escape cancels focused edit, later closes modal; no world shortcut leakage. |
| `Input.CancelActivation` | 1 | Escape/capture loss and injected deactivate during drag cancel candidate; reactivate never synthesizes click; renewed review required, coordinates retained. |
| `Input.ResizeScale` | 1 | Crossing gesture cancels; physical viewport extent updates; UI scales `1.0/1.5` at `1280×720`, plus `1600×900` at `1.0`; same intended ray/hit and HUD exclusion without double DPI. |
| `Input.RepeatedConfirm` | 1 | Repeated Confirm/Escape and local Ready transitions never submit; visible `ProofHasNoGameSession`, no success/acceptance record. |

Rendered/input baseline is `1280×720`, UI scale `1.0`; the resize test alone adds
the named variants. This is a bounded input-adapter check, not the E04/E08 full
responsive-layout/DPI matrix. Require per-event JSONL with sequence/time, screen
and viewport pixels, logical coordinates/scale, hit widget/owner, capture/focus
generation, camera before/after, stable IDs, local draft/review transition and
submission-attempt/result counters. Counts must be zero for actual transport
creation and game commands in all 16 tests. This is a fixture invariant, not proof
of a production transport's behavior. No credentials or hidden state enter traces.

Save at least six named PNGs above, viewport/camera/RHI/geometry/ray JSON, input
JSONL, Automation discovery/export JSON/HTML, process stdout/stderr and native log.
Check actual PNG dimensions/decoding and nonblank framebuffer content; geometry
assertions and visual inspection must both pass. Record screenshot inspection
findings against the fixture/axes/raised-surface expectations. No unreviewed image
becomes a golden baseline; visual inspection is distinct from pixel comparison.

## Toolchain, processes, paths and future commands

Reuse BOOT01's UE **5.8.3 / CL58210709**, bundled .NET **10.0.203**, VS2022
**17.14.37710.0**, MSVC **14.44.35229** (folder `14.44.35207`) and Windows SDK
**10.0.22621.0**. Recheck exact files/hashes/compiler selection before build;
do not install an alternative. Read-only display registry on 2026-10-16 lists
NVIDIA RTX 4090 driver `32.0.15.9186` (two entries) and AMD Radeon Graphics
`32.0.21030.2001`. CIM GPU access failed. Registry inventory proves neither active
adapter nor rendering. Runtime must log actual RHI, adapter/vendor/device, driver,
feature level, OS/display and viewport; require Direct3D 12 hardware rendering.
Unsupported D3D12 or a software/NullRHI adapter stops this scope; do not silently
fall back and call it rendering PASS.

Use fresh `.local/experiments/E02/<UTC>-<random>/` (`RunRoot`); reject existing,
reparse-point or escaping paths. Copy only the reviewed descriptor, `Source/` and
`Config/` snapshot to `RunRoot/project/`, then compare the complete staged source
manifest to the frozen candidate. Copy the synthetic fixture to `RunRoot/fixture/`.
Never copy `.git`, credentials, sibling data, existing Binaries/Saved or E01 runtime.
This stages the existing project; do not call the bootstrap creation wrapper.

| Owned output | Writer / retention |
|---|---|
| `project/Binaries/`, `project/Intermediate/` | Staged UBT/UHT/build; no canonical-project build output changes. |
| `ue-user/`, `ddc/`, `temp/`, `dotnet-home/`, `nuget/`, `uba/` | Subprocess-only UserDir/DDC/TEMP/TMP/.NET/NuGet/UBA settings; keep parent environment unchanged. |
| `logs/`, `reports/discovery/`, `reports/numeric/`, `reports/world-input/` | One supervisor/process at a time; exact command arrays, PIDs, start/end/exit and counts. |
| `artifacts/`, `manifest.json`, `result.json` | Proof/supervisor; screenshots, structured traces, hashes and explicit status for every case. |

The future reviewed wrapper must build with `Build.bat WarhammerClientEditor
Win64 Development -Project=<RunRoot/project/WarhammerClient.uproject> -WaitMutex
-NoUBA -UBARootDir=<RunRoot/uba> -Log=<RunRoot/logs/build.log>` and subprocess
`UBA_ROOT=<RunRoot/uba>`. It supervises the process tree with a 30-minute build
timeout and 10-minute limit per automation process. Use `Start-Process
-WindowStyle Hidden` for background supervision; do not attempt hidden/offscreen
rendering if it prevents the actual viewport/input evidence. Missing window/RHI
is a recorded blocker, not a reason to manufacture screenshots.

Future native invocations (all values absolute, arguments supplied as individual
process arguments by that wrapper):

```text
UnrealEditor-Cmd.exe <staged-uproject> -unattended -NullRHI -nosound
  -ExecCmds="Automation RunTest StartsWith:Warhammer.Migration.E02.Numeric;Quit"
  -ReportExportPath=<RunRoot/reports/numeric> <isolation-args>

UnrealEditor.exe <staged-uproject>
  /Engine/Maps/Entry?game=/Script/WarhammerClient.E02WorldProofGameMode
  -game -E02Proof -unattended -d3d12 -windowed -ResX=1280 -ResY=720 -nosound
  -ExecCmds="Automation RunTest StartsWith:Warhammer.Migration.E02.Rendered+StartsWith:Warhammer.Migration.E02.Input;Quit"
  -ReportExportPath=<RunRoot/reports/world-input> <isolation-args>
```

Before running filters, use a separate bounded `Automation List;Quit`
discovery invocation and require all 16 names. Installed
`AutomationCommandline.cpp:129–163` splits filters on `+` and supports `StartsWith:`;
the frozen wrapper must still validate the exact 4 numeric / 12 rendered-input
results. No claim that those suites already exist or commands have been exercised
is made here.

Use one `Automation` prefix for each semicolon command group. Installed
`ParseExecCommands.cpp:11–54` splits top-level `ExecCmds` only on commas;
`AutomationCommandline.cpp:565–586` consumes `Automation` once and then splits
its remainder on semicolons. Its queued-quit branch at `726–734` expects `Quit`,
so `;Automation Quit` does not queue the required automation-aware exit.

`isolation-args` must include explicit `-UserDir=<RunRoot/ue-user>`,
`-abslog=<RunRoot/logs/unique-phase.log>`,
`-E02Fixture=<RunRoot/fixture/world-input-v1.json>`,
`-E02Artifacts=<RunRoot/artifacts/phase>`, `-DDC-NoDefaultGraph` and a complete
custom cache replacement argument:
`-DDC=(E02=(Type=FileSystem,Path=<RunRoot/ddc>,DeleteUnused=false))`.
Use slash-normalized paths; reject quotes/parentheses in RunRoot rather than
building ambiguous command text. This complete node has no env/registry/editor
override keys and no Zen/shared/cloud nodes. Source supports the syntax; execution
must still confirm its selected graph/path and stop if a fallback occurs.

`-UserDir` redirects project user Saved/Intermediate, not every engine/user path.
Specifically, normal installed-engine EditorSettings remain under the per-user
engine settings directory: on this host,
`C:/Users/Rabid/AppData/Local/UnrealEngine/5.8/Saved/Config/WindowsEditor/EditorSettings.ini`
(absent at inspection). Also inspect user EditorSettings hierarchy layers before
execution; do not assume absent generated settings imply absent inherited values.
A plain `Local` DDC node has an EditorOverrideSetting
which is parsed after its command-line path; fresh project UserDir alone does not
prove it cannot override that path. The complete custom node avoids that inherited
key. Guard/hash existing settings before/after; never rewrite them. BOOT01's known
normal UBT environment XML/Trace.uba/config reads/writes must be declared in the
authority review: specifically UBT's existing
`C:/Users/Rabid/AppData/Local/UnrealEngine/Intermediate/Build/` and
`C:/Users/Rabid/AppData/Local/UnrealBuildTool/Trace.uba`, and its existing Roaming
`Unreal Engine/UnrealBuildTool/BuildConfiguration.xml`. Real rendering may write
ordinary per-user D3D/driver shader caches, including
`C:/Users/Rabid/AppData/Local/D3DSCache/` and
`C:/Users/Rabid/AppData/Local/NVIDIA/DXCache/`, outside RunRoot. Include that
bounded normal side effect in the execution-authority record; do not promise full
filesystem isolation or delete shared caches. Report known-path observations as
such. No new Zen/Core/web service, crash upload or external host is requested.

## Installed-source support, not runtime proof

Paths below are relative to `C:/Program Files/Epic Games/UE_5.8/Engine/`;
identity is Launcher 5.8.3/CL58210709, not an Epic Git SHA. Inspected 2026-10-16.

| Source / lines | Supported future mechanism |
|---|---|
| `Source/Developer/AutomationDriver/Public/IAutomationDriverModule.h:18–59`; `Private/AutomationDriverModule.cpp:49–94` | Driver creation, input interception, restoring the real platform application/message handler. |
| `Source/Developer/AutomationDriver/Public/IDriverSequence.h:476–491,708–720,786–798,891–898`; `Private/DriverSequence.cpp:920–975,1094–1121,1206–1312` | Position/move/press/release/perform; injected mouse/wheel/key events use the real handler. |
| `Source/Runtime/Slate/Public/Framework/Application/SlateApplication.h:1411,1691,1727–1738`; `Source/Runtime/SlateCore/Public/Widgets/SWindow.h:513–534` | Application activation, actual window/viewport resizing and observable geometry. |
| `Source/Runtime/Engine/Classes/GameFramework/PlayerController.h:735–742` | Screen deprojection/projection APIs; not a successful world hit by declaration. |
| `Source/Runtime/Engine/Public/UnrealClient.h:193–219,266–283` | Named screenshot requests/capture/processed delegates; wait for captured PNG output. |
| `Plugins/Runtime/ProceduralMeshComponent/Source/ProceduralMeshComponent/Public/ProceduralMeshComponent.h:169–196` | Runtime transient mesh construction without authored binary assets. |
| `Source/Runtime/RHI/Private/Windows/WindowsDynamicRHI.cpp:1064–1088,1239–1259`; `Source/Runtime/RHI/Public/DynamicRHI.h:215` | D3D12 selection/failure and runtime RHI identity. |
| `Source/Runtime/Core/Private/Misc/Paths.cpp:183–225,238–245,451–498,1940–1965`; `Source/Runtime/Core/Private/Misc/ConfigCacheIni.cpp:6650–6652` | Project UserDir versus normal engine EditorSettings; no all-writes containment claim. |
| `Config/BaseEngine.ini:2752–2776,2863–2868`; `Source/Developer/DerivedDataCache/Private/DerivedDataConfig.cpp:351–414,448–514`; `DerivedDataBackends.cpp:695–720`; `FileSystemCacheStore.cpp:3014–3057` | Full custom node syntax, suppressing default fallback and path-override precedence. |
| `Source/Developer/AutomationController/Private/AutomationCommandline.cpp:129–163,610–626,726–734,784`; `Source/Developer/AutomationController/Private/AutomationControllerManager.cpp:233–247` | Run/list/queued quit and report export; still verify discovered/executed counts. |
| `Source/Runtime/Engine/Private/ParseExecCommands.cpp:11–54`; `Source/Developer/AutomationController/Private/AutomationCommandline.cpp:565–586,726–734` | Comma-delimited top-level commands; one `Automation` prefix followed by semicolon subcommands such as `RunTest ...;Quit`. |

Source SHA256: `Build/Build.version` =
`EAB58750E84719489F3EE0D42D05A533CEB357EB3EE511777E9408D27A85F43C`;
`AutomationDriver/Private/DriverSequence.cpp` =
`988CCBC63FE8E36D728C6F4BAAD9C30E83E08DDCC7F2FCFFEE92580A157320E1`;
`AutomationDriver/Private/AutomationDriverModule.cpp` =
`E917AE1925402B487170C9A6CE23C856D790D5682A28F7717ACB815448A6F42E`;
`Core/Private/Misc/Paths.cpp` =
`B2069897033973C2D42966AD6B89811A06CC30A5DBFEF3BBEF4A2FD292028046`;
`Config/BaseEngine.ini` =
`04BBB301BE5C344F5387F15C1B543778A8DE5F13F36F8F77273528F49AF0E36D`.
`Source/Runtime/Engine/Private/ParseExecCommands.cpp` =
`9B8D2D78D61FD4E0EE32DE30564582EF5CE9844C692E6768F325F789640070D9`.
The executed candidate must expand this to every used engine source/tool/asset and
all proposed client files; these six hashes are an inspection anchor, not that
future full manifest. Selected Core projection/base file SHA256 are respectively
`C809481F48DA22F9321B8A1ABA1681587AF8B84105EF6F662700DAF573AE1C95` /
`2878F07F85E22E4B95A15EFE47B81D43275BF8A8F06FC500D4968B40FE1CEF4F`.

## Stop, cleanup and acceptance boundary

Stop before implementation/execution if E01 is unaccepted, authority does not
cover this exact scope/GUI/cache side effects, or independent source review is
missing. At runtime stop on missing tool/asset/window, source/hash drift,
unexpected module/install/config change, DDC fallback/nonowned cache selection,
nonhardware/NullRHI for rendered cases, zero/incomplete tests, screenshot/trace
failure, process timeout/crash or any attempted Core/network/game submission.
Use a fresh RunId for every corrected attempt; preserve failed logs and results.

On exit cancel actions, release simulated buttons/capture, remove delegates and
restore AutomationDriver; request queued automation quit, allow 15 seconds, then
terminate only recorded owned PID/process-tree identities if required. Do not
kill unrelated Unreal/ShaderCompileWorker/UBA processes by name. No concurrent
Unreal proof uses this run. Never launch an interactive IDE or change global
settings to repair a failure.

Default cleanup retains all evidence. After artifact hashes and an acceptance
audit exist, optional removal is limited to this run's staged `project/`, `temp/`,
`ddc/`, `dotnet-home/`, `nuget/`, `uba/` and `ue-user/`. Resolve absolute targets,
check the exact RunRoot prefix/no reparse points and retain logs/reports/artifacts/
manifests first. No recursive cleanup of engine, sibling, canonical project,
parent `.local`, AppData/global caches or another run. If evidence cannot be
preserved, do not clean it.

Accept only a frozen source review plus a separate acceptance audit that checks
build/tool/RHI identity, exact 4+4+8 executed cases, PNG inspection and actual
driver-to-Slate-to-world traces. Report numeric, rendered and input results
separately. Manual/physical interaction, OS focus switching, Linux, packaging,
full profile/HUD behavior and real-Core legality stay explicitly unverified.

## Freeze and remaining blockers

Planning-body SHA256 (UTF-8 bytes preceding this heading):
`FE5B906AC2A90E08E552375F2F4508935FE25E8797CD5C21AC21F9423137E7A2`.
The whole-file SHA256 is recorded in the coordinator handoff after the final edit.

Remaining authority/evidence blockers: accepted E01 manifest/audit is not yet bound
here; applicable authority for these exact new files, GUI/process and normal cache
side effects still needs recorded review; executable candidate/source review,
16 registered/executed results, real hardware RHI, six inspected PNGs and separate
acceptance audit do not yet exist. Human/physical input and Linux remain NOT RUN.
No E02 process, implementation, test, asset or runtime output was created by this
planning task. This packet is ready for review only; research remains incomplete.
