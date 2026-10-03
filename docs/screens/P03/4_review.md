# P03 Create account — QA code review (Stage 4, iteration 8)

Scope reviewed: `git diff main...HEAD` — 7 files under
`app/lib/features/auth/**` (view, bloc ×3, repository interface + impl, two
brand-glyph widgets), 7 files under `app/test/features/auth/**`, and this
screen's own notes. Reference set: `docs/ARCHITECTURE.md`,
`docs/screens/RULES.md`, `docs/DESIGN_SPEC.md` §0.9 + §5 P03,
`docs/design/SPACING_SPEC.md`, `design/html-source/screens/P03-create-account.html`,
`design/screens/{light,dark}/P03-create-account.png`, `1_plan.md`,
`ORCHESTRATOR_NOTES.md` (every item), the standing COPY / FONTS / LETTER
SPACING / CHIP ROWS / BALANCED HEADINGS / BOTTOM EDGE / ALIGNMENT rules,
`SHARED_REQUEST.md` §1–§10. No code was edited by this stage and no simulator
was used.

## Evidence gathered by this stage

- `flutter analyze` → **No issues found!** — no ignores, no weakened
  `analysis_options`, and no `google_fonts` / `GoogleFonts` string anywhere
  under `app/lib` + `app/test`. `dart format` → 21 files, 0 changed.
- `flutter test test/features/auth` → **+167: All tests passed!**
  (0 failed, **0 skipped**; `auth_bloc_test` 20, `create_account_view_test`
  38, `p03_bugs_test` 29, `typography_test` 16, `copy_audit_test` 11,
  `seeded_submit_test` 7, plus harness units).
- `flutter test` (whole app) → **+1192: All tests passed!** — the domain
  signature change does not break the shared suite; the one shared caller,
  `app/test/core/data/repositories_test.dart:414` (`createAccount(name:)`),
  still passes on its own.
- The iteration-8 test stage rewrote
  `app/test/features/auth/typography_test.dart` (the migration proof) while
  this stage was reading, so the feature suite was re-run on the final tree:
  still **+167: All tests passed!**, 0 skipped. Line references below are to
  that final tree.
- `git diff main...HEAD --name-only` touches only
  `app/lib/features/auth/**`, `app/test/features/auth/**` and
  `docs/screens/P03/**` — RULES §1 respected, `core/` and `app/` untouched.
- Copy checked character-by-character against the HTML: `You’re`
  U+2019 (`&rsquo;`), `No child emails or photos — ever.` U+2014
  (`&mdash;`), `Privacy\u00A0Notice` (the no-break space
  ORCHESTRATOR_NOTES §5 mandates). No US spellings anywhere on the screen.
- Device check by eye against `design/screens/light/P03-create-account.png`:
  `ui/filled-light.png` reproduces the design's bands — 20 dp gutters on
  every shape, the white CTA surface running to the physical bottom edge with
  no page-tint strip (BOTTOM EDGE), headline break `Create your` /
  `family account`, legal caption on the design's two centred lines.

## ORCHESTRATOR_NOTES iteration-8 items — both closed

| Item | Status |
|---|---|
| 1. h1 renders with `NestBalancedText`; hand-made `maxWidth` deleted | **closed** — `create_account_view.dart:101-106`; `_headlineMaxWidth` and its comment block are gone; `textAlign: TextAlign.left` keeps both lines on the 20 dp gutter (the component centres its narrowed box by default). `P03-BUG-24` is **un-skipped and green**, extended to pin the widget type, the copy, `maxLines`, the alignment and the painted gutter. Iteration 7's prediction that the break would move to `Create your family` / `account` was wrong: the component takes the minimum line count at full width (2) and then searches the narrowest width that still holds 2 lines — 197.68 dp, exactly the design's. `typography_test.dart:333` pins the design's two lines on the real view, `:363` proves the same break out of the full 350 dp column (so the deleted cap really was a no-op), and `:524` keeps the two even lines at scale 1.3 with the real fonts loaded. |
| 2. Delete `zz_probe8_test.dart` / any `zz_`·`probe` scratch test; analyze stays clean | **closed** — `app/test/features/auth/` now holds only the 7 real test/helper files; no `skip:` / `@Skip` anywhere in the feature; analyze clean. |

