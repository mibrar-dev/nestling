import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';

import 'test_harness.dart';

void main() {
  group('NestButton', () {
    testWidgets('renders every variant in light and dark', (tester) async {
      await pumpBothModes(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NestButton(label: 'Primary', onPressed: () {}),
            NestButton(
              label: 'Secondary',
              variant: NestButtonVariant.secondary,
              onPressed: () {},
            ),
            NestButton(
              label: 'Ghost',
              variant: NestButtonVariant.ghost,
              onPressed: () {},
            ),
            NestButton(
              label: 'Danger',
              variant: NestButtonVariant.dangerGhost,
              onPressed: () {},
            ),
          ],
        ),
      );
    });

    testWidgets('meets the 52px pill geometry', (tester) async {
      await pumpNest(
        tester,
        NestButton(label: 'Get started', onPressed: () {}),
      );
      final size = tester.getSize(find.byType(NestButton));
      expect(size.height, greaterThanOrEqualTo(52));
      expect(size.width, 390);
    });

    testWidgets('tap, loading and disabled states', (tester) async {
      var tapped = 0;
      await pumpNest(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NestButton(label: 'Tap me', onPressed: () => tapped++),
            NestButton(label: 'Loading', loading: true, onPressed: () {}),
            const NestButton(label: 'Off'),
          ],
        ),
      );
      await tester.tap(find.text('Tap me'));
      expect(tapped, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.text('Off'), warnIfMissed: false);
      expect(tapped, 1);
    });

    testWidgets('no overflow at 320 wide and textScale 1.3', (tester) async {
      await pumpBothModes(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NestButton(
              label: 'A very long button label that must wrap, never clip',
              leading: const NestIcon(NestIcons.check),
              onPressed: () {},
            ),
            NestButton(
              label: 'Secondary',
              variant: NestButtonVariant.secondary,
              onPressed: () {},
            ),
          ],
        ),
        surface: const Size(320, 568),
        textScale: 1.3,
      );
    });
  });

  group('NestKidButton', () {
    testWidgets('renders every colour in light and dark', (tester) async {
      await pumpBothModes(
        tester,
        SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final color in NestKidButtonColor.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: NestKidButton(
                    label: color.name,
                    color: color,
                    onPressed: () {},
                  ),
                ),
            ],
          ),
        ),
      );
    });

    testWidgets('64px target and tap', (tester) async {
      var tapped = 0;
      await pumpNest(
        tester,
        NestKidButton(label: 'I did it!', onPressed: () => tapped++),
      );
      expect(
        tester.getSize(find.byType(NestKidButton)).height,
        greaterThanOrEqualTo(64),
      );
      await tester.tap(find.byType(NestKidButton));
      expect(tapped, 1);
    });

    testWidgets('disabled kid button ignores taps', (tester) async {
      const tapped = 0;
      await pumpNest(tester, const NestKidButton(label: 'Locked'));
      await tester.tap(find.byType(NestKidButton), warnIfMissed: false);
      expect(tapped, 0);
    });

    testWidgets('no overflow at 320 wide and textScale 1.3', (tester) async {
      await pumpBothModes(
        tester,
        NestKidButton(
          label: 'A very long kid label that wraps to two lines',
          color: NestKidButtonColor.coin,
          onPressed: () {},
        ),
        surface: const Size(320, 568),
        textScale: 1.3,
      );
    });
  });

  group('NestIconButton', () {
    testWidgets('44 circle in light and dark', (tester) async {
      await pumpBothModes(
        tester,
        NestIconButton(
          icon: NestIcons.plus,
          semanticLabel: 'Add',
          onPressed: () {},
        ),
      );
      expect(tester.getSize(find.byType(NestIconButton)), const Size(44, 44));
    });

    testWidgets('tap fires', (tester) async {
      var tapped = 0;
      await pumpNest(
        tester,
        NestIconButton(
          icon: NestIcons.plus,
          semanticLabel: 'Add',
          onPressed: () => tapped++,
        ),
      );
      await tester.tap(find.byType(NestIconButton));
      expect(tapped, 1);
    });
  });

  group('brand buttons', () {
    testWidgets('Apple and Google render light and dark', (tester) async {
      await pumpBothModes(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NestAppleButton(label: 'Continue with Apple', onPressed: () {}),
            const SizedBox(height: 12),
            NestGoogleButton(label: 'Continue with Google', onPressed: () {}),
          ],
        ),
      );
      expect(
        tester.getSize(find.byType(NestAppleButton)).height,
        greaterThanOrEqualTo(52),
      );
      expect(
        tester.getSize(find.byType(NestGoogleButton)).height,
        greaterThanOrEqualTo(52),
      );
    });

    testWidgets('no overflow at 320 wide and textScale 1.3', (tester) async {
      await pumpBothModes(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NestAppleButton(label: 'Continue with Apple', onPressed: () {}),
            const SizedBox(height: 12),
            NestGoogleButton(label: 'Continue with Google', onPressed: () {}),
          ],
        ),
        surface: const Size(320, 568),
        textScale: 1.3,
      );
    });
  });
}
