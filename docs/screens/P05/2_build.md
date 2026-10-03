# P05 · Add children — integrated build (STAGE 2, iteration 7)

Route `/add-children` (feature `family`, parent mode). Two builders worked in
parallel this iteration (2a logic, 2b UI). This stage merged their halves and
got the combined result green. No integration breakage needed fixing: both
halves reported no contract changes and no overlapping file edits, so the
smallest possible integration was again zero code changes from this stage.

## Summary of 2a (logic) — `2a_build_logic.md`

Scope: `domain/**`, `data/**`, `presentation/bloc/**`, DI/routes.

- **Contract: unchanged.** All events/state fields match what
  `add_children_view.dart` consumes.
- **Files changed: none** (verify-only pass). The iteration-6 logic work is
  already in the tree and survived the `fc68854` main merge:
  `FamilyRepositoryImpl.watchChildren` delegates to the shared
  `AppDatabase.watchChildren` (`createdAt, rowid` ordering, schema v3); the
  interim `rowid`-only query is retired.
- Triaged `FIXES_6.md` for its layer: the only bug (P05-BUG-11) lives in the
  form card + shared `nest_chip.dart`, so nothing was in scope here.
- `flutter test test/features/family` → 122 passed, 1 skipped (the mandated
  P05-BUG-11 proof).

## Summary of 2b (UI) — `2b_build_ui.md`

Scope: `presentation/views/**`, `presentation/widgets/**`, widget tests.

- **Contract: unchanged** (same conclusion from the UI side).
- Per orchestrator decision 04:31 — keep both owner rules (32 px chip visual
  + 44 px tap target) and wait for the shared `NestChipWrap`
  (`shared/chip_wrap_hit_area`): `NestChipWrap` is **not** on this branch, so
  the age-chip `Wrap` stays, the tap-target test keeps the iteration-6 form
  (width ≥ 44, height == 32), and the `[P05-BUG-11]` proof stays skipped with
  the mandated branch reference. The green characterisation test recording
  the clipping remains visible in the passing suite.
- Re-verified FONTS / LETTER SPACING / CHILD ORDER / COPY / BOTTOM EDGE /
  ALIGNMENT / PIP via the suite.
- `flutter test test/features/family` → 122 passed, 1 skipped.

## Integration work done here

- Cross-checked both reports against the tree: no duplicate or conflicting
  edits (`git status` shows only the test files 2b owns plus the two stage
  notes), no renamed members, no import breakage, no `google_fonts` /
  `GoogleFonts` anywhere in `lib/features/family` or `test/features/family`
  (FONTS rule), no `TODO(P05)` left in the layer.
- Ran the three gates: nothing to repair, so no code change was made here.
- Confirmed the standing skip is the single orchestrator-mandated one
  (P05-BUG-11, `p05_bugs_test.dart`) and that `NestChipWrap` is indeed absent
  from `core/design_system`, so un-skipping it here would be wrong.

## Files changed (RULES §1 only)

- `docs/screens/P05/2_build.md` — this file only. The product/test changes in
  the tree belong to the builders; this stage added none.

## FIXES items — status

- **FIXES_1…4** (chip stacking, BUG-2/4/5/6/7/8, child order, card height,
  copy `’`, focus ring): closed in earlier iterations, re-proved green here.
- **FIXES_5 §1** (chip row 44 px in flow): closed by shared batch 2; the
  expectations were flipped in iteration 6.
- **FIXES_6 (P05-BUG-11, chip tap area clipped by the `Wrap`)**: LEFT —
  shared root cause, no P05-local fix exists, `NestChipWrap` not yet merged;
  proof skipped by orchestrator ruling (04:31). When it lands: swap the
  chip `Wrap` for `NestChipWrap`, restore `atLeast44` in width and height on
  the age chips, un-skip the proof, re-shoot.
- **No other open items.** No skipped tests beyond the mandated one.

## Verification tails

`dart format .` — clean (0 changed).

`flutter analyze` — `No issues found!` (full-app run, exit 0).

`flutter test` (full suite) — `00:25 +984 ~1: All tests passed!` (exit 0);
the single `~1` is the mandated P05-BUG-11 skip (runnable with
`--run-skipped`), not a failure. Every widget test that pumps the app ends
with `disposeApp(tester)`.

VERDICT: PASS