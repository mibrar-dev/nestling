# P13 · Payout — Stage 5 UI check (iteration 2)

Route `/payout`, simulator BC440E48-B3A3-43BC-971B-0EF5DB621874 (390×844).
Shots: `docs/screens/P13/ui/app_light_2.png`, `app_dark_2.png`
(seed demo, parent mode, Maya). Compares: `cmp_light_2.png`, `cmp_dark_2.png`
vs `design/screens/light|dark/P13-payout.png` (1170×2532 ÷ 3 = logical px;
all x/y below are logical px). Status-bar glyphs excluded per orchestrator
rule (OS draws the real bar).

## Mean diff

- Light: **0.61 %** — bands 0–7: 1.04 / 0.94 / 0.00 / 0.19 / 0.20 / 0.16 /
  0.90 / 1.41 %. (Iteration 1 was 7.44 %: the full-screen scrim fix landed —
  header is dimmed again in both themes.)
- Dark: **0.57 %** — bands 0–7: 1.29 / 0.60 / 0.00 / 0.19 / 0.16 / 0.12 /
  0.76 / 1.45 %.

## Measured positions (design vs app, light; dark mirrors it)

| Element | Design | App | Δ |
|---|---|---|---|
| Scrim top edge | y 0 (full-screen dim) | y 0 (full-screen dim) | 0 FIXED |
| Sheet top edge (paper) | y ~343 | y ~343 | 0 |
| Sheet title "Saturday payout" | y ~383 | y ~383 | 0 |
| Subtitle "Tick once…" | y ~413 | y ~413 | 0 |
| Summary card rect | x 20–370, y ~115–154 | x 20–370, y ~115–154 | 0 |
| Summary text "Maya is owed £4.20 · Leo is owed £2.10" | x **37**–278, y 122–133 (left-aligned) | x **75**–315, y 122–133 (centered) | **+38 FAIL** |
| Maya card rect | top y 445, x 20–369 | top y 445, x 20–369 | 0 |
| Leo card rect | top y 531, x 20–369 | top y 531, x 20–369 | 0 |
| Saverow card rect | top y 617, x 20–369 (L/R edges x 21/369) | top y 617, x 20–369 (x 21/369) | 0 |
| Maya check rect (green, shape) | x 307–355 @ y 470 | x 307–355 @ y 470 | 0 |
| Leo check rect (empty, shape) | x 307–355 @ y 560 | x 307–355 @ y 560 | 0 |
| Toggle track rect (shape) | x **305**–355, y 633–663 (51×31) | x **301**–351, y 633–663 (51×31) | **−4 FAIL** |
| CTA rect (green pill, shape) | x 20–369, bottom ~750 | x 20–369, bottom ~750 | 0 |
| Caption "Your children…" last row | y ~790 | y ~790 | 0 |
| Bottom edge | paper to y 844 | paper to y 844 | 0 |

## Deviations

1. **Summary-card text is centered; design is left-aligned (both themes).**
   Design: `.caption` has no `text-align` (components.css:34), so the HTML
   truth is start-aligned at card padding (glyphs x 37 = card x 20 + pad 16
   + 1). App: `textAlign: TextAlign.center`
   (`payout_view.dart` `_DimmedLedger`, the `NestCard` summary `Text`;
   `1_plan.md` §(a) wrongly said "centered" — HTML/CSS truth overrides the
   plan). Card rect itself matches; only the text shifts 38 px. Visible in
   the dimmed card side-by-side and as the band-1 diff ghost.
   Fix: drop `textAlign: TextAlign.center` on the summary `Text` (default
   start alignment = design). Re-measure glyph bbox to x 37–278.
2. **Savings toggle track sits 4 px left of design (both themes).**
   Design: track x 305–355, right edge flush with card content edge
   (370 − 14 pad = 356, −1 antialias). App: x 301–351, leaving a ~5 px gap
   to the content edge; size is correct (51×31). Exceeds ±2 px.
   Fix: right-flush the `NestToggle` track in the saverow `Row`
   (`payout_sheet.dart` `_SaveRow`): inspect `NestToggle` for extra
   right-side padding/hit-slop that insets the 51 px track inside a wider
   box, and/or the row `gap`; track right edge must land at x 355–356.

Checked OK (no deviation): presence/order of all elements; child order
Maya→Leo; copy incl. `you've`/`Maya's` ASCII apostrophes, `·` U+00B7,
`&`, identical two-line wraps; Maya ticked / Leo unticked; toggle ON; CTA
label + caption; avatars (lilac M / peach L, s44); check 48×48 r14, CTA
min-h 52 pill, grabber 40×5, sheet radius-top 32, 20 px gutters, all cards
and bars edge-aligned; dark-mode leaf CTA/cards/toggle/scrim; OWNER
bottom-edge rule (paper to y 844, no strip); no overflow/clipping/ellipsis
faults.

Non-findings (not deviations): status-bar time/glyphs (OS-drawn, excluded);
design home-indicator pill (OS-drawn live; app correctly runs paper to the
edge); ≤2 px glyph rasterisation on names/amounts/CTA (bands 3–5 ≈ 0.2 %).

VERDICT: FAIL
