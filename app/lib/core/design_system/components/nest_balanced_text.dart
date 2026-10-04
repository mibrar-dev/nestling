import 'package:flutter/material.dart';

/// Balanced heading text — the Flutter equivalent of CSS
/// `text-wrap: balance` (used by `.display`, `.h1`, `.kid-title`,
/// `.kid-hero` and the `.balance` utility in
/// `design/html-source/components.css`).
///
/// Flutter has no balanced-wrap mode: a centred multi-line heading breaks as
/// late as possible, orphaning one short word on the last line (P07 rendered
/// "Try Nestling free for 14" / "days"). [NestBalancedText] keeps the
/// minimum line count the full width needs, then shrinks to the narrowest
/// width that still fits that many lines (binary search over [TextPainter]
/// layouts), so the break moves earlier and the lines come out even (P07:
/// "Try Nestling" / "free for 14 days"). The narrowed box is centred — or
/// aligned as [textAlign] asks — so the heading keeps its screen position.
///
/// The text stays a single [Text] node: semantics, `find.text`, ellipsis and
/// [maxLines] all behave exactly as before (no inserted `\n`).
class NestBalancedText extends StatelessWidget {
  const NestBalancedText(
    this.text, {
    required this.style,
    super.key,
    this.textAlign = TextAlign.center,
    this.maxLines,
    this.overflow = TextOverflow.clip,
    this.softWrap = true,
  });

  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;
  final bool softWrap;

  /// Line count of [text] laid out at [maxWidth] with the given style.
  @visibleForTesting
  static int lineCountFor({
    required String text,
    required TextStyle style,
    required double maxWidth,
    required TextDirection textDirection,
    required TextScaler textScaler,
    int? maxLines,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
      textScaler: textScaler,
      maxLines: maxLines,
      ellipsis: maxLines == null ? null : '…',
    )..layout(maxWidth: maxWidth < 1 ? 1 : maxWidth);
    return painter.computeLineMetrics().length;
  }

  /// Narrowest width in `(0, maxWidth]` that still lays out in [lineCount]
  /// lines (binary search to within half a logical pixel). Callers pass the
  /// minimum line count from [lineCountFor] at the full width.
  @visibleForTesting
  static double balancedWidthFor({
    required String text,
    required TextStyle style,
    required double maxWidth,
    required int lineCount,
    required TextDirection textDirection,
    required TextScaler textScaler,
    int? maxLines,
  }) {
    var lo = 0.0;
    var hi = maxWidth;
    // Twelve halvings narrow 390 dp to well under half a pixel.
    for (var i = 0; i < 12; i++) {
      final mid = (lo + hi) / 2;
      // K04-BUG-1: probe with the NATURAL line count, not the maxLines-capped
      // one. The capped probe reports `maxLines` for any text that does not
      // fit, at every width, so the search collapsed to ~0 px and the heading
      // rendered as a 0.1 px-wide clipped gap. With the natural count the
      // search finds the narrowest width that still lays out in [lineCount]
      // natural lines (or, when the text can never fit [lineCount] lines,
      // keeps shrinking to [lo]≈0 — callers must bail out first, and
      // [build] does: it returns full-width text whenever the natural count
      // exceeds its maxLines cap).
      final lines = lineCountFor(
        text: text,
        style: style,
        maxWidth: mid,
        textDirection: textDirection,
        textScaler: textScaler,
      );
      if (lines <= lineCount) {
        hi = mid;
      } else {
        lo = mid;
      }
    }
    return hi;
  }

  Alignment get _alignment => switch (textAlign) {
    TextAlign.left || TextAlign.start => Alignment.centerLeft,
    TextAlign.right || TextAlign.end => Alignment.centerRight,
    _ => Alignment.center,
  };

  Text _text() => Text(
    text,
    style: style,
    textAlign: textAlign,
    maxLines: maxLines,
    overflow: maxLines == null ? TextOverflow.clip : overflow,
    softWrap: softWrap,
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        if (!maxWidth.isFinite || maxWidth <= 0) return _text();
        final direction = Directionality.of(context);
        final scaler = MediaQuery.textScalerOf(context);
        final minLines = lineCountFor(
          text: text,
          style: style,
          maxWidth: maxWidth,
          textDirection: direction,
          textScaler: scaler,
          maxLines: maxLines,
        );
        if (minLines <= 1) return _text();
        // K04-BUG-1: when the natural layout needs MORE lines than the
        // maxLines cap allows, the heading can never balance within the cap
        // and the width probe would collapse to ~0 px. Render full width
        // instead (the Text's own maxLines ellipsis keeps it honest).
        final naturalLines = lineCountFor(
          text: text,
          style: style,
          maxWidth: maxWidth,
          textDirection: direction,
          textScaler: scaler,
        );
        final cap = maxLines;
        if (cap != null && naturalLines > cap) return _text();
        final width = balancedWidthFor(
          text: text,
          style: style,
          maxWidth: maxWidth,
          lineCount: minLines,
          textDirection: direction,
          textScaler: scaler,
          maxLines: maxLines,
        );
        // Full width already optimal: no extra box (keeps the exact rect).
        if (width >= maxWidth - 0.5) return _text();
        return Align(
          alignment: _alignment,
          child: SizedBox(width: width, child: _text()),
        );
      },
    );
  }
}
