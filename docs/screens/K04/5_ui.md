# K04 Quest detail — Stage 5 UI check (iteration 3)

Simulator: BC440E48-B3A3-43BC-971B-0EF5DB621874 (390×844). Route `/quest-detail`, seed `demo`, mode `kid`, child `maya`.
Shots: `bash tools/screens/shot.sh "$PWD/app" /quest-detail "$PWD/docs/screens/K04/ui/app_light_3.png" BC440E48-B3A3-43BC-971B-0EF5DB621874 light demo kid maya` (same `dark` → `app_dark_3.png`).
Compares: `python3 tools/screens/compare.py design/screens/light/K04-quest-detail.png docs/screens/K04/ui/app_light_3.png docs/screens/K04/ui/cmp_light_3.png` (and dark). Both captures rendered fully first try.

## Mean diff + bands (390×844 normalized)

Light — mean diff: 1.57%. Bands: 0 (0–105) 1.59 · 1 (105–211) 0.28 · 2 (211–316) 0.37 · 3 (316–422) 1.56 · 4 (422–527) 1.58 · 5 (527–633) 1.05 · 6 (633–738) 0.56 · 7 (738–844) 5.56.
Dark — mean diff: 1.29%. Bands: 0: 1.60 · 1: 0.29 · 2: 0.39 · 3: 1.23 · 4: 1.22 · 5: 0.85 · 6: 0.45 · 7: 4.30.
Band 1 fell from ~2.2% (iteration 2) to 0.28/0.29%: the iteration-2 hero-glyph FAIL is fixed — tile region is now near-black in the diff heat-map. Band 7 = mandated bottom-edge override (surface vs design meadow strip) + home pill; band 0 = status-bar glyphs (ignored).

## Measured y positions (logical px, design vs app, edge-scan on 390×844 panels)

| Element | Light design | Light app | Dark design | Dark app |
|---|---|---|---|---|
| Icon tile top border | 109 | 109 | 109 | 109 |
| Title "Tidy your bedroom" top | 245 | 245 | 245 | 245 |
| Steps card top border | 350 | 350 | 350 | 350 |
| Bottom-bar top border | 634 | 634 | 634 | 634 |
| "I did it!" button top | 647 | 647 | 647 | 647 |

No uniform vertical shift; every pinned edge ±0 px (tolerance ±2 px).

## Element-by-element (light + dark)

Presence/order/copy/sizes/alignment/colours/radii/shadows/overflow all match: back + lock 56, 120×120 tile with the design's bed glyph (headboard, pillow, base, legs — matches K04 tile exactly, light and dark), title, +15 pill, hint, 3-step card (rows min-h 60, 2 px dividers, 40 px dots), Pip 64 + bubble (tail at bar), "I did it!" + "Back" full-width min-h 64, 20 px gutters everywhere, bar surface to y 844, dark tokens correct. Copy char-for-char vs HTML: all strings match (all ASCII on this screen).

## Numbered deviations (element, design value, app value, fix)

1. Step dots 1–2 fill — design: first two green-filled; app: all hollow. ACCEPT, no fix: known deviation per `1_plan.md` §(d), correct runtime behaviour (fresh checklist starts unticked; never pre-tick to match the mock).
2. Pip art — design: v1 `pip-stage-3.svg`; app: `PipAvatar` Maya mochi/sunny/stage 3. ACCEPT: orchestrator PIP RULE override; slot size/position kept.
3. Bottom edge — design: meadow/dark-green strip under bar; app: bar surface to physical edge. ACCEPT (app correct): OWNER BOTTOM-EDGE RULE; a strip would be a must-fail.
4. Status-bar time/glyphs — IGNORED per STATUS BAR RULE.
5. Iteration-2 hero-glyph FAIL (hollow-rectangle `questBed`) — FIXED this iteration per the new ICONS rule (kid glyphs via `questIconFor`, screen matches its own design's glyphs); band 1 confirms. No action.

No other deviations in either theme.

VERDICT: PASS
