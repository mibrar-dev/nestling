# P06 Pocket money setup — logic build (Stage 2a, iteration 3)

## CONTRACT CHANGES

No event/state shape changes — the UI builder's contract is untouched
(`PocketMoneyModeChanged(mode)`, `PocketMoneyPayoutDayChanged(day)`,
`PocketMoneyWeeklyBaseStepped(childId, deltaPence)`, `PocketMoneyState.setup`;
step stays 50p; repository clamps 0..2000). Additive only, all inside the
feature sandbox:

- `PocketMoneySetup.withChildBase(id, pence)` (new pure helper, insertion
  order kept) — used for the post-write confirmation emit.
- `PocketMoneyState.copyWith(..., {clearErrorMessage = false})` (new optional
  flag; default preserves old behavior) — the load path passes it on every
  emission so a stale `errorMessage` cannot survive recovery (P06-BUG-06).
- Private bloc fields only (`_pendingDay`, `_requestedBase`); no DI/route
  changes.

## Files changed (logic layer only — no views/widgets touched)

- `app/lib/features/pocket_money/presentation/bloc/pocket_money_bloc.dart`
  - `_onWeeklyBaseStepped`: unknown child id returns before any repository
    call (P06-BUG-07; also covers pre-load, when there is nothing to step);
    each request builds on the previous *request* via `_requestedBase`,
    recorded synchronously before the first await, so overlapping rapid taps
    accumulate instead of losing updates (P06-BUG-01 — an instrumented probe
    proved the two handlers overlap while a Drift write is in flight; the
    first optimistic-only attempt still lost one tap, the request tracking
    fixed it: writes 350 then 400, DB 400); request forgotten on write
    failure; successful write confirmed in state via `withChildBase`
    (stream emission converges and dedups; clamped no-ops emit equal state
    and stay silent).
  - `_onPayoutDayChanged`: no-op guard compares against the last *requested*
    day (`_pendingDay ?? setup`), so a fast Sun→Sat correction is not dropped
    (P06-BUG-02); pending cleared on every load emission, rolled back if its
    own write throws.
  - Load `onData`: clears `_pendingDay`, reconciles `_requestedBase` against
    confirmed values, and clears `errorMessage` (P06-BUG-02/06).
  - Write-error behavior unchanged (`failure` + message — pinned by the three
    existing throwing-write tests); BUG-05's user-visible half (failure body
    replacing a valid form) needs the view branch gated on `setup == null`,
    which is the UI chunk's file.
- `app/lib/features/pocket_money/domain/entities/pocket_money_setup.dart` —
  added `withChildBase`.
- `app/lib/features/pocket_money/presentation/bloc/pocket_money_state.dart` —
  added `clearErrorMessage` flag.
- `app/test/features/pocket_money/pocket_money_setup_bloc_test.dart` —
  unknown-child test now expects zero repository calls; replaced the
  KNOWN-DEFECT comment with the fix note; added 3 regression tests
  (double-step accumulates, Sun→Sat not dropped, message clears on recovery).
- `app/test/features/pocket_money/p06_bugs_test.dart` — un-skipped the 4
  logic-layer proofs P06-BUG-01/02/06/07 (all pass); header comment updated;
  BUG-03/04/05 left skipped (view layer — UI chunk owns them). No fake
  changes needed (repository interface unchanged, so all three feature fakes
  still compile).

## Items done (FIXES_2, logic-layer only)

- P06-BUG-01 (MAJOR): fixed + un-skipped proof passes (real repo: £3.00 → £4.00).
- P06-BUG-02 (minor): fixed + un-skipped proof passes (ends Saturday).
- P06-BUG-06 (minor): fixed via `clearErrorMessage` on load emissions +
  post-write confirm; un-skipped proof passes.
- P06-BUG-07 (minor): fixed (early return) + un-skipped proof passes
  (`baseWrites` empty); pinned bloc test updated to the fixed behavior.
- Review #3 (stale message): same fix as BUG-06. Review #4 (`assert` →
  `ArgumentError`): NOT changed — `1_plan.md` §2 mandates asserts and two
  test groups pin `AssertionError`; release-hardening is an orchestrator call.
- No skipped tests remain in my layer; no `google_fonts`/`GoogleFonts.*` in
  the logic layer or its tests.

## Checks run (stage-allowed only)

- `dart format lib/features/pocket_money
  test/features/pocket_money/pocket_money_setup_bloc_test.dart
  test/features/pocket_money/p06_bugs_test.dart` → clean.
- `flutter analyze lib/features/pocket_money` + the three test files →
  `No issues found!`
- `flutter test .../pocket_money_setup_bloc_test.dart
  .../pocket_money_setup_repository_test.dart` → `All tests passed!` (34/34).
- `flutter test .../p06_bugs_test.dart` → `All tests passed!`
  (+14 ~1 on re-verification: the 4 un-skipped logic proofs + 8
  attacks-that-hold green, plus the UI chunk's BUG-04/05 fixes; the 1 skip
  is BUG-03, view/shared layer).
- Full-app `flutter test` and simulator NOT run (integrator owns them).
- Re-verified on re-run: logic layer analyzes with zero issues (the single
  remaining `info` is in the UI chunk's view file); bloc+repo 34/34 green.

## LEFT FOR NEXT ITERATION

Nothing in the logic layer. Handoff to the UI chunk / integrator (re-verified
this run — the UI chunk has since fixed + un-skipped BUG-04 and BUG-05):
- BUG-03 still skipped (day-pill paint size — needs the shared `NestChip`
  compact/`labelStyle` follow-up from `1_plan.md` §7).
- One `info` lint remains in the UI chunk's file
  (`pocket_money_setup_view.dart:556 avoid_redundant_argument_values`); the
  logic layer analyzes with zero issues.

VERDICT: PASS
