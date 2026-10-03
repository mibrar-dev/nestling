# 2a — Build, logic chunk (iteration 1) — P13 Payout

## CONTRACT CHANGES

None. Event name, constructor shape and handler semantics are exactly as
`1_plan.md` §b specifies (`PocketMoneyPayoutSubmitted(childId, amountPence,
savingsMovePence, goalId)`; write-through via `recordPayout`; failure keeps
`loaded` + friendly `We couldn’t save that` message). The UI builder can code
against the plan unchanged.

## Files changed (logic layer only — no views/widgets touched)

- `app/lib/features/pocket_money/presentation/bloc/pocket_money_event.dart`
  — added `PocketMoneyPayoutSubmitted` per plan §b (positional
  childId/amountPence/savingsMovePence/goalId, documented savings rule).
- `app/lib/features/pocket_money/presentation/bloc/pocket_money_bloc.dart`
  — registered `on<PocketMoneyPayoutSubmitted>` and added
  `_onPayoutSubmitted`, mirroring the P12 add/spend handlers: forwards to
  `recordPayout`, `emit.isDone` guard, failure emits `copyWith(errorMessage:
  _submitErrorMessage(error))` with status staying `loaded`.
- `app/test/features/pocket_money/payout_bloc_test.dart` (new) — plan §f
  item 1: forwards `(maya, 420, 100, goal-lego)`; zero-save variant passes
  `(0, null)`; rejected write keeps `loaded` + `We couldn’t save that:
  <cause>` (U+2019); accepted submit emits nothing optimistically.
- `app/test/features/pocket_money/payout_repository_test.dart` (new) —
  plan §f item 2: seeded-DB `recordPayout` writes payout −420 +
  savings_move +100, goal 1550 → 1650, Maya owed → 0, Leo untouched at
  £2.10 (150 + 60); zero-save writes only the payout row.

No domain/data change was needed: `recordPayout` (negative `payout` row +
optional `savings_move` + goal bump in one transaction) already exists, as
the plan states. No DI/route change: `payoutRoute` (`/payout`, top-level,
`BlocProvider` + `PocketMoneyLoadRequested`) already registered. No
SHARED_REQUEST.

## Items done (plan §b + §f logic items)

- [x] `PocketMoneyPayoutSubmitted` event
- [x] `_onPayoutSubmitted` handler
- [x] `payout_bloc_test.dart` (4 tests)
- [x] `payout_repository_test.dart` (4 tests)
- [x] `dart format` clean on touched files
- [x] `flutter analyze lib/features/pocket_money` → No issues found
- [x] `flutter analyze` on the two new test files → No issues found
- [x] New tests: 8/8 pass
- [x] Existing suites still green: `pocket_money_ledger_bloc_test.dart` +
  `pocket_money_repository_test.dart` (36 tests) pass; no `google_fonts`
  references in feature lib/tests

## LEFT FOR NEXT ITERATION

Nothing in the logic layer. Remaining plan items (§a sheet/view, §c–§e
view behaviour, view/geometry/responsive tests, `shot.sh`/`compare.py`)
belong to the UI builder / integrator stages.

VERDICT: PASS
