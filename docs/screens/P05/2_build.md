# P05 · Add children — integrated build (STAGE 2, iteration 8)

Route `/add-children` (feature `family`, parent mode). Two builders worked in
parallel (2a logic, 2b UI). This stage merged their halves and got the combined
result green. No integration breakage needed fixing: the halves had disjoint
file ownership and no contract drift, so this stage added no code.

## Summary of 2a (logic) — `2a_build_logic.md`

Scope: `domain/**`, `data/**`, `presentation/bloc/**`, DI/routes.

- **Contract: unchanged.**
- **Files changed: none** (verify-only pass). Every `FIXES_7.md` item was
  outside the logic layer: the shared chip pill padding (`shared/chip_pill_padding`
  on main via `b466c96`) is read-only core, the `Wrap` → `NestChipWrap` swap
  and the test un-skip are presentation/test files owned by the UI builder,
  and the re-shoot is stage-5 work (this stage is simulator-forbidden).
- Confirmed the logic layer is intact post-merge: `FamilyRepositoryImpl`
  delegates to `AppDatabase.watchChildren` (`createdAt, rowid` ordering), no
  `google_fonts`/`GoogleFonts` anywhere.
- At its snapshot: 124 passed, 1 skipped (the P05-BUG-11 proof, correctly
  still skipped until the UI swap landed).

## Summary of 2b (UI) — `2b_build_ui.md`

Scope: `presentation/views/**`, `presentation/widgets/**`, widget tests.

- **Contract: unchanged** (same conclusion from the UI side).
- **FIXES_7 all three items closed:**
  1. Chip pills are the design size (shared fix measured with the shipped
     Inter faces: 53.28 / 52.02 / 64.80 / 52.25 wide, 32 high). New proofs
     pin the painted `DecoratedBox` rect, the 8 px gaps, the left-aligned
     single run, and the content-edge x.
  2. **P05-BUG-11 closed**: both interactive rows now use `NestChipWrap`
     (age chips **and** swatches), the `[P05-BUG-11]` proof is un-skipped and
     rewritten to tap 5 px above/below the run, and the former "32-px target"
     characterisation test (which asserted the bug) is deleted. 2b also
     found and fixed a non-obvious blocker: the `Semantics(container: true)`
     wrapper was itself a tight box clipping the widened hit test, so the
     design's group label moved onto the row's `.lbl` heading — a11y group
     labelling preserved.
  3. Re-shoot deferred to stage 5 (simulator-forbidden here).
- **BALANCED HEADINGS**: the `.h1` now renders through `NestBalancedText`
  (`text-wrap: balance` in components.css), same copy/style/maxLines; the
  gutter test measures the balanced band so the owner ALIGNMENT rule still
  holds.
- At its snapshot: 130 passed, 0 skipped; regression-checked the shared
  app/design-system suites (76 passed).

## Integration work done here

- Cross-checked both reports against the tree: no duplicate or conflicting
  edits (`git status` shows exactly the two presentation files, two test
  files and the new `p05_view_metrics_test.dart` that 2b owns), no renamed
  members, no import breakage.
- Verified the feature's rules: no `google_fonts`/`GoogleFonts`, no
  `TODO(P05)`, and **zero `skip: true`** across all three family test files
  (the P05-BUG-11 skip is gone).
- Ran the three gates: nothing to repair, so no code change was made here.

## Files changed (RULES §1 only)

- `docs/screens/P05/2_build.md` — this file only. The product/test changes in
  the tree belong to the builders; this stage added none.

## FIXES items — status

- **FIXES_1…4** (chip stacking, BUG-2/4/5/6/7/8, child order, card height,
  copy `’`, focus ring): closed in earlier iterations, re-proved green.
- **FIXES_5 §1** (chip row 44 px in flow): closed by shared batch 2.
- **FIXES_6 (P05-BUG-11)**: CLOSED in 2b this iteration (`NestChipWrap`,
  proof un-skipped and passing).
- **FIXES_7** (chip pill shape/widths; P05-BUG-11 swap; re-shoot): items 1–2
  done; item 3 (re-shoot `cmp_light_8`/`cmp_dark_8`) is stage-5 work and
  remains for the UI check.
- **No open code items, no skipped tests.**

## Verification tails

`dart format .` — clean (0 changed).

`flutter analyze` — `No issues found!` (full-app run, exit 0).

`flutter test` (full suite) — `00:21 +1155: All tests passed!` (exit 0,
zero skips). Every widget test that pumps the app ends with
`disposeApp(tester)`.

VERDICT: PASS