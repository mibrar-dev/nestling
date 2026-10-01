import 'package:nestling/features/rewards/domain/entities/reward.dart';
import 'package:nestling/features/rewards/domain/entities/reward_redemption.dart';

/// Reward shop manager (P14), backed by Drift. Owns the `rewards` table and
/// the parent side of `reward_redemptions` (approve/deny; coins move here).
abstract class RewardsRepository {
  Future<List<Reward>> getItems();
  Stream<List<Reward>> watchItems();

  Stream<List<RewardRedemption>> watchRequests();

  Future<void> createReward(Reward reward);
  Future<void> updateReward(Reward reward);
  Future<void> deleteReward(String id);
  Future<void> setNeedsOk({required String id, required bool needsOk});

  Future<void> approveRedemption(int redemptionId);
  Future<void> denyRedemption(int redemptionId);
}
