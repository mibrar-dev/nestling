# Shared rewards_seed_order — REPORT (branch `shared/rewards_seed_order`)

Scope: P14 QA — rewards creation order + seed truth. All changes are minimal
and backward-compatible: one additive schema migration, seed-only flag +
timestamp stamps, one new DB stream (no existing query renamed or
reordered), one new test file, three one-line fixture additions. No route
changes, no screen presentation code touched. Screen branches merge and
compile without edits.

Evidence read first: `design/screens/light/P14-rewards.png` +
`design/screens/dark/P14-rewards.png` (Baking toggle OFF, all other visible
toggles ON), `design/html-source/screens/P14-rewards.html` (baking checkbox
is the only one without `checked`; list order is screen, film, bedtime,
baking, café + New reward — NOT price order), `docs/ARCHITECTURE.md`,
`docs/screens/RULES.md`, `docs/design/SPACING_SPEC.md`,
`tools/screens/stages/common.md` (owner rules, CHILD ORDER ruling).

## Files changed

- `app/lib/core/data/app_database.dart` (+ regenerated
  `app_database.g.dart`) — `rewards.created_at` (UTC,
  `currentDateAndTime` default) + `created_at_tz` (London default),
  `schemaVersion` 4 → 5, v4 → v5 migration (same constant-0-placeholder +
  rowid-order backfill trick as v2 → v3 / v3 → v4), and the new canonical
  stream `watchRewardsInCreationOrder` (ordered by `created_at`, then `id`).
  Existing `watchRewards` (price order) is kept unchanged for backward
  compatibility — see follow-up below.
- `app/lib/core/data/seed.dart` — `_rewardsDemo` stamps each reward one
  second after the previous (`utc(9, 19, 8) + index`, London zone) in the
  current insertion order, and `r-baking` (`Baking together`) now inserts
  with `needsOk: false`. No other reward flag differs in the P14 design PNGs
  (light + dark agree; `r-dinner` is below the fold and keeps the default
  `needsOk: true`).
- Tests: new `app/test/core/data/rewards_order_test.dart` (5 tests);
  one-line fixture additions in `app/test/core/data/time_migration_test.dart`
  (v1 DDL), `children_order_test.dart` (v2 DDL), `quest_order_test.dart`
  (v3 DDL) — each gains the pre-v5 `rewards` table, because real v1–v4
  databases always have it and the v5 open now runs the v5 step on those
  fixtures (same rationale as the v2-shape `quests` table in the v2
  fixture).
- `app/lib/features/rewards/...` and `app/lib/features/kid_shop/...`:
  untouched (per task — P14 switches to the canonical query itself).

## Grep: rewards queries that order by price/title

No `orderBy`/sort lives in feature code. The only price-ordered rewards
query is the core stream `AppDatabase.watchRewards`
(`app/lib/core/data/app_database.dart`, `ORDER BY coin_price`), consumed at
exactly two call sites, both still on the old ordering until they switch:

- `app/lib/features/rewards/data/rewards_repository_impl.dart:23`
  (`watchItems` → P14 manager list)
- `app/lib/features/kid_shop/data/kid_shop_repository_impl.dart:28`
  (`watchShop` → K08 shop list)

## Tests added (`app/test/core/data/rewards_order_test.dart`)

1. `seed demo lists rewards in creation order (screen, film, bedtime,
   baking, café, dinner)` — `watchRewardsInCreationOrder` returns the six
   seed ids in insertion order, stamped one second apart, all London zone.
2. `baking needs no OK, every other reward needs OK (P14)` — `r-baking`
   `needsOk == false`, the other five `== true`.
3. `a reward added later sorts last, even a cheaper alphabetical first` —
   `a-aaa` / `AAA cheapest reward` / 5 coins sorts last (beats price order
   AND id/title order).
4. `ties on created_at fall back to id order` — identical `created_at`
   rows sort by `id`.
5. `v4 → v5 migration: backfills created_at in rowid order and orders the
   list` — raw-sql v4 DB (expensive inserted before cheap, `user_version =
   4`) opens under v5: zones default London, `created_at` staggered in
   rowid order, canonical list is creation order, not price order.

## Follow-up screens must do

- **P14 must switch to the canonical query
  `AppDatabase.watchRewardsInCreationOrder(familyId)`** (creation order:
  screen, film, bedtime, baking, café, dinner) — i.e. repoint
  `RewardsRepositoryImpl.watchItems` (and any P14-local sort) at it instead
  of `watchRewards` (price order: 50, 60, 80, 90, 100, 150 — contradicts the
  design order). After P14 + K08 have switched, a later shared cleanup may
  remove or redirect the legacy price-ordered `watchRewards`.
- K08: same question for `KidShopRepositoryImpl.watchShop` — kid-facing
  shop order should presumably also be creation order (owner rule); K08
  agent to confirm against the K08 design and switch to the same canonical
  query if so.
- `createReward` needs no change: it omits `created_at`, so the
  `currentDateAndTime` column default stamps new rewards after every seed
  instant and they sort last (covered by test 3 pattern).

Verification: `cd app && dart format .` clean (0 changed),
`flutter analyze` → `No issues found!`, `flutter test` → all 1776 pass.

VERDICT: PASS
