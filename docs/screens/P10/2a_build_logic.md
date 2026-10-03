# P10 · Stage 2a — build, logic chunk (iteration 2)

Scope: non-UI layer of feature `quests` only
(`domain/**`, `data/**`, `presentation/bloc/**`, DI/route registration,
plus `bloc`/`repository` unit tests). Views/widgets untouched (UI builder owns).

## CONTRACT CHANGES

**ADDITIVE, backwards-compatible:** `QuestsState` gains
`ideas: List<Quest>` (default `const <Quest>[]`), carried through `copyWith`
and `props`. `QuestsBloc._onLoadRequested` reads `_repository.ideas()` once
per load and attaches it to the loading state and every loaded emission
(failure keeps the last ideas via `copyWith` "null means keep").

UI builder: replace the view's `_ideaTemplates()` locator probe with
`state.ideas` (`QuestLibraryBody(items: state.items, ideas: state.ideas)`)
and delete the `get_it` import from
`quest_library_view.dart` — review finding 2 / BUG-P10-8. The body already
takes a required `ideas:` parameter, so no widget signature changes.
No other test file constructs `QuestsState` (grep-verified), so nothing else
breaks. No event shape changed.

## Files changed

- `app/lib/features/quests/presentation/bloc/quests_state.dart` — added
  `ideas` field + `copyWith`/`props` (review finding 2 / BUG-P10-8, bloc half).
- `app/lib/features/quests/presentation/bloc/quests_bloc.dart` — populate
  `ideas` from `_repository.ideas()` on loading + loaded.
- `app/test/features/quests/quests_bloc_test.dart` — stub `repo.ideas` in all
  bloc tests; new `loaded state carries the static idea templates` proof;
  failure/empty/re-emit expectations assert ideas travel (and survive
  failure); state group covers default/copyWith/equality/`props` for `ideas`.
- `app/test/features/quests/quests_repository_test.dart` — the order test now
  pins **creation order** (was title-sorted): Maya's 6 in added order, then
  Leo's 4, then the 2 Anyone quests.

## FIXES_1 triage — items in this layer vs not

Done here:
- Review finding 2 / BUG-P10-8 (bloc half): `ideas` in `QuestsState`,
  populated by the bloc. View half (use `state.ideas`, drop the `get_it`
  import) is the UI builder's — declared above, not implemented here.
- Review finding 10 (order test): the orchestrator's §5 ruling (Active quests
  in CREATION order) has landed on main via shared batch4
  (`8ad0cdc`, `watchActiveQuests` now orders by `createdAt, id`), merged into
  this branch — the test is updated to the ruling and passes. No P10-local
  order code exists or is needed.

NOT this layer (left for UI builder / orchestrator — untouched):
- BUG-P10-1 (double-tap guard), BUG-P10-2 (row `Column` alignment),
  BUG-P10-3 (Active-tab filters), BUG-P10-4 (trailing separator),
  BUG-P10-9 (chip/`+ Add`/row `Semantics` tap action), BUG-P10-11
  (`plate`/`sofa` tile tint), review 6/7/8/11 — all in
  `presentation/views/**` or `presentation/widgets/**`.
- BUG-P10-5/6/7, BUG-P10-10, review 3/4/5 — shared `core/` (already filed in
  `SHARED_REQUEST.md` §1–§5; orchestrator notes shared_batch4 in progress).
- `p10_bugs_test.dart` (9 proofs, bug stage's file) and
  `quest_library_a11y/view/states/filter/meta` tests are outside the
  `bloc|cubit|repository|data` filename scope — not edited here.

Skipped tests in this layer: none (`skip:` grep over both owned files is
empty; nothing to un-skip).

## Verification (this stage only — no simulator, per SIMULATORS rule)

- `dart format lib/features/quests test/features/quests` — clean.
- `flutter analyze lib/features/quests test/features/quests` — No issues found.
- `flutter test test/features/quests/quests_repository_test.dart
  test/features/quests/quests_bloc_test.dart` — all 26 pass (10 + 16).
- No `google_fonts` / `GoogleFonts.*` in the feature's lib or tests.

## LEFT FOR NEXT ITERATION

Nothing in this layer. Watch item: if the shared batch changes `ideas()`
content or the seeded quest set, the pinned id/title/coin/order assertions
above follow it.

VERDICT: PASS
