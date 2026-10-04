# CONTRACT CHANGES — read this before coding against the bloc

Two changes to `PipState` / `PipEvolution` (both additive, nothing removed that
a view reads). **Views were not edited by this stage** — they are 2b's.

## 1. Each load stream is now tracked (and reported) on its own

`PipState` (`app/lib/features/pip/presentation/bloc/pip_state.dart`) gained:

| member | meaning |
|---|---|
| `bool nestSettled` | `watchNest()` has answered at least once (a null nest counts — no child is a *healthy* emission) |
| `bool evolutionSettled` | `watchEvolution()` has answered at least once |
| `String? nestError` / `String? evolutionError` | that stream's failure, diagnostic only |
| `PipStatus get nestStatus` | **what `/pip` must switch on** |
| `PipStatus get evolutionStatus` | **what `/pip-evolution` must switch on** |

`withStreamError(Object)` and `toFailure(Object)` are **gone**, replaced by
`withNestError(Object)` / `withEvolutionError(Object)`. `status`,
`nest`, `evolution`, `errorMessage`, `actionError`, `actionNonce` and all the
care/wardrobe events are unchanged; `PipLoadRequested`, `PipNestReceived`,
`PipNestFailed`, `PipEvolutionReceived`, `PipEvolutionFailed`, `PipCareRequested`,
`PipWardrobeBuyRequested`, `PipWardrobeEquipRequested` keep their shapes.

**What 2b must do in the two views**

- `pip_evolution_view.dart`: `switch (state.status)` → `switch (state.evolutionStatus)`
  (the `failure` branch still reads `state.evolution?.profile ?? state.nest?.profile`
  for the last-known Pip — both fields survive). Then **delete lines 94-95**
  (`final nest = state.nest; if (nest != null) return _EvolutionFailure(...)`):
  with per-stream arrival, `evolutionStatus == loaded` + `evolution == null`
  means "no active child" and nothing else, so the sibling stream must not be
  consulted. `pip_nest_view.dart:89` (`if (state.evolution != null) return const
  _PipFailure();`) is the mirror and goes the same way with `state.nestStatus`.
- Nothing else in either view needs changing: while the evolution stream is
  pending, `evolutionStatus` is `loading` and the spinner is right; a nest
  failure can no longer reach the K07 failure card at all.
- **Not fixed by the UI builder → 3 pre-existing tests in
  `app/test/features/pip/pip_nest_states_test.dart` will fail until the fixture
  is adjusted** (they drive the NEST stream with K07's stream deliberately
  silent, so the aggregate `status` stays `loading` forever):
  `loading the first nest emission replaces the spinner`,
  `load failure Try again really reloads the nest`,
  `load failure the accessibility path reloads the nest too`.
  One-line fix in `_NestOnlyRepository` (same file, lines 58-69):
  ```dart
  @override
  Stream<PipEvolution?> watchEvolution() =>
      Stream<PipEvolution?>.value(null); // healthy no-child emission
  ```
  (and drop `closeEvolutionGate()` / the `_silentEvolution` controller, which
  then has no user). Every other test in the directory is green.

## 2. `PipEvolution` reports rows AND distinct quests (K07-BUG-3)

```dart
final int   questsDone;         // completion ROWS  -> "Because you helped N times"
final int?  questsFinished;     // DISTINCT quests -> the "quests done" card
int get questsFinishedCount;    // the card's number (falls back to questsDone)
```

**What 2b must do in the UI**: the "quests done" stat card
(`pip_evolution_stats.dart` / `Key('k07-stat-quests')`) must render
`evolution.questsFinishedCount`, while the sub-line keeps
`evolution.questsDone`. Demo data is unchanged (4 rows over 4 quests), so the
design's `4 / quests done` still renders `4`; only a re-completable quest now
reads honestly. This is what un-skips the widget proof of K07-BUG-3.

`const new({required profile, required questsDone, this.questsFinished})` — the
third parameter is optional, so every existing fixture that writes only
`questsDone` still compiles.

---

# K07 · Stage 2a — build, logic chunk (iteration 2)

Scope owned: `app/lib/features/pip/domain/**`, `data/**`,
`presentation/bloc/**`, the feature's DI/route files, and the `bloc` /
`repository` / `data` tests in `app/test/features/pip/`. No file under
`presentation/views/**` or `presentation/widgets/**` was touched (2b owns those),
and no simulator was booted, installed on or driven (RULES §1, loop brief).

## Files changed

| file | change |
|---|---|
| `lib/features/pip/presentation/bloc/pip_state.dart` | per-stream arrival flags + error slots, `nestStatus` / `evolutionStatus` getters, aggregate `status` = AND of both streams |
| `lib/features/pip/presentation/bloc/pip_bloc.dart` | `_onNestFailed` / `_onEvolutionFailed` now write their own stream's slot |
| `lib/features/pip/domain/entities/pip_evolution.dart` | `questsFinished` + `questsFinishedCount` |
| `lib/features/pip/data/pip_repository_impl.dart` | `watchEvolution` reports rows **and** distinct quests |
| `test/features/pip/pip_evolution_bloc_test.dart` | per-stream coverage; the parked **K07-BUG-1** proof un-skipped and green; `cascade_invocations` analyze fix (finding 3) |
| `test/features/pip/pip_bloc_test.dart` | K06 assertions read `nestStatus` (silent-sibling fixture) |
| `test/features/pip/pip_bloc_actions_test.dart` | no-child card test reads `nestStatus`; "no reload event" counts armed loads via the flags |
| `test/features/pip/pip_buy_result_test.dart` | state-copy fixture carries the arrival flags |
| `test/features/pip/pip_evolution_repository_test.dart` | new distinct-vs-rows repository proof |
| `test/features/pip/k07_bugs_test.dart` | un-skipped the two state-level proofs (K07-BUG-1 real repo, K07-BUG-3 repository) |

