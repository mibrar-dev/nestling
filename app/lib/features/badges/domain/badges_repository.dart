import 'package:nestling/features/badges/domain/entities/badge.dart' as domain;

/// Badge shelf + happy-week tracker (K11), backed by Drift.
abstract class BadgesRepository {
  Future<List<domain.Badge>> getItems();
  Stream<List<domain.Badge>> watchItems();

  /// Badge shelf for one child: every badge with its earned state.
  Stream<List<domain.Badge>> watchShelf(String childId);

  /// Happy days this week (0..7), framed positively — never a lost streak.
  Stream<int> watchHappyDays(String childId);
}
