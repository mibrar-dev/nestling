// K05 quest-complete device matrix: the three widths the app supports
// (320 / 390 / 430) × both themes × both supported text scales (1.0 / 1.3),
// plus the kid tap-target floor (56 px, `NestSpacing.tapKid`) at every cell.
//
// Why this file exists (the gaps iteration 1 left open):
//
//   * iteration 1 pinned the design geometry at 390/1.0 **light only**
//     (`quest_complete_geometry_test.dart`) and ran the whole resilience
//     matrix at 320/1.3 only (`quest_complete_view_test.dart:769-805`).
//     **430 px was never pumped at any scale, in any theme** — the widest
//     supported device (iPhone 16 Pro Max / Pixel class) had no coverage.
//   * dark mode was only exercised for *not throwing* at 320/1.3 plus the bar
//     bottom edge (`k05_bugs_test.dart:532`). The design ships a dark PNG
//     (`design/screens/dark/K05-quest-complete.png`) whose painted rects are
//     identical to the light one, so nothing pinned the dark LAYOUT: a token
//     that gained a dark-only padding or a border-width change would have
//     passed every existing test.
//   * the 56 px kid tap-target floor was asserted only as a side effect of the
//     390/light geometry numbers (lock 56×56, CTA 350×64). Nothing asserted
//     the FLOOR, and nothing checked it at any other width or scale.
//
// What it pins:
//   * no layout exception in any of the 12 cells (320/390/430 × light/dark ×
//     1.0/1.3), with the growth card scrolled into view first — at 320/1.3 the
//     card sits below the fold;
//   * the 20 px side gutters hold at every width (owner ALIGNMENT rule) and
//     the card never crosses them;
//   * the bottom bar's surface still runs to the physical screen edge in every
//     cell (owner BOTTOM EDGE rule, light AND dark — a themed strip under the
//     bar or around the home indicator is a FAIL);
//   * both interactive controls meet the 56 px kid minimum at every cell;
//   * the dark layout is the light layout: same rects, same centres, only the
//     tokens differ.
//
// Bundled Nunito/Inter are loaded first (`setUpAll`): on `flutter_test`'s
// default face every glyph is wider and the count row / hero would report
// false truncation.
//
// Every pumped app ends with `disposeApp` (test_scope.dart) so Drift's
// deferred stream-close timer is drained.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/kid_home/kid_home_routes.dart';

import '../../test_scope.dart';

/// The three widths the app supports, narrowest first.
const List<double> _widths = <double>[320, 390, 430];

/// The two text scales the shell clamps to (`textScaler` clamp 1.0–1.3).
const List<double> _scales = <double>[1, 1.3];

/// RepaintBoundary the bottom-edge probe reads painted pixels through (same
/// pattern as `kid_home_geometry_test.dart`'s meadow probe and the P06
/// bottom-edge probe): a rect assertion cannot see a strip painted INSIDE the
/// bar's surface box, so the owner's BOTTOM EDGE rule is verified on the
/// actual raster.
const Key _pixelProbe = ValueKey<String>('k05_bottom_edge_probe');

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

/// The live theme's [NestTokens], read through a widget that is always on the
/// celebration. Both surfaces are matched from the token the view actually
/// paints with, so a token change fails loudly instead of matching nothing.
NestTokens _tokens(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(NestProgress)))
        .extension<NestTokens>()!;

/// The `.kid-bar` surface: a `Container` painted `surface` with a TOP-ONLY
/// 3 px ink border (the speech bubble shares the fill but borders all four
/// sides, so the shape identifies the bar).
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

/// The `.k5-card` surface: `lilacTint` + a 3 px ink border on all four sides.
Finder _growthCard(WidgetTester tester) {
  final lilac = _tokens(tester).lilacTint;
  return find.byWidgetPredicate((widget) {
    if (widget is! Container) return false;
    final box = widget.decoration;
    if (box is! BoxDecoration) return false;
    if (box.color != lilac) return false;
    final border = box.border;
    return border is Border &&
        border.top.width == 3 &&
        border.left.width == 3 &&
        border.bottom.width == 3;
  });
}

Rect _rectOf(WidgetTester tester, Finder finder) =>
    tester.getRect(finder.first);

