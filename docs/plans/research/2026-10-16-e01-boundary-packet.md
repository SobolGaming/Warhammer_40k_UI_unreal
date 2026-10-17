# E01-WIN-BOUNDARY: selected Core boundary proof packet

Date: 2026-10-16. Packet revision: **5; E01-SLOW120 failure-path remediation**.
This packet refines Section 0 RQ03/RQ06/RQ08/RQ15/RQ17/RQ20/RQ23 of the
[canonical plan](../unreal-migration-plan.md). It credits completed BOOT01 and
defines the next bounded Windows proof. It does not claim full E01, M01,
G-RESEARCH, G-IMPLEMENT, rendering, packaging or cross-platform acceptance.

## Revision 5: bounded failure-path repairs and fresh full proof

OWN14's 120-second diagnostic and OWN15's independent reviews remain the
authority. The initial independent code review requested two repairs: retain the
finite command's complete actor-scoped envelope before submission and abandon a
failed/uncertain session before any dependent group runs; enforce the absolute
HTTP deadline on every underlying status/header/body receive and send operation.
Do not infer that a lost receipt means rollback. Mark command completion UNKNOWN
when submission may have reached a transport, retain its original command identity
and authorized scope, and mark subsequent groups BLOCKED without invoking them.
There is no automatic new-ID retry or private reconciliation path.
Retain a credential-free pre-send control ledger for every schema-valid submitted
envelope, including lifecycle/denied/stale lanes, under the run's ignored private
output. It records only the envelope, submitted role and session; it grants no
viewer access and cannot enter public wire fixtures. Full projection snapshots
remain restricted to the bound authorized actor. Explicitly close the acquired
HTTP response and connection on success or failure, including detached HTTP/1.0
response-file ownership.

The permitted implementation paths remain the existing Python harness and unit
tests. Add short-budget loopback transport tests for partial/trickled headers,
informational responses, HTTP/1.0 bodies, chunks and the readiness override, plus a
commit-before-timeout regression proving zero later group callbacks/submissions.
These test-only responders exercise HTTP transport; they are not a new Core host
or live-Core integration evidence. Keep production request/connect/readiness,
body/submission/process limits and credential/path/cleanup guards unchanged.
Local isolated unit verification may run during remediation; review the frozen
changed source before a new Core Capture or native phase.

Changing harness/test bytes invalidates their affected Capture binding. After
review, use a **fresh full Preflight → PrepareRuntime → Capture → Native → Audit
chain**, with a new RunId and verified reuse of the same owned runtime. Do not use
`-CaptureRunId` for this candidate. Revision4's historical supplement remains
immutable evidence for its old source; its unchanged-harness guard must reject
reuse against the repaired source. Preserve all earlier failed and successful
records, including the original30-second FAIL/UNKNOWN. Independently review the
new non-admin original-byte wire set before promotion and Native execution.

The initial requirements auditor independently corroborated the earlier bounded
protocol/native/configuration evidence but lacked the raw process ledgers in its
selected review packet. Supply provenance-bound, credential-free extracts of the
original wrapper and owned-host process records: executable/script identities,
argument arrays, PID, start/exit, exit code, timeout, readiness and shutdown facts.
Record the source path/SHA and selection method; derived extracts are not original
bytes. Include complete phase process inventories. Never expose credentials,
privileged bodies or quarantined generated configuration. Correct the canonical
plan's mixed line endings and bind the new hash. This evidence correction alone
does not require runtime reruns; the source repairs above require the new chain.

Save the initial CHANGES_REQUESTED and BLOCKED reports unchanged. Obtain fresh
independent code and requirements reviews of the repaired final candidate under
OWN15; neither prior runtime success nor auxiliary inspection supplies acceptance.
The additional documentation outputs `2026-10-17-e01-slow120-code-review-rN.md`
and `2026-10-17-e01-slow120-requirements-rN.md` in this research directory preserve
the respective original CLI report bytes for each review round, with invocation/
runtime provenance recorded separately. Copying a report is not a recorder's
independent verdict. Do not supply earlier reports to a new initial assessment.
The root `.gitattributes` may bind only these review report patterns to `-text`
so Git preserves their original bytes, and the canonical plan to `text eol=lf`
so the audited line-ending correction stays consistent. No broader storage or
asset policy change is permitted by this amendment.
The original code-review report includes intentional Markdown two-space hard
breaks. Preserve those bytes with a `whitespace=-blank-at-eol` attribute limited
to that report pattern; implementation and other documentation checks retain
their ordinary whitespace checks.
The result remains a bounded slow-host diagnostic, with production responsiveness,
UE transport, rendering, packaging, Linux and full E01 explicitly unaccepted.

## Revision 4: native-only supplement linked to immutable Capture

OWN14 covers completing this same diagnostic. Run
`20261017T002136Z-8dad7f29` passed Capture (40 Python tests and all14 boundary
cases). Native then built successfully and actually exported132 successful
Automation cases, with zero failed/incomplete cases and child exits0. Its
wrapper result remains **FAIL** because `-LOG=<absolute>` did not create the
expected main log. Do not rewrite that result or infer direct DDC log evidence.

The separately reviewed correction permits a **fresh Native/Audit supplement**
with its own RunId, Preflight and verified-runtime preparation, and optional
`-CaptureRunId 20261017T002136Z-8dad7f29` on Native and Audit only. This mode reads
the successful old Capture as immutable evidence. It creates no replacement
Capture result, launches no Core host and submits no game commands. It is not a
general resume mechanism or a reuse of the stopped mutable session. Retain the
normal full phase chain when this explicit parameter is absent.

