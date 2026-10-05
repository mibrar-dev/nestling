# K11 · Badges — stage 2 build, INTEGRATE (iteration 1)

Merge of the two parallel builders for feature `badges`. Sources:
`2a_build_logic.md` (logic chunk) + `2b_build_ui.md` (UI chunk), plan in
`1_plan.md`.

**Outcome: the two halves merged with ZERO integration fixes.** No file under
`app/` was edited by this stage — `git diff --stat HEAD -- app/` is empty, and
the builders' code was already committed (`6220ab0` wip, `9feace7` main merge).
`docs/screens/K11/ORCHESTRATOR_NOTES.md` does **not** exist, so there are no
mandatory orchestrator notes for this screen.

## Summary of 2a (logic chunk — domain / data / bloc)

No contract changes: the public names match `1_plan.md` exactly, so 2b could
code the view against the plan as written. That is the main reason the merge
needed no repair.

- `BadgesData(childId, items, happyDays)` entity (new, Equatable).
- `watchActiveBadges()` on `BadgesRepository` + impl: `watchAppState` →
  `activeChildId ?? 'maya'` → per-child `combineLatest2(watchShelf,
  watchHappyDays)`, via a feature-local `_switchMap` (K08 precedent) rather
  than the plan's literal `asyncExpand`, because `asyncExpand` stalls forever on
  never-closing Drift watch streams. Same public stream shape.
- `watchShelf` design detail copy owned in the repository (`Got it!` earned /
  `Keep going!` to-do) so the view never remaps it.
- Bloc: K08 `KidShopBloc` guard pattern literally — single `_sub`, reloads
  ignored while live, sub released on error/close so `Try again` works, load
  events never re-added.
- State: `childId` (`''` until first emission), `items`, `happyDays` (0..7),
  `copyWithLoaded` (clears stale errors), `isLoaded`.
- DI/routes needed no change — `badges_di.dart` and `badges_routes.dart`
  already register the bloc and dispatch `BadgesLoadRequested`.
- Tests: `badges_repository_test.dart` (12) + `badges_bloc_test.dart` (14).
- Verified `BadgesState` is exactly what 2b's view consumes —
  `childId` / `items` / `happyDays` / `copyWithLoaded` / `isLoaded` all present,
  which is why no cross-chunk rename or state mismatch had to be patched.

## Summary of 2b (UI chunk — views / widgets)

- `badges_view.dart` — `KidScope` + transparent `Scaffold` + `NestStatusBar` +
  `.krow-top` + home-indicator reserve, `BadgesCopy` (design copy transcribed
  character-by-character), back/lock, `BlocBuilder` for loading / failure /
  empty / list, `ListView`, 3-column `_BadgeGrid`.
- `badge_grid_cell.dart` — the `.k11-b` tile: `artFor(id)` over
  `NestlingIllustrations.badge*`, 60×60 medal, name box, sub line, earned =
  solid 3 px ink border + `kidShadow`, to-do = `NestDashedBorder`. One merged
  `Semantics` label `"<name>, <detail>"`, deliberately **no** tap action (static
  card, no detail route exists).
- `happy_week_card.dart` — the `.k11-week` card: 7 dots sized by
  `LayoutBuilder`, first `happyDays` filled, `M T W T F S S` letters, centred
  `.kcap` why-line.
- Tests: `badges_view_test.dart` (26) + `badges_widget_geometry_test.dart` (18).
- It fixed two real defects and made the inherited test files compile
  (8 analyzer issues in the view/widget tests, plus a `Badges` Drift-table vs
  `Badge` entity confusion, an unawaited `GoRouter.push`, a RangeError from
  indexing a 3rd cell on rows the 8-row demo shelf does not fill, and a float-tail
  `Size.square(60)` comparison).

## FIXES items

### Done in this stage

- **None required.** Format, analyze and the full suite were already green on
  the merged tree, so per the "smallest change / do not redesign" instruction I
  changed no code.

### Done by the builders before the merge (verified still green)

- 2b defect 1 — missing home-indicator reserve. `1_plan.md` §0 assumed the
  scroll ran to the physical edge; the PNG disagrees (week-card face stops at
  y 810, meadow fills 810…844). Chrome now ends with
  `SizedBox(height: NestDevice.homeH)` and nothing is painted in the reserve
  (BOTTOM EDGE owner rule).
- 2b defect 2 — dashed to-do tiles laid out 6 px short because
  `NestDashedBorder` is a `CustomPaint` with no layout thickness. `kid.borderWidth`
  is now added to the tile padding, so every grid row is 150 px and the week card
  top is back at 683.
- 2b — the inherited view/widget test files did not compile; all 8 issues fixed.
- 2a — `Got it!` / `Keep going!` copy + `_switchMap` (documented deviation from
  the plan's `asyncExpand`, same public shape).

### LEFT (correctly, not an integration issue)

- **`SHARED_REQUEST.md` — seed the nine design badges.** Still open. The demo
  seed carries 8 rows using `tidy-champion` / `super-saver` / `pet-friend`
  instead of the design's `bins-out` / `biscuit-sitter` / `plant-waterer`, so
  grid rows 2–3 will show legacy names and those three ids fall back to the
  neutral `NestIcons.ribbon` art (unknown ids never borrow another badge's).
  The fix lives in `app/lib/core/data/seed.dart`, which RULES.md §1 forbids a
  screen agent from editing — it stays a shared request for the orchestrator,
  and the file itself marks it `Blocks: no` with a `TODO(K11)` behind it in
  `badges_view.dart`. Not a stage-2 integration item and not a blocker.
- **UI check not run.** Stage 5 owns it. Drift to watch, already pinned by the
  geometry tests: title 107, first cell 193, each row +162, week card 683,
  dots 700, why-line 772, meadow visible 810…844.

## Orchestrator rules re-checked on the merged tree

- `grep -rnE 'google_fonts|GoogleFonts|DateTime\.now\(' lib/features/badges
  test/features/badges` → only a comment in `badges_view_test.dart` stating the
  rule; no call sites.
- Tokens only; `KidScope` (no local hills/meadow); `NestBalancedText` on the
  `.kid-title`; DB insertion order for badges and children (never sorted);
  counts from the database, never hard-coded from the design; no simulator was
  booted by this stage; no `flutter clean`; `analysis_options` untouched.
- No files outside `app/lib/features/badges/**`, `app/test/features/badges/**`
  and `docs/screens/K11/**` were modified.

## Command tails (verbatim)

```
$ dart format .
Formatted 631 files (0 changed) in 2.05 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 5.5s)

$ flutter test --timeout 120s
...
01:51 +4360 ~10: All tests passed!

$ flutter test --timeout 120s test/features/badges
00:02 +70: All tests passed!

$ git diff --stat HEAD -- app/
(no output — nothing to fix)
```

Full suite: **4360 passed, 10 skipped, 0 failed.** Feature suite: **70 passed**
(12 repository + 14 bloc + 26 view + 18 geometry).

The only noise in the test log is the pre-existing Drift
"created the database class AppDatabase multiple times" debug warning from
`test_scope.dart`, which is unrelated to K11 and appears in other features' runs
too. No failures, no hangs, no timeouts.

VERDICT: PASS