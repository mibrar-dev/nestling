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

VERDICT: FAIL