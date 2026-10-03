import 'dart:async';

import 'package:nestling/features/kid_home/domain/entities/kid_child.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_home_data.dart';
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

  /// Combined home stream (review finding 4, iteration 5): the active child
  /// plus their quests in ONE subscription, so a load watches the child row
  /// exactly once. The default builds on [watchActiveChild] + [watchItems];
  /// the Drift implementation overrides it with a single-subscription query.
  Stream<KidHomeData> watchHome() {
    return switchMapStream<KidChild?, KidHomeData>(watchActiveChild(), (child) {
      final current = child;
      if (current == null) {
        return Stream<KidHomeData>.value(const KidHomeData(child: null));
      }
      return watchItems().map(
        (items) => KidHomeData(child: current, items: items),
      );
    });
  }

  /// Default quest steps for the K04 checklist (v1 has no per-quest steps).
  List<String> stepsFor(String questId);

  Future<bool> verifyPin(String childId, String pin);
  Future<void> completeQuest(String childId, String questId);
}

/// `switchMap` for never-closing Drift watch streams: every outer emission
/// cancels the previous inner subscription and forwards the new inner's
/// events. ([Stream.asyncExpand] cannot be used here — it pauses the outer
/// subscription until the current inner *closes*, and watch streams never
/// close, so child switches after the first emission would stall forever.)
///
/// The result never closes while an inner stream is live. In particular the
/// outer stream completing must NOT close the result: a `watchActiveChild`
/// may legitimately end after one value (`Stream.value`, and any
/// `async*` that yields the row once), and closing there tore down the inner
/// quest subscription with it — the load then stopped one tick in and every
/// later completion flip was silently dropped.
Stream<S> switchMapStream<T, S>(
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
        // Outer done: keep forwarding the live inner (see above).
      );
    },
    onCancel: () async {
      await innerSub?.cancel();
      await outerSub?.cancel();
    },
  );
  return controller.stream;
}
