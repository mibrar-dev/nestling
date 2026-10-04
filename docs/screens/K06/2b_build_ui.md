# K06 · Pip's nest (`/pip`) — UI build (stage 2b, iteration 1)

Scope: `app/lib/features/pip/presentation/views/**`,
`app/lib/features/pip/presentation/widgets/**`, and the `view`/`widget`
tests in `app/test/features/pip/`. No domain/data/bloc edits (the logic
builder owns those); `2a_build_logic.md` CONTRACT CHANGES were re-read before
finishing and the view codes against them.

## What landed

| File | Role |
|---|---|
| `views/pip_nest_view.dart` | The screen: chrome (status bar, back, parental-gate lock), the scroll column, loading / failure / no-active-child states, the toast listener, the wardrobe tap handler. |
| `widgets/pip_nest_slot.dart` | `.k6-pet` — the design's 230 × 206 slot (nest `nest.svg` 230 × 230 at `bottom: 0`, `PipAvatar` 134 at `bottom: 81`). |
| `widgets/pip_growth_card.dart` | `.k6-grow` — lilac-tint card, next-stage Pip at 30 px, `NestProgress`, the two `.kcap` coin labels. |
| `widgets/pip_care_button.dart` | `.k6-care .btn-kid` — three-row column (icon / label / trailing), press chunk, disabled opacity, Semantics. |
| `widgets/pip_free_pill.dart` | `.k6-free` "Free" badge. |
| `widgets/pip_coin_amount.dart` | `.k6-coin` / `.k6-item-p` — coloured `coin.svg` + digits. |
| `widgets/pip_wardrobe_tile.dart` | `.k6-ward` strip + `.k6-item` tiles, owned and locked (dashed screen-local border). |
| `widgets/pip_look.dart` | Feature-local Pip-look + wardrobe-glyph maps (`1_plan.md` §1a: pip keeps its own helpers; `pipStageName` comes from the logic builder's entity). |

`widgets/pip_placeholder_card.dart` was deleted — the foundation placeholder
card, referenced nowhere.

## Geometry — measured, not guessed

Every number was measured off `design/screens/light/K06-pip.png` (÷3) and
cross-checked against the HTML box model; the two agree. The app now lands:

```
status bar    0 – 47          NestStatusBar reserves only
.k6-top       y 47 – 107      56 px back (transparent r18) + 56 px lock, pad 0 20 4
.k6-name      y 107 – 141     kid-title 28/34, NestBalancedText (text-wrap: balance)
.k6-pet       y 150 – 356     230 x 206, margin-top 9 (the design overrides s4 here)
.k6-grow      y 372 – 486     350 x 114, 3 px ink border, lilac tint, sh-kid
.k6-care      y 502 – 593     3 x 108.67, gap 12, 91 tall
.k6-sec       y 609 – 635     20/26 w900
.k6-ward      y 651 – 767     4 x 78.5, gap 12, 116 tall
caption       y 783 – 803     15/20, em dash
```

`pip_nest_widget_test.dart` pins every one of those rects (±1.5 px) with the
bundled Nunito/Inter faces loaded, so the numbers cannot drift silently. Two
values needed a decision rather than a transcription:

* **Care button = 91 tall.** The CSS says `min-height: 88px`, but the tallest
  column is Play's: 24 icon + 3 + 20 label + 3 + the 19 px `.k6-free` pill =
  69, + 16 padding + 6 border = 91, which beats the 88 floor. The design PNG's
  button border box measures y 502 – 593, i.e. 91. Pinned as
  `kPipCareButtonHeight` so the pill's own metrics cannot silently move every
  row below it.
* **Wardrobe tiles = 116 tall.** `.k6-ward` is a flex row with the default
  `align-items: stretch`, so the design's owned tiles (a 14 px text price)
  stretch to the locked ones' 16 px coin row and all four edges line up.
  Flutter rows do not stretch under an unbounded height, so the tile pins the
  same minimum (`kPipWardrobeTileHeight = 116`); the owned tile then carries the
  same 2 px of slack at the bottom as the design does. Without this the owned
  tiles were 2 px short and their art circles sat 3 px off the locked ones —
  a visible misalignment under the owner ALIGNMENT rule.
* The locked tile reserves the 3 px its dashed border paints, so owned and
  locked share identical content insets (the dashed band is a `CustomPainter`
  stroke, not a layout border).

## Owner rules applied

* **PIP** — the nest slot seats the active child's own `PipAvatar`
  (`style/skin/accessory/stage` from the profile, `inNest: false`), and the
  growth card previews the same child one stage on at the design's 30 px. No
  v1 `pip_stage_*.svg` anywhere on this screen.
* **KID BACKGROUND** — `KidScope` with the shared 136 px meadow at `bottom: 0`;
  no local hills, `Scaffold(backgroundColor: Colors.transparent)`.
* **BOTTOM EDGE** — no bar on this screen, so the meadow runs to the physical
  edge; `NestHomeIndicator()` shrinks to 0 in the app (the OS draws the pill).
* **BALANCED HEADINGS** — the `.kid-title` screen title uses `NestBalancedText`
  (maxLines 2). `.k6-sec` is a screen-local class with no `text-wrap: balance`,
  so it stays a plain `Text`.
* **COPY** — character-exact against the HTML: `Pip · Fledgling` (U+00B7),
  `Pip’s wardrobe` (U+2019), `Nothing here is a chore — it is all just for
  fun.` (U+2014). No `NestType` style sets letter-spacing here (the design CSS
  sets none), so no `copyWith(letterSpacing:)` was needed.
* **DATA OVER MOCKS** — growth numbers come from `profile.totalCoins` and
  `PipProfile.evolveAtCoins` (175/250 in the demo seed), wardrobe prices from
  `PipStage.priceCoins` (Wellies 40, Crown 120 — not the HTML's 30/60), and the
  care costs from the repository's own `feedCostCoins`/`bathCostCoins`, so the
  button label can never drift from the write.
* **ACCESSIBILITY** — every control is one `Semantics` node with `onTap` on
  the node itself (`excludeSemantics: true` + `onTap`, never label-only):
  Back, Grown-ups, Feed/Play/Bath, and all four wardrobe tiles. `Feed`/`Bath`
  drop the tap action and report `enabled: false` when the child cannot afford
  them; Play is never disabled. Tests assert `hasAction(SemanticsAction.tap)`
  for all nine controls and drive the real database through
  `performAction` (feed −5, bath −3, buy −40).
* **CLOCK / IDS / FONTS** — none used: no `DateTime.now()`, no new rows, no
  `google_fonts` (the tests import nothing of the sort).
* **ALIGNMENT** — 20 px gutters on every row; `pip_nest_widget_test.dart`
  asserts the left/right edges and that all four wardrobe tiles share a top.

## Loading / failure / no-child

Same chrome (status bar + back + lock) so a tap always has a way out.
Loading is a leaf spinner labelled "Loading Pip"; failure is K03's shape
(neutral Mochi `PipAvatar`, "Oh no! Pip got lost.", "Let's try again.", white
`Try again` → `PipLoadRequested`); a loaded-but-null nest is "Who's playing?"
+ lilac `Choose` → `/who-is-playing`.

## One piece of copy is NOT in the design — needs a ruling

`1_plan.md` §1f and `2a_build_logic.md` both say an owned **Wellies**/**Crown**
tap should "toast only, no DB write" (those items have no Pip accessory node),
and the logic builder deliberately emits nothing so the view owns it. The K06
design defines no copy for that case, and the orchestrator's COPY rule requires
the design's characters exactly. The view therefore uses one clearly-marked,
factual, shame-free string — `kPipNotWearable = 'That one is not something Pip
can wear.'` — instead of leaving a dead control (an accessibility tap with no
observable effect) or inventing design copy silently. **Please ratify or
replace this string.**

## Verification run in this stage

* `flutter analyze lib test` → **No issues found**.
* `flutter test test/features/pip` → **52 passed** (my 18 view/widget tests
  plus the logic builder's bloc/repository tests).
* `dart format` clean.
* No simulator was booted, installed on, or screenshotted in this stage.

## LEFT FOR NEXT ITERATION

1. **UI check (stage 5) has not run.** The geometry above is asserted against
   *numbers measured from the design PNG*, not against a rendered app
   screenshot — `shot.sh` + `compare.py` in light and dark is still owed, and
   the two things I could not verify without it are (a) the nest/Pip art inside
   the 230 × 206 slot, which is the one place a local widget replaces a shared
   one, and (b) the dashed lock border's appearance against the PNG.
2. **Dark mode is rendered but not compared.** Everything is token-driven
   (`lilacTint`, `surface`, `surface2`, `ink`, `ink2`, `leafInk`, `kidShadow`),
   but only a smoke test exists; the dark PNG band table is owed.
3. **`NestProgress`'s kid highlight spans the whole track.** The design's
   `.progress.kid > span::after` paints the white sheen only inside the filled
   span; the shared widget paints it across the full bar. Shared component, out
   of scope here, but it will read as a ~4 px light streak past the fill in both
   themes — worth a line in the shared backlog.
4. **Text metrics in tests** are the bundled real faces (loaded via
   `FontLoader` in `pip_nest_widget_test.dart`), but `pip_nest_view_test.dart`
   runs on the default placeholder glyphs. Copy-width assertions at real
   metrics (the `k01_copy_fit_test.dart` pattern for K06's strings) are not
   written.
5. **Wide screens**: the wardrobe tiles and care buttons are `Expanded`, so
   they stretch at 430 px exactly as the HTML flex row would; no max-width
   container was added (the design has none).

VERDICT: PASS
