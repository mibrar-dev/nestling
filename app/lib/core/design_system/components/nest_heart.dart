import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';

/// Pip happiness heart: coin fill + 2px ink-2 stroke when [filled], empty
/// surface-2 with ink-3 stroke otherwise (K03 HTML). Painted from the
/// `ic_heart` 24-space path because the SVG asset bakes fill and stroke into
/// one `currentColor`, which cannot render two tones.
class NestHeart extends StatelessWidget {
  const NestHeart({required this.filled, super.key, this.size = 26});

  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return ExcludeSemantics(
      child: CustomPaint(
        painter: _HeartPainter(
          fill: filled ? tokens.coin : tokens.surface2,
          stroke: filled ? tokens.ink2 : tokens.ink3,
        ),
        size: Size.square(size),
      ),
    );
  }
}

class _HeartPainter extends CustomPainter {
  const _HeartPainter({required this.fill, required this.stroke});

  final Color fill;
  final Color stroke;

  static Path _path(double s) {
    return Path()
      ..moveTo(12 * s, 20.4 * s)
      ..lineTo(4.9 * s, 13.4 * s)
      ..arcToPoint(Offset(11.3 * s, 7 * s), radius: Radius.circular(4.5 * s))
      ..lineTo(12 * s, 7.7 * s)
      ..lineTo(12.7 * s, 7 * s)
      ..arcToPoint(Offset(19.1 * s, 13.4 * s), radius: Radius.circular(4.5 * s))
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final path = _path(s);
    canvas
      ..drawPath(path, Paint()..color = fill)
      ..drawPath(
        path,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * s
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
  }

  @override
  bool shouldRepaint(covariant _HeartPainter oldDelegate) =>
      oldDelegate.fill != fill || oldDelegate.stroke != stroke;
}
