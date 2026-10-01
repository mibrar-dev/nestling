import 'package:drift/drift.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/london_time.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/data/stream_combine.dart';
import 'package:nestling/features/approvals/domain/approvals_repository.dart';
import 'package:nestling/features/approvals/domain/entities/approval.dart';

/// Drift-backed [ApprovalsRepository].
class ApprovalsRepositoryImpl implements ApprovalsRepository {
  new({required this._db});

  final AppDatabase _db;

  @override
  Future<List<Approval>> getItems() => watchItems().first;

  @override
  Stream<List<Approval>> watchItems() {
    return combineLatest3(
      _db.watchPendingApprovals(Seed.familyId),
      _db.select(_db.quests).watch(),
      _db.watchChildren(Seed.familyId),
    ).map((parts) {
      final pending = parts[0] as List<QuestCompletion>;
      final quests = <String, Quest>{
        for (final q in parts[1] as List<Quest>) q.id: q,
      };
      final kids = <String, ChildrenData>{
        for (final k in parts[2] as List<ChildrenData>) k.id: k,
      };
      return pending.map((c) {
        final quest = quests[c.questId];
        final kid = kids[c.childId];
        final title = quest?.title ?? 'Quest';
        return Approval(
          id: '${c.id}',
          title: title,
          detail:
              '${kid?.nickname ?? 'Child'} · '
              '${formatLondonDay(c.createdAt)} ${formatLondonTime(c.createdAt)}',
          completionId: c.id,
          questId: c.questId,
          questTitle: title,
          childId: c.childId,
          childName: kid?.nickname ?? 'Child',
          avatarColour: kid?.avatarColour ?? 'lilac',
          coins: c.coins,
          createdAt: c.createdAt,
        );
      }).toList();
    });
  }

  @override
  Future<void> approve(int completionId) async {
    final completion = await (_db.select(
      _db.questCompletions,
    )..where((c) => c.id.equals(completionId))).getSingleOrNull();
    if (completion == null || completion.status != 'done_pending') return;
    final now = DateTime.now().toUtc();
    await _db.transaction(() async {
      await (_db.update(
        _db.questCompletions,
      )..where((c) => c.id.equals(completionId))).write(
        QuestCompletionsCompanion(
          status: const Value('approved'),
          decidedAt: Value(now),
        ),
      );
      final quest = await (_db.select(
        _db.quests,
      )..where((q) => q.id.equals(completion.questId))).getSingleOrNull();
      await _db
          .into(_db.ledgerEntries)
          .insert(
            LedgerEntriesCompanion.insert(
              familyId: Seed.familyId,
              childId: completion.childId,
              type: 'quest_bonus',
              amountPence: completion.coins,
              note: Value(quest?.title ?? 'Quest'),
              date: Value(now),
            ),
          );
    });
  }

  @override
  Future<void> markNotYet(int completionId) {
    return (_db.update(
      _db.questCompletions,
    )..where((c) => c.id.equals(completionId))).write(
      QuestCompletionsCompanion(
        status: const Value('not_yet'),
        decidedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  @override
  Future<void> approveAll() async {
    final pending = await watchItems().first;
    for (final approval in pending) {
      await approve(approval.completionId);
    }
  }
}
