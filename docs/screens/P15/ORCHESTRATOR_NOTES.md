
## UPDATE (18:15, orchestrator QA of cmp_light_1, 1.21%)
1. Subtitles must render in FULL, as in the design: no early ellipsis. The trailing "Change ›" / "›" must take only its intrinsic width, and the subtitle column takes the rest (Expanded). Test at 390 that no RenderParagraph in these rows has didExceedMaxLines.
2. Quests row icon: the circled check (design HTML circle + check). Pocket money row icon: the coin asset (coin.svg), not the pound glyph. If a circled-check icon is missing in NestIcons, write SHARED_REQUEST with its SVG from the HTML.
3. PRONOUN (orchestrator decision): keep "Maya knows their code". There is no gender data (owner policy: children pick their Pip, no gender), so "their" is correct. Not a finding.
4. Quest counts ("4 Quests this week", "4 daily, 2 weekly") come from the DB, not the design: not findings.
