# K11 · Badges — stage 2b build, UI chunk (iteration 2)

> Iteration 2 addendum (this section only; iteration 1 notes follow unchanged).
>
> Scope: `app/lib/features/badges/presentation/views/**` +
> `presentation/widgets/**` and the view/widget tests only. No domain / data /
> bloc file touched (the logic builder owns those in parallel in this worktree;
> re-read `2a_build_logic.md` — no contract changes, so the view still codes
> against `1_plan.md` as written). No `docs/screens/K11/FIXES_1.md` exists for
> this screen, so there are no FIXES items; iteration-2 UI work is driven by the
> mandatory `ORCHESTRATOR_NOTES.md` items plus the seed landing on main.
>
> ## Changes
>
> - **K11-BUG-1 fixed (UI chunk, orchestrator-mandatory):**
>   `happy_week_card.dart` now clamps once —
>   `final days = happyDays.clamp(0, 7)` at the top of `build` (dots use
>   `i < days`, why-line uses `HappyWeekCopy.why(days)`) — and `HappyWeekCopy.why`
>   clamps its own input too (review finding 4 pattern: clamp at both `build`
>   and `why`). A stored 8 fills seven dots and reads “7 happy days…”, never an
>   impossible “8 happy days”; a negative reads the zero line with no dots.
> - **`TODO(K11)` removed (`badges_view.dart`):** the orchestrator's
>   `shared/k11_badges_seed` has landed — the seed now carries the design's nine
>   badges in order with Maya's earned set unchanged — so the note requires its
>   removal. The grid still renders whatever the DB returns in DB order.
> - **Badge art (orchestrator-mandatory):** unchanged code — `_artFor` already
>   maps all nine design ids to their own `badge*` medal in both earned and
>   locked states, light and dark, with the rosette fallback only for unknown
>   ids. No edit needed.
> - **K11-BUG-2 (`?? 'maya'` fallback): NOT touched** — it lives in
>   `data/badges_repository_impl.dart`, owned by the parallel logic builder.
> - **Tests (my files only):** `badges_widget_geometry_test.dart` 8→9 cells at
>   320/1.3 plus stale-comment refresh (full third row; the short-row branch now
>   pins the contract for a future odd shelf); `badges_view_test.dart` header
>   comment refreshed + new `K11 happy-day clamp (K11-BUG-1 regression)` group
>   with 3 tests (stored-8 widget probe mirroring the skipped `k11_bugs_test`,
>   negative-count probe, `HappyWeekCopy.why` clamp unit). `k11_bugs_test.dart`
>   itself is outside this chunk's files (name contains neither `view` nor
>   `widget`) and was left skipped for the bugs stage to un-skip; the new
>   regression group proves the fix now.
>
> ## Verification (iteration 2)
>
> ```
> flutter analyze lib/features/badges test/features/badges → 1 pre-existing
>   warning in the logic builder's in-progress badges_repository_test.dart
>   (unused `clearActiveChild`); zero issues in this chunk's files.
> flutter test --timeout 120s test/features/badges/badges_view_test.dart
>   test/features/badges/badges_widget_geometry_test.dart → 50/50 passed
>   (32 view incl. 3 new clamp tests + 18 geometry)
> dart format (presentation + own tests) → 0 changed
> grep google_fonts|GoogleFonts|DateTime.now (own scope) → comment mention only
> ```
>
> No simulator booted (stage 5 owns it). No whole-app suite run. With nine rows
> the geometry still lands exactly (R1 193 / R2 355 / R3 517, week 683 — pinned
> by the passing geometry tests), so the UI check should now match the design
> tile-for-tile outside DB chrome.
>
> ## LEFT FOR NEXT ITERATION
>
> - Logic-layer tests (`badges_repository_test.dart`, `badges_bloc_test.dart`)
>   still hard-code the 8 legacy rows (`tidy-champion`/`super-saver`/`pet-friend`)
>   and belong to the parallel logic builder — verify they go green with the
>   nine-badge seed before the merge.
> - Un-skip K11-BUG-1 in `k11_bugs_test.dart` (bugs stage) now that the widget
>   clamp lands; K11-BUG-2 un-skip waits on the logic fix.
>
> ---

# K11 · Badges — stage 2b build, UI chunk (iteration 1)

