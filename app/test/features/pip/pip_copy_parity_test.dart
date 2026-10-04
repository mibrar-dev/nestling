// K06 · Pip's nest — copy parity with the design HTML source.
//
// The design source is READ, never transcribed
// (`design/html-source/screens/K06-pip.html`), so this file cannot drift into
// approving whatever the app happens to draw. Entities are decoded exactly as
// a browser would, which is what makes `&rsquo;` (curly) and a literal `'`
// (straight) distinguishable — this project uses both (P05 writes
// `&rsquo;`, K01 and K06 write a literal 0x27), so the byte in the source is
// the only honest oracle.
//
// Rule under test: COPY — "use the design's typographic characters exactly…
// compare copy character-by-character with the HTML source".
//
// FIXED in iteration 2 (K06-BUG-3): the wardrobe heading now draws the
// design's byte — `pip_nest_view.dart` renders a LITERAL ASCII apostrophe
// (U+0027), where iteration 1 drew U+2019 (`’`) on the instruction of the byte
// `1_plan.md` §1e misread as `&rsquo;`. §1e is corrected with the same edit.
// The proof below is live again (its file was edited only to drop
// `skip: true`); run it alone with:
//
//   flutter test test/features/pip/pip_copy_parity_test.dart \
//     --plain-name "K06-BUG-3"
//
// Deliberately NOT asserted here (documented, not findings):
//   * the coin prices. `.k6-item-p` says 30/60, the seed says 40/120 and the
//     DATA OVER MOCKS rule makes the database correct — the NAMES are still
//     compared.
//   * the screen-reader strings. The design's `alt` / `aria-label` are
//     replaced by richer announcements ("Pip the Fledgling, stage 3 of 4");
//     the progress label now matches the design's own aria-label
//     ("Pip is 70% of the way to Songbird", with the percentage from the
//     database): a11y copy, not visible copy.
//   * `kPipNotEnoughCoins` / `kPipNotWearable`. The design defines no copy for
//     an unaffordable buy or an owned-but-unwearable tile; both are flagged
//     for the orchestrator in `2_build.md` §5.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/design_system/components/nest_balanced_text.dart';
import 'package:nestling/features/pip/data/pip_repository_impl.dart';

import '../../test_scope.dart';

/// Browser entity decoding, in the order a browser applies it (`&amp;` last).
/// · — HTML `&middot;` (U+00B7), the title's separator.
const String _middot = '·';

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
      '${dir.path}/design/html-source/screens/K06-pip.html',
    );
    if (candidate.existsSync()) return candidate;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError(
    'design/html-source/screens/K06-pip.html not found above '
    '${Directory.current.path}',
  );
}

late String _html;

/// The single capture group of [pattern], entity-decoded.
String _one(RegExp pattern) {
  final match = pattern.firstMatch(_html);
  if (match == null) {
    throw StateError('no match for $pattern in the K06 design source');
  }
  return _decode(match.group(1)!.trim());
}

/// Every capture group of [pattern], entity-decoded, in source order.
List<String> _all(RegExp pattern) =>
    pattern.allMatches(_html).map((m) => _decode(m.group(1)!.trim())).toList();

