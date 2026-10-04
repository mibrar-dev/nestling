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

  // -------------------------------------------------------------------------
  // D1 + D2 (stage 5's ±2 px rule) — the tiles band and the caption sit on the
  // design's y, not 16.5 / 34 px below it.
  //
  // Design values are read from `design/screens/light/K01-profile-picker.png`
  // ÷3 as the first/last dark ink row of each element (anti-alias makes them
  // ±0.5):
  //   title ink  128.3…154.0   → line box 123…157 (28/34)
  //   sub ink    179.3…195.0   → line box 173…199 (18/26)
  //   tiles ink  289.0…648.7   → border box 288.5…648.5 (h 360)
  //   caption ink 742.3…755.3 + 762.3…772.7 → box 738…778 (two 20px lines)
  //
  // The arithmetic behind the fix, so a future regression explains itself:
  // the design's `.scroll` is `844 − 47 (--status-h) − 60 (.k1-top)
  // − 34 (--home-h) = 703` tall. `NestHomeIndicator` reserves nothing in the
  // running app (P01 BUG-2), so the picker carries `SizedBox(NestDevice.homeH)`
  // under the caption itself. Without that 34 px the `flex: 1` band centres
  // 17 px lower (half of it above, half below) and the caption 34 px lower.
  // -------------------------------------------------------------------------

  group('K01 — D1/D2: the vertical rhythm matches the design PNG', () {
    testWidgets('title and sub line boxes are the design boxes', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/who-is-playing');
      final title = tester.getRect(find.text("Who's playing?"));
      expect(title.top, closeTo(123, 2), reason: 'design line box 123…157');
      expect(title.bottom, closeTo(157, 2));
      expect(title.height, closeTo(34, 1), reason: '.kid-title is 28/34');

      final sub = tester.getRect(find.text('Tap your face to start'));
      expect(sub.top, closeTo(173, 2), reason: 'design line box 173…199');
      expect(sub.bottom, closeTo(199, 2));
      expect(sub.height, closeTo(26, 1), reason: '.kid-body is 18/26');
      await disposeApp(tester);
    });

    testWidgets('the tiles band sits at the design y (not +16.5)', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/who-is-playing');
      for (final key in const <ValueKey<String>>[
        ValueKey('k01-tile-maya'),
        ValueKey('k01-tile-leo'),
      ]) {
        final rect = tester.getRect(find.byKey(key));
        expect(
          rect.top,
          closeTo(288.5, 2),
          reason: '$key: the design draws the tile top border at 289.0',
        );
        expect(
          rect.bottom,
          closeTo(648.5, 2),
          reason: '$key: the design draws the tile bottom border at 648.7',
        );
        expect(
          rect.height,
          closeTo(360, 2),
          reason: '360 = 3+20+96+8+32+8+20+8+10+132+20+3 from .k1-tile',
        );
      }
      await disposeApp(tester);
    });

    testWidgets('the caption sits at the design y (not +34)', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/who-is-playing');
      final caption = tester.getRect(
        find.text('Grown-ups: tap the lock to get back to your dashboard.'),
      );
      expect(
        caption.top,
        closeTo(738, 2),
        reason: 'design line box 738…778 (ink 742.3 first row)',
      );
      expect(caption.bottom, closeTo(778, 2));
      expect(caption.height, closeTo(40, 1), reason: 'two 20px lines');
      await disposeApp(tester);
    });

    testWidgets('the gap below the caption is the design’s 32 + 34', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/who-is-playing');
      final caption = tester.getRect(
        find.text('Grown-ups: tap the lock to get back to your dashboard.'),
      );
      // `--s8` (32, `.scroll` padding-bottom) + `--home-h` (34).
      expect(
        844 - caption.bottom,
        closeTo(NestSpacing.s8 + NestDevice.homeH, 1),
        reason:
            'the design reserves 32 below the caption and 34 more for the '
            'home indicator; the in-app NestHomeIndicator reserves nothing, '
            'so the view owns that 34 (D1/D2 fix)',
      );
      await disposeApp(tester);
    });
  });
}
