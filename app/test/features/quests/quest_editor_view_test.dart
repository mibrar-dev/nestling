import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/quests/domain/quests_repository.dart';
import 'package:nestling/features/quests/presentation/widgets/quest_editor_widgets.dart';
import 'package:nestling/features/quests/quests_routes.dart';

import '../../test_scope.dart';

/// Resizes the surface (and optionally scales text), then settles a frame.
Future<void> _resize(
  WidgetTester tester,
  double width, [
  double scale = 1,
]) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

QuestSavePill _savePill(WidgetTester tester) =>
    tester.widget<QuestSavePill>(find.byType(QuestSavePill));

QuestPersonPill _personPill(WidgetTester tester, String key) =>
    tester.widget<QuestPersonPill>(find.byKey(ValueKey<String>(key)));

QuestIconTile _iconTile(WidgetTester tester, String key) => tester
    .widget<QuestIconTile>(find.byKey(ValueKey<String>('quest-icon-$key')));

/// The day cells are the only `ValueKey<int>` in the sheet, and
/// `NestDayPicker` keys them by index (0 = Monday).
Finder _dayCell(int index) => find.byKey(ValueKey<int>(index));

/// Taps a stepper button (`decrease` / `increase` — the component's own
/// `ValueKey`s) until the value bottoms out (30 taps covers 15 → 1).
Future<void> _tapAllSteps(WidgetTester tester, String key) async {
  final button = find.byKey(ValueKey<String>(key));
  for (var i = 0; i < 30; i++) {
    await tester.tap(button, warnIfMissed: false);
    await tester.pump();
  }
}

/// Taps the only selected day cell, emptying the weekly selection.
Future<void> _clearDays(WidgetTester tester) async {
  await tester.tap(_dayCell(5));
  await tester.pump();
}

