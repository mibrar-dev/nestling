# 2 BUILD (INTEGRATE) — K03b Kid home all done (iteration 1)

## Result

`dart format` clean, `flutter analyze` → **No issues found!**, full suite
`flutter test --timeout 120s` → **All tests passed!** (4395 passed, 12 skipped).
No integration edits were required — the two halves merged without conflict.

## Summary of the two halves

### 2a (logic) — `2a_build_logic.md`, VERDICT: FAIL (investigation only, 0 files changed)

Investigation-only pass. It read the state/bloc/event/repository/route/DI chain and
concluded, correctly, that the logic surface is exactly one pure getter plus the
`/kid-home-done` route alias — no new events, no new states, no repository change
(period-scoped statuses already live in `KidHomeRepositoryImpl._watchItemsFor` via
`countsForCurrentPeriod`, per the PERIODS ruling). It deliberately left the three
items on its "LEFT FOR NEXT ITERATION" list to the UI builder/integrator to avoid a
parallel-edit conflict on the same files. All three landed as intended (below).

### 2b (UI) — `2b_build_ui.md`, VERDICT: PASS

Implemented the whole all-done state inside the shared `KidHomeView` (per
`ORCHESTRATOR_NOTES` §4 "ONE kid home"):

- `presentation/bloc/kid_home_state.dart` — `bool get allDone => totalCount > 0 && doneCount == totalCount;`
  (the single logic addition 2a proposed; pure getter, no `copyWith` change).
- `presentation/views/kid_home_view.dart`
  - header sub-line: `All done!` in `tokens.leafInk` (was `$done done today` / `ink2`);
    semantics label `Hi $nickname, all done!`.
  - `_AllDoneBody`: centred `NestSpeechBubble` "You did everything today! Pip is so
    proud.", `gap14`, `NestPetStage` (nest 236×188, fixedPip 152, `slotHeight: 226`)
    with the child's own `PipAvatar` (`pipStyleOf/pipSkinOf/pipAccessoryOf` from the
    child row, stage clamped 1..4, `PipMood.happy`) rotated −7°, confetti plate
    (`SvgPicture.asset(NestlingIllustrations.confetti)`, 320×250, `FittedBox.scaleDown`,
    `top: 4`, `IgnorePointer` + `ExcludeSemantics`), section row (`NestBalancedText`
    "Today's quests" + `KidStatusChip` "$done of $total done"), `NestProgress(kid: true)`
    at `state.fraction`, then the unchanged `_QuestCard` list.
  - `_AllDoneBar` replaces the 3-button dock when all done: surface Container,
    3 px `ink` top border, `SafeArea(top: false)`, one lilac `NestKidButton`
    "Visit Pip" with the `check` glyph → `context.go(PipRoutePaths.nest)`, and
    `NestHomeIndicator` INSIDE the surface (BOTTOM EDGE owner rule).
  - not-done branch: byte-identical to K03 (dock, hearts row, `_KidPetStage`,
    section row, progress, cards) — re-indented under the `if (state.allDone)` ternary,
    no behaviour or geometry change.
- `kid_home_routes.dart` — `kidHomeDoneRoute` now builds `const KidHomeView()` with the
  same `BlocProvider(... KidHomeLoadRequested ...)` as `kidHomeRoute`; path/name constants
  untouched.
- deleted `presentation/views/kid_home_done_view.dart` (placeholder AppBar
  "K03b Kid home done"); its barrel export in `kid_home.dart` and its import in
  `kid_home_routes.dart` removed.
- new `test/features/kid_home/k03b_all_done_view_test.dart` — 3 `allDone` truth-table
  tests + 5 widget tests (all-done branch, K03 branch untouched, `SemanticsAction.tap`
  on Visit Pip, 320-wide + textScale 1.3 no overflow, `/kid-home-done` renders
  `KidHomeView`).

