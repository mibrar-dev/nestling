# P05 · Add children — UI build (STAGE 2b, iteration 7)

Scope: `features/family/presentation/views/**`,
`presentation/widgets/**`, widget/view tests in
`app/test/features/family/**`. No `domain/`, `data/`, `bloc/` files touched.

## CONTRACT

`2a_build_logic.md` (iteration 7) — NO contract changes. Event/state API
unchanged; no UI rework required.

## FIXES_6.md dispositions

1. **P05-BUG-11 (chip tap target 32×pill; overlay clipped by the chip
   `Wrap`)** — orchestrator decision 04:31: keep BOTH owner rules (32 px
   visual + 44 px tap target); shared fix pending on branch
   `shared/chip_wrap_hit_area` (`NestChipWrap`). Per instructions:
   - `NestChipWrap` is NOT yet merged into this branch (`grep` finds it only
     in the shared branch / docs), so the age-chip `Wrap` in
     `add_child_form_card.dart` stays, and the tap-target test keeps the
     iteration-6 form (width ≥ 44, height == 32) until the component lands.
   - `[P05-BUG-11]` proof stays skipped with comments referencing
     `shared/chip_wrap_hit_area` in both `p05_bugs_test.dart` and
     `add_children_test.dart`; the green characterisation test ("vertical
     overlay is clipped by the chip Wrap") remains as the visible record.
   - When `NestChipWrap` merges: swap the age-chip `Wrap` for it, restore
     `atLeast44(chip)` (both dims) in the tap-target test, un-skip the proof.
2. Standing skip (P05-BUG-11) — kept, with the mandated branch reference in
   the skip comment.
3. FONTS / LETTER SPACING / CHILD ORDER / COPY / BOTTOM EDGE / ALIGNMENT /
   PIP — re-verified green via the suite (letter-spacing sweep test, Maya-
   first group, CTA-edge, copy code-unit asserts).

## Verified

- `flutter test test/features/family` → **122 passed, 1 skipped**, 0 failed.
- `flutter analyze lib/features/family test/features/family` → no issues.

## LEFT FOR NEXT ITERATION

- When main contains `NestChipWrap`: replace the age-chip `Wrap` in
  `add_child_form_card.dart`, restore `atLeast44` (w+h) on age chips,
  un-skip `[P05-BUG-11]`, re-run shot.sh + compare.

VERDICT: PASS
