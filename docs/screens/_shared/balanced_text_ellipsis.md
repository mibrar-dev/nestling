Fix NestBalancedText: with no maxLines, it truncates headings to ONE line with "…".

EVIDENCE: screen/P06 (worktree ../nestling-screens/P06), docs/screens/P06/ui/cmp_light_5.png. The h1 "How does pocket money work in your house?" renders as "How does pocket mone…" on one line, and everything below moves up 34 px. The design has 2 lines.

CAUSE (app/lib/core/design_system/components/nest_balanced_text.dart):
- `overflow` defaults to `TextOverflow.ellipsis`, and `lineCountFor` builds its TextPainter with `ellipsis: '…'` even when `maxLines` is null.
- In Flutter, an ellipsis with no maxLines truncates at the first line. So `lineCountFor` returns 1 and `build` returns `_text()`, which is also an ellipsis Text, so it renders as one line.
- P07 only worked because it passes maxLines.

DO:
1. `overflow` default becomes `TextOverflow.clip`. In `_text()`, pass `overflow: maxLines == null ? TextOverflow.clip : overflow`, so an ellipsis is only applied when there is a line cap.
2. In `lineCountFor`, set `ellipsis: maxLines == null ? null : '…'`.
3. Tests (nest_balanced_text_test.dart, real fonts via FontLoader, as the existing real-font group does):
   - At 350 px with h1 and NO maxLines, "How does pocket money work in your house?" lays out in 2 lines and contains no "…". Assert the line metrics count, and that the RenderParagraph `didExceedMaxLines` is false.
   - The same at 390 and 320 widths.
   - Keep the P07 tests green.
   - With maxLines: 1 and a long text, the ellipsis still appears.
4. grep app/lib for NestBalancedText usages and report each one with its maxLines.
DONE = dart format clean, flutter analyze "No issues found!", flutter test all green, docs/screens/_shared/balanced_text_ellipsis_REPORT.md written, committed.
