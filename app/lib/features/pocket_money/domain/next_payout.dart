// P12 payout-day math (pure, no widgets, no database).
//
// The upcoming [payoutWeekday] (DateTime Mon=1..Sun=7; 6 = Saturday) in the
// family zone, today when it matches. All zone logic goes through
// `family_time.dart` — never a fixed offset, never the legacy London-only
// shims.

import 'package:nestling/core/data/family_time.dart';
import 'package:timezone/timezone.dart' as tz;

/// UTC instant of 00:00 on the upcoming [payoutWeekday] in [zoneId] (today
/// when the zone weekday already matches). Always a plain UTC [DateTime].
DateTime nextPayoutDayUtc({
  required int payoutWeekday,
  required DateTime nowUtc,
  required String zoneId,
}) {
  assert(
    payoutWeekday >= 1 && payoutWeekday <= 7,
    'P12 payout weekday must be 1..7, got $payoutWeekday',
  );
  // The assert above is stripped in release/profile builds, so enforce the
  // invariant there too (same pattern as the P06 setters).
  if (payoutWeekday < 1 || payoutWeekday > 7) {
    throw ArgumentError.value(
      payoutWeekday,
      'payoutWeekday',
      'P12 payout weekday must be 1..7 (Mon..Sun)',
    );
  }
  final zone = normalizeZoneId(zoneId);
  final local = toFamilyZone(nowUtc, zone);
  final delta = (payoutWeekday - local.weekday) % 7;
  // Midnight arithmetic in the zone itself (not `+ Duration(days:)` on the
  // UTC instant) so a DST transition between now and payout cannot shift the
  // label by a day. `TZDateTime` normalises month overflow like `DateTime`.
  final target = tz.TZDateTime(
    local.location,
    local.year,
    local.month,
    local.day + delta,
  );
  return DateTime.fromMillisecondsSinceEpoch(
    target.millisecondsSinceEpoch,
    isUtc: true,
  );
}

/// `Sat 3 Oct` for the upcoming [payoutWeekday] rendered in [zoneId].
String payoutLabel({
  required int payoutWeekday,
  required DateTime nowUtc,
  required String zoneId,
}) {
  final zone = normalizeZoneId(zoneId);
  return formatDay(
    nextPayoutDayUtc(
      payoutWeekday: payoutWeekday,
      nowUtc: nowUtc,
      zoneId: zone,
    ),
    zone,
  );
}
