// K01 · Who's playing? — design geometry at the design's real font metrics.
//
// Same isolation as `kid_home_geometry_test.dart`: loading the bundled
// faces changes every text metric on the screen, so the pinned layout
// lives in its own file and `flutter_test`'s default font elsewhere is
// unaffected.
//
// What is pinned here, from `design/screens/light/K01-profile-picker.png`
// ÷3 and `design/html-source/screens/K01-profile-picker.html`:
//
//   lock button        56×56, x 314…370, y 47…103, radius 18
//   title              top ≈123, centred horizontally
//   tiles row          two tiles, width (390−40−16)/2 = 167, gap 16,
//                      border 3 ink, radius 32, min-height 336
//   pet circle         132 diameter, centred in the tile,
//                      tinted lilac (Maya) / peach (Leo)
//   PipAvatar          112 inside the pet circle, centred
//
// Run it directly:
//   flutter test test/features/kid_home/k01_profile_picker_geometry_test.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';

import '../../test_scope.dart';

/// Loads the bundled faces so the metrics match a device run.
Future<void> loadBundledFonts() async {
  final inter = FontLoader('Inter')
    ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-Medium.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-SemiBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-Bold.ttf'));
  final nunito = FontLoader('Nunito')
    ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Nunito-ExtraBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf'));
  await inter.load();
  await nunito.load();
}

/// The pet-circle [Container] of a tile: a [BoxShape.circle] decoration
/// of exactly [diameter] (the tiled avatar's circle is 96/64 instead).
Container petCircleOf(
  WidgetTester tester, {
  required ValueKey<String> key,
  double diameter = 132,
}) {
  final candidates = find
      .descendant(
        of: find.byKey(key),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration! as BoxDecoration).shape == BoxShape.circle,
        ),
      )
      .evaluate();
  for (final element in candidates) {
    final size = tester.getSize(find.byWidget(element.widget));
    if ((size.width - diameter).abs() < 0.5) {
      return element.widget as Container;
    }
  }
  throw StateError('pet circle not found for $key');
}

void main() {
  setUpAll(loadBundledFonts);

  group('K01 — design geometry at 390×844 (real Inter/Nunito)', () {
    testWidgets('lock button is 56×56 at x 314, y 47', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/who-is-playing');
      final lock = tester.getRect(find.byType(NestLockButton));
      expect(lock.width, 56);
      expect(lock.height, 56);
      expect(lock.left, closeTo(314, 1), reason: 'x 314…370 per the design');
      expect(
        lock.top,
        closeTo(47, 1.5),
        reason: 'right under the 47px status bar',
      );
      await disposeApp(tester);
    });

    testWidgets('two tiles, 167 wide, 16 gap, border 3, radius 32', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/who-is-playing');
      final maya = tester.getRect(find.byKey(const ValueKey('k01-tile-maya')));
      final leo = tester.getRect(find.byKey(const ValueKey('k01-tile-leo')));
      expect(maya.width, closeTo(167, 1));
      expect(leo.width, closeTo(167, 1));
      expect(leo.left - maya.right, closeTo(16, 1), reason: '.k1-tiles gap 16');
      expect(maya.left, closeTo(20, 1), reason: '20 px side gutter');
      expect(leo.right, closeTo(370, 1), reason: '20 px side gutter');
      expect(maya.height, greaterThanOrEqualTo(336));
      expect(leo.height, greaterThanOrEqualTo(336));

      final borderColor = Theme.of(tester.element(find.text('Maya')))
          .extension<NestTokens>()!
          .ink;
      for (final key in const <ValueKey<String>>[
        ValueKey('k01-tile-maya'),
        ValueKey('k01-tile-leo'),
      ]) {
        final decoration =
            tester
                    .widget<Container>(
                      find
                          .descendant(
                            of: find.byKey(key),
                            matching: find.byWidgetPredicate(
                              (widget) =>
                                  widget is Container &&
                                  widget.decoration is BoxDecoration &&
                                  (widget.decoration! as BoxDecoration)
                                          .border !=
                                      null,
                            ),
                          )
                          .first,
                    )
                    .decoration!
                as BoxDecoration;
        final border = decoration.border! as Border;
        expect(border.top.width, 3, reason: '.k1-tile border: 3px solid ink');
        expect(border.top.color, borderColor);
        expect(
          decoration.borderRadius,
          BorderRadius.circular(32),
          reason: '--r-xl',
        );
      }
      await disposeApp(tester);
    });

    testWidgets('pet circles are 132 with Pip 112 centred inside', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/who-is-playing');

      for (final key in const <ValueKey<String>>[
        ValueKey('k01-tile-maya'),
        ValueKey('k01-tile-leo'),
      ]) {
        final circle = find.byWidget(petCircleOf(tester, key: key));
        final circleRect = tester.getRect(circle);
        expect(circleRect.width, closeTo(132, 0.5));
        expect(circleRect.height, closeTo(132, 0.5));
        final tile = tester.getRect(find.byKey(key));
        expect(
          circleRect.center.dx,
          closeTo(tile.center.dx, 1),
          reason: 'pet circle centred horizontally in the tile',
        );

        final pips = tester
            .widgetList<PipAvatar>(
              find.descendant(of: circle, matching: find.byType(PipAvatar)),
            )
            .toList();
        expect(pips, hasLength(1));
        expect(pips.single.size, 112);
        final pip = tester.getRect(
          find.descendant(of: circle, matching: find.byType(PipAvatar)),
        );
        expect(pip.width, closeTo(112, 1));
        expect(pip.height, closeTo(112, 1));
        expect(pip.center.dx, closeTo(circleRect.center.dx, 1));
        expect(pip.center.dy, closeTo(circleRect.center.dy, 1));
      }
      await disposeApp(tester);
    });

    testWidgets('pet circle tints follow the avatar (lilac / peach)', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/who-is-playing');
      final tokens = Theme.of(tester.element(find.text('Maya')))
          .extension<NestTokens>()!;

      Color petColor(String key) {
        final circle = petCircleOf(tester, key: ValueKey(key));
        return (circle.decoration! as BoxDecoration).color!;
      }

      expect(petColor('k01-tile-maya'), tokens.lilacTint);
      expect(petColor('k01-tile-leo'), tokens.peachTint);
      await disposeApp(tester);
    });
  });
}
