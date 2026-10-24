# E04-A1G window-owner query: SOURCE failure closure

Status: **SOURCE_FAILED_WINDOW_OWNER_QUERY_FALSE_PASS**.
The raw SOURCE verdict is FAIL. SOURCE is not admitted; the norm is unchanged
and no actual observer fix is adopted by this closure.

The reviewed source is b049c0283953127efa82dacefbdc69cb79a38559 against
cfd2ff3e78e40ce426ce87827d848d7fa464a66b, run 20261023T151324Z-d32d856f,
session 01a16955-6fe3-7d60-8484-5eb4233def23. Root observed foreground exit 0 at
2026-10-23T15:27:11Z (497f7c). Successful CLI closure does not pass SOURCE.

The C# owned-window observer silently skips a GetWindowThreadProcessId result of
0. That failed owner lookup can therefore lead to ZERO_OBSERVED instead of a
query-failure result. The [clean norm](2026-10-21-e04a-game-proof-packet.md) requires
query failure to fail (line 418). This is a concrete source finding, not an
observed native execution failure; no native phase ran in this attempt.

The v12 packet supplied the direct emitterstyle.h BODY grant. That cleared the
[earlier packet coverage gap](2026-10-23-e04a-game-source-packet-gap-closure.md);
this FAIL concerns observer behavior. Preserve the earlier BLOCKED report and
its exact encoded bytes as history.

Root's strict pipeline 69229b and metadata inspection f6ce67 preceded first
report/tool-value BODY inspection 98aaee. Retained metadata records raw 12,
selected 8, four actual extraction consoles, 852 unique frozen/control identities
and 1,021 descriptor occurrences. The complete ledger has 47 inputs and 47
outputs, with zero unmatched inputs and zero orphan outputs. These counts alone
do not establish the completed conduct audit or SOURCE approval.

Root conduct audit and clipping qualification:
Root inspected all 47 actual inputs in 98aaee (1-16), beff60 (17-32) and 8098f1 (33-47). Observed conduct was inert source/metadata/hash/clock inspection and pinned read-only Git; no candidate/helper/test/native/GUI/Core execution, edits, connector/collaboration call or peer-report body was observed. Call 28 included unrestricted name-status metadata only followed by a scoped body diff; call 39 was a scoped wrapper body diff. Complete-record ordinals 2, 6, 84 and 88 are clipped. Preserve that qualification: paired ledgers and reported coverage do not certify semantic delivery or comprehension. Stderr retained four ignored plugin-icon warnings and one unsupported PowerShell-snapshot warning. Runtime disabling of exposed apps/network/collaboration and lower-level memory features remains UNVERIFIED.

The [encoded original FAIL report](2026-10-23-e04a-game-source-review-b049c02.json)
must preserve the exact original UTF-8 bytes with UTF8Base64:
2252 bytes, SHA256 DDD9AFB3F39A1EDCC197FDD0DC9B7DF82211563F56B36CAEFBF50668F5555854, terminal byte 46; the encoded public wrapper is 3510 bytes, SHA256 C4A62EA645457709EBD9D5AB0B1AB3EB7F052355EC60EC003F5C01FA3CB9B1DA.
The [closure receipt](../evidence/2026-10-23-e04a-game-window-query-source-failure.json)
is root-owned:
5357 bytes, SHA256 E243402F8EFA8957963FE8C337BB41D35CDA434011E36632D7E26CD939D3EDE6.
Do not normalize the original report or change frozen .gitattributes to publish
it. Private session/tool bodies remain local; nested descriptors confer no BODY
grant. Root completed the original-report and actual-input inspection after the strict seals and independent rehash; the auxiliary draft supplied no review verdict.

No SOURCE admission exists. All 14 pure controls and all nine phases—Preflight,
DependencyConfigure, DependencyBuild, EditorPrerequisiteBuild, GameBuild, Cook,
Stage, Native and Audit—are NOT_RUN. Root independently observed the actual .local/experiments/E04A1G run path absent (1290e2/this publication check), correcting the earlier private closure's noncanonical path check in a separate retained record. Native R was not allocated; no phase GO,
runtime proof or A1G acceptance follows from exit 0, sealed metadata or paired
tool records. The old a898057 Cook failure remains unchanged.

Complete the actual failure record, publish it, checkpoint it, push and verify
its exact remote OWN18 backup BEFORE any actual observer fix. A source-only
remediation proposal supplies no fix adoption. After the failure backup, separately
adopt and checkpoint the focused repair, bind a fresh packet and obtain fresh
affected SOURCE. Positive SOURCE admission must precede actual 14-control execution
and its retained receipt; the Preflight GO remains a separate later action.

Preserve revision 125 and all earlier evidence, bounded A1E acceptance, OWN17
deferred/unproven, visible authority zero, Linux UNTESTED, A2 deferred and perpetual
private source/API review consent. Fresh final CODE and a different REQ remain
future gates; no old review or native authority transfers.
