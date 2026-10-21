# Plans

The [Unreal migration plan](unreal-migration-plan.md), revision 112 (2026-10-21 UTC), is canonical.
Section 0 holds research status, owner decisions and the next bounded gate. It
preserves the client-only scope, genuine 3D/parity requirements and separate
execution and acceptance criteria. Supporting findings live under [research](research/).

**COOK_PLATFORM_FREEZE_METADATA_REPAIRED_FRESH_BINDINGS_SOURCE_PENDING** (revision 112). Root adopted only two ignored metadata builders after failure checkpoint e43ec1d and verified OWN18 backup. The freeze builder adds strict size/hash-pinned Platform.cs and WinPlatform.Automation.cs primary files to runtime .files membership; technical v7 adds Platform.cs lines 733-741 and WinPlatform.Automation.cs lines 1-1079, with overlap removed by the existing builder. Product C++, wrapper, norm, Rules, targets, project, Config, fixtures and supervisor are unchanged, as are the failed run and its freeze. [Repair](research/2026-10-21-e04a-game-cook-platform-binding-repair.md), [receipt](evidence/2026-10-21-e04a-game-cook-platform-binding-repair.json). At adoption on 2026-10-21T13:16:50.9979568Z, root inspected the full functional diff, matched both whole inverses and observed zero metadata AST errors. Actual new bindings were NOT_CREATED, new RunId UNBOUND, fresh SOURCE and all nine new phases NOT_RUN; adoption executed no native or review work. Checkpoint/push/gh-verify repaired metadata before fresh exact head/base/run/freeze/source/config/command bindings and affected SOURCE, then separate ordered native GOs after positive root admission. Preserve the closed 073826d SOURCE/five predecessor PASS admissions, actual successful Game compilation/monolithic link and pre-native Cook binding failure. No old SOURCE or phase authority transfers; no wrapper waiver or repair-phase PASS is inferred. Bounded A1E acceptance, historical failures, OWN17 deferred/unproven, visible zero, Linux UNTESTED and perpetual review consent are unchanged.

Historical revision 111: **CLOSED_COOK_PLATFORM_FREEZE_BINDING_FAILED_REPAIR_REQUIRED** (revision 111). Fresh SOURCE for 073826d / run 20261021T123959Z-657332ad is PASS and root-admitted; Preflight, DependencyConfigure, DependencyBuild, EditorPrerequisiteBuild and GameBuild passed and were admitted. The actual Game build logged 23 actions and Succeeded, including the repaired GameProbe compilation and monolithic link; caller exception-disabled/parser EHsc and Shared/monolithic evidence is retained. Cook failed closed before any native root on A1G_WIN64_LOOSE_PLATFORM_PRIMARY_NOT_UNIQUELY_FROZEN. Outer PowerShell PID 9064 closed exit 1 without timeout/kill, with streams drained; no Cook completion or cook/stage payload exists. Stage, Native and Audit are NOT_RUN, zero actual Game attempts/checks; two inputs/two attempts/52 checks remain planned. There is no cooked Game runtime or empirical window proof. The run is closed with no retry or successor GO; no repair is adopted. [Closure](research/2026-10-21-e04a-game-cook-platform-binding-failure-closure.md), [SOURCE](research/2026-10-21-e04a-game-source-prerequisite-073826d.md), [raw SOURCE](research/2026-10-21-e04a-game-source-review-073826d.md), [receipt](evidence/2026-10-21-e04a-game-cook-platform-binding-failure.json). Root finite preservation matched 84 states, 52 retained artifacts and ten predecessor descriptors. Checkpoint/push/gh-verify OWN18 failure backup before a minimal freeze-binding repair; then checkpoint/verify repaired bindings backup, derive fresh exact source/run/freeze inputs and obtain fresh affected SOURCE before a new ordered nine-phase chain. No old SOURCE or phase authority transfers. Bounded A1E acceptance, historical failures, OWN17 deferred/unproven, visible zero, Linux UNTESTED and perpetual review consent are unchanged.

Historical revision 110: **GAME_PROBE_PUBLICATION_BRACES_SOURCE_REPAIRED_FRESH_SOURCE_PENDING** (revision 110). Root adopted only four brace lines around the two bPublished UE_LOG branches after failure checkpoint 47de396 and verified OWN18 backup. Log arguments, publication/result/exit order and all 52 planned checks remain; other GameProbe logging branches were already braced, and the deprecation warning is untouched. Norm, wrapper, Rules, targets, project fixtures, parser, Config and supervisor are unchanged. [Repair](research/2026-10-21-e04a-game-probe-publication-braces-source-repair.md), [receipt](evidence/2026-10-21-e04a-game-probe-publication-braces-source-repair.json). At adoption on 2026-10-21T12:36:37.5583085Z, root inspected the full functional diff, matched whole source inverse and one CR byte before/after. C++ compilation, behavior, fresh SOURCE and all nine repaired-candidate phases were NOT_RUN then, new RunId UNBOUND and no new admission. Checkpoint/push/gh-verify repaired-source backup before fresh exact bindings and affected SOURCE; separate ordered native GOs follow positive admission. Preserve the old 03fb024 SOURCE/four-phase PASS admissions and actual C2181 GameBuild failure, including warnings; no old approval transfers. Bounded A1E acceptance, historical failures, OWN17 deferred/unproven, visible zero, Linux UNTESTED and perpetual review consent are unchanged.

Historical revision 109: **CLOSED_GAME_PROBE_COMPILATION_FAILED_REPAIR_REQUIRED** (revision 109). Fresh SOURCE for 03fb024 / run 20261021T121210Z-65f77563 is PASS and root-admitted; Preflight, DependencyConfigure, DependencyBuild and EditorPrerequisiteBuild passed and were admitted. GameBuild failed closed after actual UBT exit 6: E04ProfileGameProbeModule.cpp line 342 reports C2181 illegal else without matching if. Parser/GameProbe compilation was attempted, beyond the prior Shared plugin-selection rejection; no successful Game build, final link or runtime proof was established. C4996 PLATFORM_64BITS and historical C4701 Origin warnings remain retained. Exit/cleanup are confirmed (39.8747415 seconds; final 35/0), and outer PowerShell closed exit 1 without timeout/kill. No GameBuild completion exists. Four downstream phases are NOT_RUN, zero Game attempts/checks; two inputs/two attempts/52 checks remain planned. The run is closed with no retry or successor GO; no repair is adopted. [Closure](research/2026-10-21-e04a-game-probe-compilation-failure-closure.md), [SOURCE](research/2026-10-21-e04a-game-source-prerequisite-03fb024.md), [raw SOURCE](research/2026-10-21-e04a-game-source-review-03fb024.md), [receipt](evidence/2026-10-21-e04a-game-probe-compilation-failure.json). Root finite preservation matched 84 states, 52 retained artifacts and eight predecessor descriptors. Checkpoint/push/gh-verify OWN18 failure backup before narrow repair, then repaired-source backup, fresh bindings and affected SOURCE. No approval transfers to changed source. Bounded A1E acceptance, historical failures, OWN17 deferred/unproven, visible zero, Linux UNTESTED and perpetual review consent are unchanged.

