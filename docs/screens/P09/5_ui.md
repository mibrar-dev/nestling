# P09 — 5_ui · UI check (iteration 1, stage 5)

Route `/quest-editor`, simulator 604697A9-11DA-462F-9837-396E9CA2493A (390×844).
Shots: `docs/screens/P09/ui/app_light_1.png`, `app_dark_1.png` (seed demo,
parent, maya, `DISABLE_ANIMATIONS=1`). Compare sheets: `cmp_light_1.png`,
`cmp_dark_1.png`. Design PNGs are 1170×2532 (@3x); all px below are logical
(design px ÷ 3). Status-bar glyphs excluded per orchestrator STATUS BAR rule
(design mock 9:41 vs OS 17:50). No Pip on this screen; no `NestChip` rows, no
`text-wrap: balance`, no `letter-spacing` (all correctly absent).

Note: `shot.sh` was run with an absolute OUT path
(`$PWD/docs/screens/P09/ui/…`) — the script `cd`s into the app dir before
`cp`, so the brief's relative OUT path fails with `cp: No such file or
directory`. Same screenshots, same flags otherwise.

## Mean diff

- Light: **1.71 %** (bands 0–7: 1.64 / 1.31 / 1.53 / 1.64 / 0.65 / 2.39 /
  2.13 / 2.32). Residual is text-antialias edges + status bar + icon glyphs.
- Dark: **1.60 %** (bands: 1.62 / 1.32 / 1.41 / 1.58 / 0.70 / 2.46 / 2.13 /
  1.56).

## Measured y (design vs app, logical px, top edge)

Best-fit uniform vertical shift over y 60–800 is **dy = 0 px** — no uniform
shift. Scanline edge transitions (thresholded luminance gradient, ±3x
sampling), design → app:

| Element | Design y | App y | Δ |
|---|---|---|---|
| Grabber (40×5) | 58.7–63.7 | 58.7–63.7 | 0 |
| Screen title `New quest` (text peaks) | 100.3 / 106.6 | 100.3 / 106.6 | 0 |
| First control: `Cancel` text box / Save pill | 90 / 80–124 | 90 / 80–124 | 0 |
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

Background/border-rect check (shapes, not text): Save pill (296/80/74/44,
Δ ≤ 0.3); name field (20/156/350/52, 0); tiles at x 20/81/142/204/265/326
(0); pills h48 anchored lefts 20/128/222 (right edges ≤ 2 wider from text
shaping, anchored edges 0); segmented track (20/480/350/52, 0) with Weekly
thumb on the third segment; day cells 44.9 wide / 50.86 pitch (≤ 0.9
cumulative, inside rule); stepper block (178/380/176/44, 0); toggle track
(303/620.5 → 354, 0); both cards (20/600/350/72 and 20/684/350/88, 0).
Side gutters exactly 20 (card edges 19.7 → 369.7 in both images, both
themes). Bottom edge: paper `[251,247,240]` at y = 830 at x = 20/195/370 in
both images — paper runs to the physical edge, no strip (OWNER bottom-edge
rule satisfied, light and dark). No overflow, clipping, or ellipsis faults
at 390 px width. Child order Maya → Leo → Anyone (creation order, correct).

Copy (visual, in order): `Cancel` · `New quest` · `Save` · `Quest name` ·
`Hoover the stairs` · `Icon` · `Who's it for?` (curly ’) · `Maya` · `Leo` ·
`Anyone` · `Reward` · `= 15p at payout` · `Repeats` · `Once` · `Daily` ·
`Weekly` · `M T W T F S S` (6th S selected, hero-bg) · `Needs my approval` ·
`Coins land after your thumbs-up` (wraps, per HTML override) · `Due by` ·
`Before tea (5pm) ›` (U+203A, ink-3). All present, all spelled/punctuated as
the HTML source. Dark-mode colours resolve via tokens throughout (cards,
tiles, pills, segmented, day cells, toggle, sheet); no hard-coded colours.

## Deviations

1. (BLOCKER — icon choice) 4 of 6 icon-picker glyphs are visibly different
   line-art from the design, in light AND dark (tile geometry itself is
   correct: 44×44, r14, 1.5 border, selected = leaf border + leaf-tint bg +
   leaf-ink glyph; only the glyph strokes differ).
   - Tile 0 `Bed`: design = flat mattress/bed-frame side view (HTML Bed
     SVG); app (`NestIcons.bed`) = lidded chest/box. Whole-tile MAE 4.5.
   - Tile 1 `Dishes`: design = handled basket (HTML Dishes SVG, reads as a
     padlock silhouette); app (`NestIcons.dishwasher`) = dishwasher/oven
     with racks. Whole-tile MAE 19.9.
   - Tile 2 `Hoover` (selected): design = canister vacuum with hose and
     wheels (HTML Hoover SVG); app (`NestIcons.hoover`) = hook/whistle-like
     loop with spout. Whole-tile MAE 20.5.
   - Tile 4 `Bins`: design = small handled case/clasp (HTML Bins SVG); app
     (`NestIcons.bin`) = rimmed trash bin. Whole-tile MAE 17.3.
   - Tiles 3 `Book` (MAE 4.1) and 5 `Paw` (MAE 1.9) match (stroke-level
     raster residue only).
   - Design value: the HTML inline-SVG glyphs shown in
     `design/screens/light|dark/P09-quest-editor.png`.
   - App value: the shared `NestIcons` glyphs listed above.
   - Fix (shared, `core/` is off-limits to this screen): redraw
     `NestIcons.bed / .dishwasher / .hoover / .bin` to match the design
     line-art (24 px, 2 px stroke, round caps). The screen-side mapping in
     `quest_editor_view.dart:230-240` is already semantically correct
     (bed→bed, dishwasher→dishwasher, hoover→hoover, book→book,
     bins→bin, paw→paw) — there is no better in-DS alternative, so the
     screen needs no code change. Filed as `SHARED_REQUEST.md` §4; blocks
     a PASS verdict until the DS glyphs land on main and are merged back.
   - A designer comparing side-by-side would reject the selected quest
     icon rendering as a different object (vacuum vs whistle-loop), so
     per the UI VERDICT RULE this is a FAIL even though every pixel of
     layout is inside ±2 px.

No other deviations. Items explicitly not findings: status-bar time/glyphs
(orchestrator rule), home-indicator pill tint (OS region), pill widths
+0.5–1.5 px and day-cell 44.9 vs 44 (anchored edges exact, inside ±2 px),
text-edge heat in the diff (antialiasing; measured text block edges ≤ 2 px).

VERDICT: FAIL
