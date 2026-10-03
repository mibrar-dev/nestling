# P09 — 2a build, logic chunk (iteration 1)

## CONTRACT CHANGES (UI builder: read first)

No event/state renames: `QuestsCreateRequested(Quest quest)`,
`QuestsUpdateRequested(Quest quest)`, `QuestsDeleteRequested(String id)`,
`QuestsState.editorStatus` (`QuestEditorStatus.initial/saving/saved/failure`)
+ `editorError` are exactly as `1_plan.md` §2 named them. Two additions the
plan did not name — use these spellings:

- Enum is called `QuestEditorStatus` (values `initial`, `saving`, `saved`,
  `failure`). Save failure → `editorStatus == QuestEditorStatus.failure`
  with the message in `state.editorError` (show it in a `NestToast`).
- Edit-mode id key: `QuestsEditorQuery.questId` (`'id'`) in
  `quests_routes.dart`. The route builder still returns
  `const QuestEditorView()` (unchanged, so the tree keeps compiling while
  both builders work). The VIEW reads the id itself via
  `GoRouterState.of(context).uri.queryParameters[QuestsEditorQuery.questId]`,
  loads with `sl<QuestsRepository>().getQuest(id)` in a `FutureBuilder`
  (unknown id → `Quest not found` + ghost `Back to quests` →
  `QuestsRoutePaths.library`), and passes the quest in as `initialQuest`.
  New id on save: `q-<ms epoch>` (plan §2).

## Files changed (logic layer only — no views/widgets touched)

- `app/lib/features/quests/presentation/bloc/quests_event.dart` — added
  `QuestsCreateRequested` / `QuestsUpdateRequested` /
  `QuestsDeleteRequested` (Equatable props set).
- `app/lib/features/quests/presentation/bloc/quests_state.dart` — added
  `QuestEditorStatus` + `editorStatus` / `editorError` (in `props`;
  `copyWith` gained `clearEditorError` so a new save attempt clears a stale
  error; existing `status`/`items`/`errorMessage` untouched).
- `app/lib/features/quests/presentation/bloc/quests_bloc.dart` — three new
  handlers: emit `saving` (error cleared) → `await` the repository →
  `saved`; on error `failure` + message. `QuestsLoadRequested`
  (`emit.forEach`) byte-identical; editor saves never touch `items` — the
  Drift watch stream re-emits the new list on its own.
- `app/lib/features/quests/quests_routes.dart` — added `QuestsEditorQuery`
  (query-key contract, doc only; no widget/DI/router-shell change).
- `app/test/features/quests/quest_editor_bloc_test.dart` (new, 6 tests) —
  create/update/delete drive the repo and move
  `initial → saving → saved`; repo error → `failure` + message; a retry
  clears the old `editorError`; load path still `loading → loaded`.
- `app/test/features/quests/quests_repository_test.dart` (new, 7 tests) —
  real in-memory Drift via `setUpTestScope`: `q-hoover` seed fixture pinned
  (Hoover the stairs / hoover / maya / weekly, for `?id=q-hoover` edit
  tests); create→get round-trips every editor field verbatim (`days '6'`,
  `dueLabel`, `dueTimeLocal '17:00'`, `needsApproval`, `assigneeChildId`);
  `watchItems` grows 12 → 13 with no reload event; update persists;
  delete removes (unknown id → null); `ideas()` is 10 static templates,
  never rows; writes are scoped to `Seed.familyId`.

Not changed (already satisfied the plan): `Quest` entity (all P09 fields),
`QuestsRepository` interface + Drift impl (`getQuest`/`createQuest`/
`updateQuest`/`deleteQuest`), `quests_di.dart` (repo singleton + bloc
factory already registered). No `google_fonts` anywhere. No shared-file
edits → no `SHARED_REQUEST.md`.

## Verification (logic layer only)

- `flutter analyze lib/features/quests test/features/quests` → No issues
  found.
- `flutter test test/features/quests/quest_editor_bloc_test.dart
  test/features/quests/quests_repository_test.dart` → 13/13 pass.
- `dart format` applied to all six touched files.
- Whole-app `flutter test` and the simulator deliberately NOT run (integrator
  owns them).

## LEFT FOR NEXT ITERATION

- Nothing in the logic layer is unfinished. View work (form draft state,
  validation copy `Pick at least one day`, due sheet, delete modal,
  navigation) belongs to the UI builder per `1_plan.md` §§1,3–5.

VERDICT: PASS
