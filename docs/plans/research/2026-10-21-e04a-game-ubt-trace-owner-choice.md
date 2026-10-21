# Prospective A1G UBT trace output exception: owner choice

UNADOPTED / SOURCE-ONLY / NO EXECUTION AUTHORITY. This is a reviewable choice for
one future repaired A1G packet, after both current final reviews and preservation
close, the finding/failure checkpoint is saved, and its OWN18 remote backup is
verified. It edits no canonical norm/source, installs or patches nothing and
starts no process. The old nine-phase records and CODE finding remain unchanged;
no retrospective ownership waiver or A1G acceptance follows.

## Source finding and exact normal behavior

The closed run 20261021T152810Z-45e572ca recorded writes to
C:\Users\Rabid\AppData\Local\UnrealBuildTool\Trace.uba in
logs/a1g-editor-prerequisite.stdout.log:43 and
logs/a1g-game-build.stdout.log:49. These are outside R despite -NoUBA and an owned
-UBARootDir. The current norm's all-output ownership criterion is not satisfied.

Installed UBT creates the global trace before its normal argument/configuration
parsing. Its installed-engine saved root is the Windows known LocalApplicationData
folder. No supported owned-path argument is demonstrated by this pinned source.
-UBATraceOutputFile is declared but unused by this path. -Session= skips the global
file choice, but an actual UBA build executor rejects a null global trace path.
-NoUBA disables detouring; the local executor remains UBA. Do not present any of
these flags as an owned global-trace selector.

Log.BackupLogFile runs before normal global options are applied. The inspected
static defaults are BackupLogFiles=true and LogFileBackupCount=10. Its behavior:

1. If Trace.uba does not exist, return without pruning backups.
2. If it exists, enumerate this directory's names matching the source regex below,
   sort descending by filename, retain the newest nine matches and delete the rest.
3. Form Trace-backup-yyyy.MM.dd-HH.mm.ss.uba using the existing Trace.uba file's
   UTC creation time, not the current invocation time. Advance that candidate time
   by one second until its filename is unused.
4. Move Trace.uba to that unused name through File.Move(source,target), without
   overwrite. The new trace is later written to Trace.uba via native Trace_Destroy
   on disposal. Exact native partial-write/overwrite/error semantics are not
   established by the distributed managed-source inspection.

The pruning regex is unanchored and its extension dot is not escaped:

    Trace-backup-\d\d\d\d\.\d\d\.\d\d-\d\d\.\d\d\.\d\d.uba

Consequently an approximate glob alone does not bound every potential deletion.
The proposed future wrapper must refuse before launching UBT if any basename
matching that actual source predicate falls outside the exact anchored allowed
family below. Normal option flags controlling later log backups are not proof of
control over this earlier trace backup.

## Recommended owner option A: finite explicit normal-output exception

Proposed replacement for the single all-outputs-under-R rule:

> Own all outputs under R except the explicitly authorized normal per-user UBT
> trace and exact backup family below, solely for the two sequential owned UBT
> roots EditorPrerequisiteBuild and GameBuild in one freshly bound repaired run.
> Observe and retain the complete finite exception state; all other output,
> source, settings and process restrictions remain unchanged.

Exact external directory for this workstation:

    C:\Users\Rabid\AppData\Local\UnrealBuildTool

Exact permitted current trace path:

    C:\Users\Rabid\AppData\Local\UnrealBuildTool\Trace.uba

Exact generated backup path family, directly inside that directory:

    C:\Users\Rabid\AppData\Local\UnrealBuildTool\Trace-backup-YYYY.MM.DD-HH.mm.ss.uba

Allowed backup basename predicate (case-sensitive, whole name):

    ^Trace-backup-\d{4}\.\d{2}\.\d{2}-\d{2}\.\d{2}\.\d{2}\.uba$

This permits normal creation/replacement of Trace.uba, moving its preceding bytes
into a generated backup, and normal pruning of older matching backups. Existing
bytes must first be recoverable in the owned run. It is an explicit external
output exception, not an owned-path claim. Directory creation is permitted only
for this exact UnrealBuildTool directory if absent; its known parent must already
exist and neither it nor its ancestry may be redirected/reparse paths.

Required future wrapper/evidence additions, not implemented by this proposal:

- Before any UBT invocation, derive the actual normal Windows known-folder route
  without changing it and require equality with the exact directory above. Keep
  UBT_EXTRA_ARGS empty and all current argv/tool/target guards. Do not add a
  fictional trace selector, spoof LocalAppData/UserDir/IsBuildMachine, change
  installed-engine detection, patch the installed engine or alter user settings.
- At Preflight, before each of the two UBT roots, after each root's complete
  supervised closure, and at final Audit, record trace existence and matching
  backup membership, bytes, SHA256 and available UTC creation/last-write times.
  Before either root, copy every present eligible file into a fresh phase-specific
  owned recovery directory under R and verify the copy's size/hash before launch.
  Retain explicit absence. Enumerate directory names nonrecursively only to
  evaluate the exact pruning predicate and reject out-of-family matches.
