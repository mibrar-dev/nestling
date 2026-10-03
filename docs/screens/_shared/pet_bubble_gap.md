NestPetStage: let screens set the bubble→pet gap, and make the bubble exactly 44 tall.

READ (read-only): ../nestling-screens/K03/docs/screens/K03/SHARED_REQUEST.md item 18, and the comment above `_kStageToHearts` in ../nestling-screens/K03/app/lib/features/kid_home/presentation/views/kid_home_view.dart.
DESIGN (K03, 390×844): speech bubble top 125, bubble 44 tall (outer border box; the tail overflows, per shared/speech_tail) → `.k3-pet { margin: 14px auto 0 }` → the 236-tall pet box at 183…419 → s4 (16) → hearts row 435 (centre 448).
APP NOW: NestPetStage puts NestSpacing.s2 (8) between the bubble and the pet, and the bubble lays out 45 tall. So the pet block is at 178…414, 5 px high, and K03 compensates with a magic 21 px gap below.
DO (app/lib/core/design_system/components/nest_pet_stage.dart):
1. Add an optional `bubbleGap` (double, default the current s2 = 8, so other users don't change).
2. Make NestSpeechBubble's laid-out height exactly match `.speech` for one line: 3 + 8 + line + 8 + 3, with the line at the font's normal height. The design measures 44 outer. Find the 1 px: rounding, strut or border. Test 44 ±0.25 with real Nunito.
3. Tests: with bubbleGap 14 and K03's parameters (nestWidth 236, nestHeight 188, fixedPipHeight 152) in a 390 wide frame with the bubble top at 125, the pet box spans 183…419 ±0.5; the default gap is unchanged for other callers.
4. Do not edit feature code. In the report, give the exact K03 change: `bubbleGap: 14` and `_kStageToHearts` back to NestSpacing.s4.
DONE = dart format clean, flutter analyze "No issues found!", full flutter test green, docs/screens/_shared/pet_bubble_gap_REPORT.md, committed.
