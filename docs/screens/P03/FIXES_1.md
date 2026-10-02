# Fix list after iteration 1

## From 3_test.md
# P03 Create account — test notes (Stage 3, iteration 1)

Route `/create-account` · feature `auth` · parent mode. Tests live in
`app/test/features/auth/`; the in-memory Drift DB comes from
`setUpTestScope()` (`Seed.demo` / `Seed.empty` / `Seed.fresh`) and every
test that pumps the app ends with `disposeApp(tester)` (RULES §7). No
`lib/` file was touched by this stage.

## Verdict

**Three real bugs found** (P03-BUG-1/2/3 below, all reproduced by executable
proofs in the new `p03_bugs_test.dart`). Per the Stage 3 brief the screen is
**not** patched here, so `flutter test` on the full suite is **red by
design**: 10 of the 11 proofs in `p03_bugs_test.dart` fail. Everything else
passes (569 green, 10 red).

## Tests added this stage

`auth_bloc_test.dart` 23 → **41** (18 added)

- **In-flight guards (4)** — a second `AuthSubmitted` while one is running is
  ignored (no second repo call), and `AuthSocialSubmitted` is ignored while an
  email submit is in flight and vice-versa. These are the re-entrancy paths
  `auth_bloc.dart:81,115` implement; none had a proof.
- **Fields stay live during a submit (1)** — the plan §(d) promise that the
  user can keep typing while the request is in flight.
- **Transient-failure retry (1)** — first `createAccount` throws, second
  succeeds: the state machine goes `isSubmitting → formError → isSubmitting →
  submitted` without losing the form values.
- **`formError` clearing (2)** — editing either field after a submit failure
  drops the server error (`auth_bloc.dart:42,50,68,74`), which is the
  "recover by typing" path.
- **`AuthSubmitConsumed` is a no-op when nothing was submitted (1)** — the
  guard at `auth_bloc.dart:127` had no proof.
- **A failing members stream (1)** — `AuthLoadRequested` on an erroring
  stream still reaches `AuthStatus.failure` with the message, and the form
  keeps working (the view-level half is in the widget suite).
- **Load never disturbs an in-progress form (1)**.
- **A social submit keeps a stale field error but still submits (1)** — pins
  the current (harmless) behaviour: `emailError` survives a social sign-in.
- **Repository, real Drift (8)** — local-part verbatim incl. dots/`+tag`,
  whitespace-only local-part → `Parent`, an existing owner is never renamed,
  owner row role/detail are right, second call after social keeps one row,
  `watchItems` reflects a later insert, and **the members table has no
  `email`/`password` column at all** (asserted on the schema, so the
  password can never be persisted).

`create_account_view_test.dart` 28 → **40** (12 added) — plus two shared
helpers (`seedDemo`, `repository`) so the fake-repo tests no longer duplicate
`GetIt` plumbing.

- **Submitting state (4)** — all three buttons swap to a
  `CircularProgressIndicator` and stop accepting taps; a slow social sign-up
  blocks the email CTA as well; a failing social sign-up shows the error,
  stays on `/create-account` and leaves the form usable; a **double tap on
  Create account creates exactly one account** (the `isSubmitting` guard seen
  from the UI).
- **Layout geometry (7)** — chrome order top-down, the CTA is the last child,
  20px side gutters on every control, the s3 gap between the password helper
  and the note, 20px brand/shield glyphs, the eye toggle inside the field, a
  34px home-indicator inset clipping nothing, and the bottom-edge owner rule
  in both themes (the bar's `DecoratedBox` paints `tokens.surface` — never
  `tokens.paper` — and reaches y=844).
- **Accessibility (4 more)** — every interactive target clears 44dp at 430dp
  ×1.3, the helper text is not announced as a button, the password input is
  announced as a text field labelled `Password`, and the `or` divider row is
  decorative.

`seeded_submit_test.dart` (new, **7**) — the widget suite drives a fake
repository, so this file closes the loop on the *shipped*
`AuthRepositoryImpl` over real Drift under all three seeds:

- `Seed.demo` — submit advances to `/privacy` and the seeded owner row is
  **not** renamed by a different email (`createAccount` is idempotent).
