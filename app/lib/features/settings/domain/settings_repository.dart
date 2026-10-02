import 'package:nestling/features/settings/domain/entities/app_settings.dart';
import 'package:nestling/features/settings/domain/entities/settings_item.dart';

/// Family & settings (P16), backed by Drift. `watchItems()` derives the
/// section rows from [AppSettings] so the screen always shows live values.
abstract class SettingsRepository {
  Future<List<SettingsItem>> getItems();
  Stream<List<SettingsItem>> watchItems();

  Stream<AppSettings> watchSettings();

  Future<void> setPocketMoneyMode(String mode);
  Future<void> setPayoutDay(int day);
  Future<void> setNotifications({bool? approvals, bool? payout, bool? summary});
  Future<void> setCrashConsent({required bool consent});
  Future<void> setKidGateEnabled({required bool enabled});

  /// Stores [zoneId] as the family time zone (validated IANA id; unknown
  /// ids are ignored). No UI here — P16 Settings renders the picker plus
  /// the one-time "looks like you moved" prompt (see
  /// `FamilyZoneService.pendingMove`).
  Future<void> setFamilyTimeZone(String zoneId);

  /// Live stream of the stored family zone id (London default).
  Stream<String> watchFamilyTimeZone();
}
