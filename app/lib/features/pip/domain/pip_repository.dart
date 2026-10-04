import 'package:nestling/features/pip/domain/entities/pip_nest.dart';
import 'package:nestling/features/pip/domain/entities/pip_profile.dart';
import 'package:nestling/features/pip/domain/entities/pip_stage.dart';

/// Pip's nest + evolution (K06, K07), backed by Drift.
///
/// Care actions are kind choices with no timers: feeding costs 5 coins,
/// bathing costs 3 coins, playing is free — every action nudges happiness
/// up (max 5). Writes are no-ops when coins are insufficient (never
/// negative).
abstract class PipRepository {
  Future<List<PipStage>> getItems();
  Stream<List<PipStage>> watchItems();

  Stream<PipProfile?> watchProfile(String childId);

  /// Active child id from `app_state` (null when no child picked yet).
  /// The K06 bloc follows this to resolve the nest's owner.
  Stream<String?> watchActiveChildId();

  /// The nest screen's stream: the active child's profile plus wardrobe in
  /// design order (Scarf, Sun hat, Wellies, Crown), or null when there is
  /// no active child. Re-emits on any profile, wardrobe or active-child
  /// change, so the bloc renders updates with no reload events.
  Stream<PipNest?> watchNest();

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
