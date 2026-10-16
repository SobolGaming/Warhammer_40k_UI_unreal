# Toolchain, bootstrap, and validation research — 2026-10-16

This is supporting evidence for `../unreal-migration-plan.md`, principally RQ05, RQ06, RQ12, RQ14, RQ18, RQ20, RQ21, RQ23, and RQ24. It is research/planning output. No project, build, generator, install, new test, editor session, executable experiment, source-control configuration, or remote change was created by this investigation. Source availability is not a passing build or a rendered test.

## Source identities and authority

- Workspace: `C:/SWDev/warhammer`; root `AGENTS.md` and `Warhammer_40k_UI_arcade/AGENTS.md` were read.
- Legacy client: `Warhammer_40k_UI_arcade`, commit `5088c1c49dcaff29eb59fb64b3063d30214dde73`. The owner sometimes calls this project `Warhammer_40k_UI`; that logical name does not establish a third local client checkout. Application sources inspected here are in the `_arcade` checkout.
- External reference-only core: `Warhammer_40k_AI`, commit `5f509724da25a2f6ded0c2739a8e7c84bdf59c91`. No core file was edited.
- Destination: the owner explicitly selected the separate `Warhammer_40k_UI_unreal` repository and `docs/plans/unreal-migration-plan.md` in the current request. The repository initially had no Unreal scaffold. Existing implementation paths in the inherited plan remain proposals.
- The coordinator supplied the prior discussion's choices: native Windows development, VS Code as IDE, CLI creation/build and both VS Code/Visual Studio project-file generation, with no graphical launch. The discussion's script was a proposal and was not executed. Its precise script text was not independently inspected by this research agent; the coordinator must link its discussion evidence in the main plan.

The inspected legacy files listed below had no working-tree diff against this commit. For local Epic files, identity is the installed build plus the content hashes below, rather than a claim of an Epic Git commit.

### Dated owner choices — 2026-10-16

The coordinator relayed these explicit owner answers after the original inventory. They update requirements, without changing the historical installed/source facts above:

- **Initial platforms:** Windows x64 **and Linux x86-64**, both required from the first playable slice. Windows-only local development/bootstrap does not reduce M03's Linux delivery requirement.
- **Modes:** local play, remote participant and spectator. Do not infer an additional hotseat product requirement or authenticated actor switching from the word local.
- **Deployment:** managed local external-core runtime **and** attachment to an existing service. A missing owner-supplied runtime artifact cannot be bypassed by delivering attachment only.
- **External target:** sibling core contract **44.3.33**, after the necessary client adaptation and an exact compatibility/fixture freeze. The inspected sibling commit is `5f509724da25a2f6ded0c2739a8e7c84bdf59c91`; selection does not assert the legacy dependency pin or installed distribution has already been adapted.
- **Distribution:** personal/internal use initially. External redistribution clearance and commercial release commitments are future gates.
- **Continuity:** preserve existing profiles and exact-core continuity; no midgame switching between Arcade and Unreal is required. Keep original files and pair continuing sessions with their compatible core/client; this is not permission to rewrite core persistence formats.

Linux build/runtime/render-host access and the owner-supplied per-platform external runtime remain prerequisites. Neither a Windows cross-compiled executable nor a headless Linux check alone proves the required native Linux rendered/packaged slice. No remote access was attempted by this investigation.

**Owner clarification, 2026-10-16:** arrange the Linux machine later. Plumb the project for Linux now and label Linux build/render/package results **UNTESTED** until a real host executes them; missing Linux access does not block authorized Windows development. Linux remains an initial target, and no Windows result may be reported as Linux PASS. For initial personal/internal development, use the currently checked-out development command server through its public contract. A hardened/distributable external host is later delivery work and does not block all client development. This scoped exception supersedes any broader prerequisite wording in this evidence document that would require a distributable runtime or Linux host before Windows development can begin. Preserve separate core ownership and the exact server/contract identity; no core-source modification, public exposure, deployment hardening claim, or portable-runtime proof is authorized or implied. The canonical plan owns the updated gates and experiment authorization.

## RQ05: actual native Windows inventory

Metadata was inspected on 2026-10-16. No compiler or UBT compile was invoked.

