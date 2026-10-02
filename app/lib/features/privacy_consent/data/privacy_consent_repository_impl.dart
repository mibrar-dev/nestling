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
          id: ConsentOptionIds.crash,
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
  Future<void> setCrashConsent({required bool consent}) async {
    // P04 is the first onboarding screen that writes a setting, and on a
    // real first run no `settings` row exists yet (Seed.fresh writes only
    // `app_state`), so a bare UPDATE matches zero rows and the opt-in is
    // silently dropped (P04-1). Fall back to an insert when nothing was
    // updated; every other column takes its table default. Drift does not
    // enable PRAGMA foreign_keys, so the row lands even while `families` is
    // still missing. The `watchSetting` stream re-emits and the bloc flips
    // the toggle with no optimistic bookkeeping needed here.
    final changed =
        await (_db.update(_db.settings)
              ..where((s) => s.familyId.equals(Seed.familyId)))
            .write(SettingsCompanion(crashReportConsent: Value(consent)));
    if (changed == 0) {
      await _db
          .into(_db.settings)
          .insert(
            SettingsCompanion.insert(
              familyId: Seed.familyId,
              crashReportConsent: Value(consent),
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
  }
}
