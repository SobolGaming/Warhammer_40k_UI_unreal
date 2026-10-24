# Live Core camera and manual launcher visible run

This completed Windows run exercised the actual `scripts/Start-Client.py` launcher against a separately owned development Core. The run recorded source commit `a3ededb37f884bcd6c301367025420ec57b6bf3f`, Core commit `5f509724da25a2f6ded0c2739a8e7c84bdf59c91`, and Contract `44.3.33`. The visible client was observed for 253.2399352 seconds within its 600-second allowance. Client and launcher exited normally with code 0.

The observed workflow reached the endpoint field with Tab, reached Connect with Tab, and activated it with Space. The real initial board showed revision 1 and four offered choices. The board fit the initial 3840×2160 capture. Clicking the board and using the wheel zoomed it; wheel input over the panel, and over the board while UI controls retained focus, preserved the camera. Refresh with unchanged board bounds also preserved the zoom.

The **F shortcut remains unresolved**. Repeated attempts after board click/zoom did not visibly frame the board. This is an observed workflow failure, without a proven source cause. The **Frame board** button restored the fit. Resized captures with actual outer dimensions 2289×1335, 1602×948, and 1269×762 all showed the full board. These are captured outer dimensions, not assertions about the client area's size.

Selecting the actually offered **Fixed assassination bring_it_down** option produced revision 2 and one action reported accepted and committed. Retained Core access logs contain exactly two command POSTs (start plus this choice), one session POST, and three projection GETs. No automatic extra player action is claimed.

The manual launcher began with both development credential environment names absent; their values are excluded from this evidence. Core remained healthy after the client closed. Stopping an attached Core receipt returned `ATTACHED_NOT_STOPPED`; stopping the separately owned Core returned `STOPPED` without forced termination. All four Config files remained exact, the final observed target-window count was zero, and the root's native Error/Fatal scan counted zero.

Core stderr was not empty: it retained a pre-client readiness canceled-connection traceback with one `WinError 10053` marker. This record does not claim a completely clean server log. The launcher stderr was empty.

RMB/MMB drag, capture cancellation with Esc or application deactivation, and keyboard focus-loss cancellation have no positive graphical observation recorded in this run. A separate synthetic native Slate camera check is additional work and is not evidence for this run. The F result must remain unresolved until a proportionate follow-up establishes its behavior.

The 17 screenshots and their associated session metadata remain private. This public-safe account combines the root's direct visual observations with selected inert metadata and finite log counts; the auxiliary drafter did not inspect screenshots. It is a bounded Windows observation, with no Linux or broader migration acceptance claim. The companion JSON preserves the fact/provenance distinction and private original digests without publishing their bodies.
