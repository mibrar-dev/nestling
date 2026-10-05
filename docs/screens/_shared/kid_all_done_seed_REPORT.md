# Shared report — kid_all_done_seed: K03b "all done" seed (`SEED=kid_all_done`)

## Files changed

- `app/lib/core/data/seed.dart` — new `Seed.kidAllDone(db)` + `kid_all_done`
  header bullet (six variants now). Runs exactly `demo(db)`, then inserts a
  `done_pending` quest_completions row for each of Maya's quests with no
  done/approved completion in its current period
  (`london.countsForCurrentPeriod` from `core/data/london_time.dart`,
  imported with a `london` prefix to avoid the `family_time.dart` name
  clash). New rows are stamped `Seed.utc(10, 3, 8, 30)` (08:30 UTC = 09:30
  London on the anchor day: inside the current London day, after every demo
  completion, deterministic under the pinned test clock and "today" in
  production). Only `quest_completions` grows; no other table is touched.
- `app/lib/app/launch.dart` — `case 'kid_all_done': await Seed.kidAllDone(db);`
  plus the `SEED=…` comment value.
- `app/lib/app/launch_flags.dart` — `kid_all_done` in the `SEED=…` comment
  and in `isSupportedSeed`.
- `docs/screens/SCREENS.tsv` — K03b seed column `demo` → `kid_all_done`.
- `app/test/app/launch_flags_test.dart` — `isSupportedSeed` case now covers
  `kid_all_done`.
- `app/test/core/data/kid_all_done_seed_test.dart` (new, 5 tests, see below).

No feature presentation code touched. No schema change. No new assets.

## What / why

K03b (`design/html-source/screens/K03b-kid-home-done.html`) is Maya's kid
home with every quest for the current period done ("6 of 6 done",
"All done!"). In `demo`, Maya is 4 of 6: `q-dishwasher`/`q-table` pending
today plus weekly `q-bins`/`q-hoover` approved this week; `q-reading` and
`q-tidy` sit at `to_do`. `kidAllDone` adds exactly those two completions.

Status follows the K03b HTML per-row labels ("Approved by Mum" → approved,
"Done"/waiting → pending): both open quests are labelled "Done" with a
`+10`/`+15` coin pill, so both rows are `done_pending`. Nothing is
approved, deliberately:

- `KidHomeRepositoryImpl.completeQuest` (pending path) writes ONLY the
  completion row — no ledger entry, no coin change. Credits land only via
  the approvals `approve` path (`quest_bonus` ledger row). The new rows copy
  the `completeQuest` shape exactly (status + coin snapshot + London-zone
  stamps, `decidedAt`/`kidNote` absent), so Maya keeps her demo 120 coins /
  £4.20 owed and the design's `120` coin pill stays exact.
- Approving anything (e.g. upgrading `q-dishwasher` to match its
  "Mum said yes!" row) would insert `ledger_entries` rows — another table,
  which this task forbids — and move balances off the demo spec. Per the
  DATA OVER MOCKS ruling the DB value wins where a row and the HTML differ.

`quest_completions.id` / `ledger_entries.id` are autoincrement ints (the
demo helpers also pass no explicit id), so no `newId` UUID is applicable;
nothing in this change needs a generated id.

## Test names added

`app/test/core/data/kid_all_done_seed_test.dart` → `Seed.kidAllDone`:

- `Maya has 6 of 6 done in the current period` — driven through the real
  `KidHomeRepositoryImpl.watchItems()` (Maya is the demo active child):
  6 items, none `to_do`, with the exact per-quest map
  (dishwasher/reading/tidy/table pending; bins/hoover approved).
- `every Maya quest has a done completion in the pinned period` — per-quest
  latest-in-period check with `appNowUtc()` + `countsForCurrentPeriod`.
- `added completions are pending only, no ledger or coin effects` — demo
  completions are a strict prefix (+2 rows: `q-reading`, `q-tidy`, pending,
  coin snapshots 10/15, story-anchored times); Maya still 120 coins / 420p.
- `Leo unchanged vs demo` — Leo's completions, ledger rows and child row
  equal a parallel `Seed.demo` database.
- `every table except quest_completions is identical to demo` — full-row
  snapshot of all 14 tables.

Changed: `LaunchFlags.isSupportedSeed supports demo, empty, fresh,
new_family, kid_all_done and onboarding_kids` (added `kid_all_done`).

## Verification

- `cd app && dart format .` — clean (0 changed).
- `flutter analyze` — `No issues found!` (no new ignores).
- `flutter test --timeout 120s` — `+4392 ~12: All tests passed!` (12 skips
  are pre-existing proof-skips; 0 failures).

## Follow-up for screens

- K03b (`screen/K03b`): shoot with `SEED=kid_all_done` (already wired via
  `SCREENS.tsv`); header reads "All done!", chip "6 of 6 done", Maya 120
  coins. Note: the `q-dishwasher` row renders the pending meta (`+15`) while
  the HTML shows "Mum said yes!" — DB wins per DATA OVER MOCKS; do not
  hand-edit the seed to approved (it would move ledger/balances off spec).
- Other screens: no action. `demo` rows are untouched, so every spec number
  test still passes; only `quest_completions` gains rows and only under the
  new `kid_all_done` seed.

VERDICT: PASS
