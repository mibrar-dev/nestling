// K11 · My badges — copy-branch unit tests (stage 3, iteration 2).
//
// `BadgesCopy.subtitle` and `HappyWeekCopy.why` select the screen's lines
// from database counts the widget tests only ever show at 4/3/1/0. This file
// pins every remaining branch without touching the database: the number words
// One…Nine, the singular `one`/`day`, the digit fallback past nine, and the
// invented zero lines (`1_plan.md` §c–d flags those as kid voice).
//
// Pure unit tests: no pump, no `disposeApp`, no clock, no `google_fonts`.

import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/features/badges/presentation/views/badges_view.dart';
import 'package:nestling/features/badges/presentation/widgets/happy_week_card.dart';

void main() {
  group('BadgesCopy.subtitle (K11)', () {
    test('zero earned uses the invented zero line', () {
      expect(
        BadgesCopy.subtitle(0),
        'No shiny ones yet. Finish a quest to earn your first!',
      );
    });

    test('a negative count reads as the zero line, never "-1 shiny"', () {
      expect(
        BadgesCopy.subtitle(-2),
        'No shiny ones yet. Finish a quest to earn your first!',
      );
    });

    test('one earned is singular with a capitalised word', () {
      expect(
        BadgesCopy.subtitle(1),
        'One shiny one already. Pip is very impressed.',
      );
    });

    test('two through nine use the number words', () {
      expect(
        BadgesCopy.subtitle(2),
        'Two shiny ones already. Pip is very impressed.',
      );
      expect(
        BadgesCopy.subtitle(3),
        'Three shiny ones already. Pip is very impressed.',
      );
      expect(
        BadgesCopy.subtitle(4),
        'Four shiny ones already. Pip is very impressed.',
      );
      expect(
        BadgesCopy.subtitle(5),
        'Five shiny ones already. Pip is very impressed.',
      );
      expect(
        BadgesCopy.subtitle(9),
        'Nine shiny ones already. Pip is very impressed.',
      );
    });

    test('past nine the count renders as digits', () {
      expect(
        BadgesCopy.subtitle(10),
        '10 shiny ones already. Pip is very impressed.',
      );
      expect(
        BadgesCopy.subtitle(12),
        '12 shiny ones already. Pip is very impressed.',
      );
    });
  });

  group('HappyWeekCopy.why (K11)', () {
    test('zero uses the invented positive line (no loss-aversion)', () {
      expect(HappyWeekCopy.why(0), 'Let’s make today a happy day!');
    });

    test('one happy day is singular', () {
      expect(
        HappyWeekCopy.why(1),
        '1 happy day this week — Pip hasn’t stopped singing.',
      );
    });

    test('two through seven count up', () {
      for (var n = 2; n <= 7; n++) {
        expect(
          HappyWeekCopy.why(n),
          '$n happy days this week — Pip hasn’t stopped singing.',
          reason: 'n = $n',
        );
      }
    });

    test('the em dash and curly apostrophe are the design characters', () {
      final line = HappyWeekCopy.why(4);
      expect(line, contains('—'));
      expect(line, isNot(contains('-')));
      expect(line, contains('’'));
      expect(line, isNot(contains("'")));
    });
  });
}
