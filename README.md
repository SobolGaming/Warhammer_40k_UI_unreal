# Warhammer 40k Unreal client

This repository develops a C++ first, genuinely 3D Unreal client for the separate
authoritative Python rules engine. `WarhammerClient.uproject` is the minimal C++
foundation. Source includes an opt-in synthetic 3D proof scene. Current E02 status
is **EXECUTION_PASS_FINAL_ACCEPTANCE_BLOCKED_ADMIN**: 16 native cases / 18174
assertions and six rendered images passed their producer checks, while the sealed
final reviews retain BLOCKED verdicts with an approval-provenance finding pending.
Both visible launches are consumed and native authority is closed. Earlier
failed/blocked runs remain preserved.
A playable Core-connected client
and complete rendered/input acceptance remain future work. The plan records
actual evidence and remaining gates.

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
UE HTTP, rendering, packaging and Linux remain open.

Plan revision 40 (2026-10-20 UTC) records the completed E02 run
`20261019T202805Z-5ff8cb61` on executed source
`5e92ba336da0570cb4b57def390ad3c58921e625`. Affected SOURCE and all seven
producer phases passed; six separate supervisor cases are additional evidence.
Final [CODE r3](docs/plans/research/2026-10-20-e02-final-code-r3.md),
[REQ r2](docs/plans/research/2026-10-20-e02-final-requirements-r2.md) and the
postsealed [limited supplement v4](docs/plans/research/2026-10-20-e02-final-requirements-supplement-v4.md)
are all sealed raw **BLOCKED** for final candidate
`3a1d17902f6fa94b6009c0cae573da8bf7dff063`. Root separately verified CODE's
opaque affected-SOURCE prerequisite. The supplement resolves reading-count,
hash-gate and administrative source-binding concerns; no fundamental contamination
requiring a fresh initial assessment was established. The raw reports remain unchanged.

Root now clarifies historical checkpoint `1c99360` as **UNREVIEWED_FOR_ACCEPTANCE**:
no separate independent approval is established. Its original message omission and
OWN16 noncompliance remain unchanged; RQ25/E09 remain open/unexecuted. Independent
original prelaunch approval retrieval/timing verification remains pending owner factual clarification.
[Final-review provenance](docs/plans/evidence/2026-10-20-e02-final-review-provenance.json)
binds these limits. Native execution is closed with zero launches remaining; final
acceptance, push and merge are not released. Full E02/M02, RQ23/RQ24, Linux,
packaging, real-Core play and full HUD/profile behavior remain open. The E02
round-trip checks concern the same effective viewport pixel; they do not establish
arbitrary fractional-point pointing precision.

Separately, an isolated E04-A1 source draft covers 18 paths, eight proposed native
cases and 38 input IDs. Acquisition and byte verification of yaml-cpp pin
`56e3bb550c91fd7005566f19c079cb7a503223cf` completed (394 files / 5156535 bytes).
Canonical promotion, library configure/build, native execution and acceptance have
not occurred; full E04 remains open.

The following 3483f79 source-review disposition is historical.

Historical reviewed E02 checkpoint `3483f79031d8a7840a574b1f78974970cfe4e6e5` received **SOURCE BLOCKED** before source/requirements body reads: the matching root launch GO existed on disk but was omitted from the actual initial prompt. Source merits are **UNASSESSED**; this is an authority/protocol failure with no C++ finding. Planned run `20261019T201705Z-77706340` and all associated authority are **CLOSED_DO_NOT_REUSE**.

The full-matrix invertibility/finite-inverse guard remains authored and **UNEXECUTED**. No E02 RunRoot, Preflight, supervisor controls, build, native/GUI or Audit ran for this checkpoint; zero visible windows were consumed. Historical c9a5ac5 SOURCE CHANGES_REQUESTED and c987 WorldInput FAIL remain unchanged. Fresh affected SOURCE review with explicit actual launch authority, a new run, hidden checks and applicable visible approval remain gates. See [current facts](docs/plans/evidence/2026-10-19-e02-3483-source-result.json), the [prior c9 result](docs/plans/evidence/2026-10-19-e02-c9a5-source-result.json) and the [journal](docs/plans/evidence/2026-10-16-e02-world-input.md).