The link is restricted to these exact inputs:

| Input | Required SHA256 |
| --- | --- |
| Successful Capture `capture/result.json` | `137CEAAA5A3B85F3A49193525EEB198AEDAF28A113B7F760DA66081D5983E699` |
| Python Capture `report.json` | `C99109764C6708889F2DC365696D03A9FD987465DD6E5D71F108A794223530A0` |
| Independently approved original-byte wire index | `E1658B116E6ED53F84CEE84B3D8A5C1ADFD3DED3FA225DB61D80D21D9953DF0A` |
| Historical revision3 packet recorded by Capture | `D540CF96F8513833C4C708A7104F520554E8244B4502ED7A49D5F695EBE90C76` |
| Historical wrapper recorded by Capture | `F3B2A938A1F314EE5FF6D39B77FADB73CB3D5E1D5E92A562957305759ACBA2DC` |

Validate the linked result/status/run identity,40-unit and14-case PASS counts,
child-report hashes, reviewed index and bodies, exact clean siblings and installed
runtime provenance/tree. The linked candidate contains exactly the historical
wrapper/packet plus the unchanged harness, tests and source manifest. Only the
two explicitly historical wrapper/packet hashes may differ from current files;
the other three must still match. Freeze and independently review the current
packet/wrapper before the new Preflight. Native freezes current C++/descriptor/
target/fixture bytes and rechecks all ordinary toolchain, runtime, ownership,
positive-count and post-execution guards. Audit revalidates the same explicit
Capture link and writes its new report only beneath the new run. It must not
silently fall back to a different input or overwrite an earlier report.

Use `-ABSLOG=<new-run>/native-automation.log` and `-nowrite` for Native. In the
installed UE5.8.3/CL58210709 source, `GenericPlatformOutputDevices.cpp:75–129`
concatenates `LOG=` to ProjectLogDir but clears that prefix for `ABSLOG=`;
`ConfigCacheIni.cpp:1320–1332,2682` suppresses configuration saves for `nowrite`.
Raw source SHA256 respectively:
`AB8D8B6B5145A76AD8420BA6744A4395001E3F281E795162FC7B08345358D2DF`
and `7F4871539400DB4CF9F60CD08D8B3515E3F077D75D255305A2700799FD622DBF`.
These flags do not confine all settings reads or build/cache writes. Inspect the
actual new main log for the owned Local DDC path and reject fallback. Keep all
existing process/body/output bounds and nonempty132-case expectations.

The failed Native attempt created previously absent
`C:/Users/Rabid/AppData/Local/UnrealEngine/5.8/Saved/Config/WindowsEditor/EditorSettings.ini`,
SHA256 `B7E47645C8169E0C05AB6AD43F99F4529D33CD12EF019432FA56BD9F994B464E`.
It records the recent project and empty DDC overrides. Preserve it; do not delete
it to hide the side effect. `EditorEngine.cpp:5861–5893` updates recent projects
and invokes PostEditChange; source SHA256
`89BD1C17FA9DA8463F0039BE8F3E483238C025E726C4274221D6FF51DCD6EF6A`.
The other five observed editor configurations were unchanged. Before the new
Native run, freeze all six current existence/hash observations, including this
new file, and require them unchanged afterward. Preserve existing UBT settings
and verify the ordinary before/after guard too. No global setting edit is an
authorized repair.

The same first Editor startup also added default Android file-server settings
with a generated credential to `Config/DefaultEngine.ini` and created
`Config/DefaultInput.ini`. Their original bytes are quarantined only under the
failed run's ignored `native-generated-config/`; exclude their contents from
public evidence and commits. After verifying those copies, restore only the
attempt's changes: tracked DefaultEngine from HEAD and the previously absent
DefaultInput to absence. Record that recovery without removing failure evidence.
For the supplement, freeze every authored Config INI and its exact file set,
then require all bytes and membership unchanged after execution. `-nowrite`
must be checked in actual execution, rather than assumed from source support.

Example from the repository root, after freezing/reviewing the supplement:

```powershell
$taskNativeRunId = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ') + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
& ./scripts/migration/Invoke-E01BoundaryProof.ps1 -Phase Preflight -RunId $taskNativeRunId
& ./scripts/migration/Invoke-E01BoundaryProof.ps1 -Phase PrepareRuntime -RunId $taskNativeRunId
& ./scripts/migration/Invoke-E01BoundaryProof.ps1 -Phase Native -RunId $taskNativeRunId -CaptureRunId 20261017T002136Z-8dad7f29
& ./scripts/migration/Invoke-E01BoundaryProof.ps1 -Phase Audit -RunId $taskNativeRunId -CaptureRunId 20261017T002136Z-8dad7f29
```

Record actual command/status/counts and explicit linked provenance in the new
result/audit. Prior Native FAIL, original30-second FAIL/UNKNOWN and first
SLOW120 attempt remain unchanged. This supplement does not grant production
transport, rendering, packaging, Linux or broader implementation acceptance.

## Revision 3: separately labelled 120-second diagnostic

**OWN14, 2026-10-16:** the owner instructed, “Please go ahead with the increased
120 diagnostic,” after the coordinator explained the late Core response and
unknown client-visible outcome. This authorizes a fresh **E01-SLOW120** run of
this same public-protocol recipe, with a **120-second total HTTP request budget**
and socket waits capped by its remaining time. Keep the three-second connect cap,
30-second managed-host readiness budget, 30-minute process limits, request/response
size caps, submission limits, credential isolation and owned cleanup unchanged.
No Core edits, new host, private rules path, uncertain-session reuse or automatic
new-ID retry is authorized. Freeze and independently review the affected source
before execution; use a new RunId and verified reuse of the existing runtime.

