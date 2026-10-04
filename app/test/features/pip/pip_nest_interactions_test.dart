// K06 · Pip's nest — the interaction matrix: what every tap writes, what it
// refuses to write, where the toast copy comes from, what the accessibility
// path does, how big the targets are, and what the bottom of the screen looks
// like (owner BOTTOM EDGE rule).
//
// Copy/state facts live in `pip_nest_view_test.dart`, the non-loaded states in
// `pip_nest_states_test.dart` and the pixel geometry in
// `pip_nest_widget_test.dart`. In-memory Drift + `Seed.demo` throughout; every
// test ends with `disposeApp` INSIDE the test body (RULES §7.1).
//
// ORCHESTRATOR_NOTES 13:52: `shared/shared_batch7` moves the seed's wardrobe
// prices to the design's 30/60. The seeded 40/120 asserted below (and the
// balances derived from them) are this branch's values; they move together
// with that merge — `docs/screens/K06/3_test.md` §6 lists every place.
import 'dart:math' as math;

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/design_system/design_system.dart' hide PipStage;
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/pip/data/pip_repository_impl.dart';
import 'package:nestling/features/pip/domain/pip_repository.dart';
import 'package:nestling/features/pip/presentation/bloc/pip_bloc.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_care_button.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_wardrobe_tile.dart';

import '../../test_scope.dart';

/// Feed costs 5, Bath costs 3 (`pip_repository_impl.dart`).
const String _feedLabel = 'Feed Pip, costs 5 coins';
const String _playLabel = 'Play with Pip, free';
const String _bathLabel = 'Bathe Pip, costs 3 coins';

/// A buy whose write always throws: the view's generic-fallback toast.
class _ThrowingBuyRepository extends PipRepositoryImpl {
  _ThrowingBuyRepository({required super.db});

  @override
  Future<void> buyItem(String childId, String item) =>
      throw Exception('buy down');
}

