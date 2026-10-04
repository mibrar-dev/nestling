// K01 · Who's playing? — copy parity with the design HTML source.
//
// The design source is READ, never transcribed
// (`design/html-source/screens/K01-profile-picker.html`), so this file can
// never drift into approving whatever the app happens to draw. Entities are
// decoded exactly as a browser would, which is what makes `&rsquo;` (curly)
// and a literal `'` (straight) distinguishable: this project uses both
// (P05-add-children.html writes `&rsquo;`), so the byte in the source is the
// only honest oracle.
//
// Rule under test: COPY — "use the design's typographic characters exactly…
// compare copy character-by-character with the HTML source".
//
// KNOWN RED (K01-BUG-5, see docs/screens/K01/3_test.md): the title test below
// fails because `profile_picker_view.dart:210` draws U+2019 where the design
// source and both design PNGs use the straight ASCII apostrophe U+0027. The
// test is left RED on purpose — it flips green the moment the one-character
// fix lands, with no edit to this file.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_child.dart';
import 'package:nestling/features/kid_home/presentation/widgets/profile_tile.dart';

import '../../test_scope.dart';

const Map<String, String> _entities = <String, String>{
  '&ndash;': '–',
  '&mdash;': '—',
  '&rsquo;': '’',
  '&lsquo;': '‘',
  '&ldquo;': '“',
  '&rdquo;': '”',
  '&hellip;': '…',
  '&nbsp;': ' ',
  '&middot;': '·',
  '&amp;': '&',
  '&quot;': '"',
  '&lt;': '<',
  '&gt;': '>',
};

