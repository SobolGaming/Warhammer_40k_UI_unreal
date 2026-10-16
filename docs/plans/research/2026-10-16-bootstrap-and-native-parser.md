# Bootstrap output authority and native parser candidate

Date: 2026-10-16. The packet below records the source/environment research before
execution. It supplements Section 8.4 and RQ05/RQ11/RQ14/RQ23. **OWN11 subsequently
approved BOOT01, and Windows probe/final compilation/UHT and IDE generation passed**;
see [actual results and limits](../evidence/2026-10-16-boot01.md). No dependency
install or parser experiment occurred. Historical proposal language below is not
the current execution status.

## BOOT01 reviewable execution scope

Proposed first executable packet: minimal **Windows C++ bootstrap only**, with
Linux-capable Game/Editor targets and Linux execution explicitly NOT RUN (OWN08).
Permitted authored files after authorization:

- `WarhammerClient.uproject`, `Source/WarhammerClient.Target.cs`,
  `Source/WarhammerClientEditor.Target.cs`, and `Source/WarhammerClient/` for a
  primary runtime module and minimal reflected GameMode.
- Minimal `Config/`, empty `Content/`, `.gitignore`, and a reviewed
  `scripts/New-UnrealCppProject.ps1` / verification wrapper. The wrapper is new
  execution tooling, so it is not created during research.
- Setup documentation updates; no transport/gameplay implementation, new Python
  host, plugin adoption, binary art, Core/Arcade edits or remote publication.

Probe/staging/log/output roots: this repository's
`.local/experiments/BOOT01/`, plus final project `Binaries/`, `Intermediate/`,
`Saved/`, `.vscode/`, generated solution/workspace/project files and local cache
directories recorded by the wrapper. No source promotion may collide with docs,
`AGENTS.md`, `.git` or user changes. Probe and final path both need the initial
Editor compile and generators; rerun generation at final path, not stale staging
references. Use existing UE5.8.3 tools; install/upgrade nothing.

Set a **30-minute timeout per build/generation process** for the first proof,
capturing progress/logs. On timeout or failure stop only the process tree started
by this packet, preserve artifacts and report the failing command. Do not start
a graphical app. Pass requires an actual Development Editor compile/UHT pass,
both VS Code and VS2022 outputs at final path, recorded selected compiler/SDK,
expected generated files, and an unchanged sibling/status check. No runnable-map,
rendering, package, Linux or debugger-activation PASS follows from this result.

Do not remove failed evidence automatically. Cleanup needs resolved absolute-path
checks showing that every target is a packet-owned generated path; no recursive
delete of a computed unchecked path, shared engine/cache or user directory.

## Installed UBT writes that project selection does not isolate

Local source identity is installed UE **5.8.3 / CL58210709**, not an Epic Git SHA.
Relevant source under `C:/Program Files/Epic Games/UE_5.8/Engine/Source/Programs/UnrealBuildTool`:

SHA256: `GlobalOptions.cs` = `7981d3e552e971b22ec0cf2021d86c944c764d84e4515085d6d3467599af393a`;
`Configuration/Xml/XmlConfig.cs` = `8327a6fc80fbe88abcc571cad3d404b19451917584211ac217485e1ff5ba5e8c`.

- `GlobalOptions.cs:29–34` accepts `-Log` to supply a task-owned log path.
  `Modes/GenerateProjectFilesMode.cs:84–94` uses its default engine/program log
  only if no writer is already configured. Pass explicit log paths for each run.
- `UnrealBuildTool.cs:327–331` supports `-XmlConfigCache=`, but
  `Configuration/Xml/XmlConfig.cs:88–98` treats that as an **existing serialized
  cache input**. It is not a general writable-cache redirection flag; do not pass
  a nonexistent path and call it isolation.
- Normal project XML cache paths use project Intermediate, but installed UBT
  still enumerates global settings. `XmlConfig.cs:300–367` creates an empty
  default Roaming UBT configuration if absent. A read-only check found
  `C:/Users/Rabid/AppData/Roaming/Unreal Engine/UnrealBuildTool/BuildConfiguration.xml`
  **absent** on this machine. A build may therefore create it even with a project
  and explicit log path.

BOOT01 authorization must include normal per-user .NET/Unreal/compiler caches
and creation of that **empty default UBT configuration only if still absent**,
or an independently source-verified isolation solution. Preserve any existing
configuration byte-for-byte; do not edit global IDE/toolchain preferences or
the engine installation. Record before/after file identity and all observed
non-project outputs. This is a concrete build-tool side effect, not an assertion
that all writes can be redirected. Unexpected settings/engine writes stop proof.

`systeminfo` could not supply RAM and returned a credential/context error; it is
not a successful hardware check. The earlier CIM limitations remain. No system
credential was requested or changed.

## Native YAML parser candidate source

Retrieved **2026-10-16**, primary upstream sources:

- [Release yaml-cpp-0.9.0](https://github.com/jbeder/yaml-cpp/releases/tag/yaml-cpp-0.9.0)
  resolves to [commit 56e3bb550c91fd7005566f19c079cb7a503223cf](https://github.com/jbeder/yaml-cpp/commit/56e3bb550c91fd7005566f19c079cb7a503223cf).
  The correct tag includes `yaml-cpp-`; the initially attempted bare `0.9.0`
  release URL returned 404 and supplied no evidence.
- [CMakeLists at the release](https://github.com/jbeder/yaml-cpp/blob/yaml-cpp-0.9.0/CMakeLists.txt)
  declares version 0.9.0, defaults to C++11 unless configured, exposes static/shared
  linkage, PIC and MSVC runtime controls. E04 must build with the same ABI/runtime
  and selected Unreal compiler; no binary compatibility is claimed from CMake.
- [Release license](https://github.com/jbeder/yaml-cpp/blob/yaml-cpp-0.9.0/LICENSE)
  is MIT. Preserve notices if later adopted; no library is downloaded or installed.

This is an immutable **evaluation candidate**, not dependency adoption or a passing
YAML compatibility result. Compare its parser/node behavior against the actual
PyYAML6.0.3 source-derived semantic corpus in the capability checklist. In
particular, YAML1.2 branding does not preserve the old Boolean/numeric/merge/
duplicate-key resolver by itself. E04 must specify explicit normalization,
bounded input/depth/alias handling, diagnostics and unsupported-value rejection.
The native parser's platform/runtime and semantic questions remain empirical
blockers; there is no reason to add it merely for BOOT01's blank C++ module.
