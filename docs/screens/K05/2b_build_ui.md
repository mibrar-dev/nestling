# K05 Quest complete — 2b build UI (iteration 2, second pass)

Screen: `/quest-complete` (`KidHomeRoutePaths.complete`), kid mode, light +
dark. Scope: `app/lib/features/kid_home/presentation/views/**` and
`presentation/widgets/**`, plus the K05 view/geometry tests in
`app/test/features/kid_home/`. No simulator was booted, installed on or
driven (only `5_ui` may use a simulator).

## State on arrival

`FIXES_1.md` is empty again (both "From 2_build.md" and "From 3_test.md"
sections have no items), and the UI layer was already built and committed:
the earlier iteration-2 pass had landed K05-BUG-1…4, review findings 3/4/8 and
the `ORCHESTRATOR_NOTES.md` 19:45 `k03_bugs_test` remedy. I re-read
`1_plan.md`, `2a_build_logic.md` (no CONTRACT CHANGES — the logic builder
re-ran and confirmed the iteration-1 contract: `pipTotalCoins` defaulted,
growth helpers in `domain/entities/kid_growth.dart`), `4_review.md`,
`5_ui.md`, `6_bugs.md` and the HTML source, then **verified** that layer
rather than rewriting it:

- `quest_complete_view.dart` already matches the HTML structure and the
  measured design rects (stage 5: title y 349, lock y 48, pill y 403, card
  y 535…694, bar top y 721, all ±0/±1 of the design PNG ÷3).
- All four `6_bugs.md` findings are fixed in code and **no longer skipped**
  (`grep skip: k05_bugs_test.dart` → none).

## What I changed this pass

Three Stage 4 minors that were still open and sit in my file set. Nothing
else moved: no copy, no geometry, no colour, no component swap.

### Review finding 9 — a rebuild on every emission (perf, now pinned by a test)
`app/lib/features/kid_home/presentation/views/quest_complete_view.dart`
`BlocBuilder<KidHomeBloc, KidHomeState>` had no `buildWhen`, so **any** state
emission rebuilt the 218 px `PipAvatar`, the burst plate and the growth card.
This screen draws only three fields of that shared state — `status`, `child`
and `items` — while the K01 roster (`profiles`), the K02 PIN one-shots and
the K03 SnackBar channel (`actionError`, `justCompleted*`) belong to other
routes. Added
`buildWhen: (p, c) => p.status != c.status || p.child != c.child || p.items != c.items`,
with a comment saying why. No rendered output changes: a state that differs
only in a non-drawn field produced an identical tree.

**New proof** — `quest_complete_view_test.dart`, group *rebuild scope*,
`a roster-only emission does not rebuild the celebration`: a fake repository
serves the roster from a `StreamController` the test drives, so a second,
genuinely different roster (`_maya` + `_leo`, creation order) arrives **after**
the first frame; the built `PipAvatar` and `NestProgress` widgets must be
`identical` before and after (a rebuild constructs new widget instances), and
the celebration must still be fully on screen.

- with `buildWhen` → passes;
- with `buildWhen` stripped again (I re-ran the probe) → **fails**,
  `Expected: true / Actual: <false>` — so it is a real regression proof, not a
  tautology. My first version of the test served both rosters from a
  `fromIterable` stream, which emitted before the first frame; it passed with
  and without `buildWhen`, which is why the fake now waits for the test.

### Review finding 6 — geometry test matched hard-coded colours
`app/test/features/kid_home/quest_complete_geometry_test.dart`
`_barSurface()` matched `0xFFFFFFFF` and `_growthCardSurface()` matched
`0xFFEEEBFF` as literals: a token change would have made both finders match
**nothing** while the tests still "passed" on `.first` of nothing, and they
could not be reused for dark geometry. Both now resolve the live
`NestTokens` (`Theme.of(tester.element(find.byType(NestProgress))).extension<NestTokens>()!`),
exactly as `quest_complete_view_test.dart` already did — a token flip now
fails loudly instead of silently.

