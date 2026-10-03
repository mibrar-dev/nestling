# P03 Create account — Stage 2a logic build (iteration 7)

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

None in this iteration. The logic layer matches the plan (re-verified by
reading/grep, not assumed):

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

## FIXES_6 items in my layer

None — the single open bug, P03-BUG-23 (2 dp form offset from `_OrRow`'s
caption-token label, `create_account_view.dart:280-299`), is a one-line
screen-local view fix owned by the parallel UI builder. Both its proofs live
in `p03_bugs_test.dart` and `typography_test.dart` — neither name contains
bloc/cubit/repository/data, so there is nothing to un-skip or edit in my
layer. Also confirmed out of my scope / already handled:

- BUG-16 now fixed + pixel-proven (view), BUG-22 verified (view), BUG-17 gone
  via shared fonts (no local change).
- `google_fonts`: zero imports/calls in `lib/features/auth/` and in my owned
  test file (grep-verified); remaining view-test cleanup (if any) is the UI
  builder's.
- SHARED_REQUEST §7 (13/20 legal-caption token) and §9 (caption-token pattern
  note): shared/orchestrator items, non-blocking, no logic change.
- No letter-spacing, chip-row, child-order, or trial concerns in this layer.

## Verification (allowed scope only)

- `flutter analyze lib/features/auth` → `No issues found!`
- `flutter test test/features/auth/auth_bloc_test.dart` → `All tests passed!`
  (no skips).
- Full-suite `flutter test`, simulator, and view-test runs NOT done —
  integrator / UI builder scope per the stage brief.

## LEFT FOR NEXT ITERATION

Nothing in the logic layer. When SHARED_REQUEST §8 lands, the UI stage passes
`errorText:` and deletes its owned rows — zero logic lines (bloc already
exposes both error fields). If shared `repositories_test.dart` migrates off
`createAccount(name:)`, drop the legacy alias and restore
`required String email`.

VERDICT: PASS
