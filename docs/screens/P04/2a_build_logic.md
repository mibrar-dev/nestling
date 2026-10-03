# P04 · Privacy consent — STAGE 2a logic build (iteration 8)

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

None. The logic layer already implements the plan and every FIXES_7 item in
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

## FIXES_7 items — logic-layer triage

| Id | FIXES_7 status | Layer | Action this stage |
|---|---|---|---|
| P04-1 first-run opt-in dropped | FIXED (it. 2) | data (mine) | Verified: upsert + migration guarantee; repo tests green |
| P04-2 row-4 empty tile | FIXED (it. 5) | VIEW | Not mine; verified landed |
| P04-3 compact nav short | FIXED (shared) | shared | Not mine |
| P04-4 dividers inflate list | FIXED (it. 4) | VIEW | Not mine; verified landed |
| P04-5 double-tap same value | FIXED (it. 2) | bloc (mine) | Verified: optimistic emit; bloc tests green |
| P04-6 failed OFF claimed "stays off" | FIXED (it. 2) | bloc+view | Bloc half verified (failure keeps prior items/consent) |
| P04-7 dark shield | FIXED (it. 5) | VIEW | Not mine; verified landed |
| P04-8 revert to unpersisted value | FIXED (it. 3) | bloc (mine) | Verified: revert target `_crashFrom(items)`; tests green |
| P04-9 overlapping writes keep earlier | FIXED (it. 4) | data (mine) | Verified: single transaction; deterministic proofs green |
| P04-10 opt-card title wraps (NEW, MAJOR) | OPEN — shared fix | SHARED (core) | Not mine. FIXES_7 prescribes either core-typography `letterSpacing: 0` (preferred) or `NestToggle` minWidth 59→51, filed as SHARED_REQUEST §7. RULES §1 forbids editing `app/lib/core/**`, so I must not apply it. No logic-layer change could fix it: the title width is pure view typography, and the toggle value/layout contract is unchanged. |

Skipped-bug-tests check: `p04_bugs_test.dart:566` carries `skip: true` on
`[P04-10]` only — that file is outside my file-name scope
(`bloc`/`cubit`/`repository`/`data`) and its proof pumps the view against a
shared-typography fix I am forbidden to make. Un-skipping it is the
integrator's job once the shared fix lands on main; I did not touch the file
to avoid parallel conflicts with the UI builder.

## Verification (logic scope only)

- `flutter analyze lib/features/privacy_consent` → No issues found.
- `flutter test test/features/privacy_consent/privacy_consent_bloc_test.dart
  test/features/privacy_consent/privacy_consent_repository_test.dart` → 33 passed.
- `grep google_fonts|GoogleFonts` over `domain/`, `data/`, `bloc/`, and both
  owned test files → no matches (only string literals inside the a11y guard
  test, which asserts their absence).

## LEFT FOR NEXT ITERATION

Nothing in the logic layer. P04-10 awaits the shared typography/`NestToggle`
fix on main (orchestrator-owned); un-skipping its proof belongs to the
integrator after the merge.

VERDICT: PASS
