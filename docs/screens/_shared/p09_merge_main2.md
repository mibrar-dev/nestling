ROLE: Senior Flutter engineer (sub-agent). Working dir = the P09 worktree (branch screen/P09). Other agents are editing quest-editor files in this worktree right now: do NOT touch, stash, reset or commit them.
TASK: merge `main` into this branch. The only conflict is app/test/features/today/p08_bugs_test.dart: P11 (merged on main) and P09 both replaced placeholder-title assertions with route assertions.
1. `git merge --no-commit main`. If git refuses because of local changes, STOP and report: do not stash.
2. Resolve p08_bugs_test.dart by keeping BOTH sides: main's `/approvals` assertions via `pushedPath(tester)` plus P09's `/quest-editor` assertions (same helper). No duplicate test names, and no placeholder title text assertions.
3. `git add` ONLY that file plus the files the merge itself brought in, then `git commit -m "P09: merge main (P11) — p08_bugs_test conflict resolved"` ending with "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>". Do NOT add the other agents' working files.
4. `cd app && flutter test test/features/today` must be green.
5. Write docs/screens/P09/MERGE_MAIN2_REPORT.md, ending with `VERDICT: PASS` or `VERDICT: FAIL`.
