import 'dart:async';

import 'package:drift/drift.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/family_time.dart'
    hide countsForCurrentPeriod;
import 'package:nestling/core/data/london_time.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/data/stream_combine.dart';
import 'package:nestling/features/family/domain/entities/child_profile.dart';
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
  new({required this._db, DateTime Function()? clock})
    : _clock = clock ?? _defaultClock;

  final AppDatabase _db;

  /// "Now" for period checks. Defaults to the seed anchor when tests pin it
  /// (so demo assertions stay date-independent — P15-BUG-8) and to the wall
  /// clock otherwise — pass an explicit clock in tests that need one.
  /// (Same shape as `TodayRepositoryImpl`.)
  final DateTime Function() _clock;

  static DateTime _defaultClock() =>
      Seed.anchorOverride?.toUtc() ?? DateTime.now().toUtc();

  /// In-memory selection request from `selectChild`, effective for the
  /// mapper below the moment it is set (synchronously — no DB roundtrip).
  /// Only ever honoured when it names a loaded child, so a stale or unknown
  /// value can never render: the persisted `activeChildId` stays the source
  /// of truth and the async validation in `selectChild` converges the two.
  String? _pendingSelection;

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
  Stream<ChildProfile?> watchProfile() {
    // NOTE (P15-2a): the plan prescribes `asyncExpand` onto
    // `watchLedger(childId)`, but `Stream.asyncExpand` waits for each inner
    // stream to CLOSE before processing the next outer event ("concat"
    // semantics) — and Drift `watch()` streams never close. The second
    // selection therefore stalls forever (verified with a failing test:
    // removing Maya never re-emits Leo). This controller implements the
    // intended *switch* semantics instead — the ledger subscription follows
    // the current selection — with no change to the public shape. The four
    // base streams still combine with the shared `combineLatest4` helper.
    late final StreamController<ChildProfile?> controller;
    controller = StreamController<ChildProfile?>(
      onListen: () {
        StreamSubscription<List<dynamic>>? baseSub;
        StreamSubscription<List<LedgerEntry>>? ledgerSub;
        // Latest base snapshot; ledger rows are only meaningful against it.
        List<dynamic>? latestParts;
        // Child id the live ledger subscription tracks, with its rows.
        // Null rows mean "subscription switched, fresh data not here yet":
        // never emit a profile with another selection's ledger.
        String? ledgerChildId;
        List<LedgerEntry>? latestLedger;

        void tryEmit() {
          final parts = latestParts;
          final ledger = latestLedger;
          if (parts == null || ledger == null) return;
          final appState = parts[0] as AppStateData?;
          final kids = parts[1] as List<ChildrenData>;
          final quests = parts[2] as List<Quest>;
          final completions = parts[3] as List<QuestCompletion>;
          final selected = _selectProfileChild(
            _effectiveSelection(appState?.activeChildId, kids),
            kids,
          );
          if (selected == null || ledgerChildId != selected.id) return;
          controller.add(
            _toProfile(
              selected,
              quests,
              completions,
              ledger,
              // PERIODS ruling: `now` is taken at emission (via the
              // injectable clock so tests can pin it — P15-BUG-8).
              _clock(),
            ),
          );
        }

        baseSub =
            combineLatest4(
              _db.watchAppState(),
              // Creation order (CHILD ORDER ruling) via the shared helper.
              _db.watchChildren(Seed.familyId),
              _db.watchActiveQuests(Seed.familyId),
              _db.watchAllCompletions(Seed.familyId),
            ).listen((parts) async {
              latestParts = parts;
              final appState = parts[0] as AppStateData?;
              final kids = parts[1] as List<ChildrenData>;
              final selected = _selectProfileChild(
                _effectiveSelection(appState?.activeChildId, kids),
                kids,
              );
              if (selected == null) {
                await ledgerSub?.cancel();
                ledgerSub = null;
                ledgerChildId = null;
                latestLedger = null;
                controller.add(null);
                return;
              }
              if (ledgerChildId != selected.id) {
                await ledgerSub?.cancel();
                ledgerChildId = selected.id;
                latestLedger = null;
                // The fresh subscription emits the current rows on its own;
                // that emission (not this one) drives the profile update.
                ledgerSub = _db.watchLedger(selected.id).listen((rows) {
                  latestLedger = rows;
                  tryEmit();
                }, onError: controller.addError);
                return;
              }
              tryEmit();
            }, onError: controller.addError);

        controller.onCancel = () async {
          await baseSub?.cancel();
          await ledgerSub?.cancel();
        };
      },
    );
    return controller.stream;
  }

  /// P15 selection: `activeChildId` match, else the first child in creation
  /// order (the query above already sorts that way), else null.
  ChildrenData? _selectProfileChild(
    String? activeChildId,
    List<ChildrenData> kids,
  ) {
    if (kids.isEmpty) return null;
    if (activeChildId != null) {
      for (final kid in kids) {
        if (kid.id == activeChildId) return kid;
      }
    }
    return kids.first;
  }

  /// The id the mapper resolves: the in-memory `selectChild` request when it
  /// names a loaded child (set synchronously, so the deep link wins on the
  /// very first emission), else the persisted `activeChildId` (which the
  /// async validation converges to the same value).
  String? _effectiveSelection(String? activeChildId, List<ChildrenData> kids) {
    final requested = _pendingSelection;
    if (requested != null) {
      for (final kid in kids) {
        if (kid.id == requested) return requested;
      }
    }
    return activeChildId;
  }

  ChildProfile _toProfile(
    ChildrenData row,
    List<Quest> quests,
    List<QuestCompletion> completions,
    List<LedgerEntry> ledger,
    DateTime now,
  ) {
    var daily = 0;
    var weekly = 0;
    var once = 0;
    for (final quest in quests) {
      if (!quest.active || quest.assigneeChildId != row.id) continue;
      switch (quest.repeatRule) {
        case 'daily':
          daily++;
        case 'weekly':
          weekly++;
        default:
          // 'once', plus unknown rules (same fallback as the plan).
          once++;
      }
    }
    final repeatByQuest = <String, String>{
      for (final quest in quests) quest.id: quest.repeatRule,
    };
    var thisWeek = 0;
    for (final completion in completions) {
      if (completion.childId != row.id) continue;
      if (completion.status != 'done_pending' &&
          completion.status != 'approved') {
        continue;
      }
      final repeat = repeatByQuest[completion.questId] ?? 'once';
      if (countsForCurrentPeriod(repeat, completion.createdAt, now)) {
        thisWeek++;
      }
    }
    return ChildProfile(
      child: _toChild(row, quests, completions),
      questsThisWeek: thisWeek,
      dailyActive: daily,
      weeklyActive: weekly,
      onceActive: once,
      owedPence: _owedPence(ledger),
    );
  }

  /// Owed math for one child's ledger — the same pure algorithm as
  /// `PocketMoneyRepositoryImpl.summarise`
  /// (`features/pocket_money/data/pocket_money_repository_impl.dart:259-284`):
  /// only `weekly_base` + `quest_bonus` rows at or after the latest `payout`
  /// instant count. Replicated here (no cross-feature import) so the family
  /// feature stays self-contained.
  static int _owedPence(List<LedgerEntry> rows) {
    DateTime? latestPayout;
    for (final row in rows) {
      if (row.type == 'payout' &&
          (latestPayout == null || row.date.isAfter(latestPayout))) {
        latestPayout = row.date;
      }
    }
    var total = 0;
    for (final row in rows) {
      if (row.type != 'weekly_base' && row.type != 'quest_bonus') continue;
      if (latestPayout != null && row.date.isBefore(latestPayout)) continue;
      total += row.amountPence;
    }
    return total;
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
  Future<void> selectChild(String childId) async {
    // P15-BUG-1: the `?childId=` deep link persists through the session so
    // `watchProfile` — and every sibling screen — follows it. The request is
    // recorded synchronously so the mapper honours it on the very first
    // emission (widget proofs assert after a fixed number of pumps); the
    // async validation then converges the persisted row to the same value.
    // Unknown ids are ignored: `_selectProfileChild` already falls back to
    // the first-created child, and persisting junk would poison the sibling
    // repositories that resolve `activeChildId` (P15-BUG-7 class). A
    // superseded request never clobbers a newer one.
    _pendingSelection = childId;
    final row = await (_db.select(
      _db.children,
    )..where((c) => c.id.equals(childId))).getSingleOrNull();
    if (_pendingSelection != childId) return;
    if (row == null) {
      _pendingSelection = null;
      return;
    }
    await (_db.update(_db.appState)..where((a) => a.id.equals(1))).write(
      AppStateCompanion(activeChildId: Value(childId)),
    );
  }

  @override
  Future<void> removeChild(String childId) {
    // P15-BUG-6: the confirm modal promises "They will lose their quests,
    // coins and Pip", so every dependent row goes with the child in one
    // transaction (the schema's `references(Children, #id)` are declarative
    // only — `beforeOpen` never enables `PRAGMA foreign_keys`, so nothing
    // cascades). P15-BUG-7: when the removed child was the persisted
    // selection, repoint it at the first remaining child in creation order
    // (the P15 fallback), or NULL when the family is empty.
    return _db.transaction(() async {
      await (_db.delete(
        _db.questCompletions,
      )..where((c) => c.childId.equals(childId))).go();
      await (_db.delete(
        _db.ledgerEntries,
      )..where((l) => l.childId.equals(childId))).go();
      await (_db.delete(
        _db.savingsGoals,
      )..where((g) => g.childId.equals(childId))).go();
      await (_db.delete(
        _db.rewardRedemptions,
      )..where((r) => r.childId.equals(childId))).go();
      await (_db.delete(
        _db.earnedBadges,
      )..where((e) => e.childId.equals(childId))).go();
      await (_db.delete(
        _db.pipWardrobe,
      )..where((w) => w.childId.equals(childId))).go();
      await (_db.delete(
        _db.quests,
      )..where((q) => q.assigneeChildId.equals(childId))).go();
      await (_db.delete(_db.children)..where((c) => c.id.equals(childId))).go();
      final session = await (_db.select(
        _db.appState,
      )..where((a) => a.id.equals(1))).getSingleOrNull();
      if (session?.activeChildId == childId) {
        final next =
            await (_db.select(_db.children)
                  ..where((c) => c.familyId.equals(Seed.familyId))
                  ..orderBy([
                    (c) => OrderingTerm(expression: c.createdAt),
                    (c) => OrderingTerm(
                      expression: const CustomExpression<int>('rowid'),
                    ),
                  ])
                  ..limit(1))
                .getSingleOrNull();
        await (_db.update(_db.appState)..where((a) => a.id.equals(1))).write(
          AppStateCompanion(activeChildId: Value(next?.id)),
        );
      }
    });
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
