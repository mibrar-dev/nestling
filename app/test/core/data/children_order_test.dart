// Child creation order (CHILD ORDER ruling, shared batch 2).
//
// The `children` table carries `created_at` (+ `created_at_tz`, schema v3)
// and `watchChildren` sorts by creation order — Maya before Leo in the seed
// — never alphabetically. Covers: the v2 → v3 migration backfill (rowid
// order), the seeded order, and a later-added child sorting last.

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

/// Minimal v2 DDL: every table `beforeOpen` touches (v1 shape is enough —
/// the v2 → v3 open only runs the v3 step) plus `children` in its exact v2
/// shape (every column except `created_at` / `created_at_tz`).
const List<String> _v2Ddl = <String>[
  "CREATE TABLE families (id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL DEFAULT 'Nestling', payout_day INTEGER NOT NULL DEFAULT 6, coin_value_pence_per_coin INTEGER NOT NULL DEFAULT 1, pocket_money_mode TEXT NOT NULL DEFAULT 'both')",
  'CREATE TABLE children (id TEXT NOT NULL PRIMARY KEY, family_id TEXT NOT NULL, nickname TEXT NOT NULL, age_band TEXT NOT NULL DEFAULT "7-9", age_years INTEGER NOT NULL DEFAULT 7, avatar_colour TEXT NOT NULL DEFAULT "lilac", pin_hash TEXT NULL, pip_style TEXT NOT NULL DEFAULT "mochi", pip_skin TEXT NOT NULL DEFAULT "sunny", pip_accessory TEXT NOT NULL DEFAULT "none", pip_stage INTEGER NOT NULL DEFAULT 1, pip_total_coins INTEGER NOT NULL DEFAULT 0, coins INTEGER NOT NULL DEFAULT 0, happiness INTEGER NOT NULL DEFAULT 4, happy_days INTEGER NOT NULL DEFAULT 0, weekly_base_pence INTEGER NOT NULL DEFAULT 0)',
  "CREATE TABLE settings (family_id TEXT NOT NULL PRIMARY KEY, pocket_money_mode TEXT NOT NULL DEFAULT 'both', payout_day INTEGER NOT NULL DEFAULT 6, coin_value_pence_per_coin INTEGER NOT NULL DEFAULT 1, notif_approvals INTEGER NOT NULL DEFAULT 1, notif_payout INTEGER NOT NULL DEFAULT 1, notif_summary INTEGER NOT NULL DEFAULT 1, crash_report_consent INTEGER NOT NULL DEFAULT 0, kid_gate_enabled INTEGER NOT NULL DEFAULT 1)",
  "CREATE TABLE app_state (id INTEGER NOT NULL PRIMARY KEY, onboarding_complete INTEGER NOT NULL DEFAULT 0, subscription_status TEXT NOT NULL DEFAULT 'trial', trial_start INTEGER NULL, active_child_id TEXT NULL, app_mode TEXT NOT NULL DEFAULT 'parent')",
];

void main() {
  group('child creation order (schema v3)', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.memory();
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'seed demo lists Maya then Leo (creation, not alphabetical)',
      () async {
        await Seed.demo(db);
        final kids = await db.watchChildren('fam1').first;
        expect(kids.map((k) => k.id), ['maya', 'leo']);
        expect(kids.map((k) => k.nickname), ['Maya', 'Leo']);
        expect(kids.first.createdAt.isBefore(kids.last.createdAt), isTrue);
        expect(kids.first.createdAtTz, 'Europe/London');
      },
    );

    test(
      'a child added later appears last, even an alphabetical first',
      () async {
        await Seed.demo(db);
        // 'Aaron' sorts before every seed name: alphabetical order would put
        // this row first, creation order puts it last. The default
        // `created_at` (now) is after both seed instants.
        await db
            .into(db.children)
            .insert(
              ChildrenCompanion.insert(
                id: 'aaron',
                familyId: 'fam1',
                nickname: 'Aaron',
              ),
            );
        final kids = await db.watchChildren('fam1').first;
        expect(kids.map((k) => k.id), ['maya', 'leo', 'aaron']);
      },
    );
  });

  group('v2 → v3 migration', () {
    test(
      'backfills created_at in rowid order and reorders the roster',
      () async {
        final dir = await Directory.systemTemp.createTemp('nestling-mig3');
        final file = File('${dir.path}/nestling.db');
        try {
          // Raw sqlite: v2 tables, two children inserted Zara-then-Amy, stamp
          // user_version = 2 so the v3 open must run onUpgrade (not onCreate).
          final raw = sqlite.sqlite3.open(file.path)
            ..execute('PRAGMA foreign_keys = OFF;');
          _v2Ddl.forEach(raw.execute);
          raw
            ..execute(
              'INSERT INTO children (id, family_id, nickname) VALUES '
              "('zara', 'fam1', 'Zara')",
            )
            ..execute(
              'INSERT INTO children (id, family_id, nickname) VALUES '
              "('amy', 'fam1', 'Amy')",
            )
            ..execute('PRAGMA user_version = 2;')
            ..close();

          final db = AppDatabase(NativeDatabase(file));
          try {
            // Backfilled zones default to London.
            final rows = await db.select(db.children).get();
            expect(rows, hasLength(2));
            for (final row in rows) {
              expect(row.createdAtTz, 'Europe/London');
            }
            // Rowid order kept: Zara (inserted first) predates Amy even
            // though 'Amy' < 'Zara' alphabetically.
            final byId = {for (final r in rows) r.id: r};
            expect(
              byId['zara']!.createdAt.isBefore(byId['amy']!.createdAt),
              isTrue,
            );
            // …and the roster follows creation order, not the name order.
            final roster = await db.watchChildren('fam1').first;
            expect(roster.map((r) => r.id), ['zara', 'amy']);
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
