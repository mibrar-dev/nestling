// P03 Create account — design typography proofs with the REAL fonts.
//
// `flutter test` replaces every font family with a wide test fallback, so
// for iterations 1–5 P03's line breaks were untestable: the harness' glyphs
// are ~2× the design's advances, which is why this screen's wrap points
// ("Children never" / "Privacy Notice" / "Create your") could only be
// measured on the simulator. Since the shared batch bundled the designs'
// own Inter/Nunito builds (`assets/fonts/*.ttf`), loading them with a
// `FontLoader` makes the widget tree lay out with the design's real glyph
// metrics — the probe that produced the first measurement here also put
// "At least 8 characters" at 126.74 dp against the design PNG's 126.00.
//
// So the design's actual wraps are now pinned here, font-for-font:
//
//   headline  "Create your" / "family account"          (Nunito 900, 28/34)
//   subtitle  "You're the grown-up in charge. Children never" /
//             "need an email."                           (Inter 400, 16/24)
//   helper    "At least 8 characters" on one line        (Inter 400, 13/18)
//   caption   "By continuing you agree to our Terms and" /
//             "Privacy Notice" (U+00A0 keeps the label whole)
//
// Reference widths are the ink bounding boxes measured from
// `design/screens/light/P03-create-account.png` at 3×, divided by 3; the
// browser advance of the subtitle's first line (349.06 dp in a 350 dp
// column) is the same reference `test/design_system/body_text_width_test.dart`
// pins shared-side. A font build, size, weight or letter-spacing that
// drifts shows up here as a moved line boundary, so these assertions fail
// on the regression the shared width test only catches for body text.
//
//   flutter test test/features/auth/typography_test.dart

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';

import '../../test_scope.dart';

const String _subtitle =
    'You\u2019re the grown-up in charge. Children never need an email.';
const String nbsp = '\u00a0';

/// Design PNG ink widths (dp), measured at 3× and divided by 3.
const Map<String, double> _designInk = <String, double>{
  'Create your': 157.33,
  'family account': 198.00,
  'need an email.': 108.00,
  'At least 8 characters': 126.00,
  'By continuing you agree to our Terms and': 261.00,
  'Privacy\u00a0Notice': 91.33,
};

/// The browser advance of the subtitle's first line (shared reference).
const double _subtitleLine1Advance = 349.06;