void main() {
  setUpAll(() {
    _html = _designSource().readAsStringSync();
  });

  setUp(() async {
    await setUpTestScope();
  });

  test('the design source is the one this file reads', () {
    expect(_html, contains('<h1 class="kid-title k6-name">'));
    expect(_html, contains('k6-ward'));
  });

  testWidgets('the title, growth line and caption are the design bytes', (
    tester,
  ) async {
    await pumpAppRoute(tester, '/pip');

    // `<h1 class="kid-title k6-name">Pip &middot; Fledgling</h1>`
    expect(
      _one(RegExp('<h1 class="kid-title k6-name">([^<]*)</h1>')),
      'Pip · Fledgling',
    );
    expect(
      find.text(_one(RegExp('<h1 class="kid-title k6-name">([^<]*)</h1>'))),
      findsOneWidget,
    );

    // `<strong>Growing into a Songbird</strong>` — the design's stage-3 line.
    expect(_one(RegExp('<strong>([^<]*)</strong>')), 'Growing into a Songbird');
    expect(find.text(_one(RegExp('<strong>([^<]*)</strong>'))), findsOneWidget);

    // `<p class="kcap" …>Nothing here is a chore &mdash; …</p>`
    final caption = _one(
      RegExp('<p class="kcap" style="text-align:center">([^<]*)</p>'),
    );
    expect(caption, 'Nothing here is a chore — it is all just for fun.');
    expect(find.text(caption), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('the title renders through NestBalancedText, and only it does', (
    tester,
  ) async {
    // BALANCED HEADINGS (orchestrator rule): `.kid-title` sets
    // `text-wrap: balance`, so the title must render through
    // `NestBalancedText` — which keeps the same copy, style and maxLines and
    // breaks the lines the way the design does (no one-word orphan line).
    //
    // No other assertion in the K06 suite can see this: swapping the balanced
    // widget for a plain `Text` leaves every string, rect and measurement in
    // this file identical, and would only show up as a one-word last line in a
    // UI screenshot. `.h2`/`.h3`/`.body`/`.caption` must NOT use it.
    await pumpAppRoute(tester, '/pip');

    expect(find.byType(NestBalancedText), findsOneWidget);
    final balanced = tester.widget<NestBalancedText>(
      find.byType(NestBalancedText),
    );
    expect(balanced.text, startsWith('Pip $_middot'));
    expect(balanced.maxLines, 2, reason: "the plan's maxLines 2 for the title");
    // The title is the only balanced heading on this screen.
    expect(find.byKey(const Key('k06-section')), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('the care row labels and the Free pill are the design bytes', (
    tester,
  ) async {
    await pumpAppRoute(tester, '/pip');

    // The three `.btn-kid` blocks, first label each (the svg carries none).
    final buttons = RegExp(
      '<button class="btn-kid[^"]*"[^>]*>(.*?)</button>',
      dotAll: true,
    ).allMatches(_html).map((m) => m.group(1)!).toList();
    expect(buttons, hasLength(3));
    final labels = buttons
        .map(
          (block) => _decode(
            RegExp('<span>([^<]*)</span>').firstMatch(block)!.group(1)!,
          ),
        )
        .toList();
    expect(labels, <String>['Feed', 'Play', 'Bath']);
    for (final label in labels) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(_one(RegExp('<span class="k6-free">([^<]*)</span>')), 'Free');
    expect(find.text('Free'), findsOneWidget);
    await disposeApp(tester);
  });

  test("the repository's wardrobe names are the design's, in order", () async {
    final names = _all(RegExp('<span class="k6-item-n">([^<]*)</span>'));
    expect(names, <String>['Scarf', 'Sun hat', 'Wellies', 'Crown']);

    // The repository's mapping (its own string table) must reproduce them, in
    // source order — never alphabetical, whatever the DB row order is. Plain
    // `test`, not `testWidgets`: awaiting a Drift stream inside the
    // fake-async zone never completes.
    final repo = PipRepositoryImpl(db: GetIt.instance<AppDatabase>());
    final nest = await repo.watchNest().first;
    expect(nest!.items.map((item) => item.title).toList(), names);
  });

  testWidgets('the wardrobe strip renders those names on screen', (
    tester,
  ) async {
    final names = _all(RegExp('<span class="k6-item-n">([^<]*)</span>'));
    await pumpAppRoute(tester, '/pip');

    for (final name in names) {
      expect(find.text(name), findsOneWidget, reason: name);
    }
    // `.k6-item-p.on` — the owned state word.
    // The design marks two tiles `.on` (Scarf and Sun hat).
    final owned = _all(RegExp('<span class="k6-item-p on">([^<]*)</span>'));
    expect(owned, <String>['Owned', 'Owned']);
    expect(find.text(owned.first), findsNWidgets(2));
    await disposeApp(tester);
  });

  testWidgets('the icon-button labels are the design aria-labels', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpAppRoute(tester, '/pip');

    expect(
      _one(RegExp('<button class="nav-back lg"[^>]*aria-label="([^"]*)"')),
      'Back',
    );
    expect(
      _one(RegExp('<button class="lock-btn lg"[^>]*aria-label="([^"]*)"')),
      'Grown-ups',
    );
    expect(find.bySemanticsLabel('Back'), findsOneWidget);
    expect(find.bySemanticsLabel('Grown-ups'), findsOneWidget);
    semantics.dispose();
    await disposeApp(tester);
  });

  testWidgets('K06-BUG-3: the wardrobe heading is the design byte', (
    tester,
  ) async {
    // `.k6-sec` in the design source, decoded: a LITERAL straight apostrophe
    // (0x27), not `&rsquo;`.
    final heading = _one(RegExp('<div class="k6-sec">([^<]*)</div>'));
    // `Pip` + apostrophe: index 3.
    expect(heading.codeUnitAt(3), 0x27, reason: 'the design byte is straight');

    await pumpAppRoute(tester, '/pip');
    // Counted BEFORE the assertion so the app is always drained, even while
    // this test is red (RULES §7.1: `disposeApp` must run inside the body).
    final matches = find.text(heading).evaluate().length;
    await disposeApp(tester);

    // Fails until the view draws U+0027 at the `.k6-sec` heading
    // (K06-BUG-3 — fixed in iteration 2).
    expect(matches, 1, reason: 'the heading must be the design byte');
  });

  testWidgets('every rendered string has no stray ASCII quote or entity', (
    tester,
  ) async {
    await pumpAppRoute(tester, '/pip');

    // A cheap global net for the same class of defect: nothing on screen may
    // still carry an undecoded entity, and no apostrophe in kid copy may be
    // ASCII while the design wrote an entity (or vice versa) — the heading is
    // the only known case and is pinned above.
    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .whereType<String>()
        .toList();
    expect(texts, isNotEmpty);
    for (final text in texts) {
      expect(text, isNot(contains('&')), reason: 'undecoded entity: $text');
      expect(text, isNot(contains(';')), reason: 'undecoded entity: $text');
    }
    await disposeApp(tester);
  });
}
