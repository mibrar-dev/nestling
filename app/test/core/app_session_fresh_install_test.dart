// A real first install has no seeded app_state row: every session write must
// still persist (regression for P01 BUG-4).

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
}
