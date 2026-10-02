# P02 Value tour — Stage 5 UI check (iteration 3)

Route `/value-tour`, seed `fresh`, mode `parent`, child `maya`, simulator
604697A9-11DA-462F-9837-396E9CA2493A (390×844). `ORCHESTRATOR_NOTES.md`
exists — all 4 items verified below. Copy checked character-by-character
against `design/html-source/screens/P02-value-tour.html` per the COPY rule.

Fresh shots taken by this stage: `ui/app_light_3.png` / `app_dark_3.png`
(both reached a stable frame — the iteration-1 motion issue is gone).
Compares: `cmp_light_3.png`, `cmp_dark_3.png`.

## Mean diff

- Light: **4.00%** (bands: 0: 2.00, 1: 5.54, 2: 5.03, 3: 6.43, 4: 0.89,
  5: 3.95, 6: 4.37, 7: 3.80).
- Dark: **3.83%** (bands: 0: 1.91, 1: 5.42, 2: 5.10, 3: 5.94, 4: 0.82,
  5: 4.10, 6: 4.65, 7: 2.70). Dark token colours correct throughout.

Residual diff is raster-level text-width rendering (Flutter Inter runs
~4 px wider than the browser), the OS status bar (band 0, ignored per
rule), the home-indicator pill (OS-drawn), and the bottom edge (bar
surface to the screen edge — owner rule overrides the PNG).

## Orchestrator-notes verification (all mandatory items)

1. Static illustration copy, not the database: PASS. Card shows the
   design's exact rows — `Empty the dishwasher / Maya · weekly`,
   `Put the bins out / Leo · once`, `Reading – 20 minutes / Maya · daily`,
   `Tidy your bedroom / Maya · weekly`, coins 15/15/10/15,
   `4 of 6 quests done today`, chip `Sat 4 Oct`.
2. Typographic punctuation: PASS. Body reads `Pick from 40+ ready-made
   jobs like “Put the bins out” — or make your own.` with curly quotes and
   em dash, matching the HTML source; card titles use ’ / – correctly.
3. No truncation: PASS. All four titles render in full on one line at 390
   (row-1 ends x=243, pill starts x=254 — 11 px clear; pill/tile geometry
   measures identical to design).
4. Bottom-edge rule: PASS in both themes — Next panel surface runs to the
   physical edge, no coloured strip.

## Element-by-element (logical px, design ÷ 3)

1. Card: top y=107 both, 310 wide at x=20, peek card at x=342 both.
   Head, chip, 4 rows (pitch 50 both), progress 4/6, caption, dashed
   `New quest` row all present, ordered, correct copy/icons/tints.
2. Dots y=534–540 both; active 22 px leaf pill + 2 dots, centred.
3. Step title y=584–604 identical; body same left edge (x=22), same 2-line
   wrap, ~4 px higher than design (630 vs 634) — invisible standalone.
4. Rows sit +2–4 px vs design with exact pitch and exact card bounds —
   within rendering tolerance, nothing a designer would reject.
5. Next button y=742–792 identical in both themes; CTA side gutters 20;
   Skip position coincides; no overflow, clipping, or ellipsis anywhere.

No numbered deviations remain. 320-wide / 1.3-scale wrap behaviour is
covered by widget tests not this simulator pass; steps 2–3 stay
peek-only (content covered by tests: 4 `PipAvatar`s mochi/sunny).

VERDICT: PASS
