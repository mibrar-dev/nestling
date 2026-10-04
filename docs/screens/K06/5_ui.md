# K06 · Pip's nest (`/pip`) — Stage 5 UI check (iteration 2)

Simulator 604697A9-11DA-462F-9837-396E9CA2493A (390×844), `demo kid maya`.
Shots: `docs/screens/K06/ui/app_light_2.png`, `app_dark_2.png`.
Sheets: `cmp_light_2.png`, `cmp_dark_2.png` (design | app | heat-map).
Iteration-1 artefacts (`*_1.png`) kept for history.

- Light: `mean diff: 2.28%` (was 3.67%) — bands: 0: 1.55, 1: 1.74, 2: 2.50
  (was 12.05), 3: 0.44, 4: 1.21, 5: 2.08, 6: 4.48, 7: 4.27.
- Dark: `mean diff: 2.00%` (was 3.01%) — bands: 0: 1.58, 1: 1.23, 2: 2.20
  (was 9.41), 3: 0.35, 4: 1.38, 5: 2.04, 6: 4.34, 7: 2.90.
- Band 2 residual is the allowed Pip-art swap (own `PipAvatar` vs the v1
  illustration per the PIP rule); the nest body width matches ±1.5 px/side
  and the slot bottom edge now matches the design exactly (323.7 = 323.7).
- Band 6 residual is deviations D2/D3 below (glyph art + DB prices).

## Measured y positions, design vs app (logical px, ÷3; ±2 px rule)

Row-edge detector (background-deviation scan, x 20–370, iteration-2 shots):

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
| Nest body width at y=300 | 155.0 | 158.3 | ±1.5/side ✓ |

No uniform vertical shift. 20 px gutters everywhere; growth card, care row
and wardrobe rows share edges x20–370. Meadow runs to the physical edge;
no bar on this screen, so the BOTTOM EDGE rule passes in both themes.

Copy (character-exact vs HTML): `Pip · Fledgling` (U+00B7), `Pip's wardrobe`
(U+2019), `Nothing here is a chore — it is all just for fun.` (U+2014),
`175 coins` / `250 to grow`, `Feed 5` / `Play Free` / `Bath 3`,
`Scarf`/`Sun hat` Owned — exact. Dark mode: same geometry; peach Feed,
light-blue Play with dark Free pill, dark Bath card, dark cards with light
borders, leaf-ink Owned — all token-correct, no dark-only deviation.

Excluded (not deviations): OS status-bar time/icons; OS home-indicator pill
(app 831–835.7 vs design-drawn 825–829.7); Pip/nest artwork style inside the
slot (PIP rule, ORCHESTRATOR_NOTES item 4 confirms correct); wardrobe prices
(DB-driven — DATA OVER MOCKS, see D3).

## Deviations

### D1 (iteration-1 major — FIXED, verified light + dark)

Locked tiles had no border. Now: pixel proof, light, Wellies centre x=240 —
y649–650 page bg (lum ~221), y651–653 border (74,70,104), y654+ tile fill —
3 px dashed-length edge paints in both themes (crop + band-6 border edges
confirm; owned tiles unchanged). Closed.

### D2 (major, still open — shared-owned): wardrobe Scarf/Wellies glyphs are look-alikes, not the design glyphs

- Design value (HTML `.k6-ward` inline SVGs): scarf = two vertical strokes +
  flag + one tick; wellies = boot body + two top ticks.
- App value: shared `NestIcons.scarf` (fringed-blanket art) and
  `NestIcons.wellies` (filled boot) — recognisably a scarf/boot, visibly
  different drawing (2× crop + art rows glowing in band 6).
- Fix (not screen-side): replace `app/assets/icons/ic_scarf.svg` +
  `ic_wellies.svg` with the HTML path data. Filed as `SHARED_REQUEST.md`
  §5 (design paths quoted verbatim, asset-vs-design diff table, proof test
  `pip_orchestrator_notes_test.dart` item 2 parked with `--run-skipped`).
  RULES §1 forbids the screen touching `core/**` and the note forbids
  substituting a glyph, so there is zero screen-side work left. §5 says
  "Blocks: no" for landing, but the visual target (note item 2, mandatory)
  is unmet in-product, so the UI check cannot pass until the shared assets
  land on main and are merged in.

### D3 (not a deviation — DB truth + escalated): Wellies 40 / Crown 120 vs design 30 / 60

- App renders `watchWardrobe(item).priceCoins` (seed rows), never a literal —
  correct per DATA OVER MOCKS, and DB-driven content is excluded from the UI
  verdict rule. The seed-vs-design conflict is filed as `SHARED_REQUEST.md`
  §6 with both orchestrator options (fix seed to 30/60, or update design to
  40/120) and flip-honestly tests. No screen action possible.

## verdict data

- `shot.sh` light + dark on the assigned simulator: stable frames saved.
- `compare.py` light + dark: sheets written, tables above.
- Geometry: every element within ±2 px (all structural Δ 0, section +1).
- Remaining designer-visible deviation: D2 (shared-owned, escalated, needs
  a main-side asset swap + merge before any UI re-check can pass).

VERDICT: FAIL
