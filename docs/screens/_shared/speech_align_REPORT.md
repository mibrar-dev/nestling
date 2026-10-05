# Report — shared/speech_align: speech bubble text alignment

## Files changed
- `app/lib/core/design_system/components/nest_pet_stage.dart` — `NestSpeechBubble`: `textAlign: TextAlign.center` → `TextAlign.start`, plus a 4-line comment citing the CSS rule. Nothing else touched (padding `8/14`, `maxWidth` 260, Nunito 800/16, force-strut, tail geometry all unchanged).
- `app/test/core/design_system/nest_pet_stage_test.dart` — two new widget tests in the existing `NestSpeechBubble matches .speech` group.
- `docs/screens/_shared/speech_align_REPORT.md` — this report.

## What / why
Design CSS `.speech` (`design/html-source/components.css:191`) sets no `text-align`, so the browser start-aligns (left) a wrapped bubble's lines. The widget hard-coded `TextAlign.center`, so every two-line bubble (K03b "You did everything today! Pip is so proud.", K07 evolution copy) centred its lines while the designs start-align them. One line changed to `TextAlign.start`, the Flutter equivalent of the browser default. Line breaking is unaffected by `textAlign` (same break opportunities, same outer size) — only the horizontal offset of short lines changes — so this is backward-compatible for every screen using the bubble (K03, K03b, K04, K05, K07, K10).

## Tests added (`app/test/core/design_system/nest_pet_stage_test.dart`)
- `two-line bubble lines start-align with the text box` — pumps `NestSpeechBubble('You did everything today! Pip is so proud.')`, asserts `textAlign == TextAlign.start`, takes the `RenderParagraph`'s `getBoxesForSelection` over the full text, asserts ≥2 line boxes, asserts the last line is shorter than the full width (so the test discriminates), and asserts every line's `left` is `closeTo(0, 0.5)`. Verified it FAILS with the old `TextAlign.center` (reverted, ran, re-applied).
- `one-line bubble rect is unchanged by start alignment` — pumps `NestSpeechBubble("Let's do some quests!")`, asserts the body hugs its text (width < 260), then pumps a hand-built centred twin with identical padding/border/style/strut and asserts identical laid-out size — proving one-line bubble pixels do not move.

## Existing tests
No existing test pinned the centred bubble alignment (the `TextAlign.center` assertions in `payout_states`, `quest_library_states`, `privacy_consent_geometry`, `pip_evolution_copy` cover unrelated widgets), so none needed updating. Full `flutter test --timeout 120s`: all pass (4617 passed, 13 skipped, 0 failed). `flutter analyze`: No issues found.

## Follow-up for screens
None required. Two-line bubbles on K03b/K04/K05/K07/K10 now start-align like the designs; one-line bubbles are pixel-identical. Screen geometry pins on bubble outer rects are unaffected (outer size is alignment-independent).

VERDICT: PASS
