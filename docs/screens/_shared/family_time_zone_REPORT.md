# Family time zone — shared implementation report

Branch: `shared/family_time_zone`. Spec: task summary (owner-approved
DATETIME_STORAGE design: UTC instant + IANA `…_tz`, floating rules in
`families.time_zone`). Note: `docs/research/DATETIME_STORAGE.md` does not
exist in this worktree (research dir holds only `BRIEF_datetime.md` + business
round files), so the task summary §2–§5 equivalent in the brief was treated
as the spec.

## Files changed (what / why)

Core (`app/lib/core/**` — allowed):
- `data/family_time.dart` (NEW): `initFamilyTime()` (tz `latest_10y`
  database), `isKnownZoneId`, `normalizeZoneId` (never throws; unknown →
  family → London → UTC), `resolveWriteZone` (device → family → London),
  `toFamilyZone`, `dayStartUtc` / `weekStartUtc` (plain UTC returns),
  `countsForCurrentPeriod(rule, completed, now, zoneId)`,
  `formatDay` / `formatTime` (optional `(Zone)` label when stored zone ≠
  family zone), `shortZoneLabel`. DST handled by the tz database.
- `data/family_zone_service.dart` (NEW): `FamilyZoneService`
  (`deviceZoneReader` injectable): `deviceZoneId`, `familyZoneId`,
  `watchFamilyZone`, `pendingMove` (device ≠ family, never auto-switches),
  `confirmPendingMove`, `setFamilyTimeZone` (validated; mirrors settings).
- `data/app_database.dart`: schema v1 → v2. New: `families.time_zone` /
  `updatedAt(+Tz)`, `settings.time_zone` / `updatedAt(+Tz)`,
  `quests.due_time_local` (nullable HH:MM), `quest_completions.createdAtTz`
  / `decidedAtTz`, `ledger_entries.dateTz`,
  `reward_redemptions.createdAtTz`, `earned_badges.earnedAtTz`,
  `app_state.trialStartTz` (all `TEXT NOT NULL DEFAULT 'Europe/London'`);
  real `onUpgrade` (`m.addColumn` × 13, backfill via defaults); kept
  `beforeOpen` bootstrap; added `familyZoneId()` / `watchFamilyZoneId()`
  (London fallback) for repositories.
- `data/app_database.g.dart`: regenerated via build_runner.
- `data/london_time.dart`: now `@Deprecated` shims delegating to
  `family_time` pinned to `'Europe/London'` (London behaviour identical).
- `data/seed.dart`: family `time_zone` London; every seeded instant stamped
  London; `anchorDay` via `family_time`; NEW `Seed.movedToDubai()` fixture
  (flips family+settings to Dubai, touches no instants).
- `data/stream_combine.dart`: added `combineLatest4` (repo zone streams).
- `data/app_session.dart`: `startTrialNow` stamps `trialStartTz`.

App (`app/lib/app/**`, `main.dart` — allowed):
- `main.dart`: `initFamilyTime()` before DI. `app/di.dart`: registers
  `FamilyZoneService` lazy singleton.

Features — DATA layer only, no presentation (allowed exception):
- `today`: `watchItems`/`watchPendingCount` combine the family zone;
  `rows()` takes `zoneId` (default London); periods zone-aware.
- `approvals`: history detail via stored `createdAtTz` (+ zone label after
  a move); `approve`/`markNotYet` stamp `decidedAtTz` + ledger `dateTz`.
- `pocket_money`: ledger detail via stored `dateTz`; `addMoney` /
  `recordSpending` / `recordPayout` stamp `dateTz`; payout note uses
  family-zone day.
- `kid_jar`: entries via stored `dateTz`; `moveToSavings` stamps `dateTz`.
- `kid_home`: `completeQuest` stamps `createdAtTz` (insert + to_do/not_yet
  update paths).
- `kid_shop`: `requestReward` stamps redemption `createdAtTz`.
- `quests`: `dueTimeLocal` passthrough (create/update/entity); domain
  `Quest.dueTimeLocal` OPTIONAL (default null) + `QuestModel` JSON — all
  existing call sites compile unchanged.
