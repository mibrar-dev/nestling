import 'package:drift/drift.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/family_time.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/data/stream_combine.dart';
import 'package:nestling/features/family/domain/entities/family_child.dart';
import 'package:nestling/features/family/domain/entities/family_member.dart';
import 'package:nestling/features/family/domain/family_repository.dart';

/// Monotonic band → representative age: the top of each closed band, 13 for
/// the open-ended band, schema default 7 for anything unexpected.
int _ageYearsForBand(String ageBand) => switch (ageBand) {
  '4-6' => 6,
  '7-9' => 9,
  '10-12' => 12,
  '13+' => 13,
  _ => 7,
};

/// Drift-backed [FamilyRepository].
class FamilyRepositoryImpl implements FamilyRepository {
  new({required this._db});

  final AppDatabase _db;

  @override
  Future<List<FamilyMember>> getItems() => watchItems().first;

  @override
  Stream<List<FamilyMember>> watchItems() {
    return (_db.select(_db.members)
          ..where((m) => m.familyId.equals(Seed.familyId)))
        .watch()
        .map((rows) => rows.map(_toMember).toList());
  }

  @override
  Stream<List<FamilyChild>> watchChildren() {
    return combineLatest3(
      // CHILD ORDER ruling: creation order via the shared helper
      // (`createdAt`, then `rowid` for same-second ties) — never
      // alphabetical. (Pre-schema-v3 this feature carried its own
      // `rowid`-only query; the durable column has landed, so the interim
      // query is retired.)
      _db.watchChildren(Seed.familyId),
      _db.watchActiveQuests(Seed.familyId),
      _db.watchAllCompletions(Seed.familyId),
    ).map((parts) {
      final kids = parts[0] as List<ChildrenData>;
      final quests = parts[1] as List<Quest>;
      final completions = parts[2] as List<QuestCompletion>;
      return kids.map((k) => _toChild(k, quests, completions)).toList();
    });
  }

  @override
  Future<FamilyChild?> getChild(String childId) async {
    final row = await (_db.select(
      _db.children,
    )..where((c) => c.id.equals(childId))).getSingleOrNull();
    if (row == null) return null;
    final quests = await (_db.select(
      _db.quests,
    )..where((q) => q.familyId.equals(Seed.familyId))).get();
    final completions = await (_db.select(
      _db.questCompletions,
    )..where((c) => c.childId.equals(childId))).get();
    return _toChild(row, quests, completions);
  }

  @override
  Future<void> addChild({
    required String nickname,
    required String ageBand,
    required String avatarColour,
    int weeklyBasePence = 0,
  }) {
    final id = 'child-${DateTime.now().toUtc().millisecondsSinceEpoch}';
    return _db
        .into(_db.children)
        .insert(
          ChildrenCompanion.insert(
            id: id,
            familyId: Seed.familyId,
            nickname: nickname,
            ageBand: Value(ageBand),
            // P05-BUG-6: the schema default (7) used to stand whatever band
            // was picked, so every new child sorted as a 7-year-old.
            ageYears: Value(_ageYearsForBand(ageBand)),
            avatarColour: Value(avatarColour),
            weeklyBasePence: Value(weeklyBasePence),
            // Explicit creation marker (CHILD ORDER ruling): roster order is
            // creation order, so a newly added child sorts last. `now`, not
            // the column default, so the instant is also exact on databases
            // migrated to v3 (whose `ADD COLUMN` placeholder default is 0).
            createdAt: Value(DateTime.now().toUtc()),
            createdAtTz: const Value(defaultFamilyZoneId),
          ),
        );
  }

  @override
  Future<void> updateChild(FamilyChild child) {
    return (_db.update(
      _db.children,
    )..where((c) => c.id.equals(child.id))).write(
      ChildrenCompanion(
        nickname: Value(child.nickname),
        ageBand: Value(child.ageBand),
        ageYears: Value(child.ageYears),
        avatarColour: Value(child.avatarColour),
        pipStyle: Value(child.pipStyle),
        pipSkin: Value(child.pipSkin),
        pipAccessory: Value(child.pipAccessory),
        weeklyBasePence: Value(child.weeklyBasePence),
      ),
    );
  }

  @override
  Future<void> removeChild(String childId) {
    return (_db.delete(_db.children)..where((c) => c.id.equals(childId))).go();
  }

  @override
  Future<void> inviteCoParent(String name) {
    final id = 'coparent-${DateTime.now().toUtc().millisecondsSinceEpoch}';
    return _db
        .into(_db.members)
        .insert(
          MembersCompanion.insert(
            id: id,
            familyId: Seed.familyId,
            name: name,
            role: const Value('co-parent'),
            inviteStatus: const Value('invited'),
          ),
        );
  }

  FamilyMember _toMember(Member row) {
    final detail = row.role == 'owner'
        ? 'You'
        : row.inviteStatus == 'invited'
        ? 'Co-parent · invited'
        : 'Co-parent';
    return FamilyMember(
      id: row.id,
      title: row.name,
      detail: detail,
      name: row.name,
      role: row.role,
      inviteStatus: row.inviteStatus,
    );
  }

  FamilyChild _toChild(
    ChildrenData row,
    List<Quest> quests,
    List<QuestCompletion> completions,
  ) {
    final mine = quests
        .where((q) => q.active && q.assigneeChildId == row.id)
        .toList();
    final done = mine
        .where(
          (q) => completions.any(
            (c) =>
                c.questId == q.id &&
                c.childId == row.id &&
                (c.status == 'done_pending' || c.status == 'approved'),
          ),
        )
        .length;
    return FamilyChild(
      id: row.id,
      nickname: row.nickname,
      ageBand: row.ageBand,
      ageYears: row.ageYears,
      avatarColour: row.avatarColour,
      pinSet: row.pinHash != null,
      pipStyle: row.pipStyle,
      pipSkin: row.pipSkin,
      pipAccessory: row.pipAccessory,
      pipStage: row.pipStage,
      pipTotalCoins: row.pipTotalCoins,
      coins: row.coins,
      happiness: row.happiness,
      happyDays: row.happyDays,
      weeklyBasePence: row.weeklyBasePence,
      activeQuests: mine.length,
      doneQuests: done,
    );
  }
}
