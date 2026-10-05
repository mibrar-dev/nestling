# K09 · My jar — 5 UI CHECK (iteration 2)

Route `/my-jar`, simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB (390×844).
Seed `demo`, mode `kid`, child `maya`. No code edited.

Shots: `docs/screens/K09/ui/app_light_2.png`, `app_dark_2.png`.
Comparisons: `cmp_light_2.png`, `cmp_dark_2.png` (vs
`design/screens/light|dark/K09-jar.png`, 1170×2532 @3x → logical ÷3).

## Mean diff

- Light: **1.25%** (bands: 0–105: 1.57 · 105–211: 0.18 · 211–316: 0.16 ·
  316–422: 0.19 · 422–527: 1.09 · 527–633: 0.81 · 633–738: 2.09 ·
  738–844: 3.93)
- Dark: **1.29%** (bands: 0–105: 1.59 · 105–211: 0.19 · 211–316: 0.13 ·
  316–422: 0.44 · 422–527: 1.02 · 527–633: 1.12 · 633–738: 2.04 ·
  738–844: 3.76)

Residual diff is accounted for: band 0 = OS status bar (19:35/19:36 + real
glyphs vs mock 9:41 — ignored per STATUS BAR rule); bands 6–7 = the
DB-driven first history row (see 3) plus the mock home-indicator pill
(design) vs the OS-drawn indicator (absent in sim screenshots — same class
as the status bar, ignored). Down from 1.31/1.34% in iteration 1; the icon
heat is gone.

## Measured geometry, design vs app (logical px, ±2 px rule)

Script-measured on 390×844 downscales; identical unless stated:

| element | design | app | Δ |
|---|---|---|---|
| back chevron glyph box | x 43–51, y 67–82 | same | 0 |
| lock glyph box | x 334–349, y 66–83 | same | 0 |
| “My jar” glyph top | y 113 | y 113 | 0 |
| jar lid top (col x=195) | y 154 | y 153 | 1 ✓ |
| jar glass sides (y 200/250/350) | x 127–262 / 126–263 / 143–246 | same | 0 |
| hero “£4.20” glyph top | y 384 | y 384 | 0 |
| goal card top border | y 465–467 | y 465–467 | 0 |
| progress bar borders | y 557–558, 571–572 | same | 0 |
| goal card bottom border | y 615–617 | y 615–617 | 0 |
| “What went in” glyph top | y 639 | y 640 | 1 ✓ |
| history card top border | y 676–678 | y 676–678 | 0 |
| divider | y 739–740, x 89–367 (inset 66) | same | 0 |
| jar fill / coins / gloss / sparkle / shadow | — | pixel-identical in crops | 0 |
| progress fill 62% + gloss | — | pixel-identical in crops | 0 |

Copy (visible viewport): “My jar”, “£4.20”, “coming on Saturday”,
“Lego Friends set”, “£15.50”, “£9.49 to go”, “of £24.99”, “62% there!”,
“What went in”, “Pocket money”, “Put the bins out”, “Quest bonus”, “+12p”
all match the HTML character-for-character. Gutters 20 px both sides; both
cards share the same edges. No overflow/clipping/ellipsis issues.
Dark mode: sky, meadow, coin-tint card, disc tints, borders and shadows all
match the dark design. Bottom edge: no bar on this screen; shared meadow
runs to the physical edge in both themes — owner rule satisfied.

## Iteration-1 deviations — re-checked

1. **Row-1 disc glyph — FIXED.** Now renders the design's geometric
   coin-slot mark (`K09-jar.html:85`), verified in light and dark crops
   against the iteration-1 design crops. Feature uses shared
   `NestIcons.jarPocketMoney`, whose asset comment documents the exact
   HTML:85 paths.
2. **Row-2 (quest bonus) disc glyph — FIXED.** Now renders the bins glyph
   (`K09-jar.html:90`), verified in light and dark against the design.
   Feature uses `questIconFor(iconKey, audience: kid)` per
   ORCHESTRATOR_NOTES (18:47); the visible “Put the bins out” row resolves
   to the bins kid glyph.
3. **Row-1 sub-copy + amount (“This Sunday” / “+£3.00” vs “Last Saturday” /
   “+£3.80”) — NOT a finding (DB wins).** Seed anchored to today
   (Sun 4 Oct 2026); newest `weekly_base` is 300p this week. Correct per
   DATA OVER MOCKS. (Same reason the app lists 9 money-in rows vs the
   design's 3 example rows.)
4. **Gift-row glyph — covered by construction.** Still below the fold in
   both design and app (identical cut), so not screenshot-comparable; but
   the shared `ic_gift.svg` was read and its paths verified exact against
   `K09-jar.html:95` (`rect 3/9/18/12 rx2`, `M3 13h18`, `M12 9v12`, both
   bow loops). No pixel risk remains.
5. **ORCHESTRATOR_NOTES (18:47) third item — FIXED.** “coming on Saturday”
   colour measured: design text median (41,39,69), app (44,42,71) —
   identical, both ≈ `--ink`, not `--ink-2` (K09-BUG-2 fixed in pixels).

No new deviations found in iteration 2. K09-BUG-4/5/6 (stage 6) are logic /
below-fold matters owned by other stages; nothing in this (scroll-top)
frame shows them — BUG-6's own report confirms it “clips nothing and moves
no element of the initial frame”.

## Verdict reasoning

Every element is within ±2 px (worst Δ = 1 px), copy is character-exact
modulo DB-driven content, both history glyphs now match the HTML inline
SVGs in light and dark, dark-mode colours match, alignment/gutters are
exact, and the bottom edge trivially satisfies the owner rule. No visible
deviation a designer would reject remains.

VERDICT: PASS