Historical revision 108: **GAME_SCOPED_PROJECT_PLUGIN_SOURCE_REPAIRED_FRESH_SOURCE_PENDING** (revision 108). Root adopted the dedicated target, wrapper, norm and new owned project fixture after failure checkpoint 3d6d5ff and verified OWN18 backup. Shared target Rules.EnablePlugins is removed; the frozen owned project must select exactly Win64/Development/Game, with strict typed reference checks and positive Game BuildPlugins proof. Editor/Cook disabled requirements and actual compile/link/runtime proof remain; no Unique/Override route. Canonical product descriptor, Rules, plugin descriptor, caller/parser C++, Config and supervisor are unchanged. [Repair](research/2026-10-21-e04a-game-scoped-project-source-repair.md), [receipt](evidence/2026-10-21-e04a-game-scoped-project-source-repair.json). At adoption on 2026-10-21T12:09:20.5429418Z, root inspected the full functional diff, matched whole wrapper inverse and 169 CR bytes before/after, with zero AST errors, 112-to-113 functions and parsed fixture JSON. Behavior, fresh SOURCE and all nine repaired-candidate phases were NOT_RUN then, new RunId UNBOUND and no new admission. Checkpoint/push/gh-verify repaired-source backup before fresh exact bindings and affected SOURCE, explicitly binding the owned project fixture; separate ordered native GOs follow positive admission. Preserve the old 10f1d38 SOURCE/four-phase PASS admissions and actual GameBuild failure; no old approval transfers. Bounded A1E acceptance, historical failures, OWN17 deferred/unproven, visible zero, Linux UNTESTED and perpetual review consent are unchanged.

Historical revision 107: **CLOSED_GAME_SHARED_PLUGIN_SELECTION_FAILED_REPAIR_REQUIRED** (revision 107). Fresh SOURCE for 10f1d38 / run 20261021T114118Z-96c095f7 is PASS and root-admitted; Preflight, DependencyConfigure, DependencyBuild and EditorPrerequisiteBuild passed and were admitted. GameBuild failed closed after actual UBT exit 6: explicit target EnablePlugins=E04ProfileProof is unsupported with Shared build environment. UBT rejected target setup before Game C++ compilation; the retained partial target receipt is not a successful Game build. Exit/cleanup are confirmed (1.3311879 seconds; final 2/0), and outer PowerShell closed exit 1 without timeout/kill. No GameBuild completion exists. Four downstream phases are NOT_RUN, zero Game attempts/checks; two inputs/two attempts/52 checks remain planned. The run is closed with no retry or successor GO; no repair is adopted. [Closure](research/2026-10-21-e04a-game-shared-plugin-failure-closure.md), [SOURCE](research/2026-10-21-e04a-game-source-prerequisite-10f1d38.md), [raw SOURCE](research/2026-10-21-e04a-game-source-review-10f1d38.md), [receipt](evidence/2026-10-21-e04a-game-shared-plugin-failure.json). Root finite preservation matched 84 states, 51 retained artifacts and eight predecessor descriptors. Checkpoint/push/gh-verify OWN18 failure backup before narrow repair, then repaired-source backup, fresh bindings and affected SOURCE. No approval transfers to changed source. Bounded A1E acceptance, historical failures, OWN17 deferred/unproven, visible zero, Linux UNTESTED and perpetual review consent are unchanged.

Historical revision 106: **GAME_EDITOR_ACTION_SUFFIX_SOURCE_REPAIRED_FRESH_SOURCE_PENDING** (revision 106). Root adopted only Require-A1GBuildAction comments and the exact optional native [NoUba] suffix after failure checkpoint 668c8aaba and verified OWN18 backup. Numbered/action/leaf/x64/end anchors and exactly-one matching remain; other suffix forms refuse. Norm and Rules are unchanged. [Repair](research/2026-10-21-e04a-game-editor-action-source-repair.md), [receipt](evidence/2026-10-21-e04a-game-editor-action-source-repair.json). At adoption on 2026-10-21T11:38:38.9739915Z, root inspected the full functional diff, matched the whole wrapper inverse and 169 CR bytes before/after, with zero AST errors and 112 functions. Behavior, fresh SOURCE and all nine repaired-candidate phases were NOT_RUN then, new RunId UNBOUND and no new admission. Checkpoint/push/gh-verify repaired-source backup before fresh bindings and affected SOURCE, then separate ordered native GOs after positive admission. Preserve the old 71ce131 SOURCE/three-phase PASS admissions and closed Editor evidence failure; no old approval transfers. Optional regex controls or harness certification are not a new prerequisite. Bounded A1E acceptance, historical failures, OWN17 deferred/unproven, visible zero, Linux UNTESTED and perpetual review consent are unchanged.

Historical revision 105: **CLOSED_GAME_EDITOR_ACTION_EVIDENCE_FAILED_REPAIR_REQUIRED** (revision 105). Fresh SOURCE for 71ce131 / run 20261021T111548Z-2b6d9f0b is PASS and root-admitted; Preflight, DependencyConfigure and DependencyBuild passed and were admitted. EditorPrerequisiteBuild failed closed on A1G_UNIQUE_REAL_BUILD_ACTION_NOT_OBSERVED after native UBT exit 0: retained compile/link lines append literal [NoUba] while the current anchored matcher expects end-of-line after the basename. The compiler logged 16 actions and Succeeded, with two retained C4701 warnings; process exit/cleanup are confirmed (57.7511418 seconds; final 38/0), and outer PowerShell closed exit 1 without timeout/kill. No Editor completion exists. Five downstream phases are NOT_RUN, zero Game attempts/checks. The run is closed with no retry or successor GO; no repair is adopted. [Closure](research/2026-10-21-e04a-game-editor-action-failure-closure.md), [SOURCE](research/2026-10-21-e04a-game-source-prerequisite-71ce131.md), [raw SOURCE](research/2026-10-21-e04a-game-source-review-71ce131.md), [receipt](evidence/2026-10-21-e04a-game-editor-action-failure.json). Root finite preservation matched 84 states, 47 retained artifacts and six predecessor descriptors; compiler success does not pass the wrapper gate. Checkpoint/push/gh-verify OWN18 failure backup before narrow repair, then repaired-source backup, fresh bindings and affected SOURCE. No approval transfers to changed source. Bounded A1E acceptance, historical failures, OWN17 deferred/unproven, visible zero, Linux UNTESTED and perpetual review consent are unchanged.

Historical revision 104: **GAME_DEPENDENCY_PHASE_CLOSURE_SOURCE_REPAIRED_FRESH_SOURCE_PENDING** (revision 104). Root adopted the Game-only current-freeze and dependency phase/process/artifact joins, plus wrapper freeze path/hash environment inputs, after failure checkpoint 8e920075 and verified OWN18 backup. The norm is unchanged. [Repair](research/2026-10-21-e04a-game-dependency-phase-closure-source-repair.md), [receipt](evidence/2026-10-21-e04a-game-dependency-phase-closure-source-repair.json). At adoption on 2026-10-21T11:09:10.2893142Z, root inspected the full functional diff, matched the 15207-byte Editor prefix and wrapper inverse/AST checks, with six CR bytes recorded in both Rules versions; the whole Rules inverse is separately auxiliary-reported. C# compilation, behavior, fresh SOURCE and all nine repaired-candidate phases were NOT_RUN then, with no new RunId or approval transfer. Checkpoint/push/gh-verify repaired-source backup before fresh bindings and affected SOURCE; native phases follow positive SOURCE admission and separate ordered GOs. Preserve raw 553dc39 FAIL/closed unused run and older 3201552 PASS/failure. Bounded A1E acceptance, OWN17 deferred/unproven, visible zero, Linux UNTESTED and perpetual review consent are unchanged.

