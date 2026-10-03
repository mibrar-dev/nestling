# Fix list after iteration 2

## From 3_test.md
# P03 Create account — test notes (Stage 3, iteration 2)

Route `/create-account` · feature `auth` · parent mode. Tests live in
`app/test/features/auth/`; the in-memory Drift DB comes from
`setUpTestScope()` (`Seed.demo` / `Seed.empty` / `Seed.fresh`) and every test
that pumps the app ends with `disposeApp(tester)` (RULES §7). No `lib/` file
was touched by this stage.

## Verdict

**Three real bugs found** (P03-BUG-9/10/11, all new). The iteration-2 build
fixed everything iteration 1 reported — I verified each fix against the
design on the simulator, not just against the proofs — but the caption
rewrite introduced two new defects and left a third from the shared field
component. Per the brief the screen is **not** patched, so `flutter test` is
**red by design**: 7 of the proofs in `p03_bugs_test.dart` fail. Everything
else passes (600 green, 1 skipped, 7 red).

## The iteration-2 fixes, verified

Every iteration-1 finding is genuinely fixed. On-device evidence from
`shot.sh` (BC440E48) plus `compare.py`:

| | iteration 1 | iteration 2 | design |
|---|---|---|---|
| mean diff, light | 13.14% | **5.08%** | — |
| mean diff, dark | 12.21% | **4.61%** | — |
| compare band 6 (CTA) | 32.67% | 15.76% | — |
| CTA panel top | y=630 | **y=682** | y=677 |
| caption height | 80dp | two text lines | two text lines |
| note clearance above the bar | 4dp | **38dp** | 35dp |
| headline break | "Create your family / account" | **"Create your / family account"** | same |
| compact nav bar | 44dp | **60dp** | 60dp |

Per-band, the app now lands within **0–5dp** of the design for every
element (back chevron 65.0–80.7 vs 65.0–80.7; Apple 255–306.7 vs 255–306.7;
email field 445–496.7 vs 443–494.7; note 627.7–644 vs 625.7–642). The
bottom-edge owner rule holds in both themes: the CTA's `surface` colour runs
to y=844 with no page tint under it. ORCHESTRATOR_NOTES §1 (shared header),
§2 (headline break), §4 (helper on the gutter, 6dp under the field) and §6
(note row on the 20dp gutter) are all satisfied and now pinned by tests;
§3's filled state is pinned by the existing `design filled state` group.

## Tests added this stage

`auth_bloc_test.dart` 41 → **45** (4 added) — the dirty-gating paths the
P03-BUG-2 fix introduced, none of which had a proof:

- **A rejected submit arms live validation for both fields**, and each field
  then clears only its own error as it is fixed.
- **Clearing a field after a rejected submit re-shows its error** — the
  `submitAttempted` flag is sticky, which is the intended trade (no red on
  the first keystroke, red forever after a real submit attempt).
- **A social sign-up never arms field validation** — a failed social submit
  must show only the server error, never "Enter a valid email address".
- **A valid submit after a rejected one still reaches the repository**, with
  the full seven-state sequence pinned.

`create_account_view_test.dart` 43 → **48** (5 added):

- **The helper is replaced by the error and comes back** (never both at
  once) — the P03-BUG-8 helper row and the field error share one slot.
- **A stale server error also displaces the helper, then both recover**.
- **The legal links are 44dp targets with a tap action** — label, button
  flag, `SemanticsAction.tap` (VoiceOver activation) for both.
- **Back pops when a route is stacked** — the `canPop` branch of
  `_onBack`, previously untested (only the deep-link `go('/value-tour')`
  branch had a proof); drives a real `GoRouter` with `/` pushing
  `/create-account`.
- **The three helper/error recovery assertions run in dark mode too**, where
  the error/helper colours differ.

`p03_bugs_test.dart` 13 → **20** (7 new proofs, all RED — the bugs below).
The other 13 proofs (BUG-1/2/3/4/5/7/8 + the skipped shared BUG-6) are green
regression guards.

Total feature tests: 104 → **121** (113 green, 1 skipped, 7 red).

## Bugs found

### P03-BUG-9 (MAJOR) — the caption splits the "Privacy Notice" link, leaving a
### lone underlined "Notice" on the second line

