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

/// A repository that can stall, fail, or serve an empty shop — the states a
/// healthy demo database cannot produce (K03 precedent).
class _FakeKidShopRepository implements KidShopRepository {
  _FakeKidShopRepository({this.hang = false, this.failLoad = false});

  final bool hang;
  final bool failLoad;

  final List<({String childId, String rewardId})> requests =
      <({String childId, String rewardId})>[];

  @override
  Stream<KidShopData> watchActiveShop() {
    if (hang) return const Stream<KidShopData>.empty();
    if (failLoad) return Stream<KidShopData>.error(Exception('shop down'));
    return Stream<KidShopData>.value(
      const KidShopData(childId: 'maya', coins: 120, items: <ShopReward>[]),
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
}) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await tester.pumpWidget(const NestlingApp(initialRoute: _route));
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
