import 'package:nestling/features/rewards/data/rewards_fake_data_source.dart';
import 'package:nestling/features/rewards/domain/entities/reward.dart';
import 'package:nestling/features/rewards/domain/rewards_repository.dart';

class RewardsRepositoryImpl implements RewardsRepository {
  const new({required this._dataSource});

  final RewardsFakeDataSource _dataSource;

  @override
  Future<List<Reward>> getItems() {
    return Future.value(_dataSource.getItems());
  }
}
