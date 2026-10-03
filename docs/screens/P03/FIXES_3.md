# Fix list after iteration 3

## From 3_test.md
# P03 Create account — test notes (Stage 3, iteration 3)

Route `/create-account` · feature `auth` · parent mode. Tests live in
`app/test/features/auth/`; the in-memory Drift DB comes from
`setUpTestScope()` (`Seed.demo` / `Seed.empty` / `Seed.fresh`) and every test
that pumps the app ends with `disposeApp(tester)` (RULES §7). No `lib/` file
was touched by this stage.

## Verdict

**Two real bugs found** (P03-BUG-15 and P03-BUG-16). The iteration-3 build
fixed everything iterations 1–2 reported — I verified each fix on the
simulator, including the ones whose proofs it also had to re-anchor — and the
screen is now within 0–2 dp of the design everywhere above the fold. But the
mandatory `ORCHESTRATOR_NOTES.md` copy item is still unmet and the BUG-11 fix
silently dropped a design-system affordance. Per the brief the screen is
**not** patched, so `flutter test` is **red by design**: 2 proofs fail.
Everything else passes (659 green, 1 skipped, 2 red).

## The iteration-3 fixes, verified

| | iter 2 | iter 3 | design |
|---|---|---|---|
| compare.py mean diff, light | 5.08% | **4.66%** | — |
| compare.py mean diff, dark | 4.61% | — | — |
| CTA surface top | y=682 | **y=678** | y=677 |
| submit button | 698–749.7 | **694–745.7** | 694–745.7 |
| legal caption, line 1 | `…Terms and Privacy` | **`…Terms and` (759.3)** | 759 |
| legal caption, line 2 | `Notice` | **`Privacy Notice` (779.0)** | 779 |
| per-element vertical drift | 0–5 dp | **0–2 dp** | — |

Every element from the back chevron to the privacy note now lands within
2 dp of the design (chevron 65.0 vs 65.0, h1 113.0 vs 112.7, Apple button
255–306.7 vs 255–306.7, email field 445 vs 443, note 627.7 vs 625.7). The
bottom-edge owner rule holds: the CTA's `surface` colour runs to y=844 with
no page tint under it, in both themes. BUG-9, 10, 11, 12, 13, 14 and the
iteration-2 fixes are all green regression guards.

I also checked the proofs the build re-anchored, since a test stage has to
be sure a "correction" is not a weakening. All four are sound:
`BUG-10b` (vertical separation instead of horizontal — the design's own
inline hit boxes overlap in x too, and the new form still fails the
iteration-2 adjacent block), `BUG-1a/b/d` (18dp → 20dp line height, which is
the HTML's `.link { line-height: 20px }` and matches the design PNG's 20 dp
line pitch), and the `BUG-9/9b` line-band predicate (the old 1 dp strips
genuinely missed whenever leading > 0). The new bounds still fail the buggy
values they guard against by a wide margin (64 vs 80, 156 vs 172, 108 vs 140).

## Tests added this stage

`copy_audit_test.dart` (new, **10**) — the COPY rule says every string must
be byte-identical to the HTML, so each string is checked on its own (one
deviation cannot mask another), with the design's typographic characters
written as explicit escapes:

- **h1, note (U+2014), helper + field labels, brand buttons, CTA** — all
  green; 8 of the 9 user-facing strings match the HTML byte-for-byte.
- **subtitle** — red (P03-BUG-15).
- **legal caption** — the whole sentence is verbatim *and* carries exactly
  one U+00A0 inside "Privacy Notice", which is what the COPY rule blesses for
  keeping a phrase together.
- **The measured link targets survive a live relayout (3, green)** — the
  caption's targets are positioned from a post-frame measurement of the
  paragraph, which is the most fragile thing in the iteration-3 code. A live
  resize to 320 and to 430, a live text-scale change to 1.3 and a light→dark
  theme switch all keep each target over its own word.

`p03_bugs_test.dart` 20 → **24** (1 new proof, red — P03-BUG-16).
`create_account_view_test.dart` and `auth_bloc_test.dart` unchanged this
iteration (48 and 45, both green): the dirty-gating, navigation, seeded
repository, submitting-state and a11y coverage from iterations 1–2 already
covers every event/state path the build left in place, and I found no new
gap in them.

Feature total: 121 → **132** (130 green, 1 skipped, 2 red).

## Bugs found

### P03-BUG-15 (MINOR, mandatory) — the subtitle uses a straight apostrophe

`app/lib/features/auth/presentation/views/create_account_view.dart:116`.

The app ships `"You're the grown-up in charge. "` with U+0027. The HTML has
`You&rsquo;re` (U+2019), and `ORCHESTRATOR_NOTES.md` iteration-3 item 2
(mandatory) says "curly apostrophe 'You're' (U+2019) as in the
design/HTML". The new COPY orchestrator rule requires the design's
characters exactly.

Repro: `flutter test test/features/auth/copy_audit_test.dart` — the
"subtitle" test. The full audit (all nine strings, transcribed from the
HTML with escapes) lives in that file, so any future copy drift in either
direction is caught.

### P03-BUG-16 (MINOR) — an invalid field no longer paints the danger border

`app/lib/features/auth/presentation/views/create_account_view.dart:173-185`
and `210-223` — the iteration-3 BUG-11 fix passes `errorText: null` to both
`NestTextField`s so the error message could own the gutter slot. But the
shared field also switches its border to `errorBorder` only while
`errorText != null` (`nest_text_field.dart:128-171`), so the input now keeps
the resting `line` border in the error state.

