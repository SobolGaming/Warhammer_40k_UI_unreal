# E02 Windows world/input architecture proof — adopted packet

Date: 2026-10-16; readiness/operational/minimal-supervision proposal: 2026-10-17 UTC.
Status at adoption: **PACKET_ADOPTED_FOR_SOURCE_AUTHORING; E02 NOT RUN**.
Coordinator adoption: `2026-10-17T06:14:17.416085+00:00`; source base `bd801233cc9989e0ae146a3be7b136d26dc73183`.
This is the next reviewable subset of E02 after acceptance of the specifically
bounded E01-SLOW120 diagnostic identified below. It does not require or imply
acceptance of full E01, M01/M02, the old 30-second budget or production latency.

OWN13 continuation applies to this exact bounded Windows architecture proof:
the 14 authored paths below, owned background process trees, immutable project
staging, owned runtime/cache outputs and the documented ordinary per-user build/
driver-cache side effects. Root records that applicability against this frozen
packet in the [E02 authority/execution journal](../evidence/2026-10-16-e02-world-input.md).
Authoring is allowed; build/control/native execution waits for source review.
The desktop execution rule separately requires explicit owner authorization for
one visible interactive game window before graphical discovery/rendered input.
Prepare the concrete source first; do not infer that visible-launch approval from
OWN13 or silently substitute hidden/offscreen graphics. Do not ask the same broad approval
again. A material new commitment or scope change needs an explicit owner decision;
this packet supplies no broader E02–E08, feature, Core or new-host authority.

