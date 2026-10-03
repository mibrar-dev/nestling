// P09 · Quest editor — the full accessibility-action sweep.
//
// `quest_editor_view_test.dart` proves a slice of the a11y-actions rule; this
// file closes the rest of it, control by control:
//
//   * every one of the six icon tiles (the existing test covers only four)
//     and all seven day cells,
//   * each of the three "Due by" sheet rows — `performAction(tap)` must move
//     the REAL due label AND the `HH:MM` that lands in the database,
//   * the delete flow (row → modal → confirm) driven entirely through
//     `performAction`, with the Drift row as the oracle,
//   * a set-equality check on every button node the screen publishes, so a
//     control that loses its label (or gains a duplicated announcement) fails
//     here instead of in a screen-reader session.
//
// The rule under test (RULES §8): every interactive element exposes
// `SemanticsAction.tap`, and a disabled one exposes none while reporting
// `enabled: false`.

import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/quests/domain/quests_repository.dart';
import 'package:nestling/features/quests/presentation/widgets/quest_editor_widgets.dart';
import 'package:nestling/features/quests/quests_routes.dart';

import '../../test_scope.dart';

/// The one semantics node a control announces, found by its label.
SemanticsNode _button(String label) => find.semantics
    .byPredicate(
      (node) =>
          node.label == label &&
          node.getSemanticsData().flagsCollection.isButton,
    )
    .evaluate()
    .single;

/// `true` when the node states it is disabled (not merely "has no tap").
bool _isDisabled(SemanticsNode node) =>
    node.getSemanticsData().flagsCollection.isEnabled == Tristate.isFalse;

/// Every node a screen reader can activate: a button, or a switch (which
/// Flutter flags `toggled`, not `button` — `NestToggle` owns that flag).
bool _isInteractive(SemanticsNode node) =>
    node.getSemanticsData().flagsCollection.isButton ||
    node.getSemanticsData().flagsCollection.isToggled != Tristate.none;

/// `true` when the node carries an enabled/disabled state at all.
bool _hasEnabledState(SemanticsNode node) =>
    node.getSemanticsData().flagsCollection.isEnabled != Tristate.none;

/// Design order, from `_questIcons` (`quest_editor_view.dart`).
const List<(String, String)> _icons = <(String, String)>[
  ('bed', 'Bed'),
  ('dishwasher', 'Dishes'),
  ('hoover', 'Hoover'),
  ('book', 'Book'),
  ('bin', 'Bins'),
  ('paw', 'Paw'),
];

/// `_dueOptions` in `quest_editor_view.dart`: label plus the `HH:MM` it
/// stores. The mapping is the whole point of the test — a swapped pair would
/// persist the wrong due time.
const List<(String, String)> _dueOptions = <(String, String)>[
  ('Before school (8:30am)', '08:30'),
  ('Before tea (5pm)', '17:00'),
  ('Before bed (7:30pm)', '19:30'),
];

/// The default choice for a new quest (`_dueOptions[1]`).
const String _defaultDueLabel = 'Before tea (5pm)';

/// The handle must be disposed INSIDE the test body: `flutter_test` checks for
/// a live `SemanticsHandle` before tear-down callbacks run.
Future<SemanticsHandle> _pumpWithSemantics(
  WidgetTester tester, [
  String route = QuestsRoutePaths.editor,
]) async {
  final handle = tester.ensureSemantics();
  await pumpAppRoute(tester, route);
  await tester.pump();
  return handle;
}

Future<void> _scrollToDelete(WidgetTester tester) => tester.scrollUntilVisible(
  find.text('Delete quest'),
  200,
  scrollable: find.byType(Scrollable).first,
);

