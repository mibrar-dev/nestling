import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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

    testWidgets("?questId= (P08 Today's spelling) also pre-fills edit mode", (
      tester,
    ) async {
      // P08 Today pushes `?questId=<id>` (`today_loaded_body.dart:700`), so the
      // row it opens must land in edit mode, not on a blank NEW quest.
      await pumpAppRoute(
        tester,
        '${QuestsRoutePaths.editor}?${QuestsEditorQuery.legacyQuestId}=q-hoover',
      );
      expect(find.text('Edit quest'), findsOneWidget);
      expect(find.text('Delete quest'), findsOneWidget);
      expect(find.text('Hoover the stairs'), findsOneWidget);
      expect(find.text('New quest'), findsNothing);
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

    // Absolute y, design -> app, measured off the PNG (÷3). Everything above
    // the assignee row is pinned outright; below it the assertions are
    // block-to-block deltas, which are the same numbers (the design's pills
    // sit on one row) but survive the widget-test font, whose fixed-width
    // glyphs make the pills wrap.
    testWidgets('vertical positions match the design (UI-verdict ±2px)', (
      tester,
    ) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);

      Rect rectOf(Finder finder) => tester.getRect(finder);

      // Sheet starts under the 47px status bar; the `.sheet::before` grabber
      // sits 8 (sheet padding) + 4 (::before margin) below its top edge.
      expect(rectOf(find.byType(NestStatusBar)).height, 47);
      expect(rectOf(find.byType(DecoratedBox).at(0)).top, 47);

      // Header row 80 -> 124, Save pill flush to the 370 gutter.
      expect(rectOf(find.byType(QuestSavePill)).top, 80);
      expect(rectOf(find.byType(QuestSavePill)).height, 44);
      expect(rectOf(find.byType(QuestSavePill)).right, 370);
      expect(rectOf(find.text('Cancel')).top, 90);
      expect(rectOf(find.text('New quest')).top, 90);

      // `.field`: label 132, input 156 (52 high, 350 wide, 20 gutter).
      expect(rectOf(find.text('Quest name')).top, 132);
      final input = rectOf(find.byType(TextField));
      expect(input.top, 156);
      expect(input.height, 52);
      expect(input.left, NestSpacing.padSide);
      expect(input.width, 350);

      // `.lbl` "Icon" flush under the field, tiles on the 17.2px grid.
      expect(rectOf(find.text('Icon')).top, 208);
      final tiles = <String>[
        'bed',
        'dishwasher',
        'hoover',
        'book',
        'bin',
        'paw',
      ];
      for (var i = 0; i < tiles.length; i++) {
        final tile = rectOf(
          find.byKey(ValueKey<String>('quest-icon-${tiles[i]}')),
        );
        expect(tile.top, 232, reason: '${tiles[i]} top');
        expect(tile.height, 44, reason: '${tiles[i]} height');
        expect(
          tile.left,
          // `.icons` is `grid-template-columns: repeat(6, 44px)` with
          // `justify-content: space-between`, so the free 86px splits into
          // five 17.2px gaps.
          closeTo(NestSpacing.padSide + i * (44 + (350 - 6 * 44) / 5), 0.05),
          reason: '${tiles[i]} left',
        );
      }

      // `.lbl` "Who's it for?" then the 48-tall pills.
      expect(rectOf(find.text("Who's it for?")).top, 276);
      final pill = rectOf(
        find.byKey(const ValueKey<String>('quest-assignee-maya')),
      );
      expect(pill.top, 300);
      expect(pill.height, 48);
      expect(pill.left, NestSpacing.padSide);

      // Below the pills: exact block-to-block deltas (design y in brackets).
      // The design fits Maya/Leo/Anyone on ONE 48-tall row; the widget-test
      // font's fixed-width glyphs make them wrap, so the chain is anchored on
      // the last pill's bottom rather than on the row's top (the 16 gap below
      // the pills is identical either way).
      final lastPill = rectOf(
        find.byKey(const ValueKey<String>('quest-assignee-anyone')),
      );
      final reward = rectOf(find.byType(NestCard).at(0));
      expect(reward.top - lastPill.bottom, 16); // [364]
      expect(reward.height, 76); // 364 -> 440
      expect(reward.left, NestSpacing.padSide);
      expect(reward.width, 350);

      final stepper = rectOf(find.byType(NestStepper));
      expect(stepper.top - reward.top, 16); // 44 inside a 76 card
      expect(stepper.height, 44);
      expect(stepper.right, 354);

      final repeats = rectOf(find.text('Repeats'));
      expect(repeats.top - reward.bottom, 16); // [456]
      expect(repeats.height, 18);

      final segmented = rectOf(find.byType(NestSegmented<String>));
      expect(segmented.top - repeats.bottom, 6); // [480]
      expect(segmented.height, 52);
      expect(segmented.left, NestSpacing.padSide);
      expect(segmented.width, 350);

      final days = rectOf(find.byType(NestDayPicker));
      expect(days.top - segmented.bottom, 8); // [540]
      expect(days.height, 44);
      expect(days.left, NestSpacing.padSide);
      for (var i = 0; i < 7; i++) {
        final cell = rectOf(find.byKey(ValueKey<int>(i)));
        expect(cell.top, closeTo(days.top, 0.01), reason: 'day $i top');
        expect(cell.height, 44, reason: 'day $i height');
      }

      final approval = rectOf(find.byType(NestCard).at(1));
      expect(approval.top - days.bottom, 16); // [600]
      // Design height 72 = 16 + 16/22 title + 13/18 sub + 16. Asserted
      // against the measured text so it holds whatever the font does (the
      // widget-test font wraps both lines to two).
      expect(
        approval.height,
        NestSpacing.s4 +
            rectOf(find.text('Needs my approval')).height +
            rectOf(find.text('Coins land after your thumbs-up')).height +
            NestSpacing.s3,
      );
      expect(approval.left, NestSpacing.padSide);
      expect(approval.width, 350);

      final toggle = rectOf(find.byType(NestToggle));
      // `.toggle` is a 51x31 track with the CSS `::before` hit area 4 px wider
      // on each side, and the PNG puts the TRACK flush to the card's content
      // edge (x 303 -> 354). `NestToggle` centres the track inside its 59x44
      // box, so the view shifts the whole control by
      // `QuestEditorMetrics.toggleTrackOffset`: the box overhangs to 358 and
      // the painted track lands flush at 354.
      expect(toggle.right, 358);
      expect(toggle.height, NestDevice.tapParent);
      expect(
        toggle.right - 4,
        354,
        reason: 'painted track flush with the card content edge',
      );

      final due = rectOf(find.byType(NestCard).at(2));
      expect(due.top - approval.bottom, 12); // [684]
      expect(due.height, 88); // 56 row + 2x16 padding
      expect(due.left, NestSpacing.padSide);
      expect(due.width, 350);
      await disposeApp(tester);
    });

    // Owner rule: the sheet's paper runs to the PHYSICAL bottom edge. A
    // `--surface-2` strip under the last card (or around the home indicator)
    // is a UI failure in both themes.
    testWidgets('paper runs to the physical bottom edge', (tester) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      final sheet = tester.getRect(
        find.byKey(const ValueKey<String>('quest-editor-sheet')),
      );
      expect(sheet.top, 47); // straight under the status bar
      expect(sheet.left, 0);
      expect(sheet.width, NestDevice.width);
      // The sheet is `minHeight: 100%` of the scroll area, so it always
      // covers the last pixel of the screen. (When the content is taller than
      // the viewport — the widget-test font makes the assignee pills wrap —
      // it scrolls past, which still leaves no surface-2 strip on show.)
      expect(sheet.bottom, greaterThanOrEqualTo(NestDevice.height));
      expect(
        tester.getRect(find.byType(SingleChildScrollView)).bottom,
        NestDevice.height,
      );
      await disposeApp(tester);
    });
  });

  group('P09 quest editor — accessibility actions', () {
    setUp(setUpTestScope);

    /// Every interactive control must expose `SemanticsAction.tap` on the one
    /// node that announces it, and activating that node must move the real
    /// state (WCAG 4.1.2 — an "is a button" node that cannot be activated is
    /// the exact failure this guards).
    SemanticsNode button(String label) => find.semantics
        .byPredicate(
          (n) =>
              n.label == label && n.getSemanticsData().flagsCollection.isButton,
        )
        .evaluate()
        .single;

    /// The semantics tree must be switched on before the assertions, and the
    /// handle released inside the test body (tear-down runs too late for
    /// `flutter_test`'s own check).
    Future<SemanticsHandle> pumpSemantics(WidgetTester tester) async {
      final handle = tester.ensureSemantics();
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      await tester.pump();
      return handle;
    }

    testWidgets('icon tiles expose tap and select through semantics', (
      tester,
    ) async {
      final handle = await pumpSemantics(tester);
      for (final key in <String>['book', 'bin', 'paw', 'hoover']) {
        final label =
            'Icon: ${switch (key) {
              'book' => 'Book',
              'bin' => 'Bins',
              'paw' => 'Paw',
              _ => 'Hoover',
            }}';
        expect(
          button(label).getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
          reason: '$label must expose tap',
        );
        tester.semantics.performAction(
          find.semantics.byPredicate(
            (n) =>
                n.label == label &&
                n.getSemanticsData().flagsCollection.isButton,
          ),
          SemanticsAction.tap,
        );
        await tester.pump();
        expect(
          _iconTile(tester, key).selected,
          isTrue,
          reason: '$label must select $key',
        );
      }
      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('person pills expose tap and select through semantics', (
      tester,
    ) async {
      final handle = await pumpSemantics(tester);
      for (final id in <String>['leo', 'anyone', 'maya']) {
        final node = button(switch (id) {
          'leo' => 'Leo',
          'anyone' => 'Anyone',
          _ => 'Maya',
        });
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
        node.owner!.performAction(node.id, SemanticsAction.tap);
        await tester.pump();
        expect(_personPill(tester, 'quest-assignee-$id').selected, isTrue);
      }
      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('repeat options and day cells expose tap', (tester) async {
      final handle = await pumpSemantics(tester);
      for (final label in <String>['Once', 'Daily', 'Weekly']) {
        final node = button(label);
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
        node.owner!.performAction(node.id, SemanticsAction.tap);
        await tester.pump();
        expect(
          tester
              .widget<NestSegmented<String>>(find.byType(NestSegmented<String>))
              .value,
          label.toLowerCase(),
        );
      }
      // Day cell 3 (Thursday) toggles on, then back off.
      for (var i = 0; i < 2; i++) {
        final node = tester.getSemantics(find.byKey(const ValueKey<int>(3)));
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
        node.owner!.performAction(node.id, SemanticsAction.tap);
        await tester.pump();
        final selected = tester
            .widget<NestDayPicker>(find.byType(NestDayPicker))
            .selected;
        expect(selected.contains(3), i == 0);
      }
      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('stepper, toggle and the due row expose tap', (tester) async {
      final handle = await pumpSemantics(tester);
      for (final key in <String>['increase', 'decrease']) {
        final node = tester.getSemantics(find.byKey(ValueKey<String>(key)));
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
        node.owner!.performAction(node.id, SemanticsAction.tap);
        await tester.pump();
      }
      expect(find.text('15'), findsOneWidget);

      final toggle = tester.getSemantics(find.byType(NestToggle));
      expect(toggle.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      toggle.owner!.performAction(toggle.id, SemanticsAction.tap);
      await tester.pump();
      expect(tester.widget<NestToggle>(find.byType(NestToggle)).value, isFalse);

      final dueRow = tester.getSemantics(find.text('Due by'));
      expect(dueRow.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      dueRow.owner!.performAction(dueRow.id, SemanticsAction.tap);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Before bed (7:30pm)'), findsOneWidget);
      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('Save and Cancel expose tap', (tester) async {
      final handle = await pumpSemantics(tester);
      final save = button('Save');
      expect(save.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      final cancel = button('Cancel');
      expect(cancel.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      cancel.owner!.performAction(cancel.id, SemanticsAction.tap);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('New quest'), findsNothing);
      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('a blank title takes tap away from Save', (tester) async {
      final handle = await pumpSemantics(tester);
      await tester.enterText(find.byType(TextField).first, ' ');
      await tester.pump();
      expect(
        button('Save').getSemanticsData().hasAction(SemanticsAction.tap),
        isFalse,
      );
      handle.dispose();
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
