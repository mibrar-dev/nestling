import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/parental_gate/data/models/parental_gate_challenge_model.dart';
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

    test('a one-digit product yields a one-digit answer (2 Feb 2026)', () {
      final repo = ParentalGateRepositoryImpl(db: AppDatabase.memory());
      final challenge = repo.challengeFor(DateTime.utc(2026, 2, 2));
      expect(challenge.question, 'two times two');
      expect(challenge.answer, 4);
      expect(challenge.answer.toString().length, 1);
    });

    test('the entity carries the design copy in title and detail', () {
      final repo = ParentalGateRepositoryImpl(db: AppDatabase.memory());
      final challenge = repo.challengeFor(DateTime.utc(2026, 10, 3));
      expect(challenge.title, 'Grown-ups only');
      expect(challenge.detail, 'This keeps settings and purchases safe.');
      expect(challenge.id, '2026-10-3');
    });
  });

  group('ParentalGateChallengeModel', () {
    test('survives a JSON round trip', () {
      const challenge = ParentalGateChallengeModel(
        id: '2026-10-3',
        title: 'Grown-ups only',
        detail: 'This keeps settings and purchases safe.',
        a: 3,
        b: 9,
      );
      final restored = ParentalGateChallengeModel.fromJson(challenge.toJson());
      expect(restored, challenge);
      expect(restored.answer, 27);
      expect(restored.question, 'three times nine');
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

    test('the watch is live: flipping the switch re-emits', () async {
      final db = await setUpTestScope();
      final repo = ParentalGateRepositoryImpl(db: db);

      final emissions = <int>[];
      final sub = repo.watchItems().listen(
        (items) => emissions.add(items.length),
      );
      // Let the first (enabled) emission land.
      await Future<void>.delayed(Duration.zero);
      await repo.setGateEnabled(enabled: false);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(emissions.first, 1);
      expect(emissions.last, 0);
      await sub.cancel();
    });

    test(
      'a missing settings row leaves the gate enabled (fail open)',
      () async {
        final db = await setUpTestScope();
        // Seed.demo writes the row; drop it to model a half-migrated DB.
        await (db.delete(
          db.settings,
        )..where((s) => s.familyId.equals(Seed.familyId))).go();
        final repo = ParentalGateRepositoryImpl(db: db);
        expect(await repo.watchGateEnabled().first, isTrue);
        expect(await repo.getItems(), hasLength(1));
      },
    );

    test('Seed.empty still enables the gate (no children needed)', () async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.empty(db);
      final repo = ParentalGateRepositoryImpl(db: db);
      expect(await repo.watchGateEnabled().first, isTrue);
      final items = await repo.getItems();
      expect(items, hasLength(1));
      expect(items.single.answer, greaterThan(0));
    });
  });
}