void main() {
  setUp(setUpTestScope);

  group('P09 a11y — icon tiles', () {
    testWidgets('all six tiles expose tap and select through semantics', (
      tester,
    ) async {
      final handle = await _pumpWithSemantics(tester);

      for (final (key, label) in _icons) {
        final node = _button('Icon: $label');
        expect(
          node.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
          reason: 'Icon: $label must expose tap',
        );
        node.owner!.performAction(node.id, SemanticsAction.tap);
        await tester.pump();
        expect(
          tester
              .widget<QuestIconTile>(
                find.byKey(ValueKey<String>('quest-icon-$key')),
              )
              .selected,
          isTrue,
          reason: 'Icon: $label must select the $key icon',
        );
        // Exactly one tile is ever selected (single-select group).
        expect(
          tester
              .widgetList<QuestIconTile>(find.byType(QuestIconTile))
              .where((tile) => tile.selected),
          hasLength(1),
        );
      }
      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('the six tiles are one announced radiogroup', (tester) async {
      final handle = await _pumpWithSemantics(tester);
      // `.icons role="radiogroup" aria-label="Quest icon"` — exactly ONE node
      // carries the group label (six would mean the group is announced six
      // times).
      expect(
        find.semantics.byPredicate((node) => node.label == 'Quest icon'),
        findsOneWidget,
      );
      final group = find.semantics
          .byPredicate((node) => node.label == 'Quest icon')
          .evaluate()
          .single;
      // The group itself is not a button; its children carry the actions.
      expect(group.getSemanticsData().flagsCollection.isButton, isFalse);
      expect(group.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      handle.dispose();
      await disposeApp(tester);
    });
  });

  group('P09 a11y — repeat days', () {
    testWidgets('every day cell exposes tap and toggles the real selection', (
      tester,
    ) async {
      final handle = await _pumpWithSemantics(tester);

      Set<int> selectedNow() =>
          tester.widget<NestDayPicker>(find.byType(NestDayPicker)).selected;

      // Saturday (5) starts selected; toggle each cell on, then off again, so
      // the assertion is "the click changed the set", not "it equals X".
      for (var i = 0; i < 7; i++) {
        final cell = tester.getSemantics(find.byKey(ValueKey<int>(i)));
        expect(
          cell.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
          reason: 'day cell $i must expose tap',
        );
        expect(cell.getSemanticsData().flagsCollection.isButton, isTrue);
        // Copy: the view mutates the picked set in place, so a reference
        // would follow the tap and hide it.
        final before = selectedNow().toSet();
        expect(before.contains(i), i == 5, reason: 'day $i initial state');

        cell.owner!.performAction(cell.id, SemanticsAction.tap);
        await tester.pump();
        expect(
          selectedNow().contains(i),
          isNot(before.contains(i)),
          reason: 'day $i toggled',
        );

        // Re-fetch: the node is stale after the rebuild.
        tester
            .getSemantics(find.byKey(ValueKey<int>(i)))
            .owner!
            .performAction(
              tester.getSemantics(find.byKey(ValueKey<int>(i))).id,
              SemanticsAction.tap,
            );
        await tester.pump();
        expect(
          selectedNow().contains(i),
          before.contains(i),
          reason: 'day $i toggled back',
        );
      }
      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('the day row announces its group label', (tester) async {
      final handle = await _pumpWithSemantics(tester);
      expect(
        find.semantics.byPredicate((node) => node.label == 'Repeat days'),
        findsOneWidget,
      );
      handle.dispose();
      await disposeApp(tester);
    });
  });

  group('P09 a11y — the due-time sheet', () {
    // One test per option: `pumpAppRoute` cannot re-navigate inside a single
    // test (the app keeps the router its State built on the first pump), and
    // after a save the screen is gone anyway.
    for (final (label, time) in _dueOptions) {
      testWidgets('`$label` is operable by semantics and stores $time', (
        tester,
      ) async {
        final handle = await _pumpWithSemantics(tester);

        // The card opens the sheet from its own button node.
        final dueRow = _button('Change due time');
        expect(
          dueRow.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
        );
        dueRow.owner!.performAction(dueRow.id, SemanticsAction.tap);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('Due by'), findsWidgets);

        final row = _button(label);
        expect(
          row.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
          reason: '$label must expose tap',
        );
        // Only the current choice is announced as selected.
        expect(
          row.getSemanticsData().flagsCollection.isSelected,
          label == _defaultDueLabel ? Tristate.isTrue : Tristate.isFalse,
          reason: '$label selected state in the sheet',
        );

        row.owner!.performAction(row.id, SemanticsAction.tap);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // Real state: the card reads the picked label…
        expect(find.text('$label ›'), findsOneWidget);
        // …and the DATABASE stores the matching HH:MM, not the label text.
        await tester.enterText(find.byType(TextField).first, 'Take the bins');
        await tester.pump();
        await tester.tap(find.text('Save'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        final saved = await tester.runAsync(
          () => GetIt.instance<QuestsRepository>().getItems(),
        );
        final created = saved!.firstWhere(
          (quest) => quest.title == 'Take the bins',
        );
        expect(created.dueLabel, label);
        expect(created.dueTimeLocal, time);

        handle.dispose();
        await disposeApp(tester);
      });
    }

    testWidgets('the sheet re-opens with the newest choice marked selected', (
      tester,
    ) async {
      final handle = await _pumpWithSemantics(tester);

      Future<void> pick(String label) async {
        final dueRow = _button('Change due time');
        dueRow.owner!.performAction(dueRow.id, SemanticsAction.tap);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        final row = _button(label);
        row.owner!.performAction(row.id, SemanticsAction.tap);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
      }

      await pick(_dueOptions[2].$1);
      expect(find.text('${_dueOptions[2].$1} ›'), findsOneWidget);
      await pick(_dueOptions[0].$1);
      expect(find.text('${_dueOptions[0].$1} ›'), findsOneWidget);
      expect(find.text('${_dueOptions[2].$1} ›'), findsNothing);

      handle.dispose();
      await disposeApp(tester);
    });
  });

  group('P09 a11y — delete flow', () {
    testWidgets('the confirm modal is fully operable by semantics', (
      tester,
    ) async {
      final handle = await _pumpWithSemantics(
        tester,
        '${QuestsRoutePaths.editor}?id=q-hoover',
      );
      await _scrollToDelete(tester);

      final trigger = _button('Delete quest');
      expect(trigger.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      trigger.owner!.performAction(trigger.id, SemanticsAction.tap);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Delete this quest?'), findsOneWidget);

      // `Keep it` is a real, labelled, activatable control — and it aborts.
      final keep = _button('Keep it');
      expect(keep.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      keep.owner!.performAction(keep.id, SemanticsAction.tap);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Delete this quest?'), findsNothing);
      expect(
        await tester.runAsync(
          () => GetIt.instance<QuestsRepository>().getQuest('q-hoover'),
        ),
        isNotNull,
      );

      // …and `Delete` really removes the row.
      await _scrollToDelete(tester);
      final again = _button('Delete quest');
      again.owner!.performAction(again.id, SemanticsAction.tap);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final confirm = _button('Delete');
      expect(confirm.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      confirm.owner!.performAction(confirm.id, SemanticsAction.tap);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        await tester.runAsync(
          () => GetIt.instance<QuestsRepository>().getQuest('q-hoover'),
        ),
        isNull,
      );
      handle.dispose();
      await disposeApp(tester);
    });
  });

  group('P09 a11y — labels and actions, exhaustively', () {
    testWidgets('the screen publishes exactly the expected control nodes', (
      tester,
    ) async {
      final handle = await _pumpWithSemantics(tester);

      final labels =
          find.semantics
              .byPredicate(_isInteractive)
              .evaluate()
              .map((node) => node.label)
              .toList()
            ..sort();

      expect(
        labels,
        <String>[
          // 6 icon tiles, one per design slot, in design order.
          for (final (String _, String label) in _icons) 'Icon: $label',
          // 7 day cells: the design's M T W T F S S, so T and S repeat.
          'Day F',
          'Day M',
          'Day S',
          'Day S',
          'Day T',
          'Day T',
          'Day W',
          'Anyone',
          'Cancel',
          'Change due time',
          'Daily',
          'Decrease reward',
          'Increase reward',
          'Leo',
          'Maya',
          'Needs my approval',
          'Once',
          'Save',
          'Weekly',
        ]..sort(),
        reason: 'every control announces itself exactly once, nothing extra',
      );
      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('every control node can be activated, or says it is disabled', (
      tester,
    ) async {
      final handle = await _pumpWithSemantics(tester);

      final offenders = <String>[];
      for (final node
          in find.semantics.byPredicate(_isInteractive).evaluate()) {
        final data = node.getSemanticsData();
        if (!data.hasAction(SemanticsAction.tap) && !_isDisabled(node)) {
          offenders.add('${node.label} (button with no tap action)');
        }
      }
      expect(offenders, isEmpty);
      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('a disabled Save reports `enabled: false` and has no tap', (
      tester,
    ) async {
      final handle = await _pumpWithSemantics(tester);
      expect(
        _button('Save').getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );

      await tester.enterText(find.byType(TextField).first, '  ');
      await tester.pump();

      final disabled = _button('Save');
      expect(
        disabled.getSemanticsData().hasAction(SemanticsAction.tap),
        isFalse,
      );
      expect(_hasEnabledState(disabled), isTrue);
      expect(_isDisabled(disabled), isTrue);
      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('the title and each group label are announced as headers', (
      tester,
    ) async {
      final handle = await _pumpWithSemantics(tester);

      final headers = find.semantics
          .byPredicate(
            (node) => node.getSemanticsData().flagsCollection.isHeader,
          )
          .evaluate()
          .map((node) => node.label)
          .toList();
      expect(
        headers,
        containsAll(<String>['New quest', 'Icon', "Who's it for?", 'Repeats']),
      );
      // The plan marks exactly those four as headings; the capture shows
      // nothing else is promoted (field label / helper / toggle stay plain).
      expect(headers, hasLength(4));
      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('the approval toggle announces its state and flips it', (
      tester,
    ) async {
      final handle = await _pumpWithSemantics(tester);
      final toggle = tester.getSemantics(find.byType(NestToggle));
      expect(toggle.label, 'Needs my approval');
      expect(toggle.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      expect(
        toggle.getSemanticsData().flagsCollection.isToggled,
        Tristate.isTrue,
        reason: 'an ON switch reports toggled',
      );
      toggle.owner!.performAction(toggle.id, SemanticsAction.tap);
      await tester.pump();
      expect(
        tester
            .getSemantics(find.byType(NestToggle))
            .getSemanticsData()
            .flagsCollection
            .isToggled,
        Tristate.isFalse,
      );
      handle.dispose();
      await disposeApp(tester);
    });
  });
}
