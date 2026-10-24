# E04-A1E practical SOURCE closure — revision 70

Current status is **PRACTICAL_SOURCE_CLOSED_TOOLCHAIN_REPAIR_REQUIRED**.
The [factual overlay](../evidence/2026-10-20-e04a-practical-source-result.json)
records five closed reviews for publication
`da00e83df5cb1ff227e794d37edad433f676f368`, cumulative base
`03d28af606fc6c57d20915f746296b0d843211c6`, technical source
`73bc2c047aef669595ff5144d285d0d7f10767ef` and run
`20261020T192245Z-8fa15b75`. Reports were sealed before their first body read;
their raw contents and verdicts remain unchanged.

| Assessment | Raw verdict | Captured tool pairs | Current disposition |
| --- | --- | ---: | --- |
| P_VALUE_FIXTURE | BLOCKED | 109 | Material vendor BODY access gap; no demonstrated code defect from that gap. |
| I_FIXTURE_VALUE_RESULT | BLOCKED | 57 | Same vendor access gap and conditional success-before-lock-disposal finding; preserve its antecedent and limits. |
| D_COMPILER_ABI | CHANGES_REQUESTED | 84 | D-ABI-01 directly confirmed; toolchain-alternative refusal needs repair. |
| W_RULES_WITNESS_A | PASS | 117 | Raw PASS only; no root admission or transfer to repaired source. |
| W_RULES_WITNESS_B | PASS | 109 | Raw PASS only; no root admission or transfer to repaired source. |

There are 476 captured pairs and **zero source admissions**. All five review
processes closed with exit0 and confirmed cleanup; process success is distinct
from source approval. Bounded ordinary evidence audits preserve coverage,
truncation/recovery, access and runtime qualifications without replacing the
initial assessments. Full raw reports, tool evidence and private provenance stay
in their existing ignored locations, outside this public checkpoint.

## Required repair and fresh review

D-ABI-01 establishes that configurable `radlink.exe` and `cl-filter.exe`
alternatives are neither frozen nor refused by the current source. It does not
establish that those tools ran or that the relevant configuration was active.
The selected repair will reject effective
`Target.WindowsPlatform.bAllowRadLinker`, `Target.bPrintToolChainTimingInfo` and
`Target.WindowsPlatform.bCompilerTrace` at final module construction. That repair
is pending; this checkpoint changes documentation only.

The seven prepared future definitions have no GO, and their proposed shared
index v3 was never created. They are superseded for use after the technical
repair. Refreeze and derive current affected inputs, then obtain fresh affected
reviews, including **both complete independent finite-witness assessments**.
Neither old raw PASS supplies a repaired-source approval. The substantive
[practical v7.3 method](2026-10-20-e04a-practical-source-method-v7.3.md) is unchanged.

## Conditional FileStream finding

The wrapper publishes success/completion at lines2093–2094 before unguarded
`RunLock.Dispose()` at 2097; `Check-Previous` at 2020–2028 accepts the marker.
Preserve that source-order fact and the report's conditional failure premise.
Research of the pinned PowerShell 7.6.5 / .NET 10.0.11 implementation found no
demonstrated normally reachable throwing-close path for this untouched
synchronous lock stream. This is not a universal no-throw, OS-unlock or process
guarantee. Root does not select a wrapper patch on that antecedent alone.

## Frozen-copy incident and subsequent identity check

During ordinary research evidence preparation, a descriptor helper named `RD`
resolved to PowerShell's `rd` / `Remove-Item` alias and temporarily deleted the
ignored BODY013 frozen wrapper copy. The canonical script was unchanged. The
earliest established deletion opportunity is after `2026-10-20T20:17:39Z`;
all five SOURCE jobs had closed by `2026-10-20T20:17:10.138895Z`.
Root restored the exact 209,830 bytes at `2026-10-20T20:20:39.0379885Z`, SHA256
`FFE36D92F9CBFE1BA4609C2586FEEA0134260EFB6742A78E2CE09AFBAD3B8329`.
Continuous immutability is **not claimed**.

After restoration, root rehashed 2,344 unique current inputs: zero mismatches and
zero descriptor conflicts. The factual overlay pins the restoration receipt and
post-close check; their original pending/historical wording is not rewritten.
This establishes current byte identity, not retroactive continuity or admission.

All eight native phases remain **NOT_RUN**, with no native RunRoot and zero
visible authority. Final independent CODE and a different REQ assessment,
A1G/A2/HUD/Linux/package and broader acceptance remain open. Standing perpetual
private-source/API review consent persists until explicitly revoked. The older
[profile result](../evidence/2026-10-19-e04a-profile-result.json) remains historical;
the new overlay supplies current status without changing its sourceDraft.