- `Seed.empty` — same, on an onboarded parent with no children.
- `Seed.fresh` — the email local-part becomes the owner name (`james`).
- Apple and Google against `Seed.fresh` both advance and create one owner row
  named `Parent`.
- The password is never written — asserted on `members.$columns`.
- An invalid form never reaches the repository (the CTA is disabled).

Testing note worth keeping: Drift reads inside a `testWidgets` body must go
through `tester.runAsync` — a query stream's first event is scheduled on the
real event loop, which the fake-async test clock never advances. Seeding
itself must **not** be wrapped (that deadlocks). Both are documented in the
file header.

## Results (`app/`)

- `dart format --set-exit-if-changed .` → `Formatted 357 files (0 changed)`.
- `flutter analyze` → `No issues found! (ran in 3.3s)` — no ignores added.
- `flutter test test/features/auth` → **81 passed** (`auth_bloc_test.dart` 41,
  `create_account_view_test.dart` 40).
- `flutter test test/features/auth/seeded_submit_test.dart` → **7 passed**.
- `flutter test` (full suite) → **569 passed, 10 failed** — every failure is
  one of the `p03_bugs_test.dart` proofs below, nothing else.
- `shot.sh` light + dark on the assigned simulator, `compare.py` against both
  design PNGs → `ui/light.png`, `ui/dark.png`, `ui/compare-light.png`,
  `ui/compare-dark.png`. Mean diff 13.14% light / 12.21% dark; bands 2 and 6
  (the Apple button and the CTA) carry the drift BUG-1 explains.

## Bugs found

### P03-BUG-1 (MAJOR) — the legal caption is one link per row, so the bottom
### bar is 47dp too tall and the privacy note is clipped

`app/lib/features/auth/presentation/views/create_account_view.dart:259-315`
(`_LegalLine` / `_LegalLink`).

