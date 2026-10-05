TASK — FINISH shared/p08b_shell. The previous run made all the edits (see `git status`) but ended while the test suite was still running in the background. Do NOT redo the edits.
1. Read `docs/screens/_shared/task_p08b_shell.md` (the original task) and check the uncommitted diff satisfies items 1–3; fix only real gaps.
2. Run in the FOREGROUND (never background): `cd app && flutter analyze` then `flutter test --timeout 120s`. Fix any failure your change caused.
3. Commit everything on this branch, write docs/screens/_shared/p08b_shell_REPORT.md (diff summary, tests, full-suite counts) and end it with `VERDICT: PASS` or `VERDICT: FAIL`.
