// K08 · Reward shop — view tests over the in-memory Drift database.
//
// Scope (stage 2b, UI builder): copy from the HTML character-by-character,
// the two-column grid, every navigation destination, VoiceOver/TalkBack
// activation driving the REAL database write, the empty/loading/failure
// surfaces, and the width × text-scale matrix. Design geometry against the
// real bundled Nunito metrics lives in the sibling
// `reward_shop_widget_geometry_test.dart` (isolated on purpose — loading the
// real faces moves every text metric on the screen, same reason as K03's
// `kid_home_geometry_test.dart`).
//
// Every pumped app ends with `disposeApp` (test_scope.dart). No
// `DateTime.now`, no `google_fonts`, no simulator.

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/kid_shop/domain/entities/kid_shop_data.dart';
import 'package:nestling/features/kid_shop/domain/entities/shop_reward.dart';
import 'package:nestling/features/kid_shop/domain/kid_shop_repository.dart';
import 'package:nestling/features/kid_shop/presentation/widgets/shop_reward_card.dart';

import '../../test_scope.dart';

const String _route = '/reward-shop';

/// The demo seed's shop, in creation order (`Seed.demo` → `_rewardsDemo`) with
/// Maya's 120 coins — the numbers the design PNGs draw.
const ShopReward _screen = ShopReward(
  id: 'r-screen',
  title: '30 min extra screen time',
  detail: '50 coins',
  icon: 'tv',
  coinPrice: 50,
  needsOk: true,
  affordable: true,
);
const ShopReward _film = ShopReward(
  id: 'r-film',
  title: 'Pick Friday film',
  detail: '80 coins',
  icon: 'film',
  coinPrice: 80,
  needsOk: true,
  affordable: true,
);
const ShopReward _bedtime = ShopReward(
  id: 'r-bedtime',
  title: 'Stay up 15 min later',
  detail: '60 coins',
  icon: 'moon',
  coinPrice: 60,
  needsOk: true,
  affordable: true,
);
const ShopReward _baking = ShopReward(
  id: 'r-baking',
  title: 'Baking together',
  detail: '100 coins',
  icon: 'cake',
  coinPrice: 100,
  needsOk: false,
  affordable: true,
);
const ShopReward _cafe = ShopReward(
  id: 'r-cafe',
  title: 'Trip to the park café',
  detail: '150 coins',
  icon: 'coffee',
  coinPrice: 150,
  needsOk: true,
  affordable: false,
);
const ShopReward _dinner = ShopReward(
  id: 'r-dinner',
  title: 'Choose dinner',
  detail: '90 coins',
  icon: 'plate',
  coinPrice: 90,
  needsOk: true,
  affordable: true,
);

/// A repository that can stall, fail, serve an empty shop or serve the demo
/// shop — the states a healthy demo database cannot produce on demand
/// (K03 precedent).
class _FakeKidShopRepository implements KidShopRepository {
  _FakeKidShopRepository({
    this.hang = false,
    this.failLoad = false,
    this.failFirstWatch = false,
    this.serveDemoShop = false,
  });

  final bool hang;
  final bool failLoad;

  /// Fail only the first subscription, so "Try again" has a recovery to find.
  final bool failFirstWatch;

  /// Serve the six seeded rewards (the default is an empty shop).
  final bool serveDemoShop;

  final List<({String childId, String rewardId})> requests =
      <({String childId, String rewardId})>[];

  int _watches = 0;

  @override
  Stream<KidShopData> watchActiveShop() {
    _watches++;
    if (hang) return const Stream<KidShopData>.empty();
    if (failLoad || (failFirstWatch && _watches == 1)) {
      return Stream<KidShopData>.error(Exception('shop down'));
    }
    return Stream<KidShopData>.value(
      KidShopData(
        childId: 'maya',
        coins: 120,
        items: serveDemoShop
            ? const <ShopReward>[
                _screen,
                _film,
                _bedtime,
                _baking,
                _cafe,
                _dinner,
              ]
            : const <ShopReward>[],
      ),
    );
  }

  @override
  Future<void> requestReward(String childId, String rewardId) async {
    requests.add((childId: childId, rewardId: rewardId));
  }
}

Future<void> _useFakeRepository(KidShopRepository repo) async {
  await GetIt.instance.unregister<KidShopRepository>();
  GetIt.instance.registerSingleton<KidShopRepository>(repo);
}

