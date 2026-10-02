import 'package:drift/drift.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/family_time.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/data/stream_combine.dart';
import 'package:nestling/features/kid_jar/domain/entities/jar_entry.dart';
import 'package:nestling/features/kid_jar/domain/entities/jar_summary.dart';
import 'package:nestling/features/kid_jar/domain/kid_jar_repository.dart';

/// Drift-backed [KidJarRepository].
class KidJarRepositoryImpl implements KidJarRepository {
  new({required this._db});

  final AppDatabase _db;

  @override
  Future<List<JarEntry>> getItems() => watchItems().first;

  @override
  Stream<List<JarEntry>> watchItems() async* {
    final state = await (_db.select(
      _db.appState,
    )..where((a) => a.id.equals(1))).getSingleOrNull();
    yield* _entries(state?.activeChildId ?? 'maya');
  }

  Stream<List<JarEntry>> _entries(String childId) {
    // History renders in each row's stored zone (named when the family
    // moved); the stream re-emits when the family zone changes.
    return combineLatest2(
      _db.watchLedger(childId),
      _db.watchFamilyZoneId(),
    ).map(
      (parts) => (parts[0] as List<LedgerEntry>)
          .map((row) => _toEntity(row, normalizeZoneId(parts[1] as String)))
          .toList(),
    );
  }

  @override
  Stream<JarSummary> watchSummary(String childId) {
    return combineLatest3(
      _db.watchLedger(childId),
      _db.watchGoals(Seed.familyId),
      _db.watchSetting(Seed.familyId),
    ).map((parts) {
      final rows = parts[0] as List<LedgerEntry>;
      final goals = (parts[1] as List<SavingsGoal>)
          .where((g) => g.childId == childId)
          .toList();
      final setting = parts[2] as Setting?;
      var base = 0;
      var quests = 0;
      for (final row in rows) {
        if (row.type == 'payout') break;
        if (row.type == 'weekly_base') base += row.amountPence;
        if (row.type == 'quest_bonus') quests += row.amountPence;
      }
      final goal = goals.isEmpty ? null : goals.first;
      return JarSummary(
        childId: childId,
        owedPence: base + quests,
        nextPayoutDay: _weekday(setting?.payoutDay ?? 6),
        goalTitle: goal?.title ?? 'Savings goal',
        goalSavedPence: goal?.savedPence ?? 0,
        goalTargetPence: goal?.targetPence ?? 0,
      );
    });
  }

  @override
  Future<void> moveToSavings({
    required String childId,
    required String goalId,
    required int amountPence,
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
              type: 'savings_move',
              amountPence: amountPence.abs(),
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
            savedPence: Value(goal.savedPence + amountPence.abs()),
          ),
        );
      }
    });
  }

  JarEntry _toEntity(LedgerEntry row, String familyZone) {
    return JarEntry(
      id: '${row.id}',
      title: row.note.isEmpty ? row.type : row.note,
      detail: formatDay(row.date, row.dateTz, familyZoneId: familyZone),
      type: row.type,
      amountPence: row.amountPence,
      date: row.date,
    );
  }

  static String _weekday(int day) {
    const names = <int, String>{
      1: 'Monday',
      2: 'Tuesday',
      3: 'Wednesday',
      4: 'Thursday',
      5: 'Friday',
      6: 'Saturday',
      7: 'Sunday',
    };
    return names[day] ?? 'Saturday';
  }
}
