# Family time zone — shared implementation report

Branch: `shared/family_time_zone` (merged with main post-review).
Spec: `docs/research/DATETIME_STORAGE.md` (§2 table, §3 rules, §4
libraries/tests, §5 migration brief), via the brief
`docs/screens/_shared/family_time_zone.md`.

## Item-by-item vs the brief

1. Event instants store UTC + IANA `…_tz` — DONE. `quest_completions`
   (`createdAtTz`/`decidedAtTz`), `ledger_entries` (`dateTz`, covers
   payouts), `reward_redemptions` (`createdAtTz`),
   `earned_badges` (`earnedAtTz`), `app_state` (`trialStartTz`),
   `families`/`settings` (`updatedAt` + `updatedAtTz`, recording the move
   itself per §2). All `TEXT NOT NULL DEFAULT 'Europe/London'`, stamped
   with the writer's zone (validated; fallback family → London → UTC).
   Partial deviation: repos stamp the current FAMILY zone, not the raw
   device zone — the data layer has no device access; `FamilyZoneService`
   owns device reads (see §3). Threading the device zone into repo writes
   is a follow-up.
2. Calendar rules floating in `families.time_zone` — DONE. `time_zone TEXT
   NOT NULL DEFAULT 'Europe/London'` on families (+ settings mirror);
   `quests.due_time_local` nullable `HH:MM`; `repeatRule`/`days`/`payoutDay`
   unchanged (already zone-agnostic); all period math takes the family zone.
3. History in stored zone; today/week/payout/due in CURRENT family zone —
   DONE. Repository detail strings render via stored `…_tz` (zone named
   when it differs from the family zone); `TodayRepository.rows()` /
   pending count use the live family zone.
4. Drift v1 → v2 `MigrationStrategy.onUpgrade` + migration test —
   DONE. 13 `m.addColumn` calls (NOT NULL DEFAULT backfills London);
   `beforeOpen` bootstrap kept. Test is a real file upgrade (raw-SQL v1 at
   `user_version = 1` → v2 open asserts backfill + intact instants), not a
   drift_dev verifier (no generated schema snapshots exist in tree).
5. `timezone` + `flutter_timezone`, tz init at startup (`latest_10y`) —
   DONE. `timezone ^0.11.1`, `flutter_timezone 4.1.1` (NOT 5.x: 5.x requires
   equatable ^2, app pins equatable ^3 — solver-forbidden; 4.1.1 exposes the
   same `Future<String> getLocalTimezone()` used here).
   `family_time.dart` exposes exactly `toFamilyZone`, `dayStartUtc`,
   `weekStartUtc`, `countsForCurrentPeriod(rule, completed, now, zone)`,
   `formatDay`/`formatTime` (+ zone label), plus `normalizeZoneId`,
   `resolveWriteZone`, `shortZoneLabel`, `initFamilyTime`.
6. Shims + call-site migration — DONE per review revision. `london_time.dart`
   keeps UNANNOTATED shims (review override: `@Deprecated` broke every
   screen gate; header notes removal after screens migrate). All call sites
   on this branch in `core`, `app`, feature DATA repos and shared tests use
   `family_time`; only in-flight screen PRESENTATION (`today_bloc.dart`)
   still calls shims. No `features/**/presentation/**` edited.
7. `FamilyZoneService` + `setFamilyTimeZone` + P16 note — DONE. Service in
   core (device read, `pendingMove` one-time prompt input, never silent,
   `confirmPendingMove`, validated `setFamilyTimeZone`); registered in DI;
   `SettingsRepository.setFamilyTimeZone` / `watchFamilyTimeZone`; no UI
   (see `docs/screens/P16/ORCHESTRATOR_NOTES.md`).
8. Seed — DONE. `families.time_zone = 'Europe/London'`; every seeded
   instant stamped; `Seed.movedToDubai()` fixture (zone flip, instants
   untouched).
9. `docs/data/POSTGRES_TIME.md` — DONE. Mirror DDL (`timestamptz` + `TEXT`
   tz) + migration notes.
10. Tests — DONE, all pass (550/550, incl. all pre-existing London tests
    unchanged in expectation):
    - DST gap 2026-03-29 + ambiguous hour 2026-10-25
      (`family_time_test.dart`: spring-forward gap, autumn-back ambiguous
      hour, autumn-back day start).
    - London→Dubai move (`family_time_test.dart`: history display
      unchanged, day/week/payout follow Dubai, straddling period expires).
    - Device ≠ family uses family today (`family_time_test.dart`: family
      "today" follows the family zone).
    - Unknown zone fallback (`family_time_test.dart`: normalize/helpers/
      resolveWriteZone/set-guard).
    - Migration v1→v2 backfill (`time_migration_test.dart`).
    - London behaviour pinned (`london_period_test.dart` via new API).

## Differences vs DATETIME_STORAGE.md §2 table (checked after main merge)

- Column names: doc sketches `created_tz`/`decided_tz`/`entry_tz`/`trial_tz`;
  implemented `created_at_tz`/`decided_at_tz`/`date_tz`/`earned_at_tz`/
  `trial_start_tz` (derived from the Drift field names, same pattern).
  No functional difference.
- Doc §3 stamps Dad's rows with the DEVICE zone; v1 stamps the family zone
  (see item 1) — device-zone threading is the deferred follow-up.
- Doc §2 "owed aggregates bucket by current family zone": owed stays
  since-last-payout (no weekly bucket exists); payout weekday IS evaluated
  in the family zone (tested).
- RFC 9557 wire form, `members.preferred_tz`, Postgres migration itself:
  N/A yet (local-only, no API boundary) — POSTGRES_TIME.md stages the DDL.
- Doc §5(4) zone-setting UI + §5 acceptance "london_time.dart deleted":
  explicitly out of scope (P16 later; shims kept per review so screens keep
  compiling).

## Verification

- `dart format .` clean; `flutter analyze` → `No issues found!`
  (no ignores added); `flutter test` → 550/550 pass.

## Follow-ups for screens

- P16: build zone row + one-time move prompt per P16/ORCHESTRATOR_NOTES.md.
- First future `earned_badges` award-write path must stamp `earnedAtTz`.
- Presentation still on shims (`today_bloc` greeting/dateLine): migrate to
  `family_time` when those screens are touched; delete `london_time.dart`
  once zero callers remain. Notification-time evaluation in family zone when
  a scheduler exists.

VERDICT: PASS
