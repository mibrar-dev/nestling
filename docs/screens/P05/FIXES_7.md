# Fix list after iteration 7 (orchestrator QA — not merged)

1. AGE-BAND CHIPS LOOK WRONG (cmp_light_7 / cmp_dark_7). The pills are only as wide as their text; "7–9" selected shows as a narrow vertical oval. The design pills are text + 28 px wide and 32 px high.
   - Root cause is shared: NestChip's padding is outside its decoration. Branch shared/chip_pill_padding fixes it on main, and main is merged into your branch before this build.
   - After the merge, check that the age chips match the design: 4–6 ≈ 54 px, 7–9, 10–12, 13+.
   - Do NOT add local padding hacks.
   - Update any P05 test that pinned the old narrow width.
2. P05-BUG-11 (shared fix NestChipWrap is now on main): replace BOTH `Wrap`s of interactive items in app/lib/features/family/presentation/widgets/add_child_form_card.dart (age chips, line ~74) with `NestChipWrap`.
   - The swatch row (~line 101) may stay a Wrap only if each swatch's tap target is already ≥ 44×44 inside the row; check and say so in the report.
   - Un-skip [P05-BUG-11] in p05_bugs_test.dart and restore `atLeast44(chip)` in add_children_test.dart (~line 2282–2330): taps 5 px above and below a chip select it.
3. Re-shoot cmp_light_8/cmp_dark_8 and confirm that the chip pill backgrounds match the design widths.
