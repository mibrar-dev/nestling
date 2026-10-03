# P04 · Privacy consent — STAGE 2a logic build (iteration 9)

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

None. The logic layer already implements the plan and every FIXES_8 item in
its scope (verified, not re-edited):

- `app/lib/features/privacy_consent/data/privacy_consent_repository_impl.dart`
  — transactional upsert (P04-1/P04-9), single-row guarantee, table defaults.
- `app/lib/features/privacy_consent/presentation/bloc/privacy_consent_bloc.dart`
  — optimistic toggle (P04-5), state-aware failure keeping prior items (P04-6),
  revert to `_crashFrom(items)` (P04-8), `emit.forEach` stream (no reload events).
- `domain/`, `privacy_consent_di.dart`, `privacy_consent_routes.dart` — unchanged,
  contract stable.
- `app/test/features/privacy_consent/privacy_consent_{bloc,repository}_test.dart`
  — unchanged, no `google_fonts` imports, no skips (20 + 13 tests, all green).

## FIXES_8 items — logic-layer triage

| Id | FIXES_8 status | Layer | Action this stage |
|---|---|---|---|
| P04-1 first-run opt-in dropped | FIXED (it. 2) | data (mine) | Verified: upsert; repo tests green |
| P04-2 … P04-9 (all prior) | FIXED | view/bloc/data | Bloc/data halves verified green; view halves are UI builder's |
| P04-10 opt-card title wraps | FIXED (it. 8, local `letterSpacing: 0`) | VIEW | Not mine; proof green, 0 skips feature-wide |
| P04-11 tracking leaks into 14/15 runs (NEW, MAJOR latent) | OPEN | VIEW (UI builder) | Not mine. Every screen-side instance is in `privacy_consent_view.dart` (h1, standfirst, row titles/subs, opt sub, footnote, dialog body); the preferred fix is shared (`NestType._inter/_nunito`, `app/lib/core/**` — RULES §1 forbids me). No bloc/data change bears on it. |
| Review 1 (3 failing geometry tests) | OPEN | VIEW (UI builder) | Same letter-spacing fix in the view; failing file `privacy_consent_geometry_test.dart` is outside my file-name scope |
| Review 2 (untracked geometry test) | process | — | Not a code defect; not mine |
| Review 3 (a11y `google_fonts` literals) | MINOR | a11y test (not mine) | `privacy_consent_a11y_test.dart` is outside my file-name scope; literals are the guard test's own scanner, code genuinely clean |
| Review 4 (loop bookkeeping) | process | — | Not a finding; not mine |

Skipped-bug-tests check: `grep skip: true` over the feature test dir → zero
hits. Nothing to un-skip in my scope.

## Verification (logic scope only)

- `flutter analyze lib/features/privacy_consent` → No issues found.
- `flutter test test/features/privacy_consent/privacy_consent_bloc_test.dart
  test/features/privacy_consent/privacy_consent_repository_test.dart` → 33 passed.

## LEFT FOR NEXT ITERATION

Nothing in the logic layer. P04-11 + the 3 red geometry tests await the view
(`copyWith(letterSpacing: 0)` per run) and/or shared `NestType` fix —
UI builder / orchestrator owned.

VERDICT: PASS
