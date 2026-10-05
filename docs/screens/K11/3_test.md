# K11 · Badges — stage 3 TEST (iteration 3)

Route `/badges` (feature `badges`, kid mode). Plan `1_plan.md` §f, orchestrator
rules, RULES §1/§7/§8/§9, mandatory `ORCHESTRATOR_NOTES.md` (02:40 seed nine —
landed; per-id art — built iteration 2; 06:55 locked-medal ink ring +
whole-element ribbon opacity — built iteration 3; K11-BUG-1 clamp +
K11-BUG-2 no-hard-coded-maya — both landed iteration 2). **No file under
`app/lib/` was edited by this stage** (a stage that finds a bug records it,
it does not patch it). Only `app/test/features/badges/**` (1 new file, 2
extended) and this note changed.

Starting point: the iteration-3 build (`c81a3c5`) — `badge_grid_cell.dart`
rebuilt the five still-to-do medals as a local `lockedMedalSvg(id)` with 8
new view tests (view file 34 → 42); the logic chunk reports no contract
changes. This stage takes the feature suite from **152 passed to 166 passed,
0 skipped, 0 failed**.

## Tests added / changed

### New — `badges_locked_art_test.dart` (10)

The iteration-3 build's new code was under-pinned: the builder's 8 view
tests pump `bins-out` only, and `badges_art_test.dart` pins "an SVG, never
the rosette" — neither would catch a SWAPPED glyph (bins-out drawing
tidy-hero's basket) or a theme-dependent string. New pins, per id and per
theme, over `pumpNest` cells (no DB needed):

- String level (2 unit tests): all five todo SVGs carry the ink ring
  (`stroke="#1E1B3A" stroke-dasharray="5 4"`), never the grey asset ring,
  the whole-element ribbon (`<path fill="#6E6A8A" stroke="#1E1B3A"` +
  `opacity=".4"`), and the cream disc (`fill="#F3EEE5"`); an unknown id
  keeps the frame with an empty glyph (no crash, no grey ring).
- Widget level (5 tests, one per locked id): the pumped cell draws
  `SvgPicture.string` with its OWN glyph marker and none of the other four
  (`M21 28h22` / `cy="42"` / `M41 33H23` / `cy="38"` / `M25 30h14`), and the
  light string EQUALS the dark string (medals keep fixed illustration
  colours in both themes).
- Earned path (3 tests): an earned todo id keeps its own grey medal for all
  five (plan §a known limitation — solid border + `Got it!` flip only, never
  the rosette); the four earned ids take the shared-asset path
  (bytesLoader is NOT `SvgStringLoader`) in both states, light and dark.

### Extended — `badges_bloc_test.dart` (+1, 17 → 18)

`a childless empty emission loads an empty shelf`: `BadgesData(childId: '',
items: [], happyDays: 0)` (the K11-BUG-2 empty resolution) loads as
`loaded` with empty child/shelf/count and no error — the bloc-level pin of
the path the view renders as the childless empty state. Every event
(`BadgesLoadRequested`, `BadgesDataReceived`, `BadgesStreamFailed`),
`close()`, and the state value semantics are now driven at both bloc and
state level with no uncovered branch.

### Extended — `badges_a11y_test.dart` (+3, 15 → 18)

New group `K11 Try again control on the failure surface` (fail-once fake,
one-badge recovery shelf): the failure surface offers exactly
{Back, Grown-ups, Try again} (walked from the semantics tree, not trusted
from the widget tree); Try again exposes `SemanticsAction.tap`, announces as
an enabled button, clears the 56 px kid floor as a widget (64 min-height
`NestKidButton`) and the 44 px parent floor as a semantics rect, and a
pointer tap reloads the real shelf (`My badges`, one cell, `One shiny one
already…`); plus the failure surface in DARK renders with working chrome
(screen-reader lock tap still pushes `/parental-gate`).

## Results (verbatim tails)

```
$ dart format test/features/badges/<3 files>   → clean (0 changed, final)
$ flutter analyze test/features/badges         → No issues found!
$ flutter test --timeout 120s test/features/badges/<10 K11 files>
  00:03 +166: All tests passed!
  (bloc 18 · copy 9 · repository 20 · view 42 · a11y 18 · art 7 ·
   matrix 22 · geometry 18 · bugs 2 · locked 10 = 166, 0 skipped, 0 failed)
$ flutter test --timeout 120s   (full suite, 2nd run)
  02:01 +5210 ~16: All tests passed!
```

