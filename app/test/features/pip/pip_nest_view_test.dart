// K06 view tests over the in-memory Drift database (`Seed.demo`): the copy,
// the database-driven numbers, every control's tap action, the real DB
// writes behind those taps, navigation, theme and the fit matrix.
//
// Every test pumps the app at `/pip` and ends with `disposeApp` INSIDE the
// test body (RULES §7: Drift schedules a deferred stream-close timer on
// bloc disposal, and the framework's pending-timer check runs before
// `addTearDown` callbacks).
//
// The pixel geometry pins live in `pip_nest_widget_test.dart`.

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/pip/presentation/views/pip_nest_view.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_care_button.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_coin_amount.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_free_pill.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_growth_card.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_wardrobe_tile.dart';

import '../../test_scope.dart';

/// · — HTML `&middot;` (U+00B7).
const String _middot = '·';

/// — HTML `&mdash;` (U+2014).
const String _emDash = '—';

// ’ HTML `&rsquo;` (U+2019) — which `.k6-sec` does NOT use: the design
/// writes a LITERAL apostrophe (0x27) in "Pip's wardrobe", verified with
/// `hexdump` (50 69 70 27 73). The source byte is the oracle (K06-BUG-3).
const String _straightQuote = "'";
const String _rightQuote = '’';