Historical revision 103: **FOCUSED_SOURCE_FAILED_GAME_DEPENDENCY_PHASE_CLOSURE_REQUIRED** (revision 103). Fresh SOURCE for 553dc39 / planned run 20261021T105009Z-0a4b58ea is raw FAIL: the Game ModuleRules branch binds configure/build process and artifact receipts but omits the same-run dependency completion/result binding required by the norm. Root confirmed the source gap; no reproduction or repair occurred. [Closure](research/2026-10-21-e04a-game-dependency-phase-closure-source-failure.md), [raw report](research/2026-10-21-e04a-game-source-review-553dc39.md), [receipt](evidence/2026-10-21-e04a-game-source-failure-553dc39.json). The review process is closed; strict 12/8/774 before-body rehash matched, with console/delivery limitations retained. Ten separate archive-action controls passed before SOURCE. There is no positive SOURCE admission, native RunRoot or phase GO; all nine phases are NOT_RUN and Game attempts/checks are zero. The planned run is closed with no retry. Checkpoint/push/gh-verify OWN18 failure backup before a narrow source repair; then repaired-source backup, fresh bindings and affected SOURCE. Preserve the old 3201552 raw PASS and its closed failed run. Bounded A1E acceptance, historical failures, OWN17 deferred/unproven, visible zero, Linux UNTESTED and perpetual review consent are unchanged.

Historical revision 102: **GAME_ARCHIVE_ACTION_SOURCE_REPAIRED_FRESH_SOURCE_PENDING** (revision 102). Root adopted the narrow direct-archive action validator, build-receipt retention and five normative lines after failure checkpoint 2b9faae9 and verified OWN18 backup. The validator binds the selected shell, frozen librarian bytes/hash, x64 output and exact ordinal acquired-source object sequence; no-work and unsupported shape fail closed. [Repair](research/2026-10-21-e04a-game-archive-action-source-repair.md), [receipt](evidence/2026-10-21-e04a-game-archive-action-source-repair.json). At adoption on 2026-10-21T10:46:05.1125815Z, whole inverse/AST checks passed; behavioral controls, fresh SOURCE and all nine repaired-candidate phases were NOT_RUN, with no new RunId or approval transfer. These are as-of-adoption facts. Checkpoint/push/gh-verify the repaired-source backup before finite pure controls, fresh bindings and affected SOURCE, then separate ordered phase GOs. Preserve the old raw SOURCE PASS and closed failed run 20261021T101933Z-40d00c7c. Bounded A1E acceptance, OWN17 deferred/unproven, visible zero, Linux UNTESTED and perpetual review consent are unchanged.

Historical revision 101: **FOCUSED_SOURCE_PASSED_GAME_DEPENDENCY_BUILD_ARCHIVE_ACTION_FAILURE_CLOSED** (revision 101). Fresh SOURCE for 3201552 / run 20261021T101933Z-40d00c7c is PASS and root-admitted. Separate finite comparison controls passed 22/22 before SOURCE. Preflight and DependencyConfigure passed. DependencyBuild failed closed on A1G_VENDOR_STATIC_ARCHIVE_ACTION_NOT_OBSERVED after native CMake exit 0: stdout uses direct pinned lib.exe while the wrapper expects cmake -E vs_link_lib. Native exit/cleanup are confirmed (13.8238672 seconds; final 38/0), and outer PowerShell closed exit 1. No DependencyBuild completion or artifact receipt/copy exists. Six downstream phases are NOT_RUN, with zero Game attempts/checks. The run is closed with no retry or successor GO; no repair is adopted. [Closure](research/2026-10-21-e04a-game-archive-action-failure-closure.md), [raw SOURCE](research/2026-10-21-e04a-game-source-review-3201552.md), [receipt](evidence/2026-10-21-e04a-game-archive-action-failure.json). Checkpoint/push/gh-verify OWN18 failure backup before narrow source repair; then repaired-source backup, fresh bindings and affected SOURCE before a new phase chain. Bounded A1E acceptance, historical failures, OWN17 deferred/unproven, visible zero, Linux UNTESTED and perpetual review consent are unchanged.

Historical revision 100: **GAME_KEY_ORDER_SOURCE_REPAIRED_FRESH_SOURCE_PENDING** (revision 100). Root adopted the narrow Equal-Data source repair after failure checkpoint 38b9c668 and verified OWN18 backup. The source adds ordinal dictionary-key canonicalization while retaining array order and scalar distinctions; the norm now states those comparison criteria. [Repair](research/2026-10-21-e04a-game-key-order-source-repair.md), [receipt](evidence/2026-10-21-e04a-game-key-order-source-repair.json). At adoption on 2026-10-21T10:13:10Z, validation was inverse/AST only; no behavioral, independent SOURCE or native PASS is claimed. Next checkpoint/push/verify repaired-source backup, finite pure comparison controls, then fresh exact bindings and fresh SOURCE before nine phase GOs. All native phases remain NOT_RUN with zero attempts/checks, new RunId not bound and no admission. Raw 2b52bbc FAIL/closed run and prior failures remain unchanged. Bounded A1E acceptance, OWN17 deferred/unproven, visible zero, Linux UNTESTED and perpetual review consent are unchanged.

Historical revision99: **FOCUSED_SOURCE_FAILED_GAME_KEY_ORDER_REPAIR_REQUIRED** (revision 99). Fresh independent SOURCE for 2b52bbc / planned run 20261021T095500Z-68aaa7fa is raw FAIL: Equal-Data compares serialized JSON, so unordered dictionary key order can reject otherwise identical maps across fresh hosts. This is a source finding, with no reproduction executed. [Closure](research/2026-10-21-e04a-game-key-order-source-failure-closure.md), [raw report](research/2026-10-21-e04a-game-source-review-2b52bbc.md), [receipt](evidence/2026-10-21-e04a-game-source-failure-2b52bbc.json). No positive SOURCE admission; the planned run is closed, its native RunRoot never allocated and all nine phases NOT_RUN. Two inputs/two attempts/52 checks remain planned; zero attempts/checks executed. Checkpoint/push/gh-verify OWN18 failure backup before source repair; then repaired-source checkpoint/backup, fresh bindings and fresh SOURCE before any phase GO. Bounded A1E acceptance, OWN17 deferred/unproven, Linux UNTESTED, visible authority zero and perpetual review consent are unchanged.

Historical revision98: **GAME_WRAPPER_SOURCE_REPAIRED_FRESH_SOURCE_PENDING** (revision 98). Three source-only repairs are applied after failure checkpoint `7c0c017` and verified OWN18 backup: separate phase evidence, optional receipt arrays and ordered runtime-dependency copy joins. [Repair](research/2026-10-21-e04a-game-wrapper-source-repair.md), [receipt](evidence/2026-10-21-e04a-game-wrapper-source-repair.json). Inverse/AST diagnostics only; fresh SOURCE and all nine phases are NOT_RUN, with zero executed attempts/checks and no new RunId/freeze/admission. Preserve raw `370bfba` FAIL and its closed, never-allocated planned run. Checkpoint/verify the repaired candidate backup, then fresh exact bindings and focused SOURCE before any phase GO. Bounded A1E acceptance is unchanged; OWN17 deferred/unproven, visible authority zero, Linux UNTESTED and perpetual review consent unchanged.

