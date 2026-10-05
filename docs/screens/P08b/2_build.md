# P08b · 2 BUILD (integrate, iteration 2)

Two builders worked this worktree in parallel: `2a_build_logic.md` (the
non-UI layer — `data/**`, `presentation/bloc/**` + the bloc/repository
tests) and `2b_build_ui.md` (the views/widgets + the view/bug tests).
This stage's only job was to make the combined result compile and pass.

Iteration 1 merged with no code changes needed; iteration 2 follows the
iteration-1 FAILs (`LOOP.md: test=FAIL review=FAIL ui=FAIL bugs=FAIL`)
whose 11 fixes are catalogued in `FIXES_1.md`.

## Result

**Gates green on the merged result.** One change made in this stage, both
comment-only, in a file *both* builders had edited (see FIXES below); no
`lib/` file was touched.

## Summary of 2a (logic — iteration 2)

Contract unchanged again: events (`TodayLoadRequested`), `TodayState`
shape, `TodayRepository` interface, DI and `/today-empty` route all as-is.

- `today_bloc.dart` — **T05/B01**: the fresh-nest suffix now uses the
  same predicate as the shared empty branch (`items.isEmpty ||
  summaries.isEmpty`) instead of `summaries.isEmpty` alone, so a family
  with children but no quests (`Seed.newFamily`) reads `A fresh nest`
  rather than `Happy week: 4 days`. P08 unaffected (demo seed has items).
- `today_repository_impl.dart` — **T06/B02**: dropped the
  eldest-first + nickname re-sort in `watchSummaries()`; summaries keep
  `watchChildren` creation order (CHILD ORDER ruling: Maya, then Leo).
  Demo/new-family rendering does not move.
- `today_bloc_test.dart` / `today_repository_test.dart` — new proofs for
  both changes; the two stale "Eldest first" comments corrected.

## Summary of 2b (UI — iteration 2)

All in `today_loaded_body.dart` (populated P08 widgets untouched):

- **T01/B03** — `_EmptyGreeting` top padding removed; the 8 px belongs to
  P08's own local `.greet` rule, which P08b does not have.
- **T04/B04** — greeting is plain `Text` (`NestType.h1`, `maxLines: 2`)
  so it wraps instead of clipping the parent's name at 320 px / 1.3×.
  `NestBalancedText` was tried and rejected (see verification note).
- **T02** — link row is `ConstrainedBox(minHeight: NestDevice.tapParent)`
  + centred glyph: exactly 44 (was 46).
- **T03** — `_TipCard` column `spacing: s1` removed; 16+22+36+16 = 90.
- **B05** — link gains `decorationColor: tokens.sky`.
- Tests: `today_view_test.dart` pins the link ROW at 44 + the sky
  decoration colour; `today_empty_view_test.dart`'s T04 proof rewritten to
  assert `didExceedMaxLines == false` (its old single-line
  intrinsic-width assertion was unsatisfiable for a wrapping heading);
  `p08b_bugs_test.dart` now loads the bundled Nunito Black/Bold/ExtraBold
  so the greeting's y measurements and wrap assertions are device-faithful
  instead of measuring in the square-advance fallback.

## Cross-half checks run (all consistent)

- `p08b_bugs_test.dart` is the one file both builders edited (2a
  un-skipped B01/B02, 2b un-skipped B03–B05 and added the font loading).
  The merged file has exactly one `_loadBundledFonts`, no remaining
  `skip:` on any of the five proofs — `flutter test` on the file alone:
  `00:01 +14: All tests passed!` with B01–B05 all live and green.
- 2b's `maxLines: 2` greeting and 2a's bloc predicate agree on what "the
  empty state" means (`items.isEmpty || summaries.isEmpty`); the view's
  branch and the bloc's date line cannot now disagree.
- 2a's removal of the sort is reflected in 2b's `emptyMessageSuffix` doc
  comment (creation order) and in `today_view_test.dart`'s
  three-children Pip test comment — no half-left "eldest first" text in
  `lib/`.
