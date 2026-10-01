import 'package:drift/drift.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/features/pip/domain/entities/pip_profile.dart';
import 'package:nestling/features/pip/domain/entities/pip_stage.dart';
import 'package:nestling/features/pip/domain/pip_repository.dart';

/// Drift-backed [PipRepository].
class PipRepositoryImpl implements PipRepository {
  new({required this._db});

  final AppDatabase _db;

  /// Feeding Pip costs 5 coins.
  static const int feedCostCoins = 5;

  @override
  Future<List<PipStage>> getItems() => watchItems().first;

  @override
  Stream<List<PipStage>> watchItems() async* {
    final state = await (_db.select(
      _db.appState,
    )..where((a) => a.id.equals(1))).getSingleOrNull();
    yield* _db
        .watchWardrobe(state?.activeChildId ?? 'maya')
        .map((rows) => rows.map(_toStage).toList());
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
  Future<void> bathe(String childId) => _care(childId);

  Future<void> _care(String childId, {int cost = 0}) async {
    final kid = await (_db.select(
      _db.children,
    )..where((c) => c.id.equals(childId))).getSingleOrNull();
    if (kid == null || kid.coins < cost) return;
    await (_db.update(_db.children)..where((c) => c.id.equals(childId))).write(
      ChildrenCompanion(
        coins: Value(kid.coins - cost),
        happiness: Value((kid.happiness + 1).clamp(0, 5)),
      ),
    );
  }

  @override
  Future<void> buyItem(String childId, String item) async {
    final row =
        await (_db.select(_db.pipWardrobe)
              ..where((w) => w.childId.equals(childId) & w.item.equals(item)))
            .getSingleOrNull();
    if (row == null || row.owned) return;
    final kid = await (_db.select(
      _db.children,
    )..where((c) => c.id.equals(childId))).getSingleOrNull();
    if (kid == null || kid.coins < row.priceCoins) return;
    await _db.transaction(() async {
      await (_db.update(_db.pipWardrobe)
            ..where((w) => w.childId.equals(childId) & w.item.equals(item)))
          .write(const PipWardrobeCompanion(owned: Value(true)));
      await (_db.update(_db.children)..where((c) => c.id.equals(childId)))
          .write(ChildrenCompanion(coins: Value(kid.coins - row.priceCoins)));
    });
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

  static String _itemName(String item) {
    switch (item) {
      case 'scarf':
        return 'Cosy scarf';
      case 'sunhat':
        return 'Sunny hat';
      case 'wellies':
        return 'Muddy wellies';
      case 'crown':
        return 'Star crown';
      default:
        return item;
    }
  }
}
