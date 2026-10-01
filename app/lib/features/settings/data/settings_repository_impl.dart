import 'package:drift/drift.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/data/stream_combine.dart';
import 'package:nestling/features/settings/domain/entities/app_settings.dart';
import 'package:nestling/features/settings/domain/entities/settings_item.dart';
import 'package:nestling/features/settings/domain/settings_repository.dart';

/// Drift-backed [SettingsRepository].
class SettingsRepositoryImpl implements SettingsRepository {
  new({required this._db});

  final AppDatabase _db;

  @override
  Future<List<SettingsItem>> getItems() => watchItems().first;

  @override
  Stream<List<SettingsItem>> watchItems() {
    return watchSettings().map(_rows);
  }

  @override
  Stream<AppSettings> watchSettings() {
    return combineLatest2(
      _db.watchSetting(Seed.familyId),
      _db.watchAppState(),
    ).map((parts) {
      final setting = parts[0] as Setting?;
      return AppSettings(
        pocketMoneyMode: setting?.pocketMoneyMode ?? 'both',
        payoutDay: setting?.payoutDay ?? 6,
        coinValuePencePerCoin: setting?.coinValuePencePerCoin ?? 1,
        notifApprovals: setting?.notifApprovals ?? true,
        notifPayout: setting?.notifPayout ?? true,
        notifSummary: setting?.notifSummary ?? true,
        crashReportConsent: setting?.crashReportConsent ?? false,
        kidGateEnabled: setting?.kidGateEnabled ?? true,
        subscriptionStatus:
            (parts[1] as AppStateData?)?.subscriptionStatus ?? 'trial',
      );
    });
  }

  @override
  Future<void> setPocketMoneyMode(String mode) =>
      _write(SettingsCompanion(pocketMoneyMode: Value(mode)));

  @override
  Future<void> setPayoutDay(int day) =>
      _write(SettingsCompanion(payoutDay: Value(day)));

  @override
  Future<void> setNotifications({
    bool? approvals,
    bool? payout,
    bool? summary,
  }) => _write(
    SettingsCompanion(
      notifApprovals: approvals == null
          ? const Value.absent()
          : Value(approvals),
      notifPayout: payout == null ? const Value.absent() : Value(payout),
      notifSummary: summary == null ? const Value.absent() : Value(summary),
    ),
  );

  @override
  Future<void> setCrashConsent({required bool consent}) =>
      _write(SettingsCompanion(crashReportConsent: Value(consent)));

  @override
  Future<void> setKidGateEnabled({required bool enabled}) =>
      _write(SettingsCompanion(kidGateEnabled: Value(enabled)));

  Future<void> _write(SettingsCompanion companion) {
    return (_db.update(
      _db.settings,
    )..where((s) => s.familyId.equals(Seed.familyId))).write(companion);
  }

  List<SettingsItem> _rows(AppSettings s) {
    String onOff({required bool value}) => value ? 'On' : 'Off';
    return <SettingsItem>[
      SettingsItem(
        id: 'subscription',
        title: 'Nestling Annual',
        detail: s.subscriptionStatus == 'active'
            ? 'Active · renews yearly'
            : 'Trial · then £29.99/year',
        enabled: true,
      ),
      SettingsItem(
        id: 'notif-approvals',
        title: 'Approvals waiting',
        detail: onOff(value: s.notifApprovals),
        enabled: s.notifApprovals,
      ),
      SettingsItem(
        id: 'notif-payout',
        title: 'Payout day reminder',
        detail: onOff(value: s.notifPayout),
        enabled: s.notifPayout,
      ),
      SettingsItem(
        id: 'notif-summary',
        title: 'Weekly family summary',
        detail: onOff(value: s.notifSummary),
        enabled: s.notifSummary,
      ),
      SettingsItem(
        id: 'kid-gate',
        title: 'Kid mode needs parent gate',
        detail: onOff(value: s.kidGateEnabled),
        enabled: s.kidGateEnabled,
      ),
      const SettingsItem(
        id: 'version',
        title: 'Version 1.0.0',
        detail: 'Help & feedback',
        enabled: true,
      ),
    ];
  }
}
