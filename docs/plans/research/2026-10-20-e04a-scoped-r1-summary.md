# E04-A1E first scoped SOURCE campaign

Root disposition: **SCOPED_SOURCE_BLOCKED_TARGET_RULES_INPUTS**. This is a
closure record, not an aggregate SOURCE approval. The candidate is
`f7f77eb281c0629fba12fa5a352e5301bf43e738`, cumulative base
`03d28af606fc6c57d20915f746296b0d843211c6`, run
`20261020T044205Z-14143fc0`.

All eight initial raw reports were sealed before their first body read and
preserved byte for byte. Their local verdicts remain unchanged:

| Scope | Raw verdict |
|---|---|
| [S_VALUE](2026-10-20-e04a-scoped-r1-s-value.json) | SOURCE_PASS |
| [S_BUILD_HOST](2026-10-20-e04a-scoped-r1-s-build-host.json) | SOURCE_PASS |
| [S_TARGET_RECEIPT](2026-10-20-e04a-scoped-r1-s-target-receipt.json) | BLOCKED |
| [S_PLUGIN](2026-10-20-e04a-scoped-r1-s-plugin.json) | SOURCE_PASS |
| [S_CLIENT](2026-10-20-e04a-scoped-r1-s-client.json) | SOURCE_PASS |
| [D_SELECTORS_001_301](2026-10-20-e04a-scoped-r1-d-selectors-001-301.json) | SOURCE_PASS |
| [D_SELECTORS_302_602](2026-10-20-e04a-scoped-r1-d-selectors-302-602.json) | SOURCE_PASS |
| [D_SELECTORS_603_902](2026-10-20-e04a-scoped-r1-d-selectors-603-902.json) | SOURCE_PASS |

`TARGET-RECEIPT-B01` identifies missing primary inputs. The granted UBT code
calls `TargetRules.ShouldIgnorePluginDependency`, but its inherited
implementation is absent from the 93 granted bodies. Applicable definitions,
defaults and initialization/configuration routes for
`bIncludePluginsForTargetPlatforms`, `bAllowEnginePluginsEnabledByDefault`,
`bBuildDeveloperTools` and `bBuildRequiresCookedData` are also needed for the
complete build-selection assessment. The dedicated target's lack of an
override does not prove inherited behavior. No implementation defect is
asserted from this packet gap.

Both integration reviews remain NOT LAUNCHED. The current campaign is closed
and must not be reused. No report has been admitted to an aggregate, and no
`sourceReviewed.report` has been assigned. All eight native phases remain
NOT RUN; no native RunRoot exists. The implementation and historical 21
passing pure path controls are unchanged; those controls were not rerun.

Root captured eight distinct fresh exec sessions with read-only/never
permissions and disabled-memory metadata. Every owned job exited zero with
confirmed cleanup and final active count zero. All received prompts have two
extra trailing CRLF bytes; equality after removing only trailing CR/LF is
established, while byte-identical transport is false. Lower isolation and
backend memory internals remain unverified. A preliminary runtime comparison
mistook object-property serialization order for a value difference; the
preserved structural correction establishes zero selected-value differences.

Ordinary trace audits are separate from formal reviews. They preserve
ungranted upstream common-policy parses and S_PLUGIN's own generated
runtime/invocation reads; those accesses receive no retroactive grant.
S_VALUE also emitted two unselected false authority fields and synthetic
nulls for absent fields, with later precise presence recovery. No peer
verdict, author source-quality conclusion or credential exposure was observed
in the completed supporting checks. These observations do not establish
complete aggregate scope, graph semantics or admission of a local pass.

The next step is to amend and refreeze the missing complete target-rule and
initialization inputs, correct explicit access guidance, rederive actual
coverage duties and obtain fresh affected SOURCE and blind integrations.
The [factual record](../evidence/2026-10-20-e04a-scoped-r1-result.json) binds
the reports, runtime/sealing/closure evidence and remaining limitations.
The [composition criteria](2026-10-20-e04a-source-composition-packet.md)
continue to require complete coverage and separate root admission before
any single-phase GO. Final CODE/different REQ, A1G, A2, Linux, HUD/input,
Core-connected play and packaging remain open.