Revision 2 SHA256 was
`DA568F9BFAE7666C1CECB549B2A05B7930F5341541E25FDB96A6F08CF27B7C1F`.
Run `20261016T231112Z-f8ef82ca` remains **FAIL**, with its missing command receipt
**UNKNOWN**. Its [result JSON](../evidence/2026-10-16-e01-boundary-result.json) and
[NOT_ACCEPTED audit](2026-10-16-e01-boundary-acceptance-audit.md) are immutable
evidence for that earlier candidate. A slow-host success must never be reported
as satisfying the 30-second budget or resolving Core #590's latency concerns.

Label the new Python reports and transport measurements **E01-SLOW120**. Record
new outcomes separately in the execution journal, with any final machine-readable
summary at `docs/plans/evidence/2026-10-16-e01-slow120-result.json` and a renewed
independent audit at
`docs/plans/research/2026-10-16-e01-slow120-acceptance-audit.md`. These two added
documentation outputs extend the bounded file contract below; they do not permit
rewriting old failed results. A successful Capture still needs independent
viewer/privacy approval of the concrete non-admin original-byte wire fixtures
before promotion and Native execution. Native/Audit retain their positive-count,
frozen-source, actual-cache-path and settings-preservation requirements. Render,
UE HTTP, packaging, Linux, RISK19 and robust live Windows exclusivity remain open.

## Revision 2 execution amendments

The original reviewed packet SHA256 was
`B263A3AE8567FBDE8E6CAB0F2A7C3024F1F0D4E7516DEAA875DAECB6681775C0`.
Earlier runs retain that identity and their failures in the
[execution journal](../evidence/2026-10-16-e01-boundary.md). The runtime is now
installed and verified, PR1 is merged, and proposed source files exist. Initial
preparation/future-tense descriptions below describe the experiment design, not
the current execution result; the journal governs actual results.

Run `20261016T230019Z-9a9e3232` passed 34 Python unit tests but its movement group
timed out at the 10-second socket-read limit. The development host later logged
HTTP 200 and a disconnected-client write error; action completion was not proved
by that failed request. Revision 2 raised the read cap to **30 seconds**,
bounded by its **30-second total request deadline** and 3-second
connect cap. It does not retry the uncertain action in the old session, change
Core or relax size/submission limits. Review the changed source before execution.

Independent [source review](2026-10-16-e01-boundary-review.md) also requires the
Python classifier to preserve valid `accepted:false, committed:false` command
outcomes and route their schema separately from error envelopes. Refuse any
`.pyc` found in the owned runtime rather than omit loadable bytecode from its
fingerprint. Preserve the existing zero-bytecode environment and its provenance.
These repairs remain within this packet's protocol/runtime verification scope.

The owner instructed: “open the PR, commit, push, and merge the PR, then continue
with the migration plan.” **OWN13 covers this next bounded E01 continuation after
the requested PR/merge sequence; do not request repeated approval for that recorded
scope.** The coordinator owns publication and the dated authority record in the
canonical plan/AGENTS. Review this packet and its implementation before execution.
The initial GitHub 403 was resolved by the owner's token update and PR1 merged;
that historical access failure is not an execution failure. Initial preparation
of this packet was documentation work; actual script/runtime/host evidence is now
recorded separately in the journal. Do not ask again about settled target, user modes,
topologies, diagnostic policy or deferred Linux hardware. A repository/permission
failure is a publication blocker, not evidence of runtime failure.

## Fixed inputs and actual preparation evidence

| Input | Required identity / meaning |
| --- | --- |
| Authoritative Core | `Warhammer_40k_AI@5f509724da25a2f6ded0c2739a8e7c84bdf59c91`, external Contract **44.3.33**; shared checkout remains reference only |
| Runtime | `warhammer40k-core-v2:runtime-tree-sha256-v1:65fc8414407ae5d6a8ea779c8e737a22733459094db679a160c60f6e2129f96a`, 3,116 resources |
| Legacy comparison | `Warhammer_40k_UI_arcade@5088c1c49dcaff29eb59fb64b3063d30214dde73`; its Core 44.1 pin remains separate; the owner's `Warhammer_40k_UI` means this checkout |
| Unreal | Existing `WarhammerClient.uproject`; BOOT01 UE5.8.3 / CL58210709, Windows x64, MSVC14.44.35229 and SDK10.0.22621.0 |
| Available Python tool | `C:/Users/Rabid/AppData/Roaming/uv/python/cpython-3.14.5-windows-x86_64-none/python.exe`; do not use global Python3.12 |
| Available package tool | `C:/Users/Rabid/.local/bin/uv.exe`; inspected local `sync --help` supports the flags below; no new uv/Python installation |
| Selected host | Existing `Warhammer_40k_AI/scripts/run_phase18m_reference_server.py`; fixed development principal registry, in-memory state, loopback only in this proof |
| Linux | Required target remains configured; all Linux execution **NOT RUN**, owner supplies host later |

The coordinator ran the existing `build_engine_build_identity.py --check` using
the above interpreter with `-I -B`: exit 0 and the exact selected build identity.
The interpreter printed `Failed to find real location`; preserve that advisory
beside the successful result. This verifies the **source** runtime inventory,
not an installed package, native dependency loading or a running HTTP server.

