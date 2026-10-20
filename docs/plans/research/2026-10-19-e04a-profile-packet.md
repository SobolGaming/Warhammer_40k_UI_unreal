# E04-A1E: Editor module and raw-document proof

Source preparation began on 2026-10-19 and continued on 2026-10-20 UTC under
OWN13. Source, build, test and acceptance states are separate. This packet does
not release a build or native process. An exact candidate freeze, affected SOURCE
review and recorded phase authority must precede execution.

The experiment addresses RQ11/RQ23, RISK09 and the narrow E04 subset permitted
by the migration plan. Its exact subset is
`E04-A1E_EDITOR_MODULE_RAW_DOCUMENT_PROOF`. It evaluates Win64 module loading,
the static yaml-cpp compiler/CRT boundary, typed `noexcept` results, owned values
and basic raw parsing in the actual exception-enabled Editor environment.
Full E04/M02, G-RESEARCH and G-IMPLEMENT remain open. A2 retains all 727 proposed
legacy compatibility scenarios; shared HUD/preview/render/input proof belongs
to E04-B. No A1 result automatically removes an A2 obligation.

The original unexecuted A1 draft incorrectly expected module-local
`bEnableExceptions=false` to disable Editor exceptions. Installed UBT sets
global exceptions on for Editor (`UEBuildTarget.cs:6184`) and ORs module flags
with that base (`UEBuildModuleCPP.cs:2679`). The blocked draft is preserved.
This explicit subset split does not remove the required **E04-A1G genuinely
exception-disabled runtime caller proof**. A1G remains `NOT_RUN_REQUIRED` before
full A1/RQ11/production adoption; a compatible Game/package target and separate
bounded packet must establish it. A1E success alone cannot close that obligation.
The installed platform catalog has no supported Program configuration, so this
subset introduces no unsupported target, engine rebuild or tool installation.

## Source and ownership

The dependency is `jbeder/yaml-cpp@56e3bb550c91fd7005566f19c079cb7a503223cf`,
tag `yaml-cpp-0.9.0`. Its source acquisition is recorded separately in the
[evidence journal](../evidence/2026-10-19-e04a-profile.md). Downloading source
did not execute its CMake or C++ code. Keep its MIT notice with copied material.

Canonical inputs come from the reference-only legacy client,
`Warhammer_40k_UI_arcade` / GitHub `SobolGaming/Warhammer_40k_UI`, at
`5088c1c49dcaff29eb59fb64b3063d30214dde73`. The authoritative external
`Warhammer_40k_AI` remains a separate reference-only dependency. This proof
does not import, launch or change Core, or activate any profile setting.

The exact new source allowlist is:

- `Source/WarhammerClientE04AEditor.Target.cs`
- `Plugins/E04ProfileProof/E04ProfileProof.uplugin`
- `Plugins/E04ProfileProof/Source/ThirdParty/YamlCpp/YamlCpp.Build.cs`
- `Plugins/E04ProfileProof/Source/E04ProfileParser/E04ProfileParser.Build.cs`
- `Plugins/E04ProfileProof/Source/E04ProfileParser/Public/E04ProfileValue.h`
- `Plugins/E04ProfileProof/Source/E04ProfileParser/Public/E04ProfileFormat.h`
- `Plugins/E04ProfileProof/Source/E04ProfileParser/Private/E04ProfileInternals.h`
- `Plugins/E04ProfileProof/Source/E04ProfileParser/Private/E04ProfileParserModule.cpp`
- `Plugins/E04ProfileProof/Source/E04ProfileParser/Private/E04YamlEventReader.cpp`
- `Plugins/E04ProfileProof/Source/E04ProfileProbe/E04ProfileProbe.Build.cs`
- `Plugins/E04ProfileProof/Source/E04ProfileProbe/Private/E04ProfileProbeModule.cpp`
- `Plugins/E04ProfileProof/Source/E04ProfileProbe/Private/Tests/E04ProfileAbiTests.cpp`
- `scripts/migration/Invoke-E04AProfileProof.ps1`
- `tests/migration/fixtures/e04a/corpus-manifest.json`
- `tests/migration/fixtures/e04a/generated-cases.json`
- `docs/plans/research/2026-10-19-e04a-profile-packet.md`
- `docs/plans/evidence/2026-10-19-e04a-profile.md`
- `docs/plans/evidence/2026-10-19-e04a-profile-result.json`

