# E04-A1E focused SOURCE and Configure timeout closure

Status: **FOCUSED_SOURCE_PASSED_CONFIGURE_TIMEOUT_CLOSED**, plan revision 80.
The [factual receipt](../evidence/2026-10-21-e04a-configure-timeout-result.json)
binds executed source `9972c75dcc14b75437abd7b17a886ca0ba0461d2`, comparison base
`03d28af606fc6c57d20915f746296b0d843211c6` and run
`20261021T005502Z-ef7254a5`. This later documentation is not executed source.

One fresh focused SOURCE assessment returned PASS and root admitted its qualified
component/build/process scope. Its 81 captured tool pairs had zero extraction
anomalies. Actual runtime observations were read-only, approval-never and disabled
memory mode; lower memory, feature and OS isolation remain UNVERIFIED. Two
identical turn-context observations represent one unique turn, not another launch.
This is SOURCE approval only, with no final CODE/REQ or native acceptance.

Preflight passed in 29.0109635 seconds with zero roots and all 43 inputs prepared.
SupervisorControls passed in 46.9326087 seconds with six roots, the original six
supervisor subcases, seven generated-input controls and 18 boundary controls.
The dedicated object/source-map control correctly returned exit 8, RulesError
and `E04_RULES_OBJ_SRC_MAP_FILE_UNSUPPORTED`. All six roots had confirmed cleanup
and final private-job active count zero. These are separate process/control
results; no parser suite ran.

Configure failed after 600.1306091 seconds. CMake root 44512 itself exited 0 at
01:23:05.3665301 UTC, but job members remained active. The supervisor reached its
reserved running-budget timeout and terminated its owned job at 01:32:30.4263099
UTC. Root exit and cleanup were confirmed, with final active count zero, while
`timedOut` remained true. The phase's primary failure was
`E04A1_ROOT_FAILED_OR_CLEANUP_UNVERIFIED`. Post-phase preservation and failed-input
retention each recorded `E04A1_PHASE_DEADLINE_EXCEEDED`. No completion marker was
published; DependencyBuild, EditorBuild, Discovery, Native and Audit did not run.

The actual CMake log shows a successful real ABI compile/link using its default
Debug configuration: `-Zi /FS` and linker `/debug /INCREMENTAL`, despite the main
dependency build being Release. An MSVC PDB server was observed starting during
that probe. This is consistent with the lingering member; direct per-child job
membership and complete descendant causality were not observed. It is a normal
toolchain configuration/process-bound failure, not a reason to bypass cleanup.

Producer source/stage/fixture after-observations and retained-artifact inventory
were absent after the preservation deadline. Separate root reads after closure
matched nine settings roles (four present, five absent), 33 canonical source
descriptors, 33 staged descriptors and 56 fixture descriptors. Root also retained
a finite inventory of 388 run files. These later reads do not pass the producer's
failed preservation or establish continuous monitoring or complete membership.

Checkpoint this closed attempt and verify its OWN18 remote backup before changes.
The prospective repair selects `CMAKE_TRY_COMPILE_CONFIGURATION=Release` and checks
that exact cache value, retaining the real compiler ABI compile/link and all
existing process assertions. Installed CMake documentation supports the selection;
actual cleanup still needs a fresh run. No repair is applied in this closure.
Rebind the changed candidate, obtain fresh affected focused SOURCE, then begin a
new native sequence. Preserve this failed run without retrying it.

OWN17 special assurance remains **DEFERRED_UNPROVEN** and runtime assertions stay
fail-closed. The 43 inputs / 33 generated recipes / 50 attempts / eight suites are
still planned functional counts. Final independent CODE and different REQ follow
actual completed execution and its frozen evidence. A1E is not accepted; A1G,
A2/727 scenarios, full fidelity, HUD/render/input, Linux, packages and real-Core
play remain open. No visible window was launched and all authority for this run
is closed.
