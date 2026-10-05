import 'package:nestling/features/kid_jar/domain/entities/jar_entry.dart';
import 'package:nestling/features/kid_jar/domain/entities/jar_snapshot.dart';
import 'package:nestling/features/kid_jar/domain/entities/jar_summary.dart';
import 'package:nestling/features/kid_jar/domain/entities/payout_celebration.dart';

/// Kid jar (K09 My jar, K10 payout day), backed by Drift. Reads the same
/// ledger as the parent money screens; the only kid screen that shows £.
abstract class KidJarRepository {
  Future<List<JarEntry>> getItems();
  Stream<List<JarEntry>> watchItems();

  /// The K09 screen stream: the active child's money-in list plus the jar
  /// summary in one atomic emission. Follows `app_state.activeChildId`
  /// (`'maya'` fallback when no child is active yet).
  Stream<JarSnapshot> watchJar();

  Stream<JarSummary> watchSummary(String childId);

  /// The K10 screen stream: the latest `payout` event for the active child
  /// (`'maya'` fallback when no child is active yet), with its companion
  /// savings move, the live savings goal and the child's Pip look in one
  /// atomic emission — or null when no payout was recorded yet.
  Stream<PayoutCelebration?> watchLatestPayout();

  Future<void> moveToSavings({
    required String childId,
    required String goalId,
    required int amountPence,
  });
}
