import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';

/// P04 hero — shield with a leaf/heart on a token-coloured disc.
///
/// Geometry is transcribed 1:1 from `design/html-source/screens/P04-privacy.html`
/// (132-unit viewBox, rendered at [size], default 84): the disc uses
/// `--sky-tint` (light `#E6EFFE`, dark navy `#1A2A4A`), the shield body uses
/// `--surface` and the heart uses `--leaf`, all stroked with `--ink`.
///
/// Prefer this over the baked `privacy_shield.svg` illustration, whose light
/// `#E6EFFE` disc is wrong in dark mode.
class NestPrivacyShield extends StatelessWidget {
  const new({super.key, this.size = 84, this.semanticLabel});

  /// Rendered edge length (the HTML renders 84×84).
  final double size;

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final shield = CustomPaint(
      size: Size.square(size),
      painter: _PrivacyShieldPainter(
        disc: tokens.skyTint,
        shieldBody: tokens.surface,
        heart: tokens.leaf,
        stroke: tokens.ink,
      ),
    );
    final label = semanticLabel;
    if (label == null) {
      return shield;
    }
    return Semantics(image: true, label: label, child: shield);
  }
}

class _PrivacyShieldPainter extends CustomPainter {
  const _PrivacyShieldPainter({
    required this.disc,
    required this.shieldBody,
    required this.heart,
    required this.stroke,
  });

  final Color disc;
  final Color shieldBody;
  final Color heart;
  final Color stroke;

  @visibleForTesting
  static const double viewBox = 132;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / viewBox;

    // Disc: `<circle cx="66" cy="66" r="64" fill="var(--sky-tint)"/>`.
    final discPaint = Paint()..color = disc;

    final strokePaint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    // Shield body: `M66 20 31 33v27c0 22 14.5 39.5 35 48.5
    // 20.5-9 35-26.5 35-48.5V33L66 20z`, fill surface, ink 5px.
    final body = Path()
      ..moveTo(66, 20)
      ..lineTo(31, 33)
      ..lineTo(31, 60)
      ..cubicTo(31, 82, 45.5, 99.5, 66, 108.5)
      ..cubicTo(86.5, 99.5, 101, 82, 101, 60)
      ..lineTo(101, 33)
      ..lineTo(66, 20)
      ..close();
    final bodyPaint = Paint()..color = shieldBody;

    // Heart/leaf: `M66 84c-19-12.5-25-22.5-21.5-31.5 2.8-7.2 13-8 18.5-1.5
    // 5.5-6.5 15.7-5.7 18.5 1.5C85 61.5 79 71.5 66 84z`,
    // fill leaf, ink 4px.
    final leaf = Path()
      ..moveTo(66, 84)
      ..cubicTo(47, 71.5, 41, 61.5, 44.5, 52.5)
      ..cubicTo(47.3, 45.3, 57.5, 44.5, 63, 51)
      ..cubicTo(68.5, 44.5, 78.7, 45.3, 81.5, 52.5)
      ..cubicTo(85, 61.5, 79, 71.5, 66, 84)
      ..close();
    final leafPaint = Paint()..color = heart;

    canvas
      ..save()
      ..scale(scale)
      ..drawCircle(const Offset(66, 66), 64, discPaint)
      ..drawPath(body, bodyPaint)
      ..drawPath(body, strokePaint..strokeWidth = 5)
      ..drawPath(leaf, leafPaint)
      ..drawPath(leaf, strokePaint..strokeWidth = 4)
      ..restore();
  }

  @override
  bool shouldRepaint(covariant _PrivacyShieldPainter oldDelegate) {
    return oldDelegate.disc != disc ||
        oldDelegate.shieldBody != shieldBody ||
        oldDelegate.heart != heart ||
        oldDelegate.stroke != stroke;
  }
}
