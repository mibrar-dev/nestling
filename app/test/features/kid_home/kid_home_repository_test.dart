// K01 repository tests (DB-backed, Seed.demo): the picker roster contract.
//
// `watchProfiles` returns children in creation order (Maya, then Leo —
// never alphabetical) with the K01 display fields (`ageBand`, Pip look,
// `pinSet`), and `setActiveChild` persists the tapped profile to
// `app_state.activeChildId` so the PIN / home routes resolve it.

import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/components/audience.dart';
import 'package:nestling/core/design_system/components/quest_icons.dart';
import 'package:nestling/features/kid_home/data/kid_home_repository_impl.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.memory();
    await Seed.demo(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('K01 profiles', () {
    test('watchProfiles lists Maya then Leo with K01 fields', () async {
      final repo = KidHomeRepositoryImpl(db: db);
      final profiles = await repo.watchProfiles().first;

      expect(profiles.map((child) => child.id).toList(), <String>[
        'maya',
        'leo',
      ], reason: 'creation order (Maya added first), never alphabetical');

      final maya = profiles.first;
      expect(maya.nickname, 'Maya');
      expect(maya.ageBand, '7-9');
      expect(maya.avatarColour, 'lilac');
      expect(maya.pipStyle, 'mochi');
      expect(maya.pipSkin, 'sunny');
      expect(maya.pipStage, 3);
      expect(maya.pinSet, isTrue);

      final leo = profiles.last;
      expect(leo.nickname, 'Leo');
      expect(leo.ageBand, '4-6');
      expect(leo.avatarColour, 'peach');
      expect(leo.pipStyle, 'bolt');
      expect(leo.pipSkin, 'sky');
      expect(leo.pipStage, 2);
      expect(leo.pinSet, isFalse);
    });

    test('setActiveChild persists the tapped profile', () async {
      final repo = KidHomeRepositoryImpl(db: db);

      await repo.setActiveChild('leo');
      final state = await (db.select(
        db.appState,
      )..where((a) => a.id.equals(1))).getSingle();
      expect(state.activeChildId, 'leo');

      // …and the combined home stream follows it without a reload.
      final home = await repo.watchHome().first;
      expect(home.child?.id, 'leo');

      await repo.setActiveChild('maya');
      final back = await (db.select(
        db.appState,
      )..where((a) => a.id.equals(1))).getSingle();
      expect(back.activeChildId, 'maya');
    });
  });

  group('K02 PIN verification', () {
    test('Maya accepts 1234 and rejects anything else', () async {
      final repo = KidHomeRepositoryImpl(db: db);
      expect(await repo.verifyPin('maya', '1234'), isTrue);
      expect(await repo.verifyPin('maya', '9999'), isFalse);
      expect(await repo.verifyPin('maya', ''), isFalse);
    });

    test('Leo has no PIN so any code auto-passes', () async {
      final repo = KidHomeRepositoryImpl(db: db);
      expect(await repo.verifyPin('leo', '1234'), isTrue);
      expect(await repo.verifyPin('leo', '0000'), isTrue);
    });
  });

  // K04 ICONS audience guard — data premise (FIXES_3, "the gap I left").
  //
  // The full guard (rendered glyph == kid table) needs the view, which is
  // UI-builder owned; this group pins what the logic layer owns: the
  // database actually serves the icon keys the guard reasons about, and
  // the shared single source distinguishes the audiences on exactly
  // those keys. Read from the DB (DATA OVER MOCKS) — never hard-coded.
  group('K04 ICONS audience guard — data premise', () {
    test('Maya seed quests carry keys covering the divergent set', () async {
      final repo = KidHomeRepositoryImpl(db: db);
      // Seed.demo plays Maya, so watchItems yields her quests directly.
      final items = await repo.watchItems().first;

      final keys = items.map((item) => item.icon).toSet();
      // The audience-divergent keys: the kid table draws its own glyph
      // for exactly these; every other key is shared.
      expect(keys, containsAll(<String>['bed', 'dishwasher', 'book']));
      // Every stored key resolves through the shared single source.
      expect(questIconKeys, containsAll(keys));
    });

    test('questIconFor splits kid from parent on the divergent keys only', () {
      for (final key in <String>[
        'bed',
        'dishwasher',
        'book',
        'reading',
        'bins',
        'bin',
      ]) {
        expect(
          questIconFor(key, audience: NestAudience.kid),
          isNot(questIconFor(key, audience: NestAudience.parent)),
          reason: '$key must render the kid glyph on K04, never the parent',
        );
      }
      for (final key in <String>['hoover', 'plate']) {
        expect(
          questIconFor(key, audience: NestAudience.kid),
          questIconFor(key, audience: NestAudience.parent),
          reason: '$key is shared between audiences',
        );
      }
    });
  });
}
