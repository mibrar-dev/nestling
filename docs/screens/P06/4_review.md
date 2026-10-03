# P06 — Stage 4 QA code review (iteration 2)

Diff reviewed: `git diff main...HEAD` (feature `pocket_money`, docs/screens/P06).
Checks: architecture contract, RULES §1 path isolation, design-system/token
usage, DESIGN_SPEC §5 P06 copy, a11y, performance, error handling, Children's
Code. Verified locally: `flutter analyze lib/features/pocket_money
test/features/pocket_money` → No issues found; `flutter test
test/features/pocket_money` → 46/46 pass.

## Scope compliance — OK

All edits under `app/lib/features/pocket_money/**`,
`app/test/features/pocket_money/**`, `docs/screens/P06/**` (RULES §1). No
shared code touched, no `SHARED_REQUEST.md` outstanding. Architecture: domain
still entities + abstract repo only; one bloc per feature; DI/routes per
feature; view wrapped at the route level. Verified locally: analyze clean,
`flutter test test/features/pocket_money` 46/46 pass, no
`google_fonts`/`GoogleFonts.*`, no skips, no analytics/ads imports, copy
matches `design/html-source/screens/P06-pocket-money.html` character-for-
character, children in insertion order (rowid, not nickname), bottom edge rule
holds (NestBottomCta SafeArea runs the CTA surface to the edge).

## Findings

1. **MAJOR — weekly-base stepper loses rapid taps (lost update).**
   `app/lib/features/pocket_money/presentation/bloc/pocket_money_bloc.dart`
   `_onWeeklyBaseStepped` (~line 83) computes the new value from
   `state.setup?.childById(...)?.weeklyBasePence ?? 0` and writes it
   absolute.
   The bloc only awaits the repository write; the updated `state.setup`
   arrives later via the independent `emit.forEach` subscription. Two quick
   "+" taps can both read the stale base (e.g. £3.00), so both write £3.50
   and net +50p instead of +£1.00. Mode/day writes are absolute so they are
   immune; only the stepper arithmetic races. Fix: track in-flight deltas per
   child and add them to the last confirmed base, or have the repository
   accept a delta and do `SET weekly_base_pence = MIN(MAX(weekly_base_pence +
   Δ, 0), 2000)` atomically, then let the stream reconcile the display.

2. **MINOR — a failed write blanks the whole screen.**
   `pocket_money_bloc.dart` `_onModeChanged` / `_onPayoutDayChanged` /
   `_onWeeklyBaseStepped` emit `status: PocketMoneyStatus.failure`, and the
   view's failure branch (`pocket_money_setup_view.dart` line 57-58) swaps
   the entire settings card for `_FailureBody` even though
   `state.setup` is still valid. A transient Drift error on a stepper tap
   hides all setup UI until a later stream emission flips status back. Fix:
   keep `status: loaded` and surface the error inline/snackbar.

3. **MINOR — stale `errorMessage` survives recovery.**
   `pocket_money_state.dart` `copyWith` never clears `errorMessage`; the
   `onData` path doesn't reset it either, so after failure → re-emit the
   message persists in state. Fix: clear `errorMessage` when status becomes
   `loaded`.

4. **MINOR — `assert` validation is a no-op in release.**
   `pocket_money_repository_impl.dart` `setMode` (~line 105) and
   `setPayoutDay` (~line 135) assert only; in release an invalid value would
   be persisted and the screen would render with no option/day selected. Fix:
   `throw ArgumentError.value(mode, 'mode')` in all modes.

5. **MINOR — stepper fallback writes for unknown child.**
   `pocket_money_bloc.dart` `_onWeeklyBaseStepped`: when the child id is not
   in `state.setup` (`?? 0`), it still writes `±50` (clamped) for that id.
   Fix: no-op when `childById` returns null.

6. **MINOR — hard-coded pixel sizes instead of tokens.**
   `pocket_money_setup_view.dart`: line 292 `horizontal: 13`, lines 349-364
   radio `22`/`10`, line 145 loading placeholder `200`, lines 651-652 coin
   tile `40` (could be `NestSpacing.s10`). Fix: move to spacing/size tokens
   in the shared scale (or file a SHARED_REQUEST to add them) and reference
   the tokens.

7. **MINOR — day-cell tap targets ~30dp wide at 320dp.**
   `pocket_money_setup_view.dart` `_DayRow`/`_DayCell` (lines 461-527): 7
   `Expanded` cells across `320 − 40` gutters ≈ 40dp each minus 6px gaps —
   below the 44dp parent target on the width axis alone (height is 44 via
   `NestDevice.tapParent`). Fix: enforce a minimum chip width with
   horizontal scroll at small widths, or widen the row into two lines under a
   breakpoint (same pattern as `_WeeklyBaseRow`).

## Positives

Correct insertion-order children query (`ORDER BY rowid`, not nickname — and
a repository test pins it), `families`/`settings` mirrored writes in one
transaction, `0..2000p` clamp, day re-tap guard, `_closeOnError` so Retry
resubscribes without leaking watchers, one combined `emit.forEach`, 44dp
targets on option cards/steppers/cells, full Semantics labels on steppers,
copy verbatim from the HTML, mock glyphs/status bar follow the foundation
chrome, children only ever in Maya→Leo order.

VERDICT: FAIL
