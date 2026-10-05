# K05 Quest complete — Stage 2 integrate (iteration 2)

Route `/quest-complete` (`KidHomeRoutePaths.complete`), feature `kid_home`,
kid mode, light + dark. Scope of this stage: make the merged 2a + 2b result
compile and pass. **No code change was required** — see "Integration result"
below. No simulator was booted, installed on or driven (only `5_ui` may use one).

## What arrived

### 2a — logic (`2a_build_logic.md`)

Contract, unchanged since iteration 1:

- `KidChild.pipTotalCoins` is **defaulted (`= 0`)**, not `required` — a
  required field would break the 15 pre-existing `KidChild(` fixtures, most of
  them owned by the UI builder. The repository always maps the real DB value.
- Growth helpers live in a new **domain** file
  `domain/entities/kid_growth.dart` (`kidPipCoinsRemaining`,
  `kidPipGrowthFraction`, `kidPipGrowthCopy`, `kidPipGrowthCount`). No clock, no
  widgets, threshold from the canonical `PipProfile.evolveAtCoins` (250) via
  import. `1 more coin` singular, `remaining == 0` → `Pip is ready to grow!`,
  fraction clamped `0.0..1.0`.
- **No BLoC event/state shape change.** `copyWithLoaded` already carries the
  `KidChild`, so `pipTotalCoins` flows through untouched. Route/DI unchanged.
- Files: `kid_child.dart`, new `kid_growth.dart`, `kid_home_repository_impl.dart`
  (`_toChild` maps `row.pipTotalCoins`), `kid_home_bloc_test.dart`,
  `kid_home_repository_test.dart` (DB truth Maya 175 / Leo 60, creation order).
- 2a re-ran twice this iteration (FIXES_1.md empty both times) and changed no
  file — the iteration-1 contract stands.

### 2b — UI (`2b_build_ui.md`)

- Verified the already-committed UI layer against `1_plan.md`, the HTML source
  and the stage-5 measured rects rather than rewriting it; confirmed all four
  `6_bugs.md` fixes are in code and no longer `skip:`-ed.
- **Review finding 9** — added `buildWhen: (p, c) => p.status != c.status ||
  p.child != c.child || p.items != c.items` to the `BlocBuilder` in
  `quest_complete_view.dart`. The screen draws only `status`, `child` and
  `items`; the K01 roster (`profiles`), K02 PIN one-shots and the K03 SnackBar
  channel (`actionError`, `justCompleted*`) belong to other routes and used to
  rebuild the 218 px Pip, the burst plate and the growth card on every emission.
  New regression proof in `quest_complete_view_test.dart` (group *rebuild
  scope*): a fake repository serves the roster from a `StreamController` so a
  genuinely different roster (`_maya` + `_leo`, creation order) arrives **after**
  the first frame, and the built `PipAvatar`/`NestProgress` widgets must be
  `identical` before and after. Fails with `buildWhen` stripped.
- **Review finding 6** — `quest_complete_geometry_test.dart` matched hard-coded
  `0xFFFFFFFF` / `0xFFEEEBFF`, so a token flip would make both finders match
  **nothing** while the tests still "passed" on `.first` of nothing. Both now
  resolve the live `NestTokens` through `Theme.of(...).extension<NestTokens>()!`.
- **Review finding 7** — the bar-height assertion
  `3 + 12 + 64 + 10 + NestDevice.homeH - 34` reduces to `89` and read as if the
  34 px inset were still added. Now `expect(…, 89, reason: …)` with the reason
  spelled out (border 3 + pad 12 + button 64 + 6 px shadow room + pad 4; the
  real inset arrives via `SafeArea` **inside** the surface box).
- Files: 1 view + 2 K05 test files. Nothing else.

## Integration result — no breakage found, no edits made

The two halves merged cleanly: **no mismatched BLoC states/events, no import
breakage, no renamed members, no merge-induced test failures.** The UI builder
had already compiled against the exact iteration-1 contract 2a re-confirmed
(`pipTotalCoins` defaulted, helpers at `domain/entities/kid_growth.dart`),
because both halves ran in this one worktree against the same tree.

Changes made by this stage: **none** (0 files under `app/`). This note is the
only file written.

Verification of that claim: `dart format .` reported 0 files changed, and
`flutter analyze` + the full suite were both clean on arrival, before any edit.

## FIXES items

