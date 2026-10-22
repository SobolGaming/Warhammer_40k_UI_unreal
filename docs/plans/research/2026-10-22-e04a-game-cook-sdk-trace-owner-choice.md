# Prospective Cook SDK-validation UBT trace exception: owner choice

UNADOPTED / SOURCE-ONLY / NO EXECUTION AUTHORITY. This draft concerns one future
fresh repaired A1G proof, after the closed failure checkpoint and its exact OWN18
remote backup. It changes no canonical source/norm, launches nothing, and does
not waive the failed Cook or transfer its prior phase/SOURCE authority.

## Finding and primary call chain

The closed run20261022T192551Z-711fa6f6 executed source
a8980572ca05e9b1a32880915e7b8cbf5cb0d337. Its Cook UAT child completed exit0, but
wrapper Cook failed because the global trace family changed in a phase required
to leave that family unchanged. This was not an authorized third writer. Keep
that failure and its actual before/after/recovery evidence; do not rewrite it as
an accepted exception or reconstruct missing historical observations.

The granted closed Cook stdout is C:\SWDev\warhammer\Warhammer_40k_UI_unreal\.local\experiments\E04A1G\20261022T192551Z-711fa6f6\logs\a1g-cook.stdout.log
(119440 bytes, SHA256 68537D29B21D0DDEF66EA352A54196ABBEEAA311E094C6A95D8AB694092F5C83). It records:

- Line13: the ordinary UnrealEditor-Cmd.exe -run=Cook child, including the exact
  owned project, cooker options and owned user/log paths.
- Line42, inside that Editor child, emits:

    Running UnrealBuildTool: dotnet "..\..\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.dll" -Mode=ValidatePlatforms -OutputSDKs  -AllPlatforms  -project="C:/SWDev/warhammer/Warhammer_40k_UI_unreal/.local/experiments/E04A1G/20261022T192551Z-711fa6f6/project/WarhammerClient.uproject" -log="C:/SWDev/warhammer/Warhammer_40k_UI_unreal/.local/experiments/E04A1G/20261022T192551Z-711fa6f6/ue-user/cook/Saved/Logs/AutoSDKInfo.txt" -verbose -timestamps

- Line51 emits ##PlatformValidate: Win64 VALID 10.0.22621.0.
- Line61 emits:

    Trace written to file C:\Users\Rabid\AppData\Local\UnrealBuildTool\Trace.uba with size 319b

319b is the size reported in that closed log, not a newly read trace body or an
independently observed file-size assertion. No .uba body was read for this note.

This launcher is in native TargetPlatform initialization, rather than an
unconditional AutomationTool SDK child. TargetPlatformManagerModule.cpp366-408
constructs -Mode=ValidatePlatforms -OutputSDKs, chooses -AllPlatforms for the
startup NAME_None call, appends project and the owned ProjectLogDir/AutoSDKInfo.txt
log, and launches through DesktopPlatform when not Multiprocess and when SDK
setup is needed. FileSystemReady registration calls it early. SDKSetup492-554
waits for the child, reads its ##PlatformValidate results into PlatformsSetup,
collects its return code and closes its handle. Initialize611-624 calls SDKSetup;
ValidateSDK1336-1344 consumes the resulting per-platform Boolean.

When AutoSDK is disabled, NeedsToRunSetupPlatformsUBT220-238 deliberately invokes
UBT to establish SDK validity for an Editor target. UBT ValidatePlatformsMode
registers validation platforms, checks HasRequiredSDKsInstalled, emits VALID/
INVALID plus requested SDK versions and returns0. Thus child exit0 alone does
not prove Win64 SDK validity. UBT startup206-249 still selects/backs up and opens
its ordinary global Trace.uba before global/mode parsing, even for this mode.
The auxiliary mode performs no target build; it still owns a normal trace write.

## Supported avoidance routes do not preserve this proof

No existing exact CLI flag was established that suppresses only this auxiliary
process while retaining the ordinary single-process Editor Cook platform checks.

- UE_SKIP_UBT_SDK_SETUP=1 directly returns false at220-227. With AutoSDK disabled,
  SDKSetup573-579 then explicitly assumes all platforms valid. This weakens the
  validation being preserved and is not an acceptable environment workaround.
- -Multiprocess is a direct launch suppression guard at390, not a dedicated
  keep-validation/no-trace option. With normal AutoSDK disabled it removes the
  child which populates PlatformsSetup; ValidateSDK1336-1344 defaults to false
  for missing entries. Recasting the ordinary cooker as a multiprocess path is
  not demonstrated to preserve the required route and is not proposed.
