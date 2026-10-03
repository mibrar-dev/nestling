# P10 · Stage 2a — build, logic chunk (iteration 3)

Scope: non-UI layer of feature `quests` only
(`domain/**`, `data/**`, `presentation/bloc/**`, DI/route registration,
plus `bloc`/`repository` unit tests). Views/widgets untouched (the UI
builder has uncommitted work in `quest_idea_row.dart` /
`quest_library_body.dart` — not disturbed).

## CONTRACT CHANGES

None this iteration. `QuestsState(status, items, ideas, errorMessage)` and
`QuestsLoadRequested` are exactly as declared in iteration 2. The only
behavioural change is internal to the bloc (failed watcher is now released;
see below) — states, events and their shapes are unchanged.

## Files changed

- `app/lib/features/quests/presentation/bloc/quests_bloc.dart` — review
  finding 3: the `watchItems()` stream is now passed through a
  `_closeOnError` transformer (forward the first error, then close) before
  `emit.forEach`, so a failed load's Drift watcher is cancelled and `Try
  again` starts exactly one fresh subscription instead of piling another
  live watcher behind the dead one. Same guard as `today_bloc.dart:80`,
  `family_bloc.dart:110`, `pocket_money_bloc.dart:174`; typed
  `StreamTransformer<List<Quest>, List<Quest>>` (the shared files'
  `List<dynamic>` version does not satisfy this call site).
- `app/test/features/quests/quests_bloc_test.dart` — new proof `a failed
  load releases its watcher so retry subscribes exactly once`: broadcast
  controller, error → `hasListener == false` (asserted in `act`), retry →
  `hasListener == true` while loaded, `verify(repo.watchItems).called(2)`.

## FIXES_2 triage — items in this layer vs not

Done here:
- Review finding 3 (MAJOR, `Try again` watcher leak): fixed + proven (above).
  Mutation-checked: the new test FAILS against the pre-fix bloc
  (stashed/re-ran/re-popped) and passes with the fix.

NOT this layer (untouched — owned by UI builder / orchestrator):
- BUG-P10-12 / review finding 2 (invisible filter after tab round-trip):
  `quest_library_body.dart` state + `TextEditingController` — UI builder.
- BUG-P10-13 / review finding 5 (search field accessible name),
  review finding 1/BLOCKER + finding 4 (NestSegmented double label,
  2 px search-field box): shared `core/` — orchestrator via
  `SHARED_REQUEST.md` (RULES §1 forbids screen edits there).
- Review 6/7/8 (`quest_idea_row` style, gutters, tile token): widgets —
  UI builder.
- FIXES-1/2/3 (states-test mock stub, a11y finder regex, anchor deletion):
  already landed by the integrator / in UI files.
- `p10_bugs_test.dart` (BUG-P10-12 proof, still skipped/failing) and the
  a11y/geometry suites are outside the `bloc|cubit|repository|data`
  filename scope — not edited here.

Skipped tests in this layer: none (no `skip:` in either owned file).

## Verification (this stage only — no simulator, per SIMULATORS rule)

- `dart format lib/features/quests test/features/quests` — clean.
- `flutter analyze lib/features/quests test/features/quests` — No issues found.
- `flutter test test/features/quests/quests_repository_test.dart
  test/features/quests/quests_bloc_test.dart` — all 27 pass (10 + 17).
- No `google_fonts` / `GoogleFonts.*` in the feature's lib or tests.

## LEFT FOR NEXT ITERATION

Nothing in this layer. Residual red in the feature suite (BUG-P10-10 ×3,
BUG-P10-12, BUG-P10-13) is all UI/shared-owned per the triage above.

VERDICT: PASS
