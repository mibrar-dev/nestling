# P09 — 5_ui · UI check (iteration 4, stage 5)

Route `/quest-editor`, simulator 604697A9-11DA-462F-9837-396E9CA2493A (390×844).
Shots: `docs/screens/P09/ui/app_light_4.png`, `app_dark_4.png` (seed demo,
parent, maya, `DISABLE_ANIMATIONS=1`). Compare sheets: `cmp_light_4.png`,
`cmp_dark_4.png`. All px below are logical (design px ÷ 3). Status-bar glyphs
excluded per orchestrator STATUS BAR rule. This pass re-checks the three
iter-3 blockers after the build applied the P09-local fixes (picker →
`questBed/questDishes/questHoover/questBins`, `toggleTrackOffset` deleted,
approval-card padding restored to `s4`). No Pip on this screen; no
`NestChip` rows, no `text-wrap: balance`, no `letter-spacing` (correctly
absent).

## Mean diff

- Light: **1.37 %** (bands 0–7: 1.67 / 0.91 / 0.69 / 1.62 / 0.65 / 1.47 /
  0.97 / 2.99; iter3 was 1.81 %). Band 2 (icons) 1.53 → 0.69, band 6
  (toggle/cards) 3.31 → 0.97.
- Dark: **1.21 %** (bands: 1.67 / 0.94 / 0.61 / 1.56 / 0.70 / 1.55 / 0.92 /
  1.71; iter3 was 1.62 %).
- Band-7 light residue (2.99; 1.89 with the home-pill zone masked) is the
  OS home-indicator pill rendering plus due-card shadow softness. The home
  zone is paper in both images (sampled y = 800/830 at x = 20/195/370:
  identical 251,247,240), so the OWNER bottom-edge rule passes.

## Measured y (design vs app, logical px, top edge)

Best-fit uniform vertical shift over y 60–800 is **dy = 0 px** — no uniform
shift.

| Element | Design y | App y | Δ |
|---|---|---|---|
| Grabber (40×5) | 58.7–63.7 | 58.7–63.7 | 0 |
| Screen title `New quest` (text peaks) | 100.3 / 106.6 | 100.3 / 106.6 | 0 |
| First control: `Cancel` box / Save pill | 90 / 80–124 | 90 / 80–124 | 0 |
| `Quest name` label | 136.8 | 136.8 | 0 |
| Name input (52 high) | 156.2 | 156.2 | 0 |
| Field text ink x | 38.3 | 37.7 | 0.6 |
| `Icon` label | 207.2 | 207.2 | 0 |
| Icon tiles (6× 44×44, x 20/81/142/204/265/326) | 232 | 232 | 0 |
| `Who's it for?` label | 276 | 276 | 0 |
| Person pills (48 high) | 300.8 | 301.0 | 0.2 |
| Reward card (inset, 76) | 363.7 | 363.7 | 0 |
| `Repeats` label | 461.0 | 461.0 | 0 |
| Segmented track (52) | 479.7 | 479.7 | 0 |
| Day row (44) | 540.2 | 540.7 | 0.5 |
| Approval card | 599.7–671.7 (h 72) | 599.7–671.7 (h 72) | 0 |
| Approval text (top→ink bottom) | 621.3→654.3 | 621.3→654.3 | 0 |
| Toggle track rect | x 303→353.7, y 621→651.7 | x 303→353.7, y 620.7→651 | ≤0.3 |
| Due-by card | 683.7–771.7 (h 88) | 683.7–771.7 (h 88) | 0 |
| `Due by` title ink top (x 37.3 both) | 722.3 | 722.3 | 0 |

Shape check (background/border rects): Save pill, name field, all six
tiles, pills (anchored lefts exact), segmented + Weekly thumb, day cells,
stepper, toggle, both cards — every rect Δ ≤ 2 px, nearly all 0. Dark-mode
card edges identical (599.7 / 645.0 / 671.7 / 683.7 / 771.7 both images).
Side gutters exactly 20 both themes. No overflow, clipping, or ellipsis
faults. Child order Maya → Leo → Anyone. Copy unchanged and matching the
HTML source (`Cancel`, `New quest`, `Save`, `Quest name`,
`Hoover the stairs`, `Icon`, `Who's it for?` with curly ’, `Reward`,
`= 15p at payout`, `Repeats`, `Once/Daily/Weekly`, `M T W T F S S` with
Saturday selected, `Needs my approval`,
`Coins land after your thumbs-up`, `Due by`, `Before tea (5pm) ›`).

Iter-3 blockers, closed with measurements:

- Icons: whole-tile MAE vs design now bed 1.4 / dishes 2.5 / hoover 10.9 /
  book 4.1 / bins 2.2 / paw 1.9. The hoover tile was dissected: interior
  glyph pixels 1073 (design) vs 1053 (app) — the path-identical asset
  renders pixel-identically; bg tint identical (229.3, 245.2, 236.3 both);
  the residue is the selected ring rendering the spec 1.5 px border while
  the browser raster shows ~1.0 px (outer rect identical, ≤ 0.7 px ring
  difference). No glyph, position, colour, or shape deviation a designer
  could see — the zoomed tiles are indistinguishable.
- Toggle: lands x 303→353.7, y ≈ 620.7→651 (design 621→651.7) — the stale
  offset is gone, no double-image in the diff.
- Cards: approval 72 again (bottom 671.7), due card 683.7–771.7, due title
  722.3 — the 4 px shifts are gone.

## Deviations

None. Every element is within ±2 px of the design position, shapes match,
icons are the exact design glyphs in the design order, dark mode matches,
and the sheet paper runs to the physical edge with 20 px gutters. Residues
(status-bar glyphs, home-indicator pill, text antialiasing, ≤ 0.7 px
selected-ring raster, card-shadow softness) are rendering-level, excluded
or invisible — no visible deviation a designer would reject.

VERDICT: PASS
