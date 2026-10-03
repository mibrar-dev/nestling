# P09 — 2a build, logic chunk (FIXES_2 iteration)

## CONTRACT CHANGES (UI builder: read first)

One additive route-contract key (review finding 2, item 1 — the only
FIXES_2 item in this layer):

- **NEW: `QuestsEditorQuery.ideaId` (`'idea'`)** in `quests_routes.dart`.
  P10's Ideas tab already pushes `/quest-editor?idea=<templateId>`; with no
  `?id=`, the editor must seed a NEW draft from
  `GetIt.instance<QuestsRepository>().ideas()` (title, icon, coins,
  repeatRule, needsApproval) with a fresh id — never an update of the
  template row. Unknown idea ids fall back to the new-quest defaults. Key
  precedence: `?id=` (edit) wins over `?idea=` (seeded draft). The remaining
  finding-2 items are yours: read the key next to `_questIdOf`, delete the
  stale `TODO(P10)` in `quest_library_body.dart:242` (name `ideaId`), and
  add the `?idea=idea-bed` view test (new row, not an update).

Deliberately NOT changed (documented, not deferred silently):

- **Review finding 10** (parent-safe toast copy): not applied. The current
  contract — `editorError` carries the repository message into
  `showNestToast` — is pinned by stage-3 assertions
  (`quest_editor_states_test.dart`: failure → toast with the repo message),
  and the raw path is unreachable from the editor (the view clamps before
  dispatching). Remapping at the bloc boundary would turn those green
  assertions red for a path no parent can reach; if the copy changes, the
  states tests must change in the same commit (another stage's file).
- **BUG-P09-6/7/8** (out-of-range shown-vs-saved, alias-tap rewrite, emoji
  nickname): all view-side (`_save` clamp/caption, tile-tap guard,
  `characters.first`). No repository/bloc/route change satisfies any of
  them; the repo's coins validation stays as the unreachable last line of
  defence. Their five skipped proofs live in `p09_bugs_test.dart` (not this
  layer's file) and stay skipped until your halves land.

## Files changed (logic layer only)

- `app/lib/features/quests/quests_routes.dart` — added `ideaId` + doc
  (pure addition; no existing key, path, or builder touched).
- Nothing else in `domain/`, `data/`, `bloc/`, DI, or my tests needed
  work: `watchCoinValuePencePerCoin`, the 1..100 write guard, editor
  events/statuses and the `_FaultyRepository` delegation all stand from
  the FIXES_1 iteration. No `google_fonts`. No shared-file edits → no new
  `SHARED_REQUEST.md`.

## Verification (logic layer only)

- `flutter analyze lib/features/quests test/features/quests` → No issues
  found.
- Feature scope in split runs (one full-dir run SIGKILLs this machine):
  94 + 80 + 113 + 80 = 367 pass, `~5` skipped = exactly the BUG-P09-6/7/8
  proofs awaiting the view halves above.
- `dart format --set-exit-if-changed` on the touched file → clean.
- Whole-app `flutter test` and any simulator deliberately NOT run
  (integrator / stage 5 own them); no simulator was booted.

## LEFT FOR NEXT ITERATION

- Nothing unfinished in the logic layer. UI builder halves: `?idea=`
  seeding + test, BUG-P09-6/7/8 fixes, findings 1/3/4/5/6 view cleanups;
  then the bugs stage un-skips the five proofs. Findings 7/8/9 are
  docs/process for the loop. Open P09 items elsewhere: `NestSegmented`
  shared fix; stage 5 UI check (±2 px).

VERDICT: PASS
