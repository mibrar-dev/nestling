
## UPDATE (14:28, orchestrator QA of cmp_light_1, 1.83%)
The quest hero icon must be the design's glyph. For the 'bed' quest it is the flat bed (shared `NestIcons.questBed`, added in batch 5 from the P09 HTML), not the current bed-with-figure icon. Map each quest's icon key to the same design glyphs P09 uses (questBed / questDishes / questHoover / questBins …). Everything else matches; the ticked state is runtime.

## UPDATE (15:08) — icons per audience (shared/audience_glyphs)
Kid screens use the KID design glyphs via questIconFor/rewardIconFor(audience: kid). This is being added on main. Not a finding meanwhile; switch once main has it.

## UPDATE (16:38) — iteration 4
- K04-BUG-5 (stroke 2 vs 1.8): ORCHESTRATOR DECISION, ACCEPT the shared kid glyph at 2 (one consistent kid set; invisible at 64 px). Close the proof as accepted. Do not ship a variant.
- Add the ICONS audience regression test: the quest-detail hero for each seeded quest key resolves through questIconFor(audience: kid) and differs from the parent glyph where the designs differ.
Nothing else to change.
