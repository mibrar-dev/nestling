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

VERDICT: FAIL