## Iteration-7 findings — answered

| # | Finding | Status |
|---|---|---|
| 1 | MAJOR — h1 hand-breaks with a `maxWidth` constant | **closed** (see table above) |
| 2 | MINOR — `zz_probe8_test.dart` must not be committed | **closed** — file deleted, not tracked, not in the diff |

## Findings

No blocker and no major. Six minors — four in P03's own editable paths, two
that need a shared request. None blocks the merge; none regresses a frame the
UI stage already measured (2.1 %).

### 1. MINOR — a raw exception string is painted in the form (and announced)

`app/lib/features/auth/presentation/bloc/auth_bloc.dart:103` and `:121`
(`formError: error.toString()`) feed
`app/lib/features/auth/presentation/views/create_account_view.dart:182-183`
(`errorText = state.passwordError ?? state.formError`), so `NestTextField`
prints the string in its danger row and, because that row is a live region
(`nest_text_field.dart:209-222`), VoiceOver reads it out too. With the real
impl the only failure is a Drift insert error, so a parent would see
`Bad state: Cannot insert...` or `SqliteException(...)` under the password
field — internal detail and terrible copy for a consumer sign-up screen. The
stack trace is already preserved for observers by the adjacent
`addError(error, stackTrace)`, so nothing is lost by mapping the message.

Concrete fix:

```dart
// auth_state.dart
const String authFormErrorText =
    'We couldn’t create the account just now. Please try again.';

// auth_bloc.dart, both handlers (keep the raw error for observers)
emit(state.copyWith(isSubmitting: false, formError: authFormErrorText));
addError(error, stackTrace);
```

Test impact: `app/test/features/auth/auth_bloc_test.dart:329` and `:364`
both assert `contains('offline')` and must become the fixed string; the
`isNotNull` assertions at `:624` / `p03_bugs_test.dart:850` still pass.

### 2. MINOR — `copyWith(clearErrorMessage:)` is dead API added by this diff

`app/lib/features/auth/presentation/bloc/auth_state.dart:56` and `:72-74`.
No caller in `app/lib` or `app/test` ever passes `clearErrorMessage`
(grep: 2 hits, both inside `auth_state.dart`), and no proof exercises it — the
foundation's `errorMessage` has no clearer because no event sets it. It is
unused surface area added alongside the three clears that are used.

Concrete fix: delete the parameter and restore
`errorMessage: errorMessage ?? this.errorMessage,` in `copyWith`.

### 3. MINOR — the bottom CTA rebuilds on every keystroke

`app/lib/features/auth/presentation/views/create_account_view.dart:240-241`:
this is the only `BlocBuilder` on the screen without a `buildWhen`, so each
`AuthEmailChanged` / `AuthPasswordChanged` re-runs the panel's builder and
rebuilds `_HitTestExpand → NestBottomCta → Column → NestButton` (Material /
InkWell / Ink / RichText) plus a repaint of the bar. It is cheap today
(`_LegalLine()` is a canonical const, so `Element.updateChild` short-circuits
and the expensive `TextPainter` re-measure does **not** rerun — verified by
reading the tree), but the two fields already gate themselves with
`buildWhen`, and the panel's inputs are only `isSubmitting` and `canSubmit`.

Concrete fix:

```dart
BlocBuilder<AuthBloc, AuthState>(
  buildWhen: (previous, current) =>
      previous.isSubmitting != current.isSubmitting ||
      previous.canSubmit != current.canSubmit,
  builder: (context, state) { … },   // unchanged
)
```