Historical revision97: **FOCUSED_SOURCE_FAILED_GAME_WRAPPER_REPAIRS_REQUIRED** (revision 97). Fresh SOURCE for `370bfba` / planned run `20261021T090959Z-5fce384b` is FAIL: phase-evidence/payload collisions, optional receipt arrays and missing runtime-dependency reconciliation. The process is closed, raw FAIL report and before-body seals are retained; root made no SOURCE admission. All nine phases remain NOT_RUN, no native RunRoot or phase GO exists, visible authority is zero and Linux is UNTESTED. Checkpoint/push/verify OWN18 failure backup before narrow repairs; then checkpoint/backup, fresh bindings and affected SOURCE. A1E acceptance is unchanged; OWN17 remains deferred/unproven. Final CODE/different REQ and later gates stay open.
[Closure](research/2026-10-21-e04a-game-source-failure-closure.md), [raw report](research/2026-10-21-e04a-game-source-review-370bfba.md) and [receipt](evidence/2026-10-21-e04a-game-source-failure-370bfba.json).

Historical revision96: **A1G_SOURCE_ADOPTED_FRESH_BINDINGS_PENDING**. The dedicated Game caller, Game-only vendor branch, Editor-only AutomationDriver dependency, nine-phase wrapper and qualified Native window observer are canonical source. Two inputs/two attempts/52 checks are planned, with no actual build/cook/stage/native result or SOURCE admission. The existing bounded A1E acceptance remains unchanged. [Game proof packet](research/2026-10-21-e04a-game-proof-packet.md) and [source adoption](evidence/2026-10-21-e04a-game-source-adoption.json). Checkpoint/verify OWN18 source backup, derive fresh exact head/run/freeze/tools/config/inputs/commands, then obtain one focused SOURCE assessment before any of the nine ordered phase GOs. All nine phases are NOT_RUN, no native RunRoot is allocated, visible authority is zero and Linux remains UNTESTED. Final CODE and different REQ follow actual closed execution; OWN17 remains deferred/unproven.

Current A1E status at revision 95 is **BOUNDED_E04_A1E_ACCEPTANCE_RECORDED**.
[Final review provenance](evidence/2026-10-21-e04a-editor-final-review-provenance.json); [CODE](research/2026-10-21-e04a-editor-final-code.md), [initial REQ](research/2026-10-21-e04a-editor-final-requirements.md), [limited supplement](research/2026-10-21-e04a-editor-requirements-supplement.md) and [focused SOURCE](research/2026-10-21-e04a-editor-source-review.md).
CODE PASS plus the valid initial REQ technical findings and limited supplement PASS close only the Windows Editor subset. The initial raw BLOCKED verdict and ordering failure remain unchanged. Revision95 metadata was checkpointed and its exact remote backup verified at 2651a86. Current A1G work follows revision 112 above; no old review or native authority transfers.

Historical A1E status at revision 75 was **NULL_RESPONSE_ENV_REPAIRS_APPLIED_SOURCE_REFRESH_PENDING**.
The [repair checkpoint](research/2026-10-20-e04a-null-response-env-repair-checkpoint.md)
and [factual record](evidence/2026-10-20-e04a-null-response-env-repairs.json) bind
applied source repairs, 43 inputs/33 recipes/50 attempts/eight suites and 14
matching PS-only controls. Exact successor bindings and affected SOURCE remain
pending; C#4/Rules86/whole18 and all native phases NOT_RUN. A1G/A2/final/later
gates and standing source/API consent remain unchanged.

Historical revision 74: the [closed round](research/2026-10-20-e04a-value-build-source-closure.md)
preserves five raw reports/437 pairs, zero admissions and five never-launched jobs.

Historical A1E status at revision 71 is **TOOLCHAIN_GUARDS_REPAIRED_SOURCE_REFRESH_PENDING**.
Technical commit `3b5447e777da76b555215c135977c92a1706282b` adds 14 lines/zero
removals: `RejectUnsupportedNativeToolAlternatives` rejects three effective
unsupported toolchain flags at final module construction. Ordinary inspection
found no actionable issue; compilation/controls/native checks are NOT_RUN and
there is no SOURCE approval. Derive fresh current publication/run/common/index
bindings and affected reviews, including both whole witnesses. The
[revision70 closure](research/2026-10-20-e04a-practical-source-closure.md) and
[factual record](evidence/2026-10-20-e04a-practical-source-result.json) remain
historical and unchanged. Zero admissions, no native RunRoot, visible authority
zero and final/later gates remain open; substantive v7.3 and consent persist.

Historical A1E status at revision 66 is **SCOPED_SOURCE_R6_CLOSED_FOLLOWUP_REQUIRED**.
The [R6 summary](research/2026-10-20-e04a-scoped-r6-summary.md) and
[factual record](evidence/2026-10-20-e04a-scoped-r6-result.json) preserve eight
closed initial reports: five SOURCE_PASS, three BLOCKED and 479 tool pairs.
No local admission or aggregate follows. TARGET is incomplete, PLUGIN needs
runtime helper source, and BUILD records a review-conduct deviation. Both
integrations remain unused and all native phases NOT_RUN. Complete audits and
prospectively amend/rebind affected review duties before follow-up. Current v6
permits no reuse. Standing source/API consent persists until revoked.

Historical A1E status at revision 65 is **LOCAL_DUTY_CRITERIA_ADOPTED_BINDINGS_PENDING**.
The [v6 criteria](research/2026-10-20-e04a-source-composition-packet-v6.md),
[template](research/2026-10-20-e04a-source-scope-contract-v6.template.json) and
[adoption](evidence/2026-10-20-e04a-v6-local-duty-criteria-adoption.json) retain
complete global duties with explicit local assignments and full integrations.
Actual new source/unit/count/common bindings and fresh reviews remain pending.

Historical A1E status at revision 64 is **RULES_REPAIR_CONTROLS_PASSED_BINDINGS_PENDING**.
The [repair](research/2026-10-20-e04a-rules-repair-checkpoint.md) and
[bindings](evidence/2026-10-20-e04a-rules-source-preservation-result.json) record
80/80 actual pure controls, zero failures and exact source/raw evidence. Fresh
SOURCE packets and independent integrations remain required; native phases are
NOT_RUN and zero visible windows remain. Standing review consent persists.

Historical A1E status at revision 63 is **SCOPED_SOURCE_REPAIRS_REQUIRED**.
The [R5 summary](research/2026-10-20-e04a-scoped-r5-summary.md) and
[factual record](evidence/2026-10-20-e04a-scoped-r5-result.json) preserve eight closed
raw reports (four SOURCE_PASS, three BLOCKED, one CHANGES_REQUESTED), 490 captured
tool pairs and zero root admissions. Root-confirmed source locking, map-category
and manifest-control gaps require repair and fresh affected review. Both
integrations are unused; all eight native phases remain NOT_RUN/no native RunRoot.
Standing private-source/API review consent persists until explicitly revoked.

