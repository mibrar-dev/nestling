NestListRow: the trailing widget steals half the width, which truncates subtitles and puts the chevron mid-row.

FILE: app/lib/core/design_system/components/nest_list_row.dart ~74-97.
- The text column is `Expanded`, and the trailing is `Flexible(child: tail)`. Both have flex 1, so the text gets only HALF of the free width.
- Seen on P16 Settings (read-only: ../nestling-screens/P16/docs/screens/P16/ui/cmp_light_1.png): "Pip: Fledgling · 120 …" is truncated (the design shows "Pip: Fledgling · 120 coins") and "›" sits mid-row, not at the right edge (design: chevron right edge = row content right edge).
- P15 hit the same problem and worked around it in its own row.

FIX:
1. Trailing takes its intrinsic width at the right edge: a plain child after the Expanded text column, with the design's gap (check `.row` in components.css: gap 12). Keep a max-width guard so a long trailing string cannot overflow: use `ConstrainedBox(maxWidth: …)` and let the text column shrink first only when the trailing is wider than its cap.
2. ROW HEIGHT: P16 rows measure ≈ 2 px taller than the design. Design `.row`: check the padding and min-height in components.css (≈ 60 tall for title 22 + caption 18). Make NestListRow's laid-out height equal the CSS. Measure against design/screens/light/P16-settings.png ÷3: the first card's rows start at y 221, 281, 341.
3. Tests (real fonts):
   - At 390, "Pip: Fledgling · 120 coins" renders without ellipsis (didExceedMaxLines false).
   - The chevron's right edge = the row content's right edge ±1.
   - The row height matches the CSS.
   - A long trailing "Change" stays intact.
4. grep app/lib/features for local workarounds of this (e.g. P15 child_profile_row.dart) and list them in the report. Do NOT edit feature code.
DONE = dart format clean, flutter analyze "No issues found!", full flutter test green, docs/screens/_shared/list_row_trailing_REPORT.md, committed.