- CSS spot-check against `design/html-source/screens/P08b-today-empty.html`:
  `padding-top: 8px` on `.greet` exists only in P08's local style block,
  never in P08b's — 2b's T01 removal is HTML-correct, not a regression.
- BALANCED HEADINGS rule checked and **not** violated: `text-wrap:
  balance` lives on `.h1` (class) in `components.css`, while P08b's markup
  is a bare `<h1>` inside `.greet` with no class, so the browser default
  applies (wrap). `NestBalancedText` would have force-split the one-line
  heading and reintroduced the +8 px class of drift — hence plain `Text`.
- `git diff --stat` shows only `lib/features/today/**` and
  `test/features/today/**` plus this screen's own notes — no file outside
  RULES §1 touched; no simulator booted, installed on or driven.

## FIXES items

DONE (by the builders, verified by me here) — all 11 of `FIXES_1.md`:

- [x] **T05/B01** fresh-nest date line for children-with-no-quests.
- [x] **T06/B02** message names children in creation order.
- [x] **T01/B03** empty body starts at the scroll origin (no 8 px pad).
- [x] **T02** `Browse ideas` row exactly 44 (tap floor kept).
- [x] **T03** tip card's phantom 4 px gap removed.
- [x] **T04/B04** greeting wraps rather than clipping.
- [x] **B05** link underline paints sky.
- [x] Review findings 1–8: 1/3/4/5/6/7 = the items above; 2 = T01;
  8 = regression coverage now pinned (bloc test for the new-family state,
      repository test for creation order, view test for the 44 row +
      decoration colour).
- [x] UI findings 1–3: date line, +8 px shift, underline colour — all
      covered above.

DONE (this stage):

- [x] Two stale comments in `test/features/today/p08b_bugs_test.dart` —
  the file header still claimed "Every proof is `skip:`-marked … until the
  fix iteration unskips them" (all five now run), and the B02 body still
  said the app "currently renders 'Zara, Maya and Leo'" (2a removed that
  sort). Comment-only; no behaviour touched; full suite re-run after.

LEFT (not integration work — not blockers for this stage):

- [ ] `2_build.md`'s remaining loop work is the UI check (`5_ui`): re-shoot
      light + dark and re-measure against the PNGs now that the +8 px shift
      is gone. Expected, non-findings per 5_ui: the Pip slot renders
      `PipAvatar(mochi, sunny, stage 1)` at 140 instead of the v1 egg SVG
      (PIP rule), and the tab-bar surface runs to the physical edge where
      the PNG shows a cream strip + pill (BOTTOM EDGE owner rule). Status
      bar glyphs and the DB-driven day part are excluded from measurement.
- [ ] `SHARED_REQUEST.md` (router/tab-bar move) is resolved: `5_ui`
      confirmed `/today-empty` renders inside the Today `StatefulShellBranch`
      with Today active, tab-bar top at 727 in both themes. Can be closed
      by the orchestrator.
- [ ] Cross-screen watch item, not a P08b defect: 2a's sort removal in
      `watchSummaries()` changes the order the *shared* repository returns
      children for every screen that consumes it (P08 kids grid, P15, …).
      Maya-then-Leo rendering is unchanged for both seeds; any screen that
      relied on age ordering should be re-checked by its own loop.

## Gates and tails

```
$ dart format .
Formatted 652 files (0 changed) in 2.28 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 3.9s)

$ flutter test --timeout 120s
01:37 +4684 ~13: All tests passed!

$ flutter test --timeout 120s test/features/today/p08b_bugs_test.dart
00:01 +14: All tests passed!      # B01–B05 live, none skipped
```

4684 passed, 13 pre-existing skips, 0 failures; no ignore added to
`analysis_options.yaml`, no test skipped or deleted by this stage.

VERDICT: PASS
