# K07 · 2b BUILD UI (iteration 1) — presentation layer of feature `pip`

## What I own / what I touched

Only my slice (`presentation/views/**` + `presentation/widgets/**` for K07, and
the `view`/`widget` tests in `app/test/features/pip/`):

- `app/lib/features/pip/presentation/views/pip_evolution_view.dart` — the whole
  screen (replaced the placeholder).
- `app/lib/features/pip/presentation/widgets/pip_evolution_background.dart`
  (new) — the screen-local lilac glow + the shared dark stars.
- `app/lib/features/pip/presentation/widgets/pip_evolution_sparks.dart` (new) —
  `svg.sparks`, path for path.
- `app/lib/features/pip/presentation/widgets/pip_evolution_stage.dart` (new) —
  `.k7-stage`: old Pip → arrow → new Pip.
- `app/lib/features/pip/presentation/widgets/pip_evolution_stats.dart` (new) —
  `.k7-stats` three cards.
- `app/lib/features/pip/presentation/widgets/pip_evolution_copy.dart` (new) —
  every K07 string, each documented with its HTML line.
- `app/test/features/pip/pip_evolution_view_test.dart` (new, 16 tests)
- `app/test/features/pip/pip_evolution_widget_test.dart` (new, 13 tests)

No `domain/`, `data/`, `bloc/`, other features, `core/`, `app/` or
`tools/` file was touched (RULES §1).

## Contract

`2a_build_logic.md` says **CONTRACT CHANGES: None**, and the landed code
matches `1_plan.md` §(b) exactly — `PipEvolution { profile, questsDone }`,
`PipRepository.watchEvolution()`, `PipState.evolution`. The view codes against
it unchanged: `state.evolution` → `profile` (stage / look / `totalCoins`) +
`questsDone`, and `state.evolution?.profile ?? state.nest?.profile` on the
failure card so a mid-session error keeps the last-known child.

## Layout, measured design → app

Every number read off `design/screens/light/K07-evolution.png` with a pixel
scan of its ink runs (the PNG is 3x, so divided by 3), then pinned in
`pip_evolution_widget_test.dart` at ±2 px (the UI VERDICT RULE tolerance).
All 13 pass:

| element | design (x, y, w, h) | app |
|---|---|---|
| `.lock-btn.lg` | 313, 46, 57, 56 | 314, 47, 56, 56 |
| `.k7-stage` | 20, 105, 350, 250 | 20, 105, 350, 250 |
| `.k7-old` | +2, +178, 68, 68 | 22, 287, 68, 68 |
| `.k7-arrow` | left +76, bottom 24 | left +76, bottom 24 |
| `.k7-new` | right 6, bottom 0, 240² | 124, 115, 240, 240 |
| `.k7-hero` (line box) | 371, 34 | 371, 34 |
| `.k7-sub` | 421, 26 | 421, 26 |
| `.speech` | 463, 236, 66 (2 lines) | 463, 66 |
| `.k7-stats` cards | 20 / 140 / 260, 110, 84 | same |
| `.kid-bar` top border | 721 | 721 (bottom = 844, the physical edge) |
| `.btn-kid.lilac` | 20, 736, 350, 64 | 20, 736, painted 64 (widget box 70 = +6 sh-kid room) |
| `.sparks` | top 92, 350×250 box, art at 107 | same |

## Two deliberate deviations from the CSS (both measurement-backed)

1. **No `KidScope`** — as `1_plan.md` §0 already ruled: K07's `.screen.kid`
   overrides the kid background with `radial-gradient(118% 62% at 50% 36%)` and
   its body has no `.meadow`. The glow is transcribed exactly (canvas
   translate + `scale(rx, ry)` + a unit-circle shader; a `BoxDecoration`
   `RadialGradient` cannot express the CSS ellipse) and the stars are the
   **shared** `NestKidStarsPainter`, mounted in dark only (`--kid-stars: none`
   in light). No local hills anywhere.
2. **`.kid-bar` bottom padding 4 px (`s1`), not the CSS 10 px.** The shared
   `NestKidButton` reserves 6 px under its box for the `--sh-kid` shadow
   (SPACING_SPEC §10.6), so 12/20/10 would make the bar 6 px taller than the
   design's 89 and lift every painted rect 6 px off (the K03 dock absorbs the
   same 6 the same way). 3 + 12 + 64 + 6 + 4 + 34 = **123** puts the bar's top
   border on the design's measured **y 721** and the CTA's top edge on **736**,
   with `bar.bottom == 844` (owner bottom-edge rule, both themes).

## IMPORTANT for the 5_ui stage — the demo hero wraps one line

`1_plan.md` §(a).11's vertical map is a **stage-4** map (the PNG says
`Pip grew into a Songbird!`). With the bundled faces loaded (`FontLoader`, real
Nunito Black 28 px, `letterSpacing: 0` per the LETTER SPACING ruling):

- stage 4 `Pip grew into a Songbird!` = **346.3 px** → fits the 350 px content
  box → **one line**, and every row lands exactly on the PNG;
