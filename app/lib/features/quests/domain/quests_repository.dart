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

  /// P09 Reward helper (`= {coins × rate}p at payout`): the family's pence
  /// per coin, read from the `families` row — the source of truth (mirrors
  /// pocket_money's setup read). Emits 1 until the family row exists and
  /// re-emits on every `families` change (BUG-P09-1).
  Stream<int> watchCoinValuePencePerCoin();

  /// Coins must be 1..100 (plan §1-5). Out-of-range values throw
  /// [ArgumentError] in all builds before touching Drift (P09-TEST-6: no
  /// `assert` first, so debug throws the same type the bloc maps to the
  /// parent-safe copy), and write nothing (BUG-P09-4: last line of defence
  /// so a corrupt stored value can never be persisted again).
  Future<void> createQuest(Quest quest);

  /// Same 1..100 coins contract as [createQuest].
  Future<void> updateQuest(Quest quest);
  Future<void> deleteQuest(String id);
}
