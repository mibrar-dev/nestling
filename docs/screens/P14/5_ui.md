# P14 · Rewards manager — Stage 5 UI check (iteration 1)

Simulator 604697A9-11DA-462F-9837-396E9CA2493A (390×844). Route `/rewards`, seed demo, parent mode.
Shots: `docs/screens/P14/ui/app_light_1.png`, `app_dark_1.png`.
Comparisons: `cmp_light_1.png`, `cmp_dark_1.png` (1170×2532 = 390×844 @3x).

## Mean diff

- Light: **2.06%** (bands: 0–105: 1.61, 105–211: 0.32, 211–316: 0.33, 316–422: 2.25, 422–527: 2.20, 527–633: 1.50, 633–738: 1.96, 738–844: 6.32)
- Dark: **1.96%** (bands: 0–105: 1.56, 105–211: 0.33, 211–316: 0.26, 316–422: 2.19, 422–527: 2.14, 527–633: 1.47, 633–738: 2.25, 738–844: 5.48)

Band 0 diff is the status bar (OS-drawn 12:20/12:21 vs design mock 9:41 — ignored per STATUS BAR rule).
Bands 3–7 diff is DB-driven content (see deviations 1–2), not geometry.

## Measured positions (logical px, design ÷3 vs app ÷3, pixel-measured)

| Element | Design y | App y | Δ |
|---|---|---|---|
| Screen title “Reward shop” first text row | 70.7 | 70.7 | 0 |
| Intro first text row | 187.0 | 187.0 | 0 |
| Card 1 top | 167.0 | 167.0 | 0 |
| Card 2 top | 305.0 | 305.0 | 0 |
| Card 3 top | 443.0 | 443.0 | 0 |
| Card 4 top | 581.0 | 581.0 | 0 |
| Card 5 top | 719.0 | 719.0 | 0 |
| Card L/R edges (cards 1–2) | 20.0 / 369.7 | 20.0 / 369.7 | 0 |

No uniform vertical shift. Every element within ±2 px.

## Element-by-element

- Nav bar: back chevron 44px left, centred “Reward shop” 18/24 w800 — position identical, no shift.
- Intro copy char-for-char: “Things coins can buy — you decide. Children spend coins, never pounds.” (em dash U+2014, full stop). Wraps to 2 lines in both.
- Cards: surface bg, r-16, sh-1, padding 12, 16 gaps, 20 px gutters both sides — edges identical.
- Icon tiles 40×40 r12 with tints (sky / peach-clock / lilac / leaf / coin) — match design; bedtime uses clock glyph per plan icon map (design HTML uses the same clock SVG).
- Coin pills with amounts 50/60/80/90/100 (+150 below fold) — correct pill shapes, no collapsed/text-width pills.
- “Needs my OK” rows + 51×31 toggles, edit 44×44 r12 bordered buttons — shapes match.
- “Trip to the park café” é (U+00E9) correct.
- “+ New reward” secondary full-width button rendered after the list in code (`rewards_view.dart:125`); below fold in both design PNG and app shot (design PNG also cuts off at the 5th card) — consistent.
- Bottom edge: no bottom bar on this screen; paper runs to the physical edge with home indicator over it in light and dark — no coloured strip. PASS.
- Alignment: 20 px gutters, cards/bars on same edges, nothing off. PASS.
- Dark mode: token-flipped surfaces/text, coin pills, green ON toggles, bordered edit buttons — correct, no light-mode leakage.
- No overflow/clipping/ellipsis issues; no red; no Pip on this screen (N/A).

## Numbered deviations (design value → app value)

1. Row order/content: design rows 2–3 are “Pick Friday film 80” then “Stay up 15 min later 60”, and design has 5 rows; app shows “Stay up 15 min later 60”, “Pick Friday film 80”, plus DB-only “Choose dinner 90” (price order 50/60/80/90/100/150, 6 rows). EXPECTED — DATA OVER MOCKS + `1_plan.md` §0 (DB order wins). Not a defect.
2. “Baking together” toggle: design OFF → app ON. EXPECTED — seed `needsOk` defaults true for all rows (`1_plan.md` §0 overrides the PNG). Not a defect.
3. Status-bar clock 9:41 → 12:20/12:21 (and icon set). EXPECTED — OS draws the real status bar; ignored per rule.
4. Band 7 diff 6.32% light / 5.48% dark (bottom viewport shows different rows + home-pill blend). Consequence of deviations 1–2 shifting which row sits at the fold; card geometry itself is pixel-identical. Not a defect.

No code edited this stage. No fix needed — deviations 1–4 are all orchestrator-mandated, geometry is exact, and there is no visible deviation a designer would reject.

VERDICT: PASS
