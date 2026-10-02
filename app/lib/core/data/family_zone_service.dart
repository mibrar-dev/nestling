// Nestling — family time-zone source of truth.
//
// The family zone lives in `families.time_zone` (IANA id). The device zone
// comes from `flutter_timezone` (the writer's phone). They can differ: a
// parent travelling, or a family that moved and never confirmed.
//
// This service NEVER switches zones silently. When the device zone disagrees
// with the stored family zone it exposes [pendingMove] — a one-time confirm
// prompt for P16 Settings to show. The family confirms via
// [confirmPendingMove]; P16 also offers a manual picker via
// [setFamilyTimeZone] (same method the settings repository exposes).

import 'package:drift/drift.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/family_time.dart';
import 'package:nestling/core/data/seed.dart';

/// Reads the device zone; injectable so tests avoid the platform channel.
typedef DeviceZoneReader = Future<String> Function();

Future<String> _defaultDeviceZoneReader() => FlutterTimezone.getLocalTimezone();

/// Family zone service: device zone vs stored family zone.
class FamilyZoneService {
  FamilyZoneService(this._db, {DeviceZoneReader? deviceZoneReader})
    : _deviceZoneReader = deviceZoneReader ?? _defaultDeviceZoneReader;

  final AppDatabase _db;
  final DeviceZoneReader _deviceZoneReader;

  /// The device's current IANA zone id, or null when unreadable/invalid.
  Future<String?> deviceZoneId() async {
    try {
      final raw = await _deviceZoneReader();
      if (raw.isEmpty || !isKnownZoneId(raw)) return null;
      return raw;
    } on Object catch (_) {
      return null;
    }
  }

  /// The stored family zone (`families.time_zone`, London default).
  Future<String> familyZoneId([String familyId = Seed.familyId]) async {
    final row = await (_db.select(
      _db.families,
    )..where((f) => f.id.equals(familyId))).getSingleOrNull();
    final stored = row?.timeZone;
    if (stored == null || stored.isEmpty || !isKnownZoneId(stored)) {
      return defaultFamilyZoneId;
    }
    return stored;
  }

  /// Live stream of the stored family zone.
  Stream<String> watchFamilyZone([String familyId = Seed.familyId]) {
    return (_db.select(
      _db.families,
    )..where((f) => f.id.equals(familyId))).watchSingleOrNull().map((row) {
      final stored = row?.timeZone;
      if (stored == null || stored.isEmpty || !isKnownZoneId(stored)) {
        return defaultFamilyZoneId;
      }
      return stored;
    });
  }

  /// The device zone when it is known AND differs from the family zone —
  /// the one-time "looks like you moved, switch?" prompt input. Null means
  /// no prompt (same zone, or device zone unreadable).
  Future<String?> pendingMove([String familyId = Seed.familyId]) async {
    final device = await deviceZoneId();
    if (device == null) return null;
    final family = await familyZoneId(familyId);
    if (device == family) return null;
    return device;
  }

  /// Confirms the pending move: stores the device zone as the family zone.
  /// History keeps its stored zones; future periods follow the new zone.
  Future<void> confirmPendingMove([String familyId = Seed.familyId]) async {
    final device = await deviceZoneId();
    if (device == null) return;
    await setFamilyTimeZone(device, familyId);
  }

  /// Stores [zoneId] as the family zone (validated; unknown ids are ignored).
  /// Also mirrors the zone into `settings` so both rule tables agree.
  Future<void> setFamilyTimeZone(
    String zoneId, [
    String familyId = Seed.familyId,
  ]) async {
    if (!isKnownZoneId(zoneId)) return;
    final now = DateTime.now().toUtc();
    await (_db.update(_db.families)..where((f) => f.id.equals(familyId))).write(
      FamiliesCompanion(
        timeZone: Value(zoneId),
        updatedAt: Value(now),
        updatedAtTz: Value(zoneId),
      ),
    );
    await (_db.update(
      _db.settings,
    )..where((s) => s.familyId.equals(familyId))).write(
      SettingsCompanion(
        timeZone: Value(zoneId),
        updatedAt: Value(now),
        updatedAtTz: Value(zoneId),
      ),
    );
  }
}
