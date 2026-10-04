// K07-BUG-SPARK-1 — the `svg.sparks` sparkles lose the design's `M` vertex.
//
// FOUND BY STAGE 3 (the test stage), 2026-10-04, and the same defect stage 5
// reported as its D2 MAJOR ("sparks use the wrong path … the app draws an
// asymmetric rounded blob with a flat wide top and a single downward point").
//
// Defect: `app/lib/features/pip/presentation/widgets/pip_evolution_sparks.dart:168`
// (`_SparksPainter._sparkPath`) builds each sparkle as
//
//     Path()..moveTo(n[0], n[1])..addPolygon(<the REMAINING pairs>, true)
//
// but `Path.addPolygon` starts its OWN contour: `_addLeadingPoint` overwrites
// the pending `moveTo` instead of continuing from it. So the design's first
// vertex — the sparkle's top point — is silently dropped and the polygon is
// built from seven vertices with a flat top edge instead of eight with a
// point. Measured on the app's own painted pixels, all four sparkles:
//
//   design `d`            bbox  (13, 30) - (51, 68)
//   app paints            bbox  (13, 44) - (51, 68)   <- top 14 px missing
//
// Suggested fix (screen-local, RULES §1-legal): drop the separate `moveTo`
// and let `addPolygon` take the `M` pair as its first point, i.e.
//
//     Path()..addPolygon(<Offset>[
//       for (var i = 0; i + 1 < numbers.length; i += 2)
//         Offset(numbers[i], numbers[i + 1]),
//     ], true);
//
// Repo convention (`k06_bugs_test.dart` header): a bug proof is skipped with
// `skip: true` and carries its id in the test DESCRIPTION, so
//
//   flutter test --timeout 120s \
//     test/features/pip/pip_evolution_sparks_bug_test.dart --run-skipped
//
// runs it and FAILS until the bug is fixed. Drop `skip: true` in that commit.
// Evidence and repro live in `docs/screens/K07/3_test.md`.
// This stage does not change product code.

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart' hide PipStage;
import 'package:nestling/features/pip/presentation/widgets/pip_evolution_sparks.dart';

/// The design's first sparkle, `K07-evolution.html:37`, in its own vertices.
/// Eight, and the first one is the top point.
const List<Offset> _designVertices = <Offset>[
  Offset(32, 30),
  Offset(37, 44),
  Offset(51, 49),
  Offset(37, 54),
  Offset(32, 68),
  Offset(27, 54),
  Offset(13, 49),
  Offset(27, 44),
];

/// The design's `d` subset: one absolute `M` then implicit absolute line-to
/// pairs, closed with `Z` — the only commands the HTML uses.
Path _pathFromDesignD(String d, {required bool keepMoveToVertex}) {
  final numbers = RegExp(r'-?\d+(\.\d+)?')
      .allMatches(d.replaceAll(RegExp('[MZ]'), ' '))
      .map((m) => double.parse(m.group(0)!))
      .toList(growable: false);
  if (keepMoveToVertex) {
    return Path()
      ..moveTo(numbers[0], numbers[1])
      ..addPolygon(<Offset>[
        for (var i = 2; i + 1 < numbers.length; i += 2)
          Offset(numbers[i], numbers[i + 1]),
      ], true);
  }
  return Path()..addPolygon(<Offset>[
    for (var i = 0; i + 1 < numbers.length; i += 2)
      Offset(numbers[i], numbers[i + 1]),
  ], true);
}

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

