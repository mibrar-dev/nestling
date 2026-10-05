import 'package:drift/drift.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/current_family.dart';
import 'package:nestling/features/privacy_consent/domain/entities/consent_option.dart';
import 'package:nestling/features/privacy_consent/domain/privacy_consent_repository.dart';

/// Drift-backed [PrivacyConsentRepository].
class PrivacyConsentRepositoryImpl implements PrivacyConsentRepository {
  new({required AppDatabase db, CurrentFamily? currentFamily})
    : _db = db,
      _currentFamily = currentFamily ?? CurrentFamily.fallback(db);

  final AppDatabase _db;
  final CurrentFamily _currentFamily;

  String get _familyId => _currentFamily.familyId;

  @override
  Future<List<ConsentOption>> getItems() => watchItems().first;

  @override
  Stream<List<ConsentOption>> watchItems() {
    return _db.watchSetting(_familyId).map((setting) {
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
        .watchSetting(_familyId)
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
    //
    // The pair runs in one transaction (P04-9): without it two overlapping
    // calls both see the empty table and the first INSERT wins, dropping
    // the parent's later tap. Serialised, the second call sees the
    // committed row and its UPDATE wins — last write wins.
    await _db.transaction(() async {
      final changed =
          await (_db.update(_db.settings)
                ..where((s) => s.familyId.equals(_familyId)))
              .write(SettingsCompanion(crashReportConsent: Value(consent)));
      if (changed == 0) {
        await _db
            .into(_db.settings)
            .insert(
              SettingsCompanion.insert(
                familyId: _familyId,
                crashReportConsent: Value(consent),
                // New-family defaults, written explicitly: the DDL default
                // only applies to databases created after the change, so an
                // explicit value is exact on migrated databases too.
                notifApprovals: const Value(false),
                notifPayout: const Value(false),
                notifSummary: const Value(false),
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
    });
  }
}
