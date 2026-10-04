# P17 Parental gate — 5_ui (iteration 4)

Route `/parental-gate`, mode kid, child maya, seed demo. Simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB (390×844 logical, 1170×2532 physical; ÷3).
No code edited by this stage. ORCHESTRATOR_NOTES.md (incl. shared keypad_grid fix and shared/kid_trial_gate note) checked.

Shots:
- `docs/screens/P17/ui/app_light_4.png` / `app_dark_4.png`
- `docs/screens/P17/ui/cmp_light_4.png` / `cmp_dark_4.png` via `tools/screens/compare.py`

Mean diff:
- light: 1.37% (bands 0–7: 0.98 / 1.51 / 2.76 / 0.68 / 0.54 / 0.78 / 0.86 / 2.82)
- dark: 1.44% (bands: 1.16 / 1.52 / 2.57 / 0.72 / 0.59 / 0.84 / 0.88 / 3.20)
- Unchanged from iteration 3 (1.37% / 1.45%). Keypad bands 3–6 all <1%.

Measured y, logical px (physical ÷3; modal edges = first/last row with >60% modal-surface run; text bands = dark-ink histogram):
- Modal (card) top: design 66.0 / app 66.0 (Δ 0) — PASS
- Modal bottom: design 777.7 / app 777.7 (Δ 0) — PASS
- Modal left/width: design x24.0 w342.0 / app x24.0 w342.0 (Δ 0) — PASS
- Screen title “Grown-ups only” top: design 164.0 / app 164.0 (Δ 0) — PASS
- First control (digit boxes 56×64, gap 12): rects overlay exactly; glyph content differs by runtime state (below), positions match.
- Instruction band: design 160.0 / app 160.0 (Δ 0) — PASS
- Question band top: design 225.0 / app 225.3 (Δ +0.3) — PASS
- Keypad row 1 top: design 344.0 / app 344.0 (Δ 0) — PASS
- Keypad row 2 top: design 426.0 / app 426.0 (Δ 0) — PASS
- Keypad row 3 top: design 508.0 / app 508.0 (Δ 0) — PASS
- Keypad row 4 top: design 590.3 / app 590.3 (Δ 0) — PASS
- Cancel “Back to Pip” top: design 696.3 / app 698.0 (Δ +1.7) — PASS (within ±2)
- Caption follows cancel; only faint sub-2px text-edge red in heatmap.

Excluded per orchestrator rules (not deviations):
- Question copy (“seven times six” vs DB value) and digit content (filled “4” vs empty + carets): runtime state / DATA OVER MOCKS (ORCHESTRATOR_NOTES item 7).
- Status time/glyphs (9:41 vs 10:10/10:11): STATUS BAR rule.
- Home-indicator pill in design (py 2475–2489) vs none in simctl shot: gallery mock only; explains most of band 7 residual.
- Band 2 residual (~2.6–2.8%) is the question-text + digit-state difference, not geometry.

Element-by-element: presence, order and copy match the HTML source character-for-character; scrim dims the whole kid screen including header and status area; lock tile 52 lilac tint, h2/h3/body-s/caption styles, leaf carets, kid key rings (light ink ring + shadow, dark white ring no shadow), radii (modal 32, digits 16, keys circular), key border rects overlay exactly; no overflow/clipping/ellipsis; side gutters exact; dark-mode colours correct; no bottom bar (BOTTOM EDGE N/A) with scrim + shared kid meadow full-bleed and no strip; shared kid background, no local hills; Pip covered by the card in both, header child data correct (Maya).

P17-local items only per the 09:48 orchestrator note (redirect loop / kid-test reds belong to shared/kid_trial_gate; kid_home tests untouched).

No numbered deviations: every element is within ±2 px of the design excluding OS status glyphs and DB-driven content. No visible deviation a designer would reject.

VERDICT: PASS
