// Shared batch 4 — quest creation order (P10 SHARED_REQUEST §5).
//
// The Active list is ordered by quest CREATION order (oldest first) —
// "listed in the order they were added" — not by title. `Quests` carries
// `created_at` (+ `created_at_tz`, schema v4, UTC + IANA zone per
// `docs/research/DATETIME_STORAGE.md`) and `watchActiveQuests` sorts by
// it, then `id`. Covers: the seeded order, a later-added quest sorting
// last, and the v3 → v4 migration backfill (rowid order).

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

/// Minimal v3 DDL: `quests` in its exact v3 shape (every column except
/// `created_at` / `created_at_tz`) plus PK-only stubs for the tables
/// `beforeOpen` touches (the v3 → v5 open also runs the v4 and v5 steps).
/// `rewards` is included in its exact pre-v5 shape: real v3 databases always
/// have it, and the v5 step needs the table to exist.
/// `quest_completions` is a PK-only stub: real v3 databases always have it,
/// and the v6 step needs the table to exist.
const List<String> _v3Ddl = <String>[
  'CREATE TABLE families (id TEXT NOT NULL PRIMARY KEY)',
  'CREATE TABLE settings (family_id TEXT NOT NULL PRIMARY KEY)',
  'CREATE TABLE app_state (id INTEGER NOT NULL PRIMARY KEY)',
  "CREATE TABLE quests (id TEXT NOT NULL PRIMARY KEY, family_id TEXT NOT NULL, title TEXT NOT NULL, icon TEXT NOT NULL DEFAULT 'star', coins INTEGER NOT NULL DEFAULT 10, repeat_rule TEXT NOT NULL DEFAULT 'once', days TEXT NOT NULL DEFAULT '', due_label TEXT NULL, needs_approval INTEGER NOT NULL DEFAULT 1, assignee_child_id TEXT NULL, active INTEGER NOT NULL DEFAULT 1, due_time_local TEXT NULL)",
  "CREATE TABLE rewards (id TEXT NOT NULL PRIMARY KEY, family_id TEXT NOT NULL, title TEXT NOT NULL, icon TEXT NOT NULL DEFAULT 'gift', coin_price INTEGER NOT NULL, needs_ok INTEGER NOT NULL DEFAULT 1)",
  'CREATE TABLE quest_completions (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT)',
];

/// Seed insertion order (the display order — never alphabetical).
const List<String> _seedOrder = <String>[
  'q-dishwasher',
  'q-reading',
  'q-bins',
  'q-tidy',
  'q-hoover',
  'q-table',
  'q-bed',
  'q-biscuit',
  'q-bag',
  'q-plants',
  'q-washing',
  'q-living',
];

void main() {
  group('quest creation order (schema v4)', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.memory();
      await Seed.demo(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('seed demo lists the Active quests in creation order', () async {
      final quests = await db.watchActiveQuests('fam1').first;
      expect(quests, hasLength(12));
      expect(quests.map((q) => q.id), _seedOrder);
      // Staggered one second apart, oldest first, stamped in London.
      for (var i = 1; i < quests.length; i++) {
        expect(
          quests[i].createdAt.isAfter(quests[i - 1].createdAt),
          isTrue,
          reason:
              '${quests[i].id} must be created after '
              '${quests[i - 1].id}',
        );
      }
      for (final quest in quests) {
        expect(quest.createdAtTz, 'Europe/London');
      }
    });

    test(
      'a quest added later sorts last, even an alphabetical first',
      () async {
        // 'a-aaa' sorts before every seed id and title: alphabetical order
        // would put this row first, creation order puts it last. The
        // column default (`currentDateAndTime`) stamps it after every
        // seed instant.
        await db
            .into(db.quests)
            .insert(
              QuestsCompanion.insert(
                id: 'a-aaa',
                familyId: 'fam1',
                title: 'AAA first quest',
              ),
            );
        final quests = await db.watchActiveQuests('fam1').first;
        expect(quests, hasLength(13));
        expect(quests.last.id, 'a-aaa');
        expect(quests.map((q) => q.id).take(12), _seedOrder);
      },
    );

    test('deactivating a quest keeps the order of the rest', () async {
      await (db.update(db.quests)..where((q) => q.id.equals('q-bins'))).write(
        const QuestsCompanion(active: Value(false)),
      );
      final quests = await db.watchActiveQuests('fam1').first;
      expect(quests, hasLength(11));
      expect(quests.map((q) => q.id), _seedOrder.where((id) => id != 'q-bins'));
    });
  });

  group('v3 → v4 migration', () {
    test(
      'backfills created_at in rowid order and orders the Active list',
      () async {
        final dir = await Directory.systemTemp.createTemp('nestling-mig4');
        final file = File('${dir.path}/nestling.db');
        try {
          // Raw sqlite: v3 tables, two quests inserted Zebra-then-Apple,
          // stamp user_version = 3 so the v4 open must run onUpgrade.
          final raw = sqlite.sqlite3.open(file.path)
            ..execute('PRAGMA foreign_keys = OFF;');
          _v3Ddl.forEach(raw.execute);
          raw
            ..execute(
              'INSERT INTO quests (id, family_id, title) VALUES '
              "('q-zebra', 'fam1', 'Zebra quest')",
            )
            ..execute(
              'INSERT INTO quests (id, family_id, title) VALUES '
              "('q-apple', 'fam1', 'Apple quest')",
            )
            ..execute('PRAGMA user_version = 3;')
            ..close();

          final db = AppDatabase(NativeDatabase(file));
          try {
            // Backfilled zones default to London.
            final rows = await db.select(db.quests).get();
            expect(rows, hasLength(2));
            for (final row in rows) {
              expect(row.createdAtTz, 'Europe/London');
            }
            // Rowid order kept: Zebra (inserted first) predates Apple even
            // though 'Apple' < 'Zebra' alphabetically.
            final byId = {for (final r in rows) r.id: r};
            expect(
              byId['q-zebra']!.createdAt.isBefore(byId['q-apple']!.createdAt),
              isTrue,
            );
            // …and the Active list follows creation order, not title order.
            final active = await db.watchActiveQuests('fam1').first;
            expect(active.map((q) => q.id), ['q-zebra', 'q-apple']);
          } finally {
            await db.close();
          }
        } finally {
          await dir.delete(recursive: true);
        }
      },
    );
  });
}
