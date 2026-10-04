import 'dart:async';

import 'package:drift/drift.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/stream_combine.dart';
import 'package:nestling/features/pip/domain/entities/pip_nest.dart';
import 'package:nestling/features/pip/domain/entities/pip_profile.dart';
import 'package:nestling/features/pip/domain/entities/pip_stage.dart';
import 'package:nestling/features/pip/domain/pip_repository.dart';

/// Drift-backed [PipRepository].
class PipRepositoryImpl implements PipRepository {
  new({required this._db});

  final AppDatabase _db;

  /// Feeding Pip costs 5 coins.
  static const int feedCostCoins = 5;

  /// Bathing Pip costs 3 coins (K06 design: the Bath button shows a
  /// 3-coin price; playing stays free).
  static const int bathCostCoins = 3;

  /// Design order for the K06 wardrobe strip (never alphabetical — the DB
  /// query itself sorts by item, so the mapping re-sorts explicitly).
  static const List<String> wardrobeOrder = <String>[
    'scarf',
    'sunhat',
    'wellies',
    'crown',
  ];

  @override
  Future<List<PipStage>> getItems() => watchItems().first;

  @override
  Stream<List<PipStage>> watchItems() {
    return _switchMap<AppStateData?, List<PipStage>>(
      _db.watchAppState(),
      (state) => _watchOrderedStages(state?.activeChildId ?? 'maya'),
    );
  }

  @override
  Stream<PipProfile?> watchProfile(String childId) {
    return _db.watchChild(childId).map((row) {
      if (row == null) return null;
      return PipProfile(
        childId: row.id,
        nickname: row.nickname,
        style: row.pipStyle,
        skin: row.pipSkin,
        accessory: row.pipAccessory,
        stage: row.pipStage,
        totalCoins: row.pipTotalCoins,
        coins: row.coins,
        happiness: row.happiness,
      );
    });
  }

  @override
  Stream<String?> watchActiveChildId() {
    return _db.watchAppState().map((state) => state?.activeChildId);
  }

  @override
  Stream<PipNest?> watchNest() {
    return _switchMap<AppStateData?, PipNest?>(_db.watchAppState(), (state) {
      final id = state?.activeChildId;
      if (id == null) return Stream<PipNest?>.value(null);
      return combineLatest2(watchProfile(id), _watchOrderedStages(id)).map((
        parts,
      ) {
        final profile = parts[0] as PipProfile?;
        if (profile == null) return null;
        return PipNest(
          profile: profile,
          items: (parts[1] as List<dynamic>).cast<PipStage>(),
        );
      });
    });
  }

  @override
  Future<void> updateLook({
    required String childId,
    String? style,
    String? skin,
    String? accessory,
  }) {
    return (_db.update(_db.children)..where((c) => c.id.equals(childId))).write(
      ChildrenCompanion(
        pipStyle: style == null ? const Value.absent() : Value(style),
        pipSkin: skin == null ? const Value.absent() : Value(skin),
        pipAccessory: accessory == null
            ? const Value.absent()
            : Value(accessory),
      ),
    );
  }

  @override
  Future<void> feed(String childId) => _care(childId, cost: feedCostCoins);

  @override
  Future<void> play(String childId) => _care(childId);

  @override
  Future<void> bathe(String childId) => _care(childId, cost: bathCostCoins);

  Future<void> _care(String childId, {int cost = 0}) async {
    // Atomic conditional write (K06-BUG-1): a read-modify-write here loses
    // charges when two taps overlap (both read 120, both write 115), so the
    // deduction applies to the CURRENT row value in one statement and the
    // affordability check is part of the write. Zero changed rows means an
    // unknown child or insufficient coins: a silent no-op, never negative.
    await _db.customUpdate(
      'UPDATE children SET coins = coins - ?, '
      'happiness = min(happiness + 1, 5) '
      'WHERE id = ? AND coins >= ?',
      variables: <Variable>[
        Variable.withInt(cost),
        Variable.withString(childId),
        Variable.withInt(cost),
      ],
      updates: {_db.children},
    );
  }

  @override
  Future<PipBuyResult> buyItem(String childId, String item) {
    return _db.transaction(() async {
      final row =
          await (_db.select(_db.pipWardrobe)
                ..where((w) => w.childId.equals(childId) & w.item.equals(item)))
              .getSingleOrNull();
      if (row == null) return PipBuyResult.unavailable;
      if (row.owned) return PipBuyResult.alreadyOwned;
      // Atomic conditional deduction (K06-BUG-2): the affordability check
      // is part of the write, so two overlapping buys cannot both spend the
      // same coins. Zero changed rows means insufficient coins.
      final paid = await _db.customUpdate(
        'UPDATE children SET coins = coins - ? WHERE id = ? AND coins >= ?',
        variables: <Variable>[
          Variable.withInt(row.priceCoins),
          Variable.withString(childId),
          Variable.withInt(row.priceCoins),
        ],
        updates: {_db.children},
      );
      if (paid == 0) return PipBuyResult.cannotAfford;
      // Claim the tile only while still unowned: a same-item double tap
      // that lost the race refunds instead of charging twice.
      final claimed =
          await (_db.update(_db.pipWardrobe)..where(
                (w) =>
                    w.childId.equals(childId) &
                    w.item.equals(item) &
                    w.owned.equals(false),
              ))
              .write(const PipWardrobeCompanion(owned: Value(true)));
      if (claimed == 0) {
        await _db.customUpdate(
          'UPDATE children SET coins = coins + ? WHERE id = ?',
          variables: <Variable>[
            Variable.withInt(row.priceCoins),
            Variable.withString(childId),
          ],
          updates: {_db.children},
        );
        return PipBuyResult.alreadyOwned;
      }
      return PipBuyResult.bought;
    });
  }

  Stream<List<PipStage>> _watchOrderedStages(String childId) {
    return _db.watchWardrobe(childId).map(_orderedStages);
  }

  List<PipStage> _orderedStages(List<PipWardrobeData> rows) {
    final stages = rows.map(_toStage).toList()
      ..sort((a, b) => _orderIndex(a.id).compareTo(_orderIndex(b.id)));
    return stages;
  }

  static int _orderIndex(String item) {
    final index = wardrobeOrder.indexOf(item);
    return index < 0 ? wardrobeOrder.length : index;
  }

  PipStage _toStage(PipWardrobeData row) {
    return PipStage(
      id: row.item,
      title: _itemName(row.item),
      detail: row.owned ? 'Owned' : '${row.priceCoins} coins',
      owned: row.owned,
      priceCoins: row.priceCoins,
    );
  }

  /// Design names for the K06 wardrobe strip (the DB stores only ids).
  static String _itemName(String item) {
    switch (item) {
      case 'scarf':
        return 'Scarf';
      case 'sunhat':
        return 'Sun hat';
      case 'wellies':
        return 'Wellies';
      case 'crown':
        return 'Crown';
      default:
        return item;
    }
  }
}

/// `switchMap` for never-closing Drift watch streams: every outer emission
/// cancels the previous inner subscription and forwards the new inner's
/// events. Same shape as the kid_home helper, kept feature-local (the plan
/// lets this screen own its data dir; no cross-feature import).
///
/// The result never closes while an inner stream is live: the outer stream
/// completing must NOT close the result, so a `Stream.value(null)` outer
/// (no active child) still leaves later emissions flowing.
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
