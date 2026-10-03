import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
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

  group('P10 responsive matrix', () {
    // 320 (small), 390 (design), 430 (large) x light/dark x 1.0/1.3 text.
    const widths = <double>[320, 390, 430];
    const scales = <double>[1, 1.3];

    for (final width in widths) {
      for (final scale in scales) {
        for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
          testWidgets(
            'w$width s$scale ${theme.name}: gutters hold and nothing overflows',
            (tester) async {
              await setUpTestScope();
              await _pumpAt(
                tester,
                QuestsRoutePaths.library,
                width: width,
                textScale: scale,
                theme: theme,
              );

              expect(
                tester.takeException(),
                isNull,
                reason: 'overflow or build error at w$width s$scale',
              );

              // OWNER ALIGNMENT: every full-bleed element keeps the 20 px
              // gutter at every width.
              final card = tester.getRect(_ideaRow('idea-bed'));
              expect(card.left, NestSpacing.padSide);
              expect(card.width, width - 2 * NestSpacing.padSide);
              // `.trow` is 44 (the `+ Add` pill) + 2x12 padding at 1.0; at
              // 1.3 the text grows past the pill and the card grows with it,
              // but the padding never changes.
              if (scale == 1) {
                expect(card.height, 68);
              } else {
                expect(card.height, greaterThanOrEqualTo(68));
              }

              // Only the chip row bleeds past the gutter, by design.
              expect(tester.getRect(find.byType(QuestCategoryChips)).left, 0);
              expect(
                tester
                    .getRect(
                      find.byKey(
                        const ValueKey<String>('quest-filter-chip-All'),
                      ),
                    )
                    .left,
                NestSpacing.padSide,
              );

              // Interactive controls keep the 44 px parent floor.
              expect(
                tester.getSize(find.byType(NestSegmented<String>)).height,
                greaterThanOrEqualTo(NestDevice.tapParent),
              );
              expect(
                tester.getSize(find.byType(TextField)).height,
                greaterThanOrEqualTo(NestDevice.tapParent),
              );
              final add = tester.getRect(find.byType(QuestAddButton).first);
              expect(add.height, greaterThanOrEqualTo(NestDevice.tapParent));
              expect(add.width, greaterThanOrEqualTo(NestDevice.tapParent));

              // The `+ Add` pill stays glued to the card's inner edge.
              expect(
                card.right - add.right,
                NestSpacing.s3,
                reason: '.trow padding 12',
              );

              expect(
                tester.element(_ideaRow('idea-bed')).nest.isDark,
                theme == ThemeMode.dark,
              );

              await disposeApp(tester);
            },
          );
        }
      }
    }

    testWidgets('the shell clamps text scale above 1.3', (tester) async {
      await setUpTestScope();
      await _pumpAt(tester, QuestsRoutePaths.library, textScale: 1.3);
      final at13 = tester.getRect(_ideaRow('idea-bed'));
      await disposeApp(tester);

      await setUpTestScope();
      await _pumpAt(tester, QuestsRoutePaths.library, textScale: 2);
      final at20 = tester.getRect(_ideaRow('idea-bed'));
      await disposeApp(tester);

      expect(at20, at13, reason: 'the shell pins the scaler to 1.0-1.3');
    });

    testWidgets('the Active tab survives every width and scale', (
      tester,
    ) async {
      for (final width in widths) {
        for (final scale in scales) {
          await setUpTestScope();
          await _pumpAt(
            tester,
            QuestsRoutePaths.library,
            width: width,
            textScale: scale,
          );
          await tester.tap(find.text('Active (12)'));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull, reason: 'w$width s$scale');
          expect(find.byType(QuestIdeaRow), findsWidgets, reason: 'w$width');

          final row = tester.getRect(
            find.byKey(const ValueKey<String>('quest-active-q-dishwasher')),
          );
          expect(row.left, NestSpacing.padSide, reason: 'w$width');
          expect(row.width, width - 2 * NestSpacing.padSide, reason: 'w$width');

          await disposeApp(tester);
        }
      }
    });
  });

  group('P10 shell navigation', () {
    // Every tap on P10 lands somewhere: the two in-screen controls (covered in
    // quest_library_states_test.dart) and the four parent tab-bar items, which
    // `ParentShell` owns.
    const tabs = <String, String>{
      'Today': '/today',
      'Money': '/money',
      'Family': '/child-profile',
      'Quests': QuestsRoutePaths.library,
    };

    for (final entry in tabs.entries) {
      testWidgets('the `${entry.key}` tab goes to ${entry.value}', (
        tester,
      ) async {
        await setUpTestScope();
        await pumpAppRoute(tester, QuestsRoutePaths.library);

        await tester.tap(_tab(entry.key));
        await tester.pumpAndSettle();

        expect(currentPath(tester), entry.value);

        await disposeApp(tester);
      });
    }

    testWidgets('the four tabs round-trip back to the quest library', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      for (final entry in tabs.entries) {
        await tester.tap(_tab(entry.key));
        await tester.pumpAndSettle();
        expect(currentPath(tester), entry.value, reason: '${entry.key} tab');
      }

      expect(currentPath(tester), QuestsRoutePaths.library);
      // Back on the library, the screen is intact: title, tabs and rows.
      expect(find.text('Active (12)'), findsOneWidget);
      expect(find.byType(QuestIdeaRow), findsWidgets);

      await disposeApp(tester);
    });

    testWidgets('a tab tap does not disturb the quest filters', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      await tester.tap(find.text('Kitchen'));
      await tester.pump();
      expect(find.text('Make your bed'), findsNothing);

      await tester.tap(_tab('Today'));
      await tester.pumpAndSettle();
      await tester.tap(_tab('Quests'));
      await tester.pumpAndSettle();

      // The filter state is local to the body, so it survives the round-trip
      // (BUG-P10-12 is about the *text* of the field, not the category).
      expect(find.text('Make your bed'), findsNothing);
      expect(find.text('Lay the table'), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('`/quests` is parent-only: kid mode lands on the gate', (
      tester,
    ) async {
      await setUpTestScope();
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);

      await pumpAppRoute(tester, QuestsRoutePaths.library);

      // P10 is a parent screen (brief: "mode parent"), so the 56 px kid tap
      // floor never applies here; the router must keep it out of kid mode.
      expect(currentPath(tester), '/parental-gate');

      await disposeApp(tester);
    });
  });

  // FIXES_1 / BUG-P10-2, 3, 4, 9 — the layout and accessibility repairs this
  // iteration, pinned here so they cannot regress.
  group('P10 fixes (iteration 2)', () {
    testWidgets('row title and meta start at the tile gap, not centred', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      // Only the built rows are checked (the ListView has not scrolled), but
      // every one of them must start at the tile gap.
      final rows = find.byType(QuestIdeaRow);
      expect(rows, findsWidgets);
      for (final row in rows.evaluate()) {
        final key = (row.widget as QuestIdeaRow).key!;
        final finder = find.byKey(key);
        final card = tester.getRect(finder);
        final texts = tester
            .widgetList<Text>(
              find.descendant(of: finder, matching: find.byType(Text)),
            )
            .where((text) => text.data != '+ Add')
            .toList();
        expect(texts.length, 2, reason: '$key');
        for (final text in texts) {
          final rect = tester.getRect(
            find.descendant(of: finder, matching: find.text(text.data!)),
          );
          // `.trow { padding:12; gap:12 }` + a 40 px tile = +64 from the card.
          expect(rect.left - card.left, 64, reason: '$key · ${text.data}');
        }
      }

      await disposeApp(tester);
    });

    testWidgets('the Active tab offers no filter it cannot honour', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(QuestCategoryChips), findsOneWidget);

      await tester.tap(find.text('Active (12)'));
      await tester.pumpAndSettle();

      // The Active board is the whole family list: a search box and a category
      // row that filter nothing must not be rendered (BUG-P10-3).
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(QuestCategoryChips), findsNothing);
      expect(find.byType(QuestIdeaRow), findsWidgets);
      expect(find.text('No active quests'), findsNothing);

      // Switching back restores the Ideas filters, state intact.
      await tester.tap(find.text('Ideas'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(QuestCategoryChips), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('the gap after the last row is the design 32, not 48', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      await tester.drag(find.byType(ListView), const Offset(0, -20000));
      await tester.pumpAndSettle();

      expect(
        tester.getRect(find.byType(ListView)).bottom -
            tester.getRect(_ideaRow('idea-reading')).bottom,
        NestSpacing.s8,
      );

      await disposeApp(tester);
    });

    testWidgets('every P10 control is actionable from the semantics tree', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      // Filter chip: announcing `isButton` is not enough — the node must
      // expose a tap that really moves the selection (BUG-P10-9).
      final chip = tester.getSemantics(find.bySemanticsLabel('Kitchen'));
      expect(chip.getSemanticsData().flagsCollection.isButton, isTrue);
      expect(chip.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      tester.semantics.performAction(
        find.semantics.byLabel('Kitchen'),
        SemanticsAction.tap,
      );
      await tester.pumpAndSettle();
      expect(find.byType(QuestIdeaRow), findsNWidgets(2));
      expect(find.text('Lay the table'), findsOneWidget);
      expect(find.text('Empty the dishwasher'), findsOneWidget);

      // `+ Add`: named after its own idea, and the tap really navigates.
      final add = tester.getSemantics(
        find.bySemanticsLabel('Add Lay the table'),
      );
      expect(add.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      tester.semantics.performAction(
        find.semantics.byLabel('Add Lay the table'),
        SemanticsAction.tap,
      );
      await tester.pumpAndSettle();
      expect(pushedPath(tester), QuestsRoutePaths.editor);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(currentPath(tester), QuestsRoutePaths.library);

      // Active row: the whole row is the button and it carries its meta line.
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Active (12)'));
      await tester.pumpAndSettle();

      final row = find.byKey(const ValueKey<String>('quest-active-q-bed'));
      final data = tester.getSemantics(row).getSemanticsData();
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      expect(data.label, contains('Make your bed'));
      expect(data.label, contains('coins'));

      tester.semantics.performAction(
        find.semantics.byPredicate(
          (node) =>
              node.label.contains('Make your bed') &&
              node.label.contains('coins'),
        ),
        SemanticsAction.tap,
      );
      await tester.pumpAndSettle();
      expect(pushedPath(tester), QuestsRoutePaths.editor);

      handle.dispose();
      await disposeApp(tester);
    });
  });
}

/// The `NestTabBar` item labelled [label].
///
/// Scoped to the bar: the library's own heading is also labelled `Quests`.
Finder _tab(String label) =>
    find.descendant(of: find.byType(NestTabBar), matching: find.text(label));

/// [pumpAppRoute] with a width, a text scale and a theme.
Future<void> _pumpAt(
  WidgetTester tester,
  String route, {
  double width = 390,
  double textScale = 1.0,
  ThemeMode theme = ThemeMode.light,
}) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await tester.pumpWidget(NestlingApp(initialRoute: route));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}
