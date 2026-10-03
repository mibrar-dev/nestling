# P03 Create account — Stage 2a logic build (iteration 8)

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

None in this iteration. The logic layer matches the plan (re-verified):

- `domain/auth_repository.dart` — `AuthProvider` enum, `createAccount` (legacy
  `name:` alias kept + documented for the shared `repositories_test.dart`
  caller, out of scope per RULES §1), `createAccountSocial`.
- `domain/entities/auth_account.dart`, `data/models/auth_account_model.dart` —
  unchanged value object + fromJson/toJson.
- `data/auth_repository_impl.dart` — Drift-backed, email local-part → owner
  name (`Parent` fallback), idempotent `_ensureOwner`, password never persisted,
  `TODO(P03)` markers. Sole lib caller is `AuthBloc` with `email:`.
- `presentation/bloc/*` — dirty-gated validation (P03-BUG-2), shared helpers +
  error texts, `canSubmit`, `on Object catch` + `addError` (P03-BUG-5/14),
  in-flight guards, `AuthSubmitConsumed` no-op guard.
- `auth_di.dart` / `auth_routes.dart` — registered, `BlocProvider` +
  `AuthLoadRequested`; no change needed.

## FIXES_7 items in my layer

None — the single open item, P03-BUG-24 (headline must use `NestBalancedText`
per BALANCED HEADINGS, `create_account_view.dart:39, :101-111`), is a
view-only swap owned by the parallel UI builder, including its arbitration
(keep vs drop the 240 dp cap) and the `P03-BUG-7` bound retirement. Its proof
lives in `p03_bugs_test.dart`, whose name contains none of
bloc/cubit/repository/data — nothing to un-skip or edit in my layer. Also
confirmed out of scope:

- SHARED_REQUEST §10 (`NestBalancedText` collapse when `maxLines` clips) is a
  `core/` defect — off-limits per RULES §1; filed, not a P03 bug.
- SHARED_REQUEST §7 (13/20 legalCaption token): open, non-blocking, no logic
  change.
- BUG-16/17/22/23 all green; nothing regressed in the bloc or repository.
- `google_fonts`: zero imports/calls in `lib/features/auth/` and in
  `auth_bloc_test.dart` (grep-verified); zero `skip:` markers there too.

## Verification (allowed scope only)

- `flutter analyze lib/features/auth` → `No issues found!`
- `flutter test test/features/auth/auth_bloc_test.dart` → `All tests passed!`
  (+45, no skips).
- Full-suite `flutter test`, simulator, and view-test runs NOT done —
  integrator / UI builder scope per the stage brief.

## LEFT FOR NEXT ITERATION

Nothing in the logic layer. When SHARED_REQUEST §8/§10 land, the UI stage does
the `errorText:`/headline migrations — zero logic lines (bloc already exposes
both error fields; no headline state exists in the bloc). If shared
`repositories_test.dart` migrates off `createAccount(name:)`, drop the legacy
alias and restore `required String email`.

VERDICT: PASS
