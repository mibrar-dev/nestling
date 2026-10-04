# K08 · Reward shop — UI check (stage 5, iteration 3)

Route `/reward-shop`, kid mode, child maya, seed demo, DISABLE_ANIMATIONS=1,
simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB (390×844 logical; all PNGs
1170×2532, logical = physical ÷ 3).

Shots: `docs/screens/K08/ui/app_light_3.png`, `app_dark_3.png` (absolute-path
`OUT`, since the script `cp`s after `cd $APP_DIR`). Compares:
`cmp_light_3.png`, `cmp_dark_3.png`. Icon evidence, design left / app right
at 6×: `icon3_r1c1_tv.png`, `icon3_r1c2_film.png`, `icon3_r2c1_moon.png`,
`icon3_r2c2_bake.png`, `icon3_r3c1_cafe.png`, `icon3_r3c2_dinner.png`
(iteration-1/2 files kept as history).

Iteration 1 FAILed on two card glyphs; iteration 2 verified the fixes and
PASSed. This iteration re-verifies after the icon-plumbing change
(`rewardIconFor(audience: kid)` per the ICONS orchestrator rule).

## Mean diff

- Light: **1.90 %** — bands 0: 1.54, 1: 0.44, 2: 0.51, 3: 0.12, 4: 0.35,
  5: 0.29, 6: 0.26, **7 (738–844): 11.65**.
- Dark: **1.73 %** — bands 0: 1.55, 1: 0.47, 2: 0.54, 3: 0.15, 4: 0.36,
  5: 0.33, 6: 0.28, **7 (738–844): 10.14**.
- Same profile as iteration 2. Band 0 = status-bar mock vs real OS bar
  (ignored per orchestrator). Band 7 = DB-driven taller café card + note +
  footer shift + home-indicator mock pill (items 1–3 below).

## Measured geometry, design vs app (logical px) — identical to the pixel

Border-run scan over all four images returns the same set:

| Element | Design | App | Δ |
|---|---|---|---|
| Title “Reward shop” first ink row | 118.33 | 118.33 | 0 |
| Row-1 card top / bottom | 201.00 / 348.00 | identical | 0 |
| Row-1 price/button rows | 401.00 / 414.00 | identical | 0 |
| Row-2 card top / bottom | 433.00 / 580.00 | identical | 0 |
| Row-2 price/button rows | 633.00 / 646.00 | identical | 0 |
| Row-3 card top | 665.00 | identical | 0 |

Back chevron visually aligned; lock-button and coin-pill background/border
rects unchanged from iteration 2 (lock x 315.3–368.7, y 48–101.3; pill
x 276–369.3, y 100–148.7); meadow edge within tolerance. No uniform vertical
shift; no misalignment.

## Element-by-element

- Presence/order: back chevron, `Grown-ups` lock, `Reward shop` title,
  `120` coin pill, subtitle, 6 cards in creation order
  (screen-time 50, film 80, bedtime 60, baking 100, café 150, dinner 90),
  footer below fold. All present, correct order.
- Copy (vs `K08-shop.html`, character-by-character): exact, including `café`
  é U+00E9, `30 more to go`, `Get it`; only intentional delta is the DB
  title `Trip to the park café` (item 1).
- Icons: all six match the design at 6× zoom — monitor, film-strip,
  crescent moon, bucket/basket, domed takeaway cup/pin, plain-triangle
  pizza. Per-crop pixel diffs of ~4 % are renderer anti-aliasing noise,
  present equally on every glyph including the long-stable ones; the
  zoomed pairs are visually identical in light and dark.
- Shapes: card/pill/lock/button background+border rects measured identical;
  art discs 56 px, glyphs 32 px, buttons min-height 56 / radius 16.
- Colours/radii/shadows: match in both modes (leaf buttons, coin-tint
  discs, coin-ink prices, 3 px ink borders, r24 cards, kid shadow; dark:
  navy page/cards, olive discs, gold prices, mint buttons).
- Overflow: none; two-line names stay inside the 40 px name box.

## Accepted / excluded items (not findings)

1. DB title `Trip to the park café` (2 lines) vs design’s 1-line
   `Park café trip` — database wins; taller card, visible `30 more to go`
   note at scroll-0, and shifted footer are DB-driven, excluded by the
   verdict rule.
2. Status-bar mock (`9:41`) vs real OS bar (`17:22`/`17:23`) — ignored per
   orchestrator.
3. Home-indicator mock pill in the design vs nothing in-app
   (`NestHomeIndicator` renders nothing; OS draws the real one) —
   systematic across screens, same as K01/K03.
4. `Save up!` off-button style is below the fold in both shots — not
   visually comparable; the `NestKidButton.white`-disabled fallback pending
   the filed `.k8-get.off` SHARED_REQUEST stands.

Owner rules: BOTTOM EDGE — no bottom bar on K08, meadow runs to the physical
edge in both modes, no strip. ALIGNMENT — pixel-identical throughout. PIP —
N/A (no Pip slot; text-only footer mention). No code touched this stage.

No numbered deviations remain; nothing a designer would reject.

VERDICT: PASS
