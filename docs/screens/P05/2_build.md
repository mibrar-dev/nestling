# P05 · Add children — integrated build (STAGE 2, iteration 6)

Route `/add-children` (feature `family`, parent mode). Two builders worked in
parallel this iteration; this stage merged their halves and got the combined
result green. No integration breakage needed fixing — the two halves had no
overlapping edits, no contract drift, and the working tree needed no
correction to compile, analyse, or pass.

## Summary of 2a (logic) — `2a_build_logic.md`

Scope: `domain/**`, `data/**`, `presentation/bloc/**`, DI/route registration.
No views or widgets touched.

- **Contract: unchanged.** `FamilyLoadRequested`, `FamilyDraftChanged`,
  `FamilyAddChildRequested` and every `FamilyState` field the view consumes
  are exactly what `add_children_view.dart` already uses — verified
  read-only, so no UI rework was required on the logic side.
- `family_repository_impl.dart`: retired the iteration-4 interim
  `rowid`-only query; shared batch 2 (schema v3) gave `children` a real
  `createdAt` and `AppDatabase.watchChildren` now orders by
  `createdAt, rowid`, so the feature delegates to the shared helper
  (durable CHILD ORDER fix). `addChild` writes an explicit `now()`.
- Validation messages, BUG-2 double-tap guard, BUG-5 mid-save guard,
  BUG-6 `ageYears` mapping all present; `flutter test test/features/family`
  → 116 at that point.

## Summary of 2b (UI) — `2b_build_ui.md`

Scope: `presentation/views/**`, `presentation/widgets/**`, widget tests.

- Same no-contract-change conclusion from the UI side.
- FIXES_5 deviation 1 (chip row 44 px in flow) is now closed by main's
  batch-2 chip (32 px pill in the flow, ≥44×44 hit area overlaid); the
  P05-local `IntrinsicWidth` was already gone. 2b flipped the stale
  chip-geometry expectations (chip row height 32, tap-target assertions to
  the overlay hit area), which also repaired the collateral `Try again`
  failure.
- Refreshed the stale `kid_card_grid.dart` comment to "creation-ordered
  (createdAt, rowid)".

## Integration work done here

- Read both stage files and diffed their claims against the tree:
  no duplicate/conflicting edits (`git status` shows each file owned by
  exactly one builder), no renamed members, no import breakage, no
  `google_fonts`/`GoogleFonts` anywhere in `lib/features/family` or
  `test/features/family` (per the FONTS orchestrator rule), and no
  `TODO(P05)` left in the layer.
- Ran the three gates. Nothing to fix: no breakage was present to repair,
  so no code change was made in this stage — the smallest possible
  integration (zero edits).
- Left for the UI gate (not a build action): re-shoot light/dark and
  confirm band5 drift collapses now the chip row is 32 px, Maya-first
  from the database, then close the child-order `SHARED_REQUEST.md`
  entry.

## Files changed (RULES §1 only)

- `docs/screens/P05/2_build.md` — this file only. The product/test
  changes in the tree belong to 2a and 2b; this stage added none.

## FIXES items — status

- **FIXES_1…4** (chips stacked, BUG-2/4/5/6/7/8, child order, card
  height, chip-order proofs, copy `’`, focus ring): closed in earlier
  iterations, re-proved green in this run.
- **FIXES_5 §1** (chip row 44 px → +12 shift of swatches/caption):
  shared fix landed on main; 2b updated the affected expectations. Done.
- **FIXES_5 §2–4** (child order, cards, copy, owner rules): pass, kept.
- **No skipped bug tests** exist or are referenced;
  `grep -c "skip:"` returns 0 in both family test files.

## Verification tails

`dart format .` — clean (0 changed).

`flutter analyze` — `No issues found!` (full-app run, exit 0).

`flutter test` (full suite) — `00:31 +783: All tests passed!` (exit 0,
zero skips). Every widget test that pumps the app ends with
`disposeApp(tester)`.

VERDICT: PASS