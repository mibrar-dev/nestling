# K11 · Badges — stage 3 TEST (iteration 2)

Route `/badges` (feature `badges`, kid mode). Plan `1_plan.md` §f, orchestrator
rules, RULES §1/§7/§8/§9, mandatory `ORCHESTRATOR_NOTES.md` (seed nine —
landed; art map — already complete; K11-BUG-1 clamp + K11-BUG-2 no-hard-coded-
maya — both built in iteration 2). **No file under `app/lib/` was edited by
this stage** (a stage that finds a bug records it, it does not patch it).
Only `app/test/features/badges/**` and this file changed.

Iteration 1 (`3_test.md` history: 120 passed) plus the iteration-2 builds are
the starting point: `2_build.md` reports the merged tree at **129 passed, 2
skipped** (the two `k11_bugs_test.dart` skips). This stage takes it to
**143 passed, 1 skipped, 0 failed**.

## Tests added / changed

### Updated — `badges_bloc_test.dart` (16 → 17)

The fake still modelled the 8-row legacy shelf
(`tidy-champion`/`super-saver`/`pet-friend`) while the landed seed and the
repository tests use the 9-row design shelf — stale ids/titles/counts pinned
by a fake that never touches the DB. The fake now serves the nine design ids
in insertion order (`bins-out`, `biscuit-sitter`, `tidy-hero`, `early-bird`,
`plant-waterer` replacing the three legacy ids), and `hasLength(8)` → 9.

New: `a data event after a failure recovers the loaded shelf` — the one
event path with no bloc-level test (`BadgesStreamFailed` then
`BadgesDataReceived` must return to loaded and drop the stale error via
`copyWithLoaded`). All three events (`BadgesLoadRequested`,
`BadgesDataReceived`, `BadgesStreamFailed`) plus `close()` and the
value semantics are now driven at both bloc and state level.

### New — `badges_copy_test.dart` (9)

Pure unit tests (no pump, no DB): `BadgesCopy.subtitle` for 0, negative, 1
(singular `one`), 2…9 (words `Two`…`Nine`), 10/12 (digit fallback); and
`HappyWeekCopy.why` for 0 (positive zero line, Children's Code std 13),
1 (singular `day`), 2…7, plus the design characters (em dash U+2014 present
with no ASCII `-`, curly ’ U+2019 with no ASCII `'`). The widget tests only
ever show the DB's own 4/3/1/0 — this file pins every remaining branch.

### Extended — `badges_view_test.dart` (+2)

New group `K11 child resolution (K11-BUG-2 widget regression)`: pump-then-
mutate via `tester.runAsync` (the pattern that keeps Drift watches live) —
nulling `activeChildId` keeps Maya's 9-cell shelf with no fallback line, and
an unknown id (`nobody`) falls back to Maya with her 4-day line. End-to-end
proof of the iteration-2 `_resolveChildId` fix through the real repository.

### Extended — `badges_a11y_test.dart` (+1)

`the kid targets stay 56 at the 320 px / 1.3 corner`: back + lock are still
exactly `NestDevice.tapKid` squares with semantics rects ≥ 44 at the
narrowest, largest-type corner (targets were previously asserted only at
390/1.0).

### Un-skipped — `k11_bugs_test.dart` (BUG-1 fixed, BUG-2 stays skipped)

- **K11-BUG-1: FIXED and un-skipped.** The iteration-2 widget clamp
  (`happy_week_card.dart`) makes the stored-8 probe pass; the test is now a
  green regression pin (header comment updated).
- **K11-BUG-2: product fix verified, widget-pattern test stays skipped.**
  Before touching the skip I ran the test un-skipped in a scratch copy:
  BUG-1 passed, BUG-2 failed at line 154 (`showedZoe || showedChildlessEmpty`
  is false). A diagnostic probe (deleted afterwards) showed the screen sits
  on the perpetual spinner with zero cells — raw Drift watches never emit
  when the writes happen before the first pump (FakeAsync zone), exactly the
  infra silence `2a_build_logic.md` proved with its pre-fix control run
  (fails identically against the ORIGINAL `?? 'maya'` code, so the pattern
  cannot distinguish the fix). The fix itself is proven twice over: the five
  `child resolution` repository tests and the two new widget regression tests
  above. The skip reason in the file now says this.

## Results (verbatim tails)

```
$ dart format test/features/badges lib/features/badges
Formatted 24 files (0 changed) in 0.06 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 3.4s)

$ flutter test --timeout 120s test/features/badges/<each file>
bloc 17/0/0 · copy 9/0/0 · repository 20/0/0 · view 34/0/0 · a11y 15/0/0 ·
art 7/0/0 · matrix 22/0/0 · geometry 18/0/0 · bugs 1 passed / 1 skipped / 0 failed
= 143 passed, 1 skipped, 0 failed

$ flutter test --timeout 120s   (full suite)
03:18 +4760 ~14 -1: the single failure is k11_dbg_tmp_test.dart D1/D2 —
a concurrent worker's untracked TEMP experiment (appeared mid-run; its
predecessor k11_exp2_tmp_test.dart vanished the same way). Every other file
— all 4760 tests, including every K11 file — passes. Process item, not a
finding (orchestrator PROCESS ITEMS rule).
```

Every widget test ends with `disposeApp`; every DB mutation inside
`testWidgets` goes through `tester.runAsync`; every run uses
`--timeout 120s`. No hangs, no flakes across the whole matrix.

## Bugs found

**None in the screen.** No test added or un-skipped in this stage exposed a
defect in `app/lib/features/badges/**`; no screen file was opened for edit.

The retained K11-BUG-2 skip is test-infra silence in one write-then-pump
pattern (evidence above + `2a_build_logic.md` control run), not a product
defect: the repository resolves Zoe/null/empty correctly and the live screen
resolves null/unknown ids to the first child.

## Scope and rules

- Edited only `app/test/features/badges/**` (5 files) plus this note and one
  new test file (RULES §1). `app/lib/`, `app/core/`, `app/app/`, other
  features, `tools/`, `analysis_options.yaml` untouched.
- No simulator was booted, installed on, screenshotted or driven by this
  stage (604697A9-11DA-462F-9837-396E9CA2493A untouched — stage 5 owns it).
- No `flutter clean`, no `pkill`/`killall` (a stray
  `k11_*_tmp_test.dart` from a concurrent worker was left alone — read-only
  observation, never edited, moved or deleted).
- No `DateTime.now()` / `clock` reads (one fixed `DateTime.utc(2026,…)` seed
  timestamp in `badges_view_test.dart` only), no `google_fonts` (comment
  mentions only), no hard-coded design numbers — counts, titles and order are
  read from the seeded database; children listed Maya-then-Leo (creation
  order, never alphabetical).
- Tap targets: back/lock 56 px (kid floor) clearing the 44 px parent floor,
  proved at 390/1.0 and 320/1.3; badge cells static with merged labels and no
  tap action; `SemanticsAction.tap` + `performAction` drive real navigation
  on back, lock and `Try again`.

VERDICT: PASS
