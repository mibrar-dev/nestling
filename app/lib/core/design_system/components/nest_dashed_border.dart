import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/radii.dart';

/// Dashed border matching `.k6-item.locked` in
/// `design/html-source/screens/K06-pip.html`.
///
/// `.k6-item.locked { background: surface-2; border-style: dashed;
/// border-color: ink-2; box-shadow: none }` on the shared 3 px ink border
/// (`kid.borderWidth`) and `--r-l` (24) radius. Flutter has no dashed
/// `BorderSide`, so this walks the rounded-rect path with a [CustomPainter]
/// (dash 6 / gap 3, measured off the design PNG: dash 670→675, gap 676→678
/// on a straight edge).
///
/// The stroke paints as `CustomPaint.foregroundPainter` so it lands ON the
/// fill, exactly where CSS puts a dashed `border` (a background painter is
/// hidden under an opaque fill). Honours the card radius: the stroke is
/// inset by half its width, with the corner radius reduced by the same.
class NestDashedBorder extends StatelessWidget {
  const NestDashedBorder({
    required this.child,
    super.key,
    this.color,
    this.strokeWidth,
    this.dashLength = NestDashedBorder.defaultDashLength,
    this.dashGap = NestDashedBorder.defaultDashGap,
    this.borderRadius = NestRadii.l,
  });

  /// Content inside the dashed outline.
  final Widget child;

  /// Dash colour. Defaults to `ink-2` (the locked-tile design).
  final Color? color;

  /// Stroke width. Defaults to `kid.borderWidth` (3).
  final double? strokeWidth;

  /// Dash / gap lengths (logical px). Defaults 6 / 3 (the design PNG).
  static const double defaultDashLength = 6;
  static const double defaultDashGap = 3;

  final double dashLength;
  final double dashGap;

  /// Corner radius. Defaults to `--r-l` (24, the locked-tile design).
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final kid = context.nestKid;
    return CustomPaint(
      foregroundPainter: NestDashedBorderPainter(
        color: color ?? tokens.ink2,
        width: strokeWidth ?? kid.borderWidth,
        dashLength: dashLength,
        dashGap: dashGap,
        borderRadius: borderRadius,
      ),
      child: child,
    );
  }
}

/// The dashed rounded-rect stroke behind [NestDashedBorder], public so
/// callers that already own a `CustomPaint` can reuse it.
class NestDashedBorderPainter extends CustomPainter {
  const NestDashedBorderPainter({
    required this.color,
    required this.width,
    required this.dashLength,
    required this.dashGap,
    this.borderRadius = NestRadii.l,
  });

  final Color color;
  final double width;
  final double dashLength;
  final double dashGap;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final outer = rect.deflate(width / 2);
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          outer,
          Radius.circular(math.max(0, borderRadius - width / 2)),
        ),
      );
    final metrics = path.computeMetrics();
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    for (final metric in metrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dashLength, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant NestDashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.width != width ||
      oldDelegate.dashLength != dashLength ||
      oldDelegate.dashGap != dashGap ||
      oldDelegate.borderRadius != borderRadius;
}
