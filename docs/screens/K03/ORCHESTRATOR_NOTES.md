# Orchestrator notes for K03 (mandatory)
1. Replace the v1 Pip SVG with `PipAvatar` for the active child (Maya: Mochi, sunny, stage 3, inNest true). Keep the design's Pip slot size: Pip ≈152 px tall on the 260×236 nest, nest top ≈ y 300 — the current Pip renders larger and higher than the design.
2. "4 done today / 4 of 6 done" is correct (database). Not a defect.

## Ruling on "done today" (K03-BUG-4 / SHARED_REQUEST #4) — mandatory
Main now has `countsForCurrentPeriod` (app/lib/core/data/london_time.dart). In this feature's repository, treat a quest's latest completion as current only if `countsForCurrentPeriod(quest.repeatRule, completion.createdAt, DateTime.now().toUtc())`; otherwise the quest is "to do". Un-skip the day-boundary bug test and make it pass. The seed is anchored to today in the app and to Sat 3 Oct 2026 in tests (test/flutter_test_config.dart) — do not hard-code dates.
