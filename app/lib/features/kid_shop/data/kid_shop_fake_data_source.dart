import 'package:nestling/features/kid_shop/data/models/shop_reward_model.dart';

class KidShopFakeDataSource {
  const new();

  List<ShopRewardModel> getItems() {
    return const <ShopRewardModel>[
      ShopRewardModel(
        id: 'screen-time',
        title: '30 min extra screen time',
        detail: '50 coins',
      ),
      ShopRewardModel(
        id: 'film',
        title: 'Pick Friday film',
        detail: '80 coins',
      ),
      ShopRewardModel(
        id: 'park-cafe',
        title: 'Park cafe trip',
        detail: '150 coins, 30 more to go',
      ),
    ];
  }
}
