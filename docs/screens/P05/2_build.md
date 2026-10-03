# P05 · Add children — build notes (STAGE 2, iteration 6)

Route `/add-children` (feature `family`, parent mode). Iteration 5 record is
superseded below. `docs/screens/P05/FIXES_5.md` contains only the iteration-5
UI check: one remaining defect (shared chip-box height, +12), everything else
a pass. No skipped bug tests exist or are referenced. No product-code change
was needed this iteration: the one defect is shared/read-only with a standing
filing, and main brought no new P05-scope work (only merges plus an unrelated
K03 brief).

## Files changed (RULES §1 only)

- `docs/screens/P05/2_build.md` — this file. Nothing else.

Working tree is otherwise clean; no product, test, shared, core, or app file
touched: there was nothing in RULES §1 left to fix.

## What was done about each fix item

- **UI deviation 1 (the one remaining defect) — chip row 44 px vs design
  32 px (+12 on swatches/caption): shared, already filed, no P05-local
  action.** Re-verified the premise: the shared `NestChip` on main still
  carries the 44-min tap minimum AS the layout box (symmetric vertical 4.5
  padding around a 35 px pill), and no overlay-construction fix has landed
  since. Re-verified every P05-owned vertical value against the HTML/CSS
  sources — `.field` margin-top 10, label→input from the DS field, `.lbl`
  margin-top 8, `.chip-row` margin-top 4, `.swatches` margin-top 4 with gap
  8, swatch 44×44, `.form-note` margin-top 6 — all literal tokens in
  `add_child_form_card.dart`. Taking a 32 px chip height locally would mean
  overriding the DS component's height (breaking the pinned 44-min tap
  targets and `SPACING_SPEC` §10.6) or falsifying spacing with fixed
  heights (breaking text-scale behaviour) — both rejected by the UI stage
  itself. Standing `SHARED_REQUEST.md` #3 (32 px layout row, 44 px tap area
  overlaid) remains the fix.
- **UI deviations 2–4 (child order, cards, copy, owner rules): already
  passing, untouched.** The iteration-5 orchestrator gap targets (chip-row→
  label 8, label→swatch 4, swatch 44/gap 8) were verified literal in code;
  only the shared box height stands between them and the design centres.
- **No skipped tests.** `grep -c "skip:"` returns 0 in both family test
  files; FIXES_5 references no skipped proofs. P05-BUG-1…10 proofs all run
  un-skipped and green inside the suite.
- **Main merges consumed, not re-patched.** No new orchestrator items (notes
  file unchanged since iteration 4); the `family_time_zone` and router-test
  merges from iteration 5 still hold; core `watchChildren` still orders by
  nickname, so the iteration-4 `rowid` interim stands.

## Verification tails

`dart format .` — clean (0 changed).

`flutter analyze` — `No issues found!` (full-app run, exit 0).

`flutter test` (full suite) — `00:29 +764: All tests passed!` (exit 0,
zero skips in `test/features/family/`). Every widget test that pumps the
app ends with `disposeApp(tester)`.

VERDICT: PASS
