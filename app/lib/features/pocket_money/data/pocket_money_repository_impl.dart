import 'package:drift/drift.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/london_time.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/pocket_money/domain/entities/owed_summary.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_entry.dart';
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
    return _db.watchLedger(childId).map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Future<OwedSummary> owed(String childId) => watchOwed(childId).first;

  @override
  Stream<OwedSummary> watchOwed(String childId) {
    return _db.watchLedger(childId).map((rows) => summarise(childId, rows));
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
  }) {
    return _db
        .into(_db.ledgerEntries)
        .insert(
          LedgerEntriesCompanion.insert(
            familyId: Seed.familyId,
            childId: childId,
            type: 'gift',
            amountPence: amountPence,
            note: Value(note),
            date: Value(DateTime.now().toUtc()),
          ),
        );
  }

  @override
  Future<void> recordSpending({
    required String childId,
    required int amountPence,
    required String note,
  }) {
    return _db
        .into(_db.ledgerEntries)
        .insert(
          LedgerEntriesCompanion.insert(
            familyId: Seed.familyId,
            childId: childId,
            type: 'spend',
            amountPence: -amountPence.abs(),
            note: Value(note),
            date: Value(DateTime.now().toUtc()),
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
    await _db.transaction(() async {
      await _db
          .into(_db.ledgerEntries)
          .insert(
            LedgerEntriesCompanion.insert(
              familyId: Seed.familyId,
              childId: childId,
              type: 'payout',
              amountPence: -amountPence.abs(),
              note: Value('Paid · ${formatLondonDay(now)}'),
              date: Value(now),
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

  PocketMoneyEntry _toEntity(LedgerEntry row) {
    return PocketMoneyEntry(
      id: row.id,
      title: row.note.isEmpty ? _typeLabel(row.type) : row.note,
      detail:
          '${_typeLabel(row.type)} · ${formatLondonDay(row.date)} '
          '${formatLondonTime(row.date)}',
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
