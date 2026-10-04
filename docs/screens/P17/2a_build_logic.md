# P17 Parental gate — 2a build logic (iteration 1)

Scope: non-UI layer only — `domain/**`, `data/**`,
`presentation/bloc/**`, plus unit/bloc tests whose names contain
`bloc`/`repository`/`data`. No view/widget edits; no DI/route edits
(already registered); no simulator use.

## CONTRACT CHANGES

None. Event/state shapes are exactly the plan's (`1_plan.md` §(b)):
`ParentalGateDigitEntered(String digit)`, `ParentalGateDeletePressed`,
`ParentalGateUnlockAcknowledged`; state adds `entered`/`attempts`/
`unlocked` plus `challenge`/`expectedLength`/`isComplete` helpers.
One deliberate hardening inside the contract: `isComplete` is
`expectedLength > 0 && entered.length == expectedLength` so a disabled
gate (`items` empty, length 0, entry `''`) never reads as complete.

## Files changed

- `app/lib/features/parental_gate/presentation/bloc/parental_gate_state.dart`
  — added `entered` (default `''`), `attempts` (0), `unlocked` (false)
  with `copyWith`/`props`; helpers `challenge`, `expectedLength`,
  `isComplete`. Stream reloads preserve entry state via `copyWith`
  (only `status`/`items` are overwritten on new emissions).
- `app/lib/features/parental_gate/presentation/bloc/parental_gate_event.dart`
  — added `ParentalGateDigitEntered`, `ParentalGateDeletePressed`,
  `ParentalGateUnlockAcknowledged`.
- `app/lib/features/parental_gate/presentation/bloc/parental_gate_bloc.dart`
  — handlers: digit appends (single `0`–`9` char, loaded + challenge +
  box-free guard); full entry auto-verifies (correct → `unlocked: true`,
  wrong → cleared + `attempts + 1`); extra digits and input while
  `unlocked` ignored; delete drops last char (no-op empty);
  acknowledge resets `unlocked` (no-op when already false).
- `app/test/features/parental_gate/parental_gate_bloc_test.dart` (new,
  17 tests) — state defaults/helpers/equality; `question`/`verify`/word
  map; load/empty/failure; digit-by-digit entry; correct unlock; wrong
  clears + attempts; extra-digit/non-digit/delete guards; acknowledge;
  pre-load and disabled-gate absorption.
- `app/test/features/parental_gate/parental_gate_repository_test.dart`
  (new, 5 tests) — `challengeFor(2026-01-06)` → `seven times six`/42;
  pinned demo day 2026-10-03 → `three times nine`/27 (matches plan §(b));
  all-day stability; enabled emits 1 challenge; disable → `[]`,
  re-enable → 1 challenge (real in-memory DB via `setUpTestScope`).
- Repository impl: NO changes (plan: Drift via existing
  `ParentalGateRepository` only).

## Items done (plan §(b) + §(f) logic half)

- State/events/bloc per §(b); all guards as specified.
- Bloc + repository tests per §(f) (widget/geometry/states tests are the
  UI builder's).
- `dart format` clean, `flutter analyze lib/features/parental_gate
  test/features/parental_gate` → No issues found, `flutter test
  test/features/parental_gate` → 22/22 pass (no `google_fonts`, no
  letterSpacing, no simulator).

## LEFT FOR NEXT ITERATION

- Nothing in this layer. UI builder owns views/widgets + widget tests;
  integrator owns full-app `flutter test` + screenshots.

VERDICT: PASS
