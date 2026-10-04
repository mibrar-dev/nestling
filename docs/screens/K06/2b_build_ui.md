# K06 · Pip's nest (`/pip`) — UI build (stage 2b, iteration 2)

Scope, unchanged from iteration 1: `app/lib/features/pip/presentation/views/**`,
`app/lib/features/pip/presentation/widgets/**` and the `view`/`widget` tests in
`app/test/features/pip/`. No domain/data/bloc edit by this stage (the logic
builder owns those, in parallel, in the same worktree) and no `core/**` edit.
`2a_build_logic.md` was re-read before finishing: the view still codes against
`PipNestReceived/Failed` (internal), `kPipNotEnoughCoins`, `PipState.nest` /
`items` and the bloc's equip mapping — all unchanged by the logic builder in
this iteration, so no rebasing of the view was needed.

## Headline

Every UI-layer finding from `FIXES_1.md` is fixed and its proof now runs live:

| Finding | Was | Fix | Proof |
|---|---|---|---|
| **K06-BUG-6 / `5_ui` D1 / ORCHESTRATOR_NOTES item 1** — locked wardrobe tiles have no visible dashed border (major) | the screen-local `_DashedBorderPainter` was a `CustomPaint.painter`, i.e. *behind* the tile, and the child's opaque `surface-2` decoration covered it edge to edge | it is a `CustomPaint.foregroundPainter` now | `K06-BUG-6` (un-skipped, green) + a new `pip_nest_widget_test.dart` painter test |
| **K06-BUG-4** — the nest art box is 230 × 230 (minor) | `Positioned(230 × 230)` + `BoxFit.fill` | the design's `.k6-pet .nest { width:230px; height:206px; bottom:0 }` box, art letterboxed uniformly (`BoxFit.contain`, the browser's default for an SVG in an `<img>`) | `K06-BUG-4` (un-skipped, green) + a new `pip_nest_widget_test.dart` slot test |
| **K06-BUG-5** — care buttons lose equal heights at text scale 1.3 (minor) | a plain `Row(crossAxisAlignment: start)`; each button only floored at 91, so Play's 19 px `Free` pill grew to 101 while Feed/Bath stayed at 96 | `IntrinsicHeight` + `CrossAxisAlignment.stretch`, which is what `.k6-care`'s flex row + default `align-items: stretch` does | `K06-BUG-5` (un-skipped, green) + a new 1.3× alignment test |
| **K06-BUG-3 / `4_review.md` #9** — the wardrobe heading draws U+2019, the HTML source writes ASCII 0x27 (minor, copy) | `'Pip’s wardrobe'` | `"Pip's wardrobe"` — the source byte is the oracle (`hexdump`: `50 69 70 27 73`), K01's BUG-A precedent | `K06-BUG-3` (un-skipped, green) + the byte-level oracle in `pip_copy_parity_test.dart` (un-skipped, green) |
| **`4_review.md` #11** — progress semantics read "Pip is 70 percent of the way to **a** Songbird" | spelled-out percent and an extra article | `'Pip is $pct% of the way to $nextName'`, the design's own `aria-label` wording, percentage still from the database | two semantics assertions moved with it |

Two findings are **not** mine and stay parked, deliberately:

