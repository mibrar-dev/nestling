# K03 Kid home — UI check (Stage 5, iteration 3)

Method (simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB, 390x844):
- `bash tools/screens/shot.sh "$PWD/app" /kid-home "$PWD/docs/screens/K03/ui/app_light_3.png" <udid> light demo kid maya` -> `docs/screens/K03/ui/app_light_3.png` (1170x2532). Same with `dark` -> `app_dark_3.png`.
- NOTE: absolute OUT paths used (`shot.sh` cds to `$APP_DIR`). Both runs again printed `WARNING — frame never stabilised in 25 s`, exit 1; frames are usable and theme-consistent.
- `python3 tools/screens/compare.py design/screens/light/K03-kid-home.png docs/screens/K03/ui/app_light_3.png docs/screens/K03/ui/cmp_light_3.png` (and dark). Read both sheets. Logical px (PNG/3), tolerance ±2px.
- Rules applied: PIP (`PipAvatar` Mochi/sunny/stage 3, slot kept), STATUS BAR (ignore), DATA OVER MOCKS + PERIODS ruling (in-period counts win; seed anchored to today), BOTTOM EDGE owner rule (bar surface must run to the physical edge — FAIL any coloured strip under a bar; overrides the design), ALIGNMENT owner rule (20px gutters, no visible misalignment), ORCHESTRATOR_NOTES (all mandatory items), `1_plan.md`, SPACING_SPEC.

Results:
- light mean diff: 12.97% — bands: 0: 2.97% · 1: 4.85% · 2: 10.86% · 3: 13.18% · 4: 13.20% · 5: 23.28% · 6: 25.80% · 7: 9.64%
- dark mean diff: 11.84% — bands: 0: 3.01% · 1: 4.47% · 2: 8.89% · 3: 9.71% · 4: 12.90% · 5: 23.12% · 6: 23.37% · 7: 9.25%
- Band 7 recovered (26.5% → ~9.5%): dock top back at design height. Bands 2-6 remain elevated for accepted reasons (mandated PipAvatar art, 4-vs-3 counts + fill, Hoover/Done vs Reading/+10 sample order).

Accepted / overridden (NOT defects):
- A1 counts "4 done today" / "4 of 6 done" / ~66.7% fill vs PNG 3/50% — correct per DATA + PERIODS (seed anchored to today; all 4 completions in-period) + ORCHESTRATOR_NOTES #2.
- A2 2nd card "Hoover the stairs" (approved → "Done" chip, partly visible above dock, same presentation as PNG's partly-visible "Reading") vs PNG sample order — repo alphabetical order wins per `1_plan.md` §(a).
- A3 Pip drawing differs from v1 SVG — MANDATED `PipAvatar`; slot position kept (pet band aligns with design).
- A4 status bar (real OS 03:44/03:45 only, no mock duplication) — IGNORED per rule; band 0 is this only.
- A5 quest icon tiles `surface2` vs per-quest tints — SHARED_REQUEST #1, non-blocking. A6 card title ≈17/22 vs 18/24 — pre-declared shared token.
- A7 no home-indicator pill visible in captures — expected: `NestHomeIndicator` reserves nothing now (OS draws it; `simctl screenshot` does not capture the OS indicator). Not verifiable here, not a defect.

Deviations (design value → app value + fix):
1. Coloured strip under the dock to the screen edge (MUST-FAIL per BOTTOM EDGE rule, both themes). App light: GREEN (191,232,176) from y≈805 to y842 under the white dock; app dark: GREEN (30,74,58) under the navy dock. Rule: meadow must END at the dock's top edge; dock surface (light: white surface; dark: the dock's dark surface) must fill from the dock's top border to the physical edge, home-indicator area included. (The PNG shows green here too — the owner rule explicitly overrides the design on this point.) Fix: clip/end the meadow at the dock top; extend the dock container background through the bottom safe area to the screen edge. Do not edit code in this stage — for the iteration-4 builder.
2. Dock top ≈6px high (minor, ALIGNMENT). Dock top border: design y≈719-721 vs app y≈713-715 (light). Fix: keep the ORCHESTRATOR_NOTES y≈720 target exactly (SafeArea/inset accounting) while applying fix #1.
3. Upper-stack residuals (minor, knock-on of the same layout): hearts +12 (design y443-452 vs app y455-464, unchanged from iter2); progress bar +8 (541 vs 549-550); card-1 top +4 (559-561 vs 563-564); green band starts +38 (design y524 behind progress vs app y562 just below it). Fix: trim ≈8-12px from the pet-stage bottom/speech gaps per the mandated Pip slot (nest top ≈y300, Pip ≈152) so hearts/progress/cards/green-start land on design rows.

Otherwise correct: header row, bubble, hearts 4/5 stroked + caption, section title + chip, kid progress geometry, card geometry/chips/checks per status, dock buttons (glyphs, labels, colours both themes), 20px gutters with cards/bars edge-aligned, no overflow/ellipsis issues, coins-only, dark token flips correct.

Iteration-4 fixes (local): #1 bottom-edge fill (both themes), #2 dock top to y≈720, #3 upper-stack trim. Shared/pre-declared: tile tint, title size.

VERDICT: FAIL
