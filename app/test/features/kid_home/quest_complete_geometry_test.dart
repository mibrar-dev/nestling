// K05 quest-complete geometry: every painted rect compared with
// `design/screens/light/K05-quest-complete.png` ÷3 (1170×2532 @3x).
//
// Measured design values this file pins (logical px, 390×844):
//
//   `.status-bar`     y   0… 47  (reserved; the OS draws the glyphs)
//   `.k5-top`         y  47…105  lock 56×56 @ x 314…370
//   `.burst`          320×200 plate @ x 35…355 (absolute, `top: 0`)
//   `.k5-pip`         218×218 @ x 86…304, y 119…337, `rotate(-8deg)`
//   `h1.kid-hero`     y 343…387  ink 348.33…385.33 (40/44, margin-top 4)
//   `.coin-pill.big`  x 121…268.67, y 403…442.67  (147.67×40)
//   `.k5-sub`         y 459…485  ink 465…481.33 (18/26)
//   `.speech`         x  75…314.67, y 501…545  (239.67×44, tail 9 below)
//   `.k5-card`        x  20…369.67, y 561…694.67  (350×134)
//   `.progress.kid`   x  39…351, y 662…678  (312×16, 70 % leaf fill)
//   `.kid-bar`        y 721…810 (3 + 12 + 64 + 10); painted CTA 350×64 @
//                     y 736…800, i.e. 15 below the bar's top edge
//
// The bottom bar is measured RELATIVE to its own top edge: the app reserves
// the 34 px home-indicator inset inside the bar surface (`SafeArea`) and the
// test surface has no inset, so the bar sits 34 px lower than on the device.
// Everything above it is top-anchored and pinned absolutely.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/kid_home/kid_home_routes.dart';

import '../../test_scope.dart';

/// Loads the bundled faces so the metrics match a device run: on
/// `flutter_test`'s default font the hero, the pill and the bubble glyphs
/// measure wider and every rect below them moves.
Future<void> _loadBundledFonts() async {
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

/// The live theme's [NestTokens], read through a widget that is always on
/// this screen. Both surfaces are matched from the token the view actually
/// paints with — a hard-coded `0xFFFFFFFF` / `0xFFEEEBFF` would silently
/// match NOTHING the day a token changes (review finding 6) and could never
/// be reused for the dark geometry.
NestTokens _tokens(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(NestProgress)))
        .extension<NestTokens>()!;

/// The `.kid-bar` surface: a `Container` painted `surface` with a TOP-ONLY
/// 3 px ink border (the speech bubble shares the fill but borders all four
/// sides, so the shape identifies the bar).
Finder _barSurface(WidgetTester tester) {
  final surface = _tokens(tester).surface;
  return find.byWidgetPredicate((widget) {
    if (widget is! Container) return false;
    final box = widget.decoration;
    if (box is! BoxDecoration) return false;
    if (box.color != surface) return false;
    final border = box.border;
    return border is Border &&
        border.top.width == 3 &&
        border.left.width == 0 &&
        border.right.width == 0 &&
        border.bottom.width == 0;
  });
}

/// The `.k5-card` surface: `lilacTint` + a 3 px ink border on all four sides
/// + the kid shadow.
Finder _growthCardSurface(WidgetTester tester) {
  final lilac = _tokens(tester).lilacTint;
  return find.byWidgetPredicate((widget) {
    if (widget is! Container) return false;
    final box = widget.decoration;
    if (box is! BoxDecoration) return false;
    if (box.color != lilac) return false;
    final border = box.border;
    return border is Border &&
        border.top.width == 3 &&
        border.left.width == 3 &&
        box.boxShadow != null &&
        box.boxShadow!.isNotEmpty;
  });
}

/// The painted CTA: the button's box MINUS the 6 px shadow room
/// `NestKidButton` reserves below it (same convention as
/// `quest_detail_geometry_test.dart`).
Rect _paintedCta(WidgetTester tester) {
  final box = tester.getRect(find.byType(NestKidButton));
  return Rect.fromLTRB(box.left, box.top, box.right, box.bottom - 6);
}

Rect _rectOf(WidgetTester tester, Finder finder) =>
    tester.getRect(finder.first);

