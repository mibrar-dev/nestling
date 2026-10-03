// P06 Pocket money setup — real-fonts geometry guard (iteration 6).
//
// ORCHESTRATOR_NOTES.md "UPDATE (07:22)" mandate: *"Add a geometry test with
// real fonts (FontLoader, as
// app/test/features/privacy_consent/privacy_consent_geometry_test.dart does)
// that pins these y values at 390×844."* The Ahem fallback the rest of the
// suite runs under cannot catch a metric drift, so every anchor below is
// measured after loading the bundled Inter/Nunito.
//
// Seed: `onboarding_kids` — the shoot seed the UI-check stage uses, so the
// card lists Maya (£3.00) then Leo (£1.50) in insertion order.
//
// Coordinates are SCREEN-space logical pixels (design PNG ÷3). The
// orchestrator's 555/597/630/674/735 figures were read off the compare
// sheet, which is offset ~84.5 px; the screen-space values they correspond to
// are the ones pinned here (sheet − 84.5 ≈ 470.5/512/545/589/650).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/di.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';

import '../../test_scope.dart';

const String _heading = 'How does pocket money work in your house?';

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

/// Pumps `/pocket-money-setup` on the `onboarding_kids` seed.
Future<void> _pumpOnboardingKids(WidgetTester tester) async {
  await GetIt.instance.reset();
  final db = AppDatabase.memory();
  await configureDependencies(database: db);
  await Seed.onboardingKids(db);
  await GetIt.instance<AppSession>().refresh();
  await pumpAppRoute(tester, '/pocket-money-setup');
}

/// The painted pill of a day cell (the `.chip.day` background), by its key.
Finder _dayPill(int day) => find.descendant(
  of: find.byKey(ValueKey<String>('p06_day_$day')),
  matching: find.byType(DecoratedBox),
);

void main() {
  group('P06 screen geometry at 390×844 (real fonts, onboarding_kids)', () {
    setUpAll(_loadBundledFonts);

    testWidgets('the H1 is two 34 px lines at the design top (107–175)', (
      tester,
    ) async {
      await _pumpOnboardingKids(tester);

      final rect = tester.getRect(find.text(_heading));
      expect(rect.top, moreOrLessEquals(107, epsilon: 1));
      expect(rect.height, moreOrLessEquals(68, epsilon: 1));
      expect(rect.left, moreOrLessEquals(NestSpacing.padSide, epsilon: 0.01));
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('the three option cards sit at the design 191/263/335, '
        'each 64 tall', (tester) async {
      await _pumpOnboardingKids(tester);

      for (final entry in <(String, double)>[
        ('Weekly amount', 191),
        ('Earn per quest', 263),
        ('Both', 335),
      ]) {
        final card = tester.getRect(
          find.byKey(
            ValueKey<String>(
              'p06_option_${entry.$1 == 'Weekly amount'
                  ? 'weekly'
                  : entry.$1 == 'Earn per quest'
                  ? 'per_quest'
                  : 'both'}',
            ),
          ),
        );
        expect(
          card.top,
          moreOrLessEquals(entry.$2, epsilon: 1),
          reason: '${entry.$1} top',
        );
        expect(
          card.height,
          moreOrLessEquals(64, epsilon: 1),
          reason: '${entry.$1} height',
        );
        expect(card.left, moreOrLessEquals(20, epsilon: 0.01));
        expect(card.width, moreOrLessEquals(350, epsilon: 0.01));
      }
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('the payout card spans 415–684 and its rows land on the '
        'design anchors', (tester) async {
      await _pumpOnboardingKids(tester);

      final card = tester.getRect(find.byType(NestCard));
      expect(card.top, moreOrLessEquals(415, epsilon: 1));
      expect(card.bottom, moreOrLessEquals(684, epsilon: 1));
      expect(card.left, moreOrLessEquals(20, epsilon: 0.01));
      expect(card.width, moreOrLessEquals(350, epsilon: 0.01));

      // `Payout day` label 431–449; the day pills 455–486 (32 tall).
      final label = tester.getRect(find.text('Payout day'));
      expect(label.top, moreOrLessEquals(431, epsilon: 1));
      expect(label.height, moreOrLessEquals(18, epsilon: 1));
      final pill = tester.getRect(_dayPill(1));
      expect(pill.top, moreOrLessEquals(455, epsilon: 1));
      expect(pill.height, moreOrLessEquals(32, epsilon: 1));
      // The orchestrator's sheet-space chip-row centre 555 → 470.5 screen.
      expect(pill.center.dy, moreOrLessEquals(470.5, epsilon: 1));

      // `Weekly base` 503–521 → sheet centre 597.
      final weekly = tester.getRect(find.text('Weekly base'));
      expect(weekly.top, moreOrLessEquals(503, epsilon: 1));
      expect(weekly.center.dy, moreOrLessEquals(512, epsilon: 1));

      // Child rows: Maya then Leo (CHILD ORDER), sheet centres 630 / 674.
      final maya = tester.getRect(find.text('Maya'));
      final leo = tester.getRect(find.text('Leo'));
      expect(maya.center.dy, moreOrLessEquals(545, epsilon: 1));
      expect(leo.center.dy, moreOrLessEquals(589, epsilon: 1));
      expect(
        maya.top,
        lessThan(leo.top),
        reason: 'CHILD ORDER — Maya, then Leo, in the order they were added',
      );

      // `Coin value` row 628–672 → sheet centre 735.
      final coin = tester.getRect(find.text('Coin value'));
      expect(coin.center.dy, moreOrLessEquals(650, epsilon: 1));
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets(
      'the CTA panel runs to the physical edge at the design height',
      (tester) async {
        await _pumpOnboardingKids(tester);

        final cta = tester.getRect(find.byType(NestBottomCta));
        // OWNER BOTTOM EDGE: the panel's surface — not the page tint — reaches
        // the physical bottom, in light and dark. The design puts a 34 px
        // `.home-indicator` strip below its CTA; the app folds that inset into
        // the same surface, so the panel is content + 34 tall.
        expect(cta.bottom, moreOrLessEquals(844, epsilon: 1));
        // caption (2 × 18) + 8 gap + 52 button + 2 × 14 dense padding = 124;
        // with the 34 px home-indicator inset the panel would top out at the
        // design's 685 (844 − 34 − 124 − 1 border).
        expect(cta.height, moreOrLessEquals(124, epsilon: 1));
        expect(cta.top, moreOrLessEquals(720, epsilon: 1));
        final button = tester.getRect(
          find.byKey(const ValueKey('p06_continue')),
        );
        expect(button.height, moreOrLessEquals(52, epsilon: 1));
        expect(button.width, moreOrLessEquals(350, epsilon: 0.01));
        expect(tester.takeException(), isNull);

        await disposeApp(tester);
      },
    );
  });
}
