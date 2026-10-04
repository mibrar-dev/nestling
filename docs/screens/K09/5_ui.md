# K09 · My jar — 5 UI CHECK (iteration 1)

Route `/my-jar`, simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB (390×844).
Seed `demo`, mode `kid`, child `maya`. No code edited.

Shots: `docs/screens/K09/ui/app_light_1.png`, `app_dark_1.png`.
Comparisons: `cmp_light_1.png`, `cmp_dark_1.png` (vs
`design/screens/light|dark/K09-jar.png`, 1170×2532 @3x → logical ÷3).

## Mean diff

- Light: **1.31%** (bands: 0–105: 1.59 · 105–211: 0.18 · 211–316: 0.16 ·
  316–422: 0.19 · 422–527: 1.39 · 527–633: 0.81 · 633–738: 2.21 ·
  738–844: 3.97)
- Dark: **1.34%** (bands: 0–105: 1.60 · 105–211: 0.19 · 211–316: 0.13 ·
  316–422: 0.44 · 422–527: 1.30 · 527–633: 1.12 · 633–738: 2.14 ·
  738–844: 3.80)

Band 0 is the OS status bar (18:38 + real glyphs vs mock 9:41 — ignored per
STATUS BAR rule). Bands 6–7 are dominated by the DB-driven first history row
(see 3) and the mock home-indicator pill (design) vs OS-drawn indicator
(absent in sim screenshots — same class as the status bar, ignored).

## Measured geometry, design vs app (logical px, ±2 px rule)

All script-measured on 390×844 downscales; identical unless stated:

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
runs to the physical edge in both themes — owner rule satisfied. Hero weight
ruling (Bold w700, `2_build.md`) confirmed: hero band diff 0.19% is noise.
Jar-fill ruling (fraction × interior) confirmed: jar crops identical.

## Numbered deviations

1. **History row-1 disc glyph wrong** (light + dark). Design
   (`K09-jar.html:85`): circle r8 + vertical stroke `M12 8v8` + two
   horizontal ticks `M9.5 9.5h5` / `M9.5 14.5h5` — a geometric coin-slot
   mark, NOT a £. App renders `NestIcons.poundCoin`, a curved £ letterform
   in the circle (crop `_tmp_*_r1`: straight double-tick mark vs £).
   Element: `.k9-ico` row 1, 22 px glyph in 40 px disc. Design value: HTML
   inline SVG; app value: shared pound-coin asset. Fix: `jarEntryGlyph`
   (`app/lib/features/kid_jar/presentation/widgets/jar_history_card.dart:10`)
   maps pocket-money rows to the shared icon; transcribe the HTML:85 SVG
   feature-private (jar-illustration precedent) or file a SHARED_REQUEST if
   the shared asset is meant to change. Note the mapping lives in feature
   code but the asset is shared (`core/design_system`), so the builder
   cannot just swap the asset.
2. **History row-2 (quest bonus) disc glyph wrong** (light + dark). Design
   (`K09-jar.html:90`): bins glyph — lid trapezoid `M6 3h12l-2 5H8Z` over a
   straight body with U bottom. App renders `NestIcons.questBins`, a
   handled box/briefcase shape with a dash (crop `_tmp_*_div`: test-tube/bin
   vs handled box — unmistakably different silhouettes). Element: `.k9-ico`
   row 2. Design value: HTML:90 bins SVG; app value: shared questBins asset
   via `jarEntryGlyph` (`jar_history_card.dart:11`). Fix: same as 1 —
   transcribe the HTML:90 bins SVG feature-private (and check the fallback
   claim in `2_build.md`, which asserted the fallback “is the design”: the
   rendered pixels prove it is not) or SHARED_REQUEST.
3. **Row-1 sub-copy + amount differ — NOT a finding (DB wins).** Design:
   “Last Saturday” / “+£3.80”. App: “This Sunday” / “+£3.00”. The demo seed
   is anchored to today (Sun 4 Oct 2026): the newest `weekly_base` entry is
   300p dated this week → “This Sunday” per the `1_plan.md` §b relative-day
   rule, and 300p formats as “+£3.00”. Correct per DATA OVER MOCKS; do not
   “fix” toward the mock. (Same reason the app shows 9 money-in rows vs the
   design’s 3 example rows; viewport rows 1–2 otherwise align exactly.)
4. **Gift-row glyph unverified (below the fold).** Rows 3+ (“Birthday money
   / From Mum”) are cut off at the viewport bottom in both the design and
   the app shot, so `NestIcons.gift` vs `K09-jar.html:95` could not be
   compared. Given deviations 1–2, the builder must crop-compare the gift
   glyph the same way before signing off (scroll or widget-level capture).

## Verdict reasoning

Geometry, copy, colours, radii, shadows, progress, jar art, alignment,
gutters, dark mode and bottom edge all pass with zero measurable drift.
Deviations 1–2 are icon-choice mismatches on two of the two visible history
rows — explicitly listed in the stage-5 checklist (“icon choice”) and
covered by the ICONS orchestrator rule (“each screen matches its own
design’s glyphs exactly”). A designer would reject either glyph swap, so
the check cannot pass despite the low mean diff.

VERDICT: FAIL
