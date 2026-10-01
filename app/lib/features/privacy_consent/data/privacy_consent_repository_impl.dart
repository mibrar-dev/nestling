import 'package:drift/drift.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/privacy_consent/domain/entities/consent_option.dart';
import 'package:nestling/features/privacy_consent/domain/privacy_consent_repository.dart';

/// Drift-backed [PrivacyConsentRepository].
class PrivacyConsentRepositoryImpl implements PrivacyConsentRepository {
  new({required this._db});

  final AppDatabase _db;

  @override
  Future<List<ConsentOption>> getItems() => watchItems().first;

  @override
  Stream<List<ConsentOption>> watchItems() {
    return _db.watchSetting(Seed.familyId).map((setting) {
      final crash = setting?.crashReportConsent ?? false;
      return <ConsentOption>[
        const ConsentOption(
          id: 'no-ads',
          title: 'No ads or tracking — ever',
          detail: 'Nestling never sells data or shows adverts.',
          enabled: true,
        ),
        const ConsentOption(
          id: 'nickname',
          title: 'Children only need a nickname',
          detail: 'No photos, no email, no chat, no location.',
          enabled: true,
        ),
        const ConsentOption(
          id: 'uk-data',
          title: 'Data stored in the UK (London)',
          detail: 'Your family data stays close to home.',
          enabled: true,
        ),
        const ConsentOption(
          id: 'delete',
          title: 'Delete everything anytime',
          detail: 'One tap in Settings removes your family.',
          enabled: true,
        ),
        ConsentOption(
          id: 'crash',
          title: 'Share anonymous crash reports',
          detail: 'Optional — helps us fix bugs. Off by default.',
          enabled: crash,
        ),
      ];
    });
  }

  @override
  Stream<bool> watchCrashConsent() {
    return _db
        .watchSetting(Seed.familyId)
        .map((setting) => setting?.crashReportConsent ?? false);
  }

  @override
  Future<void> setCrashConsent({required bool consent}) {
    return (_db.update(_db.settings)
          ..where((s) => s.familyId.equals(Seed.familyId)))
        .write(SettingsCompanion(crashReportConsent: Value(consent)));
  }
}
