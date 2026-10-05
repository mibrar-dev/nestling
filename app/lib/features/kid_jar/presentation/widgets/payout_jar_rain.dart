import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/design_system.dart';

/// The K10 payout-day jar with coins raining in (`K10-payout-day.html:40-74`
/// `<svg class="rain">`), transcribed feature-private as a painter — the
/// same fixed-illustration rule as `JarIllustration`: the illustration keeps
/// its own palette in both themes and only the ground ellipse follows the
/// tokens (`--ground-shadow`).
///
/// viewBox 200×300 letter-boxed into the `.rain { width: 180px; height:
/// 270px }` box (`K10:19`): the scale is `min(180/200, 270/300) = 0.9` and
/// both offsets come out 0, so every drawing coordinate is just `× 0.9`.
class PayoutJarRain extends StatelessWidget {
  const new({super.key});

  /// `.rain` box width (`K10:19`).
  static const double boxWidth = 180;

  /// `.rain` box height (`K10:19`).
  static const double boxHeight = 270;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'A jar of coins with coins raining down into it',
      child: SizedBox(
        width: boxWidth,
        height: boxHeight,
        child: CustomPaint(
          painter: _RainPainter(groundShadow: context.nest.groundShadow),
        ),
      ),
    );
  }
}

/// The illustration's own palette (`K10:41-74`) — fixed ink outlines and all.
abstract final class _RainPalette {
  const new _();

  /// `#F4B400` coins — `--coin` in light.
  static const Color coin = Color(0xFFF4B400);

  /// `#E09700` the coin mass behind the coins.
  static const Color coinMass = Color(0xFFE09700);

  /// `#7C6CF2` lid and the small sparkle cross.
  static const Color lilac = Color(0xFF7C6CF2);

  /// `#F2FAFF` glass.
  static const Color glass = Color(0xFFF2FAFF);

  /// `#1F9D63` leaf sparkle.
  static const Color leaf = Color(0xFF1F9D63);

  /// `#1E1B3A` outlines.
  static const Color ink = Color(0xFF1E1B3A);

  /// `#FFFFFF` gloss streak at 90%.
  static const Color gloss = Color(0xFFFFFFFF);
}

class _RainPainter extends CustomPainter {
  _RainPainter({required this.groundShadow});

  /// `--ground-shadow` — the one part that follows the palette.
  final Color groundShadow;

  static const double _scale = 0.9;

  /// The seven raining coins (`K10:42-48`) as (cx, cy, r).
  static const List<({double cx, double cy, double r})> _rain =
      <({double cx, double cy, double r})>[
        (cx: 42, cy: 16, r: 14),
        (cx: 100, cy: 8, r: 12),
        (cx: 158, cy: 20, r: 15),
        (cx: 72, cy: 46, r: 11),
        (cx: 132, cy: 44, r: 12),
        (cx: 20, cy: 52, r: 9),
        (cx: 182, cy: 56, r: 9),
      ];

  /// The eight coins in the jar (`K10:61-68`) — drawn with the group's
  /// `translate(0,64)` applied (their cy values below already carry it).
  static const List<({double cx, double cy, double r})> _coins =
      <({double cx, double cy, double r})>[
        (cx: 66, cy: 114 + 64, r: 15),
        (cx: 102, cy: 104 + 64, r: 13),
        (cx: 134, cy: 118 + 64, r: 15),
        (cx: 82, cy: 140 + 64, r: 16),
        (cx: 120, cy: 144 + 64, r: 14),
        (cx: 100, cy: 168 + 64, r: 15),
        (cx: 58, cy: 164 + 64, r: 13),
        (cx: 144, cy: 166 + 64, r: 12),
      ];

  Offset _p(double x, double y) => Offset(x * _scale, y * _scale);

  double _s(double value) => value * _scale;

  RRect _rrect(double x, double y, double w, double h, double r) {
    return RRect.fromRectAndRadius(
      Rect.fromLTWH(_p(x, y).dx, _p(x, y).dy, _s(w), _s(h)),
      Radius.circular(_s(r)),
    );
  }

  Paint get _ink3 => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = _s(3)
    ..color = _RainPalette.ink;

