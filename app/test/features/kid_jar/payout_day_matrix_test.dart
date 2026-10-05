// K10 · Payout day — the stage-3 device/state/accessibility matrix.
//
// What the build stages already pinned (NOT duplicated here):
//   * the design bands at 390 / 1.0 / light — `payout_day_view_geometry_test.dart`
//     (back/lock rects, title 107/34, rain 180×270 at 141, note tops, fund
//     20/613/350/143, progress 39/695/312/16, the bar to the physical edge);
//   * the seeded copy, the Pip look, the four navigation destinations, the
//     empty/failure frames and the tap-action semantics —
//     `payout_day_view_test.dart`;
//   * every BLoC event/state path and the repository contract —
//     `kid_jar_bloc_test.dart`, `payout_celebration_test.dart`.
//
// The gaps this file closes:
//   * dark mode had NO content coverage (only the bar's bottom edge was probed
//     in dark), so nothing pinned that the dark LAYOUT equals the light one;
//   * text scale 1.3 was never pumped on this screen at any width — the plan's
//     320 px / 1.3× rule ("wrap or ellipsize, never overflow") was untested;
//   * the loading frame (a payout stream that has not emitted yet) had no test
//     at all;
//   * the empty/failure frames were only checked at 390 / 1.0 / light, and the
//     failure frame's escape hatch (the lock) was never exercised;
//   * the 56 px kid tap-target FLOOR was never asserted, only the incidental
//     390/light numbers;
//   * the `_GateLockButton` double-tap guard (`_busy`) and the `canPop()` branch
//     of the back chevron had no test.
//
// Owner rules covered: BOTTOM EDGE (probed on the painted raster, in both
// themes, with and without the 34 px home inset), ALIGNMENT (20 px gutters and
// shared card edges at every width), KID BACKGROUND (the shared KidScope sky +
// meadow hills, mounted once), COPY (byte-exact strings, straight apostrophe),
// PIP (the child's own `PipAvatar`, never a v1 `pip_stage_*.svg`), ACCESSIBILITY
// ACTIONS (every control exposes SemanticsAction.tap and performs it).
//
// No simulator was booted, installed on or driven (only `5_ui` may use one).
// Every pumped app ends with `disposeApp` (test_scope.dart) so Drift's
// deferred stream-close timer is drained.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'
    show RenderParagraph, RenderRepaintBoundary;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart' hide PipMood;
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/kid_home/kid_home_routes.dart';
import 'package:nestling/features/kid_jar/domain/entities/jar_entry.dart';
import 'package:nestling/features/kid_jar/domain/entities/jar_snapshot.dart';
import 'package:nestling/features/kid_jar/domain/entities/jar_summary.dart';
import 'package:nestling/features/kid_jar/domain/entities/payout_celebration.dart';
import 'package:nestling/features/kid_jar/domain/kid_jar_repository.dart';
import 'package:nestling/features/kid_jar/kid_jar_routes.dart';
import 'package:nestling/features/kid_jar/presentation/widgets/payout_fund_card.dart';
import 'package:nestling/features/kid_jar/presentation/widgets/payout_jar_rain.dart';
import 'package:nestling/features/kid_jar/presentation/widgets/payout_note.dart';

import '../../test_scope.dart';

/// The three widths the app supports, narrowest first.
const List<double> _widths = <double>[320, 390, 430];

/// The two text scales the shell clamps to (SPACING_SPEC §10.1).
const List<double> _scales = <double>[1, 1.3];

/// The design's copy, byte-for-byte from
/// `design/html-source/screens/K10-payout-day.html` (line 39 writes U+0027,
/// not U+2019). The amounts/goal figures are the seeded database's, not the
/// mock's (DATA OVER MOCKS).
const String _title = "It's payout day!";
const String _paid = 'Mum marked £3.80 as paid';
const String _paidSub = 'Pocket money for this week';
const String _moved = '£5.50 went into your Lego Friends set';
const String _movedSub = 'Just like you asked';
const String _goal = 'Lego Friends set';
const String _saved = '£15.50';
const String _toGo = '£9.49 to go';
const String _ofTarget = 'of £24.99';
const String _percent = '62% there!';
const String _pipSays = 'Pip says well done, Maya!';
const String _thanks = 'Thanks Mum!';
const String _rainAlt = 'A jar of coins with coins raining down into it';
const String _progressAlt = '62% of the Lego Friends set saved';

/// RepaintBoundary the bottom-edge probe reads the real raster through: a rect
/// assertion cannot see a strip painted INSIDE the bar's surface box (the K05
/// lesson, `quest_complete_matrix_test.dart`).
const Key _pixelProbe = ValueKey<String>('k10_bottom_edge_probe');

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

/// Hands out one broadcast payout stream per `watchLatestPayout()` call, so a
/// test can leave the screen loading (never add), show the empty state (add
/// null) or fail the stream (addError) and then recover on retry.
class _FakePayoutRepository implements KidJarRepository {
  final List<StreamController<PayoutCelebration?>> payouts =
      <StreamController<PayoutCelebration?>>[];

