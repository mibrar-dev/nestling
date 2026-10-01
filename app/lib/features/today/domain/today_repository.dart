import 'package:nestling/features/today/domain/entities/child_day_summary.dart';
import 'package:nestling/features/today/domain/entities/today_item.dart';

/// Today feed (P08, P08b), backed by Drift.
///
/// `watch…` streams re-emit whenever quest or completion rows change, so
/// the Today bloc reacts without re-dispatching events.
abstract class TodayRepository {
  Future<List<TodayItem>> getItems();
  Stream<List<TodayItem>> watchItems();

  /// One summary card per child ("4 of 6 quests", 120 coins).
  Stream<List<ChildDaySummary>> watchSummaries();
}
