// Shared kid background: exact `.screen.kid` + `.meadow` transcription.
//
// Design source: `design/html-source/components.css:25` and
// `design/html-source/screens/K01-profile-picker.html:8-11,37` (identical on
// every kid screen). Verified against the rendered PNGs
// (`design/screens/light|dark/K01-profile-picker.png`, 1170x2532 = 390x844
// @3x; logical px = PNG px / 3):
//
// * sky: y 0 = kid-sky-top, y 523 (0.62 x 844) = kid-sky-bottom, then a hard
//   stop to kid-horizon grading to kid-meadow at the bottom.
// * hills (`.meadow` box top = 844 - 136 = 708; in-box y = design y - 708):
//   hill-back crest at x 30 -> in-box 44.3 (design 752), hill-front crest at
//   x 30 -> in-box 84.7 (design 793). Between the crests the PNG reads pure
//   kid-meadow; below hill-front it reads the 80/20 mix.
// * light bottom row (design y 843): (204, 237, 192) = #CCEDC0.
// * dark bottom row: (30, 65, 56) = #1E4138.
//
// Never asserts placeholder view texts (screen agents own those); asserts
// the painters, the router-independent background layers, and tap-through.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';

import 'test_harness.dart';

/// Paints [painter] into an image of [size] and returns the pixel at [at].
Future<Color> paintPixel(CustomPainter painter, Size size, Offset at) async {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), size);
  final image = await recorder.endRecording().toImage(
    size.width.toInt(),
    size.height.toInt(),
  );
  final data = await image.toByteData();
  final x = at.dx.toInt();
  final y = at.dy.toInt();
  final offset = (y * size.width.toInt() + x) * 4;
  return Color.fromARGB(
    data!.getUint8(offset + 3),
    data.getUint8(offset),
    data.getUint8(offset + 1),
    data.getUint8(offset + 2),
  );
}

/// Asserts the 8-bit raster channels of [actual] — what the design PNGs
/// store — instead of float equality (`Color.lerp` keeps fractions).
void expect8Bit(Color actual, int r, int g, int b) {
  expect((actual.r * 255).round(), r, reason: 'red of $actual');
  expect((actual.g * 255).round(), g, reason: 'green of $actual');
  expect((actual.b * 255).round(), b, reason: 'blue of $actual');
  expect(actual.a, 1);
}

