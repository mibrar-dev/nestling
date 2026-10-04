Reward icons must be the designs' exact glyphs (K08 kid Reward shop + P14 parent Rewards manager).

READ (read-only): ../nestling-screens/K08/docs/screens/K08/5_ui.md deviations 1–3 and ui/cmp_light_1.png; design/html-source/screens/K08-*.html and P14-*.html (the inline SVGs per reward); design/screens/*/K08-*.png and P14-*.png.
- App today: Baking together shows a chef-hat/cake look-alike (design: the design's own baking glyph); Park café shows a cup (design: the design's café glyph); Choose dinner's pizza differs in detail.
- Each reward row stores an icon key in the DB (rewards.icon: tv, film, moon, cake, coffee, plate …).
DO:
1. For every reward icon key used by the seed, add the EXACT SVG from the HTML (K08 and P14 must agree; if they differ, report it and use the kid design for K08's key) to app/assets/icons, mapped in ONE shared map: rewardIconFor(key) in core/design_system.
2. P14 (merged) and K08 (in progress) must both use that map. You MAY update P14's feature code (app/lib/features/rewards/**) to call rewardIconFor. Do NOT edit K08's branch.
3. Tests: every seeded reward key resolves to an asset that exists; the map is the single source; P14's geometry tests stay green.
DONE = dart format clean, flutter analyze "No issues found!", full flutter test --timeout 120s green, docs/screens/_shared/reward_glyphs_REPORT.md (what K08 must call), committed.
