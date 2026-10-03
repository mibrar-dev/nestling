import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/quests/data/quests_repository_impl.dart';
import 'package:nestling/features/quests/domain/entities/quest.dart';

import '../../test_scope.dart';

/// P09 editor backing store: every field the form edits must round-trip
/// verbatim through Drift (`title`, `icon`, `coins`, `repeatRule`, `days`,
/// `dueLabel`, `dueTimeLocal`, `needsApproval`, `assigneeChildId`).
const _draft = Quest(
  id: 'q-test-hoover',
  title: 'Hoover the stairs',
  detail: 'Weekly · 15 coins',
  icon: 'hoover',
  coins: 15,
  repeatRule: 'weekly',
  days: '6',
  dueLabel: 'Before tea (5pm)',
  dueTimeLocal: '17:00',
  needsApproval: true,
  assigneeChildId: 'maya',
  active: true,
);

void main() {
  group('QuestsRepository editor (P09)', () {
    test('demo seed pins the q-hoover edit fixture', () async {
      final db = await setUpTestScope();
      final repo = QuestsRepositoryImpl(db: db);

      final hoover = await repo.getQuest('q-hoover');
      expect(hoover, isNotNull);
      expect(hoover!.title, 'Hoover the stairs');
      expect(hoover.icon, 'hoover');
      expect(hoover.assigneeChildId, 'maya');
      expect(hoover.repeatRule, 'weekly');
      expect(hoover.active, isTrue);
    });

    test('create then getQuest round-trips every editor field', () async {
      final db = await setUpTestScope();
      final repo = QuestsRepositoryImpl(db: db);

      await repo.createQuest(_draft);
      final back = await repo.getQuest('q-test-hoover');

      expect(back, isNotNull);
      expect(back!.title, 'Hoover the stairs');
      expect(back.icon, 'hoover');
      expect(back.coins, 15);
      expect(back.repeatRule, 'weekly');
      expect(back.days, '6');
      expect(back.dueLabel, 'Before tea (5pm)');
      expect(back.dueTimeLocal, '17:00');
      expect(back.needsApproval, isTrue);
      expect(back.assigneeChildId, 'maya');
      expect(back.active, isTrue);
    });

    test(
      'create appends to the watched list (no reload event needed)',
      () async {
        final db = await setUpTestScope();
        final repo = QuestsRepositoryImpl(db: db);
        expect(await repo.getItems(), hasLength(12));

        final emissions = <List<Quest>>[];
        final sub = repo.watchItems().listen(emissions.add);
        addTearDown(sub.cancel);
        await pumpEventQueue();

        await repo.createQuest(_draft);
        await pumpEventQueue();

        expect(emissions.length, greaterThan(1));
        expect(emissions.last, hasLength(13));
        expect(emissions.last.map((q) => q.id), contains('q-test-hoover'));
      },
    );

    test('update persists title, coins, days and approval', () async {
      final db = await setUpTestScope();
      final repo = QuestsRepositoryImpl(db: db);
      await repo.createQuest(_draft);

      await repo.updateQuest(
        const Quest(
          id: 'q-test-hoover',
          title: 'Hoover the stairs properly',
          detail: 'Daily · 20 coins',
          icon: 'hoover',
          coins: 20,
          repeatRule: 'daily',
          days: '',
          dueLabel: 'Before bed (7:30pm)',
          dueTimeLocal: '19:30',
          needsApproval: false,
          assigneeChildId: null,
          active: true,
        ),
      );

      final back = await repo.getQuest('q-test-hoover');
      expect(back, isNotNull);
      expect(back!.title, 'Hoover the stairs properly');
      expect(back.coins, 20);
      expect(back.repeatRule, 'daily');
      expect(back.days, isEmpty);
      expect(back.dueLabel, 'Before bed (7:30pm)');
      expect(back.dueTimeLocal, '19:30');
      expect(back.needsApproval, isFalse);
      expect(back.assigneeChildId, isNull);
    });

    test('delete removes the quest; unknown id reads null', () async {
      final db = await setUpTestScope();
      final repo = QuestsRepositoryImpl(db: db);

      expect(await repo.getQuest('no-such-quest'), isNull);

      await repo.createQuest(_draft);
      expect(await repo.getQuest('q-test-hoover'), isNotNull);

      await repo.deleteQuest('q-test-hoover');
      expect(await repo.getQuest('q-test-hoover'), isNull);
      expect(await repo.getItems(), hasLength(12));
    });

    test('ideas() are the static P10 templates, never stored', () async {
      final db = await setUpTestScope();
      final repo = QuestsRepositoryImpl(db: db);

      expect(repo.ideas(), hasLength(10));
      expect(repo.ideas().map((q) => q.id), contains('idea-hoover'));
      // Templates are not rows: the table still holds the 12 live quests.
      expect(
        (await repo.getItems()).where((q) => q.id.startsWith('idea-')),
        isEmpty,
      );
    });

    test('Seed.familyId scopes every write', () async {
      final db = await setUpTestScope();
      final repo = QuestsRepositoryImpl(db: db);

      await repo.createQuest(_draft);
      final row = await (db.select(
        db.quests,
      )..where((q) => q.id.equals('q-test-hoover'))).getSingle();
      expect(row.familyId, Seed.familyId);
    });
  });
}
