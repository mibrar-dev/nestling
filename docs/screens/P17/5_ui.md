# P17 Parental gate — 5_ui (iteration 3)

Route `/parental-gate`, mode kid, child maya, seed demo. Simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB (390×844 logical, 1170×2532 physical; ÷3).
No code edited by this stage. ORCHESTRATOR_NOTES.md items 1–7 (+shared keypad update) checked below.

Shots:
- `docs/screens/P17/ui/app_light_3.png` / `app_dark_3.png`
- `docs/screens/P17/ui/cmp_light_3.png` / `cmp_dark_3.png` via `tools/screens/compare.py`

Mean diff:
- light: 1.37% (bands 0–7: 1.00 / 1.51 / 2.76 / 0.68 / 0.54 / 0.78 / 0.86 / 2.82)
- dark: 1.45% (bands: 1.30 / 1.52 / 2.57 / 0.72 / 0.59 / 0.84 / 0.88 / 3.20)
- Iteration 2 was 6.66% / 5.41%. Keypad bands 3–6 are now all <1% (shared keypad_grid fix landed).

Measured y, logical px (physical ÷3; modal edges = first/last row with >60% modal-surface run; text bands = dark-ink histogram):
- Modal (card) top: design 66.0 / app 66.0 (Δ 0) — PASS
- Modal bottom: design 777.7 / app 777.7 (Δ 0) — PASS
- Modal left/width: design x24.0 w342.0 / app x24.0 w342.0 (Δ 0) — PASS
- Screen title “Grown-ups only” top: design 164.0 / app 164.0 (Δ 0) — PASS
- First control (digit boxes row; state differs, rect matches 56×64 gap 12 visually): glyph band design 280.3–293.3 (filled “4”); app empty with carets (runtime state, excluded). Box positions overlay exactly in the heatmap.
- Instruction band: design 160.0 / app 160.0 (Δ 0) — PASS
- Question band top: design 225.0 / app 225.3 (Δ +0.3) — PASS
- Keypad row 1 top: design 344.0 / app 344.0 (Δ 0) — PASS
- Keypad row 2 top: design 426.0 / app 426.0 (Δ 0) — PASS
- Keypad row 3 top: design 508.0 / app 508.0 (Δ 0) — PASS
- Keypad row 4 top: design 590.3 / app 590.3 (Δ 0) — PASS
- Cancel “Back to Pip” top: design 696.3 / app 698.0 (Δ +1.7) — PASS (within ±2)
- Caption follows cancel; heatmap shows only faint sub-2px text-edge red, no positional double-vision.

Excluded per orchestrator rules (not deviations):
- Question copy “seven times six” vs “four times nine”: DB-driven (orchestrator item 7 / DATA OVER MOCKS).
- Digit content (filled “4” vs empty + carets): runtime entry state (item 7).
- Status time/glyphs (9:41 vs 09:07/09:09): STATUS BAR rule.
- Home-indicator pill in design (band py 2475–2489) vs none in simctl shot: gallery mock only; explains most of band 7 residual (2.82% / 3.20%).
- Band 2 residual (~2.6–2.8%) is the question-text + digit-state difference above, not geometry.

Element-by-element: presence, order and copy match the HTML source character-for-character; scrim dims the whole kid screen including header and status area (bands 0–1 ~1–1.5%); lock tile 52 lilac tint, h2/h3/body-s/caption styles, leaf carets, kid key rings (light ink ring + shadow, dark white ring no shadow), radii (modal 32, digits 16, keys circular), key rects overlay exactly (no collapsed shapes), no overflow/clipping/ellipsis; side gutters exact; dark-mode colours correct; no bottom bar so BOTTOM EDGE rule is N/A but scrim + shared kid meadow run full-bleed with no strip; shared kid background used (no local hills); Pip covered by the card in both, header child data correct (Maya).

No numbered deviations: every element is within ±2 px of the design excluding OS status glyphs and DB-driven content. No visible deviation a designer would reject.

VERDICT: PASS
