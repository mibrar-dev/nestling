// Nestling — family time-zone helpers (IANA zone ids + UTC instants).
//
// Storage contract (owner-approved):
// * Every event instant is stored as a UTC [DateTime] plus the IANA zone id
//   that was in force when it was written (`…_tz`, e.g. `createdAtTz`).
// * Calendar rules (daily/weekly periods, payout weekday, `dueTimeLocal`
//   `HH:MM`) are floating local rules evaluated in `families.time_zone`.
// * History renders in its stored zone; "today / this week / payout day /
//   due" use the CURRENT family zone.
//
// All conversions use the `timezone` package tz database (`latest_10y`),
// initialised once at startup via [initFamilyTime] (see `main.dart`). The
// functions below lazily ensure initialisation too, so unit tests that never
// boot the app still work.

import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Default family zone for new installs and seeded data (London, UK app).
const String defaultFamilyZoneId = 'Europe/London';

/// Final fallback when no usable zone id exists anywhere.
const String utcZoneId = 'UTC';

bool _initialised = false;

/// Loads the tz database (`latest_10y`). Safe to call more than once.
void initFamilyTime() {
  if (_initialised) return;
  tzdata.initializeTimeZones();
  _initialised = true;
}

void _ensureInit() => initFamilyTime();

/// True when [id] names a zone in the tz database.
bool isKnownZoneId(String id) {
  _ensureInit();
  try {
    tz.getLocation(id);
    return true;
  } on Object catch (_) {
    return false;
  }
}

/// Validates [id], returning it unchanged when known. Otherwise returns
/// [fallback] when that is known, else `'Europe/London'`, else `'UTC'`.
/// Never throws — unknown zone ids must fall back safely.
String normalizeZoneId(String? id, {String fallback = defaultFamilyZoneId}) {
  _ensureInit();
  if (id != null && id.isNotEmpty) {
    try {
      tz.getLocation(id);
      return id;
    } on Object catch (_) {
      // Fall through to the fallback chain.
    }
  }
  if (fallback.isNotEmpty) {
    try {
      tz.getLocation(fallback);
      return fallback;
    } on Object catch (_) {
      // Fall through.
    }
  }
  for (final candidate in <String>[defaultFamilyZoneId, utcZoneId]) {
    try {
      tz.getLocation(candidate);
      return candidate;
    } on Object catch (_) {
      // Keep falling back.
    }
  }
  // The tz database always ships UTC; this is unreachable in practice.
  return utcZoneId;
}

/// Picks the zone id to stamp on a new row: the writer's device zone when
/// valid, else the family zone, else `'Europe/London'`, else `'UTC'`.
String resolveWriteZone({String? deviceZone, String? familyZone}) {
  _ensureInit();
  for (final candidate in <String?>[deviceZone, familyZone]) {
    if (candidate != null && candidate.isNotEmpty) {
      try {
        tz.getLocation(candidate);
        return candidate;
      } on Object catch (_) {
        // Try the next fallback.
      }
    }
  }
  return defaultFamilyZoneId;
}

/// Converts a UTC instant to wall-clock time in [zoneId] (unknown ids fall
/// back via [normalizeZoneId]). Handles DST transitions (BST gaps and the
/// ambiguous autumn hour) via the tz database.
tz.TZDateTime toFamilyZone(DateTime utc, String zoneId) {
  _ensureInit();
  final zone = normalizeZoneId(zoneId);
  return tz.TZDateTime.from(utc.toUtc(), tz.getLocation(zone));
}

/// UTC instant of 00:00 in [zoneId] on the zone day containing [nowUtc].
/// Always a plain UTC [DateTime] (never a `TZDateTime`).
DateTime dayStartUtc(String zoneId, DateTime nowUtc) {
  _ensureInit();
  final location = tz.getLocation(normalizeZoneId(zoneId));
  final now = tz.TZDateTime.from(nowUtc.toUtc(), location);
  final midnight = tz.TZDateTime(location, now.year, now.month, now.day);
  return DateTime.fromMillisecondsSinceEpoch(
    midnight.millisecondsSinceEpoch,
    isUtc: true,
  );
}

/// UTC instant of Monday 00:00 in [zoneId] for the week containing [nowUtc].
/// Always a plain UTC [DateTime] (never a `TZDateTime`).
DateTime weekStartUtc(String zoneId, DateTime nowUtc) {
  _ensureInit();
  final location = tz.getLocation(normalizeZoneId(zoneId));
  final now = tz.TZDateTime.from(nowUtc.toUtc(), location);
  final monday = tz.TZDateTime(
    location,
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: now.weekday - 1));
  return DateTime.fromMillisecondsSinceEpoch(
    monday.millisecondsSinceEpoch,
    isUtc: true,
  );
}

/// Whether a completion at [completedAtUtc] still counts for a quest with
/// [repeatRule] at [nowUtc], evaluated in [zoneId]: daily → same zone day,
/// weekly → same zone week (Mon–Sun), once (or anything else) → forever.
bool countsForCurrentPeriod(
  String repeatRule,
  DateTime completedAtUtc,
  DateTime nowUtc,
  String zoneId,
) {
  final start = switch (repeatRule) {
    'daily' => dayStartUtc(zoneId, nowUtc),
    'weekly' => weekStartUtc(zoneId, nowUtc),
    _ => null,
  };
  return start == null || !completedAtUtc.toUtc().isBefore(start);
}

/// Short human label for a zone id (`'Asia/Dubai'` → `'Dubai'`), used when
/// history rendered in its stored zone differs from the family zone.
String shortZoneLabel(String zoneId) {
  final tail = zoneId.split('/').last;
  return tail.replaceAll('_', ' ');
}

const _weekdays = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// `Sat 3 Oct` for a UTC instant rendered in [storedZoneId]. When
/// [familyZoneId] is given and differs from the stored zone, the zone is
/// named: `Sat 3 Oct (Dubai)` — so a family that moved still sees history in
/// the zone where it happened.
String formatDay(DateTime utc, String storedZoneId, {String? familyZoneId}) {
  final stored = normalizeZoneId(storedZoneId);
  final local = toFamilyZone(utc, stored);
  final base =
      '${_weekdays[local.weekday - 1]} ${local.day} '
      '${_months[local.month - 1]}';
  if (familyZoneId != null &&
      normalizeZoneId(familyZoneId) != stored &&
      stored != utcZoneId) {
    return '$base (${shortZoneLabel(stored)})';
  }
  return base;
}

/// `8:12am` for a UTC instant rendered in [storedZoneId], with the same
/// optional zone-label rule as [formatDay].
String formatTime(DateTime utc, String storedZoneId, {String? familyZoneId}) {
  final stored = normalizeZoneId(storedZoneId);
  final local = toFamilyZone(utc, stored);
  final suffix = local.hour < 12 ? 'am' : 'pm';
  var hour = local.hour % 12;
  if (hour == 0) hour = 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final base = '$hour:$minute$suffix';
  if (familyZoneId != null &&
      normalizeZoneId(familyZoneId) != stored &&
      stored != utcZoneId) {
    return '$base (${shortZoneLabel(stored)})';
  }
  return base;
}
