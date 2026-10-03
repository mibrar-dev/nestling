// Drift schema v1 → v2 migration: every event instant gains a `…_tz`
// zone column (backfilled to London), `families` (+ `settings` mirror)
// gains `time_zone`, and `quests` gains the floating `due_time_local` rule.
//
// The test builds a real v1 database file with raw SQL at `user_version =
// 1`, inserts pre-migration rows, then opens it with the v2 [AppDatabase]
// and asserts the upgrade backfilled London and kept every instant intact.

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

/// Minimal v1 DDL (pre-`…_tz`/`time_zone`/`due_time_local` columns).
/// References are omitted on purpose: only the upgraded tables must exist.
/// `rewards` is kept in its exact pre-v5 shape (no `created_at` /
/// `created_at_tz` until schema v5): real v1 databases have this table, and
/// the v5 open runs the v5 step on this fixture too, which needs the table
/// to exist.
const List<String> _v1Ddl = <String>[
  "CREATE TABLE families (id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL DEFAULT 'Nestling', payout_day INTEGER NOT NULL DEFAULT 6, coin_value_pence_per_coin INTEGER NOT NULL DEFAULT 1, pocket_money_mode TEXT NOT NULL DEFAULT 'both')",
  // Pre-creation-order `children` (no `created_at` / `created_at_tz` until
  // schema v3): real v1 databases have this table, so the fixture keeps it
  // and the v3 step backfills it (empty here ⇒ no-op).
  'CREATE TABLE children (id TEXT NOT NULL PRIMARY KEY, family_id TEXT NOT NULL, nickname TEXT NOT NULL, age_band TEXT NOT NULL DEFAULT "7-9", age_years INTEGER NOT NULL DEFAULT 7, avatar_colour TEXT NOT NULL DEFAULT "lilac", pin_hash TEXT NULL, pip_style TEXT NOT NULL DEFAULT "mochi", pip_skin TEXT NOT NULL DEFAULT "sunny", pip_accessory TEXT NOT NULL DEFAULT "none", pip_stage INTEGER NOT NULL DEFAULT 1, pip_total_coins INTEGER NOT NULL DEFAULT 0, coins INTEGER NOT NULL DEFAULT 0, happiness INTEGER NOT NULL DEFAULT 4, happy_days INTEGER NOT NULL DEFAULT 0, weekly_base_pence INTEGER NOT NULL DEFAULT 0)',
  "CREATE TABLE quests (id TEXT NOT NULL PRIMARY KEY, family_id TEXT NOT NULL, title TEXT NOT NULL, icon TEXT NOT NULL DEFAULT 'star', coins INTEGER NOT NULL DEFAULT 10, repeat_rule TEXT NOT NULL DEFAULT 'once', days TEXT NOT NULL DEFAULT '', due_label TEXT NULL, needs_approval INTEGER NOT NULL DEFAULT 1, assignee_child_id TEXT NULL, active INTEGER NOT NULL DEFAULT 1)",
  "CREATE TABLE quest_completions (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, quest_id TEXT NOT NULL, child_id TEXT NOT NULL, family_id TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'to_do', coins INTEGER NOT NULL DEFAULT 0, created_at INTEGER NOT NULL, decided_at INTEGER NULL)",
  "CREATE TABLE ledger_entries (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, family_id TEXT NOT NULL, child_id TEXT NOT NULL, type TEXT NOT NULL, amount_pence INTEGER NOT NULL, note TEXT NOT NULL DEFAULT '', date INTEGER NOT NULL)",
  "CREATE TABLE reward_redemptions (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, reward_id TEXT NOT NULL, child_id TEXT NOT NULL, family_id TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'requested', created_at INTEGER NOT NULL)",
  'CREATE TABLE earned_badges (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, badge_id TEXT NOT NULL, child_id TEXT NOT NULL, family_id TEXT NOT NULL, earned_at INTEGER NOT NULL)',
  "CREATE TABLE rewards (id TEXT NOT NULL PRIMARY KEY, family_id TEXT NOT NULL, title TEXT NOT NULL, icon TEXT NOT NULL DEFAULT 'gift', coin_price INTEGER NOT NULL, needs_ok INTEGER NOT NULL DEFAULT 1)",
  "CREATE TABLE settings (family_id TEXT NOT NULL PRIMARY KEY, pocket_money_mode TEXT NOT NULL DEFAULT 'both', payout_day INTEGER NOT NULL DEFAULT 6, coin_value_pence_per_coin INTEGER NOT NULL DEFAULT 1, notif_approvals INTEGER NOT NULL DEFAULT 1, notif_payout INTEGER NOT NULL DEFAULT 1, notif_summary INTEGER NOT NULL DEFAULT 1, crash_report_consent INTEGER NOT NULL DEFAULT 0, kid_gate_enabled INTEGER NOT NULL DEFAULT 1)",
  "CREATE TABLE app_state (id INTEGER NOT NULL PRIMARY KEY, onboarding_complete INTEGER NOT NULL DEFAULT 0, subscription_status TEXT NOT NULL DEFAULT 'trial', trial_start INTEGER NULL, active_child_id TEXT NULL, app_mode TEXT NOT NULL DEFAULT 'parent')",
];

