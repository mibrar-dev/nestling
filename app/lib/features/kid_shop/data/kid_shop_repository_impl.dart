import 'dart:async';

import 'package:drift/drift.dart';
import 'package:nestling/core/data/app_clock.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/data/stream_combine.dart';
import 'package:nestling/features/kid_shop/domain/entities/kid_shop_data.dart';
import 'package:nestling/features/kid_shop/domain/entities/shop_reward.dart';
import 'package:nestling/features/kid_shop/domain/kid_shop_repository.dart';

/// Drift-backed [KidShopRepository].
class KidShopRepositoryImpl implements KidShopRepository {
  new({required this._db});

  final AppDatabase _db;

  /// The active child's shop: `app_state.activeChildId` (demo seed: `maya`)
  /// fans out to exactly one rewards query (creation order — the K08 list
  /// order, never price order) plus that child's row, so coins and the list
  /// always arrive atomically.
  @override
  Stream<KidShopData> watchActiveShop() {
    return _switchMap<AppStateData?, KidShopData>(
      _db.watchAppState(),
      (state) => _shopFor(state?.activeChildId ?? 'maya'),
    );
  }

  /// Per-child shop stream: rewards in creation order (the K08 list order)
  /// with `affordable` resolved against that child's coins.
  Stream<KidShopData> _shopFor(String childId) {
    return combineLatest2(
      _db.watchRewardsInCreationOrder(Seed.familyId),
      _db.watchChild(childId),
    ).map((parts) {
      final rewards = parts[0] as List<Reward>;
      final kid = parts[1] as ChildrenData?;
      final coins = kid?.coins ?? 0;
      return KidShopData(
        childId: childId,
        coins: coins,
        items: rewards
            .map(
              (r) => ShopReward(
                id: r.id,
                title: r.title,
                detail: '${r.coinPrice} coins',
                icon: r.icon,
                coinPrice: r.coinPrice,
                needsOk: r.needsOk,
                affordable: coins >= r.coinPrice,
              ),
            )
            .toList(),
      );
    });
  }

  /// Items for an explicit child, without the active-child fan-out.
  ///
  /// Not part of [KidShopRepository]: K08 reads [watchActiveShop] only. Kept
  /// on the implementation because the foundation's shared
  /// `test/core/data/repositories_test.dart` covers affordability and the
  /// request/approve round trip through it, and that test is shared code this
  /// screen must not edit.
  Stream<List<ShopReward>> watchShop(String childId) =>
      _shopFor(childId).map((data) => data.items);

  @override
  Future<void> requestReward(String childId, String rewardId) async {
    final reward = await (_db.select(
      _db.rewards,
    )..where((r) => r.id.equals(rewardId))).getSingleOrNull();
    if (reward == null) return;
    final now = appNowUtc();
    final zone = await _db.familyZoneId();
    await _db.transaction(() async {
      if (reward.needsOk) {
        await _insertRedemption(
          childId: childId,
          rewardId: rewardId,
          status: 'requested',
          now: now,
          zone: zone,
        );
        return;
      }
      // Instant rewards are paid in coins at request time, so payment is a
      // precondition of the `approved` row (K08-BUG-1): two cards that are
      // each affordable, tapped in one frame, must not both land `approved`
      // when the balance only covers the first. The balance is read inside
      // the same transaction so concurrent requests serialize on it; when it
      // no longer covers the price the row is left `requested` for a
      // grown-up instead of an unpaid `approved` row.
      final kid = await (_db.select(
        _db.children,
      )..where((c) => c.id.equals(childId))).getSingleOrNull();
      if (kid == null || kid.coins < reward.coinPrice) {
        await _insertRedemption(
          childId: childId,
          rewardId: rewardId,
          status: 'requested',
          now: now,
          zone: zone,
        );
        return;
      }
      await _insertRedemption(
        childId: childId,
        rewardId: rewardId,
        status: 'approved',
        now: now,
        zone: zone,
      );
      await (_db.update(_db.children)..where((c) => c.id.equals(childId)))
          .write(ChildrenCompanion(coins: Value(kid.coins - reward.coinPrice)));
    });
  }

  Future<void> _insertRedemption({
    required String childId,
    required String rewardId,
    required String status,
    required DateTime now,
    required String zone,
  }) {
    return _db
        .into(_db.rewardRedemptions)
        .insert(
          RewardRedemptionsCompanion.insert(
            rewardId: rewardId,
            childId: childId,
            familyId: Seed.familyId,
            status: Value(status),
            createdAt: Value(now),
            createdAtTz: Value(zone),
          ),
        );
  }
}

/// `switchMap` for never-closing Drift watch streams: every outer emission
/// cancels the previous inner subscription and forwards the new inner's
/// events. ([Stream.asyncExpand] cannot be used here — it pauses the outer
/// subscription until the current inner *closes*, and watch streams never
/// close, so an active-child switch after the first emission would stall
/// forever.) Feature-local copy of the `kid_home` helper: no shared edits,
/// no cross-feature import.
Stream<S> _switchMap<T, S>(
  Stream<T> outer,
  Stream<S> Function(T event) convert,
) {
  late final StreamController<S> controller;
  StreamSubscription<T>? outerSub;
  StreamSubscription<S>? innerSub;
  controller = StreamController<S>(
    onListen: () {
      outerSub = outer.listen(
        (event) {
          unawaited(innerSub?.cancel());
          innerSub = convert(event).listen(
            controller.add,
            onError: controller.addError,
            // Never close: the next outer emission replaces the inner.
          );
        },
        onError: controller.addError,
        // Outer done: keep forwarding the live inner.
      );
    },
    onCancel: () async {
      await innerSub?.cancel();
      await outerSub?.cancel();
    },
  );
  return controller.stream;
}
