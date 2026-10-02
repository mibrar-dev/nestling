# P06 Pocket money setup — logic build (Stage 2a, iteration 2)

## CONTRACT CHANGES

None. Public names are exactly per `1_plan.md` §2 and unchanged for the UI
builder: `PocketMoneySetup` / `PocketMoneySetupChild.childById`,
`PocketMoneyRepository.watchSetup/setMode/setPayoutDay/setWeeklyBasePence`,
`PocketMoneyState.setup`, events `PocketMoneyModeChanged(mode)`,
`PocketMoneyPayoutDayChanged(day)`,
`PocketMoneyWeeklyBaseStepped(childId, deltaPence)`. Step stays 50p; the
repository clamps base to 0..2000.

## Files changed (logic layer only)

None — verified, no edits needed. Existing implementation already matches
`1_plan.md` §2 and the FIXES_1 logic items:

- `app/lib/features/pocket_money/domain/entities/pocket_money_setup.dart`
- `app/lib/features/pocket_money/domain/pocket_money_repository.dart`
- `app/lib/features/pocket_money/data/pocket_money_repository_impl.dart`
- `app/lib/features/pocket_money/presentation/bloc/pocket_money_bloc.dart`
- `app/lib/features/pocket_money/presentation/bloc/pocket_money_event.dart`
- `app/lib/features/pocket_money/presentation/bloc/pocket_money_state.dart`
- DI/routes (`pocket_money_di.dart`, `pocket_money_routes.dart`, barrel)
  unchanged and correct; no new registration needed.
- No views/widgets touched (UI builder owns those).
- No test files touched (bloc + repository tests already cover the contract).

## Items done (FIXES_1, logic-layer only)

- `watchSetup` combines `families` row (truth) + `settings` mirror +
  children ordered by SQLite `rowid` (Maya, then Leo — never
  `AppDatabase.watchChildren`/nickname order). Verified by repository test
  "insertion order, not alphabetical".
- Setters write `families` AND `settings` (+ `updatedAt` UTC) in one
  transaction; `setMode` asserts `weekly|per_quest|both`, `setPayoutDay`
  asserts 1..7, `setWeeklyBasePence` clamps 0..2000. Verified by
  mirror-write + clamp + assert tests.
- Bloc uses ONE `emit.forEach` over
  `combineLatest2(watchItems, watchSetup)` with `_closeOnError`
  (error-then-close, TodayBloc pattern) so a failed load terminates and
  Retry resubscribes cleanly; day re-tap guarded (`if day == current
  return`); step reads current base from `state.setup`. Verified by bloc
  tests (mode/day/step re-emit, no-op re-tap, clamp at 0 and 2000).
- No skipped bug tests for P06: no `*bug*` files, no `skip:` in
  `app/test/features/pocket_money/`. Nothing to un-skip.
- No `google_fonts`/`GoogleFonts.*` in the logic layer or its tests
  (`bloc`, `repository` files clean).

## Checks run (stage-allowed only)

- `flutter analyze lib/features/pocket_money
  test/features/pocket_money/pocket_money_setup_bloc_test.dart
  test/features/pocket_money/pocket_money_setup_repository_test.dart` →
  `No issues found!`
- `flutter test
  test/features/pocket_money/pocket_money_setup_repository_test.dart
  test/features/pocket_money/pocket_money_setup_bloc_test.dart` →
  `All tests passed!` (20/20: repo 9, bloc 11).
- Full-app `flutter test` and simulator NOT run (integrator owns them).

## Note for UI builder / integrator (not my layer, not edited)

- `app/test/features/pocket_money/pocket_money_setup_view_test.dart` still
  imports `package:google_fonts/google_fonts.dart` and calls
  `GoogleFonts.config.allowRuntimeFetching = false`. The orchestrator FONTS
  rule forbids this; that file is owned by the UI builder (its name has no
  `bloc`/`cubit`/`repository`/`data`), so I left it untouched — UI builder
  should delete those lines (use `setUpTestScope`, bundled Inter/Nunito).

## LEFT FOR NEXT ITERATION

Nothing in the logic layer. All `1_plan.md` §2 + FIXES_1 logic items are
implemented and green.

VERDICT: PASS
