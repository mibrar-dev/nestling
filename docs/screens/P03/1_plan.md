# P03 Create account — build plan (Stage 1, iteration 1)

Route `/create-account` (AuthRoutePaths.createAccount) · parent mode · feature `auth`.
Sources: `design/html-source/screens/P03-create-account.html`,
`design/screens/light/P03-create-account.png`,
`design/screens/dark/P03-create-account.png` (1170x2532 @3x; all px below are logical = raw/3),
DESIGN_SPEC §5 P03, SPACING_SPEC §§1–2,9–11.
No ORCHESTRATOR_NOTES.md exists in docs/screens/P03 (checked) — no extra mandates.
No Pip on this screen — PIP rule is vacuous here (and v1 `pip_stage_*.svg` must not be used anywhere).

## (a) Widget tree top → bottom (exact components + token spacing)

Scaffold background = paper token. Body = Column (no tab bar, no sheet):

1. `NestStatusBar` — reserves 47 (`NestDevice.statusH`); mock glyphs stay OFF in the app
   (OS draws the real bar; UI checks ignore it).
2. `NestNavBar(compact: true, onBack: ..., title: null)` — back chevron 44x44,
   44px balance spacer on the right (component does this automatically).
3. `Expanded` + `SingleChildScrollView` with padding `EdgeInsets.fromLTRB(20, 0, 20, 32)`
   (`NestSpacing.padSide` sides, 32 = s8 bottom so content clears nothing fixed — the CTA
   is in-flow at the column bottom, not overlaid; scroll bottom padding per SPACING_SPEC §1):
   - Head: `Text('Create your family account', style: NestType.h1(ink), maxLines 3)` +
     `SizedBox(8)` + `Text("You're the grown-up in charge. Children never need an email.",
     style: NestType.body(ink2))`. Headline is the screen's only `header: true` semantics
     (HTML `h1`).
   - `SizedBox(24)` → `NestAppleButton(label: 'Continue with Apple', leading: _AppleGlyph(),
     key: p03_apple)`. Min-height 52, pill, Inter 16 w700. Dark flip (white bg / black ink)
     comes from tokens — no hard-coding.
   - `SizedBox(12)` → `NestGoogleButton(label: 'Continue with Google', leading: _GoogleGlyph(),
     key: p03_google)`. Same geometry; border = googleLine token.
   - `SizedBox(16)` → or-row: `Row(children: [Expanded(Divider 1px line), SizedBox(12),
     Text('or', Inter 13 w600 ink2), SizedBox(12), Expanded(Divider)])`.
   - `SizedBox(16)` → `NestTextField(key: p03_email, label: 'Email',
     keyboardType: TextInputType.emailAddress, textInputAction: next,
     autocorrect: false, enableSuggestions: false)`. Label 13/18 w600 ink-2, gap 6,
     input 52 high, r16, border line, bg surface; focus ring = leaf border + focusRing
     shadows (component built-in).
   - `SizedBox(16)` → `NestTextField(key: p03_password, label: 'Password', obscureText: true,
     textInputAction: done, helperText: 'At least 8 characters')`. The component's built-in
     eye toggle (44x44, tooltips 'Show/Hide password') satisfies the HTML `.eye` spec —
     do NOT build a custom toggle. Helper 13/18 ink-2 (component built-in).
   - `SizedBox(12)` → note row: `Row(gap 8, crossAxisAlignment: center)` =
     `NestIcon(NestIcons.shieldCheck, size: 20, color: lilac)` +
     `Flexible(Text('No child emails or photos — ever.',
     style: NestType.bodySmallStrong(ink2)))` (15/22 w600 per HTML `.note`).
4. `NestBottomCta(caption: null, child: Column(...))` — surface bg + top hairline border,
   padding 16 vertical / 20 horizontal; `SafeArea(top: false)` inside the component runs the
   surface to the physical edge (OWNER bottom-edge rule — do NOT add any extra home-indicator
   widget; `NestHomeIndicator` renders shrink in-app). Column contents:
   - `NestButton.primary(label: 'Create account', key: p03_submit)` full-width, min-height 52.
   - `SizedBox(8)` + legal line, centered, Inter 13 ink-2 with two link spans:
     `By continuing you agree to our [Terms] and [Privacy Notice]`, links sky + underline.
     Implement as `Text.rich` with `TapGestureRecognizer`s (keys p03_terms / p03_privacy) OR
     adjacent `TextButton`s; either way each link hit-area must be >= 44 high (use the HTML
     `.link` trick: `Padding(12, 2)` + negative margin compensation, i.e. wrap in a 44-min
     `ConstrainedBox`). `NestBottomCta.caption` (plain string) must NOT be used — it cannot
     render links.