The following c987 runtime disposition is historical.

Historical E02 source `c9878630c586fc2641c08da8171ce1b969150fd1` received affected SOURCE PASS. Run `20261019T130651Z-04449a62` passed Preflight, all six supervisor cases in three groups/five roots, Win64 Editor Build, Discovery (2211 eligible engine names/exact 16 E02 names) and Numeric (four cases/17041 assertions). Discovery PID 33448 exited 0 in 250.774827s with confirmed cleanup/final job active 0/total 37; Numeric PID 20804 exited 0 in 15.5452976s with confirmed cleanup/final job active 0/total 11.

WorldInput **FAILED** before final report publication. The native log contains 11 completed Success cases / 1106 assertions: all eight Input cases / 975 assertions and three Rendered cases / 131 assertions. Input.RepeatedConfirm completed 148 assertions, exercising the status-persistence regression; these are partial log observations, not a twelve-case phase PASS. Rendered.RaisedPicking step 2 logged the exact failing combined assertion `Domain <=1e-4in and projected <=1physicalpixel` three times at 19:30:46.921/.962/.963Z. The log does not publish individual DomainError/PixelError values or identify which conjunct failed. Five other named PNGs exist; `raised-pick.png`, complete `reports/world-input/index.json` and phase completion do not. The wrapper's missing-index exception is consequential. No Audit or final CODE/REQ review ran.

WorldInput native PID 37836 exited 0 in 70.4981013s with confirmed assigned-job cleanup and final job active 0/total 13. Its nine recorded settings pairs match before/after and Preflight.after (four present/five absent). Discovery/Numeric likewise have nine matching pairs; SupervisorControls has no same-phase pair. Known Documents evidence remains limited to the logical route; resolved provider/target identity and the absent-leaf present-file branch remain UNVERIFIED. Job aggregates do not prove universal descendant identity, second-hop behavior or network isolation.

The exact-pair approval came from a trusted source-progress-chat relay: the owner's exact **Yes!** at `2026-10-19T19:18:09Z` to question `call_2a9e639c445040319e6a71082cb02a25`. The original message was not independently retrieved. Both approved visible launches have now been consumed; the run and all hidden/visible execution authority are **CLOSED_DO_NOT_REUSE**. No retry, RunId reuse or approval transfer remains.

A bounded ray/projection/quantization diagnosis and repair must preserve the existing scene/domain values, actual projection/input route, nearest-hit/NoHit semantics, geometry and pixel tolerances, cases, screenshots, zero Core counters, ownership/cleanup, timing budgets and startup controls. No repaired candidate has executed. Require a coherent checkpoint, fresh source/tool/API/fixture freeze, affected SOURCE review, new RunId, preservation/SUP/build checks and new applicable visible approval before native repaired graphical work. Fresh final independent CODE and different REQ assessments still follow a completed final execution/documentation/evidence freeze. Acceptance, publication/merge, full E02/M02, production Core-connected play, packaging and Linux remain open. Preserve every earlier failure/unknown.

See [historical c987 facts](docs/plans/evidence/2026-10-19-e02-c987-result.json) and the [journal](docs/plans/evidence/2026-10-16-e02-world-input.md).

The following 0ed4d7c disposition is historical.

Historical E02 source `0ed4d7c5b95148724af362c02380167b33cc0660` received affected
**SOURCE PASS**. Run `20261019T052432Z-c29cc04d` passed Preflight, all six supervisor
subcases, Win64 Editor Build, Discovery (2211 engine names/exact 16 E02) and four
Numeric cases/17041 assertions on 2026-10-19 UTC.

