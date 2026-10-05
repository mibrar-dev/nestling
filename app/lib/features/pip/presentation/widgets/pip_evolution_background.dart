// K07's screen-local background: the lilac glow + dark-mode stars.
//
// PLAN-vs-ORCHESTRATOR NOTE (`1_plan.md` §0): the orchestrator's generic rule
// says every K screen gets `KidScope` (sky gradient + meadow hills). K07's own
// HTML overrides `.screen.kid` (line 16):
//
//   background-color: var(--surface);
//   background-image: var(--kid-stars),
//     radial-gradient(118% 62% at 50% 36%, var(--lilac-tint) 0%,
//                     var(--surface) 58%, var(--lilac-tint) 100%);
//
// and its body contains NO `.meadow` element (the `.meadow` CSS in the style
// block is dead boilerplate): both K07 PNGs show a white/lilac glow in light
// and a dark-purple glow with pinprick stars in dark, with NO hills. So this
// paints the CSS gradient exactly and reuses the SHARED star painter
// ([NestKidStarsPainter], the same one `KidScope` mounts) in dark only. No
// local hills are painted anywhere.
import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/design_system.dart';

/// `radial-gradient(118% 62% at 50% 36%)` — the CSS geometry, as fractions of
/// the box it fills (never literals: the design is 390x844, the box is
/// whatever the device gives us).
abstract final class EvolutionGlowGeometry {
  const new _();

  /// `at 50% 36%`.
  static const double centerX = 0.5;
  static const double centerY = 0.36;

  /// `118%` of the box width.
  static const double radiusX = 1.18;

  /// `62%` of the box height.
  static const double radiusY = 0.62;

  /// `var(--surface) 58%` — where the glow hands back to the base surface.
  static const double surfaceStop = 0.58;
}

/// The K07 background layer: `background-color: var(--surface)` plus the
/// elliptical radial glow. Decorative (`pointer-events:none` in CSS), so it
/// never intercepts a tap.
class PipEvolutionGlow extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return IgnorePointer(
      child: ColoredBox(
        color: tokens.surface,
        child: CustomPaint(
          painter: _EvolutionGlowPainter(
            tint: tokens.lilacTint,
            surface: tokens.surface,
          ),
        ),
      ),
    );
  }
}

/// Paints the CSS ellipse exactly.
///
/// A `BoxDecoration`/`RadialGradient` cannot express CSS's explicit `118% 62%`
/// radii (Flutter's `RadialGradient` is always concentric circles), so the
/// canvas is translated to the centre, scaled to the ellipse radii and the
/// unit circle is filled with a circular three-stop shader — the shape and the
/// stops then match the browser's, at any box size.
class _EvolutionGlowPainter extends CustomPainter {
  const _EvolutionGlowPainter({required this.tint, required this.surface});

  final Color tint;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[tint, surface, tint],
        stops: const <double>[0, EvolutionGlowGeometry.surfaceStop, 1],
      ).createShader(const Rect.fromLTWH(-1, -1, 2, 2));
    // The shader is a 2x2 box centred on the origin (the unit circle's bounds),
    // so after `scale(rx, ry)` the gradient's radii ARE the CSS `118% 62%`.
    canvas
      ..save()
      ..translate(
        size.width * EvolutionGlowGeometry.centerX,
        size.height * EvolutionGlowGeometry.centerY,
      )
      ..scale(
        size.width * EvolutionGlowGeometry.radiusX,
        size.height * EvolutionGlowGeometry.radiusY,
      )
      ..drawCircle(Offset.zero, 1, paint)
      ..restore();
  }

  @override
  bool shouldRepaint(covariant _EvolutionGlowPainter oldDelegate) =>
      oldDelegate.tint != tint || oldDelegate.surface != surface;
}

/// The dark-only `--kid-stars` layer (CSS `background-image`'s first layer).
/// Light sets `--kid-stars: none`, so it is mounted in dark mode only —
/// identical to `KidScope`'s stars layer, shared painter and all.
class PipEvolutionStars extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: CustomPaint(painter: NestKidStarsPainter()),
    );
  }
}
