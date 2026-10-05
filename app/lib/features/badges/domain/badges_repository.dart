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

  /// The active child's badges: `app_state.activeChildId` (demo seed:
  /// `maya`) fans out to that child's shelf plus their happy-week count,
  /// so the grid and the week card always arrive atomically.
  Stream<BadgesData> watchActiveBadges();

  /// Badge shelf for one child: every badge with its earned state.
  Stream<List<domain.Badge>> watchShelf(String childId);

  /// Happy days this week (0..7), framed positively — never a lost streak.
  Stream<int> watchHappyDays(String childId);
}