void main() {
  setUpAll(() {
    _block = _sparksBlock();
  });

  group('K07-BUG-SPARK-1', () {
    test('K07-BUG-SPARK-1: Path.addPolygon overwrites the preceding moveTo, so the '
        "design's M vertex is lost", () {
      // The mechanism, isolated from the screen: the same `d` built the two
      // ways must not have the same bounds.
      final d = _paths.first;
      final withMoveTo = _pathFromDesignD(d, keepMoveToVertex: true);
      final withoutMoveTo = _pathFromDesignD(d, keepMoveToVertex: false);

      // The design itself: eight vertices, the first one the top point, and the
      // bounding box they span.
      expect(_designVertices, hasLength(8));
      expect(_designVertices.first, const Offset(32, 30));
      expect(
        Rect.fromPoints(
          _designVertices[6],
          _designVertices.first,
        ).expandToInclude(
          Rect.fromPoints(_designVertices[2], _designVertices[4]),
        ),
        const Rect.fromLTRB(13, 30, 51, 68),
      );

      expect(
        withMoveTo.getBounds().top,
        44,
        reason: 'the buggy recipe starts the polygon at the SECOND vertex',
      );
      expect(
        withoutMoveTo.getBounds().top,
        30,
        reason: "the design's top point is (32, 30)",
      );
      expect(
        withoutMoveTo.getBounds(),
        const Rect.fromLTRB(13, 30, 51, 68),
        reason: 'the design path spans 13..51 x 30..68',
      );
    }, skip: true);

    testWidgets(
      'K07-BUG-SPARK-1: the painted sparkle is the design’s polygon, tip included',
      (tester) async {
        // What the screen draws today, read back from its own painter.
        await tester.pumpWidget(
          MaterialApp(
            theme: NestTheme.light(),
            home: Center(
              child: SizedBox.fromSize(
                size: EvolutionSparksGeometry.artSize,
                child: const PipEvolutionSparks(),
              ),
            ),
          ),
        );
        await tester.pump();
        final painter = tester
            .widget<CustomPaint>(
              find.descendant(
                of: find.byType(PipEvolutionSparks),
                matching: find.byType(CustomPaint),
              ),
            )
            .painter!;

        Future<Uint8List> raster(void Function(Canvas) draw) async {
          final recorder = ui.PictureRecorder();
          draw(Canvas(recorder));
          final bytes = await tester.runAsync(() async {
            final image = await recorder.endRecording().toImage(
              EvolutionSparksGeometry.artSize.width.toInt(),
              EvolutionSparksGeometry.artSize.height.toInt(),
            );
            final data = await image.toByteData();
            return data!.buffer.asUint8List();
          });
          return bytes!;
        }

        /// The first sparkle's own neighbourhood, so the second sparkle (x 293+)
        /// cannot widen a row.
        const scanRight = 80;
        int inkedRows(Uint8List bytes, {required int from, required int to}) {
          var rows = 0;
          for (var y = from; y <= to; y++) {
            for (var x = 0; x < scanRight; x++) {
              if (bytes[((y * 350) + x) * 4 + 3] > 128) {
                rows++;
                break;
              }
            }
          }
          return rows;
        }

        final app = await raster(
          (canvas) => painter.paint(canvas, EvolutionSparksGeometry.artSize),
        );

        // The design's own tip region: y 28..33 around x 32. The 3 px stroke
        // rounds it, so the whole 6-row band must be inked.
        expect(
          inkedRows(app, from: 28, to: 33),
          6,
          reason: "the design's top tip is (32, 30) and must be painted",
        );
        expect(
          app[((30 * 350) + 32) * 4 + 3],
          greaterThan(200),
          reason: 'solid ink exactly on the design’s top vertex',
        );

        // And the whole silhouette must equal the design’s polygon.
        void paintReference(Canvas canvas) {
          canvas
            ..save()
            ..clipRect(Offset.zero & EvolutionSparksGeometry.artSize);
          final fill = Paint()
            ..color = const Color(0xFF123456)
            ..style = PaintingStyle.fill;
          final stroke = Paint()
            ..color = const Color(0xFF123456)
            ..style = PaintingStyle.stroke
            ..strokeWidth = EvolutionSparksGeometry.strokeWidth
            ..strokeJoin = StrokeJoin.round;
          for (final d in _paths) {
            final path = _pathFromDesignD(d, keepMoveToVertex: false);
            canvas
              ..drawPath(path, fill)
              ..drawPath(path, stroke);
          }
          canvas.restore();
        }

        final reference = await raster(paintReference);
        var inked = 0;
        var differing = 0;
        for (var i = 3; i < app.length; i += 4) {
          if (app[i] > 8 || reference[i] > 8) inked++;
          if ((app[i] - reference[i]).abs() > 64) differing++;
        }
        expect(
          differing,
          0,
          reason:
              'the app paints a different silhouette from the design '
              '($inked inked px)',
        );
      },
      skip: true,
    );

    testWidgets('K07-BUG-SPARK-1: the silhouette is symmetric about the design’s x = 32 axis '
        'with a tip at each end', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: NestTheme.light(),
          home: Center(
            child: SizedBox.fromSize(
              size: EvolutionSparksGeometry.artSize,
              child: const PipEvolutionSparks(),
            ),
          ),
        ),
      );
      await tester.pump();
      // The first sparkle's own neighbourhood, so the second sparkle
      // (x 293+) cannot widen a row.
      const scanRight = 80;
      final painter = tester
          .widget<CustomPaint>(
            find.descendant(
              of: find.byType(PipEvolutionSparks),
              matching: find.byType(CustomPaint),
            ),
          )
          .painter!;
      final recorder = ui.PictureRecorder();
      painter.paint(Canvas(recorder), EvolutionSparksGeometry.artSize);
      final bytes = await tester.runAsync(() async {
        final image = await recorder.endRecording().toImage(
          EvolutionSparksGeometry.artSize.width.toInt(),
          EvolutionSparksGeometry.artSize.height.toInt(),
        );
        final data = await image.toByteData();
        return data!.buffer.asUint8List();
      });
      final data = bytes!;
      final stride = EvolutionSparksGeometry.artSize.width.toInt();
      int at(int x, int y) => data[((y * stride) + x) * 4 + 3];

      ({int first, int last}) spanAt(int y) {
        var first = -1;
        var last = -1;
        for (var x = 0; x < scanRight; x++) {
          if (at(x, y) > 128) {
            if (first < 0) first = x;
            last = x;
          }
        }
        return (first: first, last: last);
      }

      /// Rows in `[from, to]` that carry any ink.
      int inkedRows(int from, int to) {
        var rows = 0;
        for (var y = from; y <= to; y++) {
          if (spanAt(y).first >= 0) rows++;
        }
        return rows;
      }

      // The design's TOP ARM runs from the tip (32, 30) down to (37, 44):
      // thirteen rows of a narrow, tapering spike. With the `M` vertex lost
      // this band is empty and the silhouette starts flat at y = 44 — which
      // is precisely stage 5's "flat wide top".
      expect(
        inkedRows(29, 41),
        greaterThanOrEqualTo(10),
        reason: "the design's top arm, tip (32, 30) to (37, 44), is missing",
      );
      // …and it TAPERS to a point, so it is narrow at the top.
      expect(
        spanAt(31).last - spanAt(31).first,
        lessThan(10),
        reason: 'the arm must taper towards its tip',
      );
      // The bottom arm survives the bug, so this half already holds; it is
      // kept so the proof fails on the top arm only, never on the stroke.
      expect(inkedRows(60, 69), greaterThanOrEqualTo(8));

      // The widest band belongs to the design's y = 49 axis, where the
      // silhouette is 13..51 wide.
      final widest = <int>[for (var y = 24; y <= 74; y++) y]
          .map((y) {
            final span = spanAt(y);
            return (
              y: y,
              width: span.first < 0 ? 0 : span.last - span.first + 1,
            );
          })
          .reduce((a, b) => a.width >= b.width ? a : b);
      expect(widest.width, greaterThan(30));
      expect(widest.y, inInclusiveRange(46, 50));
      expect(spanAt(widest.y).first, inInclusiveRange(10, 15));
      expect(spanAt(widest.y).last, inInclusiveRange(48, 53));

      // Every inked row is centred on the design's x = 32 axis: a 4-point
      // star, not a flat-topped blob with one downward point.
      for (var y = 28; y <= 72; y++) {
        final span = spanAt(y);
        if (span.first < 0) continue;
        expect(
          (span.first + span.last) / 2,
          closeTo(32, 1),
          reason: 'row $y is off the design’s axis',
        );
      }
    }, skip: true);
  });
}