### Review finding 7 — dead arithmetic in the bar-height assertion
`expect(barSurface.height, 3 + 12 + 64 + 10 + NestDevice.homeH - 34)` reduces
to `89` (`homeH` is 34) and read as if the 34 px device inset were still
added, which it is not in this test surface. Now `expect(…, 89, reason: …)`
with the reason spelled out: border 3 + pad 12 + button 64 + its 6 px shadow
room + pad 4, and the real inset arrives via `SafeArea` **inside** the surface
box (the owner bottom-edge rule).

## Verification

- `flutter analyze lib/features/kid_home test/features/kid_home` →
  **No issues found.**
- `flutter test --timeout 120s quest_complete_view_test
  quest_complete_geometry_test k05_bugs_test k03_bugs_test
  kid_home_view_test` → **All tests passed (196, 2 pre-existing K03 skips)**,
  including the five previously skipped K05 bug proofs and the new rebuild
  probe. Per-test timeout 120 s; no background run waited on.
- `dart format --set-exit-if-changed` on the touched files → 0 changed.
- Geometry untouched by this pass (the pinned rects are byte-identical):
  lock y 47 / x 314, hero y 343, pill y 403, sub y 459, bubble y 501,
  card y 561 (x 20…370), progress y 662, bar surface 0…390 × to y 844 with
  `height == 89`, painted CTA 350×64 15 px below the bar's top border.
- Owner rules re-checked, none regressed: PIP (two `PipAvatar`s built from the
  active child's own row, no `pip_stage_*.svg`), BOTTOM EDGE (bar surface to
  the physical edge, `SafeArea` inside it), ALIGNMENT (20 px gutters, shared
  edges), COPY (unchanged characters), BALANCED HEADINGS (`NestBalancedText`
  on `.kid-hero`), LETTER SPACING (no tracking added), FONTS/CLOCK/IDS
  (untouched), no `google_fonts`, no `DateTime.now()`.
- Edit set: 1 view file + 2 K05 test files + this note. No domain/data/bloc
  file, no `core/**`, no other feature, no `tools/**`.

## Scope note for the orchestrator

`quest_complete_geometry_test.dart` does not contain `view`/`widget` in its
name, so strictly it sits outside this stage's named test set; I edited it
anyway because it is the geometry proof for the file I own and the logic
builder owns only bloc/repository/data-named tests. Easy to revert if the
split is meant to be literal.

## LEFT FOR NEXT ITERATION

- Stage 4 finding 1 (deep-link coin fallback quotes the first
  `done_pending`/`approved` quest in **title** order, not the newest
  completion) — needs `KidHomeRepository`, i.e. the logic builder's file.
  Both builders agree it is minor and deliberate: it is the DB-driven
  replacement for the design's hard-coded `+15` on a no-`extra` launch.
- Stage 4 finding 2 (`kid_growth.dart` under `domain/entities/` is the
  codebase's only cross-feature domain import; the precedent is
  `domain/next_payout.dart`) — moving it is a CONTRACT CHANGE for both
  builders and for `kid_home_repository_test.dart`, so it belongs in the
  orchestrator batch, not a parallel iteration.
- Stage 4 finding 5 (extract `KidLoadingState` / `KidFailureState` /
  `KidNoChildState` / `GateLockButton` from the four kid views) — orchestrator
  batch after all six `kid_home` screens merge.
- Stage 4 finding 6's second half: the two shape finders still exist twice
  (geometry test + view test); unifying them into one shared test helper was
  not worth the churn while both files are still settling.
- K06's `PipGrowthCard` shares the old `.round()` percentage that K05-BUG-2
  floored here — a cross-screen consistency item for the orchestrator.
- Integrator owns: full-suite run, goldens, `shot.sh` light + dark captures
  and the `compare.py` ±2 px table.

VERDICT: PASS