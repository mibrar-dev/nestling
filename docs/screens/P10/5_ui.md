# P10 · Quest library (`/quests`) — Stage 5 UI check (iteration 4)

Route `/quests`, parent, maya, seed demo, simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB.
Designs `design/screens/light|dark/P10-quest-library.png` (1170×2532 @3x = 390×844 logical).
Shots `docs/screens/P10/ui/app_light_4.png`, `app_dark_4.png`; sheets `cmp_light_4.png`, `cmp_dark_4.png`.
ORCHESTRATOR_NOTES 09:46 + 10:00 + 12:17 + 13:42 applied (all shared fixes merged
to this branch before the build: §1 semantics, §9 54-tall field, §10 centred hint,
batch4 geometry + tab bar + creation order).

Mean diff: light 1.40% (bands 1.57/1.25/2.33/1.05/0.93/0.87/0.72/2.50);
dark 1.35% (bands 1.57/1.26/2.28/0.92/0.79/0.74/0.65/2.61).
Down from 3.33%/3.16% — the iteration-3 hint defect is fixed.

Status-bar glyphs ignored (OS draws real bar). Bottom edge: tab-bar surface runs to the
physical edge in both themes (owner rule) — correct. `Active (12)` from DB — correct.
No Pip on this screen. Copy/order vs HTML source all match (middot `·`, `+ Add`).
6th card peeks under the tab bar as in the design.

Measured y, design vs app, logical px (@3x ÷ 3; tolerance ±2):
- screen title top: 61.7 vs 62.0 (+0.3)
- search field outer top: 181.0 vs 181.0 (0); hint ink centre 201.2 vs 201.2 (0, pin 200 ±1)
- `All` chip top: 227.0 vs 227.0 (0)
- card tops 1–5: 297.0/381.0/465.0/549.0/633.3 vs 297.3/381.3/465.3/549.3/633.3 (≤0.3)
- 6th-card peek / bar bottom edge: 717.3/727.0 both (0)
- row-1 title/meta text x: 85.0 vs 85.3/85.0; `+ Add` pill and `All` chip rects ≤0.3
- tab-bar active content y: 739.0–776.3 both (0)
Band 7 residual (2.5%) is the design's mock home-indicator pill (5550 dark px in the
design home zone vs 0 in the app shot — the physical indicator is OS-drawn, same
class of exclusion as the status bar) plus label rasterization; no app geometry differs.

Shapes, not just text: filter chips 44-high pills, search field 54-high with centred
icon + hint, cards r-m 16 with 40×40 r-m tinted tiles (tints kept in dark mode),
44-high `+ Add` pills (pill radius, 1.5px leaf border), segmented track + pill,
tab bar content at design y. Colours, radii, shadows, icons match in both themes.
20px gutters everywhere; nothing misaligned. No overflow/clipping/ellipsis faults.

Deviations: none.

VERDICT: PASS