| Item | Actual inspected value | Evidence / limits |
|---|---|---|
| OS | X64, Windows NT `10.0.26200`, registry `DisplayVersion=25H2`, build `26200.9457`, edition `ProfessionalWorkstation` | .NET runtime OS metadata and `HKLM/SOFTWARE/Microsoft/Windows NT/CurrentVersion`. Registry `ProductName` says `Windows 10 Pro for Workstations`; retain exact build/edition instead of relying on that legacy label. |
| CPU | AMD Ryzen 9 7950X3D 16-Core Processor; environment reports 32 logical processors | `HKLM/HARDWARE/DESCRIPTION/System/CentralProcessor/0`, `NUMBER_OF_PROCESSORS`. Physical RAM unavailable through permitted CIM calls. |
| GPU | NVIDIA GeForce RTX 4090, registry driver `32.0.15.9186`, reported adapter memory `25757220864` bytes; AMD Radeon Graphics also registered | `HKLM/SYSTEM/CurrentControlSet/Control/Video/*/0000`. Duplicate RTX registry keys do not establish multiple physical cards. No render device or active display was exercised. |
| Disk | C: total `1999297835008` bytes, available `807911202816` bytes at inspection | `System.IO.DriveInfo`; free space is a point-in-time value, not a build size estimate. |
| Unreal | Launcher installed UE **5.8.3**, changelist **58210709**, compatible changelist **55116800**, branch `++UE5+Release-5.8`, promoted build | `C:/Program Files/Epic Games/UE_5.8/Engine/Build/Build.version`; LauncherInstalled.dat independently reports `5.8.3-58210709+++UE5+Release-5.8-Windows`. `Engine/Build/InstalledBuild.txt` exists. |
| Unreal executables | `UnrealEditor.exe`, `UnrealEditor-Cmd.exe`, `UnrealBuildTool.dll`, `Build.bat` exist | Existence only; none launched. |
| Visual Studio | Community 2022 **17.14.41 (September 2026)**, installation version `17.14.37710.0`; complete and no reboot required in installer metadata | `vswhere.exe -all -products '*' -format json`; root `C:/Program Files/Microsoft Visual Studio/2022/Community`. |
| MSVC | Toolchain family/directory **14.44.35207**; actual x64 `cl.exe` product **14.44.35229.0**, file **19.44.35229.0**; x64 linker exists | File version metadata under `VC/Tools/MSVC/14.44.35207/bin/Hostx64/x64`. The directory name and compiler patch differ. |
| Windows SDK | **10.0.22621.0** and **10.0.26100.0** include/lib directories and x64 `rc.exe` exist | `C:/Program Files (x86)/Windows Kits/10`. Actual UBT selection remains to be recorded during an authorized build. |
| .NET | UE-bundled x64 SDK **10.0.203** and `dotnet.exe` exist under `Engine/Binaries/ThirdParty/DotNet/10.0/win-x64` | Global `dotnet --list-sdks` returned none. Global runtime versions include 6.0.11/6.0.16, 7.0.5, 8.0.32, 10.0.13. Absence of a global SDK is not itself a UE blocker: installed `GetDotnetPath.bat` selects bundled .NET 10 unless `UE_USE_SYSTEM_DOTNET=1`. |
| VS Code | `Code.exe` version **1.140.0**, user installation at `C:/Users/Rabid/AppData/Local/Programs/Microsoft VS Code` | Executable file metadata. Extension directories include C/C++ 1.33.8 and 1.34.4, C/C++ extension pack 1.5.1; active extension version not established. No C# extension directory matched the inventory query. |
| Shell discovery | git, gh, code, dotnet, cmake, python, uv resolve; cl and ninja do not resolve in ordinary shell | `Get-Command`; MSVC binaries exist despite cl not being on ordinary PATH. This is not a reason to install a second compiler. |
| Other required hosts | No Linux native build/render host, Linux SDK, or Unreal CI host verified | The app's available remote host is not automatically evidence of access, installed UE, GPU exposure, or acceptance ownership. |

`Get-CimInstance` OS/CPU/RAM/video requests and `Get-Volume` could not access the CIM resource in this execution context. Registry and file metadata supplied the subset above. RAM, active GPU/RHI, real rendered access, and Linux host capability remain unverified. No escalation/install was attempted to make the inventory look complete.

### Compiler compatibility: inspect the executable patch

The current primary Epic 5.8 release notes specify VS 2022 17.14 minimum, recommend VS 2026/MSVC 14.50, and separately name a build-farm combination of VS 2022 17.14, toolchain family 14.44.35207, and SDK 10.0.22621.0. Installed UE metadata is more precise for this build:

- `Engine/Config/Windows/Windows_SDK.json` prefers families `14.50.35717–14.50.99999` and `14.44.35207–14.44.99999`, but bans actual compiler patches `14.44.0–14.44.35210` among other ranges.
- `Engine/Source/Programs/UnrealBuildTool/Platform/Windows/MicrosoftPlatformSDK.cs:IsValidToolChainDirMSVC`, lines 1399–1426, derives compiler version from `cl.exe` product metadata. `AddVisualCppToolChain`, lines 1144–1170, ranks the folder/family separately and tests the actual version against banned ranges.
- Therefore the installed actual compiler **14.44.35229** is not in that installed banned range. The family directory's `14.44.35207` name must not be misreported as a banned actual compiler.
- This establishes a reasonable existing Windows bootstrap candidate. It does not prove UBT discovery, successful compile/link, shader execution, packaging, or native external-runtime delivery. No upgrade is justified by the inspected metadata alone.

## RQ14: proposed basic project and CLI bootstrap

Repository selection is owner-approved. Recommended reversible layout inside this dedicated repository:

```text
AGENTS.md
WarhammerClient.uproject
Config/
Content/
Source/WarhammerClient.Target.cs
Source/WarhammerClientEditor.Target.cs
Source/WarhammerClient/WarhammerClient.Build.cs
Source/WarhammerClient/...
Plugins/TabletopPresentation/Source/{TabletopModel,TabletopHUD}/...
docs/plans/unreal-migration-plan.md
docs/plans/research/
scripts/                         # later, authorized bootstrap/check wrappers
```

No files shown as implementation paths exist by virtue of this proposal. Prefer the project at the repository root; the historical `unreal/WarhammerClient/` prefix served an earlier shared-repository proposal. The coordinator should select one consistent layout in the canonical plan before scaffold work.

