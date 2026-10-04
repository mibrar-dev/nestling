import 'package:equatable/equatable.dart';
import 'package:nestling/features/kid_shop/domain/entities/shop_reward.dart';

// One emission of the K08 shop stream
// (`KidShopRepository.watchActiveShop`): the active child plus their rewards
// in creation order (oldest first — never price order), with affordability
// computed from the child's current coin balance.
class KidShopData extends Equatable {
  const new({required this.childId, required this.coins, required this.items});

  final String childId;
  final int coins;
  final List<ShopReward> items;

  @override
  List<Object?> get props => <Object?>[childId, coins, items];
}
