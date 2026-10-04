// K07 · Pip evolves — copy parity with the design HTML source.
//
// The design source is READ, never transcribed
// (`design/html-source/screens/K07-evolution.html`), so this file cannot drift
// into approving whatever the app happens to draw. Entities are decoded exactly
// as a browser would, which is what makes `&rsquo;` (curly, U+2019) and a
// literal `'` (straight, 0x27) distinguishable — K07 writes a LITERAL 0x27
// (verified by byte-dumping line 57), the K06-BUG-3 / K01 BUG-A precedent.
//
// Rules under test:
//   * COPY — "use the design's typographic characters exactly… compare copy
//     character-by-character with the HTML source".
//   * BALANCED HEADINGS — `.kid-title` sets `text-wrap: balance`, so the hero
//     heading must render through `NestBalancedText`.
//   * RULES §4 — "Kid screens show coins, never £".
//   * DATA OVER MOCKS — the design's literals (25 / 250 / stage 4) must never
//     be rendered: the numbers come from the seeded database.
//
// The design PNG is a STAGE-4 screen ("Pip grew into a Songbird!"), so the
// on-screen comparison sets the child's `pip_stage` to 4 — the DB remains the
// source of the numbers, and `Seed.demo`'s own stage-3 copy is asserted in
// `pip_evolution_view_test.dart`.
//
// Plain `test` (not `testWidgets`) wherever a Drift stream would be awaited:
// the fake-async zone never completes such an await. Every widget test ends
// with `disposeApp` INSIDE the body (RULES §7.1).

import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/design_system/design_system.dart' hide PipStage;
import 'package:nestling/features/pip/presentation/widgets/pip_evolution_copy.dart';

import '../../test_scope.dart';

/// Browser entity decoding, in the order a browser applies it (`&amp;` last).
const Map<String, String> _entities = <String, String>{
  '&ndash;': '–',
  '&mdash;': '—',
  '&rsquo;': '’',
  '&lsquo;': '‘',
  '&ldquo;': '“',
  '&rdquo;': '”',
  '&hellip;': '…',
  '&nbsp;': ' ',
  '&middot;': '·',
  '&amp;': '&',
  '&quot;': '"',
  '&lt;': '<',
  '&gt;': '>',
};

String _decode(String raw) {
  var out = raw;
  for (final entry in _entities.entries) {
    out = out.replaceAll(entry.key, entry.value);
  }
  return out;
}

