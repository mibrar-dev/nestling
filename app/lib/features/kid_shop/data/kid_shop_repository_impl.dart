import 'package:drift/drift.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/data/stream_combine.dart';
import 'package:nestling/features/kid_shop/domain/entities/shop_reward.dart';
import 'package:nestling/features/kid_shop/domain/kid_shop_repository.dart';

/// Drift-backed [KidShopRepository].
class KidShopRepositoryImpl implements KidShopRepository {
  new({required this._db});

  final AppDatabase _db;

  @override
  Future<List<ShopReward>> getItems() => watchItems().first;

  @override
  Stream<List<ShopReward>> watchItems() async* {
    final state = await (_db.select(
      _db.appState,
    )..where((a) => a.id.equals(1))).getSingleOrNull();
    yield* watchShop(state?.activeChildId ?? 'maya');
  }

  @override
  Stream<List<ShopReward>> watchShop(String childId) {
    return combineLatest2(
      _db.watchRewards(Seed.familyId),
      _db.watchChild(childId),
    ).map((parts) {
      final rewards = parts[0] as List<Reward>;
      final kid = parts[1] as ChildrenData?;
      final coins = kid?.coins ?? 0;
      return rewards
          .map(
            (r) => ShopReward(
              id: r.id,
              title: r.title,
              detail: '${r.coinPrice} coins',
              icon: r.icon,
              coinPrice: r.coinPrice,
              needsOk: r.needsOk,
              affordable: coins >= r.coinPrice,
            ),
          )
          .toList();
    });
  }

  @override
  Future<void> requestReward(String childId, String rewardId) async {
    final reward = await (_db.select(
      _db.rewards,
    )..where((r) => r.id.equals(rewardId))).getSingleOrNull();
    if (reward == null) return;
    final status = reward.needsOk ? 'requested' : 'approved';
    final now = DateTime.now().toUtc();
    final zone = await _db.familyZoneId();
    await _db.transaction(() async {
      await _db
          .into(_db.rewardRedemptions)
          .insert(
            RewardRedemptionsCompanion.insert(
              rewardId: rewardId,
              childId: childId,
              familyId: Seed.familyId,
              status: Value(status),
              createdAt: Value(now),
              createdAtTz: Value(zone),
            ),
          );
      if (!reward.needsOk) {
        await _spendCoins(childId, reward.coinPrice, now);
      }
    });
  }

  Future<void> _spendCoins(String childId, int coins, DateTime now) async {
    final kid = await (_db.select(
      _db.children,
    )..where((c) => c.id.equals(childId))).getSingleOrNull();
    if (kid == null || kid.coins < coins) return;
    await (_db.update(_db.children)..where((c) => c.id.equals(childId))).write(
      ChildrenCompanion(coins: Value(kid.coins - coins)),
    );
  }
}
