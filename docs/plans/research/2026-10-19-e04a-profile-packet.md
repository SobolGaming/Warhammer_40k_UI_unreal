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
- `tests/migration/Test-E04RulesWitness.ps1`
- `tests/migration/fixtures/e04a/corpus-manifest.json`
- `tests/migration/fixtures/e04a/generated-cases.json`
- `docs/plans/research/2026-10-19-e04a-profile-packet.md`
- `docs/plans/evidence/2026-10-19-e04a-profile.md`
- `docs/plans/evidence/2026-10-19-e04a-profile-result.json`

This 19-path authoring allowlist includes the separate Rules-witness proof
control. It does not add that PowerShell control to the unchanged 33 staged UE
authored-source members.

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

Every graph `OnNull` starts a `NullPropertiesUnavailable` refusal: the pinned
parser can discard an explicit tag on its post-properties EOF route. Only that
private refusal triggers a fresh, nonpublishing syntax probe over the same owned
immutable input bytes, after the partial graph/parser/stream have unwound. Drive
exactly one fresh `HandleNextDocument` call. If that first document completes,
restore the exact original null diagnostic; an internal work/balance stop also
restores it without claiming syntax completion. Only a `ParserException` actually
reached during this bounded first-document probe becomes `MalformedYaml`, using
its observed mark. Other original refusals retain their existing ordering.

The probe uses a fixed 64-entry private collection-kind stack and inclusive
100,000 raw-node-event, 10,000 alias-event and 65,536 decoded-scalar-byte bounds,
after the unchanged 1 MiB entry guard. Count scalar/null/alias/collection-start
events once each, aliases separately, and stop before exceeding a bound. It
stores no graph, null placeholder, tag/anchor ownership or returned vendor value.
These fresh per-pass bounds do not claim one-pass aggregate work, scanner peak
memory, complete-stream syntax or lexical fidelity. Preserve narrow exception
handling and intentional termination for uncaught allocation/unknown exceptions.

Ordinary null, omitted values and empty documents therefore remain unsupported
in A1; valid/completed syntax or a probe bound stop never makes null a supported
value. Only
implicit `?`/`!` and the finite standard str/bool/int/float/seq/map tag set is
accepted as raw data; other tags fail before copying their expanded text.
Canonical inputs must actually pass this restricted subset; never rewrite
them to avoid a refusal. A2 must resolve faithful null/property handling before
full profile or production acceptance.

Raw source must be well-formed UTF-8. Before vendor parsing or decoding, refuse
every raw C0 byte below 0x20 except TAB (0x09), LF (0x0A) and CR (0x0D) as
`MalformedYaml`, with failed-empty result and unavailable source mark. This
includes the earlier NUL/EOT exclusions, preventing vendor encoding sniffing or
its raw EOT sentinel from reinterpreting/truncating the source. This is a raw
input check, not a filter over valid escaped decoded scalar values. Valid YAML `\N` and `\_` escapes produce single
non-UTF-8 bytes in the pinned `src/exp.cpp`; invalid callback bytes yield
`InvalidEventStream`, not a false malformed-source claim. Those valid escape
forms remain an explicit A1 fidelity gap for A2/RISK09.

Context-sensitive non-C0 lexical conformance remains unresolved. In particular,
plain raw DEL has a source-supported acceptance route in the pinned scanner;
it is not claimed fixed by the C0 entry check. Quoted DEL/C1 and an ASCII YAML
escape decoding to C0 are different cases and must not be rejected by a global
c-printable/scalar filter. Preserve this known plain-DEL risk for A2/full YAML
conformance and production; A1E remains the basic raw proof and finite typed
refusals described in this packet, not a general malformed-YAML rejection claim.
The original scope paragraphs (opening A1E/A2 split; value-boundary restrictions;
expected typed refusals; finite LexicalFailures list) retain that distinction.
No broader applicable A1, RQ11 or production criterion is waived. Any future
result must state this limitation explicitly rather than report lexical or
legacy compatibility from the finite negative set.

## Required native evidence

Exactly eight names use prefix `Warhammer.Migration.E04A1.`:

| Suffix | Required observation |
|---|---|
| `Abi.LoadAndBoundary` | Actual module/function call; build/receipt/compiler/CRT/private-header evidence also required |
| `Abi.TypedRefusal` | Typed failure to a separate Editor caller, followed by a successful parse; no exception-disabled caller claim |
| `Abi.ValueLifetime` | Independent copies/moves/destruction after vendor temporaries die |
| `Parser.CanonicalSyntax` | Ten source-bound profiles: exact root-key order, literal profile identity, selected map/sequence fields and scalar tag provenance |
| `Parser.OrderedCaseValues` | Unicode/case-distinct and equal duplicate keys; anchor rebinding/alias targets; raw scalar tags and full decoded NUL bytes; K05 escaped C0 and legal quoted DEL/C1 with exact decoded bytes |
| `Parser.LexicalFailures` | Thirteen finite typed-refusal inputs, including property-loss, source C0, invalid vendor UTF-8 and bounded null-only syntax regressions; F10 is raw quoted U+0001 refused at entry |
| `Parser.ResourceBounds` | Below/at/above inputs for all five inclusive limits |
| `Integration.RepeatIsolation` | Fresh good/bad/good parses without stale anchors, counters or diagnostics |

