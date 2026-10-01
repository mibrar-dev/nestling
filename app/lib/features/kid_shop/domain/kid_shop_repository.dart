import 'package:nestling/features/kid_shop/domain/entities/shop_reward.dart';

abstract class KidShopRepository {
  Future<List<ShopReward>> getItems();
}
