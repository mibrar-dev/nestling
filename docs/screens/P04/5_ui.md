# P04 · Privacy consent — UI check (STAGE 5, iteration 8)

Route `/privacy` · SEED=fresh · parent mode · child maya · simulator 604697A9-11DA-462F-9837-396E9CA2493A.
Shots: `docs/screens/P04/ui/app_light_8.png`, `docs/screens/P04/ui/app_dark_8.png`
(absolute OUT path — relative OUT breaks because `shot.sh` `cd`s to `app/` before copying).
Compares: `docs/screens/P04/ui/cmp_light_8.png`, `docs/screens/P04/ui/cmp_dark_8.png`.
Mandatory context: `docs/screens/P04/ORCHESTRATOR_NOTES.md`.

## Mean diff

- Light: **3.87%** (was 4.45%) — bands: 0 (0–105) 1.61% · 1 (105–211) 6.02% ·
  2 (211–316) 1.91% · 3 (316–422) 7.77% · 4 (422–527) 5.46% · 5 (527–633) 2.60% ·
  6 (633–738) 0.40% · 7 (738–844) 5.12%
- Dark: **3.76%** (was 4.43%) — bands: 0 (0–105) 1.58% · 1 (105–211) 6.29% ·
  2 (211–316) 1.87% · 3 (316–422) 7.72% · 4 (422–527) 5.42% · 5 (527–633) 2.88% ·
  6 (633–738) 0.39% · 7 (738–844) 3.91%

## Fixed since iteration 7

- Opt-card title wrap regression gone: `Optional: help improve Nestling` is ONE line again
  in both themes (ink probe: single title run y≈545–556, then body text — same structure as
  design). Band 5 dropped 6.82→2.60 light / 7.79→2.88 dark.

## Verified matching (pixel-probed, logical px)

- Opt-card title single-line both themes; row-4 glyph `#BA562E`/`#BA562E`;
  dark shield disc `#1A2A4A`/`#1A2A4A`; header at design y (chevron 66, H1 113 per
  iteration-5 probes, unchanged); toggle 51×31 OFF; CTA fill and y match.
- Copy character-exact (curly ’, em dashes); order exact; 20 px gutters; tiles 40/r12;
  divider indent 72; footnote link centred and underlined; surface-to-edge bottom panel
  both themes (OWNER rule — design PNG strip overridden, app correct).
- No Pip → PIP rule N/A. No overflow/clipping/ellipsis.

## Deviations

None. Residual band energy (1/3 ≈ 5–8%, 7 ≈ 4–5%) is fully accounted for: glyph-level
font-raster doubling on display/body strokes (all measured edges within ±2 px), the
ignored OS status-bar clock, the home-indicator pill position, and the intentional OWNER
bottom-edge override. No element-level deviation a designer would reject.

No code edited in this stage (UI check is read-only).

VERDICT: PASS