### 4. MINOR — `createAccount` takes two mutually exclusive optional params

`app/lib/features/auth/domain/auth_repository.dart:22`
(`Future<void> createAccount({String? email, String? name})`) and
`app/lib/features/auth/data/auth_repository_impl.dart:36-46`. The `name:`
alias exists only so the shared `repositories_test.dart` keeps compiling, but
the compiler cannot warn that caller: passing neither yields the silent name
`'Parent'`, and passing both silently prefers `email`. The NOTE in the
interface documents this for humans only.

Concrete fix (keeps the shared test green, tells the compiler):

```dart
@Deprecated('pass email: — `name` is a legacy alias for the shared test only')
Future<void> createAccount({
  String? email,
  @Deprecated('pass email:') String? name,
});
```

and finish the job in a `SHARED_REQUEST.md` item asking the orchestrator to
migrate `app/test/core/data/repositories_test.dart:414` to `email:` and drop
`name` entirely, restoring `required String email`.

### 5. MINOR — the email field keeps the platform's autocorrect / autocapitalise

`app/lib/features/auth/presentation/views/create_account_view.dart:163-174`
passes only `keyboardType: TextInputType.emailAddress` and
`textInputAction: TextInputAction.next`. `1_plan.md` §(a) asked for
`autocorrect: false, enableSuggestions: false` (and, ideally, an email
`autofillHints` plus a `next` that actually moves focus to Password), but
`NestTextField` (`lib/core/design_system/components/nest_text_field.dart:16-32`)
exposes no such props, and `core/` is out of bounds for a screen agent
(RULES §1). Grep confirms nothing in `app/lib` sets `autocorrect`,
`enableSuggestions`, `textCapitalization` or `autofillHints` anywhere. On iOS
the soft keyboard can therefore suggest and capitalise inside the email field,
which then fails the screen's own validation — the one field where it matters.

Concrete fix: add a `SHARED_REQUEST.md` §11 item for
`NestTextField({bool? autocorrect, bool? enableSuggestions,
TextCapitalization? textCapitalization, Iterable<String>? autofillHints})`
forwarded to the inner `TextField` (an `InputDecoration`/`TextField`
pass-through is the smallest shape). Until it lands, this is not fixable
locally — do **not** work around it by wrapping the field in a feature-owned
`TextField`.

### 6. MINOR — generic hit-test infrastructure is parked in the auth feature

`app/lib/features/auth/presentation/views/create_account_view.dart:620-701`
(`_HitTestExpand` / `_RenderHitTestExpand`). It overrides `hitTest` on a
`RenderProxyBox`, translates a probe point into the caption `Stack`'s
children and pushes their entries into the inherited `BoxHitTestResult`, and
it finds its target by descent under the assumption that "the CTA subtree
holds exactly one `Stack`" (`:683-685`). That is not P03-specific: any screen
whose bottom bar carries links needs it, the assumption silently breaks the
day a shared bar grows a `Stack`, and `SHARED_REQUEST.md` §7 already asks the
design system for the neighbouring `NestType.legalCaption`. It is well
documented and its behaviour is pinned (`P03-BUG-18/19/22`), so it is a debt
note rather than a defect — but it should not become the template the next
screen copies silently.

Concrete fix: extend the existing §7 request into one design-system item:
`NestBottomCta.linkedCaption({required List<InlineSpan> spans, required
TextStyle linkStyle})` (or a shared `HitTestExpand` wrapper) that owns the
caption's line measurement and the ≥44 dp targets, so the next screen gets
the behaviour from `core/` and this file keeps only the copy. Blocks: no.

## Checked and clean (no finding)

