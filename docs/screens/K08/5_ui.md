# K08 · Reward shop — UI check (stage 5, iteration 2)

Route `/reward-shop`, kid mode, child maya, seed demo, DISABLE_ANIMATIONS=1,
simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB (390×844 logical; all PNGs
1170×2532, logical = physical ÷ 3).

Shots: `docs/screens/K08/ui/app_light_2.png`, `app_dark_2.png` (absolute-path
`OUT`, since the script `cp`s after `cd $APP_DIR`). Compares:
`cmp_light_2.png`, `cmp_dark_2.png`. Icon evidence, design left / app right
at 6×: `icon2_r1c1_tv.png`, `icon2_r1c2_film.png`, `icon2_r2c1_moon.png`,
`icon2_r2c2_bake.png`, `icon2_r3c1_cafe.png`, `icon2_r3c2_dinner.png`
(iteration-1 files `app_*_1.png`, `cmp_*_1.png`, `icon_*` kept as history).

Iteration 1 verdict was FAIL on two card glyphs (chef-hat for baking,
sit-down mug for café); both are fixed in this build, as is the pizza
drawing variance.

## Mean diff

- Light: **1.86 %** (was 1.99) — bands 0: 1.57, 1: 0.44, 2: 0.51, 3: 0.12,
  4: 0.35 (was 0.81), 5: 0.29, 6: 0.26 (was 0.83), **7 (738–844): 11.28**.
- Dark: **1.69 %** (was 1.82) — bands 0: 1.60, 1: 0.47, 2: 0.54, 3: 0.15,
  4: 0.36 (was 0.84), 5: 0.33, 6: 0.28 (was 0.86), **7 (738–844): 9.72**.
- Bands 4/6 drops confirm the icon fixes. Band 0 = status-bar mock vs real
  OS bar (ignored per orchestrator). Band 7 = DB-driven taller café card +
  note + footer shift + home-indicator mock pill (items 2–4 below).

## Measured geometry, design vs app (logical px) — identical to the pixel

Border-run scan (rows with >250 ink/border pixels, both modes, all four
images return the same set):

| Element | Design | App | Δ |
|---|---|---|---|
| Title “Reward shop” first ink row | 118.33 | 118.33 | 0 |
| Row-1 card top / bottom | 201.00 / 348.00 | identical | 0 |
| Row-1 price/button rows | 401.00 / 414.00 | identical | 0 |
| Row-2 card top / bottom | 433.00 / 580.00 | identical | 0 |
| Row-2 price/button rows | 633.00 / 646.00 | identical | 0 |
| Row-3 card top | 665.00 | identical | 0 |

Lock-button and coin-pill background/border rects re-verified identical to
iteration 1 (lock x 315.3–368.7, y 48–101.3; pill x 276–369.3, y 100–148.7),
meadow soft-edge start within ≤1.7 px (gradient edge, in tolerance). No
uniform vertical shift; no misalignment anywhere.

## Element-by-element

- Presence/order: back chevron, `Grown-ups` lock, `Reward shop` title,
  `120` coin pill, subtitle, 6 cards in creation order
  (screen-time 50, film 80, bedtime 60, baking 100, café 150, dinner 90),
  footer below fold. All present, correct order.
- Copy (vs `K08-shop.html`, character-by-character): exact —
  `Reward shop`, `Spend your coins on things you actually want.`,
  `30 min extra screen time`, `Pick Friday film`, `Stay up 15 min later`,
  `Baking together`, `Choose dinner`, prices, `30 more to go`, `Get it`;
  `café` é U+00E9 correct. Only intentional delta is the DB title
  `Trip to the park café` (item 2).
- Icons (6× crops): monitor, film-strip, crescent moon, **bucket/basket**,
  **domed takeaway cup/pin**, plain-triangle pizza — all six now match the
  design glyph-for-glyph in light and dark.
- Shapes, not just text: card/coin-pill/lock/button background+border rects
  measured identical (table above); art discs 56 px, glyphs 32 px, buttons
  min-height 56, radius 16 — all match.
- Colours/radii/shadows: leaf buttons, coin-tint discs, coin-ink prices,
  3 px ink borders, r24 cards, kid shadow — match in both modes. Dark mode:
  navy page/cards, olive discs, gold prices, mint buttons — match.
- Overflow: none; two-line names ellipsize within the 40 px name box.

## Accepted / excluded items (not findings)

1. Status-bar mock (`9:41`) vs real OS bar (`16:44`/`16:49`) — ignored per
   orchestrator (band 0).
2. DB title `Trip to the park café` (2 lines, `seed.dart`) vs design’s
   1-line `Park café trip` — database wins; the taller card + visible
   `30 more to go` note at scroll-0 (design cuts at the price row) and the
   shifted footer are DB-driven content, excluded by the verdict rule.
3. Home-indicator mock pill in the design vs nothing in-app
   (`NestHomeIndicator` renders nothing; OS draws the real one) — systematic
   across screens, same as K01/K03.
4. `Save up!` off-button style is below the fold in both shots — not
   visually comparable; the `NestKidButton.white`-disabled fallback pending
   the filed `.k8-get.off` SHARED_REQUEST stands.

Owner rules: BOTTOM EDGE — no bottom bar on K08, meadow runs to the physical
edge in both modes, no strip. ALIGNMENT — pixel-identical throughout. PIP —
N/A (no Pip slot; text-only footer mention). No `google_fonts`, no
`DateTime.now` touched (no code touched at all this stage).

No visible deviation a designer would reject remains.

VERDICT: PASS