The first approved bootstrap should be a minimal C++ Game/Editor target plus one runtime module, without Starter Content or gameplay logic. Inspect the installed `Templates/TP_Blank` as a version-matched reference, rather than blindly copying a script that may target an older UE. Installed targets use `BuildSettingsVersion.V7` and `EngineIncludeOrderVersion.Unreal5_8`. `Config/TemplateDefs.ini` contains folder/file/content substitutions and exclusions; a recursive template-directory copy alone is not an established project-creation algorithm. A reviewed textual scaffold can avoid a graphical project wizard. No generic `-newproject` command was established by the inspected sources or current primary docs.

Both `UE_5.8/GenerateProjectFiles.bat` and `Engine/Build/BatchFiles/GenerateProjectFiles.bat` are absent in this Launcher build. Epic documents project-file generation as a wrapper around UBT's `-ProjectFiles` mode. The installed `Build.bat` forwards arguments to the existing UBT DLL and selects the bundled SDK. Local `GenerateProjectFilesMode.cs` accepts both `-VSCode` and `-2022` in a set, supporting a proposed single invocation for both formats. `-Automated` suppresses a project-format guidance warning; it does not itself promise isolated output or prevent all configuration/cache writes.

The following are **future command candidates, source-inspected but not executed**. They become executable work only under an approved bootstrap/experiment packet:

```powershell
$taskUeRoot = 'C:\Program Files\Epic Games\UE_5.8'
$taskProject = 'C:\SWDev\warhammer\Warhammer_40k_UI_unreal\WarhammerClient.uproject'
& "$taskUeRoot\Engine\Build\BatchFiles\Build.bat" -ProjectFiles "-Project=$taskProject" -Game -VSCode -2022 -Automated
& "$taskUeRoot\Engine\Build\BatchFiles\Build.bat" WarhammerClientEditor Win64 Development "-Project=$taskProject" -WaitMutex
```

Commands do not launch the graphical editor. The wrapper must check each exit code, fail visibly, and retain the exact command/toolchain/build log. Resolve outputs before execution: generated IDE files, project Intermediate/Binaries/Saved/DerivedDataCache, UBT logs/config caches, .NET first-run state and temporary locks are potential writes. Source `GenerateProjectFilesMode.cs:86–90` defaults its log under `Unreal.EngineProgramSavedDirectory`; select supported explicit log/output overrides or obtain authorization for necessary per-user/engine output paths. Never claim all writes are contained by `-Project=`. Do not modify the installed engine, persistent global IDE settings, or existing files to make bootstrap pass. VS Code project generation does not establish a complete debugger/IntelliSense setup; verify the desired active extensions/settings after authorization.

The preferred editor setting needs its own version-specific verification. Installed `Engine/Source/Developer/SourceCodeAccess/Private/SourceCodeAccessSettings.h:10–17` declares `USourceCodeAccessSettings` with `UCLASS(config=EditorSettings)` and marks `PreferredAccessor` as `Config`. `SourceCodeAccessModule.cpp:152–161` reads that setting and matches it against registered accessor names; `Engine/Plugins/Developer/VisualStudioCodeSourceCodeAccess/Source/VisualStudioCodeSourceCodeAccess/Private/VisualStudioCodeSourceCodeAccessor.cpp:182–184` returns `VisualStudioCode`. Therefore the earlier discussion's generic reference to project editor settings must not become an unverified `EditorPerProjectUserSettings` snippet. The bootstrap packet must establish the supported project-scoped EditorSettings configuration layering or override, and verify the effective accessor, before claiming VS Code is configured as preferred. Preserve the user's global editor settings. Generating both IDE formats alone does not verify this preference, and none of these settings was changed during research.

Bootstrap acceptance should record: exact source manifest and engine build; reviewed .uproject/Build.cs/Game/Editor target files; both `.code-workspace` and Visual Studio solution outputs; successful native Development Editor build with selected compiler+SDK; no graphical launch; no core import/rules code; expected generated/untracked paths; bounded log/output locations; and safe rerun/refusal to overwrite user changes. An optional blank Game target build is a separate stated check. Project compilation alone leaves M02's rendered 3D/HUD proofs and M03's packaged real-core workflow unverified.

Runtime/editor ownership should be explicit: `TabletopModel` contains presentation DTOs and command vocabulary; `TabletopHUD` owns shared composition/widgets; the client integration module alone handles the external public contract; battlefield/camera/input belong to the client host; asset generation and editor conveniences belong to editor-only modules. Runtime modules must not depend on UnrealEd, editor Python, or a future vision SDK. No binary asset or external dependency is needed merely to create the basic textual scaffold. LFS/remote storage and large binary ownership are unresolved durable choices; do not silently select or configure them.

### Concrete proposed ownership and dependency map

This expands canonical section 5.1 into reviewable file responsibilities. It is a source-only design, not existing Build.cs metadata or scaffolding. The bootstrap creates only `WarhammerClient`; later authorized milestones introduce the other modules when needed. `X -> Y` means X may depend on Y, never the reverse.

