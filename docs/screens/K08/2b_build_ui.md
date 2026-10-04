# K08 · Reward shop — stage 2b build UI (iteration 1)

Scope: `app/lib/features/kid_shop/presentation/views/**` +
`presentation/widgets/**`, and the view/widget tests in
`app/test/features/kid_shop/` (`reward_shop_view_test.dart`,
`reward_shop_widget_geometry_test.dart`). No domain/data/bloc file was
touched — the logic builder's `2a_build_logic.md` reports **CONTRACT CHANGES:
None**, and re-reading it before finishing confirmed the plan names
(`KidShopRewardRequested(rewardId)` positional, state `{status, childId,
coins, items, requestingIds, notice, noticeSeq, errorMessage}`) are exactly
what this layer codes against.

## Files

- `views/reward_shop_view.dart` — rewritten from the placeholder. One
  `KidScope` + transparent `Scaffold` chrome for every state (status reserve,
  `.k8-top` back/lock, `NestHomeIndicator`), `BlocListener` on `noticeSeq` →
  `showNestToast` + `KidShopNoticeShown`, `BlocBuilder` switching
  loading / failure / empty / loaded, and the `.scroll.k8-scroll` column.
- `widgets/shop_reward_card.dart` (new) — `.k8-card`: surface, 3 px ink border,
  `--r-l` 24, `--sh-kid`, art disc, 40 px name row, coin price, "N more to go"
  note, and the `.k8-get` kid button.
- `widgets/shop_reward_icons.dart` (new) — the screen-private glyph map
  (`tv→screenTime`, `film→filmStrip`, `moon→moon`, `cake→chefHat`,
  `coffee→cafe`, `plate→pizza`, fallback `gift`), kept separate from P14's
  `rewardIconSpecs` on purpose (plan §a).
- `widgets/kid_shop_placeholder_card.dart` — **deleted**. Unreferenced
  (`grep` over `lib/` and `test/` found no import, `kid_shop.dart` never
  exported it) and now dead weight next to the real card.
- Tests: 31 tests across the two files (see Verification).

## Geometry — measured from the design PNG, not eyeballed

I measured `design/screens/light/K08-shop.png` (1170×2532) programmatically
(component scan per exact colour: `leaf #17804F`, `coin-tint #FFF4D1`,
`surface #FFFFFF`, `ink #1E1B3A`) and divided by 3. Every number in the plan
and in the new tests comes from that:

| element | design (÷3) | app (pinned in the geometry test) |
|---|---|---|
| back / lock boxes | y 47…103, x 20…76 / 314…370 | same (±0.5) |
| `.coin-pill.big` | x 276…370, y 109…149 (94×40) | same (±0.5) |
| heading line box | y 112…146 (34, centred in the 40 row) | ±2 |
| `.kcap` intro | y 165…185 (one line) | ±2 |
| grid row 1 | y 201…417 (216 tall), cols x 20…187 / 203…370 (167) | ±1 |
| grid row 2 | y 433…649 (216) | ±2 |
| grid row 3 | y 665…905 (240 — café note, dinner stretched) | ±2 |
| art disc | y 214…270 (56, centre 242), x centred 104 / 287 | ±2 |
| name row | y 276…316 (min 40; 2 lines = 38 → 277) | ±2 |
| price row | y 322…342 (20; label 16 → 324) | ±2 |
| `.k8-get` | x 33…174 (141), y 348…404 (56) | ±1 / ±2 |

Two details worth recording for the next iteration:

1. **The card's bottom padding is `--s1` (4), not the CSS `10`.**
   `NestKidButton` carries its own 6 px shadow room *inside* its widget box, and
   the CSS puts the button's `--sh-kid` shadow inside the card's 10 px bottom
   padding. `10 + 6` would make every card 222 tall instead of 216; `10 − 6 = 4`
   lands the card on 417 AND puts the shadow band at 404…410 with 4 px of white
   to the border at 414…417 — byte-for-byte what the PNG shows. Same reason the
   `NestKidButton` widget box measures 62 tall in the tests: the painted button
   is its first 56 px.
2. **The grid stretches the last row.** `IntrinsicHeight` + `CrossAxisAlignment.stretch`
   gives the dinner card the café card's 240 height with its content still at
   the top, which is the CSS grid's default `align-items: stretch`. `mainAxisAlignment`
   is left at `start` on purpose (`.k8-card` sets no `justify-content`).

Column width is computed from the slot (`Expanded` inside a pair row), so it is
132 px at 320 wide — pinned in the matrix test, never a hard-coded 167
(SPACING_SPEC §10.2).

## Owner rules applied

- **Kid background**: shared `KidScope` only (sky gradient + the shared 390×136
  meadow, bottom 0). No local hills, no stars outside the shared painter.
- **Bottom edge**: K08 has no bar — the list runs to the edge over the meadow,
  and `NestHomeIndicator()` renders nothing, so no coloured strip appears below
  the list or around the home indicator.