The design marks the input itself:
`design/html-source/components.css:135`
`.field input[aria-invalid="true"] { border-color: var(--danger) }`, and
`docs/design/SPACING_SPEC.md` §3 states "Error: text 13/18 danger w600;
input `[aria-invalid=true]` border danger". Measured: the border painted
inside the email field is `tokens.line` both before and after the error
appears, so the only signal is red text.

This is a direct consequence of the BUG-11 fix (the build note records it as
a deliberate "trade": "no red input border"), but it costs a design-system
affordance the error state is supposed to have, and the coupling lives in a
shared component, so it is filed as SHARED_REQUEST §5 as well. Proof:
P03-BUG-16.

### P03-BUG-17 (observation, mandatory note not met) — the subtitle still
### breaks one word early

`ORCHESTRATOR_NOTES.md` iteration-3 item 2 also asks for the break
`…Children never` / `need an email.`. The app renders `…Children` /
`never need an email.` (capture: line 1 x 20.7–331.0, line 2 x 21.3–180.3).

The screen's style is already exactly the design's token
(`NestType.body` = Inter 16/24, no letter-spacing = `--fs-body`/`--lh-body`),
so this is not a styling bug: the Inter build `google_fonts` serves is
~3–4% wider than the one the HTML was rendered with (helper 130.7 vs 125.7 dp
= 1.040; note 272.7 vs 264.7 dp = 1.030; Nunito h1 159.4 vs 157.0 = 1.015).
The design's line 1 is 348 dp inside a 350 dp content width — 2 dp of
headroom — so a 3% wider face cannot fit "never".

No widget test can pin this: the harness font is not Inter, so the break it
produces says nothing about the device. The copy audit pins the *string*, and
the geometry proofs pin the tokens; the residual is a font-pipeline
difference and is filed as SHARED_REQUEST §6. It cannot be fixed at screen
level without violating "tokens only".

## Non-blocking observations

- The two 44 dp link targets overlap by ~24 dp when the caption wraps to two
  lines, so the lower ~8 dp of the visible word "Terms" belongs to the
  "Privacy Notice" target. This is **design-faithful**: the HTML's
  `.link { min-height:44px; margin:-12px 0 }` boxes overlap the same way
  between consecutive lines and the later box wins the paint order there
  too. Not a finding — noting it so a future "fix" does not chase it.
- The link targets do not exist during the first frame (they are measured
  post-frame). At 60 fps that is a sub-16 ms window with no layout, and
  `shot.sh` waits for a stable frame, so it is invisible in practice; a
  screen reader announcing on first paint could miss them.
- ORCHESTRATOR_NOTES §3 (filled-state capture on the simulator) is still
  outstanding — it belongs to the UI stage, and the filled *state* is pinned
  by the existing widget proof in `create_account_view_test.dart`.
- Shared items 2, 4, 5 remain open; P03-BUG-6 is the suite's only skip.

## Results (`app/`)

- `dart format --set-exit-if-changed .` → `Formatted 364 files (0 changed)`.
- `flutter analyze` → `No issues found!` — no ignores, no weakened options.
- `flutter test test/features/auth` → **130 passed, 1 skipped, 2 failed**
  (only the two proofs above are red). Per file: `auth_bloc_test.dart`
  45/45, `create_account_view_test.dart` 48/48, `seeded_submit_test.dart`
  7/7, `copy_audit_test.dart` 9 green + 1 red, `p03_bugs_test.dart` 23
  green + 1 skipped + 1 red.
- `flutter test` (full suite) → **659 passed, 1 skipped, 2 failed**.
- `shot.sh` light + `compare.py` → `ui/light.png`, `ui/compare-light.png`
  (mean diff 4.66%; bands 0–5 are all under 3%).


## From 4_review.md
# P03 Create account — QA code review (Stage 4, iteration 3)

Scope reviewed: `git diff main` for P03 — `app/lib/features/auth/**` (view, bloc,
domain, data, glyph widgets) + `app/test/features/auth/**` + `docs/screens/P03/**`.
No code was edited by this stage. Reference set: `docs/ARCHITECTURE.md`,
`docs/screens/RULES.md`, `docs/DESIGN_SPEC.md` §5 P03 (line 150) and §0.9,
`docs/design/SPACING_SPEC.md` §3, `design/html-source/screens/P03-create-account.html`,
`design/html-source/components.css:129-135`, `ORCHESTRATOR_NOTES.md` (**all items
mandatory**, including the iteration-3 additions), the standing **COPY** rule
(typographic characters exactly), `1_plan.md`, `FIXES_1.md`, `FIXES_2.md`,
`2_build.md`, `3_test.md`, `SHARED_REQUEST.md`.

Evidence gathered by this stage:

- `flutter analyze` → `No issues found!` — no ignores, no weakened options.
- `flutter test test/features/auth` → **132 passed, 1 skipped, 2 failed**; the two
  red are `copy_audit_test.dart` "subtitle" and `p03_bugs_test.dart` `P03-BUG-16`.
- Copy bytes: `od -c` on `create_account_view.dart:116` shows `Y o u ' r e` — a
  straight U+0027. `P03-create-account.html` has `You&rsquo;re` (U+2019).
