# P13 · Payout — Stage 5 UI check (iteration 3)

Route `/payout`, simulator BC440E48-B3A3-43BC-971B-0EF5DB621874 (390×844).
Shots: `docs/screens/P13/ui/app_light_3.png`, `app_dark_3.png`
(seed demo, parent mode, Maya). Compares: `cmp_light_3.png`, `cmp_dark_3.png`
vs `design/screens/light|dark/P13-payout.png` (1170×2532 ÷ 3 = logical px;
all x/y below are logical px). Status-bar glyphs excluded per orchestrator
rule (OS draws the real bar).

## Mean diff

- Light: **0.43 %** — bands 0–7: 1.02 / 0.08 / 0.00 / 0.19 / 0.20 / 0.16 /
  0.38 / 1.41 %. (Iteration 2 was 0.61 %.)
- Dark: **0.44 %** — bands 0–7: 1.24 / 0.04 / 0.00 / 0.19 / 0.16 / 0.12 /
  0.30 / 1.45 %.

Band 0 residual is the OS status-bar time/glyphs (excluded). Band 7 is the
design home-pill mock (OS-drawn live; app correctly runs paper to the
edge). Bands 2–6 (≈0.2 %) are bundled-font rasterisation noise.

## Measured positions (design vs app, light; dark mirrors it)

| Element | Design | App | Δ |
|---|---|---|---|
| Scrim top edge | y 0 (full-screen dim) | y 0 (full-screen dim) | 0 |
| Sheet top edge (paper) | y ~343 | y ~343 | 0 |
| Sheet title "Saturday payout" | y ~383 | y ~383 | 0 |
| Subtitle "Tick once…" | y ~413 | y ~413 | 0 |
| Summary card rect | x 20–370, y ~115–154 | x 20–370, y ~115–154 | 0 |
| Summary text "Maya is owed £4.20 · Leo is owed £2.10" | x 37–278, y 122–133 | x 38–278, y 122–133 | 1 FIXED |
| Maya card rect | top y 445, x 20–369 | top y 445, x 20–369 | 0 |
| Leo card rect | top y 531, x 20–369 | top y 531, x 20–369 | 0 |
| Saverow card rect | top y 617, x 20–369 | top y 617, x 20–369 | 0 |
| Maya check rect (green, shape) | x 307–355 @ y 470 | x 307–355 @ y 470 | 0 |
| Leo check rect (empty, shape) | x 307–355 @ y 560 | x 307–355 @ y 560 | 0 |
| Toggle track rect (shape) | x 305–355, y 633–663 (51×31) | x 305–355, y 633–663 (51×31) | 0 FIXED |
| CTA rect (green pill, shape) | x 20–369, bottom ~750 | x 20–369, bottom ~750 | 0 |
| Caption "Your children…" last row | y ~790 | y ~790 | 0 |
| Bottom edge | paper to y 844 | paper to y 844 | 0 |

## Deviations

No deviations. Iteration-2 findings verified fixed: summary text is now
start-aligned (glyph bbox x 38–278 vs design 37–278, Δ1 within tolerance)
and the toggle track is right-flushed (x 305–355, Δ0). Every element shape
and position is within ±2 px in both themes.

Checked OK: presence/order of all elements; child order Maya→Leo; copy
incl. `you've`/`Maya's` ASCII apostrophes, `·` U+00B7, `&`, identical
two-line wraps; Maya ticked / Leo unticked; toggle ON; CTA label + caption;
avatars (lilac M / peach L, s44); check 48×48 r14, toggle 51×31, CTA min-h 52
pill, grabber 40×5, sheet radius-top 32, 20 px gutters, all cards and bars
edge-aligned; dark-mode leaf CTA/cards/toggle/scrim; OWNER bottom-edge rule
(paper to y 844, no strip); no overflow/clipping/ellipsis faults.

Non-findings (not deviations): status-bar time/glyphs (OS-drawn, excluded);
design home-indicator pill (OS-drawn live); ≤2 px glyph rasterisation
(bands 3–5 ≈ 0.2 %).

VERDICT: PASS
