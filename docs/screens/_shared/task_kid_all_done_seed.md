TASK — K03b support: an "all done" seed (shared/kid_all_done_seed)

K03b (design/html-source/screens/K03b-kid-home-done.html, PNGs in design/screens/*/K03b-*.png) is Maya's kid home when EVERY one of her quests for the current period is done ("6 of 6 done", "All done!").
1. In `app/lib/core/data/seed.dart` add `Seed.kidAllDone(db)`: run exactly `demo(db)`, then add quest_completions so that each of Maya's quests that is not yet done in the CURRENT period (use `countsForCurrentPeriod` / `londonDayStartUtc` from core/data/london_time.dart, times from `clock.now()` / `Seed.anchorDay`, ids via `newId`) gets a completion. Match each quest's completion status to the K03b HTML's per-row label ("Approved by Mum" → approved, "Done" / waiting → pending). Do not change Leo, or any other table. Ledger/coin effects: follow exactly what the existing completion/approval code would write for approved completions (read the repositories), so balances stay consistent.
2. Wire `SEED=kid_all_done` into `app/lib/app/launch.dart` (+ the comment in launch_flags.dart).
3. `docs/screens/SCREENS.tsv`: K03b seed column → `kid_all_done`.
4. Tests: a seed test proving Maya has 6 of 6 done in the current period (pinned clock) and Leo unchanged vs demo.
Do NOT edit any feature view code. Run `cd app && flutter analyze` (No issues found) and `flutter test --timeout 120s` in the FOREGROUND (all green). Commit on this branch. Write docs/screens/_shared/kid_all_done_seed_REPORT.md ending with `VERDICT: PASS` or `VERDICT: FAIL`.
