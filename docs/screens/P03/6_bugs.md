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

VERDICT: FAIL