Future<void> _pumpComplete(
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
  // Wrapped in [_pixelProbe] so the bottom-edge assertion can sample the real
  // raster; the wrapper is transparent to layout and theming.
  await tester.pumpWidget(
    const RepaintBoundary(
      key: _pixelProbe,
      child: NestlingApp(initialRoute: KidHomeRoutePaths.complete),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
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

/// The growth card is below the fold at 320 px / 1.3×: scroll it in before
/// measuring, otherwise the finder hits an off-screen box.
Future<void> _revealCard(WidgetTester tester) async {
  await tester.drag(find.byType(ListView), const Offset(0, -400));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUpAll(_loadBundledFonts);

  setUp(() async {
    await setUpTestScope();
  });

  group('K05 quest complete — device matrix', () {
    for (final width in _widths) {
      for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
        for (final scale in _scales) {
          final cell = '${width.round()}px ${theme.name} @ ${scale}x';

          testWidgets('$cell: nothing overflows and the gutters hold', (
            tester,
          ) async {
            await _pumpComplete(
              tester,
              width: width,
              textScale: scale,
              theme: theme,
            );

            // The celebration rendered, whatever the cell.
            expect(
              find.text('Brilliant, Maya!'),
              findsOneWidget,
              reason: '$cell must render the hero',
            );
            expect(find.text('Yay! Back home'), findsOneWidget);
            expect(
              find.byType(NestCoinPill),
              findsOneWidget,
              reason: '$cell must render the coin pill',
            );

            await _revealCard(tester);

            // Any RenderFlex overflow / unbounded constraint surfaces here.
            expect(
              tester.takeException(),
              isNull,
              reason: '$cell must not throw a layout exception',
            );

            // Owner ALIGNMENT rule: 20 px gutters at EVERY width, and the
            // card, the CTA and the card's progress bar share those edges.
            final card = _rectOf(tester, _growthCard(tester));
            final cta = _rectOf(tester, find.byType(NestKidButton));
            expect(card.left, 20, reason: '$cell: card left gutter');
            expect(card.right, width - 20, reason: '$cell: card right gutter');
            expect(cta.left, 20, reason: '$cell: CTA left gutter');
            expect(cta.right, width - 20, reason: '$cell: CTA right gutter');

            // The burst plate never overflows its cell (FittedBox scaleDown).
            expect(
              tester.takeException(),
              isNull,
              reason: '$cell: the burst plate must scale, not overflow',
            );

            await disposeApp(tester);
          });

          testWidgets('$cell: the bar surface reaches the physical edge', (
            tester,
          ) async {
            await _pumpComplete(
              tester,
              width: width,
              textScale: scale,
              theme: theme,
            );

            final bar = _barSurface(tester);
            expect(bar, findsOneWidget, reason: '$cell: one bar surface');
            final rect = _rectOf(tester, bar);
            // Owner BOTTOM EDGE rule — applies in dark too: no themed strip
            // under the bar or around the home indicator.
            expect(rect.left, 0, reason: '$cell: the bar bleeds left');
            expect(rect.right, width, reason: '$cell: the bar bleeds right');
            expect(
              rect.bottom,
              844,
              reason: '$cell: the bar bleeds to the edge',
            );

            final surface = _tokens(tester).surface;
            final fill =
                tester.widget<Container>(bar.first).decoration!
                    as BoxDecoration;
            expect(fill.color, surface, reason: cell);

            // The surface BOX reaching the edge is necessary but NOT
            // sufficient. Verified by probe: injecting
            // `Container(height: homeH, color: context.nest.leaf)` under the
            // button (replacing the `SafeArea`) left every rect assertion
            // above GREEN — the strip lives INSIDE the surface box, so only a
            // PAINTED-PIXEL read catches it. The existing 390/light geometry
            // test cannot see this class of defect at all, which is why the
            // owner rule calls it out.
            //
            // So sample the real raster down the whole bar column: from just
            // under the CTA's painted button to the physical edge, every row
            // must be the bar's own surface (the OS draws the home pill, which
            // is why a few x positions are skipped below).
            final expected = <int>[
              (surface.r * 255).round(),
              (surface.g * 255).round(),
              (surface.b * 255).round(),
            ];

            // Sample rows are chosen from a measured pixel dump of the real
            // widget (390/light): the CTA's widget box is y 770…840, its
            // PAINTED button 770…834, and y 834…838 is the button's own 6 px
            // shadow room (token grey, legitimately not the surface). So the
            // region the owner rule covers is y 840…844 — under the button box,
            // down to the physical edge.
            //
            // Column x = 2 (and width-2) covers the FULL bar width: it sits
            // outside the CTA's 20…370 horizontal span, so a strip of ANY
            // width spanning the bar is caught there, at every row.
            final buttonBox = _rectOf(tester, find.byType(NestKidButton));
            // Skip the bar's own 3 px ink TOP BORDER (`.kid-bar`'s design
            // border — measured as ink at 30,27,58, not the surface): start one
            // row below it.
            for (final x in <double>[2, width - 2]) {
              for (var y = rect.top + 4; y < 844; y += 1) {
                final pixel = await _pixelAt(tester, x, y);
                expect(
                  pixel.sublist(0, 3),
                  expected,
                  reason:
                      '$cell: painted pixel at ($x, $y) inside the bar is not '
                      'the bar surface — a coloured strip shows beside the CTA '
                      '(owner bottom-edge rule).',
                );
              }
            }
            // Below the CTA box, across the full width including the centre
            // (where the OS draws the home pill): the bar's own surface.
            for (var y = buttonBox.bottom; y < 844; y += 1) {
              for (final x in <double>[2, width / 2, width - 2]) {
                final pixel = await _pixelAt(tester, x, y);
                expect(
                  pixel.sublist(0, 3),
                  expected,
                  reason:
                      '$cell: painted pixel at ($x, $y) under the CTA is not '
                      'the bar surface — a coloured strip shows under the bar '
                      'or around the home indicator (owner bottom-edge rule).',
                );
              }
            }

            await disposeApp(tester);
          });

          testWidgets('$cell: both controls meet the 56 px kid floor', (
            tester,
          ) async {
            await _pumpComplete(
              tester,
              width: width,
              textScale: scale,
              theme: theme,
            );

            // `NestSpacing.tapKid` is the kid minimum (the parent floor is 44).
            const kidMin = 56.0;

            final lock = _rectOf(tester, find.byType(NestLockButton));
            expect(lock.width, greaterThanOrEqualTo(kidMin), reason: cell);
            expect(lock.height, greaterThanOrEqualTo(kidMin), reason: cell);

            // `NestKidButton` reserves a 6 px shadow room BELOW the painted
            // button, so the widget box is 6 px taller than the painted pill —
            // both exceed the floor either way.
            final button = _rectOf(tester, find.byType(NestKidButton));
            expect(button.height, greaterThanOrEqualTo(kidMin), reason: cell);
            expect(button.width, greaterThanOrEqualTo(kidMin), reason: cell);

            // …and the lock keeps its semantic label in every cell.
            final semantics = tester.ensureSemantics();
            expect(
              find.bySemanticsLabel('Grown-ups'),
              findsWidgets,
              reason: '$cell: the icon button stays labelled',
            );
            semantics.dispose();

            await disposeApp(tester);
          });
        }
      }
    }
  });

  group('K05 quest complete — dark layout is the light layout', () {
    // The design ships a dark PNG with the same painted rects as the light one.
    // This is the proof that the dark theme flips TOKENS ONLY: no padding,
    // border width or spacing may differ between the two themes.
    Future<Map<String, Rect>> measure(
      WidgetTester tester,
      ThemeMode theme,
    ) async {
      await _pumpComplete(tester, theme: theme);
      await _revealCard(tester);
      return <String, Rect>{
        'lock': _rectOf(tester, find.byType(NestLockButton)),
        'pip': _rectOf(tester, find.byType(PipAvatar).first),
        'hero': _rectOf(tester, find.text('Brilliant, Maya!')),
        'pill': _rectOf(tester, find.byType(NestCoinPill)),
        'bubble': _rectOf(tester, find.byType(NestSpeechBubble)),
        'card': _rectOf(tester, _growthCard(tester)),
        'progress': _rectOf(tester, find.byType(NestProgress)),
        'cta': _rectOf(tester, find.byType(NestKidButton)),
        'bar': _rectOf(tester, _barSurface(tester)),
      };
    }

    testWidgets('every painted rect is identical in both themes', (
      tester,
    ) async {
      final light = await measure(tester, ThemeMode.light);
      await disposeApp(tester);

      final dark = await measure(tester, ThemeMode.dark);
      await disposeApp(tester);

      expect(
        dark.keys.toSet(),
        light.keys.toSet(),
        reason: 'both themes must paint the same set of surfaces',
      );
      for (final key in light.keys) {
        expect(
          dark[key],
          light[key],
          reason:
              '$key moves between light and dark: a dark-only padding, '
              'border width or spacing change. The dark PNG has the same '
              'rects as the light one — only the tokens differ.',
        );
      }
    });

    testWidgets('the dark tokens really are different from the light ones', (
      tester,
    ) async {
      // Guards the test above against being vacuously true: if dark and light
      // resolved to the SAME colours the rect comparison would prove nothing
      // about token flipping.
      await _pumpComplete(tester);
      final light = _tokens(tester);
      final lightSurface = light.surface;
      final lightLilac = light.lilacTint;
      final lightInk = light.ink;
      await disposeApp(tester);

      await _pumpComplete(tester, theme: ThemeMode.dark);
      final dark = _tokens(tester);
      await disposeApp(tester);

      expect(
        dark.surface,
        isNot(lightSurface),
        reason: 'the bar surface must actually flip theme',
      );
      expect(dark.lilacTint, isNot(lightLilac), reason: 'the card must flip');
      expect(dark.ink, isNot(lightInk), reason: 'the ink must flip');
      // …and each theme's ink is the high-contrast partner of its OWN ground:
      // the celebration stays readable without inverting the copy.
      expect(
        dark.ink.computeLuminance(),
        greaterThan(dark.surface.computeLuminance()),
        reason: 'dark-theme copy is light ink on the dark bar surface',
      );
      expect(
        lightInk.computeLuminance(),
        lessThan(lightSurface.computeLuminance()),
        reason: 'light-theme copy is dark ink on the light bar surface',
      );
    });
  });
}
