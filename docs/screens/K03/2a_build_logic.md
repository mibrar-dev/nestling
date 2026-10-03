# K03 Kid home — Stage 2a logic chunk (iteration 6)

Scope: non-UI layer of `kid_home` only. No edits to
`presentation/views/**` or `presentation/widgets/**`.

## CONTRACT CHANGES (for the UI builder — please read)

Public BLoC contract is UNCHANGED: same events (`KidHomeLoadRequested`,
`KidHomeQuestCompleted`), same state fields. Views/widgets need no changes
for this stage. Two additive notes:

1. `KidHomeRepository` gains `Stream<KidHomeData> watchHome()` (new entity
   `domain/entities/kid_home_data.dart`: `{child, items}`). The bloc now
   loads from it. Fakes note: `implements KidHomeRepository` no longer
   compiles for the new member, so all 8 test fakes switched to
   `extends KidHomeRepository` (one word each, inherits the default
   combination) — including the `_FakeKidHomeRepository` in
   `kid_home_view_test.dart` (only change in that file; behaviour identical).
2. `switchMapStream` top-level helper lives in
   `domain/kid_home_repository.dart` (feature-internal; core untouched).

## Files changed

- `app/lib/features/kid_home/domain/entities/kid_home_data.dart` (new):
  `KidHomeData` Equatable value `{child, items}`.
- `app/lib/features/kid_home/domain/kid_home_repository.dart`: new
  `watchHome()` with a default combination + `switchMapStream` helper.
- `app/lib/features/kid_home/data/kid_home_repository_impl.dart`: extracted
  `_watchItemsFor(childId)`; `watchItems()` rebuilt on it; new `watchHome()`
  override (one `app_state` sub → one `watchChild` sub + quests/completions/
  zone). Period logic (`countsForCurrentPeriod`, alphabetical title order,
  `_detail` copy) untouched.
- `app/lib/features/kid_home/presentation/bloc/kid_home_bloc.dart`: load path
  uses `emit.forEach(_repository.watchHome())`; celebration/error logic
  untouched. DI/routes untouched (no new deps).
- `app/test/features/kid_home/kid_home_bloc_test.dart`: subscription counters
  on the fake; new test "a load watches the child row exactly once";
  new `watchHome` default-combination test; `load mirrors…` 4th emission
  updated to the atomic `(null, [])` (see below).
- `app/test/features/kid_home/k03_bugs_test.dart`: K03-BUG-12 un-skipped
  (+ header comment updated). One-word `extends` on its 6 fakes.
- `app/test/features/kid_home/kid_home_view_test.dart`: one-word `extends`
  (compile-only, see §1).
- `docs/screens/K03/SHARED_REQUEST.md`: #12 marked DONE on main.

## FIXES_5 items in my layer

- Finding 4 [minor] double child subscription — DONE via `watchHome()`.
  Real fix detail: the first attempt used `asyncExpand`, and new tests
  proved it stalls — `asyncExpand` pauses the outer subscription until the
  current inner stream *closes*, and watch streams never close, so child
  switches after the first emission never propagated (the old
  `watchItems()` had this latent stall too; the old `load mirrors`
  expectation `total: 6` after clearing the child was pinning it).
  `switchMapStream` cancels/replaces the inner per outer emission instead.
  Bonus: child switch now emits child+items atomically (old tear gone).
- Finding 2 [minor] CHILD ORDER — shared fix already on main
  (`watchChildren` orders by `createdAt`+`rowid`; seed staggers Maya/Leo).
  My part DONE: K03-BUG-12 un-skipped; verified passing against a real
  in-memory `Seed.demo` DB (`['Maya', 'Leo']`); #12 marked DONE.
- Findings 1 (pet-slot size), 3 (typography TODOs), 5 (motion flag),
  6 (dock wrap) — UI/shared layer, not mine. #11 already requests the
  pet-slot size API; nothing to add.

## Verification

- `dart format lib/features/kid_home test/features/kid_home` — clean.
- `flutter analyze` on domain/data/bloc + all three kid_home test files —
  No issues found.
- `flutter test test/features/kid_home/kid_home_bloc_test.dart` — 22/22 pass.
- Real-DB scratch (in-memory `Seed.demo`, deleted after): BUG-12 order
  passes; `watchHome()` override yields Maya + 6 items in title order with
  live statuses (dishwasher/table pending, bins/hoover approved = 4 done).
- No `google_fonts` in my files (grep clean). Letter-spacing: no text styles
  in my layer. Period/COPY rules untouched.

## LEFT FOR NEXT ITERATION

- Full `k03_bugs_test.dart` / `kid_home_view_test.dart` runs are blocked on
  the UI builder's in-progress google_fonts → bundled-fonts migration in
  `views/`+`widgets/` (pre-existing at HEAD: `kid_status_chip.dart:2`
  still imports it; the parallel UI builder already fixed the view import).
  Integrator re-runs them after that lands; no logic changes expected.
- `flutter test` for the whole app + simulator shots are the integrator's.

VERDICT: PASS
