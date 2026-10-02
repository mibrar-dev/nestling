import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/today/data/models/today_item_model.dart';
import 'package:nestling/features/today/data/today_repository_impl.dart';
import 'package:nestling/features/today/domain/entities/child_day_summary.dart';
import 'package:nestling/features/today/domain/entities/today_item.dart';

import '../../test_scope.dart';

void main() {
  group('TodayRepository rows()', () {
    test('demo seed groups by child with latest-completion status', () async {
      final db = await setUpTestScope();
      final impl = TodayRepositoryImpl(db: db);
      final items = await impl.getItems();

      // 6 Maya + 4 Leo assigned quests ("Anyone" quests excluded).
      expect(items, hasLength(10));
      final maya = items.where((i) => i.childId == 'maya').toList();
      final leo = items.where((i) => i.childId == 'leo').toList();
      expect(maya, hasLength(6));
      expect(leo, hasLength(4));

      // Pending-first like the design, then α-sorted within each rank.
      final titles = maya.map((i) => i.title).toList();
      expect(
        titles,
        orderedEquals(<String>[
          'Empty the dishwasher',
          'Lay the table',
          'Reading – 20 minutes',
          'Tidy your bedroom',
          'Hoover the stairs',
          'Put the bins out',
        ]),
      );

      // Latest completion wins: pending, approved, and to-do rows present.
      final byQuest = {for (final i in items) i.questId: i};
      expect(byQuest['q-dishwasher']!.status, 'done_pending');
      expect(byQuest['q-bins']!.status, 'approved');
      expect(byQuest['q-reading']!.status, 'to_do');

      // Cadence + icon snapshot travel on the item (seed e94d063: everyday
      // chores repeat daily; bins + hoover stay weekly).
      expect(byQuest['q-dishwasher']!.repeatRule, 'daily');
      expect(byQuest['q-bins']!.repeatRule, 'weekly');
      expect(byQuest['q-dishwasher']!.iconKey, 'dishwasher');
      expect(byQuest['q-reading']!.iconKey, 'book');
      expect(byQuest['q-biscuit']!.iconKey, 'paw');
    });

    test('a newer completion overrides an older one', () async {
      final db = await setUpTestScope();
      await db
          .into(db.questCompletions)
          .insert(
            QuestCompletionsCompanion.insert(
              questId: 'q-reading',
              childId: 'maya',
              familyId: Seed.familyId,
              status: const Value('done_pending'),
              coins: const Value(10),
              createdAt: Value(Seed.utc(10, 3, 9)),
            ),
          );
      final impl = TodayRepositoryImpl(db: db);
      final items = await impl.getItems();
      final reading = items.firstWhere((i) => i.questId == 'q-reading');
      expect(reading.status, 'done_pending');
    });

    test('not_yet rows sit between to_do and approved', () async {
      final db = await setUpTestScope();
      // A newer "try again" completion outranks the seeded to_do row.
      await db
          .into(db.questCompletions)
          .insert(
            QuestCompletionsCompanion.insert(
              questId: 'q-reading',
              childId: 'maya',
              familyId: Seed.familyId,
              status: const Value('not_yet'),
              coins: const Value(10),
              createdAt: Value(Seed.utc(10, 3, 9)),
            ),
          );
      final impl = TodayRepositoryImpl(db: db);
      final items = await impl.getItems();
      final maya = items
          .where((i) => i.childId == 'maya')
          .map((i) => i.title)
          .toList();

      expect(
        maya,
        orderedEquals(<String>[
          'Empty the dishwasher', // done_pending
          'Lay the table', // done_pending
          'Tidy your bedroom', // to_do
          'Reading – 20 minutes', // not_yet (newest completion wins)
          'Hoover the stairs', // approved
          'Put the bins out', // approved
        ]),
      );
      expect(
        items.firstWhere((i) => i.questId == 'q-reading').status,
        'not_yet',
      );
    });

    test('not_yet status travels on the item', () async {
      final db = await setUpTestScope();
      await db
          .into(db.questCompletions)
          .insert(
            QuestCompletionsCompanion.insert(
              questId: 'q-tidy',
              childId: 'maya',
              familyId: Seed.familyId,
              status: const Value('not_yet'),
              coins: const Value(15),
              createdAt: Value(Seed.utc(10, 3, 9)),
            ),
          );
      final impl = TodayRepositoryImpl(db: db);
      final items = await impl.getItems();
      final tidy = items.firstWhere((i) => i.questId == 'q-tidy');
      expect(tidy.status, 'not_yet');
    });
  });

  group('TodayRepository streams', () {
    test('watchItems re-emits when a completion is inserted', () async {
      final db = await setUpTestScope();
      final impl = TodayRepositoryImpl(db: db);
      final emissions = <List<TodayItem>>[];
      final sub = impl.watchItems().listen(emissions.add);
      addTearDown(sub.cancel);

      await pumpEventQueue();
      expect(emissions, isNotEmpty);
      expect(
        emissions.last.firstWhere((i) => i.questId == 'q-reading').status,
        'to_do',
        reason: 'seed state before the new completion',
      );

      await db
          .into(db.questCompletions)
          .insert(
            QuestCompletionsCompanion.insert(
              questId: 'q-reading',
              childId: 'maya',
              familyId: Seed.familyId,
              status: const Value('done_pending'),
              coins: const Value(10),
              createdAt: Value(Seed.utc(10, 3, 9)),
            ),
          );
      await pumpEventQueue();

      expect(emissions.length, greaterThan(1));
      expect(
        emissions.last.firstWhere((i) => i.questId == 'q-reading').status,
        'done_pending',
        reason: 'the bloc relies on this live re-emission (no reload events)',
      );
    });

    test('watchPendingCount re-emits when a new approval arrives', () async {
      final db = await setUpTestScope();
      final impl = TodayRepositoryImpl(db: db);
      final counts = <int>[];
      final sub = impl.watchPendingCount().listen(counts.add);
      addTearDown(sub.cancel);

      await pumpEventQueue();
      expect(counts.last, 3);

      // "Anyone" quest (q-washing) pending: still counts on Today's banner.
      await db
          .into(db.questCompletions)
          .insert(
            QuestCompletionsCompanion.insert(
              questId: 'q-washing',
              childId: 'maya',
              familyId: Seed.familyId,
              status: const Value('done_pending'),
              coins: const Value(15),
              createdAt: Value(Seed.utc(10, 3, 9)),
            ),
          );
      await pumpEventQueue();

      expect(counts.length, greaterThan(1));
      expect(counts.last, 4);
    });
  });

  group('TodayRepository summaries', () {
    test('demo seed cards: Maya 4/6 + 120, Leo 1/4 + 45', () async {
      final db = await setUpTestScope();
      final impl = TodayRepositoryImpl(db: db);
      final summaries = await impl.watchSummaries().first;

      expect(summaries, hasLength(2));
      // Eldest first: Maya (9) before Leo (6).
      expect(summaries[0].childId, 'maya');
      expect(summaries[1].childId, 'leo');

      final maya = summaries[0];
      expect(maya.nickname, 'Maya');
      expect(maya.done, 4); // dishwasher+table pending, bins+hoover approved
      expect(maya.total, 6);
      expect(maya.coins, 120);
      expect(maya.pipStage, 3);
      expect(maya.avatarColour, 'lilac');
      expect(maya.ageYears, 9);
      expect(maya.happyDays, 4);
      expect(maya.pipStyle, 'mochi');
      expect(maya.pipSkin, 'sunny');
      expect(maya.pipAccessory, 'none');

      final leo = summaries[1];
      expect(leo.done, 1); // bed pending; bag's daily approval is yesterday's
      expect(leo.total, 4);
      expect(leo.coins, 45);
      expect(leo.pipStage, 2);
      expect(leo.ageYears, 6);
      expect(leo.happyDays, 3);
      expect(leo.pipStyle, 'bolt');
      expect(leo.pipSkin, 'sky');
    });

    test('a child with no assigned quests still gets a summary', () async {
      final db = await setUpTestScope();
      await db
          .into(db.children)
          .insert(
            ChildrenCompanion.insert(
              id: 'sam',
              familyId: Seed.familyId,
              nickname: 'Sam',
              ageYears: const Value(5),
            ),
          );
      final impl = TodayRepositoryImpl(db: db);
      final summaries = await impl.watchSummaries().first;

      expect(summaries, hasLength(3));
      final sam = summaries.firstWhere((s) => s.childId == 'sam');
      expect(sam.nickname, 'Sam');
      expect(sam.done, 0);
      expect(sam.total, 0);
      expect(sam.coins, 0);
      expect(sam.ageYears, 5);
    });

    test('pending count covers unassigned quests too', () async {
      final db = await setUpTestScope();
      final impl = TodayRepositoryImpl(db: db);
      expect(await impl.watchPendingCount().first, 3);

      await db
          .into(db.questCompletions)
          .insert(
            QuestCompletionsCompanion.insert(
              questId: 'q-living',
              childId: 'leo',
              familyId: Seed.familyId,
              status: const Value('done_pending'),
              coins: const Value(10),
              createdAt: Value(Seed.utc(10, 3, 9)),
            ),
          );
      expect(await impl.watchPendingCount().first, 4);
    });

    test('empty seed has no summaries', () async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.empty(db);
      final impl = TodayRepositoryImpl(db: db);
      expect(await impl.watchSummaries().first, isEmpty);
      expect(await impl.watchItems().first, isEmpty);
    });
  });

  group('TodayRepository header', () {
    test('parent name is Sarah, payout day is Saturday', () async {
      final db = await setUpTestScope();
      final impl = TodayRepositoryImpl(db: db);
      expect(await impl.watchParentName().first, 'Sarah');
      expect(await impl.watchPayoutDay().first, 6);
    });

    test('fresh db falls back to Sarah / Saturday', () async {
      final db = await setUpTestScope(seedDemo: false);
      final impl = TodayRepositoryImpl(db: db);
      expect(await impl.watchParentName().first, 'Sarah');
      expect(await impl.watchPayoutDay().first, 6);
    });
  });

  group('TodayRepository periods (Europe/London ruling)', () {
    Future<void> clearCompletions(AppDatabase db, String questId) => (db.delete(
      db.questCompletions,
    )..where((c) => c.questId.equals(questId))).go();

    Future<void> insertCompletion(
      AppDatabase db, {
      required String questId,
      required String childId,
      required String status,
      required DateTime createdAt,
    }) => db
        .into(db.questCompletions)
        .insert(
          QuestCompletionsCompanion.insert(
            questId: questId,
            childId: childId,
            familyId: Seed.familyId,
            status: Value(status),
            coins: const Value(10),
            createdAt: Value(createdAt),
          ),
        );

    Future<String> statusOf(
      AppDatabase db,
      DateTime now,
      String questId,
    ) async {
      // Explicit clock: this group owns "now" instead of using the anchor.
      final impl = TodayRepositoryImpl(db: db, clock: () => now);
      final items = await impl.getItems();
      return items.firstWhere((i) => i.questId == questId).status;
    }

    test(
      'daily: 00:30 London counts, even though its UTC date is 2 Oct',
      () async {
        final db = await setUpTestScope();
        await clearCompletions(db, 'q-reading');
        // BST on 3 Oct: London = UTC+1, so 00:30 London is 2 Oct 23:30 UTC.
        await insertCompletion(
          db,
          questId: 'q-reading',
          childId: 'maya',
          status: 'approved',
          createdAt: DateTime.utc(2026, 10, 2, 23, 30),
        );

        expect(
          await statusOf(db, DateTime.utc(2026, 10, 3), 'q-reading'),
          'approved',
          reason: 'the ruling is about the London day, not the UTC day',
        );
      },
    );

    test('daily: 23:30 London yesterday does not count', () async {
      final db = await setUpTestScope();
      await clearCompletions(db, 'q-reading');
      // 2 Oct 22:30 UTC = 2 Oct 23:30 London (BST) — yesterday's London day.
      await insertCompletion(
        db,
        questId: 'q-reading',
        childId: 'maya',
        status: 'approved',
        createdAt: DateTime.utc(2026, 10, 2, 22, 30),
      );

      expect(
        await statusOf(db, DateTime.utc(2026, 10, 3), 'q-reading'),
        'to_do',
      );
    });

    test('weekly: Monday 00:30 London counts (Sunday 23:30 UTC)', () async {
      final db = await setUpTestScope();
      await clearCompletions(db, 'q-bins');
      // This London week starts Mon 28 Sep 00:00 BST = 27 Sep 23:00 UTC.
      await insertCompletion(
        db,
        questId: 'q-bins',
        childId: 'maya',
        status: 'approved',
        createdAt: DateTime.utc(2026, 9, 27, 23, 30),
      );

      expect(
        await statusOf(db, DateTime.utc(2026, 10, 3), 'q-bins'),
        'approved',
      );
    });

    test('weekly: Sunday night before the week start does not count', () async {
      final db = await setUpTestScope();
      await clearCompletions(db, 'q-bins');
      await insertCompletion(
        db,
        questId: 'q-bins',
        childId: 'maya',
        status: 'approved',
        createdAt: DateTime.utc(2026, 9, 27, 22, 30),
      );

      expect(
        await statusOf(db, DateTime.utc(2026, 10, 3), 'q-bins'),
        'to_do',
        reason: 'Sunday 23:30 London belongs to the previous London week',
      );
    });

    test('daily across the BST→GMT switch (25 Oct 2026)', () async {
      final db = await setUpTestScope();
      await clearCompletions(db, 'q-reading');

      // 25 Oct is GMT from 01:00 UTC; the day start is 24 Oct 23:00 UTC.
      await insertCompletion(
        db,
        questId: 'q-reading',
        childId: 'maya',
        status: 'approved',
        createdAt: DateTime.utc(2026, 10, 24, 23, 30),
      );
      expect(
        await statusOf(db, DateTime.utc(2026, 10, 25, 12), 'q-reading'),
        'approved',
      );

      await clearCompletions(db, 'q-reading');
      await insertCompletion(
        db,
        questId: 'q-reading',
        childId: 'maya',
        status: 'approved',
        createdAt: DateTime.utc(2026, 10, 24, 22, 30),
      );
      expect(
        await statusOf(db, DateTime.utc(2026, 10, 25, 12), 'q-reading'),
        'to_do',
        reason: '23:30 London on 24 Oct is before the 25 Oct London day',
      );
    });

    test('summary counts follow the same period rule', () async {
      final db = await setUpTestScope();
      // Before the switch day, Leo bag's approval is still yesterday's:
      // 1 done of 4 on 3 Oct, but 2 of 4 if "now" is 2 Oct.
      final onStoryDay = TodayRepositoryImpl(
        db: db,
        clock: () => DateTime.utc(2026, 10, 3),
      );
      final leo = (await onStoryDay.watchSummaries().first).firstWhere(
        (s) => s.childId == 'leo',
      );
      expect(leo.done, 1);
      expect(leo.total, 4);

      final onPreviousDay = TodayRepositoryImpl(
        db: db,
        clock: () => DateTime.utc(2026, 10, 2, 12),
      );
      final yesterday = (await onPreviousDay.watchSummaries().first).firstWhere(
        (s) => s.childId == 'leo',
      );
      expect(
        yesterday.done,
        2,
        reason: "q-bag's 2 Oct approval is current on the 2 Oct London day",
      );
    });
  });

  group('Today entities', () {
    test('TodayItemModel round-trips repeat fields', () {
      const item = TodayItemModel(
        id: 'q1:maya',
        title: 'Test',
        questId: 'q1',
        childId: 'maya',
        childName: 'Maya',
        status: 'to_do',
        coins: 10,
        repeatRule: 'daily',
        iconKey: 'book',
      );
      final json = item.toJson();
      expect(json['repeatRule'], 'daily');
      expect(json['iconKey'], 'book');
      final back = TodayItemModel.fromJson(json);
      expect(back, item);
    });

    test('ChildDaySummary carries age + happy days', () {
      const summary = ChildDaySummary(
        childId: 'maya',
        nickname: 'Maya',
        avatarColour: 'lilac',
        pipStage: 3,
        done: 4,
        total: 6,
        coins: 120,
        ageYears: 9,
        happyDays: 4,
      );
      expect(summary.ageYears, 9);
      expect(summary.happyDays, 4);
    });
  });
}
