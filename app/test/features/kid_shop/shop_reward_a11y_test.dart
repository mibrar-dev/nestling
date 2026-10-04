// K08 · Reward shop — per-card semantics (stage 3, iteration 2).
//
// The shape of the accessibility tree on the shop grid, pinned node by node.
// This lives beside the card-widget tests rather than in `k08_bugs_test.dart`
// because the iteration-2 bug stage was editing that file while this stage
// ran; the open proof below is cross-referenced from `3_test.md` and
// `6_bugs.md` as K08-BUG-5.
//
//   K08-BUG-5  minor  OPEN — every card's reward NAME merges into ONE
//                     semantics node, so a screen reader announces the whole
//                     reward list ("30 min extra screen time, Pick Friday film,
//                     Stay up 15 min later, …") as a single run and the name
//                     can no longer be tied to its own price and button.
//
// Everything else in this file is green and pins the tree the fixes produced:
//   * the price is its OWN node ("50 coins", no tap action) — K08-BUG-3's fix
//     and its `container: true`;
//   * each card's button is its own node, labelled after the reward, with a tap
//     action (or `enabled: false` for the one out of reach);
//   * the coin pill and the heading are announced together in the head row.
//
// Run directly:
//   flutter test --timeout 120s test/features/kid_shop/shop_reward_a11y_test.dart

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/design_system/design_system.dart';

import '../../test_scope.dart';

const String _route = '/reward-shop';

/// The six seeded titles, in creation order.
const List<String> _titles = <String>[
  '30 min extra screen time',
  'Pick Friday film',
  'Stay up 15 min later',
  'Baking together',
  'Trip to the park café',
  'Choose dinner',
];

/// Every non-empty label a screen reader can reach, in tree order.
///
/// Walked through `find.bySemanticsLabel` rather than
/// `binding.pipelineOwner.semanticsOwner` (deprecated) or a hand-rolled
/// `visitChildren` walk, so the answer is exactly what the platform sees.
/// Requires `tester.ensureSemantics()`.
List<String> _labels(WidgetTester tester) {
  final labels = <String>[];
  for (final element in find.bySemanticsLabel(RegExp('.')).evaluate()) {
    final node = tester.getSemantics(
      find.byElementPredicate((candidate) => identical(candidate, element)),
    );
    labels.add(node.getSemanticsData().label);
  }
  return labels;
}

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  GetIt.instance<ThemeModeController>().selectMode(ThemeMode.light);
  await tester.pumpWidget(const NestlingApp(initialRoute: _route));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  group('K08 per-card semantics — the shape the fixes produced', () {
    testWidgets('each price is its own node, with no tap action', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await setUpTestScope();
      await _pump(tester);

      for (final price in <int>[50, 80, 60, 100, 150, 90]) {
        final node = find.bySemanticsLabel('$price coins');
        expect(node, findsOneWidget, reason: '$price coins');
        final data = tester.getSemantics(node).getSemanticsData();
        expect(
          data.hasAction(SemanticsAction.tap),
          isFalse,
          reason: 'a price is a reading, not a control',
        );
      }
      await disposeApp(tester);
      semantics.dispose();
    });

    testWidgets('each card button is its own node, labelled after the reward', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await setUpTestScope();
      await _pump(tester);

      // The out-of-reach card reports `enabled: false` and offers no action;
      // the other five must be operable.
      final expected = <String, bool>{
        for (final title in _titles)
          if (title == 'Trip to the park café')
            'Save up for $title': false
          else
            'Get $title': true,
      };
      for (final entry in expected.entries) {
        final node = find.bySemanticsLabel(entry.key);
        expect(node, findsOneWidget, reason: entry.key);
        final data = tester.getSemantics(node).getSemanticsData();
        expect(
          data.hasAction(SemanticsAction.tap),
          entry.value,
          reason: '${entry.key} tap action',
        );
        expect(data.flagsCollection.isButton, isTrue, reason: entry.key);
      }
      await disposeApp(tester);
      semantics.dispose();
    });

    testWidgets('the card button label never carries the price too', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await setUpTestScope();
      await _pump(tester);

      // Without the price's own `container: true` node, the label would merge
      // down the tree and one announcement would read "50, Get 30 min extra
      // screen time" — the whole reason the fix used `container`.
      expect(
        _labels(tester).where((l) => l.contains('coins') && l.contains('Get')),
        isEmpty,
        reason: 'no single announcement may mix a price and a button',
      );
      expect(find.bySemanticsLabel('50 coins'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Get 30 min extra screen time'),
        findsOneWidget,
      );
      await disposeApp(tester);
      semantics.dispose();
    });

    testWidgets('the balance and the heading are announced in the head row', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await setUpTestScope();
      await _pump(tester);

      // They are adjacent text in `.k8-head`, so they share one node — what
      // matters is that BOTH are announced, and that the pill is not a control.
      final head = _labels(tester)
          .where((l) => l.contains('Reward shop') && l.contains('120 coins'));
      expect(head, hasLength(1));
      expect(
        tester
            .getSemantics(find.byType(NestCoinPill))
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isFalse,
      );
      await disposeApp(tester);
      semantics.dispose();
    });
  });

  group('K08-BUG-5 — the reward names merge into one node', () {
    testWidgets('no announcement runs two rewards together', (tester) async {
      final semantics = tester.ensureSemantics();
      await setUpTestScope();
      await _pump(tester);

      // Today every card's name Text has no semantics container, so the grid
      // Column absorbs all six into one label and a screen-reader user hears
      // the whole shop as a single item — with no way to tell which name
      // belongs to which "50 coins" / "Get …" that follows.
      expect(
        _labels(tester)
            .where((label) => _titles.where(label.contains).length > 1),
        isEmpty,
        reason: 'one announcement must not read two different rewards',
      );
      await disposeApp(tester);
      semantics.dispose();
    });

    testWidgets('each title is announced on its own, exactly once', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await setUpTestScope();
      await _pump(tester);

      for (final title in _titles) {
        expect(
          find.bySemanticsLabel(title),
          findsOneWidget,
          reason: '"$title" must be its own announcement',
        );
      }
      await disposeApp(tester);
      semantics.dispose();
    });

    testWidgets('a card is one run: its name, price and action', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await setUpTestScope();
      await _pump(tester);

      // The strongest form of the rule: whatever node carries the name may not
      // carry another card's name, and each card's price and button stay
      // separately reachable.
      for (final label in _labels(tester)) {
        final named = _titles.where(label.contains).toList();
        expect(
          named.length,
          lessThanOrEqualTo(1),
          reason: '"$label" announces ${named.length} rewards at once',
        );
      }
      await disposeApp(tester);
      semantics.dispose();
    });
  });
}
