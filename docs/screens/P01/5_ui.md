# P01 Welcome — UI check (Stage 5, iteration 3)

Simulator: 604697A9-11DA-462F-9837-396E9CA2493A (390×844, matches designs).
Shots: `shot.sh $PWD/app /welcome $PWD/docs/screens/P01/ui/app_<theme>_3.png
<udid> light|dark fresh parent maya` (absolute out path; non-interactive).
Compares: `compare.py design/screens/<theme>/P01-welcome.png
docs/screens/P01/ui/app_<theme>_3.png docs/screens/P01/ui/cmp_<theme>_3.png`.
No code edited this stage. Orchestrator overrides applied:
PipAvatar judged by slot, not artwork; status-bar ignored; DB-over-mock N/A
(P01 renders no numbers); `ORCHESTRATOR_NOTES.md` items 1–5 honoured.

## Results

- Light: mean diff **2.73%**
  - band 0 (0–105): 1.59% · 1 (105–211): 0.67% · 2 (211–316): 8.17% ·
    3 (316–422): 0.17% · 4 (422–527): 0.56% · 5 (527–633): 5.58% ·
    6 (633–738): 0.39% · 7 (738–844): 4.75%
- Dark: mean diff **2.63%**
  - band 0: 1.59% · 1: 0.71% · 2: 7.64% · 3: 0.13% · 4: 0.59% ·
    5: 5.97% · 6: 0.35% · 7: 4.04%

Capture notes (harness, not product): the first light attempt landed on
/today (seed/redirect race, discarded), the second caught the iOS home
screen (cleanup-trap timing, discarded); the filed third frame is clean.
All four shots warned `frame never stabilised` (known harness note,
ORCHESTRATOR_NOTES #4 — not chased). Filed frames verified representative:
headline top, body bottom and button geometry all exact (below), matching
the iteration-2 stable geometry.

## What matches (element by element)

- Presence/order/copy: circle/nest/Pip-slot/3 coins, headline
  `Chores that feel like a game.`, body, primary `Get started`, ghost
  `I already have an account`, caption `Made in the UK · No ads, ever` —
  present, ordered, character-exact (em dash, UK spelling).
- Headline (ORCHESTRATOR_NOTES #3 fix verified): now breaks
  `Chores that feel` / `like a game.` in BOTH themes, matching the design;
  top 445.0 logical in all four frames (exact); band 4: 5.9% → 0.6%.
- Body: same 3-line wrap as design; bottom 595.0 vs 593.3 (+1.7px, within
  ±2px). Band 5 (~6%) is font raster only.
- Scene: circle 320 @15/44, nest 264 @43/104, coins 40/34/36 at design
  coords — bands 1+3 ≤0.71%; no overflow/clipping at 390.
- Pip slot (mandate): `PipAvatar(mochi, sunny, stage 2, idle)` in the
  unchanged 168×168 @91/120 slot, centred on the nest. Band 2 (~8%) is
  the mandated v1→v2 artwork swap alone — compliant, not a deviation.
- CTA: primary top 656.7 / bottom 708.3 / h 51.7 — exact vs design, both
  themes (band 6 ≈0.35%); side padding 21.7 vs 20.0 (+1.7px, within
  tolerance); leaf/onLeaf colours, pill radii, ghost transparency, caption
  style correct.
- Dark mode: all tokens flip correctly; no hard-coded colours.
- Status bar: app shows only the OS clock (no mock `9:41`) — the new
  contract; ignored per mandate. Home area: `NestHomeIndicator` draws
  nothing now (shared change); the pill is iOS-drawn — per
  ORCHESTRATOR_NOTES #4, not a P01 defect.

## Deviations

None. Every remaining diff is accounted for: mandated Pip artwork swap
(band 2), font raster (band 5), iOS-drawn status/home chrome (bands 0/7,
ignored per mandate). No spacing drift beyond ±2px, no wrong colours,
radii, shadows, icons, overflow or ellipsis in either theme.

VERDICT: PASS
