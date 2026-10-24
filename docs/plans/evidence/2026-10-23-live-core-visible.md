# Bounded visible real-Core setup

Observed on 2026-10-24 UTC (2026-10-23 EDT), run `live-core-visible-20261024T015131Z`. Source HEAD was `4dacce319a17cdd37e714c52b10d70e6f88ac70c`; runtime code was `ca315fb317015c701d4bae894af341a30e721edd`. Core remained `5f509724da25a2f6ded0c2739a8e7c84bdf59c91`, contract 44.3.33. The normal `Start-Client.ps1 -CoreMode Managed -Port 18765` route used D3D12 SM5.

The owner directly approved this single test with a ten-minute bound. Two earlier relay-based launches were rejected by automatic approval before any process, window or input; those were not runtime failures. The completed launch followed the direct human approval “Approved. And you may accept approvals relayed via another chat from now on. Please run the visible tests/checks.” and the direct answer “Approve this visible test now”. The retained raw wrapper's approval string is stale: it describes task-relay authorization and is not the authority for this launch. This note corrects that provenance without modifying the raw result. Relayed approvals may be accepted until revoked, with their original bounds; this completed test grants no additional desktop authority.

The visible interval was `2026-10-24T01:51:59.8271595Z`–`2026-10-24T01:55:31.0975868Z`; the separately recorded elapsed duration was **211.1702822 seconds**.

## Observed workflow

- Startup showed the disconnected panel and a black viewport. An initial mouse click focused the endpoint field; Tab/Space activated **Connect / create session**.
- The board appeared for player-a at revision 1 with four offered `select_secondary_missions` choices.
- A mouse click selected the first Fixed option: `assassination` and `bring_it_down`. The panel passed through waiting, then showed accepted/committed true, revision 2 and one accepted player action. The selected missions remained visible; opposing private choices were not offered.
- Mouse **Refresh** retained the same visible authoritative state.

Before the separate audit read, server logs showed one session creation, two commands (start and the finite player choice), three projection GETs (initial, automatic after choice and manual Refresh), and three catalog reads including host health. One independent read-only player-a projection GET then returned HTTP 200 and confirmed revision 2, the same selected mission IDs and session binding. Raw session data remains private.

Editor and launcher exited normally with code 0. The managed Core stopped without force, all four Config files remained byte-identical, and the final target-window count was zero. Five JPEG screenshots and raw logs remain private in the ignored run directory. [Structured visible evidence](2026-10-23-live-core-visible.json) records the artifact identities and observations.

## Limits and follow-up

One actual native error was recorded: `InputMode:UIOnly - Attempting to focus Non-Focusable widget SLiveCorePanel [WarhammerClientGameMode.cpp(348)]!`. The workflow succeeded using keyboard Connect; this is not a clean-error-log claim. Later repair `d2c242d989213dc06de5a4fbb3a9ae7f493166d1` makes the panel support keyboard focus, matching the installed focus API. Its Windows Editor compile/link passed (four actions, 7.56 seconds). Fresh affected CODE/requirements reviews are pending; no repeated rendered check has run for the repair.

At the observed 3840×2160 resolution, the fixed camera cropped the near board edge. Camera movement/responsive framing remain unchecked; unplaced models were omitted. This accepts a bounded Windows local setup workflow only, not full gameplay, full board fit, durable recovery, profile compatibility, remote-product completion or Linux execution. Linux remains UNTESTED. PR #3 stays open without merge.
