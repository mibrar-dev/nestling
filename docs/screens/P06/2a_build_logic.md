# P06 Pocket money setup — logic build (Stage 2a, iteration 5)

## CONTRACT CHANGES

No event/state shape changes and no repository interface changes — the UI
builder's contract is untouched (same events, `PocketMoneyState.setup`,
same `watchSetup/setMode/setPayoutDay/setWeeklyBasePence` signatures; all
three feature fakes still compile untouched). Behavior refinements only,
all inside `domain`/`data`/`bloc` (see below).

## Files changed (logic layer only — no views/widgets touched)

- `app/lib/features/pocket_money/data/pocket_money_repository_impl.dart`
  - Review #9: `watchSetup` no longer subscribes to the `settings` mirror
    (`combineLatest3` → `combineLatest2` over the `families` row + insertion-
    ordered children). The mirror is written in the same transaction as
    `families`, so the extra subscription only re-emitted identical setups.
    No test depended on settings-driven re-emission (verified by grep).
  - Review #12: `setMode`/`setPayoutDay` now also throw `ArgumentError` past
    the `assert`, so the invariant holds in release/profile builds. In debug
    the assert still fires first, which the existing validation tests pin
    (`throwsA(isA<AssertionError>())` — green, unchanged).
- `app/lib/features/pocket_money/presentation/bloc/pocket_money_bloc.dart`
  - Review #10: `if (emit.isDone) return;` before the failure emits in
    `_onModeChanged` and `_onPayoutDayChanged` (a write in flight across
    `bloc.close()`). The day-guard rollback still runs first, as the review
    requires. (`_onWeeklyBaseStepped` already had the guard.)
- No test files needed changes: every existing assertion still describes the
  behavior (validation asserts, write-through re-emits, guard/rollback
  paths, BUG-01/02/06/07/09 proofs).

Note: `git diff` also shows hunks in
`presentation/views/pocket_money_setup_view.dart` — those are the parallel
UI builder's partial edits (per ORCHESTRATOR_NOTES 05:36 they hit a rate
limit), not mine; I did not touch that file.

## Items done (FIXES_4 → review findings, logic-layer only)

- #9 (wasted `watchSetting` subscription): fixed as above.
- #10 (`emit` after `await` without `isDone`): fixed as above.
- #12 (assert-only validation): fixed as above, debug behavior preserved.
- Everything else in FIXES_4 is view/test/UI-check territory for the UI
  chunk or integrator and was deliberately not touched: #1 (44 px day row
  geometry), #2 (analyze `info` in the view *test* file — outside my
  filename scope), #3 (`NestBalancedText`, needs a main merge per the test
  stage), #4 (`disposeApp` teardowns in view tests), #5–#8/#11/#14 (view
  copy/tokens/pill/buildWhen), #13 (BUG-04 skip — justified, orchestrator
  item 2 makes 44 px width impossible), P06-BUG-10 (view heading).
- Skipped bug tests in my layer: none — the only skip in
  `p06_bugs_test.dart` remains the justified view-layer BUG-04 probe.

## Checks run (stage-allowed only)

- `dart format` on touched files → clean.
- `flutter analyze` on domain + data + bloc + the three test files →
  `No issues found!`
- `flutter test pocket_money_setup_bloc_test +
  pocket_money_setup_repository_test` → `All tests passed!` (45/45).
- `flutter test p06_bugs_test` → `All tests passed!` (+24 ~1; the single
  skip is the justified BUG-04 width probe).
- Full-app `flutter test` and simulator NOT run (integrator owns them;
  per the new SIMULATORS rule only the UI-check stage may boot one).

## LEFT FOR NEXT ITERATION

Nothing in the logic layer. Open items for the UI chunk / integrator:
the view-geometry fixes (#1), `NestBalancedText` adoption after merging
main (#3, P06-BUG-10), view-test hygiene (#2, #4), and view minors
(#5–#8, #11, #14).

VERDICT: PASS
