// Shared semantics tap-action regression tests.
//
// Every interactive design-system component must expose
// `SemanticsAction.tap` on the same node that announces its label, so
// VoiceOver/TalkBack double-tap activates it (WCAG 2.1 AA SC 4.1.2, 2.1.1).
// The bug was `Semantics(label, excludeSemantics: true)` wrapping an
// InkWell/GestureDetector: `excludeSemantics` drops every descendant
// contribution, INCLUDING the tap action. The fix mirrors the callback on
// the Semantics node (`onTap:`) while keeping the single-node announcement.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';

import '../../design_system/test_harness.dart';

Future<SemanticsHandle> pumpWithSemantics(
  WidgetTester tester,
  Widget child,
) async {
  await pumpNest(tester, child);
  final handle = tester.ensureSemantics();
  // The `find.semantics` tree populates on the next frame after enabling.
  await tester.pump();
  return handle;
}

/// The single semantics node announcing exactly [label].
SemanticsNode nodeByLabel(String label) =>
    find.semantics.byLabel(label).evaluate().single;

/// The single BUTTON node announcing exactly [label].
///
/// Components without `excludeSemantics` keep the inner `Text` node beside
/// the outer `Semantics(label)` node, so `byLabel` alone finds two. Only the
/// outer carries `isButton`, which makes it unique.
SemanticsNode buttonNode(String label) => find.semantics
    .byPredicate(
      (n) => n.label == label && n.getSemanticsData().flagsCollection.isButton,
    )
    .evaluate()
    .single;

/// The single node whose label contains [part] (disabled controls merge the
/// outer label with inner text, e.g. `Decrease\n-`, so exact match fails).
SemanticsNode containingNode(String part) =>
    find.semantics.byPredicate((n) => n.label.contains(part)).evaluate().single;

FinderBase<SemanticsNode> buttonFinder(String label) =>
    find.semantics.byPredicate(
      (n) => n.label == label && n.getSemanticsData().flagsCollection.isButton,
    );

FinderBase<SemanticsNode> containingFinder(String part) =>
    find.semantics.byPredicate((n) => n.label.contains(part));

