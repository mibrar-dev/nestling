# Orchestrator notes for P05 (mandatory)

## QA of cmp_light_1 (6.61%) — targets for iteration 2
1. BUG: the "Age band" chips (4–6, 7–9, 10–12, 13+) render stacked VERTICALLY and centred. Design: one horizontal row, left-aligned, 8 px gaps, wrapping only when the width can't fit (320 / text scale 1.3).
2. The existing-children cards (Maya 7–9, Leo 4–6 with edit pencils) must render above "Add a child" from the database. The orchestrator is adding a `SEED=onboarding_kids` state (shared fix, lands on main) — once it is merged (main is merged into your branch before each build), use it in the UI check; do not fake children.
3. Header ~16 px high is a SHARED issue being fixed on main — don't patch it locally.
4. Owner rules: bottom panel to the edge (correct now), perfect alignment.

## UPDATE (12:43) — seed override for the UI check (mandatory)
`SEED=onboarding_kids` is now on main (merged into your branch). In stage 5, run shot.sh with seed `onboarding_kids` instead of `fresh` (the stage brief was generated before this change): e.g. `bash tools/screens/shot.sh $PWD/app /add-children docs/screens/P05/ui/app_light_<it>.png <SIM> light onboarding_kids parent maya`. The Maya and Leo cards must then render from the database. The shared header fix (compact nav 60 px) is also merged — re-measure; do not patch it locally.

## QA of cmp_light_2 (5.51%) — targets for iteration 3 (mandatory)
1. The kid-card GridView inherits the MediaQuery padding (~47 px top) — set `padding: EdgeInsets.zero` (or MediaQuery.removePadding) so the cards sit 16 px under the subtitle and "Add a child" card top ≈ y 399 (390×844) as in the design. (Your UI stage found this — fix it.)
2. ORDER RULE (orchestrator ruling, applies app-wide): children are listed in the order they were added (Maya first, then Leo), never alphabetically. In this feature's repository order by the child's creation time / insertion order; if the children table lacks a usable column, file it in SHARED_REQUEST.md and order by rowid meanwhile.
3. Copy: curly apostrophe "Who’s in your nest?" (U+2019) exactly as the design/HTML.
4. Nickname field: the design shows the field focused (green 2 px ring) — that is the focused state; the unfocused launch state is fine. Add a widget test for the focused ring colour = leaf token.
