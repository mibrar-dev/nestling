# P01 Welcome — UI check (Stage 5, iteration 2)

Simulator: 604697A9-11DA-462F-9837-396E9CA2493A (390×844, matches designs).
Shots: `shot.sh $PWD/app /welcome $PWD/docs/screens/P01/ui/app_<theme>_2.png
<udid> light|dark fresh parent maya` (absolute out path; non-interactive).
Compares: `compare.py design/screens/<theme>/P01-welcome.png
docs/screens/P01/ui/app_<theme>_2.png docs/screens/P01/ui/cmp_<theme>_2.png`.
No code edited this stage. Orchestrator overrides applied to judgement:
PipAvatar replaces the v1 SVG (slot, not artwork, is compared);
status-bar differences ignored; DB-over-mock N/A (P01 renders no numbers);
`ORCHESTRATOR_NOTES.md` items 1–2 honoured.

## Results

- Light: mean diff **3.41%**
  - band 0 (0–105): 1.58% · 1 (105–211): 0.69% · 2 (211–316): 8.41% ·
    3 (316–422): 0.17% · 4 (422–527): 5.75% · 5 (527–633): 5.58% ·
    6 (633–738): 0.39% · 7 (738–844): 4.75%
- Dark: mean diff **3.31%**
  - band 0: 1.58% · 1: 0.70% · 2: 7.63% · 3: 0.13% · 4: 5.92% ·
    5: 5.97% · 6: 0.35% · 7: 4.19%

Capture caveat: both shots exited 1 (`frame never stabilised in 25 s; saved
last capture`). Frames are still representative — headline top 445.0,
body bottom 595.0, primary top/bot 656.7/708.3 all exact vs design (see
below), matching iteration-1 stable geometry — but the instability itself
is flagged for the build stage (possible font-fetch re-layout; PipAvatar
is static under `DISABLE_ANIMATIONS`, code-verified).

Fixed since iteration 1: CTA block now exact (band 6: 30.68%/23.43% →
0.39%/0.35%; primary top 656.7 = design 656.7, h 51.7, both themes).
The shared bottom-inset double-count (old deviation 2) has landed.

## What matches

- Presence/order/copy: circle/nest/Pip-slot/3 coins, headline, body,
  primary `Get started`, ghost `I already have an account`, caption
  `Made in the UK · No ads, ever` — present, ordered, character-exact
  (em dash, UK spelling). No overflow/clipping/ellipsis at 390.
- Scene geometry: circle 320 @15/44, nest 264 @43/104, coins 40/34/36
  @16/104, 308/132, 7/241 — bands 1+3 ≤0.70%; nest/circle/coins align.
- Pip slot (mandate): `PipAvatar(style: mochi, skin: sunny-default,
  stage: 2, idle)` in the unchanged 168×168 @91/120 slot, centred on the
  nest exactly where the v1 chick sat. Artwork differs by explicit
  orchestrator order — compliant, not a deviation.
- Text metrics: headline top 445.0 (all four frames exact); body bottom
  595.0 vs 593.3 (+1.7px, within ±2px); body wraps the same 3 lines.
- CTA: top/height/side-padding exact both themes; leaf/onLeaf colours,
  pill radii, ghost transparency, caption style correct.
- Dark mode: paper/circle/button tokens flip correctly; no hard-coded
  colours. Status bar: ignored per mandate (app correctly shows only the
  OS clock now — no mock `9:41`).

## Deviations

1. Headline line break (both themes, designer-visible, P01-owned).
   Design value: `Chores that feel` / `like a game.`
   App value: `Chores that feel like` / `a game.` (orphan second line;
   drives band 4 ≈6%). Unchanged since iteration 1 across stable and
   fallback captures, so systematic, not a font-timing artifact.
   Fix: `presentation/views/welcome_view.dart` + display-style check —
   match the HTML tracking (−1%) / line-height exactly; if Flutter Nunito
   still wraps late, break to the design's two lines without altering copy.
2. Home pill ~6px low, tinted (minor, chrome).
   Design value: 134×5 ink pill centred at ≈826.7 logical.
   App value: pill centred at ≈833.3 (−6.6px), grey (light 101 vs ink 52;
   dark 76 vs 221). Drives band 7 (≈4–5%).
   Fix: disposition to build/orchestrator — likely shared bottom-chrome
   reserve and/or the iOS home bar compositing in `simctl` screenshots;
   not P01-editable if it lives in `core/**`.
3. Frame instability (process, both themes). `shot.sh` never saw two
   identical frames in 25 s. Layout measures exact, so shots stand — but
   something still repaints (suspect font-fetch re-layout; cf. bundled-fonts
   request). Fix: build stage to identify the repaint source and confirm
   RULES §6 still-frame compliance.

VERDICT: FAIL