`_LegalLine` is a `Wrap` whose link children are
`ConstrainedBox(minHeight: NestDevice.tapParent)` (`:300-304`). A `Wrap` gives
each child its own row at the child's full height, so every link contributes a
**44dp** row instead of sharing the 18dp caption line. The HTML does the
opposite — `.link { min-height: 44px; margin: -12px 0 }`
(`design/html-source/screens/P03-create-account.html:26`): the 44dp hit box
*overlaps* its text line and the caption stays two 18dp lines. Plan
`1_plan.md` §(a) item 4 even called for "the HTML `.link` trick: `Padding(12,
2)` + negative margin compensation"; the build took the `ConstrainedBox`
without the compensation.

Measured (light PNG, `compare.py` sheet, and the proofs in
`p03_bugs_test.dart`):

| | design | shipped | delta |
|---|---|---|---|
| caption block | ~38dp | 80dp (140dp at scale 1.3) | +42dp |
| CTA panel height | 167dp | 172dp | +5dp… |
| CTA panel height (320dp, 1.3) | — | 242dp | — |
| CTA top edge | y=677 | y=630 | −47dp |
| note clearance above the bar | 35dp | 4dp | −31dp |
| form fits without scrolling | yes | **no** | — |

Because the panel is bottom-anchored and over-tall, it eats the form above
it: at 390×844 the note "No child emails or photos — ever." is clipped by
the bar (widget proof: note bottom 709 vs CTA top 672; in the light PNG the
note sits 4dp from the divider against the design's 35dp), and at text scale
1.3 the whole lower form is cut off. This is also the dominant contributor to
the 32.67% / 26.33% drift in compare band 6.

Repro: `flutter test test/features/auth/p03_bugs_test.dart` — proofs
P03-BUG-1a…1f. Fix direction: reproduce the HTML trick (negative margin or a
zero-height overlay hit area) so the caption is two 18dp lines while both
links keep a 44dp target.

### P03-BUG-2 (MAJOR) — a validation error appears on the first keystroke

`app/lib/features/auth/presentation/bloc/auth_bloc.dart:35-75`
(`_onEmailChanged`, `_onPasswordChanged`).

Both handlers set `emailError` / `passwordError` on **every** change, so the
moment the user types the first character of an email the field shows "Enter
a valid email address", and the first character of a password shows "Use at
least 8 characters" on top of the helper "At least 8 characters". Clearing
the field also errors immediately.

This contradicts plan §(b) ("if the field was already errored, re-validate
live") and §(d) ("field errors: shown only after the field was touched or a
submit was attempted — no red-on-first-paint"), and it is the behaviour the
rest of the app avoids. Repro: type one character into either field.

Proofs P03-BUG-2a/2b/2c. Note P03-BUG-2d **passes**: submitting an empty
form still surfaces both errors, so the fix must not remove that path.

### P03-BUG-3 (MINOR) — the compact nav bar is 44dp against the design 60dp

`app/lib/core/design_system/components/nest_nav_bar.dart:42-81` (shared, not
editable by this screen) — `compact: true` is a bare 44dp row. The design's
`.nav-bar.compact` is 4px top padding + a 44px button + 12px bottom
(`design/html-source/screens/P03-create-account.html:58`), i.e. **60dp**. The
whole form therefore renders ~16dp higher than the design (measured band
offset is a consistent −14…−16dp from the headline down to the note).

This is shared code, so it is filed for the orchestrator rather than patched
— see the new SHARED_REQUEST item. P02 already hit the same bar and shipped a
feature-private 60px `_TourNav` as a workaround; if the same treatment is
wanted here, `1_plan.md` §(a) item 2 needs updating too (it prescribes
`NestNavBar(compact: true)`).

## Non-blocking observations

- The design's own PNG shows a home-indicator pill; the app shows none. This
  simulator does not draw the pill in `simctl` captures at all (verified
  against a springboard screenshot), so it is a capture artefact, not a
  screen defect. The bottom-edge rule itself holds: the CTA's `surface`
  colour runs to y=844 with no page tint below, in both themes.
- Brand-button semantics announce the label twice
  ("Continue with Apple\nContinue with Apple") — shared `_BrandButton`
  behaviour, already SHARED_REQUEST item 2, unchanged and non-blocking.
- The blocked `createAccount(name:)` legacy alias in
  `auth_repository_impl.dart` still exists solely for the shared
  `app/test/core/data/repositories_test.dart`; unchanged this iteration.


## From 4_review.md
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


## From 5_ui.md
# P03 Create account — UI check (Stage 5, iteration 1)

Route `/create-account` · parent mode · `SEED=fresh` · child maya · simulator BC440E48-B3A3-43BC-971B-0EF5DB621874 (390×844).
No `ORCHESTRATOR_NOTES.md` exists — only the standing orchestrator overrides apply (PIP vacuous here:
no Pip on this screen; status-bar time ignored; bottom-edge OWNER rule enforced).
Design sources: `design/screens/light/P03-create-account.png`,
`design/screens/dark/P03-create-account.png` (1170×2532 @3x → logical 390×844),
`design/html-source/screens/P03-create-account.html`, DESIGN_SPEC §5 P03, SPACING_SPEC §§1–2,9–11.
No code edited in this stage.

## Captures

- `bash tools/screens/shot.sh $PWD/app /create-account $PWD/docs/screens/P03/ui/app_light_1.png BC440E48-B3A3-43BC-971B-0EF5DB621874 light fresh parent maya` → stable frame saved.
- Same with `dark` → `app_dark_1.png` → stable frame saved.
- `python3 tools/screens/compare.py design/screens/light/P03-create-account.png docs/screens/P03/ui/app_light_1.png docs/screens/P03/ui/cmp_light_1.png`
- `python3 tools/screens/compare.py design/screens/dark/P03-create-account.png docs/screens/P03/ui/app_dark_1.png docs/screens/P03/ui/cmp_dark_1.png`
- Read `cmp_light_1.png`, `cmp_dark_1.png`, both app shots, and both design PNGs with the file reader.

## Mean diff

- Light: **13.15%** — bands (0) 0–105: 2.63% · (1) 105–211: 15.65% · (2) 211–316: 31.53% · (3) 316–422: 5.24% · (4) 422–527: 3.50% · (5) 527–633: 5.35% · (6) 633–738: 32.67% · (7) 738–844: 8.75%.
- Dark: **12.21%** — bands (0) 0–105: 2.59% · (1) 105–211: 16.22% · (2) 211–316: 29.70% · (3) 316–422: 5.96% · (4) 422–527: 3.80% · (5) 527–633: 5.60% · (6) 633–738: 26.33% · (7) 738–844: 7.63%.
- Worst bands are 2 (Apple/Google zone) and 6 (CTA/legal zone) in both themes; bands 3–5 (or-row, fields, note) sit at 3–6% — the mid-form matches well.

## Checked and matching (not deviations)

- Presence/order/copy: back chevron, `Create your family account`, `You're the grown-up in charge. Children never need an email.`, `Continue with Apple`, `Continue with Google`, `or` with hairline dividers, `Email`, `Password`, eye toggle, `At least 8 characters`, shield + `No child emails or photos — ever.`, `Create account`, `By continuing you agree to our Terms and Privacy Notice` (both links, sky + underline). All present, in order, correct UK copy.
- Icon choice: Apple single-path glyph and 4-colour `G` match the HTML artwork; eye and shield-check icons correct; lilac shield, sky links in both themes.
- Dark-mode flips correct: Apple black→white bg, Google white→near-black bg with grey border, fields/labels/links resolve to dark tokens. The muted-green CTA in the app is the *disabled* state (see 5), not a theme bug.
- Alignment (OWNER): 20 px side gutters hold; email-field edges 22–367 and CTA edges 24–366 in design and app.
- Bottom edge (OWNER): below the `NestBottomCta` panel to y=844 the app is uniform surface (light `#FFFFFF`, dark `#1F1C2E`) — no paper/meadow strip, no coloured ring around the home area, in either theme. Passes the OWNER rule.
- No overflow, clipping, or unwanted ellipsis at 390 width; button radii (pill), field radius (16), and shadows match.

