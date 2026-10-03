// P15 · Child profile — view-layer (widget) proofs.
//
// Geometry is measured against `design/screens/light/P15-child-profile.png`
// ÷ 3 (390×844 logical), never against a re-derived expectation:
//
//   ```
//   47…211  hero card          (164)   20 + 64 avatar + 10 + 30 + 20 + 20
//   227…309 three stat tiles    (82)   12 + 26 + 2×16 + 12  (grid: all equal)
//   325…441 Pip card            (116)  16 + 84 + 16
//   457…637 three list rows     (180)  3 × 60
//   653…733 danger card         (80)   16 + 48 + 16
//   ```
//
// Fonts are the bundled Inter/Nunito (`FontLoader`), so the measurements are
// the ones a device renders.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/family/domain/entities/child_profile.dart';
import 'package:nestling/features/family/presentation/widgets/child_profile_body.dart';

import '../../test_scope.dart';

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

ChildProfile _profile(WidgetTester tester) =>
    tester.widget<ChildProfileBody>(find.byType(ChildProfileBody)).profile;

/// Lets real-async Drift work (the remove write and the stream re-emit)
/// complete inside a widget test, where plain `pump` only advances the fake
/// clock — the same helper `p04_bugs_test.dart` uses.
Future<void> _flushDrift(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump();
}

