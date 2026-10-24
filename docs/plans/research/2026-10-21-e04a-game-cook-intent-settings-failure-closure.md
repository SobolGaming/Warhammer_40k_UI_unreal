# E04-A1G Cook intent and settings preservation failure

Fresh SOURCE for a00c1420b239c800600122f172e8a384ecb9bb0b is PASS and root-admitted.
Preflight, DependencyConfigure, DependencyBuild, EditorPrerequisiteBuild and
GameBuild passed and were admitted for run 20261021T134112Z-677c4ca5. Preserve
those results, the [SOURCE prerequisite](2026-10-21-e04a-game-source-prerequisite-a00c142.md)
and [raw PASS](2026-10-21-e04a-game-source-review-a00c142.md).

Cook failed with status FAIL_PRESERVATION_OR_RETAINED_OUTPUT_CAP. Primary error
is A1G_UNEXPECTED_RESOLVED_UAT_INTENT: SkipBuildClient; post-phase preservation
also reports E02_SETTINGS_CHANGED. The normal copied UAT log records
SkipBuildClient=False, BUILD SUCCESSFUL and AutomationTool ExitCode=0. Native
UAT PID 36700 closed exit 0 in 304.2745012 seconds with confirmed cleanup,
no timeout and final job accounting of 70 total/zero active. Native process
success does not pass the wrapper's Cook gate. Outer PowerShell PID 13852
closed exit 1, without timeout/kill and with full stream copies completed.
No Cook completion exists. Retain partial outputs.

The editor-local-versioned EditorSettings.ini hash changed from
b7e47645c8169e0c05ab6ad43f99f4529d33cd12ef019432fa56bd9f994b464e to
8c760872a0475763f55e95d7104eb153361b4ebe4d6593e2ad6d0eb186064aa6.
This is an observed preservation failure. Exclusive writer attribution remains
unproved. Raw before-content bytes were not captured. An ignored recovery
candidate was later derived by deleting one unique this-run recent-project row;
its 461 bytes match the recorded before hash. It was not root-adopted or restored
at this failure checkpoint; the original preservation failure remains.

Independent current observations also found staged project/Config/DefaultEngine.ini
changed from 375 to 775 bytes. Generated editor settings were added; raw content
and generated token are excluded from public records and review packets.

The [failure receipt](../evidence/2026-10-21-e04a-game-cook-intent-settings-failure.json)
binds the raw artifacts and admissions. Root closed the run at
2026-10-21T14:14:32.3838876Z. Of 84 independent current states, 82 matched and
two changed. These do not fill the wrapper's null source/stage/fixtures/gameSettings
after fields; only its nine settings-after observations exist. Root rehashed 157
prior retained descriptor occurrences and ten predecessor descriptors. Retained
Cook payload is 1048 files/206699879 bytes by count/size only, not content validation.
Stage payload is absent. There is no all-matched preservation claim.

Stage, Native and Audit are NOT_RUN. Actual Game attempts/evaluated checks are
zero; two parser calls/52 checks remain planned. The run has no retry or successor
GO; no repair is adopted. Checkpoint/push/gh-verify OWN18 failure backup before
repair, then repaired-source backup, fresh bindings and affected SOURCE before
a new ordered phase chain. Final CODE and different REQ remain open.

Bounded A1E acceptance and historical evidence remain unchanged. OWN17 stays
deferred/unproven, visible authority zero, Linux UNTESTED and perpetual private
source/API review consent unchanged. This record establishes no Cook, runtime
or migration acceptance.
