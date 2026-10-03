Fix NestChip: the 14 px side padding is outside the pill, so pills are only as wide as their text.

EVIDENCE: docs/screens/P05/ui/cmp_light_7.png on branch screen/P05 (worktree ../nestling-screens/P05).
- Age-band chips "4–6", "7–9", "10–12", "13+": the design pills are 32 px high and text width + 28 px wide. Example: "4–6" ≈ 54 px.
- The app pills are only as wide as the text. The selected "7–9" pill renders as a narrow vertical oval.

CAUSE: app/lib/core/design_system/components/nest_chip.dart around lines 85–100:
`ConstrainedBox(minWidth: 44) → Padding(horizontal: gap14) → DecoratedBox(decoration) → content`
The padding sits OUTSIDE the DecoratedBox, so the background and the 1.5 px border paint only behind the text.

CSS (design/html-source/components.css:120):
`.chip { display:inline-flex; align-items:center; height:32px; padding:0 14px; border-radius: pill; background: surface-2; font 14/600; border:1.5px solid transparent }`
`.chip.selected { background: leaf-tint; color: leaf-ink; border-color: leaf }`

DO:
1. Move the padding INSIDE the decoration: `DecoratedBox(decoration) → Padding(horizontal 14) → content`, keeping the height at exactly 32. The decorated pill must be text width + 28 px wide.
   - Keep the 44 px minimum TAP width via the existing `_ExpandedHitBox` / minWidth.
   - The visible pill must NOT be stretched to 44 unless text + 28 < 44. CSS has no min-width on .chip, so a pill narrower than 44 stays narrow visually, and the hit box gives the 44 px.
2. Do not change NestChip.hitSlop, NestChipWrap, or the 32 px layout height.
3. Tests (app/test/core/design_system/nest_chip_test.dart, add to the existing file if present). Load real Inter with FontLoader, as app/test/features/privacy_consent/privacy_consent_geometry_test.dart does.
   - For label "4–6": the DecoratedBox rect width == label paragraph width + 28 (±0.5), and height == 32.
   - The selected chip's border rect == the same pill rect (not the text rect).
   - Tap targets are still ≥ 44×44, including inside a NestChipWrap.
   - Light and dark.
4. Run the whole suite. If a feature test pinned the old (wrong) narrow width, list it in the report with the test name. Do NOT edit feature code.
DONE = dart format clean, flutter analyze "No issues found!", flutter test all green, docs/screens/_shared/chip_pill_padding_REPORT.md written, committed.
