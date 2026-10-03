// Shared batch 3 — `NestBalancedText`, the Flutter equivalent of CSS
// `text-wrap: balance` (`.display`, `.h1`, `.kid-title`, `.kid-hero` and the
// `.balance` utility in `design/html-source/components.css`).
//
// The task's two proofs live here: the P07 title keeps two lines whose
// widths differ by less than one word, and — with the real bundled
// Inter/Nunito faces loaded via `FontLoader` (the P04 geometry-test
// pattern) — "Try Nestling free for 14 days" breaks after "Nestling".
// A font-independent unit group pins the search itself: the narrowest width
// that keeps the minimum line count.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';

import '../test_scope.dart';

const String _title = 'Try Nestling free for 14 days';

/// Loads the bundled faces so metrics match a device run (same set as the
/// P04 geometry test).
Future<void> _loadBundledFonts() async {
  final inter = FontLoader('Inter')
    ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-Medium.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-SemiBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-Bold.ttf'));
  final nunito = FontLoader('Nunito')
    ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Nunito-ExtraBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf'));
  await inter.load();
  await nunito.load();
}

/// Re-lays [text] out at [maxWidth] and splits it into rendered lines by
/// scanning caret rows (first offset whose caret drops to the next row
/// starts a new line).
List<String> _laidOutLines(String text, TextStyle style, double maxWidth) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textScaler: TextScaler.noScaling,
  )..layout(maxWidth: maxWidth);
  final lines = <String>[];
  var start = 0;
  var lineTop = painter
      .getOffsetForCaret(const TextPosition(offset: 0), Rect.zero)
      .dy;
  for (var i = 1; i <= text.length; i++) {
    final dy = painter.getOffsetForCaret(TextPosition(offset: i), Rect.zero).dy;
    if ((dy - lineTop).abs() > 0.5) {
      lines.add(text.substring(start, i).trim());
      start = i;
      lineTop = dy;
    }
  }
  lines.add(text.substring(start).trim());
  // The end-of-text caret can report a row of its own; it carries no text.
  return lines.where((line) => line.isNotEmpty).toList();
}

double _textWidth(String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textScaler: TextScaler.noScaling,
  )..layout();
  return painter.width;
}

void main() {
  // Real metrics everywhere below: the unit group names the bundled Nunito
  // face, so it needs the same FontLoader the widget group uses.
  setUpAll(_loadBundledFonts);

  group('NestBalancedText search', () {
    const style = TextStyle(
      fontFamily: 'Nunito',
      fontSize: 28,
      fontWeight: FontWeight.w900,
    );
    const maxWidth = 350.0;

    // Headings wrap (P07 allows three lines); the search mirrors `Text`,
    // where an ellipsis without `maxLines` is single-line by definition, so
    // the tests pin `maxLines` like every real call site does.
    const maxLines = 10;

    int count(double width) => NestBalancedText.lineCountFor(
      text: _title,
      style: style,
      maxWidth: width,
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
      maxLines: maxLines,
    );

    test('the title needs more than one line at the full width', () {
      expect(count(maxWidth), greaterThan(1));
    });

    test('the balanced width keeps the minimum line count', () {
      final minLines = count(maxWidth);
      final balanced = NestBalancedText.balancedWidthFor(
        text: _title,
        style: style,
        maxWidth: maxWidth,
        lineCount: minLines,
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
        maxLines: maxLines,
      );

      expect(balanced, lessThanOrEqualTo(maxWidth));
      expect(count(balanced), minLines);
    });

    test('one step narrower needs more lines (the width is minimal)', () {
      final minLines = count(maxWidth);
      final balanced = NestBalancedText.balancedWidthFor(
        text: _title,
        style: style,
        maxWidth: maxWidth,
        lineCount: minLines,
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
        maxLines: maxLines,
      );

      expect(count(balanced - 2), greaterThan(minLines));
    });

    test('a single-line heading lays out on one line', () {
      expect(
        NestBalancedText.lineCountFor(
          text: 'Hi',
          style: style,
          maxWidth: maxWidth,
          textDirection: TextDirection.ltr,
          textScaler: TextScaler.noScaling,
        ),
        1,
      );
    });
  });

  group('P07 title balance (real Inter/Nunito)', () {
    testWidgets('the title keeps two lines of near-equal width', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/paywall');

      // Re-lay the rendered style out at the widget's own (balanced) width:
      // `RenderParagraph` exposes no line metrics, but `TextPainter` does.
      final paragraph = tester.renderObject<RenderParagraph>(find.text(_title));
      final width = tester.getSize(find.text(_title)).width;
      final painter = TextPainter(
        text: TextSpan(text: _title, style: paragraph.text.style),
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
      )..layout(maxWidth: width);
      final metrics = painter.computeLineMetrics();
      expect(metrics, hasLength(2));

      final word = _textWidth('Nestling', paragraph.text.style!);
      expect(
        (metrics[0].width - metrics[1].width).abs(),
        lessThan(word),
        reason:
            'balanced lines differ by less than one word '
            '(${metrics[0].width} vs ${metrics[1].width}, word $word)',
      );

      await disposeApp(tester);
    });

    testWidgets('the title breaks after "Nestling"', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/paywall');

      final paragraph = tester.renderObject<RenderParagraph>(find.text(_title));
      final width = tester.getSize(find.text(_title)).width;
      final lines = _laidOutLines(_title, paragraph.text.style!, width);
      expect(lines, hasLength(2));
      expect(lines.first, 'Try Nestling');

      await disposeApp(tester);
    });
  });
}
