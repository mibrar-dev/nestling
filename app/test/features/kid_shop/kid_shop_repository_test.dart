// K08 repository tests (DB-backed, Seed.demo): the shop-stream contract.
//
// `watchActiveShop` emits the active child (demo seed: Maya, 120 coins) plus
// the six rewards in CREATION order (oldest first — never price order) with
// per-item affordability, and follows `app_state.activeChildId` switches.
// `requestReward` writes a `reward_redemptions` row: `requested` with coins
// untouched for needsOk rewards, `approved` with coins deducted for instant
// ones; unknown ids are a no-op.

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/kid_shop/data/kid_shop_repository_impl.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.memory();
    await Seed.demo(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<ChildrenData> child(String id) {
    return (db.select(db.children)..where((c) => c.id.equals(id))).getSingle();
  }

  Future<List<RewardRedemption>> redemptionsFor(String rewardId) {
    return (db.select(
      db.rewardRedemptions,
    )..where((r) => r.rewardId.equals(rewardId))).get();
  }

  group('KidShopRepository watchActiveShop (K08)', () {
    test('emits Maya with 120 coins and rewards in creation order', () async {
      final repo = KidShopRepositoryImpl(db: db);
      final data = await repo.watchActiveShop().first;

      expect(data.childId, 'maya');
      expect(data.coins, 120);
      expect(data.items.map((item) => item.id).toList(), <String>[
        'r-screen',
        'r-film',
        'r-bedtime',
        'r-baking',
        'r-cafe',
        'r-dinner',
      ], reason: 'creation order (oldest first), never price order');
    });

    test('only the park cafe is unaffordable at 120 coins', () async {
      final repo = KidShopRepositoryImpl(db: db);
      final data = await repo.watchActiveShop().first;

      expect(
        <String, bool>{for (final item in data.items) item.id: item.affordable},
        <String, bool>{
          'r-screen': true,
          'r-film': true,
          'r-bedtime': true,
          'r-baking': true,
          'r-cafe': false,
          'r-dinner': true,
        },
      );
    });

    test('detail reads "{price} coins"', () async {
      final repo = KidShopRepositoryImpl(db: db);
      final data = await repo.watchActiveShop().first;

      expect(
        <String, String>{for (final item in data.items) item.id: item.detail},
        <String, String>{
          'r-screen': '50 coins',
          'r-film': '80 coins',
          'r-bedtime': '60 coins',
          'r-baking': '100 coins',
          'r-cafe': '150 coins',
          'r-dinner': '90 coins',
        },
      );
    });

    test('follows the active child switch (Leo, 45 coins)', () async {
      final repo = KidShopRepositoryImpl(db: db);
      await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
        const AppStateCompanion(activeChildId: Value('leo')),
      );

      final data = await repo.watchActiveShop().first;

      expect(data.childId, 'leo');
      expect(data.coins, 45);
      expect(data.items.map((item) => item.id).toList(), <String>[
        'r-screen',
        'r-film',
        'r-bedtime',
        'r-baking',
        'r-cafe',
        'r-dinner',
      ]);
      // Leo's 45 coins buy nothing: even the cheapest card (50) is out.
      expect(data.items.every((item) => !item.affordable), isTrue);
    });
  });

  group('KidShopRepository requestReward (K08)', () {
    test('needsOk writes requested and leaves coins untouched', () async {
      final repo = KidShopRepositoryImpl(db: db);

      await repo.requestReward('maya', 'r-screen');

      final rows = await redemptionsFor('r-screen');
      expect(rows, hasLength(1));
      expect(rows.single.status, 'requested');
      expect(rows.single.childId, 'maya');
      expect((await child('maya')).coins, 120);
    });

    test('instant writes approved and deducts the price', () async {
      final repo = KidShopRepositoryImpl(db: db);

      await repo.requestReward('maya', 'r-baking');

      final rows = await redemptionsFor('r-baking');
      expect(rows, hasLength(1));
      expect(rows.single.status, 'approved');
      expect((await child('maya')).coins, 20);
    });

    test('unknown reward is a no-op', () async {
      final repo = KidShopRepositoryImpl(db: db);

      await repo.requestReward('maya', 'r-nope');

      expect(await db.select(db.rewardRedemptions).get(), isEmpty);
      expect((await child('maya')).coins, 120);
    });
  });
}
