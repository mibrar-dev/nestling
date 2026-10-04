# 2a BUILD LOGIC — K02 Kid PIN (`kid_home`, iteration 2)

## CONTRACT CHANGES

None. Event/state names remain exactly per `1_plan.md` §(b):

- Event: `KidHomePinSubmitted({required childId, required pin})`
- State: `pinChecking=false`, `pinWrongNonce=0`, `pinPassed=false`
- Semantics the UI builder relies on (all pinned by tests, unchanged):
  handler uses the event's own `childId` (never re-resolves the active
  child); a wrong attempt on a failed load keeps `status == failure`
  (retry card survives); a submit before the load lands still resolves
  (`status` stays `initial`, `pinPassed` flips).

## FIXES_1 triage — items in the logic layer

Logic layer = `domain/**`, `data/**`, `presentation/bloc/**`, DI/route
registration, and `test/features/kid_home/` files whose names contain
`bloc`/`cubit`/`repository`/`data`. Result: **no logic-layer defect**;
no product-code edit was needed this iteration.

- **3_test's 3 bloc tests** (`kid_home_bloc_test.dart:1540-1605`, added by
  the test stage to my owned file): event-child-id passthrough, wrong
  attempt preserves the failure card, pre-load submit resolves. All three
  pass against the iteration-1 handler unmodified — the handler already
  implements exactly these semantics. No fix required.
- **Skipped bug tests**: the 4 `skip: true` proofs live in
  `k02_bugs_test.dart` (a view-layer file, outside my owned set) and all
  four bugs sit in `presentation/views/kid_pin_view.dart` or shared
  `core/` (`NestKeypad` pitch, `nest_toast`, grapheme-safe initial
  helper). There is **no skipped test and no open bug in the logic
  layer**, so there is nothing to un-skip or fix here. K02-BUG-1..4 are
  the UI builder's (one-line view fixes per `6_bugs.md`) + the
  orchestrator's (SHARED_REQUEST #2/#3, both already filed in
  `docs/screens/K02/SHARED_REQUEST.md` by the test stage).
- **4_review findings 1–4**: #1 (SHARED_REQUEST.md missing) was resolved
  by the test stage — the file exists with all three items; nothing in
  my layer to record. #2 (4th-digit null-child revert), #3 (pill/key
  shape rects in `kid_pin_view_test.dart`), #4 (`NestHomeIndicator`
  reserve) are all view/test files owned by the UI builder.
- **5_ui deviations 1–3** (keypad pitch + downstream caption shift):
  shared `NestKeypad` fix already on `main` (`b1bfb4e`) and merged into
  this branch (`c094fd5`); the remaining call-site follow-up
  (`fit: NestKeypadFit.shrinkWrap` at `kid_pin_view.dart:261`) is a view
  edit — UI builder's. Per ORCHESTRATOR_NOTES (07:13) and the plan,
  K02 takes the component as-is; no local logic change.
- **Main merge (`c094fd5`) impact on my layer**: none — `git log` shows
  no change to `presentation/bloc/` since the iteration-1 checkpoint;
  analyze + owned tests re-verified green on the merged tree (below).

## Files changed (this iteration)

None in `app/`. The iteration-1 logic implementation
(`kid_home_event.dart` + `KidHomePinSubmitted`,
`kid_home_state.dart` + `pinChecking`/`pinWrongNonce`/`pinPassed`
threaded through every constructor and `props`,
`kid_home_bloc.dart` + `_onPinSubmitted` with re-entry guard and
completion-time outcome) stands as-is. Only this stage file is
written/overwritten.

## Gates (run on the merged tree, `app/`)

| gate | command | result |
|---|---|---|
| analyze | `flutter analyze lib/features/kid_home` | No issues found! |
| test (owned files) | `flutter test test/features/kid_home/kid_home_bloc_test.dart test/features/kid_home/kid_home_repository_test.dart` | +55: All tests passed! (52 iteration-1 + 3 test-stage PIN tests) |
| format | `dart format --set-exit-if-changed --output=none lib/features/kid_home test/.../kid_home_bloc_test.dart test/.../kid_home_repository_test.dart` | 0 changed |
| scope | `git status`/`git diff` | no `app/` modification by this stage; no views/widgets touched; no simulator used |

No `google_fonts`, no `DateTime.now()` in the layer; clock N/A.

## LEFT FOR NEXT ITERATION

- Nothing in the logic layer. Open work is UI-builder-owned
  (K02-BUG-1..4 view fixes, review findings 2–4, keypad `shrinkWrap`
  call-site + re-measure) and orchestrator-owned (SHARED_REQUEST #1
  `kidSay`/`kidMark`, #3 grapheme helper). Integrator owns full
  `flutter test`, screenshots, and the UI check.

VERDICT: PASS
