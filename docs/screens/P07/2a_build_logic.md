# P07 Paywall — Stage 2a logic chunk (iteration 4)

Scope: non-UI layer only — `domain/**`, `data/**`, `presentation/bloc/**`,
DI/route registration, and unit/bloc tests. Views/widgets untouched (the
parallel UI builder owns them).

## CONTRACT CHANGES

None. No event/state/interface change this iteration: the `readSubscription()`
addition and the BUG-12 guard from iteration 3 stand unchanged, and the UI
builder codes against the same names.

## Files changed

None — the logic layer required no edits this iteration. FIXES_3 contains
zero logic-layer items (see below); the layer was re-verified as-is:

- `app/lib/features/paywall/domain/paywall_repository.dart` — unchanged
  (`readSubscription()` with the `watchSubscription().first` default).
- `app/lib/features/paywall/data/paywall_repository_impl.dart` — unchanged
  (one-shot SELECT override, upsert writes, HTML-exact plan copy).
- `app/lib/features/paywall/presentation/bloc/paywall_bloc.dart` —
  unchanged (trial/restore actions, active-subscription guard with
  fail-open, double-tap `working` guard, `copyWith(clearError:)`).
- `app/test/features/paywall/paywall_bloc_test.dart` — unchanged (30
  tests, including stage 3's one-shot-budget test for `readSubscription`).

Two one-line `readSubscription` stubs added in iteration 3 to the view-test
and bug-hunt fakes were left untouched (they compile and behave identically).

## Items done (FIXES_3, logic layer only)

- P07-BUG-13 (major, legal-link labels 13 px above the separator baseline)
  — NOT this layer: the defect is paragraph geometry inside `_LegalLink`
  (`paywall_view.dart:795-836`), unreachable from domain/data/bloc. Proof
  re-ran with `--run-skipped` and fails exactly as documented
  (`Expected: 757.25 / Actual: 744.25`); it stays `skip: true` for the UI
  builder's view fix. Un-skipping it here would only turn the suite red.
- UI deviation 1 (4th-benefit wrap → plan tag clipped) — font-metrics
  fidelity, explicitly not fixable by shrinking text or editing copy;
  design-system level at most. Not this layer; no logic change can move it.
- UI deviation 2 (separators below the link baseline) — `Wrap`-run box
  geometry in the view. Not this layer.
- UI deviation 3 (title orphan "days") — accepted/engine-level. Not this
  layer.
- P07-BUG-8/9 — shared code, remain `skip: true`, `SHARED_REQUEST.md`
  filed. Untouched.
- Stage 6's audit of this layer ("`_alreadySubscribed()` reads once,
  fails open, keeps the double-tap guard, emits `success(restore)` for an
  active family") is accurate; no follow-up needed.
- No `google_fonts`/`GoogleFonts` in the feature; ORCHESTRATOR_NOTES
  item 1 holds on both success paths.

## Evidence (`app/`)

- `flutter analyze lib/features/paywall
  test/features/paywall/paywall_bloc_test.dart` → No issues found!
- `flutter test test/features/paywall/paywall_bloc_test.dart` → +30,
  all passed.
- `p07_bugs_test.dart --plain-name '[P07-BUG-13]' --run-skipped` →
  fails as documented (view defect, still open, still skipped).

## LEFT FOR NEXT ITERATION

Nothing in the logic layer. P07-BUG-13's view fix (centre the link label
without expanding the `Wrap` run) plus un-skipping its proof belongs to
the UI builder; whole-app `flutter test` and simulator shots belong to
the integrator.

VERDICT: PASS
