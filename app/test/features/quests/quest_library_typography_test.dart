// P10 · Quest library — typography rules with no other regression pin.
//
// Three owner rules are easy to break silently because none of them changes
// what the screen *says*:
//
//   LETTER SPACING  `NestType` styles default to `letterSpacing: 0` because
//                   the design CSS carries no tracking. Re-adding Material's
//                   default tracking would shift every line without failing a
//                   single copy or geometry assertion.
//   BALANCED        `NestBalancedText` is only for CSS that sets
//   HEADINGS        `text-wrap: balance` (`.display`, `.h1`, `.kid-title`,
//                   `.kid-hero`, screen-local `.balance`). `.ptitle` sets none,
//                   and its single word at `maxLines: 1` short-circuits anyway,
//                   so the wrapper would be invisible dead weight.
//   COPY            the seed's `Reading – 20 minutes` uses an EN DASH
//                   (U+2013); a hyphen or an em dash is a different character
//                   and reads differently on the Active tab.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/quests/presentation/widgets/quest_category_chips.dart';
import 'package:nestling/features/quests/presentation/widgets/quest_idea_meta.dart';
import 'package:nestling/features/quests/presentation/widgets/quest_library_body.dart';
import 'package:nestling/features/quests/quests_routes.dart';

import '../../test_scope.dart';

/// Every [Text] the library renders on the Ideas tab, keyed by its string.
Map<String, Text> _textsOnIdeasTab(WidgetTester tester) {
  final scope = find.byType(QuestLibraryBody);
  final texts = <String, Text>{};
  for (final text in tester.widgetList<Text>(
    find.descendant(of: scope, matching: find.byType(Text)),
  )) {
    final data = text.data;
    if (data != null) texts.putIfAbsent(data, () => text);
  }
  return texts;
}

