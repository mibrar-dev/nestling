import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/design_system.dart';

/// The K09 money jar (`K09-jar.html:48-67`), transcribed feature-private as a
/// painter instead of an asset: the fill level is live data (the savings-goal
/// fraction), so the illustration has to be drawn, not played back.
///
/// The SVG is 200x236 in a 186x220 box (`.jar`, `K09-jar.html:20`) with the
/// default `preserveAspectRatio`, so it is letter-boxed by 0.26 px: the scale
/// is `min(186/200, 220/236) = 0.93` and the drawing is centred vertically.
/// Every coordinate below is the SVG's own, scaled on the way out.
class JarIllustration extends StatelessWidget {
  const new({
    required this.fillFraction,
    required this.percentLabel,
    super.key,
  });

  /// How full the jar reads, 0..1 — the savings-goal fraction
  /// (`1_plan.md` §(a)). At the demo seed's 62% this is the design's own fill.
  final double fillFraction;

  /// `62` in `A glass money jar about 62% full of coins`
  /// (`K09-jar.html:48`).
  final int percentLabel;

  /// `.jar` box width (`K09-jar.html:20`).
  static const double boxWidth = 186;

  /// `.jar` box height (`K09-jar.html:20`).
  static const double boxHeight = 220;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'A glass money jar about $percentLabel% full of coins',
      child: SizedBox(
        width: boxWidth,
        height: boxHeight,
        child: CustomPaint(
          painter: _JarPainter(
            fillFraction: fillFraction.clamp(0.0, 1.0),
            groundShadow: context.nest.groundShadow,
          ),
        ),
      ),
    );
  }
}

/// The illustration's own palette (`K09-jar.html:48-67`).
///
/// The inline SVG hard-codes every colour, so — exactly like the Pip, coin
/// and badge illustrations — the jar keeps its own colours in both themes: the
/// dark design still shows a pale glass jar and a #1E1B3A outline over the
/// night sky (`design/screens/dark/K09-jar.png`). Only the ground ellipse
/// follows the palette (`--ground-shadow`).
abstract final class _JarPalette {
  const new _();

  /// `#7C6CF2` lid and sparkle — `--lilac` in light.
  static const Color lid = Color(0xFF7C6CF2);

  /// `#F2FAFF` glass — light `--kid-sky-bottom`.
  static const Color glass = Color(0xFFF2FAFF);

  /// `#E09700` the coin mass behind the coins; no token carries it.
  static const Color coinMass = Color(0xFFE09700);

  /// `#F4B400` coins — `--coin` in light.
  static const Color coin = Color(0xFFF4B400);

  /// `#1E1B3A` outline — light `--ink`, fixed in the SVG.
  static const Color ink = Color(0xFF1E1B3A);

  /// `#FFFFFF` gloss streak at 90%.
  static const Color gloss = Color(0xFFFFFFFF);
}

class _JarPainter extends CustomPainter {
  _JarPainter({required this.fillFraction, required this.groundShadow});

  final double fillFraction;

  /// `--ground-shadow` — the one part of the illustration that follows the
  /// palette; the jar itself keeps its own colours in both themes.
  final Color groundShadow;

  /// viewBox 200x236 letter-boxed into [JarIllustration.boxWidth] x
  /// [JarIllustration.boxHeight].
  static const double _scale = 0.93;
  static const double _offsetY = 0.26;

  /// `#jar-in` clip: `rect 36 40 128 168 rx 24` (`K09-jar.html:48`).
  static const Rect _interior = Rect.fromLTRB(36, 40, 164, 208);
  static const double _interiorRadius = 24;

  /// The eight coins (`K09-jar.html:54-62`) as (cx, cy, r).
  static const List<({double cx, double cy, double r})> _coins =
      <({double cx, double cy, double r})>[
        (cx: 66, cy: 128, r: 15),
        (cx: 102, cy: 118, r: 13),
        (cx: 134, cy: 132, r: 15),
        (cx: 82, cy: 154, r: 16),
        (cx: 120, cy: 158, r: 14),
        (cx: 100, cy: 182, r: 15),
        (cx: 58, cy: 178, r: 13),
        (cx: 144, cy: 180, r: 12),
      ];

  Offset _p(double x, double y) => Offset(x * _scale, _offsetY + y * _scale);

  double _s(double value) => value * _scale;