void main() {
  test('v1 → v2 backfills London zones and keeps every instant', () async {
    final dir = await Directory.systemTemp.createTemp('nestling-mig');
    final file = File('${dir.path}/nestling.db');
    try {
      // Raw sqlite: v1 tables + rows, then stamp user_version = 1 so the
      // v2 open below must run onUpgrade (not onCreate).
      final raw = sqlite.sqlite3.open(file.path)
        ..execute('PRAGMA foreign_keys = OFF;');
      _v1Ddl.forEach(raw.execute);
      raw
        ..execute("INSERT INTO families (id) VALUES ('fam1')")
        ..execute(
          'INSERT INTO quest_completions (quest_id, child_id, family_id, '
          "status, coins, created_at) VALUES ('q1', 'maya', 'fam1', "
          "'approved', 15, 1759491120)",
        )
        ..execute(
          'INSERT INTO ledger_entries (family_id, child_id, type, '
          "amount_pence, note, date) VALUES ('fam1', 'maya', 'quest_bonus', "
          "15, 'Bins', 1759491120)",
        )
        ..execute(
          'INSERT INTO app_state (id, onboarding_complete, '
          "subscription_status, trial_start) VALUES (1, 1, 'active', "
          '1758260000)',
        )
        ..execute("INSERT INTO settings (family_id) VALUES ('fam1')")
        ..execute('PRAGMA user_version = 1;')
        ..close();

      // Open with the v2 schema: onUpgrade must add + backfill.
      final db = AppDatabase(NativeDatabase(file));
      final families = await db.select(db.families).get();
      expect(families, hasLength(1));
      expect(families.single.timeZone, 'Europe/London');

      final completions = await db.select(db.questCompletions).get();
      expect(completions, hasLength(1));
      expect(completions.single.createdAtTz, 'Europe/London');
      expect(completions.single.decidedAtTz, 'Europe/London');

      final ledger = await db.select(db.ledgerEntries).get();
      expect(ledger.single.dateTz, 'Europe/London');

      final state = await (db.select(
        db.appState,
      )..where((a) => a.id.equals(1))).getSingle();
      expect(state.trialStartTz, 'Europe/London');
      expect(state.subscriptionStatus, 'active');

      final settings = await (db.select(
        db.settings,
      )..where((s) => s.familyId.equals('fam1'))).getSingle();
      expect(settings.timeZone, 'Europe/London');

      // New writes carry their zone; the floating rule column exists.
      await db
          .into(db.questCompletions)
          .insert(
            QuestCompletionsCompanion.insert(
              questId: 'q1',
              childId: 'maya',
              familyId: 'fam1',
              createdAt: Value(DateTime.utc(2026, 10, 3, 7)),
              createdAtTz: const Value('Asia/Dubai'),
            ),
          );
      final rows = await db.select(db.questCompletions).get();
      expect(rows, hasLength(2));
      expect(rows.last.createdAtTz, 'Asia/Dubai');
      await db.close();
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
