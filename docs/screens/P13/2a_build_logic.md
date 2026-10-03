# 2a — Build, logic chunk (iteration 2) — P13 Payout

Scope: logic layer only (`domain`/`data`/`bloc` + `*bloc*`/`*repository*`
tests). Views/widgets (`payout_view.dart`, `payout_sheet.dart`) are being
edited in parallel by the UI builder — not touched here. `p13_bugs_test.dart`
is not in this layer's filename scope, so its `skip:` flags are left for the
integrator/test stage to retire after both builders land.

## CONTRACT CHANGES

None. `PocketMoneyPayoutSubmitted(childId, amountPence, savingsMovePence,
goalId)` keeps its exact shape; `recordPayout` keeps its signature. The
changes below are internal hardening only: a per-child in-flight set in the
bloc, a clear-before-write on the payout error path, and `amount > 0` /
`move ≤ paid` guards in `recordPayout`. The UI builder codes against the
plan unchanged (their in-progress `_submit` already documents "one event per
ticked child that owes money" — consistent with these guards).

## Files changed

- `app/lib/features/pocket_money/presentation/bloc/pocket_money_bloc.dart`
  — `_onPayoutSubmitted`: per-child `_payoutInFlight` re-entrancy guard
  (duplicate event while a write is outstanding is dropped before its
  write; siblings proceed; entry removed in `finally` so failure retries
  stay reachable). Stale `errorMessage` is cleared before the write so a
  repeated identical failure is a state change again (happy path stays
  silent: the message is already null, the cleared state is equal and Bloc
  suppresses it).
- `app/lib/features/pocket_money/data/pocket_money_repository_impl.dart`
  — `recordPayout`: no-op when `amountPence <= 0` (no `Paid £0.00` rows);
  `savingsMovePence` clamped to `min(move, amount)` with the goal bumped by
  the clamped value.
- `app/test/features/pocket_money/payout_bloc_test.dart` (+3: gated
  duplicate dropped; sibling proceeds mid-flight; retry re-surfaces the
  message with a null-clear in between).
- `app/test/features/pocket_money/payout_repository_test.dart` (+2: zero
  amount writes nothing, goal/owed untouched; (50, 100) writes move +50 and
  goal 1550 → 1600).

## FIXES_1 disposition (logic-layer items only)

- P13-BUG-01 (major, double-write): fixed at this layer — duplicate
  in-flight event for the same child never reaches `recordPayout`
  (`attempted == 1` in the skipped reproducer's terms). The view-side busy
  CTA is the UI builder's item.
- P13-BUG-02 (major, unclamped £1.00 move): backstopped at this layer —
  `moved ≤ paid` and `goal delta == moved` hold for any caller. The
  `min(100, owed)` view clamp is the UI builder's item.
- Review #3 (£0.00 child writes `Paid £0.00`): backstopped at this layer —
  zero-amount payouts are a no-op. The `_submit` skip is the UI builder's
  (already in progress per their doc comment).
- P13-BUG-04 (minor, silent identical retry): fixed at this layer —
  clear-before-write makes the repeat failure emit null → message, so the
  view's `listenWhen` fires and the toast returns.
- BUG-03 (scrim), BUG-05 (semantics), review #1/#5–#10, 5_ui deviations,
  ORCHESTRATOR_NOTES 1–3: all view/geometry — UI builder's layer, untouched
  here. Finding 4 (`zz_probe_test.dart`) already deleted in iteration 1.

## Verification

- `dart format` clean on the 4 touched files.
- `flutter analyze lib/features/pocket_money` + both new test files →
  No issues found. No `google_fonts` in feature lib/tests.
- New tests: 13/13 pass (7 bloc + 6 repository).
- Regression (pure-logic suites, no widget pumping): ledger bloc (36),
  ledger repository, setup bloc, setup repository, next_payout — 88 pass.
- View/widget suites deliberately not run: the UI builder has uncommitted
  edits in `payout_view.dart`/`payout_sheet.dart`; the integrator runs them
  after the merge. No simulator used at any point.

## LEFT FOR NEXT ITERATION

- UI builder: view-side `_submit` guard + busy CTA, `min(100, owed)` clamp
  + owed-guard, scrim `inset: 0`, `ExcludeSemantics`, ORCHESTRATOR_NOTES 1–3.
- Integrator/test stage: un-skip the `p13_bugs_test.dart` reproducers that
  now pass (BUG-01/02/04 expect `attempted == 1`, `moved ≤ paid` with
  `goal delta == moved`, and a second SnackBar — all satisfied by the
  layer fixes above plus the view fixes) and retire them per the
  `p12_bugs_test.dart` precedent.

VERDICT: PASS