- Pixel measurement, `design/screens/{light,dark}/P03-create-account.png` vs
  `docs/screens/P03/ui/light.png`: CTA hairline **y=677 design / y=678 app**;
  caption line 1 one sky run x 262–300 (design 258–297) = "Terms", line 2 one run
  x 149–241 (design 150–240) = "Privacy Notice"; subtitle line 1 ends x=330 after
  "Children" (design ends x=368 after "never"); CTA `surface` uniform to y=844.
- Flutter SDK: `rendering/proxy_box.dart:183-192` — `RenderProxyBox.hitTest` only
  descends into children when `size.contains(position)`; `material/input_decorator.dart:419`
  — the framework wraps `errorText` in a `liveRegion`.
- Font pipeline: `pubspec.yaml` declares **no** `fonts:` assets and
  `tokens/typography.dart:20,36` call `GoogleFonts.inter/nunito` (resolved at runtime).
- `git status` touches only `app/lib/features/auth/**`, `app/test/features/auth/**`,
  `docs/screens/P03/**` — RULES §1 respected.

## Iteration-2 findings — all six closed

| # | Iteration-2 finding | Status | Evidence |
|---|---|---|---|
| 1 | BLOCKER — red suite | partly | 7 red proofs → 2; the remaining pair is findings 1–2 below |
| 2 | MAJOR — "Privacy Notice" split | **closed** | U+00A0 label; device line 1 = "Terms" only, line 2 = "Privacy Notice" (matches design within 4dp) |
| 3 | MAJOR — targets not over their words | **closed** | rects measured off the laid-out paragraph; live-resize/scale/theme proofs green |
| 4 | MINOR — targets 44×36 | **closed on paper** | `_targetRect` gives ≥44×44 by construction — but see finding 4 |
| 5 | MINOR — error indented 20dp | **closed** | both fields render the error in the owned gutter row (`:186-191`, `:234-240`) |
| 6 | MINOR — dropped stack trace | **closed** | `on Object catch (error, stackTrace)` + `addError` |

I also audited the four proofs the build **re-anchored** (18dp→20dp caption lines,
`BUG-1a/1b/1d` bounds 64/156/108, `BUG-10b` vertical separation, the `BUG-9/9b`
line-band predicate). They are sound, not weakenings: each new bound still fails the
iteration-1/2 buggy values by a wide margin (64 vs 80, 156 vs 214, 108 vs 140), and
`BUG-10b`'s vertical form still fails the iteration-2 adjacent 88dp block.

## Checked and clean (no finding)

- **Architecture** — `domain/` holds only the entity folder plus the abstract
  repository (enum inlined in `auth_repository.dart:4`); one bloc per screen, created by
  `registerAuth`, provided at the route level; cross-feature navigation uses route-path
  constants only; `package:nestling/...` imports; no use-case classes.
- **RULES §4** — password never persisted; owner row idempotent; `createAccount(name:)`
  legacy alias still documented for the one shared caller.
- **Geometry (measured, device vs design)** — CTA hairline 678 vs 677 (+1dp, was +47);
  caption two lines with the design's break and positions; Apple button, headline,
  helper, note all within 0–2dp (per stage 3's table, consistent with my own scan);
  bottom-edge OWNER rule holds (uniform `surface` to y=844, light and dark); 20px
  gutters and control edges unchanged.
- **Copy** — 8 of the 9 user-facing strings are byte-identical to the HTML and now
  guarded by `copy_audit_test.dart`, including the U+2014 em dash and the single U+00A0.
  Only the subtitle's apostrophe deviates (finding 2).
- **Rebuild scoping** — brand buttons on `BlocSelector(isSubmitting)`, fields on
  `buildWhen` error selectors, the CTA on `canSubmit`; a keystroke no longer rebuilds
  the static rows. Controllers disposed; the `watchItems()` subscription belongs to the
  route-scoped bloc; no timers, no animations.
- **Error handling** — both submits `on Object catch` + `addError`, so a non-`Exception`
  can no longer strand a spinner, and the failure is announced to assistive tech.
- **Children's Code / privacy** — parent-mode only; no analytics, ads, network calls or
  child data; the copy states the privacy position.
- **Test-proof audit** — the iteration-3 proofs measure through `RenderParagraph`
  (`getBoxesForSelection` / `computeLineMetrics`), so they are font-independent, which is
  the right way to pin this screen; `copy_audit_test.dart` transcribes the HTML strings
  with explicit escapes so no invisible character hides in the test either.

## Findings

### 1. BLOCKER — red suite, and two of its proofs cannot both pass inside RULES §1

`app/test/features/auth/copy_audit_test.dart` ("subtitle") and
`app/test/features/auth/p03_bugs_test.dart` (`P03-BUG-16`). RULES §7 requires
`flutter test` → all pass.

The important part for the loop: **`P03-BUG-11` (error on the gutter) and `P03-BUG-16`
(danger border on an invalid input) are mutually exclusive with the shared component as
it stands.** `NestTextField` derives both from one flag — `errorText != null` selects
`errorBorder` (`nest_text_field.dart:128-171`) *and* Material's indented error row.
P03 needs `errorText: null` for the gutter row, so the border is gone; passing
`errorText` restores the border and brings the 20dp indent back. Fixing one proof
regresses the other, so iteration 4 cannot converge on P03 alone.

Resolution (in this order):
1. Orchestrator lands the `NestTextField` fix already filed as `SHARED_REQUEST.md` §5 —
   lay the error out on the gutter **and** drive the danger border from a separate
   `hasError` flag (or `errorBorder` prop). Then both proofs go green.
2. Until it lands, keep the gutter-aligned error (BUG-11, the visible defect) and retire
   the `P03-BUG-16` proof with a comment pointing at `SHARED_REQUEST.md` §5. Do **not**
   pass `errorText` again just to satisfy BUG-16 — that re-opens a major.

Finding 2 (the apostrophe) is a one-character fix and closes the other red proof.

### 2. MAJOR — the subtitle uses a straight apostrophe where the design has U+2019

`app/lib/features/auth/presentation/views/create_account_view.dart:116`.

`"You're the grown-up in charge. "` ships U+0027 (verified byte-wise). The HTML writes
`You&rsquo;re`, `ORCHESTRATOR_NOTES.md` iteration-3 item 2 names this explicitly
("curly apostrophe 'You're' (U+2019) as in the design/HTML"), and the standing COPY rule
requires the design's characters exactly. `copy_audit_test.dart` is red on it.

Stage 3 rated this MINOR; I rate it **MAJOR** because it is an explicitly mandatory
orchestrator item, it violates a standing rule, and it ships red.

Fix: `You\u2019re the grown-up in charge. Children never need an email.` (keep it a
real character, not a hard `\n`; the apostrophe must not be split from its word — a
NBSP after the apostrophe is not needed, only `Privacy Notice` needs one).

### 3. MINOR (blocked on shared) — the subtitle still breaks one word early

`create_account_view.dart:113-117`. `ORCHESTRATOR_NOTES.md` iteration-3 item 2 also asks
for the break `…Children never` / `need an email.`; the device renders `…Children` /
`never need an email.` (my measurement: app line 1 ends x=330, design x=368).

The style is already the design's token (`NestType.body` = Inter 16/24;
`tokens.css:66` `--fs-body: 16px; --lh-body: 24px`, no letter-spacing on either side),
so this is a font-pipeline difference, not a styling bug: I re-measured the app's
Inter as ~4% wider than the design's render ("At least 8 characters" 130dp vs 125dp;
the note row 246dp vs 238dp), and the design's subtitle line 1 uses 348 of the 350dp
content width — 2dp of headroom that a 3–4% wider face cannot fit. It cannot be fixed
in P03 without breaking "tokens only" (no font-size or letter-spacing override, no
wider box). Already filed as `SHARED_REQUEST.md` §6; the orchestrator owns it (pin or
bundle the Inter build the designs were rendered with). **Do not chase it with a local
width or size hack** — that would trade a 4% glyph-width drift for a token violation.

