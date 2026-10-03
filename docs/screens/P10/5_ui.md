# P10 · Quest library (`/quests`) — Stage 5 UI check (iteration 3)

Route `/quests`, parent, maya, seed demo, simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB.
Designs `design/screens/light|dark/P10-quest-library.png` (1170×2532 @3x = 390×844 logical).
Shots `docs/screens/P10/ui/app_light_3.png`, `app_dark_3.png`; sheets `cmp_light_3.png`, `cmp_dark_3.png`.
ORCHESTRATOR_NOTES 09:46 + 10:00 + 12:17 applied (shared items are not P10 findings;
hint-centre pin: field 173–227, centre 200 ±1).

Mean diff: light 3.33% (bands 1.58/1.63/3.98/4.87/4.18/4.13/3.78/2.50);
dark 3.16% (bands 1.58/1.55/3.82/4.57/3.84/3.80/3.49/2.61) — unchanged from iteration 2.

Status-bar glyphs ignored (OS draws real bar). Bottom edge: tab-bar surface runs to the
physical edge in both themes (owner rule) — correct. `Active (12)` from DB — correct.
No Pip on this screen. Copy/order vs HTML source all match (middot `·`, `+ Add`).
6th card peeks under the tab bar as in the design.

Measured y, design vs app, logical px (@3x ÷ 3; tolerance ±2):
- screen title top: 61.7 vs 62.0 (+0.3)
- segmented track top: 100.0 vs 100.0 (0)
- search field outer top: 174.0 vs 174.0 (0)
- row-1 title/meta text x: 85.0 vs 85.3/85.0 (+0.3/0)
- card tops 1–5: 297.0/381.0/465.0/549.0/633.3 vs 295.3/379.3/463.3/547.3/631.3 (−1.7…−2.0)
- `+ Add` pill 1 x/y/w/h: 287.0/303.0/70.7/43.7 vs 286.7/301.0/71.0/43.7 (≤2.0)
- `All` chip x: 20.0 both; tab-bar active content y 739.0–776.3 both (0)
All P10-local elements are within ±2px.

## Deviations

1. Search hint text floats ~11 px too high in the field (MAJOR, both themes — shared cause).
   - Design: field ring spans y 173–227 (centre 200); hint ink centre measured 201.2.
     Icon is centred on the field in both (orchestrator 12:17).
   - App (`app_light_3.png`): field top 174.0 matches, but hint ink spans 183.0–195.0,
     centre 190.2 — 11.0 px above the design centre. Visible in both diff sheets as a
     doubled `Search ideas` line (band 1 would otherwise be ~0).
   - Cause is inside shared `NestTextField.search` (tight 44px slot + hint painted at
     the top of the line box; see SHARED_REQUEST §10 for the widget-tree measurement).
     RULES §1 forbids a screen agent from editing `core/`, and orchestrator 10:00
     forbids hacking it locally — no P10-local fix exists.
   - Fix (shared): give the editable the 44 px box (contentPadding vertical
     (44−24)/2 = 10, strut, or fill the slot so TextAlignVertical.center works);
     already filed as SHARED_REQUEST §10 with red proof
     (`the hint is centred in the field, not floated to the top`, pins 200 ±1).
     The residual chip-row (−2.0) and card-top (−1.7…−2.0) offsets follow the short
     field (§9, 52 vs 54 tall) and compose with this fix.

VERDICT: FAIL
