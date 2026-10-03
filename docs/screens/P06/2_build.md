# P06 Pocket money setup — integration build (Stage 2 INTEGRATE, iteration 6, post-merge re-run)

The loop merged `main` (`310514a`, which carries `shared/balanced_text_ellipsis`) and
both builders re-ran against the merged tree. This stage integrated the combined result.
Route `/pocket-money-setup` · feature `pocket_money` · parent mode.

## 2a — logic builder (`2a_build_logic.md`)

- **CONTRACT CHANGES: none** — no event/state/repository signature changes.
- **Files changed: none.** FIXES_5 carries no logic-layer items: findings #1–#3 (H1
  `NestBalancedText` collapse, real-font geometry guard, stepper minus glyph) are view /
  view-test / shared-component matters; #4 (day-group semantics label) and #5
  (empty-state copy ratification) are view semantics and copy.
- Re-verified with no regression: P06-BUG-01 (request tracking), BUG-02 (pending-day
  guard), BUG-06 (`clearErrorMessage`), BUG-07 (unknown-child no-op), BUG-09
  (confirm-only pending clear), review #9 (no `watchSetting` subscription), #10
  (`emit.isDone` guards), #12 (`ArgumentError` past `assert`).
- Confirmed **zero `skip:`** left in `app/test/features/pocket_money/` — the shared fixes
  landed through main and 2b un-skipped the BUG-11/12 proofs.

## 2b — UI builder (`2b_build_ui.md`)

- **CONTRACT CHANGES: none** — nothing to migrate.
- **Only file touched:** `app/test/features/pocket_money/pocket_money_setup_view_geometry_test.dart`
  (plus `SHARED_REQUEST.md`). The view and widgets needed **no** edit after the merge:
  `_SetupTitle` still renders through `NestBalancedText` with no local `maxLines`/overflow
  override (the "do not work around it" rule), and `P06WeeklyStepper` still renders
  U+2212 `−` with U+002B `+`.
- Test work: `_pumpOnboardingKids` takes a theme; a new **H1 break guard** (heading box at
  the 20px gutter, >320 and ≤350 wide, two lines, line 1 ending after "How does pocket
  money" and not containing "work"); a new **dark-mode group** replaying the light anchors
  (H1 107/68, card 415–684 × 20–370, chips 455/32, `Weekly base` 503, Maya 545, Leo 589,
  coin 650, CTA bottom 844) plus token-colour checks (scaffold `tokens.paper`, CTA panel
  `tokens.surface`, selected pill `tokens.leafTint`, no exception).
- Design re-measure (PNG ÷3): H1 break, option cards 191/263/335 ×64, settings card
  415–684, day-strip runs within 0.3px, selected radio geometry, and the dark PNG's
  identical anchors — all matching the shipped view.
- `SHARED_REQUEST.md` item 3 marked **CLOSED** (it was stale; the real remaining ask is
  item 4, `NestStepper`'s U+2212).

## Integration actions (this stage)

None required. 2a declared no contract change; 2b's only edit is a test file that compiles
against the unchanged logic layer. The worktree analyzed clean and the whole suite passed
on the first run, so the integrator made **no source edits** — only the stage gates.

## FIXES_5 items

| Item | Owner | Status |
|---|---|---|
| #1 (MAJOR) H1 collapsed to one ellipsized line | shared `9ba19ab` via main; 2b added the break guard | DONE — 350×68, `didExceedMaxLines == false`, card back at 415–684; no local workaround |
| #2 (MAJOR) no real-font geometry test | 2b | DONE — extended with the H1-break guard and a full dark pass |
| #3 (MAJOR) stepper minus is `'-'` | 2b (earlier stage) | DONE — `P06WeeklyStepper` U+2212, widget test pins the code units |
| #4 `Payout day` group label | 2b (earlier stage) | DONE — cells announce `Payout day: <day>`, ±5px hit slop intact |
| #5 invented empty-state copy | orchestrator | **LEFT OPEN** — `Add children to set weekly amounts.` kept byte-identical, awaiting ratification (renders only under `Seed.empty`/`Seed.fresh`) |
| 5_ui deviations 2/5/6 | — | NON-ITEMS (status bar, owner BOTTOM EDGE override, rasterisation artefact) |
| 5_ui deviation 3 | 2b | DONE — `_DayPill` paints the 13px `NestType.fieldLabel` directly; only de-duplication remains (SHARED_REQUEST item 5) |
| 5_ui deviation 4 | 2b | DONE — gold `NestlingIllustrations.coin` in the 40×40 `coinTint` tile |
| P06-BUG-11 / P06-BUG-12 | 2b | DONE — proofs un-skipped, green |

Shared-track follow-ups (non-blocking): `SHARED_REQUEST` item 4 (`NestStepper` U+2212
glyph override → delete `p06_weekly_stepper.dart`) and item 5 (`NestChip` day variant →
retire `_DayPill`). Neither blocks the screen.

## ORCHESTRATOR_NOTES

All 04:05 items hold (shoot seed `onboarding_kids` with DB-sourced amounts in insertion
order, chips inside the 16px inset, letterSpacing 0, gold coin tile, option cards 64
tall, `NestChipWrap` with ±5px taps), and the 07:22/07:58 additions are closed: real-font
geometry pins (now also dark), the `−` glyph fixed and tested, the title back to two lines
via `NestBalancedText`, and the five y targets from the title's bottom pinned.

## Analyze / test tails

- `dart format .` → `Formatted 403 files (0 changed) in 0.91 seconds.`
- `flutter analyze` (full app) → `No issues found! (ran in 3.8s)`
- `flutter test` (full app) → `All tests passed!` (`+1364`, EXIT 0, ~33s; the suite grew
  after the main merge brought P03's tests). Zero skips and zero `google_fonts`/
  `GoogleFonts` references in the feature.

## Scope compliance

No integrator edits. Worktree changes are 2b's geometry test plus the builders' docs —
all under `app/test/features/pocket_money/**` and `docs/screens/P06/**` (RULES §1). No
shared code, no `analysis_options` change, no simulator used.

VERDICT: PASS