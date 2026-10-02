# Orchestrator notes for P08 (mandatory)
1. Child cards: replace the v1 Pip SVGs with `PipAvatar` per child from the DB (Maya: Mochi·sunny·stage 3, Leo: Bolt·sky·stage 2), same slot size as the design (~52 px tall face), still frame when DISABLE_ANIMATIONS.
2. Approvals banner subtitle must name the children from the data, as in the design: "Maya and Leo did brilliantly yesterday" (1 child: "Maya did brilliantly yesterday"; 3+: "Maya, Leo and Ava …"). Not generic "Your little birds…".
3. Seed now has everyday chores as Daily (main 'Seed: everyday chores repeat daily'); the "Weekly · Sat" labels you saw were seed data, not your bug.
4. Quest order inside each child: status order as the design (Needs a look → To do → Approved), then title.

## Ruling on "done today" (K03-BUG-4 / SHARED_REQUEST #4) — mandatory
Main now has `countsForCurrentPeriod` (app/lib/core/data/london_time.dart). In this feature's repository, treat a quest's latest completion as current only if `countsForCurrentPeriod(quest.repeatRule, completion.createdAt, DateTime.now().toUtc())`; otherwise the quest is "to do". Un-skip the day-boundary bug test and make it pass. The seed is anchored to today in the app and to Sat 3 Oct 2026 in tests (test/flutter_test_config.dart) — do not hard-code dates.

## Orchestrator QA of cmp_light_4 (5.03%, UI PASS) — polish item (owner wants perfect alignment)
- Approvals banner title must break like the design: "3 quests waiting / for your thumbs-up" (constrain the title width to the design's text column so the line break matches; no hard "\n"). Its extra height currently pushes the kids grid and "Today's quests" ~4 px low — after the fix, kids-card top ≈ y 335 and section title ≈ y 575 (390×844).
