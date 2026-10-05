# K03b orchestrator notes

## (04:03) Mandatory decisions
- ONE kid home. "All done" is a STATE of the K03 kid home (`KidHomeView`), shown whenever every one of the child's quests counts as done for the current period. Do NOT build a separate screen. `/kid-home-done` must render the same `KidHomeView` (route keeps its path/name). A real child who finishes all quests on `/kid-home` must see exactly the K03b design. K03's own UI (demo seed, 3 of 6) must not move — re-run K03's tests.
- Replace the placeholder `KidHomeDoneView` (AppBar 'K03b Kid home done') — delete it or make it a thin alias of `KidHomeView`.
- Data: the orchestrator is adding `SEED=kid_all_done` (demo + Maya's quests all done this period) on branch shared/kid_all_done_seed; it will be merged to main and your loop merges main before the build. Every UI check of K03b uses seed `kid_all_done` (shot.sh 6th arg), whatever the brief's seed says. Do not edit seed.dart yourself.
- Counts and copy come from the DB ("6 of 6 done" = done/total for the current period). Pip is Maya's own PipAvatar.

## (04:52) Iteration 2 — exact fixes for 5_ui.md (mandatory)
- D1 (stage 15 px too tall): the K03b confetti/sparkle layer is `position: absolute` in the HTML, so it must NOT take part in layout. Paint it in a `Stack(clipBehavior: Clip.none)` with `Positioned` children (or a `CustomPaint` behind the stage) so the pet-stage block has EXACTLY the same height as K03's stage. Do not touch shared `nest_pet_stage.dart` / `pip_rive.dart`. Targets (logical px): "Today's quests" title top 469.3, progress top 513.0, first card top 545.0, both themes. K03 (demo) must not move.
- D2 (bubble alignment): fixed in shared code by the orchestrator (branch shared/speech_align → main). Not this branch's job.
- ROW ORDER (owner rule: items in creation order): the quest list is in quest creation order (dishwasher, reading, tidy … as the K03b and K03 HTML show), never re-sorted by status. If the current kid-home ordering sorts by status, change it to creation order and prove K03's demo rows still match the K03 design.
- ROW META: a done quest that needs approval and is still waiting shows "Waiting for Mum"; an approved one that needed approval shows "Mum said yes!"; a done quest that needs no approval shows its "+N" coin chip — exactly as the K03b HTML rows. These come from DB status + the quest's approval flag, never from hard-coded rows.
