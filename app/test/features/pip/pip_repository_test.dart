// K06 repository tests (DB-backed, Seed.demo): the nest contract.
//
// `watchNest` emits the active child's profile plus wardrobe in design
// order (Scarf, Sun hat, Wellies, Crown) with design names and DB prices;
// care actions deduct the K06 prices (feed 5, bath 3, play free), nudge
// happiness (clamped 0..5), and every write is a no-op when coins are
// insufficient (never negative).

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/pip/data/pip_repository_impl.dart';
import 'package:nestling/features/pip/domain/pip_repository.dart';
// `pipStageName` is presentation copy and lives next to the other Pip-look
// helpers in the feature's widget layer (4_review.md #2), not in domain/.
import 'package:nestling/features/pip/presentation/widgets/pip_look.dart';

Future<void> _setMayaCoins(AppDatabase db, int coins) async {
  await (db.update(db.children)..where((c) => c.id.equals('maya'))).write(
    ChildrenCompanion(coins: Value(coins)),
  );
}

void main() {
  late AppDatabase db;
  late PipRepositoryImpl repo;

  setUp(() async {
    db = AppDatabase.memory();
    await Seed.demo(db);
    repo = PipRepositoryImpl(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('watchNest', () {
    test('emits Maya profile with the seed truth', () async {
      final nest = await repo.watchNest().first;
      expect(nest, isNotNull);
      final profile = nest!.profile;
      expect(profile.childId, 'maya');
      expect(profile.nickname, 'Maya');
      expect(profile.style, 'mochi');
      expect(profile.skin, 'sunny');
      expect(profile.accessory, 'none');
      expect(profile.stage, 3);
      expect(profile.totalCoins, 175);
      expect(profile.coins, 120);
      expect(profile.happiness, 4);
      expect(profile.coinsToGrow, 75);
      expect(nest.growthFraction, closeTo(0.7, 0.001));
      expect(pipStageName(profile.stage), 'Fledgling');
    });

    test(
      'emits wardrobe in design order with design names + DB prices',
      () async {
        final nest = await repo.watchNest().first;
        final items = nest!.items;
        expect(items.map((i) => i.id).toList(), <String>[
          'scarf',
          'sunhat',
          'wellies',
          'crown',
        ], reason: 'design order, never alphabetical');
        expect(items.map((i) => i.title).toList(), <String>[
          'Scarf',
          'Sun hat',
          'Wellies',
          'Crown',
        ]);
        expect(items.map((i) => i.owned).toList(), <bool>[
          true,
          true,
          false,
          false,
        ]);
        // Prices come from the DB (wellies 30 / crown 60), never the HTML.
        expect(items.map((i) => i.priceCoins).toList(), <int>[0, 0, 30, 60]);
        expect(items.map((i) => i.detail).toList(), <String>[
          'Owned',
          'Owned',
          '30 coins',
          '60 coins',
        ]);
      },
    );

    test('watchItems serves the same ordered strip (legacy stream)', () async {
      final items = await repo.watchItems().first;
      expect(items.map((i) => i.id).toList(), <String>[
        'scarf',
        'sunhat',
        'wellies',
        'crown',
      ]);
      expect(await repo.getItems(), hasLength(4));
    });

    test('follows the active child (maya -> leo -> none)', () async {
      expect((await repo.watchNest().first)!.profile.childId, 'maya');
      expect(await repo.watchActiveChildId().first, 'maya');

      await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
        const AppStateCompanion(activeChildId: Value('leo')),
      );
      final leo = await repo.watchNest().first;
      expect(leo!.profile.childId, 'leo');
      expect(leo.profile.style, 'bolt');
      expect(leo.profile.skin, 'sky');
      expect(leo.profile.stage, 2);
      expect(await repo.watchActiveChildId().first, 'leo');

      await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
        const AppStateCompanion(activeChildId: Value(null)),
      );
      expect(await repo.watchNest().first, isNull);
      expect(await repo.watchActiveChildId().first, isNull);
    });
  });

  group('care actions', () {
    test('feed deducts 5 coins and +1 happiness', () async {
      await repo.feed('maya');
      final profile = await repo.watchProfile('maya').first;
      expect(profile?.coins, 115);
      expect(profile?.happiness, 5);
    });

    test('play is free and +1 happiness', () async {
      await repo.play('maya');
      final profile = await repo.watchProfile('maya').first;
      expect(profile?.coins, 120);
      expect(profile?.happiness, 5);
    });

    test('bathe deducts 3 coins and +1 happiness', () async {
      await repo.bathe('maya');
      final profile = await repo.watchProfile('maya').first;
      expect(profile?.coins, 117);
      expect(profile?.happiness, 5);
    });

    test('happiness clamps at 5', () async {
      await repo.feed('maya');
      await repo.feed('maya');
      final profile = await repo.watchProfile('maya').first;
      expect(profile?.happiness, 5);
      expect(profile?.coins, 110);
    });

    test('feed and bath with insufficient coins are no-ops', () async {
      await _setMayaCoins(db, 2);
      await repo.feed('maya');
      var profile = await repo.watchProfile('maya').first;
      expect(profile?.coins, 2);
      expect(profile?.happiness, 4);

      await repo.bathe('maya');
      profile = await repo.watchProfile('maya').first;
      expect(profile?.coins, 2);
      expect(profile?.happiness, 4);
    });

    test('care for an unknown child is a no-op', () async {
      await repo.feed('nope');
      final profile = await repo.watchProfile('maya').first;
      expect(profile?.coins, 120);
    });
  });

  group('wardrobe + look', () {
    test('buyItem marks owned and deducts the DB price', () async {
      expect(await repo.buyItem('maya', 'wellies'), PipBuyResult.bought);
      final nest = await repo.watchNest().first;
      final wellies = nest!.items.firstWhere((i) => i.id == 'wellies');
      expect(wellies.owned, isTrue);
      expect(wellies.detail, 'Owned');
      expect(nest.profile.coins, 90);
    });

    test('buyItem unaffordable is a no-op', () async {
      await _setMayaCoins(db, 10);
      expect(await repo.buyItem('maya', 'crown'), PipBuyResult.cannotAfford);
      final nest = await repo.watchNest().first;
      expect(nest!.items.firstWhere((i) => i.id == 'crown').owned, isFalse);
      expect(nest.profile.coins, 10);
    });

    test('buyItem already-owned is a no-op', () async {
      expect(await repo.buyItem('maya', 'scarf'), PipBuyResult.alreadyOwned);
      final profile = await repo.watchProfile('maya').first;
      expect(profile?.coins, 120);
    });

    test('updateLook equips scarf and cap accessories', () async {
      await repo.updateLook(childId: 'maya', accessory: 'scarf');
      expect((await repo.watchProfile('maya').first)?.accessory, 'scarf');
      await repo.updateLook(childId: 'maya', accessory: 'cap');
      expect((await repo.watchProfile('maya').first)?.accessory, 'cap');
    });
  });

  group('atomic writes (K06-BUG-1, K06-BUG-2)', () {
    test('concurrent feeds each charge the current balance', () async {
      await Future.wait(<Future<void>>[
        repo.feed('maya'),
        repo.feed('maya'),
        repo.feed('maya'),
        repo.feed('maya'),
        repo.feed('maya'),
      ]);
      final profile = await repo.watchProfile('maya').first;
      expect(profile?.coins, 95);
      expect(profile?.happiness, 5);
    });

    test('concurrent different-item buys cannot overspend', () async {
      // 70 coins fit only one of Wellies (30) + Crown (60).
      await _setMayaCoins(db, 70);
      final results = await Future.wait(<Future<PipBuyResult>>[
        repo.buyItem('maya', 'wellies'),
        repo.buyItem('maya', 'crown'),
      ]);
      expect(results, contains(PipBuyResult.bought));
      expect(results, contains(PipBuyResult.cannotAfford));
      final nest = await repo.watchNest().first;
      final owned = nest!.items.where((i) => i.owned).length;
      expect(owned, 3); // scarf + sunhat + exactly one purchase.
      expect(nest.profile.coins, greaterThanOrEqualTo(0));
    });

    test('concurrent same-item buys charge exactly once', () async {
      final results = await Future.wait(<Future<PipBuyResult>>[
        repo.buyItem('maya', 'wellies'),
        repo.buyItem('maya', 'wellies'),
      ]);
      expect(results, contains(PipBuyResult.bought));
      final nest = await repo.watchNest().first;
      expect(nest!.items.firstWhere((i) => i.id == 'wellies').owned, isTrue);
      expect(nest.profile.coins, 90);
    });
  });

  group('pipStageName', () {
    test('maps every stage (pip-local helper)', () {
      expect(pipStageName(1), 'Egg');
      expect(pipStageName(2), 'Hatchling');
      expect(pipStageName(3), 'Fledgling');
      expect(pipStageName(4), 'Songbird');
      expect(pipStageName(99), 'Fledgling');
    });
  });
}
