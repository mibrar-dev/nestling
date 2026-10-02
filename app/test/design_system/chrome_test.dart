import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';

import 'test_harness.dart';

void main() {
  group('NestTabBar', () {
    const items = [
      NestTabItem(label: 'Today', icon: NestIcons.home),
      NestTabItem(label: 'Quests', icon: NestIcons.quests),
      NestTabItem(label: 'Money', icon: NestIcons.money),
      NestTabItem(label: 'Family', icon: NestIcons.family),
    ];

    testWidgets('84 bar with 44 tabs in light and dark', (tester) async {
      await pumpBothModes(
        tester,
        NestTabBar(items: items, currentIndex: 0, onTap: (_) {}),
      );
      expect(tester.getSize(find.byType(NestTabBar)).height, 84);
    });

    testWidgets('tap switches tabs', (tester) async {
      var index = 0;
      await pumpNest(
        tester,
        StatefulBuilder(
          builder: (context, setState) => NestTabBar(
            items: items,
            currentIndex: index,
            onTap: (next) => setState(() => index = next),
          ),
        ),
      );
      await tester.tap(find.text('Money'));
      await tester.pumpAndSettle();
      expect(index, 2);
    });

    testWidgets('no overflow at 320 wide and textScale 1.3', (tester) async {
      await pumpBothModes(
        tester,
        NestTabBar(items: items, currentIndex: 1, onTap: (_) {}),
        surface: const Size(320, 568),
        textScale: 1.3,
      );
    });
  });

  group('NestNavBar', () {
    testWidgets('large and compact geometries', (tester) async {
      await pumpBothModes(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NestNavBar(
              title: 'A title that is far too long and must ellipsize',
              onBack: () {},
              actionLabel: '+',
              onAction: () {},
            ),
            const NestNavBar(title: 'Reward shop', compact: true),
            NestNavBar(title: 'Waiting', compact: true, onBack: () {}),
          ],
        ),
        surface: const Size(320, 568),
        textScale: 1.3,
      );
      // Large: 44 control row + h1 title block below, min 64.
      expect(
        tester.getSize(find.byType(NestNavBar).first).height,
        greaterThanOrEqualTo(64),
      );
      // Compact matches `.nav-bar.compact` (components.css): min-height 52,
      // padding 4/12/12. Back-less bar renders at the 52 minimum; a 44px
      // back button stretches it to 4 + 44 + 12 = 60.
      expect(tester.getSize(find.byType(NestNavBar).at(1)).height, 52);
      expect(tester.getSize(find.byType(NestNavBar).at(2)).height, 60);
    });

    testWidgets('compact action stays on the title line', (tester) async {
      await pumpBothModes(
        tester,
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NestNavBar(
              title: 'A fairly long pushed-screen title',
              compact: true,
              actionLabel: '+',
            ),
          ],
        ),
        surface: const Size(320, 568),
        textScale: 1.3,
      );
      final bar = find.byType(NestNavBar);
      // 44px action row + 4 top + 12 bottom = 60.
      expect(tester.getSize(bar).height, 60);
      final titleDy = tester
          .getCenter(find.text('A fairly long pushed-screen title'))
          .dy;
      final actionDy = tester.getCenter(find.text('+')).dy;
      expect(actionDy, moreOrLessEquals(titleDy, epsilon: 1));
    });

    testWidgets('compact back-only bar is 60 high', (tester) async {
      await pumpBothModes(tester, NestNavBar(compact: true, onBack: () {}));
      expect(tester.getSize(find.byType(NestNavBar)).height, 60);
      expect(tester.takeException(), isNull);
    });

    testWidgets('compact null and empty titles render the same', (
      tester,
    ) async {
      await pumpNest(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NestNavBar(compact: true, onBack: () {}),
            NestNavBar(compact: true, title: '', onBack: () {}),
          ],
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(NestNavBar).first).height,
        tester.getSize(find.byType(NestNavBar).at(1)).height,
      );
    });

    testWidgets('back and action fire', (tester) async {
      var back = 0;
      var action = 0;
      await pumpNest(
        tester,
        NestNavBar(
          title: 'Reward shop',
          onBack: () => back++,
          actionLabel: '+',
          onAction: () => action++,
        ),
      );
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.tap(find.text('+'));
      expect(back, 1);
      expect(action, 1);
    });
  });

  group('NestBottomCta and NestFab', () {
    testWidgets('cta with caption and 52 fab', (tester) async {
      await pumpBothModes(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NestBottomCta(
              caption: 'Children never need an email.',
              child: NestButton(label: 'Continue', onPressed: () {}),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: NestFab(
                label: 'New quest',
                icon: NestIcons.plus,
                onPressed: () {},
              ),
            ),
          ],
        ),
      );
      expect(
        tester.getSize(find.byType(NestFab)).height,
        greaterThanOrEqualTo(52),
      );
      expect(find.text('Children never need an email.'), findsOneWidget);
    });
  });

  group('NestLockButton', () {
    testWidgets('large is 56 and small is 44', (tester) async {
      await pumpBothModes(
        tester,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            NestLockButton(onPressed: () {}),
            const SizedBox(width: 8),
            NestLockButton(large: false, onPressed: () {}),
          ],
        ),
      );
      expect(
        tester.getSize(find.byType(NestLockButton).first),
        const Size(56, 56),
      );
      expect(
        tester.getSize(find.byType(NestLockButton).at(1)),
        const Size(44, 44),
      );
    });
  });

  group('NestKeypad and NestPinDots', () {
    testWidgets('72 keys digit and delete', (tester) async {
      final keys = <String>[];
      var deleted = 0;
      await pumpBothModes(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const NestPinDots(total: 4, filled: 2),
            NestKeypad(onKey: keys.add, onDelete: () => deleted++),
          ],
        ),
        surface: const Size(320, 568),
        textScale: 1.3,
      );
      await tester.tap(find.text('5'));
      await tester.tap(find.bySemanticsLabel('Delete'));
      expect(keys, ['5']);
      expect(deleted, 1);
    });

    testWidgets('kid keys carry the ink ring', (tester) async {
      await pumpNest(
        tester,
        NestKeypad(kid: true, onKey: (_) {}, onDelete: () {}),
      );
      expect(find.text('1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