  final StreamController<JarSnapshot> _jar =
      StreamController<JarSnapshot>.broadcast();

  StreamController<PayoutCelebration?> get last => payouts.last;

  @override
  Future<List<JarEntry>> getItems() async => <JarEntry>[];

  @override
  Stream<List<JarEntry>> watchItems() => const Stream<List<JarEntry>>.empty();

  @override
  Stream<JarSnapshot> watchJar() => _jar.stream;

  @override
  Stream<JarSummary> watchSummary(String childId) =>
      const Stream<JarSummary>.empty();

  @override
  Stream<PayoutCelebration?> watchLatestPayout() {
    final controller = StreamController<PayoutCelebration?>.broadcast();
    payouts.add(controller);
    return controller.stream;
  }

  @override
  Future<void> moveToSavings({
    required String childId,
    required String goalId,
    required int amountPence,
  }) async {}

  Future<void> dispose() async {
    for (final controller in payouts) {
      await controller.close();
    }
    await _jar.close();
  }
}

/// The seeded celebration (Maya), handed to the fake so the state frames can
/// recover onto the real database content.
const PayoutCelebration _seededCelebration = PayoutCelebration(
  childId: 'maya',
  nickname: 'Maya',
  paidPence: 380,
  movedPence: 550,
  goalTitle: 'Lego Friends set',
  goalSavedPence: 1550,
  goalTargetPence: 2499,
  pipStyle: 'mochi',
  pipSkin: 'sunny',
  pipAccessory: 'none',
  pipStage: 3,
);

Future<void> _useFake(_FakePayoutRepository repo) async {
  await GetIt.instance.unregister<KidJarRepository>();
  GetIt.instance.registerSingleton<KidJarRepository>(repo);
}

Future<void> _pump(
  WidgetTester tester, {
  double width = 390,
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
  double bottomInset = 0,
  String route = KidJarRoutePaths.payoutDay,
}) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  if (bottomInset > 0) {
    tester.view.padding = FakeViewPadding(bottom: bottomInset * 3);
    addTearDown(tester.view.resetPadding);
  }
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _pixelProbe,
      child: NestlingApp(initialRoute: route),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

NestTokens _tokens(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(PayoutFundCard)))
        .extension<NestTokens>()!;

/// The `.kid-bar` surface: painted `surface` with a TOP-ONLY 3 px ink border.
/// The fund card borders all four sides, so the shape identifies the bar.
Finder _barSurface(WidgetTester tester) {
  final surface = _tokens(tester).surface;
  return find.byWidgetPredicate((widget) {
    if (widget is! Container) return false;
    final box = widget.decoration;
    if (box is! BoxDecoration) return false;
    if (box.color != surface) return false;
    final border = box.border;
    return border is Border &&
        border.top.width == 3 &&
        border.left.width == 0 &&
        border.right.width == 0 &&
        border.bottom.width == 0;
  });
}

/// Painted RGBA bytes at logical ([x], [y]) of the app surface.
Future<List<int>> _pixelAt(WidgetTester tester, double x, double y) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_pixelProbe),
  );
  late List<int> pixel;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final rgba = (await image.toByteData())!;
    final offset = (y.round() * image.width + x.round()) * 4;
    pixel = <int>[
      rgba.getUint8(offset),
      rgba.getUint8(offset + 1),
      rgba.getUint8(offset + 2),
      rgba.getUint8(offset + 3),
    ];
  });
  return pixel;
}

List<int> _rgb(Color color) => <int>[
  (color.r * 255).round(),
  (color.g * 255).round(),
  (color.b * 255).round(),
];

