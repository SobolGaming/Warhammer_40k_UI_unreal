# Publication continuation and E01 source preparation

Date: 2026-10-16. Authority: OWN13, the owner's instruction to commit, push, open
and merge the PR, then continue the migration plan. **Local commit/source-check
work completed; remote publication currently BLOCKED. E01 runtime NOT RUN.**

## Publication state

The audited BOOT01 candidate was verified unchanged, scanned against both local
credential values without displaying either, and committed byte-for-byte on
`codex/unreal-bootstrap-and-migration-plan`:

- Empty initial `main` base: `61d7dce1583aff191987b5eccaf0de8b48c89ade`.
- Audited plan/bootstrap: `51cbc62c8816be20ac889364e75f543f11417aa2` (31 authored
  files). This preserves the historical frozen-review hashes. Subsequent authority
  and E01 source-preparation changes are separate work after that snapshot.

Historical BOOT01 manifest members must be checked against that commit's objects,
not a later working tree whose plan/instructions legitimately changed. Neither
the historical manifest nor its recorded review result was rewritten.

Generated binaries, caches, IDE metadata and `.local` remain ignored. Workspace
credentials and root `AGENTS.md` are outside this repository and were not staged.
No source/dependency change warranted repeating the passed Unreal compile.

The configured origin is `git@github.com:SobolGaming/Warhammer_40k_UI_unreal.git`.
Using the required `github-full-access` process credential with `gh`:

1. Repository read returned GraphQL `Could not resolve to a Repository` and REST
   **HTTP404 Not Found**. Discovery listed Core/Arcade but not Unreal. This cannot
   distinguish an absent repository from a private repository hidden from this
   credential.
2. `gh repo create ... --private` returned
   `Resource not accessible by personal access token (createRepository)`.
3. Supported `gh api --method POST orgs/SobolGaming/repos`, with private/empty
   creation requested, returned **HTTP403**,
   `Resource not accessible by personal access token`.

No repository creation success, push, PR, hosted check or merge is claimed. Both
creation routes were permitted by sandbox review; **GitHub** rejected access.
No alternate credential was substituted, permissions weakened, remote changed,
or repository created in another account. Private was the coordinator's safe
creation default, not a new owner distribution decision.

Unblock EXT07: the owner creates an empty reachable repository at the configured
origin (without generated README/license), or grants the required credential access
to the existing repository and creation rights if necessary. An async access
question is pending. Then verify the actual remote/base and permissions, push,
create the PR with the prepared body, attach it to the chat, inspect/wait for
checks, resolve actionable findings, and merge under OWN13. Do not claim no required
checks until the actual repository/PR is accessible.

## Nonblocking migration work actually performed

The installed CPython3.14.5 ran an existing dependency-free check, without bytecode
writes or environment synchronization:

```powershell
& 'C:\Users\Rabid\AppData\Roaming\uv\python\cpython-3.14.5-windows-x86_64-none\python.exe' -I -B 'C:\SWDev\warhammer\Warhammer_40k_AI\scripts\build_engine_build_identity.py' --check
```

**Exit0 / PASS:** `Engine build identity is current:
warhammer40k-core-v2:runtime-tree-sha256-v1:65fc8414407ae5d6a8ea779c8e737a22733459094db679a160c60f6e2129f96a`.
The interpreter also printed `Failed to find real location of ...python.exe`;
that advisory did not prevent the script from executing and passing. Core HEAD
remained `5f509724da25a2f6ded0c2739a8e7c84bdf59c91`, clean before/after.

The [selected-Core source manifest](../../../tests/migration/fixtures/5f509724da25a2f6ded0c2739a8e7c84bdf59c91/manifest.json),
SHA256 `BF861B2EC555C81E85A31E4B37E756C5E6B04D343522A95F3235700C2AEC43F2`,
freezes **127** canonical schema/example/identity/launcher/package-source files as
actual-byte SHA256 and immutable Git blob identities. It inventories **98 unique
canonical case IDs** and the **3,116-resource** runtime identity. It copies no live
session state. **Zero runtime cases executed.** Hashes are source inventory, not
schema validation, fixture execution or installed/native compatibility proof.
Actual checkout-byte hashes are distinct from Core's normalized identity policy.

Core has no prepared `.venv`; Arcade's installed Core is a third, mismatched
revision and its environment is not repurposed. The next E01 packet must specify
its fresh client-owned environment and selected existing development server,
canonical commands/fixtures, authenticated local/HTTP roles, bounds, viewer-safe
captures and stop conditions before live execution. No dependency installation,
host launch, HTTP test, native Unreal parser or gameplay implementation occurred in
this source-preparation step. The [bounded E01 packet](../research/2026-10-16-e01-boundary-packet.md)
records the exact next scope under OWN13. Linux execution remains owner-deferred/NOT RUN.

Both Core and Arcade remained clean at their recorded commits. Publication access
does not block independent source preparation, but is still required to satisfy
the owner's requested PR/merge sequence.
