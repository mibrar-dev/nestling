// K01 repository tests (DB-backed, Seed.demo): the picker roster contract.
//
// `watchProfiles` returns children in creation order (Maya, then Leo —
// never alphabetical) with the K01 display fields (`ageBand`, Pip look,
// `pinSet`), and `setActiveChild` persists the tapped profile to
// `app_state.activeChildId` so the PIN / home routes resolve it.

import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
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
}
