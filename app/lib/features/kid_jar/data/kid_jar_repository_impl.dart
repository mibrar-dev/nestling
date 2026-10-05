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
import 'package:nestling/features/kid_jar/domain/entities/payout_celebration.dart';
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
  /// fans out to one atomic snapshot per child. Each snapshot derives from
  /// a single `watchLedger` emission (plus goals, setting and the
  /// quest-icon lookup), so the history list and the hero/goal figures can
  /// never pair rows with a stale owed figure.
  @override
  Stream<JarSnapshot> watchJar() {
    return _switchMap<AppStateData?, JarSnapshot>(
      _db.watchAppState(),
      (state) => _jarFor(state?.activeChildId ?? 'maya'),
    );
  }

  Stream<JarSnapshot> _jarFor(String childId) {
    return combineLatest4(
      _db.watchLedger(childId),
      _db.watchGoals(Seed.familyId),
      _db.watchSetting(Seed.familyId),
      _watchFamilyQuests(),
    ).map((parts) {
      final rows = parts[0] as List<LedgerEntry>;
      final goals = (parts[1] as List<SavingsGoal>)
          .where((g) => g.childId == childId)
          .toList();
      final setting = parts[2] as Setting?;
      final quests = parts[3] as List<Quest>;
      // Quest title → icon key, first match in creation order wins. The
      // ledger carries no quest reference, so the row's note (the quest
      // title) is the join key (K09-BUG-3).
      final iconForTitle = <String, String>{};
      for (final quest in quests) {
        iconForTitle.putIfAbsent(quest.title, () => quest.icon);
      }
      return JarSnapshot(
        childId: childId,
        items: _mapItems(rows, londonWeekStartUtc(appNowUtc()), iconForTitle),
        summary: _summarize(childId, rows, goals, setting),
      );
    });
  }

  /// Every quest in the family in creation order (the title → icon join
  /// source). All quests, not just active ones: a bonus row outlives the
  /// quest being switched off.
  Stream<List<Quest>> _watchFamilyQuests() {
    return (_db.select(_db.quests)
          ..where((q) => q.familyId.equals(Seed.familyId))
          ..orderBy([
            (q) => OrderingTerm(expression: q.createdAt),
            (q) => OrderingTerm(expression: q.id),
          ]))
        .watch();
  }

  /// K09 money-in list (NOT the P12 ledger): `weekly_base`, `quest_bonus`
  /// and `gift` rows only — `payout`/`spend`/`savings_move` never reach the
  /// jar. `watchLedger` is date-desc already, so the filter preserves
  /// newest-first order.
  static List<JarEntry> _mapItems(
    List<LedgerEntry> rows,
    DateTime weekStart,
    Map<String, String> iconForTitle,
  ) {
    return <JarEntry>[
      for (final row in rows)
        if (_moneyInTypes.contains(row.type))
          _toEntry(row, weekStart, iconForTitle),
    ];
  }

  @override
  Stream<JarSummary> watchSummary(String childId) => _summaryFor(childId);

  /// The K10 screen stream: `app_state.activeChildId` (`'maya'` fallback)
  /// fans out to one atomic celebration per child (same `_switchMap`
  /// pattern as [watchJar], K09-BUG-1 comment style).
  @override
  Stream<PayoutCelebration?> watchLatestPayout() {
    return _switchMap<AppStateData?, PayoutCelebration?>(
      _db.watchAppState(),
      (state) => _payoutFor(state?.activeChildId ?? 'maya'),
    );
  }

  Stream<PayoutCelebration?> _payoutFor(String childId) {
    return combineLatest3(
      _db.watchLedger(childId),
      _db.watchGoals(Seed.familyId),
      _db.watchChild(childId),
    ).map((parts) {
      final rows = parts[0] as List<LedgerEntry>;
      final goals = (parts[1] as List<SavingsGoal>)
          .where((g) => g.childId == childId)
          .toList();
      final child = parts[2] as ChildrenData?;
      // No row for the child (Seed.empty falls back to 'maya', which has no
      // row either): no celebration without a nickname and a Pip to cheer.
      if (child == null) return null;
      // Payout rows are event history, not quest status, so the PERIODS
      // ruling (a completion counts only for its current London
      // day/week) does NOT apply here — do not "fix" this to filter by
      // period. The latest `payout` row is the event, whatever week it
      // landed in. `watchLedger` is date-desc, so the first `payout` row
      // with the greatest date wins; ties keep ledger order.
      LedgerEntry? payout;
      for (final row in rows) {
        if (row.type == 'payout' &&
            (payout == null || row.date.isAfter(payout.date))) {
          payout = row;
        }
      }
      // No payout recorded yet → the view shows its empty state.
      if (payout == null) return null;
      final paidAt = payout.date;
      // The P13 companion move is written in the same transaction with the
      // same instant (`recordPayout` stamps both rows with one `now`), and
      // the seed's own `Jar → Lego fund` landed days after its payout — so
      // the companion is the newest `Jar → …` move stamped at or after the
      // payout instant, never before it. A later payout without a move then
      // correctly reads `movedPence: null`: the older move is before its
      // instant.
      LedgerEntry? move;
      for (final row in rows) {
        if (row.type == 'savings_move' &&
            row.note.startsWith('Jar →') &&
            !row.date.isBefore(paidAt)) {
          move = row;
          break;
        }
      }
      // Same goal pick as `_summarize`: the child's first goal. None → the
      // zero-goal fallback (fraction 0, `of £0.00` / `0% there!`).
      final goal = goals.isEmpty ? null : goals.first;
      return PayoutCelebration(
        childId: childId,
        nickname: child.nickname,
        paidPence: payout.amountPence.abs(),
        movedPence: move?.amountPence.abs(),
        goalTitle: goal?.title ?? 'Savings goal',
        goalSavedPence: goal?.savedPence ?? 0,
        goalTargetPence: goal?.targetPence ?? 0,
        pipStyle: child.pipStyle,
        pipSkin: child.pipSkin,
        pipAccessory: child.pipAccessory,
        pipStage: child.pipStage,
      );
    });
  }

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
    // The ledger is signed, so a correction row can push the period total
    // below zero — but a child can never be "owed" a negative amount, and
    // the hero must not render one as positive money coming (K09-BUG-5).
    final owed = base + quests;
    final goal = goals.isEmpty ? null : goals.first;
    return JarSummary(
      childId: childId,
      owedPence: owed < 0 ? 0 : owed,
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
      final goal = await (_db.select(
        _db.savingsGoals,
      )..where((g) => g.id.equals(goalId))).getSingleOrNull();
      // A savings move can never credit past the goal's remainder — without
      // the cap the data drifts over target and the card contradicts its own
      // "100% there!" (K09-BUG-4). A full goal makes the move a no-op.
      final requested = amountPence.abs();
      final remainder = goal == null
          ? requested
          : goal.targetPence - goal.savedPence;
      if (remainder <= 0) return;
      final move = requested < remainder ? requested : remainder;
      await _db
          .into(_db.ledgerEntries)
          .insert(
            LedgerEntriesCompanion.insert(
              familyId: Seed.familyId,
              childId: childId,
              type: 'savings_move',
              amountPence: move,
              note: const Value('Jar → savings goal'),
              date: Value(now),
              dateTz: Value(zone),
            ),
          );
      if (goal != null) {
        await (_db.update(
          _db.savingsGoals,
        )..where((g) => g.id.equals(goalId))).write(
          SavingsGoalsCompanion(savedPence: Value(goal.savedPence + move)),
        );
      }
    });
  }

  static JarEntry _toEntry(
    LedgerEntry row,
    DateTime weekStart,
    Map<String, String> iconForTitle,
  ) {
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
        // `''` when the note names no known quest — the view then uses its
        // fallback glyph (K09-BUG-3).
        iconKey: iconForTitle[row.note] ?? '',
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
