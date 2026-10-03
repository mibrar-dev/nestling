// Shared batch 3 — trial expiry is elapsed time with a pinnable clock.
//
// The 14-day trial runs from the `app_state.trialStart` UTC instant
// (DATETIME_STORAGE.md: elapsed, not calendar days). `AppSession.trialExpired`
// is computed from that instant so the router fires even before the status
// row is rewritten; `refresh()`/`checkTrialExpiry()` persist
// `subscription_status = 'expired'` at launch/resume. An `active`
// subscriber never expires.

import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';

void main() {
  group('isTrialStartExpired — elapsed 14 days from the UTC instant', () {
    final now = DateTime.utc(2026, 10, 3, 12);

    test('a null start (trial never begun) never expires', () {
      expect(AppSession.isTrialStartExpired(null, now), isFalse);
    });

    test('13 days 23:59 is still a live trial', () {
      final start = now.subtract(
        const Duration(days: 13, hours: 23, minutes: 59),
      );
      expect(AppSession.isTrialStartExpired(start, now), isFalse);
    });

    test('exactly 14 days counts as expired', () {
      final start = now.subtract(const Duration(days: 14));
      expect(AppSession.isTrialStartExpired(start, now), isTrue);
    });

    test('15 days is expired', () {
      final start = now.subtract(const Duration(days: 15));
      expect(AppSession.isTrialStartExpired(start, now), isTrue);
    });
  });

  group('AppSession with a pinned clock', () {
    late AppDatabase db;
    var now = DateTime.utc(2026, 10, 3, 12);

    setUp(() async {
      db = AppDatabase.memory();
      await Seed.fresh(db);
      now = DateTime.utc(2026, 10, 3, 12);
    });

    tearDown(() async {
      await db.close();
    });

    AppSession session() {
      final s = AppSession(db, clock: () => now);
      addTearDown(s.dispose);
      return s;
    }

    Future<AppStateData?> row() => (db.select(
      db.appState,
    )..where((a) => a.id.equals(1))).getSingleOrNull();

    test(
      'startTrialNow stamps the clock instant, not the wall clock',
      () async {
        final s = session();
        await s.refresh();

        await s.startTrialNow();

        expect((await row())?.trialStart?.toUtc(), now.toUtc());
        expect((await row())?.subscriptionStatus, 'trial');
      },
    );

    test('a 15-day-old trial reads expired and persists on check', () async {
      final s = session();
      await s.refresh();
      await s.startTrialNow();
      await s.refresh();

      now = now.add(const Duration(days: 15));

      // Computed expiry needs no DB write: the router fires on the getter
      // while the stored status is still 'trial'.
      expect(s.trialExpired, isTrue);
      expect((await row())?.subscriptionStatus, 'trial');

      expect(await s.checkTrialExpiry(), isTrue);
      expect((await row())?.subscriptionStatus, 'expired');
      expect(s.trialExpired, isTrue);
    });

    test('a 13-day-old trial stays live and writes nothing', () async {
      final s = session();
      await s.refresh();
      await s.startTrialNow();

      now = now.add(const Duration(days: 13));

      expect(s.trialExpired, isFalse);
      expect(await s.checkTrialExpiry(), isFalse);
      expect((await row())?.subscriptionStatus, 'trial');
    });

    test('a trial with no start never expires, however late it gets', () async {
      final s = session();
      await s.refresh();

      now = now.add(const Duration(days: 365));

      expect(s.trialExpired, isFalse);
      expect(await s.checkTrialExpiry(), isFalse);
      expect((await row())?.subscriptionStatus, 'trial');
    });

    test('an already-expired row stays expired', () async {
      final s = session();
      await s.refresh();
      await s.startTrialNow();
      now = now.add(const Duration(days: 15));
      expect(await s.checkTrialExpiry(), isTrue);

      // A second check is a no-op (nothing left to flip).
      expect(await s.checkTrialExpiry(), isFalse);
      expect((await row())?.subscriptionStatus, 'expired');
      expect(s.trialExpired, isTrue);
    });
  });

  group('an active subscriber never expires', () {
    test('demo (active since 19 Sep) is live 100 days later', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      await Seed.demo(db);
      final now = DateTime.utc(2027, 1, 11, 12);
      final s = AppSession(db, clock: () => now);
      addTearDown(s.dispose);
      await s.refresh();

      expect(s.subscriptionStatus, 'active');
      expect(s.trialExpired, isFalse);
      expect(await s.checkTrialExpiry(), isFalse);

      final state = await (db.select(
        db.appState,
      )..where((a) => a.id.equals(1))).getSingleOrNull();
      expect(state?.subscriptionStatus, 'active');
    });
  });
}
