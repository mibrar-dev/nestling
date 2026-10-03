# P14 · Rewards manager — Stage 5 UI check (iteration 3)

Simulator 604697A9-11DA-462F-9837-396E9CA2493A (390×844). Route `/rewards`, seed demo, parent mode.
Shots: `docs/screens/P14/ui/app_light_3.png`, `app_dark_3.png`.
Comparisons: `cmp_light_3.png`, `cmp_dark_3.png` (1170×2532 = 390×844 @3x).

ORCHESTRATOR_NOTES.md applied and holding: `watchRewardsInCreationOrder`
(50/80/60/100/150 design order, “Choose dinner” below the fold), Baking `needsOk=false`
from the DB, toggle state never hard-coded.

## Mean diff

- Light: **0.97%** (bands: 0–105: 1.64, 105–211: 0.32, 211–316: 0.33, 316–422: 0.39, 422–527: 0.31, 527–633: 0.35, 633–738: 0.18, 738–844: 4.21)
- Dark: **0.91%** (bands: 0–105: 1.58, 105–211: 0.33, 211–316: 0.26, 316–422: 0.33, 422–527: 0.27, 527–633: 0.31, 633–738: 0.19, 738–844: 3.97)

Bands 1–6 are text anti-aliasing only. Band 0 is the status bar (OS-drawn 16:33/16:41
vs design mock 9:41 — ignored per STATUS BAR rule). Band 7 is the home-indicator zone
(see deviation 2).

## Measured positions (logical px, design ÷3 vs app ÷3, pixel-measured)

| Element | Design y | App y | Δ |
|---|---|---|---|
| Screen title “Reward shop” first text row | 70.7 | 70.7 | 0 |
| Intro first text row | 187.0 | 187.0 | 0 |
| Card 1 top (30 min extra screen time) | 167.0 | 167.0 | 0 |
| Card 2 top (Pick Friday film) | 305.0 | 305.0 | 0 |
| Card 3 top (Stay up 15 min later) | 443.0 | 443.0 | 0 |
| Card 4 top (Baking together) | 581.0 | 581.0 | 0 |
| Card 5 top (Trip to the park café) | 719.0 | 719.0 | 0 |
| Card L/R edges | 20.0 / 369.7 | 20.0 / 369.7 | 0 (iter 2 measurement, layout unchanged) |

No uniform vertical shift. Every element within ±2 px.

## Element-by-element

- Nav bar: 44 px back chevron, centred “Reward shop” 18/24 w800 — identical position.
- Intro copy char-for-char: “Things coins can buy — you decide. Children spend coins, never pounds.” (em dash U+2014). 2-line wrap matches.
- Row order/names/prices match the design exactly: 50 / 80 / 60 / 100 / 150; “Trip to the park café” é (U+00E9) correct.
- Toggles match the design exactly: ON, ON, ON, OFF (Baking — from DB `needsOk`, not hard-coded), ON. “Needs my OK” labels identical.
- Cards: surface bg, r-16, sh-1, padding 12, 16 gaps, 20 px gutters — edges identical; pill/button background rects full-size, no collapsed shapes.
- Icon tiles 40×40 r12, tints sky/lilac/peach/coin/leaf match; edit 44×44 r12 bordered buttons match.
- Bottom edge: no bottom bar; paper runs to the physical edge in light and dark, no coloured strip. PASS.
- Alignment: consistent 20 px gutters, nothing off. PASS.
- Dark mode: token-flipped surfaces/text, coin pills, green ON toggles, grey OFF toggle on Baking — correct.
- No overflow/clipping/ellipsis issues; no red; no Pip on this screen (N/A).

## Numbered deviations (design value → app value, fix)

1. Trip-card icon glyph: design mock draws a serving cloche → app draws the shared `ic_cafe` coffee cup. NOT A SCREEN DEFECT — the shared design-system asset (`nestling_assets.dart:214-216`) canonically defines the “trip to the park cafe” reward glyph as cup/saucer/steam, and K08 uses the same asset for the same reward. No in-feature fix exists (screen must use token assets). Fix: none.
2. Bottom fold clipping: design mock clips card 5 mid-toggle above its drawn 34 px home block → app shows the full card under the OS-drawn home indicator. NOT A DEFECT — no element position differs (only the mock-chrome clip), the 66 px scroll pad stands in for the home band per stage-4 review, and the P01 BUG-2 precedent forbids double-reserving the 34 px. Same category as ignored status-bar chrome. Fix: none.
3. Status-bar clock/glyphs 9:41 → 16:33/16:41. Ignored per STATUS BAR rule (OS draws the real bar). Fix: none.

No code edited this stage. No visible deviation a designer would reject; result stable across iterations 2–3.

VERDICT: PASS
