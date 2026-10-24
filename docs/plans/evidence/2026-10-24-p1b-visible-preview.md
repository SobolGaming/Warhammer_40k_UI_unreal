# P1b packaged Windows preview — bounded visible checks

2026-10-24. **Bounded visible preview PASS with limits.** This supporting record covers three observed workflows, not full P1 or complete gameplay. The [canonical plan](../unreal-migration-plan.md) owns the broader disposition. Source was `388b4fda24ad3bbdb5b5d92c799de9a2c2a71cee`, using the same outside-checkout Game executable as the [non-visible checks](2026-10-24-p1b-native-checks.md): 332,414,464 bytes, SHA256 `64EC651358C60880B24841FFF3B5818CABFDC7CB3865E2F3462D2D13AE2EDD9A`.

Runtime Core remained `5f509724da25a2f6ded0c2739a8e7c84bdf59c91` / 44.3.33. Fetched `4f9bef0df2fb974d1285232a1009b8781926361d` / 44.5.0 remains an unmerged planning candidate; these runs do not verify it. See the [source-review record](2026-10-24-p1b-source-reviews.json) and [native provenance](2026-10-24-p1b-native-checks.json) for separate supporting evidence.

## Completed workflows

The coordinator used supported Sky/ComputerUse APIs against the actual packaged client and `Start-Client.ps1` Managed/Attach routes. The standing visible authorization was active; application access was approved before the successful retries. This evidence author reconciled saved observations and results without controlling the UI or opening the images.

| Workflow | Actual UI result | Game lifetime seconds | Close and Core ownership |
|---|---|---:|---|
| Managed preview | Connect/create; first offered fixed secondary-mission choice submitted; accepted and committed, one player action, revision 2; explicit Refresh and truthful hidden-decision explanation. | 164.3269328 | Game and launcher exit 0 normally. Managed Core stopped normally, without forced termination. |
| Attach preview | Connect/create; offered Tactical secondary-mission choice submitted; accepted and committed, one player action, revision 2; explicit Refresh and hidden-decision explanation. Board/fonts readable. | 57.2529535 | Game and launcher exit 0. Attached service survived, HTTP200 after client close; Attach Stop was a no-op, then its separate owner stopped it normally. |
| Attach HTTP diagnostic | Intentionally invalid child viewer credential produced **HTTP401**, `authentication_required`: **“A valid bearer credential is required.”** Projection unavailable, zero accepted player actions, no invented board or finite options. The admin start command had committed before projection failed. | 56.2751614 | Game and launcher exit 0. Attached service survived with HTTP200; separate owner stopped it normally. No credential value was retained. |

All three closed runs record the same binary before/after, four Config files unchanged, parent environment restored, complete launcher streams, no forced Game/launcher cleanup and confirmed Core cleanup. Normal-close conclusions come from the later closed supervisor receipts; the earlier UI observation snapshots still say `REQUESTED_NEXT` and are preserved as such. Native logs retain two startup warnings (unspecified spawn class and light mobility), with zero Error/Fatal severity lines. This does not erase the actual displayed HTTP401 or claim diagnostically empty logs.

## Managed camera, focus and framing observations

The actual board, terrain, objectives and fonts were readable. Board focus help changed with keyboard focus. Wheel input zoomed the board; `press_key('f')` restored the full frame after zoom. F with UI focus and wheel over the panel left the camera unchanged. Explicit same-bounds Refresh preserved the zoom, and **Frame board** restored the fit. This was OS-injected key input, not a claim about a human physical keyboard.

Captured window dimensions were **2882×1668 → 3840×2088 → 2882×1668** through native Maximize and Restore. A separate stable maximized capture supported the readable full-board observation. The first corner drag did **not** change size: the retained `managed-resized-frame` label is misleading and is not used as resize proof. The maximization transition showed a ghost/transition frame and is excluded from stable-render evidence. These dimensions describe captures, not independently measured client viewport extents.

Twenty captures remain private. The [JSON record](2026-10-24-p1b-visible-preview.json) publishes their existing labels/dimensions and file-metadata byte lengths, plus the capture-manifest digest; it embeds no images, private capture IDs or paths. This author did not read or rehash PNG bodies. No gameplay model was placed or moved; undeployed models remain unplaced.

## Preserved failed attempts

| Earlier attempt | Actual failure and cleanup disposition |
|---|---|
| Initial supervisor attempt | Failed before a Game identity or useful observation was captured; launcher cleanup was forced. The original result retains `coreCleanupConfirmed=false` and `parentEnvironmentRestored=false`. A later agent checked the retained process identities as already absent; the existing Stop helper then returned STOPPED without forced termination. That follow-up is separate evidence and does not rewrite the original flags or infer environment restoration. No fresh native log was captured. |
| Application-access timeout | Failed while app-access approval timed out. The nominal 600-second visible budget expired; observed Game lifetime was 600.3487009 seconds, including about 0.35 seconds of polling overshoot. The Game was forced closed and Core cleanup was confirmed. The original failure remains a failure despite the later approval and successful retries. |

The process supervisor alone does not establish UI success. Its five original results, raw-stream/native-log descriptors, final Core receipt descriptors and later first-attempt cleanup receipt are preserved in the machine-readable record. Private bodies, identities, accounts and credentials are not published.

## Remaining limits

No supported held-button API was available, so this run does not verify real held RMB orbit/MMB pan. OS application switching, adversarial/world teardown acceptance, Linux and clean-machine delivery remain unverified. Normal close is narrower than teardown robustness. The earlier manual F failure remains an unchanged historical outcome; current injected-F success is new bounded evidence. These mission choices, limited state presentation and camera checks do not establish deployment, movement, attacks, a full battle, all Core families or complete P1 acceptance.
