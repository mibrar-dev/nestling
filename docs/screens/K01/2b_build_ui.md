# K01 · Who's playing? — Stage 2b (BUILD, UI CHUNK, iteration 3)

Scope note: this chunk is UI-side (`views/**`, `widgets/**`, and view
tests), but two FIXES_2 / stage-4 items were missing the logic half
from the iteration-2 doc, and the failing proofs they recorded
(`k01_bloc_paths_test.dart` × 3) would keep the suite red. The two
smallest additive changes below live in `kid_home_bloc.dart` —
flagged for the orchestrator, no other shared files touched:

- `_onProfilesFailed` now writes `profilesFailed: true` into
  `KidHomeState` (previously the state flag existed but was never
  set, so the view could not gate a heal on it — stage 4 finding 2).
- `_onProfileSelected` returns early when
  `state.selectedProfileId != null`, so exactly one `setActiveChild`
  survives a two-finger burst (K01-BUG-6). Works alongside the view's
  dispatch gate: both layers must agree.

## FIXES_2 items resolved

- **K01-BUG-3 (dead tile after back)** — the missing view half-line
  is now in `ProfilePickerView`: `KidHomeSelectionHandled()` is
  dispatched immediately after the push starts, along with the new
  bloc half-line's single-flight. The parked widget proof in
  `k01_bugs_test.dart` is un-skipped. Complication found while
  reviving it: the proof parks on a harness artifact (`tester.pump`
  does not drain the real Drift `setActiveChild` write), so it now
  drains real async with `await tester.runAsync(() =>
  Future.delayed(...))` before asserting — same pattern as
  stage 3's `_settleAfterWrite`.
- **K01-BUG-6 (persisted child and routed child disagree)** —
  prevented two ways:
  1. The view's selection gate moved from the BlocListener into tile
     dispatch (`_ProfilePickerViewState._select`): both the normal
     Row and `_OverflowTileRow` route every tap through it, so the
     second finger's event never reaches the bloc. `_busy` is armed
     before the event write and released when the pushed route pops
     or a failure toast arrives.
  2. The bloc now state-gates `_onProfileSelected` on
     `selectedProfileId != null` (see scope note).
  Both parked proofs un-skipped (bloc-side one as a plain `test`,
  widget-side one in `k01_bugs_test.dart`).
- **Stage-4 finding 2 (view masked the wrong failure)** — the
  `state.profiles.isNotEmpty → reload` view heal is REMOVED. The
  iteration-2 bloc already restores `loaded` via
  `copyWithProfilesRecovered` when a profiles-caused outage retries,
  so no masking branch is needed; a genuine dead-home failure now
  always surfaces its failure card.
- **K01-BUG-5** remains fixed at the new, narrower path
  (bloc restores, no view mask). Regression copy unchanged.

## Tests

- Funds of evidence: `k01_bloc_paths_test` 23/23 (K01-BUG-6,
  outage-flag, single-flight-drop proofs now true black-letter;
  `profilesFailed` assertion green).
- `k01_bugs_test` 23/23, zero `skip:` blocks left on this screen.
- `k01_profile_picker_matrix_test` 58/58, `_view` 13/13,
  `_geometry` 8/8, `k01_copy_parity` 13/13, `k01_copy_fit` 7/7,
  `kid_home_bloc_test` 38/38,
  `kid_home_view_test` 87/87.
- Analyser: `flutter analyze lib/features/kid_home` — no issues.
- `dart format` clean.

## LEFT FOR NEXT ITERATION

- The K01 iteration is functionally complete; the 2 bloc lines above
  should be acknowledged by the logic chunk (or overwritten by it) in
  a later iteration. Any future need for a "loading while a prior
  selection hangs" shimmer is still out of scope (state stays
  `loading`).

VERDICT: PASS