Freeze **43 unique inputs / 50 attempts**: ten canonical C01-C10, five K01-K05,
thirteen F01-F13 and fifteen L records: 33 generated inputs and the same eight
suites. The earlier 34-input proposal, 38-input/45-attempt set and subsequent
40-input/47-attempt set remain historical. Preserve all 38 original inputs and
28 original generated records, and all 40 preceding inputs and 30 generated
records, with their exact bytes, recipes, expectations and relative order.
K05/F10 remain unchanged. Append F11-F13 after the old 30 JSON/native records;
the existing LexicalFailures F01-F10 loop remains, followed by F11-F13 by ID.
Keep ResourceBounds on original indices 15-29 so the appended F cases do not
enter its fifteen L checks. Manifests bind deterministic recipes, exact
bytes and independent expected structures/refusals. K05 is 32 input bytes with
SHA256 `454EAAE473C179254F4404459416DCC017A06265330AA297EF33F1FFD38FF6EA`;
its two mapping values have decoded UTF8 hex `01` and `7FC280C29F`, five raw nodes,
depth 1 and zero aliases. F10 is 4 input bytes (`22 01 22 0A`), SHA256
`0EB4A4BF3ACD34AD8E86A4FDF3513252BB8B0D53CDE2F6A7E8D008F417683E03`,
and must return MalformedYaml with original input count 4, no document and default
unavailable mark/observed 0/limit 0. Hashes/metrics are independent expectations,
not observed parser results. Primary source/staging identities use SHA256. Native UE Core
FSHA1 is an auxiliary observation of bytes actually passed to the parser; it is
not SHA256 or a Core protocol identity.

| Added input | Exact recipe and required refusal |
|---|---|
| F11 | 10 bytes: `[null, x]` plus LF; completed valid first-document syntax retains `NullPropertiesUnavailable` and empty output |
| F12 | 24 bytes: `[null, a: [unterminated` plus LF; a reached first-document syntax error yields `MalformedYaml` and empty output |
| F13 | 151 bytes: `[null,` + 64 `[` + `x` + 64 `]` + `, [unterminated` + LF; depth 65 must stop the probe before the later malformed tail in the SAME first document, retaining the original null refusal rather than reaching `MalformedYaml`; no syntax-completion claim |

F13 is deliberately discriminating: a probe that continued through the deep
child would reach the later malformed tail; a completed balanced remainder
alone would not distinguish completion from a bound stop.

F11/F13 retain the original null diagnostic (available mark position 1/line 0/
column 1, observed 2/limit 0), with no document, original bytes, root or graph
observations returned. F01 remains `MalformedYaml`; tag-only F05 remains
`NullPropertiesUnavailable`. All native observations remain **NOT_RUN**; these
source-defined expectations are not parser or resource-stop execution results.

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
no-reparse ownership. Require eight unique suites, a 43-ID union and 50 exact attempts; preserve
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

The proposed phases remain Preflight 300s (no external root), SupervisorControls
600s, Configure 600s, DependencyBuild 1200s, EditorBuild 1800s, hidden Discovery 600s,
hidden Native 600s and Audit 300s, in that exact eight-phase order. SupervisorControls
retains its original six supervisor cases/three groups/five roots unchanged, adds
seven pure generated-input preparation controls and 18 pure build-boundary
controls with zero external roots, and one
separate target-refusal control with one 60-second root: total six roots. Keep
all four result families distinct; the target failure is not an additional native
suite or a seventh existing supervisor case. Configure/build/Discovery/Native each get one owned root. There is no
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

### Response closure and inherited build arguments

`Response-Chain` retains the existing breadth-first file/text order and binds
every edge, including duplicate references and edges to an already visited file.
Validate the complete directed graph for cycles independently of file deduplication;
cross-branch cycles must fail as `E04A1_RESPONSE_CYCLE`. References remain literal,
absolute, stage-owned `.rsp` paths with the existing file-kind/size/NUL checks.
Only complete standalone `@path` or `@"path with spaces"` lines are supported.
Refuse every remaining `@` occurrence, including inline or quoted data/argument
forms, as `E04A1_UNSUPPORTED_RESPONSE_REFERENCE_SYNTAX`. A quoted whole-line
reference may contain a literal `@` inside its bound filename. This conservative
grammar is not a general command-line or response-file interpreter.

