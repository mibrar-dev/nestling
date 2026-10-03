
## UPDATE (18:15, orchestrator QA of cmp_light_1, 1.21%)
1. Subtitles must render in FULL, as in the design: no early ellipsis. The trailing "Change ›" / "›" must take only its intrinsic width, and the subtitle column takes the rest (Expanded). Test at 390 that no RenderParagraph in these rows has didExceedMaxLines.
2. Quests row icon: the circled check (design HTML circle + check). Pocket money row icon: the coin asset (coin.svg), not the pound glyph. If a circled-check icon is missing in NestIcons, write SHARED_REQUEST with its SVG from the HTML.
3. PRONOUN (orchestrator decision): keep "Maya knows their code". There is no gender data (owner policy: children pick their Pip, no gender), so "their" is correct. Not a finding.
4. Quest counts ("4 Quests this week", "4 daily, 2 weekly") come from the DB, not the design: not findings.

## UPDATE (23:55) — known red test on main, NOT your finding
`test/core/family_time_test.dart` › 'kid_home completions are stamped with the family zone' fails since the date rolled to 4 Oct. It is a date-dependent test bug on main, being fixed by shared/family_time_test_fix. If it is the ONLY failing test in the full suite, treat the gate as green for this screen.
