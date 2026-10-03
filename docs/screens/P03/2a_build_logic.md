# P03 Create account — Stage 2a logic build (iteration 6)

Route `/create-account` · feature `auth` · parent mode. Scope: non-UI layer only
(`domain/**`, `data/**`, `presentation/bloc/**`, DI/routes, bloc/repository/data
tests). Views/widgets untouched — UI builder owns those.

## CONTRACT CHANGES

None. Public names stable per `1_plan.md` §(b): `AuthEmailChanged`,
`AuthPasswordChanged`, `AuthSubmitted`, `AuthSocialSubmitted(provider)`,
`AuthSubmitConsumed`, `AuthLoadRequested`; state fields `email/password`,
`emailError/passwordError`, `isSubmitting/submitted/formError/submitAttempted`,
`canSubmit`; repository `createAccount({email:, name:})` +
`createAccountSocial({provider:})`; `AuthProvider { apple, google }`.

## Files changed

None in this iteration. The logic layer already matches the plan exactly
(verified by reading every file, not assumed):

- `app/lib/features/auth/domain/auth_repository.dart` — `AuthProvider` enum,
  `createAccount({email, name})` (legacy `name:` alias kept + documented for the
  shared `repositories_test.dart` caller, out of scope per RULES §1),
  `createAccountSocial({provider})`.
- `app/lib/features/auth/domain/entities/auth_account.dart` — Equatable value
  object, unchanged.
- `app/lib/features/auth/data/auth_repository_impl.dart` — Drift-backed,
  email local-part → owner name (`Parent` fallback), idempotent `_ensureOwner`,
  password never persisted, `TODO(P03)` markers. Only lib caller of
  `createAccount` is `AuthBloc` with `email:` (grep-verified).
- `app/lib/features/auth/data/models/auth_account_model.dart` — fromJson/toJson,
  unchanged.
- `app/lib/features/auth/presentation/bloc/{auth_bloc,auth_event,auth_state}.dart`
  — dirty-gated validation (P03-BUG-2), shared helpers `isAuthEmailValid` /
  `isAuthPasswordValid` + error texts, `canSubmit`, submit/social with `on Object
  catch` + `addError` (P03-BUG-5/14), in-flight guards, `AuthSubmitConsumed`
  no-op when nothing submitted.
- `app/lib/features/auth/{auth_di,auth_routes,auth}.dart` — already registered
  (`/create-account`, `BlocProvider` + `AuthLoadRequested`); no change needed.

## FIXES_5 items in my layer

None — every open item is view/shared/UI-test layer, owned by the parallel UI
builder or the orchestrator:

- P03-BUG-16 (danger border, Decision A): view switch to shared `errorText`
  row, pending SHARED_REQUEST §8. Proof already skip-marked in
  `p03_bugs_test.dart:1035-1043` (not my file — name contains none of
  bloc/cubit/repository/data).
- Review finding 2 (`_HitTestExpand` `!hit` gate + tapAt proof): view-only.
- P03-BUG-22 skip (`p03_bugs_test.dart:1142-1145`): view-only latent proof.
- `google_fonts` imports in `create_account_view_test.dart` / `p03_bugs_test.dart`:
  real, but both files are UI-owned; editing them in parallel would conflict
  with the UI builder, so cleanup is left to that stage. My owned test file
  (`auth_bloc_test.dart`) has zero `google_fonts`/skip references (grep-verified).
- No skipped bug test referenced by FIXES_5 lives in a file I own, so nothing
  to un-skip.

## Verification (allowed scope only)

- `flutter analyze lib/features/auth` → `No issues found!`
- `flutter test test/features/auth/auth_bloc_test.dart` → `+45: All tests passed!`
  (34 bloc/state-machine + 11 Drift repository proofs; no skips).
- Full-suite `flutter test`, simulator shots, and view-test runs NOT done —
  integrator / UI builder scope per the stage brief.

## LEFT FOR NEXT ITERATION

Nothing in the logic layer. If the orchestrator lands SHARED_REQUEST §8
(live-region shared error row), the follow-up logic work is zero lines — the
bloc already exposes `emailError`/`passwordError`, so the UI stage just passes
`errorText:` and deletes its owned rows. If the shared `repositories_test.dart`
migrates off `createAccount(name:)`, the legacy alias can be dropped and the
param restored to `required String email`.

VERDICT: PASS
