// P12 payout-day math — pure next-payout tests (no database).
//
// The demo story day is Sat 3 Oct 2026 with `payoutDay = 6` (Saturday), so a
// Saturday "today" pays today and the following Monday pays Sat 10 Oct.

import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/family_time.dart';
import 'package:nestling/features/pocket_money/domain/next_payout.dart';

void main() {
  group('nextPayoutDayUtc', () {
    test('Saturday stays on Saturday 3 Oct', () {
      final next = nextPayoutDayUtc(
        payoutWeekday: 6,
        nowUtc: DateTime.utc(2026, 10, 3, 8),
        zoneId: 'Europe/London',
      );

      expect(next.isUtc, isTrue);
      final local = toFamilyZone(next, 'Europe/London');
      expect(local.weekday, 6);
      expect((local.month, local.day), (10, 3));
    });

    test('Monday 5 Oct rolls forward to Saturday 10 Oct', () {
      final next = nextPayoutDayUtc(
        payoutWeekday: 6,
        nowUtc: DateTime.utc(2026, 10, 5, 8),
        zoneId: 'Europe/London',
      );

      final local = toFamilyZone(next, 'Europe/London');
      expect(local.weekday, 6);
      expect((local.month, local.day), (10, 10));
    });

    test('Sunday 4 Oct also pays on Saturday 10 Oct', () {
      final next = nextPayoutDayUtc(
        payoutWeekday: 6,
        nowUtc: DateTime.utc(2026, 10, 4, 8),
        zoneId: 'Europe/London',
      );

      final local = toFamilyZone(next, 'Europe/London');
      expect((local.month, local.day), (10, 10));
    });

    test('rejects weekdays outside 1..7', () {
      expect(
        () => nextPayoutDayUtc(
          payoutWeekday: 0,
          nowUtc: DateTime.utc(2026, 10, 3, 8),
          zoneId: 'Europe/London',
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => nextPayoutDayUtc(
          payoutWeekday: 8,
          nowUtc: DateTime.utc(2026, 10, 3, 8),
          zoneId: 'Europe/London',
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('payoutLabel', () {
    test('anchor Saturday renders "Sat 3 Oct"', () {
      expect(
        payoutLabel(
          payoutWeekday: 6,
          nowUtc: DateTime.utc(2026, 10, 3, 8),
          zoneId: 'Europe/London',
        ),
        'Sat 3 Oct',
      );
    });

    test('Monday renders "Sat 10 Oct"', () {
      expect(
        payoutLabel(
          payoutWeekday: 6,
          nowUtc: DateTime.utc(2026, 10, 5, 8),
          zoneId: 'Europe/London',
        ),
        'Sat 10 Oct',
      );
    });

    test('a Dubai-zone family still formats in its stored zone', () {
      // Monday 00:30 UTC is already Monday morning in Asia/Dubai (UTC+4).
      expect(
        payoutLabel(
          payoutWeekday: 6,
          nowUtc: DateTime.utc(2026, 10, 5, 0, 30),
          zoneId: 'Asia/Dubai',
        ),
        'Sat 10 Oct',
      );
    });
  });
}