/// Locates the design source by walking up from the package root, so the
/// test works no matter where `flutter test` is invoked from.
File _designSource() {
  var dir = Directory.current.absolute;
  for (var depth = 0; depth < 5; depth++) {
    final candidate = File(
      '${dir.path}/design/html-source/screens/K01-profile-picker.html',
    );
    if (candidate.existsSync()) return candidate;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError(
    'design/html-source/screens/K01-profile-picker.html not found above '
    '${Directory.current.path}',
  );
}

String _decode(String raw) {
  var out = raw;
  _entities.forEach((entity, glyph) {
    out = out.replaceAll(entity, glyph);
  });
  // Collapse source-line wrapping, but never touch the non-breaking space.
  return out.replaceAll(RegExp('[ \t\r\n]+'), ' ').trim();
}

/// Guards against a vacuous pass: an empty or markup-laden capture would let
/// `find.text(...)` succeed for the wrong reason.
String _checked(String captured, String pattern) {
  expect(captured.length, greaterThan(2), reason: 'empty capture: $pattern');
  expect(captured, isNot(contains('<')), reason: 'markup leaked: $pattern');
  return captured;
}

String _capture(String html, String pattern) {
  final match = RegExp(pattern, dotAll: true).firstMatch(html);
  expect(
    match,
    isNotNull,
    reason: 'the design source no longer matches $pattern',
  );
  return _checked(_decode(match!.group(1)!), pattern);
}

List<String> _captureAll(String html, String pattern) =>
    RegExp(pattern, dotAll: true)
        .allMatches(html)
        .map((m) => _checked(_decode(m.group(1)!), pattern))
        .toList(growable: false);

/// Every string the picker actually draws, in paint order.
List<String> _drawnText(WidgetTester tester) => <String>[
  for (final widget in tester.widgetList<Text>(find.byType(Text)))
    if (widget.data != null) widget.data!,
];

void main() {
  late String html;

  setUpAll(() {
    html = _designSource().readAsStringSync();
  });

  setUp(() async {
    await setUpTestScope();
  });

  group('K01 — the design source is the oracle', () {
    test('this screen writes a straight ASCII apostrophe, not an entity', () {
      // Guards the oracle itself: the K01 h1 holds a raw 0x27, which renders
      // as the STRAIGHT tick visible in both design PNGs. A source that wrote
      // `&rsquo;` would mean curly — flip this test and the title test
      // together.
      expect(html, contains(">Who's playing?<"), reason: 'straight U+0027');
      expect(
        html,
        isNot(contains('&rsquo;')),
        reason:
            'the K01 source now uses a curly entity; the title expectation '
            'must change with it',
      );
      expect(_capture(html, '>([^<>]*playing[?])<'), "Who's playing?");
    });

    test('the source pins the sizes this screen transcribes', () {
      // Guards the numbers the geometry tests rely on: if the design CSS
      // changes, these fail loudly instead of the tests drifting.
      expect(html, contains('padding: 0 20px 4px')); // .k1-top
      expect(html, contains('.k1-tiles { display: flex; gap: 16px;')); // gap 16
      expect(html, contains('min-height: 336px')); // .k1-tile
      expect(html, contains('border: 3px solid var(--ink)')); // tile border
      expect(html, contains('.k1-pet { width: 132px; height: 132px;'));
      expect(html, contains('.k1-pet img { width: 112px; height: 112px;'));
      expect(html, contains('font-size: 28px; line-height: 32px')); // name
      expect(html, contains('font-size: 15px; line-height: 20px')); // age
      expect(html, contains('border-radius: 18px')); // lock, large
      expect(html, contains('.kcap')); // 15/20 caption
    });

    test('the shared type scale owns every K01 size', () {
      // Never hard-code sizes in a screen: prove the tokens say so.
      expect(NestType.kidTitle().fontSize, 28);
      expect(NestType.kidTitle().height, 34 / 28);
      expect(NestType.kidBody().fontSize, 18);
      expect(NestType.kidCaption().fontSize, 15);
      expect(NestType.kidCaption().height, 20 / 15);
      expect(NestType.h1().fontSize, 28, reason: '.k1-name uses h1 at 28/32');
      expect(NestType.kidTitle().letterSpacing, 0);
      expect(NestSpacing.padSide, 20);
    });

    test('tile keys are stable per child id (tests address tiles by them)', () {
      expect(
        ProfileTile.keyFor(_probe('maya')),
        const ValueKey<String>('k01-tile-maya'),
      );
      expect(
        ProfileTile.keyFor(_probe('leo')),
        const ValueKey<String>('k01-tile-leo'),
      );
    });
  });

  group('K01 — copy is the design copy, character by character', () {
    testWidgets('the title matches the source byte for byte', (tester) async {
      final source = _capture(html, '<h1[^>]*>([^<>]*)<');
      await pumpAppRoute(tester, '/who-is-playing');
      expect(
        find.text(source),
        findsOneWidget,
        reason:
            'K01-BUG-5: the title must be the HTML source copy, byte for byte '
            '(U+0027), not the curly U+2019 the view currently draws',
      );
      final drawn = tester.widget<Text>(find.text(source)).data!;
      expect(drawn.codeUnits, source.codeUnits);
      expect(drawn, isNot(contains('’')), reason: 'no curly apostrophe');
      await disposeApp(tester);
    });

    testWidgets('the sub-headline is the source copy', (tester) async {
      final source = _capture(html, '<p class="kid-body k1-sub">([^<>]*)<');
      expect(source, 'Tap your face to start');
      await pumpAppRoute(tester, '/who-is-playing');
      expect(find.text(source), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('both tile names and age lines are the source copy', (
      tester,
    ) async {
      final names = _captureAll(html, '<span class="k1-name">([^<>]*)<');
      final ages = _captureAll(html, '<span class="k1-age">([^<>]*)<');
      expect(names, <String>['Maya', 'Leo'], reason: 'creation order');
      expect(ages, <String>[
        'Age 7–9',
        'Age 4–6',
      ], reason: '&ndash; decodes to the en dash U+2013, not a hyphen');
      await pumpAppRoute(tester, '/who-is-playing');
      for (final line in <String>[...names, ...ages]) {
        expect(find.text(line), findsOneWidget, reason: line);
      }
      await disposeApp(tester);
    });

    testWidgets('the grown-ups caption is the source copy, ASCII hyphen', (
      tester,
    ) async {
      final source = _capture(html, '<p class="kcap k1-cap">([^<>]*)<');
      expect(source, 'Grown-ups: tap the lock to get back to your dashboard.');
      expect(source, contains('Grown-ups:'), reason: 'ASCII hyphen, U+002D');
      await pumpAppRoute(tester, '/who-is-playing');
      expect(find.text(source), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('the lock aria-label is the source copy', (tester) async {
      final source = _capture(
        html,
        'class="lock-btn lg"[^>]*aria-label="([^"]*)"',
      );
      expect(source, 'Grown-ups');
      await pumpAppRoute(tester, '/who-is-playing');
      expect(find.bySemanticsLabel(source), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('the pet alt text drives the pet semantics labels', (
      tester,
    ) async {
      final alts = _captureAll(
        html,
        '<span class="k1-pet[^"]*"><img[^>]*alt="([^"]*)"',
      );
      expect(alts, <String>['Pip the Fledgling', 'Pip the Hatchling']);
      await pumpAppRoute(tester, '/who-is-playing');
      for (final alt in alts) {
        expect(
          find.descendant(
            of: find.byType(ProfileTile),
            matching: find.bySemanticsLabel(alt),
          ),
          findsOneWidget,
          reason: alt,
        );
      }
      await disposeApp(tester);
    });

    testWidgets('no drawn string carries a curly apostrophe', (tester) async {
      await pumpAppRoute(tester, '/who-is-playing');
      final lines = _drawnText(tester);
      expect(lines, isNotEmpty, reason: 'the screen does draw text');
      for (final line in lines) {
        expect(
          line.contains('’'),
          isFalse,
          reason: '“$line” has a curly apostrophe; K01’s source is straight',
        );
      }
      await disposeApp(tester);
    });

    testWidgets('every drawn string keeps letterSpacing 0', (tester) async {
      // LETTER SPACING rule: NestType defaults to 0 and K01's CSS sets no
      // tracking, so no call site may add Material tracking back.
      await pumpAppRoute(tester, '/who-is-playing');
      for (final text in tester.widgetList<Text>(find.byType(Text))) {
        final spacing = text.style?.letterSpacing;
        if (spacing == null) continue;
        expect(spacing, 0, reason: '“${text.data}” must not add tracking');
      }
      await disposeApp(tester);
    });

    testWidgets('the picker never shows money, coins or dates', (tester) async {
      await pumpAppRoute(tester, '/who-is-playing');
      for (final line in _drawnText(tester)) {
        expect(line.contains('£'), isFalse, reason: line);
        expect(line.toLowerCase().contains('coin'), isFalse, reason: line);
        expect(RegExp(r'\d{4}').hasMatch(line), isFalse, reason: line);
      }
      await disposeApp(tester);
    });
  });
}

/// A throwaway child, only to address a tile by its key.
KidChild _probe(String id) => KidChild(
  id: id,
  nickname: id,
  ageBand: '',
  avatarColour: 'lilac',
  coins: 0,
  pipStyle: 'mochi',
  pipSkin: 'sunny',
  pipAccessory: 'none',
  pipStage: 1,
  happiness: 1,
  pinSet: false,
);
