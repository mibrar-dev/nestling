# K06 · Pip's nest (`/pip`) — Stage 5 UI check (iteration 1)

Simulator 604697A9-11DA-462F-9837-396E9CA2493A (390×844), `demo kid maya`.
Shots: `docs/screens/K06/ui/app_light_1.png`, `app_dark_1.png`.
Sheets: `cmp_light_1.png`, `cmp_dark_1.png` (design | app | heat-map).

- Light: `mean diff: 3.67%` — bands: 0: 1.53, 1: 1.74, 2: 12.05, 3: 1.34,
  4: 1.21, 5: 2.39, 6: 4.48, 7: 4.65.
- Dark: `mean diff: 3.01%` — bands: 0: 1.55, 1: 1.23, 2: 9.41, 3: 0.63,
  4: 1.38, 5: 2.34, 6: 4.35, 7: 3.27.
- Band 2 (y 211–316, pet art) is high in both themes: expected — the design
  shows the v1 `pip-stage-3.svg` illustration, the app renders the child's
  own `PipAvatar` (Mochi·sunny·stage 3) per the orchestrator PIP rule.
- Band 6 (y 633–738, wardrobe) glow is deviation D1 below, not art.

## Measured y positions, design vs app (logical px, ÷3; ±2 px rule)

Row-edge detector (background-deviation scan, x 20–370, full-height PNGs):

| Element | Design y | App y | Δ |
|---|---|---|---|
| Title `Pip · Fledgling` top | 114.0 | 114.0 | 0 |
| Title block bottom | 132.7 | 132.7 | 0 |
| Growth card top border | 372.0 | 372.0 | 0 |
| Progress track top/bottom | 427.0 / 442.7 | 427.0 / 442.7 | 0 |
| Growth card bottom border | 483.0–485.7 | 483.0–485.7 | 0 |
| Care row top (Feed/Play/Bath bg rect) | 502.0 | 502.0 | 0 |
| Care row bottom | 592.7 | 592.7 | 0 (91 tall ✓) |
| Section `Pip's wardrobe` text | 618.0–627.7 | 619.0–628.7 | +1 ✓ |
| Wardrobe tile tops (all 4 share) | 651.0 | 651.0 | 0 |
| Wardrobe tile bottoms | 766.7 | 766.7 | 0 (116 tall ✓) |
| Caption text | 790.7–797.7 | 790.7–797.7 | 0 |
| Nest body width at y=300 | 155.0 | 158.3 | +3 total, ±1.5/side ✓ |
| Growth card widths/borders | identical | identical | 0 |

No uniform vertical shift. Gutters: back box x20, lock box right x370,
growth card x20–370, care/wardrobe rows x20–370 in both. Meadow runs to the
physical edge under the caption; no bar on this screen, so the BOTTOM EDGE
rule is satisfied (no strip under any bar in either theme).

Copy (character-exact vs HTML): `Pip · Fledgling` (U+00B7), `Pip's wardrobe`
(U+2019), `Nothing here is a chore — it is all just for fun.` (U+2014),
`175 coins` / `250 to grow`, `Feed 5` / `Play Free` / `Bath 3`,
`Scarf`/`Sun hat` Owned, `Wellies 40` / `Crown 120` (DB prices per DATA OVER
MOCKS — the design's 30/60 are overridden, not a deviation). Free pill,
coin glyphs, progress 70%, growth preview + `Growing into a Songbird` all
present, correct order, no overflow/clipping/ellipsis.

Excluded per orchestrator rules (not deviations): OS status-bar time/icons;
OS home-indicator pill (app 831–835.7 vs design-drawn 825–829.7 — OS chrome);
Pip/nest artwork style inside the slot (PIP rule); wardrobe prices (DB wins).

## Deviations

### D1 (major — designer-visible, light + dark): locked wardrobe tiles have NO dashed border

- Design value (HTML `.k6-item.locked`): `surface-2` fill + 3 px dashed
  `ink-2` border + no shadow, on Wellies and Crown tiles.
- App value: `surface-2` fill with no border at all. Pixel proof, light,
  tile-top row (logical x=240, Wellies centre): y649–650 page bg
  (lum ~221), y651+ tile fill (243,238,229, lum 236) — background goes
  straight to fill, zero edge contrast. Same column on owned Scarf (x=60)
  shows the ink border (30,27,58, lum 38) at y651–653, then surface fill.
  Dark mode identical: page bg (33,59,75) straight to tile fill (42,38,64)
  at y651+, no border row. The 2× zoom crop (design dashed dashes vs app
  bare fill) and the band-6 heat glow on both locked tiles confirm it reads
  as flat beige cards, not locked slots.
- Fix: `app/lib/features/pip/presentation/widgets/pip_wardrobe_tile.dart` —
  the screen-local dashed-border `CustomPainter` stroke is reserving layout
  space but not painting (verify the painter is attached to the locked tile,
  paints `ink-2` at 3 px with the tile's r-l radius in both themes; add a
  widget-test pixel/golden assertion so it cannot regress silently).

### D2 (informational, not a failure): wardrobe glyph style differs from the HTML inline SVGs

- Scarf, wellies, crown glyphs are the shared `NestIcons` set (filled
  strokes), while the HTML inlines outline-style SVGs. Recognisably the same
  four items, correct slots and owned/locked styling. Shared icon set wins;
  no screen-local change possible or wanted.

### D3 (informational, not a failure): pet-art geometry inside the slot

- Pip head top (Mochi tufts, y~200) and nest-bottom curve (design 323.7 vs
  app 320.3) differ by ~3 px at isolated art edges; nest body width matches
  (±1.5 px/side at y=300) and the 230×206 slot position is unchanged. This is
  the allowed PIP-rule art swap (own `PipAvatar` + shared nest asset), not a
  layout deviation.

## verdict data

- `shot.sh` light + dark on the assigned simulator: stable frames saved.
- `compare.py` light + dark: sheets written, tables above.
- Geometry: every element within ±2 px except excluded OS chrome and the
  allowed Pip-art swap.
- One designer-visible deviation (D1) present in both themes.

VERDICT: FAIL
