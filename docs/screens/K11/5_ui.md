# K11 · Badges — stage 5 UI check (iteration 1)

Route `/badges` (feature `badges`, kid mode, child maya, seed demo).
Simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB (390×844, same as designs).
Designs: `design/screens/light/K11-badges.png`, `design/screens/dark/K11-badges.png`
(1170×2532 = 390×844 @3x; all numbers below logical px).
HTML source: `design/html-source/screens/K11-badges.html` (treated as exact).
App shots: `docs/screens/K11/ui/app_light_1.png`, `docs/screens/K11/ui/app_dark_1.png`
via `bash tools/screens/shot.sh $PWD/app /badges $PWD/docs/screens/K11/ui/app_…png … light|dark demo kid maya`
(absolute OUT path — the script `cd`s into `$APP_DIR`, so a relative OUT would resolve inside `app/`).
Compares: `docs/screens/K11/ui/cmp_light_1.png`, `docs/screens/K11/ui/cmp_dark_1.png`
via `python3 tools/screens/compare.py …`.
No code edited by this stage. No `ORCHESTRATOR_NOTES.md` exists (no mandatory overrides).
No Pip on this screen (PIP rule N/A). No coins/£ anywhere (jar-only rule holds).

## Mean diff

```
light: mean diff 3.39%
  band y-range  diff%
  0    0-105    1.59%   (status bar — OS-drawn, excluded)
  1    105-211  0.36%
  2    211-316  1.59%
  3    316-422  4.19%   (grid R2 — DB badge content)
  4    422-527  5.33%   (grid R2/R3 — DB badge content)
  5    527-633  9.19%   (grid R3 — DB 8 vs 9 + art)
  6    633-738  3.39%   (R3 tail + week top/dots)
  7    738-844  1.46%   (why-line + home-pill mock vs OS, excluded)

dark: mean diff 3.49%
  band y-range  diff%
  0    0-105    1.59%
  1    105-211  0.38%
  2    211-316  1.45%
  3    316-422  4.14%
  4    422-527  5.19%
  5    527-633  10.29%
  6    633-738  3.37%
  7    738-844  1.46%
```

Bands 3–5 carry the whole diff and are exactly the DB-driven badge cells
(see deviation 1). Bands 0 and 7 are chrome mocks vs OS (excluded).
Everything else is ≤1.6% (antialias + dash phase only).

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
| Grid R2 outer top (interior 358) | 355 (dashed) | 355 (dashed) | 0 (dash phase differs, see dev. 2) |
| Grid R3 outer top (interior 512) | ~517 (dashed) | ~517 (dashed) | 0 |
| Grid R3 bottom | 664…666 | 664…666 (left cols) | 0 |
| Week card outer top | 683…685 ink | 683…685 ink | 0 |
| Week white face bottom | 809 white → 810 meadow | 809 white → 810 meadow | 0 |
| Week dots (38 circle, y ~700) | 4 filled leaf + 3 empty | 4 filled leaf + 3 empty (green frac 0.29 vs 0.30) | 0 |
| Day letters `M T W T F S S` | y ~742, 14/18 | same | 0 |
| Why-line (2 lines, centred) | 780…786 + 800…806 | 780…786 + 800…806 | 0 |
| Side gutters | 20 (white 24…365) | 20 (white 24…364, 1 px antialias) | ≤1 (pass) |
| Grid gaps / week padding | 12 / 14+12 | same (gaps 18…19 px incl. borders, ≤1 diff) | pass |
| Meadow bottom | (204,237,192), runs to 844 | (204,237,192), runs to 844 | 0 |
| Dark colours sampled (surface/sky/meadow/leaf/medal) | — | identical (e.g. surface 31,28,46 both; leaf dot 60,201,138 both; sky 29,35,84 vs 30,36,85) | pass |

No uniform vertical shift: every top above matches at 0–1 px. No misalignment:
cards and bars share the same 20 px edges; 1 px diffs are corner-antialias
threshold only (R1 top ink 42…106 vs 41…106).