- Proposed finite capture caps are 32 eligible files, 16 MiB per file and 64 MiB
  aggregate at each observation. Check prelaunch caps before starting UBT. A cap
  violation, unavailable read, reparse/escape, unstable copy or ambiguous state
  refuses the phase; postlaunch evidence failure preserves existing recovery
  copies and reports failure rather than claiming preservation. These are capture
  bounds, not a kernel disk quota or proof that a writer cannot exceed them.
- Observe immediately before launch that captured live identities still match.
  Run the roots sequentially with no concurrent intentional desktop UBT build;
  record that exclusivity assumption and actual finite process/window evidence.
  Do not claim a filesystem lock or universal writer attribution. Unexplained
  family deltas fail closed; inspect the normal trace destination emitted by each
  child, not command intent alone.
- Retain after-state owned copies and explicit created/changed/moved/deleted names
  with correspondence to preceding bytes. Verify that deleted/replaced prior
  family bytes remain in owned recovery copies. During other phases require this
  exception state unchanged unless a later separately reviewed packet explicitly
  covers a demonstrated additional normal writer. Original nine settings roles,
  Game settings, sources, Config, fixtures and all existing output checks retain
  their previous comparison rules.
- Leave the normal trace outputs visible in the after-state; do not silently
  restore/delete global files or erase the documented exception. Recovery means
  retained verified bytes, not unchanged live filenames or automatic restoration.
  Any restoration requires a separate guarded decision based on current bytes.
- Trace files are opaque identity/recovery evidence by default. Do not grant
  unrelated historical trace bodies to reviewers or commit them. Ordinary finite
  observation supplies no OWN17 certificate or total UserDir isolation claim.

Owner approval of option A would select this explicit limited output policy only.
It would still require canonical repair, fresh source/norm/input binding, affected
SOURCE review, a fresh run, separate ordered phase GOs and final independent CODE
plus different REQ. It is not permission to reuse the closed run or launch now.

## Alternative owner option B: retain all outputs under R

Keep the current all-output rule. Remain blocked on the installed UBT trace route
until a separately authorized owned patched UBT artifact or another demonstrated
supported owned route is designed, reviewed and bound. An early global trace-path
override requires a real tool/source/ABI/provenance change; adding the declared
but unused -UBATraceOutputFile flag does not supply it. This option authorizes no
installed-engine modification, new dependency build or broader tool maintenance.

## Minimal future source scope

Wrapper touchpoints: scripts/migration/Invoke-E04A1GProfileProof.ps1 Ubt-Arguments
894-896, Get-A1GUbtActionLog 1152-1165, the two build-phase branches1789-1799, and
existing Preflight/Audit/preservation publication. Add only the finite trace
observation/recovery data and checks described above. Update the clean A1G norm's
ownership/preservation clauses and bind these direct installed-source ranges.
No target/C++/YAML behavior change is implied.

All installed source paths below start
C:/Program Files/Epic Games/UE_5.8/Engine/Source/Programs/:

| Source | Exact useful physical ranges | Bytes | SHA256 |
| --- | --- | ---: | --- |
| UnrealBuildTool/UnrealBuildTool.cs |206-249,351-352|22825|BCECEF684328BEB5DF5C20A719A98DF5ED349C3CD420696CF816A8786EA2BE72|
| Shared/EpicGames.Build/Unreal.cs |193-214,485-510|25383|C8F5C61A011231A4E224ADF22D44B0F9DD35B161B7C77E75EBE3A94312A92D48|
| UnrealBuildTool/Executors/ExecutorFactory.cs |23-59|4831|5E9A74B619529F0764550ED66667F0859416E586F76DC51F03AD7CD0B443265D|
| UnrealBuildTool/Executors/UnrealBuildAccelerator/UBAExecutor.cs |312-316,366-371|52038|CFC02E8DA06174BA9CE67922B2D52493E704D67B2D47A9501A7BBAE8B2C9A3EB|
| UnrealBuildTool/Executors/UnrealBuildAccelerator/UnrealBuildAcceleratorConfig.cs |173-178,216-221|18957|F8791D5120783C3D2C84078AD7CA7861EAA1584C1238A5900D481EBE2E31566E|
| Shared/EpicGames.Core/Logging/Log.cs |169-180,230-275|49521|D8AD2C9316814796E57AD5505099032AABCB6628F8AB3E7D52453612E460E4B4|
| Shared/EpicGames.Core/FileReference.cs |361-374|44684|F6D7884445F84EBDB51503A217D6DB1122BF65AB3CE49DAA1DB5173D8CF92404|
| Shared/EpicGames.UBA/Impl/TraceImpl.cs |42-58,71-86|3273|6815502398BCAB4FAB52D38425B27E7AE54EF9F200A94EB4024FC95C5E0A3B16|

These bind inspected installed source, not independently established correspondence
between that source and installed binaries. Actual closed stdout supplies the
observed external path. This work read only the named technical evidence and
primary sources; it did not inspect the ongoing FINAL_REQ directory/report or
invoke application, review, helper, native, build, test or network execution.
