import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/radii.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';

/// Device status bar (47px): clock + signal/wifi/battery glyph row.
///
/// Spec `.status-bar`: height 47 (min 47), padding `12px 24px 0`, row
/// space-between center, Inter 15 w600, time `letter-spacing` −1%, icon row
/// gap 6. Colour ink by default, #FFFFFF on dark chrome (pass [lightIcons]),
/// ink explicitly on kid screens.
class NestStatusBar extends StatelessWidget {
  const new({
    super.key,
    this.time = '9:41',
    this.lightIcons = false,
    this.semanticLabel,
  });

  /// Draw the mock clock/signal/battery row. Off in the app (the OS draws
  /// the real one); the design-system gallery turns it on.
  static bool showMockGlyphs = false;

  final String time;
  final bool lightIcons;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    // In the running app iOS/Android draw the real status bar, so this
    // only reserves its height. The mock clock + glyphs are for the design
    // gallery and screenshot mockups ([showMockGlyphs]).
    if (!showMockGlyphs) {
      final inset = MediaQuery.viewPaddingOf(context).top;
      return SizedBox(
        height: inset > NestDevice.statusH ? inset : NestDevice.statusH,
      );
    }
    final tokens = context.nest;
    final color = lightIcons ? const Color(0xFFFFFFFF) : tokens.ink;
    final bar = SizedBox(
      height: NestDevice.statusH,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          NestSpacing.s6,
          NestSpacing.s3,
          NestSpacing.s6,
          0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(time, style: NestType.statusTime(color: color)),
            Row(
              spacing: NestSpacing.gap6,
              children: [
                _SignalBars(color: color),
                _WifiGlyph(color: color),
                _BatteryGlyph(color: color),
              ],
            ),
          ],
        ),
      ),
    );
    final label = semanticLabel;
    if (label == null) {
      return ExcludeSemantics(child: bar);
    }
    return Semantics(label: label, header: true, child: bar);
  }
}

class _SignalBars extends StatelessWidget {
  const new({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(18, 12), painter: _BarsPainter(color));
  }
}

class _BarsPainter extends CustomPainter {
  const new(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const widths = 3.0;
    final heights = [5.0, 7.5, 10.0, 12.0];
    for (var i = 0; i < 4; i++) {
      final h = heights[i];
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(i * 5.0, 12 - h, widths, h),
          const Radius.circular(1),
        ),
        i == 3 ? (paint..color = color.withValues(alpha: 0.35)) : paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarsPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _WifiGlyph extends StatelessWidget {
  const new({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(16, 12), painter: _WifiPainter(color));
  }
}

class _WifiPainter extends CustomPainter {
  const new(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawArc(
        const Rect.fromLTWH(-3.5, -3.5, 23, 16),
        0.6,
        3.14 - 1.2,
        false,
        paint,
      )
      ..drawArc(
        const Rect.fromLTWH(-0.5, -0.5, 17, 12),
        0.6,
        3.14 - 1.2,
        false,
        paint,
      )
      ..drawCircle(const Offset(8, 10), 1.2, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _WifiPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _BatteryGlyph extends StatelessWidget {
  const new({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(25, 12),
      painter: _BatteryPainter(color),
    );
  }
}

class _BatteryPainter extends CustomPainter {
  const new(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0.5, 0.5, 20, 11),
          const Radius.circular(3.5),
        ),
        stroke,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(2, 2, 15, 8),
          const Radius.circular(2),
        ),
        Paint()..color = color,
      );
    final nub = Path()
      ..moveTo(23, 4)
      ..lineTo(25, 4)
      ..lineTo(25, 8)
      ..lineTo(23, 8)
      ..close();
    canvas.drawPath(nub, Paint()..color = color.withValues(alpha: 0.4));
  }

  @override
  bool shouldRepaint(covariant _BatteryPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Home indicator reserve (34px): 134×5 pill, ink at 90% (white on dark
/// chrome). Kid screens keep ink.
class NestHomeIndicator extends StatelessWidget {
  const new({super.key, this.lightPill = false});

  final bool lightPill;

  @override
  Widget build(BuildContext context) {
    // The OS draws the real home indicator; the bottom inset belongs to
    // SafeArea (NestBottomCta, tab bar or the screen). Reserving 34 here as
    // well double-counted it (P01 BUG-2). Mock pill only for the gallery.
    if (!NestStatusBar.showMockGlyphs) return const SizedBox.shrink();
    final tokens = context.nest;
    final pill = lightPill ? const Color(0xFFFFFFFF) : tokens.ink;
    return ExcludeSemantics(
      child: SizedBox(
        height: NestDevice.homeH,
        child: Center(
          child: Container(
            width: 134,
            height: 5,
            decoration: BoxDecoration(
              color: pill.withValues(alpha: 0.9),
              borderRadius: NestRadii.allPill,
            ),
          ),
        ),
      ),
    );
  }
}
