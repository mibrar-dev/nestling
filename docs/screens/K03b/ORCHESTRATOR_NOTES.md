# K03b orchestrator notes

## (04:03) Mandatory decisions
- ONE kid home. "All done" is a STATE of the K03 kid home (`KidHomeView`), shown whenever every one of the child's quests counts as done for the current period. Do NOT build a separate screen. `/kid-home-done` must render the same `KidHomeView` (route keeps its path/name). A real child who finishes all quests on `/kid-home` must see exactly the K03b design. K03's own UI (demo seed, 3 of 6) must not move — re-run K03's tests.
- Replace the placeholder `KidHomeDoneView` (AppBar 'K03b Kid home done') — delete it or make it a thin alias of `KidHomeView`.
- Data: the orchestrator is adding `SEED=kid_all_done` (demo + Maya's quests all done this period) on branch shared/kid_all_done_seed; it will be merged to main and your loop merges main before the build. Every UI check of K03b uses seed `kid_all_done` (shot.sh 6th arg), whatever the brief's seed says. Do not edit seed.dart yourself.
- Counts and copy come from the DB ("6 of 6 done" = done/total for the current period). Pip is Maya's own PipAvatar.
