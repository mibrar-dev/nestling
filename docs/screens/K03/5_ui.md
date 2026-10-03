# K03 Kid home — UI check (Stage 5, iteration 10)

Method (simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB only; 390x844):
- `bash tools/screens/shot.sh "$PWD/app" /kid-home "$PWD/docs/screens/K03/ui/app_light_10.png" <udid> light demo kid maya` -> valid K03 light (10:44). Same with `dark` -> valid K03 dark (10:45). Absolute OUT paths used. Both `stable frame saved`, no warnings, no contamination (dark verified K03).
- `python3 tools/screens/compare.py design/screens/light/K03-kid-home.png docs/screens/K03/ui/app_light_10.png docs/screens/K03/ui/cmp_light_10.png` (and dark). Read all four images. Logical px (PNG/3), tolerance ±2px.
- Rules applied: all (PIP, STATUS BAR, DATA + PERIODS, BOTTOM EDGE, ALIGNMENT, CHILD ORDER n/a, COPY U+0027, FONTS clean, no letterSpacing, chips display-only so CHIP ROWS n/a, SHAPES rects, BALANCED present, TRIAL n/a, ACCESSIBILITY tap actions — owned by test stage, which asserts them green), ORCHESTRATOR_NOTES (all incl. #10: `_kNestBoxHeight = 188` + geometry pins), `1_plan.md`, SPACING_SPEC.

Results:
- light mean diff: 6.02% — bands: 0: 1.85% · 1: 3.11% · 2: 7.23% · 3: 11.39% · 4: 3.64% · 5: 6.57% · 6: 7.62% · 7: 6.73%
- dark mean diff: 5.61% — bands: 0: 1.86% · 1: 3.40% · 2: 7.56% · 3: 9.61% · 4: 3.31% · 5: 6.55% · 6: 7.15% · 7: 5.42%
- Geometry chain (all #10 pins, measured + test-proven): hearts 443-452 EXACT both themes (target 448±2); progress borders EXACT; card-1 top/bottom EXACT (559-561 / 644-646); card-1 title rows identical; card-2 top EXACT (gap 12 = spec); dock top 719-721 EXACT; nest max-width 196-198 centred ≈194.5-195 (target 198±2 / 195±1, stroke-threshold noise); Pip seated in bowl, rim overlap, no gap ✓; card-2 peeking ✓; dark meadow pixel-identical at sampled rows; light green band exact; bottom edge dock-surface to y842 both themes ✓.
- Test-stage corroboration (this iteration, `3_test.md`): whole app 1557 pass / 0 fail; kid_home 175 pass; `kid_home_geometry_test` pins nest top 278±2 / bottom 364±2 / centre 195±1 / Pip feet 301±3 / hearts 448±2 / card-1 559±2 GREEN; a11y tap-action asserts green; bottom-edge + alignment matrix green.
- SHAPES: coin pill, lock 56, bubble x/w/body (36 vs 37), progress x24-365, all 3 dock buttons within 1-2px, card extents, full chip pills — match. Bubble tail white +10px lower (152-174 vs 152-164): cosmetic tail-fill nuance in the shared component, zero layout impact (downstream exact), invisible without overlay.

Accepted / overridden (NOT defects): A1 counts 4/4-of-6 + fill (DATA+PERIODS); A2 card-2 Hoover/Done vs Reading/+10 (alphabetical wins — residual band-6 heat); A3 v2 Pip/nest DRAWINGS vs v1 (mandated art swap — residual band-2/3 outlines; slot geometry proven exact); A4 status bar clock (band 0); A5 band-7 PNG delta (required by BOTTOM EDGE override); A6 dark pet glow (spec §7, PNG omits); A7 title size (pre-declared shared token).
- No remaining deviations: the iter9 items are closed (pet seat via shared fix + proven pins; tail reduced to a cosmetic fill nuance with no designer-visible impact; gap exact since iter9).

Otherwise correct: header, bubble copy, hearts 4/5 + caption, section chip, progress, cards/checks per status, exact dock, 20px gutters, no overflow/ellipsis, coins-only, all dark flips, NestBalancedText in use, no GoogleFonts, copy exact.

VERDICT: PASS
