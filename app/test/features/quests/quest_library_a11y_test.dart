// P10 · Quest library — semantics / accessibility contract.
//
// The interactive surface of the quest library is: the Active/Ideas
// segmented control, the seven category filter chips, the `+ Add` button on
// every idea row and (on the Active tab) the whole row. The earlier suites
// only checked that the *labels* exist, which is not enough — a control that
// announces itself as a button but offers no `tap` action is unreachable for
// anyone using VoiceOver or TalkBack, and a label merged with its own inner
// text is announced twice.
//
// Parent mode, so the tap-target floor is 44 (`NestDevice.tapParent`); the
// 56 px kid floor does not apply to this screen.
//
// Only P10-owned controls are asserted here: the shell's `NestTabBar` is
// shared chrome and belongs to the app-wide suite.

import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/quests/presentation/widgets/quest_filter_chip.dart';
import 'package:nestling/features/quests/presentation/widgets/quest_idea_meta.dart';
import 'package:nestling/features/quests/presentation/widgets/quest_idea_row.dart';
import 'package:nestling/features/quests/quests_routes.dart';

import '../../test_scope.dart';

Finder _chip(String category) =>
    find.byKey(ValueKey<String>('quest-filter-chip-$category'));

Finder _ideaRow(String id) => find.byKey(ValueKey<String>('quest-idea-$id'));

/// The chips that are on screen at 390 px (`Pets`, `School` and `Kindness`
/// sit off-screen in the scrolling row, so their semantics are not built).
const List<String> _visibleChips = <String>[
  'All',
  'Bedroom',
  'Kitchen',
  'Outdoors',
];

SemanticsData _data(WidgetTester tester, Finder finder) =>
    tester.getSemantics(finder.first).getSemanticsData();