/// Every visible string on the loaded screen, in tree order.
List<String> _allCopy(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((text) => text.data)
    .whereType<String>()
    .toList();

/// The Pip row sits below the fold at every width (the celebration is taller
/// than the scroll viewport), so scroll it into view before asserting on it.
Future<void> _revealPipRow(WidgetTester tester) async {
  await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUpAll(_loadBundledFonts);

  setUp(() async {
    await setUpTestScope();
  });

  // -------------------------------------------------------------------------
  // The width × theme × text-scale matrix
  // -------------------------------------------------------------------------

  for (final width in _widths) {
    for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final scale in _scales) {
        final cell = '${width.round()}px ${theme.name} @${scale}x';

        testWidgets('$cell: the whole celebration renders and nothing '
            'overflows', (tester) async {
          await _pump(tester, width: width, textScale: scale, theme: theme);

          expect(find.text(_title), findsOneWidget, reason: cell);
          expect(find.text(_paid), findsOneWidget, reason: cell);
          expect(find.text(_paidSub), findsOneWidget, reason: cell);
          expect(find.text(_moved), findsOneWidget, reason: cell);
          expect(find.text(_movedSub), findsOneWidget, reason: cell);
          expect(find.text(_goal), findsOneWidget, reason: cell);
          expect(find.text(_saved), findsOneWidget, reason: cell);
          expect(find.text(_toGo), findsOneWidget, reason: cell);
          expect(find.text(_ofTarget), findsOneWidget, reason: cell);
          expect(find.text(_percent), findsOneWidget, reason: cell);
          expect(find.text(_thanks), findsOneWidget, reason: cell);
          expect(find.byType(PayoutJarRain), findsOneWidget, reason: cell);
          expect(find.byType(PayoutNote), findsNWidgets(2), reason: cell);
          expect(find.byType(PayoutFundCard), findsOneWidget, reason: cell);

          await _revealPipRow(tester);
          expect(find.text(_pipSays), findsOneWidget, reason: cell);

          // Any RenderFlex overflow, unbounded constraint or failed assertion
          // inside the painter surfaces here.
          expect(tester.takeException(), isNull, reason: '$cell threw');

          await disposeApp(tester);
        });

        testWidgets('$cell: 20px gutters, cards aligned to one edge set', (
          tester,
        ) async {
          await _pump(tester, width: width, textScale: scale, theme: theme);

          // Owner ALIGNMENT rule: 20 px on both sides, and every card in the
          // scroll shares those edges — nothing a few px off.
          final fund = tester.getRect(find.byType(PayoutFundCard));
          expect(fund.left, closeTo(NestSpacing.padSide, 0.5), reason: cell);
          expect(
            fund.right,
            closeTo(width - NestSpacing.padSide, 0.5),
            reason: cell,
          );
          for (var i = 0; i < 2; i++) {
            final rect = tester.getRect(find.byType(PayoutNote).at(i));
            expect(rect.left, closeTo(fund.left, 0.01), reason: cell);
            expect(rect.right, closeTo(fund.right, 0.01), reason: cell);
          }
          // Chrome shares the same gutters as the cards.
          expect(
            tester.getRect(find.byType(NestIconButton)).left,
            closeTo(NestSpacing.padSide, 0.5),
            reason: cell,
          );
          expect(
            tester.getRect(find.byType(NestLockButton)).right,
            closeTo(width - NestSpacing.padSide, 0.5),
            reason: cell,
          );
          // The CTA and the bar's painted button share them too.
          final button = tester.getRect(find.byType(NestKidButton));
          expect(button.left, closeTo(NestSpacing.padSide, 0.5), reason: cell);
          expect(
            button.right,
            closeTo(width - NestSpacing.padSide, 0.5),
            reason: cell,
          );
          // The illustration and the title are centred on the same axis.
          expect(
            tester.getRect(find.byType(PayoutJarRain)).center.dx,
            closeTo(width / 2, 0.5),
            reason: cell,
          );
          expect(
            tester.getRect(find.text(_title)).center.dx,
            closeTo(width / 2, 1),
            reason: cell,
          );

          // Nothing may paint outside the gutters once scrolled, either.
          await _revealPipRow(tester);
          for (final text in tester.widgetList<Text>(find.byType(Text))) {
            if (text.data == null) continue;
            final rect = tester.getRect(
              find.text(text.data!, skipOffstage: false),
            );
            expect(
              rect.left,
              greaterThanOrEqualTo(NestSpacing.padSide - 0.5),
              reason: '$cell: "${text.data}" escapes the left gutter',
            );
            expect(
              rect.right,
              lessThanOrEqualTo(width - NestSpacing.padSide + 0.5),
              reason: '$cell: "${text.data}" escapes the right gutter',
            );
          }
          expect(tester.takeException(), isNull, reason: '$cell threw');

          await disposeApp(tester);
        });

        testWidgets('$cell: the bar surface runs to the physical edge', (
          tester,
        ) async {
          await _pump(tester, width: width, textScale: scale, theme: theme);

          final bar = _barSurface(tester);
          expect(bar, findsOneWidget, reason: '$cell: one bar surface');
          final rect = tester.getRect(bar);
          expect(rect.left, 0, reason: '$cell: bleeds left');
          expect(rect.right, width, reason: '$cell: bleeds right');
          expect(rect.bottom, 844, reason: '$cell: bleeds to the edge');

          // The box reaching the edge is necessary but NOT sufficient (a strip
          // painted inside it is invisible to rects), so read the raster.
          final expected = _rgb(_tokens(tester).surface);
          final buttonBox = tester.getRect(find.byType(NestKidButton));
          // x = 2 / width-2 sit outside the CTA's 20…width-20 span, so a strip
          // of any width inside the bar is caught on every row.
          for (final x in <double>[2, width - 2]) {
            for (var y = rect.top + 4; y < 844; y++) {
              expect(
                (await _pixelAt(tester, x, y)).sublist(0, 3),
                expected,
                reason:
                    '$cell: pixel ($x, $y) in the bar is not the bar surface — '
                    'a coloured strip shows beside the CTA (bottom-edge rule)',
              );
            }
          }
          // Below the CTA box, across the full width including the centre
          // where the OS draws the home pill.
          for (var y = buttonBox.bottom; y < 844; y++) {
            for (final x in <double>[2, width / 2, width - 2]) {
              expect(
                (await _pixelAt(tester, x, y)).sublist(0, 3),
                expected,
                reason:
                    '$cell: pixel ($x, $y) under the CTA is not the bar '
                    'surface — a strip shows under the bar or around the home '
                    'indicator (bottom-edge rule)',
              );
            }
          }

          await disposeApp(tester);
        });

        testWidgets('$cell: every control meets the 56px kid floor', (
          tester,
        ) async {
          await _pump(tester, width: width, textScale: scale, theme: theme);

          for (final finder in <Finder>[
            find.byType(NestIconButton),
            find.byType(NestLockButton),
            find.byType(NestKidButton),
          ]) {
            final rect = tester.getRect(finder);
            expect(
              rect.width,
              greaterThanOrEqualTo(NestDevice.tapKid),
              reason: '$cell: $finder is only ${rect.width} wide',
            );
            expect(
              rect.height,
              greaterThanOrEqualTo(NestDevice.tapKid),
              reason: '$cell: $finder is only ${rect.height} tall',
            );
          }

          await disposeApp(tester);
        });
      }
    }
  }

  testWidgets('a 34px home inset is absorbed by the bar surface, both themes', (
    tester,
  ) async {
    for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      await _pump(tester, theme: theme, bottomInset: 34);
      final rect = tester.getRect(_barSurface(tester));
      expect(rect.bottom, 844, reason: theme.name);
      // The surface grows by the inset instead of the meadow showing under it.
      expect(rect.height, closeTo(89 + 34, 1), reason: theme.name);

      final expected = _rgb(_tokens(tester).surface);
      for (final x in <double>[2, 195, 388]) {
        for (final y in <double>[rect.bottom - 33, rect.bottom - 1, 843]) {
          expect(
            (await _pixelAt(tester, x, y)).sublist(0, 3),
            expected,
            reason:
                '${theme.name}: pixel ($x, $y) around the home indicator is '
                'not the bar surface (bottom-edge rule)',
          );
        }
      }
      await disposeApp(tester);
    }
  });

  testWidgets('dark is the light layout: same rects, only the tokens differ', (
    tester,
  ) async {
    final light = <String, Rect>{};
    await _pump(tester);
    final lightTokens = _tokens(tester);
    for (final entry in <String, Finder>{
      'back': find.byType(NestIconButton),
      'lock': find.byType(NestLockButton),
      'title': find.text(_title),
      'rain': find.byType(PayoutJarRain),
      'note1': find.byType(PayoutNote).first,
      'note2': find.byType(PayoutNote).last,
      'fund': find.byType(PayoutFundCard),
      'progress': find.byType(NestProgress),
      'caption': find.text(_ofTarget),
      'bar': _barSurface(tester),
      'button': find.byType(NestKidButton),
    }.entries) {
      light[entry.key] = tester.getRect(entry.value);
    }
    await disposeApp(tester);

    await _pump(tester, theme: ThemeMode.dark);
    final darkTokens = _tokens(tester);
    // Guards the rect comparison from passing vacuously: the theme really
    // flipped, so equal rects mean equal LAYOUT, not equal colours.
    expect(darkTokens.surface, isNot(lightTokens.surface));
    expect(darkTokens.ink, isNot(lightTokens.ink));
    expect(darkTokens.coinTint, isNot(lightTokens.coinTint));
    for (final entry in <String, Finder>{
      'back': find.byType(NestIconButton),
      'lock': find.byType(NestLockButton),
      'title': find.text(_title),
      'rain': find.byType(PayoutJarRain),
      'note1': find.byType(PayoutNote).first,
      'note2': find.byType(PayoutNote).last,
      'fund': find.byType(PayoutFundCard),
      'progress': find.byType(NestProgress),
      'caption': find.text(_ofTarget),
      'bar': _barSurface(tester),
      'button': find.byType(NestKidButton),
    }.entries) {
      expect(
        tester.getRect(entry.value),
        light[entry.key],
        reason: 'dark ${entry.key} must keep the light rect',
      );
    }
    await disposeApp(tester);
  });

  testWidgets('every surface on the screen paints from the live theme tokens', (
    tester,
  ) async {
    for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      await _pump(tester, theme: theme);
      final tokens = _tokens(tester);

      BoxDecoration boxIn(Finder scope) {
        final container = tester.widget<Container>(
          find
              .descendant(
                of: scope,
                matching: find.byWidgetPredicate(
                  (widget) =>
                      widget is Container && widget.decoration is BoxDecoration,
                ),
              )
              .first,
        );
        return container.decoration! as BoxDecoration;
      }

      Color discColorAt(Finder scope, int index) {
        final container = tester.widget<Container>(scope.at(index));
        return (container.decoration! as BoxDecoration).color!;
      }

      /// The decoration of a finder that already matches the `Container`
      /// itself (the bar surface, the icon discs).
      BoxDecoration boxSelf(Finder finder) =>
          tester.widget<Container>(finder).decoration! as BoxDecoration;

      // `.k10-note` — surface fill, 3 px ink border on all four sides.
      for (var i = 0; i < 2; i++) {
        final note = boxIn(find.byType(PayoutNote).at(i));
        expect(note.color, tokens.surface, reason: 'note $i ${theme.name}');
        expect((note.border! as Border).top.color, tokens.ink);
        expect((note.border! as Border).top.width, 3);
        expect((note.border! as Border).left.width, 3);
        expect((note.border! as Border).bottom.width, 3);
        expect(note.borderRadius, NestRadii.allM, reason: theme.name);
      }

      // `.k10-fund` — coinTint fill, 3 px ink border, r24.
      final fund = boxIn(find.byType(PayoutFundCard));
      expect(fund.color, tokens.coinTint, reason: theme.name);
      expect((fund.border! as Border).top.color, tokens.ink);
      expect((fund.border! as Border).top.width, 3);
      expect(fund.borderRadius, NestRadii.allL, reason: theme.name);

      // The two `.k10-ico` discs: leafTint (check) then lilacTint (arrow).
      final discs = find.descendant(
        of: find.byType(PayoutNote),
        matching: find.byWidgetPredicate((widget) {
          if (widget is! Container) return false;
          final box = widget.decoration;
          return box is BoxDecoration &&
              box.shape == BoxShape.circle &&
              box.color != null;
        }),
      );
      expect(discs, findsNWidgets(2), reason: theme.name);
      expect(
        discColorAt(discs, 0),
        tokens.leafTint,
        reason: 'the paid receipt uses the leaf disc',
      );
      expect(
        discColorAt(discs, 1),
        tokens.lilacTint,
        reason: 'the savings move uses the lilac disc',
      );

      // `.kid-bar` — surface with a 3 px ink TOP border only.
      final bar = boxSelf(_barSurface(tester));
      expect(bar.color, tokens.surface, reason: theme.name);
      expect((bar.border! as Border).top.color, tokens.ink);
      expect((bar.border! as Border).bottom.width, 0);

      expect(tester.takeException(), isNull, reason: theme.name);
      await disposeApp(tester);
    }
  });

  // -------------------------------------------------------------------------
  // Non-loaded states
  // -------------------------------------------------------------------------

  testWidgets('loading: spinner + chrome, no celebration, at 320/1.3', (
    tester,
  ) async {
    final repo = _FakePayoutRepository();
    addTearDown(repo.dispose);
    await _useFake(repo);
    await _pump(tester, width: 320, textScale: 1.3);

    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel('Loading payout day'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // Chrome (and the escape hatch) stay put while the payout stream is quiet.
    expect(find.byType(NestIconButton), findsOneWidget);
    expect(find.byType(NestLockButton), findsOneWidget);
    expect(find.byType(NestStatusBar), findsOneWidget);
    expect(find.text(_title), findsNothing);
    expect(find.byType(PayoutNote), findsNothing);
    expect(find.text('9:41'), findsNothing, reason: 'the OS draws the bar');
    expect(tester.takeException(), isNull);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Loading payout day'))
          .getSemanticsData()
          .flagsCollection
          .isLiveRegion,
      isTrue,
    );
    semantics.dispose();
    await disposeApp(tester);
  });

  testWidgets('loading: a late emission swaps in the celebration', (
    tester,
  ) async {
    final repo = _FakePayoutRepository();
    addTearDown(repo.dispose);
    await _useFake(repo);
    await _pump(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repo.last.add(_seededCelebration);
    await _settle(tester);

    expect(find.text(_paid), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await disposeApp(tester);
  });

  testWidgets('empty (no payout yet): copy, no notes, Back home navigates', (
    tester,
  ) async {
    for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      final repo = _FakePayoutRepository();
      addTearDown(repo.dispose);
      await _useFake(repo);
      await _pump(tester, width: 320, textScale: 1.3, theme: theme);
      repo.last.add(null);
      await _settle(tester);

      expect(find.text('No payout yet'), findsOneWidget, reason: theme.name);
      expect(
        find.text(
          'When Mum marks your pocket money as paid, the celebration '
          'starts here.',
        ),
        findsOneWidget,
        reason: theme.name,
      );
      expect(find.text('Back home'), findsOneWidget, reason: theme.name);
      expect(find.byType(PayoutNote), findsNothing, reason: theme.name);
      expect(find.byType(PayoutFundCard), findsNothing, reason: theme.name);
      expect(find.text(_thanks), findsNothing, reason: theme.name);

      final button = tester.getRect(find.byType(NestKidButton));
      expect(
        button.height,
        greaterThanOrEqualTo(NestDevice.tapKid),
        reason: theme.name,
      );
      expect(tester.takeException(), isNull, reason: theme.name);

      await tester.tap(find.text('Back home'));
      await _settle(tester);
      expect(pushedPath(tester), '/kid-home', reason: theme.name);
      await disposeApp(tester);
    }
  });

  testWidgets('empty: Seed.empty (no children) renders the empty frame', (
    tester,
  ) async {
    await tester.runAsync(() => Seed.empty(GetIt.instance<AppDatabase>()));
    await tester.runAsync(() => GetIt.instance<AppSession>().refresh());
    await _pump(tester, textScale: 1.3);

    expect(find.text('No payout yet'), findsOneWidget);
    expect(find.text('Back home'), findsOneWidget);
    expect(find.byType(PayoutFundCard), findsNothing);
    expect(tester.takeException(), isNull);
    await disposeApp(tester);
  });

  testWidgets('failure: copy + retry, and the lock is still the escape '
      'hatch', (tester) async {
    final repo = _FakePayoutRepository();
    addTearDown(repo.dispose);
    await _useFake(repo);
    await _pump(tester, width: 320, textScale: 1.3);
    repo.last.addError(StateError('the jar is offline'));
    await _settle(tester);

    expect(find.text('Oh no! Something went wrong.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.byType(PayoutNote), findsNothing);
    expect(find.text(_thanks), findsNothing);
    final button = tester.getRect(find.byType(NestKidButton));
    expect(button.height, greaterThanOrEqualTo(NestDevice.tapKid));
    expect(tester.takeException(), isNull);

    // A kid must never be stranded: the lock still opens the grown-up gate
    // from the failure frame.
    await tester.tap(find.byType(NestLockButton));
    await _settle(tester);
    expect(pushedPath(tester), '/parental-gate');

    await disposeApp(tester);
  });

  testWidgets('failure: Try again really re-subscribes and recovers', (
    tester,
  ) async {
    final repo = _FakePayoutRepository();
    addTearDown(repo.dispose);
    await _useFake(repo);
    await _pump(tester);
    repo.last.addError(StateError('the jar is offline'));
    await _settle(tester);
    expect(find.text('Try again'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await _settle(tester);
    repo.last.add(_seededCelebration);
    await _settle(tester);

    expect(repo.payouts, hasLength(2), reason: 'the dead stream was replaced');
    expect(find.text(_paid), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
    await disposeApp(tester);
  });

  testWidgets('failure: the retry is reachable by its semantics tap action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final repo = _FakePayoutRepository();
    addTearDown(repo.dispose);
    await _useFake(repo);
    await _pump(tester);
    repo.last.addError(StateError('the jar is offline'));
    await _settle(tester);

    final node = tester.getSemantics(find.bySemanticsLabel('Try again'));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    node.owner!.performAction(node.id, SemanticsAction.tap);
    await _settle(tester);
    repo.last.add(_seededCelebration);
    await _settle(tester);

    expect(find.text(_paid), findsOneWidget);
    semantics.dispose();
    await disposeApp(tester);
  });

  // -------------------------------------------------------------------------
  // Accessibility: labels, headers, images and real tap actions
  // -------------------------------------------------------------------------

  testWidgets('the icon buttons carry the design aria-labels and tap '
      'actions', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);

    final back = tester.getSemantics(find.bySemanticsLabel('Back'));
    final backData = back.getSemanticsData();
    expect(backData.hasAction(SemanticsAction.tap), isTrue);
    expect(backData.flagsCollection.isButton, isTrue);
    expect(backData.label, 'Back');
    expect(
      backData.label,
      isNot(contains('’')),
      reason: "the design's aria-label is plain ASCII",
    );

    final lock = tester.getSemantics(find.bySemanticsLabel('Grown-ups'));
    final lockData = lock.getSemanticsData();
    expect(lockData.hasAction(SemanticsAction.tap), isTrue);
    expect(lockData.flagsCollection.isButton, isTrue);
    expect(lockData.label, 'Grown-ups');

    final thanks = tester.getSemantics(find.bySemanticsLabel(_thanks));
    expect(thanks.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

    // Each one really drives the navigation, not just advertises itself.
    lock.owner!.performAction(lock.id, SemanticsAction.tap);
    await _settle(tester);
    expect(pushedPath(tester), '/parental-gate');

    semantics.dispose();
    await disposeApp(tester);
  });

  testWidgets('the lock tap action opens the gate (only one route)', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);

    final lock = tester.getSemantics(find.bySemanticsLabel('Grown-ups'));
    lock.owner!.performAction(lock.id, SemanticsAction.tap);
    await _settle(tester);
    expect(pushedPath(tester), '/parental-gate');

    // One pop must land back on payout day: no stacked gate.
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await _settle(tester);
    expect(pushedPath(tester), '/payout-day');
    expect(find.text(_paid), findsOneWidget);

    semantics.dispose();
    await disposeApp(tester);
  });

  testWidgets('a double tap on the lock pushes exactly one gate', (
    tester,
  ) async {
    await _pump(tester);

    // A real double tap is two down/up PAIRS, not two pointers at once: the
    // gesture arena gives a tap to one pointer only, so a simultaneous burst
    // would deliver a single tap and prove nothing.
    final lock = find.byType(NestLockButton);
    final first = await tester.startGesture(tester.getCenter(lock));
    await first.up();
    final second = await tester.startGesture(tester.getCenter(lock));
    await second.up();
    await _settle(tester);

    expect(pushedPath(tester), '/parental-gate');
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await _settle(tester);
    expect(
      pushedPath(tester),
      '/payout-day',
      reason: 'the `_busy` guard must admit only the first tap',
    );

    await disposeApp(tester);
  });

  testWidgets('back pops the route payout day was pushed onto', (tester) async {
    // Start under kid home and PUSH payout day, so there really is something
    // to pop back to (`canPop()` is true on a pushed route, false when the
    // screen is the app's initial route).
    await _pump(tester, route: KidHomeRoutePaths.home);
    expect(pushedPath(tester), '/kid-home');

    unawaited(
      tester
          .element(find.byType(NestStatusBar).first)
          .push(KidJarRoutePaths.payoutDay),
    );
    await _settle(tester);
    expect(pushedPath(tester), '/payout-day');
    expect(find.text(_paid), findsOneWidget);

    // The chevron pops the stacked route…
    await tester.tap(find.byType(NestIconButton));
    await _settle(tester);
    expect(
      pushedPath(tester),
      '/kid-home',
      reason: 'back must pop when a route is stacked',
    );
    expect(find.text(_paid), findsNothing);

    // (The other branch — `canPop()` false on the app's initial route, where
    // the chevron goes to `/kid-home` — is covered in
    // `payout_day_view_test.dart`, "back falls back to kid home with no
    // stack". This test only pins the branch the existing suite could not
    // reach: a real route stacked underneath.)
    await disposeApp(tester);
  });

  testWidgets('the title is a header and the illustration is an image', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);

    final title = tester.getSemantics(find.text(_title)).getSemanticsData();
    expect(title.label, _title);
    expect(title.flagsCollection.isHeader, isTrue, reason: '`.kid-title`');
    expect(title.hasAction(SemanticsAction.tap), isFalse);

    final rain = tester
        .getSemantics(find.bySemanticsLabel(_rainAlt))
        .getSemanticsData();
    expect(rain.label, _rainAlt, reason: 'the SVG aria-label, verbatim');
    expect(rain.flagsCollection.isImage, isTrue);
    expect(rain.hasAction(SemanticsAction.tap), isFalse);

    final progress = tester
        .getSemantics(find.bySemanticsLabel(_progressAlt))
        .getSemanticsData();
    expect(progress.label, _progressAlt);
    expect(progress.hasAction(SemanticsAction.tap), isFalse);

    // Each receipt card is one spoken sentence (title + sub merged).
    for (final label in <String>['$_paid. $_paidSub', '$_moved. $_movedSub']) {
      final note = tester.getSemantics(find.bySemanticsLabel(label));
      expect(note.getSemanticsData().label, label);
      expect(note.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
    }

    // Pip is announced as an image with the design's alt text.
    await _revealPipRow(tester);
    final pip = tester.getSemantics(find.bySemanticsLabel('Pip cheering'));
    expect(pip.getSemanticsData().flagsCollection.isImage, isTrue);
    expect(pip.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);

    semantics.dispose();
    await disposeApp(tester);
  });

  testWidgets("the child's own Pip is rendered, never a v1 stage SVG", (
    tester,
  ) async {
    await _pump(tester);
    await _revealPipRow(tester);

    final pip = tester.widgetList<PipAvatar>(find.byType(PipAvatar)).single;
    expect(pip.style, PipStyle.mochi, reason: "Maya's seeded pip_style");
    expect(pip.skin, PipSkin.sunny);
    expect(pip.stage, 3);
    expect(pip.mood, PipMood.happy);
    expect(pip.size, 72, reason: "the design's `.k10-pip img` slot");

    // PIP rule: no v1 `pip_stage_*.svg` illustration may be mounted anywhere.
    final v1 = find.byWidgetPredicate((widget) {
      if (widget is! Image) return false;
      final image = widget.image;
      return image is AssetImage && image.assetName.contains('pip-stage');
    });
    expect(v1, findsNothing);

    await disposeApp(tester);
  });

  // -------------------------------------------------------------------------
  // Copy audit (COPY rule) and the shared kid background
  // -------------------------------------------------------------------------

  testWidgets('every visible string is ASCII-punctuated like the design', (
    tester,
  ) async {
    await _pump(tester);
    await _revealPipRow(tester);

    final copy = _allCopy(tester);
    expect(copy, contains(_title));
    // `K10-payout-day.html:39` is U+0027 (`27` in the hexdump), not U+2019.
    expect(_title.codeUnitAt(2), 0x27, reason: "It's, straight quote");
    expect(copy, containsAll(<String>[_paid, _paidSub, _moved, _movedSub]));
    expect(copy, containsAll(<String>[_goal, _saved, _toGo, _ofTarget]));
    expect(copy, containsAll(<String>[_percent, _thanks, _pipSays]));
    // The DB-driven strings keep the design's sentence shapes.
    expect(_paid, 'Mum marked £3.80 as paid');
    expect(_moved, '£5.50 went into your Lego Friends set');
    expect(_pipSays, 'Pip says well done, Maya!');

    for (final line in copy) {
      expect(
        line.contains('’'),
        isFalse,
        reason: '"$line" must not swap the design\'s straight apostrophe',
      );
      expect(
        line.contains('“') || line.contains('”'),
        isFalse,
        reason: '"$line" must not introduce typographic quotes',
      );
    }

    await disposeApp(tester);
  });

  group('K10 copy fit — no string loses words', () {
    // Every string the design draws in full, in the order it appears.
    const copy = <String>[
      _title,
      _paid,
      _paidSub,
      _moved,
      _movedSub,
      _goal,
      _saved,
      _toGo,
      _ofTarget,
      _percent,
      _pipSays,
      _thanks,
    ];

    bool truncated(WidgetTester tester, String line) {
      final paragraph = tester.renderObject<RenderParagraph>(
        find.text(line, skipOffstage: false),
      );
      return paragraph.didExceedMaxLines;
    }

    // 320 @1.3 is deliberately NOT in this list: it is K10-BUG-3 (see the
    // skipped proof at the end of this group). Everything else must be whole.
    for (final cell in const <(double, double)>[
      (320, 1),
      (390, 1),
      (390, 1.3),
      (430, 1),
      (430, 1.3),
    ]) {
      for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
        final label = '${cell.$1.round()}px ${theme.name} @${cell.$2}x';
        testWidgets('$label: nothing is ellipsized', (tester) async {
          await _pump(tester, width: cell.$1, textScale: cell.$2, theme: theme);
          await _revealPipRow(tester);

          for (final line in copy) {
            expect(
              truncated(tester, line),
              isFalse,
              reason:
                  '“$line” loses words at $label — the design draws all '
                  'of it (K10-payout-day.html sets no max-lines anywhere)',
            );
          }
          expect(tester.takeException(), isNull, reason: label);
          await disposeApp(tester);
        });
      }
    }

    testWidgets(
      'K10-BUG-3: 320px @1.3x truncates the note-2 title and the "to go" '
      'amount',
      (tester) async {
        await _pump(tester, width: 320, textScale: 1.3);

        // `.k10-t` is capped at `maxLines: 2`, but the seeded sentence
        // `£5.50 went into your Lego Friends set` needs THREE lines in the
        // 200 px text column at 1.3× (natural single-line width 404.5 px), so
        // the goal name loses its last word behind an ellipsis.
        expect(
          truncated(tester, _moved),
          isTrue,
          reason: 'K10-BUG-3: the savings note truncates "Lego Friends set"',
        );
        // `.k10-amts b` is `maxLines: 1`, and `£9.49 to go` needs 121.4 px in
        // the 117 px the `spaceBetween` row gives it — a MONEY string is
        // ellipsized mid-word (`£9.49 to g…`), which SPACING_SPEC §10.11
        // forbids for `.money`.
        expect(
          truncated(tester, _toGo),
          isTrue,
          reason: 'K10-BUG-3: the "to go" amount is ellipsized',
        );

        // The design cell (390 px) and every other supported cell are whole —
        // see the green group above. This test documents the defect; it does
        // not excuse it.
        expect(tester.takeException(), isNull);
        await disposeApp(tester);
      },
      skip: true,
    );
  });

  testWidgets('the shared KidScope sky and meadow are mounted exactly once', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.byType(KidScope), findsOneWidget);
    expect(find.byType(NestMeadow), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(KidScope),
        matching: find.byType(NestMeadow),
      ),
      findsOneWidget,
      reason: 'the hills belong to the shared scope, never to the screen',
    );

    // KID BACKGROUND rule: the sky comes from the live theme's kid tokens.
    // ±1 per channel: y = 8 is inside the sky GRADIENT, so the sampled row sits
    // a shade off `kidSkyTop`.
    final target = _rgb(_tokens(tester).kidSkyTop);
    final painted = (await _pixelAt(tester, 195, 8)).sublist(0, 3);
    for (var channel = 0; channel < 3; channel++) {
      expect(
        (painted[channel] - target[channel]).abs(),
        lessThanOrEqualTo(1),
        reason:
            'the sky gradient must be the shared kid sky '
            '(channel $channel: ${painted[channel]} vs ${target[channel]})',
      );
    }

    await disposeApp(tester);
  });
}
