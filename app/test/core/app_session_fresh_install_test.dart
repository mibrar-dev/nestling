// A real first install has no seeded app_state row: every session write must
// still persist (regression for P01 BUG-4).

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';

void main() {
  test(
    'completeOnboarding persists on a database with no app_state row',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final session = AppSession(db);
      await session.refresh();
      expect(session.onboardingComplete, isFalse);

      await session.completeOnboarding();
      await session.refresh();
      expect(session.onboardingComplete, isTrue);

      await session.setAppMode('kid');
      await session.refresh();
      expect(
        session.onboardingComplete,
        isTrue,
        reason: 'second write updates, not resets',
      );
      session.dispose();
      await db.close();
    },
  );

  test('app_state row 1 exists on a brand-new database', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final rows = await db.select(db.appState).get();
    expect(rows.map((r) => r.id), [1]);
    // A repository-style UPDATE WHERE id = 1 now lands.
    await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
      const AppStateCompanion(onboardingComplete: Value(true)),
    );
    final row = await (db.select(
      db.appState,
    )..where((a) => a.id.equals(1))).getSingle();
    expect(row.onboardingComplete, isTrue);
    await db.close();
  });
}
