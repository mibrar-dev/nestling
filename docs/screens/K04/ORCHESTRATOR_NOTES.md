
## UPDATE (14:28, orchestrator QA of cmp_light_1, 1.83%)
The quest hero icon must be the design's glyph. For the 'bed' quest it is the flat bed (shared `NestIcons.questBed`, added in batch 5 from the P09 HTML), not the current bed-with-figure icon. Map each quest's icon key to the same design glyphs P09 uses (questBed / questDishes / questHoover / questBins …). Everything else matches; the ticked state is runtime.

## UPDATE (15:08) — icons per audience (shared/audience_glyphs)
Kid screens use the KID design glyphs via questIconFor/rewardIconFor(audience: kid). This is being added on main. Not a finding meanwhile; switch once main has it.
