ROLE: Senior Flutter engineer (sub-agent). Working dir = the P09 worktree (branch screen/P09). App in app/.
TASK: merge `main` into this branch and resolve the conflicts. P10 (Quest library, same `quests` feature) was just merged to main.
1. `git merge main` produces conflicts in:
   - app/lib/features/quests/presentation/bloc/quests_state.dart
   - app/test/features/quests/quests_repository_test.dart (add/add)
2. Resolve by keeping BOTH sides' behaviour:
   - main/P10 is merged and correct: its QuestsState fields (e.g. `ideas`), creation-order assertions, and all its tests must stay.
   - Add P09's additions on top.
   - If both sides added the same test file, combine the test groups. Remove duplicate names and keep every assertion.
   - Quest order is CREATION order (main), never title order.
3. Then run `cd app && dart format . && flutter analyze` (must print "No issues found!") and `flutter test`. All of P10's tests must be green. P09 tests that fail because P09 is unfinished may stay failing, but list them.
4. Commit the merge: "P09: merge main (P10 quests) — conflicts resolved", ending with "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>".
5. Write docs/screens/P09/MERGE_MAIN_REPORT.md: which conflicts, how each was resolved, and the test results. The last line must be `VERDICT: PASS` (merged, analyze clean, P10 tests green) or `VERDICT: FAIL`.
NEVER: drop main's changes; flutter clean; use a simulator; edit app/lib/core/**.