The actual native supervisor must construct its effective child environment
with `UBT_EXTRA_ARGS` present and empty, even when inherited values are nonempty
or use another key spelling. Reject nonempty explicit overrides. `Child-Environment`
also reserves the key as an empty string, and `Invoke-Root` checks that override
before the root count or process call. Both the normal EditorBuild and separate
ObjSrcMap control supply the explicit empty value. The Rules consumer requires
one exact, string-empty `UBT_EXTRA_ARGS` binding in both expected and recorded
child overrides. Literal OS argv alone cannot establish this condition: installed
UBT appends this environment channel internally before parsing its arguments.

After the unchanged seven generated-input controls and before the one ObjSrcMap
root, `Build-BoundaryControls` runs 18 pure cases: ten response graphs/forms,
four real `Child-Environment` cases and four cases through the same pure C#
environment-block constructor used by the actual supervisor. Include shared DAGs
in both orders, duplicate edges, cross-branch cycles in both orders, self-cycles,
inline/quoted residual references, conservative quoted-data refusal and a valid
quoted filename containing spaces/`@`. Environment cases use synthetic hostile
inherited values and conflicting overrides; never mutate the parent environment.
The tests create owned inert files, require intended refusals and unchanged
inputs, restore the stage and preserve the root count. They launch no process.
Keep their separate report and 18-case count distinct from the original six
supervisor cases, seven generated-input controls, target refusal and native suites.
The existing 600-second phase and six-root total remain unchanged.

The source-only `tests/migration/Test-E04RulesWitness.ps1` controls bind the real
hash-selected validator over synthetic data. Its six added cases reject missing,
nonempty, null or wrongly typed UBT bindings in the applicable expected/root
records. These are pure validator controls, not a real UBT witness. Read/adopt the
exact script and helper source before a separate bounded offline invocation; use
a fresh owned control directory, at most 120 seconds and zero external roots.
Do not dot-source the wrapper, enter its dispatcher, load PE metadata or invoke
C#/native/compiler/engine code through that offline route. The four C# block
checks belong to the later source-approved SupervisorControls phase.

Preflight reports 43 materialized inputs, ten canonical inputs and 33 generated
inputs in separately named fields. The planned native union and attempts remain
43 and 50; no value is an observed native result until execution.

### Generated Configure instructions and dependency handoff

After successful Configure and Check-CMake, capture the actual typed generated
instruction closure, bound to this run/source/freeze/build root and Configure
process. Include CMakeCache.txt, compile_commands.json and build.ninja; generated
.ninja/.cmake inputs, nested CMakeCache.txt/compile_commands.json files and
include/subninja/rule/glob/regeneration inputs must have complete exact reference
mappings. Only Ninja-produced scratch response outputs with exact rule bindings
are supported; refuse literal/preexisting argument-file forms without guessing
recursive tool semantics. Generated inputs stay inside the owned build root;
external referenced primary inputs require an exact frozen descriptor. Refuse
unhandled/dynamic references, reparse paths, duplicate/case-colliding identities
or an incomplete recognizer rather than treating a root-file count as closure. Derive actual membership from Configure; do not invent a fixed file count
or include every object/output as an immutable instruction.

Retain exact baseline copies/manifest under owned logs with before/copy/after
identities. At Invoke-Root's final DependencyBuild preparation point, after the
child environment is prepared and before root-count increment/Supervisor.Run,
compare live complete membership/bytes/hash and retained copies to that same
successful Configure baseline. Bind the original Check-CMake tuple; never
self-approve a fresh baseline. Changed/missing/extra/corrupt input means no launch.
Recheck after build before the vendor receipt/artifact publication; preserve
available observations/offending bytes and baseline on failure, keeping the
primary error separate from retention errors. Generated instruction changes or
regeneration leave lineage unresolved; no silent rebaseline. This check is not
an atomic filesystem/process guarantee against post-check concurrent mutation.

`Generated-BuildInputControls` calls the actual capture/confirm helpers with
owned inert instruction files, not a duplicate validator: unchanged positive,
changed included rules, missing rule, extra.ninja, VerifyGlobs drift, corrupt
retained copy and unsupported preexisting response files. The positive includes
nested cache/compile-command files to check that all helper membership sets agree.
Negative cases require the intended refusal, unchanged baseline,
retained differences and a would-launch counter 0; they invoke no native tool.
This preparation function stays inside the wrapper; it adds no test-file or
external-root allowance. Actual Configure/Ninja/native behavior remains separate.

### Early object/source-map refusal and real negative control

