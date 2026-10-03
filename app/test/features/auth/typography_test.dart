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