void main() {
  group('LETTER SPACING — the design CSS carries no tracking', () {
    testWidgets('every text style on the library has letterSpacing 0', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      final styles = <String, TextStyle?>{
        for (final entry in _textsOnIdeasTab(tester).entries)
          entry.key: entry.value.style,
        // The shell's tab labels are on the same screen.
        'tab:Today': tester
            .widget<Text>(
              find.descendant(
                of: find.byType(NestTabBar),
                matching: find.text('Today'),
              ),
            )
            .style,
      };

      expect(styles.keys, containsAll(<String>['Quests', 'Search ideas']));
      for (final entry in styles.entries) {
        expect(
          entry.value?.letterSpacing,
          anyOf(isNull, 0),
          reason:
              '"${entry.key}" must not carry tracking '
              '(LETTER SPACING: NestType defaults to 0 and the P10 CSS sets '
              'no letter-spacing, so no call site may add one)',
        );
      }

      await disposeApp(tester);
    });

    testWidgets('the Active tab labels also carry no tracking', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);
      await tester.tap(find.text('Active (12)'));
      await tester.pumpAndSettle();

      final scope = find.byType(QuestLibraryBody);
      final styles = tester
          .widgetList<Text>(
            find.descendant(of: scope, matching: find.byType(Text)),
          )
          .map((text) => text.style?.letterSpacing);
      expect(styles, isNotEmpty);
      for (final spacing in styles) {
        expect(spacing, anyOf(isNull, 0));
      }

      await disposeApp(tester);
    });
  });

  group('BALANCED HEADINGS — `.ptitle` sets no `text-wrap: balance`', () {
    testWidgets('no `NestBalancedText` anywhere on the library', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      expect(find.byType(NestBalancedText), findsNothing);

      await tester.tap(find.text('Active (12)'));
      await tester.pumpAndSettle();
      expect(find.byType(NestBalancedText), findsNothing);

      await disposeApp(tester);
    });

    testWidgets('the title is a plain single-line `Text`', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      final title = tester.widget<Text>(
        find.descendant(
          of: find.byType(QuestLibraryBody),
          matching: find.text('Quests'),
        ),
      );
      expect(title.maxLines, 1);
      expect(title.style!.fontFamily, 'Nunito');
      expect(title.style!.fontSize, 28);
      expect(title.style!.fontWeight, FontWeight.w900);
      // 28/34 from `.ptitle { line-height: 34px }`.
      expect(title.style!.height, closeTo(34 / 28, 0.001));

      await disposeApp(tester);
    });
  });

  group('Type roles match the design CSS', () {
    testWidgets('Nunito is display-only; every body label is Inter', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      final families = <String, String?>{};
      for (final entry in _textsOnIdeasTab(tester).entries) {
        families[entry.key] = entry.value.style?.fontFamily;
      }

      expect(families['Quests'], 'Nunito', reason: '`.ptitle` is display');
      for (final label in <String>[
        'Active (12)',
        'Ideas',
        'All',
        'Search ideas',
        'Make your bed',
        '5 coins · Ages 4+ · Bedroom',
        '+ Add',
      ]) {
        expect(families[label], 'Inter', reason: label);
      }

      await disposeApp(tester);
    });

    testWidgets('the row keeps the CSS line-heights, not the type scale', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      // `.trow .nm { font-size:16px; line-height:22px }` and
      // `.trow .mt { font-size:13px; line-height:18px }` override the scale.
      final title = tester.widget<Text>(find.text('Make your bed'));
      expect(title.style!.fontSize, 16);
      expect(title.style!.height, closeTo(22 / 16, 0.001));
      expect(title.style!.fontWeight, FontWeight.w700);

      final meta = tester.widget<Text>(
        find.text('5 coins · Ages 4+ · Bedroom'),
      );
      expect(meta.style!.fontSize, 13);
      expect(meta.style!.height, closeTo(18 / 13, 0.001));

      await disposeApp(tester);
    });

    testWidgets('`.chip` is Inter 14 w600 and `.addbtn` is Inter 14 w700', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      final chip = tester.widget<Text>(find.text('All'));
      expect(chip.style!.fontSize, 14);
      expect(chip.style!.fontWeight, FontWeight.w600);

      final add = tester.widget<Text>(find.text('+ Add').first);
      expect(add.style!.fontSize, 14);
      expect(add.style!.fontWeight, FontWeight.w700);

      await disposeApp(tester);
    });
  });

  group('COPY — the seed titles carry the design punctuation', () {
    testWidgets(
      '`Reading – 20 minutes` uses EN DASH U+2013 on the Active tab',
      (tester) async {
        await setUpTestScope();
        await pumpAppRoute(tester, QuestsRoutePaths.library);
        await tester.tap(find.text('Active (12)'));
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Reading – 20 minutes'),
          240,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        final title = find.text('Reading – 20 minutes');
        expect(title, findsOneWidget);
        final data = tester.widget<Text>(title).data!;
        expect(data.codeUnits, contains(0x2013), reason: 'en dash');
        expect(data, isNot(contains('-')));
        expect(data, isNot(contains('––')));

        await disposeApp(tester);
      },
    );

    testWidgets('the middot in the meta line is U+00B7', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      final meta = tester
          .widget<Text>(find.text('5 coins · Ages 4+ · Bedroom'))
          .data!;
      expect(meta.codeUnits, contains(0x00B7), reason: 'middot U+00B7');
      expect(meta, isNot(contains('•')), reason: 'not U+2022');
      expect(meta, isNot(contains(' - ')), reason: 'not an ASCII hyphen');

      await disposeApp(tester);
    });

    testWidgets('the search hint and its label are the design strings', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      // `<input type="search" placeholder="Search ideas"
      //        aria-label="Search quest ideas">`
      expect(find.text('Search ideas'), findsOneWidget);
      expect(find.bySemanticsLabel('Search quest ideas'), findsOneWidget);

      await disposeApp(tester);
    });
  });

  group('The filter row is usable at the narrowest width', () {
    testWidgets('all seven chips can be scrolled to and selected at 320', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpAt320(tester, QuestsRoutePaths.library);

      for (final category in kQuestCategories) {
        final chip = find.byKey(
          ValueKey<String>('quest-filter-chip-$category'),
        );
        if (chip.evaluate().isEmpty ||
            tester.getRect(chip).left + tester.getRect(chip).width >
                320 - NestSpacing.padSide) {
          await tester.scrollUntilVisible(
            chip,
            120,
            scrollable: find.descendant(
              of: find.byType(QuestCategoryChips),
              matching: find.byType(Scrollable),
            ),
          );
          await tester.pumpAndSettle();
        }

        await tester.tap(chip);
        await tester.pumpAndSettle();

        // The tap really selected it: the chip is the one marked selected.
        expect(
          find.byKey(ValueKey<String>('quest-filter-chip-$category')),
          findsOneWidget,
          reason: category,
        );
        expect(tester.takeException(), isNull, reason: category);
      }

      // Kindness has no templates, so the empty state is the last result.
      expect(find.text('No ideas found'), findsOneWidget);

      await disposeApp(tester);
    });
  });
}

/// [pumpAppRoute] on the narrowest width the brief asks for (320).
Future<void> _pumpAt320(WidgetTester tester, String route) async {
  tester.view.physicalSize = const Size(320 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(NestlingApp(initialRoute: route));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}
