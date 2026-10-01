import 'package:nestling/features/quests/data/models/quest_model.dart';

class QuestsFakeDataSource {
  const new();

  List<QuestModel> getItems() {
    return const <QuestModel>[
      QuestModel(
        id: 'bins',
        title: 'Put the bins out',
        detail: '15 coins, age 8 plus',
      ),
      QuestModel(
        id: 'hoover',
        title: 'Hoover the stairs',
        detail: '20 coins, age 9 plus',
      ),
      QuestModel(
        id: 'bed',
        title: 'Make your bed',
        detail: '5 coins, age 4 plus',
      ),
    ];
  }
}
