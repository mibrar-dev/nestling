# Orchestrator notes for P05 (mandatory)

## QA of cmp_light_1 (6.61%) — targets for iteration 2
1. BUG: the "Age band" chips (4–6, 7–9, 10–12, 13+) render stacked VERTICALLY and centred. Design: one horizontal row, left-aligned, 8 px gaps, wrapping only when the width can't fit (320 / text scale 1.3).
2. The existing-children cards (Maya 7–9, Leo 4–6 with edit pencils) must render above "Add a child" from the database. The orchestrator is adding a `SEED=onboarding_kids` state (shared fix, lands on main) — once it is merged (main is merged into your branch before each build), use it in the UI check; do not fake children.
3. Header ~16 px high is a SHARED issue being fixed on main — don't patch it locally.
4. Owner rules: bottom panel to the edge (correct now), perfect alignment.
