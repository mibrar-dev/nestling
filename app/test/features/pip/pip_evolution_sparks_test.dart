// K07 · `svg.sparks` — the layer's colours and its design-block facts,
// measured from the screen's own painted pixels.
//
// `pip_evolution_widget_test.dart` already pins the sparks' BOX (350x250 at
// `top: 92`, the letterboxed 350x220 art) with `tester.getRect`. This file
// covers what a rect cannot: that the layer paints exactly the design's five
// fills plus its ink stroke, in BOTH themes, and that it never puts a
// hard-coded colour on the render path.
//
// The SILHOUETTE is deliberately not asserted here: the painted sparkle shape
// is K07-BUG-1's subject and lives with its proof in
// `pip_evolution_sparks_bug_test.dart`. (An earlier version of this file
// compared the app's painter with a reference built by the same path recipe
// the screen uses; that recipe loses the design's `M` vertex, so the
// comparison agreed with itself and proved nothing. A reference has to be
// built independently to be worth anything.)
//
// Rasterisation needs the engine, so every read runs inside `tester.runAsync`
// (`Picture.toImageSync` hangs in the widget-test environment).

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart' hide PipStage;
import 'package:nestling/features/pip/presentation/widgets/pip_evolution_sparks.dart';

/// The design's `<svg class="sparks" …>` block — everything inside it, and
/// nothing from the lock/arrow/status SVGs further down the document.
String _sparksBlock() {
  var dir = Directory.current.absolute;
  for (var depth = 0; depth < 5; depth++) {
    final candidate = File(
      '${dir.path}/design/html-source/screens/K07-evolution.html',
    );
    if (candidate.existsSync()) {
      final html = candidate.readAsStringSync();
      final start = html.indexOf('<svg class="sparks"');
      if (start < 0) {
        throw StateError('K07-evolution.html has no `svg.sparks` block');
      }
      return html.substring(start, html.indexOf('</svg>', start));
    }
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError(
    'design/html-source/screens/K07-evolution.html not found above '
    '${Directory.current.path}',
  );
}

late String _block;

/// `<path d="…">` in document order.
List<String> get _paths =>
    RegExp('<path d="([^"]+)"')
        .allMatches(_block)
        .map((m) => m.group(1)!)
        .toList();

/// `<circle cx cy r>` in document order.
List<({double cx, double cy, double r})> get _circles =>
    RegExp(r'<circle cx="([-\d.]+)" cy="([-\d.]+)" r="([-\d.]+)"')
        .allMatches(_block)
        .map((m) {
          return (
            cx: double.parse(m.group(1)!),
            cy: double.parse(m.group(2)!),
            r: double.parse(m.group(3)!),
          );
        })
        .toList();

/// The `fill` attribute of every drawn entry, in the order the painter walks
/// them (four sparkles, then four circles).
List<int> get _fills => <int>[
  for (final m in RegExp('fill="#([0-9A-Fa-f]{6})"').allMatches(_block))
    int.parse(m.group(1)!, radix: 16),
];

void main() {
  setUpAll(() {
    _block = _sparksBlock();
  });

  Future<void> pumpSparks(
    WidgetTester tester, {
    required ThemeData theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Center(
          child: SizedBox.fromSize(
            size: EvolutionSparksGeometry.artSize,
            child: const PipEvolutionSparks(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// The screen's own painter, taken from the widget so the test measures what
  /// is actually drawn (never a private import).
  CustomPainter appPainter(WidgetTester tester) => tester
      .widget<CustomPaint>(
        find.descendant(
          of: find.byType(PipEvolutionSparks),
          matching: find.byType(CustomPaint),
        ),
      )
      .painter!;

  /// Paints the screen's painter offscreen and reads the RGBA bytes back.
  Future<Uint8List> rasterise(WidgetTester tester) async {
    const size = EvolutionSparksGeometry.artSize;
    final painter = appPainter(tester);
    final recorder = ui.PictureRecorder();
    painter.paint(Canvas(recorder), size);
    final picture = recorder.endRecording();
    final bytes = await tester.runAsync(() async {
      final image = await picture.toImage(
        size.width.toInt(),
        size.height.toInt(),
      );
      final data = await image.toByteData();
      return data!.buffer.asUint8List();
    });
    return bytes!;
  }

  group('the colours are tokens, never literals', () {
    for (final theme in <ThemeData>[NestTheme.light(), NestTheme.dark()]) {
      testWidgets(
        '${theme.brightness.name}: the layer paints the five design fills '
        'and the ink stroke, and nothing else',
        (tester) async {
          final tokens = theme.extension<NestTokens>()!;
          await pumpSparks(tester, theme: theme);
          final bytes = await rasterise(tester);

          // Every fully opaque colour the layer puts on the render path.
          final opaque = <int>{};
          for (var i = 0; i < bytes.length; i += 4) {
            if (bytes[i + 3] != 255) continue;
            opaque.add(
              (bytes[i + 3] << 24) |
                  (bytes[i] << 16) |
                  (bytes[i + 1] << 8) |
                  bytes[i + 2],
            );
          }
          expect(opaque, isNotEmpty, reason: 'the layer must paint something');

          final palette = <Color>[
            tokens.lilac,
            tokens.success,
            tokens.coin,
            tokens.peach,
            tokens.sky,
            tokens.ink,
          ];
          // Antialiasing blends the fill into the 3 px stroke, so opaque
          // pixels include fill/stroke mixtures; every one must still be ON the
          // token palette. The tolerance is tight enough to reject the
          // design's one-off `#3D7FF0` (24/28/26 per channel from `--sky`,
          // pinned separately below).
          const channelTolerance = 12;
          for (final argb in opaque) {
            final colour = Color(argb);
            final nearest = palette
                .map(
                  (token) =>
                      (token.r - colour.r).abs() +
                      (token.g - colour.g).abs() +
                      (token.b - colour.b).abs(),
                )
                .reduce((a, b) => a < b ? a : b);
            expect(
              nearest,
              lessThanOrEqualTo(channelTolerance * 3),
              reason:
                  '#${argb.toRadixString(16).padLeft(8, '0')} is not a '
                  'token colour (nor a blend of them)',
            );
          }

          // All five fills are actually used (four sparkles + four dots).
          for (final token in <Color>[
            tokens.lilac,
            tokens.success,
            tokens.coin,
            tokens.peach,
            tokens.sky,
          ]) {
            expect(
              opaque,
              contains(token.toARGB32()),
              reason: '$token never appears',
            );
          }
          // The `<g>` stroke is `tokens.ink`.
          expect(opaque, contains(tokens.ink.toARGB32()));
        },
      );
    }

    testWidgets('the design’s non-token #3D7FF0 dot is NOT painted literally', (
      tester,
    ) async {
      // `tokens.css:20` defines `--sky: #2563D6`; the design's inline dot
      // fill `#3D7FF0` is a one-off literal in the K07 SVG. The TOKENS-ONLY
      // rule wins, so the app paints `tokens.sky` — this assertion makes the
      // deviation explicit and keeps it from drifting in either direction.
      const designInlineBlue = 0xFF3D7FF0;
      for (final theme in <ThemeData>[NestTheme.light(), NestTheme.dark()]) {
        expect(
          theme.extension<NestTokens>()!.sky.toARGB32(),
          isNot(designInlineBlue),
        );
        await pumpSparks(tester, theme: theme);
        final bytes = await rasterise(tester);
        for (var i = 0; i < bytes.length; i += 4) {
          final colour =
              (bytes[i + 3] << 24) |
              (bytes[i] << 16) |
              (bytes[i + 1] << 8) |
              bytes[i + 2];
          expect(
            colour,
            isNot(designInlineBlue),
            reason: 'a hard-coded colour reached the render path',
          );
        }
      }
    });
  });

  group('the layer is decorative and static (RULES §6, HTML aria-hidden)', () {
    testWidgets('it is excluded from semantics and ignores pointers', (
      tester,
    ) async {
      await pumpSparks(tester, theme: NestTheme.light());

      final sparks = find.byType(PipEvolutionSparks);
      expect(
        find.descendant(of: sparks, matching: find.byType(ExcludeSemantics)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sparks, matching: find.byType(IgnorePointer)),
        findsOneWidget,
        reason: 'the CSS is pointer-events: none',
      );
      // No motion in the layer itself (RULES §6): the MaterialApp's own theme
      // animation is irrelevant, so the check is scoped to the sparks.
      expect(
        find.descendant(of: sparks, matching: find.byType(AnimatedBuilder)),
        findsNothing,
      );
      expect(
        find.descendant(of: sparks, matching: find.byType(AnimatedOpacity)),
        findsNothing,
      );
      expect(
        find.descendant(
          of: sparks,
          matching: find.byType(ImplicitlyAnimatedWidget),
        ),
        findsNothing,
      );
      // The layer is `const` at the call site, so a theme change is the only
      // thing that can repaint it.
      expect(tester.widget<PipEvolutionSparks>(sparks).key, isNull);
    });
  });

  group('the design block the screen is transcribed from', () {
    test('four sparkles and four circles, in document order', () {
      expect(_paths, hasLength(4));
      expect(_circles, hasLength(4));
      expect(_circles.first.cx, 86);
      expect(_circles.first.cy, 10);
      expect(_circles.first.r, 7);
      expect(_circles.last.cx, 286);
      expect(_circles.last.cy, 210);
      expect(_circles.last.r, 6);
    });

    test('the fills are the five CSS colours the plan maps', () {
      expect(_fills, <int>[
        0x7C6CF2, // #7C6CF2 lilac
        0x1F9D63, // #1F9D63 success
        0xF4B400, // #F4B400 coin
        0xFF8A5B, // #FF8A5B peach
        0xF4B400, // circle, coin
        0x3D7FF0, // circle, a one-off blue (see the test above)
        0x1F9D63, // circle, success
        0x7C6CF2, // circle, lilac
      ]);
    });

    test('the stroke is the design’s ink at 3 px with round joins', () {
      expect(_block, contains('stroke="#1E1B3A" stroke-width="3"'));
      expect(_block, contains('stroke-linejoin="round"'));
      expect(EvolutionSparksGeometry.strokeWidth, 3);
    });

    test('the geometry holder matches the design’s own box and viewBox', () {
      expect(EvolutionSparksGeometry.boxWidth, 350);
      expect(EvolutionSparksGeometry.boxHeight, 250);
      expect(EvolutionSparksGeometry.artSize, const Size(350, 220));
      expect(EvolutionSparksGeometry.topFromScreen, 92);
      // The letterbox: (250 - 220) / 2 = 15 px top and bottom.
      expect(
        (EvolutionSparksGeometry.boxHeight -
                EvolutionSparksGeometry.artSize.height) /
            2,
        15,
      );
    });
  });
}
