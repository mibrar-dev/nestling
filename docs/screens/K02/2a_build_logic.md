# 2a BUILD LOGIC — K02 Kid PIN (`kid_home`, iteration 3)

## CONTRACT CHANGES

None. Event/state names remain exactly per `1_plan.md` §(b):

- Event: `KidHomePinSubmitted({required childId, required pin})`
- State: `pinChecking=false`, `pinWrongNonce=0`, `pinPassed=false`
- Semantics the UI builder relies on (unchanged, pinned by tests):
  handler uses the event's own `childId`; a wrong attempt on a failed
  load keeps `status == failure`; a pre-load submit still resolves;
  re-entry while `pinChecking` is dropped; the outcome is built from the
  state at completion time.

## FIXES_2 triage — items in the logic layer

Logic layer = `domain/**`, `data/**`, `presentation/bloc/**`, DI/route
registration, and `test/features/kid_home/` files whose names contain
`bloc`/`cubit`/`repository`/`data`. Result: **no logic-layer defect**;
no product-code edit was needed this iteration.

- **The `k02_bugs_test.dart` hang** (ORCHESTRATOR_NOTES 10:32, multi-cycle
  pumps leaking `AppSession`'s Drift watch into the fake-async queue):
  already fixed by the test stage (complete cycles via fresh
  `setUpTestScope()`); that file is a view-layer test file outside my
  owned set. Nothing to do here. My owned files finish in ~4 s.
- **K02-BUG-5 (new, parked, `skip: true`)** — read the proof
  (`k02_bugs_test.dart:449-480`) and the mechanism
  (`kid_pin_view.dart:36,72-73`): the latch is the view-local
  `_noPinHandled` flag. Leo→Maya in one turn sets it before the BUG-3
  re-check declines; when Leo returns, the flag is still set and the
  auto-advance never re-fires. The correct fix is view-local (reset
  `_noPinHandled` on the declined path) in `presentation/views/**`,
  which the UI builder owns and I must not touch. No bloc/state change
  can fix a view-local flag without a view edit anyway, so there is no
  logic-layer half to take. **Left for the UI builder** (un-skip +
  proof live in their file).
- **K02-TEST-BUG-A (avatar-initial crash class on K01/K03)** —
  `presentation/widgets/profile_tile.dart:96` and
  `presentation/views/kid_home_view.dart:364` are both UI-builder-owned
  paths; the permanent fix is SHARED_REQUEST #3 (`core/`,
  orchestrator-owned, already filed). Not my layer.
- **New view tests** (`kid_pin_view_test.dart` 47→54) and the un-skipped
  regression proofs for K02-BUG-1..4 / review #2 / #4 / keypad pitch —
  all in view-layer files. Nothing in my owned files was added or
  required.
- **SHARED_REQUEST #1 / #3** stay open with the orchestrator (`core/`
  typography + grapheme helper). No logic-layer item to record.

## Files changed (this iteration)

None in `app/`. The iteration-1 logic implementation
(`kid_home_event.dart` + `KidHomePinSubmitted`,
`kid_home_state.dart` + `pinChecking`/`pinWrongNonce`/`pinPassed`
threaded through every constructor and `props`,
`kid_home_bloc.dart` + `_onPinSubmitted` with re-entry guard and
completion-time outcome) stands as-is. Only this stage file is
written/overwritten.

## Gates (merged tree, `app/`)

| gate | command | result |
|---|---|---|
| analyze | `flutter analyze lib/features/kid_home` | No issues found! |
| test (owned files) | `flutter test --timeout 120s test/features/kid_home/kid_home_bloc_test.dart test/features/kid_home/kid_home_repository_test.dart` | +55: All tests passed! |
| format | `dart format --set-exit-if-changed --output=none lib/features/kid_home test/.../kid_home_bloc_test.dart test/.../kid_home_repository_test.dart` | 0 changed |
| scope | `git status --short -- app/` | empty — no `app/` modification by this stage; no views/widgets touched; no simulator used |

No `google_fonts`, no `DateTime.now()` in the layer; new rows: none
(IDS rule N/A); clock N/A.

## LEFT FOR NEXT ITERATION

- Nothing in the logic layer. Open work is UI-builder-owned
  (K02-BUG-5 `_noPinHandled` reset + un-skip, K02-TEST-BUG-A sibling
  sites alongside the orchestrator's shared helper) and
  orchestrator-owned (SHARED_REQUEST #1, #3). Integrator owns full
  `flutter test`, screenshots, and the UI check.

VERDICT: PASS
