// P16 Settings — repository contract against the Drift database.
//
// Covers the P16 slice: `watchRoster` creation order (Maya then Leo — CHILD
// ORDER ruling, never alphabetical) with Pip stage names and coin balances,
// `watchMembers` insertion order (Sarah then James), the notification
// round-trip, the family-zone write + validation, and the `movedToDubai`
// move fixture (zone flips, stored instants untouched).

import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/settings/data/settings_repository_impl.dart';
import 'package:nestling/features/settings/domain/entities/settings_child_entry.dart';
import 'package:nestling/features/settings/domain/settings_repository.dart';

void main() {
  group('SettingsRepository roster (P16)', () {
    late AppDatabase db;
    late SettingsRepository repository;

    setUp(() async {
      db = AppDatabase.memory();
      await Seed.demo(db);
      repository = SettingsRepositoryImpl(db: db);
    });

    tearDown(() => db.close());

    test('watchRoster lists Maya then Leo in creation order', () async {
      final roster = await repository.watchRoster().first;

      expect(roster.map((entry) => entry.id).toList(), <String>['maya', 'leo']);
      expect(roster.map((entry) => entry.nickname).toList(), <String>[
        'Maya',
        'Leo',
      ]);
    });

    test('watchRoster carries bands, Pip stages, coins and colours', () async {
      final roster = await repository.watchRoster().first;
      final byId = <String, SettingsChildEntry>{
        for (final entry in roster) entry.id: entry,
      };

      expect(byId['maya']!.ageBand, '7-9');
      expect(byId['maya']!.pipStageName, 'Fledgling');
      expect(byId['maya']!.coins, 120);
      expect(byId['maya']!.avatarColour, 'lilac');

      expect(byId['leo']!.ageBand, '4-6');
      expect(byId['leo']!.pipStageName, 'Hatchling');
      expect(byId['leo']!.coins, 45);
      expect(byId['leo']!.avatarColour, 'peach');
    });

    test('settingsPipStageName maps every stored stage', () {
      expect(settingsPipStageName(1), 'Egg');
      expect(settingsPipStageName(2), 'Hatchling');
      expect(settingsPipStageName(3), 'Fledgling');
      expect(settingsPipStageName(4), 'Songbird');
      expect(settingsPipStageName(99), 'Fledgling');
    });

    test('watchMembers lists Sarah then James in insertion order', () async {
      final members = await repository.watchMembers().first;

      expect(members.map((entry) => entry.id).toList(), <String>[
        'sarah',
        'james',
      ]);
      expect(members.first.name, 'Sarah');
      expect(members.first.role, 'owner');
      expect(members.first.inviteStatus, 'active');
      expect(members.last.name, 'James');
      expect(members.last.role, 'co-parent');
      expect(members.last.inviteStatus, 'invited');
    });

    test('empty seed has no roster rows but keeps Sarah', () async {
      await Seed.empty(db);

      expect(await repository.watchRoster().first, isEmpty);
      final members = await repository.watchMembers().first;
      expect(members.map((entry) => entry.id).toList(), <String>['sarah']);
    });

    test('setNotifications flips one toggle only', () async {
      await repository.setNotifications(approvals: false);

      final settings = await repository.watchSettings().first;
      expect(settings.notifApprovals, isFalse);
      expect(settings.notifPayout, isTrue);
      expect(settings.notifSummary, isTrue);

      await repository.setNotifications(approvals: true);
      expect((await repository.watchSettings().first).notifApprovals, isTrue);
    });

    test('writes stamp updatedAt with the app clock (CLOCK rule)', () async {
      await repository.setNotifications(approvals: false);

      // Pinned by flutter_test_config (Sat 3 Oct 2026): the write timestamp
      // comes from appNowUtc(), never the wall clock.
      const pinned = '2026-10-03 08:41:00.000Z';
      final settingRow = await (db.select(
        db.settings,
      )..where((s) => s.familyId.equals(Seed.familyId))).getSingle();
      expect(settingRow.updatedAt?.toUtc().toString(), pinned);
      final familyRow = await (db.select(
        db.families,
      )..where((f) => f.id.equals(Seed.familyId))).getSingle();
      expect(familyRow.updatedAt?.toUtc().toString(), pinned);
    });

    test('setFamilyTimeZone stores the zone and mirrors settings', () async {
      await repository.setFamilyTimeZone('Asia/Dubai');

      expect(await repository.watchFamilyTimeZone().first, 'Asia/Dubai');
      final settingsRow = await (db.select(
        db.settings,
      )..where((s) => s.familyId.equals(Seed.familyId))).getSingle();
      expect(settingsRow.timeZone, 'Asia/Dubai');
    });

    test('setFamilyTimeZone ignores unknown ids', () async {
      await repository.setFamilyTimeZone('Bogus/Zone');

      expect(await repository.watchFamilyTimeZone().first, 'Europe/London');
    });

    test('movedToDubai flips the zone without touching instants', () async {
      Future<List<DateTime>> completionInstants() async {
        final rows = await db.select(db.questCompletions).get();
        return rows.map((row) => row.createdAt).toList();
      }

      final before = await completionInstants();
      await Seed.movedToDubai(db);

      expect(await repository.watchFamilyTimeZone().first, 'Asia/Dubai');
      expect(await completionInstants(), before);
    });
  });
}
