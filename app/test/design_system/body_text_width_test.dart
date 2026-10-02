import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';

// Text widths must match the design HTML renders (headless Chrome, Inter
// 4.001 / Nunito 3.602 from Google Fonts — the same builds bundled in
// `assets/fonts`) within 1% at 390 width. Browser reference advances:
//   P04 body  "Exactly what we store — and nothing else."      319.97
//   P05 body  "Nicknames only — no photos, no email."           298.43
//   P03 full  "You're the grown-up in charge. Children …email." 463.59
//   P03 line1 "… Children never" (design break in a 350 column) 349.06
//   P04 h1    "Your family's privacy" (Nunito 900 28px)         280.52
//
// The shared styles resolve Inter/Nunito from the bundled assets, so these
// widths hold on first frame with no runtime font download. A regression to
// runtime fetching (or a wrong font build) shows up here as a fallback or
// transient width instead of the design width.

const _p04Body = 'Exactly what we store \u2014 and nothing else.';
const _p05Body = 'Nicknames only \u2014 no photos, no email.';
const _p03Body =
    'You\u2019re the grown-up in charge. '
    'Children never need an email.';
const _p04H1 = 'Your family\u2019s privacy';

Future<void> _loadBundledDesignFonts() async {
  Future<void> loadFamily(String family, List<String> assets) async {
    final loader = FontLoader(family);
    for (final asset in assets) {
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }

  await loadFamily('Inter', const [
    'assets/fonts/Inter-Regular.ttf',
    'assets/fonts/Inter-Medium.ttf',
    'assets/fonts/Inter-SemiBold.ttf',
    'assets/fonts/Inter-Bold.ttf',
  ]);
  await loadFamily('Nunito', const [
    'assets/fonts/Nunito-Bold.ttf',
    'assets/fonts/Nunito-ExtraBold.ttf',
    'assets/fonts/Nunito-Black.ttf',
  ]);
}

double _advance(String text, TextStyle style, {double? maxWidth}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: maxWidth == null ? 1 : null,
  )..layout(maxWidth: maxWidth ?? double.infinity);
  return painter.width;
}

void _expectDesignWidth(String label, double actual, double design) {
  final delta = (actual - design).abs() / design;
  expect(
    delta,
    lessThan(0.01),
    reason:
        '$label: $actual vs design $design '
        '(drift ${(delta * 100).toStringAsFixed(2)}% > 1%)',
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadBundledDesignFonts();
  });

  group('shared body text widths match the design', () {
    test('body style stays Inter 16/24 w400 from the bundled family', () {
      final body = NestType.body();
      expect(body.fontFamily, 'Inter');
      expect(body.fontSize, 16);
      expect(body.height, 24 / 16);
      expect(body.fontWeight, FontWeight.w400);
      expect(NestType.h1().fontFamily, 'Nunito');
    });

    // A missing/failed font load does not silently pass: the test fallback
    // advances every glyph at one em, so these strings would measure ~592 px
    // instead of ~319 / ~298.
    test('P04/P05 body advances match the browser renders', () {
      _expectDesignWidth(
        'P04 body',
        _advance(_p04Body, NestType.body()),
        319.97,
      );
      _expectDesignWidth(
        'P05 body',
        _advance(_p05Body, NestType.body()),
        298.43,
      );
    });

    test('P03 subtitle unwrapped advance matches the browser render', () {
      _expectDesignWidth(
        'P03 subtitle',
        _advance(_p03Body, NestType.body()),
        463.59,
      );
    });

    test('P03 subtitle wraps after "never" in a 350 px column', () {
      final painter = TextPainter(
        text: TextSpan(text: _p03Body, style: NestType.body()),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 350);
      final metrics = painter.computeLineMetrics();
      expect(
        metrics.length,
        2,
        reason: 'design wraps to 2 lines, got $metrics',
      );
      final secondLineStart = painter
          .getPositionForOffset(const Offset(0, 30))
          .offset;
      expect(
        _p03Body.substring(secondLineStart),
        'need an email.',
        reason: 'design line 2 is "need an email."',
      );
      _expectDesignWidth('P03 line 1', metrics.first.width, 349.06);
    });

    test('P04 heading advance matches the browser render', () {
      _expectDesignWidth('P04 h1', _advance(_p04H1, NestType.h1()), 280.52);
    });
  });
}
