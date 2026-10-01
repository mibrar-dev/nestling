import 'package:nestling/features/kid_home/data/models/kid_quest_model.dart';

class KidHomeFakeDataSource {
  const new();

  List<KidQuestModel> getItems() {
    return const <KidQuestModel>[
      KidQuestModel(
        id: 'dishwasher',
        title: 'Empty the dishwasher',
        detail: 'Waiting for Mum thumbs-up',
      ),
      KidQuestModel(
        id: 'reading',
        title: 'Reading, 20 minutes',
        detail: '10 coins, to do',
      ),
      KidQuestModel(
        id: 'bedroom',
        title: 'Tidy your bedroom',
        detail: '15 coins, to do',
      ),
    ];
  }
}
