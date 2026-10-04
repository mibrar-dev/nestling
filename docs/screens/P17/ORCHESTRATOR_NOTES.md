
## UPDATE (02:08, orchestrator QA of cmp_light_1, 7.86%) — iteration 2 targets
Measured in logical px at 390×844 (design → app):
1. SCRIM / BACKDROP: the design dims (and per the HTML, maybe blurs; check the P17 HTML/CSS) the WHOLE kid screen behind the card, including the header "Hi Maya!", the coin pill and the status-bar area. The app leaves the top bright. Use a full-screen barrier (root navigator / full-route overlay) with exactly the HTML's scrim colour and blur.
2. CARD: design top 66, bottom 778 (712 tall), x 24…366. App: 53…791 (738 tall).
3. Title "Grown-ups only" line centre: design 168, app 155. Question line: design 228, app 215.
4. Answer boxes centre: design 288, app 275.
5. KEYPAD row centres: design 380 / 462 / 544 / 626 (row pitch 82), app 366 / 454 / 542 / 630 (pitch 88). Keys are 70×70 circles. Match the HTML gap.
6. "Back to Pip" centre: design 702 (app 716). Footnote: design 748 (app 762).
7. The random question and the typed digits are runtime state (not findings).
Pin 2–6 in a real-font geometry test, plus a scrim test that the barrier covers (0,0) to the full size.

## UPDATE (07:13) — the keypad layout is SHARED
NestKeypad's pitch (rows 88 / cols 96 vs design 82 / 88) is being fixed on shared/keypad_grid to match CSS `.keypad`. Do not re-space keys locally. After main has it (merged before your build), re-check the key centres against the design.

## UPDATE (09:48) — your two shared requests are being fixed on shared/kid_trial_gate
The redirect loop and the 8 kid-test reds are being fixed there. Decision: in kid mode with an expired trial, everything goes to the gate, the gate is exempt, and the parent sees the paywall after the gate. Once main has it, un-skip P17-BUG-1. Do not edit kid_home tests yourself. Fix only P17-local items this pass.