WorldInput **FAILED** before final reporting. Six completed Input log successes/491
assertions are partial diagnostics; PanDollyFrame's 350 assertions exercised the
paint-coordinate repair. Trace/source show a precise no-session refusal replaced
by generic Ready text on pointer movement during RepeatedConfirm. The original
log does not identify the exact failed Check; the missing report is consequential.
PID 10544 exited 0 in 25.4225494s with confirmed assigned-job cleanup/final job
active 0/total 9. All nine settings pairs match (four present/five absent).
No complete twelve-case result, six PNGs or Audit exists. Both visible launches
were consumed; all execution authority is **CLOSED_DO_NOT_REUSE**.

The [E02 journal](docs/plans/evidence/2026-10-16-e02-world-input.md) and
[closure](.local/reviews/E02-source-review/root-0ed4d7c-20261019T052432Z-c29cc04d/worldinput-failure-and-authority-closure.json)
bind the original failure. Bounded diagnostic-status persistence, immediate failure
logging, focused regression assertions and docs are released; the repair is
**UNEXECUTED** pending checkpoint/fresh freeze/affected SOURCE/new RunId/build and
new applicable visible approval. Existing assertions, cases, screenshots, ownership,
zero Core counters, budgets and startup controls stay fixed. Final independent
CODE/different REQ, acceptance, Linux and packaging remain pending.

The following 5abe18c disposition is historical, before the paint-coordinate repair.

Historical E02 source `5abe18cbd020ea97676ad87283735e17822fc462` received affected
**SOURCE PASS**. Run `20261018T173740Z-647fb0c4` actually executed on 2026-10-19 UTC
after the owner's direct resumption/conditional approval. Preflight, six supervisor
subcases (three groups/five roots), Win64 Editor Build, Discovery and four Numeric
cases/17041 assertions passed. Discovery reconciled 2211 engine names/exact 16 E02.

WorldInput **FAILED** on `FramePaintStale` during `Input.PanDollyFrame`, before
report finalization. Missing `reports/world-input/index.json` is the consequential
wrapper error. Five preceding Input log successes/141 assertions are partial
diagnostics; twelve-case acceptance, six PNGs and Audit do not exist. PID 16900
exited 0 in 25.4134518 seconds with confirmed cleanup/final job active 0/total 9; all nine settings
pairs match (four present/five absent). Both visible launches were consumed and
all run/execution authorities are **CLOSED_DO_NOT_REUSE**.

The [E02 journal](docs/plans/evidence/2026-10-16-e02-world-input.md) and
[closure](.local/reviews/E02-source-review/root-5abe18c-20261018T173740Z-647fb0c4/worldinput-failure-and-authority-closure.json)
bind actual outcomes. Only bounded window-to-desktop paint-coordinate remediation
plus focused controls/docs is released; the strict stale-layout guard and native
assertions remain. The repair is **UNEXECUTED** and needs checkpoint/fresh freeze,
affected SOURCE review, a new RunId/build and new applicable visible approval.
Final independent CODE/different REQ, acceptance, Linux and packaging remain pending.

The following fff05fc disposition is historical, before the later BOM-reader repair.

Historical E02 candidate `fff05fc2b7e663bd345ddae22c68058f849f7029` received affected
**SOURCE PASS**. Run `20261018T160124Z-dcf2685f` passed Preflight, six supervisor
subcases in three groups/five roots, Win64 Editor Build and visible Discovery.
Discovery reconciled 2211 engine names and the exact 16 E02 set on D3D12/
RTX 4090 driver 610.88. PID11088 exited0 in 255.7679178 seconds, with confirmed
exit/cleanup and final job active0/total40.

Numeric **FAILED** because the JSON reader rejected the report's leading UTF-8
BOM. PID32692 exited0 in 20.3899516 seconds, with confirmed exit/cleanup and
final job active0/total11. The raw report separately exports four Success cases/
17041 assertions after strict BOM-aware diagnostic decoding; Numeric remains FAIL.
All nine settings pairs match Preflight.after (four present/five absent). No
Numeric completion exists; WorldInput/Audit are **NOT RUN** and six PNG captures
were **NOT REQUESTED**.

