// P16 final fixes — pins for 4_review findings 1–3 and 6.
//
// Finding 1 (major): the move banner names the CURRENT family zone for
// history and the device zone for the future — never a literal.
// Findings 2–3 (minor): the `.lockhint` glyph is `ink`, the `›` chevron is
// Inter w600 `ink-3` (16 on list rows, 15 inside the subscription linkrow).
// Finding 6 is pinned in `settings_a11y_test.dart` (own container nodes).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';

import '../../test_scope.dart';
import 'p16_test_support.dart';

void main() {
  setUpAll(loadP16Fonts);

  group('P16 final fixes — move banner zones (finding 1)', () {
    testWidgets('family Dubai + device London names Dubai then London', (
      tester,
    ) async {
      await pumpSettingsApp(
        tester,
        prepare: Seed.movedToDubai,
        deviceZone: 'Europe/London',
      );

      expect(
        find.text(
          'Looks like you’re in London now. Switch the family time zone? '
          'History keeps Dubai times; future days follow London.',
        ),
        findsOneWidget,
      );

      await disposeApp(tester);
    });

    testWidgets('family Dubai + device Karachi names Dubai then Karachi', (
      tester,
    ) async {
      await pumpSettingsApp(
        tester,
        prepare: Seed.movedToDubai,
        deviceZone: 'Asia/Karachi',
      );

      expect(
        find.text(
          'Looks like you’re in Karachi now. Switch the family time zone? '
          'History keeps Dubai times; future days follow Karachi.',
        ),
        findsOneWidget,
      );

      await disposeApp(tester);
    });

    testWidgets('seeded default still reads London then Dubai', (tester) async {
      await pumpSettingsApp(tester, deviceZone: 'Asia/Dubai');

      expect(
        find.text(
          'Looks like you’re in Dubai now. Switch the family time zone? '
          'History keeps London times; future days follow Dubai.',
        ),
        findsOneWidget,
      );

      await disposeApp(tester);
    });
  });

  group('P16 final fixes — lockhint + chevron tokens (findings 2–3)', () {
    testWidgets('the lock glyph paints ink, not ink-2', (tester) async {
      for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
        await pumpSettingsApp(tester, theme: theme);
        await scrollSettingsTo(tester, find.text('Help & feedback'));

        final lock = find.byWidgetPredicate(
          (w) => w is NestIcon && w.assetName == NestIcons.lock,
        );
        expect(lock, findsOneWidget, reason: 'one lock glyph at $theme');
        expect(
          tester.widget<NestIcon>(lock).color,
          p16Tokens(theme).ink,
          reason: '.lockhint inherits var(--ink) at $theme',
        );

        await disposeApp(tester);
      }
    });

    testWidgets('the list chevron is Inter 16 w600 ink-3, not a heading', (
      tester,
    ) async {
      for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
        await pumpSettingsApp(tester, theme: theme);
        await scrollSettingsTo(tester, find.text('Invite co-parent'));

        final row = find
            .ancestor(
              of: find.text('Invite co-parent'),
              matching: find.byWidgetPredicate((w) => w is NestListRow),
            )
            .first;
        final chevron = find
            .descendant(of: row, matching: find.text('›'))
            .first;
        final style = tester.widget<Text>(chevron).style!;
        expect(style.fontFamily, 'Inter', reason: 'Inter at $theme');
        expect(style.fontSize, 16, reason: '.list-trail 16 at $theme');
        expect(style.fontWeight, FontWeight.w600, reason: 'w600 at $theme');
        expect(style.color, p16Tokens(theme).ink3, reason: 'ink-3 at $theme');
        expect(style.letterSpacing, 0, reason: 'no tracking at $theme');

        await disposeApp(tester);
      }
    });

    testWidgets('the subscription linkrow chevron is Inter 15 w600 ink-3', (
      tester,
    ) async {
      for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
        await pumpSettingsApp(tester, theme: theme);
        await scrollSettingsTo(tester, find.text('Manage subscription'));

        final card = subscriptionCard();
        final chevron = find
            .descendant(of: card, matching: find.text('›'))
            .first;
        final style = tester.widget<Text>(chevron).style!;
        expect(style.fontFamily, 'Inter', reason: 'Inter at $theme');
        expect(style.fontSize, 15, reason: '.linkrow 15 at $theme');
        expect(style.fontWeight, FontWeight.w600, reason: 'w600 at $theme');
        expect(style.color, p16Tokens(theme).ink3, reason: 'ink-3 at $theme');

        await disposeApp(tester);
      }
    });
  });
}
