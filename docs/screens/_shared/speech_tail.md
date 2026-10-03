NestSpeechBubble tail: match the CSS `.speech::after` exactly.

CSS (design/html-source/components.css:192):
`.speech::after { content:""; position:absolute; bottom:-9px; left:50%; transform:translateX(-50%); border:9px solid transparent; border-top-color: var(--ink); border-bottom:0; }`
The tail is a SOLID INK triangle, 18 px wide at the base and 9 px tall. Its base sits on the bubble's bottom edge, which is the outer edge of the 3 px ink border, and it hangs 9 px below it. There is NO white/surface fill inside the tail.

MEASURED on K03 dark (read-only: ../nestling-screens/K03/docs/screens/K03/5_ui.md finding 1; ../nestling-screens/K03/docs/screens/K03/ui/cmp_dark_11.png): the app draws a white (surface) tail that extends ≈10 px further down than the design's (23 px tall vs 13 px). The bubble body is already correct.

DO (app/lib/core/design_system/components/nest_pet_stage.dart, NestSpeechBubble):
- Paint the tail exactly as the CSS describes: an ink triangle, 18 wide × 9 tall, centred horizontally, its top edge flush with the bubble's outer bottom edge, and no surface-coloured inner triangle.
- The bubble's laid-out height is unchanged (the tail is overflow, as in CSS). Nothing below moves.
- Light and dark both use the ink token.
TEST: with real fonts, the tail's painted rect is 18 ±0.5 wide and 9 ±0.5 tall, centred on the bubble, starting at the bubble's bottom. Sample the colour at the tail centre: ink. 1 px below the tail tip: background. The bubble's overall laid-out height is unchanged.
DONE = dart format clean, flutter analyze "No issues found!", full flutter test green, docs/screens/_shared/speech_tail_REPORT.md, committed.