| Proposed file owner | Owns | Permitted project dependency direction / review boundary |
|---|---|---|
| `WarhammerClient.uproject`, `Source/WarhammerClient.Target.cs`, `Source/WarhammerClientEditor.Target.cs` | Runtime/editor module registration, engine association, native targets | Runtime and Editor registrations are explicit. Game target/cook cannot pull an editor-only module into runtime. Version-matched V7/Unreal5_8 settings are reviewed as text. |
| `Plugins/TabletopPresentation/Source/TabletopModel/{Public,Private}/` | Viewer-safe presentation DTOs, stable-ID types, coordinate conversion, pure local reducers, normalized composition types/constraints and safe command vocabulary | Core-level value/container dependencies only; no scene/UMG/UObject ownership, HTTP, Python, core internals, or host-specific camera. Rules legality remains absent. |
| `Plugins/TabletopPresentation/Source/TabletopHUD/{Public,Private}/` | C++ UMG/Slate widgets and bindings, composition serialization adapter, layout allocation, profile preview, style/typography | `TabletopHUD -> TabletopModel`; engine facilities limited to reviewed UMG/Slate/CoreUObject/Engine needs. Parser integration stays private behind normalization and requires E04/dependency review. No dependency on WarhammerBattlefield/CoreClient or concrete observation source. |
| `Source/WarhammerCoreClient/{Public,Private}/` | Selected 44.3.33 contract DTO parsing/serialization, negotiation, HTTP/session/revision/cursor/retry state, managed-runtime adapter and attachment transport | `WarhammerCoreClient -> TabletopModel`; reviewed HTTP/JSON/platform facilities. No HUD/scene dependency or private core access. Consume an externally supplied host; this module does not create a new Python host. |
| `Source/WarhammerBattlefield/{Public,Private}/` | Mesh/token presenters, query proxies/support picking, camera, world annotations, event-to-presentation intent | `WarhammerBattlefield -> TabletopModel`; Engine/Input/render dependencies as needed. No direct CoreClient submission or profile parsing. World selection returns stable IDs/intents to the app. |
| `Source/WarhammerClient/{Public,Private}/` | Application/session coordinator, selected viewer and connection generation, workflow reducers/dispatch, synchronized world/roster focus, profile and exact-core continuity UX | `WarhammerClient -> TabletopModel + TabletopHUD + WarhammerBattlefield + WarhammerCoreClient`; calls safe typed ports, holds no duplicate rules path. External results return through generation/viewer checks before updating presentations. |
| `Source/WarhammerClientEditor/{Public,Private}/` | Reproducible asset import/generation, asset validation and development preview tools | Editor-only module may depend on runtime modules and UnrealEd/AssetTools. No runtime module points back to it. Runtime preview composition is provided by TabletopHUD, so preview does not require an editor module in a shipped client. |
| Later separate demo/test host and recorded-observation adapter | Synthetic observations, identity registration and shared-HUD host without a battlefield camera | Demo -> TabletopModel/TabletopHUD. Production modules do not depend on demo, a CV SDK or physical calibration implementation. |
| `tests/migration/fixtures/<exact-core-sha>/`, manifest and corresponding module `Private/Tests/` | Approved immutable viewer-safe contract/profile/geometry cases; named engine/low-level tests | Fixtures include core/contract/catalog/hash provenance. No sensitive real saves. Engine automation registration/test build exclusion is reviewed in the owning module; a fixture row does not create a working test. |
| `Config/`, `Content/`, plugin content and import manifests | Text settings; approved meshes/materials/fonts/UMG authoring resources; provenance/import settings | Authoring assets contain visual composition, not rules/authority. Each binary asset has one named writer per change and semantic import/rebuild/cook evidence. No LFS/locking remote configuration is selected here; resolve storage before adding assets that require it. |
| `scripts/`, `docs/plans/`, later `.artifacts/<packet>/<host>/` | Reviewed wrappers, canonical decisions/acceptance, isolated generated logs/reports/traces | Bootstrap wrapper is written only under its packet. Generated IDE/Intermediate/Binaries/Saved/cache/report output is not hand-maintained source. Track concise manifests/decisions; keep large execution artifacts in approved isolated output with hashes and retention stated. |

All `.Build.cs` files are the enforceable dependency declaration and require review against this direction. Headers expose typed ports/value types; implementation-only parser, HTTP and editor includes stay Private. A later rebuild/cook must inspect runtime module closure and fail on a runtime-to-editor dependency, rather than relying on this table as proof.

## RQ06 and RQ12: viewer and HUD research limits

Legacy `5088c1c...:src/warhammer40k_arcade_ui/core_client/local_session_client.py:get_view`, lines 77–82, updates `_last_viewer_player_id`; `get_events_since`, lines 104–115, explicitly requires the viewer. `_projected_decision_for_status`, lines 194–204, uses `request.actor_id or self._last_viewer_player_id` and retrieves that viewer's public pending decision. This is source evidence of local actor-following convenience, not approval to switch an authenticated remote user's identity. Local, remote-participant and spectator requirements are now owner-selected as recorded above; the final role matrix still needs selected-44.3.33 authorization evidence from the integration investigation. A spectator receives only its authorized projection and submits no game-effecting choice. Reconnection/viewer change tears down viewer-bound drafts, pending callbacks, highlights and caches before displaying the newly authorized view. Test credentials/privileged observability never become normal HUD inputs.

