# K11 · Badges — stage 5 UI check (iteration 3)

Route `/badges` (feature `badges`, kid mode, child maya, seed demo).
Simulator 604697A9-11DA-462F-9837-396E9CA2493A (390×844, same as designs).
Designs: `design/screens/light/K11-badges.png`, `design/screens/dark/K11-badges.png`
(1170×2532 = 390×844 @3x; all numbers below logical px).
HTML source: `design/html-source/screens/K11-badges.html` (treated as exact).
App shots: `docs/screens/K11/ui/app_light_3.png`, `docs/screens/K11/ui/app_dark_3.png`
via `bash tools/screens/shot.sh $PWD/app /badges $PWD/docs/screens/K11/ui/app_…_3.png … light|dark demo kid maya`
(absolute OUT path — the script `cd`s into `$APP_DIR`, so a relative OUT would resolve inside `app/`).
Compares: `docs/screens/K11/ui/cmp_light_3.png`, `docs/screens/K11/ui/cmp_dark_3.png`
via `python3 tools/screens/compare.py …`.
No code edited by this stage. `ORCHESTRATOR_NOTES.md` exists — all items addressed below.
No Pip on this screen (PIP rule N/A). No coins/£ anywhere (jar-only rule holds).

## Mean diff

```
light: mean diff 2.29%
  band y-range  diff%
  0    0-105    1.59%   (status bar — OS-drawn, excluded)
  1    105-211  0.36%
  2    211-316  1.59%
  3    316-422  3.23%
  4    422-527  3.22%
  5    527-633  3.65%
  6    633-738  2.37%
  7    738-844  2.29%   (OS home pill below the gallery mock, excluded — see dev. 2)

dark: mean diff 1.99%
  band y-range  diff%
  0    0-105    1.61%
  1    105-211  0.38%
  2    211-316  1.45%
  3    316-422  2.61%
  4    422-527  3.11%
  5    527-633  2.74%
  6    633-738  2.41%
  7    738-844  1.57%
```

Same as iteration 2 within run-to-run variance (2.30%/1.98%). Bands 3–5 hold only
border/antialias rendering diffs (dash phase, 1 px stroke raster); band 7 is the
OS home pill (excluded).

## Measured geometry — design vs app (light, logical px; dark uses identical layout code, theme only flips colours)

Measured with PIL on full-res PNGs (3×3 mean → 390×844), not eyeballed.
Outer card tops include the 3 px ink border; white interiors start 3 px lower.

| Element | Design | App | Δ |
|---|---|---|---|
| Title `My badges` line box (plan §0: 107…141) | glyphs 113…137 | glyphs 113…137 | 0 |
| Subtitle `.kcap` line (157…177) | glyphs 162…173 | glyphs 162…173 | 0 |
| Back box / lock box (`.krow-top` 47…107) | x 20…76 / 314…370, y 47…103 | same | 0 |
| Back chevron glyph | x 43…51, y 66…83 | x 43…51, y 67…82 | ≤1 (pass) |
| Lock glyph | x 333…350, y 65…84 | x 333…350, y 65…84 | 0 |
| Grid R1 outer top | 193…195 ink | 193…195 ink | 0 |
| Grid R1 bottom | 340…342 ink | 340…342 ink | 0 |
| Grid R2 outer top (interior 358) | 355 (dashed) | 355 (dashed) | 0 (dash phase differs, see dev. 3) |
| Grid R3 outer top (interior 512) | ~517 (dashed) | ~517 (dashed) | 0 |
| Grid R3 bottom | 664…666 | 664…666 | 0 |
| Week card outer top | 683…685 ink | 683…685 ink | 0 |
| Week white face bottom | 809 white → 810 meadow | 809 white → 810 meadow | 0 |
| Week dots (38 circle, y ~700) | 4 filled leaf + 3 empty | 4 filled leaf + 3 empty | 0 |
| Day letters `M T W T F S S` | y ~742, 14/18 | same | 0 |
| Why-line (2 lines, centred) | 780…786 + 800…806 | same ±1 px antialias | ≤1 (pass) |
| Side gutters | 20 (week white 24…365) | 20 (week white 24…364, 1 px antialias) | ≤1 (pass) |
| Grid gaps / week padding | 12 / 14+12 | same | pass |
| Meadow (x=100, y=840) | (204,237,192) to edge | (204,237,192) to edge | 0 |
| Dark colours sampled (surface/sky/leaf/medal) | — | identical (surface 31,28,46; sky 29,35,84; leaf dot 60,201,138 both) | pass |

