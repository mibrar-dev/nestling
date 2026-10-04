// K08 repository tests (DB-backed, Seed.demo): the shop-stream contract.
//
// `watchActiveShop` emits the active child (demo seed: Maya, 120 coins) plus
// the six rewards in CREATION order (oldest first — never price order) with
// per-item affordability, and follows `app_state.activeChildId` switches.
// `requestReward` writes a `reward_redemptions` row: `requested` with coins
// untouched for needsOk rewards, `approved` with coins deducted for instant
// ones; unknown ids are a no-op.

import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/kid_shop/data/kid_shop_repository_impl.dart';
import 'package:nestling/features/kid_shop/domain/entities/kid_shop_data.dart';

const List<String> _creationOrder = <String>[
  'r-screen',
  'r-film',
  'r-bedtime',
  'r-baking',
  'r-cafe',
  'r-dinner',
];

/// Collects the shop stream's emissions so a test can await the one a write
/// provokes. `package:async`'s `StreamQueue` is not a declared dependency, so
/// the queue is local — and it never waits more than [next]'s bounded retry
/// loop, so a stream that never emits fails fast instead of hanging.
class _ShopEmissions {
  _ShopEmissions(Stream<KidShopData> stream) {
    _sub = stream.listen(_events.add, onError: _errors.add);
  }

  late final StreamSubscription<KidShopData> _sub;
  final List<KidShopData> _events = <KidShopData>[];
  final List<Object> _errors = <Object>[];

  List<Object> get errors => List<Object>.unmodifiable(_errors);

  bool get hasPending => _events.isNotEmpty;

  Future<KidShopData> next() async {
    for (var i = 0; i < 30; i++) {
      if (_events.isNotEmpty) return _events.removeAt(0);
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    throw StateError('no shop emission arrived within 300 ms');
  }

  /// Gives a stray emission every chance to show up, then reports the queue.
  Future<List<KidShopData>> settle() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return List<KidShopData>.of(_events);
  }

