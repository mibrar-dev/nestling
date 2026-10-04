// K01 · Who's playing? — copy FIT at the app's real font metrics.
//
// Why this file is separate from every other K01 widget test: the bundled
// Nunito/Inter faces change every text metric, so a "does the copy still fit?"
// assertion run under `flutter_test`'s default (metric-less) font measures a
// font no device will ever show and reports false clipping. `flutter test`
// uses the Ahem-style placeholder where every glyph is one em wide, so
// "Who's playing?" looks ~2× wider than it is.
//
// This file loads the bundled faces (the same isolation
// `k01_profile_picker_geometry_test.dart` documents) and proves the copy fits
// at 320 / 390 / 430 px and text scale 1.0 and 1.3 — the app clamps the scale
// at 1.3, so 1.3 is the real worst case.
//
// Run it directly:
//   flutter test test/features/kid_home/k01_copy_fit_test.dart

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/controllers.dart';

import '../../test_scope.dart';

/// Every string the picker draws, with the maxLines the screen sets on it.
const List<(String, int)> _copy = <(String, int)>[
  ("Who's playing?", 2), // NestBalancedText, .kid-title
  ('Tap your face to start', 2), // .kid-body
  ('Grown-ups: tap the lock to get back to your dashboard.', 3), // .kcap
  ('Maya', 1), // .k1-name
  ('Leo', 1),
  ('Age 7–9', 1), // .k1-age
  ('Age 4–6', 1),
];

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

Future<void> _pumpFit(
  WidgetTester tester, {
  required double width,
  required double textScale,
  ThemeMode theme = ThemeMode.light,
}) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await pumpAppRoute(tester, '/who-is-playing', theme: theme);
}

void main() {
  setUpAll(loadBundledFonts);

  setUp(() async {
    await setUpTestScope();
  });

  for (final width in const <double>[320, 390, 430]) {
    for (final textScale in const <double>[1, 1.3]) {
      testWidgets(
        '${width.toInt()}px @${textScale}x: no string is ellipsized or clipped',
        (tester) async {
          await _pumpFit(tester, width: width, textScale: textScale);
          for (final (copy, maxLines) in _copy) {
            final finder = find.text(copy);
            expect(finder, findsOneWidget, reason: copy);
            final paragraph = tester.renderObject<RenderParagraph>(finder);
            expect(
              paragraph.didExceedMaxLines,
              isFalse,
              reason:
                  '“$copy” loses words at ${width.toInt()}px @${textScale}x '
                  '(the design draws all of it; maxLines $maxLines)',
            );
          }
          expect(tester.takeException(), isNull);
          await disposeApp(tester);
        },
      );
    }
  }

  testWidgets("the grown-ups caption wraps to the design's two lines", (
    tester,
  ) async {
    // The design PNG breaks the caption after "your"; the app must break it
    // the same way at 390 px.
    await _pumpFit(tester, width: 390, textScale: 1);
    final paragraph = tester.renderObject<RenderParagraph>(
      find.text('Grown-ups: tap the lock to get back to your dashboard.'),
    );
    expect(paragraph.size.width, greaterThan(0));
    expect(
      tester
          .getSize(
            find.text('Grown-ups: tap the lock to get back to your dashboard.'),
          )
          .height,
      closeTo(40, 0.5),
      reason: 'two 20px lines, per the design',
    );
    await disposeApp(tester);
  });
}
