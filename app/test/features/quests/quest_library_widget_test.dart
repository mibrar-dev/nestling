import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/quests/presentation/widgets/quest_category_chips.dart';
import 'package:nestling/features/quests/presentation/widgets/quest_filter_chip.dart';
import 'package:nestling/features/quests/presentation/widgets/quest_idea_meta.dart';
import 'package:nestling/features/quests/presentation/widgets/quest_idea_row.dart';

/// Design copy, character-for-character (`P10 .trow .mt`, middot U+00B7).
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

Widget _host(Widget child, {ThemeMode theme = ThemeMode.light}) {
  return MaterialApp(
    theme: NestTheme.light(),
    darkTheme: NestTheme.dark(),
    themeMode: theme,
    home: Scaffold(
      body: Align(alignment: Alignment.topLeft, child: child),
    ),
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  ThemeMode theme = ThemeMode.light,
  double textScale = 1,
}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_host(child, theme: theme));
  await tester.pump();
}

/// First [Container] inside [finder] — the icon tile / chip pill box.
Container _firstBox(WidgetTester tester, Finder finder) => tester
    .widgetList<Container>(
      find.descendant(of: finder, matching: find.byType(Container)),
    )
    .first;

void main() {
  group('QuestFilterChip', () {
    testWidgets('pill background is 44 high and at least 44 wide', (
      tester,
    ) async {
      await _pump(
        tester,
        QuestFilterChip(label: 'All', selected: true, onTap: () {}),
      );

      final size = tester.getSize(find.byType(QuestFilterChip));
      expect(size.height, 44);
      expect(size.width, greaterThanOrEqualTo(44));
    });

    testWidgets('selected pill paints leaf-tint fill + 1.5 px leaf border', (
      tester,
    ) async {
      await _pump(
        tester,
        QuestFilterChip(label: 'All', selected: true, onTap: () {}),
      );

      final finder = find.byType(QuestFilterChip);
      final decoration = _firstBox(tester, finder).decoration! as BoxDecoration;
      final tokens = tester.element(finder).nest;
      expect(decoration.color, tokens.leafTint);
      expect(decoration.borderRadius, NestRadii.allPill);
      expect((decoration.border! as Border).top.color, tokens.leaf);
      expect((decoration.border! as Border).top.width, 1.5);
      // `.chip { padding: 0 14px }`
      expect(_firstBox(tester, finder).padding, isNotNull);
    });

    testWidgets('unselected pill paints surface-2 with a transparent border', (
      tester,
    ) async {
      await _pump(
        tester,
        QuestFilterChip(label: 'Bedroom', selected: false, onTap: () {}),
      );

      final finder = find.byType(QuestFilterChip);
      final decoration = _firstBox(tester, finder).decoration! as BoxDecoration;
      final tokens = tester.element(finder).nest;
      expect(decoration.color, tokens.surface2);
      expect((decoration.border! as Border).top.color, Colors.transparent);
      expect((decoration.border! as Border).top.width, 1.5);
    });

    testWidgets('a chip narrower than 44 wide still taps 44 wide', (
      tester,
    ) async {
      var taps = 0;
      await _pump(
        tester,
        QuestFilterChip(label: 'All', selected: true, onTap: () => taps++),
      );
      expect(
        tester.getSize(find.byType(QuestFilterChip)).width,
        greaterThanOrEqualTo(44),
      );
      await tester.tap(find.byType(QuestFilterChip));
      await tester.pump();
      expect(taps, 1);
    });
  });

  group('QuestCategoryChips', () {
    testWidgets('renders all seven chips in design order', (tester) async {
      await _pump(
        tester,
        SizedBox(
          width: 390,
          child: QuestCategoryChips(
            categories: kQuestCategories,
            selected: 'All',
            onSelected: (_) {},
          ),
        ),
      );

      expect(kQuestCategories, <String>[
        'All',
        'Bedroom',
        'Kitchen',
        'Outdoors',
        'Pets',
        'School',
        'Kindness',
      ]);
      for (final category in kQuestCategories) {
        expect(find.text(category), findsOneWidget, reason: category);
      }
    });

    testWidgets('row bleeds past the gutter and spaces chips 8 apart', (
      tester,
    ) async {
      await _pump(
        tester,
        SizedBox(
          width: 390,
          child: QuestCategoryChips(
            categories: kQuestCategories,
            selected: 'All',
            onSelected: (_) {},
          ),
        ),
      );

      // The row carries its own `padding: 0 20px`, so the first pill starts
      // exactly on the 20 px gutter even though the row is full-bleed.
      final all = tester.getRect(
        find.byKey(const ValueKey<String>('quest-filter-chip-All')),
      );
      expect(all.left, 20);

      final bedroom = tester.getRect(
        find.byKey(const ValueKey<String>('quest-filter-chip-Bedroom')),
      );
      expect(bedroom.left - all.right, 8);
    });

    testWidgets('every chip keeps a 44 high tap target', (tester) async {
      await _pump(
        tester,
        SizedBox(
          width: 390,
          child: QuestCategoryChips(
            categories: kQuestCategories,
            selected: 'All',
            onSelected: (_) {},
          ),
        ),
      );

      for (final category in kQuestCategories) {
        final rect = tester.getRect(
          find.byKey(ValueKey<String>('quest-filter-chip-$category')),
        );
        expect(rect.height, 44, reason: category);
        expect(rect.width, greaterThanOrEqualTo(44), reason: category);
      }
    });

    testWidgets('tapping a chip reports its category', (tester) async {
      String? tapped;
      await _pump(
        tester,
        SizedBox(
          width: 390,
          child: QuestCategoryChips(
            categories: kQuestCategories,
            selected: 'All',
            onSelected: (value) => tapped = value,
          ),
        ),
      );

      // `School` is off-screen in a 390 px viewport (the row scrolls), so tap
      // a pill that is actually on screen.
      await tester.tap(find.text('Kitchen'));
      await tester.pump();
      expect(tapped, 'Kitchen');
    });
  });

  group('QuestIdeaRow', () {
    Widget row({VoidCallback? onAdd, VoidCallback? onTap}) {
      return QuestIdeaRow(
        title: 'Make your bed',
        meta: _metaLines.first,
        iconAsset: NestIcons.bed,
        tint: NestTileTint.peach,
        addSemanticLabel: 'Add Make your bed',
        onAdd: onAdd,
        onTap: onTap,
      );
    }

    testWidgets('card is 68 high, r-m, sh-1, 12 padding', (tester) async {
      await _pump(tester, row(onAdd: () {}));

      final finder = find.byType(QuestIdeaRow);
      expect(tester.getSize(finder).height, 68);

      final decoration =
          tester
                  .widget<DecoratedBox>(find.byType(DecoratedBox).first)
                  .decoration
              as BoxDecoration;
      final tokens = tester.element(finder).nest;
      expect(decoration.color, tokens.surface);
      expect(decoration.borderRadius, NestRadii.allM);
      expect(decoration.boxShadow, tokens.cardShadow);
      // `.trow { padding: 12px; gap: 12px }`
      final inner = tester.widget<Padding>(
        find
            .descendant(
              of: find.byType(QuestIdeaRow),
              matching: find.byType(Padding),
            )
            .first,
      );
      expect(inner.padding, const EdgeInsets.all(12));
      expect(
        find.descendant(
          of: find.byType(QuestIdeaRow),
          matching: find.byWidgetPredicate(
            (w) => w is SizedBox && w.width == NestSpacing.s3,
          ),
        ),
        findsNWidgets(2),
        reason: 'two 12 px gaps: tile→text and text→`+ Add`',
      );
    });

    testWidgets('icon tile is 40x40, r-m, tinted', (tester) async {
      await _pump(tester, row(onAdd: () {}));

      final tile = _firstBox(tester, find.byType(QuestIdeaRow));
      expect(tile.constraints!.maxHeight, 40);
      expect(tile.constraints!.maxWidth, 40);
      final decoration = tile.decoration! as BoxDecoration;
      final tokens = tester.element(find.byType(QuestIdeaRow)).nest;
      expect(decoration.color, tokens.peachTint);
      expect(decoration.borderRadius, NestRadii.allM);
    });

    testWidgets('`+ Add` is 44 high with a leaf border and its label', (
      tester,
    ) async {
      var taps = 0;
      await _pump(tester, row(onAdd: () => taps++));

      expect(tester.getSize(find.byType(QuestAddButton)).height, 44);
      expect(find.text('+ Add'), findsOneWidget);
      expect(find.bySemanticsLabel('Add Make your bed'), findsOneWidget);

      final button = _firstBox(tester, find.byType(QuestAddButton));
      final decoration = button.decoration! as BoxDecoration;
      final tokens = tester.element(find.byType(QuestAddButton)).nest;
      expect(decoration.color, tokens.leafTint);
      expect((decoration.border! as Border).top.color, tokens.leaf);
      expect((decoration.border! as Border).top.width, 1.5);
      expect(decoration.borderRadius, NestRadii.allPill);

      await tester.tap(find.byType(QuestAddButton));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('copy is exact: title Inter 16 w700/22, meta Inter 13/ink-2', (
      tester,
    ) async {
      await _pump(tester, row(onAdd: () {}));

      final title = tester.widget<Text>(find.text('Make your bed'));
      final meta = tester.widget<Text>(find.text(_metaLines.first));
      final tokens = tester.element(find.byType(QuestIdeaRow)).nest;

      expect(title.style!.fontFamily, 'Inter');
      expect(title.style!.fontSize, 16);
      expect(title.style!.fontWeight, FontWeight.w700);
      expect(title.style!.height, 22 / 16);
      expect(title.maxLines, 1);

      expect(meta.style!.fontFamily, 'Inter');
      expect(meta.style!.fontSize, 13);
      expect(meta.style!.height, 18 / 13);
      expect(meta.style!.color, tokens.ink2);
    });

    testWidgets('no overflow at 1.3 text scale', (tester) async {
      await _pump(tester, row(onAdd: () {}), textScale: 1.3);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dark mode keeps the tinted tile (never grey)', (tester) async {
      await _pump(tester, row(onAdd: () {}), theme: ThemeMode.dark);

      final decoration =
          _firstBox(tester, find.byType(QuestIdeaRow)).decoration!
              as BoxDecoration;
      final tokens = tester.element(find.byType(QuestIdeaRow)).nest;
      expect(tokens.isDark, isTrue);
      expect(decoration.color, tokens.peachTint);
      expect(decoration.color, isNot(tokens.surface2));
      expect(decoration.color, isNot(tokens.surface));
    });

    testWidgets('without `+ Add` the whole row is tappable and 64 high', (
      tester,
    ) async {
      var taps = 0;
      await _pump(tester, row(onTap: () => taps++));

      expect(find.byType(QuestAddButton), findsNothing);
      expect(tester.getSize(find.byType(QuestIdeaRow)).height, 64);

      await tester.tap(find.byType(QuestIdeaRow));
      await tester.pump();
      expect(taps, 1);
    });
  });

  group('QuestIdeaMeta', () {
    test('meta lines match the design copy character-for-character', () {
      const ids = <String>[
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
      const coins = <int>[5, 10, 15, 15, 20, 5, 5, 10, 15, 10];
      for (var i = 0; i < ids.length; i++) {
        final meta = questIdeaMetaFor(ids[i]);
        expect(meta, isNotNull, reason: ids[i]);
        expect(meta!.metaFor(coins[i]), _metaLines[i], reason: ids[i]);
      }
      // Categories must be a subset of the chip row.
      for (final id in ids) {
        expect(
          kQuestCategories,
          contains(questIdeaMetaFor(id)!.category),
          reason: id,
        );
      }
    });
  });
}
