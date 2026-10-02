import 'package:drift/drift.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/family_time.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/data/stream_combine.dart';
import 'package:nestling/features/pocket_money/domain/entities/owed_summary.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_entry.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_setup.dart';
import 'package:nestling/features/pocket_money/domain/pocket_money_repository.dart';

/// Drift-backed [PocketMoneyRepository].
class PocketMoneyRepositoryImpl implements PocketMoneyRepository {
  new({required this._db});

  final AppDatabase _db;

  @override
  Future<List<PocketMoneyEntry>> getItems() => watchItems().first;

  @override
  Stream<List<PocketMoneyEntry>> watchItems() async* {
    final state = await (_db.select(
      _db.appState,
    )..where((a) => a.id.equals(1))).getSingleOrNull();
    final childId = state?.activeChildId ?? 'maya';
    yield* watchLedger(childId);
  }

  @override
  Stream<List<PocketMoneyEntry>> watchLedger(String childId) {
    // History renders in each row's stored zone (named when the family
    // moved); the stream re-emits when the family zone changes.
    return combineLatest2(
      _db.watchLedger(childId),
      _db.watchFamilyZoneId(),
    ).map((parts) {
      final familyZone = normalizeZoneId(parts[1] as String);
      return (parts[0] as List<LedgerEntry>)
          .map((row) => _toEntity(row, familyZone))
          .toList();
    });
  }

  @override
  Future<OwedSummary> owed(String childId) => watchOwed(childId).first;

  @override
  Stream<OwedSummary> watchOwed(String childId) {
    return _db.watchLedger(childId).map((rows) => summarise(childId, rows));
  }

  // -- P06 setup -------------------------------------------------------------

  @override
  Stream<PocketMoneySetup> watchSetup() {
    return combineLatest3(
      _watchFamily(),
      _db.watchSetting(Seed.familyId),
      _watchChildrenInsertionOrder(),
    ).map((parts) {
      // `families` is the source of truth; `settings` is its write-mirror
      // (kept equal by the setters below so P16 never diverges).
      final family = parts[0] as Family?;
      final children = parts[2] as List<ChildrenData>;
      return PocketMoneySetup(
        mode: family?.pocketMoneyMode ?? 'both',
        payoutDay: family?.payoutDay ?? 6,
        coinValuePencePerCoin: family?.coinValuePencePerCoin ?? 1,
        children: children
            .map(
              (row) => PocketMoneySetupChild(
                id: row.id,
                nickname: row.nickname,
                avatarColour: row.avatarColour,
                weeklyBasePence: row.weeklyBasePence,
              ),
            )
            .toList(),
      );
    });
  }

  /// The `families` row for the demo family (null until the first launch
  /// bootstrap in `beforeOpen` inserts it).
  Stream<Family?> _watchFamily() {
    return (_db.select(
      _db.families,
    )..where((f) => f.id.equals(Seed.familyId))).watchSingleOrNull();
  }

  /// Children in the order they were added (Maya, then Leo). Never
  /// `AppDatabase.watchChildren` — it orders by nickname (Leo first).
  Stream<List<ChildrenData>> _watchChildrenInsertionOrder() {
    return _db
        .customSelect(
          'SELECT * FROM children WHERE family_id = ? ORDER BY rowid',
          variables: <Variable>[Variable.withString(Seed.familyId)],
          readsFrom: <TableInfo<Table, dynamic>>{_db.children},
        )
        .watch()
        .map((rows) => rows.map((row) => _db.children.map(row.data)).toList());
  }

  @override
  Future<void> setMode(String mode) async {
    assert(
      mode == 'weekly' || mode == 'per_quest' || mode == 'both',
      'P06 mode must be weekly | per_quest | both, got $mode',
    );
    final now = DateTime.now().toUtc();
    final zone = await _db.familyZoneId();
    await _db.transaction(() async {
      await (_db.update(
        _db.families,
      )..where((f) => f.id.equals(Seed.familyId))).write(
        FamiliesCompanion(
          pocketMoneyMode: Value(mode),
          updatedAt: Value(now),
          updatedAtTz: Value(zone),
        ),
      );
      await (_db.update(
        _db.settings,
      )..where((s) => s.familyId.equals(Seed.familyId))).write(
        SettingsCompanion(
          pocketMoneyMode: Value(mode),
          updatedAt: Value(now),
          updatedAtTz: Value(zone),
        ),
      );
    });
  }