- `paywall`: `startTrial` stamps `trialStartTz`.
- `settings`: NEW `setFamilyTimeZone` + `watchFamilyTimeZone` on the
  interface/impl; `_write` stamps `updatedAt(+Tz)` on both tables.
- Untouched (no timestamp writes / no period math): badges (read-only),
  family, rewards, pip, onboarding, auth, privacy_consent, parental_gate.
  `badges.earnedAtTz` is written by seed; a future award-write path must
  stamp it (see follow-ups).

Deps / docs:
- `pubspec.yaml` (+lock): `timezone ^0.11.1`,
  `flutter_timezone 4.1.1` (exact: 5.x needs equatable 2, app uses
  equatable 3 — solver-forbidden; 4.1.1 API is `Future<String>
  getLocalTimezone()`), `sqlite3 ^3.5.2` dev (migration test only).
- `docs/data/POSTGRES_TIME.md` (NEW): mirror DDL
  (`timestamptz` + `…_tz`) + migration notes for Supabase later.
- `docs/screens/P16/ORCHESTRATOR_NOTES.md` (NEW): setting row + one-time
  move prompt spec for P16 (service API, copy, test hooks).
- Shared tests migrated off deprecated shims: `london_period_test.dart`
  (same expectations via `family_time` + London), `p08_bugs_test`,
  `today_bloc_test`, `today_view_test`.

## Tests added

`test/core/family_time_test.dart` (22 tests):
- DST spring gap 2026-03-29 (`01:30 UTC → 02:30 BST`; day starts midnight
  GMT); ambiguous hour 2026-10-25 (1:30 twice, offsets +1/0; day starts
  23:00 UTC prev day).
- Move: history unchanged (stored zone wins; `(London)` label under Dubai);
  day boundary follows Dubai; week boundary follows Dubai (Sun→Mon split);
  payout weekday in new zone; straddling period expires (`done_pending` →
  `to_do` under Dubai).
- Device ≠ family: family "today" still London (Maya 4/6); `pendingMove`
  null when equal; surfaces Dubai without switching; confirm switches.
- Unknown zones: `normalizeZoneId` never throws; helpers accept bad ids;
  `resolveWriteZone` chain; `setFamilyTimeZone` ignores bad ids.
- Plumbing: seed stamps London everywhere; `dueTimeLocal` round-trip
  (+ null default); kid_home stamps London→Dubai; approvals decision stamp;
  payout note + zone; settings zone watch/set/validate.

`test/core/data/time_migration_test.dart` (1 test):
- `v1 → v2 backfills London zones and keeps every instant`: raw-SQL v1 file
  at `user_version = 1` → real `onUpgrade` → all `…_tz`/`time_zone`
  backfilled London, instants intact, new Dubai write works.

Existing: ALL pass — `flutter test`: 550/550 (includes pinned London
period tests proving unchanged behaviour for never-moved families).

## Verification

- `cd app && dart format .` clean (run last).
- `flutter analyze`: 0 errors, 0 warnings; 2 info-level
  `deprecated_member_use_from_same_package` remain at
  `today/presentation/bloc/today_bloc.dart:63-64` — the INTENTIONAL shims
  the task requires so screen branches keep compiling (file not editable
  per isolation rules; no ignores added anywhere).
- `flutter test`: 550/550 pass.

## Follow-ups screens must do

1. Presentation still on shims: `today_bloc.dart` greeting/dateLine
   (`toLondon`/`formatLondonDay`), `kid_jar`/`pocket_money`/`approvals`
   views that format dates themselves — migrate to `family_time` with the
   family zone + stored `…_tz` when touching those files (do NOT bulk-edit
   other screens' branches; coordinate via orchestrator).
2. P16 Settings: build the zone row + one-time move prompt per
   `docs/screens/P16/ORCHESTRATOR_NOTES.md`.
3. First future `earned_badges` award-write path must stamp `earnedAtTz`
   (currently only seed writes it).
4. Notification scheduling ("before tea 5pm", payout reminders): evaluate
   `dueTimeLocal`/times in the CURRENT family zone at fire time (no code
   yet — no scheduler exists).
5. `docs/research/DATETIME_STORAGE.md` (the approved design doc the task
   cites) is missing from this worktree — orchestrator may want it restored
   from main for traceability.

VERDICT: PASS
