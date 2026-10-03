
## UPDATE (19:48, orchestrator QA of cmp_light_1, 7.44%) — iteration 2 targets
1. SCRIM: the modal scrim must cover the WHOLE screen, including the status-bar area and the header ("Pocket money" + owed pill), as in the design: the header is dimmed. Right now the top ≈ 150 px stays bright. Show the sheet over the full route, e.g. a modal bottom sheet with useRootNavigator / a full-screen barrier, so the barrier covers everything.
2. AMOUNTS: in each payout row, "£4.20" / "£2.10" are part of the subtitle line at the subtitle's size: bold 13 px Inter, inline after "Weekly + quests · ". The app renders them as a separate ~18 px number. Match the HTML exactly (read the P13 HTML for the span's style).
3. Row text y: name top / subtitle within ±1 of the design for both rows (the UI check measured Leo ≈ 2 px high).
Pin 1–3 in a geometry test with real fonts (FontLoader), plus a scrim test that the barrier's rect covers (0,0) and the full screen size.

## UPDATE (23:25, orchestrator QA of cmp_light_3, 0.43% — layout done; one copy decision)
PRONOUN / NO SEED IDS IN PRODUCT CODE (orchestrator decision, same as P15's "their"):
- Remove the `childId == 'maya' && title == 'Lego Friends set'` special case. Product code must never branch on seed ids.
- Use ONE data-driven, ungendered sentence for every child: "Move $amount of $name's to their $goalTitle fund", e.g. "Move £1.00 of Maya's to their Lego Friends set fund". With no goal: "Move $amount of $name's money to savings".
- It may wrap to two lines like the design. Keep the row geometry (toggle track at the design rect).
- Update the copy tests: this is the intended copy, so the design's "her Lego fund" is NOT a finding.
