# Orchestrator notes for P04 (mandatory)

## QA of cmp_light_1 (7.52%) — targets for iteration 2
1. BUG: "Delete everything anytime" row shows an EMPTY peach icon tile — the trash/bin icon is not rendering (wrong asset name or colour = background). It must show the red-ink bin glyph like the design, light + dark. Add a widget test that all four row icons find their SvgPicture/Icon.
2. Header block is ~16 px HIGH: back chevron, title and subtitle must match the design (390×844 logical): chevron centre ≈ y 73, title cap top ≈ y 112, subtitle ≈ y 161, shield badge centre ≈ y 229 (measure from design/screens/light/P04-privacy.png ÷3 and the HTML).
3. List rows: each row is ~1–2 px taller than the design so the list drifts; match row height and divider insets exactly from the HTML (row heights and the 1 px divider), so the "Optional: help improve" card top lands at ≈ y 528 and Continue at ≈ y 690.
4. Owner rules: bottom panel surface runs to the screen edge (currently correct); perfect alignment.

## UPDATE (orchestrator, 12:03) — overrides item 2 above
The ~16 px header offset is SHARED (P05 has the identical offset); a shared fix is in progress on main (branch shared/onboarding_header_and_seed). Do NOT move the back row / title locally in P04. Items 1 (missing bin icon) and 3 (row heights) are still P04's to fix.

## UPDATE (13:42) — shared assets in progress
`ic_trash.svg` / `NestIcons.trash`, the token-coloured privacy shield (dark mode) and the first-run settings row are being added on main by shared/shared_requests_batch1. Keep the reserved 40×40 peach tile + TODO for now; when main contains `NestIcons.trash` (it is merged into your branch before each build), use it with the design's red-ink colour. Fix everything else in your FIXES list in this iteration (row heights/alignment, review findings, bug findings).

## UPDATE (15:27) — iteration 5: the trash icon is on main
cmp_light_4 = 4.10%; orchestrator confirms the ONLY visible deviation left is the blank row-4 tile. `NestIcons.trash` (`app/assets/icons/ic_trash.svg`) is now merged into your branch: render it in the peach tile with the design's rust/red-ink colour (design pixels #BA562E), remove the TODO, un-skip [P04-2]/[P04-7] as the review asks, and fix the review's two findings. Also check dark mode uses the new `NestPrivacyShield` (token-coloured circle) from main.
