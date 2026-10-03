# P04 · Privacy consent — UI check (STAGE 5, iteration 9)

Route `/privacy` · SEED=fresh · parent mode · child maya · simulator 604697A9-11DA-462F-9837-396E9CA2493A.
Shots: `docs/screens/P04/ui/app_light_9.png`, `docs/screens/P04/ui/app_dark_9.png`
(absolute OUT path — relative OUT breaks because `shot.sh` `cd`s to `app/` before copying).
Compares: `docs/screens/P04/ui/cmp_light_9.png`, `docs/screens/P04/ui/cmp_dark_9.png`.
Mandatory context: `docs/screens/P04/ORCHESTRATOR_NOTES.md` + LETTER SPACING rule (main
`fd92d95`: `NestType` defaults to letterSpacing 0, matching the CSS which sets no tracking).

## Mean diff

- Light: **1.84%** (was 3.87%) — bands: 0 (0–105) 1.56% · 1 (105–211) 0.29% ·
  2 (211–316) 1.08% · 3 (316–422) 3.75% · 4 (422–527) 3.16% · 5 (527–633) 0.52% ·
  6 (633–738) 0.21% · 7 (738–844) 4.16%
- Dark: **1.75%** (was 3.76%) — bands: 0 (0–105) 1.59% · 1 (105–211) 0.31% ·
  2 (211–316) 1.08% · 3 (316–422) 3.81% · 4 (422–527) 3.18% · 5 (527–633) 0.77% ·
  6 (633–738) 0.23% · 7 (738–844) 3.06%

Header bands 1–2 collapsed to ≈0.3–1.1% (letter-spacing fix); opt-card band 5 to ≈0.5–0.8%
(single-line title holds). Best result across all iterations.

## Verified matching (pixel-probed, logical px)

- Chevron top 66/66; H1 cap top 113/113; row-4 glyph `#BA562E`/`#BA562E`;
  dark shield disc `#1A2A4A`/`#1A2A4A`; CTA fill `#17804F`/`#17804F` at design y.
- Opt-card title single line both themes; toggle OFF 51×31; 20 px gutters; tiles 40/r12;
  divider indent 72; footnote link centred + underlined; surface-to-edge bottom panel both
  themes (OWNER rule — design PNG strip overridden, app correct).
- Copy character-exact (curly ’, em dashes); order exact. No Pip → PIP rule N/A.
  No overflow/clipping/ellipsis.

## Deviations

None. Residual band energy (3–4 ≈ 3–4%, 7 ≈ 3–4%, 0 ≈ 1.6%) is fully accounted for:
sub-pixel glyph raster on row titles, the ignored OS status-bar clock, the home-indicator
pill position, and the intentional OWNER bottom-edge override. No element-level deviation
a designer would reject.

No code edited in this stage (UI check is read-only).

VERDICT: PASS