The existing [source fixture manifest](../../../tests/migration/fixtures/5f509724da25a2f6ded0c2739a8e7c84bdf59c91/manifest.json)
records 127 selected source/schema/example/identity files with actual checkout-byte
SHA256 and Git blob identities, the 98 case IDs, and `RuntimeCasesExecuted: 0`.
Core's committed contract manifest declares 234 `file_sha256` members; the 127-file
inventory is not a claim that all 234 canonical hashes or schemas were validated.
Treat it as a frozen source inventory. A missing member, different HEAD, dirty
Core, changed byte hash or changed Git blob fails preflight; do not refresh the
manifest automatically to accept drift. Hash the manifest itself in each run.

Source inspection found no Core `.venv` and no exact Unreal Core environment.
Arcade's `.venv` has a different installed Core provenance and lacks the selected
`jsonschema`, `referencing` and `z3-solver` dependencies. Its environment is not a
reuse candidate and must not be synchronized. The inspected uv wheel cache also
lacks those three: an offline preparation success cannot be promised.

Current additional source hashes are recorded below. `Normalized SHA256` means
UTF-8 source text with CRLF/CR converted to LF, with no other text changes;
execution must also capture raw-byte hashes. Core's contract builder hashes
`read_text(encoding="utf-8").encode("utf-8")`, so distinguish canonical manifest
hashes from checkout bytes. Never change a copied fixture to hide this difference.

| Core path | Normalized SHA256 |
| --- | --- |
| `uv.lock` | `51896fa6800d7bbb5c6dfe08a8c7155640ec71842fafe9d78020b6a36b43e0aa` |
| `pyproject.toml` | `b0fed8cc1f2a25bec5821a96f50e0d7da47ec5e9e8e17df528cd6f69c6d67192` |
| `contracts/manifest.json` | `3723e0bf79cc163c521f6c7636d903aef987237431116cc128539366849d7e66` |
| `src/warhammer40k_core/_engine_build_manifest.json` | `b3f45468657d97f8242ecfb4f49e5fa8becfca8b2f6957721228fb44d04a1f6f` |
| `scripts/run_phase18m_reference_server.py` | `4b20a9e281e1b44f2aaac3d3badc4328592f54a789abc6c7646089ce24a595a7` |

## Bounded file and process scope

The following are the complete proposed authored implementation paths for this
packet, relative to `Warhammer_40k_UI_unreal`. They are a file contract, not a
claim that these files are already present. Stop and revise the packet if the
small proof needs materially broader architecture.

| Paths | Permitted purpose |
| --- | --- |
| `scripts/migration/Invoke-E01BoundaryProof.ps1` | Phase coordinator; path/collision/source guards, bounded owned child processes, environment isolation, sanitized logs and result manifest |
| `scripts/migration/e01_boundary.py` | Exact-source/schema/native-dependency preflight; public-facade/in-process/HTTP scenario driver; JSON Schema validation; viewer-safe evidence capture; no new server implementation |
| `tests/migration/test_e01_boundary.py` | Standard-library `unittest` checks for the proof's envelope/outcome/redaction/evidence code; real protocol fixture cases, no fake engine integration result |
| `Source/WarhammerClient/Private/Migration/CoreBoundaryEvidence.h` and `.cpp` | Small native protocol evidence reader/classifier preserving typed JSON and opaque identities; no gameplay, world, new host or production transport coordinator |
| `Source/WarhammerClient/Private/Tests/CoreBoundaryEvidenceTests.cpp` | Real nonempty Unreal Automation tests under `Warhammer.Migration.E01Boundary`; consume versioned canonical and actual sanitized wire fixtures |
| `Source/WarhammerClient/WarhammerClient.Build.cs` | Add private `Json` dependency only if required by those native tests; retain runtime/editor separation |
| `tests/migration/fixtures/5f509724da25a2f6ded0c2739a8e7c84bdf59c91/manifest.json` | Preserve existing source records; append separately named executed-run references/status only after execution and review; never rewrite old hashes/case IDs to make drift pass |
| Same fixture directory: `contracts/<member>` | Immutable copies of only `contracts/` paths named in the existing 127-entry source inventory, including the selected contract manifest; retain relative paths and original bytes; no old Arcade gzip checkpoints or unlisted contract expansion |
| Same fixture directory: `wire/index.json`, `wire/<case-slug>/<role>.json` | Reviewed credential-free canonical-session wire captures; filename slugs restricted to ASCII letters/digits/underscore/hyphen, original full case IDs retained in the index, no arbitrary supplied path names; index lists every file/hash/role/recipe and whether real HTTP, local or synthetic negative |
| `docs/plans/evidence/2026-10-16-e01-boundary.md` and `2026-10-16-e01-boundary-result.json` | Actual commands, counts, outcomes, identities, review links and limitations after execution |
| `docs/plans/research/2026-10-16-e01-boundary-review.md` and `2026-10-16-e01-boundary-acceptance-audit.md` | Separate frozen-candidate code review and evidence/acceptance audit |

The coordinator owns changes to README, AGENTS, the canonical plan and their
authority/status links. No new plugin/module graph, Content assets, Blueprint,
YAML dependency, renderer, camera, HUD, packaged target, CI/service configuration,
Core/Arcade source/dependency/history or shared environment belongs to this packet.

Generated/install outputs are limited to:

- A fresh `.local/core-44.3.33/` environment and provenance record. Refuse a
  preexisting unverified environment; a subsequent phase may reuse only the same
  verified one with unchanged installed identity/lock/source hashes.
