# P05 · Add children — logic build (STAGE 2a, iteration 8)

Scope: non-UI layer of feature `family` only —
`domain/**`, `data/**`, `presentation/bloc/**`, DI/route registration.
No file under `presentation/views/**` or `presentation/widgets/**` touched.

## CONTRACT CHANGES

None. Public names stable per `1_plan.md` §b. No UI-builder rework required.

## Files changed

None in this iteration — verify-only. Every `FIXES_7.md` item falls outside
this layer (details below); the logic layer needed no edits.

## FIXES_7 triage (why nothing here is this layer's)

1. Chip pill widths (shared `chip_pill_padding`, on main via `b466c96`) —
   shared `core/` fix, read-only for this screen. "Update any P05 test that
   pinned the old narrow width" targets widget-geometry expectations in
   `add_children_test.dart`, a file the parallel UI builder owns. Not mine.
2. P05-BUG-11 (`NestChipWrap` now on main — confirmed present at
   `core/design_system/components/nest_chip_wrap.dart`):
   - swapping the two `Wrap`s in `add_child_form_card.dart:74,101` is a
     `presentation/widgets/**` edit — UI builder owns it (verified not yet
     done; both still `Wrap`). Deliberately untouched to avoid a
     parallel-edit conflict in the shared worktree.
   - un-skipping the proof in `p05_bugs_test.dart:501` and restoring
     `atLeast44` in `add_children_test.dart` verify the UI swap, so they
     belong with it. Un-skipping before the swap lands would turn the suite
     red; the skip stays correct until the UI builder acts.
   - Swatch-row question answered read-only for the UI builder's report:
     line 101 is still a plain `Wrap`; whether each swatch already carries
     a ≥44×44 target inside the row is for the UI stage to measure with the
     new pill geometry.
3. Re-shoot `cmp_light_8/cmp_dark_8` — stage 5 (UI check) work, and this
   stage is simulator-forbidden. Not mine.

## Verification (this worktree, unchanged logic code)

- `flutter analyze lib/features/family` → No issues found.
- `flutter test test/features/family` → **124 passed, 1 skipped, 0 failed**
  (the skip is P05-BUG-11, still correctly skipped pending the UI swap).
- Logic layer re-confirmed intact post-merge: `FamilyRepositoryImpl`
  delegates to shared `AppDatabase.watchChildren` (`createdAt, rowid`
  ordering); no `google_fonts`/`GoogleFonts` in the feature or its tests.

## LEFT FOR NEXT ITERATION

- UI builder: swap both interactive `Wrap`s to `NestChipWrap`, un-skip
  P05-BUG-11, restore `atLeast44` (height and width), update any
  narrow-width chip expectations to the padded pill geometry, re-shoot the
  comparison PNGs.

VERDICT: PASS
