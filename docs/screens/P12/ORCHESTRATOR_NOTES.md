
## UPDATE (12:08, orchestrator QA of cmp_light_1, 10.46%) — targets for iteration 2 (the UI-check PASS is overruled)
Measured on the 390-wide sheet (design → app, logical y = sheet y − 84):
- "Pocket money" title baseline band: design ≈ 72 → app ≈ 88 (+16). The whole screen below inherits this. Find the extra 16 px above the title: an extra SafeArea / top padding on top of NestStatusBar, or a header spacer. The title must sit where P10 Quests puts its title (design y ≈ 72), using the same parent-tab header layout.
- Segmented control top: design ≈ 106 → app ≈ 121.
- Owed card top: design ≈ 173 → app ≈ 189. Goal card top: 400 → 419. History card top: 504 → 525 (+21: one more +5 inside the stack; check the owed-card and goal-card heights against the HTML).
- Hero amount "£4.20": use the CSS letter-spacing -0.4 (`.hero .amt`) via copyWith.
- Fix so every element is within ±1 px of the design. Add a real-font geometry test pinning the title, segmented, owed card, goal card and history tops.
- History rows, dates and amounts come from the DB (not findings).
