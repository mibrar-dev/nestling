# P04 · Privacy consent — UI check (STAGE 5, iteration 7)

Route `/privacy` · SEED=fresh · parent mode · child maya · simulator 604697A9-11DA-462F-9837-396E9CA2493A.
Shots: `docs/screens/P04/ui/app_light_7.png`, `docs/screens/P04/ui/app_dark_7.png`
(absolute OUT path — relative OUT breaks because `shot.sh` `cd`s to `app/` before copying).
Compares: `docs/screens/P04/ui/cmp_light_7.png`, `docs/screens/P04/ui/cmp_dark_7.png`.
Mandatory context: `docs/screens/P04/ORCHESTRATOR_NOTES.md`.

## Mean diff

- Light: **4.45%** (was 4.08%) — bands: 0 (0–105) 1.58% · 1 (105–211) 6.02% ·
  2 (211–316) 1.91% · 3 (316–422) 7.77% · 4 (422–527) 5.46% · 5 (527–633) 6.82% ·
  6 (633–738) 0.82% · 7 (738–844) 5.12%
- Dark: **4.43%** (was 3.98%) — bands: 0 (0–105) 1.60% · 1 (105–211) 6.29% ·
  2 (211–316) 1.87% · 3 (316–422) 7.72% · 4 (422–527) 5.42% · 5 (527–633) 7.79% ·
  6 (633–738) 0.80% · 7 (738–844) 3.91%

Band 5 jumped vs iteration 5 (4.19→6.82 light, 4.44→7.79 dark): one new regression below.

## Verified matching (no action)

- Header (chevron/H1/sub at design y), 84 px shield both themes (dark disc correct),
  all 4 promise rows with trash glyph rendering, toggle OFF 51×31, primary `Continue`,
  footnote link, 20 px gutters, surface-to-edge bottom panel both themes.
- Copy character-exact; no overflow/clipping/ellipsis elsewhere. No Pip → PIP rule N/A.
- Status-bar clock and home-indicator pill ignored per STATUS BAR rule / prior iterations.

## Deviations

1. Opt-card title wraps to two lines (both themes) — REGRESSION vs iteration 5, which was
   single-line and PASS.
   Design value: `Optional: help improve Nestling` on ONE line (ink rows y≈545–559 only).
   App value: `Optional: help improve` / `Nestling` on TWO lines (ink runs y≈545–559 AND
   y≈568–578), pushing the sub-copy and toggle geometry down ~22 px within the card.
   This is exactly what band 5 measures. A designer would reject the wrap.
   Fix (build stage, P04 scope — no code edited here): the opt-card text column lost width
   somewhere in the iteration-7 build (toggle hit-box, row gap, or card padding change —
   iteration 5 fit the same 16/22 Inter-600 string on one line). Restore the text-column
   width so the title fits on one line at 390 dp; keep the 44 px toggle tap target and
   16 h / 13 v card padding unchanged. Re-verify at text scale 1.0 that it stays one line.

No other element-level deviation. Residual bands 1/3/7 are the known font-raster doubling,
OS clock, home-indicator pill, and OWNER bottom-edge override.

VERDICT: FAIL