The only cross-half hazard was the `PipMood` name living in both the design-system barrel
and `motion/pip_avatar.dart`; 2b resolved it with
`import '.../design_system.dart' hide PipMood` — the same resolution the K05 view already
uses, so no shared file needed touching.

## FIXES items

2a "LEFT FOR NEXT ITERATION" list — all three DONE (by 2b, verified here):

| # | Item | Status |
|---|---|---|
| 1 | `allDone` getter on `KidHomeState` | DONE — `kid_home_state.dart:94`, pure getter next to `fraction` |
| 2 | `kidHomeDoneRoute` builder → `KidHomeView`, unused placeholder import dropped | DONE — `kid_home_routes.dart:73` |
| 3 | State-level unit tests (empty → false, partial 4/6 → false, all done → true, `to_do` present → false) | DONE — `k03b_all_done_view_test.dart:105-138` (`to_do` present is the partial case) |

2b "LEFT FOR NEXT ITERATION" — still open, correctly not a stage-2 item:

- `SEED=kid_all_done` is still absent from `app/lib/core/data/seed.dart` on this branch
  (`grep kid_all_done seed.dart` → no match). It is orchestrator-owned
  (`shared/kid_all_done_seed`, to be merged to `main`; the loop merges main before each
  build) and RULES §1 forbids this branch editing `core/**`. Widget tests build the
  all-done state from a fake repository, so nothing in stage 2 depends on it; the UI-check
  stage (5_ui) owns the wait and must pass `kid_all_done` as `shot.sh` 6th arg.

Integration fixes applied by this stage: **none were needed.** Nothing was renamed, no
import broke, no BLoC state/event mismatch survived the merge (2a changed no contracts),
and no test regressed.

## Verification (run in `app/`)

```
$ dart format --output=none --set-exit-if-changed .
Formatted 631 files (0 changed) in 2.57 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 6.1s)

$ flutter test --timeout 120s -j 4
03:45 +4395 ~12: All tests passed!

$ flutter test --timeout 120s -j 4 test/features/kid_home
00:29 +659 ~5: All tests passed!
```

(`~12` / `~5` are pre-existing `skip:`-marked tests, not failures. The Drift
"database was opened a second time" debug warning in the log is the known
`setUpTestScope` notice, not an error.)

## Compliance spot-checks

- Files touched are all inside RULES §1 (`app/lib/features/kid_home/**`,
  `app/test/features/kid_home/**`, `docs/screens/K03b/**`) — `git status --porcelain`
  filtered outside those paths returns nothing.
- Copy character-checked against `design/html-source/screens/K03b-kid-home-done.html`:
  "All done!" (l.43), "You did everything today! Pip is so proud." (l.49),
  "Today's quests" (l.76, ASCII apostrophe — identical to the K03 string it reuses),
  "Visit Pip" (l.108), check glyph `m5 12.5 4.5 4.5L19 7` → `NestIcon(NestIcons.check)`.
- Bar geometry vs `.kid-bar { padding: 12px 20px 10px }` (l.14) and `.btn-kid
  min-height: 64px` (components.css l.88): the code uses
  `EdgeInsets.fromLTRB(padSide, s3, padSide, s1)` = 20/12/20/4 per 1_plan §a
  (10 − 6 button-shadow room, the K05-measured precedent) and the
  `NestKidButton` default `minHeight: 64`. Vertical fit inside the bar is a stage-5
  measurement, not decided here.
- Confetti art follows the K05 precedent exactly (`SvgPicture.asset` +
  `NestlingIllustrations.*` + `placeholderBuilder: SizedBox.shrink`); the asset
  `assets/illustrations/confetti.svg` exists and `assets/illustrations/` is declared in
  `pubspec.yaml:81`.
- No `google_fonts`, no `DateTime.now()`, no hard-coded colours/sizes outside
  `NestSpacing`/`NestType`/tokens, no `pkill`, no `flutter clean`, no simulator booted.

VERDICT: PASS