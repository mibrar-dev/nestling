# K01 · Who's playing? — Stage 4 QA code review (iteration 2)

Reviewed the cumulative `git diff main...HEAD` after the iteration-2
build (K01-BUG-1..5 fixes, D1/D2 home-reserve, shared kid background).
Analyzer: `No issues found!`. `flutter test test/features/kid_home/`:
307 passed, 2 skipped.

## Findings

1. **major** — K01-BUG-3 is not actually fixed in product code. The
   `KidHomeSelectionHandled` event exists and the bloc consumes it
   (kid_home_bloc.dart:146-157, kid_home_state.dart:105-117), but nothing
   in `lib/` ever dispatches it — `_ProfilePickerViewState`'s selection
   listener (app/lib/features/kid_home/presentation/views/profile_picker_view.dart:35-63)
   pushes the route and never sends the event. The one-shot
   `selectedProfileId` therefore still clears only via a home-stream
   emission, and a repeated tap on the same tile is dropped by the
   `listenWhen: previous.selectedProfileId != current.selectedProfileId`
   guard. Proof: `flutter test --run-skipped --plain-name K01-BUG-3
   app/test/features/kid_home/k01_bugs_test.dart` fails —
   `bloc.state.selectedProfileId` is still `'maya'` after back and the
   second tap never navigates. **Fix:** in the listener, right after
   starting the push, dispatch
   `context.read<KidHomeBloc>().add(const KidHomeSelectionHandled());`
   (the handler keeps navigation out of the bloc), then un-skip the
   proof test. The current unit tests in
   `k01_bloc_paths_test.dart:495/527/556` only dispatch the event by
   hand, which is why suite-green hid this.

2. **minor** — the K01-BUG-5 view-level heal masks the wrong failure.
   `profile_picker_view.dart:80-85` renders `_PickerLoaded` whenever
   `state.status == failure && state.profiles.isNotEmpty`, but the bloc
   deliberately keeps `failure` when the *home* stream died while a
   stale roster is present (kid_home_bloc.dart:171-174 checks
   `state.child == null`, and `_onProfilesReceived` only restores
   `loaded` when `_homeSub != null`). In that case the picker shows the
   roster instead of "Oh no! Pip got lost.". **Fix:** gate the heal on
   the profiles-caused outage only — e.g. expose a
   `KidHomeState.loadErrorFrom`/`profilesFailed` flag from the bloc
   instead of re-deriving it from `profiles.isNotEmpty`.

3. **minor** — skipped proofs are now stale in both directions.
   `k01_bugs_test.dart:341` (K01-BUG-2) still asserts the pre-fix
   double navigation and fails now that `_navPending` works; invert it
   to assert single-flight (one top route) or drop it. K01-BUG-1/4/5
   proofs were converted to passing tests — this one wasn't.
   (`--run-skipped` currently reports exactly BUG-2 + BUG-3 failing.)

4. **minor** — title copy regressed from the plan's curly apostrophe to
   ASCII (`"Who's playing?"`, profile_picker_view.dart:278). All current
   K01 tests and `k01_copy_parity_test.dart` pass because they were
   updated to the fixture's ASCII, but `1_plan.md` §0 and the stage-2
   convention note (P02/P03/P04/P07 all ship U+2019) say the opposite.
   **Fix:** get the explicit orchestrator ruling recorded; whichever
   wins, update `1_plan.md` §0 vs `k01_copy_parity_test.dart` so the
   record stops contradicting itself.

5. **minor** — out-of-scope edit:
   `app/test/design_system/list_row_trailing_test.dart` (formatting
   only) was touched in this branch despite RULES.md §1 limiting K01 to
   `kid_home`. Harmless formatter sweep; fold it into a main update
   instead of this branch.

## Re-verified clean this pass

- K01-BUG-1: `_OverflowTileRow` keeps tiles at the design width
  (`(maxWidth - s4)/2` = 167 @390, 132 @320) and scrolls horizontally;
  the ellipse-clamp defect is gone.
- K01-BUG-4: empty nickname falls back to label `Kid`
  (profile_tile.dart:53-55).
- K01-BUG-5: bloc restores `loaded` via `copyWithProfilesRecovered`
  (kid_home_state.dart:206-221) and clears the stale load error; Try
  again now emits `loading` when the home subscription is still live
  (kid_home_bloc.dart:73-79). Both skipped-proof repro paths pass once
  the view-masking in finding 2 is accounted for.
- Streams cancelled on `close()`; `_profilesFailed` flag cleared on
  every healthy roster; no `DateTime.now()`/`google_fonts`/tracking
  additions; D1/D2 fix uses `NestDevice.homeH` and the shared
  `KidScope`/`kid_meadow` (no local hills — per the new
  ORCHESTRATOR_NOTES); CHILD ORDER and per-child `PipAvatar` intact;
  two-finger navigation single-flighted by `_navPending`.

VERDICT: FAIL
