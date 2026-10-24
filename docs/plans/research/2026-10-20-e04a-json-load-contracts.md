# E04-A1E missing descriptor-reader contracts

The closed v7.2 reports identify missing primary inputs, not an observed engine
failure. Separate read-only research located the implementations below. Existing
BODY099/record14 and raw reports were not edited. Clean literal units and their
identities are local proposal inputs, not current SOURCE approvals.

## Duplicate-field fidelity

Installed `StreamingADA.uplugin`, 791 bytes, SHA256
`7E98244B111906283AE13B238B166D7DCABC152A3D847AEA8B6E16F9CC928381`,
has `IsExperimentalVersion` at zero-based property14 `true` and property19
`false`. The separate catalog snapshot is `false`. Preserve both occurrences.

| Consumer | Primary source route | Conditional source inference |
| --- | --- | --- |
| UBT C# | `PluginDescriptor.cs:441–455` → `EpicGames.Core/JsonObject.cs:258–306`, constructor126–133 and bool lookup475–488 | Successful top-level construction enumerates the properties and uses an OrderedDictionary setter; the later `false` replaces the earlier `true`. Nested objects use Add, a different duplicate contract. |
| Native C++ textual reader | `PluginDescriptor.cpp:206–252` → `RapidJsonUtils.cpp:237–258` → RapidJSON ParseObject/handler/SetObjectRaw → `RapidJsonPluginLoading.cpp:14–70` | Successful ordinary textual parsing preserves both members in order; the Projects lookup selects the first matching value, `true`. |

These are source-conditioned expectations. No UBT JSON reader, native parser or
plugin load was executed in this research; actual compiled/loaded behavior is
unproved. Catalog membership, build selection and runtime activation remain
separate. The FJsonSerializer path in PluginDescriptor.cpp belongs to the
separate update/shared-DOM routes and must not substitute for ordinary textual Read.

Installed `JsonObject.cs` is 32,313 bytes/SHA256
`CCF1DCD749C7EABCA8D192192723830CFE1E541F69AFC0D14A5591A37EA8CBF9`.
The initial research could not retrieve exact framework source from dotnet/runtime.
A later `gh` lookup found the installed `.version` commit in the official
[dotnet/dotnet VMR](https://github.com/dotnet/dotnet/tree/b16286c2284fecf303dbc12a0bb152476d662e44/src/runtime).
Exact source at that commit supplies
[default duplicate acceptance](https://github.com/dotnet/dotnet/blob/b16286c2284fecf303dbc12a0bb152476d662e44/src/runtime/src/libraries/System.Text.Json/src/System/Text/Json/Document/JsonDocumentOptions.cs),
[declaration-order enumeration](https://github.com/dotnet/dotnet/blob/b16286c2284fecf303dbc12a0bb152476d662e44/src/runtime/src/libraries/System.Text.Json/src/System/Text/Json/Document/JsonElement.ObjectEnumerator.cs)
and [object-key replacement](https://github.com/dotnet/dotnet/blob/b16286c2284fecf303dbc12a0bb152476d662e44/src/runtime/src/libraries/System.Collections.Specialized/src/System/Collections/Specialized/OrderedDictionary.cs)
contracts. The failed original lookup and
its limited conclusions remain preserved separately. A source commit does not
prove the identity of an actually loaded runtime or binary.

## Localization readers

D001 row269 contains a LocalizationTargets entry. Its consumers are present in
the installed engine under `Engine/Source`:

- `Programs/UnrealBuildTool/Configuration/Descriptors/LocalizationDescriptor.cs`:
  full declarations, constructors and FromJsonObject, 6,350 bytes/SHA256
  `ECD3E793FB6F8ED24A3B05C704B7DFA4C832AA76A1D7D7A1F8184FF0F813AFF2`.
- `Runtime/Projects/Public/LocalizationDescriptor.h`: declarations/defaults,
  5,669 bytes/SHA256
  `3DDCE4B74E78A7CECE557649B622C6717A14570925B2923235AE6A67B7A95AC7`.
- `Runtime/Projects/Private/LocalizationDescriptor.cpp`: enum conversion,
  Read/error paths, serialization and loading policy, 9,047 bytes/SHA256
  `B40A9A1E12097156B1274F71BA80683895DC934D5F62EAB5863639A3834A7A50`.

Root read and copied these three unchanged files, 565 physical rows, as inert
primary inputs. Fresh semantic reviewers still need their material helper/caller
contracts. This research supplies no localization loading or native result.

The source inputs retain exact ranges/terminators and whole-origin hashes.
Research narratives, recovery notes and conclusions are excluded from future
blind initial inputs. Use the new method's actual source index and input ledger;
do not treat these pointers as a review or an automatic transitive grant.
