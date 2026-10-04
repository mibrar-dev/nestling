// P11 completion notes (shared `completion_note`): `quest_completions`
// carries nullable `kid_note` (schema v6) — the child's quote shown under
// the meta line on the approvals cards. Stored WITHOUT the surrounding
// “ ” (the UI adds them); NULL = no note → no quote line.

import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

/// Minimal v5 DDL: `quest_completions` in its exact v5 shape (every column
/// except `kid_note`) plus PK-only stubs for the tables `beforeOpen`
/// touches (the v5 → v6 open only runs the v6 step).
const List<String> _v5Ddl = <String>[
  'CREATE TABLE families (id TEXT NOT NULL PRIMARY KEY)',
  'CREATE TABLE settings (family_id TEXT NOT NULL PRIMARY KEY)',
  'CREATE TABLE app_state (id INTEGER NOT NULL PRIMARY KEY)',
  "CREATE TABLE members (id TEXT NOT NULL PRIMARY KEY, family_id TEXT NOT NULL, name TEXT NOT NULL, role TEXT NOT NULL DEFAULT 'owner', invite_status TEXT NOT NULL DEFAULT 'active')",
  "CREATE TABLE quest_completions (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, quest_id TEXT NOT NULL, child_id TEXT NOT NULL, family_id TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'to_do', coins INTEGER NOT NULL DEFAULT 0, created_at INTEGER NOT NULL, created_at_tz TEXT NOT NULL DEFAULT 'Europe/London', decided_at INTEGER NULL, decided_at_tz TEXT NOT NULL DEFAULT 'Europe/London')",
];

void main() {
  group('completion kid_note seed (schema v6)', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.memory();
      await Seed.demo(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('seed sets the two P11 quotes, q-table has no note', () async {
      final rows = await db.select(db.questCompletions).get();
      QuestCompletion byQuest(String questId, String childId) {
        return rows.firstWhere(
          (r) => r.questId == questId && r.childId == childId,
        );
      }

      expect(
        byQuest('q-dishwasher', 'maya').kidNote,
        'I stacked everything neatly!',
      );
      expect(byQuest('q-bed', 'leo').kidNote, 'I did the pillows too.');
      // Lay the table has no note → NULL → P11 shows no quote line.
      expect(byQuest('q-table', 'maya').kidNote, isNull);
    });

    test('every other seeded completion has a NULL kid_note', () async {
      final rows = await db.select(db.questCompletions).get();
      // 3 pending + 3 approved + 6 to-do = 12 rows.
      expect(rows, hasLength(12));
      for (final row in rows) {
        if ((row.questId == 'q-dishwasher' && row.childId == 'maya') ||
            (row.questId == 'q-bed' && row.childId == 'leo')) {
          expect(row.kidNote, isNotNull, reason: row.questId);
        } else {
          expect(row.kidNote, isNull, reason: row.questId);
        }
      }
    });

    test('watchPendingApprovals returns kid_note (P11 query)', () async {
      final pending = await db.watchPendingApprovals('fam1').first;
      expect(pending, hasLength(3));
      final byQuest = <String, QuestCompletion>{
        for (final c in pending) c.questId: c,
      };
      expect(byQuest['q-dishwasher']!.kidNote, 'I stacked everything neatly!');
      expect(byQuest['q-bed']!.kidNote, 'I did the pillows too.');
      expect(byQuest['q-table']!.kidNote, isNull);
    });
  });

  group('v5 → v6 migration', () {
    test('keeps every row and kid_note is NULL', () async {
      final dir = await Directory.systemTemp.createTemp('nestling-mig6');
      final file = File('${dir.path}/nestling.db');
      try {
        // Raw sqlite: v5 tables + rows, stamp user_version = 5 so the v6
        // open must run onUpgrade.
        final raw = sqlite.sqlite3.open(file.path)
          ..execute('PRAGMA foreign_keys = OFF;');
        _v5Ddl.forEach(raw.execute);
        raw
          ..execute(
            'INSERT INTO quest_completions (quest_id, child_id, family_id, '
            "status, coins, created_at) VALUES ('q-dishwasher', 'maya', "
            "'fam1', 'done_pending', 15, 1759491120)",
          )
          ..execute(
            'INSERT INTO quest_completions (quest_id, child_id, family_id, '
            "status, coins, created_at) VALUES ('q-table', 'maya', 'fam1', "
            "'done_pending', 10, 1759491000)",
          )
          ..execute('PRAGMA user_version = 5;')
          ..close();

        final db = AppDatabase(NativeDatabase(file));
        try {
          final rows = await db.select(db.questCompletions).get();
          expect(rows, hasLength(2));
          for (final row in rows) {
            expect(row.kidNote, isNull, reason: row.questId);
          }
          // Status / coins survive the upgrade untouched.
          final byId = <String, QuestCompletion>{
            for (final r in rows) r.questId: r,
          };
          expect(byId['q-dishwasher']!.status, 'done_pending');
          expect(byId['q-dishwasher']!.coins, 15);
          expect(byId['q-table']!.status, 'done_pending');

          // New writes can set a note.
          await db
              .into(db.questCompletions)
              .insert(
                QuestCompletionsCompanion.insert(
                  questId: 'q-bed',
                  childId: 'leo',
                  familyId: 'fam1',
                  status: const Value('done_pending'),
                  createdAt: Value(DateTime.utc(2026, 10, 3, 6, 58)),
                  kidNote: const Value('I did the pillows too.'),
                ),
              );
          final after = await db.select(db.questCompletions).get();
          expect(after, hasLength(3));
          expect(
            after.firstWhere((r) => r.questId == 'q-bed').kidNote,
            'I did the pillows too.',
          );
        } finally {
          await db.close();
        }
      } finally {
        await dir.delete(recursive: true);
      }
    });
  });
}