Historical A1E status at plan revision 57 (2026-10-20 UTC) is
**SCOPED_SOURCE_CHANGES_REQUESTED_RULES_OBSERVATION**. The closed
[R4 summary](research/2026-10-20-e04a-scoped-r4-summary.md) and
[factual record](evidence/2026-10-20-e04a-scoped-r4-result.json)
preserve eight initial invocations, seven unchanged reports (six local
SOURCE_PASS/one CHANGES_REQUESTED), one plugin timeout without a report and
416 captured tool pairs from the seven report contexts. All eight process groups
cleaned up. Only S_VALUE has a current bounded local admission; no aggregate or
future approval follows. Other audits remain incomplete or not admitted.

S_TARGET_RECEIPT-01 requires a concrete observation/preservation mechanism for
actual discovery/cache/process/source-order lineage, the loaded rules assembly,
selected target CLR type and applicable finalized selectors, plus retained
BuildRules artifacts/source manifest. Root confirmed the prospective harness
gap. D001's case-insensitive projection conceals ProgramAllowlist versus
ProgramAllowList; raw PASS remains unchanged. Plugin final runtime/tool capture
failed on an unterminated stdout JSON line and remains unverified.

Neither integration launched. All eight native phases are NOT_RUN/no native
RunRoot. Preserve original failures and partial ordinary audits. Checkpoint,
repair the concrete observation design and review-fidelity/capacity preparation,
rederive changed complete units/counts, refreeze and obtain fresh affected SOURCE
and independent integrations. No old GO or local admission transfers to repaired
source. Final CODE/different REQ, A1G/A2/HUD, Linux, packaging and broader gates
remain open. Standing private-source/API review consent persists until revoked.

Historical A1E status at plan revision 56 (2026-10-20 UTC) is
**NORMAL_RULES_SOURCE_AMENDMENT_ADOPTED_PACKETS_NOT_READY**. Root prospectively
adopted the [normal rules discovery SOURCE amendment](research/2026-10-20-e04a-source-composition-packet-v4.md)
and its [adoption record](evidence/2026-10-20-e04a-normal-rules-amendment-adoption.json).
The [count-text correction](evidence/2026-10-20-e04a-normal-rules-count-text-correction.json)
replaces only its unbound template. The first ten-panel metadata campaign is
closed unused after two stale prose counts were caught before any GO or launch;
fresh corrected bindings remain pending.
The reference inventory is 97 BODY files / 47,410 physical rows; actual counts
and identities must be derived from the new freeze after normative inputs are
final. BODY095 adds 4,424 physical rows / 4,332 literal rows from 23 ranges in
16 installed origins. BUILD, TARGET and both integrations require complete
BODY081/082/092/093/095. All previous body/unit/data/graph duties remain,
including 13 selected records / 902 descriptor rows / 1,561 reference occurrences;
conditional/framework leaves remain explicit rather than universal UBT closure.

SOURCE assesses frozen source, textual invocation/selection/membership and the
prospective observation/preservation design. Actual staging/cache lineage,
loaded assembly/type, effective configuration/compiler outputs and activation
remain native-phase/final observations. Their absence before authorized native
execution alone does not fail SOURCE; concrete source/input/design gaps do.
Prospective SOURCE budgets are 2,700 seconds for BUILD, TARGET and both
integrations, and 1,800 seconds for the other six scopes. Each launch requires
one fresh context, one review launch maximum per assessment, no retry, no model change and exact
consistent packet/runtime/supervisor/GO bindings.

Fresh corrected head/run/campaign/freeze/panel/GO bindings and review/native
results remain pending. All ten fresh independently valid complete PASS assessments,
root admission audits and a labelled aggregate precede any phase. All eight
native phases remain NOT RUN/no native RunRoot. No R3 admission transfers to
the amended source. Final CODE/different REQ, A1G/A2, HUD/render/input, Linux,
packaging and broader gates remain open; standing review consent persists.

Historical A1E status at plan revision 55 (2026-10-20 UTC) is
**SCOPED_SOURCE_BLOCKED_RULES_ASSEMBLY_DISCOVERY**. The
[R3 summary](research/2026-10-20-e04a-scoped-r3-summary.md) and
[factual record](evidence/2026-10-20-e04a-scoped-r3-result.json)
preserve eleven closed invocations, ten unchanged raw reports and 743 tool pairs.
Eight local admissions were initially recorded; TARGET/BUILD were later withdrawn,
leaving six old-scope admissions. The complete ten-scope SOURCE gate remains false.
I_ACTIVATION-B01 requires the normal discovery/assembly producer. ABI exited 1
after a service-capacity error and produced no report or verdict; all processes
confirmed cleanup and no timeout. The unused ABI replacement is superseded
without GO/launch. Amending/refreezing the missing source and obtaining current
complete SOURCE/integrations were pending at that checkpoint. All eight native phases
remain NOT RUN/no native RunRoot. Final CODE/different REQ, A1G/A2, Linux,
packaging and broader gates remain open. Standing review consent persists.

Historical A1E status at plan revision 54 (2026-10-20 UTC) is
**STARTUP_TARGET_SOURCE_AMENDMENT_ADOPTED_PACKETS_NOT_READY**.
Root prospectively adopted the [startup and target-selection SOURCE amendment](research/2026-10-20-e04a-source-composition-packet-v3.md)
and its [adoption record](evidence/2026-10-20-e04a-startup-target-amendment-adoption.json). The reference inventory is
96 BODY files / 42,986 physical rows, with all 13 selected records, 902 descriptor
rows, 1,561 reference occurrences and earlier full-body/unit/data duties retained.
The new literal inputs cover complete target creation/configuration/finalization
and alternate all-modules selection, plus Default startup and explicit load/mount
implementations, defaults and finite material callers.

The dedicated Editor target now explicitly assigns `bBuildAllModules=false`
(593 bytes / 16 rows). This source change is unexecuted; it establishes no actual
effective-target, build, startup or runtime result. The metadata-helper sources
are prospectively adopted, but no new helper operation, subject/freeze/campaign,
review GO, review or native result exists. Exact fresh packets and bindings
remain pending. All ten fresh complete valid SOURCE assessments and root
admission must precede any phase.

R2's six raw local SOURCE_PASS and two BLOCKED reports remain unchanged, with
zero aggregate-admitted passes. Its two integration metadata directories are
unused without GO/launch; all eight phases remain NOT RUN and no native RunRoot
exists. Final CODE/different REQ, A1G, A2's 727 scenarios, shared HUD/render/input,
Linux, packaging and broader gates remain open. Standing private-source/API
review consent persists until explicitly revoked.

Historical revision 53 records
**SCOPED_SOURCE_BLOCKED_STARTUP_AND_ALL_MODULES**.
Eight fresh scoped SOURCE reviews closed for `7ef9358d836ed75b9d8ebc40b26c1b8f74af6ac4`
/ run `20261020T052654Z-6fe9feeb`, against base
`03d28af606fc6c57d20915f746296b0d843211c6`. Six raw local reports are
SOURCE_PASS and TARGET/PLUGIN are BLOCKED; **zero passes are aggregate-admitted**.
The 94-BODY / 35,428-row, 13-record / 902-row campaign retained 414 exact tool
input/output pairs. All eight distinct review sessions exited 0 with confirmed
cleanup and no timeout. These process results do not establish SOURCE approval.

