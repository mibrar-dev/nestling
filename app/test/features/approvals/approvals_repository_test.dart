// `drift` exports an `isNull` that collides with matcher's; only the `Value`
// companion wrapper is needed from it.
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/approvals/data/approvals_repository_impl.dart';
import 'package:nestling/features/approvals/data/models/approval_model.dart';
import 'package:nestling/features/approvals/domain/entities/approval.dart';

import '../../test_scope.dart';

Future<List<LedgerEntry>> questBonusRows(AppDatabase db) async {
  final rows = await db.select(db.ledgerEntries).get();
  return rows.where((r) => r.type == 'quest_bonus').toList();
}

void main() {
  // `ORCHESTRATOR_NOTES.md` item 1 data half: the child's own words travel
  // from `quest_completions.kid_note` (schema v6, seeded) through the
  // repository into the card. The rendering half lives in
  // `approvals_quote_test.dart`.
  group('ApprovalsRepository kidNote', () {
    test('the seeded notes arrive RAW, without the curly quotes', () async {
      final db = await setUpTestScope();
      final items = await ApprovalsRepositoryImpl(db: db).getItems();

      Approval row(String quest) =>
          items.firstWhere((i) => i.questTitle == quest);

      // The seed stores the text as the child said it — the quotes are the
      // card's job (`completion_note_REPORT.md`).
      expect(
        row('Empty the dishwasher').kidNote,
        'I stacked everything neatly!',
      );
      expect(row('Make your bed').kidNote, 'I did the pillows too.');
      // q-table has no note: the card must render no quote and no gap.
      expect(row('Lay the table').kidNote, isNull);
      for (final item in items) {
        expect(
          item.kidNote ?? '',
          isNot(contains('“')),
          reason: 'quotes are added by the view, never stored',
        );
      }
    });

    test('a note written after the seed still reaches the card', () async {
      final db = await setUpTestScope();
      // q-table gets a note after seeding (K05-style write path).
      await (db.update(
        db.questCompletions,
      )..where((c) => c.questId.equals('q-table'))).write(
        const QuestCompletionsCompanion(kidNote: Value('All sorted!')),
      );

      final items = await ApprovalsRepositoryImpl(db: db).getItems();
      expect(
        items.firstWhere((i) => i.questTitle == 'Lay the table').kidNote,
        'All sorted!',
      );
    });

    test(
      'kidNote round-trips through ApprovalModel and is part of equality',
      () {
        final withNote = ApprovalModel(
          id: '1',
          title: 'Empty the dishwasher',
          detail: 'Maya · Today 8:12am',
          completionId: 1,
          questId: 'q-dishwasher',
          questTitle: 'Empty the dishwasher',
          childId: 'maya',
          childName: 'Maya',
          avatarColour: 'lilac',
          coins: 15,
          createdAt: DateTime.utc(2026, 10, 3, 7, 12),
          createdAtTz: 'Europe/London',
          kidNote: 'I stacked everything neatly!',
        );
        expect(ApprovalModel.fromJson(withNote.toJson()), withNote);
        expect(withNote.toJson()['kidNote'], 'I stacked everything neatly!');

        final withoutNote = ApprovalModel(
          id: '1',
          title: 'Lay the table',
          detail: 'Maya · Today 8:05am',
          completionId: 2,
          questId: 'q-table',
          questTitle: 'Lay the table',
          childId: 'maya',
          childName: 'Maya',
          avatarColour: 'lilac',
          coins: 10,
          createdAt: DateTime.utc(2026, 10, 3, 7, 5),
          createdAtTz: 'Europe/London',
        );
        expect(ApprovalModel.fromJson(withoutNote.toJson()).kidNote, isNull);
        expect(withoutNote, isNot(withNote));
      },
    );
  });

  group('ApprovalsRepository watchItems', () {
    test('demo seed emits exactly 3 pendings, oldest-first', () async {
      final db = await setUpTestScope();
      final impl = ApprovalsRepositoryImpl(db: db);
      final items = await impl.watchItems().first;

      expect(items, hasLength(3));
      // watchPendingApprovals orders createdAt ASC (oldest first); the
      // newest-first display sort lives in the bloc, not here.
      expect(
        items.map((i) => i.questTitle).toList(),
        orderedEquals(<String>[
          'Make your bed',
          'Lay the table',
          'Empty the dishwasher',
        ]),
      );
      expect(
        items.map((i) => i.childName).toList(),
        orderedEquals(<String>['Leo', 'Maya', 'Maya']),
      );
      expect(
        items.map((i) => i.coins).toList(),
        orderedEquals(<int>[5, 10, 15]),
      );
      // Creation order within the seed (insertion ids ascend with time here
      // except the two Maya rows, which were inserted newest-first).
      expect(
        items.map((i) => i.completionId).toList(),
        orderedEquals(<int>[3, 2, 1]),
      );
      for (final item in items) {
        expect(item.createdAtTz, 'Europe/London');
      }
      // Same instants the seed wrote (drift may return them in the local
      // zone, so compare normalised to UTC).
      expect(
        items.map((i) => i.createdAt.toUtc()).toList(),
        orderedEquals(<DateTime>[
          Seed.utc(10, 3, 6, 58),
          Seed.utc(10, 3, 7, 5),
          Seed.utc(10, 3, 7, 12),
        ]),
      );
      expect(items.first.childId, 'leo');
      expect(items.first.avatarColour, 'peach');
      expect(items.last.childId, 'maya');
      expect(items.last.avatarColour, 'lilac');
      // Seeded child notes (schema v6; q-table has none → NULL).
      expect(items[0].kidNote, 'I did the pillows too.');
      expect(items[1].kidNote, isNull);
      expect(items[2].kidNote, 'I stacked everything neatly!');
    });

    test('getItems matches the first watch emission', () async {
      final db = await setUpTestScope();
      final impl = ApprovalsRepositoryImpl(db: db);
      expect(await impl.getItems(), await impl.watchItems().first);
    });

    test('empty seed has no pending approvals', () async {
      final db = await setUpTestScope(seedDemo: false);
      final impl = ApprovalsRepositoryImpl(db: db);
      expect(await impl.getItems(), isEmpty);
    });
  });

  group('ApprovalsRepository approve', () {
    test('removes the row from pending and writes a quest_bonus row', () async {
      final db = await setUpTestScope();
      final impl = ApprovalsRepositoryImpl(db: db);
      final before = await questBonusRows(db);

      final items = await impl.getItems();
      final dishwasher = items.firstWhere(
        (i) => i.questTitle == 'Empty the dishwasher',
      );
      await impl.approve(dishwasher.completionId);

      final after = await impl.getItems();
      expect(after, hasLength(2));
      expect(
        after.map((i) => i.questTitle),
        isNot(contains('Empty the dishwasher')),
      );

      final bonus = await questBonusRows(db);
      expect(bonus, hasLength(before.length + 1));
      final mine = bonus.firstWhere(
        (r) =>
            r.childId == 'maya' &&
            r.amountPence == 15 &&
            r.note == 'Empty the dishwasher',
      );
      expect(mine.amountPence, dishwasher.coins);

      final row = await (db.select(
        db.questCompletions,
      )..where((c) => c.id.equals(dishwasher.completionId))).getSingle();
      expect(row.status, 'approved');
      expect(row.decidedAt, isNotNull);
    });

    test('approving an unknown id is a no-op', () async {
      final db = await setUpTestScope();
      final impl = ApprovalsRepositoryImpl(db: db);
      final bonusBefore = await questBonusRows(db);
      await impl.approve(999999);
      expect(await impl.getItems(), hasLength(3));
      expect(await questBonusRows(db), hasLength(bonusBefore.length));
    });
  });

  group('ApprovalsRepository markNotYet', () {
    test(
      'removes from pending with not_yet and writes NO ledger row',
      () async {
        final db = await setUpTestScope();
        final impl = ApprovalsRepositoryImpl(db: db);
        final ledgerBefore = await db.select(db.ledgerEntries).get();

        final items = await impl.getItems();
        final bed = items.firstWhere((i) => i.questTitle == 'Make your bed');
        await impl.markNotYet(bed.completionId);

        final after = await impl.getItems();
        expect(after, hasLength(2));
        expect(
          after.map((i) => i.questTitle),
          isNot(contains('Make your bed')),
        );

        final row = await (db.select(
          db.questCompletions,
        )..where((c) => c.id.equals(bed.completionId))).getSingle();
        expect(row.status, 'not_yet');
        expect(row.decidedAt, isNotNull);

        final ledgerAfter = await db.select(db.ledgerEntries).get();
        expect(ledgerAfter, hasLength(ledgerBefore.length));
      },
    );
  });

  group('ApprovalsRepository approveAll', () {
    test(
      'drains all 3 pendings; ledger gains 3 bonus rows totalling 30p',
      () async {
        final db = await setUpTestScope();
        final impl = ApprovalsRepositoryImpl(db: db);
        final bonusBefore = await questBonusRows(db);

        await impl.approveAll();

        expect(await impl.getItems(), isEmpty);
        final bonusAfter = await questBonusRows(db);
        final mine = bonusAfter.sublist(bonusBefore.length);
        expect(mine, hasLength(3));
        expect(mine.fold<int>(0, (sum, r) => sum + r.amountPence), 30);
      },
    );
  });

  group('ApprovalModel', () {
    test('round-trips createdAtTz and kidNote', () {
      final item = ApprovalModel(
        id: '1',
        title: 'Empty the dishwasher',
        detail: 'Maya · Today 8:12am',
        completionId: 1,
        questId: 'q-dishwasher',
        questTitle: 'Empty the dishwasher',
        childId: 'maya',
        childName: 'Maya',
        avatarColour: 'lilac',
        coins: 15,
        createdAt: DateTime.utc(2026, 10, 3, 7, 12),
        createdAtTz: 'Europe/London',
        kidNote: 'I stacked everything neatly!',
      );
      final back = ApprovalModel.fromJson(item.toJson());
      expect(back, item);
      expect(back.createdAtTz, 'Europe/London');
      expect(item.toJson()['createdAtTz'], 'Europe/London');
      expect(back.kidNote, 'I stacked everything neatly!');
    });

    test('kidNote defaults to null and survives missing JSON keys', () {
      final item = ApprovalModel(
        id: '2',
        title: 'Lay the table',
        detail: 'Maya · Today 8:05am',
        completionId: 2,
        questId: 'q-table',
        questTitle: 'Lay the table',
        childId: 'maya',
        childName: 'Maya',
        avatarColour: 'lilac',
        coins: 10,
        createdAt: DateTime.utc(2026, 10, 3, 7, 5),
        createdAtTz: 'Europe/London',
      );
      expect(item.kidNote, isNull);
      final json = item.toJson()..remove('kidNote');
      expect(ApprovalModel.fromJson(json), item);
    });

    test('createdAtTz is part of equality', () {
      final a = Approval(
        id: '1',
        title: 'T',
        detail: 'd',
        completionId: 1,
        questId: 'q',
        questTitle: 'T',
        childId: 'maya',
        childName: 'Maya',
        avatarColour: 'lilac',
        coins: 5,
        createdAt: DateTime.utc(2026, 10, 3, 6, 58),
        createdAtTz: 'Europe/London',
      );
      final b = Approval(
        id: '1',
        title: 'T',
        detail: 'd',
        completionId: 1,
        questId: 'q',
        questTitle: 'T',
        childId: 'maya',
        childName: 'Maya',
        avatarColour: 'lilac',
        coins: 5,
        createdAt: DateTime.utc(2026, 10, 3, 6, 58),
        createdAtTz: 'Asia/Dubai',
      );
      expect(a, isNot(b));
    });
  });
}
