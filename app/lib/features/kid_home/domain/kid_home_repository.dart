import 'package:nestling/features/kid_home/domain/entities/kid_child.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_quest.dart';

/// Kid mode home + PIN + quest flow (K01–K05), backed by Drift.
///
/// Completing a quest inserts a `done_pending` completion (and a matching
/// `not_yet` → `done_pending` flip when retrying) — coins move only when a
/// parent approves. The PIN itself is never stored; only its salted hash.
abstract class KidHomeRepository {
  Future<List<KidQuest>> getItems();
  Stream<List<KidQuest>> watchItems();

  Stream<List<KidChild>> watchProfiles();
  Stream<KidChild?> watchActiveChild();

  /// Default quest steps for the K04 checklist (v1 has no per-quest steps).
  List<String> stepsFor(String questId);

  Future<bool> verifyPin(String childId, String pin);
  Future<void> completeQuest(String childId, String questId);
}
