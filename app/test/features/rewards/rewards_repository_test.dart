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
      'watchItems emits the 6 demo rewards in ascending price order',
      () async {
        final items = await repository.watchItems().first;

        expect(items.map((item) => item.id).toList(), <String>[
          'r-screen',
          'r-bedtime',
          'r-film',
          'r-dinner',
          'r-baking',
          'r-cafe',
        ]);
        expect(items.map((item) => item.coinPrice).toList(), <int>[
          50,
          60,
          80,
          90,
          100,
          150,
        ]);
        expect(items.map((item) => item.title).toList(), <String>[
          '30 min extra screen time',
          'Stay up 15 min later',
          'Pick Friday film',
          'Choose dinner',
          'Baking together',
          'Trip to the park café',
        ]);
        // DATA OVER MOCKS: the seed leaves every toggle ON.
        expect(items.every((item) => item.needsOk), isTrue);
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
      await repository.setNeedsOk(id: 'r-baking', needsOk: false);

      final items = await repository.watchItems().first;
      expect(
        items.firstWhere((item) => item.id == 'r-baking').needsOk,
        isFalse,
      );
      expect(
        items
            .where((item) => item.id != 'r-baking')
            .every((item) => item.needsOk),
        isTrue,
      );

      await repository.setNeedsOk(id: 'r-baking', needsOk: true);
      expect(
        (await repository.watchItems().first).every((item) => item.needsOk),
        isTrue,
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
      // Price order puts 70 coins between 60 and 80.
      expect(items.map((item) => item.coinPrice).toList(), <int>[
        50,
        60,
        70,
        80,
        90,
        100,
        150,
      ]);
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
      // The repriced row sorts last.
      expect(items.last.id, 'r-screen');
    });

    test('deleteReward removes the row', () async {
      await repository.deleteReward('r-cafe');

      final items = await repository.watchItems().first;
      expect(items.length, 5);
      expect(items.any((item) => item.id == 'r-cafe'), isFalse);
    });
  });
}
