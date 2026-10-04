# K08 · Reward shop — UI check (stage 5, iteration 1)

Route `/reward-shop`, kid mode, child maya, seed demo, DISABLE_ANIMATIONS=1,
simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB (390×844 logical; all PNGs
1170×2532, logical = physical ÷ 3).

Shots: `docs/screens/K08/ui/app_light_1.png`, `app_dark_1.png` (absolute-path
invocation of `tools/screens/shot.sh`; the bare-relative `OUT` form in the
brief saves inside `app/` because the script `cp`s after `cd $APP_DIR`).
Compares: `cmp_light_1.png`, `cmp_dark_1.png`.
Icon evidence (design left, app right, 6× zoom): `icon_r1c1_tv.png`,
`icon_r1c2_film.png`, `icon_r2c1_moon.png`, `icon_r2c2_bake.png`,
`icon_r3c1_cafe.png`, `icon_r3c2_dinner.png`.

## Mean diff

- Light: **1.99 %** — bands 0: 1.55, 1: 0.44, 2: 0.54, 3: 0.12, 4: 0.81,
  5: 0.29, 6: 0.83, **7 (738–844): 11.28**.
- Dark: **1.82 %** — bands 0: 1.55, 1: 0.47, 2: 0.57, 3: 0.15, 4: 0.84,
  5: 0.33, 6: 0.86, **7 (738–844): 9.72**.
- Band 0 ≈ status-bar mock vs real OS bar (ignored per orchestrator).
  Band 7 = row-3 DB-driven height delta + note + footer shift +
  home-indicator mock pill (see 4, 6 below).

## Measured geometry, design vs app (logical px) — all within ±2

| Element | Design | App | Δ |
|---|---|---|---|
| Title “Reward shop” first ink row (light) | 118.33 | 118.33 | 0 |
| Title first ink row (dark) | 118.33 | 118.33 | 0 |
| Top-row lock-button bbox (light) | x 315.3–368.7, y 48.0–101.3 | identical | 0 |
| Coin-pill bbox (light) | x 276.0–369.3, y 100.0–148.7 | identical | 0 |
| Row-1 card top / bottom | 201.00 / 348.00 | identical | 0 |
| Row-1 “Get it” green start | 351.00 | identical | 0 |
| Row-2 card top / bottom | 433.00 / 580.00 | identical | 0 |
| Row-3 card top | 665.00 | identical | 0 |
| Meadow soft-edge start (x 10 / 195 / 380) | 546.7 / 548.0 / 546.7 | 548.3 / 549.7 / 546.3 | ≤ 1.7 (gradient edge, in tolerance) |
| Dark-mode border runs (cols x 103.3 / 286.7) | same set as light | identical | 0 |

Back chevron: visually aligned both modes (band-1 diff 0.44/0.47 is
glyph/text only). No uniform vertical shift anywhere above row 3.

## Deviations

1. **Baking-together card glyph — wrong object (major).** Design
   (`K08-shop.html:68`, `icon_r2c2_bake.png` left): basket/bucket with
   arch handle + trapezoid body. App (right): chef hat.
   Fix: `app/lib/features/kid_shop/presentation/widgets/shop_reward_icons.dart:20`
   maps `'cake' => NestIcons.chefHat`; map `'cake'` to the design’s bowl/basket
   glyph — `NestIcons.basket` exists in the shared set
   (`core/design_system/components/nest_icon.dart`) and is the obvious
   candidate; verify its SVG against the HTML path, else file a SHARED_REQUEST
   for a matching glyph. Seed key `cake` (`core/data/seed.dart:544`) is fine.
2. **Park-café card glyph — wrong drawing (major).** Design
   (`K08-shop.html:75`, `icon_r3c1_cafe.png` left): domed lid + tapered body,
   no handle, no steam, no saucer (reads as takeaway cup/pin).
   App (right): sit-down mug with handle + steam + saucer.
   Fix: `shop_reward_icons.dart:21` maps `'coffee' => NestIcons.cafe`; replace
   with the glyph matching the HTML path (check shared set first, e.g. whether
   any takeaway-cup exists; else SHARED_REQUEST). Seed key `coffee`
   (`seed.dart:545`) is fine.
3. **Pizza glyph drawing variance (minor, designer to confirm).** Design
   (`icon_r3c2_dinner.png` left): plain triangle + 3 dots. App (right):
   `NestIcons.pizza` slice with crust base + smaller dots. Same concept;
   acceptable as icon-font variance unless the designer insists on the plain
   triangle — listed so it is a conscious accept, not an unnoticed drift.
4. **Café card taller in app (accepted — database wins).** App/DB title is
   `Trip to the park café` (`seed.dart:545`), 2 lines, vs design’s 1-line
   `Park café trip`; plus the HTML-sourced `30 more to go` note
   (`shop_reward_card.dart:128-138`, copy `K08-shop.html:78` verbatim) is
   visible in the app at scroll-0 while the design cuts at the price row.
   Per DATA-OVER-MOCKS this is correct behaviour, not a defect; it explains
   most of the band-7 diff. Copy is character-exact (`café` é U+00E9, periods,
   `30 more to go`, `Get it` / `Save up!`, footer
   `You have 120 coins. Pip is helping you save!` verified in
   `reward_shop_view.dart:34-37` — footer itself is below the fold in both).
5. **Status bar (accepted — ignore per orchestrator).** Design mock
   `9:41` + mock glyphs vs real OS bar (`14:20`/`14:22`). `NestStatusBar`
   reserves height only. Explains band-0 diff.
6. **Home-indicator mock pill (accepted — systematic).** Design draws the
   134×5 pill; app renders nothing (`NestHomeIndicator`, mock-glyphs off —
   same pattern as K01/K03). Contributes to band-7 diff. No action.
7. **“Save up!” off style not visually comparable (info).** The unaffordable
   button is below the fold in both screenshots; the
   `NestKidButton.white`-disabled fallback pending the filed `.k8-get.off`
   SHARED_REQUEST cannot be checked until the icon/height fixes respin the
   shot — re-verify next iteration.

Owner rules: BOTTOM EDGE — no bottom bar on K08, meadow runs to the physical
edge in both modes, no strip under any bar. ALIGNMENT — gutters/cards/bars
pixel-identical to the design (table above). PIP — N/A (no Pip slot in this
design, text-only “Pip” footer mention; `1_plan.md` confirmed no `PipAvatar`).
Dark mode — colours match (navy page, dark cards, olive art discs, gold
prices, mint buttons); same two glyph deviations as light.

VERDICT: FAIL
