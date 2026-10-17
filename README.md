# Warhammer 40k Unreal client

This repository develops a C++ first, genuinely 3D Unreal client for the separate
authoritative Python rules engine. `WarhammerClient.uproject` is the minimal C++
foundation. The migration plan records bootstrap evidence and remaining gates;
the shell does not yet contain a playable scene or a Core connection.

- Read [AGENTS.md](AGENTS.md) before work.
- Follow the canonical [migration plan](docs/plans/unreal-migration-plan.md), starting
  with Section 0 and its research/experiment/implementation gates.
- `../Warhammer_40k_UI_arcade` is the legacy client, also called `Warhammer_40k_UI`
  in the owner's request. It supplies behavior and configuration references.
- `../Warhammer_40k_AI` is the reference-only authoritative core. This migration
  consumes its public contract and separately delivered runtime; it does not edit it.

Native Windows development, VS Code, and command line project/build/IDE generation
are established preferences. The plan includes bootstrap prerequisites, commands
and acceptance criteria; engine presence alone does not establish a successful build.

## Current development selections

The owner selected Core commit `5f509724da25a2f6ded0c2739a8e7c84bdf59c91`, external
contract **44.3.33**; its source adaptation review is recorded in the plan. Arcade remains the separate
44.1 characterization baseline. Windows x64 and Linux x86-64 are planned for the
client. The owner will arrange the Linux machine later: plumb Linux targets and
portable seams now, and explicitly mark Linux build/render/package results
**NOT RUN** until that host exists. Windows development can proceed. Local play,
remote participants and spectators, and both
client-managed local Core launch and connection to an existing service are required.
Development starts as personal/internal use. Preserve supported profiles; session
data remains paired to its exact Core. Midgame switching back to Arcade is not required.

There is no playable client executable or Core launch switch yet. The procedures below prepare or
run the existing Python rules Core for development. The separate
[E01 developer proof](docs/plans/evidence/2026-10-16-e01-boundary.md) records an
actual isolated, locked Windows installation and its boundary checks. The original
30-second run passed 38 Python tests and 11 boundary checks, but timed out on the
invalid-geometry command; that run remains failed with completion unknown.

The owner-approved `E01-SLOW120` diagnostic completed normal run
`20261017T044903Z-b0169768` on source `d1189592a5f99bdee58cea25ae8546e5ee2e3623`:
87 Python unit tests in 15.167 seconds, 14 Capture checks, 132 unique native
Automation successes and two automated evidence checks passed. The 14 include
source/runtime/schema checks alongside live HTTP checks; 135 pure PowerShell
controls with 39 stable inputs are separate pre-execution evidence. Auxiliary
privacy inspection and exact-byte promotion preceded Native. All six real
editor-settings before/after observations matched, alongside UBT and authored
Config checks. Capture retained distinct recorded-invalid and accepted movement
outcomes; all five accepted model XYZ endpoints matched within `1e-9`.

