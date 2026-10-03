# P09 — stage 2 · INTEGRATE (iteration 1)

Two builders worked the screen in parallel: **2a** (logic) and **2b** (UI).
This stage only made the combined result compile and pass. No redesign, no
refactor, no new screen behaviour beyond the two integration defects listed
in §2.

## 1. What 2a and 2b handed over

**2a — logic (`2a_build_logic.md`, iteration 3).** No logic edits this run;
it audited the `main` merge (`5ef8ea4`, P14 reward shop + schema v5→v6) and
confirmed the P09 logic contract is unchanged:

- `QuestsCreateRequested(Quest)` / `QuestsUpdateRequested(Quest)` /
  `QuestsDeleteRequested(String)`;
- `QuestsState.editorStatus` (`initial/saving/saved/failure`) + `editorError`,
  with P10's additive `ideas` kept in the same `props` list;
- edit id via `GoRouterState.of(context).uri.queryParameters[QuestsEditorQuery.questId]`
  (that constant is `'id'`);
- the view suite asserts the a11y-actions rule (18 × `hasAction(tap)` +
  `performAction` → real state/DB change).

**2b — UI (`2b_build_ui.md`).** Re-verified the whole UI layer against both
PNGs with the bundled faces loaded, fixed the one shape outside ±2 px and
turned the throwaway probe into a permanent proof:

- `QuestEditorMetrics.toggleTrackOffset = Offset(4, -2)` — `NestToggle` centres
  its 51×31 track inside a 59×44 box, while the CSS hangs the *hit area*
  around a track that stays flush with the row's content edge. The view wraps
  the toggle in `Transform.translate` so the painted track lands on
  x 303→354, y 620.5→651.5. The 44 px tap target only moves into the card's
  own 16 px padding (where `.toggle::before` overhangs anyway).
- `ValueKey('quest-editor-grabber')`, `ValueKey('quest-editor-sheet')`, and the
  plan §1-3 `Semantics(container: true, label: 'Quest icon')` radiogroup;
- new `quest_editor_view_geometry_test.dart` (5 tests, real Inter/Nunito via
  `FontLoader`) pinning absolute design coords for ~30 elements in light and
  dark, the bottom-edge rule and the radiogroup;
- `quest_editor_view_probe_test.dart` deleted (its numbers became assertions).

The two halves met on the merged bloc/state, the `QuestEditorView` + local
widgets, and the merged `quests_repository_test.dart`; nothing needed a
rename, a shape change or an import fix.

## 2. FIXES done in this stage

### F1 — 8 red tests in `test/features/today/**` (blocking; the whole point of this stage)

`flutter test` reported `+2298 ~1 −8`. Every failure was the same
assertion: `find.text('P09 Quest editor')` — the **placeholder** `AppBar`
title of the foundation stub, which P09 legitimately replaced with the real
sheet (the P09 design has no AppBar). P08's tests used it to locate the pushed
route from Today.

- Files: `app/test/features/today/today_view_test.dart` (11 uses),
  `app/test/features/today/p08_bugs_test.dart` (4 uses).
