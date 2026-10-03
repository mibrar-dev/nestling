# 2a — Build, logic chunk (iteration 3) — P13 Payout

Scope: logic layer only (`domain`/`data`/`bloc` + `*bloc*`/`*repository*`
tests). Views/widgets untouched (UI builder's parallel lane).

## CONTRACT CHANGES

None. No signature or event/state shape changed this iteration.

## Files changed

None in `app/lib` or `app/test` — iteration 3 required no logic-layer
edits (disposition below). This file is the stage's only write.

## FIXES_2 disposition (logic-layer items only)

FIXES_2 carries exactly four item groups, and **none of them is in this
layer**:

- P13-I2-01 / P13-BUG-06 (minor, the one open bug: `Move £1.00 of Leo's to
  her Lego fund` for a goal-bearing Leo) — lives in
  `PayoutSaveRow.label` (`presentation/widgets/payout_sheet.dart:421-427`),
  which keys the design-verbatim string off the goal *title* containing
  "lego". Not fixable from this layer: `Children` has no gender/pronoun
  column, and the iteration-2 test stage explicitly routes the tension
  (seeded design string vs DATA OVER MOCKS for non-Maya goal children) to
  the orchestrator as a product decision. The logic side is neutral:
  `payoutSaveChildId` (widgets, creation order) and `goalFor`/`owedFor`
  return data only. No edit made; no edit possible here without breaking
  the seeded verbatim path.
- 5_ui deviations (summary-card text centering, saverow toggle −4 px) —
  both in `payout_view.dart` / `payout_sheet.dart`. UI builder's lane.
- Whole-repo gate failure (`test/core/family_time_test.dart`, Dubai
  day-rollover vs wall clock) — shared `core` code, outside RULES §1,
  already filed as SHARED_REQUEST #2. Not touchable from this worktree
  lane; process item for the orchestrator.
- ORCHESTRATOR_NOTES 1–3 (scrim, inline amounts, row y) — all view-side,
  all verified done in iteration 2. No change since.

## Verification (post-merge `9e1663e`, no logic edits pending)

- `flutter analyze lib/features/pocket_money` + both owned test files →
  No issues found. No `google_fonts` in feature lib/tests.
- Owned tests: `payout_bloc_test.dart` (7) + `payout_repository_test.dart`
  (6) — 13/13 pass, including the BUG-01/02/04/review-#3 regression pins.
- Neighbour logic suites (read-only rerun): ledger bloc + ledger
  repository + setup bloc + setup repository + next_payout — all pass
  (101 total with owned files, 0 failures).
- View/widget suites deliberately not run: the UI builder owns them and
  the integrator runs the full feature dir after the merge. No simulator
  used at any point.

## LEFT FOR NEXT ITERATION

- UI builder: summary-card alignment, toggle right-flush (5_ui 1–2).
- Orchestrator: product decision on the saverow pronoun for non-Maya goal
  children (P13-I2-01/BUG-06); shared `family_time` gate failure
  (SHARED_REQUEST #2, fails every loop past 20:00 UTC).
- Integrator/test stage: retire the BUG-06/I2-01 reproducers once the copy
  decision lands.

VERDICT: PASS