Legacy HUD docs contain actual `size_px` preferences, including a 276-pixel example in `docs/hud-customization.md:70`; `docs/ui-configuration.md:97` calls them preferred pixels. Epic's DPI documentation supports automatic scaling and a curve; its UI settings documentation exposes application scale, scale rules and high-DPI awareness. These facilities do not prove the plan's proposed sidebar allocation, focus/scroll usability, or compatibility with current profiles. Preserve legacy sizing semantics through an explicit import mode. Treat `clamp(0.25 * allocated logical width, 288, 480)` and drawer behavior as proposed policy. E04 must inspect actual allocated geometry, supported profile semantics and live/preview composition at the plan's resolution/DPI matrix. No rendered HUD proof was performed.

The proposed composition seam is concrete: TabletopHUD's serializer reads a supported profile into TabletopModel's normalized tree, whose nodes have stable widget IDs, whitelisted widget kind, named viewer-safe bindings/typed commands, explicit zone/tab/container relationship, sizing mode (`legacy_pixels` or proportional logical allocation), constraints, overflow/wrapping and focus order. Preserve recognized inactive entries/extensions without enabling them; unsupported versions/bindings produce typed diagnostics. The app supplies viewer-scoped binding values and command dispatch; the tree cannot read raw core state or manufacture options. Runtime HUD and preview consume this same normalized tree; only preview can supply explicitly labelled sample data.

For each viewport/scale change, the HUD root obtains its allocated logical safe content rectangle; a layout allocator derives main and sidebar slots; each slot contains header/tab chrome plus a scrollable body with reachable action controls. Width policy is evaluated in that one logical coordinate space, once. If the proposed 640-unit main minimum would fail, the sidebar becomes an explicitly opened overlay/drawer with a defined close/focus-return target and world-input exclusion. Text scale is distinct from overall DPI scale; long IDs support wrapping/truncation/copy; keyboard focus follows declared node IDs through reflow/collapse. Normalized-tree tests check import/round-trip and policy mathematics; only E04's real Slate/UMG geometry, focus and input traces verify parent allocation and actual usability. This design preserves owner-required profiles without approving a new drag-and-drop HUD editor or an untested YAML dialect mapping.

## RQ18 and RQ20: validation and evidence plan

The observed workstation is a candidate Windows development/render host, not the accepted minimum hardware. No W0/W1/W2, latency, startup, memory, frame-time, or GPU-residency measurements exist from this investigation. The plan's budgets remain proposed. RAM and host access must be recorded before selecting reference hardware; owner minimum hardware/responsiveness priorities remain open. CPU/GPU metadata alone does not satisfy E05.

Legacy CI at `5088c1c...:.github/workflows/ci.yml:17` pins core `fc12fa214642f1b1f2a31b56be7323b7d76dbebc`. Existing jobs run on `ubuntu-latest`, install Python 3.14.5/dependencies, and split fast/integration coverage at lines 108–109 and 156–157. They are Python/Arcade checks with headless OpenGL dependencies, not Unreal build/render/package infrastructure. Workflow source was inspected; no remote run was fetched by this investigation. The coordinator's installed-core provenance mismatch prevents treating an unprepared local integration environment as valid evidence; do not synchronize it during research.

The coordinator separately ran the existing static boundary check from the Arcade root: `.\.venv\Scripts\python.exe -I -B scripts\check_import_boundaries.py`, exit 0, `Import boundary check passed`. The interpreter reported Python 3.14.5 but also warned that it failed to find the real location of a uv-managed Python executable. This is an actual passing static boundary check with a recorded interpreter warning; it does not prove core/dependency imports, real game execution or integration-test readiness. No integration suite was run.

| Evidence layer | Future acceptance | Existing evidence / execution status |
|---|---|---|
| Documentation | `git diff --check`, actual referenced-path/command verification | Existing Git command, appropriate to these planning edits; coordinator performs final repository-wide check. |
| Low-level/headless | DTO/schema rejection, units/handedness, IDs, reducer state, retry/viewer isolation, configuration normalization | UE framework documented; no Unreal project suites exist. Use low-level tests for code that does not need engine systems. |
| Rendered editor/runtime | Real camera/picking/elevation/mesh swap, HUD allocation and focus/input, DPI/content | Actual graphics-enabled native host required. NullRHI or successful compilation cannot pass these. |
| Packaged | Cook/stage/package on each approved OS; real canonical accepted command; exact external runtime/service and failure recovery | No package, external host artifact or clean-machine result verified. |
| Performance | W0 real-core and W1/W2 presentation workload identities, warmup/sample statistics, timings split by client/core/transport | No workload measured. Unreal/Slate Insights are later instruments, not evidence by being named. |
| Independent review | Frozen base/head and exact requirement/evidence packet; PASS/CHANGES_REQUESTED/BLOCKED with verification limits | Legacy `.codex/agents/sol-code-reviewer.toml` and `astra-auditor.toml` define read-only review/audit roles. Their presence does not prove invocation or context isolation. This investigation is not an independent acceptance review. |

Epic documents `Automation RunTest` and `-ReportExportPath`; no `Warhammer.Migration` suite was created or executed. Future invocations must verify discovered test names/counts and exported per-test results, with timeout/crash handling. An empty filter or zero process exit without test results is not success. Rendering tests require a real RHI; packaged runtime and human inspection remain separate evidence.

