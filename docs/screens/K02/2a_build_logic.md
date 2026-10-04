# 2a BUILD LOGIC — K02 Kid PIN (`kid_home`, iteration 4)

## CONTRACT CHANGES

None. Event/state names remain exactly per `1_plan.md` §(b):

- Event: `KidHomePinSubmitted({required childId, required pin})`
- State: `pinChecking=false`, `pinWrongNonce=0`, `pinPassed=false`
- Semantics the UI builder relies on (unchanged, pinned by tests):
  handler uses the event's own `childId`; a wrong attempt on a failed
  load keeps `status == failure`; a pre-load submit still resolves;
  re-entry while `pinChecking` is dropped; the outcome is built from the
  state at completion time.

## FIXES_3 triage — items in the logic layer

Logic layer = `domain/**`, `data/**`, `presentation/bloc/**`, DI/route
registration, and `test/features/kid_home/` files whose names contain
`bloc`/`cubit`/`repository`/`data`. Result: **no logic-layer defect**;
no product-code edit was needed this iteration.

- **K02-BUG-5 (fixed by the iteration-3 UI build)**: the latch release
  (`setState(() => _noPinHandled = false)` on the declined path) is a
  view-local edit in `presentation/views/kid_pin_view.dart`, owned by
  the UI builder. The test stage explicitly records "No new bloc test:
  the bloc contract this screen depends on is already pinned end to
  end" (13 `KidHomePinSubmitted` tests in `kid_home_bloc_test.dart` +
  the DB-backed no-PIN rule in `kid_home_repository_test.dart`). No
  logic change, no contract change — verified, nothing to add.
- **K02-TEST-BUG-A (still open)**: `profile_tile.dart:96`
  (presentation/widgets) and `kid_home_view.dart:364`
  (presentation/views) are UI-builder-owned paths; the permanent fix is
  SHARED_REQUEST #3 (`core/` grapheme helper, orchestrator-owned,
  already filed). Not my layer — recorded, not patched.
- **Sibling `k02_bugs_test.dart` churn** (TRIAL-gate probe redness while
  the bugs stage edited the file): view-layer test file, resolved by
  that stage; the TRIAL guard and router redirect were independently
  verified sound. No logic involvement.
- **SHARED_REQUEST #1 / #3** stay open with the orchestrator. No
  logic-layer item to record.

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

- Nothing in the logic layer. Open work is orchestrator-owned
  (SHARED_REQUEST #1 `kidSay`/`kidMark`, #3 `nestAvatarInitial`) plus
  the K01/K03 loops' two live crash sites. Integrator owns full
  `flutter test`, screenshots, and the UI check.

VERDICT: PASS
