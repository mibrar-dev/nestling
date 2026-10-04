// K07's confetti sparks — the design's `svg.sparks` (HTML lines 35-46),
// transcribed path for path.
//
//   <svg class="sparks" viewBox="0 0 350 220" aria-hidden="true">
//     <g stroke="#1E1B3A" stroke-width="3" stroke-linejoin="round">
//       four 4-point sparkle paths + four circles, with their CSS fills
//
// `.sparks` is `position: absolute; left: 50%; top: 92px;
// transform: translateX(-50%); width: 350px; height: 250px;
// pointer-events: none`, and the inline `viewBox` is 350x220 — so the SVG
// letterboxes 15 px at the top and bottom inside the 250 px box (exactly what
// `Center` around a 350x220 paint reproduces).
//
// Static art: screenshots run with `DISABLE_ANIMATIONS=1` and RULES §6 forbids
// a Timer/AnimationController here, so nothing loops.
import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/design_system.dart';

/// `svg.sparks` geometry and the `<g>`'s stroke, in the design's CSS px.
abstract final class EvolutionSparksGeometry {
  const new _();

  /// `.sparks { width: 350px; height: 250px }`.
  static const double boxWidth = 350;
  static const double boxHeight = 250;

  /// The inline `viewBox` is 350x220 inside that 250-tall box, so the art
  /// letterboxes `(250 - 220) / 2 = 15` px top and bottom.
  static const Size artSize = Size(350, 220);

  /// `.sparks { top: 92px }` from the screen top.
  static const double topFromScreen = 92;

  /// `<g stroke-width="3">`.
  static const double strokeWidth = 3;
}

/// Which token paints a spark — the design's literal fills, mapped:
/// `#7C6CF2` lilac, `#1F9D63` success, `#F4B400` coin, `#FF8A5B` peach,
/// `#3D7FF0` sky.
enum _SparkFill { lilac, success, coin, peach, sky }

/// One entry of the design's `<g>`: a 4-point sparkle `d`, or a dot.
@immutable
class _Spark {
  const _Spark.sparkle(this.d, this.fill) : center = null, radius = null;

  const _Spark.dot(this.center, this.radius, this.fill) : d = null;

  /// The SVG `d` attribute, verbatim (implicit lineto commands).
  final String? d;

  /// `(cx, cy)` and `r` of a `<circle>`.
  final Offset? center;
  final double? radius;

  final _SparkFill fill;

  /// The closed polygon for [d], parsed once per `d` and kept.
  ///
  /// The layer is static art that repaints only on a theme change, so
  /// re-parsing the path data on every paint would be pure allocation on the
  /// render path (`4_review.md` finding 11).
  Path? get path {
    final d = this.d;
    if (d == null) return null;
    return _sparkPaths.putIfAbsent(d, () => _sparkPath(d));
  }

  /// The parsed paths, keyed by their `d`.
  static final Map<String, Path> _sparkPaths = <String, Path>{};

  /// The CSS fill this entry uses, resolved from the theme's tokens.
  Color colorOf(NestTokens tokens) => switch (fill) {
    _SparkFill.lilac => tokens.lilac,
    _SparkFill.success => tokens.success,
    _SparkFill.coin => tokens.coin,
    _SparkFill.peach => tokens.peach,
    _SparkFill.sky => tokens.sky,
  };
}

