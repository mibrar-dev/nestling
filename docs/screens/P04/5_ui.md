# P04 · Privacy consent — UI check (STAGE 5, iteration 4)

Route `/privacy` · SEED=fresh · parent mode · child maya · simulator 604697A9-11DA-462F-9837-396E9CA2493A.
Shots: `docs/screens/P04/ui/app_light_4.png`, `docs/screens/P04/ui/app_dark_4.png`
(absolute OUT path — relative OUT breaks because `shot.sh` `cd`s to `app/` before copying).
Compares: `docs/screens/P04/ui/cmp_light_4.png`, `docs/screens/P04/ui/cmp_dark_4.png`.
Mandatory context: `docs/screens/P04/ORCHESTRATOR_NOTES.md` (items 1–4 + 12:03 + 13:42 updates).

## Mean diff

- Light: **4.10%** (was 4.57%) — bands: 0 (0–105) 1.58% · 1 (105–211) 6.02% ·
  2 (211–316) 1.98% · 3 (316–422) 7.94% · 4 (422–527) 5.78% · 5 (527–633) 4.19% ·
  6 (633–738) 0.40% · 7 (738–844) 4.84%
- Dark: **5.17%** (was 5.61%) — bands: 0 (0–105) 1.56% · 1 (105–211) 8.50% ·
  2 (211–316) 9.14% · 3 (316–422) 7.87% · 4 (422–527) 5.75% · 5 (527–633) 4.44% ·
  6 (633–738) 0.39% · 7 (738–844) 3.67%

Band 6 ≈ 0.4% confirms pipeline alignment. Status-bar glyphs ignored per STATUS BAR rule;
bottom-edge strip is the OWNER-rule override (app correct). Bands 4–5 improved vs iteration 3
(7.31→5.78, 6.52→4.19 light) — intra-list heights converging on the HTML.

## Shared state (read-only check)

- `app/assets/icons/ic_trash.svg` now exists on main (shared batch 1, `4751c52`, merged).
  The P04 view in this working tree still carries the `TODO(P04)` reserved-tile path
  (`privacy_consent_view.dart:126-130`) — wiring the glyph is build-stage work, not this stage's.
- Themed privacy-shield asset likewise landed on main; the view still renders the old asset.

## Verified matching (no action)

- Presence/order/copy exact (curly ’, em dashes per COPY rule); header at design y;
  20 px gutters; 40 px tiles r12; divider indent 72; opt-card 13 v/16 h; toggle OFF 51×31;
  CTA anchored; surface-to-edge panel both themes; no overflow/clipping/ellipsis.
  No Pip → PIP rule N/A.

## Deviations

1. Row-4 tile still has no trash glyph (both themes) — ORCHESTRATOR_NOTES item 1, still open.
   Design value: rust glyph pixels inside the peach tile.
   App value: plain tile — light `#FFEDE4`, dark `#3E261D` (tile tint correct, glyph absent).
   Fix (build stage, now unblocked): replace the `TODO(P04)` reserved tile with
   `NestIcons.trash` in the design's red-ink colour + widget test that all four row icons
   render. Designer-visible; blocks PASS.
2. Dark-mode shield disc still renders light (dark only; explains dark bands 1–2 at 8.50/9.14%
   vs light 6.02/1.98% — the 84 px disc sits across both bands).
   Design value: `#1A2A4A` (patch (160,228)).
   App value: `#E6EFFE`.
   Fix (build stage, now unblocked): point the shield at the themed asset from shared batch 1.
   Designer-visible in dark mode.
3. Residual glyph-level drift, bands 1/3 ≈ 6–8% both themes.
   App value: H1/row-title strokes show ~1 px doubling — consistent with HTML-vs-Flutter font
   raster (Nunito 900) rather than layout error; all measured tops/edges match within ±2 px
   logical (chevron 66/66, H1 113/113 per iteration-2 probes; CTA at design y).
   Fix: none required unless the build stage can attribute it to a concrete metric; re-probe
   after deviations 1–2 land. Not independently designer-visible.

No code edited in this stage (UI check is read-only).

VERDICT: FAIL