- **Alignment**: 20 px gutters on the top row, the scroll and the grid; cards,
  pill, lock and back all resolve to the same 20/370 edges (pinned in tests).
- **Copy**: transcribed character-by-character from the HTML — including
  `Trip to the park café` from the database (the HTML's "Park café trip" loses
  to the seeded title, per DATA OVER MOCKS) and the é in "café". No curly
  quotes or dashes are needed on this screen; the copy has none.
- **BALANCED HEADINGS**: the title renders through `NestBalancedText` (the
  `.kid-title` rule sets `text-wrap: balance`), never a bare `Text`.
- **Bottom bar / CTA**: none — nothing to paint to the edge.
- **PIP**: the design has no Pip slot on K08 (only the word "Pip" in the
  footer), so no `PipAvatar`. The failure and empty surfaces use the neutral
  96 px gift glyph, never a borrowed Pip, so they cannot contradict the PIP
  rule.
- **CHILD ORDER**: the grid renders `state.items` in repository order
  (creation order, `r-screen` → `r-dinner`), asserted in the view test.
- **FONTS / tracking / clock / ids**: no `google_fonts`, no tracking added
  (`NestType` defaults stay 0; the design's K08 CSS sets none), no
  `DateTime.now`, no ids minted in the view.
- **ACCESSIBILITY**: every control exposes `SemanticsAction.tap`; the view's own
  tests perform the real VoiceOver activation (`Back` → `/kid-home`, `Grown-ups`
  → `/parental-gate`, `Get Baking together` → a real `reward_redemptions` row +
  coins 120 → 20 + pill/footer/affordability all updating from the stream).
  `Save up!` reports `enabled: false` and offers no tap. No
  `Semantics(excludeSemantics: true)` in my files except the decorative art and
  the price coin, which are not interactive.
- **TOKENS ONLY**: colours and all shared metrics come from
  `context.nest` / `context.nestKid` / `NestSpacing` / `NestRadii`. Four
  screen-specific numbers have no token and are named local constants with the
  CSS they come from (`_backIconSize` 26, `_artSize` 56, `_artIconSize` 32,
  `_nameMinHeight` 40, `_coinSize` 20, `_getMinHeight` 56, `_getFontSize` 17) —
  the same pattern K03 uses for its design slots.

## Icons verified against the PNG

`screenTime` (monitor), `filmStrip` (side sprockets), `moon` (crescent),
`chefHat` (the K08 baking glyph), `cafe` (the cup/lamp-looking café mark),
`pizza` (slice with dots) — each matches the light design's art circle.

## SHARED_REQUEST (filed, non-blocking)

`docs/screens/K08/SHARED_REQUEST.md`: a `NestKidButton` colourway for
`.k8-get.off` (`surface-2`/`ink-2` at full opacity). Until it lands, the
unaffordable card uses `NestKidButtonColor.white` + `onPressed: null`
(plan §g), which is a deliberate, documented deviation — that one card reads
washed out instead of flat grey.

## Verification

- `flutter analyze lib/features/kid_shop test/features/kid_shop` → No issues
  found (no ignores, nothing weakened).
- `dart format lib/features/kid_shop test/features/kid_shop` → clean.
- `flutter test --timeout 120s test/features/kid_shop/` → **53 tests, all
  passed** (22 from the logic builder, 31 mine):
  - `reward_shop_view_test.dart` (20) — copy parity for title/pill/intro/footer,
    all six seeded titles in creation order, prices from the database, the
    "30 more to go" + "Save up!" pairing with no shaming copy, two-column grid
    gutters, row-stretch, back → `/kid-home`, lock → `/parental-gate`, tap
    actions on every control, the two real DB writes (`requested` keeps coins,
    instant `approved` spends them), the disabled button's semantics, empty /
    loading / failure surfaces, and the light + dark + 320 px @ 1.3 matrix.
  - `reward_shop_widget_geometry_test.dart` (11) — the design geometry table
    above, run with the bundled Nunito/Inter faces loaded (own file, so the
    real metrics cannot move the other 20 tests), every value within ±2 px.
- Whole-app `flutter test`, `dart format .` across the repo, and the
  light/dark `shot.sh` + `compare.py` band table were **not** run here — the
  brief assigns the simulator to stage `5_ui` and the whole-app run to the
  integrator. No simulator was booted, installed on or screenshotted in this
  stage.

## LEFT FOR NEXT ITERATION

1. `5_ui`: `tools/screens/shot.sh` for `/reward-shop` in light + dark
   (kid mode, `CHILD=maya`, `SEED=demo`, `DISABLE_ANIMATIONS=1`) and
   `compare.py` against both design PNGs — my geometry table is the prediction
   to check the band drift against, especially rows 2 and 3 (below the fold in
   the PNG, so only the design's own CSS backs them).
2. Swap the `Save up!` colourway once the SHARED_REQUEST lands.
3. Whole-app `flutter test` + repo-wide `dart format` (integrator).

VERDICT: PASS