## Deviations (element, design value, app value, fix)

1. Whole scroll content sits ~14–16 dp too high (shared nav-bar defect). Headline ink starts design y≈120 vs app y≈104; Apple-button top design y≈254 vs app y≈238; email-field top border design y≈426 vs app y≈412 (all at 390×844 logical, ±2). Bands 1–2 glow red from this alone. Fix: orchestrator-owned — compact `NestNavBar` must render the spec 60 dp block (4/12 vertical padding around the 44 dp slots) per `SHARED_REQUEST.md` item 3. P03 must not fork a private nav bar.
2. Headline wraps to different lines. Design: line 1 `Create your` / line 2 `family account`. App: line 1 `Create your family` / line 2 `account` (both themes; clearly visible in the diff heat-map). Same 20 px gutters, so the text block metrics differ (H1 size/weight/letter-spacing or available width a few px off). Fix: verify the H1 token application against SPACING_SPEC type scale (28/34 w900) and the scroll's horizontal padding; keep the design's break.
3. Bottom-CTA panel top edge 47 dp too high. Gutter-luminance scan: design paper→surface transition at y≈677 (surface 677–844 = 167 dp panel); app at y≈630 (630–844 = ~214 dp panel) — identical in light and dark. The privacy note's clearance above the bar is 39 dp in the design vs ~8 dp in the app, so the lower form is visibly cramped. Fix: deviation 1 accounts for ~16 dp; the remaining ~31 dp is deviation 4. Fix 4 first, then re-measure; residual offset needs the shared nav fix (1).
4. Legal caption line gap is ~2× the design. Design: `Terms` underline rows y≈762–768, `Privacy Notice` rows y≈780–788 — line gap ≈20 dp. App: the two links sit on rows ~44 dp apart (each `Wrap` child carries a full 44 dp-high link box, so the caption is 54–80 dp tall instead of ~38 dp). This is the same defect as review finding 2 and the dominant cause of band 6 (32.67% / 26.33%). Fix (P03 scope): render the caption as one fixed two-line-high `Text.rich` block with a `TapGestureRecognizer` per link (HTML `.link` behaviour: 44 dp hit area via overlap, not layout height) — no `Wrap` child may be 44 dp tall.
5. Recorded non-finding (do not fix): app fields are empty and the CTA is disabled-faded, while the design shows `sarah@example.co.uk` + dotted password and a solid-green enabled CTA. Empty/disabled is the correct initial state under `SEED=fresh` (plan §(b): `email ''`, submit enabled only when both fields validate); the design shows mock content. Likewise the OS status-bar time (design `9:41` vs simulator `12:06`/`12:07`) is ignored per the orchestrator status-bar rule, and the app correctly shows no mock home-indicator pill (surface runs to the edge per the OWNER rule; the design's mock pill + paper strip are superseded).

A designer would reject the screen as captured: the headline rewrap (2), the CTA riding 47 dp high with a cramped note (3), and the double-spaced legal line (4) are all visible at a glance in both themes, with bands 2 and 6 at 26–33% diff.


## From 6_bugs.md
# P03 Create account — bug hunt (Stage 6, iteration 1)

Route `/create-account` · feature `auth` · parent mode · design
`design/screens/{light,dark}/P03-create-account.png` + HTML source. Tree
tested: worktree `screen/P03` at `2027506` (a `main` merge that arrived
**during this stage** and fixed the shared nav-bar defect) plus the stage's
uncommitted auth work. **No screen code was changed by this stage** — only
`app/test/features/auth/**`, `SHARED_REQUEST.md` and this report.
`ORCHESTRATOR_NOTES.md` also arrived during the stage; its six mandatory
items are mapped in the ledger section. The standing orchestrator rules
(PIP — vacuous here, status bar, data-over-mocks, bottom edge, alignment)
were applied.

Executable proofs: `app/test/features/auth/p03_bugs_test.dart` — every open
bug's proof is `skip:`-marked with its id so the suite stays green (12
skipped). Run `flutter test test/features/auth/p03_bugs_test.dart
--run-skipped` to watch all of them fail; un-skip each one with its fix.

