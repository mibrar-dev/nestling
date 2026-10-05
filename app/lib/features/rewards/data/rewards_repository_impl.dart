import 'package:drift/drift.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/current_family.dart';
import 'package:nestling/core/data/ids.dart';
import 'package:nestling/core/data/stream_combine.dart';
import 'package:nestling/features/rewards/domain/entities/reward.dart'
    as domain;
import 'package:nestling/features/rewards/domain/entities/reward_redemption.dart'
    as redemption;
import 'package:nestling/features/rewards/domain/rewards_repository.dart';

/// Drift-backed [RewardsRepository].
class RewardsRepositoryImpl implements RewardsRepository {
  new({required AppDatabase db, CurrentFamily? currentFamily})
    : _db = db,
      _currentFamily = currentFamily ?? CurrentFamily.fallback(db);

  final AppDatabase _db;
  final CurrentFamily _currentFamily;

  String get _familyId => _currentFamily.familyId;

  @override
  Future<List<domain.Reward>> getItems() => watchItems().first;

  @override
  Stream<List<domain.Reward>> watchItems() {
    // Owner rule (ORCHESTRATOR_NOTES 12:27): the P14 list is creation order
    // — the order rewards were added — never price order. The legacy
    // `watchRewards` (coinPrice ASC) is kept for backward compatibility only.
    return _db
        .watchRewardsInCreationOrder(_familyId)
        .map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Stream<List<redemption.RewardRedemption>> watchRequests() {
    return combineLatest3(
      _db.watchRedemptions(_familyId),
      _db.select(_db.rewards).watch(),
      _db.watchChildren(_familyId),
    ).map((parts) {
      final redemptions = parts[0] as List<RewardRedemption>;
      final rewards = <String, Reward>{
        for (final r in parts[1] as List<Reward>) r.id: r,
      };
      final kids = <String, ChildrenData>{
        for (final k in parts[2] as List<ChildrenData>) k.id: k,
      };
      return redemptions.map((d) {
        final reward = rewards[d.rewardId];
        return redemption.RewardRedemption(
          id: d.id,
          rewardId: d.rewardId,
          rewardTitle: reward?.title ?? 'Reward',
          childId: d.childId,
          childName: kids[d.childId]?.nickname ?? 'Child',
          coinPrice: reward?.coinPrice ?? 0,
          status: d.status,
          createdAt: d.createdAt,
        );
      }).toList();
    });
  }

  @override
  Future<void> createReward(domain.Reward reward) {
    final id = reward.id.isEmpty ? newId('reward') : reward.id;
    return _db
        .into(_db.rewards)
        .insert(
          RewardsCompanion.insert(
            id: id,
            familyId: _familyId,
            title: reward.title,
            icon: Value(reward.icon),
            coinPrice: reward.coinPrice,
            needsOk: Value(reward.needsOk),
          ),
        );
  }

  @override
  Future<void> updateReward(domain.Reward reward) {
    return (_db.update(
      _db.rewards,
    )..where((r) => r.id.equals(reward.id))).write(
      RewardsCompanion(
        title: Value(reward.title),
        icon: Value(reward.icon),
        coinPrice: Value(reward.coinPrice),
        needsOk: Value(reward.needsOk),
      ),
    );
  }

  @override
  Future<void> deleteReward(String id) {
    // P14-B04: foreign keys are off app-wide, so deleting only the reward row
    // would orphan its `reward_redemptions` rows (a later approve is then a
    // silent no-op). Remove both in one transaction.
    return _db.transaction(() async {
      await (_db.delete(
        _db.rewardRedemptions,
      )..where((r) => r.rewardId.equals(id))).go();
      await (_db.delete(_db.rewards)..where((r) => r.id.equals(id))).go();
    });
  }

  @override
  Future<void> setNeedsOk({required String id, required bool needsOk}) {
    return (_db.update(_db.rewards)..where((r) => r.id.equals(id))).write(
      RewardsCompanion(needsOk: Value(needsOk)),
    );
  }

  @override
  Future<void> approveRedemption(int redemptionId) async {
    final redemption = await (_db.select(
      _db.rewardRedemptions,
    )..where((r) => r.id.equals(redemptionId))).getSingleOrNull();
    if (redemption == null || redemption.status != 'requested') return;
    final reward = await (_db.select(
      _db.rewards,
    )..where((r) => r.id.equals(redemption.rewardId))).getSingleOrNull();
    final kid = await (_db.select(
      _db.children,
    )..where((c) => c.id.equals(redemption.childId))).getSingleOrNull();
    if (reward == null || kid == null || kid.coins < reward.coinPrice) return;
    await _db.transaction(() async {
      await (_db.update(_db.rewardRedemptions)
            ..where((r) => r.id.equals(redemptionId)))
          .write(const RewardRedemptionsCompanion(status: Value('approved')));
      await (_db.update(_db.children)
            ..where((c) => c.id.equals(redemption.childId)))
          .write(ChildrenCompanion(coins: Value(kid.coins - reward.coinPrice)));
    });
  }

  @override
  Future<void> denyRedemption(int redemptionId) {
    return (_db.update(_db.rewardRedemptions)
          ..where((r) => r.id.equals(redemptionId)))
        .write(const RewardRedemptionsCompanion(status: Value('denied')));
  }

  domain.Reward _toEntity(Reward row) {
    return domain.Reward(
      id: row.id,
      title: row.title,
      detail: '${row.coinPrice} coins',
      icon: row.icon,
      coinPrice: row.coinPrice,
      needsOk: row.needsOk,
    );
  }
}
