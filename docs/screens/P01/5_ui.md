# P01 Welcome — UI check (Stage 5, iteration 1)

Simulator: 604697A9-11DA-462F-9837-396E9CA2493A (390×844, matches designs).
Shots: `shot.sh $PWD/app /welcome <out> <udid> light|dark fresh parent maya`
(non-interactive; absolute out path — relative out fails after the script's
`cd $APP_DIR`). Compares: `compare.py design/screens/<theme>/P01-welcome.png
docs/screens/P01/ui/app_<theme>_1.png docs/screens/P01/ui/cmp_<theme>_1.png`.
No code edited this stage.

## Results (clean frames)

- Light: mean diff **6.89%**
  - band 0 (0–105): 1.32% · 1 (105–211): 0.21% · 2 (211–316): 0.18% ·
    3 (316–422): 0.12% · 4 (422–527): 5.75% · 5 (527–633): 11.47% ·
    6 (633–738): 30.68% · 7 (738–844): 5.51%
- Dark: mean diff **5.92%**
  - band 0: 1.23% · 1: 0.20% · 2: 0.16% · 3: 0.08% · 4: 5.92% ·
    5: 11.23% · 6: 23.43% · 7: 5.20%

Note: the first light capture (mean 13.22%, bands 1–3 up to 18.7%) was
scrolled ~25px (headline top 420 vs design 445, body bottom 570 vs 593.3).
Retook once; the retake is the filed `app_light_1.png` (headline 445.0 =
design 445.0, body bottom 595.0 vs 593.3). Bands 1–3 ≤0.21% confirm the
illustration is pixel-aligned; remaining bands 4–6 are real deviations below.

## What matches (element by element)

- Presence/order/copy: status bar 9:41, circle/nest/Pip/3 coins, headline,
  body, primary `Get started`, ghost `I already have an account`, caption
  `Made in the UK · No ads, ever` — all present, in order, character-exact
  (em dash and UK spelling preserved).
- Scene: 350×388 geometry, circle 320 @15/44, nest 264 @43/104, Pip 168
  @91/120, coins 40/34/36 @16/104, 308/132, 7/241 — bands 1–3 ≤0.21%,
  no overflow/clipping at 390.
- Colours (sampled, full-res): paper, leafTint circle, leaf/onLeaf button
  all exact in both themes (light leaf 23,128,79; dark leaf 60,201,138).
  Dark-mode tokens flip correctly; no hard-coded colours.
- Body text: same 3-line wrap as design; bottom 595.0 vs 593.3 (+1.7px,
  within ±2px). Side padding: button left 21.7 vs 20.0 (+1.7px, within
  tolerance); button height 51.7 vs 52 (−0.3px). Radii (pill), ghost
  transparency, caption style correct. No ellipsis/clipping at 390.

## Deviations

1. Headline line break (both themes, designer-visible).
   Design value: `Chores that feel` / `like a game.`
   App value: `Chores that feel like` / `a game.` (orphan second line;
   drives band 4 ≈6%).
   Fix (P01-editable, `presentation/views/welcome_view.dart` + display
   style check): headline keeps full 350 width yet fits more per line than
   the HTML — suspect missing −1% letter-spacing and/or Nunito metric
   delta. Match the HTML tracking/line-height exactly; if Flutter still
   wraps late, constrain the headline box or break to the design's two
   lines without altering copy.
2. Bottom-CTA block ~33px too high (both themes, designer-visible).
   Design value: primary top 656.7 logical, button h 51.7.
   App value: primary top 623.3 logical (−33.4px), button h 51.7 (correct);
   ghost/caption shift with the block; internals otherwise correct.
   Drives band 6 (23–31%).
   Fix: SHARED_REQUEST (P01 must not touch `core/**`): `NestBottomCta`
   wraps `SafeArea(top:false)` (bottom inset live) AND `NestHomeIndicator`
   adds 34 below it — the OS bottom inset is counted twice. Drop the
   redundant bottom safe padding when the home indicator follows so the
   block top returns to ~657.
3. Screenshot chrome double-render (harness artifact, not app UI, both
   themes). Design value: single `9:41` + icon row; single 134×5 pill.
   App shot value: faint OS time `00:38` overlapping `9:41`, doubled
   signal/wifi/battery glyphs; doubled home pill (Flutter + iOS bar).
   Drives bands 0/7 (≈1–5%). Fix: none in P01 code (`NestStatusBar` /
   `NestHomeIndicator` match spec §1); note only — `simctl io screenshot`
   captures the OS status/home bars over the mock.
4. (Carried, not re-probed at 390) Stage-4 blocker still open:
   scene `Transform.scale` crops (not scales) below 390dp
   (`welcome_view.dart:91-104`; 320dp coin fully clipped). Invisible at
   this stage's 390 width but keeps the branch red until fixed.

VERDICT: FAIL
