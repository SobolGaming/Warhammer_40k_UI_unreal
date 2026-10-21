# E04-A1E Release Configure timeout closure

Status: **FOCUSED_SOURCE_PASSED_RELEASE_CONFIGURE_TIMEOUT_CLOSED**, revision 82.
The [factual receipt](../evidence/2026-10-21-e04a-release-configure-timeout-result.json)
binds source `5fb13f1812f26336e2e8a34f71be05d024161013`, comparison base
`03d28af606fc6c57d20915f746296b0d843211c6` and run
`20261021T013903Z-9972c927`. This later documentation is not executed source.

Fresh focused SOURCE returned PASS and root admitted its component/build/process
scope. Its 63 captured tool pairs had zero extraction anomalies. The observed
runtime was read-only, approval-never with disabled memory mode; lower memory,
feature and OS isolation remain UNVERIFIED. Root verified the raw and extraction
seals before reading the complete report. This is SOURCE approval only.

Preflight passed in 29.1928227 seconds with zero roots and 43 inputs prepared.
SupervisorControls passed in 45.978315 seconds with six roots, six supervisor
subcases, seven generated-input controls and 18 boundary controls. The dedicated
object/source-map control produced the expected RulesError/exit 8 refusal. All
six roots had confirmed cleanup and final job active count zero. No parser suite ran.

Configure failed after 599.6380226 seconds. CMake root 2508 exited 0 at
02:01:08.2777808 UTC, about 0.95 seconds after creation. The owned private job
remained active until timeout termination at 02:10:34.3431144 UTC. Root exit and
cleanup were confirmed; final aggregate accounting showed zero active members.
The receipt retains `timedOut=true` and its TimeoutException. The enclosing
primary failure is `E04A1_ROOT_FAILED_OR_CLEANUP_UNVERIFIED`; preservation and
failed-input retention each exceeded their deadline. No completion marker was
published. DependencyBuild, EditorBuild, Discovery, Native and Audit are NOT_RUN.

The complete CMake configure log establishes a real Release ABI compile and link
with exit 0, `/EHsc /GR-`, `/O2 /Ob2 /DNDEBUG`, C++20, dynamic Release CRT and
`/INCREMENTAL:NO`, without `-Zi` or `/debug`. The cache records the required
`CMAKE_TRY_COMPILE_CONFIGURATION=Release`. Release selection therefore worked,
but did not solve job cleanup. A VCTIP compiler helper was observed during the
phase; its direct job membership and complete descendant causality were not
observed. The established failure is the aggregate owned-job cleanup delay.

Producer source/stage/fixture after-observations and retained-artifact inventory
were absent after the preservation deadline. Separate post-close reads matched
nine settings roles (four present, five absent), 33 canonical sources, 33 staged
sources and 56 fixtures. Root rechecked all 131 comparisons and rehashed the
finite inventory of 388 run files. These later checks do not pass producer
preservation, continuous monitoring or the failed phase.

Checkpoint this closure and verify OWN18 remote backup before the prospective
repair. That repair is limited to an explicit mode for the fixed synchronous
CMake Configure/DependencyBuild routes and existing SUP01 control: after a
confirmed successful root exit and five-second natural grace, terminate remaining
members through the same retained private job, record the reason and verify actual
job zero. Timeout priority, failed roots, cleanup errors and finalization failures
remain failures. Other process routes retain natural draining. No repair is
applied in this closure; a changed candidate needs fresh bindings and focused
SOURCE before a new run. Do not retry or reuse this closed run's authority.

OWN17 remains **DEFERRED_UNPROVEN**, with existing assertions fail-closed.
43 inputs / 33 generated recipes / 50 attempts / eight suites remain planned.
Final independent CODE and different REQ, A1E acceptance, A1G, A2/727 scenarios,
full profile fidelity, HUD/input/rendering, Linux, packages and real-Core play
remain open. Actual visible windows: zero.