## Items done (from `docs/screens/K07/FIXES_1.md`)

- **`4_review.md` finding 2 / `6_bugs.md` K07-BUG-1 (MAJOR) — fixed in this
  layer.** Each stream now has an arrival flag and an error slot, and `status`
  is `loaded` only when *both* streams have answered. `pip_evolution_bloc_test.dart`
  → `K07-BUG-1: a NEST emission alone must not report loaded…` is **un-skipped
  and passing** (`loaded` is published exactly once, after the evolution
  answered), and so is `k07_bugs_test.dart` → `K07-BUG-1 (real repository, no
  fakes)` over 5 cold opens against `PipRepositoryImpl` — the window that
  produced "Oh no! Pip got lost." on 5/5 opens no longer exists in the state.
  The widget half of the proof stays parked for 2b (it needs the view to switch
  on `evolutionStatus`; see CONTRACT CHANGES §1).
- **`4_review.md` finding 10 (MINOR) — folded in.** `errorMessage` stays the
  aggregate diagnostic (never read by a view), but it is now written by
  per-stream handlers instead of two ambiguous ones, and
  `pip_evolution_bloc_test.dart` pins both slots.
- **`6_bugs.md` K07-BUG-3 (MINOR) — fixed in this layer (data half).**
  `watchEvolution` now counts distinct `questId`s for the milestone card while
  the row count still backs "Because you helped N times", so the two sentences
  can no longer contradict each other. New passing proof in
  `pip_evolution_repository_test.dart` + `k07_bugs_test.dart` → `K07-BUG-3
  (repository, no widget tree)` **un-skipped and green**. The widget half is 2b's
  (CONTRACT CHANGES §2).
- **`4_review.md` finding 3 (MAJOR, gates) — fixed.** The
  `cascade_invocations` info in `pip_evolution_bloc_test.dart` is gone
  (`bloc..add(...)`), and every file this stage touched is `dart format` clean.
  `flutter analyze lib/features/pip` and `flutter analyze test/features/pip` are
  both **No issues found!**

## Deliberately not actioned

- **`4_review.md` finding 4 (MINOR) — still accepted-as-is.** `PipLoadRequested`
  opens both streams, so `/pip-evolution` watches K06's tables for nothing.
  `SHARED_REQUEST.md` §2 asks the orchestrator for a ruling (a scope field on the
  existing event, or a second event); `ORCHESTRATOR_NOTES.md` has none, so the
  event is untouched — changing it now would also change the K07 route wiring 2b
  codes against.
- **`4_review.md` findings 5-9, 11, 12 and `6_bugs.md` K07-BUG-2 / K07-BUG-4**
  are all in `presentation/views/**` or `presentation/widgets/**` (2b's).
- `dart format` on `k07_sparkles_bug_test.dart` (finding 3's second half) was
  left to 2b: that file is theirs and they are writing to it right now.

## Gates (this layer only, every run with `--timeout`)

```
$ flutter analyze lib/features/pip          → No issues found!
$ flutter analyze test/features/pip/        → No issues found!
$ dart format --output=none --set-exit-if-changed lib/features/pip \
      test/features/pip/{pip_evolution_bloc_test,pip_bloc_test,
      pip_bloc_actions_test,pip_buy_result_test,pip_evolution_repository_test,
      k07_bugs_test}.dart                    → (no change)

$ flutter test --timeout 120s test/features/pip/pip_evolution_bloc_test.dart
    → +26: All tests passed!   (the K07-BUG-1 proof included, no skips)
$ flutter test --timeout 120s test/features/pip/pip_bloc_test.dart
                                      pip_bloc_actions_test.dart
                                      pip_buy_result_test.dart
    → +78: All tests passed!
$ flutter test --timeout 120s test/features/pip/pip_evolution_repository_test.dart
      pip_repository_test.dart pip_evolution_data_test.dart
      pip_atomic_writes_test.dart
    → +52: All tests passed!
$ flutter test --timeout 120s test/features/pip/k07_bugs_test.dart
    → +19 ~4: All tests passed!   (2 proofs un-skipped; 4 widget/UI proofs parked)
$ flutter test --timeout 60s test/features/pip/pip_evolution_view_test.dart
    → +21: All tests passed!   (K07 view unaffected by the state change)
$ flutter test --timeout 60s test/features/pip/pip_nest_view_test.dart
      pip_nest_interactions_test.dart k06_bugs_test.dart
      pip_evolution_a11y_test.dart pip_orchestrator_notes_test.dart
    → +104: All tests passed!
$ flutter test --timeout 60s test/features/pip/pip_nest_states_test.dart
    → +17 -3:  the 3 fixture cases listed in CONTRACT CHANGES §1 (2b's file)
```

Note on one run: a 9-file combined invocation reported
`loading …/k07_bugs_test.dart` and `loading …/pip_evolution_data_test.dart` as
errors. Both are compile failures in
`lib/features/pip/presentation/widgets/pip_evolution_sparks.dart` **while 2b was
mid-edit on it** in this shared worktree (their in-flight `_sparkPath` /
`_sparkPaths` cache). Every file of this layer passes on its own; re-run the
directory after 2b lands.

## LEFT FOR NEXT ITERATION

- Nothing in this layer. The only outstanding work for it is 2b's view wiring
  (CONTRACT CHANGES §1) and its one-line fixture change in
  `pip_nest_states_test.dart`; the repository/state/entity work K07-BUG-1 and
  K07-BUG-3 needed is complete and proven.

VERDICT: PASS
