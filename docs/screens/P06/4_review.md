# P06 — Stage 4 QA code review (iteration 3)

Diff reviewed: `git diff main...HEAD` (feature `pocket_money`, docs/screens/P06).
Checks: architecture contract, RULES §1 path isolation, design-system/token
usage, DESIGN_SPEC §5 P06 copy, a11y, performance, error handling, Children's
Code. Verified locally: `flutter analyze lib/features/pocket_money
test/features/pocket_money` → No issues found; `flutter test
test/features/pocket_money` → 100 pass, 1 skip (P06-BUG-03, pending shared
chip mode).

## Scope compliance — OK

All edits under `app/lib/features/pocket_money/**`,
`app/test/features/pocket_money/**`, `docs/screens/P06/**` (RULES §1). No
shared code touched; `SHARED_REQUEST.md` filed for the `NestChip` compact
mode (P06-BUG-03). Architecture: domain still entities + abstract repo only;
one bloc; DI/routes unchanged. No google_fonts/GoogleFonts, no skips other
than the filed BUG-03, no analytics/ads imports; copy matches the HTML;
children by `ORDER BY rowid` (Maya→Leo); bottom-edge rule holds.

## Fixed since iteration 2 (verified)

- P06-BUG-01 stepper lost update — bloc now builds each step on
  `_requestedBase` (recorded synchronously per child) and emits
  `withChildBase` optimistically; stream confirms and dedupes. Bloc test
  present.
- P06-BUG-02 payout-day fast-tap guard — `_pendingDay` tracks the last
  request; re-tap suppression compares against it.
- P06-BUG-05 failed write — view keeps `_LoadedBody` with inline
  `errorMessage` (`pocket_money_setup_view.dart:59-72`); only a load
  failure with no setup swaps to `_FailureBody`.
- P06-BUG-06 stale `errorMessage` — `clearErrorMessage: true` on data and
  stepper-success emissions.
- P06-BUG-07 unknown child id — `_onWeeklyBaseStepped` now no-ops when
  `childById` returns null.
- P06-BUG-04 day-cell target — `_DayRow` enforces
  `math.max(NestDevice.tapParent, …)` per cell with horizontal scroll on
  overflow.

## Findings

1. **MINOR — `assert`-only validation is still a no-op in release.**
   `app/lib/features/pocket_money/data/pocket_money_repository_impl.dart`
   `setMode` (~line 105), `setPayoutDay` (~line 135). In release an invalid
   mode/day would persist and the screen renders with no selection. Fix:
   `throw ArgumentError.value(...)` in all modes (same for the clamp note —
   `setWeeklyBasePence` already clamps, fine).

2. **MINOR — a few hard-coded pixel sizes remain.**
   `pocket_money_setup_view.dart`: line ~320 `horizontal: 13`, line ~377
   radio `22`, line ~159 loading placeholder `200`. The coin tile is now
   `NestSpacing.s10` (fixed). Fix: add a 13px option-card inset and a 200px
   loading-block height to the shared scale or reuse existing spacing.

3. **MINOR — P06-BUG-03 open (day pill paints below ~30px).**
   `pocket_money_setup_view.dart` `_DayCell` FittedBox-shrinks `NestChip`
   to fit 7-across; the bug test stays `skip: true` (p06_bugs_test.dart:254)
   pending the shared `NestChip` compact mode in `SHARED_REQUEST.md`. Not a
   blocker while the request is filed, but the deviation must ship with the
   shared fix.

No blocker/major findings. GPT-style checks otherwise clean: single
`emit.forEach` over combined streams, `_closeOnError` prevents watcher
leaks, no analytics/child-data exposure, tap targets on option cards and
stepper buttons ≥ 44dp parent, Semantics labels on all steppers, UK-noun
copy.

VERDICT: PASS
