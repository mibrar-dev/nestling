// First-run migration (P04 settings-row bug): a real first launch opens an
// empty database and P04 is the first onboarding screen that writes a
// setting. `AppDatabase.migration.beforeOpen` must guarantee the `fam1`
// family + settings rows (like the `app_state` row), so the repositories'
// `UPDATE settings WHERE family_id = 'fam1'` matches a row and the parent's
// choice is stored. Crash-report consent keeps its table default (OFF).

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';

void main() {
  group('first-run migration', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.memory();
    });

    tearDown(() async {
      await db.close();
    });

    test('fresh database has fam1 family + settings rows', () async {
      final families = await db.select(db.families).get();
      expect(families.map((f) => f.id), ['fam1']);

      final settings = await db.select(db.settings).get();
      expect(settings, hasLength(1));
      expect(settings.single.familyId, 'fam1');
    });

    test('crash-report consent defaults to OFF (ICO nudge rule)', () async {
      final setting = await (db.select(
        db.settings,
      )..where((s) => s.familyId.equals('fam1'))).getSingle();
      expect(setting.crashReportConsent, isFalse);
    });

    test('a settings UPDATE matches the first-run row', () async {
      final updated =
          await (db.update(db.settings)
                ..where((s) => s.familyId.equals('fam1')))
              .write(const SettingsCompanion(crashReportConsent: Value(true)));
      expect(updated, 1);
      final setting = await (db.select(
        db.settings,
      )..where((s) => s.familyId.equals('fam1'))).getSingle();
      expect(setting.crashReportConsent, isTrue);
    });

    test('re-opening never duplicates the rows', () async {
      await (db.update(db.settings)..where((s) => s.familyId.equals('fam1')))
          .write(const SettingsCompanion(crashReportConsent: Value(true)));
      // beforeOpen is idempotent (insertOrIgnore): re-running the migration
      // work keeps exactly one row and keeps the parent's choice.
      await db
          .into(db.appState)
          .insert(
            const AppStateCompanion(id: Value(1)),
            mode: InsertMode.insertOrIgnore,
          );
      await db
          .into(db.families)
          .insert(
            FamiliesCompanion.insert(id: 'fam1'),
            mode: InsertMode.insertOrIgnore,
          );
      await db
          .into(db.settings)
          .insert(
            SettingsCompanion.insert(familyId: 'fam1'),
            mode: InsertMode.insertOrIgnore,
          );
      expect(await db.select(db.settings).get(), hasLength(1));
      final setting = await (db.select(
        db.settings,
      )..where((s) => s.familyId.equals('fam1'))).getSingle();
      expect(setting.crashReportConsent, isTrue);
    });
  });
}
