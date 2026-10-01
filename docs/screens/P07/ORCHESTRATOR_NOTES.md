# Orchestrator notes for P07 (mandatory)
1. P07 is the END of onboarding. Starting the trial (or "Restore") must call `AppSession.startTrialNow()` and then `AppSession.completeOnboarding()` before navigating to Today, so a restart lands on Today, not /welcome (P01 BUG-4).