- `.local/core-44.3.33.e01-reservation.json`: atomic first-install ownership and
  interruption record beside that runtime; refuse conflicting reservations and
  preserve failed ownership evidence. It never grants ownership of a preexisting
  unrelated environment.
- `.local/experiments/E01-target/<UTC-yyyyMMddTHHmmssZ>-<8-hex>/`: source archive
  and extracted source copy, package/build/HTTP/native logs, temporary files,
  private role-separated raw responses, shutdown markers, cache, result manifest
  and source/review hashes. Nothing under either sibling is an output.
- Existing ignored Unreal `Binaries/`, `Intermediate/`, `Saved/` and normal
  documented per-user build caches; no global compiler/IDE/UBT configuration edit.
  Export automation reports to the unique run directory.

Resolve absolute paths, ensure every output is inside its intended approved root,
reject reparse points/path traversal, and collision-check before writing. Never
delete a failed run to retry. Cleanup may remove only an explicitly selected
packet-owned path after checking its resolved absolute boundary; no shared cache
purge, environment replacement, engine deletion or recursive sibling operation.

## Proposed phase commands and environment preparation

These are **future commands for the reviewed coordinator**, not checks already
run or a currently available executable suite. The coordinator must implement the
named phase arguments and process bounds before these can be used. Run from the
Unreal repository root; use one unique run ID for the phases and freeze the
candidate's Git base/head or base plus full content hashes before execution.

```powershell
$taskRunId = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ') + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
& ./scripts/migration/Invoke-E01BoundaryProof.ps1 -Phase Preflight -RunId $taskRunId
& ./scripts/migration/Invoke-E01BoundaryProof.ps1 -Phase PrepareRuntime -RunId $taskRunId
& ./scripts/migration/Invoke-E01BoundaryProof.ps1 -Phase Capture -RunId $taskRunId
& ./scripts/migration/Invoke-E01BoundaryProof.ps1 -Phase Native -RunId $taskRunId
& ./scripts/migration/Invoke-E01BoundaryProof.ps1 -Phase Audit -RunId $taskRunId
```

Each phase checks its predecessor's explicit success, source/candidate/fixture
hashes and environment provenance. A failure does not start subsequent phases.
`Audit` gathers and verifies evidence; it does not substitute for independent
human/agent code review or acceptance audit.

Implementation sequencing clarification after PR1 merged: the wrapper's complete
source/inventory checks may establish `SOURCE_INVENTORY_PASS` before the Python
harness is finished. Missing Python preflight is explicitly `NOT_RUN` at that
point; it is mandatory before Capture. This permits independently reviewed runtime
preparation while Python/native code is authored. Freeze wrapper/packet/source
inventory for preparation, Python code for Capture and native code/accepted fixture
outputs for Native; authorized fixture outputs do not silently alter an earlier
authored-source freeze. No phase gains an unexecuted test result from this split.

1. **Preflight:** verify clean selected Core HEAD and frozen inventory; preserve
   Arcade status without changing it; inspect actual Python/uv/UE/compiler paths,
   disk space and any existing runtime ownership. Verify all canonical member
   hashes and case count/IDs, distinguishing actual checkout bytes from Core's
   normalized text hashes. Validate all 234 committed contract hashes read-only;
   copy only the selected inventory's allowed fixtures. Record this as a new check,
   separate from the existing 127-file source inventory. No install, implicit uv
   sync or host launch occurs here.
2. **PrepareRuntime:** use `git -C <Core> archive --format=zip --output=<run>/core-source.zip
   5f509724da25a2f6ded0c2739a8e7c84bdf59c91` to read committed objects into the
   packet. Verify every archive entry stays beneath a fresh `<run>/source/`, reject
   absolute/parent/reparse entries, then extract. Hash archive, extracted lock,
   pyproject, launcher and fixture sources. This copy is disposable install input;
   the shared Core checkout is never a build/output directory.
3. The owned install child receives `UV_PROJECT_ENVIRONMENT=<Unreal>/.local/core-44.3.33`,
   `UV_CACHE_DIR=<run>/cache/uv`, `TEMP`/`TMP=<run>/tmp`,
   `PYTHONDONTWRITEBYTECODE=1`, and `UV_PYTHON_DOWNLOADS=never` in its own environment.
   Clear inherited GitHub credentials and package-index overrides from that child;
   use only the selected public package index and archive metadata. Do not change
   the parent shell, user environment or uv/Python global configuration.
4. The reviewed coordinator runs the following equivalent uv arguments, with
   absolute arguments passed as arguments, never through string-built shell code:

```text
C:/Users/Rabid/.local/bin/uv.exe sync --project <run>/source --locked --no-editable --no-default-groups --python C:/Users/Rabid/AppData/Roaming/uv/python/cpython-3.14.5-windows-x86_64-none/python.exe --no-python-downloads --cache-dir <run>/cache/uv --default-index https://pypi.org/simple --no-config --no-progress
```

This is a **new isolated runtime dependency installation**, including the selected
package/native dependencies from the committed lock; it has not run. It installs
no new Python, compiler, engine, npm package or developer/test dependency group.
Do not use `uv run` against the shared Core, `uv sync` in either sibling, pip
installation into Arcade, or a different Core tip. Network/package unavailability,
unsupported wheel, changed lock or native load failure is a typed preparation
failure; never fall back to a mismatched installed Core or private source import.