### Host and output responsibilities by test layer

These are proposed responsibilities for the coordinator to assign to actual named executors/hosts in each authorized packet. The Windows workstation is inventoried; Linux host/SDK/runtime/GPU access is not. Both platforms are required from M03, so missing Linux evidence blocks that slice rather than removing Linux from scope.

| Layer / planned evidence | Executor and host responsibility | Required inputs and outputs / stop condition |
|---|---|---|
| Documentation and source boundary | Documentation owner, destination Windows workspace; static Arcade check stays in Arcade | Frozen source references, changed-document/path check, `git diff --check`, actual static-check result/warning. Save concise reviewed evidence under docs; no install/sync. |
| Native bootstrap (`BOOT01`, packet consolidated in canonical plan) | Build owner, inventoried Windows UE5.8.3 host initially | Exact scaffold/module/engine manifest, both IDE outputs, selected compiler/SDK and build exit/log, permitted write paths. This is compile/generation proof only; no GUI/render claim. |
| Pure value/reducer/normalization and protocol parser tests | Owning module developer; Windows and Linux headless build/test runners once prepared | Approved exact-core 44.3.33 fixture/profile namespaces; discovered named cases with expected count fixed in the work packet, per-case pass/fail, seeds/tolerances, malformed/wrong-viewer/stale negatives. No suite/count exists yet. Engine-independent low-level tests need no world/RHI. |
| E01 public transport/authorization/retry | Integration owner; isolated selected-core service/runtime plus prepared client test host | Immutable core/runtime/hash and canonical setup, participant/spectator credentials with safe redaction, normalized request/result/revision/cursor traces and denial/duplicate/conflict results. Never infer authenticated permissions from local actor-following convenience. Missing exact fixture/host is BLOCKED. |
| E02/E04 rendered 3D/HUD/input | Rendering/UI owner on real Windows and Linux graphics hosts | Matching engine/content/profile/viewport/DPI manifests; actual RHI/GPU/driver; geometry/layout dumps, screenshots, semantic focus/input traces, per-case results and human notes. No NullRHI; record unavailable display/input access as BLOCKED. |
| E03A/E03B packaged local/attach/remote/spectator | Build/release owner plus external-core artifact owner; clean Windows x64 and Linux x86-64 test environments | Package and runtime hashes, SDK/native-library closure, user-writable paths, no dev-Python dependency, local offline startup/owned-process stop, attach non-interference, remote/auth/spectator denials, accepted real command and uncertain-result recovery logs. Exact-core continuity, preserved profile originals; no cross-client midgame-switch requirement. |
| E05 performance | Performance owner on recorded native Windows and Linux reference hardware | Declared W0/W1/W2 sources and sample/warmup policy, CPU/GPU/frame/core/transport boundaries, `.utrace`/Slate traces and timing/memory tables. Compare like workloads/core identity; registry inventory is not measurement. |
| E06/E07 recovery/reuse | Data/reuse owners; prepared exact-core package host and separate demo host | Original-file byte hashes/backups and compatibility routing; interrupted-write results; same shared HUD in camera-independent host; observation/identity/staleness traces and synthetic transforms. No real private save copied into public evidence. |
| Independent review and acceptance audit | Separate reviewer/auditor sessions selected by coordinator | Frozen base/head, requirement/capability/fixture/host manifests and retained artifact hashes, no implementation narrative as evidence; verdict and verification limits. Configured reviewer files do not establish fresh-session invocation. |

Each execution packet declares a unique approved output root such as `.artifacts/<packet>/<host>/`, timeout, actual suite/filter, expected nonzero test count and artifact retention. Test JSON/HTML, logs, images and traces have hashes in the concise evidence manifest; secrets/private state are redacted before retention. No output root, ignore rule, wrapper or test was created here. Linux compilation may use a version-pinned native or Windows cross toolchain, but Linux rendered/packaged acceptance still runs natively with an approved external runtime.

### Test arguments: inspected support, no execution claim

Installed UE5.8.3 source supports only the following claims about a future invocation:

- `Engine/Source/Runtime/Core/Private/Misc/App.cpp:274–279` parses `-unattended`; this does not provide a graphics host or all input routing.
- `Engine/Source/Runtime/Engine/Private/UnrealEngine.cpp:2552` queues `-ExecCmds` commands.
- `Engine/Source/Developer/AutomationController/Private/AutomationCommandline.cpp:610–626` parses `Automation RunTest`/`RunTests`; lines 726–734 queue `Automation Quit`; lines 478–504 process the automation queue and make reports/errors affect the exit status.
- `AutomationControllerManager.cpp:233–247` parses `-ReportExportPath=` and `-ResumeRunTest`. Report export writes to the supplied path. Resume is not a clean-run substitute; no resume run is requested by this plan.

A future source-supported command pattern may therefore use `-unattended`, `-ExecCmds="Automation RunTest <actual-registered-filter>;Automation Quit"`, and `-ReportExportPath=<approved-output>`. Angle-bracket values are placeholders; the filter must be discovered after tests exist. This is deliberately an automation-aware queued quit, with per-test exported evidence and an external timeout, not an assumption that any generic exit command waits for tests. Linux installed-source/engine parity and target executable test availability must be verified on its actual host. No command pattern here proves a suite exists, flags are accepted by a packaged configuration, a headless run can render, or a test passed.