All execution authorities and this run are **CLOSED_DO_NOT_REUSE**. The exact-run
[owner relay](.local/reviews/E02-source-review/root-fff05fc-20261018T160124Z-dcf2685f/relayed-visible-window-owner-approval.json)
covered two sequential visible windows; one was used and the remaining window
is closed/nontransferable. Only strict single-leading-BOM reader repair, focused
offline controls and docs are released. The repair candidate is **UNEXECUTED**:
checkpoint/freeze, fresh affected SOURCE review and a new RunId precede execution.
The [E02 journal](docs/plans/evidence/2026-10-16-e02-world-input.md) and
[closed-run record](.local/reviews/E02-source-review/root-fff05fc-20261018T160124Z-dcf2685f/numeric-failure-and-authority-closure.json)
preserve the evidence. Default Trace Server/control1985 and CrashReportClient
startup were observed; no attributed activation diagnostic for the six forbidden
messaging plugins was found. Secondary
startup behavior/network egress remain UNVERIFIED; no actual job escape is
established and no startup flag change is authorized here. Standing SOURCE consent,
final independent CODE/different REQ, acceptance and merge remain separate.
Linux/packaging and visual acceptance remain pending.

Historical E02 candidate `e8f1837e7083f6db03ae7a3909eae76769e1692b` received affected
**SOURCE PASS** (4589-byte raw report, SHA256
`E720D499E2ECC4E0C95E21A5AF1133DBFDFAC77CB6215000C705DBE0E1F5CF66`).
Run `20261018T061145Z-1afc8afb` passed Preflight, six supervisor subcases in
three groups/five roots, and the Win64 Development Editor Build. Build phase
duration was 97.9442252 seconds; native PID 2576 exited 0 with cleanup confirmed.

The first visible Discovery ran under [direct owner approval](.local/reviews/E02-source-review/root-e8f1837-20261018T061145Z-1afc8afb/direct-visible-window-owner-approval.json)
and **FAILED** with `E02_DISCOVERY_COMPLETE_LIST_MISSING`. Native PID 27432 exited 0
in 221.4102112 seconds within its 600-second budget, with confirmed exit/cleanup
and final job active0/total25. The engine listed 2211 unique names, while the
parser accepted 2210: an interior apostrophe in log line 2246 was excluded.
All 16 E02 names were present; Discovery remains FAIL. Nine settings states match
before/after and Preflight.after. No Discovery completion/required manifest exists;
scene JSON exists but its validation was not reached. Numeric, WorldInput and Audit
remain NOT RUN; this phase requested none of the six required screenshot captures.

The run and all hidden/visible execution authorities are **CLOSED_DO_NOT_REUSE**.
The bounded quoted-name regex repair is **UNEXECUTED**, with C++/fixture/input,
criteria and budgets unchanged. Require checkpoint/freeze, fresh affected SOURCE
review and a new RunId before repaired execution; the visible approval covers only
the closed e8f1837/061145 scope. The [E02 journal](docs/plans/evidence/2026-10-16-e02-world-input.md)
preserves actual results and failure. SOURCE PASS is not final acceptance: fresh
independent CODE and different REQ reviews remain required. Linux/packaging remain pending.

Historical E02 candidate `ba05821a8255fca334ddd1fe04a1b4e23bf6af16` received affected
**SOURCE PASS** (5656-byte raw report, SHA256
`4D50A3E104653965431EF940AB7314D828FCC08DBECFBA0504DB34EF8F5CC19A`).
Run `20261018T005629Z-05cac877` completed Preflight (PASS) and all six supervisor
subcases in three groups/five roots (PASS). Build **FAILED** with four cascading
diagnostics from incomplete `FProcMeshTangent` in `E02GeometryTests.cpp:222`.
PID28452 exited6 in 51.4887138 seconds, with confirmed cleanup and final job
active0/total35. Nine Build settings states match before/after and Preflight.after;
SupervisorControls has no separate settings pair.

