
## UPDATE (12:27, orchestrator QA of cmp_light_1, 2.06%) — the layout is right; the data order is wrong
- Rewards must be listed in CREATION order (owner rule: the order they were added), not by price. The design order is 30 min screen (50), Pick Friday film (80), Stay up 15 min later (60), Baking together (100), Trip to the park café (150); "Choose dinner" (90) is added last and sits below the fold.
- Branch shared/rewards_seed_order adds `rewards.created_at` plus a canonical ordered query, and fixes the seed: Baking together's needsOk is false, as in the design. Once main has it (it is merged into your branch before each build), switch P14 to that query and remove any sort by price. Test the order and the Baking toggle state from the DB.
- Do not hard-code the toggle state: it comes from `needsOk`.
- (12:35) P14: use `AppDatabase.watchRewardsInCreationOrder` (now on main).
