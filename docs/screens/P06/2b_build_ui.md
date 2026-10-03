# P06 Pocket money setup — UI build chunk (Stage 2b, iteration 3)

Route: `/pocket-money-setup` · feature `pocket_money` · parent mode · onboarding (P05 → P06 → P07).

## CONTRACT

Re-read `docs/screens/P06/2a_build_logic.md` (iteration 3): **no event/state
shape changes.** Additive only — `PocketMoneySetup.withChildBase`,
`PocketMoneyState.copyWith(clearErrorMessage:)`, private bloc fields
(`_pendingDay`, `_requestedBase`). Logic chunk fixed P06-BUG-01/02/06/07.

## Files changed (UI layer only)

- `app/lib/features/pocket_money/presentation/views/pocket_money_setup_view.dart`
  - **P06-BUG-05** — the failure branch keeps the loaded form whenever
    `state.setup` is valid (a failed write now renders the form plus an
    inline `NestType.caption(color: tokens.danger)` error line).
    `_FailureBody` + `Retry` only render for a load failure (`setup == null`).
  - **P06-BUG-04** — `_DayRow`/`_DayCell` reworked: cells are sized
    `max(44, (availableWidth − 6·gap6)/7)` (fill branch uses `Expanded`),
    and the row breaks out of the card's 16px inset to a `gap2` inset so
    cell width is ≥44 at 390 (44.28) and 430; at 320 the row goes
    horizontally scrollable with 44-wide cells (P10 chip-row pattern).
    Every cell keeps a 44-high tap box via `NestDevice.tapParent`.
  - **P06-BUG-03 (visual)** — the `NestChip`+`FittedBox` day cell is
    replaced by a feature-private `_DayPill` built from tokens only
    (32 high via `NestSpacing.s8`, `NestType.fieldLabel` = the design's
    13/18 w600 `.chip.day`, no horizontal padding, full-cell width,
    `surface2`/`ink` and selected `leafTint`/`leafInk` + 1.5 leaf border —
    same palette as `NestChip`). The painted pill is now the design's 32px,
    not the FittedBox-shrunk ~19px. The pill-bearing test stays skipped
    because its finder expects the shared chip; retiring `_DayPill` belongs
    with the shared change (see below). TODO(P06) left on `_DayPill`.
  - Review #6 — the two exact-token wins: coin tile `40 → NestSpacing.s10`,
    radio dot `10 → NestSpacing.gap10`. The remaining literals (option-card
    padding 13, radio ring 22, loading placeholder 200) have no token-scale
    equivalent and are parked in `docs/screens/P06/SHARED_REQUEST.md`.
- `app/test/features/pocket_money/pocket_money_setup_view_test.dart`
  - Alignment group: the day row's first cell now anchors at
    `card.left + gap2` (documented exception; all other rows still share
    the card's `s4` inner edge), and the day-cell tap box is pinned to
    44 high with a note that width is ≥44 by the breakout/scroll layout.
- `app/test/features/pocket_money/p06_bugs_test.dart`
  - Un-skipped **P06-BUG-04** (cell ≥ 44×44) and **P06-BUG-05** (failed
    write keeps the controls) — both now pass. Header updated; BUG-03 stays
    skipped (needs the shared `NestChip` compact mode).
- `docs/screens/P06/SHARED_REQUEST.md` (new) — two parked shared items:
  `NestChip` day variant (13px/padding-0, ±`labelStyle`), and spacing
  tokens for the pinned literal geometries (13, 22, 200).

## Items done (FIXES_2.md, UI-layer only)

- BUG-04: day cells ≥ 44dp wide — done (breakout row + ≥44 clamp + scroll
  branch), test un-skipped and green.
- BUG-05: failed write no longer blanks the form — done (inline error),
  test un-skipped and green.
- Review #6: literal sizes — `s10`/`gap10` applied; remainder filed as
  SHARED_REQUEST (blocked on shared edits, not screen work).
- BUG-03: visual cause fixed with `_DayPill`; the finder-level widget test
  stays skipped pending the shared `NestChip` variant.
- BUG-01/02/06/07: logic chunk (2a) — untouched here.

## Checks run (stage-allowed only)

- `flutter analyze lib/features/pocket_money test/features/pocket_money/pocket_money_setup_view_test.dart test/features/pocket_money/p06_bugs_test.dart`
  → `No issues found!`
- `flutter test test/features/pocket_money/pocket_money_setup_view_test.dart`
  → `All tests passed!` (52/52, incl. the 2×3×2 theme/width/scale matrix,
  6 alignment variants, and the failure/write-through/nav groups).
- `flutter test test/features/pocket_money/p06_bugs_test.dart`
  → `All tests passed!` (+14 ~1: un-skipped BUG-01/02/04/05/06/07 green;
  BUG-03 remains the ~1 skip by design).
- `dart format` on the feature + owned tests → 1 file re-wrapped, stable.
- Full-app `flutter test` and the simulator NOT run (integrator owns them).

## LEFT FOR NEXT ITERATION

- None in the UI layer. BUG-03's widget-test closure rides on the
  SHARED_REQUEST (shared `NestChip` day variant), and review #6's remaining
  literal sizes ride on the same request.

VERDICT: PASS