## RQ21: distribution/provenance

The sibling core's `LICENSE` at `5f5097...` contains Apache 2.0 text. No root `LICENSE` or matching tracked license file was found in the legacy UI with the limited `rg --files -g '*LICENSE*' -g '*license*'` search. This is not a determination of rights to all core data, fonts, artwork or Warhammer material. Personal/internal distribution intent is now owner-selected. The destination's intended source license and content/artifact provenance still need recording; external-distribution clearance remains a release gate rather than an invented requirement for broad publication now. Current Epic license and EULA pages were retrieved, but no project-specific legal clearance is inferred. Do not add external-release promises, purchases, assets, or dependency commitments during planning. Appropriate release/provenance review remains M07/M08 work with a named owner.

## RQ23/RQ24: proposed bounded next packet and dispositions

Source-only progress does not close mixed owner/empirical requirements:

| RQ | Disposition supported here | Remaining dependency |
|---|---|---|
| RQ05 | Windows engine/compiler/SDK metadata `CLOSED_SOURCE`; platform requirement `CLOSED_OWNER`; overall `OPEN` | Both OS targets are required from first playable slice. Minimum/reference hardware, RAM/real render-host evidence, Linux host/SDK/access, selected engine approval and native build proof remain. |
| RQ06 | Local viewer-following source recorded; local/remote/spectator modes `CLOSED_OWNER`; overall `OPEN` | Exact selected-44.3.33 role/authorization and reconnect/cache matrix plus transport proof. |
| RQ12 | Proposed normalized tree/layout seam and documented DPI facilities recorded; overall `OPEN` | Full dialect/profile mapping depends on RQ11; actual E04 allocation/focus/input compatibility remains empirical. |
| RQ14 | Destination repository/path owner-selected; concrete file/module dependency and artifact ownership design recorded; overall `OPEN` | Coordinator selects consistent layout; authoring/output/rebuild packet, any durable binary storage commitment and runtime dependency closure need later authorization/proof. |
| RQ18 | Inventory and measurement design only; overall `OPEN` | Approved hardware/workloads/budgets; no measurements. |
| RQ20 | Legacy CI/reviewer definitions, UE command parsing and proposed per-layer host/output responsibilities recorded; overall `OPEN` | Final per-capability case/fixture map; actual Linux and Unreal/package/render hosts; registered suites/counts; independent review facilities/evidence. |
| RQ21 | Personal/internal intent `CLOSED_OWNER`; license sources and missing provenance recorded; overall `OPEN` | Destination license/provenance and named future external-release rights owner; no external legal clearance claimed. |
| RQ23 | Windows bootstrap and E02/E04/E03 empirical gaps identified; overall `OPEN` | Root consolidates other RQ findings; execution-dependent subquestions remain `BLOCKED` until explicitly authorized and passed. |
| RQ24 | Supporting evidence delivered; overall `OPEN` | Canonical-plan reconciliation, owner answers, checks and final independent review status. |

The smallest next executable packet is **BOOT01: native Windows C++ bootstrap**, consolidated and authorized through the canonical plan. Its allowed implementation files should be the minimal root .uproject, Source/Config, a reviewed bootstrap wrapper and documented ignore rules; generated artifacts/logs stay in approved locations. Prerequisites: confirm project layout/name and UE 5.8.3 candidate, inspect existing destination changes, establish cache/log write authority, retain installed engine unchanged. Pass: both IDE outputs and one native Development Editor build with captured selected compiler+SDK and no graphical launch. Fail/stop: missing prerequisites, attempted installs/global configuration changes, writes outside approved output scope, unsupported toolchain, build timeout/failure, unexpected overwrite. Preserve failing logs; do not delete shared files or install alternatives automatically. BOOT01 proves Windows bootstrap only and grants no feature porting or waiver of the required Linux first-playable slice.

Architecture proof packets E01 (exact-core transport), E02 (3D picking/coordinates/mesh replacement), E04 (HUD/profile compatibility), and E03A (external runtime/platform delivery) remain separately bounded. Required endpoints/artifacts, selected platform/role/deployment choices and permitted fixture identities must precede them. E03B/M03 gameplay acceptance and E05–E08 remain later milestone evidence where the code does not yet exist. No source reading makes any experiment PASS.

Recommended strong Unreal `AGENTS.md` requirements: preserve separate core authority and public contract; read the canonical plan and active research/authorization gates first; explicitly map `_arcade`/logical `Warhammer_40k_UI` and read-only AI; keep production parsing strict and viewer state isolated; preserve stable IDs, schema/fixture hashes, units/elevation and advisory labels; enforce runtime/editor/module dependency direction; generated artifacts are rebuildable and excluded from source review; binary assets have a single writer plus provenance/import inputs before adoption; use version-pinned native CLI builds and both IDE formats; never silently launch GUI, install tools, synchronize Python environments or edit the sibling core; distinguish source, passed tests, owner choices and empirical blockers; define layered validation and frozen-candidate independent review; protect unrelated files and credentials; use workspace-approved `github-full-access` through GH_TOKEN for authorized gh actions without printing its content. Research-only publication/branch restrictions in the plan still apply until explicitly changed.

## Primary documentation retrieved 2026-10-16

