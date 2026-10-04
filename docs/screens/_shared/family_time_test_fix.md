Main is RED: app/test/core/family_time_test.dart › "seed + repository zone plumbing › kid_home completions are stamped with the family zone" fails with `Bad state: Too many elements`. It started failing when the real date rolled to 2026-10-04.
CAUSE: the test calls `repo.completeQuest('maya', 'q-reading')`, then selects ALL q-reading completions and calls `.single`. The demo seed already contains q-reading completion rows dated relative to today (Seed.anchorDay), so depending on the date the query returns 2 rows. It is a test bug, not an app bug. Same risk for 'leo'/'q-plants' just below.
FIX (test only, unless you find a real app bug):
- Identify the row the call just created: record the ids or count before the call and select the new one, or filter on `createdAt >= the instant before the call`. Keep the assertion: that row's createdAtTz is London, and after Seed.movedToDubai it is Dubai.
- Make it deterministic regardless of the real date. Check the rest of family_time_test.dart and app/test/core/** for the same `.single`-after-seed pattern, and fix those too.
- Prove it: run the test with the clock pinned to several dates (Seed.anchorDay variations, if the test config allows), and run the full suite.
DONE = dart format clean, flutter analyze "No issues found!", full flutter test green, docs/screens/_shared/family_time_test_fix_REPORT.md, committed.
