// P16 §4 (shared batch 6): `members.email TEXT NULL` (schema v7).
//
// - v6 → v7 migration keeps every row and backfills NULL.
// - `Seed.demo` sets the owner to `sarah@example.co.uk`, James stays NULL.
// - `AppDatabase.watchMembers` exposes the email in insertion order.

import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

/// Minimal v6 DDL: `members` in its exact v6 shape (every column except
/// `email`) plus stubs for the tables `beforeOpen` touches (the
/// v6 → v7 open only runs the v7 step). The `settings` stub carries the
/// notification columns in their real v6 shape (`DEFAULT 1`): `beforeOpen`
/// writes them explicitly (new-family OFF), so a PK-only stub no longer
/// satisfies the insert.
const List<String> _v6Ddl = <String>[
  'CREATE TABLE families (id TEXT NOT NULL PRIMARY KEY)',
  'CREATE TABLE settings (family_id TEXT NOT NULL PRIMARY KEY, notif_approvals INTEGER NOT NULL DEFAULT 1, notif_payout INTEGER NOT NULL DEFAULT 1, notif_summary INTEGER NOT NULL DEFAULT 1)',
  'CREATE TABLE app_state (id INTEGER NOT NULL PRIMARY KEY)',
  "CREATE TABLE members (id TEXT NOT NULL PRIMARY KEY, family_id TEXT NOT NULL, name TEXT NOT NULL, role TEXT NOT NULL DEFAULT 'owner', invite_status TEXT NOT NULL DEFAULT 'active')",
];

void main() {
  group('members.email seed (schema v7)', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.memory();
      await Seed.demo(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('demo owner carries sarah@example.co.uk, James is NULL', () async {
      final rows = await db.select(db.members).get();
      Member byId(String id) => rows.firstWhere((r) => r.id == id);
      expect(byId('sarah').email, 'sarah@example.co.uk');
      expect(byId('sarah').role, 'owner');
      expect(byId('james').email, isNull);
      expect(byId('james').role, 'co-parent');
      expect(byId('james').inviteStatus, 'invited');
    });

    test(
      'watchMembers exposes email in insertion order (Sarah, James)',
      () async {
        final members = await db.watchMembers().first;
        expect(members.map((m) => m.id).toList(), ['sarah', 'james']);
        expect(members.first.email, 'sarah@example.co.uk');
        expect(members.last.email, isNull);
      },
    );

    test('empty + onboardingKids seeds keep the owner email', () async {
      final emptyDb = AppDatabase.memory();
      try {
        await Seed.empty(emptyDb);
        final emptyRows = await emptyDb.select(emptyDb.members).get();
        expect(emptyRows.single.email, 'sarah@example.co.uk');
      } finally {
        await emptyDb.close();
      }
      final kidsDb = AppDatabase.memory();
      try {
        await Seed.onboardingKids(kidsDb);
        final kidsRows = await kidsDb.select(kidsDb.members).get();
        expect(
          kidsRows.firstWhere((r) => r.id == 'sarah').email,
          'sarah@example.co.uk',
        );
      } finally {
        await kidsDb.close();
      }
    });
  });

  group('v6 → v7 migration', () {
    test('keeps every row and email is NULL', () async {
      final dir = await Directory.systemTemp.createTemp('nestling-mig7');
      final file = File('${dir.path}/nestling.db');
      try {
        // Raw sqlite: v6 tables + rows, stamp user_version = 6 so the v7
        // open must run onUpgrade.
        final raw = sqlite.sqlite3.open(file.path)
          ..execute('PRAGMA foreign_keys = OFF;');
        _v6Ddl.forEach(raw.execute);
        raw
          ..execute(
            "INSERT INTO members (id, family_id, name) VALUES ('sarah', "
            "'fam1', 'Sarah')",
          )
          ..execute(
            'INSERT INTO members (id, family_id, name, role, invite_status) '
            "VALUES ('james', 'fam1', 'James', 'co-parent', 'invited')",
          )
          ..execute('PRAGMA user_version = 6;')
          ..close();

        final db = AppDatabase(NativeDatabase(file));
        try {
          final rows = await db.select(db.members).get();
          expect(rows, hasLength(2));
          for (final row in rows) {
            expect(row.email, isNull, reason: row.id);
          }
          // Name / role / invite_status survive the upgrade untouched.
          final byId = <String, Member>{for (final r in rows) r.id: r};
          expect(byId['sarah']!.name, 'Sarah');
          expect(byId['sarah']!.role, 'owner');
          expect(byId['james']!.inviteStatus, 'invited');

          // New writes can set an email.
          await db
              .into(db.members)
              .insert(
                MembersCompanion.insert(
                  id: 'owner2',
                  familyId: 'fam1',
                  name: 'Sam',
                  email: const Value('sam@example.co.uk'),
                ),
              );
          final after = await db.select(db.members).get();
          expect(after, hasLength(3));
          expect(
            after.firstWhere((r) => r.id == 'owner2').email,
            'sam@example.co.uk',
          );
          // And the migrated rows can gain one later.
          await (db.update(
            db.members,
          )..where((m) => m.id.equals('sarah'))).write(
            const MembersCompanion(email: Value('sarah@example.co.uk')),
          );
          final sarah = await (db.select(
            db.members,
          )..where((m) => m.id.equals('sarah'))).getSingle();
          expect(sarah.email, 'sarah@example.co.uk');
        } finally {
          await db.close();
        }
      } finally {
        await dir.delete(recursive: true);
      }
    });
  });
}