Brand glyphs: `NestIcons` has no Apple/Google logos, and core/ is off-limits, so add two
feature-private widgets in `app/lib/features/auth/presentation/widgets/`:
`apple_glyph.dart` (single-path glyph tinted with the button foreground, 20px — copy the path
geometry from the HTML source) and `google_glyph.dart` (4-path `G' in fixed brand colours
#EA4335/#4285F4/#FBBC05/#34A853, 20px — brand colours are artwork, exempt from the token rule
like other SVG art). These are brand artwork, not design-system components (no DS rule broken).

Dark mode: everything above resolves via tokens (paper/surface/ink/leaf/appleBg/googleBg/
googleLine/sky/lilac). Verify against the dark PNG: Apple button white, Google near-black
with grey border, primary CTA leaf-green, legal links light-blue.

## (b) BLoC events/states + repository calls

Existing `AuthBloc` only has `AuthLoadRequested` + `watchItems()` over `members` (owner row).
The `members` table has NO email/password columns (verified in `app_database.dart`: only
id/familyId/name/role…), and schema changes are shared/out of scope — so the password is
NEVER persisted (local-only stub); only the owner member row is ensured.

State — extend `AuthState` with form fields (keep status/items/errorMessage untouched):
`email ('')`, `password ('')`, `emailError (String?)`, `passwordError (String?)`,
`isSubmitting (false)`, `submitted (false)`, `formError (String?)`.

Events to add in `auth_event.dart`:
- `AuthEmailChanged(email)`, `AuthPasswordChanged(password)` — update value; if the field
  was already errored, re-validate live (clear error when fixed).
- `AuthSubmitted()` — validate both; if invalid, set `emailError`/`passwordError` and return
  (no repo call). Else `isSubmitting = true`, `await repository.createAccount(email: email)`,
  then `isSubmitting = false, submitted = true`. On throw: `isSubmitting = false`,
  `formError = exception message`, surfaced as the password field's `errorText`.
- `AuthSocialSubmitted(provider)` (`enum AuthProvider { apple, google }`) — same shape, but
  calls `repository.createAccountSocial(provider: provider)`; success sets `submitted = true`.
- `AuthSubmitConsumed()` — resets `submitted = false` after the view navigates (prevents
  double-navigation on rebuild).

Validation (single shared private helpers, unit-tested):
`isEmailValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim())`;
`isPasswordValid = password.length >= 8`.
Errors: email → `'Enter a valid email address'`; password → `'Use at least 8 characters'`.
Submit CTA enabled iff `isEmailValid && isPasswordValid && !isSubmitting`
(disabled ⇒ component opacity .45, onPressed null).

Repository (feature-owned domain+data — editable per RULES §1):
- Change `createAccount({required String name})` → `createAccount({required String email})`;
  impl derives the owner member `name` from the email local-part (`email.split('@').first`,
  fallback `'Parent'` when empty) and is otherwise unchanged (id `'owner'`, familyId
  `Seed.familyId`, no-op if an owner row exists). Password is never written anywhere.
- Add `createAccountSocial({required AuthProvider provider})`; impl ensures the owner row
  with name `'Parent'` (no-op if present). Mark both with `// TODO(P03): real backend auth`.
- Update the single existing caller/tests of `createAccount(name:)` accordingly (grep first).

View wiring: `BlocListener` on `submitted == true` → `bloc.add(AuthSubmitConsumed())` then
`context.go(PrivacyConsentRoutePaths.privacy)`. `BlocBuilder` rebuilds fields/buttons from
state. Field `errorText` = corresponding state error (`formError` feeds the password field
only when `passwordError == null`). Loading: primary/social buttons `loading: isSubmitting`,
all buttons `onPressed: null` while submitting.

## (c) Interactions → navigation (route constants)

| Control | Action | Destination |
|---|---|---|
| Nav back (`backSemanticLabel: 'Back'`) | `context.canPop() ? context.pop() : context.go(OnboardingRoutePaths.valueTour)` (`'/value-tour'`) | P02 value tour |
| `Create account` (valid) | bloc submit → success → `context.go(PrivacyConsentRoutePaths.privacy)` (`'/privacy'`) | P04 privacy |
| `Continue with Apple` | `AuthSocialSubmitted(apple)` → success → go `'/privacy'` | P04 privacy |
| `Continue with Google` | `AuthSocialSubmitted(google)` → success → go `'/privacy'` | P04 privacy |
| Eye toggle | component-internal obscure flip (no route, no bloc event) | — |
| `Terms` / `Privacy Notice` links | v1: inert `TODO(P03)` no-op with button semantics + 44px target (no Terms/Notice routes exist anywhere; adding screens is out of scope) | — |

## (d) Empty / loading / error states

- `initial`/`loading` (members stream pending): render the FULL form immediately — never gate
  the static form on the stream (P01 precedent). `AuthLoadRequested` stays wired for the
  data contract but `items` are not displayed.
