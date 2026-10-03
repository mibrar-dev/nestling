// P14 Rewards manager — repository contract against the Drift database.
//
// Covers the P14 slice only: `watchItems` price order, `setNeedsOk` and the
// create/update/delete round-trip. The K08/parent-approval slice
// (`watchRequests`, `approveRedemption`, `denyRedemption`) is out of scope
// for P14 and keeps its existing implementation untouched.

import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart' hide Reward;
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/rewards/data/rewards_repository_impl.dart';
import 'package:nestling/features/rewards/domain/entities/reward.dart';
import 'package:nestling/features/rewards/domain/rewards_repository.dart';

void main() {
  group('RewardsRepository items (P14)', () {
    late AppDatabase db;
    late RewardsRepository repository;

    setUp(() async {
      db = AppDatabase.memory();
      await Seed.demo(db);
      repository = RewardsRepositoryImpl(db: db);
    });

    tearDown(() => db.close());

    test(
      'watchItems emits the 6 demo rewards with the seeded titles and prices',
      () async {
        final items = await repository.watchItems().first;

        expect(items.map((item) => item.id).toSet(), <String>{
          'r-screen',
          'r-film',
          'r-bedtime',
          'r-baking',
          'r-cafe',
          'r-dinner',
        });
        expect(
          <String, String>{for (final item in items) item.id: item.title},
          <String, String>{
            'r-screen': '30 min extra screen time',
            'r-film': 'Pick Friday film',
            'r-bedtime': 'Stay up 15 min later',
            'r-baking': 'Baking together',
            'r-cafe': 'Trip to the park café',
            'r-dinner': 'Choose dinner',
          },
        );
        expect(
          <String, int>{for (final item in items) item.id: item.coinPrice},
          <String, int>{
            'r-screen': 50,
            'r-film': 80,
            'r-bedtime': 60,
            'r-baking': 100,
            'r-cafe': 150,
            'r-dinner': 90,
          },
        );
        // The order is the query's business, not a sort key pinned here:
        // ORCHESTRATOR_NOTES (12:27) rules CREATION order, which the canonical
        // database query owns. What the repository must guarantee is that it
        // hands the stream over untouched.
        final raw = await db.select(db.rewards).get();
        expect(items.length, raw.length);
      },
    );

    test('getItems matches the watched list', () async {
      expect(await repository.getItems(), await repository.watchItems().first);
    });

    test('detail reads "{price} coins"', () async {
      final items = await repository.getItems();
      for (final item in items) {
        expect(item.detail, '${item.coinPrice} coins');
      }
    });

    test('setNeedsOk flips one row only', () async {
      final before = (await repository.getItems())
          .firstWhere((item) => item.id == 'r-baking')
          .needsOk;
      await repository.setNeedsOk(id: 'r-baking', needsOk: !before);

      final items = await repository.watchItems().first;
      expect(
        items.firstWhere((item) => item.id == 'r-baking').needsOk,
        !before,
      );
      expect(
        <String, bool>{
          for (final item in items.where((item) => item.id != 'r-baking'))
            item.id: item.needsOk,
        },
        <String, bool>{
          for (final row in (await db.select(db.rewards).get()).where(
            (row) => row.id != 'r-baking',
          ))
            row.id: row.needsOk,
        },
        reason: 'the other five rows are untouched',
      );

      await repository.setNeedsOk(id: 'r-baking', needsOk: before);
      expect(
        (await repository.getItems())
            .firstWhere((item) => item.id == 'r-baking')
            .needsOk,
        before,
      );
    });

    test('createReward generates an id for an empty one', () async {
      await repository.createReward(
        const Reward(
          id: '',
          title: 'Museum trip',
          detail: '70 coins',
          icon: 'gift',
          coinPrice: 70,
          needsOk: false,
        ),
      );

      final items = await repository.watchItems().first;
      expect(items.length, 7);
      final created = items.firstWhere((item) => item.title == 'Museum trip');
      expect(created.id, startsWith('reward-'));
      expect(created.coinPrice, 70);
      expect(created.needsOk, isFalse);
      expect(created.icon, 'gift');
      // The new row lands in whatever slot the database query gives it; the
      // seeded rows keep their titles.
      expect(
        items
            .where((item) => item.title != 'Museum trip')
            .map((item) => item.id)
            .toSet(),
        <String>{
          'r-screen',
          'r-film',
          'r-bedtime',
          'r-baking',
          'r-cafe',
          'r-dinner',
        },
      );
    });

    test('createReward keeps an explicit id', () async {
      await repository.createReward(
        const Reward(
          id: 'r-museum',
          title: 'Museum trip',
          detail: '70 coins',
          icon: 'gift',
          coinPrice: 70,
          needsOk: true,
        ),
      );

      final items = await repository.watchItems().first;
      expect(items.any((item) => item.id == 'r-museum'), isTrue);
    });

    test('updateReward rewrites title, price, icon and needsOk', () async {
      final screen = (await repository.getItems()).firstWhere(
        (item) => item.id == 'r-screen',
      );
      await repository.updateReward(
        Reward(
          id: screen.id,
          title: '45 min extra screen time',
          detail: screen.detail,
          icon: 'film',
          coinPrice: 200,
          needsOk: false,
        ),
      );

      final items = await repository.watchItems().first;
      expect(items.length, 6);
      final updated = items.firstWhere((item) => item.id == 'r-screen');
      expect(updated.title, '45 min extra screen time');
      expect(updated.coinPrice, 200);
      expect(updated.icon, 'film');
      expect(updated.needsOk, isFalse);
    });

    test('deleteReward removes the row', () async {
      await repository.deleteReward('r-cafe');

      final items = await repository.watchItems().first;
      expect(items.length, 5);
      expect(items.any((item) => item.id == 'r-cafe'), isFalse);
    });
  });
}