* **K06-BUG-1 / K06-BUG-2** (lost updates in `PipRepositoryImpl._care` and the
  bloc's stale buy pre-check) are the logic layer's races, in files this stage
  does not own. Still `skip: true` in `k06_bugs_test.dart`, still runnable
  with `--run-skipped --plain-name K06-BUG-1`.
* **ORCHESTRATOR_NOTES item 2** (the scarf / wellies / sunhat glyphs) needs
  three shared `app/assets/icons/*.svg` files; `SHARED_REQUEST.md` §5 carries
  the design's path data and its proof is parked in
  `pip_orchestrator_notes_test.dart`. Unfixable from `features/pip/**`
  (RULES §1), and substitution is forbidden by the note.
* **ORCHESTRATOR_NOTES item 3** (design 30/60 vs seed 40/120): DATA OVER MOCKS
  — the database wins, the view renders `item.priceCoins` and no literal. The
  request is filed in `SHARED_REQUEST.md` §6.

`k06_bugs_test.dart` therefore drops from 6 parked to 2 parked.

## What changed in the code

* `widgets/pip_wardrobe_tile.dart` — dashed stroke moved to
  `foregroundPainter`, with the reason (CSS paints `border` over the
  background) in the file header and at the call site.
* `widgets/pip_nest_slot.dart` — the nest art box is the design's 230 × 206
  (the slot's own box), letterboxed; `kPipNestArtSize` → `kPipNestArtWidth` /
  `kPipNestArtHeight`; the header now carries the PNG measurement that
  distinguishes 206 from 230.
* `views/pip_nest_view.dart` — `IntrinsicHeight` care row; the ASCII
  apostrophe.
* `widgets/pip_growth_card.dart` — the progress `semanticLabel`.
* Tests: the four bug proofs un-skipped with an updated file header, the two
  `.k6-sec` assertions moved to the straight byte (and now also assert the
  curly form is absent), and three new geometry tests in
  `pip_nest_widget_test.dart`.

## Design evidence used (measured, not guessed)

The nest-art question (BUG-4) was the one item where the CSS, the two design
PNGs and the iteration-1 code disagreed, and the orchestrator note 4 ("Pip and
the nest are correct") appeared to contradict stage 6's BUG-4. I re-measured
both PNGs rather than pick a side:

```
design/screens/light/K06-pip.png  widest painted nest row: y 277.7, x 108.3-281.3 (173.0 wide)
design/screens/dark/K06-pip.png   widest painted nest row: y 277.7, x 113.3-276.3 (163.0 wide)
nest.svg                           viewBox 0 0 240 240, outer ellipse rx 98 + 3 stroke = 202 units wide
206/240 x 202                      = 173.4 px          <- the design, both themes
230/240 x 202                      = 193.6 px          <- what the app drew
```

The row *position* is the decisive one: the outer ellipse's widest row is at
`cy 150` of 240, i.e. `206 x (240-150)/240 = 77.3` px above the slot's bottom
edge (the slot's bottom is 356), which predicts y **278.7** — the measured
277.7. The 230 box predicts y 267.5, ~10 px high. So both themes are the 206
scale and iteration 1's code was wrong; note 4's "the nest is correct" is
consistent with the orchestrator having judged the *slot* and Pip's placement
(it also said Pip "is correct", which it is and still is), not the art box.

The pip's own box (`bottom: 81`, 134 × 134) is untouched, and the slot is
unchanged at 230 × 206 — only the nest art inside it was rescaled.

## Owner rules touched by this iteration

* **ALIGNMENT** — the three care buttons now share one height and one top at
  every text scale; asserted, not eyeballed.
* **COPY** — character-exact against the HTML source, with `hexdump` as the
  oracle.
* **ACCESSIBILITY** — `SemanticsAction.tap` contracts are untouched (no
  control was re-wrapped); the one semantics string that changed is a
  `NestProgress` label on a non-interactive element, and its "no tap action"
  assertions still pass.
* **TOKEN RULE** — no colour or size literal was introduced. The two new
  constants are the design's own box numbers (230 / 206), and the dash
  metrics, the art scale and the `IntrinsicHeight` choice are all read off the
  HTML + the PNGs.
* **PIP / KID BACKGROUND / BOTTOM EDGE / CHIP ROWS / LETTER SPACING / BALANCED
  HEADINGS / CLOCK / IDS / FONTS** — untouched this iteration, still satisfied.

## Verification (UI-stage scope only — no whole-app suite, no simulator)

```
dart format --output=none --set-exit-if-changed lib/features/pip test/features/pip → 31 files, 0 changed
flutter analyze lib/features/pip test/features/pip                          → No issues found!
flutter test --timeout 120s test/features/pip                              → +160 ~3: All tests passed!
flutter test --timeout 120s test/app test/features/kid_home                → +496 ~1: All tests passed!
```

The two non-K06 suites are run because `routes_smoke_test.dart` and
`kid_home_view_test.dart` navigate to `/pip` (the K03 dock proof locates the
route, not a placeholder title). The remaining `~3` skips are the two logic
races above and the shared-glyph proof.

No simulator was booted, installed on, screenshot or driven in this stage;
`shot.sh` is the UI stage's job. No `flutter clean`, no `analysis_options`
change, no `google_fonts` anywhere, no image attached.

## LEFT FOR NEXT ITERATION

1. **The UI check has still not been re-run.** Every fix above is asserted in
   a widget test, but only stage 5 can confirm the *rendered* result in light
   and dark against the PNGs. The two band-level items I would watch: the
   wardrobe band (the dashed border now exists in both themes — expect the
   band-6 heat glow to shrink) and the pet band (the nest art should shrink
   ~12 % and drop ~10 px, which should also shrink band 2's diff).
2. **K06-BUG-1 / K06-BUG-2** remain majors on this screen and belong to the
   logic builder. If 2a does not take them this iteration, the screen still
   cannot reach a green UI verdict on the *behaviour* side.
3. **ORCHESTRATOR_NOTES item 2** still needs the orchestrator to land three
   shared SVG assets; nothing in `features/pip/**` can close it.
4. **`kPipNotWearable`** ("That one is not something Pip can wear.") is still
   the one on-screen string that is not in the design, still awaiting
   ratification or a replacement from the orchestrator. Unchanged from
   iteration 1 — not a regression, but still an open item.
5. **`NestProgress`'s kid highlight still spans the whole track** rather than
   only the filled span (shared component, out of scope here; carried over
   from iteration 1's list).

VERDICT: PASS
