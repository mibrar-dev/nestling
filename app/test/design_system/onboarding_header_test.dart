import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';

import 'test_harness.dart';

/// Shared onboarding header geometry (P03/P04/P05 compact back row).
///
/// Design (390x844, `P04-privacy.html` / `P05-add-children.html`,
/// `components.css` with border-box sizing):
/// * `.status-bar` = 47 high,
/// * `.nav-bar.compact` = min-height 52 + padding `4px 12px 12px`; the 44px
///   back button stretches it to 4 + 44 + 12 = 60,
/// * chevron centre = 47 + 4 + 22 = 73,
/// * scroll title line-box top = 47 + 60 = 107 (cap top ≈ 112 after the
///   Nunito bearing).
void main() {
  group('onboarding compact header', () {
    testWidgets('status 47 + nav 60 puts the chevron at y 73', (tester) async {
      await pumpNest(
        tester,
        const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NestStatusBar(),
            NestNavBar(compact: true, onBack: _noop),
          ],
        ),
      );
      expect(tester.takeException(), isNull);

      final statusH = tester.getSize(find.byType(NestStatusBar)).height;
      final navH = tester.getSize(find.byType(NestNavBar)).height;
      expect(statusH, 47);
      expect(navH, 60);

      final chevron = tester.getCenter(find.bySemanticsLabel('Back'));
      expect(chevron.dy, moreOrLessEquals(47 + 4 + 22, epsilon: 1.5));
      expect(chevron.dx, moreOrLessEquals(12 + 22, epsilon: 1.5));
    });

    testWidgets('title line-box starts at y 107', (tester) async {
      await pumpNest(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const NestStatusBar(),
            const NestNavBar(compact: true, onBack: _noop),
            Text('Your family\u2019s privacy', style: NestType.h1()),
          ],
        ),
      );
      expect(tester.takeException(), isNull);
      final titleTop = tester
          .getTopLeft(find.text('Your family\u2019s privacy'))
          .dy;
      expect(titleTop, moreOrLessEquals(47 + 60, epsilon: 1.5));
    });
  });
}

void _noop() {}
