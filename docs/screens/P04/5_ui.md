# P04 · Privacy consent — UI check (STAGE 5, iteration 5)

Route `/privacy` · SEED=fresh · parent mode · child maya · simulator 604697A9-11DA-462F-9837-396E9CA2493A.
Shots: `docs/screens/P04/ui/app_light_5.png`, `docs/screens/P04/ui/app_dark_5.png`
(absolute OUT path — relative OUT breaks because `shot.sh` `cd`s to `app/` before copying).
Compares: `docs/screens/P04/ui/cmp_light_5.png`, `docs/screens/P04/ui/cmp_dark_5.png`.
Mandatory context: `docs/screens/P04/ORCHESTRATOR_NOTES.md` (items 1–4 + 12:03 + 13:42 updates).

## Mean diff

- Light: **4.08%** (was 4.10%) — bands: 0 (0–105) 1.58% · 1 (105–211) 6.02% ·
  2 (211–316) 1.98% · 3 (316–422) 7.94% · 4 (422–527) 5.62% · 5 (527–633) 4.19% ·
  6 (633–738) 0.40% · 7 (738–844) 4.84%
- Dark: **3.98%** (was 5.17%) — bands: 0 (0–105) 1.59% · 1 (105–211) 6.29% ·
  2 (211–316) 1.94% · 3 (316–422) 7.87% · 4 (422–527) 5.57% · 5 (527–633) 4.44% ·
  6 (633–738) 0.39% · 7 (738–844) 3.67%

## Fixed since iteration 4

- Row-4 trash glyph renders: `#BA562E` at tile centre in both design and app (was blank
  `#FFEDE4`). ORCHESTRATOR_NOTES item 1 closed.
- Dark shield disc now `#1A2A4A` in both (was `#E6EFFE` in app) — themed shield wired.
  Dark band 2 dropped 9.14%→1.94%. Item 2 closed.

## Verified matching (pixel-probed, logical px)

- Row-4 glyph `#BA562E`/`#BA562E`; dark disc `#1A2A4A`/`#1A2A4A`; light disc `#E7EFFC`/`#E7EFFC`.
- Chevron top 66/66; H1 cap top 113/113; opt-card top 500/500; list-card top 287/287.
- Toggle knob left edge x=295 both; track 51×31 both; CTA fill `#17804F` both, same y.
- Copy character-exact (curly ’, em dashes); order exact; 20 px gutters; tiles 40/r12;
  divider indent 72; toggle OFF; footnote link underlined sky, centred.
- Surface-to-edge bottom panel both themes (OWNER rule — design PNG strip overridden by
  design, app correct). No Pip → PIP rule N/A. No overflow/clipping/ellipsis.

## Deviations

None. Residual band energy (1/3 ≈ 6–8%, 7 ≈ 4–5%) is fully accounted for: glyph-level
font-raster doubling on Nunito/Inter strokes (all measured edges within ±2 px), the
ignored OS status-bar clock (`9:41` vs live time), the home-indicator pill position, and
the intentional OWNER bottom-edge override. No element-level deviation remains.

No code edited in this stage (UI check is read-only).

VERDICT: PASS
