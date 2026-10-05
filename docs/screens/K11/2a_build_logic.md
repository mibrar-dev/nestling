# K11 · Badges — stage 2a build, logic chunk (iteration 2)

Scope: non-UI layer of feature `badges` only
(`domain/**`, `data/**`, `presentation/bloc/**` + feature unit/bloc tests).
No edits to `presentation/views/**` or `presentation/widgets/**`.
Plan sources: `docs/screens/K11/1_plan.md` §b + §f, `6_bugs.md` (K11-BUG-1/2),
`4_review.md` findings, `ORCHESTRATOR_NOTES.md` (mandatory; no `FIXES_1.md`
exists in this worktree, so the bugs/review/notes files are the fix list).

## CONTRACT CHANGES (additive only — no renames, no removals)

- `BadgesState` gains `copyWithLoading()` (loading clears a stale
  `errorMessage`; review finding 4). The view never reads `errorMessage`
  on the loading path (generic spinner), so no view change is needed.
- `watchActiveBadges` semantics refined (K11-BUG-2): the persisted
  `activeChildId` when it names a real child, else the first child in
  creation order, else the EMPTY shelf (`BadgesData(childId: '', items: [],
  happyDays: 0)`). Stream shape unchanged; the view already renders
  `items.isEmpty` as the childless empty state (`_BadgesEmpty`), so no
  view change is needed. No event/state renames; the UI builder codes
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

## Iteration 2 (this stage)

### Files changed (logic chunk only)

- `app/lib/features/badges/data/badges_repository_impl.dart`:
  K11-BUG-2 — `watchActiveBadges` now combines `watchAppState` with the
  roster (`watchChildren(Seed.familyId)`, creation order) and resolves
  via `_resolveChildId` (persisted id when it names a real child, else
  first child, else null → empty `BadgesData`); `watchItems` routes
  through the same resolution (its `?? 'maya'` is gone too). Also
  review finding 1 (legacy `new(...)` constructor → modern syntax).
- `app/lib/features/badges/domain/badges_repository.dart`: doc contract
  for the resolution (no signature change).
- `app/lib/features/badges/presentation/bloc/badges_state.dart`: added
  `copyWithLoading()` (review finding 4 — retry starts clean).
- `app/lib/features/badges/presentation/bloc/badges_bloc.dart`: loading
  path uses `copyWithLoading()` (failure path untouched).
- `app/test/features/badges/badges_repository_test.dart`: 9-row design
  seed (shared `shared/k11_badges_seed` landed on main) — insertion
  order, 4 earned / 5 todo, titles; earn-probe id `tidy-champion` →
  `bins-out`; new `child resolution (K11-BUG-2)` group (null active →
  Maya, unknown id → Maya, Zoe-only family → Zoe with her badge/days,
  no children → empty shelf, `watchItems` follows suit); `Seed.empty`
  now also asserts `childId` empty.
- `app/test/features/badges/badges_bloc_test.dart`: retry-spinner
  assertion tightened (`errorMessage == null` on loading) + new
  `copyWithLoading` value-semantics test.
