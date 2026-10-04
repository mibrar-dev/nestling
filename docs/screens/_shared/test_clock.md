URGENT — main is red (34 failures). Pin ONE clock for the app in tests, so "today" in the app equals the seed's pinned story day.

ROOT CAUSE (read docs/screens/_shared/family_time_test_fix_REPORT.md lines 76-99 on main):
- app/test/flutter_test_config.dart pins `Seed.anchorOverride = 2026-10-03`, so the seed data lives on Sat 3 Oct 2026.
- But app code reads `DateTime.now()` directly (≈15 files: grep `DateTime.now()` in app/lib). Since the real date became 4 Oct, views compute "today" / "Today 8:12am" / periods from the real clock and disagree with the seed.
- Failing on main: P08 p08_bugs_test period scoping, P11 approvals "Today 8:12am", K03 home matrix/navigation, ~34 tests.

FIX:
1. Use the `clock` package (dart-lang; add `clock: ^1.1.x` to app/pubspec.yaml if not already a transitive dependency made direct). Replace EVERY `DateTime.now()` in app/lib/** with `clock.now()` (import 'package:clock/clock.dart'). This task explicitly allows that mechanical edit in app/lib/features/**. Change no other behaviour. `AppSession`'s injectable clock should default to `clock.now`.
2. In app/test/flutter_test_config.dart, run testMain inside `withClock(Clock.fixed(<2026-10-03 09:41 Europe/London as UTC = 2026-10-03T08:41:00Z>), …)`, keeping `Seed.anchorOverride = 2026-10-03`. The 9:41 matches the designs' status bar and comes after the seeded morning events (8:12, 8:05, 7:58).
   - Check that `testWidgets`' FakeAsync reads the zone clock: package:fake_async uses `clock`. Prove it with a test that, inside testWidgets, `clock.now()` equals the pinned instant (± elapsed fake time).
   - Tests that already pin their own clock (AppSession tests, family_time DST tests) must keep working: their explicit clocks/withClock win.
3. Run the FULL suite: it must be green with 0 failures. Then verify with the real date: temporarily set the fixed clock to 2026-10-05 08:41Z AND anchorOverride to 2026-10-05, run the suite, then restore. Report the result. This proves that test outcomes depend only on the pinned pair.
4. Add one rule to docs/screens/RULES.md: "App code never calls DateTime.now(); use clock.now() (package:clock). Tests are pinned to Sat 3 Oct 2026 09:41 London."
DONE = dart format clean, flutter analyze "No issues found!", full flutter test green (0 failures), docs/screens/_shared/test_clock_REPORT.md, committed.
