# Chip wrap hit area — REPORT (branch `shared/chip_wrap_hit_area`)

Scope: give chips inside a tight row the full 44 px tap target without
changing the 32 px layout (P05 bug P05-BUG-11; also affects P06 payout-day
chips and every chip row). Minimal, backward-compatible shared change:
one new widget + one shared constant, no screen-code edits, no public API
renames. Screen branches merge and compile without edits.

## Files changed

- `app/lib/core/design_system/components/nest_chip.dart` — added public
  `NestChip.hitSlop` (`(44 - 32) / 2 = 6`, derived from tokens, no
  duplicated number) and documented in the class comment:
  "chips in a row: use NestChipWrap".
- `app/lib/core/design_system/components/nest_chip_wrap.dart` — NEW public
  `NestChipWrap` (same chip-row API as `Wrap`: children, spacing,
  runSpacing, alignment, crossAxisAlignment) + `RenderNestChipWrap`
  extending `RenderWrap`. Layout is exactly `Wrap` (no layout overrides),
  so no screen moves. Only `hitTest` is widened: points up to
  `NestChip.hitSlop` outside all four sides are passed to
  `hitTestChildren`, and gap/outer-slop taps fall back to the nearest chip
  (forwarded to the chip centre, which is always inside the stadium —
  a clamped edge point can land outside the rounded ends and be rejected
  by the InkWell's shape-aware hit test). Covers single rows too: a
  one-run `NestChipWrap` behaves like a `Row`, so no separate
  `NestChipRow` was added (simpler option chosen, documented on the class).
- `app/lib/core/design_system/design_system.dart` — exports the new file.
- Tests: NEW `app/test/core/design_system/nest_chip_wrap_test.dart`.

## What / why

`NestChip` lays out 32 px high with a 44 px hit area via `_ExpandedHitBox`.
But Flutter hit testing stops at the first ancestor whose bounds do not
contain the point, and a `Wrap`/`Row` of chips is exactly 32 px high per
run — taps 5 px above/below never reach the chip (measured on P05 at
390×844). `NestChipWrap` fixes this at the row level without changing
layout size, and also makes the 8 px inter-chip gaps tappable (nearest
chip) and the left/right ends meet the 44 px minimum for narrow chips.

## Tests added (`nest_chip_wrap_test.dart` → `NestChipWrap`)

- `tap 5 px above the row selects the first chip`
- `tap 5 px below the row selects the first chip`
- `tap 2 px left of the first chip selects it`
- `laid-out size equals a plain Wrap with same children`
- `tap in the 8 px gap selects a neighbouring chip`
- `two runs with runSpacing 8 have no dead spots between runs`
  (sweeps the full run width in the middle of the runSpacing gap; every
  tap selects a chip).

## Where screens use Wrap/Row of NestChip today (grep `app/lib/features`)

Screens should switch interactive chip rows to `NestChipWrap`
(same props). Static (non-interactive) chips need no change.

- `app/lib/features/design_system_gallery/presentation/widgets/pip_lab_controls.dart:24`
  `Wrap(spacing: 8, runSpacing: 8)` of interactive `NestChip`
  (`PipLabMoodChips`) → switch to `NestChipWrap`.
- `.../pip_lab_controls.dart:53` same (`PipLabSkinSwatches`) → switch.
- `.../pip_lab_controls.dart:91` same (`PipLabAccessoryChips`) → switch.
- `app/lib/features/design_system_gallery/presentation/widgets/gallery_parent_a.dart:178`
  `Wrap(spacing: s2, runSpacing: s2)` of interactive `NestChip`
  (`_ChipsDemo`) → switch.
- `app/lib/features/onboarding/presentation/views/value_tour_view.dart:40`
  `_headChip` (static `NestChip`, `onSelected: null`) used in `Row`s at
  lines 348, 405, 500 — static, no tap target, no action needed unless
  made interactive.
- P05 age chips (P05-BUG-11) and P06 payout-day chips per the task brief:
  not present as `NestChip` rows on `main` in this worktree (no matches
  outside the files above); when those screens land, build chip rows with
  `NestChipWrap` from the start.

Follow-up for screens: replace the four interactive `Wrap`s above with
`NestChipWrap` (drop-in: same `spacing`/`runSpacing`/`children`); no
layout re-measurement needed (size identical to `Wrap` by test).

## Verification

`cd app && dart format .` clean, `flutter analyze` → No issues found!,
`flutter test` → all pass (700 green).

VERDICT: PASS
