import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart' hide Quest;
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
  group('QuestsRepository watchItems (P10 Active tab)', () {
    test(
      'demo seed yields 12 active quests: 6 Maya + 4 Leo + 2 Anyone',
      () async {
        final db = await setUpTestScope();
        final impl = QuestsRepositoryImpl(db: db);
        final items = await impl.watchItems().first;

        expect(items, hasLength(12));
        expect(items.where((q) => q.assigneeChildId == 'maya'), hasLength(6));
        expect(items.where((q) => q.assigneeChildId == 'leo'), hasLength(4));
        expect(items.where((q) => q.assigneeChildId == null), hasLength(2));
      },
    );

    test(
      'demo seed actives arrive in creation order (orchestrator §5)',
      () async {
        final db = await setUpTestScope();
        final impl = QuestsRepositoryImpl(db: db);
        final items = await impl.getItems();

        // Creation order (shared `watchActiveQuests`): Maya's 6 in the order
        // added, then Leo's 4, then the 2 Anyone quests — never alphabetical.
        final titles = items.map((q) => q.title).toList();
        expect(
          titles,
          orderedEquals(<String>[
            'Empty the dishwasher',
            'Reading – 20 minutes',
            'Put the bins out',
            'Tidy your bedroom',
            'Hoover the stairs',
            'Lay the table',
            'Make your bed',
            'Feed Biscuit the cat',
            'Pack school bag',
            'Water the plants',
            'Help with the washing',
            'Tidy the living room',
          ]),
        );
      },
    );

    test('watchItems re-emits when a quest row is inserted', () async {
      final db = await setUpTestScope();
      final impl = QuestsRepositoryImpl(db: db);
      final emissions = <List<Quest>>[];
      final sub = impl.watchItems().listen(emissions.add);
      addTearDown(sub.cancel);

      await pumpEventQueue();
      expect(emissions, isNotEmpty);
      expect(emissions.last, hasLength(12));

      await db
          .into(db.quests)
          .insert(
            QuestsCompanion.insert(
              id: 'q-extra',
              familyId: Seed.familyId,
              title: 'A brand new quest',
              coins: const Value(5),
            ),
          );
      await pumpEventQueue();

      expect(emissions.length, greaterThan(1));
      expect(emissions.last, hasLength(13));
    });

    test('deactivating a quest drops it from the stream', () async {
      final db = await setUpTestScope();
      final impl = QuestsRepositoryImpl(db: db);
      expect(await impl.watchItems().first, hasLength(12));

      await (db.update(db.quests)..where((q) => q.id.equals('q-bed'))).write(
        const QuestsCompanion(active: Value(false)),
      );

      expect(await impl.watchItems().first, hasLength(11));
    });

    test('empty seed has no active quests', () async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.empty(db);
      final impl = QuestsRepositoryImpl(db: db);
      expect(await impl.watchItems().first, isEmpty);
      expect(await impl.getItems(), isEmpty);
    });
  });

  group('QuestsRepository ideas() (P10 Ideas tab)', () {
    test('ten static templates with exact ids, titles and coins', () async {
      final db = await setUpTestScope();
      final ideas = QuestsRepositoryImpl(db: db).ideas();

      expect(ideas, hasLength(10));
      expect(
        ideas.map((q) => q.id).toList(),
        orderedEquals(<String>[
          'idea-bed',
          'idea-table',
          'idea-bins',
          'idea-dishwasher',
          'idea-hoover',
          'idea-pet',
          'idea-bag',
          'idea-plants',
          'idea-washing',
          'idea-reading',
        ]),
      );
      expect(
        ideas.map((q) => q.title).toList(),
        orderedEquals(<String>[
          'Make your bed',
          'Lay the table',
          'Put the bins out',
          'Empty the dishwasher',
          'Hoover the stairs',
          'Feed the pet',
          'Pack school bag',
          'Water the plants',
          'Help with the washing',
          'Read for 20 minutes',
        ]),
      );
      expect(
        ideas.map((q) => q.coins).toList(),
        orderedEquals(<int>[5, 10, 15, 15, 20, 5, 5, 10, 15, 10]),
      );
      // Templates are never stored rows: inactive, unassigned, P10-owned.
      for (final idea in ideas) {
        expect(idea.active, isFalse);
        expect(idea.assigneeChildId, isNull);
      }
    });
  });

  group('QuestsRepository CRUD', () {
    test('create + get round-trips every field', () async {
      final db = await setUpTestScope();
      final impl = QuestsRepositoryImpl(db: db);
      const quest = Quest(
        id: 'q-test',
        title: 'Test quest',
        detail: 'Daily · 10 coins',
        icon: 'star',
        coins: 10,
        repeatRule: 'daily',
        days: '',
        dueLabel: 'Before tea (5pm)',
        dueTimeLocal: '17:00',
        needsApproval: true,
        assigneeChildId: 'maya',
        active: true,
      );

      await impl.createQuest(quest);
      final fetched = await impl.getQuest('q-test');

      expect(fetched, quest);
    });

    test('update rewrites the row', () async {
      final db = await setUpTestScope();
      final impl = QuestsRepositoryImpl(db: db);
      final seeded = await impl.getQuest('q-bed');
      expect(seeded, isNotNull);

      await impl.updateQuest(seeded!.copyWith(title: 'Renamed quest'));
      expect((await impl.getQuest('q-bed'))!.title, 'Renamed quest');
    });

    test('delete removes the row', () async {
      final db = await setUpTestScope();
      final impl = QuestsRepositoryImpl(db: db);
      expect(await impl.getQuest('q-bed'), isNotNull);

      await impl.deleteQuest('q-bed');
      expect(await impl.getQuest('q-bed'), isNull);
      expect(await impl.watchItems().first, hasLength(11));
    });

    test('getQuest returns null for an unknown id', () async {
      final db = await setUpTestScope();
      final impl = QuestsRepositoryImpl(db: db);
      expect(await impl.getQuest('no-such-quest'), isNull);
    });
  });

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

extension on Quest {
  Quest copyWith({String? title}) => Quest(
    id: id,
    title: title ?? this.title,
    detail: detail,
    icon: icon,
    coins: coins,
    repeatRule: repeatRule,
    days: days,
    dueLabel: dueLabel,
    dueTimeLocal: dueTimeLocal,
    needsApproval: needsApproval,
    assigneeChildId: assigneeChildId,
    active: active,
  );
}
