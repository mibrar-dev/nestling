# 2a BUILD LOGIC — K03b Kid home all done (iteration 1)

## CONTRACT CHANGES

None made this iteration. Proposed (per 1_plan.md §a–b, for next iteration):
- ADD `bool get allDone => totalCount > 0 && doneCount == totalCount;` to
  `KidHomeState` (`app/lib/features/kid_home/presentation/bloc/kid_home_state.dart`,
  next to existing `doneCount`/`totalCount`/`fraction`). Pure getter, no new
  events/states/repository methods. UI builder codes against `state.allDone`,
  `state.doneCount`/`totalCount`/`fraction`, `state.child`, `state.items` (all
  existing names unchanged).

## Findings (investigation only — no code edits made)

- `kid_home_state.dart`: has `doneCount` (approved + done_pending), `totalCount`,
  `fraction`; `allDone` getter is MISSING — the single logic addition required.
- `kid_home_bloc.dart` / `kid_home_event.dart`: no changes needed. `KidHomeLoadRequested`
  → `watchHome()` period-scoped statuses already live in
  `KidHomeRepositoryImpl._watchItemsFor` via `countsForCurrentPeriod` (PERIODS ruling).
- `kid_home_repository.dart` / `data/kid_home_repository_impl.dart`: no changes needed.
- `kid_home_routes.dart`: `kidHomeDoneRoute` (`/kid-home-done`, name `kid-home-done`)
  still builds placeholder `KidHomeDoneView`; per plan §c it must build `KidHomeView`
  with the same `BlocProvider(... KidHomeLoadRequested ...)` as `kidHomeRoute`.
  Route-file edit is in logic-layer ownership, but the placeholder deletion
  (`presentation/views/kid_home_done_view.dart`) and barrel export removal
  (`kid_home.dart`) belong to the UI builder / integrator — NOT touched here per
  the DO-NOT-edit-views rule, to avoid a parallel-builder conflict.
- `kid_home_di.dart`: no changes needed (repository + bloc wiring already covers both routes).
- Tests: `kid_home_bloc_test.dart` covers done counts/fraction but has no `allDone`
  cases yet; no `*bloc*`/`*repository*`/`*data*` test file was added or modified.

## Files changed

None.

## Items done

- Read 1_plan.md, ORCHESTRATOR_NOTES.md, RULES.md, ARCHITECTURE.md, DESIGN_SPEC §5 K03b,
  SPACING_SPEC, bloc/state/events, repository interface + impl, routes/DI/barrel,
  existing bloc tests. Confirmed the logic-layer scope is the one `allDone` getter
  (+ route builder alias + bloc/repository unit tests).

## LEFT FOR NEXT ITERATION

1. Add `allDone` getter to `KidHomeState`.
2. Point `kidHomeDoneRoute` builder at `KidHomeView` (drop unused
   `kid_home_done_view.dart` import in the routes file only; leave the view file +
   barrel export for the UI builder/integrator to remove).
3. Add unit tests in `app/test/features/kid_home/` (bloc/state file only):
   empty list → false; partial 4/6 demo statuses → false; all approved/done_pending
   → true; `not_yet`/`to_do` present → false.
4. Run `flutter analyze lib/features/kid_home` and the touched test files with
   `flutter test --timeout 120s`; no whole-app test run, no simulator.

VERDICT: FAIL
