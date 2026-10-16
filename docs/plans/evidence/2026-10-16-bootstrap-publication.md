# BOOT01 publication and merge

Date: 2026-10-16. Authority: OWN13; the owner confirmed updating token permissions
and requested another attempt. **PASS: committed, pushed, PR created and merged.**

The required workspace credential was supplied through process-only `GH_TOKEN`
without printing or committing it. `gh repo view` now found an existing **private,
empty** `SobolGaming/Warhammer_40k_UI_unreal` repository; no further creation,
visibility change, tool installation or alternate credential was needed.

The empty `main` base `61d7dce1583aff191987b5eccaf0de8b48c89ade` and reviewed task
branch `codex/unreal-bootstrap-and-migration-plan` were pushed. Feature commits:
`51cbc62c8816be20ac889364e75f543f11417aa2` and
`d68a5afb0abdd2df978d305252f365750a06bcdf`.

[PR1: Import migration plan and verified Unreal C++ foundation](https://github.com/SobolGaming/Warhammer_40k_UI_unreal/pull/1)
was created with the prepared body and attached to this chat. GitHub reported
`MERGEABLE` / `CLEAN`, empty `statusCheckRollup`, and `gh pr checks` returned
`no checks reported` (exit1). This is **not hosted CI PASS**; no workflow exists in
the initial source tree. REST Checks API inspection returned403 for token access;
the rules API returned403 because that private-repository feature needs a plan
upgrade. Neither error was hidden or resolved by changing privacy/billing.

Normal `gh pr merge --merge --match-head-commit d68a5afb0abdd2df978d305252f365750a06bcdf`
succeeded with no admin/bypass option. Readback confirmed `state: MERGED`,
`mergedAt: 2026-10-16T21:57:12Z` and merge commit
`0467ee63fe6d4c775f429afae2233d7292787c31`. Existing frozen-source reviews,
local build results and acceptance limits remain in the PR/source evidence.

Local `main` fast-forwarded to that merge, then continuation branch
`codex/e01-core-boundary` was created. Both reference siblings remained clean;
Core still selected `5f509724da25a2f6ded0c2739a8e7c84bdf59c91`. EXT07's publication
blocker is closed. The next [E01 packet](../research/2026-10-16-e01-boundary-packet.md)
requires review of its new implementation and actual runtime/native results;
publication success supplies no E01 or full-migration PASS.
