// K10 · Payout day — design geometry.
//
// Isolated from `payout_day_view_test.dart` on purpose: loading the real
// bundled Nunito moves every text metric on the screen (K09 has the same
// split), so the positions below are only meaningful next to the real faces.
//
// Every number was measured off `design/screens/light/K10-payout-day.png`
// (1170x2532 = 390x844 @3x) and cross-checked against the box model of
// `design/html-source/screens/K10-payout-day.html`:
//
//   status bar 0…47 · back/lock row 47…107 · scroll 107…721
//   title 107…141 · rain 141…411 (`.rain` clears the 16 px rhythm) ·
//   note 1 427…493 · note 2 509…575 · fund 591…734 · Pip row 750…
//   `.kid-bar` 721…844 on device (89 tall without the home inset, 123 with)
//
// Tolerances are ±2 (UI VERDICT RULE); a uniform shift would fail.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/app/di.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/kid_jar/presentation/widgets/payout_fund_card.dart';
import 'package:nestling/features/kid_jar/presentation/widgets/payout_jar_rain.dart';
import 'package:nestling/features/kid_jar/presentation/widgets/payout_note.dart';

import '../../test_scope.dart';

const double _tolerance = 2;

/// Finds the `.kid-bar` surface: top-only 3 px ink border (the fund card
/// borders all four sides, so the shape identifies the bar).
final Finder _barSurface = find.byWidgetPredicate((widget) {
  if (widget is! Container) return false;
  final decoration = widget.decoration;
  if (decoration is! BoxDecoration) return false;
  final border = decoration.border;
  if (border is! Border) return false;
  return border.top.width == 3 && border.bottom.width == 0;
});

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

Future<void> _pumpPayout(
  WidgetTester tester, {
  double width = 390,
  ThemeMode theme = ThemeMode.light,
}) async {
  await GetIt.instance.reset();
  final db = AppDatabase.memory();
  await configureDependencies(database: db);
  await Seed.demo(db);
  await GetIt.instance<AppSession>().refresh();
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await tester.pumpWidget(const NestlingApp(initialRoute: '/payout-day'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void _expectRect(Rect actual, Rect expected, String what) {
  expect(
    actual.left,
    closeTo(expected.left, _tolerance),
    reason: '$what left (design ${expected.left})',
  );
  expect(
    actual.top,
    closeTo(expected.top, _tolerance),
    reason: '$what top (design ${expected.top})',
  );
  expect(
    actual.width,
    closeTo(expected.width, _tolerance),
    reason: '$what width (design ${expected.width})',
  );
  expect(
    actual.height,
    closeTo(expected.height, _tolerance),
    reason: '$what height (design ${expected.height})',
  );
}

void main() {
  setUpAll(_loadBundledFonts);

  testWidgets('chrome, rain, both notes and the fund card sit on the bands', (
    tester,
  ) async {
    await _pumpPayout(tester);

    // `.krow-top` chrome: 56 px boxes, 20 px gutters, 4 px below the bar.
    final back = tester.getRect(find.byType(NestIconButton));
    _expectRect(back, const Rect.fromLTWH(20, 47, 56, 56), 'back button');
    final lock = tester.getRect(find.byType(NestLockButton));
    _expectRect(lock, const Rect.fromLTWH(314, 47, 56, 56), 'lock button');

    // `.kid-title`, centred, 28/34 (`K10:39`).
    final title = tester.getRect(find.text("It's payout day!"));
    expect(title.top, closeTo(107, _tolerance));
    expect(title.height, closeTo(34, _tolerance));
    expect(title.center.dx, closeTo(195, _tolerance));

    // `.rain` 180x270, immediately after the title (no 16 px separator).
    final rain = tester.getRect(find.byType(PayoutJarRain));
    _expectRect(rain, const Rect.fromLTWH(105, 141, 180, 270), 'rain box');

    // Both receipt cards: surface, 3 px ink border, r16 (`K10:20`). Note 1
    // is 66 tall; note 2's DB title ("£5.50 went into your Lego Friends set")
    // wraps to two lines at 17/22, so its card is 88 — the CSS card grows
    // with content, the design mock's shorter copy keeps it at 66.
    final notes = find.byType(PayoutNote);
    _expectRect(
      tester.getRect(notes.first),
      const Rect.fromLTWH(20, 427, 350, 66),
      'note 1',
    );
    _expectRect(
      tester.getRect(notes.last),
      const Rect.fromLTWH(20, 509, 350, 88),
      'note 2',
    );

    // `.k10-fund` 16 px below note 2, 143 tall (3 + 14 + 26 + 10 + 23 +
    // 6 + 16 + 8 + 20 + 14 + 3).
    final fund = tester.getRect(find.byType(PayoutFundCard));
    _expectRect(fund, const Rect.fromLTWH(20, 613, 350, 143), 'fund card');

    // `h2` on the card's inner top edge (3 px border + 14 px padding).
    final heading = tester.getRect(find.text('Lego Friends set'));
    expect(heading.top, closeTo(630, _tolerance));
    expect(heading.height, closeTo(26, _tolerance));

    // `.progress.kid`: inset 3 + 16 from the card, 16 tall (`K10:86`).
    final progress = tester.getRect(find.byType(NestProgress));
    _expectRect(
      progress,
      const Rect.fromLTWH(39, 695, 312, 16),
      'progress bar',
    );

    // Captions row sits 8 px under the progress bar's border box.
    final caption = tester.getRect(find.text('of £24.99'));
    expect(caption.top, closeTo(719, _tolerance));
    expect(caption.height, closeTo(20, _tolerance));

    await disposeApp(tester);
  });

  testWidgets('the kid bar runs to the physical bottom edge, in both themes', (
    tester,
  ) async {
    for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      await _pumpPayout(tester, theme: theme);

      // BOTTOM EDGE owner rule: the bar's surface reaches the physical
      // screen edge — no meadow or sky strip under the bar in either theme.
      // The test surface has no home inset, so the bar is 89 tall here; on
      // device the inset adds 34 under the surface.
      final bar = tester.getRect(_barSurface);
      expect(bar.bottom, 844);
      expect(bar.left, 0);
      expect(bar.right, 390);
      expect(bar.height, closeTo(89, _tolerance));
      expect(bar.top, closeTo(844 - 89, _tolerance));

      // Painted button: 16 + 3 + 12 from the bar's left/top edge down to the
      // white label... outer button box 350 wide, 64 tall, leaf fill.
      final button = tester.getRect(find.byType(NestKidButton));
      expect(button.top, closeTo(bar.top + 3 + 12, _tolerance));
      expect(button.left, closeTo(NestSpacing.padSide, _tolerance));
      expect(button.width, closeTo(350, _tolerance));

      await disposeApp(tester);
    }
  });

  testWidgets('gutters stay 20 at every supported width', (tester) async {
    for (final width in <double>[320, 390, 430]) {
      await _pumpPayout(tester, width: width);
      final fund = tester.getRect(find.byType(PayoutFundCard));
      expect(fund.left, closeTo(NestSpacing.padSide, _tolerance));
      expect(fund.right, closeTo(width - NestSpacing.padSide, _tolerance));
      final notes = find.byType(PayoutNote);
      expect(tester.getRect(notes.first).left, fund.left);
      expect(tester.getRect(notes.first).right, fund.right);
      final rain = tester.getRect(find.byType(PayoutJarRain));
      expect(rain.center.dx, closeTo(width / 2, _tolerance));
      await disposeApp(tester);
    }
  });
}
