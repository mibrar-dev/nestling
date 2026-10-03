// P01 + P02 balanced headings — the design CSS uses `text-wrap: balance`
// on `.display` (P01) and on `.h1` / `pg-title` with `.balance` (P02), so
// both headlines render through `NestBalancedText` (same copy, style and
// maxLines; no maxLines added where there was none).
//
// With the bundled Inter/Nunito faces loaded (the P04 geometry-test
// pattern) each heading breaks exactly like the design PNG at 390 px:
//   P01 `design/screens/light/P01-welcome.png` (1170 px wide ÷ 3 = 390):
//     "Chores that feel" / "like a game."
//   P02 `design/screens/light/P02-value-tour.png` (÷ 3 = 390), step 1:
//     "Set quests in seconds" on one line.
// Steps 2–3 have no static PNG (the HTML only carries step 1); they are
// measured here too and also stay on one balanced line at 390 px, so the
// switch is a no-visual-change rule compliance.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';

import '../../test_scope.dart';

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

/// Splits [text] into rendered lines by scanning caret rows at [maxWidth].
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
  return lines.where((line) => line.isNotEmpty).toList();
}

Future<void> _pumpAt390(WidgetTester tester, String route) async {
  await setUpTestScope();
  await pumpAppRoute(tester, route);
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

List<String> _renderedLines(WidgetTester tester, String text) {
  final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
  final width = tester.getSize(find.text(text)).width;
  return _laidOutLines(text, paragraph.text.style!, width);
}

void main() {
  setUpAll(_loadBundledFonts);

  group('P01 + P02 balanced headings (real Inter/Nunito, 390 px)', () {
    testWidgets(
      'P01 headline uses NestBalancedText and breaks like the design',
      (tester) async {
        await _pumpAt390(tester, '/welcome');

        const headline = 'Chores that feel like a game.';
        final balanced = find.byType(NestBalancedText);
        expect(
          balanced,
          findsOneWidget,
          reason: 'the design `.display` uses text-wrap: balance',
        );
        final widget = tester.widget<NestBalancedText>(balanced);
        expect(widget.text, headline);
        expect(widget.textAlign, TextAlign.left);
        // The view had no maxLines, and the rule forbids adding one.
        expect(widget.maxLines, isNull);
        expect(widget.overflow, TextOverflow.clip);
        // Same style as before: the display token (34/40 w900, -0.34 tracking).
        final display = NestType.display();
        expect(widget.style.fontSize, display.fontSize);
        expect(widget.style.fontWeight, display.fontWeight);
        expect(widget.style.fontFamily, display.fontFamily);
        expect(widget.style.letterSpacing, display.letterSpacing);
        expect(widget.style.height, display.height);

        // Design PNG (÷ 3): two lines, break after "feel".
        expect(_renderedLines(tester, headline), [
          'Chores that feel',
          'like a game.',
        ]);

        await disposeApp(tester);
      },
    );

    testWidgets('P02 step 1 uses NestBalancedText and stays on one line', (
      tester,
    ) async {
      await _pumpAt390(tester, '/value-tour');

      const title = 'Set quests in seconds';
      final balanced = find.byType(NestBalancedText);
      expect(
        balanced,
        findsOneWidget,
        reason: 'the design `.h1.balance.pg-title` uses text-wrap: balance',
      );
      final widget = tester.widget<NestBalancedText>(balanced);
      expect(widget.text, title);
      expect(widget.textAlign, TextAlign.left);
      expect(widget.maxLines, isNull);
      final h1 = NestType.h1();
      expect(widget.style.fontSize, h1.fontSize);
      expect(widget.style.fontWeight, h1.fontWeight);
      expect(widget.style.fontFamily, h1.fontFamily);
      expect(widget.style.height, h1.height);

      // Design PNG (÷ 3): step 1 fits on one 28/34 line.
      expect(_renderedLines(tester, title), ['Set quests in seconds']);

      await disposeApp(tester);
    });

    testWidgets('P02 steps 2-3 stay on one balanced line (no visual change)', (
      tester,
    ) async {
      await _pumpAt390(tester, '/value-tour');

      await tester.tap(find.byKey(const ValueKey('p02_next')));
      await tester.pumpAndSettle();
      const step2 = 'Pip grows as they help';
      expect(find.text(step2), findsOneWidget);
      expect(
        tester.widget<NestBalancedText>(find.byType(NestBalancedText)).text,
        step2,
      );
      expect(_renderedLines(tester, step2), ['Pip grows as they help']);

      await tester.tap(find.byKey(const ValueKey('p02_next')));
      await tester.pumpAndSettle();
      const step3 = 'Pocket money, sorted';
      expect(find.text(step3), findsOneWidget);
      expect(
        tester.widget<NestBalancedText>(find.byType(NestBalancedText)).text,
        step3,
      );
      expect(_renderedLines(tester, step3), ['Pocket money, sorted']);

      await disposeApp(tester);
    });
  });
}