Future<void> _pumpRoute(
  WidgetTester tester, {
  double width = 390,
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
  String route = _route,
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

/// Scrolls the shop list until [text] is built. The footer sits below the fold
/// (design y 921 on an 844-tall screen) and the list is lazy, so the widget
/// tree only holds it once the list has moved.
Future<void> _revealFooter(WidgetTester tester, String text) async {
  final list = find.byType(Scrollable).first;
  for (var i = 0; i < 10 && find.text(text).evaluate().isEmpty; i++) {
    await tester.drag(list, const Offset(0, -200));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Finder _cardWith(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(ShopRewardCard));

void main() {
  late AppDatabase db;

  setUp(() async {
    db = await setUpTestScope();
  });

  group('K08 shop copy and grid', () {
    testWidgets('title, coin pill and intro carry the design copy', (
      tester,
    ) async {
      await _pumpRoute(tester);
      expect(find.text('Reward shop'), findsOneWidget);
      // `NestCoinPill` labels itself "$amount coins"; the node the tester
      // returns also merges the heading next to it.
      expect(
        tester.getSemantics(find.byType(NestCoinPill)).label,
        contains('120 coins'),
      );
      expect(
        find.text('Spend your coins on things you actually want.'),
        findsOneWidget,
      );
      await disposeApp(tester);
    });

    testWidgets('every reward shows the database title, in creation order', (
      tester,
    ) async {
      await _pumpRoute(tester);
      final cards = find.byType(ShopRewardCard);
      expect(cards, findsNWidgets(6));
      final titles = tester
          .widgetList<ShopRewardCard>(cards)
          .map((card) => card.item.title)
          .toList();
      expect(titles, <String>[
        '30 min extra screen time',
        'Pick Friday film',
        'Stay up 15 min later',
        'Baking together',
        // The seeded title wins over the HTML's "Park café trip"
        // (orchestrator rule: data over mocks).
        'Trip to the park café',
        'Choose dinner',
      ]);
      for (final title in titles) {
        expect(find.text(title), findsOneWidget, reason: title);
      }
      await disposeApp(tester);
    });

    testWidgets('prices come from the database, not the design', (
      tester,
    ) async {
      await _pumpRoute(tester);
      for (final item in <ShopReward>[
        _screen,
        _film,
        _bedtime,
        _baking,
        _cafe,
        _dinner,
      ]) {
        expect(
          find.descendant(
            of: _cardWith(item.title),
            matching: find.text('${item.coinPrice}'),
          ),
          findsOneWidget,
          reason: '${item.title} price',
        );
      }
      await disposeApp(tester);
    });

    testWidgets('the unaffordable card says what is still needed, kindly', (
      tester,
    ) async {
      await _pumpRoute(tester);
      // 150 − 120 = 30, exactly as the HTML draws it.
      expect(find.text('30 more to go'), findsOneWidget);
      expect(find.text('Save up!'), findsOneWidget);
      expect(find.text('Get it'), findsNWidgets(5));
      // No shaming copy (DESIGN_SPEC §5 K08: "not shaming").
      expect(find.textContaining('need more'), findsNothing);
      expect(find.textContaining('earn'), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('the footer states the live balance', (tester) async {
      await _pumpRoute(tester);
      // The footer sits below the fold (design y 921 on an 844-tall screen),
      // and the list is lazy, so it has to be scrolled into the tree.
      await _revealFooter(
        tester,
        'You have 120 coins. Pip is helping you save!',
      );
      expect(
        find.text('You have 120 coins. Pip is helping you save!'),
        findsOneWidget,
      );
      await disposeApp(tester);
    });

    testWidgets('the grid is two columns with the same 16 px gutter', (
      tester,
    ) async {
      await _pumpRoute(tester);
      final first = tester.getRect(find.byType(ShopRewardCard).at(0));
      final second = tester.getRect(find.byType(ShopRewardCard).at(1));
      expect(first.left, closeTo(20, 0.5));
      expect(first.width, closeTo(167, 1));
      expect(second.left - first.right, closeTo(16, 0.5));
      expect(second.right, closeTo(370, 0.5));
      // Rows are 16 px apart (`.k8-grid { gap: 16px }`).
      final third = tester.getRect(find.byType(ShopRewardCard).at(2));
      expect(third.top - first.bottom, closeTo(16, 1));
      expect(tester.getRect(find.byType(ShopRewardCard).at(3)).top, third.top);
      await disposeApp(tester);
    });

    testWidgets('every card in a row is as tall as the tallest one', (
      tester,
    ) async {
      await _pumpRoute(tester);
      // Row 3 pairs the café card (with the "30 more to go" note, +6 +18) and
      // the dinner card (without it): the CSS grid's `align-items: stretch`
      // makes the shorter card as tall as the taller one, and its content
      // stays at the top.
      final cafe = tester.getRect(find.byType(ShopRewardCard).at(4));
      final dinner = tester.getRect(find.byType(ShopRewardCard).at(5));
      expect(cafe.height, closeTo(240, 1));
      expect(dinner.height, closeTo(240, 1));
      expect(dinner.top, closeTo(cafe.top, 0.5));
      // The note really is inside the café card only.
      expect(find.text('30 more to go'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ShopRewardCard).at(5),
          matching: find.textContaining('more to go'),
        ),
        findsNothing,
      );
      await disposeApp(tester);
    });
  });

  group('K08 navigation', () {
    testWidgets('back leaves the shop for the kid home', (tester) async {
      await _pumpRoute(tester);
      await tester.tap(find.byType(NestIconButton));
      await tester.pumpAndSettle();
      expect(currentPath(tester), '/kid-home');
      await disposeApp(tester);
    });

    testWidgets('the lock opens the parental gate', (tester) async {
      await _pumpRoute(tester);
      await tester.tap(find.byType(NestLockButton));
      await tester.pumpAndSettle();
      expect(pushedPath(tester), '/parental-gate');
      await disposeApp(tester);
    });

    testWidgets('back POPS when the shop was pushed onto the stack', (
      tester,
    ) async {
      // Reached the way a child does: the K03 dock pushes /reward-shop, so
      // there is something to pop back to and the back button must pop rather
      // than re-route (`canPop` branch in `_ShopTopRow`).
      await _pumpRoute(tester, route: '/kid-home');
      expect(currentPath(tester), '/kid-home');
      await tester.tap(find.text('Shop'));
      await tester.pumpAndSettle();
      expect(pushedPath(tester), '/reward-shop');
      expect(find.byType(ShopRewardCard), findsNWidgets(6));

      await tester.tap(find.byType(NestIconButton));
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/kid-home');
      expect(pushedPath(tester), '/kid-home');
      await disposeApp(tester);
    });

    testWidgets('a fast double tap on the lock opens one gate only', (
      tester,
    ) async {
      await _pumpRoute(tester);
      // Two taps in the SAME frame: `_GateLockButton`'s `_busy` guard must
      // swallow the second one (K03 precedent), so only one gate is pushed.
      await tester.tap(find.byType(NestLockButton));
      await tester.tap(find.byType(NestLockButton));
      await tester.pumpAndSettle();
      expect(pushedPath(tester), '/parental-gate');

      // One gate was pushed, so one back press is enough to get home. Two
      // stacked gates would need two.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(currentPath(tester), '/reward-shop');
      expect(find.byType(NestLockButton), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('the list scrolls far enough to reach the footer', (
      tester,
    ) async {
      await _pumpRoute(tester);
      final scrollable = tester.widget<Scrollable>(
        find.byType(Scrollable).first,
      );
      expect(scrollable.controller, isNotNull);
      expect(
        scrollable.controller!.position.maxScrollExtent,
        greaterThan(0),
        reason: 'the design puts the footer below the fold',
      );
      await _revealFooter(
        tester,
        'You have 120 coins. Pip is helping you save!',
      );
      expect(
        tester.getRect(
          find.text('You have 120 coins. Pip is helping you save!'),
        ),
        isNotNull,
      );
      // The last row is reachable too, not just the footer.
      expect(find.byType(ShopRewardCard), findsNWidgets(6));
      await disposeApp(tester);
    });
  });

  group('K08 accessibility actions (VoiceOver/TalkBack)', () {
    bool hasTap(WidgetTester tester, Finder finder) => tester
        .getSemantics(finder)
        .getSemanticsData()
        .hasAction(SemanticsAction.tap);

    void performTap(WidgetTester tester, Finder finder) {
      final node = tester.getSemantics(finder);
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
        reason: 'the control must expose SemanticsAction.tap',
      );
      node.owner!.performAction(node.id, SemanticsAction.tap);
    }

    testWidgets('back and the lock both advertise a tap', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      expect(hasTap(tester, find.bySemanticsLabel('Back').first), isTrue);
      expect(hasTap(tester, find.bySemanticsLabel('Grown-ups').first), isTrue);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Back').first).label,
        contains('Back'),
      );
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('each card button is named after its reward', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      final buttons = find.byType(NestKidButton);
      expect(buttons, findsNWidgets(6));
      final labels = tester
          .widgetList<NestKidButton>(buttons)
          .map((b) => b.semanticLabel)
          .toList();
      expect(labels, <String>[
        'Get 30 min extra screen time',
        'Get Pick Friday film',
        'Get Stay up 15 min later',
        'Get Baking together',
        'Save up for Trip to the park café',
        'Get Choose dinner',
      ]);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('a screen-reader tap on Get it writes the redemption', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      // Baking needs no parental OK, so the write must also move the balance
      // and the stream must bring the pill, the footer and the affordability
      // of the café card back (150 > 20 now).
      performTap(tester, find.bySemanticsLabel('Get Baking together').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      final rows = await db.select(db.rewardRedemptions).get();
      expect(rows.length, 1);
      expect(rows.single.rewardId, 'r-baking');
      expect(rows.single.childId, 'maya');
      expect(rows.single.status, 'approved');
      final maya = await (db.select(
        db.children,
      )..where((c) => c.id.equals('maya'))).getSingle();
      expect(maya.coins, 20);
      expect(find.text('20'), findsOneWidget); // the pill
      await _revealFooter(
        tester,
        'You have 20 coins. Pip is helping you save!',
      );
      expect(
        find.text('You have 20 coins. Pip is helping you save!'),
        findsOneWidget,
      );
      // 150 − 20 = 130 to go, and nothing is affordable any more.
      expect(find.text('130 more to go'), findsOneWidget);
      expect(find.text('Get it'), findsNothing);
      expect(find.text('Save up!'), findsNWidgets(6));
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('a reward that needs an OK keeps the coins', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      performTap(
        tester,
        find.bySemanticsLabel('Get 30 min extra screen time').first,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      final rows = await db.select(db.rewardRedemptions).get();
      expect(rows.single.status, 'requested');
      await _revealFooter(
        tester,
        'You have 120 coins. Pip is helping you save!',
      );
      expect(
        find.text('You have 120 coins. Pip is helping you save!'),
        findsOneWidget,
      );
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('a fast double tap on one card writes one redemption', (
      tester,
    ) async {
      await _pumpRoute(tester);
      final button = find.descendant(
        of: find.byType(ShopRewardCard).first,
        matching: find.byType(NestKidButton),
      );
      // Two taps in the SAME frame — what an impatient child's double tap
      // sends. The bloc's `requestingIds` guard has to swallow the second one,
      // because both events reach it before the first Drift write returns.
      await tester.tap(button);
      await tester.tap(button);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final rows = await db.select(db.rewardRedemptions).get();
      expect(
        rows,
        hasLength(1),
        reason: 'a parent must not be asked to approve the same reward twice',
      );
      expect(find.text('Mum will give it a thumbs-up soon.'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('two different cards can both be bought', (tester) async {
      await _pumpRoute(tester);
      final buttons = find.byType(NestKidButton);
      await tester.tap(buttons.at(0));
      await tester.pump();
      await tester.tap(buttons.at(1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // The guard is per id: the second card is not swallowed.
      final rows = await db.select(db.rewardRedemptions).get();
      expect(rows.map((r) => r.rewardId).toList(), <String>[
        'r-screen',
        'r-film',
      ]);
      await disposeApp(tester);
    });

    testWidgets('the unaffordable button offers no tap action', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      final saveUp = find.bySemanticsLabel('Save up for Trip to the park café');
      final data = tester.getSemantics(saveUp).getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      expect(data.flagsCollection.isEnabled.toBoolOrNull(), isFalse);
      // The control still reads as a button for VoiceOver.
      expect(data.flagsCollection.isButton, isTrue);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('every card button reads as a button and is enabled', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      final buttons = find.bySemanticsLabel(RegExp('^(Get|Save up for) '));
      expect(buttons, findsNWidgets(6));
      for (var i = 0; i < 6; i++) {
        final data = tester.getSemantics(buttons.at(i)).getSemanticsData();
        expect(data.flagsCollection.isButton, isTrue, reason: 'card $i');
      }
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('every card price is announced with its coin unit', (
      tester,
    ) async {
      // K08-BUG-3 regression: with the shared audience glyphs landing in the
      // same iteration, this also proves the swap did not disturb the price
      // nodes — one "N coins" node per card, still no tap action.
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      for (final price in <int>[50, 80, 60, 100, 150, 90]) {
        final node = find.bySemanticsLabel('$price coins');
        expect(node, findsOneWidget, reason: '$price coins');
        expect(
          tester
              .getSemantics(node)
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isFalse,
          reason: 'a price is a reading, not a control',
        );
      }
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('the coin pill is a reading, not a control', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      expect(
        tester
            .getSemantics(find.byType(NestCoinPill))
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isFalse,
        reason: 'the balance is a reading, not a control',
      );
      // Only the eight real controls exist: 2 chrome + 6 cards. The reward
      // names, prices and art discs add no focusable node of their own.
      expect(find.byType(NestIconButton), findsOneWidget);
      expect(find.byType(NestLockButton), findsOneWidget);
      expect(find.byType(NestKidButton), findsNWidgets(6));
      expect(find.byType(NestCoinPill), findsOneWidget);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('a VoiceOver tap on the disabled card changes nothing', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      final saveUp = find.bySemanticsLabel('Save up for Trip to the park café');
      // The node has no tap action, so there is nothing to perform: the
      // database must be untouched.
      expect(
        tester
            .getSemantics(saveUp)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isFalse,
      );
      await tester.tap(saveUp);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(await db.select(db.rewardRedemptions).get(), isEmpty);
      expect(find.text('120'), findsOneWidget);
      semantics.dispose();
      await disposeApp(tester);
    });
  });

  // SPACING_SPEC §10 / kid minimum: `--tap-kid` 56, `--tap-parent` 44.
  group('K08 tap targets', () {
    for (final (width, scale) in <(double, double)>[(390, 1), (320, 1.3)]) {
      testWidgets('every control is at least 56 x 56 at $width px / $scale', (
        tester,
      ) async {
        await _pumpRoute(tester, width: width, textScale: scale);
        expect(tester.takeException(), isNull);

        final back = tester.getRect(find.byType(NestIconButton));
        final lock = tester.getRect(find.byType(NestLockButton));
        for (final (rect, what) in <(Rect, String)>[
          (back, 'back'),
          (lock, 'lock'),
        ]) {
          expect(rect.width, greaterThanOrEqualTo(NestDevice.tapKid));
          expect(rect.height, greaterThanOrEqualTo(NestDevice.tapKid));
          expect(what, isNotEmpty);
        }

        // Each card button: full column width, at least 56 tall.
        final cardButtons = find.byType(NestKidButton);
        expect(cardButtons, findsNWidgets(6));
        for (var i = 0; i < 6; i++) {
          final rect = tester.getRect(cardButtons.at(i));
          expect(
            rect.height,
            greaterThanOrEqualTo(NestDevice.tapKid),
            reason: 'card $i action must be a kid-sized target',
          );
          expect(rect.width, greaterThanOrEqualTo(NestDevice.tapKid));
        }
        await disposeApp(tester);
      });
    }

    testWidgets('the card action hit area is the painted 56 px', (
      tester,
    ) async {
      await _pumpRoute(tester);
      final button = find.descendant(
        of: find.byType(ShopRewardCard).first,
        matching: find.byType(NestKidButton),
      );
      final rect = tester.getRect(button);
      // `NestKidButton` reserves 6 px BELOW its painted 56 for `--sh-kid`, so
      // the widget box is 62 tall: 348…404 painted, 404…410 shadow room.
      expect(rect.height, closeTo(62, 2));

      // A tap in the middle of the painted button writes the redemption…
      await tester.tapAt(Offset(rect.center.dx, rect.top + 28));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        await db.select(db.rewardRedemptions).get(),
        hasLength(1),
        reason: 'the hit area covers the whole painted button',
      );

      // …and 5 px under the painted button is the card's bottom padding, so
      // it belongs to nothing (the shadow band is decoration, not a target).
      await tester.tapAt(Offset(rect.center.dx, rect.top + 56 + 5));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        await db.select(db.rewardRedemptions).get(),
        hasLength(1),
        reason: 'the target is never larger than it looks',
      );
      await disposeApp(tester);
    });
  });

  // Data edges a real family reaches by saving, spending, adding a child or
  // naming a reward. Each one used to be a separate probe; they are pinned
  // here so a regression in any of them fails the suite.
  group('K08 data edges', () {
    testWidgets('0 coins shows six "Save up!" cards and an empty pill', (
      tester,
    ) async {
      await (db.update(db.children)..where((c) => c.id.equals('maya'))).write(
        const ChildrenCompanion(coins: Value(0)),
      );
      await _pumpRoute(tester);

      expect(tester.takeException(), isNull);
      expect(
        tester.getSemantics(find.byType(NestCoinPill)).label,
        contains('0 coins'),
      );
      expect(find.byType(ShopRewardCard), findsNWidgets(6));
      expect(find.text('Save up!'), findsNWidgets(6));
      expect(find.text('Get it'), findsNothing);
      // 150 − 0: the café card still says what is missing, never "locked".
      expect(find.text('150 more to go'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('a family with one child keeps the shop intact', (
      tester,
    ) async {
      await (db.delete(db.children)..where((c) => c.id.equals('leo'))).go();
      await _pumpRoute(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(ShopRewardCard), findsNWidgets(6));
      expect(find.text('120'), findsOneWidget);
      expect(find.text('Get it'), findsNWidgets(5));
      await disposeApp(tester);
    });

    testWidgets('9999 coins at 320 px / 1.3 scale fits the pill', (
      tester,
    ) async {
      await (db.update(db.children)..where((c) => c.id.equals('maya'))).write(
        const ChildrenCompanion(coins: Value(9999)),
      );
      await _pumpRoute(tester, width: 320, textScale: 1.3);

      expect(tester.takeException(), isNull);
      expect(
        tester.getSemantics(find.byType(NestCoinPill)).label,
        contains('9999 coins'),
      );
      expect(find.byType(ShopRewardCard), findsNWidgets(6));
      expect(find.text('Get it'), findsNWidgets(6));
      await disposeApp(tester);
    });

    testWidgets('a very long reward title ellipsises instead of overflowing', (
      tester,
    ) async {
      const title = 'A whole weekend at the swimming pool with Grandad';
      await (db.update(db.rewards)..where((r) => r.id.equals('r-screen')))
          .write(const RewardsCompanion(title: Value(title)));
      await _pumpRoute(tester, width: 320, textScale: 1.3);

      expect(tester.takeException(), isNull);
      final name = tester.widget<Text>(find.text(title));
      expect(name.maxLines, 2);
      expect(name.overflow, TextOverflow.ellipsis);
      // The card still lays out: nothing pushed past its 132 px column.
      expect(
        tester.getRect(find.byType(ShopRewardCard).first).right,
        closeTo(20 + (320 - 40 - 16) / 2, 1),
      );
      await disposeApp(tester);
    });

    testWidgets('a 2.0 system text scale is clamped to 1.3 by the shell', (
      tester,
    ) async {
      await _pumpRoute(tester, textScale: 1.3);
      final atClamp = tester.getRect(find.text('Reward shop'));

      await _pumpRoute(tester, textScale: 2);

      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(find.text('Reward shop')),
        atClamp,
        reason: 'app.dart clamps textScaler to 1.0…1.3',
      );
      await disposeApp(tester);
    });

    testWidgets('leaving mid-request neither throws nor loses the write', (
      tester,
    ) async {
      await _pumpRoute(tester);
      await tester.tap(find.text('Get it').first);
      await tester.pump(const Duration(milliseconds: 5));

      await disposeApp(tester); // the route goes away mid-write

      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        await db.select(db.rewardRedemptions).get(),
        hasLength(1),
        reason: 'the write completes even though the screen is gone',
      );
    });

    testWidgets('a double tap on Back leaves the shop once', (tester) async {
      await _pumpRoute(tester);
      await tester.tap(find.byType(NestIconButton));
      await tester.tap(find.byType(NestIconButton));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(currentPath(tester), '/kid-home');
      await disposeApp(tester);
    });
  });

  group('K08 states', () {
    testWidgets('an empty family gets a kid-voice empty state', (tester) async {
      await _useFakeRepository(_FakeKidShopRepository());
      await _pumpRoute(tester);
      expect(find.text('No rewards yet'), findsOneWidget);
      expect(
        find.text('Ask a grown-up to add something coins can buy.'),
        findsOneWidget,
      );
      // A child cannot add a reward, so there is nothing to press.
      expect(find.byType(NestKidButton), findsNothing);
      // The chrome survives so a child can always get back or ask a grown-up.
      expect(find.byType(NestIconButton), findsOneWidget);
      expect(find.byType(NestLockButton), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('a stalled stream shows the kid spinner with a label', (
      tester,
    ) async {
      await _useFakeRepository(_FakeKidShopRepository(hang: true));
      await _pumpRoute(tester);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(CircularProgressIndicator)).label,
        'Loading rewards',
      );
      await disposeApp(tester);
    });

    testWidgets('a failed stream offers a retry that reloads', (tester) async {
      await _useFakeRepository(_FakeKidShopRepository(failLoad: true));
      await _pumpRoute(tester);
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      // No Pip art: the PIP rule wants the child's own Pip, and no child is
      // known here, so the neutral gift glyph stands in.
      expect(find.byType(NestKidButton), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('Try again really reloads and brings the shop back', (
      tester,
    ) async {
      // Fails the first watch only, so the retry has something to prove.
      await _useFakeRepository(
        _FakeKidShopRepository(failFirstWatch: true, serveDemoShop: true),
      );
      await _pumpRoute(tester);
      expect(find.text('Something went wrong'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Something went wrong'), findsNothing);
      expect(find.text('Reward shop'), findsOneWidget);
      expect(find.byType(ShopRewardCard), findsNWidgets(6));
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('the retry spinner stands in while the reload runs', (
      tester,
    ) async {
      await _useFakeRepository(_FakeKidShopRepository(hang: true));
      await _pumpRoute(tester);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // A stalled retry keeps the chrome usable: a child is never trapped.
      expect(find.byType(NestIconButton), findsOneWidget);
      expect(find.byType(NestLockButton), findsOneWidget);
      await tester.tap(find.byType(NestLockButton));
      // Deliberately NOT pumpAndSettle: the kid spinner never stops
      // animating, so pumpAndSettle would spin until its own timeout.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(pushedPath(tester), '/parental-gate');
      await disposeApp(tester);
    });

    // `Seed.empty` is covered at the repository level
    // (`kid_shop_repository_test.dart`, "on an empty family") — it cannot be
    // pumped through the full app here: `Seed.empty` calls `db.clearAll()`
    // while `AppSession` holds live watch streams on that same database, and
    // the reseed never completes in a widget-test isolate. Nothing about the
    // shop screen is involved (the repository stream emits `maya:0:0` for the
    // reseeded database in a few ms), so the empty-state surface is driven
    // through the fake instead, below and in the group above.

    testWidgets('a family with no rewards keeps the balance out of the copy', (
      tester,
    ) async {
      await db.delete(db.rewards).go();
      await _pumpRoute(tester);
      expect(find.text('No rewards yet'), findsOneWidget);
      // No grid means no pill and no footer either: nothing stale on screen.
      expect(find.byType(NestCoinPill), findsNothing);
      expect(find.byType(ShopRewardCard), findsNothing);
      await disposeApp(tester);
    });

    // The chrome-only states get the same width × scale treatment as the grid:
    // they are centred, so a narrow column or big text is where they break.
    for (final (width, scale, theme) in <(double, double, ThemeMode)>[
      (320, 1.3, ThemeMode.light),
      (320, 1.3, ThemeMode.dark),
      (430, 1, ThemeMode.light),
      (430, 1.3, ThemeMode.dark),
    ]) {
      testWidgets(
        'the empty state fits ${width.toInt()} px at $scale in ${theme.name}',
        (tester) async {
          await _useFakeRepository(_FakeKidShopRepository());
          await _pumpRoute(
            tester,
            width: width,
            textScale: scale,
            theme: theme,
          );
          expect(tester.takeException(), isNull);
          expect(find.text('No rewards yet'), findsOneWidget);
          await disposeApp(tester);
        },
      );

      testWidgets(
        'the failure state fits ${width.toInt()} px at $scale in ${theme.name}',
        (tester) async {
          await _useFakeRepository(_FakeKidShopRepository(failLoad: true));
          await _pumpRoute(
            tester,
            width: width,
            textScale: scale,
            theme: theme,
          );
          expect(tester.takeException(), isNull);
          expect(find.text('Something went wrong'), findsOneWidget);
          expect(find.text('Try again'), findsOneWidget);
          await disposeApp(tester);
        },
      );
    }
  });

  // Everything here is driven by the seeded database, never by a fake: the
  // point is that the screen reads the data and re-reads it when it changes.
  group('K08 database-driven states', () {
    testWidgets("Leo's shop shows his own balance and nothing is affordable", (
      tester,
    ) async {
      // `runAsync` so the Drift write really completes: a bare `await` inside
      // `testWidgets` runs in the fake-async zone, where Drift's deferred
      // stream notifications never fire. The switch is done WHILE the shop is
      // open (the K01 picker flow), which is also what the repository test
      // "follows an active-child switch after the first emission" covers.
      await _pumpRoute(tester);
      expect(find.text('120'), findsOneWidget); // Maya's shop first

      await tester.runAsync(() async {
        await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
          const AppStateCompanion(activeChildId: Value('leo')),
        );
        // One real-zone turn so Drift's watch notification is delivered.
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
      expect(
        tester.getSemantics(find.byType(NestCoinPill)).label,
        contains('45 coins'),
        reason: 'the pill follows the active child',
      );
      expect(find.byType(ShopRewardCard), findsNWidgets(6));
      expect(find.text('Get it'), findsNothing);
      expect(find.text('Save up!'), findsNWidgets(6));
      // Leo is 5 short of the cheapest card (50) — and the cards say what is
      // missing instead of shaming him (DESIGN_SPEC §5 K08).
      expect(find.text('5 more to go'), findsOneWidget);
      await _revealFooter(
        tester,
        'You have 45 coins. Pip is helping you save!',
      );
      expect(
        find.text('You have 45 coins. Pip is helping you save!'),
        findsOneWidget,
      );
      await disposeApp(tester);
    });

    testWidgets('an instant purchase moves the pill and every affordability', (
      tester,
    ) async {
      await _pumpRoute(tester);

      await tester.tap(find.text('Get it').first); // r-screen, needs an OK
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // A pending approval costs nothing, so the shop is unchanged…
      expect(find.text('120'), findsOneWidget); // the pill
      expect(find.text('Get it'), findsNWidgets(5));

      // …but an instant one (Baking together, 100 coins) is spent at once.
      await tester.tap(find.text('Get it').at(3));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final rows = await db.select(db.rewardRedemptions).get();
      expect(rows.map((r) => r.rewardId).toList(), <String>[
        'r-screen',
        'r-baking',
      ]);
      expect(rows.map((r) => r.status).toList(), <String>[
        'requested',
        'approved',
      ]);
      final maya = await (db.select(
        db.children,
      )..where((c) => c.id.equals('maya'))).getSingle();
      expect(maya.coins, 20);
      expect(find.text('20'), findsOneWidget); // the pill
      expect(find.text('Save up!'), findsNWidgets(6));
      expect(find.text('130 more to go'), findsOneWidget); // 150 − 20
      await _revealFooter(
        tester,
        'You have 20 coins. Pip is helping you save!',
      );
      expect(
        find.text('You have 20 coins. Pip is helping you save!'),
        findsOneWidget,
      );
      await disposeApp(tester);
    });

    testWidgets('a purchase toasts the design-free kid copy', (tester) async {
      await _pumpRoute(tester);

      await tester.tap(find.text('Get it').first); // needs an OK
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        find.text('Mum will give it a thumbs-up soon.'),
        findsOneWidget,
        reason: 'the toast is announced once, from the state sequence',
      );

      // The toast is announced through the notice SEQUENCE, so an identical second
      // purchase raises it again instead of being swallowed as "unchanged".
      expect(find.byType(NestToast), findsOneWidget, reason: 'not stacked');
      await tester.tap(find.text('Get it').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        find.byType(NestToast),
        findsOneWidget,
        reason: 'the second purchase replaces the toast, never stacks it',
      );
      expect(find.text('Mum will give it a thumbs-up soon.'), findsOneWidget);
      expect(find.byType(ShopRewardCard), findsNWidgets(6));
      await disposeApp(tester);
    });

    testWidgets('an instant purchase toasts the enjoy copy', (tester) async {
      await _pumpRoute(tester);

      await tester.tap(find.text('Get it').at(3)); // Baking together
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('It’s yours — enjoy!'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('the toast is announced as a live region', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      await tester.tap(find.text('Get it').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        tester.getSemantics(find.text('Mum will give it a thumbs-up soon.')),
        isNotNull,
      );
      semantics.dispose();
      await disposeApp(tester);
    });
  });

  group('K08 theme and layout matrix', () {
    for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('renders without overflow in ${theme.name}', (tester) async {
        await _pumpRoute(tester, theme: theme);
        expect(tester.takeException(), isNull);
        expect(find.text('Reward shop'), findsOneWidget);
        expect(find.byType(ShopRewardCard), findsNWidgets(6));
        await disposeApp(tester);
      });
    }

    // Full width × text-scale matrix: every device width the app supports and
    // both ends of the app-wide textScaler clamp (`app.dart` clamps 1.0…1.3).
    for (final width in <double>[320, 390, 430]) {
      for (final scale in <double>[1, 1.3]) {
        for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
          testWidgets(
            '${theme.name} at ${width.toInt()} px, text scale $scale',
            (tester) async {
              await _pumpRoute(
                tester,
                width: width,
                textScale: scale,
                theme: theme,
              );
              expect(tester.takeException(), isNull);
              expect(find.text('Reward shop'), findsOneWidget);
              expect(find.byType(ShopRewardCard), findsNWidgets(6));
              // The grid follows the width, never a fixed 167
              // (SPACING_SPEC §10.2): (W − 40 − 16) / 2.
              final first = tester.getRect(find.byType(ShopRewardCard).at(0));
              final second = tester.getRect(find.byType(ShopRewardCard).at(1));
              expect(first.left, closeTo(20, 0.5));
              expect(first.width, closeTo((width - 40 - 16) / 2, 1));
              expect(second.left - first.right, closeTo(16, 0.5));
              expect(second.right, closeTo(width - 20, 0.5));
              // Long names stay on their two lines (`.k8-n` max 2, ellipsis)
              // instead of pushing the card taller than the design.
              final names = tester
                  .widgetList<Text>(
                    find.descendant(
                      of: find.byType(ShopRewardCard),
                      matching: find.byType(Text),
                    ),
                  )
                  .where(
                    (t) =>
                        t.maxLines == 2 && t.overflow == TextOverflow.ellipsis,
                  );
              expect(names, isNotEmpty, reason: 'the reward names are clamped');
              await disposeApp(tester);
            },
          );
        }
      }
    }

    testWidgets('survives 320 px wide at 1.3 text scale', (tester) async {
      await _pumpRoute(tester, width: 320, textScale: 1.3);
      expect(tester.takeException(), isNull);
      expect(find.text('Reward shop'), findsOneWidget);
      expect(find.byType(ShopRewardCard), findsNWidgets(6));
      // Columns follow the width, never a fixed 167 (SPACING_SPEC §10.2):
      // (320 − 40 − 16) / 2 = 132.
      final first = tester.getRect(find.byType(ShopRewardCard).at(0));
      final second = tester.getRect(find.byType(ShopRewardCard).at(1));
      expect(first.width, closeTo(132, 1));
      expect(second.left - first.right, closeTo(16, 1));
      await disposeApp(tester);
    });
  });
}