Scope: `app/lib/features/badges/presentation/views/**` +
`presentation/widgets/**`, and the feature's view/widget tests
(`app/test/features/badges/badges_view_test.dart`,
`badges_widget_geometry_test.dart`). No domain / data / bloc file touched by
this stage (the logic builder owns those; re-read `2a_build_logic.md` — it
reports **no contract changes**, so the view codes against `1_plan.md` as
written).

Design sources: `design/html-source/screens/K11-badges.html` +
`design/screens/light|dark/K11-badges.png` (read with the file reader; pixels
÷3). Every number below was measured with a PIL scan over the PNG, not
eyeballed.

## Files

- `app/lib/features/badges/presentation/views/badges_view.dart` — chrome
  (`KidScope` + transparent `Scaffold` + `NestStatusBar` + `.krow-top` +
  home-indicator reserve), `BadgesCopy` (design copy, characters transcribed),
  back/lock, `BlocBuilder` states (loading / failure / empty / list), the
  `ListView` and the 3-column `_BadgeGrid` (`IntrinsicHeight` + `stretch`,
  `Expanded` cells, inert `SizedBox.shrink` tail filler).
- `app/lib/features/badges/presentation/widgets/badge_grid_cell.dart` — the
  `.k11-b` tile: `artFor(id)` map over `NestlingIllustrations.badge*`, 60×60
  SVG (`ExcludeSemantics`), name box (`min-height 38`, 2 lines), sub
  (`Got it!` leaf-ink / `Keep going!` ink-2), earned = solid 3 px ink border +
  `kidShadow`, todo = `NestDashedBorder` ink-2 and no shadow. One merged
  `Semantics` label `"<name>, <detail>"`, no tap action (static card — no
  detail route exists in the nav map, `1_plan.md` §c).
- `app/lib/features/badges/presentation/widgets/happy_week_card.dart` — the
  `.k11-week` card: 7 `LayoutBuilder`-sized dots (`min(38, (w−24)/7)`) with
  the first `happyDays` filled leaf + on-leaf check and the rest surface +
  ink-2 ring, `M T W T F S S` letters, centred `.kcap` why-line.
- `app/test/features/badges/badges_view_test.dart` (26 tests),
  `app/test/features/badges/badges_widget_geometry_test.dart` (18 tests).

## Design verification (measured, light PNG ÷3)

| Element | Design | App (asserted ±2 px) |
|---|---|---|
| status reserve | 47 | 47 |
| back box / lock box | x 20…76 & 314…370, y 47…103 | exact `Rect` match |
| title line box | 107…141 | 107, h 34 |
| subtitle line | 157…177 | 157, h 20 |
| grid row 1 / 2 / 3 | 193 / 355 / 517, h 150 each | 193 / 355 / 517, h 150 |
| grid columns | 108.67, 12 gap, 20 gutters | same, derived from width |
| medal | 60×60 at y 206 | 60×60, y 206 |
| name box / sub | 38 / 18 | 38 / 18 |
| week card | x 20…370, y 683…829, h 146 | same |
| week dots / letters | 38 at y 700 / 18 at y 742 | same |
| why-line | y 772, 2 × 20, centred | same |

## Two defects found and fixed this iteration

1. **Home-indicator reserve missing (`badges_view.dart`).** `1_plan.md` §0
   assumed the scroll ran to the physical edge ("content ends 861 > 844, 17 px
   scroll"). The PNG disagrees: the week card's white face stops at **y 810**
   and meadow fills 810…844, with the OS home pill over it —
   the HTML's `.home-indicator { height: 34px }` (`K11-badges.html:138`,
   `components.css:51`) is the last flex child, so the scroll viewport is
   107…810. The chrome now ends with `SizedBox(height: NestDevice.homeH)`
   (`NestHomeIndicator` paints nothing in the app — it is the gallery mock),
   K03 profile-picker / kid-PIN precedent. Nothing is painted in the reserve:
   BOTTOM EDGE owner rule — the meadow runs to the edge.
2. **Dashed tiles were 6 px short (`badge_grid_cell.dart`).** Flutter has no
   dashed `BorderSide`; `NestDashedBorder` is a `CustomPaint` with no layout
   thickness, so a still-to-do tile laid out 144 px tall against the earned
   tile's 150 and pulled the whole week card 6 px up (dots at 694, why-line at
   766 instead of 700/772). CSS paints the dashed border inside the border
   box, so the stroke's `kid.borderWidth` is now added to the tile's padding.
   All rows are 150 and the week card top is back at 683.

