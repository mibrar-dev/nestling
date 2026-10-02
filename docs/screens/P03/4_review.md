# P03 Create account — QA code review (Stage 4, iteration 1)

Scope reviewed: `git diff main` for screen P03 — `app/lib/features/auth/**` (view,
bloc, repo, glyph widgets) + `app/test/features/auth/**` + `docs/screens/P03/**`.
No code was edited by this stage. Reference set: `docs/ARCHITECTURE.md`,
`docs/screens/RULES.md`, `docs/DESIGN_SPEC.md` §5 P03 (line 150),
`docs/design/SPACING_SPEC.md`, `design/html-source/screens/P03-create-account.html`,
`docs/screens/P03/1_plan.md`, `docs/screens/P03/2_build.md`, `3_test.md`,
`SHARED_REQUEST.md`.

Evidence gathered by this stage (not copied from stage 3):

- `flutter analyze` → `No issues found! (ran in 5.1s)`, no ignores.
- `flutter test test/features/auth` → **90 passed, 10 failed** (all 10 in
  `app/test/features/auth/p03_bugs_test.dart`).
- `flutter test test/features/auth/p03_bugs_test.dart --reporter=expanded` → the 10
  red proofs are `P03-BUG-1a…1f`, `P03-BUG-2a…2c`, `P03-BUG-3`.
- Pixel measurement of `design/screens/light/P03-create-account.png` vs
  `docs/screens/P03/ui/light.png` (and the dark pair) at x=3 and over ink rows —
  the CTA divider sits at **y=677 in both designs and y=630 in both app captures**
  (−47dp), the privacy note's ink bottom is 638 vs 622 (clearance to the divider
  **39dp design / 8dp app**), and the caption's two lines are 20dp apart in the
  designs and 44dp apart in the app. Control edges measured over rows:
  email field 22–367 and CTA button 24–366 **in both the design and the app**.
- `git status` confirms only `app/lib/features/auth/**`, `app/test/features/auth/**`
  and `docs/screens/P03/**` are touched — RULES §1 respected, `analysis_options.yaml`
  untouched.

## Checked and clean (no finding)

- **Architecture** — feature-first, `AuthRepository` stays an abstract interface with
  a Drift impl in `data/` (`auth_repository_impl.dart:34-77`), `AuthBloc` is created by
  `registerAuth` and provided at the route level with `AuthLoadRequested`
  (`auth_routes.dart:19-24`), one bloc per screen, `dart analyze` clean. Cross-feature
  route constants (`OnboardingRoutePaths.valueTour`, `PrivacyConsentRoutePaths.privacy`)
  are the established pattern (`welcome_view.dart:43` imports `AuthRoutePaths`).
- **RULES §4 data contract** — the password is never persisted (no such columns; a
  Drift schema assertion backs it), the owner row is idempotent and never renamed for
  an existing owner, `Seed.familyId` respected. `createAccount(name:)` legacy alias is
  only needed by the shared `repositories_test.dart:414` and is documented.
- **Copy** — every string matches DESIGN_SPEC §5 line 150 and the HTML exactly
  (headline, subtitle, both brand labels, `or`, `Email`, `Password`,
  `At least 8 characters`, `No child emails or photos — ever.`, `Create account`,
  `By continuing you agree to our Terms and Privacy Notice`); UK spelling, no US
  variants, no lorem ipsum, em dash matches.
- **Design system** — only DS components are used (`NestStatusBar`, `NestNavBar`,
  `NestBottomCta`, `NestButton`, `NestAppleButton`, `NestGoogleButton`,
  `NestTextField`, `NestIcon`, `NestType.*`, `NestSpacing.*`, `context.nest`); no
  colour, font or radius literal is hard-coded; the two brand glyphs are feature-private
  SVG artwork with the HTML's own geometry (brand hexes are artwork, exempt). The
  `Divider(height: 1, thickness: 1, color: tokens.line)` mirrors the shared
  `nest_list_row.dart:133`.
- **Bottom edge (OWNER rule)** — the CTA's `DecoratedBox` paints `tokens.surface` to
  y=844 with no paper strip in either theme (verified by column scan of `ui/light.png`
  and `ui/dark.png`); no extra home-indicator widget added.
- **Alignment (OWNER rule)** — 20dp gutters, fields 22–367 and the CTA 24–366 in the
  app *and* in the designs; the `Wrap` caption is centre-aligned.
