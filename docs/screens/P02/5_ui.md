# P02 Value tour — Stage 5 UI check (iteration 4)

Route `/value-tour`, seed `fresh`, mode `parent`, child `maya`, simulator
604697A9-11DA-462F-9837-396E9CA2493A (390×844). `ORCHESTRATOR_NOTES.md`
exists — all 4 items verified below. Copy checked character-by-character
against `design/html-source/screens/P02-value-tour.html` per the COPY rule.

Fresh shots taken by this stage (code changed after the old `_4` files):
`ui/app_light_4.png` / `app_dark_4.png` — both reached a stable frame.
Compares: `cmp_light_4.png`, `cmp_dark_4.png`.

## Mean diff

- Light: **3.92%** (bands: 0: 1.96, 1: 5.54, 2: 5.03, 3: 6.43, 4: 0.89,
  5: 3.95, 6: 4.37, 7: 3.12).
- Dark: **3.81%** (bands: 0: 1.84, 1: 5.42, 2: 5.10, 3: 5.94, 4: 0.82,
  5: 4.10, 6: 4.65, 7: 2.58). Dark token colours correct throughout.

Residual diff is raster-level text-width rendering, the OS status bar
(band 0, ignored per rule), the OS home-indicator pill, and the bottom
edge (bar surface to the screen edge — owner rule overrides the PNG).

## Orchestrator-notes verification (all mandatory items)

1. Static illustration copy, not the database: PASS — design's exact rows
   (`Maya · weekly`, `Leo · once`, `Maya · daily`), coins 15/15/10/15,
   `4 of 6 quests done today`, chip `Sat 4 Oct`.
2. Typographic punctuation: PASS — curly quotes + em dash in the step-1
   body, ’ / – in card titles, matching the HTML source.
3. No truncation: PASS — all four titles render in full on one line at 390
   (row-1 ends x=243, pill starts x=254, 11 px clear).
4. Bottom-edge rule: PASS in both themes.

## Element-by-element (logical px, design ÷ 3)

Card top y=107 both, 310 wide at x=20, peek card at x=342 both; rows at
exact 50 px pitch; progress, caption, dashed `New quest` row present and
ordered. Dots y=535–541 both; step title identical; body same wrap, ~4 px
higher (invisible standalone). Next button y=742–792 identical both
themes; CTA gutters 20; Skip coincides; no overflow, clipping, or
ellipsis anywhere. Steps 2–3 remain peek-only (content covered by widget
tests: 4 `PipAvatar`s mochi/sunny).

No numbered deviations. Nothing visible that a designer would reject.

VERDICT: PASS
