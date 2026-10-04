// K04 quest-detail geometry: every painted rect compared with
// `design/screens/light/K04-quest-detail.png` ÷3 (1170×2532 @3x).
//
// Measured design values this file pins (logical px, 390×844):
//
//   `.k4-top` row      y  47…103   back 56×56 @ x 20, lock 56×56 @ x 314
//   `.k4-tile`         y 109…229   x 135…255  (120×120, r24, 3 px ink)
//   `h1.kid-title`     y 233…267   one line, 28/34
//   `.coin-pill.big`   y 283…323   x 148…242  (94×40)
//   `.kcap` hint       y 339…359   (15/20)
//   `.k4-steps`        y 375…561   x  20…370  (350×186)
//   `.k4-step` rows    y 378…438 / 440…498 / 500…558, dividers y 438 & 498 (2 px)
//   `.k4-dot`          40×40 @ x 37…77, text starts x 89
//   `.k4-cheer`        y 583…647   Pip 64 @ x 37…101, bubble x 113…353 y 593…637
//   `.kid-bar`         3 + 12 + 64 + 10 + 64 + 10 = 163 tall; painted buttons
//                      64 tall, 10 apart, 350 wide, 15 below the bar top
//
// The bottom bar is measured RELATIVE to its own top edge: the app reserves
// the 34 px home-indicator inset inside the bar surface (`SafeArea`), and the
// test surface has no inset, so the bar simply sits 34 px lower than on the
// device. Everything above it is top-anchored and pinned absolutely.

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
/// `flutter_test`'s default font the title alone wraps to two lines and every
/// rect below it moves (same isolation as `kid_home_geometry_test.dart`).
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

/// The painted `.k4-steps` card: the all-side-ink-bordered, r24, shadowed
/// `Container` (a UI-check rule: measure the BACKGROUND rect, not the text).
Finder _stepsCardSurface() => find.byWidgetPredicate((widget) {
  if (widget is! Container) return false;
  final box = widget.decoration;
  if (box is! BoxDecoration) return false;
  final border = box.border;
  return border is Border &&
      border.top.width > 0 &&
      border.left.width == border.top.width &&
      border.top.color == const Color(0xFF1E1B3A) &&
      box.color == const Color(0xFFFFFFFF);
});

/// The `.k4-dot` ring: a 40 px circle with a 3 px ink border.
Finder _dot(int index) => find
    .byWidgetPredicate((widget) {
      if (widget is! Container) return false;
      final box = widget.decoration;
      if (box is! BoxDecoration || box.shape != BoxShape.circle) return false;
      final size = widget.constraints?.maxHeight;
      return size == 40;
    })
    .at(index);

/// The `.k4-step + .k4-step` divider: a 2 px `line` bar, no child.
Finder _divider(int index) => find
    .byWidgetPredicate((widget) {
      if (widget is! Container) return false;
      if (widget.child != null) return false;
      return widget.constraints?.maxHeight == 2;
    })
    .at(index);

/// The `.kid-bar` surface: top-only 3 px ink border (quest cards border all
/// four sides, so the shape identifies the bar).
Finder _barSurface() => find.byWidgetPredicate((widget) {
  if (widget is! Container) return false;
  final box = widget.decoration;
  if (box is! BoxDecoration) return false;
  final border = box.border;
  return border is Border && border.top.width == 3 && border.left.width == 0;
});

Rect _rectOf(WidgetTester tester, Finder finder) =>
    tester.getRect(finder.first);

