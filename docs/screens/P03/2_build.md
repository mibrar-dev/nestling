# P03 Create account — build note (Stage 2, iteration 1)

Route `/create-account` · parent mode · feature `auth`. Built exactly per
`docs/screens/P03/1_plan.md` with five documented deviations (all below).

## Files changed (all inside RULES §1 scope)

- `app/lib/features/auth/domain/auth_provider.dart` (new) — `AuthProvider { apple, google }`.
- `app/lib/features/auth/domain/auth_repository.dart` — `createAccount({String? email, String? name})`
  + `createAccountSocial({required AuthProvider provider})` (see deviation 1).
- `app/lib/features/auth/data/auth_repository_impl.dart` — email local-part derives the owner
  name (fallback `'Parent'`); social ensures owner `'Parent'`; password never written (`TODO(P03)`).
- `app/lib/features/auth/presentation/bloc/auth_event.dart` — added `AuthEmailChanged`,
  `AuthPasswordChanged`, `AuthSubmitted`, `AuthSocialSubmitted`, `AuthSubmitConsumed`.
- `app/lib/features/auth/presentation/bloc/auth_state.dart` — added `email`, `password`,
  `emailError`, `passwordError`, `isSubmitting`, `submitted`, `formError` (+ `canSubmit` getter,
  shared `isAuthEmailValid`/`isAuthPasswordValid` helpers, error strings).
- `app/lib/features/auth/presentation/bloc/auth_bloc.dart` — live validation on change,
  validate-then-submit, social submit, `isSubmitting` re-entrancy guard, consumed reset.
- `app/lib/features/auth/presentation/widgets/apple_glyph.dart` (new) — single-path Apple mark
  from the HTML source, tinted via ambient `IconTheme` (token-driven dark flip).
- `app/lib/features/auth/presentation/widgets/google_glyph.dart` (new) — 4-path `G` in fixed
  brand colours from the HTML source.
- `app/lib/features/auth/presentation/views/create_account_view.dart` — replaced placeholder with
  the real screen (see below).
- `app/test/features/auth/auth_bloc_test.dart` (new, 23 tests) — state/validation units, blocTest
  for every event path incl. throwing repos, Drift-backed load + repository contract tests.
- `app/test/features/auth/create_account_view_test.dart` (new, 28 tests) — copy/themes, 320/390/430
  × 1.0/1.3 matrix both themes, all five bloc states, validation, submit/social/back navigation,
  throwing-repo error, full a11y contract.
- `docs/screens/P03/SHARED_REQUEST.md` (new) — two non-blocking shared-code defects found while
  building (plan §(g) said none; the null-title nav-bar crash forced one).

## What was built (plan §(a)–(f))

- Chrome: `NestStatusBar` (height-only) + `NestNavBar(compact)` back-only + `Expanded` scroll
  (`20/0/20/32` padding) + `NestBottomCta` (surface runs to the edge; no extra home indicator).
  Scaffold background is the paper token.
- Form order/spacing per spec: h1 + 8 + subtitle, 24 Apple, 12 Google, 16 or-row
  (token dividers, `ExcludeSemantics`), 16 Email, 16 Password (built-in eye toggle, helper
  `At least 8 characters`), 12 lilac-shield note. Submit disabled until both fields validate
  (opacity .45 via component); loading spinners + all buttons dead while submitting.
- Legal line as centred `Wrap` with two inert 44dp `TODO(P03)` link targets (Terms / Privacy
  Notice, sky + underline); `NestBottomCta.caption` not used.
- Navigation: back → `canPop ? pop : go('/value-tour')`; email/social success →
  consume + `go('/privacy')`; submit failure → `formError` as password `errorText` +
  `SemanticsService.sendAnnouncement`.
- Static form renders for initial/loading/loaded/failure; member rows never displayed.
- Headline is the only `header: true` semantics; glyphs/note-icon/or-row excluded; eye tooltip
  flips Show/Hide; every tap target ≥ 44 (brand/submit full-width ≥ 52).

## Deviations from 1_plan.md (all deliberate)

1. `createAccount({required String email})` → `({String? email, String? name})`: the shared
   `app/test/core/data/repositories_test.dart` (outside §1, uneditable) still calls
   `createAccount(name:)`; the optional legacy alias keeps `flutter test` green. New callers pass
   `email:`; orchestrator should migrate the shared test and restore `required`.
2. `NestNavBar(compact, title: null)` → `title: ''`: compact + null title crashes in shared
   `nest_nav_bar.dart` (Expanded around Spacer) — filed as SHARED_REQUEST item 1, workaround
   marked `NOTE(P03)`.
3. Email `autocorrect/enableSuggestions: false` not passed: `NestTextField` (shared) exposes no
   such params; keyboardType email + component defaults used (non-blocking, not filed).
4. Validation helpers are public top-levels in `auth_state.dart` (not private in the bloc) so the
   view's `canSubmit` shares the single source.
5. `SemanticsService.announce` → `sendAnnouncement(View.of(context), …)`: `announce` is
   deprecated/removed-path in this SDK; same behaviour, modern API.
6. Brand-button label assertions use `contains`: shared `_BrandButton` merges its explicit label
   with the inner Text (`'X\nX'`, double-announced) — filed as SHARED_REQUEST item 2.
7. `shot.sh`/`compare.py` not run in this stage (no simulator in this loop); light/dark + sizes
   are covered by widget tests. Screenshots belong to the test stage.

## Evidence tails (app/)

- `dart format --set-exit-if-changed .` → `Formatted 356 files (0 changed)`, exit 0.
- `flutter analyze` → `No issues found! (ran in 3.1s)`
- `flutter test` (full suite) → `00:09 +530: All tests passed!` (51 new P03 tests included)
- `git status` touches only `app/lib/features/auth/**`, `app/test/features/auth/**`,
  `docs/screens/P03/**` — nothing shared.

VERDICT: PASS
