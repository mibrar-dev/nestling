import 'package:nestling/features/pip/domain/entities/pip_profile.dart';
import 'package:nestling/features/pip/domain/entities/pip_stage.dart';

/// Pip's nest + evolution (K06, K07), backed by Drift.
///
/// Care actions are always free choices with no timers: feeding costs 5
/// coins, playing and bathing are free and nudge happiness up (max 5).
abstract class PipRepository {
  Future<List<PipStage>> getItems();
  Stream<List<PipStage>> watchItems();

  Stream<PipProfile?> watchProfile(String childId);

  Future<void> updateLook({
    required String childId,
    String? style,
    String? skin,
    String? accessory,
  });
  Future<void> feed(String childId);
  Future<void> play(String childId);
  Future<void> bathe(String childId);
  Future<void> buyItem(String childId, String item);
}
