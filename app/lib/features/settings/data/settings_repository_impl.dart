import 'package:drift/drift.dart';
import 'package:nestling/core/data/app_clock.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/current_family.dart';
import 'package:nestling/core/data/family_time.dart';
import 'package:nestling/core/data/family_zone_service.dart';
import 'package:nestling/core/data/stream_combine.dart';
import 'package:nestling/features/settings/data/family_data_export.dart';
import 'package:nestling/features/settings/domain/entities/app_settings.dart';
import 'package:nestling/features/settings/domain/entities/settings_child_entry.dart';
import 'package:nestling/features/settings/domain/entities/settings_item.dart';
import 'package:nestling/features/settings/domain/entities/settings_member_entry.dart';
import 'package:nestling/features/settings/domain/settings_repository.dart';

/// Drift-backed [SettingsRepository].
class SettingsRepositoryImpl implements SettingsRepository {
  new({
    required AppDatabase db,
    FamilyZoneService? zoneService,
    CurrentFamily? currentFamily,
  }) : _db = db,
       _zoneService = zoneService ?? FamilyZoneService(db),
       _currentFamily = currentFamily ?? CurrentFamily.fallback(db);

  final AppDatabase _db;
  final CurrentFamily _currentFamily;

  String get _familyId => _currentFamily.familyId;

  /// Family-zone writer. Injected so the DI singleton's configuration is
  /// honoured; direct constructions fall back to a local instance (review
  /// finding 6 — the repository must not build its own service inline).
  final FamilyZoneService _zoneService;

  @override
  Future<List<SettingsItem>> getItems() => watchItems().first;

  @override
  Stream<List<SettingsItem>> watchItems() {
    return watchSettings().map(settingsItemsFor);
  }

  @override
  Stream<AppSettings> watchSettings() {
    return combineLatest2(_db.watchSetting(_familyId), _db.watchAppState()).map(
      (parts) {
        final setting = parts[0] as Setting?;
        return AppSettings(
          pocketMoneyMode: setting?.pocketMoneyMode ?? 'both',
          payoutDay: setting?.payoutDay ?? 6,
          coinValuePencePerCoin: setting?.coinValuePencePerCoin ?? 1,
          // OFF when no row exists yet (new-family nudge rule).
          notifApprovals: setting?.notifApprovals ?? false,
          notifPayout: setting?.notifPayout ?? false,
          notifSummary: setting?.notifSummary ?? false,
          crashReportConsent: setting?.crashReportConsent ?? false,
          kidGateEnabled: setting?.kidGateEnabled ?? true,
          subscriptionStatus:
              (parts[1] as AppStateData?)?.subscriptionStatus ?? 'trial',
        );
      },
    );
  }

  @override
  Stream<List<SettingsChildEntry>> watchRoster() {
    // CHILD ORDER ruling: creation order via the shared helper (`createdAt`,
    // then `rowid` for same-second ties) — Maya before Leo — never
    // alphabetical.
    return _db
        .watchChildren(_familyId)
        .map((rows) => rows.map(_toChildEntry).toList());
  }

  @override
  Stream<List<SettingsMemberEntry>> watchMembers() {
    // Insertion order (`rowid`) — Sarah before James — via the shared core
    // query (review finding 5: no feature-local raw SQL for this). The
    // current family id comes from the shared holder.
    return _db
        .watchMembers(_familyId)
        .map((rows) => rows.map(_toMemberEntry).toList());
  }

  @override
  Future<Map<String, dynamic>> exportFamilyData() =>
      buildFamilyExport(_db, _familyId);

  @override
  Future<void> deleteFamilyAccount() {
    // One transaction (P16 deletion rule): empty every table, then reset
    // `app_state` to a fresh install — onboarding incomplete, parent mode,
    // no subscription (trial status with no start, like `Seed.fresh`). Only
    // the fresh `app_state` row survives, so a second launch starts at
    // `/welcome` via the router's onboarding redirect.
    return _db.transaction(() async {
      for (final table in _db.allTables) {
        await _db.delete(table).go();
      }
      await _db
          .into(_db.appState)
          .insert(
            const AppStateCompanion(
              id: Value(1),
              onboardingComplete: Value(false),
              appMode: Value('parent'),
            ),
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

  @override
  Future<void> setFamilyTimeZone(String zoneId) =>
      _zoneService.setFamilyTimeZone(zoneId);

  @override
  Stream<String> watchFamilyTimeZone() => _db.watchFamilyZoneId();

  Future<void> _write(SettingsCompanion companion) async {
    final zone = await _db.familyZoneId();
    final stamped = companion.copyWith(
      updatedAt: Value(appNowUtc()),
      updatedAtTz: Value(normalizeZoneId(zone)),
    );
    await (_db.update(
      _db.settings,
    )..where((s) => s.familyId.equals(_familyId))).write(stamped);
    // Keep the `families` rule row in step (payout day / zone live there).
    await (_db.update(
      _db.families,
    )..where((f) => f.id.equals(_familyId))).write(
      FamiliesCompanion(
        updatedAt: Value(appNowUtc()),
        updatedAtTz: Value(normalizeZoneId(zone)),
      ),
    );
  }

  SettingsChildEntry _toChildEntry(ChildrenData row) {
    return SettingsChildEntry(
      id: row.id,
      nickname: row.nickname,
      ageBand: row.ageBand,
      pipStageName: settingsPipStageName(row.pipStage),
      coins: row.coins,
      avatarColour: row.avatarColour,
    );
  }

  SettingsMemberEntry _toMemberEntry(Member row) {
    return SettingsMemberEntry(
      id: row.id,
      name: row.name,
      role: row.role,
      inviteStatus: row.inviteStatus,
      email: row.email,
    );
  }
}