Existing targets, project descriptor, Config, E02 code and both sibling checkouts
remain outside that source-authoring scope. Canonical plan/instruction status
updates are a separate documentation overlay. Ordinary targets leave the
content-free proof plugin disabled; the dedicated Editor target enables it.
Linux source seams remain required, with native toolchain/artifact/build/load
evidence explicitly NOT RUN until the owner arranges a host. No Windows binary
may serve as a Linux fallback.

## Value boundary and deliberate A1 restrictions

The parser exports a memory-only `noexcept` API using UE Core owned values.
Its module privately consumes yaml-cpp and requests exceptions. Both parser and
probe actually inherit enabled Editor exceptions. The probe's module-local false
does not override that global true. It may privately use UE Json for controlled
fixture/ledger metadata. A1G must later test an actually exception-disabled caller.
No vendor/std object, borrowed buffer, allocator, callback or exception crosses
the public API. Expected syntax, format and resource refusals are typed results;
unexpected exceptions/fatal allocations fail the process.

The raw graph retains ordered mapping pairs, case-sensitive UTF-8 values,
stable node indices, anchor definitions and alias occurrence-to-target links.
Aliases are not expanded. Scalars/tags/anchor names are length-delimited bytes;
embedded and terminal decoded NUL bytes must survive. No implicit resolver,
duplicate collapse, merge policy, numeric conversion, normalization or export
equivalence is claimed. Marks remain vendor observations, with unavailable
fields explicit; exact quote spelling, end spans and original-byte coordinates
are not supplied by the event API.

Every `OnNull` is refused as `NullPropertiesUnavailable`: the pinned parser can
discard an explicit tag on its post-properties EOF route. Ordinary null,
omitted values and empty documents therefore remain unsupported in A1. Only
implicit `?`/`!` and the finite standard str/bool/int/float/seq/map tag set is
accepted as raw data; other tags fail before copying their expanded text.
Canonical inputs must actually pass this restricted subset; never rewrite
them to avoid a refusal. A2 must resolve faithful null/property handling before
full profile or production acceptance.

Raw source must be well-formed UTF-8 without literal NUL/EOT controls, preventing
the vendor's leading-zero encoding detection and raw EOT sentinel from silently
reinterpreting/truncating it. Valid YAML `\N` and `\_` escapes produce single
non-UTF-8 bytes in the pinned `src/exp.cpp`; invalid callback bytes yield
`InvalidEventStream`, not a false malformed-source claim. Those valid escape
forms remain an explicit A1 fidelity gap for A2/RISK09.

## Required native evidence

Exactly eight names use prefix `Warhammer.Migration.E04A1.`:

| Suffix | Required observation |
|---|---|
| `Abi.LoadAndBoundary` | Actual module/function call; build/receipt/compiler/CRT/private-header evidence also required |
| `Abi.TypedRefusal` | Typed failure to a separate Editor caller, followed by a successful parse; no exception-disabled caller claim |
| `Abi.ValueLifetime` | Independent copies/moves/destruction after vendor temporaries die |
| `Parser.CanonicalSyntax` | Ten source-bound profiles: exact root-key order, literal profile identity, selected map/sequence fields and scalar tag provenance |
| `Parser.OrderedCaseValues` | Unicode/case-distinct and equal duplicate keys; anchor rebinding/alias targets; raw scalar tags and full decoded NUL bytes |
| `Parser.LexicalFailures` | Nine exact typed negatives, including property-loss, source NUL/EOT and invalid vendor UTF-8 regressions |
| `Parser.ResourceBounds` | Below/at/above inputs for all five inclusive limits |
| `Integration.RepeatIsolation` | Fresh good/bad/good parses without stale anchors, counters or diagnostics |

