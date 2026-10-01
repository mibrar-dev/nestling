import 'package:nestling/features/kid_shop/data/kid_shop_fake_data_source.dart';
import 'package:nestling/features/kid_shop/domain/entities/shop_reward.dart';
import 'package:nestling/features/kid_shop/domain/kid_shop_repository.dart';

class KidShopRepositoryImpl implements KidShopRepository {
  const new({required this._dataSource});

  final KidShopFakeDataSource _dataSource;

  @override
  Future<List<ShopReward>> getItems() {
    return Future.value(_dataSource.getItems());
  }
}
