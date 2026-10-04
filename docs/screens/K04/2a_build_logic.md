# K04 — Stage 2a build, logic chunk (iteration 2)

Scope: non-UI layer of feature `kid_home` for K04 (`/quest-detail`) —
`domain/**`, `data/**`, `presentation/bloc/**`, DI/route registration.
Views/widgets untouched (UI builder owns them, working in parallel).

## Files changed

None in iteration 2. The iteration-1 change (bloc `stepsFor` getter,
`kid_home_bloc.dart:30`) is committed and still in place; no logic-layer
edit is required by the plan or by FIXES_1 (see triage below).

## FIXES_1 triage — no item is in the logic layer

- **K04-BUG-1 (Major):** root cause is the shared component
  `app/lib/core/design_system/components/nest_balanced_text.dart`.
  RULES §1 forbids editing `app/lib/core/**`; the bug report itself marks
  this as SHARED_REQUEST territory. No domain/data/bloc change can fix a
  width-search collapse inside that component. NOT ACTIONABLE in this layer —
  needs an orchestrator-level shared fix (component + regression test next
  to the component, per the report's suggested fix).
- **K04-BUG-2 (Minor):** `_resolveQuest` in
  `presentation/views/quest_detail_view.dart` — UI-builder owned file.
  NOT MINE.
- **K04-BUG-3 (Major, mandated):** `_iconFor` in
  `presentation/views/quest_detail_view.dart` — UI-builder owned file.
  NOT MINE.
- Skipped proofs in `app/test/features/kid_home/k04_bugs_test.dart`: that
  filename contains none of `bloc`/`cubit`/`repository`/`data`, so it is
  outside my test ownership; I did not edit, un-skip, or run it with
  `--run-skipped` (un-skipping belongs to the stage that fixes each bug).

## Items done

- [x] Re-verified plan §b: no new events, no repo/DI/route changes needed —
      `KidHomeLoadRequested` + `KidHomeQuestCompleted` + `watchHome` +
      `stepsFor` + `completeQuest` already cover K04.
- [x] Re-verified no `google_fonts`/`GoogleFonts` imports in feature code.
- [x] `flutter analyze lib/features/kid_home` → No issues found.
- [x] Ran logic-layer tests with `--timeout 120s`:
      `kid_home_bloc_test.dart` + `kid_home_repository_test.dart` +
      `k01_bloc_paths_test.dart` → all 78 passed.

## CONTRACT CHANGES

None. Event/state shapes unchanged; `stepsFor` getter stands as the UI
builder's checklist call path.

## LEFT FOR NEXT ITERATION

Nothing in the logic layer. Open work belongs elsewhere: K04-BUG-2 +
K04-BUG-3 fixes + their test un-skips are UI-builder owned;
K04-BUG-1 needs a shared-component fix via the orchestrator (this screen
cannot land it under RULES §1).

VERDICT: PASS