- **Accessibility** — headline is the only `header: true`; `or`-row, glyphs and the
  shield icon are `ExcludeSemantics`; back label, eye tooltip and field labels come
  from the components; every target ≥44dp at 320dp × scale 1.3; submit failure is
  announced via `SemanticsService.sendAnnouncement`; text scale 1.3 has no overflow.
- **Lifecycle / performance hygiene** — both `TextEditingController`s are disposed
  (`create_account_view.dart:39-44`), the `watchItems()` subscription is owned and
  cancelled by the route-level bloc, no `Timer`/animation is started, `_OrRow`,
  `_LegalLine` and the status bar are `const`.
- **Children's Code / privacy** — parent-mode screen, no analytics, no ads, no
  external network call, no child data read or written; the subtitle and the note
  state the privacy position explicitly. The password lives only in memory
  (necessarily in `AuthState`, which is why it stays in `props` for equality) and is
  never logged or persisted.

## Findings

### 1. BLOCKER — the branch ships a red test suite, and 1 of the 10 red proofs cannot be fixed inside RULES §1

`app/test/features/auth/p03_bugs_test.dart` (whole file; the out-of-scope one is
`:291-303`, "P03-BUG-3 the compact nav bar is the design 60dp").

`flutter test test/features/auth` is **90 passed / 10 failed**, so RULES §7
("`flutter test` → all pass") is not met and the screen cannot land. Nine proofs
(`1a…1f`, `2a…2c`) are in P03's own scope and turn green when findings 2 and 3 are
fixed. The tenth, `P03-BUG-3`, asserts `NestNavBar` is 60dp tall, which can only be
true after editing `app/lib/core/design_system/components/nest_nav_bar.dart` — a
shared file P03 may not touch (RULES §1). As it stands the loop cannot converge.

