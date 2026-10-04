
## UPDATE (17:14) — the plan file was restored
docs/screens/P09/1_plan.md was briefly overwritten with a 4-line stub by a loop bug. The full 258-line plan is back on disk. Builders: re-read it now.

## UPDATE (17:57, orchestrator QA of cmp_light_1, 1.71%)
1. Icon picker: the 6 glyphs and their ORDER must be exactly the design's (read the HTML for the icon names; light and dark PNGs). If a glyph is missing from app/assets/icons, write SHARED_REQUEST.md with the exact names and SVG source (from design/html-source) rather than substituting a look-alike.
2. "Hoover the stairs" text in the Quest name field starts at x ≈ 40; the design has x ≈ 37 (field x 20 + 1 px border + 16 px padding). Check NestTextField's horizontal content padding for this variant. If the cause is shared, write SHARED_REQUEST with the numbers.
3. Everything else is within tolerance. Do not move other elements.

## UPDATE (19:19) — iteration 3
- Icons, NestToggle track, stepper minus and field text inset are SHARED and being fixed on shared/shared_batch5. They are NOT P09 findings this pass: do not substitute icons.
- Fix only the P09-local items from FIXES_2.md: review minors such as Cancel tooltip coupling, rebuild scope, onError on both subscriptions, and Due-by semantics; plus the test/bugs findings that are local.
- When main has batch5 (merged before the next build), switch the picker to the icon names in docs/screens/_shared/shared_batch5_REPORT.md and remove `toggleTrackOffset`.

## UPDATE (20:09) — batch 5 is on main and merged into this branch during the integrator run
Integrator: switch the icon picker to `NestIcons.questBed / questDishes / questHoover / questBins` (in the design order) and delete the `toggleTrackOffset` Transform.translate, as in docs/screens/_shared/shared_batch5_REPORT.md lines ~87-90 and ~209.

## UPDATE (23:03) — integrator, iteration 4: NestToggle on main now lays out its 51×31 track itself, so `QuestEditorMetrics.toggleTrackOffset` (Transform.translate(4,-2)) now double-shifts the switch. DELETE the offset and its Transform. The track must land at x 303→354, y 620.5→651.5 (design), so pin it in the geometry test.

## UPDATE (23:55) — known red test on main, NOT your finding
`test/core/family_time_test.dart` › 'kid_home completions are stamped with the family zone' fails since the date rolled to 4 Oct. It is a date-dependent test bug on main, being fixed by shared/family_time_test_fix. If it is the ONLY failing test in the full suite, treat the gate as green for this screen.

## UPDATE (00:25, orchestrator QA of cmp_light_4, 1.37%) — iteration 5: one item
The layout and icons match the design. Fix ONLY P09-TEST-6 (3_test.md): in debug builds the coin guard's assert text leaks into the toast. The toast must show the product copy only, in debug and release, with a test. The family_time_test failure is fixed on main (it is merged before the build). Change nothing else.
