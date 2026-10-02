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

## QA of cmp_light_3 (4.87%, was 5.51%) — iteration 4 targets (last iteration — be exact)
1. STILL OPEN: children order. The app shows Leo, Maya; the design and the CHILD ORDER rule require Maya, then Leo (order added). Fix in this feature's repository (order by creation/rowid) and add a test that asserts Maya is first.
2. "Add a child" card top ≈ y 399 (app ≈ 407): the gap between the kid-card row and this card must be 12 px as in the HTML.
3. Inside the card the rows drift down cumulatively (≈ +4 at Nickname, +8 at the field, +13 at the chips, +20 at Avatar colour). Take every vertical gap from the HTML (`.field` label→input gap, input height 52, section gaps) — likely the label-to-field gap and the field height are each a few px too big. Targets: field top ≈ 471, chips row centre ≈ 569, colour row centre ≈ 637, helper text ≈ 674.

## QA of cmp_light_4 (3.78%) — iteration 5 (final polish)
- DONE & verified: Maya first; header; kid cards; "Add a child" card top. Keep them.
- Remaining drift inside the card: Age-band chips row centre is ≈ +5 px low (app ≈ 574 vs design ≈ 569) and the Avatar-colour row ≈ +12 px low (app ≈ 649 vs ≈ 637), helper text ≈ +12 px. Cause: chip height and the gap below the chips. Take the chip height (design ≈ 32 px), the chip-row→"Avatar colour" label gap and the label→swatch gap exactly from P05-add-children.html / components.css. Swatch diameter 44 with 8 px gaps — match.
- Test stage: if your FAIL is only a shared/skipped item, write that explicitly in 3_test.md and mark PASS when every P05-owned test passes.