5. Verify with `uv pip check --python <runtime>/Scripts/python.exe`; record the
   full installed name/version inventory, lock/archive/source hashes, wheel/build
   provenance and resolved package path. From `<run>/outside-source`, use the
   isolated interpreter `-I -B`, without `PYTHONPATH`, to call
   `warhammer40k_core.build_identity.verified_engine_build_identity()`. Require the
   exact selected ID and 3,116 resources; require `warhammer40k_core.__file__` under
   this environment, not source or Arcade. Import the selected native/runtime
   dependencies, including `orjson`, `msgspec`, `pydantic`, `shapely`, `numpy`,
   `jsonschema`, `referencing` and `z3`; record their versions/load results. Package
   version `0.1.0`, a successful import alone or `pip check` alone cannot pass.
6. **Capture:** run the new harness and its standard-library `unittest` cases with
   that exact interpreter using `-I -B`. The harness takes explicit absolute
   fixture/output/core-launcher paths, not the process working directory. Validate
   JSON Schema references through the frozen local registry, with no network
   schema resolution. Do not execute/import Core tests or fixture generators.
7. **Native:** build once after native source is frozen, using the existing README
   Build.bat command and packet-local log/UBA paths. The equivalent automation
   invocation is below; the suite must first exist and enumerate a positive count.

```text
<UE>/Engine/Build/BatchFiles/Build.bat WarhammerClientEditor Win64 Development -Project=<Unreal>/WarhammerClient.uproject -WaitMutex -NoUBA -UBARootDir=<run>/uba -Log=<run>/native-build.log
<UE>/Engine/Binaries/Win64/UnrealEditor-Cmd.exe <Unreal>/WarhammerClient.uproject -unattended -nop4 -NullRHI -nosplash -ExecCmds="Automation RunTests Warhammer.Migration.E01Boundary" -TestExit="Automation Test Queue Empty" -ReportExportPath=<run>/automation -ABSLOG=<run>/native-automation.log -nowrite -UserDir=<run>/ue-user -DDC=(EnginePak=InstalledEnginePak,Local) -DDC-NoDefaultGraph -LocalDataCachePath=<run>/ddc
```

The installed UE5.8 AutomationCommandline.cpp accepts `RunTests`/`RunTest`
(lines 610-626) and emits `Automation Test Queue Empty` with the performed count
only after its command queue completes (lines 117-125). Use completion-driven
exit; do not append an immediate `Quit`. Require exported case-level results and
nonzero matching test count, not merely exit 0. NullRHI is intentional for this pure
protocol proof and cannot establish rendered behavior. Pass the evidence fixture
root through one documented test argument/config field; no hardcoded sibling
dependency in normal application startup. Native test entry points remain behind
the applicable development automation guard.

Installed UE5.8 `Paths.cpp:1940–1963` supports the supplied user directory, and
`DerivedDataBackends.cpp:698–725` accepts an inline DDC graph with default fallback
suppressed. `BaseEngine.ini:2770–2776,2866–2878` supplies the read-only installed
engine pak and filesystem Local store with `LocalDataCachePath` override. Record
these actual flags and owned cache paths; no default Zen service, shared/cloud
cache or global preference edit is needed for this logical JSON test lane.

## Sessions, ownership and bounded execution

Every install/build/test/owned-host process has a **30-minute maximum** measured
by the coordinator. Use redirected live logs and periodic progress; do not block
communication on one long uninterruptible wait. HTTP defaults for this proof:
3-second connect, at most 120-second socket read capped by remaining time in the
120-second total request deadline for the separately labelled E01-SLOW120 diagnostic,
16 MiB request and 64 MiB response ceilings, one authoritative command in flight,
at most 256 setup/action submissions per scenario and eight event pages of at
most 100 visible events each. Record actual largest bodies and latency; exceeding
these values fails with transport/unknown-outcome evidence and ends that lane.
They are proposed measured proof bounds, not established production budgets.

Launch only the existing selected host, with the verified interpreter:

```text
<runtime>/Scripts/python.exe -I -B C:/SWDev/warhammer/Warhammer_40k_AI/scripts/run_phase18m_reference_server.py --host 127.0.0.1 --port <explicit-positive-port> --shutdown-file <run>/managed-<unique>/shutdown
```

Use an owned hidden-window process with an argument array, current directory
under the run, and bytecode-disabled child environment. Record executable/script
hash, PID/start time and process handle. Select a currently unused positive port,
then fail visibly if binding races; port 0 has no supported endpoint discovery
handshake here. Do not attach to an unexpected responder. Authenticated global
catalog 200 within 30 seconds plus child-alive checks establishes readiness only;
it does not establish exact build identity. Verify selected local provenance
before launch and verify returned session metadata after create. No invented
`/health`, pre-create version or credential provisioning route.

Use separate fresh in-process and HTTP sessions for the matching canonical
scenario. Preserve the same config, recorded choices and random outcomes; record
any unavoidable transport-only normalization explicitly. A second independent
owned host may be used when the same game ID must be replayed without collision.
Never share an active mutable session between agents or parallel writers.

For the attach proof, the supervising coordinator holds the host process and
creates a separate disposable canonical session through an explicit admin context.
An independently invoked attach worker receives only endpoint, supplied session
ID and its scoped player/read-only credential. It neither creates/closes the
session nor acquires the process handle/shutdown path. Prove it can read, submit
its offered action when authorized, disconnect, and leave the host/other session
alive. This proves attach ownership on loopback, not Internet/TLS deployment.
Never test against an unrelated user's service/session by guessing identifiers.

