import 'package:drift/drift.dart';
import 'package:nestling/core/data/app_clock.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/family_time.dart';
import 'package:nestling/core/data/pin_hash.dart' as pin_hash;
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/data/stream_combine.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_child.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_home_data.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_quest.dart';
import 'package:nestling/features/kid_home/domain/kid_home_repository.dart';

/// Drift-backed [KidHomeRepository].
class KidHomeRepositoryImpl implements KidHomeRepository {
  new({required this._db});

  final AppDatabase _db;

  @override
  Future<List<KidQuest>> getItems() => watchItems().first;

  @override
  Stream<List<KidQuest>> watchItems() {
    return switchMapStream<KidChild?, List<KidQuest>>(watchActiveChild(), (
      kid,
    ) {
      if (kid == null) return Stream.value(<KidQuest>[]);
      return _watchItemsFor(kid.id);
    });
  }

  /// Single-subscription home stream (review finding 4, iteration 5): one
  /// `app_state` subscription fans out to exactly one child-row subscription
  /// plus the quest/completion/zone queries — never two child subscriptions
  /// per load. A child switch emits the new child WITH their items atomically,
  /// so no frame pairs the new child with the old child's list.
  @override
  Stream<KidHomeData> watchHome() {
    return switchMapStream<AppStateData?, KidHomeData>(_db.watchAppState(), (
      state,
    ) {
      final id = state?.activeChildId;
      if (id == null) {
        return Stream.value(const KidHomeData(child: null));
      }
      return combineLatest2(_db.watchChild(id), _watchItemsFor(id)).map((
        parts,
      ) {
        final row = parts[0] as ChildrenData?;
        if (row == null) {
          return const KidHomeData(child: null);
        }
        return KidHomeData(
          child: _toChild(row),
          items: (parts[1] as List<dynamic>).cast<KidQuest>(),
        );
      });
    });
  }

  /// Quest list for one child: active quests + their completions scoped to
  /// each quest's current family-zone period (period ruling K03-BUG-4).
  Stream<List<KidQuest>> _watchItemsFor(String childId) {
    return combineLatest3(
      _db.watchActiveQuests(Seed.familyId),
      _db.watchCompletionsForChild(childId),
      _db.watchFamilyZoneId(),
    ).map((parts) {
      final quests = parts[0] as List<Quest>;
      final completions = parts[1] as List<QuestCompletion>;
      final now = appNowUtc();
      final zone = normalizeZoneId(parts[2] as String);
      final mine = quests.where((q) => q.assigneeChildId == childId).toList()
        ..sort((a, b) => a.title.compareTo(b.title));
      return mine.map((q) {
        final rows = completions.where((c) => c.questId == q.id).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        // Period rule (orchestrator ruling for K03-BUG-4): only
        // completions inside the quest's current family-zone period count;
        // a completion outside it means the quest is "to do" again.
        final current = rows.where(
          (c) => countsForCurrentPeriod(q.repeatRule, c.createdAt, now, zone),
        );
        final status = current.isEmpty ? 'to_do' : current.first.status;
        return KidQuest(
          id: '${q.id}:$childId',
          title: q.title,
          detail: _detail(status, q.coins),
          questId: q.id,
          icon: q.icon,
          coins: q.coins,
          status: status,
        );
      }).toList();
    });
  }

  @override
  Stream<List<KidChild>> watchProfiles() {
    return _db
        .watchChildren(Seed.familyId)
        .map((rows) => rows.map(_toChild).toList());
  }

  @override
  Stream<KidChild?> watchActiveChild() {
    return _db.watchAppState().asyncExpand((state) {
      final id = state?.activeChildId;
      if (id == null) return Stream.value(null);
      return _db
          .watchChild(id)
          .map((row) => row == null ? null : _toChild(row));
    });
  }

  @override
  List<String> stepsFor(String questId) {
    return _steps[questId] ?? _defaultSteps;
  }

  @override
  Future<bool> verifyPin(String childId, String pin) async {
    final row = await (_db.select(
      _db.children,
    )..where((c) => c.id.equals(childId))).getSingleOrNull();
    final hash = row?.pinHash;
    if (hash == null) return true;
    return pin_hash.verifyPin(pin, hash);
  }

  @override
  Future<void> completeQuest(String childId, String questId) async {
    final quest = await (_db.select(
      _db.quests,
    )..where((q) => q.id.equals(questId))).getSingleOrNull();
    if (quest == null) return;
    // Writer's zone: the current family zone (validated, London fallback).
    // History renders in this stored zone even after a family move.
    final zone = await _db.familyZoneId();
    // Idempotent inside one transaction (K03-BUG-1): a rapid double tap
    // must not write a second pending row. Only the current family-zone
    // period matters (K03-BUG-4 ruling): a `to_do`/`not_yet` inside it flips
    // to `done_pending`; anything already recorded this period stays
    // untouched, and a new period starts a fresh row so coins can never be
    // minted twice for one tap.
    await _db.transaction(() async {
      final existing =
          await (_db.select(_db.questCompletions)
                ..where(
                  (c) => c.questId.equals(questId) & c.childId.equals(childId),
                )
                ..orderBy([
                  (c) => OrderingTerm(
                    expression: c.createdAt,
                    mode: OrderingMode.desc,
                  ),
                ]))
              .get();
      final now = appNowUtc();
      final inPeriod = existing
          .where(
            (c) => countsForCurrentPeriod(
              quest.repeatRule,
              c.createdAt,
              now,
              zone,
            ),
          )
          .toList();
      if (inPeriod.isNotEmpty) {
        final latest = inPeriod.first.status;
        if (latest == 'to_do' || latest == 'not_yet') {
          await (_db.update(
            _db.questCompletions,
          )..where((c) => c.id.equals(inPeriod.first.id))).write(
            QuestCompletionsCompanion(
              status: const Value('done_pending'),
              createdAt: Value(now),
              createdAtTz: Value(zone),
            ),
          );
        }
        return;
      }
      await _db
          .into(_db.questCompletions)
          .insert(
            QuestCompletionsCompanion.insert(
              questId: questId,
              childId: childId,
              familyId: Seed.familyId,
              status: const Value('done_pending'),
              coins: Value(quest.coins),
              createdAt: Value(now),
              createdAtTz: Value(zone),
            ),
          );
    });
  }

  KidChild _toChild(ChildrenData row) {
    return KidChild(
      id: row.id,
      nickname: row.nickname,
      avatarColour: row.avatarColour,
      coins: row.coins,
      pipStyle: row.pipStyle,
      pipSkin: row.pipSkin,
      pipAccessory: row.pipAccessory,
      pipStage: row.pipStage,
      happiness: row.happiness,
      pinSet: row.pinHash != null,
    );
  }

  static String _detail(String status, int coins) {
    switch (status) {
      case 'done_pending':
        return "Waiting for Mum's thumbs-up · +$coins";
      case 'approved':
        return 'Done · +$coins';
      default:
        return 'To do · +$coins';
    }
  }

  static const List<String> _defaultSteps = <String>[
    'Have a go together first',
    'Finish the whole job',
    'Tidy up afterwards',
  ];

  static const Map<String, List<String>> _steps = <String, List<String>>{
    'q-tidy': <String>[
      'Clothes in the basket',
      'Toys in the box',
      'Books on the shelf',
    ],
    'q-bed': <String>['Pull up the duvet', 'Plump the pillow', 'Teddy on top'],
    'q-dishwasher': <String>[
      'Careful with sharp things',
      'Plates on the shelf',
      'Cups on the hooks',
    ],
  };
}
