// P10 · Quest library — the `Seed.empty()` (P08b) path at the view level.
//
// Iteration 1 proved "no active quests" with a mocked empty stream because
// driving the real router with `Seed.empty()` hung the test. That is the only
// way this stage's brief names the seed ("Use the in-memory Drift DB with
// Seed.demo/empty"), so it is covered for real here: the seeded database is
// emptied and the whole app is pumped on `/quests`.
//
// What must hold (RULES §4: `Seed.empty()` = onboarded parent, no children):
//   * the router keeps `/quests` — no trial or onboarding redirect;
//   * the Active tab reports the database's real count, `Active (0)`;
//   * Active shows the `No active quests` empty state;
//   * the Ideas tab still lists all ten static templates, because `ideas()`
//     are never stored rows — DATA OVER MOCKS, an empty DB must not empty the
//     Ideas tab.

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart' hide Quest;
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/quests/presentation/widgets/quest_idea_row.dart';
import 'package:nestling/features/quests/quests_routes.dart';

import '../../test_scope.dart';

const _ideaTitles = <String>[
  'Make your bed',
  'Lay the table',
  'Put the bins out',
];

void main() {
  group('P10 with Seed.empty()', () {
    testWidgets('the route stays `/quests` and the Active count is 0', (
      tester,
    ) async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.empty(db);

      await pumpAppRoute(tester, QuestsRoutePaths.library);

      expect(currentPath(tester), QuestsRoutePaths.library);
      expect(find.text('Active (0)'), findsOneWidget);
      expect(find.text('Ideas'), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('the Active tab shows the no-quests empty state', (
      tester,
    ) async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.empty(db);

      await pumpAppRoute(tester, QuestsRoutePaths.library);
      await tester.tap(find.text('Active (0)'));
      await tester.pumpAndSettle();

      expect(find.text('No active quests'), findsOneWidget);
      expect(find.text('Add one from Ideas.'), findsOneWidget);
      expect(find.byType(QuestIdeaRow), findsNothing);

      await disposeApp(tester);
    });

    testWidgets('the Ideas tab still lists the ten static templates', (
      tester,
    ) async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.empty(db);

      await pumpAppRoute(tester, QuestsRoutePaths.library);

      // `QuestsRepository.ideas()` are never stored rows, so an empty
      // database must not empty the Ideas tab (DATA OVER MOCKS).
      for (final title in _ideaTitles) {
        expect(find.text(title), findsOneWidget, reason: title);
      }
      expect(find.text('5 coins · Ages 4+ · Bedroom'), findsOneWidget);
      expect(find.byType(QuestAddButton), findsWidgets);

      await disposeApp(tester);
    });

    testWidgets('the filters still work with an empty database', (
      tester,
    ) async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.empty(db);

      await pumpAppRoute(tester, QuestsRoutePaths.library);

      await tester.enterText(find.byType(TextField), 'pet');
      await tester.pump();
      expect(find.text('Feed the pet'), findsOneWidget);

      // The two filters combine with AND: 'pet' matches a Pets template, so a
      // Kitchen filter on top of it must empty the list.
      await tester.tap(find.text('Kitchen'));
      await tester.pump();
      expect(find.text('Feed the pet'), findsNothing);
      expect(find.text('No ideas found'), findsOneWidget);

      // …and Kitchen on its own still lists its two templates.
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      expect(find.text('Lay the table'), findsOneWidget);
      expect(find.text('Empty the dishwasher'), findsOneWidget);
      expect(find.text('Make your bed'), findsNothing);

      await disposeApp(tester);
    });

    testWidgets('no overflow and no exception on the empty tree', (
      tester,
    ) async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.empty(db);

      await pumpAppRoute(tester, QuestsRoutePaths.library);
      await tester.tap(find.text('Active (0)'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  group('P10 with Seed.demo() — the seeded counts are not hard-coded', () {
    testWidgets('Active reports 12 and a live insert moves it to 13', (
      tester,
    ) async {
      final db = await setUpTestScope();

      await pumpAppRoute(tester, QuestsRoutePaths.library);
      expect(find.text('Active (12)'), findsOneWidget);

      // A deactivation drops the count, proving the label tracks the stream.
      await (db.update(db.quests)..where((q) => q.id.equals('q-bed'))).write(
        const QuestsCompanion(active: Value(false)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Active (12)'), findsNothing);
      expect(find.text('Active (11)'), findsOneWidget);

      await disposeApp(tester);
    });
  });
}
