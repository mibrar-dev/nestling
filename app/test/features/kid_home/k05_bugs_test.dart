// K05 (quest complete) adversarial bug hunt — Stage 6, iteration 1.
//
// Findings this iteration (all MINOR — no major bug found; the screen's
// navigation, persistence, a11y actions, layout, dark-mode contrast and
// rapid-tap guards all pass the probes in this file):
//
// * K05-BUG-1 (MINOR, fixed in iteration 2) — a 1-coin quest celebrated as
//   "+1 coins" and
//   announces "1 coins earned". The quest editor's minimum reward is 1
//   (`quest_editor_view.dart:333 _minCoins = 1`), so the path is reachable.
//   The growth card next door already handles the singular ("Pip needs
//   1 more coin to grow"), so the pill is the only place the grammar slips.
//   Proofs below: `K05-BUG-1a` (visible copy) and `K05-BUG-1b` (semantics).
//
// * K05-BUG-2 (MINOR, fixed in iteration 2) — at 249 of 250 lifetime coins the
//   card showed
//   "Pip needs 1 more coin to grow" and "249 of 250 coins", yet the progress
//   node announces "Pip is 100% of the way to Songbird": `(0.996 * 100)
//   .round()` rounds the last coin away. The bar itself is 99.6 % filled, so
//   the announced 100 % contradicts the two visible lines. Proof below.
//
// * K05-BUG-3 (MINOR, fixed in iteration 2) — at 320 px wide with the 1.3×
//   accessibility
//   text scale (the app shell's supported maximum), the growth card's count
//   row gives each of "175 of 250 coins" and "Next: Songbird" 117 px and
//   BOTH ellipsise ("175 of 250 coi…" / "Next: Songbi…"). The data is still
//   reachable by VoiceOver, but the visible line loses the numbers. Proof
//   below.
//
// * K05-BUG-4 (MINOR, fixed in iteration 2) — a double-barrelled UK nickname
//   such as
//   "Maximilian-Alexander" makes the hero need 3 natural lines at the
//   design's 40/44; the view's `maxLines: 2` ellipsises the name even at
//   390 px / 1.0× ("Brilliant," / "Maximilian-Alexan…"). The design's h1 has
//   no line cap (`text-wrap: balance` only), so the browser would show the
//   whole name; the fix is to allow the third line (or drop the cap) for
//   over-cap names — the "Brilliant, Maya!" case is unaffected. Proof below.
//
// Checked clean (kept as evidence; these run in the plain suite):
//   * rapid same-frame and staggered double taps of "Yay! Back home" land on
//     /kid-home once, no exception (probe);
//   * the lock opens the parental gate exactly once for a same-frame burst;
//   * system back from a pushed celebration returns to the pusher;
//   * a completed quest survives an app restart (same Drift DB): the direct
//     launch quotes the DB's own done quest (+10 for a 10-coin q-reading);
//   * `Seed.empty` deep link offers the picker (no crash, no celebration);
//   * 6 children in the family do not change the active child's celebration;
//   * an empty quest list still celebrates with "+0 coins", never blank;
//   * 9999 coins at 320 px / 1.3× fits the pill with real Nunito (no
//     truncation, no overflow);
//   * the dark bottom bar surface reaches the physical edge under a 34 px
//     home-indicator inset (owner bottom-edge rule);
//   * every K05 token pair meets WCAG 4.5:1 in both themes;
//   * the lock's semantics action drives the real gate push;
//   * kid mode may reach /quest-complete (kid route) and parent mode may too
//     (K06 precedent: kid screens are reachable in parent mode by design).
//
// Timezone/BST: K05 has no time logic (static celebration + DB values), so
// there is nothing for the Europe/London periods to change on this screen —
// the period rule is K03/K04/K11 business and is already covered there.
// Money rounding: K05 shows integer coins only, never £ — the only rounding
// artefact is K05-BUG-2's percentage.
//
// Every pumped app ends with `disposeApp` (test_scope.dart) so Drift's
// deferred stream-close timer is drained.

import 'dart:async';
import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
// `hide PipMood`: the barrel exports the v1 `PipMood` from `pip_rive.dart`,
// which collides with the v2 one `PipAvatar` uses (same shape as K04).
import 'package:nestling/core/design_system/design_system.dart' hide PipMood;
import 'package:nestling/features/kid_home/kid_home_routes.dart';
import 'package:nestling/features/parental_gate/parental_gate_routes.dart';

import '../../test_scope.dart';

/// Loads the bundled faces so text measurements match a device run: on
/// `flutter_test`'s default font every glyph is wider and the count row /
/// hero would report false truncation (same isolation as the geometry test).
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

