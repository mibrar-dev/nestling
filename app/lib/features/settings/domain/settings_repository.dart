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
}