### 4. MINOR (new) — the "44dp" legal targets are only ~32dp *reachable*

`create_account_view.dart:414-418` (`_targetRect`) and `:456-468`
(`Positioned.fromRect`).

`_targetRect` centres a 44dp-tall box on the link's own glyph box, so each target
overhangs the caption block (40dp for the two 20dp lines) by ~4dp at each end. Flutter
only hit-tests a child when the tap is inside the parent's own box
(`rendering/proxy_box.dart:183-192`: `if (size.contains(position))`), and
`Positioned` does not enlarge the parent — so the overhang is inert. Reachable height is
the intersection with the caption block: ≈32dp per target at 390dp, not 44dp. The proofs
(`P03-BUG-13`, `create_account_view_test.dart` a11y group) read
`tester.getSize`/`getRect` of the render box, which reports 44dp and therefore cannot
see this — the same blind spot as iteration 2's finding 4, one level up.

Fix (choose):
- make the caption block at least 44dp tall so the targets sit **inside** the parent
  box: `Stack(alignment: Alignment.center)` inside
  `ConstrainedBox(constraints: BoxConstraints(minHeight: NestDevice.tapParent))`.
  Cost: the block grows 40→44dp and the CTA hairline moves from 678 to ~674 (design
  677) — a real trade, so it must be an explicit decision, and it needs a
  `tester.tapAt`-style proof (tap the extreme top/bottom of the target, assert the
  tap lands) rather than a size assertion;
- or, while the links are inert in v1, state the limitation in the doc comment, add a
  `hitTest`-based proof that documents the reachable box, and revisit when the
  Terms/Notice routes land.
  Either way, stop describing the targets as 44dp-tall without qualifying it.

### 5. MINOR (new) — the post-frame measurement can go stale (font swap, first frame)

`create_account_view.dart:356-410` (`_scheduleMeasure`, `_measure`).

The targets' rects are read from the laid-out `RenderParagraph` in a post-frame callback
and re-scheduled only from `initState` and `didChangeDependencies` (MediaQuery size,
text scaler, theme). No font is bundled (`pubspec.yaml` has no `fonts:` section;
`typography.dart:20,36` call `GoogleFonts.inter/nunito`, resolved at runtime), so on a
cold launch the first layout can be laid out with a fallback face: `_measure` then caches
*fallback* metrics, the real Inter arrives on a later frame, the paragraph reflows, and
nothing re-runs the measurement — the targets stay where the fallback put them until some
unrelated dependency changes. The same round-trip also means **no targets exist during
the first frame** (invisible in screenshots, but a screen reader announcing on first paint
would find the links missing).

Fix: make the rects follow layout instead of a one-shot side effect — either re-measure
while the caption is unsettled (chain post-frame callbacks until two consecutive
measurements agree *and* the fonts are resolved, e.g. `GoogleFonts.pendingFonts()` is
empty), or derive the boxes during layout with a small `RenderBox`/`CustomPainter` that
computes them from a `TextPainter` in `performLayout`. Add a proof that a relayout
without a dependency change (a font swap, or any future caption-text change) keeps each
target over its word.

