# P06 Pocket money setup — logic build (Stage 2a, iteration 6)

## CONTRACT CHANGES

None. No event/state/repository signature changes; no files in the logic
layer needed edits this iteration. The UI builder's contract is exactly as
in iterations 3–5.

## Files changed (logic layer only)

None — verified, no edits needed. FIXES_5 contains zero logic-layer items:

- Findings #1/#2/#3 (MAJOR: H1 `NestBalancedText` collapse, real-font
  geometry test, stepper minus glyph) are view / view-test / shared-
  component matters.
- Findings #4/#5 (day-group semantics label, empty-state copy ratification)
  are view copy/semantics — UI chunk / orchestrator.
- P06-BUG-11 (H1 one-line collapse) and P06-BUG-12 (minus hyphen) were
  rooted in shared components (`nest_balanced_text.dart`, `nest_stepper.dart`)
  that RULES §1 forbids this screen to edit.
- All earlier logic items stay fixed with no regressions: BUG-01 (request
  tracking), BUG-02 (pending-day guard), BUG-06 (`clearErrorMessage`),
  BUG-07 (unknown-child no-op), BUG-09 (confirm-only pending clear),
  review #9 (no `watchSetting` subscription), #10 (`emit.isDone` guards),
  #12 (`ArgumentError` past `assert`).

## Checks run (stage-allowed only, after the fresh main merge `310514a`)

- `flutter analyze` on domain + data + bloc + the three test files →
  `No issues found!`
- `flutter test pocket_money_setup_bloc_test +
  pocket_money_setup_repository_test` → `All tests passed!` (45/45).
- `flutter test p06_bugs_test` → `All tests passed!` (+27, ~0 — the shared
  fixes landed via main and the UI chunk un-skipped the BUG-11/12 proofs;
  no `skip:` remains anywhere in `app/test/features/pocket_money/`).
- Full-app `flutter test` and simulator NOT run (integrator owns them;
  per the SIMULATORS rule only the UI-check stage may boot one).

## LEFT FOR NEXT ITERATION

Nothing in the logic layer. Remaining FIXES_5 view items (geometry pins,
semantics label, copy ratification) sit with the UI chunk / integrator.

VERDICT: PASS
