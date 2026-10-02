SHARED REQUEST BATCH 1 — implement the OPEN shared requests filed by screen agents. Read each file in full (they contain evidence, file:line and suggested fixes):
- ../nestling-screens/P04/docs/screens/P04/SHARED_REQUEST.md  (trash icon; dark privacy shield; settings row missing on first run — skip items marked RESOLVED)
- ../nestling-screens/P05/docs/screens/P05/SHARED_REQUEST.md  (context.push no-op from top-level routes; interactive NestChip stretching inside a Wrap — skip LANDED items)
- ../nestling-screens/P08/docs/screens/P08/SHARED_REQUEST.md  (#2 NestCard double-announced semantics; #4 push contract from Today to P09/P11 — skip RESOLVED)
- ../nestling-screens/P03/docs/screens/P03/SHARED_REQUEST.md  (#2 brand buttons + #4 NestButton doubled screen-reader label; #5 NestTextField errorText rendered inside the field — skip RESOLVED)
- ../nestling-screens/P02/docs/screens/P02/SHARED_REQUEST.md  (#1 compact nav-bar wide text action; #3 pager tokens — skip WITHDRAWN)
- ../nestling-screens/K03/docs/screens/K03/SHARED_REQUEST.md  (items 1, 6, 7, 9: NestKidQuestCard tile tint, KidScope meadow band, kid type styles, NestKidButton label wrap; item 2 is design-copy only — ignore)
Rules for this batch:
1. Every change is backward-compatible (screens on other branches still compile): add parameters/variants with defaults; don't rename public APIs.
2. Icons: draw `ic_trash.svg` from the path in design/html-source/screens/P04-privacy.html (24×24, stroke currentColor, 2 px, round caps/joins) and register `NestIcons.trash` in app/lib/core/design_system/assets/nestling_assets.dart + nest_icon.dart. Privacy shield: make the circle a token-coloured layer (light sky tint / dark navy per the dark design PNG) instead of a baked #E6EFFE.
3. Data: the settings row must exist on a real first launch — create it in AppDatabase.migration beforeOpen like the app_state row (insertOrIgnore), with the documented defaults (crash-report consent OFF).
4. Navigation: fix the root cause of `push` doing nothing from top-level routes (go_router config in app/lib/app/router.dart) and add router tests that push P09 from /today, P11 from /today, and /value-tour from /welcome and assert the location + back pop returns.
5. A11y: one semantics node per card/button (merge, don't double-announce); add semantics tests.
6. For each request item write a line in docs/screens/_shared/shared_requests_batch1_REPORT.md: source file + item → DONE / NOT DONE (why) + files changed + tests added. Also append "RESOLVED on main by shared/shared_requests_batch1" under each handled item in the ORIGINAL SHARED_REQUEST.md files' copies inside YOUR worktree's docs (do not touch other worktrees).
7. Verify visually: shot.sh P04 /privacy light+dark (seed fresh) → the trash icon and the dark shield must appear; READ the PNGs.