- **Architecture** — feature-first; `domain/` holds the abstract repository +
  entities only (no use cases, no `utils`); one bloc per feature with the
  spec's `AuthStatus`; DI/routes untouched and per feature; cross-feature
  traffic only through route constants (`OnboardingRoutePaths.valueTour`,
  `PrivacyConsentRoutePaths.privacy`). Validation helpers
  (`isAuthEmailValid`, `isAuthPasswordValid`) and their error strings live in
  `presentation/bloc/auth_state.dart`, which is the right side of the
  "domain = entities + abstract repository only" rule.
- **RULES §1/§4/§7** — only allowed paths touched; the password is never
  persisted (proved on the schema itself,
  `seeded_submit_test.dart:203-205`); `createAccount` is idempotent and never
  renames a seeded owner (`seeded_submit_test.dart:102-127`); every test that
  pumps the app ends with `disposeApp(tester)` (the few that end with the
  local `_disposeView` helper pump no database).
- **Design-system usage** — no component re-implemented: `NestStatusBar`,
  `NestNavBar`, `NestAppleButton`, `NestGoogleButton`, `NestTextField`,
  `NestButton`, `NestBottomCta`, `NestIcon`, `NestBalancedText`, `NestType`,
  `NestSpacing`, `NestDevice`. Feature-private widgets are limited to brand
  artwork (`AppleGlyph`, `GoogleGlyph`, both `currentColor`/fixed brand
  artwork, matching the DS's own 20 px glyph slot) and the two rows the design
  defines itself (`_OrRow`, `_LegalLine`).
- **TOKENS-ONLY** — no `Color(0x…)`, no `Colors.*` anywhere under
  `features/auth`; every colour is `tokens.*`; no `letterSpacing` is added
  anywhere (the `_OrRow` rebuild copies `base.letterSpacing`, which is 0).
  The only owned numbers are `15.7` (the design's CSS-normal `.or-label` line
  box, `SHARED_REQUEST` §9) and the 20/13 legal line height (§7) — both
  named, derived and pinned.
- **BALANCED HEADINGS** — the h1 uses `NestBalancedText`; the subtitle,
  helper, note and CTA stay plain `Text` (pinned by
  `typography_test.dart:558`); no one-word orphan line at scale 1.3.
- **FONTS** — Inter 400/500/600/700 and Nunito 700/800/900 are bundled
  assets; no `google_fonts` import or `GoogleFonts.*` call in code or tests.
- **A11Y** — headline is the only `header: true`; the error row is a live
  region and the submit failure is announced through the widget tree
  (`create_account_view.dart:70-76`); brand labels announce once (glyphs are
  `ExcludeSemantics`, DS labels are excluded inside the buttons); every
  interactive box ≥44 dp including the two legal targets; the legal group's
  label spells the sentence once with the two link nodes explicit; text scale
  1.3 at 320/390/430 absorbs growth through the scroll view with no overflow.
- **UI CHECK MEASURES SHAPES** — `typography_test.dart:582-…` compares the
  painted background/border rects (fields, both brand pills, both or-rules,
  the CTA pill) against the design PNG, not just text positions, in both
  themes; the BOTTOM EDGE and the 20 dp gutters have proofs in light and dark.
- **Error handling** — both submit paths catch `Object`, guard on
  `isSubmitting`, re-report to the bloc observer with the stack trace, and
  leave the form editable; the form is never gated on the members stream
  (all four `AuthStatus` values render the full form).
- **Children's Code** — parent-only screen; no analytics, no ads, no child
  data, no photos, no location, no external links; the privacy promise
  ("No child emails or photos — ever.") is on screen; the Terms/Notice
  targets are inert `TODO(P03)` no-ops, and their overlap is documented and
  gated (P03-BUG-22).
- **N/A rules** — PIP (no Pip on P03), CHILD ORDER, DATA OVER MOCKS (the
  screen shows no seeded numbers), PERIODS, TRIAL, CHIP ROWS (no `NestChip`).
- **PROCESS** — noted, not reported: the modified `.brief_*` / `.start_*`
  markers and the branch's own uncommitted docs.

VERDICT: PASS