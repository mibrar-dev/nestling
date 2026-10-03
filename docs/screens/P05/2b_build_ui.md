# P05 · Add children — UI build (STAGE 2b, iteration 6)

Scope: `features/family/presentation/views/**`,
`presentation/widgets/**`, widget/view tests in
`app/test/features/family/**` (names containing `view`/`widget`).
No `domain/`, `data/`, `bloc/` files touched.

## CONTRACT

`2a_build_logic.md` reports NO contract changes: `FamilyBloc` events/states
are exactly what `add_children_view.dart` already consumes
(`FamilyLoadRequested`, `FamilyDraftChanged`, `FamilyAddChildRequested`,
`children`, `draftNickname`/`draftAgeBand`/`draftAvatarColour`,
`nicknameError`, `saveInProgress`, `lastSavedNickname`, `status`).
No UI rework required on that front.

## FIXES_5.md dispositions

1. **Chip row 44 px in flow (the one remaining defect)** — shared
   `NestChip` batch-2 fix has landed on main (32 px pill in the flow,
   ≥44×44 tap area overlaid per `SPACING_SPEC` §10.6). Rel-verified:
   - Local workaround already removed in `add_child_form_card.dart`
     (no `IntrinsicWidth`; the `Wrap` lays chips in one row directly).
   - Flipped `add_children_test.dart` expectation
     `the chip row height is the design value plus the 44-px tap box` →
     `... is the design value (32 px, shared fix landed)`: asserts
     `chip.height == NestSpacing.s8` (32). This removes the +12 px shift of
     the swatch row, its label, and the helper caption that FIXES_5 §1
     recorded (band5 drift 10.8–11.1%).
   - Tap-target test updated: age chips now assert the design geometry
     (≥44 wide, 32 high) with the overlay hit area documented, instead of
     the old 44-in-flow box.
   - `the failure panel Try again button is a 44+ target` passes again
     once the two stale expectations above are corrected (it was collateral
     of their in-test state, passes identically in isolation and group).
2. [Pass, kept] Child order Maya-then-Leo verified green via
   `p05_bugs_test.dart` + bloc tests (durable `createdAt` ordering landed
   on main; P05 consumes the shared helper).
3. [Pass, kept] Copy character-exact vs HTML; no overflow at 300+ widths
   and text scale 1.3 (pinned by existing group tests).
4. [Pass, kept] Owner rules: bottom bar to the physical edge both modes,
   20 px gutters, dark tokens; `flutter analyze lib/features/family` → no
   issues; no `google_fonts`/`GoogleFonts` anywhere.

## Shared with logic builder (LEFT FOR INTEGRATOR)

- `kid_card_grid.dart` comment refreshed "rowid-ordered" →
  "creation-ordered (createdAt, rowid)" — done, one-liner.
- Child-order `SHARED_REQUEST.md` entry: orchestrator closes it once the
  UI gate confirms Maya-first on a merged build.

## Verification

- `flutter test test/features/family` → **119 passed** (was 116 + 3 red
  chip-geometry pins from the pre-fix component; now 119 green).
- `flutter analyze lib/features/family` → No issues found!

## LEFT FOR NEXT ITERATION

- UI gate (integrator): re-run `tools/screens/shot.sh` light/dark vs the
  design PNGs — expect band5 drift (swatches + caption shift) to collapse
  now that the chip row is 32 px; confirm Maya-first from the database.

VERDICT: PASS
