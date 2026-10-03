# family_time_test_fix — deterministic kid_home zone-plumbing test

Test-only fix for the red `family_time_test.dart` (`Bad state: Too many elements`
on `kid_home completions are stamped with the family zone` once the real London
date rolled to 2026-10-04). No app code changed; no real app bug found.

## Files changed

| File | Change |
|---|---|
| `app/test/core/family_time_test.dart` | Rewrote the `kid_home completions are stamped with the family zone` test to identify the row `completeQuest` touched via a before/after snapshot diff (new id, or changed `createdAt`/`status`), instead of `.single` over all seeded rows for the quest. Scoped both queries by `questId` + `childId`. Assertions unchanged: Maya/`q-reading` row stamps `Europe/London`, Leo/`q-plants` row after `Seed.movedToDubai` stamps `Asia/Dubai`. |
| `docs/screens/_shared/family_time_test_fix_REPORT.md` | This report. |

Nothing under `app/lib/**` touched; no screen code; no lints weakened; no new
`// ignore:`; temporary anchor probe deleted before commit.

## What and why

**Root cause (test bug, not app bug).** `KidHomeRepositoryImpl.completeQuest`
(`app/lib/features/kid_home/data/kid_home_repository_impl.dart:131-198`) has two
correct branches: if a completion for the quest+child is already inside the
current family-zone period it flips that row in place (`to_do` → `done_pending`,
`createdAt = now`); otherwise it inserts a fresh row. The demo seed always
contains one `to_do` row each for `q-reading`/`maya` and `q-plants`/`leo` at
`Seed.utc(10, 3, 6)` (= `Seed.anchorDay` 06:00 UTC, pinned to 2026-10-03 by
`app/test/flutter_test_config.dart`), while `completeQuest` stamps `now` from
the real clock. On real London 2026-10-03 the seed row is in-period, so the call
updates in place and the old `.single` saw 1 row; on real London 2026-10-04 the
seed row is yesterday, so the call inserts and `.single` saw 2 rows → `Bad
state: Too many elements`. Reproduced here at Sat 3 Oct 23:04 UTC (= Sun 4 Oct
00:04 BST) before the fix.

**Why snapshot-diff, not `createdAt >= before`.** The first attempt filtered on
`createdAt >= instant-before-the-call` (as the task suggested). A 7-anchor probe
showed it fails when the seed day is today-or-future relative to the real clock
(anchors 2026-10-04, 2026-12-15, 2026-10-25 returned 0 touched rows with 1 row
total): the in-place update can move `createdAt` backwards (future seed instant
→ real `now`) and SQLite/Drift timestamp truncation can land the written instant
a few ms before the captured `before`. Comparing snapshots (`id` not in before
→ inserted; same `id` but `createdAt`/`status` changed → flipped in place) is
exact on both branches, needs no wall clock, and also pins the expected
`to_do` → `done_pending` transition. Double `.where()` (not `&`) is used so the
file keeps its existing no-`drift`-import style.

**Audit for the same pattern.** Grepped `app/test/core/**` for `.single` /
`getSingle()`: the only `.single`-over-seeded-rows-after-a-write was the two
lines fixed here (old lines 313/319). All other singles are safe: PK lookups
(`families`/`appState`/`settings` by id, completions by `id`), singleton tables,
or `hasLength` checks (`seed_test`, `completion_note_test`, `time_migration_test`,
`migration_first_run_test`, `repositories_test`, `london_period_test`,
`quest_order`/`children_order`/`rewards_order`). No other core file changed.

## Tests

No new committed tests: the fixed test itself is the coverage (it now asserts
`touched hasLength(1)` with a `completeQuest(child, quest) must touch one row`
reason on both the London and Dubai legs, plus the original `createdAtTz`
assertions). Added assertions live inside the existing test name:

- `seed + repository zone plumbing kid_home completions are stamped with the
  family zone` (fixed; asserts London then Dubai via the snapshot helper).

**Proof across dates (temporary probe, deleted before commit).**
`app/test/core/anchor_probe_test.dart` ran the same helper for
`maya/q-reading` (London) then `leo/q-plants` after `movedToDubai` (Dubai) with
`Seed.anchorOverride` set to each of 2026-10-03, 2026-10-04, 2026-10-02,
2026-09-20, 2026-12-15, 2026-03-29 (spring-forward gap), 2026-10-25 (ambiguous
hour): `+7: All tests passed!` The committed `family_time_test.dart` file alone
is `+22: All tests passed!`.

## Verification (this worktree, `app/`)

- `dart format .` → `Formatted 484 files (0 changed)` (final pass clean).
- `flutter analyze` → `No issues found!` No new ignores.
- `flutter test test/core test/app test/design_system` → `+547: All tests
  passed!` (all in-scope suites green, includes `repositories_test` kid_home
  `completeQuest` path).
- `flutter test` (full) → `+2383 ~1 -34: Some tests failed` — 34 failures, all
  in `test/features/**` (P08 `p08_bugs_test` period scoping, P11
  `approvals_view*` "Today 8:12am" stamps, K03 home matrix/navigation), i.e.
  screen-agent-owned files this task forbids touching (RULES §1). Proven
  pre-existing: with this branch's fix stashed, `approvals_view_test` "three
  seeded cards" fails identically. Same root cause class (seed pinned to 3 Oct
  via `flutter_test_config`, views stamp relative "Today" from the real clock
  now 4 Oct London), but each needs its screen owner's fix.

## What follow-up screens must do

1. Nothing for this fix: no shared API, schema, seed, router, or design-system
   change. Merge is a test-file-only change to `app/test/core/…`.
2. P08 / P11 / K03 owners: your `test/features/**` failures above are the same
   real-date-vs-`anchorDay` fragility in view expectations (e.g. hardcoded
   `Today 8:12am`, `Waiting for you (3)`, period-scoping against real `now`).
   Fix in your own feature tests (or file a `SHARED_REQUEST` if you need a
   shared clock/seed contract); do not reintroduce `.single` over seeded rows.
3. Future shared tests: never `.single` over a quest's completions after a
   `completeQuest` — use the before/after snapshot pattern from this test
   (new id or changed `createdAt`/`status`), and scope by `questId` + `childId`.

VERDICT: FAIL