- `loaded` (any items incl. empty): identical form.
- Stream `failure`: form still renders and submission still works (offline-tolerant stub).
- Submitting: button spinners + all buttons disabled; fields stay editable=false? No — fields
  stay enabled (component has no global lock); guard is `isSubmitting` in bloc (late
  AuthSubmitted while submitting is ignored).
- Submit failure: `formError` → password-field `errorText` + screen-reader announcement
  (`SemanticsService.announce` or `AlertDialog`? use announce — no new overlay).
- Field errors: shown only after the field was touched or a submit was attempted (no
  red-on-first-paint).

## (e) Accessibility

- Headline `Semantics(header: true)`; subtitle plain text; note icon `ExcludeSemantics`
  (text carries meaning); brand glyphs `ExcludeSemantics` (button label carries it).
- Labels: back 'Back' (component prop), email/password via `NestTextField.label`
  (component wraps field in `Semantics(textField)`), eye via built-in tooltip,
  links expose 'Terms' / 'Privacy Notice' button semantics.
- Tap targets ≥ 44x44 parent rule: back 44, brand/primary buttons 52 high full-width,
  eye 44 (built-in), legal links 44 via padding trick. No kid controls on this screen.
- Text scale 1.3 + width 320: scroll absorbs growth; legal line wraps centered
  (`softWrap`, `textAlign: center`); buttons keep full width; fields keep 52 height
  (text scrolls inside). App-level scaler clamp 1.0–1.3 is app-owned (SPACING_SPEC §10) —
  just verify, don't implement.
- Contrast: token pairs only (ink/paper, ink-2/paper, sky-on-paper links underlined,
  lilac icon is decorative next to 15px semibold text — the TEXT carries the meaning at
  4.5:1+, icon exempt).

## (f) Test plan (mirror `app/test/features/onboarding/welcome_view_test.dart`)

New files (allowed: `app/test/features/auth/**` — dir does not exist yet, create it):
- `app/test/features/auth/auth_bloc_test.dart` — email/password events update state + live
  revalidation; submit invalid → errors set, repo untouched (mock repo, not Drift);
  submit valid → `createAccount(email:)` called once, `submitted` true; repo throws →
  `formError` set, `submitted` false; social → `createAccountSocial` called;
  `AuthSubmitConsumed` clears `submitted`. Also keep a Drift-backed load test via
  `setUpTestScope` (watchItems emits owner row).
- `app/test/features/auth/create_account_view_test.dart` —
  1. light 390 + dark 390: title, subtitle, both brand buttons, 'or', Email/Password labels,
     'At least 8 characters', note, 'Create account', Terms + Privacy Notice links; no '9:41';
     `NestStatusBar` height 47; `tester.takeException()` null.
  2. width x scale matrix (320/390/430 × 1.0/1.3, both themes): no overflow, CTA still visible.
  3. bloc states initial/loading/loaded/failure (fake repo like P01's `_FakeOnboardingRepository`):
     full form renders in ALL FOUR.
  4. validation: type bad email + short password → errors appear, submit disabled
     (`onPressed == null` / opacity .45); fix both → enabled.
  5. submit valid (fake repo success) → route becomes `/privacy` (`currentPath` helper).
  6. submit with throwing repo → error text visible near password field, stays on P03.
  7. Apple/Google taps → `/privacy`.
  8. back tap → pops to `/value-tour`.
  9. a11y: semantics labels (Back, Terms, Privacy Notice, Show/Hide password tooltip),
     every tap target ≥ 44 (measure back/eye/links/buttons), headline header flag,
     brand glyphs excluded.
- Every widget test that pumps the app ends with `disposeApp(tester)` (RULES §7);
  `GoogleFonts.config.allowRuntimeFetching = false`; keys:
  `p03_back`(via NavBar? component has no key slot — wrap in `ValueKey`? `NestNavBar` takes no
  key passthrough issue: it takes `super.key` — pass `key` through? It accepts key in ctor,
  but the BACK BUTTON itself needs the key for tapping: tap by semantics label 'Back'
  instead — no key needed), `p03_apple`, `p03_google`, `p03_email`, `p03_password`,
  `p03_submit`, `p03_terms`, `p03_privacy`.

## (g) SHARED_REQUEST

NONE. No core/app/other-feature edits: glyphs live in feature `presentation/widgets/`,
repo changes stay inside `features/auth/{domain,data}`, routes already registered
(`/create-account`, `/privacy`, `/value-tour`). No schema change (password never persisted).
Do NOT create `SHARED_REQUEST.md`. Known v1 limitation (no Terms/Notice routes → inert links
with `TODO(P03)`) is documented in (c), not a shared request.

Build order for the implementer: glyphs → bloc events/state → repo signature + impl →
view → bloc tests → view tests → `dart format`, `flutter analyze`, `flutter test`,
`shot.sh` light+dark + `compare.py` vs design PNGs.
VERDICT: PASS
