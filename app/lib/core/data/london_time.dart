// Nestling — Europe/London display helpers (legacy).
//
// DEPRECATED: kept only so parallel screen branches still compile. New code
// must use `family_time.dart` with the CURRENT `families.time_zone` (and
// each row's stored `…_tz` zone for history). Every function below delegates
// to `family_time` pinned to `'Europe/London'`, so behaviour for a
// never-moved family is unchanged.

import 'package:nestling/core/data/family_time.dart' as ft;

/// London zone id these shims pin to.
const String londonZoneId = ft.defaultFamilyZoneId;

/// True when [utc] falls inside UK daylight saving (BST = UTC+1).
@Deprecated('Use family_time.toFamilyZone + timezone data instead')
bool isLondonSummerTime(DateTime utc) {
  final london = ft.toFamilyZone(utc, londonZoneId);
  return london.timeZoneOffset == const Duration(hours: 1);
}

/// Convert a UTC instant to wall-clock Europe/London time.
@Deprecated('Use family_time.toFamilyZone(utc, zoneId) instead')
DateTime toLondon(DateTime utc) {
  final london = ft.toFamilyZone(utc, londonZoneId);
  return DateTime(
    london.year,
    london.month,
    london.day,
    london.hour,
    london.minute,
    london.second,
    london.millisecond,
    london.microsecond,
  );
}

/// `Sat 4 Oct` for a UTC instant.
@Deprecated('Use family_time.formatDay(utc, zoneId) instead')
String formatLondonDay(DateTime utc) => ft.formatDay(utc, londonZoneId);

/// `8:12am` for a UTC instant.
@Deprecated('Use family_time.formatTime(utc, zoneId) instead')
String formatLondonTime(DateTime utc) => ft.formatTime(utc, londonZoneId);

/// UTC instant of 00:00 Europe/London on the London day containing [utc].
@Deprecated('Use family_time.dayStartUtc(zoneId, now) instead')
DateTime londonDayStartUtc(DateTime utc) =>
    ft.dayStartUtc(londonZoneId, utc.toUtc());

/// UTC instant of Monday 00:00 Europe/London for the week containing [utc].
@Deprecated('Use family_time.weekStartUtc(zoneId, now) instead')
DateTime londonWeekStartUtc(DateTime utc) =>
    ft.weekStartUtc(londonZoneId, utc.toUtc());

/// Whether a completion at [completedUtc] still counts for a quest with
/// [repeatRule] at [nowUtc]: daily → same London day, weekly → same London
/// week (Mon–Sun), once → always.
@Deprecated(
  'Use family_time.countsForCurrentPeriod(rule, completed, now, zoneId)',
)
bool countsForCurrentPeriod(
  String repeatRule,
  DateTime completedUtc,
  DateTime nowUtc,
) => ft.countsForCurrentPeriod(repeatRule, completedUtc, nowUtc, londonZoneId);
