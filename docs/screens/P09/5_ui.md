# P09 — 5_ui · UI check (iteration 2, stage 5)

Route `/quest-editor`, simulator 604697A9-11DA-462F-9837-396E9CA2493A (390×844).
Shots: `docs/screens/P09/ui/app_light_2.png`, `app_dark_2.png` (seed demo,
parent, maya, `DISABLE_ANIMATIONS=1`). Compare sheets: `cmp_light_2.png`,
`cmp_dark_2.png`. All px below are logical (design px ÷ 3). Status-bar glyphs
excluded per orchestrator STATUS BAR rule. Mandatory orchestrator items from
`ORCHESTRATOR_NOTES.md` (17:57 QA) are checked as items (a) and (b) below.
No Pip on this screen; no `NestChip` rows, no `text-wrap: balance`, no
`letter-spacing` (all correctly absent).

## Mean diff

- Light: **1.79 %** (bands 0–7: 1.66 / 1.31 / 1.49 / 1.64 / 0.65 / 2.39 /
  2.13 / 2.99; iter1 was 1.71 %).
- Dark: **1.62 %** (bands: 1.65 / 1.32 / 1.37 / 1.58 / 0.70 / 2.46 / 2.13 /
  1.71; iter1 was 1.60 %).
- Band-7 light delta (+0.67) is the OS home-indicator pill rendering darker
  in this capture plus due-card shadow softness at y ≈ 772 (app paper
  251,247,240 vs design shadow greys 232,228,225 on that single row). The
  home zone itself is paper in both (sampled y = 830 at x = 20/195/370:
  identical), so the OWNER bottom-edge rule still passes in both themes.

## Measured y (design vs app, logical px, top edge)

Best-fit uniform vertical shift over y 60–800 is **dy = 0 px** — no uniform
shift. Centre-scanline edges (x = 195), design → app:

| Element | Design y | App y | Δ |
|---|---|---|---|
| Grabber (40×5) | 58.7–63.7 | 58.7–63.7 | 0 |
| Screen title `New quest` (text peaks) | 100.3 / 106.6 | 100.3 / 106.6 | 0 |
| First control: `Cancel` box / Save pill | 90 / 80–124 | 90 / 80–124 | 0 |
| `Quest name` label | 136.8 | 136.8 | 0 |
| Name input (52 high) | 156.2 | 156.2 | 0 |
| `Icon` label | 207.2 | 207.2 | 0 |
| Icon tiles (6× 44×44) | 232 | 232 | 0 |
| `Who's it for?` label | 276 | 276 | 0 |
| Person pills (48 high) | 300.8 | 301.0 | 0.2 |
| Reward card (inset, 76) | 363.7 | 363.7 | 0 |
| `Repeats` label | 461.0 | 461.0 | 0 |
| Segmented track (52) | 479.7 | 479.7 | 0 |
| Day row (44) | 540.2 | 540.7 | 0.5 |
| Approval card (72) | 599.7 | 599.7 | 0 |
| Due-by card (88) | 683.7 | 683.7 | 0 |
| Due-card bottom edge | 771.7 | 771.7 | 0 |

Shape check (background/border rects): Save pill, name field
(20/156/350/52), tiles at x 20/81/142/204/265/326, pills (anchored lefts
exact; right edges ≤ 2 wider from text shaping), segmented + Weekly thumb,
day cells (44.9 wide / 50.86 pitch, ≤ 0.9 cumulative), stepper, toggle track
(303/620.5 → 354), both cards — all Δ ≤ 2 px, nearly all 0. Gutters exactly
20 (card edges 19.7 → 369.7, both images, both themes). No overflow,
clipping, or ellipsis faults. Child order Maya → Leo → Anyone (correct).
Copy unchanged from iter1 and matching the HTML source character-for-
character (curly ’ in `Who's`, `Before tea (5pm) ›` with U+203A).

## Deviations

1. (BLOCKER — icon choice; orchestrator 17:57 item (a)) 4 of 6 icon-picker
   glyphs are visibly different line-art from the design, light AND dark
   (tile geometry correct; only glyph strokes differ). Whole-tile MAE vs
   design: tile 0 Bed 4.5, tile 1 Dishes 17.5, tile 2 Hoover 20.5,
   tile 3 Book 4.1 (match), tile 4 Bins 17.3, tile 5 Paw 1.9 (match).
   - Tile 0 `Bed`: design flat mattress/bed-frame side view; app
     `NestIcons.bed` = lidded chest/box.
   - Tile 1 `Dishes`: design handled basket; app now `NestIcons.basket`
     (tapered slatted basket, substituted in the iter-2 build for
     `NestIcons.dishwasher`). The substitution violates the mandatory
     orchestrator instruction ("write SHARED_REQUEST … rather than
     substituting a look-alike"): the basket is visibly a different
     drawing (plain body + arch handle vs slats + side handles, MAE 17.5)
     and must be replaced with the exact design glyph, not kept.
   - Tile 2 `Hoover` (selected): design canister vacuum + hose + wheels;
     app `NestIcons.hoover` = hook/whistle-like loop.
   - Tile 4 `Bins`: design small handled case/clasp; app `NestIcons.bin` =
     rimmed trash bin.
   - Design value: exact SVGs in `design/html-source/screens/P09-quest-
     editor.html` (copied verbatim into `SHARED_REQUEST.md` §4).
   - App value: the `NestIcons` glyphs listed above.
   - Fix (shared, `core/` off-limits here): draw the four exact design
     glyphs as DS icons/assets; screen mapping stays as-is (order Bed,
     Dishes, Hoover, Book, Bins, Paw is already the design order).
     `SHARED_REQUEST.md` §4 updated with exact names + SVG sources; blocks
     PASS until the DS glyphs land on main and are merged back.

2. (Shared-cause advisory — field text x; orchestrator 17:57 item (b),
   filed as `SHARED_REQUEST.md` §6, non-blocking) `Hoover the stairs` ink
   starts at x ≈ **41.7** in the app vs **38.3** in the design (leftmost
   dark pixel, field-text band y 168–200; same y-top 176.3). Design
   arithmetic: field x 20 + 1 px border + 16 px padding = 37 (+ `H` side
   bearing ≈ 38.3 measured). The field BOX is exact (20/156/350/52, edges
   19.7 → 369.7) and the screen passes no padding to `NestTextField`
   (plain label + controller, `quest_editor_view.dart:592-596`): the ~3.4 px
   excess is the shared default variant's uncancelled editable inset
   (`contentPadding: horizontal s4` without `isDense`,
   `nest_text_field.dart:303-306`; the search variant in the same file
   cancels it with `left: -4`). Invisible without pixel measurement — a
   designer would not reject it — so it stays advisory per §6; recorded
   here because the orchestrator asked for the numbers.

No other deviations. Explicitly not findings: status-bar time/glyphs and
home-indicator pill rendering (OS regions), pill right-edge +0.5–1.5 px
and day-cell 44.9 vs 44 (anchored edges exact, inside ±2 px), text-edge
diff heat (antialiasing; block edges ≤ 2 px), due-card shadow-softness row
at y ≈ 772 (single-row painting residue, no layout effect).

VERDICT: FAIL