TARGET-B01 leaves effective XML-configurable `bBuildAllModules` and its alternate
`PreBuildSetup` path unresolved. TARGET-B02 / PLUGIN-B1 lack the complete
Default-phase startup caller; PLUGIN-B2 lacks complete explicit plugin load/mount
implementations and material callers. These are positive-input/source-context
gaps; no implementation defect is asserted. The
[R2 summary](research/2026-10-20-e04a-scoped-r2-summary.md) and [factual record](evidence/2026-10-20-e04a-scoped-r2-result.json) preserve all eight raw reports.

Both integration directories contain unused metadata only: no GO or launch.
All eight experiment phases remain NOT RUN, with no native RunRoot. Repair
proposals are being prepared; they are not adopted, implemented or natively
proved. Fresh affected SOURCE and blind integrations, root admission and a
labelled aggregate remain required before any phase. Final CODE/different REQ,
A1G, A2's 727 scenarios, shared HUD/render/input, Linux and packaging remain open.
Standing private-source/API review consent persists until explicitly revoked.

Historical revision 52 records
**TARGET_RULE_SOURCE_AMENDMENT_ADOPTED_PACKETS_NOT_READY**.
Root prospectively adopted the [target-rule SOURCE amendment](research/2026-10-20-e04a-source-composition-packet-v2.md).
Its reference inventory is 94 BODY files / 35,428 rows, including the new
2,968-row literal target-rule/default/initialization input, with all earlier
source/data/unit duties retained. Exactly three immutable common criteria
records receive explicit metadata grants; generated runtime/invocation bodies
remain ungranted, and field queries must preserve actual presence and values.
The [adoption record](evidence/2026-10-20-e04a-target-rule-amendment-adoption.json) binds the unbound v5 template, independent
literal/coverage checks and root-inspected metadata-helper proposals.
Exact candidate/run/campaign/panel bindings are not ready; helpers are
uninvoked. All ten fresh complete valid PASS assessments and root admission
audits remain required before any phase. The first campaign's seven raw local
passes/one BLOCKED and observed deviations remain unchanged. No aggregate,
native/phase GO, acceptance or merge follows. Implementation and historical
path controls are unchanged/not rerun; A1G/A2/final CODE/different REQ/Linux
and broader gates remain open. Standing review consent persists until revoked.

Historical revision 51 records **SCOPED_SOURCE_BLOCKED_TARGET_RULES_INPUTS**.
Eight fresh initial scoped SOURCE reviews are closed for `f7f77eb` / run
`20261020T044205Z-14143fc0`: seven raw local SOURCE_PASS reports and one
BLOCKED target/receipt report. `TARGET-RECEIPT-B01` identifies missing complete
inherited plugin-dependency hook and target-selector defaults/initialization
primary inputs, without asserting an implementation defect. All eight raw
reports were sealed before body reads and preserved unchanged; both integrations
remain NOT LAUNCHED. No local pass is admitted to an aggregate. The
[factual record](evidence/2026-10-20-e04a-scoped-r1-result.json) binds closure and limitations. Amend/refreeze the necessary
primary inputs and exact access guidance, then obtain fresh affected SOURCE
and blind integrations. All eight phases remain NOT RUN/no native RunRoot;
implementation and historical path controls are unchanged/not rerun. Final
CODE/different REQ, A1G/A2, Linux and broader gates remain open. Standing
private-source/API review consent persists until explicit revocation.

Historical revision 50 records **SCOPED_SOURCE_COMPOSITION_ADOPTED_PACKETS_NOT_READY**.
Root has prospectively adopted the [ten-context SOURCE composition packet](research/2026-10-20-e04a-source-composition-packet.md):
five fresh blind primary SOURCE scopes, three complete descriptor-data partitions
and two fresh blind integrations after the eight primary/data reports are sealed.
The [adoption record](evidence/2026-10-20-e04a-source-composition-adoption.json)
binds this prospective decision. Every one of the ten must be independently valid, complete and PASS, followed by
root runtime/input/output/scope/completeness audits and a labelled aggregate
SOURCE disposition. Preserve the full reference 93-BODY union, all 13 selected
metadata records/902 rows, all 1,561 Plugin-reference occurrences and material
relationships; derive actual new frozen identities/counts. Exact-candidate
packets, contracts/manifests/policies/prompts and runtime bindings are not ready.
The immutable transport is unchanged; root separately enforces scope/campaign/
full-prompt bindings and the aggregate gate. `sourceReviewed.report` must bind
the labelled root aggregate JSON; the wrapper does not automatically validate
all child reports. This adoption grants no review launch GO, native/phase GO,
acceptance or merge. Raw r7 and all earlier records remain unchanged; all eight
phases remain NOT RUN/no native RunRoot. Final CODE/different REQ and A1G/A2/
broader gates remain separate. Standing review consent persists until revoked.

Historical revision 49 records **SOURCE_BLOCKED_INCOMPLETE_REVIEW_DECOMPOSITION_PREPARING**.
The seventh [E04-A1E SOURCE report](research/2026-10-20-e04a-source-review-r7.md)
is raw **BLOCKED** for `e505b21` / run `20261020T041347Z-5175df78`.
It completed 55 of 93 BODY files; all 33 staged members now have BODY grants.
The 13-record/902-row metadata assessment remains incomplete. No confirmed
implementation defect or binding/access denial was established. The
[factual record](evidence/2026-10-20-e04a-source-r7-result.json)
preserves this uncertainty. The review is closed; all eight phases remain NOT RUN
and no native RunRoot exists. A prospective blind scoped SOURCE design plus a
fresh independent integration assessment is being prepared, **not yet adopted**.
It must retain complete current 93-file coverage across the scopes, all 13/902
selected metadata and material relationships, with no waived criterion before
any phase. Separate final CODE/different REQ remain required. The existing path
repair and 21 passing pure PowerShell controls are unchanged/not rerun; historical
r6/r5 reports and c500f21 phase results remain unchanged. Standing review consent
persists until explicit revocation; A1G, A2 and broader gates remain open.

Historical revision 48 records **SOURCE_BLOCKED_STAGED_BODY_GRANTS_REPAIR_AUTHORED**.
The sixth [E04-A1E SOURCE report](research/2026-10-20-e04a-source-review-r6.md)
is raw **BLOCKED** for `0ed4221` / run `20261020T035315Z-1e4656b7`.
It inspected 48 of 81 BODY files; the 13-record/902-row metadata assessment is
incomplete. Existing staged client/test/settings files lack positive BODY grants.
This is unresolved review scope, with no implementation defect asserted. The
[factual record](evidence/2026-10-20-e04a-source-r6-result.json)
preserves the limitations. All eight phases for this candidate remain NOT RUN;
there is no native RunRoot. Root has authored the staged-source BODY-grant
inventory proposal, without implementation changes. The root-inspected ordinary inventory proposal adds 12 missing BODY files / 5,906 rows and covers all 33 staged members. Its current-byte estimate is 93 BODY files / 32,460 rows; the actual future frozen inventory must derive and verify those counts. The path repair and 21 passing pure
PowerShell cases are unchanged and were not rerun. A new complete source
inventory, neutral packet/freeze/RunId and fresh SOURCE precede any phase;
future BODY counts must come from that inventory. Old c500f21 Preflight/SUP PASS
and Configure FAIL remain historical. Final CODE/different REQ, A1G, A2 and
broader gates remain open. Standing review consent persists until revoked.

