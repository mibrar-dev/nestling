# P04 · Privacy consent — STAGE 2a logic build (iteration 7)

Scope: non-UI layer only — `domain/**`, `data/**`, `presentation/bloc/**`,
DI/route registration, and `bloc`/`repository` unit tests. No edits to
`presentation/views/**` or `presentation/widgets/**`.

## CONTRACT CHANGES

None. Public names stable per `1_plan.md`: `PrivacyConsentLoadRequested`,
`PrivacyConsentCrashToggled(value)`, `PrivacyConsentState(status/items/
crashConsent/errorMessage)`, `PrivacyConsentRepository` (get/watch/set),
`registerPrivacyConsent`, `PrivacyConsentRoutePaths.privacy`. The UI builder
codes against these unchanged shapes.

Note (pre-existing, kept): `_onCrashToggled` uses the optimistic emit +
revert-to-stored (`_crashFrom(items)`) pattern that fixed P04-5/P04-8, rather
than the plan's original no-optimistic-emit sketch. No shape change.

## Files changed

None. The logic layer already implements the plan and every FIXES_6 item in
its scope (verified, not re-edited):

- `app/lib/features/privacy_consent/data/privacy_consent_repository_impl.dart`
  — transactional upsert (P04-1/P04-9), single-row guarantee, table defaults.
- `app/lib/features/privacy_consent/presentation/bloc/privacy_consent_bloc.dart`
  — optimistic toggle (P04-5), state-aware failure keeping prior items (P04-6),
  revert to `_crashFrom(items)` (P04-8), `emit.forEach` stream (no reload events).
- `domain/`, `privacy_consent_di.dart`, `privacy_consent_routes.dart` — unchanged,
  contract stable.
- `app/test/features/privacy_consent/privacy_consent_{bloc,repository}_test.dart`
  — unchanged, no `google_fonts` imports, no skips.

## FIXES_6 items — logic-layer triage

| Id | FIXES_6 status | Layer | Action this stage |
|---|---|---|---|
| P04-1 first-run opt-in dropped | FIXED (it. 2) | data (mine) | Verified: upsert + migration guarantee; repo tests green |
| P04-2 row-4 empty tile (`NestIcons.trash`) | OPEN, one-line wire-up | VIEW (UI builder) | Not mine — and already landed in this tree (`privacy_consent_view.dart:104-109` wires `NestIcons.trash`; bug proof header says FIXED it. 5, no `skip`) |
| P04-5 double-tap same value | FIXED (it. 2) | bloc (mine) | Verified: optimistic emit + serialised writes; bloc tests green |
| P04-6 failed OFF claimed "stays off" | FIXED (it. 2) | bloc+view | Bloc half verified (failure keeps prior items/consent); caption half is UI builder's |
| P04-7 dark shield (`NestPrivacyShield`) | OPEN, one-line wire-up | VIEW (UI builder) | Not mine — and already landed in this tree (`privacy_consent_view.dart:73-77` renders `NestPrivacyShield`; bug proof un-skipped, no `skip`) |
| P04-8 revert to unpersisted value | FIXED (it. 3) | bloc (mine) | Verified: revert target `_crashFrom(items)`; tests green |
| P04-9 overlapping writes keep earlier | FIXED (it. 4) | data (mine) | Verified: single transaction; deterministic proofs green |
| Cleanup: review findings 3/4 (local divider Stack) | cleanup | VIEW (UI builder) | Not mine — already landed (four direct `NestList` children, shared overlay) |

Skipped-bug-tests check: `p04_bugs_test.dart` in this tree carries **zero**
`skip:` markers (P04-2/P04-7 already un-skipped, headers read FIXED it. 5).
That file is outside my file-name scope (`bloc`/`cubit`/`repository`/`data`)
and imports the view, so I did not edit it; the UI builder owns its view
assertions.

## Verification (logic scope only)

- `flutter analyze lib/features/privacy_consent` → No issues found.
- `flutter test test/features/privacy_consent/privacy_consent_bloc_test.dart
  test/features/privacy_consent/privacy_consent_repository_test.dart` → 33 passed.
- `grep google_fonts|GoogleFonts` over `domain/`, `data/`, `bloc/`, and both
  owned test files → no matches. (The `google_fonts` import still present in
  `p04_bugs_test.dart:36` is outside my scope — flagged for the UI builder /
  integrator, not edited here to avoid parallel conflicts.)

## LEFT FOR NEXT ITERATION

Nothing in the logic layer. All remaining FIXES_6 work (P04-2/P04-7 companion
test flips if not yet done, `google_fonts` removal in `p04_bugs_test.dart` and
view tests) belongs to the UI builder / integrator.

VERDICT: PASS