No uniform vertical shift: every content top above matches at 0–1 px. No
misalignment: cards and bars share the same 20 px edges. SHAPES check (owner
rule): card background/border rects match, not just text.

Copy (character-exact vs HTML): title `My badges`; subtitle
`Four shiny ones already. Pip is very impressed.`; subs `Got it!` / `Keep going!`;
all nine names incl. `Bed maker ×7` (× U+00D7); why-line
`4 happy days this week — Pip hasn’t stopped singing.` (em dash U+2014, curly ’
U+2019); day letters `M T W T F S S`. Earned set = First quest / Bed maker ×7 /
Kind helper / Bookworm (solid + `Got it!`), matching the seed. No overflow,
clipping or ellipsis; radii r-l 24, 3 px borders, medal 60×60, dots 38.

## Locked-medal art verification (ORCHESTRATOR_NOTES 06:55 — mandatory)

Build iteration 3 implemented the duplicate-attribute ruling; this stage verifies
with zoomed crops of the locked Bins-out medal (R2C2), design vs app, both themes
(all four crops read with the file reader — visually identical: dark dashed ring,
muted ribbon at 40%, grey bin glyph; dark theme shows the light ring on the dark
tile in both):

- Dashed ring stroke: darkest pixels on the r20 circle = (30,27,58) design vs
  (30,27,58) app in light; ink in dark too — NOT #6E6A8A. Matches the HTML-first-
  attribute ruling (ink 3 px, dasharray 5 4).
- Ribbon (fill + 3 px ink stroke at 0.4 together): fill centre (585, 1150 px) =
  (197,195,208) design vs (197,195,208) app in light; (63,59,83) vs (63,59,83)
  in dark — exact. (Off-centre edge samples differ by ~35 levels purely from 1 px
  stroke rasterization at the trapezoid edge — antialias, not a colour error.)
- Glyph strokes remain the muted grey per design in both themes (crops match).

Remaining ORCHESTRATOR_NOTES items: nine-badge seed — DONE on main and visible
(all nine names + per-id art match, R3 full, 4 earned / 5 todo); `TODO(K11)`
removal and K11-BUG-1 (clamp happyDays 0…7) / K11-BUG-2 (no hard-coded 'maya'
fallback) are build-stage code fixes, out of scope for a no-code UI stage and not
visible in this seeded shot (stored values 4/3 render correctly).

## Numbered deviations (element, design value, app value, fix)

1. Status-bar time/icons — design `9:41` + gallery icons; app `07:25`/`07:26` +
   simulator icons. Excluded by orchestrator STATUS BAR rule (`NestStatusBar`
   reserves 47 px; the OS draws glyphs). No fix (correct as built).
2. Home-indicator pill — design gallery mock 134×5 at y825…829; app shows the
   OS-drawn pill at y831…835 (grey), 6 px lower. The screen paints nothing in
   the 34 px reserve (`badges_view.dart:109-114`, verified untouched). Pill
   position/colour is simulator OS chrome captured by `simctl io screenshot`
   (iteration 1's UDID captured none at all) — not screen code. Excluded like
   status-bar glyphs. Meadow correctly runs to the physical edge around it
   (BOTTOM EDGE owner rule holds; K11 has no bottom bar). No fix.
3. Dashed todo borders + medal inner dashed circles — dash phase differs (e.g. at
   x195 y355 design hits a dash, app hits a gap). Card rects, 3 px width, ink
   colour (verified above), r24 and no-shadow all match; CSS vs
   `NestDashedBorder` phase is unspecified. Informational; no fix.
4. Back-chevron raster — same rect (x43…51, y66…83 vs 67…82), but 62 vs 46 dark
   pixels (stroke antialias threshold; design SVG 2.5 vs Flutter icon). Visually
   identical side-by-side. No fix.

What was checked and passed: presence/order (title → subtitle → 3-col grid →
week card), spacing (±2 px table above), sizes (cells ≈108.67 via `Expanded`,
medal 60, dots 38, paddings 20/12/14/10/4), alignment (20 px gutters, shared
edges), colours (tokens only — sampled identical light+dark incl. locked-medal
ring/ribbon), radii/shadows (r24, `sh-kid` earned only), icon choice (per-id
design art both states and themes), no overflow/clipping, dark-mode flips per
tokens with medals/dots keeping own colours.

VERDICT: PASS