Historical revision 47 records **CONFIGURE_FAILED_PATH_REPAIR_AUTHORED**. The fifth
[SOURCE report](research/2026-10-20-e04a-source-review-r5.md) is raw SOURCE_PASS
only for `c500f21` / run `20261020T024733Z-0781e386`. The
[factual record](evidence/2026-10-20-e04a-source-r5-result.json) retains its bounded
Editor qualifications and closed execution: Preflight passed with zero roots,
six supervisor controls passed in three groups/five roots, then Configure failed
on generated SDK RC-path escaping. The root exited 1 in about 0.859 seconds;
one unidentified job member lingered until confirmed timeout cleanup/final zero.
Producer preservation missed its deadline; separate manual post-close checks
matched 1,885 frozen files, 33 staged sources, 51 fixtures and nine settings pairs.
They do not pass the failed phase. The path repair passed 21 pure PowerShell
cases with zero failures; checkpoint/new freeze/RunId and fresh affected SOURCE
remain pending. The five
later phases are NOT RUN. Final CODE/different REQ, A1G, A2/HUD, Linux and packages
remain open; standing review consent persists until explicit revocation.

Historical revision 46 records **SOURCE_BLOCKED_REVIEW_DELIVERY_REPAIR_AUTHORED**. The
fourth [SOURCE report](research/2026-10-20-e04a-source-review-r4.md) is raw
BLOCKED: only 19 of 78 BODY files were inspected, metadata relationships remain
incomplete, and an oversized dump exposed unselected freeze qualifications.
No new code defect was established. Its [factual record](evidence/2026-10-20-e04a-source-r4-result.json)
preserves those limits and closed authority. A compact bootstrap and positive
initial selectors repair delivery while retaining complete source/metadata
coverage. New checkpoint/freeze/RunId and complete fresh SOURCE precede any
phase. All eight phases remain NOT RUN; earlier reports remain unchanged.

Historical revision 45 records **SOURCE_BLOCKED_DDC_REPAIR_AUTHORED**. The third
[SOURCE report](research/2026-10-20-e04a-source-review-r3.md) is raw BLOCKED:
52 of 78 required BODY files were inspected and the DDC guard lacked an owned
writable active-store requirement. The guard now requires the exact owned store
and rejects installed graph-switch diagnostics. Twenty-one offline cases / 63
checks passed. The [factual record](evidence/2026-10-20-e04a-source-r3-result.json)
retains the incomplete review and closed authority. A new checkpoint/freeze/RunId
and complete fresh affected SOURCE precede any phase. All eight phases remain
NOT RUN; the three old assessments remain unchanged.

Historical revision 44 records **SOURCE_CHANGES_REQUESTED_JSON_LINE_REPAIR_AUTHORED**.
The second [SOURCE report](research/2026-10-20-e04a-source-review-r2.md) found an
undefined Parse-JsonLine call; its exact strict E02 implementation is restored.
The [factual record](evidence/2026-10-20-e04a-source-r2-result.json) preserves
the closed assessment. Fifteen offline cases / 38 checks passed. Checkpoint and freeze a new
candidate/RunId for fresh affected SOURCE. All eight phases remain NOT RUN.

Historical revision 43 records **SOURCE_BLOCKED_PRIMARY_API_AMENDMENT_AUTHORED** for
E04-A1E. The first [SOURCE report](research/2026-10-20-e04a-source-review-r1.md)
is raw BLOCKED on missing primary API inputs and an excluded metadata-purpose
projection, with no confirmed C++ defect. The [factual record](evidence/2026-10-20-e04a-source-r1-result.json)
closes that review/run authority; all eight phases remain NOT RUN. The two proof
modules request NoPCHs and UBT requests -NoVFS in the authored, unexecuted amendment.
Read the actual
[packet](research/2026-10-19-e04a-profile-packet.md),
[journal](evidence/2026-10-19-e04a-profile.md) and
[source promotion record](evidence/2026-10-20-e04a-source-promotion.json).
The promotion record retains the original 18-path bytes. The amended candidate
needs a new checkpoint/freeze, complete primary API inputs, new RunId and fresh
affected SOURCE review; all
eight phases are NOT RUN. Eight suites, 38 unique input IDs and 45 attempts are
planned. Editor exceptions are enabled by target policy; genuinely disabled A1G
runtime-caller proof remains mandatory before full A1 adoption. A2 keeps all
727 compatibility scenarios, and shared HUD/render/input, Linux and packaging
remain open. Promotion grants no execution or acceptance authority. Bounded E02
acceptance and its closed, consumed window authority remain unchanged.
Historical revision 41 records **BOUNDED_E02_WINDOWS_SYNTHETIC_ACCEPTANCE_RECORDED**.
The [combined root disposition](evidence/2026-10-20-e02-bounded-acceptance.json)
combines the unchanged technical assessments with the new
[administrative recovery supplement](research/2026-10-20-e02-final-requirements-approval-recovery.md)
SUPPLEMENTAL_PASS and separately verified SOURCE prerequisite. The original
three raw BLOCKED reports, historical checkpoint omission, relay limitations and
earlier failures remain unchanged. This is bounded synthetic Windows acceptance;
full E02/M02 and broader gates remain open. Zero visible launches remain and no
publication/merge authority is added. E04-A1E source freeze/review is next; the
actual exception-disabled A1G caller is still mandatory before full A1 adoption.

Historical revision 40 recorded **EXECUTION_PASS_FINAL_ACCEPTANCE_BLOCKED_ADMIN**. Executed source remains `5e92ba336da0570cb4b57def390ad3c58921e625`, run `20261019T202805Z-5ff8cb61`; the final reviewed candidate is `3a1d17902f6fa94b6009c0cae573da8bf7dff063`. Final [CODE r3](research/2026-10-20-e02-final-code-r3.md), [REQ r2](research/2026-10-20-e02-final-requirements-r2.md) and the postsealed [limited supplement v4](research/2026-10-20-e02-final-requirements-supplement-v4.md) are closed with raw BLOCKED verdicts. Root separately verified CODE's opaque SOURCE prerequisite; the supplement resolves reading-count/hash-gate/administrative source-binding concerns without establishing fundamental contamination requiring a fresh initial assessment. The [final-review provenance](evidence/2026-10-20-e02-final-review-provenance.json) preserves those dispositions. Historical checkpoint `1c99360` is now conservatively clarified as UNREVIEWED_FOR_ACCEPTANCE; its original missing status/noncompliance is not retroactively repaired, and RQ25/E09 remain open/unexecuted. Independent original prelaunch approval retrieval/timing verification remains pending owner factual clarification. No raw verdict is promoted to PASS, and acceptance, push and merge are not released.

The unchanged [execution result](evidence/2026-10-19-e02-5e92-result.json) and [journal](evidence/2026-10-16-e02-world-input.md) retain 16 native cases / 18174 assertions, separate SUP6, six PNGs, 4562 input events and 20 ray records. Both visible windows are consumed; native authority is closed with zero launches remaining. Root's six-image observations are implementer evidence. Same-effective-pixel accuracy does not establish arbitrary fractional-point precision. RQ23/RQ24, full E02/M02/E04, Linux, packaging, real-Core play and full HUD/profile behavior remain open.