- NOT touched (other owner's chunks): `presentation/views/**`,
  `presentation/widgets/**`, `badges_view_test.dart`,
  `badges_widget_geometry_test.dart`, `badges_a11y_test.dart`,
  `badges_art_test.dart`, `badges_matrix_test.dart`, `k11_bugs_test.dart`.

### Items done

- [x] K11-BUG-2 fixed in the logic layer (ORCHESTRATOR_NOTES mandatory).
- [x] Review findings 1 (ctor syntax) and 4 (stale error on loading)
  fixed; finding 2 is widget code (UI builder fixed it in
  `happy_week_card.dart` + a view regression test this iteration);
  finding 3 is explicit hardening-only ("if ever touched") — left as is.
- [x] Tests updated for the 9-row seed; 5 new resolution tests.
- [x] `flutter analyze lib/features/badges test/features/badges` →
  No issues found (scoped analyze of my files; full-scope run is the
  integrator's).
- [x] `flutter test --timeout 120s test/features/badges/` (whole
  feature dir, both chunks) → 129 passed, 2 skipped (the two
  `k11_bugs_test.dart` skips), 0 failed.
- [x] No `DateTime.now` / `google_fonts` in the layer; no clock use
  (verbatim-`happyDays` repo test documents the no-clamp contract —
  K11-BUG-1 stays a widget-side clamp); no simulator; no global kills.
- [x] K03 stash incident (see below) fully recovered; K11 tree verified
  clean of it.

### K11-BUG-2 widget test — still skipped, with evidence

- The repo/bloc layer proves the fix: Zoe/null/empty scenarios pass
  (`badges_repository_test.dart` `child resolution (K11-BUG-2)` group),
  and demo-state widget tests pass with the new stream
  (`the title carries the design copy`,
  `earning a badge re-reads the grid and the subtitle`).
- But `k11_bugs_test.dart` K11-BUG-2 (write-then-subscribe widget pattern:
  delete children, insert Zoe, null the active child, pump) still sees a
  perpetual spinner. Decisive control: the same test against the ORIGINAL
  `?? 'maya'` implementation (via a temporary `git show HEAD:` swap,
  restored afterwards) fails at the SAME assertion — so the breakage is
  independent of this stage's change. A probe further showed RAW Drift
  watches (`watchAppState`/`watchChildren`/`watchChild`) staying silent
  in that write-then-subscribe widget pattern, while one-shot queries
  work — i.e. below my layer, in test-infra/FakeAsync territory. (Two
  earlier probe runs hung the tool call on teardown pumps and were
  discarded; all probe files deleted.)
- The file is outside my owned filenames and the failure reproduces
  without my change, so un-skipping belongs to the test stage /
  integrator with a quieter machine or a re-seeded variant of the
  repro — NOT to a logic edit. Suite stays green-skipped.

### Process incident (handled, no action needed)

- Mid-stage, a `git stash push` with worktree-relative paths failed and
  a chained unconditional `git stash pop` applied ANOTHER screen's stash
  (`WIP on screen/K03`: `kid_home_di.dart` comment + 2 K03 brief
  iteration bumps) into this tree and dropped the stash entry.
- Recovered completely: K11 files reverted (`git checkout --`),
  stash commit `c8c96c6` restored to `refs/stash` + reflog so
  `git stash list` shows it again (`stash show --name-only` verified),
  K03 worktree confirmed untouched (only its own in-progress edits).
  Lesson: never chain `pop` after a fallible command; never touch the
  shared stash from a screen worktree.

## LEFT FOR NEXT ITERATION

- `k11_bugs_test.dart` K11-BUG-2 un-skip + pass (test stage; see evidence
  above — needs the write-then-subscribe widget-pattern silence
  investigated, likely infra/FakeAsync rather than product code).
- K11-BUG-1 widget clamp is the UI builder's item (already visible in
  their diff with a regression test; not verified by this stage).
- `SHARED_REQUEST.md` seed item is closed (landed as
  `shared/k11_badges_seed`); the `TODO(K11)` removal is the UI builder's
  (already visible in their diff).

## Iteration 3 (this stage — no FIXES_2.md exists)

- Fix list assembled from the loop artifacts instead: `6_bugs.md`
  (iteration 2: both bugs fixed+verified, no new bugs), `4_review.md`
  (single minor finding), `3_test.md` (no screen bugs),
  `ORCHESTRATOR_NOTES.md` 06:55 locked-medal art (widget/artwork layer —
  not mine), `5_ui.md` (geometry only).
- Only logic-layer candidate is review finding 1 (`_switchMap`
  cancel/subscribe overlap — explicitly "hardening only" with "fix (if
  ever touched)", stage-6 10-burst probe proving no stale emission, and
  identical to the K08 shared pattern). Per the finding's own guidance
  and to avoid diverging from K08: NOT touched, no lib edits this
  iteration.
- Post-merge (`179836f`) re-verification only:
  `flutter analyze lib/features/badges
  test/features/badges/badges_bloc_test.dart
  test/features/badges/badges_repository_test.dart` → No issues found;
  `flutter test --timeout 120s` (repository + bloc files) → 37/37 pass
  (test stage grew the files: bloc 17, repo 20 — all green unmodified).
- No contract changes; no files outside the logic chunk touched
  (working tree shows only the loop's own `.brief_*` modifications);
  no simulator, no global kills.

VERDICT: PASS