void main() {
  group('P09 quest editor — new quest (light, demo seed)', () {
    setUp(setUpTestScope);

    testWidgets('shows every design default', (tester) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      expect(find.text('New quest'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Quest name'), findsOneWidget);
      expect(find.text('Hoover the stairs'), findsOneWidget);
      expect(find.text('Icon'), findsOneWidget);
      expect(find.text("Who's it for?"), findsOneWidget);
      expect(find.text('Maya'), findsOneWidget);
      expect(find.text('Leo'), findsOneWidget);
      expect(find.text('Anyone'), findsOneWidget);
      expect(find.text('Reward'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('= 15p at payout'), findsOneWidget);
      expect(find.text('Repeats'), findsOneWidget);
      expect(find.text('Once'), findsOneWidget);
      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.byType(NestDayPicker), findsOneWidget);
      expect(find.text('Needs my approval'), findsOneWidget);
      expect(find.text('Coins land after your thumbs-up'), findsOneWidget);
      expect(find.text('Due by'), findsOneWidget);
      expect(find.text('Before tea (5pm) ›'), findsOneWidget);
      // DESIGN_SPEC: delete is not shown for a new quest.
      expect(find.text('Delete quest'), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('hoover tile and Maya pill start selected', (tester) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      expect(_iconTile(tester, 'hoover').selected, isTrue);
      expect(_iconTile(tester, 'bed').selected, isFalse);
      expect(_personPill(tester, 'quest-assignee-maya').selected, isTrue);
      expect(_personPill(tester, 'quest-assignee-leo').selected, isFalse);
      expect(_personPill(tester, 'quest-assignee-anyone').selected, isFalse);
      expect(_savePill(tester).onPressed, isNotNull);
      await disposeApp(tester);
    });

    testWidgets('Saturday (index 5) is the only selected repeat day', (
      tester,
    ) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      final picker = tester.widget<NestDayPicker>(find.byType(NestDayPicker));
      expect(picker.selected, <int>{5});
      expect(picker.days, <String>['M', 'T', 'W', 'T', 'F', 'S', 'S']);
      await disposeApp(tester);
    });

    testWidgets('children render in creation order, Maya then Leo', (
      tester,
    ) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      // Tree order, not x position: widget tests use a fixed-width box per
      // glyph, so the pills are much wider here than in the design font and
      // "Anyone" wraps onto a second row.
      expect(
        tester
            .widgetList<QuestPersonPill>(find.byType(QuestPersonPill))
            .map((pill) => pill.label),
        <String>['Maya', 'Leo', 'Anyone'],
      );
      await disposeApp(tester);
    });

    testWidgets('stepper + shows 16 and updates the helper', (tester) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      await tester.tap(find.byKey(const ValueKey<String>('increase')));
      await tester.pump();
      expect(find.text('16'), findsOneWidget);
      expect(find.text('= 16p at payout'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('stepper − stops at 1 coin', (tester) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      await _tapAllSteps(tester, 'decrease');
      expect(find.text('1'), findsOneWidget);
      expect(find.text('= 1p at payout'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('Once and Daily hide the day row', (tester) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      await tester.tap(find.text('Once'));
      await tester.pump();
      expect(find.byType(NestDayPicker), findsNothing);
      await tester.tap(find.text('Daily'));
      await tester.pump();
      expect(find.byType(NestDayPicker), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('Weekly brings the day row back', (tester) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      await tester.tap(find.text('Daily'));
      await tester.pump();
      await tester.tap(find.text('Weekly'));
      await tester.pump();
      expect(find.byType(NestDayPicker), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('blank title disables Save', (tester) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      expect(_savePill(tester).onPressed, isNotNull);
      await tester.enterText(find.byType(TextField).first, '   ');
      await tester.pump();
      expect(_savePill(tester).onPressed, isNull);
      await disposeApp(tester);
    });

    testWidgets('weekly with no day selected blocks Save and explains why', (
      tester,
    ) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      await _clearDays(tester);
      expect(
        tester.widget<NestDayPicker>(find.byType(NestDayPicker)).selected,
        isEmpty,
      );
      expect(find.text('Pick at least one day'), findsOneWidget);
      expect(_savePill(tester).onPressed, isNull);
      await disposeApp(tester);
    });

    testWidgets('the whole 44px day cell is tappable, edges included', (
      tester,
    ) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      final rect = tester.getRect(_dayCell(5));
      expect(rect.height, greaterThanOrEqualTo(NestDevice.tapParent));

      await tester.tapAt(Offset(rect.center.dx, rect.bottom - 2));
      await tester.pump();
      expect(
        tester.widget<NestDayPicker>(find.byType(NestDayPicker)).selected,
        isNot(contains(5)),
      );
      await tester.tapAt(Offset(rect.center.dx, rect.top + 2));
      await tester.pump();
      expect(
        tester.widget<NestDayPicker>(find.byType(NestDayPicker)).selected,
        contains(5),
      );
      await disposeApp(tester);
    });

    testWidgets('icon tiles are single-select', (tester) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      await tester.tap(find.byKey(const ValueKey<String>('quest-icon-book')));
      await tester.pump();
      expect(_iconTile(tester, 'book').selected, isTrue);
      expect(_iconTile(tester, 'hoover').selected, isFalse);
      await disposeApp(tester);
    });

    testWidgets('assignee pills are single-select', (tester) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      await tester.tap(find.text('Leo'));
      await tester.pump();
      expect(_personPill(tester, 'quest-assignee-leo').selected, isTrue);
      expect(_personPill(tester, 'quest-assignee-maya').selected, isFalse);
      await tester.tap(find.text('Anyone'));
      await tester.pump();
      expect(_personPill(tester, 'quest-assignee-anyone').selected, isTrue);
      expect(_personPill(tester, 'quest-assignee-leo').selected, isFalse);
      await disposeApp(tester);
    });

    testWidgets('the approval toggle flips', (tester) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      final before = tester.widget<NestToggle>(find.byType(NestToggle));
      expect(before.value, isTrue);
      await tester.tap(find.byType(NestToggle));
      await tester.pump();
      expect(tester.widget<NestToggle>(find.byType(NestToggle)).value, isFalse);
      await disposeApp(tester);
    });

    testWidgets('the due row opens the option sheet and applies a choice', (
      tester,
    ) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      await tester.tap(find.text('Due by'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Before school (8:30am)'), findsOneWidget);
      expect(find.text('Before tea (5pm)'), findsOneWidget);
      expect(find.text('Before bed (7:30pm)'), findsOneWidget);

      await tester.tap(find.text('Before bed (7:30pm)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Before tea (5pm) ›'), findsNothing);
      expect(find.text('Before bed (7:30pm) ›'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('Cancel leaves the editor', (tester) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('New quest'), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('Save persists the quest and lands on the library', (
      tester,
    ) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      await tester.enterText(find.byType(TextField).first, 'Wipe the kitchen');
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('New quest'), findsNothing);
      // Real Drift IO has to leave the fake-async zone.
      final saved = await tester.runAsync(
        () => GetIt.instance<QuestsRepository>().getItems(),
      );
      expect(saved!.map((quest) => quest.title), contains('Wipe the kitchen'));
      final created = saved.firstWhere(
        (quest) => quest.title == 'Wipe the kitchen',
      );
      expect(created.icon, 'hoover');
      expect(created.coins, 15);
      expect(created.repeatRule, 'weekly');
      expect(created.days, '6');
      expect(created.dueLabel, 'Before tea (5pm)');
      expect(created.dueTimeLocal, '17:00');
      expect(created.needsApproval, isTrue);
      expect(created.assigneeChildId, 'maya');
      expect(created.active, isTrue);
      await disposeApp(tester);
    });
  });

  group('P09 quest editor — edit quest', () {
    setUp(setUpTestScope);

    testWidgets('?id=q-hoover pre-fills the database row', (tester) async {
      await pumpAppRoute(tester, '${QuestsRoutePaths.editor}?id=q-hoover');
      expect(find.text('Edit quest'), findsOneWidget);
      expect(find.text('Delete quest'), findsOneWidget);
      expect(find.text('Hoover the stairs'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      expect(find.text('= 20p at payout'), findsOneWidget);
      expect(_iconTile(tester, 'hoover').selected, isTrue);
      expect(_personPill(tester, 'quest-assignee-maya').selected, isTrue);
      await disposeApp(tester);
    });

    testWidgets('an edited quest updates in place', (tester) async {
      await pumpAppRoute(tester, '${QuestsRoutePaths.editor}?id=q-hoover');
      await tester.enterText(
        find.byType(TextField).first,
        'Hoover the whole stairwell',
      );
      await tester.tap(find.byKey(const ValueKey<String>('increase')));
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      final updated = await tester.runAsync(
        () => GetIt.instance<QuestsRepository>().getQuest('q-hoover'),
      );
      expect(updated?.title, 'Hoover the whole stairwell');
      expect(updated?.coins, 21);
      await disposeApp(tester);
    });

    testWidgets('unknown id shows Quest not found and a way back', (
      tester,
    ) async {
      await pumpAppRoute(tester, '${QuestsRoutePaths.editor}?id=q-nope');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Quest not found'), findsOneWidget);
      expect(find.text('Back to quests'), findsOneWidget);
      await tester.tap(find.text('Back to quests'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Quest not found'), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('delete asks first, and Keep it changes nothing', (
      tester,
    ) async {
      await pumpAppRoute(tester, '${QuestsRoutePaths.editor}?id=q-hoover');
      // The edit sheet is taller than 844, so Delete sits below the fold.
      await tester.scrollUntilVisible(
        find.text('Delete quest'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Delete quest'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Delete this quest?'), findsOneWidget);

      await tester.tap(find.text('Keep it'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Delete this quest?'), findsNothing);
      expect(find.text('Edit quest'), findsOneWidget);
      expect(
        await tester.runAsync(
          () => GetIt.instance<QuestsRepository>().getQuest('q-hoover'),
        ),
        isNotNull,
      );
      await disposeApp(tester);
    });

    testWidgets('confirmed delete removes the quest', (tester) async {
      await pumpAppRoute(tester, '${QuestsRoutePaths.editor}?id=q-hoover');
      await tester.scrollUntilVisible(
        find.text('Delete quest'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Delete quest'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.widgetWithText(NestButton, 'Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Edit quest'), findsNothing);
      expect(
        await tester.runAsync(
          () => GetIt.instance<QuestsRepository>().getQuest('q-hoover'),
        ),
        isNull,
      );
      await disposeApp(tester);
    });
  });

  group('P09 quest editor — empty family', () {
    setUp(() async {
      // Onboarded parent with no children (P08b seed) — an unseeded database
      // would redirect the router to onboarding.
      final db = await setUpTestScope(seedDemo: false);
      await Seed.empty(db);
      await GetIt.instance<AppSession>().refresh();
    });

    testWidgets('the assignee row offers Anyone only', (tester) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      expect(find.text('Maya'), findsNothing);
      expect(find.text('Leo'), findsNothing);
      expect(_personPill(tester, 'quest-assignee-anyone').selected, isTrue);
      await disposeApp(tester);
    });
  });

  group('P09 quest editor — design geometry', () {
    setUp(setUpTestScope);

    // Owner rule: a UI check compares the visible BACKGROUND/BORDER rect, not
    // where the text lands. These are the rects measured off
    // design/screens/light/P09-quest-editor.png (÷3), so a collapsed pill or a
    // border that leaks outside its box fails here first. Only sizes that do
    // not depend on text metrics are asserted — widget tests use a
    // fixed-width box per glyph, which changes every measured text width.
    testWidgets('shapes match the design rects', (tester) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);

      // `.ic`: 44x44, first tile on the 20px gutter.
      final tile = tester.getRect(
        find.byKey(const ValueKey<String>('quest-icon-bed')),
      );
      expect(tile.left, NestSpacing.padSide);
      expect(tile.width, 44);
      expect(tile.height, 44);

      // `.person`: 48 tall on the same gutter.
      final pill = tester.getRect(
        find.byKey(const ValueKey<String>('quest-assignee-maya')),
      );
      expect(pill.left, NestSpacing.padSide);
      expect(pill.height, 48);

      // `.save`: 44 tall, flush to the 370 gutter.
      final save = tester.getRect(find.byType(QuestSavePill));
      expect(save.height, 44);
      expect(save.right, NestDevice.width - NestSpacing.padSide);

      // Every card spans the same 20 → 370 column.
      expect(find.byType(NestCard), findsNWidgets(3));
      for (var i = 0; i < 3; i++) {
        final rect = tester.getRect(find.byType(NestCard).at(i));
        expect(rect.left, NestSpacing.padSide, reason: 'card $i left');
        expect(rect.width, 350, reason: 'card $i width');
      }
      // `.card.inset` reward row: 44 (stepper) + 2x16 padding.
      expect(tester.getRect(find.byType(NestCard).at(0)).height, 76);
      // `.due` row: 56 + 2x16 padding.
      expect(tester.getRect(find.byType(NestCard).at(2)).height, 88);
      await disposeApp(tester);
    });
  });

  group('P09 quest editor — dark mode', () {
    setUp(setUpTestScope);

    testWidgets('pumps the same screen without error', (tester) async {
      await pumpAppRoute(
        tester,
        QuestsRoutePaths.editor,
        theme: ThemeMode.dark,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('New quest'), findsOneWidget);
      expect(find.text('= 15p at payout'), findsOneWidget);
      expect(find.text('Before tea (5pm) ›'), findsOneWidget);
      await disposeApp(tester);
    });
  });

  group('P09 quest editor — robustness', () {
    setUp(setUpTestScope);

    testWidgets('a 320-wide surface has no overflow', (tester) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      await _resize(tester, 320);
      expect(tester.takeException(), isNull);
      expect(find.text('New quest'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('text scale 1.3 has no overflow', (tester) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      await _resize(tester, 390, 1.3);
      expect(tester.takeException(), isNull);
      expect(find.text('New quest'), findsOneWidget);
      expect(find.text('Coins land after your thumbs-up'), findsOneWidget);
      await disposeApp(tester);
    });
  });
}