Copy (character-exact vs HTML):
title `My badges`; subtitle `Four shiny ones already. Pip is very impressed.`;
subs `Got it!` / `Keep going!` (with `!`); why-line
`4 happy days this week — Pip hasn’t stopped singing.` (em dash U+2014,
curly ’ U+2019 — verified in `happy_week_card.dart`; subtitle has no apostrophe
so no curly needed); `Bed maker ×7` (× U+00D7 comes from the DB title and renders
in both shots); day letters `M T W T F S S`. No overflow, clipping or ellipsis
anywhere; 2-line names wrap correctly (`Bed maker ×7`, `Tidy champion`);
week why-line wraps to 2 centred lines in both. Kid glyphs only; earned medals
keep own colours in dark mode. Radii (r-l 24), 3 px borders (solid earned +
`kidShadow`, dashed ink-2 todo with no shadow), medal 60×60 all match visually.

## Numbered deviations (element, design value, app value, fix)

1. Badge shelf content — DB-driven, excluded from the ±2 px rule (UI VERDICT RULE, DATA OVER MOCKS).
   Design: 9 badges — `First quest`, `Bed maker ×7`, `Kind helper`, `Bookworm`
   (earned) + `Bins out`, `Biscuit sitter`, `Tidy hero`, `Early bird`, `Plant waterer`
   (todo, each with its own muted medal art).
   App (demo seed, 8 rows): `First quest`, `Bed maker ×7`, `Kind helper`, `Bookworm`
   (earned — match) + `Tidy champion`, `Early bird`, `Super saver`, `Pet friend`.
   `Early bird` art matches (same id); `Tidy champion` / `Super saver` / `Pet friend`
   correctly fall back to the neutral `NestIcons.ribbon` (unknown ids never borrow
   another badge's art, per `1_plan.md` §a). R3C3 is empty meadow in the app
   (8 vs 9 — the `SizedBox.shrink` tail filler, plan §a). Grid geometry of the
   existing cards is still exact (table above).
   Fix: shared seed change in `docs/screens/K11/SHARED_REQUEST.md` (nine design
   badges; `Blocks: no`, `TODO(K11)` in code). No screen-code fix; do not hard-code
   design names (database wins).
2. Dashed todo borders — dash phase differs (e.g. at x195 y355 design hits a dash,
   app hits a gap). Card rects, 3 px width, ink-2 colour, r24 and no-shadow all
   match; CSS vs `NestDashedBorder` phase is unspecified. Informational; no fix.
3. Status-bar time/icons — design `9:41` + gallery icons; app `02:26`/`02:27` +
   simulator icons. Excluded by orchestrator STATUS BAR rule (`NestStatusBar`
   reserves 47 px; the OS draws glyphs). No fix (correct as built).
4. Home-indicator pill — design shows the 134×5 mock pill at y825…829; the app
   paints nothing there (`NestHomeIndicator` reserve only, `2b_build_ui.md` defect 1;
   the OS draws the real pill, `simctl io screenshot` does not capture it).
   Meadow correctly runs to the physical edge in both (BOTTOM EDGE owner rule holds;
   no strip under any bar — K11 has no bottom bar). No fix.
5. Back-chevron raster — same rect (x43…51, y66…83 vs 67…82), but 62 vs 46 dark
   pixels (stroke antialias threshold; design SVG 2.5 vs Flutter icon). Visually
   identical in side-by-side. No fix.

What was checked and passed: presence/order (title → subtitle → 3-col grid →
week card), spacing (±2 px table above), sizes (cells ≈108.67 via `Expanded`,
medal 60, dots 38→33 @320 via `LayoutBuilder`, paddings 20/12/14/10/4),
alignment (20 px gutters, shared edges), colours (tokens only — 6-point sample
identical light+dark), radii/shadows (r24, `sh-kid` earned only), icon choice
(design art for known ids, ribbon fallback for legacy), no overflow/clipping,
dark-mode flips per tokens with medals/dots keeping own colours.

VERDICT: PASS