- **Outside RULES §1 by the letter** — flagged in `SHARED_REQUEST.md` §3.
  Sanctioned by the repo's own precedent for this exact class:
  `docs/screens/_shared/router_push_test_fix_REPORT.md` §4 ("Never a
  placeholder view title"; §5 names these two files) and
  `docs/screens/_shared/shared_batch4.md` §4 ("You MAY edit
  `app/test/features/today/**` … to delete the hidden anchor").
  Re-adding a hidden anchor to P09 instead was rejected: the orchestrator
  ordered exactly that deleted for P10 (`P10/ORCHESTRATOR_NOTES.md` 13:42
  item 2, `P10/4_review.md`).
- What replaced it, preserving each proof's intent:
  - "the editor is on screen" → `pushedPath(tester)` / a local `_pushedUri`
    / `_pushedRouter` reading `GoRouter.state.uri` from the top-most rendered
    route (query params included, which the two `queryParameters['questId']`
    assertions need);
  - "exactly **one** editor page" (B12 double-tap, "a later tap cannot stack
    a second editor", B14 relatch) → `find.byType(QuestEditorView,
    skipOffstage: false)` `findsOneWidget`, which still counts pages and does
    not depend on any screen's copy;
  - `pop` returning to `/today`, the guard latching/releasing and every other
    assertion are untouched.
- No P08 assertion was relaxed or deleted; no tolerance was loosened.

### F2 — real integration defect: `?questId=` (what P08 pushes) opened a blank NEW quest

`today_loaded_body.dart:700` pushes
`${QuestsRoutePaths.editor}?questId=${item.questId}`, but P09's contract (plan
§3) is `?id=`. So a tap on a quest row on Today created a *new* quest form
instead of editing the row — invisible to tests, because P08 only asserts the
URI. That file is another feature's, so the fix is on P09's side:

- `QuestsEditorQuery.legacyQuestId = 'questId'` documented as an accepted
  alias (`quests_routes.dart`, feature-local — plan §3 sanctions this file);
- `_questIdOf` reads `?id=` first, then `?questId=`;
- proof: `quest_editor_view_test.dart` → "?questId= (P08 Today's spelling)
  also pre-fills edit mode" (`Edit quest` + `Delete quest` + the row's title,
  and `New quest` absent).

### F3 — P10's stale `TODO(P10)` on the Active row (same feature, now false)

`quest_library_body.dart` carried
`// TODO(P10): P09 does not read a ?id= query param yet, so the editor opens
blank`. The premise is gone, so the row now pushes
`${QuestsRoutePaths.editor}?id=${quest.id}` and the comment states the
contract. Its P10 test pinned the old assumption
("an Active row opens the editor with no query", reason: *"P09 reads ?idea,
not ?id"*); it now asserts the real outcome — the row's own id in
`?id=` **and** `Edit quest` on screen. Strictly stronger.

### FIXES left open (deliberate, unchanged from 2b)

- `?idea=` prefill (P10's `+ Add` on an idea row) is **not** implemented: it is
  new behaviour, not a merge breakage. `TODO(P10)` stays in
  `quest_library_body.dart`.
- `NestToggle` track/hit-area asymmetry stays compensated in-view (shared
  advisory, `SHARED_REQUEST.md` §2, non-blocking).
- The due-time sheet and the delete-confirm modal have no P09 design frame
  (2b deviation 5).
- `quest.detail` is written as `Weekly · 15 coins` on save (2b deviation 6,
  data-derived, P10 renders it as the meta line).

## 3. Verification (tails)

```
$ dart format --set-exit-if-changed .
Formatted 475 files (0 changed) in 1.38 seconds.          (exit 0)

$ flutter analyze
Analyzing app...
No issues found! (ran in 3.7s)

$ flutter test
00:49 +2307 ~1: All tests passed!
```

`~1` is the single pre-existing `skip:` in the repo —
`test/features/pocket_money/p12_bugs_test.dart:320` (P12-BUG-05), identical on
`main` (`git show main:… | rg 'skip: true'`), another feature's file, not
touched here. The `WARNING (drift): AppDatabase created multiple times`
notices in the output are the repo-wide debug-build notice from
`test_scope.dart`, not failures.

Scope of the diff: `app/lib/features/quests/**`,
`app/test/features/quests/**`, the two P08 test files above (F1, flagged),
`docs/screens/P09/**`. `git diff --stat -- app/lib/core app/lib/app tools/` is
empty — no shared code, no `tools/`, no `analysis_options.yaml`, no `skip:` and
no `// ignore:` added. No simulator was booted, installed on, screenshotted or
driven in this stage. `flutter clean` was never run.

## 4. Handover

Stage 3 (test) has the full suite green and can extend `test/features/quests`
without touching shared files. Stage 5 (UI check) can rely on 2b's geometry
table; note F2/F3 changed no layout (same view, one query key), so the ±2 px
numbers stand, and `?id=`/`?questId=` only decide *new* vs *edit* mode.

VERDICT: PASS