void main() {
  group('kidHillFront (color-mix 80% meadow / 20% surface)', () {
    // `Color.lerp` interpolates in floating point, so compare the 8-bit
    // raster values — the design PNG's bottom rows — not float equality.
    test('light bakes to the design bottom row (204, 237, 192)', () {
      expect8Bit(
        kidHillFront(const Color(0xFFBFE8B0), const Color(0xFFFFFFFF)),
        204,
        237,
        192,
      );
    });

    test('dark bakes to the design bottom row (30, 65, 56)', () {
      expect8Bit(
        kidHillFront(const Color(0xFF1E4A3A), const Color(0xFF1F1C2E)),
        30,
        65,
        56,
      );
    });
  });

  group('NestMeadowPainter pixels (390x136, in-box coords)', () {
    // In-box y = design y - 708 (the `.meadow` box top at 844 - 136).
    // x 30: hill-back crest in-box 44.3, hill-front crest in-box 84.7.
    const size = Size(390, 136);

    test('light: back-only band, front overlay, bottom row', () async {
      const painter = NestMeadowPainter(
        back: Color(0xFFBFE8B0),
        front: Color(0xFFCCEDC0),
      );
      // Between the crests (design (30, 768)): pure hill-back.
      expect(
        await paintPixel(painter, size, const Offset(30, 60)),
        const Color(0xFFBFE8B0),
      );
      // Below hill-front (design (30, 808)): the 80/20 overlay.
      expect(
        await paintPixel(painter, size, const Offset(30, 100)),
        const Color(0xFFCCEDC0),
      );
      // Bottom row centre (design (195, 843)): overlay to the edge.
      expect(
        await paintPixel(painter, size, const Offset(195, 135)),
        const Color(0xFFCCEDC0),
      );
      // Right crest interior (design (360, 738)): hill-back above the front.
      expect(
        await paintPixel(painter, size, const Offset(360, 30)),
        const Color(0xFFBFE8B0),
      );
    });

    test('dark: back-only band, front overlay, bottom row', () async {
      const painter = NestMeadowPainter(
        back: Color(0xFF1E4A3A),
        front: Color(0xFF1E4138),
      );
      expect(
        await paintPixel(painter, size, const Offset(30, 60)),
        const Color(0xFF1E4A3A),
      );
      expect(
        await paintPixel(painter, size, const Offset(30, 100)),
        const Color(0xFF1E4138),
      );
      expect(
        await paintPixel(painter, size, const Offset(195, 135)),
        const Color(0xFF1E4138),
      );
      expect(
        await paintPixel(painter, size, const Offset(360, 30)),
        const Color(0xFF1E4A3A),
      );
    });

    test('above the hills is transparent (sky shows through)', () async {
      const painter = NestMeadowPainter(
        back: Color(0xFFBFE8B0),
        front: Color(0xFFCCEDC0),
      );
      // Design (30, 720): above the back crest (752) — the PNG reads the
      // horizon->meadow sky grade there, so the hills must paint nothing.
      expect(
        await paintPixel(painter, size, const Offset(30, 5)),
        const Color(0x00000000),
      );
    });
  });

  group('KidScope background at 390x844', () {
    Finder meadowPaint() => find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is NestMeadowPainter,
    );

    Finder skyBox() => find.byWidgetPredicate(
      (widget) =>
          widget is DecoratedBox &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).gradient is LinearGradient,
    );

    testWidgets('light: 4-stop sky gradient with the 62% horizon', (
      tester,
    ) async {
      await pumpNest(tester, const KidScope(child: SizedBox.expand()));
      final decoration =
          tester.widget<DecoratedBox>(skyBox()).decoration as BoxDecoration;
      final gradient = decoration.gradient! as LinearGradient;
      expect(decoration.color, NestColors.light.kidSkyBottom);
      expect(gradient.colors, <Color>[
        NestColors.light.kidSkyTop,
        NestColors.light.kidSkyBottom,
        NestColors.light.kidHorizon,
        NestColors.light.kidMeadow,
      ]);
      expect(gradient.stops, <double>[0, 0.62, 0.62, 1]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dark: same stops on the dark tokens, plus stars', (
      tester,
    ) async {
      await pumpNest(
        tester,
        const KidScope(child: SizedBox.expand()),
        mode: ThemeMode.dark,
      );
      final decoration =
          tester.widget<DecoratedBox>(skyBox()).decoration as BoxDecoration;
      final gradient = decoration.gradient! as LinearGradient;
      expect(gradient.colors, <Color>[
        NestColors.dark.kidSkyTop,
        NestColors.dark.kidSkyBottom,
        NestColors.dark.kidHorizon,
        NestColors.dark.kidMeadow,
      ]);
      expect(gradient.stops, <double>[0, 0.62, 0.62, 1]);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is CustomPaint && widget.painter is NestKidStarsPainter,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('light: no stars layer', (tester) async {
      await pumpNest(tester, const KidScope(child: SizedBox.expand()));
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is CustomPaint && widget.painter is NestKidStarsPainter,
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('light: hills use the token colours with the 80/20 front', (
      tester,
    ) async {
      await pumpNest(tester, const KidScope(child: SizedBox.expand()));
      final painter =
          tester.widget<CustomPaint>(meadowPaint()).painter!
              as NestMeadowPainter;
      expect(painter.back, NestColors.light.kidMeadow);
      expect8Bit(painter.front, 204, 237, 192);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dark: hills use the token colours with the 80/20 front', (
      tester,
    ) async {
      await pumpNest(
        tester,
        const KidScope(child: SizedBox.expand()),
        mode: ThemeMode.dark,
      );
      final painter =
          tester.widget<CustomPaint>(meadowPaint()).painter!
              as NestMeadowPainter;
      expect(painter.back, NestColors.dark.kidMeadow);
      expect8Bit(painter.front, 30, 65, 56);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'light: meadow pinned full-width 136 tall at the screen bottom',
      (tester) async {
        await pumpNest(tester, const KidScope(child: SizedBox.expand()));
        final rect = tester.getRect(meadowPaint());
        expect(rect.left, 0);
        expect(rect.right, closeTo(390, 0.5));
        expect(rect.height, closeTo(136, 0.5));
        expect(rect.bottom, closeTo(844, 0.5));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'dark: meadow pinned full-width 136 tall at the screen bottom',
      (tester) async {
        await pumpNest(
          tester,
          const KidScope(child: SizedBox.expand()),
          mode: ThemeMode.dark,
        );
        final rect = tester.getRect(meadowPaint());
        expect(rect.left, 0);
        expect(rect.right, closeTo(390, 0.5));
        expect(rect.height, closeTo(136, 0.5));
        expect(rect.bottom, closeTo(844, 0.5));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('background layers sit behind content and never take taps', (
      tester,
    ) async {
      var tapped = 0;
      await pumpNest(
        tester,
        KidScope(
          child: SizedBox.expand(
            child: Center(
              child: TextButton(
                onPressed: () => tapped++,
                child: const Text('Play'),
              ),
            ),
          ),
        ),
      );
      // Every background paint is wrapped in IgnorePointer (CSS
      // `pointer-events:none`): sky, meadow, and (in dark) stars.
      for (final paint in <Finder>[skyBox(), meadowPaint()]) {
        final ignoring = find.ancestor(
          of: paint,
          matching: find.byType(IgnorePointer),
        );
        expect(
          ignoring,
          findsWidgets,
          reason: 'background must not intercept taps',
        );
      }
      // Content still receives taps through the background.
      await tester.tap(find.text('Play'));
      await tester.pump();
      expect(tapped, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('meadowColor retints the back and rebakes the front', (
      tester,
    ) async {
      await pumpNest(
        tester,
        const KidScope(
          meadowHeight: 320,
          meadowColor: Color(0xFFEAF7E2),
          child: SizedBox.expand(),
        ),
      );
      final painter =
          tester.widget<CustomPaint>(meadowPaint()).painter!
              as NestMeadowPainter;
      expect(painter.back, const Color(0xFFEAF7E2));
      expect(
        painter.front,
        kidHillFront(const Color(0xFFEAF7E2), NestColors.light.surface),
      );
      expect(tester.getRect(meadowPaint()).height, closeTo(320, 0.5));
      expect(tester.takeException(), isNull);
    });
  });
}