void main() {
  group('P10 segmented control', () {
    testWidgets('each option is one labelled, tappable button', (tester) async {
      final handle = tester.ensureSemantics();
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      for (final label in <String>['Active (12)', 'Ideas']) {
        expect(
          find.bySemanticsLabel(label),
          findsOneWidget,
          reason: '$label must be one addressable node',
        );
        final data = _data(tester, find.bySemanticsLabel(label));
        // Exactly the option label: `NestSegmented` must not merge the inner
        // Text into the button's own label (that announces it twice).
        expect(data.label, label, reason: label);
        expect(data.flagsCollection.isButton, isTrue, reason: label);
        expect(data.hasAction(SemanticsAction.tap), isTrue, reason: label);
      }

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('Ideas starts selected and Active does not', (tester) async {
      final handle = tester.ensureSemantics();
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      expect(
        _data(
          tester,
          find.bySemanticsLabel('Ideas'),
        ).flagsCollection.isSelected,
        Tristate.isTrue,
      );
      expect(
        _data(
          tester,
          find.bySemanticsLabel('Active (12)'),
        ).flagsCollection.isSelected,
        Tristate.isFalse,
      );

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('the control is grouped under its own name', (tester) async {
      final handle = tester.ensureSemantics();
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      expect(find.bySemanticsLabel('Quest lists'), findsOneWidget);

      handle.dispose();
      await disposeApp(tester);
    });
  });

  group('P10 category filter chips', () {
    testWidgets('every visible chip is a tappable button with its own label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      for (final category in _visibleChips) {
        expect(
          find.bySemanticsLabel(category),
          findsOneWidget,
          reason: category,
        );
        final data = _data(tester, find.bySemanticsLabel(category));
        expect(data.label, category, reason: category);
        expect(data.flagsCollection.isButton, isTrue, reason: category);
        expect(
          data.hasAction(SemanticsAction.tap),
          isTrue,
          reason:
              '$category is announced as a button but offers no tap action, '
              'so assistive technology cannot activate it',
        );
      }

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('selecting a chip moves the selected state', (tester) async {
      final handle = tester.ensureSemantics();
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      expect(
        _data(
          tester,
          find.bySemanticsLabel(kAllQuestCategories),
        ).flagsCollection.isSelected,
        Tristate.isTrue,
      );

      await tester.tap(find.text('Kitchen'));
      await tester.pump();

      expect(
        _data(
          tester,
          find.bySemanticsLabel('Kitchen'),
        ).flagsCollection.isSelected,
        Tristate.isTrue,
      );
      expect(
        _data(
          tester,
          find.bySemanticsLabel(kAllQuestCategories),
        ).flagsCollection.isSelected,
        Tristate.isFalse,
      );

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('every chip keeps a 44 px tap target', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      for (final category in kQuestCategories) {
        final rect = tester.getRect(_chip(category));
        expect(
          rect.height,
          greaterThanOrEqualTo(NestDevice.tapParent),
          reason: category,
        );
        expect(
          rect.width,
          greaterThanOrEqualTo(NestDevice.tapParent),
          reason: category,
        );
      }

      await disposeApp(tester);
    });

    testWidgets('a tap 1 px inside the pill edge still lands on the chip', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      // The pill is itself 44 high, so the whole pill is the target and no
      // `NestChipWrap` hit slop is needed. Pin the pill's own edges.
      final all = tester.getRect(_chip(kAllQuestCategories));
      await tester.tapAt(Offset(all.center.dx, all.top + 1));
      await tester.pump();
      await tester.tapAt(Offset(all.center.dx, all.bottom - 1));
      await tester.pump();

      expect(find.text('Make your bed'), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('the isolated chip widget exposes its label and button flag', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      expect(find.byType(QuestFilterChip), findsWidgets);
      final data = _data(tester, find.byType(QuestFilterChip).first);
      expect(data.label, 'All');
      expect(data.flagsCollection.isButton, isTrue);

      handle.dispose();
      await disposeApp(tester);
    });
  });

  group('P10 `+ Add` button', () {
    testWidgets('it is one tappable button named after the idea', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      const label = 'Add Make your bed';
      expect(
        find.bySemanticsLabel(label),
        findsOneWidget,
        reason: 'the `+ Add` control needs its own semantics node',
      );
      final data = _data(tester, find.bySemanticsLabel(label));
      expect(data.label, label);
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.hasAction(SemanticsAction.tap), isTrue);

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('every visible row names its own Add button', (tester) async {
      final handle = tester.ensureSemantics();
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      for (final id in <String>['idea-bed', 'idea-table', 'idea-bins']) {
        final title = tester
            .widgetList<Text>(
              find.descendant(of: _ideaRow(id), matching: find.byType(Text)),
            )
            .first
            .data!;
        expect(
          find.bySemanticsLabel('Add $title'),
          findsOneWidget,
          reason: title,
        );
      }

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('the button keeps a 44 x 44 tap target', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      final rect = tester.getRect(find.byType(QuestAddButton).first);
      expect(rect.height, greaterThanOrEqualTo(NestDevice.tapParent));
      expect(rect.width, greaterThanOrEqualTo(NestDevice.tapParent));

      await disposeApp(tester);
    });

    testWidgets('the visible `+ Add` glyph is not announced on its own', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      // The pill's own node is named `Add {title}`; the literal `+ Add` text
      // must not surface as a second, unlabelled node.
      expect(find.text('+ Add'), findsWidgets);
      expect(
        find.bySemanticsLabel(RegExp(r'^\+ Add$')),
        findsNothing,
        reason: 'the label above owns the announcement',
      );

      handle.dispose();
      await disposeApp(tester);
    });
  });

  group('P10 Active rows', () {
    testWidgets('a row is one tappable button naming the quest and its meta', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      await tester.tap(find.text('Active (12)'));
      await tester.pumpAndSettle();

      // `q-bed` is "Make your bed"; the row's semantic label must not hide
      // the meta line a parent reads to judge the quest. Review finding 8
      // asks for one label carrying both (`'$title. $meta'`), so the finder
      // matches the quest name as a prefix rather than as the whole label.
      expect(
        find.byKey(const ValueKey<String>('quest-active-q-bed')),
        findsOneWidget,
      );
      final finder = find.bySemanticsLabel(RegExp('^Make your bed'));
      expect(finder, findsOneWidget, reason: 'the row needs its own node');
      final data = _data(tester, finder);
      expect(data.flagsCollection.isButton, isTrue);
      expect(
        data.hasAction(SemanticsAction.tap),
        isTrue,
        reason: 'the whole row is the tap target on the Active tab',
      );
      expect(data.label, contains('Make your bed'));
      expect(
        data.label,
        contains('coins'),
        reason: "the meta line must survive the row's semantic wrapper",
      );

      handle.dispose();
      await disposeApp(tester);
    });
  });

  group('P10 search field', () {
    testWidgets('it is a labelled text field', (tester) async {
      final handle = tester.ensureSemantics();
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      expect(find.bySemanticsLabel('Search quest ideas'), findsOneWidget);
      final data = _data(tester, find.bySemanticsLabel('Search quest ideas'));
      expect(data.flagsCollection.isTextField, isTrue);
      expect(data.label, 'Search quest ideas');

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('typing is reachable and updates the list', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'pet');
      await tester.pump();

      expect(find.text('Feed the pet'), findsOneWidget);
      expect(find.byType(QuestIdeaRow), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('the field keeps a 44 px minimum height', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      expect(
        tester.getSize(find.byType(TextField)).height,
        greaterThanOrEqualTo(NestDevice.tapParent),
      );

      await disposeApp(tester);
    });
  });

  group('P10 icon buttons', () {
    testWidgets('every interactive node announces what it does', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      const labels = <String>[..._visibleChips, 'Ideas', 'Add Make your bed'];
      for (final label in labels) {
        final finder = find.bySemanticsLabel(label);
        expect(finder, findsOneWidget, reason: label);
        final data = _data(tester, finder);
        expect(data.label.isNotEmpty, isTrue, reason: label);
      }

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('the row icons are decorative (no label of their own)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      // Each idea row carries a 24 px glyph with no label; the row text is
      // the name, so the glyph must not add a second announcement.
      expect(
        tester
            .widgetList<NestIcon>(
              find.descendant(
                of: _ideaRow('idea-bed'),
                matching: find.byType(NestIcon),
              ),
            )
            .every((icon) => icon.semanticLabel == null),
        isTrue,
      );

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('the route anchor stays out of the accessibility tree', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      // `_QuestLibraryRouteAnchor` exists only for other screens' tests.
      expect(find.bySemanticsLabel('P10 Quest library'), findsNothing);

      handle.dispose();
      await disposeApp(tester);
    });
  });

  group('P10 dark mode', () {
    testWidgets('the same semantics contract holds in dark', (tester) async {
      final handle = tester.ensureSemantics();
      await setUpTestScope();
      await pumpAppRoute(
        tester,
        QuestsRoutePaths.library,
        theme: ThemeMode.dark,
      );

      for (final label in const <String>['Ideas', 'All', 'Add Make your bed']) {
        expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
        final data = _data(tester, find.bySemanticsLabel(label));
        expect(data.flagsCollection.isButton, isTrue, reason: label);
        expect(data.hasAction(SemanticsAction.tap), isTrue, reason: label);
      }

      handle.dispose();
      await disposeApp(tester);
    });
  });
}
