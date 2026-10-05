import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';

import '../../design_system/test_harness.dart';

// `NestPageTitle` — the shared parent-tab `.ptitle`.
//
// Exact CSS metrics (`P10-quest-library.html:3`, `P12-money.html:3`,
// `P16-settings.html:3`): `font-display 900 28/34`, `padding-top: 8px`.
// Migrated from the private copies in P10 (quest_library_body), P12
// (money_ledger_view `_PageTitle`), P13 (payout_view dimmed + empty) and P16
// (settings_view title). P15's hero (24/30) and P08's greet (22/28) are
// different styles, not `.ptitle` — deliberately untouched.
void main() {
  group('NestPageTitle matches .ptitle', () {
    testWidgets('top padding is the design 8 px', (tester) async {
      await pumpNest(tester, const NestPageTitle(title: 'Pocket money'));
      final padding = tester.widget<Padding>(
        find.ancestor(
          of: find.text('Pocket money'),
          matching: find.byType(Padding),
        ),
      );
      expect(
        (padding.padding as EdgeInsets).top,
        NestSpacing.s2,
        reason: '.ptitle { padding-top: 8px }',
      );
    });

    testWidgets('style is h1 28/34 w900 ink', (tester) async {
      await pumpNest(tester, const NestPageTitle(title: 'Quests'));
      final text = tester.widget<Text>(find.text('Quests'));
      expect(text.style!.fontFamily, 'Nunito');
      expect(text.style!.fontSize, 28);
      expect(text.style!.height, 34 / 28);
      expect(text.style!.fontWeight, FontWeight.w900);
      expect(text.style!.color, NestColors.light.ink);
    });

    testWidgets('announces as a heading, single line ellipsis', (tester) async {
      await pumpNest(tester, const NestPageTitle(title: 'Family & settings'));
      final text = tester.widget<Text>(find.text('Family & settings'));
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
      final handle = tester.ensureSemantics();
      await tester.pump();
      expect(
        tester
            .getSemantics(find.text('Family & settings'))
            .getSemanticsData()
            .flagsCollection
            .isHeader,
        isTrue,
        reason: 'the page title is the top heading',
      );
      handle.dispose();
    });
  });
}
