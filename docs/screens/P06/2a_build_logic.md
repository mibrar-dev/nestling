# P06 Pocket money setup — logic build (Stage 2a, iteration 4)

## CONTRACT CHANGES

No event/state shape changes — the UI builder's contract is untouched
(`PocketMoneyModeChanged(mode)`, `PocketMoneyPayoutDayChanged(day)`,
`PocketMoneyWeeklyBaseStepped(childId, deltaPence)`, `PocketMoneyState.setup`;
step 50p; clamp 0..2000). No repository interface changes (all three feature
fakes still compile untouched). Only private bloc behavior refined (see below).

## Files changed (logic layer only — no views/widgets touched)

- `app/lib/features/pocket_money/presentation/bloc/pocket_money_bloc.dart`
  - Load `onData` now drops the unconfirmed day request (`_pendingDay`) only
    once the stream *confirms* it (`setup.payoutDay == _pendingDay`), instead
    of on every emission. An unrelated re-emission still reporting the old
    day no longer swallows a correction tap (P06-BUG-09). Step-request
    reconciliation and `clearErrorMessage` behavior unchanged.
- `app/test/features/pocket_money/pocket_money_setup_repository_test.dart` —
  added `Seed.onboardingKids emits the same setup as demo (P06 shoot seed)`.
- `app/test/features/pocket_money/p06_bugs_test.dart` — un-skipped P06-BUG-09
  (now passes); header note refreshed. No fake changes needed.

## Items done (FIXES_3 → ORCHESTRATOR_NOTES "UPDATE (04:05", logic-layer only)

- Item 1 (SEED `onboarding_kids`): verified read-only in
  `app/lib/core/data/seed.dart` — `onboardingKids` reuses `_family` (both/6/1)
  and `_childrenDemo` (Maya £3.00 lilac, Leo £1.50 peach, insertion order), so
  `watchSetup` emits exactly the design values with zero code changes and no
  hard-coded view defaults. Pinned by the new repository test above. No
  SHARED_REQUEST needed (seed already carries the amounts).
- Items 2/4/5/6 (chip overflow, coin glyph, card height, `NestChipWrap`): view
  files — UI chunk owns them; not touched.
- Item 3 (letter-spacing 0): shared fix on main; nothing to do in
  domain/data/bloc (no text styles there). Not touched.
- Skipped bug tests in my layer: P06-BUG-09 was the only skipped logic-layer
  proof — now un-skipped and green. The one remaining skip in
  `p06_bugs_test.dart` is the view-layer day-cell alignment probe (UI chunk).
  P06-BUG-03 likewise remains a shared/view matter.

## Checks run (stage-allowed only)

- `dart format` on touched files → clean (0 changed).
- `flutter analyze` on domain + data + bloc + the three test files →
  `No issues found!` (the one remaining `info` in the feature dir lives in
  the UI chunk's `pocket_money_setup_view.dart`).
- `flutter test pocket_money_setup_bloc_test +
  pocket_money_setup_repository_test` → `All tests passed!` (44/44).
- `flutter test p06_bugs_test` → `All tests passed!` (+18 ~1; the single
  skip is the view-layer alignment probe).
- Full-app `flutter test` and simulator NOT run (integrator owns them).

## LEFT FOR NEXT ITERATION

Nothing in the logic layer. Open items sit with the UI chunk / orchestrator:
BUG-03 (day-pill paint size, needs the shared `NestChip` compact mode),
the day-cell alignment probe skip, and the view-file `info` lint.

VERDICT: PASS
