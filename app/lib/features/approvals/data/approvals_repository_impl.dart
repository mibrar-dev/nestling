import 'package:drift/drift.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/family_time.dart';
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
    return combineLatest4(
      _db.watchPendingApprovals(Seed.familyId),
      _db.select(_db.quests).watch(),
      _db.watchChildren(Seed.familyId),
      _db.watchFamilyZoneId(),
    ).map((parts) {
      final pending = parts[0] as List<QuestCompletion>;
      final quests = <String, Quest>{
        for (final q in parts[1] as List<Quest>) q.id: q,
      };
      final kids = <String, ChildrenData>{
        for (final k in parts[2] as List<ChildrenData>) k.id: k,
      };
      // History renders in each row's stored zone; when the family moved,
      // the zone is named so "Sat 3 Oct (London)" stays unambiguous.
      final familyZone = normalizeZoneId(parts[3] as String);
      return pending.map((c) {
        final quest = quests[c.questId];
        final kid = kids[c.childId];
        final title = quest?.title ?? 'Quest';
        return Approval(
          id: '${c.id}',
          title: title,
          detail:
              '${kid?.nickname ?? 'Child'} · '
              '${formatDay(c.createdAt, c.createdAtTz, familyZoneId: familyZone)} '
              '${formatTime(c.createdAt, c.createdAtTz, familyZoneId: familyZone)}',
          completionId: c.id,
          questId: c.questId,
          questTitle: title,
          childId: c.childId,
          childName: kid?.nickname ?? 'Child',
          avatarColour: kid?.avatarColour ?? 'lilac',
          coins: c.coins,
          createdAt: c.createdAt,
          createdAtTz: c.createdAtTz,
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
    final zone = await _db.familyZoneId();
    await _db.transaction(() async {
      await (_db.update(
        _db.questCompletions,
      )..where((c) => c.id.equals(completionId))).write(
        QuestCompletionsCompanion(
          status: const Value('approved'),
          decidedAt: Value(now),
          decidedAtTz: Value(zone),
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
              dateTz: Value(zone),
            ),
          );
    });
  }

  @override
  Future<void> markNotYet(int completionId) async {
    final zone = await _db.familyZoneId();
    await (_db.update(
      _db.questCompletions,
    )..where((c) => c.id.equals(completionId))).write(
      QuestCompletionsCompanion(
        status: const Value('not_yet'),
        decidedAt: Value(DateTime.now().toUtc()),
        decidedAtTz: Value(zone),
      ),
    );
  }

  @override
  Future<void> approveAll() async {
    // One-shot select, NOT `watchItems().first`: a query stream never
    // delivers its first event under `testWidgets` fake async, so driving
    // "Approve all" through the bloc hung forever in widget tests (P11 2b
    // finding). Same predicate as `watchPendingApprovals`.
    final pending =
        await (_db.select(_db.questCompletions)..where(
              (c) =>
                  c.familyId.equals(Seed.familyId) &
                  c.status.equals('done_pending'),
            ))
            .get();
    for (final row in pending) {
      await approve(row.id);
    }
  }
}
