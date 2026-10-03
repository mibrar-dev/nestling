# P10 · Quest library (`/quests`) — Stage 5 UI check (iteration 1)

Route `/quests`, mode parent, child maya, seed demo, simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB.
Design: `design/screens/light|dark/P10-quest-library.png` (1170×2532 @3x = 390×844 logical).
App shots: `docs/screens/P10/ui/app_light_1.png`, `docs/screens/P10/ui/app_dark_1.png`.
Compare sheets: `docs/screens/P10/ui/cmp_light_1.png`, `docs/screens/P10/ui/cmp_dark_1.png`.

Note: the first dark capture landed on the wrong route (kid home). Retaken with the
same command; the file now shows `/quests` in dark theme.

Mean diff (compare.py, design vs app):
- light: 6.47% (bands: 0: 1.65, 1: 3.40, 2: 7.46, 3: 8.80, 4: 7.61, 5: 8.24, 6: 8.62, 7: 5.99)
- dark: 6.27% (bands: 0: 1.65, 1: 3.37, 2: 7.52, 3: 8.35, 4: 7.29, 5: 7.82, 6: 8.33, 7: 5.81)

Status-bar time/glyph differences ignored per orchestrator (NestStatusBar reserves height only).
Bottom edge: app runs the tab-bar surface to the physical edge in both themes — correct
per OWNER RULE (overrides the design's tinted strip). Not a deviation.
`Active (12)` matches the seeded DB (12) — correct per DATA OVER MOCKS.
Copy/order verified against `design/html-source/screens/P10-quest-library.html`:
title `Quests`, segmented `Active (12)` / `Ideas` (Ideas selected), hint `Search ideas`,
chips `All, Bedroom, Kitchen, Outdoors, …` (All selected), rows in design order with
`{coins} coins · Ages {age}+ · {Category}` meta (middot U+00B7) and `+ Add` buttons.
No Pip on this screen (PIP N/A). No overflow, clipping, or ellipsis faults on screen.
Dark-mode tiles stay tinted and `+ Add` stays leaf-tint/leaf-ink — correct.

## Deviations

1. Idea-row title + meta are horizontally centered; design is left-aligned (MAJOR, both themes).
   - Design: `.trow .main{flex:1 min-width:0}`, `.nm`/`.mt` default start-aligned —
     text block starts at card x = 12 (pad) + 40 (tile) + 12 (gap) = 64 from card
     left edge, both lines left edges equal.
   - App (`app_light_1.png`, `app_dark_1.png`, every `.trow`): `Make your bed` /
     `5 coins · Ages 4+ · Bedroom` (and all rows below) are centered in the middle
     column instead of starting at the tile gap. Visible in the diff sheets as doubled
     title/meta ghosts in bands 2–6 (≈7–9% band diff).
   - Fix: `app/lib/features/quests/presentation/widgets/quest_idea_row.dart:71-93` —
     the `Expanded > Column` defaults to `CrossAxisAlignment.center`. Add
     `crossAxisAlignment: CrossAxisAlignment.start` (texts default to start alignment;
     keep `maxLines: 1, overflow: ellipsis`).

2. Search field icon box too wide; hint text starts right of design (MAJOR, both themes).
   - Design: `.search{min-height:52px; padding:4px 16px; gap:10px}`, icon svg 24px —
     text starts at 16 (left pad) + 24 (icon) + 10 (gap) = 50 from field left edge.
   - App: `NestTextField` uses Material `InputDecoration.prefixIcon` with the default
     48px-min icon box, so the magnifier visual sits in a wider slot and `Search ideas`
     starts visibly right of the design position (red ghosting around search in both
     compare sheets; icon also renders heavier/larger than the 24px design icon).
     Exceeds the ±2px tolerance by ~10px.
   - Fix: constrain the prefix icon to the design geometry — e.g. pass
     `prefixIconConstraints: BoxConstraints(minWidth: 50, minHeight: 44)` (or wrap the
     24px `NestIcon` in left-16/right-10 padding) in `NestTextField` usage for this
     screen or in the shared field so icon = 24, gap = 10, text x = 50. Shared-file
     change must go via SHARED_REQUEST (screen agent may not edit `core/`).

No other visible deviations: title, segmented (52 high), 44-high filter chips with
20px bleed, 40×40 r-m icon tiles, 44-high `+ Add` pills (pill radius, 1.5px leaf border,
`0 14px` padding), card r-m 16 with sh-1, 20px gutters, 16px rhythm, tab bar with
Quests active — all match within tolerance in both themes.

VERDICT: FAIL