The three uncommitted inventory rejections returned HTTP 422, `proposal_invalid`,
and `"Submitted proposal was invalid."` The diagnostic preserves that response and
the notice `"Detailed engine reasons were not supplied by this HTTP response."`
([Core #588](https://github.com/SobolGaming/Warhammer_40k_AI/issues/588)).

Aggregate transport observations were 139 HTTP requests with maximum 31.1409296
seconds, and 129 local requests with maximum 32.0962418 seconds. These maxima do
not establish per-command attribution, the old 30-second budget or production
responsiveness ([Core #590](https://github.com/SobolGaming/Warhammer_40k_AI/issues/590)).
The [factual result](docs/plans/evidence/2026-10-16-e01-slow120-result.json) records
**BOUNDED_E01_SLOW120_ACCEPTANCE_RECORDED** at `2026-10-17T06:00:32.004673+00:00`.
Root combined [CODE r13 PASS](docs/plans/research/2026-10-17-e01-slow120-code-review-r13.md) with the valid
[initial REQ r3 BLOCKED](docs/plans/research/2026-10-17-e01-slow120-requirements-r3.md) and its separate
[administrative supplement PASS](docs/plans/research/2026-10-17-e01-slow120-requirements-r3-administrative-supplement.md),
which closed A1/A2. The initial REQ verdict remains BLOCKED. The contaminated
[original REQ r2](docs/plans/research/2026-10-17-e01-slow120-requirements-r2.md) is invalid and supplies no approval.
The [final review provenance](docs/plans/evidence/2026-10-17-e01-slow120-final-review-provenance.json) binds reviewed
candidate `b97ed5e8c1b2b2a1472aeb7fb70a267e0eab3d37`, cumulative base `0467ee63fe6d4c775f429afae2233d7292787c31`
and the unchanged `044903` execution on source `d1189592a5f99bdee58cea25ae8546e5ee2e3623`.
The later publication commit is a separate metadata overlay; the reports did not
review that later commit. Execution is stopped. The narrow diagnostic is accepted;
full E01/M01/M02, research gates, the 30-second budget, production responsiveness,
UE HTTP, rendering, packaging and Linux remain open. The [E02 packet](docs/plans/research/2026-10-16-e02-world-input-packet.md) is now
adopted for bounded source authoring; its [authority journal](docs/plans/evidence/2026-10-16-e02-world-input.md)
records the gates. No E02 build/native/input/render result exists yet.

The historical `030835` run retains its missing
six-path editor-settings comparison as **UNVERIFIED** in its
[byte-exact archive](docs/plans/evidence/2026-10-17-e01-slow120-result-030835-schema2-history.json);
the new run does not retroactively fill that gap. The journal preserves all earlier
failures and unknown outcomes. The prior revision-17 pending state is retained
as dated history in the canonical plan and journal.

The manual installation alternatives below are not E01's executed commands. Unreal
project creation/build is specified in
[plan Section 8.4](docs/plans/unreal-migration-plan.md#84-basic-unreal-project-bootstrap--boot01).

## Build the Unreal project on Windows

Use the inspected Launcher installation **UE 5.8.3 / CL58210709**, VS2022 17.14,
MSVC **14.44.35229** (tool folder `14.44.35207`), Windows SDK **10.0.22621.0**,
and Unreal's bundled .NET **10.0.203**. No global .NET SDK or compiler on `PATH`
is required. VS Code's C/C++ extension is present; the optional C# extension was
not found and was not installed. Active editor accessor/debugger behavior has
not been tested.

VS2022 generates the C++ solution successfully but omits Unreal's .NET 10 C#
tooling projects. Unreal also generates `Automation_WarhammerClient.sln` / `.slnx`
for VS2026. Opening/building that C# automation solution was not tested; no VS2026
installation is required or performed for this C++ bootstrap.

From this repository in PowerShell 7.2+, rebuild and regenerate existing sources:

```powershell
$taskUeRoot = 'C:\Program Files\Epic Games\UE_5.8'
$taskProjectRoot = (Get-Location).Path
$taskProject = Join-Path $taskProjectRoot 'WarhammerClient.uproject'
if (-not (Test-Path -LiteralPath $taskProject -PathType Leaf)) { throw 'Run from the Unreal repository root' }
$taskBuild = Join-Path $taskUeRoot 'Engine\Build\BatchFiles\Build.bat'
$taskLogs = Join-Path $taskProjectRoot '.local\development'
New-Item -ItemType Directory -Force -Path $taskLogs | Out-Null
& $taskBuild WarhammerClientEditor Win64 Development "-Project=$taskProject" -WaitMutex -NoUBA "-UBARootDir=$taskLogs\uba" "-Log=$taskLogs\editor-build.log"
if ($LASTEXITCODE -ne 0) { throw "Editor build failed: $LASTEXITCODE" }
& $taskBuild -ProjectFiles "-Project=$taskProject" -Game -VSCode -2022 -Automated "-Log=$taskLogs\ide-generation.log"
if ($LASTEXITCODE -ne 0) { throw "IDE generation failed: $LASTEXITCODE" }
```

The Launcher installation has no `GenerateProjectFiles.bat`; `Build.bat -ProjectFiles`
is the verified route. UE5.8 uses its local UBA executor even with `-NoUBA`, which
disables detouring and remote execution. The command above gives local storage an
explicit project path. Unreal still uses normal per-user configuration/caches.

[BOOT01 execution evidence](docs/plans/evidence/2026-10-16-boot01.md) records passed
Windows probe/final Editor builds, UHT and both IDE generators, exact hashes and
side effects. This does not prove editor loading, rendering, gameplay or packaging.

Open generated `WarhammerClient.code-workspace` in VS Code, or open
`WarhammerClient.uproject` in Unreal when GUI work is wanted. The project requests
`VisualStudioCode` in `Config/DefaultEditorSettings.ini`; existing saved editor
settings may override it. Generated IDE files and binaries are ignored. Regenerate
them with the commands above; **do not rerun the creation script over this project**.
`scripts/New-UnrealCppProject.ps1 -CheckOnly` is a scratch-writing bootstrap probe
for an otherwise unscaffolded destination, and deliberately refuses existing project
sources/outputs.

Game/Editor targets permit Linux and configuration selects Vulkan SM6. A native
Linux UE5.8/toolchain host still needs to be arranged: Linux compilation, rendering
and packaging are **UNTESTED**. No Linux success follows from Windows generation.

## Launch using the prepared Windows development runtime

E01 prepared `.local/core-44.3.33` in this repository. From the Unreal repository
root, launch the checked-out development server with that existing environment:

```powershell
$taskCore = [IO.Path]::GetFullPath('..\Warhammer_40k_AI')
$taskCorePython = [IO.Path]::GetFullPath('.local\core-44.3.33\Scripts\python.exe')
if (-not (Test-Path -LiteralPath $taskCorePython -PathType Leaf)) { throw 'Prepare the approved isolated runtime first' }
$taskCoreRevision = git -C $taskCore rev-parse HEAD
if ($LASTEXITCODE -ne 0 -or $taskCoreRevision -ne '5f509724da25a2f6ded0c2739a8e7c84bdf59c91') { throw 'Core checkout differs from the selected revision' }
$taskCoreChanges = git -C $taskCore status --porcelain=v1 --untracked-files=all
if ($LASTEXITCODE -ne 0 -or $taskCoreChanges) { throw 'Core checkout must be readable and clean' }
& $taskCorePython -I -B -c 'from warhammer40k_core.build_identity import verified_engine_build_identity; i=verified_engine_build_identity(); assert i.build_id == "warhammer40k-core-v2:runtime-tree-sha256-v1:65fc8414407ae5d6a8ea779c8e737a22733459094db679a160c60f6e2129f96a" and i.resource_count == 3116; print(i.build_id)'
if ($LASTEXITCODE -ne 0) { throw 'Installed Core identity failed' }
& $taskCorePython -I -B -c 'import socket; s=socket.socket(socket.AF_INET, socket.SOCK_STREAM); s.settimeout(3); s.setsockopt(socket.SOL_SOCKET, socket.SO_EXCLUSIVEADDRUSE, 1); s.bind(("127.0.0.1", 8765)); s.close()'
if ($LASTEXITCODE -ne 0) { throw 'Port 8765 is unavailable; no host launched' }
& $taskCorePython -I -B (Join-Path $taskCore 'scripts\run_phase18m_reference_server.py') --host 127.0.0.1 --port 8765
if ($LASTEXITCODE -ne 0) { throw 'Core development host failed' }
```

Keep it on loopback and stop it with Ctrl+C. This starts the Python service;
the Unreal shell has no connection controls yet. The experiment wrapper's
`Preflight` and `PrepareRuntime` phases verify an existing environment in more
detail before reuse; they refuse drift. On a fresh machine, use an approved
installation recipe below rather than copying this environment directory.

On Windows the current Core host can share an occupied port with another process
([Core #589](https://github.com/SobolGaming/Warhammer_40k_AI/issues/589)). The
exclusive bind probe above rejects an already occupied port before launch; it
closes before the host binds, so it cannot prevent a race or a later second
listener. Use a dedicated local port and wait for this process's own
`Serving Phase 18M reference contract at http://127.0.0.1:8765` message. An HTTP response alone does not prove
which process answered. Robust managed-host exclusivity remains an external gap.

## Run the Python rules Core from its checkout

Use `../Warhammer_40k_AI` as read-only source. Do not reset it, run dependency sync
in its shared environment, or patch its host scripts. First verify its exact commit
and cleanliness. If it differs, obtain a separately approved exact-version checkout
or source artifact rather than changing the shared checkout.

Core supports installation as the Python package `warhammer40k-core-v2`. Its
metadata requires Python **>=3.14,<3.15**; this workspace's documented interpreter
target is **3.14.5**. It uses a Hatchling build and native dependencies including
`z3-solver==4.15.4.0`. E01 verified the selected installed build, all 3,116 runtime
resources and eight dependency imports on Windows. Relocation, Linux and packaged
delivery remain untested. Use an isolated environment outside either source
checkout. The manual recipes below require an approved execution scope; the
approved E01 route instead uses a disposable committed-source archive and Core's
lockfile, preserving both shared checkouts.

Windows PowerShell, using an already installed Python 3.14:

```powershell
$taskCore = 'C:\SWDev\warhammer\Warhammer_40k_AI'
$taskExpected = '5f509724da25a2f6ded0c2739a8e7c84bdf59c91'
$taskActual = git -C $taskCore rev-parse HEAD
if ($LASTEXITCODE -ne 0 -or $taskActual -ne $taskExpected) { throw 'Unexpected Core revision' }
$taskDirty = git -C $taskCore status --porcelain=v1 --untracked-files=all
if ($LASTEXITCODE -ne 0 -or $taskDirty) { throw 'Core source must match the reviewed clean candidate' }

$taskCoreVenv = 'C:\SWDev\warhammer\.venvs\core-44.3.33'
$taskCoreArchive = 'C:\SWDev\warhammer\.venvs\core-44.3.33-source.zip'
$taskCoreSource = 'C:\SWDev\warhammer\.venvs\core-44.3.33-source'
if (Test-Path -LiteralPath $taskCoreVenv) { throw 'Choose a fresh isolated environment or inspect the existing one first' }
if ((Test-Path -LiteralPath $taskCoreArchive) -or (Test-Path -LiteralPath $taskCoreSource)) { throw 'Choose fresh source-copy paths' }
$taskPython = 'C:\Users\Rabid\AppData\Roaming\uv\python\cpython-3.14.5-windows-x86_64-none\python.exe'
& $taskPython -I -B -m venv $taskCoreVenv
if ($LASTEXITCODE -ne 0) { throw 'Environment creation failed' }
git -C $taskCore -c core.autocrlf=false -c core.eol=lf archive --format=zip "--output=$taskCoreArchive" $taskExpected
if ($LASTEXITCODE -ne 0) { throw 'Committed source archive failed' }
Expand-Archive -LiteralPath $taskCoreArchive -DestinationPath $taskCoreSource -ErrorAction Stop
$taskCorePython = Join-Path $taskCoreVenv 'Scripts\python.exe'
& $taskCorePython -I -B -m pip install $taskCoreSource
if ($LASTEXITCODE -ne 0) { throw 'Core package installation failed' }
```

Linux equivalent, from a workspace containing the read-only Core checkout:

```bash
task_core="$PWD/Warhammer_40k_AI"
task_expected=5f509724da25a2f6ded0c2739a8e7c84bdf59c91
test "$(git -C "$task_core" rev-parse HEAD)" = "$task_expected" || exit 1
test -z "$(git -C "$task_core" status --porcelain=v1 --untracked-files=all)" || exit 1
task_core_venv="$PWD/.venvs/core-44.3.33"
task_core_archive="$PWD/.venvs/core-44.3.33-source.tar"
task_core_source="$PWD/.venvs/core-44.3.33-source"
test ! -e "$task_core_venv" || exit 1
test ! -e "$task_core_archive" && test ! -e "$task_core_source" || exit 1
python3.14 -m venv "$task_core_venv" || exit 1
git -C "$task_core" -c core.autocrlf=false -c core.eol=lf archive --format=tar --output="$task_core_archive" "$task_expected" || exit 1
mkdir "$task_core_source" || exit 1
tar -xf "$task_core_archive" -C "$task_core_source" || exit 1
task_core_python="$task_core_venv/bin/python"
"$task_core_python" -I -B -m pip install "$task_core_source" || exit 1
```

These commands build a non-editable package from a disposable committed-source
copy. Build metadata stays outside the shared Core checkout. On another Windows
host, set `$taskPython` to its installed Python 3.14 interpreter. The manual pip
and Linux recipes remain unexecuted alternatives; E01 used the reviewed locked
`uv sync` route. Preserve failed source copies rather than overwriting them.

Alternatively, install directly from the exact Git revision into the same fresh
environment **instead of** the local-source install above:

```powershell
& $taskCorePython -I -B -m pip install 'git+https://github.com/SobolGaming/Warhammer_40k_AI.git@5f509724da25a2f6ded0c2739a8e7c84bdf59c91'
if ($LASTEXITCODE -ne 0) { throw 'Pinned Core installation failed' }
```

```bash
"$task_core_python" -I -B -m pip install 'git+https://github.com/SobolGaming/Warhammer_40k_AI.git@5f509724da25a2f6ded0c2739a8e7c84bdf59c91' || exit 1
```

Git and repository access are needed for the Git recipe; use normal credential
handling, never tokens embedded in URLs. This is a development installation, not a
hash-locked portable offline runtime. After installation, record distribution
`direct_url.json`, exact dependency/native versions and Core runtime build identity.
Do not infer compatibility from package version `0.1.0` alone. The existing Arcade
environment is not a substitute: its installed Core provenance differs from both
the Arcade pin and this target.

## Start the existing development command server

The selected Core includes
`scripts/run_phase18m_reference_server.py`, an HTTP/OpenAPI conformance host. It
imports the installed `warhammer40k_core` package, so run the exact checked-out
script with the isolated interpreter above. From Windows PowerShell:

```powershell
& $taskCorePython -I -B -c 'import socket; s=socket.socket(socket.AF_INET, socket.SOCK_STREAM); s.settimeout(3); s.setsockopt(socket.SOL_SOCKET, socket.SO_EXCLUSIVEADDRUSE, 1); s.bind(("127.0.0.1", 8765)); s.close()'
if ($LASTEXITCODE -ne 0) { throw 'Port 8765 is unavailable; no host launched' }
& $taskCorePython -I -B (Join-Path $taskCore 'scripts\run_phase18m_reference_server.py') --host 127.0.0.1 --port 8765
if ($LASTEXITCODE -ne 0) { throw "Core development host failed: $LASTEXITCODE" }
```

Linux, using the variables from above:

```bash
"$task_core_python" -I -B "$task_core/scripts/run_phase18m_reference_server.py" --host 127.0.0.1 --port 8765
```

Keep the working directory outside the Core checkout. Keep this server in a
dedicated terminal and stop it with Ctrl+C when finished.
The Windows probe has the same race and late-listener limitation described above;
the Linux command remains untested on the deferred Linux host.
It also accepts `--shutdown-file <absolute-path>` for a supervised development
process; the path must be isolated and absent at startup. Its source uses the
development principal registry and does not expose credential or persistence-store
configuration flags. Keep it on loopback. It is not the remote-player/spectator
service deployment and does not establish durable game recovery or a release host.
Do not put development credentials into the Unreal client or expose this reference
host on a public interface.

The package has no registered console host command, and its wheel does not include
the repository's `scripts/` launchers. A Git-package-only installation therefore
needs this exact source script or a separately supplied supported host. The other
script, `run_local_session_dev_server.py`, is a read-only fixture server with custom
routes; it cannot accept the normative gameplay command protocol.

For an already prepared and provenance-verified Core environment, the repository's
existing runner can also start the command host with `uv run --no-sync python -I -B
scripts/run_phase18m_reference_server.py --host 127.0.0.1 --port 8765` from the Core
root. `--no-sync` avoids dependency synchronization; it does not verify the installed
runtime identity. The new migration must never silently fall back to that environment.

## Connection and local launch contract for the future client

Both modes use the same selected public `/sessions` protocol. Managed mode starts
and stops only the process the client owns; attach mode leaves service ownership
with its operator. The client needs an approved endpoint, session/admin setup,
viewer-bound credentials and exact runtime/contract identity. Session creation/start
requires administrator authority; decisions require the pending actor's player
principal; spectators receive only authorized projections/events. No viewer string
can grant access. There is no general `/health`, credential-issue or session-list
route in the normative API; do not invent those requests.

The owner selected the current checked-out development command server for initial
managed launch and attach. No new host or portable artifact is required to begin
that route. Its fixed development registry and absent durable store are explicit
limits: restarting it loses sessions, which the client must report. The spectator
role is `delayed_spectator`, with the server's one-revision delay; administrator
access is separate from player decision submission.

Later non-development remote exposure, credential provisioning, durable recovery
and checkout-independent distribution need their own supported contract and
supplier/operator. A new Python host remains separate Core work. The client-side
launcher and source-checkout convenience wrapper belong to authorized
implementation using the existing script.

See the [selected contract adaptation](docs/plans/research/2026-10-16-contract-44-3-33-adaptation.md)
and [baseline API/delivery evidence](docs/plans/research/2026-10-16-contract-integration.md)
for source references, gaps and validation limits. Actual BOOT01 and E01 commands,
results and failed attempts are recorded in their execution evidence. Graphical
interaction and packaged gameplay remain separate verification gates.