  RRect _rrect(double left, double top, double width, double height, double r) {
    return RRect.fromRectAndRadius(
      Rect.fromLTWH(_p(left, top).dx, _p(left, top).dy, _s(width), _s(height)),
      Radius.circular(_s(r)),
    );
  }

  Paint get _inkStroke => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = _s(4)
    ..color = _JarPalette.ink;

  Paint _coinStroke() => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = _s(3)
    ..color = _JarPalette.ink;

  @override
  void paint(Canvas canvas, Size size) {
    // `ellipse cx 100 cy 226 rx 62 ry 9` (`K09-jar.html:49`) — the jar sits
    // on the ground, so this is painted first.
    canvas.drawOval(
      Rect.fromCenter(center: _p(100, 226), width: _s(124), height: _s(18)),
      Paint()..color = groundShadow,
    );

    // `rect x 50 y 4 width 100 height 22 rx 10` (`:50`) — the lilac lid.
    final lid = _rrect(50, 4, 100, 22, 10);
    canvas
      ..drawRRect(lid, Paint()..color = _JarPalette.lid)
      ..drawRRect(lid, _inkStroke);

    // `rect x 28 y 24 width 144 height 192 rx 30` (`:51`) — the glass body.
    final body = _rrect(28, 24, 144, 192, 30);
    canvas.drawRRect(body, Paint()..color = _JarPalette.glass);

    // The clipped group (`:52-64`): the coin mass fills the bottom of the
    // interior and the coins sit on it. At the design's 62%
    // (`rect x 36 y 104 width 128 height 104`) the fill is 104 of the 168
    // interior units tall, so the level is measured against the interior —
    // `fillFraction * 168`, anchored to the bottom.
    final fillTop = _interior.bottom - fillFraction * _interior.height;
    final interiorClip = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        _s(_interior.left),
        _offsetY + _s(_interior.top),
        _s(_interior.right),
        _offsetY + _s(_interior.bottom),
      ),
      Radius.circular(_s(_interiorRadius)),
    );
    canvas
      ..save()
      ..clipRRect(interiorClip)
      ..drawRect(
        Rect.fromLTRB(
          _s(_interior.left),
          _offsetY + _s(fillTop),
          _s(_interior.right),
          _offsetY + _s(_interior.bottom),
        ),
        Paint()..color = _JarPalette.coinMass,
      )
      // Coins are clipped to the fill as well as to the glass, so a
      // half-empty jar never shows coins floating in the empty air above the
      // level.
      ..clipRect(
        Rect.fromLTRB(
          0,
          _offsetY + _s(fillTop),
          size.width,
          _offsetY + _s(_interior.bottom),
        ),
      );
    final coinFill = Paint()..color = _JarPalette.coin;
    final coinStroke = _coinStroke();
    for (final coin in _coins) {
      canvas
        ..drawCircle(_p(coin.cx, coin.cy), _s(coin.r), coinFill)
        ..drawCircle(_p(coin.cx, coin.cy), _s(coin.r), coinStroke);
    }
    // Clip off, then `rect ... fill="none" stroke` (`:65`) — the body outline
    // again, over the coins — and the white gloss streak (`:66`).
    canvas
      ..restore()
      ..drawRRect(body, _inkStroke)
      ..drawPath(
        Path()
          ..moveTo(_p(50, 56).dx, _p(50, 56).dy)
          ..cubicTo(
            _p(46, 72).dx,
            _p(46, 72).dy,
            _p(46, 88).dx,
            _p(46, 88).dy,
            _p(48, 104).dx,
            _p(48, 104).dy,
          ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _s(7)
          ..strokeCap = StrokeCap.round
          ..color = _JarPalette.gloss.withValues(alpha: 0.9),
      );

    // `path d="M134 44v12M128 50h12"` (`:67`) — the lilac sparkle.
    final sparkle = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _s(4)
      ..strokeCap = StrokeCap.round
      ..color = _JarPalette.lid;
    canvas
      ..drawLine(_p(134, 44), _p(134, 56), sparkle)
      ..drawLine(_p(128, 50), _p(140, 50), sparkle);
  }

  @override
  bool shouldRepaint(covariant _JarPainter oldDelegate) =>
      oldDelegate.fillFraction != fillFraction ||
      oldDelegate.groundShadow != groundShadow;
}
