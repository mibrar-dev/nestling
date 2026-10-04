// P17 parental-gate geometry tests: exact frame facts from the plan — modal
// 342×? at x24 with radius 32, lock tile 52 radius 16, digit boxes 56×64,
// 11 key cells 72×72, scrim full-bleed to the physical edge. Light + dark.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/design_system/design_system.dart';

import '../../test_scope.dart';

/// Finds every Container render box whose size matches [w]×[h].
List<RenderBox> _boxesOfSize(WidgetTester tester, double w, double h) => [
  for (final element in find.byType(Container).evaluate())
    if (element.renderObject case RenderBox(hasSize: true, size: final s)
        when (s.width - w).abs() < 0.75 && (s.height - h).abs() < 0.75)
      element.renderObject! as RenderBox,
];

void main() {
  setUp(() async {
    await setUpTestScope();
  });

  for (final (String themeName, ThemeMode theme) in const <(String, ThemeMode)>[
    ('light', ThemeMode.light),
    ('dark', ThemeMode.dark),
  ]) {
    testWidgets('modal frame and children match the spec — $themeName', (
      tester,
    ) async {
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      await pumpAppRoute(tester, '/parental-gate', theme: theme);

      // Modal: x 24, width 390 − 2×24 = 342.
      final modal = tester.getRect(find.byType(NestModal));
      expect(modal.left, moreOrLessEquals(24, epsilon: 0.5));
      expect(modal.width, moreOrLessEquals(342, epsilon: 0.5));
      final modalDecoration = tester
          .widgetList<Container>(
            find.byWidgetPredicate(
              (w) =>
                  w is Container &&
                  w.decoration is BoxDecoration &&
                  (w.decoration! as BoxDecoration).borderRadius ==
                      NestRadii.allXl,
            ),
          )
          .first
          .decoration!;
      expect(modalDecoration, isA<BoxDecoration>());
      expect((modalDecoration as BoxDecoration).borderRadius, NestRadii.allXl);

      // Lock tile 52×52 radius 16.
      expect(_boxesOfSize(tester, 52, 52), hasLength(1));

      // Digit boxes: a 2-digit answer ⇒ two 56×64 boxes, gap 12.
      final digitBoxes = _boxesOfSize(tester, 56, 64);
      expect(digitBoxes, hasLength(2));
      digitBoxes.sort(
        (a, b) => a
            .localToGlobal(Offset.zero)
            .dx
            .compareTo(b.localToGlobal(Offset.zero).dx),
      );
      final left = digitBoxes[0].localToGlobal(Offset.zero);
      final right = digitBoxes[1].localToGlobal(Offset.zero);
      expect(right.dx - (left.dx + 56), moreOrLessEquals(12, epsilon: 0.5));

      // Keys 72×72 (Ink), 11 of them (10 digits + delete; blank is not inked).
      final keys = find.byWidgetPredicate(
        (w) => w is Ink && w.width == 72 && w.height == 72,
      );
      expect(keys, findsNWidgets(11));
      expect(
        tester.getSize(keys.first).width,
        moreOrLessEquals(72, epsilon: 0.5),
      );

      // Cancel ghost stays at the 56 kid minimum.
      final cancelText = find.text('Back to Pip');
      final cancel = find.ancestor(
        of: cancelText,
        matching: find.byType(NestButton),
      );
      expect(tester.getSize(cancel).height, greaterThanOrEqualTo(56));

      // Scrim paints the whole 390×844 canvas, under the modal.
      var fullBleedFound = false;
      for (final e in find.byType(ColoredBox).evaluate()) {
        final ro = e.renderObject;
        if (ro is RenderBox && ro.size == const Size(390, 844)) {
          fullBleedFound = true;
        }
      }
      expect(fullBleedFound, isTrue);
      await disposeApp(tester);
    });
  }
}
