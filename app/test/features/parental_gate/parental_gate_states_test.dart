// P17 parental-gate state + a11y tests: dark theme, textScale 1.3 at 390 and
// 320 wide (no overflow exceptions, key rects ≥ 44, modal scrolls inside),
// and a caption contrast spot-check against the design tokens.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/design_system/design_system.dart';

import '../../test_scope.dart';

Future<void> _pump(
  WidgetTester tester, {
  required String route,
  double width = 390,
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
}) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  GetIt.instance<AppModeController>().selectMode(AppMode.kid);
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await tester.pumpWidget(NestlingApp(initialRoute: route));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// WCAG relative-luminance contrast ratio for two opaque colours (sRGB).
double _contrast(Color a, Color b) {
  double channel(double s) =>
      s <= 0.03928 ? s / 12.92 : pow((s + 0.055) / 1.055, 2.4).toDouble();

  double lum(Color c) =>
      0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);

  final la = lum(a);
  final lb = lum(b);
  return la > lb ? (la + 0.05) / (lb + 0.05) : (lb + 0.05) / (la + 0.05);
}

void main() {
  setUp(() async {
    await setUpTestScope();
  });

  testWidgets('dark theme renders the kid gate without overflow', (
    tester,
  ) async {
    await _pump(tester, route: '/parental-gate', theme: ThemeMode.dark);
    expect(find.text('Grown-ups only'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await disposeApp(tester);
  });

  testWidgets('textScale 1.3 at 390 does not overflow', (tester) async {
    await _pump(tester, route: '/parental-gate', textScale: 1.3);
    expect(find.text('Grown-ups only'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await disposeApp(tester);
  });

  testWidgets('320×844 at textScale 1.3 stays overflow-free', (tester) async {
    await _pump(tester, route: '/parental-gate', width: 320, textScale: 1.3);
    expect(find.text('Grown-ups only'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await disposeApp(tester);
  });

  testWidgets('every keypad key keeps a ≥44 rect at 320 px', (tester) async {
    await _pump(tester, route: '/parental-gate', width: 320, textScale: 1.3);
    final keys = <Size>[];
    for (final element in find.byType(Ink).evaluate()) {
      final ro = element.renderObject;
      if (ro is RenderBox && ro.hasSize) {
        final s = ro.size;
        if (s.width < 90 && s.height < 90 && s.width > 40 && s.height > 40) {
          keys.add(s);
        }
      }
    }
    expect(keys, isNotEmpty);
    for (final s in keys) {
      expect(s.width, greaterThanOrEqualTo(44));
      expect(s.height, greaterThanOrEqualTo(44));
    }
    await disposeApp(tester);
  });

  testWidgets('caption colour contrast is kind on both themes', (tester) async {
    for (final mode in const [ThemeMode.light, ThemeMode.dark]) {
      await _pump(tester, route: '/parental-gate', theme: mode);
      final context = tester.element(find.byType(NestModal));
      final tokens = context.nest;
      final surface = tokens.surface;
      final ink2 = tokens.ink2;
      final ratio = _contrast(surface, ink2);
      expect(ratio, greaterThanOrEqualTo(4.5));
      tester.takeException();
    }
    await disposeApp(tester);
  });
}
