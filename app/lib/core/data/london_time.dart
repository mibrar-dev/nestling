// Nestling — Europe/London display helpers.
//
// Legacy London-only helpers kept for in-flight screens; new code uses
// family_time.dart. Will be removed after all screens migrate.

import 'package:nestling/core/data/family_time.dart' as ft;

/// London zone id these shims pin to.
const String londonZoneId = ft.defaultFamilyZoneId;

/// True when [utc] falls inside UK daylight saving (BST = UTC+1).
bool isLondonSummerTime(DateTime utc) {
  final london = ft.toFamilyZone(utc, londonZoneId);
  return london.timeZoneOffset == const Duration(hours: 1);
}

/// Convert a UTC instant to wall-clock Europe/London time.
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
String formatLondonDay(DateTime utc) => ft.formatDay(utc, londonZoneId);

/// `8:12am` for a UTC instant.
String formatLondonTime(DateTime utc) => ft.formatTime(utc, londonZoneId);

/// UTC instant of 00:00 Europe/London on the London day containing [utc].
DateTime londonDayStartUtc(DateTime utc) =>
    ft.dayStartUtc(londonZoneId, utc.toUtc());

/// UTC instant of Monday 00:00 Europe/London for the week containing [utc].
DateTime londonWeekStartUtc(DateTime utc) =>
    ft.weekStartUtc(londonZoneId, utc.toUtc());

/// Whether a completion at [completedUtc] still counts for a quest with
/// [repeatRule] at [nowUtc]: daily → same London day, weekly → same London
/// week (Mon–Sun), once → always.
bool countsForCurrentPeriod(
  String repeatRule,
  DateTime completedUtc,
  DateTime nowUtc,
) => ft.countsForCurrentPeriod(repeatRule, completedUtc, nowUtc, londonZoneId);