The full suite's FIRST run showed two foreign failures that both cleared on
re-run with zero code changes: `k11_pixel_tmp_test.dart` (an untracked temp
experiment from a concurrent worker — appeared mid-run, vanished the same
way as iteration 2's `k11_dbg_tmp_test.dart`; read-only observation, never
edited/moved/deleted) and 4 `rewards_order_test.dart` cases (another
screen's in-progress core work settling). Process items, not findings
(orchestrator PROCESS ITEMS rule). The second run is fully green, including
all 166 K11 tests.

Every widget test ends with `disposeApp`; every DB mutation inside
`testWidgets` goes through `tester.runAsync`; every run uses
`--timeout 120s`. No hangs, no flakes in any K11 file. (The remaining
console noise is the standard Drift multi-DB debug warning the whole
harness emits — pre-existing, not a finding.)

## Bugs found

**None in the screen.** Every new test passed on its first run against the
unmodified iteration-3 build — no test exposed a defect in
`app/lib/features/badges/**`, so no screen file was opened for edit and no
`file:line` repro exists to record.

Coverage of the stage brief: light + dark pumped (view/matrix/a11y/locked
all run both themes); widths 320/390/430 × scales 1.0/1.3 (matrix 12-corner
group + geometry alignment group, no-overflow asserts); empty (wiped DB,
`Seed.empty`, childless resolution), loading (spinner + label + live
chrome), error (failure + retry reload, pointer and screen-reader driven);
every tap → right route (back go/pop branches, lock single-push guard,
Try again reload); semantics labels verbatim (`Back`, `Grown-ups`, merged
tile labels, spinner, day letters + why-line); tap targets 56 back/lock at
390/1.0 and 320/1.3 plus 64-high Try again (all clearing the 44 parent
floor), static tiles with no tap action. Counts/titles/order read from the
seeded DB (Maya-then-Leo creation order); no `DateTime.now`/`clock` reads,
no `google_fonts`, no hard-coded design numbers.

## Scope and rules

- Edited only `app/test/features/badges/**` (1 new + 2 extended files) plus
  this note (RULES §1). `app/lib/`, `core/`, `app/`, other features,
  `tools/`, `analysis_options.yaml` untouched.
- Concurrent stages' files (`k11_bugs_test.dart`, `4_review.md`, `5_ui.md`,
  `ui/*_3.png`) changed under this worktree while this stage ran — left
  alone (process items, not findings).
- No simulator was booted, installed on, screenshotted or driven by this
  stage (604697A9-11DA-462F-9837-396E9CA2493A untouched — stage 5 owns it).
- No `flutter clean`, no `pkill`/`killall`.

---

# History — stage 3 TEST (iteration 2, retained)

Route `/badges` (feature `badges`, kid mode). Plan `1_plan.md` §f, orchestrator
rules, RULES §1/§7/§8/§9, mandatory `ORCHESTRATOR_NOTES.md` (seed nine —
landed; art map — already complete; K11-BUG-1 clamp + K11-BUG-2 no-hard-coded-
maya — both built in iteration 2). **No file under `app/lib/` was edited by
this stage.** Only `app/test/features/badges/**` and the stage note changed.

Iteration 1 (120 passed) plus the iteration-2 builds were the starting point:
`2_build.md` reported the merged tree at **129 passed, 2 skipped**. Iteration 2
took it to **143 passed, 1 skipped, 0 failed** via: `badges_bloc_test.dart`
16 → 17 (nine-id fake + failure-recovery test), new `badges_copy_test.dart`
(9), `badges_view_test.dart` +2 (K11-BUG-2 widget regression), `badges_a11y_test.dart`
+1 (320/1.3 corner targets), K11-BUG-1 un-skipped (fixed) while K11-BUG-2's
widget-pattern test stayed skipped (test-infra silence, product fix proven
twice over). Full suite 4760 passed with one concurrent-worker's temp-file
failure (process item). No screen defects found. VERDICT: PASS.

VERDICT: PASS