- the seeded demo child's stage 3 `Pip grew into a Fledgling!` = **351.7 px** →
  wraps to **two lines**, exactly as the browser would for the same string in
  the same box, so the sub/stats/caption sit **34 px lower** than the PNG while
  the stage slot and the bar stay put.

This is DB-driven content (the UI VERDICT RULE exempts it), and it is pinned
both ways in `pip_evolution_widget_test.dart` (`the design PNG rows` at stage 4,
`the demo stage 3 wraps the hero by exactly one 34 px line`) so the UI stage
knows which numbers to compare. **Do not "fix" it by shrinking the heading,
adding tracking, or breaking the 20 px gutter.**

## Copy

Byte-checked against the HTML: ASCII apostrophes in `Pip's` (line 57 dumped as
`50 69 70 27 73`), straight `!`, `...` in the stage-1 line. Stage names come
from the feature's existing `pipStageName` (`pip_look.dart`) rather than a
second table. The view hard-codes **no** number or stage word: `4`, `175`,
`3`, `Pip grew into a Fledgling!`, `Meet Fledgling Pip` are all derived from
`PipEvolution` (the design's `25 / 250 / 4` never appear — asserted).

## Owner / orchestrator rules checked in code

- PIP: both slots are `PipAvatar` with the child's own `pip_style`/`skin`/
  `accessory` (`pipStyleOf`/`pipSkinOf`/`pipAccessoryOf`), old stage =
  `stage - 1`; no `pip_stage_*.svg` anywhere.
- STATUS BAR: `const NestStatusBar()` (reserve only).
- BOTTOM EDGE: bar surface runs to the physical edge; the `SafeArea` inset is
  inside the surface box (pinned: `bar.bottom == 844`).
- ALIGNMENT: one 20 px gutter everywhere (stage slot, cards, CTA all pinned to
  x 20 / 370 right).
- BALANCED HEADINGS: `.kid-title` hero renders through `NestBalancedText`.
- ACCESSIBILITY: CTA + lock + retry + choose all expose `SemanticsAction.tap`
  (tests `performAction`, not a pointer tap, and assert the real navigation);
  the new Pip is `Semantics(image: true, label: "Maya's Pip, a fledgling")`;
  the stats row is one merged sentence; old Pip / arrow / sparks are
  `ExcludeSemantics`; the lock's label is the design's `Grown-ups`.
- MOTION: no `Timer`/`AnimationController` anywhere (the sparks are static art,
  the spinner is the shared indeterminate one).
- TOKENS ONLY: every colour/size is a token or a documented CSS-derived
  constant in an `…Geometry` class; no hard-coded colours.
- No `google_fonts`, no `DateTime.now()`, no `Wrap`/`Row` chip rows, no
  `analysis_options` change, `dart format` clean, `flutter analyze
  lib/features/pip test/features/pip` → **No issues found**.

## Tests

`flutter test --timeout 120s test/features/pip/pip_evolution_view_test.dart
test/features/pip/pip_evolution_widget_test.dart` → **29/29 pass**
(2 s of test time; each test ends with `disposeApp` inside the body).

Two real bugs the tests caught and I fixed: the stat cells were keyed on the
*number* (so a collapsed card could pass — they are now keyed on the painted
card rect), and the geometry suite was measuring with the default widget-test
font (every glyph the same advance ⇒ the hero wrapped to three lines) and with
zero device insets (⇒ the bar top read 755 instead of 721); both are now
real-font + faked-47/34-inset, the established pattern from
`quest_library_design_geometry_test.dart`.

## LEFT FOR NEXT ITERATION (integration, not mine)

1. **11 pre-existing failures in K06 test files, caused by 2a's dual-stream
   bloc — not by the UI layer** (`git status` shows I did not touch them, and
   `/pip` never loads a K07 file). `flutter test test/features/pip` → 275 pass /
   11 fail:
   - `pip_nest_states_test.dart` (9): the failure card, the loading spinner and
     the retry cases all drive a repository that fails **only** `watchNest()`.
     The new rule "a stream error keeps the loaded screen while the *other*
     stream has data" means the now-healthy evolution emission arrives first,
     so the card never appears (e.g. `load failure the failure card explains
     itself and offers Try again` → 0 × `Oh no! Pip got lost.`).
   - `pip_buy_result_test.dart` (1): the state sequence is
     `[0, 0, 0, 1, 0, 1]` where the old expectation was `[0, 0, 1, 0, 1]` — the
     extra emission is the first `copyWithEvolution`.
   - `pip_nest_states_test.dart` `non-controls advertise no tap action …`.
   Those files are not `view`/`widget` tests, so they belong to the logic
   builder / integrator: either their fakes must fail both streams, or
   `pip_buy_result_test.dart`'s sequence needs the new emission acknowledged.
2. A `compare.py` run is still owed by the 5_ui stage (I never booted a
   simulator, per the brief). The geometry table above is the app-side
   expectation to compare against.
3. Optional polish for a later iteration: the failure / no-child cards reuse
   K03's shapes verbatim; if the orchestrator wants a K07-specific card
   (h2 + speech bubble), that is a copy/layout decision, not a defect.

VERDICT: PASS