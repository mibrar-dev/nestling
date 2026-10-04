import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/features/parental_gate/data/parental_gate_repository_impl.dart';

import '../../test_scope.dart';

void main() {
  group('ParentalGateRepository.challengeFor', () {
    test('the plan fixture date gives seven times six', () {
      final repo = ParentalGateRepositoryImpl(db: AppDatabase.memory());
      final challenge = repo.challengeFor(DateTime.utc(2026, 1, 6));
      expect(challenge.question, 'seven times six');
      expect(challenge.answer, 42);
      expect(challenge.verify(42), isTrue);
      expect(challenge.verify(24), isFalse);
    });

    test('the pinned demo day gives three times nine', () {
      final repo = ParentalGateRepositoryImpl(db: AppDatabase.memory());
      final challenge = repo.challengeFor(DateTime.utc(2026, 10, 3));
      expect(challenge.question, 'three times nine');
      expect(challenge.answer, 27);
    });

    test('the challenge is stable all day and deterministic per date', () {
      final repo = ParentalGateRepositoryImpl(db: AppDatabase.memory());
      final morning = repo.challengeFor(DateTime.utc(2026, 10, 3, 6, 30));
      final evening = repo.challengeFor(DateTime.utc(2026, 10, 3, 21, 45));
      expect(morning.a, evening.a);
      expect(morning.b, evening.b);
      expect(morning.question, evening.question);
    });
  });

  group('ParentalGateRepository gate switch', () {
    test('watchItems emits the challenge while the gate is enabled', () async {
      final db = await setUpTestScope();
      final repo = ParentalGateRepositoryImpl(db: db);
      final items = await repo.getItems();
      expect(items, hasLength(1));
      expect(items.single.title, 'Grown-ups only');
    });

    test(
      'disabling the gate empties the list; re-enabling restores it',
      () async {
        final db = await setUpTestScope();
        final repo = ParentalGateRepositoryImpl(db: db);

        await repo.setGateEnabled(enabled: false);
        expect(await repo.getItems(), isEmpty);
        expect(await repo.watchGateEnabled().first, isFalse);

        await repo.setGateEnabled(enabled: true);
        final items = await repo.getItems();
        expect(items, hasLength(1));
        expect(await repo.watchGateEnabled().first, isTrue);
      },
    );
  });
}