Future<void> _pumpDetail(WidgetTester tester, {double width = 390}) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await setUpTestScope();
  GetIt.instance<ThemeModeController>().selectMode(ThemeMode.light);
  await tester.pumpWidget(
    const NestlingApp(initialRoute: KidHomeRoutePaths.detail),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  setUpAll(_loadBundledFonts);

  group('K04 quest detail geometry', () {
    testWidgets('the painted rects land on the design', (tester) async {
      await _pumpDetail(tester);

      // Top row: `.k4-top { padding: 0 20px 6px }`, both buttons 56 (PNG
      // y 47…103).
      final back = _rectOf(tester, find.byType(NestIconButton));
      expect(back.left, 20);
      expect(back.top, 47);
      expect(back.width, 56);
      expect(back.height, 56);
      final lock = _rectOf(tester, find.byType(NestLockButton));
      expect(lock.width, 56);
      expect(lock.height, 56);
      expect(lock.right, 370);
      expect(lock.top, 47);

      // `.k4-tile` 120×120, centred (PNG x 135…255, y 109…229).
      final tile = _rectOf(
        tester,
        find.byWidgetPredicate((widget) {
          if (widget is! Container) return false;
          final box = widget.decoration;
          if (box is! BoxDecoration) return false;
          return box.color == const Color(0xFFFFEDE4) &&
              box.boxShadow != null &&
              box.borderRadius == BorderRadius.circular(24);
        }),
      );
      expect(tile.width, 120);
      expect(tile.height, 120);
      expect(tile.left, 135);
      expect(tile.top, 109);
      expect(tile.center.dx, closeTo(195, 0.5));

      // `h1.kid-title` 28/34 on one line, `.k4-title { margin-top: 4 }`.
      final title = _rectOf(tester, find.text('Tidy your bedroom'));
      expect(title.top, 233);
      expect(title.height, 34);
      expect(title.left, greaterThanOrEqualTo(20));
      expect(title.right, lessThanOrEqualTo(370));

      // `.coin-pill.big` (PNG x 148…242, y 283…323).
      final pill = _rectOf(tester, find.byType(NestCoinPill));
      expect(pill.top, 283);
      expect(pill.height, 40);
      expect(pill.width, 94);
      expect(pill.center.dx, closeTo(195, 0.5));

      // `.kcap` hint, 15/20.
      final hint = _rectOf(
        tester,
        find.text('Tick each bit off, then press the big button.'),
      );
      expect(hint.top, 339);
      expect(hint.height, 20);

      // `.k4-steps` 350×186 (PNG y 375…561).
      final card = _rectOf(tester, _stepsCardSurface());
      expect(card.left, 20);
      expect(card.right, 370);
      expect(card.top, 375);
      expect(card.height, 186);

      // Rows are border-box 60: 3 + 60 + 60 + 60 + 3.
      // Each 60 px row centres its 24 px step text: row centres at 408 / 469
      // / 529 (PNG divider tops 438 and 498).
      final firstRow = _rectOf(tester, find.text('Clothes in the basket'));
      expect(firstRow.height, 24);
      expect(firstRow.center.dy, closeTo(408, 0.01));
      final secondRow = _rectOf(tester, find.text('Toys in the box'));
      expect(secondRow.center.dy, closeTo(469, 0.01));
      final lastRow = _rectOf(tester, find.text('Books on the shelf'));
      expect(lastRow.center.dy, closeTo(529, 0.01));
      final dividerOne = _rectOf(tester, _divider(0));
      final dividerTwo = _rectOf(tester, _divider(1));
      expect(dividerOne.height, 2);
      expect(dividerOne.top, 438);
      expect(dividerTwo.height, 2);
      expect(dividerTwo.top, 498);
      // The dividers bleed across the card's CONTENT box (CSS content box,
      // so 3 px inside the painted border on each side).
      expect(dividerOne.left, closeTo(card.left + 3, 0.01));
      expect(dividerOne.right, closeTo(card.right - 3, 0.01));

      // `.k4-dot` 40×40 @ x 37…77 (card border 3 + row padding 14); the step
      // text starts 40 + 12 further right (PNG x 89).
      final dot = _rectOf(tester, _dot(0));
      expect(dot.width, 40);
      expect(dot.height, 40);
      expect(dot.left, closeTo(37, 0.01));
      expect(dot.center.dy, closeTo(408, 0.01));
      expect(firstRow.left, closeTo(89, 0.6));

      // `.k4-cheer { margin-top: 22px }`: the row is the card bottom + 22.
      final pip = _rectOf(tester, find.byType(PipAvatar));
      expect(pip.width, 64);
      expect(pip.height, 64);
      expect(pip.top, 583);
      expect(pip.left, closeTo(37, 0.6));
      final bubble = _rectOf(tester, find.byType(NestSpeechBubble));
      expect(bubble.top, 593);
      expect(bubble.left, closeTo(113, 0.6));
      expect(bubble.right, closeTo(353, 0.6));

      // `.kid-bar`: the surface runs to the physical bottom edge (owner rule
      // — no meadow/sky strip under it) and is 163 tall.
      final bar = _rectOf(tester, _barSurface());
      expect(bar.bottom, 844);
      expect(bar.height, 163);

      // Painted buttons: 350×64, 20 side gutters, 10 apart, 12+3 below the
      // bar's top edge (the 6 px shadow room `NestKidButton` reserves is
      // handed back to the gap and the bottom air).
      final buttons = find.byType(NestKidButton);
      expect(buttons, findsNWidgets(2));
      final first = tester.getRect(buttons.at(0));
      final second = tester.getRect(buttons.at(1));
      final paintedFirst = Rect.fromLTRB(
        first.left,
        first.top,
        first.right,
        first.bottom - 6,
      );
      final paintedSecond = Rect.fromLTRB(
        second.left,
        second.top,
        second.right,
        second.bottom - 6,
      );
      expect(paintedFirst.left, 20);
      expect(paintedFirst.right, 370);
      expect(paintedFirst.width, 350);
      expect(paintedFirst.height, 64);
      expect(paintedSecond.height, 64);
      expect(paintedSecond.top - paintedFirst.bottom, 10);
      expect(paintedFirst.top - bar.top, 15);
      expect(bar.bottom - paintedSecond.bottom, 10);

      await disposeApp(tester);
    });

    testWidgets('the card paints radius 24, a 3 px ink border and a shadow', (
      tester,
    ) async {
      await _pumpDetail(tester);
      final card = tester.widget<Container>(_stepsCardSurface().first);
      final box = card.decoration! as BoxDecoration;
      final border = box.border! as Border;
      expect(border.top.width, 3);
      expect(box.borderRadius, BorderRadius.circular(24));
      expect(box.boxShadow, isNotNull);
      expect(box.boxShadow!.isNotEmpty, isTrue);

      await disposeApp(tester);
    });

    testWidgets('320 px width and 1.3x text stay inside the gutters', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await setUpTestScope();
      GetIt.instance<ThemeModeController>().selectMode(ThemeMode.light);
      await tester.pumpWidget(
        const NestlingApp(initialRoute: KidHomeRoutePaths.detail),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
      expect(find.text('Tidy your bedroom'), findsOneWidget);
      expect(find.text('Books on the shelf'), findsOneWidget);
      expect(find.text('I did it!'), findsOneWidget);
      await disposeApp(tester);
    });
  });
}
