TASK — speech bubble text alignment (shared/speech_align)

Design CSS `.speech` (design/html-source/components.css:191) sets NO `text-align`, so a browser aligns a wrapped bubble's lines to the START (left). `NestSpeechBubble` in app/lib/core/design_system/components/nest_pet_stage.dart:441 hard-codes `textAlign: TextAlign.center`, so every two-line bubble (K03b "You did everything today! Pip / is so proud.", K07 "Hear that? … / song!") centres its lines while the designs start-align them.
1. Change it to `TextAlign.start`. Do not change padding, max width (260), font or the tail. A one-line bubble hugs its text, so its pixels must not move — prove it with a test.
2. Tests: a widget test for a two-line bubble asserting each line's left edge equals the text box's left (start-aligned), and a one-line bubble whose rect is unchanged.
3. Run `cd app && flutter analyze` (No issues found) and `flutter test --timeout 120s` in the FOREGROUND; update only tests that pinned the centred alignment. Commit on this branch. Write docs/screens/_shared/speech_align_REPORT.md ending with `VERDICT: PASS` or `VERDICT: FAIL`.
