import 'dart:async';

import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/stream_combine.dart';
import 'package:nestling/features/badges/domain/badges_repository.dart';
import 'package:nestling/features/badges/domain/entities/badge.dart' as domain;
import 'package:nestling/features/badges/domain/entities/badges_data.dart';

/// Drift-backed [BadgesRepository].
class BadgesRepositoryImpl implements BadgesRepository {
  new({required this._db});

  final AppDatabase _db;

  @override
  Future<List<domain.Badge>> getItems() => watchItems().first;

  @override
  Stream<List<domain.Badge>> watchItems() async* {
    final state = await (_db.select(
      _db.appState,
    )..where((a) => a.id.equals(1))).getSingleOrNull();
    yield* watchShelf(state?.activeChildId ?? 'maya');
  }

  /// The active child's badges: `app_state.activeChildId` (demo seed: `maya`)
  /// fans out to exactly one shelf query (DB insertion order — the K11 grid
  /// order, never sorted) plus that child's row, so the grid and the week
  /// card always arrive atomically.
  @override
  Stream<BadgesData> watchActiveBadges() {
    return _switchMap<AppStateData?, BadgesData>(
      _db.watchAppState(),
      (state) => _badgesFor(state?.activeChildId ?? 'maya'),
    );
  }

  /// Per-child badges stream: the shelf in DB insertion order with
  /// `happyDays` resolved from that child's row.
  Stream<BadgesData> _badgesFor(String childId) {
    return combineLatest2(watchShelf(childId), watchHappyDays(childId)).map((
      parts,
    ) {
      final items = parts[0] as List<domain.Badge>;
      final happyDays = parts[1] as int;
      return BadgesData(childId: childId, items: items, happyDays: happyDays);
    });
  }

  @override
  Stream<List<domain.Badge>> watchShelf(String childId) {
    return combineLatest2(
      _db.select(_db.badges).watch(),
      _db.watchEarnedBadges(childId),
    ).map((parts) {
      final all = parts[0] as List<Badge>;
      final earned = <String, EarnedBadge>{
        for (final e in parts[1] as List<EarnedBadge>) e.badgeId: e,
      };
      return all.map((b) {
        final hit = earned[b.id];
        return domain.Badge(
          id: b.id,
          title: b.title,
          detail: hit == null ? 'Keep going!' : 'Got it!',
          icon: b.icon,
          description: b.description,
          earned: hit != null,
          earnedAt: hit?.earnedAt,
        );
      }).toList();
    });
  }

  @override
  Stream<int> watchHappyDays(String childId) {
    return _db.watchChild(childId).map((row) => row?.happyDays ?? 0);
  }
}

/// `switchMap` for never-closing Drift watch streams: every outer emission
/// cancels the previous inner subscription and forwards the new inner's
/// events. ([Stream.asyncExpand] cannot be used here — it pauses the outer
/// subscription until the current inner *closes*, and watch streams never
/// close, so an active-child switch after the first emission would stall
/// forever.) Feature-local copy of the `kid_shop` helper: no shared edits,
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
