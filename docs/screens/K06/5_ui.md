# K06 · Pip's nest (`/pip`) — Stage 5 UI check (iteration 3)

Simulator 604697A9-11DA-462F-9837-396E9CA2493A (390×844), `demo kid maya`.
Shots: `docs/screens/K06/ui/app_light_3.png`, `app_dark_3.png`.
Sheets: `cmp_light_3.png`, `cmp_dark_3.png` (design | app | heat-map).
Context: shared batch 7 (wardrobe glyphs, seed prices 30/60, pet slot
params, kid-button trailing row, `NestDashedBorder`) merged via main in
`ed76a69`; iteration-3 build switched the screen onto the shared pieces per
ORCHESTRATOR_NOTES (13:52). Earlier artefacts (`*_1.png`, `*_2.png`) kept.

- Light: `mean diff: 2.17%` (3.67 → 2.28 → 2.17) — bands: 0: 1.59, 1: 1.74,
  2: 2.50, 3: 0.44, 4: 1.21, 5: 2.08, 6: 3.75, 7: 4.06.
- Dark: `mean diff: 1.87%` (3.01 → 2.00 → 1.87) — bands: 0: 1.52, 1: 1.23,
  2: 2.20, 3: 0.35, 4: 1.38, 5: 2.04, 6: 3.64, 7: 2.63.
- Band 2 residual is the allowed Pip-art swap (own `PipAvatar` Mochi·sunny·3
  vs the v1 illustration per the PIP rule; note item 4 confirms Pip + nest
  correct). Nest body width matches ±1.5 px/side; slot bottom edge = design
  exactly (323.7 = 323.7).
- Band 6/7 residuals are text anti-aliasing + the OS home-indicator pill;
  no positional component (all edges Δ ≤ 1, see table).

## Measured y positions, design vs app (logical px, ÷3; ±2 px rule)

Row-edge detector (background-deviation scan, x 20–370, iteration-3 shots;
identical to iteration 2 — the shared switch moved nothing):

| Element | Design y | App y | Δ |
|---|---|---|---|
| Title `Pip · Fledgling` top / bottom | 114.0 / 132.7 | 114.0 / 132.7 | 0 |
| Growth card top border | 372.0 | 372.0 | 0 |
| Progress track top / bottom | 427.0 / 442.7 | 427.0 / 442.7 | 0 |
| Growth card bottom border | 483.0–485.7 | 483.0–485.7 | 0 |
| Care row top (Feed/Play/Bath bg rect) | 502.0 | 502.0 | 0 |
| Care row bottom | 592.7 | 592.7 | 0 (91 tall ✓) |
| Section `Pip's wardrobe` text | 618.0–627.7 | 619.0–628.7 | +1 ✓ |
| Wardrobe tile tops (all 4 share) | 651.0 | 651.0 | 0 |
| Wardrobe tile bottoms | 766.7 | 766.7 | 0 (116 tall ✓) |
| Caption text | 790.7–797.7 | 790.7–797.7 | 0 |

No uniform vertical shift. 20 px gutters everywhere; growth card, care row
and wardrobe rows share edges x20–370. Meadow runs to the physical edge; no
bar on this screen, so the BOTTOM EDGE rule passes in both themes.

Element-by-element vs design (both themes):
- Presence/order: back, lock, title, pet slot, growth card, 3 care buttons,
  section header, 4 wardrobe tiles, caption — present, in design order.
- Copy (vs HTML char-by-char): `Pip · Fledgling` (U+00B7), `Pip's wardrobe`
  (U+2019), `Nothing here is a chore — it is all just for fun.` (U+2014),
  `Growing into a Songbird`, `175 coins` / `250 to grow`, `Feed 5` / `Play`
  + `Free` pill / `Bath 3`, `Scarf`/`Sun hat` + `Owned`, `Wellies 30` /
  `Crown 60` — exact, no overflow/clipping/ellipsis.
- Shapes, not only text: growth card 350×114 with 3 px ink border r-l;
  care buttons 91 tall with full bg rects; Free pill bg rect renders;
  wardrobe tiles 116 tall with owned solid / locked dashed borders; art
  circles 52 px. All rects at design edges.
- Icon choice: scarf flag glyph, sun hat, wellies boot glyph, crown, feed
  bowl, ball, bubbles — the design's glyphs in all four tiles (2× crop
  verified light; dark sheet matches).
- Colours/radii/shadows: lilac-tint growth card, peach/sky/white care
  buttons, kid shadows, ink borders — light correct; dark correct (peach
  Feed, light-blue Play + dark Free pill, dark Bath, dark cards with light
  borders, leaf-ink Owned). No dark-only deviation.

Excluded (not deviations): OS status-bar time/icons; OS home-indicator pill
(app 831–835.7 vs design-drawn 825–829.7); Pip/nest artwork style in the
slot (PIP rule).

## Deviations

No numbered product deviations remain. Iteration-1 D1 (missing dashed
border) fixed in iteration 2 and still painting after the shared
`NestDashedBorder` switch (3 px edge verified at tile tops, both themes).
Iteration-2 D2 (look-alike glyphs) closed by shared batch 7 — the design
glyphs render in-product. Iteration-2 D3 (prices) closed by the seed move to
30/60 — the tiles show DB values 30/60, matching the design with no
hard-coded literals.

UI VERDICT RULE audit: every element within ±2 px (all structural Δ 0,
section +1). No uniform shift. No visible deviation a designer would reject
in either theme.

VERDICT: PASS
