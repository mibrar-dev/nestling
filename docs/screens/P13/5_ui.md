# P13 · Payout — Stage 5 UI check (iteration 4)

Route `/payout`, simulator BC440E48-B3A3-43BC-971B-0EF5DB621874 (390×844).
Shots: `docs/screens/P13/ui/app_light_4.png`, `app_dark_4.png`
(seed demo, parent mode, Maya). Compares: `cmp_light_4.png`, `cmp_dark_4.png`
vs `design/screens/light|dark/P13-payout.png` (1170×2532 ÷ 3 = logical px;
all x/y below are logical px). Status-bar glyphs excluded per orchestrator
rule (OS draws the real bar).

## Mean diff

- Light: **0.62 %** — bands 0–7: 1.03 / 0.08 / 0.00 / 0.19 / 0.20 / 0.20 /
  1.87 / 1.41 %. (Iteration 3 was 0.43 %; band 6 regressed 0.38 → 1.87.)
- Dark: **0.63 %** — bands 0–7: 1.30 / 0.04 / 0.00 / 0.19 / 0.16 / 0.16 /
  1.75 / 1.45 %.

Band 0 residual is the OS status-bar time/glyphs (excluded). Band 7 is the
design home-pill mock (OS-drawn live; app correctly runs paper to the
edge).

## Measured positions (design vs app, light; dark mirrors it)

| Element | Design | App | Δ |
|---|---|---|---|
| Scrim top edge | y 0 (full-screen dim) | y 0 (full-screen dim) | 0 |
| Sheet top edge (paper) | y ~343 | y ~343 | 0 |
| Sheet title "Saturday payout" | y ~383 | y ~383 | 0 |
| Subtitle "Tick once…" | y ~413 | y ~413 | 0 |
| Summary card rect + text | x 20–370; glyphs x 37–278, y 122–133 | x 20–370; glyphs x 38–278, y 122–133 | ≤1 |
| Maya card rect | top y 445, x 20–369 | top y 445, x 20–369 | 0 |
| Leo card rect | top y 531, x 20–369 | top y 531, x 20–369 | 0 |
| Saverow card rect | top y 617, x 20–369 | top y 617, x 20–369 | 0 |
| Saverow text bbox | x 35–277, y 631–663 | x 36–286, y 631–663 | words differ — FAIL |
| Toggle track rect (shape) | x 305–355, y 633–663 (51×31) | x 305–355, y 633–663 (51×31) | 0 |
| Maya check rect (shape) | x 307–355 @ y 470 | x 307–355 @ y 470 | 0 |
| Leo check rect (shape) | x 307–355 @ y 560 | x 307–355 @ y 560 | 0 |
| CTA rect (shape) | x 20–369, bottom ~750 | x 20–369, bottom ~750 | 0 |
| Caption "Your children…" last row | y ~790 | y ~790 | 0 |
| Bottom edge | paper to y 844 | paper to y 844 | 0 |

## Deviations

1. **Saverow copy no longer matches the design (both themes).**
   Design (HTML truth, character-by-character): `Move £1.00 of Maya's to
   her Lego fund`. App renders: `Move £1.00 of Maya's to their Lego
   Friends set fund` ("their" for "her", "Lego Friends set fund" for "Lego
   fund"). Geometry is unaffected (same y-extent 631–663, toggle still
   x 305–355), but the words differ — violating the COPY rule and
   `1_plan.md` §(a) ("the design string with only `{nick}` interpolated").
   Fix: restore the exact design template in the saverow widget
   (`payout_sheet.dart` `_SaveRow`), interpolating only the nickname;
   do not substitute the goal title or change the pronoun.

Checked OK: every other element shape/position within ±2 px in both themes;
child order Maya→Leo; all other copy exact; Maya ticked / Leo unticked;
toggle ON 51×31; avatars s44; checks 48×48 r14; CTA min-h 52 pill; grabber
40×5; sheet radius-top 32; 20 px gutters; dark-mode colours; OWNER
bottom-edge rule; no overflow/clipping/ellipsis faults.

Non-findings (not deviations): status-bar time/glyphs (OS-drawn, excluded);
design home-indicator pill (OS-drawn live); ≤2 px glyph rasterisation
(bands 2–5 ≈ 0.2 %).

VERDICT: FAIL
