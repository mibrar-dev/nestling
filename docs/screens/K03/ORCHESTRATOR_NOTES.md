# Orchestrator notes for K03 (mandatory)
1. Replace the v1 Pip SVG with `PipAvatar` for the active child (Maya: Mochi, sunny, stage 3, inNest true). Keep the design's Pip slot size: Pip ≈152 px tall on the 260×236 nest, nest top ≈ y 300 — the current Pip renders larger and higher than the design.
2. "4 done today / 4 of 6 done" is correct (database). Not a defect.

## Ruling on "done today" (K03-BUG-4 / SHARED_REQUEST #4) — mandatory
Main now has `countsForCurrentPeriod` (app/lib/core/data/london_time.dart). In this feature's repository, treat a quest's latest completion as current only if `countsForCurrentPeriod(quest.repeatRule, completion.createdAt, DateTime.now().toUtc())`; otherwise the quest is "to do". Un-skip the day-boundary bug test and make it pass. The seed is anchored to today in the app and to Sat 3 Oct 2026 in tests (test/flutter_test_config.dart) — do not hard-code dates.

## Bottom inset after the shared NestHomeIndicator change (mandatory, iteration 3)
`NestHomeIndicator` no longer reserves 34 px (the OS draws the indicator). The kid dock is not inside NestBottomCta, so K03 must own the inset: put the dock in `SafeArea(top: false)` (or pad by `MediaQuery.viewPaddingOf(context).bottom`) so the dock top lands at the design's y≈720 on the 390×844 iPhone, and let the meadow background extend under the dock and the home-indicator area to the bottom edge (design: green to y=843, both themes). That fixes UI items 1–3 together.
`DISABLE_ANIMATIONS=1` now sets MediaQuery.disableAnimations app-wide (main) — K03-BUG-7 is shared and fixed; un-skip/adjust its test.

## OWNER FEEDBACK (overrides my earlier meadow note) — mandatory
The owner saw K03 and dislikes the green strip under the dock ("on the bottom I can see green, that is not looking good"). REVERSE the earlier instruction: the meadow must END at the dock's top edge. The dock's own surface colour (light: white surface; dark: the dock's dark surface) must fill everything from the dock's top border down to the physical screen edge, including the home-indicator area — no green below the dock in either theme.