/// The design's four sparkles and four dots, in document order.
const List<_Spark> _sparks = <_Spark>[
  // <path d="M32 30 37 44 51 49 37 54 32 68 27 54 13 49 27 44Z" fill="#7C6CF2"/>
  _Spark.sparkle(
    'M32 30 37 44 51 49 37 54 32 68 27 54 13 49 27 44Z',
    _SparkFill.lilac,
  ),
  // <path d="M312 24 317 38 331 43 317 48 312 62 307 48 293 43 307 38Z" fill="#1F9D63"/>
  _Spark.sparkle(
    'M312 24 317 38 331 43 317 48 312 62 307 48 293 43 307 38Z',
    _SparkFill.success,
  ),
  // <path d="M18 148 23 162 37 167 23 172 18 186 13 172 -1 167 13 162Z" fill="#F4B400"/>
  _Spark.sparkle(
    'M18 148 23 162 37 167 23 172 18 186 13 172 -1 167 13 162Z',
    _SparkFill.coin,
  ),
  // <path d="M334 150 339 164 353 169 339 174 334 188 329 174 315 169 329 164Z" fill="#FF8A5B"/>
  _Spark.sparkle(
    'M334 150 339 164 353 169 339 174 334 188 329 174 315 169 329 164Z',
    _SparkFill.peach,
  ),
  // <circle cx="86" cy="10" r="7" fill="#F4B400"/>
  _Spark.dot(Offset(86, 10), 7, _SparkFill.coin),
  // <circle cx="268" cy="8" r="6" fill="#3D7FF0"/>
  _Spark.dot(Offset(268, 8), 6, _SparkFill.sky),
  // <circle cx="70" cy="206" r="7" fill="#1F9D63"/>
  _Spark.dot(Offset(70, 206), 7, _SparkFill.success),
  // <circle cx="286" cy="210" r="6" fill="#7C6CF2"/>
  _Spark.dot(Offset(286, 210), 6, _SparkFill.lilac),
];

/// The sparks layer: a 350x250 transparent box, centred horizontally by its
/// caller at `top: 92`. Decorative (CSS `aria-hidden="true"`,
/// `pointer-events: none`), so it carries no semantics and never intercepts a
/// tap. At 320 px the 350 px box overflows and the screen's `Stack` clips it,
/// exactly like the SVG's `overflow: hidden`.
class PipEvolutionSparks extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: IgnorePointer(
        child: SizedBox(
          width: EvolutionSparksGeometry.boxWidth,
          height: EvolutionSparksGeometry.boxHeight,
          child: Center(
            child: CustomPaint(
              size: EvolutionSparksGeometry.artSize,
              painter: _SparksPainter(tokens: context.nest),
            ),
          ),
        ),
      ),
    );
  }
}

class _SparksPainter extends CustomPainter {
  const _SparksPainter({required this.tokens});

  final NestTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    // The `<g stroke="#1E1B3A" stroke-width="3" stroke-linejoin="round">`.
    final stroke = Paint()
      ..color = tokens.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = EvolutionSparksGeometry.strokeWidth
      ..strokeJoin = StrokeJoin.round;
    // The SVG root clips its own overflow, and sparkle 3 reaches x = -1, so
    // its left arm is cut at the box edge in the design.
    canvas
      ..save()
      ..clipRect(Offset.zero & size);
    for (final spark in _sparks) {
      final fill = Paint()
        ..color = spark.colorOf(tokens)
        ..style = PaintingStyle.fill;
      final path = spark.path;
      if (path != null) {
        canvas
          ..drawPath(path, fill)
          ..drawPath(path, stroke);
      } else {
        canvas
          ..drawCircle(spark.center!, spark.radius!, fill)
          ..drawCircle(spark.center!, spark.radius!, stroke);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SparksPainter oldDelegate) =>
      oldDelegate.tokens != tokens;
}

/// The design's `d` subset: one absolute `M` followed by implicit absolute
/// lineto pairs (`M32 30 37 44 …`), closed with `Z`. These are the only
/// commands the HTML uses, so a full SVG parser would be dead code.
///
/// EVERY vertex goes to [Path.addPolygon], starting at the `M` pair itself:
/// `addPolygon` opens its own contour (`_addLeadingPoint`), so a separate
/// `moveTo` before it is discarded and `close` returns to the polygon's *own*
/// first vertex, never to the `moveTo` point. Building it the old way silently
/// dropped each sparkle's `M` tip — the design's symmetric 4-point star painted
/// as a flat-topped blob (`6_bugs.md` K07-BUG-4 = `5_ui.md` D2).
Path _sparkPath(String d) {
  final numbers = RegExp(r'-?\d+(\.\d+)?')
      .allMatches(d.replaceAll(RegExp('[MZ]'), ' '))
      .map((m) => double.parse(m.group(0)!))
      .toList(growable: false);
  return Path()..addPolygon(<Offset>[
    for (var i = 0; i + 1 < numbers.length; i += 2)
      Offset(numbers[i], numbers[i + 1]),
  ], true);
}
