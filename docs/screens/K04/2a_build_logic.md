# K04 — Stage 2a build, logic chunk (iteration 1)

Scope: non-UI layer of feature `kid_home` for K04 (`/quest-detail`) —
`domain/**`, `data/**`, `presentation/bloc/**`, DI/route registration.
Views/widgets untouched (UI builder owns them).

## Files changed

- `app/lib/features/kid_home/presentation/bloc/kid_home_bloc.dart`
  - Added presentation-supporting getter (plan §b, the only logic change):
    `List<String> stepsFor(String questId) => _repository.stepsFor(questId);`
    so the view can read the K04 checklist without touching GetIt directly.
    No event, no state change.

No changes to `domain/` (entities + `KidHomeRepository` interface already
expose everything K04 needs), `data/` (`stepsFor` map already contains the
`q-tidy` design steps; `completeQuest` already idempotent + period-aware),
`kid_home_di.dart`, `kid_home_routes.dart` (route `/quest-detail` already
registered with `KidHomeLoadRequested` dispatch), or the barrel.

## Items done (plan §b)

- [x] Bloc `stepsFor` getter added — pure delegate, no state/event shape change.
- [x] Verified no new events needed: `KidHomeLoadRequested` (route builder)
      + `KidHomeQuestCompleted(childId, questId, coins)` (existing) cover the
      K04 completion channel; celebration/error routing unchanged.
- [x] Verified no repo changes needed: `stepsFor` / `completeQuest` /
      `watchHome` already exist and are period-aware (K03-BUG-4 ruling).
- [x] Verified no DI/route changes needed: detail route + bloc factory already
      registered.
- [x] Checked `google_fonts`/`GoogleFonts`: no imports in feature code or
      tests (only comment/assertion strings) — nothing to delete.
- [x] `flutter analyze lib/features/kid_home` → No issues found.
- [x] Ran logic-layer tests with `--timeout 120s`:
      `kid_home_bloc_test.dart` + `kid_home_repository_test.dart` +
      `k01_bloc_paths_test.dart` → all 78 passed.

## CONTRACT CHANGES

None. Public event/state shapes unchanged; the added `stepsFor` getter is
exactly the call path the plan §b specifies for the UI builder
(`bloc.stepsFor(questId)` for the checklist; tick `Set<int>` state lives in
the view's `State`, initialised empty).

## LEFT FOR NEXT ITERATION

Nothing in the logic layer. All remaining K04 work is UI-builder owned:
`quest_detail_view.dart` rewrite (quest resolution, steps card, cheer row,
bottom bar, loading/failure/missing states) + `quest_detail_*_test.dart`
view/geometry/copy tests.

VERDICT: PASS
