import 'package:nestling/features/settings/domain/entities/app_settings.dart';
import 'package:nestling/features/settings/domain/entities/settings_child_entry.dart';
import 'package:nestling/features/settings/domain/entities/settings_item.dart';
import 'package:nestling/features/settings/domain/entities/settings_member_entry.dart';

/// Family & settings (P16), backed by Drift. `watchItems()` derives the
/// section rows from [AppSettings] so the screen always shows live values.
abstract class SettingsRepository {
  Future<List<SettingsItem>> getItems();
  Stream<List<SettingsItem>> watchItems();

  Stream<AppSettings> watchSettings();

  /// Children roster in creation order (Maya then Leo — CHILD ORDER ruling,
  /// never alphabetical) for the P16 Children section.
  Stream<List<SettingsChildEntry>> watchRoster();

  /// Family `members` rows in insertion order (Sarah then James) for the P16
  /// Family section.
  Stream<List<SettingsMemberEntry>> watchMembers();

  Future<void> setPocketMoneyMode(String mode);
  Future<void> setPayoutDay(int day);
  Future<void> setNotifications({bool? approvals, bool? payout, bool? summary});
  Future<void> setCrashConsent({required bool consent});
  Future<void> setKidGateEnabled({required bool enabled});

  /// Local export for the P16 "Download our data" row: the family's data as
  /// a JSON-ready document (family zone + ISO timestamps, no PIN hashes).
  Future<Map<String, dynamic>> exportFamilyData();

  /// Deletes the family account: every table is emptied and `app_state` is
  /// reset to a fresh install (onboarding incomplete, parent mode, no
  /// subscription) in one transaction. The caller then resets in-memory
  /// session state (`AppSession`, `AppModeController`) and routes to
  /// `/welcome`.
  Future<void> deleteFamilyAccount();

  /// Stores [zoneId] as the family time zone (validated IANA id; unknown
  /// ids are ignored). No UI here — P16 Settings renders the picker plus
  /// the one-time "looks like you moved" prompt (see
  /// `FamilyZoneService.pendingMove`).
  Future<void> setFamilyTimeZone(String zoneId);

  /// Live stream of the stored family zone id (London default).
  Stream<String> watchFamilyTimeZone();
}
