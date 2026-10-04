# P09 — 5_ui · UI check (iteration 6, stage 5)

Route `/quest-editor`, simulator 604697A9-11DA-462F-9837-396E9CA2493A (390×844).
Shots: `docs/screens/P09/ui/app_light_6.png`, `app_dark_6.png` (seed demo,
parent, maya, `DISABLE_ANIMATIONS=1`). Compare sheets: `cmp_light_6.png`,
`cmp_dark_6.png`. All px below are logical (design px ÷ 3). Status-bar glyphs
excluded per orchestrator STATUS BAR rule. Since iter4 the only merged
change is shared/unique_ids (quest ids via `newId`, no visual surface), and
ORCHESTRATOR_NOTES.md adds no new UI item for this pass (09:27 covers
BUG-P09-14 id generation — data layer, not pixels; P09-TEST-6 remains
test-stage scope). No Pip on this screen; no `NestChip` rows, no
`text-wrap: balance`, no `letter-spacing` (correctly absent).

## Mean diff

- Light: **1.29 %** (bands 0–7: 1.66 / 0.91 / 0.69 / 1.62 / 0.65 / 1.47 /
  0.97 / 2.32; iter5 was 1.38 % — same within capture noise; band 7 fell
  2.99 → 2.32 on home-pill rendering variance alone).
- Dark: **1.19 %** (bands: 1.64 / 0.94 / 0.61 / 1.56 / 0.70 / 1.55 / 0.92 /
  1.56; iter5 was 1.21 % — unchanged).
- Residue is text antialiasing, card-shadow softness, and the OS
  home-indicator pill. Home zone is paper in both images (y = 800/830 at
  x = 195: identical 251,247,240), so the OWNER bottom-edge rule passes.

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
card and Save pill rect Δ ≤ 2 px (nearly all 0). Icon tiles: whole-tile
MAE bed 1.4 / dishes 2.5 / hoover 10.9 / book 4.1 / bins 2.2 / paw 1.9 —
iter4 dissected the hoover residue (interior glyph pixels 1073 vs 1053,
identical bg tint, path-identical asset; remainder is ≤ 0.7 px
selected-ring raster, outer rect identical). Side gutters exactly 20 both
themes. No overflow, clipping, or ellipsis faults. Child order
Maya → Leo → Anyone. Copy matches the HTML source character-for-character.

## Deviations

None. No visible deviation a designer would reject; numbers identical to
the passing iter4/iter5 within raster noise. The unique_ids merge has no
visual surface; BUG-P09-14 and P09-TEST-6 are non-visual stages' scope.

VERDICT: PASS
