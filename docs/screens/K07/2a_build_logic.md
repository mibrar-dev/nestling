# CONTRACT CHANGES — read this before coding against the bloc

**None in iteration 4.** The public surface is byte-identical to what
iteration 3 shipped, so 2b's views and the tests that pin the contract are
untouched by this stage:

- `PipState`'s constructor, `props`, `evolution`, `items`, `nestSettled` /
  `evolutionSettled`, `nestError` / `evolutionError`, `errorMessage`,
  `nestStatus` / `evolutionStatus`, `copyWithLoaded`, `copyWithEvolution`,
  `withNestError`, `withEvolutionError`, `withActionStarted`,
  `withActionFailed`, `toLoading({restartingNest, restartingEvolution})` — all
  unchanged in shape and name.
- Every `PipEvent` is unchanged, including `PipLoadRequested` (still opens
  both streams — see "SHARED_REQUEST §2" below, still awaiting a ruling).
- `PipEvolution` unchanged: `profile`, `questsDone`, `questsFinished`,
  `questsFinishedCount`, `props`.
- `PipRepository` / `PipRepositoryImpl` unchanged (no lib edit at all this
  iteration — see "Files changed").

*(Iteration 3's own file recorded the same, plus the two additive/defaulted
`toLoading` parameters; both still stand and are visible in git history at
`ab49e0b^:docs/screens/K07/2a_build_logic.md`.)*

---

# K07 · Stage 2a — build, logic chunk (iteration 4)

Scope owned: `app/lib/features/pip/domain/**`, `data/**`,
`presentation/bloc/**`, `pip_di.dart`, `pip_routes.dart`, and the
`bloc` / `repository` / `data` tests in `app/test/features/pip/`. **No file
under `presentation/views/**` or `presentation/widgets/**` was touched** (2b
owns those), and no simulator was booted, installed on, driven or
screenshotted (RULES §1, loop brief).

## Files changed

| file | change |
|---|---|
| `test/features/pip/pip_evolution_repository_test.dart` | **+5 tests, +1 private helper** — the production status-UPDATE paths on the K07 numbers (below) |

No `lib/` file changed. The audit below is why: nothing in `1_plan.md` §(b)
was unimplemented, and neither of `FIXES_3.md`'s two items sits in this layer.

## Items done

### FIXES_3 audit — both items are 2b's, not this layer's

| finding | file the fix needs | whose |
|---|---|---|
| K07-BUG-6 (MAJOR) — the three `.k7-stats` cards are unequal height because the `Row` centres instead of stretching (needs `IntrinsicHeight` + `CrossAxisAlignment.stretch`) | `presentation/widgets/pip_evolution_stats.dart` | **2b** |
| K07-BUG-7 (minor) — the app-only `maxLines: 4` hero clamp and `maxLines: 2` sub clamp truncate the headline and the count | `presentation/views/pip_evolution_view.dart` | **2b** |

