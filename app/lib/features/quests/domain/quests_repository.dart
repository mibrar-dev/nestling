import 'package:nestling/features/quests/domain/entities/quest.dart';

/// Quest library + editor (P09, P10), backed by Drift.
///
/// `ideas()` are the static P10 template list (never stored); everything
/// else reads the `quests` table. Streams re-emit on every table change.
abstract class QuestsRepository {
  Future<List<Quest>> getItems();
  Stream<List<Quest>> watchItems();

  /// Static P10 "Ideas" templates with suggested coins + age bands.
  List<Quest> ideas();

  Future<Quest?> getQuest(String id);
  Future<void> createQuest(Quest quest);
  Future<void> updateQuest(Quest quest);
  Future<void> deleteQuest(String id);
}