void main() {
  setUpAll(_loadBundledFonts);

  group('P15 card bands match the design', () {
    testWidgets('hero, stats, Pip, list and danger rects', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/child-profile');
      expect(_profile(tester).child.nickname, 'Maya');

      final hero = tester.getRect(find.byKey(const Key('p15-hero')));
      final stats = tester.getRect(find.byKey(const Key('p15-stat-quests')));
      final pip = tester.getRect(find.byKey(const Key('p15-pip')));
      final list = tester.getRect(find.byKey(const Key('p15-row-pin')));
      final danger = tester.getRect(find.byKey(const Key('p15-danger')));

      // `NestList` is one surface card; its first row's top IS the card top.
      final listCard = tester.getRect(find.byType(NestList));

      expect(hero.top, closeTo(47, 0.01));
      expect(hero.height, closeTo(164, 0.01));
      expect(stats.top, closeTo(227, 0.01));
      expect(stats.height, closeTo(82, 0.01));
      expect(pip.top, closeTo(325, 0.01));
      expect(pip.height, closeTo(116, 0.01));
      expect(listCard.top, closeTo(457, 0.01));
      expect(listCard.height, closeTo(180, 0.01));
      expect(list.top, closeTo(457, 0.01));
      expect(danger.top, closeTo(653, 0.01));
      expect(danger.height, closeTo(80, 0.01));

      // ALIGNMENT (owner rule): 20 px gutters, every band on the same edges.
      // The stats row spans the gutter-to-gutter width like every other band
      // (its first tile starts on the left gutter, its last ends on the right).
      final lastTile = tester.getRect(find.byKey(const Key('p15-stat-days')));
      for (final rect in <Rect>[hero, pip, listCard, danger]) {
        expect(rect.left, closeTo(NestSpacing.padSide, 0.01));
        expect(rect.right, closeTo(390 - NestSpacing.padSide, 0.01));
      }
      expect(stats.left, closeTo(NestSpacing.padSide, 0.01));
      expect(lastTile.right, closeTo(390 - NestSpacing.padSide, 0.01));

      await disposeApp(tester);
    });

    testWidgets('stat tiles are 110 wide with a 10 gap', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/child-profile');

      final quests = tester.getRect(find.byKey(const Key('p15-stat-quests')));
      final coins = tester.getRect(find.byKey(const Key('p15-stat-coins')));
      final days = tester.getRect(find.byKey(const Key('p15-stat-days')));

      expect(quests.width, closeTo(110, 0.01));
      expect(coins.width, closeTo(110, 0.01));
      expect(days.width, closeTo(110, 0.01));
      // `.stats { grid-template-columns: 1fr 1fr 1fr; gap: 10 }`.
      expect(coins.left - quests.right, closeTo(10, 0.01));
      expect(days.left - coins.right, closeTo(10, 0.01));
      // A grid stretches every tile to the tallest: the "Quests this week"
      // label wraps to two lines, so all three are 82 tall.
      expect(coins.height, closeTo(quests.height, 0.01));
      expect(days.height, closeTo(quests.height, 0.01));

      await disposeApp(tester);
    });
  });

  group('P15 copy is the design copy', () {
    testWidgets('exact strings, U+2013 / U+00B7 / U+203A included', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/child-profile');

      expect(find.text('Maya'), findsOneWidget);
      expect(
        find.text('Age 7\u20139 \u00B7 Pip is a Fledgling'),
        findsOneWidget,
      );
      expect(find.text('Pip \u00B7 Fledgling'), findsOneWidget);
      expect(find.text('Evolves at 250 total coins'), findsOneWidget);
      expect(find.text('175 of 250 \u00B7 70%'), findsOneWidget);
      // Scoped to the rows: the tab bar repeats "Quests" and "Money".
      Finder inRow(String key, String text) =>
          find.descendant(of: find.byKey(Key(key)), matching: find.text(text));
      expect(find.text('Kid PIN'), findsOneWidget);
      expect(
        inRow('p15-row-pin', 'On \u00B7 Maya knows their code'),
        findsOneWidget,
      );
      expect(inRow('p15-row-pin', 'Change \u203A'), findsOneWidget);
      expect(inRow('p15-row-quests', 'Quests'), findsOneWidget);
      expect(
        inRow('p15-row-quests', '6 active \u00B7 4 daily, 2 weekly'),
        findsOneWidget,
      );
      expect(inRow('p15-row-money', 'Pocket money'), findsOneWidget);
      expect(
        find.text('\u00A33.00 a week \u00B7 Owed \u00A34.20'),
        findsOneWidget,
      );
      expect(find.text('Remove Maya from family'), findsOneWidget);

      await disposeApp(tester);
    });
  });

  group('P15 Pip slot', () {
    testWidgets("renders Maya's own Pip at the design's 84 px", (tester) async {
      final handle = tester.ensureSemantics();
      await setUpTestScope();
      await pumpAppRoute(tester, '/child-profile');

      final pip = tester.widget<PipAvatar>(find.byType(PipAvatar));
      expect(pip.style, PipStyle.mochi);
      expect(pip.skin, PipSkin.sunny);
      expect(pip.accessory, PipAccessory.none);
      expect(pip.stage, 3);
      expect(pip.size, 84);

      // PIP ruling: the child carries Pip, so the label names HER Pip — the
      // same "a fledgling" wording P08's kid card announces.
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics && w.properties.label == "Maya's Pip, a fledgling",
        ),
        findsOneWidget,
      );

      final progress = tester.widget<NestProgress>(find.byType(NestProgress));
      expect(progress.fraction, closeTo(0.7, 0.001));
      expect(progress.kid, isFalse);

      // `.piprow img { width: 84px }`, centred in the row's cross axis.
      final art = tester.getRect(find.byType(PipAvatar));
      expect(art.width, closeTo(84, 0.01));
      expect(art.height, closeTo(84, 0.01));
      expect(art.left, closeTo(36, 0.01));

      handle.dispose();
      await disposeApp(tester);
    });
  });

  group('P15 navigation', () {
    testWidgets('the three rows go to PIN, the library and the ledger', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/child-profile');

      await tester.tap(find.byKey(const Key('p15-row-quests')));
      await tester.pumpAndSettle();
      expect(pushedPath(tester), '/quests');
      await disposeApp(tester);

      await setUpTestScope();
      await pumpAppRoute(tester, '/child-profile');
      await tester.tap(find.byKey(const Key('p15-row-money')));
      await tester.pumpAndSettle();
      expect(pushedPath(tester), '/money');
      await disposeApp(tester);

      await setUpTestScope();
      await pumpAppRoute(tester, '/child-profile');
      await tester.tap(find.byKey(const Key('p15-row-pin')));
      await tester.pumpAndSettle();
      expect(pushedPath(tester), '/kid-pin');
      await disposeApp(tester);
    });
  });

  group('P15 accessibility', () {
    testWidgets('every control exposes SemanticsAction.tap', (tester) async {
      final handle = tester.ensureSemantics();
      await setUpTestScope();
      await pumpAppRoute(tester, '/child-profile');

      for (final key in <Key>[
        const Key('p15-row-pin'),
        const Key('p15-row-quests'),
        const Key('p15-row-money'),
        const Key('p15-remove'),
      ]) {
        final node = tester.getSemantics(find.byKey(key));
        final data = node.getSemanticsData();
        expect(
          data.hasAction(SemanticsAction.tap),
          isTrue,
          reason: '$key must be operable by VoiceOver/TalkBack',
        );
        expect(data.flagsCollection.isButton, isTrue, reason: '$key');
      }

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('performAction(tap) on the row drives the real navigation', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await setUpTestScope();
      await pumpAppRoute(tester, '/child-profile');

      tester.semantics.performAction(
        find.semantics.byLabel('Pocket money'),
        SemanticsAction.tap,
      );
      await tester.pumpAndSettle();
      expect(pushedPath(tester), '/money');

      handle.dispose();
      await disposeApp(tester);
    });
  });

  group('P15 remove flow', () {
    testWidgets('confirm removes the child and the screen shows no-children', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/child-profile');
      expect(_profile(tester).child.id, 'maya');

      await tester.tap(find.byKey(const Key('p15-remove')));
      await tester.pumpAndSettle();
      expect(find.text('Remove Maya?'), findsOneWidget);
      expect(
        find.text(
          'They will lose their quests, coins and Pip. '
          'This cannot be undone.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(NestButton, 'Remove'));
      await tester.pumpAndSettle();
      await _flushDrift(tester);
      await tester.pumpAndSettle();

      // The watch streams re-emitted and the selection fell through to the
      // next child in ADDED order (CHILD ORDER ruling): Leo, not an empty
      // screen — and Leo's own Pip (bolt · sky · stage 2), not Maya's.
      expect(find.text('Maya'), findsNothing);
      expect(_profile(tester).child.id, 'leo');
      expect(
        find.text('Age 4\u20136 \u00B7 Pip is a Hatchling'),
        findsOneWidget,
      );
      final pip = tester.widget<PipAvatar>(find.byType(PipAvatar));
      expect(pip.style, PipStyle.bolt);
      expect(pip.skin, PipSkin.sky);
      expect(pip.stage, 2);
      expect(find.text('Remove Leo from family'), findsOneWidget);

      // Removing the last child empties the family.
      await tester.tap(find.byKey(const Key('p15-remove')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(NestButton, 'Remove'));
      await tester.pumpAndSettle();
      await _flushDrift(tester);
      await tester.pumpAndSettle();

      expect(find.text('No children yet'), findsOneWidget);
      expect(
        find.text('Add your first child and their Pip will start to hatch.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('p15-hero')), findsNothing);

      await disposeApp(tester);
    });

    testWidgets('Cancel keeps the child', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/child-profile');

      await tester.tap(find.byKey(const Key('p15-remove')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(NestButton, 'Cancel'));
      await tester.pumpAndSettle();
      await _flushDrift(tester);

      expect(find.text('Remove Maya?'), findsNothing);
      expect(_profile(tester).child.id, 'maya');
      expect(find.byKey(const Key('p15-hero')), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('the empty state CTA opens the add-children funnel', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/child-profile');

      for (final nickname in <String>['Maya', 'Leo']) {
        expect(find.text('Remove $nickname from family'), findsOneWidget);
        await tester.tap(find.byKey(const Key('p15-remove')));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(NestButton, 'Remove'));
        await tester.pumpAndSettle();
        await _flushDrift(tester);
        await tester.pumpAndSettle();
      }

      expect(find.text('No children yet'), findsOneWidget);
      await tester.tap(find.widgetWithText(NestButton, 'Add a child'));
      await tester.pumpAndSettle();
      expect(pushedPath(tester), '/add-children');

      await disposeApp(tester);
    });
  });

  group('P15 holds up at other sizes', () {
    testWidgets('320 wide: no overflow', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/child-profile');
      // [pumpAppRoute] pins 390x844; re-size and settle afterwards.
      tester.view.physicalSize = const Size(320 * 3, 844 * 3);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
      // The stat tiles shrink with the screen (never a fixed 110).
      final quests = tester.getRect(find.byKey(const Key('p15-stat-quests')));
      expect(quests.width, closeTo((320 - 40 - 20) / 3, 0.01));
      await disposeApp(tester);
    });

    testWidgets('text scale 1.3: no overflow', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await setUpTestScope();
      await pumpAppRoute(tester, '/child-profile');
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  });
}
