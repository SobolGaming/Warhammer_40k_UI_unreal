# E04-A1G window-owner query: focused source repair

Status: **WINDOW_OWNER_QUERY_SOURCE_REPAIRED_FRESH_SOURCE_PENDING**.
Root adopted the focused repair after the verified failure backup; this record supplies source evidence only.

The [b049c02 SOURCE FAIL](2026-10-23-e04a-game-window-query-source-failure-closure.md)
identified a zero-return owner-query path that can report ZERO_OBSERVED instead
of failing the observation. Preserve that actual FAIL and every earlier closure,
including the prior packet-gap BLOCKED result and historical Cook failure.

The repair scope is four narrow edits in
scripts/migration/E04A1GOwnedJobSupervisor.cs:

1. Add SetLastError to the GetWindowThreadProcessId import.
2. On a zero return, capture the original Win32 error and throw Win32Exception
   with a generic operation message.
3. Remove the now-redundant thread != 0 test after the explicit zero-return guard.
4. Rethrow callbackFailure so its original Win32 code reaches Error.

The only accompanying wrapper change is the exact C# source size/SHA256 identity
pin in scripts/migration/Invoke-E04A1GProfileProof.ps1. The
[clean norm](2026-10-21-e04a-game-proof-packet.md) is unchanged. No extra observer
scope, visible-window authority or runtime assurance campaign is introduced.

Exact OWN18 actual-failure checkpoint and remote backup:
6c05043a88241fad39da041c7e7f885f65393e21, pushed and exactly verified with gh in e6b7ea at 2026-10-23T15:39:02.8799348Z; retained backup 605 bytes, SHA256 7164935913EF44DF1A47FF1024A77B87078642FCABC89C4631AB26E20A5F5B65.
Actual source adoption after that failure backup:
52af0c after the failure backup; retained adoption 2261 bytes, SHA256 523C61A9BA6A6BCA259DEBA0F9707233BBA28419CF1BAF6915F6E34D9711D6D8.
Changed C# and wrapper before/after identities:
Supervisor 41523/F4BF73355ECCEB727DBE23E60FB21B61A29C424776F7C7938EA946F18826E32C became 41604/44BA66FD92C826F4A50B3F9FF5656AFE3C653F02D5FC42B5B8F15FE2E06D80E8; wrapper 211429/0837A1958A9FF58131C970578CFA66FF10DCA5551A39F125064936E4A4D7F6DD became 211429/64613E9C2947A1338939B1FC9D5A36D0255DD6D42206E8253D8138A58FB42F30.
Inert parse and whole-inverse checks actually performed:
Root independently checked both whole-file inverses, parsed the repaired C# syntax with zero errors, and parsed both wrapper ASTs with zero errors. All 125 wrapper functions remain; 124 are unchanged and only Check-Bindings differs. The separately prepared syntax comparison reports 44 C# method declarations, 42 unchanged; root inspected its complete minimal diff (ccc068). No semantic compilation or candidate invocation occurred.
The [repair receipt](../evidence/2026-10-23-e04a-game-window-query-source-repair.json)
is root-owned:
2883 bytes, SHA256 81A2CD73CD5F3BD878E40AD02628E8F7DF4BE934ABA28500FEE517AE9428BFED.

This record supplies source evidence only. No candidate execution is claimed.
The zero-return branch remains unforced. The 14 focused trace/SDK controls cover
pure trace-delta and SDK metadata behavior; they do not cover observer failure,
exercise GetWindowThreadProcessId or prove native callback/error behavior.

Fresh affected SOURCE, all 14 controls and all nine phases—Preflight,
DependencyConfigure, DependencyBuild, EditorPrerequisiteBuild, GameBuild, Cook,
Stage, Native and Audit—are NOT_RUN for the repaired candidate. New RunId is
UNBOUND and fresh bindings are NOT_CREATED. No SOURCE admission, native proof,
phase GO or A1G acceptance follows from the source repair or inert checks.

The actual SOURCE FAIL backup preceded adoption. After adoption, checkpoint,
push and verify the exact remote backup of repaired source BEFORE fresh bindings
and affected SOURCE. The repaired-source checkpoint/backup remains the next required action:
PENDING at this source-only publication point. The subsequent actual checkpoint and exact-gh backup are retained separately to avoid a self-referential commit identity; fresh binding must verify that receipt.
Only positive fresh SOURCE admission can precede actual execution/retention of the
14 controls; separate ordered phase GOs remain later actions. No old authority
transfers and the old FAIL is not rewritten.

Preserve revision 126 and all prior history, bounded A1E acceptance, OWN17
deferred/unproven, visible authority zero, Linux UNTESTED, A2 deferred and perpetual
private source/API review consent. Fresh final CODE and a different REQ remain
future acceptance gates.

The auxiliary draft supplied no review verdict. Root inspected the exact minimal source changes and performed the recorded inert checks. Root checked the inserted status separators at the byte level (68f4a5): they are actual LF line breaks; no separator correction was needed. Historical words and other code text are preserved.

Microsoft documents the zero return and extended Windows error behavior in [GetWindowThreadProcessId](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getwindowthreadprocessid). The repair fails on zero regardless of whether the captured diagnostic error code is also zero.
