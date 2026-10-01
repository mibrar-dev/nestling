import 'package:nestling/features/pip/data/models/pip_stage_model.dart';

class PipFakeDataSource {
  const new();

  List<PipStageModel> getItems() {
    return const <PipStageModel>[
      PipStageModel(
        id: 'fledgling',
        title: 'Pip the Fledgling',
        detail: '175 of 250 coins to Songbird',
      ),
      PipStageModel(
        id: 'care-feed',
        title: 'Feed Pip',
        detail: '5 coins, free choice',
      ),
    ];
  }
}
