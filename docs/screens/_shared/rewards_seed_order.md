Rewards: creation order + seed truth (from P14 QA).

1. Seed (app/lib/core/data/seed.dart, _rewardsDemo ~490-510): the design P14 (design/screens/light/P14-*.png) shows "Baking together" with "Needs my OK" OFF. Every other visible reward is ON. Set `needsOk: false` for r-baking in the demo seed only. Check the P14 design PNG for any other reward flag that differs and match it.
2. Owner rule: "listed in the order they were added". Give `rewards` a creation order like quests (schema v4 added quests.created_at + created_at_tz):
   - Add `rewards.created_at` (UTC) + `created_at_tz` in a schema v5 migration: same placeholder + backfill-in-rowid-order trick as v3/v4, with a migration test.
   - Make the seed insert in the current order.
   - Expose a DB query/stream that returns a family's rewards ordered by created_at, then id.
   - Grep app/lib/features for any rewards query that orders by price/title, and list it in the report. Do NOT edit P14's feature code; P14 will switch to the canonical query.
3. Tests:
   - The demo seed reward order is screen, film, bedtime, baking, café, dinner.
   - Baking needsOk is false.
   - The migration backfills in rowid order.
DONE = dart format clean, flutter analyze "No issues found!", full flutter test green, docs/screens/_shared/rewards_seed_order_REPORT.md (the query name P14 must use), committed.