All Unreal technical references below identify UE **5.8** in the retrieved primary-source result. Some direct `en-us` fetches returned inaccessible/internal-error responses; the listed alternative canonical/search-result URLs supplied the stated content. Public documentation is not local execution evidence.

| Source | Supported claim |
|---|---|
| [Epic UE 5.8 release notes](https://dev.epicgames.com/documentation/unreal-engine/unreal-engine-5-8-release-notes) | VS/MSVC/SDK and Linux version recommendations; build-farm combination. Local installed Windows SDK JSON remains the finer patch-specific source. |
| [Epic Visual Studio setup](https://dev.epicgames.com/documentation/pt-br/unreal-engine/setting-up-visual-studio-development-environment-for-cplusplus-projects-in-unreal-engine) | Retrieved English fallback supports VS 2022 17.14+ / VS 2026 18.0+ for UE5.8. |
| [Epic VS Code setup](https://dev.epicgames.com/documentation/unreal-engine/setting-up-visual-studio-code-for-unreal-engine?application_version=5.8) | Separate IDE/compiler requirements and VS Code project generation; changing default editor is not required for command-line generation. |
| [Epic IDE project generation](https://dev.epicgames.com/documentation/unreal-engine/how-to-generate-unreal-engine-project-files-for-your-ide) | Generator wraps UBT `-ProjectFiles`; generated IDE projects are not needed by UBT's source-discovery/build mechanism. |
| [Epic Linux requirements](https://dev.epicgames.com/documentation/unreal-engine/linux-development-requirements-for-unreal-engine?lang=en-US) | UE5.7–5.8 v26 clang20.1.8; Windows cross-compilation and fixed native sysroot. Does not certify any local Linux host. |
| [Epic Automation Framework](https://dev.epicgames.com/documentation/en-us/unreal-engine/automation-test-framework-in-unreal-engine) | Unit/feature/content/screenshot categories, engine-system dependency and lower-level-test distinction. |
| [Epic command-line automation](https://dev.epicgames.com/documentation/unreal-engine/run-automation-tests-in-unreal-engine?lang=en-US) | RunTest filters and exported JSON/HTML reports. |
| [Epic DPI scaling](https://dev.epicgames.com/documentation/en-us/unreal-engine/dpi-scaling-in-unreal-engine) and [UI project settings](https://dev.epicgames.com/documentation/unreal-engine/user-interface-settings-in-the-unreal-engine-project-settings?lang=en-US) | Application scale, DPI scale/curve and high-DPI awareness are distinct configurable facilities. |
| [Epic license](https://www.unrealengine.com/license) and [EULA](https://www.unrealengine.com/eula/unreal) | Current primary review inputs only; no client-specific licensing conclusion or clearance obtained. |

### Installed-file SHA-256 identities

Paths below are relative to `C:/Program Files/Epic Games/UE_5.8`:

| Path | SHA-256 |
|---|---|
| `Engine/Build/Build.version` | `EAB58750E84719489F3EE0D42D05A533CEB357EB3EE511777E9408D27A85F43C` |
| `Engine/Config/Windows/Windows_SDK.json` | `CB8A438DF72F7068256547A9A225908DEEDFBF3226D893FDDD1526AE686D74D3` |
| `Engine/Source/Programs/UnrealBuildTool/Modes/GenerateProjectFilesMode.cs` | `504EB6AB2EE0F824A1DAA8830A666828D2AD027FF4D7DE4177FEC9CEA9016329` |
| `Engine/Source/Programs/UnrealBuildTool/Platform/Windows/MicrosoftPlatformSDK.cs` | `F58410D3A3473687DE4AEFDD9A8F8FF4A19CC01EDB043ACF5604575C5DAC9374` |
| `Engine/Build/BatchFiles/GetDotnetPath.bat` | `6383A2535C0E551817289231E1755BDE58456785FE3B3DBC1D7BAA9134EB12CB` |
| `Engine/Source/Developer/SourceCodeAccess/Private/SourceCodeAccessSettings.h` | `47587ECEE79D4549A194FF3F79A18AAEAB234DAF264D54408BDA966B5E241DB4` |
| `Engine/Source/Developer/AutomationController/Private/AutomationCommandline.cpp` | `A040ADEE46CDECDCBE5C8148C6203211FD59559EA0A73CE748D5725399B899B3` |
| `Engine/Source/Developer/AutomationController/Private/AutomationControllerManager.cpp` | `FA7C0485912A80E9B47E26D5ED066D7A300008DB59FAD4C214280D807ABA54B1` |
| `Engine/Source/Runtime/Core/Private/Misc/App.cpp` | `56526F1636F70829D5B7E63C126E3965E176065BB31502F2D539F6BCD732BB3A` |
| `Engine/Source/Runtime/Engine/Private/UnrealEngine.cpp` | `A856525BD245039126444FF9978C1BF68FFADD76AEAF340B01DA30D608AF84BF` |
| `Templates/TP_Blank/Source/TP_Blank.Target.cs` | `2EB81934EB4E66F73EB60867B0837C2E7D679EAD6190584AE745B40413595371` |
| `Templates/TP_Blank/Config/TemplateDefs.ini` | `F84C653A16981720DB0E28DEF2B1DB90B9AC7AE3051A2E5082B5D7AB10E5EE95` |
