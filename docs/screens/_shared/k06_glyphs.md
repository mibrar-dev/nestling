Two more kid glyphs for K06 (Pip): copy them EXACTLY from design/html-source/screens/K06-pip.html.
1. Wardrobe "Sun hat": the design's sun-hat SVG (read-only reference: ../nestling-screens/K06/docs/screens/K06/6_bugs.md "ORCH item 2 residual" and ui/cmp_light_3.png). The app uses a look-alike. Add it as `NestIcons.wardrobeSunHat`.
2. Action button "Play": the design's play glyph (a clock-like ring with hands in the PNG; read the K06 HTML). The app uses a different circle icon. Add it as `NestIcons.kidPlay`. Check Feed and Bath against the HTML too, and add exact glyphs if they differ.
Do not change existing icons that other screens use. Tests: assets exist and render with the theme colour.
Report the names K06 must use. Do NOT edit feature code.
DONE = dart format clean, flutter analyze "No issues found!", full flutter test --timeout 120s green, docs/screens/_shared/k06_glyphs_REPORT.md, committed.
