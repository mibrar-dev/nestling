# K11 · Badges — stage 2a build, logic chunk (iteration 1)

Scope: non-UI layer of feature `badges` only
(`domain/**`, `data/**`, `presentation/bloc/**` + feature unit/bloc tests).
No edits to `presentation/views/**` or `presentation/widgets/**`.
Plan source: `docs/screens/K11/1_plan.md` §b + §f.

No CONTRACT CHANGES — public names match the plan exactly
(`BadgesData`, `watchActiveBadges`, `BadgesLoadRequested`,
`BadgesDataReceived(BadgesData)`, `BadgesStreamFailed(Object)`,
`BadgesState(status, childId, items, happyDays)` +
`copyWithLoaded(childId, items, happyDays)`). The UI builder can code
against the plan as written.

## Files changed

- `app/lib/features/badges/domain/entities/badges_data.dart` (NEW):
  `BadgesData(childId, items, happyDays)` (Equatable).
- `app/lib/features/badges/domain/badges_repository.dart`:
  added `Stream<BadgesData> watchActiveBadges()` + doc contract
  (insertion order, design detail copy).
- `app/lib/features/badges/data/badges_repository_impl.dart`:
  `watchShelf` earned detail `'Earned'` → `'Got it!'` (design copy;
  view must not remap — single source here); added `watchActiveBadges()`
  (`watchAppState` → `activeChildId ?? 'maya'` → per-child
  `combineLatest2(watchShelf, watchHappyDays)`); added feature-local
  `_switchMap` (copy of the `kid_shop` helper). `watchItems()` untouched
  (back-compat). DB insertion order, no sorting. No clock, no `newId`.
- `app/lib/features/badges/presentation/bloc/badges_event.dart`:
  added internal `BadgesDataReceived` / `BadgesStreamFailed`
  (route still sends only `BadgesLoadRequested`).
- `app/lib/features/badges/presentation/bloc/badges_state.dart`:
  added `childId` (`''` until first emission), `happyDays` (0..7),
  `copyWithLoaded` (clears stale errors), `isLoaded`.
- `app/lib/features/badges/presentation/bloc/badges_bloc.dart`:
  K08 `KidShopBloc` guard pattern literally — single `_sub`, reloads
  ignored while live, sub released on error/close so `Try again` works.
  Never re-adds load events.
- `app/test/features/badges/badges_repository_test.dart` (NEW, 12 tests):
  Maya 8 rows / 4 earned (`first-quest, bed-maker-7, kind-helper,
  bookworm`, detail `Got it!`, rest `Keep going!`); Leo 1 earned;
  `watchHappyDays` maya 4 / leo 3 / unknown 0; `watchActiveBadges`
  follows `app_state` switches; live re-emission (child switch, earn,
  happy-days write, no stale emission to switched-away child);
  `Seed.empty` → empty shelf + 0 days.
- `app/test/features/badges/badges_bloc_test.dart` (NEW, 14 tests):
  load → loaded(4 earned, happyDays 4); no stacking on double load;
  error → failure + retry reloads; live child swap; post-load error keeps
  text; `close()` releases the sub; full `BadgesState` value semantics.
- DI / routes: NO change needed — `badges_di.dart` already registers the
  repository + bloc, `badges_routes.dart` already adds
  `BadgesLoadRequested` at the route level.

Implementation note (not a contract change): the plan text says
"`asyncExpand` into `combineLatest2`", but the same paragraph requires
the K08 guard pattern literally, and K08's `_switchMap` comment proves
`asyncExpand` stalls forever on never-closing Drift watch streams (the
live child-switch tests fail under it). Implemented the feature-local
`_switchMap` copy instead — same public stream shape.

## Items done (plan §b + §f)

- [x] `BadgesData` entity
- [x] `watchActiveBadges` on interface + impl
- [x] `watchShelf` design detail copy (`Got it!` / `Keep going!`)
- [x] Bloc guard pattern + `copyWithLoaded` state
- [x] Repository + bloc tests per §f (26/26 pass, `--timeout 120s`)
- [x] `flutter analyze lib/features/badges test/features/badges` → clean
- [x] Shared `test/core/data/repositories_test.dart` still passes (22/22)
- [x] No `DateTime.now`, no `google_fonts`, no simulator, no shared edits

## LEFT FOR NEXT ITERATION

- Nothing in the logic layer. Plan §g `SHARED_REQUEST.md` (seed nine
  design badges) is a docs/integrator item — the grid renders whatever
  the DB returns in DB order, correct for Maya's 4 earned either way;
  the view layer adds the `TODO(K11)` for the exact nine.

## Re-verification (loop re-run, post-merge `9feace7`)

- No logic-layer edits needed: `git log` shows the `main` merge touched
  only `kid_jar` + K09 docs; `badges` domain/data/bloc/tests unchanged.
- `flutter analyze lib/features/badges test/features/badges` → No issues.
- `flutter test --timeout 120s` (repository + bloc files) → 26/26 pass.
- No `DateTime.now` / `google_fonts` in the logic layer or its tests
  ( happyDays is a stored count — PERIODS ruling N/A here); no simulator
  booted; no files outside the logic chunk touched.

VERDICT: PASS
