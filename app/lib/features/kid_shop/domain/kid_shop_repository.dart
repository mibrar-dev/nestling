import 'package:nestling/features/kid_shop/domain/entities/shop_reward.dart';

/// Kid reward shop (K08), backed by Drift.
///
/// "Get it" always creates a redemption row. Rewards that need a parent's OK
/// stay `requested` until approved in P14; others are approved immediately.
/// Coins leave the child's balance only on approval.
abstract class KidShopRepository {
  Future<List<ShopReward>> getItems();
  Stream<List<ShopReward>> watchItems();

  Stream<List<ShopReward>> watchShop(String childId);
  Future<void> requestReward(String childId, String rewardId);
}