Future<void> _pumpNest(
  WidgetTester tester, {
  ThemeMode theme = ThemeMode.light,
  double width = NestDevice.width,
  double textScale = 1,
}) async {
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await pumpAppRoute(tester, '/pip', theme: theme);
  // `pumpAppRoute` pins 390x844 ITSELF, so a surface set before the pump is
  // silently overwritten and the whole width matrix used to run at 390. The
  // requested surface is therefore applied AFTER the pump, then re-laid out,
  // and the size is asserted so this can never rot again (stage 6's note in
  // `6_bugs.md`, "test-infrastructure (minor, test-only)").
  tester.view.physicalSize = Size(width * 3, NestDevice.height * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pump();
  expect(
    tester.view.physicalSize.width / tester.view.devicePixelRatio,
    width,
    reason: 'the fit matrix must really run at $width logical px',
  );
}

Future<int> _coins(AppDatabase db) async {
  final child = await (db.select(
    db.children,
  )..where((c) => c.id.equals('maya'))).getSingle();
  return child.coins;
}

/// Performs the real VoiceOver/TalkBack activation of [finder]'s node — not a
/// pointer tap — after checking the node advertises the action.
void performTap(WidgetTester tester, Finder finder) {
  final node = tester.getSemantics(finder);
  expect(
    node.getSemanticsData().hasAction(SemanticsAction.tap),
    isTrue,
    reason: 'the control must expose SemanticsAction.tap',
  );
  node.owner!.performAction(node.id, SemanticsAction.tap);
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = await setUpTestScope();
  });

  testWidgets('renders the design copy and the database numbers', (
    tester,
  ) async {
    await _pumpNest(tester);

    // `.k6-name` — middle dot U+00B7, stage name from the child's stage.
    expect(find.text('Pip $_middot Fledgling'), findsOneWidget);
    expect(find.text('Growing into a Songbird'), findsOneWidget);
    // Growth labels come from the row, not the design's hard-coded numbers.
    expect(find.text('175 coins'), findsOneWidget);
    expect(find.text('250 to grow'), findsOneWidget);
    // `.k6-sec` — straight ASCII apostrophe (U+0027), the design's byte.
    expect(find.text('Pip${_straightQuote}s wardrobe'), findsOneWidget);
    expect(find.text('Pip${_rightQuote}s wardrobe'), findsNothing);
    // Caption — em dash U+2014.
    expect(
      find.text('Nothing here is a chore $_emDash it is all just for fun.'),
      findsOneWidget,
    );
    await disposeApp(tester);
  });

  testWidgets('seats the child’s own Pip and the next-stage preview', (
    tester,
  ) async {
    await _pumpNest(tester);

    // Orchestrator PIP rule: the nest slot seats the active child's own
    // PipAvatar (Maya = Mochi / sunny / stage 3), never a v1 stage SVG.
    final slot = find.byKey(const Key('k06-pet'));
    expect(slot, findsOneWidget);
    final avatars = find.descendant(of: slot, matching: find.byType(PipAvatar));
    expect(avatars, findsOneWidget);
    final avatar = tester.widget<PipAvatar>(avatars.first);
    expect(avatar.style, PipStyle.mochi);
    expect(avatar.skin, PipSkin.sunny);
    expect(avatar.stage, 3);
    expect(avatar.inNest, isFalse);

    // `.k6-grow-top img` — the same child one stage on, at the design's
    // 30 px slot.
    final growth = find.byKey(const Key('k06-grow'));
    expect(growth, findsOneWidget);
    final preview = tester.widget<PipAvatar>(
      find.descendant(of: growth, matching: find.byType(PipAvatar)).first,
    );
    expect(preview.stage, 4);
    expect(preview.size, kPipGrowthAvatarSize);
    await disposeApp(tester);
  });

  testWidgets('care row shows Feed 5, Play Free and Bath 3', (tester) async {
    await _pumpNest(tester);

    expect(find.byType(PipCareButton), findsNWidgets(3));
    expect(find.text('Feed'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Bath'), findsOneWidget);
    expect(find.byType(PipFreePill), findsOneWidget);
    expect(find.text('Free'), findsOneWidget);

    // `.k6-coin` prices live in the Feed / Bath trailing rows.
    final amounts = tester
        .widgetList<PipCoinAmount>(find.byType(PipCoinAmount))
        .map((w) => w.amount)
        .toList();
    expect(amounts, containsAll(<String>['5', '3']));
    await disposeApp(tester);
  });

  testWidgets('wardrobe renders design names, owned state and DB prices', (
    tester,
  ) async {
    await _pumpNest(tester);

    expect(find.byType(PipWardrobeTile), findsNWidgets(4));
    // Design order, never alphabetical: Scarf, Sun hat, Wellies, Crown.
    expect(find.text('Scarf'), findsOneWidget);
    expect(find.text('Sun hat'), findsOneWidget);
    expect(find.text('Wellies'), findsOneWidget);
    expect(find.text('Crown'), findsOneWidget);
    expect(find.text('Owned'), findsNWidgets(2));
    // The seed now mirrors the design (Wellies 30, Crown 60).
    final prices = tester
        .widgetList<PipCoinAmount>(find.byType(PipCoinAmount))
        .map((w) => w.amount)
        .toList();
    expect(prices, containsAll(<String>['30', '60']));
    await disposeApp(tester);
  });

  testWidgets('every control exposes SemanticsAction.tap', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpNest(tester);

    const labels = <String>[
      'Back',
      'Grown-ups',
      'Feed Pip, costs 5 coins',
      'Play with Pip, free',
      'Bathe Pip, costs 3 coins',
      'Scarf, Owned',
      'Sun hat, Owned',
      'Wellies, 30 coins',
      'Crown, 60 coins',
    ];
    for (final label in labels) {
      final node = find.bySemanticsLabel(label);
      expect(node, findsOneWidget, reason: 'no semantics node for "$label"');
      expect(
        tester
            .getSemantics(node)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
        reason: '"$label" is not operable by VoiceOver/TalkBack',
      );
    }
    await disposeApp(tester);
    semantics.dispose();
  });

  testWidgets('semantics tap actions drive the real database', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpNest(tester);

    expect(await _coins(db), 120);

    // Feed (-5) then Bath (-3) through the accessibility path.
    performTap(tester, find.bySemanticsLabel('Feed Pip, costs 5 coins'));
    await tester.pumpAndSettle();
    expect(await _coins(db), 115);

    performTap(tester, find.bySemanticsLabel('Bathe Pip, costs 3 coins'));
    await tester.pumpAndSettle();
    expect(await _coins(db), 112);

    // Buying an affordable locked tile spends the DB price (Wellies 30).
    performTap(tester, find.bySemanticsLabel('Wellies, 30 coins'));
    await tester.pumpAndSettle();
    expect(await _coins(db), 82);
    final row =
        await (db.select(db.pipWardrobe)..where(
              (w) => w.childId.equals('maya') & w.item.equals('wellies'),
            ))
            .getSingle();
    expect(row.owned, isTrue);
    await disposeApp(tester);
    semantics.dispose();
  });

  testWidgets('care taps change the database (feed -5, bath -3)', (
    tester,
  ) async {
    await _pumpNest(tester);

    expect(await _coins(db), 120);

    await tester.tap(find.byKey(const Key('k06-feed')));
    await tester.pumpAndSettle();
    expect(await _coins(db), 115);

    await tester.tap(find.byKey(const Key('k06-bath')));
    await tester.pumpAndSettle();
    expect(await _coins(db), 112);
    await disposeApp(tester);
  });

  testWidgets('an affordable wardrobe tap buys and marks the item owned', (
    tester,
  ) async {
    await _pumpNest(tester);

    // Wellies: locked, 120 coins vs the DB's 30 → the buy writes.
    await tester.tap(find.byKey(const Key('k06-ward-wellies')));
    await tester.pumpAndSettle();
    final row =
        await (db.select(db.pipWardrobe)..where(
              (w) => w.childId.equals('maya') & w.item.equals('wellies'),
            ))
            .getSingle();
    expect(row.owned, isTrue);
    expect(await _coins(db), 90);
    // The strip now shows three owned tiles.
    expect(find.text('Owned'), findsNWidgets(3));
    await disposeApp(tester);
  });

  testWidgets('an owned item Pip cannot wear says so and spends nothing', (
    tester,
  ) async {
    await _pumpNest(tester);

    // Buy the wellies first (120 - 30 = 90), then tap the OWNED tile: it has
    // no Pip accessory node, so no DB write — just the kind explanation.
    await tester.tap(find.byKey(const Key('k06-ward-wellies')));
    await tester.pumpAndSettle();
    expect(await _coins(db), 90);

    await tester.tap(find.byKey(const Key('k06-ward-wellies')));
    await tester.pumpAndSettle();
    expect(find.text(kPipNotWearable), findsOneWidget);
    expect(await _coins(db), 90);
    await disposeApp(tester);
  });

  testWidgets('back goes to kid home and the lock opens the parental gate', (
    tester,
  ) async {
    await _pumpNest(tester);

    await tester.tap(find.bySemanticsLabel('Grown-ups'));
    await tester.pumpAndSettle();
    expect(pushedPath(tester), '/parental-gate');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(pushedPath(tester), '/pip');

    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(pushedPath(tester), '/kid-home');
    await disposeApp(tester);
  });

  testWidgets('dark mode renders every token-driven surface', (tester) async {
    await _pumpNest(tester, theme: ThemeMode.dark);

    expect(find.text('Pip $_middot Fledgling'), findsOneWidget);
    expect(find.byType(PipGrowthCard), findsOneWidget);
    expect(find.byType(PipWardrobeTile), findsNWidgets(4));
    expect(tester.takeException(), isNull);
    await disposeApp(tester);
  });

  for (final width in const <double>[320, 390, 430]) {
    for (final textScale in const <double>[1, 1.3]) {
      testWidgets('${width.toInt()}px @${textScale}x: renders, no overflow', (
        tester,
      ) async {
        await _pumpNest(tester, width: width, textScale: textScale);

        expect(find.text('Pip $_middot Fledgling'), findsOneWidget);
        expect(find.byType(PipCareButton), findsNWidgets(3));
        expect(find.byType(PipWardrobeTile), findsNWidgets(4));
        expect(tester.takeException(), isNull);
        await disposeApp(tester);
      });
    }
  }
}