## Ledger

| ID | Severity | Area | Status |
|---|---|---|---|
| P03-BUG-1 | **MAJOR** | legal caption = one 44dp link row per line; CTA panel too tall, form eaten | open, in scope |
| P03-BUG-2 | **MAJOR** | validation error on first keystroke / on clearing a field | open, in scope |
| P03-BUG-3 | minor | compact nav bar 44dp vs design 60dp | **fixed** by shared merge `2027506`; proof green |
| P03-BUG-4 | minor | legal links announce "Terms\nTerms" | open, in scope |
| P03-BUG-5 | minor | non-`Exception` repo failure strands the screen in a permanent spinner | open, in scope |
| P03-BUG-6 | minor | `NestButton` announces "Create account\nCreate account" | open, shared (SHARED_REQUEST §4) |
| P03-BUG-7 | minor | headline breaks "Create your family / account", not the design's "Create your / family account" | open, in scope |
| P03-BUG-8 | minor | password helper indented 20dp instead of sitting on the 20dp gutter | open, in scope or shared `NestTextField` |

`docs/screens/P03/ORCHESTRATOR_NOTES.md` arrived on disk **during** this stage;
its six mandatory items are covered here: (1) header offset — fixed by the
shared merge `2027506`; (2) title break — P03-BUG-7; (3) filled-state
comparison — a widget test now pins it
(`create_account_view_test.dart`, "design filled state") and the filled
simulator capture is UI-stage work for iteration 2; (4) helper alignment —
P03-BUG-8; (5) legal footer — the P03-BUG-1 fix; (6) note row — checked,
the row's left edge is the 20dp gutter with the icon 20dp and the 8dp gap
(stage-3 proof green).

## P03-BUG-1 (MAJOR) — the legal caption is one 44dp link row per line, so the CTA panel is too tall and eats the form

**Where** `app/lib/features/auth/presentation/views/create_account_view.dart`
(`_LegalLine`:259-282, `_LegalLink`:284-316). `_LegalLink` is a
`ConstrainedBox(minWidth/minHeight: NestDevice.tapParent)` inside a `Wrap`, so
each link contributes its own **44dp row** to the caption instead of sharing
the text line. `1_plan.md` §(a).4 prescribed the HTML behaviour —
`.link { min-height:44px; margin:-12px 0 }` (`P03-create-account.html:26`):
the 44dp hit box *overlaps* its 18dp text line.

**Repro** Open `/create-account` (any seed — the form is static, light or
dark). The legal caption is ~2× the design's height, the bottom CTA border
sits at y≈630 instead of the design's y=677, and the privacy note has ~8dp
clearance instead of ~39dp (clipped/needs scrolling at 390×844; worse at
320dp × text scale 1.3).

