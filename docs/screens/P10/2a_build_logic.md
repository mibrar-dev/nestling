# P10 · Stage 2a — build, logic chunk (iteration 1)

Scope: non-UI layer of feature `quests` only
(`domain/**`, `data/**`, `presentation/bloc/**`, DI/route registration,
plus `bloc`/`repository` unit tests). Views/widgets untouched (UI builder owns).

## CONTRACT CHANGES

None. Public names are exactly what `docs/screens/P10/1_plan.md` §b specifies:
`QuestsRepository.watchItems()` / `ideas()`, `QuestsLoadRequested`,
`QuestsState(status, items, errorMessage)`, `QuestsStatus`. The UI builder can
code against the plan unchanged.

## Files changed

- `app/test/features/quests/quests_repository_test.dart` (new, 10 tests)
- `app/test/features/quests/quests_bloc_test.dart` (new, 6 tests)

No `lib/` changes were needed: the foundation already implements the plan —
`QuestsRepositoryImpl.watchItems()` streams the 12 seeded actives via
`AppDatabase.watchActiveQuests`, `ideas()` returns the 10 static templates,
`QuestsBloc` uses `QuestsLoadRequested` + `emit.forEach` (RULES §4), and
`quests_di.dart` / `quests_routes.dart` (`/quests`, `BlocProvider` +
`QuestsLoadRequested`) are registered.

## Items done (plan §b + §f item 4)

- Verified `watchItems()` yields the demo seed's 12 actives (6 Maya + 4 Leo +
  2 Anyone) title-sorted, re-emits on row insert (no reload events), drops
  deactivated quests, and is empty under `Seed.empty()`.
- Verified `ideas()` has the 10 template ids/titles/coins from the plan
  (`idea-bed` … `idea-reading`); templates stay inactive/unassigned.
- Verified CRUD round-trip (`create`/`get`/`update`/`delete`) against the
  in-memory DB.
- Verified bloc: initial → loading → loaded; stream error → failure with
  message; empty actives → loaded-empty (Seed.empty path); second emission
  updates without a new event; retry after failure reloads to loaded.
- `flutter analyze lib/features/quests test/features/quests` → No issues found.
- `flutter test test/features/quests/quests_repository_test.dart
  test/features/quests/quests_bloc_test.dart` → all 16 pass.
- No `google_fonts` / `GoogleFonts.*` anywhere in this feature's lib or tests.

## Layer boundary (for the UI builder)

Deliberately NOT implemented here (belongs to `presentation/widgets|views/`):
`quest_idea_meta.dart` (idea id → category/minAge/tint/icon map — the `Quest`
entity and `quests` table have no category field and shared schema must not
change), the query/category filter fn, `QuestLibraryBody` local tab/query/
category state, `QuestFilterChip` / `QuestIdeaRow` / `QuestAddButton`, and the
`quest_idea_meta` / `quest_library_filter` / `quest_library_view` tests
(plan §f items 1–3).

## LEFT FOR NEXT ITERATION

Nothing in this layer. If the UI check needs it: confirm the seeded active
count label reads `Active (12)` from `state.items.length` (never hard-coded).

VERDICT: PASS
