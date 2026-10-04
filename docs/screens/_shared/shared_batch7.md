Shared batch 7 (from K06 Pip). READ FIRST (read-only): ../nestling-screens/K06/docs/screens/K06/SHARED_REQUEST.md §1, §2, §3, §5, §6, plus design/html-source/screens/K06-pip.html and design/screens/*/K06-pip.png.

1. WARDROBE GLYPHS (§5): add the design's exact Scarf and Wellies SVGs from K06-pip.html to app/assets/icons and NestIcons, under new names (e.g. `wardrobeScarf`, `wardrobeWellies`). Do not change existing icons other screens use. Report the names.
2. WARDROBE PRICES (§6): Wellies and Crown are priced in only ONE design (K06-pip.html). The seed (app/lib/core/data/seed.dart ~605-612) says Wellies 40 / Crown 120, but the design says 30 / 60. The seed mirrors the designs, so set Maya's (and Leo's) wellies = 30 and crown = 60, unless another design shows a different price for these (grep design/html-source); then report it. Update any merged test that pinned 40/120 only if it was pinning the seed.
3. NestPetStage K06 slot (§1): K06 needs its pet slot (read §1 for the measured numbers). Add the parameters the request asks for, the same way K03's explicit mode works. Defaults are unchanged and K03 must not move: run K03's geometry tests.
4. NestKidButton third row (§2): add an optional trailing/third row (e.g. a cost chip under the label), per the request and the K06 HTML. Defaults are unchanged.
5. Dashed border (§3): add a small shared `NestDashedBorder` (or a decoration) matching the HTML's dashed style, 3 px ink, dash/gap per the CSS, honouring the card radius. Report which local dashed code K06 can delete.
Do NOT edit feature code. The report must say exactly what K06 must switch to.
DONE = dart format clean, flutter analyze "No issues found!", full flutter test green (--timeout 120s), docs/screens/_shared/shared_batch7_REPORT.md, committed.
