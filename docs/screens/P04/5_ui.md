# P04 · Privacy consent — UI check (STAGE 5, iteration 3)

Route `/privacy` · SEED=fresh · parent mode · child maya · simulator 604697A9-11DA-462F-9837-396E9CA2493A.
Shots: `docs/screens/P04/ui/app_light_3.png`, `docs/screens/P04/ui/app_dark_3.png`
(absolute OUT path — relative OUT breaks because `shot.sh` `cd`s to `app/` before copying).
Compares: `docs/screens/P04/ui/cmp_light_3.png`, `docs/screens/P04/ui/cmp_dark_3.png`.
Mandatory context: `docs/screens/P04/ORCHESTRATOR_NOTES.md` (items 1–4 + 12:03 + 13:42 updates).

## Mean diff

- Light: **4.57%** (unchanged from iteration 2) — bands: 0 (0–105) 1.56% ·
  1 (105–211) 6.02% · 2 (211–316) 1.98% · 3 (316–422) 7.86% · 4 (422–527) 7.31% ·
  5 (527–633) 6.52% · 6 (633–738) 0.40% · 7 (738–844) 4.84%
- Dark: **5.61%** (unchanged from iteration 2) — bands: 0 (0–105) 1.54% ·
  1 (105–211) 8.50% · 2 (211–316) 9.14% · 3 (316–422) 7.76% · 4 (422–527) 7.12% ·
  5 (527–633) 6.69% · 6 (633–738) 0.39% · 7 (738–844) 3.67%

Band 6 ≈ 0.4% confirms pipeline alignment. Status-bar glyphs (mock `9:41` vs OS clock)
ignored per STATUS BAR rule; bottom-edge strip is the OWNER-rule override (app correct).

## Unchanged since iteration 2 (still correct)

- Header alignment from the shared compact-nav fix: chevron/H1 at design y.
- Presence/order/copy all exact (curly ’, em dashes per COPY rule); 20 px gutters; 40 px
  tiles r12; divider indent 72; opt-card 13 v/16 h; toggle OFF 51×31; CTA anchored at design
  y; surface-to-edge bottom panel; no overflow/clipping/ellipsis. No Pip → PIP rule N/A.

## Deviations

1. Row-4 tile still has no trash glyph (both themes) — ORCHESTRATOR_NOTES item 1, still open.
   Design value: rust glyph pixels `#BA562E`/`#B9542B` inside the peach tile (x=52, y≈478/490).
   App value: plain `#FFEDE4` — blank tile. Verified `ic_trash.svg` / `NestIcons.trash`
   still absent from `app/assets/icons/` + design system (only `ic_bin.svg`, the cart, exists);
   the 13:42 orchestrator update keeps the reserved 40×40 tile + `TODO(P04)` until the shared
   batch lands, so no local fix is possible in this stage.
   Fix: use `NestIcons.trash` in the design's red-ink colour once main provides it + widget test
   that all four row icons render. Designer-visible; blocks PASS.
2. Dark-mode shield disc still renders light (dark only).
   Design value: `#1A2A4A` (patch (160,228)).
   App value: `#E6EFFE` — `privacy_shield.svg` bakes the light hex.
   Fix (shared, SHARED_REQUEST item 2, in the 13:42 shared batch): token-coloured shield asset.
   Designer-visible in dark mode.
3. Residual row-text drift, bands 3–5 ≈ 6.5–7.9% light / ≈ 6.7–7.8% dark (ORCHESTRATOR_NOTES
   item 3).
   Design value: row text lines land exactly; opt card top ≈ y 528, Continue ≈ y 690.
   App value: ~1 px doubling per row in the heat-map, accumulating down the list (rows ~1–2 px
   taller than the HTML); header and CTA anchor correctly so this is intra-list height only.
   Fix (P04 scope, next build stage): match row heights/divider insets exactly from
   `design/html-source/screens/P04-privacy.html` (SPACING_SPEC §9: pad-v 7, wrap, indent 72).

No code edited in this stage (UI check is read-only).

VERDICT: FAIL
