K09 My jar history glyphs (read-only: ../nestling-screens/K09/docs/screens/K09/5_ui.md deviations 1–2, 4).
1. Add the design's pocket-money "coin slot" glyph from design/html-source/screens/K09-jar.html:85 (circle r8, `M12 8v8`, `M9.5 9.5h5`, `M9.5 14.5h5`) as `NestIcons.jarPocketMoney`.
2. Kid quest glyphs: K09-jar.html:90 draws "bins" as a lidded bin (`M6 3h12l-2 5H8Z` + body). Compare it with the kid set's bins in `questIconFor(.., audience: kid)` (from K03/K04 HTML). If they match, nothing to do. If the kid set's bins differs from K09's, the kid designs disagree: use K09's (the screen where bins appears most prominently) for the kid set, and re-check K03/K04's rendered quests still look right. Report it.
3. The gift ("Birthday money") row glyph: add it from K09-jar.html if the shared set lacks it, as `NestIcons.jarGift`.
Tests: the assets exist and render; questIconFor('bins', kid) returns the chosen glyph.
Do NOT edit feature code. Report what K09 must call.
DONE = dart format clean, flutter analyze "No issues found!", full flutter test --timeout 120s green, docs/screens/_shared/jar_glyphs_REPORT.md, committed.
