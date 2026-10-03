Follow-up to shared/pet_stage_explicit (merged): in explicit mode the nest is squashed and too low, and Pip stands ON the rim instead of IN the bowl.

EVIDENCE (read-only): ../nestling-screens/K03/docs/screens/K03/ui/cmp_light_8.png and cmp_dark_8.png (K03 is now aligned everywhere except the pet block). K03 calls:
`NestPetStage(pip: PipAvatar(...), speech: ..., nestWidth: 236, nestHeight: 156, fixedPipHeight: 152)`.

MEASURED at 390×844, logical px (design = design/screens/light/K03-kid-home.png ÷3; app = K03 ui/app_light_8.png ÷3):
| item | design | app now |
|---|---|---|
| visible nest outline x | 96 → 294 | 95 → 293 ✓ |
| visible nest outline y (top → bottom) | 278 → 364 (86 tall) | 319 → 391 (72 tall: SQUASHED) |
| Pip head top | ≈ 199 | ≈ 216 |
| Pip bottom (feet/body) | ≈ 301, i.e. ≈ 23 px BELOW the nest's top rim (inside the bowl) | ≈ 316, i.e. standing ON the rim (nest top 319) |
| hearts row centre / everything below | 448 | 448 ✓ (block height is right; keep it) |

CAUSES TO CHECK:
- The nest art is drawn with BoxFit.fill into a 236×156 box, which changes its aspect. The nest SVG must keep its own aspect (BoxFit.contain or an exact aspect-derived height) so the visible outline is 198×86.
- The nest is vertically placed too low in the 236-tall slot, and Pip's seat line is computed at the rim instead of ≈ 23 px into the bowl.

DO:
1. Keep the nest SVG's native aspect. Visible outline 198×86 at the K03 parameters.
2. Position inside the slot to match the table: nest top 278, Pip head top ≈ 199, Pip bottom ≈ 301 (≈ 23 px below the nest's top rim). Keep the speech bubble where it is, and keep the hearts / everything below where it is: total slot height unchanged.
   - Layering: nest back layer → Pip → nest front rim, as the design shows Pip sitting in the bowl. PipNestFallback already has back/front halves; use them.
3. Update nest_pet_stage_test.dart:
   - The visible nest is 198±2 × 86±2.
   - Nest top 278±2 and Pip bottom 301±3 in the K03 harness, and Pip is centred.
   - Hearts 448±2 unchanged.
   - Both the Rive-disabled and Reduce Motion paths are covered.
4. Legacy (non-explicit) mode is unchanged and all existing tests stay green.
DONE = dart format clean, flutter analyze "No issues found!", full flutter test green, docs/screens/_shared/pet_stage_seat_REPORT.md (with the K03 call if it changes), committed.
