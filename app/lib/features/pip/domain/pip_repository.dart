import 'package:nestling/features/pip/domain/entities/pip_nest.dart';
import 'package:nestling/features/pip/domain/entities/pip_profile.dart';
import 'package:nestling/features/pip/domain/entities/pip_stage.dart';

/// Outcome of a wardrobe purchase attempt.
enum PipBuyResult {
  /// The tile is now owned and the DB price was deducted.
  bought,

  /// The fresh balance cannot afford the tile: nothing was written.
  cannotAfford,

  /// The tile was already owned: nothing was written, nothing charged.
  alreadyOwned,

  /// Unknown item or child: nothing was written.
  unavailable,
}

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

  /// Buys a wardrobe tile at its DB price. Atomic (K06-BUG-2): the
  /// affordability check is part of the write, so overlapping taps cannot
  /// overspend, and a lost same-item race refunds instead of charging
  /// twice. The result tells the caller apart what a silent `void` could
  /// not (K06-BUG-7): only [PipBuyResult.cannotAfford] needs the kind
  /// "not enough coins" toast.
  Future<PipBuyResult> buyItem(String childId, String item);

  /// Care costs, declared on the ABSTRACT contract so the screen renders the
  /// same numbers the write charges. They were static members of
  /// `PipRepositoryImpl`, which made the K06 view reach into a Drift file for
  /// copy-rendering numbers (presentation may not name the impl —
  /// 4_review.md #3).
  ///
  /// Playing is free.
  static const int feedCostCoins = 5;

  /// Bathing costs 3 coins (the K06 design's Bath button shows a 3-coin
  /// price).
  static const int bathCostCoins = 3;
}