The two knock-on items FIXES_3 names are likewise not this layer's:
`pip_evolution_copy_test.dart:334` (pins `maxLines == 4`; the file matches
neither `bloc`/`cubit`/`repository`/`data`) and the two parked proofs in
`k07_bugs_test.dart` (both measure painted widget geometry). **So the
un-skipping of K07-BUG-6 / K07-BUG-7 and the moving of that one assertion
belong to 2b** — they land together with the two fixes in one commit, exactly
as FIXES_3 verified (`+206 -1` with both fixes applied). This stage left both
`skip: true` lines in place rather than half-opening a proof it cannot make
green, and did not touch either file (they were never this layer's).

### `1_plan.md` §(b) — complete, re-verified by reading, not by assumption

- `PipEvolution` (profile + `questsDone` + `questsFinished`), the two-number
  split from K07-BUG-3 and its `props` — present.
- `PipRepository.watchEvolution()`, `switchMap` over `watchAppState()` with
  `combineLatest2(watchProfile(id), watchCompletionsForChild(id))`, null on no
  active child / deleted row — present (`data/pip_repository_impl.dart:80`).
- The `done_pending | approved`, all-time count with **no clock read** — the
  PERIODS ruling correctly does not apply; `pip_evolution_data_test.dart`
  proves yesterday / last-week / last-month rows still count.
- `PipBloc`: two guarded subscriptions under the one `PipLoadRequested`, an
  error released only in its own slot, `close()` cancelling both, and the
  iteration-3 `toLoading(restartingNest:, restartingEvolution:)` retry
  semantics — present.
- `pip_routes.dart` (`/pip-evolution` → `BlocProvider(create: … PipLoadRequested())`
  → `PipEvolutionView`) and `pip_di.dart` (lazy `PipRepositoryImpl`, factory
  `PipBloc`) — present and correct; no `TODO(<ID>)` anywhere in the layer.

### New: the production status-UPDATE paths on the K07 numbers (coverage)

The suite pinned INSERTs but not the writes the product actually performs on
these rows:

- **K05** re-does a quest by flipping the newest `to_do` / `not_yet` row of
  the current period to `done_pending`
  (`kid_home_repository_impl.dart:171-182`);
- **P11** then flips *that row* to `approved` (approve) or to `not_yet`
  (decline) — `status = 'approved' WHERE status = 'done_pending'`
  (`approvals_repository_impl.dart:76-121`).

Five tests in `pip_evolution_repository_test.dart` now pin them, all against
`Seed.demo()` and all green:

| test | pins |
|---|---|
| a re-done quest (`to_do` → `done_pending`) counts +1 | 4 → **5 / 5**; exactly one row moved |
| approving it (`done_pending` → `approved`) never double-counts | a `done_pending` row is already counted, so P11's write moves nothing: **4 / 4** — a transition-counting screen would claim two helps for one completion |
| declining it (`done_pending` → `not_yet`) takes the credit back | **4 → 3 / 3** — the milestone is derived live, never accumulated, so a grown-up's decline cannot leave "Because you helped 4 times" standing |
| declining ONE of two rows for the same quest keeps it a quest done | re-completed `q-bins` = 5 times over 4 quests; declining the newest row gives **4 / 4** — the two numbers move independently and never contradict each other on screen |
| control: a status change between two uncounted values changes nothing | `to_do` → `not_yet` still re-emits (live, no caching) yet the new emission is `==` the first, which is what lets the bloc's Equatable state dedupe keep the celebration still |

The last row is also the answer to "does an unrelated table write flicker the
celebration screen?": `PipEvolution` is an `Equatable` value object and a
no-op status change leaves every field equal, so `BlocBuilder` does not
rebuild.

## Probed and measured clean (recorded so no later pass repeats it)

`_switchMap` (`data/pip_repository_impl.dart:259`) cancels the previous inner
subscription with `unawaited(innerSub?.cancel())`, so a write to the **old**
child's rows landing inside that window could in principle forward a stale
evolution after the active child switched. Three scratch probes against a
memory DB (`awaited switch then write to Maya`, `switch and old-child write
in the same turn`, `rapid maya → leo → maya`) produced **no** stale emission
— Drift's cancel settles before the next write's hook is delivered — and the
maya → leo → maya round trip emitted `leo, maya` in order. Probe file deleted;
**no code change made**, because there is no failing proof to justify touching
a helper K06's `watchNest()` / `watchItems()` also use.

## Deliberately not actioned

- **SHARED_REQUEST §2 (screen-scoped load)** — still no orchestrator ruling;
  `docs/ARCHITECTURE.md:85` mandates one `<Feature>LoadRequested` per feature,
  so `PipLoadRequested` still opens both streams. Unchanged on purpose.
- **SHARED_REQUEST §1 / §3 / §4 / §5** — notes for the orchestrator
  (no-entry-point, `shot.sh` pre-first-frame save, the off-token `#3D7FF0` sky
  dot, and the `evolutionSub(0)` zero-branch wording). No code.
- **`watchItems()`'s `?? 'maya'` fallback** (`:34`) — a hard-coded child id in
  the data layer. It is unreachable from any view today (the wardrobe strip
  renders only when `watchNest()` resolved a real active child, and that path
  never invents an id), it is K06's behaviour, and ids in production are uuid
  `newId('child')`. Flagged, not changed: touching it would move K06's screen
  for no K07 gain.
- No simulator, no `flutter clean`, no `analysis_options` change, no skipped
  test, no `google_fonts`, no `DateTime.now()`, no `pkill`.

## Gates (this layer only, every run with `--timeout`)

```
$ dart format lib/features/pip test/features/pip/pip_evolution_repository_test.dart
    Formatted 26 files (1 changed)   ← the new tests only; `dart format`
                                       reformats in place, and analyze below
                                       re-reads the formatted file

$ flutter analyze lib/features/pip test/features/pip/pip_evolution_repository_test.dart
    No issues found!

$ flutter test --timeout 120s test/features/pip/pip_evolution_repository_test.dart
    → +14: All tests passed!   (9 existing + 5 new, no skips)

$ flutter test --timeout 120s test/features/pip/pip_evolution_repository_test.dart \
      test/features/pip/pip_evolution_data_test.dart \
      test/features/pip/pip_evolution_bloc_test.dart \
      test/features/pip/pip_repository_test.dart \
      test/features/pip/pip_bloc_test.dart test/features/pip/pip_bloc_actions_test.dart \
      test/features/pip/pip_atomic_writes_test.dart
    → +129: All tests passed!
```

The whole-app `flutter test` and the simulator are the integrator's (loop
brief); the K07 UI suites (`pip_evolution_view` / `a11y` / `widget` / `copy` /
`sparks` / `stream_contract`, `k07_bugs`, `k07_sparkles_bug`,
`pip_orchestrator_notes`, `pip_iter2_fixes`, `pip_buy_result`, the K06 nests)
were neither edited nor run by this stage — they are 2b's and the UI check's.

## LEFT FOR NEXT ITERATION

- Nothing outstanding **in this layer**: `watchEvolution`, `PipEvolution`, the
  dual-stream `PipLoadRequested` state machine, its retry semantics and the DI
  / route wiring are implemented, audited and proven.
- Still owed by others: 2b's K07-BUG-6 (`pip_evolution_stats.dart`) and
  K07-BUG-7 (`pip_evolution_view.dart`) plus the un-skip of their two parked
  proofs in `k07_bugs_test.dart` and the one moved assertion in
  `pip_evolution_copy_test.dart`; the orchestrator's ruling on SHARED_REQUEST
  §2 (and notes §1, §3, §4, §5).

VERDICT: PASS