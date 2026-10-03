// P12 Money ledger — real-font geometry guard (orchestrator mandate).
//
// ORCHESTRATOR_NOTES.md (12:08 update, QA of `cmp_light_1`) mandates:
//
//   "Fix so every element is within ±1 px of the design. Add a real-font
//    geometry test pinning the title, segmented, owed card, goal card and
//    history tops."
//
// The pinned values are read off `design/screens/light/P12-money.png`
// (1170×2532 ÷ 3 = 390×844 logical) and cross-checked against
// `design/html-source/components.css`:
//
//   .status-bar  height 47px                       → title line box  55
//   .ptitle      padding-top 8px, 28/34            → segmented top  105
//   .scroll > * + *  margin-top 16px              → owed card top  173
//                                                  → goal card top  400
//                                                  → history top    504
//
// (verified by scanning the PNG: the segmented track's surface-2 begins at
// 315 px, the hero card's ink at 519 px, the goal card's white at 1200 px and
// the history card's white at 1512 px.)
//
// Real fonts are loaded (FontLoader, as
// `pocket_money_setup_view_geometry_test.dart` does): the Ahem fallback the
// rest of the suite runs under cannot catch a metric drift, and the goal /
// history card tops depend on the hero card's text height.
//
// The screen is NOT patched here — a test stage records a defect, the build
// stage fixes it. See docs/screens/P12/3_test.md.

import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';

import '../../test_scope.dart';

/// Design tops in logical pixels (PNG ÷ 3), from the CSS/PNG cross-check
/// above.
const double designTitleTop = 55;
const double designSegmentedTop = 105;
const double designOwedCardTop = 173;
const double designGoalCardTop = 400;
const double designHistoryTop = 504;

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

/// `/money` at 390×844 on the demo seed, real fonts loaded.
Future<void> _pumpLedger(WidgetTester tester) async {
  await setUpTestScope();
  await pumpAppRoute(tester, '/money');
}

/// The card that owns [text] (the shape, not the text).
Finder _cardOwning(String text) =>
    find.ancestor(of: find.text(text), matching: find.byType(NestCard)).first;

void main() {
  group('P12 Money ledger — design geometry at 390×844 (real fonts)', () {
    setUpAll(_loadBundledFonts);

    testWidgets('the status bar reserves the design 47 px', (tester) async {
      await _pumpLedger(tester);

      expect(
        tester.getSize(find.byType(NestStatusBar)).height,
        moreOrLessEquals(47, epsilon: 0.01),
      );
      await disposeApp(tester);
    });

    testWidgets('the title sits on the design top (55)', (tester) async {
      await _pumpLedger(tester);

      expect(
        tester.getRect(find.text('Pocket money')).top,
        moreOrLessEquals(designTitleTop, epsilon: 1),
        reason:
            'the design puts .ptitle straight after the 47 px status bar '
            '(+ its own 8 px padding-top); no extra spacer may sit between '
            'them',
      );
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('the segmented track sits on the design top (105)', (
      tester,
    ) async {
      await _pumpLedger(tester);

      expect(
        tester.getRect(find.byType(NestSegmented<String>)).top,
        moreOrLessEquals(designSegmentedTop, epsilon: 1),
      );
      expect(
        tester.getRect(find.byType(NestSegmented<String>)).height,
        moreOrLessEquals(52, epsilon: 0.01),
        reason: '.segmented is 4 + 44 + 4',
      );
      await disposeApp(tester);
    });

    testWidgets('the owed card sits on the design top (173)', (tester) async {
      await _pumpLedger(tester);

      expect(
        tester.getRect(_cardOwning('Maya is owed')).top,
        moreOrLessEquals(designOwedCardTop, epsilon: 1),
      );
      await disposeApp(tester);
    });

    testWidgets('the goal card sits on the design top (400)', (tester) async {
      await _pumpLedger(tester);

      expect(
        tester.getRect(_cardOwning('£15.50 saved · 62%')).top,
        moreOrLessEquals(designGoalCardTop, epsilon: 1),
      );
      await disposeApp(tester);
    });

    testWidgets('the history card sits on the design top (504)', (
      tester,
    ) async {
      await _pumpLedger(tester);

      expect(
        tester.getRect(_cardOwning('History')).top,
        moreOrLessEquals(designHistoryTop, epsilon: 1),
      );
      await disposeApp(tester);
    });

    testWidgets('the empty state uses the same title top (55)', (tester) async {
      final db = await setUpTestScope(seedDemo: false);
      // `Seed.empty` = onboarded parent, no children — without it the router
      // redirects `/money` to `/welcome`.
      await Seed.empty(db);
      await GetIt.instance<AppSession>().refresh();
      await pumpAppRoute(tester, '/money');

      // `_EmptyBody` repeats the status bar → spacer → title stack and must
      // land identically.
      expect(find.text('No pocket money yet'), findsOneWidget);
      expect(
        tester.getRect(find.text('Pocket money')).top,
        moreOrLessEquals(designTitleTop, epsilon: 1),
      );
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  });
}
