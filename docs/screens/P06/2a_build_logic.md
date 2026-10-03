# P06 Pocket money setup — logic build (Stage 2a, iteration 6)

## CONTRACT CHANGES

None. No event/state/repository signature changes; no files in the logic
layer needed edits this iteration. The UI builder's contract is exactly as
in iterations 3–5.

## Files changed (logic layer only)

None — verified, no edits needed. FIXES_5 contains zero logic-layer items:

- Findings #1/#2/#3 (MAJOR: H1 `NestBalancedText` collapse, real-font
  geometry test, stepper minus glyph) are view / view-test / shared-
  component matters. #1 and #3 are blocked on shared fixes
  (`balanced_text_ellipsis`, `NestStepper` U+2212) owned by main; #2 is a
  widget geometry test in the UI chunk's filename scope.
- Findings #4/#5 (day-group semantics label, empty-state copy ratification)
  are view copy/semantics — UI chunk / orchestrator.
- P06-BUG-11 (H1 one-line collapse) and P06-BUG-12 (minus hyphen): both
  reproduced by skipped proofs in `p06_bugs_test.dart`, both rooted in
  shared components (`nest_balanced_text.dart`, `nest_stepper.dart`) that
  RULES §1 forbids this screen to edit. Correctly left skipped for the
  shared fix + UI chunk; un-skipping them in my stage would fail for
  reasons outside this feature's sandbox.
- All earlier logic items stay fixed with no regressions: BUG-01 (request
  tracking), BUG-02 (pending-day guard), BUG-06 (`clearErrorMessage`),
  BUG-07 (unknown-child no-op), BUG-09 (confirm-only pending clear),
  review #9 (no `watchSetting` subscription), #10 (`emit.isDone` guards),
  #12 (`ArgumentError` past `assert`).

## Checks run (stage-allowed only, after the fresh main merge `d5112fd`)

- `flutter analyze` on domain + data + bloc + the three test files →
  `No issues found!`
- `flutter test pocket_money_setup_bloc_test +
  pocket_money_setup_repository_test` → `All tests passed!` (45/45).
- `flutter test p06_bugs_test` → `All tests passed!` (+25 ~2; the 2 skips
  are BUG-11/BUG-12, shared/view-layer as above).
- Full-app `flutter test` and simulator NOT run (integrator owns them;
  per the SIMULATORS rule only the UI-check stage may boot one).

## LEFT FOR NEXT ITERATION

Nothing in the logic layer. Open items for the UI chunk / shared track /
integrator: BUG-11 + BUG-12 (pending the shared-component fixes, then
un-skip the two proofs), the real-font geometry pins, and the view findings
carried in FIXES_5.

VERDICT: PASS
