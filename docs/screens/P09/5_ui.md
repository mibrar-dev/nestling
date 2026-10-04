# P09 — 5_ui · UI check (iteration 5, stage 5)

Route `/quest-editor`, simulator 604697A9-11DA-462F-9837-396E9CA2493A (390×844).
Shots: `docs/screens/P09/ui/app_light_5.png`, `app_dark_5.png` (seed demo,
parent, maya, `DISABLE_ANIMATIONS=1`). Compare sheets: `cmp_light_5.png`,
`cmp_dark_5.png`. All px below are logical (design px ÷ 3). Status-bar glyphs
excluded per orchestrator STATUS BAR rule. Per ORCHESTRATOR_NOTES.md 00:25
(QA of cmp_light_4): layout and icons match the design; the single iter-5
item is P09-TEST-6 (coin-guard assert text leaking into the toast — a
test-stage matter, no toast is visible in these shots, out of scope here).
No Pip on this screen; no `NestChip` rows, no `text-wrap: balance`, no
`letter-spacing` (correctly absent).

## Mean diff

- Light: **1.38 %** (bands 0–7: 1.70 / 0.91 / 0.69 / 1.62 / 0.65 / 1.47 /
  0.97 / 2.99; iter4 was 1.37 % — unchanged).
- Dark: **1.21 %** (bands: 1.65 / 0.94 / 0.61 / 1.56 / 0.70 / 1.55 / 0.92 /
  1.71; iter4 was 1.21 % — unchanged).
- Band-7 light residue is the OS home-indicator pill + card-shadow
  softness (1.89 with the pill zone masked). Home zone is paper in both
  images, so the OWNER bottom-edge rule passes in both themes.

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
| Toggle track rect | x 303→353.7, y 621→651.7 | x 303→353.7, y 620.7→651 | ≤0.3 |
| Due-by card | 683.7–771.7 (h 88) | 683.7–771.7 (h 88) | 0 |
| `Due by` title ink top (x 37.3 both) | 722.3 | 722.3 | 0 |

Shape check: every pill, tile, segmented thumb, day cell, stepper block,
card and the Save pill rect Δ ≤ 2 px (nearly all 0); dark-mode card edges
identical to light. Icon tiles: whole-tile MAE bed 1.4 / dishes 2.5 /
hoover 10.9 / book 4.1 / bins 2.2 / paw 1.9 — iter4 proved the hoover
residue is sub-pixel selected-ring raster (interior glyph pixels 1073 vs
1053, bg tint identical, path-identical asset), not a shape deviation.
Side gutters exactly 20 both themes. No overflow, clipping, or ellipsis
faults. Child order Maya → Leo → Anyone. Copy matches the HTML source
character-for-character.

## Deviations

None. No visible deviation a designer would reject; no regression from
iter4 (all numbers identical within raster noise). P09-TEST-6 is noted
for the test stage and is not verifiable from UI screenshots.

VERDICT: PASS
