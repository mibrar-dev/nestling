# K11 · Badges — stage 2 build, INTEGRATE (iteration 3)

Merge of the two parallel builders for feature `badges`. Sources:
`2a_build_logic.md` (logic chunk, iteration 3) + `2b_build_ui.md` (UI chunk,
iteration 3), plan in `1_plan.md`, mandatory items in
`ORCHESTRATOR_NOTES.md` (06:55 locked-medal art). There is no `FIXES_2.md`
for this screen, so the fix list is assembled from the loop artifacts:
`6_bugs.md` (iteration 2: both bugs fixed+verified, no new bugs),
`4_review.md` (single minor finding, hardening-only), `3_test.md` (no screen
bugs), `ORCHESTRATOR_NOTES.md` 06:55.

**Outcome: the two halves merged with ZERO integration fixes.** The builders
touched disjoint file sets (logic: no lib edits this iteration; UI:
`presentation/widgets/badge_grid_cell.dart` + `badges_view_test.dart`), 2a
reports no contract changes, and the merged tree was already green — per
"smallest change / do not redesign" this stage changed no file under `app/`.

## Summary of 2a (logic chunk — domain / data / bloc, iteration 3)

- No lib edits. Only logic-layer candidate was review finding 1 (`_switchMap`
  cancel/subscribe overlap — explicitly "hardening only" with "fix (if ever
  touched)", stage-6 10-burst probe proving no stale emission, identical to
  the K08 shared pattern). Per the finding's own guidance and to avoid
  diverging from K08: NOT touched.
- Post-merge (`179836f`) re-verification only: scoped analyze clean;
  repository + bloc files 37/37 pass unmodified. No contract changes.

## Summary of 2b (UI chunk — views / widgets, iteration 3)

- **Locked medal art fixed (`badge_grid_cell.dart`, orchestrator-mandatory
  06:55):** the five still-to-do ids (`bins-out`, `biscuit-sitter`,
  `tidy-hero`, `early-bird`, `plant-waterer`) now render a local
  `lockedMedalSvg(id)` via `SvgPicture.string` instead of the shared
  `badge_*` assets — dashed ring in INK `#1E1B3A` (3 px, `dasharray 5 4`;
  HTML keeps the FIRST of the two duplicate `stroke` attributes) and the
  ribbon `opacity=".4"` kept on the WHOLE element (fill + 3 px ink stroke
  together). Fixed illustration colours in both themes (medals keep own
  colours, `1_plan.md` §0). Each id keeps its own design glyph in both
  states; the four earned ids still use their shared coloured assets;
  unknown ids still fall back to the neutral rosette. No `core/` edit
  (RULES §1) — shared files left for the orchestrator.
- **Tests:** new `K11 locked medal art (ORCHESTRATOR_NOTES 06:55)` group in
  `badges_view_test.dart` (8 tests: ink-ring unit pins for all five ids,
  whole-element ribbon-opacity pin, per-id glyph pins, light + dark widget
  pumps, earned-keeps-own-medal, earned-still-shared-asset).
- **NOT touched:** `badges_view.dart`, `happy_week_card.dart` (clamp + copy
  already landed); `k11_bugs_test.dart` (both guards already un-skipped and
  green per `6_bugs.md` iteration 2); domain/data/bloc.

## FIXES items

### Done (verified on the merged tree)

- ORCHESTRATOR_NOTES 06:55 locked-medal art — local `lockedMedalSvg` + 8
  regression tests (2b); feature + full suite green (this stage).
- K11-BUG-1 (widget clamp) / K11-BUG-2 (no hard-coded `'maya'`) — fixed and
  verified in iteration 2 (`6_bugs.md`: both guards un-skipped and passing);
  no new bugs found.
- Review findings 1 (ctor syntax), 2 (= K11-BUG-1 clamp), 4 (stale error on
  loading) — fixed in iteration 2. Finding 3 / iteration-2 finding 1
  (`_switchMap` overlap) left as is per its own hardening-only note.
- `SHARED_REQUEST.md` seed item — closed, landed as `shared/k11_badges_seed`;
  `TODO(K11)` removed (no `TODO` under the feature).

### LEFT (not integration issues)

- Nothing. The orchestrator's zoomed-crop verification (one locked medal,
  design vs app, both themes, in `5_ui.md`) belongs to stage 5 with the
  simulator — this stage supplies the corrected pixels.

## Orchestrator rules re-checked on the merged tree

- `grep google_fonts|GoogleFonts|DateTime.now` over `lib/features/badges` +
  `test/features/badges` → comment mentions only, zero call sites.
- Tokens only (locked-medal hexes are illustration art, same category as the
  shared files' hard-coded hexes; all chrome still uses tokens); `KidScope`
  shared sky+meadow; `NestBalancedText` on the `.kid-title`; children/badges
  in DB insertion order; counts from the database; no `clock`/`newId` misuse;
  no simulator booted by this stage; no `flutter clean`; `analysis_options`
  untouched; no `pkill`/`killall`.
- Files modified under `app/` are only
  `app/lib/features/badges/presentation/widgets/badge_grid_cell.dart` and
  `app/test/features/badges/badges_view_test.dart` (RULES §1). The
  `docs/screens/K11/.brief_*`, `2a_build_logic.md`, `2b_build_ui.md`
  modifications are the parallel builders' own notes, committed by the loop.

## Command tails (verbatim)

```
$ dart format .   (in app/)
Formatted 677 files (0 changed) in 2.33 seconds.

$ flutter analyze   (in app/)
Analyzing app...
No issues found! (ran in 4.1s)

$ flutter test --timeout 120s test/features/badges/
00:03 +152: All tests passed!

$ flutter test --timeout 120s   (full suite)
01:43 +5194 ~16: All tests passed!
```

Feature suite: **152 passed, 0 failed** (no skips). Full suite: **5194
passed, ~16 skipped, 0 failed.** `dart format` clean, `flutter analyze` →
No issues found. No integration breakage: no mismatched BLoC
states/events, no import or rename conflicts, no failing test caused by the
merge — nothing to fix.

Prior iteration: iteration-2 integrate reported 129 passed / 2 skipped
(feature) and 4746 passed / ~15 skipped (full); the test, review, UI and
bugs stages since grew the suite and un-skipped the guards — all green here.

VERDICT: PASS
