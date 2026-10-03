// P11 · Approvals — the child's completion note (`ORCHESTRATOR_NOTES.md`
// items 1 and 4).
//
// The design's `.qn` line is not optional decoration: `design/screens/light/
// P11-approvals.png` shows “I stacked everything neatly!” under Maya's meta
// line, and the HTML gives it real geometry —
//   .appr .qn{font-weight:700;font-size:17px;line-height:24px;margin-top:10px}
// so a card WITH a quote is 172 tall (16 + 44 + 10 + 24 + 14 + 48 + 16) and
// one without is 138 — a 34 px difference the whole stack below depends on.
//
// `shared/completion_note` (now on main) added `quest_completions.kid_note`
// (schema v6) and seeds it for two of the three pending rows:
//   Maya · Empty the dishwasher → "I stacked everything neatly!"
//   Maya · Lay the table         → NULL  (no quote, no gap)
//   Leo  · Make your bed         → "I did the pillows too."
// and `_shared/completion_note_REPORT.md` fixes the rendering: `“$kidNote”`
// with U+201C / U+201D, no line at all when the note is NULL.
//
// These are the gate for that mandate: they are written against the SEEDED
// DATABASE and the rendered screen only (no compile-time dependency on the
// `Approval.kidNote` field), so they hold whichever layer carries the note.
// They FAIL while the screen still drops the note — that is the point: the
// orchestrator overruled the UI stage for exactly this, and item 4 asks the
// test stage to pin BOTH card heights.
//
// Real faces are loaded (the same `_loadBundledFonts` the geometry test uses):
// without Inter/Nunito the test fallback font is wider, lines wrap and every
// y below slides — the "uniform vertical shift" the UI VERDICT RULE forbids.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/approvals/presentation/widgets/approval_card.dart';

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

/// The [ApprovalCard] whose `.who` line is [whoLine].
Finder _cardFor(String whoLine) =>
    find.ancestor(of: find.text(whoLine), matching: find.byType(ApprovalCard));

/// Design value ±2 px (UI VERDICT RULE tolerance).
Matcher _near(double expected) => closeTo(expected, 2);

const String _dishwasher = 'Maya · Empty the dishwasher';
const String _table = 'Maya · Lay the table';
const String _bed = 'Leo · Make your bed';

/// U+201C + note + U+201D — exactly how the shared report says to render it.
const String _dishwasherQuote = '“I stacked everything neatly!”';
const String _bedQuote = '“I did the pillows too.”';

void main() {
  setUpAll(_loadBundledFonts);
  setUp(() async {
    await setUpTestScope();
  });

  Future<void> pump(WidgetTester tester) => pumpAppRoute(tester, '/approvals');

  group('P11 child quote — copy (ORCHESTRATOR_NOTES item 1)', () {
    testWidgets("the seeded notes render with the design's curly quotes", (
      tester,
    ) async {
      await pump(tester);

      // The dishwasher and the bed carry a note in the demo seed.
      expect(find.text(_dishwasherQuote), findsOneWidget);
      expect(find.text(_bedQuote), findsOneWidget);
      // Curly quotes, never straight ones or apostrophes.
      expect(_dishwasherQuote.runes, contains(0x201C));
      expect(_dishwasherQuote.runes, contains(0x201D));
      expect(_dishwasherQuote, isNot(contains('"')));

      await disposeApp(tester);
    });

    testWidgets('a NULL note renders no quote line at all', (tester) async {
      await pump(tester);

      // q-table is seeded without a note: the design's third row
      // ("Toys are all in the box.") is mock content the database has never
      // had, and DATA OVER MOCKS wins.
      expect(find.text('“Toys are all in the box.”'), findsNothing);
      expect(find.text(_table), findsOneWidget);
      // No gap either: the button row sits 14 px under `.hd`, not 14 + 34.
      final card = tester.getRect(_cardFor(_table));
      final notYet = tester.getRect(
        find.byKey(const ValueKey<String>('p11_not_yet_2')),
      );
      expect(notYet.top - card.top, _near(74));

      await disposeApp(tester);
    });
  });

  group('P11 child quote — geometry (ORCHESTRATOR_NOTES item 4)', () {
    testWidgets('quoted cards are 172 tall, the NULL card 138, tops follow', (
      tester,
    ) async {
      await pump(tester);

      // 16 + 44 (`.hd`) + 10 + 24 (`.qn`) + 14 + 48 (`.row`) + 16 = 172.
      final quoted = tester.getRect(_cardFor(_dishwasher));
      expect(quoted.height, _near(172), reason: 'card with a quote');
      final bare = tester.getRect(_cardFor(_table));
      expect(bare.height, _near(138), reason: 'card without a note');
      expect(quoted.height - bare.height, _near(34));

      // `.scroll` 0 20 16 with 16 between rows: 187, 375, 529. (The design's
      // third card lands at 563 because its third row is the illustrative
      // "Tidy your bedroom"; with the seeded data the third card is the bed,
      // which does have a quote, so 375 + 138 + 16 = 529.)
      expect(quoted.top, _near(187));
      expect(bare.top, _near(375));
      expect(
        tester.getRect(_cardFor(_bed)).top,
        _near(529),
        reason: 'two quoted cards + one bare card',
      );

      await disposeApp(tester);
    });

    testWidgets('the quote sits between `.hd` and the button row', (
      tester,
    ) async {
      await pump(tester);
      final card = tester.getRect(_cardFor(_dishwasher));

      // `.qn`: 10 px under `.hd`, 24 high, 14 px above the 48-high `.row`.
      final quote = tester.getRect(find.text(_dishwasherQuote));
      expect(quote.height, _near(24), reason: '.qn line-height 24');
      expect(quote.top, _near(card.top + 70), reason: '16 + 44 + 10');
      final approve = tester.getRect(
        find.byKey(const ValueKey<String>('p11_approve_1')),
      );
      expect(
        approve.top,
        _near(card.top + 108),
        reason: '14 px under the quote',
      );
      expect(approve.height, _near(48));
      // `.row` still ends 16 px above the card's bottom edge.
      expect(card.bottom - approve.bottom, _near(NestSpacing.s4));

      await disposeApp(tester);
    });
  });
}
