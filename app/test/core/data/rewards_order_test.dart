// Rewards creation order + seed truth (P14 QA).
//
// The P14 reward list is ordered by reward CREATION order (oldest first) —
// "listed in the order they were added" — not by price or title. `Rewards`
// carries `created_at` (+ `created_at_tz`, schema v5, UTC + IANA zone) and
// `watchRewardsInCreationOrder` sorts by it, then `id`. Covers: the seeded
// order, the P14 "Baking together needs no OK" flag, a later-added reward
// sorting last, the id tie-break, and the v4 → v5 migration backfill
// (rowid order).

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

/// Minimal v4 DDL: `rewards` in its exact v4 shape (every column except
/// `created_at` / `created_at_tz`) plus PK-only stubs for the tables
/// `beforeOpen` touches (the v4 → v5 open only runs the v5 step).
/// `quest_completions` is a PK-only stub: real v4 databases always have it,
/// and the v6 step needs the table to exist.
const List<String> _v4Ddl = <String>[
  'CREATE TABLE families (id TEXT NOT NULL PRIMARY KEY)',
  'CREATE TABLE settings (family_id TEXT NOT NULL PRIMARY KEY)',
  'CREATE TABLE app_state (id INTEGER NOT NULL PRIMARY KEY)',
  "CREATE TABLE members (id TEXT NOT NULL PRIMARY KEY, family_id TEXT NOT NULL, name TEXT NOT NULL, role TEXT NOT NULL DEFAULT 'owner', invite_status TEXT NOT NULL DEFAULT 'active')",
  "CREATE TABLE rewards (id TEXT NOT NULL PRIMARY KEY, family_id TEXT NOT NULL, title TEXT NOT NULL, icon TEXT NOT NULL DEFAULT 'gift', coin_price INTEGER NOT NULL, needs_ok INTEGER NOT NULL DEFAULT 1)",
  'CREATE TABLE quest_completions (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT)',
];

/// Seed insertion order (the P14 display order — never price order).
const List<String> _seedOrder = <String>[
  'r-screen',
  'r-film',
  'r-bedtime',
  'r-baking',
  'r-cafe',
  'r-dinner',
];

void main() {
  group('reward creation order (schema v5)', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.memory();
      await Seed.demo(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('seed demo lists rewards in creation order '
        '(screen, film, bedtime, baking, café, dinner)', () async {
      final rewards = await db.watchRewardsInCreationOrder('fam1').first;
      expect(rewards, hasLength(6));
      expect(rewards.map((r) => r.id), _seedOrder);
      // Staggered one second apart, oldest first, stamped in London.
      for (var i = 1; i < rewards.length; i++) {
        expect(
          rewards[i].createdAt.isAfter(rewards[i - 1].createdAt),
          isTrue,
          reason:
              '${rewards[i].id} must be created after '
              '${rewards[i - 1].id}',
        );
      }
      for (final reward in rewards) {
        expect(reward.createdAtTz, 'Europe/London');
      }
    });

    test('baking needs no OK, every other reward needs OK (P14)', () async {
      final rewards = await db.watchRewardsInCreationOrder('fam1').first;
      for (final reward in rewards) {
        if (reward.id == 'r-baking') {
          expect(reward.needsOk, isFalse);
        } else {
          expect(reward.needsOk, isTrue, reason: '${reward.id} needs OK');
        }
      }
    });

    test(
      'a reward added later sorts last, even a cheaper alphabetical first',
      () async {
        // 'a-aaa' sorts before every seed id and title, and 5 coins is
        // cheaper than every seed price: price order AND id/title order
        // would both put this row first, creation order puts it last. The
        // column default (`currentDateAndTime`) stamps it after every
        // seed instant.
        await db
            .into(db.rewards)
            .insert(
              RewardsCompanion.insert(
                id: 'a-aaa',
                familyId: 'fam1',
                title: 'AAA cheapest reward',
                coinPrice: 5,
              ),
            );
        final rewards = await db.watchRewardsInCreationOrder('fam1').first;
        expect(rewards, hasLength(7));
        expect(rewards.last.id, 'a-aaa');
        expect(rewards.map((r) => r.id).take(6), _seedOrder);
      },
    );

    test('ties on created_at fall back to id order', () async {
      final stamp = DateTime.utc(2027);
      for (final id in <String>['r-b2', 'r-a1']) {
        await db
            .into(db.rewards)
            .insert(
              RewardsCompanion.insert(
                id: id,
                familyId: 'fam1',
                title: 'Tie $id',
                coinPrice: 10,
                createdAt: Value(stamp),
              ),
            );
      }
      final rewards = await db.watchRewardsInCreationOrder('fam1').first;
      expect(rewards, hasLength(8));
      expect(rewards.sublist(6).map((r) => r.id), ['r-a1', 'r-b2']);
    });
  });

  group('v4 → v5 migration', () {
    test('backfills created_at in rowid order and orders the list', () async {
      final dir = await Directory.systemTemp.createTemp('nestling-mig5');
      final file = File('${dir.path}/nestling.db');
      try {
        // Raw sqlite: v4 tables, an expensive reward inserted before a
        // cheap one, stamp user_version = 4 so the v5 open must run
        // onUpgrade.
        final raw = sqlite.sqlite3.open(file.path)
          ..execute('PRAGMA foreign_keys = OFF;');
        _v4Ddl.forEach(raw.execute);
        raw
          ..execute(
            'INSERT INTO rewards (id, family_id, title, coin_price) VALUES '
            "('r-expensive', 'fam1', 'Expensive reward', 500)",
          )
          ..execute(
            'INSERT INTO rewards (id, family_id, title, coin_price) VALUES '
            "('r-cheap', 'fam1', 'Cheap reward', 5)",
          )
          ..execute('PRAGMA user_version = 4;')
          ..close();

        final db = AppDatabase(NativeDatabase(file));
        try {
          // Backfilled zones default to London.
          final rows = await db.select(db.rewards).get();
          expect(rows, hasLength(2));
          for (final row in rows) {
            expect(row.createdAtTz, 'Europe/London');
          }
          // Rowid order kept: Expensive (inserted first) predates Cheap
          // even though 5 < 500 in price order.
          final byId = {for (final r in rows) r.id: r};
          expect(
            byId['r-expensive']!.createdAt.isBefore(byId['r-cheap']!.createdAt),
            isTrue,
          );
          // …and the canonical list follows creation order, not price.
          final ordered = await db.watchRewardsInCreationOrder('fam1').first;
          expect(ordered.map((r) => r.id), ['r-expensive', 'r-cheap']);
        } finally {
          await db.close();
        }
      } finally {
        await dir.delete(recursive: true);
      }
    });
  });
}
