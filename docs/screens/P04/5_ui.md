# P04 · Privacy consent — UI check (STAGE 5, iteration 2)

Route `/privacy` · SEED=fresh · parent mode · child maya · simulator 604697A9-11DA-462F-9837-396E9CA2493A.
Shots: `docs/screens/P04/ui/app_light_2.png`, `docs/screens/P04/ui/app_dark_2.png`
(absolute OUT path — relative OUT breaks because `shot.sh` `cd`s to `app/` before copying).
Compares: `docs/screens/P04/ui/cmp_light_2.png`, `docs/screens/P04/ui/cmp_dark_2.png`.
Mandatory context: `docs/screens/P04/ORCHESTRATOR_NOTES.md` (items 1–4 + update override).

## Mean diff

- Light: **4.57%** (was 7.52%) — bands: 0 (0–105) 1.56% · 1 (105–211) 6.02% ·
  2 (211–316) 1.98% · 3 (316–422) 7.86% · 4 (422–527) 7.31% · 5 (527–633) 6.52% ·
  6 (633–738) 0.40% · 7 (738–844) 4.84%
- Dark: **5.61%** (was 8.12%) — bands: 0 (0–105) 1.54% · 1 (105–211) 8.50% ·
  2 (211–316) 9.14% · 3 (316–422) 7.76% · 4 (422–527) 7.12% · 5 (527–633) 6.69% ·
  6 (633–738) 0.39% · 7 (738–844) 3.67%

Band 6 ≈ 0.4% confirms pipeline alignment. Status-bar glyphs (mock `9:41` vs OS clock)
ignored per STATUS BAR rule; bottom-edge strip is the OWNER-rule override (app correct).

## Fixed since iteration 1

- Header offset gone: shared compact-nav fix (main `fc981bc`, 44→60 px) landed and merged.
  Probed logical y: back-chevron top 66 design / 66 app; H1 cap top 113 design / 113 app.
  Bands 1–2 dropped 13.18%→6.02% / 6.97%→1.98% (light). Orchestrator item 2 resolved without
  any local move, per the update override.

## Verified matching (no action)

- Presence/order/copy: chevron, H1, sub, 84 px shield, 4 promise rows with exact titles/subs,
  opt card copy, toggle OFF 51×31, primary `Continue`, underlined sky footnote link.
- 20 px side gutters; tile 40/r12; divider indent 72; opt-card 13 v/16 h; CTA bottom-anchored
  at design y; surface-to-edge bottom panel both themes; no overflow/clipping/ellipsis.
- No Pip on this screen → PIP rule N/A.

## Deviations

1. Row-4 tile still has no trash glyph (both themes) — ORCHESTRATOR_NOTES item 1, still open.
   Design value: rust glyph pixels `#BA562E`/`#B9542B` inside the peach tile (col x=52,
   y≈478/490, logical).
   App value: plain `#FFEDE4` across the whole tile — blank.
   Fix (P04 scope): render the bin/trash glyph in `a-peach`/rust at 24 px centred in the
   40×40 tile (SHARED_REQUEST item 1 asset if landed, else the agreed local path) + the
   widget test asserting all four row icons render. Designer-visible; blocks PASS.
2. Dark-mode shield disc still renders light (dark only).
   Design value: disc `#1A2A4A` (patch (160,228)).
   App value: disc `#E6EFFE` — `privacy_shield.svg` bakes the light hex.
   Fix (shared, SHARED_REQUEST item 2): themed shield asset. Designer-visible in dark mode.
3. Residual row-text drift, bands 3–5 ≈ 6.5–7.9% light / ≈ 6.7–7.8% dark (ORCHESTRATOR_NOTES
   item 3, still open).
   Design value: row text lines land exactly; opt card top ≈ y 528, Continue ≈ y 690.
   App value: row titles/subs show ~1 px doubling in the heat-map, accumulating down the list
   (rows ~1–2 px taller than the HTML); header and CTA both anchor correctly so this is purely
   intra-list height (row pad-v / title-sub gap / divider).
   Fix (P04 scope): match row heights and divider insets exactly from
   `design/html-source/screens/P04-privacy.html` (SPACING_SPEC §9: pad-v 7, wrap, indent 72).
   Sub-visible-threshold per row but accumulates; fix alongside deviation 1.

No code edited in this stage (UI check is read-only).

VERDICT: FAIL