  @override
  void paint(Canvas canvas, Size size) {
    // The HTML svg root clips to the viewBox; the sparkle paths intentionally
    // bleed past x=200, so clip the canvas to the box as well.
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Seven raining coins (`K10:41-49`).
    final coinFill = Paint()..color = _RainPalette.coin;
    for (final coin in _rain) {
      canvas
        ..drawCircle(_p(coin.cx, coin.cy), _s(coin.r), coinFill)
        ..drawCircle(_p(coin.cx, coin.cy), _s(coin.r), _ink3);
    }

    // Two four-point sparkles (`K10:50-53`).
    for (final (path, fill) in <(Path, Color)>[
      (
        Path()
          ..moveTo(_p(11, 96).dx, _p(11, 96).dy)
          ..lineTo(_p(16, 110).dx, _p(16, 110).dy)
          ..lineTo(_p(30, 115).dx, _p(30, 115).dy)
          ..lineTo(_p(16, 120).dx, _p(16, 120).dy)
          ..lineTo(_p(11, 134).dx, _p(11, 134).dy)
          ..lineTo(_p(6, 120).dx, _p(6, 120).dy)
          ..lineTo(_p(-8, 115).dx, _p(-8, 115).dy)
          ..lineTo(_p(6, 110).dx, _p(6, 110).dy)
          ..close(),
        _RainPalette.leaf,
      ),
      (
        Path()
          ..moveTo(_p(189, 92).dx, _p(189, 92).dy)
          ..lineTo(_p(194, 106).dx, _p(194, 106).dy)
          ..lineTo(_p(208, 111).dx, _p(208, 111).dy)
          ..lineTo(_p(194, 116).dx, _p(194, 116).dy)
          ..lineTo(_p(189, 130).dx, _p(189, 130).dy)
          ..lineTo(_p(184, 116).dx, _p(184, 116).dy)
          ..lineTo(_p(170, 111).dx, _p(170, 111).dy)
          ..lineTo(_p(184, 106).dx, _p(184, 106).dy)
          ..close(),
        _RainPalette.lilac,
      ),
    ]) {
      canvas
        ..drawPath(path, Paint()..color = fill)
        ..drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = _s(3)
            ..strokeJoin = StrokeJoin.round
            ..color = _RainPalette.ink,
        );
    }

    // Ground ellipse (`K10:55`) — sits under the jar.
    canvas.drawOval(
      Rect.fromCenter(
        center: _p(100, 226 + 64),
        width: _s(124),
        height: _s(18),
      ),
      Paint()..color = groundShadow,
    );

    // Lilac lid (`K10:56`).
    final lid = _rrect(50, 4 + 64, 100, 22, 10);
    canvas
      ..drawRRect(lid, Paint()..color = _RainPalette.lilac)
      ..drawRRect(
        lid,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _s(4)
          ..color = _RainPalette.ink,
      );

    // Glass body (`K10:57`).
    final body = _rrect(28, 24 + 64, 144, 192, 30);
    canvas.drawRRect(body, Paint()..color = _RainPalette.glass);

    // Coin mass behind the coins, clipped to the interior (`K10:58-70`).
    final interior = _rrect(36, 40 + 64, 128, 168, 24);
    canvas
      ..save()
      ..clipRRect(interior)
      ..drawRect(
        Rect.fromLTRB(
          _p(36, 90 + 64).dx,
          _p(36, 90 + 64).dy,
          _p(164, 90 + 64).dx,
          _p(164, 208 + 64).dy,
        ),
        Paint()..color = _RainPalette.coinMass,
      );
    for (final coin in _coins) {
      canvas
        ..drawCircle(_p(coin.cx, coin.cy), _s(coin.r), coinFill)
        ..drawCircle(_p(coin.cx, coin.cy), _s(coin.r), _ink3);
    }

    // Body outline over the coins (`K10:71`) and the white gloss (`K10:72`);
    // the balance of the `save()` above is `restore()` inside this cascade.
    canvas
      ..restore()
      ..drawRRect(
        body,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _s(4)
          ..color = _RainPalette.ink,
      )
      ..drawPath(
        Path()
          ..moveTo(_p(50, 56 + 64).dx, _p(50, 56 + 64).dy)
          ..cubicTo(
            _p(46, 72 + 64).dx,
            _p(46, 72 + 64).dy,
            _p(46, 88 + 64).dx,
            _p(46, 88 + 64).dy,
            _p(48, 104 + 64).dx,
            _p(48, 104 + 64).dy,
          ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _s(7)
          ..strokeCap = StrokeCap.round
          ..color = _RainPalette.gloss.withValues(alpha: 0.9),
      );

    // Small lilac plus sparkle (`K10:73`).
    final spark = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _s(4)
      ..strokeCap = StrokeCap.round
      ..color = _RainPalette.lilac;
    canvas
      ..drawLine(_p(134, 44 + 64), _p(134, 56 + 64), spark)
      ..drawLine(_p(128, 50 + 64), _p(140, 50 + 64), spark);
  }

  @override
  bool shouldRepaint(covariant _RainPainter oldDelegate) =>
      oldDelegate.groundShadow != groundShadow;
}