Future<void> _pumpComplete(
  WidgetTester tester, {
  double width = 390,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await setUpTestScope();
  GetIt.instance<ThemeModeController>().selectMode(ThemeMode.light);
  await tester.pumpWidget(
    const NestlingApp(initialRoute: KidHomeRoutePaths.complete),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  setUpAll(_loadBundledFonts);

  group('K05 quest complete geometry', () {
    testWidgets('the painted rects land on the design', (tester) async {
      await _pumpComplete(tester);

      // `.k5-top`: the lock is 56×56 at x 314…370, y 47…103 (PNG
      // y 47…102.67). There is no back arrow on this screen.
      final lock = _rectOf(tester, find.byType(NestLockButton));
      expect(lock.left, 314);
      expect(lock.top, 47);
      expect(lock.width, 56);
      expect(lock.height, 56);
      expect(lock.right, 370);

      // `.k5-pip`: the design slot is 218×218 at x 86…304, y 119…337. The
      // `rotate(-8deg)` is a PAINT transform, so the layout box keeps the
      // design's rect and only the centre is asserted here.
      final pip = tester.getSize(find.byType(PipAvatar).first);
      expect(pip, const Size(218, 218));
      final pipRect = tester.getRect(find.byType(PipAvatar).first);
      expect(pipRect.center.dx, closeTo(195, 0.5));
      expect(pipRect.center.dy, closeTo(228, 2));

      // `h1.kid-hero`: 40/44 on one line, `.k5-hero { margin-top: 4px }`.
      final hero = _rectOf(tester, find.text('Brilliant, Maya!'));
      expect(hero.top, 343);
      expect(hero.height, 44);
      expect(hero.center.dx, closeTo(195, 0.5));

      // `.coin-pill.big`: PNG x 121…268.67, y 403…442.67.
      final pill = _rectOf(tester, find.byType(NestCoinPill));
      expect(pill.top, 403);
      expect(pill.height, 40);
      expect(pill.width, closeTo(147.67, 2));
      expect(pill.center.dx, closeTo(195, 0.5));

      // `.k5-sub`: `.kid-body` 18/26, ink y 465…481.33.
      final sub = _rectOf(
        tester,
        find.text('Mum will give it a thumbs-up soon.'),
      );
      expect(sub.top, 459);
      expect(sub.height, 26);

      // `.speech`: 3 + 8 + 22 + 8 + 3 = 44 tall, x 75…314.67.
      final bubble = _rectOf(tester, find.byType(NestSpeechBubble));
      expect(bubble.top, 501);
      expect(bubble.height, 44);
      expect(bubble.left, closeTo(75, 1));
      expect(bubble.right, closeTo(314.67, 1));

      // `.k5-card`: 3 + 14 + 48 + 10 + 20 + 6 + 16 + 14 + 3 = 134 tall.
      final card = _rectOf(tester, _growthCardSurface(tester));
      expect(card.left, 20);
      expect(card.right, 370);
      expect(card.width, 350);
      expect(card.top, 561);
      expect(card.height, 134);

      // The mini Pip is 32×32 at the card's content origin + 16 (card left
      // 20 + 3 border + 16 padding = 39).
      // `.k5-card-top { align-items: center }`: the 32 px Pip centres against
      // the two-line 18/24 headline (row 578…626), so it starts 8 px in.
      final miniPip = tester.getRect(find.byType(PipAvatar).last);
      expect(miniPip.width, 32);
      expect(miniPip.height, 32);
      expect(miniPip.left, closeTo(39, 1));
      expect(miniPip.top, closeTo(card.top + 3 + 14 + 8, 1));
      expect(
        miniPip.center.dy,
        closeTo(card.top + 3 + 14 + 24, 1),
        reason: 'centred on the 48 px headline block',
      );

      // `.k5-count`: `.kcap` 15/20, 10 px under the headline block.
      final count = _rectOf(tester, find.text('175 of 250 coins'));
      expect(count.height, 20);
      expect(count.left, closeTo(39, 1));
      final next = _rectOf(tester, find.text('Next: Songbird'));
      expect(
        next.right,
        closeTo(351, 1),
        reason: 'space-between pins it right',
      );

      // `.progress.kid`: 16 tall, 312 wide (card content box), leaf fill 70 %.
      final bar = _rectOf(tester, find.byType(NestProgress));
      expect(bar.left, closeTo(39, 1));
      expect(bar.right, closeTo(351, 1));
      expect(bar.width, closeTo(312, 1));
      expect(bar.height, 16);
      expect(bar.top, 662);

      // `.kid-bar`: the surface runs to the physical bottom edge (owner rule —
      // no meadow/sky strip under it) and the painted CTA sits 15 px below
      // the bar's top border (3 border + 12 padding), 350×64.
      final barSurface = _rectOf(tester, _barSurface(tester));
      expect(barSurface.left, 0);
      expect(barSurface.right, 390);
      expect(barSurface.bottom, 844);
      expect(
        barSurface.height,
        89,
        reason:
            'border 3 + pad 12 + button 64 + its 6 px shadow room + pad 4. '
            '`NestHomeIndicator` collapses to zero in this test surface '
            '(`NestStatusBar.showMockGlyphs` is false), and the real '
            '${NestDevice.homeH} px device inset is added by `SafeArea` '
            'INSIDE this surface box (owner bottom-edge rule) — neither '
            'belongs in the height asserted here.',
      );
      final cta = _paintedCta(tester);
      expect(cta.left, 20);
      expect(cta.right, 370);
      expect(cta.width, 350);
      expect(cta.height, 64);
      expect(cta.top - barSurface.top, 15);

      await disposeApp(tester);
    });

    testWidgets('nothing overlaps and every edge is shared', (tester) async {
      await _pumpComplete(tester);

      final card = _rectOf(tester, _growthCardSurface(tester));
      final bar = _rectOf(tester, find.byType(NestProgress));
      expect(bar.bottom, lessThanOrEqualTo(card.bottom - 3));

      // The owner ALIGNMENT rule: card, progress bar and CTA share the same
      // 20 px side gutters.
      final cta = _paintedCta(tester);
      expect(card.left, 20);
      expect(cta.left, 20);
      expect(card.right, 370);
      expect(cta.right, 370);
      // Centred elements share the 195 px axis.
      expect(
        _rectOf(tester, find.byType(NestCoinPill)).center.dx,
        closeTo(195, 1),
      );
      expect(
        _rectOf(tester, find.byType(NestSpeechBubble)).center.dx,
        closeTo(195, 1),
      );

      await disposeApp(tester);
    });

    testWidgets('320 px wide and 1.3x text stay inside the gutters', (
      tester,
    ) async {
      await _pumpComplete(tester, width: 320, textScale: 1.3);
      expect(tester.takeException(), isNull);

      final card = _rectOf(tester, _growthCardSurface(tester));
      expect(card.left, 20, reason: 'the gutters stay 20 at every width');
      expect(card.right, 300);
      // The burst plate scales down instead of overflowing (FittedBox).
      expect(tester.takeException(), isNull);
      expect(find.text('Pip needs 75 more coins to grow'), findsOneWidget);
      expect(find.text('Yay! Back home'), findsOneWidget);

      await disposeApp(tester);
    });
  });
}
