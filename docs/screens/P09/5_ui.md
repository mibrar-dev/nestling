# P09 — 5_ui · UI check (iteration 3, stage 5)

Route `/quest-editor`, simulator 604697A9-11DA-462F-9837-396E9CA2493A (390×844).
Shots: `docs/screens/P09/ui/app_light_3.png`, `app_dark_3.png` (seed demo,
parent, maya, `DISABLE_ANIMATIONS=1`). Compare sheets: `cmp_light_3.png`,
`cmp_dark_3.png`. All px below are logical (design px ÷ 3). Status-bar glyphs
excluded per orchestrator STATUS BAR rule. Shared batch5
(`87cf5d4`: exact quest icons, 51×31 toggle, stepper U+2212, field 17 px
inset) is merged into this branch — but the P09-local follow-ups from
ORCHESTRATOR_NOTES.md 20:09 (switch picker to the `quest*` icons, delete
`toggleTrackOffset`) were NOT applied: the picker still uses
`bed/dishwasher/hoover/book/bin/paw` (`quest_editor_view.dart:293-308`)
and the `Transform.translate(toggleTrackOffset)` is still in place (:996).
No Pip on this screen; no `NestChip` rows, no `text-wrap: balance`, no
`letter-spacing` (all correctly absent).

## Mean diff

- Light: **1.81 %** (bands 0–7: 1.64 / 0.91 / 1.53 / 1.62 / 0.65 / 1.72 /
  3.31 / 3.10; iter2 was 1.79 %).
- Dark: **1.62 %** (bands: 1.65 / 0.94 / 1.41 / 1.56 / 0.70 / 1.82 / 3.06 /
  1.85; iter2 was 1.62 %).
- Improvements vs iter2: band 1 (field text now at design x), band 5
  (stepper minus now U+2212). Regression: band 6 (toggle + cards, see 2–3).

## Measured y (design vs app, logical px, top edge)

Best-fit uniform vertical shift over y 60–800 is **dy = 0 px** — no uniform
shift. Rows above the approval card are unchanged from iter1/2 (all Δ ≤ 1):

| Element | Design y | App y | Δ |
|---|---|---|---|
| Grabber (40×5) | 58.7–63.7 | 58.7–63.7 | 0 |
| Screen title `New quest` (text peaks) | 100.3 / 106.6 | 100.3 / 106.6 | 0 |
| First control: `Cancel` box / Save pill | 90 / 80–124 | 90 / 80–124 | 0 |
| `Quest name` label | 136.8 | 136.8 | 0 |
| Name input (52 high) | 156.2 | 156.2 | 0 |
| Field text ink x (orchestrator item (b)) | 38.3 | 37.7 | 0.6 ✓ |
| `Icon` label | 207.2 | 207.2 | 0 |
| Icon tiles (6× 44×44) | 232 | 232 | 0 |
| `Who's it for?` label | 276 | 276 | 0 |
| Person pills (48 high) | 300.8 | 301.0 | 0.2 |
| Reward card (inset, 76) | 363.7 | 363.7 | 0 |
| `Repeats` label | 461.0 | 461.0 | 0 |
| Segmented track (52) | 479.7 | 479.7 | 0 |
| Day row (44) | 540.2 | 540.7 | 0.5 |
| Approval card top | 599.7 | 599.7 | 0 |
| Approval TEXT (top→ink bottom) | 621.3→654.3 | 621.3→654.3 | 0 |
| Approval card bottom | 671.7 (h 72) | 667.7 (h 68) | **4** ✗ |
| Toggle track rect | x 303→353.7, y 621→651.7 | x 307→357.7, y 618.7→649 | **+4/−2.3** ✗ |
| Due-by card | 683.7–771.7 (h 88) | 679.7–767.7 (h 88) | **4 up** ✗ |
| `Due by` title ink top (x 37.3 both) | 722.3 | 718.3 | **4 up** ✗ |

Shape check otherwise unchanged: Save pill, field, tiles, pills, segmented
+ Weekly thumb, day cells, stepper — all Δ ≤ 2 (nearly all 0). Gutters
exactly 20 both themes. Bottom edge paper-to-edge both themes (home-zone
paper at y = 830). No overflow/clipping/ellipsis. Child order
Maya → Leo → Anyone. Copy unchanged and matching the HTML source.

Closed since iter2 (shared batch5, verified in these shots): field text x
(38.3 vs 37.7 — orchestrator 17:57 item (b) DONE); stepper minus U+2212
(band-5 residue 2.39 → 1.72 light); exact DS icons
`questBed/questDishes/questHoover/questBins` exist in core (not yet used).

## Deviations (all P09-local fixes; shared sides are DONE)

1. (BLOCKER — icon choice) The picker still renders the OLD glyphs:
   whole-tile MAE vs design bed 4.5 / dishes 19.9 / hoover 20.5 / book 4.1 /
   bins 17.3 / paw 1.9 — identical to iter1. (The iter-2 `basket`
   substitution is gone — correctly reverted per the look-alike ban.)
   - Design value: exact P09 SVGs (quoted in `SHARED_REQUEST.md` §4).
   - App value: `NestIcons.bed/.dishwasher/.hoover/.bin` (baseline bytes).
   - Fix (P09-local, per ORCHESTRATOR_NOTES.md 20:09 + batch5 report):
     switch `_questIcons` to `NestIcons.questBed / .questDishes /
     .questHoover / .book / .questBins / .paw` in the design order
     (`quest_editor_view.dart:291-309`). Expect tile MAEs → raster residue.

2. (BLOCKER — toggle position) The track is shifted exactly
   `toggleTrackOffset (4, −2)` off the design rect: app x 307→357.7 /
   y 618.7→649 vs design 303→353.7 / 621→651.7 (right edge 4 px past the
   content edge — visible double-image in the diff heat-map, both themes).
   Batch5 made the 51×31 track the laid-out box, so the old compensation
   now misaligns it.
   - Fix (P09-local): delete the `Transform.translate` (:996-1003, use
     bare `NestToggle`) and remove `QuestEditorMetrics.toggleTrackOffset`.
     Track must land x 303→354, y 620.5→651.5.

3. (BLOCKER — approval-card height + due-card shift) Approval card is 68
   tall, not 72 (bottom 667.7 vs 671.7; pixel-verified: app paper at
   y = 668–670 where the design is still card-white; text identical
   621.3→654.3 in both). Cause: `_approvalCard` keeps the workaround
   bottom padding `s3` (12) that compensated the OLD 44-tall toggle box
   (:969-974); with batch5's 51×31 box the row is 40 tall, so the card
   needs 16 + 40 + 16 = 72 again. The due card keeps its 88 height but
   rides 4 px high (679.7–767.7, title ink 718.3 vs 722.3) on the
   shrunken card above.
   - Fix (P09-local): restore uniform `s4` (16) card padding; due card
     and its content return to 683.7 / 722.3 with no other change.

No other deviations. Explicitly not findings: status-bar time/glyphs and
home-indicator pill rendering (OS regions), pill right-edge +0.5–1.5 px
and day-cell 44.9 vs 44 (anchored edges exact, inside ±2 px), text-edge
diff heat (antialiasing), due-card shadow-softness row at y ≈ 772.

VERDICT: FAIL
