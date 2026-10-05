# K10 · Payout day — 2 INTEGRATE (iteration 1)

Combined result of `2a_build_logic.md` (logic) + `2b_build_ui.md` (UI) made to
compile and pass. Scope: integration breakage only — no redesign, no contract
change, no shared file touched.

## Summary of the two halves

**2a (logic).** `PayoutCelebration` entity (`childId`, `nickname`, `paidPence`,
`movedPence?`, goal triple, pip look + `goalFraction` / `goalRemainingPence` /
`goalPercent`); `KidJarRepository.watchLatestPayout()`; bloc state gains
`payout` (+ `copyWithPayout`, sentinel-preserving `copyWith`, `copyWithLoaded`
preserves it, `props` extended); events `KidJarPayoutRequested` (view) +
`KidJarPayoutReceived` (internal); guarded `_payoutSub` in the bloc
(K09-BUG-1 cancel-before-reload shape, released on error and in `close()`);
`payoutDayRoute` dispatches `KidJarPayoutRequested` instead of
`KidJarLoadRequested`; repository impl builds the celebration from
`watchLedger` × `watchGoals` × `watchChild` (latest `payout` row wins,
companion = newest matching `savings_move` with `date >= payout.date`, first
goal, `'maya'` fallback). PERIODS ruling N/A (payout rows are event history).
Tests: `payout_celebration_test.dart`, extended `kid_jar_bloc_test.dart`.

**2b (UI).** `payout_day_view.dart` (KidScope → status bar → `.krow-top`
back/lock → scroll title + `PayoutJarRain` + 2× `PayoutNote` + `PayoutFundCard`
+ `_PayoutPip` → fixed `.kid-bar` with `Thanks Mum!`, plus loading / failure /
empty frames); `payout_jar_rain.dart` (SVG transcribed to a fixed-palette
CustomPainter), `payout_note.dart`, `payout_fund_card.dart`, `pip_look.dart`.
Tests: `payout_day_view_test.dart`, `payout_day_view_geometry_test.dart`, plus
the `watchLatestPayout` stub added to `my_jar_view_states_test.dart`.

The two halves met on the plan's contract with no drift: the UI builder coded
against `KidJarState.payout` / `copyWithPayout` /
`KidJarPayoutRequested` exactly as 2a shipped them. No BLoC state/event
renames were needed.

## FIXES items

| # | From | Item | Status |
|---|---|---|---|
| 1 | 2a fallout | `_CountingJarRepository` in `test/features/kid_jar/k09_bugs_test.dart:147` missing `watchLatestPayout` (the only `flutter analyze` error) | **DONE** — import of `payout_celebration.dart` + `Stream<PayoutCelebration?> watchLatestPayout() => const Stream<PayoutCelebration?>.empty();` stub, verbatim from 2a's note |
| 2 | 2b | `watchLatestPayout` stub in `my_jar_view_states_test.dart` | **already DONE** by 2b; verified by clean analyze |
| 3 | 2b deviation 1 | Note 2 is 88 px with the DB copy (`£5.50 went into your Lego Friends set` wraps) instead of the mock's 66 px, shifting fund top 591 → 613 | **LEFT AS-IS (not an integration fault)** — DATA OVER MOCKS: the numbers and strings are the seeded DB's, and the CSS card grows with content. The geometry test records the real bands. For `5_ui` this is the one band that will read +22 px against the PNG; the 2px rule is about app-vs-design *for the same content*, so this is flagged, not "fixed" by hard-coding mock copy |
| 4 | 2b deviation 2 | Same as #1 (logic builder owned `k09_bugs_test.dart` by name) | merged into #1 |

No other mismatch: imports resolve, no renamed members, no test was broken by
merging the halves. Nothing outside `app/lib/features/kid_jar/**` and
`app/test/features/kid_jar/**` was edited.

## Verification tails

`dart format .` → `Formatted 638 files (0 changed)`.

`flutter analyze` →

```
Analyzing app...
No issues found! (ran in 2.7s)
```

`flutter test --timeout 120s` →

```
02:09 +4424 ~12: All tests passed!
```

(4424 passed, 12 skipped, 0 failed — includes the whole `kid_jar` suite:
`payout_celebration_test`, `kid_jar_bloc_test`, `payout_day_view_test`,
`payout_day_view_geometry_test`, plus the K09 regressions
`kid_jar_repository_test`, `k09_bugs_test`, `my_jar_view_states_test`.)

No simulator was booted, installed on or driven at this stage.

VERDICT: PASS