# Orchestrator notes for P07 (mandatory)
1. P07 is the END of onboarding. Starting the trial (or "Restore") must call `AppSession.startTrialNow()` and then `AppSession.completeOnboarding()` before navigating to Today, so a restart lands on Today, not /welcome (P01 BUG-4).

## UPDATE (04:08, iteration 4)
- main fd92d95 was merged into this branch during your build. NestType now defaults to letterSpacing 0. Before that, Material added tracking, which made Inter look 1–2% wider than the design. That most likely fixes UI item 1, "Co-parent sharing, so James sees the same" wrapping onto two lines. Re-measure it; do NOT shrink the text or edit the copy.
- Legal `·` separators: give them the same 44 px centred box as the links (UI item 2).
- The title orphan "days" (text-wrap: balance) is MINOR and accepted for now. Do not insert a hard break.