Fix (pick one, in this order):
1. Orchestrator lands the shared fix already filed as `SHARED_REQUEST.md` item 3
   (compact branch gets the spec's 4/12 vertical padding around its 44dp slots);
   the proof then passes as written.
2. Otherwise delete the single `P03-BUG-3` test from this file, keep the shared
   defect in `SHARED_REQUEST.md` item 3, and accept the uniform ~16dp upward offset
   (which is what P01/P02 already ship). Do **not** fork a feature-private 60dp nav
   bar in P03 — that would re-implement a DS component.

### 2. MAJOR — the legal caption is one link per row: the CTA panel is 47dp too tall and it eats the form

`app/lib/features/auth/presentation/views/create_account_view.dart:266-281`
(`_LegalLine` `Wrap`) and `:300-304` (`_LegalLink`'s
`ConstrainedBox(minWidth/minHeight: NestDevice.tapParent)`).

A `Wrap` gives each child its own row at the child's full height, so every link
contributes a 44dp row and the caption becomes 54–80dp instead of the design's ~38dp.
`1_plan.md` §(a) item 4 prescribed exactly the HTML behaviour (`.link {
min-height:44px; margin:-12px 0 }`, `P03-create-account.html:26` — the hit box
*overlaps* its text line); the build took the 44dp constraint without the
compensation, and the caption now overflows the CTA's vertical budget.

Measured this stage from the PNGs (identical in light **and** dark): the CTA's top
hairline is at **y=677 in both design PNGs and y=630 in both app captures** (panel
213dp vs the design's 167dp), and the privacy note's ink bottom is 638 in the design
(39dp clear of the bar) but 622 in the app (**8dp** clear). At 320dp / text scale 1.3
the lower form does not fit at all. This is also the dominant band drift
(compare band 6).

Fix: make the caption a single fixed-height block and hit-test the two spans inside
it instead of giving each link a layout row:
- build the line as `Text.rich(TextSpan(...))` with a `TapGestureRecognizer` per
  link inside a `SizedBox` two lines tall (`NestType.caption` line height × 2, ≈40dp),
  and give the whole block `GestureDetector(behavior: HitTestBehavior.translucent)`
  so the tappable area still reaches 44dp without changing layout; or
- keep the two `Text`s in a `Wrap` with `spacing: 0`, and move the 44dp target to a
  `Stack` whose `Positioned.fill` recognizers live inside the caption's fixed box.
Either way: no `Wrap` child may be 44dp tall. Re-run
`test/features/auth/p03_bugs_test.dart` (1a–1f) — all six must go green.

### 3. MAJOR — a validation error appears on the first keystroke, and on clearing the field

`app/lib/features/auth/presentation/bloc/auth_bloc.dart:35-54` (`_onEmailChanged`)
and `:56-75` (`_onPasswordChanged`).

Both handlers set `emailError` / `passwordError` on *every* change, so typing the
first character of an email shows "Enter a valid email address", typing one password
character shows "Use at least 8 characters" stacked on the helper "At least 8
characters", and clearing either field errors immediately. This contradicts
`1_plan.md` §(b) ("re-validate live **if the field was already errored**") and §(d)
("no red-on-first-paint"), and stage 3's proof `P03-BUG-2a/2b/2c` fails today.

Fix: keep the value write unconditional but gate the error on dirtiness —
`emit(state.copyWith(email: email))` when no error is showing and the field has never
been submitted; set/clear the error only when `state.emailError != null ||
state.submittedOnce` (mirror for the password). Keep the empty-form submit path
(`:84-94`) exactly as it is — `P03-BUG-2d` passes today and must keep passing.

### 4. MINOR — the legal links announce their label twice ("Terms\nTerms")

`create_account_view.dart:297-299` (`Semantics(button: true, label: label)`) wrapping
an `InkWell` whose child is `Text(label)` at `:310`. The explicit label and the inner
`Text` merge into one node, so VoiceOver reads the word twice. This is P03's own
widget (unlike the shared `_BrandButton`, which is `SHARED_REQUEST.md` item 2), so it
is fixable here: drop `label: label` from the `Semantics` (the inner `Text` already
labels the node) or wrap that `Text` in `ExcludeSemantics`. Tighten the assertion at
`app/test/features/auth/create_account_view_test.dart:920` from `contains(...)` to
`equals('Terms')` / `equals('Privacy Notice')` so it cannot regress.

### 5. MINOR — hard-coded 2 / 12 in `_LegalLink`'s padding instead of tokens

`create_account_view.dart:309` — `EdgeInsets.symmetric(horizontal: 2, vertical: 12)`.
Tokens exist for both: `NestSpacing.gap2` (2) and `NestSpacing.s3` (12). Every other
gap in this view is a `NestSpacing` constant; keep the file consistent.

### 6. MINOR — `AuthProvider` is a domain file that ARCHITECTURE does not allow

`app/lib/features/auth/domain/auth_provider.dart:3`. ARCHITECTURE restricts
`domain/` to "entities + abstract `<feature>_repository.dart` ONLY". Move the enum
into `domain/entities/auth_account.dart` (or into `auth_repository.dart`, next to
`createAccountSocial`) and delete the extra file; the import sites stay valid.

### 7. MINOR — a non-`Exception` throw strands the screen in a permanent spinner

`auth_bloc.dart:103-108` and `:118-123` catch only `on Exception`. An `Error` (or any
non-`Exception` thrown from Drift/SDK code) escapes to `Bloc.onError`, so
`isSubmitting` stays `true`: all three buttons spin and are dead, and no `formError`
is ever surfaced — no way back for the user. Fix: `on Object catch (error)` (keep
`stackTrace` for the bloc's error channel) and emit
`state.copyWith(isSubmitting: false, formError: error.toString())`.

### 8. MINOR — the entire form rebuilds on every keystroke

`create_account_view.dart:96-198`: one `BlocBuilder` wraps the whole column, so every
`AuthEmailChanged` / `AuthPasswordChanged` rebuilds both brand buttons (each parsing
inline SVG artwork), the `or` row, the fields and the note. Split it: a
`BlocSelector<AuthBloc, String?>` (or `buildWhen`) on `emailError` / `passwordError`
around the two fields, leaving the static rows to rebuild only on theme/size changes.
The CTA `BlocBuilder` (`:201-223`) is already correctly scoped to `canSubmit` /
`isSubmitting`.

## Notes for the next stage

- Fix 2 and 3 first (they are the two majors), then re-run
  `flutter test test/features/auth` and expect 100/100 once finding 1 is resolved.
- Resolve finding 1 with the orchestrator before the next iteration — the `P03-BUG-3`
  proof is a hard dependency on shared code.
- `SHARED_REQUEST.md` items 1–3 remain accurate; the `title: ''` workaround at
  `create_account_view.dart:83-87` is correctly commented and can be reverted to
  `title: null` when the nav bar is fixed.

VERDICT: FAIL