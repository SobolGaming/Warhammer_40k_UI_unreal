# E04-A1G dependency-fact comparison source repair

Status is DEPENDENCY_FACT_COMPARISONS_SOURCE_REPAIRED_FRESH_SOURCE_PENDING.
After failure checkpoint a672ab072fb7ffca237445687eebb667b52c35ba and verified
OWN18 exact remote backup, root adopted only three wrapper-line changes at
2026-10-21T13:38:02.4830571Z. The
[repair receipt](../evidence/2026-10-21-e04a-game-dependency-fact-source-repair.json)
records the source identities and finite validation.

Lines 566, 578 and 618 now use existing Equal-Data instead of comparing serialized
JSON strings. This removes dictionary enumeration order from dependency-fact
comparison. Both reference-array operands keep explicit array wrapping; exact keys,
scalar types/values, null distinctions and array order/cardinality remain material.
Independent descriptor, type, path and byte checks remain. The helper, norm, Rules,
C++, targets, project, Config, fixtures and supervisor are unchanged.

Root inspected the full functional diff, matched the whole source inverse and
preserved 169 CR/1847 LF bytes. The repaired wrapper has zero AST errors and
113 functions. These source observations establish no behavioral or native PASS.
At adoption, behavior and fresh SOURCE were NOT_RUN, all nine new phases were
NOT_RUN, new RunId was UNBOUND and actual new bindings NOT_CREATED. No new
SOURCE admission or phase authority was issued.

The [closed failure](2026-10-21-e04a-game-dependency-fact-source-failure-closure.md)
and [raw 92d915f FAIL](2026-10-21-e04a-game-source-review-92d915f.md) remain
unchanged. No old review or execution authority transfers to repaired source.
Checkpoint/push/gh-verify the repaired-source backup before fresh exact bindings
and affected SOURCE; separate ordered nine-phase GOs follow positive root
admission. Final CODE and different REQ follow successful closed execution.

Bounded A1E acceptance and historical failures remain unchanged. OWN17 stays
deferred/unproven, visible authority zero, Linux UNTESTED and perpetual private
source/API review consent unchanged. This repair record supplies no review,
native launch or milestone acceptance.
