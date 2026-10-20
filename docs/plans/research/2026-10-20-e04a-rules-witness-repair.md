# E04-A1E rules witness producer repair

Status: **RULES_WITNESS_SOURCE_CHECKED_PACKETS_NOT_READY**, 2026-10-20 UTC.
This is an implementation checkpoint and factual progress record. It is not a
fresh SOURCE disposition, phase authority or acceptance record.

The closed [R4 campaign](2026-10-20-e04a-scoped-r4-summary.md) identified a
concrete missing observation and preservation mechanism. The dedicated
[proof target](../../../Source/WarhammerClientE04AEditor.Target.cs) now retains
its actual target object through the public `AdditionalData` bridge. The
[YamlCpp module rules](../../../Plugins/E04ProfileProof/Source/ThirdParty/YamlCpp/YamlCpp.Build.cs)
observe that bridge at module construction, after target creation/validation,
and require the expected concrete target/module types and finite live selectors.
The proof target explicitly assigns `bBuildAllModules=false`,
`bCompileWithPluginSupport=true` and `bDebugBuildsActuallyUseDebugCRT=false`.
The last two assignments follow the base constructor's configuration loading;
later observed values still must match. Ordinary Game/Editor targets are unchanged.

The producer requires a same-run hash-bound input/topology receipt and nonce,
actual process/runtime descriptors, generated rules DLL/PDB/source manifest,
source membership/order and parent assembly lineage. It inspects only the
already completed project rules assembly and finite materialized discovery
cache state, with guarded private API shapes and read synchronization. It never
forces an uncreated `Lazy`, repopulates or invalidates the cache. Two existing
source roots receive cache obligations; eight optional disk absences are checked
separately. Missing or unsupported witnesses refuse the proof.

The recorded cache state and current source/manifest enumeration are poststate
facts. First population is a conditional source-supported inference from a fresh
owned process, preabsence and matching generated/source identities. Chronological
scan events, private Roslyn scheduling, native flags and plugin activation are
not established by this producer. Runtime accessibility of the guarded private
API has not been tested.

The first pure static check completed normally but returned **five CS0012
errors**: `JsonDocument.Parse` overload resolution required `System.Memory`,
which is outside UBT's normal reference set. That
[diagnostic](../evidence/2026-10-20-e04a-rules-static-check-01.json) and its
[process receipt](../evidence/2026-10-20-e04a-rules-static-check-01-process.json)
remain unchanged. The repaired calls use the named string `json:` overload.
The receipt reader retains its positive 8 MiB byte limit, strict UTF-8 decoding,
depth 32, duplicate rejection and disallowed comments/trailing commas. It reads
the exact locked byte count and resets the stream even on failure. Temporary
byte/string allocation is bounded by that input limit. These generated receipt
inputs are UTF-8 without a BOM; no broader BOM compatibility claim is made.

The second [static diagnostic](../evidence/2026-10-20-e04a-rules-static-check-02.json)
returned **zero diagnostics** for all seven project rule sources with UBT's
31 normal metadata references, C# 12 and matching compilation options. Its
[process](../evidence/2026-10-20-e04a-rules-static-check-02-process.json) completed
in 3,497 ms, exit 0, no timeout and confirmed cleanup. Only the trusted compiler
bridge executed: the project/UBT/parent assemblies were metadata inputs. No
candidate assembly was emitted or loaded, no rules object constructed and no
UBT/native build executed. The driver ran on .NET 10.0.11 against the intended
.NET 10.0.7 metadata; this does not establish actual UBT runtime parity.
The [binding record](../evidence/2026-10-20-e04a-rules-static-check-result.json)
identifies the exact checked source and retained originals.

The prospective expanded installed API input preserves the previous 191,150-byte
BODY095 prefix exactly and appends 1,005 physical rows. Root read every appended
row and independently compared all 5,257 literal rows, 43 ranges and 19 whole
origin descriptors against the installed files, with zero mismatches. This is
source-input preparation; it does not grant an amended review packet. Actual
full BODY/unit counts must be rederived after the wrapper, tests and normative
inputs are final.

The [wrapper](../../../scripts/migration/Invoke-E04AProfileProof.ps1) and
[pure controls](../../../tests/migration/Test-E04RulesWitness.ps1) are now
canonical. All [51 controls](../evidence/2026-10-20-e04a-rules-wrapper-controls.json)
passed: complete synthetic joins, wrong process/creation/CWD/argv/challenge,
selectors and source order, cache/parent mismatches, strict JSON, exact retention
paths, actual synthetic live-file drift and primary/secondary failure handling.
Root inspected every case disposition and independently compared unchanged and
changed function extents. The [binding record](../evidence/2026-10-20-e04a-rules-wrapper-result.json)
preserves exact executed source/report identities. These controls use data and
owned synthetic files; the real EditorBuild failure/finally path has its native
launch replaced by a throwing stub. They do not exercise the binary PE/PDB
decoder, private Unreal API accessibility or a real UBT process.

The wrapper source now requires the owned direct-UBT process join, metadata-only
DLL/PDB validation, exact artifact retention, failure preservation and subsequent
live-output checks. It preserves the four native-output freshness guards, all
budgets/root counts, vendor/compiler/receipt/DDC/settings checks and zero visible
windows. Concrete runtime/selector freeze metadata and the clean composition
amendment remain in preparation. The added test source needs a complete positive
BODY grant and fresh freeze; the 33 staged project members are unchanged.
All ten fresh complete scoped SOURCE assessments, root audits and the labelled
aggregate still precede native phases. No earlier report/admission or GO transfers.
All eight native phases remain NOT_RUN. Final CODE/different REQ, A1G, A2/HUD,
Linux, packaging and broader acceptance remain open.