/// Locates the design source by walking up from the package root, so the test
/// works no matter where `flutter test` is invoked from.
File _designSource() {
  var dir = Directory.current.absolute;
  for (var depth = 0; depth < 5; depth++) {
    final candidate = File(
      '${dir.path}/design/html-source/screens/K07-evolution.html',
    );
    if (candidate.existsSync()) return candidate;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError(
    'design/html-source/screens/K07-evolution.html not found above '
    '${Directory.current.path}',
  );
}

late String _html;

/// The single capture group of [pattern], entity-decoded.
String _one(RegExp pattern) {
  final match = pattern.firstMatch(_html);
  if (match == null) {
    throw StateError('no match for $pattern in the K07 design source');
  }
  return _decode(match.group(1)!.trim());
}

/// Every capture group of [pattern], entity-decoded, in source order.
List<String> _all(RegExp pattern) =>
    pattern.allMatches(_html).map((m) => _decode(m.group(1)!.trim())).toList();

/// The stage the K07 design source was drawn at: `<img class="k7-old" …
// pip-stage-3.svg>` next to `pip-stage-4.svg`, with the hero
/// "Pip grew into a Songbird!".
const int _designStage = 4;

void main() {
  late AppDatabase db;

  setUpAll(() {
    _html = _designSource().readAsStringSync();
  });

  setUp(() async {
    db = await setUpTestScope();
  });

  /// Pumps the screen with the child at the design's stage, so the DB-driven
  /// copy can be compared with the design's bytes.
  Future<void> pumpAtDesignStage(WidgetTester tester) async {
    await tester.runAsync(() async {
      await (db.update(db.children)..where((c) => c.id.equals('maya'))).write(
        const ChildrenCompanion(pipStage: Value(_designStage)),
      );
    });
    await pumpAppRoute(tester, '/pip-evolution');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  test('the design source is the one this file reads', () {
    expect(_html, contains('<h1 class="kid-title k7-hero">'));
    expect(_html, contains('k7-stats'));
  });

  test('the design source writes a LITERAL ASCII apostrophe in Pip’s line', () {
    // The COPY rule's oracle: the byte in the source, not a rendering of it.
    final speech = _one(RegExp('<span class="speech">([^<]*)</span>'));
    final apostrophe = speech.indexOf("'");
    expect(apostrophe, greaterThanOrEqualTo(0));
    expect(
      speech.codeUnitAt(apostrophe),
      0x27,
      reason: 'the design byte is straight, not U+2019',
    );
    expect(speech, isNot(contains('&rsquo;')));
    expect(speech, isNot(contains('’')));
  });

  group('the design source and the app agree on every visible string', () {
    testWidgets('the hero heading is the design byte at the design stage', (
      tester,
    ) async {
      // `<h1 class="kid-title k7-hero">Pip grew into a Songbird!</h1>`
      final hero = _one(RegExp('<h1 class="kid-title k7-hero">([^<]*)</h1>'));
      expect(hero, 'Pip grew into a Songbird!');

      await pumpAtDesignStage(tester);
      expect(find.text(hero), findsOneWidget);
      expect(find.text('Pip grew into a Songbird!'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('the CTA is the design button label', (tester) async {
      // `<button class="btn-kid lilac" type="button">Meet Songbird Pip</button>`
      final cta = _one(
        RegExp('<button class="btn-kid lilac" type="button">([^<]*)</button>'),
      );
      expect(cta, 'Meet Songbird Pip');

      await pumpAtDesignStage(tester);
      expect(find.text(cta), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('the speech bubble is the design byte at the design stage', (
      tester,
    ) async {
      final speech = _one(RegExp('<span class="speech">([^<]*)</span>'));
      expect(speech, "Hear that? That is Pip's new song!");

      await pumpAtDesignStage(tester);
      expect(find.text(speech), findsOneWidget);
      // ASCII, so the curly form must be absent (the K06-BUG-3 class).
      expect(find.text('Hear that? That is Pip’s new song!'), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('the caption is the design byte', (tester) async {
      final caption = _one(
        RegExp('<p class="kcap" style="text-align:center">([^<]*)</p>'),
      );
      expect(caption, 'Pip still loves a chin scratch.');

      await pumpAtDesignStage(tester);
      expect(find.text(caption), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('the three stat labels are the design bytes, in order', (
      tester,
    ) async {
      final labels = _all(RegExp('<span>([^<]*)</span>'));
      expect(labels, <String>['quests done', 'coins grown', 'of 4 stages']);

      await pumpAtDesignStage(tester);
      for (final label in labels) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      await disposeApp(tester);
    });

    testWidgets('the sub keeps the design’s words, with the DB’s number', (
      tester,
    ) async {
      // `<p class="kid-body k7-sub">Because you helped 25 times</p>` — the
      // design's 25 is a mock; DATA OVER MOCKS makes the database correct, so
      // only the sentence around it is compared.
      final sub = _one(RegExp('<p class="kid-body k7-sub">([^<]*)</p>'));
      expect(sub, 'Because you helped 25 times');
      expect(
        sub.replaceFirst(RegExp(r'\d+'), '#'),
        'Because you helped # times',
        reason: 'the sentence shape is the design’s',
      );

      await pumpAppRoute(tester, '/pip-evolution');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Because you helped 4 times'), findsOneWidget);
      // The design's mock number must never be rendered.
      expect(find.text('Because you helped 25 times'), findsNothing);
      await disposeApp(tester);
    });
  });

  group('the copy table (1_plan.md §(a).10)', () {
    test('the hero, article and CTA for every stage', () {
      // Stage 1 is the only vowel-initial name, so it is the only `an`.
      expect(evolutionTitle(1), 'Pip grew into an Egg!');
      expect(evolutionTitle(2), 'Pip grew into a Hatchling!');
      expect(evolutionTitle(3), 'Pip grew into a Fledgling!');
      expect(evolutionTitle(4), 'Pip grew into a Songbird!');
      expect(evolutionStageArticle(1), 'an');
      expect(evolutionStageArticle(2), 'a');
      expect(evolutionStageArticle(3), 'a');
      expect(evolutionStageArticle(4), 'a');

      expect(evolutionCta(1), 'Meet Egg Pip');
      expect(evolutionCta(2), 'Meet Hatchling Pip');
      expect(evolutionCta(3), 'Meet Fledgling Pip');
      expect(evolutionCta(4), 'Meet Songbird Pip');
    });

    test('the sub is singular for exactly one helped time', () {
      expect(evolutionSub(0), 'Because you helped 0 times');
      expect(evolutionSub(1), 'Because you helped 1 time');
      expect(evolutionSub(2), 'Because you helped 2 times');
      expect(evolutionSub(25), 'Because you helped 25 times');
    });

    test('the speech line for every stage, ASCII apostrophes throughout', () {
      expect(evolutionSpeech(1), 'Shh... Pip is still growing!');
      expect(evolutionSpeech(2), 'Hello! Pip is out of the egg!');
      expect(evolutionSpeech(3), "Flap, flap! Look at Pip's wings!");
      expect(evolutionSpeech(4), "Hear that? That is Pip's new song!");
      for (var stage = 1; stage <= 4; stage++) {
        final line = evolutionSpeech(stage);
        expect(
          line.codeUnits.where((c) => c == 0x2019),
          isEmpty,
          reason: 'no curly apostrophe at stage $stage: $line',
        );
      }
    });

    test('the caption is stage-independent', () {
      expect(evolutionCaption(), 'Pip still loves a chin scratch.');
    });

    test('the a11y phrases and labels read naturally for every stage', () {
      expect(evolutionStagePhrase(1), 'an egg');
      expect(evolutionStagePhrase(2), 'a hatchling');
      expect(evolutionStagePhrase(3), 'a fledgling');
      expect(evolutionStagePhrase(4), 'a songbird');
      expect(evolutionNewPipLabel('Maya', 3), "Maya's Pip, a fledgling");
      expect(evolutionNewPipLabel('Maya', 1), "Maya's Pip, an egg");
      expect(
        evolutionStatsLabel(questsDone: 4, coinsGrown: 175, stage: 3),
        '4 quests done, 175 coins grown, stage 3 of 4',
      );
    });

    test('an out-of-range stage still reads like a stage', () {
      // The view clamps 1..4 before calling; the table must not throw if a
      // future DB row ever carries 0 or 5.
      expect(evolutionTitle(0), isNotEmpty);
      expect(evolutionTitle(9), isNotEmpty);
    });
  });

  group('BALANCED HEADINGS', () {
    testWidgets('the hero renders through NestBalancedText, and only it', (
      tester,
    ) async {
      // `.k7-hero` is `.kid-title`, which sets `text-wrap: balance`. Swapping
      // the balanced widget for a plain `Text` would leave every string and
      // rect in this file identical, so nothing else can catch it.
      await pumpAppRoute(tester, '/pip-evolution');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final balanced = tester.widgetList<NestBalancedText>(
        find.byType(NestBalancedText),
      );
      expect(balanced, hasLength(1), reason: 'only the hero is balanced');
      expect(balanced.single.text, 'Pip grew into a Fledgling!');
      // The heading keeps the shared `kidTitle` style (the plan's maxLines 4).
      expect(
        balanced.single.style.fontSize,
        NestType.kidTitle(color: const Color(0xFF000000)).fontSize,
      );
      expect(balanced.single.maxLines, 4);
      expect(balanced.single.textAlign, TextAlign.center);
      await disposeApp(tester);
    });

    testWidgets('the sub, caption and stat labels are NOT balanced headings', (
      tester,
    ) async {
      // `.h2`/`.h3`/`.body`/`.caption` must never use it (orchestrator rule).
      await pumpAppRoute(tester, '/pip-evolution');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      for (final key in <String>['k07-sub', 'k07-caption', 'k07-speech']) {
        final finder = find.byKey(Key(key));
        expect(
          find.descendant(of: finder, matching: find.byType(NestBalancedText)),
          findsNothing,
          reason: key,
        );
      }
      await disposeApp(tester);
    });
  });

  group('kid-screen money rule (RULES §4)', () {
    testWidgets('no £ appears anywhere on K07, in either theme', (
      tester,
    ) async {
      for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
        await pumpAppRoute(tester, '/pip-evolution', theme: theme);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        final texts = tester
            .widgetList<Text>(find.byType(Text))
            .map((text) => text.data)
            .whereType<String>()
            .toList();
        expect(texts, isNotEmpty);
        for (final text in texts) {
          expect(text, isNot(contains('£')), reason: 'kid money in $text');
        }
        // Nothing on the screen carries an undecoded entity either.
        for (final text in texts) {
          expect(text, isNot(contains('&')));
          expect(text, isNot(contains(';')));
        }
        await disposeApp(tester);
      }
    });

    testWidgets('the coins stat shows an integer from the database', (
      tester,
    ) async {
      await pumpAppRoute(tester, '/pip-evolution');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final number = tester.widget<Text>(
        find.byKey(const Key('k07-stat-coins')),
      );
      expect(number.data, matches(RegExp(r'^\d+$')));
      // `Seed.demo`: Maya's lifetime total is 175 coins.
      expect(number.data, '175');
      await disposeApp(tester);
    });
  });
}
