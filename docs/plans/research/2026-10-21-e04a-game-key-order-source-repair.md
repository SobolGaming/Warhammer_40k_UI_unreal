# E04-A1G key-order source repair

Revision 100 is GAME_KEY_ORDER_SOURCE_REPAIRED_FRESH_SOURCE_PENDING.
Root adopted the narrow wrapper repair at 2026-10-21T10:13:10.2382869Z after
failure checkpoint 38b9c668 and verified OWN18 backup.
The [adoption receipt](../evidence/2026-10-21-e04a-game-key-order-source-repair.json)
records exact wrapper/norm/patch identities. The [raw FAIL](2026-10-21-e04a-game-source-review-2b52bbc.md),
[failure receipt](../evidence/2026-10-21-e04a-game-source-failure-2b52bbc.json)
and [revision 99 closure](2026-10-21-e04a-game-key-order-source-failure-closure.md)
remain unchanged.

The source adds ConvertTo-A1GComparableData before Equal-Data: require string
dictionary keys, sort them ordinally and retain a case-sensitive ordered map;
recursively retain array order/cardinality and scalar values for JSON comparison.
Empty/singleton arrays, Boolean/null and case-sensitive keys remain distinct.
No key/path lowercasing or array reordering is allowed. The norm now states those
semantic criteria.

At adoption, validation consisted only of exact whole inverse and source AST:
zero errors, 111 functions. Behavioral controls, fresh SOURCE and native phases
had not run at that timestamp. These checks establish no behavioral/review PASS.
After repaired-source checkpoint/push/verified backup, finite pure comparison
controls are required before fresh exact bindings and independent affected SOURCE.

All nine native phases remain NOT_RUN, with zero attempts/checks; two inputs/
two attempts/52 checks are planned. No new RunId, SOURCE admission, native
authority or visible launch is established. Failed planned run
20261021T095500Z-68aaa7fa stays closed and never allocated a native RunRoot.
No old authority transfers. Bounded A1E acceptance, OWN17 deferred/unproven,
Linux UNTESTED and perpetual private source/API review consent are unchanged.
Final CODE/different REQ follow actual closed execution.