Freeze **38 unique inputs**: ten canonical C01-C10, four K01-K04, nine F01-F09
and fifteen L records. The earlier 34-input proposal is historical; four focused
regressions were added during source preparation before any SOURCE/build/test
freeze. Manifests bind deterministic recipes, exact bytes and independent expected
structures/refusals. Primary source/staging identities use SHA256. Native UE Core
FSHA1 is an auxiliary observation of bytes actually passed to the parser; it is
not SHA256 or a Core protocol identity.

| Limit | Inclusive boundary and independent recipe |
|---|---|
| Input | 1,048,576 UTF-8 bytes; small valid mapping plus comment padding |
| Depth | 64 simultaneous map/sequence collections; root collection is one |
| Raw nodes | 100,000; every key/value scalar, collection or alias occurrence counts, with no expansion |
| Aliases | 10,000 occurrence events, excluding definitions |
| Scalar | 65,536 decoded UTF-8 bytes |

Use below/at/above values independently of parser counters. Reject oversized input
before copying/parsing; failed results expose no partial document. Original input
bytes/hash remain in owned fixture/artifact evidence. These adapter checks do
not establish a vendor scanner/OS allocation ceiling.

Each suite writes its actual input ledger under
`RunRoot/artifacts/native/<suite-slug>/input-ledger.json` and retained original
input bytes under its `inputs/` directory. Derive paths from exact staged project
ancestry; no user-default fallback. The wrapper independently seals physical
no-reparse ownership. Require eight unique suites and a 38-ID union; preserve
repeated attempt labels. Custom evaluated check counts and UE report assertions
remain distinct, actual observations. No totals are prefilled.
Each native suite also records actual compiler-guarded Editor exception mode:
`callerExceptionsEnabled=true`, `platformExceptionsDisabled=0`, the exact A1E
subset and `runtimeCallerProof=NOT_RUN_REQUIRED_E04_A1G`. The wrapper must bind
that mode to actual compile/shared-response/forced-definition evidence. It still
proves vendor include/definition/static-link isolation from the probe separately.

## Execution prerequisites and bounds

Before execution, freeze the actual wrapper/target/plugin/callers/tests, all used
vendor and installed UE/CMake/tool APIs, fixtures, tool identities and exact
arguments. SOURCE review precedes Configure/build/native work. Record the actual
candidate/run and phase GO; freeze and authority must identify the A1E subset and
the unresolved required A1G proof. No historical E02 authority transfers.

The proposed phases are Preflight 300s (no external root), SupervisorControls
600s (six controls/three groups/five roots), Configure 600s, DependencyBuild
1200s, EditorBuild 1800s, hidden Discovery 600s, hidden Native 600s and Audit
300s. Configure/build/Discovery/Native each get one owned root. There is no
Python/oracle phase, visible window, Core host or package execution.

Use fresh `.local/experiments/E04A1/<RunId>/project` and owned temporary,
artifacts/logs/reports/UBA/DDC paths. Preserve authored Config/source membership
and nine fresh Editor/UBT settings roles. Keep explicitly allowed ordinary UBT
cache effects separate. Clear inherited E02_* startup channels. Require 20GiB
free space; retain complete outputs and refuse cap/timeout/cleanup uncertainty.
Exact live versus post-phase cap enforcement must match the reviewed wrapper.

The selected dependency recipe is static Release, C++20, matching selected x64
MSVC and `/MD`, with tests/tools/contrib/format/install disabled. CMake may build
only after SOURCE. Copy verified headers/library into owned `vendor-artifact/`
paths; never invoke an install target or use system/nearby binaries. The external
ModuleRules binds acquired source, same-run build, copied bytes and actual UBT
compiler/SDK/tool selection. Producer lineage records do not replace inspection
of actual compile/link flags and module-load evidence.
Actual Editor `/EHsc` and `PLATFORM_EXCEPTIONS_DISABLED=0` must be demonstrated
for both parser and probe. This observation does not prove the required A1G mode.

Failure blocks the affected claim. Preserve partial artifacts and close its
authority; repair/refreeze/review rather than weakening limits or changing the
legacy corpus. Closed execution/evidence then requires fresh independent CODE
and a different REQ under OWN15. No bounded result closes full E04, Linux,
packaging, production profiles, HUD rendering or broader implementation gates.
