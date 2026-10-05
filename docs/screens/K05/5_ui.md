# K05 Quest complete — 5 UI check (iteration 2)

Route `/quest-complete`, kid mode, child maya, seed demo, simulator 604697A9-11DA-462F-9837-396E9CA2493A.
Captures: `docs/screens/K05/ui/app_light_2.png`, `app_dark_2.png`.
Compare sheets: `cmp_light_2.png`, `cmp_dark_2.png` (all panels normalised to 390×844; design PNGs are 1170×2532 ÷3).

**Mean diff: light 2.66%, dark 2.01%.**

Band tables (y-range logical, diff%):

Light: 0 (0–105) 1.54 · 1 (105–211) 2.60 · 2 (211–316) 8.47 · 3 (316–422) 0.43 ·
4 (422–527) 0.55 · 5 (527–633) 0.49 · 6 (633–738) 0.87 · 7 (738–844) 6.34.

Dark: 0 (0–105) 1.58 · 1 (105–211) 1.65 · 2 (211–316) 6.06 · 3 (316–422) 0.39 ·
4 (422–527) 0.54 · 5 (527–633) 0.42 · 6 (633–738) 1.03 · 7 (738–844) 4.44.

High bands are fully explained: band 2 = hero Pip artwork (orchestrator PIP
override, §1); band 7 = bottom-edge owner-rule override + OS home-indicator
glyph (ignored, §§2–3); band 0 residual = OS status-bar clock (ignored, §4).

Method: read `cmp_light_2.png` / `cmp_dark_2.png` (design | app | red heat-map),
then measured visible background/border rects (not just text) in Python on both
PNGs resized to 390×844 with LANCZOS, design vs app. Tolerances are ±2 px
logical per the UI verdict rule. Status-bar glyphs ignored; DB-driven numbers
(Maya 175/250, +15) match the seed.

Key rects, design vs app (x, y logical; y from screen top incl. 47 px status reserve):

- Screen title ink `Brilliant, Maya!`: design (50, 349)–(340, 384) vs app identical. Title y 349 both. ±0.
- First control (lock `Grown-ups` white fill): design (315, 48)–(368, 101) vs app identical. Top y 48 both. ±0.
- Coin pill tint `+15 coins`: design (121, 403)–(268, 442) vs app identical. Top y 403 both. ±0.
- Growth card outer ink border: design (20, 535)–(369, 694) vs app identical. Card top y 535 both. 20 px gutters ✓.
- Kid bar divider (3 px ink): y 721 both, full width. Bar top y 721 both.
- CTA green fill `Yay! Back home`: design (23, 739)–(366, 796) vs app identical. ±0.
- Dark mode: title ink top y 349 identical; card bg (20, 540)–(369, 719) identical; pill / CTA rects identical.

Copy (character-by-character vs `design/html-source/screens/K05-quest-complete.html`):
`Brilliant, Maya!` · `+15 coins` · `Mum will give it a thumbs-up soon.`
(hyphen-minus U+002D) · `Pip is doing a happy dance!` ·
`Pip needs 75 more coins to grow` · `175 of 250 coins` · `Next: Songbird` ·
`Yay! Back home`. All present, in order, no curly quotes / dashes / ellipsis.
Presence, order, colours, radii, shadows, icon choice (lock, coin), alignment
(20 px gutters; card / CTA / bar share x 20–370; pill and bubble centred on
x 195), no overflow/clipping/ellipsis in either theme. No uniform vertical
shift: every measured y matches exactly.

## Numbered deviations

1. Hero Pip artwork differs (band 2: light 8.47%, dark 6.06%). Design: v1
   `pip-stage-3.svg` egg (tall oval, 3 hair strokes, green wings). App: Maya's
   own `PipAvatar` (Mochi · sunny · stage 3, round chick, happy mood, −8° tilt,
   218 slot, same size/position as the design slot). Fix: none — orchestrator
   PIP rule mandates `PipAvatar` from the DB and forbids v1 `pip_stage_*.svg`
   in product screens.
2. Mini Pip in the growth card differs (same cause as §1, ~32 px slot):
   design egg thumbnail vs app `PipAvatar` 32. Fix: none — same PIP mandate.
3. Status-bar clock: design `9:41` vs app `02:37` (light) / `02:39` (dark);
   signal/wifi/battery glyphs also OS-drawn. Fix: none — `NestStatusBar`
   reserves height only; status-bar pixels are ignored in UI checks.
4. Bottom edge below the kid bar: design shows a meadow-green strip (light
   approx `(204,237,192)`, dark `(30,65,56)`) with the home pill on it; app shows the
   bar surface to the physical edge (light white, dark `(31,28,46)` = surface;
   the grey pixel at y835 is the OS home-indicator glyph). Band 7 (light
   6.34%, dark 4.44%) is this strip + the OS glyph. Fix: none — BOTTOM EDGE
   owner rule overrides the designs; the app is correct and the check would
   FAIL a screen that showed the design's strip.

No other deviation found: burst coins/sparkles positions, hero/pill/sub/bubble/
card/count-row/progress/bar/CTA geometry, kid sky gradient + meadow hills
position, dark-mode tints, and copy all match within ±2 px (measured rects
above are ±0).

No code edited in this stage.

VERDICT: PASS