void main() {
  group('NestButton', () {
    testWidgets('enabled exposes tap and performAction presses once', (
      tester,
    ) async {
      var calls = 0;
      final handle = await pumpWithSemantics(
        tester,
        NestButton(label: 'Continue', onPressed: () => calls++),
      );
      final node = tester.getSemantics(find.byType(NestButton));
      final data = node.getSemanticsData();
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      expect(data.flagsCollection.isEnabled.toBoolOrNull(), isTrue);
      tester.semantics.performAction(
        find.semantics.byLabel('Continue'),
        SemanticsAction.tap,
      );
      await tester.pump();
      expect(calls, 1);
      handle.dispose();
    });

    testWidgets('disabled exposes no tap and reports disabled', (tester) async {
      final handle = await pumpWithSemantics(
        tester,
        const NestButton(label: 'Continue'),
      );
      final data = tester
          .getSemantics(find.byType(NestButton))
          .getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      expect(data.flagsCollection.isEnabled.toBoolOrNull(), isFalse);
      handle.dispose();
    });
  });

  group('NestKidButton', () {
    testWidgets('enabled exposes tap and performAction presses once', (
      tester,
    ) async {
      var calls = 0;
      final handle = await pumpWithSemantics(
        tester,
        NestKidButton(label: 'Go', onPressed: () => calls++),
      );
      final data = tester
          .getSemantics(find.byType(NestKidButton))
          .getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      expect(data.flagsCollection.isEnabled.toBoolOrNull(), isTrue);
      tester.semantics.performAction(
        find.semantics.byLabel('Go'),
        SemanticsAction.tap,
      );
      await tester.pump();
      expect(calls, 1);
      handle.dispose();
    });

    testWidgets('disabled exposes no tap and reports disabled', (tester) async {
      final handle = await pumpWithSemantics(
        tester,
        const NestKidButton(label: 'Go'),
      );
      final data = tester
          .getSemantics(find.byType(NestKidButton))
          .getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      expect(data.flagsCollection.isEnabled.toBoolOrNull(), isFalse);
      handle.dispose();
    });
  });

  group('brand buttons', () {
    testWidgets('NestAppleButton enabled exposes tap', (tester) async {
      var calls = 0;
      final handle = await pumpWithSemantics(
        tester,
        NestAppleButton(label: 'Continue with Apple', onPressed: () => calls++),
      );
      final data = tester
          .getSemantics(find.byType(NestAppleButton))
          .getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      expect(data.flagsCollection.isEnabled.toBoolOrNull(), isTrue);
      tester.semantics.performAction(
        find.semantics.byLabel('Continue with Apple'),
        SemanticsAction.tap,
      );
      await tester.pump();
      expect(calls, 1);
      handle.dispose();
    });

    testWidgets('NestAppleButton disabled exposes no tap', (tester) async {
      final handle = await pumpWithSemantics(
        tester,
        const NestAppleButton(label: 'Continue with Apple'),
      );
      final data = tester
          .getSemantics(find.byType(NestAppleButton))
          .getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      expect(data.flagsCollection.isEnabled.toBoolOrNull(), isFalse);
      handle.dispose();
    });

    testWidgets('NestGoogleButton enabled exposes tap', (tester) async {
      var calls = 0;
      final handle = await pumpWithSemantics(
        tester,
        NestGoogleButton(
          label: 'Continue with Google',
          onPressed: () => calls++,
        ),
      );
      final data = tester
          .getSemantics(find.byType(NestGoogleButton))
          .getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      expect(data.flagsCollection.isEnabled.toBoolOrNull(), isTrue);
      tester.semantics.performAction(
        find.semantics.byLabel('Continue with Google'),
        SemanticsAction.tap,
      );
      await tester.pump();
      expect(calls, 1);
      handle.dispose();
    });

    testWidgets('NestGoogleButton disabled exposes no tap', (tester) async {
      final handle = await pumpWithSemantics(
        tester,
        const NestGoogleButton(label: 'Continue with Google'),
      );
      final data = tester
          .getSemantics(find.byType(NestGoogleButton))
          .getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      expect(data.flagsCollection.isEnabled.toBoolOrNull(), isFalse);
      handle.dispose();
    });
  });

  group('NestChip', () {
    testWidgets('enabled exposes tap and toggles via performAction', (
      tester,
    ) async {
      final selected = <bool>[];
      final handle = await pumpWithSemantics(
        tester,
        NestChip(label: '7-9', onSelected: selected.add),
      );
      // `excludeSemantics` keeps one node: the inner text is excluded.
      final data = nodeByLabel('7-9').getSemanticsData();
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      tester.semantics.performAction(
        find.semantics.byLabel('7-9'),
        SemanticsAction.tap,
      );
      await tester.pump();
      expect(selected, [true]);
      handle.dispose();
    });

    testWidgets('static chip exposes no tap action', (tester) async {
      final handle = await pumpWithSemantics(
        tester,
        const NestChip(label: '7-9'),
      );
      final data = tester
          .getSemantics(find.byType(NestChip))
          .getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      handle.dispose();
    });

    testWidgets('chip in NestChipWrap exposes tap', (tester) async {
      final selected = <String>[];
      final handle = await pumpWithSemantics(
        tester,
        NestChipWrap(
          spacing: NestSpacing.s2,
          runSpacing: NestSpacing.s2,
          children: [
            NestChip(
              key: const ValueKey('chip-a'),
              label: 'A',
              onSelected: (_) => selected.add('A'),
            ),
          ],
        ),
      );
      expect(
        nodeByLabel('A').getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );
      tester.semantics.performAction(
        find.semantics.byLabel('A'),
        SemanticsAction.tap,
      );
      await tester.pump();
      expect(selected, ['A']);
      handle.dispose();
    });
  });

  group('NestToggle', () {
    testWidgets('enabled exposes tap and flips via performAction', (
      tester,
    ) async {
      final values = <bool>[];
      final handle = await pumpWithSemantics(
        tester,
        NestToggle(
          value: false,
          onChanged: values.add,
          semanticLabel: 'Share reports',
        ),
      );
      // No inner labelled text: `byLabel` is unique (no button flag to need).
      final data = nodeByLabel('Share reports').getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      expect(data.flagsCollection.isEnabled.toBoolOrNull(), isTrue);
      tester.semantics.performAction(
        find.semantics.byLabel('Share reports'),
        SemanticsAction.tap,
      );
      await tester.pump();
      expect(values, [true]);
      handle.dispose();
    });

    testWidgets('disabled exposes no tap and reports disabled', (tester) async {
      final handle = await pumpWithSemantics(
        tester,
        const NestToggle(
          value: false,
          onChanged: null,
          semanticLabel: 'Share reports',
        ),
      );
      // Disabled merges nothing (no inner text): label stays exact.
      final data = nodeByLabel('Share reports').getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      expect(data.flagsCollection.isEnabled.toBoolOrNull(), isFalse);
      handle.dispose();
    });
  });

  group('NestStepper', () {
    testWidgets('enabled buttons expose tap and fire once', (tester) async {
      var dec = 0;
      var inc = 0;
      final handle = await pumpWithSemantics(
        tester,
        NestStepper(
          valueText: '3',
          onDecrease: () => dec++,
          onIncrease: () => inc++,
        ),
      );
      // Inner `-`/`+` labels differ from the outer, so `byLabel` is unique.
      expect(
        nodeByLabel('Decrease')
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
      expect(
        nodeByLabel('Increase')
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
      tester.semantics.performAction(
        find.semantics.byLabel('Decrease'),
        SemanticsAction.tap,
      );
      await tester.pump();
      expect(dec, 1);
      tester.semantics.performAction(
        find.semantics.byLabel('Increase'),
        SemanticsAction.tap,
      );
      await tester.pump();
      expect(inc, 1);
      handle.dispose();
    });

    testWidgets('disabled buttons expose no tap', (tester) async {
      final handle = await pumpWithSemantics(
        tester,
        const NestStepper(valueText: '3'),
      );
      // Disabled merges outer + inner (`Decrease\n-`): match by containment.
      final decData = containingNode('Decrease').getSemanticsData();
      final incData = containingNode('Increase').getSemanticsData();
      expect(decData.hasAction(SemanticsAction.tap), isFalse);
      expect(incData.hasAction(SemanticsAction.tap), isFalse);
      expect(decData.flagsCollection.isEnabled.toBoolOrNull(), isFalse);
      expect(incData.flagsCollection.isEnabled.toBoolOrNull(), isFalse);
      handle.dispose();
    });
  });

  group('NestSegmented', () {
    testWidgets('enabled options expose tap and select', (tester) async {
      String? picked;
      final handle = await pumpWithSemantics(
        tester,
        NestSegmented<String>(
          options: const [
            NestSegmentOption(value: 'a', label: 'Seg A'),
            NestSegmentOption(value: 'b', label: 'Seg B'),
          ],
          value: 'a',
          onChanged: (v) => picked = v,
        ),
      );
      // `excludeSemantics` keeps one node per option: the inner Text and
      // InkWell contribute no second copy (same as NestChip).
      expect(
        nodeByLabel('Seg B').getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );
      tester.semantics.performAction(
        find.semantics.byLabel('Seg B'),
        SemanticsAction.tap,
      );
      await tester.pump();
      expect(picked, 'b');
      handle.dispose();
    });

    testWidgets('each option announces once with tap and selection', (
      tester,
    ) async {
      var value = 'active';
      final handle = await pumpWithSemantics(
        tester,
        StatefulBuilder(
          builder: (context, setState) => NestSegmented<String>(
            options: const [
              NestSegmentOption(value: 'active', label: 'Active'),
              NestSegmentOption(value: 'ideas', label: 'Ideas'),
            ],
            value: value,
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      );
      // One addressable node per option: no double announcement.
      expect(find.bySemanticsLabel('Ideas'), findsOneWidget);
      final before = nodeByLabel('Ideas').getSemanticsData();
      expect(before.flagsCollection.isButton, isTrue);
      expect(before.hasAction(SemanticsAction.tap), isTrue);
      expect(
        before.flagsCollection.isSelected.toBoolOrNull(),
        isFalse,
        reason: 'Ideas starts unselected',
      );
      tester.semantics.performAction(
        find.semantics.byLabel('Ideas'),
        SemanticsAction.tap,
      );
      await tester.pump();
      // The tap action drives the real selection state.
      expect(
        nodeByLabel('Ideas')
            .getSemanticsData()
            .flagsCollection
            .isSelected
            .toBoolOrNull(),
        isTrue,
      );
      expect(
        nodeByLabel('Active')
            .getSemanticsData()
            .flagsCollection
            .isSelected
            .toBoolOrNull(),
        isFalse,
      );
      handle.dispose();
    });

    testWidgets('disabled options expose no tap', (tester) async {
      final handle = await pumpWithSemantics(
        tester,
        const NestSegmented<String>(
          options: [
            NestSegmentOption(value: 'a', label: 'Seg A'),
            NestSegmentOption(value: 'b', label: 'Seg B'),
          ],
          value: 'a',
          onChanged: null,
        ),
      );
      // `excludeSemantics` still keeps one node: the label stays exact.
      final data = nodeByLabel('Seg B').getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      expect(data.flagsCollection.isEnabled.toBoolOrNull(), isFalse);
      handle.dispose();
    });
  });

  group('NestTabBar', () {
    const items = [
      NestTabItem(label: 'Today', icon: NestIcons.home),
      NestTabItem(label: 'Quests', icon: NestIcons.quests),
      NestTabItem(label: 'Money', icon: NestIcons.money),
      NestTabItem(label: 'Family', icon: NestIcons.family),
    ];

    testWidgets('tabs expose tap and report selection', (tester) async {
      var tapped = -1;
      final handle = await pumpWithSemantics(
        tester,
        NestTabBar(items: items, currentIndex: 0, onTap: (i) => tapped = i),
      );
      expect(
        buttonNode('Quests').getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );
      tester.semantics.performAction(
        buttonFinder('Quests'),
        SemanticsAction.tap,
      );
      await tester.pump();
      expect(tapped, 1);
      handle.dispose();
    });
  });

  group('NestListRow', () {
    testWidgets('tappable row exposes tap and fires once', (tester) async {
      var calls = 0;
      final handle = await pumpWithSemantics(
        tester,
        NestListRow(title: 'RowTap', onTap: () => calls++),
      );
      expect(
        buttonNode('RowTap').getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );
      tester.semantics.performAction(
        buttonFinder('RowTap'),
        SemanticsAction.tap,
      );
      await tester.pump();
      expect(calls, 1);
      handle.dispose();
    });

    testWidgets('static row exposes no tap', (tester) async {
      final handle = await pumpWithSemantics(
        tester,
        const NestListRow(title: 'RowStatic'),
      );
      final data = tester
          .getSemantics(find.byType(NestListRow))
          .getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      handle.dispose();
    });
  });

  group('NestQuestCard', () {
    testWidgets('tappable card exposes tap and fires once', (tester) async {
      var calls = 0;
      final handle = await pumpWithSemantics(
        tester,
        NestQuestCard(title: 'Tidy up', onTap: () => calls++),
      );
      // No check: `excludeSemantics` keeps one node.
      expect(
        nodeByLabel('Tidy up')
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
      tester.semantics.performAction(
        find.semantics.byLabel('Tidy up'),
        SemanticsAction.tap,
      );
      await tester.pump();
      expect(calls, 1);
      handle.dispose();
    });

    testWidgets('parent check exposes tap and toggles', (tester) async {
      final toggled = <bool>[];
      final handle = await pumpWithSemantics(
        tester,
        NestQuestCard(title: 'Tidy up', done: false, onToggled: toggled.add),
      );
      // Card has no onTap so title + check merge: match by containment.
      final finder = containingFinder('Mark done');
      expect(
        finder.evaluate().single.getSemanticsData().hasAction(
          SemanticsAction.tap,
        ),
        isTrue,
      );
      tester.semantics.performAction(finder, SemanticsAction.tap);
      await tester.pump();
      expect(toggled, [true]);
      handle.dispose();
    });

    testWidgets('disabled parent check exposes no tap', (tester) async {
      final handle = await pumpWithSemantics(
        tester,
        const NestQuestCard(title: 'Tidy up', done: false),
      );
      final data = containingNode('Mark done').getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      expect(data.flagsCollection.isEnabled.toBoolOrNull(), isFalse);
      handle.dispose();
    });
  });

  group('NestKidQuestCard', () {
    testWidgets('tappable card exposes tap and fires once', (tester) async {
      var calls = 0;
      final handle = await pumpWithSemantics(
        tester,
        NestKidQuestCard(title: 'Kid tidy', onTap: () => calls++),
      );
      // Display-only check is excluded: one node for the card.
      expect(
        nodeByLabel('Kid tidy')
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
      tester.semantics.performAction(
        find.semantics.byLabel('Kid tidy'),
        SemanticsAction.tap,
      );
      await tester.pump();
      expect(calls, 1);
      handle.dispose();
    });

    testWidgets('kid check exposes tap and toggles', (tester) async {
      final toggled = <bool>[];
      final handle = await pumpWithSemantics(
        tester,
        NestKidQuestCard(title: 'Kid tidy', onToggled: toggled.add),
      );
      // Card has no onTap so title + check merge: match by containment.
      final finder = containingFinder('Mark done');
      expect(
        finder.evaluate().single.getSemanticsData().hasAction(
          SemanticsAction.tap,
        ),
        isTrue,
      );
      tester.semantics.performAction(finder, SemanticsAction.tap);
      await tester.pump();
      expect(toggled, [true]);
      handle.dispose();
    });

    testWidgets('disabled kid check exposes no tap', (tester) async {
      final handle = await pumpWithSemantics(
        tester,
        const NestKidQuestCard(title: 'Kid tidy'),
      );
      final data = containingNode('Mark done').getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      expect(data.flagsCollection.isEnabled.toBoolOrNull(), isFalse);
      handle.dispose();
    });
  });

  group('NestKeypad (parental gate)', () {
    testWidgets('digit and delete expose tap and fire once', (tester) async {
      final keys = <String>[];
      var deletes = 0;
      final handle = await pumpWithSemantics(
        tester,
        NestKeypad(onKey: keys.add, onDelete: () => deletes++),
      );
      expect(
        nodeByLabel('Digit 1')
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
      tester.semantics.performAction(
        find.semantics.byLabel('Digit 1'),
        SemanticsAction.tap,
      );
      await tester.pump();
      expect(keys, ['1']);
      expect(
        nodeByLabel('Delete').getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );
      tester.semantics.performAction(
        find.semantics.byLabel('Delete'),
        SemanticsAction.tap,
      );
      await tester.pump();
      expect(deletes, 1);
      handle.dispose();
    });
  });

  group('NestDayPicker', () {
    testWidgets('day cells expose tap and fire with index', (tester) async {
      final picked = <int>[];
      final handle = await pumpWithSemantics(
        tester,
        NestDayPicker(
          days: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
          selected: const {},
          onChanged: picked.add,
        ),
      );
      // Outer `Day Mon` differs from inner `Mon`: exact match is unique.
      expect(
        nodeByLabel('Day Mon')
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
      tester.semantics.performAction(
        find.semantics.byLabel('Day Mon'),
        SemanticsAction.tap,
      );
      await tester.pump();
      expect(picked, [0]);
      handle.dispose();
    });
  });

  group('NestCard', () {
    testWidgets('tappable labelled card exposes tap and fires once', (
      tester,
    ) async {
      var calls = 0;
      final handle = await pumpWithSemantics(
        tester,
        NestCard(
          onTap: () => calls++,
          semanticLabel: 'Maya card',
          child: const Text('Maya'),
        ),
      );
      expect(
        nodeByLabel('Maya card')
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
      tester.semantics.performAction(
        find.semantics.byLabel('Maya card'),
        SemanticsAction.tap,
      );
      await tester.pump();
      expect(calls, 1);
      handle.dispose();
    });

    testWidgets('static card exposes no tap', (tester) async {
      final handle = await pumpWithSemantics(
        tester,
        const NestCard(child: Text('Maya')),
      );
      final data = tester
          .getSemantics(find.byType(NestCard))
          .getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      handle.dispose();
    });
  });

  group('NestIconButton', () {
    testWidgets('enabled exposes tap and fires once', (tester) async {
      var calls = 0;
      final handle = await pumpWithSemantics(
        tester,
        NestIconButton(
          icon: NestIcons.close,
          semanticLabel: 'CloseBtn',
          onPressed: () => calls++,
        ),
      );
      // Inner icon carries no label: `byLabel` is the outer button.
      final data = nodeByLabel('CloseBtn').getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      expect(data.flagsCollection.isEnabled.toBoolOrNull(), isTrue);
      tester.semantics.performAction(
        find.semantics.byLabel('CloseBtn'),
        SemanticsAction.tap,
      );
      await tester.pump();
      expect(calls, 1);
      handle.dispose();
    });

    testWidgets('disabled exposes no tap', (tester) async {
      final handle = await pumpWithSemantics(
        tester,
        const NestIconButton(icon: NestIcons.close, semanticLabel: 'CloseBtn'),
      );
      final data = nodeByLabel('CloseBtn').getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      expect(data.flagsCollection.isEnabled.toBoolOrNull(), isFalse);
      handle.dispose();
    });
  });

  group('NestFab', () {
    testWidgets('exposes tap and fires once', (tester) async {
      var calls = 0;
      final handle = await pumpWithSemantics(
        tester,
        NestFab(
          label: 'AddFab',
          icon: NestIcons.plus,
          onPressed: () => calls++,
        ),
      );
      // Inner Text duplicates the label: the button node is the outer.
      expect(
        buttonNode('AddFab').getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );
      tester.semantics.performAction(
        buttonFinder('AddFab'),
        SemanticsAction.tap,
      );
      await tester.pump();
      expect(calls, 1);
      handle.dispose();
    });
  });

  group('NestLockButton', () {
    testWidgets('exposes tap and fires once', (tester) async {
      var calls = 0;
      final handle = await pumpWithSemantics(
        tester,
        NestLockButton(onPressed: () => calls++),
      );
      expect(
        nodeByLabel('Grown-ups only')
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
      tester.semantics.performAction(
        find.semantics.byLabel('Grown-ups only'),
        SemanticsAction.tap,
      );
      await tester.pump();
      expect(calls, 1);
      handle.dispose();
    });
  });

  group('NestNavBar', () {
    testWidgets('back exposes tap and fires once', (tester) async {
      var calls = 0;
      final handle = await pumpWithSemantics(
        tester,
        NestNavBar(title: 'T', onBack: () => calls++),
      );
      expect(
        nodeByLabel('Back').getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );
      tester.semantics.performAction(
        find.semantics.byLabel('Back'),
        SemanticsAction.tap,
      );
      await tester.pump();
      expect(calls, 1);
      handle.dispose();
    });

    testWidgets('text action exposes tap and disabled exposes none', (
      tester,
    ) async {
      var calls = 0;
      var handle = await pumpWithSemantics(
        tester,
        NestNavBar(compact: true, actionLabel: 'Skip', onAction: () => calls++),
      );
      // Inner text is `ExcludeSemantics`: one node.
      expect(
        nodeByLabel('Skip').getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );
      expect(
        nodeByLabel('Skip')
            .getSemanticsData()
            .flagsCollection
            .isEnabled
            .toBoolOrNull(),
        isTrue,
      );
      tester.semantics.performAction(
        find.semantics.byLabel('Skip'),
        SemanticsAction.tap,
      );
      await tester.pump();
      expect(calls, 1);
      handle.dispose();

      handle = await pumpWithSemantics(
        tester,
        const NestNavBar(compact: true, actionLabel: 'Skip'),
      );
      final data = nodeByLabel('Skip').getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      expect(data.flagsCollection.isEnabled.toBoolOrNull(), isFalse);
      handle.dispose();
    });
  });

  group('NestBottomSheet close', () {
    testWidgets('close exposes tap and fires once', (tester) async {
      var calls = 0;
      final handle = await pumpWithSemantics(
        tester,
        NestBottomSheet(
          title: 'SheetT',
          onClose: () => calls++,
          child: const Text('x'),
        ),
      );
      expect(
        nodeByLabel('Close').getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );
      tester.semantics.performAction(
        find.semantics.byLabel('Close'),
        SemanticsAction.tap,
      );
      await tester.pump();
      expect(calls, 1);
      handle.dispose();
    });
  });

  group('NestPagerDots', () {
    testWidgets('dots expose tap and fire with index', (tester) async {
      final tapped = <int>[];
      final handle = await pumpWithSemantics(
        tester,
        NestPagerDots(count: 3, index: 0, onDotTapped: tapped.add),
      );
      // `excludeSemantics` keeps one node per dot.
      expect(
        nodeByLabel('Go to page 2')
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
      tester.semantics.performAction(
        find.semantics.byLabel('Go to page 2'),
        SemanticsAction.tap,
      );
      await tester.pump();
      expect(tapped, [1]);
      handle.dispose();
    });

    testWidgets('without handler exposes no tap', (tester) async {
      final handle = await pumpWithSemantics(
        tester,
        const NestPagerDots(count: 3, index: 0),
      );
      final data = tester
          .getSemantics(find.byType(NestPagerDots))
          .getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      handle.dispose();
    });
  });

  group('NestTextField password affordance', () {
    testWidgets('eye button exposes tap and toggles obscuring', (tester) async {
      final handle = await pumpWithSemantics(
        tester,
        const NestTextField(label: 'Password', obscureText: true),
      );
      // IconButton tooltip lands on `tooltip`, not `label`.
      final finder = find.semantics.byPredicate(
        (n) => n.tooltip == 'Show password',
      );
      expect(
        finder.evaluate().single.getSemanticsData().hasAction(
          SemanticsAction.tap,
        ),
        isTrue,
      );
      tester.semantics.performAction(finder, SemanticsAction.tap);
      await tester.pump();
      expect(
        find.semantics.byPredicate((n) => n.tooltip == 'Hide password'),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('shared/ds_cleanup — one control, one node', () {
    testWidgets('interactive NestListRow is exactly one labelled tap node', (
      tester,
    ) async {
      var calls = 0;
      final handle = await pumpWithSemantics(
        tester,
        NestListRow(
          title: 'Invite co-parent',
          subtitle: 'Share the load',
          onTap: () => calls++,
        ),
      );
      // The subtitle folds into the outer label; the inner InkWell/Text
      // contribute no second node.
      expect(
        find.bySemanticsLabel('Invite co-parent, Share the load'),
        findsOneWidget,
      );
      final data = nodeByLabel('Invite co-parent, Share the load')
          .getSemanticsData();
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      tester.semantics.performAction(
        find.semantics.byLabel('Invite co-parent, Share the load'),
        SemanticsAction.tap,
      );
      await tester.pump();
      expect(calls, 1);
      handle.dispose();
    });

    testWidgets('static NestListRows do not merge into the next button', (
      tester,
    ) async {
      final handle = await pumpWithSemantics(
        tester,
        NestList(
          children: <Widget>[
            const NestListRow(title: 'Sarah — you'),
            const NestListRow(title: 'James — co-parent'),
            NestListRow(title: 'Invite co-parent', onTap: () {}),
          ],
        ),
      );
      // Static rows are containers with no tap; the button keeps its tap.
      // Walk the tree: no tappable node may carry static copy.
      final views = tester.binding.renderViews;
      final root = views.first.owner?.semanticsOwner?.rootSemanticsNode;
      final tappable = <SemanticsNode>[];
      void visit(SemanticsNode node) {
        if (node.getSemanticsData().hasAction(SemanticsAction.tap)) {
          tappable.add(node);
        }
        node.visitChildren((child) {
          visit(child);
          return true;
        });
      }

      visit(root!);
      for (final node in tappable) {
        expect(
          node.getSemanticsData().label,
          isNot(contains('Sarah — you')),
          reason: 'static row must not fold into a button',
        );
      }

      handle.dispose();
    });

    testWidgets('NestToggle is one labelled node, no unlabelled tap node', (
      tester,
    ) async {
      final values = <bool>[];
      final handle = await pumpWithSemantics(
        tester,
        NestToggle(
          value: false,
          onChanged: values.add,
          semanticLabel: 'Approvals waiting notifications',
        ),
      );
      expect(
        find.semantics.byLabel('Approvals waiting notifications'),
        findsOneWidget,
        reason: 'exactly one node announces the switch',
      );
      final views = tester.binding.renderViews;
      final root = views.first.owner?.semanticsOwner?.rootSemanticsNode;
      final anonymous = <SemanticsNode>[];
      void visit(SemanticsNode node) {
        final data = node.getSemanticsData();
        if (data.hasAction(SemanticsAction.tap) && data.label.trim().isEmpty) {
          anonymous.add(node);
        }
        node.visitChildren((child) {
          visit(child);
          return true;
        });
      }

      visit(root!);
      expect(anonymous, isEmpty, reason: 'the detector contributes no node');
      tester.semantics.performAction(
        find.semantics.byLabel('Approvals waiting notifications'),
        SemanticsAction.tap,
      );
      await tester.pump();
      expect(values, [true]);
      handle.dispose();
    });
  });
}
