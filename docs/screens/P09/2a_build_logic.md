# P09 — 2a build, logic chunk (FIXES_3 iteration)

## CONTRACT CHANGES (UI builder: read first)

One behaviour change at the bloc boundary (review finding 4 — carried
twice, now fixed). Everything else is additive or docs:

- **NEW: `QuestsBloc.saveFailedMessage`
  (`'Could not save the quest. Try again.'`).** All three editor handlers
  now emit `editorError: _editorError(error)`: an `ArgumentError` (today
  only the coins range guard — a programmer error unreachable from the
  clamped editor) maps to the parent-safe copy and the technical detail
  goes to `dart:developer log(name: 'quests')`; every other failure
  (offline, disk full) still surfaces the repository message, so the
  states suite's toast pins are untouched. If you assert on failure copy,
  assert the constant — never a Dart `toString()`.
- No event/state/route shape changes. `watchCoinValuePencePerCoin`, the
  1..100 write guard, `QuestsEditorQuery.{questId,legacyQuestId,ideaId}`
  all stand.

Deliberately NOT changed (documented, not deferred silently):

- **BUG-P09-9/10/12** (toggle compensation, hit-slop clipping, legacy
  glyphs): view-side only — `quest_editor_view.dart`,
  `quest_editor_widgets.dart` + geometry assertions. Nothing in
  `domain/`/`data/`/`bloc/` satisfies any of them.
- **BUG-P09-11** (9899 taps to repair 9999): the jump-to-boundary /
  `Use 100` repair is stepper/handler logic in the view. The repo guard
  stays as the last line of defence.
- **Review findings 1b/1c/1d, 2, 3** (stale test lookups, icon switch,
  card padding): view + view-test files — the parallel builder's.
- **Review finding 7** (stale `DESIGN_SPEC` tile size): `docs/` is
  off-limits — orchestrator doc pass, as the review itself says.
- **Review finding 9** (view DI degradation): view-side, marked optional.
- **`family_time_test` core failure** (FIXES_3 observation): `test/core/`,
  RULES §1 forbids — needs the core owner.
- The five BUG-P09-6/7/8 proofs stay skipped in `p09_bugs_test.dart`
  (not this layer's file); un-skipping is the bugs stage's after the view
  halves above land.

## Files changed

Logic layer (`domain/`, `data/`, `bloc/`, tests matching
bloc/cubit/repository/data):

- `app/lib/features/quests/presentation/bloc/quests_bloc.dart` —
  `saveFailedMessage`, `_editorError` mapper, all three editor handlers
  use it (load path untouched).
- `app/lib/features/quests/domain/quests_repository.dart` — finding 8:
  the create/update doc now promises `AssertionError` in debug /
  `ArgumentError` in release (the behaviour was already that; only the
  comment lied).
- `app/test/features/quests/quest_editor_bloc_test.dart` — the BUG-P09-4
  path test now pins failure + exactly `saveFailedMessage` + absence of
  `Invalid argument` (status mapping unchanged).

Requested doc corrections (screen's own docs dir, RULES §1; no code):

- `docs/screens/P09/SHARED_REQUEST.md` — finding 5: §2/§4/§5/§6 retitled
  `— RESOLVED on main (shared/shared_batch5)` in §1's style (toggle 51×31,
  quest icons, stepper U+2212, textfield s3/12 all verified on disk;
  bodies + P09-local follow-ups kept).
- `docs/screens/P09/FIXES_2.md:77` — finding 6: `NestIcons.basket` →
  `NestIcons.dishwasher` (`questDishes` once the icon switch lands). The
  cited `3_test.md:74` contains no basket reference (stale pointer; other
  mentions are accurate revert/measurement records, untouched).

## Verification (logic layer only)

- `flutter analyze lib/features/quests test/features/quests` → No issues
  found.
- Feature scope in split runs (one full-dir run SIGKILLs this machine):
  102 + 84 + 118 + 80 pass; `~7` skips = the BUG-P09-6/7/8 proofs + P12-BUG-05.
  The 3 failures in the view/geometry group are the pre-existing,
  documented BUG-P09-9 rects (approval 68 vs 72, track +4/−2, due card
  −4y) failing identically before this iteration — view-side fix, not
  this layer (no save-failure path is exercised by those tests).
- `dart format --set-exit-if-changed` on all touched files → clean.
- Whole-app `flutter test` and any simulator deliberately NOT run
  (integrator / stage 5 own them); no simulator was booted.

## LEFT FOR NEXT ITERATION

- Nothing unfinished in the logic layer. UI builder halves: findings
  1–3 (test lookups, card padding + Transform, four `quest*` icons),
  BUG-P09-9/10/11/12, BUG-P09-6/7/8 view repairs; then the bugs stage
  un-skips. Open elsewhere: stage 5 re-shoot after the icon/toggle
  switch; core `family_time_test` owner.

VERDICT: PASS
