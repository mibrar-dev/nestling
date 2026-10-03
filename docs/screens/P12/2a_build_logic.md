# P12 · 2a BUILD (logic chunk, iteration 1)

## CONTRACT CHANGES

UI builder — the plan's §b contract holds, with two additive deviations
(nothing renamed or removed; every name from `1_plan.md` exists):

1. `MoneyLedgerData` carries one extra optional field, `setup:
   PocketMoneySetup?` (null only in hand-built fixtures; both repository
   implementations always provide it). Reason: one `PocketMoneyBloc` serves
   `/money` + `/pocket-money-setup` + `/payout` from a SINGLE
   `watchLedgerData` subscription, so the P06 setup (mode/coin/weekly base)
   must ride inside the ledger emission — the bloc no longer subscribes
   `watchSetup`/`watchItems` directly. Read `state.setup` exactly as before;
   read `state.data` / `state.selectedChildId` / `state.items` for P12.
2. New public top-level `ledgerDataFallback(setupStream, itemsStream)` in
   `domain/pocket_money_repository.dart` (same file as the interface).
   Reason: Dart `implements` does NOT inherit concrete interface bodies, so
   the six P06 test fakes each needed a one-line `watchLedgerData`
   override — they all delegate to this fallback (setup × items combine,
   no goals). Production code never calls it; the Drift implementation
   overrides with the full fan-in. Widget/view code should call
   `repository.watchLedgerData()`, never the fallback.

`PocketMoneyEntry.dateTz` defaults to `'Europe/London'` (old constructions
without it still compile — relied on by P06 fakes).

## Files changed (logic layer only)

- `app/lib/features/pocket_money/domain/entities/money_child.dart` (new):
  `MoneyChild(id, nickname)`.
- `app/lib/features/pocket_money/domain/entities/savings_goal_data.dart`
  (new): `SavingsGoalData` + `fraction` (`saved/target`, 0 on
  non-positive target; view clamps 0..1).
- `app/lib/features/pocket_money/domain/entities/money_ledger_data.dart`
  (new): `MoneyLedgerData(children, entries, oweds, goals, payoutDay,
  zoneId, setup?)` + `firstChildId` / `childById` / `entriesFor` /
  `owedFor` / `goalFor`.
- `app/lib/features/pocket_money/domain/entities/pocket_money_entry.dart`:
  added `dateTz` (default London, per plan).
- `app/lib/features/pocket_money/domain/next_payout.dart` (new):
  `nextPayoutDayUtc` + `payoutLabel` via `family_time` only (zone-midnight
  arithmetic, DST-safe); 1..7 asserted + release-checked.
- `app/lib/features/pocket_money/domain/pocket_money_repository.dart`:
  abstract `watchLedgerData()` + `ledgerDataFallback` (see above).
- `app/lib/features/pocket_money/data/pocket_money_repository_impl.dart`:
  `watchLedgerData()` override — roster `asyncExpand` switchMap, N-way
  `_combineLedgers` fan-in merged newest-first, goals, family
  (`payoutDay`/`timeZone`), setup mirror equal to `watchSetup()`; `_toEntity`
  now maps `dateTz`.
- `app/lib/features/pocket_money/data/models/pocket_money_entry_model.dart`:
  `dateTz` in `fromJson` (old JSON without the key falls back to London)
  + `toJson`.
- `app/lib/features/pocket_money/presentation/bloc/pocket_money_event.dart`:
  added `PocketMoneyChildSelected`, `PocketMoneyAddMoneySubmitted`,
  `PocketMoneySpendingSubmitted` (exact plan names/shapes).
- `app/lib/features/pocket_money/presentation/bloc/pocket_money_state.dart`:
  added `data`, `selectedChildId` (+ `clearSelectedChildId`, mirroring
  `clearErrorMessage`); all P06 members untouched.
- `app/lib/features/pocket_money/presentation/bloc/pocket_money_bloc.dart`:
  `PocketMoneyLoadRequested` → ONE `emit.forEach(watchLedgerData())`
  (setup taken from `data.setup`, P06 `_pendingDay`/`_requestedBase`
  bookkeeping preserved); `ChildSelected` sync re-filter (unknown id /
  pre-load no-op); submit handlers write through, stream re-emits, submit
  errors set `errorMessage` only (status stays loaded → view toasts).
- DI/routes (`pocket_money_di.dart`, `pocket_money_routes.dart`): NO change
  needed — `MoneyLedgerView` route already provides
  `GetIt.instance<PocketMoneyBloc>()..add(LoadRequested)`.
- Tests (new): `test/features/pocket_money/pocket_money_repository_test.dart`
  (24 tests: summarise 420/210, pre-payout exclusion, gift/spend/savings
  exclusion, order, newest-first, oweds, Lego 1550/2499, payoutDay 6,
  zone, re-emits, payout-settles, empty, helpers),
  `next_payout_test.dart` (7: Sat→Sat 3 Oct, Mon→Sat 10 Oct, Sun→Sat 10 Oct,
  Dubai zone, 0/8 rejected), `pocket_money_ledger_bloc_test.dart` (7: load
  defaults maya, Leo select, unknown no-op, gift +1, spend −200, submit
  failure stays loaded, stream error → failure).
- Test compat (one line each, fakes only — behaviour identical):
  `p06_bugs_test.dart`, `pocket_money_setup_bloc_test.dart` (×2 fakes),
  `pocket_money_setup_view_test.dart` (×3 fakes) gained a
  `watchLedgerData` override (fallback or `_inner` delegation).

NOT touched: `presentation/views/**`, `presentation/widgets/**`,
`app/lib/core/**`, `app/lib/app/**`, any other feature. No `google_fonts`
anywhere. No simulator used.

## Verification

- `dart format` clean; `flutter analyze lib/features/pocket_money
  test/features/pocket_money` → No issues found.
- New tests: repository 24/24, next_payout 7/7, ledger bloc 7/7 pass.
- P06 regression (same feature, shared bloc/interface): setup bloc +
  repository 45/45, p06_bugs 31/31, setup view + geometry + stepper
  108/108 pass. Full-app `flutter test` left to the integrator.

## LEFT FOR NEXT ITERATION

- Nothing in the logic layer is unfinished. UI builder owns
  `money_ledger_view.dart` + `money_edit_sheet.dart` (+ view tests) against
  the §a/§c contract above.

VERDICT: PASS
