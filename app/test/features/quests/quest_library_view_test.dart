import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/quests/presentation/views/quest_library_view.dart';
import 'package:nestling/features/quests/presentation/widgets/quest_category_chips.dart';
import 'package:nestling/features/quests/presentation/widgets/quest_idea_meta.dart';
import 'package:nestling/features/quests/presentation/widgets/quest_idea_row.dart';
import 'package:nestling/features/quests/quests_routes.dart';

import '../../test_scope.dart';

/// `P10 .trow .mt` copy, character-for-character.
const _metaLines = <String>[
  '5 coins · Ages 4+ · Bedroom',
  '10 coins · Ages 5+ · Kitchen',
  '15 coins · Ages 8+ · Outdoors',
  '15 coins · Ages 7+ · Kitchen',
  '20 coins · Ages 9+ · Bedroom',
  '5 coins · Ages 4+ · Pets',
  '5 coins · Ages 5+ · School',
  '10 coins · Ages 5+ · Outdoors',
  '15 coins · Ages 7+ · Bedroom',
  '10 coins · Ages 5+ · School',
];

const _ideaIds = <String>[
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
];

Finder _ideaRow(String id) => find.byKey(ValueKey<String>('quest-idea-$id'));

void main() {
  group('P10 quest library view', () {
    testWidgets('renders the design chrome and the 10 idea rows', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      expect(currentPath(tester), QuestsRoutePaths.library);

      // `.ptitle` — Nunito 28/34 w900, 8 px below the status bar.
      // The tab bar also carries a "Quests" label, so scope to the view.
      final title = tester.widget<Text>(
        find.descendant(
          of: find.byType(QuestLibraryView),
          matching: find.text('Quests'),
        ),
      );
      expect(title.style!.fontFamily, 'Nunito');
      expect(title.style!.fontSize, 28);
      expect(title.style!.fontWeight, FontWeight.w900);

      // Segmented: count comes from the seeded stream, never hard-coded.
      expect(find.text('Active (12)'), findsOneWidget);
      expect(find.text('Ideas'), findsOneWidget);

      // Search.
      expect(find.text('Search ideas'), findsOneWidget);
      expect(find.bySemanticsLabel('Search quest ideas'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Category chips, in design order.
      for (final category in kQuestCategories) {
        expect(find.text(category), findsOneWidget, reason: category);
      }

      // Idea rows + `+ Add`. The list is lazy, so assert the on-screen rows
      // first and scroll for the rest.
      expect(find.byType(QuestAddButton), findsWidgets);
      for (var i = 0; i < 6; i++) {
        expect(_ideaRow(_ideaIds[i]), findsOneWidget, reason: _ideaIds[i]);
        expect(find.text(_metaLines[i]), findsOneWidget, reason: _ideaIds[i]);
      }
      // Semantics labels are asserted in quest_library_widget_test.dart: a
      // sliver child's `debugSemantics` is not populated in the app tree.
      await tester.dragUntilVisible(
        _ideaRow('idea-reading'),
        find.byType(ListView),
        const Offset(0, -240),
      );
      await tester.pumpAndSettle();
      expect(_ideaRow('idea-reading'), findsOneWidget);
      expect(find.text('10 coins · Ages 5+ · School'), findsOneWidget);
      expect(find.text('Read for 20 minutes'), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('cards keep the 20 px side gutters', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      final card = tester.getRect(_ideaRow('idea-bed'));
      expect(card.left, NestSpacing.padSide);
      expect(card.width, 390 - 2 * NestSpacing.padSide);
      expect(card.height, 68);

      await disposeApp(tester);
    });

    testWidgets(
      'the filter row is full-bleed but its pills sit on the gutter',
      (tester) async {
        await setUpTestScope();
        await pumpAppRoute(tester, QuestsRoutePaths.library);

        // `.chipscroll { margin: 0 -20px }` — the row itself spans the screen …
        final row = tester.getRect(find.byType(QuestCategoryChips));
        expect(row.left, 0);
        expect(row.width, 390);
        // … while the pills keep the 20 px edge padding.
        final all = tester.getRect(
          find.byKey(const ValueKey<String>('quest-filter-chip-All')),
        );
        expect(all.left, NestSpacing.padSide);
        expect(all.height, 44);

        await disposeApp(tester);
      },
    );

    testWidgets('`+ Add` pushes the editor with the idea id', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      await tester.tap(find.byType(QuestAddButton).first);
      await tester.pumpAndSettle();

      expect(pushedPath(tester), QuestsRoutePaths.editor);

      await disposeApp(tester);
    });

    testWidgets('the search field filters the idea list', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      final before = tester.widgetList(find.byType(QuestAddButton)).length;
      expect(before, greaterThan(0));

      await tester.enterText(find.byType(TextField), 'pet');
      await tester.pump();

      expect(find.byType(QuestAddButton), findsOneWidget);
      expect(find.text('Feed the pet'), findsOneWidget);
      expect(find.text('5 coins · Ages 4+ · Pets'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'zzzz');
      await tester.pump();
      expect(find.byType(QuestAddButton), findsNothing);
      expect(find.text('No ideas found'), findsOneWidget);
      expect(find.text('Try a different search or category.'), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('a category chip filters; Kindness has no templates', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      await tester.tap(find.text('Kitchen'));
      await tester.pump();

      expect(find.byType(QuestAddButton), findsNWidgets(2));
      expect(find.byType(QuestIdeaRow), findsNWidgets(2));
      expect(find.text('Lay the table'), findsOneWidget);
      expect(find.text('Empty the dishwasher'), findsOneWidget);
      expect(find.text('Make your bed'), findsNothing);

      await disposeApp(tester);
    });

    testWidgets('the Active tab lists the seeded quests and opens the editor', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      await tester.tap(find.text('Active (12)'));
      await tester.pumpAndSettle();

      // Active rows carry no `+ Add`.
      expect(find.byType(QuestAddButton), findsNothing);
      expect(find.byType(QuestIdeaRow), findsWidgets);
      expect(find.text('Active (12)'), findsOneWidget);

      await tester.tap(find.byType(QuestIdeaRow).first);
      await tester.pumpAndSettle();
      expect(pushedPath(tester), QuestsRoutePaths.editor);

      await disposeApp(tester);
    });

    testWidgets('dark mode keeps tinted icon tiles', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(
        tester,
        QuestsRoutePaths.library,
        theme: ThemeMode.dark,
      );

      final tokens = tester.element(_ideaRow('idea-bed')).nest;
      expect(tokens.isDark, isTrue);
      expect(find.text('5 coins · Ages 4+ · Bedroom'), findsOneWidget);

      final tile = tester
          .widgetList<Container>(
            find.descendant(
              of: _ideaRow('idea-bed'),
              matching: find.byType(Container),
            ),
          )
          .first;
      expect((tile.decoration! as BoxDecoration).color, tokens.peachTint);

      await disposeApp(tester);
    });

    testWidgets('no overflow at 1.3 text scale', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pump();

      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });
}