The dedicated target rejects every effective non-null WindowsPlatform.ObjSrcMapFile
at the first derived-constructor statement after base configuration, before proof
target setup, with exact diagnostic `E04_RULES_OBJ_SRC_MAP_FILE_UNSUPPORTED`.
Do not clear/redirect an arbitrary configured path. Keep the existing module-time
native-tool refusals and live 32-selector witness unchanged. The public field's XML
and CLI routes and normal target-to-VCToolChain construction order are material
source contracts; its constructor can delete that path before compilation.

After the unchanged supervisor cases and pure preparation controls, run exactly
one hidden frozen dotnet/UBT invocation, 60 seconds/no retry, on a separate fresh
owned project/control stage. Copy and bind the complete required 33 authored
members; keep its Rules/cache/output state disjoint from the main EditorBuild
project. Retain control files/results under existing logs coverage, and require
main source/output freshness/settings preservation. Pass the owned canary through
one argv token `-ObjSrcMap=<absolute-owned-canary>`, without modifying private XML.
Pin nonempty canary bytes before/after and leave it closed/unlocked during UBT.

Require actual resumed/assigned process exit 8/RulesError, exact dedicated target
instantiation/refusal diagnostic, complete stdout/stderr/log/receipt and exit/job
cleanup, unchanged canary and approved sources. The unchanged supervisor's nonzero
FAIL receipt is the expected attempt result; validate that exact terminal failure
rather than call Require-RootPass or accept any failure. Earlier unrelated error,
wrong/missing diagnostic, timeout, unavailable evidence or canary mutation fails
the control. Source-supported early refusal and observable evidence do not prove
a universal child/compiler absence from missing files or aggregate job counters.
The normal/null positive path remains the later ordinary EditorBuild; no extra
positive root, phase, retry or visible launch is authorized.

The proof parser/probe modules use `PCHUsageMode.NoPCHs`, and the bounded UBT
invocation explicitly passes `-NoVFS`. Installed ModuleRules/UEBuildModuleCPP
source supports direct module definitions without shared PCH selection;
TargetRules applies the explicit VFS argument after configuration. Freeze those
primary implementations and response serialization/path normalization with the
target/plugin discovery and receipt implementations. Keep the strict absolute
stage-owned response/forced-definition path checks. This removes unresolved PCH
topology from this proof; it is not a claim that the earlier candidate actually
emitted an escaping path or that the revised build has run.

Failure blocks the affected claim. Preserve partial artifacts and close its
authority; repair/refreeze/review rather than weakening limits or changing the
legacy corpus. Closed execution/evidence then requires fresh independent CODE
and a different REQ under OWN15. No bounded result closes full E04, Linux,
packaging, production profiles, HUD rendering or broader implementation gates.

## Historical revision 54: prospective SOURCE amendment and then-current state

This historical packaging record is preserved; the adopted practical v7.3 method
supersedes its context-count/projection procedure. This packet amendment changes
fixture/control contracts only, preserving substantive duties, two complete
independent finite witnesses, affected review and separate final CODE/different REQ.

Then-current status was **STARTUP_TARGET_SOURCE_AMENDMENT_ADOPTED_PACKETS_NOT_READY**.
The [adopted composition criteria](2026-10-20-e04a-source-composition-packet-v3.md)
and [adoption record](../evidence/2026-10-20-e04a-startup-target-amendment-adoption.json)
add complete applicable target creation/configuration/finalization/normal
non-test discovery/all-modules setup and Default startup/explicit load/mount
implementations, exact default arguments and finite material callers.
The reference inventory is 96 BODY files / 42,986 physical rows; actual future
frozen identities/counts remain derived. Preserve all earlier source/full-unit,
13-record/902-row/1,561-reference responsibilities and the ten-context gate.

The dedicated target explicitly assigns `bBuildAllModules=false`; its current
source is 593 bytes / 16 rows, SHA256
`1FE8F99EC560DD6C592C5DAB3434092E0A7AE313B2597BE6126C5212C25C1991`.
It remains unexecuted. No effective configuration, target discovery, startup,
library/build/native PASS or universal all-plugins execution claim follows.
No fresh subject/run/freeze/GO, metadata-helper invocation, review or phase result
has been created by the prospective adoption.

R2's six raw local SOURCE_PASS/two BLOCKED reports stay unchanged, with zero
aggregate-admitted passes and both integration metadata directories unused.
All eight experiment phases remain NOT RUN/no native RunRoot. New exact packets,
all ten fresh complete valid SOURCE assessments and root admission precede any
phase. Original packet criteria, quota/corpus/ABI contracts, standing review
consent and separate final CODE/different REQ, A1G/A2, HUD, Linux and packaging
obligations remain unchanged.
