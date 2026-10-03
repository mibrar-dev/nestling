NestTextField.search: centre the text vertically and make the field 54 tall (border box), matching `.search`.

READ (read-only): ../nestling-screens/P10/docs/screens/P10/SHARED_REQUEST.md §9 and §10, ../nestling-screens/P10/docs/screens/P10/5_ui.md, ../nestling-screens/P10/docs/screens/P10/ui/cmp_light_3.png.
MEASURED at 390×844 on P10 (design → app):
- field box: 173.0–227.0 (54 tall, border box: 4+44+4 content + 1 px borders) → app 173–225 (52)
- hint/input text ink centre: 201.2 (field centre 200) → app 190.2 (11 px too high: the hint is painted at the top of its intrinsic line box, not centred in the 44 px slot)
- icon centred: already OK.
FIX in app/lib/core/design_system/components/nest_text_field.dart (search variant only):
- The field is 54 tall overall, with 1 px borders inside.
- The editable text and the hint are vertically centred in the 44 px content slot: textAlignVertical center plus suitable contentPadding / isDense / constraints, or a strut, whatever centres it for real with the bundled Inter.
- Fix the doc comment ("52-high").
- Keep the icon at x+16 and the hint at x+50.
TESTS (real fonts via FontLoader):
- The field rect is 54 ±0.5 tall.
- The hint ink centre equals the field centre ±1.
- The typed text centre equals the field centre ±1.
- Icon x+16 and hint x+50 unchanged.
Other NestTextField variants are unchanged and all existing tests stay green.
DONE = dart format clean, flutter analyze "No issues found!", full flutter test green, docs/screens/_shared/search_field_fix_REPORT.md, committed.
