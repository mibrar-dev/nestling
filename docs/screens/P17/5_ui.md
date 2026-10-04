# P17 Parental gate — 5_ui (iteration 1)

Route `/parental-gate`, mode kid, child maya, seed demo. Simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB (390×844 logical, 1170×2532 physical; ÷3).
No code edited by this stage.

Shots:
- `docs/screens/P17/ui/app_light_1.png` (THEME=light)
- `docs/screens/P17/ui/app_dark_1.png` (THEME=dark)
- `docs/screens/P17/ui/cmp_light_1.png` / `cmp_dark_1.png` via `tools/screens/compare.py`

Mean diff:
- light: 7.86% (bands 0–7: 7.68 / 6.72 / 4.57 / 10.59 / 11.29 / 8.48 / 4.65 / 8.84; y-ranges 0-105 … 738-844)
- dark: 6.43% (bands: 3.21 / 6.51 / 4.14 / 9.91 / 10.63 / 8.08 / 4.34 / 4.54)
- Hot bands 3–4 (y 316–527, digits + keypad rows 1–2) peak at ~10–11% in both themes.

Measured y (logical px, physical ÷3; centre-column / dark-pixel histogram; modal edges = first/last row with >60% modal-surface run across middle 70% width):
- Modal top: design 66.0 / app 53.0 (Δ −13.0) — both themes identical
- Modal bottom: design 777.7 / app 790.7 (Δ +13.0) — both themes identical
- Modal left/width: design x24.0 w342.0 / app x24.0 w342.0 (Δ 0) — PASS
- Title “Grown-ups only” top: design 164.0 / app 151.0 (Δ −13.0)
- Instruction “Type the answer in numbers:” band: design ~160.0 / app ~147.0 (Δ −13)
- Question band top: design 225.0 / app 212.3 (Δ −12.7)
- Keypad row 1 top: design 344.0 / app 331.0 (Δ −13.0)
- Keypad row 2 top: design 426.0 / app 419.0 (Δ −7.0)
- Keypad row 3 top: design 508.0 / app 507.0 (Δ −1.0)
- Keypad row 4 top: design 590.3 / app 595.3 (Δ +5.0)
- Cancel “Back to Pip” top: design 696.3 / app 711.0 (Δ +14.7)
- Backdrop header “Hi Maya!”: design hidden behind scrim+modal (only ~10 px dimmed slivers peek above modal top); app fully visible band 18.3–37.7, overlapping the OS status time (01:49/01:50 glyphs over the “M” avatar)
- Caption follows cancel (+10 gap per CSS); inherits the ~+13…+15 bottom shift.

Non-findings (do NOT fix — orchestrator rules):
- Question copy “seven times six” (design) vs “four times nine” (app): DATA OVER MOCKS, challenge is deterministic per London day from the seeded DB. Do not hard-code design numbers.
- Digit boxes: design shows filled “4” + empty (example filled state); app initial state both empty with leaf caret in first box. Correct empty state, not a layout deviation.
- Status time 9:41 vs 01:49/01:50 and status glyph style: ignored per STATUS BAR rule.
- Home-indicator pill in design vs none in simctl screenshot: gallery mock only, ignored.
- Coin “120”, avatar “M” lilac, “Hi Maya!” copy: match DB/design.

What matches:
- Copy (title, instruction, “Back to Pip”, “This keeps settings and purchases safe.”) character-for-character with the HTML source.
- Side gutters x24/366 w342 exact in both themes; cards/bars aligned, no horizontal misalignment.
- Lock tile lilac tint, h2/h3/body-s/caption styles, leaf caret, kid key rings (light: ink ring + shadow; dark: white ring, no shadow), radii (modal 32, digits 16, keys circular), no overflow/clipping/ellipsis, dark-mode surfaces correct.
- BOTTOM EDGE owner rule: no bottom bar on this screen; scrim + KidScope hill run full-bleed to the physical edge in both themes. No coloured strip under a bar. PASS.
- Pip slot: Pip is fully covered by the modal in both design and app, so PipAvatar vs v1 SVG cannot be discriminated from these frames; backdrop header correctly shows Maya (M, lilac, 120). Geometry tests assert the 200 px PipAvatar.

Deviations (design value → app value + fix):

1. Modal frame shifted and stretched — FAIL (±2 px rule; uniform shift alone is FAIL).
   Design: top 66.0, bottom 777.7, height 711.7. App: top 53.0, bottom 790.7, height 737.7 (Δtop −13.0, Δbottom +13.0, +26 tall).
   Fix: anchor the modal layer as the design does (top-anchored sheet at y66 with 24 px side gutters, not vertically centred), and re-check internal gaps so total height returns to ~712. Likely the `Center`/`LayoutBuilder` wrapper noted in 2_build centres the card; replace with top-anchored positioning per `.modal`/`.gate` CSS.

2. Backdrop header exposed and colliding with the status bar — FAIL.
   Design: header row sits below the 47 px status-bar reserve and is almost fully covered + dimmed by the scrim (only slivers peek). App: full header (“M” + “Hi Maya!” + 120 pill) painted at y18–38, undimmed in light, overlapping the OS time (01:49 over “M”).
   Fix: reserve the status-bar height above the kid backdrop (backdrop starts below `NestStatusBar`, not under it) and ensure the full-bleed scrim dims the whole backdrop including the header.

3. Internal vertical rhythm drifts beyond ±2 px (consequence of 1, but each band independently fails).
   Title Δ −13.0, question Δ −12.7, keypad row 1 Δ −13.0, row 2 Δ −7.0, row 4 Δ +5.0, cancel Δ +14.7 (values above).
   Fix: with the modal frame fixed at top 66, restore CSS gaps exactly (title +12, instr +8, question +4, digits +16, keypad +16, cancel +12 with min-height 56, caption +10) and keypad geometry 72 keys / 24 col / 16 row; do not stretch gaps to fill height.

4. (Consequential, not separate fix) Band diffs 10–11% in y316–527 and 7–9% elsewhere are fully explained by 1–3 plus the expected question/digits state differences. No separate colour/radius/shadow deviation found at this pass; key rect sizes measure 72 tall in both (histogram row height 72.0), digit/box/key shapes match when overlaid modulo the shift.

Builder notes for iteration 2: fix modal anchoring + status-bar reserve + gaps per CSS; re-shoot light+dark and confirm top 66±2, bottom 778±2, title 164±2, question 225±2, row 1 344±2, cancel 696±2. Do not hard-code the design question/digits to reduce diff — DB values are correct.

VERDICT: FAIL