**Proofs** `P03-BUG-1a` caption 80.0dp vs the harness bound 58dp;
`P03-BUG-1b` CTA panel 172.0dp vs 150dp; `P03-BUG-1c` panel 232.0dp at scale
1.3 vs 170dp; `P03-BUG-1d` caption 140.0dp at 320dp × 1.3 vs 100dp. All fail
today (`--run-skipped`).

**Evidence**

- Widget harness (current tree): caption block **80.0dp**; `NestBottomCta`
  **172.0dp** at 390×844; **232.0dp** at 390×844 × 1.3; caption **140.0dp** at
  320×844 × 1.3. (Bounds are calibrated for the harness' ~1em-per-glyph test
  font, which wraps this sentence to 3 lines at 390dp and 4 at 320dp × 1.3
  where the real fonts use 2; the *design* bound is 2×18dp ≈ 38dp.)
- Device captures (stage 5, `ui/app_light_1.png` / `app_dark_1.png`): CTA top
  hairline y≈630 in both app shots vs **677** in both design PNGs; the privacy
  note's ink bottom is 622 (≈8dp clear) vs 638 in the design (≈39dp clear);
  compare band 6 = 32.67% light / 26.33% dark, the dominant drift.

**Suggested fix** Make the caption a single fixed-height block and move the
44dp targets *out of layout* — e.g. `Text.rich` (or two `Text` widgets) with
`TapGestureRecognizer`s, wrapped so the tappable area reaches 44dp via
overlap (`GestureDetector(behavior: HitTestBehavior.translucent)`,
`Positioned.fill` recognizers or the HTML negative-margin trick). No caption
child may contribute 44dp of height; keep the `p03_terms` / `p03_privacy`
keys and their 44dp targets. Then delete the four `skip:`s and re-run.

## P03-BUG-2 (MAJOR) — a validation error appears on the first keystroke and when a field is cleared

**Where** `app/lib/features/auth/presentation/bloc/auth_bloc.dart`
(`_onEmailChanged`:35-54, `_onPasswordChanged`:56-75). Both handlers set
`emailError`/`passwordError` on **every** change.

**Repro** Type `s` into Email → “Enter a valid email address” appears under a
half-typed address. Clear the field → the error appears (or never leaves).
Type `n` into Password → “Use at least 8 characters” stacked under the
identical helper text.

**Proofs** `P03-BUG-2a`, `P03-BUG-2b`, `P03-BUG-2c` (fail today). `P03-BUG-2d`
(“submitting an empty form still shows both errors”) **passes** and must stay
green — the fix must keep the submit path.

**Suggested fix** Keep writing the value unconditionally; only set/clear the
error when the field was already errored or a submit was attempted
(`1_plan.md` §(b): “re-validate live *if the field was already errored*”;
§(d): “no red-on-first-paint”). NB the passing view test
`create_account_view_test.dart:365-399` (“bad input errors and disables
submit”) currently pins the buggy behaviour — it enters `not-an-email` and
expects an immediate error and must be updated in the same fix (blur/submit
or a previously-shown error).

## P03-BUG-3 (minor) — compact nav bar 44dp vs the design 60dp — FIXED

The shared “onboarding header” fix (`fc981bc`) landed into this worktree via
merge `2027506` while this stage ran: `NestNavBar(compact: true)` now renders
4+44+12 = **60dp** (`.nav-bar.compact`, `P03-create-account.html:58`). The
former proof is now green, un-skipped and kept as a regression guard; no
action for P03. Cleanup opportunity (not a bug): with the null-title crash
also fixed, `create_account_view.dart:83-87` can pass `title: null` instead of
`title: ''`.

## P03-BUG-4 (minor) — the legal links announce their label twice

**Where** `create_account_view.dart` `_LegalLink` — explicit
`Semantics(button: true, label: label)` wraps an `InkWell` whose inner `Text`
carries the same string; both merge into one node, so assistive tech reads
“Terms, Terms” / “Privacy Notice, Privacy Notice”.

**Repro** Enable a screen reader on `/create-account` and step through the
caption; or dump the semantics tree (one node labelled `Terms\nTerms`).