Historical source preparation before canonical promotion: a separate isolated E04-A1 source-only draft covered 18 paths, eight proposed native cases and 38 input IDs. Pinned yaml-cpp source `56e3bb550c91fd7005566f19c079cb7a503223cf` was acquired and byte-verified (394 files / 5156535 bytes). No canonical promotion, library configure/build, native execution or acceptance has occurred.

Historical revision 38 records 3483f79 SOURCE BLOCKED before body reads because the actual prompt omitted explicit root launch GO. Source merits are UNASSESSED; all planned-run authority is closed with no E02 execution. [Historical source-review facts](evidence/2026-10-19-e02-3483-source-result.json) preserve that closure. The full-matrix guard was then UNEXECUTED. Historical [c9a5ac5 SOURCE CHANGES_REQUESTED](evidence/2026-10-19-e02-c9a5-source-result.json) and c987 WorldInput FAIL remain unchanged; those records supply no final CODE/REQ acceptance.

Historical revision 36 records the authored, UNEXECUTED RaisedPicking effective-pixel oracle and numeric diagnostics. Revision 35 preserves the failed c987 phase, 11-case partial diagnostics and consumed windows. [Current facts](evidence/2026-10-19-e02-c987-result.json) and [journal](evidence/2026-10-16-e02-world-input.md) distinguish the failure from the passed predecessors. Old execution authority is closed; the repair needs its own freeze/review/hidden checks and new applicable visible approval. Final independent acceptance remains pending.

Revision 34 makes the [M03 project-owned startup level](unreal-migration-plan.md#116-project-owned-startup-level-and-m03-entry-path) explicit through ENTRY01–ENTRY08: intentional editor/game defaults, reproducible launch, cook references, Core/session lifetime and meaningful slice/error evidence. A single minimal entry level is sufficient; full configuration/army-building UI and one level per battlefield are not prerequisites. This is a planning-only follow-up to 56ab55b; no asset or runtime implementation was performed.

Revision 33 adds prospective [RQ25 / reproducible start points](unreal-migration-plan.md#115-reproducible-setup-and-game-state-start-points), START01–START10 and E09, supported by the [pinned lifecycle investigation](research/2026-10-19-game-state-bootstrap.md). The development-only selector and fresh-instance reset/relaunch are required future deliveries; they do not exist yet. E09 is NOT RUN. This planning checkpoint is isolated from the frozen E02 checkout and supplies no new execution or acceptance authority.

[BOOT01 Windows evidence](evidence/2026-10-16-boot01.md) records the approved C++
scaffold, probe/final builds, IDE generation and limits. The
[plan/BOOT01 PR was merged](evidence/2026-10-16-bootstrap-publication.md); the
[earlier publication/source record](evidence/2026-10-16-publication-and-e01-source.md)
retains the original access failure and source-only preparation.

Current E01-SLOW120 status is
**BOUNDED_E01_SLOW120_ACCEPTANCE_RECORDED**, recorded by root at
`2026-10-17T06:00:32.004673+00:00` for the narrow diagnostic. Normal run
`20261017T044903Z-b0169768` completed the [revision-7 packet](research/2026-10-16-e01-boundary-packet.md)
on executed source `d1189592a5f99bdee58cea25ae8546e5ee2e3623`. The
[factual result](evidence/2026-10-16-e01-slow120-result.json) and
[execution journal](evidence/2026-10-16-e01-boundary.md) record 87 Python units
in 15.167 seconds, 14 Capture checks including source/runtime/schema checks,
132 unique native successes and two automated evidence checks. The 135 pure
PowerShell controls with 39 stable inputs are separate pre-execution evidence.
Auxiliary privacy inspection and exact-byte promotion preceded Native. All six
real editor-settings before/after observations matched, alongside UBT/Config and
same-run wire checks. Owned execution is stopped.

[CODE r13](research/2026-10-17-e01-slow120-code-review-r13.md) is PASS for candidate
`b97ed5e8c1b2b2a1472aeb7fb70a267e0eab3d37` against cumulative base `0467ee63fe6d4c775f429afae2233d7292787c31`.
Valid [initial REQ r3](research/2026-10-17-e01-slow120-requirements-r3.md) remains BLOCKED on administrative A1/A2;
its separate [administrative supplement](research/2026-10-17-e01-slow120-requirements-r3-administrative-supplement.md) is PASS and closes
those items. Root combined those dispositions for bounded acceptance. The
contaminated [original REQ r2](research/2026-10-17-e01-slow120-requirements-r2.md) is invalid and supplies no
approval. The [public provenance](evidence/2026-10-17-e01-slow120-final-review-provenance.json) records exact identities and
review limits. The supplement is a new context after the initial assessment was
sealed, not a resumed or new blind initial assessment; it received no final CODE
verdict. The later publication commit is a separate metadata overlay outside the
reviewed head.

Full E01/M01/M02, G-RESEARCH/G-IMPLEMENT, the original 30-second budget,
production responsiveness, UE HTTP, rendering, packaging, Linux, Core
#588/#589/#590 and RISK19 remain open or unaccepted. Auxiliary privacy and source-only
records retain their actual isolation limits and do not supply final review roles.

The [E02 architecture packet](research/2026-10-16-e02-world-input-packet.md) is
adopted for bounded source authoring. Its [authority journal](evidence/2026-10-16-e02-world-input.md)
records named writers and pre-execution review/visible-window gates. At revision 20 the bounded
source was authored, its frozen source/tool/asset/plugin-closure review was pending,
and E02 had not executed. Later attempted runs and failures are retained in
canonical plan Section 0.9 and the journal; this isolated planning amendment does
not revise the current frozen E02 execution record.

The [E01 continuation PR](https://github.com/SobolGaming/Warhammer_40k_UI_unreal/pull/2)
was updated and marked ready at `bd801233cc9989e0ae146a3be7b136d26dc73183`.
GitHub observation on 2026-10-17 UTC reported OPEN/MERGEABLE/CLEAN and no checks;
this is not a CI pass. Applicable merge approval has been requested separately. OWN16's
[local checkpoint workflow](unreal-migration-plan.md#02-research-procedure-and-evidence-rules)
adds no publication or merge authority.

## Historical records

- The [byte-exact 030835 schema-2 archive](evidence/2026-10-17-e01-slow120-result-030835-schema2-history.json)
  retains source `c2614b2484a66bd8465b855e59b184d49b2b926d`, packet revision 6,
  87/14/132/2 results and the omitted six-editor-settings criterion as UNVERIFIED.
  Run `044903` has its own observations and does not retroactively pass `030835`.
- The [schema-1 archive](evidence/2026-10-17-e01-slow120-result-schema1-history.json)
  preserves the earlier diagnostic result, including the historical revision-4
  Native/Audit supplement. The journal retains every failed attempt, original
  30-second FAIL/UNKNOWN and all source/guard repair results.
- The [source/helper review history](research/2026-10-16-e01-boundary-review.md),
  [original acceptance audit](research/2026-10-16-e01-boundary-acceptance-audit.md)
  and [preliminary SLOW120 audit](research/2026-10-16-e01-slow120-acceptance-audit.md)
  retain their actual scope and limitations. They did not supply the final
  cumulative OWN15 roles. Detailed rounds 2–12 remain linked from the journal and
  canonical plan; their historical results are unchanged.

The revision-17 pending state and subsequent blocked review attempts are preserved
as dated history in the canonical plan and execution journal.
