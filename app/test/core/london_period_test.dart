// "Done today / this week" boundaries in Europe/London, including BST.

import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/london_time.dart';

void main() {
  test('London day starts at 23:00 UTC during BST', () {
    // Fri 2 Oct 2026 12:00 UTC is 13:00 BST.
    expect(
      londonDayStartUtc(DateTime.utc(2026, 10, 2, 12)),
      DateTime.utc(2026, 10, 1, 23),
    );
  });

  test('London day starts at 00:00 UTC in winter', () {
    expect(
      londonDayStartUtc(DateTime.utc(2026, 12, 2, 12)),
      DateTime.utc(2026, 12, 2),
    );
  });

  test('a 23:30 UTC instant in BST belongs to the next London day', () {
    expect(
      londonDayStartUtc(DateTime.utc(2026, 10, 2, 23, 30)),
      DateTime.utc(2026, 10, 2, 23),
    );
  });

  test('London week starts Monday 00:00 London time', () {
    // Sat 3 Oct 2026 (BST) → Mon 28 Sep 00:00 BST = Sun 27 Sep 23:00 UTC.
    expect(
      londonWeekStartUtc(DateTime.utc(2026, 10, 3, 9)),
      DateTime.utc(2026, 9, 27, 23),
    );
  });

  test('daily completions expire at London midnight, weekly on Monday', () {
    final now = DateTime.utc(2026, 10, 3, 9); // Sat 10:00 BST
    final yesterday = DateTime.utc(2026, 10, 2, 17);
    final thisMorning = DateTime.utc(2026, 10, 3, 6);
    expect(countsForCurrentPeriod('daily', yesterday, now), isFalse);
    expect(countsForCurrentPeriod('daily', thisMorning, now), isTrue);
    expect(countsForCurrentPeriod('weekly', yesterday, now), isTrue);
    expect(
      countsForCurrentPeriod('weekly', DateTime.utc(2026, 9, 27, 12), now),
      isFalse,
    );
    expect(countsForCurrentPeriod('once', DateTime.utc(2020), now), isTrue);
  });
}
