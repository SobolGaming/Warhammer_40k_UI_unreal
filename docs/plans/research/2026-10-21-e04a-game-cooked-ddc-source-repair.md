# E04-A1G cooked-Game DDC source repair

Status is COOKED_GAME_DDC_SOURCE_REPAIRED_FRESH_SOURCE_PENDING. Root adopted
the three canonical source changes and review-only v9 builder at
2026-10-21T15:20:03.5397869Z after failure checkpoint
74cba5d14d315ae3200b1002f0c0f6ce48d65633 and exact verified OWN18 remote
backup. The [repair receipt](../evidence/2026-10-21-e04a-game-cooked-ddc-source-repair.json)
binds the actual identities and finite static observations.

M06 retains RequiresCookedData and uses one nonloading TryGetDerivedDataCache
observation requiring a null pointer. Result fields requiresCookedData and
existingLegacyDerivedDataCacheIsNull must both be literal Boolean true. The
wrapper also requires actual WITH_EDITORONLY_DATA=0, zero Native legacy-DDC log
rows and zero files in its owned DDC directory. Cook keeps its positive actual
owned writable DDC proof. These observations cover the queried legacy pointer,
closed log and owned directory at their validation boundaries; runtime DerivedData
IoStore is separate. No universal or continuous cache/write absence is claimed.

All 52 Game-check IDs remain. No DerivedDataCache module dependency or forced
initialization is added. Product descriptor, Rules, targets, Config and supervisor
are unchanged. Root read the three source bodies/full functional diffs and matched
whole forward/inverse bytes: three C++ literals, five wrapper literals and four
normative literals. CR counts are preserved; the wrapper has zero AST errors and
113 functions. The unchanged Cook positive-writer function comparison includes
1348 bytes and its trailing blank line. Review-only v9 matched its whole v8
forward/inverse, with zero AST errors/nine functions; it was not executed.
Runtime freeze membership 625 and required whole-source count 43 are unchanged.

At adoption C++ compilation, behavior, fresh SOURCE and all nine new phases
were NOT_RUN, new RunId UNBOUND and actual new bindings NOT_CREATED. No
new admission or GO was issued.

The [historical Native failure](2026-10-21-e04a-game-native-ddc-failure-closure.md)
remains failed, alongside its actual raw Game PASS of 52 custom checks, two parser
attempts and one callback. No old SOURCE/native authority transfers. All earlier
failures and separate exact settings restoration remain unchanged.

Checkpoint/push/gh-verify repaired-source backup before fresh exact bindings
and affected SOURCE, then separate ordered phase GOs after positive admission.
Final CODE/different REQ and A1G acceptance remain open. Bounded A1E acceptance,
OWN17 deferred/unproven, visible zero, Linux UNTESTED and perpetual private
source/API review consent remain unchanged.
