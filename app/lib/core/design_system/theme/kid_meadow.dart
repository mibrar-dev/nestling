import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';

/// Shared kid-mode background geometry and painters.
///
/// Exact transcription of the design's `.screen.kid` + `.meadow` contract
/// (`design/html-source/components.css:25`,
/// `design/html-source/screens/K01-profile-picker.html:8-11,37` — identical
/// on every kid screen K01–K11):
///
/// * `.screen.kid` paints `var(--kid-stars)` over
///   `linear-gradient(180deg, kid-sky-top 0%, kid-sky-bottom 62%,
///   kid-horizon 62%, kid-meadow 100%)`.
/// * `.meadow` is pinned to the physical screen bottom (`left:0; bottom:0`),
///   full width, 136 tall, `viewBox="0 0 390 136"` with
///   `preserveAspectRatio="none"` (stretched to the box, no aspect lock),
///   behind content (`z-index:0`, `pointer-events:none`), with two paths:
///   `.hill-back` filled `kid-meadow` and `.hill-front` filled
///   `color-mix(in srgb, kid-meadow 80%, surface)`.
abstract final class NestMeadowGeometry {
  const new _();

  /// `.meadow` viewBox width (`preserveAspectRatio="none"` stretches to fit).
  static const double viewBoxWidth = 390;

  /// `.meadow` viewBox height — also the shared hill height.
  static const double viewBoxHeight = 136;

  /// The shared bottom-hill height.
  static const double defaultHeight = 136;

  /// `.screen.kid` horizon stop: sky grades 0–62 %, then a hard stop to
  /// `kid-horizon` at 62 % and grades to `kid-meadow` at 100 %.
  static const double horizonStop = 0.62;
}

/// Bakes `.hill-front`'s `color-mix(in srgb, kid-meadow 80%, surface)` in
/// Dart: 80 % [meadow] + 20 % [surface], channel-wise in sRGB — exactly what
/// the CSS does to two opaque sRGB colours.
///
/// Light: `#BFE8B0` over white → `#CCEDC0` (204, 237, 192), the design PNG's
/// bottom row. Dark: `#1E4A3A` over `#1F1C2E` → `#1E4138` (30, 65, 56).
Color kidHillFront(Color meadow, Color surface) =>
    Color.lerp(surface, meadow, 0.8)!;

/// The exact `.meadow` `d` paths from the HTML (`K01-profile-picker.html:37`).
/// Built at paint time so `preserveAspectRatio="none"` scaling is exact:
/// x stretches by `width / 390`, y by `height / 136`.
class NestMeadowPainter extends CustomPainter {
  const new({required this.back, required this.front});

  /// `.hill-back` fill: `kid-meadow` (or the caller's tone).
  final Color back;

  /// `.hill-front` fill: [kidHillFront] of [back] over the surface.
  final Color front;

  /// `.hill-back`: `M0 56C58 28 122 32 186 22 252 12 314 28 390 10v126H0Z`.
  static Path hillBack(Size size) {
    final sx = size.width / NestMeadowGeometry.viewBoxWidth;
    final sy = size.height / NestMeadowGeometry.viewBoxHeight;
    return Path()
      ..moveTo(0, 56 * sy)
      ..cubicTo(58 * sx, 28 * sy, 122 * sx, 32 * sy, 186 * sx, 22 * sy)
      ..cubicTo(252 * sx, 12 * sy, 314 * sx, 28 * sy, 390 * sx, 10 * sy)
      ..lineTo(390 * sx, 136 * sy)
      ..lineTo(0, 136 * sy)
      ..close();
  }

  /// `.hill-front`: `M0 92c74-22 138-10 214-22 60-10 112 4 176-14v80H0Z`
  /// (relative cubics resolved to absolute here).
  static Path hillFront(Size size) {
    final sx = size.width / NestMeadowGeometry.viewBoxWidth;
    final sy = size.height / NestMeadowGeometry.viewBoxHeight;
    return Path()
      ..moveTo(0, 92 * sy)
      ..cubicTo(74 * sx, 70 * sy, 138 * sx, 82 * sy, 214 * sx, 70 * sy)
      ..cubicTo(274 * sx, 60 * sy, 326 * sx, 74 * sy, 390 * sx, 56 * sy)
      ..lineTo(390 * sx, 136 * sy)
      ..lineTo(0, 136 * sy)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..drawPath(hillBack(size), Paint()..color = back)
      ..drawPath(hillFront(size), Paint()..color = front);
  }

  @override
  bool shouldRepaint(covariant NestMeadowPainter oldDelegate) =>
      oldDelegate.back != back || oldDelegate.front != front;
}

/// The shared hills block: full width, 136 tall, the two exact `.meadow`
/// paths. Never intercepts taps (`IgnorePointer`, like the CSS
/// `pointer-events:none`). Screens do not need this directly — KidScope
/// already pins it behind their content — it exists for previews and tests.
class NestMeadow extends StatelessWidget {
  const new({
    super.key,
    this.height = NestMeadowGeometry.defaultHeight,
    this.back,
    this.front,
  });

  /// Hill height. Defaults to the shared 136 px.
  final double height;

  /// `.hill-back` fill. Defaults to `kidMeadow`.
  final Color? back;

  /// `.hill-front` fill. Defaults to [kidHillFront] of the back over surface.
  final Color? front;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<NestTokens>()!.colors;
    final resolvedBack = back ?? colors.kidMeadow;
    final resolvedFront = front ?? kidHillFront(resolvedBack, colors.surface);
    return IgnorePointer(
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: CustomPaint(
          painter: NestMeadowPainter(back: resolvedBack, front: resolvedFront),
        ),
      ),
    );
  }
}

/// Dark-only `--kid-stars` layer (`tokens.css:134`): eight pinprick stars
/// over the sky. Light sets `--kid-stars: none`, so this painter is only
/// mounted in dark mode. Positions are the CSS px in the 390×844 frame,
/// stretched with the box like the rest of the background.
class NestKidStarsPainter extends CustomPainter {
  const new();

  /// (x, y, radius, alpha) from the `--kid-stars` radial-gradients.
  static const List<(double, double, double, double)> stars =
      <(double, double, double, double)>[
        (36, 70, 1.5, 0.9),
        (110, 40, 1, 0.7),
        (190, 110, 1.5, 0.9),
        (260, 60, 1, 0.7),
        (320, 150, 2, 0.85),
        (70, 200, 1, 0.6),
        (230, 240, 1.5, 0.8),
        (350, 300, 1, 0.6),
      ];

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / NestMeadowGeometry.viewBoxWidth;
    final sy = size.height / 844;
    final rScale = (sx + sy) / 2;
    for (final (x, y, r, a) in stars) {
      canvas.drawCircle(
        Offset(x * sx, y * sy),
        r * rScale,
        Paint()..color = Colors.white.withValues(alpha: a),
      );
    }
  }

  @override
  bool shouldRepaint(covariant NestKidStarsPainter oldDelegate) => false;
}