The run and hidden authority are **CLOSED_DO_NOT_REUSE**. The single defining-header
include repair is **UNEXECUTED** and requires checkpoint/freeze, fresh affected
SOURCE review and a new RunId before execution. No Build completion exists;
Discovery, numeric/rendered/input Automation and GUI remain NOT RUN.
The [E02 journal](docs/plans/evidence/2026-10-16-e02-world-input.md) preserves
the static PASS, failed compiler output and closure. Visible-window approval,
final CODE/REQ, packaging and Linux remain pending.

Historical E02 candidate `4ee4a3a54c3877d46f1fe2cdc82d282b1fc484b4` received affected
**SOURCE PASS**. Run `20261018T002310Z-d6305fba` completed Preflight and all six
supervisor controls in three groups/five roots, including child-start and
expected timeout/injected failures. Each root confirms cleanup/final job active0.
The first C++ build reached UBT/UHT and native compilation, then **FAILED** on
UE API/type integration errors. Its root exited6 with cleanup confirmed and
final job active0/total35. Nine Build settings states match before/after and
Preflight.after; SupervisorControls has no separate snapshot pair.

The run and hidden authority are **CLOSED_DO_NOT_REUSE**. Bounded compile fixes
require checkpoint/freeze, fresh affected review and a new RunId before execution.
Discovery, numeric/rendered/input Automation and GUI remain NOT RUN. The
[E02 journal](docs/plans/evidence/2026-10-16-e02-world-input.md) preserves the
source PASS, actual completed controls, failed compiler output and closure.
Visible-window approval, final CODE/REQ, packaging and Linux remain pending.

Historical E02 candidate `8e048fc369536a76891031aa4883c888bf762aa8` received affected
**SOURCE PASS**. Run `20261017T233109Z-85e7c8a2` completed Preflight with matching
nine-before/nine-after normal-desktop settings snapshots, then SupervisorControls
**FAILED** with `E02_CHILD_CONTROL_FIXTURE_IDENTITY_INVALID` in 11.7401221 seconds.
Its one native supervisor root, PID 33344, exited 0/PASS with cleanup confirmed
and final job active 0/total 4. That is no accepted SUP01 control result: the
validator required null where the native no-fault field was an empty string.
Matching child ACK/ALIVE stdout records remain preserved. No controls index or
phase completion exists; SUP02/SUP03, Build, Unreal Automation and GUI did not run.

The run and hidden authority are **CLOSED_DO_NOT_REUSE**. Root's strict typed
empty-string repair and related inspector work remain **UNEXECUTED**; checkpoint,
fresh freeze/affected SOURCE review and a new RunId are required. The
[E02 journal](docs/plans/evidence/2026-10-16-e02-world-input.md) binds the unchanged
static review, failed run and closure. Visible-window approval, final CODE/REQ
and Linux proof remain pending; all earlier records retain their actual results.

Historical E02 candidate `58bad7984ef336dfbb486d75bcd51fd241b3b529` received
**SOURCE CHANGES_REQUESTED** for two supervisor-control gaps: a real launch error
could satisfy an injected-failure check, and a root-only timeout could pass without
proof that its intended child started. Planned RunId `20261017T210320Z-3fa544f1`
is **UNUSED_DO_NOT_EXECUTE**; no E02 phase ran on that candidate. Bounded remediation
requires exact seam diagnostics/states and a child readiness/identity/alive proof
using the original Process handle. The existing cmd grouping correction stays in
place. Repairs remain **UNEXECUTED** pending checkpoint/freeze, fresh affected
SOURCE review and a new RunId. The [E02 journal](docs/plans/evidence/2026-10-16-e02-world-input.md)
binds the raw review and closure. Visible-window approval and final independent
CODE/REQ acceptance are separate gates.