### 6. MINOR — the owned error rows lost the framework's live region and their field association

`create_account_view.dart:186-191` (email) and `:234-240` (password).

Moving the message out of `InputDecoration` (correct for the gutter) also moved it out
of the field's semantics. Material wraps `errorText` in a live region
(`material/input_decorator.dart:419`, `liveRegion: !MediaQuery.supportsAnnounceOf`), so
before this iteration a VoiceOver user heard the validation error the moment the field
went invalid; now the message is an unrelated static text node. The
`SemanticsService.sendAnnouncement` in this screen only fires for `formError` (server
failures), so **client-side validation errors are announced by nothing**.

Fix: wrap each owned error row in a live region so it announces when it appears —
`Semantics(liveRegion: true, child: ExcludeSemantics(child: Text(...)))` (keep the inner
`Text` out of semantics so the label is read once), and keep
`SemanticsService.sendAnnouncement` for `formError` as it is. Add a semantics proof that
the error node carries `SemanticsFlag.isLiveRegion` once a submit is rejected.

### 7. MINOR — `height: 20 / 13` hard-codes the design's link line height

`create_account_view.dart:425` and `:430`. The rule is tokens-only; `20` is
`NestSpacing.s5` and `13` is the caption font size baked into `NestType.caption`, so the
literal hard-codes a type metric the design system owns.

Fix now: express it as `NestSpacing.s5 / 13` with the `.link { line-height: 20px }`
citation kept in the comment, and add a `SHARED_REQUEST.md` item for a proper
`NestType.legalCaption` (13/20 w400 + 13/20 w600 sky) in
`core/design_system/tokens/typography.dart`, after which both `copyWith(height: …)` calls
disappear. Until then the override is legitimate — it is the design's line height and it
is pinned by `P03-BUG-12` — so this is a token-debt item, not a regression.

## Notes for the next stage

- Order: finding 2 (one character) → finding 1's resolution (orchestrator decision, not
  a code change) → findings 4, 5, 6 (all in `_LegalLine` / the owned error rows) →
  finding 7 (token debt + SHARED_REQUEST item).
- Everything else is in good shape: the screen is now within 0–2dp of the design from
  the back chevron to the privacy note, the caption break matches the design, the bottom
  edge and gutters hold in both themes, and the rebuild scoping, error surfacing and
  proof calibration are all sound.
- `ORCHESTRATOR_NOTES.md` iteration-3 item 3 (a filled-state capture on the simulator)
  remains outstanding for the UI stage; the filled *state* is already pinned by
  `create_account_view_test.dart`'s "design filled state" group.


## From 5_ui.md
# P03 Create account — UI check (Stage 5, iteration 3)

Route `/create-account` · parent mode · `SEED=fresh` · child maya · simulator BC440E48-B3A3-43BC-971B-0EF5DB621874 (390×844).
Mandatory: `docs/screens/P03/ORCHESTRATOR_NOTES.md` iteration-3 items (legal nbsp, subtitle curly quote + break,
filled capture) + standing rules (PIP vacuous — no Pip here; status bar ignored; bottom-edge OWNER rule;
CHILD ORDER n/a — no children listed; COPY — exact typographic characters vs HTML).
Design sources: `design/screens/light|dark/P03-create-account.png` (1170×2532 @3x), `design/html-source/screens/P03-create-account.html`
(`You&rsquo;re`, `Privacy Notice` plain space, `— ever.` em dash), DESIGN_SPEC §5 P03, SPACING_SPEC.
No code edited in this stage.

## Captures

- `bash tools/screens/shot.sh $PWD/app /create-account $PWD/docs/screens/P03/ui/app_light_3.png BC440E48-B3A3-43BC-971B-0EF5DB621874 light fresh parent maya` → stable frame saved (absolute out path; relative breaks after `shot.sh` cds into `app/`).
- Same with `dark` → `app_dark_3.png` → stable frame saved.
- `python3 tools/screens/compare.py design/screens/light/P03-create-account.png docs/screens/P03/ui/app_light_3.png docs/screens/P03/ui/cmp_light_3.png` (and dark → `cmp_dark_3.png`).
- Read `cmp_light_3.png`, `cmp_dark_3.png`, and `app_light_3.png` with the file reader.
- Filled-state capture (ORCHESTRATOR_NOTES item 3, still open): re-probed this iteration —
  `idb ui tap --udid BC440E48… 195 472` still fails with `SimulatorKit … does not exist`
  (this Xcode 27 install ships no SimulatorKit/HID path and no Simulator.app GUI, verified in iteration 2).
  Host-blocked, unchanged. Fallback stands: empty-state captures validate all state-independent geometry,
  and the filled state is pinned by the passing `create_account_view_test.dart` "design filled state" test.

## Mean diff

- Light: **4.66%** (was 5.08%) — bands (0) 0–105: 1.58% · (1) 105–211: 5.60% · (2) 211–316: 2.50% · (3) 316–422: 1.76% · (4) 422–527: 2.48% · (5) 527–633: 2.78% · (6) 633–738: 14.39% · (7) 738–844: 6.22%.
- Dark: **4.27%** (was 4.61%) — bands (0) 0–105: 1.57% · (1) 105–211: 5.87% · (2) 211–316: 2.56% · (3) 316–422: 1.78% · (4) 422–527: 2.57% · (5) 527–633: 2.88% · (6) 633–738: 11.20% · (7) 738–844: 5.74%.
- Bands 6–7 residual is empty-vs-filled pixels (field text, dots, CTA colour), the design's home-pill vs none in
  `simctl` captures, and deviation 2 below. Everything else is at noise level.

