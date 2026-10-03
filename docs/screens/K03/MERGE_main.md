# MERGE_main — screen/K03 × main (family time zone)

Date: 2026-10-02 · Branch: `screen/K03` · Merge source: `main` @ `7260014`.
Conflict: `app/lib/features/kid_home/data/kid_home_repository_impl.dart`
(K03 period rule + idempotent write vs main family-zone behaviour).
Only one content conflict; all other files auto-merged.

## Files

- Hand-resolved (1): `app/lib/features/kid_home/data/kid_home_repository_impl.dart`
- Auto-merged from main (no action): `app/lib/core/data/{app_database.dart,
  app_database.g.dart, app_session.dart, family_time.dart (new),
  family_zone_service.dart (new), london_time.dart, seed.dart,
  stream_combine.dart}`, `app/lib/app/di.dart`, `app/lib/main.dart`,
  `app/pubspec.{yaml,lock}`, approvals/kid_jar/kid_shop/onboarding/paywall/
  pocket_money/quests/settings/today repository impls, router push test,
  `app/test/core/{family_time_test.dart (new), time_migration_test.dart
  (new), london_period_test.dart}`, today/onboarding tests, `test_scope.dart`,
  `docs/{data/POSTGRES_TIME.md, research/DATETIME_STORAGE.md,
  screens/_shared/*, screens/P02/*}`, `docs/screens/K03/.brief_build.md`
  (loop iteration-6 line, pre-existing uncommitted change, kept).
- K03 tests: unchanged (no weakening, no zone-API rewrite needed — see below).

## Decisions

1. Import: `london_time.dart` → `family_time.dart`. Period checks now call
   the 4-arg `countsForCurrentPeriod(repeatRule, createdAt, now, zone)` with
   the live family zone instead of the London-pinned 3-arg shim. Semantics
   under the default `Europe/London` family zone are identical, so every
   existing London expectation still holds.
2. `watchItems()`: kept ALL of K03 (assignee filter, title sort, newest-first
   completions, current-period scoping, `to_do` fallback). Added the family
   zone reactively via `combineLatest2` → `combineLatest3` with
   `_db.watchFamilyZoneId()` + `normalizeZoneId`, mirroring main's
   `TodayRepositoryImpl.watchItems` pattern. A family-zone change now
   re-emits K03 periods (day/week bounds move) without touching history.
3. `completeQuest()`: kept ALL of K03 (single-transaction idempotency for
   rapid double taps per K03-BUG-1; in-period filter so only current-period
   `to_do`/`not_yet` flips to `done_pending` and a new period mints a fresh
   row per the K03-BUG-4 ruling). Added main's zone behaviour: `final zone =
   await _db.familyZoneId()` fetched BEFORE the transaction (approvals-repo
   pattern, avoids doing a zone read inside the txn) and stamped as
   `createdAtTz: Value(zone)` on both the update and the insert paths.
4. Tests: NO test edits. K03 repo tests insert completions without `*_tz`
   (DB defaults fill `Europe/London`) and assert London period boundaries;
   with the seeded family zone at its London default the zone-aware repo
   returns identical results. `london_time.dart` shims remain for the
   period-probe unit tests. Nothing weakened, nothing skipped/un-skipped.
5. `watchProfiles()` / child order: untouched (K03-BUG-12 stays `skip`ped —
   shared `watchChildren` still orders by nickname; the CHILD ORDER ruling
   needs an orchestrator-side shared change, filed separately).

## Test counts

- `cd app && dart format .` → `Formatted 368 files (0 changed)`.
- `flutter analyze` → `No issues found!`
- `flutter test test/features/kid_home/` → `+115 ~2: All tests passed!`
  (2 skipped: K03-BUG-7 needs `--dart-define=DISABLE_ANIMATIONS=1`,
  K03-BUG-12 intentionally skipped pending shared child-order fix).
- `flutter test` (full) → `+760 ~2: All tests passed!`

## Follow-ups for screens

- None required by this merge. Note for K-screens sharing `kid_home`:
  periods now follow `families.time_zone`; if any screen pinned London-only
  expectations with a non-London family zone, pass the zone through
  `family_time` helpers instead of `london_time`.
- K03-BUG-12 (child order) still needs the shared `watchChildren` ordering
  fix from the orchestrator; K03 must not work around it locally.

VERDICT: PASS
