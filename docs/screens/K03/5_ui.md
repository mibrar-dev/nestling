# K03 Kid home — UI check (Stage 5, iteration 4)

Method (simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB, 390x844):
- `bash tools/screens/shot.sh "$PWD/app" /kid-home "$PWD/docs/screens/K03/ui/app_light_4.png" <udid> light demo kid maya` -> `docs/screens/K03/ui/app_light_4.png` (1170x2532). Same with `dark` -> `app_dark_4.png`.
- NOTE: absolute OUT paths used (`shot.sh` cds to `$APP_DIR`). Both runs again printed `WARNING — frame never stabilised in 25 s`, exit 1; frames usable and theme-consistent.
- `python3 tools/screens/compare.py design/screens/light/K03-kid-home.png docs/screens/K03/ui/app_light_4.png docs/screens/K03/ui/cmp_light_4.png` (and dark). Read both sheets. Logical px (PNG/3), tolerance ±2px.
- Rules applied: PIP (`PipAvatar` Mochi/sunny/stage 3), STATUS BAR (ignore), DATA OVER MOCKS + PERIODS (in-period counts win; seed anchored to today), BOTTOM EDGE owner rule (bar surface to the physical edge — FAIL any coloured strip; overrides the design), ALIGNMENT owner rule (20px gutters, nothing visibly off), ORCHESTRATOR_NOTES (all items incl. the OWNER FEEDBACK reversal: meadow ENDS at dock top, dock surface fills to the edge), `1_plan.md`, SPACING_SPEC.

Results:
- light mean diff: 13.37% — bands: 0: 2.98% · 1: 4.85% · 2: 10.84% · 3: 13.18% · 4: 13.20% · 5: 23.28% · 6: 25.80% · 7: 12.80%
- dark mean diff: 12.13% — bands: 0: 3.01% · 1: 4.47% · 2: 8.97% · 3: 9.71% · 4: 12.90% · 5: 23.12% · 6: 23.37% · 7: 11.49%
- Band 7 rose (~9.5% → ~12%) for the RIGHT reason: the home strip is now dock-surface (white/navy) while the outdated PNG still shows green there — that delta is required by the BOTTOM EDGE override. Bands 2-6 heat is dominated by accepted diffs (mandated PipAvatar art, 4-vs-3 counts + fill, Hoover/Done vs Reading/+10 sample order).

Fixed since iter3 (verified):
- F1 bottom edge (was must-FAIL): below-dock rows y810-842 are now dock surface — light WHITE (255,255,255), dark NAVY (31,28,46). No green strip in either theme. Meadow ends at the dock top; light green band still present behind the cards (x=10 green y562-699).
- Dock top back at design height (light border rows 713-715 vs design 719-721, i.e. −6, see #3).

Accepted / overridden (NOT defects):
- A1 counts "4 done today" / "4 of 6 done" / ~66.7% vs PNG 3/50% — correct per DATA + PERIODS + notes #2.
- A2 2nd card "Hoover the stairs" (approved → "Done") vs PNG "Reading" sample — repo alphabetical order wins per `1_plan.md` §(a); same peek-above-dock presentation as the PNG.
- A3 Pip drawing vs v1 SVG — MANDATED `PipAvatar`; slot kept. A4 status bar (OS time only) — ignored. A5 tiles `surface2` vs tints — SHARED_REQUEST #1. A6 title ≈17/22 vs 18/24 — pre-declared token. A7 no OS pill in captures — expected (`simctl screenshot` never captures the OS indicator).
- A8 band-7 white/navy-vs-green delta vs the PNG home strip — REQUIRED by the BOTTOM EDGE override, not a defect.

Deviations (design value → app value + fix):
1. Dark lower-content background missing the meadow tint (moderate, dark-only). Design dark x=10: (37,52,88) at y540 grading to teal (33,64,72) at y700 behind progress/cards. App dark x=10: flat navy (38,46,102) → (37,51,89) — no meadow visible, while light renders its green band correctly. Fix: check the dark meadow fills (dark `--kid-meadow`/`--horizon`, `hill-front` bake per SPACING §9.14) so the meadow shows behind the lower content in dark as it does in light. For the iteration-5 builder; do not touch in this stage.
2. Upper-stack residuals (minor, unchanged from iter3): hearts +12 (443-452 vs 455-464); progress ≈+8 (541 vs 549-550); card-1 top +4 (559-561 vs 563-564); light green start +38 (524 vs 562). Fix: trim pet-stage bottom gap toward the mandated Pip slot (nest top ≈y300, Pip ≈152).
3. Dock top −6px (minor, ALIGNMENT): light 713-715 vs 719-721. Fix: land the dock top exactly on y≈720 when owning the bottom inset.

Otherwise correct: header row, bubble, hearts 4/5 stroked + caption, section title + chip, kid progress geometry, card geometry/chips/checks per status, dock buttons (glyphs, labels, colours both themes), 20px gutters edge-aligned, no overflow/ellipsis issues, coins-only, all other dark token flips correct.

Iteration-5 fixes (local): #1 dark meadow behind lower content; #2 upper-stack trim; #3 dock top to y≈720. Shared/pre-declared: tile tint, title size.

VERDICT: FAIL