## Checked and matching

- Legal footer (ORCHESTRATOR_NOTES iter-3 item 1): FIXED. Blue-link rows now design `Terms` 760–768 /
  `Privacy Notice` 780–790 vs app `Terms` 760–770 / `Privacy Notice` 780–790 — `Privacy Notice` stays together
  on line 2 via the U+00A0 (verified one U+00A0 in the view). Caption block ≈38 dp, centred, normal gap.
- CTA hairline (iteration-2 deviation 2): FIXED. 1 px gutter scan: design y=677, app y=678 (both themes) —
  within the ±2 px tolerance. Note-to-bar clearance identical at 39 px both.
- Header, title break (`Create your` / `family account`, line edges x 174/218 vs 172/217), helper on the 20 px
  gutter, note row single baseline with shield at x=24 and text at x=52–56, or-row, buttons, fields, eye icon,
  dark-mode flips (Apple white, Google near-black, sky links, lilac shield): all match within tolerance.
- Bottom edge (OWNER): surface runs uniform to y=844 both themes. Alignment (OWNER): 20 px gutters, no
  overflow/clipping/stray ellipsis. Copy beyond the subtitle (title, labels, helper, note with U+2014 em dash,
  legal line with nbsp, buttons): exact vs the HTML.
- Subtitle vertical position matches (line-1 rows y 190–200 both); only its break point and one character differ.

## Deviations (element, design value, app value, fix)