**Proof** `P03-BUG-4` (fails today: `find.bySemanticsLabel('Terms\nTerms')`
finds the node). **Suggested fix** Drop `label:` from the `Semantics` (the
inner `Text` labels the node) or wrap that `Text` in `ExcludeSemantics`;
tighten `create_account_view_test.dart:908-922` from `contains(...)` to exact
labels so it cannot regress. This is P03's own widget, unlike P03-BUG-6.

## P03-BUG-5 (minor) — a non-`Exception` repository failure strands the screen in a permanent spinner

**Where** `auth_bloc.dart` `_onSubmitted`:106 and `_onSocialSubmitted`:121 —
`on Exception catch` only. An `Error` (`StateError`, `RangeError`,
`AssertionError`, …) escapes the handler; `isSubmitting` stays `true` and
`formError` stays `null`, so all three buttons spin forever with no way out.

**Repro** Point the repository at a failing implementation that throws a
`StateError` and submit. The error is reported as an unhandled zone error and
the UI never recovers.

**Proof** `P03-BUG-5` (a plain `test` that builds the bloc inside
`runZonedGuarded`): today `unhandled` is `StateError: Bad state: boom-error`,
`isSubmitting` is `true` and `formError` is `null`.

**Suggested fix** Catch `Object` in both handlers (`on Object catch (error,
stackTrace)`) and emit `isSubmitting: false, formError: error.toString()`.
Keep `stackTrace` for the bloc error channel.

## P03-BUG-6 (minor, shared) — `NestButton` announces its label twice

**Where** `app/lib/core/design_system/components/nest_button.dart:151-153` —
`Semantics(button: true, label: widget.label)` merges with the inner
`Text(widget.label)`; the P03 submit CTA reads
`Create account\nCreate account` (same mechanism as SHARED_REQUEST §2 for the
brand buttons). Core file: **P03 must not patch it**; filed as
`SHARED_REQUEST.md` §4. **Proof** `P03-BUG-6` (skipped until the core fix
lands).

## P03-BUG-7 (minor) — the headline does not take the design's line break

**Where** `create_account_view.dart:101-108` — the headline `Text` fills the
350dp content width, so it breaks "Create your family / account"; the design
(HTML `.h1 { text-wrap: balance }`) breaks **"Create your / family account"**
(ORCHESTRATOR_NOTES §2, which supersedes the UI stage's "deviation" wording
and makes the design break mandatory; no hard `\n` allowed).

**Repro** Open `/create-account` at 390dp: line 1 ends with "family" instead
of "your" (visible in both design PNGs vs `ui/app_light_1.png`; compare bands
1–2 glow from it).

**Proof** `P03-BUG-7` asserts the title column is width-capped
(`Text` render width ≤ 260 at 390dp; today it is 350). The harness fallback
font is too wide for break-pattern assertions, so the bound encodes the
real-font reason: measured with the app's Nunito 900, "Create your" = 158.6,
"Create your family" = 251.2, "family account" = 197.7 — any cap in
**[198, 252)** produces the design break at scale 1.0 and still wraps
sensibly at 320dp and scale 1.3. **Suggested fix** `ConstrainedBox(maxWidth:
240)` (or equivalent) around the headline; verify the break on the simulator
in the UI stage.

## P03-BUG-8 (minor) — the password helper is indented instead of sitting on the field gutter

