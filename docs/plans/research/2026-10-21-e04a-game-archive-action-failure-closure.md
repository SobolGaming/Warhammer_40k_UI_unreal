# E04-A1G archive-action failure closure

Revision 101 is FOCUSED_SOURCE_PASSED_GAME_DEPENDENCY_BUILD_ARCHIVE_ACTION_FAILURE_CLOSED.
The [factual receipt](../evidence/2026-10-21-e04a-game-archive-action-failure.json)
records executed source 3201552db315e5b8fbe460b9d0984bf6b81ea71a and run
20261021T101933Z-40d00c7c. The [exact SOURCE report](2026-10-21-e04a-game-source-review-3201552.md)
remains raw PASS for its prerequisite only; root admitted it before execution.

Preflight and DependencyConfigure passed. DependencyBuild failed closed with
A1G_VENDOR_STATIC_ARCHIVE_ACTION_NOT_OBSERVED after native CMake exited 0.
Verbose stdout contains 30 fresh compile actions and a direct pinned MSVC
lib.exe archive action at step 31/32, with 30 object inputs and
/machine:x64 /out:yaml-cpp.lib. The wrapper expected cmake -E vs_link_lib.
The built archive was observed at 5706552 bytes, SHA256
F16EEC285C2609219993E56AEBE8CA215DBFFF757A42E333741071FE0DFEC031,
with the archive magic !<arch> followed by LF. This identifies an archive-action
recognition gap in the proof wrapper. The phase remains failed; no Core engine
fault is established, and no successful copied Game artifact is claimed.

Native CMake root PID 43504 exited 0 with confirmed exit/cleanup in 13.8238672
seconds, without timeout. Its declared five-second post-root grace ended with
owned-job cleanup; the final query reported 38 total and zero active processes.
Outer PowerShell PID 31944 closed exit 1. The failed result and partial generated
inputs remain retained. No DependencyBuild completion, vendor-build/artifact
receipt or owned artifact copy was created. EditorPrerequisiteBuild, GameBuild,
Cook, Stage, Native and Audit are NOT_RUN. Two Game attempts and 52 custom checks
remain planned; executed attempts/checks are zero.

Root recorded finite preservation matches for 36 canonical files, 36 staged
files, two fixtures, nine settings roles and the separate Game settings role,
and rehashed 45 selected actual artifact descriptors. These observations are
bounded; they do not prove continuous preservation or certify all partials.
Before first SOURCE report/tool-value body inspection, root rehashed 12 raw,
eight selected and 772 frozen/control identities. All 40 retained command inputs
were inspected. Actual read-only/never settings and disabled memory metadata
are retained, while internal enforcement and universal source consumption or
comprehension remain UNVERIFIED. The source review does not supply native or
final acceptance and its raw PASS remains unchanged.

The run is closed with no retry or successor authority. No source repair is
adopted here. Checkpoint this failure/report overlay, push and gh-verify OWN18
exact remote backup before a narrow source repair. After repair, checkpoint and
verify its backup, derive fresh bindings and obtain fresh affected SOURCE before
a new ordered phase chain. Final CODE and different REQ follow actual successful
closed execution.

Bounded A1E acceptance, earlier raw failures, OWN17 deferred/unproven, zero visible
authority, Linux UNTESTED and perpetual private source/API review consent remain
unchanged. This metadata/report overlay lies outside the source head assessed
and executed; it grants no launch, retry or milestone acceptance.
