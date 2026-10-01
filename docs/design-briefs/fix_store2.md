STORE QA round 2 — big improvement (phones 62–65%, balanced headlines, feature graphic fixed). ONE rule is still broken on several slides: callout chips cover real in-app content. Rule: a chip may overlap only the device bezel and the background, never the screen area's text/numbers. Fix via write_file, verify with get_file, in BOTH iOS and Play sets:
- 02-quest: "40+ ideas included" chip covers "Before tea (5pm)" row; "Put the bins out +15" and "Make your bed +5" chips cover the icon row / "Anyone" chip. Move all chips so their inner edge overlaps the frame by ≤24px only.
- 04-money: "£4.20 owed · Sat" chip covers the "£4.20" balance on the screen; "You pay your way" chip covers the "+£0.12" amount. Move both outside the screen area.
- 05-approvals: "Approved +15 coins for Maya" chip covers the first card's avatar/title — shift left so only the bezel is overlapped.
- 06-rewards: "Film night · 80" covers the "Reward shop" title; "Baking together · 100" covers a "Get it" button. Move off-screen-area.
- 07-payout: "Thanks Mum! · £1 to Lego fund" chip — check it doesn't cover the "Thanks Mum!" button.
Keep everything else exactly as is. Reply: changelog per file.
