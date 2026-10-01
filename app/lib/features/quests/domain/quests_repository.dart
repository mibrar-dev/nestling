import 'package:nestling/features/quests/domain/entities/quest.dart';

abstract class QuestsRepository {
  Future<List<Quest>> getItems();
}