1. Subtitle uses a straight apostrophe (COPY rule + ORCHESTRATOR_NOTES iter-3 item 2). Design/HTML: `You’re`
   (U+2019, `&rsquo;`). App (`create_account_view.dart:116`): `You're` (U+0027 — repo-wide U+2019 count in the
   view is 0; the repo's own `copy_audit_test.dart:27,76` expects U+2019 and documents U+0027 as a failure).
   Fix: replace the one character with U+2019. One-line, in-scope fix.
2. Subtitle wraps a word early (ORCHESTRATOR_NOTES iter-3 item 2). Design line 1 ends `…in charge. Children never`
   (right edge x≈365–367) with `need an email.` on line 2. App line 1 ends `…in charge. Children` (right edge
   x≈328–330) with `never need an email.` on line 2 — same 350 dp measure, so the app's subtitle glyphs run
   ~35 px wider per line than the HTML `.body`. Fix: match the HTML subtitle metrics exactly (16/24 Inter 400,
   weight/letter-spacing/word-spacing per `tokens.css`/`components.css` — no ad-hoc sizing), then confirm the
   design break `Children never / need an email.` at 390 width; keep sensible wrapping at 320 / scale 1.3.

## Non-findings (explained, do not fix)

- Empty fields + disabled faded CTA vs the design's filled values + solid-green CTA: correct launch behaviour
  under `SEED=fresh` (ORCHESTRATOR_NOTES item 3 — keep). Expected band-6 contributor, not a defect.
- Status-bar clock (`9:41` vs `15:25`/`15:29`) and the design's home-indicator pill (never drawn by `simctl`):
  ignored/artefact per standing rules; the OWNER bottom edge itself passes.
- Process items (uncommitted iteration-3 build/test/copy-audit work in this worktree) belong to the loop, not to findings.

Two deviations remain, both visible side-by-side and both covered by mandatory rules (exact COPY characters;
the specified subtitle break) — so this iteration does not pass. Each is a small localised fix.


## From 6_bugs.md
# P03 Create account — bug hunt (Stage 6, iteration 3)

Route `/create-account` · feature `auth` · parent mode · design
`design/screens/{light,dark}/P03-create-account.png` + HTML source. Tree
tested: worktree `screen/P03` at `29162fc` plus the uncommitted iteration-3
build/test work. **No screen code was changed by this stage** — only
`app/test/features/auth/**` and this report. `ORCHESTRATOR_NOTES.md`'s
iteration-2/3 items and the standing rules (PIP — vacuous here, status bar,
data-over-mocks, bottom edge, alignment, COPY, CHILD ORDER) were applied.

Executable proofs: `app/test/features/auth/p03_bugs_test.dart` — every
open-bug proof is `skip:`-marked with its id so the suite stays green
(7 skipped across the feature). Run
`flutter test test/features/auth/p03_bugs_test.dart --run-skipped` to watch
them fail; un-skip each one with its fix.

## Ledger

| ID | Severity | Area | Status |
|---|---|---|---|
| P03-BUG-1…14 | — | iterations 1–2's bugs (caption geometry, validation gating, nav bar, labels, spinner, headline, helper/targets/lines/stack) | **all fixed** by iteration 3; proofs green |
| P03-BUG-6 | minor | `NestButton` announces "Create account\nCreate account" | **open, shared** (§4); proof skipped |
| P03-BUG-15 | **MAJOR** | subtitle ships `You're` with a straight U+0027 where the design HTML has U+2019 | open, in scope; proofs `P03-BUG-15` + `copy_audit_test.dart` "subtitle" |
| P03-BUG-16 | minor | an invalid field no longer paints the danger border | open, **blocked on shared §5**; proof skipped |
| P03-BUG-17 | minor | subtitle breaks after "Children" instead of "Children never" | open, **shared §6** (font pipeline); no local test possible |
| P03-BUG-18 | minor | the legal targets' overhang is not hit-testable — ~32dp effective height, not 44dp | new this stage; proof 18 |
| P03-BUG-19 | minor | legal targets lag the first painted frame; the one-shot measurement can go stale (font swap) | new this stage; proof 19 |
| P03-BUG-20 | minor | validation errors lost Material's live region — client errors are announced by nothing | new this stage; proof 20 |

Iteration-3 closures were independently re-checked by me: the caption is
unbreakable (NBSP), each target overlaps its own word at 320/390/430 and
survives live resize/scale/theme changes, the error sits on the 20dp gutter,
the caption lines are 20dp and the CTA hairline lands at 678 vs the design's
677, and a repository `Error` is both surfaced and reported to observers.

ORCHESTRATOR_NOTES status: **item 1 FIXED** (one U+00A0; device line 1 =
"Terms" only, line 2 = "Privacy Notice"); **item 2 half** — the curly
apostrophe is still U+0027 (P03-BUG-15, mandatory) and the specified break is
font-pipeline-blocked (P03-BUG-17, shared §6); **item 3 outstanding** — the
filled-state capture is still host-blocked (no SimulatorKit/HID in this
Xcode; the filled *state* is pinned by the green widget test); iteration-2
items §4/§5/§6 are all satisfied (helper gutter, two-line caption, note row).

## P03-BUG-15 (MAJOR) — the subtitle uses a straight apostrophe where the design has U+2019

**Where** `create_account_view.dart:116` — `"You're the grown-up in charge. "`
with U+0027. The HTML writes `You&rsquo;re` (U+2019); ORCHESTRATOR_NOTES
iteration-3 item 2 names the character explicitly, and the standing COPY
rule requires the design's typographic characters exactly.

**Repro** Open `/create-account`: the subtitle's apostrophe is a straight
tick. Byte check on the view: subtitle apostrophe `0x27`, zero U+2019
anywhere in the file. `copy_audit_test.dart` ("subtitle") is red on it.

**Proofs** `P03-BUG-15` (finds the U+2019 string; fails today) and
`copy_audit_test.dart` "subtitle". Both are skip-marked with this id; un-skip
both with the fix. **Suggested fix** one character:
`'You\u2019re the grown-up in charge. '` (keep the rest verbatim; no hard
newline).

## P03-BUG-16 (minor, shared §5) — an invalid field no longer paints the danger border

**Where** `create_account_view.dart:173-185`, `:210-223` — both fields pass
`errorText: null` so the error can own the gutter (the BUG-11 fix), but
`NestTextField` derives its `errorBorder` from the same `errorText` flag. The
invalid input keeps the resting `line` border; only the message is red. The
design marks the input itself:
`.field input[aria-invalid="true"] { border-color: var(--danger) }`
(`components.css:135`, SPACING_SPEC §3).

**Repro** Reject a submit with an invalid form (programmatic — the CTA is
disabled while invalid): the email/password boxes stay grey while their
messages turn red. **Proof** `P03-BUG-16` (skipped).

**Fix / decision** P03 cannot fix this without re-opening BUG-11: with the
component as it stands the two proofs are mutually exclusive. SHARED_REQUEST
§5 now asks for a separate `hasError`/`errorBorder` flag so the border is
independent of the message row. Keep the visible gutter fix; if the
orchestrator declines the shared change, retire this proof explicitly rather
than passing `errorText` again.

## P03-BUG-17 (minor, shared §6) — the subtitle breaks one word early

**Where** `create_account_view.dart:113-117` — `NestType.body` (Inter 16/24,
no letter-spacing) is already the design token, but the Inter build
`google_fonts` serves is ~3–4% wider than the design's render, so the
subtitle that fits "…Children never" in 350dp (design line 1 ends x 368.3)
runs out of room in the app (line 1 ends x 330.7; "never" drops to line 2,
which ends x 180.3 vs the design's 128.3). Pixel-verified this stage.

**No local test is possible**: the harness font is not Inter, so a widget
test's break says nothing about the device. The copy is verbatim and the
style is the token, so this is not a styling bug — SHARED_REQUEST §6 (pin or
bundle the design's Inter build). Do **not** chase it with a local
size/letter-spacing/width hack; that trades a 3% glyph drift for a token-rule
violation.

## P03-BUG-18 (minor, new) — the legal targets are only ~32dp reachable

**Where** `create_account_view.dart:414-418` (`_targetRect`) and `:456-468`
(`Positioned.fromRect`). Each 44dp box is centred on its word, so it
overhangs the caption Stack (40dp for two 20dp lines) by ~12dp at one end.
Flutter only hit-tests a child when the tap is inside the parent box
(`rendering/proxy_box.dart:183-192`), so the overhang is dead: the effective
height per target is ~32dp, though `tester.getSize` reports 44dp. The design
HTML does not clip the same way — `.link { min-height:44px; margin:-12px 0 }`
boxes stay fully hit-testable in the browser.

**Repro** `P03-BUG-18` (430dp, the device's two-line geometry): a hit test at
the target box's top+1 and bottom-1 must land on that target; today the
overhang end misses. Hit-test-based, so it cannot be fooled by the rendered
rect. **Suggested fix (decide explicitly)** either make the caption block at
least 44dp tall (`ConstrainedBox(minHeight: NestDevice.tapParent)` around the
Stack; the hairline moves 678 → ~674 vs the design's 677) or implement a
custom render object whose hit test accepts the overhang (keeps the 678
hairline). Since the links are inert v1, keeping the current geometry plus a
documented limitation is also defensible — but then this proof should be
retired with that decision recorded.

## P03-BUG-19 (minor, new) — the targets lag the first frame and the measurement can go stale

**Where** `create_account_view.dart:350-411` (`_scheduleMeasure`/`_measure`):
the boxes are read from the laid-out paragraph in a post-frame callback and
re-scheduled only from `initState`/`didChangeDependencies` (MediaQuery size,
text scaler, theme). Consequences:

- the targets do not exist in the first painted frame (proof: one
  `pumpWidget` → no `p03_terms`);
- any reflow that is not a MediaQuery/theme change leaves them stale. The
  real one on device is the runtime Google Fonts swap: no font is bundled
  (`pubspec.yaml` has no `fonts:`), so the first layout can use a fallback
  face; when Inter arrives the paragraph reflows and nothing re-measures
  until an unrelated dependency change.

**Repro** `P03-BUG-19` (first frame). **Suggested fix** derive the boxes
during layout (a small `RenderBox`/`CustomPainter` that computes them from a
`TextPainter` in `performLayout`), which fixes both halves; a chained
post-frame re-measure would still leave the first-frame window. Add/extend a
proof that a relayout without a dependency change keeps each target on its
word.

## P03-BUG-20 (minor, new) — validation errors are no longer announced

**Where** `create_account_view.dart:186-192` (email) and `:234-240`
(password). Moving the message out of `InputDecoration` (correct for the
gutter) also moved it out of Material's live region
(`material/input_decorator.dart:419`), and the screen's
`SemanticsService.sendAnnouncement` only fires for server `formError`s. A
VoiceOver user therefore hears nothing when a field goes invalid.

**Repro** `P03-BUG-20`: after a rejected submit, the error nodes'
`isLiveRegion` flag is false. **Suggested fix** wrap each owned error row in
`Semantics(liveRegion: true, child: ExcludeSemantics(child: Text(...)))` so
it announces once, and keep `sendAnnouncement` for `formError`.

## Carried — not numbered

- **`height: 20 / 13` hard-codes a type metric** (`:425`, `:430`) — review
  finding 7; filed as SHARED_REQUEST §7 (`NestType.legalCaption` 13/20). The
  override is legitimate until the token lands (P03-BUG-12 pins it); the
  stopgap is `NestSpacing.s5 / 13`.
- **The filled-state capture** (ORCHESTRATOR_NOTES item 3) is still
  host-blocked: this Xcode ships no SimulatorKit/HID and there is no
  Simulator.app GUI. The filled state itself is pinned by the green "design
  filled state" widget test; re-attempt when HID tooling exists.
- **Shared items §2/§4/§6** (brand labels, `NestButton` label, font width)
  remain open and non-blocking.

## Checked — no bug found

- **Kid-mode guard** — `APP_MODE=kid` + session kid mode deep-linking
  `/create-account` redirects to `/parental-gate`.
- **Restart / Drift persistence** — one owner row after create, no rename,
  password never written (`seeded_submit_test.dart`).
- **Back / deep links** — no history → `/value-tour`; back-pops when a route
  is stacked; the form renders on all three seeds.
- **Rapid double taps** — the `isSubmitting` guard blocks a second submit;
  all three buttons disable/spin together.
- **Text scale 1.3 + width 320/390/430** — matrix clean; the caption targets
  survive live resize/scale/theme changes (new iteration-3 proofs).
- **Dark-mode contrast** — unchanged token pairs (text ≥4.5:1; lilac shield
  decorative).
- **0/1/6 children, long UK names, empty lists, money, timezone/BST** — N/A
  on this screen (static form, no money/date logic, `members` stream never
  displayed). **CHILD ORDER** N/A (no children listed).
- **Design-faithful non-finding** — the two legal targets overlap when the
  caption wraps to two lines (the later box wins); the HTML's inline hit
  boxes overlap between consecutive lines the same way. Do not “fix” it.
- **Observations** — the first-frame target gap is invisible in screenshots
  (`shot.sh` waits for a stable frame); `submitAttempted` stays sticky by
  design; the design PNG's home-indicator pill is a `simctl` capture
  artefact.

## Suite state at hand-off (`app/`)

- `dart format --set-exit-if-changed .` → `364 files (0 changed)`.
- `flutter analyze` → `No issues found!` (no ignores added).
- `flutter test test/features/auth` → **132 passed, 7 skipped, 0 failed**.
- `flutter test` (full) → **659 passed, 7 skipped, 0 failed**.
- The 7 skips are the open-bug proofs: `P03-BUG-6` (shared),
  `P03-BUG-15` ×2 (`p03_bugs_test.dart` + `copy_audit_test.dart`),
  `P03-BUG-16` (shared-blocked), `P03-BUG-18`, `P03-BUG-19`, `P03-BUG-20`.
  `--run-skipped` fails each for the documented reason.

## Verdict

One MAJOR bug remains (P03-BUG-15: the mandatory curly apostrophe — a
one-character fix) plus four minor ones, two of which need an explicit
decision (P03-BUG-16 shared component fix, P03-BUG-18 target geometry) and
one shared font-pipeline item (P03-BUG-17). Fix 15, 19 and 20 in P03, decide
16/18, then un-skip their proofs and re-run the simulator compare.