Read with [canonical Section 0/RQ05/RQ09/RQ10/RQ12/RQ20/RQ23 and E02](../unreal-migration-plan.md),
[BOOT01 results](../evidence/2026-10-16-boot01.md),
[geometry contract](2026-10-16-contract-integration.md#rq09--open-mapping-source-established-asymmetric-axis-discrepancyproof-remains),
[selected target adaptation](2026-10-16-contract-44-3-33-adaptation.md), and
[input ownership table](2026-10-16-parity-closure-design.md#complete-event-ownership-focus-cancellation-and-retry-policy).
The coordinator owns predecessor binding, authority reconciliation and plan status.
The eventual proof implementer owns source, wrapper and one isolated process tree.
The independent CODE reviewer and a different independent REQ/acceptance auditor
own their separate OWN15 reports; neither authors fixes or substitutes the other.

## Bounded predecessor and staged gates

The prerequisite is the accepted bounded E01-SLOW120 diagnostic, never a passing
source review, test-count summary, historical run or full-E01 claim by implication.
The coordinator must bind the following fields only after the actual fresh run,
final CODE and final REQ reports establish acceptance for the same frozen candidate:

| Binding | Current value / required identity |
|---|---|
| Predecessor status | `BOUNDED_E01_SLOW120_ACCEPTANCE_RECORDED`; root at `2026-10-17T06:00:32.004673+00:00` |
| Accepted diagnostic run | `20261017T044903Z-b0169768`; [factual result](../evidence/2026-10-16-e01-slow120-result.json) SHA256 `F6EDE1DD23F403FB03C9F3B8BBB5D6A1B7EDD964709F7E95C9ACDEF7C88024E6`; exact raw phase/report/manifest descriptors under `/primaryRun` |
| Frozen source and packet | Executed `d1189592a5f99bdee58cea25ae8546e5ee2e3623`; reviewed `b97ed5e8c1b2b2a1472aeb7fb70a267e0eab3d37`; cumulative base `0467ee63fe6d4c775f429afae2233d7292787c31`; E01 packet revision7 SHA256 `9AE3C7B236EF7897F033163062899B4F0BA8B9A7E622D79E06D5746FA3236367`; Core fixture manifest SHA256 `BF861B2EC555C81E85A31E4B37E756C5E6B04D343522A95F3235700C2AEC43F2` |
| Runtime/source manifests | Core `5f509724da25a2f6ded0c2739a8e7c84bdf59c91` /44.3.33; owned runtime provenance SHA256 `39C485C33E482B158EDB157A0FFAA69224C09E15DE5655277B64289887F7CF7C`, tree `B01989FC595730D8EA6F1A10C7A5004510FCA877A9B69AAD9F3285CAB357A897`; source Preflight result SHA256 `44CB8FE0FEA3B050E96289F198AA484361C1DA54CFF7702DE3A17AF6B480FA23`; paths and exact build ID in the bound factual result `/dependencyIdentity` and `/primaryRun/runtimeAndSourceEvidence`. E02 launches no Core runtime. |
| Final CODE report | [r13](2026-10-17-e01-slow120-code-review-r13.md), SHA256 `5C8F3E8B7E80A92472B658849CB03333708BEEA892C6057D2A632860D8B3A0E7`, PASS for reviewed b97; session `01a14858-1a8d-7340-b113-a658bfad52c9` |
| Final REQ role | [Valid initial r3](2026-10-17-e01-slow120-requirements-r3.md), SHA256 `6F232432B983EBB65F6CEE39B95F8F0A0ACD6B03539122AE0DB40E2817E8A301`, raw BLOCKED on administrative A1/A2, session `01a14861-6670-7f43-be6f-a5e3d1cc487f`; [separate administrative supplement](2026-10-17-e01-slow120-requirements-r3-administrative-supplement.md), SHA256 `C382B8A36ED9D033B892220ADA9FDF265119948A7D9A2455F6C8CD22B197855E`, SUPPLEMENTAL_ADMINISTRATIVE_PASS and combined REQ-role PASS, new post-initial session `01a1486d-9c0f-7362-96cb-7e47b3a05b58`. Raw initial status stays BLOCKED; invalid original r2 contributes no approval. |
| Acceptance/publication record | [Public provenance](../evidence/2026-10-17-e01-slow120-final-review-provenance.json), SHA256 `0AE6B378642921F47C8D48F4AF49FCEEA1EB1DCAFE2CAB599D4F296F910F5CFC`; root acceptance date above; separate report/metadata publication commit `bd801233cc9989e0ae146a3be7b136d26dc73183`. These reports reviewed b97, not the publication commit. |

Passing execution or source-only approval cannot fill these fields. Preserve the
original 30-second FAIL/UNKNOWN and every failed attempt. Accepted SLOW120 remains
a bounded protocol diagnostic; full E01/M01/M02, UE HTTP, responsiveness, rendering,
packaging, Linux and G-RESEARCH/G-IMPLEMENT retain their separate open criteria.

1. Before authoring E02, require this accepted predecessor binding and coordinator
   review/freeze of the exact packet, OWN13 applicability, files, owners, outputs,
   GUI/cache side effects, budgets and pass/fail rules. Executable source need not
   exist at this stage. Root recorded this gate in the linked E02 journal;
   this permits source authoring only, with the later gates unchanged.
2. Before any E02 build or native process, author only the permitted scope, freeze
   the executable source/wrapper/fixture/toolchain/config manifests, and obtain
   independent review of that exact executable candidate. Recheck those bytes
   before each affected process; a changed candidate needs fresh affected review.
3. After execution and the final documentation/evidence freeze, obtain separate
   fresh final CODE and REQ assessments under OWN15. Each initial assessment uses
   a new unprimed context with no resume/fork/inherited implementation transcript,
   enforced read-only permissions, approval policy never, and requested
   `memories.use_memories=false`. Record actual invocation/session/model/settings/
   permissions and requested versus verified memory behavior; unavailable
   properties remain BLOCKED/UNVERIFIED. Supply original requirements, clean
   normative criteria, exact frozen identities and raw results, without author
   notes or peer verdicts. Auxiliary/source-only reviews do not satisfy this gate.
   Both current reports and no unresolved acceptance blockers are required.

OWN16 requires regular coherent local checkpoint commits, before risky changes
and after fixes, recording actual tests and independent-review status. Exclude
secrets, private sessions and generated outputs. Checkpoints provide recoverable
save points, not acceptance or added publication/merge authority. Keep every
reviewed/executing candidate frozen; queue edits and checkpoint them only after
that operation ends. Do not change the active E01 candidate while preparing E02.

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
The existing Arcade axes mismatch must not be copied. The domain-to-world
reflection reverses orientation; treat that transform and UE's triangle
front-face convention separately. For submitted indices `(A,B,C)`, the installed
`UKismetProceduralMeshLibrary::GenerateBoxMesh` and normal calculator establish
the outward-normal relationship `normalize((C-A) × (B-A))`. Thus an outward `+Z`
top has an ordinary `(B-A) × (C-A)` pointing toward `-Z`; supplied normals still
point outward. Preserve outward top, bottom and side faces after reflection and
rigid placement. Do not use the same generator's cross-product assumption as
its test oracle. Within `Numeric.ShapesWinding`, compare the real installed
`GenerateBoxMesh` output and independently check outward faces, including a
rotated rigid frame. Preserve later oblique/near-top visual inspection.

Use transient `UProceduralMeshComponent` shallow opaque footprint meshes with
labelled local +X/+Y marks and asymmetric color sectors; no texture import is
needed to expose orientation. Use installed `/Engine/Maps/Entry` as the blank
world and `/Engine/BasicShapes/Cube.Cube` for board/platform and ordinary-mesh
substitution; the installed BasicShapeMaterial may supply a transient tinted
material instance. Add a transient fixed directional light and locked exposure;
record their settings so the blank Entry world is not dependent on editor lighting.
Record engine asset path/hash provenance and the actual material two-sided state
and component-transform determinant in the geometry dump. One-sided front-face
visibility must agree with the numeric outward-face checks; two-sided material
or a reflected component transform cannot conceal incorrect submitted winding.
No `.umap`/`.uasset`
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
`50°`), plus `25°` oblique and `85°` near-top proof views. Implement orbit, table-plane
pan, bounded dolly, frame-board/selection and reset with explicit focus. Record
projection matrix, camera pose, viewport pixels and UI scale for each capture.
Cube substitution changes only the visual branch: IDs, support/measurement
descriptors, query result and serialized **local advisory intent** stay identical.
There is no submitted command whose semantics this fixture can prove.

Freeze the exact camera target/distance, orbit/pan/dolly increments and bounds,
frame/reset focus, key bindings, light/exposure values and per-case input sequence
in the existing fixture/source before executable review. These are reversible
proof defaults, not new product requirements. Keep the specified angles/FOV,
domain values, scale matrix and tolerances fixed. Derive driver screen positions
from the actual owned viewport/widget geometry and stable target IDs; retain
physical/logical coordinates and camera matrices in the trace. Never tune a test
or fixture to match an already captured failure without a new reviewed candidate.

## Actual input route and its limits

Attach one C++ Slate proof surface to the game viewport. Its pointer/key/focus
handlers are the runtime route used by both a user and AutomationDriver: platform
message handler → Slate hit test/capture/focus → proof surface/widget handler →
ownership policy → camera/local intent/world-ray query. Input tests must drive
that route with screen positions/keys; directly calling the reducer, camera
method or selection setter cannot pass an input case. Numeric tests may call the
pure policy helpers and are reported separately.

Resolve text/modal/capture ownership before shortcut dispatch. Match the complete
normalized key and Shift/Ctrl/Alt/Cmd modifier state against the frozen bindings.
The fixture's arrows, `F/G/R`, `Enter`, `Escape` and `M` are bare-key bindings;
none implicitly matches a modified chord. Unbound modified shortcuts, including
`Ctrl+F` and `Ctrl+Enter`, must not change camera, selection, local review or
Confirm counters. Exercise those exclusions through AutomationDriver within the
existing input cases, then verify the corresponding bare keys still work.

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
| `Numeric.ShapesWinding` | 1 | Five dimensions, reflected polygon area and UE outward-face index/normal relationship; real installed GenerateBoxMesh reference plus independent top/bottom/side checks in a rotated frame; analytic query boundary cases and explicit synthetic capsule label. |
| `Numeric.UnsupportedGeometry` | 1 | Nonfinite/missing dimensions, unknown kind, null pose and invalid polygon fail with exact typed diagnostic; no generated substitute. |
| `Rendered.FiveForms` | 1 | Genuine perspective, all five forms/local axes distinguishable, correct silhouettes/extents; `five-forms.png`, scene/geometry dump. |
| `Rendered.RaisedPicking` | 1 | Project → deproject → nearest raised/ground/support-hole/edge/query hits; domain hit ≤`1e-4` inch, projected round trip ≤1 physical pixel; `raised-pick.png`, ray dump. |
| `Rendered.MeshSubstitution` | 1 | Same-ID cube replacement preserves descriptors, selection and local intent bytes; `mesh-before.png`, `mesh-after.png` and identity/query diff. |
| `Rendered.ObliqueNormals` | 1 | 25° and near-top views expose winding, height, orientation/occlusion; `oblique.png`, `near-top.png`; no flat-camera substitute. |
| `Input.CompletedClick` | 1 | Release commits local selection once; press/hover/drag does not; actual ray/ID trace. |
| `Input.CameraCapture` | 1 | Right movement below/above 4 logical units, orbit crossing HUD and release; capture retained, no selection or leaked widget activation. |
| `Input.PanDollyFrame` | 1 | Middle-pan, viewport wheel, frame/reset and exact bare-key keyboard orbit change camera only; unbound modified shortcuts have no effect; retain draft/domain values and zero submissions. |
| `Input.HudExclusion` | 1 | HUD button release outside cancels; disabled/blank/scroll-at-limit consumes; no world pick/dolly underneath. |
| `Input.ModalText` | 1 | Text consumes characters/Enter; first Escape cancels focused edit, later closes modal; no world shortcut leakage. |
| `Input.CancelActivation` | 1 | Escape/capture loss and injected deactivate during drag cancel candidate; reactivate never synthesizes click; renewed review required, coordinates retained. |
| `Input.ResizeScale` | 1 | Crossing gesture cancels; physical viewport extent updates; UI scales `1.0/1.5` at `1280×720`, plus `1600×900` at `1.0`; same intended ray/hit and HUD exclusion without double DPI. |
| `Input.RepeatedConfirm` | 1 | Exact bare Confirm/Escape bindings and local Ready transitions never submit; unbound modified Enter leaves review/Confirm counters unchanged; visible `ProofHasNoGameSession`, no success/acceptance record. |

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

All six minimum PNGs use absolute capture paths under
`<RunRoot/artifacts/world-input>/`, the baseline actual `1280×720` physical
viewport and the same synthetic fixture identity:

| Case / view | Exact basename |
|---|---|
| `Rendered.FiveForms` | `five-forms.png` |
| `Rendered.RaisedPicking` | `raised-pick.png` |
| `Rendered.MeshSubstitution` before | `mesh-before.png` |
| `Rendered.MeshSubstitution` after | `mesh-after.png` |
| `Rendered.ObliqueNormals` oblique | `oblique.png` |
| `Rendered.ObliqueNormals` near-top | `near-top.png` |

Each manifest entry binds case, filename, dimensions, SHA256, capture completion
and camera/viewport/RHI/fixture snapshot. Before/after share camera, selection,
support/query descriptors and local intent; only the visual branch changes.
Capture the visible synthetic/advisory label and required shape/axis evidence.
Additional resize-scale images are optional and separately identify actual
extent/scale; they cannot replace one of the six minimum artifacts.

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

Record complete canonical and staged descriptor/`Source/`/`Config/` directory/file
membership and byte manifests before the build and compare them after every
affected phase, including failure paths. Generated outputs must not alter either
authored snapshot. Hash and bind the separate wrapper and fixture as well; verify
the frozen input identities before each process and retain the actual after
observations rather than assuming the copied project is immutable.

| Owned output | Writer / retention |
|---|---|
| `project/Binaries/`, `project/Intermediate/`, any `project/Saved/` | Staged UBT/UHT/build/native generated outputs; no canonical-project build output changes. |
| `ue-user/`, `ddc/`, `temp/`, `dotnet-home/`, `nuget/`, `uba/` | Subprocess-only UserDir/DDC/TEMP/TMP/.NET/NuGet/UBA settings; keep parent environment unchanged. |
| `logs/`, `reports/supervisor-controls/`, `reports/discovery/`, `reports/numeric/`, `reports/world-input/` | One supervised root tree at a time; phase-owned logs, complete directly launched root records, actual job counters and observed cleanup. |
| `artifacts/`, `manifest.json`, `result.json` | Proof/supervisor; screenshots, structured traces, hashes and explicit status for every case. |

Build, discovery, numeric and rendered/input are four sequential supervised root
trees, not four processes total. Record every directly launched root's absolute
executable/hash, working directory, exact argument array and effective declared
subprocess environment overrides; never dump inherited secrets. Retain the
original process handle's actual PID and kernel creation FILETIME, actual kernel
exit FILETIME/code after confirmed exit, launch/exit observation UTC separately,
deadline/timeout and cleanup results, stdout/stderr and phase main-log paths.
Never substitute a phase bound or poll time for a process's kernel time.
Optional observed descendant metadata is explicitly incomplete and identifies
its observation method; unknown fields remain null/UNVERIFIED. No full historical
descendant PID/time/exit ledger is required or claimed. The original E01 host/
attach-worker inventory requirement remains unchanged. The canonical project's
`Binaries/`, `Intermediate/`, `Saved/` and both siblings are not output roots.
Inventory actual generated RunRoot paths, including unexpected staged
`project/Saved/`; flags alone cannot establish output containment or cleanup.

| Root tree / bound | stdout / stderr under `RunRoot/logs/` | Main log / report under RunRoot |
|---|---|---|
| Build / 30 minutes | `build.stdout.log`, `build.stderr.log` | `logs/build.log`; no Automation result claimed |
| Discovery / 10 minutes | `discovery.stdout.log`, `discovery.stderr.log` | `logs/native-discovery.log`; `reports/discovery/` plus selected-name manifest |
| Numeric / 10 minutes | `numeric.stdout.log`, `numeric.stderr.log` | `logs/native-numeric.log`; `reports/numeric/` |
| Rendered/input / 10 minutes | `world-input.stdout.log`, `world-input.stderr.log` | `logs/native-world-input.log`; `reports/world-input/` and `artifacts/world-input/` |

Use the staged project directory as each subprocess working directory. Resolve
tool paths and every output path absolutely; record the effective subprocess
environment without dumping inherited environment variables or credentials.
The wrapper owns manifests/results, while each phase owns only its named logs,
reports and artifact subdirectory. Finalization preserves a primary failure and
typed secondary inspection/cleanup/write/close errors, including partial outputs.

### Minimal private-job ownership and cleanup

Use a fresh private unnamed, non-inheritable Windows Job Object for each root tree.
Set `JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE`, neither `BREAKAWAY_OK` nor
`SILENT_BREAKAWAY_OK`, and no new UI/resource limits. Keep the original private job
handle in the supervisor; do not pass/duplicate it to a child. Create the exact
root suspended, retain its original process/thread handles, assign it to this job,
verify membership and effective job limits, then resume. No root code may run
before successful assignment. On setup/assignment failure, do not resume; finalize
only this original owned suspended process/handles and preserve the actual error.
Nested-job/security incompatibility is a technical **BLOCKED** result, never
permission to change the host job, enable privileges or launch outside the job.

Keep the Win32 interop in the one permitted wrapper (inline C# using the existing
PowerShell/.NET runtime is allowed); freeze its exact helper, loaded runtime and
SDK/API identities before executable review. No extra authored helper, package,
service, debugger, IOCP collector, trace/audit session or global setting is needed.
Any compilation temporaries stay under declared RunRoot paths. This is proposed
source support, not proof of actual compilation or nested-UBT/UE compatibility.

Query `JobObjectBasicAccountingInformation` through the explicit retained private
job handle, never NULL. Record genuine query UTC, success/error and all returned
counters including `TotalProcesses`, `ActiveProcesses`, `TotalTerminatedProcesses`
and raw accounting values. They aggregate job members, including nested child
jobs; they do not supply missing child identities/times. Preserve failed setup,
association and limit diagnostics. Do not equate `TotalProcesses` to an optional
observed-child list or `TotalTerminatedProcesses`, or subtract failed associations.

After normal root exit, capture its actual times/exit code and drain/close its
owned output/process references safely before terminal accounting. Preserve the
record before releasing handles. Optional retained completed-child references
also need safe finalization. Keep the job queryable and boundedly observe an
actual `ActiveProcesses=0` before declaring group cleanup complete. A root exiting
or `Kill(true)`/`WaitForExit` succeeding cannot establish descendant cleanup.
Limits and creation flags by themselves cannot establish runtime containment.

On timeout/failure, retain the primary failure, request the existing graceful
shutdown when possible, then use `TerminateJobObject` only on this private job if
needed. Confirm the root's actual exit and an actual terminal zero-active query
while the job handle is still open; afterward close owned handles and record
results/typed secondary errors. Kill-on-close is a backstop, not observed cleanup.
Use the existing 30/10-minute phase deadlines; the at-most-15-second graceful
period and finalization must not extend them. If any exit/query/close/evidence
step is unavailable, fails or exceeds its bound, retain FAIL/UNVERIFIED and stop
dependent phases; never claim cleanup PASS from an attempted termination.

Job membership covers the reviewed inherited tool group, not arbitrary outside
brokers. Inspect the actual selected launch paths and retain relevant startup/
worker diagnostics. A tool requiring an escaped/brokered process or unsupported
nested job is **BLOCKED** for this packet, with no containment PASS or broader
kill/search fallback. Preserve evidence; review a packet repair before a fresh
RunId. This does not claim a hostile-process sandbox, whole-machine containment,
or successful individual descendant exit codes from aggregate zero-active.

### Focused wrapper supervisor controls

After executable source review and before build, run three meaningful wrapper
control groups using benign owned fixtures and the same private-job mechanism.
Keep source in the permitted wrapper, outputs under
`RunRoot/reports/supervisor-controls/` with their own logs/manifests, and all control
work inside one ten-minute bound. They are separate supervisor evidence; the 16
native E02 cases and four proof-phase bounds do not change.

| Group | Required behavior and evidence |
|---|---|
| `SUP01` normal root plus lingering descendant | A benign known child remains active after its root exits; root evidence is complete and the genuine private-job query must still report active membership. The supervisor waits for the owned child to finish and records actual zero-active before cleanup completion. A root-only completion path must fail this control. Child observations support this fixture only, not a universal descendant ledger. |
| `SUP02` timeout cleanup | Prove the actual owned child started and remained alive shortly before private-job termination, using the original returned Process object and a bounded child readiness acknowledgment. The short test deadline produces the exact expected typed timeout, private-job termination and actual exit/zero-active observations; successful cleanup never changes the attempted proof's timeout to PASS. A sleeping root or aggregate member count alone cannot satisfy this control. No unrelated process is targeted. |
| `SUP03` setup/query/finalization failure | Controlled seams exercise failed assignment before resume, failed accounting query and failed evidence/handle finalization. Require each exact injected diagnostic and expected resume/exit/accounting state; reject real technical blockers, unrelated primary/secondary errors and missing evidence. Primary and secondary errors remain visible; setup fails closed, cleanup stays bounded and no dependent phase starts. Label injected checks separately from actual API observations; do not claim that injection proves every OS failure path. |

Freeze exact benign fixture commands, subcase/assertion counts, injection seams
and output contracts before source review. Require all three groups complete with
their expected outcomes, recording actual versus injected observations separately.
A missing/failed control blocks build. No fast-child timestamp acquisition or
arbitrary complete child-inventory control is added. All controls remain **NOT RUN**.

The SUP01/SUP02 fixture must stop on child Start failure, a null returned Process,
early child exit, invalid readiness text or loss of the child. Keep the original
returned Process object until the fixture exits; never reopen a PID. Redirect
only the child's stdout for one fixed, bounded readiness exchange. A child
self-report of PID/creation FILETIME must match the parent's original Process
Id/StartTime observation, with HasExited=false. The readiness deadline is two
seconds inside the existing root budget, without retries. A post-read text-size
check on ReadLineAsync is validation, not an allocation cap; the command text is
the frozen, trusted fixture. Preserve the acknowledgment and parent observations
as JSON lines in the existing owned root stdout and bind its unchanged descriptor.

The native root receipt's `syntheticFault` is a string selector. SUP01/SUP02
require exactly the empty string for no injected seam; null, nonstrings and
nonempty strings fail. The diagnostic object's `syntheticFault` is separately a
boolean. Preserve the native receipt representation and all earlier raw receipts.

For SUP01 require that identity/alive observation immediately before the normal
root exits, alongside the existing actual root-exit/active-members and eventual
zero-active observations. For SUP02 retain and poll the original child Process,
record periodic HasExited=false observations spanning at least 250 milliseconds
on the fixture's monotonic clock, and require a final observation within one
second before the successful private-job TerminateJobObject request.
Require the expected forced root exit `0xE0200001`, exact non-synthetic timeout
diagnostic, no technical blocker or unexpected secondary failure, and final
actual zero-active accounting. Missing, stale or inconsistent child evidence
fails the control even when the root alone times out. These are finite fixture
observations plus the non-breakaway inheritance mechanism, not a direct
per-descendant job query or universal child-lifecycle ledger.

For SUP03 require typed booleans/integers, real root PID/creation/exit evidence,
hidden launch identity/budget and final actual successful zero-active query.
Assignment must remain unassigned/unresumed with the exact synthetic primary
`E02_INJECTED_ASSIGN_FAILURE_BEFORE_RESUME`, forced exit `0xE0200002`, no secondary
errors and a zero-total private job. Query must be assigned/resumed with the exact
synthetic primary `E02_INJECTED_ACCOUNTING_QUERY_FAILURE`, no secondary errors,
and exit either zero (natural exit observed before injection) or `0xE0200002`.
Close must be assigned/resumed, exit zero, have no primary and exactly the one
synthetic secondary `E02_INJECTED_HANDLE_FINALIZATION_FAILURE` at
`close-control-seam`. Assign/query primary stage is `owned-root`; all three
diagnostics are `System.InvalidOperationException`, syntheticFault=true and
win32Error=null. Any real setup error, wrong seam or unrelated error fails.
Retain each raw FAIL receipt; enclosing case PASS describes only that expected
synthetic shape. The existing evidence-writer seam is unchanged.

Supporting API provenance includes the loaded System.Diagnostics.Process runtime
DLL and [public .NET v10.0.11 Process.Windows source](https://github.com/dotnet/runtime/blob/v10.0.11/src/libraries/System.Diagnostics.Process/src/System/Diagnostics/Process.Windows.cs).
The source's retained handle path supports the fixture's original-Process
observations; freeze the exact local source bytes/ranges and runtime binary.
The public tag does not establish exact source-to-installed-binary correspondence.
No extra process roots, groups, subcases, native cases or budgets are introduced:
three groups, six subcases and five roots remain required.

The future reviewed wrapper must build with `Build.bat WarhammerClientEditor
Win64 Development -Project=<RunRoot/project/WarhammerClient.uproject> -WaitMutex
-NoUBA -UBARootDir=<RunRoot/uba> -Log=<RunRoot/logs/build.log>` and subprocess
`UBA_ROOT=<RunRoot/uba>`. It supervises the process tree with a 30-minute build
timeout and 10-minute limit per automation process. The reviewed suspended
native launch replaces a racing Start-Process-then-assign sequence; preserve
hidden background supervision and exact argument/environment handling. Keep
the real proof viewport visible/reachable when needed; hidden/offscreen behavior
cannot prevent the actual viewport/input evidence. Missing window/RHI is a
recorded blocker, not a reason to manufacture screenshots.

Future native invocations (all values absolute, arguments supplied as individual
process arguments by that wrapper):

```text
UnrealEditor.exe <staged-uproject>
  /Engine/Maps/Entry?game=/Script/WarhammerClient.E02WorldProofGameMode
  -game -E02Proof -unattended -d3d12 -windowed -ResX=1280 -ResY=720 -nosound
  -ExecCmds="Automation List;Quit"
  -ReportExportPath=<RunRoot/reports/discovery>
  -DisablePlugins=UdpMessaging,TcpMessaging,QuicMessaging,WebSocketMessaging,DiscoveryBeaconReceiver,NetworkServiceDiscovery
  <isolation-args with ABSLOG=<RunRoot/logs/native-discovery.log>>

UnrealEditor-Cmd.exe <staged-uproject> -unattended -NullRHI -nosound
  -ExecCmds="Automation RunTest StartsWith:Warhammer.Migration.E02.Numeric;Quit"
  -ReportExportPath=<RunRoot/reports/numeric>
  -DisablePlugins=UdpMessaging,TcpMessaging,QuicMessaging,WebSocketMessaging,DiscoveryBeaconReceiver,NetworkServiceDiscovery
  <isolation-args with ABSLOG=<RunRoot/logs/native-numeric.log>>

UnrealEditor.exe <staged-uproject>
  /Engine/Maps/Entry?game=/Script/WarhammerClient.E02WorldProofGameMode
  -game -E02Proof -unattended -d3d12 -windowed -ResX=1280 -ResY=720 -nosound
  -ExecCmds="Automation RunTest StartsWith:Warhammer.Migration.E02.Rendered+StartsWith:Warhammer.Migration.E02.Input;Quit"
  -ReportExportPath=<RunRoot/reports/world-input>
  -DisablePlugins=UdpMessaging,TcpMessaging,QuicMessaging,WebSocketMessaging,DiscoveryBeaconReceiver,NetworkServiceDiscovery
  <isolation-args with ABSLOG=<RunRoot/logs/native-world-input.log>>
```

The discovery process lists tests without running them in the same hardware-RHI
game context as rendered/input. Record the entire eligible engine-list count
separately, select exact names beginning `Warhammer.Migration.E02.`, and require
unique set equality with the 16 names in this packet. Other engine/E01 names do
not count and are not extra E02 cases. Freeze the selected-name manifest before
running either test filter. Installed
`AutomationCommandline.cpp:129–163` splits filters on `+` and supports `StartsWith:`;
the frozen wrapper must still validate the exact 4 numeric / 12 rendered-input
results. No claim that those suites already exist or commands have been exercised
is made here.

Register numeric cases with `EditorContext | ClientContext | EngineFilter` so
they are discoverable in `-game` and executable in the separate NullRHI Editor
process. Register rendered/input with `ClientContext | NonNullRHI | EngineFilter`;
the injected automated route does not require a human, so omit `RequiresUser`.
Installed `AutomationTest.cpp:805–871` applies the actual application/feature
filters: NullRHI cannot supply the rendered discovery set, and unattended mode
cannot establish physical-user evidence. Runtime hardware/window assertions still
apply; registration flags alone do not prove a valid graphics environment.

Use one `Automation` prefix for each semicolon command group. Installed
`ParseExecCommands.cpp:11–54` splits top-level `ExecCmds` only on commas;
`AutomationCommandline.cpp:565–586` consumes `Automation` once and then splits
its remainder on semicolons. Its queued-quit branch at `726–734` expects `Quit`,
so `;Automation Quit` does not queue the required automation-aware exit.

`isolation-args` must include explicit `-UserDir=<RunRoot/ue-user>`, `-nowrite`,
`-ABSLOG=<RunRoot/logs/unique-phase.log>` for every discovery/numeric/rendered-input
process. Require the actual phase main log at that exact owned path; neither an
exit code nor stdout alone proves ABSLOG or DDC selection. Also include
`-E02Fixture=<RunRoot/fixture/world-input-v1.json>`,
`-E02Artifacts=<RunRoot/artifacts/phase>`, `-DDC-NoDefaultGraph` and a complete
custom cache replacement argument:
`-DDC=(E02=(Type=FileSystem,Path=<RunRoot/ddc>,DeleteUnused=false))`.
Use slash-normalized paths; reject quotes/parentheses in RunRoot rather than
building ambiguous command text. This complete node has no env/registry/editor
override keys and no Zen/shared/cloud nodes. Source supports the syntax; execution
must still confirm its selected graph/path and stop if a fallback occurs.

`-UserDir` redirects project user Saved/Intermediate, not every engine/user path.
Carry forward the accepted E01 preservation discipline using actual current E02
observations. Derive absolute engine/project/user/version roots, then record
these six role-identified Editor-settings observations before the build and after
native work, including failure paths. Retain all six even if Documents paths
coincide; use the staged project root for the project-default role:

| Role | Observed path |
|---|---|
| `engine-base` | `<EngineRoot>/Engine/Config/BaseEditorSettings.ini` |
| `local-user` | `<LocalApplicationData>/Unreal Engine/Engine/Config/UserEditorSettings.ini` |
| `local-versioned` | `<LocalApplicationData>/UnrealEngine/<engine-major.minor>/Saved/Config/WindowsEditor/EditorSettings.ini` |
| `profile-documents-user` | `<UserProfile>/Documents/Unreal Engine/Engine/Config/UserEditorSettings.ini` |
| `project-default` | `<staged-project>/Config/DefaultEditorSettings.ini` |
| `known-documents-user` | `<actual-known-Documents>/Unreal Engine/Engine/Config/UserEditorSettings.ini` |

The old absent observation is historical: E01 subsequently recorded creation of
the normal versioned EditorSettings file. Preserve its actual current state.
Never delete/restore it, assume absence, borrow E01's snapshots or reconstruct a
missing before observation. Each record includes role, absolute path, observation
time, typed inspection status, exact boolean existence and file SHA256 (null only
for established absence). Only explicit not-found establishes absence; access/IO/
hash-race failures remain UNAVAILABLE and fail the gate. Reject files that are
directories/reparse points and any missing/duplicate/substituted observation,
changed existence, bytes, path or membership.

Treat only the two exact `actual-known-Documents` settings paths in this table
and the UBT list below as read-only logical-path observations. Require the actual
absolute OS Known Documents path, retain it in the same-run user context and bind
each role to its exact expected path. An ancestor may have an unclassified reparse
point; this observation route is not an owned-output containment root and supplies
no resolved-target identity proof. Record a distinct path policy for these two
roles. Keep rejecting a present directory or reparse-point leaf, and preserve
typed absence versus UNAVAILABLE plus exact before/after role/path/existence/hash
comparisons for all nine observations. This exception cannot enter `Digest`,
artifact descriptors or any owned/source/tool/Engine path. Strict reparse rejection
continues for those paths and LocalApplicationData/ApplicationData/UserProfile.
Do not substitute `<UserProfile>/Documents`, omit either Documents role, change
Known Folder settings, create missing settings/XML/directories, or repair global
configuration. There is no explicit hydration request or write; provider activity
caused by a read is not established absent. A reparse attribute or null link target
does not classify the tag or establish a physical target. See Microsoft's
[reparse-point tag definitions](https://learn.microsoft.com/en-us/windows/win32/fileio/reparse-point-tags).

Observe the three UBT BuildConfiguration.xml locations under
`<ApplicationData>/Unreal Engine/UnrealBuildTool/`,
`<LocalApplicationData>/Unreal Engine/UnrealBuildTool/` and
`<actual-known-Documents>/Unreal Engine/UnrealBuildTool/`.
Preserve current existence and exact bytes at every configured location;
unavailable roots/observations block execution, and no absent XML may be created
as an E02 repair. Freeze canonical authored Config and its staged copy as complete
directory/file membership and byte manifests, then require both unchanged after
build/native work. Observe before the build, collect after-observations on
failure as well as success, and retain primary failures plus safe typed secondary
inspection/cleanup/finalization diagnostics. Missing evidence cannot produce PASS.

Pass `-nowrite` to every native process and verify its actual arguments and the
resulting unchanged Config/settings evidence. Flags alone do not prove
preservation. A plain `Local` DDC node has an EditorOverrideSetting parsed after
its command-line path; fresh project UserDir alone cannot prevent that override.
Keep the complete custom E02 node above with `-DDC-NoDefaultGraph`; check the
actual new ABSLOG for its selected graph and exact RunRoot/ddc path and stop on
fallback, nonowned write-store selection, or a Zen/shared/cloud node. This does
not authorize deleting ordinary driver caches or promise whole-filesystem
isolation.

BOOT01's known normal UBT environment XML/Trace.uba/cache reads/writes must be
declared in the coordinator's OWN13 applicability record: specifically UBT's existing
`C:/Users/Rabid/AppData/Local/UnrealEngine/Intermediate/Build/` and
`C:/Users/Rabid/AppData/Local/UnrealBuildTool/Trace.uba`, and its existing Roaming
`Unreal Engine/UnrealBuildTool/BuildConfiguration.xml`. Real rendering may write
ordinary per-user D3D/driver shader caches, including
`C:/Users/Rabid/AppData/Local/D3DSCache/` and
`C:/Users/Rabid/AppData/Local/NVIDIA/DXCache/`, outside RunRoot. Include that
bounded normal side effect in the execution-authority record; do not promise full
filesystem isolation or delete shared caches. Report known-path observations as
such. No new Zen/Core/web service, crash upload or external host is requested.

### Local Automation and external messaging boundary

Every native invocation above includes this exact subprocess-only argument:
`-DisablePlugins=UdpMessaging,TcpMessaging,QuicMessaging,WebSocketMessaging,DiscoveryBeaconReceiver,NetworkServiceDiscovery`.
Keep the engine `Messaging` module's default in-process bus for local Automation;
do not add `-Messaging`, TCP listen/connect arguments, remote workers or transport
plugin dependencies. Before launch validate the frozen descriptor/dependency
closure does not re-enable a forbidden plugin. At startup record actual enabled
plugin/module selection and bridge/listener/discovery diagnostics; stop if a
forbidden transport or service starts. Do not repair global settings or silently
permit an external connection to make discovery work.

Installed UDP/TCP descriptors enable those plugins by default; UDP supports
`-UDPMESSAGING_TRANSPORT_ENABLE=false`, but that alone does not disable an
inherited tunnel. No equivalent TCP boolean argument was established. The common
`DisablePlugins=` comma-list route is source-supported for this installed engine;
its actual E02 behavior is **NOT RUN**, and network egress remains **UNVERIFIED**.
QuicMessaging and NetworkServiceDiscovery default false; WebSocketMessaging and
DiscoveryBeaconReceiver have no explicit default enable in their inspected engine
descriptors. Their explicit disable prevents optional inherited activation. The
default MsQuic runtime library is not itself evidence of a QUIC listener.

The AutomationController publishes its find-workers message with internal
`EMessageScope::Network`; that scope by itself is not a socket, external connection
or Core submission. Distinguish local bus events from forbidden external
transports. The proof's zero Core-transport/session/game-command counters cover
its own integration boundary; flags, counters and a negative log search do not
prove all engine/OS network activity is isolated. No whole-process no-egress
claim is made without actual separate observation. This clarification adds no
new service and does not reinterpret historical E01 default transport behavior.

## Installed-source support, not runtime proof

Paths below are relative to `C:/Program Files/Epic Games/UE_5.8/Engine/`;
identity is Launcher 5.8.3/CL58210709, not an Epic Git SHA. Inspected 2026-10-16.
Operational discovery/messaging additions were source-inspected on 2026-10-17 UTC;
their hashes below identify those installed bytes, without runtime verification.

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
| `Source/Runtime/Core/Private/Misc/AutomationTest.cpp:805–871`; `Source/Developer/AutomationController/Private/AutomationCommandline.cpp:331–337` | Editor/Client/NullRHI/unattended eligibility and listing all eligible tests; select the exact E02 prefix set separately. |
| `Source/Runtime/Projects/Private/PluginManager.cpp:1473–1479,1585–1598,2030–2061,2551–2597` | Subprocess comma-list plugin disabling before target selection; required dependencies still need complete frozen-closure inspection and actual startup verification. |
| `Plugins/Runtime/ProceduralMeshComponent/Source/ProceduralMeshComponent/Private/KismetProceduralMeshLibrary.cpp:23–31,148–224,319–322` | Actual GenerateBoxMesh triangle/normal convention and opposite-cross-order normal calculation; independent reference for the existing winding proof. |
| `Source/Runtime/Messaging/Private/MessagingModule.cpp:132–136`; `Source/Developer/AutomationController/Private/AutomationControllerManager.cpp:295` | Default local message bus and Network-scope find-workers message; scope does not establish an external socket. |
| `Plugins/Messaging/UdpMessaging/Source/UdpMessaging/Private/UdpMessagingModule.cpp:344–360,628`; `Plugins/Messaging/TcpMessaging/Source/TcpMessaging/Private/TcpMessagingModule.cpp:285–292,340–350`; `Config/BaseEngine.ini:3640–3643` | UDP transport/tunnel are separate; TCP's inherited enable/endpoints and optional command-line endpoints; plugin-level disable avoids claiming an unverified universal transport boolean. |

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
Additional operational source SHA256:
`Source/Runtime/Core/Private/Misc/AutomationTest.cpp` =
`3F8E6F595469173CCF87FF07CD2A78B732AF8900F4C8EB7A17E07DEC72A471A6`;
`Source/Developer/AutomationController/Private/AutomationCommandline.cpp` =
`A040ADEE46CDECDCBE5C8148C6203211FD59559EA0A73CE748D5725399B899B3`;
`Source/Runtime/Projects/Private/PluginManager.cpp` =
`B2AA3A2C551FCBD86A3DE72103030331591F619CA2C66AFF8B6EAE7E662BD2DF`;
`Source/Runtime/Messaging/Private/MessagingModule.cpp` =
`E61351E36926FC6086B82F6CA576F1AE3A02D87721493437CE27A0BBFFEDBE32`.
The executed candidate must expand this to every used engine source/tool/asset and
all proposed client files; these six hashes are an inspection anchor, not that
future full manifest. Selected Core projection/base file SHA256 are respectively
`C809481F48DA22F9321B8A1ABA1681587AF8B84105EF6F662700DAF573AE1C95` /
`2878F07F85E22E4B95A15EFE47B81D43275BF8A8F06FC500D4968B40FE1CEF4F`.

### Immutable Microsoft source support for the proposed supervisor

Inspected 2026-10-17 UTC. These are documentation/source mechanisms, not E02
execution or confirmation that this host's nested-job launch succeeds:

- [Job Objects](https://github.com/MicrosoftDocs/win32/blob/ca8274decead49403d70ceeed4af8d4ca74eaf11/desktop-src/ProcThread/job-objects.md): inherited CreateProcess membership, kill-on-close and the broker caveat: "Child processes created using Win32_Process.Create are not associated with the job."
- [Nested Jobs](https://github.com/MicrosoftDocs/win32/blob/ca8274decead49403d70ceeed4af8d4ca74eaf11/desktop-src/ProcThread/nested-jobs.md): ancestor accounting includes child jobs; a non-breakaway ancestor retains inherited descendants.
- [Creation flags](https://github.com/MicrosoftDocs/win32/blob/ca8274decead49403d70ceeed4af8d4ca74eaf11/desktop-src/ProcThread/process-creation-flags.md) and [assignment](https://github.com/MicrosoftDocs/sdk-api/blob/656e9656bfaef34dd29cd7ee9e1146aec17e924c/sdk-api-src/content/jobapi2/nf-jobapi2-assignprocesstojobobject.md): suspended creation permits assignment before root execution; nested/security restrictions can make assignment fail.
- [Explicit-job query](https://github.com/MicrosoftDocs/sdk-api/blob/656e9656bfaef34dd29cd7ee9e1146aec17e924c/sdk-api-src/content/jobapi2/nf-jobapi2-queryinformationjobobject.md): a NULL handle queries the caller's immediate job, so it cannot identify this private group.
- [Basic accounting](https://github.com/MicrosoftDocs/sdk-api/blob/656e9656bfaef34dd29cd7ee9e1146aec17e924c/sdk-api-src/content/winnt/ns-winnt-jobobject_basic_accounting_information.md): TotalProcesses includes some failed limit associations; TotalTerminatedProcesses counts limit-caused terminations. Active accounting falls after exit when "all references to the process are released"; safely finalize references before the terminal check.
- [Process times](https://github.com/MicrosoftDocs/sdk-api/blob/656e9656bfaef34dd29cd7ee9e1146aec17e924c/sdk-api-src/content/processthreadsapi/nf-processthreadsapi-getprocesstimes.md): actual creation/exit FILETIME comes from the retained process handle; exit-time contents are undefined before exit.
- [Job termination](https://github.com/MicrosoftDocs/sdk-api/blob/656e9656bfaef34dd29cd7ee9e1146aec17e924c/sdk-api-src/content/jobapi2/nf-jobapi2-terminatejobobject.md): termination applies to the owned job and child jobs; retain a later genuine cleanup observation rather than inferring completion from the call.

Freeze inspected documentation/SDK/runtime/helper identities with the executable
candidate. No debugger/IOCP delivery or complete per-grandchild kernel-time ledger
is required. All actual supervisor behavior and cleanup remain **NOT RUN**.

## Stop, cleanup and acceptance boundary

Stop before authoring if the bounded E01-SLOW120 predecessor remains unbound or
unaccepted, or the coordinator-reviewed frozen packet/OWN13 applicability record
is missing. Stop before build/native execution if the frozen executable candidate
lacks current independent source review, preservation observations or exact
owned-output/process prerequisites, or the three supervisor controls are failed/
incomplete. These are sequential gates; source review of
not-yet-authored executable code is not an authoring prerequisite.
At runtime stop on missing tool/asset/window, source/hash drift,
unexpected module/install/config change, forbidden external transport/discovery
startup, failed/unconfirmed private-job ownership or cleanup, DDC fallback/
nonowned cache selection,
nonhardware/NullRHI for rendered cases, zero/incomplete tests, screenshot/trace
failure, process timeout/crash or any attempted Core/external/game submission.
Use a fresh RunId for every corrected attempt; preserve failed logs and results.

On exit cancel actions, release simulated buttons/capture, remove delegates and
restore AutomationDriver; request queued automation quit, allow at most 15 seconds
within the existing phase deadline, then terminate only the recorded private job/
original owned process identities if required. Confirm actual root exit and
zero-active membership as specified above. Do not kill unrelated Unreal/
ShaderCompileWorker/UBA processes by name. No concurrent
Unreal proof uses this run. Never launch an interactive IDE or change global
settings to repair a failure.

Default cleanup retains all evidence. After artifact hashes and an acceptance
audit exist, optional removal is limited to this run's staged `project/`, `temp/`,
`ddc/`, `dotnet-home/`, `nuget/`, `uba/` and `ue-user/`. Resolve absolute targets,
check the exact RunRoot prefix/no reparse points and retain logs/reports/artifacts/
manifests first. No recursive cleanup of engine, sibling, canonical project,
parent `.local`, AppData/global caches or another run. If evidence cannot be
preserved, do not clean it.

Accept only the final frozen candidate with both current fresh independent CODE
and separate REQ reports under OWN15 and no unresolved acceptance blockers.
The acceptance audit checks predecessor binding, source/packet/toolchain identity,
all six Editor/three UBT observations and complete authored Config preservation,
canonical/staged source membership/byte preservation, actual owned ABSLOG/DDC
selection, verified plugin/transport selection, build/RHI identity, exact E02
discovery set and 4+4+8 executed cases, three separate supervisor-control groups,
complete directly launched root records, actual explicit-job aggregate counters/
zero-active cleanup, six inspected PNGs and actual
driver-to-Slate-to-world traces. Report numeric,
rendered and input results separately. Manual/physical interaction, OS focus
switching, Linux, packaging, full profile/HUD behavior and real-Core legality stay
explicitly unverified. No Core connection/new-host work is introduced; rendered
Windows evidence is still an actual future execution gate, and packaging is later.

## Freeze and remaining blockers

Packet clarification revision: **2026-10-18 UTC / plan revision 26**.
Planning-body SHA256 (exact UTF-8 bytes preceding this heading):
`633CE70BDE8058F958BB5B6AC7785BC5FBFF9A44C356C9AD85CF4444D11DF1E4`.
The whole-file SHA256 is recorded in the coordinator authority journal and the
checkpoint; historical adoption/status-label-only hashes remain in that journal.
The adoption derived from ignored proposal EC29BBB1. This dated revision makes
the existing native no-fault string representation explicit for SUP01/SUP02.
It retains child-start/alive evidence, exact injected-seam validation and the read-only Known Documents
ancestor-route policy, plain-file leaves, all nine observations and strict
owned/source/tool/output path checks.
The outward-face winding/oracle and exact bare-key chord requirements remain.
The geometric/input scope,16 cases,6 PNGs,14 authored paths, private-job mechanism
and existing budgets remain the specified proof.

The bounded predecessor is bound and the coordinator has reviewed the packet,
OWN13 continuation, named source writers, staged project/process/output ownership,
ordinary cache side effects and pass/fail rules. Source authoring may proceed.
This is neither executable source approval nor acceptance of future results.

At adoption, the executable candidate/source review, three supervisor controls and actual
private-job cleanup evidence, current E02 preservation snapshots,16 discovered/
executed results, hardware RHI,six inspected PNGs and fresh final CODE/REQ reports
did not yet exist. Explicit owner authorization for one visible interactive proof
window remains required before graphical execution under the desktop rule;
authoring and independently reviewed hidden controls/build/numeric work can
proceed separately. Human/physical input and Linux remain NOT RUN.
Current source/run dispositions are recorded separately in the authority journal;
no E02 process or result is claimed by this adoption record. Research remains
incomplete; full E01/M01/M02 and G-IMPLEMENT remain open.