`docs/screens/K05/FIXES_1.md` has **no items** in either section ("From
2_build.md", "From 3_test.md") — for the third iteration running. So there was
no mandated fix list to work through.

## ORCHESTRATOR_NOTES.md (mandatory) — verified done

The 19:45 note has two items:

1. **main (K04) merged into this branch** — the tree builds and the whole
   suite passes on top of it, including the two K03 screens.
2. **K03 `k03_bugs_test.dart` "back from the celebration returns to the home
   with the card flipped"** — allowed to be updated to drive K05's real control.
   It is done and not skipped: `k03_bugs_test.dart:547` taps the real
   `Mark done` check, asserts `pushedPath(tester) == '/quest-complete'`, then
   leaves via `_leaveCelebration` and asserts `find.text('Hi Maya!')` and
   `findsNWidgets(3)` on `'Waiting for Mum'` — real pushedPath/currentPath, no
   placeholder text. Run in isolation:
   `00:00 +1: All tests passed!`

The note's "Pass 1 build/test failed only because Space Bunny returned empty
runs" is why this stage was redone properly; the redo is this document plus the
three green commands below.

## Owner-rule re-check (integration scope)

- **PIP** — both `PipAvatar`s built from the active child's own row
  (`pipStyleOf`/`pipSkinOf`/`pipAccessoryOf` + `pipStage.clamp(1,4)`); no
  `pip_stage_*.svg` in product code (the only matches in the feature are two
  explanatory comments).
- **STATUS BAR** — `NestStatusBar` reserves 47; nothing asserted about glyphs.
- **BOTTOM EDGE** — bar surface runs to the physical edge (geometry asserts
  `bottom == 844`, `left 0`, `right 390`); `SafeArea` sits inside the box.
- **ALIGNMENT** — 20 px gutters pinned (card x 20…370, CTA x 20…370) and held
  at 320 px width.
- **ACCESSIBILITY** — the three `excludeSemantics: true` nodes are
  non-interactive (loading spinner label, Pip image label, card text label), so
  they need no `onTap`. The four interactive controls are design-system buttons
  carrying their own actions: celebration CTA (`:251`), picker CTA (`:295`),
  retry CTA (`:492`), `NestLockButton` (`:698`). Tap + `performAction(tap)`
  proofs run green.
- **BALANCED HEADINGS** — `NestBalancedText` on the `.kid-hero` title (`:436`).
- **LETTER SPACING** — no tracking added anywhere on this screen.
- **FONTS / CLOCK / IDS / AVATAR INITIALS** — no `google_fonts` import or
  `GoogleFonts.*` call in the feature; the only `DateTime.now()` match in
  `kid_home/` is a comment saying it is never called; no new ids; no `name[0]`.
- **KID BACKGROUND** — shared `KidScope`/`kid_meadow.dart` sky + hills; no
  local meadow or hills painted.
- **CHILD ORDER** — creation order (Maya, then Leo) in the repository test and
  in 2b's new roster-rebuild fixture.
- **Simulators** — none booted, installed on, screenshotted or driven.
- **No global kills** — no `pkill`/`killall`; every run bounded by
  `--timeout 120s` and foreground.

## Command tails

`dart format .`

```
Formatted 629 files (0 changed) in 4.35 seconds.
```

`flutter analyze`

```
Analyzing app...
No issues found! (ran in 19.0s)
```

`flutter test --timeout 120s` (full suite)

```
02:35 +4344 ~10: All tests passed!
```

K05 + the K03 file the orchestrator note covers, together:

```
00:04 +108 ~2: All tests passed!
```

K03 back-from-celebration probe alone:

```
00:00 +1: All tests passed!
```

### On the `~10`

Ten tests are skipped suite-wide. Three of them live in `kid_home`
(`k01_bugs_test.dart:569`, `k03_bugs_test.dart:1685`, `k03_bugs_test.dart:1753`)
and all three are pre-existing, belong to the K01/K03 screens, and are
unrelated to K05 (a swallowed-tap feedback probe, a shared `_explicitBleed`
request-order probe, and a nest-bowl height probe).
`k05_bugs_test.dart` contains **no** `skip:` — the five K05 bug proofs all run.
Iteration 1's red build/test was an empty-run artefact, not these.

## LEFT FOR NEXT ITERATION

Unchanged from what the two builders handed over; all are minor and none block
this stage:

- Review finding 1 — deep-link (no `extra`) coin fallback quotes the first
  `done_pending`/`approved` quest in **title** order rather than the newest
  completion. Needs `KidHomeRepository` (the logic builder's file). Both
  builders agree it is deliberate: it is the DB-driven replacement for the
  design's hard-coded `+15`.
- Review finding 2 — `kid_growth.dart` under `domain/entities/` is the
  codebase's only cross-feature domain import (precedent:
  `domain/next_payout.dart`). Moving it is a contract change for both builders
  **and** for `kid_home_repository_test.dart`, so it belongs in an orchestrator
  batch, not a parallel iteration.
- Review finding 5 — extract `KidLoadingState` / `KidFailureState` /
  `KidNoChildState` / `GateLockButton` from the four kid views; batch after all
  six `kid_home` screens merge.
- Review finding 6, second half — the two shape finders still exist twice
  (geometry test + view test); unifying them was judged not worth the churn
  while both files are settling.
- K06's `PipGrowthCard` shares the old `.round()` percentage that K05-BUG-2
  floored here — cross-screen consistency for the orchestrator.
- `quest_complete_geometry_test.dart` has no `view`/`widget` in its filename,
  so 2b edited it slightly outside its literal named test set (it is the
  geometry proof for the view it owns). Noted, no revert needed.

## Stage 3 / 5 handoff

The tree is clean and green: analyze reports **No issues found!**, the full
suite passes (**4344**, 10 pre-existing skips, 0 failures), and `dart format`
changes nothing. Stage 3 can take the suite as its baseline, and `5_ui` may use
simulator `604697A9-11DA-462F-9837-396E9CA2493A` for the ±2 px light + dark
table.

VERDICT: PASS
