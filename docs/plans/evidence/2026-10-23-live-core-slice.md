# Live Core slice progress

The active plan prioritizes a useful rendered client driving the existing Core. Implementation and verification remain separate; no rendered acceptance is claimed during the owner's screen HOLD.

## Source checkpoint and first build

Source checkpoint `b630d46a97a88f8a77ef8c2a9bfd1b287d3bf0a5` was pushed and its exact GitHub branch ref verified. Three PowerShell AST checks and 48 documentation links passed before the build.

The first Windows Development Editor build failed with exit6 (76.79seconds). The new session adapter passed JSON map keys to an FString-only helper, while UE5.8 uses shared-string key storage (C2664 in four locations). The unit-test context mask used a nonexistent qualified enum member (C2838/C2065 and consequent C2131). The default GameMode and latent integration test translation units compiled; no native functional tests ran.

The focused repair uses explicit case-sensitive FStringView key comparisons and the existing EAutomationTestFlags_ApplicationContextMask constant. Rebuild and functional results remain pending. Private build logs are retained under `.local/development/live-core-b630d46/`; credentials and generated outputs are excluded from Git.

No Editor/Game GUI or desktop input was used. Linux remains UNTESTED; profile/727/broad certification remains deferred. PR#3 stays open without merge.

## Rebuild and startup-path correction

The repaired `0bea8f2` Windows Editor build succeeded (exit0,12.15seconds, five actions). MSVC emitted a C4701 warning for a parser output variable; it is now explicitly initialized while missing/invalid fields still fail parsing.

The first headless functional attempt stopped before launching Core or Unreal: two Git executables were discoverable on PATH and the PowerShell helper treated their combined paths as one executable. The helper now deterministically selects the first Application match. Private record: `.local/development/live-core-functional-20261023T232318Z/result.json`. This startup failure supplies no native functional result; a fresh check is required.

The `eabf6e6` rebuild succeeded (exit0,8.68seconds) without the new diameter warning. The next functional attempt exceeded the helper's 30-second readiness budget while verifying the installed Core. Its runtime-verification and own bind markers arrived during graceful shutdown; both owned processes stopped without forced termination. No Unreal test process started. Record: `.local/development/live-core-functional-20261023T232351Z/result.json` and its owned host receipt. The default development readiness budget is now60seconds; the original timeout remains failed and a fresh functional check is pending.

## First native execution and portable checksum repair

At `9c1dbb9`, managed readiness and authenticated Attach both passed; stopping the attachment returned ATTACHED_NOT_STOPPED. Native NullRHI/unattended automation then crashed (exit3) on the first session-create fixture checksum: the installed Windows FPlatformMisc::GetSHA256Signature falls through to the generic assertion, "No SHA256 Platform implementation". This is a client API-selection defect, not a Core server error. No real player action completed and the unit tests did not finish. The owned Core service stopped gracefully without force. Private run: `.local/development/live-core-functional-20261023T232501Z/`.

The repair uses portable Core FSHA1 plus exact222673-byte fixture size as an internal consistency check. The independently recorded fixture SHA256 remains2B1DB622C7C09F8A982B515A8BE932AFA38AF8A9383CF491996C2CB26A9627B0; authoritative session and runtime build checks remain unchanged. This checksum does not authenticate untrusted assets. Fresh build/native tests remain pending.

The next non-graphical test adds RenderOffScreen, whose installed Slate implementation creates a generic dummy window instead of an OS window, and bounded owned-window observations. The earlier process had already exited before a requested finite visibility observation; no continuous window-absence result is claimed. No desktop input or approved visible test was performed.

## Headless functional success and packet correction

Native C++ source `42a5bdb` built successfully (exit0,8.78seconds). Run `20261023T232738Z` completed all six tests: five protocol units and the actual Core session/action integration (six succeeded, zero failed/warnings/not-run,12.216835seconds total test duration). The real-action test created/started a canonical session, read player-a's board, submitted the offered secondary-mission choice, observed accepted/committed and revision+1, hid opposing private options and refreshed without another mutation. Managed and Attach checks passed, attachment Stop was a no-op, and managed Stop was graceful. Fifty-seven finite owned-window observations returned zero visible windows (maximum interval0.5157429seconds); this is not continuous absence proof.

The Editor also auto-wrote an AndroidFileServer section to DefaultEngine.ini and created DefaultInput.ini. This means the run's runtime configuration includes generated settings beyond the committed Config. The generated Android section included an unused development security token; root mistakenly copied it into the first independent-review input. Both review processes were stopped and their contexts invalidated without admitting verdicts. The generated files were preserved privately, tracked Config was restored from its verified pre-test copy, and only the preserved test-created input file was removed. No GitHub or Core credential was included in that packet.

AndroidFileServer and EnhancedInput are now explicitly disabled in the project: neither is used by this fixed-camera Slate client or its existing E02 input code. This prevents their unsolicited startup Config migrations. Fresh build/tests and fresh exact-Git snapshot reviews remain pending. The earlier review input/output is private and inadmissible; do not resume it or reuse its conclusions. The six-test result remains factual, with the configuration qualification above.

At `5b0adde`, the Editor build passed (exit0,3.54seconds), all six native tests passed again (zero failures/warnings,12.73 seconds total), and the original three Config files remained byte-identical. The check correctly reported CONFIG_MUTATED_PRESERVE_RESULTS because standard DefaultInput.ini was created; no AndroidFileServer section/token was generated. Both owned-review contexts are confirmed closed (exit-1, no final report) and provide no verdict.

The standard input configuration is now explicitly tracked, using Engine.PlayerInput/InputComponent and disabling automatic mouse capture/locking for the fixed-camera Slate UI. It no longer relies on an auto-created file or unavailable EnhancedInput classes. A final focused run will compare all four Config files. This is ordinary startup configuration, not a rendering/input acceptance claim; visible tests remain on HOLD.

The `c2f67fc` run passed all six native checks again but detected the Editor replacing those base input classes with EnhancedInput classes. The installed Editor still mounts EnhancedInput through its dependencies despite the explicit disabled reference; its input-class migration is directly observed. The project now explicitly enables the standard plugin and retains its canonical input classes, while keeping automatic mouse capture/locking disabled. AndroidFileServer remains disabled and its generated credential section stayed absent. The preceding input-class proposal is superseded; fresh Config-preserving validation and reviews follow.
