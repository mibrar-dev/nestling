# K06 · Pip's nest (`/pip`) — Stage 5 UI check (iteration 4)

Simulator 604697A9-11DA-462F-9837-396E9CA2493A (390×844), `demo kid maya`.
Shots: `docs/screens/K06/ui/app_light_4.png`, `app_dark_4.png`.
Sheets: `cmp_light_4.png`, `cmp_dark_4.png` (design | app | heat-map).
Context: iteration-4 build rewrote the view onto the shared pieces
(`NestDashedBorder`, shared pet-slot params, shared kid-button trailing
row, `wardrobeScarf/wardrobeWellies` glyphs, seed prices 30/60), so this is
a full re-check, not a delta check. Earlier artefacts (`*_1..3.png`) kept.

- Light: `mean diff: 2.13%` — bands: 0: 1.57, 1: 1.74, 2: 2.52, 3: 0.44,
  4: 1.08, 5: 2.02, 6: 3.60, 7: 4.04.
- Dark: `mean diff: 1.84%` — bands: 0: 1.57, 1: 1.23, 2: 2.22, 3: 0.35,
  4: 1.24, 5: 1.98, 6: 3.50, 7: 2.67.
- Band 2 residual is the allowed Pip-art swap (own `PipAvatar` Mochi·sunny·3
  vs the v1 illustration per the PIP rule; ORCHESTRATOR_NOTES item 4
  confirms Pip + nest correct).
- Band 6/7 residuals are text anti-aliasing, glyph stroke raster and the OS
  home-indicator pill; no positional component (all edges Δ ≤ 1, see table).

## Measured y positions, design vs app (logical px, ÷3; ±2 px rule)

Row-edge detector (background-deviation scan, x 20–370, iteration-4 shots;
unchanged from iterations 2–3 — the shared-component rewrite moved nothing):

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
  care buttons 91 tall with full bg rects (shared trailing row renders coin
  5 / Free pill / coin 3 exactly as before); Free pill bg rect renders;
  wardrobe tiles 116 tall, owned solid + locked dashed (`NestDashedBorder`
  paints in both themes); art circles 52 px.
- Icon choice: design scarf flag glyph, sun hat, wellies boot glyph, crown,
  feed bowl, ball, bubbles — correct in all tiles and buttons, both themes
  (kid audience glyphs per the ICONS rule; K06 design glyphs match).
- Colours/radii/shadows: lilac-tint growth card, peach/sky/white care
  buttons, kid shadows, ink borders — light correct; dark correct (peach
  Feed, light-blue Play + dark Free pill, dark Bath, dark cards with light
  borders, leaf-ink Owned). No dark-only deviation.

Excluded (not deviations): OS status-bar time/icons; OS home-indicator pill
(app 831–835.7 vs design-drawn 825–829.7); Pip/nest artwork style in the
slot (PIP rule).

## Deviations

No numbered product deviations. The shared-component rewrite preserved every
measured position and every previously closed item (dashed borders, design
glyphs, DB prices 30/60 with no hard-coded literals).

UI VERDICT RULE audit: every element within ±2 px (all structural Δ 0,
section +1). No uniform shift. No visible deviation a designer would reject
in either theme.

VERDICT: PASS
