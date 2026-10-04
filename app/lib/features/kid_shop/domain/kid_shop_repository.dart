import 'package:nestling/features/kid_shop/domain/entities/kid_shop_data.dart';

/// Kid reward shop (K08), backed by Drift.
///
/// One stream — [watchActiveShop] — emits the active child plus their rewards
/// in creation order (oldest first, never price order). "Get it" always
/// creates a redemption row. Rewards that need a parent's OK stay `requested`
/// until approved in P14; others are approved immediately. Coins leave the
/// child's balance only on approval.
abstract class KidShopRepository {
  Stream<KidShopData> watchActiveShop();

  Future<void> requestReward(String childId, String rewardId);
}
