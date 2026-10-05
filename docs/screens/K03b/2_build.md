# 2 BUILD (integrate) — K03b Kid home all done (iteration 3)

Merge of the two parallel builders: `2a_build_logic.md` (logic) +
`2b_build_ui.md` (UI). No redesign; smallest integration change only.

## Summary of 2a (logic)

`KidHomeRepository.completeQuest` behaviour change, signature unchanged:
quest with `needsApproval == false` completes terminally — status
`approved` (+ `decidedAt`/`decidedAtTz`) with a `quest_bonus` ledger credit
in the same transaction (mirrors `ApprovalsRepositoryImpl.approve`);
approval quests keep the `done_pending` write with no ledger row. Flip path
hardened to compare-and-set (`WHERE id + status IN (to_do, not_yet)`, credit
only when a row flips) so a racing retry credits exactly once. Files:
`app/lib/features/kid_home/data/kid_home_repository_impl.dart`,
`app/test/features/kid_home/kid_home_repository_test.dart` (+4 tests,
`K03B-BUG-6 terminal completion` group, 17/17 green).

## Summary of 2b (UI)

No file changes: the iteration-2 UI already satisfies the plan, the K03b
HTML and every owner rule (`_AllDoneBody` with absolute-positioned 320×250
confetti plate, `NestBalancedText("Today's quests")` with U+2019,
`KidStatusChip`, `NestProgress(fraction 1.0)`, same `_QuestCard` list with
`status + needsApproval` row-meta branch, `_AllDoneBar` with surface running
to the physical edge). Verified via owned suites (k03b_all_done 59,
kid_home_view 88, geometry + k03_bugs 70, all green).

## Integration FIXES done

- Un-skipped the parked `K03B-BUG-6` proof
  (`app/test/features/kid_home/k03b_bugs_test.dart:342`, `skip: true` →
  `skip: false`) as handed off by 2a — the fix it proves is the 2a
  repository change. Proof passes un-skipped in the plain suite:
  `flutter test --timeout 120s test/features/kid_home/k03b_bugs_test.dart
  --plain-name "K03B-BUG-6"` → All tests passed.
- `dart format .` → 0 changed (665 files). No import/member mismatches
  between the two halves (logic touched only `data/` + repo test; UI
  touched nothing this iteration) — no further merge fix needed.

## FIXES disposition

- K03B-BUG-1/2/3/4/5: fixed iteration 2, proofs un-skipped and green — untouched.
- K03B-BUG-6: fixed (2a repository change) + proof un-skipped and green (this stage).
- K03B-BUG-2 (latent, shared `_explicitBleed`): stays parked
  (`k03b_bugs_test.dart:220`, `skip: true`) per the 06:44 orchestrator
  ruling — core-owned, D1 forbids touching `core/**`. Not a failure.

## Left

- None. UI check (stage 5) owns the `SEED=kid_all_done` screenshot run.

## Tails

`flutter analyze` → `No issues found! (ran in 3.3s)`

`flutter test --timeout 120s` (full suite) →
`01:42 +5021 ~15: All tests passed!` (+5021 passed, ~15 pre-existing
parked skips, 0 failures)

VERDICT: PASS
