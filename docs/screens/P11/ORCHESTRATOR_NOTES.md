
## UPDATE (15:31, orchestrator QA of cmp_light_1, 11.3%: the UI PASS is overruled)
1. Child quotes are missing: the design shows each child's note under the meta line ("I stacked everything neatly!", "I did the pillows too."). completions had no note column. Branch shared/completion_note adds `completions.kid_note` (schema v6) and seeds the notes. Once it is on main (merged before your build), render the quote exactly per the HTML (Nunito, quote marks per the shared report). A NULL note shows no quote line and no gap.
2. The pending SET comes from the DB: Maya dishwasher 8:12, Maya table 8:05, Leo bed 7:58. That is correct (DATA OVER MOCKS), not a finding.
3. "Approve all (3)" bottom CTA: the button centre is ≈ 8 px lower than the design (design 844 − 84 = y 760 centre; app ≈ 768). Match NestBottomCta's position to the design: the button top is 16 px under the panel top and the panel surface still runs to the screen edge. If the cause is shared NestBottomCta, write SHARED_REQUEST.md with numbers.
4. Card geometry: each card's height and spacing must match the design for a card WITH a quote (design card 1: 271…443 sheet = 172 tall) and WITHOUT one. Pin both in a real-font geometry test.
- (15:38) shared/completion_note is on main: use `QuestCompletions.kidNote`; see docs/screens/_shared/completion_note_REPORT.md for where the curly quotes come from.
