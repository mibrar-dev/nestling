import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/london_time.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/data/stream_combine.dart';
import 'package:nestling/features/today/domain/entities/child_day_summary.dart';
import 'package:nestling/features/today/domain/entities/today_item.dart';
import 'package:nestling/features/today/domain/today_repository.dart';

/// Drift-backed [TodayRepository]: joins quests, completions and children.
///
/// Rows are ordered pending-first (design order), then by title. Only
/// directly assigned quests appear here ("4 of 6" on P08); "Anyone" quests
/// live in the quest library (P10).
class TodayRepositoryImpl implements TodayRepository {
  new({required this._db, DateTime Function()? clock})
    : _clock = clock ?? _defaultClock;

  final AppDatabase _db;

  /// "Now" for period checks. Defaults to the seed anchor when tests pin it
  /// (so demo assertions stay date-independent) and to the wall clock
  /// otherwise — pass an explicit clock in tests that need one.
  final DateTime Function() _clock;

  static DateTime _defaultClock() =>
      Seed.anchorOverride ?? DateTime.now().toUtc();

  @override
  Future<List<TodayItem>> getItems() => watchItems().first;

  @override
  Stream<List<TodayItem>> watchItems() {
    return combineLatest3(
      _db.watchActiveQuests(Seed.familyId),
      _db.watchAllCompletions(Seed.familyId),
      _db.watchChildren(Seed.familyId),
    ).map((parts) {
      return rows(
        parts[0] as List<Quest>,
        parts[1] as List<QuestCompletion>,
        parts[2] as List<ChildrenData>,
      );
    });
  }

  @override
  Stream<List<ChildDaySummary>> watchSummaries() {
    return combineLatest2(watchItems(), _db.watchChildren(Seed.familyId)).map((
      parts,
    ) {
      final items = parts[0] as List<TodayItem>;
      final kids = parts[1] as List<ChildrenData>;
      final byChild = <String, List<TodayItem>>{};
      for (final item in items) {
        byChild.putIfAbsent(item.childId, () => <TodayItem>[]).add(item);
      }
      // Every child gets a card — including children with no assigned
      // quests yet (the ordinary state right after P05 "Add a child").
      final summaries =
          kids.map((kid) {
              final mine = byChild[kid.id] ?? const <TodayItem>[];
              return ChildDaySummary(
                childId: kid.id,
                nickname: kid.nickname,
                avatarColour: kid.avatarColour,
                pipStage: kid.pipStage,
                done: mine
                    .where(
                      (i) =>
                          i.status == 'done_pending' || i.status == 'approved',
                    )
                    .length,
                total: mine.length,
                coins: kid.coins,
                ageYears: kid.ageYears,
                happyDays: kid.happyDays,
                pipStyle: kid.pipStyle,
                pipSkin: kid.pipSkin,
                pipAccessory: kid.pipAccessory,
              );
            }).toList()
            // Eldest first (Maya 9 before Leo 6 in the demo), then nickname.
            ..sort((a, b) {
              final age = (b.ageYears ?? -1).compareTo(a.ageYears ?? -1);
              if (age != 0) return age;
              return a.nickname.compareTo(b.nickname);
            });
      return summaries;
    });
  }

  @override
  Stream<String> watchParentName() {
    return (_db.select(
      _db.members,
    )..where((m) => m.familyId.equals(Seed.familyId))).watch().map((rows) {
      if (rows.isEmpty) return 'Sarah';
      for (final row in rows) {
        if (row.role == 'owner') return row.name;
      }
      final sorted = rows.toList()..sort((a, b) => a.name.compareTo(b.name));
      return sorted.first.name;
    });
  }

  @override
  Stream<int> watchPayoutDay() {
    return (_db.select(_db.families)..where((f) => f.id.equals(Seed.familyId)))
        .watchSingleOrNull()
        .map((family) => family?.payoutDay ?? 6);
  }

  @override
  Stream<int> watchPendingCount() {
    // Period-scoped like the rows (P08-B13): only current-period
    // `done_pending` completions count — a stale pending is "to do" again
    // per the ruling, so the banner must not count it. Unknown quests
    // default to `once` (count forever) so a pending on a removed quest is
    // not silently dropped. NOTE: P11 must apply the same scoping or the
    // Review list will disagree with this count (SHARED_REQUEST §9).
    return combineLatest2(
      _db.watchAllCompletions(Seed.familyId),
      _db.watchActiveQuests(Seed.familyId),
    ).map((parts) {
      final rule = <String, String>{
        for (final q in parts[1] as List<Quest>) q.id: q.repeatRule,
      };
      final now = _clock();
      return (parts[0] as List<QuestCompletion>)
          .where(
            (c) =>
                c.status == 'done_pending' &&
                countsForCurrentPeriod(
                  rule[c.questId] ?? 'once',
                  c.createdAt,
                  now,
                ),
          )
          .length;
    });
  }

  /// Pure row builder, shared with tests.
  ///
  /// Statuses follow the periods ruling: a completion only counts inside its
  /// quest's current period (daily → London day, weekly → London week,
  /// once → forever); otherwise the quest is `to_do` again. [now] is
  /// computed once per call from the injected clock unless passed.
  List<TodayItem> rows(
    List<Quest> quests,
    List<QuestCompletion> completions,
    List<ChildrenData> kids, {
    DateTime? now,
  }) {
    final at = now ?? _clock();
    final out = <TodayItem>[];
    for (final kid in kids) {
      final mine = quests.where((q) => q.assigneeChildId == kid.id).toList()
        // Pending-first like the design, then alphabetical.
        ..sort((a, b) {
          final ra = _rankOf(_statusOf(a, kid.id, completions, at));
          final rb = _rankOf(_statusOf(b, kid.id, completions, at));
          if (ra != rb) return ra.compareTo(rb);
          return a.title.compareTo(b.title);
        });
      for (final quest in mine) {
        final status = _statusOf(quest, kid.id, completions, at);
        out.add(
          TodayItem(
            id: '${quest.id}:${kid.id}',
            title: quest.title,
            questId: quest.id,
            childId: kid.id,
            childName: kid.nickname,
            status: status,
            coins: quest.coins,
            repeatRule: quest.repeatRule,
            iconKey: quest.icon,
          ),
        );
      }
    }
    return out;
  }

  static String _statusOf(
    Quest quest,
    String childId,
    List<QuestCompletion> completions,
    DateTime now,
  ) {
    QuestCompletion? latest;
    for (final c in completions) {
      if (c.questId == quest.id && c.childId == childId) {
        if (latest == null || c.createdAt.isAfter(latest.createdAt)) {
          latest = c;
        }
      }
    }
    if (latest == null) return 'to_do';
    final current = countsForCurrentPeriod(
      quest.repeatRule,
      latest.createdAt,
      now,
    );
    return current ? latest.status : 'to_do';
  }

  /// Design order: `done_pending` → `to_do` → `not_yet` → `approved`.
  static int _rankOf(String status) {
    switch (status) {
      case 'done_pending':
        return 0;
      case 'to_do':
        return 1;
      case 'not_yet':
        return 2;
      default:
        return 3;
    }
  }
}