- UAT's existing -NoAutoSDK is parsed globally and calls
  PlatformExports.PreventAutoSDKSwitching. That changes managed UBT AutoSDK
  switching policy; it does not select a native no-launch path. The native
  launcher has no NoAutoSDK command-line guard and ordinarily invokes validation
  precisely when AutoSDK is disabled. It does not solve this trace write.
- UAT -skipbuild does not suppress Editor startup. CookCommand332-347 still starts
  the blocking ordinary Cook commandlet. -skipcook would remove required cooking.
  No engine patch, Program target substitution, fake SDK root/cache, -Session
  spoof or unsupported global trace-selector flag is proposed.

## Stage-specific boundary

The current Stage route is BuildCookRun -skipbuild -skipcook -stage with the
ordinary loose-copy settings and no RunChunkAssigner. BuildCookRun251-266 calls
Build, Cook and staging in order; BuildProjectCommand60-67 returns when Build is
false, and CookCommand289-292 returns on SkipCook before starting the Editor.
CopyBuildToStagingDirectory6990-7035 invokes its optional pre-staging commandlet
only when RunChunkAssigner is true, then follows normal staging manifest/copy
work. BuildCookRun48-59 derives that option from the absent explicit argument.
Windows has no PreStage override in the inspected Win scripts; the base
Platform.cs398-402 implementation is empty. UAT's PlatformExports.Initialize
performs XML/platform registration in-process, not this native Editor startup.

These direct inspected routes do not establish a normal ValidatePlatforms writer
for the currently bound Stage path. Current Stage was not reached after the Cook
failure. This is a prospective source finding, not an executed Stage guarantee or
universal proof that every possible staging branch launches no process. Keep
Stage's trace state unchanged/fail-closed; authorize no Stage writer by inference.

## Recommended prospective scope: one normal Cook descendant

Extend the already approved exact global Trace.uba/anchored backup-family policy
only to ONE normal ValidatePlatforms -OutputSDKs -AllPlatforms UBT descendant of
the ordinary UnrealEditor-Cmd Cook child, within the one supervised Cook UAT root
of one freshly bound repaired run. Keep the two direct build UBT writers covered
by their existing policy. Add no Stage/Native/other-phase writer, SDK installation,
settings mutation, binary/source patch, extra root or visible-window authority.

The exact directory remains C:\Users\Rabid\AppData\Local\UnrealBuildTool.
The only live files remain Trace.uba and case-sensitive whole-name backups:

    ^Trace-backup-\d{4}\.\d{2}\.\d{2}-\d{2}\.\d{2}\.\d{2}\.uba$

Retain the source-regex out-of-family/case-alias/reparse refusal,32-file,
16MiB-per-file and64MiB-total snapshot caps, full before/after identities, fresh
verified owned copies and source-to-copy mapping, ordinary move/pruning delta,
replaced/deleted prior-byte recoverability, phase continuity and final Audit joins.
Capture/recheck immediately before the supervised Cook UAT root, and capture the
after-state only after complete owned-root/job closure. This wrapper does not
directly launch the nested UBT child: do not describe the pre-UAT observation as
an atomic or immediate pre-descendant observation. Preserve the finite timing and
no-concurrent-intentional-UBT assumption and refuse unexplained changes.

Require exactly one retained emitted ValidatePlatforms invocation with the bound
project and owned cook/Saved/Logs/AutoSDKInfo.txt destination, expected mode/options,
exact normal tool route and one normal closed trace-destination line matching the
authorized global path. Retain and compare the owned SDK log, Win64 VALID SDK
observation, Cook stdout and complete UAT process/job evidence. Missing, ambiguous,
additional or mismatched command/trace observations fail closed. These emitted
command lines are inert evidence; they do not become commands to execute.

Record the root UAT PID/process receipt, supervised job closure and absence of
remaining job members separately from the source/log-supported descendant route.
Existing job accounting does not attest the actual UBT writer PID or supply a
complete descendant command inventory. Do not invent that attribution or equate
closed-root success with SDK validity, ownership or global exclusivity. Any new
PID instrumentation would require separately bounded source/evidence work.

Preserve normal environment selectors without spoofing them. In particular,
Automation.cs73-84 coerces any inherited nonzero integer IsBuildMachine value to1
in UAT's own child environment, unlike direct UBT's exact trimmed1 test. The
future guard must refuse that active UAT build-machine condition (and -BuildMachine)
so the descendant retains the approved normal per-user trace route. Refuse an
active UE_SKIP_UBT_SDK_SETUP bypass and worker-mode substitution rather than
setting variables or weakening checks. Bind the installed marker/tool/source
identities. Leave the live global after-state intact; no implicit restore/delete.
Trace/recovery bodies remain opaque unless separately screened and granted.