Future<void> _useRepository(PipRepository repo) async {
  await GetIt.instance.unregister<PipRepository>();
  GetIt.instance.registerSingleton<PipRepository>(repo);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _pumpNest(
  WidgetTester tester, {
  double width = NestDevice.width,
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
}) async {
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await pumpAppRoute(tester, '/pip', theme: theme);
  // `pumpAppRoute` pins 390x844 ITSELF, so a surface set before the pump is
  // silently overwritten and the width matrix runs at 390 (stage 6's
  // test-infrastructure note). Apply it after, re-lay out, and assert the
  // size so this cannot rot again.
  tester.view.physicalSize = Size(width * 3, NestDevice.height * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pump();
  expect(
    tester.view.physicalSize.width / tester.view.devicePixelRatio,
    width,
    reason: 'this test must really run at $width logical px',
  );
}

Future<int> _coins(AppDatabase db, [String id = 'maya']) async {
  final row = await (db.select(
    db.children,
  )..where((c) => c.id.equals(id))).getSingle();
  return row.coins;
}

Future<int> _happiness(AppDatabase db, [String id = 'maya']) async {
  final row = await (db.select(
    db.children,
  )..where((c) => c.id.equals(id))).getSingle();
  return row.happiness;
}

Future<String?> _accessory(AppDatabase db, [String id = 'maya']) async {
  final row = await (db.select(
    db.children,
  )..where((c) => c.id.equals(id))).getSingle();
  return row.pipAccessory;
}

Future<bool> _owned(AppDatabase db, String item) async {
  final row = await (db.select(
    db.pipWardrobe,
  )..where((w) => w.childId.equals('maya') & w.item.equals(item))).getSingle();
  return row.owned;
}

Future<void> _setCoins(AppDatabase db, int coins, [String id = 'maya']) async {
  await (db.update(db.children)..where((c) => c.id.equals(id))).write(
    ChildrenCompanion(coins: Value(coins)),
  );
}

/// The real VoiceOver/TalkBack activation, after checking the node
/// advertises the action.
void performTap(WidgetTester tester, Finder finder) {
  final node = tester.getSemantics(finder);
  expect(
    node.getSemanticsData().hasAction(SemanticsAction.tap),
    isTrue,
    reason: 'the control must expose SemanticsAction.tap',
  );
  node.owner!.performAction(node.id, SemanticsAction.tap);
}

/// A semantics node that matches nothing (for "must not be a control").
bool _hasNode(WidgetTester tester, String label) {
  return tester
      .getSemantics(find.bySemanticsLabel(label))
      .getSemanticsData()
      .hasAction(SemanticsAction.tap);
}

/// `enabled: true/false` on the node — the RULES §8 contract for a disabled
/// control (`flagsCollection` is the non-deprecated reader).
bool _isEnabled(WidgetTester tester, Finder finder) =>
    tester
        .getSemantics(finder)
        .getSemanticsData()
        .flagsCollection
        .isEnabled
        .toBoolOrNull() ??
    false;

double _opacity(WidgetTester tester, Finder finder) {
  return tester
      .widget<Opacity>(
        find.descendant(of: finder, matching: find.byType(Opacity)),
      )
      .opacity;
}

/// Asset names of every [SvgPicture] currently in the tree.
List<String> _svgAssets(WidgetTester tester) => find
    .byType(SvgPicture)
    .evaluate()
    .map((element) => (element.widget as SvgPicture).bytesLoader)
    .whereType<SvgAssetLoader>()
    .map((loader) => loader.assetName)
    .toList();

/// The bundled faces, loaded first: `flutter test`'s default placeholder
/// glyphs are one em wide, which changes every measured text box (the same
/// reason `pip_nest_widget_test.dart` loads them). Without them a 15 px
/// caption wraps to three lines and the whole screen below the title drifts.
Future<void> loadBundledFonts() async {
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

void main() {
  late AppDatabase db;

  setUpAll(loadBundledFonts);

  setUp(() async {
    db = await setUpTestScope();
  });

  group('affordability', () {
    testWidgets('a coin-poor kid gets no tap action on Feed or Bath', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _setCoins(db, 2);
      await _pumpNest(tester);

      // RULES §8: a disabled control passes no tap and reports enabled:false.
      for (final label in const <String>[_feedLabel, _bathLabel]) {
        final finder = find.bySemanticsLabel(label);
        expect(finder, findsOneWidget, reason: label);
        expect(_isEnabled(tester, finder), isFalse, reason: label);
        expect(
          tester
              .getSemantics(finder)
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isFalse,
          reason: '$label must not be operable',
        );
      }
      // Play is free, so it stays live.
      final play = find.bySemanticsLabel(_playLabel);
      expect(_isEnabled(tester, play), isTrue);
      expect(
        tester
            .getSemantics(play)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
      // The design's disabled recipe: opacity .45.
      expect(_opacity(tester, find.byKey(const Key('k06-feed'))), 0.45);
      expect(_opacity(tester, find.byKey(const Key('k06-bath'))), 0.45);
      expect(_opacity(tester, find.byKey(const Key('k06-play'))), 1);
      // A pointer tap on a disabled button changes nothing.
      await tester.tap(find.byKey(const Key('k06-feed')));
      await tester.tap(find.byKey(const Key('k06-bath')));
      await _settle(tester);
      expect(await _coins(db), 2);
      expect(await _happiness(db), 4);
      expect(find.text(kPipNotEnoughCoins), findsNothing);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('the last feed disables the button for the next tap', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _setCoins(db, 6);
      await _pumpNest(tester);
      expect(_isEnabled(tester, find.bySemanticsLabel(_feedLabel)), isTrue);

      await tester.tap(find.byKey(const Key('k06-feed')));
      await _settle(tester);
      expect(await _coins(db), 1);

      // 1 < 5: the affordance follows the database, with no reload event.
      expect(_isEnabled(tester, find.bySemanticsLabel(_feedLabel)), isFalse);
      expect(_opacity(tester, find.byKey(const Key('k06-feed'))), 0.45);
      // Bath (3) is out of reach too, Play never is.
      expect(_isEnabled(tester, find.bySemanticsLabel(_bathLabel)), isFalse);
      expect(_isEnabled(tester, find.bySemanticsLabel(_playLabel)), isTrue);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('Play is free: happiness rises, coins never move', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpNest(tester);

      performTap(tester, find.bySemanticsLabel(_playLabel));
      await _settle(tester);

      expect(await _coins(db), 120);
      expect(await _happiness(db), 5);
      expect(find.text(kPipNotEnoughCoins), findsNothing);
      expect(currentPath(tester), '/pip', reason: 'Play never navigates');
      semantics.dispose();
      await disposeApp(tester);
    });
  });

  group('toasts', () {
    testWidgets('an unaffordable buy says so kindly and spends nothing', (
      tester,
    ) async {
      await _setCoins(db, 10);
      await _pumpNest(tester);

      await tester.tap(find.byKey(const Key('k06-ward-wellies')));
      await _settle(tester);

      expect(find.text(kPipNotEnoughCoins), findsOneWidget);
      expect(await _coins(db), 10);
      expect(await _owned(db, 'wellies'), isFalse);
      expect(find.text('Owned'), findsNWidgets(2), reason: 'still 2 owned');
      expect(currentPath(tester), '/pip');
      await disposeApp(tester);
    });

    testWidgets('a failed write falls back to the shared wording', (
      tester,
    ) async {
      await _useRepository(_ThrowingBuyRepository(db: db));
      await _pumpNest(tester);

      await tester.tap(find.byKey(const Key('k06-ward-wellies')));
      await _settle(tester);

      expect(find.text(kPipNotEnoughCoins), findsNothing);
      expect(find.text('Hmm, that did not work. Try again.'), findsOneWidget);
      expect(await _coins(db), 120);
      expect(await _owned(db, 'wellies'), isFalse);
      await disposeApp(tester);
    });

    testWidgets('a second unaffordable buy is announced again', (tester) async {
      await _setCoins(db, 10);
      await _pumpNest(tester);

      await tester.tap(find.byKey(const Key('k06-ward-wellies')));
      await _settle(tester);
      expect(find.text(kPipNotEnoughCoins), findsOneWidget);

      // Let the 3 s toast finish so the next one has to be a NEW toast.
      await tester.pump(const Duration(seconds: 4));
      await _settle(tester);
      expect(find.text(kPipNotEnoughCoins), findsNothing);

      // Second locked tile, same reason for refusal.
      await tester.tap(find.byKey(const Key('k06-ward-crown')));
      await _settle(tester);

      expect(find.text(kPipNotEnoughCoins), findsOneWidget);
      await disposeApp(tester);
    });
  });

  group('equipping', () {
    testWidgets('the owned Scarf equips and Pip wears it', (tester) async {
      await _pumpNest(tester);
      expect(await _accessory(db), 'none');

      await tester.tap(find.byKey(const Key('k06-ward-scarf')));
      await _settle(tester);

      expect(await _accessory(db), 'scarf');
      // Orchestrator PIP rule: the nest slot re-renders the CHILD's own Pip
      // with the new accessory, not a static illustration.
      final avatar = tester.widget<PipAvatar>(
        find
            .descendant(
              of: find.byKey(const Key('k06-pet')),
              matching: find.byType(PipAvatar),
            )
            .first,
      );
      expect(avatar.accessory, PipAccessory.scarf);
      expect(avatar.style, PipStyle.mochi);
      expect(avatar.skin, PipSkin.sunny);
      expect(avatar.stage, 3);
      // The owned, wearable tile never raises the "cannot wear" toast.
      expect(
        find.text('That one is not something Pip can wear.'),
        findsNothing,
      );
      expect(currentPath(tester), '/pip');
      await disposeApp(tester);
    });

    testWidgets('the owned Sun hat equips the cap', (tester) async {
      await _pumpNest(tester);

      await tester.tap(find.byKey(const Key('k06-ward-sunhat')));
      await _settle(tester);

      expect(await _accessory(db), 'cap');
      final avatar = tester.widget<PipAvatar>(
        find
            .descendant(
              of: find.byKey(const Key('k06-pet')),
              matching: find.byType(PipAvatar),
            )
            .first,
      );
      expect(avatar.accessory, PipAccessory.cap);
      await disposeApp(tester);
    });

    testWidgets('equipping is reachable by VoiceOver too', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpNest(tester);

      performTap(tester, find.bySemanticsLabel('Scarf, Owned'));
      await _settle(tester);

      expect(await _accessory(db), 'scarf');
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('buying an affordable item spends the DB price', (
      tester,
    ) async {
      await _pumpNest(tester);

      performTap(tester, find.bySemanticsLabel('Wellies, 40 coins'));
      await _settle(tester);

      expect(await _coins(db), 80, reason: 'the DB price, not the HTML 30');
      expect(await _owned(db, 'wellies'), isTrue);
      // The tile announces itself as owned afterwards.
      expect(find.bySemanticsLabel('Wellies, Owned'), findsOneWidget);
      expect(find.text('Owned'), findsNWidgets(3));
      await disposeApp(tester);
    });
  });

  group('no interaction navigates', () {
    testWidgets('care and wardrobe taps all stay on /pip', (tester) async {
      await _pumpNest(tester);

      for (final key in const <String>[
        'k06-feed',
        'k06-play',
        'k06-bath',
        'k06-ward-scarf',
        'k06-ward-sunhat',
        'k06-ward-wellies',
      ]) {
        await tester.tap(find.byKey(Key(key)));
        await _settle(tester);
        expect(currentPath(tester), '/pip', reason: key);
        expect(pushedPath(tester), '/pip', reason: '$key pushed nothing');
      }
      await disposeApp(tester);
    });
  });

  group('tap targets (kid: 56 px both axes)', () {
    testWidgets('every control is at least 56 x 56', (tester) async {
      await _pumpNest(tester);

      final targets = <String, Finder>{
        'back': find.byKey(const Key('k06-back')),
        'grown-ups lock': find.byKey(const Key('k06-lock')),
        'Feed': find.byKey(const Key('k06-feed')),
        'Play': find.byKey(const Key('k06-play')),
        'Bath': find.byKey(const Key('k06-bath')),
        'Scarf tile': find.byKey(const Key('k06-ward-scarf')),
        'Sun hat tile': find.byKey(const Key('k06-ward-sunhat')),
        'Wellies tile': find.byKey(const Key('k06-ward-wellies')),
        'Crown tile': find.byKey(const Key('k06-ward-crown')),
      };
      for (final entry in targets.entries) {
        final size = tester.getSize(entry.value);
        expect(
          size.width,
          greaterThanOrEqualTo(NestDevice.tapKid),
          reason: '${entry.key} width',
        );
        expect(
          size.height,
          greaterThanOrEqualTo(NestDevice.tapKid),
          reason: '${entry.key} height',
        );
      }
      await disposeApp(tester);
    });

    testWidgets('the painted rect is the whole tap target (5 px inside)', (
      tester,
    ) async {
      // The owner/UI-check rule in its tap-target form: a tap 5 px inside
      // every edge must still land, so no invisible dead margin hides inside
      // a painted button.
      await _pumpNest(tester);
      await _setCoins(db, 0);

      for (final key in const <String>[
        'k06-feed',
        'k06-play',
        'k06-ward-scarf',
        'k06-ward-wellies',
      ]) {
        final finder = find.byKey(Key(key));
        final rect = tester.getRect(finder);
        final inset = math.min(5, rect.width / 4);
        for (final point in <Offset>[
          Offset(rect.left + inset, rect.top + inset),
          Offset(rect.right - inset, rect.top + inset),
          Offset(rect.left + inset, rect.bottom - inset),
          Offset(rect.right - inset, rect.bottom - inset),
          rect.center,
        ]) {
          expect(
            tester.hitTestOnBinding(point),
            isNotNull,
            reason: '$key must be tappable at $point',
          );
        }
      }
      await disposeApp(tester);
    });
  });

  group('the bottom of the screen (owner BOTTOM EDGE rule)', () {
    testWidgets(
      'no bar sits under the content and the meadow runs to the edge',
      (tester) async {
        await _pumpNest(tester);

        // K06 has no dock / tab bar / bottom CTA — the meadow is the bottom.
        expect(find.byType(NestBottomCta), findsNothing);
        expect(find.byType(NestTabBar), findsNothing);
        final meadow = tester.getRect(find.byType(NestMeadow));
        expect(meadow.bottom, closeTo(NestDevice.height, 0.01));
        expect(meadow.height, closeTo(NestMeadowGeometry.defaultHeight, 0.01));
        expect(meadow.width, closeTo(NestDevice.width, 0.01));
        // Exactly one shared meadow, painted by the shared KidScope.
        expect(find.byType(KidScope), findsOneWidget);
        expect(find.byType(NestMeadow), findsOneWidget);
        // The caption clears the home indicator the OS draws.
        final caption = tester.getRect(find.byKey(const Key('k06-caption')));
        expect(
          caption.bottom,
          lessThanOrEqualTo(NestDevice.height - NestDevice.homeH),
        );
        await disposeApp(tester);
      },
    );
  });

  group('PIP (orchestrator rule)', () {
    testWidgets('no v1 pip_stage illustration is painted on K06', (
      tester,
    ) async {
      await _pumpNest(tester);
      final assets = _svgAssets(tester);
      expect(
        assets.where((asset) => asset.contains('pip-stage')),
        isEmpty,
        reason: 'v1 stage art must not appear in product screens: $assets',
      );
      // The nest art is the design's own shared illustration.
      expect(assets.any((asset) => asset.endsWith('nest.svg')), isTrue);
      await disposeApp(tester);
    });
  });

  group('the active child switches under the screen', () {
    testWidgets('Leo gets his own Pip, his stage name and his wardrobe', (
      tester,
    ) async {
      await _pumpNest(tester);
      expect(find.text('Pip · Fledgling'), findsOneWidget);

      // A live switch, not a cold start: the one live subscription follows it.
      await tester.runAsync(() async {
        await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
          const AppStateCompanion(activeChildId: Value<String?>('leo')),
        );
        await GetIt.instance<AppSession>().refresh();
      });
      await _settle(tester);

      // Stage name from his row (stage 2), middle dot still U+00B7.
      expect(find.text('Pip · Fledgling'), findsNothing);
      expect(find.text('Pip · Hatchling'), findsOneWidget);
      final slot = find.descendant(
        of: find.byKey(const Key('k06-pet')),
        matching: find.byType(PipAvatar),
      );
      final avatar = tester.widget<PipAvatar>(slot.first);
      expect(avatar.style, PipStyle.bolt);
      expect(avatar.skin, PipSkin.sky);
      expect(avatar.stage, 2);
      expect(avatar.accessory, PipAccessory.none);
      // The growth preview is one stage on from HIS stage.
      final preview = tester.widget<PipAvatar>(
        find
            .descendant(
              of: find.byKey(const Key('k06-grow')),
              matching: find.byType(PipAvatar),
            )
            .first,
      );
      expect(preview.stage, 3);
      // Growth and prices from his row: 60/250 = 24 %, scarf 30 locked.
      expect(find.text('Growing into a Fledgling'), findsOneWidget);
      expect(find.text('60 coins'), findsOneWidget);
      expect(find.text('250 to grow'), findsOneWidget);
      // The design's own `aria-label` wording ("Pip is 70% of the way to
      // Songbird"), with the percentage from his row.
      expect(
        find.bySemanticsLabel(RegExp('Pip is 24% of the way to')),
        findsOneWidget,
      );
      expect(find.text('Owned'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('40'), findsOneWidget);
      expect(find.text('120'), findsOneWidget);
      // Design order for every child: Scarf, Sun hat, Wellies, Crown.
      final tiles = find.byType(PipWardrobeTile);
      expect(tiles, findsNWidgets(4));
      expect(
        tester
            .widgetList<PipWardrobeTile>(tiles)
            .map((tile) => tile.item.id)
            .toList(),
        <String>['scarf', 'sunhat', 'wellies', 'crown'],
      );
      expect(currentPath(tester), '/pip');
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('care after the switch applies to Leo, not Maya', (
      tester,
    ) async {
      await _pumpNest(tester);
      await tester.runAsync(() async {
        await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
          const AppStateCompanion(activeChildId: Value<String?>('leo')),
        );
        await GetIt.instance<AppSession>().refresh();
      });
      await _settle(tester);

      await tester.tap(find.byKey(const Key('k06-feed')));
      await _settle(tester);

      expect(await _coins(db, 'leo'), 40);
      expect(await _coins(db), 120);
      await disposeApp(tester);
    });
  });

  group('nothing on this screen is a phantom button', () {
    testWidgets('the care labels are buttons, the copy is not', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpNest(tester);

      for (final label in const <String>[
        _feedLabel,
        _playLabel,
        _bathLabel,
        'Back',
        'Grown-ups',
      ]) {
        expect(_hasNode(tester, label), isTrue, reason: label);
      }
      for (final label in const <String>[
        'Feed',
        'Play',
        'Bath',
        'Scarf',
        'Sun hat',
        'Wellies',
        'Crown',
        'Owned',
      ]) {
        // The visible labels are inside `excludeSemantics` wrappers, so they
        // must NOT be reachable as separate (phantom) control nodes.
        expect(find.bySemanticsLabel(label), findsNothing, reason: label);
      }
      semantics.dispose();
      await disposeApp(tester);
    });
  });

  group('the design fit matrix for the loaded screen', () {
    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final width in const <double>[320, 430]) {
        for (final textScale in const <double>[1, 1.3]) {
          testWidgets(
            '${theme.name} @${width.toInt()}px @${textScale}x: no overflow',
            (tester) async {
              await _pumpNest(
                tester,
                theme: theme,
                width: width,
                textScale: textScale,
              );

              expect(find.byKey(const Key('k06-title')), findsOneWidget);
              expect(find.byType(PipCareButton), findsNWidgets(3));
              expect(find.byType(PipWardrobeTile), findsNWidgets(4));
              // Kid targets stay kid-sized at every width.
              for (final button in find.byType(PipCareButton).evaluate()) {
                final size = button.size!;
                expect(size.height, greaterThanOrEqualTo(NestDevice.tapKid));
              }
              expect(tester.takeException(), isNull);
              await disposeApp(tester);
            },
          );
        }
      }
    }
  });
}
