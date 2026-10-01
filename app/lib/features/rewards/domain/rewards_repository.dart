import 'package:nestling/features/rewards/domain/entities/reward.dart';

abstract class RewardsRepository {
  Future<List<Reward>> getItems();
}
