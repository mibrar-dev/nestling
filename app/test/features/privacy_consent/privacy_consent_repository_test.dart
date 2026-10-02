// P04 — PrivacyConsentRepository (Drift-backed) contract.
//
// Crash-report consent lives in `settings.crashReportConsent` and is OFF by
// default (ICO nudge rule). `watchItems` always emits 5 rows; the crash row
// mirrors the setting.

import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/privacy_consent/data/privacy_consent_repository_impl.dart';

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
          'crash',
        ]);
        expect(items.singleWhere((i) => i.id == 'crash').enabled, isFalse);

        await repository.setCrashConsent(consent: true);
        items = await repository.watchItems().first;
        expect(items.singleWhere((i) => i.id == 'crash').enabled, isTrue);
        expect(items.length, 5);
      },
    );

    test('static rows stay enabled; only the crash row toggles', () async {
      await Seed.demo(db);
      await repository.setCrashConsent(consent: true);

      final items = await repository.getItems();
      for (final item in items.where((i) => i.id != 'crash')) {
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

    // BUG(P04-1) — FAILS on purpose. First-run repro: a real first launch has
    // an empty database (Seed.fresh writes only `app_state`), and P04 is the
    // first screen in the onboarding flow that writes a setting. The UPDATE
    // matches zero rows, the write is silently dropped, and the toggle snaps
    // back to OFF with no error. Root cause: PrivacyConsentRepositoryImpl
    // (data/privacy_consent_repository_impl.dart:63) updates instead of
    // upserting, and nothing creates the fam1 `settings` row before P04.
    // See docs/screens/P04/3_test.md and SHARED_REQUEST.md item 4.
    test('BUG(P04-1): consent persists on a first-run database', () async {
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
            .singleWhere((i) => i.id == 'crash')
            .enabled,
        isTrue,
      );
    });
  });
}