Historical E02 candidate `2efd348b20bbf4adcd014dba9d50e178cad5c71c` received affected
**SOURCE PASS**. Root combined it with the historical 338 assessment only for
demonstrated unchanged scope; this is no new whole-C++/plugin verdict. Run
`20261017T202655Z-2b75d9a6` completed Preflight with matching nine-before/nine-after
normal-desktop settings snapshots. SupervisorControls completed three groups,
six subcases and five roots in 9.2460989 seconds, with 20 bound artifacts and
confirmed cleanup/final zero-active jobs. Build then **FAILED** on a missing
native-toolchain receipt. Worker PID 4472 exited 0 and cleaned up, but no SDK-selection
receipt, build.log, staged Binaries/Intermediate or Build completion exists;
no UBT/C++/UHT/native/GUI proof ran. All nine Build settings pairs also match
Preflight.after. The run and hidden authority are closed; do not resume/reuse them.

The subsequent bounded cmd FOR/IF grouping correction to the Build launcher
remains **UNEXECUTED**. The [E02 journal](docs/plans/evidence/2026-10-16-e02-world-input.md)
preserves the actual primary error, receipts, source gates and historical failures.

Historical E02 candidate `338735e737c6892736b03c884b475c66ae0f69f8` received a sealed
pre-execution **SOURCE PASS**. Run `20261017T181128Z-06d66926` then failed
Preflight with `E02_REPARSE_PATH` / `FAIL_BEFORE_PHASE_CREATION` before RunRoot
allocation: the normal Known Documents route has OneDrive reparse ancestors.
No phase result/completion or supervised child exists; Build/native/GUI remain
**NOT RUN**. Its hidden authority is **CLOSED** and the attempted RunId must
not be reused. The [E02 journal](docs/plans/evidence/2026-10-16-e02-world-input.md)
binds the unchanged source report, operator seal/audit, root gate and closure.

The bounded repair permits only the two exact Known Documents settings paths
as absolute read-only logical observations through unclassified reparse
ancestors. Leaves remain plain non-reparse files, all nine snapshots remain
required, and owned/source/tool/engine plus Local/Profile/Roaming guards remain
strict. Resolved target identity stays UNVERIFIED. The 202655 snapshots exercised
both absent-file routes; present-file hashing remains unexecuted/UNVERIFIED.
The owner separately authorized current
and subsequent E02 review-packet transmission to the same OpenAI service, within
the journal's recorded data exclusions and relayed-consent limits. This adds
neither visible-window nor merge authority; final CODE/REQ gates remain separate.

The earlier E02 SOURCE assessment of `73f73b5` is **CHANGES_REQUESTED** for procedural face winding/the
numeric oracle and unbound modifier shortcuts. At that disposition source-only
repairs required a new frozen review before execution. Planned RunId `20261017T174203Z-7dbe90d1`
is unused and has no execution authority. The [E02 journal](docs/plans/evidence/2026-10-16-e02-world-input.md)
also records the earlier pre-execution SOURCE PASS for `c10c021` and attempted run
`20261017T171627Z-6e96cd42`. Preflight completed; three supervisor groups recorded
six successful control subcases and confirmed cleanup of all five process roots
in 9.5589701 seconds. Artifact publication then failed on a dictionary `Contains`
overload, so SupervisorControls has no result/completion record and the run stops.
Build, native cases and visible game windows remain **NOT RUN**.

The old Preflight used redirected LocalAppData and omitted the real desktop
EditorSettings file and a persisted before-settings baseline; preservation of
those real settings remains **UNVERIFIED**. The later candidate repairs descriptor
traversal and requires a normal desktop context with a persisted baseline. It
received the 338 source assessment above; the failed Preflight supplies no
runtime proof of those repairs or the winding/chord corrections. The [E02 packet](docs/plans/research/2026-10-16-e02-world-input-packet.md)
clarifies outward-face and exact bare-key checks within its existing scope,
cases and budgets. Visible-window approval and final
separate CODE/REQ acceptance remain later gates.

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
