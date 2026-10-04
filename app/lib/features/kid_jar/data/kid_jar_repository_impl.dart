import 'dart:async';

import 'package:drift/drift.dart';
import 'package:nestling/core/data/app_clock.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/london_time.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/data/stream_combine.dart';
import 'package:nestling/features/kid_jar/domain/entities/jar_entry.dart';
import 'package:nestling/features/kid_jar/domain/entities/jar_snapshot.dart';
import 'package:nestling/features/kid_jar/domain/entities/jar_summary.dart';
import 'package:nestling/features/kid_jar/domain/kid_jar_repository.dart';

/// Drift-backed [KidJarRepository].
class KidJarRepositoryImpl implements KidJarRepository {
  new({required this._db});

  final AppDatabase _db;

  @override
  Future<List<JarEntry>> getItems() => watchItems().first;

  /// The K09 money-in list for the active child (same rows as [watchJar]).
  @override
  Stream<List<JarEntry>> watchItems() =>
      watchJar().map((snapshot) => snapshot.items);

  /// The K09 screen stream: `app_state.activeChildId` (`'maya'` fallback)
  /// fans out to exactly one entries query plus one summary query, so the
  /// history list and the hero/goal figures always arrive atomically.
  @override
  Stream<JarSnapshot> watchJar() {
    return _switchMap<AppStateData?, JarSnapshot>(
      _db.watchAppState(),
      (state) => _jarFor(state?.activeChildId ?? 'maya'),
    );
  }

  Stream<JarSnapshot> _jarFor(String childId) {
    // One ledger subscription feeds BOTH the list and the summary, so an
    // emission can never pair new rows with a stale owed figure (two
    // independent `watchLedger` subscriptions would race each other).
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
      return JarSnapshot(
        childId: childId,
        items: _mapItems(rows, londonWeekStartUtc(appNowUtc())),
        summary: _summarize(childId, rows, goals, setting),
      );
    });
  }

  /// K09 money-in list (NOT the P12 ledger): `weekly_base`, `quest_bonus`
  /// and `gift` rows only — `payout`/`spend`/`savings_move` never reach the
  /// jar. `watchLedger` is date-desc already, so the filter preserves
  /// newest-first order.
  static List<JarEntry> _mapItems(List<LedgerEntry> rows, DateTime weekStart) {
    return <JarEntry>[
      for (final row in rows)
        if (_moneyInTypes.contains(row.type)) _toEntry(row, weekStart),
    ];
  }

  @override
  Stream<JarSummary> watchSummary(String childId) => _summaryFor(childId);

  Stream<JarSummary> _summaryFor(String childId) {
    return _jarFor(childId).map((snapshot) => snapshot.summary);
  }

  static JarSummary _summarize(
    String childId,
    List<LedgerEntry> rows,
    List<SavingsGoal> goals,
    Setting? setting,
  ) {
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
  }

  @override
  Future<void> moveToSavings({
    required String childId,
    required String goalId,
    required int amountPence,
  }) async {
    final now = appNowUtc();
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

  static JarEntry _toEntry(LedgerEntry row, DateTime weekStart) {
    return switch (row.type) {
      'weekly_base' => JarEntry(
        id: '${row.id}',
        title: 'Pocket money',
        detail: _relativeDay(row.date, weekStart),
        type: row.type,
        amountPence: row.amountPence,
        date: row.date,
      ),
      'gift' => JarEntry(
        id: '${row.id}',
        title: _giftTitle(row.note),
        detail: _giftSub(row.note),
        type: row.type,
        amountPence: row.amountPence,
        date: row.date,
      ),
      _ => JarEntry(
        id: '${row.id}',
        title: row.note.isEmpty ? 'Quest bonus' : row.note,
        detail: 'Quest bonus',
        type: row.type,
        amountPence: row.amountPence,
        date: row.date,
      ),
    };
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

/// `This Saturday` when the entry's London date falls in the current London
/// week (Mon 00:00–Sun 24:00), else `Last {weekday}` — both from
/// `london_time.dart`, never `DateTime.now()`.
String _relativeDay(DateTime date, DateTime weekStart) {
  final name = KidJarRepositoryImpl._weekday(toLondon(date).weekday);
  return date.toUtc().isBefore(weekStart) ? 'Last $name' : 'This $name';
}

/// `Birthday money (added by Mum)` → `Birthday money`; a note with no
/// bracket suffix (or an empty note) falls back to `Gift`.
String _giftTitle(String note) {
  if (note.isEmpty) return 'Gift';
  final cut = note.indexOf(' (');
  return cut < 0 ? note : note.substring(0, cut);
}

/// `(added by Mum)` → `From Mum`; anything else falls back to `Gift`.
String _giftSub(String note) {
  final match = RegExp(r'\(added by ([^)]+)\)').firstMatch(note);
  if (match == null) return 'Gift';
  return 'From ${match.group(1)}';
}

const Set<String> _moneyInTypes = <String>{
  'weekly_base',
  'quest_bonus',
  'gift',
};

/// `switchMap` for never-closing Drift watch streams: every outer emission
/// cancels the previous inner subscription and forwards the new inner's
/// events. ([Stream.asyncExpand] cannot be used here — it pauses the outer
/// subscription until the current inner *closes*, and watch streams never
/// close, so an active-child switch after the first emission would stall
/// forever.) Feature-local copy of the `kid_home`/`kid_shop` helper: no
/// shared edits, no cross-feature import.
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
