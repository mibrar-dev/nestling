// P04 — PrivacyConsentRepository (Drift-backed) contract.
//
// Crash-report consent lives in `settings.crashReportConsent` and is OFF by
// default (ICO nudge rule). `watchItems` always emits 5 rows; the crash row
// mirrors the setting.

import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/privacy_consent/data/privacy_consent_repository_impl.dart';
import 'package:nestling/features/privacy_consent/domain/entities/consent_option.dart';

void main() {
  group('PrivacyConsentRepository (in-memory Drift)', () {
    late AppDatabase db;
    late PrivacyConsentRepositoryImpl repository;

    setUp(() {
      db = AppDatabase.memory();
      repository = PrivacyConsentRepositoryImpl(db: db);
    });

    tearDown(() => db.close());

    test('watchCrashConsent defaults to false (ICO: off by default)', () async {
      await Seed.demo(db);
      expect(await repository.watchCrashConsent().first, isFalse);
      expect((await repository.getItems()).length, 5);
    });

    test('setCrashConsent(true/false) round-trips via watchSetting', () async {
      await Seed.demo(db);
      expect(await repository.watchCrashConsent().first, isFalse);

      await repository.setCrashConsent(consent: true);
      expect(await repository.watchCrashConsent().first, isTrue);

      await repository.setCrashConsent(consent: false);
      expect(await repository.watchCrashConsent().first, isFalse);
    });

    test(
      'watchItems always emits 5 rows; crash row mirrors the setting',
      () async {
        await Seed.demo(db);

        var items = await repository.watchItems().first;
        expect(items.map((i) => i.id), <String>[
          'no-ads',
          'nickname',
          'uk-data',
          'delete',
          ConsentOptionIds.crash,
        ]);
        expect(
          items.singleWhere((i) => i.id == ConsentOptionIds.crash).enabled,
          isFalse,
        );

        await repository.setCrashConsent(consent: true);
        items = await repository.watchItems().first;
        expect(
          items.singleWhere((i) => i.id == ConsentOptionIds.crash).enabled,
          isTrue,
        );
        expect(items.length, 5);
      },
    );

    test('static rows stay enabled; only the crash row toggles', () async {
      await Seed.demo(db);
      await repository.setCrashConsent(consent: true);

      final items = await repository.getItems();
      for (final item in items.where((i) => i.id != ConsentOptionIds.crash)) {
        expect(
          item.enabled,
          isTrue,
          reason: '${item.id} is static reassurance',
        );
      }
    });

    test('Seed.empty keeps consent off', () async {
      await Seed.empty(db);
      expect(await repository.watchCrashConsent().first, isFalse);
      expect((await repository.watchItems().first).length, 5);
    });

    test('a write leaves the other settings columns untouched', () async {
      await Seed.demo(db);
      final before = (await db.select(db.settings).get()).single;
      await repository.setCrashConsent(consent: true);
      final after = (await db.select(db.settings).get()).single;

      expect(after.crashReportConsent, isTrue);
      expect(after.pocketMoneyMode, before.pocketMoneyMode);
      expect(after.notifApprovals, before.notifApprovals);
      expect(after.notifPayout, before.notifPayout);
      expect(after.notifSummary, before.notifSummary);
      expect(after.kidGateEnabled, before.kidGateEnabled);
    });

    // Regression test for P04-1 (fixed in iteration 2 by upserting in
    // PrivacyConsentRepositoryImpl.setCrashConsent): a real first launch has
    // an empty database (Seed.fresh writes only `app_state`), and P04 is the
    // first screen in the onboarding flow that writes a setting. The UPDATE
    // used to match zero rows and the write was silently dropped; now the
    // repository inserts the row when nothing was updated.
    // See docs/screens/P04/3_test.md and SHARED_REQUEST.md item 4 (kept for
    // the P16 SettingsRepositoryImpl half, which shares the UPDATE-only shape).
    test('consent persists on a first-run database', () async {
      await Seed.fresh(db);
      expect(
        (await db.select(db.settings).get()).length,
        0,
        reason: 'a first-run database has no settings row yet',
      );

      await repository.setCrashConsent(consent: true);

      expect(
        await repository.watchCrashConsent().first,
        isTrue,
        reason: 'the parent opted in on P04 — the choice must be stored',
      );
      expect(
        (await repository.watchItems().first)
            .singleWhere((i) => i.id == ConsentOptionIds.crash)
            .enabled,
        isTrue,
      );
    });

    // The upsert must insert exactly one row and then UPDATE it in place. A
    // second insert would break `watchSetting` (two rows for fam1) and the
    // `SettingsRepositoryImpl` reads that follow it.
    test('the first-run upsert creates one row and reuses it', () async {
      await Seed.fresh(db);

      await repository.setCrashConsent(consent: true);
      var rows = await db.select(db.settings).get();
      expect(rows.length, 1, reason: 'the insert fallback must add one row');
      expect(rows.single.familyId, Seed.familyId);
      expect(rows.single.crashReportConsent, isTrue);
      final created = rows.single;

      await repository.setCrashConsent(consent: false);
      rows = await db.select(db.settings).get();
      expect(
        rows.length,
        1,
        reason: 'the second write must UPDATE, not insert',
      );
      expect(rows.single.crashReportConsent, isFalse);

      // Back on again: still one row, and the stream reports it.
      await repository.setCrashConsent(consent: true);
      rows = await db.select(db.settings).get();
      expect(rows.length, 1);
      expect(rows.single.crashReportConsent, isTrue);
      expect(
        await repository.watchCrashConsent().first,
        isTrue,
        reason: 'the stored opt-in survives repeated writes',
      );
      expect(created.familyId, rows.single.familyId);
    });

    test('the inserted row takes the settings table defaults', () async {
      await Seed.fresh(db);
      await repository.setCrashConsent(consent: true);
      final row = (await db.select(db.settings).get()).single;

      // Only the consent column is written by P04; everything else keeps the
      // schema defaults (`Settings` in core/data/app_database.dart), never
      // demo-seed values.
      expect(row.crashReportConsent, isTrue);
      expect(row.kidGateEnabled, isTrue, reason: 'table default');
      expect(row.notifApprovals, isTrue, reason: 'table default');
      expect(row.notifPayout, isTrue, reason: 'table default');
      expect(row.notifSummary, isTrue, reason: 'table default');
      expect(row.pocketMoneyMode, 'both', reason: 'table default');
      expect(row.payoutDay, 6, reason: 'table default');
      expect(row.coinValuePencePerCoin, 1, reason: 'table default');
    });

    // Writing the value that is already stored must be idempotent: no second row,
    // no error, no lost write.
    test('re-writing the stored value changes nothing', () async {
      await Seed.fresh(db);
      await repository.setCrashConsent(consent: true);
      await repository.setCrashConsent(consent: true);

      final rows = await db.select(db.settings).get();
      expect(rows.length, 1);
      expect(rows.single.crashReportConsent, isTrue);
      expect(await repository.watchCrashConsent().first, isTrue);
    });

    test('concurrent first-run writes still leave exactly one row', () async {
      await Seed.fresh(db);

      await Future.wait<void>(<Future<void>>[
        repository.setCrashConsent(consent: true),
        repository.setCrashConsent(consent: true),
        repository.setCrashConsent(consent: false),
      ]);

      final rows = await db.select(db.settings).get();
      expect(
        rows.length,
        1,
        reason: 'insertOrIgnore keeps a racing pair from duplicating the row',
      );
      expect(await repository.watchCrashConsent().first, isA<bool>());
    });

    // P04-9: the UPDATE-then-conditional-INSERT pair runs in one transaction,
    // so overlapping writes serialise instead of the first INSERT winning.
    for (final lastWins in const <bool>[false, true]) {
      test(
        'overlapping first-run writes settle on the last value ($lastWins)',
        () async {
          await Seed.fresh(db);

          await Future.wait<void>(<Future<void>>[
            repository.setCrashConsent(consent: true),
            repository.setCrashConsent(consent: lastWins),
          ]);

          final rows = await db.select(db.settings).get();
          expect(rows.length, 1);
          expect(
            rows.single.crashReportConsent,
            lastWins,
            reason: 'the second write is the one that must survive',
          );
          expect(await repository.watchCrashConsent().first, lastWins);
        },
      );
    }
  });
}
