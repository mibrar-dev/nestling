// P11 · Approvals — card timestamp helpers.
//
// The card's `.tm` line is `<day> <time> · <coins>` (HTML `.appr .tm`,
// 13/18 ink-2), e.g. `Today 8:12am · 15 coins`.
//
// Storage contract (`family_time.dart`): the instant is UTC, the zone that was
// in force when the completion was written rides along as `createdAtTz`, and
// history renders in that stored zone. "Today" / "Yesterday" are relative to
// *now*, compared as wall-clock calendar days **in the stored zone** — a
// completion made at 23:50 London is still "Today" when the family reads the
// inbox at 00:10 London.
//
// `familyZoneId` is optional (P11 plan §3): the bloc streams the pending rows
// only, so the card labels render in the stored zone. Passing the family zone
// here names the zone in the label when the family has since moved
// (`Sat 3 Oct (Dubai)`), which is what `formatDay`/`formatTime` do.

import 'package:nestling/core/data/family_time.dart';

/// `Today` / `Yesterday` / `Sat 21 Sep` for a completion at
/// [createdAtUtc], rendered in [storedZoneId] and compared against [nowUtc].
///
/// Both instants are converted to the stored zone first, so the day boundary
/// is the family's midnight, not UTC's.
String approvalDayLabel({
  required DateTime createdAtUtc,
  required String storedZoneId,
  required DateTime nowUtc,
  String? familyZoneId,
}) {
  final stored = normalizeZoneId(storedZoneId);
  final created = toFamilyZone(createdAtUtc, stored);
  final now = toFamilyZone(nowUtc, stored);
  // Wall-clock dates only: two `DateTime(y, m, d)` values built the same way
  // differ by whole days, which keeps the test correct across a DST change.
  final createdDay = DateTime(created.year, created.month, created.day);
  final today = DateTime(now.year, now.month, now.day);
  final daysApart = today.difference(createdDay).inDays;
  if (daysApart == 0) return 'Today';
  if (daysApart == 1) return 'Yesterday';
  return formatDay(createdAtUtc, storedZoneId, familyZoneId: familyZoneId);
}

/// `8:12am` for a completion at [createdAtUtc], rendered in [storedZoneId].
///
/// Delegates to [formatTime] so the noon/midnight edges (`12:05pm`,
/// `12:00am`) and the optional zone suffix stay in one place.
String approvalTimeLabel({
  required DateTime createdAtUtc,
  required String storedZoneId,
  String? familyZoneId,
}) {
  return formatTime(createdAtUtc, storedZoneId, familyZoneId: familyZoneId);
}