`app/lib/features/auth/presentation/views/create_account_view.dart:328-340`
(`_LegalLine`'s `Text.rich`).

The caption renders as plain text and lets the line breaker fall where it
likes. With the app's Inter the sentence fits one word further than the
design's font did, so the break lands **inside** the link:
`…Terms and Privacy` / `Notice`. Measured on the device
(`ui/light.png`, light): caption line 1 spans x 37–354 (nine word runs ending
in "Privacy"), line 2 is a single 41dp run at x 175–215 with an underline
band directly under it — one dangling underlined word.

ORCHESTRATOR_NOTES §5 (mandatory) requires
`By continuing you agree to our Terms and` / `Privacy Notice`. Proof:
P03-BUG-9 / 9b — the label's layout boxes, read off the caption's own
`RenderParagraph`, must all sit on a single caption line, at 320/390/430 ×
1.0/1.3. Fix direction: make the two-word label unbreakable (U+00A0 between
the words) — this is also why the QA screenshot reads differently from the
design even though the caption's *height* is now right.

### P03-BUG-10 (MAJOR) — the 44dp link targets no longer sit over the words
### they represent

`app/lib/features/auth/presentation/views/create_account_view.dart:342-355`
and `367-390` (`_LegalLine`'s `Positioned.fill` overlay + `_LegalHitTarget`).

The P03-BUG-1 fix replaced the `Wrap` with a zero-height overlay that
centres both targets as **one adjacent 88dp block**
(`Row(mainAxisSize: min)`, x 151–239 at 390dp, both on the same row, gap 0)
while the words they claim to represent sit elsewhere. Measured at every
width: the "Terms" target does not overlap the word "Terms" (390: target
151–195 vs label 89–155) and neither does the "Privacy Notice" target.
Tapping the visible underlined "Terms" at the end of caption line 1 does
nothing, while the middle of the sentence — plain words, not links — is
covered by two invisible buttons.

This is a regression introduced by the iteration-2 fix: in iteration 1 each
target wrapped its own label, so a tap on the word hit its target. The links
are inert in v1 (`TODO(P03)`), so there is no user-visible failure yet, but
the touch targets are simply in the wrong place and will stay wrong when the
routes land. Proofs: P03-BUG-10 (320/390/430, overlap of each target with
its own label) and P03-BUG-10b (the targets can never touch — the words
" and " always separate the two links).

### P03-BUG-11 (MINOR) — the validation error is indented 20dp while the
### helper it replaces sits on the gutter

`app/lib/features/auth/presentation/views/create_account_view.dart:181-217`
(password field) — the error comes from the shared `NestTextField`'s
`errorText`, which Material renders 20dp inside the field, while
ORCHESTRATOR_NOTES §4 (and the iteration-2 BUG-8 fix) moved the helper onto
the 20dp gutter. Measured: helper `left = 20`, error `left = 40`. The text
therefore jumps 20dp sideways the moment an error appears — the same defect
§4 fixed for the hint, left in place for the error line. The design's
`.field` is a flex column (`.field .error`, `components.css:134`), so label,
input, hint and error all share the gutter.

Proof: P03-BUG-11. Fix direction: own the error row the way the helper row is
owned now (the screen may also want a shared fix for `NestTextField`'s
errorText padding — filed as SHARED_REQUEST §5).

## Non-blocking observations

- `submitAttempted` is never reset. It is harmless today (the bloc is
  route-scoped and a successful submit navigates away), but it means any
  later refactor that keeps the bloc alive after navigation would inherit
  permanently-dirty fields. Pinned by the "clearing a field after a rejected
  submit re-shows its error" proof so the behaviour is a decision, not an
  accident.
- The design PNG shows a home-indicator pill; the app shows none. Verified
  again this iteration to be a capture artefact: this simulator does not
  draw the pill in `simctl` screenshots at all (a springboard capture shows
  none either). The bottom-edge rule itself is satisfied and now has a
  dedicated proof in `create_account_view_test.dart`.
- `_headlineMaxWidth = 240` is a measured literal rather than a token. It is
  documented and justified from the HTML break, and it produces the design's
  line break, but it will drift if the Nunito build changes. Flagged for the
  review stage rather than as a bug.
- Shared items 2 and 4 (doubled screen-reader labels on `NestBrandButton` /
  `NestButton`) remain open; the P03-BUG-6 proof stays skipped for that
  reason — the only skip in the suite.

## Results (`app/`)

- `dart format --set-exit-if-changed .` → `Formatted 359 files (0 changed)`.
- `flutter analyze` → `No issues found!` — no ignores, no weakened options.
- `flutter test test/features/auth` → **113 passed, 1 skipped, 7 failed**
  (the 7 are the new proofs above; nothing else is red).
  Per file: `auth_bloc_test.dart` 45/45, `create_account_view_test.dart`
  48/48, `seeded_submit_test.dart` 7/7, `p03_bugs_test.dart` 13 green + 1
  skipped + 7 red.
- `flutter test` (full suite) → **600 passed, 1 skipped, 7 failed**.
- `shot.sh` light + dark + `compare.py` → `ui/light.png`, `ui/dark.png`,
  `ui/compare-light.png`, `ui/compare-dark.png`.


## From 4_review.md
# P03 Create account — QA code review (Stage 4, iteration 2)

Scope reviewed: `git diff main` for P03 — `app/lib/features/auth/**` (view, bloc,
domain, data, glyph widgets) + `app/test/features/auth/**` + `docs/screens/P03/**`.
No code was edited by this stage. Reference set: `docs/ARCHITECTURE.md`,
`docs/screens/RULES.md`, `docs/DESIGN_SPEC.md` §5 P03 (line 150),
`docs/DESIGN_SPEC.md` §0.9 (44×44 parent tap targets),
`docs/design/SPACING_SPEC.md`, `docs/screens/P03/1_plan.md`,
`ORCHESTRATOR_NOTES.md` (mandatory, all six items), `FIXES_1.md`, `2_build.md`,
`3_test.md`, `5_ui.md`, `SHARED_REQUEST.md`.

Evidence gathered by this stage (not taken from stage 3's notes):

- `flutter analyze` → `No issues found! (ran in 3.7s)`, no ignores, no weakened options.
- `flutter test test/features/auth` → **113 passed, 1 skipped, 7 failed**; the 7 are
  `P03-BUG-9`, `9b`, `10` (320/390/430), `10b`, `11`, all in
  `app/test/features/auth/p03_bugs_test.dart`.
- Pixel measurement, `design/screens/{light,dark}/P03-create-account.png` vs
  `docs/screens/P03/ui/{light,dark}.png` (x=3 colour scan + per-row ink/sky scans):
  back chevron 74–78 in both; headline ink 113–137 / 147–171 in both, line-1
  x-extent 22–178 vs 22–180; Apple button 255–306 **in both**; helper ink 598–606
  (x 21–145) vs 600–608 (x 21–150); note ink 628–638 (x 49–287) vs 631–640
  (x 50–296); CTA hairline **y=677 design / y=682 app**; CTA surface runs to y=844 in
  both themes with no page tint below it.
- Caption link geometry measured per line by sky-coloured pixel runs:
  design line 1 = one run x 258–297 ("Terms"), line 2 = one run x 150–240
  ("Privacy Notice"); **app line 1 = two runs x 236–275 and x 307–353 ("Terms" +
  "Privacy"), line 2 = one run x 175–215 ("Notice")** — identical in light and dark.
- `git status` touches only `app/lib/features/auth/**`,
  `app/test/features/auth/**`, `docs/screens/P03/**` — RULES §1 respected.

## Iteration-1 findings — all eight closed

| # | Iteration-1 finding | Status | Evidence in the current tree |
|---|---|---|---|
| 1 | BLOCKER — red suite; `P03-BUG-3` needed a shared fix | **closed** | Shared nav fix landed (`fc981bc`, merged `2027506`); `title: ''` reverted to `title: null` (`create_account_view.dart:87`); `P03-BUG-3` green |
| 2 | MAJOR — caption one link per row, panel 47dp too tall | **closed** | CTA hairline 682 vs design 677; note clearance 38dp vs the design's 39dp; proofs 1a–1f green |
| 3 | MAJOR — validation error on the first keystroke | **closed** | `submitAttempted` dirty-gating (`auth_bloc.dart:35-75`); proofs 2a–2d green |
| 4 | MINOR — legal links announced twice | **closed** | Overlay targets carry one label, no inner `Text`; assertions now `equals` (`create_account_view_test.dart:631-632`) |
| 5 | MINOR — hard-coded `2`/`12` padding | **closed** | Padding literals gone with the overlay rewrite; helper uses `NestSpacing.gap6` (`:208`) |
| 6 | MINOR — `AuthProvider` in `domain/` | **closed** | Enum moved into `domain/auth_repository.dart:4`; `auth_provider.dart` deleted |
| 7 | MINOR — `on Exception` stranded a spinner | **closed** | Both handlers `on Object catch` (`auth_bloc.dart:104,120`); proof green |
| 8 | MINOR — whole form rebuilt per keystroke | **closed** | `BlocSelector(isSubmitting)` on both brand buttons (`:119,140`), `buildWhen` error selectors on the fields (`:163-165,181-184`) |

## Checked and clean (no finding)

- **Architecture** — feature-first; `domain/` now holds only the entity folder plus the
  abstract repository (enum inlined there); `AuthBloc` is built by `registerAuth` and
  provided at the route level with `AuthLoadRequested`; cross-feature navigation uses
  the route-path constants, the established pattern. One BLoC per screen, no use-case
  classes, `package:nestling/...` imports only.
- **RULES §1 / §4 / §7** — only allowed paths touched; the password is still never
  persisted; owner row still idempotent; `createAccount(name:)` legacy alias still
  documented for the one shared caller (`repositories_test.dart:414`).
- **Design system** — no re-implemented component; every colour/space/type comes from
  `context.nest` / `NestSpacing` / `NestType`; the two brand glyphs remain the HTML's own
  artwork; `NestBottomCta.caption` still correctly avoided.
- **Mandatory `ORCHESTRATOR_NOTES.md`** — §1 shared header left alone and now correct;
  §2 headline break **"Create your / family account"** confirmed by pixel extent
  (22–178 / 20–217 design vs 22–180 / 21–220 app), no hard newline, and proof
  `P03-BUG-7` pins it; §3 filled-state widget test present and green
  (`create_account_view_test.dart:1279-1320`: CTA enabled, `tokens.leaf`, dots, eye);
  §4 helper on the 20px gutter, 2dp off the design vertically (600–608 vs 598–606);
  §6 note row: shield + text on the same baseline at the gutter (x 50 in both).
- **Alignment + bottom edge (OWNER rules)** — 20px gutters hold everywhere I measured;
  the CTA's `surface` reaches y=844 in light (`#FFFFFF`) and dark (`#1F1C2E`) with no
  paper strip and no ring around the home area.
- **Lifecycle / performance** — controllers disposed (`:46-51`); the `watchItems()`
  subscription belongs to the route-scoped bloc; keystrokes now rebuild only the two
  fields' error slots and the CTA (the `_LegalLine` is `const`, so it is not rebuilt at
  all); no timers, no animations.
- **Children's Code / privacy** — parent-mode only; no analytics, ads, network calls or
  child data touched; the copy states the privacy position; nothing logged.
- **`_headlineMaxWidth = 240`** (`:32-37`) — reviewed and **accepted**: it is a named,
  documented, measured constant derived from the HTML break, there is no design-system
  token for a content-driven wrap width, and `P03-BUG-7` guards it. Keep the proof.

## Findings

### 1. BLOCKER — the branch ships a red suite again (7 proofs)

`app/test/features/auth/p03_bugs_test.dart` — `P03-BUG-9`, `9b`, `10` (320/390/430),
`10b`, `11`.

`flutter test test/features/auth` → 113 passed / 1 skipped / **7 failed**, so RULES §7
("`flutter test` → all pass") is not met. Unlike iteration 1, every one of these seven is
in P03's own edit scope and is fixed by findings 2–5 below; no shared change is needed
this time. Fix them and the suite closes on this screen.

### 2. MAJOR — the caption splits the "Privacy Notice" link, leaving a lone underlined "Notice"

`app/lib/features/auth/presentation/views/create_account_view.dart:328-340` (`Text.rich`).

The caption is left to break wherever the app's Inter runs out of room, and it runs out
one word later than the design's font did. Measured by sky-pixel runs, identical in
light and dark:

| | caption line 1 | caption line 2 |
|---|---|---|
| design | `…our ` + **Terms** (x 258–297) | **Privacy Notice** (x 150–240) |
| app | `…our ` + **Terms** (x 236–275) + **Privacy** (x 307–353) | **Notice** (x 175–215) |

A mandatory item is broken: `ORCHESTRATOR_NOTES.md` §5 requires
`By continuing you agree to our Terms and` / `Privacy Notice`. As shipped, one underlined
word sits alone on line 2 — visible at a glance in both themes and the reason the caption
reads differently from the design even though its height and position are now correct
(line 1 ink 763 vs 762, line 2 ink 783 vs 780).

Fix: make the two-word label unbreakable — `'Privacy\u00A0Notice'` in the link
`TextSpan` (`:334`) — so the label can never be split by the line breaker. Keep it a
real string break, not a hard `\n`, so 320dp and text scale 1.3 still wrap sensibly
(the proofs already sweep 320/390/430 × 1.0/1.3).

### 3. MAJOR — the 44dp link targets sit in the middle of the sentence, not over their words

`create_account_view.dart:342-355` (`Positioned.fill` + `Center` + `Row(mainAxisSize: min)`)
and `:367-390` (`_LegalHitTarget`).

The iteration-2 caption rewrite made the caption plain text again and then re-created
the targets as an overlay that `Center`s the two 44dp boxes as **one adjacent 88dp
block** — `Terms` at x 151–195 and `Privacy Notice` at x 195–239 (caption width 350,
centred) — regardless of where the words actually landed. On device the word "Terms"
occupies x 236–275, so:

- tapping the visible underlined "Terms" hits nothing;
- the two targets touch, so the 4dp gap of "and" is not protected;
- two invisible buttons cover the plain words "…agree to our…" in the middle of the
  sentence.

This is a regression against iteration 1, where each target wrapped its own label and a
tap on the word hit its target. VoiceOver users are unaffected (two correct nodes), and
because the links are inert v1 (`TODO(P03)`) nothing visible happens on a tap today —
but the touch geometry is simply wrong and will stay wrong when the Terms/Notice routes
land.

Fix: drop the overlay entirely and make the spans themselves the targets —
`TextSpan(text: 'Terms', style: link, recognizer: _termsTap)` /
`'Privacy\u00A0Notice'` with `TapGestureRecognizer`s disposed in the `State`'s
`dispose`. Each target is then exactly its own word run at the design's position, one
semantics node per link, and no layout height is added — findings 2 and 3 are fixed by
the same change. Delete `_LegalHitTarget` and the `Positioned.fill` block; keep the
`Semantics(label: _sentence, explicitChildNodes: true)` wrapper so the sentence is still
announced once. Run `P03-BUG-9`, `9b`, `10` (all three widths) and `10b` — all six must
go green.

### 4. MINOR (new this iteration) — on device the "44dp" legal targets are actually 44×36

`create_account_view.dart:342-345` + `:377-381`.

`Positioned.fill` hands its child the stack's size, and the stack is sized by its
caption text: `NestType.caption` is 13/18 (`typography.dart:64-65`), so two lines =
**36dp**. `ConstrainedBox(minWidth/minHeight: 44)` is then clamped by
`enforce()` to 36, and the targets measure 44×36 — under the parent-mode 44×44 minimum
(`DESIGN_SPEC.md` §0.9, SPACING_SPEC tap targets). The widget proofs that assert
`size.height >= 44` (`create_account_view_test.dart:627`, `:1153-1158`) pass only
because flutter_test's placeholder font makes the harness caption taller than the real
Inter render — the assertions are blind to the device geometry. Finding 3's fix makes
this moot; if the overlay is kept instead, size the caption block from a
`NestType.caption` line-height token (`18 × 2`) rather than inheriting the text's box,
and re-check the target height on the simulator.

### 5. MINOR — the validation error is indented 20dp while the hint it replaces sits on the gutter

`create_account_view.dart:201` (`errorText: errorText` on the shared `NestTextField`).

Material lays `InputDecoration.errorText` out on the field's content box (measured
`left = 40` for a field whose label, border and input all start at `left = 20`), while
the iteration-2 fix moved the helper onto the gutter (`:207-213`). The text therefore
jumps 20dp sideways the moment an error appears — the exact defect
`ORCHESTRATOR_NOTES.md` §4 removed from the hint, left in place for the error. The
design's `.field` is a flex column (`components.css:129-135`), so label, input, hint and
error all share the gutter.

Fix: own the error row the way the helper row is now owned — pass
`errorText: null` to `NestTextField` and render `errorText` in the feature-owned slot at
`:207-213` with `NestType.caption(color: tokens.danger)` (that is the style
`NestTextField` uses for `errorStyle`), keeping the helper/error swap and the 6dp gap.
The shared component fix is filed as `SHARED_REQUEST.md` §5 and still worth landing
for every other screen, but P03 must not wait for it.

### 6. MINOR — `on Object catch` drops the stack trace

`auth_bloc.dart:104` and `:120`.

Catching `Object` is the right call (it closes the iteration-1 finding), but it also
swallows genuine programming errors from the data layer and presents
`error.toString()` to the user with no trace kept anywhere — the one case where a
developer most wants the stack. Fix: `on Object catch (error, stackTrace)` → emit the
`formError` state **and** `addError(error, stackTrace)`. This will need the proof that
currently asserts "no `addError`" (`p03_bugs_test.dart`, `P03-BUG-5`) updated to
swallow the expected error instead.

## Notes for the next stage

- Fix 2 + 3 together (one change to `_LegalLine`: unbreakable label + recognizer
  spans), then 5, then re-run `flutter test` — target 121 passed / 1 skipped / 0 failed.
- `SHARED_REQUEST.md` items 2, 4 and 5 remain open and correctly non-blocking; items 1
  and 3 are resolved by the shared nav-bar fix.
- Nothing else in the screen needs touching: geometry, copy, tokens, alignment, the
  bottom-edge rule and the rebuild scoping are all where the design says they should be
  (CTA hairline 682 vs 677, Apple button 255–306 in both, note clearance 38 vs 39).


## From 5_ui.md
# P03 Create account — UI check (Stage 5, iteration 2)

Route `/create-account` · parent mode · `SEED=fresh` · child maya · simulator BC440E48-B3A3-43BC-971B-0EF5DB621874 (390×844).
Mandatory: `docs/screens/P03/ORCHESTRATOR_NOTES.md` (6 items, mapped below) + standing orchestrator rules
(PIP vacuous — no Pip on this screen; status-bar time ignored; bottom-edge OWNER rule enforced).
Design sources: `design/screens/light|dark/P03-create-account.png` (1170×2532 @3x → 390×844 logical),
`design/html-source/screens/P03-create-account.html`, DESIGN_SPEC §5 P03, SPACING_SPEC §§1–2,9–11.
No code edited in this stage.

## Captures

- `bash tools/screens/shot.sh $PWD/app /create-account $PWD/docs/screens/P03/ui/app_light_2.png BC440E48-B3A3-43BC-971B-0EF5DB621874 light fresh parent maya` → stable frame saved (absolute out path; the brief's relative path breaks after `shot.sh` cds into `app/`, as proven in iteration 1).
- Same with `dark` → `app_dark_2.png` → stable frame saved.
- `python3 tools/screens/compare.py design/screens/light/P03-create-account.png docs/screens/P03/ui/app_light_2.png docs/screens/P03/ui/cmp_light_2.png` (and dark → `cmp_dark_2.png`).
- Read `cmp_light_2.png`, `cmp_dark_2.png`, `app_light_2.png`, and both design PNGs with the file reader.
- Filled-state capture (ORCHESTRATOR_NOTES item 3) was attempted and could not run on this host:
  `idb ui tap/text` fails (`SimulatorKit … does not exist` — this Xcode 27 install ships no SimulatorKit for HID),
  and there is no Simulator.app GUI to drive (`open -a Simulator` → `Unable to find application`; only simctl headless).
  No pyobjc/Quartz to synthesize clicks either. Fallback evidence: the empty-state captures below validate all
  state-independent geometry (header, title break, caption block height/gap, helper alignment, note row, CTA panel),
  and the filled state itself (email text, password dots, enabled green CTA, eye icon) is pinned by the passing
  `create_account_view_test.dart` "design filled state" widget test (see `6_bugs.md`). The filled simulator capture
  remains open work for an iteration with GUI/HID tooling.

## Mean diff

- Light: **5.08%** (was 13.15%) — bands (0) 0–105: 1.58% · (1) 105–211: 5.60% · (2) 211–316: 2.50% · (3) 316–422: 1.76% · (4) 422–527: 2.48% · (5) 527–633: 2.78% · (6) 633–738: 15.76% · (7) 738–844: 8.19%.
- Dark: **4.61%** (was 12.21%) — bands (0) 0–105: 1.55% · (1) 105–211: 5.87% · (2) 211–316: 2.56% · (3) 316–422: 1.78% · (4) 422–527: 2.57% · (5) 527–633: 2.88% · (6) 633–738: 12.33% · (7) 738–844: 7.36%.
- Bands 1–5 now sit at 1.5–5.9% (header/title/buttons/fields fixed). Residual diff concentrates in bands 6–7:
  empty-vs-filled field contents, disabled-vs-enabled CTA colour (both expected, see non-findings), the design's
  home-indicator pill vs none in `simctl` captures, and deviations 1–2 below.

## Checked and matching (ORCHESTRATOR_NOTES items verified)

- (1) Header offset GONE — do-not-patch respected. Headline ink starts y=120 and Apple-button black starts y=255 in **both** design and app (light, 1 px scans). Bands 1–2 dropped 15–31% → 2.5–5.6%. P03-BUG-3 shared fix confirmed; nothing patched locally.
- (2) Title break matches the design: line 1 ends x≈174 (`your`), line 2 ends x≈218 (`family account`) in both (design 172/217). No hard `\n` involved at this stage's level of observation. P03-BUG-7 fixed.
- (5) Legal footer is two centred lines with normal line height inside the edge-to-edge panel: link rows design `Terms` ≈761–771 / `Privacy Notice` ≈779–791 (gap ≈20) vs app first link ≈763–773 / second ≈781–791 (gap ≈19). Caption block ≈38 dp, not 80. P03-BUG-1 geometry fixed. CTA hairline design y=677 both themes.
- (4) Helper alignment fixed: `At least 8 characters` ink starts x≈21–23, field border at x=20 (was 40 vs 20); helper text-top sits 12 px below the field's bottom border in **both** design and app (586→598 vs 588→600). P03-BUG-8 fixed.
- (6) Note row is shield + text on one baseline: shield left x=24 both, text left x=52–56 both; row ink spans y 627–637 (design) vs 629–641 (app).
- Presence/order/copy/icons/radii/shadows: unchanged from iteration 1 — all present and correct in both themes (Apple black→white flip, Google white→near-black flip, lilac shield, sky underlined links, eye toggle, pill buttons, r16 fields).
- Bottom edge (OWNER): strip y 800–843 is uniform surface to the physical edge — light lum 255, dark lum 35 (`#1F1C2E`) — no paper/meadow strip in either theme. Passes.
- Alignment (OWNER): 20 px gutters hold; no overflow, clipping, or stray ellipsis at 390 width.

## Deviations (element, design value, app value, fix)

1. Legal caption breaks to different lines (minor, visible). Design line 1 ends `…our Terms and` (right edge x≈296) with `Privacy Notice` whole on line 2 (x 150–240). App line 1 ends `…our Terms and Privacy` (blue rows span x 236–352) with lone `Notice` on line 2 (x 176–214) — the `Privacy Notice` link itself wraps mid-phrase. Both blocks are centred, so the app's caption glyphs run ~56 px narrower per line than the design's at the same 350 dp measure. Fix: verify the caption resolves the 13/18 caption token with loaded Inter (no fallback/size slip), then pin the design break — keep `Privacy Notice` unbroken on line 2 — while retaining the two-line centred block, normal line height, and 44 dp link targets from the P03-BUG-1 fix. Re-check at 320 dp / scale 1.3 (must still wrap sensibly, no overflow).
2. Bottom-CTA hairline sits +5 px low (minor, exceeds ±2 tolerance). 1 px gutter scan: design paper→surface transition at y=677 (both themes); app at y=682 (both themes). Note-to-bar clearance is identical (39 px both: note ink bottom 638→677 vs 643→682), so the whole lower block (note + CTA) rides uniformly ~2–5 px low — upper form matches exactly (headline y=120, Apple y=255, email/password/labels within 0–2 px). Fix: find the accumulated ~5 px between the or-row and the note (field heights / 16 px gaps / helper 6 px gap — audit against SPACING_SPEC §§2–3,8) and re-measure; likely 1 px growths in a few stacked elements. Re-verify after deviation 1 lands, since caption metrics feed panel height.

## Non-findings (explained, do not fix)

- Empty fields + disabled faded CTA in the app vs `sarah@example.co.uk` + dots + solid-green CTA in the design: correct initial product behaviour under `SEED=fresh` (ORCHESTRATOR_NOTES item 3 — keep the empty state). Dominates residual band 6 alongside the dots/text pixels; not a defect.
- Status-bar time (`9:41` vs `13:28`/`13:29`) and the design's home-indicator pill (absent in every `simctl` capture — verified a capture artefact in `6_bugs.md`): ignored per the status-bar rule; the OWNER bottom-edge itself passes (see above).
- Process items (uncommitted iteration-2 build/test work in this worktree) are the loop's to commit, not findings.

A designer side-by-side would still flag the legal line reading `…Terms and Privacy / Notice` instead of `…Terms and / Privacy Notice`, and the CTA is 5 px off the ±2 px tolerance — so this iteration does not pass. Both are small, localised fixes; the 13%→5% improvement (header, title, caption block, helper, note) is confirmed and must be preserved.


## From 6_bugs.md
# P03 Create account — bug hunt (Stage 6, iteration 2)

Route `/create-account` · feature `auth` · parent mode · design
`design/screens/{light,dark}/P03-create-account.png` + HTML source. Tree
tested: worktree `screen/P03` at `d298b36` plus the uncommitted iteration-2
build/test work. **No screen code was changed by this stage** — only
`app/test/features/auth/p03_bugs_test.dart` and this report.
`ORCHESTRATOR_NOTES.md`'s six mandatory items are mapped below; the standing
orchestrator rules (PIP — vacuous here, status bar, data-over-mocks, bottom
edge, alignment) were applied.

Executable proofs: `app/test/features/auth/p03_bugs_test.dart` — every
open-bug proof is `skip:`-marked with its id so the suite stays green
(11 skipped). Run
`flutter test test/features/auth/p03_bugs_test.dart --run-skipped` to watch
all of them fail; un-skip each one with its fix.

## Ledger

| ID | Severity | Area | Status |
|---|---|---|---|
| P03-BUG-1 | — | caption one 44dp link row per line | **fixed** iteration 2; proofs 1a–1d green |
| P03-BUG-2 | — | validation error on first keystroke | **fixed** iteration 2 (`submitAttempted` gating); proofs 2a–2d green |
| P03-BUG-3 | — | compact nav bar 44 → 60dp | **fixed** by shared `fc981bc`; proof green |
| P03-BUG-4 | — | legal links announced twice | **fixed** iteration 2 (overlay targets carry one label); proof green |
| P03-BUG-5 | — | non-`Exception` throw stranded the spinner | **fixed** iteration 2 (`on Object catch`); proof green |
| P03-BUG-6 | minor | `NestButton` announces "Create account\nCreate account" | **open, shared** (SHARED_REQUEST §4); proof stays skipped |
| P03-BUG-7 | — | headline break "Create your family / account" | **fixed** iteration 2 (`maxWidth: 240`); proof green, UI stage confirms both lines match |
| P03-BUG-8 | — | password helper indented 40 vs 20 | **fixed** iteration 2 (feature-owned helper row); proof green |
| P03-BUG-9 | **MAJOR** | caption splits the "Privacy Notice" label: lone underlined "Notice" on line 2 | open, in scope; proofs 9/9b |
| P03-BUG-10 | **MAJOR** | 44dp link targets sit as one centred 88dp block, not over their words | open, in scope; proofs 10 (320/390/430), 10b |
| P03-BUG-11 | minor | validation error indented 40 while label/input/helper are at 20 | open, in scope; proof 11 |
| P03-BUG-12 | minor | caption link lines 18dp vs the design's 20dp → CTA panel ~4dp short, hairline 682.7 vs 677.7 (UI deviation 2) | new this stage; proof 12 |
| P03-BUG-13 | minor | with a 2-line caption the 44dp targets render 44×36 (DESIGN_SPEC §0.9 needs 44×44) | new proof; proof 13 |
| P03-BUG-14 | minor | `on Object catch` never `addError`s → observers get no stack trace | new proof; proof 14 |

Iteration-1 closures were independently re-checked, not just accepted: the
caption is text-height (harness 54 ≤ 58), the panel no longer eats the form,
first keystrokes stay clean, the link labels announce once, the headline is
240-capped, the nav is 60dp and the helper runs on the gutter. The UI stage's
design compare improved from 13.15%/12.21% to **5.08%/4.61%**, with bands
1–5 at 1.5–5.9%.

ORCHESTRATOR_NOTES status: §1 fixed by the shared merge (do-not-patch
respected); §2 fixed (headline break verified pixel-for-pixel by the UI
stage); §3 the filled-state widget pin is green — the filled *simulator*
capture is still blocked by missing HID tooling (idb/SimulatorKit) and is
carried for the next stage with GUI tooling; §4 fixed for the helper
(P03-BUG-11 is the error-line half); §5 **broken** (P03-BUG-9); §6 fine
(shield + text on the gutter).

## P03-BUG-9 (MAJOR) — the caption splits the "Privacy Notice" label across two lines

**Where** `create_account_view.dart` `_LegalLine` (`Text.rich`, ~:328-340).
The caption is plain flowing text and the line breaker falls where the app's
Inter runs out of room — one word later than the design's font, splitting
the two-word link.

**Repro** Open `/create-account` (light or dark). Caption line 1 reads
"…Terms and Privacy", line 2 is a lone underlined "Notice". Mandatory
ORCHESTRATOR_NOTES §5 requires
"By continuing you agree to our Terms and" / "Privacy Notice".

**Proofs** `P03-BUG-9` (the label must sit on one caption line) and
`P03-BUG-9b` (both labels on one line at 320/390/430 × 1.0/1.3). Today both
fail: the label spans 2 line boxes.

**Evidence (independent pixel scan of `ui/app_light_2.png` vs the design
PNG, sky-coloured runs):**

| caption line | design | app |
|---|---|---|
| line 1 | x 258.3–297.0 ("Terms") | x 236.0–275.0 ("Terms") **+ 307.0–353.7 ("Privacy")** |
| line 2 | x 150.3–239.7 ("Privacy Notice" whole) | x 175.3–214.7 ("Notice") |

**Suggested fix** Make the label unbreakable — the review's
`'Privacy\u00A0Notice'` (U+00A0) in the span, or render the caption as two
centred line blocks matching §5. No literal `\n`: 320dp and scale 1.3 must
still wrap (proof 9b sweeps them).

## P03-BUG-10 (MAJOR) — the 44dp link targets do not sit over their words

**Where** `create_account_view.dart` `_LegalLine`'s
`Positioned.fill`/`Center`/`Row(mainAxisSize: min)` overlay + the two
`_LegalHitTarget`s (~:342-390).

The iteration-2 caption rewrite kept the links as an overlay, but the overlay
centres the two 44dp boxes as **one adjacent 88dp block** (x 151–239 at
390dp) regardless of where the words land. The visible words are at the line
ends; the invisible targets cover the middle of the sentence. The targets
also touch (`privacy.left == terms.right == 195`), so the " and " gap between
the links is not protected.

**Repro** Tap the page — the underlined "Terms" at the end of line 1 is
untappable (its centre x≈255 is outside the 151–239 block), while two
invisible buttons cover plain words such as "…you agree to our…". Links are
inert v1 (`TODO(P03)`), so nothing happens either way today; the touch
geometry is simply wrong and stays wrong when the routes land.

**Proofs** `P03-BUG-10` at 320/390/430 (each target must overlap the label
box it serves — fails for at least one label at every width) and
`P03-BUG-10b` (the targets must not be contiguous).

**Suggested fix** Make each label's own span/word the target so the hit box
is exactly where the word is (e.g. `TextSpan` with a `TapGestureRecognizer`,
or a two-line centred layout with the keyed link widgets inline), while
keeping one semantics node per link and the 44dp minimum (P03-BUG-13). Run
proofs 9/9b/10/10b/11/13 together — they are the same code path.

## P03-BUG-11 (minor) — the validation error is indented while the helper is on the gutter

**Where** `create_account_view.dart:201` — `errorText: errorText` on
`NestTextField`; Material lays `InputDecoration.errorText` out on the field's
content box (left **40**), while the label, input and the iteration-2
feature-owned helper all start at the 20dp gutter (left **20**). The text
jumps 20dp sideways the moment an error appears. ORCHESTRATOR_NOTES §4 (and
the design's `.field` flex column) wants every line on the gutter.

**Repro** Attempt a submit with an invalid form (or the empty-submit path
used by tests): "Use at least 8 characters" renders at left 40 while the
helper it displaced was at left 20.

**Proof** `P03-BUG-11` (`error.left == field.left`; today 40 vs 20).
**Suggested fix** Own the error row like the helper row: pass
`errorText: null` and render the error in the feature-owned slot with
`NestType.caption(color: tokens.danger)`. SHARED_REQUEST §5 tracks the
component-level fix for other screens; P03 must not wait for it.

## P03-BUG-12 (minor, new) — the caption link lines are 18dp instead of the design's 20dp, so the CTA panel is ~4dp short

**Where** `create_account_view.dart` `_LegalLine` — `NestType.caption`
(13/18) for every span. The design's inline styles set
`.link { line-height: 20px }` (`P03-create-account.html:26`); a line box
containing a 20px inline box grows to 20px, so the design's two-line caption
is **40dp**, not 36dp, and its CTA panel is 167dp vs the app's ~162dp. This
is the root cause of UI iteration-2 deviation 2 ("bottom-CTA hairline +5px"),
which the UI stage could not localise.

**Repro / evidence** 1px gutter scan, `ui/app_light_2.png` vs the design
light PNG (identical in dark):

| | design | app |
|---|---|---|
| CTA hairline | y 677.7 | y 682.7 |
| primary button | y 694.0–745.7 | y 698.0–749.7 |
| caption link-line spacing | 20dp (759.3 → 779.3) | 18dp (762.3 → 780.3) |

**Proof** `P03-BUG-12`: the line height of the line containing each link,
computed from the caption's own `RenderParagraph`/`TextPainter` metrics, must
be 20dp (currently 18dp at every width).

**Suggested fix** Give the caption (or at least its link spans) the design's
`height: 20/13`, e.g. `base.copyWith(height: 20 / 13)` and the same on
`link`. The panel then measures 40 + the fixed 126/127, moving the hairline
to ~678 (design 677.7).

## P03-BUG-13 (minor, new proof) — the 44dp legal targets render 44×36 on a two-line caption

**Where** `_LegalLine`'s `Positioned.fill` overlay: `Positioned.fill` hands
the child the **stack's** size, and the stack is exactly the caption text
(two 18dp lines = 36dp). `ConstrainedBox(minHeight: 44)` is then clamped by
`BoxConstraints.enforce` to 36, so on the device — where the caption is
always two lines — the targets are 44×36, under DESIGN_SPEC §0.9's 44×44
parent minimum. In the widget harness the fallback font wraps the caption to
three lines at 320/390, so the old assertions passed blindly; at **430dp**
the harness also produces two lines and reproduces the device geometry.

**Repro** `P03-BUG-13` at 430dp: target heights are 36 (fails ≥44). On device
the review measured the same 44×36 (`ui/app_light_2.png` geometry).
**Suggested fix** Let the hit boxes overflow the 40dp caption block
(`Stack(clipBehavior: Clip.none)` + `Positioned(top: -2, bottom: -2)` for a
44dp box) — or whatever implementation the BUG-9/10 fix uses, as long as the
final hit box is ≥44×44 and covers its own label.

## P03-BUG-14 (minor, new proof) — a caught repository failure keeps no stack trace

**Where** `auth_bloc.dart:101` and `:117` — `on Object catch (error)` emits
`formError` and drops the error and stack entirely; no `addError` reaches the
bloc observer, so the one place a developer wants the stack has nothing.

**Repro** `P03-BUG-14`: with a `_RecordingObserver` installed, submit against
a repository that throws `StateError` — the user sees the error, the
observer sees **nothing** (`errors == []`). **Suggested fix**
`on Object catch (error, stackTrace)` → emit the state **and**
`addError(error, stackTrace)`. (The P03-BUG-5 proof still passes: the error
is reported, not rethrown.)

## P03-BUG-6 (minor, shared) — `NestButton` still announces its label twice

Carried from iteration 1: core `nest_button.dart` merges its explicit label
with the inner `Text`, so the CTA reads "Create account\nCreate account".
Proof `P03-BUG-6` stays skipped; SHARED_REQUEST §4. Items §2 (brand buttons)
and §5 (NestTextField error padding) are also still open and correctly
non-blocking.

## Checked — no bug found

- **Kid-mode guard** — `APP_MODE=kid` + session kid mode deep-linking
  `/create-account` redirects to `/parental-gate`.
- **Restart / Drift persistence** — one owner row after create, no rename of
  an existing owner, password never written (`seeded_submit_test.dart`).
- **Back / deep links** — no history → `/value-tour`; the form renders on
  `Seed.fresh`, `Seed.empty`, `Seed.demo`; back-pops when a route is stacked
  (new iteration-2 test).
- **Rapid double taps** — the `isSubmitting` guard still blocks a second
  submit; all three buttons disable/spin together.
- **Text scale 1.3 + width 320/390/430** — the matrix produces no overflow;
  the headline's 240dp cap still wraps to ≤3 lines with real Nunito
  ("Create your" 206dp at scale 1.3 < 240 < "family account" 257dp), so no
  clip.
- **Dark-mode contrast** — unchanged token pairs (all text ≥4.5:1; lilac
  shield decorative at 3.7:1 light).
- **0/1/6 children, long UK names, empty lists, money, timezone/BST** — N/A
  on this screen (static form, no money/date logic, `members` stream never
  displayed).
- **Async gaps** — controllers disposed, no timers, `emit` after close is a
  no-op in bloc 9.2.1; the caught-error path now needs P03-BUG-14's
  `addError` for observability only.
- **Observations, not filed** — `submitAttempted` is intentionally sticky
  (pinned by tests); because the CTA is disabled while invalid, field errors
  can only appear programmatically — a plan-level UX tension
  (`1_plan.md` §(b)/(d)), not a regression; `_headlineMaxWidth = 240` is an
  accepted measured literal (review accepted, proof 7 guards it); the design
  PNG's home-indicator pill is a `simctl` capture artifact; the test
  harness' fallback font is much wider than Inter/Nunito, so harness line
  counts are not product geometry (real-font checks used where it mattered).

## Suite state at hand-off (`app/`)

- `dart format --set-exit-if-changed .` → `359 files (0 changed)`.
- `flutter analyze` → `No issues found!` (no ignores added).
- `flutter test test/features/auth` → **113 passed, 11 skipped, 0 failed**.
- `flutter test` (full) → **600 passed, 11 skipped, 0 failed**.
- The 11 skips are the open-bug proofs: `P03-BUG-6` (shared) and
  `P03-BUG-9`, `9b`, `10` ×3, `10b`, `11`, `12`, `13`, `14`. All iteration-1
  proofs (1a–1d, 2a–2d, 3, 4, 5, 7, 8) run **green**. `--run-skipped` fails
  all 11 for the reasons above.

## Verdict

Two MAJOR bugs remain (P03-BUG-9: the mandatory two-line caption break is
broken; P03-BUG-10: the link targets sit in the wrong place) plus four minor
ones. The fixes are localised to `_LegalLine` (9/10/12/13), the password
error slot (11) and the two catch blocks (14). Fix 9+10+12+13 together in one
`_LegalLine` pass, then 11 and 14, then un-skip their proofs and re-run the
simulator compare.

