// Shared unique-id contract (shared/unique_ids, P09 BUG-P09-14).
//
// Ids must be unique regardless of the clock: under the pinned test clock
// (`Seed.anchorOverride`, `appNowUtc()` fixed) two inserts in a row used to
// mint the same `…-<ms>` primary key and Drift threw a UNIQUE violation.
// `newId(prefix)` is crypto-random, so back-to-back creates succeed with
// distinct ids.

import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/ids.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/family/data/family_repository_impl.dart';
import 'package:nestling/features/rewards/data/rewards_repository_impl.dart';
import 'package:nestling/features/rewards/domain/entities/reward.dart'
    as reward_domain;

void main() {
  group('newId', () {
    test('returns 10k distinct values', () {
      final ids = <String>{for (var i = 0; i < 10000; i++) newId('q')};
      expect(ids, hasLength(10000));
    });

    test('keeps the prefix and uuid shape', () {
      final id = newId('reward');
      expect(id.startsWith('reward-'), isTrue);
      // 'reward-' + 8-4-4-4-12 uuid hex.
      expect(
        id,
        matches(RegExp(r'^reward-[0-9a-f]{8}-.*-.*-.*-[0-9a-f]{12}$')),
      );
      expect(newId('child'), startsWith('child-'));
    });
  });

  group('pinned clock back-to-back creates', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.memory();
      await Seed.demo(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('two rewards in a row succeed with distinct ids', () async {
      final rewards = RewardsRepositoryImpl(db: db);
      const template = reward_domain.Reward(
        id: '',
        title: 'Extra film night',
        detail: '25 coins',
        icon: 'film',
        coinPrice: 25,
        needsOk: true,
      );
      await rewards.createReward(template);
      await rewards.createReward(template);
      final items = await rewards.watchItems().first;
      // Seed holds 6 rewards; both creates land on top.
      expect(items, hasLength(8));
      final created = items
          .where((r) => r.title == 'Extra film night')
          .map((r) => r.id)
          .toList();
      expect(created, hasLength(2));
      expect(created[0], isNot(created[1]));
    });

    test('two children in a row succeed with distinct ids', () async {
      final family = FamilyRepositoryImpl(db: db);
      await family.addChild(
        nickname: 'Noah',
        ageBand: '4-6',
        avatarColour: 'sky',
      );
      await family.addChild(
        nickname: 'Ava',
        ageBand: '7-9',
        avatarColour: 'leaf',
      );
      final kids = await family.watchChildren().first;
      // Seed holds Maya + Leo; both creates land on top.
      expect(kids, hasLength(4));
      final noah = kids.firstWhere((k) => k.nickname == 'Noah');
      final ava = kids.firstWhere((k) => k.nickname == 'Ava');
      expect(noah.id, isNot(ava.id));
    });

    test('two co-parents in a row succeed with distinct ids', () async {
      final family = FamilyRepositoryImpl(db: db);
      final before = await family.watchItems().first;
      await family.inviteCoParent('Alex');
      await family.inviteCoParent('Sam');
      final members = await family.watchItems().first;
      expect(members, hasLength(before.length + 2));
      final alex = members.where((m) => m.name == 'Alex').toList();
      final sam = members.where((m) => m.name == 'Sam').toList();
      expect(alex, hasLength(1));
      expect(sam, hasLength(1));
      expect(alex.single.id, isNot(sam.single.id));
    });
  });
}
