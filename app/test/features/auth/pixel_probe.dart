// Painted-pixel probe shared by P03's rendering proofs.
//
// `flutter test` lays out and paints for real, so a proof about what the
// user actually sees can read the raster instead of inferring it from
// widget properties. Two things make that reliable:
//
//  * the raster thread must have caught up — `toImage()` snapshots the
//    layer tree as it is, and a frame that has only been *pumped* may
//    still hold the previous frame's paint. Sampling too early showed a
//    clean 1 px `line` border on a field whose `InputDecoration` already
//    said `danger`, which reads as a live bug and is not one;
//  * `toImage()` needs real async, so every read is wrapped in
//    `tester.runAsync`.
//
// Neither belongs in a widget test that could assert the same thing from
// the tree — this is for the rules the tree cannot express (what colour a
// pixel ends up, e.g. the owner's bottom-edge rule and the danger border).

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// [colour] as the `rrggbb` hex [column] reports, alpha dropped.
String hexOf(Color colour) =>
    colour.toARGB32().toRadixString(16).padLeft(8, '0').substring(2);

/// The colour part of one `row:rrggbb` entry from [column].
String hexOfRow(String row) => row.split(':').last;

/// Lets the raster thread finish, so a later [column] sees the newest
/// paint: settle the animation clock, then give the raster thread three
/// real-time turns with a pump between each.
Future<void> settleRaster(WidgetTester tester) async {
  await tester.pumpAndSettle();
  for (var turn = 0; turn < 3; turn++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }
}

/// The painted colours in the column at [x] (logical px), one entry per row
/// from [y0] to [y1] inclusive, as `rrggbb` hex without the alpha.
///
/// Rows outside the boundary are skipped, so a caller can over-scan.
Future<List<String>> column(
  WidgetTester tester,
  double x,
  double y0,
  double y1,
) async {
  final finder = find.byType(RepaintBoundary).first;
  final boundary = tester.renderObject<RenderRepaintBoundary>(finder);
  // The app's outermost boundary covers the whole view, so its local space
  // is screen space and the caller's logical coordinates line up. A future
  // nesting change would shift every reading silently, so it is checked.
  expect(
    boundary.localToGlobal(Offset.zero),
    Offset.zero,
    reason:
        'the outermost repaint boundary must sit at the view origin for '
        'painted coordinates to be screen coordinates',
  );
  final image = await boundary.toImage();
  // The default format (rawStraightRgba) is what we want: unpremultiplied
  // bytes, so a token colour reads back as itself.
  final data = await image.toByteData();
  final px = x.round().clamp(0, image.width - 1);
  final out = <String>[];
  for (var y = y0.round(); y <= y1.round(); y++) {
    if (y < 0 || y >= image.height) continue;
    final i = (y * image.width + px) * 4;
    out.add(
      '${y.toStringAsFixed(0)}:'
      '${data!.getUint8(i).toRadixString(16).padLeft(2, '0')}'
      '${data.getUint8(i + 1).toRadixString(16).padLeft(2, '0')}'
      '${data.getUint8(i + 2).toRadixString(16).padLeft(2, '0')}',
    );
  }
  image.dispose();
  return out;
}

/// [column] with the raster settled first.
Future<List<String>> paintedColumn(
  WidgetTester tester,
  double x,
  double y0,
  double y1,
) async {
  await settleRaster(tester);
  return (await tester.runAsync(() => column(tester, x, y0, y1)))!;
}

/// The hex of the single pixel at [at].
Future<String> pixel(WidgetTester tester, Offset at) async {
  final rows = await paintedColumn(tester, at.dx, at.dy, at.dy);
  return rows.single.split(':').last;
}
