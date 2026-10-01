import 'package:nestling/features/rewards/data/models/reward_model.dart';

class RewardsFakeDataSource {
  const new();

  List<RewardModel> getItems() {
    return const <RewardModel>[
      RewardModel(
        id: 'screen-time',
        title: '30 min extra screen time',
        detail: '50 coins',
      ),
      RewardModel(id: 'film', title: 'Pick Friday film', detail: '80 coins'),
      RewardModel(id: 'baking', title: 'Baking together', detail: '100 coins'),
    ];
  }
}
