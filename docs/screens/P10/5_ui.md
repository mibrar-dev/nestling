# P10 · Quest library (`/quests`) — Stage 5 UI check (iteration 2)

Route `/quests`, parent, maya, seed demo, simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB.
Designs `design/screens/light|dark/P10-quest-library.png` (1170×2532 @3x = 390×844 logical).
Shots `docs/screens/P10/ui/app_light_2.png`, `app_dark_2.png`; sheets `cmp_light_2.png`, `cmp_dark_2.png`.
HTML source `design/html-source/screens/P10-quest-library.html` (copy reference).
ORCHESTRATOR_NOTES (09:46 + 10:00) applied: shared items (search prefix, segmented 52/44,
tab-bar content pos.) are not P10 findings; P10-local row alignment verified below.

Mean diff: light 3.33% (bands 1.57/1.63/3.98/4.87/4.18/4.13/3.78/2.50);
dark 3.15% (bands 1.55/1.55/3.82/4.57/3.84/3.80/3.49/2.61).
Down from 6.47%/6.27% in iteration 1. Residual is font rasterization + ≤2px edges.

Status-bar glyphs ignored (OS draws real bar). Bottom edge: tab-bar surface runs to the
physical edge in both themes (owner rule) — correct, not a deviation.
`Active (12)` from DB — correct (data over mocks). No Pip on this screen.
Copy char-for-char vs HTML: `Quests`, `Active (12)`/`Ideas` (Ideas selected),
`Search ideas`, chips `All, Bedroom, Kitchen, Outdoors, …`, rows in design order with
`{coins} coins · Ages {age}+ · {Category}` (middot U+00B7), `+ Add` buttons — all match.
6th card peeks under the tab bar exactly as in the design.

Measured y, design vs app, logical px (measured @3x ÷ 3; tolerance ±2):
- screen title top (`Quests`): 61.7 vs 62.0 (+0.3)
- segmented track top: 100.0 vs 100.0 (0)
- search field outer top: 174.0 vs 174.0 (0); bottom 226.0 vs 224.0 (−2.0)
- category `All` chip top/bottom: 227.0/266.3 vs 225.0/266.3 (−2.0/0)
- card tops 1–5: 297.0/381.0/465.0/549.0/633.3 vs 295.3/379.3/463.3/547.3/631.3 (−1.7…−2.0)
- row-1 title/meta text x: 85.0 vs 85.3/85.0 (+0.3/0); title top 310.3 vs 308.3 (−2.0)
- row-1 `+ Add` pill x/y/w/h: 287.0/303.0/70.7/43.7 vs 286.7/301.0/71.0/43.7 (≤2.0)
- `All` chip x/w: 20.0/47.7 vs 20.0/48.0 (0); gutters 20 both sides, card right 357.7 both
- tab-bar active green content y: 739.0–776.3 both (0); bar bottom edge 727.0 both (0)
Every element is within ±2px. No uniform shift exceeding tolerance (max −2.0, boundary incl.).

Shapes, not just text: filter chips 44-high pills (border 1.5 leaf when selected);
search field + icon slot match (small 24px icon, hint at design x); cards r-m 16,
40×40 r-m tinted tiles (tints kept in dark mode), `+ Add` 44-high pills (pill radius,
1.5px leaf border, `0 14px` padding, leaf-tint/leaf-ink); segmented track + selected
pill; tab bar icons/labels at design y. Colours, radii, shadows, icons all match in
both themes. No overflow/clipping/ellipsis faults. No misalignment.

Deviations: none. Iteration-1 findings (centered row text; oversized search icon box)
are fixed: rows are left-aligned at card x+64 and the search geometry matches.

VERDICT: PASS
