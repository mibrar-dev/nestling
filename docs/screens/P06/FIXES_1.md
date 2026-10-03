# Fix list after iteration 1

## From 2_build.md
# P06 Pocket money setup — build report (Stage 2, iteration 1)

Route: `/pocket-money-setup` · feature `pocket_money` · parent mode · onboarding (P05 → P06 → P07).
Plan: `docs/screens/P06/1_plan.md`. No `ORCHESTRATOR_NOTES.md` exists. No Pip on this screen.

## Files changed (all inside the feature sandbox, RULES §1)

- `app/lib/features/pocket_money/domain/entities/pocket_money_setup.dart` (new) — `PocketMoneySetup` (`mode` `weekly|per_quest|both`, `payoutDay` 1..7, `coinValuePencePerCoin`, insertion-ordered `children`) + `PocketMoneySetupChild`, Equatable, `childById`.
- `app/lib/features/pocket_money/domain/pocket_money_repository.dart` — added `watchSetup`, `setMode` (assert 3 values), `setPayoutDay` (assert 1..7), `setWeeklyBasePence` (clamp 0..2000).
- `app/lib/features/pocket_money/data/pocket_money_repository_impl.dart` — `watchSetup` via `combineLatest3` (families row = truth, settings mirror, children by `customSelect … ORDER BY rowid` with `readsFrom` so the stream re-emits; `AppDatabase.watchChildren` orders by nickname = Leo-first, so it is deliberately not used). Setters write `families` AND `settings` (+ `updatedAt` UTC) in one transaction.
- `app/lib/features/pocket_money/presentation/bloc/pocket_money_event.dart` — `PocketMoneyModeChanged`, `PocketMoneyPayoutDayChanged`, `PocketMoneyWeeklyBaseStepped(childId, deltaPence)`.
- `app/lib/features/pocket_money/presentation/bloc/pocket_money_state.dart` — added `setup` (null until first emit), kept `items` (same bloc serves `/money` + `/payout`).
- `app/lib/features/pocket_money/presentation/bloc/pocket_money_bloc.dart` — ONE `emit.forEach` over `combineLatest2(watchItems, watchSetup)`; write-through handlers (no save event; day re-tap guarded; step reads current base from `state.setup`; step = 50p; write errors → `failure`).
- `app/lib/features/pocket_money/presentation/views/pocket_money_setup_view.dart` (rewrote placeholder) — `NestStatusBar`, compact `NestNavBar` (back → `go(/add-children)`), scroll (H1 header, radiogroup `Pocket money style`, `NestCard` settings with full-bleed dividers: `Payout day` 7× `Expanded` 44-tall day cells, `Weekly base` rows in Maya-then-Leo order, `Coin value` row), dense `NestBottomCta` with caption-above-`Continue` composed in `child` (surface runs to the edge), `NestHomeIndicator`. Continue → `go(/paywall)`, no validation gate. Copy is the HTML verbatim (ASCII + `£` only). Day cells use static `NestChip` inside `FittedBox(scaleDown)` in a 44-tall tap box (the 14px chip + 28px padding cannot fit 7-across at full size) — follow-up SHARED_REQUEST candidate per 1_plan §7.
- `app/test/features/pocket_money/pocket_money_setup_bloc_test.dart` (new, 11 tests), `pocket_money_setup_repository_test.dart` (new, 9 tests), `pocket_money_setup_view_test.dart` (new, ~24 tests: copy light/dark, 2×3×2 width/scale matrix, write-through taps, nav, empty/failure/loading, semantics, 44dp targets, `disposeApp` after every app pump).

## Analyze / format tails

- `dart format` applied to `lib/features/pocket_money` + `test/features/pocket_money`.
- `flutter analyze test/features/pocket_money lib/features/pocket_money` → `No issues found!` (fixed during build: `Family` not `FamiliesData`, explicit `TableInfo<Table, dynamic>` type args, `on Object catch`, doc-comment reference, redundant `size: 24`, unused/unnecessary imports).
- Full-`app/` analyze and full `flutter test` were NOT completed this iteration (see verdict).

## Test tails

- `flutter test test/features/pocket_money/pocket_money_setup_repository_test.dart` → `All tests passed!` (9/9, EXIT 0).
- `flutter test test/features/pocket_money/pocket_money_setup_bloc_test.dart` → `All tests passed!` (11/11, EXIT 0).
- `flutter test test/features/pocket_money/pocket_money_setup_view_test.dart` → `Some tests failed` (+16 −8): copy light/dark at 390 pass, but 320dp + text-scale-1.3 overflows the weekly-base rows (`A RenderFlex overflowed by 26 pixels on the right`, `Row-<'p06_base_row_maya|leo'>`, 248px content width — the fixed `NestStepper` 44+12+64+12+44 block leaves no room for avatar + name + value at that width/scale), plus failures in the selection-flip, day-tap, stepper, selected-flags and Retry tests whose exceptions were not yet triaged. The run then hung ~10 min at teardown (`loading … [E]` + `flutter_tools` listener-cleanup crash), so the failure list may be incomplete.
- Root cause hypothesis for the overflow: at 320dp the base row is avatar 32 + gap 12 + name + stepper ~176px inside 248px; at scale 1.3 the name/value text forces the stepper past the edge. Fix for iteration 2: shrink-wrap the row (e.g. ellipsis the name harder, let the stepper value compress, or move to a wrap layout) and re-run the full matrix; also triage the interaction-test failures and the teardown hang (suspect pending Drift timer in the direct-pump tests).

## Scope compliance

Nothing outside `app/lib/features/pocket_money/**` + `app/test/features/pocket_money/**` touched. No shared-component edits. `SHARED_REQUEST.md`: not filed (the day-chip `labelStyle` follow-up from 1_plan §7 is parked until the overflow + interaction failures are fixed).


## From 3_test.md
(stage did not run in iteration 1 — run it fully next iteration)

## From 4_review.md
(stage did not run in iteration 1 — run it fully next iteration)

## From 5_ui.md
(stage did not run in iteration 1 — run it fully next iteration)

## From 6_bugs.md
(stage did not run in iteration 1 — run it fully next iteration)