Only the supervisor may close its own disposable sessions with its explicit
administrator context. Normal shutdown writes that host's unique shutdown file,
waits ten seconds, and closes its own handles. On timeout, stop only that owned
process tree after rechecking PID/start identity; no process-name or port-owner
kill. Preserve failed artifacts. Attach exit never signals/stops the host.
Restart one owned development host and prove its old session is lost; report
`SessionLost`, do not recreate the old ID or replay an uncertain command into a
new session. In-memory idempotency is not durable restart recovery.

## Meaningful case matrix and pass/fail

All case IDs below must have explicit actual status, count, command/fixture
hashes and role-scoped artifacts. No empty suite, skipped missing fixture,
schema-only success, stationary/no-op move or synthetic response passes a live
case. Failed/unavailable canonical procedures become exact blockers; never edit
Core, inject decisions, adjust engine state or add a private route to finish.

| Case group | Required proof / failure condition |
| --- | --- |
| `SOURCE-01` | Source and installed identities/127-member inventory agree; 98 canonical case IDs are present once each: 73 top-level finite, one nested finite, 24 parameterized. Catalogue consumption is shape coverage, not 98 live workflows. The source-reposition envelope-only example stays labelled synthetic/envelope-only. |
| `FINITE-01` | Public canonical setup reaches an actual visible finite request. Select only an offered option under its bound player, preserving exact request/option/result/command IDs and expected revision. Match same-build local/HTTP authorized outcomes and refresh after acceptance. No admin gameplay submission, invented option or auto-following hidden next actor. |
| `MOVE-01` | Public setup reaches normal-move proposal. Submit a complete ordered witness for every current placed living physical model in the request's canonical unit; retain current request/spatial/source IDs, pose/facing/Z and sequential order. Choose the canonical one-inch translation candidate and require Core acceptance plus at least one authoritative projected position change. A rejected candidate is evidence, not permission to rewrite legality or call it PASS. Compare local/HTTP action trace and allowed before/after views under identical inputs. |
| `MOVE-02` | Wrong/missing/duplicate witness inventory is uncommitted: preserve visible revision/current request/history evidence and show actual HTTP status/code/message. A well-formed rule-invalid geometric witness must exercise its recorded-invalid branch with committed revision/history and fresh retry request. Then submit a reviewed current complete valid witness successfully. Do not assume every 422 has the same retention semantics. |
| `RETRY-01` | Exact same complete command envelope and credential scope retries byte-equivalently on the same running HTTP host and applies once. Changed payload under same ID conflicts. A simulated lost response after a real committed request retains the envelope and reconciles the same ID; label the injected response loss. Reusing a later journaled outcome never rolls the displayed current revision backward. |
| `STALE-01` | Wrong revision, consumed request and waiting-decision advance produce their actual typed conflict/rejection, with no unauthorized client choice. Refresh authority before corrected intent; never fix by silently changing IDs/revision inside an uncertain retry. |
| `AUTH-01` | Missing/invalid bearer, wrong bound player, forged viewer claim, coach/spectator decision, administrator gameplay decision and live replay-viewer access deny with the shared scoped error policy. Check no hidden request IDs/options/event counts leak in bodies or diagnostics. PlayerA/B, coach, delayed spectator, admin and replay-viewer use distinct explicit contexts. |
| `VIEW-01` | Player/opponent/coach views and event pages obey selected policy; delayed spectator observes its server-provided one-revision delay and scoped cursor. Admin omniscient evidence stays in a separate privileged lane. Replay-viewer live access denies; terminal/closed replay policy uses a separate allowed canonical completion procedure or remains explicitly NOT RUN if unavailable. No forced private terminal-state mutation. |
| `ERROR-01` | Malformed 400, forbidden/auth failures, conflict 409, both 422 wire shapes and unavailable route retain actual status/code/message. The existing support-profile route is not invented. An action accepted before later unsupported advancement remains accepted according to explicit flags. `accepted:true, committed:false`, missing/null/wrong-type fields and malformed JSON fail native classification visibly. |
| `FIDELITY-01` | For the live uncommitted proposal rejection, display exact HTTP status/code/message and: detailed engine reasons were not supplied by this HTTP response. Link Core issue #588. Never report an in-process fine-grained inventory reason as wire-visible, infer a replacement rules reason or fetch privileged details through another route. |
| `SCOPE-01` | Pure client evidence/reducer tests switch viewer/session generation with outstanding responses, reject stale callbacks and invalidate old cursors/drafts; prove no old-view data enters the new scope. This is deterministic client state evidence, not actual UE network scheduling proof. |
| `LIFETIME-01` | Busy port/readiness failure bounded; attach disconnect leaves owned server/other session alive; managed stop affects only owned process; restart shows explicit old-session loss. Credentials/build mismatch never falls back to another principal/runtime. |
| `NATIVE-01` | Nonempty native automation consumes all 98 canonical envelopes and selected actual wire fixtures, preserves opaque string IDs/order/null/JSON types, classifies both 422 shapes and error states, and rejects missing/wrong-type/invalid flag combinations. Numeric identities/revisions outside the reader's exact representable integer range fail explicitly rather than rounding. It does not claim a full Draft 2020-12 validator or implemented UI editors. |

The one-inch movement recipe is sourced from legacy
`tests/test_live_core_smoke.py:_ready_live_core_normal_move_payload` and must be
recreated against selected Core, not executed through Arcade's mismatched
environment. Selected Core recipes/tests to trace before implementing the driver:

