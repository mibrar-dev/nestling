# K04 Quest detail — Stage 5 UI check (iteration 1)

Simulator: BC440E48-B3A3-43BC-971B-0EF5DB621874 (390×844). Route `/quest-detail`, seed `demo`, mode `kid`, child `maya`.
Shots (absolute OUT paths — relative OUT breaks after `shot.sh` cds into `app/`):
`bash tools/screens/shot.sh "$PWD/app" /quest-detail "$PWD/docs/screens/K04/ui/app_light_1.png" BC440E48-B3A3-43BC-971B-0EF5DB621874 light demo kid maya`
…same with `dark` → `app_dark_1.png`.
Compares: `python3 tools/screens/compare.py design/screens/light/K04-quest-detail.png docs/screens/K04/ui/app_light_1.png docs/screens/K04/ui/cmp_light_1.png` (and dark).
Process note (not a finding): the first dark capture was a blank white splash (app not yet drawn; stable-frame matched the splash). Retried once; second capture rendered fully. Light 1.83%, dark 1.54% below are from valid frames.

## Mean diff + bands (390×844 normalized)

Light — mean diff: 1.83%. Bands (y-range diff%): 0 (0–105) 1.55 · 1 (105–211) 2.40 · 2 (211–316) 0.37 · 3 (316–422) 1.56 · 4 (422–527) 1.58 · 5 (527–633) 1.05 · 6 (633–738) 0.56 · 7 (738–844) 5.56.
Dark — mean diff: 1.54%. Bands: 0: 1.55 · 1: 2.30 · 2: 0.39 · 3: 1.23 · 4: 1.22 · 5: 0.85 · 6: 0.45 · 7: 4.30.
Residual is fully explained: band 1 = tile glyph strokes + unticked dots; band 7 = mandated bottom-edge override (surface vs design meadow strip) + home-pill rendering; bands 0–6 remainder = status-bar glyphs (ignored) + PipAvatar-vs-v1-svg rendering.

## Measured y positions (logical px, design vs app, edge-scan on 390×844 panels)

| Element | Light design | Light app | Dark design | Dark app |
|---|---|---|---|---|
| Back chevron top (first control) | 66 | 66 | — (same chrome) | — |
| Icon tile top border | 109 | 109 | 109 | 109 |
| Title "Tidy your bedroom" top | 245 | 245 | 245 | 245 |
| Steps card top border | 350 | 350 | 350 | 350 |
| Bottom-bar top border | 634 | 634 | 634 | 634 |
| "I did it!" button top | 647 | 647 | 647 | 647 |

No uniform vertical shift; every pinned edge is ±0 px (tolerance ±2 px).

## Element-by-element (light + dark)

Presence/order: back, lock, 120×120 tile, title, +15 pill, hint, 3-step card, Pip+cheer, "I did it!", "Back" — all present, in design order. Copy (char-for-char vs HTML): "Tidy your bedroom" / "+15" / "Tick each bit off, then press the big button." / "Clothes in the basket" / "Toys in the box" / "Books on the shelf" / "Pip is doing a happy dance!" / "I did it!" / "Back" — all match (all ASCII, no curly/dash issues on this screen). Gutters 20 px both sides; tile centered (x 135…255); steps card, cheer row and both bar buttons share the same 20 px edges; no misalignment. Tile 120×120 r24 peach-tint/brown, 3 px border, kid shadow; coin pill large centered; steps rows min-h 60 with 2 px dividers, 40 px dots; cheer Pip 64 + gap 12, bubble tail points at bar; bar buttons full-width min-h 64, gap 10, pad 12/20/10; bar surface runs to y 844 (no strip under it) in both themes. Dark colours match tokens (brown tile, olive pill, navy card, green/ink buttons). No overflow/clipping/ellipsis faults.

## Numbered deviations (element, design value, app value, disposition)

1. Tile icon glyph — design: plain bed outline (HTML inline SVG); app: bed with seated figure (`NestIcons.bedSit`, same mapping K03 uses for `bed`). Same 64 px, ink, centered slot; only stroke drawing differs. Disposition: ACCEPT, no fix — the mock's inline SVG is not the shared icon set; the builder correctly reused the canonical asset (plan §a, K03 consistency). Changing it would fork shared `core/` icons and desync K03/K04.
2. Step dots 1–2 fill — design: first two dots green-filled; app: all three hollow (fresh checklist). Disposition: ACCEPT, no fix — KNOWN DEVIATION documented in `1_plan.md` §(d); correct product behaviour (steps start unticked; never pre-tick to match the mock).
3. Pip art — design: v1 `pip-stage-3.svg` still; app: `PipAvatar` (Maya = mochi/sunny/stage 3). Disposition: ACCEPT, no fix — ORCHESTRATOR PIP RULE mandates the child's own Pip; slot size/position kept.
4. Bottom edge — design: meadow strip (light) / dark-green strip (dark) under the bar around the home pill; app: bar surface colour to the physical edge. Disposition: ACCEPT (app correct), no fix — OWNER BOTTOM-EDGE RULE overrides the designs; the app passes the must-fail-if-strip check.
5. Status bar — design "9:41" + mock glyphs; app OS time (14:20/14:22) + real glyphs. Disposition: IGNORED per STATUS BAR rule (`NestStatusBar` reserves height only); no fix.

Dark mode shows the same five items and nothing else; no dark-only deviation.

VERDICT: PASS
