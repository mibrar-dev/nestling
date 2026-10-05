import 'package:nestling/features/badges/domain/entities/badge.dart' as domain;
import 'package:nestling/features/badges/domain/entities/badges_data.dart';

/// Badge shelf + happy-week tracker (K11), backed by Drift.
///
/// One stream — [watchActiveBadges] — emits the active child plus their
/// badges in DB insertion order (never sorted) with the stored happy-week
/// count. Detail copy is design copy: earned → `Got it!`,
/// unearned → `Keep going!`.
abstract class BadgesRepository {
  Future<List<domain.Badge>> getItems();
  Stream<List<domain.Badge>> watchItems();

  /// The resolved child's badges: the persisted `activeChildId` when it
  /// names a real child, else the first child in creation order (CHILD
  /// ORDER ruling), else the empty shelf (no children — the view shows
  /// the childless empty state). Never a hard-coded child id (K11-BUG-2).
  /// Shelf plus happy-week count arrive atomically.
  Stream<BadgesData> watchActiveBadges();

  /// Badge shelf for one child: every badge with its earned state.
  Stream<List<domain.Badge>> watchShelf(String childId);

  /// Happy days this week (0..7), framed positively — never a lost streak.
  Stream<int> watchHappyDays(String childId);
}
