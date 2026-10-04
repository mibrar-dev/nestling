# K01 · Who's playing? — Stage 2b (BUILD, UI CHUNK, iteration 2)

Fixes applied for `FIXES_1.md` — UI/layout/copy items only; bloc-owned
FIXES_1 items (BUG-3) and the BUG-2 assertion semantic remain with the
other stages (see "LEFT FOR NEXT ITERATION").

## FIXES_1 items resolved in code

- **BUG-A (apostrophe bytes)**: the title in
  `profile_picker_view.dart` now uses ASCII `'`, byte-identical to
  `design/html-source/screens/K01-profile-picker.html` (U+2019 was the
  plan's error). `k01_copy_parity_test.dart`'s two deliberately-red
  copies now pass; every drawn-string assertion across
  `k01_bugs_test.dart`, `k01_profile_picker_matrix_test.dart`,
  `k01_copy_fit_test.dart`, `k01_profile_picker_view_test.dart`
  repointed at the ASCII form (per the FIXES_1 follow-on list).
- **BUG-1 (3+ children collapse the tile row)**: `_PickerLoaded` now
  branches — ≤2 profiles keep the single full-width `Row` of `Expanded`
  tiles at 167 px (390) / 132 (320); **3+** tiles get `_OverflowTileRow`,
  a horizontal `SingleChildScrollView` where each tile is fixed at the
  two-up width (`(bandW − 16) / 2`, ≥ 132 compact minimum), never
  squashed. The three parked tests are un-skipped and pass.
- **BUG-2 (two-finger burst stacks two routes)**: screen-level
  `_navPending` latch in `ProfilePickerView` (now a StatefulWidget) gates
  the `BlocListener` navigation — at most ONE push per gesture burst;
  released when the route pops or when selection fails (toast channel).
  DECISION NEEDED (see below): the parked test's assertion is stricter
  than the FIXES_1 suggestion; left with `skip: true`.
- **BUG-4 (empty nickname ⇒ unlabelled tile)**: `ProfileTile` falls back
  to the spoken label `Kid` (`Kid, Age 7–9` when a band exists); the
  parked test is un-skipped and passes.
- **BUG-5 (Try again cannot recover from a profiles failure)**:
  healed at the view layer — when the failure status arrives for a
  profiles-only failure, a later successful roster emission renders the
  loaded UI even though the shared `copyWithProfiles` does not restore
  `loaded` (TODO(K01): drop the branch after the bloc restores status
  or clears `errorMessage` together, stage 4 finding 2). The parked test
  is un-skipped and passes.
- **D1 + D2 (tiles +16.5 px / caption +34 px low)**: the caption's
  bottom reserve is now `NestSpacing.s8` **plus**
  `NestDevice.homeH` (34), because the running app
  `NestHomeIndicator` reserves no space (P01 BUG-2) and
  `NestStatusBar`'s top reserve is already there; the flex-centred
  tiles band re-centres on the design values.

## Tests moved to green

- Parked k01_bugs tests un-skipped: `BUG-1 ×3`, `BUG-4`,
  `BUG-5` → green (with the missing `disposeApp(tester)` drains added to
  the three BUG-1 proofs, same P01 BUG-2 style as every pending Drift
  stream-close). The `BUG-2` and `BUG-3` parked tests stay parked.
- `k01_bugs_test` (18 pass, 2 skip), `k01_copy_parity_test` (13),
  `k01_copy_fit_test` (7), `k01_profile_picker_matrix_test` (46),
  `k01_profile_picker_view_test` (13), `k01_profile_picker_geometry_test`
  (4), `k01_bloc_paths_test` (19), `kid_home_view_test` (87) —
  all green as of this iteration.

## K01 remains consistent

- Analyser: `flutter analyze lib/features/kid_home` — no issues.
- Format: `dart format` clean on touched files.
- Matrix bottom-edge/meadow probes updated for the landed shared
  twotone meadow (`shared/kid_meadow`): samples at y 838 now expect the
  hill-front bake `kidHillFront(kidMeadow, surface)` (204/30, 65, 56),
  matching the design PNGs. This was the D3/D4 shared fix, not a K01
  layout change.

## LEFT FOR NEXT ITERATION

- **K01-BUG-3 — a tile is dead after returning from a kid route**: the
  `==`-equal `selectedProfileId` re-emit is dropped by the bloc. Fixable
  only in the bloc/state layer (e.g. a `selectionNonce` bump on every
  selection, or clearing the one-shot on the push's pop event from the
  view via a new bloc event). Left with the logic chunk; the parked
  proof sits next to it.
- **K01-BUG-2 assertion semantics**: the stage-3/6 parked assertion
  expects top-route absence of `K02 Kid PIN`, i.e. it demands routes go
  to `/kid-home` for a simultaneous-tap burst; the FIXES_1-suggested
  screen-level latch (implemented) pins one push to the *first*
  selection instead. Both collapse stacking, but the test only accepts
  one reading. Needs an orchestrator ruling to un-skip.
- **D3/D4 (meadow two-tone)** are shared (`shared/kid_meadow`, landed in
  `cb66ae2`-era main), already covered by the matrix's pixel probes.

VERDICT: PASS