  @override
  Future<void> setPayoutDay(int day) async {
    assert(day >= 1 && day <= 7, 'P06 payout day must be 1..7, got $day');
    final now = DateTime.now().toUtc();
    final zone = await _db.familyZoneId();
    await _db.transaction(() async {
      await (_db.update(
        _db.families,
      )..where((f) => f.id.equals(Seed.familyId))).write(
        FamiliesCompanion(
          payoutDay: Value(day),
          updatedAt: Value(now),
          updatedAtTz: Value(zone),
        ),
      );
      await (_db.update(
        _db.settings,
      )..where((s) => s.familyId.equals(Seed.familyId))).write(
        SettingsCompanion(
          payoutDay: Value(day),
          updatedAt: Value(now),
          updatedAtTz: Value(zone),
        ),
      );
    });
  }

  @override
  Future<void> setWeeklyBasePence(String childId, int pence) async {
    await (_db.update(_db.children)..where((c) => c.id.equals(childId))).write(
      ChildrenCompanion(weeklyBasePence: Value(pence.clamp(0, 2000))),
    );
  }

  /// Pure owed math, shared with tests: entries arrive newest-first; only
  /// `weekly_base` + `quest_bonus` rows after the latest `payout` count.
  OwedSummary summarise(String childId, List<LedgerEntry> rows) {
    var base = 0;
    var quests = 0;
    for (final row in rows) {
      if (row.type == 'payout') break;
      if (row.type == 'weekly_base') base += row.amountPence;
      if (row.type == 'quest_bonus') quests += row.amountPence;
    }
    return OwedSummary(
      childId: childId,
      totalPence: base + quests,
      basePence: base,
      questsPence: quests,
    );
  }

  @override
  Future<void> addMoney({
    required String childId,
    required int amountPence,
    required String note,
  }) async {
    final zone = await _db.familyZoneId();
    await _db
        .into(_db.ledgerEntries)
        .insert(
          LedgerEntriesCompanion.insert(
            familyId: Seed.familyId,
            childId: childId,
            type: 'gift',
            amountPence: amountPence,
            note: Value(note),
            date: Value(DateTime.now().toUtc()),
            dateTz: Value(zone),
          ),
        );
  }

  @override
  Future<void> recordSpending({
    required String childId,
    required int amountPence,
    required String note,
  }) async {
    final zone = await _db.familyZoneId();
    await _db
        .into(_db.ledgerEntries)
        .insert(
          LedgerEntriesCompanion.insert(
            familyId: Seed.familyId,
            childId: childId,
            type: 'spend',
            amountPence: -amountPence.abs(),
            note: Value(note),
            date: Value(DateTime.now().toUtc()),
            dateTz: Value(zone),
          ),
        );
  }

  @override
  Future<void> recordPayout({
    required String childId,
    required int amountPence,
    int savingsMovePence = 0,
    String? goalId,
  }) async {
    final now = DateTime.now().toUtc();
    final zone = await _db.familyZoneId();
    await _db.transaction(() async {
      await _db
          .into(_db.ledgerEntries)
          .insert(
            LedgerEntriesCompanion.insert(
              familyId: Seed.familyId,
              childId: childId,
              type: 'payout',
              amountPence: -amountPence.abs(),
              note: Value('Paid · ${formatDay(now, zone)}'),
              date: Value(now),
              dateTz: Value(zone),
            ),
          );
      if (savingsMovePence > 0 && goalId != null) {
        await _db
            .into(_db.ledgerEntries)
            .insert(
              LedgerEntriesCompanion.insert(
                familyId: Seed.familyId,
                childId: childId,
                type: 'savings_move',
                amountPence: savingsMovePence.abs(),
                note: const Value('Jar → savings goal'),
                date: Value(now),
                dateTz: Value(zone),
              ),
            );
        final goal = await (_db.select(
          _db.savingsGoals,
        )..where((g) => g.id.equals(goalId))).getSingleOrNull();
        if (goal != null) {
          await (_db.update(
            _db.savingsGoals,
          )..where((g) => g.id.equals(goalId))).write(
            SavingsGoalsCompanion(
              savedPence: Value(goal.savedPence + savingsMovePence.abs()),
            ),
          );
        }
      }
    });
  }

  PocketMoneyEntry _toEntity(LedgerEntry row, String familyZone) {
    return PocketMoneyEntry(
      id: row.id,
      title: row.note.isEmpty ? _typeLabel(row.type) : row.note,
      detail:
          '${_typeLabel(row.type)} · ${formatDay(row.date, row.dateTz, familyZoneId: familyZone)} '
          '${formatTime(row.date, row.dateTz, familyZoneId: familyZone)}',
      childId: row.childId,
      type: row.type,
      amountPence: row.amountPence,
      note: row.note,
      date: row.date,
    );
  }

  static String _typeLabel(String type) {
    switch (type) {
      case 'weekly_base':
        return 'Weekly pocket money';
      case 'quest_bonus':
        return 'Quest bonus';
      case 'gift':
        return 'Added money';
      case 'spend':
        return 'Spent';
      case 'payout':
        return 'Paid';
      case 'savings_move':
        return 'To savings';
      default:
        return type;
    }
  }
}