  Future<void> cancel() => _sub.cancel();
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.memory();
    await Seed.demo(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> setActiveChild(String childId) {
    return (db.update(db.appState)..where((a) => a.id.equals(1))).write(
      AppStateCompanion(activeChildId: Value(childId)),
    );
  }

  Future<void> setCoins(String childId, int coins) {
    return (db.update(db.children)..where((c) => c.id.equals(childId))).write(
      ChildrenCompanion(coins: Value(coins)),
    );
  }

  Future<void> makeInstant(AppDatabase db, String rewardId) {
    return (db.update(db.rewards)..where((r) => r.id.equals(rewardId))).write(
      const RewardsCompanion(needsOk: Value(false)),
    );
  }

  Future<void> addReward({
    required String id,
    required String title,
    required int price,
    required DateTime createdAt,
    String icon = 'gift',
    bool needsOk = true,
  }) {
    return db
        .into(db.rewards)
        .insert(
          RewardsCompanion.insert(
            id: id,
            familyId: Seed.familyId,
            title: title,
            icon: Value(icon),
            coinPrice: price,
            needsOk: Value(needsOk),
            createdAt: Value(createdAt),
            createdAtTz: const Value('Europe/London'),
          ),
        );
  }

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

  // The live (post-first-emission) switches are what `_switchMap` exists for:
  // `asyncExpand` would stall here forever, because Drift watch streams never
  // close. Each of these mutates the database AFTER the subscription is live.
  group('KidShopRepository live re-emission (K08)', () {
    late KidShopRepositoryImpl repo;
    late _ShopEmissions shop;

    setUp(() {
      repo = KidShopRepositoryImpl(db: db);
      shop = _ShopEmissions(repo.watchActiveShop());
    });

    tearDown(() => shop.cancel());

    test('follows an active-child switch after the first emission', () async {
      expect((await shop.next()).childId, 'maya');

      await setActiveChild('leo');

      final second = await shop.next();
      expect(second.childId, 'leo');
      expect(second.coins, 45);
      expect(second.items.map((item) => item.id).toList(), _creationOrder);
      expect(second.items.every((item) => !item.affordable), isTrue);
    });

    test('flips affordability when the balance changes', () async {
      expect((await shop.next()).coins, 120);
      await setCoins('maya', 10);
      final next = await shop.next();
      expect(next.coins, 10);
      expect(
        <String, bool>{for (final item in next.items) item.id: item.affordable},
        <String, bool>{for (final id in _creationOrder) id: false},
        reason: '10 coins buys nothing (cheapest card is 50)',
      );
    });

    test('a reward added later lands at the END of the list', () async {
      expect((await shop.next()).items, hasLength(6));
      await addReward(
        id: 'r-new',
        title: 'Trip to the skate park',
        price: 40,
        createdAt: Seed.utc(9, 19, 9),
      );
      final next = await shop.next();
      expect(next.items.map((item) => item.id).toList(), <String>[
        ..._creationOrder,
        'r-new',
      ]);
      expect(next.items.last.title, 'Trip to the skate park');
      expect(next.items.last.affordable, isTrue);
    });

    test('an instant reward streams the new balance straight back', () async {
      expect((await shop.next()).coins, 120);

      await repo.requestReward('maya', 'r-baking');

      final after = await shop.next();
      expect(after.coins, 20);
      expect(after.childId, 'maya');
      expect(after.items.map((item) => item.id).toList(), _creationOrder);
      expect(
        after.items.every((item) => !item.affordable),
        isTrue,
        reason: '20 coins is under the cheapest 50-coin card',
      );
    });

    test('a needsOk request leaves the displayed shop untouched', () async {
      await shop.next();
      await repo.requestReward('maya', 'r-screen');

      expect(
        await shop.settle(),
        isEmpty,
        reason:
            'nothing the card shows changes: the balance stays 120, so the '
            'pill, the prices and the affordability are all identical',
      );
      expect(await redemptionsFor('r-screen'), hasLength(1));
    });

    test(
      'a write to the switched-away child produces no stale emission',
      () async {
        await shop.next();
        await setActiveChild('leo');
        expect((await shop.next()).childId, 'leo');
        // Drain the switch burst before the write under test.
        await shop.settle();

        await setCoins('maya', 5);

        expect(
          (await shop.settle()).where((data) => data.childId != 'leo'),
          isEmpty,
          reason: 'the stream is bound to the active child only',
        );
        expect(shop.errors, isEmpty);
      },
    );
  });

  group('KidShopRepository legacy watchShop (K08)', () {
    test(
      'returns the same items in creation order for an explicit child',
      () async {
        final repo = KidShopRepositoryImpl(db: db);
        final items = await repo.watchShop('leo').first;
        expect(items.map((item) => item.id).toList(), _creationOrder);
        expect(items.every((item) => !item.affordable), isTrue);
      },
    );
  });

  group('KidShopRepository on an empty family (K08)', () {
    test('Seed.empty has no rewards and no active child', () async {
      await Seed.empty(db);
      final repo = KidShopRepositoryImpl(db: db);

      final data = await repo.watchActiveShop().first;

      expect(data.items, isEmpty, reason: 'nothing to buy yet');
      expect(data.coins, 0, reason: 'no child row, so no balance');
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

    test(
      'an instant reward beyond the balance is left requested (K08-BUG-1)',
      () async {
        final repo = KidShopRepositoryImpl(db: db);
        await makeInstant(db, 'r-screen'); // 50, now instant like r-baking

        await repo.requestReward('maya', 'r-baking'); // 100 of 120 → approved
        expect((await child('maya')).coins, 20);

        await repo.requestReward('maya', 'r-screen'); // 50 — NOT covered

        final baking = await redemptionsFor('r-baking');
        expect(baking.single.status, 'approved');
        final screen = await redemptionsFor('r-screen');
        expect(screen, hasLength(1));
        expect(
          screen.single.status,
          'requested',
          reason:
              'payment is a precondition of the approved row: an uncovered '
              'instant reward waits for a grown-up instead of landing approved '
              'unpaid',
        );
        expect((await child('maya')).coins, 20);
      },
    );

    test('unknown reward is a no-op', () async {
      final repo = KidShopRepositoryImpl(db: db);

      await repo.requestReward('maya', 'r-nope');

      expect(await db.select(db.rewardRedemptions).get(), isEmpty);
      expect((await child('maya')).coins, 120);
    });

    test('two requests for the same reward write two rows', () async {
      final repo = KidShopRepositoryImpl(db: db);

      // The repository is write-per-request: the shop screen is the only
      // caller, and the bloc's `requestingIds` guard is what swallows a
      // same-frame double tap (proved end-to-end in
      // `reward_shop_view_test.dart`). This test pins the write-per-request
      // behaviour underneath that guard.
      await repo.requestReward('maya', 'r-screen');
      await repo.requestReward('maya', 'r-screen');

      expect(await redemptionsFor('r-screen'), hasLength(2));
      expect(
        (await child('maya')).coins,
        120,
        reason: 'needsOk spends nothing',
      );
    });
  });
}