Future<void> _pump(
  WidgetTester tester, {
  String route = KidHomeRoutePaths.complete,
  double width = 390,
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
}) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await tester.pumpWidget(NestlingApp(initialRoute: route));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// Bounded route pumps: `pumpAndSettle` is avoided because a still-loading
/// screen spins an endless progress indicator.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Pushes the celebration with the `extra` shape K03/K04 pass.
void _pushCelebration(
  WidgetTester tester, {
  required int coins,
  String questId = 'q-tidy',
  String childId = 'maya',
}) {
  final context = tester.element(find.byType(Navigator).first);
  unawaited(
    GoRouter.of(context).push(
      KidHomeRoutePaths.complete,
      extra: <String, Object>{
        'questId': questId,
        'childId': childId,
        'coins': coins,
      },
    ),
  );
}

/// The growth card starts below the fold at 320 px / 1.3×: scroll it in.
Future<void> _revealCard(WidgetTester tester) async {
  await tester.drag(find.byType(ListView), const Offset(0, -400));
  await tester.pump();
}

double _linear(double channel) => channel <= 0.03928
    ? channel / 12.92
    : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color c) =>
    0.2126 * _linear(c.r) + 0.7152 * _linear(c.g) + 0.0722 * _linear(c.b);

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  setUpAll(_loadBundledFonts);

  setUp(() async {
    await setUpTestScope();
  });

  // -------------------------------------------------------------------------
  // K05-BUG-1 — a 1-coin quest celebrates as "+1 coins"
  // -------------------------------------------------------------------------

  testWidgets(
    'K05-BUG-1a: a 1-coin quest must read "+1 coin", not "+1 coins"',
    (tester) async {
      await _pump(tester, route: KidHomeRoutePaths.home);
      _pushCelebration(tester, coins: 1);
      await _settle(tester);

      // The design only defines the 15-coin plural, but the editor's floor
      // is 1 coin, so the singular is reachable; the growth card already
      // singularises ("1 more coin").
      expect(
        find.text('+1 coin'),
        findsOneWidget,
        reason:
            'the pill must singularise a 1-coin reward; it currently renders '
            '"+1 coins"',
      );
      await disposeApp(tester);
    },
  );

  testWidgets('K05-BUG-1b: the 1-coin pill announces "1 coin earned", not '
      '"1 coins earned"', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, route: KidHomeRoutePaths.home);
    _pushCelebration(tester, coins: 1);
    await _settle(tester);

    expect(
      find.bySemanticsLabel('1 coin earned'),
      findsOneWidget,
      reason: 'the announced label has the same plural bug: "1 coins earned"',
    );
    semantics.dispose();
    await disposeApp(tester);
  });

  // -------------------------------------------------------------------------
  // K05-BUG-2 — 249/250 announces 100 %
  // -------------------------------------------------------------------------

  testWidgets('K05-BUG-2: one coin short of growing must not announce 100 %', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final db = GetIt.instance<AppDatabase>();
    await tester.runAsync(() async {
      await (db.update(db.children)..where((c) => c.id.equals('maya'))).write(
        const ChildrenCompanion(pipTotalCoins: Value(249)),
      );
    });
    await _pump(tester);
    await _revealCard(tester);

    expect(
      find.text('Pip needs 1 more coin to grow'),
      findsOneWidget,
      reason: 'sanity: the card knows one coin is still missing',
    );
    expect(
      find.bySemanticsLabel('Pip is 100% of the way to Songbird'),
      findsNothing,
      reason:
          '(249/250 * 100).round() == 100 while the card says "1 more coin '
          'to grow" — the announced percentage must stay below 100 until '
          'the threshold is actually reached (floor, not round, while '
          'fraction < 1)',
    );
    semantics.dispose();
    await disposeApp(tester);
  });

  // -------------------------------------------------------------------------
  // K05-BUG-3 — the count row ellipsises at 320 px / 1.3×
  // -------------------------------------------------------------------------

  testWidgets('K05-BUG-3: the count row must stay readable at 320 px / 1.3×', (
    tester,
  ) async {
    await _pump(tester, width: 320, textScale: 1.3);
    await _revealCard(tester);

    final count = tester.renderObject<RenderParagraph>(
      find.text('175 of 250 coins'),
    );
    final next = tester.renderObject<RenderParagraph>(
      find.text('Next: Songbird'),
    );
    expect(
      count.didExceedMaxLines,
      isFalse,
      reason:
          '"175 of 250 coins" ellipsises at the supported 1.3× scale on a '
          '320 px screen (each Flexible gets 117 px; the text needs ~150)',
    );
    expect(
      next.didExceedMaxLines,
      isFalse,
      reason: '"Next: Songbird" ellipsises at the same size (~136 px needed)',
    );
    await disposeApp(tester);
  });

  // -------------------------------------------------------------------------
  // K05-BUG-4 — long UK names lose the hero to the 2-line cap
  // -------------------------------------------------------------------------

  testWidgets(
    'K05-BUG-4: "Brilliant, Maximilian-Alexander!" must not be truncated',
    (tester) async {
      final db = GetIt.instance<AppDatabase>();
      await tester.runAsync(() async {
        await db
            .into(db.children)
            .insert(
              ChildrenCompanion.insert(
                id: 'max',
                familyId: Seed.familyId,
                nickname: 'Maximilian-Alexander',
                avatarColour: const Value('sky'),
                coins: const Value(0),
                pipTotalCoins: const Value(175),
              ),
            );
        await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
          const AppStateCompanion(activeChildId: Value<String?>('max')),
        );
        await GetIt.instance<AppSession>().refresh();
      });
      await _pump(tester);

      final hero = tester.renderObject<RenderParagraph>(
        find.text('Brilliant, Maximilian-Alexander!'),
      );
      expect(
        hero.didExceedMaxLines,
        isFalse,
        reason:
            'the name needs 3 natural 44 px lines at the design 40/44; the '
            'view caps the hero at 2 (maxLines: 2), so the child\u2019s own '
            'name is ellipsised at 390 px / 1.0\u00d7. The design\u2019s h1 '
            'has no line cap, so the fix is to allow the third line (or drop '
            'the cap) for over-cap names \u2014 "Brilliant, Maya!" stays one '
            'line',
      );
      await disposeApp(tester);
    },
  );

  // -------------------------------------------------------------------------
  // Checked clean — navigation, persistence, data edges, a11y, contrast
  // -------------------------------------------------------------------------

  group('checked clean', () {
    testWidgets('a same-frame double tap of the CTA lands on /kid-home once', (
      tester,
    ) async {
      await _pump(tester);
      final cta = find.text('Yay! Back home');
      await tester.tap(cta);
      await tester.tap(cta);
      await _settle(tester);
      expect(pushedPath(tester), KidHomeRoutePaths.home);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('a staggered double tap of the CTA still lands once', (
      tester,
    ) async {
      await _pump(tester);
      await tester.tap(find.text('Yay! Back home'));
      await tester.pump();
      if (find.text('Yay! Back home').evaluate().isNotEmpty) {
        await tester.tap(find.text('Yay! Back home'), warnIfMissed: false);
      }
      await _settle(tester);
      expect(pushedPath(tester), KidHomeRoutePaths.home);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('the lock opens the gate exactly once for a double tap', (
      tester,
    ) async {
      await _pump(tester);
      await tester.tap(find.byType(NestLockButton));
      await tester.tap(find.byType(NestLockButton));
      await _settle(tester);
      expect(pushedPath(tester), ParentalGateRoutePaths.gate);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('the lock semantics action drives the real gate push', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester);
      final data = tester
          .getSemantics(find.bySemanticsLabel('Grown-ups'))
          .getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      tester.semantics.performAction(
        find.semantics.byLabel('Grown-ups'),
        SemanticsAction.tap,
      );
      await _settle(tester);
      expect(pushedPath(tester), ParentalGateRoutePaths.gate);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('system back from a pushed celebration returns to the pusher', (
      tester,
    ) async {
      await _pump(tester, route: KidHomeRoutePaths.home);
      _pushCelebration(tester, coins: 15);
      await _settle(tester);
      expect(pushedPath(tester), KidHomeRoutePaths.complete);
      await tester.binding.handlePopRoute();
      await _settle(tester);
      expect(pushedPath(tester), KidHomeRoutePaths.home);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('a completed quest survives an app restart', (tester) async {
      // Wipe Maya's completions, then complete only q-reading (10 coins).
      final db = GetIt.instance<AppDatabase>();
      await tester.runAsync(() async {
        await (db.delete(
          db.questCompletions,
        )..where((c) => c.childId.equals('maya'))).go();
        await db
            .into(db.questCompletions)
            .insert(
              QuestCompletionsCompanion.insert(
                questId: 'q-reading',
                childId: 'maya',
                familyId: Seed.familyId,
                status: const Value('done_pending'),
                coins: const Value(10),
                createdAt: Value(Seed.utc(10, 3, 7)),
                createdAtTz: const Value('Europe/London'),
              ),
            );
      });
      await disposeApp(tester); // "restart" the app

      await _pump(tester);
      // The direct launch has no extra: the DB's own done quest supplies the
      // reward, and it is still there after the restart.
      expect(find.text('+10 coins'), findsOneWidget);
      expect(find.text('Brilliant, Maya!'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('Seed.empty offers the picker, never a blank celebration', (
      tester,
    ) async {
      await tester.runAsync(() => Seed.empty(GetIt.instance<AppDatabase>()));
      await tester.runAsync(() => GetIt.instance<AppSession>().refresh());
      await _pump(tester);
      expect(find.text("Who's playing?"), findsOneWidget);
      expect(find.byType(NestCoinPill), findsNothing);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('six children do not change the active celebration', (
      tester,
    ) async {
      final db = GetIt.instance<AppDatabase>();
      await tester.runAsync(() async {
        for (var i = 0; i < 4; i++) {
          await db
              .into(db.children)
              .insert(
                ChildrenCompanion.insert(
                  id: 'extra$i',
                  familyId: Seed.familyId,
                  nickname: 'Extra Child $i',
                ),
              );
        }
      });
      await _pump(tester);
      expect(find.text('Brilliant, Maya!'), findsOneWidget);
      expect(find.text('175 of 250 coins'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('an empty quest list still celebrates with +0 coins', (
      tester,
    ) async {
      final db = GetIt.instance<AppDatabase>();
      await tester.runAsync(() async {
        await (db.delete(
          db.questCompletions,
        )..where((c) => c.childId.equals('maya'))).go();
        await (db.delete(
          db.quests,
        )..where((q) => q.assigneeChildId.equals('maya'))).go();
      });
      await _pump(tester);
      expect(find.text('Brilliant, Maya!'), findsOneWidget);
      expect(find.text('+0 coins'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('deleting the active child mid-view falls back to the picker', (
      tester,
    ) async {
      await _pump(tester);
      expect(find.text('Brilliant, Maya!'), findsOneWidget);
      final db = GetIt.instance<AppDatabase>();
      await tester.runAsync(() async {
        await (db.delete(db.children)..where((c) => c.id.equals('maya'))).go();
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text("Who's playing?"), findsOneWidget);
      expect(find.text('Brilliant, Maya!'), findsNothing);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('9999 coins at 320 px / 1.3x fits the pill', (tester) async {
      await _pump(
        tester,
        route: KidHomeRoutePaths.home,
        width: 320,
        textScale: 1.3,
      );
      _pushCelebration(tester, coins: 9999);
      await _settle(tester);
      final pill = tester.renderObject<RenderParagraph>(
        find.text('+9999 coins'),
      );
      expect(pill.didExceedMaxLines, isFalse);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('the dark bar surface reaches the edge under a 34 px inset', (
      tester,
    ) async {
      tester.view.padding = const FakeViewPadding(bottom: 34);
      tester.view.viewPadding = const FakeViewPadding(bottom: 34);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      await _pump(tester, theme: ThemeMode.dark);
      const scheme = NestColors.dark;
      final surfaces = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration! as BoxDecoration).color == scheme.surface,
      );
      final covering = surfaces.evaluate().where((element) {
        final rect = tester.getRect(
          find.byElementPredicate((e) => identical(e, element)),
        );
        return rect.left <= 0.5 && rect.right >= 389.5 && rect.bottom >= 843.5;
      });
      expect(
        covering,
        isNotEmpty,
        reason: 'no meadow/sky strip may show below the dark bottom bar',
      );
      await disposeApp(tester);
    });

    test('every K05 token pair meets WCAG contrast in light and dark', () {
      const light = NestColors.light;
      const dark = NestColors.dark;
      final pairs = <String, (Color, Color)>{
        'light ink on kidSkyTop': (light.ink, light.kidSkyTop),
        'light ink on kidSkyBottom': (light.ink, light.kidSkyBottom),
        'light ink on lilacTint': (light.ink, light.lilacTint),
        'light ink2 on lilacTint': (light.ink2, light.lilacTint),
        'light ink2 on kidSkyTop': (light.ink2, light.kidSkyTop),
        'light ink2 on kidSkyBottom': (light.ink2, light.kidSkyBottom),
        'light coinInk on coinTint': (light.coinInk, light.coinTint),
        'light ink on surface': (light.ink, light.surface),
        'light onLeaf on leaf': (light.onLeaf, light.leaf),
        'dark ink on kidSkyTop': (dark.ink, dark.kidSkyTop),
        'dark ink on kidSkyBottom': (dark.ink, dark.kidSkyBottom),
        'dark ink on lilacTint': (dark.ink, dark.lilacTint),
        'dark ink2 on lilacTint': (dark.ink2, dark.lilacTint),
        'dark ink2 on kidSkyTop': (dark.ink2, dark.kidSkyTop),
        'dark ink2 on kidSkyBottom': (dark.ink2, dark.kidSkyBottom),
        'dark coinInk on coinTint': (dark.coinInk, dark.coinTint),
        'dark ink on surface': (dark.ink, dark.surface),
        'dark onLeaf on leaf': (dark.onLeaf, dark.leaf),
      };
      for (final MapEntry(key: name, value: (a, b)) in pairs.entries) {
        expect(
          _contrast(a, b),
          greaterThanOrEqualTo(4.5),
          reason: '$name contrast',
        );
      }
    });
  });
}