- `scripts/external_contract_session_examples.py:phase18e_session_examples` and
  `adapters/setup_smoke.py:canonical_setup_prebattle_smoke_config` produce the
  committed `contracts/examples/sessions/session-create.json` from real state.
- `adapters/contracts.py:AdapterGameSession` and
  `adapters/server.py:AdapterGameServer.handle` supply local facade/public command
  paths. Local `GameConfig.from_payload` may decode the same frozen creation config;
  only public facade start/advance/submit/view/history APIs are allowed. HTTP
  commands use `/sessions/{id}/commands`, with separate admin lifecycle/player
  decision credentials. No direct lifecycle/queue/decision-controller access.
- `tests/shared/category_migration/phase18f_session_commands.py:`
  `_advance_to_movement_selection`, `_deployment_payload_from_proposal` and
  `_invalid_distance_witness`; read as recipes, do not import private test helpers.
- `tests/infrastructure/adapters/unit/test_session_commands.py:`
  `test_phase18f_duplicate_http_commands_are_byte_equivalent_after_reconnect`,
  `test_phase18f_well_formed_illegal_proposal_is_uncommitted_and_retryable`,
  `test_phase18f_recorded_invalid_retry_is_atomically_journaled`.
- `tests/integration/test_movement_witness_membership.py:`
  `test_native_wrong_witness_inventory_is_atomic_with_legal_retry_and_continuation`
  and `test_native_rule_invalid_geometry_still_records_attempt_and_emits_fresh_retry`.
- `tests/unit/test_phase18g_18h_session_security.py:`
  `test_phase18h_derives_live_visibility_and_delay_from_server_owned_roles`,
  `test_phase18h_enforces_mutation_replay_support_and_viewer_claim_policies`,
  `test_phase18h_auth_failures_share_one_redacted_shape_and_ignore_legacy_header`,
  `test_phase18h_event_redaction_hides_secret_counts_and_uses_viewer_sequences`,
  `test_phase18h_idempotent_retry_requires_exact_current_authorization_context`.

These are immutable references to Core `5f509724...`; they are source recipes,
not a claim that this packet has run its tests. Core's TypeScript conformance
client is additional source evidence only: it has no installed node_modules here
and explicitly omits coach, delayed spectator and live rejected unsupported
coverage. Do not run npm install/test or reproduce its implicit uv launch.

## Evidence, redaction, review and closure

The harness imports public default development credential **constant names** only
in its private test process. Never persist token values, token hashes,
Authorization headers, complete environment dumps, credential-bearing command
lines/URLs or workspace GitHub credentials. Role labels and a credential-scope
generation ID are enough for traces. Secret scan/redaction precedes every log
export, hash manifest and proposed commit. A scanner rejection quarantines output;
it does not replace the fact with a successful redaction claim.

Separate playerA/playerB/coach/delayed/admin/replay output directories and index
permissions. A permitted diagnostic comparison may privately read an admin
baseline, but the public/player fixture contains only authorized derived
assertions, not the omniscient body or hidden counts. Review all committed wire
fixtures for viewer safety; raw session/cursor/private outputs remain ignored.
Canonical published opaque IDs/hashes can remain intact; do not recompute Core
projection/spatial/catalog hashes after reserialization or anonymize authoritative
IDs while claiming byte-equivalent replay. Mark local/synthetic error fixtures
distinctly from actual HTTP captures.

The result manifest records UTC/run ID; approved phase/candidate and script
hashes; exact source/installed/runtime/schema/fixture/lock identities; interpreter,
uv, engine/compiler/SDK; process ownership/start/exit/timeout; sanitized actual
commands; discovered/executed/passed/failed/skipped case counts; each expected and
actual outcome; role/viewer/session scope; measured body/latency bounds; artifact
hashes and redaction disposition; before/after sibling cleanliness; and independent
code-review/acceptance-audit frozen manifests. Preserve failed attempts append-only.

Freeze authored sources and accepted fixture candidates before separate code
review; resolve actionable findings. After execution, freeze results and obtain a
separate acceptance audit mapping each required row to actual evidence. Any source
change invalidates the affected code review/run rather than silently inheriting
the previous PASS. A blocked case is never counted as passed.

Report phase-specific statuses: `SOURCE_INVENTORY_PASS`, `INSTALLED_RUNTIME_PASS`,
`LOCAL_HTTP_BOUNDARY_PASS`, `NATIVE_FIXTURE_PASS`, or exact `FAIL/BLOCKED/NOT_RUN`.
E01-WIN-BOUNDARY passes only when its required meaningful finite/movement,
error/retry/auth/viewer/process rows and independent reviews have evidence; an
unavailable full terminal replay case stays explicitly outside this subset and
cannot close full E01. Source-only checks do not establish installed/native/HTTP
results. Native fixture tests do not establish UE HTTP callbacks, UI input,
world rendering, packaged loading, remote TLS/security or real role controls.
Python HTTP success does not establish a functioning native UE transport.

The next architecture lane must still prove actual Unreal transport/scheduling,
E02 3D transforms/picking and E04 HUD/parser feasibility before broad dependent
implementation. E08 keeps the remaining per-variant real captures and full
behavioral parity; consuming all 98 envelopes does not close them. E03A/E03B,
standalone/offline delivery, Linux, durable recovery, performance and final release
remain separate acceptance work. The existing development host's limits and
[Core issue #588](https://github.com/SobolGaming/Warhammer_40k_AI/issues/588) remain
visible regardless of this subset's eventual result.