## Test fixes (the two files did not compile)

`flutter analyze test/features/badges` reported 8 issues in the inherited view/
widget test files; all fixed, `flutter analyze` now reports **No issues
found** for `lib/features/badges test/features/badges`:

- `_FakeBadgesRepository.childId` was an optional constructor parameter no
  caller ever passed → now a fixed field.
- `_shelfRows` returned `Future<List<Badges>>`, but `Badges` is the Drift
  *table* class (hence `row.title` being a `TextColumn`) → `Future<List<Badge>>`
  with Material's `Badge` widget hidden from the import.
- `GoRouter.push('/badges')` unawaited → `unawaited(...)` + `dart:async`.
- Geometry test's unused `db` / `math_min` naming.

Test-content fixes:

- The column test indexed `cell(index + 2)` on rows the demo shelf does not
  fill (8 rows, not the design's 9) → RangeError. Now iterates whole rows and
  asserts the trailing short row keeps the column width and the 12 gap.
- `expect(rect.size, Size.square(60))` failed on `60.00000000000001` (the
  108.67 column width carries a float tail) → per-axis `closeTo`.
- "fits 320 px at text scale 1.3" asserted the week card was built; at that
  corner it sits below the fold and the `ListView` builds lazily → the test now
  scrolls it into view and checks its gutters there.

Plan §f item 5 (`badges_a11y_test.dart`) has **no separate file**: the a11y
assertions live in `badges_view_test.dart` (merged tile labels + no tap action,
`hasAction(SemanticsAction.tap)` on Back and the lock, `performAction` driving
real navigation, the spinner's `Loading badges` label). Filename scoping
(`view`/`widget`) kept them in my chunk.

## Rules honoured

- Tokens only — no hard-coded colours or sizes; the two file-local constants
  that exist are the design's own 26 px back chevron (`_backIconSize`, K08
  precedent) and the CSS-derived type metrics the tokens do not carry (15/19,
  14/18, 38 min-height, 60 medal) with the HTML line cited.
- `KidScope` only — no local hills/meadow; `NestBalancedText` on the
  `.kid-title`; `NestChipWrap` N/A; no `google_fonts`; no `DateTime.now` in the
  view; `newId` N/A; kid glyphs only.
- Copy compared character-by-character with the HTML: `My badges`,
  `Four shiny ones already. Pip is very impressed.`, `Got it!`, `Keep going!`,
  `4 happy days this week — Pip hasn’t stopped singing.` (em dash U+2014,
  curly U+2019). Counts come from the database, never from the design.
- Child order = DB insertion order (no alphabetical sorting).
- Tests: `disposeApp` after every pump, `--timeout 120s`, no simulator, no
  `flutter clean`, no whole-app suite run.

## Verification run

```
flutter analyze lib/features/badges test/features/badges   → No issues found!
flutter test --timeout 120s test/features/badges/badges_view_test.dart test/features/badges/badges_widget_geometry_test.dart → 44/44 passed
dart format (presentation + view/widget tests)               → clean
grep google_fonts|GoogleFonts|DateTime.now (own scope)       → clean (comment mentions only)
```

No simulator was booted (stage 5 owns that). No domain/data/bloc/core file
touched.

## LEFT FOR NEXT ITERATION

- `1_plan.md` §g `SHARED_REQUEST.md` is filed and still open: the demo seed
  carries 8 shelf rows (`tidy-champion` / `super-saver` / `pet-friend`)
  instead of the design's `bins-out` / `biscuit-sitter` / `tidy-hero` /
  `plant-waterer`, so row 2 and row 3 of the screenshot will show the legacy
  names and fall back to the neutral `NestIcons.ribbon` art for
  `tidy-champion` / `super-saver` / `pet-friend` (the design's five to-do
  medals have art; unknown ids never borrow another badge's). The grid, the
  earned set and every measured geometry above are already correct. A
  `TODO(K11)` marks the spot.
- A UI check has not been run yet (stage 5). Predicted drift to watch, all
  now pinned by geometry tests: title 107, first cell 193, each row +162, week
  card 683, dots 700, why-line 772, and the meadow visible 810…844.

VERDICT: PASS
