# K02 Kid PIN (`/kid-pin`) — 5_ui (iteration 3)

Shots (simulator BC440E48-B3A3-43BC-971B-0EF5DB621874, `demo kid maya`):
- `docs/screens/K02/ui/app_light_3.png` (1170×2532, = 390×844 @3x)
- `docs/screens/K02/ui/app_dark_3.png` (1170×2532)

Compare output:
- Light: `mean diff: 0.95%`; bands 0: 1.54 (0–105), 1: 0.19 (105–211), 2: 2.07 (211–316), 3: 0.64 (316–422), 4: 0.83 (422–527), 5: 0.64 (527–633), 6: 0.55 (633–738), 7: 1.15 (738–844).
- Dark: `mean diff: 1.02%`; bands 0: 1.53, 1: 0.21, 2: 1.97, 3: 0.62, 4: 1.04, 5: 1.00, 6: 0.69, 7: 1.14.
- Unchanged from iteration 2 (0.96% / 1.04%): the shared keypad fix (`shared/keypad_grid`: 72 px keys, 10 px gaps, padding 8/24/0) holds; keypad bands stay ~0.5–1.0%.

Method: logical px = PNG px ÷ 3. Dark-ink row/column projections on design vs app (light pair; dark pair geometrically identical per the compare sheets).

Measured Y (logical px, design vs app, Δ = app − design):
- `NESTLING` mark text rows: ~265–270 both → Δ 0. Pill BG rect: design x 138–251.7, y 257–282.7 vs app x 137.3–252.3, y 257–282.7 → within ±1.
- Say title `Hi Maya! Enter your secret code`: rows ~292–305 both → Δ 0.
- PIN dots block 331–365, dots 340–358 both; x-segments identical 141–159 / 171–189 / 201–219 / 231–249 (18 px dots, 12 px gap) → Δ 0.
- Keypad row tops: R1 393–395, R2 ~473–475, R3 ~558–560, R4 ~638–640 — identical in both; row bottoms (R1 ~460–465, R2 ~545–550, R3 ~625–630, R4 ~710–715) identical too → Δ 0 throughout.
- Key columns, row-1 edges: 77 / 111.7–116.3 (glyph) / 146–149 / 159–162 / ~194–200 (glyph, sub-px raster) / 228–231 / 241–244 / 273.3–281.7 (glyph) / 310–313 — identical in both (pitch 82, grid x 77–313) → Δ 0.
- Caption `Forgot it? Just ask a grown-up.`: rows 740/745 both → Δ 0.
- Avatar disc: lilac span x 131–259 (128) identical both (iteration 1 measurement, layout untouched since).
- Screen title (say) y 285, first control (dots) 340, keypad rows 393/475/558–560/638–640, caption 731 — all match the plan's design anchors within ±2.

## Deviations

No numbered product deviations remain. Residual diff is all non-actionable:
- Status-bar time/glyphs (band 0, ~1.5%): ignored per STATUS BAR orchestrator rule (OS draws the real bar).
- Dots fill (band 2, ~2%): design shows 2 filled as an illustrative mid-entry mock (aria `Two of four digits entered`); app shows 0 filled = correct empty initial state. Same position/size; state difference is correct behaviour, excluded as DB-driven/initial content per the UI VERDICT RULE.
- 1 px glyph/shadow raster edges on text, digits and key borders (bands 3–6, ≤1%): font anti-aliasing only, no positional shift (projections identical).
- Home-indicator mock pill (band 7): design draws the 134×5 mock pill; simctl shot shows none (transparent bottom spacer per plan; the OS draws the real indicator). Chrome, not a product defect.
- Band 7 remainder (~1.1%): caption raster + the above pill mock.

Passing checks (element-by-element vs design):
- Presence/order: back, lock, avatar, mark pill, greeting, dots, 10 digit keys + blank + delete, caption — present, in design order, both themes.
- Copy (vs HTML source char-by-char): `NESTLING`, `Hi Maya! Enter your secret code` (no trailing period, source line 38), `Forgot it? Just ask a grown-up.` — exact.
- Shapes, not only text: mark pill BG rect ±1 px; dots x/Ø identical; key circles 72 with 3 px kid borders at identical edges; lock 56×56 r18 surface + line border; delete backspace icon matches.
- Spacing/sizes/alignment: 20 px gutters, centred column, keypad grid x 77–313; nothing off by more than ±1 px anywhere.
- Colours/radii/shadows/icons: kid sky + meadow to the physical edge (no strip — BOTTOM EDGE rule PASS), lilac tint disc, ink borders, kid shadows; no overflow/clipping/ellipsis issues.
- Dark mode: same geometry; colours correct (dark sky gradient, dark-navy keys with light borders, empty dots light-bordered, dark lilac disc + lavender M, ink-2 caption). No dark-only deviation.
- No `£`, no Pip slot on this screen (avatar only — PIP rule N/A), no chip rows (N/A), no `text-wrap: balance` in K02 CSS (no `NestBalancedText` — correct).

UI VERDICT RULE audit: every element within ±2 px (measured: all Δ 0, pill ±1). No uniform shift. PASS.

VERDICT: PASS