**Where** `NestTextField` renders `helperText`/`errorText` inside the
Material `InputDecoration`, which indents them by the field's content padding:
measured helper left **40** vs the field/label left **20**, and 4dp below the
input instead of the design's 6dp (`.field { display:flex; flex-direction:
column; gap:6px }`, helper is a column child at the field's left edge).

**Repro** Open `/create-account`: "At least 8 characters" starts 20dp inside
the field's left edge (and any validation error follows the same indent),
against the design's gutter alignment (ORCHESTRATOR_NOTES §4).

**Proof** `P03-BUG-8` (`helper.left == field.left`; today 40 vs 20).
**Suggested fix** Cleanest is a shared `NestTextField` change (align
helper/error to the input's left edge, 6dp below the field) which also fixes
every other form; otherwise render the helper as a feature-owned `Text`
6dp under the field and stop passing `helperText`. Both are acceptable; the
first should go through `SHARED_REQUEST` if the build stage prefers it.

## Checked — no bug found

- **Kid-mode guard** — `APP_MODE=kid` + `Session.appMode='kid'` deep-linking
  `/create-account` redirects to `/parental-gate` (probe; the router's
  `_onboardingLocations` + `isParentOnly` path works for P03).
- **Restart / Drift persistence** — create an account on `Seed.fresh`, land
  on `/privacy`, rebuild the app over the same DB and return to
  `/create-account`: exactly one owner row (`james`), no rename of an existing
  owner, password never written (also covered by `seeded_submit_test.dart`).
- **Back / deep links** — no history → back goes to `/value-tour`; the form
  renders identically on `Seed.fresh`, `Seed.empty` and `Seed.demo` (the
  members list is never displayed).
- **Rapid double taps** — the `isSubmitting` re-entrancy guard blocks a second
  submit while one is in flight (existing proof). An Apple double-tap can call
  the repository twice only after the first call has already completed; the
  repository is idempotent (`_ensureOwner` no-op) and the screen navigates
  once — no user-visible effect.
- **Text scale 1.3 + width 320/390/430** — the matrix produces no overflow and
  the CTA stays reachable; the caption defect is P03-BUG-1. The headline
  `maxLines: 3` clip that appears with the harness' fallback font is **not** a
  product bug: measured with the app's real cached Nunito 900, the headline
  fits 2 lines at every width and at scale 1.3 (the app clamps the scaler at
  1.3), so no proof was filed.
- **Dark-mode contrast** (computed from the tokens): light ink/paper 15.5:1,
  ink2/paper 8.3:1, sky/surface 5.5:1, danger/surface 5.1:1, white-on-leaf
  5.0:1; dark ink/paper 16.3:1, ink2/paper 10.8:1, sky/surface 7.1:1,
  danger/surface 6.6:1, onLeaf/leaf 8.4:1. All text pairs ≥ 4.5:1; the lilac
  shield icon is decorative at 3.7:1 light (≥ 3:1). Disabled CTA is exempt.
- **0 / 1 / 6 children, long UK names, empty lists** — N/A for this screen:
  the form is static, only the `members` stream loads, and the owner display
  name (email local-part) is never rendered on P03.
- **£0.00 / £999.99 / 9999 coins / integer-pence rounding** — N/A: P03 renders
  no money.
- **Timezone / BST** — N/A: P03 uses no dates or times; `createAccount`
  doesn't touch the clock.
- **Async gaps** — controllers are disposed; the `BlocListener` navigation
  reads state synchronously before any await; `emit` after close is a no-op
  in bloc 9.2.1 (verified in the library source). No pending-timer warnings.
- **Known v1 limitation, not a bug** — the two legal links are deliberately
  inert (`TODO(P03)`: no Terms/Notice routes exist) per `1_plan.md` §(c).
- **Minor polish (not filed)** — the email field cannot disable
  autocorrect/suggestions because `NestTextField` exposes no such param
  (build deviation 3); a failed submit shows the raw
  `error.toString()` under the password field, which the plan prescribed.

## Suite state at hand-off (`app/`)

- `dart format --set-exit-if-changed .` → `360 files (0 changed)`.
- `flutter analyze` → `No issues found!` (no ignores added).
- `flutter test test/features/auth` → **92 passed, 12 skipped, 0 failed**.
- `flutter test` (full) → **579 passed, 12 skipped, 0 failed**.
- The 12 skips are exactly the open-bug proofs: `P03-BUG-1a…1d`,
  `P03-BUG-2a…2c`, `P03-BUG-4`, `P03-BUG-5`, `P03-BUG-6`, `P03-BUG-7`,
  `P03-BUG-8`. `P03-BUG-3` and `P03-BUG-2d` run green; the new filled-state
  design pin passes. `--run-skipped` fails all 12 for the reasons above.

## Verdict

Two MAJOR bugs remain open (P03-BUG-1 caption/CTA geometry, P03-BUG-2
first-keystroke validation) plus five minor ones, so this stage does not
pass. Fix P03-BUG-1 and P03-BUG-2 first, then the P03-local minors
(P03-BUG-4/5/7/8) and un-skip their proofs; P03-BUG-6 needs the shared core
fix.