An approved extension would select this finite prospective output policy only.
It would still need canonical norm/source repair, exact repaired checkpoint and
verified backup, fresh bindings and affected independent SOURCE, new ordered
phase GOs and eventual final CODE plus a different REQ. No old authority transfers.
The old failed Cook remains failed. OWN17 stays deferred/unproven; no universal
preservation/write-absence, native trace-error semantics, rendering/Linux or wider
profile/Core-play/migration acceptance follows.

## Draft owner decision question — not yet sent or authorized

Do you approve extending the existing finite UBT Trace.uba/backup exception to
one normal SDK-validation UBT descendant within Cook for one fresh repaired A1G
proof, with the same32/16MiB/64MiB caps, verified owned recovery, normal deltas,
unique emitted command/trace/Win64 SDK evidence and closed UAT-job qualifications,
while Stage and all other phases remain unchanged and no validation bypass is used?

The alternative is to keep the current two-writer scope and remain blocked on
ordinary Cook; no bypass, engine patch or new execution is implied.

## Exact installed primary sources inspected

All relative paths below begin C:/Program Files/Epic Games/UE_5.8/Engine/Source/.
Whole-file identities bind these installed source files; the physical ranges are
the direct useful source routes. Inspected source alone does not independently
establish correspondence to installed binary bytes. The closed stdout supplies
actual observed command/trace-path evidence. No prospective PASS is claimed.

| Installed source | Physical ranges | Bytes | SHA256 |
| --- | --- | ---: | --- |
| Developer/TargetPlatform/Private/TargetPlatformManagerModule.cpp | 54-74,220-245,366-410,492-554,573-581,611-624,1336-1344,1496-1502 | 61188 | E86827925AECB8ED2250F5D7AB655269ED7FE6A83D6691B244FA36FAAD5A4E17 |
| Programs/UnrealBuildTool/Modes/ValidatePlatformsMode.cs | 14-36,44-92 | 3094 | A520CE5015EB291F6A633B7BEB4018BCBA00AD19519F29A502D831F74657E1C7 |
| Programs/UnrealBuildTool/UnrealBuildTool.cs | 206-249 | 22825 | BCECEF684328BEB5DF5C20A719A98DF5ED349C3CD420696CF816A8786EA2BE72 |
| Programs/AutomationTool/Scripts/BuildCookRun.Automation.cs | 48-59,251-266 | 11243 | 4B937241960BB31887399BA1821D2D43CDD3A354F2D548B42D0133554742C582 |
| Programs/AutomationTool/Scripts/BuildProjectCommand.Automation.cs | 60-67 | 11464 | 046A2BA4C7A8F20C3528855766EDCA47839A3A42451D61CB395BFCC6BB089BAD |
| Programs/AutomationTool/Scripts/CookCommand.Automation.cs | 275-298,332-347 | 28237 | A0C8AD9C04C1AA3C3AD27A81F5D7E0614A40D5DF1A15608719C20F87BE22E948 |
| Programs/AutomationTool/Scripts/CopyBuildToStagingDirectory.Automation.cs | 6990-7035 | 303725 | F4BE917D19E160D2DCF6A24EF9F460D04AC4692A82081617880DC83383FDB4FA |
| Programs/AutomationTool/AutomationUtils/Automation.cs | 73-84,111-133,454-460 | 19173 | 9A1DE969D4D0703B48C6DAD17CFD0E4FA19FF881978F0EB60BFFEBC9A5A962B9 |
| Programs/UnrealBuildTool/System/PlatformExports.cs | 132-159 | 5912 | 343BCB22ACC383CB48691AA4D407A9E83431B4323ABAEE59632B7CAFD3A04413 |
| Programs/AutomationTool/AutomationUtils/Platform.cs | 398-402 | 35248 | F90A31FDE3A396FE7AF084F16B6A1B8FFBB506F0434EA0EE2AE8637397775397 |
| Programs/AutomationTool/Program.cs | 286-311 | 21791 | 49CB1EB7C7CFDCC72953019F3C97E85D63903F78F5880F0E4DADE5004537E94D |

This read-only diagnosis wrote only this new ignored proposal directory. It made
no canonical/candidate edits, invoked no captured/helper/native/build/review command,
and created no scope, phase, review, acceptance, publication or merge authority.
