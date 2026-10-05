# K10 · Payout day — 2a BUILD (logic chunk, iteration 1)

## CONTRACT CHANGES

None. Implemented exactly the event/state/repository names from `1_plan.md`
§b, so the UI builder codes against the plan unchanged:

- Events: `KidJarPayoutRequested` (view event), `KidJarPayoutReceived celebration`
  (internal), `KidJarStreamFailed` reused for payout-stream errors.
- State: `KidJarState.payout` (`PayoutCelebration?`, null = no payout yet) +
  `copyWithPayout(...)`; `copyWith`/`copyWithLoaded` extended, `props` extended.
- Repository: `KidJarRepository.watchLatestPayout() → Stream<PayoutCelebration?>`.
- Route: `payoutDayRoute` dispatches `KidJarPayoutRequested` INSTEAD of
  `KidJarLoadRequested` (per plan §b).
- Additive-only extras on the entity (not in the plan, UI builder MAY use):
  `goalFraction` (clamped 0…1), `goalRemainingPence` (floored at 0),
  `goalPercent` (rounded whole percent). Demo Maya reads 62 / 949 /
  ~0.6202; after the plan's `recordPayout(420, move 100)` reads 66 / 849.

## Files changed

- `app/lib/features/kid_jar/domain/entities/payout_celebration.dart` (NEW):
  `PayoutCelebration` entity per plan §b (childId, nickname, paidPence,
  movedPence?, goalTitle/Saved/Target, pipStyle/Skin/Accessory/Stage) +
  the three goal-math getters above.
- `app/lib/features/kid_jar/domain/kid_jar_repository.dart`: abstract
  `watchLatestPayout()`.
- `app/lib/features/kid_jar/data/kid_jar_repository_impl.dart`: `watchLatestPayout()`
  (`_switchMap(watchAppState → _payoutFor(childId))`, `'maya'` fallback) with
  `combineLatest3(watchLedger, watchGoals, watchChild)`; latest `payout` row
  wins (ties keep ledger order); companion = newest `savings_move` with
  `note.startsWith('Jar →')` and `date >= payout.date` (covers `recordPayout`'s
  same-instant pair and the seed's `Jar → Lego fund`); goal = child's first
  (zero-goal fallback); null child → null; PERIODS ruling is N/A (commented —
  payout rows are event history, not quest status).
- `app/lib/features/kid_jar/presentation/bloc/kid_jar_event.dart`:
  `KidJarPayoutRequested` + `KidJarPayoutReceived`.
- `app/lib/features/kid_jar/presentation/bloc/kid_jar_state.dart`: `payout`
  field; `copyWith` keeps it by default via a private `_keepPayout` sentinel
  (`copyWith(payout: null)` clears); `copyWithLoaded` preserves it;
  new `copyWithPayout(...)` (loaded + clears error, keeps K09 fields);
  `props` extended.
- `app/lib/features/kid_jar/presentation/bloc/kid_jar_bloc.dart`: `_payoutSub`
  with the K09-BUG-1 cancel-before-reload guard (independent from `_jarSub`;
  released on error and in `close()`); shared `KidJarStreamFailed` path
  preserves the last celebration on error (same as the jar path).
- `app/lib/features/kid_jar/kid_jar_routes.dart`: `payoutDayRoute` dispatches
  `KidJarPayoutRequested`. No DI change needed (same bloc, factory).
- `app/test/features/kid_jar/payout_celebration_test.dart` (NEW, plan §f.1):
  demo Maya (paid 380 / moved 550 / Lego 1550/2499 / mochi·sunny·none·3,
  62% + £9.49 to go); `recordPayout(420, move 100)` → paid 420 / moved 100 /
  saved 1650 / 66%; payout without move → `movedPence` null; child with no
  payout row → null; `Seed.empty` → null; active-child switch re-emits
  (Leo paid 190); live payout replacement; entity equality + overshoot clamp.
- `app/test/features/kid_jar/kid_jar_bloc_test.dart` (extended, plan §f.2):
  fakes implement `watchLatestPayout` (controllable payout streams +
  payout-subscription counting); payout emission → loaded; null → empty
  state; error → failure; retry recovers; live replacement keeps K09 fields;
  error-after-load keeps celebration; payout reload guard (single live sub,
  jar stream untouched); `close()` releases; internal-event paths; payout
  value semantics (`copyWithPayout`, sentinel `copyWith`, props).

## Items done (plan §b + §f.1/§f.2)

All logic-chunk items. Verified: `dart format` clean, `flutter analyze
lib/features/kid_jar + my two test files` → No issues found,
`flutter test --timeout 120s` on `payout_celebration_test`,
`kid_jar_bloc_test` AND the untouched `kid_jar_repository_test` (K09
regression) → all pass (74/74). Pinned clock used throughout (no
`DateTime.now()` in lib; `recordPayout` tests rely on the pinned
Sat 3 Oct 2026 09:41 London instant). No `google_fonts` anywhere.

## KNOWN FALLOUT FOR THE UI BUILDER / INTEGRATOR (not mine to fix here)

Adding the plan-mandated abstract `watchLatestPayout()` breaks compilation
of the two view-layer fakes that `implements KidJarRepository` (confirmed via
`flutter analyze`: `non_abstract_class_inherits_abstract_member` in both).
I did NOT touch those files (out of my layer + parallel-edit hazard). Each
needs this one stub added inside the fake class (import
`payout_celebration.dart` first):

```dart
@override
Stream<PayoutCelebration?> watchLatestPayout() =>
    const Stream<PayoutCelebration?>.empty();
```

- `app/test/features/kid_jar/k09_bugs_test.dart:147`
  (`_CountingJarRepository`)
- `app/test/features/kid_jar/my_jar_view_states_test.dart:74`
  (`_FakeKidJarRepository`)

The K10 view tests (plan §f.3/§f.4) belong to the UI builder.

## LEFT FOR NEXT ITERATION

Nothing in the logic layer. Not run (integrator's job): whole-app
`flutter test`, `shot.sh`/simulator UI check (only stage 5_ui may use a
simulator). No `SHARED_REQUEST` (plan §g: none).

VERDICT: PASS
