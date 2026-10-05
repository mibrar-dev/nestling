// Shared/polish_ui — Money tab icon is the design's wallet/card glyph.
//
// Every parent design tab bar draws Money as a wallet/card (`rect x=3 y=6
// w=18 h=13 rx=3` + `M3 10h18` + `M7 15h4` in `design/html-source`, e.g.
// `P08-today.html`, `P16-settings.html`). The app used a banknote (centre
// disc + corner medallions). This pins the exact design path in both the
// bundled SVG and the `NestIcons.money` wiring, in light and dark.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';

import '../../design_system/test_harness.dart';

void main() {
  group('Money tab icon (shared/polish_ui)', () {
    test('NestIcons.money points at the tab-bar wallet asset', () {
      expect(NestIcons.money, 'assets/icons/ic_money.svg');
    });

    test('ic_money.svg draws the exact design wallet path', () async {
      final svg = await rootBundle.loadString('assets/icons/ic_money.svg');
      expect(
        svg,
        contains('<rect x="3" y="6" width="18" height="13" rx="3"/>'),
      );
      expect(svg, contains('M3 10h18'));
      expect(svg, contains('M7 15h4'));
      // The old banknote is gone: no centre disc, no corner medallions.
      expect(svg, isNot(contains('<circle')));
    });

    testWidgets('the tab bar renders the wallet glyph in both themes', (
      tester,
    ) async {
      const items = [
        NestTabItem(label: 'Today', icon: NestIcons.home),
        NestTabItem(label: 'Quests', icon: NestIcons.quests),
        NestTabItem(label: 'Money', icon: NestIcons.money),
        NestTabItem(label: 'Family', icon: NestIcons.family),
      ];
      for (final mode in const [ThemeMode.light, ThemeMode.dark]) {
        await pumpNest(
          tester,
          NestTabBar(items: items, currentIndex: 2, onTap: (_) {}),
          mode: mode,
        );
        final moneyIcon = find.byWidgetPredicate(
          (w) => w is NestIcon && w.assetName == NestIcons.money,
        );
        expect(moneyIcon, findsOneWidget);
        expect(tester.getSize(moneyIcon), const Size(24, 24));
        // The glyph tints through currentColor: active Money tab is leaf.
        final svg = tester.widget<SvgPicture>(
          find.descendant(of: moneyIcon, matching: find.byType(SvgPicture)),
        );
        expect(svg.colorFilter, isNotNull);
        expect(tester.takeException(), isNull);
      }
    });
  });
}