Future<void> _loadDesignFonts() async {
  Future<void> family(String name, List<String> assets) async {
    final loader = FontLoader(name);
    for (final asset in assets) {
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }

  await family('Inter', const [
    'assets/fonts/Inter-Regular.ttf',
    'assets/fonts/Inter-Medium.ttf',
    'assets/fonts/Inter-SemiBold.ttf',
    'assets/fonts/Inter-Bold.ttf',
  ]);
  await family('Nunito', const [
    'assets/fonts/Nunito-Bold.ttf',
    'assets/fonts/Nunito-ExtraBold.ttf',
    'assets/fonts/Nunito-Black.ttf',
  ]);
}

Future<void> _pump(
  WidgetTester tester, {
  Size size = const Size(390, 844),
}) async {
  await setUpTestScope();
  tester.view.physicalSize = size * 3;
  addTearDown(tester.view.reset);
  await pumpAppRoute(tester, '/create-account');
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// One laid-out line: its words, the box the paragraph painted for it, and
/// the top of that box relative to the paragraph.
class _Line {
  _Line(this.text, this.box, this.top);

  final String text;
  final Rect box;
  final double top;

  /// Where the line sits, in global coordinates.
  Rect global(RenderParagraph paragraph) =>
      box.shift(paragraph.localToGlobal(Offset.zero));
}

/// The lines of [paragraph] as the paragraph actually broke them.
///
/// A caret's vertical position is the only public signal for "a line ended
/// here", so the walk steps through the string and opens a new line
/// whenever the caret drops past the current line's top (with half a pixel
/// of slack, because the caret rounds within a line's leading). The line's
/// own box is the union of the selection boxes for its range — the advance
/// the paragraph laid that glyph run out at.
List<_Line> _linesOf(RenderParagraph paragraph) {
  final plain = paragraph.text.toPlainText();
  double caretTop(int offset) =>
      paragraph.getOffsetForCaret(TextPosition(offset: offset), Rect.zero).dy;

  final lines = <_Line>[];
  var start = 0;
  var top = caretTop(0);
  for (var i = 1; i <= plain.length; i++) {
    final atEnd = i == plain.length;
    final dy = caretTop(i);
    if (!atEnd && dy <= top + 0.5) continue;

    // A break can land on the space after the last word; measuring it would
    // add that space's advance to the line.
    var end = i;
    while (end > start && plain[end - 1] == ' ') {
      end--;
    }
    Rect? box;
    if (end > start) {
      for (final found in paragraph.getBoxesForSelection(
        TextSelection(baseOffset: start, extentOffset: end),
      )) {
        box = box == null
            ? found.toRect()
            : box.expandToInclude(found.toRect());
      }
    }
    final painted = box ?? Rect.zero;
    lines.add(_Line(plain.substring(start, i).trim(), painted, painted.top));
    start = i;
    top = dy;
  }
  return lines;
}

RenderParagraph _paragraphOf(WidgetTester tester, Finder finder) =>
    tester.renderObject<RenderParagraph>(finder);

Finder _captionParagraph() => find
    .descendant(of: find.byType(NestBottomCta), matching: find.byType(RichText))
    .last;

/// Asserts [line]'s painted advance against the design PNG's ink width.
///
/// The advance is the paragraph's box for the line, so it is at least the
/// ink run and within a side bearing of it. At the bundled builds the
/// measured advances drift from the PNG's ink boxes by -1.1% (the caption's
/// first line) to +1.9% ("need an email."), so 3% is the slack; the tight
/// guard against a swapped font build is the subtitle's first line,
/// asserted at 1% against the browser advance — that is the drift
/// P03-BUG-17 shipped with.
void _expectDesignWidth(_Line line) {
  final design = _designInk[line.text];
  expect(
    design,
    isNotNull,
    reason:
        'line "${line.text}" is not one of the design lines — the wrap moved',
  );
  final drift = (line.box.width - design!).abs() / design;
  expect(
    drift,
    lessThan(0.03),
    reason:
        'line "${line.text}" is ${line.box.width.toStringAsFixed(2)} dp '
        'wide, the design PNG measures ${design.toStringAsFixed(2)} dp '
        '(drift ${(drift * 100).toStringAsFixed(2)}%)',
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadDesignFonts();
  });

  group('P03 line breaks match the design with the design fonts loaded', () {
    testWidgets('the headline breaks after "Create your"', (tester) async {
      await _pump(tester);
      final paragraph = _paragraphOf(
        tester,
        find.text('Create your family account'),
      );
      final lines = _linesOf(paragraph);
      expect(
        lines.map((line) => line.text),
        <String>['Create your', 'family account'],
        reason:
            'the design PNG breaks the h1 after "Create your" '
            '(Nunito 900, --fs-h1/--lh-h1 28/34, components.css:29)',
      );
      expect(
        (lines[1].top - lines[0].top).round(),
        34,
        reason: "the design's headline line pitch is --lh-h1 (34)",
      );
      lines.forEach(_expectDesignWidth);
      expect(
        lines.first.global(paragraph).left,
        closeTo(20, 0.6),
        reason: 'the headline sits on the 20 px gutter (ALIGNMENT rule)',
      );
      await disposeApp(tester);
    });

    testWidgets('the subtitle breaks after "Children never"', (tester) async {
      await _pump(tester);
      final paragraph = _paragraphOf(tester, find.text(_subtitle));
      final lines = _linesOf(paragraph);
      expect(
        lines.map((line) => line.text),
        <String>[
          'You\u2019re the grown-up in charge. Children never',
          'need an email.',
        ],
        reason:
            'P03-BUG-17: the served Inter build used to be ~3–4% wider '
            'than the design\u2019s, which broke the line after "Children". '
            'The bundled builds restore the design break; the first line\u2019s '
            'advance is pinned at $_subtitleLine1Advance dp by the shared '
            'body_text_width_test.dart.',
      );
      expect(
        (lines[1].top - lines[0].top).round(),
        24,
        reason: "the design's body line pitch is --lh-body (24)",
      );
      expect(
        lines.first.box.width,
        closeTo(_subtitleLine1Advance, _subtitleLine1Advance * 0.01),
        reason:
            'the browser advances the first line by '
            '$_subtitleLine1Advance dp in the 350 dp column',
      );
      _expectDesignWidth(lines[1]);
      expect(
        lines.first.global(paragraph).left,
        closeTo(20, 0.6),
        reason: 'the subtitle sits on the 20 px gutter (ALIGNMENT rule)',
      );
      await disposeApp(tester);
    });

    testWidgets('the password helper is one line at the design width', (
      tester,
    ) async {
      await _pump(tester);
      final lines = _linesOf(
        _paragraphOf(tester, find.text('At least 8 characters')),
      );
      expect(lines.map((line) => line.text), <String>[
        'At least 8 characters',
      ], reason: 'the design puts the whole helper on one line');
      _expectDesignWidth(lines.single);
      await disposeApp(tester);
    });

    testWidgets('the caption breaks after "Terms and"', (tester) async {
      await _pump(tester);
      final lines = _linesOf(_paragraphOf(tester, _captionParagraph()));
      expect(
        lines.map((line) => line.text),
        <String>[
          'By continuing you agree to our Terms and',
          'Privacy${nbsp}Notice',
        ],
        reason:
            'the design PNG breaks the legal caption after "Terms and"; '
            'U+00A0 keeps "Privacy Notice" whole on line 2 (COPY rule, '
            'P03-BUG-9)',
      );
      expect(
        (lines[1].top - lines[0].top).round(),
        20,
        reason:
            "the design's caption line pitch is 20 dp "
            '(components.css: `.link { line-height: 20px }`)',
      );
      lines.forEach(_expectDesignWidth);
      for (final line in lines) {
        expect(
          line.global(_paragraphOf(tester, _captionParagraph())).center.dx,
          closeTo(195, 0.6),
          reason:
              'the design centres the caption '
              '(components.css: `.bottom-cta .caption { text-align: center }`)',
        );
      }
      await disposeApp(tester);
    });

    testWidgets('nothing is ellipsised or clipped at 390', (tester) async {
      await _pump(tester);
      for (final finder in <Finder>[
        find.text('Create your family account'),
        find.text(_subtitle),
        find.text('At least 8 characters'),
        _captionParagraph(),
      ]) {
        final paragraph = _paragraphOf(tester, finder);
        expect(
          paragraph.didExceedMaxLines,
          isFalse,
          reason:
              'the design never truncates "${paragraph.text.toPlainText()}"',
        );
      }
      await disposeApp(tester);
    });
  });

  group('P03 balanced headings (BALANCED HEADINGS rule)', () {
    // The finding itself lives in `p03_bugs_test.dart` (P03-BUG-24, red:
    // P03 still renders a plain `Text` in a 240 dp `ConstrainedBox` where
    // the design's `<h1 class="h1">` uses `text-wrap: balance`,
    // components.css:29). What is here guards the *migration*: these hold
    // today and must hold after the swap, so a fix that moves the design's
    // break or its gutter fails here instead of on the device.
    testWidgets('the balanced headline keeps the design break and gutter', (
      tester,
    ) async {
      await _pump(tester);
      final lines = _linesOf(
        _paragraphOf(tester, find.text('Create your family account')),
      );
      expect(
        lines.map((line) => line.text),
        <String>['Create your', 'family account'],
        reason:
            'the design PNG breaks the h1 after "Create your" — the '
            'component must not move the break',
      );
      lines.forEach(_expectDesignWidth);
      expect(
        lines.first
            .global(
              _paragraphOf(tester, find.text('Create your family account')),
            )
            .left,
        closeTo(20, 0.6),
        reason:
            'the design left-aligns the h1 on the 20 px gutter; '
            'NestBalancedText centres its narrowed box unless the call site '
            'passes `textAlign: TextAlign.left`',
      );
      await disposeApp(tester);
    });

    testWidgets('the migration keeps the pixels at the design size', (
      tester,
    ) async {
      // Builds the component the rule asks for, inside the cap the design
      // needs, so the fix is known to be reachable: at 1.0
      // `NestBalancedText` narrows the 240 dp box to 197.7 dp — the
      // narrowest width that still holds "family account" — and neither the
      // break nor the gutter moves. If this goes red the migration needs a
      // different width, not a different component.
      await tester.pumpWidget(
        MaterialApp(
          theme: NestTheme.light(),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: NestSpacing.s5),
              child: Align(
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: NestBalancedText(
                    'Create your family account',
                    // Colour is irrelevant to wrapping here; the screen
                    // applies the design's `tokens.ink`.
                    style: NestType.h1(),
                    textAlign: TextAlign.left,
                    maxLines: 3,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final paragraph = tester.renderObject<RenderParagraph>(
        find.text('Create your family account'),
      );
      final lines = _linesOf(paragraph);
      expect(
        lines.map((line) => line.text),
        <String>['Create your', 'family account'],
        reason:
            'inside the 240 dp cap the design break is already the '
            'narrowest two-line break, so balancing cannot move it',
      );
      lines.forEach(_expectDesignWidth);
      expect(
        lines.first.global(paragraph).left,
        closeTo(20, 0.6),
        reason:
            'the narrowed box must stay on the 20 dp gutter, which is why '
            'the call site has to pass textAlign: TextAlign.left',
      );
      expect(
        paragraph.size.width,
        closeTo(197.7, 1),
        reason:
            'the component narrows the cap to the narrowest two-line '
            'width; measured 197.68 dp',
      );
    });

    // Shared defect, not a P03 one — see SHARED_REQUEST.md §10.
    // `NestBalancedText.balancedWidthFor` binary-searches the narrowest
    // width whose line count is `<= lineCount`, but the painter it measures
    // through also applies `maxLines`. When the text needs more lines than
    // `maxLines` allows *at every width it is offered*, the count is clamped
    // to `maxLines` throughout, so the search converges to ~0 and the heading
    // renders one glyph per line. P03's h1 does not reach that state: at
    // scale 1.3 the 350 dp column still holds two lines, so the count falls
    // out of the clamp at ~257 dp and the narrowing lands on a real width.
    // These guards exist to catch a regression into the collapsed box
    // (240×0.1 dp, 132 tall), not to pin one wrap pattern — the two width
    // expectations below are the part that must never give.
    testWidgets('the headline is not a per-glyph column at text scale 1.3', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pump(tester);

      final finder = find.text('Create your family account');
      final paragraph = tester.renderObject<RenderParagraph>(finder);
      final lines = _linesOf(paragraph);
      expect(
        paragraph.size.width,
        greaterThan(150),
        reason:
            'a balanced wrap must never collapse the box; a ~0 dp box '
            'renders one glyph per line (SHARED_REQUEST §10)',
      );
      expect(
        lines.every((line) => line.box.width > 100),
        isTrue,
        reason:
            'every headline line must carry words, not single glyphs; '
            'got ${lines.map((line) => line.text).toList()}',
      );
      // Post-migration (BALANCED HEADINGS rule, P03-BUG-24): the balanced
      // wrap keeps the design's two even lines at 1.3 too — the h1 no longer
      // orphans a word on a third line the way the retired 240 dp cap did.
      expect(lines.map((line) => line.text), <String>[
        'Create your',
        'family account',
      ]);
      await disposeApp(tester);
    });

    testWidgets('the body, caption and CTA keep plain Text', (tester) async {
      await _pump(tester);
      // "Never use it on .h2/.h3/.body/.caption": the subtitle, the helper,
      // the note row and the CTA label are body/caption text and must stay
      // outside the balancing component, so that fixing P03-BUG-24 cannot
      // spread the component over the whole screen.
      for (final text in <String>[
        _subtitle,
        'At least 8 characters',
        'No child emails or photos \u2014 ever.',
        'Create account',
      ]) {
        final finder = find.text(text);
        expect(finder, findsOneWidget, reason: 'missing "$text"');
        expect(
          find.descendant(of: finder, matching: find.byType(NestBalancedText)),
          findsNothing,
          reason: '"$text" is body/caption text and must stay a plain Text',
        );
      }
      await disposeApp(tester);
    });
  });

  group('P03 shapes match the design PNG (UI checks measure shapes)', () {
    // Visible background/border rects measured from
    // `design/screens/light/P03-create-account.png` at 3x, divided by 3 —
    // not where the text lands. A pill that collapsed to its text width, or a
    // field that lost its fill, passes a text-only check and fails these.
    testWidgets('the fields, brand pills and rules are the design shapes', (
      tester,
    ) async {
      await _pump(tester);

      Rect fieldTop(String key) => tester.getRect(
        find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(TextField),
        ),
      );

      final email = fieldTop('p03_email');
      final password = fieldTop('p03_password');
      final apple = tester.getRect(
        find.byKey(const ValueKey('p03_apple')).first,
      );
      final google = tester.getRect(
        find.byKey(const ValueKey('p03_google')).first,
      );

      // Every full-width shape spans the 350 px column between the gutters.
      for (final entry in <String, Rect>{
        'email field': email,
        'password field': password,
        'Apple button': apple,
        'Google button': google,
      }.entries) {
        expect(
          entry.value.left,
          closeTo(20, 0.5),
          reason: '${entry.key} starts on the 20 px gutter (ALIGNMENT rule)',
        );
        expect(
          entry.value.width,
          closeTo(350, 0.5),
          reason: '${entry.key} is a 350 px full-column shape in the design',
        );
      }
      expect(email.top, closeTo(443, 1), reason: 'design 443.00');
      expect(email.height, closeTo(52, 0.5), reason: 'design 443..495');
      expect(password.top, closeTo(535, 1), reason: 'design 535.00');
      expect(password.height, closeTo(52, 0.5), reason: 'design 535..587');
      expect(apple.top, closeTo(255, 1), reason: 'design 255.00');
      expect(apple.height, closeTo(52, 0.5), reason: 'design 255..306.67');
      expect(google.top, closeTo(319, 1), reason: 'design 319.00');
      expect(google.height, closeTo(52, 0.5), reason: 'design 319.00..371.00');

      // The "or" row's two rules: 1 px hairlines at the label's vertical
      // centre, design y 395..396, x 20..176 and 214..370.
      final rules =
          <Rect>[
              for (final element
                  in find
                      .byType(Divider)
                      .evaluate()
                      .where((e) => e.widget is Divider))
                tester.getRect(find.byWidget(element.widget)),
            ].where((r) => r.top > 380 && r.bottom < 420).toList()
            ..sort((a, b) => a.left.compareTo(b.left));
      expect(rules, hasLength(2), reason: 'the design draws exactly two rules');
      for (final rule in rules) {
        expect(rule.height, closeTo(1, 0.01), reason: 'a 1 px hairline');
        expect(rule.top, closeTo(395, 1), reason: 'design 395.00..396.00');
      }
      // Design: left rule x 20..176, right rule x 214..370, so the 13 px
      // label plus two 12 px gaps leaves 38 px between them.
      expect(rules.first.left, closeTo(20, 0.5));
      expect(rules.first.right, closeTo(176, 1));
      expect(rules.last.left, closeTo(214, 1));
      expect(rules.last.right, closeTo(370, 0.5));
      expect(
        rules[1].left - rules[0].right,
        closeTo(38, 1),
        reason: 'design 214 − 176 = 38',
      );

      await disposeApp(tester);
    });

    testWidgets('the CTA pill is the design shape inside the panel', (
      tester,
    ) async {
      await _pump(tester);
      final panel = tester.getRect(find.byType(NestBottomCta));
      final button = tester.getRect(find.byKey(const ValueKey('p03_submit')));
      // Design: x 20..370 (a 350 px pill), y 694..746, inside a panel that
      // starts at 677 — 16 px below the panel top. (A scan near the pill's
      // bottom row reads 29.33..360.67 because of the 26 px corner radius;
      // the box is the full column.) The test surface has no 34 dp
      // home-indicator inset, so the panel's own top differs from the
      // device; the shape and the offsets are what this pins.
      expect(button.left, closeTo(20, 0.5));
      expect(button.width, closeTo(350, 0.5));
      expect(button.height, closeTo(52, 0.5), reason: 'design 694..746');
      expect(
        button.top - panel.top,
        closeTo(16, 0.5),
        reason: 'the design leaves 16 px above the pill (694 − 678)',
      );
      await disposeApp(tester);
    });
  });

  group('P03 adds no letter spacing (LETTER SPACING rule)', () {
    testWidgets('every rendered run has zero tracking', (tester) async {
      await _pump(tester);
      // `NestType` styles default to 0 because the design CSS tracks nothing;
      // the rule allows tracking only where a screen's CSS sets it, and
      // P03's CSS sets none. Walks the paragraphs, so a `copyWith` that
      // re-introduced Material tracking would be caught here.
      final paragraphs = find.byType(RichText).evaluate();
      expect(paragraphs, isNotEmpty);
      final tracked = <String>[];
      for (final element in paragraphs) {
        final paragraph = element.widget as RichText;
        paragraph.text.visitChildren((span) {
          final style = span.style;
          if (style != null && (style.letterSpacing ?? 0) != 0) {
            tracked.add('"${span.toPlainText()}" ${style.letterSpacing}');
          }
          return true;
        });
      }
      expect(
        tracked,
        isEmpty,
        reason: "P03's CSS tracks nothing, so no run may carry tracking",
      );
      await disposeApp(tester);
    });
  });

  group('P03 layout sits on the design PNG bands', () {
    // Every band's top is the ink or box top measured at 3x from
    // `design/screens/light/P03-create-account.png` and divided by 3; the
    // device capture `docs/screens/P03/ui/filled-light.png` (the design's
    // own FILLED state, so the only apples-to-apples frame) reproduces these
    // numbers to the pixel.
    //
    // P03-BUG-23: with the design fonts the form block lands 2 dp low
    // because `_OrRow`'s caption line box is 18 dp where the design's
    // `.or-label` has no line-height (≈15.7 dp). Left red — the fix belongs
    // to the screen.
    testWidgets("the form bands are the design's", (tester) async {
      await _pump(tester);

      Rect boxOf(Finder key) => tester.getRect(
        find.descendant(of: key, matching: find.byType(TextField)),
      );

      final bands = <String, double>{
        'google button bottom': tester
            .getRect(find.byKey(const ValueKey('p03_google')).first)
            .bottom,
        'email field top': boxOf(find.byKey(const ValueKey('p03_email'))).top,
        'password field top': boxOf(find.byKey(const ValueKey('p03_password')))
            .top,
      };
      const design = <String, double>{
        'google button bottom': 371.00,
        'email field top': 443.00,
        'password field top': 535.00,
      };
      // The CTA panel is deliberately not in this list: the design PNG
      // carries the 34 dp home-indicator inset and the test surface has no
      // safe area, so the panel's top is 712 dp here against 678 dp on the
      // device. Its bottom edge has its own proof in
      // `create_account_view_test.dart`.

      final off = <String>[];
      for (final entry in bands.entries) {
        final want = design[entry.key]!;
        if ((entry.value - want).abs() > 1) {
          off.add(
            '${entry.key}: ${entry.value.toStringAsFixed(2)} vs '
            '${want.toStringAsFixed(2)}',
          );
        }
      }
      expect(
        off,
        isEmpty,
        reason:
            'P03-BUG-23 — these bands are where the design PNG puts '
            'them; the form block below the "or" row sits 2 dp low because '
            'the row paints an 18 dp caption line box instead of the '
            "design's 13 px/normal ≈15.7 dp",
      );

      await disposeApp(tester);
    });
  });

  group('P03 typography holds at the narrow and wide ends', () {
    for (final size in const <Size>[Size(320, 844), Size(430, 844)]) {
      testWidgets('${size.width.toInt()}dp: the caption never orphans a link', (
        tester,
      ) async {
        await _pump(tester, size: size);
        final lines = _linesOf(_paragraphOf(tester, _captionParagraph()));
        final texts = lines.map((line) => line.text).toList();
        expect(texts.first, startsWith('By continuing you agree to our '));
        expect(texts.last, contains('Privacy${nbsp}Notice'));
        for (final line in lines) {
          expect(line.text, isNot(contains('$nbsp ')));
          expect(line.text.trim(), isNotEmpty);
        }
        expect(
          find.text('Create your family account'),
          findsOneWidget,
          reason: 'the headline must not be dropped at ${size.width}dp',
        );
        await disposeApp(tester);
      });
    }

    testWidgets('text scale 1.3 keeps every string untruncated', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pump(tester);
      for (final finder in <Finder>[
        find.text('Create your family account'),
        find.text(_subtitle),
        find.text('At least 8 characters'),
        _captionParagraph(),
      ]) {
        final paragraph = _paragraphOf(tester, finder);
        expect(
          paragraph.didExceedMaxLines,
          isFalse,
          reason:
              'the design truncates nothing; "'
              '${paragraph.text.toPlainText()}" overflowed at 1.3',
        );
      }
      await disposeApp(tester);
    });

    testWidgets('dark mode breaks the same lines as light', (tester) async {
      await setUpTestScope();
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      addTearDown(tester.view.reset);
      await pumpAppRoute(tester, '/create-account', theme: ThemeMode.dark);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      final lines = _linesOf(_paragraphOf(tester, _captionParagraph()));
      expect(
        lines.map((line) => line.text),
        <String>[
          'By continuing you agree to our Terms and',
          'Privacy${nbsp}Notice',
        ],
        reason:
            'the fonts are theme-independent, so a different break in '
            'dark means the dark theme resolves a different family or size',
      );
      await disposeApp(tester);
    });
  });
}
