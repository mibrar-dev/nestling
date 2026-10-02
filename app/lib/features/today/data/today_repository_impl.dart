import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/data/stream_combine.dart';
import 'package:nestling/features/today/domain/entities/child_day_summary.dart';
import 'package:nestling/features/today/domain/entities/today_item.dart';
import 'package:nestling/features/today/domain/today_repository.dart';

/// Drift-backed [TodayRepository]: joins quests, completions and children.
///
/// Rows are grouped by child (alphabetical) then quest title. Only directly
/// assigned quests appear here ("4 of 6" on P08); "Anyone" quests live in
/// the quest library (P10).
class TodayRepositoryImpl implements TodayRepository {
  new({required this._db});

  final AppDatabase _db;

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
      final kids = <String, ChildrenData>{
        for (final k in parts[1] as List<ChildrenData>) k.id: k,
      };
      final byChild = <String, List<TodayItem>>{};
      for (final item in items) {
        byChild.putIfAbsent(item.childId, () => <TodayItem>[]).add(item);
      }
      final summaries =
          byChild.values.map((mine) {
              final kid = kids[mine.first.childId];
              return ChildDaySummary(
                childId: mine.first.childId,
                nickname: mine.first.childName,
                avatarColour: kid?.avatarColour ?? 'lilac',
                pipStage: kid?.pipStage ?? 1,
                done: mine
                    .where(
                      (i) =>
                          i.status == 'done_pending' || i.status == 'approved',
                    )
                    .length,
                total: mine.length,
                coins: kid?.coins ?? 0,
                ageYears: kid?.ageYears,
                happyDays: kid?.happyDays ?? 0,
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

  /// Pure row builder, shared with tests.
  List<TodayItem> rows(
    List<Quest> quests,
    List<QuestCompletion> completions,
    List<ChildrenData> kids,
  ) {
    final out = <TodayItem>[];
    for (final kid in kids) {
      final mine = quests.where((q) => q.assigneeChildId == kid.id).toList()
        ..sort((a, b) => a.title.compareTo(b.title));
      for (final quest in mine) {
        final mine2 =
            completions
                .where((c) => c.questId == quest.id && c.childId == kid.id)
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final status = mine2.isEmpty ? 'to_do' : mine2.first.status;
        out.add(
          TodayItem(
            id: '${quest.id}:${kid.id}',
            title: quest.title,
            detail: '${kid.nickname} · ${_statusLabel(status)}',
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

  static String _statusLabel(String status) {
    switch (status) {
      case 'done_pending':
        return 'waiting for thumbs-up';
      case 'approved':
        return 'approved';
      case 'not_yet':
        return 'try again';
      default:
        return 'to do';
    }
  }
}
