# P06 Pocket money setup — integration build (Stage 2 INTEGRATE, iteration 6)

Two parallel builders worked on P06; this stage only integrated them and fixed any
merge breakage. Route `/pocket-money-setup` · feature `pocket_money` · parent mode.

## 2a — logic builder (`2a_build_logic.md`, iteration 6)

- **CONTRACT CHANGES: none.** No event/state/repository signature changes; no logic-layer
  edits at all. FIXES_5 carries zero logic items: findings #1/#2/#3 (H1 `NestBalancedText`
  collapse, the real-font geometry guard, the stepper minus glyph) are view / view-test /
  shared-component matters; #4/#5 are view semantics and copy.
- Re-verified no regression in the logic layer: P06-BUG-01 (request tracking), BUG-02
  (pending-day guard), BUG-06 (`clearErrorMessage`), BUG-07 (unknown-child no-op), BUG-09
  (confirm-only pending clear), review #9 (no `watchSetting` subscription), #10
  (`emit.isDone` guards), #12 (`ArgumentError` past `assert`).
- Checks: analyze clean on the logic files; bloc + repository 45/45; `p06_bugs_test`
  green apart from the two shared/view proofs 2b then un-skipped.

## 2b — UI builder (`2b_build_ui.md`, iteration 6)

- **Files changed:** new `presentation/widgets/p06_weekly_stepper.dart`; view swaps
  `_BaseStepper` → `P06WeeklyStepper` and gives day cells the group-prefixed semantics
  label; new `pocket_money_setup_view_geometry_test.dart` (real bundled Inter/Nunito via
  `FontLoader`, `Seed.onboardingKids`, every orchestrator anchor pinned at ±1 px); new
  `p06_weekly_stepper_widget_test.dart`; `p06_bugs_test.dart` lost both `skip: true`
  lines; `pocket_money_setup_view_test.dart` day-cell labels + one bogus
  "fits on one line" assertion fixed; `SHARED_REQUEST.md` items 4 and 5 recorded.
- Fixes: 4_review #1 H1 renders one ellipsized line → resolved by the shared
  `balanced_text_ellipsis` fix now on main (no local workaround, `NestBalancedText` kept);
  #2 real-fonts geometry guard added; #3 / P06-BUG-12 stepper minus hyphen → new
  feature-private `P06WeeklyStepper` pairs `−` (U+2212, the HTML's `&minus;`) with `+`,
  token-for-token identical to `NestStepper` and marked for retirement when the shared
  glyph override lands; #4 `Payout day` group label restored via the cells' own
  semantics label (`Payout day: Mon`) instead of a wrapper that would re-clamp the
  ±6 px hit slop; #5 empty-state copy deliberately left byte-identical, flagged for the
  orchestrator.

## Integration actions (this stage)

None required. 2a declared no contract change; 2b's new widget and the two new test
files compile against the unchanged logic layer, the worktree analyzed clean and the
whole suite passed on the first run, so the integrator made no source edits — only the
stage gates.

## FIXES_5 items (all from `4_review.md` + the bug hunt)

| Item | Owner | Status |
|---|---|---|
| #1 (MAJOR) H1 collapsed to one ellipsized line | 2b | DONE — shared `balanced_text_ellipsis` fix on main; two 34 px lines restored, card back at 415–684 |
| #2 (MAJOR) real-fonts geometry test absent | 2b | DONE — `pocket_money_setup_view_geometry_test.dart` pins H1/option cards/card/pill/rows/coin/CTA at ±1 px |
| #3 (MAJOR) stepper minus is a hyphen (P06-BUG-12) | 2b | DONE — `P06WeeklyStepper` with U+2212, widget test asserts the code units |
| #4 day-group semantics label dropped | 2b | DONE — `Payout day: <day>` on each cell, ±5 px taps still green |
| #5 invented empty-state copy | 2b / orchestrator | LEFT — `'Add children to set weekly amounts.'` unchanged, awaiting ratification (renders only under `Seed.empty`/`Seed.fresh`) |
| P06-BUG-11 (H1 one-line) | 2b | DONE — un-skipped, green |
| P06-BUG-12 (minus hyphen) | 2b | DONE — un-skipped, green |

Shared-track follow-ups (non-blocking, recorded in `SHARED_REQUEST.md`): `NestStepper`
U+2212 glyph override (item 4) so `p06_weekly_stepper.dart` can be deleted, and the
`NestChip` day variant (item 5) so `_DayPill` can be retired.

## ORCHESTRATOR_NOTES (all entries)

Items 1–6 from the 04:05 update hold unchanged and are green (shoot seed, chip row inside
the 16 px inset, letterSpacing 0, gold coin tile, option-card heights now pinned at 64,
`NestChipWrap` with ±5 px taps). The 07:22 and 07:58 additions are all closed: real-font
geometry pins added, the `−` glyph fixed and tested, the title back to two lines with
`NestBalancedText` kept, and the five y targets from the title's bottom pinned.

## Analyze / test tails

- `dart format .` → `Formatted 393 files (0 changed) in 1.96 seconds.`
- `flutter analyze` (full app) → `No issues found! (ran in 6.9s)`
- `flutter test` (full app) → `All tests passed!` (`+1180`, EXIT 0, ~74s). **No skips
  anywhere** — the feature's last two skipped proofs (BUG-11, BUG-12) were un-skipped
  and pass.

## Scope compliance

No integrator edits. Worktree changes are the two builders' files: the feature's
`presentation/{views,widgets}` plus `app/test/features/pocket_money/**` and
`docs/screens/P06/**` (RULES §1). No shared code, no `analysis_options` change, no
`google_fonts`/`GoogleFonts` in the feature, no simulator used.

VERDICT: PASS