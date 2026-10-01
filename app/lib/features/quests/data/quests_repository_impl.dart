import 'package:nestling/features/quests/data/quests_fake_data_source.dart';
import 'package:nestling/features/quests/domain/entities/quest.dart';
import 'package:nestling/features/quests/domain/quests_repository.dart';

class QuestsRepositoryImpl implements QuestsRepository {
  const new({required this._dataSource});

  final QuestsFakeDataSource _dataSource;

  @override
  Future<List<Quest>> getItems() {
    return Future.value(_dataSource.getItems());
  }
}
